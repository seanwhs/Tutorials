# Part 16 — Build Customers and Vendors

In Phase 5, we built the journal foundation.

Now we start adding business contacts.

Before we can create invoices, we need customers.

Before we can create bills, we need vendors.

By the end of this part, you will have:

- A `customers` table
- A `vendors` table
- Tenant-scoped customer and vendor data
- Server-side create actions
- Server-side validation
- Customer list page
- Vendor list page
- Customer and vendor diagnostic counts
- Updated database health output
- Neon SQL verification queries

We will not create invoices or bills yet. Those come next.

---

# 1. Understand Customers and Vendors

## The Target

We are adding two business contact types:

```txt
Customers = people or companies that buy from us
Vendors   = people or companies we buy from
```

---

## The Concept

Think of GreyMatter Ledger as a business notebook.

Customers are written in the “people who owe us money” section.

Vendors are written in the “people we may owe money to” section.

In accounting terms:

```txt
Customers connect to Accounts Receivable.
Vendors connect to Accounts Payable.
```

Later:

```txt
Invoice -> Customer -> Accounts Receivable
Bill    -> Vendor   -> Accounts Payable
```

---

## The Implementation

We will create:

```txt
customers
vendors
```

Each row belongs to one organization:

```txt
customers.organization_id
vendors.organization_id
```

That keeps company data isolated.

---

## The Verification

At the end, these pages should work:

```txt
/customers
/vendors
/settings/database
```

---

# 2. Update the Database Schema

## The Target

We are updating:

```txt
db/schema.ts
```

to add `customers` and `vendors`.

---

## The Concept

Customers and vendors are tenant-scoped master data.

“Master data” means reusable business records that other workflows refer to.

For example, one customer may have many invoices.

So later the relationship will be:

```txt
customers
  |
  |-- invoices
```

And:

```txt
vendors
  |
  |-- bills
```

---

## The Implementation

Open:

```txt
db/schema.ts
```

Replace the file with this full version.

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
      .references(() => organizations.id, {
        onDelete: "cascade",
      }),
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

/**
 * customers
 *
 * People or organizations that buy from the company.
 */
export const customers = pgTable(
  "customers",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, {
        onDelete: "cascade",
      }),

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

/**
 * vendors
 *
 * People or organizations the company buys from.
 */
export const vendors = pgTable(
  "vendors",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, {
        onDelete: "cascade",
      }),

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

export const journalEntries = pgTable(
  "journal_entries",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, {
        onDelete: "cascade",
      }),
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
      .references(() => journalEntries.id, {
        onDelete: "cascade",
      }),
    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, {
        onDelete: "cascade",
      }),
    accountId: uuid("account_id")
      .notNull()
      .references(() => accounts.id, {
        onDelete: "restrict",
      }),
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

export type JournalEntry = typeof journalEntries.$inferSelect;
export type NewJournalEntry = typeof journalEntries.$inferInsert;

export type JournalLine = typeof journalLines.$inferSelect;
export type NewJournalLine = typeof journalLines.$inferInsert;
```

---

## The Verification

Generate a migration:

```bash
pnpm db:generate
```

Apply it:

```bash
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
customers
vendors
```

---

# 3. Update Database Health

## The Target

We are updating:

```txt
lib/database-health.ts
```

to include customer and vendor counts.

---

## The Concept

Our health page should confirm that new tables are queryable.

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

The build should succeed.

---

# 4. Create Shared Contact Validation Helpers

## The Target

We are creating:

```txt
lib/contacts/validation.ts
```

---

## The Concept

Customers and vendors share similar fields.

Instead of duplicating validation logic, we create one helper.

This is like having one checklist for “business contact details.”

---

## The Implementation

Create the folder:

```bash
mkdir -p lib/contacts
```

Create:

```txt
lib/contacts/validation.ts
```

Add:

```ts
// lib/contacts/validation.ts

export type ContactInput = {
  name: string;
  email?: string | null;
  phone?: string | null;
  billingAddress?: string | null;
  notes?: string | null;
};

export type NormalizedContactInput = {
  name: string;
  email: string | null;
  phone: string | null;
  billingAddress: string | null;
  notes: string | null;
};

function normalizeOptionalText(value?: string | null): string | null {
  const normalized = value?.trim() ?? "";
  return normalized.length > 0 ? normalized : null;
}

export function normalizeContactInput(
  input: ContactInput,
): NormalizedContactInput {
  return {
    name: input.name.trim(),
    email: normalizeOptionalText(input.email),
    phone: normalizeOptionalText(input.phone),
    billingAddress: normalizeOptionalText(input.billingAddress),
    notes: normalizeOptionalText(input.notes),
  };
}

