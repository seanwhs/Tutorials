# GreyMatter Journal

# Part 15 — Layouts, Navigation, and the Architecture of Persistent User Interfaces

> **Goal of this lesson:** Build the navigation system for GreyMatter Journal and understand one of the most important concepts in modern web architecture: persistent UI trees, nested layouts, and why Next.js applications are actually trees composed of other trees.

---

# Our Blog Finally Feels Like A Blog

At this point, we have:

```text
✓ Homepage
✓ Dynamic Articles
✓ Portable Text
✓ Images
✓ Authors
✓ Categories
✓ Routing
```

But something still feels missing.

Most real websites have:

```text
Logo
Navigation
Content
Footer
```

Like this:

```text
+--------------------------------+
| GreyMatter Journal             |
| Home Articles About            |
+--------------------------------+
|                                |
|          Content               |
|                                |
+--------------------------------+
|          Footer                |
+--------------------------------+
```

---

# How Beginners Think About Pages

Many beginners imagine:

```text
Home Page
About Page
Article Page
```

as completely separate pages.

Diagram:

```text
Page A

Page B

Page C
```

But modern applications don't work this way.

---

# How Next.js Thinks About Applications

Next.js thinks:

```text
Application
      │
      ├── Shared UI
      │
      └── Page Content
```

Diagram:

```text
Application

       │

       ├── Navigation
       │
       ├── Main Content
       │
       └── Footer
```

This distinction changes everything.

---

# Remember RootLayout?

Back in Part 2, we learned:

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

At the time, it seemed mysterious.

Now we can understand it properly.

---

# What Is `children` Really?

Most beginners think:

```text
children
      =
magic
```

Not quite.

Consider JavaScript:

```javascript
function Wrapper(
  content
) {
  return `
    <div>
      ${content}
    </div>
  `;
}
```

React works similarly:

```tsx
function Layout({
  children
}) {
  return (
    <div>
      {children}
    </div>
  );
}
```

Diagram:

```text
Layout

    ┌──────────┐
    │ Header   │
    │          │
    │children  │
    │          │
    │ Footer   │
    └──────────┘
```

---

# Building Our Navigation Component

Create:

```text
components/

Navbar.tsx
```

Add:

```tsx
import Link
  from "next/link";

export default function Navbar() {
  return (
    <nav>
      <Link href="/">
        Home
      </Link>

      {" | "}

      <Link href="/articles">
        Articles
      </Link>

      {" | "}

      <Link href="/about">
        About
      </Link>
    </nav>
  );
}
```

---

# Wait...

Why Are We Using `Link`?

Why not:

```html
<a href="/">
  Home
</a>
```

Because:

```html
<a>
```

causes:

```text
Browser
      ↓
Reload Entire Page
```

But:

```tsx
<Link>
```

causes:

```text
Next.js Router
         ↓
Replace UI
```

Diagram:

```text
Traditional

Click
   ↓
Reload
   ↓
New Page

Next.js

Click
   ↓
Router
   ↓
Update UI
```

---

# What Is Client-Side Navigation?

Traditional websites:

```text
Page A
   ↓
Server
   ↓
Page B
```

Modern applications:

```text
Application
       │
       ▼
Replace
Small Portion
Of UI
```

This creates:

```text
✓ Faster transitions
✓ Less downloading
✓ Better UX
```

---

# Creating The Footer

Create:

```text
components/

Footer.tsx
```

Add:

```tsx
export default function Footer() {
  return (
    <footer>
      <p>
        © 2026
        GreyMatter Journal
      </p>
    </footer>
  );
}
```

---

# Updating RootLayout

Open:

```text
app/layout.tsx
```

Update:

```tsx
import Navbar
  from "@/components/Navbar";

import Footer
  from "@/components/Footer";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <Navbar />

        {children}

        <Footer />
      </body>
    </html>
  );
}
```

---

# What Happens Now?

Suppose the user visits:

```text
/
```

Next.js creates:

```text
RootLayout

     │

     ├── Navbar
     │
     ├── HomePage
     │
     └── Footer
```

If they navigate to:

```text
/posts/react
```

Next.js creates:

```text
RootLayout

     │

     ├── Navbar
     │
     ├── PostPage
     │
     └── Footer
```

Notice something important?

---

# Navbar Never Changes

Diagram:

```text
Before

Navbar
Home
Footer


After

Navbar
Post
Footer
```

