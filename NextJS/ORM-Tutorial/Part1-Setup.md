# Part 1: Project Setup & ORM Comparison

## 1. Prerequisites

| Requirement | Version |
|---|---|
| Node.js | 20.9+ or 22 LTS (Node 18 is EOL, unsupported) |
| Package manager | pnpm (recommended) |
| Database | PostgreSQL — we use [Neon](https://neon.tech) free serverless Postgres |

## 2. Scaffold the Next.js 16 App

```bash
pnpm create next-app@latest orm-nextjs-demo \
  --typescript \
  --eslint \
  --tailwind \
  --app \
  --src-dir \
  --turbopack \
  --import-alias "@/*"

cd orm-nextjs-demo
```

This gives you a Next.js 16 project with the App Router, Turbopack (default bundler now), and a `src/` layout.

## 3. Create a Free Postgres Database (Neon)

1. Sign up at neon.tech (free tier).
2. Create a project, e.g. `orm-demo`.
3. Copy **two** connection strings from the dashboard:
   - **Pooled connection** (for runtime queries — goes through PgBouncer, works well in serverless)
   - **Direct connection** (for running migrations — some migration tools need a non-pooled connection)

## 4. Environment Variables

```bash
# .env
# Used at runtime by both Prisma and Drizzle client instances
DATABASE_URL="postgresql://<user>:<pass>@<pooled-host>/<db>?sslmode=require"

# Used only for running migrations (Prisma migrate / drizzle-kit)
DIRECT_URL="postgresql://<user>:<pass>@<direct-host>/<db>?sslmode=require"
```

```bash
# .gitignore — make sure this is present
.env
.env.local
```

> **Why two URLs?** Neon (and most serverless Postgres providers) pool connections through PgBouncer for app runtime traffic. Schema migrations use `CREATE INDEX CONCURRENTLY`-style operations and long-lived transactions that don't play well with connection poolers, so migration tools should talk to the database directly.

## 5. Decision Matrix: Prisma vs Drizzle

| Criteria | Prisma | Drizzle |
|---|---|---|
| Schema definition | Custom DSL (`schema.prisma`) | Plain TypeScript (`schema.ts`) |
| Codegen | Yes — `prisma generate` builds a client into `node_modules/.prisma` (or custom output) | No codegen — types are inferred directly from your TS schema |
| Query style | Fluent object API (`prisma.post.findMany({ where: ... })`) | SQL-like builder (`db.select().from(posts).where(...)`) — closer to raw SQL |
| Bundle size / cold start | Larger client, historically slower cold starts on edge | Very lightweight, designed for edge/serverless from day one |
| Migrations | `prisma migrate dev` / `deploy`, strong migration history table | `drizzle-kit generate` + `migrate`, or `drizzle-kit push` for prototyping |
| Studio/GUI | Prisma Studio (`prisma studio`) — excellent visual DB browser | `drizzle-kit studio` (via Drizzle Studio, web-based) |
| Raw SQL escape hatch | `prisma.$queryRaw` | Native — you're basically already close to SQL |
| Learning curve | Gentle, very good docs & errors | Slightly steeper if unfamiliar with SQL, but very transparent |
| Edge Runtime support | Needs driver adapters (e.g. `@prisma/adapter-neon`) for full edge compatibility | First-class edge support out of the box with `neon-http`/`neon-websockets` drivers |
| Best for | Teams wanting strong conventions, rapid CRUD scaffolding, GUI tooling | Teams wanting SQL transparency, minimal overhead, edge-first apps |

## 6. Recommended Project Structure (works for either ORM)

```
src/
  app/
    posts/
      page.tsx              # Server Component list view
      [id]/
        page.tsx             # Server Component detail view (params is a Promise!)
      actions.ts              # "use server" Server Actions for mutations
  lib/
    db.ts                     # Singleton DB client (Prisma OR Drizzle instance)
  generated/                  # (Prisma only, if custom output configured)
prisma/
  schema.prisma                # (Prisma only)
drizzle/
  schema.ts                    # (Drizzle only)
  migrations/                  # (Drizzle only, generated SQL files)
```

## 7. Shared Table We'll Model in Both ORMs

Every part builds the same **Posts** feature so you can compare code 1:1.

```sql
-- Conceptual shape we'll implement in both Prisma and Drizzle
CREATE TABLE "Post" (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  title       TEXT NOT NULL,
  content     TEXT NOT NULL,
  published   BOOLEAN NOT NULL DEFAULT false,
  "authorId"  TEXT NOT NULL REFERENCES "Author"(id),
  "createdAt" TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE "Author" (
  id    TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name  TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE
);
```

Continue to **Part 2 (Prisma Setup & Schema)** or skip to **Part 5 (Drizzle Setup & Schema)** depending on which ORM you want first.
