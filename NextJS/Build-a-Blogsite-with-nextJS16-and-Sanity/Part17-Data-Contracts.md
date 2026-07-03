# GreyMatter Journal

# Part 17 — TypeScript, Data Contracts, and Building Reliable Software Systems

> **Goal of this lesson:** Replace our use of `any` with proper TypeScript types, understand why type systems exist, learn how interfaces and generics work, and discover that software engineering is fundamentally about creating reliable contracts between systems.

---

# We've Been Cheating

Throughout this tutorial, we've written code like this:

```tsx
function PortableTextRenderer({
  value,
}: {
  value: any;
}) {
  ...
}
```

and:

```tsx
const posts =
  await client.fetch(
    POSTS_QUERY
  );
```

without telling TypeScript:

```text
What exactly is a post?
```

This works.

Until it doesn't.

---

# The Problem With `any`

Suppose we write:

```typescript
const post: any = {
  title:
    "React"
};
```

Now TypeScript allows:

```typescript
post.author.name;
```

even though:

```text
author
doesn't exist.
```

This means:

```text
Compiler
      ↓
No Protection
```

Diagram:

```text
Developer

      │

      ▼

TypeScript

      │

      ▼

¯\_(ツ)_/¯
```

---

# Why Do Type Systems Exist?

Many beginners think:

```text
TypeScript
        =
Annoying Syntax
```

But type systems solve a deeper problem.

Suppose you hire a contractor.

Without a contract:

```text
"I'll build something."
```

Problems arise.

With a contract:

```text
I promise:

✓ Build a house
✓ Three bedrooms
✓ Two bathrooms
✓ Garage
```

Now everyone agrees on expectations.

---

# Types Are Contracts

Consider:

```typescript
function add(
  a: number,
  b: number
) {
  return a + b;
}
```

The type contract says:

```text
Input:
number

Input:
number

Output:
number
```

Diagram:

```text
Input
   │
   ▼

Function

   │
   ▼

Output
```

This idea scales to entire systems.

---

# What Is A Blog Post?

Let's answer that question formally.

Create:

```text
types/

post.ts
```

Add:

```typescript
export interface Author {
  name: string;
}

export interface Category {
  title: string;
}

export interface Slug {
  current: string;
}

export interface Post {
  _id: string;

  title: string;

  excerpt: string;

  body?: unknown;

  publishedAt: string;

  slug: Slug;

  mainImage?: unknown;

  author: Author;

  categories: Category[];
}
```

---

# Wait...

Why Are We Creating Interfaces?

Suppose we write:

```typescript
const post = {
  title: "React",
};
```

TypeScript infers:

```typescript
{
  title: string;
}
```

But interfaces allow:

```text
Shared Agreements
```

Diagram:

```text
Database

     │

     ▼

Interface

     │

     ▼

Application
```

Interfaces document expectations.

---

# What Is An Interface?

Most tutorials say:

> Interfaces describe object shapes.

That's true.

But a better explanation is:

> Interfaces define contracts between systems.

Example:

```typescript
interface User {
  name: string;
  age: number;
}
```

means:

```text
Any object claiming
to be a User
must satisfy
this contract.
```

---

# Step 2 — Type The Post Card

Open:

```text
components/PostCard.tsx
```

Replace:

```typescript
type PostCardProps = {
  post: {
    ...
  };
};
```

with:

```typescript
import {
  Post,
} from "@/types/post";

type Props = {
  post: Post;
};

export default function
PostCard({
  post,
}: Props) {
  ...
}
```

---

# What Did We Gain?

Suppose we accidentally write:

```typescript
post.author.fullName
```

TypeScript immediately reports:

```text
Property
'fullName'
does not exist.
```

Diagram:

```text
Write Bug

    │

    ▼

Compiler

    │

    ▼

Stop
```

This is one of the greatest productivity features ever invented.

---

# Step 3 — Type The Query Results

Currently:

```typescript
const posts =
  await client.fetch(
    POSTS_QUERY
  );
```

produces:

```typescript
any
```

But `fetch()` supports generics.

Update:

```typescript
const posts =
  await client.fetch<Post[]>(
    POSTS_QUERY
  );
```

---

# Wait...

What Are Generics?

Generics confuse almost everyone initially.

Suppose we write:

```typescript
function identity(
  value
) {
  return value;
}
```

What type does it return?

We don't know.

Generics allow us to say:

```typescript
function identity<T>(
  value: T
): T {
  return value;
}
```

Diagram:

```text
Input Type
      │
      ▼

Generic Function

      │
      ▼

Output Same Type
```

