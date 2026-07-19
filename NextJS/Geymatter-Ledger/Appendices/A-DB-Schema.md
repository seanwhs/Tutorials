# Appendix A: Database Schema Reference

The definitive reference for every table in Greymatter Ledger's database — the original 14-part course plus all extensions (14.2 through 14.8). Every column, every constraint, every journal shape, every known gap, fully spelled out.

## A.1 — Full Entity Relationship Overview

```
organizations (1) ──< accounts (self-ref via parentId)
organizations (1) ──< customers
organizations (1) ──< vendors
organizations (1) ──< journal_entries ──< journal_lines >── accounts
journal_entries (1) ──< journal_entries (self-ref via reversalOfEntryId)
organizations (1) ──< invoices >── customers
invoices (1) ──< invoice_lines
organizations (1) ──< bills >── vendors
bills (1) ──< bill_lines >── accounts (expenseAccountId)
organizations (1) ──< payments >── invoices/bills (nullable), accounts (bankAccountId)
organizations (1) ──< recurring_invoice_templates >── customers
organizations (1) ──< imported_transactions >── accounts (categorizedAccountId)
organizations (1) ──< reconciliations >── accounts
reconciliations (1) ──< reconciliation_items >── journal_lines
organizations (1) ──< employees
organizations (1) ──< pay_runs >── employees
organizations (1) ──< tax_adjustments
organizations (1) ──< bank_connections >── accounts (linkedAccountId)

invoices.journalEntryId, bills.journalEntryId, payments.journalEntryId,
imported_transactions.journalEntryId, pay_runs.journalEntryId ──> journal_entries
```

Every arrow ending in `journal_entries` is the single point where money is recognized as officially real. This holds across every table below without exception.

---

## A.2 — `organizations`

**Purpose:** Local mirror of Clerk's organization records, so every other table has a real foreign key to attach to.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `clerkOrgId` | `text` | NOT NULL, UNIQUE | Links back to Clerk |
| `name` | `text` | NOT NULL | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Cascade:** every child table's `organizationId` FK uses `onDelete: "cascade"`.

---

## A.3 — `accounts`

**Purpose:** The Chart of Accounts.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK → organizations, cascade | |
| `code` | `text` | NOT NULL | e.g. `"1000"` |
| `name` | `text` | NOT NULL | e.g. `"Cash"` |
| `accountType` | `enum(account_type)` | NOT NULL | `asset`\|`liability`\|`equity`\|`revenue`\|`expense` |
| `normalBalance` | `enum(normal_balance)` | NOT NULL | `debit`\|`credit` |
| `subtype` | `text` | NOT NULL | plain text, not enum |
| `parentId` | `uuid` | nullable, self-FK via `foreignKey()` | |
| `isActive` | `boolean` | NOT NULL, default `true` | Deactivatable via `deactivateAccount`, admin-only |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Referenced by (all restrict, except imported_transactions):** `journal_lines.accountId`, `bill_lines.expenseAccountId`, `payments.bankAccountId`, `reconciliations.accountId`, `bank_connections.linkedAccountId` (all restrict); `imported_transactions.categorizedAccountId` (set null).

### Full Seeded Chart of Accounts

| Code | Name | Type | Normal | Subtype |
|---|---|---|---|---|
| 1000 | Cash | asset | debit | bank |
| 1100 | Accounts Receivable | asset | debit | accounts_receivable |
| 1200 | GST Input Tax Receivable | asset | debit | gst_input_tax |
| 1500 | Office Equipment | asset | debit | fixed_asset |
| 2000 | Accounts Payable | liability | credit | accounts_payable |
| 2100 | GST Output Tax Payable | liability | credit | gst_output_tax |
| 2200 | Unearned Revenue | liability | credit | current_liability |
| 2300 | CPF Payable | liability | credit | cpf_payable |
| 3000 | Owner's Equity | equity | credit | owners_equity |
| 3900 | Retained Earnings | equity | credit | retained_earnings |
| 4000 | Sales Revenue | revenue | credit | operating_revenue |
| 5000 | Cost of Goods Sold | expense | debit | cost_of_goods_sold |
| 5100 | Rent Expense | expense | debit | operating_expense |
| 5200 | Office Supplies Expense | expense | debit | operating_expense |
| 5300 | Software & Subscriptions Expense | expense | debit | operating_expense |
| 5400 | Bank Fees Expense | expense | debit | operating_expense |
| 5500 | Employer CPF Contribution Expense | expense | debit | operating_expense |
| 5600 | Salary Expense | expense | debit | operating_expense |

