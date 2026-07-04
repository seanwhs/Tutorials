# **Part 2 — Understanding the App Router**

# GreyMatter Journal

## Part 2 — Understanding the App Router: Why Modern Web Applications Are Not Collections of Pages

> **Goal of this lesson:** Understand the **Next.js App Router**, learn why folders become routes, discover the roles of `page.tsx` and `layout.tsx`, and develop the mental model that modern web applications are built as **persistent UI trees**, not collections of disconnected pages.

---

# The Biggest Mental Shift in Next.js

When most developers first learn web development, they are taught to think in terms of **pages**.

A website looks like a collection of files:

```text
home.html
about.html
blog.html
contact.html
```

Clicking a link traditionally meant:

```text
Destroy old page
        ↓
Request new page
        ↓
Load everything again
        ↓
Render entire page
```

This model worked well for traditional websites.

However, modern applications don't behave this way.

Think about applications you use every day:

* Gmail
* Notion
* GitHub
* Linear
* Slack
* Discord

When you navigate between screens, the entire application does not disappear and reload.

Instead, most of the interface remains stable.

---

# What Actually Changes?

Consider GitHub:

```text
GitHub
├── Header
├── Left Navigation
├── Repository Navigation
└── Content Area
```

When you click:

```text
Issues
    ↓
Pull Requests
    ↓
Actions
```

What changes?

```text
✓ Content Area
```

What remains?

```text
✓ Header
✓ Navigation
✓ User Session
✓ Theme
✓ Application State
```

The application feels continuous.

This is the fundamental insight behind the **App Router**.

---

# Traditional Websites vs Modern Applications

| Traditional Websites | Modern Applications |
| -------------------- | ------------------- |
| Full page reload     | Partial updates     |
| Entire page replaced | UI tree updated     |
| State lost           | State preserved     |
| Duplicate layouts    | Shared layouts      |
| Slower navigation    | Instant navigation  |
| Page-oriented        | Component-oriented  |

---

# The App Router Philosophy

The App Router changes the question from:

> "Which page should I load?"

to:

> "Which parts of the interface actually need to change?"

This may sound like a small difference.

Architecturally, it changes everything.

Instead of thinking:

```text
Website
    =
Pages
```

we begin thinking:

```text
Application
    =
Persistent UI Tree
```

---

# What Is the App Router?

The App Router is a routing system based on the file system.

Your folders become your URLs.

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

No route configuration is required.

The folder structure itself becomes the routing system.

This concept is called:

```text
File-System Routing
```

---

# Folders Become Routes

Consider the following structure:

```text
app/
├── page.tsx
├── about/
│   └── page.tsx
├── posts/
│   ├── page.tsx
│   └── [slug]/
│       └── page.tsx
```

This produces:

| File                        | URL                    |
| --------------------------- | ---------------------- |
| `app/page.tsx`              | `/`                    |
| `app/about/page.tsx`        | `/about`               |
| `app/posts/page.tsx`        | `/posts`               |
| `app/posts/[slug]/page.tsx` | `/posts/my-first-post` |

---

# Dynamic Routes

Sometimes we don't know the URL beforehand.

For example:

```text
/posts/react-hooks
/posts/nextjs-app-router
/posts/system-design
```

Creating a file for every post would be impossible.

Instead, we create a dynamic segment:

```text
app/posts/[slug]/page.tsx
```

The square brackets tell Next.js:

> "Match any value here."

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

to your page component.

In modern Next.js (15+), route parameters are asynchronous:

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

  return <h1>{slug}</h1>;
}
```

---

# Why Is `params` a Promise?

This surprises almost everyone learning modern Next.js.

Older versions worked like this:

```typescript
params.slug
```

Modern Next.js works like this:

```typescript
await params
```

Why?

Because Next.js now optimizes rendering using:

* streaming
* concurrent rendering
* partial page generation
* asynchronous server components

This allows Next.js to begin rendering parts of the page immediately while other information is still being prepared.

Think of it like a restaurant:

```text
Old system:
Wait for entire meal
        ↓
Serve everything

New system:
Serve appetizers
        ↓
Prepare remaining dishes
        ↓
Serve continuously
```

This creates faster applications.

---

# Understanding `Promise<T>`

Many beginners get confused by this syntax:

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

# Analogy: Labeled Boxes

Imagine three boxes:

```text
Promise<string>

Promise<number>

Promise<{ slug: string }>
```

Each box contains different data.

```text
Promise<string>
        ↓
     "hello"

Promise<number>
        ↓
        42

