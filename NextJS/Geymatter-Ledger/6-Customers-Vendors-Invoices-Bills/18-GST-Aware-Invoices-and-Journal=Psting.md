# Part 18 — Create GST-Aware Invoices with Journal Posting

In Part 17, we created invoice tables and GST helpers.

Now we will create real GST-aware invoices and post them to the journal.

By the end of this part, you will have:

- A working invoice creation form
- GST-exclusive invoice line calculation
- Automatic invoice number generation
- Invoice records saved to Postgres
- Invoice lines saved to Postgres
- A balanced journal entry posted for each invoice
- Invoice `journalEntryId` linked to the posted journal entry
- Updated invoice list page
- Direct journal verification
- Neon SQL verification

The accounting entry for a GST invoice is:

```txt
Debit  Accounts Receivable   Total invoice amount
Credit Sales Revenue         Subtotal before GST
Credit GST Output Tax        GST collected
```

Example:

```txt
Invoice for S$109.00 including 9% GST

Debit  Accounts Receivable   S$109.00
Credit Sales Revenue         S$100.00
Credit GST Output Tax        S$9.00
```

---

# 1. Understand the Invoice Posting Flow

## The Target

We are connecting invoices to the journal engine.

---

## The Concept

An invoice is a business document.

A journal entry is the accounting truth.

Think of the invoice as the customer-facing PDF, and the journal entry as the official accounting record behind it.

The flow will be:

```txt
User creates invoice
  |
  v
App calculates GST
  |
  v
App saves invoice and invoice line
  |
  v
App posts balanced journal entry
  |
  v
Invoice stores journalEntryId
```

---

## The Implementation

For now, we will build a simple one-line invoice form.

Later, we can expand to multiple lines.

The first version will collect:

```txt
Customer
Issue date
Due date
Description
Quantity
Unit amount before GST
GST rate
Notes
```

---

## The Verification

After creating an invoice, these should increase:

```txt
Invoice count
Invoice line count
Journal entry count
Journal line count
```

---

# 2. Replace Invoice Services with Creation Logic

## The Target

We are replacing:

```txt
services/invoices/invoice-services.ts
```

with full invoice creation and query logic.

---

## The Concept

The invoice service will own the business operation:

```txt
Create invoice and post accounting entry
```

This keeps the page simple.

The service will:

1. Require active organization.
2. Validate customer belongs to that organization.
3. Calculate GST totals.
4. Find required accounts:
   - `1100 Accounts Receivable`
   - `4000 Sales Revenue`
   - `2110 GST Output Tax`
5. Insert invoice and line.
6. Post journal entry and lines.
7. Link invoice to journal entry.

---

## The Implementation

Open:

```txt
services/invoices/invoice-services.ts
```

Replace it with:

```ts
// services/invoices/invoice-services.ts

import { auth } from "@clerk/nextjs/server";
import { and, count, desc, eq } from "drizzle-orm";
import { db } from "@/db";
import {
  accounts,
  customers,
  invoiceLines,
  invoices,
  journalEntries,
  journalLines,
  type Invoice,
} from "@/db/schema";
import {
  calculateInvoiceLineTotals,
  DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS,
} from "@/lib/accounting/gst";
import { dollarsToCents } from "@/lib/money";
import { validatePostJournalEntryInput } from "@/services/journal/validate-post-journal-entry";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type CreateInvoiceInput = {
  customerId: string;
  issueDate: string;
  dueDate: string;
  description: string;
  quantity: number;
  unitAmount: string;
  gstRateBasisPoints: number;
  notes?: string | null;
};

export type CreateInvoiceResult =
  | {
      ok: true;
      invoice: Invoice;
    }
  | {
      ok: false;
      error: string;
    };

const requiredInvoiceAccountCodes = {
  accountsReceivable: "1100",
  salesRevenue: "4000",
  gstOutputTax: "2110",
} as const;

function isValidDateString(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }

  const parsed = new Date(`${value}T00:00:00.000Z`);

  if (Number.isNaN(parsed.getTime())) {
    return false;
  }

  return parsed.toISOString().slice(0, 10) === value;
}

function normalizeOptionalText(value?: string | null): string | null {
  const normalized = value?.trim() ?? "";
  return normalized.length > 0 ? normalized : null;
}

function validateCreateInvoiceInput(input: CreateInvoiceInput): string[] {
  const issues: string[] = [];

  if (!input.customerId.trim()) {
    issues.push("Customer is required.");
  }

  if (!isValidDateString(input.issueDate.trim())) {
    issues.push("Issue date must be a valid YYYY-MM-DD date.");
  }

  if (!isValidDateString(input.dueDate.trim())) {
    issues.push("Due date must be a valid YYYY-MM-DD date.");
  }

  if (
    isValidDateString(input.issueDate.trim()) &&
    isValidDateString(input.dueDate.trim()) &&
    input.dueDate.trim() < input.issueDate.trim()
  ) {
    issues.push("Due date cannot be before issue date.");
  }

  if (!input.description.trim()) {
    issues.push("Invoice line description is required.");
  }

  if (input.description.trim().length > 500) {
    issues.push("Invoice line description must be 500 characters or fewer.");
  }

  if (!Number.isInteger(input.quantity) || input.quantity <= 0) {
    issues.push("Quantity must be a positive integer.");
  }

  if (
    !Number.isInteger(input.gstRateBasisPoints) ||
    input.gstRateBasisPoints < 0 ||
    input.gstRateBasisPoints > 10000
  ) {
    issues.push("GST rate must be between 0 and 10000 basis points.");
  }

  try {
    dollarsToCents(input.unitAmount);
  } catch {
    issues.push("Unit amount must be a valid money amount.");
  }

  const notes = normalizeOptionalText(input.notes);

  if (notes && notes.length > 1000) {
    issues.push("Notes must be 1000 characters or fewer.");
  }

  return issues;
}

async function generateNextInvoiceNumberForOrganization(
  organizationId: string,
): Promise<string> {
  const currentYear = new Date().getFullYear();

  const [row] = await db
    .select({ value: count() })
    .from(invoices)
    .where(eq(invoices.organizationId, organizationId));

  const nextNumber = (row?.value ?? 0) + 1;

  return `INV-${currentYear}-${String(nextNumber).padStart(4, "0")}`;
}

/**
 * Creates a GST-aware invoice and posts the matching journal entry.
 *
 * This function is intentionally tenant-scoped:
 * - it uses the active database organization
 * - it verifies the customer belongs to that organization
 * - it only uses accounts belonging to that organization
 */
export async function createInvoiceForCurrentOrganization(
  input: CreateInvoiceInput,
): Promise<CreateInvoiceResult> {
  const organization = await requireCurrentDatabaseOrganization();
  const { userId } = await auth();

  const validationIssues = validateCreateInvoiceInput(input);

  if (validationIssues.length > 0) {
    return {
      ok: false,
      error: validationIssues.join(" "),
    };
  }

  const issueDate = input.issueDate.trim();
  const dueDate = input.dueDate.trim();
  const description = input.description.trim();
  const notes = normalizeOptionalText(input.notes);
  const unitAmountCents = dollarsToCents(input.unitAmount);

  const lineTotals = calculateInvoiceLineTotals({
    quantity: input.quantity,
    unitAmountCents,
    gstRateBasisPoints: input.gstRateBasisPoints,
  });

  try {
    const result = await db.transaction(async (tx) => {
      const [customer] = await tx
        .select()
        .from(customers)
        .where(
          and(
            eq(customers.id, input.customerId.trim()),
            eq(customers.organizationId, organization.id),
          ),
        )
        .limit(1);

      if (!customer) {
        throw new Error("Customer does not exist for the active organization.");
      }

      if (!customer.isActive) {
        throw new Error("Customer is inactive.");
      }

      const requiredAccountCodes = Object.values(requiredInvoiceAccountCodes);

      const accountRows = await tx
        .select()
        .from(accounts)
        .where(eq(accounts.organizationId, organization.id));

      const accountByCode = new Map(
        accountRows.map((account) => [account.code, account]),
      );

      for (const code of requiredAccountCodes) {
        const account = accountByCode.get(code);

        if (!account) {
          throw new Error(
            `Required account ${code} is missing. Seed the chart of accounts first.`,
          );
        }

        if (!account.isActive) {
          throw new Error(`Required account ${code} is inactive.`);
        }
      }

      const accountsReceivable =
        accountByCode.get(requiredInvoiceAccountCodes.accountsReceivable)!;
      const salesRevenue =
        accountByCode.get(requiredInvoiceAccountCodes.salesRevenue)!;
      const gstOutputTax =
        accountByCode.get(requiredInvoiceAccountCodes.gstOutputTax)!;

      const invoiceNumber =
        await generateNextInvoiceNumberForOrganization(organization.id);

      const now = new Date();

      const [createdInvoice] = await tx
        .insert(invoices)
        .values({
          organizationId: organization.id,
          customerId: customer.id,
          invoiceNumber,
          issueDate,
          dueDate,
          status: "sent",
          subtotalCents: lineTotals.subtotalCents,
          gstCents: lineTotals.gstCents,
          totalCents: lineTotals.totalCents,
          notes,
          createdAt: now,
          updatedAt: now,
        })
        .returning();

      if (!createdInvoice) {
        throw new Error("Invoice could not be created.");
      }

      await tx.insert(invoiceLines).values({
        invoiceId: createdInvoice.id,
        organizationId: organization.id,
        lineNumber: 1,
        description,
        quantity: lineTotals.quantity,
        unitAmountCents: lineTotals.unitAmountCents,
        subtotalCents: lineTotals.subtotalCents,
        gstRateBasisPoints: lineTotals.gstRateBasisPoints,
        gstCents: lineTotals.gstCents,
        totalCents: lineTotals.totalCents,
        createdAt: now,
      });

      const journalLineInputs = [
        {
          accountId: accountsReceivable.id,
          description: `Invoice ${invoiceNumber}: customer receivable`,
          debitCents: lineTotals.totalCents,
          creditCents: 0,
        },
        {
          accountId: salesRevenue.id,
          description: `Invoice ${invoiceNumber}: sales revenue`,
          debitCents: 0,
          creditCents: lineTotals.subtotalCents,
        },
      ];

      if (lineTotals.gstCents > 0) {
        journalLineInputs.push({
          accountId: gstOutputTax.id,
          description: `Invoice ${invoiceNumber}: GST output tax`,
          debitCents: 0,
          creditCents: lineTotals.gstCents,
        });
      }

      const journalValidation = validatePostJournalEntryInput({
        entryDate: issueDate,
        memo: `Invoice ${invoiceNumber} issued to ${customer.name}`,
        sourceType: "invoice",
        sourceId: createdInvoice.id,
        lines: journalLineInputs,
      });

      if (journalValidation.issues.length > 0) {
        throw new Error(journalValidation.issues.join(" "));
      }

      const [createdJournalEntry] = await tx
        .insert(journalEntries)
        .values({
          organizationId: organization.id,
          entryDate: issueDate,
          memo: `Invoice ${invoiceNumber} issued to ${customer.name}`,
          sourceType: "invoice",
          sourceId: createdInvoice.id,
          postedByUserId: userId ?? null,
          createdAt: now,
          updatedAt: now,
        })
        .returning();

      if (!createdJournalEntry) {
        throw new Error("Journal entry could not be created.");
      }

      await tx.insert(journalLines).values(
        journalValidation.normalizedInput.lines.map((line, index) => ({
          journalEntryId: createdJournalEntry.id,
          organizationId: organization.id,
          accountId: line.accountId,
          lineNumber: index + 1,
          description: line.description,
          debitCents: line.debitCents,
          creditCents: line.creditCents,
          createdAt: now,
        })),
      );

      const [updatedInvoice] = await tx
        .update(invoices)
        .set({
          journalEntryId: createdJournalEntry.id,
          updatedAt: now,
        })
        .where(eq(invoices.id, createdInvoice.id))
        .returning();

      if (!updatedInvoice) {
        throw new Error("Invoice could not be linked to journal entry.");
      }

      return updatedInvoice;
    });

    return {
      ok: true,
      invoice: result,
    };
  } catch (error) {
    return {
      ok: false,
      error:
        error instanceof Error
          ? error.message
          : "Unexpected error while creating invoice.",
    };
  }
}

export async function getCurrentOrganizationInvoiceDiagnostics(): Promise<{
  organizationId: string | null;
  invoiceCount: number;
  invoiceLineCount: number;
  recentInvoices: Array<{
    id: string;
    invoiceNumber: string;
    customerName: string;
    issueDate: string;
    dueDate: string;
    status: string;
    subtotalCents: number;
    gstCents: number;
    totalCents: number;
  }>;
}> {
  const organization = await requireCurrentDatabaseOrganization().catch(
    () => null,
  );

  if (!organization) {
    return {
      organizationId: null,
      invoiceCount: 0,
      invoiceLineCount: 0,
      recentInvoices: [],
    };
  }

  const [invoiceCountRow] = await db
    .select({ value: count() })
    .from(invoices)
    .where(eq(invoices.organizationId, organization.id));

  const [invoiceLineCountRow] = await db
    .select({ value: count() })
    .from(invoiceLines)
    .where(eq(invoiceLines.organizationId, organization.id));

  const recentInvoices = await db
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
    })
    .from(invoices)
    .innerJoin(customers, eq(invoices.customerId, customers.id))
    .where(eq(invoices.organizationId, organization.id))
    .orderBy(desc(invoices.createdAt))
    .limit(10);

  return {
    organizationId: organization.id,
    invoiceCount: invoiceCountRow?.value ?? 0,
    invoiceLineCount: invoiceLineCountRow?.value ?? 0,
    recentInvoices,
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

# 3. Create Invoice Server Actions

## The Target

We are creating:

```txt
app/invoices/actions.ts
```

---

## The Concept

The form on `/invoices` will submit to a server action.

That action calls:

```ts
createInvoiceForCurrentOrganization()
```

---

## The Implementation

Create:

```txt
app/invoices/actions.ts
```

Add:

```ts
// app/invoices/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import {
  createInvoiceForCurrentOrganization,
} from "@/services/invoices/invoice-services";

