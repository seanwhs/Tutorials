# Appendix C — Journal Engine Reference

This appendix documents the core journal engine used by **GreyMatter Ledger**.

The journal engine is the heart of the accounting system.

Its most important job is simple:

```txt
Never allow an unbalanced journal entry to be posted.
```

In code, that means:

```ts
totalDebitCents === totalCreditCents
```

If that is false, the entry must be rejected.

---

# 1. Why the Journal Engine Matters

In GreyMatter Ledger, many business workflows eventually create journal entries:

```txt
Invoice creation
Bill creation
Customer payment
Vendor payment
Bank transaction posting
Manual journal entry
Reversal
Recurring invoice generation
```

These workflows may look different in the user interface, but they all need the same accounting protection:

```txt
Total debits must equal total credits.
```

So instead of rewriting accounting rules everywhere, the application centralizes posting logic in the journal engine.

The central service is:

```txt
services/journal/post-journal-entry.ts
```

The core function is:

```ts
postJournalEntry()
```

The validation module is:

```txt
services/journal/validate-post-journal-entry.ts
```

The validator function is:

```ts
validatePostJournalEntryInput()
```

---

# 2. The Journal Tables

The journal engine writes to two main tables:

```txt
journal_entries
journal_lines
```

---

## `journal_entries`

This is the header table.

It stores:

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

A journal entry represents one accounting event.

Example:

```txt
Invoice INV-2026-0001 issued to Merlion Trading
```

---

## `journal_lines`

This is the detail table.

It stores:

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

A journal line represents one debit or one credit to one account.

Example:

```txt
Debit Accounts Receivable S$109.00
```

---

# 3. Journal Entry Shape

The journal engine accepts an input similar to this:

```ts
await postJournalEntry({
  entryDate: "2026-01-05",
  memo: "Invoice INV-2026-0001 issued to Merlion Trading",
  sourceType: "invoice",
  sourceId: "invoice-uuid-here",
  lines: [
    {
      accountId: accountsReceivableAccountId,
      description: "Customer receivable",
      debitCents: 10900,
      creditCents: 0,
    },
    {
      accountId: salesRevenueAccountId,
      description: "Sales revenue before GST",
      debitCents: 0,
      creditCents: 10000,
    },
    {
      accountId: gstOutputTaxAccountId,
      description: "GST collected",
      debitCents: 0,
      creditCents: 900,
    },
  ],
});
```

The entry above is valid because:

```txt
Total debits  = 10900
Total credits = 10000 + 900 = 10900
```

---

# 4. Source Types

Journal entries can come from different workflows.

The supported `sourceType` values are:

```txt
manual
invoice
bill
customer_payment
vendor_payment
bank_transaction
system
```

These come from the database enum:

```ts
journalSourceTypeEnum
```

Source type helps answer:

```txt
Why does this journal entry exist?
```

Examples:

```txt
source_type = invoice
source_id = invoices.id

source_type = bill
source_id = bills.id

source_type = customer_payment
source_id = customer_payments.id

source_type = bank_transaction
source_id = bank_transactions.id
```

---

# 5. Validation Rules

The journal engine validates several layers of rules.

---

## 5.1 Active Organization Required

A journal entry must belong to the active organization.

The engine does **not** trust an organization ID from the browser.

Instead, it uses server-side organization context:

```ts
const organization = await requireCurrentDatabaseOrganization();
```

This protects multi-tenant data.

Bad pattern:

```ts
await postJournalEntry({
  organizationIdFromForm,
  ...
});
```

Better pattern:

```ts
const organization = await requireCurrentDatabaseOrganization();
```

---

## 5.2 Valid Date Required

The date must be a real date in this format:

```txt
YYYY-MM-DD
```

Valid:

```txt
2026-01-31
```

Invalid:

```txt
31/01/2026
2026-02-31
not-a-date
```

The validator prevents JavaScript date normalization from accepting impossible dates.

Example:

```ts
isValidJournalDateString("2026-02-31");
```

returns:

```txt
false
```

---

## 5.3 Memo Required

Every journal entry must have a memo.

Valid:

```txt
Invoice INV-2026-0001 issued to Merlion Trading
```

Invalid:

```txt
""
"   "
```

The memo explains the purpose of the entry.

---

## 5.4 At Least Two Lines Required

