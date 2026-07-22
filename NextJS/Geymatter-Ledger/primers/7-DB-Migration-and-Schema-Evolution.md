# Primer 7 — Database Migrations and Schema Evolution

**Product:** GreyMatter Ledger  
**Document type:** Primer  
**Audience:** Developers, technical founders, engineers new to database migrations  
**Goal:** Explain how database schema changes are managed safely in GreyMatter Ledger  

---

# 1. Why Database Migrations Matter

Applications change over time.

At first, GreyMatter Ledger only needed:

```txt
organizations
```

Then it needed:

```txt
accounts
journal_entries
journal_lines
customers
vendors
invoices
bills
payments
bank_transactions
audit_logs
```

Each new feature required database changes.

A database migration is a controlled, versioned change to the database schema.

Examples:

```txt
Create accounts table
Add invoice_status enum
Add journal reversal columns
Add audit_logs table
Add bank reconciliation fields
```

Without migrations, every developer and every environment can drift out of sync.

---

# 2. What Is a Schema?

A schema is the structure of the database.

It defines:

```txt
Tables
Columns
Data types
Enums
Indexes
Foreign keys
Constraints
```

In GreyMatter Ledger, the schema is defined in:

```txt
db/schema.ts
```

Example:

```ts
export const accounts = pgTable("accounts", {
  id: uuid("id").defaultRandom().primaryKey(),
  organizationId: uuid("organization_id").notNull(),
  code: text("code").notNull(),
  name: text("name").notNull(),
});
```

This TypeScript schema becomes SQL migrations.

---

# 3. What Is a Migration?

A migration is a file containing SQL changes.

Example:

```sql
CREATE TABLE "accounts" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "code" text NOT NULL,
  "name" text NOT NULL
);
```

Migrations are stored in:

```txt
drizzle/
```

They should be committed to Git.

---

# 4. Tooling Used

GreyMatter Ledger uses:

```txt
Drizzle ORM
Drizzle Kit
Neon Postgres
```

Important files:

```txt
db/schema.ts
db/index.ts
drizzle.config.ts
drizzle/
```

Important commands:

```bash
pnpm db:generate
pnpm db:migrate
pnpm db:studio
```

---

# 5. Migration Workflow

The normal migration workflow is:

```txt
1. Edit db/schema.ts
2. Generate migration
3. Review SQL
4. Apply migration
5. Test app
6. Commit schema and migration
```

In commands:

```bash
pnpm db:generate
pnpm db:migrate
pnpm check
git add .
git commit -m "Describe schema change"
```

---

# 6. Generate vs Migrate

## Generate

```bash
pnpm db:generate
```

This creates a migration file.

It does not change the database yet.

Think of it as:

```txt
Write renovation instructions.
```

---

## Migrate

```bash
pnpm db:migrate
```

This applies migration files to the database.

Think of it as:

```txt
Perform the renovation.
```

---

# 7. Drizzle Configuration

File:

```txt
drizzle.config.ts
```

Purpose:

```txt
Tell Drizzle where the schema is
Tell Drizzle where migrations go
Tell Drizzle how to connect to the database
```

Important configuration:

```ts
export default defineConfig({
  schema: "./db/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: {
    url: databaseUrl,
  },
});
```

Drizzle CLI loads:

```txt
DATABASE_URL
```

from:

```txt
.env.local
```

using:

```ts
config({ path: ".env.local" });
```

---

# 8. Environment Safety

Migrations run against the database pointed to by:

```txt
DATABASE_URL
```

Before running migrations, ask:

```txt
Which database am I connected to?
```

This is especially important for production.

Local development:

```bash
DATABASE_URL="dev_database"
```

Production:

```bash
DATABASE_URL="production_database"
```

Never accidentally run experimental migrations against production.

---

# 9. Production Migration Safety

Before applying production migrations:

```txt
Review generated SQL
Back up or branch database
Confirm migration is expected
Apply during low-risk window
Smoke test production after migration
```

For Neon, consider using branches before risky changes.

---

# 10. Additive vs Destructive Migrations

## Additive Migration

An additive migration adds things.

Examples:

```txt
Add table
Add nullable column
Add index
Add enum value carefully
```

Generally safer.

---

## Destructive Migration

A destructive migration removes or changes existing data.

