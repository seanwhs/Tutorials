# Appendix A: Complete Database Schema Reference

This is the full, authoritative reference for every table in Greymatter Ledger's database — every column, every type, every constraint, every relationship, and why each one exists. Treat this as the master blueprint you return to whenever you extend the app per Part 14's roadmap.

## A.1 — Entity Relationship Overview

```
organizations (1) ──< accounts (self-referencing via parentId)
organizations (1) ──< customers
organizations (1) ──< vendors
organizations (1) ──< journal_entries ──< journal_lines >── accounts
organizations (1) ──< invoices >── customers
invoices (1) ──< invoice_lines
organizations (1) ──< bills >── vendors
bills (1) ──< bill_lines >── accounts (expenseAccountId)
organizations (1) ──< payments >── invoices (nullable)
                                >── bills (nullable)
                                >── accounts (bankAccountId)
organizations (1) ──< recurring_invoice_templates >── customers
organizations (1) ──< imported_transactions >── accounts (categorizedAccountId)

invoices.journalEntryId ──> journal_entries (nullable link back)
bills.journalEntryId ──> journal_entries (nullable link back)
payments.journalEntryId ──> journal_entries (nullable link back)
imported_transactions.journalEntryId ──> journal_entries (nullable link back)
```

Every arrow ending in `journal_entries` is the single point where money is recognized as officially real. Every other table exists either to *produce* a journal entry (invoices, bills, payments, bank imports) or to support the business context around it (customers, vendors, accounts themselves).

---

## A.2 — `organizations`

**Purpose:** Local mirror of Clerk's organization records, so every other table has a real foreign key to attach to (Part 3, Step 3.6).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | The ID every other table actually references |
| `clerkOrgId` | `text` | NOT NULL, UNIQUE | Links back to Clerk; enforces one local row per real company |
| `name` | `text` | NOT NULL | Copied from Clerk at creation time |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Cascade behavior:** every child table uses `onDelete: "cascade"` on its `organizationId` FK — deleting an organization wipes its entire universe of data. There is currently no UI to delete an organization; this exists purely as referential-integrity insurance.

---

## A.3 — `accounts`

**Purpose:** The Chart of Accounts (Part 3 minimal version, extended fully in Part 5).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK → organizations, cascade | Multi-tenancy boundary |
| `code` | `text` | NOT NULL | e.g. `"1000"` — human-facing reference number |
| `name` | `text` | NOT NULL | e.g. `"Cash"` |
| `accountType` | `enum(account_type)` | NOT NULL | `asset`\|`liability`\|`equity`\|`revenue`\|`expense` |
| `normalBalance` | `enum(normal_balance)` | NOT NULL | `debit`\|`credit` — which side increases this account |
| `subtype` | `text` | NOT NULL | e.g. `"bank"`, `"gst_output_tax"` — plain text, not an enum, deliberately (Part 5 reference section) |
| `parentId` | `uuid` | nullable, self-FK via `foreignKey()` | Enables nested account hierarchies |
| `isActive` | `boolean` | NOT NULL, default `true` | Soft-delete flag, never hard-deleted |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Referenced by:** `journal_lines.accountId` (restrict), `bill_lines.expenseAccountId` (restrict), `payments.bankAccountId` (restrict), `imported_transactions.categorizedAccountId` (set null).

**Why `restrict` everywhere except `imported_transactions`:** an account with real historical postings must never be silently deletable (Part 6 reference section) — except the bank-import categorization link, which is allowed to go null if an account is removed, since it's a working-review annotation, not a permanent ledger fact until posted.

### The Seeded Default Chart of Accounts (Part 5.2)

| Code | Name | Type | Normal | Subtype |
|---|---|---|---|---|
| 1000 | Cash | asset | debit | bank |
| 1100 | Accounts Receivable | asset | debit | accounts_receivable |
| 1200 | GST Input Tax Receivable | asset | debit | gst_input_tax |
| 1500 | Office Equipment | asset | debit | fixed_asset |
| 2000 | Accounts Payable | liability | credit | accounts_payable |
| 2100 | GST Output Tax Payable | liability | credit | gst_output_tax |
| 2200 | Unearned Revenue | liability | credit | current_liability |
| 3000 | Owner's Equity | equity | credit | owners_equity |
| 3900 | Retained Earnings | equity | credit | retained_earnings |
| 4000 | Sales Revenue | revenue | credit | operating_revenue |
| 5000 | Cost of Goods Sold | expense | debit | cost_of_goods_sold |
| 5100 | Rent Expense | expense | debit | operating_expense |
| 5200 | Office Supplies Expense | expense | debit | operating_expense |
| 5300 | Software & Subscriptions Expense | expense | debit | operating_expense |
| 5400 | Bank Fees Expense | expense | debit | operating_expense |

