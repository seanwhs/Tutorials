# Part 14.4: Bank Reconciliation

Part 12 built a way for bank activity to flow *into* the ledger via CSV import. But a real bookkeeping practice also periodically performs **reconciliation**: formally confirming the ledger's own Cash balance agrees with what the bank itself says, as of a specific date — and flagging anything that doesn't add up. This term was defined all the way back in Part 4's glossary specifically to set up this feature. This part builds it.

## Step 14.4.1 — Understanding Reconciliation, In Plain English

### The Target
Before writing code, understand exactly what problem this feature solves and why it's genuinely different from anything built in Parts 9 or 12.

### The Concept
Imagine balancing your personal checkbook: your own notebook says you have $842 in your account, and your bank's statement says $850. That $8 difference isn't necessarily an error — maybe a check you wrote hasn't cleared yet (the bank doesn't know about it), or the bank charged a small fee you haven't recorded yet (you don't know about it). **Reconciliation** is the disciplined process of finding and explaining every such difference until both sides agree, then formally "closing the book" on that period so it can't be silently altered later.

For Greymatter Ledger, this means: a user enters the bank statement's actual ending balance for a chosen date, we compute what the ledger's own `Cash` account balance is as of that same date (reusing `getAccountBalancesAsOf` from Part 9 — no new aggregation logic needed), and if they don't match, we help the user find out why by showing which posted Cash transactions haven't yet been "checked off" as confirmed on the statement. Once every transaction is checked and the two totals agree, the period gets marked reconciled — a `reconciliations` record locked to that date.

## Step 14.4.2 — Designing the Schema

### The Target
Add two tables: `reconciliations` (one per completed reconciliation session) and `reconciliation_items` (which specific Cash-affecting journal lines were checked off in that session).

### The Concept
Recall the journal_entries/journal_lines envelope-and-contents pattern from Part 6 — we're reusing the exact same shape here. A `reconciliations` row is the envelope ("I reconciled Cash as of March 31, bank said $850, we matched"); each `reconciliation_items` row is one specific journal line that was checked off as part of that session. This lets us answer, forever afterward, "was this specific transaction ever reconciled, and in which session?"

### The Implementation

**`src/db/schema.ts`** (new additions)
```typescript
export const reconciliations = pgTable("reconciliations", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  // Which Cash/bank account this reconciliation session covers — most
  // businesses only have one, but the schema doesn't assume that.
  accountId: uuid("account_id")
    .notNull()
    .references(() => accounts.id, { onDelete: "restrict" }),

  asOfDate: date("as_of_date").notNull(),

  // The bank's own stated ending balance, entered by the user — the
  // external source of truth we're checking our ledger against.
  statementEndingBalance: numeric("statement_ending_balance", {
    precision: 14,
    scale: 2,
  }).notNull(),

  // The ledger's own computed Cash balance as of asOfDate, captured at
  // the moment this reconciliation was completed — stored (not just
  // recalculated later) so a historical reconciliation record remains
  // meaningful even if, hypothetically, future entries get backdated
  // into this period (which Part 14.2's voiding discipline discourages,
  // but a reconciliation record shouldn't silently drift regardless).
  ledgerBalance: numeric("ledger_balance", { precision: 14, scale: 2 }).notNull(),

  isComplete: boolean("is_complete").notNull().default(false),
  completedAt: timestamp("completed_at"),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const reconciliationItems = pgTable("reconciliation_items", {
  id: uuid("id").primaryKey().defaultRandom(),

  reconciliationId: uuid("reconciliation_id")
    .notNull()
    .references(() => reconciliations.id, { onDelete: "cascade" }),

  journalLineId: uuid("journal_line_id")
    .notNull()
    .references(() => journalLines.id, { onDelete: "restrict" }),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const reconciliationsRelations = relations(reconciliations, ({ one, many }) => ({
  account: one(accounts, {
    fields: [reconciliations.accountId],
    references: [accounts.id],
  }),
  items: many(reconciliationItems),
}));

export const reconciliationItemsRelations = relations(reconciliationItems, ({ one }) => ({
  journalLine: one(journalLines, {
    fields: [reconciliationItems.journalLineId],
    references: [journalLines.id],
  }),
}));
```

### The Verification

```bash
npm run db:generate
npm run db:migrate
```

Confirm both new tables appear in Drizzle Studio, currently empty.

---

## Step 14.4.3 — Fetching Unreconciled Cash Lines

