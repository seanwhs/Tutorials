# Part 2 — Create the Next.js 16 App + TypeScript + Tailwind CSS

In this part, we will create the actual GreyMatter Ledger project.

By the end of this part, you will have:

- A working Next.js app
- TypeScript enabled
- Tailwind CSS enabled
- ESLint enabled
- A clean project folder
- A basic first page confirming the app is alive
- A local development server running at `http://localhost:3000`

We are not adding Clerk, databases, or accounting logic yet. Those come later.

For now, we are laying the foundation.

---

# 1. Create the Project Folder

## The Target

We are going to create a new Next.js project named:

```txt
greymatter-ledger
```

This folder will contain the entire application.

---

## The Concept

Creating a Next.js app is like pouring the concrete foundation before building a house.

At this stage, we are not deciding paint colors, furniture, or wiring details yet. We are creating the structure that everything else will sit on.

Next.js gives us:

- Routing
- React rendering
- Server-side features
- Development tooling
- Production build tooling

---

## The Implementation

Open your terminal in the directory where you keep your projects.

For example, you might use:

```bash
cd ~/Desktop
```

or:

```bash
cd ~/Projects
```

Now run:

```bash
pnpm create next-app@latest greymatter-ledger
```

The setup wizard will ask several questions.

Choose these options:

```txt
Would you like to use TypeScript?                  Yes
Would you like to use ESLint?                      Yes
Would you like to use Tailwind CSS?                Yes
Would you like your code inside a `src/` directory? No
Would you like to use App Router?                  Yes
Would you like to use Turbopack?                   Yes
Would you like to customize the import alias?      Yes
What import alias would you like configured?       @/*
```

Depending on your exact `create-next-app` version, the prompts may be worded slightly differently.

The important final choices are:

```txt
TypeScript: Yes
ESLint: Yes
Tailwind CSS: Yes
App Router: Yes
src directory: No
Turbopack: Yes
Import alias: @/*
```

After installation finishes, move into the project:

```bash
cd greymatter-ledger
```

---

## The Verification

Run:

```bash
pwd
```

On macOS or Linux, you should see a path ending in:

```txt
greymatter-ledger
```

On Windows PowerShell, run:

```powershell
Get-Location
```

You should also see a path ending in:

```txt
greymatter-ledger
```

Now list the files.

macOS/Linux:

```bash
ls
```

Windows PowerShell:

```powershell
Get-ChildItem
```

You should see files and folders similar to:

```txt
app
eslint.config.mjs
next-env.d.ts
next.config.ts
node_modules
package.json
pnpm-lock.yaml
postcss.config.mjs
public
README.md
tsconfig.json
```

If you see `package.json`, `app`, and `next.config.ts`, your project was created successfully.

---

# 2. Inspect the Initial Project

## The Target

We are going to understand the important files that Next.js generated for us.

---

## The Concept

A new project can feel like walking into a new workshop.

Before using the tools, we should know where they are.

The key files are:

| Path | Purpose |
|---|---|
| `app/` | Application routes and layouts |
| `app/page.tsx` | Homepage route at `/` |
| `app/layout.tsx` | Root layout shared by all pages |
| `app/globals.css` | Global styles and Tailwind CSS |
| `public/` | Static files like images and icons |
| `package.json` | Project scripts and dependencies |
| `tsconfig.json` | TypeScript configuration |
| `next.config.ts` | Next.js configuration |
| `eslint.config.mjs` | Linting configuration |

The `app/` folder is especially important.

With the Next.js App Router, folders become routes.

For example:

```txt
app/page.tsx              -> /
app/dashboard/page.tsx    -> /dashboard
app/invoices/page.tsx     -> /invoices
```

We will use this structure throughout the series.

---

## The Implementation

Open the project in VS Code:

```bash
code .
```

If the `code` command does not work, open VS Code manually and choose:

```txt
File -> Open Folder -> greymatter-ledger
```

Now open:

```txt
package.json
```

You should see something similar to this:

```json
{
  "name": "greymatter-ledger",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint"
  },
  "dependencies": {
    "next": "latest",
    "react": "latest",
    "react-dom": "latest"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "latest",
    "@types/node": "latest",
    "@types/react": "latest",
    "@types/react-dom": "latest",
    "eslint": "latest",
    "eslint-config-next": "latest",
    "tailwindcss": "latest",
    "typescript": "latest"
  }
}
```

