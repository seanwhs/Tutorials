# Next.js 16 for Absolute Beginners

# Part 35 — Cache Components and the New Next.js 16 Caching Architecture

> **Goal of this lesson:** Understand the single biggest conceptual change in Next.js 16: **Cache Components**. You'll learn how caching works, why Next.js changed its caching model, and how to use `"use cache"`, `cacheLife()`, and `cacheTag()` to build fast applications.

---

# This Is The Most Important Chapter So Far

If you remember only one thing about Next.js 16, remember this:

> **Next.js 16 changes caching from implicit behavior to explicit engineering.**

---

# The Old Mental Model

In older versions of Next.js, developers constantly asked:

```text
Is this:

SSR?
SSG?
ISR?
PPR?
Dynamic?
Static?
Revalidated?
```

This led to confusion.

---

# The New Mental Model

In Next.js 16:

```text
Everything starts dynamic.
```

You decide:

```text
What to cache.

How long to cache.

How to invalidate.

When to refresh.
```

---

# Old Next.js Architecture

```text
Request
    |
Framework Magic
    |
Maybe Cache?
    |
Maybe Render?
```

---

# Next.js 16 Architecture

```text
Request
    |
Your Code
    |
Your Cache Policy
    |
Your Invalidation
```

---

# Why Did Next.js Change?

Because modern applications have:

```text
Different data

Different lifetimes

Different freshness requirements
```

Example:

```text
Homepage Hero:
    update weekly

Blog Posts:
    update daily

Dashboard:
    update instantly

Notifications:
    update continuously
```

One caching strategy cannot solve all problems.

---

# Visualizing Modern Applications

```text
Application
     |
     +---- Static Content
     |
     +---- Cached Content
     |
     +---- Dynamic Content
     |
     +---- Real-Time Content
```

---

# What Are Cache Components?

Think of Cache Components as:

```text
Cached islands
```

inside your application.

Example:

```text
Page
    |
    +---- Header Cache
    |
    +---- Blog Cache
    |
    +---- Sidebar Cache
    |
    +---- User Session
```

---

# Visualizing Cache Boundaries

```text
+--------------------------------+
|                                |
|     Entire Application         |
|                                |
|    +------------------+        |
|    | Cached Region    |        |
|    +------------------+        |
|                                |
|    +------------------+        |
|    | Dynamic Region   |        |
|    +------------------+        |
|                                |
+--------------------------------+
```

---

# Step 1 — Enable Cache Components

Open:

```text
next.config.ts
```

---

```ts
import type {
  NextConfig,
} from "next";

const config:
  NextConfig = {

  cacheComponents:
    true,

};

export default config;
```

---

# What Does This Do?

It enables:

```text
✓ Cache Components
✓ Partial prerendering
✓ Explicit caching
✓ Tagged invalidation
✓ Streaming boundaries
```

---

# Step 2 — Create Our First Cache Component

Create:

```text
lib/posts.ts
```

---

```ts
export async function
getPosts() {

  "use cache";

  return db.post.findMany();

}
```

---

# Wait...

Did we just cache a function?

Yes.

---

# Visualizing Function Caching

Without cache:

```text
Request
    |
Database
```

Again:

```text
Request
    |
Database
```

Again:

```text
Request
    |
Database
```

---

With cache:

```text
Request
    |
Database
    |
Cache
```

Then:

```text
Request
    |
Cache
```

Then:

```text
Request
    |
Cache
```

---

# Why Cache Functions?

Because applications don't actually cache pages.

Applications cache:

```text
Operations.
```

Examples:

```text
Get posts

Get categories

Get settings

Get products

Get navigation
```

---

# Step 3 — Use Cached Data

```tsx
import {
  getPosts
} from "@/lib/posts";

export default async function
BlogPage() {

  const posts =
    await getPosts();

  return (

    <div>

      {posts.map(

        post => (

          <div
            key={
              post.id
            }
          >

            {post.title}

          </div>

        )

      )}

    </div>

  );

}
```

