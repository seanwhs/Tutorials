# ✅ Part 11 — Building Our First Real Blog Homepage

# GreyMatter Journal

## Part 11 — Building Our First Real Blog Homepage: Turning Content Into User Interfaces

> **Goal of this lesson:** Build our first real homepage using content from Sanity, and understand how modern React applications transform data into user interfaces using Next.js Server Components.

---

# Everything We've Learned Comes Together

Up until now, we've been building infrastructure:

```text
✓ Next.js Project
✓ App Router
✓ Layouts
✓ TypeScript
✓ Tailwind CSS
✓ Sanity Studio
✓ Content Models
✓ Data Connection
```

Now we finally build what readers will actually see:

```text
Homepage
        ↓
List of Articles
        ↓
Real Content
```

This is where modern web development starts becoming exciting.

---

# The Traditional Mental Model

Many beginners imagine websites working like this:

```text
Write HTML
        ↓
Display HTML
```

For example:

```html
<h1>My Blog</h1>

<p>My First Post</p>
```

But modern applications work differently.

Instead:

```text
Database
       ↓

Data

       ↓

React Components

       ↓

User Interface
```

The UI is generated from data.

---

# What We Want To Build

Eventually our homepage should look something like this:

```text
GreyMatter Journal

Exploring software engineering,
systems thinking, and architecture.


Latest Articles

----------------------------------

Understanding Event Sourcing
by Sean Wong

----------------------------------

Why Software Architecture Matters
by Sean Wong

----------------------------------

Building Systems That Scale
by Sean Wong
```

Notice something important:

We do not know ahead of time how many posts exist.

Maybe there are:

```text
0 posts

3 posts

100 posts

10,000 posts
```

Our UI must adapt automatically.

---

# Step 1 — Writing Our First Real Query

Create:

```text
lib/queries.ts
```

Add:

```typescript
export const POSTS_QUERY = `
  *[_type == "post"]
  | order(publishedAt desc)
  {
    _id,
    title,
    slug,
    excerpt,
    publishedAt,

    author->{
      name,
      slug
    },

    categories[]->{
      title,
      slug
    }
  }
`;
```

At first glance this looks scary.

But it's simply asking Sanity:

> Give me all documents where the type is `post`, sorted by publication date.

---

# Understanding The Query

Let's break it apart.

This:

```groq
*[_type == "post"]
```

means:

```text
Find all documents
whose type is "post"
```

This:

```groq
| order(publishedAt desc)
```

means:

```text
Sort by newest first
```

And this:

```groq
{
  title,
  excerpt
}
```

means:

```text
Only return these fields
```

Think of it like ordering food:

```text
Kitchen:
    "What would you like?"

You:
    "Give me all posts,
     newest first,
     and only send me
     the fields I need."
```

---

# What Data Comes Back?

Suppose Sanity contains:

```text
Post A
Post B
Post C
```

The query returns:

```typescript
[
  {
    title: "Understanding Event Sourcing",
    excerpt: "...",
  },

  {
    title: "Distributed Systems",
    excerpt: "...",
  },

  {
    title: "Software Architecture",
    excerpt: "...",
  },
];
```

Notice:

```text
The result is just an array.
```

Nothing magical.

---

# Step 2 — Building A Post Card

Rather than writing all our UI inside one file, we'll create a reusable component.

Create:

```text
components/posts/PostCard.tsx
```

```tsx
import Link from "next/link";

type Post = {
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
};

export default function PostCard({
  post,
}: {
  post: Post;
}) {
  return (
    <article
      className="
        rounded-xl
        border
        border-gray-200
        p-8
        transition
        hover:shadow-lg
      "
    >
      <h2
        className="
          mb-3
          text-3xl
          font-bold
          tracking-tight
        "
      >
        <Link
          href={`/posts/${post.slug.current}`}
        >
          {post.title}
        </Link>
      </h2>

      <p
        className="
          mb-4
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
      </div>
    </article>
  );
}
```

---

# Why Create A Separate Component?

Beginners often ask:

> Why not put everything inside `page.tsx`?

Because software grows.

This:

```text
page.tsx
        ↓
2000 lines
```

quickly becomes:

```text
😱
```

Instead:

```text
Homepage
      ↓

PostCard
      ↓

AuthorBadge
      ↓

CategoryBadge
```

Each component has one responsibility.

---

# Step 3 — Building The Homepage

Open:

```text
app/(site)/page.tsx
```

```tsx
import { client }
  from "@/lib/sanity";

import {
  POSTS_QUERY,
} from "@/lib/queries";

import PostCard
  from "@/components/posts/PostCard";

export default async function HomePage() {

  const posts =
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
      <div
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
          Exploring software
          engineering,
          systems thinking,
          and architecture.
        </p>
      </div>

      <section>
        <h2
          className="
            mb-8
            text-3xl
            font-semibold
          "
        >
          Latest Articles
        </h2>

        {posts.length === 0 ? (
          <p
            className="
              py-12
              text-center
              text-gray-500
            "
          >
            No posts yet.
          </p>
        ) : (
          <div className="space-y-10">
            {posts.map(
              (post: any) => (
                <PostCard
                  key={post._id}
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

# Wait... Why Is The Component `async`?

This is one of the biggest changes in modern React.

Old React:

```tsx
useEffect(() => {
  fetchPosts();
}, []);
```

Modern Next.js:

```tsx
export default async function HomePage() {
  const posts =
    await client.fetch();

  return (...);
}
```

Because this is a:

```text
Server Component
```

the code executes on the server first.

---

# What Actually Happens?

When someone visits:

```text
/
```

Next.js performs:

```text
Request arrives
        ↓

Server Component executes
        ↓

Fetch data from Sanity
        ↓

Build React tree
        ↓

Generate HTML
        ↓

Send HTML to browser
```

The browser receives:

```text
Finished HTML
```

This is why modern Next.js applications feel fast.

---

# Understanding `map()`

This line:

```tsx
posts.map(...)
```

is just JavaScript.

Suppose:

```javascript
const numbers = [
  1,
  2,
  3,
];
```

Then:

```javascript
numbers.map(
  number => number * 2
);
```

produces:

```javascript
[2, 4, 6]
```

React uses the same idea:

```text
Array of Data
        ↓

map()

        ↓

Array of UI
```

Example:

```text
Post Data
      ↓

PostCard
      ↓

Post Data
      ↓

PostCard
      ↓

Post Data
      ↓

PostCard
```

---

# Why Do We Need `key`?

React keeps track of items using:

```tsx
key={post._id}
```

Think of it as a passport number.

Without it:

```text
React:
    "Which post changed?"
```

With it:

```text
React:
    "I know exactly
     which post changed."
```

---

# The Most Important Mental Model

Many beginners think:

```text
React
     =
HTML Generator
```

Professional engineers think:

```text
Data
     ↓

React Components
     ↓

User Interface
```

Or even more accurately:

```text
Content
     ↓

Server Component
     ↓

React Tree
     ↓

HTML
     ↓

Browser
```

---

# Mental Model To Remember Forever

A React component is not a page.

A React component is a function that transforms data into user interfaces.

```text
Input:
    Data

Output:
    UI
```

Everything in modern React ultimately reduces to this one idea.

---

# Up Next — Part 12: Dynamic Article Pages

Next we'll build:

```text
posts/[slug]/page.tsx
```

and learn:

* Dynamic routes
* Route parameters
* `params: Promise<T>`
* Fetching a single document
* `notFound()`
* Rendering Portable Text
* Building our first real article page