Your exact version numbers may differ. That is okay.

The important scripts are:

```json
{
  "dev": "next dev --turbopack",
  "build": "next build",
  "start": "next start",
  "lint": "eslint"
}
```

They mean:

```txt
pnpm dev      Start local development server
pnpm build    Create production build
pnpm start    Run production build locally
pnpm lint     Check code quality
```

---

## The Verification

Run:

```bash
pnpm dev
```

You should see output similar to:

```txt
▲ Next.js
- Local:        http://localhost:3000
```

Open this URL in your browser:

```txt
http://localhost:3000
```

You should see the default Next.js starter page.

Stop the dev server for now by pressing:

```txt
Ctrl + C
```

Then confirm when your terminal asks whether to terminate the process.

---

# 3. Clean the Starter Homepage

## The Target

We are going to replace the default Next.js homepage with a simple GreyMatter Ledger homepage.

This gives us a clean starting point for the app.

---

## The Concept

The starter page is useful for confirming installation, but it is not our application.

Replacing it is like removing the protective plastic from a new appliance before actually using it.

We will create a simple homepage that says:

- The app name
- What it does
- That the project foundation is working

---

## The Implementation

Open this file:

```txt
app/page.tsx
```

Replace the entire file with the following code.

```tsx
// app/page.tsx

export default function HomePage() {
  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <section className="mx-auto flex min-h-screen w-full max-w-6xl flex-col items-center justify-center px-6 py-24 text-center">
        <div className="mb-6 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-4 py-2 text-sm font-medium text-emerald-300">
          Project foundation ready
        </div>

        <h1 className="max-w-4xl text-5xl font-bold tracking-tight sm:text-6xl">
          GreyMatter Ledger
        </h1>

        <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-300">
          A Singapore-ready double-entry accounting application built with
          Next.js, TypeScript, Tailwind CSS, Clerk, Drizzle ORM, Neon Postgres,
          and Inngest.
        </p>

        <div className="mt-10 grid gap-4 sm:grid-cols-3">
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-left">
            <h2 className="text-base font-semibold text-white">
              Double-entry core
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-400">
              Every financial event will become a balanced journal entry.
            </p>
          </div>

          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-left">
            <h2 className="text-base font-semibold text-white">
              Multi-company ready
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-400">
              Each organization will have isolated accounting data.
            </p>
          </div>

          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-left">
            <h2 className="text-base font-semibold text-white">
              Singapore-focused
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-400">
              GST, reports, CPF estimates, and local business workflows.
            </p>
          </div>
        </div>
      </section>
    </main>
  );
}
```

Let’s briefly explain the important pieces.

This line creates the page component:

```tsx
export default function HomePage() {
```

In the App Router, `app/page.tsx` must export a React component as the default export.

This line makes the page at least as tall as the browser window:

```tsx
<main className="min-h-screen bg-slate-950 text-white">
```

The Tailwind classes mean:

```txt
min-h-screen  Minimum height equals the screen height
bg-slate-950  Very dark slate background
text-white    White text
```

This line centers the main content:

```tsx
<section className="mx-auto flex min-h-screen w-full max-w-6xl flex-col items-center justify-center px-6 py-24 text-center">
```

The classes mean:

```txt
mx-auto         Center horizontally
flex           Use flexbox layout
items-center   Center children horizontally
justify-center Center children vertically
max-w-6xl       Limit maximum content width
px-6            Horizontal padding
py-24           Vertical padding
text-center     Center text
```

---

## The Verification

Start the dev server again:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000
```

You should see a dark page with:

```txt
GreyMatter Ledger
```

and three cards:

```txt
Double-entry core
Multi-company ready
Singapore-focused
```

If you see this, your homepage replacement worked.

Keep the dev server running or stop it with:

```txt
Ctrl + C
```

---

# 4. Clean the Root Layout Metadata

## The Target

We are going to update the browser tab title and description for the application.

---

## The Concept

A root layout is a wrapper around all pages.

Think of it like the frame around every page in a notebook.

In Next.js, the root layout lives here:

```txt
app/layout.tsx
```

The metadata exported from this file controls browser and SEO information such as:

- Page title
- Description
- Search preview text

---

## The Implementation

Open:

```txt
app/layout.tsx
```

Replace the entire file with this code.

```tsx
// app/layout.tsx

