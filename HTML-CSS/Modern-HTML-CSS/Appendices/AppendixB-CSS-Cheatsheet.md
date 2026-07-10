# Appendix B: CSS Cheat Sheet

Quick-reference tables for the concepts covered across all 5 parts. Bookmark this one.

## Grid vs. Flexbox — which one?

| Scenario | Use |
|---|---|
| A row of nav links | Flexbox |
| A button group | Flexbox |
| Centering one item (horizontally + vertically) | Flexbox (`justify-content: center; align-items: center;`) |
| Card internals (image, title, text, button stacked) | Flexbox |
| Full page shell (header/main/footer) | Grid |
| A dashboard with a sidebar | Grid |
| An image/card gallery with equal-sized cells | Grid |
| Overlapping elements (badge on a card corner) | Grid (`grid-template-areas` with overlapping placement, or `position`) |
| One-dimensional space distribution | Flexbox |
| Two-dimensional space distribution (rows AND columns) | Grid |

Rule of thumb used throughout this series: **Grid for the shell and card grids, Flexbox for what's inside each component.**

## Flexbox property quick reference

| Property | Goes on | Values worth knowing |
|---|---|---|
| `display: flex` | Parent | Establishes flex context |
| `flex-direction` | Parent | `row` (default), `column`, `row-reverse` |
| `justify-content` | Parent | `flex-start`, `center`, `space-between`, `space-around` |
| `align-items` | Parent | `stretch` (default), `center`, `flex-start`, `flex-end` |
| `flex-wrap` | Parent | `nowrap` (default), `wrap` |
| `gap` | Parent | Any length; replaces margin hacks between children |
| `flex` | Child | Shorthand for `flex-grow flex-shrink flex-basis`, e.g. `flex: 1` |
| `align-self` | Child | Overrides parent's `align-items` for one child |

## Grid property quick reference

| Property | Goes on | Values worth knowing |
|---|---|---|
| `display: grid` | Parent | Establishes grid context |
| `grid-template-columns` | Parent | `1fr 1fr`, `repeat(3, 1fr)`, `repeat(auto-fit, minmax(240px, 1fr))` |
| `grid-template-rows` | Parent | Same syntax as columns, for the vertical axis |
| `grid-template-areas` | Parent | Named ASCII-art layout regions |
| `gap` | Parent | Space between both rows and columns |
| `grid-column` / `grid-row` | Child | `span 2`, or explicit line numbers `1 / 3` |
| `grid-area` | Child | Matches a name defined in `grid-template-areas` |
| `place-items` | Parent | Shorthand for `align-items` + `justify-items` |

## Unit reference

| Unit | Relative to | Best use case |
|---|---|---|
| `px` | Nothing (absolute) | Hairline borders (`1px`) — avoid for type |
| `rem` | Root `html` font-size | Font sizes, spacing — respects user zoom/accessibility settings |
| `em` | Current element's font-size | Padding/spacing that should scale with local text size |
| `%` | Parent's matching dimension | Fluid widths inside a container |
| `vw` / `vh` | 1% of viewport width/height | Full-bleed sections on desktop; risky on mobile |
| `svh` / `svw` | Smallest possible viewport (chrome visible) | Guaranteed-safe minimum height/width on mobile |
| `lvh` / `lvw` | Largest possible viewport (chrome hidden) | Maximum possible height/width on mobile |
| `dvh` / `dvw` | Dynamic — recalculates live as browser chrome shows/hides | Mobile hero sections that must exactly fill visible space |
| `fr` | Grid: a fraction of remaining free space | Proportional Grid column/row sizing |
| `ch` | Width of the `0` character in current font | Constraining paragraph line-length for readability |

## `clamp()` quick pattern

```css
font-size: clamp(MIN, PREFERRED, MAX);
/* e.g. */
font-size: clamp(1rem, 2vw + 0.5rem, 2rem);
```

Reads as: never below MIN, never above MAX, fluid in between based on the PREFERRED expression.

## BEM naming quick reference

| Pattern | Meaning | Example |
|---|---|---|
| `.block` | Standalone reusable component | `.card` |
| `.block__element` | A part of that block | `.card__title` |
| `.block--modifier` | A variant/state of the block | `.card--featured` |
| `.block__element--modifier` | A variant/state of an element | `.card__title--large` |

## Cascade Layers quick pattern

```css
@layer reset, tokens, base, layout, components, utilities;
```

Layers listed first lose to layers listed later, **regardless of specificity or source order** — this line should be the very first thing in your entry stylesheet.

## Modern selector quick reference

| Selector | Matches |
|---|---|
| `:has(x)` | An element that contains `x` anywhere inside it |
| `:not(x)` | An element that does NOT match `x` |
| `:is(a, b)` | Shorthand for grouping — matches either `a` or `b` |
| `:where(a, b)` | Same as `:is()` but always zero specificity |
| `input:invalid` | A form input failing its validation constraints |
| `:placeholder-shown` | An input currently showing its placeholder (i.e., empty) |
| `::before` / `::after` | Generated pseudo-content |

## Animation/transition quick reference

| Feature | Purpose |
|---|---|
| `transition: prop duration ease;` | Animate a property change between two known states |
| `@keyframes name { ... }` | Define a multi-step animation sequence |
| `animation: name duration ...;` | Apply a keyframe animation |
| `animation-timeline: view();` | Tie animation progress to scroll position within the viewport |
| `animation-range: entry 0% cover 40%;` | Define which portion of scroll maps to the animation |
| `@starting-style { ... }` | Define the "before" state for an element's first-ever transition |
| `transition-behavior: allow-discrete;` | Allow transitions across discrete property jumps like `display` |
| `@media (prefers-reduced-motion: reduce)` | Always wrap non-essential animation/transition in this guard |

## Accessibility quick reference

| Technique | Why |
|---|---|
| `.visually-hidden` class | Hide content visually but keep it in the accessibility tree |
| Skip link (`<a href="#main-content">`) | Let keyboard users bypass repeated nav on every page |
| `aria-label` on multiple `nav` elements | Distinguish "navigation, navigation, navigation" for screen readers |
| `aria-labelledby` on `section` | Tie a section to its heading explicitly for the accessibility tree |
| One `<h1>` per page, no skipped heading levels | Preserve a logical outline for screen reader navigation |
| `alt` text on every meaningful `<img>` | Describe images for non-visual users; empty `alt=""` for purely decorative images |

---

Next: **Appendix C — Deployment Checklist**, the final piece — shipping NovaFolio to GitHub Pages or Vercel for free.
