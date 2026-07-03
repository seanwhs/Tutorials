# GreyMatter Journal

# Part 12 — Building Dynamic Article Pages: Understanding Routes, URL Parameters, and Tree Traversal in Next.js 16

> **Goal of this lesson:** Build individual article pages and understand what dynamic routes actually are, how `[slug]` folders work, how URL parameters become function arguments, and why routing is really a form of tree traversal.

---

# Our Blog Has A Problem

Right now, our homepage works.

We can display:

```text
Latest Articles

Understanding React Server Components

Understanding Next.js Layouts

Understanding Sanity
```

But clicking an article does...

```text
Nothing.
```

Because we haven't built article pages yet.

---

# How Beginners Think About Routing

Most beginners imagine:

```text
URL
   ↓
HTML File
```

Like old websites:

```text
/about.html
/blog.html
/contact.html
```

---

# How Next.js Thinks About Routing

Next.js thinks differently.

It thinks:

```text
Folder Tree
        ↓
Application Tree
        ↓
Route Tree
```

Diagram:

```text
app/

├── page.tsx
│
├── about/
│     page.tsx
│
└── posts/
       page.tsx
```

becomes:

```text
/

├── /about
│
└── /posts
```

---

# But Articles Are Different

Suppose we publish:

```text
Understanding React Server Components
```

and:

```text
Understanding Next.js Layouts
```

We cannot create:

```text
app/

posts/

    understanding-react/
        page.tsx

    understanding-next/
        page.tsx
```

because:

```text
We don't know future articles.
```

Our routes must be dynamic.

---

# Enter Dynamic Routes

Next.js provides:

```text
[]
```

to represent variables.

Create:

```text
app/

posts/

    [slug]/

        page.tsx
```

Notice:

```text
[slug]
```

This means:

> Match any value.

---

# What Does This Actually Mean?

Suppose the user visits:

```text
/posts/react-server-components
```

Next.js internally performs:

```text
Find:

app/posts/[slug]/page.tsx

Then:

slug =
"react-server-components"
```

Diagram:

```text
URL

/posts/react-server-components

           │
           ▼

Match

posts/[slug]

           │
           ▼

slug =
"react-server-components"
```

---

# Step 1 — Update Our Homepage Links

Open:

```text
components/PostCard.tsx
```

Import:

```tsx
import Link from "next/link";
```

Update the title:

```tsx
<h2>
  <Link
    href={`/posts/${post.slug.current}`}
  >
    {post.title}
  </Link>
</h2>
```

---

# Wait...

What is this?

```tsx
`/posts/${post.slug.current}`
```

This is called:

# Template Literal Interpolation

Example:

```typescript
const name = "Sean";

console.log(
  `Hello ${name}`
);
```

Produces:

```text
Hello Sean
```

Similarly:

```typescript
post.slug.current
```

might contain:

```text
understanding-react-server-components
```

Result:

```text
/posts/understanding-react-server-components
```

---

# Step 2 — Create The Dynamic Route

Create:

```text
app/

posts/

    [slug]/

        page.tsx
```

Add:

```tsx
export default function PostPage() {
  return (
    <h1>
      Individual Article
    </h1>
  );
}
```

Now visit:

```text
/posts/anything
```

You'll see:

```text
Individual Article
```

---

# Wait...

How Did "Anything" Work?

Because:

```text
[slug]
```

means:

```text
Match everything.
```

Examples:

```text
/posts/react
/posts/next
/posts/sanity
/posts/hello-world
```

all map to:

```text
app/posts/[slug]/page.tsx
```

---

# The Secret: Parameters

Next.js automatically passes route values into your component.

Update:

```tsx
export default function PostPage({
  params,
}: {
  params: {
    slug: string;
  };
}) {
  return (
    <pre>
      {JSON.stringify(
        params,
        null,
        2
      )}
    </pre>
  );
}
```

Visit:

```text
/posts/react-server-components
```

You'll see:

```json
{
  "slug":
    "react-server-components"
}
```

---

# Where Did This Object Come From?

Internally:

```text
URL

/posts/react-server-components

        ↓

Router

        ↓

{
  slug:
    "react-server-components"
}
```

Then Next.js calls:

```typescript
PostPage({
  params: {
    slug:
      "react-server-components"
  }
});
```

Remember:

```text
React components
       =
functions
```

---

# Step 3 — Create The Article Query

Open:

```text
lib/queries.ts
```

Add:

```typescript
export const POST_QUERY = `
  *[
    _type == "post" &&
    slug.current == $slug
  ][0]{
    _id,

    title,

    excerpt,

    body,

    publishedAt,

    author->{
      name
    },

    categories[]->{
      title
    }
  }
`;
```

