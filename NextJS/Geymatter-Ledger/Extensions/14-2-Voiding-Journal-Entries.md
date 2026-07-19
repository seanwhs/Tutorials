# Part 14.2: Voiding and Reversing Journal Entries, Invoices, Bills, and Payments

Recall the principle from Part 4 and Part 6: once a journal entry is posted, it's permanent historical fact. The correct way to "undo" anything is never to delete — it's to post an offsetting entry and mark the original as superseded. This part builds that capability all the way down the stack: the ledger itself, then invoices and bills, and now — completing the chain — payments too, since without the ability to void a payment, voiding a paid invoice was previously an unreachable dead end.

## Step 14.2.1 — Extending the Schema (Journal Entries *and* Payments)

### The Target
Add `isVoided`/`voidedAt`/`reversalOfEntryId` to `journal_entries`, **and** `isVoided`/`voidedAt` to `payments`.

### The Concept
Same crossed-out-line-in-a-physical-ledger analogy as before, applied to one more table. A voided payment is never deleted — the fact that money once moved and was later reversed both remain visible forever. Without this column, a voided payment would look structurally identical to an active one, and there'd be no way to prevent voiding the same payment twice, or to know which payments to exclude from a future "payment history" view.

### The Implementation

**`src/db/schema.ts`** (replace the existing `journalEntries` table definition — unchanged from the prior revision)
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

    isVoided: boolean("is_voided").notNull().default(false),
    voidedAt: timestamp("voided_at"),
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

**`src/db/schema.ts`** (replace the existing `payments` table definition — new columns added)
```typescript
export const payments = pgTable("payments", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  invoiceId: uuid("invoice_id").references(() => invoices.id, {
    onDelete: "restrict",
  }),
  billId: uuid("bill_id").references(() => bills.id, {
    onDelete: "restrict",
  }),

  amount: numeric("amount", { precision: 14, scale: 2 }).notNull(),
  paymentDate: date("payment_date").notNull(),
  method: paymentMethodEnum("method").notNull().default("bank_transfer"),

  bankAccountId: uuid("bank_account_id")
    .notNull()
    .references(() => accounts.id, { onDelete: "restrict" }),

  journalEntryId: uuid("journal_entry_id").references(() => journalEntries.id, {
    onDelete: "set null",
  }),

  // --- New in Part 14.2 ---
  // A voided payment is never deleted — it remains permanently visible,
  // exactly as originally recorded, with this flag marking it reversed.
  // This mirrors journal_entries.isVoided exactly, for the same reason.
  isVoided: boolean("is_voided").notNull().default(false),
  voidedAt: timestamp("voided_at"),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const paymentsRelations = relations(payments, ({ one }) => ({
  invoice: one(invoices, {
    fields: [payments.invoiceId],
    references: [invoices.id],
  }),
  bill: one(bills, {
    fields: [payments.billId],
    references: [bills.id],
  }),
  bankAccount: one(accounts, {
    fields: [payments.bankAccountId],
    references: [accounts.id],
  }),
}));
```

### The Verification

```bash
npm run db:generate
npm run db:migrate
```

Expected output should mention new columns on both `journal_entries` (`is_voided`, `voided_at`, `reversal_of_entry_id`) and `payments` (`is_voided`, `voided_at`), plus the new foreign key. Confirm all five new columns appear in Drizzle Studio, and that every existing row in both tables now shows `is_voided = false` (the `DEFAULT` applying retroactively, non-destructively, to rows created in earlier parts).

---

## Step 14.2.2 — The `voidJournalEntry` Function

### The Target
The core, reusable reversal engine — unchanged from the corrected version discussed earlier, but reproduced here in full so this part is complete and self-contained.

