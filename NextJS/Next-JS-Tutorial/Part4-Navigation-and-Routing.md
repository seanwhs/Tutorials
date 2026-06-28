# Next.js 16 for Absolute Beginners

# Part 4 — Navigation and Routing: How Users Move Around Your Application

> **Goal of this lesson:** Learn how navigation works in Next.js, why `<a>` tags are usually the wrong choice, and how file-system routing creates entire applications.

---

# Recap

In the previous lesson, we learned:

```text
Layouts
    ↓
Wrap pages
    ↓
Persist during navigation
```

Our application currently looks like this:

```text
app/

├── page.tsx
├── about/page.tsx
├── blog/page.tsx
├── contact/page.tsx
└── dashboard/
    ├── layout.tsx
    ├── page.tsx
    ├── users/page.tsx
    └── settings/page.tsx
```

This automatically creates:

```text
/
/about
/blog
/contact
/dashboard
/dashboard/users
/dashboard/settings
```

This is called:

# File-System Routing

---

# How Traditional Websites Work

Suppose you're visiting:

```text
https://example.com/about
```

The browser does this:

```text
Request page
      ↓
Download HTML
      ↓
Destroy current page
      ↓
Render new page
```

Every click reloads the entire website.

Example:

```html
<a href="/about">
    About
</a>
```

This causes:

```text
FULL PAGE RELOAD
```

---

# Single Page Applications

Modern applications work differently.

Example:

* Gmail
* Facebook
* YouTube
* Notion

When you click:

```text
Home → About
```

the browser does NOT reload everything.

Instead:

```text
Keep current application
        ↓
Fetch new content
        ↓
Update screen
```

This feels much faster.

---

# Next.js Supports Both

Next.js can perform:

### Traditional navigation

```html
<a href="/about">
```

and:

### Client-side navigation

```tsx
<Link href="/about">
```

Most of the time, we want:

```tsx
<Link>
```

---

# Why <a> Is Usually Wrong

Suppose we have:

```tsx
<a href="/about">
    About
</a>
```

Clicking this causes:

```text
Destroy page
Destroy React
Destroy state
Reload browser
Recreate everything
```

Example:

```text
Page A
    ↓
Browser reload
    ↓
Page B
```

This is slow.

---

# Enter the Link Component

Next.js provides:

```tsx
import Link from "next/link";
```

Example:

```tsx
import Link from "next/link";

export default function Navigation() {
    return (
        <nav>
            <Link href="/">
                Home
            </Link>

            <Link href="/about">
                About
            </Link>

            <Link href="/blog">
                Blog
            </Link>
        </nav>
    );
}
```

---

# What Makes Link Special?

When you write:

```tsx
<Link href="/about">
    About
</Link>
```

Next.js secretly does:

```text
User hovers link
        ↓
Next.js downloads page
        ↓
User clicks
        ↓
Instant navigation
```

This is called:

# Prefetching

---

# Visualizing Prefetching

Normal websites:

```text
Click
   ↓
Request
   ↓
Wait
   ↓
Render
```

Next.js:

```text
Hover
   ↓
Prefetch
   ↓
Click
   ↓
Instant
```

This is why Next.js applications feel so fast.

---

# Replacing Our Navigation

Let's improve our layout.

---

## app/layout.tsx

```tsx
import "./globals.css";
import Link from "next/link";

export default function RootLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <html>
            <body>

                <header>
                    <h1>
                        Next.js Academy
                    </h1>

                    <nav>

                        <Link href="/">
                            Home
                        </Link>

                        {" | "}

                        <Link href="/about">
                            About
                        </Link>

                        {" | "}

                        <Link href="/blog">
                            Blog
                        </Link>

                        {" | "}

                        <Link href="/contact">
                            Contact
                        </Link>

                    </nav>
                </header>

                <hr />

                {children}

                <hr />

                <footer>
                    Copyright 2026
                </footer>

            </body>
        </html>
    );
}
```

---

# Nested Navigation

Suppose we have:

```text
/dashboard
/dashboard/users
/dashboard/settings
```

We can also use Link.

---

## dashboard/layout.tsx

```tsx
import Link from "next/link";

export default function DashboardLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <div>

            <h2>
                Dashboard
            </h2>

            <nav>

                <Link href="/dashboard">
                    Home
                </Link>

                {" | "}

                <Link href="/dashboard/users">
                    Users
                </Link>

                {" | "}

                <Link href="/dashboard/settings">
                    Settings
                </Link>

            </nav>

            <hr />

            {children}

        </div>
    );
}
```

---

# Dynamic Routes

Most websites don't have fixed URLs.

For example:

```text
/blog/react
/blog/python
/blog/javascript
```

You can't create:

```text
blog/
    react/
    python/
    javascript/
```

for every post.

Instead, Next.js supports:

# Dynamic Segments

---

# Creating Our First Dynamic Route

Create:

```text
app/blog/[slug]
```

Your folder structure:

```text
app/

blog/
    page.tsx

    [slug]/
        page.tsx
```

Notice:

```text
[slug]
```

The square brackets make the route dynamic.

---

# Example Dynamic Page

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
        <main>

            <h1>
                Blog Post
            </h1>

            <p>
                {slug}
            </p>

        </main>
    );
}
```

---

# Testing Dynamic Routes

Visit:

```text
/blog/react
```

Output:

```text
Blog Post

react
```

---

Visit:

```text
/blog/python
```

Output:

```text
Blog Post

python
```

---

Visit:

```text
/blog/nextjs-16
```

Output:

```text
Blog Post

nextjs-16
```

Amazing.

One file creates infinitely many pages.

---

# Multiple Dynamic Segments

Suppose we want:

```text
/products/electronics/laptop
/products/books/javascript
```

Create:

```text
app/products/[category]/[product]
```

---

Example:

```tsx
export default async function ProductPage({
    params,
}: {
    params: Promise<{
        category: string;
        product: string;
    }>;
}) {

    const {
        category,
        product
    } = await params;

    return (
        <div>

            <h1>
                Product
            </h1>

            <p>
                Category:
                {category}
            </p>

            <p>
                Product:
                {product}
            </p>

        </div>
    );
}
```

---

Visiting:

```text
/products/books/react
```

produces:

```text
Category: books
Product: react
```

---

# Catch-All Routes

Suppose we want:

```text
/docs
/docs/react
/docs/react/hooks
/docs/react/hooks/useeffect
```

Create:

```text
app/docs/[...slug]
```

---

Example:

```tsx
export default async function Docs({
    params,
}: {
    params: Promise<{
        slug: string[];
    }>;
}) {

    const { slug } =
        await params;

    return (
        <div>

            <h1>
                Documentation
            </h1>

            <pre>
                {JSON.stringify(
                    slug,
                    null,
                    2
                )}
            </pre>

        </div>
    );
}
```

---

Visit:

```text
/docs/react/hooks
```

Result:

```json
[
  "react",
  "hooks"
]
```

---

# Optional Catch-All Routes

Suppose both should work:

```text
/docs
/docs/react
/docs/react/hooks
```

Create:

```text
app/docs/[[...slug]]
```

Notice:

```text
[[...slug]]
```

instead of:

```text
[...slug]
```

This means:

> zero or more segments.

---

# Route Groups

Sometimes we want folders that don't appear in the URL.

Example:

```text
app/

(marketing)
    about
    pricing

(admin)
    dashboard
    users
```

Produces:

```text
/about
/pricing
/dashboard
/users
```

without:

```text
/marketing/about
/admin/dashboard
```

This is called:

# Route Groups

---

# Parallel Routes

Large applications may render several pages simultaneously.

Example:

```text
Dashboard
    |
    +-- Analytics
    |
    +-- Notifications
    |
    +-- Team
```

We'll learn this advanced feature later.

---

# Visualizing Routing

A Next.js application is really a tree.

```text
Root Layout
      |
      |
      +--- Home
      |
      +--- About
      |
      +--- Blog
               |
               +--- [slug]
      |
      +--- Dashboard
                     |
                     +--- Users
                     |
                     +--- Settings
```

---

# Exercise 1

Create:

```text
/profile/[username]
```

Example:

```text
/profile/sean
/profile/john
/profile/mary
```

---

# Exercise 2

Create:

```text
/shop/[category]/[product]
```

Examples:

```text
/shop/books/react
/shop/games/chess
/shop/movies/interstellar
```

---

# Exercise 3

Create:

```text
/wiki/[...page]
```

Examples:

```text
/wiki
/wiki/react
/wiki/react/hooks
/wiki/react/hooks/useeffect
```

---

# What You've Learned

You now understand:

✅ `<Link>`

✅ client-side navigation

✅ prefetching

✅ dynamic routes

✅ multiple parameters

✅ catch-all routes

✅ optional catch-all routes

✅ route groups

✅ routing trees

---

# Mental Model

Always remember:

```text
Folders
    ↓
Become Routes

Layouts
    ↓
Become Structure

Pages
    ↓
Become Screens
```

This simple idea powers virtually every Next.js application.

---

# Part 5 Preview

In the next chapter, we'll learn one of the most important concepts in all of modern Next.js:

# React Server Components vs Client Components

We'll answer questions like:

* Why don't we write `useEffect` anymore?
* Why do some components execute on the server?
* Why do some components execute in the browser?
* What does `"use client"` really do?
* Why are Server Components usually faster?
* Why did React change its architecture?

This chapter is where most developers finally understand what makes modern Next.js fundamentally different from traditional React.
