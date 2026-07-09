# Part 8: Scheduled Cron Functions

## 1. Cron triggers instead of event triggers

So far every function has been triggered by an event. Inngest also supports **cron triggers** — functions that run on a schedule, with no event needed at all:

```ts
export const dailyDigest = inngest.createFunction(
  { id: "daily-digest" },
  { cron: "0 8 * * *" }, // every day at 08:00 UTC
  async ({ step }) => { /* ... */ }
);
```

The `cron` string uses standard cron syntax (`minute hour day month weekday`). No event payload exists for these runs — the handler receives `{ step }` and reads whatever it needs from your database.

## 2. Build a daily digest email

Add to `src/inngest/functions/tasks.ts`:

```ts
export const dailyDigest = inngest.createFunction(
  { id: "daily-digest" },
  { cron: "0 8 * * *" },
  async ({ step }) => {
    const users = await step.run("get-active-users", async () => {
      return prisma.user.findMany({
        include: {
          tasksAssigned: {
            where: { status: { not: "DONE" } },
          },
        },
      });
    });

    const usersWithOpenTasks = users.filter((u) => u.tasksAssigned.length > 0);

    // Fan out: one email-send step per user, via a dedicated function.
    await step.sendEvent(
      "send-digest-per-user",
      usersWithOpenTasks.map((u) => ({
        name: "email/digest.requested" as const,
        data: { userId: u.id, openTaskCount: u.tasksAssigned.length },
      }))
    );

    return { digestsSent: usersWithOpenTasks.length };
  }
);

export const sendDigestEmail = inngest.createFunction(
  { id: "send-digest-email" },
  { event: "email/digest.requested" },
  async ({ event, step }) => {
    const user = await step.run("get-user", async () => {
      return prisma.user.findUniqueOrThrow({ where: { id: event.data.userId } });
    });

    await step.run("send-email", async () => {
      await resend.emails.send({
        from: FROM_ADDRESS,
        to: user.email,
        subject: `You have ${event.data.openTaskCount} open task(s)`,
        html: `<p>Hi ${user.firstName ?? "there"}, you have ${event.data.openTaskCount} open task(s) waiting in TaskFlow.</p>`,
      });
    });
  }
);
```

Same fan-out pattern as Part 6: the cron function figures out *who* needs a digest, then delegates the actual send to a per-user event-triggered function, so one user's email failure doesn't affect anyone else's, and each retries independently.

Add the new event type to `src/inngest/client.ts`:

```ts
"email/digest.requested": {
  data: { userId: string; openTaskCount: number };
};
```

## 3. Build an overdue-task sweep

Add a `dueDate` check that flags tasks overdue and notifies the assignee, running every hour:

```ts
export const overdueTaskSweep = inngest.createFunction(
  { id: "overdue-task-sweep" },
  { cron: "0 * * * *" }, // every hour, on the hour
  async ({ step }) => {
    const overdueTasks = await step.run("find-overdue-tasks", async () => {
      return prisma.task.findMany({
        where: {
          status: { not: "DONE" },
          dueDate: { lt: new Date() },
        },
        include: { assignee: true },
      });
    });

    const withAssignee = overdueTasks.filter((t) => t.assignee !== null);

    await step.sendEvent(
      "notify-overdue",
      withAssignee.map((t) => ({
        name: "notification/member.notify" as const,
        data: {
          userId: t.assigneeId!,
          taskId: t.id,
          message: `Task "${t.title}" is overdue!`,
        },
      }))
    );

    return { overdueCount: withAssignee.length };
  }
);
```

This reuses the exact same `notification/member.notify` event and `createNotificationRow` function from Part 6 — no new notification-delivery code needed, just a new source of that event.

## 4. Cron syntax cheat sheet

| Expression | Meaning |
|---|---|
| `* * * * *` | Every minute |
| `0 * * * *` | Every hour, on the hour |
| `0 8 * * *` | Every day at 08:00 UTC |
| `0 8 * * 1` | Every Monday at 08:00 UTC |
| `0 0 1 * *` | Midnight on the 1st of every month |

Cron schedules always run in **UTC** unless you use Inngest's `TZ=` prefix syntax, e.g. `{ cron: "TZ=America/New_York 0 8 * * *" }` to run at 8am US Eastern time regardless of daylight saving.

## 5. Testing cron functions locally

You don't have to wait for the real schedule. In the Inngest Dev Server dashboard, go to the **Functions** tab, click on `daily-digest` or `overdue-task-sweep`, and use the **Invoke** button to trigger a manual test run immediately, bypassing the schedule entirely. This is by far the fastest way to iterate on cron function logic.

## 6. Register everything

Add `dailyDigest`, `sendDigestEmail`, and `overdueTaskSweep` to the `functions` array in `src/app/api/inngest/route.ts`.

## Checkpoint

- [ ] `daily-digest` and `overdue-task-sweep` created with `cron` triggers instead of `event` triggers
- [ ] Both use the fan-out-then-delegate pattern to send events per affected user
- [ ] Manually invoked both from the Dev Server dashboard's Functions tab and confirmed correct behavior
- [ ] Understand cron syntax and the `TZ=` prefix for timezone-aware schedules

## Troubleshooting

**Cron function never seems to run on its own locally.** The Dev Server does simulate cron schedules, but for fast iteration always prefer the manual **Invoke** button over waiting for real time to pass.

**Digest emails sent to users with zero open tasks.** Double check the `.filter((u) => u.tasksAssigned.length > 0)` line — this is exactly the kind of off-by-one logic bug worth testing explicitly (see Part 11 for writing tests against Inngest functions).

Next: **Part 9** covers `step.waitForEvent` — a human-in-the-loop task-approval workflow that pauses until a person acts, with a timeout fallback if they don't. Want me to bring that up next?
