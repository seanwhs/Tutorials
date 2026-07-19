# Part 6: The Journal Entry Engine

This is the part everything else in the course depends on. In Part 4, we learned the rule that must never break: debits must equal credits, every single time, no exceptions. Today, we turn that rule into actual, enforced code — a function so central that every feature from Part 7 onward (invoices, bills, payments, bank imports) will call it, and *only* it, whenever money moves.

## Step 6.1 — Designing the `journal_entries` and `journal_lines` Tables

### The Target
Add two new tables to our schema: `journal_entries` (the "envelope" for one financial event) and `journal_lines` (the individual debit/credit rows inside it).

### The Concept
Recall Part 4's vocabulary: a **Journal Entry** is one complete financial event (like "Event 3: a customer pre-pays $10"), and a **Journal Line** is one single debit or credit *within* that entry. Think of a Journal Entry like an envelope containing a stack of receipts — the envelope itself has a date and a description ("Customer prepayment received"), while each receipt inside it (a Journal Line) says exactly which account was touched, by how much, and whether it was a debit or a credit.

We need a **one-to-many relationship** here: one Journal Entry envelope can (and almost always does) contain *many* Journal Lines — but every Journal Line belongs to exactly one envelope. This is modeled with a foreign key on `journal_lines` pointing back to its parent `journal_entries` row.

### The Implementation

Open `src/db/schema.ts` and add the following new enum and two new tables. Here is the **complete, updated file**:

**`src/db/schema.ts`**
```typescript
import {
  pgTable,
  text,
  timestamp,
  uuid,
  boolean,
  pgEnum,
  foreignKey,
  numeric,
  date,
} from "drizzle-orm/pg-core";

export const organizations = pgTable("organizations", {
  id: uuid("id").primaryKey().defaultRandom(),
  clerkOrgId: text("clerk_org_id").notNull().unique(),
  name: text("name").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const accountTypeEnum = pgEnum("account_type", [
  "asset",
  "liability",
  "equity",
  "revenue",
  "expense",
]);

export const normalBalanceEnum = pgEnum("normal_balance", ["debit", "credit"]);

export const accounts = pgTable(
  "accounts",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),
    code: text("code").notNull(),
    name: text("name").notNull(),
    accountType: accountTypeEnum("account_type").notNull(),
    normalBalance: normalBalanceEnum("normal_balance").notNull(),
    subtype: text("subtype").notNull(),
    parentId: uuid("parent_id"),
    isActive: boolean("is_active").notNull().default(true),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (table) => [
    foreignKey({
      columns: [table.parentId],
      foreignColumns: [table.id],
      name: "accounts_parent_id_fk",
    }),
  ]
);

// journalEntries is the "envelope" — one complete financial event.
// It deliberately holds NO dollar amounts itself — amounts only ever
// live on the individual journalLines beneath it. This prevents the two
// from ever getting out of sync with each other.
export const journalEntries = pgTable("journal_entries", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  // The date the financial event actually occurred — not necessarily the
  // same as when it was entered into the system. This is the date used
  // by every report in Part 9 to decide which period an entry belongs to.
  entryDate: date("entry_date").notNull(),

  // A human-readable description of the whole event, e.g.
  // "Invoice #1001 to Acme Corp" or "Payment received for Invoice #1001".
  description: text("description").notNull(),

  // Loosely tracks what kind of event generated this entry (e.g. "invoice",
  // "bill", "payment", "manual", "bank_import") — useful later for filtering
  // and for linking back to the originating record when we build those
  // features in Parts 7, 8, and 12.
  sourceType: text("source_type").notNull().default("manual"),

  // The ID of the originating record (e.g. an invoice's UUID), if any.
  // Nullable, since manually-created entries have no such source record.
  sourceId: uuid("source_id"),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});

// journalLines is one single debit or credit row within a journal entry.
export const journalLines = pgTable("journal_lines", {
  id: uuid("id").primaryKey().defaultRandom(),

  journalEntryId: uuid("journal_entry_id")
    .notNull()
    .references(() => journalEntries.id, { onDelete: "cascade" }),

  accountId: uuid("account_id")
    .notNull()
    .references(() => accounts.id, { onDelete: "restrict" }),
  // onDelete: "restrict" (rather than "cascade") is intentional here —
  // we NEVER want deleting an account to silently delete historical
  // journal lines. Postgres will instead simply refuse the deletion,
  // forcing a human to consciously decide what to do with the history
  // first. This is the database itself protecting the integrity of
  // the ledger, matching the "posted entries are historical fact"
  // principle from Part 4.

  // Exactly one of debitAmount/creditAmount will be a positive number,
  // and the other will be zero — never both, and never neither. We use
  // `numeric` (not a floating point type like `real`/`double`) because
  // floating point numbers cannot represent money exactly — 0.1 + 0.2
  // famously doesn't equal 0.3 in floating point, which is unacceptable
  // for money. `numeric` stores exact decimal values.
  debitAmount: numeric("debit_amount", { precision: 14, scale: 2 })
    .notNull()
    .default("0"),
  creditAmount: numeric("credit_amount", { precision: 14, scale: 2 })
    .notNull()
    .default("0"),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```

