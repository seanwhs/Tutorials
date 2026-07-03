# GreyMatter Journal

# Part 2 — Understanding the App Router: Why Modern Web Applications Are Not Collections of Pages

> **Goal of this lesson:** Understand what the Next.js App Router actually is, why folders become URLs, what `page.tsx` and `layout.tsx` do, and why modern web applications are built as persistent UI trees rather than disconnected pages.

---

# The Biggest Mental Shift In Next.js

One of the hardest things for beginners to understand about Next.js is that modern web applications are **not really collections of pages**.

Most of us learned web development like this:

```text id="h71sux"
home.html
about.html
contact.html
blog.html
```

Every file represented a page.

When users clicked a link:

```text id="jdhj8m"
Page A
    ↓
destroy everything
    ↓
load Page B
```

This model worked for decades.

Unfortunately, modern applications don't behave this way.

---

# Think About The Applications You Use Every Day

Consider:

* Gmail
* YouTube
* LinkedIn
* GitHub
* Notion
* ChatGPT

When you navigate, does everything disappear?

No.

For example:

```text id="u0r3rr"
Sidebar
    ↓
stays

Navbar
    ↓
stays

User menu
    ↓
stays

Theme
    ↓
stays

Content
    ↓
changes
```

What you're actually seeing is this:

```text id="ik24h2"
Persistent UI
        +
Changing UI
```

---

# Traditional Website Thinking

Traditional websites think like this:

```text id="58v22r"
Page 1
```

```text id="89s9k2"
Page 2
```

```text id="qjlwmz"
Page 3
```

Each page is completely independent.

Diagram:

```text id="hmkjlwm"
Browser
    │
    ▼
Page A

Browser
    │
    ▼
Page B

Browser
    │
    ▼
Page C
```

Everything gets rebuilt.

---

# Modern Application Thinking

Modern applications think differently.

Instead of pages, they build:

```text id="w3c0jr"
Application Tree
```

Diagram:

```text id="7yx30o"
Application

├── Navbar
├── Sidebar
├── Footer
└── Content
```

When navigation occurs:

```text id="h4ftkq"
Navbar
    stays

Sidebar
    stays

Footer
    stays

Content
    changes
```

This creates:

* faster navigation,
* less rendering,
* preserved state,
* better user experience.

---

# Why Next.js Created The App Router

Before Next.js 13, applications used something called the **Pages Router**.

Example:

```text id="gv2es5"
pages/

index.tsx
about.tsx
contact.tsx
blog.tsx
```

This worked well for websites.

It worked less well for applications.

Why?

Because applications need:

* persistent layouts,
* nested interfaces,
* streaming,
* server components,
* partial rendering.

The App Router was created to solve these problems.

---

# The App Router Philosophy

The App Router asks a different question.

Instead of asking:

> Which page are we rendering?

it asks:

> Which part of the application tree changed?

This is a fundamental shift.

---

# Our First App Router Project

Inside our project, you'll find:

```text id="n7d5zt"
greymatter-journal/

app/
    layout.tsx
    page.tsx
```

At first, this seems strange.

Why don't we have:

```text id="4aewv7"
index.html
about.html
contact.html
```

Because the App Router uses folders as routes.

---

# Folders Become URLs

Suppose we create:

```text id="qwgxmd"
app/

about/
    page.tsx

posts/
    page.tsx

authors/
    page.tsx
```

Next.js automatically creates:

```text id="fijlk9"
/about

/posts

/authors
```

No router configuration.

No route registration.

No setup.

The filesystem becomes the router.

---

# Example

Consider this structure:

```text id="2c57uk"
app/

page.tsx
about/page.tsx
contact/page.tsx
blog/page.tsx
```

Next.js builds:

| File                   | URL        |
| ---------------------- | ---------- |
| `app/page.tsx`         | `/`        |
| `app/about/page.tsx`   | `/about`   |
| `app/contact/page.tsx` | `/contact` |
| `app/blog/page.tsx`    | `/blog`    |

---

# What Is page.tsx?

A `page.tsx` file defines what content appears at a route.

Example:

```tsx id="4hrlb6"
export default function HomePage() {
  return <h1>GreyMatter Journal</h1>;
}
```

This creates:

```text id="h7c48d"
/
```

Another example:

```tsx id="gk25dr"
export default function AboutPage() {
  return <h1>About Us</h1>;
}
```

inside:

```text id="ijpbld"
app/about/page.tsx
```

creates:

```text id="14jdqc"
/about
```

---

# What Is layout.tsx?

This is where the App Router becomes powerful.

A layout defines UI that persists between routes.

Example:

```tsx id="klydba"
export default function Layout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <nav>Navbar</nav>
      {children}
      <footer>Footer</footer>
    </>
  );
}
```

Notice:

```text id="g15n9l"
Navbar
    stays

Footer
    stays

children
    changes
```

---

# Understanding children

Suppose we have:

```text id="dbxwji"
app/

layout.tsx
page.tsx
about/page.tsx
```

and:

```tsx id="j0ijow"
export default function Layout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <nav>Navbar</nav>

      {children}

      <footer>Footer</footer>
    </>
  );
}
```

When visiting:

```text id="q8pb0u"
/
```

Next.js builds:

```text id="wwic7n"
Layout
   ├── Navbar
   ├── HomePage
   └── Footer
```

When visiting:

```text id="r0c9r1"
/about
```

Next.js builds:

```text id="up6z1e"
Layout
   ├── Navbar
   ├── AboutPage
   └── Footer
```

The layout remains.

Only the children change.

---

# Nested Layouts

This becomes even more powerful.

Consider:

```text id="jz3s7m"
app/

layout.tsx

posts/
    layout.tsx
    page.tsx

posts/[slug]/
    page.tsx
```

Diagram:

```text id="jlwm6m"
Root Layout
       │
       ▼
 Posts Layout
       │
       ▼
   Post Page
```

Visiting:

```text id="phw6cn"
/posts
```

renders:

```text id="1on0n8"
Root Layout
      ↓
Posts Layout
      ↓
Posts Page
```

Visiting:

```text id="4ovmio"
/posts/react-server-components
```

renders:

```text id="5nvtyd"
Root Layout
      ↓
Posts Layout
      ↓
Article Page
```

---

# Why Layouts Matter

Imagine a navigation sidebar.

Without layouts:

```text id="mbg2df"
navigate
    ↓
destroy sidebar
    ↓
rebuild sidebar
```

With layouts:

```text id="yzocws"
navigate
    ↓
keep sidebar
    ↓
change content
```

Benefits:

* faster rendering,
* preserved state,
* fewer network requests,
* smoother navigation.

---

# How Next.js Thinks About Your Application

Beginners think:

```text id="36zn3o"
Website
   ↓
Pages
```

Next.js thinks:

```text id="40obdn"
Application
       ↓
Layouts
       ↓
Layouts
       ↓
Layouts
       ↓
Page
```

Example:

```text id="c7h2dn"
Root Layout
    │
    ▼
Blog Layout
    │
    ▼
Article Layout
    │
    ▼
Article Page
```

---

# The GreyMatter Journal Architecture

Eventually, our project will look like this:

```text id="xjlwm7"
app/

layout.tsx

page.tsx

articles/
    layout.tsx
    page.tsx

    [slug]/
        page.tsx

authors/
    page.tsx

    [slug]/
        page.tsx

categories/
    page.tsx

    [slug]/
        page.tsx
```

Visually:

```text id="lcvz3t"
Root Layout
      │
      ├── Home
      │
      ├── Articles
      │        └── Article
      │
      ├── Authors
      │        └── Author
      │
      └── Categories
               └── Category
```

---

# Mental Model To Remember Forever

The biggest mistake beginners make is thinking:

```text id="mjmhln"
Next.js = Pages
```

The correct mental model is:

```text id="xjlwm8"
Next.js = UI Tree
```

More specifically:

```text id="3r6nrm"
Application
      ↓
Layouts
      ↓
Nested Layouts
      ↓
Pages
      ↓
Components
```

Modern web applications are not collections of pages.

They are collections of user interfaces that persist while parts of the interface change.

---

# Up Next

In **Part 3**, we'll explore one of the most confusing files in every Next.js application:

```text id="p9xygn"
app/layout.tsx
```

We'll learn:

* what RootLayout actually is,
* what `children` actually means,
* what `React.ReactNode` actually means,
* why every Next.js application requires a layout,
* and how layouts fundamentally changed web application architecture.
