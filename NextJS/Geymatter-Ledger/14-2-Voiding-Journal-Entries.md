# Part 14.2: Voiding and Reversing Journal Entries

This is the top recommendation from Part 14's roadmap, built out in full. Recall the reasoning: once a journal entry is posted, it's treated as permanent historical fact (Part 4, Part 6). The correct way to "undo" a mistake is never to delete the original entry — it's to post a **second, offsetting entry** that exactly reverses it, while keeping both permanently visible. This preserves a complete, honest audit trail: anyone reviewing the books later can see both that a mistake happened *and* that it was corrected.

## Step 14.2.1 — Extending the Schema

### The Target
Add `isVoided`, `voidedAt`, and a self-referencing `reversalOfEntryId` to `journal_entries`.

### The Concept
Think of this like a physical accounting ledger where you never use White-Out — instead, you cross out an old entry with a single line (still legible underneath) and write a fresh correcting entry below it, with a note pointing back and forth between the two. `isVoided` is the "crossed out" flag on the *original* entry. `reversalOfEntryId` is the note on the *new* entry saying "this exists to cancel out entry X." Both entries remain permanently in the ledger — nothing is ever deleted.

### The Implementation

Replace your existing `journalEntries` table definition in `src/db/schema.ts` with this expanded version (it now needs the third-argument callback syntax, like `accounts` in Part 5, since it has a self-reference):

**`src/db/schema.ts`** (replace the existing `journalEntries` table definition)
```typescript
export const journalEntries = pgTable(
  "journal_entries",
  {
    id: uuid("id").primaryKey().defaultRandom(),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),

    entryDate: date("entry_date").notNull(),
    description: text("description").notNull(),
    sourceType: text("source_type").notNull().default("manual"),
    sourceId: uuid("source_id"),

    // --- New in Part 14.2 ---

    // True once this specific entry has been reversed. A voided entry is
    // NEVER deleted or edited — it remains exactly as originally posted,
    // permanently visible, with this flag simply marking it superseded.
    isVoided: boolean("is_voided").notNull().default(false),

    voidedAt: timestamp("voided_at"),

    // If THIS entry is itself a reversal of another entry, this points
    // back to the original. Self-referencing, like accounts.parentId
    // (Part 5) — added via foreignKey() below rather than inline, since
    // a table can't reference its own not-yet-finished definition inline.
    reversalOfEntryId: uuid("reversal_of_entry_id"),

    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (table) => [
    foreignKey({
      columns: [table.reversalOfEntryId],
      foreignColumns: [table.id],
      name: "journal_entries_reversal_of_fk",
    }),
  ]
);

export const journalEntriesRelations = relations(journalEntries, ({ many }) => ({
  lines: many(journalLines),
}));
```

### The Verification

Save, then migrate:

```bash
npm run db:generate
npm run db:migrate
```

Expected output should mention new columns (`is_voided`, `voided_at`, `reversal_of_entry_id`) added to `journal_entries`, plus a new foreign key. Confirm all three columns and the FK appear in Drizzle Studio.

---

## Step 14.2.2 — The `voidJournalEntry` Function

### The Target
Write the core function: given an entry ID, post its exact reversal and mark the original as voided — atomically, and **composably**, so a caller can fold this into its own larger transaction.

### The Concept
Recall Part 6's engine one more time. We're not writing new balancing logic here — we're *reusing* `postJournalEntry` completely unchanged, just feeding it the original entry's lines with debit and credit swapped. If the original entry balanced (and it must have, since nothing else could have posted it), its exact mirror image balances too, automatically.

