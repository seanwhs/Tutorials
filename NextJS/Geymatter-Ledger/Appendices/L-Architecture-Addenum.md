# Appendix L — Architecture Addendum

This appendix expands the architecture discussion for **GreyMatter Ledger**.

It is intended as a deeper technical reference for developers who want to understand:

```txt
How the system is layered
Why responsibilities are separated
How requests flow through the app
How accounting data moves from UI to ledger
How multi-tenancy is enforced
How reports are generated
Where future improvements fit
```

This appendix complements:

```txt
docs/final-architecture.md
Appendix B — Database Schema Reference
Appendix C — Journal Engine Reference
Appendix E — Multi-Tenancy and Security Checklist
```

---

# 1. High-Level Architecture

GreyMatter Ledger is a full-stack SaaS accounting application.

At the highest level:

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
Accounting Engine
  |
  v
Drizzle ORM
  |
  v
Neon Postgres
```

External services:

```txt
Clerk  -> authentication, users, organizations, roles
Inngest -> background jobs and scheduled workflows
Vercel -> hosting and deployment
Neon   -> Postgres database
```

---

# 2. Primary Architectural Goals

The architecture is designed around several goals.

---

## 2.1 Accounting Correctness

The system must enforce:

```txt
Total debits = total credits
```

No business workflow should bypass this rule.

Invoices, bills, payments, and bank postings all eventually produce balanced journal entries.

---

## 2.2 Multi-Tenant Isolation

Every company workspace has isolated data.

The main tenant boundary is:

```txt
organization_id
```

Most business tables include it.

Every tenant-scoped query must filter by it.

---

## 2.3 Separation of Concerns

UI components should not contain complex accounting logic.

Instead:

```txt
Pages render UI.
Server actions receive form submissions.
Services enforce business rules.
Journal engine enforces accounting rules.
Database stores durable state.
```

---

## 2.4 Auditability

Accounting software must preserve history.

The app supports:

```txt
Journal reversals
Audit logs
Linked source documents
Posted journal entries
```

The goal is traceability.

---

## 2.5 Extensibility

The app is built so future modules can plug into the ledger.

Examples:

```txt
Payroll
Credit notes
Recurring bills
Bank feeds
Inventory
Multi-currency revaluation
```

---

# 3. Layered Architecture

GreyMatter Ledger uses layered architecture.

```txt
Presentation Layer
  |
  v
Action Layer
  |
  v
Service Layer
  |
  v
Domain / Accounting Layer
  |
  v
Persistence Layer
```

---

# 4. Presentation Layer

The presentation layer includes:

```txt
app/
components/
```

Examples:

```txt
app/invoices/page.tsx
app/bills/[billId]/page.tsx
components/invoice-create-form.tsx
components/account-group-table.tsx
components/report-date-range-form.tsx
```

Responsibilities:

```txt
Render pages
Show forms
Display tables
Show status banners
Link routes
```

Should avoid:

```txt
Direct complex database mutations
Accounting calculations
Authorization-sensitive decisions without server checks
```

UI can hide buttons, but server-side code must enforce permissions.

---

# 5. Action Layer

The action layer includes server action files such as:

```txt
app/accounts/actions.ts
app/invoices/actions.ts
app/bills/actions.ts
app/bank/actions.ts
app/settings/database/journal/actions.ts
```

Responsibilities:

```txt
Receive form submissions
Parse FormData
Call service functions
Revalidate pages
Redirect with status messages
```

Example pattern:

```ts
"use server";

