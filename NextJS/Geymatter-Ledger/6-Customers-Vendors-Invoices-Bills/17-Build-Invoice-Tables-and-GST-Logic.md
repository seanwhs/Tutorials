# Part 17 — Build Invoice Tables and GST Logic

In Part 16, we added customers and vendors.

Now we will build the database foundation for invoices.

An invoice is a business document sent to a customer when they owe us money.

In accounting terms, a posted invoice will eventually create this kind of journal entry:

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

But we are **not posting invoices to the journal yet**.

That comes in **Part 18**.

In this part, we will build:

- Invoice database tables
- Invoice line database tables
- Invoice status enum
- GST calculation helpers
- Automated tests for GST logic
- Invoice query diagnostics
- Updated database health checks
- Updated invoice page placeholder that understands the schema exists

---

# 1. Understand Invoice Data

## The Target

We are creating the database structure for:

```txt
invoices
invoice_lines
```

---

## The Concept

An invoice has two layers:

```txt
Invoice header
  = customer, invoice number, dates, totals, status

Invoice lines
  = individual items or services being billed
```

A simple invoice might look like this:

```txt
Invoice INV-0001
Customer: Merlion Trading Pte. Ltd.
Date: 2026-01-05
Due: 2026-02-04

Line 1:
  Consulting services
  Subtotal: S$100.00
  GST 9%:   S$9.00
  Total:    S$109.00
```

In database terms:

```txt
invoices
  id
  organization_id
  customer_id
  invoice_number
  issue_date
  due_date
  status
  subtotal_cents
  gst_cents
  total_cents

invoice_lines
  id
  invoice_id
  organization_id
  description
  quantity
  unit_amount_cents
  subtotal_cents
  gst_rate_basis_points
  gst_cents
  total_cents
```

---

# 2. Understand GST Basis Points

## The Target

We are deciding how to store GST rates.

---

## The Concept

Singapore GST is currently commonly represented as 9%.

Instead of storing this as a floating-point number like:

```ts
0.09
```

we will store it as **basis points**.

Basis points are hundredths of a percent.

```txt
1%    = 100 basis points
9%    = 900 basis points
0.5%  = 50 basis points
```

So:

```txt
9% GST = 900
```

Why?

Because accounting software should avoid floating-point math wherever possible.

Bad:

```ts
10000 * 0.09
```

Better:

```ts
Math.round((10000 * 900) / 10000)
```

For S$100.00:

```txt
10000 cents × 900 / 10000 = 900 cents
```

That gives:

```txt
GST = S$9.00
```

---

# 3. Create GST Logic Helpers

## The Target

We are creating:

```txt
lib/accounting/gst.ts
```

---

## The Concept

GST calculation should live in a reusable helper, not inside a page component.

Later, invoices, bills, GST reports, and tests will all use the same logic.

---

## The Implementation

Create:

```txt
lib/accounting/gst.ts
```

Add:

