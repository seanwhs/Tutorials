# Developer Onboarding Guide

**Product:** GreyMatter Ledger  
**Document type:** Developer Onboarding Guide  
**Version:** 1.0  
**Status:** Draft  
**Audience:** New developers, contributors, maintainers, technical reviewers  
**Goal:** Help a developer set up, understand, run, test, and safely extend GreyMatter Ledger  

---

# 1. Welcome

Welcome to **GreyMatter Ledger**.

GreyMatter Ledger is a Singapore-ready, multi-tenant, double-entry accounting web application.

It is built with:

```txt
Next.js
TypeScript
Tailwind CSS
Clerk
Neon Postgres
Drizzle ORM
Inngest
Vercel
Vitest
```

This guide helps you become productive in the codebase.

By the end, you should understand:

```txt
How to set up the project
How to run it locally
How the architecture is organized
How accounting workflows work
How to run tests
How to make safe changes
How to avoid common mistakes
```

---

# 2. What You Should Know First

You do not need to be an accountant, but you should understand the basics of:

```txt
TypeScript
React
Next.js App Router
Server Actions
SQL / relational databases
Environment variables
Git
```

You should also read these primers before making accounting-related changes:

```txt
Primer 1 — Double-Entry Accounting for Developers
Primer 2 — SaaS Multi-Tenancy and Organization Isolation
Primer 3 — Money, Cents, Rounding, and Financial Precision
Primer 5 — Ledger-Based Reporting
Primer 6 — Authentication vs Authorization
```

The two most important rules:

```txt
Every journal entry must balance.
Every company’s data must be isolated by organization_id.
```

---

# 3. Repository Overview

Typical repository structure:

```txt
greymatter-ledger/
  app/
  components/
  db/
  drizzle/
  docs/
  inngest/
  lib/
  services/
  tests/
  public/
  package.json
  tsconfig.json
  drizzle.config.ts
  vitest.config.ts
  proxy.ts
```

---

# 4. Key Directories

## 4.1 `app/`

Contains Next.js App Router routes.

Examples:

```txt
app/page.tsx
app/dashboard/page.tsx
app/accounts/page.tsx
app/invoices/page.tsx
app/invoices/[invoiceId]/page.tsx
app/api/inngest/route.ts
```

Use this folder for:

```txt
Pages
Route handlers
Server actions colocated with routes
```

---

## 4.2 `components/`

Contains reusable UI components.

Examples:

```txt
app-layout.tsx
app-header.tsx
account-create-form.tsx
invoice-create-form.tsx
bill-create-form.tsx
report-date-range-form.tsx
```

Use this folder for:

```txt
Tables
Forms
Banners
Layout
Reusable UI sections
```

Avoid placing core business logic here.

---

## 4.3 `services/`

Contains business logic and database workflows.

Examples:

```txt
services/invoices/invoice-services.ts
services/bills/bill-services.ts
services/journal/post-journal-entry.ts
services/reports/profit-and-loss-service.ts
services/bank/post-bank-transaction.ts
```

Use this folder for:

```txt
Tenant-safe queries
Mutations
Accounting workflows
Report services
Payment services
Bank services
Audit logging
```

Most serious changes belong here.

---

## 4.4 `lib/`

Contains shared utilities and pure domain helpers.

Examples:

```txt
lib/money.ts
lib/accounting/gst.ts
lib/accounting/normal-balance.ts
lib/reports/date-range.ts
lib/reports/balance-sign.ts
lib/currency.ts
lib/singapore/cpf.ts
```

Use this folder for:

```txt
Pure functions
Types
Formatting
Validation
Calculation helpers
```

These files should usually be easy to unit test.

---

## 4.5 `db/`

Contains Drizzle database setup.

```txt
db/schema.ts
db/index.ts
```

Use this folder for:

```txt
Schema definitions
Database client
Table types
```

---

## 4.6 `drizzle/`

Contains generated SQL migrations.

Do not casually edit generated migrations unless you know exactly what you are doing.