A journal entry must have at least two lines.

Why?

Because double-entry accounting requires at least two sides.

Invalid:

```txt
Debit Bank S$100
```

Valid:

```txt
Debit Bank S$100
Credit Sales Revenue S$100
```

---

## 5.5 Each Line Must Reference an Account

Every line must include:

```txt
accountId
```

The account ID must be a valid UUID.

The engine later verifies that the account:

```txt
exists
belongs to the active organization
is active
```

---

## 5.6 Amounts Must Be Integer Cents

Debits and credits must be integer cents.

Valid:

```ts
debitCents: 10900
creditCents: 0
```

Invalid:

```ts
debitCents: 109.00
creditCents: 0
```

Invalid:

```ts
debitCents: 100.5
```

Money must be stored as integer cents.

---

## 5.7 Amounts Cannot Be Negative

Invalid:

```ts
debitCents: -100
```

Invalid:

```ts
creditCents: -100
```

To reverse direction, use the opposite side.

Wrong:

```txt
Debit Bank -S$100
```

Correct:

```txt
Credit Bank S$100
```

---

## 5.8 A Line Must Have Exactly One Side

Valid:

```ts
{
  debitCents: 10000,
  creditCents: 0,
}
```

Valid:

```ts
{
  debitCents: 0,
  creditCents: 10000,
}
```

Invalid:

```ts
{
  debitCents: 10000,
  creditCents: 10000,
}
```

Invalid:

```ts
{
  debitCents: 0,
  creditCents: 0,
}
```

A line cannot be both a debit and a credit.

A line also cannot be neither.

---

## 5.9 Total Debits Must Equal Total Credits

This is the central invariant.

Valid:

```txt
Debit  Bank           S$100
Credit Sales Revenue  S$100
```

Invalid:

```txt
Debit  Bank           S$100
Credit Sales Revenue  S$90
```

The validator calculates:

```ts
totalDebitCents
totalCreditCents
```

and rejects when:

```ts
totalDebitCents !== totalCreditCents
```

---

## 5.10 Total Must Be Greater Than Zero

Invalid:

```txt
Debit total = 0
Credit total = 0
```

An entry with no value should not be posted.

---

## 5.11 Accounts Must Belong to Active Organization

The journal engine loads accounts using:

```ts
eq(accounts.organizationId, organization.id)
```

This prevents cross-tenant posting.

Company A cannot post journal lines to Company B’s accounts.

---

## 5.12 Accounts Must Be Active

Inactive accounts cannot be used for new postings.

This allows historical accounts to remain visible while preventing new transactions.

If an account is inactive, the engine rejects the entry.

---

# 6. Validation Function

The pure validation function is:

```ts
validatePostJournalEntryInput()
```

Location:

```txt
services/journal/validate-post-journal-entry.ts
```

It does not call:

```txt
Clerk
Database
Network
```

That makes it easy to test.

Example:

```ts
const validation = validatePostJournalEntryInput({
  entryDate: "2026-01-01",
  memo: "Owner contributes cash",
  lines: [
    {
      accountId: bankAccountId,
      debitCents: 1000000,
      creditCents: 0,
    },
    {
      accountId: shareCapitalAccountId,
      debitCents: 0,
      creditCents: 1000000,
    },
  ],
});
```

Expected:

```ts
validation.issues.length === 0
validation.totalDebitCents === 1000000
validation.totalCreditCents === 1000000
```

---

# 7. Validation Result Shape

The validation result looks like this:

```ts
type JournalInputValidationResult = {
  normalizedInput: NormalizedJournalEntryInput;
  totalDebitCents: number;
  totalCreditCents: number;
  issues: string[];
};
```

If the entry is valid:

```ts
issues: []
```

If invalid:

```ts
issues: [
  "Journal entry is unbalanced: debits total 10000 cents but credits total 9000 cents."
]
```

---

# 8. Custom Validation Error

Validation failures throw:

```ts
JournalEntryValidationError
```

Location:

```txt
services/journal/journal-errors.ts
```

Shape:

```ts
export class JournalEntryValidationError extends Error {
  readonly issues: string[];
}
```

This allows server actions to show friendly messages.

Example:

```ts
try {
  await postJournalEntry(input);
} catch (error) {
  if (isJournalEntryValidationError(error)) {
    return error.issues;
  }

  throw error;
}
```

