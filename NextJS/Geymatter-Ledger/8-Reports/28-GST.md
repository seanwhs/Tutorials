# Part 28 — GST F5-Style Report

In Part 27, we built AR and AP aging reports.

Now we will build a Singapore-oriented GST report inspired by the structure of GST F5 reporting.

This is an educational GST summary report, not official tax filing software.

By the end of this part, you will have:

- GST report service
- GST output tax calculation
- GST input tax calculation
- Net GST payable/refundable calculation
- `/reports/gst-f5`
- GST report cards and tables
- Report navigation link
- Automated tests for GST report math

---

# Important GST Disclaimer

This tutorial is educational.

The report we build is **GST F5-style**, not a certified IRAS filing system.

Real GST reporting may require additional details such as:

- Standard-rated supplies
- Zero-rated supplies
- Exempt supplies
- Total purchases
- Adjustments
- Imports
- Bad debt relief
- Deemed supplies
- GST schemes
- Rounding and filing period rules
- IRAS-specific filing box definitions

Before using any GST report for real filing, consult a qualified Singapore accountant or tax professional.

---

# 1. Understand GST Reporting

## The Target

We are summarizing GST-related ledger balances.

---

## The Concept

For a GST-registered business:

```txt
GST Output Tax = GST collected from customers
GST Input Tax  = GST paid to vendors
```

Net GST payable:

```txt
GST Output Tax - GST Input Tax
```

Example:

```txt
GST collected on sales:  S$900
GST paid on purchases:   S$300
Net GST payable:         S$600
```

If input tax is greater than output tax:

```txt
Net GST refundable
```

---

# 2. Understand Our GST Accounts

## The Target

We are using seeded chart of accounts codes:

```txt
2110 GST Output Tax
1400 GST Input Tax
```

---

## The Concept

In our chart:

```txt
2110 GST Output Tax
```

is a liability account.

It increases with credits.

```txt
1400 GST Input Tax
```

is an asset account.

It increases with debits.

So for report math:

```txt
GST Output Tax signed balance = credits - debits
GST Input Tax signed balance = debits - credits
```

Our report helpers already know this through normal balances.

---

# 3. Create GST Report Service

## The Target

We are creating:

```txt
services/reports/gst-f5-service.ts
```

---

## The Concept

The GST report will:

1. Get ledger balances for a date range.
2. Find GST Output Tax account code `2110`.
3. Find GST Input Tax account code `1400`.
4. Calculate:

```txt
outputTaxCents
inputTaxCents
netGstCents = outputTaxCents - inputTaxCents
```

---

## The Implementation

Create:

```txt
services/reports/gst-f5-service.ts
```

Add:

```ts
// services/reports/gst-f5-service.ts

import type { AccountLedgerBalance, ReportDateRange } from "@/lib/reports/types";
import {
  getLedgerAccountBalancesForCurrentOrganization,
} from "@/services/reports/ledger-report-services";

export type GstF5StyleReport = {
  organizationId: string | null;
  dateRange: ReportDateRange;
  outputTaxCents: number;
  inputTaxCents: number;
  netGstPayableCents: number;
  outputTaxAccount: AccountLedgerBalance | null;
  inputTaxAccount: AccountLedgerBalance | null;
};

export function calculateGstF5StyleReportFromBalances(params: {
  organizationId: string | null;
  dateRange: ReportDateRange;
  balances: AccountLedgerBalance[];
}): GstF5StyleReport {
  const outputTaxAccount =
    params.balances.find((balance) => balance.accountCode === "2110") ?? null;

  const inputTaxAccount =
    params.balances.find((balance) => balance.accountCode === "1400") ?? null;

  const outputTaxCents = outputTaxAccount?.signedBalanceCents ?? 0;
  const inputTaxCents = inputTaxAccount?.signedBalanceCents ?? 0;

  return {
    organizationId: params.organizationId,
    dateRange: params.dateRange,
    outputTaxCents,
    inputTaxCents,
    netGstPayableCents: outputTaxCents - inputTaxCents,
    outputTaxAccount,
    inputTaxAccount,
  };
}

export async function getGstF5StyleReport(
  dateRange: ReportDateRange,
): Promise<GstF5StyleReport> {
  const { organizationId, balances } =
    await getLedgerAccountBalancesForCurrentOrganization(dateRange);

  return calculateGstF5StyleReportFromBalances({
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

# 4. Create GST F5 Page

## The Target

We are creating:

```txt
app/reports/gst-f5/page.tsx
```

---

## The Concept

The GST page will show:

```txt
GST Output Tax
GST Input Tax
Net GST Payable / Refundable
```

If net GST is positive:

```txt
Payable
```

If net GST is negative:

```txt
Refundable
```

---

## The Implementation

Create:

```bash
mkdir -p app/reports/gst-f5
```

Create:

```txt
app/reports/gst-f5/page.tsx
```

Add:

```tsx
// app/reports/gst-f5/page.tsx

