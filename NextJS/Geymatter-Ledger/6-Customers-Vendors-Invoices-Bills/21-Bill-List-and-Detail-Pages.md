# Part 21 — Bill List and Detail Pages

In Part 20, we created GST-aware vendor bills and posted them to the journal.

Now we will make bills easier to inspect.

By the end of this part, you will have:

- A proper bill list page
- Clickable bill rows
- Bill detail pages
- Bill line display
- Vendor information display
- GST subtotal / GST / total breakdown
- Linked journal entry inspection
- Journal lines shown directly on the bill detail page
- Tenant-safe bill queries
- Clean not-found handling
- Neon SQL verification queries

This mirrors what we did for invoices in Part 19, but for the purchasing side.

---

# 1. Understand Bill List and Detail Pages

## The Target

We are improving the bill workflow by adding:

```txt
/bills
/bills/[billId]
```

---

## The Concept

The bill list is like the accounts payable filing cabinet index.

It answers:

```txt
Which vendor bills exist?
Who are they from?
How much do we owe?
Are they posted to the journal?
```

The bill detail page is like opening one vendor bill folder.

It shows:

```txt
Bill header
Vendor details
Bill lines
GST input tax totals
Linked journal entry
Journal lines
```

This matters because a bill is both:

```txt
A vendor document
```

and:

```txt
A source document for accounting
```

A strong accounting system lets us trace from the business document to the ledger.

---

## The Implementation

We will create a new query service:

```txt
services/bills/get-bills.ts
```

This keeps bill read logic separate from bill creation logic in:

```txt
services/bills/bill-services.ts
```

---

## The Verification

At the end:

1. Open `/bills`.
2. Click a bill number.
3. Confirm `/bills/[billId]` loads.
4. Confirm the page shows bill lines and linked journal lines.

---

# 2. Create Bill Query Services

## The Target

We are creating:

```txt
services/bills/get-bills.ts
```

This file will contain tenant-safe bill list and detail queries.

---

## The Concept

Every bill query must be scoped to the active organization.

Bad:

```ts
await db.select().from(bills);
```

Good:

```ts
await db
  .select()
  .from(bills)
  .where(eq(bills.organizationId, organization.id));
```

This prevents Company A from seeing Company B’s bills.

---

## The Implementation

Create:

```txt
services/bills/get-bills.ts
```

Add:

```ts
// services/bills/get-bills.ts

import { and, asc, desc, eq } from "drizzle-orm";
import { db } from "@/db";
import {
  accounts,
  billLines,
  bills,
  journalEntries,
  journalLines,
  vendors,
} from "@/db/schema";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

export type BillListItem = {
  id: string;
  billNumber: string;
  vendorName: string;
  issueDate: string;
  dueDate: string;
  status: string;
  subtotalCents: number;
  gstCents: number;
  totalCents: number;
  journalEntryId: string | null;
  createdAt: Date;
};

export type BillDetail = {
  id: string;
  billNumber: string;
  issueDate: string;
  dueDate: string;
  status: string;
  subtotalCents: number;
  gstCents: number;
  totalCents: number;
  notes: string | null;
  journalEntryId: string | null;
  createdAt: Date;
  updatedAt: Date;
  vendor: {
    id: string;
    name: string;
    email: string | null;
    phone: string | null;
    billingAddress: string | null;
  };
  lines: Array<{
    id: string;
    lineNumber: number;
    description: string;
    quantity: number;
    unitAmountCents: number;
    subtotalCents: number;
    gstRateBasisPoints: number;
    gstCents: number;
    totalCents: number;
  }>;
  journalEntry: null | {
    id: string;
    entryDate: string;
    memo: string;
    sourceType: string;
    postedByUserId: string | null;
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
};

/**
 * Lists bills for the currently active organization.
 *
 * This powers the /bills page.
 */
export async function listCurrentOrganizationBills(): Promise<{
  organizationId: string | null;
  bills: BillListItem[];
}> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return {
      organizationId: null,
      bills: [],
    };
  }

  const rows = await db
    .select({
      id: bills.id,
      billNumber: bills.billNumber,
      vendorName: vendors.name,
      issueDate: bills.issueDate,
      dueDate: bills.dueDate,
      status: bills.status,
      subtotalCents: bills.subtotalCents,
      gstCents: bills.gstCents,
      totalCents: bills.totalCents,
      journalEntryId: bills.journalEntryId,
      createdAt: bills.createdAt,
    })
    .from(bills)
    .innerJoin(vendors, eq(bills.vendorId, vendors.id))
    .where(eq(bills.organizationId, organization.id))
    .orderBy(desc(bills.createdAt));

  return {
    organizationId: organization.id,
    bills: rows,
  };
}

/**
 * Loads one bill with:
 * - vendor details
 * - bill lines
 * - linked journal entry
 * - linked journal lines
 *
 * Returns null when:
 * - no active organization exists
 * - the bill does not belong to the active organization
 * - the bill does not exist
 */
export async function getCurrentOrganizationBillDetail(
  billId: string,
): Promise<BillDetail | null> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return null;
  }

  const [bill] = await db
    .select({
      id: bills.id,
      billNumber: bills.billNumber,
      issueDate: bills.issueDate,
      dueDate: bills.dueDate,
      status: bills.status,
      subtotalCents: bills.subtotalCents,
      gstCents: bills.gstCents,
      totalCents: bills.totalCents,
      notes: bills.notes,
      journalEntryId: bills.journalEntryId,
      createdAt: bills.createdAt,
      updatedAt: bills.updatedAt,
      vendorId: vendors.id,
      vendorName: vendors.name,
      vendorEmail: vendors.email,
      vendorPhone: vendors.phone,
      vendorBillingAddress: vendors.billingAddress,
    })
    .from(bills)
    .innerJoin(vendors, eq(bills.vendorId, vendors.id))
    .where(
      and(
        eq(bills.id, billId),
        eq(bills.organizationId, organization.id),
      ),
    )
    .limit(1);

  if (!bill) {
    return null;
  }

  const lines = await db
    .select({
      id: billLines.id,
      lineNumber: billLines.lineNumber,
      description: billLines.description,
      quantity: billLines.quantity,
      unitAmountCents: billLines.unitAmountCents,
      subtotalCents: billLines.subtotalCents,
      gstRateBasisPoints: billLines.gstRateBasisPoints,
      gstCents: billLines.gstCents,
      totalCents: billLines.totalCents,
    })
    .from(billLines)
    .where(
      and(
        eq(billLines.billId, bill.id),
        eq(billLines.organizationId, organization.id),
      ),
    )
    .orderBy(asc(billLines.lineNumber));

  let journalEntry: BillDetail["journalEntry"] = null;

  if (bill.journalEntryId) {
    const [entry] = await db
      .select({
        id: journalEntries.id,
        entryDate: journalEntries.entryDate,
        memo: journalEntries.memo,
        sourceType: journalEntries.sourceType,
        postedByUserId: journalEntries.postedByUserId,
      })
      .from(journalEntries)
      .where(
        and(
          eq(journalEntries.id, bill.journalEntryId),
          eq(journalEntries.organizationId, organization.id),
        ),
      )
      .limit(1);

    if (entry) {
      const entryLines = await db
        .select({
          id: journalLines.id,
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
          and(
            eq(journalLines.journalEntryId, entry.id),
            eq(journalLines.organizationId, organization.id),
          ),
        )
        .orderBy(asc(journalLines.lineNumber));

      journalEntry = {
        id: entry.id,
        entryDate: entry.entryDate,
        memo: entry.memo,
        sourceType: entry.sourceType,
        postedByUserId: entry.postedByUserId,
        lines: entryLines.map((line) => ({
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
        })),
      };
    }
  }

  return {
    id: bill.id,
    billNumber: bill.billNumber,
    issueDate: bill.issueDate,
    dueDate: bill.dueDate,
    status: bill.status,
    subtotalCents: bill.subtotalCents,
    gstCents: bill.gstCents,
    totalCents: bill.totalCents,
    notes: bill.notes,
    journalEntryId: bill.journalEntryId,
    createdAt: bill.createdAt,
    updatedAt: bill.updatedAt,
    vendor: {
      id: bill.vendorId,
      name: bill.vendorName,
      email: bill.vendorEmail,
      phone: bill.vendorPhone,
      billingAddress: bill.vendorBillingAddress,
    },
    lines,
    journalEntry,
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

# 3. Create a Bill List Table Component

## The Target

We are creating:

```txt
components/bill-list-table.tsx
```

This component displays bill rows and links to detail pages.

---

## The Concept

A bill list table should show:

```txt
Bill number
Vendor
Dates
Status
Journal posting status
Total
```

The bill number should link to:

```txt
/bills/[billId]
```

---

## The Implementation

Create:

```txt
components/bill-list-table.tsx
```

Add:

```tsx
// components/bill-list-table.tsx

