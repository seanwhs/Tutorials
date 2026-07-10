# Modern Foundations: Essential HTML5 and CSS3 for the Modern Web

**A principal-engineer-style, code-heavy tutorial series on building modular, maintainable UIs, framework-free.**

## Philosophy

This series treats HTML and CSS as a serious architectural discipline — not "beginner glue" you rush past on the way to a framework. Two guiding principles run through every part:

1. **Locality of Behavior (LoB)** — a component's structure, styling hooks, and intent should be readable in one place. You shouldn't have to hunt across five files to understand what a `.card` does. We achieve this with **BEM naming** + **co-located, modular CSS files** (one stylesheet per component/domain), not a giant monolithic `style.css`.
2. **Clean Architecture (for the front end)** — separate **structure** (HTML — what things *are*), **presentation** (CSS — how things *look*), and later, **behavior** (JS — how things *react*, kept out of scope here). No inline styles, no `<style>` soup in HTML, no `!important` wars. Each layer is independently replaceable.

We build with **zero frameworks** (no Bootstrap, no Tailwind — that's a different series). Just HTML5 semantics, modern CSS (Grid, Flexbox, Custom Properties, `:has()`, scroll-driven animations), and your browser's dev tools. Every tool used is free and open-source, and every project ships as a static site deployable to **Vercel** or **GitHub Pages** at zero cost.

## The Capstone Project: "NovaFolio"

Across all 5 parts you incrementally build **NovaFolio** — a personal developer portfolio landing page that doubles as a mini "dashboard" (stats cards, project grid, activity feed). It's realistic enough to resemble production code, small enough to finish in a weekend.

By Part 5 you'll have:
- A fully semantic, accessible document outline
- A responsive Grid-based page shell with Flexbox-based components
- Fluid typography and a mobile-first responsive design
- A themeable design-token system (light/dark mode, no JS required for the toggle mechanics)
- Modern interactive polish (`:has()`, scroll-driven reveal animations, pure-CSS transitions)

## Series Structure

| Part | Title | Core Topics |
|---|---|---|
| 1 | The Semantic Document | `<main>`, `<section>`, `<article>`, `<aside>`, heading outline, ARIA basics, SEO |
| 2 | The Box Model & Layouts | `box-sizing: border-box`, Flexbox for components, CSS Grid for page shells |
| 3 | Responsive Design | Mobile-first media queries, fluid type with `clamp()`, responsive images |
| 4 | CSS Architecture | BEM, CSS Custom Properties for theming, file/module organization, cascade layers |
| 5 | Advanced Interactions | `:has()`, scroll-driven animations, transitions, `@starting-style`, reduced motion |
| A | Appendix: Codebase Reference | Full file tree + setup guide |
| B | Appendix: CSS Cheat Sheet | Grid vs Flexbox, unit reference (`rem`, `svh`, `dvw`, etc.) |
| C | Appendix: Deployment Checklist | Ship to Vercel / GitHub Pages for free |

## How Each Part Is Structured

Every part follows the same four-section format so you always know where you are:

1. **Concept Explanation** — the "why," with mental models and common pitfalls.
2. **Implementation** — step-by-step code you build into the NovaFolio project.
3. **Exercise Challenge** — a task to extend the concept on your own.
4. **Solution & Explanation** — a worked solution with reasoning, not just an answer key.

## Prerequisites

- A code editor (VS Code recommended, free)
- A modern browser (Chrome, Firefox, Edge, or Safari — all support the CSS features used here as of 2025)
- Zero build tools required. No Node, no bundler, no `package.json`. This is intentionally raw HTML/CSS you open directly in a browser or serve with any static file server.
- (Optional, for Appendix C) A free GitHub account and/or free Vercel account.

## Note Index

- Part 1 (The Semantic Document)
- Part 2 (The Box Model & Layouts)
- Part 3 (Responsive Design)
- Part 4 (CSS Architecture)
- Part 5 (Advanced Interactions)
- Appendix A (Codebase Reference)
- Appendix B (CSS Cheat Sheet)
- Appendix C (Deployment Checklist)
