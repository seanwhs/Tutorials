# Part 1: Tailwind v4 Architecture & the Oxide Engine

## 1.1 Concept Explanation

Tailwind CSS v4 is built on a new engine internally called **Oxide**, written partly in **Rust** using **Lightning CSS** for parsing/transforming/minifying CSS. This is why v4 is dramatically faster than v3's pure-JS engine.

Key architectural shifts you need to understand before writing any code:

1. **CSS-first configuration.** Instead of exporting a JS object from `tailwind.config.js`, you configure Tailwind by writing CSS — specifically inside an `@theme` block. Tailwind reads your *actual CSS file* as the source of truth.
2. **Automatic content detection.** v3 required you to list every file glob Tailwind should scan for class names (`content: ["./src/**/*.{ts,tsx}"]`). v4 **automatically** detects your project files, respecting `.gitignore` and ignoring binary/large files — you rarely need to configure this manually.
3. **Native cascade layers.** v4 emits real CSS `@layer` rules (`@layer theme, base, components, utilities;`) so ordering/specificity is handled by the browser's native cascade instead of Tailwind's own specificity hacks.
4. **One import, not three.** `@tailwind base/components/utilities` is gone. It's just:
   ```css
   @import "tailwindcss";
   ```
5. **Everything is a CSS variable.** Design tokens defined in `@theme` are compiled to real `:root` CSS custom properties (e.g. `--color-brand-500`), which means you can reference them directly in plain CSS or inline styles — not just via utility classes.

## 1.2 How the Build Pipeline Works

```text
Your CSS file (@import "tailwindcss" + @theme block)
        │
        ▼
@tailwindcss/postcss  (Next.js)   OR   @tailwindcss/vite (Vite/React 19)
        │
        ▼
Oxide engine scans your project source files for class-name-shaped strings
        │
        ▼
Matches candidates against core utilities + your @theme tokens
        │
        ▼
Generates only the CSS that's actually used (still "just-in-time", but now
also incrementally cached — rebuilds only look at changed files)
        │
        ▼
Lightning CSS handles nesting, vendor prefixing, minification
        │
        ▼
Final CSS output, organized into native cascade layers
```

```css
/* This is literally what Tailwind generates at the top of your CSS output */
@layer theme, base, components, utilities;
```

> **Why this matters:** because Tailwind now uses **real** `@layer` rules, utility classes always win over component classes regardless of source order or specificity wars — the browser's cascade layer mechanism guarantees it. You no longer need `!important` hacks to make a utility override a component class written later in the file.

## 1.3 No More `tailwind.config.js` — What Replaces It

```js
/* ------------------------------------------------------------------ */
/* v3 (OLD — do not use in this series)                                */
/* tailwind.config.js                                                  */
/* ------------------------------------------------------------------ */
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: { brand: "#6D28D9" },
      fontFamily: { display: ["Geist", "sans-serif"] },
    },
  },
  plugins: [],
};
```

```css
/* ------------------------------------------------------------------ */
/* v4 (NEW — used throughout this series)                              */
/* src/app/globals.css (Next.js) or src/index.css (React 19 + Vite)    */
/* ------------------------------------------------------------------ */
@import "tailwindcss";

/* @theme is the direct replacement for theme.extend in JS config.
   Every variable becomes both a real CSS custom property AND
   generates matching utility classes (e.g. --color-brand -> bg-brand, text-brand). */
@theme {
  --color-brand: #6d28d9;
  --font-display: "Geist", "sans-serif";
}
```

No `content` array, no `require()`, no build-time JS execution needed for config — Tailwind parses your CSS file directly. Full deep-dive on `@theme` is in **Part 3**.

## 1.4 Browser Support Trade-off (Read Before You Commit)

Tailwind v4 relies on modern native CSS features it does NOT polyfill:

| Feature used internally | Minimum browser |
|---|---|
| Cascade layers (`@layer`) | Safari 16.4+, Chrome 99+, Firefox 97+ |
| `@property` (used for gradient/animation interpolation) | Safari 16.4+, Chrome 85+, Firefox 128+ |
| `color-mix()` (used for opacity modifiers like `bg-brand/50`) | Safari 16.2+, Chrome 111+, Firefox 113+ |

**Practical floor: Safari 16.4, Chrome 111, Firefox 128 (roughly early-to-mid 2023 onward).** If you must support older browsers (e.g. enterprise IE-adjacent environments), stay on Tailwind v3. This series assumes a modern-browser target, which is the default assumption for new Next.js 16 / React 19 projects.

## 1.5 Exercise Challenge

1. Create an empty CSS file with just `@import "tailwindcss";`.
2. Add a `@theme` block defining `--color-accent: #16a34a;`.
3. Predict (without running it) what two utility classes Tailwind will generate from that single variable.

## 1.6 Solution

```css
@import "tailwindcss";

@theme {
  --color-accent: #16a34a;
}
```

Tailwind generates utilities for **every applicable category** that a `--color-*` namespaced variable maps to, including (non-exhaustive):

- `bg-accent` (background-color)
- `text-accent` (color)
- `border-accent` (border-color)
- `ring-accent`, `fill-accent`, `stroke-accent`, `decoration-accent`, `accent-accent` (the `accent-color` CSS property), `caret-accent`, `outline-accent`, `divide-accent`, `from-accent`/`via-accent`/`to-accent` (gradient stops)

This is the core mental model shift for v4: **you define a token once in `@theme`, and Tailwind fans it out across every relevant utility family automatically** — because the namespace prefix (`--color-*`, `--font-*`, `--spacing-*`, etc.) tells Tailwind's engine which utility categories should consume it. Full namespace table in Part 3.

---

*Next: Tailwind v4 Mastery - Part 2: Installation Deep-Dive*
