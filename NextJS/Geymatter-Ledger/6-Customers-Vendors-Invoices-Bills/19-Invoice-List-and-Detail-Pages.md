# Part 19 — Invoice List and Detail Pages

In Part 18, we created GST-aware invoices and posted their accounting entries to the journal.

Now we will make invoices easier to inspect.

By the end of this part, you will have:

- A proper invoice list page
- Clickable invoice rows
- Invoice detail pages
- Invoice line display
- Customer information display
- GST subtotal / GST / total breakdown
- Linked journal entry inspection
- Journal lines shown directly on the invoice detail page
- Tenant-safe invoice queries
- Neon SQL verification queries

This part is about visibility.

An accounting system should not only create records. It should let users inspect exactly what happened.

---

# 1. Understand Invoice List and Detail Pages

## The Target

We are improving the invoice workflow by adding:

```txt
/invoices
/invoices/[invoiceId]
```

---

## The Concept

The invoice list is like a filing cabinet index.

It tells you:

```txt
Which invoices exist?
Who are they for?
How much are they?
What is their status?
```

The invoice detail page is like opening one file folder.

It shows:

```txt
Invoice header
Customer details
Invoice lines
GST totals
Linked journal entry
Journal lines
```

This matters because an invoice is both:

```txt
A business document
```

and:

```txt
A source document for accounting
```

The detail page helps us connect those two worlds.

---

## The Implementation

We will create a new query service:

```txt
services/invoices/get-invoices.ts
```

This keeps read/query logic separate from the invoice creation logic in:

```txt
services/invoices/invoice-services.ts
```

---

## The Verification

At the end:

1. Open `/invoices`.
2. Click an invoice number.
3. Confirm `/invoices/[invoiceId]` loads.
4. Confirm the page shows invoice lines and journal lines.

---

# 2. Create Invoice Query Services

## The Target

We are creating:

```txt
services/invoices/get-invoices.ts
```

This file will contain tenant-safe invoice list and detail queries.

---

## The Concept

Tenant-safe means every query is scoped to the active organization.

Bad:

```ts
await db.select().from(invoices);
```

Good:

```ts
await db
  .select()
  .from(invoices)
  .where(eq(invoices.organizationId, organization.id));
```

Without tenant filtering, one company could accidentally see another company’s invoices.

That is one of the most serious SaaS bugs.

---

## The Implementation

Create:

```txt
services/invoices/get-invoices.ts
```

Add:

```ts
// services/invoices/get-invoices.ts

import { and, asc, desc, eq } from "drizzle-orm";
import { db } from "@/db";
import {
  accounts,
  customers,
  invoiceLines,
  invoices,
  journalEntries,
  journalLines,
} from "@/db/schema";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

export type InvoiceListItem = {
  id: string;
  invoiceNumber: string;
  customerName: string;
  issueDate: string;
  dueDate: string;
  status: string;
  subtotalCents: number;
  gstCents: number;
  totalCents: number;
  journalEntryId: string | null;
  createdAt: Date;
};

export type InvoiceDetail = {
  id: string;
  invoiceNumber: string;
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
  customer: {
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
 * Lists invoices for the currently active organization.
 *
 * This powers the /invoices page.
 */
export async function listCurrentOrganizationInvoices(): Promise<{
  organizationId: string | null;
  invoices: InvoiceListItem[];
}> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return {
      organizationId: null,
      invoices: [],
    };
  }

  const rows = await db
    .select({
      id: invoices.id,
      invoiceNumber: invoices.invoiceNumber,
      customerName: customers.name,
      issueDate: invoices.issueDate,
      dueDate: invoices.dueDate,
      status: invoices.status,
      subtotalCents: invoices.subtotalCents,
      gstCents: invoices.gstCents,
      totalCents: invoices.totalCents,
      journalEntryId: invoices.journalEntryId,
      createdAt: invoices.createdAt,
    })
    .from(invoices)
    .innerJoin(customers, eq(invoices.customerId, customers.id))
    .where(eq(invoices.organizationId, organization.id))
    .orderBy(desc(invoices.createdAt));

  return {
    organizationId: organization.id,
    invoices: rows,
  };
}

/**
 * Loads one invoice with:
 * - customer details
 * - invoice lines
 * - linked journal entry
 * - linked journal lines
 *
 * Returns null when:
 * - no active organization exists
 * - the invoice does not belong to the active organization
 * - the invoice does not exist
 */
export async function getCurrentOrganizationInvoiceDetail(
  invoiceId: string,
): Promise<InvoiceDetail | null> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return null;
  }

  const [invoice] = await db
    .select({
      id: invoices.id,
      invoiceNumber: invoices.invoiceNumber,
      issueDate: invoices.issueDate,
      dueDate: invoices.dueDate,
      status: invoices.status,
      subtotalCents: invoices.subtotalCents,
      gstCents: invoices.gstCents,
      totalCents: invoices.totalCents,
      notes: invoices.notes,
      journalEntryId: invoices.journalEntryId,
      createdAt: invoices.createdAt,
      updatedAt: invoices.updatedAt,
      customerId: customers.id,
      customerName: customers.name,
      customerEmail: customers.email,
      customerPhone: customers.phone,
      customerBillingAddress: customers.billingAddress,
    })
    .from(invoices)
    .innerJoin(customers, eq(invoices.customerId, customers.id))
    .where(
      and(
        eq(invoices.id, invoiceId),
        eq(invoices.organizationId, organization.id),
      ),
    )
    .limit(1);

  if (!invoice) {
    return null;
  }

  const lines = await db
    .select({
      id: invoiceLines.id,
      lineNumber: invoiceLines.lineNumber,
      description: invoiceLines.description,
      quantity: invoiceLines.quantity,
      unitAmountCents: invoiceLines.unitAmountCents,
      subtotalCents: invoiceLines.subtotalCents,
      gstRateBasisPoints: invoiceLines.gstRateBasisPoints,
      gstCents: invoiceLines.gstCents,
      totalCents: invoiceLines.totalCents,
    })
    .from(invoiceLines)
    .where(
      and(
        eq(invoiceLines.invoiceId, invoice.id),
        eq(invoiceLines.organizationId, organization.id),
      ),
    )
    .orderBy(asc(invoiceLines.lineNumber));

  let journalEntry: InvoiceDetail["journalEntry"] = null;

  if (invoice.journalEntryId) {
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
          eq(journalEntries.id, invoice.journalEntryId),
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
    id: invoice.id,
    invoiceNumber: invoice.invoiceNumber,
    issueDate: invoice.issueDate,
    dueDate: invoice.dueDate,
    status: invoice.status,
    subtotalCents: invoice.subtotalCents,
    gstCents: invoice.gstCents,
    totalCents: invoice.totalCents,
    notes: invoice.notes,
    journalEntryId: invoice.journalEntryId,
    createdAt: invoice.createdAt,
    updatedAt: invoice.updatedAt,
    customer: {
      id: invoice.customerId,
      name: invoice.customerName,
      email: invoice.customerEmail,
      phone: invoice.customerPhone,
      billingAddress: invoice.customerBillingAddress,
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

# 3. Create an Invoice List Table Component

## The Target

We are creating:

```txt
components/invoice-list-table.tsx
```

This component displays invoice rows and links to detail pages.

---

## The Concept

The list page should let users quickly scan invoices.

Each row should show:

```txt
Invoice number
Customer
Dates
Status
Total
Journal posting status
```

The invoice number will link to:

```txt
/invoices/[invoiceId]
```

---

## The Implementation

Create:

```txt
components/invoice-list-table.tsx
```

Add:

```tsx
// components/invoice-list-table.tsx

import Link from "next/link";
import type { InvoiceListItem } from "@/services/invoices/get-invoices";
import { formatMoney } from "@/lib/money";

type InvoiceListTableProps = {
  invoices: InvoiceListItem[];
};

