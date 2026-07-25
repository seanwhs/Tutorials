# Primer 2: Next.js App Router, React, and Server/Client Boundaries

GreyMatter Feedback uses **Next.js 16** and **React 19**.

These tools let one application provide:

- Public participant feedback pages.
- Protected administrator pages.
- API endpoints.
- Server-side database access.
- Interactive browser forms.
- Background-job integration endpoints.

Before working with the project files, it helps to understand where code runs and why that matters.

---

## 1. What Next.js Does

Next.js is a framework built around React.

React helps create interface components:

```text
Buttons
Forms
Cards
Navigation
Messages
Charts
```

Next.js adds application-level capabilities:

```text
File-based routing
Server-side rendering
API routes
Metadata
Layouts
Authentication-friendly server code
Database access
Production deployment support
```

In GreyMatter Feedback, Next.js acts as both:

```text
Website framework
AND
Backend application framework
```

This means we do not need a separate Express, Fastify, or NestJS server for the baseline application.

---

## 2. The App Router

Next.js App Router creates URLs from folders inside:

```text
src/app/
```

For example:

```text
src/app/page.tsx
```

becomes:

```text
/
```

This is the GreyMatter Feedback landing page.

Another example:

```text
src/app/admin/login/page.tsx
```

becomes:

```text
/admin/login
```

This is the administrator sign-in page.

---

## 3. Dynamic Routes

A **dynamic route** contains a variable section.

GreyMatter Feedback uses:

```text
src/app/e/[sessionId]/page.tsx
```

This supports URLs such as:

```text
/e/REACT-2026-Q3
/e/TYPESCRIPT-MODULE-1
/e/LEADERSHIP-WEEK-2
```

The folder name:

```text
[sessionId]
```

means:

> “Capture whatever appears in this part of the URL and make it available as `sessionId`.”

For this URL:

```text
/e/REACT-2026-Q3
```

Next.js provides:

```ts
{
  sessionId: "REACT-2026-Q3"
}
```

The application can then use that value to load the correct session and published form from Neon.

---

## 4. Route File Types

The App Router recognizes several specially named files.

| File name | Purpose |
|---|---|
| `page.tsx` | Renders a route page |
| `layout.tsx` | Wraps routes with shared UI |
| `route.ts` | Creates an API endpoint |
| `not-found.tsx` | Renders a custom not-found state |
| `loading.tsx` | Renders while a route is loading |
| `error.tsx` | Renders when a route throws an error |
| `actions.ts` | Convention for server-side form actions; not a special Next.js name |

Example participant route structure:

```text
src/app/e/[sessionId]/
├── page.tsx
└── not-found.tsx
```

Example API route structure:

```text
src/app/api/feedback/
└── route.ts
```

This creates:

```text
POST /api/feedback
```

---

## 5. Layouts

A layout is shared UI around one or more pages.

GreyMatter Feedback has a root layout:

```text
src/app/layout.tsx
```

It provides:

```text
HTML language
Global styles
Fonts
Page metadata
Service worker registration
```

The administrator area has another layout:

```text
src/app/(admin)/admin/layout.tsx
```

It provides:

```text
Authentication check
Admin navigation
Sign-out control
Shared administrator page spacing
```

The hierarchy looks like this:

```text
Root layout
  └── Admin layout
        └── Admin page
```

For example:

```text
src/app/layout.tsx
  └── src/app/(admin)/admin/layout.tsx
        └── src/app/(admin)/admin/events/page.tsx
```

---

## 6. Route Groups

A route group is a folder wrapped in parentheses:

```text
(admin)
```

It organizes files without changing the URL.

Example file:

```text
src/app/(admin)/admin/events/page.tsx
```

Actual URL:

```text
/admin/events
```

Not:

```text
/(admin)/admin/events
```

Route groups are useful when a set of pages shares a layout or access rule.

GreyMatter Feedback uses `(admin)` so all protected administrator routes share the same authentication layout.

---

## 7. Server Components

By default, App Router components are **Server Components**.

A Server Component runs on the server, not inside the participant’s browser.

Example:

```tsx
export default async function ParticipantSessionPage() {
  const session = await getParticipantSession("REACT-2026-Q3");

  return <h1>{session.title}</h1>;
}
```

Server Components can safely use:

```text
Prisma
Neon database queries
Environment variables
Node.js APIs
Administrator authentication checks
Private server helpers
```

They are useful for GreyMatter Feedback pages that need secure data.

Examples:

```text
Participant session page
Admin event list
Admin session editor
Analytics dashboard
```

---

## 8. Client Components

A **Client Component** runs in the browser.

It begins with this directive:

```tsx
"use client";
```

Example:

```tsx
"use client";

import { useState } from "react";

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(count + 1)} type="button">
      Count: {count}
    </button>
  );
}
```

Client Components are required for browser interaction such as:

```text
React state
onClick handlers
onChange handlers
localStorage
navigator.vibrate()
fetch()
Clipboard access
Timers
Browser events
```

