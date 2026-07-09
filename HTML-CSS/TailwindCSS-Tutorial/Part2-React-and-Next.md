# Part 2: Installation Deep-Dive — Tailwind CSS v4 in Next.js 16 & React 19

This part is the **canonical setup reference** for the rest of the series. Two install paths are covered in full; pick the one matching your project (or do both — the capstone in Part 11 uses the Next.js 16 path).

| Path | When to use |
|---|---|
| **A. Next.js 16 (App Router)** | Primary path for this whole series (Parts 5-11) |
| **B. React 19 + Vite 6** | Standalone React apps, libraries, non-Next.js SPAs |
| **C. Plain PostCSS (framework-agnostic)** | Any other build tool (webpack, esbuild, Parcel) |
| **D. CDN Play CDN** | Zero-build prototyping only — never for production |

---

## Path A — Next.js 16 (App Router) — Primary Path

### A.1 Prerequisites

```bash
node -v   # must be v20.9+ or v22 LTS — Next.js 16 requires this, Node 18 is EOL/unsupported
```

### A.2 Fresh Project (Recommended)

```bash
npx create-next-app@latest tw4-mastery \
  --typescript \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*"

# When prompted:
# ✔ Would you like to use Tailwind CSS?  › Yes   <-- scaffolds Tailwind v4 automatically
# ✔ Turbopack for `next dev`?            › Yes   <-- default in Next.js 16
```

`create-next-app` on Next.js 16 already wires up Tailwind v4 correctly out of the box. Verify what it generated:

```bash
cd tw4-mastery
cat package.json | grep -i tailwind
```
Expected:
```json
"tailwindcss": "^4.1.0",
"@tailwindcss/postcss": "^4.1.0"
```

```js
// postcss.config.mjs  (auto-generated — confirm it looks like this)
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
```

```css
/* src/app/globals.css (auto-generated — confirm it looks like this) */
@import "tailwindcss";
```

If all three match, you're done — run `npm run dev` and start building.

### A.3 Manual Install (Adding Tailwind v4 to an EXISTING Next.js 16 Project)

Use this if you skipped the prompt or are retrofitting an older project.

```bash
# 1. Install the core package + the Next.js/PostCSS-specific plugin
npm install tailwindcss @tailwindcss/postcss postcss
```

```js
// 2. Create/replace postcss.config.mjs at the project root
const config = {
  plugins: {
    "@tailwindcss/postcss": {}, // this single plugin replaces postcss-import + autoprefixer + tailwindcss from v3
  },
};

export default config;
```

```css
/* 3. src/app/globals.css — replace old @tailwind directives with a single import */
@import "tailwindcss";

/* Optional: your design tokens go here (see Part 3) */
@theme {
  --font-sans: "Geist", ui-sans-serif, system-ui, sans-serif;
}
```

```tsx
// 4. src/app/layout.tsx — make sure globals.css is imported ONCE at the root
import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "TW4 Mastery",
  description: "Tailwind CSS v4 + Next.js 16 + React 19",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
```

```bash
# 5. Delete legacy v3 artifacts if they exist — they will silently do nothing in v4
rm -f tailwind.config.js tailwind.config.ts
```

> **Why no `tailwind.config.ts`?** Because content detection is automatic and theme customization now lives in CSS via `@theme` (Part 3). A stray `tailwind.config.ts` from a v3 project is simply ignored by v4's PostCSS plugin — it is not an error, but it also does nothing, which is a common silent-bug source (see Appendix D).

### A.4 Verify It Works

```tsx
// src/app/page.tsx
export default function Home() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-950">
      <h1 className="text-4xl font-bold text-white">
        Tailwind v4 + Next.js 16 <span className="text-emerald-400">✓</span>
      </h1>
    </main>
  );
}
```

```bash
npm run dev
# open http://localhost:3000 — you should see white text, emerald checkmark, dark navy background
```

If styles don't apply, jump to **Appendix D: Troubleshooting Guide**.

---

## Path B — React 19 + Vite 6 (Standalone)

### B.1 Scaffold

```bash
npm create vite@latest tw4-react19-app -- --template react-ts
cd tw4-react19-app
npm install
```

