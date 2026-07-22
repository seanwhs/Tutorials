# Part 20 — Build Bills and Vendor Management

In Part 19, we completed invoice list and detail pages.

Now we build the purchasing side of the business.

Invoices answer:

```txt
Who owes us money?
```

Bills answer:

```txt
Who do we owe money to?
```

By the end of this part, you will have:

- Bill database tables
- Bill line database tables
- Bill status enum
- GST input tax handling
- Vendor-based bill creation
- A bill creation form
- Bill creation server action
- Bill posting to the journal
- Updated database health counts
- A working `/bills` page
- Neon SQL verification

The accounting entry for a GST-inclusive vendor bill is:

```txt
Debit  Purchases / Expense       Subtotal before GST
Debit  GST Input Tax             GST paid on purchases
Credit Accounts Payable          Total bill amount
```

Example:

```txt
Vendor bill for S$109.00 including 9% GST

Debit  Purchases                 S$100.00
Debit  GST Input Tax             S$9.00
Credit Accounts Payable          S$109.00
```

---

# 1. Understand Bills

## The Target

We are adding purchasing documents called bills.

---

## The Concept

A bill is a document from a vendor saying:

> You owe us money.

Examples:

```txt
Cloud hosting bill
Accounting service bill
Office rent bill
Software subscription bill
Supplier purchase bill
```

In accounting, a bill usually creates:

```txt
Accounts Payable
```

Accounts Payable is a liability because it represents money the business owes.

---

## The Implementation

We will create two tables:

```txt
bills
bill_lines
```

A bill has:

```txt
Vendor
Bill number
Issue date
Due date
Status
Subtotal
GST
Total
Linked journal entry
```

A bill line has:

```txt
Description
Quantity
Unit amount
GST rate
GST amount
Total
```

---

## The Verification

At the end, creating a bill for S$100.00 + 9% GST should create:

```txt
Bill subtotal: S$100.00
GST:           S$9.00
Total:         S$109.00
```

And the journal should show:

```txt
Debit  Purchases          S$100.00
Debit  GST Input Tax      S$9.00
Credit Accounts Payable   S$109.00
```

---

# 2. Update the Database Schema for Bills

## The Target

We are updating:

```txt
db/schema.ts
```

to add:

```txt
bill_status enum
bills
bill_lines
```

---

## The Concept

Bills mirror invoices, but from the purchase side.

Invoices use:

```txt
Customer
Accounts Receivable
Sales Revenue
GST Output Tax
```

Bills use:

```txt
Vendor
Accounts Payable
Purchases
GST Input Tax
```

GST Input Tax is GST paid on purchases that may be claimable, subject to Singapore GST rules.

---

## The Implementation

Open:

```txt
db/schema.ts
```

Add this enum near your other enums:

```ts
export const billStatusEnum = pgEnum("bill_status", [
  "draft",
  "received",
  "paid",
  "void",
]);
```

Now add the following table definitions after your `invoiceLines` table definition.