export async function createInvoiceAction(formData: FormData) {
  const result = await createInvoiceForCurrentOrganization({
    customerId: String(formData.get("customerId") ?? ""),
    issueDate: String(formData.get("issueDate") ?? ""),
    dueDate: String(formData.get("dueDate") ?? ""),
    description: String(formData.get("description") ?? ""),
    quantity: Number(formData.get("quantity") ?? 1),
    unitAmount: String(formData.get("unitAmount") ?? ""),
    gstRateBasisPoints: Number(formData.get("gstRateBasisPoints") ?? 900),
  });

  revalidatePath("/invoices");

  if (!result.ok) {
    redirect(`/invoices?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect(`/invoices?status=created&invoice=${result.invoice.invoiceNumber}`);
}
```

Action layer should not become the business logic layer.

It should delegate.

---

# 6. Service Layer

The service layer includes:

```txt
services/
```

Examples:

```txt
services/invoices/invoice-services.ts
services/bills/bill-services.ts
services/payments/customer-payment-services.ts
services/journal/post-journal-entry.ts
services/reports/profit-and-loss-service.ts
services/bank/post-bank-transaction.ts
```

Responsibilities:

```txt
Validate business inputs
Require active organization
Check ownership of referenced records
Enforce workflow rules
Call journal engine
Write database records
Write audit logs
Send background events
```

Service functions are usually named around business operations:

```txt
createInvoiceForCurrentOrganization()
createBillForCurrentOrganization()
recordCustomerPaymentForCurrentOrganization()
recordVendorPaymentForCurrentOrganization()
postBankTransactionForCurrentOrganization()
reverseJournalEntryForCurrentOrganization()
```

The phrase:

```txt
ForCurrentOrganization
```

is intentional.

It signals tenant-scoped behavior.

---

# 7. Domain / Accounting Layer

The accounting domain layer includes:

```txt
lib/accounting/
services/journal/
lib/reports/
services/reports/
```

Important modules:

```txt
lib/accounting/gst.ts
lib/accounting/normal-balance.ts
services/journal/validate-post-journal-entry.ts
services/journal/post-journal-entry.ts
lib/reports/balance-sign.ts
```

Responsibilities:

```txt
Money rules
GST rules
Normal balance rules
Journal validation
Posting rules
Report calculations
```

This layer should be highly testable.

Pure helpers should avoid:

```txt
Database access
Clerk auth
Network calls
```

Example pure function:

```ts
calculateSignedBalanceCents({
  accountType: "income",
  debitCents: 0,
  creditCents: 10000,
});
```

Returns:

```txt
10000
```

---

# 8. Persistence Layer

The persistence layer includes:

```txt
db/schema.ts
db/index.ts
drizzle/
```

Responsibilities:

```txt
Define tables
Define enums
Define indexes
Define constraints
Create database client
Store migrations
```

Important files:

```txt
db/schema.ts
db/index.ts
drizzle.config.ts
```

Database provider:

```txt
Neon Postgres
```

ORM:

```txt
Drizzle ORM
```

---

# 9. External Service Layer

External services:

```txt
Clerk
Inngest
Neon
Vercel
```

---

## Clerk

Used for:

```txt
Authentication
Users
Organizations
Roles
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

## Inngest

Used for:

```txt
Background events
Scheduled jobs
Durable workflows
```

Important files:

```txt
inngest/client.ts
inngest/events.ts
inngest/functions.ts
app/api/inngest/route.ts
```

---

## Neon

Used for:

```txt
Postgres database hosting
```

Configured via:

```txt
DATABASE_URL
```

---

## Vercel

Used for:

```txt
Next.js hosting
Deployment
Environment variables
```

---

# 10. Request Flow: Page Load

Example:

```txt
User opens /invoices
```

Flow:

```txt
Browser request
  |
  v
Next.js route /invoices
  |
  v
Server Component loads
  |
  v
listCurrentOrganizationCustomers()
getCurrentOrganizationInvoiceDiagnostics()
listCurrentOrganizationInvoices()
  |
  v
Services call getOrCreateCurrentOrganization()
  |
  v
Drizzle queries tenant-scoped records
  |
  v
Page renders invoice form and invoice table
```

Key security step:

```txt
Queries are scoped to active organization.
```

---

# 11. Request Flow: Form Submission

Example:

```txt
User submits invoice form
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
Require active organization
Validate customer ownership
Calculate GST
Create invoice
Create invoice line
Post journal entry
Link invoice to journal entry
Write audit log
Send invoice.created event
  |
  v
Redirect to /invoices?status=created
```

---

# 12. Accounting Flow: Invoice

Invoice creation creates both:

```txt
Business document
Accounting entry
```

Business document tables:

```txt
invoices
invoice_lines
```

Ledger tables:

```txt
journal_entries
journal_lines
```

Accounting entry:

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

Relationship:

```txt
invoices.journal_entry_id -> journal_entries.id
```

---

# 13. Accounting Flow: Customer Payment

Customer payment creates:

```txt
customer_payments
journal_entries
journal_lines
```

Accounting entry:

```txt
Debit  Bank
Credit Accounts Receivable
```

Invoice status updates:

```txt
invoices.status = paid
```

Revenue is not recorded again.

---

# 14. Accounting Flow: Bill

Bill creation creates:

```txt
bills
bill_lines
journal_entries
journal_lines
```

Accounting entry:

```txt
Debit  Purchases
Debit  GST Input Tax
Credit Accounts Payable
```

Relationship:

```txt
bills.journal_entry_id -> journal_entries.id
```

---

# 15. Accounting Flow: Vendor Payment

Vendor payment creates:

```txt
vendor_payments
journal_entries
journal_lines
```

Accounting entry:

```txt
Debit  Accounts Payable
Credit Bank
```

Bill status updates:

```txt
bills.status = paid
```

Expense is not recorded again.

---

# 16. Accounting Flow: Bank Transaction

Bank transaction workflow:

```txt
Import CSV
  |
  v
bank_imports
bank_transactions status=imported
  |
  v
Categorize
bank_transactions status=categorized
category_account_id set
  |
  v
Post
journal entry created
bank_transactions status=posted
journal_entry_id set
  |
  v
Reconcile
bank_transactions status=reconciled
reconciled_at set
```

Positive bank amount:

```txt
Debit Bank
Credit Category Account
```

Negative bank amount:

```txt
Debit Category Account
Credit Bank
```

---

# 17. Accounting Flow: Reversal

Reversal flow:

```txt
Admin submits reversal reason
  |
  v
reverseJournalEntryForCurrentOrganization()
  |
  v
Load original entry
Load original lines
Swap debits and credits
Create reversal entry
Mark original as reversed
Write audit log
```

Original:

```txt
Debit Expense
Credit Bank
```

Reversal:

```txt
Debit Bank
Credit Expense
```

---

# 18. Reporting Architecture

Reports are ledger-based.

Most financial reports read:

```txt
journal_entries
journal_lines
accounts
```

Core service:

```txt
services/reports/ledger-report-services.ts
```

It computes account balances by summing:

```txt
debit_cents
credit_cents
```

Then it calculates signed balances based on normal account type behavior.

---

# 19. Report Flow: Profit & Loss

P&L uses:

```txt
income accounts
expense accounts
```

Formula:

```txt
Net Profit = Income - Expenses
```

Service:

```txt
services/reports/profit-and-loss-service.ts
```

Page:

```txt
app/reports/profit-and-loss/page.tsx
```

---

# 20. Report Flow: Balance Sheet

Balance Sheet uses:

```txt
assets
liabilities
equity
current year earnings
```

Formula:

```txt
Assets = Liabilities + Equity
```

Current Year Earnings:

```txt
Income - Expenses
```

Service:

```txt
services/reports/balance-sheet-service.ts
```

Page:

```txt
app/reports/balance-sheet/page.tsx
```

---

# 21. Report Flow: GST F5-Style Report

GST report uses:

```txt
1400 GST Input Tax
2110 GST Output Tax
```

Formula:

```txt
Net GST = GST Output Tax - GST Input Tax
```

Service:

```txt
services/reports/gst-f5-service.ts
```

Page:

```txt
app/reports/gst-f5/page.tsx
```

---

# 22. Authentication Architecture

Authentication flow:

```txt
User opens protected route
  |
  v
proxy.ts checks Clerk session
  |
  |-- no session -> redirect to sign-in
  |
  |-- session -> allow request
```

Important file:

```txt
proxy.ts
```

Protected route examples:

```txt
/dashboard
/accounts
/invoices
/reports
/settings
/bank
```

---

# 23. Organization Architecture

Organization flow:

```txt
User signs in
  |
  v
User selects Clerk organization
  |
  v
getCurrentOrganizationContext()
  |
  v
getOrCreateCurrentOrganization()
  |
  v
Local organizations row available
  |
  v
Business records use organizations.id
```

---

# 24. Authorization Architecture

Authorization helper:

```txt
lib/authorization.ts
```

Admin check:

```ts
await requireOrganizationAdmin();
```

Used for:

```txt
Audit log access
Journal reversals
```

Key principle:

```txt
Hide buttons for UX.
Enforce permissions on the server.
```

---

# 25. Background Job Architecture

Inngest files:

```txt
inngest/client.ts
inngest/events.ts
inngest/functions.ts
app/api/inngest/route.ts
```

Event producer example:

```txt
Invoice creation sends invoice.created
```

Function consumer example:

```txt
invoiceCreatedConfirmation listens for invoice.created
```

Scheduled jobs:

```txt
daily-overdue-invoice-reminders
daily-recurring-invoice-scheduler
```

---

# 26. Audit Architecture

Audit service:

```txt
services/audit/audit-log-service.ts
```

Audit table:

```txt
audit_logs
```

Audit log fields:

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

Audit logs are written after important operations:

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

# 27. Testing Architecture

Test framework:

```txt
Vitest
```

Test directory:

```txt
tests/
```

Current test focus:

```txt
Pure functions
Financial calculations
Journal validation
Report math
CSV parsing
```

Manual integration testing is used for:

```txt
Invoice creation
Bill creation
Payments
Bank posting
Reconciliation
Inngest workflows
```

Future recommended testing:

```txt
Database integration tests
Playwright end-to-end tests
Authorization tests
Tenant isolation tests
```

---

# 28. Deployment Architecture

Deployment stack:

```txt
Vercel -> app hosting
Neon -> database
Clerk -> auth
Inngest -> jobs
GitHub -> source control
```

Important docs:

```txt
docs/deployment.md
docs/production-checklist.md
docs/security.md
docs/database-operations.md
```

---

# 29. Key Architectural Tradeoffs

## 29.1 Service Layer Instead of Fat Pages

Tradeoff:

```txt
More files
```

Benefit:

```txt
Cleaner business logic
Reusable services
Better testability
Safer accounting rules
```

---

## 29.2 Ledger-Based Reports

Tradeoff:

```txt
Reports require correct journal posting
```

Benefit:

```txt
Reports reflect accounting truth
```

---

## 29.3 Local Organization Table

Tradeoff:

```txt
Need to sync Clerk orgs
```

Benefit:

```txt
Foreign keys
Application-specific organization settings
Decoupling from identity provider internals
```

---

## 29.4 Integer Cents

Tradeoff:

```txt
Need formatting helpers
```

Benefit:

```txt
Avoid floating-point money errors
```

---

## 29.5 Reversals Instead of Deletes

Tradeoff:

```txt
More records
```

Benefit:

```txt
Better audit trail
Accounting history preserved
```

---

# 30. Recommended Future Architecture Improvements

Future improvements could include:

```txt
Command bus pattern for financial actions
Dedicated system actor context for background jobs
Database integration test harness
Role and permission matrix
Append-only ledger enforcement
Accounting period close table
Webhooks for Clerk and Inngest validation
Email provider abstraction
PDF generation service
File storage service
Event outbox pattern
Observability and tracing
```

---

# 31. Architecture Review Checklist

Before adding a new feature, ask:

```txt
Does this belong to an organization?
Does the table need organization_id?
Does the service require active organization?
Does it affect the ledger?
Does it need a journal entry?
Does it need an audit log?
Does it need admin permission?
Does it need background processing?
Does it need report impact?
Does it need tests?
```

---

# 32. Final Architecture Summary

GreyMatter Ledger is built around three core boundaries:

```txt
Tenant boundary:
  organization_id

Accounting boundary:
  balanced journal entries

Trust boundary:
  server-side services and actions
```

The system is healthy when:

```txt
Every company sees only its own data.
Every financial event posts balanced entries.
Every sensitive action is enforced on the server.
Every important action is auditable.
Reports come from the ledger.
```

That is the architecture of GreyMatter Ledger.
