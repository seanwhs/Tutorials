# **Part 2 — Understanding the App Router**

# GreyMatter Journal

## Part 2 — Understanding the App Router: Why Modern Web Applications Are Not Collections of Pages

> **Goal of this lesson:** Understand the **Next.js App Router**, learn why folders become routes, discover the roles of `page.tsx` and `layout.tsx`, understand Route Groups, and develop the mental model that modern web applications are built as **persistent UI trees and architectural systems**, not collections of disconnected pages.

---

# The Biggest Mental Shift in Next.js

Most developers begin learning web development by thinking about websites as collections of pages:

```text
home.html
about.html
blog.html
contact.html
```

Navigation works like this:

```text
Current Page
      ↓
Destroy Everything
      ↓
Request New Page
      ↓
Rebuild Everything
```

This model worked well for traditional websites.

Modern applications do not work this way.

Consider applications you use every day:

* Gmail
* GitHub
* Notion
* Slack
* Discord
* Linear

When you navigate between screens:

```text
What stays?

✓ Navigation
✓ Sidebar
✓ User session
✓ Theme
✓ Application state
✓ Layout

What changes?

✓ Main content
```

The application feels continuous.

This is the fundamental idea behind the App Router.

---

# Traditional Websites vs Modern Applications

| Traditional Websites | Modern Applications |
| -------------------- | ------------------- |
| Full page reload     | Partial updates     |
| Entire page replaced | UI tree updated     |
| State lost           | State preserved     |
| Duplicate layouts    | Shared layouts      |
| Slower               | Faster              |
| Page-oriented        | Component-oriented  |

---

# The App Router Philosophy

The App Router changes the question from:

> "Which page should I show?"

to:

> "Which parts of the interface actually need to change?"

Instead of thinking:

```text
Application
        =
Collection of Pages
```

we begin thinking:

```text
Application
        =
Persistent UI Tree
```

This single mental model explains most of modern React and Next.js architecture.

---

# The File System Becomes the Router

In the App Router, folders define URLs.

For example:

```text
app/
├── page.tsx
├── about/
│   └── page.tsx
└── posts/
    └── page.tsx
```

automatically becomes:

```text
/
/about
/posts
```

No router configuration is required.

The folder structure itself becomes the routing system.

This concept is called:

```text
File-System Routing
```

---

# But Wait — Do All Folders Become URLs?

Beginners naturally assume:

```text
Folder
      =
URL
```

This is mostly true.

However, professional applications require folders that exist purely for organization.

This introduces one of the most important concepts in modern Next.js:

# Route Groups

Route Groups are folders wrapped in parentheses:

```text
(site)
(auth)
(admin)
(dashboard)
```

For example:

```text
app/
├── (site)/
│   ├── page.tsx
│   └── about/
│
├── (auth)/
│   └── login/
│
└── layout.tsx
```

The resulting URLs are:

```text
/
/about
/login
```

Notice:

```text
(site)
(auth)
```

never appear in the URL.

---

# Why Do Route Groups Exist?

Because software architecture exists for humans.

Consider this structure:

```text
app/
├── page.tsx
├── about/
├── posts/
├── login/
├── register/
├── dashboard/
├── settings/
└── analytics/
```

After a year, this becomes difficult to understand.

Instead:

```text
app/

├── (site)/
│   ├── page.tsx
│   ├── about/
│   └── posts/

├── (auth)/
│   ├── login/
│   └── register/

├── (dashboard)/
│   ├── analytics/
│   └── settings/
```

Now the folder structure communicates the architecture.

```text
Public Website
        ↓
Authentication
        ↓
Dashboard
```

Software architecture is ultimately about organizing human understanding.

---

# GreyMatter Journal Uses Route Groups

Throughout this tutorial series, we will organize our application using the following structure:

```text
app/

├── layout.tsx
├── globals.css
├── loading.tsx
├── error.tsx
└── not-found.tsx

└── (site)/
    ├── layout.tsx
    ├── page.tsx

    ├── about/
    ├── authors/
    ├── categories/

    └── posts/
        └── [slug]/
```

This gives us multiple architectural layers.

---

# The Root Layout

```text
app/layout.tsx
```

Responsible for:

```text
✓ HTML document
✓ Body
✓ Fonts
✓ Global styles
✓ Providers
✓ Theme system
✓ Metadata
```

---

# The Site Layout

```text
app/(site)/layout.tsx
```

Responsible for:

```text
✓ Header
✓ Footer
✓ Navigation
✓ Container
✓ Site-wide UI
```

---

# Visualizing the Application Tree

Our application eventually looks like this:

```text
Root Layout
     │
     ├── HTML
     ├── BODY
     ├── Theme Provider
     ├── Analytics Provider
     │
     └── Site Layout
              │
              ├── Header
              ├── Navigation
              ├── Main Content
              └── Footer
```

