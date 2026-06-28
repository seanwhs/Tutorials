# Appendix A4 — Next.js 16 Cache Components Cheat Sheet

## The Complete Guide to `"use cache"`, `cacheTag()`, `cacheLife()`, `revalidateTag()`, and `updateTag()`

> **Purpose:** This appendix is the definitive reference for the new caching model introduced in Next.js 16. Keep this appendix nearby whenever you're building data-driven applications.

---

# Introduction

The biggest change in Next.js 16 is not:

```text
React version

TypeScript support

Server Actions
```

The biggest change is:

```text
Caching becomes explicit.
```

---

# Before Next.js 16

Developers asked:

```text
Why is this cached?
```

Or:

```text
Why isn't this cached?
```

---

# After Next.js 16

Developers explicitly declare:

```text
What

Why

How long

When to invalidate
```

---

# The New Mental Model

Old model:

```text
Request
    |
Magic
    |
Cache
```

---

New model:

```text
Request
    |
"use cache"
    |
cacheTag()
    |
cacheLife()
    |
Cache
```

---

# Enabling Cache Components

In:

```text
next.config.ts
```

enable:

```ts
import type { NextConfig }
  from "next";

const config: NextConfig = {

  cacheComponents: true,

};

export default config;
```

---

# Visualizing

```text
cacheComponents=true
           |
           V
Explicit caching model
```

---

# The Cache Pyramid

```text
Browser Cache
        |
CDN Cache
        |
Next.js Cache
        |
Database
```

---

# Cache Components primarily control:

```text
Next.js Cache
```

---

# The Five Core APIs

```text
"use cache"

cacheTag()

cacheLife()

revalidateTag()

updateTag()
```

---

# Part 1 — `"use cache"`

## Purpose

Declare:

```text
This function
may be cached.
```

---

# Example

```ts
async function getPosts() {

  "use cache";

  return db.post
    .findMany();

}
```

---

# Visualizing

```text
Call
 |
Cache?
 |
Yes
 |
Return

No
 |
Execute
 |
Store
 |
Return
```

---

# Why?

Without:

```ts
async function
getPosts() {}
```

every call executes:

```text
Database
```

---

With:

```ts
"use cache";
```

calls become:

```text
Database
    |
Cache
    |
Cache
    |
Cache
```

---

# Example

```ts
export async function
getUsers() {

  "use cache";

  return db.user
    .findMany();

}
```

---

# What Gets Cached?

Everything returned:

```text
JSON

Objects

Arrays

Results
```

provided it can be serialized.

---

# Cache Scope

Cache applies to:

```text
Function
inputs
```

---

Example:

```ts
async function getPost(
  id: string
) {

  "use cache";

}
```

---

Cache keys:

```text
getPost(1)

getPost(2)

getPost(3)
```

become:

```text
Three cache entries.
```

---

# Part 2 — cacheTag()

## Purpose

Attach:

```text
Meaning.
```

to cache entries.

---

# Example

```ts
import {
  cacheTag,
} from "next/cache";

export async function
getPosts() {

  "use cache";

  cacheTag("posts");

  return db.post
    .findMany();

}
```

---

# Visualizing

```text
Cache Entry
      |
      +---- posts
```

---

# Multiple Tags

```ts
cacheTag("posts");

cacheTag("featured");

cacheTag("homepage");
```

---

Result:

```text
Cache Entry

     |
     +--- posts

     +--- featured

     +--- homepage
```

---

# Why Tags Matter

Without tags:

```text
Invalidate everything.
```

---

With tags:

```text
Invalidate only
what changed.
```

---

# Example

```text
Blog post edited
```

Invalidate:

```text
posts
```

Not:

```text
users

analytics

dashboard
```

---

# Good Tag Names

Examples:

```text
posts

users

products

dashboard

categories
```

---

# Better Tags

Examples:

```text
post:123

user:45

product:999
```

---

# Visualizing

```text
post:1

post:2

post:3
```

---

# Part 3 — cacheLife()

## Purpose

Control:

```text
How long
cache survives.
```

---

# Example

```ts
import {
  cacheLife,
} from "next/cache";

async function
getProducts() {

  "use cache";

  cacheLife("hours");

  return products();

}
```

---

# Visualizing

```text
Request
    |
Cache
    |
1 hour
    |
Expire
```

---

# Presets

Common presets:

```text
seconds

minutes

hours

days

weeks
```

---

# Example

```ts
cacheLife("minutes");
```

---

# Example

```ts
cacheLife("hours");
```

---

# Example

```ts
cacheLife("days");
```

---

# Choosing Lifetime

Frequently changing:

```text
minutes
```

---

Moderately changing:

```text
hours
```

---

Rarely changing:

```text
days
weeks
```

---

# Examples

News:

```text
minutes
```

---

Products:

```text
hours
```

---

Documentation:

```text
days
```

---

# Why?

Because:

```text
Freshness

vs

Performance
```

is always a tradeoff.

---

# Part 4 — revalidateTag()

## Purpose

Mark cache entries:

```text
Stale.
```

---

# Example

```ts
import {
  revalidateTag,
} from "next/cache";

revalidateTag(
  "posts"
);
```

