# Part 33 — Review and Categorize Imported Transactions

In Part 32, we uploaded and parsed bank CSV files.

Now we will review and categorize imported bank transactions.

By the end of this part, you will have:

- Category account fields on imported bank transactions
- Notes field for categorization
- Categorization service
- Server action for categorizing transactions
- Categorization form in the Bank page
- Imported transaction status updates
- Tenant-safe categorization
- Neon SQL verification

We still will **not post imported transactions to the ledger yet**.

That comes in Part 34.

This part prepares imported transactions for posting.

---

# 1. Understand Bank Categorization

## The Target

We are assigning an accounting account to each imported bank transaction.

---

## The Concept

A bank transaction tells us money moved.

It does not automatically tell us why.

Example:

```txt
2026-01-06, Cloud Hosting SG, -109.00
```

This probably means:

```txt
Cloud hosting expense
```

So we categorize it to an account like:

```txt
6300 Software and Subscriptions
```

Another example:

```txt
2026-01-05, Customer payment from Merlion Trading, 109.00
```

This might be categorized as:

```txt
1100 Accounts Receivable
```

or matched to an existing invoice payment later.

For this tutorial step, we assign a category account.

---

# 2. Update Bank Transaction Schema

## The Target

We are updating:

```txt
bank_transactions
```

with categorization fields.

---

## The Concept

Each imported transaction can have:

```txt
category_account_id
categorization_notes
```

The category account tells the app what account should be used when posting.

---

## The Implementation

Open:

```txt
db/schema.ts
```

In `bankTransactions`, add:

```ts
categoryAccountId: uuid("category_account_id").references(() => accounts.id, {
  onDelete: "set null",
}),

categorizationNotes: text("categorization_notes"),
```

Add an index:

```ts
index("bank_transactions_organization_id_category_account_id_idx").on(
  table.organizationId,
  table.categoryAccountId,
),
```

---

## The Verification

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

Verify columns:

```sql
select column_name
from information_schema.columns
where table_name = 'bank_transactions'
order by ordinal_position;
```

You should see:

```txt
category_account_id
categorization_notes
```

---

# 3. Update Bank Import Diagnostics Service

## The Target

We are updating:

```txt
services/bank/bank-import-services.ts
```

to include categorization fields.

---

## The Implementation

Open:

```txt
services/bank/bank-import-services.ts
```

Find the `recentTransactions` select.

Replace it with:

```ts
const recentTransactions = await db
  .select({
    id: bankTransactions.id,
    transactionDate: bankTransactions.transactionDate,
    description: bankTransactions.description,
    amountCents: bankTransactions.amountCents,
    status: bankTransactions.status,
    categoryAccountId: bankTransactions.categoryAccountId,
    categorizationNotes: bankTransactions.categorizationNotes,
  })
  .from(bankTransactions)
  .where(eq(bankTransactions.organizationId, organization.id))
  .orderBy(desc(bankTransactions.createdAt))
  .limit(20);
```

Update the return type for `recentTransactions` to include:

```ts
categoryAccountId: string | null;
categorizationNotes: string | null;
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 4. Create Bank Categorization Service

## The Target

We are creating:

```txt
services/bank/categorize-bank-transaction.ts
```

---

## The Concept

Categorization must be tenant-safe.

We must verify:

```txt
The transaction belongs to the active organization.
The selected account belongs to the active organization.
The account is active.
The transaction has not already been posted.
```

---

## The Implementation

Create:

```txt
services/bank/categorize-bank-transaction.ts
```

Add:

```ts
// services/bank/categorize-bank-transaction.ts

import { and, eq } from "drizzle-orm";
import { db } from "@/db";
import { accounts, bankTransactions } from "@/db/schema";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type CategorizeBankTransactionResult =
  | {
      ok: true;
    }
  | {
      ok: false;
      error: string;
    };

function normalizeOptionalText(value?: string | null): string | null {
  const normalized = value?.trim() ?? "";
  return normalized.length > 0 ? normalized : null;
}

