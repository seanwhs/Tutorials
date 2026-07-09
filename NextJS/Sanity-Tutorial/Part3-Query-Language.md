# Sanity Mastery - Part 3: GROQ — The Query Language

GROQ ("Graph-Relational Object Queries") is Sanity's native query language. You can experiment live in Studio at **`/studio/vision`** (the Vision plugin we installed in Part 1).

## Anatomy of a Basic Query

```groq
*[_type == "post"]
```

- `*` — start from every document in the dataset
- `[_type == "post"]` — filter: only keep documents where `_type` equals `"post"`

This returns **full documents** by default. In practice you almost always add a **projection** to shape the output.

## Projections — Choosing Fields

```groq
*[_type == "post"]{
  title,
  slug,
  publishedAt
}
```

```json
// Example result shape
[
  { "title": "Hello World", "slug": { "current": "hello-world" }, "publishedAt": "2025-01-01T10:00:00Z" }
]
```

Rename fields and compute derived ones with `"alias": expression`:

```groq
*[_type == "post"]{
  title,
  "slug": slug.current,          // unwrap slug.current directly, so JSON is flatter
  "authorName": author->name      // follow a reference — see below
}
```

## Filtering

```groq
// Equality
*[_type == "post" && slug.current == "hello-world"][0]

// Multiple conditions (AND)
*[_type == "post" && defined(publishedAt) && publishedAt < now()]

// OR
*[_type == "post" || _type == "author"]

// "in" operator — match any category id in the given list
*[_type == "post" && count((categories[]->_id)[@ in $categoryIds]) > 0]

// Text matching (case-insensitive substring)
*[_type == "post" && title match "next*"]
```

> `[0]` at the end of a query takes just the first result and **unwraps it from an array into a single object** — critical for "get one post by slug" queries.

## Ordering & Slicing

```groq
// Order descending by publish date
*[_type == "post"] | order(publishedAt desc)

// Pagination: skip 0, take 10 (zero-indexed, end exclusive)
*[_type == "post"] | order(publishedAt desc) [0...10]

// Next page
*[_type == "post"] | order(publishedAt desc) [10...20]
```

| Range syntax | Meaning |
|---|---|
| `[0]` | first item only, unwrapped |
| `[0...10]` | items 0–9 (10 exclusive) |
| `[0..10]` | items 0–10 (10 inclusive) |

## Following References (`->`)

This is GROQ's version of a SQL join.

```groq
*[_type == "post"]{
  title,
  "author": author->{ name, "photoUrl": photo.asset->url }
}
```

- `author->` dereferences the reference field, pulling in the target document
- You can chain `->` again (`photo.asset->url`) to resolve nested references (e.g. an image asset reference)

Array of references (e.g. `categories`):

```groq
*[_type == "post"]{
  title,
  "categories": categories[]->{ title, slug }
}
```

## Parameters — Never String-Interpolate User Input

```groq
*[_type == "post" && slug.current == $slug][0]{
  title,
  body
}
```

```ts
// Passed alongside the query, never concatenated into the string —
// this is GROQ's built-in protection against injection, same idea as SQL bind params.
client.fetch(query, { slug: "hello-world" });
```

## Counting & Aggregating

```groq
// Total number of posts
count(*[_type == "post"])

// Posts per category, computed in Studio's Vision tool for debugging
*[_type == "category"]{
  title,
  "postCount": count(*[_type == "post" && references(^._id)])
}
```

> `^` refers to the parent scope inside a nested query — here, the current `category` document being iterated in the outer query.

## `references()` — Reverse Lookups

Because `post.categories` points *to* categories, finding "all posts in category X" requires a reverse lookup:

```groq
*[_type == "post" && references($categoryId)]{
  title, slug
}
```

## Coalesce — Fallback Values

```groq
*[_type == "post"]{
  title,
  "displayImage": coalesce(coverImage, author->photo, null)
}
```

## Putting It Together — The Real Queries We'll Use in Part 4

```groq
// All published posts, newest first, list-view fields only
*[_type == "post" && defined(publishedAt) && publishedAt < now()]
  | order(publishedAt desc) {
    _id,
    title,
    "slug": slug.current,
    excerpt,
    coverImage,
    publishedAt,
    "author": author->{ name },
    "categories": categories[]->{ title, "slug": slug.current }
  }
```

```groq
// Single post by slug, full detail — used on the post detail page
*[_type == "post" && slug.current == $slug][0]{
  _id,
  title,
  body,
  coverImage,
  publishedAt,
  seo,
  "author": author->{ name, photo, shortBio },
  "categories": categories[]->{ title, "slug": slug.current }
}
```

```groq
// All slugs only — used for generateStaticParams (Part 4)
*[_type == "post" && defined(slug.current)][].slug.current
```

## GROQ vs SQL — Quick Mental Mapping

| SQL | GROQ |
|---|---|
| `SELECT * FROM posts` | `*[_type == "post"]` |
| `WHERE x = y` | `[_type == "post" && x == y]` |
| `ORDER BY x DESC` | `\| order(x desc)` |
| `LIMIT 10 OFFSET 0` | `[0...10]` |
| `JOIN authors ON ...` | `author->{ ... }` |
| `SELECT COUNT(*)` | `count(*[...])` |
| Bind parameters `?`/`$1` | `$paramName` |

## Checkpoint ✅
- [ ] You can write a filtered, ordered, projected query from scratch
- [ ] You understand `->` for following references and `references()` for reverse lookups
- [ ] You've tested all 3 "real" queries above inside `/studio/vision` against your Part 2 test data
- [ ] You always use `$params`, never string concatenation, for dynamic values

**Next: Part 4 — Data Fetching in Next.js 16**