function revalidateInvoiceViews() {
  revalidatePath("/invoices");
  revalidatePath("/settings/database");
  revalidatePath("/settings/database/invoices");
  revalidatePath("/settings/database/journal");
}

export async function createInvoiceAction(formData: FormData) {
  const result = await createInvoiceForCurrentOrganization({
    customerId: String(formData.get("customerId") ?? ""),
    issueDate: String(formData.get("issueDate") ?? ""),
    dueDate: String(formData.get("dueDate") ?? ""),
    description: String(formData.get("description") ?? ""),
    quantity: Number(formData.get("quantity") ?? 1),
    unitAmount: String(formData.get("unitAmount") ?? ""),
    gstRateBasisPoints: Number(formData.get("gstRateBasisPoints") ?? 900),
    notes: String(formData.get("notes") ?? ""),
  });

  revalidateInvoiceViews();

  if (!result.ok) {
    redirect(`/invoices?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect(`/invoices?status=created&invoice=${result.invoice.invoiceNumber}`);
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 4. Create Invoice Status Banner

## The Target

We are creating:

```txt
components/invoice-status-banner.tsx
```

---

## The Implementation

Create:

```txt
components/invoice-status-banner.tsx
```

Add:

```tsx
// components/invoice-status-banner.tsx

type InvoiceStatusBannerProps = {
  status?: string;
  message?: string;
  invoiceNumber?: string;
};

export function InvoiceStatusBanner({
  status,
  message,
  invoiceNumber,
}: InvoiceStatusBannerProps) {
  if (!status) {
    return null;
  }

  if (status === "created") {
    return (
      <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
        <p className="text-sm font-semibold">
          Invoice {invoiceNumber ?? ""} created and posted successfully.
        </p>

        <p className="mt-2 text-sm leading-6">
          The invoice was saved, GST was calculated, and a balanced journal
          entry was posted.
        </p>
      </section>
    );
  }

  if (status === "error") {
    return (
      <section className="rounded-2xl border border-rose-200 bg-rose-50 p-5 text-rose-800">
        <p className="text-sm font-semibold">Invoice could not be created.</p>
        {message ? <p className="mt-2 text-sm leading-6">{message}</p> : null}
      </section>
    );
  }

  return null;
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Create Invoice Form Component

## The Target

We are creating:

```txt
components/invoice-create-form.tsx
```

---

## The Concept

For this first invoice form, we support one line.

That is enough to test the full accounting flow:

```txt
Customer
Line amount
GST
Invoice
Journal
```

---

## The Implementation

Create:

```txt
components/invoice-create-form.tsx
```

Add:

```tsx
// components/invoice-create-form.tsx

import type { Customer } from "@/db/schema";
import { createInvoiceAction } from "@/app/invoices/actions";
import { DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS } from "@/lib/accounting/gst";

type InvoiceCreateFormProps = {
  customers: Customer[];
};

function todayString(): string {
  return new Date().toISOString().slice(0, 10);
}

function defaultDueDateString(): string {
  const date = new Date();
  date.setDate(date.getDate() + 30);
  return date.toISOString().slice(0, 10);
}

export function InvoiceCreateForm({ customers }: InvoiceCreateFormProps) {
  if (customers.length === 0) {
    return (
      <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-800">
        <p className="text-sm font-semibold">Create a customer first.</p>
        <p className="mt-2 text-sm leading-6">
          Invoices must belong to a customer. Add a customer before creating an
          invoice.
        </p>
      </section>
    );
  }

  return (
    <form
      action={createInvoiceAction}
      className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
    >
      <div>
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
          New invoice
        </p>

        <h2 className="mt-3 text-lg font-semibold text-slate-950">
          Create GST-aware invoice
        </h2>

        <p className="mt-2 text-sm leading-6 text-slate-500">
          This creates an invoice, calculates GST, and posts the accounting
          entry to the journal.
        </p>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-3">
        <label className="block">
          <span className="text-sm font-semibold text-slate-700">
            Customer
          </span>
          <select
            name="customerId"
            required
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          >
            {customers.map((customer) => (
              <option key={customer.id} value={customer.id}>
                {customer.name}
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-slate-700">
            Issue date
          </span>
          <input
            name="issueDate"
            type="date"
            required
            defaultValue={todayString()}
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-slate-700">
            Due date
          </span>
          <input
            name="dueDate"
            type="date"
            required
            defaultValue={defaultDueDateString()}
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>
      </div>

      <div className="mt-6 rounded-2xl border border-slate-200 bg-slate-50 p-4">
        <h3 className="text-sm font-semibold text-slate-950">
          Invoice line
        </h3>

        <div className="mt-4 grid gap-4 md:grid-cols-[1.4fr_0.4fr_0.6fr_0.6fr]">
          <label className="block">
            <span className="text-sm font-semibold text-slate-700">
              Description
            </span>
            <input
              name="description"
              required
              maxLength={500}
              defaultValue="Consulting services"
              className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
            />
          </label>

          <label className="block">
            <span className="text-sm font-semibold text-slate-700">
              Quantity
            </span>
            <input
              name="quantity"
              type="number"
              min={1}
              step={1}
              required
              defaultValue={1}
              className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
            />
          </label>

          <label className="block">
            <span className="text-sm font-semibold text-slate-700">
              Unit amount
            </span>
            <input
              name="unitAmount"
              required
              defaultValue="100.00"
              placeholder="100.00"
              className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
            />
          </label>

          <label className="block">
            <span className="text-sm font-semibold text-slate-700">
              GST basis points
            </span>
            <input
              name="gstRateBasisPoints"
              type="number"
              min={0}
              max={10000}
              step={1}
              required
              defaultValue={DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS}
              className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
            />
          </label>
        </div>
      </div>

      <label className="mt-4 block">
        <span className="text-sm font-semibold text-slate-700">Notes</span>
        <textarea
          name="notes"
          rows={3}
          maxLength={1000}
          placeholder="Optional invoice notes."
          className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
        />
      </label>

      <div className="mt-5 flex justify-end">
        <button
          type="submit"
          className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
        >
          Create and post invoice
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

# 6. Update the Invoices Page

## The Target

We are updating:

```txt
app/invoices/page.tsx
```

to include:

- Invoice form
- Invoice status banner
- Recent invoice table

---

## The Implementation

Open:

```txt
app/invoices/page.tsx
```

Replace it with:

```tsx
// app/invoices/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { InvoiceCreateForm } from "@/components/invoice-create-form";
import { InvoiceStatusBanner } from "@/components/invoice-status-banner";
import { formatMoney } from "@/lib/money";
import { listCurrentOrganizationCustomers } from "@/services/customers/customer-services";
import { getCurrentOrganizationInvoiceDiagnostics } from "@/services/invoices/invoice-services";

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

            {diagnostics.recentInvoices.length > 0 ? (
              <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
                <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
                  <h2 className="text-lg font-semibold text-slate-950">
                    Recent invoices
                  </h2>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full border-collapse text-left text-sm">
                    <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                      <tr>
                        <th className="px-6 py-3 font-semibold">Invoice</th>
                        <th className="px-6 py-3 font-semibold">Customer</th>
                        <th className="px-6 py-3 font-semibold">Status</th>
                        <th className="px-6 py-3 text-right font-semibold">
                          Subtotal
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
                      {diagnostics.recentInvoices.map((invoice) => (
                        <tr key={invoice.id}>
                          <td className="px-6 py-4 font-semibold text-slate-950">
                            {invoice.invoiceNumber}
                          </td>

                          <td className="px-6 py-4 text-slate-600">
                            {invoice.customerName}
                          </td>

                          <td className="px-6 py-4">
                            <span className="rounded-full bg-sky-50 px-2 py-1 text-xs font-semibold capitalize text-sky-700">
                              {invoice.status}
                            </span>
                          </td>

                          <td className="px-6 py-4 text-right text-slate-600">
                            {formatMoney(invoice.subtotalCents)}
                          </td>

                          <td className="px-6 py-4 text-right text-slate-600">
                            {formatMoney(invoice.gstCents)}
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
            ) : (
              <section className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
                <h2 className="text-lg font-semibold text-slate-950">
                  No invoices yet
                </h2>

                <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
                  Create your first invoice above. It will calculate GST and
                  post a balanced journal entry automatically.
                </p>
              </section>
            )}
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

You should see a create invoice form if you have at least one customer.

---

# 7. Update Database Status Page for Invoices

## The Target

We are updating:

```txt
app/settings/database/page.tsx
```

to display invoice counts.

---

## The Implementation

Open:

```txt
app/settings/database/page.tsx
```

Inside the health `<dl>`, after the vendor row block, add:

```tsx
<div className="grid gap-1 bg-slate-50 px-4 py-3 sm:grid-cols-3">
  <dt className="text-sm font-semibold text-slate-600">Invoice rows</dt>
  <dd className="text-sm text-slate-950 sm:col-span-2">
    {health.invoiceCount}
  </dd>
</div>

<div className="grid gap-1 bg-white px-4 py-3 sm:grid-cols-3">
  <dt className="text-sm font-semibold text-slate-600">Invoice line rows</dt>
  <dd className="text-sm text-slate-950 sm:col-span-2">
    {health.invoiceLineCount}
  </dd>
</div>
```

If you already added these in Part 17, make sure the page compiles and shows them.

---

## The Verification

Open:

```txt
http://localhost:3000/settings/database
```

You should see:

```txt
Invoice rows
Invoice line rows
```

---

# 8. Create a Customer if Needed

## The Target

We need at least one customer before creating an invoice.

---

## The Implementation

Open:

```txt
http://localhost:3000/customers
```

Create:

```txt
Name: Merlion Trading Pte. Ltd.
Email: accounts@merlion.example.com
Phone: +65 6123 4567
Billing address: 1 Raffles Place, Singapore
Notes: Demo invoice customer.
```

---

## The Verification

The customer should appear in the customers table.

---

# 9. Seed Accounts if Needed

## The Target

Invoice posting requires these accounts:

```txt
1100 Accounts Receivable
4000 Sales Revenue
2110 GST Output Tax
```

---

## The Implementation

Open:

```txt
http://localhost:3000/accounts
```

If no accounts exist, click:

```txt
Seed default accounts
```

If any required accounts are inactive, reactivate them.

---

## The Verification

Confirm these accounts exist and are active:

```txt
1100 Accounts Receivable
4000 Sales Revenue
2110 GST Output Tax
```

---

# 10. Create Your First GST Invoice

## The Target

We are creating a real invoice and posting it to the journal.

---

## The Implementation

Open:

```txt
http://localhost:3000/invoices
```

Use:

```txt
Customer: Merlion Trading Pte. Ltd.
Description: Consulting services
Quantity: 1
Unit amount: 100.00
GST basis points: 900
```

Click:

```txt
Create and post invoice
```

---

## The Verification

You should see:

```txt
Invoice INV-... created and posted successfully.
```

The invoice table should show:

```txt
Subtotal: S$100.00
GST:      S$9.00
Total:    S$109.00
```

---

# 11. Verify Journal Posting

## The Target

We are confirming the invoice created a balanced journal entry.

---

## The Implementation

Open:

```txt
http://localhost:3000/settings/database/journal
```

Look for an entry like:

```txt
Invoice INV-... issued to Merlion Trading Pte. Ltd.
```

It should have:

```txt
Debit  1100 Accounts Receivable  S$109.00
Credit 4000 Sales Revenue        S$100.00
Credit 2110 GST Output Tax       S$9.00
```

---

## The Verification

The entry should show:

```txt
Balanced
```

---

# 12. Verify in Neon SQL

## The Target

We are checking invoice and journal rows directly.

---

## The Implementation

Run:

```sql
select
  i.invoice_number,
  c.name as customer_name,
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
  je.memo,
  a.code,
  a.name,
  jl.debit_cents,
  jl.credit_cents
from journal_entries je
join journal_lines jl
  on jl.journal_entry_id = je.id
join accounts a
  on a.id = jl.account_id
where je.source_type = 'invoice'
order by je.created_at desc, jl.line_number;
```

Run the balance check:

```sql
select
  je.id,
  je.memo,
  sum(jl.debit_cents) as total_debit_cents,
  sum(jl.credit_cents) as total_credit_cents,
  sum(jl.debit_cents) - sum(jl.credit_cents) as difference_cents
from journal_entries je
join journal_lines jl
  on jl.journal_entry_id = je.id
where je.source_type = 'invoice'
group by je.id, je.memo
order by je.memo;
```

---

## The Verification

Every invoice journal entry should have:

```txt
difference_cents = 0
```

---

# 13. Run Full Project Check

## The Target

We are verifying tests and build.

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

# 14. Commit GST-Aware Invoice Creation

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Create GST-aware invoices with journal posting"
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

## Error: Customer does not exist for the active organization

Make sure you created the customer while the same organization is active.

Open:

```txt
/customers
```

Create a customer again if needed.

---

## Error: Required account 1100, 4000, or 2110 is missing

Open:

```txt
/accounts
```

Click:

```txt
Seed default accounts
```

---

## Error: Required account is inactive

Open:

```txt
/accounts
```

Find the account and click:

```txt
Reactivate
```

---

## Error: Invoice total constraint fails

Check GST calculation.

The database requires:

```txt
total_cents = subtotal_cents + gst_cents
```

---

## Error: Journal entry is unbalanced

Check that invoice posting creates:

```txt
Debit AR total
Credit revenue subtotal
Credit GST output tax GST amount
```

The debit total must equal the credit total.

---

# Phase 6 Reference — Invoice Posting

## Invoice Document

The invoice stores customer-facing details:

```txt
Customer
Invoice number
Dates
Line items
GST
Total
Status
```

---

## Journal Entry

The journal entry stores accounting truth:

```txt
Debit Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

---

## GST Output Tax

GST collected from customers.

It is a liability because the business may owe it to IRAS.

---

## Accounts Receivable

Money customers owe the business.

It is an asset.

---

# Part 18 Completion Checklist

You are ready for Part 19 if:

- [ ] `createInvoiceForCurrentOrganization()` exists
- [ ] Invoice creation validates customer ownership
- [ ] Invoice creation calculates GST
- [ ] Invoice creation inserts invoice and invoice line
- [ ] Invoice creation posts journal entry
- [ ] Invoice stores `journalEntryId`
- [ ] `/invoices` has a create invoice form
- [ ] Creating S$100 invoice produces S$9 GST and S$109 total
- [ ] Journal entry debits AR and credits revenue/GST
- [ ] Journal diagnostics show invoice entry as balanced
- [ ] Neon SQL confirms invoice and journal rows
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