Commit migration files to Git.

---

## 4.7 `inngest/`

Contains background job setup.

```txt
inngest/client.ts
inngest/events.ts
inngest/functions.ts
```

Use this folder for:

```txt
Event definitions
Background functions
Scheduled jobs
```

---

## 4.8 `tests/`

Contains Vitest tests.

Examples:

```txt
tests/journal-validation.test.ts
tests/gst.test.ts
tests/balance-sheet.test.ts
tests/bank-csv.test.ts
```

Add tests here when changing pure logic.

---

## 4.9 `docs/`

Contains documentation.

Recommended structure:

```txt
docs/
  PRD.md
  user-manual.md
  test-plan.md
  architecture-addendum.md
  appendices/
  primers/
```

---

# 5. Local Setup

## 5.1 Install Prerequisites

Required:

```txt
Node.js 20+
pnpm
Git
VS Code or similar editor
```

Check:

```bash
node --version
pnpm --version
git --version
```

---

## 5.2 Install Dependencies

From project root:

```bash
pnpm install
```

---

## 5.3 Configure Environment Variables

Create:

```txt
.env.local
```

Use `.env.example` as a reference.

Minimum required:

```bash
DATABASE_URL="postgresql://user:password@host/database?sslmode=require"

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
CLERK_SECRET_KEY="sk_test_..."

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"
```

Optional for background job production-like testing:

```bash
INNGEST_EVENT_KEY="..."
INNGEST_SIGNING_KEY="..."
```

Never commit `.env.local`.

---

## 5.4 Run Database Migrations

```bash
pnpm db:migrate
```

If schema changed and migration does not exist:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## 5.5 Start Dev Server

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000
```

---

# 6. Common Commands

## Development

```bash
pnpm dev
```

## Build

```bash
pnpm build
```

## Lint

```bash
pnpm lint
```

## Test

```bash
pnpm test
```

## Test Watch

```bash
pnpm test:watch
```

## Full Check

```bash
pnpm check
```

## Generate Migration

```bash
pnpm db:generate
```

## Apply Migration

```bash
pnpm db:migrate
```

## Drizzle Studio

```bash
pnpm db:studio
```

## Inngest Dev Server

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

---

# 7. First Local Smoke Test

After setup:

1. Start app:

```bash
pnpm dev
```

2. Open:

```txt
http://localhost:3000
```

3. Sign up or sign in.

4. Create organization:

```txt
Merlion Creative Pte. Ltd.
```

5. Open:

```txt
/accounts
```

6. Seed default accounts.

7. Create customer.

8. Create invoice.

9. Open:

```txt
/settings/database/journal
```

10. Confirm journal entry is balanced.

---

# 8. Core Architecture Mental Model

GreyMatter Ledger follows this flow:

```txt
UI Page
  |
  v
Server Action
  |
  v
Service
  |
  v
Journal Engine / Domain Logic
  |
  v
Drizzle ORM
  |
  v
Postgres
```

Example invoice flow:

```txt
Invoice form
  |
  v
createInvoiceAction()
  |
  v
createInvoiceForCurrentOrganization()
  |
  v
GST calculation
  |
  v
invoice + invoice_lines inserted
  |
  v
journal entry posted
  |
  v
audit log + Inngest event
```

---

# 9. Accounting Rules Developers Must Respect

## 9.1 Store Money as Integer Cents

Good:

```ts
const amountCents = 10900;
```

Bad:

```ts
const amount = 109.00;
```

---

## 9.2 Use Basis Points for Rates

Examples:

```txt
9% GST = 900
17% tax = 1700
20% CPF = 2000
```

---

## 9.3 Never Post Unbalanced Entries

Every journal entry must satisfy:

```ts
totalDebitCents === totalCreditCents
```

---

## 9.4 Do Not Duplicate Revenue on Payment

Invoice records revenue.

Payment settles receivable.

Correct customer payment:

```txt
Debit Bank
Credit Accounts Receivable
```

Do not:

```txt
Credit Sales Revenue again
```

---

## 9.5 Do Not Duplicate Expense on Vendor Payment

Bill records expense.

Payment settles payable.

Correct vendor payment:

```txt
Debit Accounts Payable
Credit Bank
```

Do not:

```txt
Debit Expense again
```

---

# 10. Multi-Tenancy Rules Developers Must Respect

## 10.1 Never Trust Organization ID from Browser

Bad:

```ts
const organizationId = formData.get("organizationId");
```

Good:

```ts
const organization = await requireCurrentDatabaseOrganization();
```

---

## 10.2 Always Scope Queries

Bad:

```ts
await db.select().from(invoices);
```

Good:

```ts
await db
  .select()
  .from(invoices)
  .where(eq(invoices.organizationId, organization.id));
