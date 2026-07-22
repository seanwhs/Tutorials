# Phase 8 — Reports

# Part 24 — Build Reusable Report Helpers

We now have the core accounting flow:

```txt
Invoices
Bills
Customer payments
Vendor payments
Journal entries
Journal lines
```

Now we can build reports.

Reports should not calculate from invoice rows alone or bill rows alone.

Reports should come from the ledger.

The ledger source of truth is:

```txt
journal_entries
journal_lines
accounts
```

In this part, we will create reusable helpers that future reports will use.

By the end of this part, you will have:

- A reusable reporting date range type
- Report date validation helpers
- Ledger balance query helpers
- Account balance grouping by type
- Normal-balance-aware signed balances
- A report filters component
- A report overview diagnostic page
- Tests for report date and balance helpers

This part prepares us for:

```txt
Part 25 — Profit & Loss
Part 26 — Balance Sheet
Part 27 — AR/AP Aging
Part 28 — GST F5-style Report
```

---

# 1. Understand Ledger-Based Reporting

## The Target

We are creating shared reporting helpers.

---

## The Concept

A report is a view of the ledger.

Think of the ledger as a box of transaction receipts.

Reports are different ways of sorting those receipts.

Examples:

```txt
Profit & Loss
  = income and expenses for a period

Balance Sheet
  = assets, liabilities, and equity as of a date

GST report
  = GST output and input tax for a period

AR aging
  = unpaid customer invoices by age

AP aging
  = unpaid vendor bills by age
```

For double-entry reports, the safest source is:

```txt
journal_lines joined to accounts and journal_entries
```

That lets us compute balances from posted accounting entries.

---

## The Implementation

The report helpers will answer questions like:

```txt
What is the signed balance of each account between two dates?
What are balances grouped by account type?
Which accounts should appear on Profit & Loss?
Which accounts should appear on Balance Sheet?
```

---

## The Verification

At the end, this page should load:

```txt
/reports/ledger-overview
```

And this command should pass:

```bash
pnpm test
```

---

# 2. Create Report Types

## The Target

We are creating:

```txt
lib/reports/types.ts
```

---

## The Concept

Reports need common data shapes.

A date range is used by Profit & Loss and GST reports.

A single “as of” date is used by Balance Sheet.

Account balances appear in multiple reports.

So we define shared types.

---

## The Implementation

Create:

```bash
mkdir -p lib/reports
```

Create:

```txt
lib/reports/types.ts
```

Add:

```ts
// lib/reports/types.ts

import type { AccountType } from "@/lib/accounting/types";
import type { MoneyCents } from "@/lib/money";

export type ReportDateRange = {
  from: string;
  to: string;
};

export type AccountLedgerBalance = {
  accountId: string;
  accountCode: string;
  accountName: string;
  accountType: AccountType;
  debitCents: MoneyCents;
  creditCents: MoneyCents;
  signedBalanceCents: MoneyCents;
};

export type AccountBalancesByType = Record<AccountType, AccountLedgerBalance[]>;
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 3. Create Report Date Helpers

## The Target

We are creating:

```txt
lib/reports/date-range.ts
```

---

## The Concept

Reports depend heavily on dates.

We need safe date helpers for:

```txt
Validate YYYY-MM-DD dates
Default current year range
Parse URL search parameters
```

---

## The Implementation

Create:

```txt
lib/reports/date-range.ts
```

Add:

```ts
// lib/reports/date-range.ts

import type { ReportDateRange } from "@/lib/reports/types";

export function isValidReportDate(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }

  const parsed = new Date(`${value}T00:00:00.000Z`);

  if (Number.isNaN(parsed.getTime())) {
    return false;
  }

  return parsed.toISOString().slice(0, 10) === value;
}

export function getCurrentYearDateRange(): ReportDateRange {
  const year = new Date().getFullYear();

  return {
    from: `${year}-01-01`,
    to: `${year}-12-31`,
  };
}

