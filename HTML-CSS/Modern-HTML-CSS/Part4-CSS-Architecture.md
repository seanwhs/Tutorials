# Part 4: CSS Architecture

## 1. Concept Explanation

### BEM: naming as documentation

BEM (**B**lock, **E**lement, **M**odifier) is a naming convention that makes a class name self-describing, so you can understand a component's structure by reading its class list alone — no need to open the HTML and the CSS side by side to figure out relationships.

```
.block { }
.block__element { }
.block--modifier { }
.block__element--modifier { }
```

- **Block** — a standalone, reusable component: `.card`, `.button`, `.project-card`.
- **Element** — a part of that block that has no standalone meaning outside it: `.project-card__title`, `.project-card__tag`.
- **Modifier** — a variant or state of a block or element: `.button--primary`, `.project-card--featured`.

Why this matters architecturally: BEM class names are **flat by design**. `.project-card__title` needs no parent selector (`.project-card .title`) to make sense or to apply correctly — it's globally unique and low-specificity on its own. This directly prevents two classic CSS problems:

1. **Specificity wars** — nested selectors like `.sidebar .card .title` become increasingly hard to override without `!important`. A flat `.card__title` is always just one class, one specificity point, everywhere it's used.
2. **Accidental context coupling** — `.sidebar .card { }` breaks the moment you reuse `.card` outside the sidebar. `.card { }` alone never does.

### Locality of Behavior via file structure

BEM handles *naming*. The other half of maintainability is *file organization* — each block should have exactly one file that owns its styles, named to match:

```
css/
  base/
    reset.css
    tokens.css
    typography.css
  layout/
    page-shell.css
  components/
    button.css
    card.css
    stat-card.css
    project-card.css
    site-header.css
    site-footer.css
```

When you need to change how `.button--primary` looks, there is exactly one file to open: `components/button.css`. No grepping across a 2,000-line `style.css` monolith. This is Locality of Behavior applied to CSS: a component's full presentation logic lives in one predictable place.

### Cascade Layers: taming import order

Modern CSS has a native tool for controlling which rules win, independent of source order or specificity tricks: `@layer`.

```css
@layer reset, tokens, base, layout, components, utilities;
```

Declaring this order once up front means **layer order always wins over source order and, within reason, over specificity** — a component rule in the `components` layer always beats a base rule in the `base` layer, even if the base file is imported last and would otherwise win via normal cascade rules. This eliminates an entire category of "why is this file's CSS not applying" debugging sessions.

```css
@layer reset {
  * { margin: 0; padding: 0; box-sizing: border-box; }
}

@layer components {
  .button { padding: 0.75rem 1.5rem; }
}
```

### CSS Custom Properties as design tokens

Variables (Custom Properties) turn magic numbers and colors into named, reusable, themeable **tokens** — the foundation of any scalable design system:

```css
:root {
  --color-primary: #2563eb;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --radius-md: 0.5rem;
}
```

Unlike Sass variables, Custom Properties are **live in the browser** — they can be read and changed at runtime, inherited down the DOM tree, and overridden at any scope (not just globally). This is exactly what makes a light/dark theme toggle possible with zero JavaScript logic beyond flipping one attribute.

## 2. Implementation: Refactoring NovaFolio's Architecture

### Step 1 — The design tokens file (`css/base/tokens.css`)

```css
@layer tokens {
  :root {
    /* Color */
    --color-primary: #2563eb;
    --color-primary-hover: #1d4ed8;
    --color-bg: #ffffff;
    --color-surface: #f8f9fa;
    --color-text: #1a1a1a;
    --color-text-muted: #6b7280;
    --color-border: #e2e2e2;

    /* Spacing scale */
    --space-xs: 0.25rem;
    --space-sm: 0.5rem;
    --space-md: 1rem;
    --space-lg: 1.5rem;
    --space-xl: 2rem;
    --space-2xl: 3rem;

    /* Radius */
    --radius-sm: 0.25rem;
    --radius-md: 0.5rem;

    /* Type scale (from Part 3) */
    --step-0: clamp(1rem, 0.34vw + 0.91rem, 1.19rem);
    --step-1: clamp(1.2rem, 0.61vw + 1.05rem, 1.58rem);
    --step-2: clamp(1.44rem, 0.99vw + 1.21rem, 2.11rem);
    --step-3: clamp(1.73rem, 1.49vw + 1.38rem, 2.81rem);
    --step-4: clamp(2.07rem, 2.17vw + 1.56rem, 3.75rem);
  }

  [data-theme="dark"] {
    --color-bg: #111318;
    --color-surface: #1c1f26;
    --color-text: #f1f1f1;
    --color-text-muted: #9ca3af;
    --color-border: #2a2d35;
  }
}
```

