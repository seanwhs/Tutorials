Assuming you meant “give me an additional appendix,” here is a useful extra one.

# Appendix K — Quick Command Reference

This appendix collects the most important commands used throughout **GreyMatter Ledger**.

Use it as a fast terminal reference while developing, testing, migrating, and deploying the app.

---

# 1. Project Setup Commands

## Create the Next.js App

```bash
pnpm create next-app@latest greymatter-ledger
```

Recommended options:

```txt
TypeScript: Yes
ESLint: Yes
Tailwind CSS: Yes
App Router: Yes
src directory: No
Turbopack: Yes
Import alias: @/*
```

Move into the project:

```bash
cd greymatter-ledger
```

---

# 2. Development Commands

## Start Local Dev Server

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000
```

---

## Stop Dev Server

```txt
Ctrl + C
```

---

## Production Build

```bash
pnpm build
```

---

## Start Production Build Locally

First build:

```bash
pnpm build
```

Then start:

```bash
pnpm start
```

---

# 3. Health Check Commands

## Run Lint

```bash
pnpm lint
```

---

## Run Tests

```bash
pnpm test
```

---

## Run Tests in Watch Mode

```bash
pnpm test:watch
```

---

## Run Full Project Check

```bash
pnpm check
```

Expected script:

```json
"check": "pnpm lint && pnpm test && pnpm build"
```

This is the main command to run before commits and deployments.

---

# 4. Package Installation Commands

## Install Runtime Dependency

```bash
pnpm add package-name
```

Example:

```bash
pnpm add @clerk/nextjs
```

---

## Install Dev Dependency

```bash
pnpm add -D package-name
```

Example:

```bash
pnpm add -D vitest
```

---

## Install Project Dependencies

```bash
pnpm install
```

---

# 5. Clerk Commands / Setup Notes

There are no required Clerk CLI commands in this project.

Configure Clerk in the dashboard:

```txt
https://dashboard.clerk.com
```

Required local environment variables:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
CLERK_SECRET_KEY="sk_test_..."
NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"
```

---

# 6. Database / Drizzle Commands

## Generate Migration

```bash
pnpm db:generate
```

This reads:

```txt
db/schema.ts
```

and generates SQL migration files in:

```txt
drizzle/
```

---

## Apply Migrations

```bash
pnpm db:migrate
```

This applies migrations to the database configured by:

```bash
DATABASE_URL
```

---

## Open Drizzle Studio

```bash
pnpm db:studio
```

This opens a browser-based database viewer.

---

## Push Schema Directly

```bash
pnpm db:push
```

Use carefully.

For tutorial and production-like workflows, prefer:

```bash
pnpm db:generate
pnpm db:migrate
```

---

# 7. Production Migration Command

To run migrations against production without editing `.env.local`:

```bash
DATABASE_URL="postgresql://production-url" pnpm db:migrate
```

Windows PowerShell:

```powershell
$env:DATABASE_URL="postgresql://production-url"
pnpm db:migrate
```

---

# 8. Inngest Commands

## Start Inngest Dev Server

Run Next.js first:

```bash
pnpm dev
```

Then in another terminal:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

---

## Inngest Endpoint

Local:

```txt
http://localhost:3000/api/inngest
```

Production:

```txt
https://your-project.vercel.app/api/inngest
```

---

# 9. Git Commands

## Initialize Git

```bash
git init
```

---

## Check Status

```bash
git status
```

Short format:

```bash
git status --short
```

---

## Stage All Changes

```bash
git add .
```

---

## Commit

```bash
git commit -m "Commit message"
```

---

## View Remotes

```bash
git remote -v
```

---

## Add GitHub Remote

```bash
git remote add origin https://github.com/YOUR_USERNAME/greymatter-ledger.git
```

---

## Push to GitHub

```bash
git push -u origin main
```

---

# 10. Useful File Inspection Commands

## Print File Contents

macOS/Linux:

```bash
cat README.md
```

Windows PowerShell:

```powershell
Get-Content README.md
```

---

## List Files

macOS/Linux:

```bash
ls
```

Windows PowerShell:

```powershell
Get-ChildItem
```

---

## Show Current Directory

macOS/Linux:

```bash
pwd
```

Windows PowerShell:

```powershell
Get-Location
```

---

# 11. Common Cleanup Commands

## Remove Next.js Build Cache

macOS/Linux:

```bash
rm -rf .next
```

Windows PowerShell:

```powershell
Remove-Item -Recurse -Force .next
```

Then restart:

```bash
pnpm dev
```

---

## Remove `node_modules`

macOS/Linux:

```bash
rm -rf node_modules
```

Windows PowerShell:

```powershell
Remove-Item -Recurse -Force node_modules
```

Then reinstall:

```bash
pnpm install
```

---

# 12. Port Debugging Commands

## Find Process on Port 3000

macOS/Linux:

```bash
lsof -i :3000
```

Kill process:

```bash
kill -9 PID_HERE
```

Windows PowerShell:

```powershell
netstat -ano | findstr :3000
```

Kill process:

```powershell
taskkill /PID PID_HERE /F
```

---

# 13. Useful Neon SQL Queries

## List Tables

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

---

## List Columns for a Table

```sql
select
  column_name,
  data_type,
  is_nullable
from information_schema.columns
where table_name = 'journal_entries'
order by ordinal_position;
```

---

## List Indexes

```sql
select
  tablename,
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
order by tablename, indexname;
```

---

## Check Journal Entries Balance

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

## Inspect Recent Journal Entries

```sql
select
  id,
  entry_date,
  memo,
  source_type,
  source_id,
  is_reversed,
  created_at
from journal_entries
order by created_at desc
limit 20;
```

---

## Inspect Recent Journal Lines

```sql
select
  je.memo,
  jl.line_number,
  a.code,
  a.name,
  jl.debit_cents,
  jl.credit_cents
from journal_lines jl
join journal_entries je
  on je.id = jl.journal_entry_id
join accounts a
  on a.id = jl.account_id
order by je.created_at desc, jl.line_number
limit 100;
```

---

# 14. Tenant Isolation SQL Checks

## Invoice / Customer Organization Mismatch

Expected result:

```txt
0 rows
```

Query:

```sql
select
  i.id as invoice_id,
  i.organization_id as invoice_org,
  c.organization_id as customer_org
from invoices i
join customers c
  on c.id = i.customer_id
where i.organization_id <> c.organization_id;
```

---

## Bill / Vendor Organization Mismatch

Expected result:

```txt
0 rows
```

Query:

```sql
select
  b.id as bill_id,
  b.organization_id as bill_org,
  v.organization_id as vendor_org
from bills b
join vendors v
  on v.id = b.vendor_id
where b.organization_id <> v.organization_id;
```

---

## Journal Line / Account Organization Mismatch

Expected result:

```txt
0 rows
```

Query:

```sql
select
  jl.id as journal_line_id,
  jl.organization_id as line_org,
  a.organization_id as account_org
from journal_lines jl
join accounts a
  on a.id = jl.account_id
where jl.organization_id <> a.organization_id;
```

---

# 15. Application Smoke Test Routes

After starting:

```bash
pnpm dev
```

Check:

```txt
http://localhost:3000
http://localhost:3000/sign-in
http://localhost:3000/dashboard
http://localhost:3000/accounts
http://localhost:3000/customers
http://localhost:3000/vendors
http://localhost:3000/invoices
http://localhost:3000/bills
http://localhost:3000/payments
http://localhost:3000/reports
http://localhost:3000/bank
http://localhost:3000/settings
```

Diagnostic routes:

```txt
/settings/database
/settings/database/accounts
/settings/database/journal
/settings/database/invoices
/settings/audit-log
/settings/background-jobs
```

Report routes:

```txt
/reports/ledger-overview
/reports/profit-and-loss
/reports/balance-sheet
/reports/ar-aging
/reports/ap-aging
/reports/gst-f5
/reports/multi-currency
/reports/cpf-estimate
/reports/corporate-tax
```

---

# 16. Recommended Pre-Commit Routine

Before committing:

```bash
pnpm check
git status
```

If good:

```bash
git add .
git commit -m "Meaningful commit message"
```

---

# 17. Recommended Pre-Deployment Routine

Before deploying:

```bash
pnpm check
git status
git push
```

Then verify:

```txt
Vercel environment variables
Neon migrations
Clerk production URLs
Inngest endpoint
```

---

# 18. Most Important Commands

If you remember only a few commands, remember these:

```bash
pnpm dev
pnpm check
pnpm db:generate
pnpm db:migrate
pnpm db:studio
pnpm test
git status
git add .
git commit -m "message"
```

For Inngest local testing:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

For production migration:

```bash
DATABASE_URL="production-url" pnpm db:migrate
```
