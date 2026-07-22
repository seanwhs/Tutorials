# Part 8 — Double-Entry Accounting for Developers: Core Concepts

Before we create the chart of accounts schema in Part 9, we need to understand the accounting model we are about to encode.

This part is intentionally half-conceptual and half-code.

By the end of this part, you will have:

- A developer-friendly mental model for double-entry accounting
- TypeScript types for accounting account categories
- Pure accounting helper functions
- A journal entry validation helper
- A protected accounting primer page inside the app
- A small visual explanation of debits, credits, normal balances, and balanced entries

This part does **not** write to the database yet.

That is intentional.

Before putting accounting rules into Postgres, we first build small pure TypeScript helpers that explain the rules clearly.

---

# 1. Understand the Accounting Equation

## The Target

We are learning the basic equation behind double-entry accounting.

---

## The Concept

The central accounting equation is:

```txt
Assets = Liabilities + Equity
```

In plain language:

```txt
What the business owns = what the business owes + what belongs to owners
```

Example:

```txt
Business bank account:        S$10,000
Loan owed to bank:            S$4,000
Owner's remaining interest:   S$6,000
```

So:

```txt
Assets      = Liabilities + Equity
S$10,000    = S$4,000 + S$6,000
```

This equation must always stay balanced.

Revenue and expenses affect equity:

```txt
Revenue increases equity.
Expenses decrease equity.
```

So a more expanded version is:

```txt
Assets = Liabilities + Equity + Revenue - Expenses
```

A useful developer analogy:

```txt
Accounting is like maintaining database invariants.
```

An invariant is a rule that must always remain true.

In GreyMatter Ledger, one invariant is:

```txt
Every posted journal entry must have total debits equal total credits.
```

---

## The Implementation

No database implementation yet.

But we will encode this accounting worldview in TypeScript in later steps.

The categories we need are:

```txt
asset
liability
equity
income
expense
```

Those five account categories are enough to power the core ledger.

---

## The Verification

You should understand this before moving forward:

```txt
Assets are things the company owns.
Liabilities are things the company owes.
Equity is the owner's claim after liabilities.
Income increases business value.
Expenses decrease business value.
```

---

# 2. Understand Debits and Credits

## The Target

We are learning what debit and credit mean in accounting software.

---

## The Concept

Debit and credit are not the same as “good” and “bad.”

They are directions.

Think of every account as a bucket with a preferred fill direction.

Some accounts increase with debits.

Some accounts increase with credits.

This is called the account’s **normal balance**.

| Account Type | Normal Balance | Increases With | Decreases With |
|---|---:|---:|---:|
| Asset | Debit | Debit | Credit |
| Expense | Debit | Debit | Credit |
| Liability | Credit | Credit | Debit |
| Equity | Credit | Credit | Debit |
| Income | Credit | Credit | Debit |

Common memory shortcut:

```txt
Assets and expenses normally increase with debits.
Liabilities, equity, and income normally increase with credits.
```

Examples:

When cash increases:

```txt
Debit Bank
```

Because bank is an asset.

When sales revenue increases:

```txt
Credit Sales Revenue
```

Because revenue is an income account.

When GST payable increases:

```txt
Credit GST Payable
```

Because GST payable is a liability.

---

## The Implementation

We will now create TypeScript definitions for these account types.

---

# 3. Create Accounting Type Definitions

## The Target

We are creating:

```txt
lib/accounting/types.ts
```

This file defines the core accounting vocabulary used by code.

---

## The Concept

TypeScript types are like labels on boxes.

If we clearly label the boxes, we are less likely to put the wrong thing inside.

For accounting software, this matters a lot.

We want TypeScript to understand that an account type can only be one of these exact values:

```txt
asset
liability
equity
income
expense
```

Not:

```txt
assets
profit
bank_account
random_text
```

---

## The Implementation

Create the folder:

```bash
mkdir -p lib/accounting
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force lib/accounting
```

Create:

```txt
lib/accounting/types.ts
```

Add:

```ts
// lib/accounting/types.ts

import type { MoneyCents } from "@/lib/money";

/**
 * The five core account types used in double-entry accounting.
 *
 * These categories are enough to build:
 * - Chart of accounts
 * - Journal entries
 * - Profit & Loss
 * - Balance Sheet
 * - GST reports
 */
export type AccountType =
  | "asset"
  | "liability"
  | "equity"
  | "income"
  | "expense";

/**
 * Debit or credit direction.
 *
 * Debit and credit are accounting directions, not "good" or "bad".
 */
export type EntrySide = "debit" | "credit";

/**
 * A small account shape used for educational previews.
 *
 * Later, real accounts will come from the database.
 */
export type AccountingPreviewAccount = {
  code: string;
  name: string;
  type: AccountType;
};

/**
 * A journal line represents one debit or credit movement.
 *
 * Rules:
 * - debitCents and creditCents are integer cents
 * - exactly one side should be greater than zero
 * - both sides cannot be positive
 * - both sides cannot be zero
 */
export type JournalPreviewLine = {
  account: AccountingPreviewAccount;
  debitCents: MoneyCents;
  creditCents: MoneyCents;
  memo?: string;
};

/**
 * A journal entry is a collection of lines that must balance.
 */
export type JournalPreviewEntry = {
  date: string;
  memo: string;
  lines: JournalPreviewLine[];
};

/**
 * Validation result for a journal entry preview.
 */
export type JournalValidationResult =
  | {
      ok: true;
      totalDebitCents: MoneyCents;
      totalCreditCents: MoneyCents;
      lineCount: number;
    }
  | {
      ok: false;
      totalDebitCents: MoneyCents;
      totalCreditCents: MoneyCents;
      lineCount: number;
      errors: string[];
    };
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

This file is not used yet, so there is no browser change.

---

# 4. Encode Normal Balance Rules

## The Target

We are creating:

```txt
lib/accounting/normal-balance.ts
```

This file explains whether each account type normally increases with a debit or a credit.

---

## The Concept

Normal balance is the “natural increase side” of an account.

Think of it like knowing which side of a scoreboard goes up when something happens.

Examples:

```txt
Bank increases with debit.
Sales Revenue increases with credit.
Accounts Payable increases with credit.
Rent Expense increases with debit.
```

Encoding this in TypeScript lets us explain accounting behavior consistently across the app.

---

## The Implementation

Create:

```txt
lib/accounting/normal-balance.ts
```

Add:

```ts
// lib/accounting/normal-balance.ts

import type { AccountType, EntrySide } from "@/lib/accounting/types";

/**
 * The normal balance side for each account type.
 *
 * Asset and expense accounts normally increase with debits.
 * Liability, equity, and income accounts normally increase with credits.
 */
export const normalBalanceByAccountType: Record<AccountType, EntrySide> = {
  asset: "debit",
  expense: "debit",
  liability: "credit",
  equity: "credit",
  income: "credit",
};

/**
 * Returns the normal balance side for an account type.
 */
export function getNormalBalance(accountType: AccountType): EntrySide {
  return normalBalanceByAccountType[accountType];
}

/**
 * Returns true if the provided side increases the given account type.
 */
export function doesSideIncreaseAccountType(
  accountType: AccountType,
  side: EntrySide,
): boolean {
  return getNormalBalance(accountType) === side;
}

/**
 * Returns a beginner-friendly explanation for an account type.
 */
