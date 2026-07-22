# Primer 1 — Double-Entry Accounting for Developers

**Product:** GreyMatter Ledger  
**Document type:** Primer  
**Audience:** Software developers, technical founders, product engineers, and non-accountants  
**Goal:** Explain double-entry accounting in a developer-friendly way before working with the ledger engine  

---

# 1. Why Developers Need to Understand Accounting

If you are building accounting software, you cannot treat financial records as ordinary CRUD data.

A normal CRUD app might let users create, update, and delete records freely.

Accounting software is different.

Accounting software needs to preserve financial truth.

That means:

```txt
Money cannot appear from nowhere.
Money cannot disappear without explanation.
Every financial event must be balanced.
```

In GreyMatter Ledger, the core rule is:

```txt
Total debits must equal total credits.
```

This rule is enforced by the journal engine.

If you understand this primer, the database schema, services, reports, invoices, bills, and payments will make much more sense.

---

# 2. The Simplest Mental Model

Think of accounting like moving water between buckets.

Each bucket is an account.

Examples of buckets:

```txt
Bank
Accounts Receivable
Sales Revenue
GST Output Tax
Accounts Payable
Rent Expense
```

When something happens, water moves between buckets.

But the total movement must be explainable.

If one bucket receives value, another bucket must explain where that value came from.

That is double-entry accounting.

---

# 3. The Core Accounting Equation

The most important accounting equation is:

```txt
Assets = Liabilities + Equity
```

In plain English:

```txt
What the business owns = what the business owes + what belongs to owners
```

Example:

```txt
Bank account:        S$10,000
Loan owed:           S$4,000
Owner's claim:       S$6,000
```

So:

```txt
Assets      = Liabilities + Equity
S$10,000    = S$4,000 + S$6,000
```

The equation balances.

---

# 4. Expanded Accounting Equation

Income and expenses affect equity.

The expanded equation is:

```txt
Assets = Liabilities + Equity + Income - Expenses
```

Why?

Because:

```txt
Income increases business value.
Expenses decrease business value.
Profit increases equity.
Loss decreases equity.
```

At reporting time, income minus expenses becomes:

```txt
Current Year Earnings
```

which is part of equity on the Balance Sheet.

---

# 5. The Five Account Types

GreyMatter Ledger uses five core account types:

```txt
asset
liability
equity
income
expense
```

Every account belongs to one of these types.

---

## 5.1 Assets

Assets are things the business owns or controls.

Examples:

```txt
Bank
Cash on Hand
Accounts Receivable
Inventory
GST Input Tax
Fixed Assets
```

Plain English:

```txt
Assets are useful resources.
```

Assets normally increase with debits.

---

## 5.2 Liabilities

Liabilities are things the business owes.

Examples:

```txt
Accounts Payable
GST Output Tax
Loans Payable
Customer Deposits
Accrued Expenses
```

Plain English:

```txt
Liabilities are obligations.
```

Liabilities normally increase with credits.

---

## 5.3 Equity

Equity is the owner’s claim in the business after liabilities.

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

## 5.4 Income

Income is revenue earned by the business.

Examples:

```txt
Sales Revenue
Service Revenue
Other Income
```

Income normally increases with credits.

---

## 5.5 Expenses

Expenses are costs incurred by the business.

Examples:

```txt
Rent Expense
Purchases
Software and Subscriptions
Bank Charges
Professional Fees
CPF Employer Contributions
```

Expenses normally increase with debits.

---

# 6. Debits and Credits Are Directions

A common beginner mistake is thinking:

```txt
Debit = good
Credit = bad
```

That is wrong.

Debits and credits are directions.

Whether they increase or decrease an account depends on the account type.

---

# 7. Normal Balances

Each account type has a normal balance.

The normal balance tells you which side increases the account.

| Account Type | Normal Balance | Increases With | Decreases With |
|---|---:|---:|---:|
| Asset | Debit | Debit | Credit |
| Expense | Debit | Debit | Credit |
| Liability | Credit | Credit | Debit |
| Equity | Credit | Credit | Debit |
| Income | Credit | Credit | Debit |

Shortcut:

```txt
Assets and expenses increase with debits.
Liabilities, equity, and income increase with credits.
```

---

# 8. Journal Entries

A journal entry records one financial event.

A journal entry has:

```txt
Date
Memo
Lines
```

Example:

```txt
Date: 2026-01-05
Memo: Invoice INV-2026-0001 issued to Orchard Retail Group
```

The lines might be:

```txt
Debit  Accounts Receivable   S$109.00
Credit Sales Revenue         S$100.00
Credit GST Output Tax        S$9.00
```

The journal entry is valid because:

```txt
Total debits  = S$109.00
Total credits = S$109.00
```

---

# 9. Journal Lines

A journal line is one debit or credit to one account.

Example:

```txt
Debit Bank S$100.00
```

Another example:

```txt
Credit Sales Revenue S$100.00
```

