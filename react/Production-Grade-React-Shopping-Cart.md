# 🛒 The Ultimate React Shopping Cart Guide

## *Beginner → Production → Startup-Grade Architecture*

This is the **complete roadmap** of how real engineers build shopping carts and full e-commerce systems in React ecosystems.

We go from:

* 🟢 Basic cart logic
* 🟡 Context API
* 🔴 Redux Toolkit
* 🟣 Full e-commerce system
* ⚫ Startup architecture patterns
* 🟤 Stripe checkout
* ⚪ Production folder structure

---

# 🌟 Big Picture First (Core Mental Model)

A shopping cart is always:

# 👉 an ARRAY of OBJECTS

```js id="cart001"
[
  {
    id: 1,
    name: "Apple",
    price: 2,
    quantity: 1
  }
]
```

---

# 🧠 3 Core Rules (NEVER BREAK THESE)

## 1. Never mutate state

❌ push, splice, direct edits

## 2. Always create new references

✔ map, filter, spread

## 3. Cart is the single source of truth

✔ everything derives from it

---

# 🟢 LEVEL 1 — Core Cart Logic

---

## ➕ Add to Cart

```js id="cart002"
const addToCart = (product) => {
  setCart((prevCart) => {
    const existing = prevCart.find(
      item => item.id === product.id
    );

    if (existing) {
      return prevCart.map(item =>
        item.id === product.id
          ? { ...item, quantity: item.quantity + 1 }
          : item
      );
    }

    return [
      ...prevCart,
      { ...product, quantity: 1 }
    ];
  });
};
```

---

## 🔢 Update Quantity

```js id="cart003"
const increaseQty = (id) => {
  setCart(prev =>
    prev.map(item =>
      item.id === id
        ? { ...item, quantity: item.quantity + 1 }
        : item
    )
  );
};

const decreaseQty = (id) => {
  setCart(prev =>
    prev
      .map(item =>
        item.id === id
          ? { ...item, quantity: item.quantity - 1 }
          : item
      )
      .filter(item => item.quantity > 0)
  );
};
```

---

## 💰 Derived State

```js id="cart004"
const totalPrice = cart.reduce(
  (acc, item) =>
    acc + item.price * item.quantity,
  0
);
```

---

# 🟡 LEVEL 2 — Context API (Global State)

Using React Context API

---

## Problem

Prop drilling:

```text id="cart005"
App → Page → Component → Button
```

---

## Solution: Context

```js id="cart006"
const CartContext = createContext();
```

---

## Provider

```js id="cart007"
export const CartProvider = ({ children }) => {
  const [cart, setCart] = useState([]);

  return (
    <CartContext.Provider value={{ cart, setCart }}>
      {children}
    </CartContext.Provider>
  );
};
```

---

## Hook

```js id="cart008"
export const useCart = () => useContext(CartContext);
```

---

# 🔴 LEVEL 3 — Redux Toolkit (Industry Standard)

Using Redux Toolkit

---

# Why Redux?

Context works for small apps.

Redux is for:

✔ large apps
✔ predictable state
✔ debugging tools
✔ scalable architecture

---

## Slice

```js id="cart009"
const cartSlice = createSlice({
  name: "cart",
  initialState: [],
  reducers: {
    addToCart: (state, action) => {
      const item = state.find(
        i => i.id === action.payload.id
      );

      if (item) {
        item.quantity++;
      } else {
        state.push({
          ...action.payload,
          quantity: 1
        });
      }
    }
  }
});
```

---

## Store

```js id="cart010"
const store = configureStore({
  reducer: {
    cart: cartSlice.reducer
  }
});
```

---

## Why mutation works here

Because Redux Toolkit uses:

# 👉 Immer under the hood

So “mutations” are safely converted.

---

# 🔥 Redux Advanced Patterns

---

## 1. Async Thunks

Used for API calls.

```js id="cart011"
export const fetchProducts = createAsyncThunk(
  "products/fetch",
  async () => {
    const res = await fetch("/api/products");
    return res.json();
  }
);
```

---

## 2. Extra Reducers

```js id="cart012"
extraReducers: (builder) => {
  builder.addCase(fetchProducts.fulfilled, (state, action) => {
    return action.payload;
  });
}
```

---

## 3. Middleware (Logging Example)

```js id="cart013"
const logger = store => next => action => {
  console.log("dispatching", action);
  return next(action);
};
```

---

## 🧠 Why middleware matters

Used for:

* logging
* analytics
* API interceptors
* authentication checks

