# Security Threat Model

**Product:** GreyMatter Ledger  
**Document type:** Security Threat Model  
**Version:** 1.0  
**Status:** Draft  
**Audience:** Engineering, security reviewers, product owners, auditors  
**Scope:** Application security, tenant isolation, financial data integrity, authentication, authorization, database access, background jobs, file uploads  

---

# 1. Purpose

This document identifies security risks in **GreyMatter Ledger** and defines mitigations.

GreyMatter Ledger is a multi-tenant accounting application.

It handles sensitive data such as:

```txt
Company records
Customer information
Vendor information
Invoices
Bills
Payments
Journal entries
Bank transactions
Audit logs
Reports
```

The most important security goals are:

```txt
Protect tenant data isolation.
Protect financial data integrity.
Prevent unauthorized access.
Preserve auditability.
Avoid accidental or malicious data corruption.
```

---

# 2. System Overview

GreyMatter Ledger uses:

```txt
Next.js
TypeScript
Tailwind CSS
Clerk
Neon Postgres
Drizzle ORM
Inngest
Vercel
```

High-level architecture:

```txt
Browser
  |
  v
Vercel-hosted Next.js app
  |
  |-- Clerk authentication
  |-- Neon Postgres
  |-- Inngest background jobs
```

Core server-side layers:

```txt
Next.js Server Components
Server Actions
Service Layer
Journal Engine
Drizzle ORM
Postgres
```

---

# 3. Security Objectives

GreyMatter Ledger must protect:

## Confidentiality

Only authorized users should see organization data.

Examples:

```txt
Company A must not see Company B invoices.
Non-admin users must not see audit logs.
```

---

## Integrity

Financial records must remain correct.

Examples:

```txt
Journal entries must balance.
Payments must not be duplicated.
Reconciled bank transactions should be locked.
```

---

## Availability

The app should remain operational.

Examples:

```txt
Database connectivity should be monitored.
Background jobs should be observable.
Deployments should be reversible.
```

---

## Auditability

Important actions must be traceable.

Examples:

```txt
Invoice created
Payment recorded
Journal entry reversed
```

---

# 4. Assets

The main assets requiring protection are:

```txt
User identities
Organization membership
Organization financial data
Customer records
Vendor records
Invoices
Bills
Payments
Journal entries
Journal lines
Bank transactions
Audit logs
Reports
Database credentials
Clerk secret keys
Inngest signing keys
```

---

# 5. Trust Boundaries

## Browser Boundary

The browser is untrusted.

Do not trust:

```txt
Form data
Hidden fields
Organization IDs
Account IDs
Amounts
Roles
Statuses
```

Server-side validation is mandatory.

---

## Authentication Boundary

Clerk verifies user identity.

The app trusts Clerk session data from server-side Clerk helpers.

---

## Tenant Boundary

The tenant boundary is:

```txt
organization_id
```

Every tenant-scoped query must filter by organization ID.

---

## Service Layer Boundary

Business rules are enforced in services.

Server actions should delegate to services.

---

## Database Boundary

Postgres stores durable state and enforces constraints.

---

## Background Job Boundary

Inngest jobs may run without active user context.

Scheduled jobs need explicit tenant scope.

---

# 6. Threat Categories

This threat model uses practical categories:

```txt
Authentication threats
Authorization threats
Tenant isolation threats
Financial integrity threats
Input validation threats
File upload threats
Database threats
Background job threats
Audit threats
Deployment/secrets threats
```

---

# 7. Authentication Threats

## Threat AUTH-001 — Unauthenticated Access to Protected Routes

Risk:

```txt
Signed-out users access internal accounting pages.
```

Impact:

```txt
Confidential financial data exposure.
```

Mitigation:

```txt
Next.js 16 proxy.ts protects internal routes.
Clerk auth.protect() used.
Protected route matcher includes app routes.
```

Routes protected:

```txt
/dashboard
/accounts
/customers
/vendors
/invoices
/bills
/payments
/reports
/bank
/settings
/onboarding
```

Verification:

```txt
Sign out and open /dashboard.
Expected redirect to sign-in.
```

---

## Threat AUTH-002 — Misconfigured Clerk Production URLs

Risk:

```txt
Auth redirects fail or malicious domains are allowed.
```

