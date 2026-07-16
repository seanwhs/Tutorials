# Part 2: Authentication & Core Navigation Shell

Picking up exactly where Part 1 left off: you have a Next.js 16 + Tailwind workspace, a local Sanity Studio with `course`/`chapter`/`lesson` schemas, and a Neon Postgres database wired to Prisma with `User`, `Enrollment`, and `Progress` models. In Part 2 we connect a real human to that system — authentication — and give them a place to stand once logged in — the dashboard shell.

## 2.0 Why Authentication Comes Before "Building the Dashboard UI"

**The Concept:** Every student request first passes through **Next.js Edge Middleware** for a session check, *before* it ever reaches a page component [1]. Think of middleware like the bouncer at a club entrance: it checks your wristband (session token) before you're allowed anywhere inside, rather than each room individually checking IDs. If we built the dashboard UI first with no bouncer at the door, anyone — logged in or not — could load `/dashboard` and see private course progress. So authentication has to be the first gate, architecturally, not an afterthought.

We're using **Clerk**, a hosted authentication service, because it manages the security-critical parts (password hashing, session tokens, email verification) so we don't have to write or audit that code ourselves — similar to using a bank's vault instead of building your own safe.

---

## Step 1: Create a Clerk Application and Install the SDK

**The Target:** A Clerk application configured on their dashboard, and `@clerk/nextjs` installed in our project.

**The Concept:** Clerk needs to know about *your* project before your project can know about Clerk. You create an "Application" on Clerk's dashboard (their side), which hands you a **publishable key** (safe to expose in browser code, like a storefront address) and a **secret key** (must never leave the server, like a vault combination).

**The Implementation:**

1. Go to `https://dashboard.clerk.com` and create a free account.
2. Click **Create Application**, name it `greymatter-lms`, and enable **Email** as a sign-in method.
3. On the **API Keys** page, copy your `Publishable key` and `Secret key`.
4. Install the SDK:

```bash
npm install @clerk/nextjs
```

5. Update your `.env` file (created in Part 0) with real values:

#### `.env`
```bash
# ── Clerk (Authentication) ──────────────────────────────────────────────────
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_xxxxxxxxxxxxxxxxxxxxxxxx"
CLERK_SECRET_KEY="sk_test_xxxxxxxxxxxxxxxxxxxxxxxx"
NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"

# Required later in this Part for the role-syncing webhook
CLERK_WEBHOOK_SECRET=""
```

Leave `CLERK_WEBHOOK_SECRET` empty for now — we'll fill it in during Step 5.

**The Verification:**

```bash
cat .env
```

Confirm `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` and `CLERK_SECRET_KEY` show real values starting with `pk_test_` and `sk_test_`. Then run:

```bash
git status
```

`.env` should **not** appear as trackable — if it does, fix `.gitignore` before proceeding.

---

## Step 2: Wrap the App in `<ClerkProvider>`

**The Target:** Making Clerk's authentication context available to every page in the app.

**The Concept:** `<ClerkProvider>` is like the electrical wiring running through the walls of a house — invisible itself, but every outlet (every component needing "is someone logged in?") depends on it existing. It must wrap the entire app at the root layout level.

**The Implementation:**

#### `app/layout.tsx`
```tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export const metadata: Metadata = {
  title: "Greymatter LMS",
  description: "A hybrid-architecture Learning Management System.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body className="antialiased">{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

**The Verification:**

```bash
npm run dev
```

Visit `http://localhost:3000` — the page should render exactly as it did at the end of Part 1. If you see a Clerk configuration error, double-check your `.env` keys and confirm you restarted the dev server after editing `.env` (Next.js only reads env files on startup).

---

## Step 3: Create Sign-In and Sign-Up Pages

**The Target:** Dedicated `/sign-in` and `/sign-up` routes using Clerk's prebuilt UI components.

**The Concept:** Rather than hand-building a login form (fields, "forgot password" flow, error states), Clerk ships pre-built, themeable components — like using a manufactured door lock instead of forging your own. It's tested and secure; it just needs installing in the right spot.

**The Implementation:**

#### `app/sign-in/[[...sign-in]]/page.tsx`
```tsx
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-brand-50">
      <SignIn />
    </main>
  );
}
```

#### `app/sign-up/[[...sign-up]]/page.tsx`
```tsx
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-brand-50">
      <SignUp />
    </main>
  );
}
```

