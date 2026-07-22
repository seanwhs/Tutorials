# Part 25 — Profit & Loss Report

In Part 24, we created reusable report helpers.

Now we will build the first formal financial report:

```txt
Profit & Loss
```

A Profit & Loss report, often called a **P&L**, shows:

```txt
Income - Expenses = Net Profit
```

For a period.

Examples:

```txt
January 2026
Q1 2026
Financial year 2026
```

By the end of this part, you will have:

- Profit & Loss calculation service
- Income section
- Expense section
- Gross net profit calculation
- Date filter support
- A `/reports/profit-and-loss` page
- Report cards linked from `/reports`
- Automated tests for P&L calculation helpers

---

# 1. Understand Profit & Loss

## The Target

We are creating a Profit & Loss report.

---

## The Concept

Profit & Loss answers:

> Did the business make money during this period?

The formula is:

```txt
Net Profit = Income - Expenses
```

If income is greater than expenses:

```txt
Profit
```

If expenses are greater than income:

```txt
Loss
```

Example:

```txt
Sales Revenue     S$10,000
Service Revenue   S$2,000
Total Income      S$12,000

Rent Expense      S$2,000
Software Expense  S$500
Total Expenses    S$2,500

Net Profit        S$9,500
```

---

## The Implementation

The report will use the ledger helper from Part 24:

```ts
getLedgerAccountBalancesForCurrentOrganization()
```

Then it will filter:

```txt
income accounts
expense accounts
```

It will calculate:

```txt
totalIncome = sum income signed balances
totalExpenses = sum expense signed balances
netProfit = totalIncome - totalExpenses
```

---

## The Verification

After creating invoices and bills, open:

```txt
/reports/profit-and-loss
```

You should see income and expenses.

---

# 2. Create Profit & Loss Service

## The Target

We are creating:

```txt
services/reports/profit-and-loss-service.ts
```

---

## The Concept

The page should not calculate report logic itself.

A report page should ask a service:

```ts
const report = await getProfitAndLossReport(dateRange);
```

That keeps report math reusable and testable.

---

## The Implementation

Create:

```txt
services/reports/profit-and-loss-service.ts
```

Add:

```ts
// services/reports/profit-and-loss-service.ts

import type { AccountLedgerBalance, ReportDateRange } from "@/lib/reports/types";
import { sumSignedBalances } from "@/lib/reports/balance-sign";
import {
  getLedgerAccountBalancesForCurrentOrganization,
  groupBalancesByAccountType,
} from "@/services/reports/ledger-report-services";

export type ProfitAndLossReport = {
  organizationId: string | null;
  dateRange: ReportDateRange;
  income: AccountLedgerBalance[];
  expenses: AccountLedgerBalance[];
  totalIncomeCents: number;
  totalExpenseCents: number;
  netProfitCents: number;
};

export function calculateProfitAndLossFromBalances(params: {
  organizationId: string | null;
  dateRange: ReportDateRange;
  balances: AccountLedgerBalance[];
}): ProfitAndLossReport {
  const grouped = groupBalancesByAccountType(params.balances);

  const income = grouped.income;
  const expenses = grouped.expense;

  const totalIncomeCents = sumSignedBalances(income);
  const totalExpenseCents = sumSignedBalances(expenses);
  const netProfitCents = totalIncomeCents - totalExpenseCents;

  return {
    organizationId: params.organizationId,
    dateRange: params.dateRange,
    income,
    expenses,
    totalIncomeCents,
    totalExpenseCents,
    netProfitCents,
  };
}

export async function getProfitAndLossReport(
  dateRange: ReportDateRange,
): Promise<ProfitAndLossReport> {
  const { organizationId, balances } =
    await getLedgerAccountBalancesForCurrentOrganization(dateRange);

  return calculateProfitAndLossFromBalances({
    organizationId,
    dateRange,
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

# 3. Create Profit & Loss Components

## The Target

We are creating:

```txt
components/profit-and-loss-section.tsx
```

---

## The Concept

The P&L has repeated report sections:

```txt
Income
Expenses
```

Each section lists accounts and totals.

So we create one reusable component.

---

## The Implementation

Create:

```txt
components/profit-and-loss-section.tsx
```

Add:

```tsx
// components/profit-and-loss-section.tsx

import type { AccountLedgerBalance } from "@/lib/reports/types";
import { formatMoney } from "@/lib/money";

type ProfitAndLossSectionProps = {
  title: string;
  balances: AccountLedgerBalance[];
  totalCents: number;
};

