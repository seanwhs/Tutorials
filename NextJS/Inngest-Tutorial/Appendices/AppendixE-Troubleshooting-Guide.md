# Appendix E: Troubleshooting Guide

Common issues encountered while building TaskFlow, organized by category, with fixes.

## Inngest Dev Server / local setup

**Symptom**: "Discovering apps..." never finds your app.
- Confirm `pnpm dev` is running first, on port 3000, before starting `npx inngest-cli@latest dev`.
- If using a non-default port, run `npx inngest-cli@latest dev -u http://localhost:<port>/api/inngest`.

**Symptom**: Functions don't show up in the Dev Server dashboard.
- Confirm the function is included in the `functions: [...]` array passed to `serve()` in `src/app/api/inngest/route.ts`.
- Check for typos in import paths — a function defined but never imported into the route simply won't exist from Inngest's perspective.

**Symptom**: Nothing happens when sending a test event from the dashboard.
- Confirm the `"name"` field exactly matches the function's trigger event name, including case and namespace prefix.

## Steps and durability

**Symptom**: A step re-runs its side effect on every retry even though it "succeeded" before.
- Make sure the step actually returned normally (no thrown error) — if a *later* step in the same function fails, only steps after the last successful one re-run; already-succeeded steps stay memoized. If you're seeing a genuinely-completed step re-execute, double-check you're looking at a fresh new run, not a rerun of the same one.

**Symptom**: Non-deterministic values (timestamps, random IDs) differ between what you expect and what a step receives after a replay.
- Any code *outside* `step.run` re-executes on every replay. Move any `Date.now()`, `Math.random()`, or similar calls that matter for business logic *inside* a `step.run` so they get memoized too.

## Clerk webhook issues

**Symptom**: Webhook shows "Invalid signature."
- Confirm `CLERK_WEBHOOK_SECRET` matches the *signing secret* for that specific endpoint — Clerk generates a unique secret per webhook endpoint (local ngrok vs. production each have their own).

**Symptom**: No Inngest run appears after signing up a new user.
- Check the ngrok terminal for incoming requests. If nothing shows, the webhook URL configured in Clerk is stale — ngrok's free-tier URL changes every restart, so update Clerk's endpoint config each time you restart ngrok.

## Database / Prisma issues

**Symptom**: Prisma Client import errors or stale types after a schema change.
- Re-run `npx prisma generate` after any `schema.prisma` edit, then restart `pnpm dev` — the generated client is cached at module load time.

**Symptom**: "Not authenticated" errors even when signed in via Clerk.
- `getCurrentDbUser()` looks up by `clerkId` in your own database — if the Clerk webhook never successfully ran for that account (check Part 3's troubleshooting above), no matching `User` row exists yet. Check with `npx prisma studio`.

## Email issues

**Symptom**: Emails not arriving.
- Check Resend's dashboard "Logs" tab first. The free-tier `onboarding@resend.dev` sender can only deliver to the email address associated with your own Resend account unless you verify a custom domain — for testing, sign up to TaskFlow using that same email address.

## Fan-out / notification issues

**Symptom**: `step.sendEvent` with an empty array produces no visible effect.
- Expected — a project with zero other members produces zero fan-out events; not a bug.

**Symptom**: Duplicate notifications appear after a retry.
- `step.sendEvent` is itself memoized like any other step — if it already succeeded once, a retry of the function won't re-send. If you're seeing genuine duplicates, check whether the *triggering* event itself was sent twice (e.g. a Server Action called twice due to a double form submit) — add an idempotency key (Part 10) to the event's `id` field to guard against this.

## Sleep / waitForEvent issues

**Symptom**: A function with `step.sleep` seems "stuck."
- It's not stuck — check the run's status in the dashboard; "Sleeping" is the correct, expected state. It resumes automatically once the duration elapses.

**Symptom**: `step.waitForEvent` resolves for the wrong entity (e.g. wrong task gets approved).
- Almost always a missing or incorrect `match` expression. Double-check it references the correct field path (e.g. `data.taskId`) and that the field exists with matching values on both the original triggering event and the incoming event.

**Symptom**: `step.waitForEvent` never resolves even after the expected action.
- Confirm the event actually sent (check the Dev Server's Stream/Events tab) and that its `data` field used for matching has the exact same value as the original triggering event — a subtly different ID (e.g. wrong task) will never satisfy the match, and the step will only resolve via its timeout instead.

## Reliability config issues

**Symptom**: Rate-limited runs seem to silently vanish.
- Expected behavior for `rateLimit` — excess triggers within the window are dropped, not queued. If you need "eventually run everything, just spread out," use `throttle` instead.

**Symptom**: Concurrency `key` seems to have no effect.
- Confirm the expression references a field that exists on the *triggering event* (e.g. `event.data.taskId`), not something only available later after a database read inside the handler.

## Testing issues

**Symptom**: `InngestTestEngine` test hangs or times out.
- Ensure every external dependency called inside a step (Prisma, Resend) is mocked — real network/database calls in tests are slow and defeat the purpose of fast unit tests.

## Deployment issues

**Symptom**: Functions don't appear in Inngest Cloud after deploying to Vercel.
- Confirm `INNGEST_SIGNING_KEY` is set correctly in Vercel's environment variables, redeploy, then manually trigger a sync from the Inngest Cloud dashboard's app settings page.

**Symptom**: Webhook 500s in production but works locally.
- Check Vercel's function logs for the actual error. A common cause: forgetting to set `CLERK_WEBHOOK_SECRET` for the *production* webhook endpoint specifically (it's per-endpoint, not shared with your local one).

**Symptom**: Emails work locally but not in production.
- Confirm `RESEND_API_KEY` is set in Vercel, and that you're not still hitting a Resend sandbox restriction limiting delivery to your own verified address only.

---

That's the complete series — **Part 0 through Part 12, the Conclusion, and Appendices A–E**, all covered end-to-end. 