The `[[...sign-in]]` folder name is a Next.js **optional catch-all route** — the double brackets mean "match `/sign-in` itself, plus any sub-paths like `/sign-in/factor-one`," which Clerk needs internally for multi-step flows like two-factor verification.

**The Verification:** Visit `http://localhost:3000/sign-in` and `http://localhost:3000/sign-up`. You should see Clerk's styled forms. Create a real test account through sign-up — confirm it appears in the Clerk Dashboard's **Users** tab.

---

## Step 4: Protect Routes with Edge Middleware

**The Target:** A `middleware.ts` file that checks a visitor's session *before* any dashboard page loads — the "bouncer at the door" step where Edge Middleware performs the Clerk session check as the very first stage of the request lifecycle [1].

**The Concept:** Middleware runs at the edge — close to the user, before your main application code starts — and intercepts every matching request. This is the earliest point to say "you don't have a valid session, go to `/sign-in`," which is far more secure than checking auth status inside individual page components (easy to forget one).

**The Implementation:**

#### `middleware.ts` (project root)
```typescript
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

// Define which routes require a logged-in session.
// Everything under /dashboard is private; marketing/auth pages stay public.
const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    // Throws a redirect to the sign-in page if no valid session exists
    await auth.protect();
  }
});

export const config = {
  matcher: [
    // Skip Next.js internals and static files, unless found in search params
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    // Always run for API routes
    "/(api|trpc)(.*)",
  ],
};
```

