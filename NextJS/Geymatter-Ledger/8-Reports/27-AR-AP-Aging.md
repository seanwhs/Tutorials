# Part 27 — AR/AP Aging Reports

In Part 25, we built Profit & Loss.

In Part 26, we built the Balance Sheet.

Now we will build aging reports:

```txt
Accounts Receivable Aging
Accounts Payable Aging
```

These reports answer:

```txt
Who owes us money, and how overdue is it?
Who do we owe money to, and how overdue is it?
```

By the end of this part, you will have:

- AR Aging report service
- AP Aging report service
- Aging bucket helpers
- `/reports/ar-aging`
- `/reports/ap-aging`
- Report navigation links
- Tests for aging buckets

This part uses invoice and bill statuses.

For now, because we only support full payments, unpaid records are those not marked:

```txt
paid
void
```

---

# 1. Understand Aging Reports

## The Target

We are creating aging reports.

---

## The Concept

Aging reports group unpaid invoices or bills by how old they are.

Common buckets:

```txt
Current
1–30 days overdue
31–60 days overdue
61–90 days overdue
90+ days overdue
```

AR Aging:

```txt
Unpaid customer invoices
```

AP Aging:

```txt
Unpaid vendor bills
```

Aging is operational.

It helps answer:

```txt
Which customers should we follow up with?
Which vendor bills need payment soon?
```

---

# 2. Create Aging Helpers

## The Target

We are creating:

```txt
lib/reports/aging.ts
```

---

## The Concept

Aging depends on comparing:

```txt
due date
```

to:

```txt
as of date
```

If due date is in the future or today:

```txt
current
```

If due date was 10 days ago:

```txt
1-30
```

---

## The Implementation

Create:

```txt
lib/reports/aging.ts
```

Add:

```ts
// lib/reports/aging.ts

export type AgingBucketKey = "current" | "1-30" | "31-60" | "61-90" | "90+";

export type AgingBucketTotals = Record<AgingBucketKey, number>;

export const agingBucketLabels: Record<AgingBucketKey, string> = {
  current: "Current",
  "1-30": "1–30 days",
  "31-60": "31–60 days",
  "61-90": "61–90 days",
  "90+": "90+ days",
};

export function daysBetweenDates(from: string, to: string): number {
  const fromDate = new Date(`${from}T00:00:00.000Z`);
  const toDate = new Date(`${to}T00:00:00.000Z`);

  const differenceMs = toDate.getTime() - fromDate.getTime();

  return Math.floor(differenceMs / 86_400_000);
}

export function getAgingBucket(params: {
  dueDate: string;
  asOfDate: string;
}): AgingBucketKey {
  const daysOverdue = daysBetweenDates(params.dueDate, params.asOfDate);

  if (daysOverdue <= 0) {
    return "current";
  }

  if (daysOverdue <= 30) {
    return "1-30";
  }

  if (daysOverdue <= 60) {
    return "31-60";
  }

  if (daysOverdue <= 90) {
    return "61-90";
  }

  return "90+";
}

export function createEmptyAgingTotals(): AgingBucketTotals {
  return {
    current: 0,
    "1-30": 0,
    "31-60": 0,
    "61-90": 0,
    "90+": 0,
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

# 3. Create Aging Report Services

## The Target

We are creating:

```txt
services/reports/aging-report-services.ts
```

---

## The Concept

AR Aging reads unpaid invoices.

AP Aging reads unpaid bills.

We already mark invoices and bills as `paid` when full payments are recorded.

So unpaid means:

```txt
status is not paid
status is not void
```

---

## The Implementation

Create:

```txt
services/reports/aging-report-services.ts
```

Add:

```ts
// services/reports/aging-report-services.ts

import { and, asc, eq, notInArray } from "drizzle-orm";
import { db } from "@/db";
import { bills, customers, invoices, vendors } from "@/db/schema";
import {
  createEmptyAgingTotals,
  getAgingBucket,
  type AgingBucketKey,
  type AgingBucketTotals,
} from "@/lib/reports/aging";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

export type AgingReportRow = {
  id: string;
  documentNumber: string;
  partyName: string;
  dueDate: string;
  totalCents: number;
  bucket: AgingBucketKey;
};

export type AgingReport = {
  organizationId: string | null;
  asOfDate: string;
  rows: AgingReportRow[];
  totals: AgingBucketTotals;
  grandTotalCents: number;
};

