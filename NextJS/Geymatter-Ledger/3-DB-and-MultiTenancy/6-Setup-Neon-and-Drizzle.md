# Part 6 — Set Up Neon Postgres and Drizzle ORM

In Phase 2, we taught GreyMatter Ledger two identity concepts:

```txt
User          = the person signed in
Organization  = the company workspace currently active
```

Now we need a database.

Clerk stores authentication and organization identity, but Clerk is **not** our accounting database.

GreyMatter Ledger needs its own database for:

- Organizations mirrored from Clerk
- Chart of accounts
- Customers
- Vendors
- Invoices
- Bills
- Journal entries
- Journal lines
- Payments
- Reports
- Audit logs
- Bank imports
- Reconciliation data

In this part, we will connect the app to **Neon Postgres** using **Drizzle ORM**.

By the end of this part, you will have:

- A Neon Postgres database
- A `DATABASE_URL` environment variable
- Drizzle ORM installed
- Drizzle Kit installed
- A database schema folder
- An initial `organizations` table
- A generated migration
- A migrated Neon database
- A database client at `db/index.ts`
- A protected database status page inside the app
- A settings link to verify database connectivity

We will **not sync Clerk organizations yet**. That comes in **Part 7**.

In this part, we create the database foundation.

---

# 1. Understand Why We Need Our Own Database

## The Target

We are adding a real application database.

---

## The Concept

Clerk knows identity.

Postgres knows business data.

A useful analogy:

```txt
Clerk     = building security desk
Postgres  = company filing room
Drizzle   = organized filing clerk
```

Clerk can tell us:

```txt
Amanda is signed in.
Amanda is currently working in Demo Pte. Ltd.
Amanda is an organization admin.
```

But Clerk should not store accounting records like:

```txt
Invoice INV-0001
Debit Accounts Receivable S$109
Credit Sales Revenue S$100
Credit GST Payable S$9
```

That data belongs in our database.

---

## The Implementation

Our application database will eventually contain tables like:

```txt
organizations
accounts
customers
vendors
invoices
invoice_lines
bills
bill_lines
payments
journal_entries
journal_lines
audit_logs
bank_transactions
```

The most important design rule is:

```txt
Most accounting tables will include organization_id.
```

That lets us keep company data isolated.

For example:

```txt
Demo Pte. Ltd. invoices
```

must never mix with:

```txt
Client A Pte. Ltd. invoices
```

In this part, we start with the first table:

```txt
organizations
```

This table will become our local application copy of Clerk organizations.

---

## The Verification

At the end of this part, you should be able to open:

```txt
/settings/database
```

and see that the app successfully connected to Neon Postgres.

---

# 2. Create a Neon Postgres Database

## The Target

We are creating a hosted Postgres database using Neon.

---

## The Concept

Postgres is a relational database.

Relational means data is stored in tables that can reference each other.

Accounting data fits relational databases very well because accounting needs:

- Consistency
- Clear relationships
- Reliable constraints
- Durable records
- Queryable history

Neon gives us Postgres without manually running a database server.

---

## The Implementation

Go to:

```txt
https://neon.tech
```

Create an account or sign in.

Create a new project.

Recommended project name:

```txt
greymatter-ledger
```

Choose a region close to your users or close to your deployment region.

For Singapore-focused usage, choose the nearest available region in your Neon account. If Singapore is unavailable, choose a nearby Asia-Pacific region.

After creating the project, open the connection details and copy the connection string.

It will look similar to this:

```bash
postgresql://username:password@hostname/database?sslmode=require
```

Neon may show pooled and direct connection strings.

For this tutorial, use the normal/direct Postgres connection string unless Neon’s UI recommends otherwise for your account.

---

## The Verification

You are ready if you have a connection string that starts with:

```txt
postgresql://
```

and includes:

```txt
sslmode=require
```

Example shape:

```txt
postgresql://neondb_owner:password@ep-something.region.aws.neon.tech/neondb?sslmode=require
```

Do not paste your real database password into chat, Git, screenshots, or documentation.

---

# 3. Add the Database Environment Variable

## The Target

We are adding:

