# Part 7 — Sync Clerk Organizations to Database `getOrCreateOrganization()`

In Part 6, we created our first application database table:

```txt
organizations
```

That table is currently empty.

In Part 5, we enabled Clerk Organizations. Clerk knows which company workspace the user has selected.

But our database does not know about those Clerk organizations yet.

In this part, we connect the two worlds.

By the end of this part, you will have:

- A `getOrCreateCurrentOrganization()` service
- A local database row for each active Clerk organization
- A safer organization sync pattern using Clerk + Drizzle
- An app header that shows the synced database organization
- A dashboard that confirms the active database organization
- An auth diagnostic page showing both Clerk and database organization context
- A database organization list page
- A database status page linked to organization diagnostics
- Verification through Neon SQL, Drizzle Studio, and the app UI

This is a major step toward true multi-tenancy.

---

# 1. Understand Clerk Organization vs Database Organization

## The Target

We are connecting Clerk organization identity to our own local database organization records.

---

## The Concept

Clerk and our database have different jobs.

```txt
Clerk Organization
  = identity-side company workspace

Database Organization
  = application-side company record used by accounting tables
```

A helpful analogy:

```txt
Clerk organization       = company access badge
Database organization    = company filing cabinet
Accounting records       = documents inside the cabinet
```

Clerk tells us:

```txt
The signed-in user is currently working in org_abc123.
```

Our database needs a matching row:

```txt
organizations.id                      = internal UUID
organizations.clerk_organization_id   = org_abc123
organizations.name                    = Demo Pte. Ltd.
```

Later, accounting tables will reference the internal database UUID:

```txt
accounts.organization_id
invoices.organization_id
journal_entries.organization_id
```

That gives us strong database relationships.

---

## The Implementation

The sync flow will look like this:

```txt
User signs in
  |
  v
User selects Clerk organization
  |
  v
App reads Clerk orgId from auth()
  |
  v
App looks for matching row in organizations table
  |
  |-- found      -> return existing database organization
  |
  |-- not found  -> fetch organization details from Clerk
                   insert row into Postgres
                   return database organization
```

The service will be named:

```ts
getOrCreateCurrentOrganization()
```

It means:

> Give me the local database organization for the currently selected Clerk organization. If it does not exist yet, create it.

---

## The Verification

At the end of this part:

1. Create or select a Clerk organization.
2. Visit the dashboard.
3. Open `/settings/database`.
4. You should see the organization row count increase.
5. Open `/settings/database/organizations`.
6. You should see the local database organization row.

---

# 2. Confirm the Existing Database Schema

## The Target

We are confirming that `organizations` already has the columns needed for Clerk sync.

---

## The Concept

Before writing sync code, we check whether our table can store the required data.

We need:

```txt
Internal ID
Clerk organization ID
Name
Slug
Image URL
Created timestamp
Updated timestamp
```

Part 6 already created this.

---

## The Implementation

Open:

```txt
db/schema.ts
```

It should contain this table:

```ts
// db/schema.ts

import {
  index,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from "drizzle-orm/pg-core";

/**
 * organizations
 *
 * This table is our application's local copy of a Clerk organization.
 *
 * Clerk remains the identity provider, but our accounting records need a local
 * organization row to reference with foreign keys.
 *
 * In Part 7, we will add getOrCreateOrganization() to sync the active Clerk
 * organization into this table.
 */
export const organizations = pgTable(
  "organizations",
  {
    /**
     * Internal database ID.
     *
     * We use a UUID so this ID is globally unique and safe to reference from
     * many future tables.
     */
    id: uuid("id").defaultRandom().primaryKey(),

    /**
     * Clerk's organization ID.
     *
     * Example:
     *   org_2abc123...
     *
     * This lets us connect Clerk's organization identity to our own database.
     */
    clerkOrganizationId: text("clerk_organization_id").notNull(),

    /**
     * Human-readable company name.
     *
     * Example:
     *   Demo Pte. Ltd.
     */
    name: text("name").notNull(),

    /**
     * Optional Clerk organization slug.
     *
     * Example:
     *   demo-pte-ltd
     */
    slug: text("slug"),

    /**
     * Optional organization image URL from Clerk.
     */
    imageUrl: text("image_url"),

    /**
     * Row creation timestamp.
     */
    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),

    /**
     * Row update timestamp.
     *
     * We will manually set this when updating organization records.
     */
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    uniqueIndex("organizations_clerk_organization_id_idx").on(
      table.clerkOrganizationId,
    ),
    index("organizations_slug_idx").on(table.slug),
  ],
);

export type Organization = typeof organizations.$inferSelect;
export type NewOrganization = typeof organizations.$inferInsert;
```

Important unique index:

```ts
uniqueIndex("organizations_clerk_organization_id_idx").on(
  table.clerkOrganizationId,
)
```

This guarantees one Clerk organization maps to only one database organization row.

That protects us from duplicate company records.

---

## The Verification

Run:

```bash
pnpm db:migrate
```

You should see that migrations are already applied, or that there is nothing new to apply.

Then run:

```bash
pnpm check
```

The project should still pass.

---

# 3. Create the Organization Sync Service

## The Target

We are creating:

```txt
services/organizations/get-or-create-organization.ts
```

This file will contain the main sync logic.

---

## The Concept

A service is where business logic belongs.

We do **not** want organization sync logic scattered across pages and components.

Bad pattern:

```tsx
// Page component directly mixes Clerk fetching, Drizzle queries,
// insert logic, and UI rendering.
```

Better pattern:

```ts
const organization = await getOrCreateCurrentOrganization();
```

Think of the service as a dedicated office clerk who knows exactly how to file company records.