---

# What Happens Internally?

First request:

```text
Browser
    |
Server
    |
Database
    |
Cache
```

Second request:

```text
Browser
    |
Server
    |
Memory
```

---

# Step 4 — Set Cache Lifetime

Create:

```ts
import {
  cacheLife
} from
  "next/cache";

export async function
getPosts() {

  "use cache";

  cacheLife(
    "hours"
  );

  return db.post.findMany();

}
```

---

# What Is cacheLife?

It tells Next.js:

```text
How long the cache
may be reused.
```

---

# Example Lifetimes

```ts
cacheLife("seconds");

cacheLife("minutes");

cacheLife("hours");

cacheLife("days");
```

---

# Visualizing Cache Lifetime

```text
Cache Created
      |
      +------ 1 hour ------+
                           |
                      Expires
```

---

# Example Use Cases

```text
Navigation:
    days

Categories:
    hours

Blog Posts:
    hours

Dashboard:
    seconds

Admin:
    no cache
```

---

# Step 5 — Add Cache Tags

```ts
import {
  cacheTag
} from
  "next/cache";

export async function
getPosts() {

  "use cache";

  cacheTag(
    "posts"
  );

  cacheLife(
    "hours"
  );

  return db.post.findMany();

}
```

---

# What Is A Cache Tag?

A tag is:

```text
A name attached
to cache entries.
```

---

# Visualizing Tags

```text
Cache Entry
     |
     +---- posts

Cache Entry
     |
     +---- categories

Cache Entry
     |
     +---- homepage
```

---

# Why Tags Matter

Without tags:

```text
Change content
      |
Clear everything
```

Bad.

---

With tags:

```text
Change content
      |
Clear only
affected content
```

Good.

---

# Step 6 — Cache Individual Posts

```ts
export async function
getPost(
  slug: string
) {

  "use cache";

  cacheTag(
    `post:${slug}`
  );

  cacheLife(
    "hours"
  );

  return db.post.findUnique({

    where: {
      slug,
    },

  });

}
```

---

# Visualizing Post Cache

```text
post:react
post:nextjs
post:typescript
post:docker
```

---

# Step 7 — Cache Categories

```ts
export async function
getCategories() {

  "use cache";

  cacheTag(
    "categories"
  );

  cacheLife(
    "days"
  );

  return db.category
    .findMany();

}
```

---

# Visualizing Application Cache

```text
Application

    posts

    categories

    navigation

    settings

    products
```

---

# Step 8 — Revalidate Cache

Suppose an editor publishes a post.

---

Old cache:

```text
post:nextjs
```

must be refreshed.

---

```ts
import {
  revalidateTag
} from
  "next/cache";

revalidateTag(
  "posts"
);

revalidateTag(
  `post:${slug}`
);
```

---

# Visualizing Revalidation

```text
Content Update
       |
Invalidate Tag
       |
Delete Cache
       |
Next Request
       |
Fresh Data
```

---

# Why Not Immediately Refresh?

Because Next.js uses:

```text
Lazy revalidation
```

Meaning:

```text
Delete cache now

Recompute later
```

---

# Step 9 — updateTag()

Next.js 16 also provides:

```ts
import {
  updateTag
} from
  "next/cache";
```

---

Example:

```ts
updateTag(
  `post:${slug}`
);
```

---

# Difference Between Them

## revalidateTag()

```text
Delete cache.

Refresh on next request.
```

---

## updateTag()

```text
Refresh immediately
during mutations.
```

---

# Visualizing

```text
revalidateTag()

Update
   |
Delete
   |
Future Request
   |
Refresh
```

---

```text
updateTag()

Update
   |
Refresh
   |
Return
```

---

# When To Use Which?

Use:

```text
revalidateTag()
```

for:

```text
CMS updates

Webhooks

Background changes
```

---

Use:

```text
updateTag()
```

for:

```text
Server Actions

Forms

Mutations
```

---

# Step 10 — Cache Composition

Consider:

```text
Homepage
```

which contains:

```text
Hero

Categories

Featured Posts

Recent Posts
```

---

Instead of:

```text
One giant cache
```

use:

```text
Multiple caches
```

---

Example:

```tsx
<HomePage>

   <Hero />

   <Categories />

   <Featured />

   <Recent />

</HomePage>
```

---

Each component:

```text
Own cache

Own lifetime

Own invalidation
```

---

# Visualizing Composition

```text
Homepage

    Hero Cache

    Categories Cache

    Featured Cache

    Recent Cache
```

---

# Step 11 — Cache + Server Components

This is where Next.js becomes powerful.

---

```tsx
async function
FeaturedPosts() {

  const posts =

    await getPosts();

  return (
    <div />
  );

}
```

---

No:

```text
useEffect()

fetch()

loading state

client cache
```

---

Just:

```text
Server
    +
Cache
    +
Streaming
```

---

# Step 12 — Partial Prerendering

Suppose homepage:

```text
Hero
Blog
User Session
```

---

Hero:

```text
Static
```

Blog:

```text
Cached
```

User:

```text
Dynamic
```

---

Next.js automatically creates:

```text
Hybrid pages
```

---

# Visualizing PPR

```text
Page

    Static

    Cached

    Dynamic
```

All rendered independently.

---

# Step 13 — What Should Never Be Cached?

Never cache:

```text
User sessions

Authentication

Payments

Admin mutations

Personal data
```

---

Example:

BAD:

```ts
"use cache";

getCurrentUser();
```

---

Very bad.

---

# Step 14 — Cache Strategy Table

| Data            | Cache   |
| --------------- | ------- |
| Navigation      | Days    |
| Categories      | Hours   |
| Blog posts      | Hours   |
| Homepage        | Hours   |
| Dashboard       | Seconds |
| Session         | Never   |
| Payments        | Never   |
| Admin mutations | Never   |

---

# Final Cache Architecture

```text
                    Application
                           |
        +------------------+------------------+
        |                  |                  |
        V                  V                  V
    Static            Cached            Dynamic
        |                  |                  |
        V                  V                  V
      Hero             Posts            Session
      Logo             Search           Cart
      Footer           Categories       User
```

---

# What We've Learned

```text
✓ cacheComponents

✓ "use cache"

✓ cacheLife()

✓ cacheTag()

✓ revalidateTag()

✓ updateTag()

✓ Cache boundaries

✓ Partial prerendering

✓ Function caching

✓ Cache composition
```

---

# The Most Important Mental Shift

Old Next.js thinking:

```text
How do I cache pages?
```

Next.js 16 thinking:

```text
How do I cache data flows?
```

Because pages don't scale.

Data architectures do.

---

# Exercises

## Exercise 1

Cache:

```text
Featured posts
```

for:

```text
12 hours
```

---

## Exercise 2

Cache:

```text
Categories
```

for:

```text
24 hours
```

---

## Exercise 3

Create:

```text
post:{slug}
```

tagging.

---

## Exercise 4

Implement:

```text
publishPost()
```

using:

```text
updateTag()
```

---

# Mental Model

Beginners think:

```text
Cache
   =
Performance trick
```

Professional engineers think:

```text
Cache
   =
System architecture
```

Because in modern web applications:

> **Performance is architecture.**

---

# Part 36 Preview

In the next chapter we'll dive into:

# Partial Prerendering, Streaming, Suspense, and Progressive Rendering

Including:

```text
✓ Streaming
✓ Suspense
✓ Partial prerendering
✓ Progressive rendering
✓ Async components
✓ Loading boundaries
✓ Error boundaries
✓ Waterfalls
✓ Parallel fetching
✓ Rendering architecture
```

This is where Next.js becomes a distributed rendering system.
