# Part 1: The Semantic Document

## 1. Concept Explanation

### Why semantics matter

Before writing any CSS, we get the HTML right. This is the "structure" layer of Clean Architecture: it should describe what things ARE, not how they look. A `<div>` tells a browser, a screen reader, and a search crawler nothing about intent. A `<nav>`, `<article>`, or `<aside>` tells all three exactly what role that content plays.

Three audiences depend on correct semantics:

1. **Screen reader users** — assistive tech builds a navigable outline from landmark elements (`header`, `nav`, `main`, `aside`, `footer`) and heading levels. Users jump straight to "main content" the way sighted users' eyes jump to a nav bar.
2. **Search engines** — crawlers weight content inside `article` and proper heading hierarchies more meaningfully than `div` soup. Free, zero-effort SEO.
3. **Future developers** — `<section aria-labelledby="projects-heading">` documents intent directly in markup. That's Locality of Behavior applied to structure.

### The landmark elements

| Element | Role | Notes |
|---|---|---|
| `header` | Introductory content for page/section | One site header; can repeat inside articles/sections |
| `nav` | Major navigation blocks | Only primary navigation, not every link list |
| `main` | The dominant, unique content | Exactly one per page, never nested in article/aside/nav |
| `section` | Thematic grouping, usually with a heading | No heading needed? Use a `div` instead |
| `article` | Self-contained, independently distributable content | Blog posts, project cards, comments, testimonials |
| `aside` | Tangentially related content | Sidebars, pull quotes, related links |
| `footer` | Closing content for page/section | Can appear inside `article` for metadata too |

Litmus test: "If I ripped this element out onto its own page, would it still make sense?" Yes → `article`. Organizing siblings thematically → `section`. Supplementary → `aside`.

### Common pitfalls

- **Div soup** — wrapping everything in `<div class="...">` out of habit. Semantics first; classes are styling hooks, not structure.
- **`section` without a heading** — implies "distinct part of the document outline." No heading, no outline entry → use `div`.
- **Multiple `h1`s** — one per page. Don't skip heading levels for styling; control size with CSS.
- **`nav` overuse** — reserve for real navigation menus (primary, footer, breadcrumbs, pagination).
- **Nested `main`** — never inside `article`, `aside`, `nav`, `header`, or `footer`.

## 2. Implementation: Building NovaFolio's Skeleton

No CSS yet — Part 1 is pure structure. By the end, NovaFolio is a fully navigable, screen-reader-friendly, unstyled document.

### Step 1 — Project folder

```
novafolio/
  index.html
  /css
  /assets
```

### Step 2 — Boilerplate

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>NovaFolio — Alex Chen, Front-End Engineer</title>
  <meta name="description" content="Personal portfolio and project dashboard for Alex Chen, front-end engineer.">
</head>
<body>
</body>
</html>
```

`charset` must be first in `head` so the browser decodes text correctly from byte one. The viewport tag is required for any responsive behavior later. `meta description` is what search engines usually show under your title in results.

### Step 3 — Landmarks

```html
<body>
  <a class="skip-link" href="#main-content">Skip to main content</a>

  <header class="site-header"></header>

  <main id="main-content"></main>

  <footer class="site-footer"></footer>
</body>
```

The skip link is a real accessibility requirement: without it, keyboard-only users must Tab through the entire nav on every page load just to reach content.

### Step 4 — Header and navigation

```html
<header class="site-header">
  <a class="logo" href="/">Nova<span>Folio</span></a>

  <nav class="primary-nav" aria-label="Primary">
    <ul>
      <li><a href="#projects">Projects</a></li>
      <li><a href="#activity">Activity</a></li>
      <li><a href="#about">About</a></li>
      <li><a href="#contact">Contact</a></li>
    </ul>
  </nav>
</header>
```

`aria-label="Primary"` matters because pages often have multiple `nav` elements. Without labels, screen readers just announce "navigation" repeatedly with no way to tell them apart.

### Step 5 — Hero

```html
<section class="hero" aria-labelledby="hero-heading">
  <h1 id="hero-heading">Hi, I'm Alex Chen.</h1>
  <p class="hero__tagline">I build fast, accessible, framework-free front ends.</p>
  <a class="button button--primary" href="#projects">View my projects</a>