export function InvoiceListTable({ invoices }: InvoiceListTableProps) {
  if (invoices.length === 0) {
    return (
      <section className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
        <h2 className="text-lg font-semibold text-slate-950">
          No invoices yet
        </h2>

        <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
          Create your first invoice using the form above. It will calculate GST
          and post a balanced journal entry automatically.
        </p>
      </section>
    );
  }

  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
        <h2 className="text-lg font-semibold text-slate-950">
          {invoices.length} invoice{invoices.length === 1 ? "" : "s"}
        </h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-left text-sm">
          <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
            <tr>
              <th className="px-6 py-3 font-semibold">Invoice</th>
              <th className="px-6 py-3 font-semibold">Customer</th>
              <th className="px-6 py-3 font-semibold">Issue date</th>
              <th className="px-6 py-3 font-semibold">Due date</th>
              <th className="px-6 py-3 font-semibold">Status</th>
              <th className="px-6 py-3 font-semibold">Journal</th>
              <th className="px-6 py-3 text-right font-semibold">Total</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-slate-200">
            {invoices.map((invoice) => (
              <tr key={invoice.id}>
                <td className="px-6 py-4">
                  <Link
                    href={`/invoices/${invoice.id}`}
                    className="font-semibold text-slate-950 underline-offset-4 transition hover:text-emerald-700 hover:underline"
                  >
                    {invoice.invoiceNumber}
                  </Link>
                </td>

                <td className="px-6 py-4 text-slate-600">
                  {invoice.customerName}
                </td>

                <td className="px-6 py-4 text-slate-600">
                  {invoice.issueDate}
                </td>

                <td className="px-6 py-4 text-slate-600">
                  {invoice.dueDate}
                </td>

                <td className="px-6 py-4">
                  <span className="rounded-full bg-sky-50 px-2 py-1 text-xs font-semibold capitalize text-sky-700">
                    {invoice.status}
                  </span>
                </td>

                <td className="px-6 py-4">
                  {invoice.journalEntryId ? (
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
                  {formatMoney(invoice.totalCents)}
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

# 4. Update the Invoices Page to Use the List Table

## The Target

We are updating:

```txt
app/invoices/page.tsx
```

to use our new query service and list table.

---

## The Concept

The invoice page currently shows recent invoices from diagnostics.

Now we will use a dedicated invoice list query.

This keeps the page more product-like.

---

## The Implementation

Open:

```txt
app/invoices/page.tsx
```

Replace the entire file with:

```tsx
// app/invoices/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { InvoiceCreateForm } from "@/components/invoice-create-form";
import { InvoiceListTable } from "@/components/invoice-list-table";
import { InvoiceStatusBanner } from "@/components/invoice-status-banner";
import { listCurrentOrganizationCustomers } from "@/services/customers/customer-services";
import { getCurrentOrganizationInvoiceDiagnostics } from "@/services/invoices/invoice-services";
import { listCurrentOrganizationInvoices } from "@/services/invoices/get-invoices";

export const dynamic = "force-dynamic";

type InvoicesPageProps = {
  searchParams?: Promise<{
    status?: string;
    message?: string;
    invoice?: string;
  }>;
};

export default async function InvoicesPage({ searchParams }: InvoicesPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};

  const diagnostics = await getCurrentOrganizationInvoiceDiagnostics();
  const { organizationId, customers } = await listCurrentOrganizationCustomers();
  const invoiceList = await listCurrentOrganizationInvoices();

  return (
    <AppLayout
      title="Invoices"
      description="Invoices record sales to customers and create accounts receivable when posted."
    >
      <div className="space-y-6">
        <InvoiceStatusBanner
          status={resolvedSearchParams.status}
          message={resolvedSearchParams.message}
          invoiceNumber={resolvedSearchParams.invoice}
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
            <InvoiceCreateForm customers={customers} />

            <section className="grid gap-4 md:grid-cols-3">
              <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
                <p className="text-sm font-semibold text-slate-500">
                  Invoices
                </p>
                <p className="mt-2 text-3xl font-bold text-slate-950">
                  {diagnostics.invoiceCount}
                </p>
              </div>

              <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
                <p className="text-sm font-semibold text-slate-500">
                  Invoice lines
                </p>
                <p className="mt-2 text-3xl font-bold text-slate-950">
                  {diagnostics.invoiceLineCount}
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
                  View posted invoice journal entries.
                </p>
              </Link>
            </section>

            <InvoiceListTable invoices={invoiceList.invoices} />
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
http://localhost:3000/invoices
```

You should see your invoice list.

Each invoice number should be clickable.

Click an invoice.

It will 404 until we create the detail route in the next step.

---

# 5. Create the Invoice Detail Page

## The Target

We are creating:

```txt
app/invoices/[invoiceId]/page.tsx
```

---

## The Concept

The invoice detail page should prove the full chain:

```txt
Invoice
  |
  |-- Customer
  |-- Invoice lines
  |-- GST totals
  |-- Linked journal entry
        |
        |-- Journal lines
```

This page is extremely valuable for debugging accounting workflows.

When a user asks:

> Why did this invoice affect my reports?

The answer will be visible through the linked journal lines.

---

## The Implementation

Create the folder:

```bash
mkdir -p app/invoices/[invoiceId]
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force 'app/invoices/[invoiceId]'
```

Create:

```txt
app/invoices/[invoiceId]/page.tsx
```

Add:

```tsx
// app/invoices/[invoiceId]/page.tsx

import Link from "next/link";
import { notFound } from "next/navigation";
import { AppLayout } from "@/components/app-layout";
import { formatMoney } from "@/lib/money";
import { getCurrentOrganizationInvoiceDetail } from "@/services/invoices/get-invoices";

export const dynamic = "force-dynamic";

type InvoiceDetailPageProps = {
  params: Promise<{
    invoiceId: string;
  }>;
};

export default async function InvoiceDetailPage({
  params,
}: InvoiceDetailPageProps) {
  const { invoiceId } = await params;
  const invoice = await getCurrentOrganizationInvoiceDetail(invoiceId);

  if (!invoice) {
    notFound();
  }

  const journalTotalDebitCents =
    invoice.journalEntry?.lines.reduce(
      (sum, line) => sum + line.debitCents,
      0,
    ) ?? 0;

  const journalTotalCreditCents =
    invoice.journalEntry?.lines.reduce(
      (sum, line) => sum + line.creditCents,
      0,
    ) ?? 0;

  return (
    <AppLayout
      title={`Invoice ${invoice.invoiceNumber}`}
      description="Review invoice details, GST calculation, customer information, and the linked journal entry."
    >
      <div className="space-y-6">
        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.2em] text-sky-600">
                Invoice detail
              </p>

              <h2 className="mt-3 text-2xl font-bold tracking-tight text-slate-950">
                {invoice.invoiceNumber}
              </h2>

              <p className="mt-2 text-sm leading-6 text-slate-500">
                Issued on {invoice.issueDate}. Due on {invoice.dueDate}.
              </p>

              <div className="mt-4 flex flex-wrap gap-2">
                <span className="rounded-full bg-sky-50 px-3 py-1 text-xs font-semibold capitalize text-sky-700">
                  {invoice.status}
                </span>

                {invoice.journalEntryId ? (
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
                href="/invoices"
                className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
              >
                Back to invoices
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
            <h2 className="text-lg font-semibold text-slate-950">Customer</h2>

            <dl className="mt-4 space-y-4 text-sm">
              <div>
                <dt className="font-semibold text-slate-600">Name</dt>
                <dd className="mt-1 text-slate-950">{invoice.customer.name}</dd>
              </div>

              <div>
                <dt className="font-semibold text-slate-600">Email</dt>
                <dd className="mt-1 text-slate-950">
                  {invoice.customer.email ?? "—"}
                </dd>
              </div>

              <div>
                <dt className="font-semibold text-slate-600">Phone</dt>
                <dd className="mt-1 text-slate-950">
                  {invoice.customer.phone ?? "—"}
                </dd>
              </div>

              <div>
                <dt className="font-semibold text-slate-600">
                  Billing address
                </dt>
                <dd className="mt-1 whitespace-pre-wrap text-slate-950">
                  {invoice.customer.billingAddress ?? "—"}
                </dd>
              </div>
            </dl>
          </article>

          <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-slate-950">
              Invoice totals
            </h2>

            <dl className="mt-4 divide-y divide-slate-200 overflow-hidden rounded-xl border border-slate-200">
              <div className="grid grid-cols-2 bg-slate-50 px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Subtotal
                </dt>
                <dd className="text-right text-sm font-semibold text-slate-950">
                  {formatMoney(invoice.subtotalCents)}
                </dd>
              </div>

              <div className="grid grid-cols-2 bg-white px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">GST</dt>
                <dd className="text-right text-sm font-semibold text-slate-950">
                  {formatMoney(invoice.gstCents)}
                </dd>
              </div>

              <div className="grid grid-cols-2 bg-slate-950 px-4 py-3 text-white">
                <dt className="text-sm font-bold">Total</dt>
                <dd className="text-right text-sm font-bold">
                  {formatMoney(invoice.totalCents)}
                </dd>
              </div>
            </dl>

            {invoice.notes ? (
              <div className="mt-4 rounded-xl bg-slate-50 p-4">
                <p className="text-sm font-semibold text-slate-700">Notes</p>
                <p className="mt-2 text-sm leading-6 text-slate-500">
                  {invoice.notes}
                </p>
              </div>
            ) : null}
          </article>
        </section>

        <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
            <h2 className="text-lg font-semibold text-slate-950">
              Invoice lines
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
                  <th className="px-6 py-3 text-right font-semibold">GST</th>
                  <th className="px-6 py-3 text-right font-semibold">Total</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-200">
                {invoice.lines.map((line) => (
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

        {invoice.journalEntry ? (
          <section className="overflow-hidden rounded-2xl border border-emerald-200 bg-white shadow-sm">
            <div className="border-b border-emerald-200 bg-emerald-50 px-6 py-4">
              <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-700">
                    Linked journal entry
                  </p>

                  <h2 className="mt-2 text-lg font-semibold text-slate-950">
                    {invoice.journalEntry.memo}
                  </h2>

                  <p className="mt-1 break-all font-mono text-xs text-emerald-700">
                    {invoice.journalEntry.id}
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
                  {invoice.journalEntry.lines.map((line) => (
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
              This invoice does not have a linked journal entry.
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
http://localhost:3000/invoices
```

Click an invoice number.

You should arrive at a URL like:

```txt
http://localhost:3000/invoices/your-invoice-id
```

You should see:

- Invoice header
- Customer details
- Invoice lines
- Invoice totals
- Linked journal entry
- Journal lines
- Balanced badge

---

# 6. Add an Invoice Not Found Page

## The Target

We are creating:

```txt
app/invoices/[invoiceId]/not-found.tsx
```

---

## The Concept

If a user opens an invoice that does not exist or does not belong to the active organization, we should show a clean not-found page.

This avoids leaking whether another organization’s invoice exists.

That is a subtle but important multi-tenant security habit.

---

## The Implementation

Create:

```txt
app/invoices/[invoiceId]/not-found.tsx
```

Add:

```tsx
// app/invoices/[invoiceId]/not-found.tsx

import Link from "next/link";

export default function InvoiceNotFoundPage() {
  return (
    <main className="min-h-screen bg-slate-50 px-6 py-16 text-slate-950">
      <section className="mx-auto max-w-2xl rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-rose-600">
          Invoice not found
        </p>

        <h1 className="mt-3 text-2xl font-bold tracking-tight">
          We could not find that invoice.
        </h1>

        <p className="mt-3 text-sm leading-6 text-slate-500">
          The invoice may not exist, or it may not belong to the active company
          workspace.
        </p>

        <Link
          href="/invoices"
          className="mt-6 inline-flex rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
        >
          Back to invoices
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
http://localhost:3000/invoices/not-a-real-id
```

You should see the not-found page.

---

# 7. Improve Invoice Database Diagnostics Linkage

## The Target

We are updating:

```txt
app/settings/database/invoices/page.tsx
```

so invoice numbers link to detail pages.

---

## The Concept

Diagnostics should be connected.

If the diagnostics page lists invoices, it should let us inspect one.

---

## The Implementation

Open:

```txt
app/settings/database/invoices/page.tsx
```

Find this table cell:

```tsx
<td className="px-4 py-3 font-semibold text-slate-950">
  {invoice.invoiceNumber}
</td>
```

Replace it with:

```tsx
<td className="px-4 py-3 font-semibold text-slate-950">
  <Link
    href={`/invoices/${invoice.id}`}
    className="underline-offset-4 transition hover:text-emerald-700 hover:underline"
  >
    {invoice.invoiceNumber}
  </Link>
</td>
```

Make sure the file already imports `Link` from `next/link`.

It should already have:

```tsx
import Link from "next/link";
```

---

## The Verification

Open:

```txt
http://localhost:3000/settings/database/invoices
```

Click an invoice number.

You should arrive at the invoice detail page.

---

# 8. Verify the Invoice Detail Page Against Journal Diagnostics

## The Target

We are confirming that invoice details match journal diagnostics.

---

## The Concept

The invoice detail page and journal diagnostics page are two views of the same accounting event.

The invoice detail page starts from the invoice.

The journal diagnostics page starts from the ledger.

They should agree.

---

## The Implementation

Open an invoice detail page:

```txt
/invoices/[invoiceId]
```

Note the journal entry memo.

Now open:

```txt
/settings/database/journal
```

Find the same memo.

---

## The Verification

The journal lines should match.

For a S$109 GST invoice:

```txt
Invoice detail:
Subtotal S$100.00
GST      S$9.00
Total    S$109.00

Journal:
Debit  Accounts Receivable S$109.00
Credit Sales Revenue       S$100.00
Credit GST Output Tax      S$9.00
```

Both views should show the same accounting story.

---

# 9. Verify Tenant Isolation

## The Target

We are verifying that invoices belong only to the active organization.

---

## The Concept

If you switch organizations, the invoice list should change.

Company A should not see Company B’s invoices.

This is tenant isolation.

---

## The Implementation

If you have two organizations:

1. Select Organization A.
2. Create an invoice.
3. Open `/invoices`.
4. Confirm the invoice appears.
5. Switch to Organization B.
6. Open `/invoices`.

---

## The Verification

The Organization A invoice should not appear in Organization B.

If it does, invoice queries are not correctly scoped by organization.

---

# 10. Verify in Neon SQL

## The Target

We are directly checking invoice detail data in Neon.

---

## The Concept

Direct SQL gives confidence that the app UI is reflecting real database state.

---

## The Implementation

Open Neon SQL editor.

Run:

```sql
select
  i.invoice_number,
  c.name as customer_name,
  i.issue_date,
  i.due_date,
  i.status,
  i.subtotal_cents,
  i.gst_cents,
  i.total_cents,
  i.journal_entry_id
from invoices i
join customers c
  on c.id = i.customer_id
order by i.created_at desc;
```

Run:

```sql
select
  i.invoice_number,
  il.line_number,
  il.description,
  il.quantity,
  il.unit_amount_cents,
  il.subtotal_cents,
  il.gst_rate_basis_points,
  il.gst_cents,
  il.total_cents
from invoice_lines il
join invoices i
  on i.id = il.invoice_id
order by i.created_at desc, il.line_number;
```

Run:

```sql
select
  i.invoice_number,
  je.memo,
  a.code,
  a.name,
  jl.debit_cents,
  jl.credit_cents
from invoices i
join journal_entries je
  on je.id = i.journal_entry_id
join journal_lines jl
  on jl.journal_entry_id = je.id
join accounts a
  on a.id = jl.account_id
order by i.created_at desc, jl.line_number;
```

---

## The Verification

For a S$100 subtotal invoice with 9% GST, you should see:

```txt
subtotal_cents = 10000
gst_cents      = 900
total_cents    = 10900
```

And journal lines:

```txt
1100 Accounts Receivable debit 10900
4000 Sales Revenue credit 10000
2110 GST Output Tax credit 900
```

---

# 11. Run the Full Project Check

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

# 12. Commit Invoice List and Detail Pages

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Build invoice list and detail pages"
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

## Error: Invoice detail page shows not found

Possible causes:

```txt
The invoice ID is wrong.
The invoice belongs to another organization.
No active organization is selected.
```

Go back to:

```txt
/invoices
```

and click an invoice from the list.

---

## Error: Invoice detail page has no journal entry

If the invoice was created before Part 18, it may not have `journalEntryId`.

Create a new invoice using the current `/invoices` form.

---

## Error: Journal lines do not appear

Check the invoice row:

```sql
select invoice_number, journal_entry_id
from invoices;
```

If `journal_entry_id` is null, the invoice was not linked to a journal entry.

---

## Error: Invoice appears in the wrong organization

Check that all invoice queries filter by:

```ts
eq(invoices.organizationId, organization.id)
```

Also verify that invoice lines filter by:

```ts
eq(invoiceLines.organizationId, organization.id)
```

---

## Error: Not-found page does not use the app shell

That is okay for now.

The not-found page is intentionally simple and avoids trying to load invoice-specific app data.

---

# Phase 6 Reference — Invoice Visibility

## Invoice List

The invoice list helps users scan all invoices for the active organization.

---

## Invoice Detail

The invoice detail page shows the full business document and accounting result.

---

## Linked Journal Entry

The invoice’s `journalEntryId` connects the business document to the accounting ledger.

---

## Why Show Journal Lines on Invoice Detail?

Because users and developers need to trust that the invoice affected accounting correctly.

The detail page proves:

```txt
Invoice total = Accounts Receivable debit
Revenue subtotal = Sales Revenue credit
GST amount = GST Output Tax credit
```

---

# Part 19 Completion Checklist

You are ready for Part 20 if:

- [ ] `services/invoices/get-invoices.ts` exists
- [ ] Invoice list queries are scoped by active organization
- [ ] Invoice detail queries are scoped by active organization
- [ ] `/invoices` shows clickable invoice rows
- [ ] `components/invoice-list-table.tsx` exists
- [ ] `/invoices/[invoiceId]` exists
- [ ] Invoice detail page shows customer details
- [ ] Invoice detail page shows invoice lines
- [ ] Invoice detail page shows subtotal, GST, and total
- [ ] Invoice detail page shows linked journal entry
- [ ] Invoice detail page shows journal lines
- [ ] Missing or cross-tenant invoices show not found
- [ ] Invoice diagnostics link to detail pages
- [ ] Neon SQL confirms invoice and journal linkage
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