The important architectural point, corrected from the first draft of this part: `voidJournalEntry` must accept an **optional executor**, using the exact same pattern `postJournalEntry` already uses (Part 7, Step 7.8). Without this, any caller that needs to combine voiding with its *own* additional writes (like `voidInvoice` needing to also flip an invoice's status) would end up either running two separate, non-atomic transactions, or nesting a transaction inside a transaction incorrectly. The executor pattern solves this exactly once, here, so every future caller gets atomicity for free.

### The Implementation

**`src/lib/journal.ts`** (append this to the existing file — it already has `Executor`, `dbTransactional`, and `postJournalEntry` defined from Parts 6–7)
```typescript
import { journalEntries as journalEntriesTable } from "@/db/schema";
import { eq as eqOp } from "drizzle-orm";

export type VoidJournalEntryResult = {
  originalEntryId: string;
  reversalEntryId: string;
};

/**
 * Reverses a previously posted journal entry by posting a brand-new
 * entry with every debit/credit flipped, and marking the original as
 * voided. The original entry is NEVER deleted or modified in place —
 * both entries remain permanently visible in the ledger, preserving a
 * complete, honest audit trail (Part 14.2's core principle).
 *
 * Accepts an optional `executor`, exactly like postJournalEntry (Part 7,
 * Step 7.8). If omitted, this function opens its OWN transaction — safe
 * for standalone use. If a caller passes its own `tx` (as voidInvoice/
 * voidBill do below), this function participates in THAT transaction
 * instead, so the reversal and whatever else the caller does (like
 * flipping an invoice's status) commit or roll back as ONE atomic unit.
 */
export async function voidJournalEntry(
  organizationId: string,
  entryId: string,
  reason: string,
  executor: Executor = dbTransactional
): Promise<VoidJournalEntryResult> {
  async function doVoid(tx: Executor): Promise<VoidJournalEntryResult> {
    const originalEntry = await tx.query.journalEntries.findFirst({
      where: (je, { and, eq }) =>
        and(eq(je.id, entryId), eq(je.organizationId, organizationId)),
      with: { lines: true },
    });

    if (!originalEntry) {
      throw new Error("Journal entry not found for this organization.");
    }
    if (originalEntry.isVoided) {
      throw new Error(
        "This journal entry has already been voided and cannot be voided again."
      );
    }

    // Build the reversed lines: every debit becomes a credit of the same
    // amount, and every credit becomes a debit — exactly cancelling out
    // the original entry's effect on every account it touched.
    const reversedLines = originalEntry.lines.map((line) => ({
      accountId: line.accountId,
      debit:
        parseFloat(line.creditAmount) > 0
          ? parseFloat(line.creditAmount)
          : undefined,
      credit:
        parseFloat(line.debitAmount) > 0
          ? parseFloat(line.debitAmount)
          : undefined,
    }));

    // Post the reversal through the SAME trusted engine as every other
    // entry in this application — no special-case balancing logic
    // needed, since a flipped balanced entry is always itself balanced.
    // Passed `tx` here so it joins whatever transaction we're already in.
    const reversalResult = await postJournalEntry(
      {
        organizationId,
        entryDate: new Date().toISOString().split("T")[0],
        description: `Reversal of "${originalEntry.description}" — ${reason}`,
        sourceType: "void_reversal",
        sourceId: originalEntry.id,
        lines: reversedLines,
      },
      tx
    );

    // Mark the original as voided. Note we only ever UPDATE the isVoided
    // flag — we never touch its entryDate, description, or any of its
    // journal_lines rows. The original remains byte-for-byte exactly as
    // it was first posted.
    await tx
      .update(journalEntriesTable)
      .set({ isVoided: true, voidedAt: new Date() })
      .where(eqOp(journalEntriesTable.id, originalEntry.id));

    await tx
      .update(journalEntriesTable)
      .set({ reversalOfEntryId: originalEntry.id })
      .where(eqOp(journalEntriesTable.id, reversalResult.entry.id));

    return {
      originalEntryId: originalEntry.id,
      reversalEntryId: reversalResult.entry.id,
    };
  }

  // Same top-level-vs-nested decision as postJournalEntry (Part 7):
  // only open a brand-new transaction if we were NOT already handed one.
  if (executor === dbTransactional) {
    return executor.transaction((tx) => doVoid(tx as Executor));
  }
  return doVoid(executor);
}
```

### The Verification

No visible output yet — this function is exercised fully once wired into a real action in the next step. Confirm no TypeScript errors: `Executor`, `dbTransactional`, and `postJournalEntry` must already exist in this file from Parts 6–7 — if `Executor` isn't defined, revisit Part 7, Step 7.8, where it was introduced.

---

## Step 14.2.3 — Wiring Voiding Into Invoices and Bills

### The Target
Add a "Void Invoice" / "Void Bill" button to each detail page, calling `voidJournalEntry` and updating the parent record's status — as **one atomic transaction**, not two separate sequential writes.

### The Concept
Recall the reserved-but-unused `void` status from Parts 7 and 8 — this is the moment that doorway finally gets used. This step is also where the original draft of this part had its bug: voiding the journal entry and updating the invoice's status were two separate, sequential `await` calls with nothing tying them together. If the second write failed for any reason (a network blip, a database timeout), you'd end up with a voided journal entry but an invoice still showing as `sent` — an inconsistent, silently wrong state.

The fix: wrap both operations in a single `dbTransactional.transaction(...)` block, and pass that transaction's `tx` down into `voidJournalEntry` using the executor parameter from Step 14.2.2. Now either both writes happen, or neither does — no in-between state is possible.

We also deliberately guard against voiding an invoice/bill that already has payments recorded against it, since reversing the original revenue/expense recognition while a real payment sits unaddressed would leave the ledger in a confusing state — a sensible, conservative first version of this feature.

### The Implementation

**`src/lib/actions/invoices.ts`** (append this function — it uses `db`, `dbTransactional`, `invoices`, `eq`, `revalidatePath`, and `getOrCreateOrganization`, all already imported earlier in this file from Part 7)
```typescript
import { voidJournalEntry } from "@/lib/journal";
import { dbTransactional } from "@/db";

export async function voidInvoice(invoiceId: string, reason: string) {
  const organizationId = await getOrCreateOrganization();

  // Validation reads stay OUTSIDE the transaction — fail fast and cheap,
  // no need to hold a database transaction open just to check
  // preconditions that don't themselves write anything.
  const invoice = await db.query.invoices.findFirst({
    where: (invoices, { and, eq }) =>
      and(eq(invoices.id, invoiceId), eq(invoices.organizationId, organizationId)),
  });

  if (!invoice) {
    throw new Error("Invoice not found for this organization.");
  }
  if (invoice.status === "void") {
    throw new Error("This invoice has already been voided.");
  }
  // Number() rather than parseFloat() — parseFloat("12abc") silently
  // returns 12 instead of failing, which is the wrong failure mode for
  // a money-related guard. Number("12abc") correctly returns NaN, and
  // NaN > 0 is false, so a malformed value fails this check loudly
  // rather than accidentally passing it.
  if (Number(invoice.amountPaid) > 0) {
    throw new Error(
      "Cannot void an invoice that already has payments recorded against it. Void the payment(s) first."
    );
  }
  if (!invoice.journalEntryId) {
    throw new Error("This invoice has no associated journal entry to reverse.");
  }

  // ONE transaction wraps BOTH mutations: voidJournalEntry's own inserts/
  // updates, AND this invoice's status flip. They now commit or roll
  // back together as a single atomic unit — if the status update fails
  // for any reason, the journal reversal never happened either, and the
  // database is left exactly as it was before this function was called.
  await dbTransactional.transaction(async (tx) => {
    await voidJournalEntry(organizationId, invoice.journalEntryId!, reason, tx);

    await tx
      .update(invoices)
      .set({ status: "void" })
      .where(eq(invoices.id, invoiceId));
  });

  // Revalidation happens only AFTER the transaction has fully committed —
  // the same ordering discipline used for the Inngest event send in
  // Part 11.3: never announce a change before it's guaranteed to be real.
  revalidatePath("/invoices");
  revalidatePath(`/invoices/${invoiceId}`);
}
```

**`src/lib/actions/bills.ts`** (append this function, identically structured)
```typescript
import { voidJournalEntry } from "@/lib/journal";
import { dbTransactional } from "@/db";

export async function voidBill(billId: string, reason: string) {
  const organizationId = await getOrCreateOrganization();

  const bill = await db.query.bills.findFirst({
    where: (bills, { and, eq }) =>
      and(eq(bills.id, billId), eq(bills.organizationId, organizationId)),
  });

  if (!bill) {
    throw new Error("Bill not found for this organization.");
  }
  if (bill.status === "void") {
    throw new Error("This bill has already been voided.");
  }
  if (Number(bill.amountPaid) > 0) {
    throw new Error(
      "Cannot void a bill that already has payments recorded against it. Void the payment(s) first."
    );
  }
  if (!bill.journalEntryId) {
    throw new Error("This bill has no associated journal entry to reverse.");
  }

  await dbTransactional.transaction(async (tx) => {
    await voidJournalEntry(organizationId, bill.journalEntryId!, reason, tx);

    await tx
      .update(bills)
      .set({ status: "void" })
      .where(eq(bills.id, billId));
  });

  revalidatePath("/bills");
  revalidatePath(`/bills/${billId}`);
}
```

Now, the client component for the void button + reason prompt (unchanged from the original draft — this part had no bug):

**`src/components/void-button.tsx`**
```tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export function VoidButton({
  onVoid,
}: {
  onVoid: (reason: string) => Promise<void>;
}) {
  const router = useRouter();
  const [reason, setReason] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);

  async function handleVoid() {
    if (!reason.trim()) {
      setError("Please provide a reason for voiding this entry.");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await onVoid(reason);
      router.refresh();
      setShowForm(false);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  if (!showForm) {
    return (
      <button
        onClick={() => setShowForm(true)}
        className="text-xs text-red-600 hover:underline"
      >
        Void this record
      </button>
    );
  }

  return (
    <div className="mt-2 rounded border border-red-200 bg-red-50 p-3">
      <label className="block text-xs font-medium text-red-800">
        Reason for voiding (required)
      </label>
      <input
        type="text"
        value={reason}
        onChange={(e) => setReason(e.target.value)}
        placeholder="e.g. Entered in error, duplicate invoice"
        className="mt-1 w-full rounded border border-gray-300 px-2 py-1 text-sm"
      />
      {error && <p className="mt-1 text-xs text-red-600">{error}</p>}
      <div className="mt-2 flex gap-2">
        <button
          onClick={handleVoid}
          disabled={busy}
          className="rounded bg-red-600 px-3 py-1 text-xs text-white disabled:opacity-50"
        >
          {busy ? "Voiding..." : "Confirm Void"}
        </button>
        <button
          onClick={() => setShowForm(false)}
          disabled={busy}
          className="text-xs text-gray-500"
        >
          Cancel
        </button>
      </div>
    </div>
  );
}
```

Add it to the invoice detail page:

**`src/app/invoices/[id]/page.tsx`** (add near the status badge)
```tsx
import { voidInvoice } from "@/lib/actions/invoices";
import { VoidButton } from "@/components/void-button";

// ...inside the component, below the status badge:
{invoice.status !== "void" && Number(invoice.amountPaid) === 0 && (
  <VoidButton onVoid={(reason) => voidInvoice(invoice.id, reason)} />
)}
```

Add the equivalent block to `src/app/bills/[id]/page.tsx`, calling `voidBill(bill.id, reason)` instead.

### The Verification

**Baseline test (unchanged from the original draft):** Create a fresh test invoice with **no payments recorded** against it. On its detail page, confirm a "Void this record" link appears. Click it, type a reason (e.g., "Test void"), click **Confirm Void**.

Confirm the page refreshes showing status `void`. In Drizzle Studio:
- `invoices` — `status = void`.
- `journal_entries` — the **original** entry still exists, unchanged, now with `is_voided = true` and a real `voided_at` timestamp. A **new** entry exists with `source_type = void_reversal`, `reversal_of_entry_id` pointing at the original, description starting with `"Reversal of..."`.
- `journal_lines` — the new entry's lines are the exact mirror of the original (debit/credit swapped).

Revisit `/reports/balance-sheet` — confirm the green "✅ balanced" banner still holds. Revisit `/reports/aging` — confirm the voided invoice no longer appears.

Try voiding the same invoice a second time — confirm it throws "This invoice has already been voided." Try voiding an invoice with a partial payment recorded — confirm it throws "Cannot void an invoice that already has payments recorded against it."

**New: the atomicity regression test.** This is the test that specifically proves this rewrite fixed the bug. Temporarily introduce a forced failure into `voidInvoice`, right after the `voidJournalEntry` call, inside the transaction block:

```typescript
await dbTransactional.transaction(async (tx) => {
    await voidJournalEntry(organizationId, invoice.journalEntryId!, reason, tx);

    throw new Error("SIMULATED FAILURE — testing atomicity");

    await tx
      .update(invoices)
      .set({ status: "void" })
      .where(eq(invoices.id, invoiceId));
});
```

Attempt to void a fresh, unpaid test invoice. Confirm the action throws the simulated error and the UI shows a failure. Now check Drizzle Studio **carefully**:
- `invoices` — status must still be `sent` (or whatever it was before), **not** `void`.
- `journal_entries` — the original entry must **not** show `is_voided = true`, and **no** reversal entry should exist at all.

This confirms the fix: when any part of the combined operation fails, *nothing* persists — not the reversal, not the void flag, not the status change. Remove the simulated `throw new Error(...)` line afterward and re-verify the normal (non-failing) path still works exactly as in the baseline test above.

---

## ✅ Checkpoint — Part 14.2 

- [x] `journal_entries` extended with `isVoided`, `voidedAt`, `reversalOfEntryId`
- [x] `voidJournalEntry` upgraded to accept an optional `executor`, matching `postJournalEntry`'s composable transaction pattern from Part 7
- [x] `voidInvoice`/`voidBill` rewritten to wrap the reversal **and** the status update in a single `dbTransactional.transaction(...)` block
- [x] `Number(...)` used instead of `parseFloat(...)` for the payment-guard check, avoiding a silent parsing failure mode
- [x] Verified: both entries remain permanently visible, the Balance Sheet still balances, Aging correctly excludes voided records
- [x] **Verified via a deliberate forced failure** that a mid-operation error leaves zero side effects — no orphaned voided entry, no orphaned status change
