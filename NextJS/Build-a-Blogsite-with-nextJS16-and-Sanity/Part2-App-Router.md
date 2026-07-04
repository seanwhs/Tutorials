# Part 2 — Understanding the App Router: Why Modern Web Applications Are Not Collections of Pages

> **Goal of this lesson:** Build a correct mental model of the **Next.js App Router**: why folders become routes, what `page.tsx` and `layout.tsx` actually represent, and why modern applications are persistent **UI trees** instead of disconnected pages. [dev](https://dev.to/prateekshaweb/nextjs-app-router-for-beginners-pages-layouts-and-navigation-4kd)

***

# The Biggest Mental Shift in Next.js

Most developers start web development with a **page‑centric** worldview.

A website looks like a collection of files:

```text
home.html
about.html
blog.html
contact.html
```

Clicking a link traditionally meant:

```text
Destroy old page
        ↓
Request new page
        ↓
Load everything again
        ↓
Render entire page
```

This model worked well for document‑style websites.

But modern applications behave differently.

Think about tools you use every day:

- Gmail  
- Notion  
- GitHub  
- Linear  
- Slack  
- Discord  

When you navigate between screens, the entire application does not disappear and reload. Most of the interface remains stable—only certain regions change. [en.nextjs](https://en.nextjs.im/docs/app)

***

# What Actually Changes?

Consider GitHub:

```text
GitHub
├── Header
├── Left Navigation
├── Repository Navigation
└── Content Area
```

When you click:

```text
Issues
    ↓
Pull Requests
    ↓
Actions
```

What changes?

```text
✓ Content Area
```

What remains?

```text
✓ Header
✓ Navigation
✓ User Session
✓ Theme
✓ Application State
```

The application feels continuous and “alive.” Only one branch of the UI tree updates. [en.nextjs](https://en.nextjs.im/docs/app)

This is the fundamental insight behind the **App Router**. [en.nextjs](https://en.nextjs.im/docs/app)

***

# Traditional Websites vs Modern Applications

| Traditional Websites | Modern Applications |
| -------------------- | ------------------- |
| Full page reload     | Partial updates     |
| Entire page replaced | UI tree updated     |
| State lost           | State preserved     |
| Duplicate layouts    | Shared layouts      |
| Slower navigation    | Instant navigation  |
| Page-oriented        | Component-oriented  |

Traditional sites redraw the world on every navigation; modern apps surgically update the parts of the interface that actually changed. [dev](https://dev.to/prateekshaweb/nextjs-app-router-for-beginners-pages-layouts-and-navigation-4kd)

***

# The App Router Philosophy

The App Router changes the core question from:

> “Which **page** should I load?”

to:

> “Which **parts of the interface** actually need to change?”

That sounds subtle, but architecturally it changes everything.

Instead of thinking:

```text
Website
    =
Pages
```

we begin thinking:

```text
Application
    =
Persistent UI Tree
```

Next.js App Router is designed around this persistent tree: stable shells (layouts) plus changing leaves (pages and child components). [dev](https://dev.to/prateekshaweb/nextjs-app-router-for-beginners-pages-layouts-and-navigation-4kd)

***

# What Is the App Router?

The App Router is a **file‑system–based router** for React. [dev](https://dev.to/prateekshaweb/nextjs-app-router-for-beginners-pages-layouts-and-navigation-4kd)

Your folders become your URLs.

For example:

```text
app/
├── page.tsx
├── about/
│   └── page.tsx
└── posts/
    └── page.tsx
```

automatically becomes:

```text
/
 /about
 /posts
```

No explicit route configuration is required. The folder structure itself **is** the routing system. [nextjs](https://nextjs.org/docs/13/app/building-your-application/routing/defining-routes)

This concept is called:

```text
File-System Routing
```

You design the URL space by designing the `app/` tree.

***

# Folders Become Routes

Consider:

```text
app/
├── page.tsx
├── about/
│   └── page.tsx
├── posts/
│   ├── page.tsx
│   └── [slug]/
│       └── page.tsx
```

This produces:

| File                        | URL                    |
| --------------------------- | ---------------------- |
| `app/page.tsx`              | `/`                    |
| `app/about/page.tsx`        | `/about`               |
| `app/posts/page.tsx`        | `/posts`               |
| `app/posts/[slug]/page.tsx` | `/posts/my-first-post` |

Each folder in `app/` is a segment of the URL; each `page.tsx` in that folder is the renderable content for that segment. [nextjs](https://nextjs.org/docs/13/app/building-your-application/routing/defining-routes)

***

# Dynamic Routes

Sometimes we don’t know the URL values ahead of time.

For example:

```text
/posts/react-hooks
/posts/nextjs-app-router
/posts/system-design
```

Creating a file per post would be impossible and brittle.

Instead, we create a **dynamic segment**:

```text
app/posts/[slug]/page.tsx
```

The square brackets tell Next.js:

> “Match any value here and expose it as a route parameter.” [nextjs](https://nextjs.org/docs/app/api-reference/file-conventions/dynamic-routes)

***

# Understanding `[slug]`

Suppose the user visits:

```text
/posts/my-first-post
```

Next.js automatically provides:

```typescript
{
  slug: "my-first-post"
}
```

to your page component as part of the `params` prop. [nextjs](https://nextjs.org/docs/app/api-reference/file-conventions/dynamic-routes)

In modern Next.js (15+), route parameters are **asynchronous**, so your page component looks like this:

```tsx
export default async function PostPage({
  params,
}: {
  params: Promise<{
    slug: string;
  }>;
}) {
  const { slug } = await params;

  return <h1>{slug}</h1>;
}
```

The important pieces:

- The component is `async`.
- `params` is a `Promise`.
- You `await` it to read the slug. [zenn](https://zenn.dev/divsawa/articles/20251211_nextjs1516-dynamic-routing)

***

# Why Is `params` a Promise?

This surprises almost everyone learning modern Next.js.

Older versions worked like this:

```typescript
params.slug
```

Modern Next.js 15+ works like this:

```typescript
const { slug } = await params;
```

Why the change?

Because the App Router leans on modern React features:

- streaming  
- concurrent rendering  
- partial page generation  
- asynchronous Server Components  

By making `params` async, Next.js can:

- start rendering parts of the UI **before** all data and parameters are fully resolved,
- stream HTML to the browser as chunks,
- coordinate data fetching and route resolution in a single async pipeline. [joodi.medium](https://joodi.medium.com/why-params-became-a-promise-in-next-js-15-07813d39936b)

Think of it like a restaurant:

```text
Old system:
Wait for entire meal
        ↓
Serve everything

New system:
Serve appetizers
        ↓
Prepare remaining dishes
        ↓
Serve continuously
```

Next.js serves “appetizers” (already resolvable UI) as soon as possible while it finishes preparing the rest. This creates faster, more responsive applications. [joodi.medium](https://joodi.medium.com/why-params-became-a-promise-in-next-js-15-07813d39936b)

***

# Understanding `Promise<T>`

Many beginners get confused by this syntax:

```typescript
Promise<{
  slug: string;
}>
```

The angle brackets:

```typescript
<>
```

are called:

```text
TypeScript Generics
```

Generics are templates for types—like labels for boxes.

***

## Analogy: Labeled Boxes

Imagine three boxes:

```text
Promise<string>
Promise<number>
Promise<{ slug: string }>
```

Each box contains different data:

```text
Promise<string>
        ↓
     "hello"

Promise<number>
        ↓
        42

Promise<{ slug: string }>
        ↓
{
  slug: "react"
}
```

The generic tells TypeScript:

> “When I open this box (when the Promise resolves), what shape of data should I expect?”

Without the generic:

```typescript
Promise
```

TypeScript has no idea what’s inside.

With the generic:

```typescript
Promise<{ slug: string }>
```

TypeScript can provide:

- autocomplete  
- error checking  
- type validation  
- code navigation  

This matters a lot in larger codebases: the router and your components stay type‑safe even as the app grows. [dev](https://dev.to/prateekshaweb/nextjs-app-router-for-beginners-pages-layouts-and-navigation-4kd)

***

# Catch-All Routes

Sometimes a route contains **many** segments.

For example:

```text
/docs/react/hooks/useEffect
```

We can capture all segments using a **catch‑all segment**:

```text
app/docs/[...slug]/page.tsx
```

Example:

```tsx
export default async function DocsPage({
  params,
}: {
  params: Promise<{
    slug: string[];
  }>;
}) {
  const { slug } = await params;

  return (
    <pre>
      {JSON.stringify(slug)}
    </pre>
  );
}
```

Result for `/docs/react/hooks/useEffect`:

```text
[
  "react",
  "hooks",
  "useEffect"
]
```

Now you can map these segments to sections in your docs system, content lookup paths, or structured navigation models. [nextjs](https://nextjs.org/docs/13/app/building-your-application/routing/defining-routes)

***

# Optional Catch-All Routes

Sometimes the route may contain **zero or more** segments:

```text
/docs
/docs/react
/docs/react/hooks
```

We use an **optional catch‑all**:

```text
[[...slug]]
```

Example:

```text
app/docs/[[...slug]]/page.tsx
```

Possible values of `slug`:

```text
undefined

["react"]

["react", "hooks"]
```

This pattern is ideal for hierarchies like docs, categories, or filters, where deeper segments refine the view but the root route is still valid. [nextjs](https://nextjs.org/docs/app/api-reference/file-conventions/dynamic-routes)

***

# Route Groups

Folders wrapped in parentheses:

```text
(site)
(admin)
(auth)
```

do **not** affect the URL. [nextjs](https://nextjs.org/docs/13/app/building-your-application/routing/defining-routes)

Example:

```text
app/
└── (site)/
    └── about/
        └── page.tsx
```

still produces:

```text
/about
```

Route groups exist purely for **organization and layout composition**, not for browsers:

- They let you structure large apps (public site vs admin vs auth).
- They let you share different layouts with the same URL space (e.g. different shells for logged‑in vs logged‑out). [nextjs](https://nextjs.org/docs/13/app/building-your-application/routing/defining-routes)

Think of them as folders for humans, not for URLs.

***

# `page.tsx` — The Content Region

Every route segment requires a **page** file.

```tsx
export default function HomePage() {
  return (
    <div>
      <h1>GreyMatter Journal</h1>

      <p>
        Exploring software engineering
        and systems thinking.
      </p>
    </div>
  );
}
```

Think of:

```text
page.tsx
        =
Current Screen (for this segment)
```

It does **not** own `<html>` or `<body>`; it owns the portion of the UI that should change when the route changes. [en.nextjs](https://en.nextjs.im/docs/app)

***

# `layout.tsx` — The Persistent Shell

Layouts are the **long‑lived shells** around your pages. They remain mounted while you navigate through child routes. [en.nextjs](https://en.nextjs.im/docs/app)

```tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <nav>Navigation</nav>

        {children}

        <footer>Footer</footer>
      </body>
    </html>
  );
}
```

Think of:

```text
layout.tsx
        =
Application Shell
```

It defines:

- document structure (`<html>`, `<body>`)
- global providers (theme, auth, query clients)
- navigation and chrome (header, sidebar, footer) [dev](https://dev.to/prateekshaweb/nextjs-app-router-for-beginners-pages-layouts-and-navigation-4kd)

Because layouts persist, you should keep them focused on **stable UI and providers**, not ephemeral page‑specific state. [dev](https://dev.to/prateekshaweb/nextjs-app-router-for-beginners-pages-layouts-and-navigation-4kd)

***

# What Is `children`?

Another concept that confuses beginners is:

```tsx
{children}
```

The `children` prop means:

> “Insert whatever page (or nested layout) is currently active **here**.”

Visualize:

```text
Layout
   ↓

Header

{children}

Footer
```

If the current page is:

```text
/about
```

Then Next.js produces:

```text
Header

About Page

Footer
```

If the user navigates to:

```text
/posts
```

Next.js produces:

```text
Header

Posts Page

Footer
```

The layout never disappears. Only the content region (the part represented by `children`) changes. [en.nextjs](https://en.nextjs.im/docs/app)

This is the core of the “persistent UI tree” idea.

***

# Understanding `React.ReactNode`

You will often see:

```typescript
children: React.ReactNode
```

This simply means:

> “Anything React knows how to display.”

Examples include:

```typescript
<string>
<number>
<div>
<Component />
arrays
fragments
```

Think of:

```text
ReactNode
        =
Anything renderable
```

Typing `children` as `React.ReactNode` ensures your layouts can host arbitrary React UI trees: pages, nested layouts, shared components, and more. [en.nextjs](https://en.nextjs.im/docs/app)

***

# Understanding `globals.css`

Another important file is:

```text
app/globals.css
```

This file defines the **visual foundation** of your application.

Think of the three core files:

```text
page.tsx
        =
Page Content

layout.tsx
        =
Application Structure

globals.css
        =
Visual Language
```

Example:

```css
@import "tailwindcss";

:root {
  --background: white;
  --foreground: #171717;
}

body {
  background: var(--background);
  color: var(--foreground);
  font-family: Inter, sans-serif;
}
```

This introduces several important concepts:

- global styling  
- design tokens  
- CSS variables  
- typography systems  
- theming  
- design systems  

Together, `layout.tsx` and `globals.css` give you a consistent, persistent look and feel while pages and components change inside the shell. [en.nextjs](https://en.nextjs.im/docs/app)

***

# Nested Layouts

Layouts can exist **anywhere** in the `app/` tree. [nextjs](https://nextjs.org/docs/13/app/building-your-application/routing/defining-routes)

```text
app/
├── layout.tsx
│
└── posts/
    ├── layout.tsx
    └── [slug]/
        └── page.tsx
```

Visualized:

```text
Root Layout
    │
    ├── Header
    │
    └── Posts Layout
            │
            ├── Sidebar
            │
            └── Current Post
```

When navigating between posts:

```text
✓ Header remains
✓ Sidebar remains
✓ State remains
✓ Only post content changes
```

This creates:

- better performance  
- preserved state in shared sections  
- less JavaScript execution  
- smoother user experiences  

Senior‑level takeaway: use nested layouts to scope providers and shell UI to specific feature areas, reducing duplication and clarifying boundaries. [dev](https://dev.to/prateekshaweb/nextjs-app-router-for-beginners-pages-layouts-and-navigation-4kd)

***

# GreyMatter Journal Architecture

Our final structure will look like:

```text
app/
├── (site)/
│   ├── page.tsx
│   ├── about/
│   └── posts/
│       └── [slug]/
│
├── globals.css
└── layout.tsx
```

This gives us a clear hierarchy:

```text
Global Application Shell
            ↓
Site Layout
            ↓
Feature Layouts
            ↓
Page Components
            ↓
Child Components
```

Each level has a specific responsibility:

- **Global shell**: document, base providers, top‑level navigation.  
- **Site layout**: site‑wide chrome for public pages.  
- **Feature layouts**: local shells for posts, docs, etc.  
- **Pages**: route‑specific screens.  
- **Child components**: reusable UI pieces inside screens. [dev](https://dev.to/prateekshaweb/nextjs-app-router-for-beginners-pages-layouts-and-navigation-4kd)

***

# The Mental Model To Remember Forever

Beginners think:

```text
Next.js
        =
Pages
```

Professional engineers think:

```text
Next.js
        =
Persistent UI Tree

            ↓

Application Shell

            ↓

Nested Layouts

            ↓

Current Page

            ↓

Child Components
```

Modern web applications are not collections of pages. They are **living user interfaces** where stable pieces remain mounted while only the changing pieces update.

That single mental model explains almost everything in the App Router:

- why folders become routes,  
- why layouts exist and persist,  
- why `params` can be a `Promise`,  
- and why performance and UX improve when you update only the necessary branches of the UI tree. [en.nextjs](https://en.nextjs.im/docs/app)

***

# Up Next — Part 3: Understanding `app/layout.tsx`

In the next lesson, we will explore:

- why every Next.js application requires a root layout  
- how `<html>` and `<body>` work in App Router  
- what `React.ReactNode` really means in practice  
- how providers plug into layouts  
- how themes and fonts integrate with the shell  
- and how modern applications build **persistent application shells** that feel instant and continuous. [dev](https://dev.to/prateekshaweb/nextjs-app-router-for-beginners-pages-layouts-and-navigation-4kd)
