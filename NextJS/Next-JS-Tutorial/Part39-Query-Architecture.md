# Next.js 16 for Absolute Beginners

# Part 39 — Search, Filtering, Pagination, and Query Architecture

> **Goal of this lesson:** Build a production-grade search and discovery system for Nexus CMS using Next.js 16, Server Components, URL search parameters, filtering, sorting, full-text search, pagination, and query optimization.

---

# Beginners Think Search Is Easy

Most beginners think search works like this:

```text
User
   |
Search Box
   |
Database
   |
Results
```

Unfortunately, real systems look like this:

```text
User
   |
Query
   |
Validation
   |
Parsing
   |
Filtering
   |
Sorting
   |
Pagination
   |
Caching
   |
Search Index
   |
Results
```

Because search is one of the hardest problems in software engineering.

---

# What We're Building

By the end of this chapter, we'll have:

```text
✓ Search
✓ Filters
✓ Sorting
✓ Pagination
✓ Cursor pagination
✓ URL state
✓ Search indexing
✓ Query optimization
✓ Faceted search
✓ Cache integration
```

---

# The First Mistake Beginners Make

They build:

```text
/posts/search
```

using:

```tsx
useState()
```

and:

```tsx
useEffect()
```

This creates:

```text
❌ Unshareable URLs
❌ Broken back button
❌ No SSR
❌ Poor SEO
❌ Duplicate state
```

---

# Modern Search Architecture

Instead:

```text
/posts

?search=nextjs
&category=react
&sort=newest
&page=2
```

Everything becomes URL state.

---

# Visualizing Search State

```text
URL
   |
Application State
   |
Database Query
   |
Results
```

---

# Step 1 — Create Search Page

Create:

```text
app/posts/page.tsx
```

---

```tsx
export default async function
PostsPage({

  searchParams,

}) {

  console.log(
    searchParams
  );

}
```

---

# Example URL

```text
/posts

?search=next

&page=2
```

Produces:

```js
{
  search: "next",
  page: "2"
}
```

---

# Why Is This Powerful?

Because URLs become:

```text
✓ Bookmarkable
✓ Shareable
✓ Crawlable
✓ Cacheable
```

---

# Step 2 — Create Search Form

```tsx
<form>

  <input

    name="search"

    placeholder="Search"

  />

</form>
```

---

# Submit Search

```tsx
<form
  action="/posts"
>

  <input
    name="search"
  />

</form>
```

---

# Visualizing

```text
Form
   |
URL
   |
Server
   |
Database
```

---

# Step 3 — Add Database Search

Example:

```ts
const posts =

  await db.post
    .findMany({

      where: {

        title: {

          contains:
            search,

          mode:
            "insensitive",

        },

      },

    });
```

---

# Example

Search:

```text
next
```

matches:

```text
Next.js

NEXTJS

nextjs tutorial
```

---

# Step 4 — Search Multiple Fields

```ts
where: {

  OR: [

    {

      title: {

        contains:
          search,

      },

    },

    {

      excerpt: {

        contains:
          search,

      },

    },

  ],

}
```

---

# Visualizing Search

```text
Query
   |
Title
   |
Excerpt
   |
Body
```

---

# Step 5 — Add Category Filter

URL:

```text
/posts

?category=react
```

---

Database:

```ts
where: {

  category: {

    slug:
      category,

  },

}
```

---

# Add Author Filter

```text
/posts

?author=sean
```

---

```ts
where: {

  author: {

    slug:
      author,

  },

}
```

---

# Step 6 — Dynamic Query Builder

Create:

```text
lib/search.ts
```

---

```ts
export function
buildQuery({

  search,

  category,

}) {

  const where =
    {};

  if (search) {

    where.title = {

      contains:
        search,

    };

  }

  if (category) {

    where.category = {

      slug:
        category,

    };

  }

  return where;

}
```

---

# Why?

Because search conditions are optional.

---

# Visualizing

```text
Request
    |
Query Builder
    |
Database
```

---

# Step 7 — Add Sorting

URL:

```text
?sort=newest
```

---

Database:

```ts
orderBy: {

  createdAt:
    "desc",

}
```

---

Other options:

```text
newest

oldest

title

popular
```

---

# Example

```ts
switch(sort) {

  case "newest":

    return {

      createdAt:
        "desc",

    };

}
```

---

# Visualizing Sorting

```text
Search
    |
Filter
    |
Sort
    |
Results
```

---

# Step 8 — Add Pagination

Beginners often do:

```ts
findMany();
```

Bad.

---

Instead:

```ts
take: 10
```

---

Example:

```ts
const page = 2;

const limit = 10;

const posts =

  await db.post
    .findMany({

      skip:

        (page - 1)
        * limit,

      take:
        limit,

    });
```

---

# Visualizing Pagination

```text
Page 1

1-10
```

