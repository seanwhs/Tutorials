# Part 2: Stripe Account Setup, API Keys & the SDK

Previous: Part 1 (Dev Environment & Project Setup). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

Before writing checkout code, we need a Stripe account, API keys, and the `stripe` npm package installed. Everything in this tutorial uses **test mode**, which is completely free and uses fake card numbers — no real money ever moves.

## 2. Create your Stripe account

1. Go to https://dashboard.stripe.com/register and sign up (free, no credit card required).
2. After signing up, you land on the Stripe Dashboard. Look at the top-right — there should be a toggle/badge showing **"Test mode"**. Make sure it's ON. All work in this series happens in test mode.

## 3. Get your API keys

1. In the Dashboard, go to **Developers → API keys** (or visit https://dashboard.stripe.com/test/apikeys).
2. You'll see two keys:
   - **Publishable key** (starts with `pk_test_...`) — safe to expose in client-side code.
   - **Secret key** (starts with `sk_test_...`) — never expose this in client-side code or commit it to git. Server-side only.
3. Copy both into your `.env.local`:

```bash
# .env.local
STRIPE_SECRET_KEY=sk_test_yourSecretKeyHere
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_yourPublishableKeyHere
STRIPE_WEBHOOK_SECRET=
NEXT_PUBLIC_APP_URL=http://localhost:3000
DATABASE_URL="file:./dev.db"
```

We'll fill in `STRIPE_WEBHOOK_SECRET` in Part 9.

**Why the `NEXT_PUBLIC_` prefix on the publishable key?** In Next.js, only environment variables prefixed with `NEXT_PUBLIC_` are exposed to browser-side code. The secret key deliberately has no such prefix — it stays server-only.

## 4. Install the Stripe SDK

```bash
npm install stripe
```

This is Stripe's official Node.js library, open-source and free, used for all server-side calls (creating Checkout Sessions, verifying webhooks, etc.).

We are **not** installing `@stripe/stripe-js` or `@stripe/react-stripe-js` yet, because this tutorial uses Stripe Checkout (a hosted redirect page) rather than embedded Stripe Elements — this means far less client-side code and no handling of raw card fields ourselves. (Appendix E mentions embedded Elements as a "next step" if you want that instead.)

## 5. Create the server-side Stripe client

```ts
// src/lib/stripe.ts
import Stripe from "stripe";

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error("Missing STRIPE_SECRET_KEY environment variable");
}

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: "2025-08-27.basil",
  typescript: true,
});
```

Note: Stripe's `apiVersion` pins your integration to a specific version of Stripe's API so future Stripe changes don't silently break your code. Use whatever the latest stable pinned version string is shown in your Stripe Dashboard under **Developers → API version** — the one above is illustrative; check your dashboard and use the exact string it shows if it differs.

This file is imported only from server-side code (Route Handlers, Server Components, Server Actions) — never from a Client Component — because it reads `STRIPE_SECRET_KEY`.

## 6. A quick sanity-check API route

Let's confirm the SDK and key work before building real features:

```ts
// src/app/api/stripe-healthcheck/route.ts
import { NextResponse } from "next/server";
import { stripe } from "@/lib/stripe";

export async function GET() {
  const balance = await stripe.balance.retrieve();
  return NextResponse.json({ ok: true, livemode: balance.livemode });
}
```

Visit `http://localhost:3000/api/stripe-healthcheck`. You should get back JSON like:

```json
{ "ok": true, "livemode": false }
```

`"livemode": false` confirms you're using test mode keys correctly. Delete this route file once confirmed (or leave it — it's harmless, but not part of the final app, so Appendix A won't include it).

## 7. Security notes (read this before continuing)

- **Never** put `STRIPE_SECRET_KEY` in a Client Component, in code that ships to the browser, or in a public GitHub repo.
- Always double-check you're using `sk_test_...` / `pk_test_...` keys (not `sk_live_...` / `pk_live_...`) while following this tutorial.
- `.env.local` must stay git-ignored. If you ever accidentally commit a secret key, roll it immediately in the Dashboard (Developers → API keys → roll key).

## Checkpoint

- [ ] Stripe account created, test mode confirmed ON.
- [ ] `.env.local` has `STRIPE_SECRET_KEY` and `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` filled in.
- [ ] `npm install stripe` succeeded.
- [ ] `src/lib/stripe.ts` created.
- [ ] `/api/stripe-healthcheck` returns `{ "ok": true, "livemode": false }`.

## Next

Continue to **Part 3: Product Catalog & a Single "Buy Now" Button**.
