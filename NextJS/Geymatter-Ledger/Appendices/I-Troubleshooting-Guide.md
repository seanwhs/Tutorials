# Appendix I — Troubleshooting Guide

This appendix collects common errors you may encounter while building, running, testing, and deploying **GreyMatter Ledger**.

It is organized by area:

```txt
Project setup
Next.js
Clerk
Organizations
Neon and Drizzle
Database schema
Journal engine
Invoices and bills
Payments
Reports
Bank import
Inngest
Vercel deployment
Testing
```

Use this guide when something fails and you need a quick diagnosis path.

---

# 1. General Debugging Workflow

When something breaks, follow this order:

```txt
1. Read the first error carefully.
2. Identify which layer failed.
3. Check recent code changes.
4. Verify environment variables.
5. Restart the dev server.
6. Run pnpm check.
7. Check database migrations.
8. Check browser console and terminal logs.
```

Most errors are caused by one of these:

```txt
Missing environment variable
Dev server not restarted
Migration not applied
Wrong active organization
Missing seeded accounts
Route file in wrong folder
Import path typo
```

---

# 2. Project Setup Errors

## Error: `node: command not found`

Node.js is not installed or not available in your terminal.

Fix:

Install Node.js from:

```txt
https://nodejs.org
```

Then close and reopen your terminal.

Verify:

```bash
node --version
```

Recommended:

```txt
Node.js 20 or newer
```

---

## Error: `pnpm: command not found`

Install pnpm:

```bash
npm install --global pnpm
```

Verify:

```bash
pnpm --version
```

Alternative:

```bash
corepack enable
corepack prepare pnpm@latest --activate
pnpm --version
```

---

## Error: `git: command not found`

Install Git from:

```txt
https://git-scm.com
```

Verify:

```bash
git --version
```

---

# 3. Next.js Errors

## Error: Route shows 404

Check App Router structure.

Correct:

```txt
app/invoices/page.tsx
```

Creates:

```txt
/invoices
```

Correct dynamic route:

```txt
app/invoices/[invoiceId]/page.tsx
```

Creates:

```txt
/invoices/:invoiceId
```

Incorrect:

```txt
app/invoices.tsx
app/invoices/[invoiceId].tsx
```

---

## Error: `Cannot find module '@/...'`

Check `tsconfig.json`.

It should include:

```json
"paths": {
  "@/*": ["./*"]
}
```

Restart TypeScript server in VS Code:

```txt
Command Palette -> TypeScript: Restart TS Server
```

Restart dev server:

```bash
Ctrl + C
pnpm dev
```

---

## Error: App does not reflect environment variable changes

Restart the dev server:

```bash
Ctrl + C
pnpm dev
```

Next.js reads environment variables when the dev server starts.

---

## Error: Port 3000 already in use

Use the alternate port shown by Next.js, or kill the process.

macOS/Linux:

```bash
lsof -i :3000
kill -9 PID_HERE
```

Windows PowerShell:

```powershell
netstat -ano | findstr :3000
taskkill /PID PID_HERE /F
```

---

# 4. Next.js 16 Proxy Errors

## Error: Protected routes are not redirecting

For Next.js 16, the file should be:

```txt
proxy.ts
```

not:

```txt
middleware.ts
```

It must be in the project root.

Check it includes protected routes:

```ts
const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
  "/accounts(.*)",
  "/customers(.*)",
  "/vendors(.*)",
  "/invoices(.*)",
  "/bills(.*)",
  "/payments(.*)",
  "/reports(.*)",
  "/bank(.*)",
  "/settings(.*)",
  "/onboarding(.*)",
]);
```

Restart:

```bash
Ctrl + C
pnpm dev
```

---

# 5. Clerk Authentication Errors

## Error: Clerk publishable key missing