In GreyMatter Ledger, a line contains:

```txt
account_id
debit_cents
credit_cents
description
line_number
```

A valid line must have exactly one side.

Valid:

```txt
Debit S$100, Credit S$0
```

Valid:

```txt
Debit S$0, Credit S$100
```

Invalid:

```txt
Debit S$100, Credit S$100
```

Invalid:

```txt
Debit S$0, Credit S$0
```

---

# 10. Balanced Entries

A journal entry is balanced when:

```txt
Total debit amount = total credit amount
```

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

The invalid entry is rejected because:

```txt
S$100 ≠ S$90
```

In code:

```ts
if (totalDebitCents !== totalCreditCents) {
  throw new Error("Journal entry is unbalanced.");
}
```

---

# 11. Why Accounting Software Cannot Just “Update a Balance”

A naive finance app might store balances directly:

```txt
bank_balance = 10000
revenue = 5000
```

Then update those numbers directly.

That is dangerous.

Why?

Because you lose the story of how the balance changed.

Accounting software should store the transaction history.

Balances should be calculated from journal lines.

Better:

```txt
journal_entries
journal_lines
```

Then reports calculate:

```txt
Bank balance = sum debits and credits to Bank
Revenue = sum credits and debits to Revenue
```

This gives traceability.

---

# 12. Source Documents vs Journal Entries

A source document explains what happened.

A journal entry records the accounting effect.

Examples of source documents:

```txt
Invoice
Bill
Customer payment
Vendor payment
Bank transaction
```

Examples of journal entries:

```txt
Debit Accounts Receivable, Credit Sales Revenue
Debit Purchases, Credit Accounts Payable
Debit Bank, Credit Accounts Receivable
```

In GreyMatter Ledger:

```txt
Invoices and bills are source documents.
Journal entries are accounting truth.
```

---

# 13. Invoice Example

Scenario:

```txt
Merlion Creative invoices Orchard Retail Group for S$109.00.
The invoice includes S$100.00 service revenue and S$9.00 GST.
```

Journal entry:

```txt
Debit  Accounts Receivable   S$109.00
Credit Sales Revenue         S$100.00
Credit GST Output Tax        S$9.00
```

Explanation:

```txt
Customer owes us S$109.
We earned S$100.
We collected S$9 GST.
```

Why it balances:

```txt
Debits  = S$109
Credits = S$100 + S$9 = S$109
```

---

# 14. Customer Payment Example

Scenario:

```txt
Customer pays the S$109 invoice.
```

Journal entry:

```txt
Debit  Bank                  S$109.00
Credit Accounts Receivable   S$109.00
```

Explanation:

```txt
Bank increases.
Customer no longer owes us.
```

Important:

```txt
Do not credit revenue again.
```

Revenue was already recorded when the invoice was issued.

---

# 15. Bill Example

Scenario:

```txt
Cloud vendor sends a bill for S$109.00.
The bill includes S$100.00 service cost and S$9.00 GST.
```

Journal entry:

```txt
Debit  Purchases             S$100.00
Debit  GST Input Tax         S$9.00
Credit Accounts Payable      S$109.00
```

Explanation:

```txt
Expense increases by S$100.
Claimable GST input tax increases by S$9.
We owe the vendor S$109.
```

Why it balances:

```txt
Debits  = S$100 + S$9 = S$109
Credits = S$109
```

---

# 16. Vendor Payment Example

Scenario:

```txt
We pay the S$109 vendor bill.
```

Journal entry:

```txt
Debit  Accounts Payable      S$109.00
Credit Bank                  S$109.00
```

Explanation:

```txt
Vendor payable decreases.
Bank decreases.
```

Important:

```txt
Do not debit expense again.
```

The expense was already recorded when the bill was received.

---

# 17. Bank Transaction Example

Scenario:

```txt
Bank statement shows a S$15 bank charge.
```

Journal entry:

```txt
Debit  Bank Charges          S$15.00
Credit Bank                  S$15.00
```

Explanation:

```txt
Bank charge expense increases.
Bank balance decreases.
```

---

# 18. Reversal Example

Scenario:

```txt
A S$500 rent expense was posted by mistake.
```

Original entry:

```txt
Debit  Rent Expense   S$500
Credit Bank           S$500
```

Reversal entry:

```txt
Debit  Bank           S$500
Credit Rent Expense   S$500
```

Together, they cancel out.

Why not delete the original?

Because accounting history should be preserved.

---

# 19. How Reports Use Journal Lines

Reports should summarize journal lines.

---

## Profit & Loss

Uses:

```txt
income
expense
```

Formula:

```txt
Net Profit = Income - Expenses
```

---

## Balance Sheet

Uses:

```txt
asset
liability
equity
```

Formula:

```txt
Assets = Liabilities + Equity
```

Also includes:

```txt
Current Year Earnings = Income - Expenses
```

---

## GST Report

Uses:

```txt
GST Output Tax
GST Input Tax
```