Notice the comment on `debitAmount`/`creditAmount`: this is a deliberate, important design decision. Some accounting systems model this as a single signed `amount` column (positive for debit, negative for credit). We instead use **two separate columns**, both always non-negative, because it makes every future query dramatically easier to read and reason about — "sum all `debitAmount` for this account" is unambiguous, whereas "sum all `amount` values, remembering that negative means credit" is a subtle trap waiting to cause a sign error in a report.

### The Verification

Save the file. Confirm no red TypeScript errors appear. Pay attention to the new imports at the top (`numeric`, `date`) — if these are underlined red, double-check they're spelled correctly and imported from `"drizzle-orm/pg-core"`.

---

## Step 6.2 — Migrating the New Tables

### The Target
Apply `journal_entries` and `journal_lines` to the real Neon database.

### The Implementation

```bash
npm run db:generate
```

Expected output:

```
2 tables
journal_entries 6 columns 0 indexes 1 fks
journal_lines 5 columns 0 indexes 2 fks

[✓] Your SQL migration file ➜ drizzle/0002_xxxxxxx.sql created
```

```bash
npm run db:migrate
```

Expected output:

```
[✓] migrations applied successfully!
```

### The Verification

```bash
npm run db:studio
```

Confirm `journal_entries` and `journal_lines` now both appear in the sidebar, currently empty, with the exact columns described above.

---

## Step 6.3 — Designing `postJournalEntry`: The Core Function

### The Target
Write the single function that every money-moving feature in this entire application will call.

### The Concept
This is the payoff of Part 4. We're going to write a function with one job: accept a list of proposed debit/credit lines, **verify they balance perfectly**, and only then save them — as one atomic unit, meaning either *everything* saves successfully or *nothing* does, with no possibility of a half-saved, corrupted state in between.

Think of "atomic" like a bank wire transfer between two of your own accounts: the money must leave account A and arrive in account B as a single, indivisible action. If the system crashed halfway through — after debiting A but before crediting B — you'd have money that simply vanished. A **database transaction** is Postgres's built-in mechanism for guaranteeing this: we group multiple individual insert statements together, and either all of them commit permanently, or if anything fails partway through, all of them are automatically rolled back as if nothing happened at all.

### The Implementation

First, we need a database client capable of running transactions. Recall from Part 3 that we're using the `neon-http` driver, optimized for serverless HTTP requests — but HTTP-based drivers have a limitation: they can't hold a transaction open across multiple separate HTTP requests. For genuine multi-statement transactions, Neon provides a different connection mode built on WebSockets, which *can* stay open long enough to run a full transaction safely. Let's add that alongside our existing setup.

**`src/db/index.ts`**
```typescript
import { drizzle } from "drizzle-orm/neon-http";
import { drizzle as drizzleServerless } from "drizzle-orm/neon-serverless";
import { neon } from "@neondatabase/serverless";
import { Pool } from "@neondatabase/serverless";
import * as schema from "./schema";

// The HTTP-based client — fast, lightweight, ideal for simple one-shot
// reads and writes that don't need a multi-statement transaction.
const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql, { schema });

// The WebSocket-based Pool client — required specifically for real
// database transactions (db.transaction(...)), since a transaction must
// hold one continuous connection open across several statements, which
// the plain HTTP client cannot do. We use this ONLY where we specifically
// need db.transaction() — postJournalEntry being the first and most
// important example.
const pool = new Pool({ connectionString: process.env.DATABASE_URL! });
export const dbTransactional = drizzleServerless(pool, { schema });
```

