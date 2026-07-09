# Appendix A (3 of 5): Full Codebase Reference — Homepage, Cart, Success & Cancel Pages

Index: "Stripe Tutorial - INDEX (Start Here)". See part 4 of 5 for orders/pricing/account pages and part 5 of 5 for all API routes.

## src/app/page.tsx
```tsx
import ProductCard from "@/components/ProductCard";
import { products } from "@/lib/products";

export default function HomePage() {
  return (
    <main className="mx-auto max-w-5xl px-4 py-10">
      <h1 className="mb-2 text-3xl font-bold text-gray-900">Acme Shop</h1>
      <p className="mb-8 text-gray-500">
        A demo storefront. All payments run in Stripe test mode — use test card{" "}
        <code className="rounded bg-gray-100 px-1 py-0.5">4242 4242 4242 4242</code>, any future
        expiry, any CVC, any ZIP.
      </p>
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 md:grid-cols-3">
        {products.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </main>
  );
}
```

## src/app/cart/page.tsx
```tsx
"use client";
import { useState } from "react";
import Link from "next/link";
import { useCart } from "@/components/CartProvider";
import { getProductById } from "@/lib/products";
import ErrorBanner from "@/components/ErrorBanner";

export default function CartPage() {
  const { lines, removeFromCart, updateQuantity, clearCart } = useCart();
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  if (lines.length === 0) {
    return (
      <main className="mx-auto max-w-2xl px-4 py-16 text-center">
        <h1 className="text-2xl font-bold text-gray-900">Your cart is empty</h1>
        <Link href="/" className="mt-4 inline-block text-indigo-600 hover:underline">
          Continue shopping
        </Link>
      </main>
    );
  }

  const rows = lines
    .map((line) => ({ line, product: getProductById(line.productId) }))
    .filter((r) => r.product);

  const subtotalCents = rows.reduce(
    (sum, r) =>
      sum + Math.round(parseFloat(r.product!.priceLabel.replace("$", "")) * 100) * r.line.quantity,
    0
  );

  async function handleCheckout() {
    setLoading(true);
    try {
      const res = await fetch("/api/checkout-cart", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ lines }),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error ?? "Checkout failed");
      }
      const { url } = await res.json();
      window.location.href = url;
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : "Could not start checkout.");
      setLoading(false);
    }
  }

  return (
    <main className="mx-auto max-w-3xl px-4 py-10">
      <ErrorBanner message={errorMessage} onDismiss={() => setErrorMessage(null)} />
      <h1 className="mb-6 text-2xl font-bold text-gray-900">Your Cart</h1>
      <div className="divide-y divide-gray-200 rounded-lg border border-gray-200 bg-white">
        {rows.map(({ line, product }) => (
          <div key={line.productId} className="flex items-center gap-4 p-4">
            <img
              src={product!.image}
              alt={product!.name}
              className="h-16 w-16 rounded object-cover"
            />
            <div className="flex-1">
              <p className="font-medium text-gray-900">{product!.name}</p>
              <p className="text-sm text-gray-500">{product!.priceLabel}</p>
            </div>
            <input
              type="number"
              min={1}
              value={line.quantity}
              onChange={(e) => updateQuantity(line.productId, Number(e.target.value))}
              className="w-16 rounded border border-gray-300 px-2 py-1 text-center"
            />
            <button
              onClick={() => removeFromCart(line.productId)}
              className="text-sm text-red-600 hover:underline"
            >
              Remove
            </button>
          </div>
        ))}
      </div>

      <div className="mt-6 flex items-center justify-between">
        <button onClick={clearCart} className="text-sm text-gray-500 hover:underline">
          Clear cart
        </button>
        <div className="text-right">
          <p className="text-sm text-gray-500">Subtotal</p>
          <p className="text-xl font-bold text-gray-900">${(subtotalCents / 100).toFixed(2)}</p>
        </div>
      </div>

      <button
        onClick={handleCheckout}
        disabled={loading}
        className="mt-6 w-full rounded-md bg-indigo-600 px-4 py-3 font-medium text-white hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {loading ? "Redirecting…" : "Checkout"}
      </button>
    </main>
  );
}
```

## src/app/success/page.tsx
```tsx
import Link from "next/link";
import { stripe } from "@/lib/stripe";
import ClearCartOnSuccess from "@/components/ClearCartOnSuccess";

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
      <ClearCartOnSuccess shouldClear={isPaid} />
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

## src/app/cancel/page.tsx
```tsx
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

## Next
Continue to **Appendix A (4 of 5): Orders, Pricing & Account Pages**.
