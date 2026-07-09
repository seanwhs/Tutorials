## Part 9: Building the Chart of Accounts

Goal: extend the accounts schema, seed a default Chart of Accounts, and build a page to view it.

Prerequisite: Parts 1-8 completed.

---

### 1. Extend the schema

Open `src/lib/db/schema.ts`. Replace its ENTIRE contents with the following (this adds a `normalBalance` enum, `subtype`, and `parentId` to `accounts`):

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
Expected: a new migration file with `ALTER TABLE "accounts" ADD COLUMN ...` statements, applied successfully.

### 2. Create the seed function

Create `src/lib/db/seed-default-accounts.ts`:

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

### 3. Seed your existing test organization manually

First, insert your organization row (it won't exist locally yet). Create a temporary file `src/lib/db/run-seed.ts`:

```ts
import { db } from "./index";
import { organizations } from "./schema";
import { seedDefaultAccounts } from "./seed-default-accounts";

const MY_ORG_ID = "PASTE_YOUR_REAL_ORG_ID_HERE"; // starts with org_, from Part 5's dashboard page

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

Replace `PASTE_YOUR_REAL_ORG_ID_HERE` with the real `org_...` value shown on your `/dashboard` page from Part 5. Run it:
```
npx tsx src/lib/db/run-seed.ts
```
Expected output: `Seeded default accounts for org_xxxxxxxxxxxx`

Delete `src/lib/db/run-seed.ts` afterward.

### 4. Build the Chart of Accounts page

Create `src/app/dashboard/accounts/page.tsx`:

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

Visit http://localhost:3000/dashboard/accounts while signed in with your seeded organization active. You should see all 16 accounts, sorted by code.

### 5. Commit

```
git add .
git commit -m "Extend accounts schema, seed default chart of accounts, add accounts list page"
```

---

### ✅ Checkpoint

- [ ] `accounts` table has `subtype`, `normalBalance`, `parentId` columns
- [ ] `seedDefaultAccounts` inserts 16 starter accounts
- [ ] Your test org has those accounts visible in Neon
- [ ] `/dashboard/accounts` shows a real accounts table

---

### Troubleshooting

**`npm run db:migrate` fails with "column already exists" or similar**
You may have already run a migration adding some of these columns in a previous attempt. Check `drizzle/migrations/` for duplicate migration files describing the same change — if you find one, and you're sure it was already applied, you can safely delete the newly generated duplicate migration file (only during course learning, never on a database with real user data).

**`run-seed.ts` fails with "duplicate key value violates unique constraint" on organizations**
This means the org row already exists from a previous run — that's fine, the `.onConflictDoNothing()` on the organizations insert handles this gracefully. If you still see the error, confirm you actually included `.onConflictDoNothing()` exactly as shown.

**`seedDefaultAccounts` fails with "invalid input value for enum account_type"**
Check every `type:` value in `seed-default-accounts.ts` is spelled exactly as one of: `asset`, `liability`, `equity`, `income`, `expense` (lowercase, no typos). Same check for `normalBalance:` values (`debit` or `credit` only).

**`/dashboard/accounts` shows an empty table**
Confirm you actually ran `run-seed.ts` successfully (check the console output for the confirmation message), and confirm the `MY_ORG_ID` you used matches the organization that's currently ACTIVE in your browser's `<OrganizationSwitcher>` — if you have multiple test organizations, you may be seeded into one but currently viewing another.

**"Cannot find module '@/lib/db'" in the accounts page**
Confirm your `tsconfig.json` has the `@/*` path alias configured (this is set up automatically by `create-next-app` when you chose the default import alias in Part 2) — check for a `"paths"` section under `"compilerOptions"` pointing `@/*` to `./src/*`.

**Table renders but columns are misaligned or the type column shows "undefined"**
Double check the property names in the JSX (`a.code`, `a.name`, `a.type`, `a.subtype`, `a.normalBalance`) exactly match the column names as Drizzle exposes them in JavaScript/TypeScript (camelCase, e.g. `normalBalance` not `normal_balance` — Drizzle automatically converts between snake_case in the database and camelCase in your code).
