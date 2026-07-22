# Part 11 — Build the Chart of Accounts Page

In Part 10, we seeded a Singapore-friendly chart of accounts.

Now we will turn `/accounts` into a more complete working page.

By the end of this part, you will have:

- A real Chart of Accounts page backed by Postgres
- Account grouping by type
- A custom account creation form
- Server-side validation for account creation
- Safe tenant-scoped account mutation services
- Active/inactive account controls
- A no-delete accounting design
- Clear user feedback through URL status flags
- Updated diagnostics

This part is important because the chart of accounts is the foundation for the journal engine we will build soon.

Every future journal line will eventually point to one account.

---

# 1. Understand What the Chart of Accounts Page Must Do

## The Target

We are building a usable `/accounts` page.

It should support:

```txt
View accounts
Seed default accounts
Create custom accounts
Deactivate accounts
Reactivate accounts
```

---

## The Concept

A chart of accounts is not just a list.

It is the controlled vocabulary of the ledger.

A useful analogy:

```txt
Chart of accounts = official dictionary
Journal entries   = sentences written using that dictionary
Reports           = summaries of those sentences
```

If the dictionary is messy, the journal becomes messy. If the journal is messy, reports become unreliable.

So the accounts page must be careful.

We will **not** casually delete accounts.

Why?

Because once a journal entry references an account, deleting that account would damage history.

Instead, accounting systems usually make accounts inactive.

That means:

```txt
Inactive accounts stay visible in history.
Inactive accounts should not be used for new postings.
```

In this part, there are no journal entries yet, but we will build the page with that future rule in mind.

---

## The Implementation

The page will use this workflow:

```txt
/accounts
  |
  |-- no organization selected
  |     show organization setup prompt
  |
  |-- organization selected but no accounts
  |     show seed button
  |
  |-- accounts exist
        show grouped accounts
        show custom account form
        show activate/deactivate controls
```

---

## The Verification

At the end:

1. Open `/accounts`.
2. Seed default accounts if needed.
3. Create a custom account.
4. Deactivate the custom account.
5. Reactivate it.
6. Confirm no duplicate account codes are created.

---

# 2. Add Account Mutation Services

## The Target

We are creating:

```txt
services/accounts/mutate-accounts.ts
```

This file will contain server-side logic for creating and updating accounts.

---

## The Concept

Pages should not directly mutate database rows.

Instead, pages call server actions, and server actions call services.

The chain looks like this:

```txt
Form submit
  |
  v
Server action
  |
  v
Account service
  |
  v
Drizzle ORM
  |
  v
Postgres
```

This keeps important rules in one place.

For example:

- Account code is required
- Account name is required
- Account type must be valid
- Account belongs to the active organization
- Account status updates must be scoped to the active organization

The phrase **scoped to the active organization** means:

> A user can only modify accounts belonging to the company workspace they are currently using.

That is a multi-tenant safety rule.

---

## The Implementation

Create:

```txt
services/accounts/mutate-accounts.ts
```

Add:

