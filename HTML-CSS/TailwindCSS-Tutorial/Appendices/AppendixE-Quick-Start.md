# Appendix E: Quick-Start Instructions — Tailwind CSS v4 in React 19 & Next.js 16

Use this appendix as a standalone, copy-paste checklist any time you need to wire Tailwind v4 into a fresh React 19 or Next.js 16 project without re-reading the full series.

## E.1 Prerequisites (Both Paths)

```bash
node -v
# Must print v20.9.x+ or v22.x LTS. Next.js 16 will refuse to run on Node 18 (EOL).
```

## E.2 Next.js 16 (App Router) — Step by Step

**Step 1 — Scaffold with Tailwind pre-wired:**
```bash
npx create-next-app@latest my-app \
  --typescript \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*"
# Answer "Yes" to "Would you like to use Tailwind CSS?" — this configures v4 automatically.
```

**Step 2 — If retrofitting an existing project instead, install manually:**
```bash
npm install tailwindcss @tailwindcss/postcss postcss
rm -f tailwind.config.js tailwind.config.ts   # v4 does not use this file
```

**Step 3 — Create/verify `postcss.config.mjs` at the project root:**
```js
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
```

**Step 4 — Set `src/app/globals.css` to just the import (plus optional theme):**
```css
@import "tailwindcss";

@theme {
  --color-brand-500: oklch(0.58 0.22 265);
  --font-display: "Geist", ui-sans-serif, system-ui, sans-serif;
}
```

**Step 5 — Import the CSS file exactly once, in the root layout:**
```tsx
// src/app/layout.tsx
import "./globals.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
```

**Step 6 — Run and verify:**
```bash
npm run dev
```
```tsx
// src/app/page.tsx — sanity check component
export default function Home() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-950">
      <h1 className="text-4xl font-bold text-brand-500">Tailwind v4 is working ✓</h1>
    </main>
  );
}
```
If `text-brand-500` renders in your custom brand color, both the Tailwind engine AND your `@theme` token are wired correctly.

## E.3 React 19 + Vite 6 (Standalone, No Next.js) — Step by Step

**Step 1 — Scaffold:**
```bash
npm create vite@latest my-react19-app -- --template react-ts
cd my-react19-app
npm install
```

**Step 2 — Install Tailwind's Vite plugin (NOT the PostCSS plugin):**
```bash
npm install tailwindcss @tailwindcss/vite
```

**Step 3 — Register the plugin in `vite.config.ts`:**
```ts
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

**Step 4 — Set `src/index.css` to just the import:**
```css
@import "tailwindcss";
```

**Step 5 — Import it once in `src/main.tsx`:**
```tsx
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

**Step 6 — Run and verify:**
```bash
npm run dev
```
```tsx
// src/App.tsx
export default function App() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-950 text-white">
      <h1 className="text-4xl font-bold">Tailwind v4 + React 19 ✓</h1>
    </div>
  );
}
```

## E.4 React 19 Inside a Next.js 16 Project — Important Clarification

If you're using **Next.js 16**, React 19 is already the underlying UI runtime (Next.js 16 requires React 19+) — you do **not** install React or configure it separately. **Always follow the Next.js 16 instructions in E.2**, not the standalone Vite instructions in E.3, when working inside a Next.js project. E.3 is only for non-Next.js React 19 apps (plain SPA, component library dev environment, etc.).

| Situation | Use |
|---|---|
| Building a Next.js 16 app (App Router) | **E.2** (`@tailwindcss/postcss`) |
| Building a standalone React 19 SPA/library with Vite | **E.3** (`@tailwindcss/vite`) |
| Building a React 19 app with a different bundler (webpack/esbuild/Parcel) | Part 2, Path C (`@tailwindcss/postcss` via that bundler's PostCSS integration) |

## E.5 Minimal `@theme` Starter Block (Copy-Paste Into Either Path)

```css
@import "tailwindcss";

@theme {
  /* Brand color */
  --color-brand-500: oklch(0.58 0.22 265);
  --color-brand-600: oklch(0.50 0.22 265);

  /* Typography */
  --font-display: "Geist", ui-sans-serif, system-ui, sans-serif;

  /* Radii & shadows */
  --radius-xl: 1rem;
  --shadow-soft: 0 2px 10px rgb(0 0 0 / 0.06), 0 8px 24px rgb(0 0 0 / 0.08);
}
```

## E.6 Minimal Class-Based Dark Mode Snippet (Copy-Paste Into Either Path)

```css
@custom-variant dark (&:where(.dark, .dark *));
```
```tsx
// Toggle anywhere client-side (needs "use client" in Next.js)
document.documentElement.classList.toggle("dark");
```

## E.7 Recommended Companion Packages (Both Paths)

```bash
npm install clsx tailwind-merge class-variance-authority lucide-react
npm install -D prettier prettier-plugin-tailwindcss eslint-plugin-tailwindcss
```

```ts
// src/lib/cn.ts — drop this into any React 19 project, Next.js or not
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

## E.8 Final Sanity Checklist

- [ ] `npm ls tailwindcss` shows `^4.x`
- [ ] No `tailwind.config.js`/`.ts` file exists anywhere in the project
- [ ] CSS entry file contains `@import "tailwindcss";` as its first line
- [ ] Next.js → `postcss.config.mjs` registers `@tailwindcss/postcss` — OR — Vite → `vite.config.ts` registers `tailwindcss()` from `@tailwindcss/vite`
- [ ] CSS entry file is imported exactly once at the app's root entry point
- [ ] A test utility class (e.g. `bg-red-500`) visibly renders after `npm run dev`
- [ ] A custom `@theme` token (e.g. `bg-brand-500`) visibly renders in your brand color

If every box is checked, Tailwind CSS v4 is fully and correctly wired into your React 19 / Next.js 16 project — proceed to Part 3 onward for design tokens, layout, variants, and the full capstone build.
