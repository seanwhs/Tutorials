# Appendix A — Accounting Cheat Sheet

This appendix is a quick-reference guide to the accounting concepts used throughout **GreyMatter Ledger**.

It is written for developers, not accountants.

The goal is to help you understand what the code is doing when it creates accounts, posts journal entries, generates reports, records invoices, records bills, and handles payments.

This appendix is educational and simplified. Real accounting can involve additional rules, judgment, tax treatment, compliance requirements, and professional review.

---

# 1. The Big Picture

Accounting software is not just about storing invoices and bills.

At the center of a serious accounting system is the **ledger**.

In GreyMatter Ledger, the ledger is represented mainly by:

```txt
journal_entries
journal_lines
```

Every important financial event eventually becomes a journal entry.

Examples:

```txt
Customer invoice issued
Customer payment received
Vendor bill received
Vendor payment made
Bank transaction posted
Manual adjustment posted
Journal entry reversed
```

The central rule is:

```txt
Total debits must equal total credits.
```

If that rule is broken, the accounting system cannot be trusted.

---

# 2. The Accounting Equation

The core accounting equation is:

```txt
Assets = Liabilities + Equity
```

In plain English:

```txt
What the business owns = what the business owes + what belongs to owners
```

Example:

```txt
Business bank balance:       S$10,000
Loan owed to bank:           S$4,000
Owner's remaining claim:     S$6,000
```

So:

```txt
Assets      = Liabilities + Equity
S$10,000    = S$4,000 + S$6,000
```

The equation balances.

---

## Expanded Equation

Income and expenses affect equity.

A more expanded version is:

```txt
Assets = Liabilities + Equity + Income - Expenses
```

Why?

Because:

```txt
Income increases profit.
Expenses reduce profit.
Profit increases equity.
Losses reduce equity.
```

At reporting time, Profit & Loss results eventually flow into equity as:

```txt
Current Year Earnings
```

---

# 3. The Five Account Types

GreyMatter Ledger uses five main account types:

```txt
asset
liability
equity
income
expense
```

These account types appear in the chart of accounts.

---

## Asset

Assets are things the business owns or controls.

Examples:

```txt
1000 Bank
1010 Cash on Hand
1100 Accounts Receivable
1200 Inventory
1400 GST Input Tax
1600 Fixed Assets
```

Plain English:

```txt
Assets are useful resources.
```

Examples:

```txt
Money in the bank
Money customers owe you
Equipment your business owns
GST you may be able to claim
```

---

## Liability

Liabilities are things the business owes.

Examples:

```txt
2000 Accounts Payable
2100 GST Payable
2110 GST Output Tax
2200 Accrued Expenses
2300 Loans Payable
2400 Customer Deposits
```

Plain English:

```txt
Liabilities are obligations.
```

Examples:

```txt
Money owed to vendors
GST collected from customers
Loans to repay
Deposits received before delivering work
```

---

## Equity

Equity is the owners’ claim in the business after liabilities.

Examples:

```txt
3000 Share Capital
3100 Retained Earnings
3200 Current Year Earnings
```

Plain English:

```txt
Equity is what belongs to the owners after debts are considered.
```

Formula:

```txt
Equity = Assets - Liabilities
```

---

## Income

Income is revenue earned by the business.

Examples:

```txt
4000 Sales Revenue
4100 Service Revenue
4200 Other Income
```

Plain English:

```txt
Income is money earned from business activity.
```

Examples:

```txt
Consulting fees
Product sales
Subscription revenue
Service revenue
```

---

## Expense

Expenses are costs incurred by the business.

Examples:

```txt
5000 Cost of Goods Sold
5100 Purchases
6000 Rent Expense
6100 Salaries and Wages
6200 CPF Employer Contributions
6300 Software and Subscriptions
6400 Professional Fees
6700 Bank Charges
7000 Income Tax Expense
```

Plain English:

```txt
Expenses are costs of running the business.
```

---

# 4. Debits and Credits

Debits and credits are accounting directions.

They do **not** mean:

```txt
Debit = good
Credit = bad
```

