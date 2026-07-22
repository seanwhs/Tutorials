# Part 38 — Daily Overdue Invoice Reminders

In Part 37, we sent an `invoice.created` event after invoice creation.

Now we will build a scheduled background job.

The job will find overdue unpaid invoices every day.

By the end of this part, you will have:

- Overdue invoice query service
- Scheduled Inngest function
- Daily reminder workflow
- Background job page updated with reminder details
- Manual local testing through Inngest dev server

We will not send real email yet.

For now, the function returns structured reminder data.

---

# 1. Understand Scheduled Jobs

## The Target

We are creating a daily scheduled job.

---

## The Concept

Some tasks should happen automatically on a schedule.

Examples:

```txt
Every day at 8 AM, find overdue invoices.
Every month, generate recurring invoices.
Every night, sync bank feeds.
```

Inngest supports scheduled functions with cron syntax.

Cron syntax is a compact schedule format.

Example:

```txt
0 0 * * *
```

means:

```txt
Every day at midnight
```

---

# 2. Create Overdue Invoice Query Service

## The Target

We are creating:

```txt
services/invoices/overdue-invoice-services.ts
```

---

## The Concept

An invoice is overdue if:

```txt
due_date < today
status is not paid
status is not void
```

---

## The Implementation

Create:

```txt
services/invoices/overdue-invoice-services.ts
```

Add:

```ts
// services/invoices/overdue-invoice-services.ts

import { and, lt, notInArray } from "drizzle-orm";
import { db } from "@/db";
import { customers, invoices, organizations } from "@/db/schema";

export type OverdueInvoiceReminderItem = {
  organizationId: string;
  organizationName: string;
  invoiceId: string;
  invoiceNumber: string;
  customerName: string;
  customerEmail: string | null;
  dueDate: string;
  totalCents: number;
};

export async function listOverdueInvoicesForAllOrganizations(
  asOfDate: string,
): Promise<OverdueInvoiceReminderItem[]> {
  return db
    .select({
      organizationId: organizations.id,
      organizationName: organizations.name,
      invoiceId: invoices.id,
      invoiceNumber: invoices.invoiceNumber,
      customerName: customers.name,
      customerEmail: customers.email,
      dueDate: invoices.dueDate,
      totalCents: invoices.totalCents,
    })
    .from(invoices)
    .innerJoin(customers, invoices.customerId.eq(customers.id))
    .innerJoin(organizations, invoices.organizationId.eq(organizations.id))
    .where(
      and(
        lt(invoices.dueDate, asOfDate),
        notInArray(invoices.status, ["paid", "void"]),
      ),
    );
}
```

If your Drizzle version does not support `.eq()` on columns in joins, use this version instead:

```ts
import { and, eq, lt, notInArray } from "drizzle-orm";
```

and:

```ts
.innerJoin(customers, eq(invoices.customerId, customers.id))
.innerJoin(organizations, eq(invoices.organizationId, organizations.id))
```

Use whichever version matches your existing code style. Throughout this tutorial, we have mostly used `eq(...)`, so the safer final version is below.

Replace the file with this final version if needed:

