# Appendix A2 — Next.js 16 App Router Cheat Sheet

## The Complete Reference for the App Router

> **Purpose:** This appendix is your day-to-day reference guide for the Next.js 16 App Router. Keep this section open whenever you're building applications.

---

# Introduction

The App Router is one of the most important concepts in modern Next.js.

Beginners often think:

```text
Router
=
URL mapping
```

In Next.js 16, the App Router is actually:

```text
URL Router
       +
UI Router
       +
Rendering Engine
       +
Caching Engine
       +
Data Fetching Engine
```

---

# The App Router Mental Model

Traditional web frameworks:

```text
Request
   |
Route
   |
Response
```

Next.js App Router:

```text
URL
  |
Route Tree
  |
Layouts
  |
Pages
  |
Components
  |
Cache
  |
Streaming
```

---

# The Complete App Router File System

```text
app/

page.tsx

layout.tsx

template.tsx

loading.tsx

error.tsx

global-error.tsx

not-found.tsx

default.tsx

route.ts
```

Every file has a specific responsibility.

---

# page.tsx

## Purpose

Defines:

```text
A route.
```

---

# Example

```text
app/page.tsx
```

URL:

```text
/
```

---

```tsx
export default function Home() {
  return (
    <h1>Home</h1>
  );
}
```

---

# Nested Example

```text
app/about/page.tsx
```

Produces:

```text
/about
```

---

```tsx
export default function About() {
  return (
    <h1>About</h1>
  );
}
```

---

# Dynamic Routes

```text
app/blog/[slug]/page.tsx
```

Matches:

```text
/blog/hello
/blog/nextjs
/blog/react
```

---

```tsx
export default async function Post({
  params,
}: {
  params: Promise<{
    slug: string;
  }>;
}) {

  const { slug } =
    await params;

  return (
    <h1>{slug}</h1>
  );
}
```

---

# Catch-All Routes

```text
app/docs/[...slug]/page.tsx
```

Matches:

```text
/docs
/docs/api
/docs/api/auth
```

---

# Optional Catch-All

```text
app/docs/[[...slug]]/page.tsx
```

Matches:

```text
/
/docs
/docs/api
/docs/api/auth
```

---

# layout.tsx

## Purpose

Defines:

```text
Shared UI.
```

---

# Example

```text
app/layout.tsx
```

---

```tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {

  return (
    <html>
      <body>
        {children}
      </body>
    </html>
  );
}
```

---

# Nested Layout

```text
app/

dashboard/

    layout.tsx

    page.tsx
```

---

```tsx
export default function
DashboardLayout({
  children,
}: {
  children:
    React.ReactNode;
}) {

  return (
    <>
      <Sidebar />

      {children}
    </>
  );
}
```

---

# Layout Tree

```text
Root Layout
      |
Dashboard Layout
      |
Dashboard Page
```

---

# Why Layouts Matter

Layouts:

```text
Persist.
```

Meaning:

```text
Navigation
does not
re-render them.
```

---

# template.tsx

## Purpose

Force re-rendering.

---

# Example

```text
app/dashboard/template.tsx
```

---

```tsx
export default function
Template({
  children,
}: {
  children:
    React.ReactNode;
}) {

  return children;
}
```

---

# Difference

Layout:

```text
Persists.
```

Template:

```text
Recreates.
```

---

# Visualizing

```text
Navigate

Layout:
Stay

Template:
Destroy
Create
```

---

# loading.tsx

## Purpose

Suspense fallback UI.

---

# Example

```text
app/loading.tsx
```

---

```tsx
export default function
Loading() {

  return (
    <div>
      Loading...
    </div>
  );
}
```

---

# Visualizing

```text
Request
    |
Loading UI
    |
Data arrives
    |
Render page
```

---

# Nested Loading

```text
app/

dashboard/

    loading.tsx
```

Only affects:

```text
/dashboard/*
```

---

# error.tsx

## Purpose

Route-level error boundary.

---

# Example

```tsx
"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error;
  reset: () => void;
}) {

  return (
    <>
      <h1>
        Error
      </h1>

      <button
        onClick={reset}
      >
        Retry
      </button>
    </>
  );
}
```

---

# Visualizing

```text
Page throws
     |
Error boundary
     |
Fallback UI
```

---

# Why Client Component?

Because React error boundaries require:

```text
Browser state.
```

---

# global-error.tsx

## Purpose

Catch catastrophic failures.

---

# Example

```text
app/global-error.tsx
```

---

```tsx
"use client";

export default function
GlobalError() {

  return (
    <html>
      <body>
        Fatal error
      </body>
    </html>
  );
}
```

---

# Difference

```text
error.tsx

=
Route failure
```

```text
global-error.tsx

=
Application failure
```

