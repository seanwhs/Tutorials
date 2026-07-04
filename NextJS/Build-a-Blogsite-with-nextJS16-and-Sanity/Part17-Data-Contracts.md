# GreyMatter Journal

# Part 17 — TypeScript, Data Contracts, and Building Reliable Software Systems

## Why Modern Software Scales Through Contracts Rather Than Assumptions

> **Goal of this lesson:** Replace `any` with explicit contracts, understand why type systems exist, explore generics and unions deeply, and discover why reliable software systems emerge from shared agreements rather than shared assumptions.

---

# We've Been Cheating

Throughout this series, we've occasionally written code like this:

```tsx
posts.map((post: any) => ...)
```

Or:

```tsx
function PostCard({
  post,
}: {
  post: any;
}) {
  ...
}
```

The application works.

The page renders.

No errors appear.

Which naturally leads beginners to ask:

> If everything works, why should I care?

Because one of the most important lessons in software engineering is:

```text
Works
    ≠
Correct

Correct
    ≠
Reliable

Reliable
    ≠
Maintainable
```

Most software failures occur long after the code successfully ran for the first time.

---

# Software Engineering Is Mostly About Managing Uncertainty

Consider this innocent-looking line:

```typescript
post.title
```

It appears simple.

But hidden inside it are numerous assumptions:

```text
Assumption 1:
post exists

Assumption 2:
post has a title property

Assumption 3:
title is a string

Assumption 4:
title is not null

Assumption 5:
title has not been renamed

Assumption 6:
the API returned what we expected
```

The computer does not know these assumptions.

You know them.

Or more accurately:

```text
You think you know them.
```

Large systems fail when assumptions become wrong.

---

# The Fundamental Problem

Imagine our Sanity schema changes.

Yesterday:

```typescript
{
  title: "Understanding React"
}
```

Tomorrow:

```typescript
{
  headline: "Understanding React"
}
```

Our UI still contains:

```typescript
post.title
```

Without types:

```text
Deploy
    ↓
Production
    ↓
Users discover bug
```

With types:

```text
Change schema
      ↓
Compiler fails
      ↓
Developer fixes problem
      ↓
Deploy
```

This is why type systems exist.

---

# Types Are Not About Syntax

Beginners often think:

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
System Verification
```

Or even more fundamentally:

```text
Types
      =
Contracts
```

---

# What Is A Contract?

A contract is simply an agreement.

Consider a restaurant.

The menu defines a contract:

```text
Burger
    =
Bun
    +
Patty
    +
Toppings
```

If the kitchen delivers:

```text
Bun
+
Toppings
```

the contract was violated.

Software works exactly the same way.

---

# Creating Our First Contract

Consider:

```typescript
type User = {
  name: string;
  age: number;
};
```

This creates a contract:

```text
User
 ├── name
 └── age
```

Valid:

```typescript
const user: User = {
  name: "Sean",
  age: 40,
};
```

Invalid:

```typescript
const user: User = {
  name: "Sean",
};
```

TypeScript immediately responds:

```text
Property 'age' is missing.
```

The compiler has become a contract verifier.

---

# GreyMatter Journal's Domain

Our application contains several concepts:

```text
Author

Category

Post

Post Summary

Post Detail

Search Result
```

These concepts become contracts.

Create:

```text
types/content.ts
```

---

# Primitive Contracts

Let's start with our smallest building blocks.

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

---

# Why Use `unknown` Instead of `any`?

This distinction is one of the most important ideas in TypeScript.

Consider:

```typescript
any
```

This means:

```text
I don't care.
```

While:

```typescript
unknown
```

means:

```text
I don't know yet.
```

Those sound similar.

They are actually opposite philosophies.

---

## `any`

```typescript
const x: any = 42;

x.foo.bar.baz();
```

TypeScript says:

```text
Okay.
```

Even though this code is obviously dangerous.

---

## `unknown`

```typescript
const x: unknown = 42;

x.foo;
```

TypeScript says:

```text
No.

Prove what this value is first.
```

In other words:

```text
any
      =
disable safety

unknown
      =
preserve safety
```

---

# Modeling Our Domain

Our homepage requires:

```text
Title
Excerpt
Author
Categories
Image
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

# Article Pages Need More Information

