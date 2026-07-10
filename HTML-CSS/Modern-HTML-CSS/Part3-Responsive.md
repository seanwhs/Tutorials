# Part 3: Responsive Design

## 1. Concept Explanation

### Mobile-first, not desktop-first

A mobile-first stylesheet writes the base (unqualified) CSS rules for the *smallest* viewport, then uses `min-width` media queries to progressively enhance the layout as space becomes available:

```css
/* base styles = mobile */
.project-grid {
  grid-template-columns: 1fr;
}

/* enhance for wider viewports */
@media (min-width: 768px) {
  .project-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
```

This is the opposite of writing full desktop styles and then cramming them into a phone screen with `max-width` overrides — which tends to produce fighting, overridden rules and bloated specificity wars. Mobile-first keeps the cascade additive: each breakpoint only adds what's different, never undoes a previous rule.

### Units that matter

| Unit | What it means | When to use it |
|---|---|---|
| `px` | Absolute pixels | Rarely for typography; fine for hairline borders (`1px`) |
| `rem` | Relative to the root `html` font-size (default 16px) | Font sizes, spacing — respects user's browser zoom/font settings |
| `em` | Relative to the *current element's* font-size | Spacing that should scale with local text size (e.g. padding inside a button) |
| `%` | Relative to the parent's corresponding dimension | Fluid widths within a container |
| `vw` / `vh` | 1% of the viewport's width/height | Full-bleed sections, but unreliable on mobile (see below) |
| `svh` / `lvh` / `dvh` | Small/Large/Dynamic viewport height | Fixes the mobile browser chrome problem (see below) |
| `svw` / `lvw` / `dvw` | Small/Large/Dynamic viewport width | Same idea, horizontal axis |

**Why `rem` for almost everything?** If a user has increased their browser's default font size for readability, `rem`-based layouts scale with that preference. `px`-based type stays fixed regardless of the user's accessibility settings — a real usability failure for low-vision users.

**The `vh` mobile problem, and why `dvh` exists:** On mobile browsers, the address bar and toolbar show and hide as you scroll, physically changing the visible viewport height. A `100vh` hero calculated against the *largest* possible viewport ends up taller than the *actual* visible area once the browser chrome appears, causing content to look cut off or requiring an extra scroll. `dvh` (**d**ynamic viewport height) recalculates live as the browser chrome shows/hides, so `height: 100dvh` always matches exactly what's currently visible. Use `svh` (small, chrome always shown) if you want a guaranteed-safe minimum instead.

### Fluid typography with `clamp()`

`clamp(MIN, PREFERRED, MAX)` lets a value scale smoothly between a floor and a ceiling, using a fluid unit like `vw` for the middle argument:

```css
h1 {
  font-size: clamp(2rem, 5vw + 1rem, 3.5rem);
}
```

Read this as: "never smaller than 2rem, never larger than 3.5rem, and in between, scale fluidly based on viewport width." This replaces the old pattern of five separate `font-size` overrides across five different media queries with a single line that scales continuously — no jumps, no breakpoints needed for type size specifically.

### Media queries beyond width

Two more you'll use constantly:

```css
/* Respect users who've disabled motion */
@media (prefers-reduced-motion: reduce) {
  * { animation: none !important; transition: none !important; }
}

/* Respect users who've set a system-wide dark mode preference */
@media (prefers-color-scheme: dark) {
  :root { --bg: #111; --text: #eee; }
}
```

We'll build out the dark mode variables fully with a manual toggle in Part 4; `prefers-color-scheme` is the automatic, zero-JS baseline every themed site should have regardless.

## 2. Implementation: Making NovaFolio Fluid

### Step 1 — Fluid type scale (`css/typography.css`)

```css
:root {
  --step-0: clamp(1rem, 0.34vw + 0.91rem, 1.19rem);
  --step-1: clamp(1.2rem, 0.61vw + 1.05rem, 1.58rem);
  --step-2: clamp(1.44rem, 0.99vw + 1.21rem, 2.11rem);
  --step-3: clamp(1.73rem, 1.49vw + 1.38rem, 2.81rem);
  --step-4: clamp(2.07rem, 2.17vw + 1.56rem, 3.75rem);
}

body   { font-size: var(--step-0); }
h3     { font-size: var(--step-2); }
h2     { font-size: var(--step-3); }
h1     { font-size: var(--step-4); }
```

