# **✅ Part 11 — Building Our First Real Blog Homepage**

# GreyMatter Journal

## Part 11 — Building Our First Real Blog Homepage: How React Server Components Turn Data into User Interfaces

> **Goal of this lesson:** Build our first real homepage using content from Sanity and understand how React Server Components transform structured data into user interfaces.

---

# Everything Finally Comes Together

For the first time in this tutorial series, all of our architectural decisions begin to connect.

We now have:

```text
✓ Next.js 16
✓ App Router
✓ Root Layout
✓ Site Layout
✓ Sanity Studio
✓ Content Models
✓ Content Lake
✓ Sanity Client
✓ GROQ Queries
✓ Real Content
```

But our homepage still looks like this:

```text
GreyMatter Journal

Exploring software engineering...
```

Beautiful.

But static.

Today we make the transition from:

```text
Static Website
```

to:

```text
Dynamic Content Platform
```

---

# Remember Our Architecture

Everything we've built so far exists for one purpose:

```text
Writers
      ↓

Sanity Studio
      ↓

Content Lake
      ↓

GROQ Query
      ↓

Next.js
      ↓

React
      ↓

Browser
```

Our job today is simply to implement the final half of this pipeline.

---

# Step 1 — Create Our First Real Query

Create:

```text
lib/queries.ts
```

