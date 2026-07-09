# ORM in Next.js 16: Prisma & Drizzle — Complete Tutorial Series

A code-heavy, beginner-friendly series teaching how to integrate **Prisma** and **Drizzle ORM** into a **Next.js 16 (App Router)** application, using **PostgreSQL** as the database for both, so the two ORMs can be compared apples-to-apples.

## Stack Used Throughout

| Layer | Choice | Why |
|---|---|---|
| Framework | Next.js 16 (App Router, Turbopack default) | Latest stable, Node 20.9+/22 LTS required (Node 18 is EOL) |
| Language | TypeScript | Both ORMs are TS-first, type inference is the whole point |
| Database | PostgreSQL (Neon free serverless Postgres) | Free tier, works great with both ORMs, supports pooled + direct connections |
| Package manager | pnpm | Fast, disk-efficient; commands shown also work with npm/yarn |
| ORM #1 | Prisma 6+ | Schema-first, generates a client, huge ecosystem, Prisma Studio GUI |
| ORM #2 | Drizzle ORM (latest) | Code-first (TS schema = source of truth), SQL-like API, zero codegen step, lightweight, edge-friendly |

> Note: You do **not** need to build both ORMs into the same app. Each part is self-contained with its own setup instructions — clone the repo twice (or use git branches) if you want to run Prisma and Drizzle side by side.

## Series Structure

| Part | Title | Covers |
|---|---|---|
| 1 | Project Setup & ORM Comparison | Next.js 16 scaffold, Neon Postgres setup, env vars, decision matrix |
| 2 | Prisma Setup & Schema | Installing Prisma, `schema.prisma`, migrations, generating the client |
| 3 | Prisma CRUD with Server Actions | Full CRUD app (Posts) using Server Actions + Server Components |
| 4 | Prisma Relations, Transactions & Connection Pooling | 1:N and N:N relations, `$transaction`, Neon adapter for serverless/edge |
| 5 | Drizzle Setup & Schema | Installing Drizzle, `drizzle-kit`, schema files, migrations |
| 6 | Drizzle CRUD with Server Actions | Same Posts app rebuilt in Drizzle for direct comparison |
| 7 | Drizzle Relations, Transactions & Migrations | Relations API, `db.transaction`, `drizzle-kit push` vs `generate` |
| 8 | Prisma vs Drizzle — Decision Guide | Performance, bundle size, DX, edge runtime support, migration path |

## Appendices

| Appendix | Title | Covers |
|---|---|---|
| A1 | Full Codebase (Prisma Variant) | Complete file tree, every file reproduced in full for copy-paste reference |
| A2 | Full Codebase (Drizzle Variant) | Complete file tree, every file reproduced in full for copy-paste reference |
| B | package.json & Environment Reference | Full dependency lists for both variants, env var tables, Neon connection string anatomy |
| C | Troubleshooting & Common Errors | Errors common to both ORMs plus ORM-specific gotchas (pooling, params-as-Promise, transactions, etc.) with fixes |
| D | Testing Strategy for Both ORMs | Unit/integration/Server Action/E2E test examples for Prisma and Drizzle against a real test DB |
| E | Deployment Checklist | Vercel build config, CI/CD migration pipelines, zero-downtime migration practices, rollback plan |

## Critical Next.js 16 Pattern (applies to every part)

Route params and search params are now **Promises** and must be awaited:

```tsx
// app/posts/[id]/page.tsx
type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function PostPage({ params }: PageProps) {
  const { id } = await params; // must await in Next.js 16
  // ...fetch post by id using either ORM
}
```

Both ORMs are used **exclusively on the server** (Server Components, Server Actions, Route Handlers) — never import a database client into a file with `"use client"` at the top.

## Where to Start

Read Part 1 first regardless of which ORM you ultimately choose — it sets up the shared Next.js project and Neon database both later parts depend on. Once you've completed a track (Parts 2–4 for Prisma, or Parts 5–7 for Drizzle), use **Appendix A1/A2** as your copy-paste reference for the complete working codebase, and consult **Appendix C** anytime something breaks.
