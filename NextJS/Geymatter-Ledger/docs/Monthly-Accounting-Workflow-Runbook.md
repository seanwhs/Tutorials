# Monthly Accounting Workflow Runbook

**Product:** GreyMatter Ledger  
**Document type:** Operational Runbook  
**Version:** 1.0  
**Status:** Draft  
**Audience:** Business owners, bookkeepers, accountants, finance operators  
**Frequency:** Monthly  
**Purpose:** Guide users through a repeatable monthly accounting close/review workflow using GreyMatter Ledger  

---

# 1. Purpose

This runbook describes a practical monthly workflow for using **GreyMatter Ledger** to review and maintain company accounting records.

The monthly workflow helps ensure:

```txt
Invoices are recorded
Bills are recorded
Payments are recorded
Bank transactions are imported
Bank activity is reconciled
Reports are reviewed
GST position is checked
Audit logs are reviewed
```

This runbook does **not** replace professional accounting review.

It provides a structured process for maintaining clean records.

---

# 2. Recommended Timing

Perform this workflow:

```txt
Monthly
```

Recommended timing:

```txt
Within 5–10 business days after month-end
```

Example:

For February 2026:

```txt
Run monthly workflow between 1 March and 10 March 2026.
```

---

# 3. Example Company

This runbook uses a fictitious company:

```txt
Merlion Creative Pte. Ltd.
```

But the workflow applies to any organization in GreyMatter Ledger.

---

# 4. Pre-Workflow Checklist

Before starting, confirm:

- [ ] You can sign in.
- [ ] Correct company workspace is selected.
- [ ] Chart of accounts is seeded.
- [ ] You have access to invoices and bills.
- [ ] You have the month’s bank CSV statement.
- [ ] You know the review period.
- [ ] You have admin access if journal reversals or audit review are needed.

---

# 5. Select the Correct Company Workspace

Open GreyMatter Ledger.

Use the organization switcher in the app header.

Select the company you are reviewing.

Example:

```txt
Merlion Creative Pte. Ltd.
```

Verify the active organization at:

```txt
/dashboard
```

or:

```txt
/settings/auth-status
```

---

# 6. Define the Monthly Review Period

For this runbook, assume:

```txt
Month: February 2026
Start date: 2026-02-01
End date: 2026-02-28
```

You will use these dates in reports.

---

# 7. Review Chart of Accounts

Open:

```txt
/accounts
```

Confirm:

- [ ] Default accounts are seeded.
- [ ] Required accounts are active.
- [ ] Custom accounts are correct.
- [ ] No duplicate or confusing account names.
- [ ] No needed account is inactive.

Important accounts:

```txt
1000 Bank
1100 Accounts Receivable
1400 GST Input Tax
2000 Accounts Payable
2110 GST Output Tax
4000 Sales Revenue
5100 Purchases
6300 Software and Subscriptions
6700 Bank Charges
```

If an account is missing, create it.

If an account is inactive but needed, reactivate it.

---

# 8. Review Customers

Open:

```txt
/customers
```

Check:

- [ ] All active customers for the month exist.
- [ ] Customer names are spelled correctly.
- [ ] Emails are correct if used for invoice communication.
- [ ] Billing addresses are correct where needed.
- [ ] Duplicate customers are not present.

If needed, create missing customers.

Example:

```txt
Orchard Retail Group Pte. Ltd.
```

---

# 9. Review Vendors

Open:

```txt
/vendors
```

Check:

- [ ] All vendors for the month exist.
- [ ] Vendor names are spelled correctly.
- [ ] Billing emails are accurate.
- [ ] Duplicate vendors are not present.

If needed, create missing vendors.

Example:

```txt
CloudStack Hosting SG Pte. Ltd.
```

---

# 10. Enter or Review Customer Invoices

Open:

```txt
/invoices
```

For the month, confirm:

- [ ] All customer invoices have been created.
- [ ] Invoice dates are correct.
- [ ] Due dates are correct.
- [ ] GST rate is correct.
- [ ] Invoice totals are correct.
- [ ] Invoices are linked to journal entries.
- [ ] Invoice journal entries are balanced.

For each invoice, click the invoice number and review:

```txt
Customer
Invoice line
Subtotal
GST
Total
Linked journal entry
```

---

## Expected Invoice Posting

For a GST invoice:

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

Example:

```txt
Invoice subtotal: S$2,000.00
GST:              S$180.00
Total:            S$2,180.00
```

Journal entry:

```txt
Debit  Accounts Receivable   S$2,180.00
Credit Sales Revenue         S$2,000.00
Credit GST Output Tax        S$180.00
```

---

# 11. Enter or Review Vendor Bills

Open:

```txt
/bills
```

For the month, confirm:

- [ ] All vendor bills have been entered.
- [ ] Bill dates are correct.
- [ ] Due dates are correct.
- [ ] GST input tax is correct.
- [ ] Bill totals are correct.
- [ ] Bills are linked to journal entries.
- [ ] Bill journal entries are balanced.

For each bill, click the bill number and review:

```txt
Vendor
Bill line
Subtotal
GST input tax
Total payable
Linked journal entry
```

---

## Expected Bill Posting

For a GST vendor bill:

```txt
Debit  Purchases / Expense
Debit  GST Input Tax
Credit Accounts Payable
```

Example:

```txt
Bill subtotal: S$300.00
GST:           S$27.00
Total:         S$327.00
```

Journal entry:

```txt
Debit  Purchases             S$300.00
Debit  GST Input Tax         S$27.00
Credit Accounts Payable      S$327.00
```

---

# 12. Record Customer Payments

Open:

```txt
/invoices
```

For invoices paid during the month:

1. Open invoice detail.
2. Find the payment section.
3. Enter payment date.
4. Enter reference.
5. Click:

```txt
Record payment
```

Check:

- [ ] Paid invoices show status `paid`.
- [ ] Payment appears on `/payments`.
- [ ] Payment journal entry is balanced.

---

## Expected Customer Payment Posting

```txt
Debit  Bank
Credit Accounts Receivable
```

Important:

```txt
Do not record revenue again.
```

Revenue was already recorded when the invoice was issued.

---

# 13. Record Vendor Payments

Open:

```txt
/bills
```

For bills paid during the month:

1. Open bill detail.
2. Find the payment section.
3. Enter payment date.
4. Enter reference.
5. Click:

```txt
Record payment
```

Check:

- [ ] Paid bills show status `paid`.
- [ ] Payment appears on `/payments`.
- [ ] Payment journal entry is balanced.

---

## Expected Vendor Payment Posting

```txt
Debit  Accounts Payable
Credit Bank
```

Important:

```txt
Do not record the expense again.
```

Expense was already recorded when the bill was entered.

---

# 14. Review Payments

Open:

```txt
/payments
```

Review:

- [ ] Customer payments for the month.
- [ ] Vendor payments for the month.
- [ ] Amounts match bank activity.
- [ ] References are meaningful.
- [ ] Payments are linked to journal entries.

Look for unusual items:

```txt
Duplicate payments
Missing references
Wrong payment dates
Unexpected amounts
```

---

# 15. Import Bank CSV

Open:

```txt
/bank
```

Upload the bank CSV for the month.

Expected format:

```csv
date,description,amount
2026-02-15,Orchard Retail Group payment,2180.00
2026-02-20,CloudStack Hosting SG payment,-327.00
2026-02-25,Bank service charge,-15.00
```

After upload, confirm:

- [ ] Import succeeded.
- [ ] Row count is correct.
- [ ] Transactions appear in the bank table.

---

# 16. Categorize Bank Transactions

For each imported transaction, choose a category account.

Examples:

```txt
Bank service charge -> 6700 Bank Charges
Software payment -> 6300 Software and Subscriptions
Unmatched customer receipt -> 1100 Accounts Receivable or other appropriate account
Unmatched vendor payment -> 2000 Accounts Payable or expense account
```

Click:

```txt
Save category
```

Status becomes:

```txt
categorized
```

---

# 17. Avoid Duplicate Bank Posting

Be careful.

If you already recorded a customer payment or vendor payment manually, importing the same bank transaction and posting it again can duplicate the bank effect.

Current tutorial version does not fully match bank rows to existing payments.

Recommended practice:

```txt
Post bank transactions only when they have not already been recorded elsewhere.
```

Examples of safe bank postings:

```txt
Bank fees
Interest income
Small charges not entered as bills
Direct expenses not otherwise recorded
```

---

# 18. Post Bank Transactions to Ledger

For categorized transactions that should create ledger entries, click:

```txt
Post to ledger
```

For positive bank amounts:

```txt
Debit  Bank
Credit Category Account
```

For negative bank amounts:

```txt
Debit  Category Account
Credit Bank
```

Check:

- [ ] Status becomes `posted`.
- [ ] Journal entry is created.
- [ ] Journal entry is balanced.

