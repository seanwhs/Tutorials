## Appendix D Part 1: Common Business Transactions Cookbook — Revenue Side

This appendix is a practical reference: dozens of common real-world business transactions, each with the actual journal entry (which accounts, debit or credit) explained. Split across 3 notes: this one covers revenue-side transactions, Part 2 covers expense-side, Part 3 covers everything else.

---

### 1. Cash sale (customer pays immediately, no invoice)

Example: A retail shop sells $80 of merchandise, paid immediately by card.

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $80 | |
| Sales Income (Income) | | $80 |

Nothing touches Accounts Receivable here because there was never a period where the customer owed money.

### 2. Invoice sent to a customer (sale on credit, not yet paid)

Example: A consultant sends a $2,000 invoice for work completed, due in 30 days.

| Account | Debit | Credit |
|---|---|---|
| Accounts Receivable (Asset) | $2,000 | |
| Consulting Income (Income) | | $2,000 |

This is recorded the moment the invoice is sent (the work is done/earned), not when payment arrives — this is accrual accounting.

### 3. Customer pays that invoice in full

Example: 20 days later, the customer pays the $2,000 invoice from example 2 in full.

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $2,000 | |
| Accounts Receivable (Asset) | | $2,000 |

Notice Income is NOT touched again — it was already recorded in example 2. This transaction is purely about cash replacing a receivable.

### 4. Customer pays an invoice partially

Example: A $2,000 invoice; the customer pays $800 now and will pay the rest later.

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $800 | |
| Accounts Receivable (Asset) | | $800 |

The invoice's remaining open balance becomes $1,200 (tracked at the invoice/document level).

### 5. Customer pays with a discount for early payment

Example: A $1,000 invoice offers "2% off if paid within 10 days." The customer pays within the window, sending $980.

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $980 | |
| Sales Discounts (Contra-Income) | $20 | |
| Accounts Receivable (Asset) | | $1,000 |

The $20 discount is recorded as its own line so it explicitly shows up as a cost of offering the discount, rather than silently disappearing.

### 6. Customer payment that never arrives — writing off bad debt

Example: A $500 invoice from 6 months ago is deemed uncollectible.

| Account | Debit | Credit |
|---|---|---|
| Bad Debt Expense (Expense) | $500 | |
| Accounts Receivable (Asset) | | $500 |

This removes the amount from what's owed and records the loss as an expense.

### 7. Refunding a customer

Example: A customer who paid $300 for a service is refunded in full because the work wasn't completed satisfactorily, and no invoice remains open.

| Account | Debit | Credit |
|---|---|---|
| Sales Refunds (Contra-Income) | $300 | |
| Checking Account (Asset) | | $300 |

### 8. Sales tax collected from a customer

Example: A $100 sale in a jurisdiction with 8% sales tax — the customer pays $108 total.

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $108 | |
| Sales Income (Income) | | $100 |
| Sales Tax Payable (Liability) | | $8 |

A THREE-line entry (still balanced: $108 = $100 + $8). Sales tax collected is a Liability, not Income, because it doesn't belong to the business.

### 9. Remitting collected sales tax to the government

Example: At the end of the quarter, the business pays the $8 (accumulated across many sales) to the state tax authority.

| Account | Debit | Credit |
|---|---|---|
| Sales Tax Payable (Liability) | $8 | |
| Checking Account (Asset) | | $8 |

Income is never touched by this transaction — the tax was never the business's income to begin with.

### 10. Recording a deposit received in advance (unearned revenue)

Example: A customer pays a $1,000 deposit for a project that hasn't started yet.

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $1,000 | |
| Unearned Revenue (Liability) | | $1,000 |

Even though cash came in, it is NOT recorded as Income yet, because the work hasn't been done.

### 11. Recognizing that unearned revenue once work is completed

Example: The project from example 10 is now complete.

| Account | Debit | Credit |
|---|---|---|
| Unearned Revenue (Liability) | $1,000 | |
| Service Income (Income) | | $1,000 |

Now the liability is cleared and the income is finally recognized — matching exactly when the value was actually delivered.

### 12. Multiple invoices paid by a single customer payment (batch payment)

Example: A customer sends one $1,500 check covering three separate invoices ($500, $600, $400).

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $1,500 | |
| Accounts Receivable (Asset) | | $1,500 |

The journal entry itself is simple — the complexity is entirely in HOW that $1,500 gets allocated across the three specific open invoices at the document level.

---

## Appendix D Part 2: Common Business Transactions Cookbook — Expense Side

Continues directly from Part 1. This note covers bills, purchases, payroll, and other money-going-out transactions.

---

### 13. Paying a bill immediately (no credit period, cash expense)

Example: Buying $60 of office supplies, paid immediately by card.

| Account | Debit | Credit |
|---|---|---|
| Office Supplies Expense (Expense) | $60 | |
| Checking Account (Asset) | | $60 |

Simple, immediate cash-for-goods transaction — no Accounts Payable involved.

