# Next.js 16 for Absolute Beginners

# Part 31 — Application Architecture: Building Layouts, Navigation, and the Application Shell in Next.js 16

> **Goal of this lesson:** Build the complete application shell for Nexus CMS using the Next.js App Router, including root layouts, nested layouts, route groups, dashboards, admin areas, navigation, loading states, and error boundaries.

---

# Why Layouts Matter

Beginners think pages are the application:

```text
Home Page

Blog Page

Dashboard Page

Admin Page
```

Professional engineers think:

```text
Application Shell
        |
        +---- Layouts
        |
        +---- Navigation
        |
        +---- State
        |
        +---- Pages
```

Because users don't experience pages.

Users experience applications.

---

# The Next.js App Router Mental Model

Old thinking:

```text
Page
   |
Page
   |
Page
```

Next.js App Router thinking:

```text
Layout
    |
    +---- Layout
    |
    +---- Layout
    |
    +---- Page
```

---

# Visualizing the App Router

```text
app/

    layout.tsx

        |
        +---- page.tsx

        +---- blog/

        |        |
        |        +---- layout.tsx
        |        |
        |        +---- page.tsx

        +---- dashboard/

                 |
                 +---- layout.tsx
                 |
                 +---- page.tsx
```

---

# Our Final Application Structure

```text
Nexus CMS

├── Public Website
│
├── Authentication
│
├── User Dashboard
│
└── Administration
```

---

# Application Architecture

```text
                           Root Layout
                                |
            +-------------------+-------------------+
            |                   |                   |
            V                   V                   V
         Public              Dashboard          Admin
            |                   |                   |
            V                   V                   V
         Pages              Pages               Pages
```

---

# Step 1 — Create Route Groups

Create:

```text
app/

    (public)/

    (auth)/

    (dashboard)/

    (admin)/
```

---

# Why Route Groups?

Without groups:

```text
/dashboard/login
/admin/login
```

With groups:

```text
/login
/dashboard
/admin
```

---

# Visualizing Route Groups

```text
app/

    (public)
         |
         home

    (auth)
         |
         login

URL:

/
login
```

---

# Step 2 — Root Layout

Create:

```text
app/layout.tsx
```

---

```tsx
import "./globals.css";

import type {
  Metadata,
} from "next";

export const metadata:
  Metadata = {

  title:
    "Nexus CMS",

  description:
    "Production-grade CMS",

};

export default function
RootLayout({

  children,

}: {

  children:
    React.ReactNode;

}) {

  return (

    <html lang="en">

      <body>

        {children}

      </body>

    </html>

  );

}
```

---

# Why Root Layout?

Because everything lives inside:

```text
HTML
   |
BODY
   |
Application
```

---

# Step 3 — Create Public Layout

```text
app/(public)/layout.tsx
```

---

```tsx
import {
  Navbar
} from "@/components/shared/navbar";

import {
  Footer
} from "@/components/shared/footer";

export default function
PublicLayout({

  children,

}: {

  children:
    React.ReactNode;

}) {

  return (

    <>

      <Navbar />

      <main>

        {children}

      </main>

      <Footer />

    </>

  );

}
```

---

# Visualizing Public Layout

```text
Navbar
    |
Content
    |
Footer
```

---

# Create Homepage

```text
app/(public)/page.tsx
```

---

```tsx
export default function
HomePage() {

  return (

    <div>

      <h1>

        Nexus CMS

      </h1>

    </div>

  );

}
```

---

# Step 4 — Create Dashboard Layout

```text
app/(dashboard)/dashboard/layout.tsx
```

---

```tsx
import {
  DashboardSidebar
} from
  "@/components/dashboard/sidebar";

export default function
DashboardLayout({

  children,

}: {

  children:
    React.ReactNode;

}) {

  return (

    <div className="flex">

      <DashboardSidebar />

      <main>

        {children}

      </main>

    </div>

  );

}
```

---

# Visualizing Dashboard

```text
+----------------+
| Sidebar        |
|                |
|                |
+----------------+
         |
         |
         V
      Content
```

---

# Why Nested Layouts?

Without nested layouts:

```text
Page
Page
Page
Page
```

Repeated code.

---

With nested layouts:

```text
Shared UI
     |
     +--- Page
     |
     +--- Page
     |
     +--- Page
```

---

# Step 5 — Create Admin Layout

```text
app/(admin)/admin/layout.tsx
```

---

```tsx
import {
  AdminSidebar
} from
  "@/components/admin/sidebar";

export default function
AdminLayout({

  children,

}: {

  children:
    React.ReactNode;

}) {

  return (

    <div>

      <AdminSidebar />

      {children}

    </div>

  );

}
```

---

# Why Separate Admin?

Because admin systems have:

```text
Different UX

Different permissions

Different navigation
```

---

# Application Shell Architecture

```text
                    Root Layout
                          |
          +---------------+---------------+
          |               |               |
          V               V               V
      Public         Dashboard        Admin
```

---

# Step 6 — Build Navbar

Create:

```text
components/shared/navbar.tsx
```

---

```tsx
import Link
  from "next/link";

export function Navbar() {

  return (

    <nav>

      <Link href="/">

        Home

      </Link>

      <Link href="/blog">

        Blog

      </Link>

      <Link href="/login">

        Login

      </Link>

    </nav>

  );

}
```

---

# Why Use Link?

Bad:

```html
<a href="/blog">
```

Causes:

```text
Full reload.
```

---

Good:

```tsx
<Link href="/blog">
```

Provides:

```text
Client navigation.
```

---

# Step 7 — Build Dashboard Sidebar

