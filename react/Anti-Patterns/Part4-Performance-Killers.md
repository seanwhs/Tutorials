# Part 4: The Performance and Hydration Killers

## The Habit You Need to Break

This final part covers three silent killers of React app performance and correctness: using array index as a `key`, wrapping your entire app in one giant Context provider, and misplacing (or omitting) Suspense boundaries. It closes with a practical guide to deploying your React 19 app on free hosting tiers, and a summary of why all these patterns together shrink your client bundle.

---

## 1. The Anti-Pattern: Index as a Key

```tsx
// components/TodoList.tsx (DO NOT COPY)
"use client";

import { useState } from "react";

interface Todo {
  text: string;
}

export default function TodoList() {
  const [todos, setTodos] = useState<Todo[]>([
    { text: "Buy milk" },
    { text: "Walk dog" },
  ]);

  function removeFirst() {
    setTodos((prev) => prev.slice(1));
  }

  return (
    <div>
      <button onClick={removeFirst}>Remove First</button>
      <ul>
        {todos.map((todo, index) => (
          // Anti-pattern: index changes identity as items shift
          <li key={index}>
            <input defaultValue={todo.text} />
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### The Problem, Explained Simply
When you remove "Buy milk" (index 0), "Walk dog" shifts from index 1 to index 0. React thinks the item **at key `0`** just changed its text, and reuses the existing `<input>` DOM node with the new text — this can leave stale uncontrolled input values, broken form state, mismatched animations, and in SSR/hydration contexts, mismatches between server-rendered markup and client re-renders if list order differs.

**The fix:** use a stable, unique identifier from your actual data.

```tsx
// components/TodoList.tsx (React 19 — correct)
"use client";

import { useState } from "react";

interface Todo {
  id: string;
  text: string;
}

export default function TodoList() {
  const [todos, setTodos] = useState<Todo[]>([
    { id: "t1", text: "Buy milk" },
    { id: "t2", text: "Walk dog" },
  ]);

  function removeFirst() {
    setTodos((prev) => prev.slice(1));
  }

  return (
    <div>
      <button onClick={removeFirst}>Remove First</button>
      <ul>
        {todos.map((todo) => (
          <li key={todo.id}>
            <input defaultValue={todo.text} />
          </li>
        ))}
      </ul>
    </div>
  );
}
```

---

## 2. The Anti-Pattern: One Giant Context Wrapping Everything

```tsx
// context/AppContext.tsx (DO NOT COPY)
"use client";

import { createContext, useState, ReactNode } from "react";

interface AppState {
  theme: "light" | "dark";
  user: { name: string } | null;
  notifications: string[];
  cartCount: number;
}

export const AppContext = createContext<AppState | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AppState>({
    theme: "light",
    user: null,
    notifications: [],
    cartCount: 0,
  });

  return (
    <AppContext.Provider value={{ ...state, setState } as any}>
      {children}
    </AppContext.Provider>
  );
}
```

### The Problem, Explained Simply
Every field lives in one object, in one Provider, at the root of the app. When `cartCount` changes, **every** component reading `AppContext` — even ones that only care about `theme` — re-renders, because Context consumers re-render whenever the Provider's `value` reference changes, regardless of which field they actually use.

**The fix:** split Context by concern, and keep providers as low in the tree as possible.

```tsx
// context/ThemeContext.tsx
"use client";
import { createContext, useState, ReactNode } from "react";

export const ThemeContext = createContext<"light" | "dark">("light");

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme] = useState<"light" | "dark">("light");
  return <ThemeContext.Provider value={theme}>{children}</ThemeContext.Provider>;
}
```

```tsx
// context/CartContext.tsx
"use client";
import { createContext, useState, ReactNode } from "react";

interface CartContextValue {
  count: number;
  increment: () => void;
}

export const CartContext = createContext<CartContextValue | null>(null);

export function CartProvider({ children }: { children: ReactNode }) {
  const [count, setCount] = useState(0);
  return (
    <CartContext.Provider value={{ count, increment: () => setCount((c) => c + 1) }}>
      {children}
    </CartContext.Provider>
  );
}
```

```tsx
// app/layout.tsx
import { ThemeProvider } from "@/context/ThemeContext";
import { CartProvider } from "@/context/CartContext";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <ThemeProvider>
          <CartProvider>{children}</CartProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
