# Part 2: Secure Design — "Architecture is Security"

Picking up from Part 1: you have a documented threat model, 11 testable requirements, and a ranked list of risks. Now we design a system where — if one of those threats *does* get exploited — the blast radius is contained instead of catastrophic. This is the difference between a ship with one giant hull and a ship with watertight compartments: the same iceberg hits either one, but only one survives it.

**Goal recap:** design so one bug doesn't nuke everything.

---

## Step 1 — Document the Secure Architecture Patterns We'll Follow

### 🎯 The Target
`docs/ARCHITECTURE.md` — a design document naming the four architectural patterns SecureTrade commits to, and mapping each one to specific requirements from Part 1.

### 💡 The Concept
Four patterns, four everyday analogies:

- **Zero Trust** — "Never trust, always verify." A hotel doesn't give every guest a master key just because they're inside the building — every door, every time, checks the keycard. In our system, being *authenticated* (logged in) never automatically grants access to a *specific* resource; every layer re-checks.
- **Least Privilege** — Give people exactly the keys they need, nothing more. A hotel housekeeper's keycard opens guest rooms on their assigned floor, not the manager's office or the safe. Our `User` role gets exactly the database columns and API routes it needs — nothing else.
- **Defense in Depth** — Layers of independent protection, like a castle with a moat, a wall, and a locked gate. If an attacker somehow gets past input validation, parameterized queries still stop injection. If they somehow bypass client checks, server-side checks still catch it. No single layer is ever assumed to be "enough" on its own.
- **Secure Defaults** — The safest configuration is what you get automatically, without extra effort. A new employee badge should start with *zero* access and require explicit approval to gain more — not start with "everything" and require someone to remember to restrict it. Our database migrations, our roles, our error pages — all default to the most restrictive safe behavior.

### 🛠️ The Implementation

##### 📄 File: `docs/ARCHITECTURE.md`
```markdown
# SecureTrade — Secure Architecture

## Guiding Patterns

### 1. Zero Trust
No request is trusted based on where it came from or what it claims about
itself. Every layer independently re-verifies identity and permission.

Applied in SecureTrade:
- Middleware verifies session validity on every request (not just at login).
- Route handlers re-check the user's role from the database/session on
  every Admin/Auditor-only operation — never from a client-supplied field.
- The database itself enforces foreign key constraints and non-null
  requirements, so even a bug upstream can't silently corrupt referential
  integrity.

### 2. Least Privilege
Every actor (user role, database credential, API token) gets the minimum
access required to do its job — nothing more "just in case."

Applied in SecureTrade:
- Three roles only: `USER`, `ADMIN`, `AUDITOR` — each with a narrowly
  defined set of allowed operations (see RBAC matrix below).
- `AUDITOR` gets read-only access — enforced at the database query layer,
  not just hidden in the UI.
- The database connection string used by the running app uses Supabase's
  pooled connection with the minimum required Postgres role privileges
  (not the Postgres superuser).

### 3. Defense in Depth
Multiple independent layers of protection, so a failure in one layer does
not equal total compromise.

Applied in SecureTrade (layers, outside-in):
1. **Edge**: rate limiting + security headers (Part 6)
2. **Middleware**: session/auth check (Part 3)
3. **Input validation**: Zod schemas reject malformed input before it
   reaches business logic (Part 3)
4. **Authorization check**: role + ownership check in the route handler
   (Part 3)
5. **Parameterized queries**: Prisma ORM prevents injection at the query
   layer (this part + Part 3)
6. **Database constraints**: foreign keys, NOT NULL, unique constraints as
   a last-resort backstop (this part)

### 4. Secure Defaults
The out-of-the-box configuration is always the safest one; extra
permissions must be explicitly granted, never explicitly revoked.

Applied in SecureTrade:
- New users are created with role `USER` by default — `ADMIN`/`AUDITOR`
  must be explicitly assigned (see schema.prisma, Step 5).
- API routes deny access by default and only permit specific roles
  explicitly (Part 3's middleware).
- Database migrations never seed a default admin with a known password
  (see the seeding strategy in Step 6, which uses environment variables).

## RBAC Matrix

| Resource / Action              | User | Admin | Auditor |
|---------------------------------|:----:|:-----:|:-------:|
| View own portfolio               | ✅   | ✅    | ✅ (any user's) |
| Submit an order                  | ✅   | ❌    | ❌      |
| View market data                 | ✅   | ✅    | ✅      |
| Create/edit instruments          | ❌   | ✅    | ❌      |
| Manage user accounts             | ❌   | ✅    | ❌      |
| View any user's order history    | ❌   | ✅    | ✅      |
| View audit logs                  | ❌   | ✅    | ✅      |
| Modify audit logs                | ❌   | ❌    | ❌      |

Note: **nobody** can modify audit logs — not even Admin. This directly
implements REQ-08 (immutable audit trail) from Part 1 — an Admin who goes
rogue must not be able to cover their own tracks. This is Least Privilege
applied even to the most powerful role in the system.

## Requirement Traceability

| Pattern | Requirements Addressed |
|---|---|
| Zero Trust | REQ-05, REQ-06 |
| Least Privilege | REQ-05, REQ-06, REQ-09 |
| Defense in Depth | REQ-01, REQ-02, REQ-07, REQ-09 |
| Secure Defaults | REQ-05, REQ-08 |
```

### ✅ The Verification

```bash
grep -c "^###" docs/ARCHITECTURE.md
```
Expected output: `4` (confirms all four patterns are documented). Then eyeball the RBAC matrix — confirm the "Modify audit logs" row is `❌` across all three roles; this single cell is the detail we'll write an actual database-level test for in Part 3.

