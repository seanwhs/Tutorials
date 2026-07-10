# Part 3: The Semantic Web (HTML/CSS)

## 3.1 Concept: Why "Semantic" Matters

Semantic HTML means choosing tags based on *meaning*, not appearance. `<button>` vs. a styled `<div onclick>` look identical but behave completely differently: only `<button>` gets keyboard focus, triggers on `Enter`/`Space`, and is announced correctly by screen readers — for free, with zero JavaScript. Professional developers default to semantic tags first and only reach for generic `<div>`/`<span>` when no semantic tag fits.

This matters concretely in Next.js: the App Router renders real HTML on the server (Part 5). If your HTML is semantically sound, you get accessibility, SEO, and correct browser behavior essentially for free — before any client JavaScript even loads.

## 3.2 The Semantic Tag Vocabulary

| Tag | Use for |
|---|---|
| `<header>` | Page or section introductory content |
| `<nav>` | Navigation links |
| `<main>` | The primary content of the page (one per page) |
| `<section>` | A thematic grouping of content, usually with a heading |
| `<article>` | Self-contained, independently distributable content (a card, a post) |
| `<aside>` | Tangential content (sidebar, related links) |
| `<footer>` | Footer content |
| `<button>` | Anything clickable that performs an action |
| `<a>` | Anything that navigates to a new URL |

## 3.3 Implementation: DevBoard's Static Markup

This is DevBoard's structure with zero styling and zero JavaScript — pure semantic HTML, the skeleton every later Part enhances.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>DevBoard</title>
  <link rel="stylesheet" href="styles.css" />
</head>
<body>
  <header class="app-header">
    <h1>DevBoard</h1>
    <nav aria-label="Primary">
      <a href="/">Boards</a>
      <a href="/settings">Settings</a>
    </nav>
  </header>

  <main class="board">
    <section class="column" aria-labelledby="todo-heading">
      <h2 id="todo-heading">Todo</h2>
      <ul class="card-list">
        <li class="card">
          <article>
            <h3>Fix login bug</h3>
            <p>Users report session expiring too early.</p>
          </article>
        </li>
      </ul>
      <button type="button" class="add-card-btn">+ Add card</button>
    </section>

    <section class="column" aria-labelledby="progress-heading">
      <h2 id="progress-heading">In Progress</h2>
      <ul class="card-list">
        <li class="card">
          <article>
            <h3>Design card drag animation</h3>
          </article>
        </li>
      </ul>
      <button type="button" class="add-card-btn">+ Add card</button>
    </section>

    <section class="column" aria-labelledby="done-heading">
      <h2 id="done-heading">Done</h2>
      <ul class="card-list">
        <li class="card">
          <article>
            <h3>Set up Next.js project</h3>
          </article>
        </li>
      </ul>
      <button type="button" class="add-card-btn">+ Add card</button>
    </section>
  </main>

  <footer class="app-footer">
    <p>&copy; 2026 DevBoard</p>
  </footer>
</body>
</html>
```

Notice: no `<div class="column">` — a `<section>` with a heading is more meaningful, and screen readers announce "Todo, region" navigable landmarks for free.

## 3.4 Modern CSS Layout: Flexbox vs. Grid

**Rule of thumb:** Flexbox for one-dimensional layouts (a row or a column of items). Grid for two-dimensional layouts (rows *and* columns simultaneously).

DevBoard's board is a perfect Grid use case (columns side by side); each column's card list is a perfect Flexbox use case (a vertical stack).

```css
/* styles.css */

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: system-ui, -apple-system, sans-serif;
  color: #1a1a1a;
  background: #f4f5f7;
}

.app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem 1.5rem;
  background: #ffffff;
  border-bottom: 1px solid #e2e2e2;
}

.app-header nav {
  display: flex;
  gap: 1rem;
}

/* GRID: the board lays out columns side by side */
.board {
  display: grid;
  grid-template-columns: repeat(3, minmax(260px, 1fr));
  gap: 1rem;
  padding: 1.5rem;
}

/* Responsive: collapse to a single column on small screens */
@media (max-width: 768px) {
  .board {
    grid-template-columns: 1fr;
  }
}

.column {
  background: #ebecf0;
  border-radius: 8px;
  padding: 0.75rem;
  display: flex;         /* FLEX: heading, list, button stacked vertically */
  flex-direction: column;
  gap: 0.5rem;
}

/* FLEX: the list of cards stacks vertically with consistent spacing */
.card-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.card {
  background: #ffffff;
  border-radius: 6px;
  padding: 0.75rem;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.card article h3 {
  margin: 0 0 0.25rem 0;
  font-size: 0.95rem;
}

.add-card-btn {
  background: transparent;
  border: none;
  text-align: left;
  padding: 0.5rem;
  color: #5e6c84;
  cursor: pointer;
  border-radius: 4px;
}

.add-card-btn:hover {
  background: rgba(9, 30, 66, 0.08);
}

.app-footer {
  text-align: center;
  padding: 1rem;
  color: #6b6b6b;
  font-size: 0.85rem;
}
```

## 3.5 Accessibility Checklist (Applies From Here Forward)

- Every interactive element is a real `<button>` or `<a>`, never a `<div onclick>`.
- Images need `alt` text; decorative images use `alt=""` (not omitted — omission is read as "unknown image" by some screen readers).
- Every form input has an associated `<label>` (see Part 6).
- Color contrast: body text against background should meet **WCAG AA** (4.5:1 contrast ratio minimum). Use Chrome DevTools' contrast checker (inspect an element -> click the color swatch).
- Heading levels (`h1` -> `h2` -> `h3`) should never skip a level.

## 3.6 Under the Hood: The Box Model & the Cascade

Every element is a box: `content` -> `padding` -> `border` -> `margin`. `box-sizing: border-box` (set globally above) makes `width`/`height` include padding and border, which is almost always what you actually want and avoids the classic "why is my box wider than I set it" bug.

CSS specificity resolves conflicts in this order (lowest to highest): element selectors (`div`) < class selectors (`.card`) < ID selectors (`#todo-heading`) < inline styles < `!important`. Professional convention: avoid IDs for styling and never reach for `!important` — both are signs the CSS architecture needs rethinking, and both cause exactly the kind of override wars you'll fight later if you don't. This is also why Tailwind (Part 7) is popular: utility classes have flat, predictable specificity, sidestepping this entire class of bug.

## Exercise Challenge

1. Add a 4th column called "Blocked" to the Grid layout without hardcoding a 4th `grid-template-columns` track — make the CSS automatically handle any number of columns.
2. Make the `.card` element show a `focus` outline when tabbed to (keyboard accessibility) even though it's not naturally focusable.
3. Fix the heading hierarchy if you notice any issues.

## Solution & Explanation

```css
.board {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 1rem;
  padding: 1.5rem;
}
```

`repeat(auto-fit, minmax(260px, 1fr))` tells Grid to fit as many 260px-minimum columns as will comfortably wrap, growing them evenly — no column count needs to be hardcoded, and it degrades gracefully on narrow screens without a media query.

For focus visibility on non-naturally-focusable elements, the better fix is to make cards real `<button>`s or add `tabindex="0"` plus:

```css
.card:focus-visible {
  outline: 2px solid #0052cc;
  outline-offset: 2px;
}
```

`:focus-visible` (rather than `:focus`) shows the outline only for keyboard navigation, not mouse clicks — matching what users actually expect.

---
*Next: `Roadmap Tutorial - Part 4: JavaScript Fundamentals`*
