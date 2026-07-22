# Part 30 — Audit Log System

In Part 29, we added journal entry reversals.

That gave us accounting correction history.

Now we add a broader audit log system.

An audit log answers:

```txt
Who did what?
When did they do it?
What record did they affect?
What details were captured?
```

By the end of this part, you will have:

- `audit_logs` database table
- Audit action enum
- Audit log service
- Audit logging for important operations
- Audit log page
- Audit diagnostics in settings
- Tenant-scoped audit queries
- Neon SQL verification

---

# 1. Understand Audit Logs

## The Target

We are adding an audit trail for important system actions.

---

## The Concept

A journal reversal records accounting correction.

An audit log records operational history.

Examples:

```txt
User created invoice INV-2026-0001
User recorded customer payment
User reversed a journal entry
User created a custom account
User created customer Merlion Trading
```

Think of the audit log as a building security camera.

It does not replace the accounting ledger.

It records user/system activity around it.

---

# 2. Add Audit Log Schema

## The Target

We are updating:

```txt
db/schema.ts
```

to add:

```txt
audit_action enum
audit_logs
```

---

## The Concept

Each audit log belongs to one organization.

It stores:

```txt
actor_user_id
action
entity_type
entity_id
message
metadata_json
created_at
```

For metadata, we will store JSON as text for now.

A production app could use Postgres `jsonb`.

---

## The Implementation

Open:

```txt
db/schema.ts
```

Add enum near other enums:

```ts
export const auditActionEnum = pgEnum("audit_action", [
  "account.created",
  "account.status_changed",
  "customer.created",
  "vendor.created",
  "invoice.created",
  "bill.created",
  "customer_payment.recorded",
  "vendor_payment.recorded",
  "journal_entry.reversed",
]);
```

Add table after organizations or near the end:

```ts
export const auditLogs = pgTable(
  "audit_logs",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),

    actorUserId: text("actor_user_id"),

    action: auditActionEnum("action").notNull(),

    entityType: text("entity_type").notNull(),

    entityId: uuid("entity_id"),

    message: text("message").notNull(),

    metadataJson: text("metadata_json"),

    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    index("audit_logs_organization_id_created_at_idx").on(
      table.organizationId,
      table.createdAt,
    ),
    index("audit_logs_organization_id_action_idx").on(
      table.organizationId,
      table.action,
    ),
    index("audit_logs_organization_id_entity_idx").on(
      table.organizationId,
      table.entityType,
      table.entityId,
    ),
  ],
);
```

At the bottom add:

```ts
export type AuditLog = typeof auditLogs.$inferSelect;
export type NewAuditLog = typeof auditLogs.$inferInsert;
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
audit_logs
```

---

# 3. Create Audit Log Service

## The Target

We are creating:

```txt
services/audit/audit-log-service.ts
```

---

## The Concept

Services that perform important actions will call:

```ts
writeAuditLog()
```

We keep audit logic centralized so every audit row has consistent shape.

---

## The Implementation

Create:

```bash
mkdir -p services/audit
```

Create:

```txt
services/audit/audit-log-service.ts
```

Add:

```ts
// services/audit/audit-log-service.ts

import { auth } from "@clerk/nextjs/server";
import { desc, eq } from "drizzle-orm";
import { db } from "@/db";
import { auditLogs, auditActionEnum, type AuditLog } from "@/db/schema";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type AuditAction = (typeof auditActionEnum.enumValues)[number];

export type WriteAuditLogInput = {
  action: AuditAction;
  entityType: string;
  entityId?: string | null;
  message: string;
  metadata?: Record<string, unknown>;
};

export async function writeAuditLog(
  input: WriteAuditLogInput,
): Promise<AuditLog> {
  const organization = await requireCurrentDatabaseOrganization();
  const { userId } = await auth();

  const [created] = await db
    .insert(auditLogs)
    .values({
      organizationId: organization.id,
      actorUserId: userId ?? null,
      action: input.action,
      entityType: input.entityType,
      entityId: input.entityId ?? null,
      message: input.message,
      metadataJson: input.metadata ? JSON.stringify(input.metadata) : null,
      createdAt: new Date(),
    })
    .returning();

  if (!created) {
    throw new Error("Audit log could not be written.");
  }

  return created;
}

export async function listCurrentOrganizationAuditLogs(): Promise<{
  organizationId: string | null;
  logs: AuditLog[];
}> {
  const organization = await requireCurrentDatabaseOrganization().catch(
    () => null,
  );

  if (!organization) {
    return {
      organizationId: null,
      logs: [],
    };
  }

  const logs = await db
    .select()
    .from(auditLogs)
    .where(eq(auditLogs.organizationId, organization.id))
    .orderBy(desc(auditLogs.createdAt))
    .limit(100);

  return {
    organizationId: organization.id,
    logs,
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

# 4. Add Audit Logging to Selected Services

## The Target

We are adding audit logs to important operations.

---

## The Concept

We will add logs to:

```txt
Customer created
Vendor created
Invoice created
Bill created
Customer payment recorded
Vendor payment recorded
Journal entry reversed
```

This gives useful visibility without overwhelming the tutorial.

---

## The Implementation

### Customer service

Open:

```txt
services/customers/customer-services.ts
```

Import:

```ts
import { writeAuditLog } from "@/services/audit/audit-log-service";
```

After successful customer creation, before returning, add:

```ts
await writeAuditLog({
  action: "customer.created",
  entityType: "customer",
  entityId: created.id,
  message: `Customer created: ${created.name}`,
  metadata: {
    customerName: created.name,
    email: created.email,
  },
});
```

### Vendor service

Open:

```txt
services/vendors/vendor-services.ts
```

Import:

```ts
import { writeAuditLog } from "@/services/audit/audit-log-service";
```

After successful vendor creation, before returning, add:

```ts
await writeAuditLog({
  action: "vendor.created",
  entityType: "vendor",
  entityId: created.id,
  message: `Vendor created: ${created.name}`,
  metadata: {
    vendorName: created.name,
    email: created.email,
  },
});
```

### Invoice service

Open:

```txt
services/invoices/invoice-services.ts
```

Import:

```ts
import { writeAuditLog } from "@/services/audit/audit-log-service";
```

After successful invoice creation transaction returns and before returning success, add:

```ts
await writeAuditLog({
  action: "invoice.created",
  entityType: "invoice",
  entityId: result.id,
  message: `Invoice created and posted: ${result.invoiceNumber}`,
  metadata: {
    invoiceNumber: result.invoiceNumber,
    totalCents: result.totalCents,
    journalEntryId: result.journalEntryId,
  },
});
```

### Bill service

Open:

```txt
services/bills/bill-services.ts
```

Import:

```ts
import { writeAuditLog } from "@/services/audit/audit-log-service";
```

After successful bill creation transaction returns and before returning success, add:

```ts
await writeAuditLog({
  action: "bill.created",
  entityType: "bill",
  entityId: result.id,
  message: `Bill created and posted: ${result.billNumber}`,
  metadata: {
    billNumber: result.billNumber,
    totalCents: result.totalCents,
    journalEntryId: result.journalEntryId,
  },
});
```

### Customer payment service

Open:

```txt
services/payments/customer-payment-services.ts
```

Import:

```ts
import { writeAuditLog } from "@/services/audit/audit-log-service";
```

After successful payment transaction returns and before returning success, add:

```ts
await writeAuditLog({
  action: "customer_payment.recorded",
  entityType: "customer_payment",
  entityId: result.id,
  message: "Customer payment recorded.",
  metadata: {
    amountCents: result.amountCents,
    invoiceId: result.invoiceId,
    journalEntryId: result.journalEntryId,
  },
});
```

### Vendor payment service

Open:

```txt
services/payments/vendor-payment-services.ts
```

Import:

```ts
import { writeAuditLog } from "@/services/audit/audit-log-service";
```

After successful payment transaction returns and before returning success, add:

```ts
await writeAuditLog({
  action: "vendor_payment.recorded",
  entityType: "vendor_payment",
  entityId: result.id,
  message: "Vendor payment recorded.",
  metadata: {
    amountCents: result.amountCents,
    billId: result.billId,
    journalEntryId: result.journalEntryId,
  },
});
```

### Reversal service

Open:

```txt
services/journal/reverse-journal-entry.ts
```

Import:

```ts
import { writeAuditLog } from "@/services/audit/audit-log-service";
```

After successful transaction returns and before returning success, add:

```ts
await writeAuditLog({
  action: "journal_entry.reversed",
  entityType: "journal_entry",
  entityId: params.journalEntryId,
  message: `Journal entry reversed: ${params.journalEntryId}`,
  metadata: {
    reversalJournalEntryId: result.id,
    reason,
  },
});
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Create Audit Log Page

## The Target

We are creating:

```txt
app/settings/audit-log/page.tsx
```

---

## The Concept

The audit page lists recent actions for the active organization.

This helps admins and developers see operational history.

---

## The Implementation

Create:

```bash
mkdir -p app/settings/audit-log
```

Create:

```txt
app/settings/audit-log/page.tsx
```

Add:

```tsx
// app/settings/audit-log/page.tsx

import { AppLayout } from "@/components/app-layout";
import { listCurrentOrganizationAuditLogs } from "@/services/audit/audit-log-service";

export const dynamic = "force-dynamic";

export default async function AuditLogPage() {
  const { organizationId, logs } = await listCurrentOrganizationAuditLogs();

  return (
    <AppLayout
      title="Audit Log"
      description="Review recent operational activity for the active organization."
    >
      <div className="space-y-6">
        {!organizationId ? (
          <section className="rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-800">
            <p className="text-sm font-semibold">
              Create or select a company workspace first.
            </p>
          </section>
        ) : null}

        {organizationId ? (
          <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
            <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
              <h2 className="text-lg font-semibold text-slate-950">
                Recent audit events
              </h2>
              <p className="mt-1 text-sm text-slate-500">
                Showing up to 100 recent events.
              </p>
            </div>

            {logs.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="w-full border-collapse text-left text-sm">
                  <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                    <tr>
                      <th className="px-6 py-3 font-semibold">Time</th>
                      <th className="px-6 py-3 font-semibold">Action</th>
                      <th className="px-6 py-3 font-semibold">Entity</th>
                      <th className="px-6 py-3 font-semibold">Message</th>
                      <th className="px-6 py-3 font-semibold">Actor</th>
                    </tr>
                  </thead>

                  <tbody className="divide-y divide-slate-200">
                    {logs.map((log) => (
                      <tr key={log.id}>
                        <td className="px-6 py-4 text-slate-600">
                          {log.createdAt.toISOString()}
                        </td>

                        <td className="px-6 py-4">
                          <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-700">
                            {log.action}
                          </span>
                        </td>

                        <td className="px-6 py-4 text-slate-600">
                          {log.entityType}
                        </td>

                        <td className="px-6 py-4 font-medium text-slate-950">
                          {log.message}
                        </td>

                        <td className="px-6 py-4">
                          <code className="break-all text-xs text-slate-500">
                            {log.actorUserId ?? "system"}
                          </code>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="p-8 text-center text-sm text-slate-500">
                No audit events yet. Create a customer, invoice, bill, payment,
                or reversal to generate audit logs.
              </div>
            )}
          </section>
        ) : null}
      </div>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
/settings/audit-log
```

You may see no events until you perform actions after adding audit logging.

Create a customer or invoice, then reload.

---

# 6. Link Audit Log from Settings

## The Target

We are updating:

```txt
app/settings/page.tsx
```

---

## The Implementation

Add this card to `settingsCards`:

```ts
{
  eyebrow: "Audit",
  title: "Audit log",
  description:
    "Review recent operational activity for the active organization.",
  href: "/settings/audit-log",
},
```

---

## The Verification

Open:

```txt
/settings
```

Click:

```txt
Audit log
```

---

# 7. Test Audit Logging

## The Target

We are creating audit log events.

---

## The Implementation

Perform any of these actions:

```txt
Create a customer
Create a vendor
Create an invoice
Create a bill
Record a payment
Reverse a journal entry
```

Then open:

```txt
/settings/audit-log
```

---

## The Verification

You should see rows such as:

```txt
customer.created
invoice.created
bill.created
customer_payment.recorded
journal_entry.reversed
```

---

# 8. Verify in Neon SQL

## The Target

We are checking audit log rows directly.

---

## The Implementation

Run:

```sql
select
  action,
  entity_type,
  entity_id,
  message,
  actor_user_id,
  metadata_json,
  created_at
from audit_logs
order by created_at desc;
```

---

## The Verification

You should see audit rows for recent actions.

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

# 10. Commit Audit Log System

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Add audit log system"
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

## Error: `relation "audit_logs" does not exist`

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Audit log page shows no events

Only actions performed after adding audit logging will create rows.

Create a new customer or invoice.

---

## Error: Audit action enum missing value

Make sure `auditActionEnum` includes the action string you are writing.

---

## Error: Metadata JSON too large

For this tutorial, metadata is small.

In production, avoid logging sensitive data or huge objects.

---

# Phase 9 Reference — Audit Logs

## Audit Log

A record of operational activity.

---

## Actor

The user or system that performed the action.

---

## Entity

The record affected by the action.

Examples:

```txt
invoice
bill
journal_entry
customer_payment
```

---

## Audit vs Journal

The journal records accounting effects.

The audit log records operational actions.

---

# Part 30 Completion Checklist

You are ready for Part 31 if:

- [ ] `auditActionEnum` exists
- [ ] `audit_logs` table exists
- [ ] Audit migration applied
- [ ] `writeAuditLog()` exists
- [ ] Customer creation writes audit log
- [ ] Vendor creation writes audit log
- [ ] Invoice creation writes audit log
- [ ] Bill creation writes audit log
- [ ] Customer payment writes audit log
- [ ] Vendor payment writes audit log
- [ ] Journal reversal writes audit log
- [ ] `/settings/audit-log` loads
- [ ] `/settings` links to audit log
- [ ] Neon SQL shows audit log rows
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
