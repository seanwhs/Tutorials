# Comprehensive User Guide: The Complete Bookkeeping Cycle
## Part 3 of 7: Weeks 3-4 — Bills, Contractor Expense, and Owner Transactions

Continuing directly from Part 2. Riverside Design Studio's checking account sits at $16,920, with $4,500 still outstanding in Accounts Receivable (Northgate Dental). Now we cover the expense side of the month.

---

### January 20th: Adobe subscription bill arrives

Adobe sends its monthly Creative Cloud subscription bill for $55, due in 15 days (Adobe doesn't require immediate payment — it's billed on account).

**Journal Entry 9:**

| Date | Account | Debit | Credit |
|---|---|---|---|
| Jan 20 | Software Subscriptions Expense (5100) | $55 | |
| Jan 20 | Accounts Payable (2000) | | $55 |

This mirrors Appendix D's example 14 exactly — the expense is recorded the moment the bill is received (accrual accounting), not when it's actually paid. Riverside now owes $55 it didn't owe before.

### January 20th: WeWork co-working desk bill arrives

WeWork also bills monthly. January's co-working desk rental bill for $350 arrives, due in 10 days.

**Journal Entry 10:**

| Date | Account | Debit | Credit |
|---|---|---|---|
| Jan 20 | Rent Expense (5300) | $350 | |
| Jan 20 | Accounts Payable (2000) | | $350 |

Running Accounts Payable balance: $55 (Adobe) + $350 (WeWork) = $405.

### January 22nd: Paying the WeWork bill

Maya pays the WeWork bill via bank transfer, 2 days before it's due.

**Journal Entry 11:**

| Date | Account | Debit | Credit |
|---|---|---|---|
| Jan 22 | Accounts Payable (2000) | $350 | |
| Jan 22 | Checking Account (1000) | | $350 |

Rent Expense is NOT recorded again — it was already recorded in Journal Entry 10. This transaction simply clears the liability and reduces cash (Appendix D, example 15). Running Accounts Payable balance: $405 - $350 = $55 (just Adobe remaining).

Running Checking Account balance: $16,920 - $350 = $16,570.

### January 24th: Subcontracting illustration work to Jordan Reyes

Northgate Dental's rebrand needs some custom illustration work Maya doesn't do herself. She subcontracts it to Jordan Reyes, a freelance illustrator, who bills $400 for the work, due in 15 days.

**Journal Entry 12:**

| Date | Account | Debit | Credit |
|---|---|---|---|
| Jan 24 | Contractor Expense (5500) | $400 | |
| Jan 24 | Accounts Payable (2000) | | $400 |

Running Accounts Payable balance: $55 (Adobe) + $400 (Jordan) = $455.

Note for readers curious about payroll vs. contractor treatment: because Jordan is an independent contractor (not an employee), there's no payroll tax withholding here — the full $400 is simply an expense, and Jordan is responsible for handling their own taxes on that income (subject to real-world tax reporting rules, e.g. issuing a 1099 in the US at year-end, which is flagged as a Phase 3 feature in the tutorial series' roadmap, Part 24). Contrast this with Appendix D's example 22, which shows the more complex treatment required for an actual W-2 employee.

### January 26th: A business credit card purchase for office supplies

Maya buys a $120 order of printed business card stock and presentation folders for client meetings, charged to the Riverside business credit card.

**Journal Entry 13:**

| Date | Account | Debit | Credit |
|---|---|---|---|
| Jan 26 | Office Supplies Expense (5200) | $120 | |
| Jan 26 | Business Credit Card (2100) | | $120 |

This is a Liability increasing (the credit card balance owed goes up) matched against an Expense increasing — no cash left the checking account yet, since the credit card is its own liability that will be paid off separately later (see Part 4 of this guide, and Appendix D's example 20 for the equipment-financing version of this same pattern).

### January 28th: Recording the month's first depreciation entry

Recall from Part 1 that Maya contributed a $2,000 laptop to the business. She estimates it will last 3 years (36 months) of useful business life, and uses simple straight-line depreciation: $2,000 / 36 ≈ $56/month (rounded).

**Journal Entry 14:**

| Date | Account | Debit | Credit |
|---|---|---|---|
| Jan 28 | Depreciation Expense (new Expense account) | $56 | |
| Jan 28 | Accumulated Depreciation (new contra-asset account under Computer Equipment) | | $56 |

This matches Appendix D's example 19 exactly. Maya needs to add both a "Depreciation Expense" account and an "Accumulated Depreciation" contra-asset account to her Chart of Accounts to record this (a good illustration of Appendix C's point that a Chart of Accounts grows over time as new needs arise — it isn't fixed forever at whatever the starter template provided).

After this entry, the laptop's "book value" on the Balance Sheet becomes $2,000 (original cost) − $56 (accumulated depreciation) = $1,944 — reflecting that it's very slightly used/depreciated, without deleting the original purchase record.

### January 30th: Maya takes an owner's draw

Two months into running the business properly, Maya wants to pay herself $2,000 from the business's cash for personal living expenses.

**Journal Entry 15:**

| Date | Account | Debit | Credit |
|---|---|---|---|
| Jan 30 | Owner's Draws (3100) | $2,000 | |
| Jan 30 | Checking Account (1000) | | $2,000 |

This is NOT a business expense, even though cash left the checking account — it's a reduction of Maya's equity stake in the business (Appendix D, example 27). It will show up as its own clearly-labeled line reducing Total Equity on the Balance Sheet (Part 5 of this guide), not anywhere on the Profit & Loss report.

Running Checking Account balance: $16,570 - $2,000 = $14,570.

### End-of-month running totals, before reconciliation and adjustments

Before moving to Part 4 (bank reconciliation and remaining month-end adjustments), here's where the books stand after every transaction recorded in Parts 2 and 3:

**Checking Account (1000):** $14,570
**Accounts Receivable (1100):** $4,500 (Northgate Dental, not yet due)
**Computer Equipment (1500):** $2,000 (before depreciation contra-account)
**Accumulated Depreciation:** ($56) — reduces Computer Equipment's book value
**Accounts Payable (2000):** $55 (Adobe) + $400 (Jordan) = $455
**Business Credit Card (2100):** $120
**Owner's Equity (3000):** $17,000 (unchanged since opening)
**Owner's Draws (3100):** ($2,000) — reduces total equity
**Design Income (4000):** $150 + $1,200 + $4,500 = $5,850
**Consulting Income (4100):** $600
**Sales Discounts:** ($30) — reduces net income
**Rent Expense (5300):** $350
**Software Subscriptions Expense (5100):** $55
**Office Supplies Expense (5200):** $120
**Contractor Expense (5500):** $400
**Depreciation Expense:** $56

These numbers will feed directly into Part 5's full Trial Balance and financial statements, but first, Part 4 covers a genuinely essential step most bookkeeping guides for beginners skip or rush past: reconciling the bank account and catching anything that slipped through the cracks before trusting any of these numbers.

---

### What's next
Part 4 walks through the bank reconciliation process for January (comparing Riverside's recorded transactions against the actual bank statement), catches a realistic discrepancy (a bank fee neither recorded yet), and covers the remaining month-end adjusting entries needed before closing the books for January.

---

Say **"Part 4"** or **"continue"** to walk through bank reconciliation and month-end adjusting entries.
