# Part 14 — Manual Testing of the Journal Engine

In Part 13, we built the core function:

```ts
postJournalEntry()
```

That function is the heart of GreyMatter Ledger.

Now we need to prove it works.

In this part, we will manually test the journal engine through protected app pages and server actions.

By the end of this part, you will have:

- A manual journal engine test page
- Server actions that post realistic test journal entries
- A helper for finding accounts by code
- A valid owner contribution test
- A valid GST invoice test
- An invalid unbalanced entry test
- UI feedback proving invalid entries are rejected
- Journal diagnostics showing posted entries and lines
- Neon SQL verification queries
- Confidence that the journal engine is enforcing double-entry rules

This part is not the final manual journal entry UI. That will come later.

This is an engineering test harness.

Think of it as a controlled test panel for the ledger engine before we connect invoices, bills, and payments to it.

---

# 1. Understand What We Are Testing

## The Target

We are going to test whether `postJournalEntry()` correctly accepts valid entries and rejects invalid ones.

We will manually test three scenarios:

```txt
1. Owner contributes startup cash
2. GST invoice is posted
3. Invalid unbalanced entry is rejected
```

---

## The Concept

Testing an accounting engine is like testing a vault door.

You do not only check whether the door opens for the right key.

You also check whether it refuses the wrong key.

So we need both:

```txt
Positive tests = valid entries should post
Negative tests = invalid entries should fail
```

The core rule is:

```txt
Total debits must equal total credits.
```

Valid example:

```txt
Debit  Bank           S$10,000
Credit Share Capital  S$10,000
```

Invalid example:

```txt
Debit  Bank           S$100
Credit Sales Revenue   S$90
```

The invalid example must not insert anything into the database.

---

## The Implementation

The test flow will look like this:

```txt
User opens manual test page
  |
  | clicks "Post owner contribution"
  v
Server action finds Bank and Share Capital accounts
  |
  | calls postJournalEntry()
  v
Journal entry + lines are inserted

User clicks "Post invalid unbalanced entry"
  |
  | server action calls postJournalEntry()
  v
postJournalEntry() throws JournalEntryValidationError
  |
  v
No database rows inserted
```

---

## The Verification

At the end:

- Valid test entries should appear in `/settings/database/journal`
- Invalid test entries should show an error message
- Journal counts should increase only for valid entries
- Neon SQL should show balanced entries only

---

# 2. Create an Account Lookup Helper

## The Target

We are creating:

```txt
services/accounts/get-accounts-by-code.ts
```

This helper finds accounts by their account codes for the active organization.

---

## The Concept

Our test actions need account IDs.

Users think in account codes:

```txt
1000 Bank
3000 Share Capital
4000 Sales Revenue
```

But the journal engine needs database IDs:

```txt
accountId: "uuid..."
```

So we need a translator:

```txt
Account code -> database account row
```

This helper is tenant-safe because it only searches accounts for the active organization.

---

## The Implementation

Create:

```txt
services/accounts/get-accounts-by-code.ts
```

Add:

```ts
// services/accounts/get-accounts-by-code.ts

import { and, eq, inArray } from "drizzle-orm";
import { db } from "@/db";
import { accounts, type Account } from "@/db/schema";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export class MissingRequiredAccountsError extends Error {
  readonly missingCodes: string[];

  constructor(missingCodes: string[]) {
    super(`Missing required accounts: ${missingCodes.join(", ")}`);
    this.name = "MissingRequiredAccountsError";
    this.missingCodes = missingCodes;
  }
}

export function isMissingRequiredAccountsError(
  error: unknown,
): error is MissingRequiredAccountsError {
  return error instanceof MissingRequiredAccountsError;
}

/**
 * Returns accounts by code for the active organization.
 *
 * The returned map uses account code as the key.
 */
export async function getCurrentOrganizationAccountsByCode(
  codes: string[],
): Promise<Map<string, Account>> {
  const organization = await requireCurrentDatabaseOrganization();

  const normalizedCodes = [...new Set(codes.map((code) => code.trim()))];

  if (normalizedCodes.length === 0) {
    return new Map();
  }

  const accountRows = await db
    .select()
    .from(accounts)
    .where(
      and(
        eq(accounts.organizationId, organization.id),
        inArray(accounts.code, normalizedCodes),
      ),
    );

  return new Map(accountRows.map((account) => [account.code, account]));
}

/**
 * Requires specific account codes for the active organization.
 *
 * If any required account code is missing, this throws a typed error.
 */
export async function requireCurrentOrganizationAccountsByCode<
  TCode extends string,
>(codes: readonly TCode[]): Promise<Record<TCode, Account>> {
  const accountMap = await getCurrentOrganizationAccountsByCode([...codes]);

  const missingCodes = codes.filter((code) => !accountMap.has(code));

  if (missingCodes.length > 0) {
    throw new MissingRequiredAccountsError(missingCodes);
  }

  const result = {} as Record<TCode, Account>;

  for (const code of codes) {
    const account = accountMap.get(code);

    if (!account) {
      throw new MissingRequiredAccountsError([code]);
    }

    result[code] = account;
  }

  return result;
}
```