</section>
```

### Step 6 — Stats section

```html
<section id="stats" aria-labelledby="stats-heading">
  <h2 id="stats-heading" class="visually-hidden">At a Glance</h2>
  <article class="stat-card">
    <p class="stat-card__number">48</p>
    <p class="stat-card__label">Projects shipped</p>
  </article>
  <article class="stat-card">
    <p class="stat-card__number">12k</p>
    <p class="stat-card__label">GitHub stars</p>
  </article>
  <article class="stat-card">
    <p class="stat-card__number">6</p>
    <p class="stat-card__label">Years experience</p>
  </article>
</section>
```

`article` is correct here: each stat card is independently meaningful, not just a layout grouping.

### Step 7 — Projects

```html
<section id="projects" aria-labelledby="projects-heading">
  <h2 id="projects-heading">Projects</h2>
  <ul class="project-grid">
    <li>
      <article class="project-card">
        <h3>NovaFolio</h3>
        <p>A framework-free personal portfolio built with semantic HTML5 and modern CSS.</p>
        <ul class="project-card__tags">
          <li>HTML5</li>
          <li>CSS Grid</li>
        </ul>
        <a href="https://github.com/example/novafolio">View project</a>
      </article>
    </li>
  </ul>
</section>
```

### Step 8 — Activity feed and About aside

```html
<section id="activity" aria-labelledby="activity-heading">
  <h2 id="activity-heading">Recent Activity</h2>
  <ol class="activity-feed">
    <li>
      Shipped v2 of NovaFolio.
      <time datetime="2026-01-14">Jan 14, 2026</time>
    </li>
  </ol>
</section>

<aside id="about" aria-label="About the author">
  <p>Alex is a front-end engineer specializing in accessible, dependency-light web interfaces.</p>
  <ul>
    <li>Semantic HTML</li>
    <li>Modern CSS</li>
  </ul>
</aside>
```

The feed uses `ol` because recency/sequence matters (most recent first). `time datetime="..."` gives machines a parseable timestamp while showing humans a friendly date. `aside` is correct for the About blurb — it's tangential to "here are my projects," not the main flow.

### Step 9 — Footer

```html
<footer class="site-footer">
  <nav aria-label="Footer">
    <ul>
      <li><a href="#main-content">Back to top</a></li>
    </ul>
  </nav>
  <p>&copy; 2026 Alex Chen. All rights reserved.</p>
  <ul class="social-links">
    <li><a href="https://github.com/example" aria-label="GitHub profile">GitHub</a></li>
  </ul>
</footer>
```

Icon-only links always need an accessible name via `aria-label` or visually-hidden text — an icon alone announces nothing useful to a screen reader.

### Step 10 — Validate the outline

Use Chrome DevTools → Elements → Accessibility pane (or Firefox Accessibility Inspector) to confirm: exactly one `main` landmark, a logical heading order with no skipped levels, and every `nav` labeled distinctly. Also run the page through the free W3C validator at validator.w3.org before any CSS is written.

## 3. Exercise Challenge

Add a "Testimonials" section to NovaFolio, semantically. Requirements:
- It needs its own heading.
- Use the correct element for each individual testimonial — is it self-contained shareable content, or just a layout grouping?
- Correctly mark up the quote itself (there are two purpose-built HTML elements for quotations — find them).
- Correctly mark up attribution for who said it (there's a purpose-built element for that too).

## 4. Solution & Explanation

```html
<section id="testimonials" aria-labelledby="testimonials-heading">
  <h2 id="testimonials-heading">What people say</h2>
  <ul>
    <li>
      <article class="testimonial">
        <blockquote>
          <p>Alex shipped our redesign two weeks ahead of schedule with zero accessibility regressions.</p>
          <footer>
            — <cite>Jamie Lin, Product Lead</cite>
          </footer>
        </blockquote>
      </article>
    </li>
  </ul>
</section>
```

Each testimonial is an `article` because a quote is self-contained content that makes sense pulled out onto another page (e.g. a marketing page). `blockquote` is the block-level element for extended quotations. `cite` specifically references the source/author of a quoted work, and the conventional pattern nests it inside a `footer` within the `blockquote`. This gives an accessible name via the heading structure, syndication-safe articles, and semantically correct quotation markup — all without a single `div` needed for structural meaning.

---

Next: **Part 2 — The Box Model & Layouts**, where we finally add CSS and turn this skeleton into a real, styled page.
