# Part 4: Success & Cancel Pages, Reading a Checkout Session

Previous: Part 3 (Product Catalog & Buy Now Button). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

After a customer pays (or cancels), Stripe redirects their browser back to our `success_url` or `cancel_url` from Part 3. The success URL includes `?session_id={CHECKOUT_SESSION_ID}` — a real Session ID we can use to look up details **server-side** and show a friendly confirmation.

Remember: this page is for **UX only** (showing a nice confirmation). It must never be the thing that marks an order "paid" in your database — that's the webhook's job (Part 8), because a user could close the tab before this page even loads.

## 2. Success page (Server Component reading searchParams)

Next.js 16 requires `searchParams` to be awaited since it's an async dynamic API.

```tsx
// src/app/success/page.tsx
import Link from "next/link";
import { stripe } from "@/lib/stripe";

export default async function SuccessPage({
  searchParams,
}: {
  searchParams: Promise<{ session_id?: string }>;
}) {
  const { session_id: sessionId } = await searchParams;

  if (!sessionId) {
    return (
      <main className="mx-auto max-w-2xl px-4 py-16 text-center">
        <h1 className="text-2xl font-bold text-gray-900">No session found</h1>
        <p className="mt-2 text-gray-500">
          It looks like you reached this page without completing a checkout.
        </p>
        <Link href="/" className="mt-6 inline-block text-indigo-600 hover:underline">
          Back to shop
        </Link>
      </main>
    );
  }

  const session = await stripe.checkout.sessions.retrieve(sessionId, {
    expand: ["line_items"],
  });

  const isPaid = session.payment_status === "paid";

  return (
    <main className="mx-auto max-w-2xl px-4 py-16 text-center">
      <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-green-100 text-3xl">
        {isPaid ? "✅" : "⏳"}
      </div>
      <h1 className="text-2xl font-bold text-gray-900">
        {isPaid ? "Payment successful!" : "Payment processing…"}
      </h1>
      <p className="mt-2 text-gray-500">
        Thanks{session.customer_details?.email ? `, ${session.customer_details.email}` : ""}! Your
        order has been received.
      </p>

      <div className="mt-8 rounded-lg border border-gray-200 bg-white p-4 text-left">
        <h2 className="mb-2 font-semibold text-gray-900">Order summary</h2>
        <ul className="divide-y divide-gray-100">
          {session.line_items?.data.map((item) => (
            <li key={item.id} className="flex justify-between py-2 text-sm">
              <span className="text-gray-700">
                {item.description} × {item.quantity}
              </span>
              <span className="font-medium text-gray-900">
                ${((item.amount_total ?? 0) / 100).toFixed(2)}
              </span>
            </li>
          ))}
        </ul>
        <div className="mt-2 flex justify-between border-t border-gray-100 pt-2 text-sm font-semibold text-gray-900">
          <span>Total</span>
          <span>${((session.amount_total ?? 0) / 100).toFixed(2)}</span>
        </div>
      </div>

      <div className="mt-8 flex justify-center gap-4">
        <Link href="/" className="text-indigo-600 hover:underline">
          Continue shopping
        </Link>
        <Link href="/orders" className="text-indigo-600 hover:underline">
          View order history
        </Link>
      </div>
    </main>
  );
}
```

Notes:
- `expand: ["line_items"]` tells Stripe to include the purchased items in the response (by default they're not included).
- Amounts from Stripe are always in the smallest currency unit (cents for USD), so we divide by 100 for display.

## 3. Cancel page

```tsx
// src/app/cancel/page.tsx
import Link from "next/link";

export default function CancelPage() {
  return (
    <main className="mx-auto max-w-2xl px-4 py-16 text-center">
      <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-yellow-100 text-3xl">
        ⚠️
      </div>
      <h1 className="text-2xl font-bold text-gray-900">Checkout cancelled</h1>
      <p className="mt-2 text-gray-500">
        No worries — your card was not charged. You can pick up where you left off any time.
      </p>
      <Link href="/" className="mt-6 inline-block text-indigo-600 hover:underline">
        Back to shop
      </Link>
    </main>
  );
}
```

## Checkpoint

- [ ] Completing a test payment from Part 3 now lands on a styled Success page showing the correct product, price, and total.
- [ ] Clicking "Buy Now" then clicking Stripe's "← Back" link (or closing checkout) lands on a styled Cancel page.
- [ ] Refreshing the Success page with an invalid/missing `session_id` shows the "No session found" state instead of crashing.

## Next

Continue to **Part 5: Building a Multi-Item Shopping Cart**.
