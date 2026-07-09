# Part 13: Polish — Loading States, Error Handling, Env Var Safety, Security Notes

Previous: Part 12 (Customer Portal). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

Before deploying (Part 14), let's tighten up error handling, add a couple of missing UX niceties, and review the security practices this whole series has been building toward.

## 2. Centralize env var validation

Rather than scattering `process.env.X!` non-null assertions around the codebase, validate required env vars once at startup.

File: src/lib/env.ts

```ts
function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const env = {
  STRIPE_SECRET_KEY: requireEnv("STRIPE_SECRET_KEY"),
  STRIPE_WEBHOOK_SECRET: requireEnv("STRIPE_WEBHOOK_SECRET"),
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: requireEnv("NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY"),
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000",
};
```

Update src/lib/stripe.ts to use it:

```ts
import Stripe from "stripe";
import { env } from "@/lib/env";

export const stripe = new Stripe(env.STRIPE_SECRET_KEY, {
  apiVersion: "2025-08-27.basil",
  typescript: true,
});
```

And in src/app/api/webhooks/stripe/route.ts, replace `process.env.STRIPE_WEBHOOK_SECRET!` with `env.STRIPE_WEBHOOK_SECRET` (import `{ env } from "@/lib/env"`).

This way, if a required key is missing, you get one clear error message at the point of use instead of a cryptic Stripe SDK failure deep in a request handler.

## 3. Add a global error boundary for API failures

Wrap fetch calls with consistent error surfacing. We already do try/catch + `alert()` in each button handler — for a nicer UX, replace `alert()` calls with a small toast-style banner. Simple, dependency-free approach:

File: src/components/ErrorBanner.tsx

```tsx
"use client";

export default function ErrorBanner({
  message,
  onDismiss,
}: {
  message: string | null;
  onDismiss: () => void;
}) {
  if (!message) return null;
  return (
    <div className="fixed inset-x-0 top-4 z-50 mx-auto w-full max-w-md rounded-md bg-red-50 p-4 shadow-lg ring-1 ring-red-200">
      <div className="flex items-start justify-between gap-3">
        <p className="text-sm text-red-800">{message}</p>
        <button onClick={onDismiss} className="text-red-400 hover:text-red-600">
          ✕
        </button>
      </div>
    </div>
  );
}
```

Swap this in anywhere we previously used `alert(...)` (ProductCard, Cart page, Pricing page, Account page) by adding an `errorMessage` state (`useState<string | null>(null)`) and rendering `<ErrorBanner message={errorMessage} onDismiss={() => setErrorMessage(null)} />` inside each component, setting `setErrorMessage(err.message)` in the catch block instead of calling `alert()`.

## 4. Handle Stripe rate limits & transient errors gracefully

Stripe's SDK throws typed errors. Wrap checkout creation calls to give clearer feedback:

```ts
import Stripe from "stripe";
// ...inside a try/catch around stripe.checkout.sessions.create(...):
try {
  // ...
} catch (err) {
  if (err instanceof Stripe.errors.StripeRateLimitError) {
    return NextResponse.json({ error: "Too many requests, please try again shortly." }, { status: 429 });
  }
  if (err instanceof Stripe.errors.StripeInvalidRequestError) {
    console.error("Stripe invalid request:", err.message);
    return NextResponse.json({ error: "Invalid checkout request." }, { status: 400 });
  }
  console.error("Unexpected Stripe error:", err);
  return NextResponse.json({ error: "Something went wrong." }, { status: 500 });
}
```

Apply this pattern to all three checkout routes (`/api/checkout`, `/api/checkout-cart`, `/api/checkout-subscription`).

## 5. Security checklist (review before deploying)

- [ ] `STRIPE_SECRET_KEY` is never referenced from any file marked `"use client"`.
- [ ] `.env.local` (and `.env`) are git-ignored; confirm with `git status` that neither appears as tracked.
- [ ] The webhook route verifies signatures via `stripe.webhooks.constructEvent` — never trust unverified webhook payloads.
- [ ] All checkout routes derive prices/Price IDs from our own server-side catalog (`products.ts` / `plans.ts`) — never accept a raw dollar amount or arbitrary Price ID from client input.
- [ ] The webhook handler is idempotent (checks `stripeCheckoutId` uniqueness before inserting).
- [ ] We're using `sk_test_...` / `pk_test_...` keys throughout development — confirmed via the Part 2 healthcheck (`livemode: false`).

## 6. A note on Content Security & Stripe.js

Because we use Stripe Checkout (hosted redirect) rather than embedded Stripe Elements, we don't need to allow-list Stripe's JS in a Content-Security-Policy for card fields — there are no card fields in our own DOM at all. If you later adopt embedded Elements (see Appendix E), you'll need to permit `https://js.stripe.com` in your CSP `script-src` and `https://api.stripe.com` in `connect-src`.

## Checkpoint

- [ ] `src/lib/env.ts` created and used by `src/lib/stripe.ts` and the webhook route.
- [ ] Error banners replace `alert()` calls across ProductCard, Cart, Pricing, and Account pages.
- [ ] All three checkout routes handle `StripeRateLimitError` / `StripeInvalidRequestError` distinctly from generic errors.
- [ ] You've walked through the Security checklist above and every item is checked.

## Next

Continue to Part 14: Deploying to Vercel for Free.
