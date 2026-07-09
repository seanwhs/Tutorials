# Part 2: Flow & Positioning

## 1. Browser Reality — Normal Document Flow

With no CSS at all, block-level elements (`<div>`, `<p>`, `<section>`, `<article>`) stack top-to-bottom, each taking the full available width. Inline elements (`<span>`, `<a>`, `<strong>`) sit left-to-right within the line, wrapping like text. This default behavior is called **Normal Document Flow**.

```html
<section>
  <p>First paragraph.</p>
  <p>Second paragraph.</p>
</section>
```

```css
/* no CSS needed — this is the browser's default stacking behavior */
```

Both `<p>` tags render as full-width blocks, stacked vertically, in source order. This is the baseline every layout system (Flexbox, Grid, positioning) exists to override.

**Why order matters for accessibility:** Screen readers and keyboard tab order follow *source order*, not visual order. If you use CSS to visually reorder elements (e.g., `order` in Flexbox, or absolute positioning) without also updating the DOM order, sighted mouse users and screen-reader/keyboard users can experience the page in a different sequence — a common, avoidable a11y bug.

## 2. Browser Reality — Flexbox Fundamentals

Flexbox arranges children of a container along a single axis (row or column).

```css
.nav {
  display: flex;
  flex-direction: row;       /* main axis: left → right */
  justify-content: space-between; /* distribute along main axis */
  align-items: center;       /* align along cross axis */
  gap: 1rem;                 /* space between children, no manual margins needed */
}
```

```html
<nav class="nav">
  <a href="/">Logo</a>
  <a href="/about">About</a>
  <a href="/contact">Contact</a>
</nav>
```

**Core concepts:**
- `display: flex` turns direct children into flex items, opting out of normal block flow.
- **Main axis** is set by `flex-direction` (`row` = horizontal, `column` = vertical).
- `justify-content` positions items *along the main axis* (start, center, space-between, space-around).
- `align-items` positions items *along the cross axis* (perpendicular to main axis).
- `gap` replaces manual margin hacks between siblings.

## 3. The Tailwind Translation — Flexbox

```html
<nav class="flex flex-row items-center justify-between gap-4">
  <a href="/">Logo</a>
  <a href="/about">About</a>
  <a href="/contact">Contact</a>
</nav>
```

| Tailwind class | Raw CSS |
|---|---|
| `flex` | `display: flex;` |
| `flex-row` (default, often omitted) | `flex-direction: row;` |
| `flex-col` | `flex-direction: column;` |
| `justify-between` | `justify-content: space-between;` |
| `justify-center` | `justify-content: center;` |
| `items-center` | `align-items: center;` |
| `gap-4` | `gap: 1rem;` |
| `flex-1` | `flex: 1 1 0%;` (grow/shrink to fill space) |

There is a **1:1 name mapping** — Tailwind didn't invent new layout concepts, it just shortened the CSS property names into class names (`justify-content: space-between` → `justify-between`).

## 4. Browser Reality — CSS Grid Fundamentals

Grid arranges children in two dimensions (rows *and* columns) simultaneously.

```css
.gallery {
  display: grid;
  grid-template-columns: repeat(3, 1fr); /* 3 equal-width columns */
  gap: 1rem;
}
```

```html
<div class="gallery">
  <figure>1</figure>
  <figure>2</figure>
  <figure>3</figure>
  <figure>4</figure>
</div>
```

`1fr` means "one fraction of remaining space" — three `1fr` tracks split available width evenly. Grid also supports explicit rows, named areas, and item spanning (`grid-column: span 2`), which Flexbox cannot do natively in one dimension.

**When to use which:** Flexbox for one-dimensional arrangement (a toolbar, a nav, a list of tags). Grid for two-dimensional layout (a page shell, a photo gallery, a dashboard).

## 5. The Tailwind Translation — Grid

