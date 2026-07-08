## Part 10: Building the Journal Entry Engine

**Goal:** build the journal_entries and journal_lines tables, and write postJournalEntry — a function that only ever saves a transaction if debits equal credits, wrapped in a real database transaction.

**Prerequisite:** Parts 1-9 completed.

This is the single most important piece of code in the entire application — everything from here forward routes through it. Take your time.

---

### 1. Add the schema

Open src/lib/db/schema.ts. Replace its ENTIRE contents with the following (adds journal_entries and journal_lines):

```ts
import {
  pgTable,
  pgEnum,
  text,
  uuid,
  bigint,
  boolean,
  timestamp,
  date,
  jsonb,
} from "drizzle-orm/pg-core";

export const accountTypeEnum = pgEnum("account_type", [
  "asset",
  "liability",
  "equity",
  "income",
  "expense",
]);

export const normalBalanceEnum = pgEnum("normal_balance", ["debit", "credit"]);

export const journalEntryStatusEnum = pgEnum("journal_entry_status", [
  "posted",
  "void",
]);

export const journalSourceTypeEnum = pgEnum("journal_source_type", [
  "manual",
  "invoice",
  "bill",
  "payment_received",
  "payment_made",
  "opening_balance",
  "bank_transaction",
  "reversal",
]);

export const organizations = pgTable("organizations", {
  id: text("id").primaryKey(),
  name: text("name").notNull(),
  baseCurrency: text("base_currency").notNull().default("USD"),
  settings: jsonb("settings").notNull().default({}),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const accounts = pgTable("accounts", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  code: text("code").notNull(),
  name: text("name").notNull(),
  type: accountTypeEnum("type").notNull(),
  subtype: text("subtype").notNull(),
  normalBalance: normalBalanceEnum("normal_balance").notNull(),
  parentId: uuid("parent_id"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const journalEntries = pgTable("journal_entries", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  date: date("date").notNull(),
  memo: text("memo"),
  status: journalEntryStatusEnum("status").notNull().default("posted"),
  sourceType: journalSourceTypeEnum("source_type").notNull(),
  sourceId: text("source_id"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const journalLines = pgTable("journal_lines", {
  id: uuid("id").primaryKey().defaultRandom(),
  entryId: uuid("entry_id")
    .notNull()
    .references(() => journalEntries.id, { onDelete: "cascade" }),
  accountId: uuid("account_id")
    .notNull()
    .references(() => accounts.id),
  debitCents: bigint("debit_cents", { mode: "number" }).notNull().default(0),
  creditCents: bigint("credit_cents", { mode: "number" }).notNull().default(0),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```

Run:
```
npm run db:generate
npm run db:migrate
```
Expected: a migration creating journal_entries and journal_lines, plus two new enum types, applied successfully. Confirm both tables appear in Neon's dashboard.

### 2. Write the posting function

Create the folder src/lib/accounting/. Inside it, create post-journal-entry.ts:

```ts
import { db } from "@/lib/db";
import { journalEntries, journalLines } from "@/lib/db/schema";

type JournalLineInput = {
  accountId: string;
  debitCents?: number;
  creditCents?: number;
};

type PostJournalEntryParams = {
  orgId: string;
  date: Date;
  memo?: string;
  sourceType:
    | "manual"
    | "invoice"
    | "bill"
    | "payment_received"
    | "payment_made"
    | "opening_balance"
    | "bank_transaction"
    | "reversal";
  sourceId?: string;
  lines: JournalLineInput[];
};

export async function postJournalEntry(
  params: PostJournalEntryParams,
  tx?: typeof db
) {
  const { orgId, date, memo, sourceType, sourceId, lines } = params;

  if (lines.length < 2) {
    throw new Error("A journal entry needs at least two lines");
  }

  const totalDebits = lines.reduce((sum, l) => sum + (l.debitCents ?? 0), 0);
  const totalCredits = lines.reduce((sum, l) => sum + (l.creditCents ?? 0), 0);

  if (totalDebits !== totalCredits) {
    throw new Error(
      `Journal entry is unbalanced: debits ${totalDebits} !== credits ${totalCredits}`
    );
  }

  async function runPosting(activeTx: typeof db) {
    const [entry] = await activeTx
      .insert(journalEntries)
      .values({
        orgId,
        date: date.toISOString().slice(0, 10),
        memo,
        sourceType,
        sourceId,
      })
      .returning();

    await activeTx.insert(journalLines).values(
      lines.map((l) => ({
        entryId: entry.id,
        accountId: l.accountId,
        debitCents: l.debitCents ?? 0,
        creditCents: l.creditCents ?? 0,
      }))
    );

    return entry;
  }

  if (tx) {
    return runPosting(tx);
  }
  return db.transaction(async (innerTx) => runPosting(innerTx));
}
```

