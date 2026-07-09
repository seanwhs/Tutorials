# Part 11: Observability, Logging, and Testing

## 1. Reading the Inngest Dev Server dashboard effectively

You've been using this throughout, but here's a fuller tour:

- **Functions tab** — every registered function, its trigger, and a manual **Invoke** button (great for cron functions and one-off testing, seen in Part 8).
- **Runs tab** — every function run, filterable by function/status. Click into a run to see a timeline: each step, its duration, its input/output, and (if failed) the error and stack trace.
- **Stream/Events tab** — every event received, regardless of whether any function reacted to it. Useful for confirming an event was actually sent (e.g. from a Server Action) even if you're not sure which function should pick it up.
- **Rerun button** — on a completed or failed run's detail page, re-executes the function. Memoized steps return instantly; only steps after the point of failure actually re-run (demonstrated in Part 4).

## 2. Structured logging inside functions

Use the `logger` provided in the function context instead of raw `console.log` — it integrates with Inngest's tracing so log lines are attached to the correct run/step in the dashboard:

```ts
export const sendTaskAssignedEmail = inngest.createFunction(
  { id: "send-task-assigned-email" },
  { event: "task/task.assigned" },
  async ({ event, step, logger }) => {
    logger.info("Processing task assignment", { taskId: event.data.taskId });

    const assignee = await step.run("get-assignee", async () => {
      return prisma.user.findUniqueOrThrow({ where: { id: event.data.assigneeUserId } });
    });

    logger.info("Found assignee", { email: assignee.email });

    // ... rest of function
  }
);
```

Keep logging calls outside `step.run` lightweight and side-effect-free (just logging, no writes) since, like everything outside a step, they re-execute on every replay.

## 3. Adding error context

When a step throws, attach useful context so the dashboard's error view is actually actionable:

```ts
await step.run("send-email", async () => {
  try {
    await resend.emails.send({ /* ... */ });
  } catch (err) {
    logger.error("Failed to send task-assigned email", {
      taskId: event.data.taskId,
      assigneeEmail: assignee.email,
      error: err instanceof Error ? err.message : String(err),
    });
    throw err; // re-throw so Inngest still records/retries the failure
  }
});
```

## 4. Testing Inngest functions

Inngest functions are just async functions with a specific shape — you can unit test the *business logic* by extracting it from the Inngest wrapper, or use Inngest's `InngestTestEngine` (from `@inngest/test`) to test the full function including steps.

Install the test package:

```bash
pnpm add -D @inngest/test vitest
```

Example test for `sendTaskAssignedEmail` using `@inngest/test`, in `src/inngest/functions/tasks.test.ts`:

```ts
import { InngestTestEngine } from "@inngest/test";
import { describe, it, expect, vi } from "vitest";
import { sendTaskAssignedEmail } from "./tasks";

vi.mock("@/lib/prisma", () => ({
  prisma: {
    user: { findUniqueOrThrow: vi.fn().mockResolvedValue({ id: "u1", email: "a@test.com", firstName: "Ada" }) },
    task: { findUniqueOrThrow: vi.fn().mockResolvedValue({ id: "t1", title: "Write docs" }) },
  },
}));

vi.mock("@/lib/email", () => ({
  resend: { emails: { send: vi.fn().mockResolvedValue({ id: "email_1" }) } },
  FROM_ADDRESS: "TaskFlow <test@test.com>",
}));

describe("sendTaskAssignedEmail", () => {
  it("sends an email to the assignee", async () => {
    const t = new InngestTestEngine({ function: sendTaskAssignedEmail });

    const { result } = await t.execute({
      events: [{ name: "task/task.assigned", data: { taskId: "t1", assigneeUserId: "u1" } }],
    });

    expect(result).toBeUndefined(); // this function has no explicit return value
  });
});
```

`InngestTestEngine` runs your function locally (no Dev Server or network needed), executing real steps against your mocked dependencies, and lets you assert on the final result or individual step outputs. This is the recommended approach for CI — fast, no external services required.

## 5. A simpler alternative: extract pure logic

For business logic with real branching (like the digest filter in Part 8), it's often simpler and more robust to extract the pure decision logic into a plain function you can unit test directly, with no Inngest involved at all:

```ts
// src/lib/digest-rules.ts
export function usersNeedingDigest<T extends { tasksAssigned: unknown[] }>(users: T[]): T[] {
  return users.filter((u) => u.tasksAssigned.length > 0);
}
```

```ts
// src/lib/digest-rules.test.ts
import { describe, it, expect } from "vitest";
import { usersNeedingDigest } from "./digest-rules";

describe("usersNeedingDigest", () => {
  it("excludes users with zero open tasks", () => {
    const users = [{ tasksAssigned: [] }, { tasksAssigned: [{}] }];
    expect(usersNeedingDigest(users)).toHaveLength(1);
  });
});
```

Then the Inngest function itself just calls `usersNeedingDigest(users)` — the risky branching logic is fully unit tested, and the Inngest wrapper only needs light integration testing (or manual Dev Server invocation) since it's mostly plumbing.

## Checkpoint

- [ ] Comfortable navigating Functions, Runs, Stream, and using Rerun in the Dev Server dashboard
- [ ] Replaced `console.log` with the provided `logger` in at least one function
- [ ] Installed `@inngest/test` and `vitest`, written at least one test using `InngestTestEngine`
- [ ] Extracted at least one piece of pure business logic (e.g. `usersNeedingDigest`) for simple unit testing

## Troubleshooting

**`InngestTestEngine` test hangs or times out.** Make sure every external dependency your function's steps call (Prisma, Resend) is mocked — real network/database calls in tests are slow and flaky, and defeat the purpose of fast unit tests.

**Logs don't appear in the dashboard.** Confirm you're using the `logger` from the function's destructured context (`async ({ step, logger }) => ...`), not a bare imported logger — only the context-provided logger is wired into Inngest's tracing.

Next: **Part 12** deploys TaskFlow to Vercel and connects production Inngest Cloud — the final step to a live, working app. Want me to bring that up next?
