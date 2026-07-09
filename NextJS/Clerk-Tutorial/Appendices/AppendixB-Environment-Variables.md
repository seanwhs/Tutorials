# Appendix B: Environment Variables Reference

Every environment variable used across this series (built for Next.js 16), what it does, where to find its value, and whether it's safe to expose publicly.

## Clerk core keys

### `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
- **What:** Identifies your Clerk application to the frontend SDK.
- **Where to find it:** Clerk Dashboard → Configure → API Keys.
- **Safe to expose publicly?** Yes — the `NEXT_PUBLIC_` prefix means Next.js bundles this into client-side JavaScript by design. It's meant to be public, similar to how a Stripe "publishable key" works.
- **Format:** `pk_test_...` (development) or `pk_live_...` (production).
- **Introduced in:** Part 5.

### `CLERK_SECRET_KEY`
- **What:** Authenticates server-side requests to Clerk's backend API (used internally by `currentUser()`, `auth()`, webhook handling, etc.).
- **Where to find it:** Clerk Dashboard → Configure → API Keys.
- **Safe to expose publicly?** No — never prefix this with `NEXT_PUBLIC_`, never log it, never send it to the client. Treat it like a database password.
- **Format:** `sk_test_...` (development) or `sk_live_...` (production).
- **Introduced in:** Part 5.

## Redirect URL configuration

### `NEXT_PUBLIC_CLERK_SIGN_IN_URL`
- **What:** Tells Clerk components/hooks where your sign-in page lives, so links like "Already have an account? Sign in" work correctly, and so `auth.protect()` in middleware knows where to redirect unauthenticated users.
- **Value used in this tutorial:** `/sign-in`
- **Safe to expose publicly?** Yes — it's just a path, not a secret.
- **Introduced in:** Part 5.

### `NEXT_PUBLIC_CLERK_SIGN_UP_URL`
- **What:** Same idea, for the sign-up page.
- **Value used in this tutorial:** `/sign-up`
- **Introduced in:** Part 5.

### `NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL`
- **What:** Where to send a user immediately after they successfully sign in, overriding any other redirect logic.
- **Value used in this tutorial:** `/dashboard`
- **Introduced in:** Part 5.

### `NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL`
- **What:** Where to send a user immediately after they successfully sign up (and verify, if required).
- **Value used in this tutorial:** `/dashboard`
- **Introduced in:** Part 5.

## Webhooks

### `CLERK_WEBHOOK_SECRET`
- **What:** Used to cryptographically verify that incoming webhook requests to `/api/webhooks/clerk` genuinely came from Clerk (via Svix), and weren't forged by a malicious third party hitting your public endpoint.
- **Where to find it:** Clerk Dashboard → Webhooks → click your endpoint → shown at creation time (and re-visible if you regenerate it).
- **Safe to expose publicly?** No — treat as a secret, same caution as `CLERK_SECRET_KEY`.
- **Format:** `whsec_...`
- **Important:** You'll have a *different* value for your local development endpoint (registered against your ngrok URL) versus your production endpoint (registered against your Vercel URL) — don't mix them up. See Parts 13 and 14.
- **Reminder:** the route reading this value (`src/app/api/webhooks/clerk/route.ts`) also depends on correctly awaiting Next.js 16's async `headers()` function — see Part 13 and Appendix A (Note 4 of 4) for the full code.
- **Introduced in:** Part 13; updated in Part 14 for production.

## General environment variable hygiene

- All variables above go in a file named `.env.local` at your project root.
- `.env.local` must **never** be committed to Git — `create-next-app` adds `.env*.local` to `.gitignore` automatically; double-check it's there.
- Any variable prefixed `NEXT_PUBLIC_` is bundled into client-side JavaScript and visible to anyone who views your site's source — only ever put genuinely non-secret values there.
- Any variable **without** that prefix is server-only and never sent to the browser — this is where all real secrets belong.
- After editing `.env.local`, you must restart `npm run dev` for changes to take effect — Next.js reads env files once at server startup (this is unchanged in Next.js 16, and applies regardless of Turbopack being the default bundler).
- On Vercel, the equivalent is set under Project → Settings → Environment Variables, and requires a new deployment (redeploy or push) to take effect after changes.

## A note on Node.js version and environment variables

None of the environment variables above are Next.js-16-specific in format, but they only work correctly if your local Node.js version meets Next.js 16's minimum requirement (20.9+ or 22 LTS) — see Part 1. An incompatible Node version can cause confusing startup errors that look unrelated to env vars but are actually a Node version mismatch; always rule that out first if `npm run dev` fails immediately after adding new environment variables.

## Quick copy-paste template

```bash
# .env.local
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL=/dashboard
NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL=/dashboard
CLERK_WEBHOOK_SECRET=
```

