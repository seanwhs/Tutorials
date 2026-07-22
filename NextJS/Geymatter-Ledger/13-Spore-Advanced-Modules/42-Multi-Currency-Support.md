# Part 42 — Multi-Currency Support

GreyMatter Ledger has been SGD-first so far.

Singapore businesses often deal with foreign customers and vendors.

Examples:

```txt
USD invoices
EUR software subscriptions
MYR vendor bills
```

In this part, we add foundational multi-currency support.

By the end of this part, you will have:

- Currency code helpers
- Exchange rate helpers
- Database fields for transaction currency
- Tests for currency conversion
- UI reference page for multi-currency concepts

This is a foundation, not a full foreign exchange revaluation engine.

---

# 1. Understand Multi-Currency Accounting

## The Target

We are adding multi-currency foundations.

---

## The Concept

Most accounting systems have a base currency.

For GreyMatter Ledger, the base currency is:

```txt
SGD
```

If we issue a USD invoice, we need to track:

```txt
Foreign amount: USD 100
Exchange rate: 1 USD = 1.35 SGD
Base amount: SGD 135
```

Reports are usually shown in base currency.

So the ledger should still post in SGD cents.

But source documents may remember foreign currency details.

---

# 2. Create Currency Helpers

## The Target

We are creating:

```txt
lib/currency.ts
```

---

## The Implementation

Create:

```txt
lib/currency.ts
```

Add:

```ts
// lib/currency.ts

import type { MoneyCents } from "@/lib/money";

export const BASE_CURRENCY = "SGD" as const;

export type SupportedCurrency = "SGD" | "USD" | "EUR" | "GBP" | "AUD" | "MYR";

export const supportedCurrencies: SupportedCurrency[] = [
  "SGD",
  "USD",
  "EUR",
  "GBP",
  "AUD",
  "MYR",
];

export function isSupportedCurrency(value: string): value is SupportedCurrency {
  return supportedCurrencies.includes(value as SupportedCurrency);
}

/**
 * Exchange rates are represented as basis points relative to SGD.
 *
 * Example:
 *   1 USD = 1.35 SGD
 *   rate basis points = 13500
 *
 * Calculation:
 *   foreign cents * rate basis points / 10000 = SGD cents
 */
export function convertForeignCentsToBaseCents(params: {
  foreignAmountCents: MoneyCents;
  exchangeRateBasisPoints: number;
}): MoneyCents {
  if (!Number.isInteger(params.foreignAmountCents)) {
    throw new Error("Foreign amount must be integer cents.");
  }

  if (
    !Number.isInteger(params.exchangeRateBasisPoints) ||
    params.exchangeRateBasisPoints <= 0
  ) {
    throw new Error("Exchange rate basis points must be a positive integer.");
  }

  return Math.round(
    (params.foreignAmountCents * params.exchangeRateBasisPoints) / 10000,
  );
}

export function formatCurrencyAmount(params: {
  amountCents: MoneyCents;
  currency: SupportedCurrency;
}): string {
  return new Intl.NumberFormat("en-SG", {
    style: "currency",
    currency: params.currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(params.amountCents / 100);
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 3. Add Currency Tests

## The Target

We are creating:

```txt
tests/currency.test.ts
```

---

## The Implementation

Create:

```txt
tests/currency.test.ts
```

Add:

```ts
// tests/currency.test.ts

import { describe, expect, it } from "vitest";
import {
  convertForeignCentsToBaseCents,
  formatCurrencyAmount,
  isSupportedCurrency,
} from "@/lib/currency";

