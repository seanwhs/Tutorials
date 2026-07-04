# GreyMatter Journal

## Part 15 — Layouts, Navigation, and Persistent UI: Understanding Application Shells and UI Trees

> **Goal of this lesson:** Build a professional navigation system while developing a deep understanding of why modern web applications are architected as persistent user interface trees rather than collections of independent pages.

---

# The Great Shift in Web Architecture

For most of the history of the web, websites were built as collections of separate documents.

When a user navigated from one page to another, the browser would destroy everything and load an entirely new document.

```text
Request Page A
      ↓
Render Page A
      ↓
Destroy Page A
      ↓
Request Page B
      ↓
Render Page B
```

This model worked well for documents.

It works poorly for applications.

Modern applications feel different because they follow a completely different architectural model.

Instead of rebuilding the entire interface on every navigation, they preserve most of the application and replace only the parts that actually changed.

```text
Persistent Application Shell
              +
       Dynamic Content
```

This is one of the foundational ideas behind the Next.js App Router.

---

# Applications Are Not Collections of Pages

Consider applications you use every day.

### YouTube

```text
Header
   +
Sidebar
   +
Video Player
   +
Comments
```

When you click another video:

```text
Header         stays
Sidebar        stays
Navigation     stays
Video          changes
Comments        change
```

---

### GitHub

```text
Global Navigation
        +
Repository Header
        +
Current Tab Content
```

When moving from:

```text
Issues
```

to:

```text
Pull Requests
```

GitHub does not destroy the entire interface.

Only part of the tree changes.

---

### Notion

```text
Workspace
      +
Sidebar
      +
Current Document
```

The workspace persists.

Only the document changes.

---

# The Application Shell Pattern

This architectural approach is called the **Application Shell Pattern**.

An application shell contains the persistent parts of the user interface:

```text
Navigation
Header
Sidebar
Footer
Theme
Global State
Providers
```

while the content area changes dynamically.

```text
Application Shell
        +
Route Content
```

GreyMatter Journal follows exactly the same pattern.

---

# Designing the GreyMatter Journal Shell

Our application shell will contain:

```text
Header
     ↓
Navigation
     ↓
Main Content
     ↓
Footer
```

Visually:

```text
┌─────────────────────────┐
│      Header/Nav         │
├─────────────────────────┤
│                         │
│       Content           │
│                         │
├─────────────────────────┤
│        Footer           │
└─────────────────────────┘
```

---

# Step 1 — Create the Navigation Component

Create:

```text
components/layout/Navigation.tsx
```

```tsx
import Link from "next/link";

export default function Navigation() {
  return (
    <nav className="border-b border-gray-200 bg-white sticky top-0 z-50">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
        <Link
          href="/"
          className="text-2xl font-bold tracking-tight"
        >
          GreyMatter Journal
        </Link>

        <div className="flex items-center gap-8 text-sm font-medium">
          <Link
            href="/"
            className="transition-colors hover:text-gray-600"
          >
            Home
          </Link>

          <Link
            href="/posts"
            className="transition-colors hover:text-gray-600"
          >
            Posts
          </Link>

          <Link
            href="/categories"
            className="transition-colors hover:text-gray-600"
          >
            Categories
          </Link>

          <Link
            href="/search"
            className="transition-colors hover:text-gray-600"
          >
            Search
          </Link>

          <Link
            href="/about"
            className="transition-colors hover:text-gray-600"
          >
            About
          </Link>
        </div>
      </div>
    </nav>
  );
}
```

---

# Step 2 — Create the Footer

Create:

```text
components/layout/Footer.tsx
```

```tsx
export default function Footer() {
  return (
    <footer className="mt-24 border-t border-gray-200 bg-gray-50">
      <div className="mx-auto max-w-6xl px-6 py-12 text-center text-sm text-gray-500">
        © {new Date().getFullYear()} GreyMatter Journal.
        Built with Next.js 16 and Sanity.
      </div>
    </footer>
  );
}
```