import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "GreyMatter Ledger",
  description:
    "A Singapore-ready double-entry accounting app built with Next.js, TypeScript, Tailwind CSS, Clerk, Drizzle ORM, Neon Postgres, and Inngest.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en-SG">
      <body>{children}</body>
    </html>
  );
}
```

Important detail:

```tsx
<html lang="en-SG">
```

The `lang` attribute tells browsers and assistive technologies that the app content is English for Singapore.

This is a small but professional accessibility detail.

This line renders whichever page is active:

```tsx
<body>{children}</body>
```

In plain language, `children` means:

> Put the current page content here.

So when you visit `/`, `children` is the homepage from `app/page.tsx`.

Later, when you visit `/dashboard`, `children` will be the dashboard page.

---

## The Verification

Start the server if it is not already running:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000
```

Look at your browser tab.

It should say:

```txt
GreyMatter Ledger
```

You can also verify the page source metadata.

In your browser:

```txt
Right click -> View Page Source
```

Search for:

```txt
GreyMatter Ledger
```

You should find it in the document metadata.

---

# 5. Normalize Global Styles

## The Target

We are going to clean up the global CSS file so our app has predictable default styling.

---

## The Concept

Global CSS applies to the entire application.

Tailwind handles most component styling, but global CSS is still useful for base defaults such as:

- Body margin
- Font smoothing
- Background color
- Text rendering

Think of global CSS as setting the default lighting and flooring in a building. Individual rooms can still have their own furniture, but the base environment is consistent.

---

## The Implementation

Open:

```txt
app/globals.css
```

Replace the entire file with this code.

```css
/* app/globals.css */

@import "tailwindcss";

/*
  The :root selector targets the top-level HTML document.
  We define basic color variables here so the app has consistent defaults.
*/
:root {
  --background: #020617;
  --foreground: #f8fafc;
}

/*
  The universal box-sizing rule makes layout math easier.

  Without this, width calculations can feel surprising because padding and
  border may be added outside an element's declared width.

  With border-box, the declared width includes content + padding + border.
*/
* {
  box-sizing: border-box;
}

/*
  Remove default browser margin so our layouts begin exactly at the edge of
  the viewport unless we intentionally add spacing.
*/
html,
body {
  margin: 0;
  min-height: 100%;
}

/*
  Apply safe global defaults.

  We avoid putting too much styling here because Tailwind classes will handle
  most component-level design.
*/
body {
  background: var(--background);
  color: var(--foreground);
  font-family:
    Arial,
    Helvetica,
    sans-serif;
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

/*
  Make form controls inherit the page font by default.
*/
button,
input,
textarea,
select {
  font: inherit;
}
```

This file uses Tailwind v4-style import:

```css
@import "tailwindcss";
```

If your generated project uses a different Tailwind setup, keep this version for the series. The modern `create-next-app` Tailwind setup supports this pattern.

---

## The Verification

Run:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000
```

The page should still look correct.

Now run the linter:

```bash
pnpm lint
```

You should see no errors.

Depending on your tooling, you may see output like:

```txt
✔ No ESLint warnings or errors
```

or simply a successful command exit.

If the command exits without an error, this step is complete.

---

# 6. Add a Project README

## The Target

We are going to replace the default README with one that describes GreyMatter Ledger.

---

## The Concept

A README is the front page of your codebase.

It helps future you, teammates, reviewers, and deployment tools understand what the project is.

A good README answers:

- What is this?
- What stack does it use?
- How do I run it locally?
- What commands are available?

---

## The Implementation

Open:

```txt
README.md
```

Replace the entire file with this content.

```md
# GreyMatter Ledger

GreyMatter Ledger is a Singapore-ready double-entry accounting web application built with Next.js, TypeScript, Tailwind CSS, Clerk, Drizzle ORM, Neon Postgres, Inngest, and Vercel.

This project is built as a comprehensive tutorial series. It starts from an empty folder and grows into a professional-grade accounting application.

## Core Goals

