# Part 1: Foundations — Scaffolding the App & Authenticating Users

## 1.0 Where we are on the map

Recall the architecture diagram from Part 0. In this Part, we are building exactly two things from that picture:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              BROWSER (Client)                            │
│         >>> Next.js React app — we scaffold this in 1.1 <<<              │
└───────────────────────────────┬────────────────────────────────────────-─┘
                                 │  HTTPS
                                 ▼
┌────────────────────────────────────────────────────────────────────────-─┐
│                     NEXT.JS 16 APPLICATION SERVER                        │
│  ┌────────────────────┐                                                  │
│  │ >>> Clerk Middleware <<<   we build this in 1.3–1.5                   │
│  └────────────────────┘                                                  │
└────────────────────────────────────────────────────────────────────────-─┘
```

Everything else — the database, encryption, consent ledger, Inngest — comes later. Right now, our only job is: **get a real Next.js 16 app running, and make sure nobody can see a user's data without proving who they are first.** We'll close the Part by writing our first DPIA, which will directly shape the database schema we design in Part 4.

By the end of Part 1 you will have:
1. A running Next.js 16 project, version-controlled in Git.
2. Tailwind CSS configured and working.
3. Clerk authentication fully wired up — sign-up, sign-in, sign-out, and a protected dashboard route.
4. Middleware that blocks unauthenticated access to sensitive pages.
5. A written, versioned DPIA document living in the repo itself (not off in some forgotten Google Doc).

---

## Step 1.1 — Scaffolding the Next.js 16 project

### The Target
An empty folder becomes a running Next.js 16 application, using the **App Router** and **TypeScript**.

### The Concept
Think of `create-next-app` as ordering a furnished studio apartment instead of an empty concrete shell. You *could* pour your own foundation, wire your own electrics, and build your own walls (write a custom Webpack config, a custom server, custom routing) — but almost nobody does that anymore, because the "furnished apartment" comes with sensible, battle-tested defaults: a router, a build system, a dev server, TypeScript support, and Tailwind integration, all pre-wired to work together.

The **App Router** (the `app/` directory convention) is Next.js's current routing system. The core idea: **folders are routes**. A folder named `app/dashboard/` with a `page.tsx` file inside it automatically becomes the page served at `/dashboard`. No manual route-registration file to maintain — the file system *is* the router. This matters for us because later, protecting a route will be as simple as "this folder requires auth," rather than hunting through a central router config.

We'll also use **TypeScript** from the very first file. In a beginner-friendly series it might seem tempting to skip types "to keep things simple," but for an app handling sensitive personal data, TypeScript is a first line of defense: it stops entire classes of bugs (e.g., accidentally passing a raw, unencrypted string where an encrypted one was expected) at compile time, before the code ever runs. We treat this as non-negotiable from line one.

### The Implementation

Open your terminal and run:

```bash
npx create-next-app@latest greymatter-mindfulness-log
```

You'll be prompted with a series of questions. Answer exactly as follows (this matters — later steps assume these exact choices):

```
✔ Would you like to use TypeScript? … Yes
✔ Would you like to use ESLint? … Yes
✔ Would you like to use Tailwind CSS? … Yes
✔ Would you like your code inside a `src/` directory? … Yes
✔ Would you like to use App Router? (recommended) … Yes
✔ Would you like to use Turbopack for `next dev`? … Yes
✔ Would you like to customize the import alias (`@/*` by default)? … No
```

Once it finishes scaffolding, move into the project and open it in your editor:

```bash
cd greymatter-mindfulness-log
code .
```

Your folder structure should look like this:

```
greymatter-mindfulness-log/
├── src/
│   └── app/
│       ├── favicon.ico
│       ├── globals.css
│       ├── layout.tsx
│       └── page.tsx
├── public/
├── .eslintrc.json  (or eslint.config.mjs, depending on version)
├── next.config.ts
├── package.json
├── postcss.config.mjs
├── tailwind.config.ts
├── tsconfig.json
└── README.md
```

### The Verification

Start the development server:

```bash
npm run dev
```

Open **http://localhost:3000** in your browser. You should see the default Next.js welcome page. In your terminal, you should see something like:

```
▲ Next.js 16.0.0 (Turbopack)
- Local:        http://localhost:3000
✓ Ready in 900ms
```

If you see that, your foundation is poured correctly. Stop the server for now (`Ctrl+C`) — we have a couple of cleanup and configuration steps before we run it again.

---

## Step 1.2 — Initializing Git and cleaning the slate

### The Target
A Git repository tracking our project, and a clean starting `page.tsx` we'll build on throughout the series.

### The Concept
Version control is like a save-point system in a video game — at any point, if something breaks, you can rewind to the last known-good state instead of starting over. For a project themed around auditability and provable history (we will *literally build an audit ledger later*), it's fitting that our own development process starts with a clean, honest history from commit #1.

### The Implementation

`create-next-app` already initialized a Git repo for you. Let's make our first real commit and clean up the placeholder homepage.

**File: `src/app/page.tsx`**

```tsx
// src/app/page.tsx
//
// This is the public-facing landing page — the only page in the entire app
// that an unauthenticated (not-yet-signed-in) visitor is allowed to see.
// Everything else will live behind Clerk's authentication wall.