When the user navigates:

```text
/posts/react

        ↓

/posts/nextjs
```

Only this portion changes:

```text
Main Content
```

Everything else stays alive.

---

# Dynamic Routes

Most applications have URLs that are not known beforehand.

Examples:

```text
/posts/react-hooks
/posts/system-design
/posts/nextjs-16
```

We define these using square brackets:

```text
app/posts/[slug]/page.tsx
```

This tells Next.js:

> Match any value here.

---

# Understanding `[slug]`

Suppose the user visits:

```text
/posts/my-first-post
```

Next.js automatically provides:

```typescript
{
  slug: "my-first-post"
}
```

to our page component.

In modern Next.js:

```tsx
export default async function PostPage({
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

# Why Is `params` a Promise?

In older versions of Next.js:

```typescript
params.slug
```

In modern Next.js:

```typescript
await params
```

Why?

Because Next.js now supports:

```text
✓ Streaming
✓ Concurrent Rendering
✓ Partial Rendering
✓ Server Components
✓ Suspense
```

This allows Next.js to begin rendering immediately while other information is still loading.

Think of it like a restaurant:

```text
Old System

Prepare Entire Meal
        ↓
Serve Everything

New System

Serve Available Food
        ↓
Continue Cooking
        ↓
Serve Remaining Food
```

This creates faster applications.

---

# Understanding `Promise<T>`

Many beginners find this syntax confusing:

```typescript
Promise<{
  slug: string;
}>
```

The angle brackets:

```typescript
<>
```

are called:

```text
TypeScript Generics
```

Generics are templates for types.

Think of them as labels on boxes.

---

# The Box Analogy

Imagine three boxes:

```text
Promise<string>

Promise<number>

Promise<{ slug: string }>
```

When the box opens:

```text
Promise<string>
        ↓
     "hello"

Promise<number>
        ↓
        42

Promise<{ slug:string }>
        ↓

{
   slug: "react"
}
```

The generic tells TypeScript:

> "What do I expect to find inside this container?"

Without the generic:

```typescript
Promise
```

TypeScript cannot help us.

With the generic:

```typescript
Promise<{ slug:string }>
```

we gain:

```text
✓ Autocomplete
✓ Error checking
✓ Type safety
✓ Documentation
```

---

# Catch-All Routes

Sometimes a route contains multiple segments:

```text
/docs/react/hooks/useEffect
```

We use:

```text
app/docs/[...slug]/page.tsx
```

Example:

```typescript
{
  slug: [
    "react",
    "hooks",
    "useEffect"
  ]
}
```

---

# Optional Catch-All Routes

Sometimes we allow zero or more segments:

```text
/docs

/docs/react

/docs/react/hooks
```

We use:

```text
[[...slug]]
```

Example:

```typescript
slug === undefined

slug === ["react"]

slug === [
  "react",
  "hooks"
]
```

---

# The Real Power: Nested Layouts

Layouts can exist anywhere:

```text
app/

├── layout.tsx

└── (site)/
    ├── layout.tsx

    └── posts/
        ├── layout.tsx

        └── [slug]/
            └── page.tsx
```

Visualized:

```text
Root Layout
      │
      └── Site Layout
               │
               └── Posts Layout
                        │
                        └── Current Article
```

When navigating between posts:

```text
✓ Root Layout survives
✓ Site Layout survives
✓ Posts Layout survives
✓ Only article content changes
```

This gives us:

```text
✓ Preserved state
✓ Faster rendering
✓ Better performance
✓ Better user experience
```

---

# Understanding `globals.css`

Another file created by Next.js is:

```text
app/globals.css
```

This is not simply a CSS file.

It becomes the foundation of our design system.

Think of our application architecture:

```text
page.tsx
        =
Content

layout.tsx
        =
Structure

globals.css
        =
Visual Language
```

Throughout GreyMatter Journal, we will gradually evolve:

```text
globals.css

        ↓

Design Tokens

        ↓

Themes

        ↓

Typography

        ↓

Dark Mode

        ↓

Component Styling

        ↓

Design System
```

---

# The Mental Model To Remember Forever

Beginners think:

```text
Next.js
        =
Pages
```

Intermediate developers think:

```text
Next.js
        =
Routes
```

Professional engineers think:

```text
Next.js
        =
Persistent UI Trees

                +
Architectural Boundaries

                +
System Organization
```

Modern applications are not collections of pages.

They are systems of persistent user interfaces organized to help both computers and humans manage complexity.

---

# Up Next — Part 3: Understanding `app/layout.tsx`

In the next lesson, we'll explore:

* why every application needs a root layout
* how `<html>` and `<body>` work
* what `React.ReactNode` really means
* providers
* themes
* fonts
* metadata
* application shells
* persistent user interfaces
* the foundations of modern web architecture