```typescript
export const POSTS_QUERY = `
*[_type=="post"]
| order(
    publishedAt desc
  )
{
  _id,

  title,

  slug,

  excerpt,

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

# Understanding What GROQ Is Actually Doing

Most beginners see:

```groq
*[_type=="post"]
```

and think:

```text
Database Query
```

That's true.

But GROQ is doing much more.

Our query performs:

```text
Find Posts
        ↓

Sort Posts
        ↓

Select Fields
        ↓

Follow References
        ↓

Construct New Objects
        ↓

Return Exactly
What React Needs
```

Visually:

```text
Content Lake
        ↓

Post Documents
        ↓

Author References
        ↓

Category References
        ↓

Final JSON Object
```

This is why GROQ is so powerful.

---

# The Data Shape We Receive

Suppose we have one article.

Our query returns something similar to:

```json
[
  {
    "_id": "abc123",

    "title":
      "Understanding React Server Components",

    "slug": {
      "current":
        "understanding-react-server-components"
    },

    "excerpt":
      "A beginner-friendly introduction.",

    "publishedAt":
      "2026-07-05",

    "author": {
      "name":
        "Sean Wong"
    },

    "categories": [
      {
        "title":
          "Architecture"
      },
      {
        "title":
          "Web Development"
      }
    ]
  }
]
```

Notice something important:

```text
No HTML.

No Components.

No UI.
```

Just:

```text
Structured Data
```

---

# Step 2 — Describe The Contract

Create:

```text
types/post.ts
```

```typescript
export interface Post {
  _id: string;

  title: string;

  slug: {
    current: string;
  };

  excerpt: string;

  publishedAt: string;

  author: {
    name: string;
  };

  categories: {
    title: string;
  }[];
}
```

---

# Why Create Types?

Beginners often think:

```text
TypeScript
      =
Extra Work
```

Professional engineers think:

```text
TypeScript
      =
Reality Documentation
```

This interface describes a contract:

```text
Sanity
     ↓

Returns

     ↓

Post Object
```

If Sanity changes:

```text
TypeScript warns us.
```

---

# Step 3 — Create Our First Real Component

Create:

```text
components/posts/PostCard.tsx
```

```tsx
import Link
  from "next/link";

import type {
  Post,
} from "@/types/post";

export default function
PostCard({
  post,
}: {
  post: Post;
}) {
  return (
    <article
      className="
        rounded-2xl
        border
        border-gray-200
        p-8
        transition
        hover:shadow-lg
      "
    >
      <div
        className="
          mb-4
          flex
          gap-2
        "
      >
        {post.categories.map(
          (category) => (
            <span
              key={
                category.title
              }
              className="
                text-xs
                uppercase
                tracking-widest
                text-blue-600
              "
            >
              {category.title}
            </span>
          )
        )}
      </div>

      <Link
        href={
          `/posts/${post.slug.current}`
        }
      >
        <h2
          className="
            mb-4
            text-3xl
            font-bold
            tracking-tight
            hover:underline
          "
        >
          {post.title}
        </h2>
      </Link>

      <p
        className="
          mb-6
          text-gray-600
        "
      >
        {post.excerpt}
      </p>

      <div
        className="
          text-sm
          text-gray-500
        "
      >
        By {post.author.name}
        {" • "}
        {
          new Date(
            post.publishedAt
          ).toLocaleDateString()
        }
      </div>
    </article>
  );
}
```

---

# What Is A React Component Really?

Beginners often think:

```text
Component
      =
HTML Template
```

Professional engineers think:

```text
Component
      =
Function
```

More specifically:

```text
Data
     ↓

Function
     ↓

UI
```

Our component:

```text
Post Object
       ↓

PostCard()
       ↓

React Elements
```

This is one of the most important ideas in React.

---

# Step 4 — Build The Homepage

Open:

```text
app/(site)/page.tsx
```

Replace everything with:

```tsx
import {
  client,
} from "@/lib/sanity";

import {
  POSTS_QUERY,
} from "@/lib/queries";

import PostCard
  from "@/components/posts/PostCard";

import type {
  Post,
} from "@/types/post";

export default async function
HomePage() {

  const posts:
    Post[] =
      await client.fetch(
        POSTS_QUERY
      );

  return (
    <div
      className="
        mx-auto
        max-w-4xl
        px-6
        py-12
      "
    >
      <section
        className="
          mb-16
          text-center
        "
      >
        <h1
          className="
            mb-6
            text-6xl
            font-bold
            tracking-tight
          "
        >
          GreyMatter Journal
        </h1>

        <p
          className="
            mx-auto
            max-w-md
            text-xl
            text-gray-600
          "
        >
          Exploring
          software engineering,
          systems thinking,
          and architecture.
        </p>
      </section>

      <section>
        <h2
          className="
            mb-10
            text-3xl
            font-semibold
          "
        >
          Latest Articles
        </h2>

        {posts.length === 0
          ? (
            <p
              className="
                py-12
                text-center
                text-gray-500
              "
            >
              No posts yet.
            </p>
          )
          : (
            <div
              className="
                space-y-12
              "
            >
              {posts.map(
                (post) => (
                  <PostCard
                    key={
                      post._id
                    }
                    post={post}
                  />
                )
              )}
            </div>
          )}
      </section>
    </div>
  );
}
```

---

# Notice What We Didn't Write

Many beginners expect:

```tsx
useState()

useEffect()

loading

fetch()

axios
```

But we wrote none of them.

Why?

Because:

```text
HomePage
```

is a:

```text
React Server Component
```

---

# Understanding React Server Components

When the browser requests:

```text
/
```

this happens:

```text
Browser
      ↓

Next.js Server
      ↓

HomePage()
      ↓

Sanity Query
      ↓

Data
      ↓

React Tree
      ↓

HTML
      ↓

Browser
```

Notice:

```text
The browser never
fetches Sanity.
```

The server does.

---

# Visualizing The Entire Render Pipeline

What users see:

```text
Browser
```

What actually happens:

```text
Request
     ↓

React Server Component
     ↓

Fetch Data
     ↓

Build React Tree
     ↓

Generate HTML
     ↓

Send HTML
     ↓

Browser
```

This is fundamentally different from traditional React SPAs.

---

# Why Server Components Matter

Traditional React:

```text
Browser
      ↓

Download JS
      ↓

Execute JS
      ↓

Fetch API
      ↓

Render UI
```

React Server Components:

```text
Server
      ↓

Fetch API
      ↓

Render UI
      ↓

Send HTML
      ↓

Browser
```

Advantages:

```text
✓ Better SEO
✓ Faster loading
✓ Smaller bundles
✓ Better performance
✓ Better security
✓ Simpler code
```

---

# The Most Important Mental Model

Beginners think:

```text
React
     =
Frontend Framework
```

Professional engineers think:

```text
React
     =
UI Transformation Engine
```

More specifically:

```text
Data
     ↓

Components
     ↓

React Tree
     ↓

HTML
     ↓

User Interface
```

Or, for our application:

```text
Sanity Content
        ↓

GROQ
        ↓

Server Component
        ↓

PostCard Components
        ↓

HTML
        ↓

Browser
```

---

# The Most Important Idea To Remember

Our homepage doesn't store articles.

Our homepage doesn't create articles.

Our homepage doesn't manage articles.

It simply transforms:

```text
Structured Data
```

into:

```text
User Experience
```

This is the essence of React:

> React components are functions that transform data into interfaces.

---

# Up Next — Part 12: Dynamic Article Pages

Next we'll build our first dynamic route:

```text
app/

posts/
    [slug]/
        page.tsx
```

We'll learn:

* Dynamic routing
* `params`
* Fetching a single article
* `notFound()`
* Error handling
* Rendering Portable Text
* Why URLs are really structured data
