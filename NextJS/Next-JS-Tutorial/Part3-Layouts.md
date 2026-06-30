# Next.js 16 for Absolute Beginners

# Part 3 — Understanding Layouts: The Secret Behind Modern Web Applications

> **Goal of this lesson:** Master layouts—the most powerful feature of the Next.js App Router—and understand how Next.js builds, preserves, and updates your application's user interface.

---

# Stop Thinking in Pages

When most beginners first learn web development, they think of websites as collections of pages:

* Home page
* About page
* Blog page
* Contact page

This mental model comes from traditional websites, where every navigation loads an entirely new HTML document.

Modern web applications work differently.

Professional developers think of applications as **hierarchical user interface trees**.

```text
Application
│
├── Shared UI
│   ├── Header
│   ├── Navigation
│   ├── Sidebar
│   └── Footer
│
└── Current Content
```

Instead of rebuilding everything during navigation, modern frameworks preserve the parts of the interface that remain unchanged.

This is exactly what layouts provide in Next.js.

---

# Think Like an Architect

Imagine building a shopping mall.

Every store shares:

* entrances
* escalators
* elevators
* parking
* electricity
* air conditioning

Individual stores do not rebuild these systems.

They simply customize the interior of their own shops.

Next.js layouts work exactly the same way.

```text
Shopping Mall
     ↓
Shared Infrastructure
     ↓
Individual Stores

Next.js Application
     ↓
Shared Layout
     ↓
Individual Pages
```

Layouts provide the shared infrastructure.

Pages provide the unique content.

---

# The App Router Is Built Around Special Files

Unlike React Router, which requires explicit route configuration, the Next.js App Router uses special files inside the filesystem.

## Important App Router Files

| File            | Purpose                   | Required  |
| --------------- | ------------------------- | --------- |
| `page.tsx`      | Creates a route           | Yes       |
| `layout.tsx`    | Creates shared UI         | Root only |
| `template.tsx`  | Creates non-persistent UI | No        |
| `loading.tsx`   | Creates loading states    | No        |
| `error.tsx`     | Creates error boundaries  | No        |
| `not-found.tsx` | Creates 404 pages         | No        |
| `route.ts`      | Creates API endpoints     | No        |

Example:

```text
app/
├── layout.tsx
├── page.tsx
├── about/
│   └── page.tsx
├── blog/
│   ├── layout.tsx
│   ├── loading.tsx
│   └── [slug]/
│       └── page.tsx
```

These files do not merely define pages.

They define how Next.js constructs a **user interface tree**.

---

# Route Segments: The Building Blocks of the App Router

Every folder inside the `app` directory is called a **route segment**.

Consider:

```text
app/
└── blog/
     └── react/
          └── hooks/
               └── page.tsx
```

This produces:

```text
/blog/react/hooks
```

Internally, Next.js thinks about this as:

```text
/
└── blog
     └── react
          └── hooks
```

Each route segment can contribute:

* pages
* layouts
* templates
* loading states
* error boundaries

This means URLs are transformed into a hierarchy of UI components.

---

# The Professional Mental Model

Beginners think:

```text
URL
 ↓
Page
```

Professional Next.js engineers think:

```text
URL
 ↓
Route Segments
 ↓
Special Files
 ↓
Layout Tree
 ↓
React Component Tree
 ↓
Rendered UI
```

This mental model explains almost everything in the App Router.

---

# Why Do We Need Layouts?

Suppose our application contains:

```text
/
/about
/blog
/contact
```

Every page requires:

* a header
* navigation
* footer

Without layouts, we would repeatedly write:

```tsx
export default function HomePage() {
  return (
    <>
      <header>
        <h1>My Website</h1>
        <nav>...</nav>
      </header>

      <main>
        Home Content
      </main>

      <footer>
        Copyright 2026
      </footer>
    </>
  );
}
```

Then repeat the same structure:

```tsx
export default function AboutPage() {
  return (
    <>
      <header>
        <h1>My Website</h1>
        <nav>...</nav>
      </header>

      <main>
        About Content
      </main>

      <footer>
        Copyright 2026
      </footer>
    </>
  );
}
```

