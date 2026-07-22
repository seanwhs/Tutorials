# Architecture Addendum  
# GreyMatter Ledger

**Document type:** Architecture Addendum  
**Product:** GreyMatter Ledger  
**Version:** 1.0  
**Status:** Draft  
**Audience:** Engineering, architecture reviewers, technical leads, maintainers, auditors  
**Purpose:** Expanded technical architecture reference  

---

# 1. Executive Summary

GreyMatter Ledger is a full-stack, multi-tenant, Singapore-ready accounting SaaS application.

It is built around one central accounting principle:

```txt
Every financial event must be represented by balanced double-entry journal entries.
```

And one central SaaS security principle:

```txt
Every company’s data must remain isolated by organization.
```

The application uses:

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

At a high level, the architecture looks like this:

```txt
Browser
  |
  v
Next.js App Router
  |
  v
Server Actions / Route Handlers
  |
  v
Service Layer
  |
  v
Accounting Domain Layer
  |
  v
Drizzle ORM
  |
  v
Neon Postgres
```

External services:

```txt
Clerk  -> Authentication, users, organizations, roles
Inngest -> Background jobs, events, schedules
Vercel -> Hosting and deployment
Neon   -> PostgreSQL database
```

The architecture is intentionally layered so that:

- UI remains readable.
- Business rules live in services.
- Accounting rules are centralized.
- Reports derive from the ledger.
- Tenant isolation is enforced server-side.
- Sensitive actions are auditable.
- The system can be extended safely.

---

# 2. Architectural Principles

## 2.1 Ledger-First Design

The ledger is the accounting source of truth.

The key tables are:

```txt
journal_entries
journal_lines
```

Invoices, bills, payments, and bank transactions are source documents.

They explain why accounting activity happened.

But reports should be generated from journal lines.

```txt
Source documents explain.
Journal entries account.
Reports summarize.
```

---

## 2.2 Double-Entry Integrity

The system must never allow unbalanced journal entries.

The invariant is:

```txt
totalDebitCents === totalCreditCents
```

This rule is enforced by:

```txt
services/journal/validate-post-journal-entry.ts
services/journal/post-journal-entry.ts
```

Invalid examples must be rejected:

```txt
Debit  Bank           S$100
Credit Sales Revenue  S$90
```

Valid examples may be posted:

```txt
Debit  Bank           S$100
Credit Sales Revenue  S$100
```

---

## 2.3 Multi-Tenant Isolation

Every company workspace is isolated by:

```txt
organization_id
```

Most business tables include this field.

Tenant-scoped tables include:

```txt
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
bank_imports
bank_transactions
audit_logs
recurring_invoices
```

No normal business query should read or mutate these tables without organization scope.

---

## 2.4 Server-Side Trust Boundary

The browser is not trusted.

Do not trust:

```txt
organization IDs
account IDs
amounts
roles
status changes
journal line values
```

from the client without server validation.

Server-side services must enforce:

- Active organization
- Record ownership
- Account ownership
- Account active state
- Role permissions
- Balanced journal entries

---

## 2.5 Auditability

Financial systems must preserve history.

GreyMatter Ledger uses:

```txt
journal reversals
audit_logs
linked source documents
posted journal entries
```

Posted accounting history should not be casually edited or deleted.

Corrections should use:

```txt
reversals
```

---

## 2.6 Integer Money

All money is stored as integer cents.

Examples:

```txt
S$100.00 = 10000
S$9.00   = 900
S$109.00 = 10900
```

This avoids floating-point rounding errors.

---

## 2.7 Extensible Domain Modules

The architecture is designed to support future modules:

```txt
Credit notes
Partial payments
Payroll
Inventory
Bank feeds
Foreign exchange revaluation
Approval workflows
Period close
General ledger exports
```

These modules should plug into the existing service and journal architecture rather than bypassing it.

---

# 3. System Context

## 3.1 External Actors

Primary human users:

```txt
Business owner
Accountant
Bookkeeper
Finance operator
Developer/admin
```

External systems:

```txt
Clerk
Neon Postgres
Inngest
Vercel
Bank CSV files
```

---

## 3.2 Context Diagram

```txt
             +----------------+
             |     Browser    |
             +-------+--------+
                     |
                     v
          +----------+-----------+
          |   Next.js on Vercel  |
          +----------+-----------+
                     |
      +--------------+--------------+
      |              |              |
      v              v              v
   Clerk          Neon DB        Inngest
(Auth/Org)      (Postgres)      (Jobs/Events)
```

---

# 4. Application Layer Architecture

The project is organized into major directories:

```txt
app/
components/
db/
lib/
services/
inngest/
tests/
docs/
```

---

## 4.1 `app/`

Contains Next.js App Router routes.

Examples:

```txt
app/page.tsx
app/dashboard/page.tsx
app/accounts/page.tsx
app/invoices/page.tsx
app/invoices/[invoiceId]/page.tsx
app/bills/page.tsx
app/reports/profit-and-loss/page.tsx
app/settings/audit-log/page.tsx
app/api/inngest/route.ts
```

Responsibilities:

- Route definitions
- Server Components
- Page-level composition
- Server Actions colocated with routes
- API route handlers

---

## 4.2 `components/`

Contains reusable UI components.

Examples:

```txt
app-layout.tsx
app-header.tsx
app-sidebar.tsx
invoice-create-form.tsx
bill-create-form.tsx
account-group-table.tsx
report-date-range-form.tsx
```

Responsibilities:

- Reusable UI
- Forms
- Tables
- Banners
- Layout elements

Components should avoid complex database logic.

---

## 4.3 `db/`

Contains database schema and client setup.

```txt
db/schema.ts
db/index.ts
```

Responsibilities:

- Drizzle table definitions
- Database enums
- Type exports
- Database client

---

## 4.4 `lib/`

Contains shared utilities and pure domain helpers.

Examples:

```txt
lib/money.ts
lib/accounting/gst.ts
lib/accounting/normal-balance.ts
lib/reports/balance-sign.ts
lib/reports/date-range.ts
lib/currency.ts
lib/singapore/cpf.ts
```

Responsibilities:

- Pure calculations
- Formatting helpers
- Validation helpers
- Shared types
- Domain math

These should be easy to test.

---

## 4.5 `services/`

Contains business logic and database workflows.

Examples:

```txt
services/invoices/invoice-services.ts
services/bills/bill-services.ts
services/journal/post-journal-entry.ts
services/payments/customer-payment-services.ts
services/reports/profit-and-loss-service.ts
services/bank/post-bank-transaction.ts
```

Responsibilities:

- Business rules
- Tenant-safe database access
- Multi-step workflows
- Journal posting
- Audit logging
- Background event sending

This is the most important application layer.

---

## 4.6 `inngest/`

Contains background job definitions.

```txt
inngest/client.ts
inngest/events.ts
inngest/functions.ts
```

Responsibilities:

- Inngest client setup
- Event names and payload types
- Background functions
- Scheduled jobs

---

## 4.7 `tests/`

Contains automated tests.

Examples:

```txt
tests/journal-validation.test.ts
tests/gst.test.ts
tests/profit-and-loss.test.ts
tests/balance-sheet.test.ts
tests/bank-csv.test.ts
```

Responsibilities:

- Unit tests
- Pure domain logic tests
- Report math tests
- Parser tests

---

# 5. Layered Request Flow

## 5.1 Page Load Flow

Example:

```txt
User opens /invoices
```

Flow:

```txt
Browser
  |
  v
Next.js page: app/invoices/page.tsx
  |
  v
Server-side data loading
  |
  v
services/invoices/get-invoices.ts
services/customers/customer-services.ts
  |
  v
getOrCreateCurrentOrganization()
  |
  v
Drizzle queries filtered by organization_id
  |
  v
Render invoice page
```

---

## 5.2 Form Submission Flow

Example:

```txt
User creates invoice
```

Flow:

```txt
InvoiceCreateForm
  |
  v
createInvoiceAction(formData)
  |
  v
createInvoiceForCurrentOrganization(input)
  |
  v
Validate input
Verify customer ownership
Calculate GST
Insert invoice
Insert invoice lines
Post journal entry
Write audit log
Send Inngest event
  |
  v
Redirect with status
```

---

# 6. Identity Architecture

## 6.1 Clerk

Clerk handles:

```txt
User sign-up
User sign-in
Sessions
User profile
Organizations
Organization roles
```

Important files:

```txt
app/layout.tsx
proxy.ts
lib/auth.ts
lib/authorization.ts
components/auth-controls.tsx
components/organization-controls.tsx
```

---

## 6.2 Auth Provider

The app is wrapped with:

```tsx
<ClerkProvider>
  ...
</ClerkProvider>
```

in:

```txt
app/layout.tsx
```

---

## 6.3 Route Protection

Next.js 16 uses:

```txt
proxy.ts
```

Protected route groups include:

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

The proxy uses Clerk’s route protection.

---

# 7. Organization Architecture

## 7.1 Clerk Organization

Clerk stores identity-side organization data.

Example Clerk organization ID:

```txt
org_abc123
```

---

## 7.2 Local Database Organization

The app stores local organization rows in:

```txt
organizations
```

Important columns:

```txt
id
clerk_organization_id
name
slug
```

---

## 7.3 Organization Sync

Service:

```txt
services/organizations/get-or-create-organization.ts
```

Key function:

```ts
getOrCreateCurrentOrganization()
```

Flow:

```txt
Read Clerk orgId
Find local organization by clerk_organization_id
If missing, fetch Clerk org details
Insert local organization
Return local organization
```

---

## 7.4 Why Local Organization Rows Exist

Using local organization rows allows:

```txt
Foreign keys
Application-specific organization settings
Tenant-scoped business records
Decoupling from Clerk internals
```

Business tables reference:

```txt
organizations.id
```

---

# 8. Authorization Architecture

## 8.1 Role Helpers

File:

```txt
lib/authorization.ts
```

Key helpers:

```ts
getCurrentOrganizationRole()
isCurrentUserOrganizationAdmin()
requireOrganizationAdmin()
```

---

## 8.2 Admin-Only Actions

Admin-only features include:

```txt
Viewing audit logs
Reversing journal entries
```

Server enforcement example:

```ts
await requireOrganizationAdmin();
```

UI hiding is not sufficient.

---

# 9. Data Architecture

## 9.1 Core Tables

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

## 9.2 Key Relationship Map

```txt
organizations
  |
  |-- accounts
  |-- customers
  |     |-- invoices
  |           |-- invoice_lines
  |           |-- customer_payments
  |
  |-- vendors
  |     |-- bills
  |           |-- bill_lines
  |           |-- vendor_payments
  |
  |-- journal_entries
  |     |-- journal_lines
  |           |-- accounts
  |
  |-- bank_imports
  |     |-- bank_transactions
  |
  |-- audit_logs
  |-- recurring_invoices
```

---

# 10. Accounting Architecture

## 10.1 Chart of Accounts

The chart of accounts defines valid financial categories.

Table:

```txt
accounts
```

Important account types:

```txt
asset
liability
equity
income
expense
```

---

## 10.2 Journal Engine

Main service:

```txt
services/journal/post-journal-entry.ts
```

Validation module:

```txt
services/journal/validate-post-journal-entry.ts
```

The engine validates:

```txt
Date
Memo
Line count
Account IDs
Integer cents
Non-negative amounts
Exactly one side per line
Debits equal credits
Account ownership
Account active state
```

---

## 10.3 Journal Posting Result

A successful post creates:

```txt
journal_entries row
journal_lines rows
```

It returns:

```txt
created journal entry
created journal lines
total debits
total credits
```

---

# 11. Source Document Architecture

Business documents include:

```txt
Invoices
Bills
Payments
Bank transactions
```

They link to journal entries using:

```txt
journal_entry_id
```

Examples:

```txt
invoices.journal_entry_id
bills.journal_entry_id
customer_payments.journal_entry_id
vendor_payments.journal_entry_id
bank_transactions.journal_entry_id
```

This provides traceability.

---

# 12. Invoice Architecture

Invoice creation service:

```txt
services/invoices/invoice-services.ts
```

Invoice tables:

```txt
invoices
invoice_lines
```

Posting:

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

Additional actions:

```txt
Audit log
Inngest invoice.created event
```

---

# 13. Bill Architecture

Bill creation service:

```txt
services/bills/bill-services.ts
```

Bill tables:

```txt
bills
bill_lines
```

Posting:

```txt
Debit  Purchases
Debit  GST Input Tax
Credit Accounts Payable
```

---

# 14. Payment Architecture

## Customer Payments

Service:

```txt
services/payments/customer-payment-services.ts
```

Posting:

```txt
Debit  Bank
Credit Accounts Receivable
```

Invoice status changes to:

```txt
paid
```

---

## Vendor Payments

Service:

```txt
services/payments/vendor-payment-services.ts
```

Posting:

```txt
Debit  Accounts Payable
Credit Bank
```

Bill status changes to:

```txt
paid
```

---

# 15. Bank Architecture

Bank workflow:

```txt
CSV Upload
  |
  v
bank_imports
bank_transactions imported
  |
  v
Categorization
  |
  v
Posting
  |
  v
Reconciliation
```

Tables:

```txt
bank_imports
bank_transactions
```

Status flow:

```txt
imported -> categorized -> posted -> reconciled
```

---

# 16. Report Architecture

Reports are ledger-based.

Core service:

```txt
services/reports/ledger-report-services.ts
```

It queries:

```txt
journal_lines
journal_entries
accounts
```

and calculates account balances.

---

## 16.1 Signed Balances

Signed balance logic lives in:

```txt
lib/reports/balance-sign.ts
```

Rules:

```txt
Assets: debit - credit
Expenses: debit - credit
Liabilities: credit - debit
Equity: credit - debit
Income: credit - debit
```

---

## 16.2 Profit & Loss

Service:

```txt
services/reports/profit-and-loss-service.ts
```

Formula:

```txt
Income - Expenses = Net Profit
```

---

## 16.3 Balance Sheet

Service:

```txt
services/reports/balance-sheet-service.ts
```

Formula:

```txt
Assets = Liabilities + Equity
```

Includes:

```txt
Current Year Earnings
```

---

## 16.4 GST Report

Service:

```txt
services/reports/gst-f5-service.ts
```

Formula:

```txt
GST Output Tax - GST Input Tax = Net GST
```

---

## 16.5 Aging Reports

Service:

```txt
services/reports/aging-report-services.ts
```

Reads:

```txt
unpaid invoices
unpaid bills
```

Groups by:

```txt
Current
1–30
31–60
61–90
90+
```

---

# 17. Audit Architecture

Audit table:

```txt
audit_logs
```

Audit service:

```txt
services/audit/audit-log-service.ts
```

Audit records include:

```txt
organization_id
actor_user_id
action
entity_type
entity_id
message
metadata_json
created_at
```

Important events:

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

# 18. Reversal Architecture

Reversal service:

```txt
services/journal/reverse-journal-entry.ts
```

Flow:

```txt
Require admin
Load original entry
Load original lines
Swap debits and credits
Create reversal entry
Mark original reversed
Write audit log
```

Reports automatically reflect reversals because they sum journal lines.

---

# 19. Background Job Architecture

Inngest files:

```txt
inngest/client.ts
inngest/events.ts
inngest/functions.ts
app/api/inngest/route.ts
```

Functions:

```txt
background-health-check
invoice-created-confirmation
daily-overdue-invoice-reminders
daily-recurring-invoice-scheduler
```

Events:

```txt
invoice.created
app/health.check
```

---

# 20. Testing Architecture

Test runner:

```txt
Vitest
```

Test files:

```txt
tests/
```

Test focus:

```txt
Money
GST
Journal validation
Report math
Aging
CSV parsing
Currency
CPF
Corporate tax
```

