# Primer 4 — Singapore GST for Software Builders

**Product:** GreyMatter Ledger  
**Document type:** Primer  
**Audience:** Developers, technical founders, product engineers, accountants reviewing software behavior  
**Goal:** Explain Singapore GST concepts as they apply to accounting software design  

---

# 1. Important Disclaimer

This primer is educational.

It is not GST advice.

Singapore GST rules can be complex and may depend on:

```txt
GST registration status
Type of supply
Customer location
Place of supply
Import rules
Exempt supplies
Zero-rated supplies
Deemed supplies
GST schemes
Bad debt relief
Partial exemption
Adjustments
Filing period rules
```

Before using any GST-related software output for real filing or business decisions, consult:

```txt
IRAS guidance
A qualified Singapore accountant
A qualified tax professional
```

GreyMatter Ledger’s GST implementation is a simplified educational model.

---

# 2. What GST Is

GST stands for:

```txt
Goods and Services Tax
```

In Singapore, GST is a consumption tax applied to many goods and services.

For a GST-registered business, two common GST flows are:

```txt
Collect GST from customers
Pay GST to vendors
```

The business then reports its net GST position.

Simplified formula:

```txt
Net GST = GST Output Tax - GST Input Tax
```

If output tax is greater than input tax:

```txt
GST payable
```

If input tax is greater than output tax:

```txt
GST refundable or claimable, subject to rules
```

---

# 3. GST Output Tax

GST Output Tax is GST collected from customers.

Example:

```txt
You invoice a customer S$100.00 + 9% GST.
GST collected = S$9.00.
```

Accounting:

```txt
Credit GST Output Tax S$9.00
```

Why credit?

Because GST Output Tax is treated as a liability.

You collected GST that may be payable to IRAS.

In GreyMatter Ledger:

```txt
2110 GST Output Tax
```

Account type:

```txt
liability
```

Normal balance:

```txt
credit
```

---

# 4. GST Input Tax

GST Input Tax is GST paid to vendors.

Example:

```txt
A vendor bills you S$100.00 + 9% GST.
GST paid = S$9.00.
```

Accounting:

```txt
Debit GST Input Tax S$9.00
```

Why debit?

In this tutorial, GST Input Tax is modeled as an asset because it may be claimable from IRAS, subject to rules.

In GreyMatter Ledger:

```txt
1400 GST Input Tax
```

Account type:

```txt
asset
```

Normal balance:

```txt
debit
```

---

# 5. GST Rate as Basis Points

GreyMatter Ledger stores GST rates as basis points.

Basis points are hundredths of a percent.

```txt
1% = 100 basis points
9% = 900 basis points
```

So 9% GST is:

```ts
900
```

Why use basis points?

Because software should avoid floating-point money calculations.

Avoid:

```ts
amount * 0.09
```

Prefer:

```ts
Math.round((amountCents * 900) / 10000)
```

---

# 6. GST Calculation Example

Invoice subtotal:

```txt
S$100.00
```

Stored as cents:

```txt
10000
```

GST rate:

```txt
900 basis points
```

Calculation:

```txt
10000 × 900 / 10000 = 900
```

So:

```txt
GST = 900 cents = S$9.00
```

Total:

```txt
10000 + 900 = 10900
```

Human display:

```txt
S$109.00
```

---

# 7. GST in Customer Invoices

When the company issues a GST-taxable invoice:

```txt
Customer owes total amount.
Business earns revenue before GST.
Business records GST collected.
```

Example:

```txt
Subtotal: S$100.00
GST:      S$9.00
Total:    S$109.00
```

Journal entry:

```txt
Debit  Accounts Receivable   S$109.00
Credit Sales Revenue         S$100.00
Credit GST Output Tax        S$9.00
```

In code, this uses:

```txt
1100 Accounts Receivable
4000 Sales Revenue
2110 GST Output Tax
```

---

# 8. Why GST Is Not Revenue

GST collected from customers is not revenue.

If you invoice:

```txt
S$100 service fee + S$9 GST
```

Revenue is:

```txt
S$100
```

Not:

```txt
S$109
```

The extra S$9 is GST collected.

That GST is tracked separately as a liability.

This is why the invoice entry credits:

```txt
Sales Revenue S$100
GST Output Tax S$9
```

not:

```txt
Sales Revenue S$109
```

---

# 9. GST in Vendor Bills

When the company receives a GST-taxable vendor bill:

```txt
Business records purchase or expense before GST.
Business records GST input tax.
Business records amount owed to vendor.
```

Example:

```txt
Subtotal: S$100.00
GST:      S$9.00
Total:    S$109.00
```

Journal entry:

```txt
Debit  Purchases             S$100.00
Debit  GST Input Tax         S$9.00
Credit Accounts Payable      S$109.00
```

In code, this uses:

```txt
5100 Purchases
1400 GST Input Tax
2000 Accounts Payable
```

---

# 10. Why GST Is Not Usually an Expense

If GST input tax is claimable, it is not treated as an expense in this simplified model.

For a vendor bill:

```txt
Subtotal = expense
GST = input tax asset
Total = payable
```

So:

```txt
Debit Purchases S$100
Debit GST Input Tax S$9
Credit Accounts Payable S$109
```

Not:

```txt
Debit Purchases S$109
Credit Accounts Payable S$109
```

However, real GST treatment can vary.

Some GST may be blocked or non-claimable.

That would require more advanced rules.

---

# 11. Payments Do Not Record GST Again

This is important.

When a customer pays an invoice, GST is not recorded again.

Invoice already recorded GST Output Tax.

Customer payment only settles the receivable:

```txt
Debit  Bank
Credit Accounts Receivable
```

Similarly, vendor payment does not record GST again.

Bill already recorded GST Input Tax.

Vendor payment only settles the payable:

```txt
Debit  Accounts Payable
Credit Bank
```

---

# 12. GST Accounts in the Chart of Accounts

GreyMatter Ledger seeds these GST-related accounts:

```txt
1400 GST Input Tax
2100 GST Payable
2110 GST Output Tax
```

The most important for current workflows:

```txt
1400 GST Input Tax
2110 GST Output Tax
```

`2100 GST Payable` exists as a useful future control account.

A more advanced GST settlement workflow may clear GST Input and Output Tax into a net GST Payable account.

---

# 13. GST F5-Style Report

GreyMatter Ledger includes:

```txt
/reports/gst-f5
```

This report summarizes:

```txt
GST Output Tax
GST Input Tax
Net GST Payable / Refundable
```

Simplified formula:

```txt
Net GST Payable = GST Output Tax - GST Input Tax
```

Example:

```txt
Output Tax: S$180.00
Input Tax:  S$27.00
Net GST:    S$153.00 payable
```

---

# 14. Why the GST Report Uses Journal Lines

The GST report reads ledger balances.

It does not simply add invoice rows and bill rows.

Why?

Because the ledger is the accounting source of truth.

If a journal entry is reversed, reports should reflect that.

If a GST-related bank transaction is posted, reports should reflect that too.

Ledger-based reporting is more reliable.

---

# 15. GST and Profit & Loss

GST Input Tax and GST Output Tax should generally not appear in Profit & Loss in this simplified model.

Why?

Because they are not income or expense accounts.

They are:

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

---

# 16. GST and Balance Sheet

GST accounts appear on the Balance Sheet.

Examples:

```txt
GST Input Tax -> asset
GST Output Tax -> liability
```

If output tax is higher than input tax, the business may have net GST payable.

If input tax is higher, the business may have net GST recoverable.

---

# 17. Zero-Rated GST

A GST rate of 0% is represented as:

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

However, a real system should distinguish between:

```txt
zero-rated
exempt
out-of-scope
standard-rated
```

The tutorial does not fully model those categories.

---

# 18. Exempt and Out-of-Scope Supplies

The tutorial does not fully implement exempt and out-of-scope supply tracking.

A production system may need fields like:

```txt
tax_code
supply_type
gst_treatment
```

Examples:

```txt
SR - Standard-rated
ZR - Zero-rated
ES - Exempt supply
OS - Out-of-scope
```

These would affect GST reports differently.

---

# 19. Tax Codes as Future Enhancement

A more complete GST architecture might introduce a `tax_codes` table:

```txt
tax_codes
  id
  organization_id
  code
  name
  rate_basis_points
  treatment
  is_active
```

Example tax codes:

```txt
SR9
ZR0
EXEMPT
OUT_OF_SCOPE
IMPORT
```

Invoice and bill lines would reference:

```txt
tax_code_id
```

instead of storing only:

```txt
gst_rate_basis_points
```

---

# 20. GST Rounding

GreyMatter Ledger uses:

```ts
Math.round((subtotalCents * gstRateBasisPoints) / 10000)
```

This rounds GST to the nearest cent.

Example:

```txt
Subtotal: S$9.99
GST 9%:   S$0.8991
Rounded:  S$0.90
```

Stored:

```txt
subtotal_cents = 999
gst_cents = 90
total_cents = 1089
```

---

# 21. Line-Level Rounding

The current helper calculates GST at the line level.

For a single-line invoice, this is straightforward.

For multi-line invoices, total GST would be:

```txt
sum of rounded line GST
```

Some businesses may use invoice-level rounding.

That would require explicit policy and implementation.

---

# 22. GST Data Stored on Invoices

Invoice header stores:

```txt
subtotal_cents
gst_cents
total_cents
```

Invoice line stores:

```txt
quantity
unit_amount_cents
subtotal_cents
gst_rate_basis_points
gst_cents
total_cents
```