```

---

## 10.3 Check Related Record Ownership

Example:

Before creating invoice, verify customer belongs to active organization.

```ts
const [customer] = await db
  .select()
  .from(customers)
  .where(
    and(
      eq(customers.id, input.customerId),
      eq(customers.organizationId, organization.id),
    ),
  );
```

---

# 11. Where to Add New Code

## New Page

Use:

```txt
app/your-route/page.tsx
```

---

## New Form Action

Use route-local action file:

```txt
app/your-route/actions.ts
```

---

## New Business Workflow

Use:

```txt
services/your-domain/
```

Example:

```txt
services/credit-notes/credit-note-services.ts
```

---

## New Pure Helper

Use:

```txt
lib/
```

Example:

```txt
lib/accounting/tax-codes.ts
```

---

## New Database Table

Edit:

```txt
db/schema.ts
```

Then run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## New Background Job

Edit:

```txt
inngest/functions.ts
```

If adding new event names, edit:

```txt
inngest/events.ts
```

---

## New Tests

Add:

```txt
tests/your-feature.test.ts
```

---

# 12. Adding a New Accounting Workflow

When adding a new accounting workflow, follow this checklist:

```txt
1. Does it need a source document table?
2. Does the table include organization_id?
3. Does it need line items?
4. Does it need status?
5. Does it post a journal entry?
6. Which accounts does it debit and credit?
7. Does it need GST?
8. Does it need an audit log?
9. Does it affect reports?
10. Does it need tests?
```

---

## Example: Future Credit Note Workflow

Potential entry:

```txt
Debit  Sales Revenue
Debit  GST Output Tax
Credit Accounts Receivable
```

Required architecture:

```txt
credit_notes
credit_note_lines
credit note service
journal posting
audit log
invoice balance impact
tests
```

---

# 13. Database Change Workflow

When changing schema:

1. Edit:

```txt
db/schema.ts
```

2. Generate migration:

```bash
pnpm db:generate
```

3. Review SQL in:

```txt
drizzle/
```

4. Apply migration:

```bash
pnpm db:migrate
```

5. Run:

```bash
pnpm check
```

6. Commit:

```bash
git add .
git commit -m "Describe schema change"
```

---

# 14. Testing Expectations

Before opening a PR or committing major work:

```bash
pnpm check
```

This should pass.

If adding pure logic, add tests.

Good candidates for tests:

```txt
Money
GST
Journal validation
Report calculations
CSV parsing
Tax calculations
Date calculations
```

---

# 15. Manual Testing Expectations

For accounting workflows, also manually test.

Example invoice workflow:

1. Create customer.
2. Create invoice.
3. Open invoice detail.
4. Verify linked journal entry.
5. Verify report impact.
6. Verify audit log.

Example payment workflow:

1. Open unpaid invoice.
2. Record payment.
3. Verify invoice status paid.
4. Verify payment journal entry.
5. Verify payment appears on `/payments`.

---

# 16. Useful Diagnostic Pages

Development and admin diagnostics:

```txt
/settings/auth-status
/settings/database
/settings/database/accounts
/settings/database/journal
/settings/database/invoices
/settings/database/organizations
/settings/audit-log
/settings/background-jobs
```

Reports:

```txt
/reports/ledger-overview
/reports/profit-and-loss
/reports/balance-sheet
/reports/gst-f5
```

---

# 17. Important SQL Checks

## Journal Balance Check

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

## Tenant Mismatch Check: Journal Lines and Accounts

```sql
select
  jl.id,
  jl.organization_id as line_org,
  a.organization_id as account_org