- Enforce double-entry accounting rules
- Support multiple company workspaces
- Keep each organization's accounting data isolated
- Build GST-aware invoicing and reporting workflows
- Generate financial reports from journal entries
- Provide auditability for important accounting actions
- Support bank import and reconciliation
- Automate reminders and recurring invoices with background jobs

## Tech Stack

- Next.js
- React
- TypeScript
- Tailwind CSS
- Clerk
- Neon Postgres
- Drizzle ORM
- Inngest
- Vercel

## Local Development

Install dependencies:

```bash
pnpm install
```

Start the development server:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000
```

## Useful Scripts

```bash
pnpm dev
pnpm build
pnpm start
pnpm lint
```

## Accounting Principle

The central rule of the application is:

```txt
Total debits must equal total credits.
```

Every invoice, bill, payment, adjustment, and bank transaction will eventually be represented as a balanced journal entry.
```

---

## The Verification

Run:

```bash
cat README.md
```

On Windows PowerShell, use:

```powershell
Get-Content README.md
```

You should see the GreyMatter Ledger README content.

This does not affect the app in the browser, but it improves the project documentation.

---

# 7. Confirm TypeScript Configuration

## The Target

We are going to inspect TypeScript configuration and confirm that the import alias works.

The import alias is:

```txt
@/*
```

It allows us to import files from the project root more cleanly later.

---

## The Concept

Without an import alias, deeply nested files can require ugly relative imports.

For example:

```ts
import { formatMoney } from "../../../lib/money";
```

With the `@/*` alias, we can write:

```ts
import { formatMoney } from "@/lib/money";
```

This is easier to read and safer to move around.

We will use this heavily once the app grows.

---

## The Implementation

Open:

```txt
tsconfig.json
```

You should see configuration similar to this.

Do **not** worry if your generated file has slightly different formatting.

Make sure it includes the `paths` setting shown below.

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "react-jsx",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts",
    ".next/dev/types/**/*.ts"
  ],
  "exclude": ["node_modules"]
}
```

If your file does not have this section:

```json
"paths": {
  "@/*": ["./*"]
}
```

add it inside `compilerOptions`.

Be careful to keep valid JSON commas.

---

## The Verification

Run:

```bash
pnpm build
```

A successful build should finish without TypeScript errors.

You should see output similar to:

```txt
Creating an optimized production build ...
Compiled successfully
```

If the build succeeds, TypeScript is configured correctly.

---

# 8. Add a Basic Utility File to Test the Alias

## The Target

We are going to create our first `lib` utility file and import it using the `@/*` alias.

This confirms our project structure is ready for reusable code.

---

## The Concept

A utility file contains reusable helper functions.

For example, later we will create helpers for:

- Money formatting
- Date formatting
- Validation
- Authorization checks
- Accounting calculations

Instead of writing formatting logic directly inside pages, we put shared logic in `lib`.

Think of `lib` like a toolbox.

Pages should not rebuild the same tool every time. They should reach into the toolbox.

---

## The Implementation

Create a new folder:

```bash
mkdir lib
```

Now create this file:

```txt
lib/app-info.ts
```

Add the following code.

```ts
// lib/app-info.ts

export const appInfo = {
  name: "GreyMatter Ledger",
  tagline: "Singapore-ready double-entry accounting",
  description:
    "A professional accounting application built with Next.js, TypeScript, Tailwind CSS, Clerk, Drizzle ORM, Neon Postgres, and Inngest.",
} as const;
```

Now update:

```txt
app/page.tsx
```

Replace the entire file with this version, which imports from `@/lib/app-info`.

```tsx
// app/page.tsx

import { appInfo } from "@/lib/app-info";

export default function HomePage() {
  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <section className="mx-auto flex min-h-screen w-full max-w-6xl flex-col items-center justify-center px-6 py-24 text-center">
        <div className="mb-6 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-4 py-2 text-sm font-medium text-emerald-300">
          Project foundation ready
        </div>

        <p className="mb-4 text-sm font-semibold uppercase tracking-[0.3em] text-emerald-300">
          {appInfo.tagline}
        </p>

        <h1 className="max-w-4xl text-5xl font-bold tracking-tight sm:text-6xl">
          {appInfo.name}
        </h1>

        <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-300">
          {appInfo.description}
        </p>

        <div className="mt-10 grid gap-4 sm:grid-cols-3">
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-left">
            <h2 className="text-base font-semibold text-white">
              Double-entry core
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-400">
              Every financial event will become a balanced journal entry.
            </p>
          </div>

          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-left">
            <h2 className="text-base font-semibold text-white">
              Multi-company ready
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-400">
              Each organization will have isolated accounting data.
            </p>
          </div>

          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-left">
            <h2 className="text-base font-semibold text-white">
              Singapore-focused
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-400">
              GST, reports, CPF estimates, and local business workflows.
            </p>
          </div>
        </div>
      </section>
    </main>
  );
}
```

The important line is:

```tsx
import { appInfo } from "@/lib/app-info";
```

This confirms that `@` maps to the project root.

---

## The Verification

Run:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000
```

You should still see:

```txt
GreyMatter Ledger
```

You should also see the tagline:

```txt
Singapore-ready double-entry accounting
```

Now run:

```bash
pnpm build
```

If the build succeeds, the alias works correctly.

---

# 9. Add a Basic Money Utility

## The Target

We are going to add our first accounting-related helper: a money formatter.

This is small, but important. Accounting applications display money constantly.

---

## The Concept

We will store money as integer cents.

For example:

```txt
S$109.00 = 10900 cents
```

But users do not want to see:

```txt
10900
```

They want to see:

```txt
S$109.00
```

So we need a reusable formatter.

Think of this function like a translator. The database speaks in cents. Humans speak in dollars.

---

## The Implementation

Create this file:

```txt
lib/money.ts
```

Add the following code.

```ts
// lib/money.ts

/**
 * The application stores money as integer cents.
 *
 * Example:
 *   S$109.00 is stored as 10900
 *
 * This avoids floating-point rounding bugs in JavaScript.
 */
