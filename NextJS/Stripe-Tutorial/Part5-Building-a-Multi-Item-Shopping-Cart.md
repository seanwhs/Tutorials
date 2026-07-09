# Part 5: Building a Multi-Item Shopping Cart

Previous: Part 4 (Success and Cancel Pages). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

We need a cart before we can check out multiple products in one Stripe Checkout Session. We keep it simple: client-side React Context state, persisted to localStorage so it survives refreshes without needing a database yet.

## 2. Cart types and context

File: src/components/CartProvider.tsx

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

## 3. Wire the provider into the root layout

File: src/app/layout.tsx — wrap the body contents with CartProvider (it stays a Server Component; CartProvider itself is the "use client" boundary):

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

## 4. Add a cart badge — extract a small client component

File: src/components/CartLink.tsx

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

Update Nav to use it (Nav itself stays a Server Component):

File: src/components/Nav.tsx

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
          <CartLink />
          <Link href="/orders" className="hover:text-gray-900">Orders</Link>
          <Link href="/account" className="hover:text-gray-900">Account</Link>
        </div>
      </div>
    </nav>
  );
}
```

## 5. Add an "Add to Cart" button to ProductCard

Update src/components/ProductCard.tsx: import useCart from "@/components/CartProvider", add a small local addedJustNow state, and render a second button next to Buy Now:

```tsx
const { addToCart } = useCart();
const [added, setAdded] = useState(false);

function handleAddToCart() {
  addToCart(product.id);
  setAdded(true);
  setTimeout(() => setAdded(false), 1000);
}
```

```tsx
<button
  onClick={handleAddToCart}
  className="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
>
  {added ? "Added!" : "Add to Cart"}
</button>
```

Place this button next to the existing "Buy Now" button in the card's footer row.

## 6. Build the Cart page

File: src/app/cart/page.tsx

```tsx
"use client";
import Link from "next/link";
import { useCart } from "@/components/CartProvider";
import { getProductById } from "@/lib/products";

export default function CartPage() {
  const { lines, removeFromCart, updateQuantity, clearCart } = useCart();

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
    (sum, r) => sum + Math.round(parseFloat(r.product!.priceLabel.replace("$", "")) * 100) * r.line.quantity,
    0
  );

  return (
    <main className="mx-auto max-w-3xl px-4 py-10">
      <h1 className="mb-6 text-2xl font-bold text-gray-900">Your Cart</h1>
      <div className="divide-y divide-gray-200 rounded-lg border border-gray-200 bg-white">
        {rows.map(({ line, product }) => (
          <div key={line.productId} className="flex items-center gap-4 p-4">
            <img src={product!.image} alt={product!.name} className="h-16 w-16 rounded object-cover" />
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

      <button className="mt-6 w-full rounded-md bg-indigo-600 px-4 py-3 font-medium text-white hover:bg-indigo-500">
        Checkout
      </button>
    </main>
  );
}
```

The "Checkout" button isn't wired up to Stripe yet — that's Part 6.

## Checkpoint

- [ ] Adding items from the homepage updates the Cart badge count in the nav immediately.
- [ ] Refreshing the page preserves cart contents (backed by localStorage).
- [ ] The Cart page lists correct products, prices, and a correct subtotal.
- [ ] Changing quantity updates the line total and subtotal live.
- [ ] Removing an item and clearing the cart both work and update the nav badge.

## Next

Continue to Part 6: Cart Checkout with Multiple Line Items.
