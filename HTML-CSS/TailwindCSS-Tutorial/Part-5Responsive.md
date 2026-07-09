# Part 5: Responsive Design, Container Queries & Dark Mode

## 5.1 Concept Explanation: Mobile-First Breakpoints

Tailwind applies styles **mobile-first**: an unprefixed utility (`p-4`) applies at all sizes; a prefixed one (`md:p-8`) applies from that breakpoint **up**.

| Prefix | Min-width | Typical device |
|---|---|---|
| (none) | 0px | Mobile (base) |
| `sm:` | 40rem (640px) | Large phone / small tablet |
| `md:` | 48rem (768px) | Tablet |
| `lg:` | 64rem (1024px) | Laptop |
| `xl:` | 80rem (1280px) | Desktop |
| `2xl:` | 96rem (1536px) | Large desktop |
| `3xl:` | Custom (Part 3, `--breakpoint-3xl`) | Ultra-wide, if you defined one |

```tsx
<div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
  {/* 1 col on mobile, 2 on sm+, 3 on lg+, 4 on xl+ */}
</div>
```

Max-width variants exist too (`max-sm:`, `max-lg:`) for "apply below this breakpoint" logic, and ranged variants can be combined: `md:max-lg:` applies only between md and lg.

```tsx
<div className="hidden md:max-lg:block">
  Only visible between md and lg (a "tablet-only" banner, for example)
</div>
```

## 5.2 Customizing Breakpoints via `@theme`

```css
@theme {
  --breakpoint-3xl: 1920px; /* adds a new 3xl: variant on top of defaults */

  /* Or fully replace the default scale: */
  --breakpoint-*: initial;
  --breakpoint-sm: 30rem;
  --breakpoint-md: 48rem;
  --breakpoint-lg: 64rem;
}
```

## 5.3 Container Queries (Built-in in v4 — No Plugin Needed)

This is one of v4's headline features. Instead of media queries reacting to the **viewport**, container queries react to the size of a **parent container** — critical for reusable components that get dropped into sidebars, modals, or full-width sections interchangeably.

```tsx
// src/components/CardGrid.tsx
export function CardGrid() {
  return (
    // @container marks this element as a query container for its descendants
    <div className="@container">
      <div className="grid grid-cols-1 gap-4 @sm:grid-cols-2 @lg:grid-cols-3">
        {/* @sm/@lg here react to the WIDTH OF THE PARENT DIV, not the viewport */}
        <div className="rounded-lg bg-brand-100 p-4">A</div>
        <div className="rounded-lg bg-brand-100 p-4">B</div>
        <div className="rounded-lg bg-brand-100 p-4">C</div>
      </div>
    </div>
  );
}
```

```tsx
// Named containers let nested @container elements target a SPECIFIC ancestor,
// not just the nearest one — essential in deeply nested dashboard layouts.
<div className="@container/sidebar">
  <div className="@container/main">
    <div className="text-sm @lg/sidebar:text-base">
      {/* reacts to the width of the @container/sidebar ancestor specifically */}
    </div>
  </div>
</div>
```

```css
/* Custom container breakpoints via @theme, same pattern as --breakpoint-* */
@theme {
  --container-8xl: 96rem;
}
```
```tsx
<div className="@container">
  <div className="@8xl:grid-cols-6 grid grid-cols-2">...</div>
</div>
```

> **Why this matters for component libraries:** a `<Sidebar>` and a `<MainContent>` can render the exact same `<StatsPanel>` component, and it will lay itself out correctly based on the space it's actually given, not the browser window — impossible cleanly with media queries alone.

## 5.4 Dark Mode Strategy

Tailwind v4's `dark:` variant defaults to the OS-level `prefers-color-scheme: dark` media query. For most apps (especially with a manual toggle button), you'll want **class-based** dark mode instead.

### 5.4.1 Default (media-query based) — zero config

```tsx
<div className="bg-white text-slate-900 dark:bg-slate-900 dark:text-white">
  Automatically flips based on OS setting. No config needed.
</div>
```

### 5.4.2 Class-Based Dark Mode (Recommended — supports a manual toggle)

In v4, custom variants are defined in CSS with `@custom-variant`:

```css
/* src/app/globals.css */
@import "tailwindcss";

/* Redefine `dark:` to trigger off a .dark class on <html> instead of OS preference.
   The & refers to the element the utility is applied to. */
@custom-variant dark (&:where(.dark, .dark *));
```

