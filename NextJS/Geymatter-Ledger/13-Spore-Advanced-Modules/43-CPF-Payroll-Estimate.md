# Part 43 — CPF Payroll Estimate Module

In Part 42, we added multi-currency foundations.

Now we will build a Singapore-oriented CPF payroll estimate module.

This module is educational.

It is **not** a complete payroll system.

CPF rules vary by:

```txt
Citizenship / PR status
Age
Wage bands
Ordinary wages
Additional wages
Contribution ceilings
Contribution year
Sector and special cases
```

For this tutorial, we will build a simplified CPF estimate calculator to show how payroll logic can be isolated and tested.

By the end of this part, you will have:

- CPF estimate helper
- CPF tests
- CPF estimate page
- Link from reports/advanced section

---

# Important CPF Disclaimer

This module is for learning software architecture.

It is not payroll advice.

Before using CPF calculations for real payroll, verify rates and rules with CPF Board guidance and qualified payroll professionals.

---

# 1. Understand CPF Estimates

## The Target

We are creating an educational CPF contribution estimate.

---

## The Concept

CPF contributions usually include:

```txt
Employee contribution
Employer contribution
Total contribution
```

For a simplified example, we can estimate:

```txt
Employee CPF = wage × 20%
Employer CPF = wage × 17%
```

For many Singapore citizen/PR employees under common conditions, these rates are familiar reference points, but actual rules may differ.

We will cap ordinary wage at a configurable ceiling.

---

# 2. Create CPF Helper

## The Target

We are creating:

```txt
lib/singapore/cpf.ts
```

---

## The Implementation

Create:

```bash
mkdir -p lib/singapore
```

Create:

```txt
lib/singapore/cpf.ts
```

Add:

```ts
// lib/singapore/cpf.ts

import type { MoneyCents } from "@/lib/money";

export type CpfEstimateInput = {
  monthlyOrdinaryWageCents: MoneyCents;
  employeeRateBasisPoints?: number;
  employerRateBasisPoints?: number;
  ordinaryWageCeilingCents?: MoneyCents;
};

export type CpfEstimateResult = {
  cappedWageCents: MoneyCents;
  employeeContributionCents: MoneyCents;
  employerContributionCents: MoneyCents;
  totalContributionCents: MoneyCents;
};

export const DEFAULT_EMPLOYEE_CPF_RATE_BASIS_POINTS = 2000;
export const DEFAULT_EMPLOYER_CPF_RATE_BASIS_POINTS = 1700;

/**
 * Simplified educational ordinary wage ceiling.
 *
 * Always verify current CPF ceilings before real payroll use.
 */
export const DEFAULT_ORDINARY_WAGE_CEILING_CENTS = 680000;

function assertNonNegativeIntegerCents(value: number, label: string): void {
  if (!Number.isInteger(value) || !Number.isSafeInteger(value)) {
    throw new Error(`${label} must be integer cents.`);
  }

  if (value < 0) {
    throw new Error(`${label} cannot be negative.`);
  }
}

function assertBasisPoints(value: number, label: string): void {
  if (!Number.isInteger(value)) {
    throw new Error(`${label} must be integer basis points.`);
  }

  if (value < 0 || value > 10000) {
    throw new Error(`${label} must be between 0 and 10000.`);
  }
}

export function estimateCpfContributions(
  input: CpfEstimateInput,
): CpfEstimateResult {
  const employeeRateBasisPoints =
    input.employeeRateBasisPoints ?? DEFAULT_EMPLOYEE_CPF_RATE_BASIS_POINTS;

  const employerRateBasisPoints =
    input.employerRateBasisPoints ?? DEFAULT_EMPLOYER_CPF_RATE_BASIS_POINTS;

  const ordinaryWageCeilingCents =
    input.ordinaryWageCeilingCents ?? DEFAULT_ORDINARY_WAGE_CEILING_CENTS;

  assertNonNegativeIntegerCents(
    input.monthlyOrdinaryWageCents,
    "Monthly ordinary wage",
  );
  assertNonNegativeIntegerCents(
    ordinaryWageCeilingCents,
    "Ordinary wage ceiling",
  );
  assertBasisPoints(employeeRateBasisPoints, "Employee CPF rate");
  assertBasisPoints(employerRateBasisPoints, "Employer CPF rate");

  const cappedWageCents = Math.min(
    input.monthlyOrdinaryWageCents,
    ordinaryWageCeilingCents,
  );

  const employeeContributionCents = Math.round(
    (cappedWageCents * employeeRateBasisPoints) / 10000,
  );

  const employerContributionCents = Math.round(
    (cappedWageCents * employerRateBasisPoints) / 10000,
  );

  return {
    cappedWageCents,
    employeeContributionCents,
    employerContributionCents,
    totalContributionCents:
      employeeContributionCents + employerContributionCents,
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

# 3. Add CPF Tests

## The Target

We are creating:

```txt
tests/cpf.test.ts
```

---

## The Implementation

Create:

```txt
tests/cpf.test.ts
```

Add:

```ts
// tests/cpf.test.ts

import { describe, expect, it } from "vitest";
import {
  DEFAULT_ORDINARY_WAGE_CEILING_CENTS,
  estimateCpfContributions,
} from "@/lib/singapore/cpf";

