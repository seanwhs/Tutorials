# Next.js 16 for Absolute Beginners

# Part 9 — Cache Components: Understanding the Biggest Change in Next.js 16

> **Goal of this lesson:** Understand the new caching model introduced in Next.js 16, why caching became explicit, and how Cache Components change the way we build web applications.

---

# Welcome to the Most Important Next.js 16 Feature

Up until now, we've been writing code like this:

```tsx
export default async function PostsPage() {

    const response =
        await fetch(
            "https://jsonplaceholder.typicode.com/posts"
        );

    const posts =
        await response.json();

    return (
        <div>
            {posts.length}
        </div>
    );
}
```

This works.

But a question immediately appears:

> Should this data be cached?

And if yes:

* how long?
* where?
* when should it refresh?
* who refreshes it?
* what happens when content changes?

For many years, Next.js tried to answer these questions automatically.

That turned out to be very difficult.

---

# The Old Next.js Mental Model

Before Next.js 16, caching often felt mysterious.

Example:

```tsx
fetch(url, {
    next: {
        revalidate: 60
    }
});
```

Or:

```tsx
export const revalidate = 3600;
```

Or:

```tsx
export const dynamic =
    "force-static";
```

Or:

```tsx
export const dynamic =
    "force-dynamic";
```

Developers often asked:

> Why is my page cached?

or:

> Why isn't my page cached?

---

# The Problem

Consider this page:

```tsx
export default async function Page() {

    const user =
        await getUser();

    const posts =
        await getPosts();

    return (
        <>
            <User user={user} />
            <Posts posts={posts} />
        </>
    );
}
```

Questions:

```text
Should User be cached?

Should Posts be cached?

Should both be cached?

Should neither be cached?

Should they have different lifetimes?
```

The framework had to guess.

And guessing is hard.

---

# Next.js 16 Changes Everything

The new philosophy is:

> **Nothing is cached unless you explicitly say so.**

This is the most important idea in Next.js 16.

---

# Old Mental Model

```text
Next.js
     |
     |
     +--- tries to guess
           what to cache
```

---

# New Mental Model

```text
Developer
      |
      |
      +--- explicitly
            declares
            cache behavior
```

You decide:

* what gets cached
* how long
* when it expires
* how it refreshes

---

# Enabling Cache Components

Open:

```text
next.config.ts
```

Add:

```ts
import type { NextConfig }
    from "next";

const nextConfig: NextConfig = {

    cacheComponents: true,

};

export default nextConfig;
```

This enables:

# Cache Components

---

# What Is a Cache Component?

A Cache Component is simply:

```text
React Component
        +
Explicit Cache Rules
```

Example:

```text
Component
      |
      +--- cache lifetime
      |
      +--- cache tags
      |
      +--- invalidation rules
```

---

# Introducing "use cache"

This is the most important directive in Next.js 16.

Example:

```tsx
export async function getPosts() {

    "use cache";

    return fetchPosts();
}
```

This tells Next.js:

> cache the result of this function.

---

# Our First Cached Function

Create:

```text
lib/posts.ts
```

```tsx
export async function getPosts() {

    "use cache";

    const response =
        await fetch(
            "https://jsonplaceholder.typicode.com/posts"
        );

    return response.json();
}
```

---

Now use it:

```tsx
import { getPosts }
    from "@/lib/posts";

export default async function Page() {

    const posts =
        await getPosts();

    return (
        <div>

            Posts:
            {posts.length}

        </div>
    );
}
```

---

# What Happens?

First request:

```text
Request
    ↓
Execute function
    ↓
Store result
```

Second request:

```text
Request
    ↓
Return cache
```

No API call.

---

# Visualizing "use cache"

Without caching:

```text
Request
    ↓
API
    ↓
Response

Request
    ↓
API
    ↓
Response
```

---

With:

```tsx
"use cache";
```

```text
Request
    ↓
API
    ↓
Cache

Request
    ↓
Cache
```

---

# Cache Lifetime

Suppose we want:

```text
Cache for:
5 minutes
```

We use:

```tsx
import {
    cacheLife
} from "next/cache";
```

Example:

```tsx
import {
    cacheLife
} from "next/cache";

export async function getPosts() {

    "use cache";

    cacheLife("minutes");

    const response =
        await fetch(
            "https://jsonplaceholder.typicode.com/posts"
        );

    return response.json();
}
```

---

# Common Cache Lifetimes

```tsx
cacheLife("seconds");
cacheLife("minutes");
cacheLife("hours");
cacheLife("days");
cacheLife("weeks");
```

Think:

```text
How stale can this data become?
```

---

# Example: Blog Posts

Blog posts rarely change.

```tsx
export async function getPosts() {

    "use cache";

    cacheLife("hours");

    return database.posts();
}
```

---

# Example: Weather

Weather changes frequently.

