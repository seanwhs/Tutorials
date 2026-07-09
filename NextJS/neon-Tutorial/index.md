# Neon Tutorial

# Using Neon for Free in Next.js 16 — Complete Tutorial Series

A code-heavy, beginner-friendly series teaching how to use **Neon** (serverless Postgres) as the database layer for a **Next.js 16** (App Router) application — entirely on free tiers.

All notes in this series are titled with the **"Neon Tutorial - "** prefix. Read them in order.

## Stack Used Throughout

| Layer | Choice | Why | Cost |
|---|---|---|---|
| Framework | Next.js 16 (App Router, Turbopack default) | Latest stable; Node 20.9+/22 LTS required (Node 18 is EOL) | Free |
| Language | TypeScript | Type-safe queries/schemas | Free |
| Database | **Neon** (serverless Postgres) | Scale-to-zero, instant branching, generous free tier, native Vercel integration | Free tier |
| Driver (raw) | `@neondatabase/serverless` | HTTP/WebSocket driver built for serverless & edge runtimes | Free (OSS) |
| ORM #1 | Prisma 6+ with `@prisma/adapter-neon` | Most popular, schema-first, Prisma Studio GUI | Free (OSS) |
| ORM #2 | Drizzle ORM | Lightweight, SQL-like, zero-codegen, edge-friendly | Free (OSS) |
| Package manager | pnpm | Fast, disk-efficient (npm/yarn also work) | Free |
| Hosting | Vercel (Hobby tier) | Native Neon integration, preview branch automation | Free tier |

> **Standing constraint for this entire series:** every tool, tier, and service used is free. Neon's free tier (as of this writing) includes 1 project, 10 branches, 0.5 GB storage, and generous compute hours with scale-to-zero — more than enough to build and deploy a real app.

## Why Neon Specifically?

- **Serverless-native**: no manual server to provision or manage; connects over HTTP/WebSocket, ideal for serverless functions and edge runtimes.
- **Scale-to-zero**: your database "sleeps" when idle and wakes on the next query — no cost/compute burned while you're not using it.
- **Instant branching**: create a full copy-on-write branch of your database (schema + data) in seconds — perfect for per-PR preview environments, migrations testing, or just experimenting safely.
- **First-class Vercel integration**: one click links a Neon project to a Vercel project and automatically provisions a database branch for every preview deployment.
- **No Docker, no local Postgres install**: you get a real Postgres instance in the cloud in under a minute.

## Series Structure

| Part | Title | Covers |
|---|---|---|
| 1 | What Is Neon & Why Use It | Serverless Postgres concepts, free tier limits, branching model, compute vs storage |
| 2 | Creating a Free Neon Project & Connecting Locally | Sign-up, project/branch creation, `psql`/Neon SQL Editor, connection strings explained |
| 3 | Next.js 16 Project Setup & Environment Variables | Scaffolding the app, `.env.local`, zod-validated env, project structure |
| 4 | Connecting Neon via `@neondatabase/serverless` | Raw SQL queries from Server Components/Route Handlers, the HTTP driver vs WebSocket `Pool` |
| 5 | Neon + Prisma ORM Integration | `schema.prisma`, `@prisma/adapter-neon`, migrations, CRUD via Server Actions |
| 6 | Neon + Drizzle ORM Integration | `drizzle-orm/neon-http`, schema-as-code, `drizzle-kit`, CRUD via Server Actions |
| 7 | Database Branching for Preview Deployments | Neon branches, Vercel-Neon integration, per-PR ephemeral databases, branch reset |
| 8 | Connection Pooling, Edge Runtime & Performance | Pooled vs direct connection strings, cold starts, `runtime = "edge"` compatibility, query latency tips |
| 9 | Deploying to Vercel Free Tier with Neon | Production env vars, running migrations in CI/CD, verifying the deployed app |
| 10 | Free Tier Limits, Monitoring & Scaling | What "free" actually includes, the Neon dashboard/Monitoring tab, when/how to upgrade |
| — | Conclusion | Recap, architecture diagram, next steps |

## Appendices

| Appendix | Title | Covers |
|---|---|---|
| A | Full Codebase Reference (split into 3 notes: 1 of 3 config/env/lib, 2 of 3 Server Actions/schemas, 3 of 3 app pages/routes) | Every file in its final state: schema files, `db.ts` clients, Server Actions, `package.json` |
| B | Environment Variables Reference | Every env var used across the series, where to get it, which part introduces it |
| C | Troubleshooting Guide | Common errors (SSL, pooled vs direct, cold start timeouts, migration drift) and fixes |
| D | Neon CLI & SQL Cheat Sheet | `neonctl` commands, useful SQL snippets, branch management one-liners |

## Critical Next.js 16 Pattern (applies to every part)

Route params and search params are **Promises** in Next.js 16 and must be awaited:

```tsx
// app/notes/[id]/page.tsx
type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function NotePage({ params }: PageProps) {
  const { id } = await params; // must await in Next.js 16
  // ...query Neon for the note with this id
}
```

Database clients (raw driver, Prisma, or Drizzle) are used **exclusively on the server** — Server Components, Server Actions, and Route Handlers. Never import a database client into a file that starts with `"use client"`.

## Where to Start

Read **Part 1** first to understand Neon's model, then **Part 2** to actually create your free database — every later part depends on it.
