# Phase 7 — Payments

# Part 23 — Record Vendor Payments

In Part 22, we recorded customer payments.

Customer payment accounting is:

```txt
Debit  Bank
Credit Accounts Receivable
```

Now we record vendor payments.

Vendor payment accounting is the mirror image for bills:

```txt
Debit  Accounts Payable
Credit Bank
```

For a full payment of a S$109 bill:

```txt
Debit  Accounts Payable   S$109.00
Credit Bank               S$109.00
```

By the end of this part, you will have:

- Vendor payment database table
- Vendor payment posting service
- Payment form on bill detail pages
- Bill status update to `paid`
- Journal entry for vendor payment
- Updated payments page showing both customer and vendor payments
- Database health payment counts
- Neon SQL verification

We will support **full bill payments** in this part.

Partial vendor payments can be added later.

---

# 1. Understand Vendor Payments

## The Target

We are recording money paid to vendors against bills.

---

## The Concept

A bill creates money owed to a vendor.

That is Accounts Payable.

Example bill posting:

```txt
Debit  Purchases            S$100.00
Debit  GST Input Tax        S$9.00
Credit Accounts Payable     S$109.00
```

When we pay the vendor, we do not record the expense again.

Payment entry:

```txt
Debit  Accounts Payable     S$109.00
Credit Bank                 S$109.00
```

Why?

Because:

```txt
Accounts Payable decreases.
Bank decreases.
```

Think of Accounts Payable like a “we owe vendors” bucket.

The bill fills the bucket.

The payment empties the bucket and reduces the bank bucket.

---

# 2. Add Vendor Payment Table

## The Target

We are updating:

```txt
db/schema.ts
```

to add:

```txt
vendor_payments
```

---

## The Concept

A vendor payment record stores business workflow information:

```txt
Vendor
Bill
Payment date
Amount
Reference
Linked journal entry
```

The journal stores accounting truth.

---

## The Implementation

Open:

```txt
db/schema.ts
```

Add this table after `billLines`:

```ts
export const vendorPayments = pgTable(
  "vendor_payments",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),

    vendorId: uuid("vendor_id")
      .notNull()
      .references(() => vendors.id, { onDelete: "restrict" }),

    billId: uuid("bill_id")
      .notNull()
      .references(() => bills.id, { onDelete: "restrict" }),

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
    index("vendor_payments_organization_id_idx").on(table.organizationId),
    index("vendor_payments_organization_id_bill_id_idx").on(
      table.organizationId,
      table.billId,
    ),
    index("vendor_payments_organization_id_vendor_id_idx").on(
      table.organizationId,
      table.vendorId,
    ),
    check("vendor_payments_amount_positive_check", sql`${table.amountCents} > 0`),
  ],
);
```

At the bottom, add:

```ts
export type VendorPayment = typeof vendorPayments.$inferSelect;
export type NewVendorPayment = typeof vendorPayments.$inferInsert;
```

Important ordering note:

Because `vendorPayments` references `journalEntries`, `bills`, and `vendors`, make sure those tables are declared before `vendorPayments`.

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
vendor_payments
```

---

# 3. Create Vendor Payment Service

## The Target

We are creating:

```txt
services/payments/vendor-payment-services.ts
```

---

## The Concept

The service will:

1. Require active organization.
2. Verify bill belongs to the organization.
3. Verify bill is not already paid.
4. Create vendor payment row.
5. Post journal entry:
   - Debit Accounts Payable
   - Credit Bank
6. Link payment to journal entry.
7. Mark bill as `paid`.

Required accounts:

```txt
1000 Bank
2000 Accounts Payable
```

---

## The Implementation

Create:

```txt
services/payments/vendor-payment-services.ts
```

Add:

```ts
// services/payments/vendor-payment-services.ts

import { auth } from "@clerk/nextjs/server";
import { and, count, desc, eq } from "drizzle-orm";
import { db } from "@/db";
import {
  accounts,
  bills,
  journalEntries,
  journalLines,
  vendorPayments,
  vendors,
  type VendorPayment,
} from "@/db/schema";
import { validatePostJournalEntryInput } from "@/services/journal/validate-post-journal-entry";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type RecordVendorPaymentInput = {
  billId: string;
  paymentDate: string;
  reference?: string | null;
};

