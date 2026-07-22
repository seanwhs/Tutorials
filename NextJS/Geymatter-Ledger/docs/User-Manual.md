# User Manual Addendum — End-to-End Walkthrough with a Fictitious Company

This section should be appended to the existing **GreyMatter Ledger User Manual**.

It keeps the full manual intact and adds a practical, realistic walkthrough showing how a user would use **all major GreyMatter Ledger features** for a fictitious Singapore company.

---

# End-to-End Walkthrough: Merlion Creative Pte. Ltd.

In this walkthrough, we will operate a fictional Singapore business:

```txt
Merlion Creative Pte. Ltd.
```

Merlion Creative provides design, branding, and digital consulting services to customers in Singapore.

The company:

- Issues GST-aware invoices
- Receives vendor bills
- Records customer payments
- Pays vendors
- Imports bank transactions
- Reconciles bank activity
- Reviews financial reports
- Uses audit logs
- Uses background jobs
- Sets up recurring invoices
- Reviews Singapore estimate modules

---

# 1. Company Profile

## Company Name

```txt
Merlion Creative Pte. Ltd.
```

## Business Type

```txt
Creative and digital consulting services
```

## Base Currency

```txt
SGD
```

## GST Treatment

For tutorial purposes, we assume the company is GST-registered and charges 9% GST.

```txt
GST rate: 9%
GST basis points: 900
```

## Main Customer

```txt
Orchard Retail Group Pte. Ltd.
```

## Main Vendor

```txt
CloudStack Hosting SG Pte. Ltd.
```

## Main Bank Account

```txt
1000 Bank
```

---

# 2. Sign In and Create Company Workspace

## Step 1 — Open GreyMatter Ledger

Open the app.

Local development:

```txt
http://localhost:3000
```

Production:

```txt
https://your-production-domain.com
```

Click:

```txt
Sign in
```

or:

```txt
Sign up
```

---

## Step 2 — Create Organization

After signing in, create a company workspace.

Open:

```txt
/onboarding/organization
```

Create:

```txt
Merlion Creative Pte. Ltd.
```

After creation, the app redirects to:

```txt
/dashboard
```

---

## Step 3 — Confirm Active Organization

In the app header, confirm the active company says something like:

```txt
Company: Merlion Creative Pte. Ltd.
```

You can also verify organization context at:

```txt
/settings/auth-status
```

You should see:

```txt
Current user profile
Active Clerk organization
Synced database organization
```

---

# 3. Seed the Chart of Accounts

Before entering real transactions, Merlion Creative needs a chart of accounts.

Open:

```txt
/accounts
```

If no accounts exist, click:

```txt
Seed default accounts
```

This creates a Singapore-friendly chart of accounts.

Important seeded accounts include:

```txt
1000 Bank
1100 Accounts Receivable
1400 GST Input Tax
2000 Accounts Payable
2110 GST Output Tax
3000 Share Capital
4000 Sales Revenue
5100 Purchases
6000 Rent Expense
6200 CPF Employer Contributions
6300 Software and Subscriptions
6400 Professional Fees
6700 Bank Charges
7000 Income Tax Expense
```

---

# 4. Maintain the Chart of Accounts

GreyMatter Ledger lets you maintain accounts after seeding.

---

## 4.1 Add a Custom Account

Merlion Creative wants to track design tools separately.

Open:

```txt
/accounts
```

In the custom account form, enter:

```txt
Code: 6310
Name: Design Software Subscriptions
Type: Expenses
Description: Adobe, Figma, stock assets, and other design tools.
```

Click:

```txt
Create account
```

The account appears under:

```txt
Expenses
```

Because it is user-created:

```txt
Source: Custom
```

---

## 4.2 Deactivate an Account

Suppose Merlion Creative does not use petty cash.

Find:

```txt
1010 Cash on Hand
```

Click:

```txt
Deactivate
```

The account becomes:

```txt
Inactive
```

Inactive accounts remain visible but should not be used for new postings.

---

## 4.3 Reactivate an Account

