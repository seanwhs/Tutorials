# QB Clone: Accounting Core - Double-Entry Theory, Chart of Accounts, Journal Engine

File 4 of 8. This is the single most important file in the whole set - it covers the actual accounting theory, then the Chart of Accounts, then the journal entry posting engine that every later feature (invoices, bills, payments, bank import) depends on. See file "00 Master Overview and Architecture" for the big picture.

---

## PART A: Debits, Credits and Double-Entry Accounting (theory, no code)

### Why an accounting app needs "double-entry" at all

A naive "accounting app" would just add up an invoices table and a bills table. This breaks down fast: it can't distinguish money in the bank from money owed to you, can't handle partial payments cleanly, can't correct mistakes without deleting history, and can't produce a Balance Sheet.

### The one rule that explains everything

Every financial transaction is recorded as at least two lines: something increases, something else decreases (or increases), and total debits must always equal total credits, for every single transaction, no exceptions.

### Forget your bank statement's meaning of "debit"

In accounting, debit and credit are just labels for two sides of a transaction - "left side" and "right side," not "bad" and "good." Whether a debit increases or decreases an account depends entirely on the account's TYPE.

### The five account types and their normal balance

| Account Type | Normal Balance | Increases with | Decreases with | Examples |
|---|---|---|---|---|
| Asset | Debit | Debit | Credit | Checking, Accounts Receivable, Equipment |
| Liability | Credit | Credit | Debit | Credit card owed, Accounts Payable, Loans |
| Equity | Credit | Credit | Debit | Owner's investment, Retained Earnings |
| Income | Credit | Credit | Debit | Sales income, Service revenue |
| Expense | Debit | Debit | Credit | Rent, Utilities, Office Supplies |

Memory trick: Assets and Expenses are debit-normal. Liabilities, Equity, and Income are credit-normal.

### Worked example 1: Owner invests $10,000

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $10,000 | |
| Owner's Equity (Equity) | | $10,000 |

### Worked example 2: Send a $500 invoice (unpaid)

| Account | Debit | Credit |
|---|---|---|
| Accounts Receivable (Asset) | $500 | |
| Service Income (Income) | | $500 |

The income is earned the moment the invoice is sent - this is accrual accounting.

### Worked example 3: Customer pays that $500 invoice

| Account | Debit | Credit |
|---|---|---|
| Checking Account (Asset) | $500 | |
| Accounts Receivable (Asset) | | $500 |

Income is NOT touched again - it was already recorded in example 2.

### Worked example 4: Pay a $200 electric bill

| Account | Debit | Credit |
|---|---|---|
| Utilities Expense (Expense) | $200 | |
| Checking Account (Asset) | | $200 |

### Why debits=credits is a powerful safety net

A single-line entry would be rejected - it's not a complete, real transaction. This is exactly why it's enforced at the code/database level (Part C below), and why money is always stored as integer cents (never floating point) - a fraction-of-a-cent rounding error could break this rule for no real reason.

### Where reports come from

- **Profit & Loss**: sum Income (credits minus debits) minus Expenses (debits minus credits) over a date range
- **Balance Sheet**: running balance of every Asset, Liability, and Equity account as of a date - Assets will always exactly equal Liabilities + Equity
- **General Ledger**: chronological list of every journal line, per account
- **AR/AP Aging**: open AR/AP balances grouped by overdueness

### Vocabulary

- **Journal Entry**: one complete transaction
- **Journal Line**: one row within a journal entry
- **Posting**: saving a journal entry as final
- **Chart of Accounts**: the full list of accounts a business uses
- **Ledger**: the complete history of all posted journal entries

### Checkpoint A (conceptual)
- [ ] Which two account types increase with a debit? Which three increase with a credit?
- [ ] A business buys a $2,000 laptop with a credit card - what are the two journal lines?
- [ ] Why doesn't income get recorded again when an invoice gets paid later?
- [ ] Why must total debits always equal total credits on every entry?
- [ ] Why build reports from journal_lines instead of directly from invoices/bills tables?

### Troubleshooting A (common misunderstandings, not code errors)

**"I keep wanting to think of debit as bad/negative and credit as good/positive"** - The single most common beginner trap. There is no inherent good/bad meaning - re-read the section above. Try replacing "debit"/"credit" with "left"/"right" mentally while learning.

**"I can't tell which account type a real-world account belongs to"** - Ask: does this represent something the business OWNS (Asset), OWES (Liability), the OWNER'S STAKE (Equity), MONEY EARNED (Income), or MONEY SPENT (Expense)? Almost everything sorts cleanly with that question.

**"The credit card purchase example really tripped me up"** - Good sign, not bad - work through it slowly: a laptop is an Asset going up (debit), the credit card balance owed is a Liability going up (credit). Two accounts increasing at once, on opposite sides - exactly what double-entry looks like for a credit purchase.