export type MoneyCents = number;

/**
 * Formats integer cents as Singapore Dollar currency.
 *
 * Example:
 *   formatMoney(10900) -> "S$109.00"
 */
export function formatMoney(amountCents: MoneyCents): string {
  if (!Number.isInteger(amountCents)) {
    throw new Error("Money amounts must be stored as integer cents.");
  }

  return new Intl.NumberFormat("en-SG", {
    style: "currency",
    currency: "SGD",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amountCents / 100);
}

/**
 * Converts a dollar string or number into integer cents.
 *
 * Examples:
 *   dollarsToCents("109.00") -> 10900
 *   dollarsToCents(109)      -> 10900
 *
 * This helper is intentionally strict because financial inputs should not be
 * silently accepted when ambiguous.
 */
export function dollarsToCents(value: string | number): MoneyCents {
  const normalized =
    typeof value === "number" ? value.toFixed(2) : value.trim();

  if (!/^-?\d+(\.\d{1,2})?$/.test(normalized)) {
    throw new Error(
      "Invalid money amount. Use a whole number or up to two decimal places.",
    );
  }

  const [wholePart, decimalPart = ""] = normalized.split(".");
  const sign = wholePart.startsWith("-") ? -1 : 1;
  const absoluteWholePart = wholePart.replace("-", "");

  const centsPart = decimalPart.padEnd(2, "0");
  const wholeCents = Number.parseInt(absoluteWholePart, 10) * 100;
  const fractionalCents = Number.parseInt(centsPart, 10);

  return sign * (wholeCents + fractionalCents);
}
```

Now update the homepage to use `formatMoney`.

Open:

```txt
app/page.tsx
```

Replace it with this version.

```tsx
// app/page.tsx

import { appInfo } from "@/lib/app-info";
import { formatMoney } from "@/lib/money";

export default function HomePage() {
  const exampleInvoiceTotal = formatMoney(10900);

  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <section className="mx-auto flex min-h-screen w-full max-w-6xl flex-col items-center justify-center px-6 py-24 text-center">
        <div className="mb-6 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-4 py-2 text-sm font-medium text-emerald-300">
          Project foundation ready
        </div>

        <p className="mb-4 text-sm font-semibold uppercase tracking-[0.3em] text-emerald-300">
          {appInfo.tagline}
        </p>

        <h1 className="max-w-4xl text-5xl font-bold tracking-tight sm:text-6xl">
          {appInfo.name}
        </h1>

        <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-300">
          {appInfo.description}
        </p>

        <div className="mt-8 rounded-2xl border border-emerald-400/20 bg-emerald-400/10 px-6 py-4 text-sm text-emerald-100">
          Example accounting amount:{" "}
          <span className="font-semibold">{exampleInvoiceTotal}</span>
        </div>

        <div className="mt-10 grid gap-4 sm:grid-cols-3">
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-left">
            <h2 className="text-base font-semibold text-white">
              Double-entry core
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-400">
              Every financial event will become a balanced journal entry.
            </p>
          </div>

          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-left">
            <h2 className="text-base font-semibold text-white">
              Multi-company ready
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-400">
              Each organization will have isolated accounting data.
            </p>
          </div>

          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-left">
            <h2 className="text-base font-semibold text-white">
              Singapore-focused
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-400">
              GST, reports, CPF estimates, and local business workflows.
            </p>
          </div>
        </div>
      </section>
    </main>
  );
}
```

The important part is:

```tsx
const exampleInvoiceTotal = formatMoney(10900);
```

This proves our utility works inside a page.

---

## The Verification

Run:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000
```