---

## A.4 — `journal_entries` and `journal_lines`

**Purpose:** The core ledger — the only place money is ever officially recorded (Part 6).

**`journal_entries`** (the envelope):

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK → organizations, cascade | |
| `entryDate` | `date` | NOT NULL | The date used by every report's period filtering |
| `description` | `text` | NOT NULL | Human-readable summary, e.g. `"Invoice INV-..."` |
| `sourceType` | `text` | NOT NULL, default `"manual"` | `invoice`\|`bill`\|`payment`\|`bank_import`\|`manual` |
| `sourceId` | `uuid` | nullable | Points back to the originating invoice/bill/payment/import row |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**`journal_lines`** (one debit or credit):

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `journalEntryId` | `uuid` | NOT NULL, FK → journal_entries, cascade | |
| `accountId` | `uuid` | NOT NULL, FK → accounts, **restrict** | |
| `debitAmount` | `numeric(14,2)` | NOT NULL, default `0` | Exactly one of debit/credit is nonzero per row |
| `creditAmount` | `numeric(14,2)` | NOT NULL, default `0` | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Invariant enforced entirely in application code (`postJournalEntry`), never at the database constraint level:** for any given `journalEntryId`, `SUM(debitAmount) = SUM(creditAmount)`. No database-level `CHECK` constraint enforces this — it's guaranteed exclusively by the fact that every write path in the entire application passes through `postJournalEntry`, which is why that discipline matters so much (Part 6).

---

## A.5 — `customers` and `vendors`

Structurally identical, deliberately kept as separate tables (Part 7 reference section) since they drive opposite sides of the ledger.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK → organizations, cascade | |
| `name` | `text` | NOT NULL | |
| `email` | `text` | nullable | |
| `address` | `text` | nullable | |
| `isActive` | `boolean` | NOT NULL, default `true` | Soft-delete via "deactivate" |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Referenced by:** `invoices.customerId` (restrict), `bills.vendorId` (restrict), `recurring_invoice_templates.customerId` (restrict).

---

## A.6 — `invoices` and `invoice_lines`

**Purpose:** Accounts Receivable workflow (Part 7).

**`invoices`:**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `customerId` | `uuid` | NOT NULL, FK → customers, **restrict** | |
| `invoiceNumber` | `text` | NOT NULL | `INV-{timestamp}` |
| `issueDate` | `date` | NOT NULL | Drives journal `entryDate` and all reporting |
| `dueDate` | `date` | NOT NULL | Drives AR Aging bucketing |
| `status` | `enum(invoice_status)` | NOT NULL, default `draft` | `draft`\|`sent`\|`partially_paid`\|`paid`\|`overdue`\|`void` |
| `subtotal` | `numeric(14,2)` | NOT NULL | Denormalized sum of lines (pre-GST) |
| `gstTotal` | `numeric(14,2)` | NOT NULL | Denormalized sum of line GST |
| `total` | `numeric(14,2)` | NOT NULL | `subtotal + gstTotal` |
| `amountPaid` | `numeric(14,2)` | NOT NULL, default `0` | Updated by `recordInvoicePayment` |
| `journalEntryId` | `uuid` | FK → journal_entries, **set null** | Traceability link |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**`invoice_lines`:**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `invoiceId` | `uuid` | NOT NULL, FK → invoices, **cascade** | Lines have no meaning without their parent |
| `description` | `text` | NOT NULL | |
| `quantity` | `numeric(10,2)` | NOT NULL | |
| `unitPrice` | `numeric(14,2)` | NOT NULL | |
| `gstRate` | `numeric(5,2)` | NOT NULL, default `9.00` | Per-line, not per-invoice — supports mixed-rate invoices |
| `lineTotal` | `numeric(14,2)` | NOT NULL | `quantity × unitPrice`, denormalized |
| `createdAt` | `timestamp` | NOT NULL  | default now | 

