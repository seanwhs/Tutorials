# Appendix A (4 of 5): Full Codebase Reference — Orders, Pricing & Account Pages

Index: "Stripe Tutorial - INDEX (Start Here)". See part 3 of 5 for homepage/cart/success/cancel pages, and part 5 of 5 for all API routes.

## src/app/orders/page.tsx
```tsx
import { db } from "@/lib/db";

export const dynamic = "force-dynamic";

export default async function OrdersPage() {
  const orders = await db.order.findMany({
    orderBy: { createdAt: "desc" },
    include: { items: true },
    take: 50,
  });

  return (
    <main className="mx-auto max-w-4xl px-4 py-10">
      <h1 className="mb-2 text-2xl font-bold text-gray-900">Order History</h1>
      <p className="mb-8 text-sm text-gray-500">
        Demo note: this tutorial has no login system, so this page shows every order ever placed.
      </p>
      {orders.length === 0 ? (
        <p className="text-gray-500">No orders yet. Go buy something!</p>
      ) : (
        <div className="space-y-4">
          {orders.map((order) => (
            <div key={order.id} className="rounded-lg border border-gray-200 bg-white p-4">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <div>
                  <p className="font-medium text-gray-900">
                    Order #{order.id.slice(-8).toUpperCase()}
                  </p>
                  <p className="text-xs text-gray-500">
                    {order.createdAt.toLocaleString()} · {order.customerEmail ?? "no email"}
                  </p>
                </div>
                <span className="rounded-full bg-green-100 px-3 py-1 text-xs font-medium text-green-700">
                  {order.status}
                </span>
              </div>
              <ul className="mt-3 divide-y divide-gray-100 border-t border-gray-100 pt-2">
                {order.items.map((item) => (
                  <li key={item.id} className="flex justify-between py-1 text-sm">
                    <span className="text-gray-700">
                      {item.productName} × {item.quantity}
                    </span>
                    <span className="font-medium text-gray-900">
                      ${(item.amountTotal / 100).toFixed(2)}
                    </span>
                  </li>
                ))}
              </ul>
              <div className="mt-2 flex justify-end border-t border-gray-100 pt-2 text-sm font-semibold text-gray-900">
                Total: ${(order.amountTotal / 100).toFixed(2)} {order.currency.toUpperCase()}
              </div>
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
```

## src/app/pricing/page.tsx
```tsx
"use client";
import { useState } from "react";
import { plans } from "@/lib/plans";
import ErrorBanner from "@/components/ErrorBanner";

export default function PricingPage() {
  const [loading, setLoading] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

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
      setErrorMessage(err instanceof Error ? err.message : "Could not start checkout.");
      setLoading(null);
    }
  }

  return (
    <main className="mx-auto max-w-3xl px-4 py-10">
      <ErrorBanner message={errorMessage} onDismiss={() => setErrorMessage(null)} />
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

## src/app/account/page.tsx
```tsx
"use client";
import { useState } from "react";
import ErrorBanner from "@/components/ErrorBanner";

export default function AccountPage() {
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

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
      setErrorMessage(err instanceof Error ? err.message : "Something went wrong");
      setLoading(false);
    }
  }

  return (
    <main className="mx-auto max-w-2xl px-4 py-16 text-center">
      <ErrorBanner message={errorMessage} onDismiss={() => setErrorMessage(null)} />
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

## Next
Continue to **Appendix A (5 of 5): API Routes** (checkout, checkout-cart, checkout-subscription, portal, webhooks).
