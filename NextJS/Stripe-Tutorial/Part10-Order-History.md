# Part 10: Order History Page

Previous: Part 9 (Local Webhook Testing with the Stripe CLI). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

Now that verified orders are being written to our database by the webhook, we can build a simple Order History page that reads directly from Prisma — a Server Component, no client-side fetching needed.

Since this tutorial has no user accounts/authentication (out of scope — see Appendix E for pointers on adding one), we'll show **all** orders for demo purposes, most recent first, and note clearly in the UI that a real app would scope this to the signed-in customer.

## 2. Build the Orders page

File: src/app/orders/page.tsx

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
        A real app would filter by the signed-in customer.
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

Notes:
- `export const dynamic = "force-dynamic"` ensures this page always fetches fresh data from the database rather than being statically cached at build time — important since orders change constantly.
- Prisma returns `createdAt` as a real JS `Date` object, so `.toLocaleString()` works directly.

## 3. Checkpoint

- [ ] Visiting `/orders` after completing at least one real test purchase (Part 9) shows that order with correct items, quantities, and total.
- [ ] Placing a second order shows both, most recent first.
- [ ] The page with zero orders shows the "No orders yet" empty state (test by temporarily clearing the `Order` table in Prisma Studio, then reload — re-checkout afterward to keep testing later parts).

## Next

Continue to Part 11: Subscriptions — Recurring Prices & Checkout in Subscription Mode.
