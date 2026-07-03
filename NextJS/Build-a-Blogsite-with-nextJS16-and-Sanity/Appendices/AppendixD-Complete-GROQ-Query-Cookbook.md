# Appendix D — The Complete GROQ Query Cookbook for GreyMatter Journal

> **Goal of this appendix:** Master the Graph-Relational Object Queries (GROQ) language used by Sanity while learning the broader concepts of querying, filtering, projection, joins, aggregation, and information retrieval systems.

---

# Introduction

When developers first encounter GROQ, they often ask:

> "Why doesn't Sanity use SQL?"

Or:

> "Why doesn't Sanity just use GraphQL?"

The answer is that GROQ was designed specifically for:

```text id="yzn78u"
Structured Content Retrieval
```

rather than:

```text id="jlwmop"
Relational Databases
```

or:

```text id="z0l3uj"
Generic APIs
```

---

# What Is GROQ?

GROQ stands for:

```text id="r41vv7"
Graph
Relational
Object
Queries
```

Think of GROQ as:

```text id="bz97gd"
SQL
     +
JSON
     +
Graph Traversal
```

---

# SQL Versus GROQ

SQL:

```sql id="w4n4oz"
SELECT *
FROM posts
WHERE featured = true;
```

GROQ:

```groq id="ztjlwm"
*[
  _type == "post" &&
  featured == true
]
```

---

# Mental Model

Imagine your content database:

```text id="k79jj9"
Posts

Authors

Categories

Comments
```

GROQ allows us to ask:

```text id="iwqqhc"
Find

Filter

Project

Join

Transform
```

information.

---

# The Universal GROQ Pattern

Almost every query follows:

```groq id="l8ih8f"
*[
  FILTER
]{
  PROJECTION
}
```

Diagram:

```text id="wjx4kx"
Database
    │
    ▼

Filter
    │
    ▼

Select Fields
    │
    ▼

Return Data
```

---

# Query 1 — Fetch All Posts

```groq id="w5gnzq"
*[
  _type == "post"
]
```

Result:

```json id="oc93ph"
[
  {...},
  {...},
  {...}
]
```

---

# Query 2 — Fetch One Post

```groq id="p3l87v"
*[
  _type == "post"
][0]
```

The:

```text id="lpm55v"
[0]
```

means:

```text id="2uvgbw"
Return first result.
```

---

# Query 3 — Filter By Slug

```groq id="89oy0g"
*[
  _type == "post" &&
  slug.current == $slug
][0]
```

Example:

```typescript id="mkljrf"
client.fetch(
  QUERY,
  {
    slug:
      "nextjs-guide",
  }
);
```

---

# Parameters

Bad:

```groq id="4xw17l"
slug.current ==
"nextjs-guide"
```

Good:

```groq id="w4u7e0"
slug.current ==
$slug
```

Why?

Because parameters provide:

```text id="8mpn5x"
Security

Reusability

Performance
```

---

# Query 4 — Sort Posts

Newest first:

```groq id="arxlt7"
*[
  _type == "post"
]
| order(
    publishedAt desc
  )
```

Oldest first:

```groq id="g69g0n"
*[
  _type == "post"
]
| order(
    publishedAt asc
  )
```

---

# Query 5 — Limit Results

Recent articles:

```groq id="o8n9ta"
*[
  _type == "post"
]
| order(
    publishedAt desc
  )[0...5]
```

Result:

```text id="rqarfz"
First 5 posts
```

---

# Query 6 — Select Specific Fields

Instead of:

```groq id="07w9r0"
*[
  _type == "post"
]
```

Use:

```groq id="h26j2n"
*[
  _type == "post"
]{
  title,
  slug,
  excerpt
}
```

---

# Why Projection Matters

Suppose your article contains:

```text id="eukvrr"
100KB body
20 images
metadata
comments
```

Fetching everything wastes bandwidth.

Projection retrieves:

```text id="3rhtiv"
Only what you need.
```

---

# Query 7 — Rename Fields

```groq id="wksn3e"
*[
  _type == "post"
]{
  "id": _id,

  "url":
    slug.current,

  title
}
```

Result:

```json id="gfnsqj"
{
  "id":"123",
  "url":"react",
  "title":"React"
}
```

---

# Query 8 — Fetch Author Reference

Post:

```text id="2jz77i"
Post
   │
   ▼
Author
```

Query:

```groq id="cv4c25"
*[
  _type == "post"
]{
  title,

  author->{
    name,
    bio
  }
}
```

---

# What Does -> Mean?

The arrow operator means:

```text id="sftt4k"
Follow Reference
```

Diagram:

```text id="tyovj8"
Post
   │
   ▼

author

   │
   ▼

Author Document
```

---

# Query 9 — Multiple References

```groq id="g8k7gq"
*[
  _type == "post"
]{
  title,

  categories[]->{
    title
  }
}
```

Result:

```json id="v6mpqf"
{
  "categories": [
    {
      "title":
        "React"
    },
    {
      "title":
        "Next.js"
    }
  ]
}
```

---

# Query 10 — Featured Posts

```groq id="ovk81z"
*[
  _type == "post" &&
  featured == true
]
```

---

# Query 11 — Search

```groq id="m5qjtr"
*[
  _type == "post" &&
  title match
    $search
]
```

Example:

```text id="s7q57i"
"react*"
```

---

