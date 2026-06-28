# Appendix A6 — Next.js 16 Data Fetching Cheat Sheet

## The Complete Guide to Fetching Data in the App Router Era

> **Purpose:** This appendix is the definitive reference for data fetching in Next.js 16. Understanding this appendix is critical because modern Next.js applications are fundamentally data pipelines disguised as UI applications.

---

# Introduction

The biggest mistake beginners make is asking:

```text id="67v8lo"
How do I fetch data?
```

Professional engineers ask:

```text id="d5n8zu"
Where should data be fetched?
```

Because in Next.js 16:

```text id="7j6j07"
Where
```

matters more than:

```text id="v7nj6h"
How.
```

---

# The Evolution of Data Fetching

## Old React

```text id="01jq3x"
Browser
    |
useEffect
    |
fetch
    |
API
    |
Render
```

---

## Next.js 16

```text id="aqv2qk"
Browser
    |
Server Component
    |
Database/API
    |
Cache
    |
HTML
```

---

# The Golden Rule

Always ask:

```text id="ekc8zq"
Can this run
on the server?
```

If yes:

```text id="6e0agk"
Use a Server Component.
```

---

# Data Fetching Locations

There are five places to fetch data:

```text id="9x98g0"
1. Server Components

2. Client Components

3. Server Actions

4. Route Handlers

5. Middleware
```

---

# 1. Server Components

## Preferred Approach

Example:

```tsx id="ngd77j"
export default async function
Page() {

  const posts =
    await getPosts();

  return (
    <div>
      {posts.length}
    </div>
  );

}
```

---

# Visualizing

```text id="m41d4p"
Request
    |
Server Component
    |
Database
    |
HTML
    |
Browser
```

---

# Advantages

```text id="dbw2vf"
✓ No API route

✓ No useEffect

✓ No loading state

✓ No extra JavaScript

✓ Fast
```

---

# Example

```tsx id="t0p0uc"
async function getUsers() {

  return db.user
    .findMany();

}

export default async function
UsersPage() {

  const users =
    await getUsers();

  return (
    <>
      {users.map(user => (
        <div key={user.id}>
          {user.name}
        </div>
      ))}
    </>
  );

}
```

---

# 2. Client Components

Use only when interaction requires it.

---

Example:

```tsx id="1nvk7j"
"use client";

export default function Search() {

  const [posts,
         setPosts] =
    useState([]);

  useEffect(() => {

    fetch("/api/posts")
      .then(r => r.json())
      .then(setPosts);

  }, []);

}
```

---

# Visualizing

```text id="gmmzjv"
Browser
    |
Download JS
    |
Run JS
    |
Fetch API
    |
Render
```

---

# Why This Is Worse

Because the user waits for:

```text id="xhzwg6"
Download

Execute

Fetch

Render
```

---

# 3. Server Actions

Use for:

```text id="r5h6r2"
Mutations.
```

---

Example:

```ts id="mbzx02"
"use server";

export async function
createPost() {

  await db.post
    .create();

}
```

---

# Visualizing

```text id="szlcba"
User
   |
Server Action
   |
Database
```

---

# 4. Route Handlers

Use for:

```text id="l6o6a4"
External APIs.
```

---

Example:

```ts id="z0m82u"
export async function
GET() {

  const posts =
    await db.post
      .findMany();

  return Response
    .json(posts);

}
```

---

# Visualizing

```text id="zv4a3h"
HTTP
   |
Route Handler
   |
Database
```

---

# 5. Middleware

Use for:

```text id="1mmlhj"
Authentication

Redirects

Localization
```

---

Avoid:

```text id="pb1q4h"
Database queries.
```

---

# The Fetch API

Next.js extends:

```ts id="j1q4vq"
fetch()
```

---

Basic example:

```ts id="arjxcr"
const response =
  await fetch(
    "https://api.com"
  );

const data =
  await response.json();
```

---

# Cached Fetching

Example:

```ts id="m2dj06"
const data =
  await fetch(url, {

    cache:
      "force-cache",

  });
```

---

# No Cache

```ts id="4m1hkl"
await fetch(url, {

  cache:
    "no-store",

});
```

---

# Revalidation

```ts id="3jz5yu"
await fetch(url, {

  next: {

    revalidate:
      3600,

  },

});
```

---

# Visualizing

```text id="34lmq7"
Fetch
   |
Cache
   |
1 hour
   |
Expire
```

---

# Next.js 16 Preferred Style

Instead of:

```ts id="js9ozz"
fetch(...,{
  next: {
    revalidate
  }
});
```

Prefer:

```ts id="gd1tzu"
"use cache";

cacheLife(
  "hours"
);
```

---

# Parallel Fetching

Bad:

```ts id="zkgd08"
const users =
  await getUsers();

const posts =
  await getPosts();

const comments =
  await getComments();
```

---

Visualizing:

```text id="ccbdq6"
Users
    |
Posts
    |
Comments
```

---

# Better

```ts id="7i7mja"
const [

  users,

  posts,

  comments,

] = await Promise.all([

  getUsers(),

  getPosts(),

  getComments(),

]);
```

---

Visualizing:

```text id="6ewx5f"
Users
     \
Posts ----> Complete
     /
Comments
```

---

# Waterfalls