export function ProfitAndLossSection({
  title,
  balances,
  totalCents,
}: ProfitAndLossSectionProps) {
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
                <th className="px-6 py-3 text-right font-semibold">Amount</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-200">
              {balances.map((balance) => (
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
      ) : (
        <div className="p-8 text-center text-sm text-slate-500">
          No {title.toLowerCase()} recorded for this period.
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

# 4. Create the Profit & Loss Page

## The Target

We are creating:

```txt
app/reports/profit-and-loss/page.tsx
```

---

## The Concept

The P&L page will:

1. Read date filters.
2. Get ledger balances.
3. Calculate income, expenses, and net profit.
4. Display report sections.

---

## The Implementation

Create:

```bash
mkdir -p app/reports/profit-and-loss
```

Create:

```txt
app/reports/profit-and-loss/page.tsx
```

Add:

```tsx
// app/reports/profit-and-loss/page.tsx

import { AppLayout } from "@/components/app-layout";
import { ProfitAndLossSection } from "@/components/profit-and-loss-section";
import { ReportDateRangeForm } from "@/components/report-date-range-form";
import { formatMoney } from "@/lib/money";
import { normalizeReportDateRange } from "@/lib/reports/date-range";
import { getProfitAndLossReport } from "@/services/reports/profit-and-loss-service";

export const dynamic = "force-dynamic";

type ProfitAndLossPageProps = {
  searchParams?: Promise<{
    from?: string;
    to?: string;
  }>;
};

export default async function ProfitAndLossPage({
  searchParams,
}: ProfitAndLossPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const dateRange = normalizeReportDateRange(resolvedSearchParams);
  const report = await getProfitAndLossReport(dateRange);

  const isProfit = report.netProfitCents >= 0;

  return (
    <AppLayout
      title="Profit & Loss"
      description="Review income, expenses, and net profit for a selected period."
    >
      <div className="space-y-6">
        <ReportDateRangeForm
          actionPath="/reports/profit-and-loss"
          dateRange={dateRange}
        />

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
                  Total income
                </p>
                <p className="mt-2 text-3xl font-bold text-emerald-950">
                  {formatMoney(report.totalIncomeCents)}
                </p>
              </div>

              <div className="rounded-2xl border border-rose-200 bg-rose-50 p-6 shadow-sm">
                <p className="text-sm font-semibold text-rose-700">
                  Total expenses
                </p>
                <p className="mt-2 text-3xl font-bold text-rose-950">
                  {formatMoney(report.totalExpenseCents)}
                </p>
              </div>

              <div
                className={`rounded-2xl border p-6 shadow-sm ${
                  isProfit
                    ? "border-sky-200 bg-sky-50"
                    : "border-amber-200 bg-amber-50"
                }`}
              >
                <p
                  className={`text-sm font-semibold ${
                    isProfit ? "text-sky-700" : "text-amber-700"
                  }`}
                >
                  {isProfit ? "Net profit" : "Net loss"}
                </p>
                <p
                  className={`mt-2 text-3xl font-bold ${
                    isProfit ? "text-sky-950" : "text-amber-950"
                  }`}
                >
                  {formatMoney(report.netProfitCents)}
                </p>
              </div>
            </section>

            <ProfitAndLossSection
              title="Income"
              balances={report.income}
              totalCents={report.totalIncomeCents}
            />

            <ProfitAndLossSection
              title="Expenses"
              balances={report.expenses}
              totalCents={report.totalExpenseCents}
            />

            <section className="rounded-2xl border border-slate-200 bg-slate-950 p-6 text-white shadow-sm">
              <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-400">
                    Bottom line
                  </p>
                  <h2 className="mt-2 text-xl font-bold">
                    {isProfit ? "Net Profit" : "Net Loss"}
                  </h2>
                </div>

                <p className="text-3xl font-bold">
                  {formatMoney(report.netProfitCents)}
                </p>
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
http://localhost:3000/reports/profit-and-loss
```

If you have invoices and bills posted, you should see income and expense balances.

---

# 5. Link Profit & Loss from Reports Page

## The Target

We are updating:

```txt
app/reports/page.tsx
```

to link to the P&L report.

---

## The Implementation

Open:

```txt
app/reports/page.tsx
```

Add or update a report card linking to:

```txt
/reports/profit-and-loss
```

Use this card:

```tsx
<Link
  href="/reports/profit-and-loss"
  className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
>
  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-700">
    Financial report
  </p>

  <h2 className="mt-3 text-lg font-semibold text-slate-950">
    Profit & Loss
  </h2>

  <p className="mt-2 text-sm leading-6 text-emerald-800">
    Review income, expenses, and net profit from posted journal lines.
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
Profit & Loss
```

---

# 6. Add Profit & Loss Tests

## The Target

We are creating:

```txt
tests/profit-and-loss.test.ts
```

---

## The Concept

We can test P&L math without a database by testing:

```ts
calculateProfitAndLossFromBalances()
```

---

## The Implementation

Create:

```txt
tests/profit-and-loss.test.ts
```

Add:

```ts
// tests/profit-and-loss.test.ts

import { describe, expect, it } from "vitest";
import type { AccountLedgerBalance } from "@/lib/reports/types";
import { calculateProfitAndLossFromBalances } from "@/services/reports/profit-and-loss-service";

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

describe("calculateProfitAndLossFromBalances", () => {
  it("calculates net profit when income exceeds expenses", () => {
    const report = calculateProfitAndLossFromBalances({
      organizationId: "org-db-id",
      dateRange: {
        from: "2026-01-01",
        to: "2026-12-31",
      },
      balances: [
        balance({
          code: "4000",
          name: "Sales Revenue",
          type: "income",
          signed: 100000,
        }),
        balance({
          code: "6000",
          name: "Rent Expense",
          type: "expense",
          signed: 30000,
        }),
      ],
    });

    expect(report.totalIncomeCents).toBe(100000);
    expect(report.totalExpenseCents).toBe(30000);
    expect(report.netProfitCents).toBe(70000);
  });

  it("calculates net loss when expenses exceed income", () => {
    const report = calculateProfitAndLossFromBalances({
      organizationId: "org-db-id",
      dateRange: {
        from: "2026-01-01",
        to: "2026-12-31",
      },
      balances: [
        balance({
          code: "4000",
          name: "Sales Revenue",
          type: "income",
          signed: 10000,
        }),
        balance({
          code: "6000",
          name: "Rent Expense",
          type: "expense",
          signed: 30000,
        }),
      ],
    });

    expect(report.netProfitCents).toBe(-20000);
  });

  it("ignores asset, liability, and equity accounts", () => {
    const report = calculateProfitAndLossFromBalances({
      organizationId: "org-db-id",
      dateRange: {
        from: "2026-01-01",
        to: "2026-12-31",
      },
      balances: [
        balance({
          code: "1000",
          name: "Bank",
          type: "asset",
          signed: 999999,
        }),
        balance({
          code: "2000",
          name: "Accounts Payable",
          type: "liability",
          signed: 999999,
        }),
        balance({
          code: "3000",
          name: "Share Capital",
          type: "equity",
          signed: 999999,
        }),
      ],
    });

    expect(report.totalIncomeCents).toBe(0);
    expect(report.totalExpenseCents).toBe(0);
    expect(report.netProfitCents).toBe(0);
  });
});
```

---

## The Verification

Run:

```bash
pnpm test
```

The tests should pass.

---

# 7. Verify with Real App Data

## The Target

We are checking the report against invoices and bills.

---

## The Concept

If you created:

```txt
Invoice subtotal S$100
Bill subtotal S$100
```

Then your P&L might show:

```txt
Income:   S$100
Expenses: S$100
Net:      S$0
```

GST should generally not appear in P&L because:

```txt
GST Output Tax = liability
GST Input Tax  = asset
```

Those belong to the Balance Sheet / GST reports, not P&L.

---

## The Implementation

Open:

```txt
http://localhost:3000/reports/profit-and-loss
```

Use a broad date range if needed:

```txt
From: 2020-01-01
To: 2030-12-31
```

---

## The Verification

You should see:

```txt
Sales Revenue
Purchases
```

If you posted invoices and bills.

---

# 8. Verify in Neon SQL

## The Target

We are checking P&L account balances directly.

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
where a.type in ('income', 'expense')
group by a.code, a.name, a.type
order by a.code;
```

---

## The Verification

Income accounts usually have credits.

Expense accounts usually have debits.

That matches signed balance behavior.

---

# 9. Run Full Project Check

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

# 10. Commit Profit & Loss Report

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Build profit and loss report"
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

## Error: Profit & Loss shows no data

Check:

1. Have you created invoices or bills?
2. Are they posted to the journal?
3. Is your report date range wide enough?
4. Are you in the correct organization?

---

## Error: GST appears in P&L

GST accounts should be asset or liability accounts:

```txt
1400 GST Input Tax = asset
2110 GST Output Tax = liability
```

If you changed those accounts to expense/income, P&L will include them.

---

## Error: Expenses show negative

Check `calculateSignedBalanceCents()`.

Expense accounts should use:

```txt
debits - credits
```

---

# Phase 8 Reference — Profit & Loss

## Income

Revenue earned during the period.

Examples:

```txt
Sales Revenue
Service Revenue
Other Income
```

---

## Expenses

Costs incurred during the period.

Examples:

```txt
Purchases
Rent Expense
Software and Subscriptions
Professional Fees
```

---

## Net Profit

```txt
Income - Expenses
```

---

## Why P&L Uses Journal Lines

Because journal lines are the accounting source of truth.

Invoices and bills are source documents, but the ledger determines reports.

---

# Part 25 Completion Checklist

You are ready for Part 26 if:

- [ ] `services/reports/profit-and-loss-service.ts` exists
- [ ] P&L report calculates from journal lines
- [ ] Income accounts are included
- [ ] Expense accounts are included
- [ ] Asset/liability/equity accounts are excluded
- [ ] `/reports/profit-and-loss` loads
- [ ] Report date filters work
- [ ] `/reports` links to Profit & Loss
- [ ] `tests/profit-and-loss.test.ts` passes
- [ ] Real invoice/bill data appears in P&L
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