```

Now a `cartCount` update only re-renders components subscribed to `CartContext` — the theme-reading components are untouched.

---

## 3. Proper Suspense Boundary Placement

```tsx
// Anti-pattern: one Suspense boundary around the entire page
// blocks the ENTIRE page behind the slowest data fetch
export default function DashboardPage() {
  return (
    <Suspense fallback={<FullPageSpinner />}>
      <Header />
      <SlowAnalyticsWidget />
      <FastUserGreeting />
    </Suspense>
  );
}
```

```tsx
// components/DashboardPage.tsx (React 19 — granular boundaries)
import { Suspense } from "react";
import Header from "@/components/Header";
import SlowAnalyticsWidget from "@/components/SlowAnalyticsWidget";
import FastUserGreeting from "@/components/FastUserGreeting";

export default function DashboardPage() {
  return (
    <>
      <Header />
      {/* Fast content renders immediately, unblocked */}
      <FastUserGreeting />
      {/* Only the slow widget shows a fallback, and only for itself */}
      <Suspense fallback={<WidgetSkeleton />}>
        <SlowAnalyticsWidget />
      </Suspense>
    </>
  );
}
```

**Rule of thumb:** put Suspense boundaries around the *slowest, least critical* piece of UI, as close to that piece as possible — never around content that's ready fast just because it's a sibling of something slow. This lets the server stream fast content immediately and patch in slow content later, instead of blocking everything on the slowest fetch.

---

## 4. Bonus: How to Deploy (Free Tiers)

### Option A: Vercel (native Next.js support)

1. Push your project to GitHub.
2. Go to vercel.com, click "Add New Project," import your repo.
3. Vercel auto-detects Next.js — no config needed for standard App Router projects.
4. Add environment variables (API keys, DB URLs) in Project Settings → Environment Variables.
5. Click Deploy. Every push to `main` auto-deploys; every PR gets a preview URL.

```bash
# Or deploy from the CLI
npm i -g vercel
vercel --prod
```

### Option B: Netlify (works with Next.js via adapter)

1. Push your project to GitHub.
2. Go to netlify.com, "Add new site" → "Import an existing project."
3. Netlify's build settings for Next.js: build command `next build`, publish directory handled automatically by the Next.js Runtime plugin (`@netlify/plugin-nextjs`, auto-installed).
4. Add environment variables in Site Settings → Environment Variables.
5. Click Deploy.

```bash
# Or deploy from the CLI
npm i -g netlify-cli
netlify deploy --prod
```

### Post-Deploy Checklist
- [ ] Confirm `"use server"` functions only run server-side (check no secrets leak into client bundle — use your host's bundle analyzer)
- [ ] Confirm environment variables are set in the hosting dashboard, not just `.env.local`
- [ ] Test Suspense fallbacks under real network conditions (throttle in DevTools)
- [ ] Verify hydration has zero console warnings in production build (`next build && next start` locally first)

---

## 5. Why All of This Shrinks Your Bundle

Every anti-pattern fixed in this series removes client-side JavaScript:

| Fix | Bundle Impact |
|---|---|
| Compiler replaces manual `useMemo`/`useCallback`/`memo` | Removes repetitive wrapper code and dependency-array logic from every component |
| Server Actions replace client `fetch` + state machines | Data-fetching logic and validation stay server-side, never shipped to the browser |
| Default-to-Server-Components | Only interactive leaf components (`"use client"`) and their dependencies are bundled for the client; everything else renders to HTML and ships zero JS |
| No `forwardRef` wrappers | Marginally leaner component definitions, clearer tree |
| Split Context + granular Suspense | Fewer unnecessary re-renders means less JS execution work at runtime (not bundle size, but real perceived performance) |

**The throughline of this whole series:** React 19's model pushes as much work as possible to the server and the compiler, so the JavaScript that actually reaches the user's browser is the smallest, most essential subset — just the interactive parts.

---

## Quick Checklist

- [ ] All list `key` props use a stable unique ID, never the array index
- [ ] Context is split by concern (theme, cart, user, etc.), not one mega-object
- [ ] Providers are placed as low in the tree as their consumers require, not always at the root
- [ ] Suspense boundaries wrap only the specific slow subtree, not the whole page
- [ ] Production build (`next build`) shows no hydration mismatch warnings
- [ ] App deployed and verified on Vercel or Netlify free tier
- [ ] Bundle analyzer confirms server-only code isn't leaking into the client bundle

---

## Series Complete

You've now covered all 4 parts of **Breaking Bad Habits: The React 19 Anti-Patterns Guide**:
1. The Memoization Trap → trust the Compiler
2. The Data Fetching and Form Muddle → use Actions, `useActionState`, `useFormStatus`, `useOptimistic`
3. The Component Bloat → ref as a prop, `use()`, proper Server/Client splitting
4. The Performance and Hydration Killers → stable keys, split Context, granular Suspense, and how to ship it