```ts
// lib/accounting/gst.ts

import type { MoneyCents } from "@/lib/money";

/**
 * Singapore GST rate represented as basis points.
 *
 * 9% = 900 basis points.
 */
export const DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS = 900;

/**
 * A line-level GST calculation result.
 */
export type GstLineCalculation = {
  subtotalCents: MoneyCents;
  gstRateBasisPoints: number;
  gstCents: MoneyCents;
  totalCents: MoneyCents;
};

/**
 * Ensures an amount is safe integer cents.
 */
function assertIntegerCents(value: number, label: string): void {
  if (!Number.isInteger(value) || !Number.isSafeInteger(value)) {
    throw new Error(`${label} must be integer cents.`);
  }
}

/**
 * Validates a GST rate represented in basis points.
 */
function assertValidBasisPoints(value: number): void {
  if (!Number.isInteger(value)) {
    throw new Error("GST rate basis points must be an integer.");
  }

  if (value < 0) {
    throw new Error("GST rate basis points cannot be negative.");
  }

  if (value > 10000) {
    throw new Error("GST rate basis points cannot exceed 100%.");
  }
}

/**
 * Calculates GST from a tax-exclusive subtotal.
 *
 * Example:
 *   subtotal: S$100.00 = 10000 cents
 *   GST rate: 9% = 900 basis points
 *
 *   gst = round(10000 * 900 / 10000)
 *       = 900 cents
 */
export function calculateGstFromExclusiveAmount(
  subtotalCents: MoneyCents,
  gstRateBasisPoints = DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS,
): GstLineCalculation {
  assertIntegerCents(subtotalCents, "Subtotal");
  assertValidBasisPoints(gstRateBasisPoints);

  if (subtotalCents < 0) {
    throw new Error("Subtotal cannot be negative.");
  }

  const gstCents = Math.round((subtotalCents * gstRateBasisPoints) / 10000);

  return {
    subtotalCents,
    gstRateBasisPoints,
    gstCents,
    totalCents: subtotalCents + gstCents,
  };
}

/**
 * Calculates a line subtotal from quantity and unit amount.
 *
 * Quantity is stored as an integer for now.
 * Example:
 *   quantity = 2
 *   unit = S$50.00 = 5000 cents
 *   subtotal = 10000 cents
 */
export function calculateInvoiceLineTotals(params: {
  quantity: number;
  unitAmountCents: MoneyCents;
  gstRateBasisPoints?: number;
}): GstLineCalculation & {
  quantity: number;
  unitAmountCents: MoneyCents;
} {
  if (!Number.isInteger(params.quantity)) {
    throw new Error("Quantity must be an integer.");
  }

  if (params.quantity <= 0) {
    throw new Error("Quantity must be greater than zero.");
  }

  assertIntegerCents(params.unitAmountCents, "Unit amount");

  if (params.unitAmountCents < 0) {
    throw new Error("Unit amount cannot be negative.");
  }

  const subtotalCents = params.quantity * params.unitAmountCents;

  const calculation = calculateGstFromExclusiveAmount(
    subtotalCents,
    params.gstRateBasisPoints ?? DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS,
  );

  return {
    quantity: params.quantity,
    unitAmountCents: params.unitAmountCents,
    ...calculation,
  };
}

/**
 * Sums multiple invoice line calculations.
 */
export function sumInvoiceLineTotals(lines: GstLineCalculation[]): {
  subtotalCents: MoneyCents;
  gstCents: MoneyCents;
  totalCents: MoneyCents;
} {
  return lines.reduce(
    (totals, line) => ({
      subtotalCents: totals.subtotalCents + line.subtotalCents,
      gstCents: totals.gstCents + line.gstCents,
      totalCents: totals.totalCents + line.totalCents,
    }),
    {
      subtotalCents: 0,
      gstCents: 0,
      totalCents: 0,
    },
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

# 4. Add GST Tests

## The Target

We are creating:

```txt
tests/gst.test.ts
```

---

## The Concept

GST logic is financial logic.

It should be tested.

We want to prove:

```txt
S$100 at 9% GST = S$9 GST and S$109 total
```

---

## The Implementation

Create:

```txt
tests/gst.test.ts
```

Add:

```ts
// tests/gst.test.ts

import { describe, expect, it } from "vitest";
import {
  calculateGstFromExclusiveAmount,
  calculateInvoiceLineTotals,
  DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS,
  sumInvoiceLineTotals,
} from "@/lib/accounting/gst";

describe("calculateGstFromExclusiveAmount", () => {
  it("calculates 9% Singapore GST on S$100.00", () => {
    const result = calculateGstFromExclusiveAmount(10000);

    expect(result.gstRateBasisPoints).toBe(
      DEFAULT_SINGAPORE_GST_RATE_BASIS_POINTS,
    );
    expect(result.subtotalCents).toBe(10000);
    expect(result.gstCents).toBe(900);
    expect(result.totalCents).toBe(10900);
  });

  it("supports zero-rated GST", () => {
    const result = calculateGstFromExclusiveAmount(10000, 0);

    expect(result.gstCents).toBe(0);
    expect(result.totalCents).toBe(10000);
  });

  it("rounds GST to the nearest cent", () => {
    const result = calculateGstFromExclusiveAmount(999, 900);

    expect(result.gstCents).toBe(90);
    expect(result.totalCents).toBe(1089);
  });

  it("rejects negative subtotals", () => {
    expect(() => calculateGstFromExclusiveAmount(-100)).toThrow(
      "Subtotal cannot be negative.",
    );
  });
});

