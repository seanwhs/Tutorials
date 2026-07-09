# Comprehensive User Guide: The Complete Bookkeeping Cycle
## Part 5 of 7: Trial Balance and Financial Statements

Continuing directly from Part 4. Riverside Design Studio's books for January are fully reconciled and adjusted. Now we build the actual financial statements a real business owner or bookkeeper would look at — starting with a Trial Balance (the internal working document that feeds everything else), then the Profit & Loss, Balance Sheet, and Aging reports in their final form.

---

### Step 1: The Trial Balance

A Trial Balance is simply a list of every single account and its current balance, with debit-normal accounts (Assets, Expenses) and credit-normal accounts (Liabilities, Equity, Income) each shown in their natural column — used as a working checkpoint to confirm total debits equal total credits across the ENTIRE set of books, not just within individual entries. It's not usually shown to a business owner directly (the P&L and Balance Sheet are far more readable), but it's the direct computational input to both.

**Riverside Design Studio — Trial Balance as of January 31**

| Account | Debit | Credit |
|---|---|---|
| Checking Account (1000) | $14,558 | |
| Accounts Receivable (1100) | $4,500 | |
| Computer Equipment (1500) | $2,000 | |
| Accumulated Depreciation | | $56 |
| Accounts Payable (2000) | | $455 |
| Business Credit Card (2100) | | $120 |
| Owner's Equity (3000) | | $17,000 |
| Owner's Draws (3100) | $2,000 | |
| Design Income (4000) | | $5,850 |
| Consulting Income (4100) | | $600 |
| Sales Discounts | $30 | |
| Rent Expense (5300) | $350 | |
| Software Subscriptions Expense (5100) | $55 | |
| Office Supplies Expense (5200) | $120 | |
| Contractor Expense (5500) | $400 | |
| Depreciation Expense | $56 | |
| Bank Fees Expense (5700) | $12 | |
| **Totals** | **$24,081** | **$24,081** |

Total debits ($24,081) equal total credits ($24,081) — this is the same debit=credit rule from Appendix B, section 4, just proven across every single transaction from the whole month at once, rather than one entry at a time. If these two totals didn't match, it would mean an entry somewhere in Parts 2-4 was posted incorrectly (bypassing the `postJournalEntry` engine's built-in enforcement, per Appendix A) — a real, meaningful integrity check, not just a formality.

### Step 2: The Profit & Loss Report (January 1 — January 31)

Reorganizing the Income and Expense accounts from the Trial Balance into the standard P&L layout (Appendix E, section 2):

```
RIVERSIDE DESIGN STUDIO
Profit & Loss
For the Period January 1 - January 31

Income
  Design Income                    $5,850
  Consulting Income                   $600
  Total Income                                  $6,450

Less: Sales Discounts                              ($30)
Net Income                                        $6,420

Expenses
  Rent Expense                        $350
  Software Subscriptions Expense       $55
  Office Supplies Expense             $120
  Contractor Expense                  $400
  Depreciation Expense                 $56
  Bank Fees Expense                    $12
  Total Expenses                                  $993

NET PROFIT                                       $5,427
```

Reading this the way Maya would: Riverside earned $6,420 in net revenue this month and spent $993 running the business, leaving $5,427 in profit for January — a strong first month. Notice there's no Cost of Goods Sold section at all, and therefore no separate "Gross Profit" line before Net Profit — this is completely correct for a pure service business with nothing to manufacture or resell (contrast with Appendix C section 6's coffee shop example, which WOULD have a COGS section).

### Step 3: The Balance Sheet (as of January 31)

Reorganizing the Asset, Liability, and Equity accounts from the Trial Balance into the standard Balance Sheet layout (Appendix E, section 3), folding January's Net Profit into Equity as the current period's unclosed earnings (Appendix E, section 4):

```
RIVERSIDE DESIGN STUDIO
Balance Sheet
As of January 31

ASSETS
  Checking Account                $14,558
  Accounts Receivable               $4,500
  Computer Equipment (net of
    $56 accumulated depreciation)   $1,944
  Total Assets                                 $21,002

LIABILITIES
  Accounts Payable                    $455
  Business Credit Card                $120
  Total Liabilities                                $575

EQUITY
  Owner's Equity                  $17,000
  Owner's Draws                   ($2,000)
  Net Income (current period,
    unclosed)                       $5,427
  Total Equity                                 $20,427

TOTAL LIABILITIES + EQUITY                    $21,002
```

Total Assets ($21,002) exactly equals Total Liabilities + Equity ($575 + $20,427 = $21,002). Balanced — proving live, from Riverside's own real month of activity, that the fundamental accounting equation (Appendix B, section 2) holds perfectly, automatically, purely as a consequence of every transaction across Parts 2 through 4 having been recorded as a genuinely balanced double-entry. This is the same `isBalanced` check the tutorial application's code computes automatically (Appendix A, Part 2b).

### Step 4: The AR Aging Report (as of January 31)

```
RIVERSIDE DESIGN STUDIO
Accounts Receivable Aging
As of January 31

Customer          Invoice #   Due Date    Days Overdue   Bucket      Amount
Northgate Dental   INV-1002   Feb 7          0          Current     $4,500

Totals by Bucket:
  Current:        $4,500
  1-30 days:          $0
  31-60 days:         $0
  61+ days:           $0
```

Only one open invoice, correctly shown as Current (not yet due). Cross-checking against the Balance Sheet: Accounts Receivable shows $4,500 in both places — they agree exactly, since there are no partial payments this month to create the small netting discrepancy discussed in Appendix E section 5's caveat.

### Step 5: The AP Aging Report (as of January 31)

```
RIVERSIDE DESIGN STUDIO
Accounts Payable Aging
As of January 31

Vendor           Bill #      Due Date    Days Overdue   Bucket      Amount
Adobe            (subscription) Feb 4       0          Current        $55
Jordan Reyes     (illustration) Feb 8       0          Current       $400

Totals by Bucket:
  Current:          $455
  1-30 days:           $0
  31-60 days:          $0
  61+ days:            $0
```

Both bills correctly shown as Current, matching the $455 Accounts Payable balance on the Balance Sheet exactly.

### A moment worth sitting with

Every one of these four reports — the P&L, the Balance Sheet, and both Aging reports — was built purely by reorganizing the exact same underlying set of journal entries from Parts 2 through 4, with zero additional data entry or separate calculation logic. This is the entire point of the discipline covered throughout this guide and the tutorial series it accompanies: get the transaction recording right, atomically and consistently, and the reports simply fall out correctly, automatically, every time.

---

### What's next
Part 6 covers what Maya does with these results — interpreting what the numbers actually tell her about the business's first month, deciding whether any changes are needed, and the distinction between this month's routine closing and the formal annual books-closing process, before starting February's cycle.

---

Say **"Part 6"** or **"continue"** to see how Maya interprets these results and closes out January.