Every hardcoded color and spacing value from Parts 1-3 gets replaced by a reference to one of these tokens. The `[data-theme="dark"]` selector overrides just the color tokens — every component that already uses `var(--color-bg)` etc. re-themes automatically, with zero changes to component files.

### Step 2 — The theme toggle (pure HTML + CSS, no JS logic required for styling)

```html
<button class="theme-toggle" onclick="document.documentElement.toggleAttribute('data-theme') ? document.documentElement.setAttribute('data-theme','dark') : null">
  Toggle theme
</button>
```

For a genuinely zero-JavaScript-file approach appropriate to this series' scope, a `<details>`-based or checkbox-based CSS-only toggle also works, but the single-attribute-flip pattern above is the simplest to reason about and is the pattern real design systems use (React apps just call `setAttribute` from a click handler instead of inline `onclick`). The architectural point stands regardless of toggle mechanism: **CSS never needs to know how the attribute got set** — it only reacts to `[data-theme="dark"]` being present. That's a clean separation between behavior (JS, out of scope) and presentation (CSS, our layer).

### Step 3 — Declare cascade layers (`css/main.css`, the single entry point)

```css
@layer reset, tokens, base, layout, components, utilities;

@import url("base/reset.css") layer(reset);
@import url("base/tokens.css") layer(tokens);
@import url("base/typography.css") layer(base);
@import url("layout/page-shell.css") layer(layout);
@import url("components/button.css") layer(components);
@import url("components/card.css") layer(components);
@import url("components/site-header.css") layer(components);
@import url("components/site-footer.css") layer(components);
@import url("utilities.css") layer(utilities);
```

Now `index.html` links a **single** stylesheet:

```html
<link rel="stylesheet" href="css/main.css">
```

One `<link>` tag, one clear entry point, but the actual styles stay modular across many small files — the `@import ... layer(...)` mechanism gives us file-per-component organization *and* predictable cascade ordering simultaneously, satisfying both Locality of Behavior and "no specificity surprises."

### Step 4 — Rewriting a component with tokens + BEM (`components/card.css`)

```css
.card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: var(--space-lg);
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
}

.card--featured {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px var(--color-primary);
}

.card__title {
  font-size: var(--step-2);
  color: var(--color-text);
}

.card__description {
  color: var(--color-text-muted);
}
```

Applied to markup:

```html
<article class="card card--featured">
  <h3 class="card__title">NovaFolio</h3>
  <p class="card__description">A framework-free personal portfolio.</p>
</article>
```

Compare this to Part 2's `.project-card` — same visual result, but now every color and spacing value is a token (instantly themeable) and the naming makes the block/element/modifier relationship explicit at a glance.

### Step 5 — Utility classes for one-off tweaks (`css/utilities.css`)

```css
@layer utilities {
  .u-mt-lg { margin-top: var(--space-lg); }
  .u-text-center { text-align: center; }
  .u-flex-center {
    display: flex;
    align-items: center;
    justify-content: center;
  }
}
```

A small, deliberately restrained set of utilities for genuinely one-off layout tweaks — not a full utility-first framework (that's a different series). Because `utilities` is declared last in the layer order, a utility class reliably overrides a component's default even with a lower specificity selector, without ever reaching for `!important`.

## 3. Exercise Challenge

Refactor the `.button` component (from Part 2) to fully match this part's architecture:

1. Move all hardcoded colors and spacing to tokens from `tokens.css`.
2. Add a `.button--secondary` modifier using `--color-surface` and a `--color-border` outline instead of a solid primary fill.
3. Ensure `.button` styles live in their own `components/button.css` file and are pulled into `main.css` via the `components` layer.
4. Confirm that switching `[data-theme="dark"]` on `<html>` re-themes both button variants without touching `button.css` at all.

## 4. Solution & Explanation

```css
/* components/button.css */
.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-sm) var(--space-lg);
  border-radius: var(--radius-sm);
  text-decoration: none;
  font-weight: 600;
  border: 2px solid transparent;
}

.button--primary {
  background: var(--color-primary);
  color: white;
}

.button--primary:hover {
  background: var(--color-primary-hover);
}

.button--secondary {
  background: var(--color-surface);
  color: var(--color-text);
  border-color: var(--color-border);
}

.button--secondary:hover {
  border-color: var(--color-primary);
}
```

Because every value here is a token reference rather than a literal, flipping `data-theme="dark"` on `<html>` changes `--color-surface`, `--color-border`, and `--color-text` at the root — and `button.css` never has to know dark mode exists. This is the entire payoff of the architecture: **components declare intent ("I am the surface color"), the token layer declares the actual value, and theming becomes a token-layer-only concern.** The button file you wrote once in Part 2 now works correctly in both themes without a single edit.

---

Next: **Part 5 — Advanced Interactions**, where we add `:has()`, scroll-driven animations, and pure-CSS transitions to bring NovaFolio to life without a line of JavaScript.
