# Next.js 16 for Absolute Beginners

# Part 17 — Routing Deep Dive: Understanding the App Router

> **Goal of this lesson:** Learn how the Next.js App Router works internally, understand every routing pattern available, and build complex application navigation systems.

---

# Routing Is the Heart of Next.js

At its core, Next.js is a routing framework.

Every application eventually becomes:

```text
URL
   |
   V
Route
   |
   V
Component
   |
   V
UI
```

---

# What Is Routing?

Suppose a user visits:

```text
/about
```

Next.js automatically maps it to:

```text
app/about/page.tsx
```

---

# Visualizing Basic Routing

```text
URL
   |
   +--- /
   |
   +--- /about
   |
   +--- /contact
```

becomes:

```text
app/

    page.tsx

    about/
        page.tsx

    contact/
        page.tsx
```

---

# Your First Routes

Create:

```text
app/

    page.tsx

    about/
        page.tsx

    pricing/
        page.tsx
```

---

## Home

```tsx
export default function Home() {

    return (

        <h1>
            Home
        </h1>

    );

}
```

---

## About

```tsx
export default function About() {

    return (

        <h1>
            About
        </h1>

    );

}
```

---

## Pricing

```tsx
export default function Pricing() {

    return (

        <h1>
            Pricing
        </h1>

    );

}
```

---

# Visualizing File-System Routing

```text
Filesystem
      |
      V

app/about/page.tsx
      |
      V

/about
```

---

# Nested Routes

Create:

```text
app/

    dashboard/

        page.tsx

        analytics/
            page.tsx

        users/
            page.tsx
```

---

Result:

```text
/dashboard

/dashboard/analytics

/dashboard/users
```

---

# Visualizing Nested Routes

```text
dashboard
      |
      +--- analytics
      |
      +--- users
```

---

# Dynamic Routes

Suppose:

```text
/blog/react
/blog/nextjs
/blog/javascript
```

Creating thousands of folders is impossible.

Instead:

```text
app/

    blog/

        [slug]/

            page.tsx
```

---

# Reading Route Parameters

```tsx
export default async function BlogPost({

    params,

}: {

    params: Promise<{
        slug: string;
    }>;

}) {

    const { slug } =
        await params;

    return (

        <h1>
            {slug}
        </h1>

    );

}
```

---

# Visualizing Dynamic Routing

```text
/blog/react
        |
        V

slug = "react"


/blog/nextjs
         |
         V

slug = "nextjs"
```

---

# Multiple Parameters

Example:

```text
/products/electronics/iphone
```

---

Create:

```text
app/

    products/

        [category]/

            [product]/

                page.tsx
```

---

Read:

```tsx
export default async function Page({

    params,

}: {

    params: Promise<{

        category: string;

        product: string;

    }>;

}) {

    const {
        category,
        product,
    } = await params;

}
```

---

# Visualizing Multiple Parameters

```text
products
     |
     +--- category
               |
               +--- product
```

---

# Catch-All Routes

Suppose:

```text
/docs/install
/docs/react/setup
/docs/react/hooks/useeffect
```

Depth varies.

---

Create:

```text
app/

    docs/

        [...slug]/

            page.tsx
```

---

Example:

```text
/docs/react/hooks/useeffect
```

Produces:

```tsx
{
    slug: [
        "react",
        "hooks",
        "useeffect",
    ]
}
```

---

# Visualizing Catch-All Routes

```text
/docs
     |
     +--- anything
     |
     +--- anything
     |
     +--- anything
```

---

# Optional Catch-All Routes

Sometimes:

```text
/docs
```

should also work.

Use:

```text
[[...slug]]
```

---

Example:

```text
app/

    docs/

        [[...slug]]/

            page.tsx
```

---

Results:

```text
/docs
/docs/react
/docs/react/hooks
```

all work.

---

# Route Parameters Are Server Data

Bad:

```tsx
"use client";

const params =
    useParams();
```

Good:

```tsx
export default async function Page({

    params,

}) {

}
```

Keep routing on the server whenever possible.

---

# Layouts

Suppose every dashboard page needs:

```text
Sidebar
Navbar
Footer
```

Don't repeat code.

---

Create:

```text
dashboard/

    layout.tsx
```

---

```tsx
export default function Layout({

    children,

}: {

    children:
        React.ReactNode;

}) {

    return (

        <div>

            <Sidebar />

            {children}

        </div>

    );

}
```

---

# Visualizing Layouts

```text
Layout
    |
    +--- Sidebar
    |
    +--- Navbar
    |
    +--- Child Page
```

---

# Nested Layouts

Example:

```text
app/

    layout.tsx

    dashboard/

        layout.tsx

        analytics/

            page.tsx
```

---

Visualized:

```text
Root Layout
      |
Dashboard Layout
      |
Analytics Page
```

---

# Route Groups

Sometimes folders should organize code but not URLs.

Example:

```text
(marketing)
(dashboard)
```

---

Create:

```text
app/

    (marketing)/

        about/

    (dashboard)/

        users/
```

---

Generated URLs:

```text
/about
/users
```

not:

```text
/marketing/about
/dashboard/users
```

---

# Visualizing Route Groups

```text
Folder
     |
Ignored
     |
URL
```

---

# Why Route Groups Exist

They allow:

```text
Different layouts
Different loading states
Different error boundaries
Different teams
```

---

# Example

```text
app/

    (marketing)/

        layout.tsx

    (dashboard)/

        layout.tsx
```

---

# Parallel Routes

Suppose:

```text
Dashboard
```

contains:

```text
Analytics
Notifications
Messages
```

Each loads independently.

---

Create:

```text
dashboard/

    @analytics/

    @messages/

    @notifications/
```

---

Visualized:

```text
Dashboard
     |
     +--- Analytics
     |
     +--- Messages
     |
     +--- Notifications
```

---

# Example Layout

```tsx
export default function Layout({

    analytics,

    messages,

    notifications,

}: any) {

    return (

        <div>

            {analytics}

            {messages}

            {notifications}

        </div>

    );

}
```

---

# Why Parallel Routes Matter

Without them:

```text
Load everything
```

With them:

```text
Load independently
```

which enables:

```text
Streaming
Suspense
Partial updates
```

---

# Intercepting Routes

One of the most powerful App Router features.

Suppose:

```text
/feed
```

contains:

```text
/photo/123
```

Clicking photo:

```text
Open modal
```

without leaving the feed.

---

Create:

```text
(..)photo
```

folders.

---

Visualizing Interception

Normal:

```text
/feed
      |
      V
/photo/123
```

Intercepted:

```text
/feed
      |
      V
Modal Overlay
```

---

# Real Example

Applications using this pattern:

```text
Instagram
Twitter/X
Reddit
GitHub
```

---

# Route Handlers

Sometimes you need backend endpoints.

Create:

```text
app/api/posts/route.ts
```

---

Example:

```tsx
export async function GET() {

    return Response.json([
        {
            title:
                "Hello",
        },
    ]);

}
```

---

# POST Endpoint

```tsx
export async function POST(
    request: Request
) {

    const body =
        await request.json();

    return Response.json(
        body
    );

}
```

---

# Visualizing Route Handlers

```text
Browser
    |
HTTP Request
    |
Route Handler
    |
Response
```

---

# Why Server Actions Are Usually Better

Instead of:

```text
Client
     |
API
     |
Database
```

Next.js encourages:

```text
Client
     |
Server Action
     |
Database
```

---

# URL Search Parameters

Example:

```text
/products?page=2
```

---

Access:

```tsx
export default function Page({

    searchParams,

}: {

    searchParams:
        Promise<{
            page?: string;
        }>;

}) {

    const {
        page,
    } =
        await searchParams;

}
```

---

# Visualizing Search Params

```text
/products?page=2

page = "2"
```

---

# Programmatic Navigation

Client component:

```tsx
"use client";

import {
    useRouter
} from
    "next/navigation";
```

---

Navigate:

```tsx
const router =
    useRouter();

router.push(
    "/dashboard"
);
```

---

Other methods:

```tsx
router.push()

router.replace()

router.back()

router.refresh()
```

---

# The Power of refresh()

Example:

```tsx
await createPost();

router.refresh();
```

Visualized:

```text
Mutation
    |
Refresh
    |
Server Components Re-render
```

---

# Link Component

Never use:

```html
<a href="/about">
```

Instead:

```tsx
import Link
    from "next/link";
```

---

Example:

```tsx
<Link
    href="/about"
>

    About

</Link>
```

---

# Why Link Is Better

Benefits:

```text
Prefetching
Caching
Fast Navigation
Partial Updates
Streaming
```

---

# Visualizing Navigation

Traditional:

```text
Page Reload
```

Next.js:

```text
Partial Navigation
```

---

# Complete App Router Architecture

```text
URL
   |
Route Match
   |
Layout Tree
   |
Server Components
   |
Suspense
   |
Streaming
   |
Browser
```

---

# Folder Structure Example

```text
app/

    layout.tsx

    page.tsx

    blog/

        page.tsx

        [slug]/

            page.tsx

    dashboard/

        layout.tsx

        users/

            page.tsx

        settings/

            page.tsx

    api/

        posts/

            route.ts
```

---

# Professional Rules

Prefer:

```text
Server Components
Layouts
Server Actions
Suspense
```

Avoid:

```text
Client routing everywhere
Manual state management
Large SPA patterns
```

---

# Exercises

## Exercise 1

Create:

```text
/blog/[slug]
```

that renders:

```text
slug
```

---

## Exercise 2

Create:

```text
/docs/[...slug]
```

and print:

```text
params.slug
```

---

## Exercise 3

Build:

```text
/dashboard
```

with:

```text
layout.tsx
```

containing a sidebar.

---

## Exercise 4

Create:

```text
app/api/users/route.ts
```

with:

```tsx
GET()
POST()
```

handlers.

---

# What You've Learned

You now understand:

✅ file-system routing

✅ nested routes

✅ dynamic routes

✅ catch-all routes

✅ optional catch-all routes

✅ layouts

✅ nested layouts

✅ route groups

✅ parallel routes

✅ intercepting routes

✅ route handlers

✅ search parameters

✅ programmatic navigation

---

# Mental Model

Don't think:

```text
Pages
```

Think:

```text
Route Tree
      |
      Layout Tree
      |
      Component Tree
      |
      Streaming Tree
```

The App Router isn't merely a router.

It's the execution engine that powers the entire Next.js application.

---

# Part 18 Preview

In the next chapter we'll learn:

# Caching Deep Dive in Next.js 16

Including:

* Cache Components
* `"use cache"`
* `cacheLife()`
* `cacheTag()`
* `revalidateTag()`
* `updateTag()`
* Partial Prerendering
* cache invalidation strategies
* production caching architectures

This is the chapter where we'll finally understand what makes Next.js 16 fundamentally different from previous versions.
