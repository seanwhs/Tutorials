# Part 1: Dev Environment & Project Setup

Previous: Part 0 (Introduction & Architecture). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

We scaffold a Next.js 16 app with TypeScript and Tailwind CSS v4, and set up the folder structure we'll use for the rest of the series. No Stripe yet — that's Part 2.

## 2. Prerequisites

1. **Node.js 20.9+ or 22 LTS** — Next.js 16 requires this. Check with:
   ```bash
   node -v
   ```
   If it's older, download the latest LTS from nodejs.org.
2. **npm** (ships with Node) — or pnpm/yarn if you prefer; this series uses `npm` in examples.
3. **Git** — check with `git --version`.
4. A code editor (VS Code recommended).
5. A free Stripe account — sign up now at https://dashboard.stripe.com/register (no credit card required to use test mode).

## 3. Scaffold the app

```bash
npx create-next-app@latest acme-shop
```

When prompted, choose:
```
Would you like to use TypeScript?          Yes
Would you like to use ESLint?              Yes
Would you like to use Tailwind CSS?        Yes
Would you like to use `src/` directory?    Yes
Would you like to use App Router?          Yes  (required)
Would you like to use Turbopack? (for next dev)  Yes  (default in Next.js 16)
Would you like to customize the import alias (@/*)?  No (keep default)
```

```bash
cd acme-shop
npm run dev
```

Visit `http://localhost:3000` — you should see the default Next.js starter page. Confirm your Next.js version:

```bash
npm list next
```

You should see `next@16.x.x`.

## 4. Confirm Tailwind v4 setup

Next.js 16's scaffolder installs Tailwind CSS v4, which uses a CSS-first config. Open `src/app/globals.css` — you should see something like:

```css
/* src/app/globals.css */
@import "tailwindcss";
```

There is no `tailwind.config.js` by default in v4 — theme customization happens in CSS via `@theme` blocks if you ever need it. We won't need heavy customization in this series.

## 5. Clean up the starter homepage

```tsx
// src/app/page.tsx
export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-5xl flex-col items-center justify-center gap-4 px-4">
      <h1 className="text-3xl font-bold text-gray-900">Acme Shop</h1>
      <p className="text-gray-500">Under construction — building it step by step.</p>
    </main>
  );
}
```

## 6. Set up the root layout

```tsx
// src/app/layout.tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Acme Shop",
  description: "A demo storefront built with Next.js 16, Tailwind CSS, and Stripe.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-gray-50 antialiased">{children}</body>
    </html>
  );
}
```

## 7. Add a simple shared Nav component

```tsx
// src/components/Nav.tsx
import Link from "next/link";

export default function Nav() {
  return (
    <nav className="border-b border-gray-200 bg-white">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
        <Link href="/" className="text-lg font-bold text-gray-900">
          Acme Shop
        </Link>
        <div className="flex items-center gap-6 text-sm font-medium text-gray-600">
          <Link href="/" className="hover:text-gray-900">
            Shop
          </Link>
          <Link href="/cart" className="hover:text-gray-900">
            Cart
          </Link>
          <Link href="/orders" className="hover:text-gray-900">
            Orders
          </Link>
          <Link href="/account" className="hover:text-gray-900">
            Account
          </Link>
        </div>
      </div>
    </nav>
  );
}
```

Wire it into the layout:

```tsx
// src/app/layout.tsx
import type { Metadata } from "next";
import "./globals.css";
import Nav from "@/components/Nav";

export const metadata: Metadata = {
  title: "Acme Shop",
  description: "A demo storefront built with Next.js 16, Tailwind CSS, and Stripe.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-gray-50 antialiased">
        <Nav />
        {children}
      </body>
    </html>
  );
}
```

The `/cart`, `/orders`, and `/account` links will 404 for now — that's expected, we build those pages in later parts.

## 8. Target folder structure

We'll grow into this structure over the series:

```
acme-shop/
├─ prisma/
│  └─ schema.prisma            (Part 7)
├─ src/
│  ├─ app/
│  │  ├─ page.tsx               (product catalog, Part 3)
│  │  ├─ layout.tsx
│  │  ├─ globals.css
│  │  ├─ cart/page.tsx          (Part 5)
│  │  ├─ success/page.tsx       (Part 4)
│  │  ├─ cancel/page.tsx        (Part 4)
│  │  ├─ orders/page.tsx        (Part 10)
│  │  ├─ account/page.tsx       (Part 12)
│  │  └─ api/
│  │     ├─ checkout/route.ts              (Part 3)
│  │     ├─ checkout-cart/route.ts         (Part 6)
│  │     ├─ checkout-subscription/route.ts (Part 11)
│  │     ├─ portal/route.ts                (Part 12)
│  │     └─ webhooks/stripe/route.ts       (Part 8)
│  ├─ components/
│  │  ├─ Nav.tsx
│  │  ├─ ProductCard.tsx        (Part 3)
│  │  └─ CartProvider.tsx       (Part 5)
│  ├─ lib/
│  │  ├─ stripe.ts              (Part 2)
│  │  ├─ db.ts                  (Part 7)
│  │  └─ products.ts            (Part 3)
├─ .env.local
├─ package.json
└─ tsconfig.json
```

See **Appendix A** for the finalized version of every file.

## 9. Environment variables placeholder file

Create `.env.local` in the project root now (values filled in as we reach each part):

```bash
# .env.local

# Stripe (Part 2)
STRIPE_SECRET_KEY=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
STRIPE_WEBHOOK_SECRET=

# App URL (used to build redirect URLs)
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Database (Part 7)
DATABASE_URL="file:./dev.db"
```

Next.js ignores `.env.local` in git by default (check your `.gitignore` includes `.env*.local`).

## 10. Initialize git

```bash
git init
git add .
git commit -m "chore: scaffold Next.js 16 app with Tailwind v4"
```

Optional: create a GitHub repo and push now so it's ready for Vercel's Git integration in Part 14.

```bash
git remote add origin <your-repo-url>
git push -u origin main
```

## Checkpoint

- [ ] `node -v` shows 20.9+ or 22.x.
- [ ] `npm run dev` runs with no errors, Turbopack is used automatically.
- [ ] `npm list next` shows a 16.x version.
- [ ] Homepage shows "Acme Shop" heading and a nav bar with Shop/Cart/Orders/Account links.
- [ ] `.env.local` exists with placeholder keys and is git-ignored.
- [ ] Project committed to git.

## Next

Continue to **Part 2: Stripe Account Setup, API Keys, and the SDK**.
