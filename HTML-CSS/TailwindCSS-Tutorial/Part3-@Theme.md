# Part 3: The `@theme` Directive & Design Tokens

## 3.1 Concept Explanation

`@theme` is the **direct CSS-native replacement** for `theme.extend` in the old `tailwind.config.js`. Every variable you declare inside `@theme`:

1. Is compiled into a real `:root` CSS custom property (accessible anywhere, even outside Tailwind classes).
2. Automatically generates matching utility classes based on its **namespace prefix**.

```css
@import "tailwindcss";

@theme {
  --color-brand-500: oklch(0.58 0.22 265);
  --font-display: "Geist Sans", sans-serif;
  --spacing-18: 4.5rem;
  --breakpoint-3xl: 1920px;
  --radius-xl: 1rem;
}
```

Compiles (conceptually) to:
```css
:root {
  --color-brand-500: oklch(0.58 0.22 265);
  --font-display: "Geist Sans", sans-serif;
  --spacing-18: 4.5rem;
  --breakpoint-3xl: 1920px;
  --radius-xl: 1rem;
}
```
...**plus** it unlocks `bg-brand-500`, `text-brand-500`, `font-display`, `p-18`/`m-18`/`gap-18`, `3xl:` variant, `rounded-xl` overrides, etc.

## 3.2 The Namespace Table (Memorize This)

| `@theme` prefix | Generates utilities for | Example |
|---|---|---|
| `--color-*` | `bg-`, `text-`, `border-`, `ring-`, `fill-`, `stroke-`, `divide-`, `accent-`, `caret-`, `outline-`, `decoration-`, gradient `from-/via-/to-` | `--color-brand-500` → `bg-brand-500` |
| `--font-*` | `font-` (font-family) | `--font-display` → `font-display` |
| `--text-*` | `text-` (font-size, paired with a line-height) | `--text-huge: 4rem` → `text-huge` |
| `--font-weight-*` | `font-` (weight) | `--font-weight-black: 900` → `font-black` |
| `--spacing-*` | `p-`, `m-`, `gap-`, `w-`, `h-`, `top-`, `inset-`, etc. (the universal spacing scale) | `--spacing-18: 4.5rem` → `p-18`, `w-18` |
| `--breakpoint-*` | Responsive variants (`sm:`, `md:`, custom) | `--breakpoint-3xl: 1920px` → `3xl:` |
| `--container-*` | Container query variants (`@sm:`, custom) | `--container-8xl: 96rem` → `@8xl:` |
| `--radius-*` | `rounded-` | `--radius-xl: 1rem` → `rounded-xl` |
| `--shadow-*` | `shadow-` | `--shadow-soft: 0 4px 24px ...` → `shadow-soft` |
| `--ease-*` | `ease-` (transition-timing-function) | `--ease-snappy: cubic-bezier(...)` → `ease-snappy` |
| `--animate-*` | `animate-` | `--animate-fade-in: fade-in 0.3s ease` → `animate-fade-in` |
| `--z-*` | `z-` | `--z-modal: 100` → `z-modal` |
| `--tracking-*` | `tracking-` (letter-spacing) | `--tracking-tightest: -0.08em` → `tracking-tightest` |
| `--leading-*` | `leading-` (line-height) | `--leading-loose: 2.25` → `leading-loose` |

## 3.3 Full Working Design Token Setup (Used Throughout the Rest of This Series)

```css
/* src/app/globals.css (Next.js) OR src/index.css (React 19 + Vite) — identical either way */
@import "tailwindcss";

@theme {
  /* ---- Brand color ramp (OKLCH = perceptually uniform, better than hex for ramps) ---- */
  --color-brand-50:  oklch(0.97 0.02 265);
  --color-brand-100: oklch(0.93 0.05 265);
  --color-brand-300: oklch(0.80 0.12 265);
  --color-brand-500: oklch(0.58 0.22 265);
  --color-brand-600: oklch(0.50 0.22 265);
  --color-brand-700: oklch(0.42 0.20 265);
  --color-brand-900: oklch(0.28 0.14 265);

  /* ---- Semantic / status colors ---- */
  --color-success: oklch(0.6 0.16 150);
  --color-warning: oklch(0.75 0.18 80);
  --color-danger:  oklch(0.55 0.22 25);

  /* ---- Typography ---- */
  --font-display: "Geist", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "Geist Mono", ui-monospace, monospace;

  /* ---- Custom spacing step (extends the default 0-96 scale, doesn't replace it) ---- */
  --spacing-18: 4.5rem;
  --spacing-112: 28rem;

  /* ---- Custom breakpoint ---- */
  --breakpoint-3xl: 1920px;

  /* ---- Radii ---- */
  --radius-xl: 1rem;
  --radius-2xl: 1.5rem;

  /* ---- Shadows ---- */
  --shadow-soft: 0 2px 10px rgb(0 0 0 / 0.06), 0 8px 24px rgb(0 0 0 / 0.08);

  /* ---- Easing curves ---- */
  --ease-snappy: cubic-bezier(0.2, 0, 0, 1);
}
```

