# Part 7: Styling & Polish

## 7.1 Concept: Why Utility-First CSS Won

Recall Part 3.6: hand-written CSS files accumulate specificity conflicts as a project grows — two developers both touch `.card` in different files, and now there's a bug that only appears in production. Utility-first CSS (Tailwind) sidesteps this entirely: styles live *on the element*, as flat, single-purpose classes with predictable, low, uniform specificity. Nobody "overrides" `.card` because there is no `.card` — there's just `rounded-md bg-white p-3 shadow-sm` directly on the `<li>`.

The tradeoff, honestly stated: HTML gets more verbose, and there's a learning curve to the utility names. Professionally, the tradeoff is judged worth it at scale — component-scoped styling with zero cross-file specificity fights.

## 7.2 Installing Tailwind CSS v4 (CSS-First Config)

If you used `create-next-app` with the Tailwind option in Part 2, it's already wired up. Tailwind v4 changed configuration significantly from v3 — there is no `tailwind.config.js` by default anymore. Configuration lives directly in CSS:

```bash
npm install tailwindcss @tailwindcss/postcss postcss
```

```css
/* app/globals.css */
@import "tailwindcss";

@theme {
  --color-brand-50: #eff6ff;
  --color-brand-500: #2563eb;
  --color-brand-600: #1d4ed8;
  --font-sans: "Inter", system-ui, sans-serif;
  --radius-card: 0.5rem;
}

@layer base {
  body {
    @apply bg-slate-50 text-slate-900 font-sans;
  }
}
```

`@theme` defines design tokens as CSS custom properties, which Tailwind then generates utility classes from automatically (`bg-brand-500`, `text-brand-600`, `rounded-card`, etc.) — no JS config file, no restart required to see token changes reflected.

```javascript
// postcss.config.mjs
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
```

## 7.3 Rebuilding DevBoard's Board with Tailwind

Directly comparable to Part 3.4's hand-written CSS Grid/Flexbox — same layout, expressed as utilities:

```tsx
// app/board/page.tsx
export default async function BoardPage() {
  const board = await getBoard();

  return (
    <main className="grid grid-cols-1 gap-4 p-6 md:grid-cols-3">
      {board.columns.map((column) => (
        <section
          key={column.id}
          className="flex flex-col gap-2 rounded-lg bg-slate-100 p-3"
        >
          <h2 className="px-1 text-sm font-semibold text-slate-600">
            {column.name}
          </h2>
          <ul className="flex flex-col gap-2">
            {column.cards.map((card) => (
              <li
                key={card.id}
                className="rounded-card bg-white p-3 shadow-sm ring-1 ring-slate-200"
              >
                <h3 className="text-sm font-medium">{card.title}</h3>
              </li>
            ))}
          </ul>
        </section>
      ))}
    </main>
  );
}
```

