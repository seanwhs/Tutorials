# Part 9 — Build the Chart of Accounts Schema

In Part 8, we learned the accounting vocabulary:

```txt
Asset
Liability
Equity
Income
Expense

Debit
Credit

Journal entry
Journal line
Balanced entry
```

Now we start turning that knowledge into database structure.

In this part, we will build the database schema for the **chart of accounts**.

By the end of this part, you will have:

- A database enum for account types
- A database table named `accounts`
- Organization-scoped account records
- A unique account code rule per organization
- A reusable account query service
- A protected database diagnostic page for accounts
- Updated database health output
- A generated and applied Drizzle migration

We will **not seed the accounts yet**. That happens in **Part 10**.

This part builds the empty filing cabinet.

Part 10 puts the default Singapore-friendly folders inside it.

---

# 1. Understand the Chart of Accounts

## The Target

We are designing the database structure for company accounts.

Examples of accounts:

```txt
1000 Bank
1100 Accounts Receivable
2000 Accounts Payable
2100 GST Payable
3000 Owner Capital
4000 Sales Revenue
6000 Rent Expense
```

---

## The Concept

The **chart of accounts** is the master list of financial categories a company uses.

Think of it like a labeled filing cabinet.

Every financial transaction must be filed into the correct drawer.

For example, when a customer pays an invoice:

```txt
Debit  Bank
Credit Accounts Receivable
```

That transaction uses two accounts from the chart of accounts.

A company cannot post a journal entry safely unless it has accounts to post into.

So before we build the journal engine, we need the `accounts` table.

---

## The Implementation

Each account belongs to exactly one organization.

That means the future database relationship is:

```txt
organizations
  |
  |-- accounts
```

In plain language:

```txt
Demo Pte. Ltd. has its own Bank account.
Client A Pte. Ltd. has its own Bank account.
They are separate rows.
```

Even if both companies use account code `1000`, those accounts are not the same account because they belong to different organizations.

So our uniqueness rule should be:

```txt
organization_id + code must be unique
```

Not:

```txt
code must be globally unique
```

Because this should be allowed:

```txt
Demo Pte. Ltd.      1000 Bank
Client A Pte. Ltd.  1000 Bank
```

But this should not be allowed inside the same company:

```txt
Demo Pte. Ltd.  1000 Bank
Demo Pte. Ltd.  1000 Cash at Bank
```

---

## The Verification

At the end of this part, the database should contain a new empty table:

```txt
accounts
```

And this query should work in Neon:

```sql
select *
from accounts;
```

It should return zero rows for now.

That is correct.

---

# 2. Design the `accounts` Table

## The Target

We are deciding exactly what columns the `accounts` table needs.

---

## The Concept

A good account record needs enough information to support:

- Accounting correctness
- User-friendly display
- Future reporting
- Multi-tenant isolation
- System default accounts
- Active/inactive account behavior

We will include these columns:

| Column | Purpose |
|---|---|
| `id` | Internal UUID primary key |
| `organization_id` | Which company owns this account |
| `code` | Account code such as `1000` |
| `name` | Human-readable account name |
| `type` | Asset, liability, equity, income, or expense |
| `description` | Optional explanation |
| `is_system` | Whether the app seeded/owns this account |
| `is_active` | Whether users can currently post to it |
| `created_at` | Row creation timestamp |
| `updated_at` | Row update timestamp |

The account type is extremely important.

It tells the app how the account behaves in reports.

For example:

```txt
Asset accounts appear on the Balance Sheet.
Income accounts appear on the Profit & Loss report.
Expense accounts appear on the Profit & Loss report.
Liability accounts appear on the Balance Sheet.
Equity accounts appear on the Balance Sheet.
```

---

## The Implementation

We will represent account type with a Postgres enum.

An enum is a fixed list of allowed values.

Allowed account types:

```txt
asset
liability
equity
income
expense
```

Using an enum prevents invalid database values like:

```txt
assets
revenue
cost
banana
```

---

## The Verification

After the migration, the database should reject invalid account types.

Later, when we insert rows, this should be valid:

```txt
asset
```

But this should be invalid:

```txt
assets
```

---

# 3. Update the Database Schema

## The Target

We are updating:

```txt
db/schema.ts
```

to add:

- `accountTypeEnum`
- `accounts` table
- account TypeScript types

---

## The Concept

The schema file is our database blueprint.

In Part 6 and Part 7, it only knew about organizations.

