## Part 1: The Blueprint

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
**Goal of this part:** Understand the architecture we're building (Orbit), set up the dev environment, scaffold the Next.js 16 project, and establish the `lib/` directory convention every later part will slot into.

---

### 1. Concept Explanation

#### 1.1 Why these four services, together?

A common mistake in "modern stack" tutorials is picking tools because they're trendy, not because they solve distinct problems. Here, each service maps to a *distinct architectural responsibility*, and none of them overlap:

- **Clerk** answers: *who is this?* (Authentication + Authorization)
- **Sanity** answers: *what do we want to say / offer?* (Structured, editorial content that changes independently of code deploys)
- **Neon + Prisma** answers: *what is the current state of the business?* (Transactional, relational, ACID-guaranteed data)
- **Inngest** answers: *what should happen next, reliably?* (Event-driven side effects, decoupled from the request/response cycle)

If you ever find yourself putting transactional data in Sanity, or editorial marketing copy in Postgres, or doing slow multi-step work synchronously inside a Server Action — that's a sign the architecture boundary has been crossed. This series enforces the boundary deliberately so the lesson sticks.

#### 1.2 The `lib/` abstraction principle

Every external service gets **one file that owns constructing its client**, and nothing else in the codebase is allowed to construct that client directly. This is the single most important architectural habit this series teaches:

```
lib/
  clerk/
    roles.ts          # role-checking helpers built on Clerk's auth()
  sanity/
    client.ts         # the ONE sanity client instance + typed fetch helper
    queries.ts         # GROQ queries, colocated and typed
  db/
    prisma.ts          # the ONE PrismaClient singleton
  inngest/
    client.ts          # the ONE Inngest client instance
    functions/         # individual background functions
  validations/
    project.ts         # Zod schemas, shared by Server Actions + Route Handlers + Inngest payloads
```

Why this matters: in Part 5 you'll write a Server Action that touches all four services in one function. If each service's client were constructed ad-hoc wherever needed, you'd get duplicated connections (expensive on Neon's free tier, which limits concurrent connections), inconsistent config, and no single point to add logging/error handling. One owning file per service = one seam to test, mock, and harden.

#### 1.3 Environment variable strategy

We separate env vars into three trust tiers, because mixing them is the single most common security mistake in Next.js apps:

1. **Public (`NEXT_PUBLIC_*`)** — bundled into client JS. Only Clerk's publishable key and Sanity's project ID/dataset belong here (they are safe to expose by design).
2. **Server-only secrets** — never prefixed `NEXT_PUBLIC_`, only readable in Server Components, Server Actions, Route Handlers, and Inngest functions (all server-only execution contexts). Includes Clerk secret key, Sanity API token (write access), Neon connection string, Inngest signing/event keys.
3. **Build-time vs runtime** — Vercel injects env vars at build AND runtime for serverless functions; we'll rely on that in Part 10, but locally everything comes from `.env.local`.

We'll build the full `.env.local` template in Appendix A, but each part introduces its own slice of variables as needed, so nothing feels abstract.

---

### 2. Implementation

#### 2.1 Prerequisites

Install once, globally:

```bash
node -v   # must be >= 20.9 (Next.js 16 requirement); 22 LTS recommended
corepack enable
corepack prepare pnpm@latest --activate
pnpm -v
```

Accounts to create now (all free tier, no credit card required for any of them):

- https://clerk.com
- https://sanity.io
- https://neon.tech
- https://inngest.com
- https://vercel.com
- A GitHub account (for Part 10)

#### 2.2 Scaffold the project

```bash
pnpm create next-app@latest orbit --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --turbopack
cd orbit
```