---

## Step 2 — Draw the Data Flow Diagram (Where Does PII Go?)

### 🎯 The Target
`docs/DATA-FLOW.md` plus `docs/diagrams/data-flow.drawio.png` — a diagram tracing exactly where PII (Personally Identifiable Information) enters, moves through, and could leak from SecureTrade.

### 💡 The Concept
A **Data Flow Diagram (DFD)** is different from the trust-boundary diagram in Part 1 — that one showed *components and boundaries*; this one follows a specific *piece of data* on its journey, like tracing a single dollar bill's path through a store: cash register → safe → bank deposit → ledger. If at any hop the bill could be handed to the wrong person, that's the leak point we need to design against.

We do this specifically for the two most sensitive data types identified in Part 1: **user PII** (email, name) and **financial data** (orders, balances).

### 🛠️ The Implementation

Build this diagram in the same draw.io project from Part 1 (or a new tab):

1. Draw a swimlane-style diagram with these numbered steps as boxes, connected by arrows, left to right:
   - `1. Registration Form (Browser)` → `2. POST /api/v1/auth/register` → `3. Zod validation (Server)` → `4. bcrypt hash password (Server)` → `5. INSERT INTO "User" (Supabase Postgres)`
2. Add a second row for the order flow:
   - `1. Order Form (Browser)` → `2. POST /api/v1/orders` → `3. Zod validation + ownership check (Server)` → `4. Server recalculates price (Server)` → `5. INSERT INTO "Order" (Supabase Postgres)` → `6. INSERT INTO "AuditLog" (Supabase Postgres)`
3. At each arrow, label with a small annotation: what data crosses that arrow, and its classification from `SYSTEM-OVERVIEW.md` (e.g., "email, name — PII" or "hashed password — Secret").
4. Mark with a red dot any hop where data would be classified more sensitively **downstream** than it needs to be — e.g., if the raw password ever appeared anywhere after step 3 (it shouldn't — that's exactly the point of drawing this).
5. Export as `docs/diagrams/data-flow.drawio.png` (and save the `.drawio` source alongside it), same as Part 1.

##### 📄 File: `docs/DATA-FLOW.md`
```markdown
# SecureTrade — Data Flow: PII and Financial Data

See `docs/diagrams/data-flow.drawio.png` for the visual version.

## Flow 1: User Registration (PII)

| Step | Component | Data Present | Classification |
|---|---|---|---|
| 1 | Browser registration form | email, name, plaintext password | PII, Secret |
| 2 | `POST /api/v1/auth/register` | same, over TLS | PII, Secret |
| 3 | Zod validation (server) | same, validated shape | PII, Secret |
| 4 | bcrypt hashing (server) | email, name, **hashed** password | PII, Secret (hash, not plaintext) |
| 5 | `INSERT INTO "User"` (Supabase) | email, name, password hash stored | PII, Secret |

**Design rule enforced:** plaintext password must never exist past Step 4,
and must never be logged, cached, or written to any table. This is why
hashing happens in the same server-side function that receives the
request — there is no intermediate step where plaintext could leak to a
log line (see REQ-01).

## Flow 2: Order Submission (Financial Data)

| Step | Component | Data Present | Classification |
|---|---|---|---|
| 1 | Browser order form | instrumentId, side, quantity, (client-suggested price — ignored) | Confidential |
| 2 | `POST /api/v1/orders` | same, over TLS | Confidential |
| 3 | Ownership + role check (server) | authenticated userId from session | Confidential |
| 4 | Server recalculates price from live instrument data | server-authoritative price | Confidential |
| 5 | `INSERT INTO "Order"` (Supabase) | full order record | Confidential |
| 6 | `INSERT INTO "AuditLog"` (Supabase) | actorId, action, timestamp | Confidential |

**Design rule enforced:** the client-submitted price field, if present, is
never read by the server for calculation — it exists in the request only
because the UI displays a quote to the user for confirmation. This
directly implements REQ-07 and closes threat T-006 from Part 1.

## Leak Points Identified and Closed

| Potential Leak Point | Mitigation |
|---|---|
| Plaintext password in logs | Never log request bodies for auth endpoints (Part 3 logging config) |
| Client-submitted price trusted | Server always recalculates (REQ-07) |
| Order record visible to non-owner | Row-level ownership check before every read (REQ-06) |
| Audit log editable/deletable | No `UPDATE`/`DELETE` permission granted on `AuditLog` table at the database role level (Step 5) |
```

### ✅ The Verification

```bash
ls docs/diagrams/data-flow.drawio.png
grep -c "^## Flow" docs/DATA-FLOW.md
```
Expected: the file listing succeeds, and the grep returns `2`.

---

## Step 3 — Create the Supabase Project and Configure Secrets Properly

### 🎯 The Target
A live Supabase Postgres database, with connection credentials stored in a git-ignored `.env.local` file — never committed — and a documented `.env.example` template for teammates (and future-you).