Promise<{ slug: string }>
        ↓
{
  slug: "react"
}
```

The generic tells TypeScript:

> "When I open this box, what should I expect to find?"

Without the generic:

```typescript
Promise
```

TypeScript has no idea what is inside.

With the generic:

```typescript
Promise<{ slug: string }>
```

TypeScript now understands:

* autocomplete
* error checking
* type validation
* code navigation

---

# Catch-All Routes

Sometimes a route contains many segments.

For example:

```text
/docs/react/hooks/useEffect
```

We can capture all segments:

```text
app/docs/[...slug]/page.tsx
```

Example:

```tsx
export default async function DocsPage({
  params,
}: {
  params: Promise<{
    slug: string[];
  }>;
}) {
  const { slug } =
    await params;

  return (
    <pre>
      {JSON.stringify(slug)}
    </pre>
  );
}
```

Result:

```text
[
  "react",
  "hooks",
  "useEffect"
]
```

---

# Optional Catch-All Routes

Sometimes the route may contain zero or more segments:

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

```text
app/docs/[[...slug]]/page.tsx
```

Possible values:

```text
undefined

["react"]

["react", "hooks"]
```

---

# Route Groups

Folders wrapped in parentheses:

```text
(site)
(admin)
(auth)
```

do not affect the URL.

Example:

```text
app/
└── (site)/
    └── about/
        └── page.tsx
```

still produces:

```text
/about
```

Route groups exist purely for organization.

Think of them as folders for humans, not for browsers.

---

# `page.tsx` — The Content

Every route requires a page.

```tsx
export default function HomePage() {
  return (
    <div>
      <h1>
        GreyMatter Journal
      </h1>

      <p>
        Exploring software
        engineering and
        systems thinking.
      </p>
    </div>
  );
}
```

Think of:

```text
page.tsx
        =
Current Screen
```

---

# `layout.tsx` — The Persistent Shell

Layouts remain mounted while navigating.

```tsx
export default function RootLayout({
  children,
}: {
  children:
    React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>

        <nav>
          Navigation
        </nav>

        {children}

        <footer>
          Footer
        </footer>

      </body>
    </html>
  );
}
```

Think of:

```text
layout.tsx
        =
Application Shell
```

---

# What Is `children`?

Another concept that confuses beginners is:

```tsx
{children}
```

The `children` prop means:

> "Insert whatever page is currently active here."

Example:

```text
Layout
   ↓

Header

{children}

Footer
```

If the current page is:

```text
/about
```

Then Next.js produces:

```text
Header

About Page

Footer
```

If the user navigates to:

```text
/posts
```

Next.js produces:

```text
Header

Posts Page

Footer
```

The layout never disappears.

Only the content changes.

---

# Understanding `React.ReactNode`

You will often see:

```typescript
children: React.ReactNode
```

This simply means:

> "Anything React knows how to display."

Examples include:

```typescript
<string>

<number>

<div>

<Component />

arrays

fragments
```

Think of:

```text
ReactNode
        =
Anything renderable
```

---

# Understanding `globals.css`

Another important file is:

```text
app/globals.css
```

This file defines the visual foundation of your application.

Think of the three core files:

```text
page.tsx
        =
Page Content

layout.tsx
        =
Application Structure

globals.css
        =
Visual Language
```

Example:

```css
@import "tailwindcss";

:root {
  --background: white;
  --foreground: #171717;
}

body {
  background:
    var(--background);

  color:
    var(--foreground);

  font-family:
    Inter,
    sans-serif;
}
```

This introduces several important concepts:

* global styling
* design tokens
* CSS variables
* typography systems
* theming
* design systems

---

# Nested Layouts

Layouts can exist anywhere.

```text
app/
├── layout.tsx
│
└── posts/
    ├── layout.tsx
    └── [slug]/
        └── page.tsx
```

Visualized:

```text
Root Layout
    │
    ├── Header
    │
    └── Posts Layout
            │
            ├── Sidebar
            │
            └── Current Post
```

When navigating between posts:

```text
✓ Header remains
✓ Sidebar remains
✓ State remains
✓ Only post content changes
```

This creates:

* better performance
* preserved state
* less JavaScript execution
* smoother user experiences

---

# GreyMatter Journal Architecture

Our final structure will look like:

```text
app/
├── (site)/
│   ├── page.tsx
│   ├── about/
│   └── posts/
│       └── [slug]/
│
├── globals.css
└── layout.tsx
```

This gives us:

```text
Global Application Shell
            ↓
Site Layout
            ↓
Feature Layouts
            ↓
Page Components
            ↓
Child Components
```

---

# The Mental Model To Remember Forever

Beginners think:

```text
Next.js
        =
Pages
```

Professional engineers think:

```text
Next.js
        =
Persistent UI Tree

            ↓

Application Shell

            ↓

Nested Layouts

            ↓

Current Page

            ↓

Child Components
```

Modern web applications are not collections of pages.

They are living user interfaces where stable pieces remain mounted while only the changing pieces update.

That single mental model explains almost everything in the App Router.

---

# Up Next — Part 3: Understanding `app/layout.tsx`

In the next lesson, we will explore:

* why every Next.js application requires a root layout
* how `<html>` and `<body>` work
* what `React.ReactNode` really means
* how providers work
* how themes work
* how fonts work
* how modern applications build persistent application shells
