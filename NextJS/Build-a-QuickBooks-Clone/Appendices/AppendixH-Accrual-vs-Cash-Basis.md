## Appendix H: Accrual vs Cash Basis and Other Core Accounting Concepts

This is the final appendix in the B-H domain primer series. It rounds out the foundational concepts referenced throughout the previous appendices: the accrual vs. cash basis distinction, plus the matching principle, materiality, and the going concern assumption.

---

### 1. Cash Basis Accounting

Under cash basis accounting, income is recorded ONLY when cash is actually received, and expenses are recorded ONLY when cash is actually paid. No Accounts Receivable, no Accounts Payable, no "unearned revenue" — just: did money physically move yet?

**Example:** A consultant does $2,000 of work in March, sends an invoice, and gets paid in April. Under cash basis, this $2,000 is recorded as APRIL's income, because that's when the cash arrived, regardless of when the work was actually done.

**Advantages:** Extremely simple to understand and maintain. Directly matches a business's actual bank balance changes. Popular with very small businesses, sole proprietors, and for personal tax filing simplicity in many jurisdictions.

**Disadvantages:** Doesn't show a true picture of business performance in a given period, since income/expenses can be timed almost arbitrarily by when checks are cut or invoices are paid. Cannot produce a meaningful Balance Sheet. Makes it easy to accidentally or intentionally distort a period's apparent profitability by delaying/accelerating payments.

### 2. Accrual Basis Accounting

Under accrual accounting, income is recorded when EARNED (goods delivered or services performed), and expenses are recorded when INCURRED, regardless of when cash actually moves. This is the method this project's entire application is built around.

**Same example, accrual basis:** The consultant's $2,000 of work done in March is recorded as MARCH income (an invoice sent, debiting Accounts Receivable, crediting Income), even though the cash doesn't arrive until April (which is instead recorded in April as clearing the receivable, not as new income).

**Advantages:** Gives a much more accurate picture of a business's true performance in a given period. Enables meaningful Balance Sheets. Required for most larger businesses and generally considered the more rigorous, standard-compliant approach (aligned with formal accounting standards like GAAP in the US or IFRS internationally).

**Disadvantages:** More complex to maintain — requires tracking what's owed and owing, not just cash movements. Can show a "profitable" period on paper while the business is actually short on cash — which is exactly why larger businesses also produce a separate Cash Flow Statement.

### 3. Why this project uses accrual accounting

Every worked example, every report, and the entire ledger design assumes accrual accounting. This is a deliberate choice, not an oversight: accrual is the method real, serious accounting software (QuickBooks, Xero, and this project's clone) is built around, because it's the method that produces meaningful, comparable financial reports over time. A cash-basis-only system would be a much simpler build, but it would also be a much less useful and much less realistic one — unable to produce a real Balance Sheet at all, and easily gamed by payment timing.

### 4. The Matching Principle

Closely related to accrual accounting: expenses should be recorded in the SAME period as the income they helped generate, so that a period's P&L shows a true, matched picture of effort-and-reward.

**Example:** A business pays a salesperson a commission for a sale made in March, but the commission check isn't cut until April. The matching principle says: record that commission expense in MARCH, alongside the sale it's directly tied to, even though the cash payment happens in April.

Without the matching principle, a business could show artificially high profit in March and artificially low profit in April — neither month would accurately reflect what actually happened.

### 5. Materiality

Materiality is the practical principle that very small, insignificant amounts don't need the full, rigorous treatment that larger amounts require.

**Example:** Technically, a $15 stapler provides value over several years and could be depreciated as a fixed asset, just like a $2,500 laptop. In practice, virtually every business simply expenses the stapler immediately because tracking depreciation schedules for a $15 item is administrative effort with zero real benefit.

Most businesses set an informal or formal "capitalization threshold" (e.g., "anything under $500 gets expensed immediately, anything over gets treated as a fixed asset") to make this judgment call consistent and quick.

### 6. The Going Concern Assumption

A foundational assumption underlying essentially all standard financial reporting: that the business will continue operating for the foreseeable future, not shut down or liquidate imminently. This assumption justifies things like:
- Recording a prepaid expense as an asset to be used up over future months
- Depreciating equipment over years
- Reporting Accounts Receivable at its full expected value (minus reasonable bad debt estimates)

If a business is genuinely expected to shut down soon, accounting standards require a different, more conservative reporting basis — but this is a specialized edge case most businesses never need to deal with.

### 7. How these concepts connect back to the whole appendix series

- **Appendix B** introduced double-entry bookkeeping and the accounting equation — the mechanical foundation
- **Appendix C** explained the Chart of Accounts — the specific categories used within that mechanical foundation
- **Appendix D** worked through real transactions — applying the mechanics to real business events, largely relying on accrual timing
- **Appendix E** explained how those recorded transactions become readable reports
- **Appendix F** provided a quick-reference glossary
- **Appendix G** covered real-world practice: mistakes to avoid and the month-end close discipline
- **Appendix H** (this one) explained the underlying WHY behind the timing choices — accrual vs. cash, matching, materiality, going concern

Together, Appendices B through H form a complete, standalone domain-knowledge companion to the code — readers can now understand both HOW the QuickBooks clone application is built AND WHY it's built to model real accounting practice the way it does, independent of any particular software implementation.