Impact:

```txt
Login failures or session risk.
```

Mitigation:

```txt
Configure Clerk allowed origins and redirect URLs.
Use production Clerk keys in production.
```

Verification:

```txt
Production sign-in and sign-up smoke test.
```

---

# 8. Authorization Threats

## Threat AUTHZ-001 — Non-Admin Views Audit Logs

Risk:

```txt
Regular member accesses audit history.
```

Impact:

```txt
Sensitive operational data exposure.
```

Mitigation:

```txt
/settings/audit-log calls requireOrganizationAdmin().
Audit log route has error boundary.
```

Verification:

```txt
Test with org:member role.
Expected access restricted.
```

---

## Threat AUTHZ-002 — Non-Admin Reverses Journal Entry

Risk:

```txt
Unauthorized user reverses financial entries.
```

Impact:

```txt
Financial reports altered.
```

Mitigation:

```txt
reverseJournalEntryForCurrentOrganization() calls requireOrganizationAdmin().
Server action catches authorization errors.
```

Verification:

```txt
Test reversal as non-admin.
Expected failure.
```

---

## Threat AUTHZ-003 — UI-Only Authorization

Risk:

```txt
Button hidden but server action still callable.
```

Impact:

```txt
Unauthorized sensitive operation.
```

Mitigation:

```txt
Permissions enforced in server-side services.
Do not rely only on UI hiding.
```

Verification:

```txt
Inspect services for requireOrganizationAdmin().
```

---

# 9. Tenant Isolation Threats

## Threat TENANT-001 — Query Without Organization Filter

Risk:

```txt
A query returns data from all organizations.
```

Impact:

```txt
Cross-tenant data exposure.
```

Mitigation:

```txt
Use requireCurrentDatabaseOrganization().
Filter by organization_id.
```

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

Verification:

```txt
Cross-organization manual tests.
Code review checklist.
```

---

## Threat TENANT-002 — Loading Record by ID Only

Risk:

```txt
User opens another organization’s invoice URL.
```

Impact:

```txt
Data leakage.
```

Mitigation:

```txt
Detail queries filter by id and organization_id.
Not-found response for missing/cross-tenant records.
```

Good:

```ts
and(
  eq(invoices.id, invoiceId),
  eq(invoices.organizationId, organization.id),
)
```

Verification:

```txt
Copy invoice URL from Org A.
Switch to Org B.
Expected not found.
```

---

## Threat TENANT-003 — Related Record From Different Organization

Risk:

```txt
Invoice in Organization A references customer from Organization B.
```

Impact:

```txt
Data contamination.
```

Mitigation:

```txt
Services verify referenced records belong to active organization.
```

Verification SQL:

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

## Threat TENANT-004 — Cross-Tenant Journal Account Posting

Risk:

```txt
Company A posts journal line to Company B account.
```

Impact:

```txt
Severe ledger contamination.
```

Mitigation:

```txt
Journal engine loads accounts by active organization.
Rejects account IDs not found for organization.
```

Verification SQL:

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

# 10. Financial Integrity Threats

## Threat FIN-001 — Unbalanced Journal Entry Inserted

Risk:

```txt
Debits do not equal credits.
```

Impact:

```txt
Reports cannot be trusted.
```

Mitigation:

```txt
validatePostJournalEntryInput()
postJournalEntry()
journal line constraints
automated tests
manual journal test harness
```

Verification SQL:

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

## Threat FIN-002 — Duplicate Payment Recording

Risk:

```txt
Invoice or bill paid multiple times.
```

Impact:

```txt
Bank and receivable/payable balances wrong.
```

Mitigation:

```txt
Customer payment rejects paid/void invoices.
Vendor payment rejects paid/void bills.
```

Verification:

```txt
Try paying same invoice twice.
Expected error.
```

---

## Threat FIN-003 — Revenue Duplicated on Payment

Risk:

```txt
Customer payment credits revenue again.
```

Impact:

```txt
Income overstated.
```

Mitigation:

```txt
Payment service posts Debit Bank / Credit AR.
Tests/manual review.
```

Expected customer payment entry:

```txt
Debit Bank
Credit Accounts Receivable
```

---

## Threat FIN-004 — Expense Duplicated on Vendor Payment

