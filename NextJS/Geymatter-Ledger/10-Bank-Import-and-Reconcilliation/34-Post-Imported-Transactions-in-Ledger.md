# Part 34 — Post Imported Transactions to the Ledger

In Part 33, we categorized imported bank transactions.

Now we will post categorized bank transactions to the ledger.

By the end of this part, you will have:

- Bank transaction posting service
- Server action for posting bank transactions
- UI button to post categorized transactions
- Journal entries created from bank transactions
- Bank transactions marked as `posted`
- Linked `journalEntryId`
- Neon SQL verification

Accounting logic:

For a positive bank transaction:

```txt
Debit  Bank
Credit Category Account
```

For a negative bank transaction:

```txt
Debit  Category Account
Credit Bank
```

Example income:

```txt
Bank import row: +S$109 Customer receipt
Debit  Bank              S$109
Credit Category Account  S$109
```

Example expense:

```txt
Bank import row: -S$25.50 Bank charge
Debit  Category Account  S$25.50
Credit Bank              S$25.50
```

---

# 1. Understand Posting Imported Bank Transactions

## The Target

We are converting categorized bank transactions into journal entries.

---

## The Concept

A bank transaction shows money entering or leaving the bank.

But the ledger needs a double-entry explanation.

Positive bank amount:

```txt
Bank increases
Some other account is credited
```

Negative bank amount:

```txt
Some other account is debited
Bank decreases
```

The category account provides the “other side.”

---

# 2. Create Bank Posting Service

## The Target

We are creating:

```txt
services/bank/post-bank-transaction.ts
```

---

## The Concept

The service will:

1. Require active organization.
2. Load bank transaction.
3. Verify status is `categorized`.
4. Verify category account exists.
5. Verify bank account `1000` exists.
6. Build journal entry lines based on sign.
7. Insert journal entry and lines.
8. Mark bank transaction as `posted`.

---

## The Implementation

Create:

```txt
services/bank/post-bank-transaction.ts
```

Add:

```ts
// services/bank/post-bank-transaction.ts

import { auth } from "@clerk/nextjs/server";
import { and, eq } from "drizzle-orm";
import { db } from "@/db";
import {
  accounts,
  bankTransactions,
  journalEntries,
  journalLines,
} from "@/db/schema";
import { validatePostJournalEntryInput } from "@/services/journal/validate-post-journal-entry";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type PostBankTransactionResult =
  | {
      ok: true;
    }
  | {
      ok: false;
      error: string;
    };

export async function postBankTransactionForCurrentOrganization(
  bankTransactionId: string,
): Promise<PostBankTransactionResult> {
  const organization = await requireCurrentDatabaseOrganization();
  const { userId } = await auth();

  if (!bankTransactionId.trim()) {
    return {
      ok: false,
      error: "Bank transaction ID is required.",
    };
  }

  try {
    await db.transaction(async (tx) => {
      const [transaction] = await tx
        .select()
        .from(bankTransactions)
        .where(
          and(
            eq(bankTransactions.id, bankTransactionId.trim()),
            eq(bankTransactions.organizationId, organization.id),
          ),
        )
        .limit(1);

      if (!transaction) {
        throw new Error("Bank transaction not found for active organization.");
      }

      if (transaction.status !== "categorized") {
        throw new Error("Only categorized transactions can be posted.");
      }

      if (!transaction.categoryAccountId) {
        throw new Error("Transaction must have a category account before posting.");
      }

      const accountRows = await tx
        .select()
        .from(accounts)
        .where(eq(accounts.organizationId, organization.id));

      const accountById = new Map(
        accountRows.map((account) => [account.id, account]),
      );

      const accountByCode = new Map(
        accountRows.map((account) => [account.code, account]),
      );

      const bank = accountByCode.get("1000");

      if (!bank) {
        throw new Error("Required account 1000 Bank is missing.");
      }

      if (!bank.isActive) {
        throw new Error("Required account 1000 Bank is inactive.");
      }

      const categoryAccount = accountById.get(transaction.categoryAccountId);

      if (!categoryAccount) {
        throw new Error("Category account not found.");
      }

      if (!categoryAccount.isActive) {
        throw new Error("Category account is inactive.");
      }

      const absoluteAmountCents = Math.abs(transaction.amountCents);

      const journalLinesInput =
        transaction.amountCents > 0
          ? [
              {
                accountId: bank.id,
                description: `Bank import: ${transaction.description}`,
                debitCents: absoluteAmountCents,
                creditCents: 0,
              },
              {
                accountId: categoryAccount.id,
                description: `Bank import category: ${transaction.description}`,
                debitCents: 0,
                creditCents: absoluteAmountCents,
              },
            ]
          : [
              {
                accountId: categoryAccount.id,
                description: `Bank import category: ${transaction.description}`,
                debitCents: absoluteAmountCents,
                creditCents: 0,
              },
              {
                accountId: bank.id,
                description: `Bank import: ${transaction.description}`,
                debitCents: 0,
                creditCents: absoluteAmountCents,
              },
            ];

      const validation = validatePostJournalEntryInput({
        entryDate: transaction.transactionDate,
        memo: `Bank transaction posted: ${transaction.description}`,
        sourceType: "bank_transaction",
        sourceId: transaction.id,
        lines: journalLinesInput,
      });

      if (validation.issues.length > 0) {
        throw new Error(validation.issues.join(" "));
      }

      const now = new Date();

      const [createdJournalEntry] = await tx
        .insert(journalEntries)
        .values({
          organizationId: organization.id,
          entryDate: transaction.transactionDate,
          memo: `Bank transaction posted: ${transaction.description}`,
          sourceType: "bank_transaction",
          sourceId: transaction.id,
          postedByUserId: userId ?? null,
          createdAt: now,
          updatedAt: now,
        })
        .returning();

      if (!createdJournalEntry) {
        throw new Error("Journal entry could not be created.");
      }

      await tx.insert(journalLines).values(
        validation.normalizedInput.lines.map((line, index) => ({
          journalEntryId: createdJournalEntry.id,
          organizationId: organization.id,
          accountId: line.accountId,
          lineNumber: index + 1,
          description: line.description,
          debitCents: line.debitCents,
          creditCents: line.creditCents,
          createdAt: now,
        })),
      );

      await tx
        .update(bankTransactions)
        .set({
          status: "posted",
          journalEntryId: createdJournalEntry.id,
        })
        .where(eq(bankTransactions.id, transaction.id));
    });

    return {
      ok: true,
    };
  } catch (error) {
    return {
      ok: false,
      error:
        error instanceof Error
          ? error.message
          : "Unexpected error while posting bank transaction.",
    };
  }
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 3. Add Posting Server Action

## The Target

We are updating:

```txt
app/bank/actions.ts
```

---

## The Implementation

Open:

```txt
app/bank/actions.ts
```

Import:

```ts
import { postBankTransactionForCurrentOrganization } from "@/services/bank/post-bank-transaction";
```

Add:

```ts
export async function postBankTransactionAction(formData: FormData) {
  const result = await postBankTransactionForCurrentOrganization(
    String(formData.get("bankTransactionId") ?? ""),
  );

  revalidatePath("/bank");
  revalidatePath("/settings/database/journal");
  revalidatePath("/reports/ledger-overview");

  if (!result.ok) {
    redirect(`/bank?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect("/bank?status=posted");
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 4. Update Bank Status Banner

## The Target

We are updating:

```txt
components/bank-import-status-banner.tsx
```

---

## The Implementation

Add this branch:

```tsx
if (status === "posted") {
  return (
    <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
      <p className="text-sm font-semibold">
        Bank transaction posted successfully.
      </p>

      <p className="mt-2 text-sm leading-6">
        A balanced journal entry was created and the bank transaction is now
        marked as posted.
      </p>
    </section>
  );
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Update Categorization Table with Post Button

## The Target

We are updating:

```txt
components/bank-transaction-categorization-table.tsx
```

---

## The Implementation

Open:

```txt
components/bank-transaction-categorization-table.tsx
```

Import:

```tsx
import { postBankTransactionAction } from "@/app/bank/actions";
```

Inside the categorization table, after the category form, add this when transaction status is `categorized`:

```tsx
{transaction.status === "categorized" ? (
  <form action={postBankTransactionAction} className="mt-2">
    <input
      type="hidden"
      name="bankTransactionId"
      value={transaction.id}
    />

    <button
      type="submit"
      className="rounded-xl bg-emerald-700 px-3 py-2 text-xs font-semibold text-white transition hover:bg-emerald-800"
    >
      Post to ledger
    </button>
  </form>
) : null}
```

A safe structure is:

```tsx
<form action={categorizeBankTransactionAction} className="grid gap-2">
  ...
</form>

{transaction.status === "categorized" ? (
  <form action={postBankTransactionAction} className="mt-2">
    ...
  </form>
) : null}
```

Do not show the post button for imported transactions with no category.

Do not show it for posted or reconciled transactions.

---

## The Verification

Open:

```txt
/bank
```

A categorized transaction should show:

```txt
Post to ledger
```

---

# 6. Categorize and Post a Bank Transaction

## The Target

We are testing the full bank transaction posting flow.

---

## The Implementation

Open:

```txt
/bank
```

If needed, upload a sample CSV:

```csv
date,description,amount
2026-01-05,Customer payment from Merlion Trading,109.00
2026-01-06,Cloud Hosting SG,-109.00
```

Categorize:

```txt
Positive customer payment -> 4000 Sales Revenue or 1100 Accounts Receivable
Negative Cloud Hosting SG -> 6300 Software and Subscriptions
```

Click:

```txt
Post to ledger
```

---

## The Verification

You should see:

```txt
Bank transaction posted successfully.
```

The transaction status should become:

```txt
posted
```

---

# 7. Verify Journal Entry

## The Target

We are confirming the bank transaction created a balanced journal entry.

---

## The Implementation

Open:

```txt
/settings/database/journal
```

Look for:

```txt
Bank transaction posted: ...
```

For positive amount:

```txt
Debit Bank
Credit Category Account
```

For negative amount:

```txt
Debit Category Account
Credit Bank
```

---

## The Verification

The entry should show:

```txt
Balanced
```

---

# 8. Verify in Neon SQL

## The Target

We are checking bank posting rows directly.

---

## The Implementation

Run:

```sql
select
  transaction_date,
  description,
  amount_cents,
  status,
  journal_entry_id
from bank_transactions
order by created_at desc;
```

Run:

```sql
select
  je.memo,
  a.code,
  a.name,
  jl.debit_cents,
  jl.credit_cents
from journal_entries je
join journal_lines jl
  on jl.journal_entry_id = je.id
join accounts a
  on a.id = jl.account_id
where je.source_type = 'bank_transaction'
order by je.created_at desc, jl.line_number;
```

---

## The Verification

Posted bank transactions should have:

```txt
status = posted
journal_entry_id not null
```

---

# 9. Run Full Project Check

## The Target

We are verifying everything still passes.

---

## The Implementation

Run:

```bash
pnpm check
```

---

## The Verification

The command should pass.

---

# 10. Commit Bank Transaction Posting

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Post imported bank transactions to ledger"
```

---

## The Verification

Run:

```bash
git status
```

You should see:

```txt
nothing to commit, working tree clean
```

---

# Common Errors and Fixes

## Error: Only categorized transactions can be posted

Choose an account and save category first.

---

## Error: Required account 1000 Bank is missing

Open:

```txt
/accounts
```

Seed default accounts.

---

## Error: Category account is inactive

Open:

```txt
/accounts
```

Reactivate the account.

---

## Error: Bank transaction already posted

Posted transactions are locked from reposting.

This avoids duplicate journal entries.

---

# Phase 10 Reference — Bank Posting

## Positive Bank Transaction

```txt
Debit Bank
Credit Category Account
```

---

## Negative Bank Transaction

```txt
Debit Category Account
Credit Bank
```

---

## Posted Status

The transaction has created a journal entry.

---

# Part 34 Completion Checklist

You are ready for Part 35 if:

- [ ] Bank posting service exists
- [ ] Only categorized transactions can be posted
- [ ] Bank account 1000 is required
- [ ] Category account is required
- [ ] Positive amounts debit Bank
- [ ] Negative amounts credit Bank
- [ ] Posted transaction stores `journalEntryId`
- [ ] `/bank` shows post button for categorized rows
- [ ] Journal diagnostics show bank transaction entries
- [ ] Neon SQL confirms posted bank transactions
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