describe("currency helpers", () => {
  it("detects supported currencies", () => {
    expect(isSupportedCurrency("SGD")).toBe(true);
    expect(isSupportedCurrency("USD")).toBe(true);
    expect(isSupportedCurrency("XYZ")).toBe(false);
  });

  it("converts foreign cents to base cents", () => {
    const result = convertForeignCentsToBaseCents({
      foreignAmountCents: 10000,
      exchangeRateBasisPoints: 13500,
    });

    expect(result).toBe(13500);
  });

  it("rounds converted base cents", () => {
    const result = convertForeignCentsToBaseCents({
      foreignAmountCents: 999,
      exchangeRateBasisPoints: 13500,
    });

    expect(result).toBe(1349);
  });

  it("formats foreign currency amount", () => {
    expect(formatCurrencyAmount({ amountCents: 10000, currency: "USD" })).toBe(
      "US$100.00",
    );
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

# 4. Add Currency Fields to Invoices and Bills

## The Target

We are updating:

```txt
invoices
bills
```

with currency metadata.

---

## The Concept

The ledger remains SGD.

But documents can store foreign currency data.

For now, we add:

```txt
currency
exchange_rate_basis_points
foreign_total_cents
```

---

## The Implementation

Open:

```txt
db/schema.ts
```

In `invoices`, add:

```ts
currency: text("currency").default("SGD").notNull(),

exchangeRateBasisPoints: integer("exchange_rate_basis_points")
  .default(10000)
  .notNull(),

foreignTotalCents: bigint("foreign_total_cents", { mode: "number" }),
```

In `bills`, add the same:

```ts
currency: text("currency").default("SGD").notNull(),

exchangeRateBasisPoints: integer("exchange_rate_basis_points")
  .default(10000)
  .notNull(),

foreignTotalCents: bigint("foreign_total_cents", { mode: "number" }),
```

---

## The Verification

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

Verify columns:

```sql
select column_name
from information_schema.columns
where table_name = 'invoices'
  and column_name in ('currency', 'exchange_rate_basis_points', 'foreign_total_cents');
```

---

# 5. Create Multi-Currency Reference Page

## The Target

We are creating:

```txt
app/reports/multi-currency/page.tsx
```

---

## The Implementation

Create:

```bash
mkdir -p app/reports/multi-currency
```

Create:

```txt
app/reports/multi-currency/page.tsx
```

Add:

```tsx
// app/reports/multi-currency/page.tsx

import { AppLayout } from "@/components/app-layout";
import {
  BASE_CURRENCY,
  convertForeignCentsToBaseCents,
  formatCurrencyAmount,
} from "@/lib/currency";
import { formatMoney } from "@/lib/money";

export default function MultiCurrencyPage() {
  const usdAmountCents = 10000;
  const exchangeRateBasisPoints = 13500;
  const sgdAmountCents = convertForeignCentsToBaseCents({
    foreignAmountCents: usdAmountCents,
    exchangeRateBasisPoints,
  });

  return (
    <AppLayout
      title="Multi-Currency Reference"
      description="Understand how GreyMatter Ledger stores foreign currency document values while reporting in SGD."
    >
      <div className="space-y-6">
        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
            Base currency
          </p>

          <h2 className="mt-3 text-2xl font-bold tracking-tight text-slate-950">
            Reports use {BASE_CURRENCY}
          </h2>

          <p className="mt-3 max-w-3xl text-sm leading-6 text-slate-500">
            Foreign invoices and bills can store foreign currency metadata, but
            journal entries and financial reports remain in SGD cents.
          </p>
        </section>

        <section className="grid gap-4 md:grid-cols-3">
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold text-slate-500">
              Foreign amount
            </p>
            <p className="mt-2 text-3xl font-bold text-slate-950">
              {formatCurrencyAmount({
                amountCents: usdAmountCents,
                currency: "USD",
              })}
            </p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold text-slate-500">
              Exchange rate
            </p>
            <p className="mt-2 text-3xl font-bold text-slate-950">1.35</p>
          </div>

          <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm">
            <p className="text-sm font-semibold text-emerald-700">
              Base amount
            </p>
            <p className="mt-2 text-3xl font-bold text-emerald-950">
              {formatMoney(sgdAmountCents)}
            </p>
          </div>
        </section>
      </div>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
/reports/multi-currency
```

---

# 6. Link Multi-Currency Page from Reports

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
  href="/reports/multi-currency"
  className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
>
  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-600">
    Advanced
  </p>

  <h2 className="mt-3 text-lg font-semibold text-slate-950">
    Multi-Currency Reference
  </h2>

  <p className="mt-2 text-sm leading-6 text-slate-500">
    Review base currency and foreign amount conversion concepts.
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
Multi-Currency Reference
```

---

# 7. Run Full Project Check

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

# 8. Commit Multi-Currency Foundation

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Add multi-currency foundation"
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

## Error: Currency columns missing

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Currency formatting differs

Node/Intl output may vary slightly by environment.

Adjust tests carefully if your runtime formats `USD` differently.

---

# Phase 13 Reference — Multi-Currency

## Base Currency

The currency used for reports.

For this app:

```txt
SGD
```

---

## Foreign Currency

The transaction/document currency.

Example:

```txt
USD
```

---

## Exchange Rate Basis Points

Whole-number rate representation.

```txt
1.35 = 13500
```

---

# Part 42 Completion Checklist

You are ready for Part 43 if:

- [ ] `lib/currency.ts` exists
- [ ] Currency tests pass
- [ ] Invoice currency fields exist
- [ ] Bill currency fields exist
- [ ] `/reports/multi-currency` loads
- [ ] `/reports` links to multi-currency page
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