import Link from "next/link";
import type { BillListItem } from "@/services/bills/get-bills";
import { formatMoney } from "@/lib/money";

type BillListTableProps = {
  bills: BillListItem[];
};

export function BillListTable({ bills }: BillListTableProps) {
  if (bills.length === 0) {
    return (
      <section className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
        <h2 className="text-lg font-semibold text-slate-950">No bills yet</h2>

        <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
          Create your first vendor bill using the form above. It will calculate
          GST input tax and post a balanced journal entry automatically.
        </p>
      </section>
    );
  }

  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
        <h2 className="text-lg font-semibold text-slate-950">
          {bills.length} bill{bills.length === 1 ? "" : "s"}
        </h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-left text-sm">
          <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
            <tr>
              <th className="px-6 py-3 font-semibold">Bill</th>
              <th className="px-6 py-3 font-semibold">Vendor</th>
              <th className="px-6 py-3 font-semibold">Issue date</th>
              <th className="px-6 py-3 font-semibold">Due date</th>
              <th className="px-6 py-3 font-semibold">Status</th>
              <th className="px-6 py-3 font-semibold">Journal</th>
              <th className="px-6 py-3 text-right font-semibold">Total</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-slate-200">
            {bills.map((bill) => (
              <tr key={bill.id}>
                <td className="px-6 py-4">
                  <Link
                    href={`/bills/${bill.id}`}
                    className="font-semibold text-slate-950 underline-offset-4 transition hover:text-emerald-700 hover:underline"
                  >
                    {bill.billNumber}
                  </Link>
                </td>

                <td className="px-6 py-4 text-slate-600">{bill.vendorName}</td>

                <td className="px-6 py-4 text-slate-600">{bill.issueDate}</td>

                <td className="px-6 py-4 text-slate-600">{bill.dueDate}</td>

                <td className="px-6 py-4">
                  <span className="rounded-full bg-sky-50 px-2 py-1 text-xs font-semibold capitalize text-sky-700">
                    {bill.status}
                  </span>
                </td>

                <td className="px-6 py-4">
                  {bill.journalEntryId ? (
                    <span className="rounded-full bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700">
                      Posted
                    </span>
                  ) : (
                    <span className="rounded-full bg-amber-50 px-2 py-1 text-xs font-semibold text-amber-700">
                      Not posted
                    </span>
                  )}
                </td>

                <td className="px-6 py-4 text-right font-semibold text-slate-950">
                  {formatMoney(bill.totalCents)}
                </td>
              </tr>
            ))}
          </tbody>
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

The build should succeed.

---

# 4. Update the Bills Page to Use the List Table

## The Target

We are updating:

```txt
app/bills/page.tsx
```

to use `BillListTable`.

---

## The Concept

The `/bills` page should now have:

```txt
Create bill form
Summary cards
Bill list table
Clickable bill numbers
```

---

## The Implementation

Open:

```txt
app/bills/page.tsx
```

Replace the entire file with:

```tsx
// app/bills/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { BillCreateForm } from "@/components/bill-create-form";
import { BillListTable } from "@/components/bill-list-table";
import { BillStatusBanner } from "@/components/bill-status-banner";
import { getCurrentOrganizationBillDiagnostics } from "@/services/bills/bill-services";
import { listCurrentOrganizationBills } from "@/services/bills/get-bills";
import { listCurrentOrganizationVendors } from "@/services/vendors/vendor-services";

export const dynamic = "force-dynamic";

type BillsPageProps = {
  searchParams?: Promise<{
    status?: string;
    message?: string;
    bill?: string;
  }>;
};

export default async function BillsPage({ searchParams }: BillsPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};

  const diagnostics = await getCurrentOrganizationBillDiagnostics();
  const { organizationId, vendors } = await listCurrentOrganizationVendors();
  const billList = await listCurrentOrganizationBills();

  return (
    <AppLayout
      title="Bills"
      description="Bills record purchases from vendors and create accounts payable when posted."
    >
      <div className="space-y-6">
        <BillStatusBanner
          status={resolvedSearchParams.status}
          message={resolvedSearchParams.message}
          billNumber={resolvedSearchParams.bill}
        />

        {!organizationId ? (
          <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6">
            <p className="text-sm font-semibold text-amber-800">
              Create or select a company workspace first.
            </p>

            <Link
              href="/onboarding/organization"
              className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white"
            >
              Create company workspace
            </Link>
          </section>
        ) : (
          <>
            <BillCreateForm vendors={vendors} />

            <section className="grid gap-4 md:grid-cols-3">
              <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
                <p className="text-sm font-semibold text-slate-500">Bills</p>
                <p className="mt-2 text-3xl font-bold text-slate-950">
                  {diagnostics.billCount}
                </p>
              </div>

              <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
                <p className="text-sm font-semibold text-slate-500">
                  Bill lines
                </p>
                <p className="mt-2 text-3xl font-bold text-slate-950">
                  {diagnostics.billLineCount}
                </p>
              </div>

              <Link
                href="/settings/database/journal"
                className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
              >
                <p className="text-sm font-semibold text-emerald-700">
                  Journal
                </p>
                <p className="mt-2 text-sm leading-6 text-emerald-800">
                  View posted bill journal entries.
                </p>
              </Link>
            </section>

            <BillListTable bills={billList.bills} />
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
http://localhost:3000/bills
```

You should see a bill list table.

Click a bill number.

It will 404 until we create the detail route in the next step.

---

# 5. Create the Bill Detail Page

## The Target

We are creating:

```txt
app/bills/[billId]/page.tsx
```

---

## The Concept

The bill detail page proves the purchasing accounting chain:

```txt
Bill
  |
  |-- Vendor
  |-- Bill lines
  |-- GST input tax totals
  |-- Linked journal entry
        |
        |-- Journal lines
```

For a S$109 GST-inclusive bill, we expect:

```txt
Bill:
Subtotal S$100.00
GST      S$9.00
Total    S$109.00

Journal:
Debit  Purchases          S$100.00
Debit  GST Input Tax      S$9.00
Credit Accounts Payable   S$109.00
```

---

## The Implementation

Create the folder:

```bash
mkdir -p app/bills/[billId]
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force 'app/bills/[billId]'
```

Create:

```txt
app/bills/[billId]/page.tsx
```

Add:

```tsx
// app/bills/[billId]/page.tsx

import Link from "next/link";
import { notFound } from "next/navigation";
import { AppLayout } from "@/components/app-layout";
import { formatMoney } from "@/lib/money";
import { getCurrentOrganizationBillDetail } from "@/services/bills/get-bills";

export const dynamic = "force-dynamic";

type BillDetailPageProps = {
  params: Promise<{
    billId: string;
  }>;
};

export default async function BillDetailPage({ params }: BillDetailPageProps) {
  const { billId } = await params;
  const bill = await getCurrentOrganizationBillDetail(billId);

  if (!bill) {
    notFound();
  }

  const journalTotalDebitCents =
    bill.journalEntry?.lines.reduce((sum, line) => sum + line.debitCents, 0) ??
    0;

  const journalTotalCreditCents =
    bill.journalEntry?.lines.reduce((sum, line) => sum + line.creditCents, 0) ??
    0;

  return (
    <AppLayout
      title={`Bill ${bill.billNumber}`}
      description="Review bill details, GST input tax calculation, vendor information, and the linked journal entry."
    >
      <div className="space-y-6">
        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.2em] text-sky-600">
                Bill detail
              </p>

              <h2 className="mt-3 text-2xl font-bold tracking-tight text-slate-950">
                {bill.billNumber}
              </h2>

              <p className="mt-2 text-sm leading-6 text-slate-500">
                Received on {bill.issueDate}. Due on {bill.dueDate}.
              </p>

              <div className="mt-4 flex flex-wrap gap-2">
                <span className="rounded-full bg-sky-50 px-3 py-1 text-xs font-semibold capitalize text-sky-700">
                  {bill.status}
                </span>

                {bill.journalEntryId ? (
                  <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
                    Journal posted
                  </span>
                ) : (
                  <span className="rounded-full bg-amber-50 px-3 py-1 text-xs font-semibold text-amber-700">
                    Journal missing
                  </span>
                )}
              </div>
            </div>

            <div className="flex flex-wrap gap-2">
              <Link
                href="/bills"
                className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
              >
                Back to bills
              </Link>

              <Link
                href="/settings/database/journal"
                className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
              >
                View journal diagnostics
              </Link>
            </div>
          </div>
        </section>

        <section className="grid gap-6 lg:grid-cols-[0.8fr_1.2fr]">
          <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-slate-950">Vendor</h2>

            <dl className="mt-4 space-y-4 text-sm">
              <div>
                <dt className="font-semibold text-slate-600">Name</dt>
                <dd className="mt-1 text-slate-950">{bill.vendor.name}</dd>
              </div>

              <div>
                <dt className="font-semibold text-slate-600">Email</dt>
                <dd className="mt-1 text-slate-950">
                  {bill.vendor.email ?? "—"}
                </dd>
              </div>

              <div>
                <dt className="font-semibold text-slate-600">Phone</dt>
                <dd className="mt-1 text-slate-950">
                  {bill.vendor.phone ?? "—"}
                </dd>
              </div>

              <div>
                <dt className="font-semibold text-slate-600">
                  Billing address
                </dt>
                <dd className="mt-1 whitespace-pre-wrap text-slate-950">
                  {bill.vendor.billingAddress ?? "—"}
                </dd>
              </div>
            </dl>
          </article>

          <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-slate-950">
              Bill totals
            </h2>

            <dl className="mt-4 divide-y divide-slate-200 overflow-hidden rounded-xl border border-slate-200">
              <div className="grid grid-cols-2 bg-slate-50 px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Subtotal
                </dt>
                <dd className="text-right text-sm font-semibold text-slate-950">
                  {formatMoney(bill.subtotalCents)}
                </dd>
              </div>

              <div className="grid grid-cols-2 bg-white px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">
                  GST input tax
                </dt>
                <dd className="text-right text-sm font-semibold text-slate-950">
                  {formatMoney(bill.gstCents)}
                </dd>
              </div>

              <div className="grid grid-cols-2 bg-slate-950 px-4 py-3 text-white">
                <dt className="text-sm font-bold">Total payable</dt>
                <dd className="text-right text-sm font-bold">
                  {formatMoney(bill.totalCents)}
                </dd>
              </div>
            </dl>

            {bill.notes ? (
              <div className="mt-4 rounded-xl bg-slate-50 p-4">
                <p className="text-sm font-semibold text-slate-700">Notes</p>
                <p className="mt-2 text-sm leading-6 text-slate-500">
                  {bill.notes}
                </p>
              </div>
            ) : null}
          </article>
        </section>

        <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
            <h2 className="text-lg font-semibold text-slate-950">
              Bill lines
            </h2>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-left text-sm">
              <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-6 py-3 font-semibold">#</th>
                  <th className="px-6 py-3 font-semibold">Description</th>
                  <th className="px-6 py-3 text-right font-semibold">Qty</th>
                  <th className="px-6 py-3 text-right font-semibold">Unit</th>
                  <th className="px-6 py-3 text-right font-semibold">
                    Subtotal
                  </th>
                  <th className="px-6 py-3 text-right font-semibold">
                    GST rate
                  </th>
                  <th className="px-6 py-3 text-right font-semibold">
                    GST
                  </th>
                  <th className="px-6 py-3 text-right font-semibold">
                    Total
                  </th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-200">
                {bill.lines.map((line) => (
                  <tr key={line.id}>
                    <td className="px-6 py-4 text-slate-500">
                      {line.lineNumber}
                    </td>

                    <td className="px-6 py-4 font-semibold text-slate-950">
                      {line.description}
                    </td>

                    <td className="px-6 py-4 text-right text-slate-600">
                      {line.quantity}
                    </td>

                    <td className="px-6 py-4 text-right text-slate-600">
                      {formatMoney(line.unitAmountCents)}
                    </td>

                    <td className="px-6 py-4 text-right text-slate-600">
                      {formatMoney(line.subtotalCents)}
                    </td>

                    <td className="px-6 py-4 text-right text-slate-600">
                      {line.gstRateBasisPoints / 100}%
                    </td>

                    <td className="px-6 py-4 text-right text-slate-600">
                      {formatMoney(line.gstCents)}
                    </td>

                    <td className="px-6 py-4 text-right font-semibold text-slate-950">
                      {formatMoney(line.totalCents)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        {bill.journalEntry ? (
          <section className="overflow-hidden rounded-2xl border border-emerald-200 bg-white shadow-sm">
            <div className="border-b border-emerald-200 bg-emerald-50 px-6 py-4">
              <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-700">
                    Linked journal entry
                  </p>

                  <h2 className="mt-2 text-lg font-semibold text-slate-950">
                    {bill.journalEntry.memo}
                  </h2>

                  <p className="mt-1 break-all font-mono text-xs text-emerald-700">
                    {bill.journalEntry.id}
                  </p>
                </div>

                {journalTotalDebitCents === journalTotalCreditCents ? (
                  <span className="rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-800">
                    Balanced
                  </span>
                ) : (
                  <span className="rounded-full bg-rose-100 px-3 py-1 text-xs font-semibold text-rose-800">
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
                    <th className="px-6 py-3 font-semibold">Description</th>
                    <th className="px-6 py-3 text-right font-semibold">
                      Debit
                    </th>
                    <th className="px-6 py-3 text-right font-semibold">
                      Credit
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-200">
                  {bill.journalEntry.lines.map((line) => (
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
                      {formatMoney(journalTotalDebitCents)}
                    </td>
                    <td className="px-6 py-4 text-right font-bold text-slate-950">
                      {formatMoney(journalTotalCreditCents)}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </section>
        ) : (
          <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6">
            <p className="text-sm font-semibold text-amber-800">
              This bill does not have a linked journal entry.
            </p>
          </section>
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
http://localhost:3000/bills
```

Click a bill number.

You should arrive at:

```txt
/bills/[billId]
```

You should see:

- Bill header
- Vendor details
- Bill lines
- Bill totals
- Linked journal entry
- Journal lines
- Balanced badge

---

# 6. Add a Bill Not Found Page

## The Target

We are creating:

```txt
app/bills/[billId]/not-found.tsx
```

---

## The Concept

If a bill does not exist or does not belong to the active organization, we should show a clean not-found page.

We should not reveal cross-tenant data.

---

## The Implementation

Create:

```txt
app/bills/[billId]/not-found.tsx
```

Add:

```tsx
// app/bills/[billId]/not-found.tsx

import Link from "next/link";

export default function BillNotFoundPage() {
  return (
    <main className="min-h-screen bg-slate-50 px-6 py-16 text-slate-950">
      <section className="mx-auto max-w-2xl rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-rose-600">
          Bill not found
        </p>

        <h1 className="mt-3 text-2xl font-bold tracking-tight">
          We could not find that bill.
        </h1>

        <p className="mt-3 text-sm leading-6 text-slate-500">
          The bill may not exist, or it may not belong to the active company
          workspace.
        </p>

        <Link
          href="/bills"
          className="mt-6 inline-flex rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
        >
          Back to bills
        </Link>
      </section>
    </main>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/bills/not-a-real-id
```

You should see the not-found page.

---

# 7. Verify Bill Detail Against Journal Diagnostics

## The Target

We are confirming that the bill detail page matches the journal diagnostics.

---

## The Concept

The bill detail page starts from the bill.

The journal diagnostics page starts from the ledger.

They should tell the same accounting story.

---

## The Implementation

Open a bill detail page:

```txt
/bills/[billId]
```

Note the journal entry memo.

Now open:

```txt
/settings/database/journal
```

Find the same memo.

---

## The Verification

For a S$109 GST bill:

```txt
Bill detail:
Subtotal S$100.00
GST      S$9.00
Total    S$109.00

Journal:
Debit  Purchases          S$100.00
Debit  GST Input Tax      S$9.00
Credit Accounts Payable   S$109.00
```

Both views should show the same accounting story.

---

# 8. Verify Tenant Isolation

## The Target

We are verifying that bills belong only to the active organization.

---

## The Concept

Company A should not see Company B’s bills.

This is multi-tenant isolation.

---

## The Implementation

If you have two organizations:

1. Select Organization A.
2. Create a bill.
3. Open `/bills`.
4. Confirm the bill appears.
5. Switch to Organization B.
6. Open `/bills`.

---

## The Verification

The Organization A bill should not appear in Organization B.

If it does, bill queries are not correctly scoped.

---

# 9. Verify in Neon SQL

## The Target

We are directly checking bill detail data in Neon.

---

## The Implementation

Open Neon SQL editor.

Run:

```sql
select
  b.bill_number,
  v.name as vendor_name,
  b.issue_date,
  b.due_date,
  b.status,
  b.subtotal_cents,
  b.gst_cents,
  b.total_cents,
  b.journal_entry_id
from bills b
join vendors v
  on v.id = b.vendor_id
order by b.created_at desc;
```

Run:

```sql
select
  b.bill_number,
  bl.line_number,
  bl.description,
  bl.quantity,
  bl.unit_amount_cents,
  bl.subtotal_cents,
  bl.gst_rate_basis_points,
  bl.gst_cents,
  bl.total_cents
from bill_lines bl
join bills b
  on b.id = bl.bill_id
order by b.created_at desc, bl.line_number;
```

Run:

```sql
select
  b.bill_number,
  je.memo,
  a.code,
  a.name,
  jl.debit_cents,
  jl.credit_cents
from bills b
join journal_entries je
  on je.id = b.journal_entry_id
join journal_lines jl
  on jl.journal_entry_id = je.id
join accounts a
  on a.id = jl.account_id
order by b.created_at desc, jl.line_number;
```

---

## The Verification

For a S$100 subtotal bill with 9% GST, you should see:

```txt
subtotal_cents = 10000
gst_cents      = 900
total_cents    = 10900
```

And journal lines:

```txt
5100 Purchases debit 10000
1400 GST Input Tax debit 900
2000 Accounts Payable credit 10900
```

---

# 10. Run the Full Project Check

## The Target

We are confirming everything still passes.

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

# 11. Commit Bill List and Detail Pages

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Build bill list and detail pages"
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

## Error: Bill detail page shows not found

Possible causes:

```txt
The bill ID is wrong.
The bill belongs to another organization.
No active organization is selected.
```

Go back to:

```txt
/bills
```

and click a bill from the list.

---

## Error: Bill detail page has no journal entry

If the bill was created before journal posting was added, it may not have `journalEntryId`.

Create a new bill using the current `/bills` form.

---

## Error: Journal lines do not appear

Check the bill row:

```sql
select bill_number, journal_entry_id
from bills;
```

If `journal_entry_id` is null, the bill was not linked to a journal entry.

---

## Error: Bill appears in the wrong organization

Check that all bill queries filter by:

```ts
eq(bills.organizationId, organization.id)
```

Also verify bill lines filter by:

```ts
eq(billLines.organizationId, organization.id)
```

---

# Phase 6 Reference — Bill Visibility

## Bill List

The bill list helps users scan all vendor bills for the active organization.

---

## Bill Detail

The bill detail page shows the full vendor document and accounting result.

---

## Linked Journal Entry

The bill’s `journalEntryId` connects the vendor document to the accounting ledger.

---

## Why Show Journal Lines on Bill Detail?

Because users and developers need to trust that the bill affected accounting correctly.

The detail page proves:

```txt
Bill subtotal = Purchases debit
GST amount = GST Input Tax debit
Bill total = Accounts Payable credit
```

---

# Part 21 Completion Checklist

You are ready for Part 22 if:

- [ ] `services/bills/get-bills.ts` exists
- [ ] Bill list queries are scoped by active organization
- [ ] Bill detail queries are scoped by active organization
- [ ] `/bills` shows clickable bill rows
- [ ] `components/bill-list-table.tsx` exists
- [ ] `/bills/[billId]` exists
- [ ] Bill detail page shows vendor details
- [ ] Bill detail page shows bill lines
- [ ] Bill detail page shows subtotal, GST, and total
- [ ] Bill detail page shows linked journal entry
- [ ] Bill detail page shows journal lines
- [ ] Missing or cross-tenant bills show not found
- [ ] Neon SQL confirms bill and journal linkage
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
