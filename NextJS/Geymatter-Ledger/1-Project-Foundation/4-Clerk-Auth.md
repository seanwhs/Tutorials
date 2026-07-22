# Part 4 — Add Clerk Authentication: Sign up, Sign in, Protected Routes

In this part, we will add authentication to GreyMatter Ledger using **Clerk**.

By the end of this part, you will have:

- Clerk installed
- Clerk environment variables configured
- A global `ClerkProvider`
- Sign-in page
- Sign-up page
- Protected app routes using **Next.js 16 `proxy.ts`**
- Public landing page with auth links
- Clerk user avatar menu in the app header
- Server-side current-user helper
- Dashboard greeting based on the signed-in user
- A protected auth diagnostic page

We are **not adding organizations yet**. That comes in **Part 5**.

For now, we are answering the first security question:

> Who is using the app?

In Part 5, we will answer the second question:

> Which company are they working in?

---

# 1. Understand the Authentication Layer

## The Target

We are adding authentication so users must sign in before accessing internal accounting pages.

These routes remain public:

```txt
/
 /sign-in
 /sign-up
 /design
```

These routes become protected:

```txt
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

---

## The Concept

Authentication means proving identity.

A simple analogy:

```txt
Authentication = showing your ID at the building entrance
Authorization  = checking which rooms your ID lets you enter
```

This part focuses on authentication.

Clerk will handle:

- Sign up
- Sign in
- Sign out
- Session cookies
- User profiles
- Secure server-side auth helpers
- Route protection integration

Instead of writing password security ourselves, we use Clerk because authentication is security-critical and easy to get wrong.

---

## The Implementation

The flow will work like this:

```txt
Visitor opens /
  |
  | clicks Sign in or Sign up
  v
/sign-in or /sign-up
  |
  | Clerk authenticates user
  v
/dashboard
  |
  | Next.js proxy checks session
  v
Protected application pages
```

In **Next.js 16**, request interception uses:

```txt
proxy.ts
```

Older Next.js tutorials often use:

```txt
middleware.ts
```

For this series, because we are targeting **Next.js 16**, we will use:

```txt
proxy.ts
```

---

## The Verification

At the end of this part:

- Visiting `/` should work while signed out.
- Visiting `/sign-in` should show Clerk’s sign-in UI.
- Visiting `/sign-up` should show Clerk’s sign-up UI.
- Visiting `/dashboard` while signed out should redirect to sign-in.
- Visiting `/dashboard` while signed in should show the dashboard.

---

# 2. Create a Clerk Application

## The Target

We are creating a Clerk application and getting the required API keys.

---

## The Concept

A Clerk application is the authentication project connected to GreyMatter Ledger.

Think of it as the security office for our app.

It stores configuration for:

- Sign-in methods
- Sessions
- Redirect URLs
- User accounts
- API keys
- Organizations later

---

## The Implementation

Go to:

```txt
https://clerk.com
```

Create an account or sign in.

Create a new application named:

```txt
GreyMatter Ledger
```

For sign-in methods, enable at least:

```txt
Email
```

Optional providers such as Google or GitHub are fine, but not required.

After creating the application, find your Clerk keys.

They will look similar to:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
```

Do **not** commit real Clerk keys to Git.

---

## The Verification

You are ready if you have:

```txt
Publishable key
Secret key
```

The publishable key usually starts with:

```txt
pk_test_
```

The secret key usually starts with:

```txt
sk_test_
```

---

# 3. Install Clerk

## The Target

We are installing Clerk’s Next.js SDK.

---

## The Concept

A package is reusable code maintained by another team.

The Clerk Next.js package provides:

- `ClerkProvider`
- `SignIn`
- `SignUp`
- `UserButton`
- `currentUser`
- `clerkMiddleware`
- Route protection helpers

It is the bridge between our Next.js app and Clerk.

---

## The Implementation

Run this from the project root:

```bash
pnpm add @clerk/nextjs
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should still succeed.

You can also check `package.json`. It should now include:

```json
"@clerk/nextjs": "..."
```

The exact version number may differ.

---

# 4. Add Clerk Environment Variables

## The Target

We are creating:

```txt
.env.local
```

This file stores local Clerk configuration.

---

## The Concept

Environment variables keep secrets and environment-specific settings outside source code.

Clerk uses two important keys:

```txt
Publishable key  Safe for browser use
Secret key       Server-only and private
```

In Next.js, environment variables beginning with:

```txt
NEXT_PUBLIC_
```

can be exposed to browser code.

That is why Clerk’s publishable key uses:

```txt
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
```

The secret key must **not** use `NEXT_PUBLIC_`.

---

## The Implementation

Create this file in the project root:

```txt
.env.local
```

Add your real Clerk values:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_your_actual_publishable_key_from_clerk"
CLERK_SECRET_KEY="sk_test_your_actual_secret_key_from_clerk"

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"
```

Replace these placeholders:

```txt
pk_test_your_actual_publishable_key_from_clerk
sk_test_your_actual_secret_key_from_clerk
```

with your real Clerk keys.

Now confirm `.env.local` is ignored by Git:

```bash
git status --short
```

You should **not** see:

```txt
.env.local
```

If you do, check `.gitignore`.

It should include:

```gitignore
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
```

---

## The Verification

Run:

```bash
pnpm dev
```

If the dev server starts without a Clerk key error, the environment variables are being loaded.

Stop the server for now:

```txt
Ctrl + C
```

---

# 5. Add an Environment Example File

## The Target

We are creating:

```txt
.env.example
```

This documents required environment variables without exposing real secrets.

---

## The Concept

`.env.local` is private.

`.env.example` is safe documentation.

Future developers can copy it:

```bash
cp .env.example .env.local
```

Then fill in real values.

---

## The Implementation

Create:

```txt
.env.example
```

Add:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_replace_with_your_clerk_publishable_key"
CLERK_SECRET_KEY="sk_test_replace_with_your_clerk_secret_key"

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"
```

---

## The Verification

Run:

```bash
git status --short
```

You should see `.env.example` listed, but not `.env.local`.

Expected:

```txt
?? .env.example
```

Not expected:

```txt
?? .env.local
```

---

# 6. Wrap the App with `ClerkProvider`

## The Target

We are updating:

```txt
app/layout.tsx
```

to provide Clerk context to the whole application.

---

## The Concept

`ClerkProvider` gives Clerk components access to authentication state.

Think of it like installing the building’s security system at the main electrical panel. Once installed at the root, every floor can use it.

---

## The Implementation

Open:

```txt
app/layout.tsx
```

Replace the entire file with:

```tsx
// app/layout.tsx

import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
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
    <ClerkProvider>
      <html lang="en-SG">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

The key addition is:

```tsx
import { ClerkProvider } from "@clerk/nextjs";
```

and:

```tsx
<ClerkProvider>
  ...
</ClerkProvider>
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

If Clerk complains about missing keys, recheck:

```txt
.env.local
```

Then restart the dev server.

---

# 7. Create the Sign-In Page

## The Target

We are creating:

```txt
app/sign-in/[[...sign-in]]/page.tsx
```

This provides:

```txt
/sign-in
```

---

## The Concept

Clerk provides a complete sign-in component.

The folder name:

```txt
[[...sign-in]]
```

is an optional catch-all route.

It lets Clerk handle multi-step sign-in paths such as:

```txt
/sign-in
/sign-in/factor-one
/sign-in/factor-two
```

Authentication flows can have more than one step, so Clerk needs this flexible route.

---

## The Implementation

Create the folder.

macOS/Linux:

```bash
mkdir -p app/sign-in/[[...sign-in]]
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force 'app/sign-in/[[...sign-in]]'
```

Create:

```txt
app/sign-in/[[...sign-in]]/page.tsx
```

Add:

```tsx
// app/sign-in/[[...sign-in]]/page.tsx

import Link from "next/link";
import { SignIn } from "@clerk/nextjs";
import { appInfo } from "@/lib/app-info";

