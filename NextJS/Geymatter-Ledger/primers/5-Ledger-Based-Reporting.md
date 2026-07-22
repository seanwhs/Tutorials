# Primer 5 — Ledger-Based Reporting

**Product:** GreyMatter Ledger  
**Document type:** Primer  
**Audience:** Developers, accountants reviewing system behavior, product managers, reporting engineers  
**Goal:** Explain why GreyMatter Ledger reports are generated from journal lines and how ledger-based reporting works  

---

# 1. Why Ledger-Based Reporting Matters

A common mistake in accounting software is building reports directly from source documents.

For example:

```txt
Profit & Loss from invoices and bills
GST report from invoice and bill tax fields
Balance Sheet from account balance columns
```

This can work for very simple cases, but it becomes fragile.

GreyMatter Ledger uses a ledger-based reporting model.

That means reports are generated from:

```txt
journal_entries
journal_lines
accounts
```

The core idea is:

```txt
Business documents explain what happened.
Journal entries record accounting truth.
Reports summarize journal lines.
```

---

# 2. Source Documents vs Ledger

## Source Documents

Source documents are business records.

Examples:

```txt
Invoices
Bills
Customer payments
Vendor payments
Bank transactions
```

They answer:

```txt
What business event happened?
Who was involved?
What document number?
What due date?
What status?
```

---

## Ledger

The ledger is the accounting record.

It answers:

```txt
Which accounts changed?
Was each change a debit or credit?
How much?
When?
```

The ledger is stored in:

```txt
journal_entries
journal_lines
```

---

# 3. Why Not Report Directly from Invoices?

Suppose you create an invoice:

```txt
Subtotal: S$100
GST:      S$9
Total:    S$109
```

You could calculate revenue from:

```txt
invoices.subtotal_cents
```

But what happens if:

```txt
The invoice is reversed?
A manual adjustment is posted?
A credit note is added later?
The journal entry differs from the invoice?
A migration fixes the ledger?
```

If the report reads only invoice rows, it may not reflect accounting truth.

If the report reads journal lines, corrections and adjustments are naturally included.

---

# 4. Why Not Store Account Balances Directly?

Another tempting design is:

```txt
accounts.balance_cents
```

Then update it every time something posts.

This is risky.

Why?

Because balance columns can drift.

Example:

```txt
Journal line inserted.
Balance update fails.
```

Now the account balance is wrong.

Ledger-based reporting avoids this.

Instead of storing current balance as truth, calculate balance from journal lines.

---

# 5. Core Reporting Tables

Ledger-based reports use:

```txt
journal_entries
journal_lines
accounts
```

---

## `journal_entries`

Provides:

```txt
entry_date
memo
source_type
organization_id
```

Useful for:

```txt
Date filtering
Source filtering
Tenant filtering
```

---

## `journal_lines`

Provides:

```txt
account_id
debit_cents
credit_cents
organization_id
```

Useful for:

```txt
Summing account balances
Calculating report totals
```

---

## `accounts`

Provides:

```txt
code
name
type
```

Useful for:

```txt
Grouping report lines
Determining signed balance
Showing account names
```

---

# 6. Basic Ledger Query Pattern

A typical report query:

```ts
await db
  .select({
    accountId: accounts.id,
    accountCode: accounts.code,
    accountName: accounts.name,
    accountType: accounts.type,
    debitCents: sql<number>`coalesce(sum(${journalLines.debitCents}), 0)`,
    creditCents: sql<number>`coalesce(sum(${journalLines.creditCents}), 0)`,
  })
  .from(journalLines)
  .innerJoin(accounts, eq(journalLines.accountId, accounts.id))
  .innerJoin(journalEntries, eq(journalLines.journalEntryId, journalEntries.id))
  .where(
    and(
      eq(journalLines.organizationId, organization.id),
      gte(journalEntries.entryDate, from),
      lte(journalEntries.entryDate, to),
    ),
  )
  .groupBy(accounts.id, accounts.code, accounts.name, accounts.type);
```

This produces debit and credit totals by account.

---

# 7. Signed Balances

Raw debits and credits are useful, but reports often need signed balances.

Signed balance depends on account type.

---

## Debit-Normal Accounts

Assets and expenses normally increase with debits.

Signed balance:

```txt
debits - credits
```

Examples:

```txt
Bank
Accounts Receivable
Purchases
Rent Expense
GST Input Tax
```

---

## Credit-Normal Accounts

Liabilities, equity, and income normally increase with credits.

Signed balance:

```txt
credits - debits
```

Examples:

```txt
Accounts Payable
GST Output Tax
Share Capital
Sales Revenue
```

---

# 8. Signed Balance Helper

GreyMatter Ledger uses:

```txt
lib/reports/balance-sign.ts
```

Key function:

```ts
calculateSignedBalanceCents()
```

Example:

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

Example:

```ts
calculateSignedBalanceCents({
  accountType: "asset",
  debitCents: 10900,
  creditCents: 0,
});
```

Returns:

```txt
10900
```

---

# 9. Ledger Overview

The ledger overview report groups all account balances by account type.

Page:

```txt
/reports/ledger-overview
```

It shows:

```txt
Assets
Liabilities
Equity
Income
Expenses
```

This is a diagnostic report.

It helps verify that posted journal entries are flowing into report helpers.

---

# 10. Profit & Loss Reporting

Profit & Loss uses:

```txt
Income
Expenses
```

Formula:

```txt
Net Profit = Income - Expenses
```

Example:

```txt
Sales Revenue: S$2,000
Purchases:     S$300
Bank Charges:  S$15

Net Profit: S$1,685
```

Page:

```txt
/reports/profit-and-loss
```

Service:

```txt
services/reports/profit-and-loss-service.ts
```

---

# 11. Why GST Usually Does Not Appear in P&L

In GreyMatter Ledger:

```txt
1400 GST Input Tax = asset
2110 GST Output Tax = liability
```

Profit & Loss includes only:

```txt
income
expense
```

Therefore GST Input and GST Output do not usually appear in P&L.

They appear in:

```txt
Balance Sheet
GST report
```

---

# 12. Balance Sheet Reporting

The Balance Sheet uses:

```txt
Assets
Liabilities
Equity
```

Formula:

```txt
Assets = Liabilities + Equity
```

Page:

```txt
/reports/balance-sheet
```

Service:

```txt
services/reports/balance-sheet-service.ts
```

---

# 13. Current Year Earnings

Income and expenses affect equity.

So the Balance Sheet includes:

```txt
Current Year Earnings = Income - Expenses
```

This keeps the accounting equation balanced.

Example:

```txt
Assets: S$10,000
Liabilities: S$2,000
Equity before earnings: S$7,000
Current year earnings: S$1,000

Liabilities + Equity = S$2,000 + S$8,000 = S$10,000
```

---

# 14. GST F5-Style Reporting

The GST report uses GST account balances.

Accounts:

```txt
1400 GST Input Tax
2110 GST Output Tax
```

Formula:

```txt
Net GST Payable = GST Output Tax - GST Input Tax
```

Page:

```txt
/reports/gst-f5
```

Service:

```txt
services/reports/gst-f5-service.ts
```

Because it reads journal lines, reversals and adjustments are naturally reflected.

---

# 15. AR Aging Is Different

AR Aging is not primarily a journal-line report.

It is an operational report based on unpaid invoices.

It answers:

```txt
Which customers owe us money?
How overdue are they?
```

Source:

```txt
invoices
customers
```

It excludes invoices with status:

```txt
paid
void
```

Page:

```txt
/reports/ar-aging
```

---

# 16. AP Aging Is Different

AP Aging is based on unpaid vendor bills.

It answers:

```txt
Which vendors do we owe?
How overdue are the bills?
```

Source:

```txt
bills
vendors
```

It excludes bills with status:

```txt
paid
void
```

Page:

```txt
/reports/ap-aging
```

---

# 17. Date Ranges

Many reports use date filters.

Examples:

```txt
Profit & Loss
GST report
Ledger overview
```

Date range:

```txt
from
to
```

Example:

```txt
2026-01-01 to 2026-12-31
```

The report helper validates dates in:

```txt
lib/reports/date-range.ts
```

---

# 18. As-Of Dates

Some reports use a single date.

Example:

```txt
Balance Sheet as of 2026-12-31
AR Aging as of 2026-12-31
AP Aging as of 2026-12-31
```

A Balance Sheet should include balances up to the as-of date.

---

# 19. Reversals and Reports

Reversals work naturally with ledger-based reporting.

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

Report result:

```txt
Net Rent Expense = S$0
Net Bank effect = S$0
```

No special report logic is needed.

Reports just sum journal lines.

---

# 20. Tenant Scope in Reports

Every report must filter by organization.

Bad:

```ts
await db.select().from(journalLines);
```

Good:

```ts
await db
  .select()
  .from(journalLines)
  .where(eq(journalLines.organizationId, organization.id));
```

Reports mixing companies are unacceptable.

---

# 21. Common Reporting Mistakes

## Mistake 1 — Reporting from Invoices Only

Risk:

```txt
Manual adjustments and reversals are ignored.
```

Better:

```txt
Use journal lines.
```

---

## Mistake 2 — Forgetting Normal Balance

Wrong:

```txt
signed balance = debits - credits for all accounts
```

Correct:

```txt
Assets/expenses = debits - credits
Liabilities/equity/income = credits - debits
```

---

## Mistake 3 — Forgetting Current Year Earnings

Balance Sheet may not balance if income and expenses are ignored.

Add:

```txt
Current Year Earnings = Income - Expenses
```

---

## Mistake 4 — Missing Organization Filter

Reports can leak or mix data.

Always scope by:

```txt
organization_id
```

---

## Mistake 5 — Date Range Too Narrow

Users may think reports are wrong when the report date excludes transactions.

Try a broad range:

```txt
2020-01-01 to 2030-12-31
```

---

# 22. SQL Report Verification

## Income and Expense Balances

```sql
select
  a.code,
  a.name,
  a.type,
  sum(jl.debit_cents) as debits,
  sum(jl.credit_cents) as credits
from journal_lines jl
join accounts a
  on a.id = jl.account_id
join journal_entries je
  on je.id = jl.journal_entry_id
where a.type in ('income', 'expense')
group by a.code, a.name, a.type
order by a.code;
```

---

## Balance Sheet Accounts

```sql
select
  a.code,
  a.name,
  a.type,
  sum(jl.debit_cents) as debits,
  sum(jl.credit_cents) as credits
from journal_lines jl
join accounts a
  on a.id = jl.account_id
join journal_entries je
  on je.id = jl.journal_entry_id
where a.type in ('asset', 'liability', 'equity')
group by a.code, a.name, a.type
order by a.code;
```

---

## GST Accounts

```sql
select
  a.code,
  a.name,
  a.type,
  sum(jl.debit_cents) as debits,
  sum(jl.credit_cents) as credits
from journal_lines jl
join accounts a
  on a.id = jl.account_id
join journal_entries je
  on je.id = jl.journal_entry_id
where a.code in ('1400', '2110')
group by a.code, a.name, a.type
order by a.code;
```

---

# 23. Testing Report Logic

Report tests live in:

```txt
tests/report-helpers.test.ts
tests/profit-and-loss.test.ts
tests/balance-sheet.test.ts
tests/gst-f5-report.test.ts
tests/aging.test.ts
```

Run:

```bash
pnpm test
```

These tests verify:

```txt
Signed balance behavior
P&L calculation
Balance Sheet calculation
GST report calculation
Aging bucket logic
```

---

# 24. Developer Checklist for New Reports

When adding a new report, ask:

```txt
Should this report come from journal lines?
Does it need source documents instead?
Does it need date range or as-of date?
Does it filter by organization_id?
Does it use signed balances correctly?
Does it need account type grouping?
Does it need tests?
Does it need SQL verification?
```

---

# 25. Which Reports Use Which Data?

| Report | Primary Data Source |
|---|---|
| Ledger Overview | Journal lines |
| Profit & Loss | Journal lines |
| Balance Sheet | Journal lines |
| GST F5-style | Journal lines |
| AR Aging | Invoices |
| AP Aging | Bills |
| CPF Estimate | User input |
| Corporate Tax Estimate | P&L result |
| Multi-Currency Reference | User/example input |

---

# 26. Final Mental Model

Ledger-based reporting follows this flow:

```txt
Business event happens
  |
  v
Journal entry is posted
  |
  v
Journal lines store debits and credits
  |
  v
Report queries journal lines
  |
  v
Report groups by account type
  |
  v
Report displays balances
```

The key rule:

```txt
If it affects financial statements, it should be in the ledger.
```

The second key rule:

```txt
If it is in the ledger, reports should reflect it.
```