```ts
export const bills = pgTable(
  "bills",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),

    vendorId: uuid("vendor_id")
      .notNull()
      .references(() => vendors.id, { onDelete: "restrict" }),

    billNumber: text("bill_number").notNull(),

    issueDate: date("issue_date").notNull(),

    dueDate: date("due_date").notNull(),

    status: billStatusEnum("status").default("received").notNull(),

    subtotalCents: bigint("subtotal_cents", { mode: "number" })
      .default(0)
      .notNull(),

    gstCents: bigint("gst_cents", { mode: "number" }).default(0).notNull(),

    totalCents: bigint("total_cents", { mode: "number" }).default(0).notNull(),

    notes: text("notes"),

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
    uniqueIndex("bills_organization_id_bill_number_idx").on(
      table.organizationId,
      table.billNumber,
    ),
    index("bills_organization_id_idx").on(table.organizationId),
    index("bills_organization_id_vendor_id_idx").on(
      table.organizationId,
      table.vendorId,
    ),
    index("bills_organization_id_status_idx").on(
      table.organizationId,
      table.status,
    ),
    check("bills_subtotal_non_negative_check", sql`${table.subtotalCents} >= 0`),
    check("bills_gst_non_negative_check", sql`${table.gstCents} >= 0`),
    check("bills_total_non_negative_check", sql`${table.totalCents} >= 0`),
    check(
      "bills_total_matches_components_check",
      sql`${table.totalCents} = ${table.subtotalCents} + ${table.gstCents}`,
    ),
  ],
);

export const billLines = pgTable(
  "bill_lines",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    billId: uuid("bill_id")
      .notNull()
      .references(() => bills.id, { onDelete: "cascade" }),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),

    lineNumber: integer("line_number").notNull(),

    description: text("description").notNull(),

    quantity: integer("quantity").notNull(),

    unitAmountCents: bigint("unit_amount_cents", { mode: "number" })
      .notNull(),

    subtotalCents: bigint("subtotal_cents", { mode: "number" }).notNull(),

    gstRateBasisPoints: integer("gst_rate_basis_points").notNull(),

    gstCents: bigint("gst_cents", { mode: "number" }).notNull(),

    totalCents: bigint("total_cents", { mode: "number" }).notNull(),

    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    uniqueIndex("bill_lines_bill_id_line_number_idx").on(
      table.billId,
      table.lineNumber,
    ),
    index("bill_lines_organization_id_idx").on(table.organizationId),
    index("bill_lines_bill_id_idx").on(table.billId),
    check("bill_lines_quantity_positive_check", sql`${table.quantity} > 0`),
    check(
      "bill_lines_unit_amount_non_negative_check",
      sql`${table.unitAmountCents} >= 0`,
    ),
    check(
      "bill_lines_subtotal_non_negative_check",
      sql`${table.subtotalCents} >= 0`,
    ),
    check("bill_lines_gst_non_negative_check", sql`${table.gstCents} >= 0`),
    check("bill_lines_total_non_negative_check", sql`${table.totalCents} >= 0`),
    check(
      "bill_lines_total_matches_components_check",
      sql`${table.totalCents} = ${table.subtotalCents} + ${table.gstCents}`,
    ),
  ],
);
```

At the bottom of `db/schema.ts`, add these exported types:

```ts
export type Bill = typeof bills.$inferSelect;
export type NewBill = typeof bills.$inferInsert;

export type BillLine = typeof billLines.$inferSelect;
export type NewBillLine = typeof billLines.$inferInsert;
```

Important note:

If TypeScript complains that `journalEntries` is used before declaration, move your `journalEntries` and `journalLines` definitions above the `invoices` and `bills` definitions. The important runtime rule is:

```txt
A referenced table must already be declared before another table references it.
```

---

## The Verification

Generate and apply the migration:

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
bill_lines
bills
```

Verify bill constraints:

```sql
select
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
from pg_constraint
where conrelid in ('bills'::regclass, 'bill_lines'::regclass)
order by conname;
```

You should see constraints like:

```txt
bills_total_matches_components_check
bill_lines_total_matches_components_check
bill_lines_quantity_positive_check
```

---

# 3. Create Bill Services

## The Target

We are creating:

```txt
services/bills/bill-services.ts
```

This service will create vendor bills and post them to the journal.

---

## The Concept

A bill creation service is similar to invoice creation, but the accounting direction is different.

Invoice:

```txt
Debit  Accounts Receivable
Credit Revenue
Credit GST Output Tax
```

Bill:

```txt
Debit  Purchases
Debit  GST Input Tax
Credit Accounts Payable
```

The bill service will require these seeded accounts:

```txt
2000 Accounts Payable
1400 GST Input Tax
5100 Purchases
```

---

## The Implementation

Create the folder:

```bash
mkdir -p services/bills
```

Create:

```txt
services/bills/bill-services.ts
```

Add:

```ts
// services/bills/bill-services.ts

import { auth } from "@clerk/nextjs/server";
import { and, count, desc, eq } from "drizzle-orm";
import { db } from "@/db";
import {
  accounts,
  billLines,
  bills,
  journalEntries,
  journalLines,
  vendors,
  type Bill,
} from "@/db/schema";
import {
  calculateInvoiceLineTotals,
  DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS,
} from "@/lib/accounting/gst";
import { dollarsToCents } from "@/lib/money";
import { validatePostJournalEntryInput } from "@/services/journal/validate-post-journal-entry";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type CreateBillInput = {
  vendorId: string;
  issueDate: string;
  dueDate: string;
  description: string;
  quantity: number;
  unitAmount: string;
  gstRateBasisPoints: number;
  notes?: string | null;
};

