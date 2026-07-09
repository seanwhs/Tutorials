# Appendix E: Troubleshooting Guide

## Next.js 16 specific issues

**TypeScript error:** `Property 'id' does not exist on type 'Promise<{ id: string }>'`
- You forgot `await params`. Fix: `const { id } = await params;` — the single most common mistake if coming from an older Next.js version.

**`next dev`/`pnpm create next-app` fails with engine/version errors**
- Check `node -v` — Next.js 16 needs 20.9+/22 LTS. Upgrade: `nvm install 22 && nvm use 22`.

**Tailwind classes don't apply / errors about missing `tailwind.config.ts`**
- No config file is correct for v4 — CSS-first config. Confirm `globals.css` starts with `@import "tailwindcss";` and remove any stray `tailwind.config.*` or `@tailwind base/components/utilities` directives from an older v3 tutorial.

**`headers()`/`cookies()` throws calling `.get()` on a Promise**
- Same root cause — both are async in Next.js 16. Always `const headerPayload = await headers();` first (Part 7's webhook route).

**Confusion about Turbopack**
- On by default for `next dev`/`next build`, nothing to configure. If you see Webpack in build output, confirm your Next.js version is actually 16.

## Environment variables
- `DATABASE_URL` errors → check pooled connection string + `?sslmode=require`, regenerate if password rotated, confirm `.env.local` at project root
- Drizzle Kit "DATABASE_URL is not defined" → `drizzle.config.ts` needs its own `dotenv` call
- Clerk "Missing publishable key" → confirm var set + restarted `pnpm dev`

## Clerk webhook issues
- No `users` row on signup → check ngrok is running/URL matches Clerk's registered endpoint (changes every ngrok restart), check Message Attempts, confirm `CLERK_WEBHOOK_SECRET` matches current endpoint
- "Invalid signature" → secret doesn't match the calling endpoint

## Timezone/date issues
- Off-by-hours display → confirm `timestamp with time zone` columns, `datetime-local` → UTC conversion via `new Date(...)`, `.toLocaleString()` correctly shows viewer's local time

## Inngest issues
- Functions missing from Dev Server → confirm `pnpm dev` on port 3000, function added to `functions` array
- Run fails with no error → check Next.js terminal directly
- Cron never runs in production → confirm production URL added + synced in Inngest dashboard, `INNGEST_SIGNING_KEY`/`INNGEST_EVENT_KEY` set in Vercel

## Email issues
- Confirmation never arrives → check spam (esp. `onboarding@resend.dev`), Resend dashboard Logs, API key validity
- Reminder sends twice → confirm idempotency keys present, confirm `reminder_sent_at` actually gets set

## QR code/check-in issues
- Camera won't start → needs HTTPS or `localhost` (not a LAN IP over HTTP); confirm camera permission granted
- False "already checked in" → check `check_ins` table for stray test rows

## Authorization issues
- "You do not manage this event" incorrectly → confirm same browser session/account; confirm `isAdmin` truly `true` if testing admin override

## Deployment issues (Vercel)
- Build fails on Vercel but not locally → run `pnpm build` locally first; check all build-time env vars set; confirm Node 20.x/22.x configured
- Clerk/webhooks/Inngest don't work in production → missed Part 23 step: production needs its own webhook endpoint + Inngest registration

## General debugging tips
- `pnpm db:studio` to inspect real DB state
- Inngest Dev Server **Runs** tab for step failures
- Server logs appear in the `pnpm dev` terminal, not the browser console
- **When in doubt: "did I await this?"** — `params`, `searchParams`, `headers()`, `cookies()`, Clerk's `auth()`/`currentUser()` are all Promises, no exceptions