```ts
// services/accounts/mutate-accounts.ts

import { and, eq } from "drizzle-orm";
import { db } from "@/db";
import { accounts, type Account } from "@/db/schema";
import type { AccountType } from "@/lib/accounting/types";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

const validAccountTypes: AccountType[] = [
  "asset",
  "liability",
  "equity",
  "income",
  "expense",
];

export type CreateAccountInput = {
  code: string;
  name: string;
  type: AccountType;
  description?: string | null;
};

export type AccountMutationResult =
  | {
      ok: true;
      account: Account;
    }
  | {
      ok: false;
      error: string;
    };

function normalizeAccountCode(code: string): string {
  return code.trim();
}

function normalizeAccountName(name: string): string {
  return name.trim();
}

function normalizeDescription(description?: string | null): string | null {
  const normalized = description?.trim() ?? "";

  return normalized.length > 0 ? normalized : null;
}

function isValidAccountType(value: string): value is AccountType {
  return validAccountTypes.includes(value as AccountType);
}

/**
 * Creates a custom account for the currently active organization.
 *
 * This function is tenant-safe because it always uses the active database
 * organization from the server-side Clerk context.
 */
export async function createAccountForCurrentOrganization(
  input: CreateAccountInput,
): Promise<AccountMutationResult> {
  const organization = await requireCurrentDatabaseOrganization();

  const code = normalizeAccountCode(input.code);
  const name = normalizeAccountName(input.name);
  const description = normalizeDescription(input.description);

  if (!code) {
    return {
      ok: false,
      error: "Account code is required.",
    };
  }

  if (!/^[0-9A-Za-z.-]{2,20}$/.test(code)) {
    return {
      ok: false,
      error:
        "Account code must be 2–20 characters and may contain letters, numbers, dots, or hyphens.",
    };
  }

  if (!name) {
    return {
      ok: false,
      error: "Account name is required.",
    };
  }

  if (name.length > 120) {
    return {
      ok: false,
      error: "Account name must be 120 characters or fewer.",
    };
  }

  if (!isValidAccountType(input.type)) {
    return {
      ok: false,
      error: "Invalid account type.",
    };
  }

  try {
    const [createdAccount] = await db
      .insert(accounts)
      .values({
        organizationId: organization.id,
        code,
        name,
        type: input.type,
        description,
        isSystem: false,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
      .returning();

    if (!createdAccount) {
      return {
        ok: false,
        error: "Account could not be created.",
      };
    }

    return {
      ok: true,
      account: createdAccount,
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : "";

    /**
     * Postgres will reject duplicate account codes because Part 9 added a
     * unique index on organization_id + code.
     */
    if (
      message.includes("accounts_organization_id_code_idx") ||
      message.toLowerCase().includes("duplicate")
    ) {
      return {
        ok: false,
        error:
          "An account with this code already exists for the active organization.",
      };
    }

    return {
      ok: false,
      error: "Unexpected database error while creating account.",
    };
  }
}

/**
 * Updates whether an account is active for the currently active organization.
 *
 * We do not delete accounts because future journal history may reference them.
 * Deactivation is safer than deletion in accounting systems.
 */
export async function setAccountActiveStateForCurrentOrganization(
  accountId: string,
  isActive: boolean,
): Promise<AccountMutationResult> {
  const organization = await requireCurrentDatabaseOrganization();

  if (!accountId.trim()) {
    return {
      ok: false,
      error: "Account ID is required.",
    };
  }

  const [updatedAccount] = await db
    .update(accounts)
    .set({
      isActive,
      updatedAt: new Date(),
    })
    .where(
      and(
        eq(accounts.id, accountId),
        eq(accounts.organizationId, organization.id),
      ),
    )
    .returning();

  if (!updatedAccount) {
    return {
      ok: false,
      error:
        "Account was not found for the active organization, or you do not have access to it.",
    };
  }

  return {
    ok: true,
    account: updatedAccount,
  };
}
```

Important tenant-safe condition:

```ts
and(
  eq(accounts.id, accountId),
  eq(accounts.organizationId, organization.id),
)
```

This prevents updating an account from another organization.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

---

# 3. Expand Account Server Actions

## The Target

We are updating:

```txt
app/accounts/actions.ts
```

to support:

- Seeding default accounts
- Creating custom accounts
- Deactivating accounts
- Reactivating accounts

---

## The Concept

Server actions are the bridge between HTML forms and server-side logic.

A form can call a server action directly:

```tsx
<form action={createAccountAction}>
```

When submitted, Next.js runs the action on the server.

That means database credentials never go to the browser.

---

## The Implementation

Open:

```txt
app/accounts/actions.ts
```

Replace the entire file with:

```ts
// app/accounts/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import type { AccountType } from "@/lib/accounting/types";
import {
  createAccountForCurrentOrganization,
  setAccountActiveStateForCurrentOrganization,
} from "@/services/accounts/mutate-accounts";
import { seedDefaultChartOfAccountsForCurrentOrganization } from "@/services/accounts/seed-default-chart-of-accounts";

function revalidateAccountViews() {
  revalidatePath("/accounts");
  revalidatePath("/settings/database");
  revalidatePath("/settings/database/accounts");
}

/**
 * Seeds the default chart of accounts for the active organization.
 */
export async function seedDefaultChartOfAccountsAction() {
  await seedDefaultChartOfAccountsForCurrentOrganization();

  revalidateAccountViews();

  redirect("/accounts?status=seeded");
}

/**
 * Creates a custom account for the active organization.
 */
export async function createAccountAction(formData: FormData) {
  const code = String(formData.get("code") ?? "");
  const name = String(formData.get("name") ?? "");
  const type = String(formData.get("type") ?? "") as AccountType;
  const description = String(formData.get("description") ?? "");

  const result = await createAccountForCurrentOrganization({
    code,
    name,
    type,
    description,
  });

  revalidateAccountViews();

  if (!result.ok) {
    redirect(`/accounts?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect("/accounts?status=created");
}

