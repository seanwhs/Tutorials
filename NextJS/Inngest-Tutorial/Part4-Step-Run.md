# Part 4: step.run Deep Dive and Welcome Emails with Resend

## 1. Why `step.run` matters (the mental model)

Every `step.run(name, fn)` call is a checkpoint. Inngest persists the **return value** of `fn` after it succeeds. If your function later throws (say, on step 3 of 4) and Inngest retries the whole function from the top, steps 1 and 2 do **not** re-execute their callbacks — Inngest instantly returns their previously-saved results ("memoization"), and only step 3 actually re-runs.

This means:
- Each `step.run` should be **idempotent** or side-effect-safe to re-run, OR wrapped so it only ever truly executes once (memoized).
- Steps should be reasonably small, single-purpose units: "create the row," "call the email API," "update a flag" — not one giant step doing five things.
- Never put non-deterministic values (like `Date.now()` or `Math.random()`) *outside* a `step.run` if the result needs to be consistent across replays — compute them *inside* a step so the value gets memoized too.

## 2. Rule: don't put side effects outside step.run

Bad (runs on every replay, not memoized):

```ts
async ({ event, step }) => {
  console.log("about to process", event.data.userId); // fine, logging is harmless
  const now = new Date(); // BAD if used for business logic - recomputed on every replay
  await step.run("create-thing", async () => { ... });
}
```

Good:

```ts
async ({ event, step }) => {
  const { now } = await step.run("get-current-time", async () => ({ now: new Date().toISOString() }));
  await step.run("create-thing", async () => { /* use `now` */ });
}
```

Any code *outside* `step.run` executes on every single replay of the function (Inngest re-runs your handler from the top each time, skipping memoized steps). Keep code outside steps limited to reading `event.data` and basic control flow (if/else, loops that call step.run) — no API calls, no DB writes, no `Date.now()`/`Math.random()` used for logic outside a step.

## 3. Install Resend

```bash
pnpm add resend
```

Sign up at resend.com (free tier: 100 emails/day, 3,000/month), grab an API key:

```
RESEND_API_KEY=re_xxx
```

Create `src/lib/email.ts`:

```ts
import { Resend } from "resend";

export const resend = new Resend(process.env.RESEND_API_KEY);

export const FROM_ADDRESS = "TaskFlow <onboarding@resend.dev>";
// Once you verify your own domain in Resend, switch to e.g. "TaskFlow <noreply@yourdomain.com>"
```

## 4. Extend the user-sync function with a welcome email step

Update `src/inngest/functions/users.ts`:

```ts
import { inngest } from "../client";
import { prisma } from "@/lib/prisma";
import { resend, FROM_ADDRESS } from "@/lib/email";

export const syncUserOnCreate = inngest.createFunction(
  { id: "sync-user-on-create" },
  { event: "app/user.created" },
  async ({ event, step }) => {
    const user = await step.run("upsert-user-in-db", async () => {
      return prisma.user.upsert({
        where: { clerkId: event.data.clerkId },
        update: {
          email: event.data.email,
          firstName: event.data.firstName,
          lastName: event.data.lastName,
        },
        create: {
          clerkId: event.data.clerkId,
          email: event.data.email,
          firstName: event.data.firstName,
          lastName: event.data.lastName,
        },
      });
    });

    await step.run("send-welcome-email", async () => {
      await resend.emails.send({
        from: FROM_ADDRESS,
        to: event.data.email,
        subject: "Welcome to TaskFlow!",
        html: `<p>Hi ${event.data.firstName ?? "there"},</p><p>Welcome to TaskFlow — let's get your first project set up.</p>`,
      });
    });

    return { userId: user.id };
  }
);
```

Two separate named steps: `upsert-user-in-db` and `send-welcome-email`. Why not combine them into one step? Because if the email send fails (Resend down, rate limited) and the function retries, we do **not** want to re-run the DB upsert unnecessarily (it's harmless here since it's an upsert, but in general, splitting into small steps means only the failed step retries — the DB write already succeeded and stays memoized, saving time and avoiding redundant work).

## 5. Watch it fail and retry (on purpose)

Let's prove the checkpointing model works. Temporarily break the email step to force a failure:

```ts
await step.run("send-welcome-email", async () => {
  if (Math.random() < 1) throw new Error("Simulated Resend outage");
  await resend.emails.send({ ... });
});
```

Sign up a new test user (or re-send the `app/user.created` event manually from the Dev Server dashboard with a fresh `clerkId`). Watch the **Runs** tab: `sync-user-on-create` will show `upsert-user-in-db` completed instantly and stay green, while `send-welcome-email` shows failed attempts, retrying automatically (default: 4 retries with exponential backoff) before the whole run is marked Failed. Click into the run to see each retry attempt individually.

Now revert your change (remove the `throw`), and manually **Rerun** the failed run from the dashboard (button on the run detail page). You'll see `upsert-user-in-db` complete **instantly** (memoized, not re-executed) while only `send-welcome-email` actually runs this time and succeeds. This is the entire value proposition of Inngest in one demo: failures self-heal without redoing completed work.

## 6. Configuring retry behavior per function

You can tune retries in the function config:

```ts
export const syncUserOnCreate = inngest.createFunction(
  { id: "sync-user-on-create", retries: 2 },
  { event: "app/user.created" },
  async ({ event, step }) => { /* ... */ }
);
```

`retries` is the max number of retry attempts (default 4, so 5 total attempts including the first). We'll revisit retry tuning, `NonRetriableError`, and backoff in Part 10.

## 7. Non-retriable errors

Sometimes a failure is *permanent* and retrying is pointless (e.g. malformed data, invalid email address). Use `NonRetriableError` to skip retries and fail fast:

```ts
import { NonRetriableError } from "inngest";

await step.run("send-welcome-email", async () => {
  if (!event.data.email) {
    throw new NonRetriableError("User has no email address, cannot send welcome email");
  }
  await resend.emails.send({ /* ... */ });
});
```

## Checkpoint

- [ ] You understand why side effects must live inside `step.run`, not outside
- [ ] Welcome email step added, using Resend, wrapped in its own named step
- [ ] You deliberately broke and watched a step retry, then rerun successfully with the DB step staying memoized
- [ ] You understand `retries` config and `NonRetriableError`

## Troubleshooting

**Emails not arriving.** Check Resend's dashboard "Logs" tab — free tier `onboarding@resend.dev` sender only delivers to the email address you signed up to Resend with, unless you verify your own domain. For testing, sign up to TaskFlow using that same email.

**Retries happen instantly with no backoff visible.** That's expected in the Dev Server for very fast local failures — backoff delays are still applied but may be short; in production/Cloud you'll see longer gaps between attempts.

Next: **Part 5** builds the actual Projects and Tasks UI so we have real triggers for the fan-out and scheduling patterns coming in Parts 6-9 — want me to bring that up next?