---

# Understanding `$slug`

This is a parameter.

Example:

```groq
slug.current == $slug
```

does NOT mean:

```text
slug.current == "$slug"
```

Instead it means:

```text
Insert variable here.
```

Example:

```typescript
{
  slug:
    "react-server-components"
}
```

produces:

```groq
slug.current ==
"react-server-components"
```

---

# Step 4 — Fetch The Article

Update:

```text
app/posts/[slug]/page.tsx
```

```tsx
import { client } from "@/lib/sanity";
import { POST_QUERY } from "@/lib/queries";

export default async function PostPage({
  params,
}: {
  params: {
    slug: string;
  };
}) {
  const post =
    await client.fetch(
      POST_QUERY,
      {
        slug:
          params.slug,
      }
    );

  return (
    <>
      <h1>
        {post.title}
      </h1>

      <p>
        By {post.author.name}
      </p>

      <p>
        {post.excerpt}
      </p>
    </>
  );
}
```

---

# Wait...

What Is This Second Argument?

```typescript
client.fetch(
  POST_QUERY,
  {
    slug:
      params.slug,
  }
)
```

This supplies variables.

Diagram:

```text
Query

slug.current == $slug

          ▲
          │

{
  slug:
   "react"
}
```

Think of it like:

```sql
SELECT *
WHERE slug = ?
```

---

# What Happens Internally?

Suppose we visit:

```text
/posts/react-server-components
```

Next.js performs:

```text
URL
    ↓

params.slug

    ↓

react-server-components

    ↓

GROQ Query

    ↓

Sanity

    ↓

Post Document

    ↓

React Component

    ↓

HTML
```

---

# Handling Missing Articles

What if somebody visits:

```text
/posts/does-not-exist
```

Currently:

```text
Crash.
```

That's bad.

Next.js provides:

```tsx
notFound()
```

Update:

```tsx
import { notFound }
  from "next/navigation";
```

Add:

```tsx
if (!post) {
  notFound();
}
```

Complete example:

```tsx
import { client }
  from "@/lib/sanity";

import { POST_QUERY }
  from "@/lib/queries";

import { notFound }
  from "next/navigation";

export default async function PostPage({
  params,
}: {
  params: {
    slug: string;
  };
}) {
  const post =
    await client.fetch(
      POST_QUERY,
      {
        slug:
          params.slug,
      }
    );

  if (!post) {
    notFound();
  }

  return (
    <>
      <h1>
        {post.title}
      </h1>

      <p>
        By {post.author.name}
      </p>

      <p>
        {post.excerpt}
      </p>
    </>
  );
}
```

---

# What Does `notFound()` Actually Do?

Many beginners think:

```text
Throw Error
```

Not exactly.

Instead:

```text
Tell Router:

This route
doesn't exist.
```

Diagram:

```text
Route Found?

    YES            NO
     │              │
     ▼              ▼

 Render        notFound()
                  │
                  ▼

              404 Page
```

---

# Let's Add Categories

Update:

```tsx
<div>
  {post.categories.map(
    category => (
      <span
        key={category.title}
      >
        {category.title}
      </span>
    )
  )}
</div>
```

---

# Our First Dynamic Rendering Pipeline

We now have:

```text
Browser

      ↓

/posts/react

      ↓

Next.js Router

      ↓

params.slug

      ↓

GROQ Query

      ↓

Sanity

      ↓

Post Document

      ↓

React Component

      ↓

HTML
```

---

# Why This Is Revolutionary

Traditional websites worked like this:

```text
Page File
      ↓
URL
```

Modern applications work like this:

```text
URL
     ↓
Data
     ↓
Component
     ↓
UI
```

The page no longer exists until data creates it.

---

# The Hidden Secret: Routing Is Tree Traversal

Suppose your application contains:

```text
app/

posts/

    [slug]/

        page.tsx
```

Next.js internally traverses:

```text
Root
   │
   ▼

posts
   │
   ▼

[slug]
   │
   ▼

page
```

This is literally:

```text
Tree Traversal
```

One of the most important concepts in computer science.

---

# Mental Model To Remember Forever

Most beginners think:

```text
URL
    =
Page
```

Modern frameworks think:

```text
URL
   ↓
Parameters
   ↓
Data Query
   ↓
Component
   ↓
UI
```

Or more abstractly:

```text
Route
     =
Function(URL)
```

This is the foundation of modern web architecture.

---

# Up Next

In **Part 13**, we'll tackle one of the hardest concepts in modern CMS development:

* rendering Portable Text,
* understanding why Sanity doesn't store HTML,
* building custom renderers,
* rendering headings, paragraphs, images, and links,
* and learning why rich text editors actually produce abstract syntax trees.