/**
 * Deactivates an account for the active organization.
 */
export async function deactivateAccountAction(formData: FormData) {
  const accountId = String(formData.get("accountId") ?? "");

  const result = await setAccountActiveStateForCurrentOrganization(
    accountId,
    false,
  );

  revalidateAccountViews();

  if (!result.ok) {
    redirect(`/accounts?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect("/accounts?status=deactivated");
}

/**
 * Reactivates an account for the active organization.
 */
export async function reactivateAccountAction(formData: FormData) {
  const accountId = String(formData.get("accountId") ?? "");

  const result = await setAccountActiveStateForCurrentOrganization(
    accountId,
    true,
  );

  revalidateAccountViews();

  if (!result.ok) {
    redirect(`/accounts?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect("/accounts?status=reactivated");
}
```

The URL status flags are intentionally simple.

Examples:

```txt
/accounts?status=created
/accounts?status=error&message=Account%20code%20is%20required
```

Later, we can replace this with richer toast notifications.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

---

# 4. Create Account Page UI Helpers

## The Target

We are creating:

```txt
components/account-status-banner.tsx
```

This component displays status messages on the accounts page.

---

## The Concept

After a server action redirects, the page can read URL search params.

For example:

```txt
/accounts?status=created
```

The banner turns that technical status into a human-readable message.

This gives users feedback after clicking buttons.

---

## The Implementation

Create:

```txt
components/account-status-banner.tsx
```

Add:

```tsx
// components/account-status-banner.tsx

type AccountStatusBannerProps = {
  status?: string;
  message?: string;
};

const statusMessages: Record<
  string,
  {
    title: string;
    description: string;
    className: string;
  }
> = {
  seeded: {
    title: "Default chart of accounts seeded successfully.",
    description:
      "Your active organization now has a Singapore-friendly starter chart of accounts.",
    className: "border-emerald-200 bg-emerald-50 text-emerald-800",
  },
  created: {
    title: "Account created successfully.",
    description:
      "The new account is now available in the active organization's chart of accounts.",
    className: "border-emerald-200 bg-emerald-50 text-emerald-800",
  },
  deactivated: {
    title: "Account deactivated.",
    description:
      "The account remains in the chart for history but should not be used for new postings.",
    className: "border-amber-200 bg-amber-50 text-amber-800",
  },
  reactivated: {
    title: "Account reactivated.",
    description:
      "The account is active again and can be used for future postings.",
    className: "border-emerald-200 bg-emerald-50 text-emerald-800",
  },
  error: {
    title: "Account action failed.",
    description:
      "The requested account operation could not be completed.",
    className: "border-rose-200 bg-rose-50 text-rose-800",
  },
};

export function AccountStatusBanner({
  status,
  message,
}: AccountStatusBannerProps) {
  if (!status) {
    return null;
  }

  const statusInfo = statusMessages[status];

  if (!statusInfo) {
    return null;
  }

  return (
    <section className={`rounded-2xl border p-5 ${statusInfo.className}`}>
      <p className="text-sm font-semibold">{statusInfo.title}</p>

      <p className="mt-2 text-sm leading-6">
        {status === "error" && message ? message : statusInfo.description}
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

The build should succeed.

---

# 5. Create the Custom Account Form Component

## The Target

We are creating:

```txt
components/account-create-form.tsx
```

This form lets users add custom accounts.

---

## The Concept

The default seed gives a useful starter chart, but businesses often need extra accounts.

Examples:

```txt
6050 Office Supplies
6310 Hosting Expense
4210 Grant Income
1520 Rental Deposit
```

A custom account form should collect:

```txt
Code
Name
Type
Description
```

The actual validation still happens on the server. Browser fields help the user, but server validation is the real security gate.

---

## The Implementation

Create:

```txt
components/account-create-form.tsx
```

Add:

```tsx
// components/account-create-form.tsx

import { createAccountAction } from "@/app/accounts/actions";
import {
  accountTypeDisplayOrder,
  accountTypeLabels,
} from "@/services/accounts/get-accounts";

export function AccountCreateForm() {
  return (
    <form
      action={createAccountAction}
      className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
    >
      <div>
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
          Custom account
        </p>

        <h2 className="mt-3 text-lg font-semibold text-slate-950">
          Add an account
        </h2>

        <p className="mt-2 text-sm leading-6 text-slate-500">
          Add organization-specific accounts that are not part of the default
          seed list.
        </p>
      </div>

      <div className="mt-6 grid gap-4 lg:grid-cols-[0.5fr_1fr_0.7fr]">
        <label className="block">
          <span className="text-sm font-semibold text-slate-700">Code</span>
          <input
            name="code"
            required
            minLength={2}
            maxLength={20}
            placeholder="6050"
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-slate-700">Name</span>
          <input
            name="name"
            required
            maxLength={120}
            placeholder="Office Supplies"
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-slate-700">Type</span>
          <select
            name="type"
            required
            defaultValue="expense"
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          >
            {accountTypeDisplayOrder.map((accountType) => (
              <option key={accountType} value={accountType}>
                {accountTypeLabels[accountType]}
              </option>
            ))}
          </select>
        </label>
      </div>

      <label className="mt-4 block">
        <span className="text-sm font-semibold text-slate-700">
          Description
        </span>
        <textarea
          name="description"
          rows={3}
          placeholder="Optional explanation for when this account should be used."
          className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
        />
      </label>

      <div className="mt-5 flex justify-end">
        <button
          type="submit"
          className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
        >
          Create account
        </button>
      </div>
    </form>
  );
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

# 6. Create the Account Group Table Component

## The Target

We are creating:

```txt
components/account-group-table.tsx
```

This component displays accounts for one account type.

---

## The Concept

The page is easier to read if each account type is in its own section:

```txt
Assets
Liabilities
Equity
Income
Expenses
```

This component renders one section.

It also provides activate/deactivate forms.

---

## The Implementation

Create:

```txt
components/account-group-table.tsx
```

Add:

```tsx
// components/account-group-table.tsx

import type { Account } from "@/db/schema";
import type { AccountType } from "@/lib/accounting/types";
import {
  deactivateAccountAction,
  reactivateAccountAction,
} from "@/app/accounts/actions";
import { accountTypeLabels } from "@/services/accounts/get-accounts";

type AccountGroupTableProps = {
  accountType: AccountType;
  accounts: Account[];
};

export function AccountGroupTable({
  accountType,
  accounts,
}: AccountGroupTableProps) {
  if (accounts.length === 0) {
    return null;
  }

  return (
    <article className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
        <h2 className="text-lg font-semibold text-slate-950">
          {accountTypeLabels[accountType]}
        </h2>

        <p className="mt-1 text-sm text-slate-500">
          {accounts.length} account{accounts.length === 1 ? "" : "s"}
        </p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-left text-sm">
          <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
            <tr>
              <th className="px-6 py-3 font-semibold">Code</th>
              <th className="px-6 py-3 font-semibold">Name</th>
              <th className="px-6 py-3 font-semibold">Description</th>
              <th className="px-6 py-3 font-semibold">Source</th>
              <th className="px-6 py-3 font-semibold">Status</th>
              <th className="px-6 py-3 text-right font-semibold">Action</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-slate-200">
            {accounts.map((account) => (
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

                <td className="px-6 py-4 text-right">
                  {account.isActive ? (
                    <form action={deactivateAccountAction}>
                      <input
                        type="hidden"
                        name="accountId"
                        value={account.id}
                      />

                      <button
                        type="submit"
                        className="rounded-xl border border-amber-200 bg-amber-50 px-3 py-2 text-xs font-semibold text-amber-700 transition hover:bg-amber-100"
                      >
                        Deactivate
                      </button>
                    </form>
                  ) : (
                    <form action={reactivateAccountAction}>
                      <input
                        type="hidden"
                        name="accountId"
                        value={account.id}
                      />

                      <button
                        type="submit"
                        className="rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs font-semibold text-emerald-700 transition hover:bg-emerald-100"
                      >
                        Reactivate
                      </button>
                    </form>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </article>
  );
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

# 7. Rebuild the `/accounts` Page Using Components

## The Target

We are updating:

```txt
app/accounts/page.tsx
```

The page will now use our new components.

---

## The Concept

As pages grow, breaking UI into components keeps files readable.

This page will now use:

```txt
AccountStatusBanner
AccountCreateForm
AccountGroupTable
```

The page itself will focus on data loading and page-level decisions.

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
import { AccountCreateForm } from "@/components/account-create-form";
import { AccountGroupTable } from "@/components/account-group-table";
import { AccountStatusBanner } from "@/components/account-status-banner";
import { AppLayout } from "@/components/app-layout";
import { EmptyState } from "@/components/empty-state";
import {
  accountTypeDisplayOrder,
  groupAccountsByType,
  listCurrentOrganizationAccounts,
} from "@/services/accounts/get-accounts";
import { seedDefaultChartOfAccountsAction } from "@/app/accounts/actions";

export const dynamic = "force-dynamic";

type AccountsPageProps = {
  searchParams?: Promise<{
    status?: string;
    message?: string;
  }>;
};

export default async function AccountsPage({
  searchParams,
}: AccountsPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};

  const { organizationId, accounts } = await listCurrentOrganizationAccounts();
  const groupedAccounts = groupAccountsByType(accounts);
  const hasAccounts = accounts.length > 0;
  const activeAccountCount = accounts.filter((account) => account.isActive).length;
  const inactiveAccountCount = accounts.length - activeAccountCount;

  return (
    <AppLayout
      title="Chart of Accounts"
      description="The chart of accounts is the master list of categories used to classify every financial transaction."
    >
      <div className="space-y-6">
        <AccountStatusBanner
          status={resolvedSearchParams.status}
          message={resolvedSearchParams.message}
        />

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
              organization before seeding or managing the chart of accounts.
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

                <div className="mt-4 flex flex-wrap gap-2">
                  <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
                    {activeAccountCount} active
                  </span>

                  <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                    {inactiveAccountCount} inactive
                  </span>
                </div>
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

        {organizationId && hasAccounts ? <AccountCreateForm /> : null}

        {organizationId && hasAccounts ? (
          <section className="space-y-6">
            {accountTypeDisplayOrder.map((accountType) => (
              <AccountGroupTable
                key={accountType}
                accountType={accountType}
                accounts={groupedAccounts[accountType]}
              />
            ))}
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

You should see:

- A chart summary
- A re-run seed button
- A database diagnostic link
- A custom account form
- Grouped accounts by type
- Deactivate/reactivate buttons

---

# 8. Update the Database Accounts Diagnostic Page

## The Target

We are updating:

```txt
app/settings/database/accounts/page.tsx
```

to display active and inactive counts.

---

## The Concept

Diagnostics should help us understand data quickly.

Now that accounts can be active or inactive, the diagnostic page should show that split.

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

  const activeAccountCount = accounts.filter((account) => account.isActive).length;
  const inactiveAccountCount = accounts.length - activeAccountCount;

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
          <div className="mt-6 grid gap-4 lg:grid-cols-3">
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 lg:col-span-3">
              <p className="text-sm font-semibold text-slate-700">
                Active database organization ID
              </p>

              <p className="mt-1 break-all font-mono text-xs text-slate-500">
                {organizationId}
              </p>
            </div>

            <div className="rounded-xl bg-emerald-50 p-4">
              <p className="text-sm font-semibold text-emerald-700">
                Active accounts
              </p>
              <p className="mt-2 text-3xl font-bold text-emerald-900">
                {activeAccountCount}
              </p>
            </div>

            <div className="rounded-xl bg-slate-100 p-4">
              <p className="text-sm font-semibold text-slate-700">
                Inactive accounts
              </p>
              <p className="mt-2 text-3xl font-bold text-slate-900">
                {inactiveAccountCount}
              </p>
            </div>

            <div className="rounded-xl bg-sky-50 p-4">
              <p className="text-sm font-semibold text-sky-700">
                Total accounts
              </p>
              <p className="mt-2 text-3xl font-bold text-sky-900">
                {accounts.length}
              </p>
            </div>
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

You should see:

- Active account count
- Inactive account count
- Total account count

Deactivate an account from `/accounts`, then refresh this diagnostic page.

The inactive count should increase.

---

# 9. Test Creating a Custom Account

## The Target

We are testing custom account creation.

---

## The Concept

Custom accounts are necessary because no seed list can predict every business.

For example, a company may need:

```txt
6050 Office Supplies
6320 Cloud Infrastructure
4210 Government Grants
1510 Rental Deposit
```

---

## The Implementation

Open:

```txt
http://localhost:3000/accounts
```

Find the custom account form.

Enter:

```txt
Code: 6050
Name: Office Supplies
Type: Expenses
Description: Stationery, office consumables, and small office purchases.
```

Click:

```txt
Create account
```

You should be redirected to:

```txt
/accounts?status=created
```

---

## The Verification

You should see:

```txt
Account created successfully.
```

Under the Expenses section, you should see:

```txt
6050 Office Supplies
```

Now open Neon SQL editor and run:

```sql
select
  code,
  name,
  type,
  is_system,
  is_active
from accounts
where code = '6050'
order by created_at desc;
```

You should see:

```txt
6050  Office Supplies  expense  false  true
```

`is_system` should be `false` because this account was created manually, not by the seed.

---

# 10. Test Duplicate Account Protection

## The Target

We are verifying that duplicate account codes are rejected.

---

## The Concept

Inside one organization, account codes must be unique.

This protects the chart of accounts from ambiguity.

Imagine if a company had:

```txt
1000 Bank
1000 Petty Cash
```

A journal line using account code `1000` would become confusing.

So the database rejects duplicates.

---

## The Implementation

Try to create another account with the same code:

```txt
Code: 6050
Name: Duplicate Office Supplies
Type: Expenses
Description: This should fail.
```

Click:

```txt
Create account
```

---

## The Verification

You should be redirected to a URL like:

```txt
/accounts?status=error&message=...
```

The page should show:

```txt
Account action failed.
```

With a message similar to:

```txt
An account with this code already exists for the active organization.
```

Now verify in Neon:

```sql
select
  organization_id,
  code,
  count(*) as duplicate_count
from accounts
where code = '6050'
group by organization_id, code
having count(*) > 1;
```

This should return zero rows.

---

# 11. Test Deactivation and Reactivation

## The Target

We are verifying that accounts can be made inactive and active again.

---

## The Concept

We do not delete accounts.

We deactivate them.

This preserves history and avoids future broken references once journal entries exist.

---

## The Implementation

Open:

```txt
http://localhost:3000/accounts
```

Find:

```txt
6050 Office Supplies
```

Click:

```txt
Deactivate
```

You should be redirected to:

```txt
/accounts?status=deactivated
```

Now the row should show:

```txt
Inactive
```

Click:

```txt
Reactivate
```

You should be redirected to:

```txt
/accounts?status=reactivated
```

Now the row should show:

```txt
Active
```

---

## The Verification

Open Neon SQL editor and run:

```sql
select
  code,
  name,
  is_active
from accounts
where code = '6050';
```

After deactivation:

```txt
is_active = false
```

After reactivation:

```txt
is_active = true
```

---

# 12. Verify Tenant Isolation Manually

## The Target

We are confirming that accounts are scoped per organization.

---

## The Concept

Two organizations can both have account code:

```txt
6050
```

That is okay because each company has its own chart of accounts.

The database uniqueness rule is:

```txt
organization_id + code
```

not just:

```txt
code
```

---

## The Implementation

If you have two Clerk organizations:

1. Use the organization switcher to select Organization A.
2. Create account:

```txt
6050 Office Supplies
```

3. Switch to Organization B.
4. Open `/accounts`.
5. Seed default accounts if needed.
6. Create account:

```txt
6050 Office Supplies
```

This should be allowed.

Now run in Neon:

```sql
select
  o.name as organization_name,
  a.code,
  a.name as account_name
from accounts a
join organizations o
  on o.id = a.organization_id
where a.code = '6050'
order by o.name;
```

---

## The Verification

You should see one row per organization.

This is correct:

```txt
Organization A  6050  Office Supplies
Organization B  6050  Office Supplies
```

This proves account codes are isolated by organization.

---

# 13. Run the Project Health Check

## The Target

We are confirming that the full app still passes linting and production build.

---

## The Concept

We added:

- Mutation services
- Server actions
- Form components
- Account tables
- Account status controls

That touches many important layers, so we should run the full check.

---

## The Implementation

Stop the dev server if it is running:

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

Common issues are listed below.

---

# 14. Commit the Chart of Accounts Page

## The Target

We are saving this work with Git.

---

## The Concept

This is a meaningful product milestone.

GreyMatter Ledger now has a working chart of accounts interface.

The app can:

```txt
Seed accounts
Create custom accounts
Deactivate accounts
Reactivate accounts
Show organization-scoped account lists
```

That prepares us for the journal engine.

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
components/account-create-form.tsx
components/account-group-table.tsx
components/account-status-banner.tsx
services/accounts/mutate-accounts.ts
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Build chart of accounts page"
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

## Error: Account creation redirects to an error

Check the banner message.

Common causes:

```txt
Account code is required.
Account name is required.
Invalid account type.
Duplicate account code.
```

Fix the form input and submit again.

---

## Error: Duplicate account code fails

That is expected if the same organization already has that code.

Use a different code, such as:

```txt
6051
```

---

## Error: `No active organization selected`

Create or select a company workspace:

```txt
/onboarding/organization
```

Then return to:

```txt
/accounts
```

---

## Error: Deactivate button says account not found

This usually means the account ID does not belong to the active organization.

Refresh the page after switching organizations.

Remember:

```txt
/accounts only controls accounts for the active organization.
```

---

## Error: Server action import fails

Check:

```txt
app/accounts/actions.ts
```

It must start with:

```ts
"use server";
```

Also confirm imports use the alias:

```ts
import { createAccountAction } from "@/app/accounts/actions";
```

---

## Error: Account status does not update immediately

The server action calls:

```ts
revalidatePath("/accounts");
```

If you still see stale output, hard refresh the browser.

Also confirm the action redirects back to `/accounts`.

---

## Error: `pnpm check` fails because `DATABASE_URL` is missing

The app now contains database-backed server pages.

Make sure `.env.local` includes:

```bash
DATABASE_URL="postgresql://..."
```

For production, we will add this value to Vercel environment variables in the deployment phase.

---

# Phase 4 Reference — Chart of Accounts UI Rules

## Do Not Delete Accounts Casually

Once journal entries exist, deleting accounts can break historical reports.

Use:

```txt
is_active = false
```

instead.

---

## System Accounts

Seeded accounts have:

```txt
is_system = true
```

They are used by standard workflows such as:

```txt
Invoices
Bills
Payments
GST reports
```

---

## Custom Accounts

User-created accounts have:

```txt
is_system = false
```

They let businesses customize the chart for their own needs.

---

## Account Codes Are Organization-Scoped

This is allowed:

```txt
Company A: 6050 Office Supplies
Company B: 6050 Office Supplies
```

This is not allowed:

```txt
Company A: 6050 Office Supplies
Company A: 6050 Stationery
```

---

## Active vs Inactive

Active accounts can be used for future postings.

Inactive accounts stay visible for history but should not be used for new transactions.

---

# Part 11 Completion Checklist

You are ready for Part 12 if:

- [ ] `services/accounts/mutate-accounts.ts` exists
- [ ] Account creation is validated server-side
- [ ] Account creation is scoped to the active organization
- [ ] Duplicate account codes are rejected per organization
- [ ] `app/accounts/actions.ts` includes create/deactivate/reactivate actions
- [ ] `components/account-status-banner.tsx` exists
- [ ] `components/account-create-form.tsx` exists
- [ ] `components/account-group-table.tsx` exists
- [ ] `/accounts` shows seeded accounts grouped by type
- [ ] `/accounts` can create a custom account
- [ ] `/accounts` can deactivate an account
- [ ] `/accounts` can reactivate an account
- [ ] `/settings/database/accounts` shows active/inactive counts
- [ ] Neon SQL confirms custom account rows
- [ ] Tenant isolation is preserved by organization
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
