# Part 13 — Build the Core `postJournalEntry()` Function

In Part 12, we created the database tables for the ledger:

```txt
journal_entries
journal_lines
```

Now we build the function that writes to those tables safely.

This is the most important accounting function in the application so far.

By the end of this part, you will have:

- A production-minded `postJournalEntry()` service
- Server-side journal entry validation
- Balanced debit/credit enforcement
- Active organization enforcement
- Active account enforcement
- Account ownership checks
- Transactional journal posting
- Clear typed errors
- Updated journal diagnostics
- A foundation ready for manual testing in Part 14

We will **not** build the manual journal posting UI yet.

That comes in **Part 14**.

This part focuses on the core engine.

---

# 1. Understand the Role of `postJournalEntry()`

## The Target

We are building the central service that safely posts journal entries.

The function will eventually be used by:

```txt
Manual journal entries
Invoices
Bills
Customer payments
Vendor payments
Bank imports
Reversals
Recurring invoices
System adjustments
```

---

## The Concept

Think of `postJournalEntry()` as the chief accountant.

A form can ask to record something, but the chief accountant checks:

```txt
Is there an active company?
Do all accounts belong to that company?
Are all accounts active?
Are amounts valid integer cents?
Does every line have exactly one side?
Do total debits equal total credits?
```

Only after those checks pass does the entry get written to the ledger.

The most important rule is:

```txt
Total debits must equal total credits.
```

If that rule fails, the function must reject the entry.

---

## The Implementation

The posting flow will look like this:

```txt
postJournalEntry()
  |
  |-- validate input shape
  |-- require active organization
  |-- verify accounts belong to active organization
  |-- verify accounts are active
  |-- calculate total debits and credits
  |-- reject if unbalanced
  |-- insert journal entry
  |-- insert journal lines
  |-- return posted entry and lines
```

The database already has line-level constraints from Part 12.

But the service layer will enforce the full entry-level balance rule.

---

## The Verification

At the end of this part:

```bash
pnpm check
```

should pass.

And the app should still load:

```txt
/settings/database/journal
```

The journal counts will still usually be zero because we are not posting test entries until Part 14.

---

# 2. Create Journal Error Types

## The Target

We are creating:

```txt
services/journal/journal-errors.ts
```

This file defines a specific error class for journal validation failures.

---

## The Concept

Not all errors are the same.

A database connection failure is different from a user submitting an unbalanced journal entry.

So we create a custom error type:

```ts
JournalEntryValidationError
```

This lets future UI code show helpful validation messages instead of a generic crash.

Think of it like a form rejection slip that lists exactly what needs to be fixed.

---

## The Implementation

Create:

```txt
services/journal/journal-errors.ts
```

Add:

```ts
// services/journal/journal-errors.ts

/**
 * Error thrown when a journal entry fails accounting validation.
 *
 * We keep a list of issues so UI pages and server actions can show helpful
 * messages to the user.
 */
export class JournalEntryValidationError extends Error {
  readonly issues: string[];

  constructor(issues: string[]) {
    super(issues.join(" "));
    this.name = "JournalEntryValidationError";
    this.issues = issues;
  }
}

/**
 * Type guard for safely checking whether an unknown error is a journal
 * validation error.
 */
export function isJournalEntryValidationError(
  error: unknown,
): error is JournalEntryValidationError {
  return error instanceof JournalEntryValidationError;
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

# 3. Build the Journal Posting Service

## The Target

We are creating:

```txt
services/journal/post-journal-entry.ts
```

This file contains the core posting function.

---

## The Concept

This is the heart of the accounting engine.

The service should be strict because financial data must be trustworthy.

Important rules:

```txt
A journal entry must have a date.
A journal entry must have a memo.
A journal entry must have at least two lines.
Every line must reference an account.
Debit and credit values must be integer cents.
Amounts cannot be negative.
Each line must have exactly one side.
Total debits must equal total credits.
Total amount must be greater than zero.
Accounts must belong to the active organization.
Accounts must be active.
```

This service will write everything in one database transaction.

A transaction means:

> Either all database changes succeed together, or none of them are saved.

That matters because we never want this situation:

```txt
journal_entries row inserted
but journal_lines failed
```

That would create a broken ledger entry.

---

## The Implementation

Create:

```txt
services/journal/post-journal-entry.ts
```

Add:

```ts
// services/journal/post-journal-entry.ts