describe("calculateInvoiceLineTotals", () => {
  it("calculates invoice line totals from quantity and unit amount", () => {
    const result = calculateInvoiceLineTotals({
      quantity: 2,
      unitAmountCents: 5000,
    });

    expect(result.subtotalCents).toBe(10000);
    expect(result.gstCents).toBe(900);
    expect(result.totalCents).toBe(10900);
  });

  it("rejects zero quantity", () => {
    expect(() =>
      calculateInvoiceLineTotals({
        quantity: 0,
        unitAmountCents: 5000,
      }),
    ).toThrow("Quantity must be greater than zero.");
  });

  it("rejects decimal unit cents", () => {
    expect(() =>
      calculateInvoiceLineTotals({
        quantity: 1,
        unitAmountCents: 100.5,
      }),
    ).toThrow("Unit amount must be integer cents.");
  });
});

describe("sumInvoiceLineTotals", () => {
  it("sums invoice line totals", () => {
    const first = calculateInvoiceLineTotals({
      quantity: 1,
      unitAmountCents: 10000,
    });

    const second = calculateInvoiceLineTotals({
      quantity: 2,
      unitAmountCents: 5000,
    });

    const totals = sumInvoiceLineTotals([first, second]);

    expect(totals.subtotalCents).toBe(20000);
    expect(totals.gstCents).toBe(1800);
    expect(totals.totalCents).toBe(21800);
  });
});
```

---

## The Verification

Run:

```bash
pnpm test
```

The tests should pass.

---

# 5. Update the Database Schema with Invoice Tables

## The Target

We are updating:

```txt
db/schema.ts
```

to add:

- `invoiceStatusEnum`
- `invoices`
- `invoiceLines`

---

## The Concept

Invoices belong to:

```txt
organization
customer
```

Invoice lines belong to:

```txt
invoice
organization
```

We store `organization_id` on invoice lines too because future report and diagnostic queries may need tenant filtering directly.

---

## The Implementation

Open:

```txt
db/schema.ts
```

Replace the full file with:

```ts
// db/schema.ts

import { sql } from "drizzle-orm";
import {
  bigint,
  boolean,
  check,
  date,
  index,
  integer,
  pgEnum,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from "drizzle-orm/pg-core";

export const accountTypeEnum = pgEnum("account_type", [
  "asset",
  "liability",
  "equity",
  "income",
  "expense",
]);

export const journalSourceTypeEnum = pgEnum("journal_source_type", [
  "manual",
  "invoice",
  "bill",
  "customer_payment",
  "vendor_payment",
  "bank_transaction",
  "system",
]);

export const invoiceStatusEnum = pgEnum("invoice_status", [
  "draft",
  "sent",
  "paid",
  "void",
]);

export const organizations = pgTable(
  "organizations",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    clerkOrganizationId: text("clerk_organization_id").notNull(),
    name: text("name").notNull(),
    slug: text("slug"),
    imageUrl: text("image_url"),
    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    uniqueIndex("organizations_clerk_organization_id_idx").on(
      table.clerkOrganizationId,
    ),
    index("organizations_slug_idx").on(table.slug),
  ],
);