You should see:

```txt
Example accounting amount: S$109.00
```

Now run:

```bash
pnpm build
```

The build should succeed.

---

# 10. Add a Basic Project Health Check Script

## The Target

We are going to add a convenient command that checks the project before we move on.

---

## The Concept

As the project grows, we need a quick way to ask:

> Is the codebase still healthy?

For now, a healthy project means:

- TypeScript can compile through Next.js
- ESLint passes
- The production build succeeds

Later, we will add automated tests.

---

## The Implementation

Open:

```txt
package.json
```

Update the `scripts` section.

Your full `package.json` will have version numbers generated by your machine, so do not blindly replace the whole file if your dependency versions differ.

Only update the `"scripts"` block to look like this:

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "check": "pnpm lint && pnpm build"
  }
}
```

For clarity, your `package.json` should look similar to this:

```json
{
  "name": "greymatter-ledger",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "check": "pnpm lint && pnpm build"
  },
  "dependencies": {
    "next": "latest",
    "react": "latest",
    "react-dom": "latest"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "latest",
    "@types/node": "latest",
    "@types/react": "latest",
    "@types/react-dom": "latest",
    "eslint": "latest",
    "eslint-config-next": "latest",
    "tailwindcss": "latest",
    "typescript": "latest"
  }
}
```

Again, your actual dependency version numbers may not say `"latest"`. That is okay.

The key addition is:

```json
"check": "pnpm lint && pnpm build"
```

This command runs linting first. If linting succeeds, it runs the production build.

---

## The Verification

Run:

```bash
pnpm check
```

You should see linting complete, then the production build complete.

A successful result means your foundation is healthy.

---

# 11. Initialize Git

## The Target

We are going to initialize Git version control.

---

## The Concept

Git is a history system for your code.

It lets you save checkpoints as the project evolves.

A commit is like a named save point in a game. If something breaks later, you can inspect what changed or return to a previous state.

---

## The Implementation

First, confirm you are inside the project folder:

```bash
pwd
```

The path should end with:

```txt
greymatter-ledger
```

Now initialize Git:

```bash
git init
```

Check the generated `.gitignore` file:

```bash
cat .gitignore
```

On Windows PowerShell:

```powershell
Get-Content .gitignore
```

Make sure it includes entries similar to:

```gitignore
node_modules
.next
.env*
```

If your `.gitignore` is missing, create one:

```txt
.gitignore
```

Use this complete content:

```gitignore
# dependencies
/node_modules
/.pnp
.pnp.*

# testing
/coverage

# next.js
/.next/
/out/

