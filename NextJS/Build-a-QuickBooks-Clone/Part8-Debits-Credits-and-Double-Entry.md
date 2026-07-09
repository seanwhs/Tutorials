## Part 8: Debits, Credits and Double-Entry Accounting for Programmers

Goal: understand, with worked examples, the accounting concept our entire app is built around, before writing any of the code that enforces it. No code today — this is the most important non-code part in the whole course.

Prerequisite: Parts 1-7 completed.

---

### 1. Why an accounting app needs "double-entry" at all

A naive "accounting app" would just add up an invoices table and a bills table. This breaks down fast: it can't tell money in the bank from money owed to you, can't handle partial payments cleanly, can't correct mistakes without deleting history, and can't produce a Balance Sheet.

### 2. The one rule that explains everything

Every financial transaction is recorded as at least two lines: something increases, something else decreases (or increases), and total debits must always equal total credits, for every single transaction, no exceptions.

### 3. Forget your bank statement's meaning of "debit"

In accounting, debit and credit are just labels for two sides of a transaction — "left side" and "right side," not "bad" and "good." Whether a debit increases or decreases an account depends entirely on the account's TYPE.

### 4. The five account types and their normal balance

| Account Type | Normal Balance | Increases with | Decreases with | Examples |
|---|---|---|---|---|
| Asset | Debit | Debit | Credit | Checking, Accounts Receivable, Equipment |
| Liability | Credit | Credit | Debit | Credit card owed, Accounts Payable, Loans |
| Equity | Credit | Credit | Debit | Owner's investment, Retained Earnings |
| Income | Credit | Credit | Debit | Sales income, Service revenue |
| Expense | Debit | Debit | Credit | Rent, Utilities, Office Supplies |

Memory trick: Assets and Expenses are debit-normal. Liabilities, Equity, and Income are credit-normal.

### 5. Worked example 1: Owner invests $10,000

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $10,000 | |
| Owner's Equity (Equity) | | $10,000 |

### 6. Worked example 2: Send a $500 invoice (unpaid)

| Account | Debit | Credit |
|---|---|---|
| Accounts Receivable (Asset) | $500 | |
| Service Income (Income) | | $500 |

The income is earned the moment the invoice is sent — this is accrual accounting.

### 7. Worked example 3: Customer pays that $500 invoice

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $500 | |
| Accounts Receivable (Asset) | | $500 |

Income is NOT touched again — it was already recorded in example 6.

### 8. Worked example 4: Pay a $200 electric bill

| Account | Debit | Credit |
|---|---|---|
| Utilities Expense (Expense) | $200 | |
| Checking Account (Asset) | | $200 |

### 9. Why debits=credits is a powerful safety net

If you tried to enter only one line, the entry would be rejected — it's not a complete, real transaction. This is exactly why we'll enforce it at the code/database level in Part 10, and why we store money as integer cents (never floating point) — a fraction-of-a-cent rounding error could break this rule for no real reason.

### 10. Where reports come from

- **Profit & Loss**: sum Income (credits minus debits) minus Expenses (debits minus credits) over a date range
- **Balance Sheet**: running balance of every Asset, Liability, and Equity account as of a date — Assets will always exactly equal Liabilities + Equity
- **General Ledger**: chronological list of every journal line, per account
- **AR/AP Aging**: open AR/AP balances grouped by overdueness

### 11. Vocabulary

- **Journal Entry**: one complete transaction
- **Journal Line**: one row within a journal entry
- **Posting**: saving a journal entry as final
- **Chart of Accounts**: the full list of accounts a business uses
- **Ledger**: the complete history of all posted journal entries

---

### ✅ Checkpoint

- [ ] Which two account types increase with a debit? Which three increase with a credit?
- [ ] A business buys a $2,000 laptop with a credit card — what are the two journal lines?
- [ ] Why doesn't income get recorded again when an invoice gets paid later?
- [ ] Why must total debits always equal total credits on every entry?
- [ ] Why build reports from journal_lines instead of directly from invoices/bills tables?

---

### Troubleshooting (common misunderstandings, not code errors)

**"I keep wanting to think of debit as bad/negative and credit as good/positive"**
This is the single most common beginner trap. There is no inherent good/bad meaning — re-read section 3. Try replacing the words "debit" and "credit" with "left" and "right" in your head while you're learning; it removes the emotional baggage the words carry from everyday bank statement language.

**"I can't tell which account type a real-world account belongs to"**
Ask: does this represent something the business OWNS (Asset), OWES (Liability), the OWNER'S STAKE (Equity), MONEY EARNED (Income), or MONEY SPENT (Expense)? Almost everything sorts cleanly into one of these five with that question.

**"The credit card purchase example (checkpoint question 2) really tripped me up"**
That's a great sign, not a bad one — work through it slowly: a laptop is an Asset going up (debit, since assets increase with debit), and the credit card balance owed is a Liability going up (credit, since liabilities increase with credit). Two accounts increasing at once, on opposite sides — that's exactly what double-entry looks like for a purchase made on credit.

**"Why does an invoice being SENT count as income, before I've even been paid?"**
This is accrual accounting (section 6/7) — income is recognized when it's earned (the work was done / the sale happened), not when cash physically arrives. This is standard practice for real accounting and is what QuickBooks does by default too.

**"I don't understand why we need BOTH a Balance Sheet and a P&L if they're both derived from the same journal_lines"**
They answer different questions over different scopes: P&L = performance over a period (a range of dates); Balance Sheet = position at a single instant (one date). You'll see this distinction very concretely once we build both reports in Parts 16-17.