export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-slate-950 px-6 text-slate-100">
      <div className="max-w-xl text-center">
        <h1 className="text-4xl font-bold tracking-tight">
          GreyMatter Mindfulness Log
        </h1>
        <p className="mt-4 text-lg text-slate-400">
          A private space to track your mood, journal your thoughts, and stay
          on top of your wellbeing — built with privacy as a first-class
          feature, not an afterthought.
        </p>
      </div>
    </main>
  );
}
```

Now let's commit:

```bash
git add -A
git commit -m "chore: initial Next.js 16 scaffold with Tailwind and TypeScript"
```

### The Verification

Run:

```bash
git log --oneline
```

You should see your one commit listed. Run `npm run dev` again and confirm **http://localhost:3000** now shows your new placeholder landing page with the dark background and centered text.

---

## Step 1.3 — Meeting Clerk: creating your application

### The Target
A Clerk account and application instance, giving us API keys we'll wire into our Next.js app.

### The Concept
**Authentication** answers the question "who are you?" It's easy to underestimate how much work goes into doing this *safely*: secure password hashing, session tokens, protection against brute-force attacks, email verification, password reset flows, optional multi-factor authentication (a second proof of identity, like a code from your phone, in addition to your password)... Rolling all of this yourself is like deciding to smelt your own steel to build a door hinge — technically possible, but a very poor use of your time, and extremely easy to get subtly wrong in a way that isn't discovered until it's exploited.

**Clerk** is a hosted authentication provider: a specialized company whose entire job is to run that "ID check at the door" correctly, at scale, with a well-audited security team behind it. We integrate it as a *dependency*, the same way we depend on Postgres to store bytes safely on disk. This isn't a cop-out — for a solo developer or small team, using a proven auth provider for something this security-critical is itself a best practice, not a shortcut.

### The Implementation

1. Go to **https://clerk.com** and sign up for a free account.
2. Once logged into the Clerk Dashboard, click **"Create Application"**.
3. Name it `GreyMatter Mindfulness Log`.
4. Under **sign-in options**, enable **Email** and **Google** (you can enable more later — we're keeping the surface area small for now, which is itself a data-minimization habit: don't add sign-in methods you don't need).
5. Click **Create Application**.

Clerk will now show you an **API Keys** screen with two values you need:

- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
- `CLERK_SECRET_KEY`

Back in your project, create an environment file to hold these. **Environment variables** are a way of keeping configuration — especially secrets — out of your source code, so they're never accidentally committed to Git or exposed in your bundled frontend JavaScript.

**File: `.env.local`**

```bash
# .env.local
# This file holds secrets and environment-specific config.
# It must NEVER be committed to Git (we'll enforce that in the next step).

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_actual_key_here
CLERK_SECRET_KEY=sk_test_your_actual_key_here