---

# Problems With This Approach

## Code Duplication

The same code appears repeatedly.

## Difficult Maintenance

Changing navigation requires editing many files.

## Inconsistent UI

Pages slowly diverge.

## Poor Performance

Entire pages reload unnecessarily.

---

# Enter Layouts

A layout is a special React component that wraps pages and other layouts.

```tsx
// app/layout.tsx

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <header>
          <h1>Next.js Academy</h1>
          <nav>...</nav>
        </header>

        {children}

        <footer>
          Copyright 2026
        </footer>
      </body>
    </html>
  );
}
```

Think of a layout as a reusable application shell.

---

# The Root Layout

Every App Router application must contain exactly one root layout.

```text
app/
├── layout.tsx
└── page.tsx
```

The root layout has two responsibilities.

## 1. Wrap the Entire Application

Everything renders inside this component.

## 2. Define the HTML Document

Unlike ordinary React components, the root layout must contain:

```html
<html>
<body>
```

Example:

```tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

Without a root layout, your application cannot run.

---

# Understanding the Function Syntax

Many beginners find this syntax intimidating:

```tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
```

Let's break it down.

---

## What Next.js Actually Calls

Internally, Next.js executes:

```tsx
RootLayout({
  children: <CurrentPage />
});
```

So the layout receives an object.

---

## Object Destructuring

Instead of:

```tsx
function RootLayout(props) {
  return props.children;
}
```

we write:

```tsx
function RootLayout({ children }) {
  return children;
}
```

This is called destructuring.

---

## TypeScript Annotation

The type:

```tsx
{
  children: React.ReactNode
}
```

tells TypeScript:

> "This property contains valid React output."

---

# What Is React.ReactNode?

`React.ReactNode` means:

> Anything React can render.

Examples:

```tsx
"Hello"

42

<div>Hello</div>

<Component />

null

[
  <li>A</li>,
  <li>B</li>
]
```

---

# The Most Important Concept: Children Are Placeholders

Suppose our layout contains:

```tsx
<body>
  <header>Header</header>

  {children}

  <footer>Footer</footer>
</body>
```

When the user visits:

```text
/about
```

and `about/page.tsx` contains:

```tsx
export default function AboutPage() {
  return <h2>About Us</h2>;
}
```

Next.js automatically produces:

```html
<body>
  <header>Header</header>

  <h2>About Us</h2>

  <footer>Footer</footer>
</body>
```

The page is injected into the layout.

---

# Server Components vs Client Components

One of the biggest conceptual shifts in Next.js is that not all React components run in the browser.

Traditional React:

```text
Browser
   ↓
All Components
```

App Router:

```text
Server
   ↓
Server Components

Browser
   ↓
Client Components
```

By default, every component inside `app/` is a Server Component.

```tsx
export default function Page() {
  return <h1>Hello</h1>;
}
```

Server Components:

* run on the server
* send minimal JavaScript
* improve performance
* reduce bundle size
* can fetch data directly

---

# When Do We Need Client Components?

You need a Client Component whenever you require:

| Feature             | Client Component Required |
| ------------------- | ------------------------- |
| `useState()`        | Yes                       |
| `useReducer()`      | Yes                       |
| `useEffect()`       | Yes                       |
| `onClick`           | Yes                       |
| `onSubmit`          | Yes                       |
| `localStorage`      | Yes                       |
| `window`            | Yes                       |
| `document`          | Yes                       |
| `usePathname()`     | Yes                       |
| `useSearchParams()` | Yes                       |

Example:

```tsx
"use client";

import { useState } from "react";

export default function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(count + 1)}>
      {count}
    </button>
  );
}
```

---

# The Golden Rule of Client Components

> Keep `"use client"` as high as necessary, but as low as possible.

Good:

```text
RootLayout (server)
     ↓
Header (server)
     ↓
SearchBox (client)
```

Bad:

```text
RootLayout (client)
     ↓
