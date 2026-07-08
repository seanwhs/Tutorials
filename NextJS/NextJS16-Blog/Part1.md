## Blog Tutorial - Part 1: Project Setup (Next.js 16 + TypeScript + Tailwind CSS v4)

## What we're doing
We'll scaffold a new Next.js 16 App Router project with TypeScript and Tailwind CSS v4 pre-configured, then verify it runs on Turbopack (the default bundler in Next.js 16).

## Step 0: Verify your Node.js version

Next.js 16 requires **Node.js 20.9+** (Node 22 LTS recommended). Node 18 is end-of-life and will not work.

```bash
node -v
```

If this shows anything below `v20.9.0`, install Node 22 LTS from nodejs.org (or via `nvm install 22 && nvm use 22`) before continuing.

## Step 1: Create the project

```bash
npx create-next-app@latest my-blog
```

When prompted, answer:
```
Would you like to use TypeScript?  Yes
Would you like to use ESLint?      Yes
Would you like to use Tailwind CSS? Yes
Would you like to use `src/` directory? Yes
Would you like to use App Router?  Yes
Would you like to use Turbopack for `next dev`? Yes (this is the default in Next.js 16)
Would you like to customize the default import alias (@/*)? Yes (keep default @/*)
```

Then move into the project:

```bash
cd my-blog
```

create-next-app on Next.js 16 sets up **Tailwind CSS v4** automatically, using its new CSS-first configuration — there is no `tailwind.config.ts` file to edit.

## Step 2: Verify project structure

You should have:

```
my-blog/
  src/
    app/
      layout.tsx
      page.tsx
      globals.css
    public/
  postcss.config.mjs
  package.json
  tsconfig.json
```

Notice: **no `tailwind.config.ts`** — in Tailwind v4, configuration lives inside `globals.css` itself.

## Step 3: Install extra dependencies we'll need throughout this series

```bash
npm install @sanity/client @sanity/image-url @portabletext/react next-sanity sanity groq
npm install @clerk/nextjs
npm install @tailwindcss/typography
```

- `next-sanity` / `sanity` — embeds Sanity Studio + client helpers into Next.js
- `@sanity/client` — talks to Sanity's API
- `@sanity/image-url` — builds optimized image URLs from Sanity image assets
- `@portabletext/react` — renders Sanity's rich text ("Portable Text") as React
- `groq` — tagged template helper for Sanity's query language
- `@clerk/nextjs` — authentication (a recent version with Next.js 16 support)
- `@tailwindcss/typography` — nice default prose styling for blog content

## Step 4: Configure Tailwind v4 and the typography plugin in globals.css

Open `src/app/globals.css`. create-next-app will have already put something like `@import "tailwindcss";` at the top. Update the file to:

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";

@custom-variant dark (&:where(.dark, .dark *));

body {
  @apply bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100;
}
```

Notes on what changed from Tailwind v3:
- `@import "tailwindcss";` replaces the old `@tailwind base; @tailwind components; @tailwind utilities;` trio.
- `@plugin "@tailwindcss/typography";` registers the typography plugin directly in CSS — no `plugins: [require(...)]` array needed.
- `@custom-variant dark (&:where(.dark, .dark *));` recreates Tailwind v3's `darkMode: "class"` behavior in the v4 CSS-first world — this is what makes `dark:` utility classes respond to a `.dark` class on `<html>`, which we'll toggle in Part 11.
- There is no `tailwind.config.ts` `content` array to maintain — Tailwind v4 automatically detects template files.

## Step 5: Clean up the default homepage

Replace the contents of `src/app/page.tsx` with:

```tsx
export default function HomePage() {
  return (
    <main className="mx-auto max-w-4xl px-4 py-16">
      <h1 className="text-4xl font-bold tracking-tight">
        Welcome to My Blog
      </h1>
      <p className="mt-4 text-gray-600 dark:text-gray-300">
        This is where our blog posts will appear. Built with Next.js 16,
        Tailwind CSS v4, Sanity, and Clerk.
      </p>
    </main>
  );
}
```

## Step 6: Update global layout

Replace `src/app/layout.tsx` with:

```tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "My Blog",
  description: "A blog built with Next.js, Tailwind CSS, Sanity, and Clerk",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
```

## Step 7: Run the dev server

```bash
npm run dev
```

Next.js 16 uses **Turbopack by default** for `next dev` — you'll see it mentioned in the terminal output. Visit http://localhost:3000 — you should see "Welcome to My Blog" styled with Tailwind.

## Step 8: Initialize git and push to GitHub (needed later for Vercel deployment)

```bash
git init
git add .
git commit -m "Initial commit: Next.js 16 + Tailwind v4 setup"
```

Create a new empty repository on GitHub (github.com/new), then:

```bash
git remote add origin https://github.com/YOUR_USERNAME/my-blog.git
git branch -M main
git push -u origin main
```

## Checkpoint ✅
- [ ] `node -v` reports 20.9+ (22 LTS recommended)
- [ ] `npm run dev` runs without errors, using Turbopack
- [ ] Homepage displays styled text at localhost:3000
- [ ] No `tailwind.config.ts` file exists; all Tailwind config lives in `globals.css`
- [ ] Project is pushed to a GitHub repo

Next: **Part 2 — Setting Up Sanity: Account, Project, Embedded Studio**
