# Part 5 — Implement Company / Organization Switching

In Part 4, we answered:

> Who is using the app?

In this part, we answer the next question:

> Which company are they working in?

That question is extremely important for accounting software.

A user account is a person.  
An organization is a company workspace.

GreyMatter Ledger must not attach accounting records only to users, because one user may work with many companies.

For example:

```txt
Amanda Tan
  |
  |-- Amanda Consulting Pte. Ltd.
  |-- Orchard Studio Pte. Ltd.
  |-- Client Company A
  |-- Client Company B
```

Each company needs isolated:

- Chart of accounts
- Customers
- Vendors
- Invoices
- Bills
- Journal entries
- Reports
- Bank imports
- Settings

By the end of this part, you will have:

- Clerk Organizations enabled conceptually
- Organization creation page
- Organization switcher in the app header
- Server-side organization context helper
- Dashboard organization awareness
- Organization profile/settings page
- Updated Next.js 16 `proxy.ts`
- A clear foundation for multi-tenant data in later phases

We are **not creating our own database organization table yet**. That comes in **Part 7**, after Neon and Drizzle are installed.

For now, Clerk is the source of truth for organization identity.

---

# 1. Understand Organizations in Accounting Software

## The Target

We are adding company workspaces using Clerk Organizations.

---

## The Concept

A user is a human.

An organization is a company.

In accounting software, the company owns the accounting data.

A useful analogy is a shared office building:

```txt
GreyMatter Ledger app = office building
User account          = person with an access card
Organization          = locked company office
Accounting records    = documents inside that company office
```

A person may have access to multiple offices, but documents from one office must not appear inside another.

That is multi-tenancy.

In software, **multi-tenancy** means one application serves multiple customers or companies while keeping each tenant’s data isolated.

Later, every important database table will include something like:

```txt
organization_id
```

That lets us query:

```txt
Only show invoices for this active organization.
Only show journal entries for this active organization.
Only show customers for this active organization.
```

---

## The Implementation

In this part, we will rely on Clerk’s organization context.

Clerk gives us values like:

```ts
orgId
orgSlug
orgRole
```

Those values tell the server which organization is currently active for the signed-in user.

Later, we will store Clerk’s organization ID in our own database as:

```txt
clerk_org_id
```

That will let us connect Clerk organizations to accounting records.

---

## The Verification

At the end of this part:

- You should be able to create an organization.
- You should be able to switch active organizations.
- The dashboard should show the active organization ID or slug.
- The app header should include an organization switcher.

---

# 2. Enable Organizations in Clerk

## The Target

We are enabling organization support in the Clerk dashboard.

---

## The Concept

Clerk has user accounts by default.

Organizations are an additional feature that lets users create and join shared workspaces.

For GreyMatter Ledger, every company workspace will be represented by a Clerk Organization.

---

## The Implementation

Open your Clerk dashboard:

```txt
https://dashboard.clerk.com
```

Select your GreyMatter Ledger application.

Find the section for:

```txt
Organizations
```

Enable organizations if they are not already enabled.

Recommended development settings:

```txt
Organizations enabled: Yes
Users can create organizations: Yes
Organization invitations: Enabled
Organization membership roles: Enabled
```

If Clerk offers default roles, keep them. We will discuss role-based access control more deeply in Phase 9.

For now, Clerk roles are useful labels such as:

```txt
org:admin
org:member
```

---

## The Verification

In the Clerk dashboard, you should see organization settings available.

You do not need to create an organization manually in the dashboard. We will create one through the app.

---

# 3. Update Environment Documentation

## The Target

We are updating:

```txt
.env.example
```

to document organization-related redirect URLs.

---

## The Concept

When users create or switch organizations, we want them to land back in the app.

Environment variables make those defaults visible.

This step is mostly documentation, but it helps keep the project predictable.

---

## The Implementation

Open:

```txt
.env.example
```

Replace the entire file with:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_replace_with_your_clerk_publishable_key"
CLERK_SECRET_KEY="sk_test_replace_with_your_clerk_secret_key"

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"
```

Now open your real local file:

```txt
.env.local
```

Add these two lines if they are not already present:

```bash
NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"
```

Your `.env.local` should now look similar to:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_your_actual_publishable_key_from_clerk"
CLERK_SECRET_KEY="sk_test_your_actual_secret_key_from_clerk"

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"
```

