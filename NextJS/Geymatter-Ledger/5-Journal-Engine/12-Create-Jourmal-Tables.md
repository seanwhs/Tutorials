# Part 12 — Create Journal Entry Tables `journal_entries` + `journal_lines`

In Phase 4, we built the chart of accounts.

Now we start building the heart of GreyMatter Ledger:

```txt
The journal.
```

The journal is the accounting source of truth.

Every serious accounting workflow eventually posts to the journal:

```txt
Invoice issued
Bill received
Customer payment received
Vendor payment made
Bank transaction categorized
Manual adjustment posted
Reversal created
```

In this part, we will create the database tables that store journal entries and journal lines.

By the end of this part, you will have:

- A `journal_entries` table
- A `journal_lines` table
- Foreign keys to organizations and accounts
- Database checks that prevent negative debit/credit amounts
- Database checks that prevent one line from having both debit and credit
- Tenant-scoped journal diagnostics
- Updated database health checks
- A protected journal database diagnostic page
- A generated and applied Drizzle migration

We will **not** build the full `postJournalEntry()` function yet.

That comes in **Part 13**.

This part builds the database structure the journal engine will write into.

---

# 1. Understand the Journal Data Model

## The Target

We are designing two tables:

```txt
journal_entries
journal_lines
```

---

## The Concept

A journal entry is the header.

Journal lines are the accounting movements inside that header.

A useful analogy:

```txt
Journal entry = receipt envelope
Journal lines = receipts inside the envelope
```

For example, a GST invoice for S$109.00 might be stored as:

```txt
journal_entries
  id: entry_123
  date: 2026-01-05
  memo: Invoice INV-0001

journal_lines
  Debit  Accounts Receivable  S$109.00
  Credit Sales Revenue        S$100.00
  Credit GST Payable          S$9.00
```

The journal entry itself says:

```txt
What event happened?
When did it happen?
Which company owns it?
```

The journal lines say:

```txt
Which accounts changed?
Was each change a debit or a credit?
How much?
```

---

## The Implementation

The database relationship will look like this:

```txt
organizations
  |
  |-- journal_entries
        |
        |-- journal_lines
              |
              |-- accounts
```

Each journal entry belongs to one organization.

Each journal line belongs to:

- One journal entry
- One organization
- One account

We store `organization_id` on both `journal_entries` and `journal_lines`.

Why store it on lines too?

Because reports usually query journal lines directly.

For example:

```txt
Profit & Loss report
Balance Sheet report
GST report
```

Those reports will need to filter lines by organization quickly.

So this design makes reporting safer and faster.

---

## The Verification

At the end of this part, Neon should show these tables:

```txt
organizations
accounts
journal_entries
journal_lines
```

And this query should work:

```sql
select *
from journal_entries;
```

It should return zero rows for now.

That is correct.

---

# 2. Design `journal_entries`

## The Target

We are deciding the columns for:

```txt
journal_entries
```

---

## The Concept

A journal entry is the header for an accounting event.

It should include:

| Column | Purpose |
|---|---|
| `id` | Internal UUID primary key |
| `organization_id` | Which company owns this entry |
| `entry_date` | Accounting date of the entry |
| `memo` | Human-readable description |
| `source_type` | Optional source such as `invoice`, `bill`, `payment`, `manual` |
| `source_id` | Optional ID of the source document |
| `posted_by_user_id` | Clerk user ID of the user or system actor |
| `created_at` | Row creation timestamp |
| `updated_at` | Row update timestamp |

Later phases will add more auditability features such as voiding and reversing.

For now, we keep the schema focused.

---

## The Implementation

A journal entry might represent:

```txt
Manual journal entry
Invoice posting
Bill posting
Payment posting
Bank transaction posting
```

So `source_type` and `source_id` are optional.

Examples:

```txt
source_type = invoice
source_id   = invoice database UUID

source_type = manual
source_id   = null
```

---

## The Verification

After migration, `journal_entries` should exist and include:

```txt
organization_id
entry_date
memo
source_type
source_id
posted_by_user_id
```

---

# 3. Design `journal_lines`

## The Target

We are deciding the columns for:

```txt
journal_lines
```

---

## The Concept

A journal line is one debit or credit movement to one account.

It should include:

| Column | Purpose |
|---|---|
| `id` | Internal UUID primary key |
| `journal_entry_id` | Parent journal entry |
| `organization_id` | Company that owns the line |
| `account_id` | Account affected |
| `line_number` | Stable ordering within the journal entry |
| `description` | Optional line-level memo |
| `debit_cents` | Debit amount in integer cents |
| `credit_cents` | Credit amount in integer cents |
| `created_at` | Row creation timestamp |

A journal line should follow these rules:

```txt
Debit cannot be negative.
Credit cannot be negative.
A line cannot have both debit and credit.
A line cannot have neither debit nor credit.
```

The full journal entry balance rule:

```txt
total debits = total credits
```

cannot be easily enforced with a simple row-level database check because it depends on summing multiple rows.

We will enforce that in the `postJournalEntry()` service in Part 13.

