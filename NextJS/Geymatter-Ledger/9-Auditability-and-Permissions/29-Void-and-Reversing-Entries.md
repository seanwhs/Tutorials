# Part 29 — Voiding and Reversing Entries

In accounting software, posted journal entries should not be casually edited or deleted.

Once something is posted to the ledger, the safer correction pattern is:

```txt
Create a reversing entry.
```

In this part, we will add reversal support.

By the end of this part, you will have:

- Reversal fields on `journal_entries`
- A `reverseJournalEntry()` service
- Tenant-safe reversal validation
- Reversal diagnostic UI
- A reversal button on journal diagnostics
- Journal reports that naturally include reversals
- Neon SQL verification

---

# 1. Understand Reversals

## The Target

We are adding a way to reverse posted journal entries.

---

## The Concept

Imagine this entry was posted by mistake:

```txt
Debit  Rent Expense   S$500
Credit Bank           S$500
```

Instead of deleting it, we post the opposite:

```txt
Debit  Bank           S$500
Credit Rent Expense   S$500
```

The original entry stays visible.

The reversal entry also stays visible.

Together, their net effect is zero.

This gives an audit trail.

A useful analogy:

> Do not erase ink from a legal notebook. Write a correction entry.

---

# 2. Update Journal Entry Schema

## The Target

We are updating:

```txt
journal_entries
```

with reversal metadata.

---

## The Concept

We need to know:

```txt
Is this entry reversed?
Which entry reversed it?
Is this entry itself a reversal of another entry?
Why was it reversed?
When was it reversed?
```

---

## The Implementation

Open:

```txt
db/schema.ts
```

In the `journalEntries` table, add these columns:

```ts
isReversed: boolean("is_reversed").default(false).notNull(),

reversedAt: timestamp("reversed_at", { withTimezone: true }),

reversalReason: text("reversal_reason"),

reversedByJournalEntryId: uuid("reversed_by_journal_entry_id"),

reversesJournalEntryId: uuid("reverses_journal_entry_id"),
```

Add indexes in the table callback:

```ts
index("journal_entries_organization_id_is_reversed_idx").on(
  table.organizationId,
  table.isReversed,
),
index("journal_entries_reverses_journal_entry_id_idx").on(
  table.reversesJournalEntryId,
),
```

Important note:

We intentionally do **not** add self-referential foreign keys in this tutorial step because self-references in Drizzle can require extra care depending on version and inference. We still store the UUID links and validate them in the service.

---

## The Verification

Generate and apply migration:

```bash
pnpm db:generate
pnpm db:migrate
```

Verify columns:

```sql
select column_name
from information_schema.columns
where table_name = 'journal_entries'
order by ordinal_position;
```

You should see:

```txt
is_reversed
reversed_at
reversal_reason
reversed_by_journal_entry_id
reverses_journal_entry_id
```

---

# 3. Create Reversal Service

## The Target

We are creating:

```txt
services/journal/reverse-journal-entry.ts
```

---

## The Concept

The reversal service will:

1. Require active organization.
2. Load the original journal entry.
3. Reject if already reversed.
4. Load original lines.
5. Create a new entry with debit/credit swapped.
6. Mark the original as reversed.
7. Link original and reversal entries.

---

## The Implementation

Create:

```txt
services/journal/reverse-journal-entry.ts
```

Add:

```ts
// services/journal/reverse-journal-entry.ts

import { auth } from "@clerk/nextjs/server";
import { and, asc, eq } from "drizzle-orm";
import { db } from "@/db";
import {
  journalEntries,
  journalLines,
  type JournalEntry,
} from "@/db/schema";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";
import { validatePostJournalEntryInput } from "@/services/journal/validate-post-journal-entry";

export type ReverseJournalEntryResult =
  | {
      ok: true;
      reversalEntry: JournalEntry;
    }
  | {
      ok: false;
      error: string;
    };

function todayString(): string {
  return new Date().toISOString().slice(0, 10);
}

export async function reverseJournalEntryForCurrentOrganization(params: {
  journalEntryId: string;
  reason: string;
}): Promise<ReverseJournalEntryResult> {
  const organization = await requireCurrentDatabaseOrganization();
  const { userId } = await auth();

  const reason = params.reason.trim();

  if (!params.journalEntryId.trim()) {
    return {
      ok: false,
      error: "Journal entry ID is required.",
    };
  }

  if (!reason) {
    return {
      ok: false,
      error: "Reversal reason is required.",
    };
  }

  try {
    const result = await db.transaction(async (tx) => {
      const [originalEntry] = await tx
        .select()
        .from(journalEntries)
        .where(
          and(
            eq(journalEntries.id, params.journalEntryId.trim()),
            eq(journalEntries.organizationId, organization.id),
          ),
        )
        .limit(1);

      if (!originalEntry) {
        throw new Error("Journal entry not found for active organization.");
      }

      if (originalEntry.isReversed) {
        throw new Error("Journal entry has already been reversed.");
      }

      if (originalEntry.reversesJournalEntryId) {
        throw new Error("A reversal entry cannot be reversed in this tutorial flow.");
      }

      const originalLines = await tx
        .select()
        .from(journalLines)
        .where(eq(journalLines.journalEntryId, originalEntry.id))
        .orderBy(asc(journalLines.lineNumber));

      if (originalLines.length === 0) {
        throw new Error("Original journal entry has no lines.");
      }

      const reversalLines = originalLines.map((line) => ({
        accountId: line.accountId,
        description: `Reversal of line ${line.lineNumber}: ${
          line.description ?? originalEntry.memo
        }`,
        debitCents: line.creditCents,
        creditCents: line.debitCents,
      }));

      const entryDate = todayString();

      const validation = validatePostJournalEntryInput({
        entryDate,
        memo: `Reversal of: ${originalEntry.memo}`,
        sourceType: "manual",
        sourceId: null,
        lines: reversalLines,
      });

      if (validation.issues.length > 0) {
        throw new Error(validation.issues.join(" "));
      }

      const now = new Date();

      const [createdReversalEntry] = await tx
        .insert(journalEntries)
        .values({
          organizationId: organization.id,
          entryDate,
          memo: `Reversal of: ${originalEntry.memo}`,
          sourceType: "manual",
          sourceId: null,
          postedByUserId: userId ?? null,
          isReversed: false,
          reversesJournalEntryId: originalEntry.id,
          createdAt: now,
          updatedAt: now,
        })
        .returning();

      if (!createdReversalEntry) {
        throw new Error("Reversal journal entry could not be created.");
      }

      await tx.insert(journalLines).values(
        validation.normalizedInput.lines.map((line, index) => ({
          journalEntryId: createdReversalEntry.id,
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
        .update(journalEntries)
        .set({
          isReversed: true,
          reversedAt: now,
          reversalReason: reason,
          reversedByJournalEntryId: createdReversalEntry.id,
          updatedAt: now,
        })
        .where(eq(journalEntries.id, originalEntry.id));

      return createdReversalEntry;
    });

    return {
      ok: true,
      reversalEntry: result,
    };
  } catch (error) {
    return {
      ok: false,
      error:
        error instanceof Error
          ? error.message
          : "Unexpected error while reversing journal entry.",
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

# 4. Create Reversal Server Action

## The Target

We are creating:

```txt
app/settings/database/journal/actions.ts
```

---

## The Implementation

Create:

```txt
app/settings/database/journal/actions.ts
```

Add:

```ts
// app/settings/database/journal/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { reverseJournalEntryForCurrentOrganization } from "@/services/journal/reverse-journal-entry";

