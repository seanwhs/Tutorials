# Part 10 — Seed a Singapore-Friendly Chart of Accounts

In Part 9, we created the database structure for the chart of accounts:

```txt
accounts
```

But the table is still empty.

In this part, we will seed each active company workspace with a practical, Singapore-friendly starter chart of accounts.

By the end of this part, you will have:

- A reusable default chart of accounts seed list
- A safe, idempotent seeding service
- A server action for seeding the active organization
- A real `/accounts` page that lists accounts from the database
- A “Seed default accounts” button
- Account grouping by type
- Database verification through Neon SQL and the app UI
- No duplicate accounts when the seed runs multiple times

The word **idempotent** is important.

It means:

> Running the same operation multiple times produces the same final result.

For example, if you click “Seed default accounts” twice, the app should not create duplicate `1000 Bank` accounts.

---

# 1. Understand What We Are Seeding

## The Target

We are creating a starter chart of accounts for each organization.

---

## The Concept

A chart of accounts is like the filing cabinet for financial activity.

Before a business can record invoices, bills, payments, or journal entries, it needs drawers such as:

```txt
Bank
Accounts Receivable
Accounts Payable
GST Payable
Sales Revenue
Rent Expense
CPF Employer Contributions
```

Because GreyMatter Ledger is Singapore-ready, our starter accounts should include practical Singapore business concepts such as:

- GST output tax
- GST input tax
- CPF employer contributions
- Corporate income tax expense
- Professional fees
- Software subscriptions
- Bank charges

This is not a full replacement for accountant-specific customization, but it gives small businesses a useful starting point.

---

## The Implementation

We will seed accounts like:

```txt
1000 Bank
1100 Accounts Receivable
1400 GST Input Tax
2000 Accounts Payable
2100 GST Payable
2110 GST Output Tax
3000 Share Capital
4000 Sales Revenue
6000 Rent Expense
6200 CPF Employer Contributions
7000 Income Tax Expense
```

Each account will belong to the currently active database organization:

```txt
accounts.organization_id = organizations.id
```

That keeps each company’s chart of accounts isolated.

---

## The Verification

After seeding, this query should return rows for your active company:

```sql
select code, name, type
from accounts
order by code;
```

And the app page:

```txt
/accounts
```

should show grouped accounts.

---

# 2. Create the Default Chart of Accounts Seed List

## The Target

We are creating:

```txt
lib/accounting/default-chart-of-accounts.ts
```

This file contains the default account list.

---

## The Concept

Seed data should live in a clear, reviewable place.

We do not want default accounts scattered through a page component or hidden inside a button.

Think of this file as the official starter filing cabinet label list.

The seed service will read this list and insert the accounts into the database.

---

## The Implementation

Create:

```txt
lib/accounting/default-chart-of-accounts.ts
```

Add:

```ts
// lib/accounting/default-chart-of-accounts.ts

import type { AccountType } from "@/lib/accounting/types";

/**
 * A default account definition used when seeding a new organization's chart of
 * accounts.
 *
 * These are not database rows yet. They become database rows when the seed
 * service inserts them into the accounts table for a specific organization.
 */
export type DefaultChartAccount = {
  code: string;
  name: string;
  type: AccountType;
  description: string;
};

/**
 * Singapore-friendly starter chart of accounts.
 *
 * This is intentionally practical rather than exhaustive.
 *
 * Account code ranges:
 * - 1000–1999 Assets
 * - 2000–2999 Liabilities
 * - 3000–3999 Equity
 * - 4000–4999 Income
 * - 5000–5999 Cost of sales
 * - 6000–7999 Expenses
 */
export const defaultChartOfAccounts: DefaultChartAccount[] = [
  {
    code: "1000",
    name: "Bank",
    type: "asset",
    description:
      "Primary operating bank account used for receipts and payments.",
  },
  {
    code: "1010",
    name: "Cash on Hand",
    type: "asset",
    description:
      "Physical cash held by the business, such as petty cash.",
  },
  {
    code: "1100",
    name: "Accounts Receivable",
    type: "asset",
    description:
      "Amounts owed by customers for invoices issued but not yet paid.",
  },
  {
    code: "1200",
    name: "Inventory",
    type: "asset",
    description:
      "Goods held for resale or production, if the business tracks inventory.",
  },
  {
    code: "1300",
    name: "Prepayments",
    type: "asset",
    description:
      "Expenses paid in advance, such as prepaid insurance or rent.",
  },
  {
    code: "1400",
    name: "GST Input Tax",
    type: "asset",
    description:
      "GST paid on purchases that may be claimable from IRAS, subject to GST rules.",
  },
  {
    code: "1500",
    name: "Deposits Paid",
    type: "asset",
    description:
      "Refundable deposits paid to suppliers, landlords, or service providers.",
  },
  {
    code: "1600",
    name: "Fixed Assets",
    type: "asset",
    description:
      "Long-term assets such as equipment, computers, or furniture.",
  },

  {
    code: "2000",
    name: "Accounts Payable",
    type: "liability",
    description:
      "Amounts owed to vendors for bills received but not yet paid.",
  },
  {
    code: "2100",
    name: "GST Payable",
    type: "liability",
    description:
      "Net GST amount payable to IRAS after offsetting output tax and input tax.",
  },
  {
    code: "2110",
    name: "GST Output Tax",
    type: "liability",
    description:
      "GST collected from customers on taxable sales.",
  },
  {
    code: "2200",
    name: "Accrued Expenses",
    type: "liability",
    description:
      "Expenses incurred but not yet billed or paid.",
  },
  {
    code: "2300",
    name: "Loans Payable",
    type: "liability",
    description:
      "Amounts owed to banks, directors, shareholders, or other lenders.",
  },
  {
    code: "2400",
    name: "Customer Deposits",
    type: "liability",
    description:
      "Customer payments received before goods or services are delivered.",
  },

  {
    code: "3000",
    name: "Share Capital",
    type: "equity",
    description:
      "Capital contributed by shareholders or owners.",
  },
  {
    code: "3100",
    name: "Retained Earnings",
    type: "equity",
    description:
      "Accumulated profits retained in the business from prior periods.",
  },
  {
    code: "3200",
    name: "Current Year Earnings",
    type: "equity",
    description:
      "Current year profit or loss before closing to retained earnings.",
  },

  {
    code: "4000",
    name: "Sales Revenue",
    type: "income",
    description:
      "Revenue from selling goods or services to customers.",
  },
  {
    code: "4100",
    name: "Service Revenue",
    type: "income",
    description:
      "Revenue from professional services, consulting, support, or project work.",
  },
  {
    code: "4200",
    name: "Other Income",
    type: "income",
    description:
      "Other business income, such as interest income or miscellaneous receipts.",
  },

  {
    code: "5000",
    name: "Cost of Goods Sold",
    type: "expense",
    description:
      "Direct costs of goods sold or services delivered.",
  },
  {
    code: "5100",
    name: "Purchases",
    type: "expense",
    description:
      "Purchases of goods or materials used in business operations.",
  },

  {
    code: "6000",
    name: "Rent Expense",
    type: "expense",
    description:
      "Office, shop, warehouse, or coworking rental costs.",
  },
  {
    code: "6100",
    name: "Salaries and Wages",
    type: "expense",
    description:
      "Employee salary and wage expenses before employer CPF contributions.",
  },
  {
    code: "6200",
    name: "CPF Employer Contributions",
    type: "expense",
    description:
      "Employer CPF contributions for Singapore employees.",
  },
  {
    code: "6300",
    name: "Software and Subscriptions",
    type: "expense",
    description:
      "Cloud software, SaaS tools, hosting, domains, and subscription services.",
  },
  {
    code: "6400",
    name: "Professional Fees",
    type: "expense",
    description:
      "Accounting, legal, corporate secretarial, consulting, and advisory fees.",
  },
  {
    code: "6500",
    name: "Marketing Expense",
    type: "expense",
    description:
      "Advertising, design, campaigns, sponsorships, and promotion costs.",
  },
  {
    code: "6600",
    name: "Transport and Travel",
    type: "expense",
    description:
      "Business travel, transport, parking, taxi, ride-hailing, and delivery costs.",
  },
  {
    code: "6700",
    name: "Bank Charges",
    type: "expense",
    description:
      "Bank fees, payment gateway fees, card processing fees, and transfer charges.",
  },
  {
    code: "6800",
    name: "Depreciation Expense",
    type: "expense",
    description:
      "Periodic depreciation expense for fixed assets.",
  },
  {
    code: "6900",
    name: "Other Expenses",
    type: "expense",
    description:
      "General expenses that do not fit another specific category.",
  },
  {
    code: "7000",
    name: "Income Tax Expense",
    type: "expense",
    description:
      "Estimated or actual corporate income tax expense.",
  },
];

/**
 * Convenience count used by diagnostics and tests.
 */
export const defaultChartOfAccountsCount = defaultChartOfAccounts.length;
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

No browser change yet.

---

# 3. Create the Seeding Service

## The Target

We are creating:

```txt
services/accounts/seed-default-chart-of-accounts.ts
```

This service inserts the default accounts for the active organization.

---

## The Concept

Seeding should be safe to run multiple times.

The database already enforces this rule:

```txt
organization_id + code must be unique
```

So our service will use an **upsert**.

An upsert means:

```txt
Insert this row.
But if a matching row already exists, update it instead of failing.
```

A simple analogy:

> Put a labeled folder in the filing cabinet. If the folder already exists, refresh the label instead of creating a duplicate folder.

---

## The Implementation

Create:

```txt
services/accounts/seed-default-chart-of-accounts.ts
```

Add:

```ts
// services/accounts/seed-default-chart-of-accounts.ts

