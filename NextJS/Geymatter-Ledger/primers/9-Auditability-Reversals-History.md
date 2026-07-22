# Primer 9 — Auditability, Reversals, and Financial History

**Product:** GreyMatter Ledger  
**Document type:** Primer  
**Audience:** Developers, accountants, auditors, product managers, technical reviewers  
**Goal:** Explain why accounting systems preserve history, how reversals work, and how audit logs complement the ledger  

---

# 1. Why Auditability Matters

Accounting software is not only about calculating totals.

It must also answer:

```txt
What happened?
When did it happen?
Who did it?
Why did it happen?
What changed as a result?
```

In ordinary software, users often edit or delete records.

In accounting software, that can be dangerous.

If a posted journal entry disappears, financial history becomes unreliable.

GreyMatter Ledger uses two major tools for auditability:

```txt
Journal reversals
Audit logs
```

They serve different purposes.

---

# 2. Financial History Should Be Preserved

Accounting records are historical records.

Once a journal entry is posted, it should not be casually edited or deleted.

Why?

Because reports, tax summaries, bank reconciliation, and business decisions may already depend on it.

A safer correction pattern is:

```txt
Post a reversing entry.
```

This preserves the original record and adds a correction.

---

# 3. Legal Notebook Analogy

Think of the ledger like a legal notebook written in ink.

If you make a mistake, you do not rip out the page.

You write a correction.

Original note:

```txt
Paid rent S$500
```

Correction:

```txt
Reverse prior rent entry because it was entered by mistake.
```

Both remain visible.

This creates trust.

---

# 4. Auditability vs Editing

## Editing

Editing changes the past.

Example:

```txt
Change a posted S$500 expense to S$50.
```

Problem:

```txt
The original state disappears.
```

---

## Reversal

Reversal preserves the past and adds a correction.

Original:

```txt
Debit  Rent Expense   S$500
Credit Bank           S$500
```

Reversal:

```txt
Debit  Bank           S$500
Credit Rent Expense   S$500
```

Net effect:

```txt
Zero
```

But history remains visible.

---

# 5. What Is a Reversal?

A reversal is a journal entry that cancels another journal entry.

It swaps every debit and credit.

Original:

```txt
Debit  Expense   S$100
Credit Bank      S$100
```

Reversal:

```txt
Debit  Bank      S$100
Credit Expense   S$100
```

Together:

```txt
Expense net effect = 0
Bank net effect = 0
```

---

# 6. Why Reversals Balance

If the original entry balanced, the reversal also balances.

Original:

```txt
Debits = Credits
```

Reversal:

```txt
Original credits become debits.
Original debits become credits.
```

So the totals still match.

This is why reversal logic is safe and systematic.

---

# 7. Reversal Metadata

GreyMatter Ledger stores reversal metadata on:

```txt
journal_entries
```

Important fields:

```txt
is_reversed
reversed_at
reversal_reason
reversed_by_journal_entry_id
reverses_journal_entry_id
```

---

## `is_reversed`

Indicates that this original entry has been reversed.

Example:

```txt
true
```

---

## `reversed_at`

Timestamp of reversal.

---

## `reversal_reason`

Human explanation.

Example:

```txt
Entered against wrong vendor.
Duplicate transaction.
Testing correction workflow.
```

---

## `reversed_by_journal_entry_id`

Points from original entry to the reversal entry.

---

## `reverses_journal_entry_id`

Points from reversal entry back to the original entry.

---

# 8. Reversal Flow in GreyMatter Ledger

The reversal service is:

```txt
services/journal/reverse-journal-entry.ts
```

Flow:

```txt
User submits reversal reason
  |
  v
Server checks admin permission
  |
  v
Server verifies active organization
  |
  v
Server loads original entry
  |
  v
Server rejects if already reversed
  |
  v
Server loads original lines
  |
  v
Server swaps debit and credit amounts
  |
  v
Server creates reversal entry
  |
  v
Server marks original as reversed
  |
  v
Server writes audit log
```

---

# 9. Why Reversal Requires Admin

Reversing a journal entry affects financial reports.

It can change:

```txt
Profit & Loss
Balance Sheet
GST report
Ledger overview
```

Therefore, GreyMatter Ledger restricts reversal to organization admins.

The service calls:

```ts
await requireOrganizationAdmin();
```

This is server-side enforcement.

---

# 10. Reversal Example: Wrong Expense

Scenario:

```txt
A S$500 rent expense was entered by mistake.
```

Original entry:

```txt
Debit  Rent Expense   S$500
Credit Bank           S$500
```

Reversal:

```txt
Debit  Bank           S$500
Credit Rent Expense   S$500
```

Reports after reversal:

```txt
Rent Expense net effect = S$0
Bank net effect = S$0
```

---

# 11. Reversal Example: Duplicate Invoice Posting

Scenario:

```txt
An invoice was posted twice.
```

Original duplicate entry:

```txt
Debit  Accounts Receivable   S$109
Credit Sales Revenue         S$100
Credit GST Output Tax        S$9
```

Reversal:

```txt
Debit  Sales Revenue         S$100
Debit  GST Output Tax        S$9
Credit Accounts Receivable   S$109
```

This cancels the duplicate accounting effect.

---

# 12. Why Not Delete the Duplicate?

Deleting the duplicate removes evidence that it happened.

A reversal shows:

```txt
A duplicate was posted.
It was corrected.
Here is who corrected it.
Here is why.
Here is when.
```

That is better for auditability.

---

# 13. Reversals and Reports

Reports do not need special reversal logic.

Why?

Because reports sum journal lines.

Original and reversal cancel naturally.

Example:

```txt
Original expense debit: S$500
Reversal expense credit: S$500
Net expense: S$0
```

This applies to:

```txt
Profit & Loss
Balance Sheet
GST report
Ledger overview
```

---

# 14. Reversal Restrictions in the Tutorial

GreyMatter Ledger’s tutorial flow includes these restrictions:

```txt
Already reversed entries cannot be reversed again.
Reversal entries cannot be reversed in this simplified flow.
Only admins can reverse entries.
A reversal reason is required.
```

A more advanced production system may support:

```txt
Reversing reversals
Correction entries
Approval workflows
Period locks
```

But the tutorial keeps the model clear.

---

# 15. Audit Logs

Audit logs record operational activity.

They answer:

```txt
Who did what?
When?
To which record?
With what metadata?
```

Audit log table:

```txt
audit_logs
```

Important fields:

```txt
organization_id
actor_user_id
action
entity_type
entity_id
message
metadata_json
created_at
```

---

# 16. Journal vs Audit Log

The journal records accounting effects.

The audit log records operational actions.

Example invoice creation:

Journal:

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

Audit log:

```txt
User created invoice INV-2026-0001.
```

Both are useful.

They answer different questions.

---

# 17. Audit Log Examples

Examples of audit actions:

```txt
customer.created
vendor.created
invoice.created
bill.created
customer_payment.recorded
vendor_payment.recorded
journal_entry.reversed
```

Example audit message:

```txt
Invoice created and posted: INV-2026-0001
```

Metadata might include:

```json
{
  "invoiceNumber": "INV-2026-0001",
  "totalCents": 10900,
  "journalEntryId": "..."
}
```

---

# 18. Audit Logs Are Tenant-Scoped

Audit logs belong to an organization.

They include:

```txt
organization_id
```

When listing audit logs, filter by active organization.

```ts
await db
  .select()
  .from(auditLogs)
  .where(eq(auditLogs.organizationId, organization.id));
```

Company A must not see Company B’s audit logs.

---

# 19. Audit Logs Are Admin-Only

Audit logs can reveal sensitive information.

Examples:

```txt
Who created invoices
Who recorded payments
Who reversed entries
Which records changed
```

GreyMatter Ledger restricts audit log access to admins.

The audit log page calls:

```ts
await requireOrganizationAdmin();
```

---

# 20. What Should Be Audited?

Audit important actions such as:

```txt
Creating customers
Creating vendors
Creating invoices
Creating bills
Recording payments
Posting bank transactions
Reconciling bank transactions
Reversing journal entries
Changing account status
Changing organization settings
```

Not every page view needs an audit log.

Focus on actions that change important business or financial state.

---

# 21. What Should Not Be Stored in Audit Logs?

Avoid storing:

```txt
Passwords
API keys
Full bank account numbers
Sensitive personal data
Large raw files
Unnecessary secrets
```

Audit logs are useful, but they should not become a security risk.

---

# 22. Audit Logs and User IDs

Audit logs store:

```txt
actor_user_id
```

This comes from Clerk.

Example:

```txt
user_abc123
```

For background jobs, a production system may use:

```txt
system actor
```

or:

```txt
actor_user_id = null
```

with metadata indicating automated activity.

---

# 23. Auditability in Bank Workflows

Bank workflows should be auditable because they affect cash.

Important actions:

```txt
CSV imported
Transaction categorized
Transaction posted
Transaction reconciled
```

The tutorial includes audit logs for many major operations, but bank audit coverage can be expanded in future versions.