```tsx
export async function getWeather() {

    "use cache";

    cacheLife("minutes");

    return weatherAPI();
}
```

---

# Example: Stock Prices

Stock prices change constantly.

```tsx
export async function getStocks() {

    return stockAPI();
}
```

No cache.

---

# Cache Tags

Sometimes we want to invalidate groups of cached data.

Example:

```text
Posts
    |
    +--- Post 1
    +--- Post 2
    +--- Post 3
```

If Post 2 changes:

```text
Invalidate:
posts
```

---

# Using cacheTag()

```tsx
import {
    cacheTag
} from "next/cache";

export async function getPosts() {

    "use cache";

    cacheTag("posts");

    return fetchPosts();
}
```

---

# Multiple Tags

```tsx
export async function getPost(
    slug: string
) {

    "use cache";

    cacheTag("posts");

    cacheTag(
        `post:${slug}`
    );

    return fetchPost(slug);
}
```

---

# Visualizing Cache Tags

```text
Cache
   |
   +--- posts
   |
   +--- post:react
   |
   +--- post:nextjs
   |
   +--- post:python
```

---

# Why Tags Matter

Suppose:

```text
User edits:

react
```

We invalidate:

```text
post:react
```

Only one cache entry disappears.

Everything else remains cached.

---

# Partial Prerendering

This is another major feature of Cache Components.

Imagine:

```text
Page
   |
   +--- Header
   |
   +--- Sidebar
   |
   +--- User Feed
```

Header:

```text
Rarely changes
```

Sidebar:

```text
Rarely changes
```

User Feed:

```text
Changes constantly
```

---

# Traditional Rendering

```text
Render everything
every request
```

---

# Partial Prerendering

```text
Pre-render:
    Header
    Sidebar

Stream:
    User Feed
```

---

# Visualizing Partial Prerendering

```text
STATIC
   |
   +--- Header
   |
   +--- Sidebar

DYNAMIC
   |
   +--- Feed
```

This gives:

* static performance
* dynamic freshness

simultaneously.

---

# Building a Cached Data Layer

Create:

```text
lib/data.ts
```

---

```tsx
import {
    cacheLife,
    cacheTag
} from "next/cache";

export async function getUsers() {

    "use cache";

    cacheLife("hours");

    cacheTag("users");

    const response =
        await fetch(
            "https://jsonplaceholder.typicode.com/users"
        );

    return response.json();
}
```

---

```tsx
export async function getPosts() {

    "use cache";

    cacheLife("minutes");

    cacheTag("posts");

    const response =
        await fetch(
            "https://jsonplaceholder.typicode.com/posts"
        );

    return response.json();
}
```

---

Now:

```tsx
import {
    getUsers,
    getPosts,
} from "@/lib/data";

export default async function Dashboard() {

    const [
        users,
        posts,
    ] = await Promise.all([
        getUsers(),
        getPosts(),
    ]);

    return (
        <main>

            <h1>
                Dashboard
            </h1>

            <p>
                Users:
                {users.length}
            </p>

            <p>
                Posts:
                {posts.length}
            </p>

        </main>
    );
}
```

---

# The New Professional Pattern

Instead of:

```tsx
await fetch(...)
```

everywhere,

build:

```text
lib/

    users.ts
    posts.ts
    comments.ts
```

where each function defines:

* cache lifetime
* cache tags
* invalidation rules

---

# The New Mental Model

Old:

```text
Database
      |
      V

Page
```

New:

```text
Database
      |
      V

Cached Data Layer
      |
      V

React Components
```

---

# Exercises

## Exercise 1

Create:

```tsx
getUsers()
```

with:

```tsx
"use cache";
cacheLife("hours");
cacheTag("users");
```

---

## Exercise 2

Create:

```tsx
getProducts()
```

with:

```tsx
cacheLife("minutes");
cacheTag("products");
```

---

## Exercise 3

Build:

```text
Dashboard
```

that loads:

* users
* posts
* comments

from cached functions.

---

# What You've Learned

You now understand:

✅ `cacheComponents: true`

✅ `"use cache"`

✅ explicit caching

✅ `cacheLife()`

✅ `cacheTag()`

✅ cache invalidation concepts

✅ partial prerendering

✅ cached data layers

---

# The Most Important Rule of Next.js 16

Before Next.js 16:

```text
Next.js decides
what to cache
```

After Next.js 16:

```text
YOU decide
what to cache
```

This one change is arguably the biggest architectural shift in the history of Next.js.

---

# Part 10 Preview

In the next chapter we'll learn:

# Cache Invalidation

Including:

* `revalidateTag()`
* `updateTag()`
* webhook-driven cache invalidation
* CMS publishing workflows
* database mutations
* optimistic updates
* real-time content freshness

This is where Next.js 16 caching becomes truly production-ready.