If the company later starts using petty cash, click:

```txt
Reactivate
```

The account becomes active again.

---

# 5. Create Customer

Merlion Creative has a customer:

```txt
Orchard Retail Group Pte. Ltd.
```

Open:

```txt
/customers
```

Fill in:

```txt
Name: Orchard Retail Group Pte. Ltd.
Email: finance@orchardretail.example.com
Phone: +65 6123 4567
Billing address: 10 Orchard Road, Singapore 238800
Notes: Monthly digital marketing and creative services client.
```

Click:

```txt
Create customer
```

The customer now appears in the customers table.

---

# 6. Create Vendor

Merlion Creative uses cloud hosting services from:

```txt
CloudStack Hosting SG Pte. Ltd.
```

Open:

```txt
/vendors
```

Fill in:

```txt
Name: CloudStack Hosting SG Pte. Ltd.
Email: billing@cloudstack.example.com
Phone: +65 6234 5678
Billing address: 80 Robinson Road, Singapore 068898
Notes: Monthly cloud hosting and infrastructure provider.
```

Click:

```txt
Create vendor
```

The vendor now appears in the vendors table.

---

# 7. Create a GST-Aware Customer Invoice

Merlion Creative performs branding consulting work for Orchard Retail Group.

Invoice details:

```txt
Service: Brand strategy consulting
Subtotal: S$2,000.00
GST 9%:   S$180.00
Total:    S$2,180.00
```

Open:

```txt
/invoices
```

Fill in:

```txt
Customer: Orchard Retail Group Pte. Ltd.
Issue date: 2026-02-01
Due date: 2026-03-03
Description: Brand strategy consulting services
Quantity: 1
Unit amount: 2000.00
GST basis points: 900
Notes: February brand strategy engagement.
```

Click:

```txt
Create and post invoice
```

---

## What GreyMatter Ledger Does

The app:

1. Creates invoice header.
2. Creates invoice line.
3. Calculates GST.
4. Posts a journal entry.
5. Links the invoice to the journal entry.
6. Writes an audit log.
7. Sends an `invoice.created` background event.

---

## Invoice Totals

The invoice shows:

```txt
Subtotal: S$2,000.00
GST:      S$180.00
Total:    S$2,180.00
```

---

## Journal Entry Posted

GreyMatter Ledger posts:

```txt
Debit  1100 Accounts Receivable   S$2,180.00
Credit 4000 Sales Revenue         S$2,000.00
Credit 2110 GST Output Tax        S$180.00
```

This entry balances:

```txt
Debits:  S$2,180.00
Credits: S$2,180.00
```

---

# 8. View Invoice Detail

Open:

```txt
/invoices
```

Click the invoice number, for example:

```txt
INV-2026-0001
```

The detail page shows:

- Customer details
- Invoice dates
- Invoice line
- Subtotal
- GST
- Total
- Linked journal entry
- Journal lines

Confirm that the linked journal entry shows:

```txt
Balanced
```

---

# 9. Record Customer Payment

Orchard Retail Group pays the invoice in full.

Open the invoice detail page.

Find:

```txt
Record full payment
```

Enter:

```txt
Payment date: 2026-02-15
Reference: ORCHARD-PAY-001
```

Click:

```txt
Record payment
```

---

## What GreyMatter Ledger Does

The app:

1. Creates a customer payment row.
2. Posts a payment journal entry.
3. Marks invoice as paid.
4. Links payment to journal entry.
5. Writes audit log.

---

## Payment Journal Entry

```txt
Debit  1000 Bank                  S$2,180.00
Credit 1100 Accounts Receivable   S$2,180.00
```

Important:

```txt
Sales Revenue is not credited again.
```

Revenue was already recorded when the invoice was created.

---

# 10. Create a GST-Aware Vendor Bill

CloudStack Hosting sends Merlion Creative a vendor bill.

Bill details:

```txt
Cloud hosting services
Subtotal: S$300.00
GST 9%:   S$27.00
Total:    S$327.00
```

Open:

```txt
/bills
```

Fill in:

```txt
Vendor: CloudStack Hosting SG Pte. Ltd.
Issue date: 2026-02-05
Due date: 2026-03-06
Description: Cloud hosting services
Quantity: 1
Unit amount: 300.00
GST basis points: 900
Notes: February hosting services.
```

Click:

```txt
Create and post bill
```

---

## Bill Totals

The bill shows:

```txt
Subtotal: S$300.00
GST:      S$27.00
Total:    S$327.00
```

---

## Bill Journal Entry

GreyMatter Ledger posts:

```txt
Debit  5100 Purchases             S$300.00
Debit  1400 GST Input Tax         S$27.00
Credit 2000 Accounts Payable      S$327.00
```

This entry balances:

```txt
Debits:  S$327.00
Credits: S$327.00
```

---

# 11. View Bill Detail

Open:

```txt
/bills
```

Click the bill number, for example:

```txt
BILL-2026-0001
```

The detail page shows:

- Vendor details
- Bill dates
- Bill line
- Subtotal
- GST input tax
- Total payable
- Linked journal entry
- Journal lines

Confirm the journal entry shows:

```txt
Balanced
```

---

# 12. Record Vendor Payment

Merlion Creative pays CloudStack Hosting.

Open the bill detail page.

Find:

```txt
Record full payment
```

Enter:

```txt
Payment date: 2026-02-20
Reference: CLOUDSTACK-PAY-001
```

Click:

```txt
Record payment
```

---

## Vendor Payment Journal Entry

GreyMatter Ledger posts:

```txt
Debit  2000 Accounts Payable      S$327.00
Credit 1000 Bank                  S$327.00
```

Important:

```txt
Purchases is not debited again.
```

The expense was already recorded when the bill was created.

---

# 13. Review Payments

Open:

```txt
/payments
```

You should see:

```txt
Customer payments: 1
Vendor payments: 1
```

Recent customer payment:

```txt
Invoice: INV-2026-0001
Customer: Orchard Retail Group Pte. Ltd.
Amount: S$2,180.00
Reference: ORCHARD-PAY-001
```

Recent vendor payment:

```txt
Bill: BILL-2026-0001
Vendor: CloudStack Hosting SG Pte. Ltd.
Amount: S$327.00
Reference: CLOUDSTACK-PAY-001
```

---

# 14. Review Journal Diagnostics

Open:

```txt
/settings/database/journal
```

You should see journal entries for:

```txt
Invoice created
Customer payment recorded
Bill created
Vendor payment recorded
```

Expected entries:

```txt
Invoice INV-2026-0001 issued to Orchard Retail Group Pte. Ltd.
Payment received for invoice INV-2026-0001 from Orchard Retail Group Pte. Ltd.
Bill BILL-2026-0001 received from CloudStack Hosting SG Pte. Ltd.
Payment made for bill BILL-2026-0001 to CloudStack Hosting SG Pte. Ltd.
```

Each should show:

```txt
Balanced
```

---

# 15. Review Profit & Loss

Open:

```txt
/reports/profit-and-loss
```

Use date range:

```txt
From: 2026-01-01
To: 2026-12-31
```

Expected result from our example:

Income:

```txt
4000 Sales Revenue       S$2,000.00
```

Expenses:

```txt
5100 Purchases           S$300.00
```

Net profit:

```txt
S$1,700.00
```

Important:

GST does not appear in Profit & Loss because GST Input and Output Tax are Balance Sheet accounts.

---

# 16. Review Balance Sheet

Open:

```txt
/reports/balance-sheet
```

Use as-of date:

```txt
2026-12-31
```

After invoice, payment, bill, and vendor payment, you may see balances such as:

Assets:

```txt
1000 Bank
1400 GST Input Tax
```

Liabilities:

```txt
2110 GST Output Tax
```

Equity:

```txt
Current Year Earnings
```

The report should show whether:

```txt
Assets = Liabilities + Equity
```

If all journal entries were posted correctly, the equation should balance.

---

# 17. Review GST F5-Style Report

