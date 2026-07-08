## Appendix C: The Chart of Accounts Explained In Depth

This appendix assumes you've read Appendix B (the five account types). Here we go deep on the Chart of Accounts — the actual, specific list of accounts a real business uses day to day, how it's structured, numbered, and why the categories matter.

---

### 1. What a Chart of Accounts actually is

A Chart of Accounts (often abbreviated "CoA") is the complete list of every account a business uses to categorize its money. Think of it as the full set of labeled buckets a business sorts every dollar into. "Checking Account," "Accounts Receivable," "Office Supplies Expense," "Rent Expense," "Sales Income" — each of these is one account on the Chart of Accounts.

Every journal entry references specific accounts from this list. The Chart of Accounts is set up once when a business starts (usually from a sensible template, then customized), and grows slowly over time as new categories are needed.

### 2. Why businesses use numeric codes for accounts

Real charts of accounts almost universally assign each account a numeric code, not just a name. This isn't just tradition — it serves real purposes:
- **Sorting** — numeric codes let you list accounts in the same predictable order every time (Assets first, then Liabilities, then Equity, then Income, then Expenses)
- **Grouping** — similar accounts get similar number ranges, so you can tell an account's general category from its code alone, at a glance
- **Stability** — if you rename an account, its code (and therefore its position in reports and its identity in the system) stays the same

### 3. The standard numbering convention

An extremely common convention:

| Number range | Account Type |
|---|---|
| 1000-1999 | Assets |
| 2000-2999 | Liabilities |
| 3000-3999 | Equity |
| 4000-4999 | Income |
| 5000-5999 (and up) | Expenses |

Within each range, businesses often further order accounts by liquidity (for Assets):
- 1000-1099: Cash and bank accounts (the MOST liquid — can be spent immediately)
- 1100-1199: Receivables (money owed to you — liquid, but not instantly)
- 1200-1299: Other current assets (things expected to convert to cash within a year)
- 1500+: Fixed assets (equipment, property — NOT easily converted to cash)

This "most liquid first" ordering isn't arbitrary — it directly mirrors how a Balance Sheet is conventionally presented, so the Chart of Accounts' natural order already matches the report's expected order.

### 4. Account "subtype" — a second, more specific classification

Beyond the five broad types, most real accounting systems track a more specific subtype for each account.

**Asset subtypes:**
- `bank` — actual cash in checking/savings accounts
- `accounts_receivable` — money owed to the business by customers (normally exactly ONE per business)
- `other_current_asset` — assets expected to be used/converted within a year that aren't cash or receivables (prepaid insurance, inventory, undeposited funds)
- `fixed_asset` — equipment, vehicles, buildings, furniture

**Liability subtypes:**
- `accounts_payable` — money the business owes to vendors (normally exactly ONE per business)
- `credit_card` — a credit card balance owed
- `loan` / `long_term_liability` — bank loans, equipment financing

**Equity subtypes:**
- `equity` — owner investment/draws, retained earnings

**Income subtypes:**
- `income` — can be split further (Sales Income, Service Income, Consulting Income)

**Expense subtypes:**
- `cogs` (Cost of Goods Sold) — costs directly tied to producing what you sell
- `expense` — everything else: rent, utilities, office supplies, advertising, payroll, etc.

### 5. Why Accounts Receivable and Accounts Payable are usually singular

A subtlety worth calling out explicitly: while a business might have MANY income accounts and MANY expense accounts, it almost always has exactly ONE Accounts Receivable account and exactly ONE Accounts Payable account.

Why? Because AR and AP aren't really "categories" of transactions the way income/expense accounts are — they're a single running total representing "all the money currently owed to us" (AR) or "all the money we currently owe" (AP), regardless of which specific customer or vendor it's tied to. The DETAIL of who owes what is tracked separately (in a business's list of open invoices/bills), while the Chart of Accounts just needs one account that sums up the total.

This is exactly why the code in this project looks up AR by subtype rather than by a specific name or ID — there's only ever supposed to be one, and the code can rely on that.

### 6. Cost of Goods Sold (COGS) — why it's treated specially

COGS is technically an Expense (debit-normal, appears on the Profit & Loss), but it's placed in its own special zone because of a specific reporting need: **Gross Profit**.

Gross Profit = Total Income - COGS (and only COGS, not other expenses)

This tells you how profitable your core product/service is BEFORE accounting for overhead. A business selling a product for $100 that costs $40 in materials/direct labor has a Gross Profit of $60 (60% gross margin) on that sale.

Regular expenses (rent, utilities, office supplies, general admin salaries) are NOT part of COGS because they're not directly tied to producing a specific unit of product/service — they're overhead that exists regardless of sales volume.

A simple example: a coffee shop's COGS includes coffee beans, milk, cups. Its regular expenses include the lease on the shop space, the manager's salary, and the accountant's fee — things that cost the same whether they sell 10 cups of coffee or 1,000.

### 7. Sub-accounts and hierarchy (parent-child accounts)

Many real charts of accounts support nesting — a "parent" account with several "child" sub-accounts underneath it:
```
6000 Utilities Expense (parent)
  6010 Electric
  6020 Water
  6030 Internet
```
This lets a business see a combined "Utilities Expense" total on a summary report, while still being able to drill into the detail.

### 8. Is Active / archiving accounts

Real charts of accounts rarely delete an account outright, even if a business stops using it. Instead, accounts are marked inactive so that HISTORICAL reports covering a period when the account WAS in use still display correctly and accurately, while new transactions can no longer be posted to it. This mirrors the broader accounting principle of never destroying historical financial records.

### 9. A realistic, expanded example Chart of Accounts for a small service business

```
1000 Checking Account (Asset, bank)
1010 Savings Account (Asset, bank)
1100 Accounts Receivable (Asset, accounts_receivable)
1200 Undeposited Funds (Asset, other_current_asset)
1500 Computer Equipment (Asset, fixed_asset)
1510 Office Furniture (Asset, fixed_asset)
1900 Accumulated Depreciation (Asset, contra-asset)

2000 Accounts Payable (Liability, accounts_payable)
2100 Business Credit Card (Liability, credit_card)
2200 Sales Tax Payable (Liability)
2500 Equipment Loan (Liability, loan)

3000 Owner's Equity (Equity)
3100 Owner's Draws (Equity)
3200 Retained Earnings (Equity)

4000 Consulting Income (Income)
4100 Training Income (Income)

5000 Cost of Subcontractors (Expense, cogs)
5100 Advertising Expense (Expense)
5200 Office Supplies Expense (Expense)
5300 Rent Expense (Expense)
5400 Utilities Expense (Expense)
5500 Payroll Expense (Expense)
5600 Software Subscriptions Expense (Expense)
5700 Professional Fees Expense (Expense)
5800 Travel Expense (Expense)
```

This naturally extends the 16-account starter set from the project — same numbering logic, same five-type structure, just more specific categories as the business's needs grow. This is exactly how real businesses evolve their charts of accounts over time: start simple, add specificity only when actually needed.

### 10. What's next

Appendix D takes this Chart of Accounts and works through dozens of real, worked journal entry examples showing exactly which accounts get debited and credited for common business events.