```tsx
import Link
  from "next/link";

export function
DashboardSidebar() {

  return (

    <aside>

      <Link
        href="/dashboard">

        Dashboard

      </Link>

      <Link
        href="/dashboard/posts">

        Posts

      </Link>

      <Link
        href="/dashboard/settings">

        Settings

      </Link>

    </aside>

  );

}
```

---

# Visualizing Sidebar Navigation

```text
Dashboard

Posts

Comments

Analytics

Settings
```

---

# Step 8 — Active Navigation

Create:

```tsx
"use client";

import {
  usePathname
} from "next/navigation";

export function NavItem({

  href,

  children,

}) {

  const pathname =
    usePathname();

  const active =

    pathname === href;

  return (

    <Link
      href={href}>

      {children}

    </Link>

  );

}
```

---

# Why Client Component?

Because:

```text
Current URL
```

exists only in the browser.

---

# Step 9 — Dashboard Page

```tsx
export default function
DashboardPage() {

  return (

    <div>

      <h1>

        Dashboard

      </h1>

    </div>

  );

}
```

---

# Step 10 — Dashboard Statistics Cards

```tsx
export function StatCard({

  title,

  value,

}) {

  return (

    <div>

      <h2>
        {title}
      </h2>

      <p>
        {value}
      </p>

    </div>

  );

}
```

---

# Example Usage

```tsx
<StatCard
  title="Posts"
  value={32}
/>

<StatCard
  title="Comments"
  value={118}
/>
```

---

# Visualizing Dashboard

```text
+----------+
| Posts    |
|    32    |
+----------+

+----------+
| Comments |
|    118   |
+----------+
```

---

# Step 11 — Loading UI

Create:

```text
loading.tsx
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

# What Happens?

```text
Request
    |
Loading UI
    |
Data arrives
    |
Page renders
```

---

# Why Loading UI Matters

Without loading:

```text
Blank screen.
```

With loading:

```text
Immediate feedback.
```

---

# Step 12 — Error Boundaries

Create:

```text
error.tsx
```

---

```tsx
"use client";

export default function
Error({

  error,

  reset,

}: {

  error: Error;

  reset:
    () => void;

}) {

  return (

    <div>

      <h1>

        Error

      </h1>

      <button
        onClick={reset}>

        Retry

      </button>

    </div>

  );

}
```

---

# Visualizing Error Recovery

```text
Request
   |
Error
   |
Boundary
   |
Recovery UI
```

---

# Step 13 — Not Found UI

Create:

```text
not-found.tsx
```

---

```tsx
export default function
NotFound() {

  return (

    <div>

      Not Found

    </div>

  );

}
```

---

# Example

User visits:

```text
/posts/does-not-exist
```

Response:

```text
404 page
```

---

# Step 14 — Protected Dashboard Layout

```tsx
import {
  redirect
} from
  "next/navigation";

export default async function
DashboardLayout({

  children,

}) {

  const user =
    await getCurrentUser();

  if (!user) {

    redirect(
      "/login"
    );

  }

  return children;

}
```

---

# Why Protect Layouts?

Bad:

```text
Protect every page.
```

Good:

```text
Protect the entire section.
```

---

# Visualizing Protected Layouts

```text
Dashboard Layout
        |
Auth Check
        |
+-------+-------+
|       |       |
Page   Page   Page
```

---

# Step 15 — Streaming Layouts

```tsx
import {
  Suspense
} from "react";

export default function
Dashboard() {

  return (

    <>

      <Suspense
        fallback={
          <div>
            Loading...
          </div>
        }
      >

        <Analytics />

      </Suspense>

      <Suspense
        fallback={
          <div>
            Loading...
          </div>
        }
      >

        <RecentPosts />

      </Suspense>

    </>

  );

}
```

---

# Visualizing Streaming

Without streaming:

```text
Wait
Wait
Wait
Render
```

---

With streaming:

```text
Render
    |
Render
    |
Render
```

---

# Final Application Architecture

```text
                    Root Layout
                          |
        +-----------------+----------------+
        |                 |                |
        V                 V                V
     Public         Dashboard         Admin
        |                 |                |
        V                 V                V
   Navigation       Sidebar        Sidebar
        |                 |                |
        V                 V                V
     Pages            Pages            Pages
```

---

# Application Shell Philosophy

Beginners build:

```text
Pages.
```

Professionals build:

```text
Experiences.
```

Because users don't think:

```text
I visited a page.
```

They think:

```text
I used an application.
```

---

# Exercises

## Exercise 1

Add:

```text
Profile page
```

to dashboard.

---

## Exercise 2

Add:

```text
Breadcrumb navigation.
```

---

## Exercise 3

Create:

```text
Admin top navigation.
```

---

## Exercise 4

Add:

```text
Mobile sidebar support.
```

---

# What You've Learned

You now understand:

✅ root layouts

✅ nested layouts

✅ route groups

✅ application shells

✅ navigation

✅ sidebars

✅ loading UI

✅ error boundaries

✅ not-found pages

✅ streaming layouts

---

# Mental Model

Beginners think:

```text
Website
     =
Pages
```

Professional engineers think:

```text
Application
      =
Layouts
      +
Navigation
      +
State
      +
Streaming
      +
User Experience
```

Because application architecture is user experience architecture.

---

# Part 32 Preview

In the next chapter we'll build our first major feature:

# The Post Management System

Including:

```text
✓ Create posts
✓ Edit posts
✓ Delete posts
✓ Drafts
✓ Publishing
✓ Slugs
✓ Validation
✓ Server Actions
✓ Cache Components
✓ Revalidation
✓ Rich metadata
```

This is where content management becomes systems engineering.
