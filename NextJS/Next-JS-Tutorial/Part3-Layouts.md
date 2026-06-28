# Next.js 16 for Absolute Beginners

# Part 3 — Understanding Layouts: The Secret Behind Modern Web Applications

> **Goal of this lesson:** Understand what layouts are, why they exist, and how they allow Next.js applications to share UI across pages.

---

# Why Do We Need Layouts?

Let's imagine we're building a simple website.

```
Home
About
Blog
Contact
```

Every page needs:

* a logo
* navigation
* a footer

Without layouts, we'd have to repeat the same code over and over.

---

## Without Layouts

### Home Page

```tsx
export default function HomePage() {
    return (
        <>
            <header>
                <h1>My Website</h1>

                <nav>
                    <a href="/">Home</a>
                    <a href="/about">About</a>
                    <a href="/blog">Blog</a>
                </nav>
            </header>

            <main>
                <h2>Home</h2>
            </main>

            <footer>
                Copyright 2026
            </footer>
        </>
    );
}
```

---

### About Page

```tsx
export default function AboutPage() {
    return (
        <>
            <header>
                <h1>My Website</h1>

                <nav>
                    <a href="/">Home</a>
                    <a href="/about">About</a>
                    <a href="/blog">Blog</a>
                </nav>
            </header>

            <main>
                <h2>About</h2>
            </main>

            <footer>
                Copyright 2026
            </footer>
        </>
    );
}
```

---

### Blog Page

```tsx
export default function BlogPage() {
    return (
        <>
            <header>
                <h1>My Website</h1>

                <nav>
                    <a href="/">Home</a>
                    <a href="/about">About</a>
                    <a href="/blog">Blog</a>
                </nav>
            </header>

            <main>
                <h2>Blog</h2>
            </main>

            <footer>
                Copyright 2026
            </footer>
        </>
    );
}
```

Notice the problem?

We copied the same code three times.

This violates one of the most important principles in programming:

> **Don't Repeat Yourself (DRY).**

---

# What Is a Layout?

A layout is a component that wraps multiple pages.

Think of it as a reusable template.

```
        Layout
           |
    +------+------+------+
    |      |      |      |
  Home   About   Blog  Contact
```

Instead of each page containing the navigation and footer, the layout contains them.

---

# The Root Layout

When you create a Next.js application, you already have one layout:

```
app/
    layout.tsx
```

Open it.

You might see something similar to:

```tsx
export default function RootLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <html>
            <body>
                {children}
            </body>
        </html>
    );
}
```

This file is special.

It wraps every page in your application.

---

# What Is children?

Suppose we have:

```tsx
function Box({ children }) {
    return (
        <div>
            {children}
        </div>
    );
}
```

Now we use it:

```tsx
<Box>
    <h1>Hello</h1>
</Box>
```

React automatically converts this into:

```tsx
Box({
    children: <h1>Hello</h1>
});
```

So:

```tsx
function Box({ children }) {
    return (
        <div>
            {children}
        </div>
    );
}
```

produces:

```html
<div>
    <h1>Hello</h1>
</div>
```

---

# How Next.js Uses children

Suppose we have:

```
app/
    layout.tsx
    page.tsx
```

### layout.tsx

```tsx
export default function RootLayout({
    children,
}) {
    return (
        <html>
            <body>
                <header>
                    My Website
                </header>

                {children}

                <footer>
                    Copyright
                </footer>
            </body>
        </html>
    );
}
```

---

### page.tsx

```tsx
export default function HomePage() {
    return (
        <main>
            Home Page
        </main>
    );
}
```

Next.js internally creates:

```tsx
<RootLayout>
    <HomePage />
</RootLayout>
```

which renders:

```html
<html>
<body>

<header>
    My Website
</header>

<main>
    Home Page
</main>

<footer>
    Copyright
</footer>

</body>
</html>
```

---

# Building Our First Real Layout

Replace your existing layout.

## app/layout.tsx

```tsx
import "./globals.css";

export default function RootLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <html lang="en">
            <body>

                <header>
                    <h1>
                        Next.js Academy
                    </h1>

                    <nav>
                        <a href="/">Home</a>
                        {" | "}

                        <a href="/about">
                            About
                        </a>
                        {" | "}

                        <a href="/blog">
                            Blog
                        </a>
                        {" | "}

                        <a href="/contact">
                            Contact
                        </a>
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

# Observe What Happens

Visit:

```
/
```

Then:

```
/about
```

Then:

```
/blog
```

Notice:

* header remains
* navigation remains
* footer remains

Only the page content changes.

This is the fundamental idea behind layouts.

---

# Why Layouts Are Powerful

Without layouts:

```
Page
    |