Formula:

```txt
Net GST = GST Output Tax - GST Input Tax
```

---

# 20. Why Payments Do Not Duplicate Revenue or Expense

This is one of the most important beginner concepts.

---

## Invoice Then Payment

Invoice:

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

Payment:

```txt
Debit  Bank
Credit Accounts Receivable
```

Revenue appears only once.

---

## Bill Then Payment

Bill:

```txt
Debit  Expense
Debit  GST Input Tax
Credit Accounts Payable
```

Payment:

```txt
Debit  Accounts Payable
Credit Bank
```

Expense appears only once.

---

# 21. Money as Integer Cents

In code, never use floating-point dollars for stored amounts.

Bad:

```ts
const amount = 109.99;
```

Good:

```ts
const amountCents = 10999;
```

Why?

JavaScript can produce floating-point surprises:

```ts
0.1 + 0.2
```

Result:

```txt
0.30000000000000004
```

Accounting systems should avoid that.

---

# 22. Basis Points

Basis points are used to represent percentages as integers.

```txt
1% = 100 basis points
9% = 900 basis points
17% = 1700 basis points
```

Examples:

```txt
GST 9% = 900
Corporate tax 17% = 1700
CPF employee 20% = 2000
```

This avoids storing rates as floating-point values.

---

# 23. How GreyMatter Ledger Enforces Accounting Rules

The main function is:

```ts
postJournalEntry()
```

It validates:

```txt
Active organization exists
Date is valid
Memo is present
At least two lines exist
Each line references an account
Amounts are integer cents
Amounts are non-negative
Each line has exactly one side
Debits equal credits
Accounts belong to the active organization
Accounts are active
```

If any rule fails, the entry is rejected.

---

# 24. Developer View of an Invoice Posting

A simplified invoice creation flow:

```txt
User submits invoice form
  |
  v
Server action receives form data
  |
  v
Invoice service validates customer and line
  |
  v
GST helper calculates totals
  |
  v
Invoice row inserted
  |
  v
Invoice line row inserted
  |
  v
Journal entry posted
  |
  v
Invoice linked to journal entry
```

Accounting entry:

```txt
Debit AR total
Credit Revenue subtotal
Credit GST output tax GST
```

---

# 25. Developer View of a Report

A report flow:

```txt
User opens Profit & Loss
  |
  v
Report service queries journal lines
  |
  v
Join accounts
  |
  v
Group by account type
  |
  v
Calculate signed balances
  |
  v
Render report
```

This is why journal lines are central.

---

# 26. Common Developer Mistakes

## Mistake 1 — Updating Balances Directly

Bad:

```ts
bank.balance += 10000;
```

Better:

```txt
Post journal entry.
Calculate balance from journal lines.
```

---

## Mistake 2 — Skipping Journal Entry for Source Document

Bad:

```txt
Create invoice row only.
```

Better:

```txt
Create invoice row.
Create journal entry.
Link invoice to journal entry.
```

---

## Mistake 3 — Trusting UI Math

The UI can show helpful calculations, but server-side logic must recalculate and validate.

---

## Mistake 4 — Using Floats

Bad:

```ts
const gst = subtotal * 0.09;
```

Better:

```ts
const gstCents = Math.round((subtotalCents * 900) / 10000);
```

---

## Mistake 5 — Forgetting Organization Scope

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

---

# 27. Practice Questions

Use these to check your understanding.

---

## Question 1

A customer invoice is issued for S$218.00 including 9% GST.

What is the journal entry?

Answer:

```txt
Debit  Accounts Receivable   S$218.00
Credit Sales Revenue         S$200.00
Credit GST Output Tax        S$18.00
```

---

## Question 2

The customer pays the invoice.

What is the journal entry?

Answer:

```txt
Debit  Bank                  S$218.00
Credit Accounts Receivable   S$218.00
```

---

## Question 3

A vendor bill is received for S$327.00 including 9% GST.

What is the journal entry?

Answer:

```txt
Debit  Purchases             S$300.00
Debit  GST Input Tax         S$27.00
Credit Accounts Payable      S$327.00
```

---

## Question 4

The vendor bill is paid.

What is the journal entry?

Answer:

```txt
Debit  Accounts Payable      S$327.00
Credit Bank                  S$327.00
```

---

## Question 5

Why should reports come from journal lines?

Answer:

```txt
Because journal lines are the accounting source of truth.
```

---

# 28. Final Mental Model

For developers, double-entry accounting can be summarized as:

```txt
Accounts are categories.
Journal lines move value between categories.
Journal entries group lines into balanced events.
Reports summarize journal lines.
Business documents explain why journal entries exist.
```

In GreyMatter Ledger:

```txt
Invoices create receivables and revenue.
Bills create payables and expenses.
Payments settle receivables and payables.
Bank imports explain bank movement.
Reversals preserve correction history.
Reports read the ledger.
```

The most important rule:

```txt
No balanced journal entry, no posting.
```
