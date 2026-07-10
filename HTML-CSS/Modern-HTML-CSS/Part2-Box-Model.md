# Part 2: The Box Model & Layouts

## 1. Concept Explanation

### The Box Model, and why `box-sizing` is non-negotiable

Every element on a page is a rectangular box made of four layers, from the inside out: **content**, **padding**, **border**, **margin**. By default, CSS uses `box-sizing: content-box`, which means when you set `width: 300px`, that width applies only to the content area — padding and border get *added on top*, making the element's rendered footprint bigger than the number you typed. This causes constant surprises: add `padding: 20px` to a `width: 300px` box and it silently becomes 340px wide (assuming no border).

`box-sizing: border-box` fixes this by making `width`/`height` include padding and border. The box you specify is the box you get. This is why virtually every modern CSS reset starts with:

```css
*, *::before, *::after {
  box-sizing: border-box;
}
```

Applying it globally, once, at the top of your stylesheet, removes an entire category of layout bugs for the rest of the project.

### Flexbox vs. Grid — choosing the right tool

Both are modern layout systems, but they solve different problems:

- **Flexbox is one-dimensional.** It excels at distributing space among items in a row *or* a column — navbars, button groups, card internals (image + title + text + button stacked vertically), centering a single item. Think "arrange a strip of things."
- **Grid is two-dimensional.** It excels at defining both rows and columns simultaneously — full page shells, image galleries, dashboard layouts. Think "arrange things on a spreadsheet."

A practical rule used throughout this series: **Grid for the page-level shell and card grids, Flexbox for the internals of individual components.** You'll see this exact split in the NovaFolio implementation below.

### Key properties reference

**Flexbox (on the parent, `display: flex`):**

| Property | Purpose |
|---|---|
| `flex-direction` | `row` (default) or `column` |
| `justify-content` | Alignment along the main axis (`flex-start`, `center`, `space-between`) |
| `align-items` | Alignment along the cross axis |
| `gap` | Space between children (replaces margin hacks) |
| `flex-wrap` | Allow items to wrap onto new lines |

**Grid (on the parent, `display: grid`):**

| Property | Purpose |
|---|---|
| `grid-template-columns` | Defines column tracks, e.g. `1fr 1fr 1fr` or `repeat(3, 1fr)` |
| `grid-template-rows` | Defines row tracks |
| `gap` | Space between grid cells (rows and columns) |
| `grid-template-areas` | Named layout regions for readable, self-documenting shells |
| `grid-column` / `grid-row` | Place a specific child, e.g. `span 2` |

The `fr` unit is Grid's superpower: it means "a fraction of the remaining free space" — `grid-template-columns: 2fr 1fr` gives the first column exactly twice the width of the second, and it recalculates automatically on resize.

## 2. Implementation: Styling NovaFolio

### Step 1 — The reset and base file (`css/reset.css`)

```css
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html {
  -webkit-text-size-adjust: 100%;
}

img, picture, svg {
  display: block;
  max-width: 100%;
}

body {
  min-height: 100vh;
  line-height: 1.5;
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
}

.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
}

.visually-hidden:focus {
  position: static;
  width: auto;
  height: auto;
  clip: auto;
}
```

Note `.visually-hidden:focus` — this is what makes our skip link from Part 1 invisible normally but pop into view the moment a keyboard user tabs to it. Locality of Behavior in action: the accessibility contract lives right next to the class that implements it.

### Step 2 — Link the stylesheets

Modular CSS files, one per concern, loaded in a deliberate order (reset first, then layout, then components):

```html
<head>
  ...
  <link rel="stylesheet" href="css/reset.css">
  <link rel="stylesheet" href="css/layout.css">
  <link rel="stylesheet" href="css/components.css">
</head>
```

This is the CSS-file equivalent of the folder structure in Part 1: structure (HTML) stays untouched, and presentation is layered in from separate, single-responsibility files. We'll deepen this modular approach in Part 4.

### Step 3 — The page shell with Grid (`css/layout.css`)

```css
body {
  display: grid;
  grid-template-rows: auto 1fr auto;
  grid-template-areas:
    "header"
    "main"
    "footer";
  min-height: 100vh;
}

.site-header  { grid-area: header; }
main          { grid-area: main; }
.site-footer  { grid-area: footer; }
```