export const accounts = pgTable(
  "accounts",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),
    code: text("code").notNull(),
    name: text("name").notNull(),
    type: accountTypeEnum("type").notNull(),
    description: text("description"),
    isSystem: boolean("is_system").default(false).notNull(),
    isActive: boolean("is_active").default(true).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    uniqueIndex("accounts_organization_id_code_idx").on(
      table.organizationId,
      table.code,
    ),
    index("accounts_organization_id_idx").on(table.organizationId),
    index("accounts_organization_id_type_idx").on(
      table.organizationId,
      table.type,
    ),
    index("accounts_organization_id_is_active_idx").on(
      table.organizationId,
      table.isActive,
    ),
  ],
);

export const customers = pgTable(
  "customers",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),
    name: text("name").notNull(),
    email: text("email"),
    phone: text("phone"),
    billingAddress: text("billing_address"),
    notes: text("notes"),
    isActive: boolean("is_active").default(true).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    index("customers_organization_id_idx").on(table.organizationId),
    index("customers_organization_id_is_active_idx").on(
      table.organizationId,
      table.isActive,
    ),
    index("customers_organization_id_name_idx").on(
      table.organizationId,
      table.name,
    ),
  ],
);

export const vendors = pgTable(
  "vendors",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),
    name: text("name").notNull(),
    email: text("email"),
    phone: text("phone"),
    billingAddress: text("billing_address"),
    notes: text("notes"),
    isActive: boolean("is_active").default(true).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    index("vendors_organization_id_idx").on(table.organizationId),
    index("vendors_organization_id_is_active_idx").on(
      table.organizationId,
      table.isActive,
    ),
    index("vendors_organization_id_name_idx").on(
      table.organizationId,
      table.name,
    ),
  ],
);

export const invoices = pgTable(
  "invoices",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),

    customerId: uuid("customer_id")
      .notNull()
      .references(() => customers.id, { onDelete: "restrict" }),

    invoiceNumber: text("invoice_number").notNull(),

    issueDate: date("issue_date").notNull(),

    dueDate: date("due_date").notNull(),

    status: invoiceStatusEnum("status").default("draft").notNull(),

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
    uniqueIndex("invoices_organization_id_invoice_number_idx").on(
      table.organizationId,
      table.invoiceNumber,
    ),
    index("invoices_organization_id_idx").on(table.organizationId),
    index("invoices_organization_id_customer_id_idx").on(
      table.organizationId,
      table.customerId,
    ),
    index("invoices_organization_id_status_idx").on(
      table.organizationId,
      table.status,
    ),
    check("invoices_subtotal_non_negative_check", sql`${table.subtotalCents} >= 0`),
    check("invoices_gst_non_negative_check", sql`${table.gstCents} >= 0`),
    check("invoices_total_non_negative_check", sql`${table.totalCents} >= 0`),
    check(
      "invoices_total_matches_components_check",
      sql`${table.totalCents} = ${table.subtotalCents} + ${table.gstCents}`,
    ),
  ],
);

export const invoiceLines = pgTable(
  "invoice_lines",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    invoiceId: uuid("invoice_id")
      .notNull()
      .references(() => invoices.id, { onDelete: "cascade" }),

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
    uniqueIndex("invoice_lines_invoice_id_line_number_idx").on(
      table.invoiceId,
      table.lineNumber,
    ),
    index("invoice_lines_organization_id_idx").on(table.organizationId),
    index("invoice_lines_invoice_id_idx").on(table.invoiceId),
    check("invoice_lines_quantity_positive_check", sql`${table.quantity} > 0`),
    check(
      "invoice_lines_unit_amount_non_negative_check",
      sql`${table.unitAmountCents} >= 0`,
    ),
    check(
      "invoice_lines_subtotal_non_negative_check",
      sql`${table.subtotalCents} >= 0`,
    ),
    check("invoice_lines_gst_non_negative_check", sql`${table.gstCents} >= 0`),
    check(
      "invoice_lines_total_non_negative_check",
      sql`${table.totalCents} >= 0`,
    ),
    check(
      "invoice_lines_total_matches_components_check",
      sql`${table.totalCents} = ${table.subtotalCents} + ${table.gstCents}`,
    ),
  ],
);

