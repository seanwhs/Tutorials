# Appendix B — Database Schema Reference

This appendix documents the final database schema built throughout the GreyMatter Ledger tutorial series.

The goal is to give you a high-level map of the database:

```txt
What tables exist?
What each table represents?
How tables relate to each other?
Which columns are important?
Which tables are tenant-scoped?
```

GreyMatter Ledger uses:

```txt
Neon Postgres
Drizzle ORM
TypeScript schema definitions
```

The primary schema file is:

```txt
db/schema.ts
```

The generated SQL migrations live in:

```txt
drizzle/
```

---

# 1. Database Design Principles

GreyMatter Ledger follows several key database principles.

---

## 1.1 Tenant Isolation

Most business data belongs to one organization.

That means most tables include:

```txt
organization_id
```

This keeps Company A’s records separate from Company B’s records.

Examples:

```txt
accounts.organization_id
customers.organization_id
vendors.organization_id
invoices.organization_id
journal_entries.organization_id
journal_lines.organization_id
```

A normal application query should almost always filter by the active organization.

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

This is one of the most important rules in the app.

---

## 1.2 Journal Lines Are the Accounting Source of Truth

Business documents explain what happened.

The ledger records the accounting truth.

Business documents include:

```txt
invoices
bills
customer_payments
vendor_payments
bank_transactions
```

Accounting truth lives in:

```txt
journal_entries
journal_lines
```

Reports should be based primarily on:

```txt
journal_lines
```

joined to:

```txt
journal_entries
accounts
```

---

## 1.3 Money Is Stored as Integer Cents

GreyMatter Ledger stores money as integer cents.

Examples:

```txt
S$100.00 = 10000
S$9.00   = 900
S$109.00 = 10900
```

This avoids floating-point rounding bugs.

Most amount columns end with:

```txt
_cents
```

Examples:

```txt
total_cents
gst_cents
debit_cents
credit_cents
amount_cents
```

---

## 1.4 Posted Accounting History Is Not Casually Deleted

Posted journal entries are corrected through reversals, not edits or deletes.

Relevant columns:

```txt
journal_entries.is_reversed
journal_entries.reversed_at
journal_entries.reversal_reason
journal_entries.reversed_by_journal_entry_id
journal_entries.reverses_journal_entry_id
```

---

## 1.5 Database Constraints Protect Critical Rules

Some rules are enforced directly by the database.

Examples:

```txt
journal_lines.debit_cents >= 0
journal_lines.credit_cents >= 0
journal line must have exactly one side
invoice total = subtotal + GST
bill total = subtotal + GST
payment amount > 0
account code unique per organization
```

The journal entry-level balance rule:

```txt
total debits = total credits
```

is enforced in the service layer because it requires summing multiple lines.

---

# 2. Table Overview

The final schema includes these major table groups:

```txt
Identity / tenancy:
  organizations

Accounting foundation:
  accounts

Ledger:
  journal_entries
  journal_lines

Contacts:
  customers
  vendors

Sales:
  invoices
  invoice_lines
  customer_payments
  recurring_invoices

Purchases:
  bills
  bill_lines
  vendor_payments

Bank:
  bank_imports
  bank_transactions

Audit:
  audit_logs
```

---

# 3. Entity Relationship Overview

A simplified relationship map:

```txt
organizations
  |
  |-- accounts
  |
  |-- customers
  |     |
  |     |-- invoices
  |           |
  |           |-- invoice_lines
  |           |-- customer_payments
  |
  |-- vendors
  |     |
  |     |-- bills
  |           |
  |           |-- bill_lines
  |           |-- vendor_payments
  |
  |-- journal_entries
  |     |
  |     |-- journal_lines
  |           |
  |           |-- accounts
  |
  |-- bank_imports
  |     |
  |     |-- bank_transactions
  |
  |-- recurring_invoices
  |
  |-- audit_logs
```

---

# 4. Enums

The schema uses several Postgres enums.

---

## 4.1 `account_type`

Used by:

```txt
accounts.type
```

Values:

```txt
asset
liability
equity
income
expense
```

Purpose:

Determines account behavior and reporting category.

---

## 4.2 `journal_source_type`

Used by:

```txt
journal_entries.source_type
```

Values:

```txt
manual
invoice
bill
customer_payment
vendor_payment
bank_transaction
system
```

Purpose:

Identifies where a journal entry came from.

---

## 4.3 `invoice_status`

Used by:

```txt
invoices.status
```

Values:

```txt
draft
sent
paid
void
```

Purpose:

Tracks invoice workflow state.

---

## 4.4 `bill_status`