GreyMatter Feedback uses Client Components for:

```text
Participant form controls
Draft persistence
Offline outbox
Administrator login form
Question authoring form
QR-code image generation
Automatic dashboard refresh
PDF report status polling
```

---

## 9. Why Server and Client Boundaries Matter

A browser is not a secure environment.

Anything sent to the browser can potentially be inspected by the person using it.

This means the participant browser must never receive:

```text
DATABASE_URL
DIRECT_URL
ADMIN_PASSWORD
ADMIN_SESSION_SECRET
IP_HASH_SECRET
S3 credentials
Raw response data from other participants
Raw administrator session tokens
```

The secure division is:

```text
Server Component
  ├── Loads secure data
  ├── Uses Prisma
  ├── Checks permissions
  └── Passes only safe data down

Client Component
  ├── Displays interactive controls
  ├── Manages browser state
  ├── Saves local drafts
  └── Sends validated requests to API routes
```

---

## 10. Example: Participant Form Boundary

The participant page is a Server Component:

### `src/app/e/[sessionId]/page.tsx`

```tsx
import { FeedbackForm } from "@/components/participant/feedback-form";
import { getParticipantSession } from "@/lib/participant-session";

export default async function ParticipantSessionPage({
  params,
}: {
  params: Promise<{ sessionId: string }>;
}) {
  const { sessionId } = await params;
  const state = await getParticipantSession(sessionId);

  if (state.kind !== "ready") {
    return <p>Feedback is unavailable.</p>;
  }

  return (
    <FeedbackForm
      formVersionId={state.session.formVersionId}
      questions={state.session.questions}
      sessionId={state.session.id}
    />
  );
}
```

This page can query Neon because it runs on the server.

The interactive form is a Client Component:

### `src/components/participant/feedback-form.tsx`

```tsx
"use client";

import { useState } from "react";

export function FeedbackForm() {
  const [answers, setAnswers] = useState({});

  return <form>{/* Interactive controls appear here. */}</form>;
}
```

The client form receives only safe information:

```text
Session ID
Form version ID
Question text
Question types
Question options
Question settings
Required status
```

It does not receive:

```text
Database credentials
Admin data
Other participant answers
Raw server secrets
```

---

## 11. The `server-only` Guard

Files that must never be used by browser components should import:

```ts
import "server-only";
```

Example:

### `src/lib/prisma.ts`

```ts
import "server-only";

import { PrismaClient } from "@prisma/client";

export const prisma = new PrismaClient();
```

This tells Next.js:

> “This module belongs only on the server.”

If someone accidentally imports it into a Client Component, the build should fail instead of exposing unsafe code.

GreyMatter Feedback uses `server-only` for modules that work with:

```text
Prisma
Authentication secrets
IP hashing
Rate limiting
Report storage
PDF generation
Analytics queries
Inngest persistence
```

---

## 12. The `"use client"` Boundary

When a file contains:

```tsx
"use client";
```

that file and the modules it imports become part of the browser-side dependency tree.

For that reason, a Client Component should not import a server-only module.

This is unsafe:

```tsx
"use client";

import { prisma } from "@/lib/prisma";
```

This is also unsafe:

```tsx
"use client";

import { env } from "@/lib/env";
```

Instead, the client should call an API route or receive safe data from a Server Component.

Correct example:

```tsx
"use client";

async function submitFeedback(payload: unknown) {
  await fetch("/api/feedback", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });
}
```

---

## 13. API Routes

An API route uses:

```text
route.ts
```

Example:

### `src/app/api/feedback/route.ts`

```ts
import { NextResponse } from "next/server";

export async function POST(request: Request): Promise<NextResponse> {
  const body = await request.json();

  return NextResponse.json({
    accepted: true,
    received: body,
  });
}
```

This creates:

```text
POST /api/feedback
```

GreyMatter Feedback uses API routes when browser code needs a server operation.

Examples:

| API route | Purpose |
|---|---|
| `POST /api/feedback` | Validate and queue participant feedback |
| `GET /api/admin/export/[sessionId]` | Download protected CSV |
| `GET /api/admin/reports/[sessionId]` | Read PDF report history |
| `POST /api/admin/reports/[sessionId]` | Queue PDF report |
| `/api/inngest` | Inngest function endpoint |

---

## 14. Server Actions

A **Server Action** is another way to run server-side code from a React form.

GreyMatter Feedback uses Server Actions primarily for administrator workflows.

Example:

### `src/app/(admin)/admin/events/actions.ts`

```ts
"use server";

import { prisma } from "@/lib/prisma";

export async function createEventAction(formData: FormData) {
  const title = String(formData.get("title") ?? "");

  await prisma.event.create({
    data: {
      title,
    },
  });
}
```

A React form can use it:

```tsx
<form action={createEventAction}>
  <input name="title" />
  <button type="submit">Create event</button>
</form>
```

The browser submits form data, but the action runs on the server.

