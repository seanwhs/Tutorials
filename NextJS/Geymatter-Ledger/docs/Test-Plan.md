# GreyMatter Ledger Test Plan

**Document type:** Test Plan  
**Product:** GreyMatter Ledger  
**Version:** 1.0  
**Status:** Draft  
**Audience:** QA engineers, developers, product owners, technical reviewers  
**Application type:** Multi-tenant accounting SaaS web application  
**Primary region focus:** Singapore  

---

# 1. Purpose

This test plan defines how to verify that **GreyMatter Ledger** works correctly, securely, and reliably.

GreyMatter Ledger handles accounting data, so testing must cover more than visual behavior.

The test plan must verify:

```txt
Accounting correctness
Multi-tenant data isolation
Authentication and authorization
Database integrity
GST calculations
Journal posting
Financial reports
Payments
Bank import and reconciliation
Auditability
Background jobs
Deployment readiness
```

The most important accounting invariant is:

```txt
Total debits must equal total credits.
```

The most important SaaS security invariant is:

```txt
One organization must never access another organization’s data.
```

---

# 2. Scope

## 2.1 In Scope

This test plan covers:

- Public landing page
- Authentication
- Organization creation and switching
- Database connectivity
- Chart of accounts
- Journal engine
- Customers and vendors
- Invoices
- Bills
- Customer payments
- Vendor payments
- Financial reports
- Audit logs
- Role-based access control
- Bank CSV import
- Bank categorization
- Bank transaction posting
- Bank reconciliation
- Inngest background jobs
- Singapore advanced modules
- Deployment smoke testing

---

## 2.2 Out of Scope

The following are not fully covered in this version:

- Official IRAS GST filing validation
- Full payroll compliance testing
- CPF statutory submission
- Full corporate tax computation validation
- Real email delivery testing
- PDF rendering
- Bank feed integrations
- Load testing at enterprise scale
- Penetration testing
- Accessibility audit by a specialist
- Full disaster recovery drill

---

# 3. Test Objectives

The test effort should prove that:

1. Users can sign in and work inside company organizations.
2. Company data is isolated by organization.
3. Accounts can be seeded and maintained.
4. Journal entries must balance.
5. Invoices and bills create correct accounting entries.
6. Payments settle receivables/payables without duplicating income or expense.
7. Reports are generated from journal lines.
8. Audit logs capture important operations.
9. Admin-only operations are protected.
10. Bank CSV import, categorization, posting, and reconciliation work.
11. Background jobs can be triggered.
12. Production deployment is operational.

---

# 4. Test Strategy

Testing will be divided into:

```txt
Unit tests
Integration tests
Manual functional tests
Security/authorization tests
Accounting validation tests
Report validation tests
End-to-end smoke tests
Deployment tests
```

---

## 4.1 Unit Tests

Unit tests verify pure logic without database or browser dependencies.

Examples:

- Money formatting
- GST calculation
- Journal validation
- Report math
- Aging bucket calculation
- Currency conversion
- CPF estimate
- Corporate tax estimate
- Bank CSV parsing

Command:

```bash
pnpm test
```

---

## 4.2 Integration Tests

Integration tests should verify services working with a database.

Recommended future coverage:

- Invoice creation writes invoice, lines, journal entry, audit log
- Bill creation writes bill, lines, journal entry, audit log
- Payment recording updates invoice/bill status
- Bank posting creates journal entry
- Reversal creates reversing entry

Current tutorial relies on manual integration testing for many of these workflows.

---

## 4.3 Manual Functional Tests

Manual tests verify user workflows through the UI.

Examples:

- Create organization
- Seed accounts
- Create invoice
- Record payment
- Run reports
- Upload bank CSV
- Reconcile bank transaction

---

## 4.4 Security Tests

Security tests verify:

- Protected routes require authentication
- Tenant data is isolated
- Admin-only routes and actions reject non-admins
- Hidden form fields are not trusted
- Cross-tenant record IDs do not leak data

---

## 4.5 Accounting Tests

Accounting tests verify:

- Journal entries balance
- Source documents link to journal entries
- Payments do not duplicate revenue or expense
- Reversals cancel original entries
- Reports match posted ledger activity

---

# 5. Test Environments

## 5.1 Local Development

Used for:

```txt
Development
Unit tests
Manual UI testing
Inngest dev testing
Drizzle Studio inspection
```

Local URL:

```txt
http://localhost:3000
```

Commands:

```bash
pnpm dev
pnpm test
pnpm check
pnpm db:studio
```

---

## 5.2 Test Database

Recommended for integration testing.

Options:

- Separate Neon branch
- Separate Neon project
- Local Postgres database

Recommended variable:

```bash
DATABASE_URL_TEST="postgresql://..."
```

---

## 5.3 Preview Deployment

Used for:

```txt
Vercel preview validation
Pre-production smoke tests
Auth redirect tests
Background job endpoint tests
```

---

## 5.4 Production

Used for:

```txt
Final smoke test
Operational verification
Monitoring
```

Production testing should avoid destructive or unrealistic data unless using a test organization.

---

# 6. Test Data

## 6.1 Fictitious Organization

```txt
Merlion Creative Pte. Ltd.
```

---

## 6.2 Test Customer

```txt
Name: Orchard Retail Group Pte. Ltd.
Email: finance@orchardretail.example.com
Phone: +65 6123 4567
Billing address: 10 Orchard Road, Singapore 238800
```

---

## 6.3 Test Vendor

```txt
Name: CloudStack Hosting SG Pte. Ltd.
Email: billing@cloudstack.example.com
Phone: +65 6234 5678
Billing address: 80 Robinson Road, Singapore 068898
```

---

## 6.4 Test Invoice

```txt
Description: Brand strategy consulting services
Quantity: 1
Unit amount: 2000.00
GST basis points: 900
Subtotal: S$2,000.00
GST: S$180.00
Total: S$2,180.00
```

---

## 6.5 Test Bill

```txt
Description: Cloud hosting services
Quantity: 1
Unit amount: 300.00
GST basis points: 900
Subtotal: S$300.00
GST: S$27.00
Total: S$327.00
```

---

## 6.6 Test Bank CSV

```csv
date,description,amount
2026-02-15,Orchard Retail Group payment,2180.00
2026-02-20,CloudStack Hosting SG payment,-327.00
2026-02-25,Bank service charge,-15.00
```

---

# 7. Entry Criteria

Testing may begin when:

- App builds successfully
- `.env.local` is configured
- Database migrations are applied
- Clerk authentication is configured
- At least one organization can be created
- Test user can sign in
- `pnpm check` passes

---

# 8. Exit Criteria

Testing is complete when:

- All unit tests pass
- All critical manual workflows pass
- No known journal balance issues exist
- No known cross-tenant leakage exists
- Production smoke test passes
- Critical defects are resolved or accepted
- Documentation is updated

---

# 9. Test Execution Commands

## Run Unit Tests

```bash
pnpm test
```

---

## Run Tests in Watch Mode

```bash
pnpm test:watch
```

---

## Run Full Health Check

```bash
pnpm check
```

---

## Start App

```bash
pnpm dev
```

---

## Run Migrations

```bash
pnpm db:migrate
```

---

## Open Drizzle Studio

```bash
pnpm db:studio
```

---

## Run Inngest Dev Server

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

---

# 10. Unit Test Coverage

## 10.1 Money Helpers

File:

```txt
tests/money.test.ts
```

Test cases:

| ID | Test | Expected |
|---|---|---|
| MONEY-001 | Format `10900` cents | `S$109.00` |
| MONEY-002 | Convert `"109.00"` | `10900` |
| MONEY-003 | Reject decimal cents | Throws error |
| MONEY-004 | Convert negative value | Correct negative cents |

---

## 10.2 GST Helpers

File:

```txt
tests/gst.test.ts
```

Test cases:

| ID | Test | Expected |
|---|---|---|
| GST-001 | S$100 at 9% | GST S$9, total S$109 |
| GST-002 | Zero-rated | GST S$0 |
| GST-003 | Rounding | Correct nearest cent |
| GST-004 | Invalid subtotal | Throws error |
| GST-005 | Invalid quantity | Throws error |

---

## 10.3 Journal Validation

File:

```txt
tests/journal-validation.test.ts
```

Test cases:

| ID | Test | Expected |
|---|---|---|
| JOURNAL-001 | Valid owner contribution | Pass |
| JOURNAL-002 | Valid GST invoice | Pass |
| JOURNAL-003 | Unbalanced entry | Fail |
| JOURNAL-004 | One-line entry | Fail |
| JOURNAL-005 | Missing memo | Fail |
| JOURNAL-006 | Invalid date | Fail |
| JOURNAL-007 | Invalid UUID | Fail |
| JOURNAL-008 | Both debit and credit on line | Fail |
| JOURNAL-009 | Zero line | Fail |
| JOURNAL-010 | Negative amount | Fail |
| JOURNAL-011 | Decimal cents | Fail |