They also do **not** always mean:

```txt
Debit = increase
Credit = decrease
```

Whether a debit or credit increases an account depends on the account type.

---

# 5. Normal Balances

Each account type has a normal balance.

The normal balance tells us which side usually increases the account.

| Account Type | Normal Balance | Increases With | Decreases With |
|---|---:|---:|---:|
| Asset | Debit | Debit | Credit |
| Expense | Debit | Debit | Credit |
| Liability | Credit | Credit | Debit |
| Equity | Credit | Credit | Debit |
| Income | Credit | Credit | Debit |

A useful shortcut:

```txt
Assets and expenses increase with debits.
Liabilities, equity, and income increase with credits.
```

---

## Debit-Normal Accounts

These increase with debits:

```txt
Assets
Expenses
```

Examples:

```txt
Debit Bank                  increases Bank
Debit Accounts Receivable   increases AR
Debit Rent Expense          increases Rent Expense
Debit GST Input Tax         increases GST Input Tax
```

---

## Credit-Normal Accounts

These increase with credits:

```txt
Liabilities
Equity
Income
```

Examples:

```txt
Credit Accounts Payable     increases AP
Credit GST Output Tax       increases GST collected liability
Credit Share Capital        increases Equity
Credit Sales Revenue        increases Income
```

---

# 6. Journal Entries

A journal entry records a financial event.

A journal entry has:

```txt
Date
Memo
Lines
```

Example:

```txt
Date: 2026-01-05
Memo: Invoice INV-0001 issued to Merlion Trading
```

The lines might be:

```txt
Debit  Accounts Receivable   S$109.00
Credit Sales Revenue         S$100.00
Credit GST Output Tax        S$9.00
```

The journal entry balances because:

```txt
Total debits  = S$109.00
Total credits = S$109.00
```

---

# 7. Journal Lines

A journal line is one debit or credit to one account.

Example:

```txt
Debit Bank S$100.00
```

In GreyMatter Ledger, a journal line has:

```txt
journal_entry_id
organization_id
account_id
line_number
description
debit_cents
credit_cents
```

A valid line must have exactly one side:

```txt
Debit amount > 0 and credit amount = 0
```

or:

```txt
Credit amount > 0 and debit amount = 0
```

Invalid:

```txt
Debit S$100 and Credit S$100 on the same line
```

Invalid:

```txt
Debit S$0 and Credit S$0
```

---

# 8. Balanced Entries

A journal entry is balanced when:

```txt
Total debit cents = total credit cents
```

Example:

```txt
Debit  Bank           S$100.00
Credit Sales Revenue  S$100.00
```

Balanced:

```txt
Debits  = S$100.00
Credits = S$100.00
```

---

## Unbalanced Entry

Invalid:

```txt
Debit  Bank           S$100.00
Credit Sales Revenue  S$90.00
```

Because:

```txt
Debits  = S$100.00
Credits = S$90.00
Difference = S$10.00
```

GreyMatter Ledger must reject this.

---

# 9. Why Money Is Stored as Integer Cents

Never store money as floating-point dollars.

Bad:

```ts
const amount = 109.99;
```

Good:

```ts
const amountCents = 10999;
```

Why?

Because JavaScript floating-point math can produce surprises:

```ts
0.1 + 0.2
```

Result:

```txt
0.30000000000000004
```

That is unacceptable in accounting software.

So GreyMatter Ledger stores:

```txt
S$100.00 as 10000
S$9.00 as 900
S$109.00 as 10900
```

---

# 10. Chart of Accounts

The chart of accounts is the official list of accounts a company uses.

Examples:

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

Think of the chart of accounts as labeled drawers.

Every journal line must be filed into one drawer.

---

## Account Codes

Account codes help organize accounts.

Typical ranges:

```txt
1000–1999 Assets
2000–2999 Liabilities
3000–3999 Equity
4000–4999 Income
5000–7999 Expenses
```

GreyMatter Ledger uses organization-scoped account codes.

This means this is allowed:

```txt
Company A: 1000 Bank
Company B: 1000 Bank
```