### The Target
Write a function returning every posted `journal_lines` row touching a given Cash account, up to a chosen date, that hasn't yet been checked off in a completed reconciliation.

### The Concept
This is the reconciliation review screen's data source — the list of individual transactions a user checks off one by one until the running total matches the bank statement.

### The Implementation

**`src/lib/reconciliation.ts`**
```typescript
import { db } from "@/db";
import { journalLines, journalEntries, reconciliationItems } from "@/db/schema";
import { eq, and, lte, notInArray, inArray } from "drizzle-orm";

export type UnreconciledLine = {
  id: string;
  entryDate: string;
  description: string;
  debitAmount: string;
  creditAmount: string;
};

export async function getUnreconciledCashLines(
  organizationId: string,
  accountId: string,
  asOfDate: string
): Promise<UnreconciledLine[]> {
  // First, find every journal_line ID that has ALREADY been checked off
  // in a previously COMPLETED reconciliation for this account — these
  // must never be offered again, since re-reconciling an already-closed
  // period would defeat the entire point of "closing the book."
  const alreadyReconciled = await db
    .select({ journalLineId: reconciliationItems.journalLineId })
    .from(reconciliationItems)
    .innerJoin(
      journalLines,
      eq(reconciliationItems.journalLineId, journalLines.id)
    );

  const excludedIds = alreadyReconciled.map((r) => r.journalLineId);

  const rows = await db
    .select({
      id: journalLines.id,
      entryDate: journalEntries.entryDate,
      description: journalEntries.description,
      debitAmount: journalLines.debitAmount,
      creditAmount: journalLines.creditAmount,
    })
    .from(journalLines)
    .innerJoin(journalEntries, eq(journalLines.journalEntryId, journalEntries.id))
    .where(
      and(
        eq(journalEntries.organizationId, organizationId),
        eq(journalLines.accountId, accountId),
        lte(journalEntries.entryDate, asOfDate),
        eq(journalEntries.isVoided, false), // voided entries (Part 14.2) never need reconciling
        excludedIds.length > 0
          ? notInArray(journalLines.id, excludedIds)
          : undefined
      )
    )
    .orderBy(journalEntries.entryDate);

  return rows;
}
```

### The Verification

No visible output yet — verified alongside the review page next.

---

## Step 14.4.4 — Starting and Completing a Reconciliation

