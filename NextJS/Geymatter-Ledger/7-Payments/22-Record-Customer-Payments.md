# Phase 7 — Payments

# Part 22 — Record Customer Payments

In Phase 6, we created invoices and bills.

Now we start recording payments.

In this part, we focus on **customer payments**.

When a customer pays an invoice, we do **not** record revenue again.

Revenue was already recorded when the invoice was issued.

Instead, payment settles the receivable.

The accounting entry is:

```txt
Debit  Bank                  Payment amount
Credit Accounts Receivable   Payment amount
```

For a full payment of a S$109 invoice:

```txt
Debit  Bank                  S$109.00
Credit Accounts Receivable   S$109.00
```

By the end of this part, you will have:

- Customer payment tables
- Customer payment posting service
- Payment form on invoice detail pages
- Invoice status update to `paid`
- Journal entry for customer payment
- Linked payment diagnostics
- Neon SQL verification

We will support **full invoice payments** in this part.

Partial payments can be added later.

---

# 1. Understand Customer Payments

## The Target

We are recording money received from customers against invoices.

---

## The Concept

An invoice creates money owed by the customer.

That is Accounts Receivable.

Example invoice:

```txt
Debit  Accounts Receivable   S$109.00
Credit Sales Revenue         S$100.00
Credit GST Output Tax        S$9.00
```

When the customer pays, we do not touch revenue again.

Payment entry:

```txt
Debit  Bank                  S$109.00
Credit Accounts Receivable   S$109.00
```

Why?

Because:

```txt
Bank increases.
Customer receivable decreases.
```

Think of Accounts Receivable like a “customer owes us” bucket.

The invoice fills the bucket.

The payment empties the bucket and moves the money into the bank bucket.

---

# 2. Add Customer Payment Tables

## The Target

We are updating:

```txt
db/schema.ts
```

to add:

```txt
customer_payments
```

---

## The Concept

A payment record should store:

```txt
Organization
Customer
Invoice
Payment date
Amount
Reference
Linked journal entry
```

The journal entry stores accounting truth.

The payment row stores business workflow details.

---

## The Implementation

Open:

```txt
db/schema.ts
```

Add this table after `invoiceLines`:

```ts
export const customerPayments = pgTable(
  "customer_payments",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),

    customerId: uuid("customer_id")
      .notNull()
      .references(() => customers.id, { onDelete: "restrict" }),

    invoiceId: uuid("invoice_id")
      .notNull()
      .references(() => invoices.id, { onDelete: "restrict" }),

    paymentDate: date("payment_date").notNull(),

    amountCents: bigint("amount_cents", { mode: "number" }).notNull(),

    reference: text("reference"),

    journalEntryId: uuid("journal_entry_id").references(() => journalEntries.id, {
      onDelete: "set null",
    }),

    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),

    updatedAt: timestamp("updated_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    index("customer_payments_organization_id_idx").on(table.organizationId),
    index("customer_payments_organization_id_invoice_id_idx").on(
      table.organizationId,
      table.invoiceId,
    ),
    index("customer_payments_organization_id_customer_id_idx").on(
      table.organizationId,
      table.customerId,
    ),
    check(
      "customer_payments_amount_positive_check",
      sql`${table.amountCents} > 0`,
    ),
  ],
);
```

At the bottom, add:

```ts
export type CustomerPayment = typeof customerPayments.$inferSelect;
export type NewCustomerPayment = typeof customerPayments.$inferInsert;
```

Important:

If `customerPayments` references `journalEntries`, make sure `journalEntries` is declared before `customerPayments`.

A safe order is:

```txt
organizations
accounts
customers
vendors
journalEntries
journalLines
invoices
invoiceLines
customerPayments
bills
billLines
```

If TypeScript complains about declaration order, reorder the table definitions accordingly.

---

## The Verification

Generate and apply migration:

```bash
pnpm db:generate
pnpm db:migrate
```

Verify in Neon:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

You should see:

```txt
customer_payments
```

---

# 3. Create Customer Payment Service

## The Target

We are creating:

```txt
services/payments/customer-payment-services.ts
```

---

## The Concept

The service will:

1. Require active organization.
2. Verify invoice belongs to the organization.
3. Verify invoice is not already paid.
4. Create payment row.
5. Post journal entry:
   - Debit Bank
   - Credit Accounts Receivable
6. Link payment to journal entry.
7. Mark invoice as `paid`.

Required accounts:

```txt
1000 Bank
1100 Accounts Receivable
```

---

## The Implementation

Create:

```bash
mkdir -p services/payments
```

Create:

```txt
services/payments/customer-payment-services.ts
```

Add:

```ts
// services/payments/customer-payment-services.ts

import { auth } from "@clerk/nextjs/server";
import { and, count, desc, eq } from "drizzle-orm";
import { db } from "@/db";
import {
  accounts,
  customerPayments,
  customers,
  invoices,
  journalEntries,
  journalLines,
  type CustomerPayment,
} from "@/db/schema";
import { validatePostJournalEntryInput } from "@/services/journal/validate-post-journal-entry";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type RecordCustomerPaymentInput = {
  invoiceId: string;
  paymentDate: string;
  reference?: string | null;
};

export type RecordCustomerPaymentResult =
  | {
      ok: true;
      payment: CustomerPayment;
    }
  | {
      ok: false;
      error: string;
    };

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

export async function recordCustomerPaymentForCurrentOrganization(
  input: RecordCustomerPaymentInput,
): Promise<RecordCustomerPaymentResult> {
  const organization = await requireCurrentDatabaseOrganization();
  const { userId } = await auth();

  const paymentDate = input.paymentDate.trim();
  const reference = normalizeOptionalText(input.reference);

  if (!input.invoiceId.trim()) {
    return {
      ok: false,
      error: "Invoice is required.",
    };
  }

  if (!isValidDateString(paymentDate)) {
    return {
      ok: false,
      error: "Payment date must be a valid YYYY-MM-DD date.",
    };
  }

  try {
    const result = await db.transaction(async (tx) => {
      const [invoice] = await tx
        .select({
          id: invoices.id,
          invoiceNumber: invoices.invoiceNumber,
          organizationId: invoices.organizationId,
          customerId: invoices.customerId,
          status: invoices.status,
          totalCents: invoices.totalCents,
          customerName: customers.name,
        })
        .from(invoices)
        .innerJoin(customers, eq(invoices.customerId, customers.id))
        .where(
          and(
            eq(invoices.id, input.invoiceId.trim()),
            eq(invoices.organizationId, organization.id),
          ),
        )
        .limit(1);

      if (!invoice) {
        throw new Error("Invoice does not exist for the active organization.");
      }

      if (invoice.status === "paid") {
        throw new Error("Invoice is already paid.");
      }

      if (invoice.status === "void") {
        throw new Error("Cannot record payment for a void invoice.");
      }

      const accountRows = await tx
        .select()
        .from(accounts)
        .where(eq(accounts.organizationId, organization.id));

      const accountByCode = new Map(
        accountRows.map((account) => [account.code, account]),
      );

      const bank = accountByCode.get("1000");
      const accountsReceivable = accountByCode.get("1100");

      if (!bank) {
        throw new Error("Required account 1000 Bank is missing.");
      }

      if (!accountsReceivable) {
        throw new Error(
          "Required account 1100 Accounts Receivable is missing.",
        );
      }

      if (!bank.isActive) {
        throw new Error("Required account 1000 Bank is inactive.");
      }

      if (!accountsReceivable.isActive) {
        throw new Error(
          "Required account 1100 Accounts Receivable is inactive.",
        );
      }

      const now = new Date();

      const [createdPayment] = await tx
        .insert(customerPayments)
        .values({
          organizationId: organization.id,
          customerId: invoice.customerId,
          invoiceId: invoice.id,
          paymentDate,
          amountCents: invoice.totalCents,
          reference,
          createdAt: now,
          updatedAt: now,
        })
        .returning();

      if (!createdPayment) {
        throw new Error("Customer payment could not be created.");
      }

      const journalValidation = validatePostJournalEntryInput({
        entryDate: paymentDate,
        memo: `Payment received for invoice ${invoice.invoiceNumber} from ${invoice.customerName}`,
        sourceType: "customer_payment",
        sourceId: createdPayment.id,
        lines: [
          {
            accountId: bank.id,
            description: `Payment received for ${invoice.invoiceNumber}`,
            debitCents: invoice.totalCents,
            creditCents: 0,
          },
          {
            accountId: accountsReceivable.id,
            description: `Receivable cleared for ${invoice.invoiceNumber}`,
            debitCents: 0,
            creditCents: invoice.totalCents,
          },
        ],
      });

      if (journalValidation.issues.length > 0) {
        throw new Error(journalValidation.issues.join(" "));
      }

      const [createdJournalEntry] = await tx
        .insert(journalEntries)
        .values({
          organizationId: organization.id,
          entryDate: paymentDate,
          memo: `Payment received for invoice ${invoice.invoiceNumber} from ${invoice.customerName}`,
          sourceType: "customer_payment",
          sourceId: createdPayment.id,
          postedByUserId: userId ?? null,
          createdAt: now,
          updatedAt: now,
        })
        .returning();

      if (!createdJournalEntry) {
        throw new Error("Payment journal entry could not be created.");
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

      const [updatedPayment] = await tx
        .update(customerPayments)
        .set({
          journalEntryId: createdJournalEntry.id,
          updatedAt: now,
        })
        .where(eq(customerPayments.id, createdPayment.id))
        .returning();

      if (!updatedPayment) {
        throw new Error("Payment could not be linked to journal entry.");
      }

      await tx
        .update(invoices)
        .set({
          status: "paid",
          updatedAt: now,
        })
        .where(eq(invoices.id, invoice.id));

      return updatedPayment;
    });

    return {
      ok: true,
      payment: result,
    };
  } catch (error) {
    return {
      ok: false,
      error:
        error instanceof Error
          ? error.message
          : "Unexpected error while recording customer payment.",
    };
  }
}

export async function getCurrentOrganizationCustomerPaymentDiagnostics(): Promise<{
  organizationId: string | null;
  paymentCount: number;
  recentPayments: Array<{
    id: string;
    invoiceNumber: string;
    customerName: string;
    paymentDate: string;
    amountCents: number;
    reference: string | null;
    journalEntryId: string | null;
  }>;
}> {
  const organization = await requireCurrentDatabaseOrganization().catch(
    () => null,
  );

  if (!organization) {
    return {
      organizationId: null,
      paymentCount: 0,
      recentPayments: [],
    };
  }

  const [paymentCountRow] = await db
    .select({ value: count() })
    .from(customerPayments)
    .where(eq(customerPayments.organizationId, organization.id));

  const recentPayments = await db
    .select({
      id: customerPayments.id,
      invoiceNumber: invoices.invoiceNumber,
      customerName: customers.name,
      paymentDate: customerPayments.paymentDate,
      amountCents: customerPayments.amountCents,
      reference: customerPayments.reference,
      journalEntryId: customerPayments.journalEntryId,
    })
    .from(customerPayments)
    .innerJoin(invoices, eq(customerPayments.invoiceId, invoices.id))
    .innerJoin(customers, eq(customerPayments.customerId, customers.id))
    .where(eq(customerPayments.organizationId, organization.id))
    .orderBy(desc(customerPayments.createdAt))
    .limit(10);

  return {
    organizationId: organization.id,
    paymentCount: paymentCountRow?.value ?? 0,
    recentPayments,
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

# 4. Create Customer Payment Server Action

## The Target

We are creating:

```txt
app/invoices/[invoiceId]/actions.ts
```

---

## The Implementation

Create:

```txt
app/invoices/[invoiceId]/actions.ts
```

Add:

```ts
// app/invoices/[invoiceId]/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { recordCustomerPaymentForCurrentOrganization } from "@/services/payments/customer-payment-services";

