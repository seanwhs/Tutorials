# Appendix H — Deployment and Operations Runbook

This appendix is a practical operations guide for deploying and running **GreyMatter Ledger**.

It is designed to answer:

```txt
How do I deploy the app?
Which services must be configured?
How do I verify production?
How do I apply migrations?
What do I do if something breaks?
```

This runbook assumes the stack used throughout the tutorial:

```txt
Vercel
Neon Postgres
Clerk
Inngest
Drizzle ORM
Next.js
```

---

# 1. Production Architecture

GreyMatter Ledger production architecture:

```txt
Browser
  |
  v
Vercel Next.js App
  |
  |-- Clerk Authentication
  |-- Neon Postgres
  |-- Inngest Background Jobs
```

Core responsibilities:

```txt
Vercel  -> hosts the app
Neon    -> hosts Postgres
Clerk   -> handles auth and organizations
Inngest -> handles events and background jobs
```

---

# 2. Pre-Deployment Checklist

Before deploying, run:

```bash
pnpm check
```

This runs:

```txt
lint
tests
build
```

Also check Git status:

```bash
git status
```

Expected:

```txt
nothing to commit, working tree clean
```

If there are changes:

```bash
git add .
git commit -m "Prepare deployment"
```

---

# 3. Required Production Services

You need production-ready accounts/projects for:

```txt
GitHub
Vercel
Neon
Clerk
Inngest
```

---

# 4. GitHub Repository

Push the project to GitHub.

Example:

```bash
git remote add origin https://github.com/YOUR_USERNAME/greymatter-ledger.git
git branch -M main
git push -u origin main
```

Verify:

```txt
.env.local is not in GitHub
```

If `.env.local` was committed, rotate all secrets immediately.

---

# 5. Vercel Deployment

## Create Project

In Vercel:

```txt
Add New Project
Import GitHub repository
Select greymatter-ledger
Framework: Next.js
```

Default settings are usually fine:

```txt
Install Command: pnpm install
Build Command: pnpm build
Output Directory: .next
```

---

# 6. Vercel Environment Variables

Add these in:

```txt
Vercel Project Settings -> Environment Variables
```

Required:

```bash
DATABASE_URL

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
CLERK_SECRET_KEY

NEXT_PUBLIC_CLERK_SIGN_IN_URL
NEXT_PUBLIC_CLERK_SIGN_UP_URL
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL

INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
```

Recommended values:

```bash
NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"
```

After adding or changing environment variables:

```txt
Redeploy the app.
```

---

# 7. Neon Production Database

## Create Neon Project

Create a production Neon project:

```txt
greymatter-ledger-production
```

Copy the connection string.

It should look like:

```txt
postgresql://user:password@host/database?sslmode=require
```

Make sure it includes:

```txt
sslmode=require
```

---

# 8. Apply Production Migrations

Vercel deployment does not automatically apply Drizzle migrations unless you build that workflow.

For this tutorial, apply migrations manually.

Option 1 — temporarily export production URL:

```bash
DATABASE_URL="postgresql://production-url" pnpm db:migrate
```

Option 2 — PowerShell:

```powershell
$env:DATABASE_URL="postgresql://production-url"
pnpm db:migrate
```

Option 3 — temporarily update `.env.local`, run migration, then restore development URL.

Be careful with Option 3.

---

## Verify Production Tables

In Neon SQL editor:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

Expected key tables include:

```txt
organizations
accounts
customers
vendors
invoices
invoice_lines
bills
bill_lines
customer_payments
vendor_payments
journal_entries
journal_lines
audit_logs
bank_imports
bank_transactions
recurring_invoices
```

---

# 9. Clerk Production Configuration

In Clerk dashboard:

```txt
Create or select production application
Enable organizations
Configure allowed origins
Configure redirect URLs
```

Add Vercel domain:

```txt
https://your-project.vercel.app
```

If using a custom domain:

```txt
https://app.yourdomain.com
```

Configure URLs:

```txt
Sign-in URL: /sign-in
Sign-up URL: /sign-up
After sign-in: /dashboard
After sign-up: /dashboard
```

Confirm organizations are enabled:

```txt
Organizations: enabled
Users can create organizations: enabled
```

---

# 10. Inngest Production Configuration

In Inngest dashboard:

```txt
Create app
Set endpoint URL
```

Endpoint:

```txt
https://your-project.vercel.app/api/inngest
```

Required environment variables in Vercel:

```bash
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
```

Verify functions appear:

```txt
background-health-check
invoice-created-confirmation
daily-overdue-invoice-reminders
daily-recurring-invoice-scheduler
```

---

# 11. Production Smoke Test

After deployment and migrations, perform a smoke test.

Open:

```txt
https://your-project.vercel.app
```

Test:

```txt
1. Landing page loads
2. Sign up works
3. Sign in works
4. Create organization
5. Open dashboard
6. Open /settings/database
7. Seed chart of accounts
8. Create customer
9. Create invoice
10. Open invoice detail
11. Record customer payment
12. Create vendor
13. Create bill
14. Record vendor payment
15. Open /reports/profit-and-loss
16. Open /reports/balance-sheet
17. Open /reports/gst-f5
18. Upload bank CSV
19. Categorize bank transaction
20. Post bank transaction
21. Reconcile bank transaction
22. Open /settings/audit-log as admin
23. Send Inngest health check
```

