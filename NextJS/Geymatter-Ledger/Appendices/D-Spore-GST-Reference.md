# Appendix D — Singapore GST Reference

This appendix explains how **GreyMatter Ledger** models GST for Singapore-oriented accounting workflows.

It is designed for developers building or extending the app.

This is **not tax advice** and is **not a complete GST filing guide**.

Singapore GST rules can be complex. Real-world GST treatment may depend on:

```txt
GST registration status
Type of supply
Place of supply
Customer location
Import rules
Exempt supplies
Zero-rated supplies
Deemed supplies
Bad debt relief
Partial exemption
GST schemes
Adjustments
IRAS filing rules
```

Before using any GST report for real filing, consult a qualified Singapore accountant or tax professional and verify requirements with IRAS.

---

# 1. What GST Is

GST stands for:

```txt
Goods and Services Tax
```

It is a consumption tax applied to many goods and services in Singapore.

In a simplified GST-registered business workflow:

```txt
You collect GST from customers on taxable sales.
You pay GST to vendors on taxable purchases.
You report the net GST position.
```

Simplified formula:

```txt
Net GST Payable = GST Output Tax - GST Input Tax
```

If output tax is larger:

```txt
GST is payable to IRAS.
```

If input tax is larger:

```txt
GST may be refundable, subject to rules.
```

---

# 2. GST in GreyMatter Ledger

GreyMatter Ledger models GST using two seeded accounts:

```txt
1400 GST Input Tax
2110 GST Output Tax
```

These are part of the Singapore-friendly chart of accounts.

---

## GST Input Tax

Account:

```txt
1400 GST Input Tax
```

Type:

```txt
asset
```

Meaning:

```txt
GST paid on purchases that may be claimable from IRAS.
```

Normal balance:

```txt
Debit
```

Typical posting:

```txt
Debit GST Input Tax
```

---

## GST Output Tax

Account:

```txt
2110 GST Output Tax
```

Type:

```txt
liability
```

Meaning:

```txt
GST collected from customers on taxable sales.
```

Normal balance:

```txt
Credit
```

Typical posting:

```txt
Credit GST Output Tax
```

---

# 3. GST Rate Representation

GreyMatter Ledger stores GST rates as **basis points**.

Basis points are hundredths of a percent.

```txt
1%   = 100 basis points
9%   = 900 basis points
0.5% = 50 basis points
```

So Singapore GST at 9% is represented as:

```ts
900
```

The helper constant is:

```ts
DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS = 900;
```

Location:

```txt
lib/accounting/gst.ts
```

---

## Why Basis Points?

Because financial software should avoid floating-point math where possible.

Avoid:

```ts
const gst = amount * 0.09;
```

Prefer integer math:

```ts
const gstCents = Math.round((subtotalCents * 900) / 10000);
```

For example:

```txt
Subtotal: 10000 cents
Rate:     900 basis points

GST = round(10000 × 900 / 10000)
    = 900 cents
```

So:

```txt
S$100.00 + 9% GST = S$109.00
```

---

# 4. GST Helper Functions

GST helpers live in:

```txt
lib/accounting/gst.ts
```

Important functions:

```ts
calculateGstFromExclusiveAmount()
calculateInvoiceLineTotals()
sumInvoiceLineTotals()
```

---

## `calculateGstFromExclusiveAmount()`

Example:

```ts
const result = calculateGstFromExclusiveAmount(10000, 900);
```

Result:

```ts
{
  subtotalCents: 10000,
  gstRateBasisPoints: 900,
  gstCents: 900,
  totalCents: 10900
}
```

Meaning:

```txt
Subtotal: S$100.00
GST:      S$9.00
Total:    S$109.00
```

---

## `calculateInvoiceLineTotals()`

Despite the name, this helper is also used for bill lines.

Example:

```ts
const result = calculateInvoiceLineTotals({
  quantity: 2,
  unitAmountCents: 5000,
  gstRateBasisPoints: 900,
});
```

Calculation:

```txt
Quantity: 2
Unit:     S$50.00
Subtotal: S$100.00
GST:      S$9.00
Total:    S$109.00
```

Result:

```ts
{
  quantity: 2,
  unitAmountCents: 5000,
  subtotalCents: 10000,
  gstRateBasisPoints: 900,
  gstCents: 900,
  totalCents: 10900
}
```

---

# 5. GST on Customer Invoices

When a GST-taxable invoice is issued, the customer owes the full GST-inclusive amount.