export default function SignInPage() {
  return (
    <main className="min-h-screen bg-slate-950 px-6 py-10 text-white">
      <div className="mx-auto flex min-h-[calc(100vh-5rem)] max-w-6xl flex-col items-center justify-center">
        <div className="mb-8 text-center">
          <Link href="/" className="inline-flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-emerald-400 text-sm font-bold text-slate-950">
              GM
            </div>

            <div className="text-left">
              <p className="text-sm font-bold">{appInfo.name}</p>
              <p className="text-xs text-slate-400">{appInfo.tagline}</p>
            </div>
          </Link>

          <h1 className="mt-8 text-3xl font-bold tracking-tight">
            Sign in to your ledger
          </h1>

          <p className="mt-3 max-w-md text-sm leading-6 text-slate-400">
            Access your accounting workspace, invoices, reports, and ledger
            tools.
          </p>
        </div>

        <SignIn
          routing="path"
          path="/sign-in"
          signUpUrl="/sign-up"
          fallbackRedirectUrl="/dashboard"
          appearance={{
            elements: {
              rootBox: "mx-auto",
              card: "shadow-2xl",
            },
          }}
        />
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
http://localhost:3000/sign-in
```

You should see Clerk’s sign-in form.

---

# 8. Create the Sign-Up Page

## The Target

We are creating:

```txt
app/sign-up/[[...sign-up]]/page.tsx
```

This provides:

```txt
/sign-up
```

---

## The Concept

Sign-up is account creation.

Like sign-in, it may involve multiple steps, such as email verification. The optional catch-all route supports those steps.

---

## The Implementation

Create the folder.

macOS/Linux:

```bash
mkdir -p app/sign-up/[[...sign-up]]
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force 'app/sign-up/[[...sign-up]]'
```

Create:

```txt
app/sign-up/[[...sign-up]]/page.tsx
```

Add:

```tsx
// app/sign-up/[[...sign-up]]/page.tsx

import Link from "next/link";
import { SignUp } from "@clerk/nextjs";
import { appInfo } from "@/lib/app-info";

export default function SignUpPage() {
  return (
    <main className="min-h-screen bg-slate-950 px-6 py-10 text-white">
      <div className="mx-auto flex min-h-[calc(100vh-5rem)] max-w-6xl flex-col items-center justify-center">
        <div className="mb-8 text-center">
          <Link href="/" className="inline-flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-emerald-400 text-sm font-bold text-slate-950">
              GM
            </div>

            <div className="text-left">
              <p className="text-sm font-bold">{appInfo.name}</p>
              <p className="text-xs text-slate-400">{appInfo.tagline}</p>
            </div>
          </Link>

          <h1 className="mt-8 text-3xl font-bold tracking-tight">
            Create your GreyMatter Ledger account
          </h1>

          <p className="mt-3 max-w-md text-sm leading-6 text-slate-400">
            Start building your accounting workspace. Company organizations are
            added in the next part.
          </p>
        </div>

        <SignUp
          routing="path"
          path="/sign-up"
          signInUrl="/sign-in"
          fallbackRedirectUrl="/dashboard"
          appearance={{
            elements: {
              rootBox: "mx-auto",
              card: "shadow-2xl",
            },
          }}
        />
      </div>
    </main>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/sign-up
```

You should see Clerk’s sign-up form.

Create a test user if you want.

After sign-up, Clerk should redirect you to:

```txt
/dashboard
```

We will protect `/dashboard` next.

---

# 9. Add Next.js 16 `proxy.ts` for Protected Routes

## The Target

We are creating:

```txt
proxy.ts
```

This protects internal application routes.

---

## The Concept

In **Next.js 16**, `proxy.ts` runs before a matching request reaches the route.

Think of it as a security guard standing before the application workspace.

When someone requests:

```txt
/dashboard
```

the proxy checks:

```txt
Is this user signed in?
```

If yes, the request continues.

If no, Clerk redirects them to sign in.

Important:

```txt
Next.js 16: proxy.ts
Older Next.js versions: middleware.ts
```

For this tutorial, use:

```txt
proxy.ts
```

---

## The Implementation

Create this file at the project root:

```txt
proxy.ts
```

Add:

```ts
// proxy.ts

import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

/**
 * Internal application routes that require authentication.
 *
 * Public routes such as `/`, `/sign-in`, `/sign-up`, and `/design` are not
 * included here, so visitors can access them without signing in.
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
     *
     * This prevents the proxy from running for files like images, fonts,
     * generated JS chunks, and CSS.
     */
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",

    /**
     * Always run for API and tRPC routes.
     *
     * We do not have API routes yet, but this prepares the app for later route
     * handlers, webhooks, and background integrations.
     */
    "/(api|trpc)(.*)",
  ],
};
```

If you previously created `middleware.ts`, remove it or rename it:

```bash
mv middleware.ts proxy.ts
```

Windows PowerShell:

```powershell
Rename-Item middleware.ts proxy.ts
```

Do not keep both files for this tutorial.

---

## The Verification

Restart the dev server:

```bash
Ctrl + C
pnpm dev
```

Open a private/incognito browser window.

Visit:

```txt
http://localhost:3000/dashboard
```

You should be redirected to sign in.

Now visit:

```txt
http://localhost:3000
```

The landing page should still load.

Visit:

```txt
http://localhost:3000/design
```

The design reference page should still load because it is intentionally public for now.

---

# 10. Create Server-Side Auth Helpers

## The Target

We are creating:

```txt
lib/auth.ts
```

This file will contain reusable server-side authentication helpers.

---

## The Concept

The proxy protects routes, but server-side pages and services often need user details.

Examples:

- User ID
- Email address
- Display name
- Profile image URL

Instead of repeating Clerk code everywhere, we create a helper.

Think of it like asking the front desk:

> Who is currently signed in?

---

## The Implementation

Create:

```txt
lib/auth.ts
```

Add:

```ts
// lib/auth.ts

import { currentUser } from "@clerk/nextjs/server";

export type CurrentUserProfile = {
  id: string;
  displayName: string;
  primaryEmail: string | null;
  imageUrl: string;
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
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should succeed.

We will use this helper in the dashboard next.

---

# 11. Add Auth Controls to the App Header

## The Target

We are creating:

```txt
components/auth-controls.tsx
```

Then updating:

```txt
components/app-header.tsx
```

to show Clerk’s `UserButton`.

---

## The Concept

`UserButton` shows the signed-in user’s avatar and account menu.

Users can:

- View account settings
- Manage profile
- Sign out

Because `UserButton` is interactive, it must live in a **Client Component**.

In Next.js, Client Components start with:

```tsx
"use client";
```

---

## The Implementation

Create:

```txt
components/auth-controls.tsx
```

Add:

```tsx
// components/auth-controls.tsx

"use client";

import { UserButton } from "@clerk/nextjs";

export function AuthControls() {
  return (
    <div className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white px-3 py-2 shadow-sm">
      <span className="hidden text-xs font-semibold text-slate-500 sm:inline">
        Signed in
      </span>

      <UserButton
        afterSignOutUrl="/"
        appearance={{
          elements: {
            avatarBox: "h-8 w-8",
          },
        }}
      />
    </div>
  );
}
```

Now open:

```txt
components/app-header.tsx
```

Replace the entire file with:

```tsx
// components/app-header.tsx

import Link from "next/link";
import { AuthControls } from "@/components/auth-controls";

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
              Auth Enabled
            </span>

            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
              Company setup coming next
            </span>
          </div>

          <h1 className="text-2xl font-bold tracking-tight text-slate-950">
            {title}
          </h1>

          <p className="mt-1 max-w-3xl text-sm leading-6 text-slate-500">
            {description}
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
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

---

## The Verification

Run:

```bash
pnpm dev
```

Sign in, then open:

```txt
http://localhost:3000/dashboard
```

You should see the user avatar button in the header.

Click it.

You should see Clerk’s user menu.

Sign out from that menu.

After signing out, try opening:

```txt
http://localhost:3000/dashboard
```

You should be redirected to sign in again.

---

# 12. Make the Dashboard Aware of the Signed-In User

## The Target

We are updating:

```txt
app/dashboard/page.tsx
```

to greet the current signed-in user.

---

## The Concept

Now that authentication works, server-rendered pages can read user identity.

Later, this same pattern will help us display:

- Active organization
- User role
- Company-specific dashboard data

For now, we show the user’s name and email.

---

## The Implementation

Open:

```txt
app/dashboard/page.tsx
```

Replace the entire file with:

```tsx
// app/dashboard/page.tsx

import { AppLayout } from "@/components/app-layout";
import { StatCard } from "@/components/stat-card";
import { getCurrentUserProfile } from "@/lib/auth";
import { formatMoney } from "@/lib/money";

export default async function DashboardPage() {
  const user = await getCurrentUserProfile();

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

        <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
          Authentication is now active. In the next part, we will add company
          organizations so accounting data belongs to a business workspace, not
          only to an individual user.
        </p>

        {user?.primaryEmail ? (
          <p className="mt-4 inline-flex rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
            Signed in as {user.primaryEmail}
          </p>
        ) : null}
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

Sign in and open:

```txt
http://localhost:3000/dashboard
```

You should see:

```txt
Welcome, Your Name.
```

If Clerk has a primary email, you should also see:

```txt
Signed in as you@example.com
```

---

# 13. Update the Landing Page Auth Buttons

## The Target

We are updating:

```txt
app/page.tsx
```

so the public landing page includes sign-in and sign-up entry points.

---

## The Concept

The landing page should guide users into the authentication flow:

- Existing users sign in.
- New users sign up.
- Signed-in users can open the protected app.

---

## The Implementation

Open:

```txt
app/page.tsx
```

Replace the entire file with:

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

          <div className="flex items-center gap-2">
            <Link
              href="/sign-in"
              className="hidden rounded-xl border border-white/15 px-4 py-2 text-sm font-semibold text-white transition hover:bg-white/10 sm:inline-flex"
            >
              Sign in
            </Link>

            <Link
              href="/sign-up"
              className="rounded-xl bg-white px-4 py-2 text-sm font-semibold text-slate-950 shadow-sm transition hover:bg-slate-200"
            >
              Sign up
            </Link>
          </div>
        </div>
      </header>

      <section className="mx-auto grid max-w-7xl gap-12 px-6 py-20 lg:grid-cols-[1.1fr_0.9fr] lg:items-center lg:py-28">
        <div>
          <div className="mb-6 inline-flex rounded-full border border-emerald-400/30 bg-emerald-400/10 px-4 py-2 text-sm font-medium text-emerald-300">
            Authentication now powered by Clerk
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
              href="/sign-up"
              className="rounded-xl bg-emerald-400 px-5 py-3 text-center text-sm font-bold text-slate-950 shadow-sm transition hover:bg-emerald-300"
            >
              Create account
            </Link>

            <Link
              href="/dashboard"
              className="rounded-xl border border-white/15 px-5 py-3 text-center text-sm font-bold text-white transition hover:bg-white/10"
            >
              Open protected app
            </Link>
          </div>

          <p className="mt-4 text-sm leading-6 text-slate-400">
            The dashboard link is now protected. If you are signed out, Clerk
            will redirect you to sign in.
          </p>

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

---

## The Verification

Open:

```txt
http://localhost:3000
```

You should see:

- `Sign in`
- `Sign up`
- `Create account`
- `Open protected app`

Click `Open protected app` while signed out.

You should be redirected to sign in.

After signing in, you should reach:

```txt
/dashboard
```

---

# 14. Add an Auth Status Diagnostic Page

## The Target

We are creating:

```txt
app/settings/auth-status/page.tsx
```

This protected page verifies server-side Clerk auth.

---

## The Concept

A diagnostic page shows what the server can see.

This is useful while building authentication because it confirms:

- The route is protected
- Clerk can identify the user
- Server Components can read user data

Because this route is under `/settings`, our `proxy.ts` protects it automatically.

---

## The Implementation

Create the folder.

macOS/Linux:

```bash
mkdir -p app/settings/auth-status
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force app/settings/auth-status
```

Create:

```txt
app/settings/auth-status/page.tsx
```

Add:

```tsx
// app/settings/auth-status/page.tsx

import { AppLayout } from "@/components/app-layout";
import { getCurrentUserProfile } from "@/lib/auth";

export default async function AuthStatusPage() {
  const user = await getCurrentUserProfile();

  return (
    <AppLayout
      title="Auth Status"
      description="A protected diagnostic page showing what Clerk user data is available to server-side code."
    >
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-slate-950">
          Current user profile
        </h2>

        <p className="mt-2 text-sm leading-6 text-slate-500">
          This data is read on the server using Clerk. It confirms that route
          protection and server-side authentication are working.
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

            <div className="grid gap-1 bg-white px-4 py-3 sm:grid-cols-3">
              <dt className="text-sm font-semibold text-slate-600">
                Image URL
              </dt>
              <dd className="break-all text-sm text-slate-950 sm:col-span-2">
                {user.imageUrl}
              </dd>
            </div>
          </dl>
        ) : (
          <div className="mt-6 rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm font-semibold text-rose-700">
            No signed-in user found. If you can see this message on a protected
            route, check the proxy configuration.
          </div>
        )}
      </section>
    </AppLayout>
  );
}
```

---

## The Verification

While signed in, open:

```txt
http://localhost:3000/settings/auth-status
```

You should see your Clerk user information.

Sign out and try opening the same URL again.

You should be redirected to sign in.

---

# 15. Update the Settings Page with Auth Status Link

## The Target

We are updating:

```txt
app/settings/page.tsx
```

to link to the auth diagnostic page.

---

## The Concept

Settings pages often contain administrative and diagnostic tools.

For now, this gives us a convenient way to verify authentication from inside the app.

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

export default function SettingsPage() {
  return (
    <AppLayout
      title="Settings"
      description="Settings control company configuration, permissions, tax setup, and automation preferences."
    >
      <section className="grid gap-4 md:grid-cols-2">
        <Link
          href="/settings/auth-status"
          className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
            Authentication
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            Auth status
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            Verify Clerk proxy protection, signed-in user data, and server-side
            auth access.
          </p>
        </Link>

        <article className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 shadow-sm">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-400">
            Coming next
          </p>

          <h2 className="mt-3 text-lg font-semibold text-slate-950">
            Company organizations
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            In Part 5, we will enable Clerk Organizations so each company has
            its own isolated accounting workspace.
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

Click:

```txt
Auth status
```

You should arrive at:

```txt
/settings/auth-status
```

The page should show your signed-in user profile.

---

# 16. Run a Full Auth Flow Test

## The Target

We are testing the entire authentication journey.

---

## The Concept

A feature is not complete just because code compiles.

We need to test the real user path:

```txt
Signed-out visitor
  -> landing page
  -> sign in/sign up
  -> dashboard
  -> user menu
  -> sign out
  -> protected routes blocked again
```

This is like testing a lock by actually opening and closing the door.

---

## The Implementation

Start the dev server:

```bash
pnpm dev
```

Open a private/incognito browser window.

Visit:

```txt
http://localhost:3000
```

Confirm the landing page loads.

Now visit:

```txt
http://localhost:3000/dashboard
```

You should be redirected to:

```txt
/sign-in
```

Sign in or create a test account.

After authentication, confirm you reach:

```txt
/dashboard
```

Open:

```txt
http://localhost:3000/settings/auth-status
```

Confirm your user ID and email appear.

Click the user avatar in the app header and sign out.

Now try:

```txt
http://localhost:3000/reports
```

You should be redirected to sign in again.

---

## The Verification

The flow is correct if:

- Public landing page works while signed out.
- Protected app pages redirect while signed out.
- Sign-in page works.
- Sign-up page works.
- Dashboard loads while signed in.
- User button appears while signed in.
- Sign out returns to `/`.
- Protected pages are blocked again after sign out.

---

# 17. Run the Project Health Check

## The Target

We are confirming linting and production build still pass.

---

## The Concept

Authentication touches root layout, route protection, pages, and components.

That is enough surface area to justify a full project check.

---

## The Implementation

Stop the dev server if needed:

```txt
Ctrl + C
```

Run:

```bash
pnpm check
```

If your `package.json` does not have a `check` script, add this to the `scripts` object:

```json
"check": "pnpm lint && pnpm build"
```

Then run again:

```bash
pnpm check
```

---

## The Verification

The command should complete successfully.

If it fails, read the first error carefully.

Common causes include:

- Missing `.env.local`
- Invalid Clerk keys
- Dev server not restarted after environment changes
- Incorrect catch-all route folder names
- Accidentally using `middleware.ts` instead of `proxy.ts`

---

# 18. Commit the Authentication Layer

## The Target

We are saving the authentication work with Git.

---

## The Concept

This is a major milestone.

The app now has:

- Clerk identity integration
- Sign-in and sign-up routes
- Protected internal pages
- Signed-in user UI
- Server-side auth helper
- Next.js 16 proxy route protection

That deserves a clean commit.

---

## The Implementation

Run:

```bash
git status
```

Confirm `.env.local` is **not** listed.

You should see files such as:

```txt
.env.example
app/layout.tsx
app/page.tsx
app/sign-in/[[...sign-in]]/page.tsx
app/sign-up/[[...sign-up]]/page.tsx
app/dashboard/page.tsx
app/settings/page.tsx
app/settings/auth-status/page.tsx
components/app-header.tsx
components/auth-controls.tsx
lib/auth.ts
proxy.ts
package.json
pnpm-lock.yaml
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Add Clerk authentication and protected routes"
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

## Error: Clerk says publishable key is missing

Check:

```txt
.env.local
```

It must include:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="..."
CLERK_SECRET_KEY="..."
```

Restart the dev server after editing env files:

```bash
Ctrl + C
pnpm dev
```

---

## Error: `/sign-in` shows 404

Check the folder structure.

It must be exactly:

```txt
app/sign-in/[[...sign-in]]/page.tsx
```

Not:

```txt
app/signin/page.tsx
app/sign-in/page.tsx
app/sign-in/[...sign-in]/page.tsx
```

The optional catch-all folder uses double square brackets:

```txt
[[...sign-in]]
```

---

## Error: `/sign-up` shows 404

Check:

```txt
app/sign-up/[[...sign-up]]/page.tsx
```

---

## Error: Protected routes are not redirecting

For Next.js 16, check that this file exists at the project root:

```txt
proxy.ts
```

Do not put it inside `app/`.

Also do not rely on:

```txt
middleware.ts
```

for this tutorial.

Restart the dev server:

```bash
Ctrl + C
pnpm dev
```

---

## Error: User button does not appear

Make sure:

```txt
components/auth-controls.tsx
```

starts with:

```tsx
"use client";
```

Also make sure `components/app-header.tsx` imports:

```tsx
import { AuthControls } from "@/components/auth-controls";
```

---

## Error: `.env.local` appears in Git status

Do not commit `.env.local`.

Make sure `.gitignore` contains:

```gitignore
.env.local
.env
.env.development.local
.env.test.local
.env.production.local
```

If it was staged, unstage it:

```bash
git restore --staged .env.local
```

If it was committed, rotate your Clerk keys in the Clerk dashboard.

---

## Error: `currentUser()` returns null on dashboard

Make sure `/dashboard` is listed in `proxy.ts`:

```ts
const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
]);
```

Also confirm you are signed in.

---

# Phase 2 Reference — Clerk Authentication Basics

## `ClerkProvider`

Wraps the application and gives Clerk components access to auth state.

File:

```txt
app/layout.tsx
```

---

## `SignIn`

Renders Clerk’s sign-in UI.

File:

```txt
app/sign-in/[[...sign-in]]/page.tsx
```

---

## `SignUp`

Renders Clerk’s sign-up UI.

File:

```txt
app/sign-up/[[...sign-up]]/page.tsx
```

---

## `UserButton`

Renders the signed-in user avatar and account menu.

File:

```txt
components/auth-controls.tsx
```

---

## `proxy.ts`

In Next.js 16, `proxy.ts` handles request interception.

We use it to protect routes before they reach page code.

File:

```txt
proxy.ts
```

---

## `currentUser()`

Reads the signed-in Clerk user on the server.

We wrapped it in:

```txt
lib/auth.ts
```

as:

```ts
getCurrentUserProfile()
```

---

## Current Public Routes

```txt
/
 /sign-in
 /sign-up
 /design
```

---

## Current Protected Routes

```txt
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

---

# Part 4 Completion Checklist

You are ready for Part 5 if:

- [ ] Clerk application exists
- [ ] `@clerk/nextjs` is installed
- [ ] `.env.local` contains real Clerk keys
- [ ] `.env.local` is ignored by Git
- [ ] `.env.example` documents required variables
- [ ] `app/layout.tsx` uses `ClerkProvider`
- [ ] `/sign-in` shows Clerk sign-in UI
- [ ] `/sign-up` shows Clerk sign-up UI
- [ ] `proxy.ts` protects app routes
- [ ] Signed-out users cannot access `/dashboard`
- [ ] Signed-in users can access `/dashboard`
- [ ] User avatar menu appears in the app header
- [ ] `/settings/auth-status` displays server-side Clerk user data
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