Risk:

```txt
Vendor payment debits expense again.
```

Impact:

```txt
Expenses overstated.
```

Mitigation:

```txt
Vendor payment posts Debit AP / Credit Bank.
```

Expected vendor payment entry:

```txt
Debit Accounts Payable
Credit Bank
```

---

## Threat FIN-005 — Reconciled Bank Transaction Modified

Risk:

```txt
Confirmed bank transaction changed after reconciliation.
```

Impact:

```txt
Reconciliation integrity lost.
```

Mitigation:

```txt
Categorization blocks posted/reconciled transactions.
Reconciliation marks status.
Future improvement: stronger update guards.
```

---

# 11. Input Validation Threats

## Threat INPUT-001 — Invalid Money Amount

Risk:

```txt
User submits decimal cents, malformed amount, or float.
```

Impact:

```txt
Incorrect financial records.
```

Mitigation:

```txt
dollarsToCents()
integer cents validation
database constraints
tests
```

---

## Threat INPUT-002 — Invalid Date

Risk:

```txt
Impossible dates accepted.
```

Impact:

```txt
Reports and due dates wrong.
```

Mitigation:

```txt
YYYY-MM-DD validators.
Reject normalized impossible dates like 2026-02-31.
```

---

## Threat INPUT-003 — Invalid Account Type or Status

Risk:

```txt
Invalid enum-like values.
```

Impact:

```txt
Broken workflows.
```

Mitigation:

```txt
Postgres enums.
Server-side validation.
TypeScript unions.
```

---

# 12. File Upload Threats

## Threat FILE-001 — Malformed Bank CSV

Risk:

```txt
Invalid CSV corrupts import process.
```

Impact:

```txt
Bad bank transaction data.
```

Mitigation:

```txt
parseBankCsv validates headers and rows.
Required headers: date, description, amount.
```

---

## Threat FILE-002 — Large File Upload

Risk:

```txt
Very large CSV causes memory/performance issues.
```

Impact:

```txt
Denial of service.
```

Current status:

```txt
Tutorial implementation does not enforce file size limit.
```

Recommended mitigation:

```txt
Add file size limit.
Add row count limit.
Stream large files.
```

---

## Threat FILE-003 — Trusting File Name

Risk:

```txt
Malicious file name stored/displayed unsafely.
```

Mitigation:

```txt
Treat fileName as untrusted text.
Escape in UI by default through React.
Avoid using it as filesystem path.
```

---

# 13. Database Threats

## Threat DB-001 — Secret Leakage

Risk:

```txt
DATABASE_URL exposed.
```

Impact:

```txt
Database compromise.
```

Mitigation:

```txt
.env.local ignored.
Use Vercel env vars.
Rotate if leaked.
```

---

## Threat DB-002 — Destructive Migration

Risk:

```txt
Migration drops or corrupts financial data.
```

Impact:

```txt
Data loss.
```

Mitigation:

```txt
Review SQL migrations.
Back up/branch Neon before risky migrations.
Avoid destructive changes.
```

---

## Threat DB-003 — Missing Constraints

Risk:

```txt
Invalid financial data inserted.
```

Mitigation:

```txt
Use check constraints.
Use foreign keys.
Use unique indexes.
```

Examples:

```txt
invoice total = subtotal + GST
journal line exactly one side
payment amount > 0
```

---

# 14. Background Job Threats

## Threat BG-001 — Scheduled Job Without Tenant Scope

Risk:

```txt
Background job processes data across organizations incorrectly.
```

Impact:

```txt
Cross-tenant actions or leaks.
```

Mitigation:

```txt
Explicit organization iteration.
System actor context.
Avoid relying on active user session in cron jobs.
```

---

## Threat BG-002 — Duplicate Background Processing

Risk:

```txt
Retry creates duplicate invoices or reminders.
```

Impact:

```txt
Duplicate documents or messages.
```

Mitigation:

```txt
Idempotency keys.
Unique generation logs.
Check existing records before creating.
```

Current recurring scheduler is intentionally a stub for production-path safety.

---

## Threat BG-003 — Sensitive Event Payloads

Risk:

```txt
Secrets or excessive personal data sent to Inngest.
```

Mitigation:

```txt
Send IDs and minimal payloads.
Load fresh data server-side if needed.
```

---

# 15. Audit Threats

## Threat AUDIT-001 — Important Actions Not Logged

Risk:

```txt
Cannot trace who performed financial action.
```

Mitigation:

```txt
writeAuditLog() used for key operations.
```

Current audited actions include:

```txt
customer.created
vendor.created
invoice.created
bill.created
customer_payment.recorded
vendor_payment.recorded
journal_entry.reversed
```

---

## Threat AUDIT-002 — Audit Logs Expose Sensitive Data

Risk:

```txt
Audit metadata contains secrets or excessive data.
```

Mitigation:

```txt
Keep metadata minimal.
Do not log secrets.
Restrict audit log access to admins.
```

---

# 16. Deployment and Secret Threats

## Threat DEPLOY-001 — Missing Production Env Vars

Risk:

```txt
Production app fails at runtime/build.
```

Mitigation:

```txt
Vercel env checklist.
Deployment smoke test.
```

---

## Threat DEPLOY-002 — Clerk Production Misconfiguration

Risk:

```txt
Auth broken or incorrect allowed origins.
```

Mitigation:

```txt
Configure Clerk production URLs.
Use production keys.
Test sign-in.
```

---

## Threat DEPLOY-003 — Inngest Endpoint Misconfiguration

Risk:

```txt
Background jobs do not run.
```

Mitigation:

```txt
Configure /api/inngest endpoint in Inngest.
Set signing keys.
Test health event.
```

---

# 17. Security Controls Summary

| Area | Control |
|---|---|
| Auth | Clerk |
| Route protection | Next.js 16 `proxy.ts` |
| Tenant isolation | `organization_id` filters |
| RBAC | Clerk org roles |
| Admin enforcement | `requireOrganizationAdmin()` |
| Financial integrity | Journal engine |
| Money precision | Integer cents |
| Database integrity | Constraints and foreign keys |
| Auditability | `audit_logs` |
| Background jobs | Inngest |
| Secrets | Environment variables |
| Deployment | Vercel env vars and smoke tests |

---

# 18. Recommended Security Tests

## Authentication

```txt
Signed-out user cannot access /dashboard.
Signed-out user cannot access /reports.
Signed-out user cannot access /settings.
```

---

## Authorization

```txt
Non-admin cannot view audit logs.
Non-admin cannot reverse journal entries.
```

---

## Tenant Isolation

```txt
Organization A invoice URL returns not found in Organization B.
Organization A reports do not show Organization B data.
Organization A accounts cannot be used in Organization B journal entry.
```

---

## Financial Integrity

```txt
Unbalanced journal entry rejected.
Duplicate payment rejected.
Reversal creates balanced swapped entry.
```

---

## Bank

```txt
Posted transaction cannot be recategorized.
Only posted transaction can be reconciled.
Reconciled transaction status locks workflow.
```

---

# 19. Risk Ratings

## Critical Risks

```txt
Cross-tenant data leakage
Unbalanced journal entries
Database secret leakage
Unauthorized journal reversals
Data loss from destructive migration
```

---

## High Risks

```txt
Duplicate payments
Incorrect GST report
Bank transaction duplicate posting
Audit log exposure
Background job duplicate generation
```

---

## Medium Risks

```txt
Malformed CSV import
Invalid date handling
Missing audit coverage
Production env misconfiguration
```

---

# 20. Future Security Improvements

Recommended:

```txt
Add rate limiting.
Add security headers.
Add integration tests for tenant isolation.
Add Playwright E2E authorization tests.
Add system actor model for background jobs.
Add idempotency keys for background workflows.
Add audit logging for bank categorization/posting/reconciliation.
Add file size limits for CSV upload.
Add period locks.
Add append-only ledger protections.
Add monitoring and alerting.
Add dependency vulnerability scanning.
```

---

# 21. Final Security Principles

The most important principles are:

```txt
1. Never trust the browser.
2. Always enforce organization scope.
3. Always enforce sensitive permissions server-side.
4. Never allow unbalanced journal entries.
5. Never commit secrets.
6. Preserve audit history.
7. Treat production data as sensitive financial data.
```

GreyMatter Ledger is safest when these principles are followed consistently.