Database checks enforce:

```txt
total_cents = subtotal_cents + gst_cents
```

---

# 23. GST Data Stored on Bills

Bill header stores:

```txt
subtotal_cents
gst_cents
total_cents
```

Bill line stores:

```txt
quantity
unit_amount_cents
subtotal_cents
gst_rate_basis_points
gst_cents
total_cents
```

Database checks enforce:

```txt
total_cents = subtotal_cents + gst_cents
```

---

# 24. GST Settlement as Future Feature

The current tutorial does not fully implement GST settlement/payment to IRAS.

A future GST settlement workflow might:

1. Calculate net GST payable.
2. Create a GST settlement journal entry.
3. Clear GST Output Tax and GST Input Tax.
4. Record payment to IRAS.

Simplified example if net GST payable is S$153:

```txt
Debit  GST Output Tax       S$180
Credit GST Input Tax        S$27
Credit Bank / GST Payable   S$153
```

Or using a GST Payable clearing account.

The exact accounting structure should be reviewed by an accountant.

---

# 25. GST and Reversals

If an invoice or bill journal entry is reversed, GST impact is reversed too.

Original invoice:

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

Reversal:

```txt
Debit  Sales Revenue
Debit  GST Output Tax
Credit Accounts Receivable
```

Reports reflect both entries because they are ledger-based.

---

# 26. GST and Auditability

GST-related actions should be auditable.

Important events:

```txt
invoice.created
bill.created
journal_entry.reversed
```

Audit logs help answer:

```txt
Who created the GST invoice?
Who reversed the GST entry?
When did it happen?
```

---

# 27. GST and Multi-Tenancy

GST reports must be scoped by organization.

Company A’s GST must not include Company B’s invoices or bills.

Always filter by:

```txt
organization_id
```

GST report service must use active organization context.

---

# 28. GST Test Cases for Developers

A good GST test suite should include:

```txt
S$100 at 9% = S$9 GST
Zero-rated GST = S$0
Rounding edge cases
Negative amount rejection
Decimal cent rejection
Invoice total = subtotal + GST
Bill total = subtotal + GST
GST report payable case
GST report refundable case
Missing GST accounts default to zero
```

Existing test files:

```txt
tests/gst.test.ts
tests/gst-f5-report.test.ts
```

---

# 29. Common GST Mistakes in Software

## Mistake 1 — Treating GST as Revenue

Wrong:

```txt
Credit Sales Revenue S$109
```

Correct:

```txt
Credit Sales Revenue S$100
Credit GST Output Tax S$9
```

---

## Mistake 2 — Treating Claimable GST as Expense

Wrong in simplified claimable case:

```txt
Debit Purchases S$109
```

Correct:

```txt
Debit Purchases S$100
Debit GST Input Tax S$9
```

---

## Mistake 3 — Recording GST Again on Payment

Wrong:

```txt
Customer payment includes GST lines again.
```

Correct:

```txt
Customer payment only settles Accounts Receivable.
```

---

## Mistake 4 — Using Floating Rates

Wrong:

```ts
subtotal * 0.09
```

Correct:

```ts
Math.round((subtotalCents * 900) / 10000)
```

---

## Mistake 5 — Reporting from Invoice Rows Only

Risky:

```txt
GST report sums invoice.gst_cents only.
```

Better:

```txt
GST report reads ledger balances for GST accounts.
```

This captures reversals and adjustments.

---

# 30. Developer Checklist for GST Features

When adding GST features, ask:

```txt
Is GST rate stored as basis points?
Are amounts stored as integer cents?
Is GST calculated server-side?
Does total equal subtotal + GST?
Does the database enforce totals?
Does the journal entry balance?
Are GST accounts correctly typed?
Does the report use journal lines?
Is organization_id enforced?
Does the UI show disclaimers where needed?
```

---

# 31. Production GST Questions

Before turning this into production GST filing software, answer:

```txt
Is the company GST-registered?
What is the GST registration number?
What is the effective GST registration date?
Which supplies are standard-rated?
Which supplies are zero-rated?
Which supplies are exempt?
Which transactions are out-of-scope?
Are input tax claims restricted?
Are imports handled?
Are adjustments handled?
Are GST periods locked after filing?
How are GST F5 boxes mapped?
How are GST settlements posted?
```

---

# 32. Final GST Mental Model

For developers:

```txt
GST collected from customers is not revenue.
GST paid to vendors is not always an expense.
GST belongs in dedicated GST accounts.
Payments do not record GST again.
GST reports should come from journal lines.
```

In GreyMatter Ledger:

```txt
Customer invoice:
  Credit GST Output Tax

Vendor bill:
  Debit GST Input Tax

GST report:
  Output Tax - Input Tax
```

The key implementation rule:

```txt
Calculate GST in integer cents, post it to the correct account, and report it from the ledger.
```
