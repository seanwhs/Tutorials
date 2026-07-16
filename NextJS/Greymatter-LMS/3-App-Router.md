# Part 3 — Next.js App Router Foundation: Building the Greymatter LMS Frontend 

In Part 2, we scaffolded the Greymatter LMS monorepo — a proper folder structure with strict boundaries between `apps/web`, `packages/*`, and `infra/*` [8]. Now it's time to build the first real, executable piece of the system: the Next.js 16 frontend itself [7].

**🎯 Goal of this lesson:** Stand up the App Router structure, wire in Clerk authentication, and render our first Tailwind-styled dashboard page — while respecting the strict rule that the frontend does **not** run AI, orchestrate workflows, or execute business logic [12].

**🧰 Prereqs:** Part 2 completed (monorepo exists). You'll need a free Clerk account for this lesson — sign up at clerk.com and grab your API keys before starting section 4 [7].

---

## 1. Architectural boundaries — a reminder before we write any code

Just like the original spec defines strict responsibilities for `apps/web` [8], remember the rule we set in Part 2: `apps/web` handles UI rendering, Server Actions, authentication via Clerk, event emission, and data fetching from Neon Postgres — but it does **not** run AI logic, define workflows, or contain worker logic [8]. Every section below respects that boundary. If you ever find yourself tempted to write grading logic inside a Server Action, that's the signal you've drifted outside this part's scope — that logic belongs in a worker, built starting in Part 7 [3].

---

## 2. Scaffolding the Next.js 16 app

Inside `apps/web` (created empty back in Part 2), scaffold a real Next.js 16 project using the App Router:

```bash
cd apps/web
pnpm create next-app@latest . --typescript --tailwind --app --src-dir --import-alias "@/*"
```

When prompted, confirm the **App Router** (not Pages Router) — this is required for every later part, since Server Actions and route groups both depend on it.

**✅ Checkpoint:** Run `pnpm dev` from `apps/web` and visit `localhost:3000`. You should see the default Next.js welcome page rendering with Tailwind already active. If Tailwind classes aren't applying, confirm `--tailwind` was included in the scaffold command above before continuing.

---

## 3. Setting up route groups

Now shape the App Router into the structure Greymatter LMS actually needs — separating unauthenticated auth pages from the authenticated dashboard:

```bash
mkdir -p src/app/\(auth\)/sign-in/\[\[...sign-in\]\]
mkdir -p src/app/\(auth\)/sign-up/\[\[...sign-up\]\]
mkdir -p src/app/\(dashboard\)/courses
mkdir -p src/app/\(dashboard\)/assignments
```

**✅ Checkpoint:** Run `tree -L 4 src/app` (or `ls -R src/app`) and confirm you see both `(auth)` and `(dashboard)` route groups, each with their respective subfolders. Route groups in parentheses don't affect the URL — `(dashboard)/courses` still resolves to `/courses`, which matters for the middleware we write next.

---

## 4. Authentication Layer — Clerk

The tutorial series is explicit and short on this point: "We use Clerk" [7]. Let's wire it in.

```bash
pnpm add @clerk/nextjs
```

Add your keys to `.env.local` — this is the first entry in what will become a growing list of environment variables accumulated across the series, all the way through deployment in Part 12 [9]:

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

**✅ Checkpoint:** Visit `localhost:3000/courses` while signed out. You should be redirected to `/sign-in`. Sign up for a test account, and you should land back on `/courses` successfully [7].

**🩹 Common confusion at this stage:** "The matcher regex in `middleware.ts` looks intimidating — do I need to understand it fully?" — Not fully, but the important part is that it excludes static assets (`_next`, files with extensions) while still matching every page and API route. If your CSS or images stop loading after adding middleware, this is almost always the cause — double check the matcher wasn't accidentally narrowed.

---

## 5. A first dashboard page, reading nothing real yet

Before wiring up any data, let's confirm the `(dashboard)` route group actually renders:

```tsx
// src/app/(dashboard)/courses/page.tsx
export default function CoursesPage() {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold">My Courses</h1>
      <p className="text-slate-500">Course data will load here starting in Part 4.</p>
    </div>
  );
}
```

**✅ Checkpoint:** Signed in, visit `/courses` again — you should now see "My Courses" rendered with Tailwind styling, instead of the default Next.js page.

---

## 6. A Server Action stub — deliberately thin

The frontend is more than a UI layer — it's an event emitter, a workflow initiator, and a domain gateway, but one that must stay **deliberately thin** [7]. So for now, we write a Server Action stub that stops short of any real business logic — no database write, no event emission yet:

```typescript
// src/app/(dashboard)/assignments/actions.ts
"use server";

export async function submitAssignment(assignmentId: string, courseId: string, content: string) {
  console.log("Submission received:", { assignmentId, courseId, content });
}
```

We'll make this real in two later steps: writing to Neon Postgres in Part 4 [6], and emitting the `assignment.submitted` event to Inngest in Part 5 [5].

**✅ Checkpoint:** Wire this stub to a simple `<form action={submitAssignment}>` on the assignments page (any minimal form works), submit it, and confirm you see `Submission received: {...}` logged in your terminal — not the browser console, since this runs on the server.

---

## 7. What's next

We now have a Next.js 16 frontend shell — route groups, Clerk auth, a Tailwind dashboard, and a Server Action stub that stops short of any business logic. In Part 4, we build the system of record: the Greymatter LMS database itself, using Neon Postgres and Drizzle ORM in place of Supabase [6].

**🩹 Common confusion at this stage:** "Why does the Server Action just `console.log` instead of doing something real?" — Because at this point in the series we don't have a database (Part 4 [6]) or an event bus (Part 5 [5]) to connect it to yet. Building it as an empty stub now, then filling it in piece by piece, is deliberate — it lets you see exactly which line of code corresponds to which architectural layer as each one comes online, matching the boundary rules from Part 1 [12].

Ready? → **Part 4: Data Modelling — Designing the Greymatter LMS Database**