Entire Application
```

Smaller client boundaries produce better performance.

---

# Layouts Are Persistent Application Shells

Beginners think layouts are:

```text
Reusable wrappers
```

Professional developers think layouts are:

```text
Persistent application shells
```

Example:

```text
Browser Window
│
├── RootLayout
│
├── Header
│
├── Navigation
│
├── AdminLayout
│
│   ├── Sidebar
│   │
│   └── Current Page
│
└── Footer
```

The shell remains alive.

Only the page changes.

---

# How Next.js Builds the Layout Tree

Suppose we have:

```text
app/
├── layout.tsx
└── blog/
    ├── layout.tsx
    └── [slug]/
        └── page.tsx
```

When the user visits:

```text
/blog/hello-world
```

Beginners think:

```text
BlogPostPage
```

gets rendered.

This is incorrect.

Next.js constructs:

```text
RootLayout
     ↓
BlogLayout
     ↓
BlogPostPage
```

Equivalent React:

```tsx
<RootLayout>
  <BlogLayout>
    <BlogPostPage />
  </BlogLayout>
</RootLayout>
```

This is the App Router execution tree.

---

# Nested Layouts: The App Router Superpower

Nested layouts are arguably the most powerful feature of the App Router.

Example:

```text
app/
└── admin/
     ├── layout.tsx
     ├── page.tsx
     ├── users/
     │    └── page.tsx
     └── settings/
          └── page.tsx
```

The admin layout provides:

* sidebar
* navigation
* shared state
* dashboard shell

Visiting:

```text
/admin/users
```

produces:

```text
RootLayout
     ↓
AdminLayout
     ↓
UsersPage
```

Visiting:

```text
/admin/settings
```

produces:

```text
RootLayout
     ↓
AdminLayout
     ↓
SettingsPage
```

Notice:

```text
RootLayout
AdminLayout
```

never disappear.

---

# The Lifetime of a Layout

Suppose we navigate:

```text
/admin/users
```

to:

```text
/admin/settings
```

Traditional websites:

```text
Destroy everything
       ↓
Recreate everything
```

App Router:

```text
Keep RootLayout
Keep AdminLayout
Destroy UsersPage
Create SettingsPage
```

This means:

* sidebars stay open
* search boxes preserve values
* state survives navigation
* interactions feel instant

---

# Partial Rendering

Traditional websites:

```text
Click Link
     ↓
Destroy Everything
     ↓
Reload Everything
```

App Router:

```text
Header
Sidebar
Footer
       ↓
Remain Alive

Current Page
       ↓
Replace Only This
```

Example:

Before:

```text
Header
Sidebar
Users Page
Footer
```

After:

```text
Header
Sidebar
Settings Page
Footer
```

This optimization is called **partial rendering**.

---

# What Actually Happens When You Click a Link?

Suppose we navigate:

```text
/admin/users
        ↓
/admin/settings
```

The App Router performs:

```text
Step 1:
Analyze URL

        ↓

Step 2:
Find shared route segments

        ↓

Step 3:
Preserve shared layouts

        ↓

Step 4:
Destroy changed page subtree

        ↓

Step 5:
Render new page subtree
```

Only the changed portion of the UI updates.

---

# Building an Interactive Admin Layout

Most layouts should remain Server Components.

However, dashboards often require:

* collapsible sidebars
* localStorage
* active navigation
* keyboard shortcuts
* user preferences

These require a Client Component.

```tsx
"use client";
```

Once added, the layout can use:

* `useState`
* `useEffect`
* `usePathname`
* `localStorage`

---

# Persisting Sidebar State

```tsx
const [collapsed, setCollapsed] = useState(false);
```

Load preferences:

```tsx
useEffect(() => {
  const saved = localStorage.getItem(
    "sidebar"
  );

  if (saved) {
    setCollapsed(saved === "true");
  }
}, []);
```

Persist preferences:

```tsx
useEffect(() => {
  localStorage.setItem(
    "sidebar",
    String(collapsed)
  );
}, [collapsed]);
```

Result:

```text
Collapse Sidebar
       ↓
