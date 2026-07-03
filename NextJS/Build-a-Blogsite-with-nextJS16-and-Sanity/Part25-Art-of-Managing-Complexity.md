# GreyMatter Journal

# Part 25 — Refactoring to Production Architecture, Dependency Inversion, and the Art of Managing Complexity

> **Goal of this lesson:** Refactor GreyMatter Journal into a production-grade architecture while learning software architecture, separation of concerns, dependency inversion, layering, boundaries, and why software engineering ultimately becomes the discipline of managing complexity rather than writing code.

***

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

```text
Success.
```

***

# Wait…

How Can Success Become a Problem?

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

New question:

```text
Where does anything belong?
```

Answer:

```text
Nobody is quite sure.
```

As the codebase grows, the primary risk is no longer “does it work?” but “can anyone understand it?”.

***

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

The features are just the user-facing surface; architecture is about everything underneath that makes ongoing change possible.

***

# What Is Complexity?

Suppose you have:

```javascript
function add(a, b) {
  return a + b;
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

Architecture is the set of constraints that makes that understanding possible.

***

# The First Rule of Architecture

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

Boundaries answer:

```text
What belongs where?

What depends on what?

What is allowed to talk to what?
```

***

# Why Boundaries Matter

Suppose you design a city.

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

all mixed together?

Of course not.

Instead you create:

```text
Residential Zones

Industrial Zones

Commercial Zones
```

Software architecture works the same way: we partition the system into zones with clear responsibilities.

***

# Our Current Architecture

Right now, it probably looks like:

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

This “flat” architecture scales poorly. Every new concern ends up in `lib/` or `utils/`, and coupling grows silently.

***

# A Production-Oriented Architecture

Let’s introduce a more intentional structure:

```text
src/

├── app/
│
├── domain/
│
├── features/
│
├── infrastructure/
│
└── shared/
```

Each top-level folder represents a different kind of responsibility.

***

# What Are These Layers?

Think in terms of concepts:

```text
Domain
     =
Business Concepts

Infrastructure
     =
Technology & Integrations

Features
     =
Use Cases / Vertical Slices

Shared
     =
Cross-cutting Reusable Code

App
     =
Next.js Wiring & Routes
```

We’re separating *what the system is about* from *how it talks to the outside world*.

***

# Domain Layer

Create:

```text
src/domain/
```

Examples:

```text
domain/
  post.ts
  comment.ts
  author.ts
  user.ts
```

***

## What Goes Into Domain?

Domain contains:

```text
Business Concepts
and
Business Rules
```

Example:

```typescript
export interface Post {
  id: string;
  title: string;
  slug: string;
  publishedAt: Date;
  likes: number;
}
```

Notice what is *not* here:

```text
No React

No Next.js

No Sanity

No HTTP
```

Because:

```text
Business
       ≠
Technology
```

The domain describes *what* things are, not *how* we fetch or render them.

***

# Why Is This Important?

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

Domain models should be stable even when infrastructure changes; otherwise everything becomes brittle.

***

# Infrastructure Layer

Create:

```text
src/infrastructure/
```

Examples:

```text
infrastructure/
  sanity/
  auth/
  analytics/
  logging/
```

This is where technology-specific code lives.

***

## Example: Sanity Integration

```text
infrastructure/sanity/

  client.ts
  queries.ts
  post-repository.ts
```

Example:

```typescript
export async function getPostBySlug(slug: string) {
  return client.fetch(QUERY, { slug });
}
```

This module *knows* about GROQ, Sanity client APIs, and datasets.

***

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

Infrastructure is where you talk to databases, CMSs, queues, external APIs, and cloud services; domain is where you talk about posts, comments, users, and workflows.

***

# Feature Layer

Create:

```text
src/features/
```

Examples:

```text
features/
  posts/
  comments/
  likes/
  search/
  auth/
```

Each feature folder is a vertical slice: UI + use cases + any local logic for a specific capability.

***

## Example Feature Structure

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

       ├── UI Components
       ├── Actions / Use Cases
       ├── Hooks
       └── Types
```

Features orchestrate domain and infrastructure to solve real user problems.

***

# Shared Layer

Create:

```text
src/shared/
```

Examples:

```text
shared/
  components/
  hooks/
  utils/
  constants/
```

This is where you place cross-cutting, reusable pieces that are not tied to a single feature.

***

## Why Shared Exists

Suppose you have a:

```text
Button
```