Install the one additional dependency this requires (the `ws` WebSocket package, needed by Neon's serverless Pool client when running outside the browser, e.g. during local development or on the server):

```bash
npm install ws
npm install -D @types/ws
```

Now, the core function itself:

**`src/lib/journal.ts`**
```typescript
import { dbTransactional } from "@/db";
import { journalEntries, journalLines, accounts } from "@/db/schema";
import { eq, and } from "drizzle-orm";

// One proposed line in a journal entry, before it's been saved. Exactly
// one of debit/credit must be a positive amount; the other must be zero.
export type ProposedJournalLine = {
  accountId: string;
  debit?: number;
  credit?: number;
};

export type PostJournalEntryInput = {
  organizationId: string;
  entryDate: string; // formatted as "YYYY-MM-DD"
  description: string;
  sourceType?: string;
  sourceId?: string;
  lines: ProposedJournalLine[];
};

/**
 * The single, central function through which every financial event in
 * Greymatter Ledger must pass. It enforces the one unbreakable rule from
 * Part 4 — total debits must equal total credits — before anything is
 * ever saved, and it saves the entry and all its lines as one atomic
 * database transaction, so a partially-saved, unbalanced entry can never
 * exist in the ledger.
 */
export async function postJournalEntry(input: PostJournalEntryInput) {
  const { organizationId, entryDate, description, sourceType, sourceId, lines } =
    input;

  // --- Guard 1: an entry needs at least two lines to make any sense at all.
  // A single-line entry could never balance (one side would have nothing
  // to offset it against), so we reject this before doing any real work.
  if (lines.length < 2) {
    throw new Error(
      "A journal entry must have at least two lines (double-entry requires at least one debit and one credit)."
    );
  }

  // --- Guard 2: every line must specify exactly one of debit/credit,
  // never both, and never neither — matching Part 4's definition that
  // a single line is either a debit OR a credit, never a hybrid.
  for (const line of lines) {
    const hasDebit = (line.debit ?? 0) > 0;
    const hasCredit = (line.credit ?? 0) > 0;
    if (hasDebit === hasCredit) {
      throw new Error(
        `Each journal line must have exactly one of debit or credit set to a positive amount (account ${line.accountId} had debit=${line.debit ?? 0}, credit=${line.credit ?? 0}).`
      );
    }
  }

  // --- Guard 3: THE rule. Total debits must exactly equal total credits.
  // We round to 2 decimal places using integer cents internally to avoid
  // any floating point rounding drift creeping in during this comparison.
  const totalDebitCents = lines.reduce(
    (sum, line) => sum + Math.round((line.debit ?? 0) * 100),
    0
  );
  const totalCreditCents = lines.reduce(
    (sum, line) => sum + Math.round((line.credit ?? 0) * 100),
    0
  );

  if (totalDebitCents !== totalCreditCents) {
    throw new Error(
      `Journal entry does not balance: total debits (${(totalDebitCents / 100).toFixed(2)}) must equal total credits (${(totalCreditCents / 100).toFixed(2)}). This entry was rejected and nothing was saved.`
    );
  }

  // --- Guard 4: every referenced account must actually belong to this
  // organization. Without this check, a bug elsewhere in the app could
  // accidentally post a journal line against another company's account —
  // a serious multi-tenancy violation given everything from Part 2.
  const accountIds = lines.map((line) => line.accountId);
  const matchingAccounts = await dbTransactional.query.accounts.findMany({
    where: (accounts, { and, eq, inArray }) =>
      and(eq(accounts.organizationId, organizationId), inArray(accounts.id, accountIds)),
  });

  if (matchingAccounts.length !== new Set(accountIds).size) {
    throw new Error(
      "One or more accounts in this journal entry do not belong to the specified organization, or do not exist."
    );
  }

  // --- Everything checks out. Now we actually save it, atomically.
  // db.transaction() opens a real database transaction: every statement
  // inside this callback either ALL succeed together, or if anything
  // throws partway through, Postgres automatically undoes everything
  // that already ran inside this block, leaving the database exactly
  // as it was before we started. This is what makes it impossible for
  // an unbalanced or half-written entry to ever exist in the ledger.
  const result = await dbTransactional.transaction(async (tx) => {
    const [entry] = await tx
      .insert(journalEntries)
      .values({
        organizationId,
        entryDate,
        description,
        sourceType: sourceType ?? "manual",
        sourceId: sourceId ?? null,
      })
      .returning();

    const insertedLines = await tx
      .insert(journalLines)
      .values(
        lines.map((line) => ({
          journalEntryId: entry.id,
          accountId: line.accountId,
          debitAmount: (line.debit ?? 0).toFixed(2),
          creditAmount: (line.credit ?? 0).toFixed(2),
        }))
      )
      .returning();

    return { entry, lines: insertedLines };
  });

  return result;
}
```

### The Verification

Save both files. Confirm no TypeScript errors appear. We'll write real tests for this function in the next step, since a function this important deserves hands-on proof before we trust it with real invoices in Part 7.

---

## Step 6.4 — Proving It Works: A Temporary Test Page

### The Target
Manually exercise `postJournalEntry` with both a valid entry and several intentionally invalid ones, confirming each behaves exactly as designed.

### The Concept
This is the same spirit as a structural engineer stress-testing a bridge design with weights before ever letting a car drive across it. We're going to deliberately try to break our own function, on purpose, to build real confidence it protects the ledger correctly before Part 7 starts relying on it for real invoices.

### The Implementation

Create a temporary test page:

**`src/app/journal-test/page.tsx`** *(temporary — we'll delete this at the end of this step)*
```tsx
import { getOrCreateOrganization } from "@/lib/organizations";
import { db } from "@/db";
import { accounts } from "@/db/schema";
import { eq } from "drizzle-orm";
import { postJournalEntry } from "@/lib/journal";

export default async function JournalTestPage() {
  const organizationId = await getOrCreateOrganization();

  const allAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.organizationId, organizationId));

  const cash = allAccounts.find((a) => a.code === "1000")!;
  const equity = allAccounts.find((a) => a.code === "3000")!;

  const results: { label: string; outcome: string }[] = [];

  // TEST 1: A valid, balanced entry — owner puts in $500 of cash.
  // Expected: succeeds.
  try {
    await postJournalEntry({
      organizationId,
      entryDate: "2025-01-01",
      description: "TEST: Owner cash contribution",
      lines: [
        { accountId: cash.id, debit: 500 },
        { accountId: equity.id, credit: 500 },
      ],
    });
    results.push({ label: "Test 1: Valid balanced entry", outcome: "✅ Succeeded (expected)" });
  } catch (err) {
    results.push({
      label: "Test 1: Valid balanced entry",
      outcome: `❌ Failed unexpectedly: ${(err as Error).message}`,
    });
  }

  // TEST 2: An unbalanced entry — debits don't equal credits.
  // Expected: throws an error, nothing saved.
  try {
    await postJournalEntry({
      organizationId,
      entryDate: "2025-01-01",
      description: "TEST: Unbalanced entry (should fail)",
      lines: [
        { accountId: cash.id, debit: 500 },
        { accountId: equity.id, credit: 400 },
      ],
    });
    results.push({
      label: "Test 2: Unbalanced entry",
      outcome: "❌ Succeeded unexpectedly — this should have been rejected!",
    });
  } catch (err) {
    results.push({
      label: "Test 2: Unbalanced entry",
      outcome: `✅ Correctly rejected: ${(err as Error).message}`,
    });
  }

  // TEST 3: A single-line entry — impossible to balance by definition.
  // Expected: throws an error before even checking amounts.
  try {
    await postJournalEntry({
      organizationId,
      entryDate: "2025-01-01",
      description: "TEST: Single line entry (should fail)",
      lines: [{ accountId: cash.id, debit: 500 }],
    });
    results.push({
      label: "Test 3: Single-line entry",
      outcome: "❌ Succeeded unexpectedly — this should have been rejected!",
    });
  } catch (err) {
    results.push({
      label: "Test 3: Single-line entry",
      outcome: `✅ Correctly rejected: ${(err as Error).message}`,
    });
  }

  // TEST 4: A line with both debit AND credit set — an invalid line shape.
  // Expected: throws an error.
  try {
    await postJournalEntry({
      organizationId,
      entryDate: "2025-01-01",
      description: "TEST: Line with both debit and credit (should fail)",
      lines: [
        { accountId: cash.id, debit: 100, credit: 50 },
        { accountId: equity.id, credit: 50 },
      ],
    });
    results.push({
      label: "Test 4: Hybrid debit+credit line",
      outcome: "❌ Succeeded unexpectedly — this should have been rejected!",
    });
  } catch (err) {
    results.push({
      label: "Test 4: Hybrid debit+credit line",
      outcome: `✅ Correctly rejected: ${(err as Error).message}`,
    });
  }

  return (
    <div className="p-8">
      <h1 className="text-xl font-bold">Journal Engine Test Results</h1>
      <ul className="mt-4 space-y-2">
        {results.map((r) => (
          <li key={r.label} className="rounded border border-gray-200 p-3">
            <div className="font-semibold">{r.label}</div>
            <div className="mt-1 text-sm">{r.outcome}</div>
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### The Verification

While signed in with an active organization (e.g., "Acme Test Co"), visit `http://localhost:3000/journal-test`. Expected output — all four tests should show a ✅:

```
Test 1: Valid balanced entry
✅ Succeeded (expected)

Test 2: Unbalanced entry
✅ Correctly rejected: Journal entry does not balance: total debits (500.00) must equal total credits (400.00). This entry was rejected and nothing was saved.

Test 3: Single-line entry
✅ Correctly rejected: A journal entry must have at least two lines (double-entry requires at least one debit and one credit).

Test 4: Hybrid debit+credit line
✅ Correctly rejected: Each journal line must have exactly one of debit or credit set to a positive amount (account ...).
```

Now confirm the *database* reality matches — run `npm run db:studio`, open `journal_entries`, and confirm **exactly one row exists** (from Test 1 only) with description "TEST: Owner cash contribution." Open `journal_lines` and confirm **exactly two rows** exist, linked to that one entry — one with `debit_amount = 500.00`, one with `credit_amount = 500.00`. Critically, confirm **zero rows** exist relating to Tests 2, 3, or 4 — proving the transaction rollback genuinely prevented any partial data from ever touching the real database, even though those calls did throw errors after some validation work had already happened.

Once confirmed, delete the temporary test page:

```bash
rm -rf src/app/journal-test
```

(Windows PowerShell: `Remove-Item -Recurse -Force src\app\journal-test`)

---

## Step 6.5 — Fifth Git Commit

### The Target
Save the completed journal engine as a new checkpoint — arguably the most important commit in the entire course so far.

### The Implementation

```bash
git add .
git commit -m "Add journal_entries/journal_lines schema and postJournalEntry engine with transactional balance enforcement"
```

### The Verification

```bash
git log --oneline
```

Expected output, five lines, newest first:

```
d4e5f6g Add journal_entries/journal_lines schema and postJournalEntry engine with transactional balance enforcement
c3d4e5f Add Chart of Accounts schema, default seed data, and viewing page
b2c3d4e Add Drizzle ORM, Neon connection, first schema, and org sync
a1b2c3d Add Clerk authentication, proxy.ts route protection, and organizations
e4f5g6h Initial commit: scaffold Next.js project, reorganized into src directory
```

---

## ✅ Checkpoint — Part 6

At this point, you should have:

- [x] `journal_entries` and `journal_lines` tables defined and migrated
- [x] `debitAmount`/`creditAmount` stored as separate `numeric` columns, never a single signed amount
- [x] A WebSocket-based `dbTransactional` client (`drizzle-orm/neon-serverless`) added specifically to support real multi-statement transactions
- [x] `postJournalEntry()` implemented with four layered guards: minimum line count, no hybrid debit+credit lines, debits must equal credits exactly, and every account must belong to the calling organization
- [x] The entire save wrapped in `dbTransactional.transaction(...)`, guaranteeing atomicity
- [x] Hands-on proof, via a temporary test page and direct Drizzle Studio inspection, that valid entries save correctly and invalid entries save *nothing at all*
- [x] A fifth Git commit checkpoint

---

## 📚 Reference Section: Transactions, Precision, and Defensive Design

*(A standalone reference — read now or return later.)*

**Why do we need `dbTransactional` (WebSocket/Pool-based) in addition to `db` (HTTP-based) — why not just use one client everywhere?**
The plain HTTP client (`neon-http`) sends each query as an independent, one-shot HTTP request — there's no persistent connection between separate calls, so Postgres has no way to know "these three inserts belong together as one all-or-nothing unit." A real transaction requires holding one continuous connection open from `BEGIN` through either `COMMIT` or `ROLLBACK`. The Pool/WebSocket-based client can hold that connection open across multiple statements, which is exactly what `db.transaction()` needs internally. We keep both clients because the HTTP client remains simpler and marginally faster for the vast majority of our app's simple reads (like the `/accounts` page in Part 5), and we reserve the transactional client specifically for the smaller number of places that genuinely need atomic multi-statement guarantees — `postJournalEntry` being the flagship example, and the pattern every future money-moving feature (Parts 7, 8, 12) will reuse.

**Why round to integer cents (`Math.round(x * 100)`) instead of comparing the dollar amounts directly?**
JavaScript's built-in number type is a "floating point" number, which cannot represent every decimal fraction exactly in binary — the classic demonstration is that `0.1 + 0.2` evaluates to `0.30000000000000004` in JavaScript, not exactly `0.3`. For most software, that tiny error is irrelevant. For accounting software, it's precisely the kind of silent, invisible bug that could eventually cause "debits equal credits" to falsely fail (or worse, falsely pass) on a rounding technicality. Converting to whole integer cents before comparing sidesteps this entirely, since integer arithmetic in JavaScript has no such rounding error for the ranges we care about.

**Why does the database column use `numeric(14, 2)` instead of storing cents as an integer directly?**
Both are valid real-world approaches used in production accounting systems. We chose `numeric(14, 2)` (an exact decimal type, with up to 14 total digits and exactly 2 after the decimal point) because it keeps values human-readable directly in the database (Drizzle Studio, Neon's SQL editor) without needing to mentally divide every number by 100, which matters a lot for a beginner-friendly course where you'll be eyeballing raw table data constantly to verify your work. The cents-comparison trick above still protects us at the JavaScript layer regardless of which storage approach is chosen.

**Why check that every account belongs to the calling organization *inside* `postJournalEntry` itself, rather than trusting the calling code to have already checked?**
This is a defensive programming principle called "don't trust the caller." Even though every feature we build in this course will *also* independently scope its own queries to the current organization, `postJournalEntry` is the single most consequential function in the entire app — if a future bug anywhere else ever accidentally passed the wrong account ID, we want the *last line of defense*, right here in the core engine, to catch it and refuse to post rather than silently corrupting another company's ledger. This matters enormously given the multi-tenancy model established in Part 2.

**What does `onDelete: "restrict"` on `journalLines.accountId` actually prevent, concretely?**
Imagine someone, months from now, tries to delete the "Cash" account because they think it's no longer needed. If Cash has ever had a single journal line posted against it, Postgres will flatly refuse the deletion with a foreign key violation error, forcing a conscious decision (e.g., mark it `isActive: false` instead, as designed back in Part 5) rather than silently deleting the account and leaving behind journal lines that point at nothing — which would make historical reports permanently, silently wrong.

---

## 🔧 Troubleshooting — Part 6

**"`dbTransactional.transaction is not a function` or similar error."**
Confirm you imported `dbTransactional` (not `db`) from `@/db` in `journal.ts`, and that `src/db/index.ts` correctly exports it using `drizzleServerless(pool, { schema })` from `drizzle-orm/neon-serverless` — not the plain HTTP `drizzle()` call, which does not support `.transaction()`.

**"Error mentioning `ws` module not found, or WebSocket-related errors when calling `postJournalEntry`."**
Confirm you ran both `npm install ws` and `npm install -D @types/ws`, and restart the dev server (`Ctrl+C`, then `npm run dev`) — this package is loaded at server startup, so a running server won't pick up a freshly installed dependency without a restart.

**"Test 1 fails with an error about the `1000` or `3000` account codes not being found."**
This means your currently active organization doesn't have a seeded Chart of Accounts yet — revisit Part 5, Step 5.6, and either switch to an organization you already backfilled, or visit `/accounts` first to trigger the auto-seed check (which runs via `getOrCreateOrganization`) before visiting `/journal-test`.

**"Tests 2, 3, or 4 unexpectedly show '❌ Succeeded unexpectedly' instead of being rejected."**
This means one of the guard clauses in `postJournalEntry` isn't functioning as written — re-check the exact code in Step 6.3 against your own file line-by-line, paying particular attention to the comparison operators (`===`, not `==`) and that the guards run in order, before the `dbTransactional.transaction(...)` block, not after.

**"After running the tests, Drizzle Studio shows more than one row in `journal_entries`, even though only Test 1 should have succeeded."**
This likely means you visited `/journal-test` more than once — each page visit re-runs all four tests fresh, and every successful Test 1 call creates a brand-new, genuinely valid entry (there's no duplicate-prevention built into this temporary test page, since it's meant to be visited once and deleted). This is expected behavior for the test page itself, not a bug in `postJournalEntry` — simply note how many times you loaded the page when interpreting the row count.

**"I want to double check a transaction actually rolled back, not just that an error was thrown."**
This is exactly why Step 6.4 explicitly directs you to check Drizzle Studio's raw table contents after running the tests, rather than trusting the on-screen ✅/❌ messages alone — the on-screen message only proves an error was *thrown*, not that nothing was *saved*. Confirming zero related rows exist in the actual database is the real proof of atomicity.
