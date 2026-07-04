# **✅ Part 15 — Layouts, Route Groups, and Persistent User Interfaces**

# GreyMatter Journal

## Part 15 — Layouts, Navigation, and the Architecture of Persistent User Interfaces

> **Goal of this lesson:** Build the persistent application shell for GreyMatter Journal, understand how route groups and nested layouts work together, and learn why modern web applications are fundamentally composed as persistent UI trees.

---

# We've Built Pages. Now We Build an Application.

At this point, GreyMatter Journal has:

* A content management system
* Dynamic routes
* Rich text rendering
* Optimized images
* Server-side data fetching

Yet something still feels incomplete.

Our application has pages.

What it does not yet have is a true application shell.

---

# The Old Web Was Built from Pages

Traditional websites looked like this:

```text
home.html

about.html

posts.html

article.html
```

When users navigated:

```text
Current Page
        ↓
Destroyed
        ↓
Browser Request
        ↓
New Page
        ↓
Rendered
```

Everything disappeared.

Everything reloaded.

Everything restarted.

---

# Modern Applications Work Differently

Open applications you use every day:

* GitHub
* Notion
* Gmail
* Linear
* Slack

When navigating:

```text
Navigation
        stays

Theme
        stays

Application state
        stays

Sidebar
        stays

Header
        stays

Only the content changes
```

This leads us to one of the most important ideas in modern frontend architecture:

> Applications are not collections of pages.

They are persistent user interface trees.

---

# The GreyMatter Journal Architecture

Our current application structure looks like this:

```text
greymatter-journal/

app/

├── layout.tsx
│
├── (site)/
│   ├── layout.tsx
│   ├── page.tsx
│   │
│   ├── about/
│   │   └── page.tsx
│   │
│   └── posts/
│       ├── page.tsx
│       └── [slug]/
│           └── page.tsx
```

Notice something important:

```text
(site)
```

does not appear in the URL.

Instead, it acts as an organizational and architectural boundary.

---

# Why Route Groups Exist

Suppose we eventually build:

```text
Public Website

Admin Dashboard

Authentication Pages
```

Without route groups:

```text
app/

about/
posts/
dashboard/
login/
register/
settings/
admin/
analytics/
```

The application becomes difficult to understand.

Instead:

```text
app/

(site)/
(auth)/
(admin)/
```

gives us:

```text
Architecture
        =
Folder Structure
```

This is one of the major strengths of the App Router.

---

# Our Layout Hierarchy

GreyMatter Journal uses two primary layouts:

```text
Root Layout
        ↓
Site Layout
        ↓
Page
```

Visually:

```text
Root Layout

    Providers

        Site Layout

            Header

            Navigation

            Footer

                Page
```

The root layout manages infrastructure.

The site layout manages visible UI.

---

# The Root Layout

Open:

```text
app/layout.tsx
```

Our root layout remains intentionally simple:

```tsx
import type { Metadata }
  from "next";

import "./globals.css";

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
    <html
      lang="en"
      suppressHydrationWarning
    >
      <body
        className="
          bg-white
          text-gray-900
          antialiased
        "
      >
        {children}
      </body>
    </html>
  );
}
```

Notice:

```text
No navigation.

No header.

No footer.
```

Those belong elsewhere.

---

# Building Our Site Layout

Create:

```text
app/(site)/layout.tsx
```

```tsx
import Header
  from "@/components/layout/Header";

import Footer
  from "@/components/layout/Footer";

export default function SiteLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <Header />

      <main
        className="
          mx-auto
          max-w-6xl
          px-4
          py-10
        "
      >
        {children}
      </main>

      <Footer />
    </>
  );
}
```

This creates our persistent shell:

```text
Header
       +
Main Content
       +
Footer
```

---

# Creating the Header

Create:

```text
components/layout/Header.tsx
```

