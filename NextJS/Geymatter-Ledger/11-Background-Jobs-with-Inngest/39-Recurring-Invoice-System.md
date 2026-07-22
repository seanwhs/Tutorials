# Part 39 — Recurring Invoices System

In Part 38, we created a scheduled job for overdue invoice reminders.

Now we will build a simple recurring invoices system.

By the end of this part, you will have:

- Recurring invoice profile table
- Recurring frequency enum
- Recurring invoice creation form
- Scheduled Inngest function
- Service that generates invoices from recurring profiles
- Links between recurring profiles and generated invoices
- Diagnostics page
- Neon SQL verification

This is a practical automation feature.

Many businesses invoice customers monthly for services such as:

```txt
Retainers
Subscriptions
Hosting
Maintenance
Support
```

---

# 1. Understand Recurring Invoices

## The Target

We are automating invoice creation on a schedule.

---

## The Concept

A recurring invoice profile is a template.

It says:

```txt
Every month, invoice this customer for S$100 + GST.
```

The background job reads active profiles and creates invoices when they are due.

A profile is not an invoice.

It is the instruction for generating future invoices.

---

# 2. Add Recurring Invoice Schema

## The Target

We are updating:

```txt
db/schema.ts
```

---

## The Concept

We need:

```txt
recurring_frequency enum
recurring_invoices table
```

A recurring invoice stores:

```txt
Customer
Description
Quantity
Unit amount
GST rate
Frequency
Next run date
Active flag
```

---

## The Implementation

Add enum:

```ts
export const recurringFrequencyEnum = pgEnum("recurring_frequency", [
  "monthly",
  "quarterly",
  "yearly",
]);
```

Add table:

```ts
export const recurringInvoices = pgTable(
  "recurring_invoices",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),

    customerId: uuid("customer_id")
      .notNull()
      .references(() => customers.id, { onDelete: "restrict" }),

    description: text("description").notNull(),

    quantity: integer("quantity").notNull(),

    unitAmountCents: bigint("unit_amount_cents", { mode: "number" }).notNull(),

    gstRateBasisPoints: integer("gst_rate_basis_points").notNull(),

    frequency: recurringFrequencyEnum("frequency").notNull(),

    nextRunDate: date("next_run_date").notNull(),

    isActive: boolean("is_active").default(true).notNull(),

    lastGeneratedInvoiceId: uuid("last_generated_invoice_id").references(
      () => invoices.id,
      { onDelete: "set null" },
    ),

    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),

    updatedAt: timestamp("updated_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    index("recurring_invoices_organization_id_idx").on(table.organizationId),
    index("recurring_invoices_organization_id_next_run_date_idx").on(
      table.organizationId,
      table.nextRunDate,
    ),
    check("recurring_invoices_quantity_positive_check", sql`${table.quantity} > 0`),
    check(
      "recurring_invoices_unit_amount_non_negative_check",
      sql`${table.unitAmountCents} >= 0`,
    ),
  ],
);
```

Add types:

```ts
export type RecurringInvoice = typeof recurringInvoices.$inferSelect;
export type NewRecurringInvoice = typeof recurringInvoices.$inferInsert;
```

---

## The Verification

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

Verify:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

You should see:

```txt
recurring_invoices
```

---

# 3. Create Recurring Invoice Service

## The Target

We are creating:

```txt
services/invoices/recurring-invoice-services.ts
```

---

## The Concept

This service will:

- Create recurring profiles
- List recurring profiles
- Generate due invoices

For invoice generation, we will reuse the same accounting pattern as Part 18.

To keep this tutorial focused, generation will create invoices directly with the same journal posting logic structure.

---

## The Implementation

Create:

```txt
services/invoices/recurring-invoice-services.ts
```

Add:

```ts
// services/invoices/recurring-invoice-services.ts

import { and, asc, eq, lte } from "drizzle-orm";
import { db } from "@/db";
import { recurringInvoices, type RecurringInvoice } from "@/db/schema";
import { dollarsToCents } from "@/lib/money";
import { createInvoiceForCurrentOrganization } from "@/services/invoices/invoice-services";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type RecurringFrequency = "monthly" | "quarterly" | "yearly";

export type CreateRecurringInvoiceInput = {
  customerId: string;
  description: string;
  quantity: number;
  unitAmount: string;
  gstRateBasisPoints: number;
  frequency: RecurringFrequency;
  nextRunDate: string;
};

export type CreateRecurringInvoiceResult =
  | {
      ok: true;
      recurringInvoice: RecurringInvoice;
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
  return !Number.isNaN(parsed.getTime()) && parsed.toISOString().slice(0, 10) === value;
}

export function calculateNextRunDate(params: {
  currentRunDate: string;
  frequency: RecurringFrequency;
}): string {
  const date = new Date(`${params.currentRunDate}T00:00:00.000Z`);

  if (params.frequency === "monthly") {
    date.setUTCMonth(date.getUTCMonth() + 1);
  } else if (params.frequency === "quarterly") {
    date.setUTCMonth(date.getUTCMonth() + 3);
  } else {
    date.setUTCFullYear(date.getUTCFullYear() + 1);
  }

  return date.toISOString().slice(0, 10);
}

export async function createRecurringInvoiceForCurrentOrganization(
  input: CreateRecurringInvoiceInput,
): Promise<CreateRecurringInvoiceResult> {
  const organization = await requireCurrentDatabaseOrganization();

  if (!input.customerId.trim()) {
    return { ok: false, error: "Customer is required." };
  }

  if (!input.description.trim()) {
    return { ok: false, error: "Description is required." };
  }

  if (!Number.isInteger(input.quantity) || input.quantity <= 0) {
    return { ok: false, error: "Quantity must be a positive integer." };
  }

  if (!isValidDateString(input.nextRunDate)) {
    return { ok: false, error: "Next run date must be valid." };
  }

  let unitAmountCents = 0;

  try {
    unitAmountCents = dollarsToCents(input.unitAmount);
  } catch {
    return { ok: false, error: "Unit amount must be a valid money amount." };
  }

  const now = new Date();

  const [created] = await db
    .insert(recurringInvoices)
    .values({
      organizationId: organization.id,
      customerId: input.customerId,
      description: input.description.trim(),
      quantity: input.quantity,
      unitAmountCents,
      gstRateBasisPoints: input.gstRateBasisPoints,
      frequency: input.frequency,
      nextRunDate: input.nextRunDate,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    })
    .returning();

  if (!created) {
    return { ok: false, error: "Recurring invoice could not be created." };
  }

  return {
    ok: true,
    recurringInvoice: created,
  };
}

export async function listCurrentOrganizationRecurringInvoices(): Promise<{
  organizationId: string | null;
  recurringInvoices: RecurringInvoice[];
}> {
  const organization = await requireCurrentDatabaseOrganization().catch(
    () => null,
  );

  if (!organization) {
    return {
      organizationId: null,
      recurringInvoices: [],
    };
  }

  const rows = await db
    .select()
    .from(recurringInvoices)
    .where(eq(recurringInvoices.organizationId, organization.id))
    .orderBy(asc(recurringInvoices.nextRunDate));

  return {
    organizationId: organization.id,
    recurringInvoices: rows,
  };
}

/**
 * Generates due recurring invoices.
 *
 * Note:
 * This simple tutorial implementation loops through profiles and calls the
 * existing invoice creation service. In production, you may want a dedicated
 * system-context invoice creation service that does not depend on a signed-in
 * Clerk user.
 */
export async function generateDueRecurringInvoicesForCurrentOrganization(
  asOfDate: string,
): Promise<{
  generatedCount: number;
}> {
  const organization = await requireCurrentDatabaseOrganization();

  const dueProfiles = await db
    .select()
    .from(recurringInvoices)
    .where(
      and(
        eq(recurringInvoices.organizationId, organization.id),
        eq(recurringInvoices.isActive, true),
        lte(recurringInvoices.nextRunDate, asOfDate),
      ),
    );

  let generatedCount = 0;

  for (const profile of dueProfiles) {
    const result = await createInvoiceForCurrentOrganization({
      customerId: profile.customerId,
      issueDate: asOfDate,
      dueDate: calculateNextRunDate({
        currentRunDate: asOfDate,
        frequency: "monthly",
      }),
      description: profile.description,
      quantity: profile.quantity,
      unitAmount: (profile.unitAmountCents / 100).toFixed(2),
      gstRateBasisPoints: profile.gstRateBasisPoints,
      notes: `Generated from recurring invoice profile ${profile.id}`,
    });

    if (result.ok) {
      generatedCount += 1;

      await db
        .update(recurringInvoices)
        .set({
          lastGeneratedInvoiceId: result.invoice.id,
          nextRunDate: calculateNextRunDate({
            currentRunDate: profile.nextRunDate,
            frequency: profile.frequency,
          }),
          updatedAt: new Date(),
        })
        .where(eq(recurringInvoices.id, profile.id));
    }
  }

  return {
    generatedCount,
  };
}
```

