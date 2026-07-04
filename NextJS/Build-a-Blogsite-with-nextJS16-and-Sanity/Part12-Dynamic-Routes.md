# ✅ Part 12 — Building Dynamic Article Pages

<img width="1246" height="1050" alt="image" src="https://github.com/user-attachments/assets/f87126fc-3d0f-46e6-bd87-0d6152df6c6e" />

# GreyMatter Journal

## Part 12 — Building Dynamic Article Pages: Understanding Routes, Parameters, and Tree Traversal

> **Goal of this lesson:** Build our first dynamic article page, understand how Next.js captures URL parameters, and discover why routing in modern web applications is fundamentally a problem of traversing trees.

---

# From Collections to Individual Resources

Our homepage now displays a collection of articles.

The next step is allowing readers to click on a post and view the complete article.

Conceptually, we're moving from:

```text
Collection
      ↓
Individual Resource
```

For our blog:

```text
Homepage
      ↓
List of Articles
      ↓
Single Article
```

This pattern exists throughout software:

```text
Products
      ↓
Product Detail

Users
      ↓
Profile Page

Movies
      ↓
Movie Detail

Orders
      ↓
Order Detail

Articles
      ↓
Article Page
```

The domain changes.

The architecture remains the same.

---

# The Fundamental Question

Suppose a user visits:

```text
/posts/understanding-react-server-components
```

How does Next.js know:

* which component to render?
* which article to fetch?
* where the value
  `understanding-react-server-components`
  came from?

Answering this question requires understanding one of the deepest ideas in the App Router:

> Routing is not page switching.
>
> Routing is structured tree traversal.

---

# Step 1 — Making Articles Clickable

Our `PostCard` component already contains a title.

We simply transform that title into a link:

```tsx
import Link from "next/link";

<Link
  href={`/posts/${post.slug.current}`}
  className="hover:underline"
>
  {post.title}
</Link>
```

Suppose our Sanity document contains:

```json
{
  "slug": {
    "current":
      "understanding-react-server-components"
  }
}
```

The generated URL becomes:

```text
/posts/understanding-react-server-components
```

Likewise:

```text
nextjs-16-app-router
```

becomes:

```text
/posts/nextjs-16-app-router
```

Every article now has its own address.

---

# Why Do We Use Slugs?

A slug is simply a human-readable identifier.

Instead of:

```text
/posts/83947298347
```

we prefer:

```text
/posts/understanding-react-server-components
```

Good URLs should be:

```text
✓ Human readable
✓ Predictable
✓ Stable
✓ Bookmarkable
✓ Search-engine friendly
```

Professional engineers often think of URLs as part of their application's public API.

Once a URL becomes public, changing it becomes expensive.

---

# Step 2 — Creating a Dynamic Route

Create:

```text
app/

└── (site)/
    └── posts/
        └── [slug]/
            └── page.tsx
```

The square brackets are special:

```text
[slug]
```

This tells Next.js:

> This segment is a variable.

You can mentally translate:

```text
[slug]
```

into:

```text
variable
```

or:

```text
:slug
```

if you've previously used Express, NestJS, or React Router.

---

# Understanding Dynamic Segments

Consider several URLs:

| URL                  | Captured Value  |
| -------------------- | --------------- |
| `/posts/hello-world` | `"hello-world"` |
| `/posts/react-hooks` | `"react-hooks"` |
| `/posts/nextjs-16`   | `"nextjs-16"`   |

Next.js automatically converts these into:

```typescript
{
  slug: "hello-world"
}
```

or:

```typescript
{
  slug: "react-hooks"
}
```

or:

```typescript
{
  slug: "nextjs-16"
}
```

You never create this object.

The router creates it for you.

---

# What Actually Happens Internally?

Suppose a user visits:

```text
/posts/react-server-components
```

Next.js begins traversing the application tree:

```text
app
 ↓
(site)
 ↓
posts
 ↓
[slug]
 ↓
page.tsx
```

The traversal looks conceptually like this:

```text
Find "posts"
        ✓

Find
"react-server-components"
        ✗

Find variable segment
"[slug]"
        ✓
```

At that point, the router captures:

```typescript
{
  slug:
    "react-server-components"
}
```

and passes it into the page.

---

# Routing Is Actually Tree Traversal

This reveals one of the deepest ideas in the App Router:

```text
Routing
       =
Tree Traversal
```

Consider:

```text
/posts/react/hooks
```

Internally, the router walks:

```text
app
 ↓
posts
 ↓
react
 ↓
hooks
```

Similarly:

```text
/authors/sean/posts/nextjs
```

becomes:

```text
app
 ↓
authors
 ↓
sean
 ↓
posts
 ↓
nextjs
```

The router is fundamentally traversing a tree.

This explains why file-system routing feels natural:

```text
Folder Structure
         =
Application Structure
```

---

# Step 3 — Creating the Article Page

Create:

```text
app/(site)/posts/[slug]/page.tsx
```