---

# 19. Reconcile Bank Transactions

For posted transactions, click:

```txt
Mark reconciled
```

Status becomes:

```txt
reconciled
```

Open:

```txt
/bank/reconciliation
```

Check:

- [ ] Imported count
- [ ] Categorized count
- [ ] Posted count
- [ ] Reconciled count

The goal is to have all relevant bank transactions reconciled or intentionally ignored.

---

# 20. Review Journal Diagnostics

Open:

```txt
/settings/database/journal
```

Review recent entries.

Check:

- [ ] Entries are balanced.
- [ ] Source types make sense.
- [ ] Invoice entries are correct.
- [ ] Bill entries are correct.
- [ ] Payment entries are correct.
- [ ] Bank posting entries are correct.
- [ ] Reversals, if any, have reasons.

Important source types:

```txt
invoice
bill
customer_payment
vendor_payment
bank_transaction
manual
```

---

# 21. Run Journal Balance SQL Check

If you have database access, run:

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

If rows appear, stop and investigate.

---

# 22. Review Profit & Loss

Open:

```txt
/reports/profit-and-loss
```

Use monthly date range:

```txt
From: 2026-02-01
To: 2026-02-28
```

Review:

- [ ] Income accounts
- [ ] Expense accounts
- [ ] Net profit or loss
- [ ] Unexpected expenses
- [ ] Missing income
- [ ] GST not appearing as income/expense

Expected P&L accounts may include:

```txt
4000 Sales Revenue
5100 Purchases
6300 Software and Subscriptions
6700 Bank Charges
```

---

# 23. Review Balance Sheet

Open:

```txt
/reports/balance-sheet
```

Use as-of date:

```txt
2026-02-28
```

Review:

- [ ] Bank balance direction
- [ ] Accounts Receivable
- [ ] Accounts Payable
- [ ] GST Input Tax
- [ ] GST Output Tax
- [ ] Current Year Earnings
- [ ] Equation check

Expected equation:

```txt
Assets = Liabilities + Equity
```

If not balanced, investigate journal entries.

---

# 24. Review GST F5-Style Report

Open:

```txt
/reports/gst-f5
```

Use monthly date range:

```txt
From: 2026-02-01
To: 2026-02-28
```

Review:

```txt
GST Output Tax
GST Input Tax
Net GST Payable / Refundable
```

Important:

This report is educational and simplified.

Before filing GST, consult a qualified accountant or tax professional.

---

# 25. Review AR Aging

Open:

```txt
/reports/ar-aging
```

Use as-of date:

```txt
2026-02-28
```

Check:

- [ ] Unpaid invoices appear.
- [ ] Paid invoices do not appear.
- [ ] Due dates are correct.
- [ ] Overdue buckets are correct.

Follow up with customers if needed.

---

# 26. Review AP Aging

Open:

```txt
/reports/ap-aging
```

Use as-of date:

```txt
2026-02-28
```

Check:

- [ ] Unpaid bills appear.
- [ ] Paid bills do not appear.
- [ ] Due dates are correct.
- [ ] Overdue buckets are correct.

Schedule vendor payments if needed.

---

# 27. Review Audit Log

Open:

```txt
/settings/audit-log
```

Admin-only.

Review monthly events:

```txt
customer.created
vendor.created
invoice.created
bill.created
customer_payment.recorded
vendor_payment.recorded
journal_entry.reversed
```

Look for:

```txt
Unexpected activity
Duplicate actions
Unusual reversals
Missing expected activity
```

---

# 28. Review Background Jobs

Open:

```txt
/settings/background-jobs
```

Check:

- [ ] Inngest endpoint is configured.
- [ ] Health check event can be sent.
- [ ] Overdue invoice reminder job exists.
- [ ] Recurring invoice scheduler exists.

If using Inngest dev or production dashboard, review failed jobs.

---

# 29. Generate Recurring Invoices

Open:

```txt
/invoices/recurring
```

Check recurring profiles.

If profiles are due, click:

```txt
Generate due invoices
```

Then review generated invoices in:

```txt
/invoices
```

---

# 30. Review Advanced Singapore Estimate Modules

Optional monthly review:

## CPF Estimate

Open:

```txt
/reports/cpf-estimate
```

Use for educational payroll planning only.

## Corporate Tax Estimate

Open:

```txt
/reports/corporate-tax
```

Use as a rough estimate only.

## Multi-Currency Reference

Open:

```txt
/reports/multi-currency
```

Use for understanding foreign currency concepts.

---

# 31. Investigate and Correct Errors

If you find an incorrect posted journal entry:

1. Open:

```txt
/settings/database/journal
```

2. Confirm the issue.
3. If you are an admin, use reversal with a clear reason.

Example reason:

```txt
Incorrect expense account used during February review.
```

Do not delete posted history casually.

Use reversals.

---

# 32. Month-End Review Checklist

Use this checklist before considering the month reviewed.

## Setup

- [ ] Correct organization selected
- [ ] Chart of accounts reviewed
- [ ] Customers reviewed
- [ ] Vendors reviewed

## Sales

- [ ] All invoices entered
- [ ] Invoice GST reviewed
- [ ] Customer payments recorded
- [ ] AR Aging reviewed

## Purchases

- [ ] All bills entered
- [ ] Bill GST input tax reviewed
- [ ] Vendor payments recorded
- [ ] AP Aging reviewed

## Bank

- [ ] Bank CSV uploaded
- [ ] Transactions categorized
- [ ] Relevant transactions posted
- [ ] Transactions reconciled
- [ ] Duplicate bank posting avoided

## Ledger

- [ ] Journal diagnostics reviewed
- [ ] Journal balance SQL returns zero rows
- [ ] Reversals reviewed

## Reports

- [ ] Profit & Loss reviewed
- [ ] Balance Sheet reviewed
- [ ] GST report reviewed
- [ ] AR/AP Aging reviewed

## Controls

- [ ] Audit log reviewed
- [ ] Admin-only actions checked
- [ ] Background jobs checked

---

# 33. Suggested Monthly Notes Template

Create a monthly note outside the app or in your internal documentation.

Example:

```md
# Monthly Accounting Review — February 2026

Company: Merlion Creative Pte. Ltd.
Reviewed by:
Review date:

## Sales

Invoices reviewed:
Customer payments reviewed:
AR Aging notes:

## Purchases

Bills reviewed:
Vendor payments reviewed:
AP Aging notes:

## Bank

CSV imported:
Transactions reconciled:
Unusual bank items:

## Reports

Profit & Loss reviewed:
Balance Sheet reviewed:
GST report reviewed:

## Corrections

Reversals posted:
Reason:

## Follow-ups

- 
```

---

# 34. Recommended Monthly Accounting Controls

For stronger control:

```txt
Separate data entry and review roles.
Require admin approval for reversals.
Review audit logs monthly.
Lock closed periods in future versions.
Export key reports monthly.
Back up database before major corrections.
```

---

# 35. Common Monthly Issues

## Issue: Reports Do Not Match Expectations

Check:

```txt
Date range
Active organization
Unposted bank transactions
Unpaid invoices/bills
Reversed entries
Duplicate postings
Missing bills
Missing invoices
```

---

## Issue: GST Looks Wrong

Check:

```txt
Invoice GST rates
Bill GST rates
GST Input/Output accounts
Date range
Reversals
```

---

## Issue: Bank Balance Looks Wrong

Check:

```txt
Duplicate payment posting
Bank CSV posted rows
Unreconciled transactions
Manual journal entries
Vendor payments
Customer payments
```

---

## Issue: AR Aging Has Old Invoices

Check whether payments were recorded.

If customer paid but invoice still open, record payment from invoice detail page.

---

## Issue: AP Aging Has Old Bills

Check whether vendor payments were recorded.

If paid, record payment from bill detail page.

---

# 36. Month-End Completion

The month is ready for accountant review when:

```txt
All known invoices are entered.
All known bills are entered.
Payments are recorded.
Bank transactions are reconciled.
Reports have been reviewed.
Audit logs have been checked.
Known corrections are documented.
```

If the company is GST-registered, have a qualified person review the GST report before filing.

---

# 37. Final Monthly Workflow Summary

The monthly workflow is:

```txt
1. Select company.
2. Review accounts.
3. Review customers/vendors.
4. Enter invoices.
5. Enter bills.
6. Record payments.
7. Import bank statement.
8. Categorize bank transactions.
9. Post relevant bank transactions.
10. Reconcile bank transactions.
11. Review journal.
12. Review reports.
13. Review audit logs.
14. Correct with reversals if needed.
15. Document month-end notes.
```

The most important monthly control:

```txt
Journal balance check must return zero unbalanced entries.
```

The second most important control:

```txt
Reports must be reviewed using the correct company and date range.
```