export function validateContactInput(input: NormalizedContactInput): string[] {
  const issues: string[] = [];

  if (!input.name) {
    issues.push("Name is required.");
  }

  if (input.name.length > 160) {
    issues.push("Name must be 160 characters or fewer.");
  }

  if (input.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.email)) {
    issues.push("Email address is invalid.");
  }

  if (input.email && input.email.length > 254) {
    issues.push("Email address must be 254 characters or fewer.");
  }

  if (input.phone && input.phone.length > 50) {
    issues.push("Phone number must be 50 characters or fewer.");
  }

  if (input.billingAddress && input.billingAddress.length > 1000) {
    issues.push("Billing address must be 1000 characters or fewer.");
  }

  if (input.notes && input.notes.length > 1000) {
    issues.push("Notes must be 1000 characters or fewer.");
  }

  return issues;
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Create Customer Services

## The Target

We are creating:

```txt
services/customers/customer-services.ts
```

---

## The Concept

This service owns customer database logic.

The UI should not directly insert customer rows.

---

## The Implementation

Create:

```bash
mkdir -p services/customers
```

Create:

```txt
services/customers/customer-services.ts
```

Add:

```ts
// services/customers/customer-services.ts

import { asc, eq } from "drizzle-orm";
import { db } from "@/db";
import { customers, type Customer } from "@/db/schema";
import {
  normalizeContactInput,
  type ContactInput,
  validateContactInput,
} from "@/lib/contacts/validation";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type ContactMutationResult =
  | {
      ok: true;
      record: Customer;
    }
  | {
      ok: false;
      error: string;
    };

export async function listCurrentOrganizationCustomers(): Promise<{
  organizationId: string | null;
  customers: Customer[];
}> {
  const organization = await requireCurrentDatabaseOrganization().catch(
    () => null,
  );

  if (!organization) {
    return {
      organizationId: null,
      customers: [],
    };
  }

  const rows = await db
    .select()
    .from(customers)
    .where(eq(customers.organizationId, organization.id))
    .orderBy(asc(customers.name));

  return {
    organizationId: organization.id,
    customers: rows,
  };
}

export async function createCustomerForCurrentOrganization(
  input: ContactInput,
): Promise<ContactMutationResult> {
  const organization = await requireCurrentDatabaseOrganization();
  const normalized = normalizeContactInput(input);
  const issues = validateContactInput(normalized);

  if (issues.length > 0) {
    return {
      ok: false,
      error: issues.join(" "),
    };
  }

  const now = new Date();

  const [created] = await db
    .insert(customers)
    .values({
      organizationId: organization.id,
      name: normalized.name,
      email: normalized.email,
      phone: normalized.phone,
      billingAddress: normalized.billingAddress,
      notes: normalized.notes,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    })
    .returning();

  if (!created) {
    return {
      ok: false,
      error: "Customer could not be created.",
    };
  }

  return {
    ok: true,
    record: created,
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

# 6. Create Vendor Services

## The Target

We are creating:

```txt
services/vendors/vendor-services.ts
```

---

## The Concept

Vendors mirror customers, but they support purchasing workflows.

Later:

```txt
Vendor -> Bill -> Accounts Payable
```

---

## The Implementation

Create:

```bash
mkdir -p services/vendors
```

Create:

```txt
services/vendors/vendor-services.ts
```

Add:

```ts
// services/vendors/vendor-services.ts

import { asc, eq } from "drizzle-orm";
import { db } from "@/db";
import { vendors, type Vendor } from "@/db/schema";
import {
  normalizeContactInput,
  type ContactInput,
  validateContactInput,
} from "@/lib/contacts/validation";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type VendorMutationResult =
  | {
      ok: true;
      record: Vendor;
    }
  | {
      ok: false;
      error: string;
    };

export async function listCurrentOrganizationVendors(): Promise<{
  organizationId: string | null;
  vendors: Vendor[];
}> {
  const organization = await requireCurrentDatabaseOrganization().catch(
    () => null,
  );

  if (!organization) {
    return {
      organizationId: null,
      vendors: [],
    };
  }

  const rows = await db
    .select()
    .from(vendors)
    .where(eq(vendors.organizationId, organization.id))
    .orderBy(asc(vendors.name));

  return {
    organizationId: organization.id,
    vendors: rows,
  };
}