Example:

```txt
Invoice subtotal: S$100.00
GST 9%:           S$9.00
Total:            S$109.00
```

Accounting entry:

```txt
Debit  Accounts Receivable   S$109.00
Credit Sales Revenue         S$100.00
Credit GST Output Tax        S$9.00
```

---

## Why Accounts Receivable Is Debited

Accounts Receivable is an asset.

The customer owes the business money.

Assets increase with debits.

```txt
Debit Accounts Receivable S$109.00
```

---

## Why Sales Revenue Is Credited

Sales Revenue is income.

Income increases with credits.

```txt
Credit Sales Revenue S$100.00
```

---

## Why GST Output Tax Is Credited

GST Output Tax is a liability.

The business has collected GST that may be payable to IRAS.

Liabilities increase with credits.

```txt
Credit GST Output Tax S$9.00
```

---

# 6. GST on Vendor Bills

When the business receives a vendor bill with GST, the GST may be claimable as input tax, subject to rules.

Example:

```txt
Bill subtotal: S$100.00
GST 9%:        S$9.00
Total:         S$109.00
```

Accounting entry:

```txt
Debit  Purchases             S$100.00
Debit  GST Input Tax         S$9.00
Credit Accounts Payable      S$109.00
```

---

## Why Purchases Is Debited

Purchases is an expense.

Expenses increase with debits.

```txt
Debit Purchases S$100.00
```

---

## Why GST Input Tax Is Debited

GST Input Tax is modeled as an asset in this tutorial.

It may be claimable from IRAS.

Assets increase with debits.

```txt
Debit GST Input Tax S$9.00
```

---

## Why Accounts Payable Is Credited

Accounts Payable is a liability.

The business owes the vendor.

Liabilities increase with credits.

```txt
Credit Accounts Payable S$109.00
```

---

# 7. Customer Payments Do Not Affect GST

When a customer pays an invoice, GST is not recorded again.

Invoice posting already recorded GST Output Tax.

Payment only settles receivable.

Customer payment entry:

```txt
Debit  Bank                  S$109.00
Credit Accounts Receivable   S$109.00
```

No GST line appears here.

Why?

Because GST was already recorded when the invoice was issued.

---

# 8. Vendor Payments Do Not Affect GST

When the business pays a vendor bill, GST is not recorded again.

Bill posting already recorded GST Input Tax.

Vendor payment entry:

```txt
Debit  Accounts Payable      S$109.00
Credit Bank                  S$109.00
```

No GST line appears here.

Why?

Because GST was already recorded when the bill was received.

---

# 9. GST and Reports

GST generally does not appear in Profit & Loss in this simplified model.

Why?

Because GST accounts are Balance Sheet accounts:

```txt
1400 GST Input Tax = asset
2110 GST Output Tax = liability
```

Profit & Loss includes:

```txt
income
expense
```

Balance Sheet includes:

```txt
asset
liability
equity
```

So GST Input Tax and GST Output Tax appear on the Balance Sheet or GST report, not P&L.

---

# 10. GST F5-Style Report

GreyMatter Ledger includes a simplified GST F5-style report at:

```txt
/reports/gst-f5
```

It calculates:

```txt
GST Output Tax
GST Input Tax
Net GST Payable / Refundable
```

From journal line balances.

---

## Formula

```txt
Net GST Payable = GST Output Tax - GST Input Tax
```

Example:

```txt
GST Output Tax: S$900
GST Input Tax:  S$300
Net GST:        S$600 payable
```

If input tax is greater:

```txt
GST Output Tax: S$300
GST Input Tax:  S$900
Net GST:        S$600 refundable
```

---

## Report Service

The GST report service lives in:

```txt
services/reports/gst-f5-service.ts
```

It looks for account codes:

```txt
2110
1400
```

Specifically:

```txt
2110 GST Output Tax
1400 GST Input Tax
```

---

# 11. Important Limitation of Current GST Report

The tutorial GST report is simplified.

It does **not** fully implement official GST F5 boxes.

It does not separately calculate:

```txt
Total value of standard-rated supplies
Total value of zero-rated supplies
Exempt supplies
Total purchases
Imported services
Adjustments
Bad debt relief
Deemed supplies
Partial exemption
Tourist refund scheme
Major exporter scheme
Other GST schemes
```

It is best understood as:

```txt
A ledger-based GST output/input summary.
```

Not as:

```txt
A complete IRAS filing system.
```

---

# 12. GST in Invoice Tables

Invoices store GST values in:

```txt
invoices.subtotal_cents
invoices.gst_cents
invoices.total_cents
```

Invoice lines store:

```txt
invoice_lines.subtotal_cents
invoice_lines.gst_rate_basis_points
invoice_lines.gst_cents
invoice_lines.total_cents
```

Database constraint:

```txt
total_cents = subtotal_cents + gst_cents
```

This protects against inconsistent invoice totals.

---

# 13. GST in Bill Tables

Bills store GST values in:

```txt
bills.subtotal_cents
bills.gst_cents
bills.total_cents
```

Bill lines store:

```txt
bill_lines.subtotal_cents
bill_lines.gst_rate_basis_points
bill_lines.gst_cents
bill_lines.total_cents
```

Database constraint:

```txt
total_cents = subtotal_cents + gst_cents
```

---

# 14. Zero-Rated GST

The helper supports a GST rate of:

```txt
0 basis points
```

Example:

```ts
calculateGstFromExclusiveAmount(10000, 0);
```

Result:

```txt
Subtotal: S$100.00
GST:      S$0.00
Total:    S$100.00
```

However, the current app does not fully distinguish:

```txt
zero-rated
exempt
out-of-scope
standard-rated
```

Those would require additional fields and reporting rules.

---

# 15. GST Rounding

The helper rounds GST to the nearest cent:

```ts
Math.round((subtotalCents * gstRateBasisPoints) / 10000)
```

Example:

```txt
Subtotal: 999 cents
GST 9%:   89.91 cents
Rounded:  90 cents
```

This gives:

```txt
Subtotal: S$9.99
GST:      S$0.90
Total:    S$10.89
```

Real-world GST rounding policies can depend on invoice-level vs line-level treatment and business policy.

The tutorial uses line-level calculation.

---

# 16. GST Test Coverage

GST tests live in:

```txt
tests/gst.test.ts
tests/gst-f5-report.test.ts
```

They verify:

```txt
9% GST on S$100 = S$9
Zero-rated GST works
Rounding works
Invalid values are rejected
GST report calculates payable/refundable amounts
```

Run:

```bash
pnpm test
```

---

# 17. Common GST Entries

## 17.1 GST Invoice

```txt
Debit  Accounts Receivable   Total
Credit Sales Revenue         Subtotal
Credit GST Output Tax        GST
```

---

## 17.2 Customer Payment

```txt
Debit  Bank                  Total
Credit Accounts Receivable   Total
```

No GST line.

---

## 17.3 GST Vendor Bill

```txt
Debit  Purchases             Subtotal
Debit  GST Input Tax         GST
Credit Accounts Payable      Total
```

---

## 17.4 Vendor Payment

```txt
Debit  Accounts Payable      Total
Credit Bank                  Total
```

No GST line.

---

## 17.5 Net GST Settlement Payment

This was not fully implemented in the tutorial, but a simplified GST payment to IRAS might look like:

```txt
Debit  GST Payable / GST Output Tax    Net payable
Credit Bank                            Net payable
```

Depending on how GST control accounts are structured, a production system may use a dedicated GST clearing account.

---

# 18. Recommended Future GST Enhancements

A production GST module should consider adding:

```txt
GST registration settings
GST registration number
GST effective date
Standard-rated supply tracking
Zero-rated supply tracking
Exempt supply tracking
Out-of-scope transaction handling
GST F5 box mapping
GST adjustment entries
GST settlement workflow
GST filing period locks
GST audit report
GST transaction export
IRAS-friendly summaries
```

---

# 19. Developer Checklist for GST Features

When adding a GST-related feature, check:

```txt
Are amounts stored in integer cents?
Is the GST rate stored as basis points?
Are subtotal, GST, and total internally consistent?
Does the database enforce total = subtotal + GST?
Does the journal entry balance?
Does GST affect the right account?
Does the report come from journal lines?
Is tenant isolation enforced?
```

---

# 20. Final GST Mental Model

For developers, remember:

```txt
Invoices collect GST.
Bills pay GST.
GST Output Tax is usually a liability.
GST Input Tax is usually an asset.
Payments do not record GST again.
GST reports should summarize ledger balances.
```

The simplest formula:

```txt
Net GST = GST Output Tax - GST Input Tax
```

The safest technical rule:

```txt
Calculate GST once, store integer cents, post balanced journal entries.
```