Do not commit `.env.local`.

---

## The Verification

Run:

```bash
git status --short
```

You should see:

```txt
M .env.example
```

You should **not** see:

```txt
.env.local
```

If `.env.local` appears, make sure `.gitignore` includes:

```gitignore
.env.local
```

---

# 4. Update Server-Side Auth Helpers with Organization Context

## The Target

We are updating:

```txt
lib/auth.ts
```

to include active organization information.

---

## The Concept

In Part 4, our helper answered:

```txt
Who is the signed-in user?
```

Now it will also answer:

```txt
Which organization is currently active?
```

The active organization is the company workspace the user is currently using.

For example:

```txt
User: Amanda Tan
Active organization: Orchard Studio Pte. Ltd.
```

In code, we will represent this as a compact object:

```ts
{
  id: "org_...",
  slug: "orchard-studio",
  role: "org:admin"
}
```

The exact values come from Clerk.

---

## The Implementation

Open:

```txt
lib/auth.ts
```

Replace the entire file with:

```ts
// lib/auth.ts

import { auth, currentUser } from "@clerk/nextjs/server";

export type CurrentUserProfile = {
  id: string;
  displayName: string;
  primaryEmail: string | null;
  imageUrl: string;
};

export type CurrentOrganizationContext = {
  id: string;
  slug: string | null;
  role: string | null;
};

export type CurrentWorkspaceContext = {
  user: CurrentUserProfile | null;
  organization: CurrentOrganizationContext | null;
};

/**
 * Returns a compact profile for the currently signed-in Clerk user.
 *
 * This helper is intended for Server Components, Server Actions, and
 * server-side services. Do not import it into Client Components.
 */
export async function getCurrentUserProfile(): Promise<CurrentUserProfile | null> {
  const user = await currentUser();

  if (!user) {
    return null;
  }

  const primaryEmail =
    user.emailAddresses.find(
      (emailAddress) => emailAddress.id === user.primaryEmailAddressId,
    )?.emailAddress ?? null;

  const displayName =
    user.fullName ??
    user.username ??
    primaryEmail ??
    "Signed-in GreyMatter user";

  return {
    id: user.id,
    displayName,
    primaryEmail,
    imageUrl: user.imageUrl,
  };
}

/**
 * Returns the currently active Clerk organization for this request.
 *
 * Clerk stores organization membership and the currently selected organization.
 * In later phases, we will use organization.id to scope all accounting queries.
 */
export async function getCurrentOrganizationContext(): Promise<CurrentOrganizationContext | null> {
  const { orgId, orgSlug, orgRole } = await auth();

  if (!orgId) {
    return null;
  }

  return {
    id: orgId,
    slug: orgSlug ?? null,
    role: orgRole ?? null,
  };
}

/**
 * Returns both user and organization context.
 *
 * This is useful for pages that need to show:
 * - who is signed in
 * - which company workspace is active
 */
export async function getCurrentWorkspaceContext(): Promise<CurrentWorkspaceContext> {
  const [user, organization] = await Promise.all([
    getCurrentUserProfile(),
    getCurrentOrganizationContext(),
  ]);

  return {
    user,
    organization,
  };
}

/**
 * Requires an active organization and returns it.
 *
 * Later, server actions and accounting services will use this helper before
 * creating organization-scoped records like invoices, bills, and journal
 * entries.
 */
export async function requireActiveOrganization(): Promise<CurrentOrganizationContext> {
  const organization = await getCurrentOrganizationContext();

  if (!organization) {
    throw new Error(
      "No active organization selected. Create or select a company workspace before continuing.",
    );
  }

  return organization;
}
```

The most important helper is:

```ts
getCurrentOrganizationContext()
```

This gives us the active Clerk organization.

Later, a server action might do:

```ts
const organization = await requireActiveOrganization();
```

before creating an invoice.

That protects us from accidentally creating company data without a company.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

