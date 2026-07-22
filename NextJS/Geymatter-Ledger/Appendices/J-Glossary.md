# Appendix J — Glossary

This glossary defines important terms used throughout the **GreyMatter Ledger** tutorial series.

It includes:

```txt
Accounting terms
Software engineering terms
Database terms
Security terms
Singapore-specific business terms
```

The explanations are intentionally beginner-friendly.

---

# A

## Account

An account is a category used to classify financial activity.

Examples:

```txt
Bank
Accounts Receivable
Accounts Payable
Sales Revenue
Rent Expense
GST Output Tax
```

In GreyMatter Ledger, accounts are stored in:

```txt
accounts
```

Every journal line points to one account.

---

## Account Code

A short code used to identify an account.

Examples:

```txt
1000 Bank
1100 Accounts Receivable
4000 Sales Revenue
6000 Rent Expense
```

Account codes are unique per organization.

---

## Account Type

The category of an account.

GreyMatter Ledger uses:

```txt
asset
liability
equity
income
expense
```

Account type affects normal balance and reporting.

---

## Accounts Payable

Money the business owes vendors.

Abbreviation:

```txt
AP
```

Example:

```txt
A vendor sends a bill for S$109.
The business owes the vendor S$109.
```

Accounts Payable is a liability account.

---

## Accounts Receivable

Money customers owe the business.

Abbreviation:

```txt
AR
```

Example:

```txt
The business sends an invoice for S$109.
The customer owes the business S$109.
```

Accounts Receivable is an asset account.

---

## ACRA

Accounting and Corporate Regulatory Authority of Singapore.

ACRA regulates business entities, company filings, and statutory compliance in Singapore.

---

## Aging Report

A report that groups unpaid invoices or bills by how overdue they are.

Common buckets:

```txt
Current
1–30 days
31–60 days
61–90 days
90+ days
```

Types:

```txt
AR Aging
AP Aging
```

---

## App Router

The modern Next.js routing system using the `app/` directory.

Example:

```txt
app/page.tsx -> /
app/invoices/page.tsx -> /invoices
app/invoices/[invoiceId]/page.tsx -> /invoices/:invoiceId
```

---

## Asset

Something the business owns or controls.

Examples:

```txt
Bank
Cash
Accounts Receivable
Inventory
GST Input Tax
Fixed Assets
```

Assets normally increase with debits.

---

## Audit Log

A record of operational activity.

Examples:

```txt
Invoice created
Bill created
Payment recorded
Journal entry reversed
```

Audit logs answer:

```txt
Who did what, when, and to which record?
```

Stored in:

```txt
audit_logs
```

---

## Authorization

Determines what a signed-in user is allowed to do.

Example:

```txt
An organization admin can reverse journal entries.
A normal member cannot.
```

Authorization is different from authentication.

---

# B

## Balance Sheet

A report showing:

```txt
Assets
Liabilities
Equity
```

as of a specific date.

Core equation:

```txt
Assets = Liabilities + Equity
```

---

## Bank Import

The process of uploading bank statement data into the app.

In GreyMatter Ledger, bank CSV uploads create:

```txt
bank_imports
bank_transactions
```

---

## Bank Reconciliation

The process of confirming that accounting bank records match the bank statement.

A simple workflow:

```txt
Import bank CSV
Categorize transaction
Post to ledger
Mark reconciled
```

---

## Basis Points

A whole-number way to represent percentages.

```txt
1% = 100 basis points
9% = 900 basis points
17% = 1700 basis points
```

Used for:

```txt
GST rates
CPF rates
Tax rates
Exchange rates
```

---

## Bill

A document from a vendor saying the business owes money.

Example:

```txt
Cloud Hosting SG sends a bill for S$109.
```

A bill usually creates Accounts Payable.

---

# C

## Chart of Accounts

The master list of accounts used by an organization.

Examples:

```txt
1000 Bank
1100 Accounts Receivable
2000 Accounts Payable
4000 Sales Revenue
6000 Rent Expense
```

Stored in:

```txt
accounts
```

---

## Clerk

The authentication and user management platform used by GreyMatter Ledger.

Clerk handles:

```txt
Sign-in
Sign-up
Sessions
Users
Organizations
Roles
```

---

## Clerk Organization

A company workspace managed by Clerk.