Used by:

```txt
bills.status
```

Values:

```txt
draft
received
paid
void
```

Purpose:

Tracks bill workflow state.

---

## 4.5 `bank_transaction_status`

Used by:

```txt
bank_transactions.status
```

Values:

```txt
imported
categorized
posted
reconciled
ignored
```

Purpose:

Tracks bank import workflow state.

---

## 4.6 `audit_action`

Used by:

```txt
audit_logs.action
```

Values include:

```txt
account.created
account.status_changed
customer.created
vendor.created
invoice.created
bill.created
customer_payment.recorded
vendor_payment.recorded
journal_entry.reversed
```

Purpose:

Classifies audit log events.

---

## 4.7 `recurring_frequency`

Used by:

```txt
recurring_invoices.frequency
```

Values:

```txt
monthly
quarterly
yearly
```

Purpose:

Determines how often recurring invoices generate.

---

# 5. `organizations`

## Purpose

Stores the local database representation of a Clerk organization.

Clerk is the identity provider.

The local database organization is the tenant anchor for accounting records.

---

## Important Columns

```txt
id
clerk_organization_id
name
slug
image_url
created_at
updated_at
```

---

## Key Rules

```txt
clerk_organization_id is unique
```

Each Clerk organization maps to one local organization.

---

## Relationships

One organization has many:

```txt
accounts
customers
vendors
invoices
bills
journal_entries
journal_lines
audit_logs
bank_imports
bank_transactions
```

---

# 6. `accounts`

## Purpose

Stores the chart of accounts for each organization.

Every journal line points to one account.

---

## Important Columns

```txt
id
organization_id
code
name
type
description
is_system
is_active
created_at
updated_at
```

---

## Key Rules

Account codes are unique per organization:

```txt
organization_id + code
```

This allows:

```txt
Company A: 1000 Bank
Company B: 1000 Bank
```

But prevents:

```txt
Company A: 1000 Bank
Company A: 1000 Operating Bank
```

---

## Account Type Values

```txt
asset
liability
equity
income
expense
```

---

## Important Seeded Accounts

```txt
1000 Bank
1100 Accounts Receivable
1400 GST Input Tax
2000 Accounts Payable
2110 GST Output Tax
3000 Share Capital
4000 Sales Revenue
5100 Purchases
6300 Software and Subscriptions
```

---

# 7. `journal_entries`

## Purpose

Stores the header record for each posted accounting event.

A journal entry groups multiple journal lines.

---

## Important Columns

```txt
id
organization_id
entry_date
memo
source_type
source_id
posted_by_user_id
is_reversed
reversed_at
reversal_reason
reversed_by_journal_entry_id
reverses_journal_entry_id
created_at
updated_at
```

---

## Source Types

```txt
manual
invoice
bill
customer_payment
vendor_payment
bank_transaction
system
```

---

## Reversal Columns

```txt
is_reversed
```

Whether this original entry has been reversed.

```txt
reversed_at
```

When it was reversed.

```txt
reversal_reason
```

Why it was reversed.

```txt
reversed_by_journal_entry_id
```

The journal entry that reversed this one.

```txt
reverses_journal_entry_id
```

If this entry is itself a reversal, this points to the original entry.

---

## Relationships

One journal entry has many:

```txt
journal_lines
```

---

# 8. `journal_lines`

## Purpose

Stores debit and credit lines inside journal entries.

This is the core accounting data used by reports.

---

## Important Columns

```txt
id
journal_entry_id
organization_id
account_id
line_number
description
debit_cents
credit_cents
created_at
```

---

## Key Rules

Debit cannot be negative:

```txt
debit_cents >= 0
```

Credit cannot be negative:

```txt
credit_cents >= 0
```

Each line must have exactly one side:

```txt
(debit_cents > 0 and credit_cents = 0)
or
(credit_cents > 0 and debit_cents = 0)
```

Line numbers are unique within a journal entry:

```txt
journal_entry_id + line_number
```

---

## Reporting Importance

Most reports are built from:

```txt
journal_lines
```

joined to:

```txt
journal_entries
accounts
```

---

# 9. `customers`

## Purpose

Stores customers for each organization.

Customers are people or businesses that buy from the company.

---

## Important Columns

```txt
id
organization_id
name
email
phone
billing_address
notes
is_active
created_at
updated_at
```

---

## Used By

```txt
invoices
customer_payments
```

---

# 10. `vendors`

## Purpose

Stores vendors for each organization.

Vendors are people or businesses the company buys from.

---

## Important Columns

