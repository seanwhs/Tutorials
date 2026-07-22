# Product Requirements Document  
# GreyMatter Ledger

**Document type:** Product Requirements Document  
**Product name:** GreyMatter Ledger  
**Version:** 1.0  
**Status:** Draft  
**Primary market:** Singapore small businesses, accountants, and finance operators  
**Primary platform:** Web application  
**Prepared for:** Product, engineering, design, QA, and operations teams  

---

# 1. Executive Summary

GreyMatter Ledger is a modern, Singapore-ready, multi-tenant double-entry accounting web application for small businesses, accountants, and finance teams.

The product allows users to manage company workspaces, maintain a chart of accounts, create GST-aware invoices and bills, record payments, import bank transactions, reconcile bank activity, generate core financial reports, and maintain an auditable accounting history.

The central product principle is:

```txt
Every financial event must be explainable through balanced double-entry journal entries.
```

The central accounting invariant is:

```txt
Total debits = total credits
```

GreyMatter Ledger is designed as a professional SaaS-style accounting foundation with:

- Secure authentication
- Company/organization workspaces
- Tenant-isolated financial records
- Double-entry journal engine
- Singapore GST-aware workflows
- Audit logs
- Financial reporting
- Bank import and reconciliation
- Background jobs
- Production deployment readiness

---

# 2. Product Vision

GreyMatter Ledger aims to provide a clean, reliable accounting platform that helps Singapore small businesses and accounting professionals maintain accurate financial records without hiding the accounting logic.

The product should be beginner-friendly for operators while remaining technically and financially rigorous under the hood.

The long-term vision is to become a modular accounting SaaS platform that can support:

```txt
Sales workflows
Purchase workflows
Payments
GST reporting
Bank reconciliation
Payroll estimates
Tax estimates
Multi-currency documents
Automation
Auditability
```

---

# 3. Product Goals

## 3.1 Business Goals

GreyMatter Ledger should:

1. Help small businesses record financial activity accurately.
2. Support Singapore-oriented workflows such as GST, CPF estimates, and corporate tax estimates.
3. Provide a strong foundation for accountants managing multiple client companies.
4. Demonstrate professional SaaS architecture and accounting correctness.
5. Reduce manual bookkeeping errors by enforcing double-entry rules.

---

## 3.2 User Goals

Users should be able to:

1. Create and manage company workspaces.
2. Maintain a chart of accounts.
3. Create GST-aware invoices.
4. Record vendor bills.
5. Record customer and vendor payments.
6. Import and categorize bank transactions.
7. Reconcile bank activity.
8. Generate financial reports.
9. Review audit history.
10. Trust that posted journal entries balance.

---

## 3.3 Engineering Goals

The system should:

1. Enforce multi-tenant data isolation.
2. Store all money as integer cents.
3. Enforce balanced journal entries.
4. Keep accounting logic server-side.
5. Use type-safe database queries.
6. Provide auditability for sensitive operations.
7. Be deployable to Vercel.
8. Use background jobs for automation.
9. Support future expansion without major rewrites.

---

# 4. Non-Goals

The initial product does **not** aim to be a complete certified accounting package.

The following are out of scope for the initial version:

- Official IRAS GST filing submission
- Full payroll processing
- CPF statutory submission
- IR8A generation
- Full corporate tax computation
- Inventory costing
- Project accounting
- Approval workflows
- E-invoicing network integration
- Real bank feed integration
- Full multi-currency revaluation
- Advanced consolidation
- Accrual automation beyond basic invoices/bills
- Native mobile apps
- Offline mode

---

# 5. Target Users

## 5.1 Small Business Owner

A small business owner wants to:

- Send invoices
- Track bills
- Know who owes money
- Know what vendors are owed
- See business profit
- Understand GST position
- Keep records organized

Technical skill level:

```txt
Low to medium
```

Accounting skill level:

```txt
Basic
```

---

## 5.2 Accountant / Bookkeeper

An accountant wants to:

- Manage multiple client companies
- Review journal entries
- Check reports
- Reconcile bank transactions
- Correct mistakes with audit trail
- Export or inspect accounting records

Technical skill level:

```txt
Medium
```

Accounting skill level:

```txt
High
```

---

## 5.3 Finance Operator

A finance operator wants to:

- Enter customer invoices
- Enter supplier bills
- Record payments
- Upload bank CSVs
- Categorize bank transactions
- Run routine reports

Technical skill level:

```txt
Low to medium
```

Accounting skill level:

```txt
Medium
```

---

## 5.4 Developer / Technical Evaluator