export async function getAccountsReceivableAgingReport(
  asOfDate: string,
): Promise<AgingReport> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return {
      organizationId: null,
      asOfDate,
      rows: [],
      totals: createEmptyAgingTotals(),
      grandTotalCents: 0,
    };
  }

  const invoiceRows = await db
    .select({
      id: invoices.id,
      documentNumber: invoices.invoiceNumber,
      partyName: customers.name,
      dueDate: invoices.dueDate,
      totalCents: invoices.totalCents,
    })
    .from(invoices)
    .innerJoin(customers, eq(invoices.customerId, customers.id))
    .where(
      and(
        eq(invoices.organizationId, organization.id),
        notInArray(invoices.status, ["paid", "void"]),
      ),
    )
    .orderBy(asc(invoices.dueDate));

  const totals = createEmptyAgingTotals();

  const rows = invoiceRows.map((invoice) => {
    const bucket = getAgingBucket({
      dueDate: invoice.dueDate,
      asOfDate,
    });

    totals[bucket] += invoice.totalCents;

    return {
      id: invoice.id,
      documentNumber: invoice.documentNumber,
      partyName: invoice.partyName,
      dueDate: invoice.dueDate,
      totalCents: invoice.totalCents,
      bucket,
    };
  });

  return {
    organizationId: organization.id,
    asOfDate,
    rows,
    totals,
    grandTotalCents: rows.reduce((sum, row) => sum + row.totalCents, 0),
  };
}