**Journal shape produced by `createInvoice` (Part 7):**

```
Debit  Accounts Receivable (1100)  = total (subtotal + GST)
Credit Sales Revenue (4000)        = subtotal
Credit GST Output Tax Payable (2100) = gstTotal   [only if gstTotal > 0]
```

---

## A.7 — `bills` and `bill_lines`

**Purpose:** Accounts Payable workflow — the structural mirror of invoices, but posting the opposite journal direction (Part 8).

**`bills`:**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `vendorId` | `uuid` | NOT NULL, FK → vendors, **restrict** | |
| `billNumber` | `text` | NOT NULL | `BILL-{timestamp}` |
| `issueDate` | `date` | NOT NULL | |
| `dueDate` | `date` | NOT NULL | Drives AP Aging bucketing |
| `status` | `enum(bill_status)` | NOT NULL, default `received` | `draft`\|`received`\|`partially_paid`\|`paid`\|`overdue`\|`void` |
| `subtotal` | `numeric(14,2)` | NOT NULL | |
| `gstTotal` | `numeric(14,2)` | NOT NULL | |
| `total` | `numeric(14,2)` | NOT NULL | |
| `amountPaid` | `numeric(14,2)` | NOT NULL, default `0` | |
| `journalEntryId` | `uuid` | FK → journal_entries, **set null** | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**`bill_lines`:**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `billId` | `uuid` | NOT NULL, FK → bills, **cascade** | |
| `description` | `text` | NOT NULL | |
| `quantity` | `numeric(10,2)` | NOT NULL | |
| `unitPrice` | `numeric(14,2)` | NOT NULL | |
| `gstRate` | `numeric(5,2)` | NOT NULL, default `9.00` | |
| `lineTotal` | `numeric(14,2)` | NOT NULL | |
| `expenseAccountId` | `uuid` | NOT NULL, FK → accounts, **restrict** | The one structural difference from invoice_lines — each line can target a different expense account |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Journal shape produced by `createBill` (Part 8)** — one debit line *per distinct expense account used*, not a single flat line:

```
Debit  [Expense Account A]           = sum of lines targeting A
Debit  [Expense Account B]           = sum of lines targeting B   [repeated per distinct account]
Debit  GST Input Tax Receivable (1200) = gstTotal   [only if gstTotal > 0]
Credit Accounts Payable (2000)       = total
```

---

## A.8 — `payments`

**Purpose:** A single shared table recording cash movement against *either* an invoice or a bill — never both (Part 8).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `invoiceId` | `uuid` | nullable, FK → invoices, **restrict** | Exactly one of invoiceId/billId is set |
| `billId` | `uuid` | nullable, FK → bills, **restrict** | |
| `amount` | `numeric(14,2)` | NOT NULL | |
| `paymentDate` | `date` | NOT NULL | |
| `method` | `enum(payment_method)` | NOT NULL, default `bank_transfer` | `bank_transfer`\|`cash`\|`credit_card`\|`cheque`\|`other` |
| `bankAccountId` | `uuid` | NOT NULL, FK → accounts, **restrict** | Which Cash/bank account the money moved through |
| `journalEntryId` | `uuid` | FK → journal_entries, **set null** | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Journal shape, invoice payment:**
```
Debit  Cash (1000)                    = amount
Credit Accounts Receivable (1100)     = amount
```

**Journal shape, bill payment:**
```
Debit  Accounts Payable (2000)        = amount
Credit Cash (1000)                    = amount
```

---

## A.9 — `recurring_invoice_templates`

**Purpose:** The "recipe" a scheduled Inngest job reads to auto-generate future invoices (Part 11).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `customerId` | `uuid` | NOT NULL, FK → customers, **restrict** | |
| `interval` | `enum(recurring_interval)` | NOT NULL | `weekly`\|`monthly`\|`quarterly`\|`yearly` |
| `lineItemsJson` | `text` | NOT NULL | JSON-serialized `InvoiceLineInput[]` — deliberately not relational (Part 11 reference section: read-as-a-whole, never queried per-field) |
| `nextRunDate` | `date` | NOT NULL | Advanced by the job itself after each firing — the mechanism that makes the job idempotent |
| `isActive` | `boolean` | NOT NULL, default `true` | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**No direct journal link** — this table never posts anything itself; it only ever calls `createInvoice`, which produces its own standard invoice journal entry (Section A.6 above).