**The Verification:** With the dev server running, open an incognito window and navigate to `http://localhost:3000/dashboard`. You should be redirected to `/sign-in`. Now sign in with your test account — you should land back on `/dashboard`, which will 404 for now (expected, since we haven't built that page yet — a 404 *after* passing the auth check confirms middleware is working).

---

## Step 5: Sync Clerk Users into Neon via Webhook (Role Assignment)

**The Target:** A webhook endpoint listening for Clerk's `user.created` event, writing a corresponding `User` row into Neon via Prisma — defaulting new signups to the `STUDENT` role.

**The Concept:** Clerk owns *authentication* (proving who someone is), but Greymatter's `Progress` and `Enrollment` tables need a `User` row to attach to. Rather than querying Clerk's API every time we need a user's role, we keep a lightweight mirrored copy in our own database — like a company keeping its own badge-swipe records instead of calling a government registry every time it needs to verify identity. Webhooks are how Clerk notifies *us* the moment a new user signs up.

**The Implementation:**

```bash
npm install svix
```

#### `app/api/webhooks/clerk/route.ts`

```typescript
import { Webhook } from "svix";
import { headers } from "next/headers";
import { PrismaClient } from "@prisma/client";
import type { WebhookEvent } from "@clerk/nextjs/server";

const prisma = new PrismaClient();

export async function POST(req: Request) {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET;

  if (!WEBHOOK_SECRET) {
    throw new Error("Missing CLERK_WEBHOOK_SECRET in environment variables.");
  }

  // Clerk signs every webhook request with these three headers.
  // We must verify them to prove the request truly came from Clerk,
  // not an attacker pretending to be Clerk.
  const headerPayload = await headers();
  const svix_id = headerPayload.get("svix-id");
  const svix_timestamp = headerPayload.get("svix-timestamp");
  const svix_signature = headerPayload.get("svix-signature");

  if (!svix_id || !svix_timestamp || !svix_signature) {
    return new Response("Missing required svix headers.", { status: 400 });
  }

  const payload = await req.json();
  const body = JSON.stringify(payload);

  const wh = new Webhook(WEBHOOK_SECRET);
  let evt: WebhookEvent;

  try {
    evt = wh.verify(body, {
      "svix-id": svix_id,
      "svix-timestamp": svix_timestamp,
      "svix-signature": svix_signature,
    }) as WebhookEvent;
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    return new Response("Invalid webhook signature.", { status: 400 });
  }

  // We only care about new user creation for this endpoint.
  if (evt.type === "user.created") {
    const { id, email_addresses } = evt.data;
    const primaryEmail = email_addresses[0]?.email_address;

    if (!primaryEmail) {
      return new Response("User has no email address on record.", { status: 400 });
    }

    // Mirror the Clerk user into our own Neon database,
    // defaulting to STUDENT — instructors are promoted manually later.
    // This matches the User model's Role enum exactly (STUDENT, INSTRUCTOR, ADMIN) [1].
    await prisma.user.upsert({
      where: { id },
      update: { email: primaryEmail },
      create: {
        id,
        email: primaryEmail,
        role: "STUDENT",
      },
    });
  }

  return new Response("Webhook processed successfully.", { status: 200 });
}
```

Notice this endpoint reuses the exact `User` model shape from your Prisma schema — `id`, `email`, `role` — which was defined with `role Role @default(STUDENT)` against the `enum Role { STUDENT INSTRUCTOR ADMIN }` [1]. This webhook is the first moment that model receives real, live data.

**The Verification (local testing):**

Since Clerk needs a public URL to deliver webhooks to, and your app runs on `localhost`, use a tunnel tool such as `ngrok`:

```bash
ngrok http 3000
```

Copy the `https://xxxx.ngrok.io` URL. In the Clerk Dashboard, go to **Webhooks → Add Endpoint**, set the URL to:

```
https://xxxx.ngrok.io/api/webhooks/clerk
```

Subscribe to the `user.created` event. Clerk will show a **Signing Secret** — copy it into `.env`:

```bash
CLERK_WEBHOOK_SECRET="whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

Restart your dev server so the new env var is picked up:

```bash
# Ctrl+C to stop, then:
npm run dev
```

Now trigger the event — either click **Send test event** in the Clerk Dashboard's Webhooks page, or sign up a brand-new test user via `/sign-up`. Watch your terminal for errors, then confirm the row landed in Neon:

```bash
npx prisma studio
```

Open `http://localhost:5555`, click the `User` table, and confirm a new row exists with:
- `id` matching the Clerk user ID (e.g., `user_2abc...`)
- `email` matching your signup address
- `role` set to `STUDENT`

If the row is missing, check for an `"Invalid webhook signature"` error in your terminal — this almost always means `CLERK_WEBHOOK_SECRET` doesn't match the Clerk Dashboard value, or the server wasn't restarted.

Commit this checkpoint:

```bash
git add .
git commit -m "feat: add Clerk auth, middleware protection, and user-sync webhook"
```

---

## Step 6: Build the Collapsible Sidebar Dashboard Shell

**The Target:** A responsive dashboard layout at `/dashboard` with a collapsible sidebar that will eventually list courses, chapters, and lessons.

**The Concept:** A **layout** in Next.js's App Router is a shared UI wrapper that persists across page navigations within a route segment — like a picture frame that stays the same while you swap the photo inside it. We use a Client Component for the sidebar's collapse/expand toggle because that interactivity (a click event, local open/closed state) can only run in the browser, whereas the surrounding page content can remain a Server Component for fast initial rendering.

**The Implementation:**

First, create a small reusable Client Component to hold the toggle state:

#### `app/dashboard/_components/sidebar.tsx`
```tsx
"use client";

import { useState } from "react";
import Link from "next/link";
import { UserButton } from "@clerk/nextjs";

export function Sidebar({ children }: { children: React.ReactNode }) {
  // Local UI state — whether the sidebar is expanded or collapsed.
  // This lives only in the browser, so it must be a Client Component.
  const [isOpen, setIsOpen] = useState(true);

  return (
    <div className="flex min-h-screen">
      <aside
        className={`flex flex-col border-r border-brand-100 bg-white transition-all duration-200 ${
          isOpen ? "w-72" : "w-16"
        }`}
      >
        <div className="flex items-center justify-between p-4 border-b border-brand-100">
          {isOpen && (
            <Link href="/dashboard" className="font-bold text-brand-900">
              Greymatter
            </Link>
          )}
          <button
            onClick={() => setIsOpen(!isOpen)}
            aria-label="Toggle sidebar"
            className="rounded-md p-1.5 text-brand-600 hover:bg-brand-50"
          >
            {isOpen ? "«" : "»"}
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto p-2">{isOpen && children}</nav>

        <div className="border-t border-brand-100 p-4 flex items-center gap-2">
          <UserButton afterSignOutUrl="/sign-in" />
          {isOpen && <span className="text-sm text-brand-600">My Account</span>}
        </div>
      </aside>
    </div>
  );
}
```

Now wire it into a dashboard layout that wraps every page under `/dashboard`:

#### `app/dashboard/layout.tsx`
```tsx
import { Sidebar } from "./_components/sidebar";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex">
      <Sidebar>
        <p className="px-2 py-1.5 text-xs font-semibold uppercase text-brand-600">
          My Courses
        </p>
        {/* Course/chapter/lesson links will be rendered here in the next step */}
      </Sidebar>
      <main className="flex-1 bg-brand-50 p-8">{children}</main>
    </div>
  );
}
```

#### `app/dashboard/page.tsx`
```tsx
import { currentUser } from "@clerk/nextjs/server";

export default async function DashboardHomePage() {
  const user = await currentUser();

  return (
    <div>
      <h1 className="text-2xl font-bold text-brand-900">
        Welcome back{user?.firstName ? `, ${user.firstName}` : ""} 👋
      </h1>
      <p className="mt-2 text-brand-600">
        Your enrolled courses will appear in the sidebar once we connect
        Sanity content in the next step.
      </p>
    </div>
  );
}
```

**The Verification:** Sign in through `/sign-in`, then navigate to `http://localhost:3000/dashboard`. You should see:
- A left sidebar (default expanded, ~288px wide) with "Greymatter" branding, a "My Courses" label, and a user avatar/button at the bottom
- Clicking the `«`/`»` toggle button collapses the sidebar down to a narrow 64px icon rail and back
- The main content area shows a personalized welcome message using your Clerk first name

If `user.firstName` renders as `undefined` or the greeting looks wrong, check that you filled in a first name during sign-up, or simply confirm the fallback text ("Welcome back 👋") displays correctly instead.

Commit:

```bash
git add .
git commit -m "feat: build collapsible sidebar dashboard shell"
```

---

## Step 7: Fetch and Render Static Course Layouts from Sanity CDN

**The Target:** Replace the placeholder "My Courses" label with real course, chapter, and lesson data fetched from Sanity — rendered directly into the sidebar as navigable links.

**The Concept:** This is "Parallel Fetch A" from the architecture diagram — content coming from Sanity's CDN rather than Neon. We query Sanity using **GROQ** (Sanity's query language, similar in spirit to SQL but built specifically for JSON document trees) and fetch it from the CDN endpoint, which serves cached, fast responses since course structure rarely changes.