---

## A.4 — `journal_entries`

**Purpose:** The envelope for one complete financial event — the only place money is officially recognized.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK → organizations, cascade | |
| `entryDate` | `date` | NOT NULL | Drives every report's period filtering |
| `description` | `text` | NOT NULL | e.g. `"Invoice INV-..."` |
| `sourceType` | `text` | NOT NULL, default `"manual"` | `invoice`\|`bill`\|`payment`\|`bank_import`\|`manual`\|`void_reversal`\|`payroll` |
| `sourceId` | `uuid` | nullable | Points back to the originating record |
| `isVoided` | `boolean` | NOT NULL, default `false` | True once reversed; original never edited/deleted |
| `voidedAt` | `timestamp` | nullable | |
| `reversalOfEntryId` | `uuid` | nullable, self-FK via `foreignKey()` | If this entry IS a reversal, points to the original |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Invariant, enforced entirely in application code, never a database CHECK constraint:** for any given `journalEntryId`, `SUM(debitAmount) = SUM(creditAmount)`. Guaranteed exclusively because every write path passes through `postJournalEntry`.

**Second invariant:** an entry is never deleted or edited once posted. The only mutation ever applied to an already-posted entry is flipping `isVoided`/`voidedAt`. Reversal is always additive — a brand-new row — never destructive.

---

## A.5 — `journal_lines`

**Purpose:** One single debit or credit within a journal entry.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `journalEntryId` | `uuid` | NOT NULL, FK → journal_entries, cascade | |
| `accountId` | `uuid` | NOT NULL, FK → accounts, **restrict** | Never silently orphan a historical posting |
| `debitAmount` | `numeric(14,2)` | NOT NULL, default `0` | **SGD** — the only figure the balance check reads |
| `creditAmount` | `numeric(14,2)` | NOT NULL, default `0` | **SGD** |
| `originalCurrency` | `text` | NOT NULL, default `"SGD"` | ISO 4217 code of the original transaction |
| `originalDebitAmount` | `numeric(14,2)` | NOT NULL, default `0` | Amount in the original currency |
| `originalCreditAmount` | `numeric(14,2)` | NOT NULL, default `0` | |
| `exchangeRateToSgd` | `numeric(12,6)` | NOT NULL, default `1.000000` | Rate in effect on the transaction date, permanently stored |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Confirmed invariant:** `postJournalEntry`'s balance check operates exclusively on `debitAmount`/`creditAmount` (SGD). The four original guard clauses — minimum line count, no hybrid debit+credit line, debits equal credits, every account belongs to the calling organization — are entirely unaffected by the currency columns, which exist purely as descriptive metadata.

### Journal Shapes By `sourceType`

| sourceType | Shape |
|---|---|
| `invoice` | Debit Accounts Receivable (total) / Credit Sales Revenue (subtotal) / Credit GST Output Tax Payable (gstTotal, if any) |
| `bill` | Debit each distinct Expense account used / Debit GST Input Tax Receivable (if any) / Credit Accounts Payable (total) |
| `payment` (invoice) | Debit Cash / Credit Accounts Receivable |
| `payment` (bill) | Debit Accounts Payable / Credit Cash |
| `bank_import` | If amount ≥ 0: Debit Cash / Credit categorized account. If amount < 0: Debit categorized account / Credit Cash |
| `void_reversal` | Exact mirror (debit↔credit swapped) of whatever entry it reverses |
| `payroll` | Debit Salary Expense (gross wage) / Debit Employer CPF Contribution Expense / Credit Cash (net pay) / Credit CPF Payable (total CPF) |
| `manual` | Free-form, any valid balanced combination |