Navigate
       ↓
Refresh Browser
       ↓
Sidebar Still Collapsed
```

---

# Active Navigation with usePathname()

Client layouts can inspect the current route.

```tsx
"use client";

import { usePathname } from "next/navigation";

export default function Sidebar() {
  const pathname = usePathname();

  return <>{pathname}</>;
}
```

This enables:

* active links
* breadcrumbs
* route-aware navigation
* dashboard menus

---

# Sharing Layout State with Context

A layout often contains shared state.

Example:

```text
AdminLayout
      │
      ├── Sidebar State
      │
      └── Current Page
```

Instead of prop drilling:

```text
Layout
   ↓
Page
   ↓
Component
   ↓
Child
```

Use Context:

```text
SidebarProvider
       ↓
AdminLayout
       ↓
UsersPage
       ↓
SettingsPage
```

Now every page can access:

```tsx
const {
  collapsed,
  toggleSidebar
} = useSidebar();
```

without passing props.

---

# Layouts vs Templates

| Feature                    | `layout.tsx` | `template.tsx`    |
| -------------------------- | ------------ | ----------------- |
| Persists                   | Yes          | No                |
| Preserves state            | Yes          | No                |
| Preserves scroll           | Yes          | No                |
| Remounts                   | No           | Yes               |
| Runs animations repeatedly | No           | Yes               |
| Best use                   | Shared UI    | Route transitions |

Rule of thumb:

> Use `layout.tsx` about 95% of the time.

---

# Production Architecture

Large applications often look like this:

```text
app/
│
├── layout.tsx
│
├── auth/
│   └── layout.tsx
│
├── dashboard/
│   ├── layout.tsx
│   ├── analytics/
│   ├── users/
│   ├── reports/
│   └── settings/
│
└── marketing/
    ├── layout.tsx
    ├── blog/
    └── pricing/
```

Each layout acts as a separate application shell.

| Layout    | Responsibility      |
| --------- | ------------------- |
| Root      | Global application  |
| Auth      | Authentication UI   |
| Marketing | Public website      |
| Dashboard | Dashboard shell     |
| Settings  | Settings navigation |

---

# Production Best Practices

### Keep layouts server-first

Good:

```text
RootLayout (server)
      ↓
Header (server)
      ↓
SearchBox (client)
```

Bad:

```text
RootLayout (client)
      ↓
Entire application
```

---

### Store persistent UI state in layouts

Examples:

* sidebar state
* theme preference
* dashboard filters
* open panels
* active tabs

---

### Share layout state with Context

Avoid prop drilling.

---

### Extract complex logic into hooks

Example:

```text
hooks/
└── useAdminSidebar.ts
```

---

### Consider state libraries for large applications

For very large dashboards:

* Zustand
* Jotai
* Redux Toolkit

may become better choices.

---

# What You've Learned

You now understand:

✅ App Router special files

✅ Route segments

✅ Root layouts

✅ Nested layouts

✅ Server Components

✅ Client Components

✅ Layout trees

✅ Persistent UI shells

✅ Partial rendering

✅ State preservation

✅ Shared layout state

✅ Context providers

✅ Templates

✅ Production architecture

---

# The Ultimate Mental Model

Beginners think:

```text
Website
   ↓
Pages
```

Professional Next.js engineers think:

```text
Website
   ↓
Route Segments
   ↓
Special Files
   ↓
Layout Tree
   ↓
Server Components
   ↓
Client Components
   ↓
Persistent UI Shell
   ↓
Rendered Application
```

Or, put another way:

> **The App Router is not a page router.**
>
> **It is a persistent UI composition engine that constructs and preserves a hierarchical React component tree based on the current URL.**

Once you understand this, you understand the philosophy behind the Next.js App Router.

---

## Coming Up Next

In Part 4, we'll explore:

* `next/link`
* client-side navigation
* dynamic routes
* route parameters
* catch-all routes
* prefetching
* navigation performance
* route transitions
