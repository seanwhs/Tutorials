# Part 5: Advanced Interactions

## 1. Concept Explanation

### `:has()` — the "parent selector" CSS always needed

For years, CSS could style a descendant based on its ancestor, but never the reverse. `:has()` finally lets a selector match a parent based on what's *inside* it:

```css
/* Style a card differently if it contains a "featured" badge */
.card:has(.card__badge--featured) {
  border-color: var(--color-primary);
}
```

This eliminates a whole category of JavaScript that used to exist purely to toggle a class on a parent based on a child's state. Common real-world uses: styling a form field's wrapper when its `input:invalid` is present, styling a `label` when its paired `input:checked`, or — as we'll use below — styling a whole card differently depending on its content, and building form validation states with zero JS.

### Scroll-driven animations — animating with scroll position, not JS scroll listeners

Traditionally, "animate this element in as it scrolls into view" required an `IntersectionObserver` and JavaScript class-toggling. The `animation-timeline: view()` property ties a CSS animation's progress directly to an element's position in the scrollport — the browser drives it natively, off the main thread, with no scroll event listeners at all:

```css
.project-card {
  animation: fade-slide-up linear;
  animation-timeline: view();
  animation-range: entry 0% cover 40%;
}

@keyframes fade-slide-up {
  from { opacity: 0; transform: translateY(24px); }
  to   { opacity: 1; transform: translateY(0); }
}
```

`animation-range: entry 0% cover 40%` means: start the animation the instant the element begins entering the viewport, and finish it once it's 40% scrolled into view. No JS, no scroll listener, no layout thrashing.

### `@starting-style` — animating an element's *entrance*, including `display: none` → visible

CSS transitions have historically been unable to animate an element appearing for the first time (e.g., from `display: none` to `display: block`, or a newly-inserted popover) because there was no "before" state to transition *from*. `@starting-style` defines that before-state explicitly:

```css
.toast {
  transition: opacity 0.3s, transform 0.3s;

  @starting-style {
    opacity: 0;
    transform: translateY(-10px);
  }
}
```

The moment `.toast` is added to the DOM (or becomes visible via the popover API / `display` changes handled with `transition-behavior: allow-discrete`), the browser now knows to animate *from* the starting style *to* the element's normal resolved style — a true CSS-only entrance transition.

### Respecting motion preferences — never optional

Every animation or transition we add in this part must be wrapped so it's disabled for users who've told their OS they get motion sickness or vestibular discomfort from movement:

```css
@media (prefers-reduced-motion: reduce) {
  .project-card {
    animation: none;
  }
  * {
    transition-duration: 0.001ms !important;
  }
}
```

This isn't a nice-to-have — treat it as a hard requirement any time `animation` or `transition` appears in a stylesheet.

## 2. Implementation: Bringing NovaFolio to Life

### Step 1 — Scroll-reveal the project cards

```css
@layer components {
  .project-card {
    animation: card-reveal linear both;
    animation-timeline: view();
    animation-range: entry 0% cover 35%;
  }

  @keyframes card-reveal {
    from {
      opacity: 0;
      transform: translateY(32px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .project-card {
      animation: none;
    }
  }
}
```

Each project card now fades and slides into place purely as a function of scroll position, entirely driven by the compositor thread. Scroll performance is unaffected because there is no JavaScript polling scroll position at all.

### Step 2 — `:has()` for a "featured" project state

Add an optional badge to a project card's markup:

```html
<article class="project-card">
  <span class="project-card__badge project-card__badge--featured">Featured</span>
  <h3 class="card__title">NovaFolio</h3>
  <p class="card__description">A framework-free personal portfolio.</p>
</article>
```

```css
.project-card:has(.project-card__badge--featured) {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px var(--color-primary);
}
```

No modifier class needed on `.project-card` itself — its own appearance reacts automatically to the presence of the badge inside it. Remove the badge, the highlight disappears; add it back, it returns. This keeps the "is this featured" decision entirely in the HTML content layer, with CSS just reacting — a clean separation of concerns.

