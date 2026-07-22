# Appendix G — Testing Guide

This appendix documents the testing strategy for **GreyMatter Ledger**.

The goal is to help you understand:

```txt
What is tested
Why it is tested
How to run tests
Where tests live
What still needs more testing before serious production use
```

GreyMatter Ledger uses:

```txt
Vitest
TypeScript
Pure function unit tests
Manual integration testing through the app UI
```

---

# 1. Why Testing Matters in Accounting Software

Accounting software requires a higher level of correctness than many ordinary apps.

A visual bug is annoying.

A financial logic bug can be dangerous.

Examples:

```txt
Unbalanced journal entries
Incorrect GST calculation
Wrong report totals
Cross-tenant data leakage
Incorrect invoice payment status
Duplicate bank postings
```

Testing helps prevent these problems from returning after future changes.

The most important tested rule is:

```txt
Total debits must equal total credits.
```

---

# 2. Test Runner

GreyMatter Ledger uses:

```txt
Vitest
```

Vitest is a fast TypeScript-friendly test runner.

Test config:

```txt
vitest.config.ts
```

Test files live in:

```txt
tests/
```

Test file naming convention:

```txt
*.test.ts
```

Example:

```txt
tests/journal-validation.test.ts
```

---

# 3. Test Commands

Run all tests once:

```bash
pnpm test
```

Run tests in watch mode:

```bash
pnpm test:watch
```

Run full health check:

```bash
pnpm check
```

The full check runs:

```txt
lint
test
build
```