```txt
DATABASE_URL
```

to local environment configuration.

---

## The Concept

A database URL is a secret.

It contains:

- Username
- Password
- Host
- Database name

So it belongs in:

```txt
.env.local
```

not in source code.

We also document the variable in:

```txt
.env.example
```

without using a real password.

---

## The Implementation

Open your real local file:

```txt
.env.local
```

Add your actual Neon connection string:

```bash
DATABASE_URL="postgresql://your_neon_user:your_neon_password@your_neon_host/your_neon_database?sslmode=require"
```

Your `.env.local` should now look similar to this:

```bash
DATABASE_URL="postgresql://your_neon_user:your_neon_password@your_neon_host/your_neon_database?sslmode=require"

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_your_actual_publishable_key_from_clerk"
CLERK_SECRET_KEY="sk_test_your_actual_secret_key_from_clerk"

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"
```

Now open:

```txt
.env.example
```

Replace the entire file with:

```bash
DATABASE_URL="postgresql://user:password@host/database?sslmode=require"

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_replace_with_your_clerk_publishable_key"
CLERK_SECRET_KEY="sk_test_replace_with_your_clerk_secret_key"

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"
```

---

## The Verification

Run:

```bash
git status --short
```

You should see:

```txt
M .env.example
```

You should **not** see:

```txt
.env.local
```

If `.env.local` appears, confirm `.gitignore` includes:

```gitignore
.env.local
.env
.env.development.local
.env.test.local
.env.production.local
```

---

# 4. Install Drizzle ORM and Neon Packages

## The Target

We are installing the database packages.

---

## The Concept

We need three main tools:

| Package | Purpose |
|---|---|
| `drizzle-orm` | Type-safe ORM used by application code |
| `drizzle-kit` | Migration generator and migration runner |
| `@neondatabase/serverless` | Neon serverless Postgres client |
| `dotenv` | Loads `.env.local` for Drizzle config |

An **ORM** is an Object-Relational Mapper.

In plain language, it is a bridge between TypeScript and database tables.

Drizzle lets us define tables in TypeScript and then generate SQL migrations from those definitions.

---

## The Implementation

Run:

```bash
pnpm add drizzle-orm @neondatabase/serverless
```

Now install development tools:

```bash
pnpm add -D drizzle-kit dotenv
```

---

## The Verification

Open:

```txt
package.json
```

You should see dependencies similar to:

```json
"dependencies": {
  "@neondatabase/serverless": "...",
  "drizzle-orm": "..."
}
```

And dev dependencies similar to:

```json
"devDependencies": {
  "drizzle-kit": "...",
  "dotenv": "..."
}
```

Now run:

```bash
pnpm build
```

The build should still succeed.

---

# 5. Add Drizzle Scripts

## The Target

We are adding database scripts to:

```txt
package.json
```

---

## The Concept

Drizzle has a few common commands:

```txt
Generate migration files
Apply migrations to the database
Open Drizzle Studio
```

Instead of remembering long commands, we add scripts.

Think of scripts like named shortcuts.

---

## The Implementation

Open:

```txt
package.json
```

Update the `"scripts"` section so it includes these commands:

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "check": "pnpm lint && pnpm build",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio",
    "db:push": "drizzle-kit push"
  }
}
```

Do not delete your dependencies or dev dependencies.

Only update the scripts block.

Your full `package.json` will have different version numbers depending on when you installed packages. That is okay.

---

## The Verification

Run:

```bash
pnpm db:generate --help
```

You should see Drizzle Kit help output.

If the command is recognized, the scripts are wired correctly.

---

# 6. Create the Drizzle Configuration File

## The Target

We are creating:

```txt
drizzle.config.ts
```

This tells Drizzle where the schema lives and how to connect to Neon.

---

## The Concept

Drizzle needs to know:

```txt
Where are my table definitions?
Where should migration files be saved?
Which database should migrations run against?
```

That is the job of `drizzle.config.ts`.

Because Drizzle Kit runs outside the Next.js runtime, it does not automatically load `.env.local`.

So we explicitly load it using:

```ts
config({ path: ".env.local" });
```

---

## The Implementation

Create this file in the project root:

```txt
drizzle.config.ts
```

Add:

```ts
// drizzle.config.ts

