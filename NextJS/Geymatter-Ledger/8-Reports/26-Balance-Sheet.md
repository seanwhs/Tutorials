# Part 26 — Balance Sheet Report

In Part 25, we built the Profit & Loss report.

Profit & Loss answers:

```txt
Did the business make money during a period?
```

Now we build the Balance Sheet.

The Balance Sheet answers:

```txt
What does the business own, owe, and retain at a point in time?
```

The central equation is:

```txt
Assets = Liabilities + Equity
```

By the end of this part, you will have:

- Balance Sheet calculation service
- As-of date report behavior
- Asset, liability, and equity sections
- Current year earnings included in equity
- Accounting equation check
- `/reports/balance-sheet` page
- Tests for Balance Sheet logic
- Report navigation link

---

# 1. Understand the Balance Sheet

## The Target

We are creating a Balance Sheet report.

---

## The Concept

A Balance Sheet is a snapshot.

It is not mainly about a period like January.

It is about a date:

```txt
As of 2026-12-31
```

It shows:

```txt
Assets
Liabilities
Equity
```

The equation:

```txt
Assets = Liabilities + Equity
```

If the equation does not balance, something is wrong.

Examples:

```txt
Assets:
Bank                    S$10,000
Accounts Receivable     S$1,000
GST Input Tax              S$90

Liabilities:
Accounts Payable          S$500
GST Output Tax              S$90

Equity:
Share Capital          S$10,000
Current Year Earnings     S$500
```

---

# 2. Understand Current Year Earnings

## The Target

We are deciding how P&L results appear on the Balance Sheet.

---

## The Concept

Income and expenses do not appear directly as Balance Sheet sections.

Instead, their net result flows into equity.

That is:

```txt
Current Year Earnings = Income - Expenses
```

So Balance Sheet equity includes:

```txt
Share Capital
Retained Earnings
Current Year Earnings
```

This keeps the accounting equation balanced.

If the business earned profit, equity increases.

If it had a loss, equity decreases.

---

# 3. Create Balance Sheet Service

## The Target

We are creating:

```txt
services/reports/balance-sheet-service.ts
```

---

## The Concept

A Balance Sheet uses ledger balances from the beginning of time through the as-of date.

That means the report date range is:

```txt
from: 1900-01-01
to: asOfDate
```

Then it groups balances:

```txt
Assets
Liabilities
Equity
Income
Expenses
```

But the final report displays:

```txt
Assets
Liabilities
Equity + Current Year Earnings
```

---

## The Implementation

Create:

```txt
services/reports/balance-sheet-service.ts
```

Add:

```ts
// services/reports/balance-sheet-service.ts

import type { AccountLedgerBalance } from "@/lib/reports/types";
import { sumSignedBalances } from "@/lib/reports/balance-sign";
import {
  getLedgerAccountBalancesForCurrentOrganization,
  groupBalancesByAccountType,
} from "@/services/reports/ledger-report-services";

export type BalanceSheetReport = {
  organizationId: string | null;
  asOfDate: string;
  assets: AccountLedgerBalance[];
  liabilities: AccountLedgerBalance[];
  equity: AccountLedgerBalance[];
  totalAssetsCents: number;
  totalLiabilitiesCents: number;
  totalEquityCents: number;
  currentYearEarningsCents: number;
  totalLiabilitiesAndEquityCents: number;
  differenceCents: number;
};

export function calculateBalanceSheetFromBalances(params: {
  organizationId: string | null;
  asOfDate: string;
  balances: AccountLedgerBalance[];
}): BalanceSheetReport {
  const grouped = groupBalancesByAccountType(params.balances);

  const assets = grouped.asset;
  const liabilities = grouped.liability;
  const equity = grouped.equity;

  const totalAssetsCents = sumSignedBalances(assets);
  const totalLiabilitiesCents = sumSignedBalances(liabilities);
  const rawEquityCents = sumSignedBalances(equity);

  const totalIncomeCents = sumSignedBalances(grouped.income);
  const totalExpenseCents = sumSignedBalances(grouped.expense);
  const currentYearEarningsCents = totalIncomeCents - totalExpenseCents;

  const totalEquityCents = rawEquityCents + currentYearEarningsCents;

  const totalLiabilitiesAndEquityCents =
    totalLiabilitiesCents + totalEquityCents;

  const differenceCents = totalAssetsCents - totalLiabilitiesAndEquityCents;

  return {
    organizationId: params.organizationId,
    asOfDate: params.asOfDate,
    assets,
    liabilities,
    equity,
    totalAssetsCents,
    totalLiabilitiesCents,
    totalEquityCents,
    currentYearEarningsCents,
    totalLiabilitiesAndEquityCents,
    differenceCents,
  };
}

export async function getBalanceSheetReport(
  asOfDate: string,
): Promise<BalanceSheetReport> {
  const { organizationId, balances } =
    await getLedgerAccountBalancesForCurrentOrganization({
      from: "1900-01-01",
      to: asOfDate,
    });

  return calculateBalanceSheetFromBalances({
    organizationId,
    asOfDate,
    balances,
  });
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 4. Create Balance Sheet Section Component

## The Target

We are creating:

```txt
components/balance-sheet-section.tsx
```

---

## The Implementation

Create:

```txt
components/balance-sheet-section.tsx
```

Add:

```tsx
// components/balance-sheet-section.tsx