# production
/build

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# env files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts
```

Now stage your files:

```bash
git add .
```

Create your first commit:

```bash
git commit -m "Create Next.js project foundation"
```

---

## The Verification

Run:

```bash
git status
```

You should see:

```txt
nothing to commit, working tree clean
```

If Git asks for your name and email, configure them:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Then run the commit command again:

```bash
git commit -m "Create Next.js project foundation"
```

---

# Common Errors and Fixes

## Error: `pnpm create next-app@latest` fails

Try updating pnpm:

```bash
npm install --global pnpm
```

Then run:

```bash
pnpm create next-app@latest greymatter-ledger
```

If the folder already exists from a failed attempt, remove it carefully:

macOS/Linux:

```bash
rm -rf greymatter-ledger
```

Windows PowerShell:

```powershell
Remove-Item -Recurse -Force greymatter-ledger
```

Then rerun the create command.

---

## Error: Port 3000 is already in use

Another app is already running on port `3000`.

Next.js may offer another port, such as:

```txt
http://localhost:3001
```

You can use that URL.

Or stop the other process.

macOS/Linux:

```bash
lsof -i :3000
```

Then kill the process using the printed PID:

```bash
kill -9 PID_HERE
```

Windows PowerShell:

```powershell
netstat -ano | findstr :3000
```

Then stop the process:

```powershell
taskkill /PID PID_HERE /F
```

---

## Error: `code .` does not open VS Code

Open VS Code manually.

Then choose:

```txt
File -> Open Folder
```

Select:

```txt
greymatter-ledger
```

To install the `code` command inside VS Code:

macOS:

```txt
Command Palette -> Shell Command: Install 'code' command in PATH
```

Windows usually installs this automatically if selected during VS Code installation.

---

## Error: `pnpm lint` behaves differently from the tutorial

Different Next.js versions may generate slightly different lint scripts.

The important thing is that this command runs without errors:

```bash
pnpm lint
```

If your generated script is missing, add it to `package.json`:

```json
"lint": "eslint"
```

Then run:

```bash
pnpm lint
```

---

## Error: `@/lib/app-info` cannot be resolved

Check `tsconfig.json`.

Make sure this exists inside `compilerOptions`:

```json
"paths": {
  "@/*": ["./*"]
}
```

Then restart the dev server:

```bash
Ctrl + C
pnpm dev
```

Some editor TypeScript servers also need a restart.

In VS Code:

```txt
Command Palette -> TypeScript: Restart TS Server
```

---

## Error: Money formatter throws an error

The formatter expects integer cents.

This is correct:

```ts
formatMoney(10900);
```

This is incorrect:

```ts
formatMoney(109.99);
```

Why?

Because `109.99` is a dollar amount, not cents.

Use:

```ts
formatMoney(10999);
```

or convert first:

```ts
formatMoney(dollarsToCents("109.99"));
```

---

# Phase 1 Reference — Next.js Project Basics

## `app/page.tsx`

This file renders the homepage at:

```txt
/
```

A minimal page looks like:

```tsx
export default function HomePage() {
  return <main>Hello</main>;
}
```

---

## `app/layout.tsx`

This file wraps pages.

A minimal layout looks like:

```tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

Every route appears inside `{children}`.

---

## Tailwind CSS

Tailwind lets us style using utility classes.

Example:

```tsx
<div className="rounded-xl bg-white p-6 shadow-sm">
  Content
</div>
```

This means:

```txt
rounded-xl  Large rounded corners
bg-white    White background
p-6         Padding
shadow-sm   Small shadow
```

---

## TypeScript

TypeScript helps catch errors before runtime.

For example:

```ts
function addCents(a: number, b: number): number {
  return a + b;
}
```

If you accidentally pass text:

```ts
addCents("100", 200);
```

TypeScript warns you.

That is extremely useful in accounting software where data correctness matters.

---

## Import Alias

This:

```ts
import { formatMoney } from "@/lib/money";
```

is cleaner than:

```ts
import { formatMoney } from "../../lib/money";
```

We will use `@/` throughout the project.

---

# Part 2 Completion Checklist

You are ready for Part 3 if:

- [ ] The `greymatter-ledger` folder exists
- [ ] `pnpm dev` starts the local server
- [ ] `http://localhost:3000` shows the GreyMatter Ledger homepage
- [ ] `app/page.tsx` has been replaced
- [ ] `app/layout.tsx` has been cleaned
- [ ] `app/globals.css` has been normalized
- [ ] `lib/app-info.ts` exists
- [ ] `lib/money.ts` exists
- [ ] `formatMoney(10900)` displays `S$109.00`
- [ ] `pnpm check` succeeds
- [ ] Git has an initial commit
