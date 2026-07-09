# QB Clone: Auth and Database Foundation - Clerk, Organizations, Neon, Drizzle

File 3 of 8. Covers: real login with Clerk, multi-tenancy via Clerk Organizations, a free Postgres database on Neon, and Drizzle ORM with the first schema and migration. See file "00 Master Overview and Architecture" for the big picture.

**Next.js 16 note:** the request-interception file used below is named **`src/proxy.ts`**, not the older `src/middleware.ts` from pre-16 tutorials (Next.js 16 renamed the file/location convention; the Clerk API called inside it, `clerkMiddleware`, is unchanged - do not create both files in the same project).

---

## PART A: Adding Login with Clerk

### Create a Clerk account and application

1. Go to https://clerk.com, sign up (free, no credit card)
2. Click "Create Application", name it `qb-clone`
3. Leave "Email" checked under sign-in options
4. Click Create Application
5. Keep the API Keys page open - you need NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY and CLERK_SECRET_KEY

### Install Clerk

```
npm install @clerk/nextjs
```

### Add your keys

Create `.env.local` at the project root (same level as package.json):
```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxx
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxx
```
Confirm `.gitignore` contains a line with `.env*.local`. Stop the dev server (Ctrl+C) and restart: `npm run dev`.

### Wrap the app with ClerkProvider

Replace `src/app/layout.tsx` entirely:
```tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export const metadata: Metadata = {
  title: "QB Clone",
  description: "A QuickBooks clone built for learning",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

### Add sign-in / sign-up UI (temporary version, replaced in Part B below)

Replace `src/app/page.tsx` entirely:
```tsx
import {
  SignedIn,
  SignedOut,
  SignInButton,
  SignUpButton,
  UserButton,
} from "@clerk/nextjs";

export default function Home() {
  return (
    <main style={{ padding: "2rem" }}>
      <h1>QB Clone</h1>

      <SignedOut>
        <p>You are not signed in.</p>
        <SignInButton />
        <SignUpButton />
      </SignedOut>

      <SignedIn>
        <p>You are signed in!</p>
        <UserButton />
      </SignedIn>
    </main>
  );
}
```
Save, check localhost:3000. Click Sign Up, use a real email, complete verification, confirm you land back showing "You are signed in!" and your avatar.

### Protect a page with proxy.ts (Next.js 16's renamed middleware)

Create `src/proxy.ts` (directly inside `src/`, NOT inside `src/app/`, and NOT named `middleware.ts`):
```ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher(["/dashboard(.*)"]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
```

Create `src/app/dashboard/page.tsx` (temporary version, replaced in Part B below):
```tsx
import { currentUser } from "@clerk/nextjs/server";

export default async function DashboardPage() {
  const user = await currentUser();

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Dashboard</h1>
      <p>Welcome, {user?.firstName ?? "friend"}! Only signed-in users can see this page.</p>
    </main>
  );
}
```

Test: while signed in, visit /dashboard, see the welcome message. Sign out, revisit /dashboard directly - Clerk should redirect to sign-in automatically.

### Commit

```
git add .
git commit -m "Add Clerk authentication with a protected dashboard page (proxy.ts)"
```

### Troubleshooting A

**Blank white screen / Clerk error after adding ClerkProvider** - `.env.local` missing/misnamed, or dev server not restarted. Confirm the file is named exactly `.env.local` (check with `ls -la` on Mac; enable file extensions in Windows Explorer). Fully stop and restart `npm run dev`.

**"Missing publishableKey"** - No quotes around values in `.env.local`, no extra spaces around `=`, exact spelling (case-sensitive). Restart dev server after any `.env.local` change.

**Sign-up verification email never arrives** - Check spam. Wait a minute and try "resend code."

**`/dashboard` doesn't redirect when logged out** - Confirm the file is at `src/proxy.ts`, NOT `src/app/proxy.ts` and NOT `src/middleware.ts` (a leftover file from an older tutorial). Never have both `proxy.ts` and `middleware.ts` in the same project. Restart dev server after moving/creating it.

**`currentUser()` returns null even though logged in** - Confirm the function is `async` and you used `await currentUser()`.

**Proxy's "matcher" breaks some static assets** - If you add unusual file extensions, add them to the matcher's exclusion list, following the same pattern as the others already listed.

---

## PART B: Organizations = Companies

### Turn on Organizations in Clerk

1. https://dashboard.clerk.com, select your `qb-clone` application
2. Left sidebar -> Organizations (may be under "Configure")
3. Toggle it ON
4. Leave default settings (anyone can create an organization)

### Update the homepage with an org switcher

Replace `src/app/page.tsx` entirely:
```tsx
import {
  SignedIn,
  SignedOut,
  SignInButton,
  SignUpButton,
  UserButton,
  OrganizationSwitcher,
} from "@clerk/nextjs";
import { auth } from "@clerk/nextjs/server";
import Link from "next/link";