But this is not allowed:

```txt
Company A: 1000 Bank
Company A: 1000 Operating Bank
```

Because duplicate codes inside the same organization are confusing.

---

# 11. Common Business Transactions

This section shows the most important entries used in GreyMatter Ledger.

---

# 12. Owner Contributes Cash

Scenario:

```txt
Owner puts S$10,000 into the company bank account.
```

Entry:

```txt
Debit  Bank            S$10,000.00
Credit Share Capital   S$10,000.00
```

Why?

```txt
Bank increases.
Equity increases.
```

Account behavior:

```txt
Bank is an asset -> increases with debit.
Share Capital is equity -> increases with credit.
```

---

# 13. Customer Invoice with GST

Scenario:

```txt
We issue an invoice for S$109.00 including 9% GST.
Revenue before GST is S$100.00.
GST is S$9.00.
```

Entry:

```txt
Debit  Accounts Receivable   S$109.00
Credit Sales Revenue         S$100.00
Credit GST Output Tax        S$9.00
```

Why?

```txt
Customer owes us S$109.00.
We earned S$100.00 revenue.
We collected S$9.00 GST that may be payable to IRAS.
```

Account behavior:

```txt
Accounts Receivable is an asset -> debit increases it.
Sales Revenue is income -> credit increases it.
GST Output Tax is a liability -> credit increases it.
```

---

# 14. Customer Payment

Scenario:

```txt
Customer pays the S$109.00 invoice.
```

Entry:

```txt
Debit  Bank                  S$109.00
Credit Accounts Receivable   S$109.00
```

Why?

```txt
Bank increases.
Customer no longer owes us.
```

Important:

```txt
Do not credit Sales Revenue again.
```

Revenue was already recorded when the invoice was issued.

The payment settles the receivable.

---

# 15. Vendor Bill with GST

Scenario:

```txt
We receive a vendor bill for S$109.00 including 9% GST.
Purchase before GST is S$100.00.
GST is S$9.00.
```

Entry:

```txt
Debit  Purchases             S$100.00
Debit  GST Input Tax         S$9.00
Credit Accounts Payable      S$109.00
```

Why?

```txt
We incurred S$100.00 of purchase cost.
We paid or owe S$9.00 GST that may be claimable.
We owe the vendor S$109.00.
```

Account behavior:

```txt
Purchases is an expense -> debit increases it.
GST Input Tax is an asset -> debit increases it.
Accounts Payable is a liability -> credit increases it.
```

---

# 16. Vendor Payment

Scenario:

```txt
We pay the S$109.00 vendor bill.
```

Entry:

```txt
Debit  Accounts Payable      S$109.00
Credit Bank                  S$109.00
```

Why?

```txt
Vendor payable decreases.
Bank decreases.
```

Important:

```txt
Do not debit Purchases again.
```

The expense was already recorded when the bill was entered.

The payment settles the payable.

---

# 17. Bank Charge

Scenario:

```txt
The bank charges S$25.00.
```

Entry:

```txt
Debit  Bank Charges          S$25.00
Credit Bank                  S$25.00
```

Why?

```txt
Expense increases.
Bank decreases.
```

---

# 18. Software Subscription Paid Immediately

Scenario:

```txt
We pay S$109.00 for software, including S$9.00 GST.
```

If recording directly from bank:

```txt
Debit  Software and Subscriptions   S$100.00
Debit  GST Input Tax                S$9.00
Credit Bank                         S$109.00
```

Why?

```txt
Expense increases.
Claimable GST input tax increases.
Bank decreases.
```

---

# 19. Customer Deposit Received

Scenario:

```txt
Customer pays S$500 before we deliver work.
```

Entry:

```txt
Debit  Bank                  S$500.00
Credit Customer Deposits     S$500.00
```

Why?

```txt
Bank increases.
We now owe goods/services to the customer.
```

Customer Deposits is a liability.

Revenue should usually wait until goods/services are delivered.

---

# 20. Loan Received

Scenario:

```txt
Business receives S$20,000 loan proceeds.
```