import { config } from "dotenv";
import { defineConfig } from "drizzle-kit";

/**
 * Drizzle Kit runs as a separate CLI process.
 *
 * Next.js automatically loads `.env.local` for the app, but Drizzle Kit does
 * not. We load it manually so DATABASE_URL is available when generating and
 * running migrations.
 */
config({ path: ".env.local" });

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error(
    "DATABASE_URL is missing. Add it to .env.local before running Drizzle commands.",
  );
}

export default defineConfig({
  schema: "./db/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: {
    url: databaseUrl,
  },
  strict: true,
  verbose: true,
});
```

---

## The Verification

Run:

```bash
pnpm db:generate
```

At this moment, you should see an error similar to:

```txt
No schema file found
```

or:

```txt
Cannot find ./db/schema.ts
```

That is expected because we have not created the schema yet.

The important thing is that Drizzle found the config file and tried to use it.

We will create the schema next.

---

# 7. Create the Database Schema Folder

## The Target

We are creating:

```txt
db/schema.ts
```

This file will contain our Drizzle table definitions.

---

## The Concept

A database schema describes the shape of our database.

Think of a schema like an architect’s blueprint.

Before building rooms, doors, and wiring, the blueprint says what should exist.

In our first schema, we define the `organizations` table.

Why start with organizations?

Because almost every future accounting record will belong to an organization.

The `organizations` table is our local application anchor for a company workspace.

---

## The Implementation

Create the folder:

macOS/Linux:

```bash
mkdir -p db
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force db
```

Create:

```txt
db/schema.ts
```

Add:

```ts
// db/schema.ts