---

# 9. `postJournalEntry()` Flow

The production posting flow is:

```txt
postJournalEntry()
  |
  |-- require active organization
  |-- read current Clerk user ID
  |-- validate input shape
  |-- reject validation issues
  |-- collect distinct account IDs
  |-- begin database transaction
        |
        |-- load accounts for active organization
        |-- verify all accounts exist
        |-- verify all accounts active
        |-- insert journal entry
        |-- insert journal lines
  |
  |-- return created entry and lines
```

---

# 10. Transactional Write

The journal engine writes using a database transaction.

This matters because we must never allow:

```txt
journal_entries row inserted
but only some journal_lines inserted
```

The write must be all-or-nothing.

Either:

```txt
Entry and all lines are saved.
```

or:

```txt
Nothing is saved.
```

---

# 11. Valid Examples

## 11.1 Owner Contribution

Scenario:

```txt
Owner contributes S$10,000 cash.
```

Entry:

```txt
Debit  Bank            S$10,000
Credit Share Capital   S$10,000
```

Input shape:

```ts
await postJournalEntry({
  entryDate: "2026-01-01",
  memo: "Owner contributes startup cash",
  sourceType: "manual",
  lines: [
    {
      accountId: bankAccountId,
      debitCents: 1000000,
      creditCents: 0,
    },
    {
      accountId: shareCapitalAccountId,
      debitCents: 0,
      creditCents: 1000000,
    },
  ],
});
```

---

## 11.2 GST Invoice

Scenario:

```txt
Invoice for S$109 including 9% GST.
```

Entry:

```txt
Debit  Accounts Receivable   S$109
Credit Sales Revenue         S$100
Credit GST Output Tax        S$9
```

Input shape:

```ts
await postJournalEntry({
  entryDate: "2026-01-05",
  memo: "Invoice INV-2026-0001 issued to Merlion Trading",
  sourceType: "invoice",
  sourceId: invoiceId,
  lines: [
    {
      accountId: accountsReceivableAccountId,
      debitCents: 10900,
      creditCents: 0,
    },
    {
      accountId: salesRevenueAccountId,
      debitCents: 0,
      creditCents: 10000,
    },
    {
      accountId: gstOutputTaxAccountId,
      debitCents: 0,
      creditCents: 900,
    },
  ],
});
```

---

## 11.3 Customer Payment

Scenario:

```txt
Customer pays S$109 invoice.
```

Entry:

```txt
Debit  Bank                  S$109
Credit Accounts Receivable   S$109
```

Input shape:

```ts
await postJournalEntry({
  entryDate: "2026-01-12",
  memo: "Payment received for invoice INV-2026-0001",
  sourceType: "customer_payment",
  sourceId: paymentId,
  lines: [
    {
      accountId: bankAccountId,
      debitCents: 10900,
      creditCents: 0,
    },
    {
      accountId: accountsReceivableAccountId,
      debitCents: 0,
      creditCents: 10900,
    },
  ],
});
```

---

## 11.4 Vendor Bill

Scenario:

```txt
Vendor bill for S$109 including 9% GST.
```

Entry:

```txt
Debit  Purchases             S$100
Debit  GST Input Tax         S$9
Credit Accounts Payable      S$109
```

Input shape:

```ts
await postJournalEntry({
  entryDate: "2026-01-20",
  memo: "Bill BILL-2026-0001 received from Cloud Hosting SG",
  sourceType: "bill",
  sourceId: billId,
  lines: [
    {
      accountId: purchasesAccountId,
      debitCents: 10000,
      creditCents: 0,
    },
    {
      accountId: gstInputTaxAccountId,
      debitCents: 900,
      creditCents: 0,
    },
    {
      accountId: accountsPayableAccountId,
      debitCents: 0,
      creditCents: 10900,
    },
  ],
});
```

---

## 11.5 Vendor Payment

Scenario:

```txt
Pay S$109 vendor bill.
```

Entry:

```txt
Debit  Accounts Payable   S$109
Credit Bank               S$109
```

Input shape:

```ts
await postJournalEntry({
  entryDate: "2026-01-25",
  memo: "Payment made for bill BILL-2026-0001",
  sourceType: "vendor_payment",
  sourceId: vendorPaymentId,
  lines: [
    {
      accountId: accountsPayableAccountId,
      debitCents: 10900,
      creditCents: 0,
    },
    {
      accountId: bankAccountId,
      debitCents: 0,
      creditCents: 10900,
    },
  ],
});
```

---

## 11.6 Bank Import Inflow

Scenario:

```txt
Imported bank row: +S$250
```

Entry:

```txt
Debit  Bank              S$250
Credit Category Account  S$250
```

Input shape:

```ts
await postJournalEntry({
  entryDate: "2026-02-01",
  memo: "Bank transaction posted: Customer receipt",
  sourceType: "bank_transaction",
  sourceId: bankTransactionId,
  lines: [
    {
      accountId: bankAccountId,
      debitCents: 25000,
      creditCents: 0,
    },
    {
      accountId: categoryAccountId,
      debitCents: 0,
      creditCents: 25000,
    },
  ],
});
```

---

## 11.7 Bank Import Outflow

Scenario:

```txt
Imported bank row: -S$25.50
```

Entry:

```txt
Debit  Category Account  S$25.50
Credit Bank              S$25.50
```

Input shape:

```ts
await postJournalEntry({
  entryDate: "2026-02-02",
  memo: "Bank transaction posted: Bank charge",
  sourceType: "bank_transaction",
  sourceId: bankTransactionId,
  lines: [
    {
      accountId: categoryAccountId,
      debitCents: 2550,
      creditCents: 0,
    },
    {
      accountId: bankAccountId,
      debitCents: 0,
      creditCents: 2550,
    },
  ],
});
```

---

# 12. Invalid Examples

## 12.1 Unbalanced Entry

Invalid:

```ts
await postJournalEntry({
  entryDate: "2026-01-01",
  memo: "Bad entry",
  lines: [
    {
      accountId: bankAccountId,
      debitCents: 10000,
      creditCents: 0,
    },
    {
      accountId: revenueAccountId,
      debitCents: 0,
      creditCents: 9000,
    },
  ],
});
```

Reason:

```txt
Debits = 10000
Credits = 9000
```

Rejected.

---

## 12.2 Both Debit and Credit on Same Line

Invalid:

```ts
{
  accountId: bankAccountId,
  debitCents: 10000,
  creditCents: 10000,
}
```

Reason:

```txt
A line cannot have both debit and credit amounts.
```

Rejected.

---

## 12.3 Zero Line

Invalid:

```ts
{
  accountId: bankAccountId,
  debitCents: 0,
  creditCents: 0,
}
```

Reason:

```txt
A line must have either a debit or credit amount.
```

Rejected.

---

## 12.4 Negative Amount

Invalid:

```ts
{
  accountId: bankAccountId,
  debitCents: -10000,
  creditCents: 0,
}
```

Reason:

```txt
Debit cannot be negative.
```

Rejected.

---

## 12.5 Inactive Account

Invalid if account is inactive:

```ts
{
  accountId: inactiveAccountId,
  debitCents: 10000,
  creditCents: 0,
}
```

Reason:

```txt
Inactive accounts cannot be used for new postings.
```

Rejected.

---

## 12.6 Cross-Tenant Account

Invalid if account belongs to another organization:

```ts
{
  accountId: otherCompanyAccountId,
  debitCents: 10000,
  creditCents: 0,
}
```

Reason:

```txt
Account does not exist for the active organization.
```

Rejected.

---

# 13. Reversals

A reversal cancels a posted journal entry by swapping every debit and credit.

Original:

```txt
Debit  Rent Expense   S$500
Credit Bank           S$500
```

Reversal:

```txt
Debit  Bank           S$500
Credit Rent Expense   S$500
```

The reversal service is:

```txt
services/journal/reverse-journal-entry.ts
```

Function:

```ts
reverseJournalEntryForCurrentOrganization()
```

---

## Reversal Rules

The reversal service:

```txt
Requires active organization
Requires admin permission
Rejects already reversed entries
Rejects reversing reversal entries in tutorial flow
Loads original lines
Swaps debits and credits
Creates reversal entry
Marks original as reversed
Links both entries
Writes audit log
```

---

# 14. Manual Test Harness

Manual journal engine testing page:

```txt
/settings/database/journal/manual-test
```

It tests:

```txt
Owner contribution
GST invoice
Invalid unbalanced entry
```

Expected behavior:

```txt
Valid entries post.
Invalid entry is rejected.
Invalid entry does not create database rows.
```

---

# 15. Automated Tests

Journal validation tests live in:

```txt
tests/journal-validation.test.ts
```

Journal error tests live in:

```txt
tests/journal-errors.test.ts
```

Run tests:

```bash
pnpm test
```

Run full health check:

```bash
pnpm check
```

---

# 16. SQL Verification Queries

## Check Every Journal Entry Balances

```sql
select
  je.id,
  je.memo,
  sum(jl.debit_cents) as total_debit_cents,
  sum(jl.credit_cents) as total_credit_cents,
  sum(jl.debit_cents) - sum(jl.credit_cents) as difference_cents
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

## Inspect Recent Journal Entries

```sql
select
  id,
  entry_date,
  memo,
  source_type,
  source_id,
  is_reversed,
  reverses_journal_entry_id,
  created_at
from journal_entries
order by created_at desc
limit 20;
```

---

## Inspect Journal Lines

```sql
select
  je.memo,
  jl.line_number,
  a.code,
  a.name,
  jl.debit_cents,
  jl.credit_cents
from journal_lines jl
join journal_entries je
  on je.id = jl.journal_entry_id
join accounts a
  on a.id = jl.account_id
order by je.created_at desc, jl.line_number;
```

---

# 17. Common Journal Engine Errors

## Error: No Active Organization Selected

Cause:

```txt
The user has not selected or created an organization.
```

Fix:

```txt
Create or select company workspace.
```

---

## Error: Account Does Not Exist for Active Organization

Cause:

```txt
The account ID is missing or belongs to another organization.
```

Fix:

```txt
Use accounts from the active organization.
```

---

## Error: Account Is Inactive

Cause:

```txt
The account has is_active = false.
```

Fix:

```txt
Reactivate the account or choose a different account.
```

---

## Error: Journal Entry Is Unbalanced

Cause:

```txt
Total debits do not equal total credits.
```

Fix:

```txt
Correct line amounts.
```

---

## Error: Source ID Must Be UUID

Cause:

```txt
sourceId was provided but is not a UUID.
```

Fix:

```txt
Use a real database UUID or set sourceId to null.
```

---

# 18. Best Practices

## 18.1 Never Bypass the Journal Engine

Do not insert directly into:

```txt
journal_entries
journal_lines
```

from random pages or services.

Use:

```ts
postJournalEntry()
```

or a carefully designed service that enforces the same rules.

---

## 18.2 Keep Business Documents and Journal Entries Linked

Invoices should link to their journal entry:

```txt
invoices.journal_entry_id
```

Bills should link to their journal entry:

```txt
bills.journal_entry_id
```

Payments should link to their journal entry:

```txt
customer_payments.journal_entry_id
vendor_payments.journal_entry_id
```

Bank transactions should link to their journal entry:

```txt
bank_transactions.journal_entry_id
```

---

## 18.3 Use Reversals, Not Deletes

Do not delete posted entries casually.

Use:

```txt
reverseJournalEntryForCurrentOrganization()
```

---

## 18.4 Keep Validation Pure Where Possible

Pure validation logic is easier to test.

Good:

```txt
validatePostJournalEntryInput()
```

This function does not require:

```txt
database
Clerk
network
```

---

## 18.5 Reports Should Use Journal Lines

Reports should summarize:

```txt
journal_lines
```

not just invoices or bills.

This keeps reports tied to accounting truth.

---

# 19. Final Journal Engine Checklist

Before trusting the journal engine, verify:

```txt
Valid balanced entries post.
Unbalanced entries are rejected.
Invalid lines are rejected.
Negative amounts are rejected.
Inactive accounts are rejected.
Cross-tenant accounts are rejected.
Journal entries write transactionally.
Reversals swap debits and credits.
Reports reflect journal lines.
SQL balance check returns zero rows.
```

---

# 20. Final Rule

The most important journal engine rule is:

```txt
No balanced entry, no posting.
```

In TypeScript:

```ts
if (totalDebitCents !== totalCreditCents) {
  throw new JournalEntryValidationError([...]);
}
```

Everything else in GreyMatter Ledger depends on this discipline.