export const journalEntries = pgTable(
  "journal_entries",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),
    entryDate: date("entry_date").notNull(),
    memo: text("memo").notNull(),
    sourceType: journalSourceTypeEnum("source_type").default("manual").notNull(),
    sourceId: uuid("source_id"),
    postedByUserId: text("posted_by_user_id"),
    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    index("journal_entries_organization_id_entry_date_idx").on(
      table.organizationId,
      table.entryDate,
    ),
    index("journal_entries_organization_id_source_idx").on(
      table.organizationId,
      table.sourceType,
      table.sourceId,
    ),
  ],
);

export const journalLines = pgTable(
  "journal_lines",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    journalEntryId: uuid("journal_entry_id")
      .notNull()
      .references(() => journalEntries.id, { onDelete: "cascade" }),
    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),
    accountId: uuid("account_id")
      .notNull()
      .references(() => accounts.id, { onDelete: "restrict" }),
    lineNumber: integer("line_number").notNull(),
    description: text("description"),
    debitCents: bigint("debit_cents", { mode: "number" })
      .default(0)
      .notNull(),
    creditCents: bigint("credit_cents", { mode: "number" })
      .default(0)
      .notNull(),
    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    uniqueIndex("journal_lines_entry_id_line_number_idx").on(
      table.journalEntryId,
      table.lineNumber,
    ),
    index("journal_lines_organization_id_idx").on(table.organizationId),
    index("journal_lines_organization_id_account_id_idx").on(
      table.organizationId,
      table.accountId,
    ),
    index("journal_lines_journal_entry_id_idx").on(table.journalEntryId),
    check("journal_lines_debit_non_negative_check", sql`${table.debitCents} >= 0`),
    check(
      "journal_lines_credit_non_negative_check",
      sql`${table.creditCents} >= 0`,
    ),
    check(
      "journal_lines_exactly_one_side_check",
      sql`(
        (${table.debitCents} > 0 AND ${table.creditCents} = 0)
        OR
        (${table.creditCents} > 0 AND ${table.debitCents} = 0)
      )`,
    ),
  ],
);

export type Organization = typeof organizations.$inferSelect;
export type NewOrganization = typeof organizations.$inferInsert;

export type Account = typeof accounts.$inferSelect;
export type NewAccount = typeof accounts.$inferInsert;

export type Customer = typeof customers.$inferSelect;
export type NewCustomer = typeof customers.$inferInsert;

export type Vendor = typeof vendors.$inferSelect;
export type NewVendor = typeof vendors.$inferInsert;

export type Invoice = typeof invoices.$inferSelect;
export type NewInvoice = typeof invoices.$inferInsert;

export type InvoiceLine = typeof invoiceLines.$inferSelect;
export type NewInvoiceLine = typeof invoiceLines.$inferInsert;

export type JournalEntry = typeof journalEntries.$inferSelect;
export type NewJournalEntry = typeof journalEntries.$inferInsert;

export type JournalLine = typeof journalLines.$inferSelect;
export type NewJournalLine = typeof journalLines.$inferInsert;
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
invoice_lines
invoices
```

---

# 6. Create Invoice Query Services

## The Target

We are creating:

```txt
services/invoices/invoice-services.ts
```

---

## The Concept

For now, invoices are mostly diagnostic.

In Part 18, we will add creation and journal posting.

---

## The Implementation

Create:

```bash
mkdir -p services/invoices
```

Create:

```txt
services/invoices/invoice-services.ts
```

Add:

```ts
// services/invoices/invoice-services.ts

import { count, desc, eq } from "drizzle-orm";
import { db } from "@/db";
import { customers, invoiceLines, invoices } from "@/db/schema";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

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
  const organization = await getOrCreateCurrentOrganization();

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

---

# 7. Update Database Health

## The Target

We are updating:

```txt
lib/database-health.ts
```

to include invoice counts.

---

## The Implementation

Open:

```txt
lib/database-health.ts
```

Replace it with:

```ts
// lib/database-health.ts

import { count } from "drizzle-orm";
import { db } from "@/db";
import {
  accounts,
  customers,
  invoiceLines,
  invoices,
  journalEntries,
  journalLines,
  organizations,
  vendors,
} from "@/db/schema";

export type DatabaseHealthResult =
  | {
      ok: true;
      latencyMs: number;
      organizationCount: number;
      accountCount: number;
      customerCount: number;
      vendorCount: number;
      invoiceCount: number;
      invoiceLineCount: number;
      journalEntryCount: number;
      journalLineCount: number;
    }
  | {
      ok: false;
      latencyMs: number;
      errorMessage: string;
    };

export async function getDatabaseHealth(): Promise<DatabaseHealthResult> {
  const startedAt = Date.now();

  try {
    const [organizationRow] = await db
      .select({ value: count() })
      .from(organizations);

    const [accountRow] = await db.select({ value: count() }).from(accounts);
    const [customerRow] = await db.select({ value: count() }).from(customers);
    const [vendorRow] = await db.select({ value: count() }).from(vendors);
    const [invoiceRow] = await db.select({ value: count() }).from(invoices);

    const [invoiceLineRow] = await db
      .select({ value: count() })
      .from(invoiceLines);

    const [journalEntryRow] = await db
      .select({ value: count() })
      .from(journalEntries);

    const [journalLineRow] = await db
      .select({ value: count() })
      .from(journalLines);

    return {
      ok: true,
      latencyMs: Date.now() - startedAt,
      organizationCount: organizationRow?.value ?? 0,
      accountCount: accountRow?.value ?? 0,
      customerCount: customerRow?.value ?? 0,
      vendorCount: vendorRow?.value ?? 0,
      invoiceCount: invoiceRow?.value ?? 0,
      invoiceLineCount: invoiceLineRow?.value ?? 0,
      journalEntryCount: journalEntryRow?.value ?? 0,
      journalLineCount: journalLineRow?.value ?? 0,
    };
  } catch (error) {
    return {
      ok: false,
      latencyMs: Date.now() - startedAt,
      errorMessage:
        error instanceof Error
          ? error.message
          : "Unknown database connection error.",
    };
  }
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 8. Create Invoice Database Diagnostic Page

## The Target

We are creating:

```txt
app/settings/database/invoices/page.tsx
```

---

## The Implementation

Create:

```bash
mkdir -p app/settings/database/invoices
```

Create:

```txt
app/settings/database/invoices/page.tsx
```

Add:

```tsx
// app/settings/database/invoices/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { formatMoney } from "@/lib/money";
import { getCurrentOrganizationInvoiceDiagnostics } from "@/services/invoices/invoice-services";

export const dynamic = "force-dynamic";

