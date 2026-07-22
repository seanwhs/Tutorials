# Part 40 — Deploy to Vercel

We have built a large full-stack accounting application.

Now it is time to deploy it.

By the end of this part, you will have:

- A production-ready GitHub repository
- A Vercel project
- Environment variables configured
- Clerk production settings prepared
- Neon production database connection configured
- Drizzle migrations applied
- Inngest endpoint available
- Production deployment verified

This part is more operations-focused than code-heavy, but deployment is still engineering.

A feature is not truly done until it can run outside your laptop.

---

# 1. Understand Production Deployment

## The Target

We are deploying GreyMatter Ledger to Vercel.

---

## The Concept

Local development is your workshop.

Production is the real shopfront.

In production, the app needs:

```txt
Hosted web server
Production database
Authentication provider
Background job endpoint
Environment variables
Secure secrets
```

The production architecture is:

```txt
Browser
  |
  v
Vercel Next.js App
  |
  |-- Clerk authentication
  |-- Neon Postgres
  |-- Inngest background jobs
```

---

# 2. Verify Local Health Before Deployment

## The Target

We are confirming the project is clean before pushing.

---

## The Implementation

Run:

```bash
pnpm check
```

Run:

```bash
git status
```

Expected:

```txt
nothing to commit, working tree clean
```

If not clean, commit your changes:

```bash
git add .
git commit -m "Prepare for deployment"
```

---

## The Verification

You are ready if:

```txt
pnpm check passes
git status is clean
```

---

# 3. Push to GitHub

## The Target

We are pushing the repository to GitHub.

---

## The Implementation

Create a new GitHub repository named:

```txt
greymatter-ledger
```

Then connect your local repo:

```bash
git remote add origin https://github.com/YOUR_USERNAME/greymatter-ledger.git
git branch -M main
git push -u origin main
```

If you already have a remote:

```bash
git remote -v
git push
```

---

## The Verification

Open your GitHub repository in the browser.

You should see your project files.

Make sure this file is **not** present:

```txt
.env.local
```

---

# 4. Create Vercel Project

## The Target

We are importing the GitHub repo into Vercel.

---

## The Implementation

Go to:

```txt
https://vercel.com
```

Click:

```txt
Add New Project
```

Import:

```txt
greymatter-ledger
```

Use defaults:

```txt
Framework Preset: Next.js
Build Command: pnpm build
Install Command: pnpm install
Output Directory: .next
```

Do not deploy yet if Vercel requires environment variables first.

---

# 5. Configure Production Environment Variables

## The Target

We are adding required environment variables in Vercel.

---

## The Concept

Production secrets must live in Vercel environment variables.

Do not commit secrets to Git.

---

## The Implementation

In Vercel project settings, add:

```bash
DATABASE_URL="your_neon_production_connection_string"

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="your_clerk_publishable_key"
CLERK_SECRET_KEY="your_clerk_secret_key"

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"

INNGEST_EVENT_KEY="your_inngest_event_key"
INNGEST_SIGNING_KEY="your_inngest_signing_key"
```

If you are using test Clerk keys for a preview deployment, that is acceptable for learning.

For true production, use Clerk production instance keys.

---

## The Verification

In Vercel, confirm all required variables exist for:

```txt
Production
Preview
Development
```

at least for the environments you intend to deploy.

---

# 6. Configure Clerk Production URLs

## The Target

We are updating Clerk allowed URLs.

---

## The Implementation

In Clerk dashboard, set allowed redirect/origin URLs.

Add your Vercel domain:

```txt
https://your-project.vercel.app
```

Configure:

```txt
Sign-in URL: /sign-in
Sign-up URL: /sign-up
After sign-in: /dashboard
After sign-up: /dashboard
```

If using organizations, confirm they are enabled in the production Clerk app too.

---

## The Verification

Clerk should allow authentication from your Vercel domain.

---

# 7. Deploy to Vercel

## The Target

We are running the first deployment.

---

## The Implementation

In Vercel, click:

```txt
Deploy
```

Or from CLI:

```bash
pnpm dlx vercel
```

Follow prompts.

---

## The Verification

After build completes, open:

```txt
https://your-project.vercel.app
```

You should see the landing page.

---

# 8. Apply Database Migrations to Production

## The Target

We are ensuring Neon production database has all tables.

---

## The Concept

Vercel builds the app, but Drizzle migrations must be applied to the database.

You can run migrations locally against the production Neon URL or configure a deployment migration workflow.