A developer wants to:

- Understand accounting software architecture
- Review type-safe implementation
- Inspect database schema
- Extend the app
- Use it as a portfolio-grade SaaS project

Technical skill level:

```txt
High
```

Accounting skill level:

```txt
Low to medium
```

---

# 6. User Personas

## Persona 1 — Amanda, Small Business Owner

Amanda runs a Singapore consulting company.

She needs to:

- Invoice clients
- Track payments
- Track software subscriptions
- Know her GST payable
- See monthly profit

Pain points:

- Spreadsheets are error-prone
- Accounting software feels complicated
- She wants confidence without becoming an accountant

---

## Persona 2 — Daniel, Accountant

Daniel manages books for multiple clients.

He needs to:

- Switch between companies
- Review chart of accounts
- Inspect journal entries
- Correct errors without deleting history
- Run Profit & Loss and Balance Sheet reports

Pain points:

- Client data must stay isolated
- Corrections need audit trail
- Reports must be ledger-based

---

## Persona 3 — Priya, Finance Admin

Priya handles weekly bookkeeping.

She needs to:

- Enter bills
- Record payments
- Upload bank statements
- Categorize transactions
- Check unpaid invoices and bills

Pain points:

- Manual matching is tedious
- Payment mistakes are common
- She needs clear status indicators

---

# 7. Product Scope

## 7.1 In Scope

The first complete product version includes:

```txt
Authentication
Organizations
Database
Chart of accounts
Journal engine
Customers
Vendors
Invoices
Bills
Payments
Reports
Audit logs
Role checks
Bank CSV import
Bank categorization
Bank posting
Bank reconciliation
Background jobs
Deployment docs
Singapore advanced estimate modules
```

---

## 7.2 Out of Scope

The following are explicitly out of scope for the current product version:

```txt
Real email sending
Invoice PDF rendering
Partial payments
Credit notes
Debit notes
Official GST submission
Full payroll
Inventory
Bank feed APIs
Native mobile app
```

---

# 8. Core Product Principles

## 8.1 Ledger First

Reports must come from journal lines, not only source documents.

```txt
Source documents explain.
Journal entries account.
Reports summarize.
```

---

## 8.2 Double-Entry Integrity

The app must reject unbalanced journal entries.

```txt
totalDebitCents === totalCreditCents
```

---

## 8.3 Tenant Isolation

Every company’s data must remain isolated.

Users must only access records belonging to the active organization.

---

## 8.4 Server-Side Trust

Sensitive rules must be enforced on the server.

Do not trust browser-submitted organization IDs, amounts, permissions, or account ownership.

---

## 8.5 Auditability

Important financial and administrative actions must be traceable.

Posted accounting history should be corrected through reversals, not casual deletion.

---

## 8.6 Integer Money

Money must be stored as integer cents.

Example:

```txt
S$109.00 = 10900
```

---

# 9. Functional Requirements

---

# 9.1 Authentication

## Requirement

The system must allow users to sign up, sign in, sign out, and access protected routes.

## Acceptance Criteria

- Users can sign up.
- Users can sign in.
- Users can sign out.
- Signed-out users cannot access protected routes.
- Signed-in users can access dashboard routes.
- User identity is available server-side.

## Protected Routes

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

---

# 9.2 Organizations / Company Workspaces

## Requirement

The system must support multiple company workspaces using organizations.

## Acceptance Criteria

- Users can create an organization.
- Users can switch active organizations.
- The app can read active organization context.
- The active Clerk organization can be synced to a local database organization.
- Business records are scoped to local database organization ID.

---

# 9.3 Chart of Accounts

## Requirement

Each organization must have its own chart of accounts.

## Acceptance Criteria

- Accounts belong to organizations.
- Account codes are unique per organization.
- Users can seed a Singapore-friendly default chart of accounts.
- Users can create custom accounts.
- Users can deactivate and reactivate accounts.
- Inactive accounts cannot be used for new journal postings.

## Default Accounts Must Include

```txt
1000 Bank
1100 Accounts Receivable
1400 GST Input Tax
2000 Accounts Payable
2110 GST Output Tax
3000 Share Capital
4000 Sales Revenue
5100 Purchases
6200 CPF Employer Contributions
7000 Income Tax Expense
```

---

# 9.4 Journal Engine

## Requirement

The system must post only valid balanced journal entries.

## Acceptance Criteria

The journal engine must reject entries when:

- Date is invalid
- Memo is missing
- Fewer than two lines exist
- Account ID is invalid
- Amounts are not integer cents
- Amounts are negative
- A line has both debit and credit
- A line has neither debit nor credit
- Total debits do not equal total credits
- Account does not belong to active organization
- Account is inactive

The journal engine must:

- Insert journal entry and lines transactionally.
- Store source type and source ID.
- Store posting user ID when available.
- Return created journal entry and lines.

---

# 9.5 Customers

## Requirement

Users must be able to create and list customers per organization.

## Acceptance Criteria

- Customer records include name, email, phone, billing address, notes, and active status.
- Customers are scoped by organization.
- Customer creation validates name and email.
- Customer list only shows active organization data.

---

# 9.6 Vendors

## Requirement

Users must be able to create and list vendors per organization.

## Acceptance Criteria

- Vendor records include name, email, phone, billing address, notes, and active status.
- Vendors are scoped by organization.
- Vendor creation validates name and email.
- Vendor list only shows active organization data.

---

# 9.7 Invoices

## Requirement

Users must be able to create GST-aware invoices for customers.

## Acceptance Criteria

- Invoice belongs to active organization.
- Invoice belongs to a customer in the same organization.
- Invoice number is generated automatically.
- Invoice lines calculate subtotal, GST, and total.
- Invoice creation posts a balanced journal entry.
- Invoice stores linked journal entry ID.
- Invoice list shows invoices.
- Invoice detail shows customer, lines, totals, and journal entry.

## Invoice Journal Entry

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

---

# 9.8 Bills

## Requirement

Users must be able to record GST-aware vendor bills.

## Acceptance Criteria

- Bill belongs to active organization.
- Bill belongs to a vendor in the same organization.
- Bill number is generated automatically.
- Bill lines calculate subtotal, GST, and total.
- Bill creation posts a balanced journal entry.
- Bill stores linked journal entry ID.
- Bill list shows bills.
- Bill detail shows vendor, lines, totals, and journal entry.

## Bill Journal Entry

```txt
Debit  Purchases
Debit  GST Input Tax
Credit Accounts Payable
```

---

# 9.9 Customer Payments

## Requirement

Users must be able to record full customer invoice payments.

## Acceptance Criteria

- Payment belongs to active organization.
- Payment references an invoice in the same organization.
- Already paid invoices cannot be paid again.
- Void invoices cannot be paid.
- Payment posts a balanced journal entry.
- Invoice status updates to paid.
- Payment appears in payment diagnostics.

## Customer Payment Journal Entry

```txt
Debit  Bank
Credit Accounts Receivable
```

---

# 9.10 Vendor Payments

## Requirement

Users must be able to record full vendor bill payments.

## Acceptance Criteria

- Payment belongs to active organization.
- Payment references a bill in the same organization.
- Already paid bills cannot be paid again.
- Void bills cannot be paid.
- Payment posts a balanced journal entry.
- Bill status updates to paid.
- Payment appears in payment diagnostics.

## Vendor Payment Journal Entry

```txt
Debit  Accounts Payable
Credit Bank
```

---

# 9.11 Reports

## Requirement

The system must generate financial reports from journal lines.

## Required Reports

```txt
Ledger Overview
Profit & Loss
Balance Sheet
AR Aging
AP Aging
GST F5-style Report
```

## Acceptance Criteria

- Reports are scoped to active organization.
- Reports use date filters where applicable.
- Profit & Loss includes income and expenses.
- Balance Sheet includes assets, liabilities, equity, and current year earnings.
- AR Aging includes unpaid invoices.
- AP Aging includes unpaid bills.
- GST report includes GST Output Tax and GST Input Tax.
- Reports must not mix tenant data.

---

# 9.12 Reversals

## Requirement

Admins must be able to reverse posted journal entries.

## Acceptance Criteria

- Reversal requires organization admin role.
- Already reversed entries cannot be reversed again.
- Reversal entry swaps debits and credits.
- Original entry is marked reversed.
- Reversal entry links to original entry.
- Reversal writes audit log.
- Reports reflect reversal automatically.

---

# 9.13 Audit Logs

## Requirement

The system must record important operational actions.

## Acceptance Criteria

Audit logs should be created for:

```txt
Customer creation
Vendor creation
Invoice creation
Bill creation
Customer payment
Vendor payment
Journal reversal
```

Audit logs must include:

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

Audit log access must be admin-only.

---

# 9.14 Role-Based Access Control

## Requirement

The system must restrict sensitive actions by organization role.

## Acceptance Criteria

- Current organization role can be read from Clerk.
- Admin helper exists.
- Audit log page requires admin.
- Journal reversal requires admin.
- Non-admin users are blocked from admin-only actions.

