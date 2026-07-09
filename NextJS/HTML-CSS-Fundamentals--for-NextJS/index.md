## The Modern Web: From Browser Fundamentals to Next.js Architectures

**Philosophy:** Every framework abstraction is a shortcut for something the browser already does natively. Before you trust Tailwind's `p-4` or Next.js's `layout.tsx`, you should be able to write the raw HTML/CSS it compiles down to in your head. This series builds that mental model, then layers the modern tooling back on top.

**Stack targeted:** Next.js 16 (App Router, Turbopack default bundler, async dynamic APIs), Tailwind CSS v4 (CSS-first config via `@import "tailwindcss";`, no `tailwind.config.ts` required), semantic HTML5, WCAG-conscious accessibility (A11y) patterns throughout.

### Structure
Each part follows the same two-beat pattern:
1. **Browser Reality** — a minimal, dependency-free HTML/CSS snippet showing the raw mechanism.
2. **Next.js/Tailwind Translation** — the exact framework feature that automates that mechanism, with working App Router code.

### Parts
- **Part 1: The Anatomy of a Page** — `<html>`/`<head>`/`<body>`, the CSS Box Model, `RootLayout.tsx`, and why `p-4`/`m-2`/`border` are just the box model spelled differently.
- **Part 2: Flow & Positioning** — Normal Document Flow, Flexbox, Grid, and how `flex`/`justify-between`/`grid-cols-3` map 1:1 to raw CSS properties.
- **Part 3: The Styling System** — The Cascade, specificity wars, why Tailwind's utility classes are "atomic," and how `tailwind-merge` resolves conflicting classes at runtime.
- **Part 4: The Component Model** — Global CSS vs component-scoped styling, why we extract components, and building a full responsive, semantic, accessible UI component from scratch.
- **Part 5: Data & the Network** — Raw HTTP request/response, forms without JavaScript, and how Server Actions (`'use server'`), `useActionState`, and Server Component `fetch()` caching automate and progressively enhance those fundamentals.
- **Part 6: Routing & Navigation** — The browser's URL bar, full-page navigation, and nested HTML shells, and how the App Router's file-system routing, `<Link>` client-side transitions, and nested `layout.tsx` files automate them.
- **Part 7: State & Interactivity** — The DOM's native stateful elements (`details`, checkboxes), manual DOM mutation vs. `useState`, why `'use client'` marks the server/client boundary, and controlled vs. uncontrolled inputs.
- **Part 8: Images & Performance** — Native `img`/`srcset`/`sizes`/`loading="lazy"`, render-blocking `<script>` vs `defer`/`async`, `@font-face` layout shift, and how `next/image`, `next/script`, and `next/font` automate each.

### Prerequisites
- Node.js 20.9+ or 22 LTS
- A Next.js 16 app: `npx create-next-app@latest --typescript --tailwind --app`
- Basic comfort reading HTML and JSX (no prior CSS theory assumed — that's what this series teaches)

### Notes on conventions used in code samples
- All Server Components are the default; `'use client'` is called out explicitly wherever a component needs interactivity.
- Dynamic Next.js APIs (`params`, `searchParams`, `cookies()`, `headers()`) are treated as async per Next.js 16 requirements, even in examples that don't strictly need them, to build correct muscle memory.
- Tailwind v4's CSS-first config means `globals.css` — not `tailwind.config.ts` — is the source of truth for theme tokens in these examples.