---

## The Implementation

We will store money as integer cents using Postgres `bigint`.

Examples:

```txt
S$109.00 -> 10900
S$1.00   -> 100
```

We use `bigint` instead of decimal floats because money should not suffer floating-point rounding bugs.

---

## The Verification

The database should reject lines like:

```txt
debit_cents = -100
credit_cents = 0
```

And:

```txt
debit_cents = 100
credit_cents = 100
```

And:

```txt
debit_cents = 0
credit_cents = 0
```

Later we will test this through the journal engine.

---

# 4. Update the Database Schema

## The Target

We are updating:

```txt
db/schema.ts
```

to add:

- `journalSourceTypeEnum`
- `journal_entries`
- `journal_lines`
- TypeScript table types

---

## The Concept

The database schema is our blueprint.

We already have:

```txt
organizations
accounts
```

Now we add the journal.

The journal tables reference existing tables with foreign keys.

A foreign key is a database rule that says:

> This value must point to a real row in another table.

So:

```txt
journal_entries.organization_id
```

must point to:

```txt
organizations.id
```

And:

```txt
journal_lines.account_id
```

must point to:

```txt
accounts.id
```

---

## The Implementation

Open:

```txt
db/schema.ts
```

Replace the entire file with this complete version:

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

/**
 * account_type enum
 *
 * These are the five core account categories used by double-entry accounting.
 *
 * They intentionally match the AccountType union from lib/accounting/types.ts.
 */
export const accountTypeEnum = pgEnum("account_type", [
  "asset",
  "liability",
  "equity",
  "income",
  "expense",
]);

/**
 * journal_source_type enum
 *
 * This describes where a journal entry came from.
 *
 * We start with a practical set of sources. Later modules can use these values
 * when invoices, bills, payments, and bank imports post to the ledger.
 */
export const journalSourceTypeEnum = pgEnum("journal_source_type", [
  "manual",
  "invoice",
  "bill",
  "customer_payment",
  "vendor_payment",
  "bank_transaction",
  "system",
]);

/**
 * organizations
 *
 * This table is our application's local copy of a Clerk organization.
 *
 * Clerk remains the identity provider, but our accounting records need a local
 * organization row to reference with foreign keys.
 */
export const organizations = pgTable(
  "organizations",
  {
    /**
     * Internal database ID.
     *
     * We use a UUID so this ID is globally unique and safe to reference from
     * many future tables.
     */
    id: uuid("id").defaultRandom().primaryKey(),

    /**
     * Clerk's organization ID.
     *
     * Example:
     *   org_2abc123...
     *
     * This lets us connect Clerk's organization identity to our own database.
     */
    clerkOrganizationId: text("clerk_organization_id").notNull(),

    /**
     * Human-readable company name.
     *
     * Example:
     *   Demo Pte. Ltd.
     */
    name: text("name").notNull(),

    /**
     * Optional Clerk organization slug.
     *
     * Example:
     *   demo-pte-ltd
     */
    slug: text("slug"),

    /**
     * Optional organization image URL from Clerk.
     */
    imageUrl: text("image_url"),

    /**
     * Row creation timestamp.
     */
    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),

    /**
     * Row update timestamp.
     *
     * We manually update this when syncing changed Clerk organization data.
     */
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

/**
 * accounts
 *
 * The chart of accounts for each organization.
 *
 * Every future journal line will point to one account from this table.
 */
export const accounts = pgTable(
  "accounts",
  {
    /**
     * Internal database ID.
     */
    id: uuid("id").defaultRandom().primaryKey(),

    /**
     * The organization that owns this account.
     *
     * This is the most important multi-tenancy column on this table.
     */
    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, {
        onDelete: "cascade",
      }),

    /**
     * Account code.
     *
     * Examples:
     *   1000
     *   1100
     *   2100
     *   4000
     *
     * Codes are unique per organization, not globally unique.
     */
    code: text("code").notNull(),

    /**
     * Human-readable account name.
     */
    name: text("name").notNull(),

    /**
     * Core account type.
     *
     * This determines reporting behavior and normal balance behavior.
     */
    type: accountTypeEnum("type").notNull(),

    /**
     * Optional description shown in the UI.
     */
    description: text("description"),

    /**
     * Whether this account was created by our system seed process.
     */
    isSystem: boolean("is_system").default(false).notNull(),

    /**
     * Whether users can actively post new transactions to this account.
     */
    isActive: boolean("is_active").default(true).notNull(),

    /**
     * Row creation timestamp.
     */
    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),

    /**
     * Row update timestamp.
     */
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
 * journal_entries
 *
 * The header table for posted accounting events.
 *
 * A journal entry belongs to one organization and has one or more journal lines.
 */
export const journalEntries = pgTable(
  "journal_entries",
  {
    /**
     * Internal database ID.
     */
    id: uuid("id").defaultRandom().primaryKey(),

    /**
     * The organization that owns this journal entry.
     *
     * This is the tenant boundary for the entry.
     */
    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, {
        onDelete: "cascade",
      }),

    /**
     * Accounting date of the entry.
     *
     * We use a date, not a timestamp, because accounting reports are usually
     * grouped by accounting dates rather than exact times.
     */
    entryDate: date("entry_date").notNull(),

    /**
     * Human-readable explanation of the entry.
     */
    memo: text("memo").notNull(),

    /**
     * Optional source type.
     *
     * Examples:
     * - manual
     * - invoice
     * - bill
     * - customer_payment
     */
    sourceType: journalSourceTypeEnum("source_type").default("manual").notNull(),

    /**
     * Optional source document ID.
     *
     * This can reference an invoice ID, bill ID, payment ID, or other document
     * ID from future modules.
     */
    sourceId: uuid("source_id"),

    /**
     * Clerk user ID of the user who posted the entry.
     *
     * System-generated entries may use a system actor string later.
     */
    postedByUserId: text("posted_by_user_id"),

    /**
     * Row creation timestamp.
     */
    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),

    /**
     * Row update timestamp.
     */
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    /**
     * Common report queries filter entries by organization and date.
     */
    index("journal_entries_organization_id_entry_date_idx").on(
      table.organizationId,
      table.entryDate,
    ),

    /**
     * Helpful for looking up entries created from a specific source document.
     */
    index("journal_entries_organization_id_source_idx").on(
      table.organizationId,
      table.sourceType,
      table.sourceId,
    ),
  ],
);

