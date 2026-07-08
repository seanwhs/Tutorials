# Part 1: Project Setup

Goal: create the Next.js 16 project, install dependencies, and lay out the folder structure we'll use for the rest of the course.

Prerequisites:

- Node.js 22 LTS (or at least 20.9+) — check with `node -v`
- npm
- a code editor (VS Code recommended)
- a terminal

---

## 1. Create the app

```bash
npx create-next-app@latest hdb-resale-api
```

Answer the prompts exactly like this:

```txt
Would you like to use TypeScript?      Yes
Would you like to use ESLint?          Yes
Would you like to use Tailwind CSS?    Yes
Would you like your code inside a src/ directory?   Yes
Would you like to use App Router?      Yes
Would you like to use Turbopack for next dev?   Yes
Would you like to customize the import alias?   Yes -> @/*
```

Move into the project:

```bash
cd hdb-resale-api
```

Confirm you're on Next.js 16:

```bash
npm list next
```

You should see something like `next@16.x.x`. If not, see Troubleshooting below.

---

## 2. Install dependencies

```bash
npm install @upstash/redis @upstash/ratelimit zod nanoid fumadocs-ui fumadocs-mdx fumadocs-core lucide-react
```

What each package is for:

- `@upstash/redis` — HTTP-based Redis client (no persistent TCP connections needed, ideal for serverless).
- `@upstash/ratelimit` — rate limiting built on top of Upstash Redis.
- `zod` — runtime validation for query params and env vars.
- `nanoid` — generates short random IDs for API keys.
- `fumadocs-ui`, `fumadocs-mdx`, `fumadocs-core` — the documentation site (Part 10).
- `lucide-react` — small icon set for the dashboard UI.

---

## 3. Create the folder structure

```bash
mkdir -p src/components/ui
mkdir -p src/lib/auth
mkdir -p src/lib/api-keys
mkdir -p src/lib/hdb
mkdir -p src/lib/usage
mkdir -p src/app/dashboard/keys
mkdir -p src/app/dashboard/usage
mkdir -p src/app/api/auth/login
mkdir -p src/app/api/auth/logout
mkdir -p src/app/api/keys/revoke
mkdir -p src/app/api/v1/resale-prices
mkdir -p src/app/login
mkdir -p content/docs
mkdir -p scripts
```

---

## 4. Replace the home page

Open `src/app/page.tsx` and replace its contents:

```tsx
import Link from "next/link";

export default function HomePage() {
  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <section className="mx-auto flex min-h-screen max-w-5xl flex-col items-start justify-center px-6 py-20">
        <p className="mb-4 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-4 py-1 text-sm text-emerald-200">
          Singapore public housing data, developer friendly
        </p>
        <h1 className="max-w-3xl text-5xl font-bold tracking-tight md:text-7xl">
          HDB Resale Price API
        </h1>
        <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-300">
          A simple, fast API for Singapore HDB resale flat transaction data — built for
          dashboards, research tools, and property apps.
        </p>
        <div className="mt-10 flex gap-4">
          <Link
            href="/login"
            className="rounded-xl bg-emerald-400 px-5 py-3 font-semibold text-slate-950 hover:bg-emerald-300"
          >
            Get an API key
          </Link>
          <Link
            href="/docs"
            className="rounded-xl border border-slate-700 px-5 py-3 font-semibold text-slate-100 hover:bg-slate-900"
          >
            Read the docs
          </Link>
        </div>
      </section>
    </main>
  );
}
```

---

## 5. Update the root layout metadata

Open `src/app/layout.tsx` and replace its contents:

```tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "HDB Resale Price API",
  description: "A public API and usage dashboard for Singapore HDB resale flat prices.",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

---

## 6. Run it

```bash
npm run dev
```

Visit `http://localhost:3000` — you should see the landing page.

---

## 7. First commit

```bash
git init
git add .
git commit -m "Initial Next.js 16 project setup for HDB Resale API"
```

---

## Checkpoint

- [ ] `npm list next` shows version 16.x.
- [ ] `npm run dev` runs without errors.
- [ ] Home page renders the HDB Resale Price API landing page.
- [ ] All folders from step 3 exist.

---

## Troubleshooting

**`npm list next` shows an older version**
Run `npm install next@latest react@latest react-dom@latest`, then re-check.

**Turbopack prompt didn't appear**
Some `create-next-app` versions default to Turbopack automatically on Next 16 — that's fine, no action needed.

**Tailwind classes have no effect**
Confirm `src/app/globals.css` is imported by `src/app/layout.tsx` (it is, by default, via `import "./globals.css";`).

**`Module not found: Can't resolve '@/...'`**
Check `tsconfig.json` has `"paths": { "@/*": ["./src/*"] }` under `compilerOptions`. `create-next-app` sets this automatically when you choose the `@/*` import alias.

---

Ready for **Part 2 — Environment Variables and Upstash Redis** ?