---

## A.6 — `customers`

**Purpose:** Who the business invoices — drives Accounts Receivable.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `name` | `text` | NOT NULL | |
| `email` | `text` | nullable | |
| `address` | `text` | nullable | |
| `isActive` | `boolean` | NOT NULL, default `true` | Soft-delete via "deactivate" |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Referenced by:** `invoices.customerId` (restrict), `recurring_invoice_templates.customerId` (restrict).

---

## A.7 — `vendors`

**Purpose:** Who bills the business — drives Accounts Payable. Structurally identical to `customers`.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `name` | `text` | NOT NULL | |
| `email` | `text` | nullable | |
| `address` | `text` | nullable | |
| `isActive` | `boolean` | NOT NULL, default `true` | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Referenced by:** `bills.vendorId` (restrict).

---

## A.8 — `invoices`

**Purpose:** The Accounts Receivable header — one bill sent to one customer.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `customerId` | `uuid` | NOT NULL, FK → customers, **restrict** | |
| `invoiceNumber` | `text` | NOT NULL | `INV-{timestamp}` |
| `issueDate` | `date` | NOT NULL | Drives journal `entryDate` and all reporting |
| `dueDate` | `date` | NOT NULL | Drives AR Aging bucketing |
| `status` | `enum(invoice_status)` | NOT NULL, default `draft` | `draft`\|`sent`\|`partially_paid`\|`paid`\|`overdue`\|`void` |
| `subtotal` | `numeric(14,2)` | NOT NULL | Denormalized sum of lines, in the invoice's own currency |
| `gstTotal` | `numeric(14,2)` | NOT NULL | |
| `total` | `numeric(14,2)` | NOT NULL | `subtotal + gstTotal` |
| `amountPaid` | `numeric(14,2)` | NOT NULL, default `0` | Also gates voiding — must be `0` before `voidInvoice` will run |
| `currency` | `text` | NOT NULL, default `"SGD"` | The currency the invoice was actually issued/displayed in |
| `exchangeRateToSgd` | `numeric(12,6)` | NOT NULL, default `1.000000` | Rate used to convert to SGD when posted to the ledger |
| `journalEntryId` | `uuid` | FK → journal_entries, **set null** | Traceability link |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Relations:** `customer` (one), `lines` (many `invoice_lines`), `payments` (many `payments`).

---

## A.9 — `invoice_lines`

**Purpose:** Individual billable items within one invoice.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `invoiceId` | `uuid` | NOT NULL, FK → invoices, **cascade** | Lines have no meaning without their parent |
| `description` | `text` | NOT NULL | |
| `quantity` | `numeric(10,2)` | NOT NULL | |
| `unitPrice` | `numeric(14,2)` | NOT NULL | In the invoice's own currency |
| `gstRate` | `numeric(5,2)` | NOT NULL, default `9.00` | Per-line, supports mixed-rate invoices |
| `lineTotal` | `numeric(14,2)` | NOT NULL | `quantity × unitPrice`, denormalized |
| `createdAt` | `timestamp` | NOT NULL, default now | |

---

## A.10 — `bills`

