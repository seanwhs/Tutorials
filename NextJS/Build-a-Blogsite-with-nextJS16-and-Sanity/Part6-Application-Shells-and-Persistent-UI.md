# **✅ Part 6 — Building Our First Real Layout**

# GreyMatter Journal

## Part 6 — Building Our First Real Layout: Route Groups, Application Shells, and Persistent UI

> **Goal of this lesson:** Create our first real application shell, introduce Next.js Route Groups, and understand why modern applications are built from persistent layouts rather than individual pages.

---

# We've Reached An Important Architectural Moment

Up until now, our application has been extremely simple:

```text
app/

├── layout.tsx
└── page.tsx
```

This works.

But it doesn't reflect how real applications are structured.

Remember what we learned in Part 3:

```text
Root Layout
        =
Infrastructure

Site Layout
        =
Application Shell
```

The root layout should manage:

* HTML document structure
* global styles
* providers
* metadata
* application infrastructure

The visible user interface should live somewhere else.

---

# Introducing Route Groups

Next.js provides a feature called **Route Groups**.

A route group is simply a folder wrapped in parentheses:

```text
(site)
```

For example:

```text
app/

└── (site)/
```

This folder behaves differently from normal folders.

Normally:

```text
app/about/page.tsx
        ↓
/about
```

But with a route group:

```text
app/(site)/about/page.tsx
        ↓
/about
```

The `(site)` folder disappears from the URL.

---

# Why Use Route Groups?

Suppose our application eventually grows into:

```text
Public Website

Administration Dashboard

Authentication Pages

API Endpoints
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
```

Everything becomes mixed together.

With route groups:

```text
app/

(site)/
(auth)/
(admin)/
api/
```

Our application becomes much easier to understand.

---

# Our Target Architecture

Eventually, GreyMatter Journal will look like this:

```text
app/

├── layout.tsx
├── globals.css

├── (site)/
│   ├── layout.tsx
│   ├── page.tsx
│   ├── about/
│   └── posts/

└── api/
```

Today we'll build the first piece of that architecture.

---

# Step 1 — Create The Route Group

Create the following structure:

```text
app/

├── layout.tsx
├── globals.css

└── (site)/
    └── page.tsx
```

Move your existing homepage:

```text
app/page.tsx
```

into:

```text
app/(site)/page.tsx
```

After doing this:

```text
/
```

still works.

Why?

Because route groups do not affect URLs.

---

# Step 2 — Create The Site Layout

Create:

```text
app/(site)/layout.tsx
```

Add:

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

This file creates our first application shell.

---

# But Wait...

If you run:

```bash
npm run dev
```

right now, you'll get an error:

```text
Cannot find module:

@/components/layout/Header
```

That's because we haven't created those components yet.

Let's fix that.

---

# Step 3 — Create The Layout Components

Create:

```text
components/

└── layout/
```

---

## Header.tsx

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
          px-4
          py-6
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
            gap-6
            text-sm
          "
        >
          <Link href="/">
            Home
          </Link>

          <Link href="/posts">
            Posts
          </Link>

          <Link href="/about">
            About
          </Link>
        </nav>
      </div>
    </header>
  );
}
```

---

## Footer.tsx

Create:

```text
components/layout/Footer.tsx
```

```tsx
export default function Footer() {
  return (
    <footer
      className="
        mt-20
        border-t
        border-gray-200
      "
    >
      <div
        className="
          mx-auto
          max-w-6xl
          px-4
          py-8
          text-center
          text-sm
          text-gray-500
        "
      >
        © 2026
        {" "}
        GreyMatter Journal
      </div>
    </footer>
  );
}
```

Now:

```bash
npm run dev
```

works correctly.

---

# Step 4 — Update The Homepage

Update:

```text
app/(site)/page.tsx
```

```tsx
export default function HomePage() {
  return (
    <section
      className="
        py-20
        text-center
      "
    >
      <h1
        className="
          text-5xl
          font-bold
          tracking-tight
          sm:text-6xl
        "
      >
        GreyMatter Journal
      </h1>

      <p
        className="
          mx-auto
          mt-6
          max-w-2xl
          text-lg
          text-gray-600
        "
      >
        Exploring software
        engineering,
        systems thinking,
        and architecture.
      </p>
    </section>
  );
}
```

---

# What We Just Built

Our application now looks like:

```text
Root Layout
        ↓

Site Layout
        ↓

Header

        ↓

Page Content

        ↓

Footer
```

Visually:

```text
┌─────────────────┐
│     Header      │
├─────────────────┤
│                 │
│   Home Page     │
│                 │
├─────────────────┤
│     Footer      │
└─────────────────┘
```

---

# Why Does This Matter?

Suppose tomorrow we add:

```text
/about

/posts

/posts/react

/posts/nextjs
```

We do not rebuild:

```text
Header

Footer

Navigation
```

Those components remain mounted.

Only:

```text
{children}
```

changes.

This is why modern applications feel fast.

---

# Tailwind In The Application Shell

Notice this code:

```tsx
className="
  mx-auto
  max-w-6xl
  px-4
  py-10
"
```

Each utility represents a design decision:

```text
mx-auto
        =
center content

max-w-6xl
        =
maximum width

px-4
        =
horizontal spacing

py-10
        =
vertical spacing
```

Instead of writing CSS files, we compose our design system directly in our components.

---

# The Mental Model To Remember Forever

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

Infrastructure

     +

Application Shell

     +

Dynamic Content
```

More concretely:

```text
Root Layout
        ↓

Providers
        ↓

Site Layout
        ↓

Header
        +
Footer
        +
Navigation
        ↓

Pages
```

The layout is the architecture.

The page is merely the content.

---

# Up Next — Part 7: Introducing Sanity

We'll begin building the content layer of GreyMatter Journal and learn:

* what a headless CMS actually is
* why content and presentation should be separated
* how Sanity's Content Lake works
* why modern publishing systems are distributed architectures
* how Next.js and Sanity cooperate to build scalable publications

```
```
