# **✅ Part 3-2 — Understanding `params` and `searchParams`**

# GreyMatter Journal

## Part 3-2 — Understanding `params` and `searchParams`: How Pages Receive Reality from the Router

> **Goal of this lesson:** Understand how Next.js pages receive information from the URL, learn the difference between `params` and `searchParams`, and discover why routing is fundamentally about translating user intent into structured data.

---

# The Next Question Everyone Asks

After learning about `app/layout.tsx`, most beginners eventually encounter code like this:

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

Or:

```tsx
export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<{
    q?: string;
  }>;
}) {
  const { q } = await searchParams;

  return <div>{q}</div>;
}
```

This immediately raises a new set of questions:

* Where does `params` come from?
* Who creates `searchParams`?
* Why don't we pass them ourselves?
* What's the difference between them?
* Why are they typed?
* Why are they `Promise`s?

These questions reveal another important truth about modern web applications:

> Pages don't create reality.
>
> They receive reality from the router.

---

# The URL Is Data

Most beginners think of URLs as strings:

```text
/posts/react-server-components
```

But professional systems think of URLs differently.

A URL is structured information.

For example:

```text
/posts/react-server-components
```

actually contains:

```text
resource:
    posts

identifier:
    react-server-components
```

Likewise:

```text
/search?q=react
```

contains:

```text
operation:
    search

parameter:
    q = react
```

The job of the router is to transform URLs into structured data.

---

# Dynamic Routes

Suppose we create this file:

```text
app/
└── (site)/
    └── posts/
        └── [slug]/
            └── page.tsx
```

The folder:

```text
[slug]
```

is called a **dynamic segment**.

It tells Next.js:

> "Capture whatever appears here and give it to me."

For example:

```text
/posts/react
```

becomes:

```tsx
{
  slug: "react"
}
```

while:

```text
/posts/nextjs
```

becomes:

```tsx
{
  slug: "nextjs"
}
```

The router automatically constructs this object.

---

# Understanding `params`

Consider:

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

When a user visits:

```text
/posts/react-server-components
```

Next.js internally does something conceptually similar to:

```tsx
<PostPage
  params={
    Promise.resolve({
      slug:
        "react-server-components",
    })
  }
/>
```

You never create this object.

You never pass this object.

The router creates it automatically.

---

# Visualizing Dynamic Routes

Consider our application:

```text
app/

posts/
    [slug]/
        page.tsx
```

When visiting:

```text
/posts/react
```

the router performs:

```text
URL
    ↓

Route Match
    ↓

Extract Variables
    ↓

Create params
    ↓

Render Page
```

Visually:

```text
/posts/react

        ↓

{
    slug: "react"
}

        ↓

<PostPage />
```

---

# What About Multiple Parameters?

Suppose we build:

```text
app/

authors/
    [author]/
        posts/
            [slug]/
                page.tsx
```

Visiting:

```text
/authors/sean/posts/nextjs
```

produces:

```tsx
{
  author: "sean",
  slug: "nextjs",
}
```

The router simply maps folder names to values.

---

# Understanding `searchParams`

Now consider this URL:

```text
/search?q=react&page=2
```

This is not a route parameter.

This is a query string.

Everything after:

```text
?
```

becomes:

```tsx
{
  q: "react",
  page: "2",
}
```

Inside Next.js:

```tsx
export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<{
    q?: string;
    page?: string;
  }>;
}) {
  const { q, page } =
    await searchParams;

  return (
    <>
      <h1>{q}</h1>
      <p>{page}</p>
    </>
  );
}
```

Again, you never create this object.

The router creates it.

---

# The Difference Between `params` and `searchParams`

This distinction is extremely important.

## Route Parameters

```text
/posts/react
```

becomes:

```tsx
params = {
  slug: "react",
}
```

Route parameters identify resources.

---

## Search Parameters

```text
/search?q=react
```

becomes:

```tsx
searchParams = {
  q: "react",
}
```

Search parameters modify behavior.

---

Think of it this way:

```text
params
      =
What thing?

searchParams
      =
How should I view it?
```

Examples:

```text
/posts/react
        ↑
     What post?

/search?q=react
          ↑
     How to search?

/products?page=2
            ↑
     How to paginate?

/posts?sort=date
          ↑
     How to order?
```

