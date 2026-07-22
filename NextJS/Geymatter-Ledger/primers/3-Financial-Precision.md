# Primer 3 — Money, Cents, Rounding, and Financial Precision

**Product:** GreyMatter Ledger  
**Document type:** Primer  
**Audience:** Developers, technical founders, engineers new to financial software  
**Goal:** Explain how GreyMatter Ledger handles money safely and why financial precision matters  

---

# 1. Why Money Handling Deserves Its Own Primer

Money looks simple.

It is tempting to write code like this:

```ts
const subtotal = 100.00;
const gst = subtotal * 0.09;
const total = subtotal + gst;
```

But financial software cannot be casual with decimals.

Small rounding mistakes can accumulate.

A one-cent error can cause:

```txt
Invoice mismatch
GST report mismatch
Bank reconciliation mismatch
Audit issues
User distrust
```

GreyMatter Ledger follows a strict rule:

```txt
Store money as integer cents.
```

Example:

```txt
S$100.00 = 10000
S$9.00   = 900
S$109.00 = 10900
```

---

# 2. The Floating-Point Problem

JavaScript numbers are floating-point values.

Floating-point math can produce surprising results:

```ts
0.1 + 0.2
```

Result:

```txt
0.30000000000000004
```

This is normal computer behavior, but it is unacceptable for accounting records.

Imagine this appearing in accounting:

```txt
Expected GST: S$9.00
Actual GST:   S$8.9999999997
```

That is why GreyMatter Ledger avoids storing money as decimal dollars.

---

# 3. Integer Cents

Instead of storing:

```ts
109.00
```

GreyMatter Ledger stores:

```ts
10900
```

This means:

```txt
All stored money values are whole numbers.
```

Examples:

| Human Amount | Stored Amount |
|---:|---:|
| S$0.01 | `1` |
| S$1.00 | `100` |
| S$9.00 | `900` |
| S$100.00 | `10000` |
| S$109.00 | `10900` |
| -S$25.50 | `-2550` |

---

# 4. Naming Convention

Money columns should usually end with:

```txt
_cents
```

Examples:

```txt
subtotal_cents
gst_cents
total_cents
debit_cents
credit_cents
amount_cents
unit_amount_cents
foreign_total_cents
```

In TypeScript, variables should follow the same pattern:

```ts
const subtotalCents = 10000;
const gstCents = 900;
const totalCents = 10900;
```

This makes it clear that the value is not dollars.

---

# 5. Money Helper File

GreyMatter Ledger’s main money helper is:

```txt
lib/money.ts
```

Important exports:

```ts
type MoneyCents = number;
formatMoney()
dollarsToCents()
```

---

# 6. `MoneyCents`

The type alias:

```ts
export type MoneyCents = number;
```

This does not create a new runtime type, but it documents intent.

When you see:

```ts
amountCents: MoneyCents
```

you should understand:

```txt
This value must be integer cents.
```

---

# 7. Formatting Money

The helper:

```ts
formatMoney(amountCents)
```

turns integer cents into a human-readable Singapore dollar amount.

Example:

```ts
formatMoney(10900);
```

Output:

```txt
S$109.00
```

Example:

```ts
formatMoney(-2550);
```

Output:

```txt
-S$25.50
```

The function rejects non-integer cents.

Invalid:

```ts
formatMoney(109.99);
```

Why?

Because `109.99` looks like dollars, not cents.

Correct:

```ts
formatMoney(10999);
```

---

# 8. Converting Dollars to Cents

The helper:

```ts
dollarsToCents(value)
```

converts user-entered dollar amounts into integer cents.

Examples:

```ts
dollarsToCents("109.00"); // 10900
dollarsToCents("109.9");  // 10990
dollarsToCents("109");    // 10900
dollarsToCents("-25.50"); // -2550
```

It rejects invalid money strings:

```ts
dollarsToCents("109.999");
dollarsToCents("abc");
```

This prevents ambiguous or invalid input.

---

# 9. Why Inputs May Use Dollars but Storage Uses Cents

Users think in dollars:

```txt
100.00
```

The database stores cents:

```txt
10000
```