Verify React 19 landed (Vite's react-ts template tracks latest stable React):
```bash
cat package.json | grep '"react"'
# "react": "^19.0.0"
```

### B.2 Install Tailwind's Vite Plugin (No PostCSS Needed)

```bash
npm install tailwindcss @tailwindcss/vite
```

```ts
// vite.config.ts
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  // Order matters conceptually but not functionally here — tailwindcss()
  // hooks into Vite's transform pipeline independently of the React plugin.
  plugins: [react(), tailwindcss()],
});
```

```css
/* src/index.css — replace entire file contents with just this import */
@import "tailwindcss";
```

```tsx
// src/main.tsx — confirm index.css is imported at the entry point
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App.tsx";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
```

```tsx
// src/App.tsx — verify
export default function App() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-950">
      <h1 className="text-4xl font-bold text-white">
        Tailwind v4 + React 19 (Vite) <span className="text-emerald-400">✓</span>
      </h1>
    </div>
  );
}
```

```bash
npm run dev
```

> **Why the Vite plugin instead of PostCSS here?** `@tailwindcss/vite` integrates directly with Vite's module graph, giving faster HMR than routing through PostCSS. Next.js 16 does not yet expose an equivalent native-Vite-style plugin hook for its (Turbopack) build, so the PostCSS plugin (`@tailwindcss/postcss`) remains the correct choice for Next.js specifically — this is the one meaningful install difference between the two frameworks.

---

## Path C — Plain PostCSS (Any Other Bundler: webpack, esbuild, Parcel)

```bash
npm install tailwindcss @tailwindcss/postcss postcss
```

```js
// postcss.config.js (CommonJS) or postcss.config.mjs (ESM) — match your project's module type
module.exports = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

```css
/* any CSS entry point your bundler already loads */
@import "tailwindcss";
```

No other config is required — `@tailwindcss/postcss` handles importing, nesting, and vendor prefixing internally (it bundles Lightning CSS), so you can safely remove `autoprefixer` and `postcss-import` from your `devDependencies` if they were only there for Tailwind.

---

## Path D — CDN Play CDN (Prototyping Only — Never Production)

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <script src="https://cdn.tailwindcss.com/4"></script>
  </head>
  <body>
    <h1 class="text-3xl font-bold text-purple-600">Hello, Tailwind v4 CDN</h1>
  </body>
</html>
```

Use only for CodePen-style demos. It ships the entire engine to the browser and recompiles at runtime — no `@theme` file customization, no build optimization, not tree-shaken. Never ship this to production.

---

## Side-by-Side Summary Table

| Step | Next.js 16 | React 19 + Vite |
|---|---|---|
| Packages | `tailwindcss @tailwindcss/postcss postcss` | `tailwindcss @tailwindcss/vite` |
| Config file | `postcss.config.mjs` | `vite.config.ts` (plugins array) |
| CSS entry | `src/app/globals.css` | `src/index.css` |
| Import statement | `@import "tailwindcss";` | `@import "tailwindcss";` (identical!) |
| `tailwind.config.ts`? | ❌ not needed | ❌ not needed |
| Content scanning | Automatic | Automatic |
| Dev server | `next dev` (Turbopack) | `vite` |

The CSS-side API (`@import`, `@theme`, utility classes) is **100% identical** across both frameworks — this is the biggest ergonomic win of v4. Only the *build tool wiring* differs.

## Exercise Challenge

Starting from a fresh `create-next-app@latest` Next.js 16 project, intentionally break the setup by renaming `postcss.config.mjs` to `postcss.config.js.bak`. Run `npm run dev`, observe that Tailwind classes stop applying (raw unstyled HTML), then fix it.

## Solution

Renaming/removing the PostCSS config file means the build tool never invokes `@tailwindcss/postcss`, so `@import "tailwindcss";` in `globals.css` is treated as a literal (and likely failing) CSS `@import` rather than being expanded into Tailwind's generated stylesheet. Restore the file with:
```js
const config = { plugins: { "@tailwindcss/postcss": {} } };
export default config;
```
and restart the dev server (PostCSS config changes are not hot-reloaded).

---

*Next: Tailwind v4 Mastery - Part 3: The @theme Directive & Design Tokens*
