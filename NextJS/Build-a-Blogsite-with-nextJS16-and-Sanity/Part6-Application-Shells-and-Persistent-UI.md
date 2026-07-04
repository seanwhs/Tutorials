# **✅ Part 6 — Building Our First Real Layout**

# GreyMatter Journal

## Part 6 — Building Our First Real Layout: Route Groups, Application Shells, and Persistent UI

> **Goal of this lesson:** Build our first real application shell, understand route groups, and discover why modern applications are organized around persistent layouts rather than individual pages.

---

# We're Finally Building an Application

Up until now, GreyMatter Journal has looked like this:

```text
app/

├── layout.tsx
├── globals.css
└── page.tsx
```

This works.

But it doesn't resemble how modern applications are actually built.

Real applications have:

```text
Navigation

Headers

Footers

Sidebars

Themes

Authentication

Analytics

Persistent State
```

These elements do not belong to individual pages.

They belong to something much larger.

---

# Stop Thinking in Pages (Again)

Traditional websites taught us:

```text
Home Page

About Page

Contact Page

Blog Page
```

Each page owned everything:

```text
Page
    +
Header
    +
Footer
    +
Navigation
```

Modern applications work differently.

Consider:

* Gmail
* GitHub
* Notion
* Slack
* Linear

When navigating:

```text
Header
        stays

Navigation
        stays

Sidebar
        stays

Theme
        stays

Application state
        stays

Only content changes
```

This architecture is called:

```text
Application Shell
```

---

# What Is An Application Shell?

An application shell is the persistent user interface surrounding dynamic content.

Visually:

```text
Application Shell

    Header

    Navigation

    Sidebar

    Footer

            ↓

      Dynamic Content
```

The shell remains mounted.

Only the content changes.

This creates applications that feel:

```text
Fast

Continuous

Interactive

Stateful
```

This is precisely what Next.js layouts provide.

---

# The First Architectural Refactor

Our current application:

```text
app/

├── layout.tsx
├── page.tsx
```

will become:

```text
app/

├── layout.tsx
│
├── (site)/
│   └── page.tsx
│
└── api/
```

The first question most beginners ask is:

> Why are there parentheses?

---

# Understanding Route Groups

Folders wrapped in parentheses are called:

```text
Route Groups
```

For example:

```text
(site)
```

is a route group.

The important rule is:

> Route groups organize code but do not create URLs.

For example:

```text
app/

(site)/
    page.tsx
```

still produces:

```text
/
```

not:

```text
/site
```

Similarly:

```text
app/

(site)/
    about/
        page.tsx
```

produces:

```text
/about
```

not:

```text
/site/about
```

---

# Why Do Route Groups Exist?

Beginners often think folders exist to create URLs.

Professional engineers use folders to create:

```text
Boundaries

Responsibilities

Architectures

Subsystems
```

For example, a future application might contain:

```text
app/

├── (site)/
│
├── (auth)/
│
├── (dashboard)/
│
├── (admin)/
│
└── api/
```

Visually:

```text
Public Website
        ↓

Authentication
        ↓

Dashboard
        ↓

Administration
        ↓

API Layer
```

Each subsystem can have its own layouts, loading states, error boundaries, and architecture.

For GreyMatter Journal, however, we'll keep things simple:

```text
app/

├── layout.tsx
│
└── (site)/
```

---

# Moving Our Homepage

Move:

```text
app/page.tsx
```

to:

```text
app/(site)/page.tsx
```

Our application now becomes:

```text
app/

├── layout.tsx
├── globals.css
│
└── (site)/
    └── page.tsx
```

Nothing changes visually.

But architecturally, everything changes.

We've introduced our first application boundary.

---

# Creating Our First Nested Layout

Now create:

```text
app/(site)/layout.tsx
```

Remember what we learned in Part 3:

```text
Root Layout
        =
Infrastructure

Site Layout
        =
Application Shell

Page
        =
Content
```

---

# Building the Site Layout

Create:

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
          px-6
          py-12
        "
      >
        {children}
      </main>

      <Footer />
    </>
  );
}
```

Notice what this layout does:

```text
Header
       ✓

Footer
       ✓

Page Content
       ✓
```

Notice what it doesn't do:

```text
Blog Posts
       ✗

About Page
       ✗

Homepage Content
       ✗
```

The layout owns structure.

Pages own content.

---

# Visualizing The Layout Tree

When visiting:

```text
/
```

Next.js internally builds:

```tsx
<RootLayout>
  <SiteLayout>
    <HomePage />
  </SiteLayout>
</RootLayout>
```

Visually:

```text
Root Layout
        ↓

Site Layout

    Header

    Main

        Home Page

    Footer
```

---

# Creating The Components Directory

Now create:

```text
components/

└── layout/
    ├── Header.tsx
    └── Footer.tsx
```

We're beginning to separate:

```text
Architecture

from

Implementation
```

---

# Building The Header

Create:

```tsx
import Link
  from "next/link";

export default function Header() {
  return (
    <header
      className="
        border-b
        border-gray-200
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
          py-6
        "
      >
        <Link
          href="/"
          className="
            text-3xl
            font-bold
            tracking-tight
          "
        >
          GreyMatter Journal
        </Link>

        <nav
          className="
            flex
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

# Building The Footer

Create:

```tsx
export default function Footer() {
  return (
    <footer
      className="
        mt-24
        border-t
        bg-gray-50
        py-12
      "
    >
      <div
        className="
          mx-auto
          max-w-6xl
          px-6
          text-center
          text-sm
          text-gray-500
        "
      >
        © {new Date().getFullYear()}
        {" "}
        GreyMatter Journal
      </div>
    </footer>
  );
}
```

---

# What Happens During Navigation?

This is where the App Router becomes truly interesting.

Suppose we're viewing:

```text
/
```

and then navigate to:

```text
/about
```

What changes?

Beginners imagine:

```text
Destroy Everything
         ↓
Load Everything Again
```

But Next.js actually performs:

```text
Root Layout
        stays

Site Layout
        stays

Header
        stays

Footer
        stays

Only Page Content Changes
```

Visually:

```text
Before:

Header
Home Page
Footer

        ↓

After:

Header
About Page
Footer
```

This is why modern applications feel continuous.

---

# The Application Shell Pattern

We can now finally see the architecture we've been discussing since Part 3.

```text
Infrastructure

        ↓

Application Shell

        ↓

Persistent UI

        ↓

Dynamic Content
```

Or, more specifically:

```text
Root Layout
        ↓

Site Layout
        ↓

Header
Navigation
Footer
        ↓

Page Content
```

---

# The Correct Mental Model

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
Application

        =

Infrastructure

        +

Persistent Shell

        +

Dynamic Content
```

Or, in App Router terminology:

```text
Root Layout

        ↓

Nested Layouts

        ↓

Pages

        ↓

Components
```

---

# The Most Important Idea To Remember

Our application now consists of two different kinds of UI:

```text
Persistent UI
        +
Dynamic UI
```

More specifically:

```text
Header
        stays

Footer
        stays

Layout
        stays

Page
        changes
```

Modern web applications are not collections of pages.

They are persistent user interfaces designed to manage complexity, preserve state, and create seamless user experiences.

---

# Up Next — Part 7: Introducing Sanity CMS

Our application shell now exists.

Next, we'll build something even more important:

```text
Content
```

We'll introduce Sanity CMS and discover why professional applications separate:

```text
Content

from

Presentation
```

and why modern websites are increasingly becoming distributed information systems.
