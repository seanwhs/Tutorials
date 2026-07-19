**[GENERATED: Part 1 — Setup, First Project & Toolbox]**
**[STARTING: Part 2 — Auth & Organizations]**

---

# Part 2: Auth & Organizations

With our workshop set up and a running project on screen, it's time to make Greymatter Ledger actually recognize *who* is using it. Right now, anyone who visits `localhost:3000` sees the same generic page — there's no concept of "logged in," let alone "which company's books am I looking at." This part fixes that entirely: real sign-up/sign-in, and then Organizations, so each company using the app gets its own completely separate set of books.

## Step 2.1 — Creating a Clerk Account and Application

### The Target
Sign up for Clerk and create a new "application" inside their dashboard — the container that will hold all of Greymatter Ledger's users.

### The Concept
Recall the front-desk-security-company analogy from Part 1. Before that company can guard *your* building specifically, they need to open a file for your building — your address, your floor plan, your specific rules. That's what a Clerk "application" is: a dedicated, isolated configuration just for Greymatter Ledger, completely separate from any other project you might build with Clerk later.

### The Implementation

1. Go to **[clerk.com](https://clerk.com)** and click **Sign up**. Create an account using your email, Google, or GitHub.
2. Once inside the dashboard, click **Create application**.
3. Name it `Greymatter Ledger`.
4. Under "Sign-in options," leave the defaults checked (Email, Google is fine to leave enabled too) — we'll keep this simple for now and it's easy to change later.
5. Click **Create application**.

You'll land on a page titled something like **"Next.js"** under a "Set up your application" quickstart. Keep this tab open — you'll copy two keys from it in the next step.

### The Verification

Confirm you can see your new application's dashboard, with a left sidebar showing sections like **Users**, **Organizations**, **Sessions**, and **API Keys**. If you see this, your Clerk application exists and is ready to connect to our code.

---

## Step 2.2 — Installing the Clerk SDK

### The Target
Add Clerk's Next.js package to our project.

### The Concept
Right now, our project has no idea Clerk exists — it's just a website with no login capability. Installing Clerk's **SDK** ("Software Development Kit" — a pre-written package of code someone else built so you don't have to write it yourself) gives our project the actual components and functions (`<SignIn />`, `auth()`, etc.) needed to talk to the Clerk service we just set up.

### The Implementation

In your terminal, inside `greymatter-ledger/` (make sure `npm run dev` is still running in your other tab — you don't need to stop it):

```bash
npm install @clerk/nextjs
```

### The Verification

Open `package.json` and confirm a new line exists under `"dependencies"`:

```json
"@clerk/nextjs": "^6.x.x"
```

(Exact version number may differ — any recent `6.x.x` or higher is correct.)

---

## Step 2.3 — Environment Variables: Storing Secret Keys Safely

### The Target
Create a `.env.local` file to store Clerk's API keys — without ever committing them to Git.

### The Concept
Think of these keys like the physical master key to your building's front desk system. You'd never staple a photocopy of your master key to a public bulletin board — but that's effectively what happens if you paste a secret key directly into your code and push it to GitHub (which we will do in Part 13, publicly). **Environment variables** are a way to keep secrets in a separate file, on your machine only, that your code reads at runtime — and that file is explicitly excluded from Git via `.gitignore`.

### The Implementation

Back in the Clerk dashboard tab, find the section showing:

```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
```

In VS Code, create a new file at the **project root** (same level as `package.json`, not inside `src/`):

**`.env.local`**
```bash
# Clerk authentication keys — copy these exact values from your Clerk dashboard's API Keys page.
# NEXT_PUBLIC_ prefix means this value is safe to expose to the browser (it's a public identifier).
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_actual_key_here

# No NEXT_PUBLIC_ prefix means this stays server-side only — never sent to the browser. This is the truly secret one.
CLERK_SECRET_KEY=sk_test_your_actual_key_here

# We'll add these next — they tell Clerk which URLs in our app handle sign-in/sign-up.
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dashboard
```

Replace `pk_test_your_actual_key_here` and `sk_test_your_actual_key_here` with your real values copied from Clerk.

### The Verification

Open `.gitignore` at the project root and confirm this line already exists (Next.js's scaffold includes it by default):

```
.env*
```

This pattern matches `.env.local` and any other `.env` variant, telling Git to never track it. Run:

```bash
git status
```

Confirm `.env.local` does **not** appear in the list of files Git wants to add. If it *does* appear, stop — do not commit — and double check `.gitignore` contains `.env*` exactly, then re-run `git status`.

---

## Step 2.4 — Wrapping the App in `<ClerkProvider>`

### The Target
Modify `src/app/layout.tsx` so every page in our app has access to Clerk's authentication state.

### The Concept
Think of `<ClerkProvider>` like the building's main electrical panel — it needs to sit at the very top of the building, feeding power down to every single floor and room, before any individual light switch (a `<SignIn />` button, a `useUser()` hook) can work anywhere inside. We wrap our entire app, at the root layout, so authentication state is available everywhere.

### The Implementation

Open `src/app/layout.tsx`. Replace its full contents with:

**`src/app/layout.tsx`**
```tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export const metadata: Metadata = {
  title: "Greymatter Ledger",
  description: "Double-entry accounting, built from scratch.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    // ClerkProvider wraps the entire app so any page or component
    // below it can ask "is someone logged in?" via Clerk's hooks/components.
    <ClerkProvider>
      <html lang="en">
        <body className="antialiased">{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

### The Verification

Save the file. Check the terminal running `npm run dev` — it should recompile without errors. Visit `http://localhost:3000` in your browser — the page should still load (it will look identical to before; `<ClerkProvider>` doesn't change appearance, it just makes auth state available). If you see a red error overlay instead, re-check that `.env.local`'s two Clerk keys are pasted correctly with no extra quotes or spaces.

---

## Step 2.5 — Creating `src/proxy.ts` (Next.js 16's Replacement for `middleware.ts`)

### The Target
Create the file that intercepts every incoming request to check "should this visitor be allowed to see this page?"

### The Concept
Imagine a checkpoint at the entrance of a secured office building — before anyone reaches their desk, a guard checks their badge. In older versions of Next.js, this checkpoint file was named `middleware.ts`. **Next.js 16 renames this exact concept to `src/proxy.ts`** — same job, new name, new required location (inside `src/`, which is exactly why we made sure our project had that folder in Part 1).

This file runs on *every* request, before any page even starts rendering, and decides: does this route need a logged-in user? If so, and nobody's logged in, redirect them to sign in.

### The Implementation

Create a new file directly inside `src/` (as a sibling to the `app` folder, **not** inside `app`):

**`src/proxy.ts`**
```typescript
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

// createRouteMatcher builds a function that tests an incoming request's URL
// against a list of patterns. Think of this as the guard's checklist of
// "which rooms actually require a badge scan."
const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)", // the (.*) means "this path and everything under it"
  "/accounts(.*)",
  "/invoices(.*)",
  "/bills(.*)",
  "/reports(.*)",
  "/settings(.*)",
]);

// clerkMiddleware runs on every request matched by our config below.
// auth.protect() is the actual "badge scan" — if the visitor isn't signed in,
// Clerk automatically redirects them to the sign-in page for us.
export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  // This tells Next.js exactly which requests should even bother running
  // through proxy.ts — skipping static files (images, CSS) and internals
  // for performance, since those never need an auth check.
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
```

### The Verification

Save the file. In the terminal running `npm run dev`, confirm there are no compile errors. Visit `http://localhost:3000/dashboard`** in your browser (a route that doesn't exist as a page yet, but that's fine for this test). You should be redirected to a Clerk-hosted sign-in URL (something like `localhost:3000/sign-in`) instead of seeing a raw 404 — this confirms `proxy.ts` is intercepting the request and correctly identifying `/dashboard` as protected. The sign-in page itself will look broken/unstyled right now (we haven't built it yet) — that's expected at this exact step; we're only verifying the *redirect* happens.

If instead you see a Next.js 404 page with no redirect at all, `proxy.ts` isn't being picked up — double check it's saved as `src/proxy.ts` (not `src/app/proxy.ts`, and not `src/middleware.ts`), then restart the dev server (`Ctrl+C`, then `npm run dev` again).

---

## Step 2.6 — Building the Sign-In and Sign-Up Pages

### The Target
Create two real pages, `/sign-in` and `/sign-up`, using Clerk's pre-built components.

### The Concept
Recall the security-company analogy: Clerk doesn't just guard the door, it also hands out the actual sign-in desk/kiosk. Instead of building a login form by hand — handling password fields, error states, "forgot password" flows, all of which are genuinely hard to get right and dangerous to get wrong — we drop in Clerk's `<SignIn />` and `<SignUp />` components, which render a complete, secure, working form.

Clerk requires these to live at a special kind of route called a **catch-all route**, written as `[[...sign-in]]`. This unusual folder name means "this page handles `/sign-in` itself, and also any sub-path Clerk might need, like `/sign-in/factor-one` during multi-step verification" — without us having to build each of those sub-pages ourselves.

### The Implementation

Create the following folder structure and files inside `src/app/`:

**`src/app/sign-in/[[...sign-in]]/page.tsx`**
```tsx
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    // The centering wrapper just puts Clerk's form in the middle of the screen.
    // Clerk's <SignIn /> component renders the entire form, validation,
    // and "forgot password" flow — we don't write any of that ourselves.
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <SignIn />
    </div>
  );
}
```

**`src/app/sign-up/[[...sign-up]]/page.tsx`**
```tsx
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <SignUp />
    </div>
  );
}
```

### The Verification

Save both files. Visit `http://localhost:3000/sign-up` directly in your browser. You should now see Clerk's fully-styled sign-up form (email field, password field, "Continue" button) rendered in the center of the page.

Create a real account for yourself right now using your own email — you'll use this account for the rest of the course. Complete the sign-up flow (including any email verification code Clerk sends you).

After signing up, Clerk should redirect you to `/dashboard` (because of the `NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL` we set in `.env.local`) — this page doesn't exist yet, so you'll see a 404. **This 404 is expected and correct** — it actually proves sign-up succeeded and the redirect fired.

---

## Step 2.7 — Building a Minimal Dashboard Page

### The Target
Create `/dashboard` — a real, protected page — so we have somewhere for authenticated users to land, and so we can visibly confirm "logged in" state.

### The Concept
Right now we've built the checkpoint (`proxy.ts`) and the sign-in desk (`/sign-in`, `/sign-up`), but there's no actual "inside the building" yet. This step builds the simplest possible lobby: a page that greets the logged-in user by name and offers a sign-out button, proving the whole chain — sign up → redirect → protected page → know who's logged in — works end to end.

### The Implementation

**`src/app/dashboard/page.tsx`**
```tsx
import { currentUser } from "@clerk/nextjs/server";
import { UserButton } from "@clerk/nextjs";
import { redirect } from "next/navigation";

export default async function DashboardPage() {
  // currentUser() runs on the server and asks Clerk: "who is making this request?"
  // Because proxy.ts already guarantees only signed-in users reach this far,
  // this should never actually be null in practice — but we check anyway,
  // since defensive code is cheap insurance against future changes.
  const user = await currentUser();

  if (!user) {
    redirect("/sign-in");
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-4xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">
            Welcome, {user.firstName ?? user.emailAddresses[0].emailAddress}
          </h1>
          {/* UserButton is a pre-built Clerk component: clicking it opens
              a dropdown with account settings and a "Sign out" option. */}
          <UserButton afterSignOutUrl="/" />
        </div>
        <p className="mt-4 text-gray-600">
          This is your Greymatter Ledger dashboard. We&apos;ll build the real
          contents of this page starting in Part 5.
        </p>
      </div>
    </div>
  );
}
```

### The Verification

Save the file. In your browser, navigate to `http://localhost:3000/dashboard`. Since you're already signed in from Step 2.6, you should now see:

- A heading reading "Welcome, [your first name]"
- A small circular user avatar/button in the top right

Click the user avatar button, and confirm a dropdown appears with a **Sign out** option. Click it — you should be signed out and redirected to `/` (the homepage). Then navigate back to `http://localhost:3000/dashboard` directly — you should be bounced to `/sign-in`, proving the protection in `proxy.ts` is working correctly for signed-out visitors.

Sign back in at `/sign-in` using the account you created, and confirm you land back on `/dashboard`.

---

## Step 2.8 — Enabling Clerk Organizations

### The Target
Turn on Clerk's Organizations feature in the dashboard, so Greymatter Ledger can support multiple separate companies, each with its own isolated data.

### The Concept
Right now, our app only understands *individual people*. But Greymatter Ledger is a business accounting tool — and one person might run (or work for) more than one company, and one company might have more than one employee needing access to the same books. We need a concept that sits *above* the individual user: the **Organization**. Recall the apartment-building-floors analogy from Part 1 — a user can hold keycards to multiple floors, but data on Floor 3 must never leak to someone standing on Floor 5. Every table we build from Part 3 onward will include an `organizationId` column, tying every single row of data to exactly one company.

### The Implementation

1. In your Clerk dashboard, click **Organizations** in the left sidebar.
2. Toggle **Enable organizations** to on.
3. Leave the default settings (allow any user to create an organization; require an organization membership isn't enforced by Clerk itself — we'll build that requirement ourselves in the next step, at the application level, so we control the exact behavior).

### The Verification

Back in Clerk's sidebar, confirm the **Organizations** section now shows an empty table with a header like "No organizations yet" — this confirms the feature is live on your Clerk application, ready for our code to use.

---

## Step 2.9 — Adding the Organization Switcher

### The Target
Add Clerk's `<OrganizationSwitcher />` component to the dashboard, letting a signed-in user create a new organization or switch between ones they belong to.

### The Concept
Think of this like the floor-selection panel inside an elevator — press a button, and you're instantly moved to a different floor (organization), with completely different contents behind each door, even though it's the same elevator (the same logged-in user).

### The Implementation

Update the dashboard page to include the switcher:

**`src/app/dashboard/page.tsx`**
```tsx
import { currentUser } from "@clerk/nextjs/server";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";
import { redirect } from "next/navigation";

export default async function DashboardPage() {
  const user = await currentUser();

  if (!user) {
    redirect("/sign-in");
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-4xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">
            Welcome, {user.firstName ?? user.emailAddresses[0].emailAddress}
          </h1>
          <div className="flex items-center gap-4">
            {/* OrganizationSwitcher lets the user create a new company
                ("organization") or switch between companies they already
                belong to. hidePersonal=true forces every user into a real
                organization context — we don't want anyone working "outside"
                a company, since every table we build expects an org ID. */}
            <OrganizationSwitcher
              hidePersonal={true}
              afterCreateOrganizationUrl="/dashboard"
              afterSelectOrganizationUrl="/dashboard"
            />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>
        <p className="mt-4 text-gray-600">
          This is your Greymatter Ledger dashboard. We&apos;ll build the real
          contents of this page starting in Part 5.
        </p>
      </div>
    </div>
  );
}
```

### The Verification

Save the file and reload `http://localhost:3000/dashboard`. You should now see an **"Create organization"** button/switcher next to your user avatar (since `hidePersonal={true}` prevents it from offering a "personal account" option). Click it, choose **Create organization**, name it something like `Acme Test Co`, and confirm.

After creating it, the switcher should now display "Acme Test Co" as the active organization. Click the switcher again and confirm you can see an option to create a *second* organization — go ahead and create one (e.g., `Second Test Co`), then switch back and forth between the two using the switcher. Confirm the switcher UI correctly reflects whichever one is currently active.

---

## Step 2.10 — Guarding the Dashboard: Requiring an Active Organization

### The Target
Prevent a signed-in user from seeing real dashboard content if they haven't selected (or created) an organization yet.

### The Concept
Think of this like a hotel key card that's been activated (you're a verified guest — signed in) but not yet assigned to a specific room (no organization selected). You're allowed inside the building lobby, but you shouldn't be able to wander into "the dashboard" — meaningful, company-specific data — until you've picked a room. This guard is important now because every feature from Part 3 onward assumes `auth().orgId` is never null.

### The Implementation

Update the dashboard page one more time to add this check:

**`src/app/dashboard/page.tsx`**
```tsx
import { auth, currentUser } from "@clerk/nextjs/server";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";
import { redirect } from "next/navigation";

export default async function DashboardPage() {
  const user = await currentUser();

  if (!user) {
    redirect("/sign-in");
  }

  // auth() gives us the current request's session details, including
  // orgId — the ID of whichever organization is currently active for this user.
  // If it's null, they're signed in as a person
  // but haven't created or selected a company yet — and since every
  // future feature (invoices, journal entries, reports) is scoped to
  // an organization, we can't let them past this point without one.

  const { orgId } = await auth();

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-4xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">
            Welcome, {user.firstName ?? user.emailAddresses[0].emailAddress}
          </h1>
          <div className="flex items-center gap-4">
            <OrganizationSwitcher
              hidePersonal={true}
              afterCreateOrganizationUrl="/dashboard"
              afterSelectOrganizationUrl="/dashboard"
            />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        {orgId ? (
          <div className="mt-8 rounded-lg border border-gray-200 bg-white p-6">
            <p className="text-gray-600">
              This is your Greymatter Ledger dashboard for organization{" "}
              <span className="font-mono text-sm text-gray-800">{orgId}</span>.
              We&apos;ll build the real contents of this page starting in Part 5.
            </p>
          </div>
        ) : (
          // No active organization selected — show a clear call-to-action
          // instead of any real data, since there's no company to show
          // data for yet.
          <div className="mt-8 rounded-lg border border-yellow-300 bg-yellow-50 p-6">
            <h2 className="text-lg font-semibold text-yellow-900">
              No organization selected
            </h2>
            <p className="mt-2 text-yellow-800">
              Greymatter Ledger organizes all your accounting data by company.
              Use the switcher above to create your first organization before
              continuing.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
```

### The Verification

**Test the "no organization" state:** In the Clerk `<OrganizationSwitcher />`, switch to "Personal account" if that option is still reachable, or open an incognito/private browser window, sign up as a brand-new test user who hasn't created any organization yet, and land on `/dashboard`. You should see the yellow "No organization selected" box, and **not** any organization ID.

**Test the "has organization" state:** Back in your normal browser window (signed in as yourself with "Acme Test Co" active), reload `/dashboard`. You should see the white box showing "This is your Greymatter Ledger dashboard for organization `org_...`" with a real Clerk organization ID printed. Switch to "Second Test Co" using the switcher and confirm the printed `orgId` value changes to match — this proves the app correctly tracks *which* company's context you're currently in, which is the foundation every remaining part of this course depends on.

---

## Step 2.11 — Second Git Commit

### The Target
Save this entire chunk of working authentication code as a new checkpoint.

### The Concept
We just completed a meaningful, working unit of functionality — real accounts, real sign-in/sign-up, real organizations. This is exactly the kind of milestone worth freezing in Git history, so if anything breaks later, we can always compare against this known-good point.

### The Implementation

```bash
git add .
git commit -m "Add Clerk authentication, proxy.ts route protection, and organizations"
```

### The Verification

```bash
git log --oneline
```

Expected output: two lines, your original scaffold commit and this new one, e.g.:

```
a1b2c3d Add Clerk authentication, proxy.ts route protection, and organizations
e4f5g6h Initial commit: scaffold Next.js project, reorganized into src directory
```

---

## ✅ Checkpoint — Part 2

At this point, you should have:

- [x] A Clerk application created and connected via `.env.local` (never committed to Git)
- [x] `@clerk/nextjs` installed
- [x] `<ClerkProvider>` wrapping the entire app in `src/app/layout.tsx`
- [x] `src/proxy.ts` created, protecting `/dashboard`, `/accounts`, `/invoices`, `/bills`, `/reports`, and `/settings`
- [x] Working `/sign-in` and `/sign-up` pages using Clerk's pre-built components
- [x] A real account created and verified for yourself
- [x] A `/dashboard` page that greets the signed-in user and includes a working sign-out button
- [x] Clerk Organizations enabled, with a working `<OrganizationSwitcher />`
- [x] A guard on the dashboard requiring an active organization before showing real content
- [x] A second Git commit checkpoint

---

## 🔧 Troubleshooting — Part 2

**"Visiting any page shows a Clerk error like 'Missing publishable key'."**
Your `.env.local` values are missing or malformed. Confirm the file is named exactly `.env.local` (not `.env.local.txt`), sits at the project root, and that both keys are pasted with no surrounding quotes. Restart the dev server after any `.env.local` change — Next.js only reads environment variables at server startup, not on hot-reload.

**"`/dashboard` never redirects to sign-in — it just 404s."**
`src/proxy.ts` isn't in the right place, or the route matcher pattern isn't matching. Confirm the file path is exactly `src/proxy.ts` (sibling to `src/app`, not inside it), and that you restarted `npm run dev` after creating it.

**"After signing up, I get redirected to `/dashboard` but see a blank white screen."**
Open your browser's developer console (F12) and check for a red error. The most common cause at this stage is a typo in one of the `NEXT_PUBLIC_CLERK_*_URL` values in `.env.local` — double-check for stray spaces or missing slashes.

**"The Organization Switcher doesn't appear at all."**
Confirm you completed Step 2.8 (enabling Organizations in the Clerk dashboard) — this is a dashboard toggle, not something controlled by our code, and the component simply won't render its "create organization" option if the feature is off.

**"I created an organization, but `orgId` still shows as null on the dashboard."**
Try fully signing out and back in once — Clerk's session sometimes needs a fresh session token to reflect a brand-new organization membership immediately after creation. If it persists, double-check you clicked directly on the newly created organization in the switcher dropdown (rather than it silently staying on "Personal account", if that option was still visible).

**"I committed `.env.local` to Git by accident before adding `.gitignore`'s pattern."**
Stop immediately and do not push to GitHub yet (we don't reach that until Part 13). Run `git rm --cached .env.local`, confirm `.gitignore` contains `.env*`, then commit that removal: `git commit -m "Remove accidentally tracked .env.local"`. Also rotate (regenerate) your Clerk secret key in the dashboard as a precaution, since it briefly existed in your local Git history.
