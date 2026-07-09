# Part 21: Deployment to Vercel

## Concept

We deploy the finished app to Vercel's free Hobby tier, wire up production environment variables across all our services (Neon, Upstash, Clerk, Finnhub, Groq/Gemini, Resend), switch our database workflow from `db push` to proper Prisma Migrate, ensure Vercel is running Node.js 20.9+, and verify Vercel Cron actually fires on schedule.

## Step 1: Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit: SGX Stock Analytics Dashboard"
```

Create a new empty repository on GitHub, then:

```bash
git remote add origin https://github.com/yourusername/sgx-dashboard.git
git branch -M main
git push -u origin main
```

Double-check `.env.local` is in `.gitignore` and was never committed — run `git log --all --full-history -- .env.local` to confirm it has zero history.

## Step 2: Switch to Prisma Migrate for production

Up to now we used `prisma db push` for fast prototyping (Part 3). Before shipping, generate a proper migration history:

```bash
npx prisma migrate dev --name init
```

This creates a `prisma/migrations` folder that should be committed to git — this is what Vercel's build step will run against your production database on Neon.

## Step 3: Import the project into Vercel

1. Go to vercel.com, sign up/log in free with your GitHub account.
2. Click "Add New Project", select your `sgx-dashboard` repo.
3. Framework preset should auto-detect as Next.js.
4. Before deploying, go to **Settings → General → Node.js Version** and confirm it's set to **20.x** or newer (Vercel's default is usually current, but explicitly confirm this — Next.js 16 will fail to build on an older runtime).
5. Add all environment variables under "Environment Variables" (Production, and optionally Preview/Development too):

```
DATABASE_URL
DIRECT_URL
UPSTASH_REDIS_REST_URL
UPSTASH_REDIS_REST_TOKEN
FINNHUB_API_KEY
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
CLERK_SECRET_KEY
GOOGLE_GENERATIVE_AI_API_KEY
GROQ_API_KEY
OPENROUTER_API_KEY   (optional)
RESEND_API_KEY
CRON_SECRET
NEXT_PUBLIC_APP_URL
```

Use the exact same values from your `.env.local` (or fresh production-appropriate ones if you prefer to separate dev/prod Neon branches or Upstash instances — Neon's branching feature, mentioned in Part 3, makes a dedicated production branch easy to set up if you want that separation). Set `NEXT_PUBLIC_APP_URL` to your actual production URL (e.g. `https://sgx-dashboard.vercel.app`) once you know it — this is used in Part 19's alert email deep links.

> **Neon + Vercel tip:** If you install the official Neon integration from the Vercel Marketplace/Integrations tab, it can automatically sync your `DATABASE_URL`/`DIRECT_URL` environment variables into your Vercel project and even provision a separate Neon branch per Vercel preview deployment. This is optional — manually copying the connection strings from Part 3 works perfectly fine too — but worth knowing about if you want a more automated multi-environment setup later.

## Step 4: Configure the build command to run migrations

Update `package.json`'s build script so Vercel automatically applies pending Prisma migrations on every deploy:

```json
{
  "scripts": {
    "build": "prisma generate && prisma migrate deploy && next build"
  }
}
```

`prisma migrate deploy` (not `migrate dev`) is the correct command for production/CI environments — it applies existing migrations against your Neon database without prompting or generating new ones.

## Step 5: Deploy

Click "Deploy" in the Vercel dashboard, or simply push to `main` — Vercel automatically builds and deploys on every push once the project is linked (continuous deployment). Watch the build logs for any missing environment variable errors, Node version errors, or migration failures.

Once deployed, visit your `*.vercel.app` URL and re-run the manual click-through checklist from Part 20's Step 8, this time against the live production deployment.

## Step 6: Update callback/redirect URLs

Some services need your production URL registered:
- **Clerk**: in the Clerk dashboard, add your Vercel domain to allowed origins/redirect URLs if you configured any custom sign-in/sign-up redirect behavior.
- **Resend**: verify your sending domain (or continue using Resend's test sending domain if you're comfortable with its limitations for a portfolio project) and update the `from` address in `src/lib/email.ts` accordingly.
- Confirm `NEXT_PUBLIC_APP_URL` in your Vercel environment variables now matches your real deployed domain, so alert emails link correctly.

## Step 7: Verify Vercel Cron is running

Go to your Vercel project → **Settings → Cron Jobs**. You should see the two entries from `vercel.json` (Part 19's alert-check and nightly-refresh) listed with their schedules. Vercel also shows an execution log/history here — after your first scheduled run passes, confirm it shows a successful (200) response rather than a 401 (which would indicate a `CRON_SECRET` mismatch between your code and your Vercel environment variables) or 500.

## Step 8: Custom domain (optional)

If you own a domain, add it under **Settings → Domains** in Vercel — free SSL is provisioned automatically. Not required for a portfolio project, but a nice touch (e.g., `sgxdashboard.yourname.dev`).

## Step 9: A production smoke test

After every deploy, hit your production URL's key routes: home page loads with heatmap data, a known ticker's stock page loads with chart data, sign-in works, and the AI summary generates successfully. Also confirm your Neon project isn't showing any unexpected connection errors in its own dashboard (Neon's free tier scales compute to zero when idle and resumes automatically on the next query — the very first request after a period of inactivity may be a little slower than usual as the compute endpoint wakes up, which is expected behavior, not a bug).

## Checkpoint

- [ ] Code pushed to GitHub, `.env.local` confirmed never committed
- [ ] `prisma migrate dev --name init` run locally, migrations committed
- [ ] Vercel project created, Node.js Version confirmed 20.x+, all environment variables (including Neon's `DATABASE_URL`/`DIRECT_URL`) configured
- [ ] Build script updated to run `prisma migrate deploy` before `next build`
- [ ] First deploy succeeds, live URL loads correctly
- [ ] Clerk, Resend, and `NEXT_PUBLIC_APP_URL` updated for production
- [ ] Vercel Cron Jobs dashboard shows both scheduled jobs with successful recent executions

Next: **Part 22 — UI Polish (Bloomberg Terminal Theme)**, where we do a final visual pass to make the whole app feel cohesive, dense, and professional.