**"Why does an invoice being SENT count as income, before I've even been paid?"** - Accrual accounting: income is recognized when earned (work done/sale happened), not when cash physically arrives. Standard practice, and what real QuickBooks does by default.

**"I don't understand why we need BOTH a Balance Sheet and a P&L if they're derived from the same journal_lines"** - They answer different questions over different scopes: P&L = performance over a period (range of dates); Balance Sheet = position at a single instant (one date). This becomes very concrete once both reports are built (file 05).

---
```

```markdown
## PART B: Building the Chart of Accounts

### Extend the schema

Open src/lib/db/schema.ts. Replace its ENTIRE contents with the following (adds normalBalance enum, subtype, parentId to accounts):

```ts
import {
  pgTable,
  pgEnum,
  text,
  uuid,
  boolean,
  timestamp,
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
```

Run:
```
npm run db:generate
npm run db:migrate
```

### Create the seed function

Create src/lib/db/seed-default-accounts.ts:
```ts
import { db } from "./index";
import { accounts } from "./schema";

export async function seedDefaultAccounts(orgId: string) {
  await db.insert(accounts).values([
    { orgId, code: "1000", name: "Checking Account", type: "asset", subtype: "bank", normalBalance: "debit" },
    { orgId, code: "1100", name: "Accounts Receivable", type: "asset", subtype: "accounts_receivable", normalBalance: "debit" },
    { orgId, code: "1200", name: "Undeposited Funds", type: "asset", subtype: "other_current_asset", normalBalance: "debit" },
    { orgId, code: "1500", name: "Fixed Assets", type: "asset", subtype: "fixed_asset", normalBalance: "debit" },
    { orgId, code: "2000", name: "Accounts Payable", type: "liability", subtype: "accounts_payable", normalBalance: "credit" },
    { orgId, code: "2100", name: "Credit Card", type: "liability", subtype: "credit_card", normalBalance: "credit" },
    { orgId, code: "3000", name: "Owner's Equity", type: "equity", subtype: "equity", normalBalance: "credit" },
    { orgId, code: "3100", name: "Retained Earnings", type: "equity", subtype: "equity", normalBalance: "credit" },
    { orgId, code: "4000", name: "Sales Income", type: "income", subtype: "income", normalBalance: "credit" },
    { orgId, code: "4100", name: "Service Income", type: "income", subtype: "income", normalBalance: "credit" },
    { orgId, code: "5000", name: "Cost of Goods Sold", type: "expense", subtype: "cogs", normalBalance: "debit" },
    { orgId, code: "5100", name: "Advertising Expense", type: "expense", subtype: "expense", normalBalance: "debit" },
    { orgId, code: "5200", name: "Office Supplies Expense", type: "expense", subtype: "expense", normalBalance: "debit" },
    { orgId, code: "5300", name: "Rent Expense", type: "expense", subtype: "expense", normalBalance: "debit" },
    { orgId, code: "5400", name: "Utilities Expense", type: "expense", subtype: "expense", normalBalance: "debit" },
    { orgId, code: "5500", name: "Payroll Expense", type: "expense", subtype: "expense", normalBalance: "debit" },
  ]);
}
```

### Seed your test organization manually

Create a temporary file src/lib/db/run-seed.ts:
```ts
import { db } from "./index";
import { organizations } from "./schema";
import { seedDefaultAccounts } from "./seed-default-accounts";

const MY_ORG_ID = "PASTE_YOUR_REAL_ORG_ID_HERE"; // starts with org_, from the dashboard page

async function main() {
  await db.insert(organizations).values({
    id: MY_ORG_ID,
    name: "My Test Company",
  }).onConflictDoNothing();

  await seedDefaultAccounts(MY_ORG_ID);
  console.log("Seeded default accounts for", MY_ORG_ID);
}

main();
```
Replace MY_ORG_ID with your real org_... value. Run:
```
npx tsx src/lib/db/run-seed.ts
```
Delete run-seed.ts afterward.

### Build the Chart of Accounts page

Create src/app/dashboard/accounts/page.tsx:
```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { accounts } from "@/lib/db/schema";
import { eq } from "drizzle-orm";

export default async function AccountsPage() {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const allAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.orgId, orgId))
    .orderBy(accounts.code);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Chart of Accounts</h1>
      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Code</th>
            <th>Name</th>
            <th>Type</th>
            <th>Subtype</th>
            <th>Normal Balance</th>
          </tr>
        </thead>
        <tbody>
          {allAccounts.map((a) => (
            <tr key={a.id}>
              <td>{a.code}</td>
              <td>{a.name}</td>
              <td>{a.type}</td>
              <td>{a.subtype}</td>
              <td>{a.normalBalance}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
```

### Commit

