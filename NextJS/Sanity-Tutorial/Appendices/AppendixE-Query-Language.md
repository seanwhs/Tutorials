# Sanity Mastery - Appendix E: GROQ Cheat Sheet

# Appendix E: GROQ Cheat Sheet

Quick reference card — see Part 3 for full explanations.

## Core Syntax

```groq
*                                  // every document in the dataset
*[_type == "post"]                 // filter by type
*[_type == "post" && x == y]       // AND
*[_type == "post" || _type == "author"]  // OR
*[_type == "post"][0]              // first result, unwrapped from array
```

## Projections

```groq
*[_type == "post"]{ title, slug }              // pick fields
*[_type == "post"]{ "url": slug.current }      // rename/compute with alias
*[_type == "post"]{ ... }                      // spread all fields
*[_type == "post"]{ ..., "extra": "value" }    // spread + add computed field
```

## Ordering & Slicing

```groq
| order(publishedAt desc)          // sort descending
| order(title asc)                 // sort ascending
[0]                                 // first item, unwrapped
[0...10]                            // items 0-9 (end exclusive)
[0..10]                              // items 0-10 (end inclusive)
```

## References

```groq
author->                            // dereference a single reference
author->{ name }                    // dereference + project fields
categories[]->{ title }              // dereference an array of references
references($id)                     // reverse lookup: docs that reference $id
^                                    // parent scope, inside a nested query
```

## Filtering Operators

```groq
== != < > <= >=                     // comparison
in                                   // membership: x in [a, b, c]
match                                // glob-style text match: title match "next*"
defined(field)                       // field is not null/missing
!defined(field)                      // field is null/missing
count(array)                          // length of an array or query result
```

## Functions

```groq
now()                                // current datetime, ISO string
coalesce(a, b, c)                    // first non-null value
count(*[_type == "post"])            // count matching documents
length(someArray)                    // array/string length
lower(str) / upper(str)              // case conversion
```

## Parameters (always use these, never string-concat)

```groq
*[_type == "post" && slug.current == $slug][0]
```
```ts
client.fetch(query, { slug: "hello-world" });
```

## Common Full Query Patterns (from this series)

```groq
// List, published only, newest first
*[_type == "post" && defined(publishedAt) && publishedAt < now()]
  | order(publishedAt desc) { _id, title, "slug": slug.current }

// Single by slug
*[_type == "post" && slug.current == $slug][0]{ title, body }

// All slugs (for generateStaticParams)
*[_type == "post" && defined(slug.current)][].slug.current

// Reverse lookup (posts in a category)
*[_type == "post" && references($categoryId)]{ title }

// Paginated
*[_type == "post"] | order(publishedAt desc) [$start...$end]{ title }

// Text search
*[_type == "post" && title match $term + "*"]{ title }

// Count
count(*[_type == "post"])
```

## GROQ vs SQL Quick Map

| SQL | GROQ |
|---|---|
| `SELECT * FROM posts` | `*[_type == "post"]` |
| `WHERE x = y` | `[_type == "post" && x == y]` |
| `ORDER BY x DESC` | `\| order(x desc)` |
| `LIMIT 10 OFFSET 0` | `[0...10]` |
| `JOIN` | `field->{ ... }` |
| `COUNT(*)` | `count(*[...])` |
| `?` / `$1` bind params | `$paramName` |

---

**This concludes the Sanity Mastery series.** 🎉