Important function:

```ts
requireCurrentOrganizationAccountsByCode()
```

This gives us a safe way to say:

> I need accounts `1000`, `3000`, and `4000`. If any are missing, stop and tell me.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

No browser change yet.

---

# 3. Create Manual Journal Test Server Actions

## The Target

We are creating:

```txt
app/settings/database/journal/manual-test/actions.ts
```

This file contains server actions that call `postJournalEntry()`.

---

## The Concept

A server action lets a button submit work to the server.

In this case, the buttons will:

- Find required accounts
- Call `postJournalEntry()`
- Redirect back to the manual test page with a status message

The database work stays on the server.

That is important because users should never send arbitrary organization IDs or trusted accounting data directly from the browser without server-side validation.

---

## The Implementation

Create the folder:

```bash
mkdir -p app/settings/database/journal/manual-test
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/settings/database/journal/manual-test
```

Create:

```txt
app/settings/database/journal/manual-test/actions.ts
```

Add:

```ts
// app/settings/database/journal/manual-test/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import {
  isMissingRequiredAccountsError,
  requireCurrentOrganizationAccountsByCode,
} from "@/services/accounts/get-accounts-by-code";
import {
  isJournalEntryValidationError,
} from "@/services/journal/journal-errors";
import { postJournalEntry } from "@/services/journal/post-journal-entry";

function revalidateJournalViews() {
  revalidatePath("/settings/database");
  revalidatePath("/settings/database/journal");
  revalidatePath("/settings/database/journal/manual-test");
}

function redirectWithStatus(status: string, message?: string): never {
  const params = new URLSearchParams({
    status,
  });

  if (message) {
    params.set("message", message);
  }

  redirect(`/settings/database/journal/manual-test?${params.toString()}`);
}

function getErrorMessage(error: unknown): string {
  if (isJournalEntryValidationError(error)) {
    return error.issues.join(" ");
  }

  if (isMissingRequiredAccountsError(error)) {
    return `Missing required account codes: ${error.missingCodes.join(
      ", ",
    )}. Seed the default chart of accounts first.`;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return "Unknown error.";
}

/**
 * Posts a valid owner contribution journal entry.
 *
 * Accounting:
 *   Debit  Bank          S$10,000
 *   Credit Share Capital S$10,000
 */
export async function postOwnerContributionTestAction() {
  try {
    const requiredAccounts = await requireCurrentOrganizationAccountsByCode([
      "1000",
      "3000",
    ] as const);

    await postJournalEntry({
      entryDate: new Date().toISOString().slice(0, 10),
      memo: "Manual test: owner contributes startup cash",
      sourceType: "manual",
      lines: [
        {
          accountId: requiredAccounts["1000"].id,
          description: "Cash deposited into company bank account",
          debitCents: 1000000,
          creditCents: 0,
        },
        {
          accountId: requiredAccounts["3000"].id,
          description: "Share capital contribution",
          debitCents: 0,
          creditCents: 1000000,
        },
      ],
    });

    revalidateJournalViews();

    redirectWithStatus(
      "posted",
      "Owner contribution test entry posted successfully.",
    );
  } catch (error) {
    revalidateJournalViews();

    redirectWithStatus("error", getErrorMessage(error));
  }
}

/**
 * Posts a valid GST invoice-style journal entry.
 *
 * Accounting:
 *   Debit  Accounts Receivable S$109
 *   Credit Sales Revenue       S$100
 *   Credit GST Output Tax      S$9
 */
export async function postGstInvoiceTestAction() {
  try {
    const requiredAccounts = await requireCurrentOrganizationAccountsByCode([
      "1100",
      "2110",
      "4000",
    ] as const);

    await postJournalEntry({
      entryDate: new Date().toISOString().slice(0, 10),
      memo: "Manual test: GST invoice for S$109.00",
      sourceType: "manual",
      lines: [
        {
          accountId: requiredAccounts["1100"].id,
          description: "Customer owes full GST-inclusive invoice amount",
          debitCents: 10900,
          creditCents: 0,
        },
        {
          accountId: requiredAccounts["4000"].id,
          description: "Revenue before GST",
          debitCents: 0,
          creditCents: 10000,
        },
        {
          accountId: requiredAccounts["2110"].id,
          description: "GST collected from customer",
          debitCents: 0,
          creditCents: 900,
        },
      ],
    });

    revalidateJournalViews();

    redirectWithStatus(
      "posted",
      "GST invoice test entry posted successfully.",
    );
  } catch (error) {
    revalidateJournalViews();

    redirectWithStatus("error", getErrorMessage(error));
  }
}

/**
 * Attempts to post an intentionally invalid unbalanced journal entry.
 *
 * This action should NOT create database rows.
 *
 * Accounting attempt:
 *   Debit  Bank          S$100
 *   Credit Sales Revenue  S$90
 *
 * Expected result:
 *   postJournalEntry() rejects it.
 */
export async function postInvalidUnbalancedTestAction() {
  try {
    const requiredAccounts = await requireCurrentOrganizationAccountsByCode([
      "1000",
      "4000",
    ] as const);

    await postJournalEntry({
      entryDate: new Date().toISOString().slice(0, 10),
      memo: "Manual test: intentionally invalid unbalanced entry",
      sourceType: "manual",
      lines: [
        {
          accountId: requiredAccounts["1000"].id,
          description: "Invalid debit side",
          debitCents: 10000,
          creditCents: 0,
        },
        {
          accountId: requiredAccounts["4000"].id,
          description: "Invalid short credit side",
          debitCents: 0,
          creditCents: 9000,
        },
      ],
    });

    revalidateJournalViews();

    redirectWithStatus(
      "unexpected",
      "The invalid entry was posted. This should not happen.",
    );
  } catch (error) {
    revalidateJournalViews();

    if (isJournalEntryValidationError(error)) {
      redirectWithStatus(
        "rejected",
        `Invalid entry correctly rejected: ${error.issues.join(" ")}`,
      );
    }

    redirectWithStatus("error", getErrorMessage(error));
  }
}
```