export function normalizeReportDateRange(params: {
  from?: string;
  to?: string;
}): ReportDateRange {
  const fallback = getCurrentYearDateRange();

  const from =
    params.from && isValidReportDate(params.from) ? params.from : fallback.from;

  const to =
    params.to && isValidReportDate(params.to) ? params.to : fallback.to;

  if (to < from) {
    return fallback;
  }

  return {
    from,
    to,
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

# 4. Create Balance Sign Helpers

## The Target

We are creating:

```txt
lib/reports/balance-sign.ts
```

---

## The Concept

Raw ledger balances have debits and credits.

Reports often need signed balances.

For debit-normal accounts:

```txt
assets
expenses
```

signed balance is:

```txt
debits - credits
```

For credit-normal accounts:

```txt
liabilities
equity
income
```

signed balance is:

```txt
credits - debits
```

This makes report numbers easier to read.

Example:

```txt
Sales Revenue:
debits  = 0
credits = 10000
signed balance = 10000
```

---

## The Implementation

Create:

```txt
lib/reports/balance-sign.ts
```

Add:

```ts
// lib/reports/balance-sign.ts

import type { AccountType } from "@/lib/accounting/types";
import type { MoneyCents } from "@/lib/money";
import { getNormalBalance } from "@/lib/accounting/normal-balance";

export function calculateSignedBalanceCents(params: {
  accountType: AccountType;
  debitCents: MoneyCents;
  creditCents: MoneyCents;
}): MoneyCents {
  const normalBalance = getNormalBalance(params.accountType);

  if (normalBalance === "debit") {
    return params.debitCents - params.creditCents;
  }

  return params.creditCents - params.debitCents;
}

export function sumSignedBalances(
  balances: Array<{
    signedBalanceCents: MoneyCents;
  }>,
): MoneyCents {
  return balances.reduce(
    (sum, balance) => sum + balance.signedBalanceCents,
    0,
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

# 5. Create Ledger Report Query Helpers

## The Target

We are creating:

```txt
services/reports/ledger-report-services.ts
```

---

## The Concept

This service queries posted journal lines and calculates balances by account.

It is the foundation of:

```txt
Profit & Loss
Balance Sheet
GST report
```

The core query groups journal lines by account and sums:

```txt
debit_cents
credit_cents
```

Then TypeScript computes the signed balance based on account type.

---

## The Implementation

Create:

```bash
mkdir -p services/reports
```

Create:

```txt
services/reports/ledger-report-services.ts
```

Add:

```ts
// services/reports/ledger-report-services.ts

import { and, asc, eq, gte, lte, sql } from "drizzle-orm";
import { db } from "@/db";
import { accounts, journalEntries, journalLines } from "@/db/schema";
import type { AccountType } from "@/lib/accounting/types";
import { calculateSignedBalanceCents } from "@/lib/reports/balance-sign";
import type {
  AccountBalancesByType,
  AccountLedgerBalance,
  ReportDateRange,
} from "@/lib/reports/types";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

export async function getLedgerAccountBalancesForCurrentOrganization(
  dateRange: ReportDateRange,
): Promise<{
  organizationId: string | null;
  balances: AccountLedgerBalance[];
}> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return {
      organizationId: null,
      balances: [],
    };
  }

  const rows = await db
    .select({
      accountId: accounts.id,
      accountCode: accounts.code,
      accountName: accounts.name,
      accountType: accounts.type,
      debitCents:
        sql<number>`coalesce(sum(${journalLines.debitCents}), 0)`.as(
          "debit_cents",
        ),
      creditCents:
        sql<number>`coalesce(sum(${journalLines.creditCents}), 0)`.as(
          "credit_cents",
        ),
    })
    .from(journalLines)
    .innerJoin(accounts, eq(journalLines.accountId, accounts.id))
    .innerJoin(journalEntries, eq(journalLines.journalEntryId, journalEntries.id))
    .where(
      and(
        eq(journalLines.organizationId, organization.id),
        gte(journalEntries.entryDate, dateRange.from),
        lte(journalEntries.entryDate, dateRange.to),
      ),
    )
    .groupBy(accounts.id, accounts.code, accounts.name, accounts.type)
    .orderBy(asc(accounts.code));

  const balances = rows.map((row) => ({
    accountId: row.accountId,
    accountCode: row.accountCode,
    accountName: row.accountName,
    accountType: row.accountType as AccountType,
    debitCents: Number(row.debitCents),
    creditCents: Number(row.creditCents),
    signedBalanceCents: calculateSignedBalanceCents({
      accountType: row.accountType as AccountType,
      debitCents: Number(row.debitCents),
      creditCents: Number(row.creditCents),
    }),
  }));

  return {
    organizationId: organization.id,
    balances,
  };
}

