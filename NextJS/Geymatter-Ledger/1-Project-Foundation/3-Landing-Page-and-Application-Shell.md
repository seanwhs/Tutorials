# Part 3 — Build the Landing Page and Professional App Shell

In this part, we will turn the basic starter page into a more professional application foundation.

By the end of this part, you will have:

- A polished public landing page
- Reusable UI helper components
- A professional dashboard shell
- Sidebar navigation
- Header layout
- Dashboard preview cards
- Placeholder routes for future modules
- A consistent visual design foundation

We are still **not adding authentication yet**. Clerk comes in Part 4.

For now, the app shell will be publicly reachable. In the next part, we will protect dashboard routes behind sign-in.

---

# 1. Understand What We Are Building

## The Target

We are building two major interface areas:

```txt
Public marketing area:
  /

Application area:
  /dashboard
  /accounts
  /customers
  /vendors
  /invoices
  /bills
  /payments
  /reports
  /bank
  /settings
```

The public area introduces GreyMatter Ledger.

The application area is where signed-in users will eventually manage accounting data.

---

## The Concept

Most SaaS applications have two “worlds.”

The first world is the **public website**. Anyone can visit it.

Examples:

```txt
Homepage
Pricing page
Feature pages
Sign-in page
```

The second world is the **authenticated app**. Only signed-in users should access it.

Examples:

```txt
Dashboard
Invoices
Reports
Settings
```

A helpful analogy is a bank branch:

```txt
Public lobby       = landing page
Staff-only office  = dashboard app
Security desk      = authentication
```

In this part, we are building the lobby and the office layout.

In Part 4, we will add the security desk.

---

## The Implementation

By the end of this part, our relevant folder structure will look like this:

```txt
greymatter-ledger/
  app/
    accounts/
      page.tsx
    bank/
      page.tsx
    bills/
      page.tsx
    customers/
      page.tsx
    dashboard/
      page.tsx
    invoices/
      page.tsx
    payments/
      page.tsx
    reports/
      page.tsx
    settings/
      page.tsx
    vendors/
      page.tsx
    globals.css
    layout.tsx
    page.tsx
  components/
    app-header.tsx
    app-layout.tsx
    app-sidebar.tsx
    empty-state.tsx
    stat-card.tsx
  lib/
    app-info.ts
    money.ts
    navigation.ts
```

We already created:

```txt
app/page.tsx
app/layout.tsx
app/globals.css
lib/app-info.ts
lib/money.ts
```

Now we will expand the UI.

---

## The Verification

At the end, these URLs should load:

```txt
http://localhost:3000
http://localhost:3000/dashboard
http://localhost:3000/accounts
http://localhost:3000/invoices
http://localhost:3000/reports
```

And the command below should pass:

```bash
pnpm check
```

---

# 2. Add Shared Navigation Configuration

## The Target

We are creating a shared navigation file:

```txt
lib/navigation.ts
```

This file will contain the sidebar links used by the application shell.

---

## The Concept

Navigation links are used in multiple places.

For example, the sidebar needs to know:

- The label
- The URL
- The description
- The section grouping

We could hardcode links directly inside the sidebar component, but that becomes messy as the app grows.

Instead, we create a configuration file.

Think of this like a restaurant menu. The kitchen, waiters, and cashier all refer to the same menu instead of each person inventing their own list of dishes.

---

## The Implementation

Create this file:

```txt
lib/navigation.ts
```

Add the following complete code.

```ts
// lib/navigation.ts

export type AppNavigationItem = {
  title: string;
  href: string;
  description: string;
};

export type AppNavigationSection = {
  title: string;
  items: AppNavigationItem[];
};

export const appNavigation: AppNavigationSection[] = [
  {
    title: "Workspace",
    items: [
      {
        title: "Dashboard",
        href: "/dashboard",
        description: "Overview of business health and recent activity.",
      },
    ],
  },
  {
    title: "Accounting",
    items: [
      {
        title: "Chart of Accounts",
        href: "/accounts",
        description: "Manage the financial categories used by the ledger.",
      },
      {
        title: "Reports",
        href: "/reports",
        description: "Review Profit & Loss, Balance Sheet, GST, and aging.",
      },
    ],
  },
  {
    title: "Sales",
    items: [
      {
        title: "Customers",
        href: "/customers",
        description: "Manage people and businesses that buy from you.",
      },
      {
        title: "Invoices",
        href: "/invoices",
        description: "Create GST-aware invoices and track money owed to you.",
      },
      {
        title: "Payments",
        href: "/payments",
        description: "Record customer and vendor payment activity.",
      },
    ],
  },
  {
    title: "Purchases",
    items: [
      {
        title: "Vendors",
        href: "/vendors",
        description: "Manage people and businesses you buy from.",
      },
      {
        title: "Bills",
        href: "/bills",
        description: "Track supplier bills and accounts payable.",
      },
    ],
  },
  {
    title: "Operations",
    items: [
      {
        title: "Bank",
        href: "/bank",
        description: "Import bank CSV files and reconcile bank activity.",
      },
      {
        title: "Settings",
        href: "/settings",
        description: "Configure company, tax, permissions, and automation.",
      },
    ],
  },
];

export function getNavigationItemByHref(
  href: string,
): AppNavigationItem | undefined {
  for (const section of appNavigation) {
    const matchingItem = section.items.find((item) => item.href === href);

    if (matchingItem) {
      return matchingItem;
    }
  }

  return undefined;
}
```

The helper function:

```ts
getNavigationItemByHref()
```

will let us find metadata for a route later if needed.

---

## The Verification

Run:

```bash
pnpm build
```

The build should pass.

This file is not used yet, so there will be no visual browser change.

If the build succeeds, TypeScript accepts the navigation configuration.

---