used by:

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
Common Building Blocks
```

that can be safely reused without pulling in feature-specific dependencies.

***

# Separation of Concerns

Suppose we start with a Next.js page that does everything:

```tsx
export default async function PostPage() {
  const post = await client.fetch();
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

***

# Instead, Refactor Responsibilities

```tsx
export default async function PostPage() {
  const post = await getPostUseCase();
  return <PostView post={post} />;
}
```

Now:

- `PostPage` is responsible for wiring to Next.js (route-level concerns).
- `getPostUseCase` (in `features/posts`) orchestrates data and business logic.
- `PostView` (in `features/posts/components`) renders UI.

Each layer has:

```text
One primary reason
to change.
```

***

# The Single Responsibility Principle

A module should have:

```text
One reason
to change.
```

Bad:

```text
PostService

- Fetches data
- Sends emails
- Logs metrics
- Caches results
- Authenticates users
```

Good:

```text
PostRepository

EmailService

Logger

Cache

AuthService
```

Each module focuses on one axis of change.

***

# Responsibility Boundaries

We’ve already talked about:

```text
Failure Boundaries

Trust Boundaries

State Boundaries
```

Architecture introduces:

```text
Responsibility Boundaries
```

Boundaries define:

```text
This module does X,
and only X.
```

Everything else is someone else’s job.

***

# Dependency Inversion

Consider:

```typescript
class PostService {
  constructor(
    private sanity: SanityClient
  ) {}
}
```

Here:

```text
Business Layer
      depends on
Technology Detail
```

Dependency inversion flips this relationship.

***

## Defining an Abstraction

```typescript
export interface PostRepository {
  getPost(slug: string): Promise<Post>;
}
```

Then:

```typescript
class PostService {
  constructor(
    private repo: PostRepository
  ) {}

  async getPost(slug: string) {
    return this.repo.getPost(slug);
  }
}
```

`PostService` now depends on an abstraction (`PostRepository`), not on a concrete `SanityClient`.

***

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

      ├── SanityPostRepository
      ├── ContentfulPostRepository
      └── PostgresPostRepository
```

Business logic doesn’t change when infrastructure does; you only swap implementations.

***

# This Is Dependency Injection

Instead of:

```typescript
const service = new PostService(new SanityClient());
```

we move construction to a higher layer:

```typescript
const repo = new SanityPostRepository(client);
const service = new PostService(repo);
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

Construction and usage are separated.

***

# Why This Feels Familiar in React

Remember patterns like:

```tsx
<AuthProvider>
  <ThemeProvider>
    <QueryProvider>
      {children}
    </QueryProvider>
  </ThemeProvider>
</AuthProvider>
```

These are all:

```text
Dependency Injection
```

mechanisms: they inject context and services into the React tree without hard-coding them everywhere.

***

# Layered Architecture

Classic layered architecture:

```text
Presentation (UI)

       ▲

Application (Use Cases)

       ▲

Domain (Business)

       ▲

Infrastructure (Details)
```

Rule of thumb:

```text
Upper layers
depend on
lower abstractions,
not concrete infrastructure.
```

Details are plugged in at the edges.

***

## Bad vs Good Flow

Bad:

```text
React
   │
   ▼
Sanity
```

UI directly talks to CMS APIs.

Good:

```text
React (Presentation)
   │
   ▼

Use Case / Service (Application)
   │
   ▼

Repository Interface (Domain)
   │
   ▼

Sanity Implementation (Infrastructure)
```

Each layer has a clear role and clear dependencies.

***

# What Is a Use Case?

Examples:

```text
Get Post

Create Comment

Publish Article

Like Article
```

Use cases represent:

```text
Business Actions
```

They answer: “What does this system do for the user?” not “Which HTTP call does it make?”.

***

## Example Use Case

```typescript
export async function createCommentUseCase(
  input: CommentInput,
  repo: CommentRepository
) {
  // validate, enforce rules, etc.
  return repo.create(input);
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
wired through abstractions.
```

***

# Architecture Is Compression

Suppose you have:

```text
100,000 lines
of code
```

Humans cannot hold:

```text
100,000 lines
in their head at once.
```

But humans can understand:

```text
Posts

Comments

Users

Auth
```

Architecture compresses complexity into concepts.

Instead of thinking about every file, you think about a few well-defined modules and their contracts.

***

# Conway’s Law

One of the most important observations in software:

> Systems tend to mirror the communication structures of the organizations that build them.

Example organization:

```text
Frontend Team
Backend Team
Platform Team
```

Often produces architecture like:

```text
Frontend

Backend

Platform / Infra
```

This is neither good nor bad; it’s a reminder that architecture is partly a **social** design.

***

# Is Architecture Social?

Yes.

Software architecture is:

```text
Part Technical

Part Organizational

Part Cognitive
```

Because software exists to help:

```text
Humans
understand
complexity.
```

If the team cannot understand the system, the architecture is failing, regardless of how “clean” the code looks.

***

# The Hidden Architecture of GreyMatter

Conceptually, our final GreyMatter Journal looks like:

```text
Next.js App (app/)
     │
     ▼

Features (posts, comments, auth, etc.)
     │
     ▼

Use Cases / Services
     │
     ▼

Domain Models
     │
     ▼

Repositories (interfaces)
     │
     ▼

Infrastructure (Sanity, Clerk, Vercel, etc.)
     │
     ▼

External Systems
```

Each layer knows only what it needs to know, and nothing more.

***

# Complexity Trees

We’ve already discovered:

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

Now we add:

```text
Complexity Trees
```

because architecture is:

```text
The way we shape
and prune
complexity.
```

Each “branch” is a module, boundary, or abstraction that helps us reason about a system too large to see all at once.

***

# The Deep Secret of Software Architecture

Most beginners think:

```text
Architecture
            =
Folder Structure
```

Professional engineers think:

```text
Architecture
            =
Decisions
            About
            Complexity
```

Key questions:

```text
What changes most?

How often does it change?

Who owns it?

What depends on it?

Can we replace it?

Can humans understand it
in a few diagrams or pages?
```

Architecture is the set of constraints that keep these answers sane over time.

***

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
Can Fully Hold
```

Once you see architecture this way, frameworks, patterns, layers, and dependencies become tools for one task: keeping complexity just small enough for humans to safely change the system.

***

# Up Next

In **Part 26 (Finale)**, we’ll step back and examine everything we’ve built while exploring:

- why software engineering is fundamentally systems thinking,
- how React, Next.js, databases, caches, CDNs, and AI systems share the same underlying principles,
- and why becoming a senior engineer is ultimately about developing better mental models rather than learning more frameworks.