When prompted, accept defaults. This gives you Next.js 16 with the App Router, `src/` directory, Turbopack as the default dev/build bundler, and Tailwind CSS v4 pre-wired (CSS-first — check that `src/app/globals.css` starts with `@import "tailwindcss";` rather than the old `@tailwind base;` directives; that's the v4 signature).

Verify the Next.js version:

```bash
pnpm list next
# next 16.x.x
```

#### 2.3 Project skeleton

Create the full folder structure up front so later parts just fill in files:

```bash
mkdir -p src/lib/clerk src/lib/sanity src/lib/db src/lib/inngest/functions src/lib/validations
mkdir -p src/components/ui src/components/dashboard src/components/shared
mkdir -p src/app/\(auth\)/sign-in/\[\[...sign-in\]\] src/app/\(auth\)/sign-up/\[\[...sign-up\]\]
mkdir -p src/app/\(dashboard\)/dashboard
mkdir -p sanity/schemaTypes
touch src/proxy.ts
```

Resulting top-level shape (full tree with every file lands in Appendix A once all parts exist):

```
orbit/
├── src/
│   ├── app/
│   │   ├── (auth)/
│   │   │   ├── sign-in/[[...sign-in]]/page.tsx
│   │   │   └── sign-up/[[...sign-up]]/page.tsx
│   │   ├── (dashboard)/
│   │   │   └── dashboard/page.tsx
│   │   ├── layout.tsx
│   │   └── globals.css
│   ├── components/
│   │   ├── ui/            (shadcn/ui generated components — Part 4)
│   │   ├── dashboard/
│   │   └── shared/
│   ├── lib/
│   │   ├── clerk/roles.ts
│   │   ├── sanity/client.ts
│   │   ├── sanity/queries.ts
│   │   ├── db/prisma.ts
│   │   ├── inngest/client.ts
│   │   ├── inngest/functions/
│   │   └── validations/
│   └── proxy.ts
├── sanity/
│   └── schemaTypes/
├── prisma/
│   └── schema.prisma       (Part 3)
├── .env.local
└── package.json
```

#### 2.4 Base dependencies for this part

We install the full dependency set incrementally across parts, but let's lock the package manager behavior now:

```bash
# .npmrc equivalent for pnpm strictness (optional but recommended for monorepo-like clarity)
echo "auto-install-peers=true" >> .npmrc
echo "strict-peer-dependencies=false" >> .npmrc
```

Add a couple of housekeeping scripts to `package.json` now, since we'll need them from Part 3 onward:

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit"
  }
}
```

#### 2.5 The env var placeholder file

Create `.env.local` now with empty placeholders — we'll fill each block in as its part arrives. Committing the *shape* early avoids "where do I even put this" confusion later.

```bash
# .env.local

# --- Clerk (Part 2) ---
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up

# --- Sanity (Part 2) ---
NEXT_PUBLIC_SANITY_PROJECT_ID=
NEXT_PUBLIC_SANITY_DATASET=production
SANITY_API_TOKEN=

# --- Neon + Prisma (Part 3) ---
DATABASE_URL=

# --- Inngest (Part 6) ---
INNGEST_EVENT_KEY=
INNGEST_SIGNING_KEY=
```

Add `.env.local` to `.gitignore` (Next.js scaffolds this by default — verify it's present):

```bash
grep ".env" .gitignore
```

#### 2.6 A note on `src/proxy.ts`

Next.js 16 renamed the middleware file/convention to `proxy.ts`. We create the empty file now as a placeholder; Part 2 fills it with Clerk's route-protection logic:

```ts
// src/proxy.ts
// Populated in Part 2 with clerkMiddleware(). Do not also create src/middleware.ts —
// Next.js 16 will throw a build error if both exist.
```

---

### 3. Checkpoint

At the end of Part 1 you should be able to run:

```bash
pnpm dev
```

...and see the default Next.js 16 welcome page at `http://localhost:3000`, with:

- ✅ `pnpm list next` showing version 16.x
- ✅ Full `src/lib/*`, `src/components/*`, `sanity/*` folder skeleton in place
- ✅ `.env.local` present (git-ignored) with the placeholder keys listed above
- ✅ `src/proxy.ts` created (empty, to be filled in Part 2)
- ✅ Accounts created on Clerk, Sanity, Neon, Inngest, Vercel

---

### 4. Troubleshooting

- **`pnpm create next-app` asks about Turbopack for build too:** Next.js 16 defaults Turbopack for `dev`; you may be prompted separately about enabling it for `build` — accept, it's stable in 16 and we use it in Part 9/10.
- **Node version errors on install:** Next.js 16 hard-requires Node 20.9+. Use `nvm install 22 && nvm use 22` if your system Node is older.
- **`src/app/globals.css` still has `@tailwind base/components/utilities`:** you scaffolded with an older cached create-next-app template — delete `node_modules`, clear pnpm store (`pnpm store prune`), and re-run the create command to get Tailwind v4's CSS-first import.
- **Mac/Linux glob errors on the `mkdir -p` with `\[\[...sign-in\]\]`:** if your shell doesn't like the escaped brackets, just `mkdir -p "src/app/(auth)/sign-in/[[...sign-in]]"` with quotes instead of backslash-escapes.

---

Next: **"Ecosystem Tutorial - Part 2: Identity & Content"**
