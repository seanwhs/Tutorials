# Part 4: Core Utility Classes Crash Course

## 4.1 Concept Explanation

Tailwind's utility classes map (mostly) 1:1 to CSS properties. This part is a practical, code-first tour through the categories you'll use in 90% of real components, built as actual React 19 components you can drop into the `tw4-mastery` project from Part 2.

## 4.2 Layout: Flexbox & Grid

```tsx
// src/components/LayoutDemo.tsx
export function LayoutDemo() {
  return (
    <div className="space-y-8 p-8">
      {/* Flexbox row, space-between, centered vertically */}
      <div className="flex items-center justify-between rounded-lg bg-slate-100 p-4">
        <span>Left</span>
        <span>Right</span>
      </div>

      {/* Flex column with consistent gaps (gap replaces margin-juggling between children) */}
      <div className="flex flex-col gap-3 rounded-lg bg-slate-100 p-4">
        <div className="rounded bg-white p-2 shadow-sm">Item 1</div>
        <div className="rounded bg-white p-2 shadow-sm">Item 2</div>
      </div>

      {/* CSS Grid: responsive column count via template columns */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="rounded-lg bg-brand-100 p-6 text-center">
            Card {i + 1}
          </div>
        ))}
      </div>
    </div>
  );
}
```

## 4.3 Spacing: Padding, Margin, Gap

| Utility | CSS | Notes |
|---|---|---|
| `p-4` | `padding: 1rem;` | Uses `--spacing-*` scale (1 unit = 0.25rem by default) |
| `px-4` / `py-4` | horizontal / vertical padding | |
| `pt-4` `pr-4` `pb-4` `pl-4` | single-side padding | |
| `m-4` / `mx-auto` | margin / auto-center horizontally | |
| `-mt-4` | negative margin | prefix with `-` |
| `gap-4` / `gap-x-4` / `gap-y-4` | flex/grid gap | preferred over margins between siblings |
| `space-y-4` | margin-top on all but first child | classic "stack spacing" trick, still works in v4 |

```tsx
<div className="mx-auto max-w-2xl px-4 py-12">
  <div className="space-y-4">
    <p className="p-4">Paragraph with all-sides padding.</p>
    <p className="-mt-2 px-4">Pulled up slightly with negative margin.</p>
  </div>
</div>
```

## 4.4 Sizing

```tsx
<div className="h-screen w-full">Full viewport height, full width</div>
<div className="h-64 w-64">Fixed 16rem square (64 * 0.25rem)</div>
<div className="min-h-screen max-w-4xl">Common page-shell pattern</div>
<div className="aspect-video w-full">16:9 box — no manual padding-hack needed</div>
<div className="size-12">Shorthand for w-12 h-12 (v4 keeps this v3.4+ utility)</div>
```

## 4.5 Typography

```tsx
export function TypographyDemo() {
  return (
    <article className="mx-auto max-w-prose space-y-4">
      <h1 className="text-4xl font-extrabold tracking-tight text-slate-900">
        Heading uses text-size, font-weight, tracking
      </h1>
      <p className="text-base leading-relaxed text-slate-600">
        Body copy: text-base sets 1rem font-size with a paired default
        line-height. leading-relaxed overrides to 1.625 for readability.
      </p>
      <p className="truncate text-sm text-slate-400">
        This line truncates with an ellipsis if it overflows its container width.
      </p>
      <blockquote className="border-l-4 border-brand-500 pl-4 italic text-slate-700">
        line-clamp-3 and italic/uppercase/underline all work as expected too.
      </blockquote>
    </article>
  );
}
```

## 4.6 Color & Opacity Modifiers

Tailwind v4 uses `color-mix()` under the hood for the `/opacity` modifier syntax:

```tsx
<div className="bg-brand-500/20 text-brand-900">
  20% opacity brand background, full-opacity brand-900 text
</div>
<div className="border border-slate-900/10">
  10% opacity border — common for subtle dividers on white backgrounds
</div>
```

## 4.7 Borders, Radius, Rings, Shadows

```tsx
<button
  className="rounded-xl border border-slate-200 bg-white px-4 py-2
             shadow-soft ring-1 ring-slate-900/5
             focus:outline-none focus:ring-2 focus:ring-brand-500"
>
  Accessible focus ring button
</button>
```

