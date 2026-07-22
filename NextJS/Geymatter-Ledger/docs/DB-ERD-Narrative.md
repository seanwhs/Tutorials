# Database ERD Narrative

**Product:** GreyMatter Ledger  
**Document type:** Database ERD Narrative  
**Version:** 1.0  
**Status:** Draft  
**Audience:** Developers, database designers, technical reviewers, QA engineers, architects  
**Database:** PostgreSQL via Neon  
**ORM:** Drizzle ORM  
**Primary schema file:** `db/schema.ts`  

---

# 1. Purpose

This document explains the GreyMatter Ledger database as an **Entity Relationship Diagram narrative**.

Instead of presenting a visual ERD image, this document describes:

```txt
Entities
Relationships
Cardinality
Ownership
Foreign keys
Tenant boundaries
Accounting flow
```

It is meant to help readers understand how the tables fit together.

---

# 2. High-Level ERD Summary

At the highest level:

```txt
Organization owns everything.
Accounts define the chart of accounts.
Journal entries and journal lines form the ledger.
Customers connect to invoices and customer payments.
Vendors connect to bills and vendor payments.
Bank imports connect to bank transactions.
Source documents link to journal entries.
Reports read journal lines.
Audit logs record operational actions.
```

Simplified map:

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

# 3. Central Tenant Entity: `organizations`

The root entity is:

```txt
organizations
```

Every company workspace has one local organization row.

Most business records belong to one organization.

Relationship:

```txt
organizations 1 -> many accounts
organizations 1 -> many customers
organizations 1 -> many vendors
organizations 1 -> many invoices
organizations 1 -> many bills
organizations 1 -> many journal_entries
organizations 1 -> many journal_lines
organizations 1 -> many audit_logs
organizations 1 -> many bank_imports
organizations 1 -> many bank_transactions
organizations 1 -> many recurring_invoices
```

This is the tenant boundary.

The most important column is:

```txt
organization_id
```

---

# 4. Organization and Clerk Relationship

Clerk manages identity-side organizations.

The local database stores:

```txt
organizations.clerk_organization_id
```

Relationship:

```txt
Clerk organization 1 -> 1 local database organization
```

In database terms:

```txt
organizations.clerk_organization_id unique
```

This allows the app to map:

```txt
Clerk orgId -> local organization id
```

---

# 5. Chart of Accounts Relationship

The table:

```txt
accounts
```

belongs to:

```txt
organizations
```

Relationship:

```txt
organizations 1 -> many accounts
```

Each account belongs to one organization.

Each journal line references one account.

Relationship:

```txt
accounts 1 -> many journal_lines
```

Cardinality:

```txt
One account can appear in many journal lines.
One journal line references exactly one account.
```

---

# 6. Ledger Relationship

The ledger uses:

```txt
journal_entries
journal_lines
```

Relationship:

```txt
journal_entries 1 -> many journal_lines
```

Each journal line belongs to one journal entry.

Each journal line references one account.

```txt
journal_lines many -> 1 accounts
```

Each journal entry belongs to one organization.

Each journal line also belongs to one organization.

This duplicated `organization_id` on journal lines helps report queries.

---

# 7. Why `journal_lines` Has `organization_id`

At first glance, this may seem redundant:

```txt
journal_entries.organization_id
journal_lines.organization_id
```

But reports query journal lines heavily.

Having `organization_id` directly on `journal_lines` allows:

```txt
Fast tenant filtering
Safer report queries
Simpler indexing
```

Relationship integrity should ensure:

```txt
journal_lines.organization_id = journal_entries.organization_id
```

---

# 8. Customer Sales Relationships

Customers are stored in:

```txt
customers
```

Relationship:

```txt
organizations 1 -> many customers
customers 1 -> many invoices
customers 1 -> many customer_payments
```

An invoice belongs to one customer.

A customer can have many invoices.

```txt
customers 1 -> many invoices
```

A customer payment belongs to one customer and one invoice.

