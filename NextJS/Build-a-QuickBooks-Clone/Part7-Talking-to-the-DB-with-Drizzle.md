## Part 7: Talking to the Database with Drizzle ORM

Goal: install Drizzle, define our first schema, run our first migration against Neon, and query the database from real Next.js code.

Prerequisite: Parts 1-6 completed.

---

### 1. Install Drizzle and the Neon driver

In your terminal, inside `qb-clone`:
```
npm install drizzle-orm @neondatabase/serverless ws
npm install -D drizzle-kit @types/ws dotenv tsx
```

### 2. Create the database client file

Create the folder `src/lib/db/`. Inside it, create `index.ts`:

```ts
import { Pool, neonConfig } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-serverless";
import ws from "ws";
import * as schema from "./schema";

neonConfig.webSocketConstructor = ws;

const pool = new Pool({ connectionString: process.env.DATABASE_URL! });

export const db = drizzle(pool, { schema });
```

### 3. Define our first schema

In the same folder, create `schema.ts`:

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
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});
```

### 4. Configure drizzle-kit

Create `drizzle.config.ts` at the project root (same level as `package.json`):

```ts
import { defineConfig } from "drizzle-kit";
import "dotenv/config";

export default defineConfig({
  schema: "./src/lib/db/schema.ts",
  out: "./drizzle/migrations",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL_UNPOOLED!,
  },
});
```

Open `package.json`, find the `"scripts"` section, and add these two lines inside it (keep the existing lines, just add these):
```json
"db:generate": "drizzle-kit generate",
"db:migrate": "drizzle-kit migrate"
```

### 5. Generate and run your first migration

```
npm run db:generate
```

Expected output ends with something like: "1 tables created, 1 enum created". A new folder `drizzle/migrations/` appears containing a file like `0000_something_random.sql`. Open it — you'll see real SQL creating the `account_type` enum, the `organizations` table, and the `accounts` table.

Now apply it to your actual database:
```
npm run db:migrate
```
Expected output: something like "Migrations applied successfully!"

### 6. Verify in Neon's dashboard

In Neon's SQL Editor, run:
```sql
SELECT * FROM accounts;
SELECT * FROM organizations;
```
Both should succeed and return zero rows.

### 7. Query the database from real code

Create `src/lib/db/seed-test.ts`:

```ts
import { db } from "./index";
import { organizations } from "./schema";

async function main() {
  const [org] = await db
    .insert(organizations)
    .values({
      id: "org_test_123",
      name: "Test Company",
    })
    .returning();

  console.log("Inserted:", org);

  const all = await db.select().from(organizations);
  console.log("All organizations:", all);
}

main();
```

Run it:
```
npx tsx src/lib/db/seed-test.ts
```

Expected output shows the inserted row, then the full organizations list containing it.

Delete `src/lib/db/seed-test.ts` once confirmed. Clean up the test row via Neon's SQL Editor:
```sql
DELETE FROM organizations WHERE id = 'org_test_123';
```

### 8. Commit

```
git add .
git commit -m "Add Drizzle ORM, first schema (organizations, accounts), first migration"
```

---

### ✅ Checkpoint

- [ ] All packages installed
- [ ] `src/lib/db/index.ts` and `src/lib/db/schema.ts` created
- [ ] `npm run db:generate` produced a readable migration file
- [ ] `npm run db:migrate` ran successfully
- [ ] Tables visible in Neon's dashboard
- [ ] Test insert/read via `tsx` succeeded

---

### Troubleshooting

**`npm run db:generate` errors with "DATABASE_URL_UNPOOLED is not defined" or similar**
Confirm `drizzle.config.ts` is at the project ROOT, not inside `src/`. Confirm `.env.local` really has `DATABASE_URL_UNPOOLED` set (Part 6). The `import "dotenv/config"` line at the top of `drizzle.config.ts` is what loads `.env.local` for this command-line tool — don't remove it.

**`npm run db:migrate` fails with a connection error / ETIMEDOUT**
Check your internet connection. Also confirm you copied the UNPOOLED (no `-pooler` in hostname) connection string into `DATABASE_URL_UNPOOLED` specifically — using the pooled one for migrations can occasionally cause issues with certain migration operations.

**`npx tsx src/lib/db/seed-test.ts` says "Cannot find module '@/lib/db'" or path errors**
This file uses relative imports (`./index`, `./schema`), not the `@/` alias, specifically so it runs correctly outside of Next.js's own bundler via `tsx`. Confirm you typed `./index` and `./schema`, not `@/lib/db` and `@/lib/db/schema`, in `seed-test.ts`.

**Running the seed script twice gives a duplicate key error**
That's expected and correct — `id: "org_test_123"` is a fixed primary key, so inserting it twice violates uniqueness. Either delete the row first via Neon's SQL Editor (step 7's cleanup command) before re-running, or change the `id` value in the script.

**`ws` related error like "WebSocket constructor" when running the seed script**
Confirm the top of `src/lib/db/index.ts` has both `import ws from "ws";` and `neonConfig.webSocketConstructor = ws;` exactly as shown — this line is required specifically because Node.js doesn't have WebSocket support built in the way a browser does.

**Migration file looks empty or only has partial tables**
Delete the `drizzle/migrations` folder entirely and your local migration journal, then run `npm run db:generate` again fresh. Only do this if you have NOT yet run `db:migrate` against a real database with important data — for this early stage of the course that's always safe.

**TypeScript errors inside `schema.ts` about enum values**
Confirm every enum value is a plain lowercase string in quotes, comma-separated, exactly matching the arrays shown above — a stray comma or missing quote is the most common cause.

**Package install fails or shows peer dependency warnings mentioning Next.js/React versions**
This project uses Next.js 16 and React 19 (from Part 2). If npm warns about peer dependencies for `drizzle-orm` or `@neondatabase/serverless`, it's almost always safe to proceed — these packages are framework-agnostic and don't depend on a specific Next.js version. If you see an actual install failure (not just a warning), run `npm install` again; a transient npm registry issue is more likely than a real incompatibility.
