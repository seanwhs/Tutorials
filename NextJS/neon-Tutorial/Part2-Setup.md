# Neon Tutorial - Part 2: Creating a Free Neon Project & Connecting Locally

## 1. Sign Up (Free, No Credit Card)

1. Go to [console.neon.tech](https://console.neon.tech).
2. Sign up with GitHub, Google, or email — no credit card required for the free tier.
3. You'll be prompted to create your first **project**.

## 2. Create Your Project

Fill in the project creation form:

| Field | Value for this series |
|---|---|
| Project name | `neon-nextjs16-tutorial` |
| Postgres version | Latest available (17 at time of writing) |
| Region | Pick the region closest to you / your Vercel deployment region |
| Database name | `neondb` (default is fine) |

Click **Create Project**. Within a few seconds, Neon provisions:

- A project containing one branch named `main` (sometimes labeled `production`)
- A default compute endpoint attached to that branch
- A default database (`neondb`) and role (e.g. `neondb_owner`)

## 3. Get Your Connection Strings

On the project dashboard, click **Connect** (or "Connection Details"). Neon shows you a connection string. There are **two variants** — understanding the difference now avoids confusion in every later part:

```bash
# POOLED connection string — hostname contains "-pooler"
# Use this for your APPLICATION at runtime (Server Components,
# Server Actions, Route Handlers). Routed through Neon's built-in
# pgbouncer-style pooler, safe for many concurrent short-lived
# serverless connections.
DATABASE_URL="postgresql://neondb_owner:<password>@ep-xxxx-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require"

# DIRECT connection string — no "-pooler" in hostname.
# Use this for MIGRATIONS (Prisma Migrate, drizzle-kit) and any
# session-level Postgres feature (LISTEN/NOTIFY, advisory locks,
# long-lived transactions) that a pooled connection can't support.
DIRECT_URL="postgresql://neondb_owner:<password>@ep-xxxx.us-east-2.aws.neon.tech/neondb?sslmode=require"
```

> **Rule of thumb used throughout this series:** `DATABASE_URL` = pooled (runtime), `DIRECT_URL` = direct (migrations). Copy both now into a scratch file — you'll paste them into `.env.local` in Part 3.

## 4. Explore the Neon Console

Before writing any code, get familiar with three tabs in the console:

- **SQL Editor** — run raw SQL directly in the browser, no local client needed. Good for quick checks.
- **Tables** — a lightweight visual browser of your schema and rows (updates as you create tables in later parts).
- **Branches** — where you'll create/manage branches starting in Part 7.

## 5. Optional: Connect Locally with `psql`

If you have `psql` installed locally, you can connect directly:

```bash
# Uses the DIRECT connection string (psql doesn't need pooling)
psql "postgresql://neondb_owner:<password>@ep-xxxx.us-east-2.aws.neon.tech/neondb?sslmode=require"
```

```sql
-- Quick sanity check once connected
SELECT version();
SELECT current_database();
\dt   -- list tables (empty for now)
```

Don't have `psql`? Skip it — the Neon SQL Editor in the browser and your Next.js app (Part 4 onward) are all you actually need for this series.

## 6. Optional: Install the Neon CLI (`neonctl`)

Handy for scripting branch creation/deletion later (used heavily in Part 7):

```bash
npm install -g neonctl

# Authenticate (opens a browser)
neonctl auth

# Verify it works — lists your projects
neonctl projects list
```

```bash
# Quick example: list branches of a project
neonctl branches list --project-id <your-project-id>
```

See **Appendix D** for a full CLI cheat sheet.

## 7. Run Your First Query From the SQL Editor

In the Neon console's SQL Editor, run:

```sql
-- A simple table we'll reuse across the raw-driver, Prisma, and
-- Drizzle parts of this series (each part creates its own version,
-- but this proves the connection works end-to-end right now).
CREATE TABLE IF NOT EXISTS connection_test (
  id SERIAL PRIMARY KEY,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO connection_test (message) VALUES ('Hello from the Neon SQL Editor!');

SELECT * FROM connection_test;
```

You should see one row returned. That confirms your project and branch are live and queryable.

```sql
-- Clean up — later parts create their own schema via
-- migrations/drizzle-kit, so we don't want this lying around.
DROP TABLE connection_test;
```

## 8. Checkpoint

- [ ] Signed up for Neon (free, no credit card)
- [ ] Created a project named `neon-nextjs16-tutorial` with a `main` branch
- [ ] Copied both the **pooled** (`DATABASE_URL`) and **direct** (`DIRECT_URL`) connection strings somewhere safe
- [ ] Ran a test query in the SQL Editor and saw a row come back
- [ ] (Optional) Installed `neonctl` and confirmed `neonctl projects list` works

## Troubleshooting

| Problem | Fix |
|---|---|
| "password authentication failed" | Re-copy the connection string from the console — the password shown is only revealed once per session unless you click "reveal" again |
| `psql: error: connection requires SSL` | Ensure `?sslmode=require` is appended to the connection string |
| Can't find pooled vs direct toggle | In the Connect dialog, look for a "Pooled connection" checkbox/toggle — switching it changes the hostname between `ep-xxxx-pooler...` and `ep-xxxx...` |

## Next

**Part 3: Next.js 16 Project Setup & Environment Variables** — scaffold the app and wire up both connection strings safely with runtime validation.
