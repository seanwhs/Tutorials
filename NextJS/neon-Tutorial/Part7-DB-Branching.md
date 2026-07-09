# Neon Tutorial - Part 7: Database Branching for Preview Deployments

This is Neon's headline feature: instant, cheap, copy-on-write database branches. This part connects Neon to Vercel so every pull request/preview deployment automatically gets its own isolated database.

## 1. Branching Recap (from Part 1)

A branch is a full copy-on-write snapshot of your database's schema **and data** at the moment of creation. It shares underlying storage with its parent until data diverges, so creating one is nearly instant and nearly free.

```
main (production data)
 └── preview/pr-142     ← created automatically when PR #142 opens
 └── preview/pr-150     ← created automatically when PR #150 opens
 └── dev/alice          ← a personal branch a teammate creates manually
```

## 2. Create a Branch Manually (Console)

1. In the Neon console, go to **Branches** → **Create Branch**.
2. Choose a parent branch (usually `main`).
3. Name it, e.g. `dev/manual-test`.
4. Neon gives you a **new connection string** scoped to that branch only.

```bash
# Branch-specific pooled connection string — completely isolated from main
DATABASE_URL="postgresql://neondb_owner:<password>@ep-yyyy-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require"
```

Any writes you make on this branch never touch `main` — perfect for testing a risky migration or seeding fake data.

## 3. Create a Branch via the CLI

```bash
neonctl branches create \
  --project-id <your-project-id> \
  --name dev/manual-test \
  --parent main

# Get the connection string for that branch
neonctl connection-string dev/manual-test --project-id <your-project-id>
```

```bash
# Delete it when done — instant, no lingering cost
neonctl branches delete dev/manual-test --project-id <your-project-id>
```

## 4. The Vercel-Neon Integration (Automatic Per-PR Branches)

This is the real payoff. Instead of manually creating/deleting branches, link Neon to Vercel once and it's fully automated.

1. In your Vercel project dashboard, go to **Integrations** (or **Storage** tab) → search **Neon** → **Add Integration**.
2. Authorize Vercel to access your Neon account and select your project (`neon-nextjs16-tutorial`).
3. Choose which Vercel environments get Neon branches:
   - **Production** → connects to your `main` Neon branch
   - **Preview** → Neon automatically creates a **new branch per Git branch/PR**
   - **Development** → optional, for local `vercel env pull`

4. The integration automatically injects `DATABASE_URL` and `DIRECT_URL` (or your chosen names) into the matching Vercel environment for you — no manual copy-pasting per deployment.

## 5. What Happens on Each PR

```
Git: open PR "feature/add-search" ──► Vercel: new Preview Deployment
                                        │
                                        ▼
                          Neon: creates branch "preview/feature-add-search"
                                (copy-on-write from main, has real schema+data)
                                        │
                                        ▼
                    Vercel injects DATABASE_URL pointing at THIS branch
                    into THIS preview deployment's environment
```

Your Server Actions and queries don't change at all — they just read `env.DATABASE_URL`, which now transparently points at an isolated database per PR. You can test destructive migrations, seed weird data, or run a full E2E suite against a preview branch with zero risk to production.

```
Git: PR merged/closed ──► Vercel: preview deployment torn down
                                  │
                                  ▼
                    Neon: branch auto-deleted (configurable) or left
                          for manual cleanup, depending on integration settings
```

## 6. Running Migrations Against Preview Branches in CI

Add a build step so each preview deployment applies pending migrations to *its own* branch before the app boots:

```json
// package.json
{
  "scripts": {
    "build": "prisma migrate deploy && next build"
  }
}
```

```ts
// Or, if using Drizzle, migrate programmatically at build time
// scripts/migrate.ts
import { drizzle } from "drizzle-orm/neon-http";
import { migrate } from "drizzle-orm/neon-http/migrator";
import { neon } from "@neondatabase/serverless";

async function main() {
  const sql = neon(process.env.DATABASE_URL!);
  const db = drizzle(sql);
  await migrate(db, { migrationsFolder: "./drizzle/migrations" });
  console.log("Migrations applied.");
}

main();
```

```json
{
  "scripts": {
    "build": "tsx scripts/migrate.ts && next build"
  }
}
```

Because `DATABASE_URL` is different per Vercel environment (thanks to the integration), this same build command safely migrates `main` in production and the correct ephemeral branch in each preview — no extra conditional logic needed.

## 7. Resetting a Branch to Match Its Parent

Useful when a preview branch's data has drifted too far and you just want a clean slate matching `main` again:

```bash
neonctl branches reset dev/manual-test --parent --project-id <your-project-id>
```

This is instant — it re-establishes the copy-on-write link rather than copying data.

## 8. Seeding a Fresh Branch with Test Data

```ts
// scripts/seed.ts — run manually against any branch by pointing
// DATABASE_URL at it before running this script
import { db } from "@/lib/db-drizzle";
import { notesDrizzle } from "../drizzle/schema";

async function seed() {
  await db.insert(notesDrizzle).values([
    { title: "Welcome", content: "This is a seeded note." },
    { title: "Second note", content: "Another seeded example." },
  ]);
  console.log("Seed complete.");
}

seed();
```

```bash
# Point at a specific branch's connection string just for this run
DATABASE_URL="postgresql://...preview-branch-url..." pnpm tsx scripts/seed.ts
```

## 9. Checkpoint

- [ ] Understand that branches are copy-on-write, near-instant, near-free
- [ ] Manually created and deleted a branch via the console or `neonctl`
- [ ] Installed the Vercel-Neon integration and confirmed it maps Production/Preview environments to `main`/per-PR branches
- [ ] Added a migration step to the build command so preview branches auto-migrate
- [ ] Know how to reset a branch back to match its parent

## Troubleshooting

| Problem | Fix |
|---|---|
| Preview deployment shows old/production data | Confirm the Neon Vercel integration is actually creating per-branch databases for Preview, not reusing one shared preview branch |
| Migrations fail on preview build | Ensure the preview branch's `DIRECT_URL` env var is also injected by the integration — check Vercel's environment variables per environment |
| Too many stale preview branches piling up | Check the integration's branch cleanup setting, or periodically run `neonctl branches list` + delete manually; free tier caps at 10 branches |

## Next

**Part 8: Connection Pooling, Edge Runtime & Performance** — go deeper on pooled vs direct connections, cold starts, and when to reach for the WebSocket driver.