```txt
customers 1 -> many customer_payments
invoices 1 -> many customer_payments
```

In the current tutorial, only full payments are supported, so practically there is one payment per invoice, but the schema can support multiple payment rows if expanded.

---

# 9. Invoice Relationships

Invoices use two tables:

```txt
invoices
invoice_lines
```

Relationships:

```txt
organizations 1 -> many invoices
customers 1 -> many invoices
invoices 1 -> many invoice_lines
invoices many -> 0/1 journal_entries
```

An invoice has one or more invoice lines.

An invoice may link to one journal entry:

```txt
invoices.journal_entry_id -> journal_entries.id
```

This relationship connects the business document to accounting truth.

---

# 10. Invoice Posting Relationship

When an invoice is posted:

```txt
invoices
  |
  v
journal_entries
  |
  v
journal_lines
```

Example accounting:

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

Relationship:

```txt
invoices.journal_entry_id references journal_entries.id
```

This lets the invoice detail page show its journal entry.

---

# 11. Customer Payment Relationships

Customer payments are stored in:

```txt
customer_payments
```

Relationships:

```txt
organizations 1 -> many customer_payments
customers 1 -> many customer_payments
invoices 1 -> many customer_payments
customer_payments many -> 0/1 journal_entries
```

A customer payment links to the invoice it pays.

It also links to the journal entry that records:

```txt
Debit Bank
Credit Accounts Receivable
```

---

# 12. Vendor Purchase Relationships

Vendors are stored in:

```txt
vendors
```

Relationship:

```txt
organizations 1 -> many vendors
vendors 1 -> many bills
vendors 1 -> many vendor_payments
```

A vendor can have many bills.

A vendor can have many payments.

---

# 13. Bill Relationships

Bills use two tables:

```txt
bills
bill_lines
```

Relationships:

```txt
organizations 1 -> many bills
vendors 1 -> many bills
bills 1 -> many bill_lines
bills many -> 0/1 journal_entries
```

A bill may link to a journal entry:

```txt
bills.journal_entry_id -> journal_entries.id
```

---

# 14. Bill Posting Relationship

When a bill is posted:

```txt
bills
  |
  v
journal_entries
  |
  v
journal_lines
```

Example accounting:

```txt
Debit  Purchases
Debit  GST Input Tax
Credit Accounts Payable
```

The bill detail page uses this relationship to show the linked journal entry.

---

# 15. Vendor Payment Relationships

Vendor payments are stored in:

```txt
vendor_payments
```

Relationships:

```txt
organizations 1 -> many vendor_payments
vendors 1 -> many vendor_payments
bills 1 -> many vendor_payments
vendor_payments many -> 0/1 journal_entries
```

A vendor payment links to the bill it pays.

It also links to the journal entry that records:

```txt
Debit Accounts Payable
Credit Bank
```

---

# 16. Bank Import Relationships

Bank imports are stored in:

```txt
bank_imports
```

Imported rows are stored in:

```txt
bank_transactions
```

Relationship:

```txt
organizations 1 -> many bank_imports
bank_imports 1 -> many bank_transactions
organizations 1 -> many bank_transactions
```

Each bank transaction belongs to:

```txt
one bank import
one organization
```

---

# 17. Bank Transaction Categorization Relationship

A bank transaction may reference a category account:

```txt
bank_transactions.category_account_id -> accounts.id
```

Relationship:

```txt
accounts 1 -> many bank_transactions as category account
```

The category account is used when posting the bank transaction to the ledger.

---

# 18. Bank Transaction Posting Relationship

A posted bank transaction links to a journal entry:

```txt
bank_transactions.journal_entry_id -> journal_entries.id
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

Relationship:

```txt
bank_transactions many -> 0/1 journal_entries
```

---

# 19. Bank Reconciliation Relationship

Reconciliation fields live on:

```txt
bank_transactions
```

Important fields:

```txt
status
reconciled_at
reconciled_by_user_id
```

A reconciled bank transaction is not a new entity in this version.

It is a status transition on the bank transaction row.

---

# 20. Audit Log Relationships

Audit logs are stored in:

```txt
audit_logs
```

Relationship:

```txt
organizations 1 -> many audit_logs
```

Audit logs can reference many different entity types.

Instead of hard foreign keys to every table, audit logs store:

```txt
entity_type
entity_id
```

Example:

```txt
entity_type = invoice
entity_id = invoices.id
```

This is a polymorphic reference pattern.

---

# 21. Why Audit Logs Use Polymorphic References

Audit logs need to record many types of actions:

```txt
customer.created
invoice.created
bill.created
journal_entry.reversed
```

Creating a separate nullable foreign key for every possible entity would be awkward.

So the audit log stores:

```txt
entity_type
entity_id
```

This is flexible.

Tradeoff:

```txt
Database does not enforce every entity reference with foreign keys.
Application logic must write correct values.
```

---

# 22. Recurring Invoice Relationships

Recurring invoice profiles are stored in:

```txt
recurring_invoices
```

Relationships:

```txt
organizations 1 -> many recurring_invoices
customers 1 -> many recurring_invoices
recurring_invoices many -> 0/1 invoices as last_generated_invoice
```

A recurring invoice profile is a template.

It can generate invoices over time.

It may store:

```txt
last_generated_invoice_id
```

to track the latest generated invoice.

---

# 23. Source Document to Journal Relationship Summary

Many source documents link to journal entries:

```txt
invoices.journal_entry_id
bills.journal_entry_id
customer_payments.journal_entry_id
vendor_payments.journal_entry_id
bank_transactions.journal_entry_id
```

This pattern means:

```txt
The source document explains the business event.
The journal entry records the accounting effect.
```

---

# 24. Journal Source Type Relationship

`journal_entries.source_type` identifies the originating workflow.

Examples:

```txt
invoice
bill
customer_payment
vendor_payment
bank_transaction
manual
system
```

`journal_entries.source_id` stores the source document ID.

This is another polymorphic reference pattern.

Example:

```txt
source_type = invoice
source_id = invoices.id
```

---

# 25. Why Journal Source Is Polymorphic

Many tables can create journal entries.

Instead of separate columns like:

```txt
invoice_id
bill_id
payment_id
bank_transaction_id
```

the journal entry stores:

```txt
source_type
source_id
```

This keeps the journal table flexible.

Tradeoff:

```txt
Database does not enforce source_id target table directly.
Application logic must maintain correctness.
```

---

# 26. Reversal Relationships

Journal entries can reference other journal entries for reversals.

Fields:

```txt
reversed_by_journal_entry_id
reverses_journal_entry_id
```

Relationship concept:

```txt
Original journal entry 1 -> 0/1 reversal journal entry
Reversal journal entry many -> 1 original journal entry
```

In tutorial implementation, these are UUID references without explicit self-referential foreign keys.

Application logic enforces reversal relationships.

---

# 27. Entity Ownership Summary

| Entity | Owned By |
|---|---|
| Account | Organization |
| Customer | Organization |
| Vendor | Organization |
| Invoice | Organization, Customer |
| Invoice Line | Organization, Invoice |
| Customer Payment | Organization, Customer, Invoice |
| Bill | Organization, Vendor |
| Bill Line | Organization, Bill |
| Vendor Payment | Organization, Vendor, Bill |
| Journal Entry | Organization |
| Journal Line | Organization, Journal Entry, Account |
| Bank Import | Organization |
| Bank Transaction | Organization, Bank Import |
| Audit Log | Organization |
| Recurring Invoice | Organization, Customer |

---

# 28. Cardinality Summary

```txt
Organization 1 -> many Accounts
Organization 1 -> many Customers
Organization 1 -> many Vendors
Organization 1 -> many Invoices
Organization 1 -> many Bills
Organization 1 -> many Journal Entries
Organization 1 -> many Journal Lines
Organization 1 -> many Bank Imports
Organization 1 -> many Bank Transactions
Organization 1 -> many Audit Logs

