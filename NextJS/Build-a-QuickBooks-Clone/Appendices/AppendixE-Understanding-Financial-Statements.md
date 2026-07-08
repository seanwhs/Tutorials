## Appendix E: Reading and Understanding Financial Statements

This appendix explains how to actually READ the reports that all the transaction recording in Appendices B-D builds toward. Here we focus purely on what the numbers mean and how to interpret them like a business owner would, not on implementation.

---

### 1. The three core financial statements, in one sentence each

- **Profit & Loss (P&L)**, also called an Income Statement: "Did the business make money over this period, and on what?"
- **Balance Sheet**: "What does the business own and owe, as of this exact moment?"
- **Cash Flow Statement**: "Where did cash actually come from and go, over this period?" (covered conceptually in section 6 since it's a core statement in real accounting, though not built in this project's tutorial)

The single most important thing to internalize: **P&L and Cash Flow Statement cover a PERIOD of time** — like a video. **The Balance Sheet is a SNAPSHOT at one instant** — like a photograph. This distinction trips up almost every beginner at least once.

### 2. The Profit & Loss report, section by section

A P&L is structured, top to bottom, roughly like this:

```
Income
  Sales Income               $12,000
  Service Income              $8,000
  Total Income                              $20,000

Cost of Goods Sold
  Cost of Goods Sold          $4,000
  Total COGS                                 $4,000

Gross Profit                                $16,000

Expenses
  Rent Expense                $2,000
  Utilities Expense             $300
  Advertising Expense           $500
  Payroll Expense              $6,000
  Office Supplies Expense       $200
  Total Expenses                              $9,000

Net Profit (or Net Income)                  $7,000
```

Reading this from top to bottom:
- **Total Income** — everything earned from sales/services during the period
- **Total COGS** — direct costs of producing what was sold
- **Gross Profit** = Total Income - Total COGS. Tells you how profitable the core product/service is, before overhead.
- **Total Expenses** — everything else spent running the business
- **Net Profit** = Gross Profit - Total Expenses. This is "the bottom line."

A business owner reading this should ask: is Gross Profit margin (here 16,000/20,000 = 80%) healthy for this type of business? Are expenses growing faster than income month over month? Is any single expense category unexpectedly large?

### 3. The Balance Sheet, section by section

```
Assets
  Checking Account            $15,000
  Accounts Receivable          $3,000
  Computer Equipment           $2,500
  Total Assets                              $20,500

Liabilities
  Accounts Payable             $1,500
  Credit Card                    $800
  Total Liabilities                          $2,300

Equity
  Owner's Equity               $10,000
  Retained Earnings             $1,200
  Net Income (current period)   $7,000
  Total Equity                               $18,200

Total Liabilities + Equity                  $20,500
```

Notice the last line MUST equal Total Assets — this is the accounting equation, proven live with real numbers. If Assets doesn't equal Liabilities + Equity, something in the underlying bookkeeping is broken (an unbalanced entry snuck in somewhere).

Reading this report, an owner should ask: does the business have enough cash/liquid assets to cover its near-term liabilities (the "current ratio")? Is the business's debt load reasonable relative to its equity? Is Accounts Receivable growing faster than sales (a warning sign that customers are taking longer to pay)?

### 4. Why "Net Income (current period)" appears on the Balance Sheet

This is worth explaining carefully because it's a common point of confusion. Profit that hasn't been formally distributed to the owner effectively belongs to Equity. In real, mature accounting systems, there's a formal "closing the books" process at the end of each fiscal year, where the current year's Net Income gets moved into "Retained Earnings" (a permanent equity account), and the Income/Expense accounts reset to zero. Until that formal closing happens, a live, up-to-the-minute Balance Sheet needs to show the current period's not-yet-closed profit somewhere, or the equation wouldn't balance — so it's shown as a distinct line, clearly labeled as "current period, unclosed."

### 5. AR and AP Aging reports

These are operational reports, not strictly "financial statements" in the formal sense, but essential for day-to-day business management:

**AR Aging** answers: "Who owes us money, and how overdue are they?" Organized into buckets (Current, 1-30 days overdue, 31-60, 61+), it lets a business owner prioritize collection efforts.

**AP Aging** answers the mirror question: "Who do we owe money to, and how overdue are we?" Used to prioritize which vendor bills to pay first, especially useful when cash is tight.

Both reports read from the actual open invoices/bills (not just the ledger's aggregate AR/AP balance), because they need document-level detail that a pure ledger balance can't provide.

### 6. The Cash Flow Statement, conceptually

A Cash Flow Statement answers a question that neither the P&L nor Balance Sheet directly answers: "where did our actual cash come from and go, this period?" This matters because **profit and cash are not the same thing**. Common reasons profit and cash diverge:
- A business made a large sale on credit — profitable on paper, no cash in hand yet
- A business paid down a large loan principal — reduces cash significantly, but doesn't appear as an expense on the P&L at all (only the interest portion does)
- A business bought a large piece of equipment for cash — a big cash outflow, but not an expense — it's an asset

A full Cash Flow Statement organizes cash movements into three categories: **Operating**, **Investing**, and **Financing**.

### 7. A few useful ratios and quick health checks

- **Gross Margin** = Gross Profit / Total Income
- **Net Margin** = Net Profit / Total Income
- **Current Ratio** = Total Current Assets / Total Current Liabilities — a rough measure of short-term liquidity
- **Days Sales Outstanding** (roughly) — how long, on average, customers take to pay

None of these ratios are magic thresholds — they're most useful compared against the same business's own numbers over time, or against typical numbers for similar businesses in the same industry.

### 8. What's next

Appendix F is a glossary for quick term lookups. Appendix G covers common bookkeeping mistakes and the month-end close process. Appendix H rounds out the domain knowledge with accrual vs. cash basis accounting.