Usage anywhere in your React 19 / Next.js 16 components — no import, no config, just class names:

```tsx
// src/components/BrandCard.tsx
export function BrandCard() {
  return (
    <div className="rounded-2xl bg-brand-50 p-18 shadow-soft">
      <h2 className="font-display text-2xl font-black text-brand-900">
        Design tokens, zero JS config
      </h2>
      <p className="mt-2 font-mono text-sm text-brand-700">
        --color-brand-500 → bg-brand-500 / text-brand-500 / border-brand-500 ...
      </p>
    </div>
  );
}
```

## 3.4 `@theme` vs `@theme inline` — Critical Distinction for Next.js/CSS Variables Interop

By default, `@theme` values are treated as **static, compile-time constants** — great for design tokens. But if you need a theme value to **reference another runtime CSS variable** (e.g. one injected by `next/font` or set dynamically via `style={{ "--x": ... }}`), use `@theme inline`:

```css
/* next/font injects a CSS variable like --font-geist-sans onto <html> or <body> at runtime */
@theme inline {
  /* inline tells Tailwind: don't bake this in at build time, resolve it live via var() */
  --font-sans: var(--font-geist-sans);
}
```

```tsx
// src/app/layout.tsx
import { Geist } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans", // this is the runtime CSS variable @theme inline references
  subsets: ["latin"],
});

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={geistSans.variable}>
      <body className="font-sans">{children}</body>
    </html>
  );
}
```

> **Rule of thumb:** use plain `@theme` for static design tokens (colors, spacing, radii). Use `@theme inline` specifically when wiring up `next/font` variables or any other CSS custom property whose actual value is set at runtime by something outside Tailwind's build step.

## 3.5 Overriding vs Extending the Default Theme

```css
@import "tailwindcss";

@theme {
  /* Adds a NEW color alongside all default Tailwind colors (slate, red, blue, etc. still exist) */
  --color-brand-500: oklch(0.58 0.22 265);
}
```

```css
@import "tailwindcss";

/* Wipes ALL default theme values in the color namespace, then you must redefine everything you want */
@theme {
  --color-*: initial; /* nukes every built-in color: slate, red, blue, green, all of them */

  --color-white: #fff;
  --color-black: #000;
  --color-brand-500: oklch(0.58 0.22 265);
}
```

Use `--<namespace>-*: initial;` only when you deliberately want a fully custom, constrained design system (e.g. a strict client brand system where designers should not be able to reach for `bg-blue-500`).

## 3.6 Referencing Theme Variables in Custom CSS

Because every `@theme` value is a real CSS variable, you can use them in plain CSS (e.g. for a third-party component library you don't control via `className`):

```css
.legacy-widget-header {
  background-color: var(--color-brand-600);
  font-family: var(--font-display);
  border-radius: var(--radius-xl);
}
```

This interop is impossible in v3 without the `theme()` function inside `@layer` blocks — v4 removes that indirection entirely.

## 3.7 Exercise Challenge

Add a `--color-brand-*` ramp restricted to only `100/500/900`, plus a custom `--shadow-glow` token, then build a `<GlowButton>` React component using `shadow-glow` and `bg-brand-500` with a `hover:bg-brand-900` state.

## 3.8 Solution

```css
@theme {
  --color-brand-100: oklch(0.93 0.05 265);
  --color-brand-500: oklch(0.58 0.22 265);
  --color-brand-900: oklch(0.28 0.14 265);
  --shadow-glow: 0 0 24px oklch(0.58 0.22 265 / 0.5);
}
```

```tsx
// src/components/GlowButton.tsx
export function GlowButton({ children }: { children: React.ReactNode }) {
  return (
    <button
      className="rounded-full bg-brand-500 px-6 py-3 font-semibold text-brand-100
                 shadow-glow transition-colors duration-200 hover:bg-brand-900"
    >
      {children}
    </button>
  );
}
```

---

*Next: Tailwind v4 Mastery - Part 4: Core Utility Classes Crash Course*
