# GreyMatter Journal

# Part 25 — Refactoring to Production Architecture, Dependency Inversion, and the Art of Managing Complexity

> **Goal of this lesson:** Refactor GreyMatter Journal into a production-grade architecture while learning software architecture, separation of concerns, dependency inversion, layering, boundaries, and why software engineering ultimately becomes the discipline of managing complexity rather than writing code.

---

# Congratulations

At this point, GreyMatter Journal has:

```text
✓ Next.js App Router
✓ Sanity CMS
✓ Authentication
✓ Comments
✓ Likes
✓ Images
✓ CDN
✓ Deployment
✓ Monitoring
✓ Analytics
```

Unfortunately, we now have the biggest problem of all:

> Success.

---

# Wait...

How Can Success Become A Problem?

Because our application probably now looks something like this:

```text
app/
components/
lib/
utils/
hooks/
services/
helpers/
```

And inside:

```text
lib/
    sanity.ts
    auth.ts
    image.ts
    comments.ts
    likes.ts
    analytics.ts
    logger.ts
    helpers.ts
    utils.ts
```

Question:

```text
Where does anything belong?
```

Nobody knows.

---

# The Beginner Mental Model

Most beginners think:

```text
Software
      =
Features
```

Diagram:

```text
Blog
   │
   ├── Posts
   ├── Comments
   ├── Likes
   └── Auth
```

Professional engineers think:

```text
Software
      =
Managing Complexity
```

---

# What Is Complexity?

Suppose you have:

```javascript
function add(a,b){
  return a+b;
}
```

Complexity:

```text
Low
```

Suppose you have:

```text
500 files

30 APIs

12 databases

100 components

50 services
```

Complexity:

```text
Very High
```

The challenge becomes:

> How do humans understand systems larger than their brains?

---

# The First Rule Of Architecture

Architecture is not about:

```text
Patterns

Frameworks

Microservices

Diagrams
```

Architecture is about:

```text
Boundaries
```

---

# Why Boundaries Matter

Suppose you own a city.

Would you build:

```text
Everything
Everywhere
```

Diagram:

```text
Hospital
School
Airport
Factory
Farm
```

mixed together?

Of course not.

Instead:

```text
Residential

Industrial

Commercial
```

zones exist.

Software architecture works the same way.

---

# Our Current Architecture

Probably:

```text
app/
components/
lib/
```

Diagram:

```text
Everything
     │
     ▼
Everything
     │
     ▼
Everything
```

This scales poorly.

---

# A Production Architecture

Let's reorganize:

```text
src/

├── app/
│
├── features/
│
├── shared/
│
├── infrastructure/
│
└── domain/
```

---

# Wait...

What Are These?

Think:

```text
Domain
     =
Business

Infrastructure
     =
Technology

Features
     =
Use Cases

Shared
     =
Reusable Code
```

---

# Domain Layer

Create:

```text
src/domain/
```

Example:

```text
domain/

post.ts
comment.ts
author.ts
user.ts
```

---

# What Goes Into Domain?

Domain contains:

```text
Business Concepts
```

Example:

```typescript
export interface Post {
  id: string;

  title: string;

  slug: string;

  publishedAt: Date;
}
```

Notice:

```text
No React

No Next.js

No Sanity
```

Because:

```text
Business
       ≠
Technology
```

---

# Wait...

Why Is This Important?

Suppose we replace:

```text
Sanity
```

with:

```text
Contentful
```

Should:

```text
Post
```

change?

No.

Because:

```text
A post
is still
a post.
```

---

# Infrastructure Layer

Create:

```text
src/infrastructure/
```

Example:

```text
infrastructure/

sanity/
auth/
analytics/
logging/
```

---

# Example

```text
infrastructure/

sanity/

    client.ts
    queries.ts
    posts.ts
```

Now:

```typescript
export async function
getPostBySlug(
  slug: string
) {
  return client.fetch(
    QUERY,
    { slug }
  );
}
```

---

# Why Separate Infrastructure?

Because:

```text
Sanity
```

is a:

```text
Technology Decision
```

while:

```text
Blog Post
```

is a:

```text
Business Decision
```

These change at different speeds.

---

# Feature Layer

Create:

```text
src/features/
```

Example:

```text
features/

posts/
comments/
likes/
search/
auth/
```

---

# Example Structure

```text
features/posts/

    components/
    actions/
    hooks/
    types.ts
```

Diagram:

```text
Posts Feature

       │

       ├── UI
       ├── Actions
       ├── Types
       └── Logic
```

---

# Shared Layer

Create:

```text
src/shared/
```

Example:

```text
shared/

components/
hooks/
utils/
constants/
```

---

# Why Shared Exists

Suppose:

```text
Button
```

is used:

```text
Posts

Comments

Auth

Admin
```

Diagram:

```text
Button

   ▲
   │
   ├── Posts
   ├── Auth
   └── Admin
```

Shared contains:

```text
Reusable Things
```

---

# Separation Of Concerns

Suppose we have:

```tsx
export default async function
PostPage() {

  const post =
    await client.fetch();

  await analytics();

  await auth();

  await comments();

  await logging();

  return <UI />;
}
```

Question:

```text
What does this component do?
```

Answer:

```text
Everything.
```

Which means:

```text
Nothing clearly.
```

---

# Instead

```tsx
export default async function
PostPage() {

  const post =
    await getPost();

  return (
    <PostView
      post={post}
    />
  );
}
```

Now:

```text
One responsibility.
```

---

# The Single Responsibility Principle

A module should have:

```text
One reason
to change.
```

Bad:

```text
PostService

Fetches data
Sends email
Logs metrics
Caches results
Authenticates users
```

Good:

```text
PostRepository

EmailService

Logger

Cache
```

---

# Wait...

Haven't We Seen This Before?

Remember:

```text
Failure Boundaries

Trust Boundaries

State Boundaries
```

Architecture introduces:

```text
Responsibility Boundaries
```

---

# Dependency Inversion

Suppose:

```typescript
class PostService {

  constructor(
    private sanity:
      SanityClient
  ) {}
}
```

Problem:

```text
Business
    │
    ▼
Technology
```

Dependency inversion says:

```text
Technology
     │
     ▼
Business
```

---

# Example

Define:

```typescript
export interface
PostRepository {

  getPost(
    slug: string
  ): Promise<Post>;
}
```

Then:

```typescript
class PostService {

  constructor(
    private repo:
      PostRepository
  ) {}
}
```

---

# Why Is This Better?

Today:

```text
Sanity
```

Tomorrow:

```text
Contentful
```

Next year:

```text
Postgres
```

Diagram:

```text
PostService

      │

      ▼

PostRepository

      ▲

      ├── Sanity
      ├── Contentful
      └── Postgres
```

Business code never changes.

---

# This Is Dependency Injection

Instead of:

```typescript
const client =
  new SanityClient();
```

we do:

```typescript
new PostService(
  repository
);
```

Diagram:

```text
Create Dependency
         │
         ▼

Inject Dependency
         │
         ▼

Use Dependency
```

---

# Why Does React Use This?

Remember:

```tsx
<AuthProvider>

<ThemeProvider>

<QueryProvider>
```

These are all:

```text
Dependency Injection
```

systems.

---

# Layered Architecture

Diagram:

```text
Presentation

       ▲

Application

       ▲

Domain

       ▲

Infrastructure
```

Rule:

```text
Upper layers
never know
lower details.
```

---

# Example

Bad:

```text
React
   │
   ▼
Sanity
```

Good:

```text
React
   │
   ▼

Use Case
   │
   ▼

Repository
   │
   ▼

Sanity
```

---

# What Is A Use Case?

Examples:

```text
Get Post

Create Comment

Publish Article

Like Article
```

These represent:

```text
Business Actions
```

---

# Example

```typescript
export async function
createComment(
  input:
    CommentInput
) {
  return repository
    .create(input);
}
```

Notice:

```text
No React

No HTTP

No Database
```

Only:

```text
Business Logic
```

---

# Architecture Is Compression

Suppose you have:

```text
100,000 lines
```

Humans cannot understand:

```text
100,000 lines
```

But humans can understand:

```text
Posts

Comments

Users

Auth
```

Architecture compresses complexity.

---

# Conway's Law

One of the most important laws in engineering:

> Systems resemble the organizations that build them.

Example:

```text
Frontend Team
Backend Team
Platform Team
```

often produces:

```text
Frontend

Backend

Platform
```

architecture.

---

# Wait...

Does This Mean Architecture Is Social?

Yes.

Software architecture is partially:

```text
Technical
```

and partially:

```text
Human
```

because software exists to help:

```text
Humans
understand
complexity.
```

---

# The Hidden Architecture

Our finished GreyMatter Journal now looks like:

```text
app/
     │
     ▼

Features
     │
     ▼

Use Cases
     │
     ▼

Domain
     │
     ▼

Repositories
     │
     ▼

Infrastructure
     │
     ▼

External Systems
```

---

# Wait...

Does This Look Familiar?

We've discovered:

```text
React Trees

Failure Trees

Reality Trees

Trust Trees

State Trees

Cache Trees

Deployment Trees

Observation Trees
```

Now we discover:

```text
Complexity Trees
```

because architecture itself is simply:

```text
Organized
Complexity.
```

---

# The Deep Secret Of Software Architecture

Most beginners think:

```text
Architecture
            =
Folders
```

Professional engineers think:

```text
Architecture
            =
Decisions
            About
            Complexity
```

Questions become:

```text
What changes?

How often?

Who owns it?

What depends on it?

Can we replace it?

Can humans understand it?
```

---

# Mental Model To Remember Forever

Beginners think:

```text
Software Engineering
                    =
Writing Code
```

Professional engineers think:

```text
Software Engineering
                    =
Managing
                    Complexity
```

Or more generally:

```text
Architecture
            =
The Art
            Of Building
            Systems
            Larger
            Than
            Human Brains
```

---

# Up Next

In **Part 26 (Finale)**, we'll step back and examine everything we've built while learning:

* why software engineering is fundamentally systems thinking,
* how React, Next.js, databases, caches, CDNs, and AI systems share the same underlying principles,
* and why becoming a senior engineer is ultimately about developing better mental models rather than learning more frameworks.