export default async function Home() {
  const { orgId } = await auth();

  return (
    <main style={{ padding: "2rem" }}>
      <h1>QB Clone</h1>

      <SignedOut>
        <p>You are not signed in.</p>
        <SignInButton />
        <SignUpButton />
      </SignedOut>

      <SignedIn>
        <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
          <UserButton />
          <OrganizationSwitcher
            afterCreateOrganizationUrl="/dashboard"
            afterSelectOrganizationUrl="/dashboard"
          />
        </div>

        {orgId ? (
          <p style={{ marginTop: "1rem" }}>
            <Link href="/dashboard">Go to your Dashboard -&gt;</Link>
          </p>
        ) : (
          <p style={{ marginTop: "1rem" }}>
            Create or select a company above to get started.
          </p>
        )}
      </SignedIn>
    </main>
  );
}
```
Refresh while signed in, click the switcher, "Create organization," name it "Joe's Landscaping," create it.

### Require an active organization on the dashboard

Replace `src/app/dashboard/page.tsx` entirely:
```tsx
import { auth, currentUser } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";

export default async function DashboardPage() {
  const { orgId } = await auth();
  const user = await currentUser();

  if (!orgId) {
    redirect("/");
  }

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Dashboard</h1>
      <p>Welcome, {user?.firstName ?? "friend"}!</p>
      <p>You&apos;re currently working in organization: {orgId}</p>
    </main>
  );
}
```
Test in an incognito window: visiting /dashboard without an active org redirects to /. With an org active, /dashboard shows the raw org ID (starts with `org_`).

### Commit

```
git add .
git commit -m "Add Clerk Organizations: org switcher, require active org for dashboard"
```

### Troubleshooting B

**`<OrganizationSwitcher>` doesn't appear** - Confirm Organizations is toggled ON in Clerk's dashboard; refresh both the dashboard and your app.

**Clicking "Create organization" errors out** - Check browser console (F12); usually an outdated `@clerk/nextjs` - run `npm install @clerk/nextjs@latest`, restart dev server.

**`orgId` always null after creating an org** - Explicitly select the organization as active in the switcher after creating it.

**Redirect loop** - Confirm you're actually signed in first (SignedIn content visible on `/`).

**TypeScript complains about apostrophe in JSX** - Use `&apos;` for apostrophes in JSX text, as shown (`You&apos;re`).

**Wrong organization ID showing** - Click the switcher and explicitly select the correct org if you created multiple while testing.

---

## PART C: Getting a Free Database with Neon

### Create a Neon account and project

1. https://neon.tech, sign up (GitHub sign-in fastest)
2. Click "Create a project", name it `qb-clone`, accept default Postgres version, choose a nearby region, click "Create Project"

### Understand the connection string

Neon's dashboard shows something like:
```
postgresql://neondb_owner:AbC123XyZ@ep-cool-forest-12345.us-east-1.aws.neon.tech/neondb?sslmode=require
```
`neondb_owner` = username, `AbC123XyZ` = password, `ep-cool-forest-12345...` = server address, `neondb` = database name, `?sslmode=require` = encrypted connection.

### Copy both pooled and unpooled connection strings

Find a toggle labeled "Pooled connection" (hostname contains `-pooler`) and "Direct connection" (no `-pooler`). Copy both.

### Add both to your project

Add to `.env.local`:
```
DATABASE_URL="postgresql://neondb_owner:AbC123XyZ@ep-cool-forest-12345-pooler.us-east-1.aws.neon.tech/neondb?sslmode=require"
DATABASE_URL_UNPOOLED="postgresql://neondb_owner:AbC123XyZ@ep-cool-forest-12345.us-east-1.aws.neon.tech/neondb?sslmode=require"
```
Replace with your real copied values.

```markdown
a row like `PostgreSQL 16.4 on x86_64-pc-linux-gnu...`

Scratch test:
```sql
CREATE TABLE scratch_test (id serial primary key, note text);
INSERT INTO scratch_test (note) VALUES ('hello from Neon');
SELECT * FROM scratch_test;
DROP TABLE scratch_test;
```