Examples:

```txt
Drop table
Drop column
Change column type
Make nullable column required
Delete enum value
```

Dangerous in production.

Requires extra review.

---

# 11. Migration Review Checklist

Before applying a migration, inspect the SQL.

Ask:

```txt
Does it create expected tables?
Does it drop anything unexpectedly?
Does it modify data?
Does it add constraints that old data violates?
Does it create indexes with expected names?
Does it reference tables that exist?
Does it affect production data?
```

---

# 12. Common Schema Elements

## Tables

Example:

```ts
pgTable("customers", {
  id: uuid("id").defaultRandom().primaryKey(),
  name: text("name").notNull(),
});
```

---

## Enums

Example:

```ts
export const invoiceStatusEnum = pgEnum("invoice_status", [
  "draft",
  "sent",
  "paid",
  "void",
]);
```

---

## Indexes

Example:

```ts
index("invoices_organization_id_idx").on(table.organizationId)
```

Indexes improve query performance.

---

## Unique Indexes

Example:

```ts
uniqueIndex("accounts_organization_id_code_idx").on(
  table.organizationId,
  table.code,
)
```

This prevents duplicate account codes inside one organization.

---

## Foreign Keys

Example:

```ts
customerId: uuid("customer_id")
  .notNull()
  .references(() => customers.id, { onDelete: "restrict" })
```

Foreign keys protect relationships.

---

## Check Constraints

Example:

```ts
check(
  "invoices_total_matches_components_check",
  sql`${table.totalCents} = ${table.subtotalCents} + ${table.gstCents}`,
)
```

Check constraints enforce data integrity.

---

# 13. Schema Ordering

In Drizzle schema files, referenced tables should generally be declared before tables that reference them.

Safe order example:

```txt
enums
organizations
accounts
customers
vendors
journal_entries
journal_lines
invoices
invoice_lines
customer_payments
bills
bill_lines
vendor_payments
bank_imports
bank_transactions
audit_logs
recurring_invoices
```

If you see errors like:

```txt
Cannot access 'journalEntries' before initialization
```

reorder table definitions.

---

# 14. Tenant Columns in Migrations

Every organization-owned table should include:

```txt
organization_id
```

When adding a new business table, ask:

```txt
Does this belong to a company?
```

If yes, add:

```ts
organizationId: uuid("organization_id")
  .notNull()
  .references(() => organizations.id, { onDelete: "cascade" })
```

---

# 15. Money Columns in Migrations

Money should be stored as integer cents.

Use columns like:

```ts
bigint("amount_cents", { mode: "number" })
```

Examples:

```txt
subtotal_cents
gst_cents
total_cents
debit_cents
credit_cents
amount_cents
```

Avoid:

```txt
decimal dollars
floating-point numbers
```

---

# 16. Constraint Examples from GreyMatter Ledger

## Invoice Total Constraint

```txt
total_cents = subtotal_cents + gst_cents
```

## Bill Total Constraint

```txt
total_cents = subtotal_cents + gst_cents
```

## Journal Line Constraint

```txt
debit_cents >= 0
credit_cents >= 0
exactly one side is positive
```

## Payment Constraint

```txt
amount_cents > 0
```

These constraints catch bad data even if application code has a bug.

---

# 17. Migration Verification Queries

## List Tables

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

---

## List Columns

```sql
select
  column_name,
  data_type,
  is_nullable
from information_schema.columns
where table_name = 'invoices'
order by ordinal_position;
```

---

## List Indexes

```sql
select
  tablename,
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
order by tablename, indexname;
```

---

## List Constraints

```sql
select
  conname as constraint_name,
  conrelid::regclass as table_name,
  pg_get_constraintdef(oid) as definition
from pg_constraint
where connamespace = 'public'::regnamespace
order by table_name, constraint_name;
```

---

# 18. Common Migration Errors

## Error: `relation already exists`

Cause:

```txt
Table already exists.
Migration state may be out of sync.
```

Development fix:

```txt
Use fresh database or branch.
```

Production fix:

```txt
Investigate migration history carefully.
Do not drop tables casually.
```

---

## Error: `relation does not exist`

Cause:

```txt
Migration not applied.
Referenced table missing.
Wrong database.
```

Fix:

```bash
pnpm db:migrate
```