export type CreateBillResult =
  | {
      ok: true;
      bill: Bill;
    }
  | {
      ok: false;
      error: string;
    };

const requiredBillAccountCodes = {
  accountsPayable: "2000",
  gstInputTax: "1400",
  purchases: "5100",
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

function validateCreateBillInput(input: CreateBillInput): string[] {
  const issues: string[] = [];

  if (!input.vendorId.trim()) {
    issues.push("Vendor is required.");
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
    issues.push("Bill line description is required.");
  }

  if (input.description.trim().length > 500) {
    issues.push("Bill line description must be 500 characters or fewer.");
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

async function generateNextBillNumberForOrganization(
  organizationId: string,
): Promise<string> {
  const currentYear = new Date().getFullYear();

  const [row] = await db
    .select({ value: count() })
    .from(bills)
    .where(eq(bills.organizationId, organizationId));

  const nextNumber = (row?.value ?? 0) + 1;

  return `BILL-${currentYear}-${String(nextNumber).padStart(4, "0")}`;
}

export async function createBillForCurrentOrganization(
  input: CreateBillInput,
): Promise<CreateBillResult> {
  const organization = await requireCurrentDatabaseOrganization();
  const { userId } = await auth();

  const validationIssues = validateCreateBillInput(input);

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
      const [vendor] = await tx
        .select()
        .from(vendors)
        .where(
          and(
            eq(vendors.id, input.vendorId.trim()),
            eq(vendors.organizationId, organization.id),
          ),
        )
        .limit(1);

      if (!vendor) {
        throw new Error("Vendor does not exist for the active organization.");
      }

      if (!vendor.isActive) {
        throw new Error("Vendor is inactive.");
      }

      const accountRows = await tx
        .select()
        .from(accounts)
        .where(eq(accounts.organizationId, organization.id));

      const accountByCode = new Map(
        accountRows.map((account) => [account.code, account]),
      );

      for (const code of Object.values(requiredBillAccountCodes)) {
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

      const accountsPayable =
        accountByCode.get(requiredBillAccountCodes.accountsPayable)!;
      const gstInputTax = accountByCode.get(requiredBillAccountCodes.gstInputTax)!;
      const purchases = accountByCode.get(requiredBillAccountCodes.purchases)!;

      const billNumber = await generateNextBillNumberForOrganization(
        organization.id,
      );

      const now = new Date();

      const [createdBill] = await tx
        .insert(bills)
        .values({
          organizationId: organization.id,
          vendorId: vendor.id,
          billNumber,
          issueDate,
          dueDate,
          status: "received",
          subtotalCents: lineTotals.subtotalCents,
          gstCents: lineTotals.gstCents,
          totalCents: lineTotals.totalCents,
          notes,
          createdAt: now,
          updatedAt: now,
        })
        .returning();

      if (!createdBill) {
        throw new Error("Bill could not be created.");
      }

      await tx.insert(billLines).values({
        billId: createdBill.id,
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
          accountId: purchases.id,
          description: `Bill ${billNumber}: purchase expense`,
          debitCents: lineTotals.subtotalCents,
          creditCents: 0,
        },
      ];

      if (lineTotals.gstCents > 0) {
        journalLineInputs.push({
          accountId: gstInputTax.id,
          description: `Bill ${billNumber}: GST input tax`,
          debitCents: lineTotals.gstCents,
          creditCents: 0,
        });
      }

      journalLineInputs.push({
        accountId: accountsPayable.id,
        description: `Bill ${billNumber}: accounts payable`,
        debitCents: 0,
        creditCents: lineTotals.totalCents,
      });

      const journalValidation = validatePostJournalEntryInput({
        entryDate: issueDate,
        memo: `Bill ${billNumber} received from ${vendor.name}`,
        sourceType: "bill",
        sourceId: createdBill.id,
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
          memo: `Bill ${billNumber} received from ${vendor.name}`,
          sourceType: "bill",
          sourceId: createdBill.id,
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

      const [updatedBill] = await tx
        .update(bills)
        .set({
          journalEntryId: createdJournalEntry.id,
          updatedAt: now,
        })
        .where(eq(bills.id, createdBill.id))
        .returning();

      if (!updatedBill) {
        throw new Error("Bill could not be linked to journal entry.");
      }

      return updatedBill;
    });

    return {
      ok: true,
      bill: result,
    };
  } catch (error) {
    return {
      ok: false,
      error:
        error instanceof Error
          ? error.message
          : "Unexpected error while creating bill.",
    };
  }
}

export async function getCurrentOrganizationBillDiagnostics(): Promise<{
  organizationId: string | null;
  billCount: number;
  billLineCount: number;
  recentBills: Array<{
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
  }>;
}> {
  const organization = await requireCurrentDatabaseOrganization().catch(
    () => null,
  );

  if (!organization) {
    return {
      organizationId: null,
      billCount: 0,
      billLineCount: 0,
      recentBills: [],
    };
  }

  const [billCountRow] = await db
    .select({ value: count() })
    .from(bills)
    .where(eq(bills.organizationId, organization.id));

  const [billLineCountRow] = await db
    .select({ value: count() })
    .from(billLines)
    .where(eq(billLines.organizationId, organization.id));

  const recentBills = await db
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
    })
    .from(bills)
    .innerJoin(vendors, eq(bills.vendorId, vendors.id))
    .where(eq(bills.organizationId, organization.id))
    .orderBy(desc(bills.createdAt))
    .limit(10);

  return {
    organizationId: organization.id,
    billCount: billCountRow?.value ?? 0,
    billLineCount: billLineCountRow?.value ?? 0,
    recentBills,
  };
}

export { DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS };
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 4. Create Bill Server Actions

## The Target

We are creating:

```txt
app/bills/actions.ts
```

---

## The Implementation

Create:

```txt
app/bills/actions.ts
```

Add:

```ts
// app/bills/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createBillForCurrentOrganization } from "@/services/bills/bill-services";

function revalidateBillViews() {
  revalidatePath("/bills");
  revalidatePath("/settings/database");
  revalidatePath("/settings/database/journal");
}

export async function createBillAction(formData: FormData) {
  const result = await createBillForCurrentOrganization({
    vendorId: String(formData.get("vendorId") ?? ""),
    issueDate: String(formData.get("issueDate") ?? ""),
    dueDate: String(formData.get("dueDate") ?? ""),
    description: String(formData.get("description") ?? ""),
    quantity: Number(formData.get("quantity") ?? 1),
    unitAmount: String(formData.get("unitAmount") ?? ""),
    gstRateBasisPoints: Number(formData.get("gstRateBasisPoints") ?? 900),
    notes: String(formData.get("notes") ?? ""),
  });

  revalidateBillViews();

  if (!result.ok) {
    redirect(`/bills?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect(`/bills?status=created&bill=${result.bill.billNumber}`);
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Create Bill Status Banner

## The Target

We are creating:

```txt
components/bill-status-banner.tsx
```

---

## The Implementation

Create:

```txt
components/bill-status-banner.tsx
```

Add:

```tsx
// components/bill-status-banner.tsx

type BillStatusBannerProps = {
  status?: string;
  message?: string;
  billNumber?: string;
};

export function BillStatusBanner({
  status,
  message,
  billNumber,
}: BillStatusBannerProps) {
  if (!status) {
    return null;
  }

  if (status === "created") {
    return (
      <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
        <p className="text-sm font-semibold">
          Bill {billNumber ?? ""} created and posted successfully.
        </p>

        <p className="mt-2 text-sm leading-6">
          The bill was saved, GST input tax was calculated, and a balanced
          journal entry was posted.
        </p>
      </section>
    );
  }

  if (status === "error") {
    return (
      <section className="rounded-2xl border border-rose-200 bg-rose-50 p-5 text-rose-800">
        <p className="text-sm font-semibold">Bill could not be created.</p>
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

# 6. Create Bill Form Component

## The Target

We are creating:

```txt
components/bill-create-form.tsx
```

---

## The Implementation

Create:

```txt
components/bill-create-form.tsx
```

Add:

```tsx
// components/bill-create-form.tsx

import type { Vendor } from "@/db/schema";
import { createBillAction } from "@/app/bills/actions";
import { DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS } from "@/lib/accounting/gst";

type BillCreateFormProps = {
  vendors: Vendor[];
};

function todayString(): string {
  return new Date().toISOString().slice(0, 10);
}

function defaultDueDateString(): string {
  const date = new Date();
  date.setDate(date.getDate() + 30);
  return date.toISOString().slice(0, 10);
}

export function BillCreateForm({ vendors }: BillCreateFormProps) {
  if (vendors.length === 0) {
    return (
      <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-800">
        <p className="text-sm font-semibold">Create a vendor first.</p>
        <p className="mt-2 text-sm leading-6">
          Bills must belong to a vendor. Add a vendor before recording supplier
          bills.
        </p>
      </section>
    );
  }

  return (
    <form
      action={createBillAction}
      className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
    >
      <div>
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
          New bill
        </p>

        <h2 className="mt-3 text-lg font-semibold text-slate-950">
          Record GST-aware vendor bill
        </h2>

        <p className="mt-2 text-sm leading-6 text-slate-500">
          This creates a bill, calculates GST input tax, and posts the
          accounting entry to the journal.
        </p>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-3">
        <label className="block">
          <span className="text-sm font-semibold text-slate-700">Vendor</span>
          <select
            name="vendorId"
            required
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          >
            {vendors.map((vendor) => (
              <option key={vendor.id} value={vendor.id}>
                {vendor.name}
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
          <span className="text-sm font-semibold text-slate-700">Due date</span>
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
        <h3 className="text-sm font-semibold text-slate-950">Bill line</h3>

        <div className="mt-4 grid gap-4 md:grid-cols-[1.4fr_0.4fr_0.6fr_0.6fr]">
          <label className="block">
            <span className="text-sm font-semibold text-slate-700">
              Description
            </span>
            <input
              name="description"
              required
              maxLength={500}
              defaultValue="Cloud hosting services"
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
          placeholder="Optional bill notes."
          className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
        />
      </label>

      <div className="mt-5 flex justify-end">
        <button
          type="submit"
          className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
        >
          Create and post bill
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

# 7. Update Bills Page

## The Target

We are replacing:

```txt
app/bills/page.tsx
```

---

## The Implementation

Open:

```txt
app/bills/page.tsx
```

Replace it with:

```tsx
// app/bills/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { BillCreateForm } from "@/components/bill-create-form";
import { BillStatusBanner } from "@/components/bill-status-banner";
import { formatMoney } from "@/lib/money";
import { getCurrentOrganizationBillDiagnostics } from "@/services/bills/bill-services";
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

            {diagnostics.recentBills.length > 0 ? (
              <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
                <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
                  <h2 className="text-lg font-semibold text-slate-950">
                    Recent bills
                  </h2>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full border-collapse text-left text-sm">
                    <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                      <tr>
                        <th className="px-6 py-3 font-semibold">Bill</th>
                        <th className="px-6 py-3 font-semibold">Vendor</th>
                        <th className="px-6 py-3 font-semibold">Status</th>
                        <th className="px-6 py-3 font-semibold">Journal</th>
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
                      {diagnostics.recentBills.map((bill) => (
                        <tr key={bill.id}>
                          <td className="px-6 py-4 font-semibold text-slate-950">
                            {bill.billNumber}
                          </td>

                          <td className="px-6 py-4 text-slate-600">
                            {bill.vendorName}
                          </td>

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
                                Missing
                              </span>
                            )}
                          </td>

                          <td className="px-6 py-4 text-right text-slate-600">
                            {formatMoney(bill.subtotalCents)}
                          </td>

                          <td className="px-6 py-4 text-right text-slate-600">
                            {formatMoney(bill.gstCents)}
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
            ) : (
              <section className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
                <h2 className="text-lg font-semibold text-slate-950">
                  No bills yet
                </h2>

                <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
                  Create your first vendor bill above. It will calculate GST
                  input tax and post a balanced journal entry automatically.
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
http://localhost:3000/bills
```

You should see the bill creation form if you have at least one vendor.

---

# 8. Update Database Health

## The Target

We are updating:

```txt
lib/database-health.ts
```

to include bill counts.

---

## The Implementation

Open:

```txt
lib/database-health.ts
```

Add imports:

```ts
billLines,
bills,
```

from `@/db/schema`.

Update the success type to include:

```ts
billCount: number;
billLineCount: number;
```

Inside `getDatabaseHealth()`, add:

```ts
const [billRow] = await db.select({ value: count() }).from(bills);

const [billLineRow] = await db.select({ value: count() }).from(billLines);
```

And return:

```ts
billCount: billRow?.value ?? 0,
billLineCount: billLineRow?.value ?? 0,
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 9. Create a Vendor if Needed

## The Target

We need a vendor before creating bills.

---

## The Implementation

Open:

```txt
http://localhost:3000/vendors
```

Create:

```txt
Name: Cloud Hosting SG
Email: billing@cloudhosting.example.com
Phone: +65 6234 5678
Billing address: Singapore
Notes: Demo vendor for supplier bills.
```

---

## The Verification

The vendor should appear in the vendors table.

---

# 10. Seed Accounts if Needed

## The Target

Bill posting requires these accounts:

```txt
2000 Accounts Payable
1400 GST Input Tax
5100 Purchases
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
1400 GST Input Tax
2000 Accounts Payable
5100 Purchases
```

---

# 11. Create Your First GST Bill

## The Target

We are creating a real vendor bill and posting it to the journal.

---

## The Implementation

Open:

```txt
http://localhost:3000/bills
```

Use:

```txt
Vendor: Cloud Hosting SG
Description: Cloud hosting services
Quantity: 1
Unit amount: 100.00
GST basis points: 900
```

Click:

```txt
Create and post bill
```

---

## The Verification

You should see:

```txt
Bill BILL-... created and posted successfully.
```

The recent bills table should show:

```txt
Subtotal: S$100.00
GST:      S$9.00
Total:    S$109.00
Journal:  Posted
```

---

# 12. Verify Journal Posting

## The Target

We are confirming the bill created a balanced journal entry.

---

## The Implementation

Open:

```txt
http://localhost:3000/settings/database/journal
```

Look for an entry like:

```txt
Bill BILL-... received from Cloud Hosting SG
```

It should have:

```txt
Debit  5100 Purchases          S$100.00
Debit  1400 GST Input Tax      S$9.00
Credit 2000 Accounts Payable   S$109.00
```

---

## The Verification

The entry should show:

```txt
Balanced
```

---

# 13. Verify in Neon SQL

## The Target

We are checking bill and journal rows directly.

---

## The Implementation

Run:

```sql
select
  b.bill_number,
  v.name as vendor_name,
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
where je.source_type = 'bill'
order by je.created_at desc, jl.line_number;
```

Run:

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
where je.source_type = 'bill'
group by je.id, je.memo
order by je.memo;
```

---

## The Verification

Every bill journal entry should have:

```txt
difference_cents = 0
```

---

# 14. Run Full Project Check

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

# 15. Commit Bill Creation

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Build GST-aware bills with journal posting"
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

## Error: `relation "bills" does not exist`

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Vendor does not exist for the active organization

Make sure you created the vendor while the same organization is active.

Open:

```txt
/vendors
```

Create the vendor again if needed.

---

## Error: Required account 2000, 1400, or 5100 is missing

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

## Error: Bill total constraint fails

Check that:

```txt
total_cents = subtotal_cents + gst_cents
```

The helper should calculate this automatically.

---

## Error: Journal entry is unbalanced

The bill posting must create:

```txt
Debit Purchases subtotal
Debit GST Input Tax GST
Credit Accounts Payable total
```

The debit total must equal the credit total.

---

# Phase 6 Reference — Bill Posting

## Bill Document

The bill stores vendor-facing purchase details:

```txt
Vendor
Bill number
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
Debit Purchases
Debit GST Input Tax
Credit Accounts Payable
```

---

## GST Input Tax

GST paid to vendors.

It is recorded as an asset account in our starter chart because it may be claimable from IRAS, subject to GST rules.

---

## Accounts Payable

Money the business owes vendors.

It is a liability.

---

# Part 20 Completion Checklist

You are ready for Part 21 if:

- [ ] `billStatusEnum` exists
- [ ] `bills` table exists
- [ ] `bill_lines` table exists
- [ ] Bill totals have database checks
- [ ] Bill lines have quantity and total checks
- [ ] `services/bills/bill-services.ts` exists
- [ ] Bill creation validates vendor ownership
- [ ] Bill creation calculates GST input tax
- [ ] Bill creation inserts bill and bill line
- [ ] Bill creation posts journal entry
- [ ] Bill stores `journalEntryId`
- [ ] `/bills` has a create bill form
- [ ] Creating S$100 bill produces S$9 GST and S$109 total
- [ ] Journal entry debits purchases/GST input and credits AP
- [ ] Journal diagnostics show bill entry as balanced
- [ ] Neon SQL confirms bill and journal rows
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
