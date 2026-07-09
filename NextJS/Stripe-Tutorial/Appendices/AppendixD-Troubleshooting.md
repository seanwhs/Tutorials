# Appendix D: Troubleshooting Guide

Index: "Stripe Tutorial - INDEX (Start Here)".

## Setup & environment issues

**"Missing required environment variable: X"**
Thrown by `src/lib/env.ts` (Part 13). Means the named variable isn't set in `.env.local` (or Vercel's env var settings in production). Add it and restart `npm run dev` (Next.js only reads env files at process startup).

**Node/Next.js version errors on `npm run dev` or `npm run build`**
Confirm `node -v` shows 20.9+ or 22.x. Next.js 16 will refuse to run on older Node versions. Reinstall Node from nodejs.org or use a version manager (nvm/fnm) to switch.

**Tailwind classes not applying / no styling at all**
Confirm `src/app/globals.css` contains `@import "tailwindcss";` and is imported in `src/app/layout.tsx`. Next.js 16's default scaffold uses Tailwind v4's CSS-first config — there should be no need for a `tailwind.config.js` for anything in this tutorial.

## Checkout issues

**"Unknown product" / "Unknown plan" error when clicking Buy Now / Subscribe**
The `priceId` placeholders in `src/lib/products.ts` or `src/lib/plans.ts` were never replaced with real Price IDs from your Stripe Dashboard (Parts 3 and 11). Double check they start with `price_` and were copied from the correct product/plan in test mode.

**Redirect to Stripe Checkout works, but the page shows a Stripe error like "No such price"**
Usually means the Price ID belongs to a different Stripe account, or you copied a Product ID (`prod_...`) instead of a Price ID (`price_...`). Go back to the Dashboard and copy the Price ID specifically.

**Checkout succeeds but `/success` shows "No session found"**
Check that your `success_url` includes `?session_id={CHECKOUT_SESSION_ID}` exactly as shown in Parts 3/6/11 (the literal `{CHECKOUT_SESSION_ID}` string, not a real value — Stripe substitutes it). Also confirm you're reading `searchParams` correctly with `await searchParams` (Next.js 16 requires awaiting it).

## Webhook issues

**Signature verification failing (400 "Invalid signature")**
The #1 cause: `STRIPE_WEBHOOK_SECRET` in `.env.local` doesn't match the secret currently shown by your running `stripe listen` command (Part 9) — this secret can change between CLI sessions. Copy it fresh and restart `npm run dev`. In production, make sure you copied the secret from the specific webhook endpoint you registered in the Dashboard (Part 14), not your local CLI's secret.

**Webhook never receives events at all (locally)**
Confirm `stripe listen --forward-to localhost:3000/api/webhooks/stripe` is actually running in a separate terminal and hasn't been closed. It must stay running for the entire local dev session.

**Order not appearing in `/orders` after a successful payment**
1. Check the `npm run dev` terminal for a "Recorded order for session ..." log line (Part 8). If missing, the webhook never fired or failed — check the `stripe listen` terminal for a non-200 response.
2. Open Prisma Studio (`npx prisma studio`, Part 9) and check the `Order` table directly.
3. In production specifically, remember SQLite may not persist reliably on Vercel (Part 14) — this is expected without migrating to Postgres.

**Duplicate orders for the same purchase**
Should not happen due to the idempotency check (`findUnique` by `stripeCheckoutId`) in Part 8's webhook handler. If you see duplicates, confirm the `@unique` attribute is present on `stripeCheckoutId` in `prisma/schema.prisma` and that you ran a fresh migration after adding it.

## Subscription / Portal issues

**"No Stripe customer found. Subscribe first from /pricing." on `/account`**
This tutorial's simplified Portal route (Part 12) looks up the most recent order with a `stripeCustomerId` — you need to have completed at least one subscription checkout first. In a real app, you'd store the customer ID on a user record instead.

**Customer Portal link gives a Stripe configuration error**
Make sure you completed Part 12 step 2 — the Customer Portal must be enabled/configured once in Dashboard Settings → Billing → Customer Portal before `stripe.billingPortal.sessions.create` will work.

## Deployment issues (Part 14)

**Build succeeds locally but fails on Vercel**
Check the Vercel build logs for the actual error — most commonly a missing environment variable (Prisma needs `DATABASE_URL` at build time too, since `prisma generate` runs during `npm install`/build).

**Webhook works locally but not in production**
You must create a **separate, second webhook endpoint** in the Stripe Dashboard pointing at your live Vercel URL (Part 14, step 7) — the local Stripe CLI forwarding from Part 9 has no effect once deployed. Each endpoint has its own signing secret; make sure production's `STRIPE_WEBHOOK_SECRET` matches the production endpoint, not your local CLI's.

## General debugging tips

- The Stripe Dashboard's **Developers → Events** log (test mode) shows every event Stripe generated, whether or not your webhook received it successfully — great for confirming what Stripe actually sent.
- The Stripe Dashboard's **Developers → Webhooks → [endpoint] → recent deliveries** shows the exact HTTP response your server returned for each attempt — check this first when debugging any webhook issue.
- `console.log` liberally in your webhook handler during development; remove/reduce verbosity before considering the project "finished," but this tutorial's logs are intentionally left in as learning aids.

## Next

Continue to **Appendix E: Further Resources & Next Steps** — the final note in this series.