/**
 * journal_lines
 *
 * The detailed debit and credit lines inside a journal entry.
 *
 * The complete journal entry must balance:
 *   total debits = total credits
 *
 * The database can enforce line-level checks here, while the service layer will
 * enforce entry-level balancing in Part 13.
 */
export const journalLines = pgTable(
  "journal_lines",
  {
    /**
     * Internal database ID.
     */
    id: uuid("id").defaultRandom().primaryKey(),

    /**
     * Parent journal entry.
     */
    journalEntryId: uuid("journal_entry_id")
      .notNull()
      .references(() => journalEntries.id, {
        onDelete: "cascade",
      }),

    /**
     * Organization that owns this journal line.
     *
     * This intentionally duplicates the journal entry organization ID so report
     * queries can filter directly on journal_lines.organization_id.
     */
    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, {
        onDelete: "cascade",
      }),

    /**
     * Account affected by this line.
     */
    accountId: uuid("account_id")
      .notNull()
      .references(() => accounts.id, {
        onDelete: "restrict",
      }),

    /**
     * Stable display order within a journal entry.
     */
    lineNumber: integer("line_number").notNull(),

    /**
     * Optional line-level description.
     */
    description: text("description"),

    /**
     * Debit amount in integer cents.
     *
     * We use bigint with mode number so TypeScript sees a number while Postgres
     * stores a large integer.
     */
    debitCents: bigint("debit_cents", { mode: "number" })
      .default(0)
      .notNull(),

    /**
     * Credit amount in integer cents.
     */
    creditCents: bigint("credit_cents", { mode: "number" })
      .default(0)
      .notNull(),

    /**
     * Row creation timestamp.
     */
    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    /**
     * Ensures line ordering is unique within one journal entry.
     */
    uniqueIndex("journal_lines_entry_id_line_number_idx").on(
      table.journalEntryId,
      table.lineNumber,
    ),

    /**
     * Common report queries filter journal lines by organization.
     */
    index("journal_lines_organization_id_idx").on(table.organizationId),

    /**
     * Common ledger queries filter by account.
     */
    index("journal_lines_organization_id_account_id_idx").on(
      table.organizationId,
      table.accountId,
    ),

    /**
     * Helpful when loading all lines for an entry.
     */
    index("journal_lines_journal_entry_id_idx").on(table.journalEntryId),

    /**
     * Debit amount cannot be negative.
     */
    check("journal_lines_debit_non_negative_check", sql`${table.debitCents} >= 0`),

    /**
     * Credit amount cannot be negative.
     */
    check(
      "journal_lines_credit_non_negative_check",
      sql`${table.creditCents} >= 0`,
    ),

    /**
     * A journal line must have exactly one side:
     * - debit > 0 and credit = 0
     * - OR credit > 0 and debit = 0
     *
     * It cannot have both sides.
     * It cannot have neither side.
     */
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

export type JournalEntry = typeof journalEntries.$inferSelect;
export type NewJournalEntry = typeof journalEntries.$inferInsert;

export type JournalLine = typeof journalLines.$inferSelect;
export type NewJournalLine = typeof journalLines.$inferInsert;
```

---

## The Verification

Run:

```bash
pnpm db:generate
```

You should see Drizzle generate a new migration.

Then run:

```bash
pnpm build
```

The build should succeed.

---

# 5. Review the Generated Migration

## The Target

We are inspecting the generated SQL migration.

---

## The Concept

Schema changes in financial software should be reviewed before applying.

This migration should be additive.

It should create:

```txt
journal_source_type enum
journal_entries table
journal_lines table
indexes
foreign keys
check constraints
```

It should **not** delete existing tables.

---

## The Implementation

Open the newest migration file in:

```txt
drizzle/
```

It will likely be named something like:

```txt
drizzle/0002_some_name.sql
```

You should see SQL similar to:

```sql
CREATE TYPE "public"."journal_source_type" AS ENUM(
  'manual',
  'invoice',
  'bill',
  'customer_payment',
  'vendor_payment',
  'bank_transaction',
  'system'
);

CREATE TABLE "journal_entries" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "entry_date" date NOT NULL,
  "memo" text NOT NULL,
  "source_type" "journal_source_type" DEFAULT 'manual' NOT NULL,
  "source_id" uuid,
  "posted_by_user_id" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "journal_lines" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "journal_entry_id" uuid NOT NULL,
  "organization_id" uuid NOT NULL,
  "account_id" uuid NOT NULL,
  "line_number" integer NOT NULL,
  "description" text,
  "debit_cents" bigint DEFAULT 0 NOT NULL,
  "credit_cents" bigint DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
```

You should also see constraints and indexes.

---

## The Verification

Confirm that the migration includes:

```txt
journal_entries
journal_lines
journal_source_type
foreign key to organizations
foreign key to accounts
check constraints on journal_lines
```

If yes, continue.

---

# 6. Apply the Migration

## The Target

We are applying the journal table migration to Neon.

---

## The Concept

Generating a migration creates the instructions.

Applying the migration changes the real database.

```txt
pnpm db:generate = write migration file
pnpm db:migrate  = apply migration to Neon
```

---

## The Implementation

Run:

```bash
pnpm db:migrate
```

---

## The Verification

Open Neon SQL editor and run:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

You should see:

```txt
accounts
journal_entries
journal_lines
organizations
```

Now verify the journal source enum:

```sql
select enumlabel
from pg_enum
join pg_type on pg_enum.enumtypid = pg_type.oid
where pg_type.typname = 'journal_source_type'
order by enumsortorder;
```

You should see:

```txt
manual
invoice
bill
customer_payment
vendor_payment
bank_transaction
system
```

Now verify the journal tables are empty:

```sql
select * from journal_entries;
select * from journal_lines;
```

Both should return zero rows.

That is correct.

---

# 7. Create Journal Diagnostic Services

## The Target

We are creating:

```txt
services/journal/get-journal-diagnostics.ts
```

This service will count journal entries and lines for the active organization.

---

## The Concept

Before we build posting logic, we need visibility.

Diagnostic services help us confirm the tables exist and can be queried.

This is like checking that the ledger book exists before writing entries into it.

---

## The Implementation

Create the folder:

```bash
mkdir -p services/journal
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force services/journal
```

Create:

```txt
services/journal/get-journal-diagnostics.ts
```

Add:

```ts
// services/journal/get-journal-diagnostics.ts

import { count, desc, eq } from "drizzle-orm";
import { db } from "@/db";
import { journalEntries, journalLines } from "@/db/schema";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

export type JournalDiagnostics = {
  organizationId: string | null;
  journalEntryCount: number;
  journalLineCount: number;
  recentEntries: Array<{
    id: string;
    entryDate: string;
    memo: string;
    sourceType: string;
    createdAt: Date;
  }>;
};

/**
 * Returns journal diagnostics for the currently active organization.
 *
 * At the end of Part 12, these counts will usually be zero.
 * In Part 13 and Part 14, they will increase when we post test entries.
 */
export async function getCurrentOrganizationJournalDiagnostics(): Promise<JournalDiagnostics> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return {
      organizationId: null,
      journalEntryCount: 0,
      journalLineCount: 0,
      recentEntries: [],
    };
  }

  const [entryCountRow] = await db
    .select({ value: count() })
    .from(journalEntries)
    .where(eq(journalEntries.organizationId, organization.id));

  const [lineCountRow] = await db
    .select({ value: count() })
    .from(journalLines)
    .where(eq(journalLines.organizationId, organization.id));

  const recentEntries = await db
    .select({
      id: journalEntries.id,
      entryDate: journalEntries.entryDate,
      memo: journalEntries.memo,
      sourceType: journalEntries.sourceType,
      createdAt: journalEntries.createdAt,
    })
    .from(journalEntries)
    .where(eq(journalEntries.organizationId, organization.id))
    .orderBy(desc(journalEntries.createdAt))
    .limit(10);

  return {
    organizationId: organization.id,
    journalEntryCount: entryCountRow?.value ?? 0,
    journalLineCount: lineCountRow?.value ?? 0,
    recentEntries,
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

# 8. Update Database Health Checks

## The Target

We are updating:

```txt
lib/database-health.ts
```

to include:

- Global journal entry count
- Global journal line count

---

## The Concept

The database health page should evolve as the database grows.

Previously, it checked:

```txt
organizations
accounts
```

Now it should also check:

```txt
journal_entries
journal_lines
```

At this stage, both journal counts should be zero.

That is expected.

---

## The Implementation

Open:

```txt
lib/database-health.ts
```

Replace the entire file with:

```ts
// lib/database-health.ts

import { count } from "drizzle-orm";
import { db } from "@/db";
import {
  accounts,
  journalEntries,
  journalLines,
  organizations,
} from "@/db/schema";

export type DatabaseHealthResult =
  | {
      ok: true;
      latencyMs: number;
      organizationCount: number;
      accountCount: number;
      journalEntryCount: number;
      journalLineCount: number;
    }
  | {
      ok: false;
      latencyMs: number;
      errorMessage: string;
    };

/**
 * Performs small database queries to verify that:
 * - DATABASE_URL is valid
 * - Neon is reachable
 * - migrations have created required tables
 */
export async function getDatabaseHealth(): Promise<DatabaseHealthResult> {
  const startedAt = Date.now();

  try {
    const [organizationRow] = await db
      .select({ value: count() })
      .from(organizations);

    const [accountRow] = await db.select({ value: count() }).from(accounts);

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

If a later page says `relation "journal_entries" does not exist`, run:

```bash
pnpm db:migrate
```

---

# 9. Create the Journal Database Diagnostic Page

## The Target

We are creating:

```txt
app/settings/database/journal/page.tsx
```

This page verifies the journal tables for the active organization.

---

## The Concept

This diagnostic page answers:

```txt
Does the active organization have journal entries?
Does the active organization have journal lines?
Can the app query the new journal tables?
```

At the end of Part 12, counts should usually be:

```txt
Journal entries: 0
Journal lines:   0
```

That is correct.

We have built the tables, but we have not posted entries yet.

---

## The Implementation

Create the folder:

```bash
mkdir -p app/settings/database/journal
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/settings/database/journal
```

Create:

```txt
app/settings/database/journal/page.tsx
```

Add:

```tsx
// app/settings/database/journal/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { getCurrentOrganizationJournalDiagnostics } from "@/services/journal/get-journal-diagnostics";

export const dynamic = "force-dynamic";

export default async function DatabaseJournalPage() {
  const diagnostics = await getCurrentOrganizationJournalDiagnostics();

  return (
    <AppLayout
      title="Database Journal"
      description="Inspect journal entry and journal line table readiness for the active database organization."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
              Journal schema
            </p>

            <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
              Journal database readiness
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
              This page confirms that the <code>journal_entries</code> and{" "}
              <code>journal_lines</code> tables exist and can be queried for the
              active organization.
            </p>
          </div>

          <div className="flex flex-wrap gap-2">
            <Link
              href="/settings/database"
              className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
            >
              Database status
            </Link>

            <Link
              href="/reports/accounting-primer"
              className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
            >
              Accounting primer
            </Link>
          </div>
        </div>

        {diagnostics.organizationId ? (
          <div className="mt-6 grid gap-4 lg:grid-cols-3">
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 lg:col-span-3">
              <p className="text-sm font-semibold text-slate-700">
                Active database organization ID
              </p>

              <p className="mt-1 break-all font-mono text-xs text-slate-500">
                {diagnostics.organizationId}
              </p>
            </div>

            <div className="rounded-xl bg-emerald-50 p-4">
              <p className="text-sm font-semibold text-emerald-700">
                Journal entries
              </p>
              <p className="mt-2 text-3xl font-bold text-emerald-900">
                {diagnostics.journalEntryCount}
              </p>
            </div>

            <div className="rounded-xl bg-sky-50 p-4">
              <p className="text-sm font-semibold text-sky-700">
                Journal lines
              </p>
              <p className="mt-2 text-3xl font-bold text-sky-900">
                {diagnostics.journalLineCount}
              </p>
            </div>

            <div className="rounded-xl bg-amber-50 p-4">
              <p className="text-sm font-semibold text-amber-700">
                Expected status
              </p>
              <p className="mt-2 text-sm leading-6 text-amber-800">
                Zero rows is normal until Part 13 and Part 14 post test journal
                entries.
              </p>
            </div>
          </div>
        ) : (
          <div className="mt-6 rounded-2xl border border-amber-200 bg-amber-50 p-5">
            <p className="text-sm font-semibold text-amber-800">
              No active organization selected.
            </p>

            <p className="mt-2 text-sm leading-6 text-amber-700">
              Create or select a company workspace before viewing journal
              diagnostics.
            </p>

            <Link
              href="/onboarding/organization"
              className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-amber-700"
            >
              Create company workspace
            </Link>
          </div>
        )}

        {diagnostics.organizationId && diagnostics.recentEntries.length > 0 ? (
          <div className="mt-6 overflow-hidden rounded-xl border border-slate-200">
            <table className="w-full border-collapse text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-semibold">Date</th>
                  <th className="px-4 py-3 font-semibold">Memo</th>
                  <th className="px-4 py-3 font-semibold">Source</th>
                  <th className="px-4 py-3 font-semibold">Entry ID</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-200 bg-white">
                {diagnostics.recentEntries.map((entry) => (
                  <tr key={entry.id}>
                    <td className="px-4 py-3 text-slate-600">
                      {entry.entryDate}
                    </td>

                    <td className="px-4 py-3 font-semibold text-slate-950">
                      {entry.memo}
                    </td>

                    <td className="px-4 py-3 text-slate-600">
                      {entry.sourceType}
                    </td>

                    <td className="px-4 py-3">
                      <code className="break-all text-xs text-slate-500">
                        {entry.id}
                      </code>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : diagnostics.organizationId ? (
          <div className="mt-6 rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
            <h3 className="text-lg font-semibold text-slate-950">
              No journal entries yet
            </h3>

            <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
              This is expected at the end of Part 12. We have created the
              database tables, but the journal posting engine comes in Part 13.
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

Run:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000/settings/database/journal
```

If an organization is active, you should see:

```txt
Journal entries: 0
Journal lines: 0
```

That is correct.

---

# 10. Update the Database Status Page

## The Target

We are updating:

```txt
app/settings/database/page.tsx
```

to display journal table counts and link to the journal diagnostic page.

---

## The Concept

The database status page is our central schema health page.

Now it should show:

```txt
Organizations
Accounts
Journal entries
Journal lines
```

---

## The Implementation

Open:

```txt
app/settings/database/page.tsx
```

Replace the entire file with:

```tsx
// app/settings/database/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { getDatabaseHealth } from "@/lib/database-health";

export const dynamic = "force-dynamic";

export default async function DatabaseStatusPage() {
  const health = await getDatabaseHealth();

  return (
    <AppLayout
      title="Database Status"
      description="Verify Neon Postgres connectivity, Drizzle migrations, and application database readiness."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
              Neon Postgres
            </p>

            <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
              Database connection check
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
              This page runs real server-side queries through Drizzle ORM. It
              confirms that the application can reach the database and that
              required tables exist.
            </p>
          </div>

          {health.ok ? (
            <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
              Connected
            </span>
          ) : (
            <span className="rounded-full bg-rose-50 px-3 py-1 text-xs font-semibold text-rose-700">
              Connection failed
            </span>
          )}
        </div>

        {health.ok ? (
          <dl className="mt-6 divide-y divide-slate-200 overflow-hidden rounded-xl border border-slate-200">
            <div className="grid gap-1 bg-slate-50 px-4 py-3 sm:grid-cols-3">
              <dt className="text-sm font-semibold text-slate-600">Status</dt>
              <dd className="text-sm font-semibold text-emerald-700 sm:col-span-2">
                Database queries succeeded
              </dd>
            </div>

            <div className="grid gap-1 bg-white px-4 py-3 sm:grid-cols-3">
              <dt className="text-sm font-semibold text-slate-600">
                Query latency
              </dt>
              <dd className="text-sm text-slate-950 sm:col-span-2">
                {health.latencyMs}ms
              </dd>
            </div>

            <div className="grid gap-1 bg-slate-50 px-4 py-3 sm:grid-cols-3">
              <dt className="text-sm font-semibold text-slate-600">
                Organization rows
              </dt>
              <dd className="text-sm text-slate-950 sm:col-span-2">
                {health.organizationCount}
              </dd>
            </div>

            <div className="grid gap-1 bg-white px-4 py-3 sm:grid-cols-3">
              <dt className="text-sm font-semibold text-slate-600">
                Account rows
              </dt>
              <dd className="text-sm text-slate-950 sm:col-span-2">
                {health.accountCount}
              </dd>
            </div>

            <div className="grid gap-1 bg-slate-50 px-4 py-3 sm:grid-cols-3">
              <dt className="text-sm font-semibold text-slate-600">
                Journal entry rows
              </dt>
              <dd className="text-sm text-slate-950 sm:col-span-2">
                {health.journalEntryCount}
              </dd>
            </div>

            <div className="grid gap-1 bg-white px-4 py-3 sm:grid-cols-3">
              <dt className="text-sm font-semibold text-slate-600">
                Journal line rows
              </dt>
              <dd className="text-sm text-slate-950 sm:col-span-2">
                {health.journalLineCount}
              </dd>
            </div>
          </dl>
        ) : (
          <div className="mt-6 rounded-2xl border border-rose-200 bg-rose-50 p-5">
            <h3 className="text-sm font-semibold text-rose-800">
              Database check failed
            </h3>

            <p className="mt-2 text-sm leading-6 text-rose-700">
              {health.errorMessage}
            </p>

            <div className="mt-4 rounded-xl bg-white/70 p-4 text-sm leading-6 text-rose-800">
              Check that <code>DATABASE_URL</code> exists in{" "}
              <code>.env.local</code>, that your Neon database is active, and
              that you have run <code>pnpm db:migrate</code>.
            </div>
          </div>
        )}
      </section>

      <section className="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <Link
          href="/settings/database/organizations"
          className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
            Organization sync
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            View database organizations
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            Inspect local organization rows synced from Clerk into the
            application database.
          </p>
        </Link>

        <Link
          href="/settings/database/accounts"
          className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-sky-600">
            Chart of accounts
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            View database accounts
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            Inspect account rows for the active organization.
          </p>
        </Link>

        <Link
          href="/settings/database/journal"
          className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-purple-600">
            Journal
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            View journal tables
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            Inspect journal entry and journal line readiness for the active
            organization.
          </p>
        </Link>

        <Link
          href="/settings/auth-status"
          className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-amber-600">
            Auth context
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            View auth status
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            Compare Clerk user, Clerk organization, and synced database
            organization context.
          </p>
        </Link>
      </section>

      <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-slate-950">
          What this confirms
        </h2>

        <ul className="mt-4 space-y-3 text-sm leading-6 text-slate-600">
          <li className="rounded-xl bg-slate-50 p-3">
            The Next.js server can read <code>DATABASE_URL</code>.
          </li>

          <li className="rounded-xl bg-slate-50 p-3">
            The Neon serverless client can connect to Postgres.
          </li>

          <li className="rounded-xl bg-slate-50 p-3">
            Drizzle can query <code>organizations</code> and{" "}
            <code>accounts</code>.
          </li>

          <li className="rounded-xl bg-slate-50 p-3">
            Drizzle can query the new <code>journal_entries</code> and{" "}
            <code>journal_lines</code> tables.
          </li>
        </ul>
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/settings/database
```

You should see:

```txt
Journal entry rows
Journal line rows
```

Both should usually be:

```txt
0
```

---

# 11. Update the Settings Page

## The Target

We are updating:

```txt
app/settings/page.tsx
```

to include a direct journal diagnostics link.

---

## The Concept

Settings is our temporary operational console while building the app.

We now have diagnostics for:

```txt
Auth
Organizations
Database
Accounts
Journal
```

---

## The Implementation

Open:

```txt
app/settings/page.tsx
```

Replace the entire file with:

```tsx
// app/settings/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";

const settingsCards = [
  {
    eyebrow: "Authentication",
    title: "Auth status",
    description:
      "Verify Clerk proxy protection, signed-in user data, organization context, and server-side auth access.",
    href: "/settings/auth-status",
  },
  {
    eyebrow: "Organization",
    title: "Organization settings",
    description:
      "Manage the active company workspace, members, invitations, and profile details.",
    href: "/settings/organization",
  },
  {
    eyebrow: "Database",
    title: "Database status",
    description:
      "Verify Neon Postgres connectivity, Drizzle migrations, and application database readiness.",
    href: "/settings/database",
  },
  {
    eyebrow: "Sync",
    title: "Database organizations",
    description:
      "Inspect local organization rows synced from Clerk into the organizations table.",
    href: "/settings/database/organizations",
  },
  {
    eyebrow: "Accounts",
    title: "Database accounts",
    description:
      "Inspect chart of accounts rows for the active database organization.",
    href: "/settings/database/accounts",
  },
  {
    eyebrow: "Journal",
    title: "Database journal",
    description:
      "Inspect journal entry and journal line table readiness for the active organization.",
    href: "/settings/database/journal",
  },
];

export default function SettingsPage() {
  return (
    <AppLayout
      title="Settings"
      description="Settings control company configuration, permissions, tax setup, and automation preferences."
    >
      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {settingsCards.map((card) => (
          <Link
            key={card.href}
            href={card.href}
            className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
              {card.eyebrow}
            </p>

            <h2 className="mt-3 text-lg font-semibold text-slate-950">
              {card.title}
            </h2>

            <p className="mt-2 text-sm leading-6 text-slate-500">
              {card.description}
            </p>
          </Link>
        ))}

        <article className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 shadow-sm md:col-span-2 xl:col-span-3">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-400">
            Coming later
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            Accounting company settings
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            In later phases, we will store GST registration details, financial
            year settings, invoice numbering, default accounts, and reporting
            preferences in our own database.
          </p>
        </article>
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/settings
```

You should see a card named:

```txt
Database journal
```

Click it.

You should arrive at:

```txt
/settings/database/journal
```

---

# 12. Verify Journal Constraints in Neon

## The Target

We are confirming the database constraints exist.

---

## The Concept

The database should protect line-level journal integrity.

Even before we write the full posting engine, Postgres should reject impossible line amounts.

We want to confirm these checks exist:

```txt
debit_cents >= 0
credit_cents >= 0
exactly one side is positive
```

---

## The Implementation

Open Neon SQL editor.

Run:

```sql
select
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
from pg_constraint
where conrelid = 'journal_lines'::regclass
order by conname;
```

You should see constraints including:

```txt
journal_lines_debit_non_negative_check
journal_lines_credit_non_negative_check
journal_lines_exactly_one_side_check
```

Now inspect indexes:

```sql
select
  indexname,
  indexdef
from pg_indexes
where tablename in ('journal_entries', 'journal_lines')
order by tablename, indexname;
```

You should see indexes for organization/date, organization/source, journal entry lines, and account lookups.

---

## The Verification

The schema is correct if the SQL output shows:

```txt
journal_lines_debit_non_negative_check
journal_lines_credit_non_negative_check
journal_lines_exactly_one_side_check
```

And journal indexes exist.

---

# 13. Run the Full Schema Flow Test

## The Target

We are verifying the full journal table setup.

---

## The Concept

A schema feature is complete only when every layer works:

```txt
Drizzle schema
  -> migration file
  -> Neon database
  -> runtime database client
  -> app diagnostic page
```

---

## The Implementation

Run:

```bash
pnpm db:generate
pnpm db:migrate
pnpm check
```

Notes:

- If `pnpm db:generate` says there are no schema changes, that is fine if you already generated the migration.
- `pnpm db:migrate` should apply or confirm migrations.
- `pnpm check` should pass.

Now start the app:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000/settings/database
```

Then open:

```txt
http://localhost:3000/settings/database/journal
```

---

## The Verification

Everything is working if:

- `pnpm db:migrate` succeeds
- `pnpm check` succeeds
- `/settings/database` shows journal counts
- `/settings/database/journal` loads
- Neon shows `journal_entries` and `journal_lines`

---

# 14. Commit the Journal Tables

## The Target

We are committing the journal schema work.

---

## The Concept

This is a major accounting milestone.

GreyMatter Ledger now has the database tables required for the ledger.

The next part will build the service that safely posts balanced journal entries.

---

## The Implementation

Run:

```bash
git status
```

You should see files like:

```txt
app/settings/database/journal/page.tsx
app/settings/database/page.tsx
app/settings/page.tsx
db/schema.ts
drizzle/0002_...
drizzle/meta/...
lib/database-health.ts
services/journal/get-journal-diagnostics.ts
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Create journal entry and journal line tables"
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

## Error: `relation "journal_entries" does not exist`

You updated the schema but did not apply the migration.

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

Then reload:

```txt
/settings/database
```

---

## Error: `type "journal_source_type" does not exist`

The enum migration was not applied.

Run:

```bash
pnpm db:migrate
```

If no migration exists, run:

```bash
pnpm db:generate
```

Then migrate again.

---

## Error: Drizzle says there are no schema changes

If you already generated the migration, that is normal.

Check whether a new migration file exists in:

```txt
drizzle/
```

Then run:

```bash
pnpm db:migrate
```

---

## Error: Check constraint syntax error

Make sure `db/schema.ts` imports both:

```ts
import { sql } from "drizzle-orm";
import { check } from "drizzle-orm/pg-core";
```

And make sure the checks are inside the `journalLines` table callback.

---

## Error: Database diagnostic page says no active organization selected

Create or select an organization:

```txt
/onboarding/organization
```

Then open:

```txt
/dashboard
```

Then retry:

```txt
/settings/database/journal
```

---

## Error: Journal counts are zero

That is expected at the end of Part 12.

We have created the tables, but we have not posted journal entries yet.

Part 13 builds the posting engine.

---

## Error: `DATABASE_URL` is missing during build

Make sure `.env.local` includes:

```bash
DATABASE_URL="postgresql://..."
```

Then run:

```bash
pnpm check
```

---

# Phase 5 Reference — Journal Schema Vocabulary

## Journal Entry

A journal entry is the header record for an accounting event.

Examples:

```txt
Invoice INV-0001 posted
Customer payment received
Manual adjustment
Vendor bill posted
```

---

## Journal Line

A journal line is one debit or credit inside a journal entry.

Example:

```txt
Debit Bank S$109.00
```

---

## Source Type

`source_type` explains where the entry came from.

Examples:

```txt
manual
invoice
bill
customer_payment
vendor_payment
bank_transaction
system
```

---

## Source ID

`source_id` optionally stores the database ID of the source document.

For example, if an invoice posts a journal entry:

```txt
journal_entries.source_type = invoice
journal_entries.source_id = invoices.id
```

We do not have invoice tables yet, but the journal schema is ready.

---

## Line-Level Constraints

The database enforces that a line has exactly one side:

```txt
Debit positive, credit zero
```

or:

```txt
Credit positive, debit zero
```

The database rejects:

```txt
Debit and credit both positive
```

and:

```txt
Debit and credit both zero
```

---

## Entry-Level Balance

The database does not yet enforce:

```txt
total debits = total credits
```

because that rule requires summing multiple journal lines.

The service layer will enforce it in Part 13.

---

# Part 12 Completion Checklist

You are ready for Part 13 if:

- [ ] `db/schema.ts` defines `journalSourceTypeEnum`
- [ ] `db/schema.ts` defines `journalEntries`
- [ ] `db/schema.ts` defines `journalLines`
- [ ] `journal_entries.organization_id` references `organizations.id`
- [ ] `journal_lines.journal_entry_id` references `journal_entries.id`
- [ ] `journal_lines.organization_id` references `organizations.id`
- [ ] `journal_lines.account_id` references `accounts.id`
- [ ] `journal_lines` has non-negative debit/credit checks
- [ ] `journal_lines` has exactly-one-side check
- [ ] Drizzle generated a journal migration
- [ ] `pnpm db:migrate` applied the migration
- [ ] Neon shows `journal_entries` and `journal_lines`
- [ ] `services/journal/get-journal-diagnostics.ts` exists
- [ ] `lib/database-health.ts` checks journal counts
- [ ] `/settings/database` shows journal entry and line rows
- [ ] `/settings/database/journal` loads
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