```text
Page 2

11-20
```

```text
Page 3

21-30
```

---

# Step 9 — Calculate Total Pages

```ts
const total =

  await db.post
    .count();
```

---

```ts
const pages =

  Math.ceil(

    total / limit

  );
```

---

# Render

```tsx
{Array.from({

  length:
    pages,

}).map(

  (_, page) => (

    <a>

      {page+1}

    </a>

  )

)}
```

---

# Problem With Offset Pagination

Suppose:

```text
1 million rows
```

Query:

```sql
OFFSET 900000
```

Database:

```text
Reads
900000 rows
```

Very slow.

---

# Step 10 — Cursor Pagination

Instead:

```text
after=id123
```

---

Example:

```ts
await db.post
  .findMany({

    cursor: {

      id:
        cursor,

    },

    take:
      10,

  });
```

---

# Visualizing Cursor Pagination

```text
Page

1
2
3
4
```

becomes:

```text
A
↓
B
↓
C
↓
D
```

---

# Why Cursor Pagination?

Benefits:

```text
✓ Fast
✓ Stable
✓ Infinite scroll
✓ Large datasets
```

---

# Step 11 — Full Text Search

Simple:

```text
contains()
```

works for:

```text
1000 rows
```

---

Not for:

```text
10 million rows
```

---

# Real Search Architecture

```text
Database
      |
Search Index
      |
Search Engine
```

---

Examples:

```text
PostgreSQL FTS

Meilisearch

OpenSearch

Elasticsearch

Algolia
```

---

# Visualizing Search Engine

```text
Content
    |
Index
    |
Search
```

---

# PostgreSQL Full Text Search

Example:

```sql
SELECT *

FROM posts

WHERE

to_tsvector(
    title
)

@@

to_tsquery(
    'next'
);
```

---

# What Does This Do?

Instead of:

```text
Searching text
```

it searches:

```text
Search indexes
```

---

# Step 12 — Add Facets

Suppose:

```text
Category

React (34)

Next.js (15)

Node (8)
```

---

Query:

```ts
await db.post
  .groupBy({

    by:
      ["categoryId"],

    _count:
      true,

  });
```

---

# Visualizing Facets

```text
Search

    React (34)

    Next (15)

    Vue (7)
```

---

# Step 13 — Cache Search Results

Example:

```ts
"use cache";

cacheTag(
  "search"
);

cacheLife(
  "minutes"
);
```

---

# Why?

Because popular searches repeat.

---

# Visualizing Search Cache

```text
Search
    |
Cache
    |
Database
```

---

# Step 14 — Debouncing

Bad:

```text
N
Ne
Nex
Next
```

Four requests.

---

Better:

```text
Wait 300ms
```

Then:

```text
Next
```

One request.

---

# Visualizing

```text
Type
Type
Type
Pause
|
Search
```

---

# Step 15 — Search Architecture

```text
Browser
    |
URL Params
    |
Server Component
    |
Query Builder
    |
Cache
    |
Database
    |
Results
```

---

# Production Search Architecture

```text
User
   |
Search
   |
Cache
   |
Search Engine
   |
Database
   |
Results
```

---

# Search Performance Rules

Never:

```text
SELECT *
```

on:

```text
1 million rows
```

---

Never:

```text
OFFSET
900000
```

---

Never:

```text
Search
without indexes
```

---

Always:

```text
✓ Index
✓ Paginate
✓ Filter
✓ Cache
✓ Limit
```

---

# What We've Built

```text
✓ Search

✓ Filters

✓ Sorting

✓ Pagination

✓ Cursor pagination

✓ URL state

✓ Full text search

✓ Facets

✓ Search cache

✓ Query optimization
```

---

# Search Philosophy

Beginners think:

```text
Search
   =
Textbox
```

Professional engineers think:

```text
Search
   =
Information retrieval
```

Because search is not about finding text.

It's about helping humans find knowledge.

---

# Exercises

## Exercise 1

Add:

```text
Tag filtering.
```

---

## Exercise 2

Implement:

```text
Cursor pagination.
```

---

## Exercise 3

Add:

```text
Popular searches.
```

---

## Exercise 4

Add:

```text
Related posts.
```

using search similarity.

---

# Mental Model

Beginners build:

```text
Search bars.
```

Professional engineers build:

```text
Discovery systems.
```

Because users rarely know exactly what they're looking for.

---

# Part 40 Preview

In the next chapter we'll build:

# Background Jobs, Queues, Cron Jobs, and Asynchronous Architectures

Including:

```text
✓ Job queues
✓ Background workers
✓ Scheduled jobs
✓ Email queues
✓ Image processing
✓ Retry policies
✓ Dead letter queues
✓ Distributed workers
✓ Event-driven architecture
✓ Reliability engineering
```

This is where Next.js becomes a distributed systems platform.
