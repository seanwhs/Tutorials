# Part 3: Product Catalog & a Single "Buy Now" Button

Previous: Part 2 (Stripe Account Setup, API Keys & SDK). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

We'll define a small hardcoded product catalog, render it on the homepage, and wire up a "Buy Now" button that creates a **Stripe Checkout Session** for a one-time payment and redirects the browser to Stripe's hosted payment page.

## 2. Create products & prices in the Stripe Dashboard

1. Go to **Product catalog** in the Dashboard (https://dashboard.stripe.com/test/products) — make sure you're still in Test mode.
2. Click **+ Add product** and create three products:
   - **Acme Mug** — $12.00 USD, one-time
   - **Acme T-Shirt** — $25.00 USD, one-time
   - **Acme Sticker Pack** — $6.00 USD, one-time
3. For each, after saving, click into the product and copy its **Price ID** (starts with `price_...`). You'll need these.

## 3. Define the catalog in code

```ts
// src/lib/products.ts
export type Product = {
  id: string;
  name: string;
  description: string;
  priceId: string; // Stripe Price ID, e.g. price_1AbCdEf...
  priceLabel: string; // for display only
  image: string;
};

export const products: Product[] = [
  {
    id: "mug",
    name: "Acme Mug",
    description: "A sturdy 11oz ceramic mug with the Acme logo.",
    priceId: "price_REPLACE_WITH_MUG_PRICE_ID",
    priceLabel: "$12.00",
    image: "https://placehold.co/400x400?text=Acme+Mug",
  },
  {
    id: "tshirt",
    name: "Acme T-Shirt",
    description: "100% cotton tee, unisex fit, in classic black.",
    priceId: "price_REPLACE_WITH_TSHIRT_PRICE_ID",
    priceLabel: "$25.00",
    image: "https://placehold.co/400x400?text=Acme+T-Shirt",
  },
  {
    id: "stickers",
    name: "Acme Sticker Pack",
    description: "A pack of 5 vinyl stickers, weatherproof.",
    priceId: "price_REPLACE_WITH_STICKERS_PRICE_ID",
    priceLabel: "$6.00",
    image: "https://placehold.co/400x400?text=Acme+Stickers",
  },
];

export function getProductById(id: string): Product | undefined {
  return products.find((p) => p.id === id);
}
```

Replace the three `priceId` placeholders with the real Price IDs you copied from the Dashboard.

## 4. Build the ProductCard component

```tsx
// src/components/ProductCard.tsx
"use client";

import { useState } from "react";
import type { Product } from "@/lib/products";

export default function ProductCard({ product }: { product: Product }) {
  const [loading, setLoading] = useState(false);

  async function handleBuyNow() {
    setLoading(true);
    try {
      const res = await fetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ productId: product.id }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error ?? "Something went wrong");
      }

      const { url } = await res.json();
      window.location.href = url;
    } catch (err) {
      console.error(err);
      alert("Could not start checkout. Please try again.");
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-col overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
      <img src={product.image} alt={product.name} className="h-48 w-full object-cover" />
      <div className="flex flex-1 flex-col gap-2 p-4">
        <h3 className="text-lg font-semibold text-gray-900">{product.name}</h3>
        <p className="flex-1 text-sm text-gray-500">{product.description}</p>
        <div className="flex items-center justify-between pt-2">
          <span className="text-lg font-bold text-gray-900">{product.priceLabel}</span>
          <button
            onClick={handleBuyNow}
            disabled={loading}
            className="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {loading ? "Redirecting…" : "Buy Now"}
          </button>
        </div>
      </div>
    </div>
  );
}
```

## 5. Render the catalog on the homepage

```tsx
// src/app/page.tsx
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

## 6. Create the checkout API route (single item)

This is the server-side code that actually talks to Stripe. It never runs in the browser.

```ts
// src/app/api/checkout/route.ts
import { NextRequest, NextResponse } from "next/server";
import { stripe } from "@/lib/stripe";
import { getProductById } from "@/lib/products";

export async function POST(req: NextRequest) {
  const { productId } = await req.json();

  const product = getProductById(productId);
  if (!product) {
    return NextResponse.json({ error: "Unknown product" }, { status: 400 });
  }

  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";

  const session = await stripe.checkout.sessions.create({
    mode: "payment",
    line_items: [
      {
        price: product.priceId,
        quantity: 1,
      },
    ],
    success_url: `${appUrl}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${appUrl}/cancel`,
    metadata: {
      productId: product.id,
    },
  });

  if (!session.url) {
    return NextResponse.json({ error: "Could not create checkout session" }, { status: 500 });
  }

  return NextResponse.json({ url: session.url });
}
```

Key points:
- `mode: "payment"` means a one-time charge (as opposed to `"subscription"`, covered in Part 11).
- `{CHECKOUT_SESSION_ID}` is a literal placeholder string Stripe substitutes for you — Stripe fills it in when redirecting back, so your success page can look up what was purchased.
- `metadata` lets you stash your own data (like your internal product ID) on the Session, retrievable later from the webhook.

## Checkpoint

- [ ] Three products + prices created in Stripe Dashboard (test mode), Price IDs copied into `src/lib/products.ts`.
- [ ] Homepage renders 3 product cards with images, names, prices, and a "Buy Now" button.
- [ ] Clicking "Buy Now" redirects to a real Stripe-hosted checkout page showing the correct product name and price.
- [ ] Paying with test card `4242 4242 4242 4242` (any future expiry, any CVC/ZIP) completes without error (you'll briefly see a Next.js 404 on `/success` — that's expected, we build it next).

## Next

Continue to **Part 4: Success & Cancel Pages, Reading a Checkout Session**.