### 💡 The Concept
A database connection string is like the master key to your building — anyone holding it can read or write everything. Committing it to Git is like taping a photo of that key to the building's public noticeboard: even if you delete the photo later, anyone who saw it (or anyone browsing your Git history) still has it forever. That's why secrets live only in `.env.local` (which Next.js's default `.gitignore` already excludes from version control) and never in any file Git tracks.

We also use two different connection strings — a **pooled** connection for the running app, and a **direct** connection for migrations — because serverless environments (like Vercel, which we deploy to in Part 6) open far more simultaneous database connections than a traditional server would, and Postgres has a hard limit on how many connections it can hold open at once. A **connection pooler** (Supabase uses PgBouncer) sits in front of the database and shares a small set of real connections across many app requests — like a restaurant host seating many customers at a limited number of tables by turning tables over quickly, instead of needing one table permanently reserved per customer.

### 🛠️ The Implementation

1. Go to your Supabase dashboard (created in Part 0) → **New Project**.
2. Name it `securetrade`, choose a strong database password (generate one, don't type your own — click **Generate a password** in the UI), select the Singapore region (`ap-southeast-1`) since our compliance context is Singapore-based, and click **Create new project**.
3. Once provisioned, go to **Project Settings → Database → Connection String**.
4. Copy the **Transaction pooler** string (port `6543`) — this becomes `DATABASE_URL`.
5. Copy the **Direct connection** string (port `5432`) — this becomes `DIRECT_URL`.

Confirm `.env.local` is already ignored (Next.js scaffolds this automatically in Part 1's `create-next-app`, but verify it):

```bash
grep -E "^\.env" .gitignore
```
Expected output should include lines like `.env*.local`.

Now create the two environment files:

##### 📄 File: `.env.local` (⚠️ never commit this — already git-ignored)
```bash
# Pooled connection (via PgBouncer) — used by the running application.
# pgbouncer=true tells Prisma not to use features PgBouncer doesn't support
# (like prepared statement caching), avoiding hard-to-debug connection errors.
DATABASE_URL="postgresql://postgres.xxxxxxxx:YOUR-DB-PASSWORD@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true"

# Direct connection — used only for running migrations, which need a
# persistent, non-pooled connection to apply schema changes safely.
DIRECT_URL="postgresql://postgres.xxxxxxxx:YOUR-DB-PASSWORD@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres"

# Used only by scripts/seed.ts (Step 6) — plaintext seed passwords for local
# test accounts. Real user passwords are NEVER stored this way; this is
# strictly for creating throwaway dev/test accounts.
SEED_ADMIN_PASSWORD="ChangeThisAdminPassLocally123!"
SEED_AUDITOR_PASSWORD="ChangeThisAuditorPassLocally123!"
SEED_USER_PASSWORD="ChangeThisUserPassLocally123!"
```

##### 📄 File: `.env.example` (✅ this one IS committed — it's a template, not a secret)
```bash
# Copy this file to .env.local and fill in real values.
# See docs/ARCHITECTURE.md for why two separate connection strings exist.

DATABASE_URL="postgresql://USER:PASSWORD@HOST:6543/postgres?pgbouncer=true"
DIRECT_URL="postgresql://USER:PASSWORD@HOST:5432/postgres"

SEED_ADMIN_PASSWORD="set-a-strong-local-only-password"
SEED_AUDITOR_PASSWORD="set-a-strong-local-only-password"
SEED_USER_PASSWORD="set-a-strong-local-only-password"
```

### ✅ The Verification

```bash
# Confirm .env.local is genuinely ignored by Git — this command should
# print the filename back, confirming Git recognizes it as ignored.
git check-ignore -v .env.local
```
Expected output: something like `.gitignore:34:.env*.local	.env.local`. If this prints **nothing**, stop immediately — that means `.env.local` would be committed, and you must fix `.gitignore` before proceeding.

```bash
git status
```
Confirm `.env.local` does **not** appear in the list of files to be committed, while `.env.example` does.

---

## Step 4 — Install and Configure Prisma

### 🎯 The Target
Prisma installed and initialized, with `prisma/schema.prisma` pointed at the Supabase connection strings from Step 3.

### 💡 The Concept
**Prisma** is an ORM (Object-Relational Mapper) — a translator between TypeScript code and SQL. Instead of hand-writing SQL strings (which is exactly how SQL injection vulnerabilities like T-007 from Part 1 happen), you write `prisma.user.findUnique({ where: { id } })` and Prisma generates a safe, parameterized SQL query behind the scenes. Think of it like ordering food from a menu with numbered items instead of shouting your order into the kitchen in freeform text — the "menu" (Prisma's typed API) makes it structurally impossible to accidentally order something that wasn't on the menu.

### 🛠️ The Implementation

```bash
npm install prisma @prisma/client
npx prisma init
```

This creates `prisma/schema.prisma` and a `.env` reference. Since we already have `.env.local` from Step 3 (which Next.js conventions prefer), configure Prisma to read from it explicitly rather than relying on the default `.env`:

```bash
npm install -D dotenv-cli
```

##### 📄 File: `package.json` (edit — add/update these entries)
```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "dread": "tsx scripts/dread-score.ts",
    "verify:part1": "tsx scripts/verify-part1.ts",
    "verify:part2": "tsx scripts/verify-part2.ts",
    "db:migrate": "dotenv -e .env.local -- prisma migrate dev",
    "db:seed": "dotenv -e .env.local -- tsx prisma/seed.ts",
    "db:studio": "dotenv -e .env.local -- prisma studio"
  },
  "prisma": {
    "seed": "dotenv -e .env.local -- tsx prisma/seed.ts"
  }
}
```

##### 📄 File: `prisma/schema.prisma` (initial datasource block — we add models in Step 5)
```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider  = "postgresql"
  // url is the pooled connection — used at runtime by the deployed app.
  url       = env("DATABASE_URL")
  // directUrl is used only when running migrations, which require a
  // stable, non-pooled connection (see Step 3's explanation).
  directUrl = env("DIRECT_URL")
}
```

### ✅ The Verification

```bash
npx dotenv -e .env.local -- npx prisma validate
```
Expected output:
```
The schema at prisma/schema.prisma is valid 🚀
```

---

## Step 5 — Design the RBAC Data Model

### 🎯 The Target
The complete `prisma/schema.prisma`, defining `User` (with a `Role` enum), `Instrument`, `Order`, `Holding`, and `AuditLog` — the concrete database implementation of the RBAC matrix from Step 1.

### 💡 The Concept
A **schema** is the blueprint of every "room" in our database and the rules for what can go in each one — like architectural blueprints specifying that the bathroom has a water line and the bedroom doesn't, *by construction*, not by someone remembering not to plumb the bedroom. We encode as many security rules as possible directly into the schema shape itself (an `enum` that only allows 3 specific role strings; a `@unique` constraint that makes duplicate idempotency keys structurally impossible) — because a rule enforced by the database can't be forgotten by a future developer the way a rule enforced only by "remembering to check in the code" can.

### 🛠️ The Implementation

##### 📄 File: `prisma/schema.prisma` (complete file)
```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL")
}

// Only these three strings can ever be stored in the `role` column.
// This is Secure Defaults + Least Privilege enforced at the type level —
// it is literally impossible to insert an invalid role like "SUPERADMIN".
enum Role {
  USER
  ADMIN
  AUDITOR
}

enum OrderSide {
  BUY
  SELL
}

enum OrderStatus {
  PENDING
  FILLED
  REJECTED
}

model User {
  id           String   @id @default(cuid())
  email        String   @unique
  name         String
  // Never store plaintext passwords. This column holds a bcrypt hash only
  // (enforced in application code in Part 3 — the schema can't force
  // "is bcrypt", but naming it passwordHash, not password, keeps intent
  // unmistakable to every future developer reading this file).
  passwordHash String

  // Defaults to the LEAST privileged role. Elevating to ADMIN/AUDITOR is
  // always an explicit, separate, audited action — never the default.
  role         Role     @default(USER)

  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  orders       Order[]
  holdings     Holding[]
  // An Admin/Auditor performs actions; a User's own account can also be the
  // TARGET of an audit log entry (e.g., "Admin X changed User Y's role").
  // These are two different relations, so we name them distinctly below.
  actionsPerformed AuditLog[] @relation("ActorRelation")

  @@index([role]) // speeds up "list all Admins" / "list all Auditors" queries
}

// Market data. Classified PUBLIC in SYSTEM-OVERVIEW.md — safe to read
// without authentication, which is why it has no ownership/userId field.
model Instrument {
  id           String    @id @default(cuid())
  symbol       String    @unique // e.g. "D05" for DBS on SGX
  name         String    // e.g. "DBS Group Holdings Ltd"
  currentPrice Decimal   @db.Decimal(12, 4)
  updatedAt    DateTime  @updatedAt

  orders       Order[]
  holdings     Holding[]
}

model Order {
  id             String      @id @default(cuid())

  userId         String
  user           User        @relation(fields: [userId], references: [id], onDelete: Cascade)

  instrumentId   String
  instrument     Instrument  @relation(fields: [instrumentId], references: [id])

  side           OrderSide
  quantity       Int
  // This is the SERVER-CALCULATED price at the moment of execution — never
  // a value trusted directly from the client. See docs/DATA-FLOW.md Flow 2
  // and REQ-07. Application code (Part 3) is responsible for populating
  // this correctly; the schema names it clearly to make the intent obvious.
  executedPrice  Decimal     @db.Decimal(12, 4)
  status         OrderStatus @default(PENDING)

  // Implements API idempotency (see docs/API-DESIGN.md, Step 7). A UNIQUE
  // constraint means the database itself physically rejects a duplicate
  // order caused by a retried request — this is a Defense in Depth layer
  // that works even if the application-level idempotency check has a bug.
  idempotencyKey String      @unique

  createdAt      DateTime    @default(now())

  @@index([userId])       // fast "get my orders" queries
  @@index([instrumentId]) // fast "get all orders for this stock" queries
}

// A user's current holdings per instrument — this is what "portfolio"
// means in SYSTEM-OVERVIEW.md. Kept as its own table (rather than derived
// by summing Order rows on every read) for query performance at scale.
model Holding {
  id           String     @id @default(cuid())

  userId       String
  user         User       @relation(fields: [userId], references: [id], onDelete: Cascade)

  instrumentId String
  instrument   Instrument @relation(fields: [instrumentId], references: [id])

  quantity     Int
  updatedAt    DateTime   @updatedAt

  // A user can only ever have ONE holding row per instrument — enforced by
  // the database, not just application logic.
  @@unique([userId, instrumentId])
}

// Implements REQ-08 (immutable audit trail) from Part 1. Note there is
// deliberately NO code anywhere in this application that performs an
// UPDATE or DELETE against this table — see docs/ARCHITECTURE.md's RBAC
// matrix ("Modify audit logs" = ❌ for every role, including Admin).
model AuditLog {
  id        String   @id @default(cuid())

  actorId   String
  actor     User     @relation("ActorRelation", fields: [actorId], references: [id])

  // e.g. "ORDER_PLACED", "USER_ROLE_CHANGED", "INSTRUMENT_CREATED"
  action    String

  // What was acted upon — kept as loosely-typed strings (rather than a
  // foreign key) because a single audit log table needs to reference many
  // different kinds of targets (users, orders, instruments) without
  // needing a separate audit table per entity type.
  targetType String
  targetId   String

  // Arbitrary structured detail about the action, e.g. { "oldRole": "USER",
  // "newRole": "ADMIN" }. Postgres's native JSON type keeps this queryable.
  metadata  Json?

  createdAt DateTime @default(now())

  @@index([actorId])
  @@index([targetType, targetId])
}
```

### ✅ The Verification

```bash
npx dotenv -e .env.local -- npx prisma validate
npx dotenv -e .env.local -- npx prisma format
```
Expected: `The schema at prisma/schema.prisma is valid 🚀` again, and `prisma format` should report no changes needed if you copied the file exactly (it auto-aligns spacing — harmless if it adjusts whitespace).

---

## Step 6 — Run the Migration and Seed Role-Based Test Accounts

### 🎯 The Target
The schema from Step 5 applied to your real Supabase database, plus `prisma/seed.ts` creating one test account per role (`USER`, `ADMIN`, `AUDITOR`) and a couple of sample instruments.

### 💡 The Concept
A **migration** is a recorded, versioned set of instructions for how to change a database's structure — like a construction change-order log for a building, so anyone can see exactly what was modified, when, and in what order, and rebuild the same structure from scratch elsewhere. We use `prisma migrate dev` rather than manually running SQL in Supabase's UI, because manual changes leave no trail — directly undermining the same non-repudiation principle we designed `AuditLog` to protect (Step 5).

Seeding creates known test accounts for development — but notice every password comes from `.env.local` (Step 3), never hardcoded in the seed script itself. This matters because seed scripts are committed to Git; if a password were hardcoded here, it would suffer the exact same "photo on the noticeboard" problem as a committed `.env` file.

### 🛠️ The Implementation

```bash
npm install bcryptjs
npm install -D @types/bcryptjs
```

We use `bcryptjs` (a pure-JavaScript implementation) rather than `bcrypt` (which requires native compilation) specifically because it installs reliably across every OS and in serverless build environments (relevant again in Part 6) without native-binary build failures.

##### 📄 File: `prisma/seed.ts`
```typescript
// prisma/seed.ts
//
// Populates the database with one test account per role, plus sample
// market instruments. Run via `npm run db:seed`. Safe to re-run — it uses
// upsert (update-or-insert) so it never creates duplicate rows.

import { PrismaClient, Role } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

// A cost factor of 12 is the current OWASP-recommended minimum for bcrypt —
// high enough to make brute-forcing meaningfully slow, low enough not to
// noticeably slow down legitimate logins. We'll reuse this exact constant
// in the real registration code in Part 3, so it's defined once here as
// the canonical reference value.
const BCRYPT_COST_FACTOR = 12;

async function hashPassword(plaintext: string): Promise<string> {
  return bcrypt.hash(plaintext, BCRYPT_COST_FACTOR);
}

// Reads a required environment variable, or throws immediately — this is
// far safer than silently falling back to a hardcoded default password,
// which is exactly the kind of "secure default" failure Part 1's threat
// model warns about (T-001).
function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Missing required environment variable: ${name}. Check .env.local (see .env.example).`
    );
  }
  return value;
}

async function main() {
  const adminPassword = await hashPassword(requireEnv("SEED_ADMIN_PASSWORD"));
  const auditorPassword = await hashPassword(requireEnv("SEED_AUDITOR_PASSWORD"));
  const userPassword = await hashPassword(requireEnv("SEED_USER_PASSWORD"));

  const admin = await prisma.user.upsert({
    where: { email: "admin@securetrade.test" },
    update: {},
    create: {
      email: "admin@securetrade.test",
      name: "Alice Admin",
      passwordHash: adminPassword,
      role: Role.ADMIN,
    },
  });

  const auditor = await prisma.user.upsert({
    where: { email: "auditor@securetrade.test" },
    update: {},
    create: {
      email: "auditor@securetrade.test",
      name: "Aidan Auditor",
      passwordHash: auditorPassword,
      role: Role.AUDITOR,
    },
  });

  const user = await prisma.user.upsert({
    where: { email: "user@securetrade.test" },
    update: {},
    create: {
      email: "user@securetrade.test",
      name: "Uma User",
      passwordHash: userPassword,
      role: Role.USER,
    },
  });

  // Sample instruments so we have something to place orders against later.
  const dbs = await prisma.instrument.upsert({
    where: { symbol: "D05" },
    update: {},
    create: {
      symbol: "D05",
      name: "DBS Group Holdings Ltd",
      currentPrice: 42.5,
    },
  });

  const singtel = await prisma.instrument.upsert({
    where: { symbol: "Z74" },
    update: {},
    create: {
      symbol: "Z74",
      name: "Singapore Telecommunications Ltd",
      currentPrice: 2.87,
    },
  });

  console.log("Seed complete:");
  console.log({
    admin: admin.email,
    auditor: auditor.email,
    user: user.email,
    instruments: [dbs.symbol, singtel.symbol],
  });
}

main()
  .catch((e) => {
    console.error("Seed failed:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

Now run the migration, then the seed:

```bash
npm run db:migrate -- --name init_rbac_schema
npm run db:seed
```

### ✅ The Verification

```bash
npm run db:studio
```

This opens Prisma Studio at `http://localhost:5555` — a visual database browser. Confirm:
1. The `User` table has exactly 3 rows, with `role` values `ADMIN`, `AUDITOR`, `USER` respectively.
2. The `Instrument` table has 2 rows (`D05`, `Z74`).
3. Every `passwordHash` value looks like `$2a$12$...` (a bcrypt hash) — **never** plaintext.

Close Prisma Studio (`Ctrl+C`), then confirm the migration file was actually recorded in Git:
```bash
ls prisma/migrations/
```
You should see a timestamped folder like `20250101000000_init_rbac_schema/` containing a `migration.sql` file — this is your permanent, reviewable change log.

---

## Step 7 — Define API Design Conventions (Versioning, Idempotency, Rate Limiting)

### 🎯 The Target
`docs/API-DESIGN.md` — the conventions every API route built in Part 3 onward must follow, plus a mapping to the OWASP API Security Top 10.

### 💡 The Concept
Three ideas, three analogies:

- **Versioning** (`/api/v1/...`) is like printing "Edition 1" on a textbook. When you later need to change how an endpoint behaves in a breaking way, you publish `/api/v2/...` instead of silently rewriting Edition 1 — so anyone still relying on the old edition (a mobile app that hasn't updated, a partner integration) doesn't break without warning.
- **Idempotency** means "doing it twice has the same effect as doing it once." Think of an elevator call button — mashing it five times doesn't summon five elevators. We already built the database-level guarantee for this in Step 5 (`idempotencyKey String @unique` on `Order`) — this section documents the *contract* the API makes with clients about how to use it: the client generates a unique key per logical order attempt and sends it in a header; if a network hiccup causes the client to retry, the same key reaches the server twice, and the server recognizes the duplicate instead of double-executing the trade.
- **Rate limiting** is a bouncer counting people at a door — past a certain number of requests per minute from the same source, further requests get politely turned away, protecting the system from being overwhelmed (this directly closes threat T-004 from Part 1). We document the *design* here; the actual middleware implementation happens in Part 3, once we have Next.js middleware and real routes to attach it to.

### 🛠️ The Implementation

##### 📄 File: `docs/API-DESIGN.md`
```markdown
# SecureTrade — API Design Conventions

## Versioning
All API routes are prefixed `/api/v1/...`. A breaking change to any
endpoint's request/response shape requires introducing `/api/v2/...`
rather than modifying `/api/v1/...` in place. Non-breaking changes
(adding an optional field) may be made within a version.

Route inventory planned for Part 3:
| Route | Method | Role Required |
|---|---|---|
| `/api/v1/auth/register` | POST | Public |
| `/api/v1/auth/login` | POST | Public |
| `/api/v1/orders` | POST | USER |
| `/api/v1/orders` | GET | USER (own), ADMIN/AUDITOR (any) |
| `/api/v1/instruments` | GET | Public |
| `/api/v1/instruments` | POST | ADMIN |
| `/api/v1/admin/users` | GET, PATCH | ADMIN |
| `/api/v1/audit-logs` | GET | ADMIN, AUDITOR |

## Idempotency
Any endpoint that creates a financial side effect (currently: `POST
/api/v1/orders`) requires an `Idempotency-Key` request header, a
client-generated UUID unique per logical attempt.

Contract:
1. Client generates a UUID once per "submit order" click.
2. Client sends it as `Idempotency-Key: <uuid>`.
3. Server stores it in `Order.idempotencyKey` (UNIQUE constraint, see
   `prisma/schema.prisma`).
4. If a request arrives with a key that already exists, the server returns
   the ALREADY-CREATED order's data with HTTP 200, instead of creating a
   second order or erroring.
5. If the client retries with a network timeout but the first request
   actually succeeded server-side, the retry is safely absorbed — the
   trade executes exactly once.

## Rate Limiting (design — implemented in Part 3)
| Endpoint | Limit | Scope |
|---|---|---|
| `POST /api/v1/auth/login` | 5 requests / 5 min | per IP + per email |
| `POST /api/v1/auth/register` | 10 requests / hour | per IP |
| `POST /api/v1/orders` | 20 requests / min | per authenticated user |
| All other routes | 100 requests / min | per IP |

Algorithm: token bucket (see Reference section below for how this works).

## OWASP API Security Top 10 — Mapping to Our Design

| # | Risk | How SecureTrade Addresses It |
|---|---|---|
| API1 | Broken Object Level Authorization | Every record fetch checks ownership or role (REQ-06); enforced again in Part 3 code |
| API2 | Broken Authentication | bcrypt hashing, rate-limited login, session expiry (REQ-01, REQ-02) |
| API3 | Broken Object Property Level Authorization | Zod schemas (Part 3) whitelist exactly which fields a role may set — e.g. a User can never set their own `role` field |
| API4 | Unrestricted Resource Consumption | Rate limiting (above), pagination on list endpoints (Part 3) |
| API5 | Broken Function Level Authorization | Role checked server-side on every Admin/Auditor route (REQ-05) |
| API6 | Unrestricted Access to Sensitive Business Flows | Idempotency keys + rate limits on order submission |
| API7 | Server-Side Request Forgery (SSRF) | No user-supplied URLs are ever fetched server-side in this app's design; flagged as a standing constraint for all future features |
| API8 | Security Misconfiguration | Secure Defaults pattern (docs/ARCHITECTURE.md); security headers in Part 6 |
| API9 | Improper Inventory Management | This very table + the route inventory above, kept up to date every part |
| API10 | Unsafe Consumption of APIs | Any future third-party API responses will be validated with Zod before use, never trusted blindly |
```

### ✅ The Verification

```bash
grep -c "^| API" docs/API-DESIGN.md
```
Expected output: `10` (all ten OWASP API Security risks are mapped).

---

## Step 8 — Automate Verification of Part 2's Artifacts

### 🎯 The Target
`scripts/verify-part2.ts` — extends the Part 1 verification pattern to check the schema, environment configuration, and design documents from this part.

### 💡 The Concept
Same building-inspector idea as Part 1's Step 8 — but now we're inspecting both documents *and* a real database schema. This script becomes noticeably more valuable now, because it can catch a genuinely dangerous mistake: accidentally committing `.env.local`. Confirming that automatically, on every check, is far more reliable than remembering to eyeball `git status` every time.

### 🛠️ The Implementation

##### 📄 File: `scripts/verify-part2.ts`
```typescript
// scripts/verify-part2.ts
//
// Verifies Part 2 deliverables: architecture docs, data flow docs, API
// design docs, the Prisma schema's RBAC shape, and — critically — that no
// secrets have been accidentally committed to Git.

import { existsSync, readFileSync } from "node:fs";
import { execSync } from "node:child_process";
import { join } from "node:path";

type Check = { label: string; pass: boolean; detail?: string };
const checks: Check[] = [];

function fileExists(relativePath: string): boolean {
  return existsSync(join(process.cwd(), relativePath));
}

function readDoc(relativePath: string): string {
  return readFileSync(join(process.cwd(), relativePath), "utf-8");
}

function main() {
  const requiredFiles = [
    "docs/ARCHITECTURE.md",
    "docs/DATA-FLOW.md",
    "docs/API-DESIGN.md",
    "docs/diagrams/data-flow.drawio.png",
    "prisma/schema.prisma",
    "prisma/seed.ts",
    ".env.example",
  ];

  for (const f of requiredFiles) {
    checks.push({ label: `File exists: ${f}`, pass: fileExists(f) });
  }

  // Critical secrets check: .env.local must be git-ignored. We use
  // `git check-ignore` and treat a non-zero exit code (meaning "NOT
  // ignored") as an automatic hard failure, regardless of any other check.
  let envIgnored = false;
  try {
    execSync("git check-ignore -q .env.local", { stdio: "ignore" });
    envIgnored = true; // exit code 0 means it IS ignored
  } catch {
    envIgnored = false; // non-zero exit code means it is NOT ignored — danger
  }
  checks.push({
    label: ".env.local is git-ignored (not trackable)",
    pass: envIgnored,
  });

  // Confirm .env.local is not currently staged/tracked, as a second
  // independent check using a different git command.
  let envTracked = true;
  try {
    execSync("git ls-files --error-unmatch .env.local", { stdio: "ignore" });
    envTracked = true; // no error means it IS tracked — bad
  } catch {
    envTracked = false; // error means it is NOT tracked — good
  }
  checks.push({
    label: ".env.local is not tracked by Git",
    pass: !envTracked,
  });

  if (fileExists("prisma/schema.prisma")) {
    const schema = readDoc("prisma/schema.prisma");

    checks.push({
      label: "Role enum defines exactly USER, ADMIN, AUDITOR",
      pass:
        /enum Role\s*{\s*USER\s*ADMIN\s*AUDITOR\s*}/.test(
          schema.replace(/\r/g, "")
        ) || (schema.includes("USER") && schema.includes("ADMIN") && schema.includes("AUDITOR") && schema.includes("enum Role")),
    });

    checks.push({
      label: "User.role defaults to USER (secure default)",
      pass: /role\s+Role\s+@default\(USER\)/.test(schema),
    });

    checks.push({
      label: "Order.idempotencyKey is unique",
      pass: /idempotencyKey\s+String\s+@unique/.test(schema),
    });

    checks.push({
      label: "AuditLog model exists",
      pass: /model AuditLog\s*{/.test(schema),
    });
  }

  if (fileExists("docs/API-DESIGN.md")) {
    const apiDesign = readDoc("docs/API-DESIGN.md");
    const apiRows = apiDesign.match(/^\| API\d{1,2}/gm) ?? [];
    checks.push({
      label: "All 10 OWASP API Security risks are mapped",
      pass: apiRows.length === 10,
      detail: `found ${apiRows.length}`,
    });
  }

  console.log("\nSecureTrade — Part 2 Verification\n");
  let allPassed = true;
  for (const c of checks) {
    const icon = c.pass ? "✅" : "❌";
    console.log(`${icon} ${c.label}${c.detail ? ` (${c.detail})` : ""}`);
    if (!c.pass) allPassed = false;
  }

  console.log(
    allPassed
      ? "\nAll Part 2 checks passed. Ready for Part 3.\n"
      : "\nSome checks failed — fix the items above before continuing.\n"
  );

  process.exit(allPassed ? 0 : 1);
}

main();
```

### ✅ The Verification

```bash
npm run verify:part2
```

Expected output:
```
SecureTrade — Part 2 Verification

✅ File exists: docs/ARCHITECTURE.md
✅ File exists: docs/DATA-FLOW.md
✅ File exists: docs/API-DESIGN.md
✅ File exists: docs/diagrams/data-flow.drawio.png
✅ File exists: prisma/schema.prisma
✅ File exists: prisma/seed.ts
✅ File exists: .env.example
✅ .env.local is git-ignored (not trackable)
✅ .env.local is not tracked by Git
✅ Role enum defines exactly USER, ADMIN, AUDITOR
✅ User.role defaults to USER (secure default)
✅ Order.idempotencyKey is unique
✅ AuditLog model exists
✅ All 10 OWASP API Security risks are mapped

All Part 2 checks passed. Ready for Part 3.
```

Commit everything (Git will correctly skip `.env.local`):

```bash
git add -A
git commit -m "feat: secure architecture docs, RBAC schema, Supabase integration, API design conventions"
git push
```

---

## ✅ Part 2 Completion Checklist

- [ ] `docs/ARCHITECTURE.md` documents Zero Trust, Least Privilege, Defense in Depth, Secure Defaults + RBAC matrix
- [ ] `docs/DATA-FLOW.md` + diagram trace PII and financial data through 2 real flows
- [ ] Supabase project created; `.env.local` populated and confirmed git-ignored
- [ ] `prisma/schema.prisma` models `User`/`Role`, `Instrument`, `Order`, `Holding`, `AuditLog`
- [ ] Migration applied; `npm run db:seed` created 3 role-based test accounts
- [ ] `docs/API-DESIGN.md` documents versioning, idempotency, rate limits, and OWASP API Top 10 mapping
- [ ] `npm run verify:part2` exits all green

---

# 📚 Reference Section — Deep Dives for Part 2

### R1. Zero Trust — Beyond the Basics

Zero Trust is often summarized as "never trust, always verify," but the full model (as formalized in NIST SP 800-207) rests on these tenets:
- Every access request is evaluated per-session, not granted once and cached forever.
- Trust is dynamic — computed from identity, device state, and context (e.g., "logged in from an unrecognized device" might warrant extra verification, even for a valid session — a concept we'll touch on with MFA in Part 3).
- Resources (APIs, databases) enforce their own policy, rather than relying entirely on a network perimeter (firewall) to keep attackers out — because once an attacker is inside the perimeter (e.g., via a stolen employee laptop), a perimeter-only model offers zero further resistance.

### R2. Defense in Depth — Why Redundant Controls Aren't Wasteful

A common junior-engineer objection: "we already validate with Zod, why *also* use parameterized queries — isn't that redundant?" The answer is that Defense in Depth assumes **any single layer can fail** — a Zod schema might have a gap you didn't think of, a code review might miss a raw SQL string slipped in during a rushed hotfix. Independent layers fail independently; the probability of *two* unrelated layers failing on the same request, in the same way, at the same time, is dramatically lower than either failing alone. This is the same logic behind aircraft having triple-redundant flight computers.

### R3. Data Flow Diagrams — Standard Notation

When drawing DFDs professionally, four symbol types are conventional:
| Symbol | Meaning |
|---|---|
| Rounded rectangle / circle | A process (something that transforms data) |
| Rectangle | An external entity (user, third-party system) |
| Open-ended rectangle / two parallel lines | A data store (database, file, cache) |
| Arrow | Data flow, ideally labeled with what data moves |

DFDs come in "levels" — a Level 0 DFD (a "context diagram") shows the whole system as a single process with external entities around it; Level 1 breaks that single process into its major sub-processes (roughly what we drew in Step 2); Level 2 would break each of *those* down further. Most teams stop at Level 1 for threat-modeling purposes — going deeper has diminishing returns unless a specific flow needs closer scrutiny.

### R4. Idempotency Keys — Implementation Patterns

Beyond the unique-constraint approach we used, production systems (Stripe's API is the canonical example) typically also:
- Store the **response** alongside the idempotency key, so a retried request gets back the *exact original response body*, not just a generic "already exists" error.
- Expire idempotency keys after a window (e.g., 24 hours) to bound storage growth — implemented via a scheduled cleanup job or a database TTL.
- Return **HTTP 409 Conflict** (not 200) if the same idempotency key is reused with a *different* request body — signaling client-side misuse (reusing a key across genuinely different operations) rather than a legitimate retry.

We'll implement the full response-caching version of this pattern when we build the actual `/api/v1/orders` route in Part 3.

### R5. Rate Limiting Algorithms

| Algorithm | How It Works | Trade-off |
|---|---|---|
| **Fixed Window** | Count requests in discrete time buckets (e.g., "requests since :00 of this minute") | Simple, but allows a burst of 2x the limit right at a window boundary |
| **Sliding Window** | Count requests in a continuously moving time window | More accurate, slightly more computationally expensive |
| **Token Bucket** | A bucket holds N tokens; each request consumes one; tokens refill at a fixed rate over time | Allows short bursts while still enforcing a long-term average rate — what we specify for SecureTrade |
| **Leaky Bucket** | Requests queue and are processed at a strictly constant output rate | Smooths traffic completely but adds latency under burst load |

We chose **token bucket** for SecureTrade because it tolerates the realistic case of a legitimate user clicking "submit order" a few times in quick succession (e.g., placing several small orders back-to-back) without needing an artificially high sustained limit that would also make brute-force login attempts easier.

### R6. OWASP API Security Top 10 vs. OWASP (Web) Top 10 — Why Both Exist

The OWASP (Web) Top 10 (which we address throughout Part 3) focuses on risks in traditional server-rendered web applications — things like Cross-Site Scripting, which requires a browser rendering HTML to matter. The **API Security Top 10** exists separately because modern apps expose APIs consumed by many client types (browsers, mobile apps, other services) where browser-specific attacks are less relevant, but authorization granularity (object-level, function-level, property-level — API1, API3, API5) becomes disproportionately important, since an API often exposes far more raw data operations than a traditional server-rendered page ever would. Since SecureTrade is a Next.js app that's *also* effectively an API (via its Route Handlers), both lists apply to us simultaneously — which is why Part 3 addresses the Web Top 10 directly, while this part mapped the API Top 10.

---

**Next up: Part 3 — Secure Coding ("Write Code That Doesn't Suck")**, where we finally write real application code: registration and login with NextAuth, Zod validation on every input, the `middleware.ts` that enforces the RBAC rules we designed here, and — following the series' "break it first" pattern for the first time — a deliberately vulnerable version of the order-submission flow that we'll attack ourselves before patching all 7 planted bugs.