Command:

```bash
pnpm test
pnpm check
```

---

# 21. Deployment Architecture

Deployment stack:

```txt
GitHub -> Vercel
Vercel -> Next.js app
Neon -> Database
Clerk -> Auth
Inngest -> Background jobs
```

Production docs:

```txt
docs/deployment.md
docs/production-checklist.md
docs/security.md
docs/database-operations.md
```

---

# 22. Key Workflows

## 22.1 New Organization Setup

```txt
User signs up
Creates organization
Organization syncs locally
User seeds chart of accounts
Company ready for transactions
```

---

## 22.2 Sales Workflow

```txt
Create customer
Create GST invoice
Post AR/revenue/GST journal entry
Record customer payment
Post bank/AR journal entry
Invoice marked paid
```

---

## 22.3 Purchase Workflow

```txt
Create vendor
Create GST bill
Post purchase/GST input/AP journal entry
Record vendor payment
Post AP/bank journal entry
Bill marked paid
```

---

## 22.4 Bank Workflow

```txt
Upload CSV
Parse rows
Categorize row
Post row to ledger
Mark reconciled
```

---

## 22.5 Reporting Workflow

```txt
Journal lines
  |
  v
Report helpers
  |
  v
Financial reports
```

---

# 23. Important Architecture Risks

## 23.1 Cross-Tenant Data Leakage

Mitigation:

```txt
organization_id filters
server-side organization helpers
tenant isolation tests
```

---

## 23.2 Unbalanced Journal Entries

Mitigation:

```txt
journal validation
database line constraints
automated tests
manual test harness
SQL balance checks
```

---

## 23.3 Background Jobs Without User Context

Scheduled jobs do not naturally have active Clerk user/org context.

Production solution should use:

```txt
system actor
explicit organization iteration
tenant-scoped job execution
```

---

## 23.4 Audit Log Gaps

Mitigation:

```txt
writeAuditLog()
admin review
future audit coverage expansion
```

---

# 24. Architecture Extension Guide

When adding a new financial module, follow this pattern:

```txt
1. Define source document tables.
2. Add organization_id.
3. Build service layer.
4. Validate inputs.
5. Verify referenced records belong to organization.
6. Post journal entry.
7. Link source document to journal entry.
8. Write audit log.
9. Add report impact if needed.
10. Add tests.
```

---

# 25. Example: Adding Credit Notes

Future credit note architecture should follow:

```txt
credit_notes
credit_note_lines
```

Journal entry might be:

```txt
Debit  Sales Revenue
Debit  GST Output Tax
Credit Accounts Receivable
```

It should link:

```txt
credit_notes.journal_entry_id
```

and be tenant-scoped.

---

# 26. Example: Adding Partial Payments

Future partial payment architecture should include:

```txt
amount_paid_cents
amount_due_cents
payment allocation table
invoice status partial
```

Journal posting remains:

```txt
Debit Bank
Credit Accounts Receivable
```

for the payment amount only.

---

# 27. Final Architecture Checklist

The architecture is healthy when:

```txt
UI does not contain core accounting logic.
Server actions delegate to services.
Services enforce tenant scope.
Journal engine enforces balance.
Reports come from journal lines.
Audit logs record sensitive operations.
Admin permissions are server-enforced.
Background jobs are explicit and observable.
Database migrations are reviewed.
Tests protect financial logic.
```

---

# 28. Final Architectural Summary

GreyMatter Ledger is built around three core boundaries:

```txt
Tenant boundary:
  organization_id

Accounting boundary:
  balanced journal entries

Trust boundary:
  server-side validation and authorization
```

The application remains maintainable when those boundaries are respected.

The final architecture can be summarized as:

```txt
Clerk identifies the user and company.
Services validate business operations.
The journal engine protects accounting truth.
Postgres stores durable records.
Reports summarize the ledger.
Audit logs preserve operational history.
Inngest runs background automation.
Vercel hosts the product.
```

That is the architectural foundation of GreyMatter Ledger.