```txt
id
organization_id
name
email
phone
billing_address
notes
is_active
created_at
updated_at
```

---

## Used By

```txt
bills
vendor_payments
```

---

# 11. `invoices`

## Purpose

Stores customer invoices.

An invoice is a business document saying a customer owes the company money.

---

## Important Columns

```txt
id
organization_id
customer_id
invoice_number
issue_date
due_date
status
subtotal_cents
gst_cents
total_cents
notes
journal_entry_id
currency
exchange_rate_basis_points
foreign_total_cents
created_at
updated_at
```

---

## Status Values

```txt
draft
sent
paid
void
```

---

## Key Rules

Invoice number is unique per organization:

```txt
organization_id + invoice_number
```

Totals must match:

```txt
total_cents = subtotal_cents + gst_cents
```

Amounts cannot be negative:

```txt
subtotal_cents >= 0
gst_cents >= 0
total_cents >= 0
```

---

## Accounting Posting

Invoice creation posts:

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

The invoice stores the linked journal entry:

```txt
journal_entry_id
```

---

# 12. `invoice_lines`

## Purpose

Stores line items for invoices.

---

## Important Columns

```txt
id
invoice_id
organization_id
line_number
description
quantity
unit_amount_cents
subtotal_cents
gst_rate_basis_points
gst_cents
total_cents
created_at
```

---

## Key Rules

Quantity must be positive:

```txt
quantity > 0
```

Totals must match:

```txt
total_cents = subtotal_cents + gst_cents
```

Line numbers are unique per invoice:

```txt
invoice_id + line_number
```

---

# 13. `customer_payments`

## Purpose

Stores payments received from customers against invoices.

---

## Important Columns

```txt
id
organization_id
customer_id
invoice_id
payment_date
amount_cents
reference
journal_entry_id
created_at
updated_at
```

---

## Key Rules

Payment amount must be positive:

```txt
amount_cents > 0
```

---

## Accounting Posting

Customer payment posts:

```txt
Debit  Bank
Credit Accounts Receivable
```

Then the invoice status becomes:

```txt
paid
```

---

# 14. `bills`

## Purpose

Stores vendor bills.

A bill is a business document saying the company owes a vendor money.

---

## Important Columns

```txt
id
organization_id
vendor_id
bill_number
issue_date
due_date
status
subtotal_cents
gst_cents
total_cents
notes
journal_entry_id
currency
exchange_rate_basis_points
foreign_total_cents
created_at
updated_at
```

---

## Status Values

```txt
draft
received
paid
void
```

---

## Key Rules

Bill number is unique per organization:

```txt
organization_id + bill_number
```

Totals must match:

```txt
total_cents = subtotal_cents + gst_cents
```

---

## Accounting Posting

Bill creation posts:

```txt
Debit  Purchases
Debit  GST Input Tax
Credit Accounts Payable
```

The bill stores the linked journal entry:

```txt
journal_entry_id
```

---

# 15. `bill_lines`

## Purpose

Stores line items for bills.

---

## Important Columns

```txt
id
bill_id
organization_id
line_number
description
quantity
unit_amount_cents
subtotal_cents
gst_rate_basis_points
gst_cents
total_cents
created_at
```

---

## Key Rules

Quantity must be positive:

```txt
quantity > 0
```

Totals must match:

```txt
total_cents = subtotal_cents + gst_cents
```

Line numbers are unique per bill:

```txt
bill_id + line_number
```

---

# 16. `vendor_payments`

## Purpose

Stores payments made to vendors against bills.

---

## Important Columns

```txt
id
organization_id
vendor_id
bill_id
payment_date
amount_cents
reference
journal_entry_id
created_at
updated_at
```

---

## Key Rules

Payment amount must be positive:

```txt
amount_cents > 0
```

---

## Accounting Posting

Vendor payment posts:

```txt
Debit  Accounts Payable
Credit Bank
```

Then the bill status becomes:

```txt
paid
```

---

# 17. `bank_imports`

## Purpose

Stores one uploaded bank CSV import.

---

## Important Columns

```txt
id
organization_id
file_name
row_count
created_at
```

---

## Relationships

One bank import has many:

```txt
bank_transactions
```

---

# 18. `bank_transactions`

## Purpose

Stores imported bank statement rows.

---

## Important Columns

```txt
id
organization_id
bank_import_id
transaction_date
description
amount_cents
status
category_account_id
categorization_notes
journal_entry_id
reconciled_at
reconciled_by_user_id
created_at
```

---

## Status Values

```txt
imported
categorized
posted
reconciled
ignored
```

---

## Bank Posting Logic

Positive amount:

```txt
Debit  Bank
Credit Category Account
```

Negative amount:

```txt
Debit  Category Account
Credit Bank
```

---

## Reconciliation

Once reconciled:

```txt
status = reconciled
reconciled_at is not null
```

Reconciled transactions should be locked from casual changes.

---

# 19. `audit_logs`

## Purpose

Stores operational audit events.

Examples:

```txt
customer.created
invoice.created
bill.created
customer_payment.recorded
vendor_payment.recorded
journal_entry.reversed
```

---

## Important Columns

```txt
id
organization_id
actor_user_id
action
entity_type
entity_id
message
metadata_json
created_at
```

---

## Audit vs Journal

The journal records accounting effects.

The audit log records operational activity.

Example:

```txt
Journal:
Debit AR
Credit Revenue
Credit GST Output Tax

Audit:
User created invoice INV-2026-0001
```

Both are useful, but they answer different questions.

---

# 20. `recurring_invoices`

## Purpose

Stores recurring invoice templates.

A recurring invoice profile is not itself an invoice.

It is an instruction for creating future invoices.

---

## Important Columns

```txt
id
organization_id
customer_id
description
quantity
unit_amount_cents
gst_rate_basis_points
frequency
next_run_date
is_active
last_generated_invoice_id
created_at
updated_at
```

---

## Frequency Values

```txt
monthly
quarterly
yearly
```

---

## Used By

Recurring invoice generation workflow.

---

# 21. Multi-Currency Fields

Invoices and bills include foundational multi-currency fields:

```txt
currency
exchange_rate_basis_points
foreign_total_cents
```

---

## Base Currency

GreyMatter Ledger’s base currency is:

```txt
SGD
```

Journal entries and reports are still in SGD cents.

---

## Foreign Currency Metadata

For a foreign currency document:

```txt
currency = USD
foreign_total_cents = 10000
exchange_rate_basis_points = 13500
total_cents = 13500
```

This means:

```txt
USD 100.00 at 1.35 = SGD 135.00
```

The tutorial adds the foundation, not a full FX revaluation engine.

---

# 22. Common Query Patterns

## Get Current Organization Accounts

```ts
await db
  .select()
  .from(accounts)
  .where(eq(accounts.organizationId, organization.id));
```

---

## Get Invoice List

```ts
await db
  .select()
  .from(invoices)
  .where(eq(invoices.organizationId, organization.id));
```

---

## Get Journal Lines for Reports

```ts
await db
  .select()
  .from(journalLines)
  .innerJoin(accounts, eq(journalLines.accountId, accounts.id))
  .innerJoin(journalEntries, eq(journalLines.journalEntryId, journalEntries.id))
  .where(eq(journalLines.organizationId, organization.id));
```

---

## Check Journal Entry Balance

SQL:

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

Expected result:

```txt
0 rows
```

---

# 23. Important Indexes

The schema includes indexes for common access patterns.

Examples:

```txt
organizations_clerk_organization_id_idx
accounts_organization_id_code_idx
journal_entries_organization_id_entry_date_idx
journal_lines_organization_id_account_id_idx
invoices_organization_id_invoice_number_idx
bills_organization_id_bill_number_idx
bank_transactions_organization_id_status_idx
audit_logs_organization_id_created_at_idx
```

These help with:

```txt
tenant filtering
date-based reports
account lookups
document number uniqueness
audit history
bank workflow status filtering
```

---

# 24. Tables That Should Be Tenant-Scoped

These tables must always be treated as organization-scoped:

```txt
accounts
customers
vendors
invoices
invoice_lines
customer_payments
bills
bill_lines
vendor_payments
journal_entries
journal_lines
bank_imports
bank_transactions
audit_logs
recurring_invoices
```

The key column:

```txt
organization_id
```

---

# 25. Schema Verification Queries

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

## List Constraints

```sql
select
  conname as constraint_name,
  conrelid::regclass as table_name,
  pg_get_constraintdef(oid) as definition
from pg_constraint
where connamespace = 'public'::regnamespace
order by table_name, constraint_name;
```

---

# 26. Final Mental Model

If you remember only one database idea, remember this:

```txt
Business documents explain events.
Journal entries record accounting truth.
Reports summarize journal lines.
Organization IDs protect tenant boundaries.
```

In diagram form:

```txt
organizations
  |
  |-- source documents
  |     |-- invoices
  |     |-- bills
  |     |-- payments
  |     |-- bank transactions
  |
  |-- ledger
        |-- journal_entries
        |-- journal_lines
              |-- accounts
```

That is the database heart of GreyMatter Ledger.
