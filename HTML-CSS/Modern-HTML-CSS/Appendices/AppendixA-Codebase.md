# Appendix A: Codebase Reference

This appendix consolidates the full NovaFolio project structure as it stands after completing Parts 1-5, so you have one canonical reference instead of piecing files together from five separate notes.

## Full File Tree

```
novafolio/
├── index.html
├── css/
│   ├── main.css                 # single entry point, declares @layer order + imports
│   ├── base/
│   │   ├── reset.css            # box-sizing, margin/padding reset, visually-hidden
│   │   ├── tokens.css           # color/spacing/radius/type-scale custom properties + dark theme
│   │   └── typography.css       # heading font-size assignments using type-scale tokens
│   ├── layout/
│   │   └── page-shell.css       # body grid-template-areas, main dashboard grid
│   ├── components/
│   │   ├── button.css           # .button, .button--primary, .button--secondary
│   │   ├── card.css             # generic .card block + BEM elements/modifiers
│   │   ├── stat-card.css        # .stat-card + :has() trend-based border states
│   │   ├── project-card.css     # .project-card + scroll-reveal animation + :has() featured state
│   │   ├── site-header.css      # header flex layout + primary-nav
│   │   ├── site-footer.css      # footer flex layout + social-links
│   │   ├── form-field.css       # .form-field + :has() validation states
│   │   └── mobile-nav.css       # <details>-based disclosure + @starting-style transition
│   └── utilities.css            # small utility classes + prefers-reduced-motion override (last layer)
└── assets/
    ├── images/
    └── favicon.ico
```

## Setup Guide (from empty folder to running project)

### 1. Create the folder structure

```
mkdir -p novafolio/css/base novafolio/css/layout novafolio/css/components novafolio/assets/images
cd novafolio
touch index.html
touch css/main.css css/utilities.css
touch css/base/reset.css css/base/tokens.css css/base/typography.css
touch css/layout/page-shell.css
touch css/components/button.css css/components/card.css css/components/stat-card.css css/components/project-card.css css/components/site-header.css css/components/site-footer.css css/components/form-field.css css/components/mobile-nav.css
```

### 2. Wire up `index.html`

Only one stylesheet is ever linked directly from HTML — the rest is composed via `@import ... layer(...)` inside `main.css`, as established in Part 4:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>NovaFolio — Alex Chen, Front-End Engineer</title>
  <meta name="description" content="Personal portfolio and project dashboard for Alex Chen, front-end engineer.">
  <link rel="icon" href="assets/favicon.ico">
  <link rel="stylesheet" href="css/main.css">
</head>
<body>
  <!-- Part 1 skeleton: skip-link, header, main, footer -->
</body>
</html>
```

### 3. Populate `main.css` with the layer declaration and imports

```css
@layer reset, tokens, base, layout, components, utilities;

@import url("base/reset.css") layer(reset);
@import url("base/tokens.css") layer(tokens);
@import url("base/typography.css") layer(base);
@import url("layout/page-shell.css") layer(layout);
@import url("components/button.css") layer(components);
@import url("components/card.css") layer(components);
@import url("components/stat-card.css") layer(components);
@import url("components/project-card.css") layer(components);
@import url("components/site-header.css") layer(components);
@import url("components/site-footer.css") layer(components);
@import url("components/form-field.css") layer(components);
@import url("components/mobile-nav.css") layer(components);
@import url("utilities.css") layer(utilities);
```

### 4. Serve it locally (no build tools required)

Any of these free options work — pick whichever is already on your machine:

```
# Python (built into macOS/Linux, free installer on Windows)
python3 -m http.server 8000

# Node's http-server (if Node is already installed)
npx http-server -p 8000

# VS Code
# Install the free "Live Server" extension, then right-click index.html -> "Open with Live Server"
```

Then visit `http://localhost:8000` in your browser. Opening `index.html` directly via `file://` also works for this project since there are zero build steps or absolute-path assets, but a local server more accurately mirrors production behavior (relative paths, correct MIME types, no `file://`-specific security restrictions on things like `fetch`).

### 5. File-naming and ownership conventions used throughout this series

- One file per BEM block inside `components/` — the file name matches the block's class name (`project-card.css` owns `.project-card` and all its elements/modifiers).
- `base/` owns anything that isn't tied to one visual component: reset rules, design tokens, and global typography defaults.
- `layout/` owns page-shell-level Grid/Flexbox rules — anything positioning entire landmark regions relative to each other, not the internals of a single component.
- `utilities.css` stays intentionally small — a handful of one-off helper classes and the global `prefers-reduced-motion` override. If a utility class starts being used dozens of times for the same combination of properties, that's a signal it should graduate into a proper named component instead.

This structure is what makes the whole series' Locality of Behavior claim concrete: for any visual element on the page, there's exactly one predictably-named file responsible for its styling.

---

Next: **Appendix B — CSS Cheat Sheet**, a quick-reference for Grid vs. Flexbox, units, BEM, cascade layers, modern selectors, and animation/accessibility patterns.