### The Concept
Recall Part 6's engine: we're not writing new balancing logic — we're reusing `postJournalEntry` unchanged, feeding it the original entry's lines with debit and credit swapped. The critical architectural detail: this function accepts an **optional executor** (Part 7's composable-transaction pattern), so any caller — `voidInvoice`, `voidBill`, and now `voidPayment` — can fold the reversal into its own larger, single atomic transaction, rather than each void operation running as two or three separate, un-linked writes.

### The Implementation

**`src/lib/journal.ts`** (append to the existing file)
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
 * voided. The original entry is NEVER deleted or modified in place.
 *
 * Accepts an optional `executor`, exactly like postJournalEntry. If
 * omitted, opens its own transaction. If a caller passes its own `tx`,
 * this function joins THAT transaction — used by voidInvoice, voidBill,
 * and voidPayment below, so each of those can combine the reversal with
 * their own additional writes as one atomic unit.
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

  if (executor === dbTransactional) {
    return executor.transaction((tx) => doVoid(tx as Executor));
  }
  return doVoid(executor);
}
```

### The Verification

No visible output yet — exercised fully in the steps below.

---

## Step 14.2.3 — Voiding Payments (`voidPayment`)

### The Target
Write `voidPayment(paymentId, reason)` — reverses a payment's Cash↔AR (or Cash↔AP) journal entry, decrements the parent invoice's/bill's `amountPaid`, recomputes its `status`, and marks the payment itself as voided — all as one atomic transaction.

### The Concept
This is the piece that was missing before, and it has to come *first* in this rewrite's build order — logically, you must be able to void a payment before you can void a fully-paid invoice or bill, since Step 14.2.4 (voiding invoices/bills) will now actively call this when needed.

Think of the relationship: an invoice's `amountPaid` is a running total built up from potentially multiple `payments` rows. Voiding one payment doesn't just reverse its own journal entry — it must also reduce the parent's `amountPaid` by exactly that payment's amount, and recompute whether the parent is still `paid`, drops back to `partially_paid`, or returns to `sent`/`received` if that was the only payment. Getting the status recomputation right (not just decrementing the number) is what makes this genuinely correct rather than superficially plausible.

### The Implementation

**`src/lib/actions/payments.ts`** (append to the existing file from Part 8)
```typescript
import { voidJournalEntry } from "@/lib/journal";
import { dbTransactional } from "@/db";

export async function voidPayment(paymentId: string, reason: string) {
  const organizationId = await getOrCreateOrganization();

  const payment = await db.query.payments.findFirst({
    where: (payments, { and, eq }) =>
      and(eq(payments.id, paymentId), eq(payments.organizationId, organizationId)),
  });

  if (!payment) {
    throw new Error("Payment not found for this organization.");
  }
  if (payment.isVoided) {
    throw new Error("This payment has already been voided.");
  }
  if (!payment.journalEntryId) {
    throw new Error("This payment has no associated journal entry to reverse.");
  }
  if (!payment.invoiceId && !payment.billId) {
    throw new Error("Malformed payment — has neither an invoiceId nor a billId.");
  }

  const paymentAmount = Number(payment.amount);

  await dbTransactional.transaction(async (tx) => {
    // 1. Reverse the payment's own Cash↔AR / Cash↔AP journal entry,
    // participating in this same transaction via the executor pattern.
    await voidJournalEntry(organizationId, payment.journalEntryId!, reason, tx);

    // 2. Mark the payment itself as voided — never deleted.
    await tx
      .update(payments)
      .set({ isVoided: true, voidedAt: new Date() })
      .where(eq(payments.id, paymentId));

    // 3. Decrement the parent invoice/bill's amountPaid and recompute
    // its status. We re-fetch the parent's CURRENT total/amountPaid
    // inside the transaction (not from an earlier read) to guarantee
    // we're working from the true, latest committed values.
    if (payment.invoiceId) {
      const invoice = await tx.query.invoices.findFirst({
        where: (invoices, { eq }) => eq(invoices.id, payment.invoiceId!),
      });
      if (!invoice) throw new Error("Parent invoice not found.");

      const newAmountPaid = Number(invoice.amountPaid) - paymentAmount;
      const total = Number(invoice.total);

      // Recompute status from scratch based on the new amountPaid,
      // rather than just assuming "partially_paid" — this correctly
      // handles the case where voiding the ONLY payment should return
      // the invoice all the way back to "sent", not leave it stuck as
      // "partially_paid" with zero actually paid.
      const newStatus =
        newAmountPaid <= 0.001
          ? "sent"
          : newAmountPaid >= total - 0.001
          ? "paid"
          : "partially_paid";

      await tx
        .update(invoices)
        .set({
          amountPaid: Math.max(0, newAmountPaid).toFixed(2),
          status: newStatus,
        })
        .where(eq(invoices.id, payment.invoiceId));
    }

    if (payment.billId) {
      const bill = await tx.query.bills.findFirst({
        where: (bills, { eq }) => eq(bills.id, payment.billId!),
      });
      if (!bill) throw new Error("Parent bill not found.");

      const newAmountPaid = Number(bill.amountPaid) - paymentAmount;
      const total = Number(bill.total);

      const newStatus =
        newAmountPaid <= 0.001
          ? "received"
          : newAmountPaid >= total - 0.001
          ? "paid"
          : "partially_paid";

      await tx
        .update(bills)
        .set({
          amountPaid: Math.max(0, newAmountPaid).toFixed(2),
          status: newStatus,
        })
        .where(eq(bills.id, payment.billId));
    }
  });

  revalidatePath("/invoices");
  revalidatePath("/bills");
  if (payment.invoiceId) revalidatePath(`/invoices/${payment.invoiceId}`);
  if (payment.billId) revalidatePath(`/bills/${payment.billId}`);
}
```

### The Verification

Create a fresh test invoice, record a **partial** payment against it (e.g., $500 of $1,290), then void that payment. Confirm:
- `payments` — the row now shows `is_voided = true`, `voided_at` set.
- `invoices` — `amountPaid` back to `0.00`, `status` back to `sent` (not stuck at `partially_paid`).
- `journal_entries` — a new `void_reversal` entry exists, the original payment entry now shows `is_voided = true`.

Now record a **full** payment ($1,290) against a different fresh test invoice, confirm it flips to `paid`, then void that single payment. Confirm `amountPaid` returns to `0.00` and `status` returns to `sent` — proving the "recompute from scratch" logic correctly handles the full-to-zero case, not just partial decrements.

---

## Step 14.2.4 — Voiding Invoices and Bills (Now With a Real Escape Hatch)

### The Target
Rewrite `voidInvoice`/`voidBill` so a paid invoice/bill is no longer a dead end — the guard now tells the truth about what's actually blocking it, and the payments *can* be voided first via the function built in Step 14.2.3.

### The Concept
The old guard clause said "void the payment(s) first" without giving any way to do so. Now that `voidPayment` exists, the guard is no longer a dead end — it's an accurate, actionable instruction. We keep the guard itself (an invoice with real payments still attached genuinely shouldn't be voided directly — the payments must be unwound first, in the right order, which is a deliberate design choice, not a shortcut), but we close the loop by actually building the button that lets a user do it.

### The Implementation

**`src/lib/actions/invoices.ts`** (replace `voidInvoice` — logic unchanged from the atomicity fix, error message clarified)
```typescript
import { voidJournalEntry } from "@/lib/journal";
import { dbTransactional } from "@/db";