If all pass, production is basically healthy.

---

# 12. Post-Deployment Verification Queries

## Check Tables

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

---

## Check Journal Balance

```sql
select
  je.id,
  je.memo,
  sum(jl.debit_cents) as debits,
  sum(jl.credit_cents) as credits,
  sum(jl.debit_cents) - sum(jl.credit_cents) as difference
from journal_entries je
join journal_lines jl
  on jl.journal_entry_id = je.id
group by je.id, je.memo
having sum(jl.debit_cents) <> sum(jl.credit_cents);
```

Expected:

```txt
0 rows
```

---

## Check Tenant Counts

```sql
select
  o.name,
  count(i.id) as invoices,
  count(b.id) as bills
from organizations o
left join invoices i
  on i.organization_id = o.id
left join bills b
  on b.organization_id = o.id
group by o.name
order by o.name;
```

---

# 13. Deployment Rollback

If a deployment breaks:

1. Open Vercel project.
2. Go to Deployments.
3. Select previous working deployment.
4. Promote/rollback to previous deployment.

Important:

```txt
Rolling back app code does not automatically roll back database migrations.
```

If the migration caused the issue, you need a database rollback plan.

---

# 14. Database Rollback Strategy

Before risky migrations:

```txt
Create Neon branch or backup.
Review SQL migration.
Apply migration.
Smoke test.
```

If migration breaks production:

```txt
Use Neon restore/branch strategy.
Or apply corrective migration.
```

Avoid manually editing production schema unless you know exactly what you are doing.

---

# 15. Secret Rotation Runbook

Rotate secrets if:

```txt
.env.local was committed
Vercel env vars exposed
logs leaked secrets
team member with access leaves
security incident occurs
```

Rotate:

```txt
DATABASE_URL password
CLERK_SECRET_KEY
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
```

Steps:

1. Generate new secret in provider dashboard.
2. Update Vercel environment variable.
3. Update local `.env.local`.
4. Redeploy.
5. Verify smoke test.
6. Revoke old secret.

---

# 16. Incident Response Runbook

If something suspicious happens:

```txt
1. Preserve logs.
2. Rotate affected secrets.
3. Disable suspicious accounts if needed.
4. Check audit logs.
5. Check database changes.
6. Review Vercel deployment history.
7. Review Clerk sessions.
8. Review Inngest function runs.
9. Document timeline.
10. Notify affected parties if legally required.
```

For accounting data issues:

```txt
Do not delete entries casually.
Use reversals or corrective entries.
Preserve audit trail.
```

---

# 17. Monitoring Checklist

Recommended monitoring areas:

```txt
Vercel runtime errors
Vercel build failures
Neon database connection failures
Clerk auth failures
Inngest function failures
Slow database queries
Failed journal postings
Failed bank postings
Unexpected unbalanced journal SQL results
```

Future tools:

```txt
Sentry
Axiom
Datadog
Logtail
Vercel Analytics
Neon monitoring
Inngest dashboard alerts
```

---

# 18. Backup Checklist

For production accounting data:

```txt
Neon backups enabled
Recovery process documented
Restore process tested
Production database access restricted
Backups protected
Critical migration backups taken
```

A backup that has never been restored is only a hope.

Test restore procedures.

---

# 19. Operational Tasks

Daily or weekly:

```txt
Review failed Inngest jobs
Review Vercel errors
Review database health
Review audit logs
Check journal balance SQL
Review backup status
```

Before releases:

```txt
Run pnpm check
Review migrations
Deploy preview
Smoke test preview
Deploy production
Smoke test production
```

---

# 20. Common Production Errors

## Error: Vercel Build Fails

Likely causes:

```txt
Missing env vars
TypeScript error
Lint error
Test failure
```

Fix:

```bash
pnpm check
```

locally, then update env vars or code.

---

## Error: Production Database Tables Missing

Cause:

```txt
Migrations not applied
```

Fix:

```bash
DATABASE_URL="production-url" pnpm db:migrate
```

---

## Error: Clerk Redirect Fails

Cause:

```txt
Production domain not configured in Clerk
```

Fix:

Add Vercel/custom domain to Clerk allowed origins and redirect URLs.

---

## Error: Inngest Functions Not Appearing

Check:

```txt
/api/inngest route exists
Vercel deployment is live
INNGEST keys configured
Endpoint configured in Inngest dashboard
```

---

## Error: Database Connection Fails

Check:

```txt
DATABASE_URL
sslmode=require
Neon project status
Vercel env var value
Password encoding
```

---

# 21. Production Readiness Summary

Before real business use, confirm:

```txt
Authentication works
Organizations work
Tenant isolation tested
Database migrated
Backups understood
Journal balance SQL returns zero rows
Reports tested
Audit logs enabled
Admin permissions tested
Inngest configured
Production smoke test passed
Professional accounting/tax review completed
```

---

# 22. Final Operations Rule

For an accounting application, production operations must preserve:

```txt
Confidentiality
Integrity
Availability
Auditability
Recoverability
```

In plain language:

```txt
Keep data private.
Keep data correct.
Keep the app available.
Keep a record of important actions.
Be able to recover from mistakes.
```