| Category | Examples |
|---|---|
| Border width | `border`, `border-2`, `border-t`, `border-x` |
| Border color | `border-slate-200`, `border-brand-500/50` |
| Radius | `rounded`, `rounded-lg`, `rounded-full`, `rounded-t-xl` (per-corner) |
| Ring (focus outlines, non-layout-shifting) | `ring-2`, `ring-offset-2`, `ring-brand-500` |
| Shadow | `shadow-sm`, `shadow-lg`, `shadow-soft` (custom, Part 3) |

## 4.8 Backgrounds & Gradients

```tsx
<div className="bg-gradient-to-br from-brand-500 via-brand-600 to-brand-900 p-10 text-white">
  Diagonal gradient using theme color stops
</div>

<div
  className="bg-cover bg-center bg-no-repeat"
  style={{ backgroundImage: "url(/hero.jpg)" }}
>
  Background image utilities combined with inline style for the URL itself
  (arbitrary values also work: bg-[url(/hero.jpg)])
</div>
```

## 4.9 Flexbox/Grid Alignment Cheat Sheet

| Goal | Classes |
|---|---|
| Center everything (both axes) | `flex items-center justify-center` |
| Space items evenly with equal gaps | `flex justify-between` or `gap-*` + `flex` |
| Vertically stack, full width children | `flex flex-col` |
| Wrap items onto multiple lines | `flex flex-wrap gap-4` |
| Responsive 12-column grid | `grid grid-cols-12 gap-4` then `col-span-6` per item |
| Grid auto-fit cards | `grid grid-cols-[repeat(auto-fit,minmax(200px,1fr))]` (arbitrary value, Part 9) |

## 4.10 A Complete Composed Example: Product Card

```tsx
// src/components/ProductCard.tsx
type Product = {
  name: string;
  price: number;
  imageUrl: string;
  inStock: boolean;
};

export function ProductCard({ product }: { product: Product }) {
  return (
    <div className="group flex flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-soft transition-shadow hover:shadow-lg">
      <div className="aspect-square w-full overflow-hidden bg-slate-100">
        {/* group-hover here previews Part 6's state-variant coverage */}
        <img
          src={product.imageUrl}
          alt={product.name}
          className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
        />
      </div>
      <div className="flex flex-1 flex-col gap-2 p-4">
        <h3 className="font-display text-lg font-semibold text-slate-900">
          {product.name}
        </h3>
        <p className="text-2xl font-bold text-brand-600">
          ${product.price.toFixed(2)}
        </p>
        <span
          className={
            product.inStock
              ? "w-fit rounded-full bg-success/10 px-2 py-1 text-xs font-medium text-success"
              : "w-fit rounded-full bg-danger/10 px-2 py-1 text-xs font-medium text-danger"
          }
        >
          {product.inStock ? "In Stock" : "Out of Stock"}
        </span>
      </div>
    </div>
  );
}
```

## 4.11 Exercise Challenge

Build a `<StatBadge>` component that accepts `label`, `value`, and `trend: "up" | "down"` props, rendering a pill with a colored trend arrow (green up, red down) using only utilities covered so far.

## 4.12 Solution

```tsx
// src/components/StatBadge.tsx
import { ArrowUp, ArrowDown } from "lucide-react";

type StatBadgeProps = {
  label: string;
  value: string;
  trend: "up" | "down";
};

export function StatBadge({ label, value, trend }: StatBadgeProps) {
  const isUp = trend === "up";
  return (
    <div className="flex items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 py-3 shadow-soft">
      <div className="flex flex-col">
        <span className="text-xs font-medium uppercase tracking-wide text-slate-400">
          {label}
        </span>
        <span className="text-xl font-bold text-slate-900">{value}</span>
      </div>
      <span
        className={
          isUp
            ? "ml-auto flex items-center gap-1 rounded-full bg-success/10 px-2 py-1 text-xs font-semibold text-success"
            : "ml-auto flex items-center gap-1 rounded-full bg-danger/10 px-2 py-1 text-xs font-semibold text-danger"
        }
      >
        {isUp ? <ArrowUp className="size-3" /> : <ArrowDown className="size-3" />}
        {isUp ? "Up" : "Down"}
      </span>
    </div>
  );
}
```

---

*Next: Tailwind v4 Mastery - Part 5: Responsive Design, Container Queries & Dark Mode*
