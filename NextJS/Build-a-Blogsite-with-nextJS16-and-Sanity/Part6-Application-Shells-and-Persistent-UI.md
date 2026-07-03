# GreyMatter Journal

# Part 6 — Building Our First Real Layout: Understanding Application Shells and Persistent UI

> **Goal of this lesson:** Build the first real layout for GreyMatter Journal and understand why modern web applications are built around persistent application shells rather than individual pages.

---

# Until Now, Our Website Has Been Lying To Us

Currently, our application looks something like this:

```text
/
```

and:

```tsx
export default function HomePage() {
  return (
    <main>
      <h1>GreyMatter Journal</h1>
    </main>
  );
}
```

This feels natural because we've spent years thinking:

```text
Website
    ↓
Pages
```

But modern applications don't actually work like this.

Instead, they work like this:

```text
Application
        ↓
Persistent Shell
        ↓
Dynamic Content
```

---

# What Is An Application Shell?

Think about applications you use every day.

## YouTube

```text
Header
Sidebar
Search Bar

remain

Video
changes
```

---

## GitHub

```text
Navigation
User Menu
Theme

remain

Repository Content
changes
```

---

## ChatGPT

```text
Sidebar
Header
Account Menu

remain

Conversation
changes
```

---

This persistent part of the interface is called:

# The Application Shell

Diagram:

```text
┌───────────────────────────┐
│         Header            │
├────────────┬──────────────┤
│ Sidebar    │ Content      │
│            │              │
│            │              │
└────────────┴──────────────┘
```

---

# Why Application Shells Exist

Imagine navigating between pages.

Without layouts:

```text
Navigate
    ↓
Destroy navbar
    ↓
Destroy footer
    ↓
Destroy sidebar
    ↓
Build everything again
```

With layouts:

```text
Navigate
    ↓
Keep navbar
    ↓
Keep footer
    ↓
Keep sidebar
    ↓
Change content only
```

Benefits:

* faster navigation,
* preserved state,
* smoother UI,
* less rendering,
* better performance.

---

# Designing GreyMatter Journal

Let's design our application shell.

Eventually our blog will contain:

```text
Header
    ↓
Navigation
    ↓
Main Content
    ↓
Footer
```

Diagram:

```text
┌────────────────────────────┐
│      GreyMatter Journal    │
├────────────────────────────┤
│ Home Articles About Search │
├────────────────────────────┤
│                            │
│        Content             │
│                            │
├────────────────────────────┤
│          Footer            │
└────────────────────────────┘
```

---

# Updating RootLayout

Open:

```text
app/layout.tsx
```

Replace everything with:

```tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "GreyMatter Journal",
  description:
    "Thoughts on software, architecture, and systems",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <header>
          <h1>GreyMatter Journal</h1>
        </header>

        <nav>
          Home | Articles | Authors
        </nav>

        <main>{children}</main>

        <footer>
          © 2026 GreyMatter Journal
        </footer>
      </body>
    </html>
  );
}
```

---

# What Did We Just Build?

Remember:

```text
Layout
      ↓
contains
      ↓
Page
```

So Next.js now creates:

```text
RootLayout
      │
      ▼
Current Page
```

Diagram:

```text
<html>

    <body>

        Header

        Navigation

        Current Page

        Footer

    </body>

</html>
```

---

# Let's Improve The Homepage

Open:

```text
app/page.tsx
```

Replace the contents:

```tsx
export default function HomePage() {
  return (
    <>
      <h2>Welcome to GreyMatter Journal</h2>

      <p>
        Exploring software engineering,
        architecture, distributed systems,
        and modern web development.
      </p>
    </>
  );
}
```

Refresh your browser.

You should now see:

```text
GreyMatter Journal

Home | Articles | Authors

Welcome to GreyMatter Journal

Exploring software engineering...

© 2026 GreyMatter Journal
```

---

# Creating Our First Additional Page

Let's create:

```text
app/

about/
    page.tsx
```

Create:

```tsx
export default function AboutPage() {
  return (
    <>
      <h2>About GreyMatter Journal</h2>

      <p>
        GreyMatter Journal is a modern
        publication platform built with
        Next.js 16 and Sanity.
      </p>
    </>
  );
}
```

Visit:

```text
http://localhost:3000/about
```

What happened?

---

# The Magic Of Layout Persistence

Even though we created a new page:

```text
/about
```

Next.js still renders:

```text
Header
Navigation
About Content
Footer
```

Why?

Because internally, Next.js constructs:

```text
RootLayout
        │
        ▼
AboutPage
```

Diagram:

```text
                RootLayout
                     │
                     ▼
        ┌────────────────────────┐
        │ Header                 │
        │ Navigation             │
        │                        │
        │ AboutPage              │
        │                        │
        │ Footer                 │
        └────────────────────────┘
```

---

# Creating A Real Navigation Menu

Our current navigation:

```tsx
<nav>
  Home | Articles | Authors
</nav>
```

isn't very useful.

Next.js provides a special component:

```tsx
import Link from "next/link";
```

Let's update our layout:

```tsx
import Link from "next/link";
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "GreyMatter Journal",
  description:
    "Thoughts on software, architecture, and systems",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <header>
          <h1>GreyMatter Journal</h1>
        </header>

        <nav>
          <Link href="/">Home</Link>{" "}
          <Link href="/about">About</Link>
        </nav>

        <main>{children}</main>

        <footer>
          © 2026 GreyMatter Journal
        </footer>
      </body>
    </html>
  );
}
```

---

# Why Not Use `<a>` Tags?

Many beginners ask:

```html
<a href="/about">About</a>
```

Why can't we use this?

Because traditional links behave like this:

```text
Click
   ↓
Browser Request
   ↓
Destroy Page
   ↓
Load Page
```

`Link` behaves like this:

```text
Click
   ↓
Next.js Router
   ↓
Fetch New Content
   ↓
Update UI Tree
```

Diagram:

```text
Traditional

Page A
   ↓
Destroy
   ↓
Page B

Next.js

Layout
   ↓
Replace Child
   ↓
New Content
```

---

# The Hidden Architecture

When you click:

```text
/about
```

Next.js doesn't think:

```text
Load another page
```

It thinks:

```text
Keep:

✓ RootLayout

Replace:

✗ Current Page
```

Internally:

```text
Before

RootLayout
     └── HomePage

After

RootLayout
     └── AboutPage
```

The layout survives.

The child changes.

---

# Why This Matters For Blogs

Imagine our future blog.

Without layouts:

```text
Article A
      ↓
destroy navigation
      ↓
destroy sidebar
      ↓
destroy footer
```

With layouts:

```text
Article A
      ↓
keep navigation
      ↓
keep footer
      ↓
replace article
```

This enables:

* instant navigation,
* article prefetching,
* preserved state,
* streaming updates,
* excellent user experience.

---

# Our Future GreyMatter Journal Tree

Eventually our application will look like this:

```text
RootLayout
     │
     ├── HomePage
     │
     ├── ArticlesLayout
     │       ├── ArticlesPage
     │       └── ArticlePage
     │
     ├── AuthorsLayout
     │       ├── AuthorsPage
     │       └── AuthorPage
     │
     └── CategoriesLayout
             ├── CategoriesPage
             └── CategoryPage
```

Notice something important:

```text
The pages are not the application.

The layouts are the application.
```

---

# Mental Model To Remember Forever

Most beginners think:

```text
Website
      ↓
Pages
```

Modern Next.js thinks:

```text
Application
       ↓
Persistent Layouts
       ↓
Dynamic Content
```

Or more specifically:

```text
Application Shell
          +
Changing Content
```

This is the architectural idea that powers nearly every modern web application.

---

# Up Next

In **Part 7**, we'll finally introduce the second half of our architecture:

# Sanity

We'll learn:

* what a Headless CMS actually is,
* why Next.js doesn't store blog posts,
* what the Sanity Content Lake is,
* what `npx sanity@latest init` actually creates,
* and why modern applications separate content management from rendering.
