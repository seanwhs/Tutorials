# Appendix A (2 of 5): Full Codebase Reference — Layout, Nav & Cart Components

Index: "Stripe Tutorial - INDEX (Start Here)". Covers root layout, nav, and cart-related components. See part 1 of 5 for config/lib/schema, part 3 of 5 for homepage/cart/success/cancel pages, part 4 of 5 for orders/pricing/account pages, and part 5 of 5 for all API routes.

## src/app/layout.tsx
```tsx
import type { Metadata } from "next";
import "./globals.css";
import Nav from "@/components/Nav";
import { CartProvider } from "@/components/CartProvider";

export const metadata: Metadata = {
  title: "Acme Shop",
  description: "A demo storefront built with Next.js 16, Tailwind CSS, and Stripe.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-gray-50 antialiased">
        <CartProvider>
          <Nav />
          {children}
        </CartProvider>
      </body>
    </html>
  );
}
```

## src/components/Nav.tsx
```tsx
import Link from "next/link";
import CartLink from "@/components/CartLink";

export default function Nav() {
  return (
    <nav className="border-b border-gray-200 bg-white">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
        <Link href="/" className="text-lg font-bold text-gray-900">Acme Shop</Link>
        <div className="flex items-center gap-6 text-sm font-medium text-gray-600">
          <Link href="/" className="hover:text-gray-900">Shop</Link>
          <Link href="/pricing" className="hover:text-gray-900">Pricing</Link>
          <CartLink />
          <Link href="/orders" className="hover:text-gray-900">Orders</Link>
          <Link href="/account" className="hover:text-gray-900">Account</Link>
        </div>
      </div>
    </nav>
  );
}
```

## src/components/CartLink.tsx
```tsx
"use client";
import Link from "next/link";
import { useCart } from "@/components/CartProvider";

export default function CartLink() {
  const { itemCount } = useCart();
  return (
    <Link href="/cart" className="relative hover:text-gray-900">
      Cart
      {itemCount > 0 && (
        <span className="absolute -right-4 -top-2 flex h-4 w-4 items-center justify-center rounded-full bg-indigo-600 text-[10px] font-bold text-white">
          {itemCount}
        </span>
      )}
    </Link>
  );
}
```

## src/components/CartProvider.tsx
```tsx
"use client";
import { createContext, useContext, useEffect, useState, ReactNode } from "react";

type CartLine = { productId: string; quantity: number };
type CartContextValue = {
  lines: CartLine[];
  addToCart: (productId: string) => void;
  removeFromCart: (productId: string) => void;
  updateQuantity: (productId: string, quantity: number) => void;
  clearCart: () => void;
  itemCount: number;
};

const CartContext = createContext<CartContextValue | null>(null);
const STORAGE_KEY = "acme-shop-cart";

export function CartProvider({ children }: { children: ReactNode }) {
  const [lines, setLines] = useState<CartLine[]>([]);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (raw) setLines(JSON.parse(raw));
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (hydrated) window.localStorage.setItem(STORAGE_KEY, JSON.stringify(lines));
  }, [lines, hydrated]);

  function addToCart(productId: string) {
    setLines((prev) => {
      const existing = prev.find((l) => l.productId === productId);
      if (existing) {
        return prev.map((l) =>
          l.productId === productId ? { ...l, quantity: l.quantity + 1 } : l
        );
      }
      return [...prev, { productId, quantity: 1 }];
    });
  }

  function removeFromCart(productId: string) {
    setLines((prev) => prev.filter((l) => l.productId !== productId));
  }

  function updateQuantity(productId: string, quantity: number) {
    setLines((prev) =>
      prev.map((l) => (l.productId === productId ? { ...l, quantity: Math.max(1, quantity) } : l))
    );
  }

  function clearCart() {
    setLines([]);
  }

  const itemCount = lines.reduce((sum, l) => sum + l.quantity, 0);

  return (
    <CartContext.Provider
      value={{ lines, addToCart, removeFromCart, updateQuantity, clearCart, itemCount }}
    >
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart must be used within a CartProvider");
  return ctx;
}
```

## src/components/ClearCartOnSuccess.tsx
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

## src/components/ErrorBanner.tsx
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

## src/components/ProductCard.tsx
```tsx
"use client";

import { useState } from "react";
import type { Product } from "@/lib/products";
import { useCart } from "@/components/CartProvider";
import ErrorBanner from "@/components/ErrorBanner";

export default function ProductCard({ product }: { product: Product }) {
  const [loading, setLoading] = useState(false);
  const [added, setAdded] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const { addToCart } = useCart();

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
      setErrorMessage(err instanceof Error ? err.message : "Could not start checkout.");
      setLoading(false);
    }
  }

  function handleAddToCart() {
    addToCart(product.id);
    setAdded(true);
    setTimeout(() => setAdded(false), 1000);
  }

  return (
    <div className="flex flex-col overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
      <ErrorBanner message={errorMessage} onDismiss={() => setErrorMessage(null)} />
      <img src={product.image} alt={product.name} className="h-48 w-full object-cover" />
      <div className="flex flex-1 flex-col gap-2 p-4">
        <h3 className="text-lg font-semibold text-gray-900">{product.name}</h3>
        <p className="flex-1 text-sm text-gray-500">{product.description}</p>
        <div className="flex items-center justify-between pt-2">
          <span className="text-lg font-bold text-gray-900">{product.priceLabel}</span>
          <div className="flex gap-2">
            <button
              onClick={handleAddToCart}
              className="rounded-md border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              {added ? "Added!" : "Add to Cart"}
            </button>
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
    </div>
  );
}
```

## Next
Continue to **Appendix A (3 of 5): Homepage, Cart, Success & Cancel Pages**.
