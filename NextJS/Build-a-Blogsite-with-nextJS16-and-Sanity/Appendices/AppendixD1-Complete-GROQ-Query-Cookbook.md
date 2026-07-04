# **✅ Appendix D1 — The Complete GROQ Query Cookbook for GreyMatter Journal**

---

# Appendix D1 — The Complete GROQ Query Cookbook

> **Goal of this appendix:** Master GROQ while learning the broader principles of querying, filtering, projection, joins, and information retrieval systems.

---

### What is GROQ?

**GROQ** (Graph-Relational Object Queries) is Sanity’s query language. It combines:

- The filtering power of SQL
- The flexibility of JSON
- The graph traversal of graph databases

---

### Core Mental Model

```text
All Documents
     ↓
Filter (WHERE)
     ↓
Project (SELECT fields)
     ↓
Sort / Limit
     ↓
Transform / Join
```

---

### Basic Queries

**Get all posts (newest first):**

```groq
*[_type == "post"] | order(publishedAt desc)
```

**Get one post by slug:**

```groq
*[_type == "post" && slug.current == $slug][0]
```

**Limit results:**

```groq
*[_type == "post"] | order(publishedAt desc)[0...10]
```

---

### Projection (Selecting Fields)

```groq
*[_type == "post"]{
  title,
  slug,
  excerpt,
  publishedAt,
  "authorName": author->name,
  "categoryTitles": categories[]->title
}
```

---

### Advanced Joins & Relationships

**Fetch author details:**

```groq
*[_type == "post"]{
  title,
  author->{
    name,
    bio,
    image
  }
}
```

**Fetch related posts by category:**

```groq
*[_type == "post" && _id != $currentId && categories[]._ref in $categoryIds]
```

---

### Search

```groq
*[_type == "post" && (title match $term || excerpt match $term)]
```

---

### Pro Tips

- Use parameters (`$slug`, `$term`) for security and performance
- Exclude drafts: `!(_id in path("drafts.**"))`
- Computed fields: `"url": "/posts/" + slug.current`

---

### Mental Model To Remember Forever

**Queries are not about "getting data."**

They are about **asking meaningful questions** about your structured knowledge.

GROQ lets you describe the shape of the information you want — and the system figures out how to deliver it efficiently.