Now it will also know about accounts.

The relationship will look like this:

```txt
accounts.organization_id -> organizations.id
```

That is called a **foreign key**.

A foreign key is a database rule saying:

> This value must point to a real row in another table.

So an account cannot belong to a non-existent organization.

That is exactly what we want.

---

## The Implementation

Open:

```txt
db/schema.ts
```

Replace the entire file with this complete version:

```ts
// db/schema.ts

import {
  boolean,
  index,
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
     *
     * Examples:
     *   Bank
     *   Accounts Receivable
     *   GST Payable
     *   Sales Revenue
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
     *
     * System accounts are important because invoices, bills, payments, and GST
     * workflows will rely on known default accounts.
     */
    isSystem: boolean("is_system").default(false).notNull(),

    /**
     * Whether users can actively post new transactions to this account.
     *
     * We generally avoid deleting accounts that have accounting history.
     * Instead, we deactivate them.
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
    /**
     * Each organization can use its own account code sequence.
     *
     * This allows:
     *   Demo Pte. Ltd.      -> 1000 Bank
     *   Client A Pte. Ltd.  -> 1000 Bank
     *
     * But prevents duplicate account codes inside the same organization.
     */
    uniqueIndex("accounts_organization_id_code_idx").on(
      table.organizationId,
      table.code,
    ),

    /**
     * Speeds up account lists filtered by organization.
     */
    index("accounts_organization_id_idx").on(table.organizationId),

    /**
     * Speeds up report queries that group/filter accounts by type.
     */
    index("accounts_organization_id_type_idx").on(
      table.organizationId,
      table.type,
    ),

    /**
     * Speeds up common UI queries that show active accounts only.
     */
    index("accounts_organization_id_is_active_idx").on(
      table.organizationId,
      table.isActive,
    ),
  ],
);

export type Organization = typeof organizations.$inferSelect;
export type NewOrganization = typeof organizations.$inferInsert;

export type Account = typeof accounts.$inferSelect;
export type NewAccount = typeof accounts.$inferInsert;
```

Important relationship:

```ts
organizationId: uuid("organization_id")
  .notNull()
  .references(() => organizations.id, {
    onDelete: "cascade",
  }),
```

This means:

> Every account belongs to a real organization.

The `onDelete: "cascade"` means:

> If an organization row is deleted, its accounts are also deleted.

In future production accounting systems, you may choose stricter deletion behavior because deleting accounting history is sensitive. For this tutorial stage, cascade keeps development cleanup simple. Once we have posted journal entries, we will treat accounting records much more carefully.

---

## The Verification

Run:

```bash
pnpm db:generate
```

You should see Drizzle generate a new migration.

Example output shape:

```txt
Reading config file ...
2 tables
accounts ...
[✓] Your SQL migration file ➜ drizzle/0001_...
```

Now run:

```bash
pnpm build
```

The build should succeed.

---

# 4. Review the Generated Migration

## The Target

We are inspecting the migration Drizzle generated for the `accounts` table.

---

## The Concept

A migration is the database change script.

Before applying migrations, it is healthy to inspect them.

This is especially important for financial software because accidental destructive migrations can be dangerous.

At this stage, the migration should be additive.

Additive means:

```txt
It adds new structures without deleting old data.
```

---

## The Implementation

Open the newly generated SQL file inside:

```txt
drizzle/
```

The file will likely be named something like:

```txt
drizzle/0001_some_name.sql
```

You should see SQL similar to this:

```sql
CREATE TYPE "public"."account_type" AS ENUM('asset', 'liability', 'equity', 'income', 'expense');

CREATE TABLE "accounts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"code" text NOT NULL,
	"name" text NOT NULL,
	"type" "account_type" NOT NULL,
	"description" text,
	"is_system" boolean DEFAULT false NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "accounts" ADD CONSTRAINT "accounts_organization_id_organizations_id_fk"
FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id")
ON DELETE cascade ON UPDATE no action;

CREATE UNIQUE INDEX "accounts_organization_id_code_idx"
ON "accounts" USING btree ("organization_id","code");

CREATE INDEX "accounts_organization_id_idx"
ON "accounts" USING btree ("organization_id");

CREATE INDEX "accounts_organization_id_type_idx"
ON "accounts" USING btree ("organization_id","type");

CREATE INDEX "accounts_organization_id_is_active_idx"
ON "accounts" USING btree ("organization_id","is_active");
```