If TypeScript complains about Clerk fields, confirm that `@clerk/nextjs` is installed and up to date:

```bash
pnpm add @clerk/nextjs@latest
```

Then rerun:

```bash
pnpm build
```

---

# 5. Create Organization Controls for the Header

## The Target

We are creating:

```txt
components/organization-controls.tsx
```

This will render Clerk’s organization switcher.

---

## The Concept

The organization switcher lets a user choose the active company workspace.

It is like choosing which company file to open in accounting software.

A user might switch between:

```txt
Demo Pte. Ltd.
Client A Pte. Ltd.
Client B Pte. Ltd.
```

When the active organization changes, the app should show data for that organization only.

For now, we only switch Clerk organization context. Later, database queries will use that context.

---

## The Implementation

Create:

```txt
components/organization-controls.tsx
```

Add:

```tsx
// components/organization-controls.tsx

"use client";

import Link from "next/link";
import { OrganizationSwitcher } from "@clerk/nextjs";

export function OrganizationControls() {
  return (
    <div className="flex flex-wrap items-center gap-2">
      <OrganizationSwitcher
        hidePersonal
        afterCreateOrganizationUrl="/dashboard"
        afterSelectOrganizationUrl="/dashboard"
        afterLeaveOrganizationUrl="/onboarding/organization"
        appearance={{
          elements: {
            rootBox: "max-w-full",
            organizationSwitcherTrigger:
              "rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50",
            organizationPreviewTextContainer: "max-w-[10rem]",
          },
        }}
      />

      <Link
        href="/onboarding/organization"
        className="rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm font-semibold text-emerald-700 shadow-sm transition hover:bg-emerald-100"
      >
        New company
      </Link>
    </div>
  );
}
```

Important prop:

```tsx
hidePersonal
```

This encourages users to work inside company organizations rather than personal workspaces.

For accounting software, this is the correct direction because accounting data belongs to companies.

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

The component is not visible yet. We will add it to the header next.

---

# 6. Create an Active Organization Badge

## The Target

We are creating:

```txt
components/active-organization-badge.tsx
```

This will display the active organization context in the app header.

---

## The Concept

The organization switcher is interactive and runs in the browser.

The active organization badge reads server-side Clerk context.

Using both is useful:

```txt
OrganizationSwitcher = user can change company
ActiveOrganizationBadge = server confirms current company
```

Think of the badge as the label on the open company file.

---

## The Implementation

Create:

```txt
components/active-organization-badge.tsx
```

Add:

```tsx
// components/active-organization-badge.tsx

import Link from "next/link";
import { getCurrentOrganizationContext } from "@/lib/auth";

export async function ActiveOrganizationBadge() {
  const organization = await getCurrentOrganizationContext();

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
      Company: {organization.slug ?? organization.id}
    </span>
  );
}
```

This line:

```tsx
organization.slug ?? organization.id
```

means:

> Show the organization slug if Clerk has one. Otherwise, show the organization ID.

A slug is a readable URL-friendly name, such as:

```txt
demo-pte-ltd
```

An ID is the unique Clerk identifier, such as:

```txt
org_2abc123...
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

---

# 7. Update the App Header

## The Target

We are updating:

```txt
components/app-header.tsx
```

to include:

- Active organization badge
- Organization switcher
- New company link
- User button

---

## The Concept

The app header is the top control bar for the signed-in workspace.

After this change, the header will answer:

```txt
Where am I?
Which company am I using?
Who am I signed in as?
```

That is the basic context every accounting screen needs.

---

## The Implementation

Open:

```txt
components/app-header.tsx
```

Replace the entire file with:

```tsx
// components/app-header.tsx

import Link from "next/link";
import { ActiveOrganizationBadge } from "@/components/active-organization-badge";
import { AuthControls } from "@/components/auth-controls";
import { OrganizationControls } from "@/components/organization-controls";

type AppHeaderProps = {
  title: string;
  description: string;
};