---

## A.10 — `imported_transactions`

**Purpose:** One row per uploaded bank CSV line, tracked through a review lifecycle before ever touching the ledger (Part 12).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `transactionDate` | `date` | NOT NULL | Normalized from the bank's raw date format |
| `description` | `text` | NOT NULL | Raw text from the CSV |
| `amount` | `numeric(14,2)` | NOT NULL | **Signed** — positive = money in, negative = money out (unlike journal_lines' two-column convention) |
| `status` | `enum(imported_transaction_status)` | NOT NULL, default `pending` | `pending`\|`categorized`\|`posted`\|`ignored` |
| `categorizedAccountId` | `uuid` | nullable, FK → accounts, **set null** | User's chosen offsetting account |
| `journalEntryId` | `uuid` | FK → journal_entries, **set null** | Only populated once `status = posted` |
| `duplicateCheckHash` | `text` | NOT NULL | `sha256(date|description|amount)` — prevents re-importing overlapping CSV exports |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Journal shape produced by `postImportedTransaction`** — the sign of `amount` determines which side Cash lands on:

```
If amount >= 0 (money in):
  Debit  Cash (1000)              = |amount|
  Credit [categorizedAccountId]   = |amount|

If amount < 0 (money out):
  Debit  [categorizedAccountId]   = |amount|
  Credit Cash (1000)              = |amount|
```

---

## A.11 — Every Enum, In One Place

| Enum name | Values | Table(s) |
|---|---|---|
| `account_type` | `asset`, `liability`, `equity`, `revenue`, `expense` | `accounts` |
| `normal_balance` | `debit`, `credit` | `accounts` |
| `invoice_status` | `draft`, `sent`, `partially_paid`, `paid`, `overdue`, `void` | `invoices` |
| `bill_status` | `draft`, `received`, `partially_paid`, `paid`, `overdue`, `void` | `bills` |
| `payment_method` | `bank_transfer`, `cash`, `credit_card`, `cheque`, `other` | `payments` |
| `recurring_interval` | `weekly`, `monthly`, `quarterly`, `yearly` | `recurring_invoice_templates` |
| `imported_transaction_status` | `pending`, `categorized`, `posted`, `ignored` | `imported_transactions` |

---

## A.12 — `onDelete` Behavior Cheat Sheet

A quick-reference for the reasoning behind every foreign key's delete behavior (each individually justified in its originating part's reference section):

| Relationship | Behavior | Why |
|---|---|---|
| Any table → `organizations` | `cascade` | Deleting a whole company should remove everything under it |
| `accounts.parentId` → `accounts` | (self-ref, no cascade specified) | Nested account hierarchy |
| `journal_lines.accountId` → `accounts` | `restrict` | Never silently orphan historical postings |
| `invoices.customerId` → `customers` | `restrict` | Never silently erase revenue history |
| `bills.vendorId` → `vendors` | `restrict` | Never silently erase expense history |
| `bill_lines.expenseAccountId` → `accounts` | `restrict` | Same historical-integrity principle |
| `payments.invoiceId` / `.billId` → invoices/bills | `restrict` | Payment history must survive |
| `payments.bankAccountId` → `accounts` | `restrict` | Same |
| `invoice_lines.invoiceId` → `invoices` | `cascade` | Lines have no independent meaning |
| `bill_lines.billId` → `bills` | `cascade` | Same |
| `*.journalEntryId` → `journal_entries` | `set null` | Traceability link only — losing the pointer doesn't corrupt the underlying fact |
| `imported_transactions.categorizedAccountId` → `accounts` | `set null` | Pre-posting annotation, not yet a permanent fact |

**The one-sentence rule underlying every choice above:** once a row represents money that has actually moved (a posted journal line, an invoice with revenue behind it, a bill with expense behind it), the database itself refuses to let you silently delete anything it depends on — matching Part 4 and Part 6's core discipline, enforced structurally, not just by convention.