Your exact constraint names may differ slightly. That is okay.

---

## The Verification

Confirm the migration does these things:

- Creates enum `account_type`
- Creates table `accounts`
- Adds foreign key from `accounts.organization_id` to `organizations.id`
- Adds unique index on `organization_id + code`
- Adds indexes for organization, type, and active status

If yes, the migration is correct.

---

# 5. Apply the Migration

## The Target

We are applying the new schema to Neon.

---

## The Concept

Generating a migration writes the instructions.

Applying the migration changes the database.

```txt
pnpm db:generate  = write migration file
pnpm db:migrate   = apply migration to database
```

---

## The Implementation

Run:

```bash
pnpm db:migrate
```

You should see Drizzle apply the new migration.

---

## The Verification

Open Neon SQL editor and run:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

You should now see:

```txt
accounts
organizations
```

Now verify the enum:

```sql
select enumlabel
from pg_enum
join pg_type on pg_enum.enumtypid = pg_type.oid
where pg_type.typname = 'account_type'
order by enumsortorder;
```

You should see:

```txt
asset
liability
equity
income
expense
```

Now verify the table is empty:

```sql
select *
from accounts;
```

You should get zero rows.

That is correct. We have not seeded accounts yet.

---

# 6. Create Account Query Services

## The Target

We are creating:

```txt
services/accounts/get-accounts.ts
```

This file will contain database queries for accounts.

---

## The Concept

Pages should not directly contain database query details.

Instead, we create a service layer.

Think of this like giving the UI a clean request form:

```ts
await listCurrentOrganizationAccounts();
```

The UI should not need to know every Drizzle detail.

This also keeps tenant filtering centralized.

Tenant filtering means:

```txt
Only query accounts for the active organization.
```

That is one of the most important safety habits in a multi-company app.

---

## The Implementation

Create the folder:

```bash
mkdir -p services/accounts
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force services/accounts
```

Create:

```txt
services/accounts/get-accounts.ts
```

Add:

```ts
// services/accounts/get-accounts.ts

import { asc, count, eq } from "drizzle-orm";
import { db } from "@/db";
import { accounts, type Account } from "@/db/schema";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

export type AccountListResult = {
  organizationId: string | null;
  accounts: Account[];
};

/**
 * Lists accounts for the currently active database organization.
 *
 * If no organization is selected, we return an empty list instead of throwing.
 * This makes diagnostic and empty-state pages easier to render.
 */
export async function listCurrentOrganizationAccounts(): Promise<AccountListResult> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return {
      organizationId: null,
      accounts: [],
    };
  }

  const organizationAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.organizationId, organization.id))
    .orderBy(asc(accounts.code));

  return {
    organizationId: organization.id,
    accounts: organizationAccounts,
  };
}

/**
 * Counts accounts for the currently active database organization.
 *
 * This is useful for dashboards and diagnostics.
 */
export async function countCurrentOrganizationAccounts(): Promise<{
  organizationId: string | null;
  accountCount: number;
}> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return {
      organizationId: null,
      accountCount: 0,
    };
  }

  const [row] = await db
    .select({ value: count() })
    .from(accounts)
    .where(eq(accounts.organizationId, organization.id));

  return {
    organizationId: organization.id,
    accountCount: row?.value ?? 0,
  };
}
```

Important tenant filter:

```ts
.where(eq(accounts.organizationId, organization.id))
```

This is the pattern we will repeat throughout the project.

Never list all accounts across all organizations in normal business screens.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

---

# 7. Update Database Health Helper

## The Target

We are updating:

```txt
lib/database-health.ts
```

so the database status page can show both:

- Organization row count
- Account row count

---

## The Concept

Our database health page should evolve as the schema grows.

Previously, it checked only:

```txt
organizations
```

Now it should also verify:

```txt
accounts
```

This confirms the new migration was applied successfully.

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
import { accounts, organizations } from "@/db/schema";

