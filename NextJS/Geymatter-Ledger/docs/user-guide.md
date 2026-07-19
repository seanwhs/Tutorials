# Greymatter Ledger: User Guide

This guide is for actually *using* Greymatter Ledger as a business owner or bookkeeper — not building it. If you're the person who followed the tutorial series (or deployed someone else's build of it), this is what you hand to the person who's going to run their books on it day-to-day. No code, no jargon left unexplained, organized by what you're trying to *do*, not by how it was built.

---

## Getting Started

### Creating Your Account

1. Visit your Greymatter Ledger URL and click **Sign Up**.
2. Enter your email and create a password (or sign up with Google, if enabled).
3. Check your email for a verification code and enter it.

### Setting Up Your Company

Greymatter Ledger organizes everything by **company** — called an "Organization." If you run more than one business, or you're an accountant managing books for several clients, each one gets its own completely separate, private set of books.

1. On your first login, click **Create Organization**.
2. Give it your company's name.
3. That's it — Greymatter Ledger automatically sets you up with a starter **Chart of Accounts** (see below), so you're ready to start recording transactions immediately.

**Switching between companies:** if you belong to more than one organization, use the switcher at the top of any page to jump between them. Everything you see and do is always scoped to whichever company is currently active — invoices, reports, and settings never mix between companies.

**Inviting your team:** from your organization's settings, you can invite other people to join. New team members join as a **Member** by default — they can do day-to-day work (create invoices, record payments, upload bank statements) but cannot void records, run payroll, or complete a bank reconciliation. Only an **Admin** (you, as the creator, by default) can do those. See "Roles & Permissions" below for the full breakdown.

---

## Your Chart of Accounts

Every business needs a list of "buckets" to sort money into — this is your **Chart of Accounts**, visible under the **Accounts** tab. Greymatter Ledger seeds you with a sensible starter list automatically, including Singapore-specific accounts for GST and CPF:

- **Cash** — money in your bank
- **Accounts Receivable** — money customers owe you
- **GST Input Tax Receivable** — GST you've paid to suppliers, reclaimable from IRAS
- **Accounts Payable** — money you owe suppliers
- **GST Output Tax Payable** — GST you've collected from customers, owed to IRAS
- **CPF Payable** — CPF contributions owed to the CPF Board
- **Sales Revenue** — money you've earned
- Various expense accounts (Rent, Office Supplies, Software, Bank Fees, Salaries, etc.)

You don't need to touch this list to get started — everything else in the app already knows how to use it. If an admin ever needs to retire an account you no longer use, there's a **Deactivate** option next to each one (admin-only) — this hides it going forward without erasing any history attached to it.

---

## Customers and Vendors

Before you can invoice anyone or record a bill, add them:

- **Customers** (people/companies who owe *you* money) — go to the **Customers** tab, fill in name, email, and address, click **Add Customer**.
- **Vendors** (people/companies *you* owe money to) — same process under the **Vendors** tab.

You can deactivate a customer or vendor you no longer work with — this doesn't delete their record or any past invoices/bills, it just removes them from the "create new" dropdown lists going forward.

---

## Invoicing a Customer

1. Go to **Invoices** → **New Invoice**.
2. Pick the customer, set the issue date and due date.
3. Add one or more line items: description, quantity, unit price, and GST rate per line (9% standard, or 0% for zero-rated items — you can mix both on the same invoice).
4. Watch the live total at the bottom update as you type.
5. Click **Create & Send Invoice**.

The invoice is immediately recorded in your books — no separate "posting" step. You'll land on the invoice's detail page, where you can see its full breakdown and current status (Sent, Partially Paid, Paid, Overdue, or Void).

**If your business invoices in a foreign currency** (USD, EUR, etc.), the invoice form lets you set a currency and exchange rate — the invoice displays in that currency, while your internal books always convert everything to SGD behind the scenes, so your reports stay accurate regardless of how many currencies you invoice in.

### Recording a Payment

Open the invoice and use the **Record a Payment** box at the bottom — enter the amount received, the date, and how it was paid (bank transfer, cash, card, cheque). Partial payments are fully supported: the invoice status updates automatically (Partially Paid → Paid) as payments come in, and the form disappears once it's fully settled.

---

## Recording Bills You Owe

