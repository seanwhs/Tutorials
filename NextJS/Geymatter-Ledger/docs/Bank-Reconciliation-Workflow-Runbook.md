# Bank Reconciliation Workflow Runbook

**Product:** GreyMatter Ledger  
**Document type:** Operational Runbook  
**Version:** 1.0  
**Status:** Draft  
**Audience:** Bookkeepers, accountants, finance operators, business owners  
**Frequency:** Monthly or weekly, depending on transaction volume  
**Purpose:** Provide a step-by-step workflow for importing, categorizing, posting, and reconciling bank transactions in GreyMatter Ledger  

---

# 1. Purpose

This runbook explains how to perform a bank reconciliation workflow in **GreyMatter Ledger**.

Bank reconciliation helps confirm that:

```txt
The company’s accounting records
```

match:

```txt
The bank statement
```

In GreyMatter Ledger, the current workflow is:

```txt
Upload bank CSV
Review imported transactions
Categorize transactions
Post selected transactions to the ledger
Mark posted transactions as reconciled
Review reconciliation summary
```

This version is intentionally simple.

It does not yet fully match imported bank transactions against existing invoice or bill payments automatically.

Because of that, users must avoid duplicate posting.

---

# 2. Important Warning About Duplicate Posting

GreyMatter Ledger currently supports manual payment recording and bank transaction posting.

If you already recorded a customer payment or vendor payment manually, and then import the same bank transaction, posting the bank row again can duplicate the bank effect.

Example duplicate risk:

```txt
You record customer payment:
Debit Bank
Credit Accounts Receivable

Then you post imported bank receipt:
Debit Bank
Credit Category Account
```

This may overstate the bank balance.

Recommended rule:

```txt
Only post imported bank transactions that have not already been recorded elsewhere.
```

For transactions already represented by customer/vendor payments, categorize or note them, but do not post them again unless you are intentionally creating a missing ledger entry.

A future version should include bank matching to existing payments.

---

# 3. When to Perform Bank Reconciliation

Recommended frequency:

```txt
Monthly
```

For higher transaction volume:

```txt
Weekly
```

Best time:

```txt
After bank statement is available
After invoices, bills, and payments are entered
Before final monthly report review
```

---

# 4. Required Access

The user should have access to:

```txt
Bank page
Chart of accounts
Reports
Journal diagnostics
Bank statement CSV file
```

Admin access may be required if corrections or reversals are needed.

---

# 5. Pre-Reconciliation Checklist

Before starting:

- [ ] Correct organization is selected.
- [ ] Chart of accounts is seeded.
- [ ] Bank account `1000 Bank` exists and is active.
- [ ] Relevant expense/income/category accounts exist.
- [ ] Customer payments already known have been recorded.
- [ ] Vendor payments already known have been recorded.
- [ ] Bank CSV file is available.
- [ ] You know the statement period.

---

# 6. Example Company

This runbook uses:

```txt
Merlion Creative Pte. Ltd.
```

Example bank statement period:

```txt
February 2026
```

Example CSV:

```csv
date,description,amount
2026-02-15,Orchard Retail Group payment,2180.00
2026-02-20,CloudStack Hosting SG payment,-327.00
2026-02-25,Bank service charge,-15.00
2026-02-26,Interest income,2.50
```

---

# 7. Step 1 — Select the Correct Organization

Use the organization switcher in the header.

Select:

```txt
Merlion Creative Pte. Ltd.
```

Confirm on:

```txt
/dashboard
```

or:

```txt
/settings/auth-status
```

Do not import bank transactions under the wrong organization.

---

# 8. Step 2 — Review Chart of Accounts

Open:

```txt
/accounts
```

Confirm required accounts exist and are active.

Common bank reconciliation accounts:

```txt
1000 Bank
1100 Accounts Receivable
2000 Accounts Payable
4000 Sales Revenue
4200 Other Income
6300 Software and Subscriptions
6700 Bank Charges
```

If an account is missing, create it or seed the default chart.

If an account is inactive, reactivate it if appropriate.

---

# 9. Step 3 — Prepare the Bank CSV File