import { auth } from "@clerk/nextjs/server";
import { and, eq, inArray } from "drizzle-orm";
import { db } from "@/db";
import {
  accounts,
  journalEntries,
  journalLines,
  journalSourceTypeEnum,
  type Account,
  type JournalEntry,
  type JournalLine,
} from "@/db/schema";
import type { MoneyCents } from "@/lib/money";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";
import { JournalEntryValidationError } from "@/services/journal/journal-errors";

export type JournalSourceType =
  (typeof journalSourceTypeEnum.enumValues)[number];

export type PostJournalEntryLineInput = {
  accountId: string;
  description?: string | null;
  debitCents?: MoneyCents;
  creditCents?: MoneyCents;
};

export type PostJournalEntryInput = {
  entryDate: string;
  memo: string;
  sourceType?: JournalSourceType;
  sourceId?: string | null;
  lines: PostJournalEntryLineInput[];
};

export type PostedJournalEntryResult = {
  journalEntry: JournalEntry;
  journalLines: JournalLine[];
  totalDebitCents: MoneyCents;
  totalCreditCents: MoneyCents;
};

type NormalizedJournalLineInput = {
  accountId: string;
  description: string | null;
  debitCents: MoneyCents;
  creditCents: MoneyCents;
};

type NormalizedJournalEntryInput = {
  entryDate: string;
  memo: string;
  sourceType: JournalSourceType;
  sourceId: string | null;
  lines: NormalizedJournalLineInput[];
};

const validJournalSourceTypes = journalSourceTypeEnum.enumValues;

const uuidRegex =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isValidUuid(value: string): boolean {
  return uuidRegex.test(value);
}

function isValidDateString(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }

  const parsed = new Date(`${value}T00:00:00.000Z`);

  if (Number.isNaN(parsed.getTime())) {
    return false;
  }

  /**
   * This prevents JavaScript date normalization from accepting impossible dates.
   *
   * Example:
   *   new Date("2026-02-31") normalizes into March.
   */
  return parsed.toISOString().slice(0, 10) === value;
}

function isIntegerCents(value: number): boolean {
  return Number.isInteger(value) && Number.isSafeInteger(value);
}

function normalizeOptionalText(value: string | null | undefined): string | null {
  const normalized = value?.trim() ?? "";

  return normalized.length > 0 ? normalized : null;
}

function normalizeJournalEntryInput(
  input: PostJournalEntryInput,
): NormalizedJournalEntryInput {
  return {
    entryDate: input.entryDate.trim(),
    memo: input.memo.trim(),
    sourceType: input.sourceType ?? "manual",
    sourceId: normalizeOptionalText(input.sourceId),
    lines: input.lines.map((line) => ({
      accountId: line.accountId.trim(),
      description: normalizeOptionalText(line.description),
      debitCents: line.debitCents ?? 0,
      creditCents: line.creditCents ?? 0,
    })),
  };
}