from journal_lines jl
join accounts a
  on a.id = jl.account_id
where jl.organization_id <> a.organization_id;
```

Expected:

```txt
0 rows
```

---

# 18. Code Review Checklist

When reviewing changes, ask:

```txt
Does this preserve tenant isolation?
Does this use integer cents?
Does this avoid floating-point money?
Does this post balanced journal entries?
Does this verify related record ownership?
Does this need an audit log?
Does this need admin authorization?
Does this need tests?
Does this affect reports?
Does this require a migration?
```

---

# 19. Pull Request Checklist

Before merging:

```txt
pnpm check passes
Migrations reviewed
No secrets committed
Tenant filters present
Journal rules respected
Tests added where needed
Manual workflow tested
Docs updated if behavior changed
```

---

# 20. Common Mistakes for New Developers

## Mistake 1 — Querying Without Organization

Bad:

```ts
await db.select().from(customers);
```

Fix:

```ts
.where(eq(customers.organizationId, organization.id))
```

---

## Mistake 2 — Storing Dollars Instead of Cents

Bad:

```ts
totalCents: 109.00
```

Fix:

```ts
totalCents: 10900
```

---

## Mistake 3 — Posting Directly to Journal Tables

Avoid direct inserts unless you are inside a carefully designed service.

Prefer:

```ts
postJournalEntry()
```

or equivalent validated workflow.

---

## Mistake 4 — Hiding Button Instead of Authorizing

Bad:

```tsx
{isAdmin && <button>Reverse</button>}
```

without server enforcement.

Fix:

```ts
await requireOrganizationAdmin();
```

---

## Mistake 5 — Forgetting Audit Logs

Important financial actions should write audit logs.

---

# 21. Suggested First Tasks for New Developers

Good beginner tasks:

```txt
Improve empty states
Add report descriptions
Add small UI polish
Add tests for existing helpers
Improve docs
Add better validation messages
```

Intermediate tasks:

```txt
Add credit note schema
Add invoice PDF mock
Add export CSV for reports
Add partial payment model proposal
Improve bank duplicate detection
```

Advanced tasks:

```txt
Partial payments
Credit notes
Period close
Full GST tax code system
System-context recurring invoice scheduler
Integration tests
Playwright E2E tests
```

---

# 22. Development Safety Rules

Before changing accounting logic:

```txt
Read Primer 1.
Read Appendix C.
Run current tests.
Add new tests.
Manually test journal impact.
Run journal balance SQL.
```

Before changing multi-tenancy logic:

```txt
Read Primer 2.
Read Appendix E.
Test with two organizations.
Try cross-tenant URLs.
```

Before changing database schema:

```txt
Read Primer 7.
Review generated SQL.
Use a dev database first.
```

---

# 23. Final Onboarding Checklist

A new developer is ready to contribute when they can:

- [ ] Run the app locally
- [ ] Sign in with Clerk
- [ ] Create/select organization
- [ ] Run migrations
- [ ] Seed chart of accounts
- [ ] Create invoice
- [ ] Record payment
- [ ] Run reports
- [ ] Run `pnpm test`
- [ ] Run `pnpm check`
- [ ] Explain why journal entries must balance
- [ ] Explain why organization filters are required
- [ ] Add a small tested helper function

---

# 24. Final Advice

GreyMatter Ledger is not just a UI project.

It is accounting infrastructure.

When making changes, optimize for:

```txt
Correctness
Traceability
Tenant safety
Clarity
Testability
```

The most important developer habit:

```txt
Do not bypass the ledger.
```

The second most important habit:

```txt
Do not bypass organization isolation.
```

If you preserve those two principles, the system can grow safely.