Important note:

The scheduled Inngest version cannot rely on a current user session. In this tutorial, we will provide UI-triggered generation for the active organization and a scheduled function stub. A production implementation should create a system-context organization service.

---

## The Verification

Run:

```bash
pnpm build
```

---

# 4. Create Recurring Invoice Actions

## The Target

We are creating:

```txt
app/invoices/recurring/actions.ts
```

---

## The Implementation

Create:

```bash
mkdir -p app/invoices/recurring
```

Create:

```txt
app/invoices/recurring/actions.ts
```

Add:

```ts
// app/invoices/recurring/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import {
  createRecurringInvoiceForCurrentOrganization,
  generateDueRecurringInvoicesForCurrentOrganization,
} from "@/services/invoices/recurring-invoice-services";

export async function createRecurringInvoiceAction(formData: FormData) {
  const result = await createRecurringInvoiceForCurrentOrganization({
    customerId: String(formData.get("customerId") ?? ""),
    description: String(formData.get("description") ?? ""),
    quantity: Number(formData.get("quantity") ?? 1),
    unitAmount: String(formData.get("unitAmount") ?? ""),
    gstRateBasisPoints: Number(formData.get("gstRateBasisPoints") ?? 900),
    frequency: String(formData.get("frequency") ?? "monthly") as
      | "monthly"
      | "quarterly"
      | "yearly",
    nextRunDate: String(formData.get("nextRunDate") ?? ""),
  });

  revalidatePath("/invoices/recurring");

  if (!result.ok) {
    redirect(
      `/invoices/recurring?status=error&message=${encodeURIComponent(
        result.error,
      )}`,
    );
  }

  redirect("/invoices/recurring?status=created");
}

export async function generateDueRecurringInvoicesAction() {
  const today = new Date().toISOString().slice(0, 10);

  const result = await generateDueRecurringInvoicesForCurrentOrganization(today);

  revalidatePath("/invoices");
  revalidatePath("/invoices/recurring");

  redirect(`/invoices/recurring?status=generated&count=${result.generatedCount}`);
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Create Recurring Invoice Page

## The Target

We are creating:

```txt
app/invoices/recurring/page.tsx
```

---

## The Implementation

Create:

```txt
app/invoices/recurring/page.tsx
```

Add:

```tsx
// app/invoices/recurring/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS } from "@/lib/accounting/gst";
import { formatMoney } from "@/lib/money";
import { listCurrentOrganizationCustomers } from "@/services/customers/customer-services";
import {
  listCurrentOrganizationRecurringInvoices,
} from "@/services/invoices/recurring-invoice-services";
import {
  createRecurringInvoiceAction,
  generateDueRecurringInvoicesAction,
} from "@/app/invoices/recurring/actions";

export const dynamic = "force-dynamic";

type RecurringInvoicesPageProps = {
  searchParams?: Promise<{
    status?: string;
    message?: string;
    count?: string;
  }>;
};

function todayString(): string {
  return new Date().toISOString().slice(0, 10);
}

