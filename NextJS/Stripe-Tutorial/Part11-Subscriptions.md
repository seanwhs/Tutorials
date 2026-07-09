# Part 11: Subscriptions — Recurring Prices & Checkout in Subscription Mode

Previous: Part 10 (Order History Page). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

So far every purchase has been `mode: "payment"` (one-time). Stripe Checkout also supports `mode: "subscription"` for recurring billing — same hosted page, same Checkout Session API, just a different Price type and mode value. Stripe handles all recurring billing logic (renewals, retries, proration) for you.

## 2. Create a recurring Price in the Dashboard

1. Go to **Product catalog** (https://dashboard.stripe.com/test/products), still in test mode.
2. Create a new product: **Acme Pro Plan**.
3. Add a Price: **$9.00 USD**, billing period **Monthly**, recurring.
4. Copy the resulting Price ID (starts with `price_...`).

## 3. Add the plan to our catalog

File: src/lib/plans.ts

```ts
export type Plan = {
  id: string;
  name: string;
  description: string;
  priceId: string;
  priceLabel: string;
};

export const plans: Plan[] = [
  {
    id: "pro-monthly",
    name: "Acme Pro Plan",
    description: "Unlock pro features, billed monthly. Cancel anytime.",
    priceId: "price_REPLACE_WITH_PRO_MONTHLY_PRICE_ID",
    priceLabel: "$9.00 / month",
  },
];

export function getPlanById(id: string): Plan | undefined {
  return plans.find((p) => p.id === id);
}
```

## 4. Subscription checkout API route

File: src/app/api/checkout-subscription/route.ts

```ts
import { NextRequest, NextResponse } from "next/server";
import { stripe } from "@/lib/stripe";
import { getPlanById } from "@/lib/plans";

export async function POST(req: NextRequest) {
  const { planId } = await req.json();

  const plan = getPlanById(planId);
  if (!plan) {
    return NextResponse.json({ error: "Unknown plan" }, { status: 400 });
  }

  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";

  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    line_items: [{ price: plan.priceId, quantity: 1 }],
    success_url: `${appUrl}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${appUrl}/cancel`,
  });

  if (!session.url) {
    return NextResponse.json({ error: "Could not create checkout session" }, { status: 500 });
  }

  return NextResponse.json({ url: session.url });
}
```

The only differences from Part 3's one-time checkout: `mode: "subscription"` and a recurring Price ID. Everything else about Checkout Sessions works the same.

## 5. Build a simple Pricing page

File: src/app/pricing/page.tsx

```tsx
"use client";
import { useState } from "react";
import { plans } from "@/lib/plans";

export default function PricingPage() {
  const [loading, setLoading] = useState<string | null>(null);

  async function handleSubscribe(planId: string) {
    setLoading(planId);
    try {
      const res = await fetch("/api/checkout-subscription", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ planId }),
      });
      if (!res.ok) throw new Error("Checkout failed");
      const { url } = await res.json();
      window.location.href = url;
    } catch (err) {
      console.error(err);
      alert("Could not start checkout. Please try again.");
      setLoading(null);
    }
  }

  return (
    <main className="mx-auto max-w-3xl px-4 py-10">
      <h1 className="mb-8 text-2xl font-bold text-gray-900">Pricing</h1>
      <div className="grid gap-6 sm:grid-cols-2">
        {plans.map((plan) => (
          <div key={plan.id} className="rounded-lg border border-gray-200 bg-white p-6">
            <h2 className="text-lg font-semibold text-gray-900">{plan.name}</h2>
            <p className="mt-1 text-2xl font-bold text-gray-900">{plan.priceLabel}</p>
            <p className="mt-2 text-sm text-gray-500">{plan.description}</p>
            <button
              onClick={() => handleSubscribe(plan.id)}
              disabled={loading === plan.id}
              className="mt-6 w-full rounded-md bg-indigo-600 px-4 py-2 font-medium text-white hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {loading === plan.id ? "Redirecting…" : "Subscribe"}
            </button>
          </div>
        ))}
      </div>
    </main>
  );
}
```

Add a "Pricing" link to the Nav component alongside Shop/Cart/Orders/Account.

## 6. Handle subscription-related webhook events

Subscriptions fire additional event types beyond `checkout.session.completed`. Update the webhook handler to also log (and optionally store) subscription lifecycle events. For this tutorial we'll keep it lightweight: extend the `switch` statement in src/app/api/webhooks/stripe/route.ts.

```ts
case "customer.subscription.created":
case "customer.subscription.updated":
case "customer.subscription.deleted": {
  const subscription = event.data.object as Stripe.Subscription;
  console.log(
    `Subscription ${subscription.id} is now status: ${subscription.status}`
  );
  // Optional extension: store subscription status on a Customer/Order-like model.
  // Left as a Phase 2 exercise — see Appendix E.
  break;
}
```

For `checkout.session.completed` specifically with `mode: "subscription"`, `session.mode` will be `"subscription"` and `session.subscription` will contain the new Subscription ID — our existing `handleCheckoutCompleted` function from Part 8 still runs fine and will record an "Order" row for the initial subscription signup too (useful as a receipt), though ongoing renewal charges are a separate topic covered by the `invoice.paid` event, mentioned in Appendix E as a next step.

## 7. Test it

With `stripe listen` still running (Part 9):
1. Visit `/pricing`, click Subscribe.
2. Pay with test card `4242 4242 4242 4242`.
3. Confirm you land on `/success`, and check your `npm run dev` terminal / Prisma Studio for the recorded order and subscription log lines.
4. In the Stripe Dashboard, go to **Customers** (test mode) — you should see a new customer with an active subscription.

## Checkpoint

- [ ] Recurring Price created in Dashboard, added to `src/lib/plans.ts`.
- [ ] `/pricing` page renders and "Subscribe" redirects to Stripe Checkout in subscription mode.
- [ ] Test subscription completes successfully and appears under Customers in the Stripe Dashboard.
- [ ] Webhook logs show subscription lifecycle events being received.

## Next

Continue to Part 12: Customer Portal — Let Users Manage/Cancel Their Own Subscription.