export async function getAccountsPayableAgingReport(
  asOfDate: string,
): Promise<AgingReport> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return {
      organizationId: null,
      asOfDate,
      rows: [],
      totals: createEmptyAgingTotals(),
      grandTotalCents: 0,
    };
  }

  const billRows = await db
    .select({
      id: bills.id,
      documentNumber: bills.billNumber,
      partyName: vendors.name,
      dueDate: bills.dueDate,
      totalCents: bills.totalCents,
    })
    .from(bills)
    .innerJoin(vendors, eq(bills.vendorId, vendors.id))
    .where(
      and(
        eq(bills.organizationId, organization.id),
        notInArray(bills.status, ["paid", "void"]),
      ),
    )
    .orderBy(asc(bills.dueDate));

  const totals = createEmptyAgingTotals();

  const rows = billRows.map((bill) => {
    const bucket = getAgingBucket({
      dueDate: bill.dueDate,
      asOfDate,
    });

    totals[bucket] += bill.totalCents;

    return {
      id: bill.id,
      documentNumber: bill.documentNumber,
      partyName: bill.partyName,
      dueDate: bill.dueDate,
      totalCents: bill.totalCents,
      bucket,
    };
  });

  return {
    organizationId: organization.id,
    asOfDate,
    rows,
    totals,
    grandTotalCents: rows.reduce((sum, row) => sum + row.totalCents, 0),
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

# 4. Create Aging Report Table Component

## The Target

We are creating:

```txt
components/aging-report-table.tsx
```

---

## The Implementation

Create:

```txt
components/aging-report-table.tsx
```

Add:

```tsx
// components/aging-report-table.tsx

import Link from "next/link";
import {
  agingBucketLabels,
  type AgingBucketTotals,
} from "@/lib/reports/aging";
import { formatMoney } from "@/lib/money";
import type { AgingReportRow } from "@/services/reports/aging-report-services";

type AgingReportTableProps = {
  title: string;
  rows: AgingReportRow[];
  totals: AgingBucketTotals;
  grandTotalCents: number;
  documentHrefPrefix: "/invoices" | "/bills";
};

const bucketOrder = ["current", "1-30", "31-60", "61-90", "90+"] as const;

export function AgingReportTable({
  title,
  rows,
  totals,
  grandTotalCents,
  documentHrefPrefix,
}: AgingReportTableProps) {
  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
        <h2 className="text-lg font-semibold text-slate-950">{title}</h2>
      </div>

      <div className="grid gap-4 border-b border-slate-200 p-6 md:grid-cols-5">
        {bucketOrder.map((bucket) => (
          <div key={bucket} className="rounded-xl bg-slate-50 p-4">
            <p className="text-sm font-semibold text-slate-600">
              {agingBucketLabels[bucket]}
            </p>
            <p className="mt-2 text-xl font-bold text-slate-950">
              {formatMoney(totals[bucket])}
            </p>
          </div>
        ))}
      </div>

      {rows.length > 0 ? (
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left text-sm">
            <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-6 py-3 font-semibold">Document</th>
                <th className="px-6 py-3 font-semibold">Party</th>
                <th className="px-6 py-3 font-semibold">Due date</th>
                <th className="px-6 py-3 font-semibold">Bucket</th>
                <th className="px-6 py-3 text-right font-semibold">Amount</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-200">
              {rows.map((row) => (
                <tr key={row.id}>
                  <td className="px-6 py-4">
                    <Link
                      href={`${documentHrefPrefix}/${row.id}`}
                      className="font-semibold text-slate-950 underline-offset-4 transition hover:text-emerald-700 hover:underline"
                    >
                      {row.documentNumber}
                    </Link>
                  </td>

                  <td className="px-6 py-4 text-slate-600">
                    {row.partyName}
                  </td>

                  <td className="px-6 py-4 text-slate-600">{row.dueDate}</td>

                  <td className="px-6 py-4 text-slate-600">
                    {agingBucketLabels[row.bucket]}
                  </td>

                  <td className="px-6 py-4 text-right font-semibold text-slate-950">
                    {formatMoney(row.totalCents)}
                  </td>
                </tr>
              ))}
            </tbody>

            <tfoot className="bg-slate-50">
              <tr>
                <td className="px-6 py-4 font-bold text-slate-950" colSpan={4}>
                  Grand total
                </td>
                <td className="px-6 py-4 text-right font-bold text-slate-950">
                  {formatMoney(grandTotalCents)}
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      ) : (
        <div className="p-8 text-center text-sm text-slate-500">
          No open documents for this aging report.
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

# 5. Create AR Aging Page

## The Target

We are creating:

```txt
app/reports/ar-aging/page.tsx
```

---

## The Implementation

Create:

```bash
mkdir -p app/reports/ar-aging
```

Create:

```txt
app/reports/ar-aging/page.tsx
```

Add:

```tsx
// app/reports/ar-aging/page.tsx

import { AgingReportTable } from "@/components/aging-report-table";
import { AppLayout } from "@/components/app-layout";
import { getCurrentYearDateRange, isValidReportDate } from "@/lib/reports/date-range";
import { getAccountsReceivableAgingReport } from "@/services/reports/aging-report-services";

export const dynamic = "force-dynamic";

type ArAgingPageProps = {
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

export default async function ArAgingPage({ searchParams }: ArAgingPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const asOfDate = normalizeAsOfDate(resolvedSearchParams.asOf);

  const report = await getAccountsReceivableAgingReport(asOfDate);

  return (
    <AppLayout
      title="Accounts Receivable Aging"
      description="Review unpaid customer invoices by aging bucket."
    >
      <div className="space-y-6">
        <form
          action="/reports/ar-aging"
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
        ) : (
          <AgingReportTable
            title="Accounts Receivable Aging"
            rows={report.rows}
            totals={report.totals}
            grandTotalCents={report.grandTotalCents}
            documentHrefPrefix="/invoices"
          />
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
http://localhost:3000/reports/ar-aging
```

Unpaid invoices should appear.

Paid invoices should not.

---

# 6. Create AP Aging Page

## The Target

We are creating:

```txt
app/reports/ap-aging/page.tsx
```

---

## The Implementation

Create:

```bash
mkdir -p app/reports/ap-aging
```

Create:

```txt
app/reports/ap-aging/page.tsx
```

Add:

```tsx
// app/reports/ap-aging/page.tsx

import { AgingReportTable } from "@/components/aging-report-table";
import { AppLayout } from "@/components/app-layout";
import { getCurrentYearDateRange, isValidReportDate } from "@/lib/reports/date-range";
import { getAccountsPayableAgingReport } from "@/services/reports/aging-report-services";

export const dynamic = "force-dynamic";

type ApAgingPageProps = {
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

export default async function ApAgingPage({ searchParams }: ApAgingPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const asOfDate = normalizeAsOfDate(resolvedSearchParams.asOf);

  const report = await getAccountsPayableAgingReport(asOfDate);

  return (
    <AppLayout
      title="Accounts Payable Aging"
      description="Review unpaid vendor bills by aging bucket."
    >
      <div className="space-y-6">
        <form
          action="/reports/ap-aging"
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
        ) : (
          <AgingReportTable
            title="Accounts Payable Aging"
            rows={report.rows}
            totals={report.totals}
            grandTotalCents={report.grandTotalCents}
            documentHrefPrefix="/bills"
          />
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
http://localhost:3000/reports/ap-aging
```

Unpaid bills should appear.

Paid bills should not.

---

# 7. Link Aging Reports from Reports Page

## The Target

We are updating:

```txt
app/reports/page.tsx
```

---

## The Implementation

Add two cards:

```tsx
<Link
  href="/reports/ar-aging"
  className="rounded-2xl border border-amber-200 bg-amber-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
>
  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-amber-700">
    Receivables
  </p>

  <h2 className="mt-3 text-lg font-semibold text-slate-950">
    AR Aging
  </h2>

  <p className="mt-2 text-sm leading-6 text-amber-800">
    Review unpaid customer invoices by aging bucket.
  </p>
</Link>

<Link
  href="/reports/ap-aging"
  className="rounded-2xl border border-rose-200 bg-rose-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
>
  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-rose-700">
    Payables
  </p>

  <h2 className="mt-3 text-lg font-semibold text-slate-950">
    AP Aging
  </h2>

  <p className="mt-2 text-sm leading-6 text-rose-800">
    Review unpaid vendor bills by aging bucket.
  </p>
</Link>
```

---

## The Verification

Open:

```txt
http://localhost:3000/reports
```

You should see links for:

```txt
AR Aging
AP Aging
```

---

# 8. Add Aging Tests

## The Target

We are creating:

```txt
tests/aging.test.ts
```

---

## The Implementation

Create:

```txt
tests/aging.test.ts
```

Add:

```ts
// tests/aging.test.ts

import { describe, expect, it } from "vitest";
import {
  daysBetweenDates,
  getAgingBucket,
} from "@/lib/reports/aging";

describe("daysBetweenDates", () => {
  it("calculates positive day difference", () => {
    expect(daysBetweenDates("2026-01-01", "2026-01-31")).toBe(30);
  });

  it("calculates zero day difference", () => {
    expect(daysBetweenDates("2026-01-01", "2026-01-01")).toBe(0);
  });

  it("calculates negative day difference", () => {
    expect(daysBetweenDates("2026-01-31", "2026-01-01")).toBe(-30);
  });
});

describe("getAgingBucket", () => {
  it("returns current when due date is today", () => {
    expect(
      getAgingBucket({
        dueDate: "2026-01-31",
        asOfDate: "2026-01-31",
      }),
    ).toBe("current");
  });

  it("returns current when due date is in the future", () => {
    expect(
      getAgingBucket({
        dueDate: "2026-02-15",
        asOfDate: "2026-01-31",
      }),
    ).toBe("current");
  });

  it("returns 1-30 bucket", () => {
    expect(
      getAgingBucket({
        dueDate: "2026-01-01",
        asOfDate: "2026-01-31",
      }),
    ).toBe("1-30");
  });

  it("returns 31-60 bucket", () => {
    expect(
      getAgingBucket({
        dueDate: "2026-01-01",
        asOfDate: "2026-02-15",
      }),
    ).toBe("31-60");
  });

  it("returns 61-90 bucket", () => {
    expect(
      getAgingBucket({
        dueDate: "2026-01-01",
        asOfDate: "2026-03-15",
      }),
    ).toBe("61-90");
  });

  it("returns 90+ bucket", () => {
    expect(
      getAgingBucket({
        dueDate: "2026-01-01",
        asOfDate: "2026-04-15",
      }),
    ).toBe("90+");
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

# 9. Verify with Real App Data

## The Target

We are checking aging reports against real invoices and bills.

---

## The Implementation

Create an invoice but do not pay it.

Open:

```txt
/reports/ar-aging
```

Create a bill but do not pay it.

Open:

```txt
/reports/ap-aging
```

---

## The Verification

Unpaid invoice appears in AR Aging.

Unpaid bill appears in AP Aging.

Paid invoices and bills should not appear.

---

# 10. Verify in Neon SQL

## The Target

We are checking unpaid documents directly.

---

## The Implementation

Run:

```sql
select
  invoice_number,
  due_date,
  status,
  total_cents
from invoices
where status not in ('paid', 'void')
order by due_date;
```

Run:

```sql
select
  bill_number,
  due_date,
  status,
  total_cents
from bills
where status not in ('paid', 'void')
order by due_date;
```

---

## The Verification

The SQL rows should match the aging report rows.

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

# 12. Commit Aging Reports

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Build AR and AP aging reports"
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

## Error: Aging report shows no rows

Check:

1. Do you have unpaid invoices or bills?
2. Did you accidentally record payment?
3. Are you in the correct organization?
4. Is the document status not `paid` or `void`?

---

## Error: Paid invoice still appears

Check invoice status:

```sql
select invoice_number, status
from invoices;
```

Paid invoices should have:

```txt
status = paid
```

---

## Error: Document appears in wrong aging bucket

Check:

```txt
dueDate
asOfDate
```

A document due today is current.

A document due 1 day before as-of date is 1–30.

---

# Phase 8 Reference — Aging Reports

## AR Aging

Unpaid customer invoices by age.

---

## AP Aging

Unpaid vendor bills by age.

---

## Current Bucket

Documents not overdue yet.

---

## Overdue Buckets

Documents past due grouped by days overdue.

---

# Part 27 Completion Checklist

You are ready for Part 28 if:

- [ ] `lib/reports/aging.ts` exists
- [ ] Aging bucket logic works
- [ ] `services/reports/aging-report-services.ts` exists
- [ ] AR Aging reads unpaid invoices
- [ ] AP Aging reads unpaid bills
- [ ] Paid and void documents are excluded
- [ ] `/reports/ar-aging` loads
- [ ] `/reports/ap-aging` loads
- [ ] Aging report rows link to invoice/bill details
- [ ] `/reports` links to aging reports
- [ ] `tests/aging.test.ts` passes
- [ ] Real unpaid documents appear in aging reports
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