**Purpose:** The Accounts Payable header — the mirror of invoices.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `vendorId` | `uuid` | NOT NULL, FK → vendors, **restrict** | |
| `billNumber` | `text` | NOT NULL | `BILL-{timestamp}` |
| `issueDate` | `date` | NOT NULL | |
| `dueDate` | `date` | NOT NULL | Drives AP Aging bucketing |
| `status` | `enum(bill_status)` | NOT NULL, default `received` | `draft`\|`received`\|`partially_paid`\|`paid`\|`overdue`\|`void` |
| `subtotal` | `numeric(14,2)` | NOT NULL | |
| `gstTotal` | `numeric(14,2)` | NOT NULL | |
| `total` | `numeric(14,2)` | NOT NULL | |
| `amountPaid` | `numeric(14,2)` | NOT NULL, default `0` | Also gates voiding |
| `currency` | `text` | NOT NULL, default `"SGD"` | |
| `exchangeRateToSgd` | `numeric(12,6)` | NOT NULL, default `1.000000` | |
| `journalEntryId` | `uuid` | FK → journal_entries, **set null** | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Relations:** `vendor` (one), `lines` (many `bill_lines`), `payments` (many `payments`).

---

## A.11 — `bill_lines`

**Purpose:** Individual expense items within one bill.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `billId` | `uuid` | NOT NULL, FK → bills, **cascade** | |
| `description` | `text` | NOT NULL | |
| `quantity` | `numeric(10,2)` | NOT NULL | |
| `unitPrice` | `numeric(14,2)` | NOT NULL | |
| `gstRate` | `numeric(5,2)` | NOT NULL, default `9.00` | |
| `lineTotal` | `numeric(14,2)` | NOT NULL | |
| `expenseAccountId` | `uuid` | NOT NULL, FK → accounts, **restrict** | Each line can target a different expense account |
| `createdAt` | `timestamp` | NOT NULL, default now | |

---

## A.12 — `payments`

**Purpose:** A single shared table recording cash movement against either an invoice or a bill — never both on the same row.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `invoiceId` | `uuid` | nullable, FK → invoices, **restrict** | Exactly one of invoiceId/billId is set |
| `billId` | `uuid` | nullable, FK → bills, **restrict** | |
| `amount` | `numeric(14,2)` | NOT NULL | |
| `paymentDate` | `date` | NOT NULL | |
| `method` | `enum(payment_method)` | NOT NULL, default `bank_transfer` | `bank_transfer`\|`cash`\|`credit_card`\|`cheque`\|`other` |
| `bankAccountId` | `uuid` | NOT NULL, FK → accounts, **restrict** | Which Cash account the money moved through |
| `journalEntryId` | `uuid` | FK → journal_entries, **set null** | |
| `isVoided` | `boolean` | NOT NULL, default `false` | A voided payment is never deleted, only flagged |
| `voidedAt` | `timestamp` | nullable | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**`voidPayment`:** reverses the Cash↔AR/AP entry, then recomputes the parent invoice's/bill's `amountPaid` and `status` **from scratch** (never a naive decrement), all inside one transaction alongside marking this row `isVoided`.

---

## A.13 — `recurring_invoice_templates`

**Purpose:** The "recipe" a scheduled Inngest job reads to auto-generate future invoices.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `customerId` | `uuid` | NOT NULL, FK → customers, **restrict** | |
| `interval` | `enum(recurring_interval)` | NOT NULL | `weekly`\|`monthly`\|`quarterly`\|`yearly` |
| `lineItemsJson` | `text` | NOT NULL | JSON-serialized line items — read-as-a-whole, never queried per-field, so kept as JSON rather than a relational table |
| `nextRunDate` | `date` | NOT NULL | Advanced by the job itself after each firing — makes the job idempotent |
| `isActive` | `boolean` | NOT NULL, default `true` | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

No direct journal link — invoices it generates get their own standard invoice journal entry, independently voidable afterward like any other invoice.

---

## A.14 — `imported_transactions`