import { AppLayout } from "@/components/app-layout";
import { ReportDateRangeForm } from "@/components/report-date-range-form";
import { formatMoney } from "@/lib/money";
import { normalizeReportDateRange } from "@/lib/reports/date-range";
import { getGstF5StyleReport } from "@/services/reports/gst-f5-service";

export const dynamic = "force-dynamic";

type GstF5PageProps = {
  searchParams?: Promise<{
    from?: string;
    to?: string;
  }>;
};

export default async function GstF5Page({ searchParams }: GstF5PageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const dateRange = normalizeReportDateRange(resolvedSearchParams);
  const report = await getGstF5StyleReport(dateRange);

  const isPayable = report.netGstPayableCents >= 0;

  return (
    <AppLayout
      title="GST F5-Style Report"
      description="Review GST output tax, GST input tax, and net GST payable or refundable for a selected period."
    >
      <div className="space-y-6">
        <ReportDateRangeForm actionPath="/reports/gst-f5" dateRange={dateRange} />

        <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-800">
          <p className="text-sm font-semibold uppercase tracking-[0.2em]">
            Educational report disclaimer
          </p>

          <p className="mt-2 text-sm leading-6">
            This is a GST F5-style educational summary. It is not certified IRAS
            filing software and may not include every adjustment required for
            real GST submission.
          </p>
        </section>

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
              <div className="rounded-2xl border border-sky-200 bg-sky-50 p-6 shadow-sm">
                <p className="text-sm font-semibold text-sky-700">
                  GST Output Tax
                </p>

                <p className="mt-2 text-3xl font-bold text-sky-950">
                  {formatMoney(report.outputTaxCents)}
                </p>

                <p className="mt-2 text-sm leading-6 text-sky-800">
                  GST collected from customers.
                </p>
              </div>

              <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm">
                <p className="text-sm font-semibold text-emerald-700">
                  GST Input Tax
                </p>

                <p className="mt-2 text-3xl font-bold text-emerald-950">
                  {formatMoney(report.inputTaxCents)}
                </p>

                <p className="mt-2 text-sm leading-6 text-emerald-800">
                  GST paid on purchases.
                </p>
              </div>

              <div
                className={`rounded-2xl border p-6 shadow-sm ${
                  isPayable
                    ? "border-rose-200 bg-rose-50"
                    : "border-emerald-200 bg-emerald-50"
                }`}
              >
                <p
                  className={`text-sm font-semibold ${
                    isPayable ? "text-rose-700" : "text-emerald-700"
                  }`}
                >
                  {isPayable ? "Net GST Payable" : "Net GST Refundable"}
                </p>

                <p
                  className={`mt-2 text-3xl font-bold ${
                    isPayable ? "text-rose-950" : "text-emerald-950"
                  }`}
                >
                  {formatMoney(Math.abs(report.netGstPayableCents))}
                </p>

                <p
                  className={`mt-2 text-sm leading-6 ${
                    isPayable ? "text-rose-800" : "text-emerald-800"
                  }`}
                >
                  Output tax minus input tax.
                </p>
              </div>
            </section>

            <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
              <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
                <h2 className="text-lg font-semibold text-slate-950">
                  GST account detail
                </h2>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full border-collapse text-left text-sm">
                  <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                    <tr>
                      <th className="px-6 py-3 font-semibold">Account</th>
                      <th className="px-6 py-3 text-right font-semibold">
                        Debits
                      </th>
                      <th className="px-6 py-3 text-right font-semibold">
                        Credits
                      </th>
                      <th className="px-6 py-3 text-right font-semibold">
                        Signed balance
                      </th>
                    </tr>
                  </thead>

                  <tbody className="divide-y divide-slate-200">
                    {[report.outputTaxAccount, report.inputTaxAccount].map(
                      (account) =>
                        account ? (
                          <tr key={account.accountId}>
                            <td className="px-6 py-4">
                              <div className="font-semibold text-slate-950">
                                {account.accountCode} {account.accountName}
                              </div>
                              <div className="mt-1 text-xs capitalize text-slate-500">
                                {account.accountType}
                              </div>
                            </td>

                            <td className="px-6 py-4 text-right text-slate-600">
                              {formatMoney(account.debitCents)}
                            </td>

                            <td className="px-6 py-4 text-right text-slate-600">
                              {formatMoney(account.creditCents)}
                            </td>

                            <td className="px-6 py-4 text-right font-semibold text-slate-950">
                              {formatMoney(account.signedBalanceCents)}
                            </td>
                          </tr>
                        ) : null,
                    )}
                  </tbody>
                </table>
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
http://localhost:3000/reports/gst-f5
```

You should see GST Output Tax and GST Input Tax if you posted invoices and bills.

---

# 5. Link GST Report from Reports Page

## The Target

We are updating:

```txt
app/reports/page.tsx
```

---

## The Implementation

Add this card:

```tsx
<Link
  href="/reports/gst-f5"
  className="rounded-2xl border border-purple-200 bg-purple-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
>
  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-purple-700">
    GST
  </p>

  <h2 className="mt-3 text-lg font-semibold text-slate-950">
    GST F5-Style Report
  </h2>

  <p className="mt-2 text-sm leading-6 text-purple-800">
    Review GST output tax, GST input tax, and net GST payable or refundable.
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
GST F5-Style Report
```

---

# 6. Add GST Report Tests

## The Target

We are creating:

```txt
tests/gst-f5-report.test.ts
```

---

## The Implementation

Create:

```txt
tests/gst-f5-report.test.ts
```

Add:

```ts
// tests/gst-f5-report.test.ts

import { describe, expect, it } from "vitest";
import type { AccountLedgerBalance } from "@/lib/reports/types";
import { calculateGstF5StyleReportFromBalances } from "@/services/reports/gst-f5-service";

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

describe("calculateGstF5StyleReportFromBalances", () => {
  it("calculates net GST payable", () => {
    const report = calculateGstF5StyleReportFromBalances({
      organizationId: "org-db-id",
      dateRange: {
        from: "2026-01-01",
        to: "2026-03-31",
      },
      balances: [
        balance({
          code: "2110",
          name: "GST Output Tax",
          type: "liability",
          signed: 9000,
        }),
        balance({
          code: "1400",
          name: "GST Input Tax",
          type: "asset",
          signed: 3000,
        }),
      ],
    });

    expect(report.outputTaxCents).toBe(9000);
    expect(report.inputTaxCents).toBe(3000);
    expect(report.netGstPayableCents).toBe(6000);
  });

  it("calculates net GST refundable", () => {
    const report = calculateGstF5StyleReportFromBalances({
      organizationId: "org-db-id",
      dateRange: {
        from: "2026-01-01",
        to: "2026-03-31",
      },
      balances: [
        balance({
          code: "2110",
          name: "GST Output Tax",
          type: "liability",
          signed: 1000,
        }),
        balance({
          code: "1400",
          name: "GST Input Tax",
          type: "asset",
          signed: 3000,
        }),
      ],
    });

    expect(report.netGstPayableCents).toBe(-2000);
  });

  it("uses zero when GST accounts are missing", () => {
    const report = calculateGstF5StyleReportFromBalances({
      organizationId: "org-db-id",
      dateRange: {
        from: "2026-01-01",
        to: "2026-03-31",
      },
      balances: [],
    });

    expect(report.outputTaxCents).toBe(0);
    expect(report.inputTaxCents).toBe(0);
    expect(report.netGstPayableCents).toBe(0);
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

# 7. Verify with Real App Data

## The Target

We are checking the GST report against real invoice and bill postings.

---

## The Implementation

Create:

```txt
Invoice S$100 + 9% GST
Bill S$100 + 9% GST
```

Open:

```txt
/reports/gst-f5
```

Use a broad date range:

```txt
2020-01-01 to 2030-12-31
```

---

## The Verification

If invoice GST output is S$9 and bill GST input is S$9:

```txt
GST Output Tax: S$9.00
GST Input Tax:  S$9.00
Net GST:        S$0.00
```

If you have more invoices than bills, net GST payable should be positive.

---

# 8. Verify in Neon SQL

## The Target

We are checking GST account balances directly.

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
where a.code in ('1400', '2110')
group by a.code, a.name, a.type
order by a.code;
```

---

## The Verification

You should see:

```txt
1400 GST Input Tax
2110 GST Output Tax
```

Their signed balances should match the GST report.

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

# 10. Commit GST F5-Style Report

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Build GST F5 style report"
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

## Error: GST report shows zero

Check:

1. Did you create GST invoices or bills?
2. Are journal entries posted?
3. Is date range wide enough?
4. Are accounts coded `1400` and `2110`?

---

## Error: GST output appears negative

Check account type for `2110`.

It should be:

```txt
liability
```

---

## Error: GST input appears negative

Check account type for `1400`.

It should be:

```txt
asset
```

---

# Phase 8 Reference — GST F5-Style Reporting

## GST Output Tax

GST collected from customers.

Usually a liability.

---

## GST Input Tax

GST paid on purchases.

Often claimable, subject to rules.

---

## Net GST Payable

```txt
GST Output Tax - GST Input Tax
```

---

## Educational Limitation

This report is a simplified GST summary.

It is not a substitute for IRAS filing guidance or professional tax advice.

---

# Part 28 Completion Checklist

You are ready for Part 29 if:

- [ ] `services/reports/gst-f5-service.ts` exists
- [ ] GST report uses journal lines
- [ ] GST Output Tax account `2110` is included
- [ ] GST Input Tax account `1400` is included
- [ ] Net GST payable/refundable is calculated
- [ ] `/reports/gst-f5` loads
- [ ] `/reports` links to GST report
- [ ] GST report tests pass
- [ ] Real invoice/bill GST appears in report
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
