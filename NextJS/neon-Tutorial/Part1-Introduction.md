# Neon Tutorial - Part 1: What Is Neon & Why Use It

## 1. What Is Neon?

Neon is a **serverless Postgres** platform. It's 100% wire-compatible with vanilla PostgreSQL (you can `psql` into it, use any Postgres driver/ORM), but the underlying architecture separates **storage** from **compute**:

```
┌─────────────────────────────────────────────────┐
│                  Neon Project                    │
│                                                   │
│   ┌───────────────┐        ┌──────────────────┐  │
│   │  Compute Node │◄──────►│  Storage (Pageserver) │
│   │ (Postgres)    │        │  - durable, versioned │
│   │ scales to 0   │        │  - branchable (CoW)   │
│   └───────────────┘        └──────────────────┘  │
│                                                   │
│   Branches share storage until data diverges     │
└─────────────────────────────────────────────────┘
```

Because storage and compute are decoupled:

- **Compute can scale to zero** when nobody is querying the database — you pay (or use free-tier hours) only while the compute node is actually awake.
- **Branches are cheap and instant** — a new branch is a copy-on-write pointer into the same storage, not a physical copy of all your data. Branching a 50 GB database takes seconds and costs almost nothing until the branch's data diverges from the parent.

## 2. Why This Matters for a Next.js App

| Next.js Need | How Neon Helps |
|---|---|
| Serverless functions / Route Handlers spin up per-request | Neon's HTTP driver (`@neondatabase/serverless`) connects over HTTP, not a long-lived TCP socket — no connection-pool exhaustion from serverless cold starts |
| Edge Runtime (`export const runtime = "edge"`) | Neon's driver works in edge runtimes (Cloudflare Workers, Vercel Edge) where raw TCP Postgres connections are impossible |
| Preview deployments per pull request | Neon branches map 1:1 to Vercel preview deployments — each PR gets its own isolated database automatically (Part 7) |
| Local dev without Docker | No `docker-compose.yml`, no local Postgres install — just a connection string to a real cloud Postgres instance |
| Cost while prototyping | Scale-to-zero means an idle side-project costs nothing beyond storage, which is free up to the tier limit |

## 3. The Neon Free Tier (What You Actually Get)

> Tier details are correct as of this writing but Neon can change free-tier numbers over time — always confirm current limits on [neon.tech/pricing](https://neon.tech/pricing) before relying on them for production planning.

| Resource | Free Tier Allowance |
|---|---|
| Projects | 1 |
| Branches per project | 10 |
| Storage | 0.5 GB per branch (shared via copy-on-write until diverged) |
| Compute | Generous monthly compute hours, autosuspend after ~5 min idle |
| Compute size | Shared vCPU (0.25 vCPU class) |
| Data transfer | Included allowance per month |
| Point-in-time restore window | Limited (shorter than paid tiers) |

This is more than sufficient for:
- Learning/tutorials (this series)
- Side projects and MVPs
- Preview/staging environments for small teams

## 4. Key Vocabulary You'll See Throughout This Series

| Term | Meaning |
|---|---|
| **Project** | The top-level container in Neon — roughly equivalent to "one database server" |
| **Branch** | An isolated, independently-connectable copy of your database's schema+data (like a Git branch, but for data) |
| **Main branch (`main` / `production`)** | The default/primary branch, typically what your production app connects to |
| **Compute endpoint** | The actual running Postgres process attached to a branch; can autosuspend/resume |
| **Pooled connection** | A connection string routed through Neon's built-in PgBouncer-style pooler — required for serverless/many-short-lived-connections workloads |
| **Direct connection** | A connection string that talks straight to the compute endpoint — used for migrations and admin tasks that need session-level features (e.g. `SET`, long transactions) |

## 5. Architecture We'll Build in This Series

```
┌──────────────────────┐        ┌───────────────────────┐
│   Next.js 16 App      │        │       Neon Project     │
│  (App Router)         │        │                         │
│                        │        │  ┌───────────────────┐  │
│  Server Components ───┼───────►│  │  main (production) │  │
│  Server Actions       │ pooled │  └───────────────────┘  │
│  Route Handlers      │  conn  │  ┌───────────────────┐  │
│                        │───────►│  │  preview/pr-123    │  │
│  (raw driver / Prisma │ direct │  │  (branch, ephemeral)│  │
│   / Drizzle — Parts   │ conn   │  └───────────────────┘  │
│   4–6)                 │(migr.)│                         │
└──────────────────────┘        └───────────────────────┘
```

We'll connect three different ways over the series so you can choose what fits your project:

```ts
// Option A — raw SQL via the official serverless driver (Part 4)
import { neon } from "@neondatabase/serverless";
const sql = neon(process.env.DATABASE_URL!);
const rows = await sql`SELECT * FROM notes WHERE id = ${id}`;
```

```ts
// Option B — Prisma ORM with the Neon adapter (Part 5)
import { PrismaClient } from "@/generated/prisma";
import { PrismaNeon } from "@prisma/adapter-neon";
const adapter = new PrismaNeon({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });
```

```ts
// Option C — Drizzle ORM over the neon-http driver (Part 6)
import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql);
```

## 6. Checkpoint

Before moving to Part 2, make sure you understand:

- [ ] Neon separates storage from compute, enabling scale-to-zero and instant branching
- [ ] Neon is 100% Postgres-compatible — any Postgres driver/ORM works
- [ ] Free tier = 1 project, up to 10 branches, 0.5 GB storage/branch, autosuspending compute
- [ ] Pooled connections are for your app's runtime queries; direct connections are for migrations
- [ ] This series will connect via three methods: raw driver, Prisma, and Drizzle

## Next

**Part 2: Creating a Free Neon Project & Connecting Locally** — sign up, create your first project and branch, and get your connection strings.