import { count, eq } from "drizzle-orm";
import { db } from "@/db";
import { accounts } from "@/db/schema";
import {
  defaultChartOfAccounts,
  defaultChartOfAccountsCount,
} from "@/lib/accounting/default-chart-of-accounts";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type SeedChartOfAccountsResult = {
  organizationId: string;
  attemptedSeedCount: number;
  accountCountAfterSeed: number;
};

/**
 * Seeds the default chart of accounts for a specific database organization.
 *
 * This function is idempotent:
 * - First run inserts accounts.
 * - Later runs update existing seeded account labels/descriptions.
 * - It does not create duplicate account codes because the database has a
 *   unique index on organization_id + code.
 */
export async function seedDefaultChartOfAccountsForOrganization(
  organizationId: string,
): Promise<SeedChartOfAccountsResult> {
  const now = new Date();

  for (const seedAccount of defaultChartOfAccounts) {
    await db
      .insert(accounts)
      .values({
        organizationId,
        code: seedAccount.code,
        name: seedAccount.name,
        type: seedAccount.type,
        description: seedAccount.description,
        isSystem: true,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      })
      .onConflictDoUpdate({
        target: [accounts.organizationId, accounts.code],
        set: {
          name: seedAccount.name,
          type: seedAccount.type,
          description: seedAccount.description,
          isSystem: true,
          updatedAt: now,
        },
      });
  }

  const [accountCountRow] = await db
    .select({ value: count() })
    .from(accounts)
    .where(eq(accounts.organizationId, organizationId));

  return {
    organizationId,
    attemptedSeedCount: defaultChartOfAccountsCount,
    accountCountAfterSeed: accountCountRow?.value ?? 0,
  };
}

/**
 * Seeds the default chart of accounts for the currently active organization.
 *
 * Server actions and setup pages should usually call this helper rather than
 * passing organization IDs around manually.
 */
export async function seedDefaultChartOfAccountsForCurrentOrganization(): Promise<SeedChartOfAccountsResult> {
  const organization = await requireCurrentDatabaseOrganization();

  return seedDefaultChartOfAccountsForOrganization(organization.id);
}
```

Important part:

```ts
.onConflictDoUpdate({
  target: [accounts.organizationId, accounts.code],
  set: {
    ...
  },
});
```

This tells Postgres:

> If this organization already has account code `1000`, update that row instead of inserting a duplicate.

Notice that we do **not** update `isActive` during conflict.

That is intentional.

If a future user deactivates an account, rerunning the seed should not automatically reactivate it.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

---

# 4. Create the Server Action for Seeding

## The Target

We are creating:

```txt
app/accounts/actions.ts
```

This server action will let the `/accounts` page seed the current organization.

---

## The Concept

A **Server Action** is a server-side function that can be called from a form.

For this feature, the user clicks a button:

```txt
Seed default accounts
```

The browser submits a form.

Next.js runs the server action.

The server action inserts accounts into Postgres.

Then the page refreshes with the new accounts.

Think of a server action like a secure office clerk behind the counter. The button asks for work to be done, but the actual database changes happen safely on the server.

---

## The Implementation

Create:

```txt
app/accounts/actions.ts
```

Add:

```ts
// app/accounts/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { seedDefaultChartOfAccountsForCurrentOrganization } from "@/services/accounts/seed-default-chart-of-accounts";

/**
 * Seeds the default chart of accounts for the active organization.
 *
 * This action is called by a form on the /accounts page.
 */