export type DatabaseHealthResult =
  | {
      ok: true;
      latencyMs: number;
      organizationCount: number;
      accountCount: number;
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
 * - migrations have created the organizations table
 * - migrations have created the accounts table
 */
export async function getDatabaseHealth(): Promise<DatabaseHealthResult> {
  const startedAt = Date.now();

  try {
    const [organizationRow] = await db
      .select({ value: count() })
      .from(organizations);

    const [accountRow] = await db.select({ value: count() }).from(accounts);

    return {
      ok: true,
      latencyMs: Date.now() - startedAt,
      organizationCount: organizationRow?.value ?? 0,
      accountCount: accountRow?.value ?? 0,
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

If the build succeeds but the database status page later fails, it usually means the migration has not been applied.

Run:

```bash
pnpm db:migrate
```

---

# 8. Update the Database Status Page

## The Target

We are updating:

```txt
app/settings/database/page.tsx
```

to display account table health.

---

## The Concept

The database status page should show that the `accounts` table exists.

Right now, the account count should be:

```txt
0
```

That is expected because we seed accounts in Part 10.

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

      <section className="mt-6 grid gap-4 md:grid-cols-3">
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
            Drizzle can query the <code>organizations</code> table.
          </li>

          <li className="rounded-xl bg-slate-50 p-3">
            Drizzle can query the new <code>accounts</code> table.
          </li>
        </ul>
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
http://localhost:3000/settings/database
```

You should see:

```txt
Account rows: 0
```

If you see an error like:

```txt
relation "accounts" does not exist
```

run:

```bash
pnpm db:migrate
```

Then reload the page.

---

# 9. Create a Database Accounts Diagnostic Page

## The Target

We are creating:

```txt
app/settings/database/accounts/page.tsx
```

This page lists accounts for the active organization.

Right now it will usually show an empty state because Part 10 has not seeded accounts yet.

---

## The Concept

This page confirms that:

- The `accounts` table exists
- We can query accounts for the active organization
- The app is correctly scoped to the current database organization

This page is diagnostic for now. Later, the main chart of accounts page at `/accounts` will become the real user-facing management page.

---

## The Implementation

Create the folder:

```bash
mkdir -p app/settings/database/accounts
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/settings/database/accounts
```

Create:

```txt
app/settings/database/accounts/page.tsx
```

Add:

```tsx
// app/settings/database/accounts/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { listCurrentOrganizationAccounts } from "@/services/accounts/get-accounts";

export const dynamic = "force-dynamic";

export default async function DatabaseAccountsPage() {
  const { organizationId, accounts } = await listCurrentOrganizationAccounts();

  return (
    <AppLayout
      title="Database Accounts"
      description="Inspect chart of accounts rows for the active database organization."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-sky-600">
              Chart of accounts schema
            </p>

            <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
              Active organization accounts
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
              This diagnostic page queries the <code>accounts</code> table for
              the currently active database organization. In Part 10, we will
              seed a Singapore-friendly default chart of accounts.
            </p>
          </div>

          <Link
            href="/settings/database"
            className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
          >
            Back to database status
          </Link>
        </div>

        {organizationId ? (
          <div className="mt-6 rounded-xl border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm font-semibold text-slate-700">
              Active database organization ID
            </p>

            <p className="mt-1 break-all font-mono text-xs text-slate-500">
              {organizationId}
            </p>
          </div>
        ) : (
          <div className="mt-6 rounded-2xl border border-amber-200 bg-amber-50 p-5">
            <p className="text-sm font-semibold text-amber-800">
              No active organization selected.
            </p>

            <p className="mt-2 text-sm leading-6 text-amber-700">
              Create or select a company workspace before viewing organization
              accounts.
            </p>

            <Link
              href="/onboarding/organization"
              className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-amber-700"
            >
              Create company workspace
            </Link>
          </div>
        )}

        {organizationId && accounts.length > 0 ? (
          <div className="mt-6 overflow-hidden rounded-xl border border-slate-200">
            <table className="w-full border-collapse text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-semibold">Code</th>
                  <th className="px-4 py-3 font-semibold">Name</th>
                  <th className="px-4 py-3 font-semibold">Type</th>
                  <th className="px-4 py-3 font-semibold">System</th>
                  <th className="px-4 py-3 font-semibold">Active</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-200 bg-white">
                {accounts.map((account) => (
                  <tr key={account.id}>
                    <td className="px-4 py-3 font-mono text-xs font-semibold text-slate-700">
                      {account.code}
                    </td>

                    <td className="px-4 py-3 font-semibold text-slate-950">
                      {account.name}
                    </td>

                    <td className="px-4 py-3 capitalize text-slate-600">
                      {account.type}
                    </td>

                    <td className="px-4 py-3 text-slate-600">
                      {account.isSystem ? "Yes" : "No"}
                    </td>

                    <td className="px-4 py-3 text-slate-600">
                      {account.isActive ? "Yes" : "No"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : organizationId ? (
          <div className="mt-6 rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
            <h3 className="text-lg font-semibold text-slate-950">
              No accounts yet
            </h3>

            <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
              This is expected at the end of Part 9. The accounts table exists,
              but we have not seeded the Singapore-friendly chart of accounts
              yet. That comes in Part 10.
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
http://localhost:3000/settings/database/accounts
```

If an organization is active, you should see:

```txt
No accounts yet
```

That is correct.

If no organization is active, you should see a prompt to create a company workspace.

---

# 10. Update Settings Page with Accounts Diagnostic Link

## The Target

We are updating:

```txt
app/settings/page.tsx
```

to include the database accounts page.

---

## The Concept

Settings is our temporary diagnostic center while the app grows.

We already have links for:

- Auth status
- Organization settings
- Database status
- Database organizations

Now we add:

- Database accounts

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
];

export default function SettingsPage() {
  return (
    <AppLayout
      title="Settings"
      description="Settings control company configuration, permissions, tax setup, and automation preferences."
    >
      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
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

        <article className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 shadow-sm md:col-span-2 xl:col-span-5">
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

You should see a new card:

```txt
Database accounts
```

Click it.

You should arrive at:

```txt
/settings/database/accounts
```

---

# 11. Update the Main Accounts Page Empty State

## The Target

We are updating:

```txt
app/accounts/page.tsx
```

to acknowledge that the schema now exists.

---

## The Concept

The user-facing Chart of Accounts page still does not list real accounts yet because we have not seeded them.

But the message should now reflect our progress:

```txt
The database schema exists.
Seeding comes next.
```

---

## The Implementation

Open:

```txt
app/accounts/page.tsx
```

Replace the entire file with:

```tsx
// app/accounts/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { EmptyState } from "@/components/empty-state";

export default function AccountsPage() {
  return (
    <AppLayout
      title="Chart of Accounts"
      description="The chart of accounts is the master list of categories used to classify every financial transaction."
    >
      <div className="space-y-6">
        <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-700">
            Schema ready
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            The accounts table now exists
          </h2>

          <p className="mt-2 max-w-3xl text-sm leading-6 text-emerald-800">
            In this part, we created the database structure for organization
            scoped accounts. In Part 10, we will seed a Singapore-friendly
            default chart of accounts for each company workspace.
          </p>

          <Link
            href="/settings/database/accounts"
            className="mt-4 inline-flex rounded-xl bg-emerald-700 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-emerald-800"
          >
            View database accounts diagnostic
          </Link>
        </section>

        <EmptyState
          title="Chart of accounts seeding coming next"
          description="The accounts table is ready, but this organization does not have seeded accounts yet. In Part 10, we will create default asset, liability, equity, income, expense, GST, receivable, payable, and bank accounts."
          actionLabel="Seed accounts in Part 10"
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
http://localhost:3000/accounts
```

You should see:

```txt
Schema ready
The accounts table now exists
```

Click:

```txt
View database accounts diagnostic
```

You should arrive at:

```txt
/settings/database/accounts
```

---

# 12. Verify Account Table Constraints Manually

## The Target

We are manually verifying that the account table enforces important constraints.

---

## The Concept

Database constraints are safety rails.

Even if a future bug tries to insert invalid data, the database should reject it.

We want to verify:

- `organization_id` is required
- `type` must be one of the enum values
- duplicate account codes are not allowed within the same organization

---

## The Implementation

Open Neon SQL editor.

First, inspect account indexes:

```sql
select
  indexname,
  indexdef
from pg_indexes
where tablename = 'accounts'
order by indexname;
```

You should see indexes including:

```txt
accounts_organization_id_code_idx
accounts_organization_id_idx
accounts_organization_id_type_idx
accounts_organization_id_is_active_idx
```

Now inspect columns:

```sql
select
  column_name,
  data_type,
  is_nullable
from information_schema.columns
where table_name = 'accounts'
order by ordinal_position;
```

You should see columns including:

```txt
id
organization_id
code
name
type
description
is_system
is_active
created_at
updated_at
```

Now verify foreign keys:

```sql
select
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name as foreign_table_name,
  ccu.column_name as foreign_column_name
from information_schema.table_constraints as tc
join information_schema.key_column_usage as kcu
  on tc.constraint_name = kcu.constraint_name
join information_schema.constraint_column_usage as ccu
  on ccu.constraint_name = tc.constraint_name
where tc.constraint_type = 'FOREIGN KEY'
  and tc.table_name = 'accounts';
```

You should see that:

```txt
accounts.organization_id
```

references:

```txt
organizations.id
```

---

## The Verification

If all three SQL checks show the expected structure, the schema is correct.

---

# 13. Run the Full Schema Flow Test

## The Target

We are verifying the entire schema flow.

---

## The Concept

A schema change is complete only when every layer agrees:

```txt
Drizzle schema
  -> generated migration
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

- If there are no new schema changes, `pnpm db:generate` may say no changes were found.
- That is fine after the migration has already been generated.

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
http://localhost:3000/settings/database/accounts
```

Then open:

```txt
http://localhost:3000/accounts
```

---

## The Verification

Everything is working if:

- `pnpm db:migrate` succeeds
- `pnpm check` succeeds
- `/settings/database` shows account row count
- `/settings/database/accounts` loads
- `/accounts` shows the schema-ready message

---

# 14. Commit the Chart of Accounts Schema

## The Target

We are committing the accounts schema work.

---

## The Concept

This is an important accounting milestone.

GreyMatter Ledger now has a database structure for company-specific charts of accounts.

The next part will seed this structure with default Singapore-friendly accounts.

---

## The Implementation

Run:

```bash
git status
```

You should see files like:

```txt
app/accounts/page.tsx
app/settings/database/accounts/page.tsx
app/settings/database/page.tsx
app/settings/page.tsx
db/schema.ts
drizzle/0001_...
drizzle/meta/...
lib/database-health.ts
services/accounts/get-accounts.ts
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Add chart of accounts schema"
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

## Error: `relation "accounts" does not exist`

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

## Error: `type "account_type" does not exist`

The enum migration was not applied.

Run:

```bash
pnpm db:migrate
```

If the migration file does not include `CREATE TYPE "account_type"`, regenerate:

```bash
pnpm db:generate
```

---

## Error: Drizzle says there are no schema changes

If you already generated the migration, that is normal.

Check whether a new file exists in:

```txt
drizzle/
```

Then run:

```bash
pnpm db:migrate
```

---

## Error: Build fails because `DATABASE_URL` is missing

Server-rendered diagnostic pages use the database.

Make sure `.env.local` includes:

```bash
DATABASE_URL="postgresql://..."
```

Then rerun:

```bash
pnpm check
```

---

## Error: Account diagnostic page shows “No active organization selected”

Create or select an organization first:

```txt
/onboarding/organization
```

Then visit:

```txt
/dashboard
```

Then open:

```txt
/settings/database/accounts
```

---

## Error: Duplicate account code later fails

That is expected.

The database prevents duplicate account codes within the same organization:

```txt
organization_id + code must be unique
```

This is correct accounting behavior.

---

# Phase 4 Reference — Chart of Accounts Schema

## `accounts`

The `accounts` table stores account categories for each organization.

Examples:

```txt
Bank
Accounts Receivable
GST Payable
Sales Revenue
Rent Expense
```

---

## `account_type`

The database enum for account categories.

Allowed values:

```txt
asset
liability
equity
income
expense
```

---

## `organization_id`

The tenant isolation column.

Every account belongs to one organization.

Future queries must filter accounts by the active organization.

---

## `code`

The account code.

Examples:

```txt
1000
1100
2100
4000
6000
```

Codes are unique per organization.

---

## `is_system`

Indicates whether the app created the account as part of its default seed process.

System accounts will be important for invoice, bill, GST, and payment automation.

---

## `is_active`

Indicates whether users can currently post to the account.

Accounting systems often deactivate old accounts instead of deleting them, because old accounts may have historical journal entries.

---

# Part 9 Completion Checklist

You are ready for Part 10 if:

- [ ] `db/schema.ts` defines `accountTypeEnum`
- [ ] `db/schema.ts` defines `accounts`
- [ ] `accounts.organizationId` references `organizations.id`
- [ ] Account codes are unique per organization
- [ ] Drizzle generated a migration for `accounts`
- [ ] `pnpm db:migrate` applied the migration
- [ ] Neon shows the `accounts` table
- [ ] Neon shows the `account_type` enum
- [ ] `services/accounts/get-accounts.ts` exists
- [ ] `lib/database-health.ts` checks account count
- [ ] `/settings/database` shows account row count
- [ ] `/settings/database/accounts` loads
- [ ] `/accounts` shows the schema-ready message
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
