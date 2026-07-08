# Part 1: Dev Environment & Project Setup

Previous: Part 0 (Introduction & Architecture).

In this part we verify prerequisites (Node version first — non-negotiable for Next.js 16), scaffold the Next.js 16 app, confirm Tailwind CSS v4's CSS-first config, and install shadcn/ui with the components we'll need throughout the series.

## 1. Concept

Everything else sits on top of:
- Node.js 20.9+ (22 LTS recommended) — Next.js 16 will refuse to run on Node 18.
- A Next.js 16 App Router project with TypeScript, using Turbopack (default dev/build bundler).
- Tailwind CSS v4 — CSS-first configuration, no `tailwind.config.js`.
- shadcn/ui components (Button, Input, Card, Dialog, Table, Badge, Avatar, Textarea, Dropdown, Sonner/Toast).

Clerk/Prisma/tRPC come in Parts 2–4. This part is just "get a styled Next.js 16 app running locally."

## 2. Step 0: verify your Node version

```bash
node -v
```

Need **v20.9.0 or higher**. If you see v18.x or lower:

```bash
nvm install 22
nvm use 22
node -v
```

Do not proceed until confirmed — nearly every "weird" error later traces back to an outdated Node version.

## 3. Other prerequisites

1. **pnpm**: `npm install -g pnpm`
2. **Git**: `git --version`
3. VS Code (recommended)
4. Free accounts (create now): neon.tech, clerk.com, uploadthing.com, resend.com, stripe.com, vercel.com

## 4. Scaffold the app

```bash
pnpm create next-app@latest freelancer-portal
```

Prompts: TypeScript Yes, ESLint Yes, Tailwind CSS Yes, `src/` directory Yes, App Router Yes, Turbopack Yes (default), import alias `@/*` Yes.

```bash
cd freelancer-portal
pnpm dev
```

Visit `http://localhost:3000` — default starter page, served via Turbopack.

## 5. Confirm Tailwind CSS v4 setup

Check `src/app/globals.css` — should contain:

```css
@import "tailwindcss";
```

No `tailwind.config.js`. Custom theme tokens go in `globals.css` via `@theme`/`@utility` blocks.

## 6. Clean up the starter

```tsx
// src/app/page.tsx
export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4">
      <h1 className="text-3xl font-bold">Freelancer Client Portal</h1>
      <p className="text-muted-foreground">Under construction — building it step by step.</p>
    </main>
  );
}
```

## 7. Install shadcn/ui

```bash
pnpm dlx shadcn@latest init
```

Prompts: Default style, Slate base color, CSS variables Yes.

```bash
pnpm dlx shadcn@latest add button input label card dialog table badge avatar textarea dropdown-menu separator tabs sonner form select
```

## 8. Add the Toaster

```tsx
// src/app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/sonner";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Freelancer Client Portal",
  description: "Manage clients, proposals, invoices, and payments in one place.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>
        {children}
        <Toaster richColors position="top-right" />
      </body>
    </html>
  );
}
```

## 9. Project folder structure (target)

```
freelancer-portal/
├─ prisma/schema.prisma
├─ src/
│  ├─ app/
│  │  ├─ admin/ (layout, page, clients/, projects/, proposals/, invoices/)
│  │  ├─ portal/ (layout, page, projects/, proposals/, invoices/)
│  │  ├─ api/ (trpc/[trpc]/, uploadthing/, webhooks/stripe/, webhooks/clerk/)
│  │  ├─ sign-in/[[...sign-in]]/, sign-up/[[...sign-up]]/
│  │  ├─ layout.tsx, page.tsx
│  ├─ components/ui/, components/(feature)
│  ├─ server/ (api/routers/, api/root.ts, api/trpc.ts, db.ts, email/)
│  ├─ lib/ (utils.ts, uploadthing.ts)
│  └─ trpc/ (client.tsx, server.ts)
├─ .env.local, package.json, tsconfig.json
```

No `tailwind.config.js` — see Appendix F for the finalized tree.

## 10. Environment variables file

```bash
# .env.local
DATABASE_URL=
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
CLERK_WEBHOOK_SECRET=
UPLOADTHING_TOKEN=
RESEND_API_KEY=
EMAIL_FROM=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

Add to `.gitignore` (default in Next.js — double check).

## 11. Set the Node engines field

```json
// package.json
{
  "engines": { "node": ">=20.9.0" }
}
```

## 12. Initialize git

```bash
git init
git add .
git commit -m "chore: scaffold Next.js 16 app with Tailwind v4 + shadcn/ui"
git remote add origin <your-repo-url>
git push -u origin main
```

## Checkpoint

- [ ] `node -v` reports 20.9+
- [ ] `pnpm dev` runs, confirms Turbopack
- [ ] Homepage shows heading
- [ ] No `tailwind.config.js` anywhere
- [ ] `src/components/ui/` has all requested components
- [ ] `.env.local` exists, git-ignored
- [ ] Project committed

## Next

Continue to **Part 2: Auth with Clerk**.