---

# Visualizing

Before:

```text
posts
    |
cache
```

---

After:

```text
posts
    |
stale
```

---

# Next Request

```text
Request
    |
Miss
    |
Recompute
    |
Store
```

---

# Typical Workflow

```text
Editor
   |
Update post
   |
Webhook
   |
revalidateTag()
```

---

# Example API Route

```ts
import {
  revalidateTag,
} from "next/cache";

export async function
POST() {

  revalidateTag(
    "posts"
  );

  return Response.json({
    success: true,
  });

}
```

---

# Visualizing

```text
CMS
  |
Webhook
  |
API
  |
revalidateTag()
  |
Cache
```

---

# Why Not Delete Immediately?

Because:

```text
Users
should not
experience
cache misses
simultaneously.
```

---

# Part 5 — updateTag()

## Purpose

Immediately refresh cache after mutations.

---

# Example

```ts
import {
  updateTag,
} from "next/cache";

export async function
createPost() {

  await db.post.create();

  updateTag(
    "posts"
  );

}
```

---

# Visualizing

```text
Mutation
     |
updateTag()
     |
Refresh now
```

---

# Difference Between updateTag and revalidateTag

---

## revalidateTag

```text
Mark stale.
```

---

Visualizing:

```text
Request
    |
Old cache
    |
Invalidate
    |
Future request refreshes
```

---

## updateTag

```text
Refresh immediately.
```

---

Visualizing:

```text
Mutation
    |
Refresh
    |
New cache
```

---

# Comparison Table

| Feature           | revalidateTag | updateTag  |
| ----------------- | ------------- | ---------- |
| Marks stale       | ✓             | ✗          |
| Immediate refresh | ✗             | ✓          |
| User mutations    | Sometimes     | Yes        |
| Webhooks          | Yes           | Usually no |
| CMS updates       | Yes           | No         |
| Forms             | Possible      | Yes        |

---

# Practical Example

User creates:

```text
New Post
```

---

Bad:

```ts
revalidateTag(
  "posts"
);
```

Because user still sees:

```text
Old data.
```

---

Good:

```ts
updateTag(
  "posts"
);
```

---

# Full Example

```ts
import {
  cacheTag,
  cacheLife,
} from "next/cache";

export async function
getPosts() {

  "use cache";

  cacheTag("posts");

  cacheLife("hours");

  return db.post
    .findMany();

}
```

---

# Mutation

```ts
"use server";

import {
  updateTag,
} from "next/cache";

export async function
createPost() {

  await db.post.create();

  updateTag(
    "posts"
  );

}
```

---

# CMS Webhook

```ts
import {
  revalidateTag,
} from "next/cache";

export async function
POST() {

  revalidateTag(
    "posts"
  );

}
```

---

# The Cache Lifecycle

```text
Request
    |
Miss
    |
Execute
    |
Store
    |
Hit
    |
Hit
    |
Hit
    |
Invalidate
    |
Miss
```

---

# Cache Hierarchy

Example:

```text
posts

post:1

post:2

post:3
```

---

Example invalidation:

```ts
revalidateTag(
  "post:1"
);
```

---

Result:

```text
Only post 1
refreshes.
```

---

# Cache Design Pattern

Example:

```text
products

product:1

product:2

product:3

categories

category:5
```

---

# Blog Pattern

```text
posts

post:slug

authors

author:id

homepage
```

---

# Ecommerce Pattern

```text
products

product:id

inventory

cart:user

orders:user
```

---

# Dashboard Pattern

```text
dashboard

analytics

metrics

reports
```

---

# Common Mistakes

---

## Mistake 1

```ts
"use cache";
```

without:

```text
cacheTag()
```

---

## Mistake 2

Using:

```text
One giant tag.
```

Example:

```ts
cacheTag("app");
```

---

## Mistake 3

Using:

```text
Thousands of
unrelated tags.
```

---

## Mistake 4

Using:

```ts
updateTag()
```

inside CMS webhooks.

---

## Mistake 5

Using:

```ts
revalidateTag()
```

for user mutations.

---

# Decision Tree

Did a user change data?

Use:

```text
updateTag()
```

---

Did a CMS publish content?

Use:

```text
revalidateTag()
```

---

Need reusable caching?

Use:

```text
"use cache"
```

---

Need selective invalidation?

Use:

```text
cacheTag()
```

---

Need expiration?

Use:

```text
cacheLife()
```

---

# The Complete Mental Model

Old Next.js:

```text
Cache
   |
Magic
```

---

Next.js 16:

```text
"use cache"
      |
cacheTag()
      |
cacheLife()
      |
revalidateTag()
      |
updateTag()
```

---

# Final Architecture

```text
Database
    |
"use cache"
    |
cacheTag()
    |
cacheLife()
    |
Cache
    |
User
```

---

# Mental Model

Beginners think:

```text
Caching
=
Performance.
```

Professional engineers think:

```text
Caching
=
A consistency model
with performance
side effects.
```

Because cache design is not fundamentally about speed.

It's about deciding:

```text
How stale
you are willing
to allow
your system
to become.
```