### Step 3 — `:has()` for zero-JS form validation states

NovaFolio's contact form gets real-time visual feedback with no JavaScript:

```html
<div class="form-field">
  <label for="email">Email</label>
  <input type="email" id="email" required>
</div>
```

```css
.form-field:has(input:invalid:not(:placeholder-shown)) {
  --field-color: #dc2626;
}

.form-field:has(input:valid:not(:placeholder-shown)) {
  --field-color: #16a34a;
}

.form-field label {
  color: var(--field-color, var(--color-text));
}

.form-field input {
  border: 1px solid var(--field-color, var(--color-border));
}
```

`:not(:placeholder-shown)` is the key trick here — it prevents the invalid state from showing red before the user has typed anything (an empty `required` field is technically `:invalid`, but we don't want to shame the user before they've had a chance to type).

### Step 4 — Pure CSS transitions on interactive elements

```css
.button {
  transition: background-color 0.2s ease, transform 0.15s ease;
}

.button:active {
  transform: scale(0.97);
}

.project-card {
  transition: box-shadow 0.2s ease, transform 0.2s ease;
}

.project-card:hover {
  box-shadow: 0 8px 24px rgb(0 0 0 / 0.08);
  transform: translateY(-4px);
}
```

Small, tasteful, and cheap transitions like these are what separate a page that feels "static and dead" from one that feels considered — and they cost nothing in JS bundle size because there is no JS bundle.

### Step 5 — An entrance transition for the mobile nav with `@starting-style`

Assume a `
```

```css
.mobile-nav[open] .mobile-nav__list {
  transition: opacity 0.2s ease, transform 0.2s ease;
  transition-behavior: allow-discrete;

  @starting-style {
    opacity: 0;
    transform: translateY(-8px);
  }
}
```

`transition-behavior: allow-discrete` is required to let a transition run across a `display: none <-> block`-style jump (which `<details>`'s open/closed content technically triggers) — without it, discrete properties snap instantly rather than transitioning. Combined with `@starting-style`, the menu now genuinely fades and slides open, and the whole interaction — state, toggle, and animation — required zero JavaScript.

### Step 6 — Wrapping it all in a reduced-motion guard

```css
@layer utilities {
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 0.001ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.001ms !important;
      scroll-behavior: auto !important;
    }
  }
}
```

Placed in the `utilities` layer (the last, highest-priority layer from Part 4's cascade order), this single block guarantees it overrides every specific animation/transition declared anywhere else in the codebase, for any user who has requested reduced motion.

## 3. Exercise Challenge

Using `:has()`, style the `.stat-card` elements so that any stat card whose `.stat-card__number` text content represents a negative trend (assume a `<span class="stat-card__trend stat-card__trend--down">` element is present inside it) gets a subtle red left border, while a `.stat-card__trend--up` gets a green one — with no JavaScript and no modifier class added directly to `.stat-card` itself.

## 4. Solution & Explanation

```html
<article class="stat-card">
  <p class="stat-card__number">48</p>
  <p class="stat-card__label">Projects shipped</p>
  <span class="stat-card__trend stat-card__trend--up">+12% this month</span>
</article>
```

```css
.stat-card {
  border-left: 4px solid transparent;
}

.stat-card:has(.stat-card__trend--up) {
  border-left-color: #16a34a;
}

.stat-card:has(.stat-card__trend--down) {
  border-left-color: #dc2626;
}
```

This is the same pattern as the featured-project badge in Step 2: the parent (`.stat-card`) never needs a corresponding modifier class computed and injected by JavaScript to know its own state — the *content* (a child element's presence) *is* the state, and `:has()` lets CSS read it directly. This is a meaningful architectural shift: state that used to require JS-computed class names on parents can now often live purely in semantic, content-driven HTML, with CSS doing all the reactive styling work.

---

This completes the core 5-part series. Continue to **Appendix A (Codebase Reference)**, **Appendix B (CSS Cheat Sheet)**, and **Appendix C (Deployment Checklist)** to finish setting up and shipping NovaFolio.