This is a **modular type scale** expressed entirely in `clamp()` steps — each heading level scales fluidly and proportionally, with no breakpoint jumps. We're using CSS Custom Properties here as a preview of Part 4, where theming and variables get their own deep dive.

### Step 2 — Mobile-first main grid

Recall Part 2's two-column dashboard grid. On a phone, two columns of a sidebar layout is unusable — so mobile is single-column by default, and we enhance upward:

```css
main {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1.5rem;
  padding: 1.25rem;
}

.hero, #stats, #projects, #activity, #about {
  grid-column: 1;
}

@media (min-width: 768px) {
  main {
    grid-template-columns: 2fr 1fr;
    gap: 2rem;
    padding: 2rem;
    max-width: 1200px;
    margin-inline: auto;
  }

  #about {
    grid-column: 2;
    grid-row: 1 / 4;
  }
}
```

Everything below 768px gets one honest column, top to bottom, in source order (which also happens to be the most accessible reading order). At 768px and above, we introduce the sidebar layout from Part 2.

### Step 3 — Responsive stat cards and project grid

```css
#stats {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

@media (min-width: 500px) {
  #stats {
    flex-direction: row;
  }
}

.project-grid {
  grid-template-columns: 1fr;
}

@media (min-width: 500px) {
  .project-grid {
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  }
}
```

Note that `repeat(auto-fit, minmax(...))` from Part 2 is *already* fairly responsive on its own — but wrapping it behind a `min-width` guard prevents a single very-narrow phone from squeezing two overly-cramped 240px-minimum columns side-by-side before there's room to do so comfortably.

### Step 4 — The hero, with a `dvh`-aware height and fluid padding

```css
.hero {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 1rem;
  min-height: 60svh;
  padding: clamp(1.5rem, 5vw, 4rem);
  text-align: center;
}

@media (min-width: 768px) {
  .hero {
    text-align: left;
  }
}
```

`min-height: 60svh` guarantees the hero fills a comfortable majority of the *guaranteed-visible* viewport even before the mobile browser chrome collapses — safer than `60vh`, which can be taller than what's actually visible on first paint. `padding: clamp(1.5rem, 5vw, 4rem)` gives the hero breathing room that scales with screen size without a single media query.

### Step 5 — Responsive navigation (stacking on mobile)

```css
.site-header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem clamp(1rem, 4vw, 2rem);
}

.primary-nav ul {
  display: flex;
  flex-wrap: wrap;
  gap: clamp(0.75rem, 2vw, 1.5rem);
  list-style: none;
}
```

`flex-wrap` on both the header and the nav list means that on very narrow phones, the nav links simply wrap onto a second line rather than overflowing or shrinking illegibly — a lightweight responsive behavior with zero JavaScript and zero hamburger menu required for this project's scope. `clamp()` inside `gap` and `padding` is a nice trick: spacing itself can be fluid, not just font sizes.

### Step 6 — Responsive images

```css
.project-card img {
  width: 100%;
  aspect-ratio: 16 / 9;
  object-fit: cover;
  border-radius: 0.375rem;
}
```

`aspect-ratio` reserves the correct box size before the image even loads (preventing layout shift), and `object-fit: cover` crops intelligently to fill that box regardless of the source image's native dimensions — critical when project cards render arbitrary screenshots of varying sizes.

## 3. Exercise Challenge

The `.stat-card__number` currently uses a fixed `font-size: 2rem` from Part 2. Convert it to a fluid `clamp()` value that stays readable on a small phone but doesn't look oversized on a 4K monitor. Then, add a `@media (min-width: 500px)` rule that switches `#stats` from a wrapped column layout into an even 3-column Grid instead of Flexbox, now that there's guaranteed horizontal room for exactly three cards.

## 4. Solution & Explanation

```css
.stat-card__number {
  font-size: clamp(1.5rem, 4vw, 2.5rem);
}

#stats {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

@media (min-width: 500px) {
  #stats {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1rem;
  }
}
```

Switching `display` itself inside the media query (from `flex` to `grid`) is completely valid and often the cleanest option: below 500px we want items in a simple stacked column (Flexbox's specialty), and above it we want three *guaranteed-equal* columns regardless of content length (Grid's specialty, via `repeat(3, 1fr)`) — rather than fighting Flexbox's `flex: 1` sizing quirks with variable-length card content. Choosing the right layout tool per breakpoint, not just resizing the same one, is the mobile-first mindset applied fully.

---

Next: **Part 4 — CSS Architecture**, where we formalize BEM, build a full CSS custom-property design-token system, and organize these files into a maintainable module structure.
