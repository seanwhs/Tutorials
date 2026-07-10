# Part 1: The Memoization Trap

## The Habit You Need to Break

If you learned React during the hooks era (2019-2023), you were probably taught to wrap almost everything in `useMemo`, `useCallback`, and `React.memo` "for performance." Senior engineers reviewed PRs demanding you memoize every callback passed as a prop. This created a habit: **memoize defensively, everywhere, just in case.**

React 19 ships with the **React Compiler**, which does this work for you, automatically, at build time — and does it better than most humans do it by hand.

---

## 1. The Anti-Pattern

```tsx
// components/Dashboard.tsx  (React 18 style — DO NOT COPY)
"use client";

import { useState, useMemo, useCallback, memo } from "react";

interface Invoice {
  id: string;
  client: string;
  amount: number;
  paid: boolean;
}

interface InvoiceRowProps {
  invoice: Invoice;
  onToggle: (id: string) => void;
}

// Manually wrapped in memo() to "prevent re-renders"
const InvoiceRow = memo(function InvoiceRow({ invoice, onToggle }: InvoiceRowProps) {
  return (
    <tr>
      <td>{invoice.client}</td>
      <td>${invoice.amount.toFixed(2)}</td>
      <td>
        <button onClick={() => onToggle(invoice.id)}>
          {invoice.paid ? "Paid" : "Mark Paid"}
        </button>
      </td>
    </tr>
  );
});

export default function Dashboard({ invoices }: { invoices: Invoice[] }) {
  const [filter, setFilter] = useState("");
  const [paidMap, setPaidMap] = useState<Record<string, boolean>>({});

  // Manually memoized derived value
  const filteredInvoices = useMemo(() => {
    return invoices.filter((inv) =>
      inv.client.toLowerCase().includes(filter.toLowerCase())
    );
  }, [invoices, filter]);

  // Manually memoized total
  const total = useMemo(() => {
    return filteredInvoices.reduce((sum, inv) => sum + inv.amount, 0);
  }, [filteredInvoices]);

  // Manually memoized callback so InvoiceRow's memo() doesn't break
  const handleToggle = useCallback((id: string) => {
    setPaidMap((prev) => ({ ...prev, [id]: !prev[id] }));
  }, []);

  return (
    <div>
      <input
        value={filter}
        onChange={(e) => setFilter(e.target.value)}
        placeholder="Filter by client..."
      />
      <p>Total: ${total.toFixed(2)}</p>
      <table>
        <tbody>
          {filteredInvoices.map((inv) => (
            <InvoiceRow
              key={inv.id}
              invoice={{ ...inv, paid: paidMap[inv.id] ?? inv.paid }}
              onToggle={handleToggle}
            />
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

### Why This Feels "Right" But Isn't
- Every derived value gets `useMemo`, every function gets `useCallback`, every child gets `memo()` — "just to be safe."
- Dependency arrays are easy to get wrong (stale closures, missing deps, exhaustive-deps lint fighting you).
- The code is **twice as long** as the logic it expresses. A reviewer has to check whether the memoization is even correct, on top of checking the actual business logic.
- Most of this memoization provides **zero measurable benefit** — the components are cheap to re-render anyway. You paid a readability tax for nothing.

---

## 2. The Problem, Explained Simply

`useMemo`/`useCallback` exist to solve one problem: **skip expensive recalculation or prevent a child from re-rendering when its props haven't meaningfully changed.** But:

1. **Humans are bad at deciding what's "expensive."** Most components aren't expensive enough to matter, yet the pattern got applied everywhere anyway.
2. **Manual memoization is easy to invalidate silently.** Forget one dependency, or introduce a new inline object, and the memoization quietly stops working — with no error, just lost performance (or worse, a stale-value bug).
3. **It couples performance code with business logic**, making both harder to read and change.

React 19's compiler solves this at the *build* level: it statically analyzes your component's data flow and inserts the equivalent of `useMemo`/`useCallback`/`memo` automatically, correctly, everywhere it's safe to do so — without you writing a single dependency array.

---

## 3. The Modern React 19 Solution

### Step 1: Install the React Compiler

```bash
npm install --save-dev babel-plugin-react-compiler@rc eslint-plugin-react-hooks@^5
```

### Step 2: Enable it in your framework config

**Next.js (`next.config.ts`):**
```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    reactCompiler: true,
  },
};

export default nextConfig;
```

**Vite (`babel.config.js` via `vite-plugin-babel` or `@vitejs/plugin-react`):**
```js
// vite.config.ts
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [["babel-plugin-react-compiler", {}]],
      },
    }),
  ],
});
```

### Step 3: Turn on the compiler-aware ESLint rule

```jsonc
// .eslintrc.json
{
  "plugins": ["react-hooks"],
  "rules": {
    "react-hooks/react-compiler": "error"
  }
}
```

This rule flags code that *breaks* compiler assumptions (e.g., conditional hook calls) so you get compile-time safety instead of silent opt-outs.

### Step 4: Delete the manual memoization

```tsx
// components/Dashboard.tsx  (React 19 + Compiler — write it this way)
"use client";

