# Part 6: Cart Checkout with Multiple Line Items

Previous: Part 5 (Building a Multi-Item Shopping Cart). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

Now we create a second checkout API route that accepts an arbitrary list of cart lines and builds a Stripe Checkout Session with multiple `line_items` — one per distinct product, each with its own quantity.

## 2. The cart checkout API route

File: src/app/api/checkout-cart/route.ts

```ts
import { NextRequest, NextResponse } from "next/server";
import { stripe } from "@/lib/stripe";
import { getProductById } from "@/lib/products";

type CartLine = { productId: string; quantity: number };

export async function POST(req: NextRequest) {
  const { lines }: { lines: CartLine[] } = await req.json();

  if (!Array.isArray(lines) || lines.length === 0) {
    return NextResponse.json({ error: "Cart is empty" }, { status: 400 });
  }

  const lineItems = [];
  for (const line of lines) {
    const product = getProductById(line.productId);
    if (!product) {
      return NextResponse.json({ error: `Unknown product: ${line.productId}` }, { status: 400 });
    }
    if (!Number.isInteger(line.quantity) || line.quantity < 1) {
      return NextResponse.json({ error: `Invalid quantity for ${line.productId}` }, { status: 400 });
    }
    lineItems.push({ price: product.priceId, quantity: line.quantity });
  }

  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";

  const session = await stripe.checkout.sessions.create({
    mode: "payment",
    line_items: lineItems,
    success_url: `${appUrl}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${appUrl}/cart`,
  });

  if (!session.url) {
    return NextResponse.json({ error: "Could not create checkout session" }, { status: 500 });
  }

  return NextResponse.json({ url: session.url });
}
```

Important: we always **re-validate on the server** which products exist and re-derive their Stripe Price IDs from our own trusted `products.ts` catalog — we never let the client tell us a price directly. This is a critical security pattern: client-submitted prices can be tampered with, but Price IDs pulled server-side from your own catalog cannot be.

## 3. Wire up the Cart page's Checkout button

Update src/app/cart/page.tsx — add a loading state and an async handler:

```tsx
const [loading, setLoading] = useState(false);

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
    console.error(err);
    alert("Could not start checkout. Please try again.");
    setLoading(false);
  }
}
```

Don't forget to add `import { useState } from "react";` at the top if it isn't already imported, and update the Checkout button:

```tsx
<button
  onClick={handleCheckout}
  disabled={loading}
  className="mt-6 w-full rounded-md bg-indigo-600 px-4 py-3 font-medium text-white hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-60"
>
  {loading ? "Redirecting…" : "Checkout"}
</button>
```

## 4. Clear the cart after a successful purchase

Since the Success page is a Server Component (Part 4) and the cart lives in client-side localStorage, we clear the cart from the client. Add a small client component to the success page that clears the cart on mount, only when payment_status is paid.

File: src/components/ClearCartOnSuccess.tsx

```tsx
"use client";
import { useEffect } from "react";
import { useCart } from "@/components/CartProvider";

export default function ClearCartOnSuccess({ shouldClear }: { shouldClear: boolean }) {
  const { clearCart } = useCart();
  useEffect(() => {
    if (shouldClear) clearCart();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [shouldClear]);
  return null;
}
```

Update src/app/success/page.tsx to render it (add the import and drop `<ClearCartOnSuccess shouldClear={isPaid} />` right after the opening `<main>` tag, alongside the existing JSX):

```tsx
import ClearCartOnSuccess from "@/components/ClearCartOnSuccess";
// ...inside the returned JSX, as the first child of <main>:
<ClearCartOnSuccess shouldClear={isPaid} />
```

## Checkpoint

- [ ] Adding 2-3 different products with varying quantities to the cart, then clicking Checkout, redirects to a single Stripe Checkout page listing all items correctly with correct quantities and total.
- [ ] Completing payment with the test card lands on the Success page showing all purchased line items.
- [ ] After a successful checkout, the cart badge resets to empty automatically.
- [ ] Cancelling from the multi-item checkout returns to `/cart` with the cart still intact.

## Next

Continue to Part 7: Database Setup with Prisma + SQLite.
