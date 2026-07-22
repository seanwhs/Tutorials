# Part 35 — Bank Reconciliation System

In Part 34, we posted imported bank transactions to the ledger.

Now we will add a simple bank reconciliation system.

By the end of this part, you will have:

- Bank reconciliation fields
- Reconciliation service
- Reconciliation server action
- Reconcile button for posted bank transactions
- Reconciliation summary page
- Neon SQL verification

This version is intentionally simple:

```txt
Posted bank transaction -> mark reconciled
```

A more advanced version would match imported bank transactions against existing ledger entries and statement balances.

---

# 1. Understand Bank Reconciliation

## The Target

We are confirming that posted bank transactions are accepted as reconciled.

---

## The Concept

Bank reconciliation means checking that:

```txt
Your accounting records
```

agree with:

```txt
The bank statement
```

A simple reconciliation workflow:

```txt
Import bank transaction
Categorize it
Post it to the ledger
Mark it reconciled
```

Once reconciled, the transaction should be locked from further changes.

---

# 2. Add Reconciliation Fields

## The Target

We are updating:

```txt
bank_transactions
```

with:

```txt
reconciled_at
reconciled_by_user_id
```

---

## The Implementation

Open:

```txt
db/schema.ts
```

In `bankTransactions`, add:

```ts
reconciledAt: timestamp("reconciled_at", { withTimezone: true }),

reconciledByUserId: text("reconciled_by_user_id"),
```

Add index:

```ts
index("bank_transactions_organization_id_reconciled_at_idx").on(
  table.organizationId,
  table.reconciledAt,
),
```

---

## The Verification

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

Verify:

```sql
select column_name
from information_schema.columns
where table_name = 'bank_transactions'
order by ordinal_position;
```

You should see:

```txt
reconciled_at
reconciled_by_user_id
```

---

# 3. Create Reconciliation Service

## The Target

We are creating:

```txt
services/bank/reconcile-bank-transaction.ts
```

---

## The Concept

A transaction can be reconciled only if:

```txt
It belongs to the active organization.
It is posted.
It has a journal entry.
It is not already reconciled.
```

---

## The Implementation

Create:

```txt
services/bank/reconcile-bank-transaction.ts
```

Add:

```ts
// services/bank/reconcile-bank-transaction.ts

import { auth } from "@clerk/nextjs/server";
import { and, eq } from "drizzle-orm";
import { db } from "@/db";
import { bankTransactions } from "@/db/schema";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type ReconcileBankTransactionResult =
  | {
      ok: true;
    }
  | {
      ok: false;
      error: string;
    };

export async function reconcileBankTransactionForCurrentOrganization(
  bankTransactionId: string,
): Promise<ReconcileBankTransactionResult> {
  const organization = await requireCurrentDatabaseOrganization();
  const { userId } = await auth();

  if (!bankTransactionId.trim()) {
    return {
      ok: false,
      error: "Bank transaction ID is required.",
    };
  }

  const [transaction] = await db
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
    return {
      ok: false,
      error: "Bank transaction not found for active organization.",
    };
  }

  if (transaction.status === "reconciled") {
    return {
      ok: false,
      error: "Bank transaction is already reconciled.",
    };
  }

  if (transaction.status !== "posted") {
    return {
      ok: false,
      error: "Only posted bank transactions can be reconciled.",
    };
  }

  if (!transaction.journalEntryId) {
    return {
      ok: false,
      error: "Bank transaction must have a journal entry before reconciliation.",
    };
  }

  await db
    .update(bankTransactions)
    .set({
      status: "reconciled",
      reconciledAt: new Date(),
      reconciledByUserId: userId ?? null,
    })
    .where(eq(bankTransactions.id, transaction.id));

  return {
    ok: true,
  };
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 4. Add Reconciliation Server Action

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
import { reconcileBankTransactionForCurrentOrganization } from "@/services/bank/reconcile-bank-transaction";
```

Add action:

```ts
export async function reconcileBankTransactionAction(formData: FormData) {
  const result = await reconcileBankTransactionForCurrentOrganization(
    String(formData.get("bankTransactionId") ?? ""),
  );

  revalidatePath("/bank");
  revalidatePath("/bank/reconciliation");

  if (!result.ok) {
    redirect(`/bank?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect("/bank?status=reconciled");
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Update Bank Status Banner

## The Target

We are updating:

```txt
components/bank-import-status-banner.tsx
```

---

## The Implementation

Add branch:

```tsx
if (status === "reconciled") {
  return (
    <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
      <p className="text-sm font-semibold">
        Bank transaction reconciled successfully.
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

# 6. Update Bank Transaction Table with Reconcile Button

## The Target

We are updating:

```txt
components/bank-transaction-categorization-table.tsx
```

---

## The Implementation

Open the file and import:

```tsx
import { reconcileBankTransactionAction } from "@/app/bank/actions";
```

After the post button section, add:

```tsx
{transaction.status === "posted" ? (
  <form action={reconcileBankTransactionAction} className="mt-2">
    <input
      type="hidden"
      name="bankTransactionId"
      value={transaction.id}
    />

    <button
      type="submit"
      className="rounded-xl bg-sky-700 px-3 py-2 text-xs font-semibold text-white transition hover:bg-sky-800"
    >
      Mark reconciled
    </button>
  </form>
) : null}
```

---

## The Verification

Open:

```txt
/bank
```

A posted transaction should show:

```txt
Mark reconciled
```

---

# 7. Update Bank Diagnostics Service

## The Target

We are updating:

```txt
services/bank/bank-import-services.ts
```

to include reconciliation fields.

---

## The Implementation

In `recentTransactions` select, add:

```ts
reconciledAt: bankTransactions.reconciledAt,
reconciledByUserId: bankTransactions.reconciledByUserId,
```

Update the return type accordingly:

```ts
reconciledAt: Date | null;
reconciledByUserId: string | null;
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 8. Create Reconciliation Page

## The Target

We are creating:

```txt
app/bank/reconciliation/page.tsx
```

---

## The Concept

The reconciliation page summarizes:

```txt
Imported
Categorized
Posted
Reconciled
```

---

## The Implementation

Create:

```bash
mkdir -p app/bank/reconciliation
```

Create:

```txt
app/bank/reconciliation/page.tsx
```

Add:

```tsx
// app/bank/reconciliation/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { formatMoney } from "@/lib/money";
import { getCurrentOrganizationBankImportDiagnostics } from "@/services/bank/bank-import-services";

export const dynamic = "force-dynamic";

export default async function BankReconciliationPage() {
  const diagnostics = await getCurrentOrganizationBankImportDiagnostics();

  const imported = diagnostics.recentTransactions.filter(
    (transaction) => transaction.status === "imported",
  );

  const categorized = diagnostics.recentTransactions.filter(
    (transaction) => transaction.status === "categorized",
  );

  const posted = diagnostics.recentTransactions.filter(
    (transaction) => transaction.status === "posted",
  );

  const reconciled = diagnostics.recentTransactions.filter(
    (transaction) => transaction.status === "reconciled",
  );

  return (
    <AppLayout
      title="Bank Reconciliation"
      description="Review imported, posted, and reconciled bank transactions."
    >
      <div className="space-y-6">
        <section className="grid gap-4 md:grid-cols-4">
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold text-slate-500">Imported</p>
            <p className="mt-2 text-3xl font-bold text-slate-950">
              {imported.length}
            </p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold text-slate-500">Categorized</p>
            <p className="mt-2 text-3xl font-bold text-slate-950">
              {categorized.length}
            </p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold text-slate-500">Posted</p>
            <p className="mt-2 text-3xl font-bold text-slate-950">
              {posted.length}
            </p>
          </div>

          <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm">
            <p className="text-sm font-semibold text-emerald-700">
              Reconciled
            </p>
            <p className="mt-2 text-3xl font-bold text-emerald-950">
              {reconciled.length}
            </p>
          </div>
        </section>

        <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-3 border-b border-slate-200 bg-slate-50 px-6 py-4 sm:flex-row sm:items-center sm:justify-between">
            <h2 className="text-lg font-semibold text-slate-950">
              Recent bank transactions
            </h2>

            <Link
              href="/bank"
              className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white"
            >
              Back to bank import
            </Link>
          </div>

          {diagnostics.recentTransactions.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full border-collapse text-left text-sm">
                <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                  <tr>
                    <th className="px-6 py-3 font-semibold">Date</th>
                    <th className="px-6 py-3 font-semibold">Description</th>
                    <th className="px-6 py-3 font-semibold">Status</th>
                    <th className="px-6 py-3 font-semibold">Reconciled at</th>
                    <th className="px-6 py-3 text-right font-semibold">
                      Amount
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-200">
                  {diagnostics.recentTransactions.map((transaction) => (
                    <tr key={transaction.id}>
                      <td className="px-6 py-4 text-slate-600">
                        {transaction.transactionDate}
                      </td>

                      <td className="px-6 py-4 font-medium text-slate-950">
                        {transaction.description}
                      </td>

                      <td className="px-6 py-4">
                        <span className="rounded-full bg-sky-50 px-2 py-1 text-xs font-semibold text-sky-700">
                          {transaction.status}
                        </span>
                      </td>

                      <td className="px-6 py-4 text-slate-600">
                        {transaction.reconciledAt
                          ? transaction.reconciledAt.toISOString()
                          : "—"}
                      </td>

                      <td className="px-6 py-4 text-right font-semibold text-slate-950">
                        {formatMoney(transaction.amountCents)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="p-8 text-center text-sm text-slate-500">
              No bank transactions imported yet.
            </div>
          )}
        </section>
      </div>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
/bank/reconciliation
```