import type { AccountLedgerBalance } from "@/lib/reports/types";
import { formatMoney } from "@/lib/money";

type BalanceSheetSectionProps = {
  title: string;
  balances: AccountLedgerBalance[];
  totalCents: number;
  extraRows?: Array<{
    label: string;
    amountCents: number;
  }>;
};

export function BalanceSheetSection({
  title,
  balances,
  totalCents,
  extraRows = [],
}: BalanceSheetSectionProps) {
  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
        <h2 className="text-lg font-semibold text-slate-950">{title}</h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-left text-sm">
          <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
            <tr>
              <th className="px-6 py-3 font-semibold">Account</th>
              <th className="px-6 py-3 text-right font-semibold">Amount</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-slate-200">
            {balances.length > 0 ? (
              balances.map((balance) => (
                <tr key={balance.accountId}>
                  <td className="px-6 py-4">
                    <div className="font-semibold text-slate-950">
                      {balance.accountCode} {balance.accountName}
                    </div>
                  </td>

                  <td className="px-6 py-4 text-right font-medium text-slate-950">
                    {formatMoney(balance.signedBalanceCents)}
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td
                  className="px-6 py-8 text-center text-slate-500"
                  colSpan={2}
                >
                  No balances in this section.
                </td>
              </tr>
            )}

            {extraRows.map((row) => (
              <tr key={row.label}>
                <td className="px-6 py-4 font-semibold text-slate-950">
                  {row.label}
                </td>

                <td className="px-6 py-4 text-right font-medium text-slate-950">
                  {formatMoney(row.amountCents)}
                </td>
              </tr>
            ))}
          </tbody>

          <tfoot className="bg-slate-50">
            <tr>
              <td className="px-6 py-4 font-bold text-slate-950">
                Total {title}
              </td>
              <td className="px-6 py-4 text-right font-bold text-slate-950">
                {formatMoney(totalCents)}
              </td>
            </tr>
          </tfoot>
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

# 5. Create Balance Sheet Page

## The Target

We are creating:

```txt
app/reports/balance-sheet/page.tsx
```

---

## The Concept

This page will:

1. Read an `asOf` date from search params.
2. Calculate Balance Sheet.
3. Show Assets, Liabilities, Equity.
4. Show whether the accounting equation balances.

---

## The Implementation

Create:

```bash
mkdir -p app/reports/balance-sheet
```

Create:

```txt
app/reports/balance-sheet/page.tsx
```

Add:

```tsx
// app/reports/balance-sheet/page.tsx

import { AppLayout } from "@/components/app-layout";
import { BalanceSheetSection } from "@/components/balance-sheet-section";
import { formatMoney } from "@/lib/money";
import {
  getCurrentYearDateRange,
  isValidReportDate,
} from "@/lib/reports/date-range";
import { getBalanceSheetReport } from "@/services/reports/balance-sheet-service";

export const dynamic = "force-dynamic";

type BalanceSheetPageProps = {
  searchParams?: Promise<{
    asOf?: string;
  }>;
};

function normalizeAsOfDate(value?: string): string {
  if (value && isValidReportDate(value)) {
    return value;
  }

  return getCurrentYearDateRange().to;
}

export default async function BalanceSheetPage({
  searchParams,
}: BalanceSheetPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const asOfDate = normalizeAsOfDate(resolvedSearchParams.asOf);

  const report = await getBalanceSheetReport(asOfDate);
  const isBalanced = report.differenceCents === 0;

  return (
    <AppLayout
      title="Balance Sheet"
      description="Review assets, liabilities, and equity as of a selected date."
    >
      <div className="space-y-6">
        <form
          action="/reports/balance-sheet"
          method="get"
          className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
            Report filter
          </p>

          <div className="mt-4 grid gap-4 md:grid-cols-[1fr_auto] md:items-end">
            <label className="block">
              <span className="text-sm font-semibold text-slate-700">
                As of date
              </span>
              <input
                name="asOf"
                type="date"
                defaultValue={asOfDate}
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

        {!report.organizationId ? (
          <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-800">
            <p className="text-sm font-semibold">
              Create or select a company workspace first.
            </p>
          </section>
        ) : null}

        {report.organizationId ? (
          <>
            <section className="grid gap-4 md:grid-cols-3">
              <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm">
                <p className="text-sm font-semibold text-emerald-700">
                  Assets
                </p>
                <p className="mt-2 text-3xl font-bold text-emerald-950">
                  {formatMoney(report.totalAssetsCents)}
                </p>
              </div>

              <div className="rounded-2xl border border-sky-200 bg-sky-50 p-6 shadow-sm">
                <p className="text-sm font-semibold text-sky-700">
                  Liabilities + Equity
                </p>
                <p className="mt-2 text-3xl font-bold text-sky-950">
                  {formatMoney(report.totalLiabilitiesAndEquityCents)}
                </p>
              </div>

              <div
                className={`rounded-2xl border p-6 shadow-sm ${
                  isBalanced
                    ? "border-emerald-200 bg-emerald-50"
                    : "border-rose-200 bg-rose-50"
                }`}
              >
                <p
                  className={`text-sm font-semibold ${
                    isBalanced ? "text-emerald-700" : "text-rose-700"
                  }`}
                >
                  Equation check
                </p>
                <p
                  className={`mt-2 text-3xl font-bold ${
                    isBalanced ? "text-emerald-950" : "text-rose-950"
                  }`}
                >
                  {isBalanced ? "Balanced" : formatMoney(report.differenceCents)}
                </p>
              </div>
            </section>

            <BalanceSheetSection
              title="Assets"
              balances={report.assets}
              totalCents={report.totalAssetsCents}
            />

            <BalanceSheetSection
              title="Liabilities"
              balances={report.liabilities}
              totalCents={report.totalLiabilitiesCents}
            />

            <BalanceSheetSection
              title="Equity"
              balances={report.equity}
              extraRows={[
                {
                  label: "Current Year Earnings",
                  amountCents: report.currentYearEarningsCents,
                },
              ]}
              totalCents={report.totalEquityCents}
            />

            <section className="rounded-2xl border border-slate-200 bg-slate-950 p-6 text-white shadow-sm">
              <div className="grid gap-4 md:grid-cols-3">
                <div>
                  <p className="text-sm text-slate-400">Assets</p>
                  <p className="mt-2 text-xl font-bold">
                    {formatMoney(report.totalAssetsCents)}
                  </p>
                </div>

                <div>
                  <p className="text-sm text-slate-400">
                    Liabilities + Equity
                  </p>
                  <p className="mt-2 text-xl font-bold">
                    {formatMoney(report.totalLiabilitiesAndEquityCents)}
                  </p>
                </div>

                <div>
                  <p className="text-sm text-slate-400">Difference</p>
                  <p className="mt-2 text-xl font-bold">
                    {formatMoney(report.differenceCents)}
                  </p>
                </div>
              </div>
            </section>
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
http://localhost:3000/reports/balance-sheet
```

You should see assets, liabilities, and equity.

If you have posted invoices, bills, and payments, you should see balances.

---

# 6. Link Balance Sheet from Reports Page

## The Target

We are updating:

```txt
app/reports/page.tsx
```

to link to the Balance Sheet.

---

## The Implementation

Open:

```txt
app/reports/page.tsx
```

Add a card:

```tsx
<Link
  href="/reports/balance-sheet"
  className="rounded-2xl border border-sky-200 bg-sky-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
>
  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-sky-700">
    Financial report
  </p>

  <h2 className="mt-3 text-lg font-semibold text-slate-950">
    Balance Sheet
  </h2>

  <p className="mt-2 text-sm leading-6 text-sky-800">
    Review assets, liabilities, and equity from posted journal lines.
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
Balance Sheet
```

---

# 7. Add Balance Sheet Tests

## The Target

We are creating:

```txt
tests/balance-sheet.test.ts
```

---

## The Concept

We can test Balance Sheet math without a database.

We will test:

```txt
Assets
Liabilities
Equity
Current Year Earnings
Difference
```

---

## The Implementation

Create:

```txt
tests/balance-sheet.test.ts
```

Add:

```ts
// tests/balance-sheet.test.ts

import { describe, expect, it } from "vitest";
import type { AccountLedgerBalance } from "@/lib/reports/types";
import { calculateBalanceSheetFromBalances } from "@/services/reports/balance-sheet-service";

function balance(params: {
  code: string;
  name: string;
  type: AccountLedgerBalance["accountType"];
  signed: number;
}): AccountLedgerBalance {
  return {
    accountId: params.code,
    accountCode: params.code,
    accountName: params.name,
    accountType: params.type,
    debitCents: 0,
    creditCents: 0,
    signedBalanceCents: params.signed,
  };
}

describe("calculateBalanceSheetFromBalances", () => {
  it("calculates a balanced balance sheet with current year earnings", () => {
    const report = calculateBalanceSheetFromBalances({
      organizationId: "org-db-id",
      asOfDate: "2026-12-31",
      balances: [
        balance({
          code: "1000",
          name: "Bank",
          type: "asset",
          signed: 150000,
        }),
        balance({
          code: "2000",
          name: "Accounts Payable",
          type: "liability",
          signed: 50000,
        }),
        balance({
          code: "3000",
          name: "Share Capital",
          type: "equity",
          signed: 80000,
        }),
        balance({
          code: "4000",
          name: "Sales Revenue",
          type: "income",
          signed: 40000,
        }),
        balance({
          code: "6000",
          name: "Rent Expense",
          type: "expense",
          signed: 20000,
        }),
      ],
    });

    expect(report.totalAssetsCents).toBe(150000);
    expect(report.totalLiabilitiesCents).toBe(50000);
    expect(report.currentYearEarningsCents).toBe(20000);
    expect(report.totalEquityCents).toBe(100000);
    expect(report.totalLiabilitiesAndEquityCents).toBe(150000);
    expect(report.differenceCents).toBe(0);
  });

  it("detects an unbalanced balance sheet", () => {
    const report = calculateBalanceSheetFromBalances({
      organizationId: "org-db-id",
      asOfDate: "2026-12-31",
      balances: [
        balance({
          code: "1000",
          name: "Bank",
          type: "asset",
          signed: 100000,
        }),
        balance({
          code: "3000",
          name: "Share Capital",
          type: "equity",
          signed: 80000,
        }),
      ],
    });

    expect(report.differenceCents).toBe(20000);
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

# 8. Verify with Real App Data

## The Target

We are checking Balance Sheet output from real journal entries.

---

## The Implementation

Open:

```txt
http://localhost:3000/reports/balance-sheet
```

Use a future as-of date if needed:

```txt
2030-12-31
```

---

## The Verification

If you posted invoices, bills, and payments, you should see accounts such as:

```txt
Bank
Accounts Receivable
GST Input Tax
Accounts Payable
GST Output Tax
Share Capital
Current Year Earnings
```

Depending on which entries you posted, some balances may be zero or absent.

---

# 9. Verify in Neon SQL

## The Target

We are checking Balance Sheet accounts directly.

---

## The Implementation

Run:

```sql
select
  a.code,
  a.name,
  a.type,
  sum(jl.debit_cents) as debits,
  sum(jl.credit_cents) as credits
from journal_lines jl
join accounts a
  on a.id = jl.account_id
join journal_entries je
  on je.id = jl.journal_entry_id
where a.type in ('asset', 'liability', 'equity')
group by a.code, a.name, a.type
order by a.code;
```

---

## The Verification

Assets normally have debit balances.

Liabilities and equity normally have credit balances.

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

# 11. Commit Balance Sheet Report

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Build balance sheet report"
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

## Error: Balance Sheet shows no data

Check:

1. Have you posted journal entries?
2. Is your as-of date after the journal entry dates?
3. Are you in the correct organization?

---

## Error: Balance Sheet does not balance

Possible reasons:

- You manually inserted unbalanced data.
- There is a bug in custom journal posting.
- Some P&L balances are not included as current year earnings.

Run the journal balance SQL from earlier parts.

---

## Error: Current Year Earnings looks unexpected

Current Year Earnings is:

```txt
Income - Expenses
```

Check the Profit & Loss report for the same date range context.

---

# Phase 8 Reference — Balance Sheet

## Assets

Things the business owns.

Examples:

```txt
Bank
Accounts Receivable
GST Input Tax
```

---

## Liabilities

Things the business owes.

Examples:

```txt
Accounts Payable
GST Output Tax
Loans Payable
```

---

## Equity

Owner claim in the business.

Examples:

```txt
Share Capital
Retained Earnings
Current Year Earnings
```

---

## Accounting Equation

```txt
Assets = Liabilities + Equity
```

---

# Part 26 Completion Checklist

You are ready for Part 27 if:

- [ ] `services/reports/balance-sheet-service.ts` exists
- [ ] Balance Sheet calculates from journal lines
- [ ] Assets are included
- [ ] Liabilities are included
- [ ] Equity is included
- [ ] Current Year Earnings are included in equity
- [ ] Accounting equation difference is calculated
- [ ] `/reports/balance-sheet` loads
- [ ] Report as-of date filter works
- [ ] `/reports` links to Balance Sheet
- [ ] `tests/balance-sheet.test.ts` passes
- [ ] Real ledger data appears in Balance Sheet
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