```tsx
// src/components/ThemeToggle.tsx ("use client" — needs interactivity/state)
"use client";

import { useState, useEffect } from "react";
import { Moon, Sun } from "lucide-react";

export function ThemeToggle() {
  const [isDark, setIsDark] = useState(false);

  // Sync the .dark class on <html> whenever isDark changes
  useEffect(() => {
    document.documentElement.classList.toggle("dark", isDark);
  }, [isDark]);

  return (
    <button
      onClick={() => setIsDark((prev) => !prev)}
      aria-label="Toggle dark mode"
      className="rounded-full border border-slate-200 p-2 text-slate-700
                 dark:border-slate-700 dark:text-slate-200"
    >
      {isDark ? <Sun className="size-5" /> : <Moon className="size-5" />}
    </button>
  );
}
```

```tsx
// src/components/ThemedCard.tsx — any component now respects the manual toggle
export function ThemedCard() {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-6 text-slate-900 shadow-soft
                    dark:border-slate-800 dark:bg-slate-900 dark:text-slate-100">
      <h3 className="font-semibold">Dark mode via class strategy</h3>
      <p className="text-sm text-slate-500 dark:text-slate-400">
        Toggled manually, persists independent of OS setting.
      </p>
    </div>
  );
}
```

### 5.4.3 Persisting the Choice + Avoiding Flash-of-Wrong-Theme (Next.js 16)

```tsx
// src/app/layout.tsx
// An inline, blocking script run BEFORE hydration prevents a "flash of light theme"
// on reload when the user previously chose dark mode. This must NOT be deferred.
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                const stored = localStorage.getItem("theme");
                const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
                const isDark = stored === "dark" || (!stored && prefersDark);
                document.documentElement.classList.toggle("dark", isDark);
              })();
            `,
          }}
        />
      </head>
      <body className="bg-white dark:bg-slate-950">{children}</body>
    </html>
  );
}
```

```tsx
// Updated ThemeToggle.tsx that persists to localStorage
"use client";
import { useState, useEffect } from "react";

export function ThemeToggle() {
  const [isDark, setIsDark] = useState(
    () => typeof document !== "undefined" && document.documentElement.classList.contains("dark"),
  );

  useEffect(() => {
    document.documentElement.classList.toggle("dark", isDark);
    localStorage.setItem("theme", isDark ? "dark" : "light");
  }, [isDark]);

  return (
    <button onClick={() => setIsDark((d) => !d)} className="rounded-full border p-2">
      {isDark ? "☀️" : "🌙"}
    </button>
  );
}
```

## 5.5 Combining Responsive + Dark + Container Variants (Stacking Rules)

Variants stack left-to-right and all must match:

```tsx
<div className="text-sm @md:text-base md:dark:bg-slate-800 lg:dark:hover:bg-slate-700">
  {/* lg:dark:hover:bg-slate-700 -> only applies at lg+ AND dark mode AND on hover */}
</div>
```

## 5.6 Exercise Challenge

Build a `<ResponsiveStatsGrid>` that: uses container queries (not viewport breakpoints) to go 1→2→4 columns, and supports dark mode via the class strategy.

## 5.7 Solution

```tsx
// src/components/ResponsiveStatsGrid.tsx
type Stat = { label: string; value: string };

export function ResponsiveStatsGrid({ stats }: { stats: Stat[] }) {
  return (
    <div className="@container rounded-2xl border border-slate-200 bg-white p-4
                    dark:border-slate-800 dark:bg-slate-900">
      <div className="grid grid-cols-1 gap-4 @md:grid-cols-2 @2xl:grid-cols-4">
        {stats.map((stat) => (
          <div
            key={stat.label}
            className="rounded-lg bg-slate-50 p-4 text-center dark:bg-slate-800"
          >
            <p className="text-xs uppercase text-slate-400 dark:text-slate-500">
              {stat.label}
            </p>
            <p className="text-xl font-bold text-slate-900 dark:text-white">
              {stat.value}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}
```

Because it's driven by `@container`, this exact component correctly reflows to 4 columns when placed in a wide dashboard area, and stays 1-2 columns when placed in a narrow sidebar — no separate mobile/desktop variant needed.

---

*Next: Tailwind v4 Mastery - Part 6: State Variants & Selectors*