Header
Content
Footer

Page
    |
Header
Content
Footer
```

With layouts:

```
          Layout
             |
    +--------+--------+
    |        |        |
  Home     About    Blog
```

Benefits:

* less code
* easier maintenance
* shared UI
* faster navigation
* persistent state

---

# Nested Layouts

Next.js allows layouts inside layouts.

Example:

```
app/

layout.tsx

dashboard/
    layout.tsx
    page.tsx
    analytics/
        page.tsx
```

---

## Root Layout

```tsx
export default function RootLayout({
    children
}) {
    return (
        <>
            <header>
                Main Website
            </header>

            {children}
        </>
    );
}
```

---

## Dashboard Layout

```tsx
export default function DashboardLayout({
    children
}) {
    return (
        <div>

            <aside>
                Dashboard Menu
            </aside>

            <main>
                {children}
            </main>

        </div>
    );
}
```

---

The resulting hierarchy becomes:

```
RootLayout
     |
DashboardLayout
     |
DashboardPage
```

---

# Let's Build a Dashboard

Create:

```
app/dashboard
```

Inside:

```
app/dashboard/page.tsx
```

```tsx
export default function DashboardPage() {
    return (
        <h2>
            Dashboard Home
        </h2>
    );
}
```

---

Create:

```
app/dashboard/layout.tsx
```

```tsx
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
                <a href="/dashboard">
                    Home
                </a>
                {" | "}

                <a href="/dashboard/users">
                    Users
                </a>
                {" | "}

                <a href="/dashboard/settings">
                    Settings
                </a>
            </nav>

            <hr />

            {children}

        </div>
    );
}
```

---

Create:

```
app/dashboard/users/page.tsx
```

```tsx
export default function UsersPage() {
    return (
        <h3>
            Users Page
        </h3>
    );
}
```

---

Create:

```
app/dashboard/settings/page.tsx
```

```tsx
export default function SettingsPage() {
    return (
        <h3>
            Settings Page
        </h3>
    );
}
```

---

# Visualizing Nested Layouts

When visiting:

```
/dashboard/users
```

Next.js builds:

```
RootLayout
    |
DashboardLayout
    |
UsersPage
```

Result:

```
Website Header

    Dashboard Header
    Dashboard Menu

        Users Page

Website Footer
```

---

# Layout Persistence

One of the most powerful features of Next.js is that layouts persist.

Imagine:

```tsx
function Sidebar() {
    const [count, setCount] =
        useState(0);

    return (
        <>
            <button
                onClick={() =>
                    setCount(count + 1)
                }
            >
                {count}
            </button>
        </>
    );
}
```

If Sidebar lives inside a layout:

```
layout.tsx
```

the sidebar doesn't get recreated every time you navigate.

This makes navigation feel extremely fast.

---

# What About Templates?

Next.js also has:

```
template.tsx
```

Unlike layouts:

```
layout.tsx
```

persists.

But:

```
template.tsx
```

re-renders every navigation.

Think:

```
layout
    =
    persistent

template
    =
    temporary
```

We'll learn templates later.

---

# File Structure So Far

```
app/

layout.tsx
page.tsx

about/
    page.tsx

blog/
    page.tsx

contact/
    page.tsx

dashboard/
    layout.tsx
    page.tsx

    users/
        page.tsx

    settings/
        page.tsx
```

---

# Exercises

## Exercise 1

Create:

```
/admin
```

with its own layout.

---

## Exercise 2

Add pages:

```
/admin/users
/admin/posts
/admin/settings
```

---

## Exercise 3

Create a sidebar:

```text
Dashboard
-----------
Home
Users
Posts
Settings
```

that appears on every admin page.

---

# What You've Learned

You now understand:

✅ root layouts

✅ nested layouts

✅ children

✅ shared UI

✅ persistent layouts

✅ layout composition

✅ dashboard layouts

---

# Mental Model

Always think of a Next.js application as a tree:

```
RootLayout
        |
   +----+----+
   |         |
 Home    DashboardLayout
                |
          +-----+-----+
          |           |
        Users     Settings
```

Next.js applications are not collections of pages.

They are **trees of layouts and pages**.

---

# Next Part

In Part 4 we'll learn:

# Navigation and Routing

Including:

* `<Link>`
* client-side navigation
* why `<a>` tags are bad
* dynamic routes
* route parameters
* URL segments
* nested routes
* route groups
* parallel routes

This is where Next.js begins to feel truly magical.
