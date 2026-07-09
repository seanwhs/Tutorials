# Part 7: Multi-Day Onboarding Drip with step.sleep

## 1. The problem this solves

Imagine you want to email a new user: immediately (welcome, done in Part 4), again after 1 day ("here's a tip"), and again after 3 days ("here's what you're missing"). Doing this with `setTimeout` is impossible across serverless invocations — the process doesn't live that long. You'd normally need a database table of "pending scheduled emails" plus a cron job polling it.

Inngest's `step.sleep` and `step.sleepUntil` let you write this as one linear function that "pauses" for days, without any server staying online. Inngest suspends the function and wakes it back up exactly when the sleep ends — your Vercel function isn't running (and costing you anything) during the sleep at all.

## 2. Add the onboarding drip function

Add to `src/inngest/functions/users.ts`:

```ts
export const onboardingEmailDrip = inngest.createFunction(
  { id: "onboarding-email-drip" },
  { event: "app/user.created" },
  async ({ event, step }) => {
    // Day 0 tip, a few minutes after welcome email so it doesn't feel like spam
    await step.sleep("wait-before-first-tip", "10 minutes");

    await step.run("send-tip-1-email", async () => {
      await resend.emails.send({
        from: FROM_ADDRESS,
        to: event.data.email,
        subject: "Tip: create your first project",
        html: `<p>Quick tip — head to TaskFlow and create your first project to get organized.</p>`,
      });
    });

    // Wait until day 3 for a follow-up
    await step.sleep("wait-until-day-3", "3 days");

    const stillNoProjects = await step.run("check-if-user-has-projects", async () => {
      const user = await prisma.user.findUnique({
        where: { clerkId: event.data.clerkId },
        include: { projects: true },
      });
      return (user?.projects.length ?? 0) === 0;
    });

    if (stillNoProjects) {
      await step.run("send-nudge-email", async () => {
        await resend.emails.send({
          from: FROM_ADDRESS,
          to: event.data.email,
          subject: "Still there? Let's set up your first project",
          html: `<p>We noticed you haven't created a project yet — need help getting started?</p>`,
        });
      });
    }

    return { completed: true };
  }
);
```

Notice this is a **separate function** from `syncUserOnCreate`, even though both trigger on `app/user.created`. Keeping the drip separate means a slow multi-day function doesn't block or complicate the fast, important user-creation logic — they run entirely independently and can fail/retry independently.

Also notice the **conditional send** at the end: we re-check the database *after* the sleep, inside a fresh `step.run`, rather than checking once at the start. This is important — 3 days is a long time, and the whole point of checking again is to react to the *current* state of the world, not stale data captured before the sleep began.

## 3. `step.sleep` vs `step.sleepUntil`

- `step.sleep(id, duration)` — relative duration: `"10 minutes"`, `"3 days"`, or a number of milliseconds.
- `step.sleepUntil(id, date)` — sleep until an absolute `Date` or ISO timestamp. Useful when you have a specific target time, e.g. a task's due date:

```ts
await step.sleepUntil("wait-until-due-date", task.dueDate);
```

Both suspend the function durably — Inngest persists exactly where you are in the function and the wake-up time, then resumes execution from that exact point later, re-entering your handler and skipping already-completed steps via memoization, same as any other step.

## 4. Register the function

Add `onboardingEmailDrip` to the `functions` array in `src/app/api/inngest/route.ts`.

## 5. Speed up testing with shorter durations

Waiting 3 real days to test is impractical. Temporarily change durations to `"30 seconds"` and `"2 minutes"` while developing, then change back before shipping. Alternatively, the Inngest Dev Server dashboard lets you inspect a sleeping run and see its scheduled resume time directly — open the **Runs** tab, click into the run, and you'll see a "Sleeping until ..." status with a countdown.

## 6. Test it

1. Temporarily shorten the sleeps as above.
2. Sign up a new test user.
3. Watch the Runs tab: `onboarding-email-drip` starts, immediately shows "Sleeping" status for the first duration, then wakes and runs `send-tip-1-email`, sleeps again, wakes, checks projects, conditionally sends the nudge.
4. Confirm in your inbox (or Resend's dashboard Logs) that the tip email arrived, and that the nudge email only arrives if you haven't created a project for that test user.

## Checkpoint

- [ ] `onboardingEmailDrip` function created, separate from `syncUserOnCreate`
- [ ] Understand `step.sleep` (relative) vs `step.sleepUntil` (absolute)
- [ ] Watched a function pause ("Sleeping" status) and automatically resume in the Dev Server dashboard
- [ ] Confirmed the day-3 check re-reads the database rather than relying on stale state from before the sleep
- [ ] Reverted sleep durations back to realistic values (`10 minutes`, `3 days`) after testing

## Troubleshooting

**Function seems "stuck".** It's not stuck — check the run's status in the dashboard; "Sleeping" is expected and correct. It will resume automatically once the duration elapses (or immediately if you shortened it for testing and enough real time has passed).

**Restarting the Dev Server loses sleeping runs.** The local Dev Server persists state in memory by default between restarts in some versions — if a sleeping run disappears after you restart `inngest-cli dev`, that's a local-dev-only limitation; production Inngest Cloud persists sleep state durably regardless of your app's deploys/restarts.

Next: **Part 8** covers scheduled (cron) functions — a daily digest email and an overdue-task sweep, running on a timer rather than being triggered by an event. Want me to bring that up next?