**The Implementation:**

Install the Sanity client if you haven't already from Part 1:

```bash
npm install @sanity/client
```

Create a typed query helper:

#### `lib/sanity/queries.ts`
```typescript
import { client } from "./client";

// Shape returned by our GROQ query below — kept in sync manually with
// the course/chapter/lesson schemas defined in the Studio during Part 1.
export interface SidebarLesson {
  _id: string;
  title: string;
  slug: string;
}

export interface SidebarChapter {
  _id: string;
  title: string;
  lessons: SidebarLesson[];
}

export interface SidebarCourse {
  _id: string;
  title: string;
  slug: string;
  chapters: SidebarChapter[];
}

// GROQ query: fetch every course, and for each one, resolve its
// referenced chapters and lessons in a single round trip.
const COURSE_NAV_QUERY = `*[_type == "course"] {
  _id,
  title,
  "slug": slug.current,
  "chapters": chapters[]-> {
    _id,
    title,
    "lessons": lessons[]-> {
      _id,
      title,
      "slug": slug.current
    }
  }
}`;

export async function getCourseNavigation(): Promise<SidebarCourse[]> {
  // useCdn: true serves this from Sanity's fast, cached edge network —
  // appropriate here since course structure changes rarely.
  return client.fetch(COURSE_NAV_QUERY, {}, { cache: "force-cache" });
}
```

Now that `getCourseNavigation()` is defined, let's wire it into the sidebar so real course/chapter/lesson links render instead of the placeholder text.

**The Concept:** The dashboard layout is a **Server Component** by default (no `"use client"` directive), which means it can directly `await` data — including calling our Sanity fetch function — during server-side rendering, before any HTML is sent to the browser. This is the "Combined Server Render" step from the architecture diagram: content resolved on the server, then handed down as props into the interactive `Sidebar` Client Component we built in Step 6.

**The Implementation:**