Entry:

```txt
Debit  Bank             S$20,000.00
Credit Loans Payable    S$20,000.00
```

Why?

```txt
Bank increases.
Liability increases.
```

---

# 21. Loan Repayment

Scenario:

```txt
Business repays S$1,000 loan principal.
```

Entry:

```txt
Debit  Loans Payable    S$1,000.00
Credit Bank             S$1,000.00
```

If interest is included, split it:

```txt
Debit  Loans Payable       S$900.00
Debit  Interest Expense    S$100.00
Credit Bank                S$1,000.00
```

Why?

```txt
Principal reduces liability.
Interest is an expense.
Bank decreases.
```

---

# 22. GST Output Tax vs GST Input Tax

GreyMatter Ledger uses:

```txt
2110 GST Output Tax
1400 GST Input Tax
```

---

## GST Output Tax

GST Output Tax is GST collected from customers.

Example:

```txt
Credit GST Output Tax S$9.00
```

It is usually a liability because the business may owe it to IRAS.

---

## GST Input Tax

GST Input Tax is GST paid on purchases.

Example:

```txt
Debit GST Input Tax S$9.00
```

It is treated as an asset in this tutorial because it may be claimable from IRAS.

---

## Net GST

Simplified:

```txt
Net GST Payable = GST Output Tax - GST Input Tax
```

Example:

```txt
GST Output Tax: S$900
GST Input Tax:  S$300
Net GST:        S$600 payable
```

If input tax is larger:

```txt
GST Output Tax: S$300
GST Input Tax:  S$900
Net GST:        S$600 refundable
```

---

# 23. Profit & Loss Report

The Profit & Loss report shows income and expenses for a period.

Formula:

```txt
Net Profit = Income - Expenses
```

It includes:

```txt
Income accounts
Expense accounts
```

Examples:

```txt
4000 Sales Revenue
4100 Service Revenue
5100 Purchases
6000 Rent Expense
6300 Software and Subscriptions
```

It generally does **not** include:

```txt
Bank
Accounts Receivable
Accounts Payable
GST Input Tax
GST Output Tax
Share Capital
```

Those are Balance Sheet accounts.

---

# 24. Balance Sheet Report

The Balance Sheet shows financial position as of a date.

Formula:

```txt
Assets = Liabilities + Equity
```

It includes:

```txt
Asset accounts
Liability accounts
Equity accounts
Current Year Earnings
```

Current Year Earnings comes from:

```txt
Income - Expenses
```

This allows profit or loss to flow into equity.

---

# 25. AR Aging

AR means:

```txt
Accounts Receivable
```

AR Aging shows unpaid customer invoices grouped by how overdue they are.

Examples:

```txt
Current
1–30 days overdue
31–60 days overdue
61–90 days overdue
90+ days overdue
```

Purpose:

```txt
Help collect money from customers.
```

---

# 26. AP Aging

AP means:

```txt
Accounts Payable
```

AP Aging shows unpaid vendor bills grouped by due date.

Purpose:

```txt
Help manage vendor payments.
```

---

# 27. Bank Reconciliation

Bank reconciliation checks whether the app’s bank ledger agrees with the real bank statement.

A simple workflow:

```txt
Import bank CSV
Categorize transaction
Post to ledger
Mark reconciled
```

A posted bank transaction affects the ledger.

A reconciled bank transaction confirms it against the bank statement.

---

# 28. Reversals

A reversal cancels a posted journal entry by swapping debits and credits.

Original:

```txt
Debit  Rent Expense   S$500.00
Credit Bank           S$500.00
```

Reversal:

```txt
Debit  Bank           S$500.00
Credit Rent Expense   S$500.00
```

Net effect:

```txt
Rent Expense = 0
Bank = 0
```

Why reverse instead of delete?

```txt
To preserve audit history.
```

---

# 29. Audit Logs

Audit logs record operational actions.

Examples:

```txt
Customer created
Invoice created
Bill created
Payment recorded
Journal entry reversed
Bank transaction posted
```

Audit logs answer:

```txt
Who did what?
When?
To which record?
```

Audit logs do not replace the journal.

The journal records accounting effect.

The audit log records system activity.

---

# 30. Common Mistakes to Avoid

## Mistake 1 — Recording Revenue Again on Payment

Wrong:

```txt
Debit  Bank
Credit Sales Revenue
```

when collecting an invoice that was already posted.

Correct:

```txt
Debit  Bank
Credit Accounts Receivable
```

---

## Mistake 2 — Recording Expense Again on Vendor Payment

Wrong:

```txt
Debit  Expense
Credit Bank
```

when paying a bill already recorded.

Correct:

```txt
Debit  Accounts Payable
Credit Bank
```

---

## Mistake 3 — Posting Unbalanced Entries

Wrong:

```txt
Debit  Bank           S$100
Credit Sales Revenue  S$90
```

Correct:

```txt
Debit  Bank           S$100
Credit Sales Revenue  S$100
```

---

## Mistake 4 — Using Floating-Point Money

Wrong:

```ts
const gst = 100.00 * 0.09;
```

Better:

```ts
const gstCents = Math.round((10000 * 900) / 10000);
```

---

## Mistake 5 — Deleting Posted Entries

Wrong:

```txt
Delete journal entry from database.
```

Correct:

```txt
Post a reversing journal entry.
```

---

## Mistake 6 — Reporting from Source Documents Only

Risky:

```txt
Profit & Loss from invoices and bills only.
```

Better:

```txt
Profit & Loss from journal lines.
```

Why?

Because journal lines are the accounting source of truth.

---

# 31. Developer Mental Model

For developers, the accounting model can be summarized like this:

```txt
Accounts are categories.
Journal lines move values between categories.
Journal entries group lines into balanced events.
Reports summarize journal lines.
Business documents explain why journal entries exist.
```

In code:

```txt
Invoice
  -> create invoice row
  -> create invoice lines
  -> post journal entry

Bill
  -> create bill row
  -> create bill lines
  -> post journal entry

Payment
  -> create payment row
  -> post journal entry

Report
  -> read journal lines
  -> group by account type
  -> calculate balances
```

---

# 32. Core GreyMatter Ledger Posting Patterns

## Invoice Posting

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

## Customer Payment Posting

```txt
Debit  Bank
Credit Accounts Receivable
```

## Bill Posting

```txt
Debit  Purchases / Expense
Debit  GST Input Tax
Credit Accounts Payable
```

## Vendor Payment Posting

```txt
Debit  Accounts Payable
Credit Bank
```

## Bank Inflow Posting

```txt
Debit  Bank
Credit Category Account
```

## Bank Outflow Posting

```txt
Debit  Category Account
Credit Bank
```

## Reversal Posting

```txt
Swap every debit and credit from the original entry.
```

---

# 33. Final Quick Reference Table

| Event | Debit | Credit |
|---|---|---|
| Owner contributes cash | Bank | Share Capital |
| Invoice issued | Accounts Receivable | Sales Revenue, GST Output Tax |
| Customer pays invoice | Bank | Accounts Receivable |
| Vendor bill received | Expense/Purchases, GST Input Tax | Accounts Payable |
| Vendor bill paid | Accounts Payable | Bank |
| Bank fee | Bank Charges | Bank |
| Loan received | Bank | Loans Payable |
| Loan principal repaid | Loans Payable | Bank |
| Customer deposit received | Bank | Customer Deposits |
| Bank import inflow | Bank | Category Account |
| Bank import outflow | Category Account | Bank |
| Reversal | Original credits | Original debits |

---

# 34. Final Rule to Remember

If you remember only one accounting rule from this appendix, remember this:

```txt
Every journal entry must balance.
```

In code, that means:

```ts
totalDebitCents === totalCreditCents
```

If that is false:

```txt
Do not post the entry.
```

The second rule:

```txt
Reports should come from journal lines.
```

The third rule:

```txt
Never erase accounting history casually. Reverse it.
```

These three rules are the backbone of GreyMatter Ledger.