1. Go to **Bills** → **New Bill**.
2. Pick the vendor, dates, and add line items — for each line, choose which expense category it belongs to (Rent, Software, etc.) alongside the amount and GST rate.
3. Click **Record Bill**.

Recording a payment against a bill works exactly like invoices — open the bill's detail page and use the payment box there.

---

## Reports

All under the **Reports** tab.

- **Profit & Loss** — how much you earned vs. spent over a date range you choose. Shows revenue by category, expenses by category, and your net income (or loss) at the bottom.
- **Balance Sheet** — a snapshot of everything you own, owe, and your equity, as of any date you pick. A green **✅ Balanced** banner confirms your books are internally consistent — if you ever see a red warning here, something needs investigating (contact whoever manages your Greymatter Ledger deployment).
- **AR/AP Aging** — answers "who owes me money, and how late are they?" and "who am I overdue in paying?" Unpaid invoices/bills are grouped by how many days overdue: Current, 1–30, 31–60, 61–90, and 90+ days.
- **GST F5** — a quarterly summary modeled on IRAS's actual GST return form, showing your standard-rated and zero-rated sales, taxable purchases, and the net GST you owe to (or are owed by) IRAS. Pick a quarter's start date and it fills in automatically.
- **Tax Estimate** — an illustrative estimate of your Corporate Income Tax, starting from your accounting profit and letting an admin add known adjustments (non-deductible expenses, capital allowances).

**Important:** the GST F5 and Tax Estimate reports are internal planning tools, not official filings — always have your actual GST return and tax computation reviewed by a real accountant or filed properly through IRAS's own channels before submission.

---

## Importing Your Bank Statement

Instead of manually entering every bank fee or incoming wire transfer:

1. Log into your online banking and export your recent transactions as a **CSV file** (most banks, including DBS, OCBC, and UOB, offer this — look for a "Download" or "Export" option on your transaction history page).
2. In Greymatter Ledger, go to **Bank Import**, and upload the file. It expects three columns: **Date**, **Description**, and **Amount** (positive for money in, negative for money out) — if your bank's export uses different column names, you may need to rename the header row before uploading.
3. Every transaction lands in a review list with status "Pending."
4. For each one, pick which account it should be categorized against (e.g., a bank fee → "Bank Fees Expense"), then click **Save Category**.
5. Once categorized, click **Post to Ledger** to record it properly in your books.
6. If a transaction shouldn't be recorded at all (an internal transfer between your own accounts, for instance), click **Ignore** instead.

Uploading the same statement twice (or overlapping date ranges) won't create duplicates — the system automatically recognizes rows it's already seen.

---

## Payroll (CPF)

Under the **Payroll** tab (visible to everyone, but only admins can add employees or run a pay cycle):

