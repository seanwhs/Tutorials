# Part 2 — Understanding the App Router

# GreyMatter Journal

## Part 2 — Understanding the App Router: Why Modern Web Applications Are Not Collections of Pages

> **Goal of this lesson:** Understand the philosophy behind the Next.js App Router, learn why folders become routes, discover how `page.tsx` and `layout.tsx` work together, and develop the mental model that modern web applications are persistent UI trees rather than collections of independent pages.

---

# The Biggest Mental Shift in Modern Web Development

When most people first learn web development, they learn to think in terms of **pages**.

A website looks something like this:

```text
home.html
about.html
blog.html
contact.html
```

When a user clicks a link:

```text
Current Page
      ↓
Destroy Everything
      ↓
Load New HTML
      ↓
Render Again
```

Every page visit starts from zero.

This model worked well for decades because websites were primarily collections of documents.

---

# But Modern Applications Don't Feel Like Websites

Open applications such as:

* Gmail
* Notion
* GitHub
* Linear
* Slack
* Figma

When you navigate around these applications, something interesting happens.

The application never feels like it disappears and reloads.

Instead, most of the interface remains stable.

What stays:

```text
✓ Navigation
✓ Sidebar
✓ Theme
✓ User Session
✓ Application State
✓ Notifications
✓ Search
```

What changes:

```text
✓ Only the content area
```

The experience feels continuous.

This is the fundamental insight behind the **Next.js App Router**.

---

# Traditional Websites vs Modern Applications

| Traditional Websites | Modern Applications     |
| -------------------- | ----------------------- |
| Full page reload     | Partial UI updates      |
| State destroyed      | State preserved         |
| Layout duplicated    | Layout shared           |
| Browser-driven       | Component-driven        |
| Document navigation  | UI tree updates         |
| Slower               | Faster                  |
| Feels like websites  | Feels like applications |

---

# The Fundamental Question Changed

Traditional routing asks:

> Which page should I load?

Modern routing asks:

> Which parts of my user interface should change?

This sounds like a small difference.

It is actually an entirely different philosophy of application architecture.

---

# The App Router Philosophy

The App Router treats your application as a tree of user interfaces.

Instead of:

```text
Website = Pages
```

Next.js thinks:

```text
Application = Persistent UI Tree
```

For example:

```text
Application

    Root Layout
          │
          ├── Navigation
          │
          ├── Sidebar
          │
          └── Content
                    │
                    └── Current Page
```

When navigation occurs:

```text
Navigation = UNCHANGED

Sidebar = UNCHANGED

Content = UPDATED
```

Only the portions of the interface that actually changed are replaced.

This creates:

* Faster navigation
* Less JavaScript execution
* Preserved state
* Better user experience
* Reduced server work

---

# File System Routing

The App Router uses your folder structure to define routes.

This concept is called:

```text
File-System Routing
```

In other words:

```text
Folders = URLs
```

For example:

```text
app/

├── page.tsx
├── about/
│   └── page.tsx
└── posts/
    └── page.tsx
```

Automatically becomes:

```text
/
      ↓

/about
      ↓

/posts
```

You never configure routes manually.

The filesystem itself becomes the router.

---

# Route Mapping

| File Structure                  | URL                           |
| ------------------------------- | ----------------------------- |
| `app/page.tsx`                  | `/`                           |
| `app/about/page.tsx`            | `/about`                      |
| `app/posts/page.tsx`            | `/posts`                      |
| `app/posts/[slug]/page.tsx`     | `/posts/my-post`              |
| `app/category/[name]/page.tsx`  | `/category/react`             |
| `app/docs/[...slug]/page.tsx`   | `/docs/react/hooks/useEffect` |
| `app/docs/[[...slug]]/page.tsx` | `/docs` or nested docs        |

---

# Dynamic Routes

Sometimes the URL isn't fixed.

For example:

```text
/posts/react-hooks
/posts/nextjs-16
/posts/server-components
```

You obviously cannot create:

```text
react-hooks.html
nextjs-16.html
server-components.html
```

Instead, Next.js uses dynamic segments.

---

## Single Dynamic Segment

```text
app/posts/[slug]/page.tsx
```

matches:

```text
/posts/react-hooks

/posts/nextjs-16

/posts/server-components
```

The value inside the brackets becomes a parameter.

---

# Understanding the Modern Next.js Route Parameters

In Next.js 15+ and Next.js 16, route parameters are asynchronous.

This is one of the biggest changes from older tutorials.