`grid-cols-1 md:grid-cols-3` is the responsive breakpoint pattern (Part 3.5's media query, now inline): mobile-first by default, `md:` prefix overrides at the medium breakpoint and up.

## 7.4 Installing shadcn/ui

shadcn/ui is not a component *library* you `npm install` and import from `node_modules` — it's a CLI that copies component source code directly into your project, so you own and can edit every line:

```bash
npx shadcn@latest init
```

Answer the prompts (base color, CSS variables — accept defaults for a new Next.js 16 + Tailwind v4 project). This creates a `components.json` config and a `lib/utils.ts` helper (the `cn()` classname merger you'll use constantly).

Add components as needed:

```bash
npx shadcn@latest add button
npx shadcn@latest add card
npx shadcn@latest add input
npx shadcn@latest add dialog
npx shadcn@latest add label
```

Each command adds a real `.tsx` file under `components/ui/` — inspect them, they're plain React + Tailwind, nothing magic.

## 7.5 Rebuilding the Add-Card Form with shadcn/ui

```tsx
// app/components/AddCardDialog.tsx
"use client";

import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { createCard } from "@/app/actions/cards";

export function AddCardDialog({ columnId }: { columnId: string }) {
  const [open, setOpen] = useState(false);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="ghost" size="sm" className="justify-start text-slate-500">
          + Add card
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Add a new card</DialogTitle>
        </DialogHeader>
        <form
          action={async (formData) => {
            await createCard(formData);
            setOpen(false);
          }}
          className="flex flex-col gap-4"
        >
          <input type="hidden" name="columnId" value={columnId} />
          <div className="flex flex-col gap-2">
            <Label htmlFor="title">Title</Label>
            <Input id="title" name="title" required autoFocus />
          </div>
          <Button type="submit">Save card</Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}
```

Notice this composes directly with Part 6's Server Action (`createCard`) — shadcn/ui components are just styled primitives; all the data logic from Part 6 is unchanged.

## 7.6 Using `cn()` for Conditional Classes

A recurring professional pattern once components have variant states (selected, disabled, error):

```tsx
// lib/utils.ts (generated by shadcn init)
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

```tsx
import { cn } from "@/lib/utils";

function CardBadge({ isOverdue }: { isOverdue: boolean }) {
  return (
    <span
      className={cn(
        "rounded-full px-2 py-0.5 text-xs font-medium",
        isOverdue ? "bg-red-100 text-red-700" : "bg-slate-100 text-slate-600"
      )}
    >
      {isOverdue ? "Overdue" : "On track"}
    </span>
  );
}
```

`twMerge` (inside `cn`) resolves conflicting Tailwind classes intelligently (e.g., if two conditional branches both set a `bg-*` class, the later one wins cleanly instead of both being applied) — plain `clsx` alone can't do that.

## 7.7 Dark Mode (A Practical Polish Feature)

```css
/* app/globals.css */
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));
```

```tsx
// app/components/ThemeToggle.tsx
"use client";
import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";

export function ThemeToggle() {
  const [isDark, setIsDark] = useState(false);

  useEffect(() => {
    document.documentElement.classList.toggle("dark", isDark);
  }, [isDark]);

  return (
    <Button variant="outline" size="sm" onClick={() => setIsDark((d) => !d)}>
      {isDark ? "Light mode" : "Dark mode"}
    </Button>
  );
}
```

```tsx
<section className="flex flex-col gap-2 rounded-lg bg-slate-100 p-3 dark:bg-slate-800">
  <h2 className="text-sm font-semibold text-slate-600 dark:text-slate-300">
    {column.name}
  </h2>
</section>
```

## Exercise Challenge

1. Convert the `.card:focus-visible` accessibility rule from Part 3's Exercise Solution into Tailwind utilities on the shadcn `<Card>`-based card component.
2. Add a `variant` prop to a custom `PriorityBadge` component (`"low" | "medium" | "high"`) using `cn()` to switch background colors, and render it inside each DevBoard card.

## Solution & Explanation

```tsx
// Focus-visible in Tailwind:
<li
  tabIndex={0}
  className="rounded-card bg-white p-3 shadow-sm ring-1 ring-slate-200 focus-visible:outline-2 focus-visible:outline-blue-600 focus-visible:outline-offset-2"
>
```

```tsx
// components/PriorityBadge.tsx
import { cn } from "@/lib/utils";

const variants = {
  low: "bg-slate-100 text-slate-600",
  medium: "bg-amber-100 text-amber-700",
  high: "bg-red-100 text-red-700",
};

export function PriorityBadge({ priority }: { priority: "low" | "medium" | "high" }) {
  return (
    <span className={cn("rounded-full px-2 py-0.5 text-xs font-medium", variants[priority])}>
      {priority}
    </span>
  );
}
```

Tailwind's `focus-visible:` variant maps directly to the native CSS pseudo-class from Part 3.6 — the underlying browser behavior didn't change, only the authoring ergonomics did.

---
*Next: `Roadmap Tutorial - Part 8: Launch & Iterate`*
