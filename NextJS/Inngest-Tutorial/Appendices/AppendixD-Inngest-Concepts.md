# Appendix D: Inngest Concepts Cheat Sheet

## Core vocabulary

| Term | Definition |
|---|---|
| Event | A JSON payload (`{ name, data }`) describing something that happened. Sent via `inngest.send()`. |
| Function | A durable handler triggered by an event or a cron schedule, created via `inngest.createFunction()`. |
| Step | A unit of work inside a function (`step.run`, `step.sleep`, etc.) whose result is checkpointed/memoized. |
| Run | One execution instance of a function, triggered by one event (or one cron tick). |
| Dev Server | Local tool (`npx inngest-cli@latest dev`) simulating Inngest's event bus + dashboard for development. |
| Inngest Cloud | The hosted, production version of the same event bus + scheduler + dashboard. |
| `serve()` handler | The one API route (`/api/inngest`) exposing all your functions to Inngest via GET/POST/PUT. |

## Function trigger types

```ts
// Event-triggered
inngest.createFunction({ id: "..." }, { event: "some/event.name" }, handler);

// Cron-triggered
inngest.createFunction({ id: "..." }, { cron: "0 8 * * *" }, handler);

// Multiple event triggers
inngest.createFunction({ id: "..." }, [{ event: "a" }, { event: "b" }], handler);

// Conditional trigger
inngest.createFunction({ id: "..." }, { event: "a", if: "event.data.x == 'y'" }, handler);
```

## Step types

| Method | Purpose |
|---|---|
| `step.run(id, fn)` | Run and memoize an arbitrary async function's result. |
| `step.sleep(id, duration)` | Pause for a relative duration (`"10 minutes"`, `"3 days"`). |
| `step.sleepUntil(id, date)` | Pause until an absolute date/time. |
| `step.waitForEvent(id, { event, timeout, match })` | Pause until a matching event arrives or timeout elapses; resolves to the event or `null`. |
| `step.sendEvent(id, events)` | Send one or more events as a memoized step (supports batching an array). |
| `step.invoke(id, { function, data })` | Directly invoke another Inngest function and wait for its result (not covered in the main series, but useful for composing functions synchronously). |

## Function config options

```ts
inngest.createFunction(
  {
    id: "my-function",             // required, unique, stable
    retries: 3,                     // max retry attempts (default 4)
    concurrency: { limit: 10, key: "event.data.projectId" }, // cap simultaneous runs
    rateLimit: { limit: 1, period: "1h", key: "event.data.userId" }, // drop excess triggers
    throttle: { limit: 10, period: "1m" }, // queue excess triggers, smooth bursts
    idempotency: "event.data.taskId", // dedupe runs by expression over a rolling window
    batchEvents: { maxSize: 100, timeout: "5s" }, // (not used in main series) batch multiple events into one run
  },
  trigger,
  handler
);
```

## Errors

| Tool | Use case |
|---|---|
| Throwing a normal `Error` | Transient failure — Inngest retries per the `retries` config with backoff |
| `NonRetriableError` (from `"inngest"`) | Permanent failure — Inngest fails the run immediately, no retries |
| `step.waitForEvent` resolving to `null` | Timeout elapsed with no matching event — not an error, handle it as a valid branch |

## Idempotency: two mechanisms, don't confuse them

1. **Event-level idempotency key**: `inngest.send({ name, data, id: "stable-key" })` — dedupes at the *event* level. A second `send()` with the same `id` within the window triggers no new runs at all, for any function.
2. **Function-level `idempotency` config**: dedupes at the *function run* level, based on an expression over the triggering event's data, within a rolling window — even if the events themselves have different auto-generated IDs.

## Concurrency vs. rate limiting vs. throttling (recap table)

| Control | Excess triggers | Best for |
|---|---|---|
| `concurrency` | Queued, run when a slot frees up | Protecting a downstream resource (DB pool, 3rd-party API concurrency limit) |
| `rateLimit` | Dropped entirely | Hard caps where a "late" execution has no value (e.g. one digest per hour) |
| `throttle` | Queued, spread over time | Smoothing bursts against a strict requests-per-minute API limit |

## The mental model in one sentence

Write your function's logic as plain, linear async/await code using `step.*` for anything that should survive a crash or a multi-day wait; Inngest replays your handler from the top on every resume, instantly returning memoized step results until it reaches the next step that actually needs to execute.

---

Last one is **Appendix E: Troubleshooting Guide** — want me to bring that up?