---

# Why Are They Typed?

Consider:

```tsx
params: Promise<{
  slug: string;
}>
```

TypeScript creates a contract:

```text
Router
     ↓
Page
```

The router promises:

```text
I will provide:

{
    slug: string
}
```

Your page promises:

```text
I know how to handle:

{
    slug: string
}
```

This contract prevents entire classes of bugs.

---

# Why Are They `Promise`s?

In recent versions of Next.js, route information is asynchronous.

This allows Next.js to integrate routing with:

* React Server Components
* streaming
* Suspense
* server rendering
* partial rendering
* future router optimizations

Instead of:

```tsx
const slug =
  params.slug;
```

we now write:

```tsx
const { slug } =
  await params;
```

The router becomes another asynchronous data source.

---

# Real Example: Article Pages

Our future article page will look like this:

```tsx
export default async function PostPage({
  params,
}: {
  params: Promise<{
    slug: string;
  }>;
}) {
  const { slug } =
    await params;

  const post =
    await client.fetch(
      POST_QUERY,
      { slug }
    );

  if (!post) {
    notFound();
  }

  return (
    <article>
      <h1>{post.title}</h1>
    </article>
  );
}
```

The flow becomes:

```text
URL
     ↓

Router
     ↓

params
     ↓

Database Query
     ↓

Data
     ↓

React UI
```

---

# Real Example: Search Pages

Search pages work similarly:

```tsx
export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<{
    q?: string;
  }>;
}) {
  const { q } =
    await searchParams;

  const posts =
    q
      ? await searchPosts(q)
      : [];

  return (
    <SearchResults
      posts={posts}
    />
  );
}
```

The flow:

```text
URL
     ↓

searchParams
     ↓

Search Query
     ↓

Database
     ↓

Results
     ↓

UI
```

---

# The Router Is a Data Transformation Engine

Beginners often think:

```text
Router
     =
Page Switcher
```

Professional engineers think:

```text
Router
     =
URL Parser
     +
State Machine
     +
Data Provider
     +
Rendering Coordinator
```

The router continuously transforms:

```text
User Intent
        ↓

URL
        ↓

Structured Data
        ↓

React Tree
        ↓

User Interface
```

---

# The Correct Mental Model

Beginners think:

```text
URL
      =
String
```

Professional engineers think:

```text
URL
      =
Serialized Application State
```

More specifically:

```text
params
      =
Resource Identity

searchParams
      =
Resource Configuration
```

Or, even more broadly:

```text
User Intent
        ↓

URL
        ↓

Router
        ↓

Structured Data
        ↓

React Components
        ↓

User Interface
```

---

# The Most Important Idea To Remember

You never pass:

```tsx
params
```

You never create:

```tsx
searchParams
```

The router constructs both.

More importantly:

> Modern routing is not about navigating between pages.

It is about translating user intent into structured data that React can render.

However, once we understand that the router provides structured information, another question immediately appears:

> If the router knows which page we're rendering, how does Next.js know what metadata to generate?

For example:

```text
/posts/react-server-components
```

should ideally produce:

```html
<title>
  React Server Components
</title>

<meta
  name="description"
  content="An introduction to React Server Components..."
/>
```

while:

```text
/posts/nextjs-app-router
```

should produce:

```html
<title>
  Understanding the Next.js App Router
</title>
```

But where does this metadata come from?

How does Next.js generate different `<title>` tags for different pages?

And why does metadata generation participate in the same server-rendering pipeline as the page itself?

These questions lead us to one of the most important ideas in modern web applications:

> User interfaces are not the only thing applications render.

They also render metadata, documents, previews, social cards, and machine-readable descriptions of reality.

---

# Up Next — Part 3-3: Understanding `generateMetadata()`

Next, we'll explore how Next.js generates metadata dynamically using:

```tsx
export async function generateMetadata()
```

You'll learn:

* Why metadata is part of the rendering pipeline
* Static versus dynamic metadata
* How `params` flow into metadata generation
* SEO, Open Graph, and social previews
* Why metadata is really a second user interface
* How modern applications render both for humans and machines