Notice `tx?: typeof db` as an optional second parameter: if provided, this function joins the caller's existing transaction instead of always opening its own — this is how later features (Part 13) combine "create an invoice" and "post its journal entry" into one atomic all-or-nothing operation.

### 3. Write a manual test

Create src/lib/accounting/test-post.ts:

```ts
import { db } from "@/lib/db";
import { accounts } from "@/lib/db/schema";
import { eq, and } from "drizzle-orm";
import { postJournalEntry } from "./post-journal-entry";

const MY_ORG_ID = "PASTE_YOUR_REAL_ORG_ID_HERE";

async function main() {
  const [checking] = await db
    .select()
    .from(accounts)
    .where(and(eq(accounts.orgId, MY_ORG_ID), eq(accounts.code, "1000")));
  const [equity] = await db
    .select()
    .from(accounts)
    .where(and(eq(accounts.orgId, MY_ORG_ID), eq(accounts.code, "3000")));

  const entry = await postJournalEntry({
    orgId: MY_ORG_ID,
    date: new Date(),
    memo: "Owner investment",
    sourceType: "manual",
    lines: [
      { accountId: checking.id, debitCents: 1000000 },
      { accountId: equity.id, creditCents: 1000000 },
    ],
  });

  console.log("Balanced entry created:", entry);
}

main();
```

Replace PASTE_YOUR_REAL_ORG_ID_HERE with your real org ID. Run:
```
npx tsx src/lib/accounting/test-post.ts
```
Expected output: `Balanced entry created: { id: '...', orgId: '...', date: '2025-...', memo: 'Owner investment', ... }`

Now edit the script temporarily — change `creditCents: 1000000` to `creditCents: 900000` on the equity line — and run it again:
```
npx tsx src/lib/accounting/test-post.ts
```
Expected output this time: an uncaught error printed to the terminal containing `Journal entry is unbalanced: debits 1000000 !== credits 900000`. Revert the change back to `1000000` once confirmed.

Verify in Neon's SQL Editor:
```sql
SELECT * FROM journal_entries;
SELECT * FROM journal_lines;
```
You should see exactly ONE entry (the balanced one) with exactly two lines — the failed unbalanced attempt saved nothing.

Delete src/lib/accounting/test-post.ts once done, or leave it — it's harmless.

### 4. Commit

```
git add .
git commit -m "Add journal_entries/journal_lines tables and postJournalEntry engine with debit=credit enforcement"
```

---

### Checkpoint

- [ ] journal_entries and journal_lines tables exist in Neon
- [ ] postJournalEntry rejects entries with fewer than 2 lines
- [ ] postJournalEntry rejects entries where debits != credits, with a clear thrown error
- [ ] A balanced entry saves successfully using a real db.transaction
- [ ] You manually tested both a balanced and an unbalanced entry

---

### Troubleshooting

**"Cannot find module './post-journal-entry'" or similar in test-post.ts**
Confirm both files are in the same folder, src/lib/accounting/, and that post-journal-entry.ts is spelled with hyphens exactly as shown (not underscores or camelCase).

**Error: "invalid input value for enum journal_source_type"**
Check the sourceType value you're passing matches exactly one of the enum's lowercase values (manual, invoice, bill, payment_received, payment_made, opening_balance, bank_transaction, reversal) — a common typo is "Manual" with a capital M, which will fail.

**Error mentioning "bigint" or numbers being too large/small**
The debitCents/creditCents columns use { mode: "number" } which is fine for normal amounts but can lose precision on extremely large numbers (billions of cents). For this course's scale, this is a non-issue — just be aware it exists if you ever see odd rounding on very large test amounts.

**The unbalanced test still saved a row instead of throwing**
Double-check you actually changed the amount in test-post.ts and saved the file before re-running — a very common mistake is editing but forgetting to save, then re-running the old cached version mentally (Node.js always reads the current file on disk when you run tsx, so this really would mean the edit didn't save).

**"relation journal_entries does not exist" when running the test**
Migrations weren't applied. Re-run npm run db:migrate and confirm it completes with no errors before trying the test script again.

**Both accounts (checking/equity) come back as undefined in test-post.ts**
Confirm MY_ORG_ID matches an org that actually has seeded accounts (Part 9) — and confirm the account codes 1000 and 3000 exist for that org exactly as seeded. Query manually in Neon's SQL Editor to double check: SELECT code, name FROM accounts WHERE org_id = 'your-org-id';

---

Ready for **Part 11: Customers & Vendors** ? We're now moving from foundational engine-building into real user-facing features.