---

# 24. Auditability in Payment Workflows

Payments are important financial events.

Customer payment audit log:

```txt
customer_payment.recorded
```

Vendor payment audit log:

```txt
vendor_payment.recorded
```

These help answer:

```txt
Who recorded the payment?
When?
For which invoice or bill?
What amount?
```

---

# 25. Auditability in Admin Workflows

Admin actions should be especially auditable.

Examples:

```txt
Journal reversal
Role changes
Organization settings changes
Account deactivation
```

GreyMatter Ledger audits journal reversals.

Future versions should audit role and settings changes if implemented.

---

# 26. Period Locks as Future Audit Feature

Many accounting systems lock closed periods.

A locked period prevents casual changes to historical records.

Future enhancement:

```txt
accounting_periods
period_status
locked_at
locked_by_user_id
```

Example rule:

```txt
Do not post or reverse entries in locked periods without special permission.
```

---

# 27. Append-Only Ledger as Future Feature

A stronger production system might enforce append-only journal records at the database level.

That means:

```txt
No update/delete on posted journal rows except controlled metadata.
Corrections require new entries.
```

This may involve:

```txt
Database triggers
Row-level permissions
Application-level restrictions
Audit tables
```

---

# 28. Reversal Testing Checklist

When testing reversals:

```txt
Original entry exists.
Original entry belongs to active organization.
User is admin.
Reason is required.
Reversal entry is created.
Reversal lines swap debits and credits.
Original is marked reversed.
Audit log is written.
Reports reflect net zero effect.
Already reversed entry cannot be reversed again.
```

---

# 29. Audit Log Testing Checklist

When testing audit logs:

```txt
Create customer -> audit log appears.
Create vendor -> audit log appears.
Create invoice -> audit log appears.
Create bill -> audit log appears.
Record customer payment -> audit log appears.
Record vendor payment -> audit log appears.
Reverse journal entry -> audit log appears.
Non-admin cannot view audit log.
Audit logs only show active organization data.
```

---

# 30. SQL Verification for Reversals

Inspect reversal metadata:

```sql
select
  id,
  memo,
  is_reversed,
  reversed_at,
  reversal_reason,
  reversed_by_journal_entry_id,
  reverses_journal_entry_id
from journal_entries
order by created_at desc;
```

Check all entries still balance:

```sql
select
  je.id,
  je.memo,
  sum(jl.debit_cents) as debits,
  sum(jl.credit_cents) as credits,
  sum(jl.debit_cents) - sum(jl.credit_cents) as difference
from journal_entries je
join journal_lines jl
  on jl.journal_entry_id = je.id
group by je.id, je.memo
having sum(jl.debit_cents) <> sum(jl.credit_cents);
```

Expected:

```txt
0 rows
```

---

# 31. SQL Verification for Audit Logs

View recent audit logs:

```sql
select
  action,
  entity_type,
  entity_id,
  message,
  actor_user_id,
  metadata_json,
  created_at
from audit_logs
order by created_at desc
limit 50;
```

Check audit logs by organization:

```sql
select
  organization_id,
  count(*) as audit_count
from audit_logs
group by organization_id
order by audit_count desc;
```

---

# 32. Common Mistakes

## Mistake 1 — Editing Posted Entries

Avoid changing posted journal entries directly.

Use reversals.

---

## Mistake 2 — Deleting Bad Entries

Deleting destroys history.

Use reversal entries.

---

## Mistake 3 — No Reversal Reason

A reversal without a reason is hard to audit.

Always require a reason.

---

## Mistake 4 — Audit Log Contains Secrets

Never store API keys, passwords, or sensitive secrets in audit logs.

---

## Mistake 5 — Audit Logs Visible to Everyone

Audit logs should be restricted.

In GreyMatter Ledger, they are admin-only.

---

# 33. Developer Checklist for Auditable Features

When adding a new sensitive feature, ask:

```txt
Does it affect money?
Does it affect reports?
Does it affect permissions?
Does it change bank status?
Does it change invoice/bill/payment state?
Should it write an audit log?
Can it be reversed?
Should it be blocked in locked periods?
Should it require admin permission?
```

---

# 34. Final Mental Model

Auditability in GreyMatter Ledger has two layers:

```txt
Ledger auditability:
  journal entries
  journal lines
  reversals

Operational auditability:
  audit_logs
```

The ledger answers:

```txt
What was the accounting effect?
```

The audit log answers:

```txt
Who performed the action and when?
```

Together, they make the system trustworthy.

The final rule:

```txt
Do not erase accounting history. Correct it visibly.
```
