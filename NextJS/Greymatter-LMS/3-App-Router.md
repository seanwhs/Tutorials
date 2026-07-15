# Part 3 — Next.js App Router Foundation: Building the Greymatter LMS Frontend

In Part 2, we scaffolded the Greymatter LMS monorepo — a proper folder structure with strict boundaries between `apps/web`, `packages/*`, and `infra/*`. Now it's time to build the first real, executable piece of the system: the Next.js 16 frontend itself.

**🎯 Goal of this lesson:** Stand up the App Router structure, wire in Clerk authentication, and render our first Tailwind-styled dashboard page — while respecting the strict rule that the frontend does **not** run AI, orchestrate workflows, or execute business logic [12].

**🧰 Prereqs:** Part 2 completed (monorepo exists). You'll need a free Clerk account for this lesson — sign up at clerk.com and grab your API keys before starting section 4.

---

## 1. What the frontend is actually responsible for

Before writing code, let's restate the boundary from Part 1 and Part 2, because it's the single most important rule in this lesson. The original spec is blunt about it — the Next.js app's responsibilities are:

* UI rendering
* server actions
* authentication (via Clerk)
* event emission
* data fetching from the database

And explicitly, it does **NOT**:
* run AI logic
* define workflows
* contain worker logic [8]

Everything we build in this part exists to support those five responsibilities — nothing more.

---

## 2. Scaffolding the Next.js 16 app

Inside the monorepo, initialize the actual app:

```bash
cd apps/web
pnpm create next-app@latest . --typescript --tailwind --app --src-dir --import-alias "@/*"
```

When prompted, confirm you want the App Router (not Pages Router) — this matches the architecture described in the original tutorial series [7].

**✅ Checkpoint:** Run `pnpm dev` from `apps/web` and visit `localhost:3000`. You should see the default Next.js welcome page with Tailwind already working.

---

## 3. Route Groups Strategy

The original tutorial establishes a route groups strategy for organizing the App Router [7]. For Greymatter LMS, we'll use three route groups that map directly to who can access them:

```bash
mkdir -p src/app/\(auth\)/sign-in src/app/\(auth\)/sign-up
mkdir -p src/app/\(dashboard\)/courses src/app/\(dashboard\)/assignments
mkdir -p src/app/\(marketing\)
```

```text
src/app/
  (marketing)/          # public landing page — no auth required
    page.tsx
  (auth)/               # sign-in / sign-up flows
    sign-in/[[...sign-in]]/page.tsx
    sign-up/[[...sign-up]]/page.tsx
  (dashboard)/           # authenticated LMS core
    courses/page.tsx
    assignments/page.tsx
    layout.tsx
```

Route groups (the parentheses folders) don't affect the URL — `(dashboard)/courses` still resolves to `/courses`. They exist purely to let us apply different layouts and middleware rules to different sections of the app.

---

## 4. Authentication Layer — Clerk

The tutorial series is explicit and short on this point: "We use Clerk" [7]. Let's wire it in.

```bash
pnpm add @clerk/nextjs
```

Add your keys to `.env.local`:

```bash
# apps/web/.env.local
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxx
CLERK_SECRET_KEY=sk_test_xxxxxxxx
```

Wrap the app in the provider:

```tsx
// src/app/layout.tsx
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

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

Protect the `(dashboard)` route group with middleware:

```typescript
// src/middleware.ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher(["/courses(.*)", "/assignments(.*)"]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: ["/((?!_next|.*\\..*).*)", "/(api|trpc)(.*)"],
};
```

Build the sign-in page:

```tsx
// src/app/(auth)/sign-in/[[...sign-in]]/page.tsx
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50">
      <SignIn />
    </div>
  );
}
```

**✅ Checkpoint:** Visit `localhost:3000/courses` while signed out. You should be redirected to `/sign-in`. Sign up for a test account, and you should land back on `/courses` successfully.

---

## 5. Building the dashboard layout (Tailwind)

```tsx
// src/app/(dashboard)/layout.tsx
import { UserButton } from "@clerk/nextjs";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-slate-50">
      <header className="flex items-center justify-between border-b bg-white px-6 py-4">
        <h1 className="text-lg font-semibold text-slate-800">Greymatter LMS</h1>
        <UserButton afterSignOutUrl="/" />
      </header>
      <main className="mx-auto max-w-5xl p-6">{children}</main>
    </div>
  );
}
```

```tsx
// src/app/(dashboard)/courses/page.tsx
export default function CoursesPage() {
  return (
    <div>
      <h2 className="mb-4 text-2xl font-bold text-slate-900">My Courses</h2>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-lg border bg-white p-4 shadow-sm">
          <h3 className="font-semibold">Intro to Event-Driven Systems</h3>
          <p className="text-sm text-slate-500">4 assignments</p>
        </div>
      </div>
    </div>
  );
}
```

**✅ Checkpoint:** Visit `/courses` while signed in. You should see the Greymatter LMS header with your Clerk user avatar, and a single course card styled with Tailwind.

---

## 6. Event emission layer — the frontend's real job

Here's where we tie this back to Part 0 and Part 1. The frontend's *only* job related to workflows is to **emit an event** — never to execute logic itself. Let's preview the event emission layer we'll fully wire up once Inngest is set up in Part 5. For now, create the Server Action stub:

```typescript
// src/app/(dashboard)/assignments/actions.ts
"use server";

import { auth } from "@clerk/nextjs/server";

export async function submitAssignment(assignmentId: string, content: string) {
  const { userId } = await auth();
  if (!userId) throw new Error("Unauthorized");

  // In Part 5, this becomes: await inngest.send({ name: "assignment.submitted", ... })
  console.log("Would emit assignment.submitted event for:", { assignmentId, userId });

  return { success: true };
}
```

Notice what this function does **not** do: it doesn't grade anything, doesn't call an AI model, and doesn't define a workflow. That logic lives entirely in the Orchestration and Execution layers we mapped out in Part 1 — the frontend's job stops at "authenticate, then emit."

**✅ Checkpoint:** Add a simple form to `assignments/page.tsx` that calls `submitAssignment`, submit it, and confirm the console log appears in your terminal (not the browser console — Server Actions run server-side).

---

## 7. What's next

We now have a working Next.js 16 app with route groups, Clerk authentication, a Tailwind-styled dashboard, and a Server Action stub ready to emit events. In Part 4, we build the actual system of record — the database schema — using Neon Postgres, since as the original tutorial puts it: "If events are the nervous system, the database is the memory" [6]. We'll also confront directly what changes when moving from Supabase's built-in RLS to Neon + application-level checks.

**🩹 Common confusion at this stage:** "Why does `submitAssignment` check `auth()` again if middleware already protects the route?" — Middleware protects *pages*, but Server Actions can be called directly (e.g., from client-side JS), so they must **always** re-verify identity themselves. This is the first of several defense-in-depth patterns we'll expand on heavily in Part 9 (Hardening) [1].

Ready? → **Part 4: Data Modelling for Greymatter LMS**