# Where Clerk should redirect users after they sign in / sign up.
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dashboard
```

Replace the two placeholder key values with the real ones from your Clerk dashboard.

Now confirm `.env.local` is ignored by Git — open the generated `.gitignore` file and confirm it contains this line (it does by default in Next.js scaffolds, but we verify explicitly since this is a security-critical file):

**File: `.gitignore`** (verify this line exists)

```
.env*.local
```

### The Verification

Run:

```bash
git check-ignore -v .env.local
```

You should see output confirming `.env.local` is matched by the `.gitignore` rule, e.g.:

```
.gitignore:34:.env*.local	.env.local
```

If nothing prints, **stop** — it means `.env.local` is NOT ignored, and committing it would leak your Clerk secret key. Fix `.gitignore` before proceeding.

---

## Step 1.4 — Installing and wiring the Clerk SDK

### The Target
The `@clerk/nextjs` package installed, and the entire app wrapped in Clerk's authentication context.

### The Concept
Clerk needs to know, on every single page of your app, whether there's a signed-in user and who they are. The way it does this in Next.js's App Router is by wrapping your whole application in a **Provider** component — think of it like a security guard's radio channel that's broadcasting "here's who's currently signed in" to every single component in the tree, so any component, anywhere, can ask "is someone signed in right now, and if so, who?"

### The Implementation

Install the package:

```bash
npm install @clerk/nextjs
```

Now we wrap the entire application in Clerk's `<ClerkProvider>`. This has to happen in the **root layout** — the one file that wraps every single page in the app, no exceptions.

**File: `src/app/layout.tsx`**

```tsx
// src/app/layout.tsx
//
// The root layout wraps EVERY page in the app. By putting <ClerkProvider>
// here, every component in our tree — no matter how deeply nested — can
// ask "is there a signed-in user right now?" via Clerk's hooks/helpers.