The UI should not need to know how the filing cabinet works.

---

## The Implementation

Create the folder:

```bash
mkdir -p services/organizations
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force services/organizations
```

Create:

```txt
services/organizations/get-or-create-organization.ts
```

Add:

```ts
// services/organizations/get-or-create-organization.ts

import { clerkClient } from "@clerk/nextjs/server";
import { eq } from "drizzle-orm";
import { db } from "@/db";
import { organizations, type Organization } from "@/db/schema";
import { getCurrentOrganizationContext } from "@/lib/auth";

/**
 * Finds a local database organization by Clerk organization ID.
 *
 * This function only reads from our database. It does not call Clerk.
 */
export async function findOrganizationByClerkId(
  clerkOrganizationId: string,
): Promise<Organization | null> {
  const [organization] = await db
    .select()
    .from(organizations)
    .where(eq(organizations.clerkOrganizationId, clerkOrganizationId))
    .limit(1);

  return organization ?? null;
}

/**
 * Returns the currently active organization from our local database.
 *
 * This does not create anything. It simply checks whether the selected Clerk
 * organization has already been synced into the local organizations table.
 */
export async function getCurrentDatabaseOrganization(): Promise<Organization | null> {
  const currentOrganization = await getCurrentOrganizationContext();

  if (!currentOrganization) {
    return null;
  }

  return findOrganizationByClerkId(currentOrganization.id);
}

/**
 * Fetches organization details from Clerk.
 *
 * Clerk is the identity source of truth, so if our local database does not yet
 * have a row for the current organization, we fetch the organization name,
 * slug, and image URL from Clerk before inserting the local row.
 */
async function getClerkOrganizationDetails(clerkOrganizationId: string) {
  const client = await clerkClient();

  return client.organizations.getOrganization({
    organizationId: clerkOrganizationId,
  });
}

/**
 * Gets or creates the local database organization for the active Clerk
 * organization.
 *
 * This is the key multi-tenancy bridge:
 *
 * Clerk orgId
 *   -> organizations.clerk_organization_id
 *   -> organizations.id
 *
 * Later accounting tables will reference organizations.id.
 */
export async function getOrCreateCurrentOrganization(): Promise<Organization | null> {
  const currentOrganization = await getCurrentOrganizationContext();

  if (!currentOrganization) {
    return null;
  }

  const existingOrganization = await findOrganizationByClerkId(
    currentOrganization.id,
  );

  if (existingOrganization) {
    return existingOrganization;
  }

  const clerkOrganization = await getClerkOrganizationDetails(
    currentOrganization.id,
  );

  const [createdOrganization] = await db
    .insert(organizations)
    .values({
      clerkOrganizationId: currentOrganization.id,
      name: clerkOrganization.name,
      slug: clerkOrganization.slug ?? currentOrganization.slug ?? null,
      imageUrl: clerkOrganization.imageUrl ?? null,
    })
    .onConflictDoUpdate({
      target: organizations.clerkOrganizationId,
      set: {
        name: clerkOrganization.name,
        slug: clerkOrganization.slug ?? currentOrganization.slug ?? null,
        imageUrl: clerkOrganization.imageUrl ?? null,
        updatedAt: new Date(),
      },
    })
    .returning();

  return createdOrganization ?? null;
}

/**
 * Forces a sync from Clerk into our local database.
 *
 * Unlike getOrCreateCurrentOrganization(), this function always fetches the
 * latest Clerk organization details and upserts them into Postgres.
 *
 * This is useful after organization profile changes.
 */
export async function syncCurrentOrganizationFromClerk(): Promise<Organization | null> {
  const currentOrganization = await getCurrentOrganizationContext();

  if (!currentOrganization) {
    return null;
  }

  const clerkOrganization = await getClerkOrganizationDetails(
    currentOrganization.id,
  );

  const [syncedOrganization] = await db
    .insert(organizations)
    .values({
      clerkOrganizationId: currentOrganization.id,
      name: clerkOrganization.name,
      slug: clerkOrganization.slug ?? currentOrganization.slug ?? null,
      imageUrl: clerkOrganization.imageUrl ?? null,
      updatedAt: new Date(),
    })
    .onConflictDoUpdate({
      target: organizations.clerkOrganizationId,
      set: {
        name: clerkOrganization.name,
        slug: clerkOrganization.slug ?? currentOrganization.slug ?? null,
        imageUrl: clerkOrganization.imageUrl ?? null,
        updatedAt: new Date(),
      },
    })
    .returning();

  return syncedOrganization ?? null;
}

/**
 * Requires a synced local database organization.
 *
 * Later server actions will use this before creating organization-scoped
 * records such as accounts, invoices, bills, and journal entries.
 */
export async function requireCurrentDatabaseOrganization(): Promise<Organization> {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    throw new Error(
      "No active organization selected. Create or select a company workspace before continuing.",
    );
  }

  return organization;
}
```

Important part:

```ts
.onConflictDoUpdate({
  target: organizations.clerkOrganizationId,
  set: {
    ...
  },
})
```

This protects against a race condition.

A race condition is when two requests try to do the same thing at the same time.

For example:

```txt
Request A checks for organization row.
Request B checks for organization row.
Both see no row.
Both try to insert.
```

The unique index prevents duplicates, and `onConflictDoUpdate` makes the insert safe.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

If you see a Clerk type error around `clerkClient`, update Clerk:

```bash
pnpm add @clerk/nextjs@latest
```

Then run:

```bash
pnpm build
```

---

# 4. Update the Active Organization Badge

## The Target

We are updating:

```txt
components/active-organization-badge.tsx
```

so it displays the synced database organization.

---

