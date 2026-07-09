# Part 1: The Anatomy of a Page

## 1. Browser Reality — The Document Skeleton

Every page a browser renders starts as this, with no framework involved:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>My Page</title>
    <link rel="stylesheet" href="styles.css" />
  </head>
  <body>
    <header>
      <h1>Site Title</h1>
    </header>
    <main>
      <p>Page content goes here.</p>
    </main>
    <footer>
      <p>&copy; 2025</p>
    </footer>
  </body>
</html>
```

**What each piece does:**
- `<!DOCTYPE html>` — tells the browser to use standards mode rendering (not quirks mode).
- `<html lang="en">` — the root element. `lang` is not decoration — screen readers use it to pick pronunciation rules.
- `<head>` — metadata that never renders visually: `<title>`, `<meta>` tags, stylesheet links, favicons.
- `<body>` — the only part a user actually sees.

**Why `<header>`, `<main>`, `<footer>` instead of `<div>`?**
These are *landmark* elements. Screen reader users can jump directly between landmarks (press a shortcut key to skip to `main`, `nav`, etc.). A page built entirely from `<div>`s is invisible to landmark navigation — technically it "works," but it's functionally inaccessible to assistive tech users. There should be exactly **one** `<main>` per page, and it should wrap the primary content only (not the header/nav/footer).

## 2. The Next.js Translation — `RootLayout.tsx`

In the Next.js 16 App Router, `app/layout.tsx` **is** your `<html>`/`<head>`/`<body>` shell. You write it once, and Next.js injects it around every route.

```tsx
// app/layout.tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "My Site",
  description: "A demonstration of Next.js 16 fundamentals",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <header>
          <h1>Site Title</h1>
        </header>
        <main>{children}</main>
        <footer>
          <p>&copy; 2025</p>
        </footer>
      </body>
    </html>
  );
}
```

**Mapping the abstraction back to the fundamental:**

| Raw HTML | RootLayout.tsx equivalent |
|---|---|
| `<head><title>...</title></head>` | The exported `metadata` object — Next.js generates the `<head>` tags for you |
| `<html lang="en">` written by hand | `<html lang="en">` written by hand — Next.js does **not** auto-generate this; you must set `lang` yourself, still, for a11y |
| `<body>` wrapping every page | `<body>` in `layout.tsx`, rendered once, wrapping every route via `{children}` |
| Copy-pasting header/footer into every `.html` file | `{children}` — the *only* part that changes per route; header/footer are defined once |

`children` here is literally the current route's `page.tsx` output. Nothing magic — it's the same children-prop composition pattern as any React component, just Next.js decides *which* page fills the slot based on the URL.

**A note on `metadata`:** this is Next.js generating `<head>` content for you at build/request time so you never hand-write `<title>` or `<meta>` tags per page. Each nested `page.tsx` or `layout.tsx` can export its own `metadata` and Next.js merges them going down the tree.

## 3. Browser Reality — The CSS Box Model

Every rendered HTML element is a rectangular box made of four layers, from the inside out:

```
┌─────────────────────────────────────┐
│               margin                 │  ← space outside the border, transparent
│  ┌─────────────────────────────────┐ │
│  │             border               │ │  ← visible line, has width + style + color
│  │  ┌───────────────────────────┐  │ │
│  │  │          padding           │  │ │  ← space inside the border, same bg as content
│  │  │  ┌─────────────────────┐  │  │ │
│  │  │  │       content        │  │  │ │  ← the actual text/image/element
│  │  │  └─────────────────────┘  │  │ │
│  │  └───────────────────────────┘  │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

Raw CSS:

```css
.card {
  margin: 8px;
  border: 1px solid #d1d5db;
  padding: 16px;
  /* content is whatever's inside the element */
}
```

**Key fact:** by default, `width`/`height` apply only to *content*. Padding and border are added on top, growing the box (this is `box-sizing: content-box`). Most modern CSS resets — including Tailwind's — switch every element to `box-sizing: border-box`, where `width` includes padding and border, so sizing is predictable.

## 4. The Tailwind Translation — Utility Classes Are the Box Model

Tailwind classes are literally named after the box model properties they set:

```html
<div class="m-2 border p-4">
  Content
</div>
```

```css
/* what m-2 border p-4 compiles to, roughly */
.m-2   { margin: 0.5rem; }        /* 8px — Tailwind's spacing scale: 1 unit = 0.25rem = 4px */
.border { border-width: 1px; border-style: solid; border-color: currentColor; }
.p-4   { padding: 1rem; }         /* 16px */
```

| Tailwind class | Box model property | Raw CSS |
|---|---|---|
| `m-2` | margin | `margin: 0.5rem;` |
| `mt-4` / `mb-4` / `ml-4` / `mr-4` | margin per-side | `margin-top/bottom/left/right: 1rem;` |
| `mx-4` / `my-4` | margin horizontal/vertical pair | `margin-left + margin-right` / `margin-top + margin-bottom` |
| `p-4` | padding | `padding: 1rem;` |
| `border` | border-width + style | `border: 1px solid;` |
| `border-2` | thicker border | `border-width: 2px;` |
| `border-gray-300` | border color | `border-color: #d1d5db;` |
| `w-64` | content width (border-box) | `width: 16rem;` |

There is no new mechanism here — Tailwind just gives you a pre-scaled, constrained numeric system (increments of `0.25rem`) so every developer on a team draws from the same spacing scale instead of inventing arbitrary `13px`, `17px` values.

## 5. Putting It Together

```tsx
// app/page.tsx
export default function Page() {
  return (
    <article className="m-2 border border-gray-300 p-4">
      <h2 className="mb-2 text-lg font-semibold">Card Title</h2>
      <p className="text-gray-600">
        This article element uses the box model: margin pushes it away from
        siblings, the border draws a visible edge, and padding keeps the text
        off the border.
      </p>
    </article>
  );
}
```

Note `<article>` instead of `<div>` — it signals to assistive tech and search engines that this block is a self-contained, independently distributable piece of content (a card, a blog post, a comment). Reach for the most specific semantic element before falling back to `<div>`.

## Exercise Challenge

Build a `Notice.tsx` Server Component that renders a semantic `<aside>` styled as a callout box: `border-l-4` (a left accent border), `p-4`, `m-4`, with a `role="note"` or appropriate semantic wrapper. Requirements:
1. Accepts a `children` prop for the message content.
2. Uses `<aside>`, not `<div>`.
3. Uses only box-model utility classes (`m-*`, `p-*`, `border-*`) — no flex/grid yet, that's Part 2.

## Solution

```tsx
// app/components/Notice.tsx
export default function Notice({ children }: { children: React.ReactNode }) {
  return (
    <aside
      className="m-4 border-l-4 border-blue-500 bg-blue-50 p-4 text-blue-900"
      role="note"
    >
      {children}
    </aside>
  );
}
```

**Why this passes:** `<aside>` is semantically correct for content that's tangentially related to the main flow (a tip, a callout) — screen readers announce it as a distinct region. `role="note"` reinforces intent for assistive tech that doesn't fully support `<aside>` semantics. Every visual property traces back to the box model: `m-4` (margin, spacing from siblings), `border-l-4` (a border, just constrained to one side), `p-4` (padding, keeping text off the accent line).

**Next:** Part 2 covers how boxes are arranged relative to each other — Normal Flow, Flexbox, and Grid.