```
git add .
git commit -m "Extend accounts schema, seed default chart of accounts, add accounts list page"
```

### Checkpoint B
- [ ] accounts table has subtype, normalBalance, parentId columns
- [ ] seedDefaultAccounts inserts 16 starter accounts
- [ ] Test org has those accounts visible in Neon
- [ ] /dashboard/accounts shows a real accounts table

### Troubleshooting B

**db:migrate fails with "column already exists"** - You may have already run a migration adding some columns. Check drizzle/migrations for duplicates - safe to delete a newly generated duplicate ONLY during early learning with no real data.

**run-seed.ts fails with duplicate key on organizations** - Expected if the org row already exists - .onConflictDoNothing() handles this gracefully.

**seedDefaultAccounts fails with invalid enum value** - Check every type/normalBalance value is spelled exactly lowercase as shown.

**/dashboard/accounts shows empty table** - Confirm run-seed.ts actually succeeded, and that MY_ORG_ID matches the organization currently ACTIVE in the browser's OrganizationSwitcher.

**"Cannot find module '@/lib/db'"** - Confirm tsconfig.json has the @/* path alias (set up automatically by create-next-app).

**Columns misaligned / "undefined" values** - Confirm JSX property names (a.normalBalance, not a.normal_balance) match Drizzle's camelCase conversion from snake_case database columns.

---

## PART C: Building the Journal Entry Engine

This is the single most important piece of code in the entire application. Every feature from file 05 onward posts through this function.

### Add the schema

Open src/lib/db/schema.ts. Replace its ENTIRE contents with the following (adds journal_entries and journal_lines, plus their enums):

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

Right — it cut off mid-schema. Here's the rest of PART C, continuing exactly from where it stopped:

```markdown
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
Confirm journal_entries and journal_lines appear in Neon's dashboard.

### Write the posting function

Create folder src/lib/accounting/, inside it post-journal-entry.ts:

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

Notice `tx?: typeof db` as an optional second parameter: if provided, this function joins the caller's existing transaction instead of always opening its own - this is how later features (file 05) combine "create an invoice" and "post its journal entry" into one atomic all-or-nothing operation.

### Write a manual test

Create src/lib/accounting/find-account.ts (used by the test script and by all of file 05's features):
```ts
import { db } from "@/lib/db";
import { accounts } from "@/lib/db/schema";
import { and, eq } from "drizzle-orm";

export async function findAccountBySubtype(orgId: string, subtype: string) {
  const [account] = await db
    .select()
    .from(accounts)
    .where(and(eq(accounts.orgId, orgId), eq(accounts.subtype, subtype)))
    .limit(1);

  if (!account) {
    throw new Error(`No account found with subtype "${subtype}" for this organization`);
  }

  return account;
}
```

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
Replace MY_ORG_ID. Run:
```
npx tsx src/lib/accounting/test-post.ts
```
Expected: `Balanced entry created: { id: '...', ... }`.

Now temporarily change `creditCents: 1000000` to `creditCents: 900000` on the equity line and run again - expected: a thrown error containing "Journal entry is unbalanced: debits 1000000 !== credits 900000". Revert the change once confirmed.

Verify in Neon:
```sql
SELECT * FROM journal_entries;
SELECT * FROM journal_lines;
```
Exactly ONE entry (the balanced one) with exactly two lines.

Delete test-post.ts once done (or leave it, it's harmless).

### Commit

```
git add .
git commit -m "Add journal_entries/journal_lines tables and postJournalEntry engine with debit=credit enforcement"
```

### Checkpoint C
- [ ] journal_entries and journal_lines tables exist
- [ ] postJournalEntry rejects entries with fewer than 2 lines
- [ ] postJournalEntry rejects unbalanced entries with a clear thrown error
- [ ] A balanced entry saves successfully using a real db.transaction
- [ ] Manually tested both a balanced and an unbalanced entry

### Troubleshooting C

**"Cannot find module './post-journal-entry'"** - Confirm both files are in src/lib/accounting/, spelled with hyphens exactly.

**"invalid input value for enum journal_source_type"** - Check the sourceType value matches exactly one of the enum's lowercase values - a common typo is capitalizing it.

**Unbalanced test still saved a row instead of throwing** - Confirm you actually edited AND saved test-post.ts before re-running - tsx always reads the current file on disk.

**"relation journal_entries does not exist"** - Migrations weren't applied; re-run npm run db:migrate.

**Both accounts come back undefined in test-post.ts** - Confirm MY_ORG_ID matches an org with seeded accounts (Part B above), and that codes 1000/3000 exist for that org - check via Neon's SQL Editor: `SELECT code, name FROM accounts WHERE org_id = 'your-org-id';`

---


**`03-accounting-core.md` is now complete** (PART A + PART B + PART C combined across the last three messages).