export async function voidInvoice(invoiceId: string, reason: string) {
  const organizationId = await getOrCreateOrganization();

  const invoice = await db.query.invoices.findFirst({
    where: (invoices, { and, eq }) =>
      and(eq(invoices.id, invoiceId), eq(invoices.organizationId, organizationId)),
  });

  if (!invoice) throw new Error("Invoice not found for this organization.");
  if (invoice.status === "void") throw new Error("This invoice has already been voided.");
  if (Number(invoice.amountPaid) > 0) {
    throw new Error(
      "Cannot void an invoice that still has payments recorded against it. Void each payment individually first (see the invoice's payment history), then void the invoice."
    );
  }
  if (!invoice.journalEntryId) {
    throw new Error("This invoice has no associated journal entry to reverse.");
  }

  await dbTransactional.transaction(async (tx) => {
    await voidJournalEntry(organizationId, invoice.journalEntryId!, reason, tx);

    await tx
      .update(invoices)
      .set({ status: "void" })
      .where(eq(invoices.id, invoiceId));
  });

  revalidatePath("/invoices");
  revalidatePath(`/invoices/${invoiceId}`);
}
```

**`src/lib/actions/bills.ts`** (replace `voidBill`, identically)
```typescript
import { voidJournalEntry } from "@/lib/journal";
import { dbTransactional } from "@/db";