export type RecordVendorPaymentResult =
  | {
      ok: true;
      payment: VendorPayment;
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

export async function recordVendorPaymentForCurrentOrganization(
  input: RecordVendorPaymentInput,
): Promise<RecordVendorPaymentResult> {
  const organization = await requireCurrentDatabaseOrganization();
  const { userId } = await auth();

  const paymentDate = input.paymentDate.trim();
  const reference = normalizeOptionalText(input.reference);

  if (!input.billId.trim()) {
    return {
      ok: false,
      error: "Bill is required.",
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
      const [bill] = await tx
        .select({
          id: bills.id,
          billNumber: bills.billNumber,
          organizationId: bills.organizationId,
          vendorId: bills.vendorId,
          status: bills.status,
          totalCents: bills.totalCents,
          vendorName: vendors.name,
        })
        .from(bills)
        .innerJoin(vendors, eq(bills.vendorId, vendors.id))
        .where(
          and(
            eq(bills.id, input.billId.trim()),
            eq(bills.organizationId, organization.id),
          ),
        )
        .limit(1);

      if (!bill) {
        throw new Error("Bill does not exist for the active organization.");
      }

      if (bill.status === "paid") {
        throw new Error("Bill is already paid.");
      }

      if (bill.status === "void") {
        throw new Error("Cannot record payment for a void bill.");
      }

      const accountRows = await tx
        .select()
        .from(accounts)
        .where(eq(accounts.organizationId, organization.id));

      const accountByCode = new Map(
        accountRows.map((account) => [account.code, account]),
      );

      const bank = accountByCode.get("1000");
      const accountsPayable = accountByCode.get("2000");

      if (!bank) {
        throw new Error("Required account 1000 Bank is missing.");
      }

      if (!accountsPayable) {
        throw new Error("Required account 2000 Accounts Payable is missing.");
      }

      if (!bank.isActive) {
        throw new Error("Required account 1000 Bank is inactive.");
      }

      if (!accountsPayable.isActive) {
        throw new Error("Required account 2000 Accounts Payable is inactive.");
      }

      const now = new Date();

      const [createdPayment] = await tx
        .insert(vendorPayments)
        .values({
          organizationId: organization.id,
          vendorId: bill.vendorId,
          billId: bill.id,
          paymentDate,
          amountCents: bill.totalCents,
          reference,
          createdAt: now,
          updatedAt: now,
        })
        .returning();

      if (!createdPayment) {
        throw new Error("Vendor payment could not be created.");
      }

      const journalValidation = validatePostJournalEntryInput({
        entryDate: paymentDate,
        memo: `Payment made for bill ${bill.billNumber} to ${bill.vendorName}`,
        sourceType: "vendor_payment",
        sourceId: createdPayment.id,
        lines: [
          {
            accountId: accountsPayable.id,
            description: `Payable cleared for ${bill.billNumber}`,
            debitCents: bill.totalCents,
            creditCents: 0,
          },
          {
            accountId: bank.id,
            description: `Payment made for ${bill.billNumber}`,
            debitCents: 0,
            creditCents: bill.totalCents,
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
          memo: `Payment made for bill ${bill.billNumber} to ${bill.vendorName}`,
          sourceType: "vendor_payment",
          sourceId: createdPayment.id,
          postedByUserId: userId ?? null,
          createdAt: now,
          updatedAt: now,
        })
        .returning();

      if (!createdJournalEntry) {
        throw new Error("Vendor payment journal entry could not be created.");
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
        .update(vendorPayments)
        .set({
          journalEntryId: createdJournalEntry.id,
          updatedAt: now,
        })
        .where(eq(vendorPayments.id, createdPayment.id))
        .returning();

      if (!updatedPayment) {
        throw new Error("Vendor payment could not be linked to journal entry.");
      }

      await tx
        .update(bills)
        .set({
          status: "paid",
          updatedAt: now,
        })
        .where(eq(bills.id, bill.id));

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
          : "Unexpected error while recording vendor payment.",
    };
  }
}

export async function getCurrentOrganizationVendorPaymentDiagnostics(): Promise<{
  organizationId: string | null;
  paymentCount: number;
  recentPayments: Array<{
    id: string;
    billNumber: string;
    vendorName: string;
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
    .from(vendorPayments)
    .where(eq(vendorPayments.organizationId, organization.id));

  const recentPayments = await db
    .select({
      id: vendorPayments.id,
      billNumber: bills.billNumber,
      vendorName: vendors.name,
      paymentDate: vendorPayments.paymentDate,
      amountCents: vendorPayments.amountCents,
      reference: vendorPayments.reference,
      journalEntryId: vendorPayments.journalEntryId,
    })
    .from(vendorPayments)
    .innerJoin(bills, eq(vendorPayments.billId, bills.id))
    .innerJoin(vendors, eq(vendorPayments.vendorId, vendors.id))
    .where(eq(vendorPayments.organizationId, organization.id))
    .orderBy(desc(vendorPayments.createdAt))
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

# 4. Create Vendor Payment Server Action

## The Target

We are creating:

```txt
app/bills/[billId]/actions.ts
```

---

## The Implementation

Create:

```txt
app/bills/[billId]/actions.ts
```

Add:

```ts
// app/bills/[billId]/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { recordVendorPaymentForCurrentOrganization } from "@/services/payments/vendor-payment-services";

export async function recordVendorPaymentAction(formData: FormData) {
  const billId = String(formData.get("billId") ?? "");

  const result = await recordVendorPaymentForCurrentOrganization({
    billId,
    paymentDate: String(formData.get("paymentDate") ?? ""),
    reference: String(formData.get("reference") ?? ""),
  });

  revalidatePath("/bills");
  revalidatePath(`/bills/${billId}`);
  revalidatePath("/payments");
  revalidatePath("/settings/database");
  revalidatePath("/settings/database/journal");

  if (!result.ok) {
    redirect(
      `/bills/${billId}?paymentStatus=error&paymentMessage=${encodeURIComponent(
        result.error,
      )}`,
    );
  }

  redirect(`/bills/${billId}?paymentStatus=recorded`);
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Create Vendor Payment Form Component

## The Target

We are creating:

```txt
components/vendor-payment-form.tsx
```

---

## The Implementation

Create:

```txt
components/vendor-payment-form.tsx
```

Add:

```tsx
// components/vendor-payment-form.tsx

import { recordVendorPaymentAction } from "@/app/bills/[billId]/actions";
import { formatMoney } from "@/lib/money";

type VendorPaymentFormProps = {
  billId: string;
  billNumber: string;
  status: string;
  totalCents: number;
};

function todayString(): string {
  return new Date().toISOString().slice(0, 10);
}

export function VendorPaymentForm({
  billId,
  billNumber,
  status,
  totalCents,
}: VendorPaymentFormProps) {
  if (status === "paid") {
    return (
      <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 text-emerald-800">
        <p className="text-sm font-semibold">Bill paid.</p>

        <p className="mt-2 text-sm leading-6">
          Bill {billNumber} has been marked as paid.
        </p>
      </section>
    );
  }

  if (status === "void") {
    return (
      <section className="rounded-2xl border border-slate-200 bg-slate-50 p-6 text-slate-700">
        <p className="text-sm font-semibold">Bill void.</p>

        <p className="mt-2 text-sm leading-6">
          Payments cannot be recorded for void bills.
        </p>
      </section>
    );
  }

  return (
    <form
      action={recordVendorPaymentAction}
      className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
    >
      <input type="hidden" name="billId" value={billId} />

      <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
        Vendor payment
      </p>

      <h2 className="mt-3 text-lg font-semibold text-slate-950">
        Record full payment
      </h2>

      <p className="mt-2 text-sm leading-6 text-slate-500">
        This records payment of {formatMoney(totalCents)} and posts:
      </p>

      <div className="mt-4 rounded-xl bg-slate-50 p-4 text-sm leading-6 text-slate-700">
        <p>Debit Accounts Payable {formatMoney(totalCents)}</p>
        <p>Credit Bank {formatMoney(totalCents)}</p>
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

# 6. Update Bill Detail Page with Payment Form

## The Target

We are updating:

```txt
app/bills/[billId]/page.tsx
```

---

## The Implementation

Open:

```txt
app/bills/[billId]/page.tsx
```

Add imports:

```tsx
import { PaymentStatusBanner } from "@/components/payment-status-banner";
import { VendorPaymentForm } from "@/components/vendor-payment-form";
```

Update props type:

```ts
type BillDetailPageProps = {
  params: Promise<{
    billId: string;
  }>;
  searchParams?: Promise<{
    paymentStatus?: string;
    paymentMessage?: string;
  }>;
};
```

Update function signature:

```tsx
export default async function BillDetailPage({
  params,
  searchParams,
}: BillDetailPageProps) {
```

After resolving params, add:

```ts
const resolvedSearchParams = searchParams ? await searchParams : {};
```

Inside the top-level `<div className="space-y-6">`, add this at the top:

```tsx
<PaymentStatusBanner
  status={resolvedSearchParams.paymentStatus}
  message={resolvedSearchParams.paymentMessage}
/>
```

After the vendor/totals grid section, add:

```tsx
<VendorPaymentForm
  billId={bill.id}
  billNumber={bill.billNumber}
  status={bill.status}
  totalCents={bill.totalCents}
/>
```

Do not remove bill lines or journal entry sections.

---

## The Verification

Open an unpaid bill detail page:

```txt
/bills/[billId]
```

You should see:

```txt
Record full payment
```

---

# 7. Update Payments Page to Show Both Payment Types

## The Target

We are updating:

```txt
app/payments/page.tsx
```

to show:

- Customer payments
- Vendor payments

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
import { getCurrentOrganizationVendorPaymentDiagnostics } from "@/services/payments/vendor-payment-services";

export const dynamic = "force-dynamic";

export default async function PaymentsPage() {
  const customerDiagnostics =
    await getCurrentOrganizationCustomerPaymentDiagnostics();

  const vendorDiagnostics =
    await getCurrentOrganizationVendorPaymentDiagnostics();

  return (
    <AppLayout
      title="Payments"
      description="Payments settle invoices and bills without duplicating the original revenue or expense."
    >
      <div className="space-y-6">
        <section className="grid gap-4 md:grid-cols-2">
          <Link
            href="/invoices"
            className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <p className="text-sm font-semibold text-emerald-700">
              Customer payments
            </p>

            <p className="mt-2 text-3xl font-bold text-emerald-950">
              {customerDiagnostics.paymentCount}
            </p>

            <p className="mt-2 text-sm leading-6 text-emerald-800">
              Debit Bank and credit Accounts Receivable.
            </p>
          </Link>

          <Link
            href="/bills"
            className="rounded-2xl border border-sky-200 bg-sky-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <p className="text-sm font-semibold text-sky-700">
              Vendor payments
            </p>

            <p className="mt-2 text-3xl font-bold text-sky-950">
              {vendorDiagnostics.paymentCount}
            </p>

            <p className="mt-2 text-sm leading-6 text-sky-800">
              Debit Accounts Payable and credit Bank.
            </p>
          </Link>
        </section>

        <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
            <h2 className="text-lg font-semibold text-slate-950">
              Recent customer payments
            </h2>
          </div>

          {customerDiagnostics.recentPayments.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full border-collapse text-left text-sm">
                <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                  <tr>
                    <th className="px-6 py-3 font-semibold">Date</th>
                    <th className="px-6 py-3 font-semibold">Invoice</th>
                    <th className="px-6 py-3 font-semibold">Customer</th>
                    <th className="px-6 py-3 font-semibold">Reference</th>
                    <th className="px-6 py-3 text-right font-semibold">
                      Amount
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-200">
                  {customerDiagnostics.recentPayments.map((payment) => (
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
                      <td className="px-6 py-4 text-right font-semibold text-slate-950">
                        {formatMoney(payment.amountCents)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="p-8 text-center text-sm text-slate-500">
              No customer payments yet.
            </div>
          )}
        </section>

        <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
            <h2 className="text-lg font-semibold text-slate-950">
              Recent vendor payments
            </h2>
          </div>

          {vendorDiagnostics.recentPayments.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full border-collapse text-left text-sm">
                <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                  <tr>
                    <th className="px-6 py-3 font-semibold">Date</th>
                    <th className="px-6 py-3 font-semibold">Bill</th>
                    <th className="px-6 py-3 font-semibold">Vendor</th>
                    <th className="px-6 py-3 font-semibold">Reference</th>
                    <th className="px-6 py-3 text-right font-semibold">
                      Amount
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-200">
                  {vendorDiagnostics.recentPayments.map((payment) => (
                    <tr key={payment.id}>
                      <td className="px-6 py-4 text-slate-600">
                        {payment.paymentDate}
                      </td>
                      <td className="px-6 py-4 font-semibold text-slate-950">
                        {payment.billNumber}
                      </td>
                      <td className="px-6 py-4 text-slate-600">
                        {payment.vendorName}
                      </td>
                      <td className="px-6 py-4 text-slate-600">
                        {payment.reference ?? "—"}
                      </td>
                      <td className="px-6 py-4 text-right font-semibold text-slate-950">
                        {formatMoney(payment.amountCents)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="p-8 text-center text-sm text-slate-500">
              No vendor payments yet.
            </div>
          )}
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
http://localhost:3000/payments
```

You should see both customer and vendor payment sections.

---

# 8. Update Database Health

## The Target

We are updating:

```txt
lib/database-health.ts
```

to include vendor payment count.

---

## The Implementation

Import:

```ts
vendorPayments,
```

from schema.

Add to success type:

```ts
vendorPaymentCount: number;
```

In the function, add:

```ts
const [vendorPaymentRow] = await db
  .select({ value: count() })
  .from(vendorPayments);
```

Return:

```ts
vendorPaymentCount: vendorPaymentRow?.value ?? 0,
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 9. Record a Vendor Payment

## The Target

We are recording a full payment for a bill.

---

## The Implementation

Open:

```txt
/bills
```

Click an unpaid bill.

On the detail page, use:

```txt
Payment date: today
Reference: TEST-VENDOR-PAYMENT-001
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

The bill should now show status:

```txt
paid
```

The payment form should be replaced with:

```txt
Bill paid.
```

---

# 10. Verify Journal Entry

## The Target

We are confirming the vendor payment journal entry.

---

## The Implementation

Open:

```txt
/settings/database/journal
```

Look for:

```txt
Payment made for bill BILL-...
```

It should show:

```txt
Debit 2000 Accounts Payable
Credit 1000 Bank
```

---

## The Verification

The entry should show:

```txt
Balanced
```

---

# 11. Verify in Neon SQL

## The Target

We are verifying vendor payment rows directly.

---

## The Implementation

Run:

```sql
select
  vp.payment_date,
  b.bill_number,
  v.name as vendor_name,
  vp.amount_cents,
  vp.reference,
  vp.journal_entry_id
from vendor_payments vp
join bills b
  on b.id = vp.bill_id
join vendors v
  on v.id = vp.vendor_id
order by vp.created_at desc;
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
where je.source_type = 'vendor_payment'
order by je.created_at desc, jl.line_number;
```

---

## The Verification

You should see:

```txt
2000 Accounts Payable debit
1000 Bank credit
```

for the same amount.

---

# 12. Run Full Project Check

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

# 13. Commit Vendor Payments

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Record vendor payments"
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

## Error: `relation "vendor_payments" does not exist`

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Bill already paid

The tutorial supports full payment once per bill.

Create a new bill if you want to test another payment.

---

## Error: Required account 1000 or 2000 is missing

Open:

```txt
/accounts
```

Seed default accounts.

---

## Error: Cannot record payment for void bill

Void bills cannot be paid.

Use a non-void bill.

---

## Error: Payment form does not appear

The bill may already be paid.

Create a new bill and open its detail page.

---

# Phase 7 Reference — Vendor Payment Accounting

## Bill Posting

```txt
Debit  Purchases
Debit  GST Input Tax
Credit Accounts Payable
```

---

## Vendor Payment Posting

```txt
Debit  Accounts Payable
Credit Bank
```

---

## Why Expense Is Not Debited Again

The expense was already recorded when the bill was received.

The payment only settles what the company owes.

---

# Part 23 Completion Checklist

You are ready for Part 24 if:

- [ ] `vendor_payments` table exists
- [ ] `VendorPayment` types exist
- [ ] Vendor payment service exists
- [ ] Vendor payment validates bill ownership
- [ ] Vendor payment rejects already paid bills
- [ ] Vendor payment posts journal entry
- [ ] Payment journal debits AP and credits Bank
- [ ] Bill status updates to `paid`
- [ ] Bill detail page shows payment form
- [ ] `/payments` shows customer and vendor payment diagnostics
- [ ] Neon SQL confirms vendor payment rows
- [ ] Journal diagnostics show balanced vendor payment entry
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