---

## 10.4 Reports

Files:

```txt
tests/report-helpers.test.ts
tests/profit-and-loss.test.ts
tests/balance-sheet.test.ts
tests/gst-f5-report.test.ts
tests/aging.test.ts
```

Test cases:

| ID | Test | Expected |
|---|---|---|
| REPORT-001 | Signed asset balance | Debit minus credit |
| REPORT-002 | Signed income balance | Credit minus debit |
| PNL-001 | Income exceeds expenses | Profit |
| PNL-002 | Expenses exceed income | Loss |
| BS-001 | Balanced sheet | Difference 0 |
| GSTF5-001 | Output greater than input | GST payable |
| GSTF5-002 | Input greater than output | GST refundable |
| AGE-001 | Current bucket | Current |
| AGE-002 | 1–30 bucket | Correct |
| AGE-003 | 90+ bucket | Correct |

---

## 10.5 Bank CSV

File:

```txt
tests/bank-csv.test.ts
```

Test cases:

| ID | Test | Expected |
|---|---|---|
| BANKCSV-001 | Valid CSV | Rows parsed |
| BANKCSV-002 | Quoted comma description | Parsed correctly |
| BANKCSV-003 | Missing headers | Fail |
| BANKCSV-004 | Invalid row values | Fail |

---

## 10.6 Advanced Modules

Files:

```txt
tests/currency.test.ts
tests/cpf.test.ts
tests/corporate-tax.test.ts
```

Test cases:

| ID | Test | Expected |
|---|---|---|
| FX-001 | USD to SGD conversion | Correct base cents |
| CPF-001 | CPF estimate | Correct simplified result |
| TAX-001 | 17% tax estimate | Correct tax |
| TAX-002 | Negative profit | Tax zero |

---

# 11. Manual Functional Test Cases

---

## AUTH-001 — Sign Up

Steps:

1. Open app.
2. Click Sign up.
3. Complete Clerk sign-up.

Expected:

```txt
User account created.
User redirected to dashboard.
```

---

## AUTH-002 — Sign In

Steps:

1. Open `/sign-in`.
2. Enter valid credentials.

Expected:

```txt
User signed in.
Dashboard loads.
```

---

## AUTH-003 — Protected Route Redirect

Steps:

1. Sign out.
2. Open `/dashboard`.

Expected:

```txt
User redirected to sign-in.
```

---

## ORG-001 — Create Organization

Steps:

1. Sign in.
2. Open `/onboarding/organization`.
3. Create `Merlion Creative Pte. Ltd.`.

Expected:

```txt
Organization created.
Dashboard shows active organization.
Local database organization row exists.
```

---

## ACC-001 — Seed Chart of Accounts

Steps:

1. Open `/accounts`.
2. Click Seed default accounts.

Expected:

```txt
Default accounts created.
Accounts grouped by type.
No duplicate accounts after re-running seed.
```

---

## ACC-002 — Create Custom Account

Steps:

1. Open `/accounts`.
2. Add:

```txt
Code: 6310
Name: Design Software Subscriptions
Type: Expenses
```

Expected:

```txt
Account appears under Expenses.
is_system = false.
```

---

## CUST-001 — Create Customer

Steps:

1. Open `/customers`.
2. Create Orchard Retail Group.

Expected:

```txt
Customer appears in customer list.
Audit log created.
```

---

## VEND-001 — Create Vendor

Steps:

1. Open `/vendors`.
2. Create CloudStack Hosting SG.

Expected:

```txt
Vendor appears in vendor list.
Audit log created.
```

---

## INV-001 — Create GST Invoice

Steps:

1. Open `/invoices`.
2. Create invoice:

```txt
Customer: Orchard Retail Group
Unit amount: 2000.00
GST: 900 basis points
```

Expected:

```txt
Invoice created.
Subtotal = 200000 cents.
GST = 18000 cents.
Total = 218000 cents.
Journal entry posted.
Audit log created.
Inngest invoice.created event sent.
```

Expected journal:

```txt
Debit AR 218000
Credit Sales Revenue 200000
Credit GST Output Tax 18000
```

---

## INV-002 — View Invoice Detail

Steps:

1. Open `/invoices`.
2. Click invoice number.

Expected:

```txt
Invoice detail loads.
Customer details shown.
Invoice lines shown.
Linked journal entry shown.
Journal entry balanced.
```