# 3. Create a Reusable Stat Card Component

## The Target

We are creating:

```txt
components/stat-card.tsx
```

This component will display dashboard metrics such as:

- Revenue
- Expenses
- Cash balance
- Outstanding invoices

---

## The Concept

A component is a reusable piece of UI.

Instead of writing the same card markup again and again, we create one reusable `StatCard`.

Think of a component like a cookie cutter. Once the shape is designed, we can stamp out many cards with different labels and values.

---

## The Implementation

First, create the `components` folder if it does not already exist:

```bash
mkdir components
```

On Windows PowerShell, if the folder already exists, this command may show an error. That is harmless. You can also use:

```powershell
New-Item -ItemType Directory -Force components
```

Now create:

```txt
components/stat-card.tsx
```

Add the following complete code.

```tsx
// components/stat-card.tsx

type StatCardTone = "emerald" | "sky" | "amber" | "rose" | "slate";

type StatCardProps = {
  title: string;
  value: string;
  description: string;
  tone?: StatCardTone;
};

const toneClasses: Record<StatCardTone, string> = {
  emerald: "border-emerald-200 bg-emerald-50 text-emerald-700",
  sky: "border-sky-200 bg-sky-50 text-sky-700",
  amber: "border-amber-200 bg-amber-50 text-amber-700",
  rose: "border-rose-200 bg-rose-50 text-rose-700",
  slate: "border-slate-200 bg-slate-50 text-slate-700",
};

export function StatCard({
  title,
  value,
  description,
  tone = "slate",
}: StatCardProps) {
  return (
    <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div
        className={`mb-4 inline-flex rounded-full border px-3 py-1 text-xs font-semibold ${toneClasses[tone]}`}
      >
        {title}
      </div>

      <p className="text-3xl font-bold tracking-tight text-slate-950">
        {value}
      </p>

      <p className="mt-2 text-sm leading-6 text-slate-500">{description}</p>
    </article>
  );
}
```

Important detail:

```tsx
type StatCardTone = "emerald" | "sky" | "amber" | "rose" | "slate";
```

This means the `tone` prop can only be one of those five exact strings.

TypeScript will reject invalid values such as:

```tsx
<StatCard tone="purple" />
```

That is useful because it prevents design system typos.

---

## The Verification

Run:

```bash
pnpm build
```

The build should pass.

Again, there is no browser change yet because we have not used the component.

---

# 4. Create an Empty State Component

## The Target

We are creating:

```txt
components/empty-state.tsx
```

This component will be used on pages where data does not exist yet.

---

## The Concept

Early in the app, many pages will not have real data.

For example:

- No customers yet
- No invoices yet
- No vendors yet
- No bank imports yet

A good empty state explains what belongs on the page and what the user will eventually do there.

Think of an empty state like a helpful sign in an empty room:

> “Customer records will appear here after you add your first customer.”

---

## The Implementation

Create this file:

```txt
components/empty-state.tsx
```

Add this complete code.

```tsx
// components/empty-state.tsx

type EmptyStateProps = {
  title: string;
  description: string;
  actionLabel?: string;
};

export function EmptyState({
  title,
  description,
  actionLabel,
}: EmptyStateProps) {
  return (
    <section className="rounded-2xl border border-dashed border-slate-300 bg-white p-10 text-center shadow-sm">
      <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-100 text-xl">
        ◌
      </div>

      <h2 className="mt-4 text-lg font-semibold text-slate-950">{title}</h2>

      <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
        {description}
      </p>

      {actionLabel ? (
        <button
          type="button"
          className="mt-6 rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
        >
          {actionLabel}
        </button>
      ) : null}
    </section>
  );
}
```

This section:

```tsx
{actionLabel ? (...) : null}
```

means:

> Only show the button if an action label was provided.

That lets us use the component with or without a button.

---

## The Verification

Run:

```bash
pnpm build
```

The build should pass.

---

# 5. Build the Application Sidebar

## The Target

We are creating:

```txt
components/app-sidebar.tsx
```

This sidebar will display the app navigation links.

---

## The Concept

The sidebar is the application’s table of contents.

In an accounting app, users need to move between modules quickly:

- Dashboard
- Accounts
- Invoices
- Bills
- Reports
- Bank
- Settings

A sidebar gives these modules a stable home.

We will use the navigation configuration from `lib/navigation.ts` so the links stay centralized.

---

## The Implementation

Create this file:

```txt
components/app-sidebar.tsx
```

Add the following complete code.

```tsx
// components/app-sidebar.tsx

import Link from "next/link";
import { appInfo } from "@/lib/app-info";
import { appNavigation } from "@/lib/navigation";

export function AppSidebar() {
  return (
    <aside className="hidden min-h-screen w-72 shrink-0 border-r border-slate-200 bg-white px-5 py-6 lg:block">
      <Link href="/" className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-slate-950 text-sm font-bold text-white">
          GM
        </div>

        <div>
          <p className="text-sm font-bold text-slate-950">{appInfo.name}</p>
          <p className="text-xs text-slate-500">Accounting workspace</p>
        </div>
      </Link>

      <nav className="mt-8 space-y-8">
        {appNavigation.map((section) => (
          <section key={section.title}>
            <h2 className="px-3 text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
              {section.title}
            </h2>

            <div className="mt-3 space-y-1">
              {section.items.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="block rounded-xl px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-100 hover:text-slate-950"
                >
                  {item.title}
                </Link>
              ))}
            </div>
          </section>
        ))}
      </nav>
    </aside>
  );
}
```

The sidebar is hidden on small screens:

```tsx
hidden ... lg:block
```

That means:

- Hidden by default on mobile
- Visible on large screens and above

Later, we can add a mobile menu. For now, a responsive header will still provide useful navigation context.

---

## The Verification

Run:

```bash
pnpm build
```

The build should pass.

No visual browser change yet because the sidebar is not mounted in a page.

---

# 6. Build the Application Header

## The Target

We are creating:

```txt
components/app-header.tsx
```

This header will appear at the top of app pages.

---

## The Concept

The header tells the user where they are and gives quick access to important context.

Later, this area will contain:

- Organization switcher
- User button
- Search
- Notifications
- Quick-create actions

For now, it will show:

- Current environment label
- Placeholder company name
- Reminder that authentication is coming next

Think of the header as the dashboard’s control strip.

---

## The Implementation

Create this file:

```txt
components/app-header.tsx
```

Add the following complete code.

```tsx
// components/app-header.tsx

import Link from "next/link";

type AppHeaderProps = {
  title: string;
  description: string;
};

export function AppHeader({ title, description }: AppHeaderProps) {
  return (
    <header className="border-b border-slate-200 bg-white px-6 py-5">
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <div className="mb-2 flex flex-wrap items-center gap-2">
            <Link
              href="/"
              className="rounded-full border border-slate-200 px-3 py-1 text-xs font-semibold text-slate-600 transition hover:bg-slate-50 lg:hidden"
            >
              Home
            </Link>

            <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
              Development Preview
            </span>

            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
              Company: Demo Pte. Ltd.
            </span>
          </div>

          <h1 className="text-2xl font-bold tracking-tight text-slate-950">
            {title}
          </h1>

          <p className="mt-1 max-w-3xl text-sm leading-6 text-slate-500">
            {description}
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          <Link
            href="/invoices"
            className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
          >
            New invoice
          </Link>

          <Link
            href="/reports"
            className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
          >
            View reports
          </Link>
        </div>
      </div>
    </header>
  );
}
```

The company name is currently hardcoded:

```txt
Demo Pte. Ltd.
```

That is intentional for now.

In later parts, we will replace it with the active Clerk organization.

---

## The Verification

Run:

```bash
pnpm build
```

The build should pass.

---

# 7. Build the Application Layout Component

## The Target

We are creating:

```txt
components/app-layout.tsx
```

This component combines the sidebar and header into a reusable app shell.

---

## The Concept

A layout component prevents repeated page structure.

Without it, every dashboard page would need to manually include:

```tsx
<AppSidebar />
<AppHeader />
```

That repetition creates maintenance problems.

Instead, we create one wrapper:

```tsx
<AppLayout title="Dashboard" description="...">
  Page content here
</AppLayout>
```

Think of `AppLayout` like a picture frame. Every page can have different artwork inside, but the frame stays consistent.

---

## The Implementation

Create this file:

```txt
components/app-layout.tsx
```

Add the following complete code.

```tsx
// components/app-layout.tsx

import { AppHeader } from "@/components/app-header";
import { AppSidebar } from "@/components/app-sidebar";

type AppLayoutProps = {
  title: string;
  description: string;
  children: React.ReactNode;
};

export function AppLayout({ title, description, children }: AppLayoutProps) {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-950">
      <div className="flex min-h-screen">
        <AppSidebar />

        <div className="flex min-w-0 flex-1 flex-col">
          <AppHeader title={title} description={description} />

          <main className="flex-1 px-6 py-6">{children}</main>
        </div>
      </div>
    </div>
  );
}
```

Important line:

```tsx
children: React.ReactNode;
```

This means the layout can wrap any valid React content.

Important structure:

```tsx
<AppSidebar />
<div className="flex min-w-0 flex-1 flex-col">
```

The sidebar takes a fixed width on large screens. The main area takes the remaining space.

---

## The Verification

Run:

```bash
pnpm build
```

The build should pass.

Now we are ready to actually create app pages that use the layout.

---

# 8. Build the Dashboard Page

## The Target

We are creating:

```txt
app/dashboard/page.tsx
```

This page will show a preview of the final app dashboard.

---

## The Concept

A dashboard is a quick summary of business health.

For accounting software, common dashboard metrics include:

- Cash balance
- Revenue
- Outstanding invoices
- Upcoming bills
- GST position

At this stage, we do not have a database yet, so the data will be realistic placeholder data.

That is okay. We are building the interface foundation first.

Later, these placeholder values will come from journal entries.

---

## The Implementation

Create the route folder:

```bash
mkdir app/dashboard
```

On Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/dashboard
```

Create this file:

```txt
app/dashboard/page.tsx
```

Add the following complete code.

```tsx
// app/dashboard/page.tsx

import { AppLayout } from "@/components/app-layout";
import { StatCard } from "@/components/stat-card";
import { formatMoney } from "@/lib/money";