export default async function DatabaseInvoicesPage() {
  const diagnostics = await getCurrentOrganizationInvoiceDiagnostics();

  return (
    <AppLayout
      title="Database Invoices"
      description="Inspect invoice and invoice line table readiness for the active organization."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-sky-600">
              Invoice schema
            </p>

            <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
              Invoice database readiness
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
              This page confirms that invoice tables exist and can be queried.
              In Part 18, we will create invoices and post them to the journal.
            </p>
          </div>

          <Link
            href="/invoices"
            className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
          >
            Open invoices
          </Link>
        </div>

        {diagnostics.organizationId ? (
          <div className="mt-6 grid gap-4 md:grid-cols-3">
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 md:col-span-3">
              <p className="text-sm font-semibold text-slate-700">
                Active database organization ID
              </p>
              <p className="mt-1 break-all font-mono text-xs text-slate-500">
                {diagnostics.organizationId}
              </p>
            </div>

            <div className="rounded-xl bg-sky-50 p-4">
              <p className="text-sm font-semibold text-sky-700">Invoices</p>
              <p className="mt-2 text-3xl font-bold text-sky-900">
                {diagnostics.invoiceCount}
              </p>
            </div>

            <div className="rounded-xl bg-emerald-50 p-4">
              <p className="text-sm font-semibold text-emerald-700">
                Invoice lines
              </p>
              <p className="mt-2 text-3xl font-bold text-emerald-900">
                {diagnostics.invoiceLineCount}
              </p>
            </div>

            <div className="rounded-xl bg-amber-50 p-4">
              <p className="text-sm font-semibold text-amber-700">
                Expected status
              </p>
              <p className="mt-2 text-sm leading-6 text-amber-800">
                Zero rows is normal until invoice creation is added in Part 18.
              </p>
            </div>
          </div>
        ) : (
          <div className="mt-6 rounded-2xl border border-amber-200 bg-amber-50 p-5">
            <p className="text-sm font-semibold text-amber-800">
              No active organization selected.
            </p>

            <Link
              href="/onboarding/organization"
              className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white"
            >
              Create company workspace
            </Link>
          </div>
        )}

        {diagnostics.recentInvoices.length > 0 ? (
          <div className="mt-6 overflow-hidden rounded-xl border border-slate-200">
            <table className="w-full border-collapse text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-semibold">Invoice</th>
                  <th className="px-4 py-3 font-semibold">Customer</th>
                  <th className="px-4 py-3 font-semibold">Status</th>
                  <th className="px-4 py-3 text-right font-semibold">
                    Subtotal
                  </th>
                  <th className="px-4 py-3 text-right font-semibold">GST</th>
                  <th className="px-4 py-3 text-right font-semibold">Total</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-200">
                {diagnostics.recentInvoices.map((invoice) => (
                  <tr key={invoice.id}>
                    <td className="px-4 py-3 font-semibold text-slate-950">
                      {invoice.invoiceNumber}
                    </td>
                    <td className="px-4 py-3 text-slate-600">
                      {invoice.customerName}
                    </td>
                    <td className="px-4 py-3 text-slate-600">
                      {invoice.status}
                    </td>
                    <td className="px-4 py-3 text-right">
                      {formatMoney(invoice.subtotalCents)}
                    </td>
                    <td className="px-4 py-3 text-right">
                      {formatMoney(invoice.gstCents)}
                    </td>
                    <td className="px-4 py-3 text-right font-semibold">
                      {formatMoney(invoice.totalCents)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : diagnostics.organizationId ? (
          <div className="mt-6 rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
            <h3 className="text-lg font-semibold text-slate-950">
              No invoices yet
            </h3>
            <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
              This is expected at the end of Part 17.
            </p>
          </div>
        ) : null}
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/settings/database/invoices
```

You should see invoice counts, usually zero.

---

# 9. Update the Invoices Page

## The Target

We are updating:

```txt
app/invoices/page.tsx
```

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
import { EmptyState } from "@/components/empty-state";
import { getCurrentOrganizationInvoiceDiagnostics } from "@/services/invoices/invoice-services";

export const dynamic = "force-dynamic";

export default async function InvoicesPage() {
  const diagnostics = await getCurrentOrganizationInvoiceDiagnostics();

  return (
    <AppLayout
      title="Invoices"
      description="Invoices record sales to customers and create accounts receivable when posted."
    >
      <div className="space-y-6">
        <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-700">
            Schema ready
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            Invoice tables and GST logic now exist
          </h2>

          <p className="mt-2 max-w-3xl text-sm leading-6 text-emerald-800">
            In Part 18, we will create GST-aware invoices and post the resulting
            accounting entry to the journal.
          </p>

          <div className="mt-4 flex flex-wrap gap-2">
            <Link
              href="/settings/database/invoices"
              className="rounded-xl bg-emerald-700 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-emerald-800"
            >
              View invoice diagnostics
            </Link>

            <Link
              href="/customers"
              className="rounded-xl border border-emerald-300 bg-white/70 px-4 py-2 text-sm font-semibold text-emerald-800 shadow-sm transition hover:bg-white"
            >
              Manage customers
            </Link>
          </div>
        </section>

        <section className="grid gap-4 md:grid-cols-2">
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold text-slate-500">Invoices</p>
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
        </section>

        <EmptyState
          title="GST-aware invoice creation coming next"
          description="The invoice database schema is ready. In Part 18, we will create invoices, calculate GST, and post balanced journal entries."
        />
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

You should see:

```txt
Schema ready
Invoice tables and GST logic now exist
```

---

# 10. Update Settings Page Links

## The Target

We are updating:

```txt
app/settings/page.tsx
```

to include invoice diagnostics.

---

## The Implementation

Open:

```txt
app/settings/page.tsx
```

In the `settingsCards` array, add:

```ts
{
  eyebrow: "Invoices",
  title: "Database invoices",
  description:
    "Inspect invoice and invoice line table readiness for the active organization.",
  href: "/settings/database/invoices",
},
```

Your full `settingsCards` array should include this new card alongside the existing auth, database, accounts, and journal cards.

---

## The Verification

Open:

```txt
http://localhost:3000/settings
```

You should see:

```txt
Database invoices
```

---

# 11. Verify Database Constraints

## The Target

We are checking invoice constraints in Neon.

---

## The Implementation

Open Neon SQL editor.

Run:

```sql
select
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
from pg_constraint
where conrelid in ('invoices'::regclass, 'invoice_lines'::regclass)
order by conname;
```

Also inspect indexes:

```sql
select
  indexname,
  indexdef
from pg_indexes
where tablename in ('invoices', 'invoice_lines')
order by tablename, indexname;
```

---

## The Verification

You should see constraints such as:

```txt
invoices_total_matches_components_check
invoice_lines_total_matches_components_check
invoice_lines_quantity_positive_check
```

---

# 12. Run Full Project Check

## The Target

We are verifying schema, tests, and build.

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

# 13. Commit Invoice Schema and GST Logic

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Add invoice tables and GST logic"
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

## Error: `relation "invoices" does not exist`

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: GST test fails on rounding

Check:

```txt
lib/accounting/gst.ts
```

The GST calculation should use:

```ts
Math.round((subtotalCents * gstRateBasisPoints) / 10000)
```

---

## Error: Database health page fails

Make sure `lib/database-health.ts` imports:

```ts
invoices
invoiceLines
```

from:

```txt
@/db/schema
```

Then make sure the migration is applied.

---

## Error: TypeScript says `journalEntries` is used before declaration

If your TypeScript version complains because `invoices` references `journalEntries` before it is declared, move the `journalEntries` and `journalLines` table definitions above the `invoices` table.

The tutorial schema keeps all definitions in one file. The key rule is:

```txt
A referenced table must be in scope at runtime.
```

If needed, reorder:

```txt
organizations
accounts
customers
vendors
journalEntries
journalLines
invoices
invoiceLines
```

and regenerate the migration.

---

# Phase 6 Reference — Invoice Schema Vocabulary

## Invoice

A document sent to a customer requesting payment.

---

## Invoice Line

A billed item or service inside an invoice.

---

## GST Rate Basis Points

A whole-number representation of tax rate.

```txt
9% = 900
```

---

## Tax-Exclusive Amount

An amount before GST.

Example:

```txt
Subtotal S$100
GST S$9
Total S$109
```

---

## Invoice Status

We created:

```txt
draft
sent
paid
void
```

Later workflow rules will decide when status changes.

---

# Part 17 Completion Checklist

You are ready for Part 18 if:

- [ ] `lib/accounting/gst.ts` exists
- [ ] GST calculations use integer cents and basis points
- [ ] `tests/gst.test.ts` passes
- [ ] `invoiceStatusEnum` exists
- [ ] `invoices` table exists
- [ ] `invoice_lines` table exists
- [ ] Invoice totals have database checks
- [ ] Invoice lines have quantity and total checks
- [ ] `services/invoices/invoice-services.ts` exists
- [ ] `/settings/database/invoices` loads
- [ ] `/invoices` shows schema-ready state
- [ ] Neon shows invoice tables and constraints
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