GreyMatter Ledger syncs Clerk organizations into local database rows.

---

## Corporate Tax

Tax on company profits.

The tutorial includes a simplified corporate tax estimate module, but it is not tax advice.

---

## CPF

Central Provident Fund.

Singapore’s mandatory social security savings scheme.

The tutorial includes a simplified CPF estimate module, but it is not payroll advice.

---

## Credit

One side of a journal line.

Credits increase:

```txt
Liabilities
Equity
Income
```

Credits decrease:

```txt
Assets
Expenses
```

---

## Customer

A person or business that buys from the company.

Customers are used for invoices and accounts receivable.

Stored in:

```txt
customers
```

---

# D

## Database Migration

A versioned database schema change.

Example:

```txt
Create invoices table
Add customer_payments table
Add audit_logs table
```

GreyMatter Ledger uses Drizzle Kit for migrations.

---

## Debit

One side of a journal line.

Debits increase:

```txt
Assets
Expenses
```

Debits decrease:

```txt
Liabilities
Equity
Income
```

---

## Double-Entry Accounting

An accounting system where every financial event has equal debits and credits.

Core rule:

```txt
Total debits = total credits
```

GreyMatter Ledger enforces this through the journal engine.

---

## Drizzle ORM

The TypeScript ORM used to define schemas and query Postgres.

Files:

```txt
db/schema.ts
db/index.ts
drizzle.config.ts
```

---

# E

## Equity

The owner’s claim in the business after liabilities.

Formula:

```txt
Equity = Assets - Liabilities
```

Examples:

```txt
Share Capital
Retained Earnings
Current Year Earnings
```

Equity normally increases with credits.

---

## Expense

A cost incurred by the business.

Examples:

```txt
Rent Expense
Software and Subscriptions
Professional Fees
Bank Charges
CPF Employer Contributions
```

Expenses normally increase with debits.

---

# F

## Financial Statement

A formal report about financial position or performance.

Examples:

```txt
Profit & Loss
Balance Sheet
Cash Flow Statement
```

---

## Foreign Key

A database rule linking one table to another.

Example:

```txt
invoices.customer_id references customers.id
```

Foreign keys protect relational integrity.

---

# G

## General Ledger

The complete set of accounts and journal activity.

GreyMatter Ledger’s ledger is built from:

```txt
journal_entries
journal_lines
accounts
```

---

## GST

Goods and Services Tax in Singapore.

GreyMatter Ledger models simplified GST using:

```txt
GST Input Tax
GST Output Tax
```

---

## GST F5

A Singapore GST return form.

The tutorial includes a simplified GST F5-style report, not official filing software.

---

## GST Input Tax

GST paid on purchases.

In the tutorial chart of accounts:

```txt
1400 GST Input Tax
```

Modeled as an asset.

---

## GST Output Tax

GST collected from customers.

In the tutorial chart of accounts:

```txt
2110 GST Output Tax
```

Modeled as a liability.

---

# I

## Immutable

Not changed after creation.

In accounting, posted journal entries should generally be treated as immutable.

Corrections should use reversals.

---

## Income

Revenue earned by the business.

Examples:

```txt
Sales Revenue
Service Revenue
Other Income
```

Income normally increases with credits.

---

## Inngest

The background job and workflow platform used by GreyMatter Ledger.

Used for:

```txt
Invoice events
Overdue invoice reminders
Recurring invoice scheduler stub
```

---

## Invoice

A document sent to a customer requesting payment.

Invoices create Accounts Receivable when posted.

---

## IRAS

Inland Revenue Authority of Singapore.

IRAS administers taxes such as GST and corporate tax.

---

# J

## Journal Entry

A group of journal lines that records one financial event.

Example:

```txt
Invoice INV-0001 issued
```

A journal entry must balance.

Stored in:

```txt
journal_entries
```

---

## Journal Line

One debit or credit inside a journal entry.

Example:

```txt
Debit Bank S$100
```

Stored in:

```txt
journal_lines
```

---

## Journal Engine

The service layer that validates and posts journal entries.

Important function:

```ts
postJournalEntry()
```

---

# L

## Ledger

The accounting source of truth.

In GreyMatter Ledger, the ledger is made of:

```txt
journal_entries
journal_lines
```

---

## Liability

Something the business owes.