---

# not-found.tsx

## Purpose

Custom 404 pages.

---

# Example

```tsx
export default function
NotFound() {

  return (
    <h1>
      Not Found
    </h1>
  );
}
```

---

# Trigger

```ts
import {
  notFound,
} from "next/navigation";

notFound();
```

---

# Example

```tsx
if (!post) {
  notFound();
}
```

---

# route.ts

## Purpose

API endpoints.

---

# Example

```text
app/api/users/route.ts
```

---

```ts
export async function GET() {

  return Response.json({
    users: [],
  });

}
```

---

# Supported Methods

```text
GET

POST

PUT

PATCH

DELETE

HEAD

OPTIONS
```

---

# Example

```ts
export async function POST(
  req: Request
) {

  const body =
    await req.json();

  return Response.json(
    body
  );
}
```

---

# Route Handlers vs Server Actions

Route Handler:

```text
HTTP API
```

Server Action:

```text
Function call
```

---

# Example

Server Action:

```ts
"use server";

export async function
createUser() {}
```

---

Route:

```ts
export async function
POST() {}
```

---

# Route Groups

## Purpose

Organization without URLs.

---

# Example

```text
app/

(marketing)/

(admin)/

(shop)/
```

---

# Result

```text
/about

/dashboard

/products
```

---

# Route groups do NOT appear:

```text
( )
```

---

# Example

```text
app/

(admin)/

    dashboard/

        page.tsx
```

URL:

```text
/dashboard
```

---

# Parallel Routes

## Purpose

Multiple UIs simultaneously.

---

# Example

```text
app/

@team

@analytics

@activity
```

---

# Visualizing

```text
Dashboard

    |
    +--- Team

    |
    +--- Analytics

    |
    +--- Activity
```

---

# Example Layout

```tsx
export default function
Layout({

  team,

  analytics,

  activity,

}: any) {

  return (
    <>
      {team}
      {analytics}
      {activity}
    </>
  );
}
```

---

# Intercepting Routes

## Purpose

Display pages inside modals.

---

# Example

```text
(.)photo
(..)photo
(...)photo
```

---

# Example Flow

```text
Gallery
    |
Click
    |
Open Modal
    |
Still preserve URL
```

---

# Metadata

Every page can define:

```ts
export const metadata = {
  title: "",
  description: "",
};
```

---

# Dynamic Metadata

```ts
export async function
generateMetadata() {

  return {
    title:
      "Blog",
  };

}
```

---

# Static Parameters

Used for prerendering.

---

```ts
export async function
generateStaticParams() {

  return [
    {
      slug: "a",
    },
    {
      slug: "b",
    },
  ];

}
```

---

# Middleware

File:

```text
middleware.ts
```

---

# Example

```ts
import {
  NextResponse,
} from "next/server";

export function
middleware() {

  return NextResponse
    .next();

}
```

---

# Common Uses

```text
Authentication

Localization

Redirects

A/B testing

Rate limiting
```

---

# Rendering Modes

Next.js supports:

```text
Static

Dynamic

Streaming

Partial prerendering
```

---

# Visualizing

```text
Request
   |
Cache?
   |
Yes -> Return
   |
No
   |
Render
   |
Cache
```

---

# Cache Components

Enable:

```ts
cacheComponents: true
```

---

# Example

```ts
async function
getPosts() {

  "use cache";

}
```

---

# Route Segment Configuration

Example:

```ts
export const dynamic =
  "force-dynamic";
```

---

Other options:

```text
force-static

force-dynamic

auto
```

---

# App Router Execution Order

```text
middleware

     |

layout

     |

template

     |

loading

     |

page

     |

components
```

---

# Complete Route Tree Example

```text
app/

layout.tsx

page.tsx

blog/

    layout.tsx

    loading.tsx

    page.tsx

    [slug]/

        page.tsx

dashboard/

    layout.tsx

    error.tsx

    page.tsx

api/

    users/

        route.ts
```

---

# Decision Tree

Need:

```text
A page?
```

Use:

```text
page.tsx
```

---

Need:

```text
Shared UI?
```

Use:

```text
layout.tsx
```

---

Need:

```text
Force remount?
```

Use:

```text
template.tsx
```

---

Need:

```text
Loading UI?
```

Use:

```text
loading.tsx
```

---

Need:

```text
Error UI?
```

Use:

```text
error.tsx
```

---

Need:

```text
404?
```

Use:

```text
not-found.tsx
```

---

Need:

```text
API?
```

Use:

```text
route.ts
```

---

# App Router Mental Model

Beginners think:

```text
Folders
=
Folders.
```

Professional engineers think:

```text
Folders
=
Application topology.
```

Because the App Router is not merely a router.

It is the execution model of your entire Next.js application.