export async function createVendorForCurrentOrganization(
  input: ContactInput,
): Promise<VendorMutationResult> {
  const organization = await requireCurrentDatabaseOrganization();
  const normalized = normalizeContactInput(input);
  const issues = validateContactInput(normalized);

  if (issues.length > 0) {
    return {
      ok: false,
      error: issues.join(" "),
    };
  }

  const now = new Date();

  const [created] = await db
    .insert(vendors)
    .values({
      organizationId: organization.id,
      name: normalized.name,
      email: normalized.email,
      phone: normalized.phone,
      billingAddress: normalized.billingAddress,
      notes: normalized.notes,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    })
    .returning();

  if (!created) {
    return {
      ok: false,
      error: "Vendor could not be created.",
    };
  }

  return {
    ok: true,
    record: created,
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

# 7. Create Customer Server Actions

## The Target

We are creating:

```txt
app/customers/actions.ts
```

---

## The Concept

The form submits to a server action.

The action calls the service.

The service writes to the database.

---

## The Implementation

Create:

```txt
app/customers/actions.ts
```

Add:

```ts
// app/customers/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createCustomerForCurrentOrganization } from "@/services/customers/customer-services";

export async function createCustomerAction(formData: FormData) {
  const result = await createCustomerForCurrentOrganization({
    name: String(formData.get("name") ?? ""),
    email: String(formData.get("email") ?? ""),
    phone: String(formData.get("phone") ?? ""),
    billingAddress: String(formData.get("billingAddress") ?? ""),
    notes: String(formData.get("notes") ?? ""),
  });

  revalidatePath("/customers");
  revalidatePath("/settings/database");

  if (!result.ok) {
    redirect(`/customers?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect("/customers?status=created");
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 8. Create Vendor Server Actions

## The Target

We are creating:

```txt
app/vendors/actions.ts
```

---

## The Implementation

Create:

```txt
app/vendors/actions.ts
```

Add:

```ts
// app/vendors/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createVendorForCurrentOrganization } from "@/services/vendors/vendor-services";

export async function createVendorAction(formData: FormData) {
  const result = await createVendorForCurrentOrganization({
    name: String(formData.get("name") ?? ""),
    email: String(formData.get("email") ?? ""),
    phone: String(formData.get("phone") ?? ""),
    billingAddress: String(formData.get("billingAddress") ?? ""),
    notes: String(formData.get("notes") ?? ""),
  });

  revalidatePath("/vendors");
  revalidatePath("/settings/database");

  if (!result.ok) {
    redirect(`/vendors?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect("/vendors?status=created");
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 9. Create a Reusable Contact Form Component

## The Target

We are creating:

```txt
components/contact-create-form.tsx
```

---

## The Concept

Customer and vendor forms are almost identical.

A reusable form prevents copy-paste UI.

---

## The Implementation

Create:

```txt
components/contact-create-form.tsx
```

Add:

```tsx
// components/contact-create-form.tsx

type ContactCreateFormProps = {
  title: string;
  description: string;
  submitLabel: string;
  action: (formData: FormData) => void | Promise<void>;
};

export function ContactCreateForm({
  title,
  description,
  submitLabel,
  action,
}: ContactCreateFormProps) {
  return (
    <form
      action={action}
      className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
    >
      <div>
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
          New contact
        </p>

        <h2 className="mt-3 text-lg font-semibold text-slate-950">{title}</h2>

        <p className="mt-2 text-sm leading-6 text-slate-500">{description}</p>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-2">
        <label className="block">
          <span className="text-sm font-semibold text-slate-700">Name</span>
          <input
            name="name"
            required
            maxLength={160}
            placeholder="Example Pte. Ltd."
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-slate-700">Email</span>
          <input
            name="email"
            type="email"
            maxLength={254}
            placeholder="finance@example.com"
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-slate-700">Phone</span>
          <input
            name="phone"
            maxLength={50}
            placeholder="+65 6123 4567"
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-slate-700">
            Billing address
          </span>
          <input
            name="billingAddress"
            maxLength={1000}
            placeholder="Singapore business address"
            className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
          />
        </label>
      </div>

      <label className="mt-4 block">
        <span className="text-sm font-semibold text-slate-700">Notes</span>
        <textarea
          name="notes"
          rows={3}
          maxLength={1000}
          placeholder="Optional internal notes."
          className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
        />
      </label>

      <div className="mt-5 flex justify-end">
        <button
          type="submit"
          className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
        >
          {submitLabel}
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

# 10. Create a Contact Status Banner

## The Target

We are creating:

```txt
components/contact-status-banner.tsx
```

---

## The Implementation

Create:

```txt
components/contact-status-banner.tsx
```

Add:

```tsx
// components/contact-status-banner.tsx

type ContactStatusBannerProps = {
  status?: string;
  message?: string;
  noun: "customer" | "vendor";
};

export function ContactStatusBanner({
  status,
  message,
  noun,
}: ContactStatusBannerProps) {
  if (!status) {
    return null;
  }

  if (status === "created") {
    return (
      <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
        <p className="text-sm font-semibold">
          {noun === "customer" ? "Customer" : "Vendor"} created successfully.
        </p>
      </section>
    );
  }

  if (status === "error") {
    return (
      <section className="rounded-2xl border border-rose-200 bg-rose-50 p-5 text-rose-800">
        <p className="text-sm font-semibold">
          {noun === "customer" ? "Customer" : "Vendor"} could not be created.
        </p>

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

# 11. Create a Reusable Contact Table

## The Target

We are creating:

```txt
components/contact-table.tsx
```

---

## The Implementation

Create:

```txt
components/contact-table.tsx
```

Add:

```tsx
// components/contact-table.tsx

type ContactRow = {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  billingAddress: string | null;
  notes: string | null;
  isActive: boolean;
};

type ContactTableProps = {
  rows: ContactRow[];
  emptyTitle: string;
  emptyDescription: string;
};

export function ContactTable({
  rows,
  emptyTitle,
  emptyDescription,
}: ContactTableProps) {
  if (rows.length === 0) {
    return (
      <section className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
        <h2 className="text-lg font-semibold text-slate-950">{emptyTitle}</h2>
        <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
          {emptyDescription}
        </p>
      </section>
    );
  }

  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
        <h2 className="text-lg font-semibold text-slate-950">
          {rows.length} contact{rows.length === 1 ? "" : "s"}
        </h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-left text-sm">
          <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
            <tr>
              <th className="px-6 py-3 font-semibold">Name</th>
              <th className="px-6 py-3 font-semibold">Email</th>
              <th className="px-6 py-3 font-semibold">Phone</th>
              <th className="px-6 py-3 font-semibold">Address</th>
              <th className="px-6 py-3 font-semibold">Status</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-slate-200">
            {rows.map((row) => (
              <tr key={row.id}>
                <td className="px-6 py-4">
                  <div className="font-semibold text-slate-950">{row.name}</div>
                  {row.notes ? (
                    <div className="mt-1 text-xs leading-5 text-slate-500">
                      {row.notes}
                    </div>
                  ) : null}
                </td>

                <td className="px-6 py-4 text-slate-600">
                  {row.email ?? "—"}
                </td>

                <td className="px-6 py-4 text-slate-600">
                  {row.phone ?? "—"}
                </td>

                <td className="max-w-md px-6 py-4 text-slate-600">
                  {row.billingAddress ?? "—"}
                </td>

                <td className="px-6 py-4">
                  {row.isActive ? (
                    <span className="rounded-full bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700">
                      Active
                    </span>
                  ) : (
                    <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-600">
                      Inactive
                    </span>
                  )}
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

---

# 12. Build the Customers Page

## The Target

We are replacing:

```txt
app/customers/page.tsx
```

---

## The Implementation

Open:

```txt
app/customers/page.tsx
```

Replace it with:

```tsx
// app/customers/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { ContactCreateForm } from "@/components/contact-create-form";
import { ContactStatusBanner } from "@/components/contact-status-banner";
import { ContactTable } from "@/components/contact-table";
import { createCustomerAction } from "@/app/customers/actions";
import { listCurrentOrganizationCustomers } from "@/services/customers/customer-services";

export const dynamic = "force-dynamic";

type CustomersPageProps = {
  searchParams?: Promise<{
    status?: string;
    message?: string;
  }>;
};

export default async function CustomersPage({
  searchParams,
}: CustomersPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const { organizationId, customers } = await listCurrentOrganizationCustomers();

  return (
    <AppLayout
      title="Customers"
      description="Customers are people or businesses that buy from your company."
    >
      <div className="space-y-6">
        <ContactStatusBanner
          noun="customer"
          status={resolvedSearchParams.status}
          message={resolvedSearchParams.message}
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
            <ContactCreateForm
              title="Add customer"
              description="Create a customer record before issuing invoices."
              submitLabel="Create customer"
              action={createCustomerAction}
            />

            <ContactTable
              rows={customers}
              emptyTitle="No customers yet"
              emptyDescription="Create your first customer before building GST-aware invoices in the next parts."
            />
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
http://localhost:3000/customers
```

Create:

```txt
Name: Merlion Trading Pte. Ltd.
Email: accounts@merlion.example
Phone: +65 6123 4567
Billing address: 1 Raffles Place, Singapore
Notes: Demo customer for invoices.
```

You should see the customer appear in the table.

---

# 13. Build the Vendors Page

## The Target

We are replacing:

```txt
app/vendors/page.tsx
```

---

## The Implementation

Open:

```txt
app/vendors/page.tsx
```

Replace it with:

```tsx
// app/vendors/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { ContactCreateForm } from "@/components/contact-create-form";
import { ContactStatusBanner } from "@/components/contact-status-banner";
import { ContactTable } from "@/components/contact-table";
import { createVendorAction } from "@/app/vendors/actions";
import { listCurrentOrganizationVendors } from "@/services/vendors/vendor-services";

export const dynamic = "force-dynamic";

type VendorsPageProps = {
  searchParams?: Promise<{
    status?: string;
    message?: string;
  }>;
};

export default async function VendorsPage({ searchParams }: VendorsPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const { organizationId, vendors } = await listCurrentOrganizationVendors();

  return (
    <AppLayout
      title="Vendors"
      description="Vendors are people or businesses your company buys from."
    >
      <div className="space-y-6">
        <ContactStatusBanner
          noun="vendor"
          status={resolvedSearchParams.status}
          message={resolvedSearchParams.message}
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
            <ContactCreateForm
              title="Add vendor"
              description="Create a vendor record before entering supplier bills."
              submitLabel="Create vendor"
              action={createVendorAction}
            />

            <ContactTable
              rows={vendors}
              emptyTitle="No vendors yet"
              emptyDescription="Create your first vendor before building bill and accounts payable workflows."
            />
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
http://localhost:3000/vendors
```

Create:

```txt
Name: Cloud Hosting SG
Email: billing@cloudhosting.example
Phone: +65 6234 5678
Billing address: Singapore
Notes: Demo vendor for bills.
```

You should see the vendor appear in the table.

---

# 14. Update Database Status Page

## The Target

We are updating:

```txt
app/settings/database/page.tsx
```

to show customer and vendor counts.

---

## The Implementation

Open:

```txt
app/settings/database/page.tsx
```

Find the `<dl>` section where counts are shown.

After the account row block, add these two blocks:

```tsx
<div className="grid gap-1 bg-slate-50 px-4 py-3 sm:grid-cols-3">
  <dt className="text-sm font-semibold text-slate-600">Customer rows</dt>
  <dd className="text-sm text-slate-950 sm:col-span-2">
    {health.customerCount}
  </dd>
</div>

<div className="grid gap-1 bg-white px-4 py-3 sm:grid-cols-3">
  <dt className="text-sm font-semibold text-slate-600">Vendor rows</dt>
  <dd className="text-sm text-slate-950 sm:col-span-2">
    {health.vendorCount}
  </dd>
</div>
```

Because this page is already large, do not change anything else.

---

## The Verification

Open:

```txt
http://localhost:3000/settings/database
```

You should see:

```txt
Customer rows
Vendor rows
```

---

# 15. Verify in Neon SQL

## The Target

We are confirming database rows directly.

---

## The Implementation

Run:

```sql
select
  o.name as organization_name,
  c.name as customer_name,
  c.email,
  c.is_active
from customers c
join organizations o
  on o.id = c.organization_id
order by c.created_at desc;
```

Run:

```sql
select
  o.name as organization_name,
  v.name as vendor_name,
  v.email,
  v.is_active
from vendors v
join organizations o
  on o.id = v.organization_id
order by v.created_at desc;
```

---

## The Verification

You should see the customer and vendor you created.

---

# 16. Run the Full Health Check

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

# 17. Commit Customers and Vendors

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Build customers and vendors"
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

## Error: `relation "customers" does not exist`

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Customer or vendor page says no active organization

Create or select an organization:

```txt
/onboarding/organization
```

Then reload:

```txt
/customers
```

---

## Error: Invalid email

Use a valid email shape:

```txt
name@example.com
```

---

## Error: Database health page fails after schema change

Make sure the migration has been applied:

```bash
pnpm db:migrate
```

---

# Phase 6 Reference — Customers and Vendors

## Customer

A customer buys from your company.

Customers will connect to invoices and accounts receivable.

---

## Vendor

A vendor sells to your company.

Vendors will connect to bills and accounts payable.

---

## Tenant Scoped Contacts

Every contact belongs to one organization.

That means Company A customers never mix with Company B customers.

---

# Part 16 Completion Checklist

You are ready for Part 17 if:

- [ ] `customers` table exists
- [ ] `vendors` table exists
- [ ] Customers are scoped by organization
- [ ] Vendors are scoped by organization
- [ ] Customer creation works
- [ ] Vendor creation works
- [ ] `/customers` lists customer rows
- [ ] `/vendors` lists vendor rows
- [ ] Database health shows customer and vendor counts
- [ ] Neon SQL confirms records
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