Important action:

```ts
postInvalidUnbalancedTestAction()
```

This should fail.

If it succeeds, the journal engine is broken.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

---

# 4. Create a Manual Test Status Banner

## The Target

We are creating:

```txt
components/journal-test-status-banner.tsx
```

This component displays feedback after test actions run.

---

## The Concept

After a server action runs, it redirects back with URL parameters like:

```txt
?status=posted&message=...
```

The banner converts those flags into helpful UI feedback.

---

## The Implementation

Create:

```txt
components/journal-test-status-banner.tsx
```

Add:

```tsx
// components/journal-test-status-banner.tsx

type JournalTestStatusBannerProps = {
  status?: string;
  message?: string;
};

const statusStyles: Record<
  string,
  {
    title: string;
    className: string;
  }
> = {
  posted: {
    title: "Journal entry posted.",
    className: "border-emerald-200 bg-emerald-50 text-emerald-800",
  },
  rejected: {
    title: "Invalid entry rejected correctly.",
    className: "border-emerald-200 bg-emerald-50 text-emerald-800",
  },
  error: {
    title: "Journal test failed.",
    className: "border-rose-200 bg-rose-50 text-rose-800",
  },
  unexpected: {
    title: "Unexpected result.",
    className: "border-rose-200 bg-rose-50 text-rose-800",
  },
};

export function JournalTestStatusBanner({
  status,
  message,
}: JournalTestStatusBannerProps) {
  if (!status) {
    return null;
  }

  const statusStyle = statusStyles[status];

  if (!statusStyle) {
    return null;
  }

  return (
    <section className={`rounded-2xl border p-5 ${statusStyle.className}`}>
      <p className="text-sm font-semibold">{statusStyle.title}</p>

      {message ? <p className="mt-2 text-sm leading-6">{message}</p> : null}
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

# 5. Create the Manual Journal Engine Test Page

## The Target

We are creating:

```txt
app/settings/database/journal/manual-test/page.tsx
```

This page lets us manually trigger test journal postings.

---

## The Concept

This page is a controlled test harness.

It is not the final journal entry form.

It gives us buttons for known test cases:

```txt
Post owner contribution
Post GST invoice
Try invalid unbalanced entry
```

The purpose is to verify the engine.

A test harness is like a mechanic’s diagnostic panel. It exposes specific controls so we can prove the machinery works.

---

## The Implementation

Create:

```txt
app/settings/database/journal/manual-test/page.tsx
```

Add:

```tsx
// app/settings/database/journal/manual-test/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { JournalTestStatusBanner } from "@/components/journal-test-status-banner";
import { formatMoney } from "@/lib/money";
import { listCurrentOrganizationAccounts } from "@/services/accounts/get-accounts";
import { getCurrentOrganizationJournalDiagnostics } from "@/services/journal/get-journal-diagnostics";
import { listRecentCurrentOrganizationJournalEntries } from "@/services/journal/get-journal-entries";
import {
  postGstInvoiceTestAction,
  postInvalidUnbalancedTestAction,
  postOwnerContributionTestAction,
} from "@/app/settings/database/journal/manual-test/actions";

export const dynamic = "force-dynamic";

type ManualJournalTestPageProps = {
  searchParams?: Promise<{
    status?: string;
    message?: string;
  }>;
};