GreyMatter Ledger expects CSV headers:

```csv
date,description,amount
```

Required columns:

```txt
date
description
amount
```

Date format:

```txt
YYYY-MM-DD
```

Amount format:

```txt
109.00
-25.50
```

Positive amount:

```txt
Money came into bank.
```

Negative amount:

```txt
Money left bank.
```

Example:

```csv
date,description,amount
2026-02-15,Orchard Retail Group payment,2180.00
2026-02-20,CloudStack Hosting SG payment,-327.00
2026-02-25,Bank service charge,-15.00
2026-02-26,Interest income,2.50
```

---

# 10. Step 4 — Upload Bank CSV

Open:

```txt
/bank
```

Choose your CSV file.

Click:

```txt
Upload CSV
```

Expected result:

```txt
Bank CSV imported successfully.
```

The page should show imported transactions.

---

# 11. Step 5 — Review Imported Transactions

On `/bank`, review each imported row.

Check:

```txt
Date
Description
Amount
Status
```

Initial status:

```txt
imported
```

Review for:

- Duplicate rows
- Wrong dates
- Incorrect signs
- Missing descriptions
- Unexpected bank activity
- Transactions already recorded as payments

---

# 12. Step 6 — Categorize Transactions

Each imported row should be categorized to an account.

Categorization assigns the accounting account used if the transaction is posted.

---

## 12.1 Categorize Customer Receipt

Example transaction:

```txt
2026-02-15 Orchard Retail Group payment +S$2,180.00
```

If this payment was already recorded from the invoice detail page:

```txt
Do not post it again.
```

You may categorize it to:

```txt
1100 Accounts Receivable
```

and add note:

```txt
Matched to existing invoice payment. Do not post again.
```

If it was not recorded elsewhere, categorize it appropriately and post.

---

## 12.2 Categorize Vendor Payment

Example transaction:

```txt
2026-02-20 CloudStack Hosting SG payment -S$327.00
```

If vendor payment was already recorded from bill detail:

```txt
Do not post it again.
```

You may categorize it to:

```txt
2000 Accounts Payable
```

and add note:

```txt
Matched to existing vendor payment. Do not post again.
```

If not recorded elsewhere, categorize and post carefully.

---

## 12.3 Categorize Bank Charge

Example transaction:

```txt
2026-02-25 Bank service charge -S$15.00
```

This may not already exist in the ledger.

Categorize to:

```txt
6700 Bank Charges
```

Note:

```txt
Monthly bank service fee.
```

This is a good candidate for posting.

---

## 12.4 Categorize Interest Income

Example transaction:

```txt
2026-02-26 Interest income +S$2.50
```

Categorize to:

```txt
4200 Other Income
```

This may be posted if not already recorded.

---

# 13. Step 7 — Understand Posting Logic

Before posting, understand how GreyMatter Ledger posts bank transactions.

---

## Positive Bank Transaction

Example:

```txt
+S$2.50 interest income
```

Posting:

```txt
Debit  Bank            S$2.50
Credit Other Income    S$2.50
```

---

## Negative Bank Transaction

Example:

```txt
-S$15.00 bank charge
```

Posting:

```txt
Debit  Bank Charges    S$15.00
Credit Bank            S$15.00
```

---

# 14. Step 8 — Post Transactions to Ledger

Only post transactions that should create new accounting entries.

For each appropriate categorized transaction, click:

```txt
Post to ledger
```

The status changes:

```txt
categorized -> posted
```

A journal entry is created.

---

## Example: Bank Charge Posting

Transaction:

```txt
Bank service charge -S$15.00
```

Category:

```txt
6700 Bank Charges
```

Journal entry:

```txt
Debit  6700 Bank Charges    S$15.00
Credit 1000 Bank            S$15.00
```

---

## Example: Interest Income Posting

Transaction:

```txt
Interest income +S$2.50
```

Category:

```txt
4200 Other Income
```

Journal entry:

```txt
Debit  1000 Bank            S$2.50
Credit 4200 Other Income    S$2.50
```

---