export async function voidBill(billId: string, reason: string) {
  const organizationId = await getOrCreateOrganization();

  const bill = await db.query.bills.findFirst({
    where: (bills, { and, eq }) =>
      and(eq(bills.id, billId), eq(bills.organizationId, organizationId)),
  });

  if (!bill) throw new Error("Bill not found for this organization.");
  if (bill.status === "void") throw new Error("This bill has already been voided.");
  if (Number(bill.amountPaid) > 0) {
    throw new Error(
      "Cannot void a bill that still has payments recorded against it. Void each payment individually first, then void the bill."
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

Now add a payment history list with per-payment void buttons to both detail pages, so the escape hatch is actually reachable in the UI:

**`src/components/payment-history.tsx`**
```tsx
"use client";

import { VoidButton } from "@/components/void-button";
import { voidPayment } from "@/lib/actions/payments";

type Payment = {
  id: string;
  amount: string;
  paymentDate: string;
  method: string;
  isVoided: boolean;
};

export function PaymentHistory({ payments }: { payments: Payment[] }) {
  if (payments.length === 0) return null;

  return (
    <div className="mt-6 rounded-lg border border-gray-200 bg-gray-50 p-4">
      <h3 className="text-sm font-semibold text-gray-800">Payment History</h3>
      <table className="mt-2 w-full text-left text-sm">
        <tbody>
          {payments.map((p) => (
            <tr key={p.id} className="border-t border-gray-200">
              <td className="py-1.5 text-gray-700">{p.paymentDate}</td>
              <td className="py-1.5 text-gray-700">${p.amount}</td>
              <td className="py-1.5 text-gray-500">{p.method}</td>
              <td className="py-1.5">
                {p.isVoided ? (
                  <span className="rounded-full bg-gray-100 px-2 py-0.5 text-xs text-gray-400">
                    Voided
                  </span>
                ) : (
                  <VoidButton onVoid={(reason) => voidPayment(p.id, reason)} />
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

Update `getInvoiceById`/`getBillById` (Parts 7/8) to also fetch `payments`, and render `<PaymentHistory />` plus the invoice/bill-level `<VoidButton />` on both detail pages:

**`src/lib/actions/invoices.ts`** (update `getInvoiceById`)
```typescript
export async function getInvoiceById(invoiceId: string) {
  const organizationId = await getOrCreateOrganization();

  return db.query.invoices.findFirst({
    where: (invoices, { and, eq }) =>
      and(eq(invoices.id, invoiceId), eq(invoices.organizationId, organizationId)),
    with: {
      customer: true,
      lines: true,
      payments: true, // NEW — needed for the payment history + void UI
    },
  });
}
```

This requires an `invoices.payments` relation — add it alongside the existing `invoicesRelations`:

**`src/db/schema.ts`** (extend `invoicesRelations`)
```typescript
export const invoicesRelations = relations(invoices, ({ one, many }) => ({
  customer: one(customers, {
    fields: [invoices.customerId],
    references: [customers.id],
  }),
  lines: many(invoiceLines),
  payments: many(payments), // NEW
}));
```

(Add the equivalent `payments: many(payments)` to `billsRelations`, and `payments: true` to `getBillById`.)

**`src/app/invoices/[id]/page.tsx`** (add near the existing `<VoidButton />` block)
```tsx
import { PaymentHistory } from "@/components/payment-history";

// ...inside the component, after the balance summary:
<PaymentHistory payments={invoice.payments} />

{invoice.status !== "void" && Number(invoice.amountPaid) === 0 && (
  <VoidButton onVoid={(reason) => voidInvoice(invoice.id, reason)} />
)}
```

(Mirror this in `src/app/bills/[id]/page.tsx`.)

### The Verification

**Full end-to-end test — this is the scenario that was previously impossible:**

1. Create a fresh invoice, record a **full** payment against it. Confirm `status = paid`.
2. On the detail page, confirm the invoice-level "Void this record" button is **gone** (guarded by `Number(invoice.amountPaid) === 0`), but a **Payment History** section now appears showing the payment with its own "Void this record" link.
3. Click void on the payment. Confirm the page refreshes: the invoice's `status` drops back to `sent`, `amountPaid` returns to `0.00`, and the payment row now shows a grey "Voided" badge instead of a void link.
4. The invoice-level void button now **reappears** (since `amountPaid` is back to `0`). Click it, provide a reason, confirm.
5. In Drizzle Studio: `invoices.status = void`; `payments.is_voided = true`; **two** reversal entries exist in `journal_entries` (one reversing the payment, one reversing the original invoice), plus the two original entries, both now `is_voided = true`. Four `journal_entries` rows total for this one invoice's full lifecycle — all four permanently visible, none deleted.
6. `/reports/balance-sheet` — confirm still balanced. `/reports/aging` — confirm the invoice no longer appears.

This closes the loop the earlier guard clause had left open.

---

## ✅ Checkpoint — Part 14.2 (Complete)

- [x] `journal_entries` extended with `isVoided`/`voidedAt`/`reversalOfEntryId`; `payments` extended with `isVoided`/`voidedAt`
- [x] `voidJournalEntry` — composable via an optional executor, reuses `postJournalEntry` unchanged
- [x] `voidPayment` — reverses the payment's journal entry, correctly recomputes the parent invoice/bill's `amountPaid` and `status` from scratch, atomically
- [x] `voidInvoice`/`voidBill` — atomic, with an error message that now points to a real, working escape hatch
- [x] A payment history UI with per-payment void controls, closing the previously-dead-end guard clause
- [x] Verified end-to-end: pay → void payment → status correctly reverts → void invoice → four permanently-visible ledger entries, Balance Sheet still balanced
