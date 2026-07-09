# Part 8: Animations & Transitions

## 8.1 Transitions — The Basics

```tsx
<button
  className="rounded-lg bg-brand-500 px-4 py-2 text-white
             transition-colors duration-200 ease-in-out
             hover:bg-brand-600"
>
  Smooth color transition on hover
</button>
```

| Utility | Purpose |
|---|---|
| `transition` | Shorthand: transitions `color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter` |
| `transition-colors` | Only color-related properties (cheaper, avoid layout jank) |
| `transition-transform` | Only `transform` (scale/rotate/translate) |
| `transition-opacity` | Only `opacity` |
| `transition-all` | Everything — use sparingly, can cause unexpected animating properties |
| `duration-150` … `duration-1000` | Transition duration in ms |
| `ease-linear` / `ease-in` / `ease-out` / `ease-in-out` | Timing functions |
| `ease-snappy` (custom, Part 3) | Your own `@theme`-defined curve |
| `delay-150` | Transition delay |

## 8.2 Transform Utilities (Paired with Transitions Constantly)

```tsx
<div className="group relative overflow-hidden rounded-2xl">
  <img
    src="/product.jpg"
    className="scale-100 transition-transform duration-500 ease-out group-hover:scale-110"
    alt="Product"
  />
  <div
    className="absolute inset-0 flex items-end bg-gradient-to-t from-black/60 to-transparent
               p-4 opacity-0 transition-opacity duration-300 group-hover:opacity-100"
  >
    <span className="translate-y-2 text-white transition-transform duration-300 group-hover:translate-y-0">
      View Details
    </span>
  </div>
</div>
```

`scale-*`, `rotate-*`, `translate-x-*`/`translate-y-*`, `skew-*` all compose via the single `transform` property (v4 handles this automatically, no need to add a bare `transform` class like old v2).

## 8.3 Built-in `animate-*` Utilities

```tsx
<div className="animate-spin rounded-full border-4 border-slate-200 border-t-brand-500 h-8 w-8" />
{/* Classic spinner using animate-spin + a partial border trick */}

<div className="animate-pulse rounded-lg bg-slate-200 h-4 w-3/4" />
{/* Skeleton loading placeholder */}

<span className="relative flex h-3 w-3">
  <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-brand-400 opacity-75" />
  <span className="relative inline-flex h-3 w-3 rounded-full bg-brand-500" />
</span>
{/* "Live" notification dot using animate-ping layered under a static dot */}

<div className="animate-bounce">↓</div>
{/* Scroll-down indicator */}
```

## 8.4 Custom Keyframe Animations via `@theme`

```css
/* src/app/globals.css */
@import "tailwindcss";

@theme {
  --animate-fade-in: fade-in 0.4s ease-out;
  --animate-slide-up: slide-up 0.3s cubic-bezier(0.2, 0, 0, 1);
  --animate-shimmer: shimmer 2s linear infinite;
}

/* Keyframes are declared as plain CSS OUTSIDE the @theme block (v4 does not
   put @keyframes inside @theme — only the --animate-* variable pointing to it) */
@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slide-up {
  from { opacity: 0; transform: translateY(1rem); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes shimmer {
  from { background-position: -200% 0; }
  to { background-position: 200% 0; }
}
```

```tsx
// Usage — indistinguishable from built-in animate-* utilities
<div className="animate-fade-in rounded-xl bg-white p-6 shadow-soft">
  Fades in on mount
</div>

<div className="animate-slide-up">Slides up + fades in, using a custom easing curve</div>

<div className="animate-shimmer bg-gradient-to-r from-slate-200 via-white to-slate-200 bg-[length:200%_100%]">
  Shimmering skeleton loader
</div>
```

## 8.5 The `starting:` Variant — Native CSS Entry Transitions (New in v4)

Before v4, animating an element's **entrance** (e.g. a modal appearing) required a mount-delay trick in JS (render with initial styles, then flip a class on the next tick). v4 exposes the native CSS `@starting-style` feature directly as a variant:

```tsx
// src/components/Modal.tsx
"use client";

export function Modal({ open, children }: { open: boolean; children: React.ReactNode }) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop: fades in from opacity 0 using starting: + a plain transition, NO JS state delay needed */}
      <div
        className="fixed inset-0 bg-black/50 opacity-100 transition-opacity duration-300
                   starting:opacity-0"
      />
      <div
        className="relative z-10 w-full max-w-md scale-100 rounded-2xl bg-white p-6 opacity-100
                   shadow-soft transition-all duration-300
                   starting:scale-95 starting:opacity-0"
      >
        {children}
      </div>
    </div>
  );
}
```

> **Why this matters:** `starting:` requires the element to use `display` that isn't `none` at the moment it's inserted (e.g. conditional rendering via `{open && <Modal />}` in React works correctly here since React inserts the whole subtree at once) — the browser then animates from the `starting:` styles to the resting styles automatically on the very first paint, with zero `useEffect`/`requestAnimationFrame` timing hacks. Requires Chrome 117+/Safari 17.5+/Firefox 129+.

## 8.6 Exit Animations (Still Requires a Tiny Bit of JS — No Native CSS Exit Yet)

CSS alone cannot animate an element OUT before React unmounts it (React removes the DOM node immediately). Use a short delay-based unmount pattern:

```tsx
// src/components/Toast.tsx
"use client";

import { useState, useEffect } from "react";
import { cn } from "@/lib/cn";

export function Toast({ message, onDone }: { message: string; onDone: () => void }) {
  const [leaving, setLeaving] = useState(false);

  useEffect(() => {
    const showTimer = setTimeout(() => setLeaving(true), 3000);
    return () => clearTimeout(showTimer);
  }, []);

  useEffect(() => {
    if (!leaving) return;
    // Wait for the exit transition duration to finish before actually unmounting
    const unmountTimer = setTimeout(onDone, 300);
    return () => clearTimeout(unmountTimer);
  }, [leaving, onDone]);

  return (
    <div
      className={cn(
        "rounded-lg bg-slate-900 px-4 py-3 text-sm text-white shadow-soft transition-all duration-300",
        leaving ? "translate-y-2 opacity-0" : "translate-y-0 opacity-100 starting:translate-y-2 starting:opacity-0",
      )}
    >
      {message}
    </div>
  );
}
```

## 8.7 Respecting `prefers-reduced-motion`

```tsx
<div
  className="transition-transform duration-500 hover:scale-105
             motion-reduce:transition-none motion-reduce:hover:scale-100"
>
  Respects user's OS-level reduced-motion accessibility setting
</div>
```

`motion-safe:` is the inverse — apply an animation ONLY if the user has not requested reduced motion:
```tsx
<div className="motion-safe:animate-fade-in">Only animates if motion is not reduced</div>
```

## 8.8 Exercise Challenge

Build an `<AccordionPanel>` whose content height animates open/closed smoothly using the `grid-rows` trick from Part 6, plus a chevron that rotates, and respects `prefers-reduced-motion`.

## 8.9 Solution

```tsx
// src/components/AccordionPanel.tsx
"use client";

import { useState } from "react";
import { ChevronDown } from "lucide-react";
import { cn } from "@/lib/cn";

export function AccordionPanel({ title, children }: { title: string; children: React.ReactNode }) {
  const [open, setOpen] = useState(false);

  return (
    <div className="rounded-xl border border-slate-200">
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center justify-between p-4 text-left font-medium"
      >
        {title}
        <ChevronDown
          className={cn(
            "size-5 text-slate-400 transition-transform duration-300 motion-reduce:transition-none",
            open && "rotate-180",
          )}
        />
      </button>
      <div
        className={cn(
          "grid transition-[grid-template-rows] duration-300 ease-snappy motion-reduce:transition-none",
          open ? "grid-rows-[1fr]" : "grid-rows-[0fr]",
        )}
      >
        <div className="overflow-hidden">
          <div className="px-4 pb-4 text-sm text-slate-600">{children}</div>
        </div>
      </div>
    </div>
  );
}
```

---

*Next: Tailwind v4 Mastery - Part 9: Advanced Customization*
