# Part 13: Deploying to Vercel for Free

Everything we've built so far has lived only on your own computer, reachable at `localhost:3000` — invisible to the rest of the world. This part changes that permanently: we'll push the code to GitHub, connect it to Vercel (a hosting platform built specifically for Next.js), and wire up all our existing free-tier services (Neon, Clerk, Inngest) so Greymatter Ledger becomes a real, live, shareable URL on the internet — with no credit card required anywhere in the process.

## Step 13.1 — The Pre-Flight Secrets Check

### The Target
Before touching GitHub at all, do one final, careful check to guarantee no secret ever gets published publicly.

### The Concept
Recall Part 2's warning: `.env.local` contains real passwords and API keys. GitHub repositories, by default, are visible to absolutely anyone on the internet unless explicitly marked private — and even a "private" repository can accidentally become public later, or be viewed by any collaborator you add. Think of this step like patting your pockets one last time before leaving the house for a long trip — checking, deliberately and explicitly, that you haven't left your house keys sitting on the kitchen counter in plain view.

### The Implementation

In your terminal, inside `greymatter-ledger/`, run:

```bash
cat .gitignore
```

Confirm the output includes a line matching `.env*` (added automatically back in Part 1's scaffold, and relied upon ever since). It should look something like:

```
# env files
.env*
```

Now run the single most important command in this entire step:

```bash
git status
```

Carefully read the full output. Confirm `.env.local` does **not** appear anywhere in the list of files Git is tracking or planning to commit. If you see it listed, **stop immediately** — do not proceed to Step 13.2 — and instead run:

```bash
git rm --cached .env.local
git commit -m "Remove accidentally tracked .env.local"
```

As one final, absolute confirmation, search your entire commit history for the word "secret" or any key-like pattern, just in case an earlier accidental commit slipped through unnoticed:

```bash
git log --all --full-history -- .env.local
```

Expected output: **nothing at all** (an empty result) — meaning `.env.local` has never once been part of any commit, in the entire history of this repository. If this command *does* print any commits, your secrets have been part of your Git history at some point, even if the file was later removed — in that case, rotate every single key mentioned in `.env.local` (generate brand-new keys in the Clerk, Neon, and Inngest dashboards, replacing the old ones) before proceeding, since old keys embedded in history remain retrievable by anyone who ever clones the repository.

### The Verification

`git log --all --full-history -- .env.local` returns empty, and `git status` shows a clean working state with no `.env.local` anywhere in sight. Only proceed to Step 13.2 once both of these are confirmed.

---

## Step 13.2 — Pushing to GitHub

### The Target
Create a GitHub repository and push our complete local Git history to it.

### The Concept
Recall Part 1's novel-drafting analogy for Git — we've been keeping a complete local history of every "draft" (commit) of our project, but it's only ever lived on your one computer. GitHub is a cloud-hosted place to store that same history, which serves two purposes here: it's a backup, and — critically for this part — it's the exact bridge Vercel uses to actually deploy your code. Vercel doesn't want your code emailed to it; it wants to be pointed at a GitHub repository it can watch and automatically redeploy from every time you push a new change.

### The Implementation

1. Go to **[github.com](https://github.com)** and sign in (or create an account).
2. Click the **+** icon in the top right, then **New repository**.
3. Name it `greymatter-ledger`.
4. Set visibility to **Private** (recommended, especially since this project will eventually contain real business logic you may not want publicly indexed — though note, per Step 13.1, that privacy is a second layer of protection, never a substitute for keeping real secrets out of Git entirely).
5. **Do not** check any of the "Initialize this repository with..." options (README, .gitignore, license) — our local project already has real content, and starting with an empty remote repository avoids a merge conflict on the very first push.
6. Click **Create repository**.

GitHub will show you a page with setup instructions. Since our project already exists locally with commit history, use the **"push an existing repository from the command line"** section. In your terminal, inside `greymatter-ledger/`:

```bash
git remote add origin https://github.com/YOUR_USERNAME/greymatter-ledger.git
git branch -M main
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username. You may be prompted to authenticate — follow GitHub's on-screen instructions (this typically opens a browser window to confirm sign-in, or prompts for a personal access token depending on your Git configuration).

### The Verification

Refresh the GitHub repository page in your browser. Confirm you see your entire project's file structure (`src/`, `package.json`, `drizzle.config.ts`, etc.) — and critically, confirm **`.env.local` is nowhere to be found** in the file listing. Click through to `.gitignore` on GitHub and confirm the `.env*` line is visible there, proving the exclusion rule itself is safely and correctly part of the tracked history, even though the excluded file itself is not.

---

## Step 13.3 — Creating a Vercel Account and Importing the Project

### The Target
Sign up for Vercel and connect it to the GitHub repository we just created.

### The Concept
**Vercel** is a hosting platform created by the same team that builds Next.js itself — meaning it understands Next.js's specific conventions (like Server Actions, the App Router, and serverless functions) natively, with essentially zero configuration required, unlike a generic hosting provider where you'd need to manually explain how to build and run a Next.js app.

### The Implementation

1. Go to **[vercel.com](https://vercel.com)** and sign up using **"Continue with GitHub"** — this is the simplest path, since it immediately links your GitHub account for the next step.
2. Once inside the Vercel dashboard, click **Add New...** → **Project**.
3. Vercel will show a list of your GitHub repositories — find `greymatter-ledger` and click **Import**.
4. On the configuration screen, Vercel should automatically detect **Framework Preset: Next.js** — leave this as-is.
5. **Do not click Deploy yet** — we need to add environment variables first (Step 13.4), since deploying without them would fail immediately (the app would have no way to reach Neon, Clerk, or Inngest).

### The Verification

Confirm you're looking at Vercel's project configuration screen, with "Next.js" correctly detected as the framework, and a collapsed **"Environment Variables"** section visible — we'll expand and fill this in next.

---

## Step 13.4 — Configuring Environment Variables on Vercel

### The Target
Recreate every value from `.env.local` inside Vercel's environment variable settings — with one important adjustment to the database connection string.

### The Concept
Recall Part 3, Step 3.2's explanation of pooled vs. unpooled Neon connections: unpooled connections are like a hotel's direct room line — fine for one caller at a time, but quickly overwhelmed by many simultaneous callers. Vercel runs your app as multiple independent serverless function instances that can scale up and down rapidly under real traffic — exactly the scenario Part 3 warned would exhaust an unpooled connection. **This is the moment that distinction finally matters in practice**: on Vercel, `DATABASE_URL` must always be the **pooled** connection string.

### The Implementation

Open your local `.env.local` file in VS Code, and back in the Vercel project configuration screen, expand **Environment Variables**. Add each of the following, one at a time (Key on the left, Value on the right):

| Key | Value |
|---|---|
| `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` | (copy from `.env.local`) |
| `CLERK_SECRET_KEY` | (copy from `.env.local`) |
| `NEXT_PUBLIC_CLERK_SIGN_IN_URL` | `/sign-in` |
| `NEXT_PUBLIC_CLERK_SIGN_UP_URL` | `/sign-up` |
| `NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL` | `/dashboard` |
| `NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL` | `/dashboard` |
| `DATABASE_URL` | **the POOLED connection string** (contains `-pooler` in the hostname) |
| `DATABASE_URL_UNPOOLED` | the unpooled connection string (only used for migrations — see Step 13.6) |
| `INNGEST_EVENT_KEY` | (copy from `.env.local`) |
| `INNGEST_SIGNING_KEY` | (copy from `.env.local`) |

Double-check `DATABASE_URL`'s value specifically contains `-pooler` in its hostname before moving on — this is the single most consequential value in this entire table, per the concept explained above.

### The Verification

Count the rows in Vercel's environment variable list and confirm all ten keys above are present, with no typos in the key names (an exact match to how they're referenced in code — e.g., `process.env.DATABASE_URL` in `src/db/index.ts` — is required; a mismatched key name would silently result in `undefined` at runtime).

---

## Step 13.5 — Configuring Clerk for Production

### The Target
Tell Clerk about our new production URL, so authentication works correctly once deployed (not just on `localhost`).

### The Concept
Clerk needs to know which URLs are allowed to use its authentication flow — this is a security measure preventing some other website from embedding your Clerk sign-in form and phishing your users. Right now, Clerk only knows about `localhost:3000`.

### The Implementation

Click **Deploy** in Vercel now (we'll need the real production URL Clerk requires before we can fully configure it, and Vercel needs at least one deployment to generate that URL). Wait for the build to complete — this typically takes one to three minutes. Once finished, Vercel will show a **"Congratulations!"** screen with a live URL, something like `https://greymatter-ledger-yourname.vercel.app`.

Copy that URL. Go to your Clerk dashboard → **Domains** (or **Paths**, depending on Clerk's current dashboard layout) → add your Vercel URL as an authorized domain/production instance.

If Clerk prompts you to switch from a "Development" instance to a "Production" instance (common for first-time production setup), follow its guided flow — this typically involves confirming your production domain and may regenerate your API keys specifically for production use. If Clerk issues new production keys at this point, **update `CLERK_SECRET_KEY` and `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` in Vercel's environment variables** (Project Settings → Environment Variables) to match the new production values, then trigger a redeploy (Vercel's **Deployments** tab → **⋯** menu on the latest deployment → **Redeploy**).

### The Verification

Visit your live Vercel URL. You should see Greymatter Ledger's homepage load without error. Attempt to sign up for a brand-new account directly on the live site. If Clerk's domain configuration is correct, this should succeed exactly as it did locally in Part 2 — if you instead see a Clerk configuration error, revisit the domain/production instance settings above.

---

## Step 13.6 — Running Migrations Against the Production Database

### The Target
Apply every schema migration we've built across Parts 3–12 to the real production Neon database, since Vercel deploying our *code* does not automatically create any database tables.

### The Concept
Recall Part 3's construction-crew analogy: our `schema.ts` file and the `drizzle/` migration files are the blueprint and the crew's instructions — but so far, we've only ever had that crew build against our *local development* connection to Neon. If you've been using the same single Neon project throughout this entire course (the typical case for this series), the good news is your production database **is** the same database you've already been testing against all along — meaning it likely already has every table built. If, however, you created a *separate* Neon project specifically for production, or want a clean slate, you'll need to run migrations against it explicitly before the live app can function.

### The Implementation

**If reusing the same Neon project from Parts 3–12** (the default path in this course), no action is needed here at all — your production `DATABASE_URL`/`DATABASE_URL_UNPOOLED` point at the exact same already-migrated database you've been developing against. Skip to the verification step below.

**If you created a brand-new, separate Neon project for production**, run migrations against it from your local machine, temporarily pointing at the new production database:

```bash
DATABASE_URL_UNPOOLED="your-production-unpooled-connection-string" npx drizzle-kit migrate
```

This temporarily overrides the `DATABASE_URL_UNPOOLED` environment variable for this single command only (your local `.env.local` file remains untouched), directing `drizzle-kit` to apply every migration file in `drizzle/` to the new production database instead of your local one.

### The Verification

In your Neon dashboard, switch to whichever project your production `DATABASE_URL` actually points at. Open its **Tables** view (or run `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';` in Neon's SQL editor) and confirm every table from this entire course is present: `organizations`, `accounts`, `journal_entries`, `journal_lines`, `customers`, `vendors`, `invoices`, `invoice_lines`, `bills`, `bill_lines`, `payments`, `recurring_invoice_templates`, `imported_transactions`.

---

## Step 13.7 — Configuring Inngest for Production

### The Target
Point our deployed Inngest functions at the real Inngest cloud service, instead of the local dev server we've been using since Part 11.

### The Concept
Recall Part 11's local dev server (`npx inngest-cli@latest dev`) — that tool only exists to simplify local testing; it has no place in a live, deployed app. Once deployed, Inngest's actual cloud service needs to discover our functions directly from our live `/api/inngest` route, which requires one manual "sync" step the very first time.

### The Implementation

In your Inngest dashboard (the same one from Step 11.1), navigate to your `greymatter-ledger` app's settings and find an option like **"Sync App"** or **"Add Deployment"**. Provide your live Vercel URL's Inngest endpoint, e.g.:

```
https://greymatter-ledger-yourname.vercel.app/api/inngest
```

Click **Sync**. Inngest will make a request to that URL (the same `GET /api/inngest` request we tested locally back in Step 11.3) to discover your three registered functions.

### The Verification

In the Inngest dashboard, confirm all three functions now appear under your production app: `send-invoice-confirmation-email`, `send-overdue-invoice-reminders`, and `generate-recurring-invoices`, each showing as correctly synced with your live deployment.

Create a real test invoice on your live production URL (not localhost). Check the Inngest dashboard's **Events** and **Runs** tabs — confirm a real `invoice/created` event appears, and the corresponding function run completes successfully. Since there's no local terminal to check for the `[SIMULATED EMAIL]` console log in production, instead check the function run's details in the Inngest dashboard directly — its execution log should show both steps (`fetch-invoice-details`, `send-email`) completing, which is the production-equivalent proof that the job ran correctly.

---

## Step 13.8 — Final End-to-End Verification on Production

### The Target
Walk through one complete, real business scenario entirely on the live production URL, confirming every part of the course works together in the deployed environment.

### The Implementation

On your live Vercel URL:

1. Sign up as a new user (or sign in as your existing test user).
2. Create a new organization (e.g., "Production Test Co").
3. Visit `/accounts` and confirm the full 15-account Chart of Accounts auto-seeded correctly.
4. Visit `/customers`, add a real customer.
5. Visit `/vendors`, add a real vendor.
6. Visit `/invoices/new`, create an invoice with at least one standard-rated and one zero-rated line.
7. Visit `/bills/new`, create a bill against at least two different expense accounts.
8. Record a partial payment against the invoice, and a full payment against the bill.
9. Visit `/reports/profit-and-loss`, `/reports/balance-sheet`, `/reports/aging`, and `/reports/gst-f5` — confirm every figure looks correct and the Balance Sheet shows the green "✅ balanced" banner.
10. Visit `/bank-import`, upload a small test CSV, categorize and post at least one row.

### The Verification

Every single step above should behave identically to how it behaved on `localhost` throughout Parts 2–12. If everything works, **Greymatter Ledger is now a live, real, deployed application on the open internet, running entirely on free-tier infrastructure, with no credit card used anywhere in this entire course.**

---

## Step 13.9 — Twelfth Git Commit (and Understanding Continuous Deployment)

### The Target
Understand what happens from this point forward whenever you make further changes to the code.

### The Concept
One of Vercel's most valuable features, once connected to GitHub as we've done, is **continuous deployment**: every single `git push` to your `main` branch from now on automatically triggers a brand-new production deployment, with zero manual steps required on Vercel's side. This is worth internalizing clearly, since it changes your development workflow going forward — any future change (like the extensions discussed in Part 14) becomes live the moment you push it.

### The Implementation

If you made any final tweaks during this part's verification steps, commit and push them now:

```bash
git add .
git commit -m "Final verification pass for production deployment"
git push
```

### The Verification

Watch the Vercel dashboard's **Deployments** tab — within a few seconds of pushing, a new deployment should automatically appear and begin building, without you ever touching the Vercel UI directly. This is the continuous deployment pipeline confirmed working end to end.

---

## ✅ Checkpoint — Part 13

At this point, you should have:

- [x] Confirmed, via `git log --all --full-history`, that `.env.local` has never been part of any Git commit
- [x] A private GitHub repository containing the complete project history
- [x] A Vercel project connected to that repository, with all ten required environment variables configured, `DATABASE_URL` specifically set to the **pooled** connection string
- [x] Clerk configured for the production domain, with sign-up/sign-in verified working live
- [x] Confirmed the production database has every table from the entire course
- [x] Inngest synced against the live production `/api/inngest` endpoint, with a real event/function run verified in the Inngest dashboard
- [x] A complete end-to-end walkthrough of every major feature (accounts, customers, vendors, invoices, bills, payments, all four reports, bank import) verified working on the live URL
- [x] Confirmed continuous deployment: a `git push` automatically triggers a new Vercel deployment
- [x] A twelfth Git commit checkpoint

---

## 📚 Reference Section: Environments, Secrets, and Deployment Hygiene

*(A standalone reference — read now or return later.)*

**Why does Vercel need its own separate copy of every environment variable, instead of somehow reading our local `.env.local` directly?**
`.env.local` is explicitly excluded from Git (Part 2, Part 13.1) — it exists purely on your own computer's disk and is genuinely never transmitted anywhere as part of your code. Vercel's servers have no access to your local filesystem at all; the *only* way for your deployed code to know these values is for you to explicitly, manually enter them into Vercel's own separate environment variable storage, which itself is never exposed in your public GitHub repository — it lives entirely within Vercel's own secured dashboard.

**What's the actual difference between Vercel's "Production," "Preview," and "Development" environment variable scopes, which you may have noticed as checkboxes during Step 13.4?**
Vercel supports deploying different versions of your code for different purposes: "Production" is your real, live `main` branch deployment; "Preview" deployments are automatically created for every other Git branch or pull request (letting you review a change before merging it into `main`); "Development" refers to running `vercel dev` locally through Vercel's own CLI tooling (which we didn't use in this course, since `npm run dev` served the same local-development purpose throughout). For this course, checking all three scopes for each variable is the simplest, safest default — a natural refinement for Part 14 onward would be using genuinely separate Neon/Clerk projects for Preview vs. Production, so that testing a risky change in a Preview deployment can never accidentally affect real production data.

**Why did Step 13.2 specify creating the GitHub repository as empty, without a README or .gitignore?**
Because our local repository already has its own complete commit history, including its own `.gitignore` (created automatically by `create-next-app` back in Part 1). If GitHub had also initialized the new remote repository with its own README or `.gitignore`, that remote repository would have a commit our local repository doesn't share a common history with — causing Git to reject a simple push and require a more complex merge resolution. Starting from a genuinely empty remote sidesteps this entirely, making `git push -u origin main` a clean, first-time upload.

**Is it actually true this entire course requires zero cost and no credit card, at real, meaningful usage levels?**
For the purposes of learning, building, and even running a genuinely small real business, yes — Neon, Clerk, Vercel, and Inngest all offer meaningfully generous free tiers specifically designed to support hobby projects and early-stage products without requiring payment information up front. It's worth understanding, though, that all four services are commercial companies with paid tiers that unlock higher usage limits (more database storage, more monthly active users, more function executions) — the free tier is genuinely functional, not a crippled trial, but a growing real business should expect to eventually evaluate whether its usage has grown past the free tier's specific limits, at which point upgrading is a deliberate, known business decision, not a surprise.

---

## 🔧 Troubleshooting — Part 13

**"The Vercel deployment fails during the build step."**
Click into the failed deployment's build logs in Vercel — the most common cause at this stage is a missing or misspelled environment variable that code expects at build time (rare, since most of our environment variable usage is server-side runtime, not build-time) or a genuine TypeScript error that somehow wasn't caught locally. Run `npm run build` locally first to reproduce and fix any build error before pushing again.

**"The live site loads, but every page shows a database connection error."**
Double-check `DATABASE_URL` in Vercel's environment variables — confirm it's the **pooled** string (contains `-pooler`), correctly pasted with no missing characters, and that you triggered a redeploy after adding/changing any environment variable (Vercel does not automatically retroactively apply a newly-added environment variable to an already-running deployment — a fresh deploy is required).

**"Sign-up/sign-in works locally but fails on the live URL with a Clerk-related error."**
Revisit Step 13.5 — this is almost always caused by Clerk not yet recognizing your production domain, or Vercel's environment variables still pointing at outdated development-instance Clerk keys after Clerk issued new production keys. Double-check the exact key values in Vercel's dashboard match precisely what Clerk's dashboard currently shows for your production instance, and trigger a fresh redeploy after any correction.

**"Inngest sync fails, or shows zero functions found at the production URL."**
Visit `https://your-vercel-url.vercel.app/api/inngest` directly in your browser first — if this doesn't return a JSON response listing your functions, the problem is in your deployed code or environment variables, not in Inngest's sync process itself. Confirm `INNGEST_EVENT_KEY` and `INNGEST_SIGNING_KEY` are both set correctly in Vercel's environment variables, and that you triggered a redeploy after adding them.

**"A feature that worked perfectly on localhost throws an error only on the live production URL."**
This is almost always an environment variable mismatch, or a difference between your local database's data and your production database's data (e.g., testing against an organization on production that was never properly seeded with a Chart of Accounts, per Part 5). Check Vercel's **Runtime Logs** (under the Deployments tab, click into the specific deployment, then **Functions** or **Logs**) for the exact server-side error message — this is the production-equivalent of watching your local terminal running `npm run dev`.

**"I pushed a new commit, but the live site doesn't reflect the change."**
Check the Vercel **Deployments** tab to confirm a new deployment actually triggered and completed successfully — if it's still building, wait for it to finish. If no new deployment appears at all after pushing, confirm your Vercel project is genuinely connected to the correct GitHub repository and branch (Project Settings → Git), and that you pushed to `main` specifically, not a different branch.

**"I'm worried I may have exposed a secret at some point during this course — what should I actually do?"**
Treat this seriously and immediately: regenerate every credential from scratch in each service's dashboard (Clerk's API keys, Neon's database password/connection string, Inngest's event and signing keys), update all four values in Vercel's environment variables, redeploy, and update your local `.env.local` to match the new values as well. This fully invalidates anything that may have leaked, at the small cost of a few minutes of reconfiguration — a trade worth making without hesitation whenever in doubt.
