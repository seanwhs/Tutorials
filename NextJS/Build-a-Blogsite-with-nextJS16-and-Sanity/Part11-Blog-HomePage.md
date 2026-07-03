# GreyMatter Journal

# Part 11 — Building Our First Real Blog Homepage: Understanding Server Components, Async Rendering, and React Lists

> **Goal of this lesson:** Build the first real homepage for GreyMatter Journal and understand how Next.js Server Components fetch data, why `await` works inside components, how React renders lists, and what React components actually are.

---

# This Is The Moment Everything Comes Together

Up until now, we've built many pieces:

```text
✓ Next.js Application
✓ App Router
✓ Layouts
✓ Sanity Studio
✓ Content Models
✓ Content Lake
✓ Sanity Client
✓ GROQ Queries
```

But our website still looks like this:

```text
GreyMatter Journal

Welcome to GreyMatter Journal
```

Today we finally build:

```text
GreyMatter Journal

Latest Articles

[Article]
[Article]
[Article]
```

This is the first time our application becomes a real blog.

---

# What Are We Actually Building?

Our homepage should display:

```text
Latest Articles

Understanding React Server Components
by Sean Wong

A beginner-friendly introduction...

----------------------------------

Understanding Next.js Layouts
by Sean Wong

Persistent UI trees explained...
```

Conceptually:

```text
Database

Post
Post
Post

      ↓

Next.js

      ↓

React Components

      ↓

HTML
```

---

# Step 1 — Create A Query File

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
      name
    },

    categories[]->{
      title
    }
  }
`;
```

---

# Why Create Separate Query Files?

Many beginners do this:

```typescript
const posts =
  await client.fetch(`
    ...
  `);
```

inside every component.

This quickly becomes:

```text
Messy
Duplicated
Difficult to maintain
```

Instead:

```text
Queries
     ↓
lib/queries.ts

Components
     ↓
app/
```

This separation is called:

# Separation of Concerns

---

# Understanding Our Query

Let's read it like English.

---

## Step 1

```groq
*[_type == "post"]
```

means:

```text
Find all posts.
```

---

## Step 2

```groq
| order(publishedAt desc)
```

means:

```text
Sort newest first.
```

Diagram:

```text
Old
Old
New

      ↓

New
Old
Old
```

---

## Step 3

```groq
author->{
  name
}
```

means:

```text
Follow the author reference.
```

Diagram:

```text
Post
   │
   ▼
Author
```

---

## Step 4

```groq
categories[]->{
  title
}
```

means:

```text
Follow every category reference.
```

Diagram:

```text
Post

   ├── Category
   ├── Category
   └── Category
```

---

# Step 2 — Create A Post Card Component

Create:

```text
components/
```

Inside:

```text
components/PostCard.tsx
```

Add:

```tsx
type PostCardProps = {
  post: {
    _id: string;
    title: string;
    excerpt: string;
    publishedAt: string;

    author: {
      name: string;
    };

    categories: {
      title: string;
    }[];

    slug: {
      current: string;
    };
  };
};

export default function PostCard({
  post,
}: PostCardProps) {
  return (
    <article>
      <h2>{post.title}</h2>

      <p>
        By {post.author.name}
      </p>

      <p>
        {post.excerpt}
      </p>

      <p>
        Categories:
        {" "}
        {post.categories
          .map(
            category =>
              category.title
          )
          .join(", ")}
      </p>
    </article>
  );
}
```

---

# Wait...

Many beginners think:

```text
React Component
       =
HTML Template
```

Not quite.

A React component is simply:

```text
Function
      ↓
Returns UI Description
```

Diagram:

```text
Input Data
       │
       ▼
Function
       │
       ▼
User Interface
```

---

# Step 3 — Build The Homepage

Open:

```text
app/page.tsx
```

Replace everything:

```tsx
import { client } from "@/lib/sanity";
import { POSTS_QUERY } from "@/lib/queries";
import PostCard from "@/components/PostCard";

export default async function HomePage() {
  const posts =
    await client.fetch(
      POSTS_QUERY
    );

  return (
    <main>
      <h1>
        Latest Articles
      </h1>

      {posts.map(post => (
        <PostCard
          key={post._id}
          post={post}
        />
      ))}
    </main>
  );
}
```

---

# Wait...

Did we just do this?

```tsx
export default async function HomePage()
```

Yes.

And this is one of the biggest architectural changes in React history.

---

# Traditional React

Traditional React works like this:

```text
Render Empty UI
       ↓
Browser Fetches Data
       ↓
Receive Data
       ↓
Render Again
```

Diagram:

```text
Browser

Loading...

       ↓

Fetch

       ↓

Render
```

---

# Server Components

Server Components work differently:

```text
Fetch Data
      ↓
Render HTML
      ↓
Send To Browser
```

Diagram:

```text
Server

Fetch
   ↓
Render
   ↓
HTML
   ↓
Browser
```

This means:

```tsx
const posts =
  await client.fetch();
```

works directly inside components.

---

# Why Does This Feel Strange?

Because most of us learned React like this:

```tsx
useEffect(() => {
  fetch(...);
}, []);
```

Example:

```tsx
const [posts, setPosts] =
  useState([]);

useEffect(() => {
  fetchPosts();
}, []);
```

This creates:

```text
Render
    ↓
Fetch
    ↓
Re-render
```

But Server Components allow:

```text
Fetch
    ↓
Render
```

Which is dramatically simpler.

---

# What Does `map()` Actually Do?

This line:

```tsx
posts.map(post => (
  <PostCard
    key={post._id}
    post={post}
  />
))
```

confuses many beginners.

Suppose:

```typescript
const posts = [
  "React",
  "Next",
  "Sanity",
];
```

Then:

```typescript
posts.map(post =>
  `Article: ${post}`
);
```

produces:

```typescript
[
  "Article: React",
  "Article: Next",
  "Article: Sanity",
]
```

React simply does:

```text
Data
     ↓
map()
     ↓
Components
```

Diagram:

```text
Post
Post
Post

    ↓

Component
Component
Component
```

---

# What Is The `key` Prop?

This question has confused React developers for years.

Consider:

```text
A
B
C
```

Now imagine:

```text
A
X
B
C
```

React must determine:

```text
Which item changed?
```

Without keys:

```text
Everything looks new.
```

With keys:

```text
A unchanged

X added

B unchanged

C unchanged
```

Diagram:

```text
Before

1
2
3

After

1
4
2
3
```

Keys allow React to identify objects.

---

# Let's Improve The UI

Update:

```tsx
import { client } from "@/lib/sanity";
import { POSTS_QUERY } from "@/lib/queries";
import PostCard from "@/components/PostCard";

export default async function HomePage() {
  const posts =
    await client.fetch(
      POSTS_QUERY
    );

  return (
    <main>
      <h1>
        GreyMatter Journal
      </h1>

      <p>
        Thoughts on software,
        architecture,
        and engineering.
      </p>

      <hr />

      <h2>
        Latest Articles
      </h2>

      {posts.length === 0 ? (
        <p>
          No posts found.
        </p>
      ) : (
        posts.map(post => (
          <PostCard
            key={post._id}
            post={post}
          />
        ))
      )}
    </main>
  );
}
```

---

# Wait...

What Is This?

```tsx
posts.length === 0
  ? ...
  : ...
```

This is called:

# Conditional Rendering

Think of it as:

```text
IF posts exist

    show posts

ELSE

    show empty state
```

Diagram:

```text
Condition
      │
      ▼

 TRUE        FALSE
   │            │
   ▼            ▼

Posts      Empty State
```

---

# Our Rendering Pipeline

For the first time, our entire system is operational:

```text
Editor
   │
   ▼
Sanity Studio
   │
   ▼
Content Lake
   │
   ▼
GROQ Query
   │
   ▼
Sanity Client
   │
   ▼
Server Component
   │
   ▼
React Tree
   │
   ▼
HTML
   │
   ▼
Browser
```

---

# The Secret Of React Components

Many beginners think:

```text
React Components
       =
HTML Files
```

But React components are actually:

```text
Functions
      +
Data
      +
Composition
```

Or more formally:

```text
UI
    =
f(state)
```

Meaning:

```text
User Interface
        =
Function(Data)
```

This idea is the foundation of React.

---

# Mental Model To Remember Forever

Old web development:

```text
Database
     ↓
Template
     ↓
HTML
```

Modern React architecture:

```text
Data
    ↓
Functions
    ↓
Components
    ↓
UI Tree
    ↓
HTML
```

React isn't an HTML framework.

React is a system for transforming data into user interfaces.

---

# Up Next

In **Part 12**, we'll build our first dynamic article page and learn:

* what dynamic routes actually are,
* how `[slug]` folders work,
* how URL parameters become function arguments,
* how to fetch a single article,
* and why routing is really just tree traversal.