Check `.env.local`:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
```

Restart dev server.

---

## Error: Clerk secret key missing

Check `.env.local`:

```bash
CLERK_SECRET_KEY="sk_test_..."
```

Do not prefix it with:

```txt
NEXT_PUBLIC_
```

Restart dev server.

---

## Error: `/sign-in` shows 404

Check route:

```txt
app/sign-in/[[...sign-in]]/page.tsx
```

It must use double brackets:

```txt
[[...sign-in]]
```

---

## Error: `/sign-up` shows 404

Check route:

```txt
app/sign-up/[[...sign-up]]/page.tsx
```

---

## Error: Sign-in works but does not redirect to dashboard

Check `.env.local`:

```bash
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"
```

Also check SignIn/SignUp components use:

```tsx
fallbackRedirectUrl="/dashboard"
```

---

# 6. Clerk Organization Errors

## Error: Organization switcher does not show

Make sure Clerk Organizations are enabled in Clerk dashboard.

Check component:

```txt
components/organization-controls.tsx
```

It should use:

```tsx
<OrganizationSwitcher />
```

---

## Error: No active organization selected

Create or select an organization:

```txt
/onboarding/organization
```

Then open:

```txt
/dashboard
```

This syncs the organization to the database.

---

## Error: `auth()` returns no `orgId`

Usually means no active organization.

Use the organization switcher in the header.

---

## Error: Local database organization row not created

Open:

```txt
/dashboard
```

or any page that calls:

```ts
getOrCreateCurrentOrganization()
```

Check database:

```sql
select *
from organizations;
```

---

# 7. Neon and Database Errors

## Error: `DATABASE_URL is missing`

Check `.env.local`:

```bash
DATABASE_URL="postgresql://..."
```

Restart dev server.

For Drizzle commands, make sure:

```txt
drizzle.config.ts
```

loads `.env.local`:

```ts
config({ path: ".env.local" });
```

---

## Error: SSL connection issue

Neon URLs should usually include:

```txt
sslmode=require
```

Example:

```bash
DATABASE_URL="postgresql://user:password@host/database?sslmode=require"
```

---

## Error: Password contains special characters

Characters may need URL encoding.

Examples:

```txt
@ -> %40
# -> %23
& -> %26
```

Best fix:

```txt
Copy the connection string directly from Neon.
```

---

# 8. Drizzle Errors

## Error: Drizzle cannot find schema

Check:

```txt
db/schema.ts
```

Check:

```txt
drizzle.config.ts
```

has:

```ts
schema: "./db/schema.ts"
```

---

## Error: Table does not exist

Example:

```txt
relation "accounts" does not exist
```

Cause:

```txt
Migration not applied.
```

Fix:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Enum does not exist

Example:

```txt
type "account_type" does not exist
```

Fix:

```bash
pnpm db:migrate
```

If migration file missing:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Relation already exists

This usually means:

```txt
Table was manually created
Migration partially applied
Database state drifted
```

For tutorial development, easiest fix:

```txt
Create a fresh Neon branch/database.
Update DATABASE_URL.
Run pnpm db:migrate.
```

For production, do not casually drop tables.

---

# 9. Schema Ordering Errors

## Error: Table used before declaration

Example:

```txt
journalEntries is used before declaration
```

Cause:

A table references another table before it is declared.

Fix:

Reorder `db/schema.ts`.

A safe order:

```txt
enums
organizations
accounts
customers
vendors
journal_entries
journal_lines
invoices
invoice_lines
customer_payments
bills
bill_lines
vendor_payments
bank_imports
bank_transactions
audit_logs
recurring_invoices
```

Referenced tables should be declared before referencing tables.

---

# 10. Chart of Accounts Errors

## Error: Accounts page says no active organization

Create/select organization.

Open:

```txt
/onboarding/organization
```

Then:

```txt
/accounts
```

---

## Error: Required account missing

Examples:

```txt
Required account 1100 is missing
Required account 2000 is missing
Required account 1000 Bank is missing
```

Fix:

Open:

```txt
/accounts
```

Click:

```txt
Seed default accounts
```

---

## Error: Required account inactive

Open:

```txt
/accounts
```

Find account.

Click:

```txt
Reactivate
```

---

## Error: Duplicate account code

Account codes are unique per organization.

Use a different code.

---

# 11. Journal Engine Errors

## Error: Journal entry is unbalanced

Debits do not equal credits.

Check totals.

Example invalid:

```txt
Debit  Bank S$100
Credit Revenue S$90
```

Correct:

```txt
Debit  Bank S$100
Credit Revenue S$100
```

---

## Error: A line cannot have both debit and credit

Invalid:

```ts
{
  debitCents: 10000,
  creditCents: 10000,
}
```

Fix:

Use one side only.

---

## Error: A line must have either debit or credit

Invalid:

```ts
{
  debitCents: 0,
  creditCents: 0,
}
```

Fix:

Provide a positive amount on one side.

---

## Error: Account does not exist for active organization

The account ID is wrong or belongs to another organization.

Fix:

Use accounts from the active organization.

---

## Error: `db.transaction is not a function`

Update Drizzle and Neon packages:

```bash
pnpm add drizzle-orm@latest @neondatabase/serverless@latest
pnpm add -D drizzle-kit@latest
```

---

# 12. Invoice Errors

## Error: Customer does not exist for active organization

Create customer under the same active organization.

Open:

```txt
/customers
```

---

## Error: Invoice total constraint fails

The database requires:

```txt
total_cents = subtotal_cents + gst_cents
```

Check GST calculation helper.

---

## Error: Invoice has no journal entry

Older invoice may have been created before journal posting.

Create a new invoice using current form.

---

## Error: Invoice detail shows not found

Possible causes:

```txt
Wrong invoice ID
Invoice belongs to another organization
No active organization
```

Go back to:

```txt
/invoices
```

and click from the list.

---

# 13. Bill Errors

## Error: Vendor does not exist for active organization

Create vendor under same organization.

Open:

```txt
/vendors
```

---

## Error: Bill total constraint fails

The database requires:

```txt
total_cents = subtotal_cents + gst_cents
```

---

## Error: Bill detail shows not found

Possible causes:

```txt
Wrong bill ID
Bill belongs to another organization
No active organization
```

Go back to:

```txt
/bills
```

and click from the list.

---

# 14. Payment Errors

## Error: Invoice already paid

The tutorial supports full payment once per invoice.

Create a new invoice to test again.

---

## Error: Bill already paid

The tutorial supports full payment once per bill.

Create a new bill to test again.

---

## Error: Payment form not visible

The invoice or bill may already be paid or void.

---

## Error: Required bank account missing

Open:

```txt
/accounts
```

Seed default accounts.

Required:

```txt
1000 Bank
```

---

# 15. Report Errors

## Error: Profit & Loss shows no data

Check:

```txt
Have you created invoices or bills?
Are journal entries posted?
Is date range wide enough?
Are you in the correct organization?
```

Try range:

```txt
2020-01-01 to 2030-12-31
```

---

## Error: Balance Sheet does not balance

Run SQL:

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

## Error: GST report shows zero

Check:

```txt
Did you create GST invoice or bill?
Are accounts coded 1400 and 2110?
Is date range wide enough?
```

---

## Error: Aging report shows no rows

Paid and void documents are excluded.

Create an unpaid invoice or bill.

---

# 16. Bank Import Errors

## Error: CSV header missing

CSV must include:

```csv
date,description,amount
```

---

## Error: Row date invalid

Use:

```txt
YYYY-MM-DD
```

Example:

```txt
2026-01-05
```

---

## Error: Amount invalid

Use:

```txt
109.00
-25.50
```

---

## Error: No accounts in categorization dropdown

Open:

```txt
/accounts
```

Seed accounts.

---

## Error: Only categorized transactions can be posted

Choose a category account and save first.

---

## Error: Only posted transactions can be reconciled

Post the transaction before reconciliation.

---

## Error: Transaction already reconciled

Reconciled transactions are locked.

---

# 17. Inngest Errors

## Error: `/api/inngest` not found

Check route:

```txt
app/api/inngest/route.ts
```

---

## Error: Inngest function does not appear

Check:

```txt
inngest/functions.ts
```

The function must be included in:

```ts
inngestFunctions
```

---

## Error: Dev server cannot connect

Run Next.js:

```bash
pnpm dev
```

Then in another terminal:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

---

## Error: Invoice created event does not fire

Check invoice service sends:

```ts
inngest.send({
  name: inngestEvents.invoiceCreated,
  ...
});
```

---

# 18. Vercel Deployment Errors

## Error: Build fails on Vercel

Common causes:

```txt
Missing environment variables
TypeScript error
Lint error
Test failure
```

Run locally:

```bash
pnpm check
```

Then verify Vercel env vars.

---

## Error: Production database tables missing

Run migrations against production:

```bash
DATABASE_URL="production_database_url" pnpm db:migrate
```

---

## Error: Clerk auth fails in production

Check Clerk dashboard:

```txt
Allowed origins
Redirect URLs
Production keys
```

Add:

```txt
https://your-project.vercel.app
```

---

## Error: Inngest production functions missing

Check Inngest endpoint:

```txt
https://your-project.vercel.app/api/inngest
```

Check Vercel env vars:

```txt
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
```

---

# 19. Testing Errors

## Error: Vitest cannot resolve `@/`

Check:

```txt
vitest.config.ts
```

It should include:

```ts
alias: {
  "@": fileURLToPath(new URL(".", import.meta.url)),
}
```

---

## Error: No test files found

Tests should be in:

```txt
tests/
```

and end with:

```txt
.test.ts
```

---

## Error: Currency formatting test fails

Intl output may differ slightly between environments.

Inspect actual output and adjust carefully.

---

# 20. Emergency Debug Commands

Run full check:

```bash
pnpm check
```

Run tests:

```bash
pnpm test
```

Run build:

```bash
pnpm build
```

Run migrations:

```bash
pnpm db:migrate
```

Open Drizzle Studio:

```bash
pnpm db:studio
```

Restart dev server:

```bash
Ctrl + C
pnpm dev
```

Clear Next build cache:

```bash
rm -rf .next
pnpm dev
```

Windows PowerShell:

```powershell
Remove-Item -Recurse -Force .next
pnpm dev
```

---

# 21. Final Troubleshooting Rule

When in doubt, check these five things first:

```txt
1. Is the active organization selected?
2. Are environment variables present?
3. Have migrations been applied?
4. Are required accounts seeded and active?
5. Does pnpm check pass?
```

Most issues in GreyMatter Ledger trace back to one of those.