export async function seedDefaultChartOfAccountsAction() {
  await seedDefaultChartOfAccountsForCurrentOrganization();

  /**
   * Revalidate pages that display account or database health information.
   */
  revalidatePath("/accounts");
  revalidatePath("/settings/database");
  revalidatePath("/settings/database/accounts");

  /**
   * Redirect back to the accounts page after the mutation.
   *
   * The URL flag is only for simple user feedback.
   */
  redirect("/accounts?seeded=1");
}
```

Important:

```ts
"use server";
```

This marks the file’s exported functions as server actions.

Important:

```ts
revalidatePath("/accounts");
```

This tells Next.js to refresh cached server-rendered content for that route.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

The action is not visible yet. We will wire it into the accounts page next.

---

# 5. Improve Account Query Services

## The Target

We are updating:

```txt
services/accounts/get-accounts.ts
```

to include account grouping helpers.

---

## The Concept

A raw account list is useful, but users usually think in groups:

```txt
Assets
Liabilities
Equity
Income
Expenses
```

So we will add a helper that groups accounts by type.

This is like sorting folders into cabinet drawers.

---

## The Implementation

Open:

```txt
services/accounts/get-accounts.ts
```

Replace the entire file with:

```ts
// services/accounts/get-accounts.ts

import { asc, count, eq } from "drizzle-orm";
import { db } from "@/db";
import { accounts, type Account } from "@/db/schema";
import type { AccountType } from "@/lib/accounting/types";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

export type AccountListResult = {
  organizationId: string | null;
  accounts: Account[];
};

export type GroupedAccounts = Record<AccountType, Account[]>;

export const accountTypeDisplayOrder: AccountType[] = [
  "asset",
  "liability",
  "equity",
  "income",
  "expense",
];

export const accountTypeLabels: Record<AccountType, string> = {
  asset: "Assets",
  liability: "Liabilities",
  equity: "Equity",
  income: "Income",
  expense: "Expenses",
};

/**
 * Lists accounts for the currently active database organization.
 *
 * If no organization is selected, we return an empty list instead of throwing.
 * This makes diagnostic and empty-state pages easier to render.
 */
export async function listCurrentOrganizationAccounts(): Promise<AccountListResult> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return {
      organizationId: null,
      accounts: [],
    };
  }

  const organizationAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.organizationId, organization.id))
    .orderBy(asc(accounts.code));

  return {
    organizationId: organization.id,
    accounts: organizationAccounts,
  };
}

/**
 * Counts accounts for the currently active database organization.
 *
 * This is useful for dashboards and diagnostics.
 */
export async function countCurrentOrganizationAccounts(): Promise<{
  organizationId: string | null;
  accountCount: number;
}> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return {
      organizationId: null,
      accountCount: 0,
    };
  }

  const [row] = await db
    .select({ value: count() })
    .from(accounts)
    .where(eq(accounts.organizationId, organization.id));

  return {
    organizationId: organization.id,
    accountCount: row?.value ?? 0,
  };
}

/**
 * Groups accounts by account type.
 */
export function groupAccountsByType(accountRows: Account[]): GroupedAccounts {
  const grouped: GroupedAccounts = {
    asset: [],
    liability: [],
    equity: [],
    income: [],
    expense: [],
  };

  for (const account of accountRows) {
    grouped[account.type].push(account);
  }

  return grouped;
}
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

---

# 6. Build a Real Chart of Accounts Page

## The Target

We are updating:

```txt
app/accounts/page.tsx
```

This page will now:

- Query real accounts from the database
- Show a seed button when accounts are missing
- Group seeded accounts by type
- Show account code, name, description, and status

---

## The Concept

This is our first real accounting data page.

The page is still simple, but it now reads from Postgres and respects the active organization.

The flow is:

```txt
User opens /accounts
  |
  v
Server reads active organization
  |
  v
Server queries accounts for that organization
  |
  |-- no accounts -> show seed button
  |
  |-- accounts exist -> show grouped chart of accounts
```

---

## The Implementation

Open:

```txt
app/accounts/page.tsx
```

Replace the entire file with:

```tsx
// app/accounts/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { EmptyState } from "@/components/empty-state";
import {
  accountTypeDisplayOrder,
  accountTypeLabels,
  groupAccountsByType,
  listCurrentOrganizationAccounts,
} from "@/services/accounts/get-accounts";
import { seedDefaultChartOfAccountsAction } from "@/app/accounts/actions";

export const dynamic = "force-dynamic";

type AccountsPageProps = {
  searchParams?: Promise<{
    seeded?: string;
  }>;
};

export default async function AccountsPage({
  searchParams,
}: AccountsPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const seeded = resolvedSearchParams.seeded === "1";

  const { organizationId, accounts } = await listCurrentOrganizationAccounts();
  const groupedAccounts = groupAccountsByType(accounts);
  const hasAccounts = accounts.length > 0;

  return (
    <AppLayout
      title="Chart of Accounts"
      description="The chart of accounts is the master list of categories used to classify every financial transaction."
    >
      <div className="space-y-6">
        {seeded ? (
          <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5">
            <p className="text-sm font-semibold text-emerald-800">
              Default chart of accounts seeded successfully.
            </p>

            <p className="mt-2 text-sm leading-6 text-emerald-700">
              Your active organization now has starter accounts for assets,
              liabilities, equity, income, expenses, GST, receivables, payables,
              CPF, and common Singapore business costs.
            </p>
          </section>
        ) : null}

        {!organizationId ? (
          <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6">
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-amber-700">
              Company required
            </p>

            <h2 className="mt-3 text-lg font-semibold text-slate-950">
              Create or select a company workspace first
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-amber-800">
              Accounts belong to a company organization. Create or select an
              organization before seeding the chart of accounts.
            </p>

            <Link
              href="/onboarding/organization"
              className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-amber-700"
            >
              Create company workspace
            </Link>
          </section>
        ) : null}

        {organizationId && !hasAccounts ? (
          <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
              Ready to seed
            </p>

            <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
              Seed a Singapore-friendly chart of accounts
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
              This organization has no accounts yet. Seed default accounts for
              bank, receivables, payables, GST, income, expenses, CPF employer
              contributions, software subscriptions, bank charges, and income
              tax expense.
            </p>

            <form action={seedDefaultChartOfAccountsAction} className="mt-5">
              <button
                type="submit"
                className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
              >
                Seed default accounts
              </button>
            </form>
          </section>
        ) : null}

        {organizationId && hasAccounts ? (
          <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
              <div>
                <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
                  Active chart of accounts
                </p>

                <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
                  {accounts.length} accounts available
                </h2>

                <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
                  These accounts are scoped to the active database organization.
                  Future invoices, bills, payments, and journal entries will
                  post into these accounts.
                </p>
              </div>

              <div className="flex flex-wrap gap-2">
                <form action={seedDefaultChartOfAccountsAction}>
                  <button
                    type="submit"
                    className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
                  >
                    Re-run seed safely
                  </button>
                </form>

                <Link
                  href="/settings/database/accounts"
                  className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
                >
                  Database diagnostic
                </Link>
              </div>
            </div>
          </section>
        ) : null}

        {organizationId && hasAccounts ? (
          <section className="space-y-6">
            {accountTypeDisplayOrder.map((accountType) => {
              const accountsForType = groupedAccounts[accountType];

              if (accountsForType.length === 0) {
                return null;
              }

              return (
                <article
                  key={accountType}
                  className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"
                >
                  <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
                    <h2 className="text-lg font-semibold text-slate-950">
                      {accountTypeLabels[accountType]}
                    </h2>

                    <p className="mt-1 text-sm text-slate-500">
                      {accountsForType.length} account
                      {accountsForType.length === 1 ? "" : "s"}
                    </p>
                  </div>

                  <div className="overflow-x-auto">
                    <table className="w-full border-collapse text-left text-sm">
                      <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                        <tr>
                          <th className="px-6 py-3 font-semibold">Code</th>
                          <th className="px-6 py-3 font-semibold">Name</th>
                          <th className="px-6 py-3 font-semibold">
                            Description
                          </th>
                          <th className="px-6 py-3 font-semibold">System</th>
                          <th className="px-6 py-3 font-semibold">Status</th>
                        </tr>
                      </thead>

                      <tbody className="divide-y divide-slate-200">
                        {accountsForType.map((account) => (
                          <tr key={account.id}>
                            <td className="px-6 py-4 font-mono text-xs font-semibold text-slate-700">
                              {account.code}
                            </td>

                            <td className="px-6 py-4 font-semibold text-slate-950">
                              {account.name}
                            </td>

                            <td className="max-w-xl px-6 py-4 text-slate-500">
                              {account.description ?? "No description"}
                            </td>

                            <td className="px-6 py-4">
                              {account.isSystem ? (
                                <span className="rounded-full bg-sky-50 px-2 py-1 text-xs font-semibold text-sky-700">
                                  System
                                </span>
                              ) : (
                                <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-600">
                                  Custom
                                </span>
                              )}
                            </td>

                            <td className="px-6 py-4">
                              {account.isActive ? (
                                <span className="rounded-full bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700">
                                  Active
                                </span>
                              ) : (
                                <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-600">
                                  Inactive
                                </span>
                              )}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </article>
              );
            })}
          </section>
        ) : null}

        {organizationId && !hasAccounts ? (
          <EmptyState
            title="No chart of accounts yet"
            description="Use the seed button above to create the default Singapore-friendly account list for this company workspace."
          />
        ) : null}
      </div>
    </AppLayout>
  );
}
```

