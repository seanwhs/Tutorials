## Part 23: Deploying to Vercel for Free

Goal of this part: put your app on the real internet, entirely on free tiers — no credit card required anywhere in this process — using Vercel to host the app, and connecting it to your already-free Neon, Clerk, and Inngest accounts. By the end, you'll have a real URL you can share with anyone.

Prerequisite: Parts 1-22 completed (Part 22 optional/Plaid can be skipped entirely — nothing here depends on it).

---

### 1. What "deploying" actually means, and why Vercel specifically

Right now, your app only runs on your own computer (`npm run dev`) — if you closed your laptop, nobody else could see it. Deploying means putting your code on a server that's always on and reachable from anywhere via a real URL. Vercel is the company that makes Next.js (the framework we've used this whole course), so it has the best, most seamless support for it of any hosting provider — deploying a Next.js app to Vercel is close to a one-click process, and its free "Hobby" tier requires no credit card and is genuinely usable for a real side project or portfolio piece indefinitely, not just a trial period.

### 2. Push your project to GitHub

Recall Part 1 — you already created a GitHub account. Now we connect your local project to it.

1. Go to https://github.com and click "New repository" (the + icon top right, or a "New" button on your repositories page)
2. Name it `qb-clone`, leave it Public or Private (either works fine for Vercel), do NOT initialize it with a README (your project already has files) — click Create Repository
3. GitHub will show you commands to run — in your terminal, inside your `qb-clone` project folder:

```
git remote add origin https://github.com/YOUR_USERNAME/qb-clone.git
git branch -M main
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username. This uploads every commit you've made across this entire course to GitHub. Refresh the GitHub page — you should see all your project files there.

**A critical double-check before continuing:** confirm `.env.local` was never pushed. Look through your files on GitHub — you should NOT see `.env.local` listed anywhere (only `.env.example` if you happened to make one, which we didn't in this course). If you do see it, stop, remove it, and rotate every secret in it immediately (treat any exposed key as compromised) before proceeding — this is exactly why we relied on `.gitignore`'s default behavior throughout the course.

### 3. Create a free Vercel account and import your project

1. Go to https://vercel.com and sign up — choose "Continue with GitHub" so your accounts are linked automatically, no credit card requested anywhere in this flow
2. Once logged in, click "Add New..." -> "Project"
3. Vercel will show your GitHub repositories — find `qb-clone` and click "Import"
4. Vercel auto-detects it's a Next.js project and pre-fills the build settings correctly — you don't need to change anything here
5. Before clicking Deploy, we need to add environment variables (next step) — Vercel lets you add these on this same screen before the first deploy

### 4. Add every environment variable

Open your local `.env.local` file and, for each line, add a matching entry in Vercel's "Environment Variables" section on the import screen (or later under Project Settings -> Environment Variables if you already deployed once). You'll be adding:

- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
- `CLERK_SECRET_KEY`
- `DATABASE_URL`
- `DATABASE_URL_UNPOOLED`
- Any Inngest-related keys if you added them (see step 7)

A genuinely important note for a production accounting-style app: consider, at this point, whether to create a SEPARATE Clerk application and a SEPARATE Neon database branch/project for "production" versus the "development" ones you've been using throughout this course, so your real deployed app doesn't share data with your local testing. For learning purposes, reusing the same ones is fine and simpler — just know real teams virtually always separate development and production credentials. Neon's branching feature (mentioned back in Part 6) is designed exactly for this — you could create a production branch off your existing database that starts as a clean copy, rather than paying for or manually setting up a second database from scratch.

Click Deploy. Vercel will build and deploy your app — this takes a minute or two. When it finishes, you'll get a real URL like `qb-clone-yourname.vercel.app` — open it. Your app is now live on the internet, for free.

### 5. Fix the Clerk redirect URLs for production

Clerk needs to know your production URL is allowed to use it. In your Clerk dashboard, under your application's settings, look for allowed redirect/origin URLs (sometimes automatically handled if you're on Clerk's newer setup, but worth confirming) and add your Vercel URL if it's not already recognized. Try signing up/signing in on your live deployed URL to confirm authentication works end to end in production, not just locally.

### 6. Wire up the real Clerk webhook (resolving Part 9's deferral)

Back in Part 9, we deferred automatically seeding a Chart of Accounts when a new organization is created, because testing a webhook locally requires a public URL — which we now have.

1. In your Clerk dashboard, go to Configure -> Webhooks -> Add Endpoint
2. Set the endpoint URL to `https://your-vercel-url.vercel.app/api/webhooks/clerk`
3. Subscribe to the `organization.created` event
4. Clerk will show you a signing secret — add it to your Vercel environment variables as `CLERK_WEBHOOK_SECRET`, and redeploy (Vercel Project Settings -> Deployments -> ... -> Redeploy, or just push any small commit) so the new env var takes effect
5. Test it: create a brand new organization on your live deployed app, and confirm (via Neon's dashboard) that `seedDefaultAccounts` ran automatically for it — no manual script needed anymore, exactly as real QuickBooks-style onboarding should work

### 7. Connect Inngest to your production deployment

Locally, we used `npx inngest-cli@latest dev` as a stand-in for Inngest's real infrastructure. In production, Inngest Cloud (your free account from Part 19) needs to know where your deployed app's `/api/inngest` endpoint lives.

1. In your Inngest dashboard (https://app.inngest.com), go to your app and look for "Sync" or "Add app" pointing at a production URL
2. Enter `https://your-vercel-url.vercel.app/api/inngest`
3. Inngest will call that URL to discover your registered functions (`sendInvoiceEmail`, `sendOverdueReminders`, `generateRecurringInvoices`) — confirm they show up correctly in the dashboard
4. Some Inngest setups use a signing key for production apps — if prompted, generate one and add it to Vercel as `INNGEST_SIGNING_KEY`, then redeploy

Test by creating an invoice on your live app and confirming (via the Inngest Cloud dashboard, not the old local one) that the `invoice/created` event fired and `sendInvoiceEmail` ran successfully against your real production database.

### 8. Confirm Neon works correctly under real serverless load

This is a good moment to revisit Part 6's pooled-vs-unpooled explanation with fresh eyes: Vercel runs your app as serverless functions, meaning many short-lived instances may run concurrently under real traffic — exactly the scenario the pooled `DATABASE_URL` exists for. Double check your `src/lib/db/index.ts` is using `DATABASE_URL` (the pooled one) for the running app, and that only `drizzle.config.ts` (used for migrations, run from your own machine, not from Vercel) uses `DATABASE_URL_UNPOOLED`. If you got this right back in Part 6/7, there's nothing to change here — just confirm it, since it's easy to mix these up and only notice under real concurrent traffic, not during solo local testing.

### 9. Running migrations against production

Notice Vercel's build process does NOT automatically run `npm run db:migrate` for you unless you set it up to. For this course, the simplest approach: run migrations manually from your own machine whenever you change the schema, pointed at your production database's `DATABASE_URL_UNPOOLED` (temporarily swap your local `.env.local`'s values, or keep a separate `.env.production.local` file, run `npm run db:migrate`, then switch back). More advanced setups add a build step or a dedicated migration CI job — a good improvement to explore once you're comfortable with the basics, but not required to have a working deployed app today.

### 10. Optional: a free custom domain-ish URL

Vercel gives you a free `your-project-name.vercel.app` subdomain automatically — genuinely fine for a portfolio piece or personal project, no extra cost or steps needed. If you own a real domain name (that itself typically costs money from a registrar, so this part is optional and not free), Vercel's project settings -> Domains lets you attach it with guided DNS instructions. Not required to complete this course.

### 11. Staying within free tier limits long term

A quick honest rundown so nothing surprises you months from now:
- **Vercel Hobby tier**: generous for personal projects; watch for their fair-use policy around commercial use if this ever becomes a real paid product (fine for learning/portfolio use)
- **Neon free tier**: storage cap plus scale-to-zero (Part 6) — fine for low-traffic apps; a real paying-customer product would eventually need a paid tier
- **Clerk free tier**: a monthly active user cap — plenty for personal/demo use
- **Inngest free tier**: a monthly function run cap — plenty for personal/demo use, cron jobs count as runs too so keep that in mind if you add many frequent schedules

None of these limits should affect you during or after this course for learning purposes — just know they exist if this project ever grows into something with real users.

### 12. Commit and wrap up

```
git add .
git commit -m "Deployment notes and any production-related fixes"
git push
```

Every future `git push` to your main branch will automatically trigger a new Vercel deployment — this is called "continuous deployment," and it means your live app always reflects your latest committed code, with zero manual redeploy steps needed going forward.

---

### Checkpoint — confirm before moving on

- [ ] Project is pushed to GitHub, with `.env.local` confirmed absent from the repository
- [ ] App is deployed on Vercel with a real, working public URL, no credit card required
- [ ] All environment variables are set in Vercel and sign-up/sign-in works on the live URL
- [ ] The Clerk `organization.created` webhook is wired to production and auto-seeds a Chart of Accounts for new organizations, with no manual script needed
- [ ] Inngest Cloud shows your production app and its functions, and you confirmed an event fires correctly against production
- [ ] You understand why `DATABASE_URL` (pooled) is used by the running app while `DATABASE_URL_UNPOOLED` is only for migrations, and why this matters more under real serverless traffic
- [ ] You understand that `git push` now automatically triggers a new deployment

---

### Troubleshooting

**Vercel build fails with a TypeScript or lint error that never appeared locally**
Vercel runs a stricter production build than `npm run dev` does. Run `npm run build` locally first (before pushing) to catch these errors on your own machine — it's much faster to debug locally than by re-reading Vercel's build logs repeatedly.

**Build succeeds but the deployed site shows a 500 error or blank page**
Almost always a missing or misspelled environment variable in Vercel's dashboard. Go to Project Settings -> Environment Variables and carefully compare every name against your local `.env.local` — a single typo (missing `NEXT_PUBLIC_` prefix, wrong casing) will break things silently.

**Sign-in works locally but fails on the deployed URL with a Clerk-related error**