---

# Step 3 — Update the Root Layout

Open:

```text
app/layout.tsx
```

```tsx
import type { Metadata } from "next";

import "./globals.css";

import Navigation from "@/components/layout/Navigation";
import Footer from "@/components/layout/Footer";

export const metadata: Metadata = {
  title: "GreyMatter Journal",
  description:
    "Exploring software engineering, systems thinking, and architecture.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-white text-gray-900 antialiased">
        <Navigation />

        <main className="min-h-screen">
          {children}
        </main>

        <Footer />
      </body>
    </html>
  );
}
```

---

# What Actually Happens During Navigation?

Suppose the user moves from:

```text
/posts/nextjs-16
```

to:

```text
/posts/react-server-components
```

Many beginners imagine this:

```text
Destroy Everything
        ↓
Rebuild Everything
```

But that is not what happens.

Instead:

```text
RootLayout
     │
     ├── Navigation
     │
     ├── Current Page
     │
     └── Footer
```

becomes:

```text
RootLayout
     │
     ├── Navigation
     │
     ├── New Page
     │
     └── Footer
```

Notice what changed:

```text
Navigation   → stays
Footer       → stays
Page         → changes
```

The application shell persists.

---

# Why `next/link` Exists

You may wonder why we use:

```tsx
<Link href="/posts">
```

instead of:

```html
<a href="/posts">
```

The answer is architectural.

### Traditional HTML

```text
Click Link
      ↓
Browser Request
      ↓
Destroy Document
      ↓
Download New Page
      ↓
Render Again
```

---

### Next.js Navigation

```text
Click Link
      ↓
Prefetch Route
      ↓
Keep Layout Tree
      ↓
Replace Route Segment
      ↓
Update UI
```

This provides:

* Faster navigation
* Less JavaScript execution
* Reduced network traffic
* Preserved state
* Better user experience

---

# Persistent UI Means Persistent State

Suppose we add a theme toggle:

```text
Dark Mode
```

If the layout remained persistent:

```text
Dark Mode
        ↓
Navigate
        ↓
Dark Mode remains
```

If the entire application reloaded:

```text
Dark Mode
        ↓
Navigate
        ↓
Dark Mode lost
```

Persistence is not just about performance.

It is about preserving user context.

---

# Layouts Form a Tree

As our application grows, our layouts become hierarchical.

```text
Root Layout
      │
      └── Site Layout
              │
              └── Posts Layout
                      │
                      └── Article Page
```

Every level provides additional context.

For example:

```text
Root Layout
     =
Global Shell

Site Layout
     =
Site Navigation

Posts Layout
     =
Blog Navigation

Article Page
     =
Actual Content
```

This is why the App Router feels so natural.

The folder structure mirrors the UI structure.

---

# The Deep Idea: Applications Are Trees of Trees

By now, we have encountered many different kinds of trees:

```text
File System Tree

Route Tree

React Component Tree

Layout Tree

Portable Text Tree

DOM Tree
```

These are not separate ideas.

Modern software is largely the art of organizing and traversing trees.

A Next.js application can be viewed as:

```text
Application
        =
Tree of Trees
```

More specifically:

```text
Application
      =
Route Tree
           +
Layout Tree
           +
Component Tree
           +
Content Tree
```

This perspective explains much of modern frontend architecture.

---

# Mental Model To Remember Forever

Beginners think:

```text
Website
     =
Pages
```

Modern engineers think:

```text
Application
      =
Persistent UI Tree
             +
Dynamic Data
```

Or more fundamentally:

```text
Application
      =
Composition of Persistent Structures
```

The App Router is not a page system.

It is a system for managing persistent trees.

---

# Up Next — Part 16: Search, Filtering, and Information Retrieval

We'll implement:

* Full-text search
* Category filtering
* URL-based state
* GROQ queries
* Information retrieval concepts
* Search as data transformation

This is where GreyMatter Journal begins to evolve from a publication into an information retrieval system.
