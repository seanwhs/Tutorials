# **✅ Part 2 — Understanding the App Router**

---

# GreyMatter Journal

## Part 2 — Understanding the App Router: Why Modern Web Applications Are Not Collections of Pages

> **Goal of this lesson:** Master the **Next.js App Router**, understand why folders become routes, the power of `page.tsx` and `layout.tsx`, and why modern applications are built as **persistent UI trees** instead of isolated pages.

---

### The Biggest Mental Shift in Next.js

Traditional web development taught us to think in **static pages**:

```text id="tr3b6q"
home.html
about.html
blog.html
contact.html
```

Clicking a link meant:

* Destroy the current page completely
* Load the entire new page from scratch

Modern applications (Gmail, Notion, GitHub, Linear, etc.) don’t work this way. They feel continuous.

**What stays:**

* Navigation bar
* Sidebar
* Footer
* Theme / user state

**What changes:**

* Only the main content area

This is the core idea behind the **App Router**.

---

### Traditional Pages vs Modern Applications

| Aspect          | Traditional Pages       | Modern Applications (App Router) |
| --------------- | ----------------------- | -------------------------------- |
| Navigation      | Full page reload        | Partial update                   |
| Layouts         | Duplicated across files | Persistent & nested              |
| State           | Lost on navigation      | Preserved                        |
| Performance     | Slower                  | Faster (less re-rendering)       |
| User Experience | Disjointed              | Smooth & app-like                |

---

### The App Router Philosophy

The App Router changes the fundamental question from:

> "Which page should I show?"

to:

> "Which **parts** of the UI tree need to change?"

It uses the **file system** as the router — a concept called **file-system routing**.

---

## Folders = Routes

In the `app/` directory, folders define your application's URL structure:

| File / Folder Structure              | Resulting URL                              | Route Type                      |
| ------------------------------------ | ------------------------------------------ | ------------------------------- |
| `app/page.tsx`                       | `/`                                        | Static route                    |
| `app/about/page.tsx`                 | `/about`                                   | Static route                    |
| `app/posts/page.tsx`                 | `/posts`                                   | Static route                    |
| `app/posts/[slug]/page.tsx`          | `/posts/my-first-post`                     | Dynamic route                   |
| `app/posts/[slug]/comments/page.tsx` | `/posts/my-first-post/comments`            | Nested dynamic route            |
| `app/category/[category]/page.tsx`   | `/category/react`                          | Dynamic route                   |
| `app/docs/[...slug]/page.tsx`        | `/docs/getting-started/install`            | Catch-all route                 |
| `app/docs/[[...slug]]/page.tsx`      | `/docs` or `/docs/getting-started/install` | Optional catch-all route        |
| `app/admin/(dashboard)/page.tsx`     | `/admin`                                   | Route group (organization only) |

### Dynamic Route Syntax

Next.js uses square brackets to define dynamic route segments.

#### `[slug]` — Single Dynamic Segment

Matches exactly one URL segment:

```text id="q84l9n"
app/posts/[slug]/page.tsx
                  ↓
        /posts/my-first-post
```

Inside the page component:

```tsx id="d5rq2j"
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

---

#### `[...slug]` — Catch-All Route

Matches one or more segments:

```text id="w8x2fs"
app/docs/[...slug]/page.tsx
                  ↓
        /docs/react/hooks/useEffect
```

Example:

```tsx id="a7v4kr"
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
      {JSON.stringify(
        slug
      )}
    </pre>
  );
}
```

Result:

```text id="h3p9qt"
["react",
 "hooks",
 "useEffect"]
```

---

#### `[[...slug]]` — Optional Catch-All Route

Matches zero or more segments:

```text id="p7n2wd"
app/docs/[[...slug]]/page.tsx
                  ↓

        /docs

        /docs/react

        /docs/react/hooks
```

Example:

```tsx id="u6k4jb"
export default async function DocsPage({
  params,
}: {
  params: Promise<{
    slug?: string[];
  }>;
}) {
  const { slug } =
    await params;

  return (
    <pre>
      {JSON.stringify(
        slug
      )}
    </pre>
  );
}
```

Possible values:

```text id="m9c5ry"
undefined

