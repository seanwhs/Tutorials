# Neon Tutorial - Appendix D: Neon CLI & SQL Cheat Sheet

## Installing & Authenticating `neonctl`

```bash
npm install -g neonctl
neonctl auth              # opens a browser to authenticate
neonctl me                # confirm who you're logged in as
```

## Project Commands

```bash
neonctl projects list
neonctl projects create --name my-project
neonctl projects get <project-id>
neonctl projects delete <project-id>
```

## Branch Commands

```bash
# List all branches in a project
neonctl branches list --project-id <project-id>

# Create a branch off main
neonctl branches create \
  --project-id <project-id> \
  --name dev/my-feature \
  --parent main

# Get the connection string for a specific branch
neonctl connection-string dev/my-feature --project-id <project-id>

# Reset a branch to match its parent (discard local changes)
neonctl branches reset dev/my-feature --parent --project-id <project-id>

# Delete a branch
neonctl branches delete dev/my-feature --project-id <project-id>
```

## Database & Role Commands

```bash
neonctl databases list --project-id <project-id> --branch main
neonctl roles list --project-id <project-id> --branch main
```

## Connecting with `psql`

```bash
# Direct connection (recommended for psql — no pooling needed for
# an interactive session)
psql "postgresql://neondb_owner:<password>@ep-xxxx.us-east-2.aws.neon.tech/neondb?sslmode=require"
```

```sql
\dt              -- list tables
\d notes         -- describe a table's columns
\l               -- list databases
\du              -- list roles
\q               -- quit
```

## Useful SQL Snippets

```sql
-- Confirm connection details
SELECT version();
SELECT current_database();
SELECT current_user;
```

```sql
-- Table size / row count sanity checks (helps track free-tier storage usage)
SELECT
  relname AS table_name,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

```sql
-- Add a useful index (Part 8)
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes (created_at DESC);
```

```sql
-- Basic CRUD reference used throughout the series
CREATE TABLE IF NOT EXISTS notes (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO notes (title, content) VALUES ('Hello', 'World') RETURNING *;
SELECT * FROM notes ORDER BY created_at DESC;
UPDATE notes SET title = 'Updated' WHERE id = 1;
DELETE FROM notes WHERE id = 1;
```

```sql
-- Clean up a test table
DROP TABLE IF EXISTS connection_test;
```

## Neon Management API (Direct HTTP, No CLI)

```bash
# List branches via raw API call (used by scripts/audit-branches.ts in Part 10)
curl -s \
  -H "Authorization: Bearer $NEON_API_KEY" \
  "https://console.neon.tech/api/v2/projects/$NEON_PROJECT_ID/branches" | jq
```

```bash
# Create a branch via API
curl -s -X POST \
  -H "Authorization: Bearer $NEON_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"branch": {"name": "dev/api-created"}}' \
  "https://console.neon.tech/api/v2/projects/$NEON_PROJECT_ID/branches" | jq
```

## Prisma Command Reference (Part 5)

```bash
pnpm dlx prisma init --datasource-provider postgresql
pnpm dlx prisma migrate dev --name <migration_name>   # dev — creates + applies
pnpm dlx prisma migrate deploy                         # CI/prod — applies only
pnpm dlx prisma studio                                 # GUI browser
pnpm dlx prisma generate                               # regenerate client
```

## Drizzle Command Reference (Part 6)

```bash
pnpm dlx drizzle-kit generate    # diff schema.ts -> new migration SQL file
pnpm dlx drizzle-kit migrate     # apply pending migrations
pnpm dlx drizzle-kit push        # push schema directly, no migration files (prototyping only)
pnpm dlx drizzle-kit studio      # GUI browser
```

## Quick Decision Reference

| I want to... | Use |
|---|---|
| Browse data visually | Neon console **Tables** tab, or `prisma studio` / `drizzle-kit studio` |
| Run one-off SQL quickly | Neon console **SQL Editor** |
| Script branch creation/deletion | `neonctl` or the Management API |
| Apply schema changes in CI | `prisma migrate deploy` or a Drizzle `migrate()` script (Part 7, Part 9) |
| Check free-tier usage | Neon console **Monitoring** tab, or `scripts/audit-branches.ts` (Part 10) |

**This concludes the Neon + Next.js 16 tutorial series.** 