Bad:

```ts id="c2zprj"
const user =
  await getUser();

const posts =
  await getPosts(
    user.id
  );
```

---

Visualizing:

```text id="tb4a4u"
User
   |
Posts
```

---

This creates:

```text id="7k9aqt"
Latency.
```

---

# Suspense

Example:

```tsx id="76shwl"
<Suspense
  fallback={
    <Loading />
  }
>
  <Posts />
</Suspense>
```

---

Visualizing:

```text id="z9cme0"
Page
   |
Header
   |
Loading
   |
Posts arrive
```

---

# Streaming

Traditional:

```text id="t1e84a"
Wait
   |
Wait
   |
Wait
   |
Render
```

---

Streaming:

```text id="lq61od"
Render
   |
Render
   |
Render
```

---

# Example

```tsx id="p0vpp0"
export default function
Page() {

  return (

    <>
      <Header />

      <Suspense
        fallback={
          <Loading />
        }
      >
        <Analytics />
      </Suspense>

    </>

  );

}
```

---

# Request Memoization

Next.js automatically deduplicates:

```ts id="jlwm1c"
await getPosts();

await getPosts();
```

---

Visualizing:

```text id="ykv04u"
Call
    |
Database
    |
Reuse
```

---

# Example

```tsx id="ybyyt5"
const a =
  await getPosts();

const b =
  await getPosts();
```

Database executes:

```text id="pdkj1q"
Once.
```

---

# React cache()

Example:

```ts id="f5jg95"
import {
  cache,
} from "react";

export const getUser =
  cache(
    async (id) => {

      return db.user
        .findUnique();

    }
  );
```

---

# Cache Components

Example:

```ts id="cw2mfw"
export async function
getPosts() {

  "use cache";

  return db.post
    .findMany();

}
```

---

# Tagged Caching

Example:

```ts id="94r7vm"
"use cache";

cacheTag(
  "posts"
);
```

---

# Lifetime

Example:

```ts id="lx4i3e"
cacheLife(
  "hours"
);
```

---

# Database Pattern

```ts id="mrf74j"
export async function
getPosts() {

  "use cache";

  cacheTag(
    "posts"
  );

  cacheLife(
    "hours"
  );

  return db.post
    .findMany();

}
```

---

# GraphQL Pattern

```ts id="4e2hrm"
export async function
queryGraphQL() {

  "use cache";

  return fetch(
    endpoint
  );

}
```

---

# REST Pattern

```ts id="d3lfvx"
export async function
getProducts() {

  "use cache";

  return fetch(
    api
  );

}
```

---

# Error Handling

Example:

```ts id="j7vh55"
try {

  const posts =
    await getPosts();

} catch {

  return [];
}
```

---

# Throwing Errors

```ts id="2xbxgr"
throw new Error(
  "Failed"
);
```

---

# Loading States

Use:

```text id="9kx0u2"
loading.tsx
```

or:

```tsx id="ob2bdn"
<Suspense>
```

---

# Empty States

Example:

```tsx id="56i2r0"
if (!posts.length) {

  return (
    <Empty />
  );

}
```

---

# Not Found

Example:

```tsx id="cvc71k"
if (!post) {

  notFound();

}
```

---

# Authentication

Example:

```tsx id="f7nsdk"
const session =
  await auth();
```

---

# Authorization

Example:

```tsx id="rz1dsp"
if (
  !session?.admin
) {

  redirect(
    "/login"
  );

}
```

---

# Data Fetching Decision Tree

Need:

```text id="t9g2lr"
Read database?
```

Use:

```text id="7mgtvx"
Server Component
```

---

Need:

```text id="7x4mh4"
Submit form?
```

Use:

```text id="kxwe8v"
Server Action
```

---

Need:

```text id="u4p2dz"
External API?
```

Use:

```text id="9h0p6q"
Route Handler
```

---

Need:

```text id="jlwmzk"
User interaction?
```

Use:

```text id="u8g4v5"
Client Component
```

---

Need:

```text id="8yxm0i"
Authentication?
```

Use:

```text id="m2tkrv"
Middleware
```

---

# The Data Fetching Pyramid

```text id="9jghsx"
Server Components
          |
Server Actions
          |
Route Handlers
          |
Client Components
```

---

# Common Beginner Mistakes

---

## Mistake 1

```tsx id="f0i7mg"
"use client";

useEffect(
  fetch
);
```

for everything.

---

## Mistake 2

Creating APIs for:

```text id="59nqsy"
Your own frontend.
```

---

## Mistake 3

Sequential fetching.

---

## Mistake 4

Ignoring caching.

---

## Mistake 5

Fetching inside event handlers when unnecessary.

---

# The Complete Next.js 16 Data Pipeline

```text id="j81d1j"
User
   |
Route
   |
Server Component
   |
"use cache"
   |
cacheTag()
   |
cacheLife()
   |
Database
   |
HTML
   |
Browser
```

---

# Mental Model

Beginners think:

```text id="jrr4n5"
Fetching data
=
Getting data.
```

Professional engineers think:

```text id="u4mwd7"
Fetching data
=
Deciding:

Where

When

How often

How stale

How expensive
```

Because modern applications are not UI systems.

They are distributed data systems that happen to render HTML.
