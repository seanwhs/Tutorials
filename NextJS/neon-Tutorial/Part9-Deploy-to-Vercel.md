# Neon Tutorial - Part 9: Deploying to Vercel Free Tier with Neon

## 1. Prerequisites

- A GitHub (or GitLab/Bitbucket) repo containing the project from Parts 1-8.
- A free [Vercel](https://vercel.com) account.
- The Neon-Vercel integration installed (Part 7) — if you skipped Part 7, do that first, or manually add env vars per step 4 below.

## 2. Push Your Code

```bash
git init
git add .
git commit -m "Neon + Next.js 16 tutorial project"
git branch -M main
git remote add origin https://github.com/<you>/neon-nextjs16-tutorial.git
git push -u origin main
```

Make sure `.env.local` is **not** committed — confirm it's listed in `.gitignore` (Next.js scaffolds this by default).

## 3. Import the Project into Vercel

1. [vercel.com/new](https://vercel.com/new) → **Import Git Repository** → select your repo.
2. Framework Preset: Vercel auto-detects **Next.js** — leave defaults.
3. Before clicking Deploy, expand **Environment Variables**.

## 4. Configure Environment Variables

If you installed the Neon-Vercel integration (Part 7), `DATABASE_URL` and `DIRECT_URL` are likely already populated for Production automatically. Otherwise, add them manually:

| Name | Value | Environments |
|---|---|---|
| `DATABASE_URL` | Neon **pooled** connection string for your `main` branch | Production, Preview, Development |
| `DIRECT_URL` | Neon **direct** connection string for your `main` branch | Production, Preview, Development |

> If using the integration, Preview environments automatically get their own per-branch strings (Part 7) — you don't need to manage those manually.

## 5. Add a Migration Step to the Build Command

Choose the block matching whichever ORM you used (Part 5 Prisma or Part 6 Drizzle) — or both if you followed both parts.

```json
// package.json — Prisma
{
  "scripts": {
    "build": "prisma generate && prisma migrate deploy && next build"
  }
}
```

```json
// package.json — Drizzle (using the migrate script from Part 7)
{
  "scripts": {
    "build": "tsx scripts/migrate.ts && next build"
  }
}
```

`prisma migrate deploy` (unlike `migrate dev`) only applies existing migration files — it never generates new ones or prompts interactively, which is exactly what you want in a CI build.

## 6. Deploy

Click **Deploy**. Vercel will:

1. Install dependencies (`pnpm install`).
2. Run your `build` script — applying migrations against Neon, then building the Next.js app.
3. Deploy the built app to a production URL (`your-project.vercel.app`).

## 7. Verify the Deployed App

```bash
# Quick smoke test with curl once deployed
curl -s https://your-project.vercel.app/api/notes | jq
```

Also manually click through:

- [ ] Homepage loads and shows "✅ Yes" for env vars configured (Part 3 sanity check)
- [ ] `/notes` (raw driver), `/notes-prisma`, `/notes-drizzle` all list rows
- [ ] Creating a new note via the form works and appears after redirect/revalidation
- [ ] A dynamic `[id]` page loads a specific note correctly

## 8. Confirm Data Landed in the Right Neon Branch

In the Neon console, open the **Tables** tab on your `main` branch and confirm the row you just created via the deployed app is visible there — proving the production deployment is really talking to Neon's `main` branch (not a stale local `.env.local` value baked into the build).

## 9. Set Up a Custom Domain (Optional)

```bash
# Vercel dashboard → Project → Settings → Domains → Add
# Point your domain's DNS per Vercel's instructions (A/CNAME record)
```

Not required for this tutorial, but worth knowing it's a few clicks on the free/Hobby tier.

## 10. Ongoing Workflow From Here

```
1. git checkout -b feature/new-thing
2. Make changes, add a migration if schema changed
3. git push origin feature/new-thing
4. Open PR → Vercel creates Preview deployment
              → Neon integration creates a matching branch (Part 7)
              → Preview build runs migrations against THAT branch
5. Test the preview URL safely — production untouched
6. Merge PR → Vercel promotes to Production
              → Production build runs migrations against Neon `main`
```

## 11. Checkpoint

- [ ] Code pushed to a Git repository, `.env.local` excluded
- [ ] Project imported into Vercel with `DATABASE_URL`/`DIRECT_URL` configured
- [ ] Build command includes a migration step (`prisma migrate deploy` or Drizzle migrate script)
- [ ] Deployment succeeded and the app is reachable at a `.vercel.app` URL
- [ ] Verified data written via the deployed app appears in Neon's `main` branch

## Troubleshooting

| Problem | Fix |
|---|---|
| Build fails at migration step with "relation already exists" | Someone ran migrations manually against `main` outside the CI flow — reconcile migration history, consider `prisma migrate resolve` for Prisma |
| App builds but every page 500s | Check Vercel's Function Logs — usually a missing/incorrect env var not present in the Production environment specifically |
| Works in Preview but not Production | Environment variables are scoped per-environment in Vercel — confirm `DATABASE_URL`/`DIRECT_URL` are checked for **Production** too, not just Preview/Development |
| `prisma generate` not run before build | Ensure it's part of the `build` script, or add a `postinstall` script: `"postinstall": "prisma generate"` |

## Next

**Part 10: Free Tier Limits, Monitoring & Scaling Considerations** — understand exactly what "free" includes long-term and how to keep an eye on usage.