Expected `package.json` scripts:

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "test": "vitest --run",
    "test:watch": "vitest",
    "check": "pnpm lint && pnpm test && pnpm build",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio",
    "db:push": "drizzle-kit push"
  }
}
```

---

# 4. Vitest Configuration

Vitest config:

```txt
vitest.config.ts
```

Expected contents:

```ts
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["tests/**/*.test.ts"],
    globals: false,
  },
  resolve: {
    alias: {
      "@": fileURLToPath(new URL(".", import.meta.url)),
    },
  },
});
```

The alias config lets tests import project files like:

```ts
import { formatMoney } from "@/lib/money";
```

---

# 5. Current Test Coverage

GreyMatter Ledger includes tests for:

```txt
Money helpers
GST helpers
Journal validation
Journal validation errors
Report helper logic
Profit & Loss math
Balance Sheet math
GST F5-style report math
Aging bucket logic
Bank CSV parser
Currency helpers
CPF estimate helper
Corporate tax estimate helper
```

---

# 6. Money Tests

File:

```txt
tests/money.test.ts
```

Covers:

```txt
formatMoney()
dollarsToCents()
integer cents enforcement
negative amounts
invalid money strings
```

Important examples:

```ts
formatMoney(10900); // S$109.00
dollarsToCents("109.00"); // 10900
```

Why this matters:

```txt
All money in the app is stored as integer cents.
```

A failure here can affect everything.

---

# 7. GST Tests

File:

```txt
tests/gst.test.ts
```

Covers:

```txt
9% GST calculation
Zero-rated GST
GST rounding
Invoice line totals
Invalid quantities
Invalid decimal cents
```

Important example:

```txt
S$100.00 at 9% GST = S$9.00 GST
```

In cents:

```txt
10000 subtotal
900 GST
10900 total
```

Why this matters:

```txt
Invoices and bills rely on GST helpers.
```

---

# 8. Journal Validation Tests

File:

```txt
tests/journal-validation.test.ts
```

Covers:

```txt
Valid owner contribution entry
Valid GST invoice entry
Default source type
Input trimming
Unbalanced entries
Entries with fewer than two lines
Missing memo
Invalid dates
Invalid account UUIDs
Line with both debit and credit
Line with neither debit nor credit
Negative amounts
Decimal cents
Invalid source IDs
```

This is one of the most important test files.

The journal validation function is:

```ts
validatePostJournalEntryInput()
```

Location:

```txt
services/journal/validate-post-journal-entry.ts
```

Why this matters:

```txt
postJournalEntry() uses this validator.
```

So the tests protect real posting behavior.

---

# 9. Journal Error Tests

File:

```txt
tests/journal-errors.test.ts
```

Covers:

```txt
JournalEntryValidationError stores issues
Error message combines issues
Type guard identifies validation errors
Normal errors are not misclassified
```

Important helper:

```ts
isJournalEntryValidationError()
```

Why this matters:

```txt
Server actions use typed errors to show friendly validation messages.
```

---

# 10. Report Helper Tests

File:

```txt
tests/report-helpers.test.ts
```

Covers:

```txt
Report date validation
Invalid date ranges
Signed balance calculation
```

Signed balance behavior:

```txt
Assets: debit - credit
Expenses: debit - credit
Liabilities: credit - debit
Equity: credit - debit
Income: credit - debit
```

Why this matters:

```txt
Reports depend on signed balances.
```

---

# 11. Profit & Loss Tests

File:

```txt
tests/profit-and-loss.test.ts
```

Covers:

```txt
Net profit when income exceeds expenses
Net loss when expenses exceed income
Asset/liability/equity accounts ignored
```

Formula:

```txt
Net Profit = Income - Expenses
```

Why this matters:

```txt
P&L should include only income and expense accounts.
```

---

# 12. Balance Sheet Tests

File:

```txt
tests/balance-sheet.test.ts
```

Covers:

```txt
Assets
Liabilities
Equity
Current Year Earnings
Balance sheet difference
Unbalanced detection
```

Formula:

```txt
Assets = Liabilities + Equity
```

Current Year Earnings:

```txt
Income - Expenses
```

Why this matters:

```txt
Balance Sheet depends on correctly flowing P&L into equity.
```

---

# 13. Aging Tests

File:

```txt
tests/aging.test.ts
```

Covers:

```txt
Day difference calculation
Current bucket
1–30 bucket
31–60 bucket
61–90 bucket
90+ bucket
```

Why this matters:

```txt
AR/AP aging reports depend on accurate bucket classification.
```

---

# 14. GST F5-Style Report Tests

File:

```txt
tests/gst-f5-report.test.ts
```

Covers:

```txt
Net GST payable
Net GST refundable
Missing GST accounts default to zero
```

Formula:

```txt
GST Output Tax - GST Input Tax
```

Why this matters:

```txt
GST reporting depends on correct output/input tax summaries.
```

---

# 15. Bank CSV Parser Tests

File:

```txt
tests/bank-csv.test.ts
```

Covers:

```txt
Valid CSV parsing
Positive amounts
Negative amounts
Quoted descriptions with commas
Missing headers
Invalid rows
```

Expected CSV format:

```csv
date,description,amount
2026-01-05,Customer payment,109.00
2026-01-06,Vendor payment,-25.50
```

Why this matters:

```txt
Bank import is user-supplied file input.
```

User-supplied files must be validated carefully.

---

# 16. Currency Tests

File:

```txt
tests/currency.test.ts
```

Covers:

```txt
Supported currency detection
Foreign-to-base conversion
Rounding
Foreign currency formatting
```

Example:

```txt
USD 100.00 at 1.35 = SGD 135.00
```

In cents:

```txt
10000 × 13500 / 10000 = 13500
```

---

# 17. CPF Tests

File:

```txt
tests/cpf.test.ts
```

Covers:

```txt
Employee CPF estimate
Employer CPF estimate
Ordinary wage ceiling
Negative wage rejection
```

Important disclaimer:

```txt
CPF module is simplified and educational.
```

---

# 18. Corporate Tax Tests

File:

```txt
tests/corporate-tax.test.ts
```

Covers:

```txt
17% tax estimate
Losses not taxed
Custom tax rate
Decimal cent rejection
```

Important disclaimer:

```txt
Corporate tax module is simplified and educational.
```

---

# 19. What Is Not Fully Automated Yet

The current test suite focuses mostly on pure logic.

It does **not** fully automate:

```txt
Clerk authentication flows
Organization switching
Database integration workflows
Drizzle transaction behavior
Invoice creation end-to-end
Bill creation end-to-end
Payment posting end-to-end
Bank posting end-to-end
RBAC behavior
Inngest production behavior
Browser UI workflows
```

Those were tested manually throughout the tutorial.

For real production, these should be expanded.

---

# 20. Recommended Future Test Types

## Unit Tests

Already used.

Good for:

```txt
Pure functions
Validation
Calculations
Report math
Parsers
```

---

## Integration Tests

Recommended next step.

Should test:

```txt
Database writes
Journal posting
Invoice creation
Bill creation
Payments
Bank posting
Reversals
```

These require a test database.

---

## End-to-End Tests

Use a browser automation tool such as:

```txt
Playwright
```

Should test:

```txt
Sign in
Create organization
Seed accounts
Create invoice
Record payment
View reports
```

---

## Authorization Tests

Should verify:

```txt
Non-admin cannot view audit log
Non-admin cannot reverse journal entries
User cannot access another organization’s records
```

---

# 21. Recommended Test Database Strategy

For future integration tests:

```txt
Use a separate Neon branch or local Postgres database.
Set DATABASE_URL_TEST.
Run migrations before tests.
Seed test organization and accounts.
Clean database after tests.
```

Example environment variable:

```bash
DATABASE_URL_TEST="postgresql://..."
```

Possible test command:

```bash
pnpm test:integration
```

---

# 22. Manual Test Checklist

Even with automated tests, run a manual smoke test after major changes.

Checklist:

```txt
Sign in
Select organization
Seed chart of accounts
Create customer
Create invoice
Record customer payment
Create vendor
Create bill
Record vendor payment
Import bank CSV
Categorize bank transaction
Post bank transaction
Reconcile bank transaction
Reverse a journal entry as admin
Open Profit & Loss
Open Balance Sheet
Open GST report
Open audit log
Trigger Inngest health check
```

---

# 23. Journal Balance SQL Test

Run this query occasionally in development or production diagnostics:

```sql
select
  je.id,
  je.memo,
  sum(jl.debit_cents) as total_debit_cents,
  sum(jl.credit_cents) as total_credit_cents,
  sum(jl.debit_cents) - sum(jl.credit_cents) as difference_cents
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