You should see reconciliation summary counts.

---

# 9. Link Reconciliation from Bank Page

## The Target

We are updating:

```txt
app/bank/page.tsx
```

---

## The Implementation

Add import:

```tsx
import Link from "next/link";
```

In the top upload section or near summary cards, add:

```tsx
<Link
  href="/bank/reconciliation"
  className="inline-flex rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
>
  View reconciliation
</Link>
```

---

## The Verification

Open:

```txt
/bank
```

Click:

```txt
View reconciliation
```

---

# 10. Reconcile a Posted Bank Transaction

## The Target

We are testing reconciliation.

---

## The Implementation

Open:

```txt
/bank
```

Find a posted bank transaction.

Click:

```txt
Mark reconciled
```

---

## The Verification

You should see:

```txt
Bank transaction reconciled successfully.
```

The row should show:

```txt
reconciled
```

Open:

```txt
/bank/reconciliation
```

The reconciled count should increase.

---

# 11. Verify in Neon SQL

## The Target

We are checking reconciliation fields directly.

---

## The Implementation

Run:

```sql
select
  transaction_date,
  description,
  amount_cents,
  status,
  reconciled_at,
  reconciled_by_user_id
from bank_transactions
order by created_at desc;
```

---

## The Verification

Reconciled transactions should show:

```txt
status = reconciled
reconciled_at not null
```

---

# 12. Run Full Project Check

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

# 13. Commit Bank Reconciliation

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Build bank reconciliation system"
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

## Error: Reconciliation columns do not exist

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Only posted transactions can be reconciled

Categorize and post the transaction first.

---

## Error: Already reconciled

Reconciled transactions are locked.

---

# Phase 10 Reference — Reconciliation

## Posted

The imported bank transaction has a journal entry.

---

## Reconciled

The posted transaction has been confirmed against the bank statement.

---

## Why Lock Reconciled Transactions?

Reconciliation is a control point.

Once confirmed, changes should be restricted.

---

# Part 35 Completion Checklist

You are ready for Part 36 if:

- [ ] Bank transactions have reconciliation fields
- [ ] Reconciliation migration applied
- [ ] Reconciliation service exists
- [ ] Only posted transactions can be reconciled
- [ ] `/bank` shows reconcile button for posted rows
- [ ] `/bank/reconciliation` exists
- [ ] Reconciled transactions show status `reconciled`
- [ ] Neon SQL confirms reconciliation fields
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