Check `DATABASE_URL`.

---

## Error: `type does not exist`

Cause:

```txt
Enum migration missing or not applied.
```

Fix:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: Column Missing

Cause:

```txt
Schema updated but migration not applied.
```

Fix:

```bash
pnpm db:migrate
```

---

# 19. Database Drift

Database drift means:

```txt
The real database schema differs from expected migrations.
```

Causes:

```txt
Manual SQL changes
Partially applied migrations
Different environments
Skipped migration files
```

Avoid manual production schema edits unless absolutely necessary.

---

# 20. Migrations and Git

Commit both:

```txt
db/schema.ts
drizzle/
```

Do not commit:

```txt
.env.local
```

A migration without schema changes is confusing.

A schema change without migration means other environments cannot update.

---

# 21. Safe Production Migration Process

Recommended process:

```txt
1. Create branch.
2. Edit schema.
3. Generate migration.
4. Review SQL.
5. Run tests locally.
6. Apply to staging/preview database.
7. Smoke test.
8. Apply to production database.
9. Deploy app.
10. Smoke test production.
```

For many changes, app deploy and migration order matters.

Example:

```txt
If app expects new column, migrate before deploying app.
```

---

# 22. Migration Order and App Code

Some deployments require sequencing.

## Additive Column

Usually safe:

```txt
Add nullable/default column
Deploy app
```

## Removing Column

Safer multi-step:

```txt
1. Deploy app that no longer uses column.
2. Confirm stable.
3. Drop column in later migration.
```

---

# 23. Accounting-Specific Migration Caution

Accounting migrations are sensitive.

Be extra careful with:

```txt
journal_entries
journal_lines
accounts
invoices
bills
payments
audit_logs
```

Avoid destructive changes to posted accounting data.

If a correction is needed, prefer:

```txt
new migration
data backfill
audit trail
reversal entries
```

---

# 24. Backfills

A backfill updates existing data after adding a new column.

Example:

```txt
Add currency column to invoices.
Set existing rows to SGD.
```

If the column has a default:

```ts
currency: text("currency").default("SGD").notNull()
```

Postgres can populate existing rows depending on migration behavior.

Review generated SQL.

---

# 25. Indexing Strategy

Indexes should support common queries.

Examples:

```txt
organization_id
organization_id + date
organization_id + status
organization_id + account_id
organization_id + invoice_number
```

Common index examples:

```txt
journal_entries_organization_id_entry_date_idx
journal_lines_organization_id_account_id_idx
invoices_organization_id_status_idx
bank_transactions_organization_id_status_idx
```

Do not over-index too early, but index obvious tenant/date/status lookups.

---

# 26. Schema Evolution Checklist for New Tables

When adding a new table:

```txt
Does it need organization_id?
Does it need created_at?
Does it need updated_at?
Does it need foreign keys?
Does it need status enum?
Does it need amount_cents fields?
Does it need constraints?
Does it need indexes?
Does it need audit logs?
Does it need migration tests/verification?
```

---

# 27. Schema Evolution Checklist for Money Columns

When adding money columns:

```txt
Use integer cents.
Use bigint where appropriate.
Add non-negative checks if negative values are invalid.
Add total consistency checks where needed.
Name with _cents suffix.
Add tests for calculations.
```

---

# 28. Schema Evolution Checklist for Accounting Features

When adding accounting-related tables:

```txt
Link source document to journal_entry_id.
Ensure organization_id exists.
Add status fields if workflow-based.
Add constraints for totals.
Add indexes for organization/status/date.
Preserve auditability.
Avoid destructive changes.
```

---

# 29. Running Migrations in Different Environments

## Local

```bash
pnpm db:migrate
```

Uses `.env.local`.

---

## Production

```bash
DATABASE_URL="production-url" pnpm db:migrate
```

PowerShell:

```powershell
$env:DATABASE_URL="production-url"
pnpm db:migrate
```

---

# 30. Final Migration Rules

If you remember only a few rules:

```txt
1. Review generated SQL before applying.
2. Never run migrations without knowing which DATABASE_URL is active.
3. Commit migrations with schema changes.
4. Avoid destructive changes to accounting data.
5. Verify production after migration.
```

Database migrations are not just code changes.

They are changes to the system of record.

Treat them carefully.