const requiredSeedCodes = ["1000", "1100", "2110", "3000", "4000"];

export default async function ManualJournalTestPage({
  searchParams,
}: ManualJournalTestPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};

  const { organizationId, accounts } = await listCurrentOrganizationAccounts();
  const diagnostics = await getCurrentOrganizationJournalDiagnostics();
  const recentJournalEntries =
    await listRecentCurrentOrganizationJournalEntries(5);

  const accountCodes = new Set(accounts.map((account) => account.code));
  const missingRequiredCodes = requiredSeedCodes.filter(
    (code) => !accountCodes.has(code),
  );

  return (
    <AppLayout
      title="Manual Journal Engine Test"
      description="Run controlled manual tests against the core postJournalEntry() service."
    >
      <div className="space-y-6">
        <JournalTestStatusBanner
          status={resolvedSearchParams.status}
          message={resolvedSearchParams.message}
        />

        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.2em] text-purple-600">
                Test harness
              </p>

              <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
                Controlled journal posting tests
              </h2>

              <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
                These buttons call <code>postJournalEntry()</code> with known
                accounting examples. Valid examples should post. The invalid
                unbalanced example should be rejected and should not create
                journal rows.
              </p>
            </div>

            <div className="flex flex-wrap gap-2">
              <Link
                href="/settings/database/journal"
                className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
              >
                Journal diagnostics
              </Link>

              <Link
                href="/accounts"
                className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
              >
                Chart of accounts
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
                Create or select a company workspace before testing the journal
                engine.
              </p>

              <Link
                href="/onboarding/organization"
                className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-amber-700"
              >
                Create company workspace
              </Link>
            </div>
          )}

          {organizationId && missingRequiredCodes.length > 0 ? (
            <div className="mt-6 rounded-2xl border border-amber-200 bg-amber-50 p-5">
              <p className="text-sm font-semibold text-amber-800">
                Required seeded accounts are missing.
              </p>

              <p className="mt-2 text-sm leading-6 text-amber-700">
                Missing account codes:{" "}
                <span className="font-mono font-semibold">
                  {missingRequiredCodes.join(", ")}
                </span>
                . Seed the default chart of accounts before running these
                tests.
              </p>

              <Link
                href="/accounts"
                className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-amber-700"
              >
                Open chart of accounts
              </Link>
            </div>
          ) : null}
        </section>

        {organizationId && missingRequiredCodes.length === 0 ? (
          <section className="grid gap-4 lg:grid-cols-3">
            <article className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm">
              <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-700">
                Valid entry
              </p>

              <h2 className="mt-3 text-lg font-semibold text-slate-950">
                Owner contribution
              </h2>

              <p className="mt-2 text-sm leading-6 text-emerald-800">
                Posts startup cash contributed by owners.
              </p>

              <div className="mt-4 rounded-xl bg-white/70 p-4 text-sm leading-6 text-emerald-900">
                <p>Debit Bank {formatMoney(1000000)}</p>
                <p>Credit Share Capital {formatMoney(1000000)}</p>
              </div>

              <form action={postOwnerContributionTestAction} className="mt-5">
                <button
                  type="submit"
                  className="rounded-xl bg-emerald-700 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-emerald-800"
                >
                  Post owner contribution
                </button>
              </form>
            </article>

            <article className="rounded-2xl border border-sky-200 bg-sky-50 p-6 shadow-sm">
              <p className="text-sm font-semibold uppercase tracking-[0.2em] text-sky-700">
                Valid entry
              </p>

              <h2 className="mt-3 text-lg font-semibold text-slate-950">
                GST invoice
              </h2>

              <p className="mt-2 text-sm leading-6 text-sky-800">
                Posts a GST invoice for S$109 including 9% GST.
              </p>

              <div className="mt-4 rounded-xl bg-white/70 p-4 text-sm leading-6 text-sky-900">
                <p>Debit Accounts Receivable {formatMoney(10900)}</p>
                <p>Credit Sales Revenue {formatMoney(10000)}</p>
                <p>Credit GST Output Tax {formatMoney(900)}</p>
              </div>

              <form action={postGstInvoiceTestAction} className="mt-5">
                <button
                  type="submit"
                  className="rounded-xl bg-sky-700 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-sky-800"
                >
                  Post GST invoice
                </button>
              </form>
            </article>

            <article className="rounded-2xl border border-rose-200 bg-rose-50 p-6 shadow-sm">
              <p className="text-sm font-semibold uppercase tracking-[0.2em] text-rose-700">
                Invalid entry
              </p>

              <h2 className="mt-3 text-lg font-semibold text-slate-950">
                Unbalanced entry
              </h2>

              <p className="mt-2 text-sm leading-6 text-rose-800">
                Attempts to post an entry where debits do not equal credits.
                The engine should reject this.
              </p>

              <div className="mt-4 rounded-xl bg-white/70 p-4 text-sm leading-6 text-rose-900">
                <p>Debit Bank {formatMoney(10000)}</p>
                <p>Credit Sales Revenue {formatMoney(9000)}</p>
              </div>

              <form action={postInvalidUnbalancedTestAction} className="mt-5">
                <button
                  type="submit"
                  className="rounded-xl bg-rose-700 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-rose-800"
                >
                  Try invalid entry
                </button>
              </form>
            </article>
          </section>
        ) : null}

        {organizationId ? (
          <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-slate-950">
              Current journal counts
            </h2>

            <div className="mt-4 grid gap-4 md:grid-cols-2">
              <div className="rounded-xl bg-emerald-50 p-4">
                <p className="text-sm font-semibold text-emerald-700">
                  Journal entries
                </p>
                <p className="mt-2 text-3xl font-bold text-emerald-900">
                  {diagnostics.journalEntryCount}
                </p>
              </div>

              <div className="rounded-xl bg-sky-50 p-4">
                <p className="text-sm font-semibold text-sky-700">
                  Journal lines
                </p>
                <p className="mt-2 text-3xl font-bold text-sky-900">
                  {diagnostics.journalLineCount}
                </p>
              </div>
            </div>
          </section>
        ) : null}

        {organizationId && recentJournalEntries.entries.length > 0 ? (
          <section className="space-y-6">
            {recentJournalEntries.entries.map((entry) => {
              const totalDebitCents = entry.lines.reduce(
                (sum, line) => sum + line.debitCents,
                0,
              );

              const totalCreditCents = entry.lines.reduce(
                (sum, line) => sum + line.creditCents,
                0,
              );

              return (
                <article
                  key={entry.id}
                  className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"
                >
                  <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
                    <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                      <div>
                        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-400">
                          {entry.entryDate} · {entry.sourceType}
                        </p>

                        <h2 className="mt-2 text-lg font-semibold text-slate-950">
                          {entry.memo}
                        </h2>

                        <p className="mt-1 break-all font-mono text-xs text-slate-500">
                          {entry.id}
                        </p>
                      </div>

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
                  </div>

                  <div className="overflow-x-auto">
                    <table className="w-full border-collapse text-left text-sm">
                      <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                        <tr>
                          <th className="px-6 py-3 font-semibold">#</th>
                          <th className="px-6 py-3 font-semibold">Account</th>
                          <th className="px-6 py-3 font-semibold">
                            Description
                          </th>
                          <th className="px-6 py-3 text-right font-semibold">
                            Debit
                          </th>
                          <th className="px-6 py-3 text-right font-semibold">
                            Credit
                          </th>
                        </tr>
                      </thead>

                      <tbody className="divide-y divide-slate-200">
                        {entry.lines.map((line) => (
                          <tr key={line.id}>
                            <td className="px-6 py-4 text-slate-500">
                              {line.lineNumber}
                            </td>

                            <td className="px-6 py-4">
                              <div className="font-semibold text-slate-950">
                                {line.account.code} {line.account.name}
                              </div>

                              <div className="mt-1 text-xs capitalize text-slate-500">
                                {line.account.type}
                              </div>
                            </td>

                            <td className="px-6 py-4 text-slate-500">
                              {line.description ?? "—"}
                            </td>

                            <td className="px-6 py-4 text-right font-medium text-slate-950">
                              {line.debitCents > 0
                                ? formatMoney(line.debitCents)
                                : "—"}
                            </td>

                            <td className="px-6 py-4 text-right font-medium text-slate-950">
                              {line.creditCents > 0
                                ? formatMoney(line.creditCents)
                                : "—"}
                            </td>
                          </tr>
                        ))}
                      </tbody>

                      <tfoot className="bg-slate-50">
                        <tr>
                          <td
                            className="px-6 py-4 font-bold text-slate-950"
                            colSpan={3}
                          >
                            Total
                          </td>
                          <td className="px-6 py-4 text-right font-bold text-slate-950">
                            {formatMoney(totalDebitCents)}
                          </td>
                          <td className="px-6 py-4 text-right font-bold text-slate-950">
                            {formatMoney(totalCreditCents)}
                          </td>
                        </tr>
                      </tfoot>
                    </table>
                  </div>
                </article>
              );
            })}
          </section>
        ) : organizationId ? (
          <section className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
            <h3 className="text-lg font-semibold text-slate-950">
              No journal entries yet
            </h3>

            <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
              Use the test buttons above to post valid entries and verify that
              invalid entries are rejected.
            </p>
          </section>
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
http://localhost:3000/settings/database/journal/manual-test
```

If you have not seeded accounts, the page should tell you which account codes are missing.

If your chart of accounts is seeded, you should see three test cards:

```txt
Owner contribution
GST invoice
Unbalanced entry
```

---

# 6. Link the Manual Test Page from Journal Diagnostics

## The Target

We are updating:

```txt
app/settings/database/journal/page.tsx
```

to link to the manual test page.

---

## The Concept

The journal diagnostic page should lead naturally to the manual test harness.

The diagnostic page answers:

```txt
What is in the journal?
```

The manual test page answers:

```txt
Can the engine post and reject entries correctly?
```

---

## The Implementation

Open:

```txt
app/settings/database/journal/page.tsx
```

Find this button area:

```tsx
<div className="flex flex-wrap gap-2">
  <Link
    href="/settings/database"
```

Replace that whole button `<div>` with:

```tsx
<div className="flex flex-wrap gap-2">
  <Link
    href="/settings/database/journal/manual-test"
    className="rounded-xl bg-purple-700 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-purple-800"
  >
    Manual test
  </Link>

  <Link
    href="/settings/database"
    className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
  >
    Database status
  </Link>

  <Link
    href="/reports/accounting-primer"
    className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
  >
    Accounting primer
  </Link>
</div>
```

The rest of the file stays the same.

---

## The Verification

Open:

```txt
http://localhost:3000/settings/database/journal
```

You should see a button:

```txt
Manual test
```

Click it.

You should arrive at:

```txt
/settings/database/journal/manual-test
```

---

# 7. Link the Manual Test Page from the Journal Engine Reference

## The Target

We are updating:

```txt
app/reports/journal-engine/page.tsx
```

to link to the manual test page.

---

## The Concept

The journal engine reference explains the rules.

The manual test page lets us run the rules.

So they should link to each other.

---

## The Implementation

Open:

```txt
app/reports/journal-engine/page.tsx
```

Find the final grid section:

```tsx
<section className="mt-6 grid gap-4 md:grid-cols-2">
```

Replace that whole section with:

```tsx
<section className="mt-6 grid gap-4 md:grid-cols-3">
  <Link
    href="/settings/database/journal/manual-test"
    className="rounded-2xl border border-purple-200 bg-purple-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
  >
    <p className="text-sm font-semibold uppercase tracking-[0.2em] text-purple-700">
      Manual testing
    </p>

    <h2 className="mt-3 text-lg font-semibold text-slate-950">
      Run journal engine tests
    </h2>

    <p className="mt-2 text-sm leading-6 text-purple-800">
      Post valid test entries and prove that unbalanced entries are rejected.
    </p>
  </Link>

  <Link
    href="/settings/database/journal"
    className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
  >
    <p className="text-sm font-semibold uppercase tracking-[0.2em] text-purple-600">
      Diagnostics
    </p>

    <h2 className="mt-3 text-lg font-semibold text-slate-950">
      View journal database
    </h2>

    <p className="mt-2 text-sm leading-6 text-slate-500">
      Inspect journal table counts and recent entries for the active
      organization.
    </p>
  </Link>

  <Link
    href="/reports/accounting-primer"
    className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
  >
    <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-700">
      Accounting concepts
    </p>

    <h2 className="mt-3 text-lg font-semibold text-slate-950">
      Review double-entry basics
    </h2>

    <p className="mt-2 text-sm leading-6 text-emerald-800">
      Revisit debits, credits, account types, normal balances, and balanced
      entries.
    </p>
  </Link>
</section>
```

---

## The Verification

Open:

```txt
http://localhost:3000/reports/journal-engine
```

You should see:

```txt
Run journal engine tests
```

Click it.

You should arrive at:

```txt
/settings/database/journal/manual-test
```

---

# 8. Run the Manual Owner Contribution Test

## The Target

We are posting a valid owner contribution entry.

---

## The Concept

Owner contribution means the owner puts money into the company.

Accounting:

```txt
Debit  Bank           S$10,000
Credit Share Capital  S$10,000
```

Why?

- Bank is an asset. Assets increase with debits.
- Share Capital is equity. Equity increases with credits.

The entry balances:

```txt
Debit total  = S$10,000
Credit total = S$10,000
```

---

## The Implementation

Open:

```txt
http://localhost:3000/settings/database/journal/manual-test
```

Click:

```txt
Post owner contribution
```

---

## The Verification

You should see a success banner:

```txt
Journal entry posted.
Owner contribution test entry posted successfully.
```

The journal entry count should increase by:

```txt
1
```

The journal line count should increase by:

```txt
2
```

The recent journal entries section should show:

```txt
Manual test: owner contributes startup cash
```

with:

```txt
Debit  1000 Bank            S$10,000.00
Credit 3000 Share Capital   S$10,000.00
```

---

# 9. Run the Manual GST Invoice Test

## The Target

We are posting a valid GST invoice-style entry.

---

## The Concept

A GST invoice for S$109.00 including 9% GST means:

```txt
Revenue before GST: S$100.00
GST collected:       S$9.00
Customer owes:       S$109.00
```

Accounting:

```txt
Debit  Accounts Receivable  S$109.00
Credit Sales Revenue        S$100.00
Credit GST Output Tax       S$9.00
```

Why?

- Accounts Receivable is an asset. It increases with a debit.
- Sales Revenue is income. It increases with a credit.
- GST Output Tax is a liability. It increases with a credit.

The entry balances:

```txt
Debit total  = S$109.00
Credit total = S$109.00
```

---

## The Implementation

Open:

```txt
http://localhost:3000/settings/database/journal/manual-test
```

Click:

```txt
Post GST invoice
```

---

## The Verification

You should see a success banner:

```txt
GST invoice test entry posted successfully.
```

The journal entry count should increase by:

```txt
1
```

The journal line count should increase by:

```txt
3
```

The recent entries section should show:

```txt
Manual test: GST invoice for S$109.00
```

with three lines:

```txt
1100 Accounts Receivable
4000 Sales Revenue
2110 GST Output Tax
```

---

# 10. Run the Invalid Unbalanced Entry Test

## The Target

We are proving the journal engine rejects unbalanced entries.

---

## The Concept

The invalid test attempts:

```txt
Debit  Bank           S$100.00
Credit Sales Revenue   S$90.00
```

This is invalid because:

```txt
S$100 debit ≠ S$90 credit
```

The engine should throw:

```txt
JournalEntryValidationError
```

and should not insert rows.

---

## The Implementation

Before clicking, note your current journal counts on the manual test page.

For example:

```txt
Journal entries: 2
Journal lines: 5
```

Now click:

```txt
Try invalid entry
```

---

## The Verification

You should see a success-style rejection banner:

```txt
Invalid entry rejected correctly.
```

The message should include something like:

```txt
Journal entry is unbalanced: debits total 10000 cents but credits total 9000 cents.
```

The journal counts should **not** increase.

If the journal entry count increases after this invalid test, stop. That means the engine is not protecting the ledger correctly.

---

# 11. Verify Directly in Neon SQL

## The Target

We are verifying posted entries directly in Neon.

---

## The Concept

The UI is helpful, but direct database checks give deeper confidence.

We will verify:

- Journal entries exist
- Journal lines exist
- Entries balance
- No unbalanced entries were inserted

---

## The Implementation

Open Neon SQL editor.

Run:

```sql
select
  je.id,
  je.entry_date,
  je.memo,
  je.source_type,
  je.created_at
from journal_entries je
order by je.created_at desc;
```

You should see entries such as:

```txt
Manual test: owner contributes startup cash
Manual test: GST invoice for S$109.00
```

Now inspect lines:

```sql
select
  je.memo,
  jl.line_number,
  a.code,
  a.name,
  jl.debit_cents,
  jl.credit_cents
from journal_lines jl
join journal_entries je
  on je.id = jl.journal_entry_id
join accounts a
  on a.id = jl.account_id
order by je.created_at desc, jl.line_number;
```

Now run a balance check:

```sql
select
  je.id,
  je.memo,
  sum(jl.debit_cents) as total_debit_cents,
  sum(jl.credit_cents) as total_credit_cents,
  sum(jl.debit_cents) - sum(jl.credit_cents) as difference_cents
from journal_entries je
join journal_lines jl
  on jl.journal_entry_id = je.id
group by je.id, je.memo
order by je.created_at desc;
```

---

## The Verification

Every row should have:

```txt
difference_cents = 0
```

That proves every posted journal entry is balanced.

---

# 12. Verify No Invalid Entry Was Inserted

## The Target

We are checking that the invalid test did not create a journal entry.

---

## The Concept

A rejected entry should leave no trace in `journal_entries` or `journal_lines`.

The function uses a validation step before inserting, so the invalid test should not write anything.

---

## The Implementation

Run this SQL:

```sql
select
  id,
  memo,
  created_at
from journal_entries
where memo = 'Manual test: intentionally invalid unbalanced entry'
order by created_at desc;
```

---

## The Verification

This should return:

```txt
0 rows
```

If it returns a row, the invalid entry was inserted. That would be a serious bug.

---

# 13. Verify Journal Counts in App Diagnostics

## The Target

We are confirming that app diagnostics reflect database state.

---

## The Concept

The diagnostic page reads journal entries and lines for the active organization.

It should match what we see in SQL for that organization.

---

## The Implementation

Open:

```txt
http://localhost:3000/settings/database/journal
```

You should see:

```txt
Journal entries
Journal lines
```

Open:

```txt
http://localhost:3000/settings/database
```

You should see global counts:

```txt
Journal entry rows
Journal line rows
```

---

## The Verification

The journal diagnostic page should list the valid entries posted from the manual test page.

Every displayed entry should show:

```txt
Balanced
```

---

# 14. Run a Full Project Health Check

## The Target

We are confirming the project still passes linting and production build.

---

## The Concept

We added:

- Account lookup helpers
- Manual journal server actions
- Manual journal test page
- Status banner
- New diagnostic links

This touches database services, server actions, pages, and UI.

So we run the full check.

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

---

# 15. Commit the Manual Journal Tests

## The Target

We are saving this work with Git.

---

## The Concept

This is an important milestone.

We have proven that the journal engine can:

```txt
Post valid balanced entries
Reject invalid unbalanced entries
Write journal entries and lines correctly
Display posted entries in diagnostics
```

That prepares us for automated tests in Part 15.

---

## The Implementation

Run:

```bash
git status
```

You should see files like:

```txt
app/reports/journal-engine/page.tsx
app/settings/database/journal/manual-test/actions.ts
app/settings/database/journal/manual-test/page.tsx
app/settings/database/journal/page.tsx
components/journal-test-status-banner.tsx
services/accounts/get-accounts-by-code.ts
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Add manual journal engine tests"
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

## Error: Required seeded accounts are missing

Open:

```txt
/accounts
```

Click:

```txt
Seed default accounts
```

Then return to:

```txt
/settings/database/journal/manual-test
```

The manual tests require these account codes:

```txt
1000 Bank
1100 Accounts Receivable
2110 GST Output Tax
3000 Share Capital
4000 Sales Revenue
```

---

## Error: No active organization selected

Create or select a company workspace:

```txt
/onboarding/organization
```

Then open:

```txt
/dashboard
```

Then return to:

```txt
/settings/database/journal/manual-test
```

---

## Error: Account is inactive

Open:

```txt
/accounts
```

Find the missing or inactive account.

Click:

```txt
Reactivate
```

Then retry the manual journal test.

---

## Error: Invalid entry appears to post

This should not happen.

Check:

```txt
services/journal/post-journal-entry.ts
```

Make sure validation includes:

```ts
if (totalDebitCents !== totalCreditCents) {
  issues.push(...)
}
```

And make sure the service throws before the transaction if validation issues exist:

```ts
if (validation.issues.length > 0) {
  throw new JournalEntryValidationError(validation.issues);
}
```

---

## Error: Journal counts do not update immediately

The server actions call:

```ts
revalidatePath(...)
```

If the UI still looks stale, hard refresh the browser.

You can also confirm directly in Neon SQL.

---

## Error: SQL balance check shows a nonzero difference

That means an unbalanced entry exists in the database.

At this stage, if this happens in development, inspect the rows:

```sql
select
  je.id,
  je.memo,
  jl.line_number,
  a.code,
  a.name,
  jl.debit_cents,
  jl.credit_cents
from journal_entries je
join journal_lines jl
  on jl.journal_entry_id = je.id
join accounts a
  on a.id = jl.account_id
order by je.created_at desc, jl.line_number;
```

Do not proceed until you understand how the unbalanced entry was inserted.

---

## Error: `DATABASE_URL` is missing during build

Make sure `.env.local` includes:

```bash
DATABASE_URL="postgresql://..."
```

Then run:

```bash
pnpm check
```

---

# Phase 5 Reference — Manual Journal Testing

## Positive Test

A positive test proves valid data is accepted.

Example:

```txt
Debit  Bank
Credit Share Capital
```

---

## Negative Test

A negative test proves invalid data is rejected.

Example:

```txt
Debit  Bank S$100
Credit Revenue S$90
```

---

## Test Harness

A test harness is a controlled UI or script used to exercise system behavior.

The page:

```txt
/settings/database/journal/manual-test
```

is a manual test harness.

---

## Why We Test Invalid Entries

Financial systems must reject bad data.

It is not enough to prove valid entries work.

We must prove invalid entries fail safely.

---

## What We Have Proven

After this part, we have manually proven:

```txt
Valid balanced entries are inserted.
Journal lines are inserted.
Entries are tenant-scoped.
Invalid unbalanced entries are rejected.
Rejected entries do not create database rows.
Diagnostics can display posted entries.
```

---

# Part 14 Completion Checklist

You are ready for Part 15 if:

- [ ] `services/accounts/get-accounts-by-code.ts` exists
- [ ] Manual journal test server actions exist
- [ ] `components/journal-test-status-banner.tsx` exists
- [ ] `/settings/database/journal/manual-test` loads
- [ ] The page detects missing seeded accounts
- [ ] Owner contribution test posts successfully
- [ ] GST invoice test posts successfully
- [ ] Invalid unbalanced test is rejected
- [ ] Invalid test does not create database rows
- [ ] `/settings/database/journal` displays valid posted entries
- [ ] Neon SQL balance check shows `difference_cents = 0`
- [ ] Neon SQL confirms invalid entry memo does not exist
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
