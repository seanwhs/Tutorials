# Neon Tutorial - Appendix C: Troubleshooting Guide

Organized by category. Cross-references the Part where the underlying concept is explained in depth.

## Connection & Authentication

| Problem | Cause | Fix |
|---|---|---|
| `password authentication failed` | Stale or mistyped connection string | Re-copy from Neon console (Part 2) — passwords are masked and must be re-revealed |
| `connection requires SSL` | Missing `?sslmode=require` | Append `?sslmode=require` to both `DATABASE_URL` and `DIRECT_URL` |
| `NeonDbError` on every request | Wrong string type used for the context | Confirm pooled (`-pooler`) for runtime, direct (no `-pooler`) for migrations (Part 2, Part 8) |
| Special characters in password break the URL | Unencoded characters like `@`, `#`, `%` in the password | URL-encode the password, or regenerate a simpler password from the Neon console |

## Next.js 16 Specific

| Problem | Cause | Fix |
|---|---|---|
| `id` is `undefined` in a dynamic route | Forgot to `await params` | Next.js 16 requires `const { id } = await params;` — `params` is a `Promise` (Part 4) |
| TypeScript error on `params` prop type | Using the old synchronous type | Type as `params: Promise<{ id: string }>`, not `{ id: string }` |
| Env vars undefined at build time | `.env.local` not loaded, or wrong `cwd` | Run `next dev`/`next build` from the project root; confirm the file is named exactly `.env.local` |

## Migrations

| Problem | Cause | Fix |
|---|---|---|
| `Error: P1001: Can't reach database server` (Prisma) | Migration attempted over the pooled connection | Ensure `directUrl` in `schema.prisma` points at `DIRECT_URL` (Part 5) |
| `relation already exists` on deploy | Migration history drift between environments | Reconcile with `prisma migrate resolve`, or inspect `drizzle/migrations` history table (Part 9) |
| Drizzle migration diff is empty after a schema change | Wrong schema path in `drizzle.config.ts` | Confirm `schema:` points at the actual edited file (Part 6) |
| CI build fails at migration step | Missing `DIRECT_URL` in that Vercel environment | Add it for Production/Preview/Development as needed (Part 9, Appendix B) |

## ORM-Specific

| Problem | Cause | Fix |
|---|---|---|
| Too many connections error in dev (Prisma) | New `PrismaClient` created on every hot reload | Use the global singleton pattern shown in Part 5 |
| `driverAdapters` preview warning | Expected — still a preview feature in Prisma 6.x | Safe to ignore; keep Prisma updated |
| Drizzle `db.transaction()` throws/not supported | Using `neon-http` (stateless) driver | Switch to `neon-serverless`/`Pool`-based Drizzle client (Part 6, Part 8) |
| `relations()` query returns empty `with` | Schema not passed into `drizzle(sql, { schema })` | Confirm the `schema` object is imported and passed (Part 6) |

## Branching & Deployment

| Problem | Cause | Fix |
|---|---|---|
| Preview deployment shows production data | Vercel-Neon integration not actually creating per-branch databases | Re-check integration settings map Preview → new branch per PR (Part 7) |
| Stuck at 10-branch limit | Stale preview branches not cleaned up | Run `neonctl branches list` and delete manually, or fix integration auto-cleanup settings (Part 7, Part 10) |
| App builds but 500s on every page | Missing/incorrect env var for that specific Vercel environment | Check Vercel Function Logs; confirm vars are checked for the right environment (Part 9) |

## Performance

| Problem | Cause | Fix |
|---|---|---|
| First request after idle is slow | Scale-to-zero cold start | Expected on free tier; add query timeouts (Part 8), consider "always on" compute on paid tiers if critical |
| Queries feel slow under real traffic | Missing indexes, or shared 0.25 vCPU compute under real load | Add indexes on filtered/sorted columns (Part 8); consider a larger compute size on paid tiers |
| Edge Runtime build fails referencing `net`/`tls` | Using a non-Neon, TCP-based driver under `runtime = "edge"` | Switch to `@neondatabase/serverless` (Part 8) |

## Monitoring & Limits

| Problem | Cause | Fix |
|---|---|---|
| "storage limit reached" | Real data exceeding 0.5 GB, or too many diverged branches | Archive/delete old data, delete unused branches (Part 10) |
| Neon API script returns 401 | Expired/revoked API key | Regenerate in Account Settings → API Keys (Part 10) |

## General Debugging Checklist

1. Confirm `node -v` is 20.9+/22 LTS.
2. Confirm `.env.local` has both `DATABASE_URL` (pooled) and `DIRECT_URL` (direct), each ending in `?sslmode=require`.
3. Restart `pnpm dev` after any `.env.local` change.
4. Check the Neon console's **Monitoring** tab for storage/compute/branch usage.
5. Check Vercel's **Function Logs** for the specific deployment when a production error occurs.
6. When in doubt about params, remember: **Next.js 16 params/searchParams are Promises — always `await` them.**

---

Say **"next"** to continue to **Appendix D: Neon CLI & SQL Cheat Sheet** — the final note in the series.
