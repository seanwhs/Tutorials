# Part 3: The Styling System

## 1. Browser Reality — The Cascade & Specificity

When multiple CSS rules target the same element, the browser must decide which one wins. This resolution process is the **Cascade**, and it's governed by **specificity** — a scoring system.

```css
/* specificity: 0-0-1 (1 element selector) */
p { color: black; }

/* specificity: 0-1-0 (1 class selector) — wins over the element selector above */
.warning { color: red; }

/* specificity: 1-0-0 (1 ID selector) — wins over everything above */
#alert { color: orange; }

/* inline style: always wins over the above (short of !important) */
```

```html
<p id="alert" class="warning">What color am I?</p>
```

**Result:** the text is **orange** — ID beats class beats element, regardless of source order. If two rules have equal specificity, the one declared *later* in the stylesheet (or later in the cascade order) wins.

**The "Specificity War":** in large legacy codebases, this creates a real problem. A component's local class (`.warning { color: red; }`) can get silently overridden weeks later by someone else's more specific selector (`#sidebar .warning { color: blue; }`) added far away in a different file. Teams respond by escalating: adding more IDs, more nested selectors, eventually `!important`. This arms race is the specificity war — styles become unpredictable because *any* rule anywhere in the codebase can outrank yours.

## 2. The Tailwind Translation — Atomic, Single-Purpose Classes

Tailwind sidesteps specificity wars structurally, not by being "smarter" about the cascade — every Tailwind utility is a **single class selector** (specificity `0-1-0`), full stop. There are no nested selectors, no IDs, no `.parent .child` chains in Tailwind's generated CSS.

```css
/* Tailwind's generated output — every rule is exactly one class, same specificity */
.text-red-600 { color: #dc2626; }
.text-black   { color: #000000; }
.p-4          { padding: 1rem; }
.font-bold    { font-weight: 700; }
```

```html
<p class="text-black text-red-600">Which color wins?</p>
```

Since both classes have **identical specificity** (`0-1-0`), the winner is decided purely by **source order in the compiled stylesheet** — whichever utility's CSS rule appears later in Tailwind's generated `.css` file wins, not the order you typed the classes in the `class` attribute. In practice this is why Tailwind ships a deterministic build step: it controls the output order so results are consistent, but it also means **you should never rely on two conflicting utilities on the same element** — pick one.

**The real guarantee Tailwind gives you:** because every utility is exactly one class with no nesting, no rule from anywhere else in your codebase can silently outrank a Tailwind class via extra specificity — the worst any conflicting *other* Tailwind class can do is tie. Combined with `@layer` ordering in Tailwind's build, this makes visual output predictable regardless of file import order, which is the actual problem legacy global CSS could never solve.

## 3. Browser Reality — Conflicting Classes Without a Merge Tool

Say you're building a reusable `Button` and want to let a consumer override the background color:

```html
<!-- Button.tsx renders this by default -->
<button class="bg-blue-500 px-4 py-2 text-white">Save</button>

<!-- consumer wants red instead, so they append a class -->
<button class="bg-blue-500 px-4 py-2 text-white bg-red-500">Delete</button>
```

Both `bg-blue-500` and `bg-red-500` set the same CSS property (`background-color`) with equal specificity. The winner depends on which rule appears **later in the generated stylesheet** — often `bg-blue-500`, because Tailwind's internal ordering isn't alphabetical by your usage, it's fixed at build time. Naively string-concatenating classes like this is fragile and easy to get wrong.

## 4. The Tailwind Translation — `tailwind-merge`

`tailwind-merge` (commonly paired with `clsx`) solves this at the **string level, before the browser ever sees CSS** — it doesn't touch the cascade at all. It parses your class list, groups classes by the CSS property they control, and keeps only the last one per group.

```tsx
// utils/cn.ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

```tsx
// app/components/Button.tsx
import { cn } from "@/utils/cn";

