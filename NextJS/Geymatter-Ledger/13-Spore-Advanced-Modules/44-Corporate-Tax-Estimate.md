# Part 44 — Corporate Tax Estimate Report

In Part 43, we built a simplified CPF estimate module.

Now we will build a simplified Singapore corporate tax estimate report.

This module is educational.

It is **not** tax advice.

By the end of this part, you will have:

- Corporate tax estimate helper
- Corporate tax tests
- Corporate tax estimate page
- P&L-based taxable profit estimate
- Link from reports page

---

# Important Corporate Tax Disclaimer

This report is for learning software architecture.

Singapore corporate tax rules can involve:

- Partial tax exemption
- Start-up tax exemption
- Non-deductible expenses
- Capital allowances
- Unabsorbed losses
- Donations
- Foreign income
- Group relief
- Tax rebates
- Year of assessment rules
- IRAS-specific forms and schedules

Before using any tax estimate for real business decisions or filing, consult a qualified Singapore tax professional.

---

# 1. Understand Corporate Tax Estimate

## The Target

We are estimating corporate tax from accounting profit.

---

## The Concept

A simplified corporate tax estimate can start with:

```txt
Accounting profit × tax rate
```

Singapore headline corporate tax rate is commonly:

```txt
17%
```

Represented as basis points:

```txt
1700
```

Example:

```txt
Profit: S$100,000
Tax rate: 17%
Estimated tax: S$17,000
```

Real taxable income may differ from accounting profit.

This tutorial keeps the estimate simple.

---

# 2. Create Corporate Tax Helper

## The Target

We are creating:

```txt
lib/singapore/corporate-tax.ts
```

---

## The Implementation

Create:

```txt
lib/singapore/corporate-tax.ts
```

Add:

```ts
// lib/singapore/corporate-tax.ts

import type { MoneyCents } from "@/lib/money";

export const DEFAULT_SINGAPORE_CORPORATE_TAX_RATE_BASIS_POINTS = 1700;

export type CorporateTaxEstimateInput = {
  taxableProfitCents: MoneyCents;
  taxRateBasisPoints?: number;
};

export type CorporateTaxEstimateResult = {
  taxableProfitCents: MoneyCents;
  taxRateBasisPoints: number;
  estimatedTaxCents: MoneyCents;
  effectiveTaxRateBasisPoints: number;
};

function assertIntegerCents(value: number): void {
  if (!Number.isInteger(value) || !Number.isSafeInteger(value)) {
    throw new Error("Taxable profit must be integer cents.");
  }
}

function assertTaxRate(value: number): void {
  if (!Number.isInteger(value)) {
    throw new Error("Tax rate must be integer basis points.");
  }

  if (value < 0 || value > 10000) {
    throw new Error("Tax rate must be between 0 and 10000 basis points.");
  }
}

export function estimateCorporateTax(
  input: CorporateTaxEstimateInput,
): CorporateTaxEstimateResult {
  const taxRateBasisPoints =
    input.taxRateBasisPoints ??
    DEFAULT_SINGAPORE_CORPORATE_TAX_RATE_BASIS_POINTS;

  assertIntegerCents(input.taxableProfitCents);
  assertTaxRate(taxRateBasisPoints);

  const taxableProfitCents = Math.max(0, input.taxableProfitCents);

  const estimatedTaxCents = Math.round(
    (taxableProfitCents * taxRateBasisPoints) / 10000,
  );

  const effectiveTaxRateBasisPoints =
    taxableProfitCents === 0
      ? 0
      : Math.round((estimatedTaxCents * 10000) / taxableProfitCents);

  return {
    taxableProfitCents,
    taxRateBasisPoints,
    estimatedTaxCents,
    effectiveTaxRateBasisPoints,
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

# 3. Add Corporate Tax Tests

## The Target

We are creating:

```txt
tests/corporate-tax.test.ts
```

---

## The Implementation

Create:

```txt
tests/corporate-tax.test.ts
```

Add:

```ts
// tests/corporate-tax.test.ts

import { describe, expect, it } from "vitest";
import { estimateCorporateTax } from "@/lib/singapore/corporate-tax";