export async function categorizeBankTransactionForCurrentOrganization(params: {
  bankTransactionId: string;
  categoryAccountId: string;
  notes?: string | null;
}): Promise<CategorizeBankTransactionResult> {
  const organization = await requireCurrentDatabaseOrganization();

  if (!params.bankTransactionId.trim()) {
    return {
      ok: false,
      error: "Bank transaction ID is required.",
    };
  }

  if (!params.categoryAccountId.trim()) {
    return {
      ok: false,
      error: "Category account is required.",
    };
  }

  const [transaction] = await db
    .select()
    .from(bankTransactions)
    .where(
      and(
        eq(bankTransactions.id, params.bankTransactionId.trim()),
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

  if (transaction.status === "posted" || transaction.status === "reconciled") {
    return {
      ok: false,
      error: "Posted or reconciled transactions cannot be recategorized.",
    };
  }

  const [account] = await db
    .select()
    .from(accounts)
    .where(
      and(
        eq(accounts.id, params.categoryAccountId.trim()),
        eq(accounts.organizationId, organization.id),
      ),
    )
    .limit(1);

  if (!account) {
    return {
      ok: false,
      error: "Category account not found for active organization.",
    };
  }

  if (!account.isActive) {
    return {
      ok: false,
      error: "Category account is inactive.",
    };
  }

  await db
    .update(bankTransactions)
    .set({
      categoryAccountId: account.id,
      categorizationNotes: normalizeOptionalText(params.notes),
      status: "categorized",
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

# 5. Create Categorization Server Action

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

Add import:

```ts
import { categorizeBankTransactionForCurrentOrganization } from "@/services/bank/categorize-bank-transaction";
```

Add this action:

```ts
export async function categorizeBankTransactionAction(formData: FormData) {
  const result = await categorizeBankTransactionForCurrentOrganization({
    bankTransactionId: String(formData.get("bankTransactionId") ?? ""),
    categoryAccountId: String(formData.get("categoryAccountId") ?? ""),
    notes: String(formData.get("notes") ?? ""),
  });

  revalidatePath("/bank");

  if (!result.ok) {
    redirect(`/bank?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect("/bank?status=categorized");
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 6. Update Bank Status Banner

## The Target

We are updating:

```txt
components/bank-import-status-banner.tsx
```

---

## The Implementation

Open:

```txt
components/bank-import-status-banner.tsx
```

Add this branch before the error branch:

```tsx
if (status === "categorized") {
  return (
    <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
      <p className="text-sm font-semibold">
        Bank transaction categorized successfully.
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

# 7. Create Bank Transaction Categorization Component

## The Target

We are creating:

```txt
components/bank-transaction-categorization-table.tsx
```

---

## The Concept

Each imported transaction will show:

```txt
Date
Description
Amount
Status
Category form
```

The category form lets the user choose an active account.

---

## The Implementation

Create:

```txt
components/bank-transaction-categorization-table.tsx
```

Add:

```tsx
// components/bank-transaction-categorization-table.tsx

import type { Account } from "@/db/schema";
import { categorizeBankTransactionAction } from "@/app/bank/actions";
import { formatMoney } from "@/lib/money";

type BankTransactionRow = {
  id: string;
  transactionDate: string;
  description: string;
  amountCents: number;
  status: string;
  categoryAccountId: string | null;
  categorizationNotes: string | null;
};

type BankTransactionCategorizationTableProps = {
  transactions: BankTransactionRow[];
  accounts: Account[];
};

export function BankTransactionCategorizationTable({
  transactions,
  accounts,
}: BankTransactionCategorizationTableProps) {
  if (transactions.length === 0) {
    return (
      <section className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
        <h2 className="text-lg font-semibold text-slate-950">
          No bank transactions imported yet
        </h2>

        <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
          Upload a CSV file to begin bank import and reconciliation workflows.
        </p>
      </section>
    );
  }

  const activeAccounts = accounts.filter((account) => account.isActive);

  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
        <h2 className="text-lg font-semibold text-slate-950">
          Review imported transactions
        </h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[1100px] border-collapse text-left text-sm">
          <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
            <tr>
              <th className="px-6 py-3 font-semibold">Date</th>
              <th className="px-6 py-3 font-semibold">Description</th>
              <th className="px-6 py-3 text-right font-semibold">Amount</th>
              <th className="px-6 py-3 font-semibold">Status</th>
              <th className="px-6 py-3 font-semibold">Categorize</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-slate-200">
            {transactions.map((transaction) => {
              const isLocked =
                transaction.status === "posted" ||
                transaction.status === "reconciled";

              return (
                <tr key={transaction.id}>
                  <td className="px-6 py-4 text-slate-600">
                    {transaction.transactionDate}
                  </td>

                  <td className="px-6 py-4 font-medium text-slate-950">
                    {transaction.description}
                  </td>

                  <td className="px-6 py-4 text-right font-semibold text-slate-950">
                    {formatMoney(transaction.amountCents)}
                  </td>

                  <td className="px-6 py-4">
                    <span className="rounded-full bg-sky-50 px-2 py-1 text-xs font-semibold text-sky-700">
                      {transaction.status}
                    </span>
                  </td>

                  <td className="px-6 py-4">
                    {isLocked ? (
                      <span className="text-sm text-slate-500">
                        Locked after posting
                      </span>
                    ) : (
                      <form
                        action={categorizeBankTransactionAction}
                        className="grid gap-2"
                      >
                        <input
                          type="hidden"
                          name="bankTransactionId"
                          value={transaction.id}
                        />

                        <select
                          name="categoryAccountId"
                          required
                          defaultValue={transaction.categoryAccountId ?? ""}
                          className="rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950"
                        >
                          <option value="" disabled>
                            Select account
                          </option>

                          {activeAccounts.map((account) => (
                            <option key={account.id} value={account.id}>
                              {account.code} {account.name}
                            </option>
                          ))}
                        </select>

                        <input
                          name="notes"
                          placeholder="Optional notes"
                          defaultValue={transaction.categorizationNotes ?? ""}
                          className="rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950"
                        />

                        <button
                          type="submit"
                          className="w-fit rounded-xl bg-slate-950 px-3 py-2 text-xs font-semibold text-white transition hover:bg-slate-800"
                        >
                          Save category
                        </button>
                      </form>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
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

# 8. Update Bank Page

## The Target

We are updating:

```txt
app/bank/page.tsx
```

to use the categorization table and load accounts.

---

## The Implementation

Open:

```txt
app/bank/page.tsx
```

Add import:

```tsx
import { BankTransactionCategorizationTable } from "@/components/bank-transaction-categorization-table";
import { listCurrentOrganizationAccounts } from "@/services/accounts/get-accounts";
```

Inside the page function, add:

```ts
const { accounts } = await listCurrentOrganizationAccounts();
```

Replace the old recent transactions table section with:

```tsx
<BankTransactionCategorizationTable
  transactions={diagnostics.recentTransactions}
  accounts={accounts}
/>
```

Keep the upload form and summary cards.

---

## The Verification

Open:

```txt
/bank
```

Imported transactions should now show a category form.

Choose an account and save.

You should see:

```txt
Bank transaction categorized successfully.
```

The transaction status should become:

```txt
categorized
```

---

# 9. Verify in Neon SQL

## The Target

We are checking categorization data directly.

---

## The Implementation

Run:

```sql
select
  bt.transaction_date,
  bt.description,
  bt.amount_cents,
  bt.status,
  a.code,
  a.name,
  bt.categorization_notes
from bank_transactions bt
left join accounts a
  on a.id = bt.category_account_id
order by bt.created_at desc;
```

---

## The Verification

Categorized rows should show:

```txt
status = categorized
category account code/name
```

---

# 10. Run Full Project Check

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

# 11. Commit Bank Categorization

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Review and categorize bank transactions"
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

## Error: Categorization columns do not exist

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: No accounts in dropdown

Open:

```txt
/accounts
```

Seed default accounts.

---

## Error: Transaction cannot be recategorized

Posted or reconciled transactions are locked.

This is intentional.

---

# Phase 10 Reference — Bank Categorization

## Imported

Raw bank row imported from CSV.

---

## Categorized

A bank transaction has been assigned an account.

---

## Posted

A categorized transaction has been posted to the ledger.

---

## Reconciled

A posted transaction has been matched/confirmed against the bank statement.

---

# Part 33 Completion Checklist

You are ready for Part 34 if:

- [ ] `bank_transactions.category_account_id` exists
- [ ] `bank_transactions.categorization_notes` exists
- [ ] Categorization service exists
- [ ] Categorization validates transaction ownership
- [ ] Categorization validates account ownership
- [ ] `/bank` shows category forms
- [ ] Saving category updates status to `categorized`
- [ ] Posted/reconciled rows cannot be recategorized
- [ ] Neon SQL confirms category account links
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