function validateNormalizedInput(input: NormalizedJournalEntryInput): {
  totalDebitCents: MoneyCents;
  totalCreditCents: MoneyCents;
  issues: string[];
} {
  const issues: string[] = [];

  if (!isValidDateString(input.entryDate)) {
    issues.push("Journal entry date must be a valid YYYY-MM-DD date.");
  }

  if (!input.memo) {
    issues.push("Journal entry memo is required.");
  }

  if (input.memo.length > 500) {
    issues.push("Journal entry memo must be 500 characters or fewer.");
  }

  if (!validJournalSourceTypes.includes(input.sourceType)) {
    issues.push("Journal entry source type is invalid.");
  }

  if (input.sourceId && !isValidUuid(input.sourceId)) {
    issues.push("Journal entry source ID must be a valid UUID when provided.");
  }

  if (input.lines.length < 2) {
    issues.push("A journal entry must contain at least two lines.");
  }

  let totalDebitCents = 0;
  let totalCreditCents = 0;

  input.lines.forEach((line, index) => {
    const lineNumber = index + 1;

    if (!line.accountId) {
      issues.push(`Line ${lineNumber}: account ID is required.`);
    } else if (!isValidUuid(line.accountId)) {
      issues.push(`Line ${lineNumber}: account ID must be a valid UUID.`);
    }

    if (!isIntegerCents(line.debitCents)) {
      issues.push(`Line ${lineNumber}: debit must be integer cents.`);
    }

    if (!isIntegerCents(line.creditCents)) {
      issues.push(`Line ${lineNumber}: credit must be integer cents.`);
    }

    if (line.debitCents < 0) {
      issues.push(`Line ${lineNumber}: debit cannot be negative.`);
    }

    if (line.creditCents < 0) {
      issues.push(`Line ${lineNumber}: credit cannot be negative.`);
    }

    if (line.debitCents > 0 && line.creditCents > 0) {
      issues.push(
        `Line ${lineNumber}: a line cannot have both debit and credit amounts.`,
      );
    }

    if (line.debitCents === 0 && line.creditCents === 0) {
      issues.push(
        `Line ${lineNumber}: a line must have either a debit or a credit amount.`,
      );
    }

    if (line.description && line.description.length > 500) {
      issues.push(`Line ${lineNumber}: description must be 500 characters or fewer.`);
    }

    totalDebitCents += line.debitCents;
    totalCreditCents += line.creditCents;
  });

  if (totalDebitCents !== totalCreditCents) {
    issues.push(
      `Journal entry is unbalanced: debits total ${totalDebitCents} cents but credits total ${totalCreditCents} cents.`,
    );
  }

  if (totalDebitCents === 0 && totalCreditCents === 0) {
    issues.push("Journal entry total must be greater than zero.");
  }

  return {
    totalDebitCents,
    totalCreditCents,
    issues,
  };
}

function validateAccountsForPosting(params: {
  lines: NormalizedJournalLineInput[];
  accountRows: Account[];
}): string[] {
  const issues: string[] = [];

  const accountById = new Map(
    params.accountRows.map((account) => [account.id, account]),
  );

  params.lines.forEach((line, index) => {
    const lineNumber = index + 1;
    const account = accountById.get(line.accountId);

    if (!account) {
      issues.push(
        `Line ${lineNumber}: account does not exist for the active organization.`,
      );
      return;
    }

    if (!account.isActive) {
      issues.push(
        `Line ${lineNumber}: account ${account.code} ${account.name} is inactive.`,
      );
    }
  });

  return issues;
}

/**
 * Posts a balanced journal entry for the currently active organization.
 *
 * This is the core accounting write function.
 *
 * It is intentionally strict:
 * - validates entry shape
 * - enforces balanced debits and credits
 * - verifies accounts belong to the active organization
 * - verifies accounts are active
 * - writes entry and lines in one transaction
 */
export async function postJournalEntry(
  rawInput: PostJournalEntryInput,
): Promise<PostedJournalEntryResult> {
  const organization = await requireCurrentDatabaseOrganization();
  const { userId } = await auth();

  const input = normalizeJournalEntryInput(rawInput);

  const validation = validateNormalizedInput(input);

  if (validation.issues.length > 0) {
    throw new JournalEntryValidationError(validation.issues);
  }

  const distinctAccountIds = [
    ...new Set(input.lines.map((line) => line.accountId)),
  ];

  const result = await db.transaction(async (tx) => {
    const accountRows = await tx
      .select()
      .from(accounts)
      .where(
        and(
          eq(accounts.organizationId, organization.id),
          inArray(accounts.id, distinctAccountIds),
        ),
      );

    const accountIssues = validateAccountsForPosting({
      lines: input.lines,
      accountRows,
    });

    if (accountIssues.length > 0) {
      throw new JournalEntryValidationError(accountIssues);
    }

    const [createdJournalEntry] = await tx
      .insert(journalEntries)
      .values({
        organizationId: organization.id,
        entryDate: input.entryDate,
        memo: input.memo,
        sourceType: input.sourceType,
        sourceId: input.sourceId,
        postedByUserId: userId ?? null,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
      .returning();

    if (!createdJournalEntry) {
      throw new Error("Journal entry could not be created.");
    }

    const lineValues = input.lines.map((line, index) => ({
      journalEntryId: createdJournalEntry.id,
      organizationId: organization.id,
      accountId: line.accountId,
      lineNumber: index + 1,
      description: line.description,
      debitCents: line.debitCents,
      creditCents: line.creditCents,
      createdAt: new Date(),
    }));

    const createdJournalLines = await tx
      .insert(journalLines)
      .values(lineValues)
      .returning();

    return {
      journalEntry: createdJournalEntry,
      journalLines: createdJournalLines,
      totalDebitCents: validation.totalDebitCents,
      totalCreditCents: validation.totalCreditCents,
    };
  });

  return result;
}
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

If TypeScript complains about `db.transaction`, make sure your Drizzle and Neon packages are up to date:

```bash
pnpm add drizzle-orm@latest @neondatabase/serverless@latest
pnpm add -D drizzle-kit@latest
pnpm build
```

---

# 4. Add Journal Query Helpers

## The Target

We are creating:

```txt
services/journal/get-journal-entries.ts
```

This helper will load recent journal entries with their lines.

---

## The Concept

Posting entries is only half the story.

We also need to read them back.

A journal entry without its lines is like a receipt envelope without the receipts inside.

This helper will be useful in Part 14 when we manually test the journal engine.

---

## The Implementation

Create:

```txt
services/journal/get-journal-entries.ts
```

Add:

```ts
// services/journal/get-journal-entries.ts

import { asc, desc, eq, inArray } from "drizzle-orm";
import { db } from "@/db";
import { accounts, journalEntries, journalLines } from "@/db/schema";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

export type JournalEntryWithLines = {
  id: string;
  entryDate: string;
  memo: string;
  sourceType: string;
  sourceId: string | null;
  postedByUserId: string | null;
  createdAt: Date;
  lines: Array<{
    id: string;
    lineNumber: number;
    description: string | null;
    debitCents: number;
    creditCents: number;
    account: {
      id: string;
      code: string;
      name: string;
      type: string;
    };
  }>;
};

/**
 * Lists recent journal entries for the currently active organization.
 *
 * This function is tenant-safe because it always filters by the active
 * database organization.
 */
export async function listRecentCurrentOrganizationJournalEntries(
  limit = 10,
): Promise<{
  organizationId: string | null;
  entries: JournalEntryWithLines[];
}> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return {
      organizationId: null,
      entries: [],
    };
  }

  const entryRows = await db
    .select({
      id: journalEntries.id,
      entryDate: journalEntries.entryDate,
      memo: journalEntries.memo,
      sourceType: journalEntries.sourceType,
      sourceId: journalEntries.sourceId,
      postedByUserId: journalEntries.postedByUserId,
      createdAt: journalEntries.createdAt,
    })
    .from(journalEntries)
    .where(eq(journalEntries.organizationId, organization.id))
    .orderBy(desc(journalEntries.createdAt))
    .limit(limit);

  if (entryRows.length === 0) {
    return {
      organizationId: organization.id,
      entries: [],
    };
  }

  const entryIds = entryRows.map((entry) => entry.id);

  const lineRows = await db
    .select({
      id: journalLines.id,
      journalEntryId: journalLines.journalEntryId,
      lineNumber: journalLines.lineNumber,
      description: journalLines.description,
      debitCents: journalLines.debitCents,
      creditCents: journalLines.creditCents,
      accountId: accounts.id,
      accountCode: accounts.code,
      accountName: accounts.name,
      accountType: accounts.type,
    })
    .from(journalLines)
    .innerJoin(accounts, eq(journalLines.accountId, accounts.id))
    .where(
      inArray(journalLines.journalEntryId, entryIds),
    )
    .orderBy(asc(journalLines.lineNumber));

  const linesByEntryId = new Map<string, JournalEntryWithLines["lines"]>();

  for (const line of lineRows) {
    const lines = linesByEntryId.get(line.journalEntryId) ?? [];

    lines.push({
      id: line.id,
      lineNumber: line.lineNumber,
      description: line.description,
      debitCents: line.debitCents,
      creditCents: line.creditCents,
      account: {
        id: line.accountId,
        code: line.accountCode,
        name: line.accountName,
        type: line.accountType,
      },
    });

    linesByEntryId.set(line.journalEntryId, lines);
  }

  return {
    organizationId: organization.id,
    entries: entryRows.map((entry) => ({
      ...entry,
      lines: linesByEntryId.get(entry.id) ?? [],
    })),
  };
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

# 5. Update Journal Diagnostics to Include Recent Entries with Lines

## The Target

We are updating:

```txt
app/settings/database/journal/page.tsx
```

to show recent journal entries with their lines when entries exist.

At the end of this part, the list will probably still be empty.

But this prepares the page for Part 14.

---

## The Concept

A diagnostic page should not only count rows.

It should help us inspect the rows.

After Part 14, we will post manual test entries and see them here.

---

## The Implementation

Open:

```txt
app/settings/database/journal/page.tsx
```

Replace the entire file with:

```tsx
// app/settings/database/journal/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { formatMoney } from "@/lib/money";
import { getCurrentOrganizationJournalDiagnostics } from "@/services/journal/get-journal-diagnostics";
import { listRecentCurrentOrganizationJournalEntries } from "@/services/journal/get-journal-entries";

export const dynamic = "force-dynamic";

export default async function DatabaseJournalPage() {
  const diagnostics = await getCurrentOrganizationJournalDiagnostics();
  const recentJournalEntries =
    await listRecentCurrentOrganizationJournalEntries(10);

  return (
    <AppLayout
      title="Database Journal"
      description="Inspect journal entry and journal line table readiness for the active database organization."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
              Journal schema
            </p>

            <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
              Journal database readiness
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
              This page confirms that the <code>journal_entries</code> and{" "}
              <code>journal_lines</code> tables exist and can be queried for the
              active organization.
            </p>
          </div>

          <div className="flex flex-wrap gap-2">
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
        </div>

        {diagnostics.organizationId ? (
          <div className="mt-6 grid gap-4 lg:grid-cols-3">
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 lg:col-span-3">
              <p className="text-sm font-semibold text-slate-700">
                Active database organization ID
              </p>

              <p className="mt-1 break-all font-mono text-xs text-slate-500">
                {diagnostics.organizationId}
              </p>
            </div>

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

            <div className="rounded-xl bg-amber-50 p-4">
              <p className="text-sm font-semibold text-amber-700">
                Engine status
              </p>
              <p className="mt-2 text-sm leading-6 text-amber-800">
                The <code>postJournalEntry()</code> service now exists. Manual
                posting UI arrives in Part 14.
              </p>
            </div>
          </div>
        ) : (
          <div className="mt-6 rounded-2xl border border-amber-200 bg-amber-50 p-5">
            <p className="text-sm font-semibold text-amber-800">
              No active organization selected.
            </p>

            <p className="mt-2 text-sm leading-6 text-amber-700">
              Create or select a company workspace before viewing journal
              diagnostics.
            </p>

            <Link
              href="/onboarding/organization"
              className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-amber-700"
            >
              Create company workspace
            </Link>
          </div>
        )}
      </section>

      {diagnostics.organizationId &&
      recentJournalEntries.entries.length > 0 ? (
        <section className="mt-6 space-y-6">
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
      ) : diagnostics.organizationId ? (
        <section className="mt-6 rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
          <h3 className="text-lg font-semibold text-slate-950">
            No journal entries yet
          </h3>

          <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
            This is expected until we manually post entries in Part 14. The
            posting service exists now, but no UI calls it yet.
          </p>
        </section>
      ) : null}
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
http://localhost:3000/settings/database/journal
```

You should see:

```txt
The postJournalEntry() service now exists. Manual posting UI arrives in Part 14.
```

Journal counts will likely still be:

```txt
0
```

That is correct.

---

# 6. Create a Developer Reference Page for the Journal Engine

## The Target

We are creating:

```txt
app/reports/journal-engine/page.tsx
```

This page explains the `postJournalEntry()` rules.

---

## The Concept

Before we expose manual posting in Part 14, we create a reference page that documents how the engine works.

This is useful because the journal engine is the most important accounting layer.

Think of this page as the operating manual for the chief accountant function.

---

## The Implementation

Create the folder:

```bash
mkdir -p app/reports/journal-engine
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/reports/journal-engine
```

Create:

```txt
app/reports/journal-engine/page.tsx
```

Add:

```tsx
// app/reports/journal-engine/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";

const engineRules = [
  "The user must have an active organization.",
  "The organization must be synced into the local database.",
  "The entry date must be a valid YYYY-MM-DD date.",
  "The memo is required.",
  "There must be at least two journal lines.",
  "Every line must reference a valid account.",
  "Every account must belong to the active organization.",
  "Every account must be active.",
  "Debit and credit values must be integer cents.",
  "Amounts cannot be negative.",
  "Each line must have exactly one side: debit or credit.",
  "Total debits must equal total credits.",
  "The total entry amount must be greater than zero.",
  "The entry and lines are inserted in one database transaction.",
];

export default function JournalEngineReferencePage() {
  return (
    <AppLayout
      title="Journal Engine Reference"
      description="A developer reference for the core postJournalEntry() service."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
          Core accounting engine
        </p>

        <h2 className="mt-3 text-2xl font-bold tracking-tight text-slate-950">
          `postJournalEntry()` is the heart of the ledger
        </h2>

        <p className="mt-3 max-w-4xl text-sm leading-6 text-slate-500">
          Every future accounting workflow will eventually call this service or
          a specialized wrapper around it. Invoices, bills, payments, bank
          transactions, and manual adjustments all become balanced journal
          entries.
        </p>

        <div className="mt-6 rounded-2xl bg-slate-950 p-5 text-sm leading-6 text-slate-100">
          <pre className="overflow-x-auto">
{`await postJournalEntry({
  entryDate: "2026-01-05",
  memo: "Owner contributes startup cash",
  sourceType: "manual",
  lines: [
    {
      accountId: bankAccountId,
      debitCents: 1000000,
      creditCents: 0,
    },
    {
      accountId: ownerCapitalAccountId,
      debitCents: 0,
      creditCents: 1000000,
    },
  ],
});`}
          </pre>
        </div>
      </section>

      <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-slate-950">
          Validation rules
        </h2>

        <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
          The engine rejects entries that fail any of these rules.
        </p>

        <div className="mt-6 grid gap-3 md:grid-cols-2">
          {engineRules.map((rule) => (
            <div
              key={rule}
              className="rounded-xl border border-slate-200 bg-slate-50 p-4 text-sm font-medium text-slate-700"
            >
              {rule}
            </div>
          ))}
        </div>
      </section>

      <section className="mt-6 grid gap-4 md:grid-cols-2">
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
            Revisit debits, credits, account types, normal balances, and
            balanced entries.
          </p>
        </Link>
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/reports/journal-engine
```

You should see the journal engine reference page.

---

# 7. Link the Journal Engine Reference from Reports

## The Target

We are updating:

```txt
app/reports/page.tsx
```

to link to the journal engine reference page.

---

## The Concept

The Reports area is currently also our accounting learning and diagnostics hub.

We already link to:

```txt
Double-entry accounting primer
```

Now we add:

```txt
Journal engine reference
```

---

## The Implementation

Open:

```txt
app/reports/page.tsx
```

Replace the entire file with:

```tsx
// app/reports/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { StatCard } from "@/components/stat-card";
import { formatMoney } from "@/lib/money";

export default function ReportsPage() {
  return (
    <AppLayout
      title="Reports"
      description="Financial reports summarize journal entries into useful business views."
    >
      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          title="Profit & Loss"
          value={formatMoney(642300)}
          description="Preview net profit for the current period."
          tone="emerald"
        />

        <StatCard
          title="Assets"
          value={formatMoney(5892000)}
          description="Preview total assets for the business."
          tone="sky"
        />

        <StatCard
          title="GST Payable"
          value={formatMoney(127800)}
          description="Preview GST amount owed to IRAS."
          tone="amber"
        />

        <StatCard
          title="Overdue AR"
          value={formatMoney(219900)}
          description="Preview overdue customer receivables."
          tone="rose"
        />
      </section>

      <section className="mt-6 grid gap-4 md:grid-cols-2">
        <Link
          href="/reports/accounting-primer"
          className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-700">
            Accounting foundations
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            Double-entry accounting primer
          </h2>

          <p className="mt-2 text-sm leading-6 text-emerald-800">
            Learn account types, normal balances, debits, credits, and journal
            entry validation before we build the ledger tables.
          </p>
        </Link>

        <Link
          href="/reports/journal-engine"
          className="rounded-2xl border border-purple-200 bg-purple-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-purple-700">
            Ledger engine
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            Journal engine reference
          </h2>

          <p className="mt-2 text-sm leading-6 text-purple-800">
            Review the validation rules enforced by the core
            postJournalEntry() service.
          </p>
        </Link>

        <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm md:col-span-2">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-400">
            Coming in Phase 8
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            Report modules
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            We will build Profit & Loss, Balance Sheet, Accounts Receivable
            aging, Accounts Payable aging, and GST F5-style reports from posted
            journal lines.
          </p>
        </article>
      </section>

      <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-slate-950">
          Report modules coming soon
        </h2>

        <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
          Reports will be generated from journal lines rather than copied from
          invoices or bills. This keeps reports tied to the accounting source of
          truth.
        </p>

        <div className="mt-6 grid gap-3 md:grid-cols-2">
          <div className="rounded-xl bg-slate-50 p-4 text-sm font-medium text-slate-700">
            Profit & Loss report
          </div>

          <div className="rounded-xl bg-slate-50 p-4 text-sm font-medium text-slate-700">
            Balance Sheet report
          </div>

          <div className="rounded-xl bg-slate-50 p-4 text-sm font-medium text-slate-700">
            AR/AP aging reports
          </div>

          <div className="rounded-xl bg-slate-50 p-4 text-sm font-medium text-slate-700">
            GST F5-style report
          </div>
        </div>
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/reports
```

You should see:

```txt
Journal engine reference
```

Click it.

You should arrive at:

```txt
/reports/journal-engine
```

---

# 8. Run a Compile-Time Verification

## The Target

We are verifying that the journal engine compiles.

---

## The Concept

We have not called `postJournalEntry()` from the UI yet, but TypeScript and the production build still give us useful safety checks.

This verifies:

- Imports are correct
- Drizzle table names are correct
- Types are valid
- Pages compile
- Server code builds

---

## The Implementation

Run:

```bash
pnpm check
```

---

## The Verification

The command should complete successfully.

If it fails, read the first error carefully.

Common fixes are listed below.

---

# 9. Verify Journal Diagnostic Pages

## The Target

We are checking the pages touched in this part.

---

## The Concept

Even though no journal entries are posted yet, the pages should load correctly.

---

## The Implementation

Start the dev server:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000/settings/database/journal
```

Then open:

```txt
http://localhost:3000/reports/journal-engine
```

Then open:

```txt
http://localhost:3000/reports
```

---

## The Verification

Expected results:

```txt
/settings/database/journal
```

shows journal counts and engine status.

```txt
/reports/journal-engine
```

shows validation rules.

```txt
/reports
```

links to the journal engine reference page.

---

# 10. Commit the Journal Engine Service

## The Target

We are committing the core journal posting service.

---

## The Concept

This is a major milestone.

GreyMatter Ledger now has the core service that future accounting workflows will use to write balanced ledger entries.

Even though we have not yet built the manual UI, the engine exists.

---

## The Implementation

Run:

```bash
git status
```

You should see files like:

```txt
app/reports/journal-engine/page.tsx
app/reports/page.tsx
app/settings/database/journal/page.tsx
services/journal/get-journal-entries.ts
services/journal/journal-errors.ts
services/journal/post-journal-entry.ts
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Build core journal posting service"
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

## Error: `db.transaction is not a function`

Update Drizzle packages:

```bash
pnpm add drizzle-orm@latest @neondatabase/serverless@latest
pnpm add -D drizzle-kit@latest
```

Then rerun:

```bash
pnpm check
```

If your installed Neon HTTP driver still does not support transactions in your environment, you can temporarily switch to a Postgres driver that supports transactions more explicitly in a later refactor. For this tutorial path, use current Drizzle + Neon packages.

---

## Error: `journalSourceTypeEnum.enumValues` is not found

Update Drizzle:

```bash
pnpm add drizzle-orm@latest
pnpm add -D drizzle-kit@latest
```

Then rerun:

```bash
pnpm check
```

---

## Error: `No active organization selected`

`postJournalEntry()` requires an active organization.

Create or select one:

```txt
/onboarding/organization
```

Then visit:

```txt
/dashboard
```

This ensures the organization is synced to the local database.

---

## Error: Journal posting says account does not exist

The account must belong to the active organization.

Open:

```txt
/accounts
```

Seed default accounts if needed.

Then use account IDs from the active organization.

---

## Error: Journal posting says account is inactive

Reactivate the account at:

```txt
/accounts
```

Inactive accounts cannot be used for new journal postings.

---

## Error: Journal entry is unbalanced

The sum of line debits must equal the sum of line credits.

Example valid entry:

```txt
Debit  Bank           S$100.00
Credit Sales Revenue  S$100.00
```

Example invalid entry:

```txt
Debit  Bank           S$100.00
Credit Sales Revenue   S$90.00
```

---

## Error: `sourceId` must be a UUID

The service accepts `sourceId` only when it is a valid UUID.

For manual journal entries, omit it:

```ts
sourceType: "manual"
```

or:

```ts
sourceId: null
```

---

# Phase 5 Reference — `postJournalEntry()` Rules

## Required Active Organization

The service always posts to the currently active database organization.

It does not accept arbitrary organization IDs from the browser.

This protects tenant isolation.

---

## Account Ownership Check

Every account used by a journal line must belong to the active organization.

This prevents Company A from posting to Company B’s accounts.

---

## Active Account Check

Inactive accounts cannot be used for new postings.

This preserves historical accounts while keeping new entries clean.

---

## Integer Cents

Money is stored as integer cents.

Examples:

```txt
S$100.00 = 10000
S$9.00   = 900
```

Do not pass floating-point dollar values.

---

## Exactly One Side Per Line

Each journal line must have either:

```txt
debit > 0 and credit = 0
```

or:

```txt
credit > 0 and debit = 0
```

Not both.

Not neither.

---

## Balanced Entry

The full journal entry must satisfy:

```txt
total debit cents = total credit cents
```

This is the central accounting invariant.

---

## Transactional Write

The service writes:

```txt
journal_entries
journal_lines
```

inside one transaction.

If any line insert fails, the whole entry is rolled back.

---

# Part 13 Completion Checklist

You are ready for Part 14 if:

- [ ] `services/journal/journal-errors.ts` exists
- [ ] `services/journal/post-journal-entry.ts` exists
- [ ] `postJournalEntry()` requires an active organization
- [ ] `postJournalEntry()` validates date and memo
- [ ] `postJournalEntry()` requires at least two lines
- [ ] `postJournalEntry()` validates integer cents
- [ ] `postJournalEntry()` rejects negative amounts
- [ ] `postJournalEntry()` rejects lines with both debit and credit
- [ ] `postJournalEntry()` rejects lines with neither debit nor credit
- [ ] `postJournalEntry()` rejects unbalanced entries
- [ ] `postJournalEntry()` verifies accounts belong to the active organization
- [ ] `postJournalEntry()` rejects inactive accounts
- [ ] `postJournalEntry()` inserts entry and lines in a transaction
- [ ] `services/journal/get-journal-entries.ts` exists
- [ ] `/settings/database/journal` loads
- [ ] `/reports/journal-engine` loads
- [ ] `/reports` links to the journal engine reference
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