# 15. Step 9 — Verify Journal Entries

Open:

```txt
/settings/database/journal
```

Look for entries:

```txt
Bank transaction posted: Bank service charge
Bank transaction posted: Interest income
```

Each should show:

```txt
Balanced
```

Verify lines.

For bank charge:

```txt
Debit Bank Charges
Credit Bank
```

For interest income:

```txt
Debit Bank
Credit Other Income
```

---

# 16. Step 10 — Mark Posted Transactions as Reconciled

Return to:

```txt
/bank
```

For posted transactions, click:

```txt
Mark reconciled
```

The status changes:

```txt
posted -> reconciled
```

A reconciled transaction stores:

```txt
reconciled_at
reconciled_by_user_id
```

---

# 17. Step 11 — Review Reconciliation Summary

Open:

```txt
/bank/reconciliation
```

Review counts:

```txt
Imported
Categorized
Posted
Reconciled
```

Goal:

```txt
All relevant transactions should be reconciled or intentionally left unposted/ignored.
```

In the current version, unreconciled transactions may remain if they represent payments already recorded manually.

---

# 18. Step 12 — Review Bank Impact in Reports

Open:

```txt
/reports/ledger-overview
```

Check:

```txt
1000 Bank
6700 Bank Charges
4200 Other Income
```

Open:

```txt
/reports/profit-and-loss
```

Bank charges should appear as expenses.

Interest income should appear as income.

---

# 19. Step 13 — Verify with SQL

If you have database access, run:

```sql
select
  transaction_date,
  description,
  amount_cents,
  status,
  category_account_id,
  journal_entry_id,
  reconciled_at
from bank_transactions
order by transaction_date;
```

For reconciled rows:

```txt
status = reconciled
journal_entry_id is not null
reconciled_at is not null
```

---

## Verify Bank Journal Entries

```sql
select
  je.memo,
  a.code,
  a.name,
  jl.debit_cents,
  jl.credit_cents
from journal_entries je
join journal_lines jl
  on jl.journal_entry_id = je.id
join accounts a
  on a.id = jl.account_id
where je.source_type = 'bank_transaction'
order by je.created_at desc, jl.line_number;
```

---

## Verify Journal Balance

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

Expected:

```txt
0 rows
```

---

# 20. Handling Transactions Already Recorded as Payments

If a bank row corresponds to a payment already recorded in GreyMatter Ledger:

```txt
Do not post it again.
```

Examples:

```txt
Customer invoice payment already recorded
Vendor bill payment already recorded
```

Current recommended handling:

1. Categorize with note.
2. Do not post to ledger.
3. Keep for reference until future matching workflow exists.

Possible note:

```txt
Matched to existing customer payment. Not posted from bank import.
```

---

# 21. Handling Unknown Transactions

If a transaction is unclear:

```txt
Do not post immediately.
```

Instead:

1. Categorize only if confident.
2. Add note.
3. Ask business owner/accountant.
4. Post only after confirmed.

Examples:

```txt
Unknown deposit
Unknown card charge
Unclear transfer
```

---

# 22. Handling Transfers

Bank transfers between accounts require special handling.

The current tutorial app has one main bank account.

If future versions support multiple bank accounts, transfers should avoid creating income or expense.

Example transfer:

```txt
Debit  Destination Bank
Credit Source Bank
```

Do not categorize transfers as revenue or expense.

---

# 23. Handling Bank Fees

Bank fees are usually straightforward.

Example:

```txt
-S$15.00 bank service charge
```

Category:

```txt
6700 Bank Charges
```

Posting:

```txt
Debit  Bank Charges
Credit Bank
```

---

# 24. Handling Interest Income

Example:

```txt
+S$2.50 interest income
```

Category:

```txt
4200 Other Income
```

Posting:

```txt
Debit  Bank
Credit Other Income
```

---

# 25. Handling Refunds

Refunds require judgment.

Example vendor refund:

```txt
+S$50.00 refund from software vendor
```

Possible treatment:

```txt
Debit Bank
Credit Original Expense Account
```

or another account depending on context.

