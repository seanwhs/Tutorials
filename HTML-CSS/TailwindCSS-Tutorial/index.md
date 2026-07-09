# Tailwind CSS v4 Mastery — Complete Tutorial Series

> **Status:** ✅ COMPLETE. Beginner-friendly, code-heavy tutorial series teaching **Tailwind CSS v4** — the CSS-first, Oxide-engine rewrite — integrated with **React 19** and **Next.js 16 (App Router, Turbopack)**.

All notes in this series use the prefix **"Tailwind v4 Mastery - "**. Read them in order. Each part builds on the previous one using a single running project (`tw4-mastery`).

---

## 1. Why This Series Exists

Tailwind CSS v4 (2025) is **not** an incremental update — it's a ground-up rewrite:

| | Tailwind v3 (old) | Tailwind v4 (this series) |
|---|---|---|
| Engine | JS-based | **Oxide** (Rust + Lightning CSS), 5-10x faster full builds, ~100x faster incremental |
| Config | `tailwind.config.js` (JS object) | **CSS-first**: `@theme` block directly in your CSS |
| Import | `@tailwind base; @tailwind components; @tailwind utilities;` | Single `@import "tailwindcss";` |
| PostCSS plugin | `tailwindcss` | `@tailwindcss/postcss` (separate package) |
| Content scanning | Manual `content: []` glob array | **Automatic** — scans your project, respects `.gitignore` |
| Vite / Next.js | PostCSS plugin only | Native `@tailwindcss/vite` plugin available, plus PostCSS for Next.js |
| Browser support | IE11-friendly fallbacks | Modern browsers only (Safari 16.4+, Chrome 111+, Firefox 128+) |
| Container queries | Plugin (`@tailwindcss/container-queries`) | **Built-in** (`@container`, `@sm:`, etc.) |
| Dynamic values | Fixed spacing/color scale | **Arbitrary values everywhere**, plus dynamic utility matching |
| Variants | Fixed list | Extendable via `@custom-variant`, plus new `not-*`, `has-*`, `starting:`, `inert:` |

## 2. Tech Stack (Standing Requirement)

| Layer | Choice |
|---|---|
| Styling engine | **Tailwind CSS v4.x** — CSS-first config, no `tailwind.config.ts` |
| PostCSS plugin (Next.js) | `@tailwindcss/postcss` |
| Vite plugin (React 19 standalone) | `@tailwindcss/vite` |
| Framework A | **Next.js 16** (App Router, Turbopack, Node 20.9+/22 LTS) — primary framework |
| Framework B | **React 19** + Vite 6 — for portability/standalone patterns |
| Utility helpers | `clsx` + `tailwind-merge` (`cn()`), `class-variance-authority` (CVA) |
| Icons | `lucide-react` |
| Fonts | `next/font` |
| Editor tooling | Tailwind CSS IntelliSense (VS Code), `prettier-plugin-tailwindcss` |

No backend, database, or auth service is required — 100% frontend/styling-focused.

## 3. Full Series Index (All Notes)

| # | Title | Covers |
|---|---|---|
| — | **Tailwind v4 Mastery - INDEX (Start Here)** | This note |
| 1 | **Tailwind v4 Mastery - Part 1: Architecture & the Oxide Engine** | Engine internals, cascade layers, no-JS-config rationale, namespace fan-out |
| 2 | **Tailwind v4 Mastery - Part 2: Installation Deep-Dive (Next.js 16 & React 19)** | Full install: Next.js 16 (primary), React 19 + Vite, plain PostCSS, CDN |
| 3 | **Tailwind v4 Mastery - Part 3: The @theme Directive & Design Tokens** | Replacing JS config, namespace table, `@theme inline`, overriding defaults |
| 4 | **Tailwind v4 Mastery - Part 4: Core Utility Classes Crash Course** | Layout, spacing, sizing, typography, color, borders, effects |
| 5 | **Tailwind v4 Mastery - Part 5: Responsive Design, Container Queries & Dark Mode** | Breakpoints, `@container`, class-based dark mode, flash-of-wrong-theme fix |
| 6 | **Tailwind v4 Mastery - Part 6: State Variants, group/peer/has-*, Custom Variants** | Interaction states, `group`, `peer`, `has-*`, `not-*`, `@custom-variant` |
| 7 | **Tailwind v4 Mastery - Part 7: Component Patterns in React 19** | `cn()`, CVA, `@apply`, Server vs Client Component styling boundary |
| 8 | **Tailwind v4 Mastery - Part 8: Animations & Transitions** | Transitions, `animate-*`, custom keyframes, `starting:`, exit animations, `motion-reduce:` |
| 9 | **Tailwind v4 Mastery - Part 9: Advanced Customization** | `@utility`, arbitrary values/variants, prefixing, `@source` |
| 10 | **Tailwind v4 Mastery - Part 10: Performance, Tooling & Editor Setup** | Build perf, VS Code IntelliSense, Prettier/ESLint plugins, purge myths |
| 11a | **Tailwind v4 Mastery - Part 11: Capstone Project** | PulseBoard dashboard: overview, data, theme, layout, sidebar/topbar |
| 11b | **Tailwind v4 Mastery - Part 11 (continued): Dashboard Components & Wrap-up** | StatGrid, RevenueChart, ActivityFeed, PlanUsage, traceability table |
| A1 | **Tailwind v4 Mastery - Appendix A: Full Codebase Reference** | package.json, postcss config, prettier/vscode config, globals.css, lib/ |
| A2 | **Tailwind v4 Mastery - Appendix A (continued): Component Files** | layout.tsx, page.tsx, ui/ primitives, ThemeToggle, Sidebar, Topbar |
| A3 | **Tailwind v4 Mastery - Appendix A (part 3): Dashboard Widget Files** | StatGrid, RevenueChartCard, RecentActivityFeed, PlanUsagePanel, setup recap |
| B | **Tailwind v4 Mastery - Appendix B: v3 to v4 Migration Guide** | Automated codemod, config mapping table, renamed utilities, breaking changes, checklist |
| C | **Tailwind v4 Mastery - Appendix C: Utility Class Quick Reference Tables** | Spacing scale, layout, flexbox, grid, typography, colors, borders, sizing, breakpoints, variants, animation |
| D | **Tailwind v4 Mastery - Appendix D: Troubleshooting Guide** | Styles not applying, IntelliSense, dark mode, container queries, animations, React-specific, build/perf issues |
| E | **Tailwind v4 Mastery - Appendix E: Quick-Start Cheat Sheet (React 19 & Next.js 16)** | Standalone copy-paste setup instructions for both frameworks + sanity checklist |

## 4. The 60-Second Version

**Next.js 16 setup:**
```bash
npx create-next-app@latest tw4-mastery --typescript --eslint --app --src-dir --import-alias "@/*"
# Answer "Yes" to Tailwind CSS prompt — scaffolds v4 automatically
```
```js
// postcss.config.mjs
export default { plugins: { "@tailwindcss/postcss": {} } };
```
```css
/* src/app/globals.css */
@import "tailwindcss";
@theme {
  --color-brand: oklch(0.65 0.24 260);
}
```

**React 19 + Vite setup:**
```bash
npm create vite@latest tw4-react19-app -- --template react-ts
cd tw4-react19-app
npm install tailwindcss @tailwindcss/vite
```
```ts
// vite.config.ts
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```
```css
/* src/index.css */
@import "tailwindcss";
```

**No `tailwind.config.ts` file is needed in either path.** Full step-by-step instructions (including the "which path to use inside Next.js" clarification) are in **Appendix E**. Complete install walkthroughs with verification steps are in **Part 2**.