### Confirm .env.local isn't tracked by git

```
git status
```
Confirm `.env.local` is NOT listed. Commit other changes if any:
```
git add .
git commit -m "Prepare environment for Neon database connection"
```

### Checkpoint C
- [ ] Neon account/project created
- [ ] DATABASE_URL and DATABASE_URL_UNPOOLED both set in .env.local
- [ ] SELECT version(); ran successfully
- [ ] .env.local confirmed NOT tracked by git

### Troubleshooting C

**Project creation seems stuck** - Refresh after 30 seconds; provisioning is usually near-instant.

**Can't find "Pooled connection" toggle** - Look for the word "pooler" appearing in one of the two hostnames shown - that's the pooled one.

**Connection string looks broken across multiple lines in the editor** - Just visual wrapping if you didn't manually press Enter mid-string; turn on word-wrap in VS Code (View menu).

**Should DATABASE_URL have quotes?** - Keep double quotes as shown, since connection strings can contain special characters like `&` or `?`.

**Scratch test's DROP TABLE says "table does not exist"** - Run all four SQL lines together in one execution, top to bottom, not one at a time skipping the CREATE.

---

## PART D: Talking to the Database with Drizzle ORM

### Install Drizzle and the Neon driver

```
npm install drizzle-orm @neondatabase/serverless ws
npm install -D drizzle-kit @types/ws dotenv tsx
```

### Create the database client file

Create folder `src/lib/db/`, inside it `index.ts`:
```ts
import { Pool, neonConfig } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-serverless";
import ws from "ws";
import * as schema from "./schema";

neonConfig.webSocketConstructor = ws;

const pool = new Pool({ connectionString: process.env.DATABASE_URL! });

export const db = drizzle(pool, { schema });
```

### Define the first schema

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
(This schema is extended further in file 04 with more tables - always add new tables to the end of this same file, never delete existing ones without a real migration plan.)

### Configure drizzle-kit

Create `drizzle.config.ts` at the project root:
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
Add to `package.json`'s "scripts" section:
```json
"db:generate": "drizzle-kit generate",
"db:migrate": "drizzle-kit migrate"
```

### Generate and run the first migration

```
npm run db:generate
```
Creates `drizzle/migrations/0000_something_random.sql` with real SQL (CREATE TYPE, CREATE TABLE statements). Then:
```
npm run db:migrate
```

### Verify in Neon's dashboard

```sql
SELECT * FROM accounts;
SELECT * FROM organizations;
```
Both should succeed, zero rows.

### Query from real code

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
Run:
```
npx tsx src/lib/db/seed-test.ts
```
Delete this file once confirmed. Clean up:
```sql
DELETE FROM organizations WHERE id = 'org_test_123';
```

### Commit

```
git add .
git commit -m "Add Drizzle ORM, first schema (organizations, accounts), first migration"
```

### Checkpoint D
- [ ] Packages installed
- [ ] src/lib/db/index.ts and schema.ts created
- [ ] npm run db:generate produced a readable migration
- [ ] npm run db:migrate ran successfully
- [ ] Tables visible in Neon
- [ ] Test insert/read via tsx succeeded

### Troubleshooting D

**"DATABASE_URL_UNPOOLED is not defined" during db:generate** - Confirm drizzle.config.ts is at the project ROOT, and `import "dotenv/config"` is present at its top.

**db:migrate connection error / ETIMEDOUT** - Confirm DATABASE_URL_UNPOOLED is the direct (no `-pooler`) string.

**"Cannot find module '@/lib/db'" in seed-test.ts** - This file uses relative imports (./index, ./schema) intentionally, not the @/ alias, so it runs correctly via tsx outside Next.js's bundler.

**Duplicate key error running seed-test.ts twice** - Expected; delete the row first via Neon's SQL Editor, or change the id in the script.

**WebSocket constructor error** - Confirm `import ws from "ws";` and `neonConfig.webSocketConstructor = ws;` are both present in index.ts.

**Migration file looks empty/partial** - Only during early learning (no real data yet): delete drizzle/migrations folder and regenerate fresh.

**TypeScript errors in schema.ts about enum values** - Every enum value must be a lowercase quoted string, comma-separated, matching exactly.

---

This completes file 3 of 8. Proceed to file "03 Accounting Core - Double-Entry Theory, Chart of Accounts, Journal Engine" next.
```

Expected:
