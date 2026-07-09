# Part 6: Fan-Out Notifications with step.sendEvent

## 1. The scenario

When a task is created, we want to notify **every member of the project** (not just the assignee) that a new task exists, via an in-app "activity feed" style notification (we'll store these as DB rows and just log/email a summary — no push infra needed for this tutorial). When a task is specifically **assigned**, the assignee should also get a dedicated email.

This is a classic fan-out: one event, potentially many downstream actions (one per member). Doing this with a plain `for` loop inside one function works, but Inngest gives us a cleaner, more resilient tool: `step.sendEvent`, which lets one function emit new events that other functions (or even the same function type, recursively) can react to — decoupling "figure out who to notify" from "actually notify one person."

## 2. Add a Notification model

Update `prisma/schema.prisma`, add:

```prisma
model Notification {
  id        String   @id @default(cuid())
  user      User     @relation(fields: [userId], references: [id])
  userId    String
  message   String
  taskId    String?
  read      Boolean  @default(false)
  createdAt DateTime @default(now())
}
```

Add the reverse relation on `User`: `notifications Notification[]`. Then:

```bash
npx prisma db push && npx prisma generate
```

## 3. Add new event types

Update `Events` in `src/inngest/client.ts`:

```ts
"notification/member.notify": {
  data: { userId: string; taskId: string; message: string };
};
"email/task.assigned": {
  data: { taskId: string; assigneeUserId: string };
};
```

## 4. The orchestrator function: fan out via step.sendEvent

Create `src/inngest/functions/tasks.ts`:

```ts
import { inngest } from "../client";
import { prisma } from "@/lib/prisma";
import { resend, FROM_ADDRESS } from "@/lib/email";

export const fanOutTaskCreatedNotifications = inngest.createFunction(
  { id: "fan-out-task-created-notifications" },
  { event: "task/task.created" },
  async ({ event, step }) => {
    const members = await step.run("get-project-members", async () => {
      return prisma.projectMember.findMany({
        where: { projectId: event.data.projectId },
        select: { userId: true },
      });
    });

    const task = await step.run("get-task", async () => {
      return prisma.task.findUniqueOrThrow({ where: { id: event.data.taskId } });
    });

    // Fan out: send one "notify" event per member, in a single batched call.
    await step.sendEvent(
      "notify-all-members",
      members.map((m) => ({
        name: "notification/member.notify" as const,
        data: {
          userId: m.userId,
          taskId: event.data.taskId,
          message: `New task "${task.title}" was created`,
        },
      }))
    );

    return { notified: members.length };
  }
);

export const createNotificationRow = inngest.createFunction(
  { id: "create-notification-row" },
  { event: "notification/member.notify" },
  async ({ event, step }) => {
    await step.run("insert-notification", async () => {
      await prisma.notification.create({
        data: {
          userId: event.data.userId,
          taskId: event.data.taskId,
          message: event.data.message,
        },
      });
    });
  }
);

export const sendTaskAssignedEmail = inngest.createFunction(
  { id: "send-task-assigned-email" },
  { event: "task/task.assigned" },
  async ({ event, step }) => {
    const assignee = await step.run("get-assignee", async () => {
      return prisma.user.findUniqueOrThrow({ where: { id: event.data.assigneeUserId } });
    });

    const task = await step.run("get-task", async () => {
      return prisma.task.findUniqueOrThrow({ where: { id: event.data.taskId } });
    });

    await step.run("send-email", async () => {
      await resend.emails.send({
        from: FROM_ADDRESS,
        to: assignee.email,
        subject: `You've been assigned: ${task.title}`,
        html: `<p>Hi ${assignee.firstName ?? "there"},</p><p>You've been assigned the task "<strong>${task.title}</strong>".</p>`,
      });
    });
  }
);
```

Why split "figure out who to notify" (`fanOutTaskCreatedNotifications`) from "create one notification row" (`createNotificationRow`) into two functions connected by an event, instead of just looping and writing rows directly in one function? Two reasons:

1. **Independent retries.** If writing one member's notification row fails, only that one `createNotificationRow` run retries — not the whole fan-out, and not the DB queries that already succeeded.
2. **Scalability.** For a project with 500 members, `step.sendEvent` with a batch of 500 events is still one fast, cheap operation; Inngest then runs up to its configured concurrency of `createNotificationRow` invocations in parallel, rather than your one function serially awaiting 500 `prisma.create` calls in a loop (which is slower and more fragile to a single failure).

## 5. Wire everything into the serve route

```ts
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { helloWorld } from "@/inngest/functions";
import { syncUserOnCreate } from "@/inngest/functions/users";
import {
  fanOutTaskCreatedNotifications,
  createNotificationRow,
  sendTaskAssignedEmail,
} from "@/inngest/functions/tasks";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    helloWorld,
    syncUserOnCreate,
    fanOutTaskCreatedNotifications,
    createNotificationRow,
    sendTaskAssignedEmail,
  ],
});
```

## 6. Show notifications in the UI

Add a simple notifications dropdown/page. Create `src/app/notifications/page.tsx`:

```tsx
import { prisma } from "@/lib/prisma";
import { getCurrentDbUser } from "@/lib/current-user";

export default async function NotificationsPage() {
  const user = await getCurrentDbUser();
  if (!user) return <p>Please sign in.</p>;

  const notifications = await prisma.notification.findMany({
    where: { userId: user.id },
    orderBy: { createdAt: "desc" },
    take: 20,
  });

  return (
    <main className="mx-auto max-w-2xl p-8">
      <h1 className="text-2xl font-bold mb-6">Notifications</h1>
      <ul className="space-y-2">
        {notifications.map((n) => (
          <li key={n.id} className="border rounded p-3">
            {n.message}
          </li>
        ))}
      </ul>
    </main>
  );
}
```

## 7. Test the whole flow

1. Add a second member to a project directly via Prisma Studio (create another `User` row and a `ProjectMember` linking them) if you don't have a second real test account.
2. Create a task in that project and assign it to that member.
3. Watch the Inngest Dev Server Runs tab: you should see `fan-out-task-created-notifications` run once, then `create-notification-row` run once per member (from the batched `step.sendEvent`), and `send-task-assigned-email` run once for the assignment event.
4. Visit `/notifications` (as the notified user) and confirm rows appear.

## Checkpoint

- [ ] `Notification` model added and migrated
- [ ] `fanOutTaskCreatedNotifications` sends a batch of events via `step.sendEvent`
- [ ] `createNotificationRow` and `sendTaskAssignedEmail` each react independently
- [ ] Creating and assigning a task in the UI results in the correct chain of Inngest runs
- [ ] `/notifications` page shows stored notifications

## Troubleshooting

**`step.sendEvent` with an empty array does nothing.** That's expected — a project with zero other members produces zero fan-out events; not a bug.

**Duplicate notifications on retry.** If `fan-out-task-created-notifications` fails *after* `step.sendEvent` already ran but before the function returns, and then retries, `step.sendEvent` is itself memoized as a step — so it won't re-send on retry, matching the same durability guarantee as `step.run`.

Next: **Part 7** introduces `step.sleep`/`step.sleepUntil` for a multi-day onboarding email drip — durable delays without keeping any server process alive. Want me to bring that up next?