## The Concept

Previously, the badge only showed Clerk context.

Now we want the header to prove that the active Clerk organization has a matching database row.

This is like saying:

```txt
Access badge recognized.
Company filing cabinet found.
```

Because `getOrCreateCurrentOrganization()` is idempotent, calling it from the header is safe:

- If the row exists, it returns it.
- If the row does not exist, it creates it.
- It will not create duplicates because of the unique index.

---

## The Implementation

Open:

```txt
components/active-organization-badge.tsx
```

Replace the entire file with:

```tsx
// components/active-organization-badge.tsx

import Link from "next/link";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

export async function ActiveOrganizationBadge() {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return (
      <Link
        href="/onboarding/organization"
        className="rounded-full bg-amber-50 px-3 py-1 text-xs font-semibold text-amber-700 transition hover:bg-amber-100"
      >
        No company selected
      </Link>
    );
  }

  return (
    <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
      Company: {organization.name}
    </span>
  );
}
```

The key change is:

```tsx
const organization = await getOrCreateCurrentOrganization();
```

The header now becomes part of the sync path.

---

## The Verification

Start the dev server:

```bash
pnpm dev
```

Sign in and select or create an organization.

Open:

```txt
http://localhost:3000/dashboard
```

The header should show something like:

```txt
Company: Demo Pte. Ltd.
```

Now open Neon SQL editor and run:

```sql
select id, clerk_organization_id, name, slug, created_at, updated_at
from organizations
order by created_at desc;
```

You should see a row for the active Clerk organization.

---

# 5. Create Organization Diagnostics Helpers

## The Target

We are creating:

```txt
lib/organization-diagnostics.ts
```

This helper will list local database organizations for diagnostic pages.

---

## The Concept

We need a safe way to inspect synced organization rows.

This is not business logic like creating invoices. It is a diagnostic helper for admin/development visibility.

Think of it like opening the filing cabinet index and checking which company folders exist.

---

## The Implementation

Create:

```txt
lib/organization-diagnostics.ts
```

Add:

```ts
// lib/organization-diagnostics.ts

import { desc } from "drizzle-orm";
import { db } from "@/db";
import { organizations } from "@/db/schema";

/**
 * Returns local database organizations ordered by newest first.
 *
 * This is used by diagnostic settings pages so we can verify Clerk-to-database
 * organization sync.
 */
export async function listDatabaseOrganizations() {
  return db
    .select({
      id: organizations.id,
      clerkOrganizationId: organizations.clerkOrganizationId,
      name: organizations.name,
      slug: organizations.slug,
      imageUrl: organizations.imageUrl,
      createdAt: organizations.createdAt,
      updatedAt: organizations.updatedAt,
    })
    .from(organizations)
    .orderBy(desc(organizations.createdAt));
}
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

---

# 6. Update the Dashboard for Synced Database Organizations

## The Target

We are updating:

```txt
app/dashboard/page.tsx
```

so it shows the local database organization ID.

---

## The Concept

Clerk organization ID tells us identity context.

Database organization ID tells us accounting context.

Eventually, accounting records will look like:

```txt
invoice.organization_id = organizations.id
journal_entry.organization_id = organizations.id
account.organization_id = organizations.id
```

So the dashboard should now show:

```txt
Active database organization selected
```

not merely:

```txt
Active Clerk organization selected
```

---

## The Implementation

Open:

```txt
app/dashboard/page.tsx
```

Replace the entire file with:

```tsx
// app/dashboard/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { StatCard } from "@/components/stat-card";
import { getCurrentWorkspaceContext } from "@/lib/auth";
import { formatMoney } from "@/lib/money";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

export const dynamic = "force-dynamic";

const recentActivityRows = [
  {
    date: "2026-01-05",
    activity: "Invoice INV-0007 issued to Merlion Trading",
    status: "Awaiting payment",
    statusClass: "bg-amber-50 text-amber-700",
    amountCents: 218000,
  },
  {
    date: "2026-01-04",
    activity: "Payment received from Orchard Studio",
    status: "Posted",
    statusClass: "bg-emerald-50 text-emerald-700",
    amountCents: 109000,
  },
  {
    date: "2026-01-03",
    activity: "Vendor bill recorded for Cloud Hosting SG",
    status: "In review",
    statusClass: "bg-sky-50 text-sky-700",
    amountCents: 54500,
  },
];