Customer 1 -> many Invoices
Invoice 1 -> many Invoice Lines
Invoice 1 -> many Customer Payments

Vendor 1 -> many Bills
Bill 1 -> many Bill Lines
Bill 1 -> many Vendor Payments

Journal Entry 1 -> many Journal Lines
Account 1 -> many Journal Lines

Bank Import 1 -> many Bank Transactions
```

---

# 29. Tenant Isolation in the ERD

Most relationships are scoped within the same organization.

Examples that should always be true:

```txt
invoice.organization_id = customer.organization_id
bill.organization_id = vendor.organization_id
journal_line.organization_id = journal_entry.organization_id
journal_line.organization_id = account.organization_id
invoice_line.organization_id = invoice.organization_id
bill_line.organization_id = bill.organization_id
```

These should be verified through service logic and optional SQL checks.

---

# 30. Integrity Verification Queries

## Invoice Customer Organization Mismatch

Expected:

```txt
0 rows
```

```sql
select
  i.id,
  i.organization_id as invoice_org,
  c.organization_id as customer_org
from invoices i
join customers c
  on c.id = i.customer_id
where i.organization_id <> c.organization_id;
```

---

## Bill Vendor Organization Mismatch

Expected:

```txt
0 rows
```

```sql
select
  b.id,
  b.organization_id as bill_org,
  v.organization_id as vendor_org
from bills b
join vendors v
  on v.id = b.vendor_id
where b.organization_id <> v.organization_id;
```

---

## Journal Line Account Organization Mismatch

Expected:

```txt
0 rows
```

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

---

## Journal Line Entry Organization Mismatch

Expected:

```txt
0 rows
```

```sql
select
  jl.id,
  jl.organization_id as line_org,
  je.organization_id as entry_org
from journal_lines jl
join journal_entries je
  on je.id = jl.journal_entry_id
where jl.organization_id <> je.organization_id;
```

---

# 31. Accounting Integrity Query

Every journal entry should balance.

Expected:

```txt
0 rows
```

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

---

# 32. ERD Design Tradeoffs

## 32.1 Duplicating `organization_id` on Line Tables

Examples:

```txt
journal_lines.organization_id
invoice_lines.organization_id
bill_lines.organization_id
```

Benefit:

```txt
Easier tenant filtering
Faster reporting
Simpler diagnostics
```

Tradeoff:

```txt
Application must ensure line organization matches parent organization.
```

---

## 32.2 Polymorphic `source_type` and `source_id`

Benefit:

```txt
Flexible journal source tracking
```

Tradeoff:

```txt
Database does not enforce exact target table.
```

---

## 32.3 Polymorphic Audit Entity References

Benefit:

```txt
One audit log table can track many entity types.
```

Tradeoff:

```txt
Database does not enforce every entity_id target.
```

---

## 32.4 Source Document + Journal Entry Separation

Benefit:

```txt
Business document detail remains distinct from accounting effect.
```

Tradeoff:

```txt
Services must keep them linked.
```

---

# 33. Future ERD Enhancements

Potential future entities:

```txt
credit_notes
credit_note_lines
tax_codes
accounting_periods
attachments
invoice_email_events
payment_allocations
bank_reconciliation_statements
exchange_rates
employees
payroll_runs
inventory_items
inventory_movements
approval_requests
```

---

# 34. Final ERD Mental Model

The ERD can be understood in three layers:

```txt
Tenant Layer:
  organizations

Business Layer:
  customers
  vendors
  invoices
  bills
  payments
  bank transactions
  recurring invoices

Accounting Layer:
  accounts
  journal_entries
  journal_lines
```

The bridge between the business layer and accounting layer is:

```txt
journal_entry_id
```

The bridge between every layer and tenant isolation is:

```txt
organization_id
```

The most important relationship:

```txt
journal_lines -> accounts
```

because reports depend on that connection.

Final rule:

```txt
Source documents tell the story.
Journal entries record the accounting.
Organization IDs keep companies separate.
```