export function AppHeader({ title, description }: AppHeaderProps) {
  return (
    <header className="border-b border-slate-200 bg-white px-6 py-5">
      <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
        <div>
          <div className="mb-2 flex flex-wrap items-center gap-2">
            <Link
              href="/"
              className="rounded-full border border-slate-200 px-3 py-1 text-xs font-semibold text-slate-600 transition hover:bg-slate-50 lg:hidden"
            >
              Home
            </Link>

            <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
              Organizations Enabled
            </span>

            <ActiveOrganizationBadge />
          </div>

          <h1 className="text-2xl font-bold tracking-tight text-slate-950">
            {title}
          </h1>

          <p className="mt-1 max-w-3xl text-sm leading-6 text-slate-500">
            {description}
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <OrganizationControls />

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

          <AuthControls />
        </div>
      </div>
    </header>
  );
}
```

The header now includes:

```tsx
<ActiveOrganizationBadge />
```

and:

```tsx
<OrganizationControls />
```

---

## The Verification

Run:

```bash
pnpm dev
```

Sign in and open:

```txt
http://localhost:3000/dashboard
```

You should see:

- `Organizations Enabled`
- An organization badge
- Organization switcher
- `New company` link
- User avatar menu

If you have not created an organization yet, the badge should say:

```txt
No company selected
```

---

# 8. Add an Organization Onboarding Page

## The Target

We are creating:

```txt
app/onboarding/organization/page.tsx
```

This page lets users create a company workspace.

---

## The Concept

A new user may sign up before they have a company organization.

Instead of letting them wander through accounting screens with no active company, we provide a clear setup page:

```txt
Create your first company workspace.
```

This is like opening a new company file before entering transactions.

---

## The Implementation

Create the folder.

macOS/Linux:

```bash
mkdir -p app/onboarding/organization
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/onboarding/organization
```

Create:

```txt
app/onboarding/organization/page.tsx
```

Add:

```tsx
// app/onboarding/organization/page.tsx

import Link from "next/link";
import { CreateOrganization } from "@clerk/nextjs";
import { appInfo } from "@/lib/app-info";

export default function OrganizationOnboardingPage() {
  return (
    <main className="min-h-screen bg-slate-950 px-6 py-10 text-white">
      <div className="mx-auto grid min-h-[calc(100vh-5rem)] max-w-6xl gap-10 lg:grid-cols-[0.9fr_1.1fr] lg:items-center">
        <section>
          <Link href="/" className="inline-flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-emerald-400 text-sm font-bold text-slate-950">
              GM
            </div>

            <div>
              <p className="text-sm font-bold">{appInfo.name}</p>
              <p className="text-xs text-slate-400">{appInfo.tagline}</p>
            </div>
          </Link>

          <div className="mt-10 inline-flex rounded-full border border-emerald-400/30 bg-emerald-400/10 px-4 py-2 text-sm font-medium text-emerald-300">
            Company setup
          </div>

          <h1 className="mt-6 text-4xl font-bold tracking-tight sm:text-5xl">
            Create your company workspace.
          </h1>

          <p className="mt-5 max-w-xl text-base leading-7 text-slate-300">
            GreyMatter Ledger keeps accounting records inside company
            organizations. Create one workspace for each business, client, or
            legal entity you manage.
          </p>

          <div className="mt-8 rounded-2xl border border-white/10 bg-white/5 p-5">
            <h2 className="text-base font-semibold text-white">
              Why this matters
            </h2>

            <ul className="mt-4 space-y-3 text-sm leading-6 text-slate-300">
              <li>• Each company gets its own chart of accounts.</li>
              <li>• Invoices and bills stay isolated by company.</li>
              <li>• Reports are generated for the selected company only.</li>
              <li>• Team members can be invited to the correct workspace.</li>
            </ul>
          </div>
        </section>

        <section className="flex justify-center">
          <CreateOrganization
            routing="hash"
            afterCreateOrganizationUrl="/dashboard"
            appearance={{
              elements: {
                rootBox: "mx-auto",
                card: "shadow-2xl",
              },
            }}
          />
        </section>
      </div>
    </main>
  );
}
```

Important Clerk component:

```tsx
<CreateOrganization />
```

This renders Clerk’s organization creation UI.

---

## The Verification

Open:

```txt
http://localhost:3000/onboarding/organization
```

If signed out, you should be redirected to sign in after we update `proxy.ts` in the next step.

If signed in, you should see a company creation form.

---

# 9. Update Next.js 16 `proxy.ts`

## The Target

We are updating:

```txt
proxy.ts
```

to protect onboarding routes as signed-in routes.

---

## The Concept

The organization onboarding page should not be public.

Only signed-in users should create company workspaces.

So we add:

```txt
/onboarding
```

to protected routes.

---

## The Implementation

Open:

```txt
proxy.ts
```

Replace the entire file with:

```ts
// proxy.ts