`grid-template-areas` reads like a diagram of the page itself — you can look at the CSS and immediately see the page's shape without mentally tracing row/column numbers. This is a deliberate architectural choice: named areas are self-documenting.

### Step 4 — The header, styled with Flexbox

```css
.site-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem 2rem;
  border-bottom: 1px solid #e2e2e2;
}

.primary-nav ul {
  display: flex;
  gap: 1.5rem;
  list-style: none;
}

.primary-nav a {
  text-decoration: none;
  color: inherit;
  font-weight: 600;
}
```

The header is a one-dimensional strip: logo on the left, nav on the right. `justify-content: space-between` pushes them to opposite ends with zero manual math. The nav's `ul` is itself a flex row with `gap` instead of margin-right hacks on each `li`.

### Step 5 — Main content grid (the dashboard shell)

```css
main {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 2rem;
  padding: 2rem;
  max-width: 1200px;
  margin-inline: auto;
}

.hero,
#projects,
#activity {
  grid-column: 1;
}

#about {
  grid-column: 2;
  grid-row: 1 / 4;
}
```

This is the two-dimensional layout Grid is built for: a wide primary column (hero, projects, activity feed) and a narrower sidebar column (the About aside) that spans multiple rows. `margin-inline: auto` centers the whole shell on wide screens using logical properties (more on those in Part 3).

### Step 6 — Stat cards and project cards with Flexbox internals

```css
#stats {
  display: flex;
  gap: 1rem;
  margin-block: 2rem;
}

.stat-card {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 1.5rem;
  border: 1px solid #e2e2e2;
  border-radius: 0.5rem;
  text-align: center;
}

.stat-card__number {
  font-size: 2rem;
  font-weight: 700;
}

.project-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1.5rem;
  list-style: none;
}

.project-card {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  padding: 1.5rem;
  border: 1px solid #e2e2e2;
  border-radius: 0.5rem;
  height: 100%;
}

.project-card__tags {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
  list-style: none;
}
```

Notice the pattern repeating across the whole file: **Grid decides how many cards fit per row and how wide each is; Flexbox decides how the content stacks inside each individual card.** `repeat(auto-fit, minmax(240px, 1fr))` is worth memorizing — it's a fully responsive card grid with zero media queries: cards are at least 240px wide, and Grid automatically fits as many as will fit per row, wrapping the rest.

### Step 7 — The button component

```css
.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.75rem 1.5rem;
  border-radius: 0.375rem;
  text-decoration: none;
  font-weight: 600;
  border: 2px solid transparent;
}

.button--primary {
  background: #2563eb;
  color: white;
}

.button--primary:hover {
  background: #1d4ed8;
}
```

This is our first taste of BEM naming (`button`, `button--primary`) — formalized fully in Part 4, but introduced here so it feels natural by the time we name it explicitly.

## 3. Exercise Challenge

The `.site-footer` currently has no styling. Using what you've learned:

1. Lay out the footer as a Flexbox row on desktop, with the copyright text on the left and the social links list on the right — but stack them vertically, centered, on narrow viewports (you can use `flex-wrap` for a basic version; a proper breakpoint-based version comes in Part 3).
2. Convert `.social-links` into a horizontal Flexbox row with consistent `gap`.
3. Give the footer's `nav` (the "Back to top" link) sensible spacing using `padding` and confirm your `box-sizing: border-box` reset is preventing any width overflow.

## 4. Solution & Explanation

```css
.site-footer {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.5rem 2rem;
  border-top: 1px solid #e2e2e2;
}

.social-links {
  display: flex;
  gap: 1rem;
  list-style: none;
}

.site-footer nav {
  padding-inline-end: 1rem;
}
```

`flex-wrap: wrap` combined with `justify-content: space-between` is the "cheap responsive" trick: when the row runs out of horizontal space, the copyright block and social links naturally drop to their own lines instead of overflowing or squeezing unreadably — because every child's box already respects `border-box`, no padding or border miscalculation causes an unexpected horizontal scrollbar. This is a preview of Part 3, where we'll replace ad-hoc wrapping with deliberate, mobile-first media queries for full control over the breakpoint.

---

Next: **Part 3 — Responsive Design**, where NovaFolio gets fluid typography, `clamp()`, and real breakpoints.