export default async function DashboardPage() {
  const { user, organization: clerkOrganization } =
    await getCurrentWorkspaceContext();

  const databaseOrganization = await getOrCreateCurrentOrganization();

  return (
    <AppLayout
      title="Dashboard"
      description="A high-level preview of business health. Later, these numbers will be calculated from posted journal entries."
    >
      <section className="mb-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
          Signed-in workspace
        </p>

        <h2 className="mt-3 text-2xl font-bold tracking-tight text-slate-950">
          Welcome{user ? `, ${user.displayName}` : ""}.
        </h2>

        {user?.primaryEmail ? (
          <p className="mt-2 text-sm leading-6 text-slate-500">
            Signed in as{" "}
            <span className="font-semibold text-slate-700">
              {user.primaryEmail}
            </span>
          </p>
        ) : null}

        {databaseOrganization ? (
          <div className="mt-5 rounded-2xl border border-emerald-200 bg-emerald-50 p-4">
            <p className="text-sm font-semibold text-emerald-800">
              Active database organization synced
            </p>

            <p className="mt-2 text-sm leading-6 text-emerald-700">
              You are working in{" "}
              <span className="font-semibold">{databaseOrganization.name}</span>
              . The local database organization ID is{" "}
              <span className="font-mono font-semibold">
                {databaseOrganization.id}
              </span>
              .
            </p>

            <dl className="mt-4 grid gap-3 text-xs sm:grid-cols-2">
              <div className="rounded-xl bg-white/70 p-3">
                <dt className="font-semibold text-emerald-900">
                  Clerk organization ID
                </dt>
                <dd className="mt-1 break-all font-mono text-emerald-700">
                  {databaseOrganization.clerkOrganizationId}
                </dd>
              </div>

              <div className="rounded-xl bg-white/70 p-3">
                <dt className="font-semibold text-emerald-900">
                  Organization slug
                </dt>
                <dd className="mt-1 break-all font-mono text-emerald-700">
                  {databaseOrganization.slug ?? "No slug"}
                </dd>
              </div>
            </dl>
          </div>
        ) : clerkOrganization ? (
          <div className="mt-5 rounded-2xl border border-rose-200 bg-rose-50 p-4">
            <p className="text-sm font-semibold text-rose-800">
              Clerk organization exists, but database sync failed
            </p>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-rose-700">
              Clerk reports an active organization, but the app could not create
              or read the matching local database organization. Check your Neon
              connection and Drizzle migration status.
            </p>

            <Link
              href="/settings/database"
              className="mt-4 inline-flex rounded-xl bg-rose-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-rose-700"
            >
              Check database status
            </Link>
          </div>
        ) : (
          <div className="mt-5 rounded-2xl border border-amber-200 bg-amber-50 p-4">
            <p className="text-sm font-semibold text-amber-800">
              No company workspace selected
            </p>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-amber-700">
              Before creating invoices, bills, accounts, or journal entries,
              create a company organization. Accounting data belongs to a
              company, not only to a user account.
            </p>

            <Link
              href="/onboarding/organization"
              className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-amber-700"
            >
              Create company workspace
            </Link>
          </div>
        )}
      </section>

      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          title="Cash"
          value={formatMoney(4285000)}
          description="Preview bank position across operating accounts."
          tone="emerald"
        />

        <StatCard
          title="Revenue"
          value={formatMoney(1862400)}
          description="Preview revenue for the current month."
          tone="sky"
        />

        <StatCard
          title="Receivables"
          value={formatMoney(724900)}
          description="Preview customer invoices awaiting payment."
          tone="amber"
        />

        <StatCard
          title="Payables"
          value={formatMoney(318700)}
          description="Preview vendor bills awaiting settlement."
          tone="rose"
        />
      </section>

      <section className="mt-6 grid gap-6 xl:grid-cols-[1.3fr_0.7fr]">
        <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h2 className="text-lg font-semibold text-slate-950">
                Recent accounting activity
              </h2>

              <p className="mt-1 text-sm leading-6 text-slate-500">
                This preview shows the type of ledger activity GreyMatter
                Ledger will track after we connect the database.
              </p>
            </div>

            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
              Preview data
            </span>
          </div>

          <div className="mt-6 overflow-hidden rounded-xl border border-slate-200">
            <table className="w-full border-collapse text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-semibold">Date</th>
                  <th className="px-4 py-3 font-semibold">Activity</th>
                  <th className="px-4 py-3 font-semibold">Status</th>
                  <th className="px-4 py-3 text-right font-semibold">
                    Amount
                  </th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-200 bg-white">
                {recentActivityRows.map((row) => (
                  <tr key={`${row.date}-${row.activity}`}>
                    <td className="px-4 py-3 text-slate-500">{row.date}</td>

                    <td className="px-4 py-3 font-medium text-slate-900">
                      {row.activity}
                    </td>

                    <td className="px-4 py-3">
                      <span
                        className={`rounded-full px-2 py-1 text-xs font-semibold ${row.statusClass}`}
                      >
                        {row.status}
                      </span>
                    </td>

                    <td className="px-4 py-3 text-right font-semibold text-slate-900">
                      {formatMoney(row.amountCents)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </article>

        <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-950">
            Multi-tenant accounting guardrails
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            Organization context is the foundation for safe accounting data
            isolation.
          </p>

          <ul className="mt-5 space-y-3 text-sm text-slate-700">
            <li className="rounded-xl bg-slate-50 p-3">
              Every journal entry will belong to one database organization.
            </li>
            <li className="rounded-xl bg-slate-50 p-3">
              Every invoice and bill will be scoped by organization ID.
            </li>
            <li className="rounded-xl bg-slate-50 p-3">
              Reports will only read journal lines from the active company.
            </li>
            <li className="rounded-xl bg-slate-50 p-3">
              Users can switch companies without mixing accounting records.
            </li>
          </ul>
        </article>
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Run:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000/dashboard
```

If an organization is selected, you should see:

```txt
Active database organization synced
```

You should also see:

```txt
Local database organization ID
Clerk organization ID
Organization slug
```

---

# 7. Update the Auth Status Diagnostic Page

## The Target

We are updating:

```txt
app/settings/auth-status/page.tsx
```

to show:

- Clerk user
- Clerk organization
- Database organization

---

## The Concept

This page now verifies the entire identity-to-database chain:

```txt
Signed-in user
  -> active Clerk organization
  -> synced database organization
```

This is the chain every future accounting operation depends on.

---

## The Implementation

Open:

```txt
app/settings/auth-status/page.tsx
```

Replace the entire file with:

```tsx
// app/settings/auth-status/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { getCurrentWorkspaceContext } from "@/lib/auth";
import { getOrCreateCurrentOrganization } from "@/services/organizations/get-or-create-organization";

export const dynamic = "force-dynamic";

export default async function AuthStatusPage() {
  const { user, organization: clerkOrganization } =
    await getCurrentWorkspaceContext();

  const databaseOrganization = await getOrCreateCurrentOrganization();

  return (
    <AppLayout
      title="Auth Status"
      description="A protected diagnostic page showing what Clerk user, Clerk organization, and database organization data is available to server-side code."
    >
      <section className="grid gap-6 xl:grid-cols-3">
        <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-950">
            Current user profile
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            This data is read from Clerk on the server.
          </p>

          {user ? (
            <dl className="mt-6 divide-y divide-slate-200 overflow-hidden rounded-xl border border-slate-200">
              <div className="bg-slate-50 px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Clerk user ID
                </dt>
                <dd className="mt-1 break-all text-sm text-slate-950">
                  {user.id}
                </dd>
              </div>

              <div className="bg-white px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Display name
                </dt>
                <dd className="mt-1 text-sm text-slate-950">
                  {user.displayName}
                </dd>
              </div>

              <div className="bg-slate-50 px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Primary email
                </dt>
                <dd className="mt-1 text-sm text-slate-950">
                  {user.primaryEmail ?? "No primary email found"}
                </dd>
              </div>
            </dl>
          ) : (
            <div className="mt-6 rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm font-semibold text-rose-700">
              No signed-in user found.
            </div>
          )}
        </article>

        <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-950">
            Active Clerk organization
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            This is the identity-side organization selected by Clerk.
          </p>

          {clerkOrganization ? (
            <dl className="mt-6 divide-y divide-slate-200 overflow-hidden rounded-xl border border-slate-200">
              <div className="bg-slate-50 px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Clerk organization ID
                </dt>
                <dd className="mt-1 break-all text-sm text-slate-950">
                  {clerkOrganization.id}
                </dd>
              </div>

              <div className="bg-white px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">Slug</dt>
                <dd className="mt-1 text-sm text-slate-950">
                  {clerkOrganization.slug ?? "No slug available"}
                </dd>
              </div>

              <div className="bg-slate-50 px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">Role</dt>
                <dd className="mt-1 text-sm text-slate-950">
                  {clerkOrganization.role ?? "No role available"}
                </dd>
              </div>
            </dl>
          ) : (
            <div className="mt-6 rounded-xl border border-amber-200 bg-amber-50 p-4">
              <p className="text-sm font-semibold text-amber-800">
                No active Clerk organization selected.
              </p>

              <Link
                href="/onboarding/organization"
                className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-amber-700"
              >
                Create company workspace
              </Link>
            </div>
          )}
        </article>

        <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-950">
            Synced database organization
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            This is the application-side row future accounting tables will
            reference.
          </p>

          {databaseOrganization ? (
            <dl className="mt-6 divide-y divide-slate-200 overflow-hidden rounded-xl border border-slate-200">
              <div className="bg-slate-50 px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Database organization ID
                </dt>
                <dd className="mt-1 break-all font-mono text-sm text-slate-950">
                  {databaseOrganization.id}
                </dd>
              </div>

              <div className="bg-white px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">Name</dt>
                <dd className="mt-1 text-sm text-slate-950">
                  {databaseOrganization.name}
                </dd>
              </div>

              <div className="bg-slate-50 px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Clerk organization ID
                </dt>
                <dd className="mt-1 break-all font-mono text-sm text-slate-950">
                  {databaseOrganization.clerkOrganizationId}
                </dd>
              </div>

              <div className="bg-white px-4 py-3">
                <dt className="text-sm font-semibold text-slate-600">Slug</dt>
                <dd className="mt-1 text-sm text-slate-950">
                  {databaseOrganization.slug ?? "No slug"}
                </dd>
              </div>
            </dl>
          ) : (
            <div className="mt-6 rounded-xl border border-amber-200 bg-amber-50 p-4">
              <p className="text-sm font-semibold text-amber-800">
                No database organization found.
              </p>

              <p className="mt-2 text-sm leading-6 text-amber-700">
                Select or create a Clerk organization, then reload this page.
              </p>
            </div>
          )}
        </article>
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/settings/auth-status
```

You should see three cards:

```txt
Current user profile
Active Clerk organization
Synced database organization
```

The Clerk organization ID and the database row’s `clerkOrganizationId` should match.

---

# 8. Create a Database Organizations Diagnostic Page

## The Target

We are creating:

```txt
app/settings/database/organizations/page.tsx
```

This page lists local organization rows in Postgres.

---

## The Concept

This page lets us verify that Clerk organizations are being synced into our database.

It is especially useful when switching between multiple company workspaces.

Think of it as the database filing cabinet index.

---

## The Implementation

Create the folder:

```bash
mkdir -p app/settings/database/organizations
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/settings/database/organizations
```

Create:

```txt
app/settings/database/organizations/page.tsx
```

Add:

```tsx
// app/settings/database/organizations/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { listDatabaseOrganizations } from "@/lib/organization-diagnostics";

export const dynamic = "force-dynamic";

export default async function DatabaseOrganizationsPage() {
  const databaseOrganizations = await listDatabaseOrganizations();

  return (
    <AppLayout
      title="Database Organizations"
      description="Inspect local organization rows synced from Clerk into Neon Postgres."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
              Organization sync
            </p>

            <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
              Local database organization rows
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
              These rows live in the <code>organizations</code> table. Future
              accounting records will reference these database IDs.
            </p>
          </div>

          <Link
            href="/settings/auth-status"
            className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
          >
            View auth status
          </Link>
        </div>

        {databaseOrganizations.length > 0 ? (
          <div className="mt-6 overflow-hidden rounded-xl border border-slate-200">
            <table className="w-full border-collapse text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-semibold">Name</th>
                  <th className="px-4 py-3 font-semibold">Database ID</th>
                  <th className="px-4 py-3 font-semibold">Clerk Org ID</th>
                  <th className="px-4 py-3 font-semibold">Slug</th>
                  <th className="px-4 py-3 font-semibold">Created</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-200 bg-white">
                {databaseOrganizations.map((organization) => (
                  <tr key={organization.id}>
                    <td className="px-4 py-3 font-semibold text-slate-950">
                      {organization.name}
                    </td>

                    <td className="px-4 py-3">
                      <code className="break-all text-xs text-slate-600">
                        {organization.id}
                      </code>
                    </td>

                    <td className="px-4 py-3">
                      <code className="break-all text-xs text-slate-600">
                        {organization.clerkOrganizationId}
                      </code>
                    </td>

                    <td className="px-4 py-3 text-slate-600">
                      {organization.slug ?? "—"}
                    </td>

                    <td className="px-4 py-3 text-slate-500">
                      {organization.createdAt.toISOString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="mt-6 rounded-2xl border border-amber-200 bg-amber-50 p-5">
            <p className="text-sm font-semibold text-amber-800">
              No local organization rows yet.
            </p>

            <p className="mt-2 text-sm leading-6 text-amber-700">
              Create or select a Clerk organization, then visit the dashboard.
              The app will sync the active Clerk organization into this table.
            </p>

            <Link
              href="/onboarding/organization"
              className="mt-4 inline-flex rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-amber-700"
            >
              Create company workspace
            </Link>
          </div>
        )}
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/settings/database/organizations
```

If you have visited the dashboard with an active organization, you should see at least one row.

If not, create/select an organization and open:

```txt
http://localhost:3000/dashboard
```

Then return to:

```txt
http://localhost:3000/settings/database/organizations
```

---

# 9. Update the Database Status Page

## The Target

We are updating:

```txt
app/settings/database/page.tsx
```

to link to the local organization rows page.

---

## The Concept

The database status page confirms connectivity.

The organizations diagnostic page confirms synced data.

They belong together.

---

## The Implementation

Open:

```txt
app/settings/database/page.tsx
```

Replace the entire file with:

```tsx
// app/settings/database/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import { getDatabaseHealth } from "@/lib/database-health";

export const dynamic = "force-dynamic";

export default async function DatabaseStatusPage() {
  const health = await getDatabaseHealth();

  return (
    <AppLayout
      title="Database Status"
      description="Verify Neon Postgres connectivity, Drizzle migrations, and application database readiness."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
              Neon Postgres
            </p>

            <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
              Database connection check
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
              This page runs a real server-side query through Drizzle ORM. It
              confirms that the application can reach the database and that the
              initial organizations table exists.
            </p>
          </div>

          {health.ok ? (
            <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
              Connected
            </span>
          ) : (
            <span className="rounded-full bg-rose-50 px-3 py-1 text-xs font-semibold text-rose-700">
              Connection failed
            </span>
          )}
        </div>

        {health.ok ? (
          <dl className="mt-6 divide-y divide-slate-200 overflow-hidden rounded-xl border border-slate-200">
            <div className="grid gap-1 bg-slate-50 px-4 py-3 sm:grid-cols-3">
              <dt className="text-sm font-semibold text-slate-600">Status</dt>
              <dd className="text-sm font-semibold text-emerald-700 sm:col-span-2">
                Database query succeeded
              </dd>
            </div>

            <div className="grid gap-1 bg-white px-4 py-3 sm:grid-cols-3">
              <dt className="text-sm font-semibold text-slate-600">
                Query latency
              </dt>
              <dd className="text-sm text-slate-950 sm:col-span-2">
                {health.latencyMs}ms
              </dd>
            </div>

            <div className="grid gap-1 bg-slate-50 px-4 py-3 sm:grid-cols-3">
              <dt className="text-sm font-semibold text-slate-600">
                Organization rows
              </dt>
              <dd className="text-sm text-slate-950 sm:col-span-2">
                {health.organizationCount}
              </dd>
            </div>
          </dl>
        ) : (
          <div className="mt-6 rounded-2xl border border-rose-200 bg-rose-50 p-5">
            <h3 className="text-sm font-semibold text-rose-800">
              Database check failed
            </h3>

            <p className="mt-2 text-sm leading-6 text-rose-700">
              {health.errorMessage}
            </p>

            <div className="mt-4 rounded-xl bg-white/70 p-4 text-sm leading-6 text-rose-800">
              Check that <code>DATABASE_URL</code> exists in{" "}
              <code>.env.local</code>, that your Neon database is active, and
              that you have run <code>pnpm db:migrate</code>.
            </div>
          </div>
        )}
      </section>

      <section className="mt-6 grid gap-4 md:grid-cols-2">
        <Link
          href="/settings/database/organizations"
          className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
            Organization sync
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            View database organizations
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            Inspect local organization rows synced from Clerk into the
            application database.
          </p>
        </Link>

        <Link
          href="/settings/auth-status"
          className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-sky-600">
            Auth context
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            View auth status
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            Compare Clerk user, Clerk organization, and synced database
            organization context.
          </p>
        </Link>
      </section>

      <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-slate-950">
          What this confirms
        </h2>

        <ul className="mt-4 space-y-3 text-sm leading-6 text-slate-600">
          <li className="rounded-xl bg-slate-50 p-3">
            The Next.js server can read <code>DATABASE_URL</code>.
          </li>

          <li className="rounded-xl bg-slate-50 p-3">
            The Neon serverless client can connect to Postgres.
          </li>

          <li className="rounded-xl bg-slate-50 p-3">
            Drizzle can query the <code>organizations</code> table.
          </li>

          <li className="rounded-xl bg-slate-50 p-3">
            Clerk organizations can now be synced into local database rows.
          </li>
        </ul>
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/settings/database
```

You should see links to:

```txt
View database organizations
View auth status
```

Click:

```txt
View database organizations
```

You should arrive at:

```txt
/settings/database/organizations
```

---

# 10. Update the Settings Page

## The Target

We are updating:

```txt
app/settings/page.tsx
```

to include a direct organization database diagnostic link.

---

## The Concept

Settings now has several diagnostic tools.

To keep navigation convenient, we expose them as cards.

---

## The Implementation

Open:

```txt
app/settings/page.tsx
```

Replace the entire file with:

```tsx
// app/settings/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";

const settingsCards = [
  {
    eyebrow: "Authentication",
    title: "Auth status",
    description:
      "Verify Clerk proxy protection, signed-in user data, organization context, and server-side auth access.",
    href: "/settings/auth-status",
  },
  {
    eyebrow: "Organization",
    title: "Organization settings",
    description:
      "Manage the active company workspace, members, invitations, and profile details.",
    href: "/settings/organization",
  },
  {
    eyebrow: "Database",
    title: "Database status",
    description:
      "Verify Neon Postgres connectivity, Drizzle migrations, and application database readiness.",
    href: "/settings/database",
  },
  {
    eyebrow: "Sync",
    title: "Database organizations",
    description:
      "Inspect local organization rows synced from Clerk into the organizations table.",
    href: "/settings/database/organizations",
  },
];

export default function SettingsPage() {
  return (
    <AppLayout
      title="Settings"
      description="Settings control company configuration, permissions, tax setup, and automation preferences."
    >
      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {settingsCards.map((card) => (
          <Link
            key={card.href}
            href={card.href}
            className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
              {card.eyebrow}
            </p>

            <h2 className="mt-3 text-lg font-semibold text-slate-950">
              {card.title}
            </h2>

            <p className="mt-2 text-sm leading-6 text-slate-500">
              {card.description}
            </p>
          </Link>
        ))}

        <article className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 shadow-sm md:col-span-2 xl:col-span-4">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-400">
            Coming later
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            Accounting company settings
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            In later phases, we will store GST registration details, financial
            year settings, invoice numbering, default accounts, and reporting
            preferences in our own database.
          </p>
        </article>
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/settings
```

You should see a card named:

```txt
Database organizations
```

Click it.

You should arrive at:

```txt
/settings/database/organizations
```

---

# 11. Run the Full Clerk-to-Database Sync Test

## The Target

We are testing the entire organization sync workflow.

---

## The Concept

A sync feature is complete only when all layers work together:

```txt
Clerk active organization
  -> server auth context
  -> sync service
  -> Drizzle insert/upsert
  -> Neon organizations table
  -> UI diagnostics
```

This is the first real multi-tenant persistence flow in the app.

---

## The Implementation

Start the dev server:

```bash
pnpm dev
```

Sign in.

If you do not have an organization, open:

```txt
http://localhost:3000/onboarding/organization
```

Create:

```txt
Demo Pte. Ltd.
```

Then open:

```txt
http://localhost:3000/dashboard
```

You should see:

```txt
Active database organization synced
```

Now open:

```txt
http://localhost:3000/settings/auth-status
```

You should see:

```txt
Current user profile
Active Clerk organization
Synced database organization
```

Now open:

```txt
http://localhost:3000/settings/database
```

You should see:

```txt
Organization rows: 1
```

or a higher number if you have created multiple organizations.

Now open:

```txt
http://localhost:3000/settings/database/organizations
```

You should see the synced organization rows.

---

## The Verification

The flow is correct if:

- The dashboard shows a database organization ID.
- `/settings/auth-status` shows both Clerk and database organization context.
- `/settings/database` shows organization row count greater than zero.
- `/settings/database/organizations` lists local organization rows.
- The Clerk organization ID matches `clerk_organization_id` in the database.

---

# 12. Verify Directly in Neon SQL

## The Target

We are confirming the organization rows directly in Neon.

---

## The Concept

The app UI is useful, but direct database verification gives us extra confidence.

We want to inspect the actual table rows.

---

## The Implementation

Open your Neon dashboard SQL editor.

Run:

```sql
select
  id,
  clerk_organization_id,
  name,
  slug,
  image_url,
  created_at,
  updated_at
from organizations
order by created_at desc;
```

You should see rows similar to:

```txt
id                                    clerk_organization_id  name
1e0f...                               org_abc123             Demo Pte. Ltd.
```

Now count rows:

```sql
select count(*) as organization_count
from organizations;
```

---

## The Verification

The result should match the count shown at:

```txt
/settings/database
```

---

# 13. Verify with Drizzle Studio

## The Target

We are inspecting synced data with Drizzle Studio.

---

## The Concept

Drizzle Studio gives us a browser-based table viewer.

It is often more comfortable than writing SQL for quick inspection.

---

## The Implementation

Run:

```bash
pnpm db:studio
```

Open the URL Drizzle prints.

Usually it looks like:

```txt
https://local.drizzle.studio
```

Open:

```txt
organizations
```

---

## The Verification

You should see rows for the Clerk organizations you have activated in the app.

The table should include:

```txt
id
clerk_organization_id
name
slug
image_url
created_at
updated_at
```

---

# 14. Run the Project Health Check

## The Target

We are verifying that the app still passes linting and production build.

---

## The Concept

We added:

- A service layer
- Clerk server calls
- Drizzle queries
- Database diagnostics
- Dashboard database sync
- Settings updates

That is a meaningful change set.

Run the full check before committing.

---

## The Implementation

Stop the dev server if it is running:

```txt
Ctrl + C
```

Run:

```bash
pnpm check
```

---

## The Verification

The command should complete successfully.

If it fails, read the first error carefully.

Common issues are listed below.

---

# 15. Commit the Organization Sync Layer

## The Target

We are saving the Clerk-to-database sync work with Git.

---

## The Concept

This is a key production architecture milestone.

GreyMatter Ledger now has a persistent tenant model:

```txt
Clerk Organization
  -> local database organization
  -> future accounting records
```

That deserves a commit.

---

## The Implementation

Run:

```bash
git status
```

You should see files like:

```txt
app/dashboard/page.tsx
app/settings/auth-status/page.tsx
app/settings/database/organizations/page.tsx
app/settings/database/page.tsx
app/settings/page.tsx
components/active-organization-badge.tsx
lib/organization-diagnostics.ts
services/organizations/get-or-create-organization.ts
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Sync Clerk organizations to database"
```

---

## The Verification

Run:

```bash
git status
```

You should see:

```txt
nothing to commit, working tree clean
```

---

# Common Errors and Fixes

## Error: `clerkClient is not a function`

Different Clerk versions have changed server helper APIs.

First update Clerk:

```bash
pnpm add @clerk/nextjs@latest
```

Then restart the dev server:

```bash
Ctrl + C
pnpm dev
```

The service in this tutorial uses the current pattern:

```ts
const client = await clerkClient();
```

---

## Error: `No active organization selected`

This means Clerk does not currently have an active organization.

Create one:

```txt
/onboarding/organization
```

Or select one from the organization switcher in the header.

Then reload:

```txt
/dashboard
```

---

## Error: Database organization row is not created

Check these in order:

1. Are you signed in?
2. Is an organization selected?
3. Does `/settings/database` show `Connected`?
4. Did you run migrations?

Run:

```bash
pnpm db:migrate
```

Then reload:

```txt
/dashboard
```

---

## Error: `relation "organizations" does not exist`

The migration has not been applied to your Neon database.

Run:

```bash
pnpm db:migrate
```

Then check:

```txt
/settings/database
```

---

## Error: Duplicate organization rows

This should not happen if the unique index exists.

Check the generated migration includes:

```sql
CREATE UNIQUE INDEX "organizations_clerk_organization_id_idx"
ON "organizations" USING btree ("clerk_organization_id");
```

If your database was manually altered, inspect indexes in Neon:

```sql
select
  indexname,
  indexdef
from pg_indexes
where tablename = 'organizations';
```

You should see:

```txt
organizations_clerk_organization_id_idx
```

---

## Error: Organization name changed in Clerk but database still shows old name

`getOrCreateCurrentOrganization()` avoids unnecessary Clerk fetches after the row exists.

To force a refresh, use the diagnostic page flow by calling `syncCurrentOrganizationFromClerk()` in future admin tools.

For now, the easiest development workaround is:

1. Open Neon SQL editor.
2. Delete the local row for that Clerk organization.
3. Reload `/dashboard`.

Development-only SQL:

```sql
delete from organizations
where clerk_organization_id = 'org_your_clerk_org_id';
```

Do **not** casually delete production organization rows later once accounting records reference them.

---

## Error: Build fails because `DATABASE_URL` is missing

Now that server-rendered pages query the database, `DATABASE_URL` is required during build.

For local builds, ensure `.env.local` contains:

```bash
DATABASE_URL="postgresql://..."
```

For production, we will configure this in Vercel in Phase 12.

---

# Phase 3 Reference — Organization Sync Pattern

## Clerk Organization ID

Example:

```txt
org_2abc123...
```

This comes from Clerk.

It is stored in our database as:

```txt
organizations.clerk_organization_id
```

---

## Database Organization ID

Example:

```txt
5e6f2c1a-4d2e-43a4-b8f5-9f091a7e8c33
```

This is our internal UUID.

Future accounting tables will reference this value as:

```txt
organization_id
```

---

## Why Not Use Clerk Org ID Everywhere?

We could store Clerk org IDs directly on every accounting row.

But using an internal database UUID gives us:

- Stronger relational modeling
- Cleaner foreign keys
- Freedom to store application-specific organization settings
- Better separation between identity provider and accounting domain

The Clerk org ID remains important, but it is treated as an external identity key.

---

## `getOrCreateCurrentOrganization()`

This function:

1. Reads the active Clerk organization.
2. Checks for an existing local row.
3. Fetches Clerk organization details if needed.
4. Inserts or upserts the local organization.
5. Returns the database organization.

This is the bridge between authentication and application data.

---

## Tenant Isolation Coming Next

Now that we have:

```txt
organizations.id
```

future tables can include:

```txt
organization_id
```

For example:

```txt
accounts.organization_id
journal_entries.organization_id
invoices.organization_id
```

Every query must filter by the active organization.

That is the heart of safe multi-tenant accounting software.

---

# Part 7 Completion Checklist

You are ready for Part 8 if:

- [ ] `services/organizations/get-or-create-organization.ts` exists
- [ ] `getOrCreateCurrentOrganization()` reads Clerk org context
- [ ] Missing database organization rows are inserted
- [ ] Existing organization rows are reused
- [ ] `components/active-organization-badge.tsx` displays synced database organization name
- [ ] `/dashboard` shows the local database organization ID
- [ ] `/settings/auth-status` shows Clerk and database organization context
- [ ] `lib/organization-diagnostics.ts` exists
- [ ] `/settings/database/organizations` lists local organization rows
- [ ] `/settings/database` links to organization diagnostics
- [ ] Neon SQL confirms rows in `organizations`
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