Open:

```txt
/reports/gst-f5
```

Use date range:

```txt
From: 2026-01-01
To: 2026-12-31
```

From our example:

GST Output Tax:

```txt
S$180.00
```

GST Input Tax:

```txt
S$27.00
```

Net GST payable:

```txt
S$153.00
```

Formula:

```txt
GST Output Tax - GST Input Tax = Net GST Payable
S$180.00 - S$27.00 = S$153.00
```

Reminder:

This is an educational GST summary, not official filing software.

---

# 18. Review AR Aging

Open:

```txt
/reports/ar-aging
```

Because the invoice was paid, it should not appear.

To test AR Aging, create another invoice and do not record payment.

Example unpaid invoice:

```txt
Customer: Orchard Retail Group Pte. Ltd.
Issue date: 2026-01-01
Due date: 2026-01-15
Description: Additional consulting services
Unit amount: 500.00
GST basis points: 900
```

If unpaid and overdue, it appears in AR Aging.

---

# 19. Review AP Aging

Open:

```txt
/reports/ap-aging
```

Because the CloudStack bill was paid, it should not appear.

To test AP Aging, create another bill and do not record payment.

Example unpaid bill:

```txt
Vendor: CloudStack Hosting SG Pte. Ltd.
Issue date: 2026-01-01
Due date: 2026-01-15
Description: Additional hosting usage
Unit amount: 150.00
GST basis points: 900
```

If unpaid and overdue, it appears in AP Aging.

---

# 20. Upload Bank CSV

Now Merlion Creative imports a bank statement.

Create a file:

```txt
merlion-bank-february.csv
```

Content:

```csv
date,description,amount
2026-02-15,Orchard Retail Group payment,2180.00
2026-02-20,CloudStack Hosting SG payment,-327.00
2026-02-25,Bank service charge,-15.00
```

Open:

```txt
/bank
```

Upload the CSV.

The app imports 3 bank transactions.

---

# 21. Categorize Bank Transactions

After upload, each row appears with a category form.

Categorize the rows:

## Orchard Retail Group payment

This represents customer cash received.

If you already recorded the customer payment manually, you may choose not to post this again to avoid duplicating bank activity.

For tutorial categorization, choose:

```txt
1100 Accounts Receivable
```

Add note:

```txt
Imported bank row for customer invoice payment.
```

Click:

```txt
Save category
```

---

## CloudStack Hosting SG payment

This represents vendor cash paid.

If you already recorded vendor payment manually, avoid posting again.

For tutorial categorization, choose:

```txt
2000 Accounts Payable
```

Add note:

```txt
Imported bank row for vendor bill payment.
```

Click:

```txt
Save category
```

---

## Bank service charge

This is a new expense.

Choose:

```txt
6700 Bank Charges
```

Add note:

```txt
Monthly bank service fee.
```

Click:

```txt
Save category
```

---

# 22. Post Bank Transaction to Ledger

For this walkthrough, post only the bank service charge to avoid duplicating already-recorded customer/vendor payments.

Find:

```txt
Bank service charge -15.00
```

Status should be:

```txt
categorized
```

Click:

```txt
Post to ledger
```

---

## Bank Charge Journal Entry

Because amount is negative:

```txt
Debit  6700 Bank Charges     S$15.00
Credit 1000 Bank             S$15.00
```

The bank transaction status becomes:

```txt
posted
```

---

# 23. Reconcile Bank Transaction

After posting the bank service charge, click:

```txt
Mark reconciled
```

The transaction status becomes:

```txt
reconciled
```

Open:

```txt
/bank/reconciliation
```

You should see counts for:

```txt
Imported
Categorized
Posted
Reconciled
```

---

# 24. Review Updated Profit & Loss

Open:

```txt
/reports/profit-and-loss
```

Now expenses should include:

```txt
5100 Purchases       S$300.00
6700 Bank Charges    S$15.00
```

Income remains:

```txt
4000 Sales Revenue   S$2,000.00
```

Net profit becomes:

```txt
S$2,000.00 - S$315.00 = S$1,685.00
```

---

# 25. Create a Recurring Invoice Profile

Merlion Creative signs a monthly retainer with Orchard Retail Group.

Open:

```txt
/invoices/recurring
```

Create profile:

```txt
Customer: Orchard Retail Group Pte. Ltd.
Frequency: Monthly
Next run date: today
Description: Monthly creative retainer
Quantity: 1
Unit amount: 1200.00
GST basis points: 900
```

Click:

```txt
Create recurring profile
```

Then click:

```txt
Generate due invoices
```

If the profile is due, GreyMatter Ledger creates a new invoice.

The generated invoice appears in:

```txt
/invoices
```

---

# 26. Use Background Jobs

Open:

```txt
/settings/background-jobs
```

Click:

```txt
Send test event
```

If running Inngest locally:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

You should see:

```txt
app/health.check
```

When invoices are created, GreyMatter Ledger also sends:

```txt
invoice.created
```

The Inngest function can process this event.

---

# 27. Review Audit Log

Open:

```txt
/settings/audit-log
```

Admin-only.

You should see audit events for actions such as:

```txt
customer.created
vendor.created
invoice.created
bill.created
customer_payment.recorded
vendor_payment.recorded
```

This tells you who performed important actions and when.

---

# 28. Reverse a Journal Entry

Admins can reverse journal entries.

Open:

```txt
/settings/database/journal
```

Choose a test entry or a bank charge entry.

Enter reason:

```txt
Correction test for Merlion Creative walkthrough
```

Click:

```txt
Reverse entry
```

GreyMatter Ledger creates a reversal entry by swapping debits and credits.

Example original bank charge:

```txt
Debit  Bank Charges   S$15.00
Credit Bank           S$15.00
```

Reversal:

```txt
Debit  Bank           S$15.00
Credit Bank Charges   S$15.00
```

The original is marked:

```txt
Reversed
```

Reports automatically reflect the reversal because reports read journal lines.

---

# 29. Multi-Currency Reference

Open:

```txt
/reports/multi-currency
```

This page explains how a foreign currency transaction can be represented.

Example:

```txt
USD 100.00
Exchange rate: 1.35
Base amount: SGD 135.00
```

GreyMatter Ledger’s base currency remains:

```txt
SGD
```

---

# 30. CPF Payroll Estimate

Merlion Creative wants a rough educational CPF estimate for an employee earning:

```txt
S$5,000.00/month
```

Open:

```txt
/reports/cpf-estimate
```

Enter:

```txt
5000.00
```

The page estimates:

```txt
Employee CPF
Employer CPF
Total CPF
```

Reminder:

This is simplified and not payroll advice.

---

# 31. Corporate Tax Estimate

Open:

```txt
/reports/corporate-tax
```

Use date range:

```txt
2026-01-01 to 2026-12-31
```

The page uses Profit & Loss net profit as a simplified taxable profit estimate.

Example:

```txt
Accounting profit: S$1,685.00
Tax rate: 17%
Estimated tax: S$286.45
```

Reminder:

This is simplified and not tax advice.

---

# 32. Review Admin Settings

Open:

```txt
/settings/admin
```

You should see your current Clerk organization role.

If you are an admin:

```txt
You are an organization admin.
```

Admin users can:

```txt
View audit logs
Reverse journal entries
```

---

# 33. Review Database Diagnostics

Open:

```txt
/settings/database
```

This shows counts for key records.

You may see counts for:

```txt
Organizations
Accounts
Customers
Vendors
Invoices
Bills
Payments
Journal entries
Journal lines
Bank imports
Bank transactions
```

Additional diagnostic pages include:

```txt
/settings/database/accounts
/settings/database/journal
/settings/database/invoices
/settings/database/organizations
```

These are useful for checking data health.

---

# 34. End-to-End Accounting Story

After completing this walkthrough, Merlion Creative has:

```txt
A company workspace
Seeded chart of accounts
A customer
A vendor
A GST invoice
A customer payment
A GST vendor bill
A vendor payment
Imported bank transactions
A posted bank charge
A reconciled bank transaction
Reports
Audit logs
Recurring invoice profile
Advanced Singapore estimate modules
```

The ledger contains accounting entries for:

```txt
Invoice
Customer payment
Bill
Vendor payment
Bank charge
Reversal if tested
```

---

# 35. Expected Main Accounting Entries

## Invoice

```txt
Debit  Accounts Receivable   S$2,180.00
Credit Sales Revenue         S$2,000.00
Credit GST Output Tax        S$180.00
```

## Customer Payment

```txt
Debit  Bank                  S$2,180.00
Credit Accounts Receivable   S$2,180.00
```

## Bill

```txt
Debit  Purchases             S$300.00
Debit  GST Input Tax         S$27.00
Credit Accounts Payable      S$327.00
```

## Vendor Payment

```txt
Debit  Accounts Payable      S$327.00
Credit Bank                  S$327.00
```

## Bank Charge

```txt
Debit  Bank Charges          S$15.00
Credit Bank                  S$15.00
```

---

# 36. Expected Report Impact

## Profit & Loss

Income:

```txt
Sales Revenue S$2,000.00
```

Expenses:

```txt
Purchases S$300.00
Bank Charges S$15.00
```

Net profit:

```txt
S$1,685.00
```

If you reversed the bank charge, expenses decrease by S$15.00 and net profit increases accordingly.

---

## GST Report

GST Output Tax:

```txt
S$180.00
```

GST Input Tax:

```txt
S$27.00
```

Net GST payable:

```txt
S$153.00
```

---

## AR Aging

Paid invoices are excluded.

Unpaid invoices appear by due date bucket.

---

## AP Aging

Paid bills are excluded.

Unpaid bills appear by due date bucket.

---

# 37. Recommended Monthly Workflow for Merlion Creative

At the end of each month:

1. Create all customer invoices.
2. Enter all vendor bills.
3. Record known payments.
4. Import bank CSV.
5. Categorize bank transactions.
6. Post unmatched transactions carefully.
7. Reconcile bank transactions.
8. Review AR Aging.
9. Review AP Aging.
10. Review Profit & Loss.
11. Review Balance Sheet.
12. Review GST F5-style report.
13. Review audit log.
14. Investigate unusual balances.
15. Consult accountant before filing or closing.

---

# 38. Common Walkthrough Mistakes

## Mistake: Posting Bank Transactions That Duplicate Payments

If you already recorded a customer payment manually, and then import the same bank receipt, posting the bank row again may duplicate the bank effect.

In a more advanced system, bank rows would be matched to existing payments.

For this tutorial version, be careful.

Recommended:

```txt
Use bank posting for transactions not already recorded elsewhere.
```

---

## Mistake: Reports Show Unexpected Values

Check:

```txt
Date range
Active organization
Whether entries were reversed
Whether bank rows were posted twice
Whether invoices/bills were paid
```

---

## Mistake: Cannot Create Invoice or Bill

Check required accounts:

Invoices need:

```txt
1100 Accounts Receivable
4000 Sales Revenue
2110 GST Output Tax
```

Bills need:

```txt
2000 Accounts Payable
1400 GST Input Tax
5100 Purchases
```

Payments need:

```txt
1000 Bank
1100 Accounts Receivable
2000 Accounts Payable
```

---

# 39. Final Walkthrough Summary

This walkthrough demonstrates how GreyMatter Ledger supports a complete small-business accounting cycle:

```txt
Setup company
Maintain accounts
Create customer
Create vendor
Issue invoice
Record customer payment
Enter bill
Record vendor payment
Import bank CSV
Categorize bank rows
Post bank entries
Reconcile bank activity
Review reports
Review audit logs
Use background jobs
Use recurring invoices
Use Singapore estimate modules
```

The most important thing to remember:

```txt
Business documents explain what happened.
Journal entries record the accounting truth.
Reports summarize the journal.
```

GreyMatter Ledger is designed so each major financial action is backed by a balanced journal entry.