### 14. Receiving a bill from a vendor (expense on credit, not yet paid)

Example: An electric company sends a $200 bill, due in 30 days.

| Account | Debit | Credit |
|---|---|---|
| Utilities Expense (Expense) | $200 | |
| Accounts Payable (Liability) | | $200 |

Recorded the moment the bill is received, not when it's paid. This is the direct mirror of an invoice sent — just the reverse direction.

### 15. Paying that bill

Example: The $200 electric bill from example 14 is paid 25 days later.

| Account | Debit | Credit |
|---|---|---|
| Accounts Payable (Liability) | $200 | |
| Checking Account (Asset) | | $200 |

Expense is NOT recorded again — this transaction just clears the liability and reduces cash.

### 16. Buying inventory/materials on credit

Example: A retailer buys $3,000 of inventory from a supplier, on 30-day terms.

| Account | Debit | Credit |
|---|---|---|
| Inventory (Asset) | $3,000 | |
| Accounts Payable (Liability) | | $3,000 |

Inventory is recorded as an ASSET rather than an immediate Expense. It only becomes an expense (COGS) at the moment it's actually sold, not when purchased.

### 17. Selling inventory (recognizing COGS at the moment of sale)

Example: $500 worth of that inventory (at cost) is sold to a customer for $900.

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $900 | |
| Sales Income (Income) | | $900 |

...and separately:

| Account | Debit | Credit |
|---|---|---|
| Cost of Goods Sold (Expense) | $500 | |
| Inventory (Asset) | | $500 |

This is exactly how a $900 sale of $500-cost inventory produces a $400 Gross Profit — visible clearly because COGS was tracked as its own line.

### 18. Buying equipment (a fixed asset, not an immediate expense)

Example: Buying a $2,500 laptop for business use, paid immediately.

| Account | Debit | Credit |
|---|---|---|
| Computer Equipment (Asset, fixed_asset) | $2,500 | |
| Checking Account (Asset) | | $2,500 |

Not recorded as an expense — it's recorded as an Asset, because the laptop provides value over multiple years.

### 19. Depreciating a fixed asset over time

Example: That $2,500 laptop is expected to last 3 years. Using simple straight-line depreciation: $2,500 / 36 months ≈ $69/month.

| Account | Debit | Credit |
|---|---|---|
| Depreciation Expense (Expense) | $69 | |
| Accumulated Depreciation (Asset, contra-asset) | | $69 |

This entry repeats monthly. "Accumulated Depreciation" has a credit balance that offsets the asset's value on the Balance Sheet, so the laptop's "book value" declines over time.

### 20. Buying equipment on credit / financing

Example: A $10,000 piece of equipment is bought using a loan from the equipment seller.

| Account | Debit | Credit |
|---|---|---|
| Equipment (Asset, fixed_asset) | $10,000 | |
| Equipment Loan (Liability) | | $10,000 |

An Asset increasing is matched by a Liability increasing, since no cash changed hands yet.

### 21. Making a loan payment (principal + interest)

Example: A monthly loan payment of $500 total: $450 goes to reducing the loan balance (principal), $50 is interest expense.

| Account | Debit | Credit |
|---|---|---|
| Equipment Loan (Liability) | $450 | |
| Interest Expense (Expense) | $50 | |
| Checking Account (Asset) | | $500 |

A loan payment is NOT one simple expense — it's split between reducing a liability (principal) and a real expense (interest). Only the interest portion appears on the Profit & Loss report.

### 22. Running payroll (simplified single-employee example)

Example: An employee's gross pay is $3,000. After taxes withheld ($700 total), their net pay is $2,300.

| Account | Debit | Credit |
|---|---|---|
| Payroll Expense (Expense) | $3,000 | |
| Payroll Taxes Payable (Liability) | | $700 |
| Checking Account (Asset) | | $2,300 |

The FULL gross pay is the expense, not just the amount that hits the employee's bank account.

### 23. Remitting withheld payroll taxes to the government

Example: The $700 withheld in example 22 is paid to tax authorities.

| Account | Debit | Credit |
|---|---|---|
| Payroll Taxes Payable (Liability) | $700 | |
| Checking Account (Asset) | | $700 |

Same pattern as remitting sales tax — clearing a liability that was never really the business's money to keep.

### 24. Prepaying an expense (e.g., a year of insurance paid upfront)

Example: Paying $1,200 for a full year of business insurance, upfront.

| Account | Debit | Credit |
|---|---|---|
| Prepaid Insurance (Asset, other_current_asset) | $1,200 | |
| Checking Account (Asset) | | $1,200 |

Not recorded as an immediate expense — it's a resource the business will consume over the coming year.

### 25. Recognizing prepaid insurance as it's used up (monthly)

Example: One month later, 1/12 of the $1,200 prepaid insurance has been "used."

| Account | Debit | Credit |
|---|---|---|
| Insurance Expense (Expense) | $100 | |
| Prepaid Insurance (Asset) | | $100 |