If this query returns rows, investigate immediately.

---

# 24. Tenant Isolation SQL Tests

Check invoice/customer organization mismatch:

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

Expected:

```txt
0 rows
```

Check bill/vendor organization mismatch:

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

Expected:

```txt
0 rows
```

Check journal line/account organization mismatch:

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

Expected:

```txt
0 rows
```

---

# 25. How to Add a New Test

Create a file:

```txt
tests/example.test.ts
```

Use:

```ts
import { describe, expect, it } from "vitest";

describe("feature", () => {
  it("does something", () => {
    expect(1 + 1).toBe(2);
  });
});
```

Run:

```bash
pnpm test
```

---

# 26. Good Test Naming

Prefer descriptive test names.

Good:

```ts
it("rejects unbalanced journal entries", () => {
  // ...
});
```

Less useful:

```ts
it("works", () => {
  // ...
});
```

A future maintainer should understand the behavior from the test name.

---

# 27. What to Test When Adding New Accounting Features

For every new accounting feature, add tests for:

```txt
Valid balanced posting
Unbalanced posting rejection
Integer cents validation
Negative amount rejection
Tenant ownership validation
Inactive account rejection
Report impact
Audit log behavior
```

If the feature involves tax:

```txt
Rate calculation
Rounding
Zero-rate behavior
Invalid rate rejection
```

If the feature involves dates:

```txt
Valid date
Invalid date
Boundary dates
Date range behavior
```

---

# 28. CI Recommendation

For production projects, run this in CI:

```bash
pnpm install
pnpm check
```

Optional future CI steps:

```bash
pnpm db:generate
pnpm test:integration
npx playwright test
```

---

# 29. Troubleshooting Tests

## Error: Vitest Cannot Resolve `@/`

Check:

```txt
vitest.config.ts
```

It should include:

```ts
resolve: {
  alias: {
    "@": fileURLToPath(new URL(".", import.meta.url)),
  },
}
```

---

## Error: No Test Files Found

Make sure tests are in:

```txt
tests/
```

and named:

```txt
*.test.ts
```

---

## Error: Currency Format Differs

Some environments may format currency slightly differently.

If a test fails on formatting, inspect output:

```ts
console.log(formatMoney(10900));
```

Adjust carefully.

Do not weaken financial formatting tests too much.

---

## Error: `pnpm check` Fails on Build, Not Tests

The build may require:

```txt
DATABASE_URL
CLERK_SECRET_KEY
```

Make sure `.env.local` is configured.

---

# 30. Final Testing Mindset

The most important testing principle for GreyMatter Ledger is:

```txt
Test financial invariants, not just screens.
```

Key invariants:

```txt
Journal entries balance.
Money is integer cents.
Reports come from journal lines.
Tenant data stays isolated.
Payments do not duplicate revenue or expenses.
Reversals cancel original entries.
```

If those invariants hold, the accounting foundation is strong.

If those invariants break, the app cannot be trusted.