So the boundary is:

```txt
User input -> parse -> integer cents -> store
```

Example:

```ts
const unitAmountCents = dollarsToCents(formData.get("unitAmount"));
```

Then store:

```ts
unitAmountCents: 10000
```

Never store the raw string as the accounting amount.

---

# 10. GST and Rounding

GST is calculated with integer math.

Singapore GST 9% is represented as basis points:

```txt
900
```

Formula:

```ts
gstCents = Math.round((subtotalCents * gstRateBasisPoints) / 10000);
```

Example:

```txt
subtotalCents = 10000
gstRateBasisPoints = 900

gstCents = round(10000 × 900 / 10000)
         = 900
```

So:

```txt
Subtotal: S$100.00
GST:      S$9.00
Total:    S$109.00
```

---

# 11. Basis Points

Basis points are a whole-number way to represent percentages.

```txt
1% = 100 basis points
9% = 900 basis points
17% = 1700 basis points
20% = 2000 basis points
```

GreyMatter Ledger uses basis points for:

```txt
GST rates
CPF rates
Corporate tax rates
Exchange rates
```

Why?

Because this avoids storing percentages as floating-point values like:

```ts
0.09
0.17
0.2
```

---

# 12. Line-Level vs Invoice-Level Rounding

There are two common ways to calculate tax:

```txt
Line-level rounding
Invoice-level rounding
```

---

## Line-Level Rounding

Each line calculates GST independently.

Example:

```txt
Line 1 GST rounded
Line 2 GST rounded
Line 3 GST rounded
Total GST = sum of rounded line GST
```

GreyMatter Ledger’s current invoice and bill helpers use line-level calculations.

---

## Invoice-Level Rounding

Calculate subtotal across all lines first, then calculate GST once.

Example:

```txt
Subtotal = sum all lines
GST = round(subtotal × rate)
```

A production accounting system may need explicit policy choices here.

The tutorial uses simple line-level GST.

---

# 13. Quantity and Unit Amount

Invoice and bill lines use:

```txt
quantity
unit_amount_cents
subtotal_cents
gst_cents
total_cents
```

Example:

```txt
Quantity: 2
Unit amount: S$50.00
Subtotal: S$100.00
GST 9%: S$9.00
Total: S$109.00
```

In cents:

```txt
quantity = 2
unit_amount_cents = 5000
subtotal_cents = 10000
gst_cents = 900
total_cents = 10900
```

---

# 14. Database Amount Columns

Important amount columns include:

```txt
invoices.subtotal_cents
invoices.gst_cents
invoices.total_cents

invoice_lines.unit_amount_cents
invoice_lines.subtotal_cents
invoice_lines.gst_cents
invoice_lines.total_cents

bills.subtotal_cents
bills.gst_cents
bills.total_cents

journal_lines.debit_cents
journal_lines.credit_cents

customer_payments.amount_cents
vendor_payments.amount_cents

bank_transactions.amount_cents
```

All are integer cents.

---

# 15. Database Constraints

The database protects some money rules.

Examples:

```txt
invoice total = subtotal + GST
bill total = subtotal + GST
journal line debit >= 0
journal line credit >= 0
payment amount > 0
```

Example invoice constraint:

```txt
total_cents = subtotal_cents + gst_cents
```

This prevents inconsistent totals.

---

# 16. Negative Money

Some values may be negative.

Example:

```txt
Bank CSV amount -25.50
```

Stored as:

```txt
-2550
```

This means money left the bank.

However, journal line debit and credit amounts should not be negative.

Instead of:

```txt
Debit Bank -S$25.50
```

Use:

```txt
Credit Bank S$25.50
```

For bank imports:

```txt
Positive amount:
Debit Bank
Credit Category Account

Negative amount:
Debit Category Account
Credit Bank
```

---

# 17. Journal Lines and Money

Journal lines use:

```txt
debit_cents
credit_cents
```

Rules:

```txt
Debit cannot be negative.
Credit cannot be negative.
A line cannot have both debit and credit.
A line cannot have neither debit nor credit.
```

Valid:

```ts
{
  debitCents: 10900,
  creditCents: 0,
}
```