```tsx
import Link
  from "next/link";

export default function Header() {
  return (
    <header
      className="
        sticky
        top-0
        z-50
        border-b
        bg-white/90
        backdrop-blur
      "
    >
      <div
        className="
          mx-auto
          flex
          max-w-6xl
          items-center
          justify-between
          px-6
          py-5
        "
      >
        <Link
          href="/"
          className="
            text-2xl
            font-bold
            tracking-tight
          "
        >
          GreyMatter Journal
        </Link>

        <nav
          className="
            flex
            items-center
            gap-8
            text-sm
            font-medium
          "
        >
          <Link
            href="/"
            className="
              transition-colors
              hover:text-gray-600
            "
          >
            Home
          </Link>

          <Link
            href="/posts"
            className="
              transition-colors
              hover:text-gray-600
            "
          >
            Posts
          </Link>

          <Link
            href="/about"
            className="
              transition-colors
              hover:text-gray-600
            "
          >
            About
          </Link>
        </nav>
      </div>
    </header>
  );
}
```

---

# Creating the Footer

Create:

```text
components/layout/Footer.tsx
```

```tsx
export default function Footer() {
  return (
    <footer
      className="
        mt-24
        border-t
      "
    >
      <div
        className="
          mx-auto
          max-w-6xl
          px-6
          py-12
          text-center
          text-sm
          text-gray-500
        "
      >
        © {new Date().getFullYear()}
        {" "}
        GreyMatter Journal.

        Built with Next.js
        and Sanity.
      </div>
    </footer>
  );
}
```

---

# Why Not Put Header in Root Layout?

Many beginners naturally write:

```text
Root Layout

    Header

    Footer

    Pages
```

This works initially.

However, consider future expansion:

```text
(site)

(auth)

(admin)
```

Should login pages show the blog navigation?

```text
No.
```

Should the admin dashboard use the public footer?

```text
No.
```

By moving visual structure into route-group layouts:

```text
Root Layout
       =
Infrastructure

Route Layout
       =
User Experience
```

we gain architectural flexibility.

---

# What Actually Happens During Navigation?

Suppose we navigate:

```text
/posts/react
```

to:

```text
/posts/nextjs
```

Next.js does not destroy everything.

Instead:

```text
Root Layout
        stays

Site Layout
        stays

Header
        stays

Footer
        stays

Only:

Post Page
        changes
```

Visually:

```text
Before:

Root
 └── Site
      └── Post A


After:

Root
 └── Site
      └── Post B
```

Only the leaf node changes.

---

# Why This Feels Fast

Traditional navigation:

```text
Destroy Everything
         ↓
Download Everything
         ↓
Render Everything
```

Modern navigation:

```text
Keep Everything
        ↓
Replace One Node
        ↓
Render Minimal Changes
```

This provides:

* Faster navigation
* Less JavaScript execution
* Preserved state
* Reduced network activity
* Better user experience

---

# React, Routing, and Trees

Throughout this course, we've repeatedly discovered:

```text
React
      =
Tree

Router
      =
Tree

Layouts
      =
Tree

Portable Text
      =
Tree

File System
      =
Tree
```

This is not accidental.

Modern software systems are fundamentally hierarchical.

---

# The Deep Mental Model

Beginners think:

```text
Page

    +
Header

    +
Footer
```

Professional engineers think:

```text
Infrastructure
        ↓

Providers
        ↓

Application Shell
        ↓

Persistent Layout Tree
        ↓

Dynamic Route Tree
        ↓

Component Tree
```

More concretely:

```text
Application

       =
Root Layout

       +
Route Group Layouts

       +
Nested Layouts

       +
Pages

       +
Components
```

---

# Mental Model To Remember Forever

Traditional web development:

```text
Website
      =
Collection of Pages
```

Modern application architecture:

```text
Application
       =
Persistent UI Tree
       +
Dynamic Data
```

Or more fundamentally:

```text
Layout Tree
       +
Route Tree
       +
Component Tree
       +
Data Tree
```

Everything in modern frontend architecture is ultimately a composition of trees.

---

# Up Next — Part 16: Search, Filtering, and URL State

We'll implement one of the most important features of any publication platform:

* Search
* Category filtering
* Query parameters
* URL state
* Server-side filtering
* GROQ query composition
* Why URLs are part of your application's public API

This is where GreyMatter Journal begins to behave like a true information retrieval system.
