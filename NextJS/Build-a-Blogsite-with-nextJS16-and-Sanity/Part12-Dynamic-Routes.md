# ✅ Part 12 — Building Dynamic Article Pages

# GreyMatter Journal

## Part 12 — Building Dynamic Article Pages: Understanding Routes, Parameters, and Tree Traversal

<img width="1246" height="1050" alt="image" src="https://github.com/user-attachments/assets/f87126fc-3d0f-46e6-bd87-0d6152df6c6e" />

> **Goal of this lesson:** Build our first dynamic article page, understand how Next.js captures URL parameters, and discover why routing in modern web applications is fundamentally a problem of traversing trees.

---

# From Lists to Individual Pages

Our homepage now displays a list of articles.

The next step is allowing readers to click on a post and view the full article.

Visually:

```text
Homepage
    ↓
List of Articles
    ↓
Single Article
```

This pattern exists everywhere:

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

Articles
      ↓
Article Page
```

The data changes.

The architecture stays the same.

---

# Step 1 — Making Articles Clickable

In our `PostCard` component, we already have the post title.

Now we'll wrap it with a Next.js `Link`:

```tsx
import Link from "next/link";

<Link
  href={`/posts/${post.slug.current}`}
  className="hover:underline"
>
  {post.title}
</Link>
```

Suppose a post has this slug:

```text
understanding-react-server-components
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

---

# Why Are Slugs Important?

A slug is simply a URL-friendly identifier.

Instead of:

```text
/posts/87234987234
```

we create:

```text
/posts/understanding-react-server-components
```

Good URLs should be:

```text
✓ Human readable
✓ Predictable
✓ Stable
✓ Search-engine friendly
```

In many ways, URLs become part of your application's public API.

---

# Step 2 — Creating a Dynamic Route

Create:

```text
app/(site)/posts/[slug]/page.tsx
```

Notice the square brackets:

```text
[slug]
```

This tells Next.js:

> This part of the URL is a variable.

Our application structure now becomes:

```text
app/

└── (site)/
    └── posts/
        └── [slug]/
            └── page.tsx
```

---

# Understanding `[slug]`

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

if you've used other frameworks.

Examples:

| URL                  | Captured Value  |
| -------------------- | --------------- |
| `/posts/hello-world` | `"hello-world"` |
| `/posts/react-hooks` | `"react-hooks"` |
| `/posts/nextjs-16`   | `"nextjs-16"`   |

---

# What Happens Internally?

Suppose a user visits:

```text
/posts/react-server-components
```

Next.js searches the application tree:

```text
app/
    ↓
(site)/
    ↓
posts/
    ↓
[slug]/
    ↓
page.tsx
```

When it reaches:

```text
[slug]
```

it says:

> I don't have an exact folder called
>
> ```text
> react-server-components
> ```
>
> but I do have a variable folder.

So it captures:

```typescript
{
  slug:
    "react-server-components"
}
```

and passes it into our page.

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

Internally:

```text
app
 ↓
posts
 ↓
react
 ↓
hooks
```

The router simply walks the folder tree.

This is why file-system routing feels so natural:

```text
Folder Structure
        =
Application Structure
```

---

# Step 3 — Building the Article Page

Create:

```text
app/(site)/posts/[slug]/page.tsx
```

```tsx
import { client }
  from "@/lib/sanity";

import {
  POST_QUERY,
} from "@/lib/queries";

import {
  notFound,
} from "next/navigation";

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
      <header
        className="mb-12"
      >
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

In Next.js 16, route parameters are asynchronous.

Instead of:

```typescript
params: {
  slug: string;
}
```

we now write:

```typescript
params: Promise<{
  slug: string;
}>
```

and then:

```typescript
const { slug } =
  await params;
```

This initially feels strange.

However, it allows Next.js to integrate route handling with:

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

---

# Understanding TypeScript Generics

Many beginners ask:

```typescript
Promise<{
  slug: string;
}>
```

What do the angle brackets mean?

The angle brackets:

```text
< >
```

are called **TypeScript Generics**.

Think of them as labels on containers.

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

---

# What Does `client.fetch()` Return?

When we run:

```typescript
const post =
  await client.fetch(
    POST_QUERY,
    { slug }
  );
```

we are saying:

> Ask Sanity for the post whose slug matches the URL.

For example:

```text
/posts/why-nextjs-matters
```

becomes:

```typescript
{
  slug:
    "why-nextjs-matters"
}
```

which gets inserted into:

```groq
slug.current == $slug
```

and returns:

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

---

# What Does `notFound()` Do?

Suppose someone visits:

```text
/posts/this-does-not-exist
```

Our query returns:

```typescript
null
```

Instead of crashing, we do:

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
> page.

This gives us graceful error handling.

---

# Dynamic Routes and Persistent UI

Remember our most important architectural idea:

> Modern applications are not collections of pages.

They are persistent UI trees.

When navigating between:

```text
/posts/nextjs-16
```

and:

```text
/posts/react-server-components
```

Next.js does not rebuild everything.

Instead:

```text
Root Layout
       ↓
Site Layout
       ↓
Article Page
```

only the article page changes.

The rest stays mounted.

This is why modern applications feel fast.

---

# Mental Model To Remember Forever

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

This single idea explains why the App Router architecture feels so natural.

---

# Up Next — Part 13: Rendering Portable Text

Next we'll learn:

* What Portable Text actually is
* Why structured content beats HTML
* Building custom Portable Text renderers
* Rendering headings, lists, images, and code blocks
* Building a professional typography system for GreyMatter Journal
