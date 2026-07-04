# **✅ Part 17 — TypeScript, Data Contracts, and Reliable Software Systems**

# GreyMatter Journal

## Part 17 — TypeScript, Data Contracts, and Building Reliable Software Systems

> **Goal of this lesson:** Replace `any` with explicit contracts, understand why type systems exist, and discover how modern software systems scale through shared agreements rather than assumptions.

---

# The Problem With `any`

So far, we've occasionally written code like this:

```tsx
posts.map((post: any) => ...)
```

or:

```tsx
function PostCard({
  post,
}: {
  post: any;
})
```

This works.

Unfortunately:

```text
Works
    ≠
Reliable
```

When we use:

```typescript
any
```

we are telling TypeScript:

> Stop helping me.

Consider:

```typescript
post.title
```

What if:

```typescript
title
```

doesn't exist?

Or:

```typescript
author
```

is missing?

Or:

```typescript
slug
```

has the wrong shape?

With `any`, TypeScript cannot help us.

---

# Software Engineering Is Really About Managing Assumptions

Suppose we write:

```typescript
post.title
```

Hidden inside that line are several assumptions:

```text
post exists

post has a title

title is a string

title is not null
```

Large systems fail because assumptions become incorrect.

Type systems exist to make assumptions explicit.

---

# Types Are Contracts

Beginners often think:

```text
Types
    =
Extra Syntax
```

Professional engineers think:

```text
Types
    =
Contracts
```

A contract says:

> This data must have this shape.

For example:

```typescript
type User = {
  name: string;
  age: number;
};
```

This creates an agreement:

```text
User
 ├── name
 └── age
```

If someone writes:

```typescript
const user = {
  name: "Sean",
};
```

TypeScript responds:

```text
Contract violated.
```

---

# Our Domain Model

GreyMatter Journal contains several concepts:

```text
Author

Category

Post

Search Result

Post Summary

Post Detail
```

These concepts become contracts.

Create:

```text
types/content.ts
```

---

# Primitive Contracts

```typescript
export type Slug = {
  current: string;
};

export type Category = {
  title: string;

  slug?: Slug;
};

export type Author = {
  name: string;

  slug?: Slug;

  image?: unknown;
};
```

Notice:

```typescript
unknown
```

instead of:

```typescript
any
```

Why?

Because:

```text
unknown
        =
"I don't know yet."

any
        =
"I don't care."
```

These are very different.

---

# Post Summary

Our homepage does not need the entire article.

It only needs:

```text
Title

Excerpt

Author

Categories
```

Therefore:

```typescript
export type PostSummary = {
  _id: string;

  title: string;

  slug: Slug;

  excerpt: string;

  publishedAt: string;

  author: Author;

  categories: Category[];

  mainImage?: unknown;
};
```

---

# Full Post

Article pages require more information.

```typescript
export type Post = {
  _id: string;

  title: string;

  slug: Slug;

  excerpt: string;

  body?: unknown[];

  publishedAt: string;

  author: Author;

  categories: Category[];

  mainImage?: unknown;
};
```

Notice something important:

```text
One Entity
       ≠
One Type
```

Instead:

```text
Different Views
          ↓
Different Contracts
```

---

# Search Results Are Also Contracts

Search pages need even less information:

```typescript
export type SearchResult = {
  _id: string;

  title: string;

  slug: Slug;

  excerpt: string;

  author: Author;
};
```

This reflects a larger principle:

```text
UI Requirements
         ↓
Data Requirements
         ↓
Type Contracts
```

---

# Updating Our Components

Instead of:

```tsx
function PostCard({
  post,
}: {
  post: any;
})
```

we write:

```tsx
import type {
  PostSummary,
} from "@/types/content";

type Props = {
  post: PostSummary;
};

export default function PostCard({
  post,
}: Props) {
  ...
}
```

Now TypeScript guarantees:

```text
title exists

slug exists

author exists

categories exist
```

before our code runs.

---

# Generics

One of the most important TypeScript features appears here:

```typescript
const posts =
  await client.fetch<PostSummary[]>(
    POSTS_QUERY
  );
```

The syntax:

```typescript
<T>
```

is called a generic.

You can read:

```typescript
fetch<PostSummary[]>()
```

as:

> Execute this function and tell TypeScript that the result must satisfy the PostSummary[] contract.

Likewise:

```typescript
const post =
  await client.fetch<
    Post | null
  >(
    POST_QUERY,
    { slug }
  );
```

means:

> This function returns either a valid Post or nothing.

---

# Union Types

This syntax:

```typescript
Post | null
```

is called a union type.

It means:

```text
This value may be:

Post

OR

null
```

This forces us to handle both possibilities.

For example:

```typescript
if (!post) {
  notFound();
}
```

The type system now guarantees:

```text
No null access occurs.
```

---

# Contracts Exist Everywhere

One of the major themes of GreyMatter Journal is:

> Software systems scale through contracts.

Consider our architecture:

```text
Sanity Schema
       ↓
GROQ Query
       ↓
TypeScript Type
       ↓
React Component
       ↓
Rendered UI
```

Each layer defines a contract.

For example:

```typescript
defineField({
  name: "title",
  type: "string",
});
```

becomes:

```typescript
type Post = {
  title: string;
};
```

which becomes:

```tsx
<h1>{post.title}</h1>
```

This entire chain depends on contracts remaining consistent.

---

# Reliability Is Mostly About Contracts

Many software failures are not algorithm failures.

They are contract failures.

Examples:

```text
API returned wrong shape

Database field missing

Property renamed

Null value unexpected

Schema changed
```

Type systems exist to detect these failures early.

Without types:

```text
Deploy
    ↓
User discovers bug
```

With types:

```text
Write code
     ↓
Editor detects bug
```

---

# Mental Model To Remember Forever

Beginners think:

```text
TypeScript
        =
JavaScript
+
Extra Syntax
```

Professional engineers think:

```text
TypeScript
        =
Executable Contracts
```

More broadly:

```text
Schema
     ↓
Query
     ↓
Type
     ↓
Component
     ↓
UI
```

Reliable systems emerge when every layer agrees on reality.

---

# Up Next — Part 18: Loading States, Error Boundaries, and Reliability Engineering

We'll learn how modern applications handle failure through:

* loading.tsx
* error.tsx
* not-found.tsx
* Suspense
* Error boundaries
* Progressive rendering
* Failure isolation
