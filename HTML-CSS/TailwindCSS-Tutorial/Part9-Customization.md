# Part 9: Advanced Customization

## 9.1 `@utility` — Defining Custom Utility Classes (Replaces `@layer utilities` + `theme()`)

In v3, custom utilities were added via a JS plugin function or a manual `@layer utilities { .my-class { ... } }` block that couldn't easily accept variants (`hover:`, `md:`, etc.). In v4, `@utility` produces a **first-class utility** that automatically supports every variant.

```css
/* src/app/globals.css */
@import "tailwindcss";

/* Simple static custom utility */
@utility scrollbar-hide {
  scrollbar-width: none;
  &::-webkit-scrollbar {
    display: none;
  }
}

/* Functional custom utility accepting a value — the dash placeholder captures it */
@utility text-shadow-* {
  text-shadow: 0 2px 4px --value(--color-*, [color]);
}
```

```tsx
<div className="scrollbar-hide flex overflow-x-auto hover:scrollbar-hide">
  {/* scrollbar-hide now supports variants automatically, e.g. md:scrollbar-hide */}
</div>

<h1 className="text-shadow-brand-900 md:text-shadow-black">
  {/* text-shadow-* resolves against theme colors OR arbitrary [color] values */}
</h1>
```

## 9.2 Arbitrary Values — Escape Hatch for One-Off Styles

Square-bracket syntax lets you use any valid CSS value without touching `@theme`:

```tsx
<div className="w-[137px] bg-[#1da1f2] text-[15px] top-[calc(100%-1rem)]">
  Arbitrary width, exact brand hex, precise font size, calc() expression
</div>

<div className="grid grid-cols-[repeat(auto-fit,minmax(200px,1fr))] gap-4">
  Auto-fit responsive grid without any breakpoints
</div>

<div className="bg-[url('/hero.jpg')] bg-cover">Arbitrary background image URL</div>

<div className="[mask-image:linear-gradient(to_bottom,black,transparent)]">
  Arbitrary CSS PROPERTY entirely (property:value in brackets) for one-off cases
  Tailwind doesn't have a named utility for
</div>
```

> **Rule of thumb:** reach for arbitrary values for genuinely one-off cases. If you find yourself repeating the same arbitrary value 3+ times, promote it to a named `@theme` token instead (Part 3) — that gives you IntelliSense autocomplete, consistency, and a single point of change.

## 9.3 Arbitrary Variants — One-Off Selectors

```tsx
<div className="[&>p]:mt-2 [&>p]:text-slate-500">
  {/* Targets direct child <p> elements without needing a custom @custom-variant */}
  <p>First paragraph</p>
  <p>Second paragraph</p>
</div>

<ul className="[&_li:nth-child(3)]:font-bold">
  {/* Targets the 3rd <li> specifically via a descendant + pseudo-class combo */}
</ul>

<div className="[@media(min-width:1440px)]:hidden">
  {/* A fully custom, inline media query when no theme breakpoint fits */}
</div>
```

## 9.4 The `--value()` and `--modifier()` Functions in Custom Utilities

```css
@theme {
  --spacing-gutter: 1.5rem;
}

/* --value() resolves a bare value against a theme namespace, a literal, or an arbitrary value */
@utility gutter-* {
  padding-inline: --value(--spacing-*, [length]);
}
```

```tsx
<div className="gutter-gutter">Uses the theme token --spacing-gutter</div>
<div className="gutter-[2vw]">Uses an arbitrary value directly</div>
```

## 9.5 Prefixing Utilities (Avoiding Collisions with Other CSS Libraries)

If you're integrating Tailwind into a codebase that also loads Bootstrap, a design system, or a CMS theme with clashing class names (e.g. both define `.container` or `.btn`), apply a prefix:

```css
@import "tailwindcss" prefix(tw);
```

```tsx
<div className="tw:flex tw:items-center tw:gap-4 tw:bg-brand-500">
  {/* Every utility now requires the tw: prefix, preventing collisions with
      a legacy .flex or .bg-* class from another library */}
</div>
```

> Note the syntax difference from v3 (`prefix: 'tw-'` in JS config) — v4 prefixes are applied as a **variant-like prefix** (`tw:flex`), not concatenated directly onto the class name (`tw-flex`).

## 9.6 Important Modifier & Important Strategy

```tsx
<div className="flex! bg-red-500!">
  {/* Trailing ! forces !important on that utility only — useful for overriding
      inline styles injected by a third-party JS widget you don't control */}
</div>
```

```css
/* Global important strategy (rare — prefer per-utility ! when possible) */
@import "tailwindcss" important;
```

## 9.7 Disabling Specific Core Plugins / Utilities

```css
@theme {
  /* Remove default filter-related utilities entirely from output if genuinely unused,
     shrinking generated CSS marginally (usually unnecessary — v4 already only
     generates classes actually found in your source) */
  --blur-*: initial;
}
```

In practice this is rarely needed in v4 because content-based generation already means unused utilities never make it into your CSS bundle — this is mostly for enforcing design-system constraints (e.g. "no team member should be able to reach for an arbitrary blur value").

## 9.8 Source() Directive — Explicit Content Scanning (Overriding Automatic Detection)

Automatic detection (Part 1) usually "just works," but for monorepos or shared UI packages living outside the app's own directory tree, be explicit:

```css
@import "tailwindcss";

/* Explicitly include a shared UI package's source files in class scanning,
   e.g. a pnpm workspace package at packages/ui that Tailwind wouldn't
   otherwise discover automatically from the app's own folder */
@source "../../packages/ui/src/**/*.{ts,tsx}";
```

```css
/* Explicitly EXCLUDE a directory that would otherwise be scanned
   (e.g. a large vendored/generated folder with false-positive class-like strings) */
@source not "../../vendor/**/*";
```

## 9.9 Exercise Challenge

Define a custom `@utility` called `card-grid-*` that accepts a numeric column count value and produces a CSS grid with that many equal columns, then use it with both a theme-friendly value and an arbitrary one.

## 9.10 Solution

```css
@theme {
  --card-grid-2: 2;
  --card-grid-3: 3;
  --card-grid-4: 4;
}

@utility card-grid-* {
  display: grid;
  grid-template-columns: repeat(--value(--card-grid-*, integer), minmax(0, 1fr));
  gap: 1rem;
}
```

```tsx
<div className="card-grid-3">
  {/* Uses the theme token --card-grid-3 -> 3 equal columns */}
</div>

<div className="card-grid-[5]">
  {/* Arbitrary value bypassing the theme entirely -> 5 equal columns */}
</div>
```

---

*Next: Tailwind v4 Mastery - Part 10: Performance, Tooling & Editor Setup*