import { useState } from "react";

interface Invoice {
  id: string;
  client: string;
  amount: number;
  paid: boolean;
}

interface InvoiceRowProps {
  invoice: Invoice;
  onToggle: (id: string) => void;
}

// No memo(). The compiler decides if/when to skip re-renders.
function InvoiceRow({ invoice, onToggle }: InvoiceRowProps) {
  return (
    <tr>
      <td>{invoice.client}</td>
      <td>${invoice.amount.toFixed(2)}</td>
      <td>
        <button onClick={() => onToggle(invoice.id)}>
          {invoice.paid ? "Paid" : "Mark Paid"}
        </button>
      </td>
    </tr>
  );
}

export default function Dashboard({ invoices }: { invoices: Invoice[] }) {
  const [filter, setFilter] = useState("");
  const [paidMap, setPaidMap] = useState<Record<string, boolean>>({});

  // Plain derived values. The compiler memoizes these automatically
  // because it can see `invoices` and `filter` are the only inputs.
  const filteredInvoices = invoices.filter((inv) =>
    inv.client.toLowerCase().includes(filter.toLowerCase())
  );

  const total = filteredInvoices.reduce((sum, inv) => sum + inv.amount, 0);

  // Plain function. The compiler gives it a stable identity when needed.
  function handleToggle(id: string) {
    setPaidMap((prev) => ({ ...prev, [id]: !prev[id] }));
  }

  return (
    <div>
      <input
        value={filter}
        onChange={(e) => setFilter(e.target.value)}
        placeholder="Filter by client..."
      />
      <p>Total: ${total.toFixed(2)}</p>
      <table>
        <tbody>
          {filteredInvoices.map((inv) => (
            <InvoiceRow
              key={inv.id}
              invoice={{ ...inv, paid: paidMap[inv.id] ?? inv.paid }}
              onToggle={handleToggle}
            />
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

**Line count dropped from ~75 to ~50. Zero dependency arrays. Zero `memo()` wrappers. Same (or better) runtime performance.**

---

## 4. Migration Steps (For Existing Codebases)

1. **Install** `babel-plugin-react-compiler` and `eslint-plugin-react-hooks@5` (Step 1-3 above).
2. **Run the compiler in "opt-in" mode first** if you have a large codebase — most frameworks let you annotate directories or use a compiler-generated report to see which components are safe to compile.
3. **Delete `useCallback`/`useMemo` calls** whose *only* purpose is referential stability for children or cheap derived values. Keep ones wrapping genuinely expensive computation (see Step 5).
4. **Remove `React.memo()` wrappers** from child components — the compiler applies the equivalent optimization automatically based on prop usage analysis.
5. **Run your test suite and the ESLint compiler rule.** The lint rule will catch any hook-rule violations that would silently disable compilation for that component (e.g., calling a hook conditionally).
6. **Verify with React DevTools Profiler** — record before/after renders to confirm re-render counts didn't regress.

---

## 5. When You STILL Need Manual Memoization

The compiler handles *component render* memoization. It does **not** know your code's semantic intent for these cases — keep `useMemo` for:

```tsx
// Genuinely expensive computation (e.g., processing 100k rows)
const sortedHugeDataset = useMemo(
  () => hugeDataset.toSorted((a, b) => a.value - b.value),
  [hugeDataset]
);

// Referential stability required by an external library
// that does its own reference-equality checks (e.g., a canvas lib)
const chartConfig = useMemo(() => ({ theme: "dark", animate: true }), []);
```

**Rule of thumb:** if the compiler is enabled and linting is clean, default to *no* manual memoization. Add it back only when profiling shows a real, measured problem — not speculatively.

---

## Quick Checklist

- [ ] `babel-plugin-react-compiler` installed and enabled in framework config
- [ ] `eslint-plugin-react-hooks@5` with `react-compiler` rule set to `"error"`
- [ ] No `React.memo()` wrapping components "just in case"
- [ ] No `useCallback` around handlers passed only to compiler-covered children
- [ ] No `useMemo` around cheap derived values (filters, sums, string formatting)
- [ ] `useMemo` retained only for measured-expensive computation or 3rd-party referential-equality requirements
- [ ] Profiled with React DevTools to confirm no regression

**Next:** Part 2: The Data Fetching & Form Muddle — replacing `useEffect` fetches and manual loading state with Server Actions and `useActionState`.