```html
<div class="grid grid-cols-3 gap-4">
  <figure>1</figure>
  <figure>2</figure>
  <figure>3</figure>
  <figure>4</figure>
</div>
```

| Tailwind class | Raw CSS |
|---|---|
| `grid` | `display: grid;` |
| `grid-cols-3` | `grid-template-columns: repeat(3, minmax(0, 1fr));` |
| `col-span-2` | `grid-column: span 2 / span 2;` |
| `grid-rows-2` | `grid-template-rows: repeat(2, minmax(0, 1fr));` |
| `gap-4` | `gap: 1rem;` |

Tailwind also gives you **responsive variants for free** by prefixing a breakpoint:

```html
<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
```

This compiles to CSS media queries under the hood:

```css
.grid-cols-1 { grid-template-columns: repeat(1, minmax(0, 1fr)); }
@media (min-width: 768px) {
  .md\:grid-cols-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (min-width: 1024px) {
  .lg\:grid-cols-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
}
```

You are still writing media queries — Tailwind just lets you write them inline next to the element they affect, instead of in a separate stylesheet block far from the markup.

## 6. Putting It Together in Next.js 16

```tsx
// app/components/SiteNav.tsx
export default function SiteNav() {
  return (
    <nav className="flex items-center justify-between gap-4 border-b border-gray-200 p-4">
      <span className="font-bold">Acme</span>
      <ul className="flex items-center gap-6">
        <li><a href="/" className="hover:underline">Home</a></li>
        <li><a href="/about" className="hover:underline">About</a></li>
        <li><a href="/contact" className="hover:underline">Contact</a></li>
      </ul>
    </nav>
  );
}
```

```tsx
// app/components/DashboardGrid.tsx
export default function DashboardGrid({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="grid grid-cols-1 gap-4 p-4 md:grid-cols-2 lg:grid-cols-3">
      {children}
    </div>
  );
}
```

**Why `<nav>` + `<ul>` instead of `<div>` + `<div>`s?** `<nav>` is a landmark region ("jump to navigation" for screen readers). `<ul>` communicates "this is a list of N related links" — screen readers announce list length ("list, 3 items"), which orients users in a way a `<div>` soup never can. Flexbox is purely visual arrangement; it does not change the semantic meaning already established by the tags.

## Exercise Challenge

Build a `CardGrid.tsx` Server Component:
1. A responsive grid: 1 column on mobile, 2 on `md`, 3 on `lg`.
2. Each card is an `<article>` with a `<h3>` title and `<p>` description, passed as `children`.
3. Inside each card, use Flexbox to vertically stack the title above the description with consistent spacing — no manual margins, use `gap`.

## Solution

```tsx
// app/components/CardGrid.tsx
export default function CardGrid({ children }: { children: React.ReactNode }) {
  return (
    <div className="grid grid-cols-1 gap-4 p-4 md:grid-cols-2 lg:grid-cols-3">
      {children}
    </div>
  );
}

// app/components/Card.tsx
export default function Card({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <article className="flex flex-col gap-2 rounded border border-gray-200 p-4">
      <h3 className="font-semibold">{title}</h3>
      <p className="text-gray-600">{description}</p>
    </article>
  );
}

// app/page.tsx
import CardGrid from "./components/CardGrid";
import Card from "./components/Card";

export default function Page() {
  return (
    <CardGrid>
      <Card title="Fast" description="Turbopack dev server." />
      <Card title="Typed" description="TypeScript end to end." />
      <Card title="Styled" description="Tailwind utility classes." />
    </CardGrid>
  );
}
```

**Why this passes:** Grid solves the outer two-dimensional layout (cards wrap into rows/columns responsively); Flexbox solves the inner one-dimensional stacking (title above description). Nesting layout systems this way — Grid for the macro layout, Flexbox for micro layout inside each cell — is the standard pattern, not a workaround.

**Next:** Part 3 covers the Cascade, specificity, and why Tailwind's atomic classes sidestep the "specificity war" entirely.