export default async function RecurringInvoicesPage({
  searchParams,
}: RecurringInvoicesPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const { organizationId, customers } = await listCurrentOrganizationCustomers();
  const recurring = await listCurrentOrganizationRecurringInvoices();

  return (
    <AppLayout
      title="Recurring Invoices"
      description="Create invoice templates that can generate invoices on a schedule."
    >
      <div className="space-y-6">
        {resolvedSearchParams.status === "created" ? (
          <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
            <p className="text-sm font-semibold">
              Recurring invoice profile created.
            </p>
          </section>
        ) : null}

        {resolvedSearchParams.status === "generated" ? (
          <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
            <p className="text-sm font-semibold">
              Generated {resolvedSearchParams.count ?? "0"} recurring invoice
              {resolvedSearchParams.count === "1" ? "" : "s"}.
            </p>
          </section>
        ) : null}

        {resolvedSearchParams.status === "error" ? (
          <section className="rounded-2xl border border-rose-200 bg-rose-50 p-5 text-rose-800">
            <p className="text-sm font-semibold">
              Recurring invoice action failed.
            </p>
            <p className="mt-2 text-sm leading-6">
              {resolvedSearchParams.message}
            </p>
          </section>
        ) : null}

        {!organizationId ? (
          <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-800">
            <p className="text-sm font-semibold">
              Create or select a company workspace first.
            </p>
          </section>
        ) : (
          <>
            <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
                New recurring invoice
              </p>

              <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
                Create recurring profile
              </h2>

              {customers.length === 0 ? (
                <div className="mt-5 rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
                  Create a customer before setting up recurring invoices.
                </div>
              ) : (
                <form action={createRecurringInvoiceAction} className="mt-6">
                  <div className="grid gap-4 md:grid-cols-3">
                    <label className="block">
                      <span className="text-sm font-semibold text-slate-700">
                        Customer
                      </span>
                      <select
                        name="customerId"
                        required
                        className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm"
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
                        Frequency
                      </span>
                      <select
                        name="frequency"
                        required
                        defaultValue="monthly"
                        className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm"
                      >
                        <option value="monthly">Monthly</option>
                        <option value="quarterly">Quarterly</option>
                        <option value="yearly">Yearly</option>
                      </select>
                    </label>

                    <label className="block">
                      <span className="text-sm font-semibold text-slate-700">
                        Next run date
                      </span>
                      <input
                        name="nextRunDate"
                        type="date"
                        required
                        defaultValue={todayString()}
                        className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm"
                      />
                    </label>
                  </div>

                  <div className="mt-4 grid gap-4 md:grid-cols-[1.4fr_0.4fr_0.6fr_0.6fr]">
                    <input
                      name="description"
                      required
                      defaultValue="Monthly retainer services"
                      className="rounded-xl border border-slate-300 px-3 py-2 text-sm"
                    />

                    <input
                      name="quantity"
                      type="number"
                      min={1}
                      step={1}
                      required
                      defaultValue={1}
                      className="rounded-xl border border-slate-300 px-3 py-2 text-sm"
                    />

                    <input
                      name="unitAmount"
                      required
                      defaultValue="100.00"
                      className="rounded-xl border border-slate-300 px-3 py-2 text-sm"
                    />

                    <input
                      name="gstRateBasisPoints"
                      type="number"
                      required
                      defaultValue={DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS}
                      className="rounded-xl border border-slate-300 px-3 py-2 text-sm"
                    />
                  </div>

                  <button
                    type="submit"
                    className="mt-5 rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white"
                  >
                    Create recurring profile
                  </button>
                </form>
              )}
            </section>

            <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <h2 className="text-lg font-semibold text-slate-950">
                    Recurring profiles
                  </h2>
                  <p className="mt-1 text-sm text-slate-500">
                    Generate due invoices manually for this tutorial.
                  </p>
                </div>

                <form action={generateDueRecurringInvoicesAction}>
                  <button
                    type="submit"
                    className="rounded-xl bg-emerald-700 px-4 py-2 text-sm font-semibold text-white"
                  >
                    Generate due invoices
                  </button>
                </form>
              </div>

              {recurring.recurringInvoices.length > 0 ? (
                <div className="mt-6 overflow-x-auto">
                  <table className="w-full border-collapse text-left text-sm">
                    <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                      <tr>
                        <th className="px-4 py-3 font-semibold">
                          Description
                        </th>
                        <th className="px-4 py-3 font-semibold">
                          Frequency
                        </th>
                        <th className="px-4 py-3 font-semibold">
                          Next run
                        </th>
                        <th className="px-4 py-3 text-right font-semibold">
                          Unit
                        </th>
                      </tr>
                    </thead>

                    <tbody className="divide-y divide-slate-200">
                      {recurring.recurringInvoices.map((profile) => (
                        <tr key={profile.id}>
                          <td className="px-4 py-3 font-semibold">
                            {profile.description}
                          </td>
                          <td className="px-4 py-3">{profile.frequency}</td>
                          <td className="px-4 py-3">{profile.nextRunDate}</td>
                          <td className="px-4 py-3 text-right">
                            {formatMoney(profile.unitAmountCents)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="mt-6 rounded-xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center text-sm text-slate-500">
                  No recurring profiles yet.
                </div>
              )}
            </section>

            <Link
              href="/invoices"
              className="inline-flex rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm"
            >
              Back to invoices
            </Link>
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
/invoices/recurring
```

Create a recurring invoice profile.

Click:

```txt
Generate due invoices
```

If the profile is due, a new invoice should be generated.

---

# 6. Add Scheduled Inngest Function Stub

## The Target

We are updating:

```txt
inngest/functions.ts
```

---

## The Concept

A full production recurring invoice job needs a system-context version of invoice creation that does not depend on the current signed-in user.

For this tutorial, we add the scheduled function as a stub that documents the automation path.

---

## The Implementation

Open:

```txt
inngest/functions.ts
```

Add:

```ts
export const dailyRecurringInvoiceScheduler = inngest.createFunction(
  {
    id: "daily-recurring-invoice-scheduler",
    name: "Daily Recurring Invoice Scheduler",
  },
  {
    cron: "15 0 * * *",
  },
  async ({ step }) => {
    const result = await step.run("document-recurring-invoice-scan", async () => {
      return {
        message:
          "Recurring invoice scheduler triggered. Production implementation should generate due invoices using system organization context.",
        triggeredAt: new Date().toISOString(),
      };
    });

    return result;
  },
);
```

Add it to `inngestFunctions`:

```ts
dailyRecurringInvoiceScheduler,
```

---

## The Verification

Run:

```bash
pnpm build
```

Run Inngest dev server and confirm the function appears.

---

# 7. Link Recurring Invoices from Invoice Page

## The Target

We are updating:

```txt
app/invoices/page.tsx
```

---

## The Implementation

Add a link near summary cards:

```tsx
<Link
  href="/invoices/recurring"
  className="rounded-2xl border border-purple-200 bg-purple-50 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
>
  <p className="text-sm font-semibold text-purple-700">
    Recurring invoices
  </p>
  <p className="mt-2 text-sm leading-6 text-purple-800">
    Create invoice templates for repeat billing.
  </p>
</Link>
```

If your grid currently has three columns, change to four columns or place it below.

---

## The Verification

Open:

```txt
/invoices
```

Click recurring invoices link.

---

# 8. Verify in Neon SQL

## The Target

We are checking recurring profiles.

---

## The Implementation

Run:

```sql
select
  description,
  frequency,
  next_run_date,
  is_active,
  last_generated_invoice_id
from recurring_invoices
order by created_at desc;
```

---

## The Verification

You should see recurring invoice profiles.

After generation, `last_generated_invoice_id` should be populated.

---

# 9. Run Full Project Check

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

# 10. Commit Recurring Invoices

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Build recurring invoices system"
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

## Error: `relation "recurring_invoices" does not exist`

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Generate due invoices creates zero

Check:

```txt
next_run_date <= today
is_active = true
```

---

## Error: Scheduled recurring function does not generate invoices

That is expected in this tutorial implementation.

The scheduled function is a production-path stub because true generation should use system organization context.

Use the manual button for now.

---

# Phase 11 Reference — Recurring Invoices

## Recurring Profile

A template for generating invoices.

---

## Next Run Date

The date the profile is next due to generate an invoice.

---

## Frequency

How often it repeats:

```txt
monthly
quarterly
yearly
```

---

# Part 39 Completion Checklist

You are ready for Part 40 if:

- [ ] Recurring invoice enum exists
- [ ] `recurring_invoices` table exists
- [ ] Recurring invoice service exists
- [ ] Recurring invoice page exists
- [ ] Profiles can be created
- [ ] Due profiles can generate invoices manually
- [ ] Generated invoices appear in `/invoices`
- [ ] Scheduled Inngest stub exists
- [ ] Inngest dev server sees recurring scheduler
- [ ] Neon SQL confirms recurring profiles
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