**Purpose:** One row per bank transaction awaiting review, whether it arrived via CSV upload (Part 12) or a live feed sync (Part 14.8) — both write into this exact same table.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `transactionDate` | `date` | NOT NULL | Normalized to `YYYY-MM-DD` regardless of source |
| `description` | `text` | NOT NULL | Raw text from the CSV or feed |
| `amount` | `numeric(14,2)` | NOT NULL | Signed — positive = money in, negative = money out |
| `status` | `enum(imported_transaction_status)` | NOT NULL, default `pending` | `pending`\|`categorized`\|`posted`\|`ignored` |
| `categorizedAccountId` | `uuid` | nullable, FK → accounts, **set null** | User's chosen offsetting account |
| `journalEntryId` | `uuid` | FK → journal_entries, **set null** | Only populated once `status = posted` |
| `duplicateCheckHash` | `text` | NOT NULL | `sha256(date|description|amount)` — prevents duplicate rows regardless of source |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**⚠️ Known gap:** no `void` value exists in `imported_transaction_status`, and no `voidImportedTransaction()` function exists. A posted bank-import entry can be reversed at the ledger level via `voidJournalEntry` directly, but this row's own `status` would remain stale at `posted`, out of sync with the ledger's true state.

---

## A.15 — `reconciliations`

**Purpose:** One completed (or in-progress) bank reconciliation session for a specific account, as of a specific date.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `accountId` | `uuid` | NOT NULL, FK → accounts, **restrict** | Which Cash/bank account this session covers |
| `asOfDate` | `date` | NOT NULL | |
| `statementEndingBalance` | `numeric(14,2)` | NOT NULL | The bank's own stated balance — external source of truth |
| `ledgerBalance` | `numeric(14,2)` | NOT NULL | The ledger's computed Cash balance at completion time, captured permanently |
| `isComplete` | `boolean` | NOT NULL, default `false` | |
| `completedAt` | `timestamp` | nullable | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Completion guard:** `completeReconciliation` recomputes the checked-off total from actual line amounts server-side and refuses to complete unless it matches `statementEndingBalance` within 1 cent — never trusts a client-supplied total.

## A.16 — `reconciliation_items`

**Purpose:** Records which specific `journal_lines` rows were checked off as part of one reconciliation session — so it's always possible to answer "was this specific transaction ever reconciled, and in which session?"

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `reconciliationId` | `uuid` | NOT NULL, FK → reconciliations, **cascade** | Items have no meaning without their parent session |
| `journalLineId` | `uuid` | NOT NULL, FK → journal_lines, **restrict** | Never silently orphan the reconciliation record from the line it references |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Exclusion rule:** any `journalLineId` that appears in a `reconciliation_items` row is permanently excluded from ever being offered again in a future reconciliation session for that account — enforced by `getUnreconciledCashLines`'s exclusion query, which is what makes "closing the book" on a period actually mean something.

---

## A.17 — `employees`

**Purpose:** A minimal payroll roster — who gets paid, and at what CPF rates.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `name` | `text` | NOT NULL | |
| `monthlyWage` | `numeric(14,2)` | NOT NULL | |
| `employeeCpfRate` | `numeric(5,2)` | NOT NULL, default `20.00` | Simplified flat rate — not IRAS's real age-banded tables |
| `employerCpfRate` | `numeric(5,2)` | NOT NULL, default `17.00` | Same caveat |
| `isActive` | `boolean` | NOT NULL, default `true` | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**⚠️ Explicit limitation:** rates are entered per-employee as a flat percentage, not derived from IRAS's actual age-banded contribution tables, which change periodically. A real payroll product must source current rates directly from IRAS/CPF Board, not from a hardcoded course default.

---

## A.18 — `pay_runs`

**Purpose:** One payroll cycle for one employee, and the journal entry it produced.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `employeeId` | `uuid` | NOT NULL, FK → employees, **restrict** | |
| `payDate` | `date` | NOT NULL | |
| `grossWage` | `numeric(14,2)` | NOT NULL | |
| `employeeCpfAmount` | `numeric(14,2)` | NOT NULL | Withheld from the employee's own pay |
| `employerCpfAmount` | `numeric(14,2)` | NOT NULL | Paid entirely by the employer, on top of wage |
| `netPay` | `numeric(14,2)` | NOT NULL | `grossWage − employeeCpfAmount` — actual cash paid out |
| `journalEntryId` | `uuid` | FK → journal_entries, **set null** | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Admin-gated:** `runPayroll` requires admin role, checked as the first line, before any read or write — same trust tier as voiding.