---

# 9.15 Bank Import

## Requirement

Users must be able to upload bank CSV files.

## CSV Format

```csv
date,description,amount
2026-01-05,Customer payment,109.00
2026-01-06,Vendor payment,-25.50
```

## Acceptance Criteria

- CSV parser validates headers.
- CSV parser validates date, description, and amount.
- Upload creates bank import row.
- Upload creates bank transaction rows.
- Positive amounts represent inflows.
- Negative amounts represent outflows.

---

# 9.16 Bank Categorization

## Requirement

Users must categorize imported bank transactions.

## Acceptance Criteria

- Categorization selects an account.
- Category account must belong to active organization.
- Category account must be active.
- Posted or reconciled transactions cannot be recategorized.
- Categorized transaction status becomes `categorized`.

---

# 9.17 Bank Posting

## Requirement

Users must post categorized bank transactions to the ledger.

## Acceptance Criteria

- Only categorized transactions can be posted.
- Posting creates balanced journal entry.
- Positive amount debits Bank and credits category account.
- Negative amount debits category account and credits Bank.
- Bank transaction stores journal entry ID.
- Bank transaction status becomes `posted`.

---

# 9.18 Bank Reconciliation

## Requirement

Users must mark posted bank transactions as reconciled.

## Acceptance Criteria

- Only posted transactions can be reconciled.
- Reconciled transactions store reconciled timestamp.
- Reconciled transactions store user ID.
- Reconciled transactions status becomes `reconciled`.

---

# 9.19 Background Jobs

## Requirement

The system must support background jobs with Inngest.

## Acceptance Criteria

- Inngest client exists.
- Inngest route exists.
- Health check event can be sent.
- Invoice created event is emitted.
- Invoice created function handles event.
- Daily overdue invoice reminder job exists.
- Recurring invoice scheduler stub exists.

---

# 9.20 Advanced Singapore Modules

## Requirement

The system must include educational Singapore-oriented modules.

## Modules

```txt
Multi-currency reference
CPF estimate
Corporate tax estimate
```

## Acceptance Criteria

- Multi-currency helper converts foreign cents to SGD cents.
- CPF estimate helper calculates simplified employee/employer CPF.
- Corporate tax helper estimates simplified tax at 17%.
- All advanced modules include disclaimers.

---

# 10. Non-Functional Requirements

---

## 10.1 Security

The system must:

- Protect internal routes.
- Enforce server-side authorization.
- Keep secrets out of Git.
- Scope tenant data by organization.
- Avoid trusting browser-submitted organization IDs.
- Restrict admin features.
- Avoid leaking cross-tenant record existence.

---

## 10.2 Data Integrity

The system must:

- Store money as integer cents.
- Enforce balanced journal entries.
- Use database constraints for line-level validity.
- Link source documents to journal entries.
- Use reversals instead of deleting posted entries.
- Prevent duplicate account codes per organization.

---

## 10.3 Performance

Initial performance requirements:

- Dashboard should load within acceptable SaaS norms for small datasets.
- Reports should support normal small-business datasets.
- Indexes should exist on key organization/date/status columns.
- Heavy future reporting may require pagination and optimization.

---

## 10.4 Availability

The app should be deployable to Vercel and use managed services for reliability.

Dependencies:

```txt
Vercel
Neon
Clerk
Inngest
```

---

## 10.5 Observability

Initial observability:

- Vercel logs
- Inngest dashboard
- Neon dashboard
- Audit logs
- Database diagnostic pages

Future observability:

- Error tracking
- Structured logging
- Performance tracing
- Alerting

---

## 10.6 Compliance

The system must include clear disclaimers for:

```txt
GST reports
CPF estimates
Corporate tax estimates
```

The product must not claim to be certified filing software.

---

# 11. Data Requirements

## Core Tables

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

## Data Retention

Financial records should be retained and not casually deleted.

Future production requirements should define retention policy according to Singapore legal and business needs.

---

# 12. User Experience Requirements

## General UX

The UI should be:

- Clear
- Beginner-friendly
- Responsive
- Consistent
- Helpful when empty
- Explicit about accounting effects

---

## Forms

Forms should:

- Use clear labels.
- Validate required fields.
- Show success and error banners.
- Avoid exposing internal complexity unnecessarily.

---

## Accounting Transparency

Where useful, pages should show journal impact.

Examples:

- Invoice detail page shows linked journal entry.
- Bill detail page shows linked journal entry.
- Journal diagnostics show debits and credits.