```ts
// services/invoices/overdue-invoice-services.ts

import { and, eq, lt, notInArray } from "drizzle-orm";
import { db } from "@/db";
import { customers, invoices, organizations } from "@/db/schema";

export type OverdueInvoiceReminderItem = {
  organizationId: string;
  organizationName: string;
  invoiceId: string;
  invoiceNumber: string;
  customerName: string;
  customerEmail: string | null;
  dueDate: string;
  totalCents: number;
};

export async function listOverdueInvoicesForAllOrganizations(
  asOfDate: string,
): Promise<OverdueInvoiceReminderItem[]> {
  return db
    .select({
      organizationId: organizations.id,
      organizationName: organizations.name,
      invoiceId: invoices.id,
      invoiceNumber: invoices.invoiceNumber,
      customerName: customers.name,
      customerEmail: customers.email,
      dueDate: invoices.dueDate,
      totalCents: invoices.totalCents,
    })
    .from(invoices)
    .innerJoin(customers, eq(invoices.customerId, customers.id))
    .innerJoin(organizations, eq(invoices.organizationId, organizations.id))
    .where(
      and(
        lt(invoices.dueDate, asOfDate),
        notInArray(invoices.status, ["paid", "void"]),
      ),
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

# 3. Add Scheduled Inngest Function

## The Target

We are updating:

```txt
inngest/functions.ts
```

---

## The Concept

This function will run daily and find overdue invoices.

For local testing, the Inngest dev server can trigger it manually.

---

## The Implementation

Open:

```txt
inngest/functions.ts
```

Add import:

```ts
import { listOverdueInvoicesForAllOrganizations } from "@/services/invoices/overdue-invoice-services";
```

Add function:

```ts
export const dailyOverdueInvoiceReminders = inngest.createFunction(
  {
    id: "daily-overdue-invoice-reminders",
    name: "Daily Overdue Invoice Reminders",
  },
  {
    cron: "0 0 * * *",
  },
  async ({ step }) => {
    const today = new Date().toISOString().slice(0, 10);

    const overdueInvoices = await step.run("load-overdue-invoices", async () => {
      return listOverdueInvoicesForAllOrganizations(today);
    });

    const reminders = await step.run("prepare-reminders", async () => {
      return overdueInvoices.map((invoice) => ({
        organizationId: invoice.organizationId,
        organizationName: invoice.organizationName,
        invoiceId: invoice.invoiceId,
        invoiceNumber: invoice.invoiceNumber,
        customerName: invoice.customerName,
        customerEmail: invoice.customerEmail,
        dueDate: invoice.dueDate,
        totalCents: invoice.totalCents,
        reminderMessage: `Invoice ${invoice.invoiceNumber} is overdue.`,
      }));
    });

    return {
      asOfDate: today,
      reminderCount: reminders.length,
      reminders,
    };
  },
);
```

Update `inngestFunctions`:

```ts
export const inngestFunctions = [
  backgroundHealthCheck,
  invoiceCreatedConfirmation,
  dailyOverdueInvoiceReminders,
];
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 4. Update Background Jobs Settings Page

## The Target

We are updating:

```txt
app/settings/background-jobs/page.tsx
```

---

## The Concept

We want the page to document the scheduled job.

---

## The Implementation

Add this section below the health check section:

```tsx
<section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-sky-600">
    Scheduled workflow
  </p>

  <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
    Daily overdue invoice reminders
  </h2>

  <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
    The Inngest function <code>daily-overdue-invoice-reminders</code> runs on a
    daily cron schedule and finds unpaid overdue invoices. In this tutorial
    stage, it prepares reminder payloads instead of sending real emails.
  </p>

  <div className="mt-4 rounded-xl bg-slate-50 p-4 text-sm leading-6 text-slate-700">
    Cron schedule: <code>0 0 * * *</code>
  </div>
</section>
```

---

## The Verification

Open:

```txt
/settings/background-jobs
```

You should see the overdue invoice reminder section.

---

# 5. Create an Overdue Invoice for Testing

## The Target

We are creating an invoice with a past due date.

---

## The Implementation

Open:

```txt
/invoices
```

Create an invoice with:

```txt
Issue date: 2026-01-01
Due date: 2026-01-02
```

Do not record payment.

If today is after that due date, it is overdue.

---

## The Verification

Open:

```txt
/reports/ar-aging
```

The invoice should appear as overdue.

---

# 6. Run Inngest Dev Server and Trigger Schedule

## The Target

We are testing the scheduled function locally.

---

## The Implementation

Terminal 1:

```bash
pnpm dev
```

Terminal 2:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

Open the Inngest dev UI.

Find:

```txt
Daily Overdue Invoice Reminders
```

Trigger it manually if the dev UI allows.

---

## The Verification

The function output should include:

```txt
reminderCount
reminders
```

If you have overdue invoices, reminder count should be greater than zero.

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

# 8. Commit Overdue Reminder Job

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Add daily overdue invoice reminders"
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

## Error: Scheduled function does not appear

Check that it is included in:

```ts
inngestFunctions
```

---

## Error: No overdue invoices found

Check invoice status and due date.

Overdue means:

```txt
due_date < today
status not paid
status not void
```

---

## Error: Build fails on join syntax

Use:

```ts
innerJoin(customers, eq(invoices.customerId, customers.id))
```

instead of column `.eq()` syntax.

---

# Phase 11 Reference — Scheduled Jobs

## Cron

A schedule expression.

```txt
0 0 * * *
```

means daily at midnight.

---

## Overdue Invoice

An invoice where:

```txt
due date is before today
status is not paid or void
```

---

# Part 38 Completion Checklist

You are ready for Part 39 if:

- [ ] Overdue invoice service exists
- [ ] Scheduled Inngest function exists
- [ ] Function included in `inngestFunctions`
- [ ] Background jobs settings page documents reminder job
- [ ] Test overdue invoice can be created
- [ ] Inngest dev server can trigger reminder job
- [ ] Reminder output includes overdue invoices
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
