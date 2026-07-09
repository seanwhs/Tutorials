# Part 10: Reliability Controls (Retries, Idempotency, Concurrency, Rate Limiting, Throttling)

This part is a focused, practical reference on the controls Inngest gives you to make functions behave well in production. We'll apply each to functions already in TaskFlow.

## 1. Retries, revisited

Default: 4 retries (5 total attempts) with exponential backoff. Configure per function:

```ts
export const sendTaskAssignedEmail = inngest.createFunction(
  { id: "send-task-assigned-email", retries: 3 },
  { event: "task/task.assigned" },
  async ({ event, step }) => { /* ... */ }
);
```

Use `NonRetriableError` (seen in Part 4) for permanent failures you know retrying won't fix — this fails the run immediately instead of burning through retry attempts.

```ts
import { NonRetriableError } from "inngest";

await step.run("send-email", async () => {
  if (!isValidEmail(assignee.email)) {
    throw new NonRetriableError("Invalid email address, cannot send");
  }
  // ...
});
```

## 2. Idempotency keys

Every event can optionally carry an `id`. If you send two events with the *same* `id` within Inngest's idempotency window, the second is deduplicated — no new function run is triggered. This matters for webhooks that might redeliver the same event (Clerk, Stripe, etc. all can and do retry webhook deliveries).

Update the Clerk webhook function's event send in `src/app/api/webhooks/clerk/route.ts`:

```ts
await inngest.send({
  name: "app/user.created",
  id: `clerk-user-created-${data.id}`, // idempotency key
  data: { /* ... */ },
});
```

Now if Clerk redelivers the same `user.created` webhook (e.g. because your endpoint was briefly slow), Inngest recognizes the duplicate `id` and skips re-triggering `syncUserOnCreate` and `onboardingEmailDrip` a second time — even though the webhook route itself ran twice.

You can also set idempotency at the function level, deduping runs based on event data over a rolling time window, using the `idempotency` config option:

```ts
export const sendTaskAssignedEmail = inngest.createFunction(
  {
    id: "send-task-assigned-email",
    idempotency: "event.data.taskId", // dedupe key expression
  },
  { event: "task/task.assigned" },
  async ({ event, step }) => { /* ... */ }
);
```

This deduplicates runs of *this specific function* within a short rolling window (a few minutes) if the same `taskId` triggers it again — useful defense-in-depth alongside `upsert`-style database writes.

## 3. Concurrency limits

Prevent a function from overwhelming a downstream resource (e.g. your database, or a third-party API with rate limits) by capping how many instances of it run at once:

```ts
export const createNotificationRow = inngest.createFunction(
  {
    id: "create-notification-row",
    concurrency: { limit: 10 },
  },
  { event: "notification/member.notify" },
  async ({ event, step }) => { /* ... */ }
);
```

Now, even if a fan-out sends 500 `notification/member.notify` events at once, only 10 `createNotificationRow` runs execute simultaneously — the rest queue and run as capacity frees up. No code changes needed inside the handler; Inngest manages the queueing.

You can scope concurrency per-key (e.g. per project, so one huge project's fan-out doesn't starve other projects' notifications):

```ts
concurrency: { limit: 5, key: "event.data.taskId" }
```

This limits concurrency to 5 *per unique `taskId`*, rather than 5 globally across all tasks.

## 4. Rate limiting

Rate limiting caps how many times a function can *start* within a time window, and simply drops/skips excess triggers rather than queueing them (different from concurrency, which queues and eventually runs everything). Useful for things like "at most 1 digest email per user per day" even if something bugs out and fires the event repeatedly:

```ts
export const sendDigestEmail = inngest.createFunction(
  {
    id: "send-digest-email",
    rateLimit: { limit: 1, period: "1h", key: "event.data.userId" },
  },
  { event: "email/digest.requested" },
  async ({ event, step }) => { /* ... */ }
);
```

This means: at most 1 run per unique `userId` per rolling hour. Additional matching events within that window are simply not executed at all (not queued, not retried later) — appropriate here since a digest is time-sensitive and a "catch-up" digest an hour later wouldn't make sense.

## 5. Throttling

Throttling is like rate limiting but **queues** excess triggers to run later instead of dropping them — appropriate when you must eventually process every event, just not too fast. Good for calling a third-party API with a strict requests-per-minute limit:

```ts
export const sendTaskAssignedEmail = inngest.createFunction(
  {
    id: "send-task-assigned-email",
    throttle: { limit: 10, period: "1m" },
  },
  { event: "task/task.assigned" },
  async ({ event, step }) => { /* ... */ }
);
```

This ensures at most 10 runs start per minute; any beyond that wait in queue and run in subsequent minutes, rather than being dropped like rate limiting would do.

## 6. Choosing the right control — quick decision guide

| Need | Use |
|---|---|
| Cap simultaneous executions to protect a downstream resource | `concurrency` |
| Drop excess triggers beyond a hard cap in a window (stale ones don't matter) | `rateLimit` |
| Smooth out bursts while still eventually processing everything | `throttle` |
| Prevent duplicate runs from the same logical event (webhook redelivery) | Event `id` (idempotency key) |
| Prevent duplicate runs of the same function for the same business entity in a short window | Function-level `idempotency` |
| A step's own failure shouldn't retry (permanent/bad-input error) | `NonRetriableError` |
| Tune how many times transient failures get retried | `retries` config |

## 7. Apply these to TaskFlow

Update your functions from earlier parts:

- `createNotificationRow`: add `concurrency: { limit: 10 }`
- `sendDigestEmail`: add `rateLimit: { limit: 1, period: "1h", key: "event.data.userId" }`
- `sendTaskAssignedEmail`: add `throttle: { limit: 10, period: "1m" }`
- Clerk webhook event send: add the `id: \`clerk-user-created-${data.id}\`` idempotency key

## Checkpoint

- [ ] Understand the difference between concurrency, rate limiting, and throttling
- [ ] Added an idempotency key to the Clerk webhook's event send
- [ ] Added `concurrency` to `createNotificationRow`
- [ ] Added `rateLimit` to `sendDigestEmail`
- [ ] Added `throttle` to `sendTaskAssignedEmail`
- [ ] Know when to reach for `NonRetriableError` vs. letting default retries handle a failure

## Troubleshooting

**Rate-limited runs seem to silently vanish.** That's expected behavior for `rateLimit` — excess triggers within the window are dropped, not queued. If you need "eventually run everything, just slower," use `throttle` instead.

**Concurrency key seems to have no effect.** Double check the expression syntax — it must reference a field that exists on the *triggering event* (e.g. `event.data.taskId`), not on database state fetched later inside the handler.

Next: **Part 11** covers observability — reading the dashboard effectively, structured logging, and writing automated tests for your Inngest functions. Want me to bring that up next?
