# Part 3 — Next.js App Router Foundation: Building the Greymatter LMS Frontend 

In Part 2, we scaffolded a real, running Next.js 16 app with `create-next-app`, then grew the rest of the monorepo — `packages/*` and `infra/*` — around it, giving us a proper folder structure with strict boundaries between `apps/web`, shared packages, and infrastructure code [8]. Now it's time to build out that already-running app into the first real, executable piece of the system: the Greymatter LMS frontend itself [7].

**🎯 Goal of this lesson:** Stand up the App Router structure, wire in Clerk authentication, and render our first Tailwind-styled dashboard page — while respecting the strict rule that the frontend does **not** run AI, orchestrate workflows, or execute business logic [12].

**🧰 Prereqs:** Part 2 completed (monorepo exists, `apps/web` runs on `localhost:3000`). You'll need a free Clerk account for this lesson — sign up at clerk.com and grab your API keys before starting section 4 [7].

---

## 1. Architectural boundaries — a reminder before we write any code

Just like the original spec defines strict responsibilities for `apps/web` [8], remember the rule we set in Part 2: `apps/web` handles UI rendering, Server Actions, authentication via Clerk, event emission, and data fetching from Neon Postgres — but it does **not** run AI logic, define workflows, or contain worker logic [8]. Every section below respects that boundary. If you ever find yourself tempted to write grading logic inside a Server Action, that's the signal you've drifted outside this part's scope — that logic belongs in a worker, built starting in Part 7 [3].

This restriction can feel counterintuitive at first — it would genuinely be *easier* to just call an OpenAI API directly from a Server Action right now. Resisting that urge here is exactly what keeps Part 5's Orchestration Layer, Part 6's Registry Layer, and Part 7's Execution Layer meaningful rather than redundant [5][4][3]. Every "why doesn't this just call the AI directly" moment in this part has the same answer: that call belongs several layers downstream, not here.

---

## 2. Confirming what Part 2 already gave us

Since Part 2 already ran `create-next-app` inside `apps/web` — complete with TypeScript, Tailwind, the App Router, a `src/` directory, and the `@/*` import alias — this part doesn't scaffold anything new from scratch. Instead, open `apps/web` and confirm the baseline is intact:

```bash
cd apps/web
npm run dev
```

**✅ Checkpoint:** Visit `localhost:3000` and confirm the default Next.js welcome page still renders. Everything in this part modifies this already-running project rather than creating a new one.

---

## 3. Structuring the App Router with route groups

Route groups let us organize the app by *audience* (public marketing pages vs. authenticated dashboard) without that grouping affecting the URL itself — folders wrapped in parentheses are invisible to the actual route path. Inside `apps/web/src/app`, create:

```text
app/
  (marketing)/
    page.tsx           # public landing page — route: /
  (dashboard)/
    layout.tsx          # authenticated shell — wraps all dashboard routes
    dashboard/
      page.tsx           # route: /dashboard
    courses/
      page.tsx           # route: /courses
  layout.tsx             # root layout — wraps everything
```

The `(marketing)` and `(dashboard)` folder names never appear in the URL — `(dashboard)/dashboard/page.tsx` still resolves to `/dashboard`. This is exactly the tool for our purpose: keeping "logged-out" and "logged-in" concerns cleanly separated in the file tree while sharing one deployment.

---

## 4. Wiring in Clerk authentication

Install Clerk's Next.js package from inside `apps/web`:

```bash
npm install @clerk/nextjs
```

Add your Clerk keys to `apps/web/.env.local`:

```text
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
```

Wrap the root layout in `ClerkProvider`, so every route — marketing or dashboard — has access to auth state:

```tsx
// app/layout.tsx
import { ClerkProvider } from "@clerk/nextjs";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

Then protect the dashboard route group specifically, so marketing pages stay public while `/dashboard` and `/courses` require sign-in:

```tsx
// app/(dashboard)/layout.tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { userId, orgId } = await auth();
  if (!userId) redirect("/sign-in");

  return <div className="min-h-screen bg-slate-50">{children}</div>;
}
```

Notice `orgId` is pulled out here too, not just `userId` — Greymatter LMS is multi-tenant (multiple schools/organizations sharing the same deployment), and `orgId` is what Part 4's database schema uses to keep one organization's courses and submissions invisible to another [6].

**✅ Checkpoint:** Visit `/dashboard` while signed out and confirm you're redirected to `/sign-in`. Sign in, then confirm `/dashboard` renders and `/` (marketing) still loads without requiring auth.

---

## 5. Building the first Tailwind dashboard page

Since Part 2's `create-next-app` command already included the `--tailwind` flag, no additional setup is needed — just write the page:

```tsx
// app/(dashboard)/dashboard/page.tsx
import { auth } from "@clerk/nextjs/server";

export default async function DashboardPage() {
  const { userId, orgId } = await auth();

  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold text-slate-900">Welcome back</h1>
      <p className="text-slate-600 mt-2">
        Signed in as {userId}, organization {orgId ?? "none"}
      </p>
      <div className="mt-6 rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <p className="text-slate-500">No courses yet — Part 4 gives us somewhere to store them.</p>
      </div>
    </main>
  );
}
```

**✅ Checkpoint:** Confirm `/dashboard` shows your real Clerk `userId` and `orgId`, styled with Tailwind, not the default Next.js boilerplate.

---

## 6. A Server Action stub — and why it stays a stub

Add a Server Action that will eventually kick off the entire event-driven pipeline, but for now, deliberately does nothing more than log:

```tsx
// app/(dashboard)/courses/actions.ts
"use server";

import { auth } from "@clerk/nextjs/server";

export async function submitAssignment(submissionId: string) {
  const { userId, orgId } = await auth();
  if (!userId || !orgId) throw new Error("Unauthorized");

  console.log("Assignment submitted:", { submissionId, userId, orgId });
  // Part 4 gives us somewhere to store this.
  // Part 5 makes this actually emit a real event.
}
```

This stub is intentionally incomplete — no database write, no event emission, just an auth check and a `console.log`. That's not a placeholder we forgot to finish; it's a deliberate teaching device. Right now, the only layers that exist are Client + Application and Auth. There's nowhere real to persist this submission (Part 4 [6]) and nothing that turns it into a workflow (Part 5 [5]) — so writing more here would mean either faking a database call or, worse, sneaking business logic into the Application Layer, exactly the boundary violation section 1 warned against.

**✅ Checkpoint:** Wire a simple button in `courses/page.tsx` that calls `submitAssignment("test-123")`, click it while signed in, and confirm the console log appears in your terminal with your real `userId` and `orgId` attached.

---

## 7. What's next

We now have a Next.js 16 frontend shell — route groups, Clerk auth, a Tailwind dashboard, and a Server Action stub that stops short of any business logic. In Part 4, we build the system of record: the Greymatter LMS database itself, using Neon Postgres and Drizzle ORM in place of Supabase [6].

**🩹 Common confusion at this stage:** "Why does the Server Action just `console.log` instead of doing something real?" — Because at this point in the series we don't have a database (Part 4 [6]) or an event bus (Part 5 [5]) to connect it to yet. Building it as an empty stub now, then filling it in piece by piece, is deliberate — it lets you see exactly which line of code corresponds to which architectural layer as each one comes online, matching the boundary rules from Part 1 [12].

Ready? → **Part 4: Data Modelling — Designing the Greymatter LMS Database**
