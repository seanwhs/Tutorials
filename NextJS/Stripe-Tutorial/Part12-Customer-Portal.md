# Part 12: Customer Portal — Let Users Manage/Cancel Their Own Subscription

Previous: Part 11 (Subscriptions). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

Stripe's **Billing/Customer Portal** is a hosted page (like Checkout) where customers can update payment methods, view invoices, and cancel their own subscription — without you building any of that UI. We just need to enable it once in the Dashboard and add one API route that creates a Portal Session.

## 2. Enable the Customer Portal

1. Go to https://dashboard.stripe.com/test/settings/billing/portal (test mode).
2. Configure basic settings: enable "Customers can cancel subscriptions" and "Customers can update payment methods." Save.

## 3. Track which Stripe Customer belongs to which order (simplification)

This tutorial has no login system, so we don't have a durable mapping of "current visitor → Stripe Customer ID" the way a real app would (typically stored on a `User` record after they first check out). For this tutorial we take the simplest working approach: look up the most recent order's `stripeCustomerId` from our database. Real apps should store `stripeCustomerId` on the logged-in user's own account row instead — see Appendix E.

## 4. Portal API route

File: src/app/api/portal/route.ts

```ts
import { NextResponse } from "next/server";
import { stripe } from "@/lib/stripe";
import { db } from "@/lib/db";

export async function POST() {
  const lastOrderWithCustomer = await db.order.findFirst({
    where: { stripeCustomerId: { not: null } },
    orderBy: { createdAt: "desc" },
  });

  if (!lastOrderWithCustomer?.stripeCustomerId) {
    return NextResponse.json(
      { error: "No Stripe customer found. Subscribe first from /pricing." },
      { status: 400 }
    );
  }

  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";

  const portalSession = await stripe.billingPortal.sessions.create({
    customer: lastOrderWithCustomer.stripeCustomerId,
    return_url: `${appUrl}/account`,
  });

  return NextResponse.json({ url: portalSession.url });
}
```

## 5. Build the Account page

File: src/app/account/page.tsx

```tsx
"use client";
import { useState } from "react";

export default function AccountPage() {
  const [loading, setLoading] = useState(false);

  async function handleManageSubscription() {
    setLoading(true);
    try {
      const res = await fetch("/api/portal", { method: "POST" });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error ?? "Could not open billing portal");
      }
      const { url } = await res.json();
      window.location.href = url;
    } catch (err) {
      console.error(err);
      alert(err instanceof Error ? err.message : "Something went wrong");
      setLoading(false);
    }
  }

  return (
    <main className="mx-auto max-w-2xl px-4 py-16 text-center">
      <h1 className="text-2xl font-bold text-gray-900">Account</h1>
      <p className="mt-2 text-gray-500">
        Manage your subscription, payment methods, and billing history.
      </p>
      <button
        onClick={handleManageSubscription}
        disabled={loading}
        className="mt-8 rounded-md bg-indigo-600 px-6 py-3 font-medium text-white hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {loading ? "Opening…" : "Manage Subscription"}
      </button>
    </main>
  );
}
```

## 6. Test it

1. Make sure you've completed at least one subscription checkout from Part 11.
2. Visit `/account`, click "Manage Subscription."
3. You should land on a Stripe-hosted portal page showing your active subscription, with options to cancel or update payment method — all built by Stripe, zero custom UI from us.
4. Try cancelling — then check the Stripe Dashboard's Customers page; the subscription should show as cancelled. Your webhook (Part 11's `customer.subscription.deleted`/`updated` case) should log the change in your dev server terminal too (with `stripe listen` running).

## Checkpoint

- [ ] Customer Portal enabled in Dashboard settings.
- [ ] `/api/portal` route created.
- [ ] `/account` page's "Manage Subscription" button redirects to a real Stripe Customer Portal session.
- [ ] Cancelling a subscription from the portal is reflected in the Dashboard and logged by your webhook handler.

## Next

Continue to Part 13: Polish — Loading States, Error Handling, Environment Variable Safety, Security Notes.