export async function recordCustomerPaymentAction(formData: FormData) {
  const invoiceId = String(formData.get("invoiceId") ?? "");

  const result = await recordCustomerPaymentForCurrentOrganization({
    invoiceId,
    paymentDate: String(formData.get("paymentDate") ?? ""),
    reference: String(formData.get("reference") ?? ""),
  });

  revalidatePath("/invoices");
  revalidatePath(`/invoices/${invoiceId}`);
  revalidatePath("/payments");
  revalidatePath("/settings/database");
  revalidatePath("/settings/database/journal");

  if (!result.ok) {
    redirect(
      `/invoices/${invoiceId}?paymentStatus=error&paymentMessage=${encodeURIComponent(
        result.error,
      )}`,
    );
  }

  redirect(`/invoices/${invoiceId}?paymentStatus=recorded`);
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Create Customer Payment Form Component

## The Target

We are creating:

```txt
components/customer-payment-form.tsx
```

---

## The Concept

The payment form appears on the invoice detail page.

If the invoice is already paid, we show a paid message.

If not, we show a form.

---

## The Implementation

Create:

```txt
components/customer-payment-form.tsx
```

Add:

```tsx
// components/customer-payment-form.tsx

import { recordCustomerPaymentAction } from "@/app/invoices/[invoiceId]/actions";
import { formatMoney } from "@/lib/money";

type CustomerPaymentFormProps = {
  invoiceId: string;
  invoiceNumber: string;
  status: string;
  totalCents: number;
};

function todayString(): string {
  return new Date().toISOString().slice(0, 10);
}

export function CustomerPaymentForm({
  invoiceId,
  invoiceNumber,
  status,
  totalCents,
}: CustomerPaymentFormProps) {
  if (status === "paid") {
    return (
      <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 text-emerald-800">
        <p className="text-sm font-semibold">Invoice paid.</p>

        <p className="mt-2 text-sm leading-6">
          Invoice {invoiceNumber} has been marked as paid.
        </p>
      </section>
    );
  }

  if (status === "void") {
    return (
      <section className="rounded-2xl border border-slate-200 bg-slate-50 p-6 text-slate-700">
        <p className="text-sm font-semibold">Invoice void.</p>

        <p className="mt-2 text-sm leading-6">
          Payments cannot be recorded for void invoices.
        </p>
      </section>
    );
  }

  return (
    <form
      action={recordCustomerPaymentAction}
      className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
    >
      <input type="hidden" name="invoiceId" value={invoiceId} />

      <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
        Customer payment
      </p>

      <h2 className="mt-3 text-lg font-semibold text-slate-950">
        Record full payment
      </h2>

      <p className="mt-2 text-sm leading-6 text-slate-500">
        This records payment of {formatMoney(totalCents)} and posts:
      </p>

      <div className="mt-4 rounded-xl bg-slate-50 p-4 text-sm leading-6 text-slate-700">
        <p>Debit Bank {formatMoney(totalCents)}</p>
        <p>Credit Accounts Receivable {formatMoney(totalCents)}</p>
      </div>

      <div className="mt-5 grid gap-4 md:grid-cols-2">
        <label className="block">
          <span className="text-sm font-semibold text-slate-700">
            Payment date
          </span>
          <input
            name="paymentDate"
            type="date"
            required
            defaultValue={todayString()}
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-slate-700">
            Reference
          </span>
          <input
            name="reference"
            placeholder="Bank transfer reference"
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>
      </div>

      <div className="mt-5 flex justify-end">
        <button
          type="submit"
          className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
        >
          Record payment
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

# 6. Create Payment Status Banner

## The Target

We are creating:

```txt
components/payment-status-banner.tsx
```

---

## The Implementation

Create:

```txt
components/payment-status-banner.tsx
```

Add:

```tsx
// components/payment-status-banner.tsx

type PaymentStatusBannerProps = {
  status?: string;
  message?: string;
};

export function PaymentStatusBanner({
  status,
  message,
}: PaymentStatusBannerProps) {
  if (!status) {
    return null;
  }

  if (status === "recorded") {
    return (
      <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
        <p className="text-sm font-semibold">
          Payment recorded successfully.
        </p>

        <p className="mt-2 text-sm leading-6">
          The invoice was marked as paid and a balanced payment journal entry
          was posted.
        </p>
      </section>
    );
  }

  if (status === "error") {
    return (
      <section className="rounded-2xl border border-rose-200 bg-rose-50 p-5 text-rose-800">
        <p className="text-sm font-semibold">Payment could not be recorded.</p>

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

# 7. Update Invoice Detail Page with Payment Form

## The Target

We are updating:

```txt
app/invoices/[invoiceId]/page.tsx
```

---

## The Implementation

Open:

```txt
app/invoices/[invoiceId]/page.tsx
```

Add imports:

```tsx
import { CustomerPaymentForm } from "@/components/customer-payment-form";
import { PaymentStatusBanner } from "@/components/payment-status-banner";
```

Update the props type to include search params:

```ts
type InvoiceDetailPageProps = {
  params: Promise<{
    invoiceId: string;
  }>;
  searchParams?: Promise<{
    paymentStatus?: string;
    paymentMessage?: string;
  }>;
};
```

Update the function signature:

```tsx
export default async function InvoiceDetailPage({
  params,
  searchParams,
}: InvoiceDetailPageProps) {
```

After resolving params, add:

```ts
const resolvedSearchParams = searchParams ? await searchParams : {};
```

Then inside the `<div className="space-y-6">`, right at the top, add:

```tsx
<PaymentStatusBanner
  status={resolvedSearchParams.paymentStatus}
  message={resolvedSearchParams.paymentMessage}
/>
```

After the invoice totals/customer grid section, add:

```tsx
<CustomerPaymentForm
  invoiceId={invoice.id}
  invoiceNumber={invoice.invoiceNumber}
  status={invoice.status}
  totalCents={invoice.totalCents}
/>
```

Do not remove the existing invoice lines or journal entry sections.

---

## The Verification

Open an unpaid invoice detail page:

```txt
/invoices/[invoiceId]
```

You should see:

```txt
Record full payment
```

---

# 8. Update Payments Page

## The Target

We are updating:

```txt
app/payments/page.tsx
```

to show customer payment diagnostics.

---

## The Implementation

Open:

```txt
app/payments/page.tsx
```

Replace it with:

```tsx
// app/payments/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { formatMoney } from "@/lib/money";
import { getCurrentOrganizationCustomerPaymentDiagnostics } from "@/services/payments/customer-payment-services";

export const dynamic = "force-dynamic";

export default async function PaymentsPage() {
  const diagnostics =
    await getCurrentOrganizationCustomerPaymentDiagnostics();

  return (
    <AppLayout
      title="Payments"
      description="Payments settle invoices and bills without duplicating the original revenue or expense."
    >
      <div className="space-y-6">
        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
            Customer payments
          </p>

          <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
            {diagnostics.paymentCount} customer payment
            {diagnostics.paymentCount === 1 ? "" : "s"} recorded
          </h2>

          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
            Customer payments debit Bank and credit Accounts Receivable. This
            settles invoices without recording revenue again.
          </p>

          <Link
            href="/invoices"
            className="mt-4 inline-flex rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
          >
            Open invoices
          </Link>
        </section>

        {diagnostics.recentPayments.length > 0 ? (
          <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
            <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
              <h2 className="text-lg font-semibold text-slate-950">
                Recent customer payments
              </h2>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full border-collapse text-left text-sm">
                <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                  <tr>
                    <th className="px-6 py-3 font-semibold">Date</th>
                    <th className="px-6 py-3 font-semibold">Invoice</th>
                    <th className="px-6 py-3 font-semibold">Customer</th>
                    <th className="px-6 py-3 font-semibold">Reference</th>
                    <th className="px-6 py-3 font-semibold">Journal</th>
                    <th className="px-6 py-3 text-right font-semibold">
                      Amount
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-200">
                  {diagnostics.recentPayments.map((payment) => (
                    <tr key={payment.id}>
                      <td className="px-6 py-4 text-slate-600">
                        {payment.paymentDate}
                      </td>

                      <td className="px-6 py-4 font-semibold text-slate-950">
                        {payment.invoiceNumber}
                      </td>

                      <td className="px-6 py-4 text-slate-600">
                        {payment.customerName}
                      </td>

                      <td className="px-6 py-4 text-slate-600">
                        {payment.reference ?? "—"}
                      </td>

                      <td className="px-6 py-4">
                        {payment.journalEntryId ? (
                          <span className="rounded-full bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700">
                            Posted
                          </span>
                        ) : (
                          <span className="rounded-full bg-amber-50 px-2 py-1 text-xs font-semibold text-amber-700">
                            Missing
                          </span>
                        )}
                      </td>

                      <td className="px-6 py-4 text-right font-semibold text-slate-950">
                        {formatMoney(payment.amountCents)}
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
              No customer payments yet
            </h2>

            <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
              Open an invoice detail page and record a full payment.
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
http://localhost:3000/payments
```

It should load and show payment diagnostics.

---

# 9. Update Database Health

## The Target

We are updating:

```txt
lib/database-health.ts
```

to include customer payment count.

---

## The Implementation

Import:

```ts
customerPayments,
```

from schema.

Add to success type:

```ts
customerPaymentCount: number;
```

In the function, add:

```ts
const [customerPaymentRow] = await db
  .select({ value: count() })
  .from(customerPayments);
```

Return:

```ts
customerPaymentCount: customerPaymentRow?.value ?? 0,
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 10. Record a Customer Payment

## The Target

We are recording a full payment for an invoice.

---

## The Implementation

Open:

```txt
/invoices
```

Click an unpaid invoice.

On the detail page, use:

```txt
Payment date: today
Reference: TEST-PAYMENT-001
```

Click:

```txt
Record payment
```

---

## The Verification

You should see:

```txt
Payment recorded successfully.
```

The invoice should now show status:

```txt
paid
```

The payment form should be replaced with:

```txt
Invoice paid.
```

---

# 11. Verify Journal Entry

## The Target

We are confirming the payment journal entry.

---

## The Implementation

Open:

```txt
/settings/database/journal
```

Look for:

```txt
Payment received for invoice INV-...
```

It should show:

```txt
Debit 1000 Bank                 invoice total
Credit 1100 Accounts Receivable invoice total
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

We are verifying payment rows directly.

---

## The Implementation

Run:

```sql
select
  cp.payment_date,
  i.invoice_number,
  c.name as customer_name,
  cp.amount_cents,
  cp.reference,
  cp.journal_entry_id
from customer_payments cp
join invoices i
  on i.id = cp.invoice_id
join customers c
  on c.id = cp.customer_id
order by cp.created_at desc;
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
where je.source_type = 'customer_payment'
order by je.created_at desc, jl.line_number;
```

---

## The Verification

You should see:

```txt
1000 Bank debit
1100 Accounts Receivable credit
```

for the same amount.

---

# 13. Run Full Project Check

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

# 14. Commit Customer Payments

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Record customer payments"
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

## Error: `relation "customer_payments" does not exist`

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Invoice already paid

The tutorial supports full payment once per invoice.

Create a new invoice if you want to test another payment.

---

## Error: Required account 1000 or 1100 is missing

Open:

```txt
/accounts
```

Seed default accounts.

---

## Error: Cannot record payment for void invoice

Void invoices cannot be paid.

Use a non-void invoice.

---

## Error: Payment form does not appear

The invoice may already be paid.

Create a new invoice and open its detail page.

---

# Phase 7 Reference — Customer Payment Accounting

## Invoice Posting

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

---

## Customer Payment Posting

```txt
Debit  Bank
Credit Accounts Receivable
```

---

## Why Revenue Is Not Credited Again

Revenue was already recorded when the invoice was issued.

A payment only settles what the customer owes.

---

# Part 22 Completion Checklist

You are ready for Part 23 if:

- [ ] `customer_payments` table exists
- [ ] `CustomerPayment` types exist
- [ ] Customer payment service exists
- [ ] Customer payment validates invoice ownership
- [ ] Customer payment rejects already paid invoices
- [ ] Customer payment posts journal entry
- [ ] Payment journal debits Bank and credits AR
- [ ] Invoice status updates to `paid`
- [ ] Invoice detail page shows payment form
- [ ] `/payments` shows customer payment diagnostics
- [ ] Neon SQL confirms payment rows
- [ ] Journal diagnostics show balanced payment entry
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