---

# 13. Acceptance Criteria Summary

The product is acceptable when:

```txt
Users can authenticate.
Users can create/select organizations.
Organizations sync to database.
Accounts can be seeded.
Journal engine posts only balanced entries.
Customers and vendors can be created.
Invoices and bills post journal entries.
Payments settle invoices and bills.
Reports generate from journal lines.
Audit logs record important actions.
Bank CSV import works.
Bank transactions can be categorized, posted, and reconciled.
Background job endpoint works.
Production deployment docs exist.
```

---

# 14. Key Workflows

## 14.1 New Company Setup

```txt
User signs up
Creates organization
Organization syncs to database
User seeds chart of accounts
User can begin accounting workflows
```

---

## 14.2 Invoice Workflow

```txt
Create customer
Create invoice
Calculate GST
Post journal entry
Invoice appears in list
Invoice detail shows journal entry
Record customer payment
Invoice marked paid
```

---

## 14.3 Bill Workflow

```txt
Create vendor
Create bill
Calculate GST input tax
Post journal entry
Bill appears in list
Bill detail shows journal entry
Record vendor payment
Bill marked paid
```

---

## 14.4 Bank Workflow

```txt
Upload CSV
Parse transactions
Categorize transaction
Post transaction to ledger
Mark transaction reconciled
```

---

## 14.5 Reporting Workflow

```txt
Post invoices/bills/payments
Open reports
Reports read journal lines
Review P&L, Balance Sheet, GST, aging reports
```

---

# 15. Success Metrics

Potential product success metrics:

## Product Usage

```txt
Organizations created
Accounts seeded
Invoices created
Bills created
Payments recorded
Bank transactions imported
Reports viewed
```

## Accounting Integrity

```txt
Number of unbalanced entries inserted: must be zero
Journal balance SQL returns zero rows
Failed posting attempts due to validation
```

## Operational Health

```txt
Vercel build success rate
Inngest function success rate
Database migration success
Error rate
```

## User Value

```txt
Time to create first invoice
Time to generate first report
Number of reconciled bank transactions
```

---

# 16. Risks

## 16.1 Accounting Incorrectness

Risk:

```txt
Incorrect journal entries or reports.
```

Mitigation:

```txt
Central journal engine
Automated validation tests
Ledger-based reports
SQL balance checks
```

---

## 16.2 Cross-Tenant Data Leakage

Risk:

```txt
One company sees another company’s data.
```

Mitigation:

```txt
organization_id on business tables
server-side organization helpers
tenant-scoped queries
manual tenant isolation testing
```

---

## 16.3 Tax Misinterpretation

Risk:

```txt
Users rely on simplified GST/CPF/tax modules for real filing.
```

Mitigation:

```txt
Clear disclaimers
Educational labeling
Professional review recommendation
```

---

## 16.4 Background Job Context

Risk:

```txt
Scheduled jobs lack user organization context.
```

Mitigation:

```txt
Use explicit system-context design for production jobs
Avoid relying on active user session in scheduled jobs
```

---

# 17. Future Enhancements

High-priority future features:

```txt
Partial payments
Credit notes
Debit notes
Manual journal entry UI
Trial Balance
General Ledger
Cash Flow Statement
Invoice PDFs
Email sending
Approval workflow
Accounting period close
Full GST F5 mapping
Full CPF payroll
Production-grade recurring invoice scheduler
System actor background jobs
Integration tests
Playwright E2E tests
```

---

# 18. Open Questions

Before production use, answer:

```txt
Should users be allowed to edit posted invoices?
How should voiding invoices work?
How should credit notes be modeled?
How should partial payments be handled?
How should GST filing periods be locked?
Should journal entries be append-only at database level?
What roles beyond admin/member are required?
What data export formats are needed?
What email provider should send invoices/reminders?
What backup and restore SLA is required?
```

---

# 19. Launch Readiness Checklist

Before launch:

```txt
pnpm check passes
Production env vars configured
Database migrations applied
Clerk production URLs configured
Inngest endpoint configured
Admin user verified
Tenant isolation manually tested
Journal balance SQL returns zero rows
Audit log tested
Smoke test completed
Production docs reviewed
```

---

# 20. Final Product Statement

GreyMatter Ledger is a multi-tenant, Singapore-ready accounting SaaS foundation that prioritizes:

```txt
Accounting correctness
Data isolation
Auditability
Clear reporting
Production-minded engineering
```

The product is successful when users can confidently record financial activity and trust that every accounting result is backed by a balanced ledger.