["react"]

["react", "hooks"]
```

---

> **Important:** Route groups (folders wrapped in parentheses), such as `(site)` or `(dashboard)`, do **not** affect the URL structure. They exist purely for organizing your application architecture and layouts.

---

### Core Building Blocks

#### 1. `page.tsx` — The Content

Every route needs a `page.tsx` file to define what is rendered at that URL.

```tsx id="n2f8xk"
// app/page.tsx
export default function HomePage() {
  return (
    <div>
      <h1 className="text-4xl font-bold">
        GreyMatter Journal
      </h1>

      <p>
        Exploring
        software
        engineering
        and systems
        thinking.
      </p>
    </div>
  );
}
```

#### 2. `layout.tsx` — The Persistent UI

Layouts wrap pages and persist across navigation.

```tsx id="k7d3qa"
// app/layout.tsx
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
          Persistent
          Navigation
        </nav>

        {children}

        <footer>
          Persistent
          Footer
        </footer>
      </body>
    </html>
  );
}
```

**Key insight:** The `children` prop represents the content of the current page (or nested layout).

---

### Understanding `globals.css`

Another file generated by Next.js is:

```text id="tbq9je"
app/globals.css
```

At first glance, it may seem like "just another CSS file."

In reality, `globals.css` defines the visual foundation of the entire application.

Think of it as:

```text id="x8h4pm"
page.tsx
        =
page content

layout.tsx
        =
shared UI

globals.css
        =
shared styling
```

For GreyMatter Journal, we'll gradually build our design system using this file.

A typical starting point looks like:

```css id="r4n2kv"
@import "tailwindcss";

:root {
  --background:
    #ffffff;

  --foreground:
    #171717;
}

* {
  box-sizing:
    border-box;
}

body {
  background:
    var(--background);

  color:
    var(--foreground);

  font-family:
    Inter,
    system-ui,
    sans-serif;

  line-height:
    1.7;
}
```

This teaches several important ideas:

* Global CSS
* CSS variables
* Typography systems
* Design tokens
* Tailwind integration
* Shared application styling

We'll continue expanding `globals.css` throughout the series as our design system evolves.

---

### Nested Layouts — The Real Power

You can create layouts at any level:

```text id="s9m4dk"
app/
├── layout.tsx
│
├── page.tsx
│
├── posts/
│   ├── layout.tsx
│   ├── page.tsx
│   └── [slug]/
│       └── page.tsx
```

**Visual Tree:**

```text id="e3p7jf"
Root Layout
   ├── Navbar
   ├── Posts Layout
   │     ├── Sidebar
   │     └── {children}
   └── Footer
```

When navigating between posts, the **Root Layout** and **Posts Layout** stay mounted. Only the innermost page changes.

**Benefits:**

* Preserved component state
* Reduced JavaScript execution
* Better performance
* Smoother user experience

---

### The GreyMatter Journal Structure (Preview)

As defined in **Appendix B**, our final routing will look like this:

```text id="w4r2jm"
app/
├── (site)/
│   ├── page.tsx
│   ├── posts/
│   │   ├── page.tsx
│   │   └── [slug]/
│   │       └── page.tsx
│   └── about/
│       └── page.tsx
│
├── globals.css
│
└── layout.tsx
```

This organization keeps the project clean and scalable.

---

### Mental Model To Remember Forever

**Wrong mental model:**

```text id="d9h5ql"
Next.js
     =
Collection
of Pages
```

**Correct mental model:**

```text id="b2p8wc"
Next.js
     =
UI Tree

     ↓

Root Layout

     ↓

Nested Layouts

     ↓

Page Component

     ↓

Child Components
```

Modern web applications are **composable user interfaces** where stable parts stay and dynamic parts update efficiently.

---

### Up Next — Part 3: Deep Dive into `app/layout.tsx`

We'll examine the root layout in detail and learn:

* Why every Next.js app needs a root layout
* How to structure the HTML document (`<html>`, `<body>`)
* What `React.ReactNode` really means
* How to add global styles, fonts, and providers
* Best practices for the GreyMatter Journal design
