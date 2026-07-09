# Neon Tutorial - Appendix B: Environment Variables Reference

## Core Variables

| Variable | Introduced In | Where to Get It | Required? | Notes |
|---|---|---|---|---|
| `DATABASE_URL` | Part 3 | Neon console → Connect → **pooled** connection string (hostname contains `-pooler`) | Yes | Used at runtime by all Server Components/Actions/Route Handlers |
| `DIRECT_URL` | Part 3 | Neon console → Connect → **direct** connection string (no `-pooler` in hostname) | Yes | Used only for migrations (`prisma migrate`, `drizzle-kit migrate`) and admin scripts |

## Optional / Advanced Variables

| Variable | Introduced In | Where to Get It | Required? | Notes |
|---|---|---|---|---|
| `NEON_API_KEY` | Part 10 | Neon console → Account Settings → API Keys | Only for branch-audit script | Treat as a secret — grants API access to your account |
| `NEON_PROJECT_ID` | Part 10 | Neon console → Project → shown in the dashboard URL/settings | Only for branch-audit script | Not secret, but project-specific |

## `.env.local` Template

```bash
# .env.local — never commit this file

# Pooled connection — app runtime queries
DATABASE_URL="postgresql://neondb_owner:<password>@ep-xxxx-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require"

# Direct connection — migrations only
DIRECT_URL="postgresql://neondb_owner:<password>@ep-xxxx.us-east-2.aws.neon.tech/neondb?sslmode=require"

# Optional — only needed if running scripts/audit-branches.ts
NEON_API_KEY=""
NEON_PROJECT_ID=""
```

## Per-Environment Setup Checklist (Vercel)

| Environment | `DATABASE_URL` | `DIRECT_URL` | Source |
|---|---|---|---|
| Production | Neon `main` branch, pooled | Neon `main` branch, direct | Manually set, or auto-populated by Vercel-Neon integration |
| Preview | Per-PR Neon branch, pooled | Per-PR Neon branch, direct | Auto-populated by Vercel-Neon integration (Part 7) |
| Development (local) | `main` or a personal `dev/*` branch, pooled | Same branch, direct | `.env.local`, not committed |

## Validation

All variables are validated at startup via `src/lib/env.ts` (Part 3):

```ts
import { z } from "zod";

const envSchema = z.object({
  DATABASE_URL: z.string().url().startsWith("postgresql://"),
  DIRECT_URL: z.string().url().startsWith("postgresql://"),
});

export const env = envSchema.parse({
  DATABASE_URL: process.env.DATABASE_URL,
  DIRECT_URL: process.env.DIRECT_URL,
});
```

A missing or malformed variable throws a clear `ZodError` immediately at boot rather than failing silently or with a cryptic error deep in a query.

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Using the direct string for `DATABASE_URL` | Connection errors under concurrent load in production | Swap in the pooled (`-pooler`) string |
| Using the pooled string for `DIRECT_URL` | Migrations fail with session-feature errors | Swap in the direct (no `-pooler`) string |
| Forgetting `?sslmode=require` | `connection requires SSL` error | Append `?sslmode=require` to both strings |
| Env vars only set for one Vercel environment | Works in Preview, 500s in Production (or vice versa) | Check the box for all relevant environments when adding vars in Vercel |
| Committing `.env.local` | Secrets leaked in Git history | Confirm `.gitignore` includes `.env*.local` (default in Next.js scaffolds); rotate the password in Neon console if leaked |

---

Say **"next"** to continue to **Appendix C: Troubleshooting Guide**, or name any Part/Appendix to jump directly.