This is useful because the server action can safely:

```text
Use Prisma
Validate with Zod
Check authentication
Redirect after success
Revalidate pages
```

---

## 15. API Route or Server Action?

Both tools run on the server. Use the one that fits the caller.

| Situation | Better option |
|---|---|
| Browser form inside your Next.js admin UI | Server Action |
| Public participant submission endpoint | API route |
| External mobile app integration | API route |
| CSV file download | API route |
| Inngest endpoint | API route |
| Admin form creation with React form | Server Action |
| Third-party integration webhook | API route |

GreyMatter Feedback uses this pattern:

```text
Admin forms
  → Server Actions

Participant feedback
  → POST /api/feedback

Exports and report status
  → API routes

Background job integration
  → /api/inngest
```

---

## 16. Data Flow Between Components

A common GreyMatter Feedback flow is:

```text
Server Component
  ↓ passes safe data
Client Component
  ↓ sends browser request
API route or Server Action
  ↓ calls server helper
Prisma
  ↓
Neon PostgreSQL
```

For participant feedback:

```text
Participant session page
  ↓
FeedbackForm Client Component
  ↓
POST /api/feedback
  ↓
Validation and rate limiting
  ↓
Inngest event
  ↓
Neon persistence
```

For admin form authoring:

```text
Session editor Server Component
  ↓
QuestionForm Client Component
  ↓
Server Action
  ↓
Zod validation
  ↓
Prisma
  ↓
Neon
```

---

## 17. Rendering Strategy in GreyMatter Feedback

Different pages have different needs.

### Participant session page

```text
Route:
 /e/[sessionId]

Rendering:
 Server Component shell + Client Component form

Why:
 Server loads secure published form quickly.
 Client handles taps, drafts, vibration, and submission.
```

### Admin analytics page

```text
Route:
 /admin/sessions/[sessionId]

Rendering:
 Mostly Server Component

Why:
 Analytics data stays server-side.
 Dashboard refreshes through router.refresh().
 QR and report controls use small Client Components.
```

### Form authoring page

```text
Route:
 /admin/sessions/[sessionId]/edit

Rendering:
 Server Component page + Client Component authoring form

Why:
 Server loads session and draft state.
 Client updates question-type configuration controls.
 Server Actions safely persist changes.
```

---

## 18. Important Rule: Keep Client Components Small

Client Components add JavaScript to the browser.

For a participant form, that JavaScript is necessary because the participant needs to interact with controls.

However, unnecessary Client Components can slow the page.

Avoid making an entire route client-side when only one small feature needs browser interaction.

Prefer:

```text
Server-rendered page
  └── Small Client Component for interactivity
```

Example:

```tsx
export default async function DashboardPage() {
  const analytics = await getSessionAnalytics("REACT-2026-Q3");

  return (
    <>
      <DashboardContent analytics={analytics} />
      <AnalyticsAutoRefresh />
    </>
  );
}
```

Only `AnalyticsAutoRefresh` needs to be a Client Component.

---

## 19. Common Boundary Mistakes

### Mistake 1: Using `window` in a Server Component

This fails because `window` exists only in a browser.

Incorrect:

```tsx
export default function Page() {
  const width = window.innerWidth;

  return <p>{width}</p>;
}
```

Correct: move browser-specific code into a Client Component.

```tsx
"use client";

import { useEffect, useState } from "react";

export function ScreenWidth() {
  const [width, setWidth] = useState(0);

  useEffect(() => {
    setWidth(window.innerWidth);
  }, []);

  return <p>{width}</p>;
}
```

### Mistake 2: Using Prisma in a Client Component

Incorrect:

```tsx
"use client";

import { prisma } from "@/lib/prisma";
```

Correct:

```text
Load data in Server Component
or
Call a protected API route
or
Use a Server Action
```

### Mistake 3: Passing too much data to the browser

Incorrect participant payload:

```text
All session responses
All IP hashes
All report records
All admin metadata
```

Correct participant payload:

```text
Current session title
Published form version ID
Published questions
Question settings
Question options
```

### Mistake 4: Making every component client-side

Incorrect:

```tsx
"use client";

export default function EntireAdminDashboard() {
  // Fetches everything in browser.
}
```

Better:

```tsx
export default async function AdminDashboard() {
  // Fetch secure analytics on server.
}
```

Then embed small interactive Client Components where needed.

---

## 20. Primer Summary

The most useful mental model is:

```text
Next.js App Router
  = application map and server framework

Server Components
  = secure data loading and rendering

Client Components
  = browser interactions

API routes
  = HTTP service desks

Server Actions
  = secure form operations inside Next.js UI

Prisma
  = typed database translator

Neon
  = persistent data storage

Inngest
  = reliable background work coordinator
```

For GreyMatter Feedback:

```text
Server loads the correct published form.
Browser lets participant answer it.
API validates the submission.
Inngest processes it in the background.
Neon stores it.
Admin dashboard reads and reports on it.
```