---

# Example

Suppose:

```typescript
identity(
  "hello"
);
```

Then:

```text
T = string
```

Suppose:

```typescript
identity(
  42
);
```

Then:

```text
T = number
```

The function adapts.

---

# `client.fetch<T>()` Works Similarly

When we write:

```typescript
client.fetch<Post[]>(
  POSTS_QUERY
)
```

We're telling TypeScript:

```text
Trust me.

This query returns:

Post[]
```

Diagram:

```text
Query

      │

      ▼

Type Contract

      │

      ▼

Typed Result
```

---

# Step 4 — Type The Single Post Query

Open:

```text
app/posts/[slug]/page.tsx
```

Update:

```typescript
const post =
  await client.fetch<
    Post | null
  >(
    POST_QUERY,
    {
      slug:
        params.slug,
    }
  );
```

---

# Why `Post | null`?

Suppose the article exists:

```text
Result:
Post
```

Suppose it doesn't:

```text
Result:
null
```

Diagram:

```text
Exists?

 YES         NO
  │           │
  ▼           ▼

Post       null
```

TypeScript forces us to handle both.

---

# This Is Called A Union Type

Example:

```typescript
let value:
  string | null;
```

means:

```text
Possible Values

string

or

null
```

This models reality.

---

# Reality Matters

Software bugs often happen because developers think:

```text
One possibility.
```

Reality contains:

```text
Many possibilities.
```

Example:

```typescript
User

or

null
```

Example:

```typescript
Success

or

Error
```

Example:

```typescript
Loaded

or

Loading
```

Type systems force us to acknowledge reality.

---

# Step 5 — Create Shared Query Types

Create:

```text
types/

queries.ts
```

Add:

```typescript
import {
  Post,
} from "./post";

export type PostsQuery =
  Post[];

export type PostQuery =
  Post | null;
```

Now:

```typescript
const posts =
  await client.fetch<
    PostsQuery
  >(
    POSTS_QUERY
  );
```

---

# Why Create Aliases?

Suppose our model changes.

Without aliases:

```text
100 files
100 updates
```

With aliases:

```text
1 file
1 update
```

This is called:

# Abstraction

---

# What Is Abstraction?

Most tutorials say:

> Hide complexity.

A better definition:

> Create useful simplifications.

Example:

```text
Car

instead of

10,000 parts.
```

Example:

```typescript
Post
```

instead of:

```typescript
{
  _id: string;
  title: string;
  ...
}
```

---

# TypeScript Creates Executable Documentation

Suppose another developer sees:

```typescript
interface Post {
  title: string;

  author: Author;

  categories:
    Category[];
}
```

They immediately understand:

```text
What exists

What doesn't exist

What's required

What's optional
```

The code becomes documentation.

---

# Wait...

Does This Look Familiar?

We've already seen:

```text
API Contracts

Portable Text Contracts

Component Contracts

Route Contracts
```

Now:

```text
Type Contracts
```

appear too.

---

# The Hidden Secret Of Software Engineering

Most beginners think:

```text
Programming
         =
Writing Code
```

Professional engineers think:

```text
Programming
         =
Managing Assumptions
```

Example:

```text
Database
     ↓
Contract
     ↓
API
     ↓
Contract
     ↓
Frontend
```

Every layer communicates through contracts.

---

# Why TypeScript Became Dominant

JavaScript allows:

```typescript
post.author.name
```

even if:

```typescript
post.author
```

doesn't exist.

TypeScript says:

```text
Prove it.
```

This single principle prevents enormous classes of bugs.

---

# The Full Architecture Now

Our application now contains:

```text
Sanity Schema
       │
       ▼

Content

       │
       ▼

GROQ Query

       │
       ▼

Type Contract

       │
       ▼

React Component

       │
       ▼

UI
```

Notice:

```text
Data
     +
Contracts
     +
Transformations
```

Again.

---

# Mental Model To Remember Forever

Beginners think:

```text
TypeScript
          =
Extra Syntax
```

Professional engineers think:

```text
TypeScript
          =
Executable Contracts
```

Or more generally:

```text
Software Engineering
                    =
Building
                    Reliable
                    Abstractions
```

The code itself is often the easy part.

The hard part is ensuring every assumption remains true.

---

# Up Next

In **Part 18**, we'll implement loading states, error handling, and not-found pages while learning:

* how asynchronous systems fail,
* what error boundaries really are,
* why loading is a first-class architectural concern,
* how Suspense works,
* and why reliability engineering is fundamentally about managing uncertainty.