A full article page requires additional data.

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

Notice something subtle.

Many beginners assume:

```text
Database Table
        ↓
One Type
```

Professional systems rarely work this way.

Instead:

```text
Use Case
      ↓
Contract
```

Different views require different contracts.

---

# Search Results Are Different Contracts

A search page only needs:

```text
Title
Excerpt
Slug
Author
```

Therefore:

```typescript
export type SearchResult = {
  _id: string;

  title: string;

  slug: Slug;

  excerpt: string;

  author: Author;
};
```

This reveals a larger principle:

```text
UI Requirements
         ↓
Data Requirements
         ↓
Type Contracts
```

---

# Replacing `any`

Instead of:

```tsx
function PostCard({
  post,
}: {
  post: any;
}) {
  ...
}
```

We write:

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

Now the compiler guarantees:

```text
title exists

slug exists

author exists

categories exist
```

before the application ever runs.

---

# Understanding Generics

One of the most confusing TypeScript syntaxes is:

```typescript
<T>
```

This is called a generic.

Generics are simply contracts that accept other contracts.

---

# Think Of Generics As Containers

Consider:

```typescript
Promise<string>
```

This means:

```text
A Promise
that eventually contains
a string.
```

Likewise:

```typescript
Promise<number>
```

means:

```text
A Promise
that eventually contains
a number.
```

And:

```typescript
Promise<Post>
```

means:

```text
A Promise
that eventually contains
a Post.
```

---

# Arrays Are Also Generics

This syntax:

```typescript
string[]
```

is actually shorthand for:

```typescript
Array<string>
```

Which means:

```text
An array
whose elements
are strings.
```

Similarly:

```typescript
Array<PostSummary>
```

means:

```text
An array
of PostSummary objects.
```

---

# `client.fetch<T>()`

Consider:

```typescript
const posts =
  await client.fetch<
    PostSummary[]
  >(POSTS_QUERY);
```

You can read this as:

> Execute this function and verify that the returned value satisfies the `PostSummary[]` contract.

The generic itself doesn't change runtime behavior.

It changes what TypeScript knows.

---

# Union Types

Consider:

```typescript
Post | null
```

This is called a union.

It means:

```text
Either:

Post

OR

null
```

Nothing else.

---

For example:

```typescript
const post =
  await client.fetch<
    Post | null
  >(
    POST_QUERY,
    { slug }
  );
```

Now TypeScript forces us to consider both possibilities:

```typescript
if (!post) {
  notFound();
}
```

Without this check:

```typescript
post.title
```

would generate a compiler error.

The compiler is protecting us from ourselves.

---

# Contracts Exist Everywhere

One of the recurring themes of GreyMatter Journal is:

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

Each layer promises something to the next layer.

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

The entire system depends on all layers agreeing about reality.

---

# Most Software Failures Are Contract Failures

Many developers imagine software failures as:

```text
Algorithm failed
```

In reality, most failures look like:

```text
API changed

Schema changed

Property renamed

Null appeared

Field removed

Wrong shape returned
```

These are all contract failures.

---

Without contracts:

```text
Developer
      ↓
Deploy
      ↓
Production
      ↓
User discovers bug
```

With contracts:

```text
Developer
      ↓
Compiler detects bug
      ↓
Developer fixes bug
      ↓
Deploy
```

The earlier you detect violations, the cheaper they become.

---

# The Deep Idea

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

And system architects often think:

```text
Reliable Systems
           =
Layers of Contracts
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
User Interface
```

Reliable software emerges when every layer agrees on reality.

---

# Mental Model To Remember Forever

Traditional thinking:

```text
Software
       =
Code
```

Modern engineering thinking:

```text
Software
       =
Code
       +
Contracts
       +
Verification
```

Or, even more fundamentally:

```text
Systems fail when assumptions fail.

Type systems exist to replace assumptions with agreements.
```

---

# Up Next — Part 18: Loading States, Error Boundaries, and Reliability Engineering

Next, we'll explore how modern applications embrace failure through:

* `loading.tsx`
* `error.tsx`
* `not-found.tsx`
* Suspense
* Error boundaries
* Progressive rendering
* Failure isolation
* Reliability engineering principles

Because professional software engineering is not about preventing failure.

It is about designing systems that fail safely.