---

## PAY-001 — Record Customer Payment

Steps:

1. Open unpaid invoice detail.
2. Record payment.

Expected:

```txt
Customer payment created.
Invoice status = paid.
Journal entry posted.
```

Expected journal:

```txt
Debit Bank
Credit Accounts Receivable
```

---

## BILL-001 — Create GST Bill

Steps:

1. Open `/bills`.
2. Create bill:

```txt
Vendor: CloudStack Hosting SG
Unit amount: 300.00
GST: 900 basis points
```

Expected:

```txt
Bill created.
Subtotal = 30000 cents.
GST = 2700 cents.
Total = 32700 cents.
Journal entry posted.
```

Expected journal:

```txt
Debit Purchases 30000
Debit GST Input Tax 2700
Credit Accounts Payable 32700
```

---

## PAY-002 — Record Vendor Payment

Steps:

1. Open unpaid bill detail.
2. Record payment.

Expected:

```txt
Vendor payment created.
Bill status = paid.
Journal entry posted.
```

Expected journal:

```txt
Debit Accounts Payable
Credit Bank
```

---

## BANK-001 — Upload Bank CSV

Steps:

1. Open `/bank`.
2. Upload test CSV.

Expected:

```txt
Bank import created.
Bank transactions created.
Rows visible on bank page.
```

---

## BANK-002 — Categorize Bank Transaction

Steps:

1. Select category account for imported row.
2. Save category.

Expected:

```txt
Transaction status = categorized.
category_account_id populated.
```

---

## BANK-003 — Post Bank Transaction

Steps:

1. Click Post to ledger for categorized row.

Expected:

```txt
Transaction status = posted.
journal_entry_id populated.
Balanced journal entry created.
```

---

## BANK-004 — Reconcile Bank Transaction

Steps:

1. Click Mark reconciled for posted row.

Expected:

```txt
Transaction status = reconciled.
reconciled_at populated.
```

---

## REV-001 — Reverse Journal Entry as Admin

Steps:

1. Open `/settings/database/journal`.
2. Enter reversal reason.
3. Reverse eligible entry.

Expected:

```txt
Original entry marked reversed.
Reversal entry created.
Debits and credits swapped.
Audit log created.
```

---

## RBAC-001 — Non-Admin Audit Access

Steps:

1. Sign in as non-admin organization member.
2. Open `/settings/audit-log`.

Expected:

```txt
Access restricted.
Audit log not shown.
```

---

# 12. Report Test Cases

## RPT-001 — Profit & Loss

Steps:

1. Create invoice.
2. Create bill.
3. Open `/reports/profit-and-loss`.

Expected:

```txt
Sales Revenue appears as income.
Purchases appears as expense.
Net profit calculated correctly.
GST accounts excluded.
```

---

## RPT-002 — Balance Sheet

Steps:

1. Post invoice, bill, payments.
2. Open `/reports/balance-sheet`.

Expected:

```txt
Assets shown.
Liabilities shown.
Equity shown.
Current Year Earnings included.
Equation difference = 0.
```

---

## RPT-003 — GST F5-Style Report

Steps:

1. Create GST invoice and GST bill.
2. Open `/reports/gst-f5`.

Expected:

```txt
GST Output Tax shown.
GST Input Tax shown.
Net GST calculated.
```

---

## RPT-004 — AR Aging

Steps:

1. Create unpaid invoice.
2. Open `/reports/ar-aging`.

Expected:

```txt
Unpaid invoice appears.
Paid invoice does not appear.
Correct aging bucket shown.
```

---

## RPT-005 — AP Aging

Steps:

1. Create unpaid bill.
2. Open `/reports/ap-aging`.

Expected:

```txt
Unpaid bill appears.
Paid bill does not appear.
Correct aging bucket shown.
```

---

# 13. Tenant Isolation Test Cases

## TENANT-001 — Invoice Isolation

Steps:

1. Organization A creates invoice.
2. Copy invoice URL.
3. Switch to Organization B.
4. Open copied URL.

Expected:

```txt
Invoice not found.
```

---

## TENANT-002 — Customer Isolation

Steps:

1. Organization A creates customer.
2. Switch to Organization B.
3. Open `/customers`.

Expected:

```txt
Organization A customer not visible.
```

---

## TENANT-003 — Report Isolation

Steps:

1. Organization A posts invoice.
2. Organization B has no transactions.
3. Switch to Organization B.
4. Open P&L.