Only:

```text
children
```

changed.

This is called:

# Persistent UI

---

# Why Is This Important?

Traditional websites:

```text
Destroy Everything

Rebuild Everything
```

Modern applications:

```text
Keep Shared UI

Update Dynamic UI
```

Benefits:

```text
✓ Faster
✓ Less Work
✓ Better UX
✓ Shared State
```

---

# Let's Create An About Page

Create:

```text
app/

about/

page.tsx
```

Add:

```tsx
export default function AboutPage() {
  return (
    <>
      <h1>
        About
      </h1>

      <p>
        GreyMatter Journal
        explores software
        architecture,
        systems design,
        and AI-era
        engineering.
      </p>
    </>
  );
}
```

Visit:

```text
/about
```

Notice:

```text
Navbar remains.

Footer remains.

Only content changes.
```

---

# But Wait...

Our navigation contains:

```text
/articles
```

We don't have that route.

Let's create it.

---

# Create The Articles Route

Create:

```text
app/

articles/

page.tsx
```

Add:

```tsx
import Link
  from "next/link";

import { client }
  from "@/lib/sanity";

import {
  POSTS_QUERY,
} from "@/lib/queries";

export default async function
ArticlesPage() {
  const posts =
    await client.fetch(
      POSTS_QUERY
    );

  return (
    <>
      <h1>
        Articles
      </h1>

      {posts.map(post => (
        <article
          key={post._id}
        >
          <Link
            href={
              `/posts/${post.slug.current}`
            }
          >
            {post.title}
          </Link>
        </article>
      ))}
    </>
  );
}
```

---

# Notice Something Interesting

This page:

```tsx
export default async function
ArticlesPage()
```

is:

```text
Server Component
```

while:

```tsx
<Link>
```

is:

```text
Client Navigation
```

Diagram:

```text
Server

Render HTML

       │
       ▼

Browser

       │
       ▼

Client Router
```

Modern applications mix:

```text
Server
+
Client
```

continuously.

---

# Nested Layouts

Suppose we want:

```text
Articles

├── Categories
├── Search
└── Content
```

Next.js allows:

```text
app/

articles/

    layout.tsx

    page.tsx

    [slug]/
```

Diagram:

```text
RootLayout

      │

      ▼

ArticlesLayout

      │

      ▼

ArticlePage
```

---

# This Creates Nested UI Trees

Example:

```text
Application

     │

     ├── Navbar
     │
     ├── Articles Layout
     │       │
     │       ├── Sidebar
     │       │
     │       └── Article
     │
     └── Footer
```

Notice:

```text
Tree
inside
tree
inside
tree
```

---

# Wait...

Does This Look Familiar?

We've already seen:

```text
Portable Text Tree

React Tree

Route Tree

Folder Tree
```

Now:

```text
Layout Tree
```

appears too.

---

# The Hidden Secret Of Next.js

A Next.js application is actually:

```text
Filesystem Tree
          ↓
Route Tree
          ↓
Layout Tree
          ↓
React Tree
          ↓
HTML Tree
```

Diagram:

```text
Folders
    ↓

Routes
    ↓

Layouts
    ↓

Components
    ↓

HTML
```

Everything transforms into another tree.

---

# Why Persistent Layouts Matter

Suppose your navbar contains:

```text
Search Box
Notifications
Theme
User Profile
```

Without persistence:

```text
Reload
Lose Everything
```

With persistence:

```text
Keep State
Replace Content
```

Diagram:

```text
Navbar State

       │
       ▼

Page Change

       │
       ▼

Navbar State
Preserved
```

---

# Mental Model To Remember Forever

Beginners think:

```text
Website
      =
Pages
```

Modern frameworks think:

```text
Website
      =
Persistent UI Tree
      +
Dynamic Subtrees
```

Or even more abstractly:

```text
Application
       =
Tree Of Trees
```

Examples:

```text
Filesystem
Routing
Layouts
React
Portable Text
DOM
```

Once you understand that software architecture is largely the organization and transformation of trees, modern frameworks become dramatically easier to understand.

---

# Up Next

In **Part 16**, we'll build search and filtering for GreyMatter Journal and learn:

* what query languages really are,
* how GROQ filtering works,
* how search engines think,
* server-side search versus client-side search,
* URL search parameters,
* and why databases are fundamentally systems for traversing graphs and trees.
