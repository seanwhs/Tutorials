**# 🛒 The  React Shopping Cart Guide**  
**Beginner → Production → Startup-Grade Architecture**

### 🌟 Big Picture First (Core Mental Model)

A shopping cart in React is **always an array of objects**:

```js
[
  {
    id: 1,
    name: "Apple",
    price: 2.99,
    quantity: 1
  }
]
```

Think of it like a spreadsheet where each row is a product with its quantity. The cart array is the **single source of truth** — everything else (totals, UI) is derived from it.

---

### 🧠 3 Core Rules (Never Break These)

1. **Never mutate state** — No `push`, `splice`, or direct property edits.
2. **Always create new references** — Use `map`, `filter`, spread (`...`).
3. **Cart is the single source of truth** — Derive totals, counts, etc. Do not duplicate state.

---

## 🟢 LEVEL 1 — Core Cart Logic (Beginner)

### State Setup
```jsx
import { useState, useEffect } from "react";

const [cart, setCart] = useState([]);
```

### ➕ Add to Cart (Most Important Function)
```js
const addToCart = (product) => {
  setCart((prevCart) => {
    const existing = prevCart.find(item => item.id === product.id);

    if (existing) {
      return prevCart.map(item =>
        item.id === product.id
          ? { ...item, quantity: item.quantity + 1 }
          : item
      );
    }

    return [...prevCart, { ...product, quantity: 1 }];
  });
};
```

**Why this works**:
- Functional update (`prevCart =>`) gets the latest state.
- `find()` checks for existing items.
- `map()` + spread creates a new array and new object (immutability).
- New items get `quantity: 1`.

### 🔢 Quantity Updates
```js
const increaseQty = (id) => {
  setCart(prev =>
    prev.map(item =>
      item.id === id ? { ...item, quantity: item.quantity + 1 } : item
    )
  );
};

const decreaseQty = (id) => {
  setCart(prev =>
    prev
      .map(item =>
        item.id === id ? { ...item, quantity: item.quantity - 1 } : item
      )
      .filter(item => item.quantity > 0)
  );
};

const removeFromCart = (id) => {
  setCart(prev => prev.filter(item => item.id !== id));
};
```

### 💰 Derived State (Critical Concept)
```js
const totalPrice = cart.reduce((acc, item) => acc + item.price * item.quantity, 0);
const totalItems = cart.reduce((acc, item) => acc + item.quantity, 0);
```

**Never** store totals in separate state — derive them to avoid sync bugs.

---

### 🟡 LEVEL 2 — Context API (Simple Global State)

```jsx
// CartContext.js
import { createContext, useContext, useState } from 'react';

const CartContext = createContext();

export const CartProvider = ({ children }) => {
  const [cart, setCart] = useState([]);

  // All cart functions here...

  return (
    <CartContext.Provider value={{ cart, addToCart, increaseQty, decreaseQty, removeFromCart, totalPrice, totalItems }}>
      {children}
    </CartContext.Provider>
  );
};

export const useCart = () => useContext(CartContext);
```

Wrap your app with `<CartProvider>` and use `useCart()` anywhere.

---

### 🔴 LEVEL 3 — Redux Toolkit (Industry Standard for Larger Apps)

```js
// features/cart/cartSlice.ts
import { createSlice } from '@reduxjs/toolkit';

const cartSlice = createSlice({
  name: 'cart',
  initialState: [],
  reducers: {
    addToCart: (state, action) => {
      const item = state.find(i => i.id === action.payload.id);
      if (item) {
        item.quantity++;
      } else {
        state.push({ ...action.payload, quantity: 1 });
      }
    },
    // other reducers...
  }
});
```

**Redux Toolkit uses Immer** under the hood, so “mutations” are safe.

**Store setup**:
```js
const store = configureStore({
  reducer: { cart: cartSlice.reducer }
});
```

**Async Thunks** and **middleware** are easy to add for API calls, logging, etc.

---

### 🟣 LEVEL 4 — Full E-Commerce Architecture (Next.js)

#### Recommended Production Folder Structure
```text
app/
  (auth)/
  (shop)/
    products/
    cart/
    checkout/
  api/
    checkout/
    webhooks/

features/          # Feature-based
  cart/
  products/
  auth/

components/
  ui/
  layout/

lib/
  db/
  stripe/
  utils/

store/             # Redux slices
```

**Key Benefits**: Scalable, team-friendly, clear separation of concerns.

---

### 🟤 LEVEL 5 — Stripe Checkout Integration

1. **Install**: `npm install stripe @stripe/stripe-js`

2. **API Route** (`app/api/checkout/route.ts`)
```js
import Stripe from 'stripe';
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export async function POST(req) {
  const { cart } = await req.json();

  const session = await stripe.checkout.sessions.create({
    payment_method_types: ['card'],
    line_items: cart.map(item => ({
      price_data: {
        currency: 'usd',
        product_data: { name: item.name },
        unit_amount: Math.round(item.price * 100),
      },
      quantity: item.quantity,
    })),
    mode: 'payment',
    success_url: `${process.env.NEXT_PUBLIC_URL}/success`,
    cancel_url: `${process.env.NEXT_PUBLIC_URL}/cancel`,
  });

  return Response.json({ url: session.url });
}
```

3. **Frontend Trigger**
```js
const handleCheckout = async () => {
  const res = await fetch('/api/checkout', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ cart }),
  });
  const { url } = await res.json();
  window.location.href = url;
};
```

---

### ⚫ LEVEL 6 — Startup-Grade Patterns

- **Feature-based organization**
- **Smart vs Dumb components** (logic vs pure UI)
- **Custom hooks** for reusable logic
- **Service layer** (`cartService.ts`)
- **API abstraction layer**
- **Multiple state solutions**: Redux (global), Context (theme/auth), local state (UI)
- **Performance**: `React.memo`, `useCallback`, code splitting, lazy loading
- **Persistence**: localStorage + `useEffect`

**Mental Model**:
```
UI Layer
   ↓
Logic Layer (hooks/services)
   ↓
State Layer (Redux/Context)
   ↓
API Layer
   ↓
Backend
```

---

### 🚀 Pro Tips & Common Mistakes

**Do**:
- Persist cart to `localStorage`
- Use `item.id` as `key` (never index)
- Memoize functions and components for performance
- Handle edge cases (negative quantities, etc.)

**Avoid**:
- Mutating state directly
- Storing derived values in state
- Prop drilling (use Context/Redux)

---

### 🏁 Final Takeaway

A shopping cart is much more than a feature — it teaches you:
- Immutability & state design
- `map`/`filter`/`reduce` in real apps
- Derived state
- Architecture thinking
- Backend integration (Stripe, APIs)
- Scalable patterns used by real companies


Start with **Level 1** (pure React), then progressively add Context → Redux → Next.js + Stripe as your app grows.

You now have the complete roadmap from beginner logic to startup-grade architecture. Build it, ship it, and iterate! 🚀