import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

/**
 * Internal application routes that require authentication.
 *
 * Next.js 16 uses `proxy.ts` for request interception.
 * Older tutorials may use `middleware.ts`, but this series targets Next.js 16.
 */
const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
  "/accounts(.*)",
  "/customers(.*)",
  "/vendors(.*)",
  "/invoices(.*)",
  "/bills(.*)",
  "/payments(.*)",
  "/reports(.*)",
  "/bank(.*)",
  "/settings(.*)",
  "/onboarding(.*)",
]);

export default clerkMiddleware(async (auth, request) => {
  if (isProtectedRoute(request)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    /**
     * Match all request paths except:
     * - Next.js internals
     * - static assets
     */
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",

    /**
     * Always run for API and tRPC routes.
     */
    "/(api|trpc)(.*)",
  ],
};
```

---

## The Verification

Restart the dev server:

```bash
Ctrl + C
pnpm dev
```

Open a private/incognito window and visit:

```txt
http://localhost:3000/onboarding/organization
```

You should be redirected to sign in.

After signing in, the organization creation page should load.

---

# 10. Create an Organization Settings Page

## The Target

We are creating:

```txt
app/settings/organization/page.tsx
```

This page lets users manage the active organization through Clerk’s organization profile UI.

---

## The Concept

A company workspace needs settings.

Examples:

- Organization name
- Members
- Invitations
- Roles
- Profile settings

Clerk provides a built-in organization profile component for managing those settings.

Later, we will add our own accounting-specific company settings, such as:

- GST registration status
- GST registration number
- Financial year start
- Default currency
- Invoice numbering preferences

For now, Clerk handles identity-side organization settings.

---

## The Implementation

Create the folder.

macOS/Linux:

```bash
mkdir -p app/settings/organization
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/settings/organization
```

Create:

```txt
app/settings/organization/page.tsx
```

Add:

```tsx
// app/settings/organization/page.tsx

import { OrganizationProfile } from "@clerk/nextjs";
import { AppLayout } from "@/components/app-layout";

export default function OrganizationSettingsPage() {
  return (
    <AppLayout
      title="Organization Settings"
      description="Manage the active company workspace, members, invitations, and organization profile details."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <OrganizationProfile
          routing="hash"
          appearance={{
            elements: {
              rootBox: "w-full",
              card: "shadow-none border border-slate-200",
            },
          }}
        />
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

Sign in and make sure you have an active organization.

Open:

```txt
http://localhost:3000/settings/organization
```

You should see Clerk’s organization profile UI.

If you do not have an active organization yet, create one first:

```txt
http://localhost:3000/onboarding/organization
```

---

# 11. Update the Settings Page

## The Target

We are updating:

```txt
app/settings/page.tsx
```

to include links to organization settings and auth status.

---

## The Concept

The Settings page now becomes the control center for identity and workspace configuration.

We will include:

- Auth status
- Organization settings
- Coming-soon accounting company settings

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
      "Verify Clerk proxy protection, signed-in user data, and server-side auth access.",
    href: "/settings/auth-status",
  },
  {
    eyebrow: "Organization",
    title: "Organization settings",
    description:
      "Manage the active company workspace, members, invitations, and profile details.",
    href: "/settings/organization",
  },
];

export default function SettingsPage() {
  return (
    <AppLayout
      title="Settings"
      description="Settings control company configuration, permissions, tax setup, and automation preferences."
    >
      <section className="grid gap-4 md:grid-cols-2">
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

        <article className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 shadow-sm">
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

You should see cards for:

```txt
Auth status
Organization settings
Accounting company settings
```

Click:

```txt
Organization settings
```

You should arrive at:

```txt
/settings/organization
```

---

# 12. Update the Auth Status Diagnostic Page

## The Target

We are updating:

```txt
app/settings/auth-status/page.tsx
```

to show both user and organization context.

---

## The Concept

This diagnostic page should now confirm:

```txt
User context works.
Organization context works.
```

If no organization is active, it should clearly tell us.

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

export default async function AuthStatusPage() {
  const { user, organization } = await getCurrentWorkspaceContext();

  return (
    <AppLayout
      title="Auth Status"
      description="A protected diagnostic page showing what Clerk user and organization data is available to server-side code."
    >
      <section className="grid gap-6 xl:grid-cols-2">
        <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-950">
            Current user profile
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            This data is read on the server using Clerk.
          </p>

          {user ? (
            <dl className="mt-6 divide-y divide-slate-200 overflow-hidden rounded-xl border border-slate-200">
              <div className="grid gap-1 bg-slate-50 px-4 py-3 sm:grid-cols-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Clerk user ID
                </dt>
                <dd className="break-all text-sm text-slate-950 sm:col-span-2">
                  {user.id}
                </dd>
              </div>

              <div className="grid gap-1 bg-white px-4 py-3 sm:grid-cols-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Display name
                </dt>
                <dd className="text-sm text-slate-950 sm:col-span-2">
                  {user.displayName}
                </dd>
              </div>

              <div className="grid gap-1 bg-slate-50 px-4 py-3 sm:grid-cols-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Primary email
                </dt>
                <dd className="text-sm text-slate-950 sm:col-span-2">
                  {user.primaryEmail ?? "No primary email found"}
                </dd>
              </div>
            </dl>
          ) : (
            <div className="mt-6 rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm font-semibold text-rose-700">
              No signed-in user found. If you can see this message on a
              protected route, check the proxy configuration.
            </div>
          )}
        </article>

        <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-950">
            Active organization
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            Later, this organization ID will scope every accounting database
            query.
          </p>

          {organization ? (
            <dl className="mt-6 divide-y divide-slate-200 overflow-hidden rounded-xl border border-slate-200">
              <div className="grid gap-1 bg-slate-50 px-4 py-3 sm:grid-cols-3">
                <dt className="text-sm font-semibold text-slate-600">
                  Organization ID
                </dt>
                <dd className="break-all text-sm text-slate-950 sm:col-span-2">
                  {organization.id}
                </dd>
              </div>

              <div className="grid gap-1 bg-white px-4 py-3 sm:grid-cols-3">
                <dt className="text-sm font-semibold text-slate-600">Slug</dt>
                <dd className="text-sm text-slate-950 sm:col-span-2">
                  {organization.slug ?? "No slug available"}
                </dd>
              </div>

              <div className="grid gap-1 bg-slate-50 px-4 py-3 sm:grid-cols-3">
                <dt className="text-sm font-semibold text-slate-600">Role</dt>
                <dd className="text-sm text-slate-950 sm:col-span-2">
                  {organization.role ?? "No role available"}
                </dd>
              </div>
            </dl>
          ) : (
            <div className="mt-6 rounded-xl border border-amber-200 bg-amber-50 p-4">
              <p className="text-sm font-semibold text-amber-800">
                No active organization selected.
              </p>

              <p className="mt-2 text-sm leading-6 text-amber-700">
                Create or select a company workspace before entering accounting
                records.
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

If you have not selected an organization, you should see:

```txt
No active organization selected.
```

Create an organization, then return to the page.

You should see:

```txt
Organization ID
Slug
Role
```

---

# 13. Update the Dashboard for Organization Awareness

## The Target

We are updating:

```txt
app/dashboard/page.tsx
```

to show whether the user has an active organization.

---

## The Concept

The dashboard should be company-aware.

If there is no selected organization, we should not pretend the user is ready to work with accounting data.

Instead, we show a clear call to action:

```txt
Create a company workspace.
```

Once an organization is active, we show the normal dashboard preview.

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
  const { user, organization } = await getCurrentWorkspaceContext();

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

        {organization ? (
          <div className="mt-5 rounded-2xl border border-emerald-200 bg-emerald-50 p-4">
            <p className="text-sm font-semibold text-emerald-800">
              Active company workspace selected
            </p>

            <p className="mt-2 text-sm leading-6 text-emerald-700">
              Organization{" "}
              <span className="font-semibold">
                {organization.slug ?? organization.id}
              </span>{" "}
              is active. In later phases, every accounting query will be scoped
              to this organization.
            </p>
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
              Every journal entry will belong to one organization.
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

Open:

```txt
http://localhost:3000/dashboard
```

If no organization is active, you should see:

```txt
No company workspace selected
```

Create or select an organization.

Then return to:

```txt
http://localhost:3000/dashboard
```

You should see:

```txt
Active company workspace selected
```

---

# 14. Update Navigation with Organization Onboarding

## The Target

We are updating:

```txt
lib/navigation.ts
```

to include a company setup link.

---

## The Concept

The sidebar should help users find organization setup.

For now, we will place it under `Operations`.

Later, once settings become richer, we may reorganize navigation.

---

## The Implementation

Open:

```txt
lib/navigation.ts
```

Replace the entire file with:

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
        title: "Company Setup",
        href: "/onboarding/organization",
        description: "Create or select a company organization workspace.",
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

---

## The Verification

Open:

```txt
http://localhost:3000/dashboard
```

On a large screen, the sidebar should include:

```txt
Company Setup
```

Click it.

You should arrive at:

```txt
/onboarding/organization
```

---

# 15. Full Organization Flow Test

## The Target

We are testing the full company workspace flow.

---

## The Concept

We need to prove the user journey works:

```txt
Sign in
  -> create organization
  -> dashboard sees active organization
  -> switch organization
  -> settings can manage organization
  -> server can read org context
```

This is important because multi-tenancy depends on active organization context.

---

## The Implementation

Start the dev server:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000/dashboard
```

If you do not have an organization yet, click:

```txt
Create company workspace
```

or open:

```txt
http://localhost:3000/onboarding/organization
```

Create an organization named something like:

```txt
Demo Pte. Ltd.
```

After creating it, you should land at:

```txt
/dashboard
```

Now open:

```txt
http://localhost:3000/settings/auth-status
```

Confirm that the page shows:

```txt
Organization ID
Slug
Role
```

Now create another organization from:

```txt
/onboarding/organization
```

For example:

```txt
Client Test Pte. Ltd.
```

Use the organization switcher in the header to switch between organizations.

After switching, return to:

```txt
/settings/auth-status
```

The active organization details should change.

---

## The Verification

The flow is correct if:

- Signed-out users cannot open `/onboarding/organization`.
- Signed-in users can create organizations.
- The app header shows an organization switcher.
- The dashboard detects whether an organization is active.
- `/settings/auth-status` shows active organization context.
- Switching organizations changes the active organization context.

---

# 16. Run the Project Health Check

## The Target

We are verifying the project still passes linting and production build.

---

## The Concept

We added:

- Clerk organization components
- Server-side organization helpers
- New pages
- Header changes
- Proxy changes

That is enough to justify a full health check.

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

If your `check` script is missing, add this to `package.json`:

```json
"check": "pnpm lint && pnpm build"
```

Then rerun:

```bash
pnpm check
```

---

## The Verification

The command should complete successfully.

If it fails, read the first error carefully.

Common causes:

- Clerk Organizations not enabled
- `OrganizationSwitcher` prop typo
- `.env.local` missing Clerk keys
- `proxy.ts` not at project root
- Dev server not restarted after env changes

---

# 17. Commit the Organization Layer

## The Target

We are committing the organization switching work.

---

## The Concept

This is a major milestone.

GreyMatter Ledger now understands that accounting work happens inside company workspaces.

That is the foundation for multi-tenant database design in Phase 3.

---

## The Implementation

Run:

```bash
git status
```

Confirm `.env.local` is not listed.

You should see files like:

```txt
.env.example
app/dashboard/page.tsx
app/onboarding/organization/page.tsx
app/settings/auth-status/page.tsx
app/settings/organization/page.tsx
app/settings/page.tsx
components/active-organization-badge.tsx
components/app-header.tsx
components/organization-controls.tsx
lib/auth.ts
lib/navigation.ts
proxy.ts
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Add Clerk organization switching"
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

## Error: Organization switcher does not show organization options

Make sure organizations are enabled in the Clerk dashboard.

Then create an organization at:

```txt
/onboarding/organization
```

If you only have one organization, the switcher may show only that organization plus management options.

---

## Error: `CreateOrganization` does not render

Check that organizations are enabled in Clerk.

Also confirm this page exists:

```txt
app/onboarding/organization/page.tsx
```

And that you are signed in.

---

## Error: `/onboarding/organization` is public

Check `proxy.ts`.

It must include:

```ts
"/onboarding(.*)",
```

Then restart the dev server:

```bash
Ctrl + C
pnpm dev
```

---

## Error: `auth()` returns no `orgId`

This usually means no organization is active.

Create or select an organization through the header switcher.

Then reload:

```txt
/settings/auth-status
```

---

## Error: Organization settings page fails

Make sure you have an active organization selected.

Open:

```txt
/onboarding/organization
```

Create an organization, then open:

```txt
/settings/organization
```

---

## Error: TypeScript complains about Clerk component props

Update Clerk:

```bash
pnpm add @clerk/nextjs@latest
```

Then run:

```bash
pnpm check
```

If Clerk has changed a prop in your installed version, remove the specific redirect prop causing the error and rely on Clerk’s default routing. The core component usage remains:

```tsx
<OrganizationSwitcher hidePersonal />
<CreateOrganization routing="hash" />
<OrganizationProfile routing="hash" />
```

---

## Error: `.env.local` appears in Git status

Do not commit `.env.local`.

Unstage it if needed:

```bash
git restore --staged .env.local
```

Confirm `.gitignore` includes:

```gitignore
.env.local
```

---

# Phase 2 Reference — Organizations and Multi-Tenancy

## User

A user is a person who signs in.

Example:

```txt
amanda@example.com
```

---

## Organization

An organization is a company workspace.

Example:

```txt
Demo Pte. Ltd.
```

---

## Active Organization

The active organization is the company currently selected by the user.

Server-side code can read it using Clerk:

```ts
const { orgId } = await auth();
```

---

## Organization Switcher

The organization switcher lets users change the active company workspace.

We added it in:

```txt
components/organization-controls.tsx
```

---

## Organization Onboarding

The organization onboarding page lets users create a company workspace.

We added it at:

```txt
/onboarding/organization
```

---

## Organization Profile

The organization profile page lets users manage organization members and settings.

We added it at:

```txt
/settings/organization
```

---

## Tenant Isolation

Tenant isolation means each organization’s data stays separate.

Later, database queries must always include organization scope.

Bad:

```ts
await db.select().from(invoices);
```

Good:

```ts
await db
  .select()
  .from(invoices)
  .where(eq(invoices.organizationId, activeOrganizationId));
```

This prevents Company A from seeing Company B’s records.

---

## Why We Do Not Create Database Tables Yet

We have not installed Neon or Drizzle yet.

So for now:

```txt
Clerk stores users and organizations.
```

In Phase 3:

```txt
Postgres stores our application organization records.
```

Eventually, we will sync Clerk organizations into our database.

---

# Part 5 Completion Checklist

You are ready for Part 6 if:

- [ ] Clerk Organizations are enabled in the Clerk dashboard
- [ ] `.env.example` documents organization redirect variables
- [ ] `lib/auth.ts` includes organization context helpers
- [ ] `components/organization-controls.tsx` exists
- [ ] `components/active-organization-badge.tsx` exists
- [ ] `components/app-header.tsx` shows organization controls
- [ ] `/onboarding/organization` exists
- [ ] `proxy.ts` protects `/onboarding`
- [ ] `/settings/organization` exists
- [ ] `/settings/auth-status` shows active organization context
- [ ] `/dashboard` detects missing or active organization
- [ ] Sidebar includes `Company Setup`
- [ ] Organization switching works in the header
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