Consider:

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
    <h1>
      {slug}
    </h1>
  );
}
```

This syntax can initially look intimidating.

Let's break it apart.

---

## Step 1 — The Component Is Async

```tsx
export default async function PostPage()
```

Why?

Because modern Next.js allows parts of the page to wait for asynchronous information without blocking the entire page render.

This enables:

```text
Streaming
+
Suspense
+
Progressive Rendering
```

---

## Step 2 — Understanding `params`

In older versions of Next.js:

```tsx
params: {
  slug: string;
}
```

In modern Next.js:

```tsx
params: Promise<{
  slug: string;
}>
```

The route parameters are now provided asynchronously.

---

## Step 3 — Awaiting the Parameters

Since `params` is a Promise:

```tsx
const { slug } =
  await params;
```

After awaiting:

```text
{
  slug: "react-hooks"
}
```

becomes:

```text
slug = "react-hooks"
```

---

# Why Did Next.js Change This?

The answer is performance.

Modern React applications are built around the idea of:

```text
Don't block the entire page
while waiting for one thing.
```

Instead:

```text
Start rendering immediately

        ↓

Pause only where necessary

        ↓

Stream remaining content later
```

This enables:

* Better performance
* Better streaming
* Faster first paint
* Improved server rendering
* Better Suspense integration

---

# Catch-All Routes

Sometimes you don't know how many URL segments will exist.

Example:

```text
/docs/react/hooks/useEffect
```

You can use:

```text
[...slug]
```

Example:

```text
app/docs/[...slug]/page.tsx
```

This captures:

```text
[
  "react",
  "hooks",
  "useEffect"
]
```

---

# Optional Catch-All Routes

Sometimes there may be no segments.

Example:

```text
/docs

/docs/react

/docs/react/hooks
```

You can use:

```text
[[...slug]]
```

Possible values become:

```text
undefined

["react"]

["react", "hooks"]
```

---

# Route Groups

Sometimes folders exist only to organize code.

Example:

```text
app/

├── (site)
├── (admin)
└── (auth)
```

The parentheses tell Next.js:

> This folder exists for organization only.

For example:

```text
app/(site)/about/page.tsx
```

still becomes:

```text
/about
```

The `(site)` folder never appears in the URL.

---

# The Two Most Important Files

The App Router only has two fundamental building blocks.

---

## `page.tsx`

Think of:

```text
page.tsx
        =
Current Screen
```

Example:

```tsx
export default function HomePage() {
  return (
    <>
      <h1>
        GreyMatter Journal
      </h1>

      <p>
        Exploring software
        engineering and
        systems thinking.
      </p>
    </>
  );
}
```

---

## `layout.tsx`

Think of:

```text
layout.tsx
        =
Persistent UI
```

Example:

```tsx
export default function RootLayout({
  children,
}: {
  children:
    React.ReactNode;
}) {
  return (
    <html>
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

---

# What Is `children`?

This is one of the most important concepts in React.

Think of:

```text
children
        =
The thing inserted here
```

For example:

```text
Layout

   Header

   {children}

   Footer
```

When visiting:

```text
/about
```

Next.js effectively builds:

```text
Header

About Page

Footer
```

When visiting:

```text
/posts
```

Next.js builds:

```text
Header

Posts Page

Footer
```

The layout never changes.

Only the children change.

---

# Nested Layouts: The Secret Sauce

Consider:

```text
app/

├── layout.tsx

└── posts/
    ├── layout.tsx
    └── page.tsx
```

This creates:

```text
Root Layout
      │
      ├── Navigation
      │
      └── Posts Layout
              │
              ├── Sidebar
              │
              └── Posts Page
```

When navigating between posts:

```text
Navigation
        =
STAYS

Sidebar
        =
STAYS

Page Content
        =
CHANGES
```

This is why modern applications feel instantaneous.

---

# Understanding `globals.css`

Another important file is:

```text
app/globals.css
```

Think of it as:

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

Example:

```css
@import "tailwindcss";

:root {
  --background:
    #ffffff;

  --foreground:
    #171717;
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

This file becomes the foundation of your:

* Design tokens
* Themes
* Typography
* Colors
* Layout rules
* Design system

---

# The GreyMatter Journal Structure

Eventually our project will evolve into:

```text
app/

├── layout.tsx
│
├── globals.css
│
└── (site)/
    ├── page.tsx
    │
    ├── about/
    │   └── page.tsx
    │
    └── posts/
        ├── page.tsx
        │
        └── [slug]/
            └── page.tsx
```

This structure gives us:

```text
Scalability
+
Maintainability
+
Performance
+
Clear Architecture
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
```

More specifically:

```text
Root Layout
       ↓

Nested Layouts
       ↓

Page
       ↓

Components
       ↓

State
       ↓

User Experience
```

Modern web applications are not collections of pages.

They are living, persistent user interface trees where stable parts remain and only changing parts are replaced efficiently.

---

# Up Next — Part 3: Understanding `app/layout.tsx`

In the next lesson, we'll explore:

* Why every Next.js application requires a Root Layout
* What `<html>` and `<body>` really do
* What `React.ReactNode` actually means
* How `children` works
* Where providers belong
* How global styling works
* How GreyMatter Journal builds its application shell