describe("estimateCorporateTax", () => {
  it("estimates tax at 17%", () => {
    const result = estimateCorporateTax({
      taxableProfitCents: 10000000,
    });

    expect(result.estimatedTaxCents).toBe(1700000);
    expect(result.taxRateBasisPoints).toBe(1700);
  });

  it("does not tax losses", () => {
    const result = estimateCorporateTax({
      taxableProfitCents: -100000,
    });

    expect(result.taxableProfitCents).toBe(0);
    expect(result.estimatedTaxCents).toBe(0);
  });

  it("supports custom tax rate", () => {
    const result = estimateCorporateTax({
      taxableProfitCents: 1000000,
      taxRateBasisPoints: 1000,
    });

    expect(result.estimatedTaxCents).toBe(100000);
  });

  it("rejects decimal cents", () => {
    expect(() =>
      estimateCorporateTax({
        taxableProfitCents: 100.5,
      }),
    ).toThrow("Taxable profit must be integer cents.");
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

# 4. Create Corporate Tax Estimate Page

## The Target

We are creating:

```txt
app/reports/corporate-tax/page.tsx
```

---

## The Concept

This page will use Profit & Loss data as a simplified taxable profit estimate.

It will:

1. Read date range.
2. Get P&L report.
3. Use net profit as estimated taxable profit.
4. Estimate tax at 17%.

---

## The Implementation

Create:

```bash
mkdir -p app/reports/corporate-tax
```

Create:

```txt
app/reports/corporate-tax/page.tsx
```

Add:

```tsx
// app/reports/corporate-tax/page.tsx

import { AppLayout } from "@/components/app-layout";
import { ReportDateRangeForm } from "@/components/report-date-range-form";
import { formatMoney } from "@/lib/money";
import { normalizeReportDateRange } from "@/lib/reports/date-range";
import { estimateCorporateTax } from "@/lib/singapore/corporate-tax";
import { getProfitAndLossReport } from "@/services/reports/profit-and-loss-service";

export const dynamic = "force-dynamic";

type CorporateTaxPageProps = {
  searchParams?: Promise<{
    from?: string;
    to?: string;
  }>;
};

export default async function CorporateTaxPage({
  searchParams,
}: CorporateTaxPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const dateRange = normalizeReportDateRange(resolvedSearchParams);
  const profitAndLoss = await getProfitAndLossReport(dateRange);

  const taxEstimate = estimateCorporateTax({
    taxableProfitCents: profitAndLoss.netProfitCents,
  });

  return (
    <AppLayout
      title="Corporate Tax Estimate"
      description="Educational Singapore corporate tax estimate based on accounting profit."
    >
      <div className="space-y-6">
        <ReportDateRangeForm
          actionPath="/reports/corporate-tax"
          dateRange={dateRange}
        />

        <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-800">
          <p className="text-sm font-semibold uppercase tracking-[0.2em]">
            Educational disclaimer
          </p>

          <p className="mt-2 text-sm leading-6">
            This simplified estimate uses accounting net profit as taxable
            profit and applies a headline 17% rate. Real corporate tax
            computation may require many adjustments.
          </p>
        </section>

        {!profitAndLoss.organizationId ? (
          <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-800">
            <p className="text-sm font-semibold">
              Create or select a company workspace first.
            </p>
          </section>
        ) : (
          <>
            <section className="grid gap-4 md:grid-cols-4">
              <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
                <p className="text-sm font-semibold text-slate-500">
                  Accounting profit
                </p>
                <p className="mt-2 text-2xl font-bold text-slate-950">
                  {formatMoney(profitAndLoss.netProfitCents)}
                </p>
              </div>

              <div className="rounded-2xl border border-sky-200 bg-sky-50 p-6 shadow-sm">
                <p className="text-sm font-semibold text-sky-700">
                  Taxable profit estimate
                </p>
                <p className="mt-2 text-2xl font-bold text-sky-950">
                  {formatMoney(taxEstimate.taxableProfitCents)}
                </p>
              </div>

              <div className="rounded-2xl border border-purple-200 bg-purple-50 p-6 shadow-sm">
                <p className="text-sm font-semibold text-purple-700">
                  Tax rate
                </p>
                <p className="mt-2 text-2xl font-bold text-purple-950">
                  {taxEstimate.taxRateBasisPoints / 100}%
                </p>
              </div>

              <div className="rounded-2xl border border-rose-200 bg-rose-50 p-6 shadow-sm">
                <p className="text-sm font-semibold text-rose-700">
                  Estimated tax
                </p>
                <p className="mt-2 text-2xl font-bold text-rose-950">
                  {formatMoney(taxEstimate.estimatedTaxCents)}
                </p>
              </div>
            </section>

            <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <h2 className="text-lg font-semibold text-slate-950">
                Estimate notes
              </h2>

              <ul className="mt-4 list-inside list-disc space-y-2 text-sm leading-6 text-slate-600">
                <li>Accounting profit is taken from the Profit & Loss report.</li>
                <li>Losses are treated as zero taxable profit in this simplified estimate.</li>
                <li>No exemptions, rebates, capital allowances, or disallowable expense adjustments are applied.</li>
                <li>Consult a qualified Singapore tax professional before relying on tax numbers.</li>
              </ul>
            </section>
          </>
        )}
      </div>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
/reports/corporate-tax
```

If you have P&L data, you should see an estimated tax amount.

---

# 5. Link Corporate Tax Page from Reports

## The Target

We are updating:

```txt
app/reports/page.tsx
```

---

## The Implementation

Add card:

```tsx
<Link
  href="/reports/corporate-tax"
  className="rounded-2xl border border-rose-200 bg-rose-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
>
  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-rose-700">
    Singapore module
  </p>

  <h2 className="mt-3 text-lg font-semibold text-slate-950">
    Corporate Tax Estimate
  </h2>

  <p className="mt-2 text-sm leading-6 text-rose-800">
    Estimate corporate tax from accounting profit for learning purposes.
  </p>
</Link>
```

---

## The Verification

Open:

```txt
/reports
```

Click:

```txt
Corporate Tax Estimate
```

---

# 6. Run Full Project Check

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

# 7. Commit Corporate Tax Module

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Add corporate tax estimate report"
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

## Error: Tax estimate is zero

If net profit is negative or zero, taxable profit is treated as zero in this simplified estimate.

Check:

```txt
/reports/profit-and-loss
```

---

## Error: Corporate tax calculation does not match real Singapore tax

This module is simplified and educational.

Real tax computation may be very different.

---

# Phase 13 Reference — Corporate Tax Estimate

## Accounting Profit

Profit from the Profit & Loss report.

---

## Taxable Profit

Profit after tax adjustments.

This tutorial uses accounting profit as a simplified proxy.

---

## Corporate Tax Rate

The simplified default rate is:

```txt
17%
```

---

# Part 44 Completion Checklist

You are ready for Part 45 if:

- [ ] `lib/singapore/corporate-tax.ts` exists
- [ ] Corporate tax tests pass
- [ ] `/reports/corporate-tax` loads
- [ ] Corporate tax uses P&L net profit
- [ ] `/reports` links to corporate tax page
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