---

# 🟣 LEVEL 4 — Full E-Commerce System

Using Next.js

---

# Architecture

```text id="cart014"
Frontend (Next.js)
   ↓
Backend API Routes
   ↓
Database
   ↓
Payments (Stripe)
```

---

# Core Features

* authentication
* product catalog
* cart system
* checkout system
* order tracking

---

# 🗂️ Production Folder Structure (IMPORTANT)

---

## Next.js E-commerce Structure

```text id="cart015"
app/
  (auth)/
    login/
    register/

  (shop)/
    products/
    cart/
    checkout/

  api/
    products/
    checkout/
    webhooks/

features/
  cart/
  products/
  auth/

components/
  ui/
  layout/

lib/
  db/
  stripe/
  auth/

store/
  cartSlice.ts
  userSlice.ts
```

---

# 🧠 Why this structure works

✔ feature-based grouping
✔ scalable
✔ used in startups
✔ separation of concerns

---

# 🟤 LEVEL 5 — Full Stripe Checkout (Step-by-Step)

Using Stripe payments system

---

# Step 1 — Install Stripe

```bash id="cart016"
npm install stripe @stripe/stripe-js
```

---

# Step 2 — Create Checkout API

```js id="cart017"
import Stripe from "stripe";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export async function POST(req) {
  const { cart } = await req.json();

  const session = await stripe.checkout.sessions.create({
    payment_method_types: ["card"],
    line_items: cart.map(item => ({
      price_data: {
        currency: "usd",
        product_data: {
          name: item.name
        },
        unit_amount: item.price * 100
      },
      quantity: item.quantity
    })),
    mode: "payment",
    success_url: "http://localhost:3000/success",
    cancel_url: "http://localhost:3000/cancel"
  });

  return Response.json({ url: session.url });
}
```

---

# Step 3 — Redirect User

```js id="cart018"
const handleCheckout = async () => {
  const res = await fetch("/api/checkout", {
    method: "POST",
    body: JSON.stringify({ cart })
  });

  const data = await res.json();
  window.location.href = data.url;
};
```

---

# 🧠 What is happening?

```text id="cart019"
Cart → API → Stripe Session → Payment Page
```

---

# 🟤 Stripe Flow Summary

✔ frontend sends cart
✔ backend creates session
✔ Stripe handles payment
✔ redirect back to success page

---

# ⚫ LEVEL 6 — Startup React Architecture Patterns

---

# 1. Feature-Based Design

```text id="cart020"
features/
  cart/
  auth/
  checkout/
```

---

# 2. Smart vs Dumb Components

### Smart (logic)

* state
* API calls

### Dumb (UI)

* buttons
* cards
* layouts

---

# 3. Custom Hooks Pattern

```js id="cart021"
function useCart() {
  const [cart, setCart] = useState([]);
  return { cart };
}
```

---

# 4. Service Layer Pattern

```js id="cart022"
export const cartService = {
  addItem,
  removeItem,
  clearCart
};
```

---

# 5. API Layer Separation

```text id="cart023"
UI → service → API → backend
```

---

# 🧠 Why startups use this

✔ maintainable
✔ scalable
✔ testable
✔ team-friendly

---

# ⚪ LEVEL 7 — Real Startup Codebase Walkthrough

---

# What real companies do

A production React app looks like:

---

## 1. Multiple state systems

* Redux (global)
* Context (auth/theme)
* local state (UI)

---

## 2. API abstraction layer

```js id="cart024"
api/
  client.ts
  products.ts
  orders.ts
```

---

## 3. Separation of concerns

```text id="cart025"
UI ≠ logic ≠ data fetching ≠ state
```

---

## 4. Reusable design system

* buttons
* modals
* inputs
* cards

---

## 5. Performance optimization

* memoization
* lazy loading
* code splitting

---

# 🧠 Startup Mental Model

```text id="cart026"
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

# 🏁 FINAL EVOLUTION PATH

You now understand:

---

## 🟢 Beginner

React cart logic

## 🟡 Intermediate

Context API global state

## 🔴 Advanced

Redux Toolkit + middleware + async thunks

## 🟣 Professional

Full Next.js e-commerce system

## 🟤 Industry

Stripe checkout integration

## ⚫ Startup Level

Architecture patterns used in real companies

---

# 🚀 Final Takeaway

A shopping cart is NOT just a feature.

It teaches:

* state design
* immutability
* architecture thinking
* async systems
* backend integration
* production engineering patterns