Valid:

```ts
{
  debitCents: 0,
  creditCents: 10900,
}
```

Invalid:

```ts
{
  debitCents: -10900,
  creditCents: 0,
}
```

Invalid:

```ts
{
  debitCents: 10900,
  creditCents: 10900,
}
```

---

# 18. Multi-Currency Amounts

GreyMatter Ledger’s base currency is:

```txt
SGD
```

Multi-currency fields include:

```txt
currency
exchange_rate_basis_points
foreign_total_cents
```

Example:

```txt
Foreign amount: USD 100.00
Exchange rate: 1.35
Base amount: SGD 135.00
```

Stored:

```txt
currency = USD
foreign_total_cents = 10000
exchange_rate_basis_points = 13500
total_cents = 13500
```

The ledger still posts base currency amounts.

---

# 19. Exchange Rate Basis Points

Exchange rates use basis points too.

Example:

```txt
1 USD = 1.35 SGD
```

Stored as:

```txt
13500
```

Formula:

```ts
baseCents = Math.round((foreignAmountCents * exchangeRateBasisPoints) / 10000);
```

Example:

```txt
10000 × 13500 / 10000 = 13500
```

So:

```txt
USD 100.00 = SGD 135.00
```

---

# 20. Display vs Storage

Always distinguish display values from storage values.

Display:

```txt
S$109.00
```

Storage:

```txt
10900
```

Input:

```txt
"109.00"
```

Parsed:

```txt
10900
```

Never confuse these layers.

---

# 21. Common Money Mistakes

## Mistake 1 — Storing Dollars in Cents Columns

Wrong:

```ts
totalCents: 109.00
```

Correct:

```ts
totalCents: 10900
```

---

## Mistake 2 — Passing Dollars to `formatMoney`

Wrong:

```ts
formatMoney(109.00);
```

Correct:

```ts
formatMoney(10900);
```

---

## Mistake 3 — Using Floating GST Rate

Wrong:

```ts
const gst = subtotal * 0.09;
```

Correct:

```ts
const gstCents = Math.round((subtotalCents * 900) / 10000);
```

---

## Mistake 4 — Negative Journal Line Amounts

Wrong:

```ts
debitCents: -10000
```

Correct:

```ts
creditCents: 10000
```

if value is moving in the opposite direction.

---

## Mistake 5 — Ignoring Rounding Policy

If you add multi-line invoices, be clear whether GST is rounded:

```txt
per line
```

or:

```txt
per invoice
```

---

# 22. Testing Money Logic

Money tests live in:

```txt
tests/money.test.ts
tests/gst.test.ts
tests/currency.test.ts
```

Run:

```bash
pnpm test
```

Important test expectations:

```txt
formatMoney(10900) = S$109.00
dollarsToCents("109.00") = 10900
S$100 at 9% GST = S$9 GST
USD 100 at 1.35 = SGD 135
```

---

# 23. Developer Checklist for Money Features

When adding a money feature, ask:

```txt
Are all stored amounts integer cents?
Are all user inputs parsed safely?
Are all rates stored as basis points?
Are negative amounts allowed only where appropriate?
Do database constraints protect totals?
Do journal lines avoid negative debit/credit values?
Are display values formatted with formatMoney?
Are tests added for rounding and invalid input?
```

---

# 24. Recommended Naming

Use names like:

```ts
amountCents
subtotalCents
gstCents
totalCents
unitAmountCents
debitCents
creditCents
foreignTotalCents
```

Avoid ambiguous names like:

```ts
amount
total
price
value
```

unless the unit is obvious.

---

# 25. Final Mental Model

Money handling in GreyMatter Ledger follows this pipeline:

```txt
User enters dollars
  |
  v
Convert to integer cents
  |
  v
Calculate using integer math
  |
  v
Store cents in database
  |
  v
Post cents to journal
  |
  v
Reports summarize cents
  |
  v
Format cents for display
```

The most important rule:

```txt
Never store financial money as floating-point dollars.
```

The second rule:

```txt
Use basis points for rates.
```

The third rule:

```txt
Round deliberately and test the result.
```
