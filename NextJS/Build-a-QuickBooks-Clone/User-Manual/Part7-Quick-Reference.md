# Comprehensive User Guide: The Complete Bookkeeping Cycle
## Part 7 of 7: Quick Reference Checklist and Full Cycle Summary

This final part distills Parts 1 through 6 (the full Riverside Design Studio walkthrough) into a single reusable checklist — the shape of the complete bookkeeping cycle, stripped of the specific example numbers, ready to apply to any real business or client engagement.

---

### The Complete Bookkeeping Cycle, Step by Step

**PHASE 1: Opening the Books (done once, when a business/company file starts)**
1. Build the Chart of Accounts (start from a sensible template, customize for the specific business — see Appendix C)
2. Record opening balances (owner investments of cash and/or other assets) as balanced journal entries
3. Confirm the opening Balance Sheet balances (Assets = Liabilities + Equity) before proceeding
4. Set up customer and vendor records for everyone the business will transact with

**PHASE 2: Day-to-Day Transaction Recording (continuous, throughout the month)**
5. Record cash sales the moment they happen (debit Cash/Checking, credit Income)
6. Send invoices for credit sales the moment work is delivered/earned, not when paid (debit Accounts Receivable, credit Income) — this is accrual accounting
7. Record customer payments as they arrive (debit Checking, credit Accounts Receivable) — watch for partial payments, early-payment discounts, and batch payments covering multiple invoices
8. Record vendor bills the moment they're received, not when paid (debit the relevant Expense or Asset, credit Accounts Payable)
9. Record bill payments as they're made (debit Accounts Payable, credit Checking)
10. Record any owner investments or draws as they occur (debit/credit Checking against Owner's Equity or Owner's Draws — never treat draws as a business expense)
11. Record credit card purchases as they happen (debit the relevant Expense, credit the credit card Liability account)
12. Record any fixed asset purchases as Assets, not Expenses, if they'll provide value over multiple years

**PHASE 3: Month-End Close (done once per month, before trusting that month's reports)**
13. Pull the actual bank statement(s) for the period
14. Reconcile every bank/credit card account line by line against your own recorded transactions
15. Record any discrepancies found (commonly: bank fees, interest earned, or occasionally a genuine data-entry error) as adjusting entries
16. Review the AR Aging report — are any invoices newly overdue? Any that should be written off as bad debt?
17. Review the AP Aging report — any bills approaching their due date that need to be paid soon?
18. Record any accrued expenses/income for the period that don't yet have a formal bill/invoice (e.g., work done but not yet billed, expenses incurred but not yet billed)
19. Record depreciation for the period on any fixed assets in use
20. Confirm the Trial Balance's total debits equal total credits across every account
21. Generate and review the Balance Sheet's isBalanced check (Assets = Liabilities + Equity) — if it doesn't hold, find the broken entry before trusting anything else
22. Scan the P&L for anything unusual compared to prior months

**PHASE 4: Reading and Acting on the Reports (done once per month, after closing)**
23. Read the Profit & Loss: what's the Net Margin? Is any expense category unusually large or small? Which revenue streams are driving performance?
24. Read the Balance Sheet: is the business overly reliant on debt? Is there enough short-term liquidity (Current Ratio)? Is Accounts Receivable growing faster than sales?
25. Read the AR/AP Aging reports: who needs a collections follow-up? What bills need to be prioritized for payment?
26. Make real business decisions informed by these numbers (pricing, staffing, collections policy, growth plans) — this is the entire point of maintaining the books in the first place

**PHASE 5: Repeat**
27. Begin the next month with Phase 2, carrying forward every Balance Sheet account's ending balance as the new starting point (Income/Expense accounts continue accumulating for the current fiscal year — they do NOT reset monthly)

**PHASE 6: Formal Year-End Closing (done once per fiscal year, NOT monthly)**
28. At fiscal year-end (only), move the full year's accumulated Net Income into Retained Earnings
29. Reset Income and Expense accounts to zero for the new fiscal year
30. Begin the new fiscal year's Phase 2 cycle

---

### The One Rule Underlying Every Single Step Above

Every single journal entry recorded across all six phases must have total debits equal total credits, with a minimum of two lines per entry. If this rule is enforced rigorously and automatically (as it is in the tutorial application's `postJournalEntry` function, and as it should be in any real accounting system or disciplined manual process), then:
- The Trial Balance will always balance
- The Balance Sheet's Assets will always equal Liabilities + Equity
- Every number on every report can be traced back to specific, real, dated transactions
- Mistakes get caught immediately (an entry that won't balance) rather than discovered months later

This is genuinely the entire foundation the whole cycle rests on — everything else in this guide (invoicing, bills, payments, reconciliation, reports) is just applying that one rule consistently to real business events, over and over, month after month.

### Quick Reference: Which Account Types Increase With What

| Account Type | Increases With | Decreases With |
|---|---|---|
| Asset | Debit | Credit |
| Liability | Credit | Debit |
| Equity | Credit | Debit |
| Income | Credit | Debit |
| Expense | Debit | Credit |

### Quick Reference: Common Transaction Patterns (see Appendix D for 34 fully worked examples)

| Event | Debit | Credit |
|---|---|---|
| Cash sale | Checking | Income |
| Invoice sent (credit sale) | Accounts Receivable | Income |
| Customer pays invoice | Checking | Accounts Receivable |
| Bill received | Expense (or Asset) | Accounts Payable |
| Bill paid | Accounts Payable | Checking |
| Owner invests cash | Checking | Owner's Equity |
| Owner takes a draw | Owner's Draws | Checking |
| Fixed asset purchased | Fixed Asset | Checking (or Liability if financed) |
| Depreciation recorded | Depreciation Expense | Accumulated Depreciation |
| Loan taken out | Checking | Loan Liability |
| Loan payment made | Loan Liability + Interest Expense (split) | Checking |

---

### Closing note on this guide

Parts 1 through 6 of this guide followed one fictitious business, Riverside Design Studio, through a single complete month, with every number traceable back to a specific, realistic transaction — deliberately chosen to exercise nearly every pattern covered across Appendices B through H, in the order a real bookkeeper actually encounters them, rather than as isolated, disconnected examples. This Part 7 checklist is meant to be the thing you actually keep open on a second monitor while doing this work for real, once the underlying concepts (covered in depth across Appendices B-H) are understood.

The cycle never fundamentally changes — only the specific numbers, the specific customers and vendors, and the specific judgment calls change from business to business, and month to month. Understanding this rhythm, once, is what lets it be applied confidently to any real accounting situation going forward.

---

🎉 **That's the complete 7-part User Guide, start to finish** — Riverside Design Studio's entire January bookkeeping cycle, from opening the books to closing the month and reading the results.

You now have three complementary resources in this knowledge base:
- **The code tutorial series (Parts 0-24) + Appendix A** — how to *build* the software
- **Appendices B-H** — accounting concepts explained in isolation
- **This User Guide (Parts 1-7)** — everything applied together on one real, narrative case study
