# Part 3 — Next.js App Router Foundation: Building the Greymatter LMS Frontend

Following directly from Part 2, where we scaffolded the Greymatter LMS monorepo with strict boundaries between `apps/web`, `packages/*`, and `infra/*`, this part builds the first real, executable piece of the system: the Next.js 16 frontend itself [7].

**🎯 Goal of this lesson:** Stand up the App Router structure, wire in Clerk authentication, and render our first Tailwind-styled dashboard page — while respecting the strict rule that the frontend does **not** run AI, orchestrate workflows, or execute business logic [12].

**🧰 Prereqs:** Part 2 completed (monorepo exists). You'll need a free Clerk account for this lesson — sign up at clerk.com and grab your API keys before starting section 4 [7].

---

## 1. Architectural boundaries — a reminder

Before writing any code, remember the rule established in Part 2: `apps/web` handles UI rendering, Server Actions, authentication (via Clerk), event emission, and data fetching from Neon Postgres — but it does **not** run AI logic, define workflows, or contain worker logic [8]. Everything in this part respects that boundary.

---

## 2. Setting up route groups

Inside `apps/web`, scaffold the App Router structure with route groups separating authenticated and unauthenticated areas:

```bash
mkdir -p src/app/(auth)/sign-in/[[...sign-in]]
mkdir -p src/app/(auth)/sign-up/[[...sign-up]]
mkdir -p src/app/(dashboard)/courses
mkdir -p src/app/(dashboard)/assignments
```

---

## 3. Tailwind setup

Install and configure Tailwind so our dashboard pages have real styling from the start:

```bash
pnpm add -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

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

**✅ Checkpoint:** Visit `localhost:3000/courses` while signed out. You should be redirected to `/sign-in`. Sign up for a test account, and you should land back on `/courses` successfully [7].

---

## 5. A Server Action stub — deliberately thin

The frontend is more than a UI layer — it's an event emitter, a workflow initiator, and a domain gateway, but one that must stay **deliberately thin** [7]. So for now, we write a Server Action stub that stops short of any real business logic — no database write, no event emission yet:

```typescript
// src/app/(dashboard)/assignments/actions.ts
"use server";

export async function submitAssignment(assignmentId: string, courseId: string, content: string) {
  console.log("Submission received:", { assignmentId, courseId, content });
}
```

We'll make this real in two later steps: writing to Neon Postgres in Part 4, and emitting the `assignment.submitted` event to Inngest in Part 5 [5].

---

## 6. What's next

We now have a Next.js 16 frontend shell — route groups, Clerk auth, a Tailwind dashboard, and a Server Action stub that stops short of any business logic. In Part 4, we build the system of record: the Greymatter LMS database itself, using Neon Postgres and Drizzle ORM in place of Supabase [6].

**🩹 Common confusion at this stage:** "Why does the Server Action just `console.log` instead of doing something real?" — Because at this point in the series we don't have a database (Part 4) or an event bus (Part 5) to connect it to yet. Building it as an empty stub now, then filling it in piece by piece, is deliberate — it lets you see exactly which line of code corresponds to which architectural layer as each one comes online.

Ready? → **Part 4: Data Modelling — Designing the Greymatter LMS Database**