describe("estimateCpfContributions", () => {
  it("estimates employee and employer CPF contributions", () => {
    const result = estimateCpfContributions({
      monthlyOrdinaryWageCents: 500000,
    });

    expect(result.cappedWageCents).toBe(500000);
    expect(result.employeeContributionCents).toBe(100000);
    expect(result.employerContributionCents).toBe(85000);
    expect(result.totalContributionCents).toBe(185000);
  });

  it("caps wage at ordinary wage ceiling", () => {
    const result = estimateCpfContributions({
      monthlyOrdinaryWageCents: 1000000,
    });

    expect(result.cappedWageCents).toBe(DEFAULT_ORDINARY_WAGE_CEILING_CENTS);
  });

  it("rejects negative wages", () => {
    expect(() =>
      estimateCpfContributions({
        monthlyOrdinaryWageCents: -1,
      }),
    ).toThrow("Monthly ordinary wage cannot be negative.");
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

# 4. Create CPF Estimate Page

## The Target

We are creating:

```txt
app/reports/cpf-estimate/page.tsx
```

---

## The Concept

This page lets users enter a monthly wage and see estimated contributions.

We will use GET parameters so the URL can show the calculation input.

---

## The Implementation

Create:

```bash
mkdir -p app/reports/cpf-estimate
```

Create:

```txt
app/reports/cpf-estimate/page.tsx
```

Add:

```tsx
// app/reports/cpf-estimate/page.tsx

import { AppLayout } from "@/components/app-layout";
import { dollarsToCents, formatMoney } from "@/lib/money";
import { estimateCpfContributions } from "@/lib/singapore/cpf";

type CpfEstimatePageProps = {
  searchParams?: Promise<{
    wage?: string;
  }>;
};

export default async function CpfEstimatePage({
  searchParams,
}: CpfEstimatePageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const wageInput = resolvedSearchParams.wage ?? "5000.00";

  let wageCents = 500000;
  let error: string | null = null;

  try {
    wageCents = dollarsToCents(wageInput);
  } catch {
    error = "Wage must be a valid money amount.";
  }

  const estimate = error
    ? null
    : estimateCpfContributions({
        monthlyOrdinaryWageCents: wageCents,
      });

  return (
    <AppLayout
      title="CPF Payroll Estimate"
      description="Educational CPF contribution estimate for Singapore payroll planning."
    >
      <div className="space-y-6">
        <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-800">
          <p className="text-sm font-semibold uppercase tracking-[0.2em]">
            Educational disclaimer
          </p>

          <p className="mt-2 text-sm leading-6">
            This is a simplified CPF estimate. It is not payroll advice and does
            not replace CPF Board guidance or professional payroll review.
          </p>
        </section>

        <form
          action="/reports/cpf-estimate"
          method="get"
          className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
        >
          <label className="block">
            <span className="text-sm font-semibold text-slate-700">
              Monthly ordinary wage
            </span>
            <input
              name="wage"
              defaultValue={wageInput}
              className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
            />
          </label>

          <button
            type="submit"
            className="mt-4 rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white"
          >
            Estimate CPF
          </button>
        </form>

        {error ? (
          <section className="rounded-2xl border border-rose-200 bg-rose-50 p-6 text-rose-800">
            <p className="text-sm font-semibold">{error}</p>
          </section>
        ) : null}

        {estimate ? (
          <section className="grid gap-4 md:grid-cols-4">
            <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <p className="text-sm font-semibold text-slate-500">
                Capped wage
              </p>
              <p className="mt-2 text-2xl font-bold text-slate-950">
                {formatMoney(estimate.cappedWageCents)}
              </p>
            </div>

            <div className="rounded-2xl border border-sky-200 bg-sky-50 p-6 shadow-sm">
              <p className="text-sm font-semibold text-sky-700">
                Employee CPF
              </p>
              <p className="mt-2 text-2xl font-bold text-sky-950">
                {formatMoney(estimate.employeeContributionCents)}
              </p>
            </div>

            <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm">
              <p className="text-sm font-semibold text-emerald-700">
                Employer CPF
              </p>
              <p className="mt-2 text-2xl font-bold text-emerald-950">
                {formatMoney(estimate.employerContributionCents)}
              </p>
            </div>

            <div className="rounded-2xl border border-purple-200 bg-purple-50 p-6 shadow-sm">
              <p className="text-sm font-semibold text-purple-700">
                Total CPF
              </p>
              <p className="mt-2 text-2xl font-bold text-purple-950">
                {formatMoney(estimate.totalContributionCents)}
              </p>
            </div>
          </section>
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
/reports/cpf-estimate
```

Try:

```txt
5000.00
```

You should see estimated CPF values.

---

# 5. Link CPF Page from Reports

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
  href="/reports/cpf-estimate"
  className="rounded-2xl border border-purple-200 bg-purple-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
>
  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-purple-700">
    Singapore module
  </p>

  <h2 className="mt-3 text-lg font-semibold text-slate-950">
    CPF Payroll Estimate
  </h2>

  <p className="mt-2 text-sm leading-6 text-purple-800">
    Estimate employee and employer CPF contributions for learning purposes.
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
CPF Payroll Estimate
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

# 7. Commit CPF Module

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Add CPF payroll estimate module"
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

## Error: CPF output seems wrong

This module is simplified.

Actual CPF rules depend on many details.

Use this only as an educational estimate.

---

## Error: Wage input invalid

Use values like:

```txt
5000.00
```

---

# Phase 13 Reference — CPF Estimate

## Employee CPF

Amount deducted from employee wages.

---

## Employer CPF

Additional employer contribution.

---

## Ordinary Wage Ceiling

A cap applied to wage amount for contribution calculation.

---

# Part 43 Completion Checklist

You are ready for Part 44 if:

- [ ] `lib/singapore/cpf.ts` exists
- [ ] CPF tests pass
- [ ] `/reports/cpf-estimate` loads
- [ ] CPF estimate form works
- [ ] `/reports` links to CPF page
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