For this tutorial, we run manually.

---

## The Implementation

Temporarily set your local `.env.local` `DATABASE_URL` to the production Neon URL, or use a separate command environment.

Then run:

```bash
pnpm db:migrate
```

Safer one-off approach:

```bash
DATABASE_URL="your_neon_production_connection_string" pnpm db:migrate
```

On Windows PowerShell:

```powershell
$env:DATABASE_URL="your_neon_production_connection_string"
pnpm db:migrate
```

---

## The Verification

Open Neon SQL editor and run:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

You should see all app tables, including:

```txt
organizations
accounts
customers
vendors
invoices
bills
journal_entries
journal_lines
audit_logs
bank_imports
bank_transactions
```

---

# 9. Verify Production App

## The Target

We are testing production manually.

---

## The Implementation

Open production URL:

```txt
https://your-project.vercel.app
```

Test:

```txt
Sign up
Create organization
Open dashboard
Open settings/database
Seed chart of accounts
Create customer
Create invoice
Open reports
```

---

## The Verification

Minimum production smoke test:

- Landing page loads
- Clerk sign-in works
- Organization switcher works
- Database status says connected
- Chart of accounts can seed
- Invoice creation works
- Reports load

---

# 10. Configure Inngest Production

## The Target

We are connecting Inngest to the production endpoint.

---

## The Implementation

In Inngest dashboard, create or configure app endpoint:

```txt
https://your-project.vercel.app/api/inngest
```

Make sure Vercel has:

```txt
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
```

Trigger:

```txt
app/health.check
```

from:

```txt
/settings/background-jobs
```

---

## The Verification

Inngest dashboard should show your functions and events.

---

# 11. Production Deployment Notes

## The Target

We are recording deployment-specific notes.

---

## The Implementation

Create:

```txt
docs/deployment.md
```

Add:

```md
# Deployment Notes

## Hosting

GreyMatter Ledger is deployed to Vercel.

## Required Environment Variables

- DATABASE_URL
- NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
- CLERK_SECRET_KEY
- NEXT_PUBLIC_CLERK_SIGN_IN_URL
- NEXT_PUBLIC_CLERK_SIGN_UP_URL
- NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL
- NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL
- NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL
- NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL
- INNGEST_EVENT_KEY
- INNGEST_SIGNING_KEY

## Database Migrations

Run:

```bash
pnpm db:migrate
```

against the production Neon database before using the deployed app.

## Smoke Test

After deployment:

1. Visit landing page.
2. Sign in.
3. Create organization.
4. Open `/settings/database`.
5. Seed chart of accounts.
6. Create customer.
7. Create invoice.
8. Confirm journal diagnostics.
9. Open reports.
10. Send background health check event.

## Security Notes

Do not commit `.env.local`.

Rotate keys if they are leaked.

Use production Clerk keys for real production deployments.
```

---

## The Verification

Run:

```bash
pnpm check
```

---

# 12. Commit Deployment Notes

## The Target

We are saving deployment documentation.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Add deployment notes"
git push
```

---

## The Verification

GitHub should show:

```txt
docs/deployment.md
```

---

# Common Errors and Fixes

## Error: Vercel build fails because `DATABASE_URL` is missing

Add `DATABASE_URL` in Vercel environment variables.

Redeploy.

---

## Error: Clerk auth fails in production

Check Clerk allowed origins and redirect URLs.

Add:

```txt
https://your-project.vercel.app
```

---

## Error: Database tables missing in production

Run:

```bash
DATABASE_URL="production_url" pnpm db:migrate
```

---

## Error: Inngest cannot find functions

Check endpoint:

```txt
https://your-project.vercel.app/api/inngest
```

Check environment variables.

---

# Phase 12 Reference — Deployment

## Vercel

Hosts the Next.js app.

---

## Neon

Hosts Postgres.

---

## Clerk

Handles auth and organizations.

---

## Inngest

Handles background jobs.

---

# Part 40 Completion Checklist

You are ready for Part 41 if:

- [ ] `pnpm check` passes locally
- [ ] GitHub repository exists
- [ ] Vercel project exists
- [ ] Vercel env vars configured
- [ ] Clerk production URLs configured
- [ ] Neon production database migrated
- [ ] Production landing page loads
- [ ] Production auth works
- [ ] Production database status works
- [ ] Inngest production endpoint configured
- [ ] `docs/deployment.md` exists
- [ ] Changes pushed to GitHub
