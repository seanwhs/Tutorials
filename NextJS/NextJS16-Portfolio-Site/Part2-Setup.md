# Part 2: Environment Setup & Creating the Next.js App

This series targets **Next.js 16** (the current major version at time of writing), which uses **React 19**, **Turbopack** as the default bundler, and **async dynamic APIs** (`params`, `searchParams`, `cookies()`, `headers()` are all Promises now). All code in this series is written with that in mind, so you won't need to rewrite anything later.

## Step 1: Install Node.js

Next.js 16 requires **Node.js 20.9 or later** (Node 22 LTS recommended). Download the LTS installer from https://nodejs.org and install it.

Verify your versions in a terminal:

```bash
node -v
# should print v20.9.0 or higher, ideally v22.x.x

npm -v
# should print 10.x or higher
```

If you see an older version, uninstall and reinstall Node from nodejs.org, or use a version manager like `nvm`:

```bash
# Optional: using nvm (Node Version Manager) on macOS/Linux
nvm install 22
nvm use 22
```

## Step 2: Install a Code Editor

We recommend **VS Code** (free, open-source): https://code.visualstudio.com

Useful free extensions once installed (open the Extensions panel, search, click Install):
- **Tailwind CSS IntelliSense**
- **ES7+ React/Redux/React-Native snippets**
- **Prettier - Code formatter**

## Step 3: Install Git

Download from https://git-scm.com if you don't already have it. Verify:

```bash
git --version
```

We'll use Git to push our code to GitHub in Part 16 for deployment.

## Step 4: Create the Next.js App

Open a terminal, navigate to the folder where you keep your projects, and run:

```bash
npx create-next-app@latest my-portfolio
```

You'll be asked a series of questions. Answer exactly as follows so your project matches this tutorial:

```txt
Would you like to use TypeScript?               › Yes
Would you like to use ESLint?                    › Yes
Would you like to use Tailwind CSS?              › Yes
Would you like your code inside a `src/` directory? › No
Would you like to use App Router?                › Yes
Would you like to use Turbopack for `next dev`?  › Yes
Would you like to customize the import alias (@/*)? › No
```

This scaffolds a new Next.js 16 project with Tailwind CSS already wired up (we'll take a closer look and customize it in Part 3).

Once it finishes, move into the project folder:

```bash
cd my-portfolio
```

## Step 5: Run the Dev Server

```bash
npm run dev
```

Open http://localhost:3000 in your browser. You should see the default Next.js welcome page. Leave this terminal running — Next.js will hot-reload as you edit files.

## Step 6: Open the Project in VS Code

```bash
code .
```

(If the `code` command isn't recognized, open VS Code manually and use File → Open Folder.)

## Step 7: Understand the Starter Project Structure

```txt
my-portfolio/
├── app/
│   ├── favicon.ico
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx
├── public/
├── next.config.ts
├── package.json
├── postcss.config.mjs
├── tsconfig.json
└── ...
```

Key files:
- **`app/layout.tsx`** — the root layout, wraps every page. This is where `<html>` and `<body>` live.
- **`app/page.tsx`** — the homepage component, rendered at `/`.
- **`app/globals.css`** — global styles, including the Tailwind import.
- **`next.config.ts`** — Next.js configuration.
- App Router uses **file-based routing**: a folder named `app/about/` with a `page.tsx` inside automatically becomes the `/about` route. We'll use this extensively.

## Step 8: Clean Up the Starter Template

Let's clear out the default demo content so we start from a clean slate.

Replace the entire contents of `app/page.tsx`:

```tsx
// File: app/page.tsx
export default function Home() {
  return (
    <main className="min-h-screen flex items-center justify-center">
      <h1 className="text-4xl font-bold">Hello, portfolio!</h1>
    </main>
  );
}
```

Replace the entire contents of `app/layout.tsx`:

```tsx
// File: app/layout.tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "My Portfolio",
  description: "Personal portfolio site built with Next.js, Tailwind CSS, and Sanity.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
```

Save both files. Your browser at http://localhost:3000 should hot-reload to show "Hello, portfolio!" centered on the page.

## Step 9: Initialize Git

Even though we'll push to GitHub later (Part 16), it's good practice to start version control now:

```bash
git init
git add .
git commit -m "Initial commit: create-next-app scaffold"
```

`create-next-app` already generated a sensible `.gitignore` (excluding `node_modules`, `.next`, `.env*.local`, etc.), so you don't need to configure that yourself.

## Checkpoint ✅

At this point you should have:
- Node.js 20.9+ installed and verified
- A new Next.js 16 project named `my-portfolio` with TypeScript, ESLint, Tailwind CSS, App Router, and Turbopack enabled
- The dev server running at http://localhost:3000 showing "Hello, portfolio!"
- A local Git repository with your first commit

Next up: **Part 3: Tailwind CSS Setup & Base Layout**, where we'll explore Tailwind CSS v4's configuration and build the shared page shell (container widths, typography, fonts) our whole site will use.

---

Want me to keep going and show Part 3 next?