### The Target
Server actions to start a reconciliation session (entering the bank's statement balance) and complete it (once every line is checked off and the totals match).

### The Implementation

**`src/lib/actions/reconciliation.ts`**
```typescript
"use server";

import { db } from "@/db";
import { reconciliations, reconciliationItems, accounts } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { getAccountBalancesAsOf } from "@/lib/reports";
import { requireAdminRole } from "@/lib/permissions";
import { eq, and } from "drizzle-orm";
import { revalidatePath } from "next/cache";

export async function startReconciliation(
  accountId: string,
  asOfDate: string,
  statementEndingBalance: number
) {
  const organizationId = await getOrCreateOrganization();

  const balances = await getAccountBalancesAsOf(organizationId, asOfDate);
  const accountBalance = balances.find((b) => b.accountId === accountId);

  if (!accountBalance) {
    throw new Error("Account not found for this organization.");
  }

  const [reconciliation] = await db
    .insert(reconciliations)
    .values({
      organizationId,
      accountId,
      asOfDate,
      statementEndingBalance: statementEndingBalance.toFixed(2),
      ledgerBalance: accountBalance.balance.toFixed(2),
      isComplete: false,
    })
    .returning();

  revalidatePath("/reconciliation");
  return reconciliation;
}

export async function toggleReconciliationItem(
  reconciliationId: string,
  journalLineId: string,
  checked: boolean
) {
  if (checked) {
    await db.insert(reconciliationItems).values({ reconciliationId, journalLineId });
  } else {
    await db
      .delete(reconciliationItems)
      .where(
        and(
          eq(reconciliationItems.reconciliationId, reconciliationId),
          eq(reconciliationItems.journalLineId, journalLineId)
        )
      );
  }
  revalidatePath("/reconciliation");
}

export async function completeReconciliation(reconciliationId: string) {
  // Closing a period is a meaningful, hard-to-undo action — same trust
  // tier as voiding (Part 14.3), so it's gated identically.
  await requireAdminRole("complete a reconciliation");

  const organizationId = await getOrCreateOrganization();

  const reconciliation = await db.query.reconciliations.findFirst({
    where: (r, { and, eq }) =>
      and(eq(r.id, reconciliationId), eq(r.organizationId, organizationId)),
    with: { items: { with: { journalLine: true } } },
  });

  if (!reconciliation) throw new Error("Reconciliation not found.");
  if (reconciliation.isComplete) throw new Error("This reconciliation is already complete.");

  // Recompute the running checked-off total from the actual line amounts
  // (never trust a client-supplied total) and confirm it matches the
  // statement balance before allowing completion — the server-side proof
  // that reconciliation, not just a UI checkbox count, actually occurred.
  const checkedTotal = reconciliation.items.reduce((sum, item) => {
    const line = item.journalLine;
    return sum + Number(line.debitAmount) - Number(line.creditAmount);
  }, 0);

  const statementBalance = Number(reconciliation.statementEndingBalance);

  if (Math.abs(checkedTotal - statementBalance) > 0.01) {
    throw new Error(
      `Checked items total $${checkedTotal.toFixed(2)}, which does not match the statement balance of $${statementBalance.toFixed(2)}. Check off additional items, or investigate the difference, before completing this reconciliation.`
    );
  }

  await db
    .update(reconciliations)
    .set({ isComplete: true, completedAt: new Date() })
    .where(eq(reconciliations.id, reconciliationId));

  revalidatePath("/reconciliation");
}
```

### The Verification

No visible output yet — exercised fully in the next step alongside the review page.

---

## Step 14.4.5 — The Reconciliation Review Page

### The Target
Build `/reconciliation`, letting a user start a session, check off transactions one by one, watch a running total update live, and complete the session once it matches.

### The Implementation

**`src/components/reconciliation-checklist.tsx`**
```tsx
"use client";

import { useState, useTransition } from "react";
import {
  toggleReconciliationItem,
  completeReconciliation,
} from "@/lib/actions/reconciliation";

type Line = {
  id: string;
  entryDate: string;
  description: string;
  debitAmount: string;
  creditAmount: string;
};

export function ReconciliationChecklist({
  reconciliationId,
  lines,
  checkedLineIds,
  statementEndingBalance,
}: {
  reconciliationId: string;
  lines: Line[];
  checkedLineIds: string[];
  statementEndingBalance: string;
}) {
  const [checked, setChecked] = useState<Set<string>>(new Set(checkedLineIds));
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const runningTotal = lines
    .filter((l) => checked.has(l.id))
    .reduce((sum, l) => sum + Number(l.debitAmount) - Number(l.creditAmount), 0);

  const target = Number(statementEndingBalance);
  const isMatched = Math.abs(runningTotal - target) < 0.01;

  function toggle(lineId: string, isChecked: boolean) {
    setChecked((prev) => {
      const next = new Set(prev);
      isChecked ? next.add(lineId) : next.delete(lineId);
      return next;
    });
    startTransition(() => {
      toggleReconciliationItem(reconciliationId, lineId, isChecked);
    });
  }

  async function handleComplete() {
    setError(null);
    try {
      await completeReconciliation(reconciliationId);
    } catch (err) {
      setError((err as Error).message);
    }
  }

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4">
      <table className="w-full text-left text-sm">
        <thead className="border-b border-gray-200 text-gray-500">
          <tr>
            <th className="py-2"></th>
            <th className="py-2">Date</th>
            <th className="py-2">Description</th>
            <th className="py-2 text-right">Amount</th>
          </tr>
        </thead>
        <tbody>
          {lines.map((line) => {
            const amount = Number(line.debitAmount) - Number(line.creditAmount);
            return (
              <tr key={line.id} className="border-t border-gray-100">
                <td className="py-1.5">
                  <input
                    type="checkbox"
                    checked={checked.has(line.id)}
                    onChange={(e) => toggle(line.id, e.target.checked)}
                  />
                </td>
                <td className="py-1.5 text-gray-500">{line.entryDate}</td>
                <td className="py-1.5">{line.description}</td>
                <td className={`py-1.5 text-right ${amount >= 0 ? "text-green-700" : "text-red-700"}`}>
                  {amount >= 0 ? "+" : ""}
                  {amount.toFixed(2)}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>

      <div className="mt-4 flex items-center justify-between border-t-2 border-gray-800 pt-3">
        <div className="text-sm">
          <div>Checked total: ${runningTotal.toFixed(2)}</div>
          <div>Statement balance: ${target.toFixed(2)}</div>
        </div>
        <div
          className={`rounded px-3 py-1 text-sm font-semibold ${
            isMatched ? "bg-green-100 text-green-800" : "bg-yellow-100 text-yellow-800"
          }`}
        >
          {isMatched ? "✅ Matched" : "Not yet matched"}
        </div>
      </div>

      {error && <p className="mt-2 text-sm text-red-600">{error}</p>}

      <button
        onClick={handleComplete}
        disabled={!isMatched || isPending}
        className="mt-3 rounded bg-blue-600 px-4 py-2 text-sm text-white disabled:opacity-50"
      >
        Complete Reconciliation
      </button>
    </div>
  );
}
```

**`src/app/reconciliation/page.tsx`**
```tsx
import { getOrCreateOrganization } from "@/lib/organizations";
import { getUnreconciledCashLines } from "@/lib/reconciliation";
import { db } from "@/db";
import { accounts, reconciliations } from "@/db/schema";
import { eq, and } from "drizzle-orm";
import { ReconciliationChecklist } from "@/components/reconciliation-checklist";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";

export default async function ReconciliationPage({
  searchParams,
}: {
  searchParams: Promise<{ reconciliationId?: string }>;
}) {
  const { reconciliationId } = await searchParams;
  const organizationId = await getOrCreateOrganization();

  const cashAccount = await db.query.accounts.findFirst({
    where: (a, { and, eq }) => and(eq(a.organizationId, organizationId), eq(a.code, "1000")),
  });

  if (!cashAccount) {
    return <p className="p-8">Cash account (1000) not found — seed the Chart of Accounts first.</p>;
  }

  let activeReconciliation = null;
  if (reconciliationId) {
    activeReconciliation = await db.query.reconciliations.findFirst({
      where: (r, { and, eq }) =>
        and(eq(r.id, reconciliationId), eq(r.organizationId, organizationId)),
      with: { items: true },
    });
  }

  const unreconciledLines = activeReconciliation
    ? await getUnreconciledCashLines(organizationId, cashAccount.id, activeReconciliation.asOfDate)
    : [];

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-3xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Bank Reconciliation</h1>
          <div className="flex items-center gap-4">
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        {!activeReconciliation ? (
          <form
            action={async (formData: FormData) => {
              "use server";
              const { startReconciliation } = await import("@/lib/actions/reconciliation");
              const result = await startReconciliation(
                cashAccount.id,
                formData.get("asOfDate") as string,
                parseFloat(formData.get("statementBalance") as string)
              );
              const { redirect } = await import("next/navigation");
              redirect(`/reconciliation?reconciliationId=${result.id}`);
            }}
            className="mt-6 space-y-3 rounded-lg border border-gray-200 bg-white p-4"
          >
            <h3 className="font-semibold text-gray-800">Start a new reconciliation</h3>
            <div>
              <label className="block text-xs font-medium text-gray-600">As of date</label>
              <input type="date" name="asOfDate" required className="mt-1 rounded border border-gray-300 px-2 py-1 text-sm" />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-600">Bank statement ending balance</label>
              <input type="number" step="0.01" name="statementBalance" required className="mt-1 rounded border border-gray-300 px-2 py-1 text-sm" />
            </div>
            <button className="rounded bg-blue-600 px-4 py-2 text-sm text-white">Start</button>
          </form>
        ) : (
          <div className="mt-6">
            <p className="text-sm text-gray-500">
              Reconciling Cash as of {activeReconciliation.asOfDate}
            </p>
            <div className="mt-4">
              <ReconciliationChecklist
                reconciliationId={activeReconciliation.id}
                lines={unreconciledLines}
                checkedLineIds={activeReconciliation.items.map((i) => i.journalLineId)}
                statementEndingBalance={activeReconciliation.statementEndingBalance}
              />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
```

Add `/reconciliation` to `src/proxy.ts`'s protected matcher.

### The Verification

Visit `/reconciliation`. Start a session for today's date with a statement balance matching your current test data's actual Cash balance (cross-check via `/reports/balance-sheet`). Check off transactions one by one — confirm the running total updates live and the "✅ Matched" badge appears once it equals the statement balance. Click **Complete Reconciliation** — confirm success, and that `reconciliations.is_complete = true` in Drizzle Studio.

Start a *second* reconciliation for a later date — confirm previously-checked-off lines from the completed session no longer appear in the new session's list (enforced by `getUnreconciledCashLines`'s exclusion query).
