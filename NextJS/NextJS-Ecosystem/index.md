## Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem

A 10-part, code-heavy, production-oriented tutorial series teaching how to architect a **multi-service SaaS application** by orchestrating four best-in-class, free-tier/open-source platforms around Next.js 16.

### The Sample Application: "Orbit"

Every part builds toward one coherent product: **Orbit**, a client engagement & knowledge portal for a fictional digital agency.

- **Clerk (Identity):** Agency staff and clients sign in. Roles (`ADMIN`, `MEMBER`, `CLIENT`) live in Clerk `publicMetadata` and gate UI + Server Actions.
- **Sanity (Structured Content):** `servicePackage` (productized service offerings) and `article` (knowledge-base posts), editable by non-technical staff via a hosted Studio, zero redeploys.
- **Neon + Prisma (Transactional State):** `Client`, `Project`, `Task`, `Comment` — the normalized, relational system of record.
- **Inngest (Background Orchestration):** The seam between the above three — a Sanity `servicePackage` + a Clerk `userId` become a Prisma `Project`, which fires an event triggering durable onboarding work, plus a weekly digest cron.

**Throughline:** Sanity answers "what is offered," Prisma answers "what is happening," Clerk answers "who is doing it," and Inngest answers "what happens next, reliably, without blocking the user."

### Full Note Index (read in this order)

1. **Ecosystem Tutorial - Part 1: The Blueprint** — Architecture, environment variable strategy, project skeleton, `lib/` design.
2. **Ecosystem Tutorial - Part 2: Identity & Content** — Clerk auth (sign-in/up, roles, `proxy.ts` middleware).
3. **Ecosystem Tutorial - Part 2b: Content (Sanity Setup)** — Sanity schemas, client, GROQ queries, embedded Studio. (Continuation of Part 2.)
4. **Ecosystem Tutorial - Part 3: The Persistence Layer** — Neon provisioning, Prisma schema/migrations, the `db` singleton with the Neon driver adapter.
5. **Ecosystem Tutorial - Part 4: Styling & UI Components** — Tailwind CSS v4 (CSS-first) + shadcn/ui, dashboard shell, role-aware sidebar.
6. **Ecosystem Tutorial - Part 5: Server-Side Orchestration** — The flagship Server Action bridging Clerk + Sanity + Prisma in one transaction, firing an Inngest event.
7. **Ecosystem Tutorial - Part 6: Event-Driven Background Jobs** — Inngest client, the `project/requested` handler (step-based, durable), the weekly cron digest, local dev server.
8. **Ecosystem Tutorial - Part 7: Advanced Data Fetching** — `"use cache"`, `cacheTag`, `revalidateTag`/`revalidatePath`, Sanity webhook-driven invalidation, Suspense streaming.
9. **Ecosystem Tutorial - Part 8: Security & Validation** — Centralized Zod schemas, a validation wrapper, row-level Prisma authorization, hardened webhook/Inngest boundaries, basic rate limiting.
10. **Ecosystem Tutorial - Part 9: Performance & Optimization** — Sanity image optimization via `next/image`, code-splitting the Studio out of the main bundle, lean Prisma selects, bundle analysis, Lighthouse pass.
11. **Ecosystem Tutorial - Part 10: Production Deployment** — GitHub → Vercel, environment variable scoping (Prod/Preview/Dev), Neon preview branching, re-registering Inngest/Sanity webhooks for production, full smoke test.
12. **Ecosystem Tutorial - Appendices (A, B, C)** — Full project file tree, `.env.local` template, the Free & Open-Source Service Matrix, and the condensed Deployment Checklist.

### Baseline Stack (locked for the whole series)

- **Framework:** Next.js 16, App Router, TypeScript, Turbopack (default bundler)
- **Package manager:** pnpm
- **Auth:** Clerk (`@clerk/nextjs`) — free tier (up to 10,000 MAU)
- **CMS:** Sanity (`next-sanity`, embedded Studio) — free tier (2 non-admin users, 3 datasets)
- **Database:** Neon serverless Postgres — free tier (0.5 GB storage, database branching)
- **ORM:** Prisma ORM 6+ with `@prisma/adapter-neon` for serverless-friendly connections
- **Background jobs:** Inngest — free "Hobby" tier
- **Styling:** Tailwind CSS v4 (CSS-first config, no `tailwind.config.ts`)
- **Components:** shadcn/ui (copied source, not a runtime dependency)
- **Validation:** Zod
- **Deployment:** Vercel free "Hobby" tier

> ⚠️ Next.js 16 baseline reminders used throughout: Node.js 20.9+/22 LTS required; all dynamic APIs (`params`, `searchParams`, Clerk's `auth()`/`currentUser()`, `headers()`, `cookies()`) are **async** and must be awaited; middleware convention is `src/proxy.ts`, not `middleware.ts`.

### How Each Part Is Structured

Every part note contains: **Concept Explanation → Implementation (step-by-step code) → Checkpoint → Troubleshooting**. Parts 5–8 are the architectural core (orchestration, events, caching, security); Parts 9–10 harden and ship the app.