#### `app/dashboard/layout.tsx` (updated)
```tsx
import { Sidebar } from "./_components/sidebar";
import { getCourseNavigation } from "@/lib/sanity/queries";
import Link from "next/link";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Server-side fetch — runs before any HTML is sent to the browser.
  // This is "Parallel Fetch A" from the architecture diagram: Sanity content.
  const courses = await getCourseNavigation();

  return (
    <div className="flex">
      <Sidebar>
        <p className="px-2 py-1.5 text-xs font-semibold uppercase text-brand-600">
          My Courses
        </p>
        <div className="mt-2 space-y-4">
          {courses.map((course) => (
            <div key={course._id}>
              <Link
                href={`/dashboard/courses/${course.slug}`}
                className="block rounded-md px-2 py-1.5 font-medium text-brand-900 hover:bg-brand-50"
              >
                {course.title}
              </Link>
              <div className="ml-3 mt-1 space-y-1 border-l border-brand-100 pl-3">
                {course.chapters.map((chapter) => (
                  <div key={chapter._id}>
                    <p className="px-2 py-1 text-sm font-semibold text-brand-600">
                      {chapter.title}
                    </p>
                    <div className="space-y-0.5">
                      {chapter.lessons.map((lesson) => (
                        <Link
                          key={lesson._id}
                          href={`/dashboard/courses/${course.slug}/lessons/${lesson.slug}`}
                          className="block rounded-md px-2 py-1 text-sm text-brand-600 hover:bg-brand-50 hover:text-brand-900"
                        >
                          {lesson.title}
                        </Link>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </Sidebar>
      <main className="flex-1 bg-brand-50 p-8">{children}</main>
    </div>
  );
}
```

Notice this component is `async` — that's what allows the direct `await getCourseNavigation()` call. This only works because it's a Server Component; you cannot make a Client Component's function body `async` in this way.

**The Verification:**

1. Make sure your local Sanity Studio (from Part 1) has at least one `course` document with a linked `chapter`, which itself has at least one linked `lesson`. If you haven't created test content yet, open your Studio (`npm run dev` inside the `studio/` folder, or wherever you configured it in Part 1) and add:
   - One `course` document, titled e.g. "Intro to SQL"
   - One `chapter` document titled "Getting Started", referenced from that course
   - One `lesson` document titled "What is a Database?", referenced from that chapter
   - Publish all three documents (draft-only content won't appear via the CDN query)

2. Restart your Next.js dev server and visit `http://localhost:3000/dashboard`:

```bash
npm run dev
```

3. You should now see, in the sidebar:
   - "Intro to SQL" as a bold clickable course title
   - Indented beneath it, "Getting Started" as a chapter label
   - Indented further, "What is a Database?" as a clickable lesson link

4. Click the lesson link — it will currently 404, since we haven't built the actual lesson page route yet. That's expected; it confirms the `href` is being generated correctly from real Sanity slugs.

If the sidebar shows no courses at all, double-check:
- Your `NEXT_PUBLIC_SANITY_PROJECT_ID` and `NEXT_PUBLIC_SANITY_DATASET` in `.env` match your actual Sanity project
- The documents are **published**, not left as unpublished drafts (the CDN-cached `force-cache` fetch only serves published content)
- Your GROQ query's `_type == "course"` matches the exact schema type name you defined in Part 1

Once confirmed, commit this final checkpoint for Part 2:

```bash
git add .
git commit -m "feat: fetch and render course/chapter/lesson navigation from Sanity CDN"
```

---

## Closing Out Part 2

### What You Have Right Now
- A Clerk application fully wired into Next.js via `<ClerkProvider>`
- Working `/sign-in` and `/sign-up` pages using Clerk's prebuilt components
- Edge Middleware protecting every `/dashboard` route, redirecting unauthenticated visitors
- A webhook endpoint that mirrors every new Clerk signup into your Neon `User` table via Prisma, defaulting to the `STUDENT` role
- A responsive, collapsible sidebar dashboard shell
- Real course/chapter/lesson navigation rendered server-side from Sanity's CDN

### What's Next
**Part 3: The React-Only Plugin Registry & Component Contract** — you'll define a typed `@greymatter/plugin-sdk` contract, build a dynamic client-side component registry using `next/dynamic` for lazy loading, and create a working "SQL Sandbox" interactive lesson plugin that invokes a completion callback — setting up the exact hand-off point where Part 4's progress-tracking transaction (the `prisma.$transaction` pattern shown earlier) will plug in.


    