Important page prop:

```ts
searchParams?: Promise<{
  seeded?: string;
}>;
```

In recent Next.js App Router versions, `searchParams` may be asynchronous in Server Components. This version handles that safely.

---

## The Verification

Run:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000/accounts
```

If your active organization has no accounts, you should see:

```txt
Seed default accounts
```

Click it.

You should be redirected to:

```txt
/accounts?seeded=1
```

You should now see grouped accounts.

Click:

```txt
Re-run seed safely
```

The number of accounts should not double.

---

# 7. Update the Database Accounts Diagnostic Page

## The Target

We are updating:

```txt
app/settings/database/accounts/page.tsx
```

so it can also seed accounts and show better diagnostic context.

---

## The Concept

The main `/accounts` page is for users.

The database diagnostic page is for developers and admins.

Both can use the same server action safely because the seeding operation is idempotent.

---

## The Implementation

Open:

```txt
app/settings/database/accounts/page.tsx
```

Replace the entire file with:

```tsx
// app/settings/database/accounts/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { seedDefaultChartOfAccountsAction } from "@/app/accounts/actions";
import {
  accountTypeLabels,
  listCurrentOrganizationAccounts,
} from "@/services/accounts/get-accounts";

export const dynamic = "force-dynamic";

export default async function DatabaseAccountsPage() {
  const { organizationId, accounts } = await listCurrentOrganizationAccounts();

  return (
    <AppLayout
      title="Database Accounts"
      description="Inspect chart of accounts rows for the active database organization."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-sky-600">
              Chart of accounts data
            </p>

            <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
              Active organization accounts
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
              This diagnostic page queries the <code>accounts</code> table for
              the currently active database organization.
            </p>
          </div>

          <div className="flex flex-wrap gap-2">
            <Link
              href="/accounts"
              className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
            >
              Open accounts page
            </Link>

            <Link
              href="/settings/database"
              className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
            >
              Database status
            </Link>
          </div>
        </div>

        {organizationId ? (
          <div className="mt-6 rounded-xl border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm font-semibold text-slate-700">
              Active database organization ID
            </p>

            <p className="mt-1 break-all font-mono text-xs text-slate-500">
              {organizationId}
            </p>
          </div>
        ) : (
          <div className="mt-6 rounded-2xl border border-amber-200 bg-amber-50 p-5">
            <p className="text-sm font-semibold text-amber-800">
              No active organization selected.
            </p>

            <p className="mt-2 text-sm leading-6 text-amber-700">
              Create or select a company workspace before viewing organization
              accounts.
            </p>

            <Link
              href="/onboarding/organization"
              className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-amber-700"
            >
              Create company workspace
            </Link>
          </div>
        )}

        {organizationId && accounts.length === 0 ? (
          <div className="mt-6 rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
            <h3 className="text-lg font-semibold text-slate-950">
              No accounts yet
            </h3>

            <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
              The accounts table exists, but this organization has not been
              seeded yet.
            </p>

            <form action={seedDefaultChartOfAccountsAction} className="mt-5">
              <button
                type="submit"
                className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
              >
                Seed default accounts
              </button>
            </form>
          </div>
        ) : null}

        {organizationId && accounts.length > 0 ? (
          <div className="mt-6 overflow-hidden rounded-xl border border-slate-200">
            <table className="w-full border-collapse text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-semibold">Code</th>
                  <th className="px-4 py-3 font-semibold">Name</th>
                  <th className="px-4 py-3 font-semibold">Type</th>
                  <th className="px-4 py-3 font-semibold">System</th>
                  <th className="px-4 py-3 font-semibold">Active</th>
                  <th className="px-4 py-3 font-semibold">Database ID</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-200 bg-white">
                {accounts.map((account) => (
                  <tr key={account.id}>
                    <td className="px-4 py-3 font-mono text-xs font-semibold text-slate-700">
                      {account.code}
                    </td>

                    <td className="px-4 py-3 font-semibold text-slate-950">
                      {account.name}
                    </td>

                    <td className="px-4 py-3 text-slate-600">
                      {accountTypeLabels[account.type]}
                    </td>

                    <td className="px-4 py-3 text-slate-600">
                      {account.isSystem ? "Yes" : "No"}
                    </td>

                    <td className="px-4 py-3 text-slate-600">
                      {account.isActive ? "Yes" : "No"}
                    </td>

                    <td className="px-4 py-3">
                      <code className="break-all text-xs text-slate-500">
                        {account.id}
                      </code>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : null}
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/settings/database/accounts
```

You should see accounts if you already seeded them.

If not, click:

```txt
Seed default accounts
```

Then return to the page.

---

# 8. Update Database Health Expectations

## The Target

We are verifying that the database status page now shows account rows.

---

## The Concept

In Part 9, the account count was expected to be:

```txt
0
```

After seeding, it should be greater than zero.

The exact count should match:

```txt
defaultChartOfAccounts.length
```

At the time of this tutorial, that is:

```txt
33
```

If you later edit the seed list, the count may change.

---

## The Implementation

No code change required in this step.

Open:

```txt
http://localhost:3000/settings/database
```

Look for:

```txt
Account rows
```

---

## The Verification

After seeding, you should see something like:

```txt
Account rows: 33
```

If you have multiple organizations and seeded each one, this number may be higher because the database status page counts all account rows across all organizations.

The `/accounts` page only shows accounts for the active organization.

That distinction is important:

```txt
/settings/database       = global diagnostic count
/accounts                = active organization only
```

---

# 9. Verify the Seed in Neon SQL

## The Target

We are directly verifying seeded accounts in Neon.

---

## The Concept

The app UI is useful, but direct database verification confirms the rows really exist in Postgres.

---

## The Implementation

Open Neon SQL editor.

Run:

```sql
select
  o.name as organization_name,
  a.code,
  a.name as account_name,
  a.type,
  a.is_system,
  a.is_active
from accounts a
join organizations o
  on o.id = a.organization_id
order by o.name, a.code;
```

You should see rows such as:

```txt
Demo Pte. Ltd.  1000  Bank                 asset
Demo Pte. Ltd.  1100  Accounts Receivable  asset
Demo Pte. Ltd.  2100  GST Payable          liability
Demo Pte. Ltd.  4000  Sales Revenue        income
Demo Pte. Ltd.  6200  CPF Employer Contributions expense
```

Now verify that duplicate account codes do not exist within one organization:

```sql
select
  organization_id,
  code,
  count(*) as duplicate_count
from accounts
group by organization_id, code
having count(*) > 1;
```

---

## The Verification

The duplicate query should return zero rows.

That proves the seed did not create duplicate account codes.

---

# 10. Verify Idempotency

## The Target

We are proving the seed can safely run multiple times.

---

## The Concept

A good seed operation should not panic if a user clicks the button twice.

It should also be safe during development if you rerun setup.

This is especially important for SaaS onboarding flows.

---

## The Implementation

Open:

```txt
http://localhost:3000/accounts
```

Click:

```txt
Re-run seed safely
```

Now open Neon SQL editor and run:

```sql
select
  organization_id,
  count(*) as account_count
from accounts
group by organization_id
order by account_count desc;
```

Run the seed again.

Run the SQL query again.

---

## The Verification

The account count for the same organization should stay the same.

It should not double.

If the count was:

```txt
33
```

it should remain:

```txt
33
```

---

# 11. Run Drizzle Studio Verification

## The Target

We are inspecting the seeded accounts visually.

---

## The Concept

Drizzle Studio gives a table view of your database.

It is useful for quickly checking seed data.

---

## The Implementation

Run:

```bash
pnpm db:studio
```

Open the Studio URL printed in the terminal.

Open the table:

```txt
accounts
```

---

## The Verification

You should see rows with:

```txt
code
name
type
description
is_system
is_active
organization_id
```

Confirm that:

```txt
is_system = true
is_active = true
```

for the seeded accounts.

---

# 12. Run the Project Health Check

## The Target

We are confirming the project still passes linting and production build.

---

## The Concept

We added:

- Seed data
- Account seeding service
- Server action
- Updated account page
- Updated diagnostic page

That touches server actions, database queries, and UI. We should run the full check.

---

## The Implementation

Stop the dev server if needed:

```txt
Ctrl + C
```

Run:

```bash
pnpm check
```

---

## The Verification

The command should complete successfully.

If it fails, read the first error carefully.

---

# 13. Commit the Chart of Accounts Seed

## The Target

We are committing the seed implementation.

---

## The Concept

This is a major accounting milestone.

GreyMatter Ledger now has a real, organization-scoped chart of accounts that can be seeded from the UI.

That means we are ready to build:

- Chart of Accounts page improvements
- Journal entry tables
- Journal posting engine

---

## The Implementation

Run:

```bash
git status
```

You should see files like:

```txt
app/accounts/actions.ts
app/accounts/page.tsx
app/settings/database/accounts/page.tsx
lib/accounting/default-chart-of-accounts.ts
services/accounts/get-accounts.ts
services/accounts/seed-default-chart-of-accounts.ts
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Seed Singapore-friendly chart of accounts"
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

## Error: `No active organization selected`

You need to create or select a company workspace first.

Open:

```txt
/onboarding/organization
```

Create an organization.

Then open:

```txt
/accounts
```

---

## Error: `relation "accounts" does not exist`

The Part 9 migration was not applied.

Run:

```bash
pnpm db:migrate
```

Then reload:

```txt
/accounts
```

---

## Error: Clicking seed creates duplicate rows

This should not happen if the unique index exists.

Check Neon:

```sql
select
  indexname,
  indexdef
from pg_indexes
where tablename = 'accounts';
```

You should see:

```txt
accounts_organization_id_code_idx
```

If this index is missing, rerun the Part 9 migration or inspect your migration history.

---

## Error: Server action import fails

Make sure this file exists:

```txt
app/accounts/actions.ts
```

And starts with:

```ts
"use server";
```

Also make sure the page imports:

```ts
import { seedDefaultChartOfAccountsAction } from "@/app/accounts/actions";
```

---

## Error: `searchParams` type error

The tutorial uses:

```ts
searchParams?: Promise<{
  seeded?: string;
}>;
```

This is compatible with newer App Router behavior.

If your local Next.js setup expects synchronous `searchParams`, you can adjust the page props to:

```ts
type AccountsPageProps = {
  searchParams?: {
    seeded?: string;
  };
};
```

and remove:

```ts
const resolvedSearchParams = searchParams ? await searchParams : {};
```

with:

```ts
const resolvedSearchParams = searchParams ?? {};
```

But for the Next.js 16-targeted tutorial, keep the asynchronous version.

---

## Error: Account count in `/settings/database` is higher than expected

That page counts all accounts across all organizations.

If you have seeded multiple organizations, the count will be higher.

For example:

```txt
33 accounts × 2 organizations = 66 account rows
```

The `/accounts` page only shows accounts for the active organization.

---

## Error: Seed updates account names after I customize them

This tutorial seed marks default accounts as system accounts and refreshes their names/descriptions when rerun.

In a production accounting system, you may choose a stricter rule:

- Seed only missing accounts
- Never update existing user-edited account names
- Store system account mappings separately

For now, refreshing system seed labels keeps the tutorial predictable.

---

# Phase 4 Reference — Seeding Vocabulary

## Seed Data

Seed data is default data inserted into a database to make the application usable.

In this part, seed data means default chart of accounts rows.

---

## Idempotent

Idempotent means safe to run more than once.

Our seed is idempotent because the database unique index prevents duplicate account codes per organization, and the service uses upsert logic.

---

## Upsert

Upsert means:

```txt
Insert if missing.
Update if already exists.
```

In Drizzle, we used:

```ts
.onConflictDoUpdate(...)
```

---

## System Account

A system account is created by the application’s default seed process.

Examples:

```txt
1000 Bank
1100 Accounts Receivable
2000 Accounts Payable
2100 GST Payable
4000 Sales Revenue
```

Later, invoice and payment workflows will rely on system accounts.

---

## Active Account

An active account can be used for new transactions.

An inactive account remains in history but should not normally be used for new postings.

---

# Part 10 Completion Checklist

You are ready for Part 11 if:

- [ ] `lib/accounting/default-chart-of-accounts.ts` exists
- [ ] Default accounts include Singapore-friendly GST, CPF, and tax-related accounts
- [ ] `services/accounts/seed-default-chart-of-accounts.ts` exists
- [ ] The seed service uses upsert logic
- [ ] `app/accounts/actions.ts` exists
- [ ] `/accounts` shows a seed button when no accounts exist
- [ ] Clicking seed creates accounts for the active organization
- [ ] `/accounts` groups accounts by type after seeding
- [ ] Re-running the seed does not create duplicate account codes
- [ ] `/settings/database/accounts` shows seeded accounts
- [ ] Neon SQL confirms account rows exist
- [ ] Duplicate account SQL check returns zero rows
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