Examples:

```txt
Accounts Payable
GST Output Tax
Loans Payable
Customer Deposits
```

Liabilities normally increase with credits.

---

# M

## Migration

See Database Migration.

---

## Multi-Currency

The ability to handle documents in currencies other than the base currency.

GreyMatter Ledger’s base currency is:

```txt
SGD
```

---

## Multi-Tenancy

One application serving multiple organizations while keeping data isolated.

In GreyMatter Ledger:

```txt
organization_id
```

is the key tenant boundary.

---

# N

## Neon

The serverless Postgres database platform used by GreyMatter Ledger.

---

## Normal Balance

The side that normally increases an account.

Examples:

```txt
Assets: debit
Expenses: debit
Liabilities: credit
Equity: credit
Income: credit
```

---

# O

## Organization

A company workspace.

In GreyMatter Ledger, organization context comes from Clerk and is synced to the local database.

---

## ORM

Object-Relational Mapper.

A tool that helps application code work with database tables.

GreyMatter Ledger uses Drizzle ORM.

---

# P

## Payment

A transaction that settles an invoice or bill.

Customer payment:

```txt
Debit Bank
Credit Accounts Receivable
```

Vendor payment:

```txt
Debit Accounts Payable
Credit Bank
```

---

## Postgres

The relational database engine used by GreyMatter Ledger.

Hosted on Neon.

---

## Profit & Loss

A report showing income and expenses over a period.

Formula:

```txt
Net Profit = Income - Expenses
```

Also called:

```txt
P&L
Income Statement
```

---

## Proxy

In Next.js 16, `proxy.ts` handles request interception.

GreyMatter Ledger uses it to protect routes with Clerk authentication.

---

# R

## RBAC

Role-Based Access Control.

Determines permissions based on roles.

Examples:

```txt
Admin
Member
Viewer
```

GreyMatter Ledger uses admin checks for audit logs and journal reversals.

---

## Reconciliation

See Bank Reconciliation.

---

## Recurring Invoice

A template that can generate invoices on a schedule.

Examples:

```txt
Monthly retainer
Quarterly support contract
Yearly subscription
```

---

## Reversal

A journal entry that cancels another journal entry by swapping debits and credits.

Original:

```txt
Debit Rent Expense
Credit Bank
```

Reversal:

```txt
Debit Bank
Credit Rent Expense
```

---

# S

## Server Action

A Next.js server-side function callable from a form or component.

Used for:

```txt
Creating customers
Creating invoices
Recording payments
Uploading bank CSV
```

---

## Source Document

A business document that explains a journal entry.

Examples:

```txt
Invoice
Bill
Payment
Bank transaction
```

---

## Source Type

A journal entry field that describes where the entry came from.

Examples:

```txt
invoice
bill
customer_payment
vendor_payment
bank_transaction
manual
```

---

# T

## Tailwind CSS

The utility-first CSS framework used for styling GreyMatter Ledger.

---

## Tenant

A customer or organization using the shared application.

In GreyMatter Ledger, each organization is a tenant.

---

## Tenant Isolation

Keeping one tenant’s data separate from another tenant’s data.

Implemented using:

```txt
organization_id
```

---

## TypeScript

JavaScript with static types.

Used throughout GreyMatter Ledger for safer code.

---

# V

## Vercel

The deployment platform used to host the Next.js application.

---

## Vendor

A person or business the company buys from.

Vendors are used for bills and accounts payable.

Stored in:

```txt
vendors
```

---

## Vitest

The test runner used by GreyMatter Ledger.

Run tests with:

```bash
pnpm test
```

---

# Z

## Zero-Rated GST

A GST category where GST is charged at 0%.

The tutorial supports zero GST rates mathematically, but does not fully implement official GST category reporting.

---

# Final Glossary Note

If you are new to accounting, focus first on these terms:

```txt
Account
Debit
Credit
Journal Entry
Journal Line
Chart of Accounts
Accounts Receivable
Accounts Payable
Profit & Loss
Balance Sheet
GST Input Tax
GST Output Tax
```

If you are new to SaaS engineering, focus first on:

```txt
Authentication
Authorization
Organization
Tenant
Tenant Isolation
Server Action
Migration
Audit Log
Background Job
```

Those concepts form the foundation of GreyMatter Ledger.