1. Add an employee: name, monthly wage, and their CPF contribution rates (defaults to 20% employee / 17% employer if you don't know the exact figures — check IRAS/CPF Board's current official rates for your employees' actual age bands, since this is a simplified default, not a real-time lookup).
2. Click **Run Payroll** for that employee, pick the pay date.

This automatically calculates the employee's CPF deduction, your employer's CPF contribution, the employee's actual take-home pay, and records everything correctly in your books — no manual journal entries needed.

---

## Bank Reconciliation

Periodically (monthly is typical), confirm your books match your actual bank statement:

1. Go to **Reconciliation**, enter the date and your bank statement's ending balance for that date.
2. A checklist of every Cash transaction up to that date appears — check off each one that appears on your bank statement.
3. As you check items off, a running total updates. Once it matches your entered statement balance, a green **✅ Matched** badge appears.
4. Click **Complete Reconciliation** to lock in that period.

Once a transaction has been reconciled, it won't appear again in a future reconciliation session — each period only shows what's genuinely new since the last one.

---

## Fixing Mistakes: Voiding

Sometimes an invoice, bill, or payment was entered wrong. Greymatter Ledger never lets you edit or delete something once it's recorded — instead, you **void** it, which creates a clean, fully-reversing correction while keeping the original visible for your records (this is exactly how proper bookkeeping is meant to work — nothing quietly disappears).

- On any unpaid invoice or bill's detail page, click **Void this record**, type a reason, and confirm.
- If a payment needs to be undone, void the *payment* first (from the invoice/bill's Payment History section) — once that's voided, the invoice or bill itself becomes voidable too.

**Only admins can void anything.** If you're a Member and need something corrected, ask an admin on your team.

---

## Roles & Permissions

| Action | Member | Admin |
|---|---|---|
| Create invoices, bills, customers, vendors | ✅ | ✅ |
| Record payments | ✅ | ✅ |
| Upload and categorize bank transactions | ✅ | ✅ |
| View all reports | ✅ | ✅ |
| Void an invoice, bill, or payment | ❌ | ✅ |
| Deactivate a Chart of Accounts entry | ❌ | ✅ |
| Add/run payroll | ❌ | ✅ |
| Add tax adjustments | ❌ | ✅ |
| Complete a bank reconciliation | ❌ | ✅ |

Change a team member's role from your Clerk organization settings.

---

## Frequently Asked Questions

**"I made a typo on an invoice — can I just edit it?"**
No — Greymatter Ledger deliberately never allows editing a posted invoice or bill. This protects your books from silent, untracked changes. If nothing has been paid against it yet, an admin can **void** it and you can create a fresh, correct one. If a payment has already been recorded, void the payment first, then void the invoice.

**"Why can't I void a paid invoice directly?"**
Because voiding reverses the exact accounting effect the invoice created — if a payment has already come in against it, that payment needs to be unwound first (voided), so the numbers stay consistent at every step. Void the payment from the invoice's Payment History section, then the invoice itself becomes voidable.

**"I'm not an admin and I need something voided — what do I do?"**
Ask an admin on your team to do it. This restriction is intentional — voiding rewrites financial history, so it's limited to people your organization has specifically trusted with that level of access.

**"The Balance Sheet shows a red warning instead of the green checkmark — what does that mean?"**
This should never happen in normal use. It means something in your books has become mathematically inconsistent — contact whoever manages your Greymatter Ledger deployment (your developer or IT contact) right away rather than trying to fix it yourself, since the underlying cause needs to be found before any correction is made.

**"Can I invoice in a currency other than SGD?"**
Yes — set the currency and exchange rate when creating the invoice. The invoice displays and totals in that currency; your internal reports always convert everything back to SGD so your Profit & Loss, Balance Sheet, and tax figures stay meaningful across every currency you use.

**"Is the GST F5 report something I can file directly with IRAS?"**
No — treat it as a helpful internal estimate to prepare for filing, not the filing itself. It doesn't account for every real-world GST scenario (reverse charges, special schemes, bad debt relief). File your actual return through IRAS's own channels, ideally with your accountant's review.

**"What happens if I upload the same bank statement twice by accident?"**
Nothing bad — Greymatter Ledger recognizes transactions it's already seen (matched by date, description, and amount) and simply skips them, telling you how many were skipped as duplicates.

**"My bank's CSV export doesn't have columns called exactly 'Date', 'Description', and 'Amount' — what do I do?"**
Open the file in a spreadsheet program first and rename the header row to match those three exact column names before uploading. If your bank splits amounts into separate "Debit" and "Credit" columns instead of one column, you'll need to combine them into a single column first (positive for money in, negative for money out).

**"Can I delete a customer or vendor I no longer work with?"**
Not permanently — click **Deactivate** instead. This removes them from dropdown lists when creating new invoices/bills, but keeps every past invoice, bill, and payment tied to them fully intact and visible in your history.

**"How do I know if my CPF rates are correct?"**
Greymatter Ledger uses simplified default rates (20% employee / 17% employer) unless you set different ones per employee. Real CPF contribution rates depend on your employee's actual age band and are set by the CPF Board, and they do change over time — always check IRAS/CPF Board's current official rates rather than relying on the app's defaults for real payroll runs.

**"Who can see my company's data?"**
Only people you've explicitly added as a member of your organization. Data is never shared or visible across different organizations, even ones the same person belongs to — switching organizations always shows a completely separate set of books.

---

## Getting Help

If something isn't behaving as described in this guide, or you suspect an error in your books, don't attempt to fix it directly in the underlying data — reach out to whoever set up and maintains your Greymatter Ledger deployment. Many issues (an "out of balance" warning, unexpected report figures, a stuck bank import) are much easier to diagnose with the full picture than after a well-intentioned manual correction.

**[END OF USER GUIDE]**