export async function reverseJournalEntryAction(formData: FormData) {
  const journalEntryId = String(formData.get("journalEntryId") ?? "");
  const reason = String(formData.get("reason") ?? "");

  const result = await reverseJournalEntryForCurrentOrganization({
    journalEntryId,
    reason,
  });

  revalidatePath("/settings/database/journal");
  revalidatePath("/reports/ledger-overview");
  revalidatePath("/reports/profit-and-loss");
  revalidatePath("/reports/balance-sheet");
  revalidatePath("/reports/gst-f5");

  if (!result.ok) {
    redirect(
      `/settings/database/journal?reversalStatus=error&reversalMessage=${encodeURIComponent(
        result.error,
      )}`,
    );
  }

  redirect("/settings/database/journal?reversalStatus=reversed");
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Create Reversal Status Banner

## The Target

We are creating:

```txt
components/reversal-status-banner.tsx
```

---

## The Implementation

Create:

```txt
components/reversal-status-banner.tsx
```

Add:

```tsx
// components/reversal-status-banner.tsx

type ReversalStatusBannerProps = {
  status?: string;
  message?: string;
};

export function ReversalStatusBanner({
  status,
  message,
}: ReversalStatusBannerProps) {
  if (!status) {
    return null;
  }

  if (status === "reversed") {
    return (
      <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
        <p className="text-sm font-semibold">
          Journal entry reversed successfully.
        </p>

        <p className="mt-2 text-sm leading-6">
          A reversing entry was posted and the original entry was marked as
          reversed.
        </p>
      </section>
    );
  }

  if (status === "error") {
    return (
      <section className="rounded-2xl border border-rose-200 bg-rose-50 p-5 text-rose-800">
        <p className="text-sm font-semibold">Reversal failed.</p>
        {message ? <p className="mt-2 text-sm leading-6">{message}</p> : null}
      </section>
    );
  }

  return null;
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 6. Update Journal Entry Query to Include Reversal Fields

## The Target

We are updating:

```txt
services/journal/get-journal-entries.ts
```

---

## The Implementation

Open:

```txt
services/journal/get-journal-entries.ts
```

In the `JournalEntryWithLines` type, add:

```ts
isReversed: boolean;
reversedAt: Date | null;
reversalReason: string | null;
reversedByJournalEntryId: string | null;
reversesJournalEntryId: string | null;
```

In the `entryRows` select, add:

```ts
isReversed: journalEntries.isReversed,
reversedAt: journalEntries.reversedAt,
reversalReason: journalEntries.reversalReason,
reversedByJournalEntryId: journalEntries.reversedByJournalEntryId,
reversesJournalEntryId: journalEntries.reversesJournalEntryId,
```

Because the final returned object spreads `...entry`, these fields will now be included.

---

## The Verification

Run:

```bash
pnpm build
```

---

# 7. Update Journal Diagnostic Page with Reversal UI

## The Target

We are updating:

```txt
app/settings/database/journal/page.tsx
```

---

## The Concept

We will show:

- A reversal status banner
- Reversal badges
- A reversal form for entries that can be reversed

---

## The Implementation

Open:

```txt
app/settings/database/journal/page.tsx
```

Add imports:

```tsx
import { ReversalStatusBanner } from "@/components/reversal-status-banner";
import { reverseJournalEntryAction } from "@/app/settings/database/journal/actions";
```

Update page props:

```ts
type DatabaseJournalPageProps = {
  searchParams?: Promise<{
    reversalStatus?: string;
    reversalMessage?: string;
  }>;
};
```

Update function signature:

```tsx
export default async function DatabaseJournalPage({
  searchParams,
}: DatabaseJournalPageProps) {
```

At the top of the function, add:

```ts
const resolvedSearchParams = searchParams ? await searchParams : {};
```

Inside the top-level page content before the first section, add:

```tsx
<ReversalStatusBanner
  status={resolvedSearchParams.reversalStatus}
  message={resolvedSearchParams.reversalMessage}
/>
```

Now, inside the recent journal entry card header where the Balanced badge appears, add reversal badges and form.

Find the area where you show:

```tsx
{totalDebitCents === totalCreditCents ? (
  <span ...>Balanced</span>
) : (
  <span ...>Unbalanced</span>
)}
```

Replace it with:

```tsx
<div className="flex flex-wrap gap-2">
  {entry.isReversed ? (
    <span className="rounded-full bg-amber-50 px-3 py-1 text-xs font-semibold text-amber-700">
      Reversed
    </span>
  ) : null}

  {entry.reversesJournalEntryId ? (
    <span className="rounded-full bg-purple-50 px-3 py-1 text-xs font-semibold text-purple-700">
      Reversal entry
    </span>
  ) : null}

  {totalDebitCents === totalCreditCents ? (
    <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
      Balanced
    </span>
  ) : (
    <span className="rounded-full bg-rose-50 px-3 py-1 text-xs font-semibold text-rose-700">
      Unbalanced
    </span>
  )}
</div>
```

After the journal line table for each entry, add:

```tsx
{!entry.isReversed && !entry.reversesJournalEntryId ? (
  <div className="border-t border-slate-200 bg-slate-50 px-6 py-4">
    <form
      action={reverseJournalEntryAction}
      className="grid gap-3 md:grid-cols-[1fr_auto]"
    >
      <input type="hidden" name="journalEntryId" value={entry.id} />

      <input
        name="reason"
        required
        placeholder="Reason for reversal"
        className="rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
      />

      <button
        type="submit"
        className="rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-amber-700"
      >
        Reverse entry
      </button>
    </form>
  </div>
) : entry.reversalReason ? (
  <div className="border-t border-amber-200 bg-amber-50 px-6 py-4 text-sm text-amber-800">
    <span className="font-semibold">Reversal reason:</span>{" "}
    {entry.reversalReason}
  </div>
) : null}
```

---

## The Verification

Run:

```bash
pnpm build
```

Then open:

```txt
/settings/database/journal
```

You should see reversal forms on eligible entries.

---

# 8. Test a Reversal

## The Target

We are reversing a posted journal entry.

---

## The Implementation

Open:

```txt
/settings/database/journal
```

Choose a manual test entry or an invoice/bill entry.

In the reversal reason field, enter:

```txt
Testing reversal workflow
```

Click:

```txt
Reverse entry
```

---

## The Verification

You should see:

```txt
Journal entry reversed successfully.
```

The original entry should show:

```txt
Reversed
```

A new entry should appear:

```txt
Reversal of: ...
```

The reversal entry should have debits and credits swapped.

---

# 9. Verify in Neon SQL

## The Target

We are checking reversal data directly.

---

## The Implementation

Run:

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

Run a balance check:

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
order by je.memo;
```

---

## The Verification

Every entry should still have:

```txt
difference = 0
```

The original entry should have:

```txt
is_reversed = true
```

The reversal entry should have:

```txt
reverses_journal_entry_id = original entry id
```

---

# 10. Understand Report Impact

## The Target

We are confirming reversals naturally affect reports.

---

## The Concept

Because reports are ledger-based, a reversal cancels the original entry.

Example:

Original:

```txt
Debit Rent Expense S$500
Credit Bank        S$500
```

Reversal:

```txt
Debit Bank         S$500
Credit Rent Expense S$500
```

Net effect:

```txt
Rent Expense = 0
Bank = 0
```

Reports do not need special reversal logic.

They just sum journal lines.

---

## The Verification

Open:

```txt
/reports/ledger-overview
/reports/profit-and-loss
/reports/balance-sheet
```

The reversal should affect balances automatically.

---

# 11. Run Full Project Check

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

# 12. Commit Reversal Support

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Add journal entry reversals"
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

## Error: Reversal columns do not exist

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Entry already reversed

That is expected.

Each original entry can only be reversed once.

---

## Error: Reversal entry cannot be reversed

In this tutorial flow, we block reversing reversal entries to keep the model simple.

A production app may support correcting reversals with additional controls.

---

## Error: Reports look different after reversal

That is expected.

A reversal cancels the original accounting effect.

---

# Phase 9 Reference — Reversals

## Reversal

A journal entry that cancels another journal entry by swapping debits and credits.

---

## Why Not Delete?

Deleting breaks audit history.

Reversing preserves the original and the correction.

---

## Report Behavior

Reports naturally include both original and reversal entries.

The net effect is zero.

---

# Part 29 Completion Checklist

You are ready for Part 30 if:

- [ ] `journal_entries` has reversal columns
- [ ] Migration applied successfully
- [ ] `reverseJournalEntryForCurrentOrganization()` exists
- [ ] Reversal validates active organization
- [ ] Reversal rejects already reversed entries
- [ ] Reversal creates swapped debit/credit lines
- [ ] Original entry is marked reversed
- [ ] Reversal entry links back to original
- [ ] Journal diagnostic page shows reversal UI
- [ ] Neon SQL confirms reversal metadata
- [ ] Reports reflect reversal impact
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