export default function Button({
  className,
  children,
}: {
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <button
      className={cn("bg-blue-500 px-4 py-2 text-white rounded", className)}
    >
      {children}
    </button>
  );
}
```

```tsx
// consumer
<Button className="bg-red-500">Delete</Button>
```

**What `twMerge` does internally, conceptually:**

```ts
// simplified mental model of the algorithm
const classGroups = {
  "bg-blue-500": "background-color",
  "bg-red-500": "background-color",
  "px-4": "padding-x",
  "py-2": "padding-y",
};

// twMerge scans left-to-right, buckets each class by the property it maps to,
// and for each bucket, discards all but the *last* class seen.
// Input:  ["bg-blue-500", "px-4", "py-2", "text-white", "rounded", "bg-red-500"]
// Bucket "background-color": [bg-blue-500, bg-red-500] → keeps bg-red-500, drops bg-blue-500
// Output: "px-4 py-2 text-white rounded bg-red-500"
```

This is a **string-level property override calculation**, done in JavaScript at render time, completely independent of CSS specificity rules. It guarantees "last one wins, per property" regardless of Tailwind's internal stylesheet ordering — which is the predictability legacy CSS never had, because in raw CSS the *cascade*, not the *source string order*, decides.

| Mechanism | Where it happens | What decides the winner |
|---|---|---|
| CSS Cascade/Specificity | Browser, at paint time | Selector specificity, then source order in the compiled stylesheet |
| `tailwind-merge` | JavaScript, before render | Last class *per CSS property* in the array you pass in |

## 5. Global CSS Still Has a Place

Tailwind doesn't eliminate the cascade — it operates inside it. Global resets, CSS variables for design tokens, and `@layer base` styles still live in `globals.css`:

```css
/* app/globals.css — Tailwind v4, CSS-first config */
@import "tailwindcss";

@layer base {
  h1 { font-size: 1.875rem; font-weight: 700; }
  a { color: theme(--color-blue-600); }
}
```

`@layer` is native CSS (not Tailwind-specific) that lets you explicitly declare cascade priority between groups of rules, regardless of source order — Tailwind's build tool uses this to guarantee utilities always beat base styles, and your explicit utility classes always beat both.

## Exercise Challenge

1. Write a raw CSS example demonstrating a specificity conflict between an ID selector and two chained classes, and state which wins and why (score it out of 3 parts: id-class-element).
2. Build a `Badge.tsx` component using `cn()` that has a sensible default `bg-gray-100 text-gray-800` and accepts a `className` prop that can override the color, proving the override actually takes effect (not just gets appended and lost to specificity).

## Solution

**Part 1:**

```css
#header .btn.primary { color: green; }  /* specificity: 1-2-0 */
.btn.primary { color: purple; }          /* specificity: 0-2-0 */
```
`#header .btn.primary` wins (1 ID > 2 classes) — text renders green — regardless of which rule appears later in the file, because ID selectors always outrank any number of class selectors.

**Part 2:**

```tsx
// app/components/Badge.tsx
import { cn } from "@/utils/cn";

export default function Badge({
  className,
  children,
}: {
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <span
      className={cn(
        "inline-block rounded-full px-3 py-1 text-sm bg-gray-100 text-gray-800",
        className,
      )}
    >
      {children}
    </span>
  );
}

// usage — proves override works
<Badge>Default</Badge>                              {/* gray */}
<Badge className="bg-green-100 text-green-800">Active</Badge>  {/* green wins, gray dropped */}
```

**Why this passes:** `twMerge` recognizes `bg-gray-100` and `bg-green-100` both map to `background-color`, and `text-gray-800`/`text-green-800` both map to `color` — it keeps only the last of each pair. The consumer's override reliably wins every time, with zero dependency on Tailwind's internal build-order quirks.

**Next:** Part 4 covers why we extract components at all, and builds a full accessible UI component from first principles.
