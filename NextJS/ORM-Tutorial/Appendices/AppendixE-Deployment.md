# Appendix E: Deployment Checklist (Vercel + CI/CD Migrations)

## 1. Pre-Deploy Checklist

| Item | Prisma | Drizzle |
|---|---|---|
| Env vars set in Vercel dashboard | `DATABASE_URL`, `DIRECT_URL` | `DATABASE_URL`, `DIRECT_URL` |
| `DATABASE_URL` uses pooled (`-pooler`) host | ✅ | ✅ |
| `DIRECT_URL` uses non-pooled host | ✅ | ✅ |
| Migrations committed to repo | `prisma/migrations/**` | `drizzle/migrations/**` |
| Client build step wired in | `postinstall: prisma generate` | none needed — no codegen |
| No `drizzle-kit push` used in prod flow | N/A | ✅ confirm only `generate`+`migrate` are used |

## 2. Vercel Build Command Overrides

### Prisma

```bash
# vercel.json or Project Settings -> Build & Development Settings
```

```json
// vercel.json
{
  "buildCommand": "prisma generate && next build",
  "installCommand": "pnpm install"
}
```

> `prisma generate` is also wired as a `postinstall` script (Appendix B) as a safety net — Vercel runs `pnpm install` which triggers it automatically. The explicit `buildCommand` override is a belt-and-suspenders approach for CI environments that skip lifecycle scripts.

### Drizzle

```json
// vercel.json
{
  "buildCommand": "next build",
  "installCommand": "pnpm install"
}
```

> No codegen step needed — Drizzle's types come directly from `schema.ts`, which is already part of the build.

## 3. Running Migrations as Part of Deployment

Migrations should **not** run automatically on every `next build` (concurrent deploys/previews could race). Instead, run them as an explicit, separate step.

### Option A — GitHub Actions (Recommended for Both)

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  migrate-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v4
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm

      - run: pnpm install --frozen-lockfile

      # --- Prisma path ---
      - name: Run Prisma migrations
        if: ${{ env.ORM == 'prisma' }}
        run: pnpm dlx prisma migrate deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          DIRECT_URL: ${{ secrets.DIRECT_URL }}

      # --- Drizzle path ---
      - name: Run Drizzle migrations
        if: ${{ env.ORM == 'drizzle' }}
        run: pnpm tsx src/db/migrate.ts
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          DIRECT_URL: ${{ secrets.DIRECT_URL }}

      - name: Trigger Vercel deploy
        run: curl -X POST "${{ secrets.VERCEL_DEPLOY_HOOK_URL }}"
```

> `prisma migrate deploy` (unlike `migrate dev`) never prompts, never generates new migration files, and never resets the DB — it strictly applies pending migrations already committed to the repo. This is the only migration command that belongs in a production pipeline.

### Option B — Manual Pre-Deploy Step (Smaller Teams)

```bash
# Run locally or from a one-off script before pushing to main
DATABASE_URL=$PROD_DATABASE_URL DIRECT_URL=$PROD_DIRECT_URL \
  pnpm dlx prisma migrate deploy      # Prisma

DATABASE_URL=$PROD_DATABASE_URL DIRECT_URL=$PROD_DIRECT_URL \
  pnpm tsx src/db/migrate.ts          # Drizzle
```

## 4. Zero-Downtime Migration Practices

| Practice | Why |
|---|---|
| Additive migrations first (add nullable column), backfill, then add `NOT NULL`/constraints in a follow-up migration | Avoids locking large tables or breaking currently-running app instances mid-deploy |
| Never rename a column in one step | Old running instances (from the previous deploy) will error on the missing old column name — instead: add new column → dual-write → backfill → drop old column in a later deploy |
| Avoid long-running `CREATE INDEX` without `CONCURRENTLY` on large tables | Blocks writes; both Prisma and Drizzle let you hand-edit generated SQL to add `CONCURRENTLY` before applying |
| Always run migrations against `DIRECT_URL`, never the pooled URL | PgBouncer (transaction pooling mode) breaks some DDL/session-level operations |

```sql
-- Example: manually editing a Drizzle-generated migration to add CONCURRENTLY
-- (safe because you review generated SQL before applying — a key Drizzle advantage)
CREATE INDEX CONCURRENTLY IF NOT EXISTS "posts_author_id_idx" ON "posts" ("author_id");
```

## 5. Runtime Configuration Per Route (Edge vs Node)

```ts
// src/app/posts/page.tsx
// Only needed if you explicitly want this route on the Edge Runtime.
// Drizzle (neon-http) supports this out of the box; Prisma needs the
// @prisma/adapter-neon driver adapter (already configured in Part 2/Appendix A1).
export const runtime = "edge"; // or omit for default Node.js runtime
```

| Scenario | Recommended runtime |
|---|---|
| Simple reads, low-latency global routes, Drizzle | `edge` |
| Complex Prisma queries, raw SQL, heavier transaction logic | Default Node.js runtime |
| Any route using `txDb` (Drizzle WebSocket pool) | Node.js runtime — WebSocket pooling behaves better with long-lived server processes than pure edge functions |

## 6. Post-Deploy Smoke Test

```bash
# Quick manual check after every deploy touching the schema
curl -s https://your-app.vercel.app/posts | grep -q "New Post" && echo "OK" || echo "FAILED"
```

```ts
// Or an automated Playwright smoke test run against the production URL
// e2e/smoke.spec.ts
import { test, expect } from "@playwright/test";

test("posts page loads and lists at least one post", async ({ page }) => {
  await page.goto(process.env.PROD_URL ?? "http://localhost:3000");
  await page.goto("/posts");
  await expect(page.locator("li")).not.toHaveCount(0);
});
```

## 7. Rollback Plan

| Situation | Prisma | Drizzle |
|---|---|---|
| Bad migration deployed, app broken | Write and deploy a new forward migration that reverses the change (never edit/delete an already-applied migration file) | Same principle — write a new migration file that reverses the change |
| Need to inspect what actually ran in prod | `prisma migrate status` | Check `drizzle/migrations/` + your migrations tracking table (`__drizzle_migrations`) |
| App code deployed before matching migration | Revert the Vercel deployment to the previous build (Vercel dashboard "Instant Rollback") while you fix the migration | Same |

---

This concludes the **ORM in Next.js 16: Prisma & Drizzle** series — all 8 parts plus 6 appendices (A1, A2, B, C, D, E).