export function groupBalancesByAccountType(
  balances: AccountLedgerBalance[],
): AccountBalancesByType {
  const grouped: AccountBalancesByType = {
    asset: [],
    liability: [],
    equity: [],
    income: [],
    expense: [],
  };

  for (const balance of balances) {
    grouped[balance.accountType].push(balance);
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

---

# 6. Create Report Filter Component

## The Target

We are creating:

```txt
components/report-date-range-form.tsx
```

---

## The Concept

Most reports need date filters.

This form submits with GET parameters:

```txt
?from=2026-01-01&to=2026-12-31
```

Using GET is good for reports because report URLs become shareable.

---

## The Implementation

Create:

```txt
components/report-date-range-form.tsx
```

Add:

```tsx
// components/report-date-range-form.tsx

import type { ReportDateRange } from "@/lib/reports/types";

type ReportDateRangeFormProps = {
  actionPath: string;
  dateRange: ReportDateRange;
};

export function ReportDateRangeForm({
  actionPath,
  dateRange,
}: ReportDateRangeFormProps) {
  return (
    <form
      action={actionPath}
      method="get"
      className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
    >
      <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
        Report filters
      </p>

      <div className="mt-4 grid gap-4 md:grid-cols-[1fr_1fr_auto] md:items-end">
        <label className="block">
          <span className="text-sm font-semibold text-slate-700">From</span>
          <input
            name="from"
            type="date"
            defaultValue={dateRange.from}
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-slate-700">To</span>
          <input
            name="to"
            type="date"
            defaultValue={dateRange.to}
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>

        <button
          type="submit"
          className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
        >
          Run report
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

---

# 7. Create Account Balance Table Component

## The Target

We are creating:

```txt
components/account-balance-table.tsx
```

---

## The Concept

Multiple reports need to display account balances.

So we create one reusable table.

---

## The Implementation

Create:

```txt
components/account-balance-table.tsx
```

Add:

```tsx
// components/account-balance-table.tsx

import type { AccountLedgerBalance } from "@/lib/reports/types";
import { formatMoney } from "@/lib/money";

type AccountBalanceTableProps = {
  title: string;
  balances: AccountLedgerBalance[];
};

export function AccountBalanceTable({
  title,
  balances,
}: AccountBalanceTableProps) {
  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
        <h2 className="text-lg font-semibold text-slate-950">{title}</h2>
      </div>

      {balances.length > 0 ? (
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left text-sm">
            <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-6 py-3 font-semibold">Account</th>
                <th className="px-6 py-3 text-right font-semibold">Debits</th>
                <th className="px-6 py-3 text-right font-semibold">Credits</th>
                <th className="px-6 py-3 text-right font-semibold">
                  Signed balance
                </th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-200">
              {balances.map((balance) => (
                <tr key={balance.accountId}>
                  <td className="px-6 py-4">
                    <div className="font-semibold text-slate-950">
                      {balance.accountCode} {balance.accountName}
                    </div>
                    <div className="mt-1 text-xs capitalize text-slate-500">
                      {balance.accountType}
                    </div>
                  </td>

                  <td className="px-6 py-4 text-right text-slate-600">
                    {formatMoney(balance.debitCents)}
                  </td>

                  <td className="px-6 py-4 text-right text-slate-600">
                    {formatMoney(balance.creditCents)}
                  </td>

                  <td className="px-6 py-4 text-right font-semibold text-slate-950">
                    {formatMoney(balance.signedBalanceCents)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="p-8 text-center text-sm text-slate-500">
          No balances for this section.
        </div>
      )}
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

# 8. Create Ledger Overview Report Page

## The Target

We are creating:

```txt
app/reports/ledger-overview/page.tsx
```

---

## The Concept

This is a diagnostic report that shows ledger balances grouped by account type.

It is not a formal financial statement yet.

It helps us verify that journal postings are flowing into report helpers.

---

## The Implementation

Create:

```bash
mkdir -p app/reports/ledger-overview
```

Create:

```txt
app/reports/ledger-overview/page.tsx
```

Add:

```tsx
// app/reports/ledger-overview/page.tsx

import { AccountBalanceTable } from "@/components/account-balance-table";
import { AppLayout } from "@/components/app-layout";
import { ReportDateRangeForm } from "@/components/report-date-range-form";
import { formatMoney } from "@/lib/money";
import { normalizeReportDateRange } from "@/lib/reports/date-range";
import { sumSignedBalances } from "@/lib/reports/balance-sign";
import {
  getLedgerAccountBalancesForCurrentOrganization,
  groupBalancesByAccountType,
} from "@/services/reports/ledger-report-services";

export const dynamic = "force-dynamic";

type LedgerOverviewPageProps = {
  searchParams?: Promise<{
    from?: string;
    to?: string;
  }>;
};

export default async function LedgerOverviewPage({
  searchParams,
}: LedgerOverviewPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const dateRange = normalizeReportDateRange(resolvedSearchParams);

  const { organizationId, balances } =
    await getLedgerAccountBalancesForCurrentOrganization(dateRange);

  const grouped = groupBalancesByAccountType(balances);

  const totalAssets = sumSignedBalances(grouped.asset);
  const totalLiabilities = sumSignedBalances(grouped.liability);
  const totalEquity = sumSignedBalances(grouped.equity);
  const totalIncome = sumSignedBalances(grouped.income);
  const totalExpenses = sumSignedBalances(grouped.expense);

  return (
    <AppLayout
      title="Ledger Overview"
      description="A diagnostic ledger-based report showing account balances grouped by account type."
    >
      <div className="space-y-6">
        <ReportDateRangeForm
          actionPath="/reports/ledger-overview"
          dateRange={dateRange}
        />

        {!organizationId ? (
          <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-800">
            <p className="text-sm font-semibold">
              Create or select a company workspace first.
            </p>
          </section>
        ) : null}

        {organizationId ? (
          <>
            <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
              <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
                <p className="text-sm font-semibold text-slate-500">Assets</p>
                <p className="mt-2 text-2xl font-bold text-slate-950">
                  {formatMoney(totalAssets)}
                </p>
              </div>

              <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
                <p className="text-sm font-semibold text-slate-500">
                  Liabilities
                </p>
                <p className="mt-2 text-2xl font-bold text-slate-950">
                  {formatMoney(totalLiabilities)}
                </p>
              </div>

              <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
                <p className="text-sm font-semibold text-slate-500">Equity</p>
                <p className="mt-2 text-2xl font-bold text-slate-950">
                  {formatMoney(totalEquity)}
                </p>
              </div>

              <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
                <p className="text-sm font-semibold text-slate-500">Income</p>
                <p className="mt-2 text-2xl font-bold text-slate-950">
                  {formatMoney(totalIncome)}
                </p>
              </div>

              <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
                <p className="text-sm font-semibold text-slate-500">
                  Expenses
                </p>
                <p className="mt-2 text-2xl font-bold text-slate-950">
                  {formatMoney(totalExpenses)}
                </p>
              </div>
            </section>

            <AccountBalanceTable title="Assets" balances={grouped.asset} />
            <AccountBalanceTable
              title="Liabilities"
              balances={grouped.liability}
            />
            <AccountBalanceTable title="Equity" balances={grouped.equity} />
            <AccountBalanceTable title="Income" balances={grouped.income} />
            <AccountBalanceTable title="Expenses" balances={grouped.expense} />
          </>
        ) : null}
      </div>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/reports/ledger-overview
```

You should see account balances from posted journal entries.

If you have invoices, bills, and payments, balances should appear.

---

# 9. Link Ledger Overview from Reports Page

## The Target

We are updating:

```txt
app/reports/page.tsx
```

to include ledger overview.

---

## The Implementation

Open:

```txt
app/reports/page.tsx
```

Add a card linking to:

```txt
/reports/ledger-overview
```

Use this card inside the existing grid of report links:

```tsx
<Link
  href="/reports/ledger-overview"
  className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
>
  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-600">
    Ledger
  </p>

  <h2 className="mt-3 text-lg font-semibold text-slate-950">
    Ledger overview
  </h2>

  <p className="mt-2 text-sm leading-6 text-slate-500">
    Inspect account balances grouped by type from posted journal lines.
  </p>
</Link>
```

---

## The Verification

Open:

```txt
http://localhost:3000/reports
```

Click:

```txt
Ledger overview
```

---

# 10. Add Report Helper Tests

## The Target

We are creating:

```txt
tests/report-helpers.test.ts
```

---

## The Implementation

Create:

```txt
tests/report-helpers.test.ts
```

Add:

```ts
// tests/report-helpers.test.ts

import { describe, expect, it } from "vitest";
import { calculateSignedBalanceCents } from "@/lib/reports/balance-sign";
import {
  isValidReportDate,
  normalizeReportDateRange,
} from "@/lib/reports/date-range";

describe("report date helpers", () => {
  it("accepts valid report dates", () => {
    expect(isValidReportDate("2026-01-31")).toBe(true);
  });

  it("rejects invalid report dates", () => {
    expect(isValidReportDate("2026-02-31")).toBe(false);
    expect(isValidReportDate("31/01/2026")).toBe(false);
  });

  it("falls back when date range is invalid", () => {
    const result = normalizeReportDateRange({
      from: "2026-12-31",
      to: "2026-01-01",
    });

    expect(result.from.endsWith("-01-01")).toBe(true);
    expect(result.to.endsWith("-12-31")).toBe(true);
  });
});

describe("calculateSignedBalanceCents", () => {
  it("uses debit minus credit for assets", () => {
    expect(
      calculateSignedBalanceCents({
        accountType: "asset",
        debitCents: 10000,
        creditCents: 2500,
      }),
    ).toBe(7500);
  });

  it("uses debit minus credit for expenses", () => {
    expect(
      calculateSignedBalanceCents({
        accountType: "expense",
        debitCents: 10000,
        creditCents: 2500,
      }),
    ).toBe(7500);
  });

  it("uses credit minus debit for liabilities", () => {
    expect(
      calculateSignedBalanceCents({
        accountType: "liability",
        debitCents: 2500,
        creditCents: 10000,
      }),
    ).toBe(7500);
  });

  it("uses credit minus debit for income", () => {
    expect(
      calculateSignedBalanceCents({
        accountType: "income",
        debitCents: 2500,
        creditCents: 10000,
      }),
    ).toBe(7500);
  });
});
```

---

## The Verification

Run:

```bash
pnpm test
```

---

# 11. Run Full Project Check

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

# 12. Commit Report Helpers

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Build reusable report helpers"
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

## Error: Ledger overview shows no balances

Make sure you have posted journal entries by creating invoices, bills, or payments.

Also check the date range.

---

## Error: Report date range excludes entries

Use a wider range:

```txt
from=2020-01-01
to=2030-12-31
```

---

## Error: SQL aggregation type issue

Make sure the aggregate expressions use:

```ts
sql<number>`coalesce(sum(...), 0)`
```

and convert with:

```ts
Number(row.debitCents)
```

---

# Phase 8 Reference — Report Helpers

## Ledger-Based Report

A report calculated from journal lines.

This is more reliable than calculating directly from source documents.

---

## Signed Balance

A report-friendly account balance that respects normal debit/credit behavior.

---

## Date Range

A period used for reports like Profit & Loss and GST.

---

# Part 24 Completion Checklist

You are ready for Part 25 if:

- [ ] `lib/reports/types.ts` exists
- [ ] `lib/reports/date-range.ts` exists
- [ ] `lib/reports/balance-sign.ts` exists
- [ ] `services/reports/ledger-report-services.ts` exists
- [ ] Report balances are calculated from journal lines
- [ ] Report balances are tenant-scoped
- [ ] `components/report-date-range-form.tsx` exists
- [ ] `components/account-balance-table.tsx` exists
- [ ] `/reports/ledger-overview` loads
- [ ] `/reports` links to ledger overview
- [ ] Report helper tests pass
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
