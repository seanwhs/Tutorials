## Part 6: Getting a Free Database with Neon

Goal: create a free Neon Postgres database, understand the connection string, and add credentials to the project.

Prerequisite: Parts 1-5 completed.

---

### 1. Create a Neon account and project

1. Go to https://neon.tech, sign up (GitHub sign-in is fastest)
2. Click **Create a project**
3. Name it `qb-clone`
4. Accept the default Postgres version
5. Choose a region close to you
6. Click **Create Project**

### 2. Understand the connection string

On your project dashboard, find **Connection Details**. You'll see something like:
```
postgresql://neondb_owner:AbC123XyZ@ep-cool-forest-12345.us-east-1.aws.neon.tech/neondb?sslmode=require
```

Breaking it down: `neondb_owner` = username, `AbC123XyZ` = password, `ep-cool-forest-12345...` = server address, `neondb` = database name, `?sslmode=require` = encrypted connection.

### 3. Copy both pooled and unpooled connection strings

Look for a toggle labeled "Pooled connection" (hostname contains `-pooler`) and "Direct connection" (no `-pooler`). Copy both.

### 4. Add both to your project

Open `.env.local` in your `qb-clone` project (created in Part 4) and add two new lines at the end:

```
DATABASE_URL="postgresql://neondb_owner:AbC123XyZ@ep-cool-forest-12345-pooler.us-east-1.aws.neon.tech/neondb?sslmode=require"
DATABASE_URL_UNPOOLED="postgresql://neondb_owner:AbC123XyZ@ep-cool-forest-12345.us-east-1.aws.neon.tech/neondb?sslmode=require"
```

Replace with your real copied values.

### 5. Verify the connection using Neon's SQL Editor

In your Neon project dashboard, find **SQL Editor** in the sidebar. Type and run:
```sql
SELECT version();
```
Expected output: a row showing something like `PostgreSQL 16.4 on x86_64-pc-linux-gnu...`

Try a scratch test:
```sql
CREATE TABLE scratch_test (id serial primary key, note text);
INSERT INTO scratch_test (note) VALUES ('hello from Neon');
SELECT * FROM scratch_test;
DROP TABLE scratch_test;
```
You should see your inserted row printed by the `SELECT` before the `DROP TABLE` removes it.

### 6. Confirm .env.local still isn't tracked by git

```
git status
```
Confirm `.env.local` is NOT listed. If you have other small changes, commit them:
```
git add .
git commit -m "Prepare environment for Neon database connection"
```

---

### ✅ Checkpoint

- [ ] Neon account and project created
- [ ] `DATABASE_URL` and `DATABASE_URL_UNPOOLED` both set in `.env.local`
- [ ] `SELECT version();` ran successfully in Neon's SQL Editor
- [ ] `.env.local` confirmed NOT tracked by git

---

### Troubleshooting

**Neon project creation seems stuck / spinner never finishes**
Refresh the page after 30 seconds — project provisioning is usually near-instant, but occasionally the UI doesn't auto-update. Check your Neon dashboard's project list; if it's there, it worked.

**Can't find "Pooled connection" toggle**
Some Neon dashboard layouts show it as two separate copy-icon buttons instead of a toggle, sometimes labeled "Connection string" and a small pooling mode dropdown nearby (Pooled vs Direct). Look for the word "pooler" appearing in one of the two hostnames shown — that's the pooled one.

**`SELECT version();` gives a permissions or connection error in the SQL Editor**
This is Neon's own web-based editor talking to your own database — it should never fail due to your local setup. If it errors, try refreshing the Neon dashboard page, or check Neon's status page (status.neon.tech) for an outage.

**Pasted connection string into `.env.local` but it looks broken across multiple lines**
Connection strings are long but must be on ONE line. If your editor auto-wrapped the display, that's just visual — as long as you didn't manually press Enter in the middle of it, it's fine. Turn on VS Code's word-wrap (View menu -> Word Wrap) to display long lines without them looking broken.

**Quotes: should DATABASE_URL have quotes around it or not?**
Either works for Next.js's env loading, but be consistent — the examples in this course use double quotes around connection strings since they sometimes contain special characters (like `&` or `?`) that can otherwise confuse the shell in certain contexts. Keep the quotes as shown.

**Scratch test's `DROP TABLE` gives "table does not exist"**
This means the earlier `CREATE TABLE` line didn't actually run (maybe you ran statements out of order, or one at a time and skipped the CREATE). Re-run all four lines together in one query execution, top to bottom.