Consult accountant if unsure.

---

# 26. Handling GST in Bank Imports

A bank transaction amount alone usually does not show GST breakdown.

Example:

```txt
-S$109.00 software payment
```

If this was not already entered as a bill, posting directly to an expense account does not split GST.

Better accounting may require entering a bill first:

```txt
Debit Expense S$100
Debit GST Input Tax S$9
Credit Accounts Payable S$109
```

Then record payment.

For GST-registered companies, direct bank posting may not be enough for GST accuracy.

Recommended:

```txt
Use bills for GST-bearing vendor expenses when GST input tax matters.
```

---

# 27. Reconciliation Status Meaning

## Imported

Raw CSV row imported.

No category yet.

---

## Categorized

User selected an account.

No journal entry yet.

---

## Posted

A journal entry was created.

---

## Reconciled

The posted bank transaction has been confirmed against the statement.

---

## Ignored

Reserved for future use.

Would mean transaction intentionally excluded from posting/reconciliation workflow.

---

# 28. Monthly Bank Reconciliation Checklist

Use this checklist each month.

## Import

- [ ] Correct company selected.
- [ ] Correct bank CSV uploaded.
- [ ] Row count matches statement.
- [ ] Dates and amounts look correct.

## Categorize

- [ ] Bank fees categorized.
- [ ] Interest income categorized.
- [ ] Unknown transactions investigated.
- [ ] Customer receipts reviewed.
- [ ] Vendor payments reviewed.

## Avoid Duplicates

- [ ] Customer payments already recorded are not posted again.
- [ ] Vendor payments already recorded are not posted again.
- [ ] Bank rows representing existing documents are noted.

## Post

- [ ] Only valid unrecorded transactions posted.
- [ ] Posted journal entries reviewed.
- [ ] Journal entries balanced.

## Reconcile

- [ ] Posted transactions marked reconciled.
- [ ] Reconciliation page reviewed.
- [ ] Unreconciled items explained.

## Reports

- [ ] Bank account reviewed in ledger overview.
- [ ] Bank charges reviewed in P&L.
- [ ] Unusual bank activity investigated.

---

# 29. Common Reconciliation Problems

## Problem: Bank Balance Looks Too High

Possible causes:

```txt
Customer payment recorded manually and bank import also posted
Duplicate CSV upload
Positive bank transaction categorized incorrectly
```

Review:

```txt
/settings/database/journal
```

Look for duplicate bank debits.

---

## Problem: Bank Balance Looks Too Low

Possible causes:

```txt
Vendor payment recorded manually and bank import also posted
Bank charges posted twice
Wrong sign in CSV
```

Review bank transaction amounts and journal lines.

---

## Problem: Transaction Cannot Be Posted

Possible causes:

```txt
Transaction not categorized
Category account inactive
Bank account 1000 missing/inactive
Transaction already posted
```

Fix:

```txt
Categorize first
Reactivate required account
Avoid reposting
```

---

## Problem: Transaction Cannot Be Reconciled

Possible causes:

```txt
Transaction not posted
Transaction already reconciled
Missing journal entry
```

Fix:

```txt
Post to ledger first
```

---

# 30. Future Enhancements Recommended

A production-grade reconciliation system should add:

```txt
Bank statement ending balance
Reconciled balance calculation
Matching imported rows to existing payments
Duplicate detection
Ignore workflow
Undo reconciliation with admin permission
Multiple bank accounts
Bank transfer handling
Statement period records
Reconciliation reports
CSV format templates per bank
OFX/QIF support
Bank feed integrations
```

---

# 31. Final Bank Reconciliation Summary

The current GreyMatter Ledger bank workflow is:

```txt
Upload CSV
Review transactions
Categorize transactions
Post only transactions not already recorded
Mark posted transactions reconciled
Review reports
```

The most important caution:

```txt
Do not duplicate payments already recorded from invoices or bills.
```

The most important accounting check:

```txt
Every bank-posted journal entry must balance.
```

The most important reconciliation principle:

```txt
Reconciled means confirmed against the bank statement and should be treated as locked.
```