export default function DashboardPage() {
  return (
    <AppLayout
      title="Dashboard"
      description="A high-level preview of business health. Later, these numbers will be calculated from posted journal entries."
    >
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
                <tr>
                  <td className="px-4 py-3 text-slate-500">2026-01-05</td>
                  <td className="px-4 py-3 font-medium text-slate-900">
                    Invoice INV-0007 issued to Merlion Trading
                  </td>
                  <td className="px-4 py-3">
                    <span className="rounded-full bg-amber-50 px-2 py-1 text-xs font-semibold text-amber-700">
                      Awaiting payment
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right font-semibold text-slate-900">
                    {formatMoney(218000)}
                  </td>
                </tr>

                <tr>
                  <td className="px-4 py-3 text-slate-500">2026-01-04</td>
                  <td className="px-4 py-3 font-medium text-slate-900">
                    Payment received from Orchard Studio
                  </td>
                  <td className="px-4 py-3">
                    <span className="rounded-full bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700">
                      Posted
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right font-semibold text-slate-900">
                    {formatMoney(109000)}
                  </td>
                </tr>

                <tr>
                  <td className="px-4 py-3 text-slate-500">2026-01-03</td>
                  <td className="px-4 py-3 font-medium text-slate-900">
                    Vendor bill recorded for Cloud Hosting SG
                  </td>
                  <td className="px-4 py-3">
                    <span className="rounded-full bg-sky-50 px-2 py-1 text-xs font-semibold text-sky-700">
                      In review
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right font-semibold text-slate-900">
                    {formatMoney(54500)}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </article>

        <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-950">
            Accounting guardrails
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            GreyMatter Ledger will protect financial data with strict rules.
          </p>

          <ul className="mt-5 space-y-3 text-sm text-slate-700">
            <li className="rounded-xl bg-slate-50 p-3">
              Every journal entry must balance.
            </li>
            <li className="rounded-xl bg-slate-50 p-3">
              Money is stored as integer cents.
            </li>
            <li className="rounded-xl bg-slate-50 p-3">
              Company data is isolated by organization.
            </li>
            <li className="rounded-xl bg-slate-50 p-3">
              Posted accounting history is corrected through reversals.
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

You should see:

- Sidebar on large screens
- Header
- Four stat cards
- Recent accounting activity table
- Accounting guardrails card

Now run:

```bash
pnpm build
```

The build should succeed.

---

# 9. Build Placeholder Pages for Core Modules

## The Target

We are creating placeholder pages for the major modules we will implement later.

These pages are:

```txt
app/accounts/page.tsx
app/customers/page.tsx
app/vendors/page.tsx
app/invoices/page.tsx
app/bills/page.tsx
app/payments/page.tsx
app/reports/page.tsx
app/bank/page.tsx
app/settings/page.tsx
```

---

## The Concept

A placeholder page is not useless. It is a promise.

It establishes:

- The route exists
- The app shell works across pages
- Navigation has somewhere to go
- The future module has a defined home

Think of it like putting labeled folders in a filing cabinet before documents arrive.

---

## The Implementation

Create all route folders.

macOS/Linux:

```bash
mkdir -p app/accounts app/customers app/vendors app/invoices app/bills app/payments app/reports app/bank app/settings
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/accounts
New-Item -ItemType Directory -Force app/customers
New-Item -ItemType Directory -Force app/vendors
New-Item -ItemType Directory -Force app/invoices
New-Item -ItemType Directory -Force app/bills
New-Item -ItemType Directory -Force app/payments
New-Item -ItemType Directory -Force app/reports
New-Item -ItemType Directory -Force app/bank
New-Item -ItemType Directory -Force app/settings
```

Now create each page exactly as shown below.

---

## `app/accounts/page.tsx`

```tsx
// app/accounts/page.tsx

import { AppLayout } from "@/components/app-layout";
import { EmptyState } from "@/components/empty-state";

export default function AccountsPage() {
  return (
    <AppLayout
      title="Chart of Accounts"
      description="The chart of accounts is the master list of categories used to classify every financial transaction."
    >
      <EmptyState
        title="Chart of accounts coming soon"
        description="In Phase 4, we will create account tables, seed a Singapore-friendly chart of accounts, and build the management interface for assets, liabilities, equity, income, and expenses."
        actionLabel="Preview account setup"
      />
    </AppLayout>
  );
}
```

---

## `app/customers/page.tsx`

```tsx
// app/customers/page.tsx

import { AppLayout } from "@/components/app-layout";
import { EmptyState } from "@/components/empty-state";

export default function CustomersPage() {
  return (
    <AppLayout
      title="Customers"
      description="Customers are people or businesses that buy from your company."
    >
      <EmptyState
        title="Customer management coming soon"
        description="In Phase 6, we will build customer records, invoice relationships, receivable balances, and customer detail pages."
        actionLabel="Add customer later"
      />
    </AppLayout>
  );
}
```

---

## `app/vendors/page.tsx`

```tsx
// app/vendors/page.tsx

import { AppLayout } from "@/components/app-layout";
import { EmptyState } from "@/components/empty-state";

export default function VendorsPage() {
  return (
    <AppLayout
      title="Vendors"
      description="Vendors are people or businesses your company buys from."
    >
      <EmptyState
        title="Vendor management coming soon"
        description="In Phase 6, we will build vendor records, bill relationships, payable balances, and vendor detail pages."
        actionLabel="Add vendor later"
      />
    </AppLayout>
  );
}
```

---

## `app/invoices/page.tsx`

```tsx
// app/invoices/page.tsx

import { AppLayout } from "@/components/app-layout";
import { EmptyState } from "@/components/empty-state";

export default function InvoicesPage() {
  return (
    <AppLayout
      title="Invoices"
      description="Invoices record sales to customers and create accounts receivable when posted."
    >
      <EmptyState
        title="GST-aware invoicing coming soon"
        description="In Phase 6, we will create invoice tables, calculate GST, generate invoice numbers, and post balanced journal entries for customer invoices."
        actionLabel="Create invoice later"
      />
    </AppLayout>
  );
}
```

---

## `app/bills/page.tsx`

```tsx
// app/bills/page.tsx

import { AppLayout } from "@/components/app-layout";
import { EmptyState } from "@/components/empty-state";

export default function BillsPage() {
  return (
    <AppLayout
      title="Bills"
      description="Bills record purchases from vendors and create accounts payable when posted."
    >
      <EmptyState
        title="Vendor bill workflows coming soon"
        description="In Phase 6, we will create bill tables, GST input tax logic, payable tracking, and bill detail pages."
        actionLabel="Record bill later"
      />
    </AppLayout>
  );
}
```

---

## `app/payments/page.tsx`

```tsx
// app/payments/page.tsx

import { AppLayout } from "@/components/app-layout";
import { EmptyState } from "@/components/empty-state";

export default function PaymentsPage() {
  return (
    <AppLayout
      title="Payments"
      description="Payments settle invoices and bills without duplicating the original revenue or expense."
    >
      <EmptyState
        title="Payment recording coming soon"
        description="In Phase 7, we will record customer payments and vendor payments through balanced journal entries."
        actionLabel="Record payment later"
      />
    </AppLayout>
  );
}
```

---

## `app/reports/page.tsx`

```tsx
// app/reports/page.tsx

import { AppLayout } from "@/components/app-layout";
import { StatCard } from "@/components/stat-card";
import { formatMoney } from "@/lib/money";

export default function ReportsPage() {
  return (
    <AppLayout
      title="Reports"
      description="Financial reports summarize journal entries into useful business views."
    >
      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          title="Profit & Loss"
          value={formatMoney(642300)}
          description="Preview net profit for the current period."
          tone="emerald"
        />

        <StatCard
          title="Assets"
          value={formatMoney(5892000)}
          description="Preview total assets for the business."
          tone="sky"
        />

        <StatCard
          title="GST Payable"
          value={formatMoney(127800)}
          description="Preview GST amount owed to IRAS."
          tone="amber"
        />

        <StatCard
          title="Overdue AR"
          value={formatMoney(219900)}
          description="Preview overdue customer receivables."
          tone="rose"
        />
      </section>

      <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-slate-950">
          Report modules coming soon
        </h2>

        <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
          In Phase 8, we will build Profit & Loss, Balance Sheet, Accounts
          Receivable aging, Accounts Payable aging, and GST F5-style reports.
          These reports will be generated from journal lines rather than copied
          from invoices or bills.
        </p>

        <div className="mt-6 grid gap-3 md:grid-cols-2">
          <div className="rounded-xl bg-slate-50 p-4 text-sm font-medium text-slate-700">
            Profit & Loss report
          </div>

          <div className="rounded-xl bg-slate-50 p-4 text-sm font-medium text-slate-700">
            Balance Sheet report
          </div>

          <div className="rounded-xl bg-slate-50 p-4 text-sm font-medium text-slate-700">
            AR/AP aging reports
          </div>

          <div className="rounded-xl bg-slate-50 p-4 text-sm font-medium text-slate-700">
            GST F5-style report
          </div>
        </div>
      </section>
    </AppLayout>
  );
}
```

---

## `app/bank/page.tsx`

```tsx
// app/bank/page.tsx

import { AppLayout } from "@/components/app-layout";
import { EmptyState } from "@/components/empty-state";

export default function BankPage() {
  return (
    <AppLayout
      title="Bank"
      description="Bank workflows help import, categorize, post, and reconcile bank transactions."
    >
      <EmptyState
        title="Bank import and reconciliation coming soon"
        description="In Phase 10, we will upload CSV statements, parse transactions, categorize rows, post accounting entries, and reconcile against the ledger."
        actionLabel="Import statement later"
      />
    </AppLayout>
  );
}
```

---

## `app/settings/page.tsx`

```tsx
// app/settings/page.tsx

import { AppLayout } from "@/components/app-layout";
import { EmptyState } from "@/components/empty-state";

export default function SettingsPage() {
  return (
    <AppLayout
      title="Settings"
      description="Settings control company configuration, permissions, tax setup, and automation preferences."
    >
      <EmptyState
        title="Company settings coming soon"
        description="In later phases, we will configure organization syncing, role-based permissions, audit logs, GST settings, and automation preferences."
        actionLabel="Configure later"
      />
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

Open each URL:

```txt
http://localhost:3000/accounts
http://localhost:3000/customers
http://localhost:3000/vendors
http://localhost:3000/invoices
http://localhost:3000/bills
http://localhost:3000/payments
http://localhost:3000/reports
http://localhost:3000/bank
http://localhost:3000/settings
```

Every route should load without a 404 error.

Now run:

```bash
pnpm build
```

The production build should succeed.

---

# 10. Upgrade the Public Landing Page

## The Target

We are replacing the simple homepage with a polished landing page at:

```txt
app/page.tsx
```

---

## The Concept

The landing page is the public face of the product.

It should clearly explain:

- What the product is
- Who it helps
- What makes it valuable
- How users enter the app

Even though this is a tutorial project, building a polished landing page helps us establish a real SaaS structure.

Think of the landing page as the shopfront. The accounting app is the back office.

---

## The Implementation

Open:

```txt
app/page.tsx
```

Replace the entire file with the following complete code.

```tsx
// app/page.tsx

import Link from "next/link";
import { appInfo } from "@/lib/app-info";
import { formatMoney } from "@/lib/money";

const features = [
  {
    title: "Double-entry accounting engine",
    description:
      "Every invoice, bill, payment, adjustment, and bank transaction will be represented by balanced journal entries.",
  },
  {
    title: "Singapore-ready GST workflows",
    description:
      "Build GST-aware invoices, GST input tax handling, and GST F5-style reporting designed around local business needs.",
  },
  {
    title: "Multi-company workspaces",
    description:
      "Use Clerk Organizations to support multiple companies while keeping each organization's data isolated.",
  },
  {
    title: "Operational automation",
    description:
      "Use Inngest to power overdue reminders, recurring invoices, and scheduled accounting workflows.",
  },
];

const previewJournalLines = [
  {
    account: "Accounts Receivable",
    debit: formatMoney(10900),
    credit: "—",
  },
  {
    account: "Sales Revenue",
    debit: "—",
    credit: formatMoney(10000),
  },
  {
    account: "GST Payable",
    debit: "—",
    credit: formatMoney(900),
  },
];

export default function HomePage() {
  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <header className="border-b border-white/10">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-5">
          <Link href="/" className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-emerald-400 text-sm font-bold text-slate-950">
              GM
            </div>

            <div>
              <p className="text-sm font-bold">{appInfo.name}</p>
              <p className="text-xs text-slate-400">{appInfo.tagline}</p>
            </div>
          </Link>

          <nav className="hidden items-center gap-6 text-sm font-medium text-slate-300 md:flex">
            <a href="#features" className="transition hover:text-white">
              Features
            </a>
            <a href="#accounting" className="transition hover:text-white">
              Accounting core
            </a>
            <a href="#roadmap" className="transition hover:text-white">
              Roadmap
            </a>
          </nav>

          <Link
            href="/dashboard"
            className="rounded-xl bg-white px-4 py-2 text-sm font-semibold text-slate-950 shadow-sm transition hover:bg-slate-200"
          >
            Open app preview
          </Link>
        </div>
      </header>

      <section className="mx-auto grid max-w-7xl gap-12 px-6 py-20 lg:grid-cols-[1.1fr_0.9fr] lg:items-center lg:py-28">
        <div>
          <div className="mb-6 inline-flex rounded-full border border-emerald-400/30 bg-emerald-400/10 px-4 py-2 text-sm font-medium text-emerald-300">
            Singapore-ready accounting SaaS tutorial
          </div>

          <h1 className="max-w-4xl text-5xl font-bold tracking-tight sm:text-6xl lg:text-7xl">
            Build accounting software that respects the ledger.
          </h1>

          <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-300">
            GreyMatter Ledger is a full-stack tutorial project for building a
            professional double-entry accounting app with Next.js, TypeScript,
            Clerk, Drizzle ORM, Neon Postgres, Inngest, and Vercel.
          </p>

          <div className="mt-10 flex flex-col gap-3 sm:flex-row">
            <Link
              href="/dashboard"
              className="rounded-xl bg-emerald-400 px-5 py-3 text-center text-sm font-bold text-slate-950 shadow-sm transition hover:bg-emerald-300"
            >
              Explore app shell
            </Link>

            <a
              href="#features"
              className="rounded-xl border border-white/15 px-5 py-3 text-center text-sm font-bold text-white transition hover:bg-white/10"
            >
              View features
            </a>
          </div>

          <dl className="mt-12 grid gap-6 sm:grid-cols-3">
            <div>
              <dt className="text-3xl font-bold text-white">45</dt>
              <dd className="mt-1 text-sm text-slate-400">
                guided tutorial parts
              </dd>
            </div>

            <div>
              <dt className="text-3xl font-bold text-white">14</dt>
              <dd className="mt-1 text-sm text-slate-400">
                engineering phases
              </dd>
            </div>

            <div>
              <dt className="text-3xl font-bold text-white">100%</dt>
              <dd className="mt-1 text-sm text-slate-400">
                ledger-first design
              </dd>
            </div>
          </dl>
        </div>

        <div
          id="accounting"
          className="rounded-3xl border border-white/10 bg-white/5 p-5 shadow-2xl shadow-emerald-950/30"
        >
          <div className="rounded-2xl border border-white/10 bg-slate-900 p-6">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-sm font-semibold text-emerald-300">
                  Journal preview
                </p>
                <h2 className="mt-2 text-xl font-bold text-white">
                  GST invoice for {formatMoney(10900)}
                </h2>
                <p className="mt-2 text-sm leading-6 text-slate-400">
                  A customer invoice creates receivable, revenue, and GST
                  payable lines. The entry balances exactly.
                </p>
              </div>

              <span className="rounded-full bg-emerald-400/10 px-3 py-1 text-xs font-semibold text-emerald-300">
                Balanced
              </span>
            </div>

            <div className="mt-6 overflow-hidden rounded-xl border border-white/10">
              <table className="w-full border-collapse text-left text-sm">
                <thead className="bg-white/5 text-xs uppercase tracking-wide text-slate-400">
                  <tr>
                    <th className="px-4 py-3 font-semibold">Account</th>
                    <th className="px-4 py-3 text-right font-semibold">
                      Debit
                    </th>
                    <th className="px-4 py-3 text-right font-semibold">
                      Credit
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-white/10">
                  {previewJournalLines.map((line) => (
                    <tr key={line.account}>
                      <td className="px-4 py-3 font-medium text-white">
                        {line.account}
                      </td>
                      <td className="px-4 py-3 text-right text-slate-300">
                        {line.debit}
                      </td>
                      <td className="px-4 py-3 text-right text-slate-300">
                        {line.credit}
                      </td>
                    </tr>
                  ))}
                </tbody>

                <tfoot className="bg-white/5">
                  <tr>
                    <td className="px-4 py-3 font-bold text-white">Total</td>
                    <td className="px-4 py-3 text-right font-bold text-white">
                      {formatMoney(10900)}
                    </td>
                    <td className="px-4 py-3 text-right font-bold text-white">
                      {formatMoney(10900)}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>

            <div className="mt-5 rounded-xl bg-emerald-400/10 p-4 text-sm leading-6 text-emerald-100">
              The future journal engine will reject entries where total debits
              do not equal total credits.
            </div>
          </div>
        </div>
      </section>

      <section id="features" className="border-t border-white/10 bg-slate-900/60">
        <div className="mx-auto max-w-7xl px-6 py-20">
          <div className="max-w-3xl">
            <p className="text-sm font-semibold uppercase tracking-[0.3em] text-emerald-300">
              Features
            </p>

            <h2 className="mt-4 text-3xl font-bold tracking-tight text-white sm:text-4xl">
              Built like real accounting software, explained like a beginner
              course.
            </h2>

            <p className="mt-4 text-base leading-7 text-slate-300">
              We will keep explanations approachable while implementing
              production-minded patterns: validation, type safety, tenant
              isolation, immutable accounting history, and background jobs.
            </p>
          </div>

          <div className="mt-10 grid gap-5 md:grid-cols-2">
            {features.map((feature) => (
              <article
                key={feature.title}
                className="rounded-2xl border border-white/10 bg-white/[0.03] p-6"
              >
                <h3 className="text-lg font-bold text-white">
                  {feature.title}
                </h3>

                <p className="mt-3 text-sm leading-6 text-slate-400">
                  {feature.description}
                </p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section id="roadmap" className="bg-slate-950">
        <div className="mx-auto max-w-7xl px-6 py-20">
          <div className="grid gap-10 lg:grid-cols-[0.8fr_1.2fr]">
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.3em] text-emerald-300">
                Roadmap
              </p>

              <h2 className="mt-4 text-3xl font-bold tracking-tight text-white">
                From empty folder to deployed accounting app.
              </h2>

              <p className="mt-4 text-sm leading-6 text-slate-400">
                The series starts with a clean Next.js foundation and gradually
                adds authentication, organizations, database schemas, accounting
                workflows, reports, automation, and deployment.
              </p>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              {[
                "Project foundation",
                "Authentication and organizations",
                "Database and multi-tenancy",
                "Chart of accounts",
                "Journal engine",
                "Invoices and bills",
                "Payments",
                "Reports",
                "Audit logs and permissions",
                "Bank reconciliation",
                "Background jobs",
                "Deployment",
              ].map((item, index) => (
                <div
                  key={item}
                  className="rounded-2xl border border-white/10 bg-white/[0.03] p-4"
                >
                  <p className="text-xs font-semibold text-emerald-300">
                    Phase {index + 1}
                  </p>
                  <p className="mt-1 text-sm font-semibold text-white">
                    {item}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      <footer className="border-t border-white/10 px-6 py-8 text-center text-sm text-slate-500">
        Built for learning professional SaaS and accounting software
        architecture.
      </footer>
    </main>
  );
}
```

Important detail:

```tsx
const previewJournalLines = [...]
```

This is not database data yet. It is a static preview that explains the accounting model visually.

---

## The Verification

Run:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000
```

You should see:

- A polished dark landing page
- Header navigation
- Hero section
- Journal preview table
- Features section
- Roadmap section
- Button linking to `/dashboard`

Click:

```txt
Open app preview
```

You should arrive at:

```txt
http://localhost:3000/dashboard
```

Now run:

```bash
pnpm build
```

The build should succeed.

---

# 11. Improve Root Metadata

## The Target

We are updating:

```txt
app/layout.tsx
```

with richer metadata.

---

## The Concept

Metadata helps browsers, search engines, and social previews understand the page.

Even though this is a tutorial project, adding thoughtful metadata is a professional habit.

Think of metadata as the label on the outside of a package. The package may contain excellent content, but the label helps people understand what is inside before opening it.

---

## The Implementation

Open:

```txt
app/layout.tsx
```

Replace the entire file with this complete code.

```tsx
// app/layout.tsx

import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "GreyMatter Ledger",
    template: "%s | GreyMatter Ledger",
  },
  description:
    "A Singapore-ready double-entry accounting app built with Next.js, TypeScript, Tailwind CSS, Clerk, Drizzle ORM, Neon Postgres, and Inngest.",
  applicationName: "GreyMatter Ledger",
  authors: [
    {
      name: "GreyMatter Ledger Tutorial",
    },
  ],
  keywords: [
    "accounting software",
    "double-entry accounting",
    "Singapore GST",
    "Next.js",
    "TypeScript",
    "Drizzle ORM",
    "Neon Postgres",
    "Clerk",
    "Inngest",
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en-SG">
      <body>{children}</body>
    </html>
  );
}
```

The title configuration:

```ts
title: {
  default: "GreyMatter Ledger",
  template: "%s | GreyMatter Ledger",
}
```

means child pages can later set titles such as:

```txt
Invoices | GreyMatter Ledger
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

Open:

```txt
http://localhost:3000
```

Your browser tab should still show:

```txt
GreyMatter Ledger
```

---

# 12. Add a Local Design Reference Page

## The Target

We are creating a temporary internal page:

```txt
app/design/page.tsx
```

This page previews our basic UI building blocks.

---

## The Concept

A design reference page is like a small style guide.

It helps us see components in one place:

- Stat cards
- Empty states
- Buttons
- Colors
- Layout sections

This is especially useful in tutorials because it confirms reusable components behave correctly outside their first use case.

Later, we may remove this page or protect it behind admin access.

---

## The Implementation

Create the folder:

macOS/Linux:

```bash
mkdir -p app/design
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/design
```

Create this file:

```txt
app/design/page.tsx
```

Add the following complete code.

```tsx
// app/design/page.tsx

import Link from "next/link";
import { EmptyState } from "@/components/empty-state";
import { StatCard } from "@/components/stat-card";
import { formatMoney } from "@/lib/money";

export default function DesignPage() {
  return (
    <main className="min-h-screen bg-slate-50 px-6 py-10 text-slate-950">
      <div className="mx-auto max-w-6xl">
        <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.3em] text-emerald-600">
              Design Reference
            </p>

            <h1 className="mt-3 text-3xl font-bold tracking-tight">
              GreyMatter Ledger UI primitives
            </h1>

            <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-500">
              This temporary page previews reusable components created during
              the project foundation phase.
            </p>
          </div>

          <Link
            href="/"
            className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
          >
            Back home
          </Link>
        </div>

        <section>
          <h2 className="text-lg font-semibold">Stat cards</h2>

          <div className="mt-4 grid gap-4 md:grid-cols-2 xl:grid-cols-5">
            <StatCard
              title="Emerald"
              value={formatMoney(120000)}
              description="Positive cash or success state."
              tone="emerald"
            />

            <StatCard
              title="Sky"
              value={formatMoney(98000)}
              description="Informational metric state."
              tone="sky"
            />

            <StatCard
              title="Amber"
              value={formatMoney(45000)}
              description="Attention or pending state."
              tone="amber"
            />

            <StatCard
              title="Rose"
              value={formatMoney(23000)}
              description="Risk or overdue state."
              tone="rose"
            />

            <StatCard
              title="Slate"
              value={formatMoney(76000)}
              description="Neutral accounting metric."
              tone="slate"
            />
          </div>
        </section>

        <section className="mt-10">
          <h2 className="text-lg font-semibold">Empty state</h2>

          <div className="mt-4">
            <EmptyState
              title="No records yet"
              description="This is how we will explain empty modules before users create customers, invoices, bills, reports, or bank imports."
              actionLabel="Create first record"
            />
          </div>
        </section>
      </div>
    </main>
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
http://localhost:3000/design
```

You should see:

- Design Reference page
- Five stat cards
- Empty state example
- Back home button

Now run:

```bash
pnpm build
```

The build should succeed.

---

# 13. Run a Full Project Health Check

## The Target

We are running the project’s full check command.

---

## The Concept

After adding many files, we want one command that answers:

> Is the project still healthy?

Our check command runs:

```txt
lint -> build
```

This catches:

- Syntax errors
- TypeScript errors
- Some React mistakes
- Production build issues

---

## The Implementation

Run:

```bash
pnpm check
```

If you did not add the `check` script in Part 2, open `package.json` and make sure the scripts section includes:

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "check": "pnpm lint && pnpm build"
  }
}
```

Then run again:

```bash
pnpm check
```

---

## The Verification

The command should complete successfully.

You should see linting finish, then Next.js create an optimized production build.

If the command exits without an error, Part 3 is technically complete.

---

# 14. Commit the App Shell

## The Target

We are saving the current project state with Git.

---

## The Concept

A commit is a checkpoint.

We just added a meaningful slice of functionality:

- Landing page
- App layout
- Navigation
- Placeholder routes
- Reusable UI components

That deserves a commit.

---

## The Implementation

Run:

```bash
git status
```

You should see modified and new files.

Stage everything:

```bash
git add .
```

Commit:

```bash
git commit -m "Build landing page and app shell"
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

If yes, your work is saved.

---

# Common Errors and Fixes

## Error: `Cannot find module '@/components/app-layout'`

Make sure this file exists:

```txt
components/app-layout.tsx
```

Also confirm `tsconfig.json` includes:

```json
"paths": {
  "@/*": ["./*"]
}
```

Then restart the dev server:

```bash
Ctrl + C
pnpm dev
```

---

## Error: Route shows 404

Make sure the route has this exact structure:

```txt
app/dashboard/page.tsx
```

Not:

```txt
app/dashboard.tsx
```

In the App Router, a route folder must contain a `page.tsx` file.

---

## Error: Sidebar is missing

The sidebar is hidden on small screens by design:

```tsx
hidden ... lg:block
```

If your browser window is narrow, expand it.

You should see the sidebar on large desktop widths.

---

## Error: `mkdir components` says folder already exists

That is okay.

It means the folder already exists.

Continue creating the files inside it.

On Windows PowerShell, you can use:

```powershell
New-Item -ItemType Directory -Force components
```

---

## Error: `formatMoney` throws `Money amounts must be stored as integer cents`

Make sure you pass cents as integers.

Correct:

```ts
formatMoney(10900);
```

Incorrect:

```ts
formatMoney(109.00);
```

Remember:

```txt
S$109.00 = 10900 cents
```

---

## Error: Hydration warning or unexpected browser output

Stop and restart the dev server:

```bash
Ctrl + C
pnpm dev
```

If the issue persists, clear the Next.js cache:

```bash
rm -rf .next
pnpm dev
```

Windows PowerShell:

```powershell
Remove-Item -Recurse -Force .next
pnpm dev
```

---

# Phase 1 Reference — UI Architecture

## Public Landing Page

The public landing page lives at:

```txt
app/page.tsx
```

It is intended for unauthenticated visitors.

Later, it will include real sign-in and sign-up buttons from Clerk.

---

## App Shell

The app shell is made of:

```txt
components/app-layout.tsx
components/app-sidebar.tsx
components/app-header.tsx
```

It gives internal application pages a consistent structure.

---

## Reusable Components

So far, reusable UI components include:

```txt
components/stat-card.tsx
components/empty-state.tsx
```

These components help avoid repeated markup.

---

## Route Folders

In Next.js App Router:

```txt
app/invoices/page.tsx
```

creates:

```txt
/invoices
```

And:

```txt
app/reports/page.tsx
```

creates:

```txt
/reports
```

The file must be named:

```txt
page.tsx
```

---

## Static Preview Data

The dashboard and landing page currently use static preview data.

That is intentional.

We are building visual structure first.

Later:

- Dashboard metrics will come from journal entries.
- Reports will come from journal lines.
- Invoice counts will come from invoice tables.
- Bank status will come from reconciliation tables.

---

# Part 3 Completion Checklist

You are ready for Part 4 if:

- [ ] `lib/navigation.ts` exists
- [ ] `components/stat-card.tsx` exists
- [ ] `components/empty-state.tsx` exists
- [ ] `components/app-sidebar.tsx` exists
- [ ] `components/app-header.tsx` exists
- [ ] `components/app-layout.tsx` exists
- [ ] `/` shows the polished landing page
- [ ] `/dashboard` shows the application dashboard
- [ ] `/accounts` loads
- [ ] `/customers` loads
- [ ] `/vendors` loads
- [ ] `/invoices` loads
- [ ] `/bills` loads
- [ ] `/payments` loads
- [ ] `/reports` loads
- [ ] `/bank` loads
- [ ] `/settings` loads
- [ ] `/design` loads
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