---

## A.19 — `tax_adjustments`

**Purpose:** A separate worksheet of manually-entered tax-law adjustments per fiscal year, kept deliberately outside the ledger — these never get posted as journal entries, since they represent tax-law reclassifications of numbers the ledger already correctly recorded, not real cash movements.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `fiscalYearStart` | `date` | NOT NULL | |
| `fiscalYearEnd` | `date` | NOT NULL | |
| `adjustmentType` | `enum(tax_adjustment_type)` | NOT NULL | `add_back_non_deductible`\|`capital_allowance`\|`other_deduction` |
| `description` | `text` | NOT NULL | |
| `amount` | `numeric(14,2)` | NOT NULL | |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**Admin-gated:** `addTaxAdjustment` requires admin role — these figures directly affect a number a business might file with IRAS.

**⚠️ Explicit limitation:** the resulting tax estimate uses a flat 17% rate only, excluding IRAS's partial tax exemption scheme's tiered calculation and any loss carry-forward mechanics — an internal estimate only, never a substitute for a real tax computation.

---

## A.20 — `bank_connections`

**Purpose:** Records that an organization has authorized a live, ongoing connection to a specific real bank account via an aggregator (Brankas, Finverse, or similar) — the stretch-goal feature, feeding into the exact same `imported_transactions` table CSV import already uses.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default random | |
| `organizationId` | `uuid` | NOT NULL, FK, cascade | |
| `linkedAccountId` | `uuid` | NOT NULL, FK → accounts, **restrict** | Which internal Cash account this feed posts against |
| `provider` | `text` | NOT NULL | e.g. `"brankas"`, `"finverse"` |
| `providerAccountId` | `text` | NOT NULL | The aggregator's own ID for this bank account |
| `accessToken` | `text` | NOT NULL | ⚠️ Stored as plain text in this course's implementation — a real deployment MUST encrypt this at the application layer before storage; this course does not build an encryption-at-rest layer |
| `status` | `enum(bank_connection_status)` | NOT NULL, default `active` | `active`\|`requires_reauth`\|`disconnected` |
| `lastSyncedAt` | `timestamp` | nullable | Used to compute the "since" date for the next sync |
| `createdAt` | `timestamp` | NOT NULL, default now | |

**⚠️ Explicit limitation, stated plainly:** this table and its sync job are illustrative scaffolding, not a production-ready integration. Real endpoint shapes, authentication flows (OAuth token refresh), and webhook signature verification all require the aggregator's actual, current API documentation and were only sketched here, not fully built — consistent with Part 14.8's status as a stretch goal, explicitly not recommended until a concrete business need exists.

---

## A.21 — Every Enum, In One Place

| Enum name | Values | Table(s) |
|---|---|---|
| `account_type` | `asset`, `liability`, `equity`, `revenue`, `expense` | `accounts` |
| `normal_balance` | `debit`, `credit` | `accounts` |
| `invoice_status` | `draft`, `sent`, `partially_paid`, `paid`, `overdue`, `void` | `invoices` |
| `bill_status` | `draft`, `received`, `partially_paid`, `paid`, `overdue`, `void` | `bills` |
| `payment_method` | `bank_transfer`, `cash`, `credit_card`, `cheque`, `other` | `payments` |
| `recurring_interval` | `weekly`, `monthly`, `quarterly`, `yearly` | `recurring_invoice_templates` |
| `imported_transaction_status` | `pending`, `categorized`, `posted`, `ignored` | `imported_transactions` (no `void` value — known gap) |
| `tax_adjustment_type` | `add_back_non_deductible`, `capital_allowance`, `other_deduction` | `tax_adjustments` |
| `bank_connection_status` | `active`, `requires_reauth`, `disconnected` | `bank_connections` |

`journal_entries.sourceType` remains a plain `text` column, not an enum — this is why `"void_reversal"` and `"payroll"` could be added as new values with zero schema migration, only new application-code strings.

---

## A.22 — `onDelete` Behavior, Every Relationship

| Relationship | Behavior | Why |
|---|---|---|
| Any table → `organizations` | `cascade` | Deleting a whole company removes everything under it |
| `accounts.parentId` → `accounts` | self-ref, no cascade | Nested account hierarchy |
| `journal_entries.reversalOfEntryId` → `journal_entries` | self-ref, no cascade | Neither side of a reversal pair is ever deleted |
| `journal_lines.accountId` → `accounts` | `restrict` | Never orphan a historical posting |
| `invoices.customerId` → `customers` | `restrict` | Never erase revenue history |
| `bills.vendorId` → `vendors` | `restrict` | Never erase expense history |
| `bill_lines.expenseAccountId` → `accounts` | `restrict` | Same |
| `payments.invoiceId` / `.billId` → invoices/bills | `restrict` | Payment history must survive |
| `payments.bankAccountId` → `accounts` | `restrict` | Same |
| `invoice_lines.invoiceId` → `invoices` | `cascade` | Lines have no independent meaning |
| `bill_lines.billId` → `bills` | `cascade` | Same |
| `reconciliations.accountId` → `accounts` | `restrict` | Same historical-integrity principle |
| `reconciliation_items.reconciliationId` → `reconciliations` | `cascade` | Items have no meaning without their session |
| `reconciliation_items.journalLineId` → `journal_lines` | `restrict` | Never orphan the reconciliation record |
| `employees` → `organizations` | `cascade` | Standard tenancy boundary |
| `pay_runs.employeeId` → `employees` | `restrict` | Payroll history must survive |
| `bank_connections.linkedAccountId` → `accounts` | `restrict` | Same |
| `*.journalEntryId` → `journal_entries` | `set null` | Traceability link only, not a permanent-fact dependency |
| `imported_transactions.categorizedAccountId` → `accounts` | `set null` | Pre-posting annotation only |

**The rule underlying every choice above, holding across all 20 tables:** once a row represents money that has actually moved, the database refuses to let you silently delete anything it depends on — and reversing a transaction is itself implemented as an addition to the ledger, never a deletion or in-place edit of what came before.

---

## A.23 — Known Gaps (Complete List)

1. **No void state for `imported_transactions`** — a posted bank-import entry can be reversed at the ledger level directly, but its own `status` column has no `void` value and stays stale at `posted`.
2. **`bank_connections.accessToken` stored as plain text** — a real deployment must add application-layer encryption before this table ever holds a genuine credential.
3. **`bank_connections` sync job is illustrative** — real endpoint shapes, OAuth refresh flows, and webhook verification require the actual aggregator's current documentation.
4. **Multi-currency payments have no FX gain/loss recognition** — paying a foreign-currency invoice with SGD cash (or vice versa) when the exchange rate has moved is not modeled; payments must be entered already-converted to SGD.
5. **Tax estimate excludes IRAS's partial tax exemption scheme and loss carry-forwards** — the flat 17% calculation is a simplified illustrative figure only, not a real tax computation.
6. **CPF rates are flat per-employee entries, not IRAS's real age-banded tables** — a real payroll product must source current rates directly from IRAS/CPF Board rather than a hardcoded default.

None of these six gaps require a third-party service to close, and each was called out explicitly at the point it was introduced rather than glossed over — consistent with the honesty principle this appendix has followed throughout: every simplification is a stated, deliberate scope boundary, not an accidental omission.