export function explainAccountType(accountType: AccountType): string {
  const normalBalance = getNormalBalance(accountType);

  switch (accountType) {
    case "asset":
      return `Assets are things the business owns. They normally increase with ${normalBalance}s.`;

    case "liability":
      return `Liabilities are things the business owes. They normally increase with ${normalBalance}s.`;

    case "equity":
      return `Equity is the owner's residual claim in the business. It normally increases with ${normalBalance}s.`;

    case "income":
      return `Income records revenue earned by the business. It normally increases with ${normalBalance}s.`;

    case "expense":
      return `Expenses record costs incurred by the business. They normally increase with ${normalBalance}s.`;
  }
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

# 5. Build a Journal Entry Validation Helper

## The Target

We are creating:

```txt
lib/accounting/validate-journal-preview.ts
```

This file validates journal entry previews.

---

## The Concept

A journal entry is valid only when:

```txt
Total debits = total credits
```

But that is not the only rule.

A good journal validator should also check:

- There are at least two lines
- Every amount is an integer number of cents
- A line cannot have both debit and credit
- A line cannot have neither debit nor credit
- Amounts cannot be negative
- Total debit must equal total credit
- Total must be greater than zero

This is like a gatekeeper.

The user interface may be friendly, but the accounting engine must be strict.

---

## The Implementation

Create:

```txt
lib/accounting/validate-journal-preview.ts
```

Add:

```ts
// lib/accounting/validate-journal-preview.ts

import type {
  JournalPreviewEntry,
  JournalValidationResult,
} from "@/lib/accounting/types";

function isIntegerCents(value: number): boolean {
  return Number.isInteger(value);
}

/**
 * Validates a journal entry preview.
 *
 * This is an educational pure function. It does not write to the database.
 *
 * Later, the real postJournalEntry() service will enforce similar rules before
 * inserting journal entries and journal lines into Postgres.
 */
export function validateJournalPreviewEntry(
  entry: JournalPreviewEntry,
): JournalValidationResult {
  const errors: string[] = [];

  if (!entry.date.trim()) {
    errors.push("Journal entry date is required.");
  }

  if (!entry.memo.trim()) {
    errors.push("Journal entry memo is required.");
  }

  if (entry.lines.length < 2) {
    errors.push("A journal entry must contain at least two lines.");
  }

  let totalDebitCents = 0;
  let totalCreditCents = 0;

  entry.lines.forEach((line, index) => {
    const lineNumber = index + 1;

    if (!line.account.code.trim()) {
      errors.push(`Line ${lineNumber}: account code is required.`);
    }

    if (!line.account.name.trim()) {
      errors.push(`Line ${lineNumber}: account name is required.`);
    }

    if (!isIntegerCents(line.debitCents)) {
      errors.push(`Line ${lineNumber}: debit must be integer cents.`);
    }

    if (!isIntegerCents(line.creditCents)) {
      errors.push(`Line ${lineNumber}: credit must be integer cents.`);
    }

    if (line.debitCents < 0) {
      errors.push(`Line ${lineNumber}: debit cannot be negative.`);
    }

    if (line.creditCents < 0) {
      errors.push(`Line ${lineNumber}: credit cannot be negative.`);
    }

    if (line.debitCents > 0 && line.creditCents > 0) {
      errors.push(
        `Line ${lineNumber}: a line cannot have both debit and credit amounts.`,
      );
    }

    if (line.debitCents === 0 && line.creditCents === 0) {
      errors.push(
        `Line ${lineNumber}: a line must have either a debit or a credit amount.`,
      );
    }

    totalDebitCents += line.debitCents;
    totalCreditCents += line.creditCents;
  });

  if (totalDebitCents !== totalCreditCents) {
    errors.push(
      `Journal entry is unbalanced: debits are ${totalDebitCents} cents but credits are ${totalCreditCents} cents.`,
    );
  }

  if (totalDebitCents === 0 && totalCreditCents === 0) {
    errors.push("Journal entry total must be greater than zero.");
  }

  if (errors.length > 0) {
    return {
      ok: false,
      totalDebitCents,
      totalCreditCents,
      lineCount: entry.lines.length,
      errors,
    };
  }

  return {
    ok: true,
    totalDebitCents,
    totalCreditCents,
    lineCount: entry.lines.length,
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

# 6. Create Example Accounting Entries

## The Target

We are creating:

```txt
lib/accounting/examples.ts
```

This file contains realistic sample journal entries.

---

## The Concept

Examples help accounting concepts become concrete.

We will encode three examples:

1. Owner contributes cash
2. GST invoice is issued
3. Customer payment is received

These examples are not database records yet. They are teaching examples.

---

## The Implementation

Create:

```txt
lib/accounting/examples.ts
```

Add:

```ts
// lib/accounting/examples.ts

import type {
  AccountingPreviewAccount,
  JournalPreviewEntry,
} from "@/lib/accounting/types";

export const previewAccounts = {
  bank: {
    code: "1000",
    name: "Bank",
    type: "asset",
  },
  accountsReceivable: {
    code: "1100",
    name: "Accounts Receivable",
    type: "asset",
  },
  gstPayable: {
    code: "2100",
    name: "GST Payable",
    type: "liability",
  },
  ownerCapital: {
    code: "3000",
    name: "Owner Capital",
    type: "equity",
  },
  salesRevenue: {
    code: "4000",
    name: "Sales Revenue",
    type: "income",
  },
  rentExpense: {
    code: "6000",
    name: "Rent Expense",
    type: "expense",
  },
} satisfies Record<string, AccountingPreviewAccount>;

export const ownerContributionEntry: JournalPreviewEntry = {
  date: "2026-01-01",
  memo: "Owner contributes startup cash",
  lines: [
    {
      account: previewAccounts.bank,
      debitCents: 1000000,
      creditCents: 0,
      memo: "Cash deposited into company bank account",
    },
    {
      account: previewAccounts.ownerCapital,
      debitCents: 0,
      creditCents: 1000000,
      memo: "Owner capital contribution",
    },
  ],
};

export const gstInvoiceEntry: JournalPreviewEntry = {
  date: "2026-01-05",
  memo: "Invoice issued for S$109.00 including 9% GST",
  lines: [
    {
      account: previewAccounts.accountsReceivable,
      debitCents: 10900,
      creditCents: 0,
      memo: "Customer owes the full invoice amount",
    },
    {
      account: previewAccounts.salesRevenue,
      debitCents: 0,
      creditCents: 10000,
      memo: "Revenue before GST",
    },
    {
      account: previewAccounts.gstPayable,
      debitCents: 0,
      creditCents: 900,
      memo: "GST collected and payable to IRAS",
    },
  ],
};

export const customerPaymentEntry: JournalPreviewEntry = {
  date: "2026-01-12",
  memo: "Customer pays invoice for S$109.00",
  lines: [
    {
      account: previewAccounts.bank,
      debitCents: 10900,
      creditCents: 0,
      memo: "Cash received into bank",
    },
    {
      account: previewAccounts.accountsReceivable,
      debitCents: 0,
      creditCents: 10900,
      memo: "Customer receivable cleared",
    },
  ],
};

export const invalidUnbalancedEntry: JournalPreviewEntry = {
  date: "2026-01-15",
  memo: "Invalid unbalanced example",
  lines: [
    {
      account: previewAccounts.bank,
      debitCents: 10000,
      creditCents: 0,
    },
    {
      account: previewAccounts.salesRevenue,
      debitCents: 0,
      creditCents: 9000,
    },
  ],
};

export const accountingPreviewEntries = [
  ownerContributionEntry,
  gstInvoiceEntry,
  customerPaymentEntry,
  invalidUnbalancedEntry,
];
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

---

# 7. Create a Journal Preview Component

## The Target

We are creating:

```txt
components/journal-preview-card.tsx
```

This component displays a journal entry and its validation status.

---

## The Concept

We want to show journal entries in a way beginners can read.

The component will show:

- Entry memo
- Date
- Lines
- Account type
- Debit amount
- Credit amount
- Validation result

Think of this as a microscope for journal entries.

---

## The Implementation

Create:

```txt
components/journal-preview-card.tsx
```

Add:

```tsx
// components/journal-preview-card.tsx

import type { JournalPreviewEntry } from "@/lib/accounting/types";
import { validateJournalPreviewEntry } from "@/lib/accounting/validate-journal-preview";
import { formatMoney } from "@/lib/money";

type JournalPreviewCardProps = {
  entry: JournalPreviewEntry;
};

export function JournalPreviewCard({ entry }: JournalPreviewCardProps) {
  const validation = validateJournalPreviewEntry(entry);

  return (
    <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-400">
            {entry.date}
          </p>

          <h2 className="mt-2 text-lg font-semibold text-slate-950">
            {entry.memo}
          </h2>
        </div>

        {validation.ok ? (
          <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
            Balanced
          </span>
        ) : (
          <span className="rounded-full bg-rose-50 px-3 py-1 text-xs font-semibold text-rose-700">
            Invalid
          </span>
        )}
      </div>

      <div className="mt-6 overflow-hidden rounded-xl border border-slate-200">
        <table className="w-full border-collapse text-left text-sm">
          <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
            <tr>
              <th className="px-4 py-3 font-semibold">Account</th>
              <th className="px-4 py-3 font-semibold">Type</th>
              <th className="px-4 py-3 text-right font-semibold">Debit</th>
              <th className="px-4 py-3 text-right font-semibold">Credit</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-slate-200 bg-white">
            {entry.lines.map((line, index) => (
              <tr key={`${line.account.code}-${index}`}>
                <td className="px-4 py-3">
                  <div className="font-semibold text-slate-950">
                    {line.account.code} {line.account.name}
                  </div>

                  {line.memo ? (
                    <div className="mt-1 text-xs leading-5 text-slate-500">
                      {line.memo}
                    </div>
                  ) : null}
                </td>

                <td className="px-4 py-3 text-slate-600">
                  {line.account.type}
                </td>

                <td className="px-4 py-3 text-right font-medium text-slate-950">
                  {line.debitCents > 0 ? formatMoney(line.debitCents) : "—"}
                </td>

                <td className="px-4 py-3 text-right font-medium text-slate-950">
                  {line.creditCents > 0 ? formatMoney(line.creditCents) : "—"}
                </td>
              </tr>
            ))}
          </tbody>

          <tfoot className="bg-slate-50">
            <tr>
              <td className="px-4 py-3 font-bold text-slate-950" colSpan={2}>
                Total
              </td>
              <td className="px-4 py-3 text-right font-bold text-slate-950">
                {formatMoney(validation.totalDebitCents)}
              </td>
              <td className="px-4 py-3 text-right font-bold text-slate-950">
                {formatMoney(validation.totalCreditCents)}
              </td>
            </tr>
          </tfoot>
        </table>
      </div>

      {!validation.ok ? (
        <div className="mt-4 rounded-xl border border-rose-200 bg-rose-50 p-4">
          <p className="text-sm font-semibold text-rose-800">
            Validation errors
          </p>

          <ul className="mt-2 list-inside list-disc space-y-1 text-sm leading-6 text-rose-700">
            {validation.errors.map((error) => (
              <li key={error}>{error}</li>
            ))}
          </ul>
        </div>
      ) : (
        <p className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-sm leading-6 text-emerald-700">
          This journal entry is balanced because total debits equal total
          credits.
        </p>
      )}
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

# 8. Create the Accounting Primer Page

## The Target

We are creating:

```txt
app/reports/accounting-primer/page.tsx
```

This protected page teaches the accounting concepts visually.

Because it is under:

```txt
/reports
```

it is already protected by `proxy.ts`.

---

## The Concept

This page is a bridge between explanation and implementation.

It shows:

- Account types
- Normal balances
- Example journal entries
- Valid and invalid entries

This page will help readers understand why our later database tables and journal engine are structured the way they are.

---

## The Implementation

Create the folder:

```bash
mkdir -p app/reports/accounting-primer
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/reports/accounting-primer
```

Create:

```txt
app/reports/accounting-primer/page.tsx
```

Add:

```tsx
// app/reports/accounting-primer/page.tsx

import { AppLayout } from "@/components/app-layout";
import { JournalPreviewCard } from "@/components/journal-preview-card";
import {
  accountingPreviewEntries,
  previewAccounts,
} from "@/lib/accounting/examples";
import {
  explainAccountType,
  getNormalBalance,
} from "@/lib/accounting/normal-balance";
import type { AccountType } from "@/lib/accounting/types";

export default function AccountingPrimerPage() {
  const accountTypes: AccountType[] = [
    "asset",
    "liability",
    "equity",
    "income",
    "expense",
  ];

  const accounts = Object.values(previewAccounts);

  return (
    <AppLayout
      title="Double-Entry Accounting Primer"
      description="A developer-friendly explanation of account types, debits, credits, normal balances, and balanced journal entries."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
          Core equation
        </p>

        <h2 className="mt-3 text-2xl font-bold tracking-tight text-slate-950">
          Assets = Liabilities + Equity
        </h2>

        <p className="mt-3 max-w-4xl text-sm leading-6 text-slate-500">
          Double-entry accounting keeps this equation balanced. Every financial
          event is recorded as debits and credits. A journal entry is valid only
          when total debits equal total credits.
        </p>

        <div className="mt-6 grid gap-4 md:grid-cols-3">
          <div className="rounded-2xl bg-emerald-50 p-5">
            <p className="text-sm font-semibold text-emerald-700">Assets</p>
            <p className="mt-2 text-sm leading-6 text-emerald-800">
              Things the business owns, such as bank cash and customer
              receivables.
            </p>
          </div>

          <div className="rounded-2xl bg-sky-50 p-5">
            <p className="text-sm font-semibold text-sky-700">Liabilities</p>
            <p className="mt-2 text-sm leading-6 text-sky-800">
              Things the business owes, such as supplier bills and GST payable.
            </p>
          </div>

          <div className="rounded-2xl bg-amber-50 p-5">
            <p className="text-sm font-semibold text-amber-700">Equity</p>
            <p className="mt-2 text-sm leading-6 text-amber-800">
              The owner&apos;s remaining claim after liabilities are deducted
              from assets.
            </p>
          </div>
        </div>
      </section>

      <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-slate-950">
          Account types and normal balances
        </h2>

        <p className="mt-2 max-w-4xl text-sm leading-6 text-slate-500">
          Normal balance means the side that usually increases the account.
          Assets and expenses normally increase with debits. Liabilities,
          equity, and income normally increase with credits.
        </p>

        <div className="mt-6 overflow-hidden rounded-xl border border-slate-200">
          <table className="w-full border-collapse text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-4 py-3 font-semibold">Account Type</th>
                <th className="px-4 py-3 font-semibold">Normal Balance</th>
                <th className="px-4 py-3 font-semibold">Explanation</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-200 bg-white">
              {accountTypes.map((accountType) => (
                <tr key={accountType}>
                  <td className="px-4 py-3 font-semibold capitalize text-slate-950">
                    {accountType}
                  </td>

                  <td className="px-4 py-3 capitalize text-slate-700">
                    {getNormalBalance(accountType)}
                  </td>

                  <td className="px-4 py-3 text-slate-600">
                    {explainAccountType(accountType)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-slate-950">
          Example chart of accounts preview
        </h2>

        <p className="mt-2 max-w-4xl text-sm leading-6 text-slate-500">
          These are not database accounts yet. In the next parts, we will create
          real account tables and seed a Singapore-friendly chart of accounts.
        </p>

        <div className="mt-6 grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {accounts.map((account) => (
            <div
              key={account.code}
              className="rounded-xl border border-slate-200 bg-slate-50 p-4"
            >
              <p className="font-semibold text-slate-950">
                {account.code} {account.name}
              </p>

              <p className="mt-1 text-sm capitalize text-slate-500">
                {account.type} · normal {getNormalBalance(account.type)}
              </p>
            </div>
          ))}
        </div>
      </section>

      <section className="mt-6 space-y-6">
        {accountingPreviewEntries.map((entry) => (
          <JournalPreviewCard key={`${entry.date}-${entry.memo}`} entry={entry} />
        ))}
      </section>
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

Sign in and open:

```txt
http://localhost:3000/reports/accounting-primer
```

You should see:

- Core accounting equation
- Account type table
- Example chart of accounts preview
- Balanced owner contribution entry
- Balanced GST invoice entry
- Balanced payment entry
- Invalid unbalanced entry with validation errors

Now run:

```bash
pnpm build
```

The build should succeed.

---

# 9. Link the Primer from the Reports Page

## The Target

We are updating:

```txt
app/reports/page.tsx
```

to link to the accounting primer.

---

## The Concept

The Reports area is a reasonable place for accounting education and diagnostics.

Later, this page will link to real reports:

- Profit & Loss
- Balance Sheet
- AR Aging
- AP Aging
- GST F5-style report

For now, we add a card that links to the primer.

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

        <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
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

You should see a card named:

```txt
Double-entry accounting primer
```

Click it.

You should arrive at:

```txt
/reports/accounting-primer
```

---

# 10. Run the Accounting Helper Verification

## The Target

We are verifying all new accounting helper code through the app and build.

---

## The Concept

We added pure accounting logic and UI display code.

We want to verify:

- Types compile
- Normal balance rules display
- Journal validation works
- The invalid example is rejected
- The primer route loads

---

## The Implementation

Run:

```bash
pnpm check
```

Then start the app:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000/reports/accounting-primer
```

Inspect the invalid journal entry.

It should show:

```txt
Invalid
```

And a validation error similar to:

```txt
Journal entry is unbalanced: debits are 10000 cents but credits are 9000 cents.
```

---

## The Verification

This part is correct if:

- `pnpm check` succeeds
- `/reports/accounting-primer` loads
- Balanced examples show `Balanced`
- The invalid example shows `Invalid`
- The invalid example displays validation errors

---

# 11. Commit the Accounting Primer

## The Target

We are saving the accounting foundation work with Git.

---

## The Concept

This is an important conceptual and technical checkpoint.

We now have the beginning of the accounting domain layer:

```txt
lib/accounting
```

Even though it does not write to the database yet, it defines the vocabulary and rules that later services will enforce.

---

## The Implementation

Run:

```bash
git status
```

You should see files like:

```txt
app/reports/accounting-primer/page.tsx
app/reports/page.tsx
components/journal-preview-card.tsx
lib/accounting/examples.ts
lib/accounting/normal-balance.ts
lib/accounting/types.ts
lib/accounting/validate-journal-preview.ts
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Add double-entry accounting primer"
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

## Error: `/reports/accounting-primer` redirects to sign-in

That is expected if you are signed out.

The route is under `/reports`, and `/reports(.*)` is protected by `proxy.ts`.

Sign in, then try again.

---

## Error: `Cannot find module '@/lib/accounting/types'`

Make sure this file exists:

```txt
lib/accounting/types.ts
```

Also confirm `tsconfig.json` includes:

```json
"paths": {
  "@/*": ["./*"]
}
```

Restart the dev server:

```bash
Ctrl + C
pnpm dev
```

---

## Error: Invalid example does not show validation errors

Check that:

```txt
components/journal-preview-card.tsx
```

uses:

```ts
validateJournalPreviewEntry(entry)
```

Also check that `invalidUnbalancedEntry` in:

```txt
lib/accounting/examples.ts
```

has:

```ts
debitCents: 10000
creditCents: 9000
```

---

## Error: `formatMoney` throws an error

Remember that money must be passed as integer cents.

Correct:

```ts
formatMoney(10900);
```

Incorrect:

```ts
formatMoney(109.0);
```

---

# Phase 4 Reference — Double-Entry Accounting Vocabulary

## Account

An account is a category used to classify money movement.

Examples:

```txt
Bank
Accounts Receivable
GST Payable
Sales Revenue
Rent Expense
```

---

## Chart of Accounts

The chart of accounts is the full list of accounts available to a company.

We will build this in Part 9 and seed it in Part 10.

---

## Debit

A debit is one side of a journal line.

Debits increase:

```txt
Assets
Expenses
```

Debits decrease:

```txt
Liabilities
Equity
Income
```

---

## Credit

A credit is the other side of a journal line.

Credits increase:

```txt
Liabilities
Equity
Income
```

Credits decrease:

```txt
Assets
Expenses
```

---

## Journal Entry

A journal entry records a financial event.

It has:

```txt
Date
Memo
Lines
```

Every valid journal entry must balance.

---

## Journal Line

A journal line records one debit or credit to one account.

Example:

```txt
Debit Bank S$109.00
```

---

## Balanced Entry

A journal entry is balanced when:

```txt
Total debits = total credits
```

Example:

```txt
Debit  Bank           S$100
Credit Sales Revenue  S$100
```

---

## Unbalanced Entry

An entry is unbalanced when debits and credits do not match.

Example:

```txt
Debit  Bank           S$100
Credit Sales Revenue   S$90
```

This must be rejected.

---

# Part 8 Completion Checklist

You are ready for Part 9 if:

- [ ] You understand the accounting equation
- [ ] You understand that debits and credits are directions
- [ ] You understand normal balances
- [ ] `lib/accounting/types.ts` exists
- [ ] `lib/accounting/normal-balance.ts` exists
- [ ] `lib/accounting/validate-journal-preview.ts` exists
- [ ] `lib/accounting/examples.ts` exists
- [ ] `components/journal-preview-card.tsx` exists
- [ ] `/reports/accounting-primer` loads
- [ ] Balanced journal examples show `Balanced`
- [ ] Invalid journal example shows `Invalid`
- [ ] `/reports` links to the accounting primer
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
