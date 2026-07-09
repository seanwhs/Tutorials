# Part 2: Events, Functions, and the Serve Route Deep Dive

In Part 1 you built one function triggered by one event. Real apps have many events and many functions, often with more complex relationships between them. This part covers that in depth before we start building TaskFlow's real features in Part 3.

## 1. Anatomy of an event

An Inngest event is just JSON with a required shape:

```ts
type Event = {
  name: string;        // e.g. "app/user.created" - namespace/subject.verb convention
  data: Record<string, unknown>;  // your payload
  user?: Record<string, unknown>; // optional, attached user context (e.g. { email })
  id?: string;          // optional, YOU can set this for idempotency (see Part 10)
  ts?: number;          // optional, timestamp override
};
```

**Naming convention**: `<namespace>/<subject>.<verb>`, e.g. `app/user.created`, `task/task.assigned`, `email/welcome.requested`. Namespacing avoids collisions as your app grows. We'll use `app/`, `task/`, `project/`, and `email/` prefixes throughout TaskFlow.

## 2. Sending events

Anywhere in server-side code (Server Actions, Route Handlers, Inngest functions themselves):

```ts
import { inngest } from "@/inngest/client";

await inngest.send({
  name: "task/task.created",
  data: { taskId: "abc123", projectId: "proj1" },
});
```

You can send **multiple events at once** (batched, single network call):

```ts
await inngest.send([
  { name: "task/task.created", data: { taskId: "abc123" } },
  { name: "email/notification.requested", data: { taskId: "abc123" } },
]);
```

## 3. Multiple functions can listen to the same event (fan-out)

This is one of Inngest's most useful patterns. Say `task/task.created` fires. You might want to: (a) notify assignees, AND (b) update a project activity log — as two completely separate, independently-retried functions:

```ts
export const notifyOnTaskCreated = inngest.createFunction(
  { id: "notify-on-task-created" },
  { event: "task/task.created" },
  async ({ event, step }) => {
    await step.run("send-notification", async () => {
      console.log("Notifying about task", event.data.taskId);
    });
  }
);

export const logTaskActivity = inngest.createFunction(
  { id: "log-task-activity" },
  { event: "task/task.created" },
  async ({ event, step }) => {
    await step.run("write-log", async () => {
      console.log("Logging activity for task", event.data.taskId);
    });
  }
);
```

Both functions run independently when `task/task.created` fires. If `notifyOnTaskCreated` fails and retries, `logTaskActivity` is completely unaffected. This decoupling is much simpler than manually orchestrating multiple side effects inside one API route.

## 4. One function can match multiple events

Use an array, or add conditional logic:

```ts
export const auditLogger = inngest.createFunction(
  { id: "audit-logger" },
  [{ event: "task/task.created" }, { event: "task/task.deleted" }],
  async ({ event, step }) => {
    await step.run("write-audit-entry", async () => {
      console.log(`Audit: ${event.name}`, event.data);
    });
  }
);
```

Inside the handler, `event.name` tells you which of the two fired.

## 5. Event payload typing (recommended from day one)

Rather than `Record<string, unknown>` everywhere, define your event schema once and get full type-safety on both `inngest.send()` and every function's `event.data`. Update `src/inngest/client.ts`:

```ts
import { EventSchemas, Inngest } from "inngest";

type Events = {
  "test/hello.world": {
    data: { name?: string };
  };
  "task/task.created": {
    data: { taskId: string; projectId: string; createdByUserId: string };
  };
  "task/task.assigned": {
    data: { taskId: string; assigneeUserId: string };
  };
  "app/user.created": {
    data: { userId: string; email: string; firstName: string | null };
  };
};

export const inngest = new Inngest({
  id: "taskflow",
  schemas: new EventSchemas().fromRecord<Events>(),
});
```

Now `inngest.send({ name: "task/task.created", data: { ... } })` is type-checked, and every function's `event.data` is fully typed based on its trigger. We'll keep expanding this `Events` type as we add features in later parts — treat it as the single source of truth for every event in TaskFlow.

## 6. Conditional triggers (`if`)

You can filter which events actually trigger a function, without writing the check yourself, using an `if` expression on the trigger:

```ts
export const notifyHighPriorityOnly = inngest.createFunction(
  { id: "notify-high-priority-only" },
  { event: "task/task.created", if: "event.data.priority == 'high'" },
  async ({ event, step }) => {
    await step.run("notify", async () => {
      console.log("High priority task created:", event.data.taskId);
    });
  }
);
```

The `if` string is a small expression language (CEL-like) evaluated against the event — cheap filtering before your function even starts, useful for high-volume events where most runs should be skipped.

## 7. The `serve` route, revisited

Update `src/app/api/inngest/route.ts` to register all functions we've built so far:

```ts
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { helloWorld, notifyOnTaskCreated, logTaskActivity, auditLogger } from "@/inngest/functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [helloWorld, notifyOnTaskCreated, logTaskActivity, auditLogger],
});
```

As TaskFlow grows, this array will get long. From Part 3 onward we'll organize functions into separate files per feature (e.g. `src/inngest/functions/users.ts`, `src/inngest/functions/tasks.ts`) and import them all into this one route file — a common, scalable pattern.

## 8. Try it yourself

Add the two new functions and the audit logger to `src/inngest/functions.ts`, wire them into the route, restart both dev processes, and send a `task/task.created` event from the Dev Server dashboard:

```json
{
  "name": "task/task.created",
  "data": { "taskId": "t1", "projectId": "p1", "createdByUserId": "u1" }
}
```

You should see **two separate runs** appear in the Runs tab — one for `notify-on-task-created`, one for `log-task-activity` — both triggered by the single event you sent. This is fan-out in action, and it's the exact mechanism we'll use for real task-assignment notifications in Part 6.

## Checkpoint

- [ ] You understand event naming convention and payload shape
- [ ] You've typed your events via `EventSchemas().fromRecord<Events>()`
- [ ] You've registered 2+ functions listening to the same event and watched both fire from one `inngest.send()`
- [ ] You understand `if` conditional triggers
- [ ] The `serve` route lists every function you've defined

## Troubleshooting

**Type errors on `inngest.send()` after adding schemas.** Make sure the event name you're sending exactly matches a key in your `Events` type, including the namespace prefix.

**Only one of two functions listening to the same event ran.** Confirm both are added to the `functions` array in the `serve()` call — a function not registered there simply doesn't exist from Inngest's perspective, even if defined in your codebase.

Next: Part 3 starts building TaskFlow for real — Clerk auth, a Postgres schema via Prisma, and your first *real* event-driven Inngest function, triggered by a Clerk webhook.