# Query 12 — Search Multiple Fields

```groq id="0wthwy"
*[
  _type == "post" &&
  (
    title match $term ||
    excerpt match $term
  )
]
```

---

# Query 13 — Count Documents

Count posts:

```groq id="5h8dn5"
count(
  *[
    _type=="post"
  ]
)
```

Result:

```text id="v2f0br"
42
```

---

# Query 14 — Count Comments

```groq id="pv8scm"
count(
  *[
    _type=="comment" &&
    approved == true
  ]
)
```

---

# Query 15 — Related Posts

```groq id="a2kpfu"
*[
  _type=="post" &&
  category._ref
    in
  ^.category._ref &&
  _id != ^._id
]
```

---

# Wait...

What Is ^ ?

The:

```text id="f8drf6"
^
```

means:

```text id="o9z8t5"
Current Parent Context
```

Diagram:

```text id="w0o68s"
Current Post
      │
      ▼

Reference Parent
```

---

# Query 16 — Recent Posts

```groq id="9mbjbe"
*[
  _type=="post"
]
| order(
    publishedAt desc
  )[0...10]
```

---

# Query 17 — Draft Posts

```groq id="sq6yca"
*[
  _id in
  path("drafts.**")
]
```

---

# Query 18 — Published Posts

```groq id="z55nvo"
*[
  _type=="post" &&
  !(_id in
    path(
      "drafts.**"
    ))
]
```

---

# Query 19 — Comments For Post

```groq id="r1wdrg"
*[
  _type=="comment" &&
  approved == true &&
  post._ref == $id
]
```

---

# Query 20 — Count Comments Per Post

```groq id="gbpjlwm"
*[
  _type=="post"
]{
  title,

  "comments":
    count(
      *[
        _type=="comment" &&
        post._ref == ^._id
      ]
    )
}
```

---

# Query 21 — Latest Post

```groq id="f9ef4a"
*[
  _type=="post"
]
| order(
    publishedAt desc
  )[0]
```

---

# Query 22 — Generate Sitemap

```groq id="wwu8w2"
*[
  _type=="post"
]{
  "slug":
    slug.current,

  publishedAt
}
```

---

# Query 23 — RSS Feed

```groq id="lt7nqo"
*[
  _type=="post"
]
| order(
    publishedAt desc
  ){
    title,
    excerpt,
    publishedAt,
    slug
}
```

---

# Query 24 — Metadata Query

```groq id="f19o0z"
*[
  _type=="post" &&
  slug.current==$slug
][0]{
  title,

  seoTitle,

  seoDescription,

  heroImage
}
```

---

# Query 25 — Homepage Query

```groq id="kxvkmu"
*[
  _type=="post"
]
| order(
    publishedAt desc
  )[0...10]{

  title,

  excerpt,

  publishedAt,

  featured,

  slug,

  heroImage,

  author->{
    name,
    image
  },

  categories[]->{
    title
  }
}
```

---

# Query 26 — Full Article Query

```groq id="9r9mcc"
*[
  _type=="post" &&
  slug.current==$slug
][0]{

  _id,

  title,

  excerpt,

  body,

  heroImage,

  publishedAt,

  seoTitle,

  seoDescription,

  author->{
    name,
    bio,
    image
  },

  categories[]->{
    title,
    slug
  }
}
```

---

# Conditional Projection

GROQ supports:

```groq id="vcc8v8"
*[
  _type=="post"
]{
  title,

  featured =>
  {
    "badge":
      "Featured"
  }
}
```

---

# Computed Fields

```groq id="vzv8ig"
*[
  _type=="post"
]{
  title,

  "url":
    "/posts/" +
    slug.current
}
```

---

# Nested Queries

```groq id="w15mjh"
{
  "posts":
    *[
      _type=="post"
    ],

  "authors":
    *[
      _type=="author"
    ]
}
```

---

# Why GROQ Feels Strange

SQL thinks:

```text id="xtbyxw"
Tables
```

GraphQL thinks:

```text id="q5qjhb"
APIs
```

GROQ thinks:

```text id="lkrvyc"
Documents
```

and asks:

> "What information shape do you want returned?"

---

# The Hidden Architecture

When you execute:

```typescript id="2j4v5p"
await client.fetch(
  QUERY
);
```

the system becomes:

```text id="bq2y0u"
Next.js
    │
    ▼

Sanity Client
    │
    ▼

GROQ Parser
    │
    ▼

Content Lake
    │
    ▼

Reference Resolver
    │
    ▼

Projection Engine
    │
    ▼

JSON Result
```

---

# The Deep Secret Of Query Languages

Most beginners think:

```text id="j4fdcc"
Queries
      =
Getting Data
```

Professional engineers think:

```text id="9qtv75"
Queries
      =
Asking Questions
      About Reality
```

SQL, GraphQL, GROQ, search engines, AI retrieval systems, and even human language all solve the same fundamental problem:

```text id="mjlwm2"
How do we extract
meaningful information
from large collections
of knowledge?
```

---

# Mental Model To Remember Forever

Beginners think:

```text id="bcrk6l"
Database
       =
Storage
```

Professional engineers think:

```text id="lyoluv"
Database
       =
A system
       for answering
       questions
```

GROQ is not merely a query language.

It is a language for describing:

```text id="u0g4x8"
What information exists,

how information relates,

and what meaning
we wish to extract.
```