import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export const metadata: Metadata = {
  title: "GreyMatter Mindfulness Log",
  description:
    "A privacy-first mood tracking and journaling application.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    // ClerkProvider must wrap <html> so that auth context is available
    // to every Server Component and Client Component in the tree.
    <ClerkProvider>
      <html lang="en">
        <body className="antialiased">{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

### The Verification

Run `npm run dev` and reload **http://localhost:3000**. The page should look identical to before — `<ClerkProvider>` doesn't render any visible UI by itself, it just makes authentication context available. If the page loads without errors in the browser console or terminal, the provider is wired correctly.

If you see an error like `Missing publishableKey`, double check your `.env.local` file has the correct key name (`NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`) and restart the dev server — Next.js only reads `.env.local` on startup.

---

## Step 1.5 — Middleware: the ID check at every door

### The Target
`src/middleware.ts` — a file that runs before *every* matching request, deciding whether the request is allowed to proceed.

### The Concept
**Middleware** is code that runs *before* your actual page or API logic, on every incoming request. Picture an office building with a single security desk in the lobby: no matter which floor or office you're heading to, you pass the desk first. The guard doesn't need to know what's on floor 12 — they just check your badge and either wave you through or stop you.

That's exactly the job of Clerk's middleware here: it intercepts every request to our app and checks "does this route require sign-in, and if so, is this visitor signed in?" We get to declare which routes are public (the landing page, sign-in, sign-up) and treat everything else as protected, by default. This "protected by default, public by exception" posture is a deliberate security choice — it's much harder to accidentally leave a sensitive page unprotected if the default is "locked," than if the default is "open."

### The Implementation

**File: `src/middleware.ts`**

```typescript
// src/middleware.ts
//
// This file runs on the Edge (Clerk/Next.js's fast, globally-distributed
// runtime) before almost every request. It's our single, centralized
// "ID check at the door" for the entire application.

import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

// We explicitly enumerate the routes that DO NOT require authentication.
// Everything not matched here is protected by default — this is the
// "secure by default" posture we want for an app handling sensitive data.
const isPublicRoute = createRouteMatcher([
  "/",             // the marketing/landing page
  "/sign-in(.*)",  // Clerk's sign-in page and its sub-routes
  "/sign-up(.*)",  // Clerk's sign-up page and its sub-routes
]);

export default clerkMiddleware(async (auth, request) => {
  // If the requested route is NOT in our public allow-list,
  // force authentication — this throws a redirect to sign-in
  // if the visitor isn't logged in yet.
  if (!isPublicRoute(request)) {
    await auth.protect();
  }
});

export const config = {
  // This matcher tells Next.js which requests should even run through
  // the middleware in the first place. We skip static assets (images,
  // fonts, etc.) and Next.js's internal files for performance, but we
  // always run on API routes and page navigations.
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
```

### The Verification

With `npm run dev` running, open a **private/incognito browser window** (so you're not accidentally signed in) and navigate to:

```
http://localhost:3000/dashboard
```

Since `/dashboard` doesn't exist yet as a page, and isn't in our public allow-list, Clerk's middleware should redirect you to a sign-in page (it will look like a generic Clerk-hosted page for now — we'll build a custom one shortly). This confirms the "protected by default" rule is working *before* we've even built the protected page — proof that our security posture doesn't depend on remembering to protect each page individually.

---

## Step 1.6 — Building sign-in, sign-up, and a protected dashboard

### The Target
Dedicated `/sign-in` and `/sign-up` pages using Clerk's pre-built components, and a `/dashboard` route that only signed-in users can reach.

### The Concept
Clerk ships pre-built, fully-accessible React components (`<SignIn />` and `<SignUp />`) that render the entire sign-in/sign-up form — fields, validation, error messages, social login buttons — all correctly wired to Clerk's backend. Think of it like installing a pre-fabricated, code-compliant staircase instead of building one board-by-board: it's faster, and far less likely to have a structural flaw (e.g., a subtly broken password-reset flow) than a custom one built under deadline pressure.

For routes that use these dynamic Clerk components with sub-paths (like `/sign-in/factor-one` for multi-factor auth steps), Next.js's App Router uses a **catch-all route** — a folder named `[[...rest]]` — which means "match `/sign-in` and also `/sign-in/anything/else/after/it`."

### The Implementation

**File: `src/app/sign-in/[[...rest]]/page.tsx`**

```tsx
// src/app/sign-in/[[...rest]]/page.tsx
//
// The [[...rest]] folder name is a Next.js "optional catch-all" route.
// It matches /sign-in AND /sign-in/anything-clerk-needs (e.g. MFA steps),
// which Clerk's <SignIn /> component manages internally.

import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-950">
      <SignIn />
    </main>
  );
}
```

**File: `src/app/sign-up/[[...rest]]/page.tsx`**

```tsx
// src/app/sign-up/[[...rest]]/page.tsx

import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-950">
      <SignUp />
    </main>
  );
}
```

Now let's build the protected dashboard. This page will use Clerk's `currentUser()` server-side helper — a function that runs on the server and returns the signed-in user's details, or `null` if nobody's signed in. Since our middleware already guarantees nobody unauthenticated reaches this far, we use it here purely to *personalize* the page, not to re-check authentication (that's the middleware's job — one job, one place).

**File: `src/app/dashboard/page.tsx`**

```tsx
// src/app/dashboard/page.tsx
//
// This is a Server Component (no "use client" directive), meaning it runs
// entirely on the server. currentUser() safely fetches the signed-in
// user's profile server-side — it never ships any secret to the browser.

import { currentUser } from "@clerk/nextjs/server";
import { UserButton } from "@clerk/nextjs";

export default async function DashboardPage() {
  // By the time this code runs, Clerk's middleware has ALREADY guaranteed
  // a signed-in user exists — this is defense-in-depth, not the primary gate.
  const user = await currentUser();

  return (
    <main className="min-h-screen bg-slate-950 px-6 py-10 text-slate-100">
      <div className="mx-auto max-w-3xl">
        <header className="flex items-center justify-between border-b border-slate-800 pb-4">
          <h1 className="text-2xl font-semibold">
            Welcome back, {user?.firstName ?? "friend"}
          </h1>
          {/* UserButton is a pre-built Clerk component: clicking it opens
              an account menu with "Manage account" and "Sign out". */}
          <UserButton afterSignOutUrl="/" />
        </header>

        <section className="mt-8 rounded-lg border border-slate-800 bg-slate-900 p-6">
          <p className="text-slate-400">
            This is your private dashboard. In upcoming parts of this
            series, this is where you&apos;ll log your mood, write journal
            entries, set medication reminders, and manage your consent
            preferences.
          </p>
        </section>
      </div>
    </main>
  );
}
```

### The Verification

With `npm run dev` running:

1. Navigate to `http://localhost:3000/sign-up`. You should see Clerk's full sign-up form rendered inside your dark-themed page background.
2. Create a test account using your own email address.
3. After verifying (Clerk will email you a code if email verification is enabled), you should be automatically redirected to `/dashboard` (this is because of the `NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL` we set in `.env.local`).
4. Confirm you see "Welcome back, [Your First Name]" and a user avatar button in the top-right.
5. Click the avatar button, then "Sign out." Confirm you're returned to the landing page.
6. Try navigating directly to `http://localhost:3000/dashboard` again while signed out. You should be bounced to `/sign-in` — proof the middleware is protecting the route.

Commit your progress:

```bash
git add -A
git commit -m "feat: wire up Clerk auth with protected dashboard route"
```

---

## Step 1.7 — Writing the project's first DPIA

### The Target
A living document, stored in the repository itself, formally assessing the privacy risk of the data we're about to collect — *before* we design a single database table.

### The Concept
A **DPIA (Data Protection Impact Assessment)** is a structured, written answer to the question: *"If we collect this data, what could go wrong, for whom, and what are we doing about it?"* Under GDPR, a DPIA is not just good practice — it's a **legal requirement** whenever you're processing special category data (like mental health information) at scale.

Think of it like a building's fire safety assessment, done at the blueprint stage, not after the building is occupied. You look at the floor plan and ask: "Where are the exits? What happens if there's a fire in the server room? Who's responsible for maintaining the extinguishers?" You don't wait for a fire to find out your assumptions were wrong. A DPIA does the same thing for data: it forces you to name your data flows, name your risks, and name your mitigations, *on paper*, before you write the `CREATE TABLE` statement.

We store this DPIA as a Markdown file **inside the Git repository**, not in a separate Google Doc or wiki, for a deliberate reason: a document that lives next to the code gets reviewed in the same pull requests as the code, gets versioned alongside the code, and can't quietly drift out of sync with what the app actually does. If Part 4 introduces a new sensitive column, the honest workflow is "update the DPIA in the same PR" — not "update the database and remember to tell compliance later" (which, in the real world, is exactly how these things get forgotten).

A DPIA typically documents, for each category of data:
- **What** is being collected.
- **Why** (the purpose).
- **Legal basis** — under GDPR, every piece of personal data processing needs one of six lawful bases; for sensitive mental-health data, the relevant one is almost always **explicit consent** (Article 9(2)(a)), meaning the user must actively and specifically agree, not just passively accept a generic terms-of-service checkbox.
- **Risk if exposed** — what's the realistic worst case if this data leaks?
- **Mitigation** — what technical/organizational control reduces that risk?
- **Retention** — how long do we keep it, and why that long and no longer?

We won't get everything right in this first draft — that's expected and fine. This is a *living document*: we'll revise it explicitly in later Parts as our architecture evolves (e.g., once we add encryption in Part 4, we'll update the "Mitigation" column to reference it by name).

### The Implementation

Create a `docs/` folder at the project root (sitting alongside `src/`, not inside it — this is project documentation, not application source code) and add the DPIA file.

**File: `docs/DPIA.md`**

```markdown
# Data Protection Impact Assessment (DPIA)
### GreyMatter Mindfulness Log

**Status:** Living document — revised as the architecture evolves.
**Version:** 1.0 (initial draft, written at project scaffolding stage — Part 1)
**Last updated:** 2026-07-21

---

## 1. Purpose of this document

This DPIA identifies the personal data GreyMatter Mindfulness Log intends to
collect, the purpose and legal basis for each category, the risk to the
individual if that data were exposed or misused, and the mitigations we
commit to building. It is written *before* implementation of the database
schema (Part 4) so that privacy risk informs the design, rather than being
retrofitted onto it afterward.

## 2. Description of processing

GreyMatter Mindfulness Log is a web application allowing an individual
("the user") to record their own mood, journal entries, and medication
reminders, and to manage granular consent preferences over how their data
is used. The application is intended for personal, individual use — not
for clinical, diagnostic, or third-party monitoring purposes. We are not
a medical device and do not provide medical advice.

## 3. Data inventory

| # | Data category | What, specifically | Special category? (GDPR Art. 9) |
|---|---|---|---|
| 1 | Account identity | Email address, name, hashed password (managed entirely by Clerk, never touched by our own code) | No |
| 2 | Mood entries | A numeric score (1–10) plus an optional short free-text note, timestamped | **Yes** — reveals health/mental health information |
| 3 | Journal entries | Free-text, user-authored long-form content | **Yes** — likely to reveal health, and potentially other special categories (e.g., religious belief, sexual orientation) depending on user's own writing |
| 4 | Medication reminders | Medication name, dosage/time schedule | **Yes** — directly reveals health condition being treated |
| 5 | Consent preferences | Boolean/categorical flags (e.g., "allow anonymized research use: yes/no") plus a timestamped history of changes | No (metadata about consent, not health data itself) — but must be handled carefully as it is evidentiary |
| 6 | Usage/audit metadata | Login timestamps, IP address at login (via Clerk), access logs for admin actions | No, but sensitive in aggregate (behavioral pattern) |

## 4. Purpose and legal basis for each category

| Data category | Purpose | Legal basis (GDPR Art. 6) | Special category basis (GDPR Art. 9, where applicable) |
|---|---|---|---|
| Account identity | Authenticate the user; enable sign-in | Art. 6(1)(b) — necessary for the contract (providing the service the user signed up for) | N/A |
| Mood entries | Let the user track mood trends over time | Art. 6(1)(a) — consent | Art. 9(2)(a) — **explicit consent**, captured distinctly from general ToS acceptance |
| Journal entries | Let the user record free-form reflections | Art. 6(1)(a) — consent | Art. 9(2)(a) — explicit consent |
| Medication reminders | Help the user remember to take medication | Art. 6(1)(a) — consent | Art. 9(2)(a) — explicit consent |
| Consent preferences | Record and honor the user's own choices | Art. 6(1)(c) — legal obligation (we are legally required to be able to prove consent was given) | N/A |
| Usage/audit metadata | Detect abuse, debug issues, satisfy security obligations | Art. 6(1)(f) — legitimate interest (security), narrowly scoped | N/A |

**Why explicit, separate consent and not just "agreeing to the Terms of Service"?**
Bundling consent for special category data into a general terms-of-service
acceptance is precisely the kind of "dark pattern" GDPR Art. 9 explicit
consent requirements exist to prevent. A user must be able to say yes to
"store my journal entries" independently of saying yes to "receive
marketing emails." We formalize this requirement now so it directly shapes
the consent UI we build in Part 5 — it cannot be a single "I agree" checkbox.

## 5. Necessity and proportionality

We ask, for each field: *do we need this specific piece of data to deliver
the specific feature, or are we collecting it "just in case"?* This is the
**data minimization** principle we formalize with database-level
constraints in Part 3. Notably, at this stage we are **explicitly deciding
not to collect**:

- Precise geolocation (not needed for any current feature).
- Full IP address history beyond what Clerk retains for its own security
  purposes (we do not need our own copy).
- Any government ID or clinical diagnosis codes (this app is a personal
  journal, not a clinical record system — collecting diagnosis codes would
  expand our regulatory obligations, e.g., toward HIPAA-style regimes, well
  beyond what this product needs).

## 6. Risk assessment

| Risk scenario | Likelihood | Impact on individual | Current/planned mitigation |
|---|---|---|---|
| Database is stolen/leaked (e.g., misconfigured backup, insider threat) | Low–Medium | Severe — mood/journal/medication data exposed in bulk could lead to discrimination, blackmail, reputational harm | **Field-level encryption** of mood notes, journal text, and medication data (Part 4), so a raw database leak yields ciphertext, not readable content |
| An internal admin/support tool over-exposes user content while debugging | Medium | Moderate–Severe — support staff read full journal entries when only metadata was needed | **Masking utilities** (Part 3) that show admins redacted/truncated views by default; **RBAC/ABAC** (Part 4) restricting which roles can request full decryption, with all such access logged |
| A user's consent choice is silently ignored or not honored (e.g., research opt-out doesn't propagate) | Low | Severe — legal violation, loss of user trust | **Append-only consent ledger** (Part 5) as the single source of truth, with an event-driven consumer (Inngest) that reacts to every consent change |
| A user requests deletion, but data lingers in a downstream system | Medium | Severe — legal violation of "right to be forgotten" | **Inngest-orchestrated deletion workflow** (Part 6) that cascades across every table and confirms completion |
| A future developer adds a new sensitive column without encrypting it | Medium (this is the single most common way real-world privacy incidents happen — an innocent, rushed schema change) | Severe | **CI/CD guardrail** (Part 7) that statically scans migrations and fails the build if a sensitive-looking column lacks encryption |
| Credential theft / account takeover | Low–Medium | Severe — full access to another person's mental health data | Delegated entirely to Clerk (Part 1), including secure session handling and optional MFA |

## 7. Data retention

| Data category | Retention period | Rationale |
|---|---|---|
| Mood entries, journal entries, medication reminders | Retained until account deletion, or until the user manually deletes an individual entry | The core value of the product is longitudinal (long-term) tracking; indefinite retention *while the account is active* is proportionate to that purpose |
| Consent ledger entries | Retained permanently, even after account deletion (in anonymized/pseudonymized form) | We must be able to prove historical consent was obtained, even for a since-deleted account, in case of a future regulatory inquiry |
| Account data (post-deletion request) | Deleted within 30 days across all systems | Aligns with GDPR's expectation of "undue delay," implemented concretely via the Part 6 DSAR workflow |

## 8. Open questions / risks accepted at this stage

*(Honesty here is the point — a DPIA that claims zero open risk is not
credible.)*

- We are relying on Clerk as a sub-processor for identity data. A full DPIA
  in a production system would include a review of Clerk's own security
  certifications and data processing agreement. Flagged for follow-up
  before real production launch.
- Encryption key management strategy is not yet decided (addressed in
  Part 4). Until implemented, no real user data should be entered into
  any deployed instance of this application.
- This document does not yet cover email/notification delivery (e.g., a
  future email reminder service would introduce a new sub-processor and
  new data flow) — to be added when that feature is built, if ever.

## 9. Revision history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-21 | Initial draft, written alongside Part 1 (project scaffolding + auth) |
```

### The Verification

There's no `curl` command or browser check for a Markdown file — the "test" here is a **review step**, which is itself the correct real-world practice: DPIAs are validated by human review, not automated tests. Confirm:

1. The file exists at `docs/DPIA.md` and renders correctly (open it in your editor's Markdown preview, or push to GitHub and view it there — GitHub renders Markdown tables automatically).
2. Every table is complete — no empty cells, no "TBD" left unresolved except the ones explicitly and honestly listed in Section 8.
3. Cross-check Section 3 (data inventory) against what you've actually built so far in this Part — at this point, only "Account identity" exists in the running app, and everything else is planned. That's correct and expected; the DPIA is intentionally written ahead of the schema so it *drives* Part 4, not the other way around.

Commit it:

```bash
git add docs/DPIA.md
git commit -m "docs: add initial DPIA covering planned data categories and legal basis"
```

---

## Part 1 Reference Section: Deep Dive — How Clerk Middleware Actually Works

*(This section is a standalone deep-dive for readers who want to understand the mechanics beneath Step 1.5. It is not required reading to proceed to Part 3 — feel free to skip ahead if you're eager to keep building.)*

**Where does middleware run, physically?** Next.js middleware executes in the **Edge Runtime** — a lightweight JavaScript environment that runs geographically close to the user, often before the request even reaches your main application server region. This is why middleware code has restrictions compared to normal server code: no direct filesystem access, and only a subset of Node.js APIs are available. This matters for us practically — it's the reason our `middleware.ts` only does an auth *check* (asking Clerk "is this request authenticated?") rather than anything heavier like a database query. Heavier logic belongs in Route Handlers or Server Actions, which run in the full Node.js runtime, not the Edge.

**What does `auth.protect()` actually do?** Internally, when a request arrives, Clerk's middleware reads a **session token** — a signed, tamper-proof piece of data (a JWT, or JSON Web Token) — typically stored in an HTTP-only cookie in the browser. "HTTP-only" means client-side JavaScript can never read this cookie directly, even via a malicious script injected through an XSS vulnerability; only the browser and server can exchange it. Clerk's middleware verifies the token's cryptographic signature (proving it wasn't forged) and checks it hasn't expired. If valid, `auth()` inside your app returns the user's ID and session claims. If `auth.protect()` finds no valid session, it throws a redirect response to your configured sign-in URL *before* your page component ever executes — meaning your dashboard's data-fetching code never even runs for an unauthenticated request. This is important: it's not "render the page, then hide the data" (which is fragile and has historically been the source of real-world data leaks), it's "never construct the response at all."

**Why `createRouteMatcher` instead of hardcoding `if` statements?** `createRouteMatcher(["/", "/sign-in(.*)", "/sign-up(.*)"])` compiles your route patterns into an efficient matcher function once, rather than re-parsing route strings on every request. More importantly for our purposes, it centralizes the "what's public" list into one array that's easy to audit — when you're reviewing this codebase for a security check, there's exactly one place to look to answer "what can an unauthenticated visitor reach?"

**What happens with API routes and Server Actions?** The same middleware matcher includes `"/(api|trpc)(.*)"`, meaning our future API routes (e.g., `/api/mood-entries`) are protected identically to pages — an unauthenticated `fetch()` to a protected API route gets rejected before any handler code runs, returning an authentication error rather than leaking data through an unprotected backend endpoint. This is a common real-world mistake: teams protect their *pages* carefully but forget their *API routes*, not realizing an attacker doesn't need to load the page at all if the underlying API is unprotected. Our single middleware file, matching both pages and APIs, closes that gap by construction.

---

## Part 1 Wrap-up: What we have, and why it matters going forward

At this point, GreyMatter Mindfulness Log is a real, running, authenticated application. Nothing about it is a toy — the authentication is production-grade (Clerk is used by real companies handling real sensitive data), the routing is secure-by-default, and we have a written DPIA that will act as our compass for every schema decision from here forward.

Critically, notice the order we did things in: **we wrote down what data we intend to collect and why, before we wrote a single line of schema.** This is the entire point of privacy-by-design — problems caught on paper in Section 6 of a DPIA are free to fix; problems caught after a data breach are not.

