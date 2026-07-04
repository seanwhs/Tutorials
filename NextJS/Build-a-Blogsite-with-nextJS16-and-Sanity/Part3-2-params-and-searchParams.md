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

Or perhaps this:

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

This immediately creates a new set of questions:

* Where does `params` come from?
* Who creates `searchParams`?
* Why don't we pass them ourselves?
* Why are they typed?
* Why are they `Promise`s?
* What do the angle brackets (`< >`) mean?

These questions reveal another important truth about modern web applications:

> Pages don't create reality.
>
> They receive reality from the router.

---

# The URL Is Not A String

Beginners often think about URLs like this:

```text
/posts/react-server-components
```

as merely a string.

Professional systems think differently.

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

The router's job is to transform URLs into structured data.

---

# The Router Is A Translator

You can think of the router as a translator:

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
```

For example:

```text
/posts/react-server-components
```

becomes:

```typescript
{
  slug:
    "react-server-components"
}
```

while:

```text
/search?q=react
```

becomes:

```typescript
{
  q: "react"
}
```

The router continuously transforms URLs into JavaScript objects.

---

# Dynamic Routes

Suppose we create:

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

> Capture whatever appears here and give it to me.

For example:

```text
/posts/react
```

becomes:

```typescript
{
  slug: "react"
}
```

while:

```text
/posts/nextjs
```

becomes:

```typescript
{
  slug: "nextjs"
}
```

The router constructs this object automatically.

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
  const { slug } =
    await params;

  return <h1>{slug}</h1>;
}
```

When a user visits:

```text
/posts/react-server-components
```

Next.js conceptually performs something similar to:

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

Notice something important:

```text
You never create params.

You never pass params.

You never construct params.
```

The router does.

---

# Visualizing Route Resolution

Suppose our application contains:

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

# Multiple Route Parameters

Suppose we build:

```text
app/

authors/
    [author]/
        posts/
            [slug]/
                page.tsx
```

Then:

```text
/authors/sean/posts/nextjs
```

produces:

```typescript
{
  author: "sean",
  slug: "nextjs",
}
```

The router simply maps folder names to values.

---

# Understanding `searchParams`

Now consider:

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

```typescript
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

Again:

```text
You never create searchParams.

The router creates them.
```

---

# `params` vs `searchParams`

This distinction is one of the most important ideas in routing.

## Route Parameters

```text
/posts/react
```

becomes:

```typescript
params = {
  slug: "react"
}
```

Route parameters identify resources.

---

## Search Parameters

```text
/search?q=react
```

becomes:

```typescript
searchParams = {
  q: "react"
}
```

Search parameters modify behavior.

---

A useful mental model is:

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

```typescript
params: Promise<{
  slug: string;
}>
```

This creates a contract:

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

# Understanding `Promise<{ slug: string }>`

For many beginners, this line looks terrifying:

```typescript
Promise<{
  slug: string;
}>
```

In reality, it consists of three simple ideas.

---

## Layer 1 — Object Types

This:

```typescript
{
  slug: string;
}
```

means:

> An object containing a property called `slug`, and that property must be a string.

Example:

```typescript
{
  slug:
    "react-server-components"
}
```

---

## Layer 2 — Generics

<img width="587" height="348" alt="image" src="https://github.com/user-attachments/assets/8be9c4ec-4ffd-4d78-a3b3-2947f467d0b4" />


The angle brackets:

```typescript
<>
```

are called **generics**.

Think of generics as labels attached to containers.

For example:

```typescript
Array<string>
```

means:

```text
An array
containing strings
```

while:

```typescript
Array<number>
```

means:

```text
An array
containing numbers
```

The pattern is:

```text
Container<Type>
```

---

## Layer 3 — Promise<T>

A Promise is simply an asynchronous container.

For example:

```typescript
Promise<string>
```

means:

```text
A Promise
that eventually
contains a string
```

Visually:

```text
Promise
      ↓
(wait)
      ↓
"hello"
```

Similarly:

```typescript
Promise<number>
```

means:

```text
Promise
      ↓
(wait)
      ↓
42
```

---

# Putting Everything Together

Now we combine the pieces.

We know:

```typescript
{
  slug: string;
}
```

means:

```text
An object
containing a slug
```

Wrapping it inside a Promise:

```typescript
Promise<{
  slug: string;
}>
```

means:

```text
A Promise
that eventually
contains:

{
    slug: string
}
```

Visually:

```text
Promise
      ↓
(wait)
      ↓

{
    slug:
      "react-server-components"
}
```

---

# Why Are Route Parameters Asynchronous?

Older versions of Next.js behaved more like this:

```typescript
params: {
  slug: string;
}
```

Modern Next.js behaves like this:

```typescript
params: Promise<{
  slug: string;
}>
```

because routing now participates in the asynchronous rendering pipeline.

This allows Next.js to integrate with:

```text
React Server Components
            ↓
Streaming
            ↓
Suspense
            ↓
Partial Rendering
            ↓
Future Optimizations
```

The router itself has become another asynchronous data source.

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

The complete flow becomes:

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

# The Router Is A Data Transformation Engine

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

Or even more broadly:

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

```typescript
params
```

You never create:

```typescript
searchParams
```

The router constructs both.

More importantly:

> Modern routing is not about navigating between pages.

It is about translating user intent into structured data that React can render.

However, once we understand that the router provides structured information, another question immediately appears:

> If the router knows which page we're rendering, how does Next.js know what metadata to generate?

For example:

```html
<title>
  React Server Components
</title>
```

or:

```html
<title>
  Understanding the Next.js App Router
</title>
```

Where does this metadata come from?

How does metadata participate in the rendering pipeline?

These questions lead us to one of the most important ideas in modern web applications:

> Applications don't only render user interfaces.

They also render metadata, documents, previews, social cards, and machine-readable descriptions of reality.

---

# Up Next — Part 3-3: Understanding `generateMetadata()`

Next, we'll explore:

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