This entry repeats monthly for the remaining 11 months, systematically converting the prepaid asset into expense as time passes.

---

## Appendix D Part 3: Common Business Transactions Cookbook — Owner Transactions, Loans, Corrections

Continues directly from Parts 1 and 2. This final part covers owner investments/withdrawals, taking out loans, correcting mistakes, and a few other situations that don't fit neatly into "revenue" or "expense."

---

### 26. Owner invests additional money into the business

Example: An owner deposits an extra $5,000 of personal savings into the business bank account.

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $5,000 | |
| Owner's Equity (Equity) | | $5,000 |

This is not income (the business didn't earn it by selling anything), it's a direct increase in the owner's stake.

### 27. Owner withdraws money for personal use (a "draw")

Example: The owner takes $1,000 out of the business bank account for personal expenses.

| Account | Debit | Credit |
|---|---|---|
| Owner's Draws (Equity, contra-equity) | $1,000 | |
| Checking Account (Asset) | | $1,000 |

Important: this is NOT an expense of the business. It's a reduction of the owner's equity stake — the owner is simply taking some of their own money/stake out of the business. "Owner's Draws" is typically its own contra-equity account so a business can see total draws for a period clearly on reports.

### 28. Taking out a business loan

Example: A business takes out a $20,000 loan from a bank, deposited directly into the checking account.

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $20,000 | |
| Bank Loan (Liability) | | $20,000 |

This increases BOTH an asset and a liability simultaneously — the business now has more cash, but also owes more money. Equity is untouched, because nothing was earned or invested by the owner.

### 29. Correcting a data entry mistake — the WRONG way (never do this)

Imagine a bookkeeper accidentally recorded a $500 utility bill as $5,000 (an extra zero). The tempting-but-wrong fix: go back and edit the original journal entry, changing the $5,000 to $500.

**Why this is wrong**: it destroys the historical record of what was actually entered and when. If anyone (an accountant, an auditor, or even the business owner months later) wants to understand what changed and why, silently editing history gives them nothing to go on. Worse, if any report was already generated, printed, or sent to a bank before the "fix," that report is now permanently inconsistent with what the books currently say — with no trace of why.

### 30. Correcting a data entry mistake — the RIGHT way (reversal entry)

The correct approach: leave the original (wrong) entry exactly as it was, and post a NEW entry that reverses it, followed by a third entry with the correct amounts.

Assume the original wrong entry was:

| Account | Debit | Credit |
|---|---|---|
| Utilities Expense (Expense) | $5,000 | |
| Accounts Payable (Liability) | | $5,000 |

Step 1 — reverse it exactly (swap debit and credit):

| Account | Debit | Credit |
|---|---|---|
| Accounts Payable (Liability) | $5,000 | |
| Utilities Expense (Expense) | | $5,000 |

Step 2 — post the correct entry:

| Account | Debit | Credit |
|---|---|---|
| Utilities Expense (Expense) | $500 | |
| Accounts Payable (Liability) | | $500 |

Net effect on the books: exactly as if $500 had been entered correctly from the start. But critically, the full history is preserved: anyone looking at the books can see the original mistake, the reversal, and the correction, each as their own dated, traceable entries. This is exactly why the project's schema includes a `reversal` value in `journalSourceTypeEnum`, ready for exactly this pattern.

### 31. Voiding an entire transaction (e.g., an invoice was created by mistake, never sent)

Similar principle: rather than deleting the invoice and its journal entry outright, the correct approach marks the invoice as "void" (status field, not deleted) and posts a reversing journal entry that exactly cancels out the original. The original invoice record remains visible in history, and the ledger nets to zero for that transaction.

### 32. Transferring money between two of the business's own bank accounts

Example: Moving $2,000 from a checking account to a savings account.

| Account | Debit | Credit |
|---|---|---|
| Savings Account (Asset) | $2,000 | |
| Checking Account (Asset) | | $2,000 |

Both accounts are Assets — this transaction doesn't create or destroy any value, it just moves cash between two "buckets" the business already owns.

### 33. Recording a bank fee

Example: The bank charges a $15 monthly account maintenance fee.

| Account | Debit | Credit |
|---|---|---|
| Bank Fees Expense (Expense) | $15 | |
| Checking Account (Asset) | | $15 |

### 34. Recording interest earned on a bank account

Example: A business savings account earns $8 of interest in a month.

| Account | Debit | Credit |
|---|---|---|
| Checking/Savings Account (Asset) | $8 | |
| Interest Income (Income) | | $8 |

Interest earned is genuine income, often broken out into its own "Other Income" category to distinguish it from operating revenue.

---

### Summary of the cookbook (Parts 1-3 combined)

Across these three notes, every transaction followed the same discipline: identify what actually increased and what actually decreased, translate that into debit/credit using each account's type, and confirm the entry balances. This is the exact same discipline the project's `postJournalEntry` function enforces in code — reject anything that doesn't balance, wrap multi-step operations atomically, and never silently edit history.

---