import {
  index,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from "drizzle-orm/pg-core";

/**
 * organizations
 *
 * This table is our application's local copy of a Clerk organization.
 *
 * Clerk remains the identity provider, but our accounting records need a local
 * organization row to reference with foreign keys.
 *
 * In Part 7, we will add getOrCreateOrganization() to sync the active Clerk
 * organization into this table.
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
     * We will manually set this when updating organization records.
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

export type Organization = typeof organizations.$inferSelect;
export type NewOrganization = typeof organizations.$inferInsert;
```

Important column:

```ts
clerkOrganizationId
```

This stores the Clerk organization ID.

Later, when Clerk says:

```txt
Current orgId = org_abc123
```

we can find or create the matching row in our database.

---

## The Verification

Run:

```bash
pnpm db:generate
```

This time, Drizzle should generate a migration.

You should see output similar to:

```txt
No config path provided, using default 'drizzle.config.ts'
Reading config file ...
1 tables
organizations 7 columns 2 indexes
[✓] Your SQL migration file ➜ drizzle/0000_...
```

Now list the generated migration folder:

macOS/Linux:

```bash
ls drizzle
```

Windows PowerShell:

```powershell
Get-ChildItem drizzle
```

You should see files similar to:

```txt
0000_some_generated_name.sql
meta
```

The exact migration file name will differ. That is normal.

---

# 8. Review the Generated Migration

## The Target

We are inspecting the SQL migration generated by Drizzle.

---

## The Concept

A migration is a versioned database change.

Think of it like a renovation instruction:

```txt
Add organizations table.
Add unique index for Clerk organization ID.
Add slug index.
```

Migrations are important because they let every environment apply the same database changes:

```txt
local development
preview deployment
production
```

---

## The Implementation

Open the generated SQL file inside:

```txt
drizzle/
```

The file name will be something like:

```txt
drizzle/0000_generated_name.sql
```

You should see SQL similar to:

```sql
CREATE TABLE "organizations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"clerk_organization_id" text NOT NULL,
	"name" text NOT NULL,
	"slug" text,
	"image_url" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE UNIQUE INDEX "organizations_clerk_organization_id_idx" ON "organizations" USING btree ("clerk_organization_id");
CREATE INDEX "organizations_slug_idx" ON "organizations" USING btree ("slug");
```

Do not edit the generated migration unless you know exactly why.

For this tutorial, leave it as generated.

---

## The Verification

Confirm the migration creates:

```txt
organizations table
organizations_clerk_organization_id_idx
organizations_slug_idx
```

If yes, the migration is correct.

---

# 9. Apply the Migration to Neon

## The Target

We are applying the generated migration to your Neon database.

---

## The Concept

Generating a migration creates the SQL file.

Applying a migration actually changes the database.

The difference is:

```txt
db:generate = write renovation instructions
db:migrate  = perform the renovation
```

---

## The Implementation

Run:

```bash
pnpm db:migrate
```

You should see output from Drizzle Kit showing that migrations were applied.

Example:

```txt
Reading config file ...
Using 'postgres' driver for database querying
[✓] migrations applied successfully!
```

---

## The Verification

Open your Neon dashboard.

Go to the SQL editor and run:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

You should see:

```txt
organizations
```

You can also run:

```sql
select *
from organizations;
```

You should get an empty result set.

That is correct.

We created the table, but we have not inserted any organizations yet.

---

# 10. Create the Database Client

## The Target

We are creating:

```txt
db/index.ts
```

This file exports the Drizzle database client used by server-side code.

---

## The Concept

Application code should not create a new database setup in every page or service.

Instead, we create one database module.

Think of it like installing one phone line to the database and letting server-side code use that shared connection setup.

---

## The Implementation

Create:

```txt
db/index.ts
```

Add:

```ts
// db/index.ts

import { neon } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-http";
import * as schema from "@/db/schema";

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error(
    "DATABASE_URL is missing. Add it to .env.local before using the database.",
  );
}

/**
 * Neon HTTP client.
 *
 * This is a serverless-friendly database client for Neon Postgres.
 */
const sql = neon(databaseUrl);

/**
 * Drizzle database client.
 *
 * Passing the schema here gives us typed access to our tables.
 */
export const db = drizzle(sql, {
  schema,
});

export { schema };
```

Important:

```ts
import * as schema from "@/db/schema";
```

This imports all table definitions.

And:

```ts
export const db = drizzle(sql, { schema });
```

This creates the typed Drizzle client.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

If it says `DATABASE_URL is missing`, check:

```txt
.env.local
```

Then restart commands after saving the file.

---

# 11. Add a Database Health Helper

## The Target

We are creating:

```txt
lib/database-health.ts
```

This helper verifies that the app can query the database.

---

## The Concept

A database connection should be testable.

Instead of waiting until invoices fail later, we create a small health function now.

It will check:

- Can the app query the `organizations` table?
- How long did the query take?
- How many organization rows currently exist?

Right now, the count should be:

```txt
0
```

because Part 7 has not synced organizations yet.

---

## The Implementation

Create:

```txt
lib/database-health.ts
```

Add:

```ts
// lib/database-health.ts

import { count } from "drizzle-orm";
import { db } from "@/db";
import { organizations } from "@/db/schema";

export type DatabaseHealthResult =
  | {
      ok: true;
      latencyMs: number;
      organizationCount: number;
    }
  | {
      ok: false;
      latencyMs: number;
      errorMessage: string;
    };

/**
 * Performs a small database query to verify that:
 * - DATABASE_URL is valid
 * - Neon is reachable
 * - migrations have created the organizations table
 */
export async function getDatabaseHealth(): Promise<DatabaseHealthResult> {
  const startedAt = Date.now();

  try {
    const [row] = await db.select({ value: count() }).from(organizations);

    return {
      ok: true,
      latencyMs: Date.now() - startedAt,
      organizationCount: row?.value ?? 0,
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

This query:

```ts
db.select({ value: count() }).from(organizations)
```

runs SQL similar to:

```sql
select count(*) from organizations;
```

If the table does not exist, this helper will return an error.

That makes it useful for confirming migrations were applied.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

The helper is not visible in the browser yet. We will add a database status page next.

---

# 12. Create a Protected Database Status Page

## The Target

We are creating:

```txt
app/settings/database/page.tsx
```

This page will show database connection status inside the protected app.

---

## The Concept

A database status page is a simple diagnostic tool.

It answers:

```txt
Can the deployed app reach the database?
Have migrations been applied?
Is the organizations table queryable?
```

This page is under:

```txt
/settings
```

so it is protected by our existing `proxy.ts`.

---

## The Implementation

Create the folder:

macOS/Linux:

```bash
mkdir -p app/settings/database
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/settings/database
```

Create:

```txt
app/settings/database/page.tsx
```

Add:

```tsx
// app/settings/database/page.tsx

import { AppLayout } from "@/components/app-layout";
import { getDatabaseHealth } from "@/lib/database-health";

/**
 * This page must be rendered dynamically because it checks live database state.
 */
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
              This page runs a real server-side query through Drizzle ORM. It
              confirms that the application can reach the database and that the
              initial organizations table exists.
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
                Database query succeeded
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
            The initial migration has been applied successfully.
          </li>
        </ul>
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Start the dev server:

```bash
pnpm dev
```

Sign in and open:

```txt
http://localhost:3000/settings/database
```

You should see:

```txt
Connected
Database query succeeded
Organization rows: 0
```

If you see an error, read the message. Common causes are covered in the troubleshooting section below.

---

# 13. Update the Settings Page with a Database Link

## The Target

We are updating:

```txt
app/settings/page.tsx
```

to include a link to the new database status page.

---

## The Concept

Settings is becoming our administrative control center.

It should include diagnostic pages for:

- Authentication
- Organizations
- Database

Later, it will also include company accounting settings.

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
      "Verify Clerk proxy protection, signed-in user data, and server-side auth access.",
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

        <article className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 shadow-sm">
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
Database status
```

Click it.

You should arrive at:

```txt
/settings/database
```

The page should show the database connection status.

---

# 14. Optional: Open Drizzle Studio

## The Target

We are opening Drizzle Studio to visually inspect the database.

---

## The Concept

Drizzle Studio is a browser-based database viewer.

It lets you inspect tables and rows without using raw SQL.

Think of it as a spreadsheet-like window into your database.

---

## The Implementation

Run:

```bash
pnpm db:studio
```

Drizzle should start a local Studio server.

It will print a URL similar to:

```txt
https://local.drizzle.studio
```

Open that URL in your browser.

You should see the `organizations` table.

---

## The Verification

In Drizzle Studio, confirm:

```txt
organizations
```

exists.

It should currently have:

```txt
0 rows
```

That is correct.

Part 7 will insert or update rows when syncing Clerk organizations.

---

# 15. Run a Full Database Flow Test

## The Target

We are testing the entire database setup from migration to app page.

---

## The Concept

A database setup is complete only when all layers work together:

```txt
Environment variable
  -> Drizzle config
  -> Migration generation
  -> Migration execution
  -> Runtime database client
  -> App page query
```

If any layer is broken, the database status page will tell us.

---

## The Implementation

Run these commands from the project root:

```bash
pnpm db:generate
pnpm db:migrate
pnpm check
```

Important note:

If you already generated the migration earlier and did not change the schema, `pnpm db:generate` may say there are no schema changes.

That is fine.

Now start the app:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000/settings/database
```

---

## The Verification

Everything is working if:

- `pnpm db:generate` succeeds
- `pnpm db:migrate` succeeds
- `pnpm check` succeeds
- `/settings/database` shows `Connected`
- The organization row count is currently `0`

---

# 16. Commit the Database Foundation

## The Target

We are committing the database setup.

---

## The Concept

This is a major foundation change.

We added:

- Neon database connection
- Drizzle ORM
- Drizzle Kit config
- Initial schema
- Migration files
- Database client
- Database health diagnostics

That deserves a Git checkpoint.

---

## The Implementation

Run:

```bash
git status
```

You should see files like:

```txt
.env.example
app/settings/database/page.tsx
app/settings/page.tsx
db/index.ts
db/schema.ts
drizzle.config.ts
drizzle/0000_...
drizzle/meta/...
lib/database-health.ts
package.json
pnpm-lock.yaml
```

Confirm `.env.local` is **not** listed.

Now stage files:

```bash
git add .
```

Commit:

```bash
git commit -m "Set up Neon Postgres and Drizzle ORM"
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

## Error: `DATABASE_URL is missing`

Check:

```txt
.env.local
```

It must include:

```bash
DATABASE_URL="postgresql://..."
```

If you added it while the dev server was running, restart:

```bash
Ctrl + C
pnpm dev
```

---

## Error: Drizzle cannot find schema

Make sure this file exists:

```txt
db/schema.ts
```

And make sure `drizzle.config.ts` contains:

```ts
schema: "./db/schema.ts"
```

---

## Error: Migration generated but database page says table does not exist

You generated the migration but did not apply it.

Run:

```bash
pnpm db:migrate
```

Then reload:

```txt
/settings/database
```

---

## Error: Neon connection fails with SSL error

Make sure your `DATABASE_URL` includes:

```txt
sslmode=require
```

Example:

```bash
DATABASE_URL="postgresql://user:password@host/database?sslmode=require"
```

---

## Error: Password contains special characters

If your database password contains characters like:

```txt
@
:
/
?
#
&
```

they may need URL encoding.

For example:

```txt
@ becomes %40
# becomes %23
& becomes %26
```

The safest approach is to copy the connection string directly from Neon’s dashboard.

---

## Error: `pnpm db:migrate` says relation already exists

This usually means the table was created manually or migrations were partially applied.

For a brand-new tutorial database, the easiest fix is:

1. Create a fresh Neon branch or database.
2. Update `DATABASE_URL`.
3. Rerun:

```bash
pnpm db:migrate
```

Do not casually drop production tables.

---

## Error: `pnpm check` fails during build because of database variables

Now that the app has database-backed server pages, `DATABASE_URL` must be present during builds.

For local development, add it to:

```txt
.env.local
```

For Vercel later, we will add it to production environment variables.

---

## Error: Drizzle Studio cannot connect

Confirm:

```bash
pnpm db:migrate
```

works first.

Then run:

```bash
pnpm db:studio
```

If your network blocks the Studio URL, use Neon’s SQL editor instead.

---

# Phase 3 Reference — Database Vocabulary

## Postgres

Postgres is the relational database engine.

It stores tables, rows, indexes, constraints, and transactions.

---

## Neon

Neon is a hosted serverless Postgres platform.

It gives us a production-ready database without managing database servers manually.

---

## Drizzle ORM

Drizzle ORM is the TypeScript library we use in application code to query Postgres safely.

Example:

```ts
await db.select().from(organizations);
```

---

## Drizzle Kit

Drizzle Kit is the CLI tool that generates and runs migrations.

Commands:

```bash
pnpm db:generate
pnpm db:migrate
pnpm db:studio
```

---

## Schema

A schema defines the shape of database tables.

In this project, schema code lives in:

```txt
db/schema.ts
```

---

## Migration

A migration is a versioned SQL file that changes the database structure.

Generated migrations live in:

```txt
drizzle/
```

Commit migration files to Git.

---

## `DATABASE_URL`

`DATABASE_URL` tells the app how to connect to Postgres.

It is secret and must stay out of Git.

---

## Index

An index helps the database find rows faster.

We added indexes for:

```txt
clerk_organization_id
slug
```

The Clerk organization ID index is unique because each Clerk organization should map to only one local organization row.

---

# Part 6 Completion Checklist

You are ready for Part 7 if:

- [ ] Neon project exists
- [ ] `.env.local` contains `DATABASE_URL`
- [ ] `.env.example` documents `DATABASE_URL`
- [ ] `drizzle-orm` is installed
- [ ] `@neondatabase/serverless` is installed
- [ ] `drizzle-kit` is installed
- [ ] `dotenv` is installed
- [ ] `drizzle.config.ts` exists
- [ ] `db/schema.ts` defines the `organizations` table
- [ ] `db/index.ts` exports the Drizzle database client
- [ ] A migration was generated in `drizzle/`
- [ ] `pnpm db:migrate` applied the migration to Neon
- [ ] `lib/database-health.ts` exists
- [ ] `/settings/database` shows database connection status
- [ ] `/settings` links to database status
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