```tsx
import { client } from "@/lib/sanity";
import { POST_QUERY } from "@/lib/queries";
import { notFound } from "next/navigation";

export default async function PostPage({
  params,
}: {
  params: Promise<{
    slug: string;
  }>;
}) {
  const { slug } = await params;

  const post =
    await client.fetch(
      POST_QUERY,
      { slug }
    );

  if (!post) {
    notFound();
  }

  return (
    <article
      className="
        prose
        prose-lg
        mx-auto
        max-w-3xl
        px-6
        py-12
      "
    >
      <header className="mb-12">
        <h1
          className="
            mb-4
            text-5xl
            font-bold
            tracking-tight
          "
        >
          {post.title}
        </h1>

        <div
          className="
            flex
            gap-4
            text-sm
            text-gray-500
          "
        >
          <span>
            By {post.author.name}
          </span>

          <span>•</span>

          <time
            dateTime={
              post.publishedAt
            }
          >
            {new Date(
              post.publishedAt
            ).toLocaleDateString(
              "en-US",
              {
                year: "numeric",
                month: "long",
                day: "numeric",
              }
            )}
          </time>
        </div>
      </header>

      <p
        className="
          mb-10
          text-xl
          text-gray-600
        "
      >
        {post.excerpt}
      </p>

      {/* Portable Text
          comes next */}
    </article>
  );
}
```

---

# Wait... Why Is `params` a Promise?

One of the biggest surprises in Next.js 16 is this:

```typescript
params: Promise<{
  slug: string;
}>
```

instead of:

```typescript
params: {
  slug: string;
}
```

This means we write:

```typescript
const { slug } =
  await params;
```

rather than:

```typescript
const slug =
  params.slug;
```

At first, this feels strange.

However, modern Next.js treats routing as an asynchronous operation that integrates with:

```text
React Server Components
             ↓
Streaming
             ↓
Suspense
             ↓
Partial Rendering
             ↓
Future Router Optimizations
```

The router itself has become another asynchronous data source.

---

# Understanding TypeScript Generics

Many beginners ask:

```typescript
Promise<{
  slug: string;
}>
```

What do the angle brackets mean?

These are called **generics**.

Think of generics as labels attached to containers.

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

Likewise:

```typescript
Promise<number>
```

means:

```text
A Promise
that eventually
contains a number
```

And:

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

The generic tells TypeScript what will eventually emerge from the container.

---

# What Does `client.fetch()` Actually Do?

When we execute:

```typescript
const post =
  await client.fetch(
    POST_QUERY,
    { slug }
  );
```

we're effectively saying:

> Fetch the post whose slug matches the URL.

Suppose the user visits:

```text
/posts/why-nextjs-matters
```

The router produces:

```typescript
{
  slug:
    "why-nextjs-matters"
}
```

This value gets inserted into our GROQ query:

```groq
slug.current == $slug
```

which might return:

```typescript
{
  title:
    "Why Next.js Matters",

  excerpt:
    "...",

  author: {
    name:
      "Sean Wong"
  }
}
```

The complete pipeline becomes:

```text
URL
    ↓
Router
    ↓
params
    ↓
GROQ Query
    ↓
Sanity
    ↓
Document
    ↓
React UI
```

---

# What Happens When Content Doesn't Exist?

Suppose someone visits:

```text
/posts/this-post-does-not-exist
```

Our query returns:

```typescript
null
```

Instead of crashing, we write:

```typescript
if (!post) {
  notFound();
}
```

This tells Next.js:

> Render the nearest
>
> ```text
> not-found.tsx
> ```
>
> boundary.

This gives us:

```text
Graceful failure
        instead of
Application failure
```

---

# Dynamic Routes and Persistent UI

Remember our most important architectural principle:

> Modern applications are not collections of pages.

They are persistent UI trees.

When navigating from:

```text
/posts/nextjs-16
```

to:

```text
/posts/react-server-components
```

Next.js does not destroy the entire application.

Instead:

```text
Root Layout
       ↓
Site Layout
       ↓
Article Page
```

only the article page changes.

Everything else remains mounted:

```text
✓ Header stays
✓ Navigation stays
✓ Footer stays
✓ Theme stays
✓ Application state stays
```

This is why modern applications feel instantaneous.

---

# The Correct Mental Model

Traditional thinking:

```text
URL
    ↓
Page
```

Modern thinking:

```text
URL
    ↓
Router
    ↓
Route Parameters
    ↓
Data Fetching
    ↓
React Tree
    ↓
User Interface
```

And underneath everything:

```text
Routing
       =
Tree Traversal
```

This single idea explains why the App Router architecture feels so intuitive.

---

# The Most Important Idea To Remember

A URL is not merely a string.

A URL is:

```text
Serialized Application State
```

The router's job is to transform:

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

Once you understand this, file-system routing, dynamic segments, layouts, and Server Components all begin to feel like different pieces of the same system.

---
<img width="1023" height="1537" alt="image" src="https://github.com/user-attachments/assets/364faca2-0fa3-4ae1-8021-c70b2c9fcae0" />

---

# Up Next — Part 13: Rendering Portable Text

Next we'll learn:

* What Portable Text actually is
* Why structured content beats HTML
* Understanding content as an Abstract Syntax Tree (AST)
* Building custom Portable Text renderers
* Rendering headings, lists, images, and code blocks
* Building a professional typography system for GreyMatter Journal