Expected:

```txt
Organization A revenue not shown.
```

---

## TENANT-004 — Account Isolation

Steps:

1. Organization A creates custom account `6050`.
2. Switch to Organization B.
3. Open `/accounts`.

Expected:

```txt
Custom account not visible unless created in Organization B.
```

---

# 14. Database Integrity SQL Tests

## JOURNAL-SQL-001 — All Journal Entries Balance

Run:

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

## TENANT-SQL-001 — Invoice Customer Organization Match

Run:

```sql
select
  i.id,
  i.organization_id,
  c.organization_id
from invoices i
join customers c
  on c.id = i.customer_id
where i.organization_id <> c.organization_id;
```

Expected:

```txt
0 rows
```

---

## TENANT-SQL-002 — Bill Vendor Organization Match

Run:

```sql
select
  b.id,
  b.organization_id,
  v.organization_id
from bills b
join vendors v
  on v.id = b.vendor_id
where b.organization_id <> v.organization_id;
```

Expected:

```txt
0 rows
```

---

## TENANT-SQL-003 — Journal Line Account Organization Match

Run:

```sql
select
  jl.id,
  jl.organization_id,
  a.organization_id
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

# 15. Background Job Test Cases

## BG-001 — Health Check Event

Steps:

1. Run:

```bash
pnpm dev
```

2. Run:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

3. Open `/settings/background-jobs`.
4. Click Send test event.

Expected:

```txt
Inngest receives app/health.check.
Function runs successfully.
```

---

## BG-002 — Invoice Created Event

Steps:

1. Run Inngest dev server.
2. Create invoice.

Expected:

```txt
invoice.created event appears.
invoice-created-confirmation function runs.
```

---

## BG-003 — Overdue Reminder Job

Steps:

1. Create overdue unpaid invoice.
2. Run Inngest dev server.
3. Trigger daily overdue reminder function manually.

Expected:

```txt
Reminder payload includes overdue invoice.
```

---

# 16. Deployment Smoke Test

After deployment:

1. Open production URL.
2. Sign up.
3. Create organization.
4. Open `/settings/database`.
5. Seed accounts.
6. Create customer.
7. Create invoice.
8. Record payment.
9. Create vendor.
10. Create bill.
11. Record vendor payment.
12. Open reports.
13. Send Inngest health check.

Expected:

```txt
All critical workflows complete successfully.
```

---

# 17. Defect Severity

## Critical

Examples:

```txt
Unbalanced journal entry inserted
Cross-tenant data leakage
Authentication bypass
Production app unavailable
Data loss
```

Must fix before release.

---

## High

Examples:

```txt
Invoice posting fails
Payment posting fails
Reports materially incorrect
Admin restrictions fail
Bank posting duplicates entries
```

Should fix before release.

---

## Medium

Examples:

```txt
Incorrect UI status
Non-critical diagnostic page broken
Minor report formatting issue
```

Fix soon.

---

## Low

Examples:

```txt
Copy typo
Minor styling issue
Non-blocking layout problem
```

Fix when practical.

---

# 18. Test Completion Report Template

Use this template after a test cycle:

```md
# Test Completion Report

## Build / Version

## Environment

## Test Date

## Tester

## Summary

## Tests Executed

## Passed

## Failed

## Blocked

## Critical Defects

## High Defects

## Notes

## Release Recommendation

- [ ] Approve
- [ ] Approve with known issues
- [ ] Do not release
```

---

# 19. Final Test Plan Checklist

Testing is acceptable when:

- [ ] `pnpm check` passes
- [ ] Journal validation tests pass
- [ ] GST tests pass
- [ ] Report tests pass
- [ ] CSV parser tests pass
- [ ] Authentication works
- [ ] Organization switching works
- [ ] Tenant isolation tests pass
- [ ] Invoice workflow passes
- [ ] Bill workflow passes
- [ ] Payment workflows pass
- [ ] Bank workflow passes
- [ ] Reports match expected values
- [ ] Audit logs work
- [ ] Admin restrictions work
- [ ] Inngest health check works
- [ ] Production smoke test passes

---

# 20. Final Testing Principle

For GreyMatter Ledger, the most important testing principle is:

```txt
Test the accounting truth, not just the screen.
```

Screens can look correct while accounting is wrong.

Always verify:

```txt
Journal entries balance.
Reports come from journal lines.
Tenant data is isolated.
Payments settle, not duplicate.
Reversals preserve history.
```
