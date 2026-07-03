# Appendix H — Production Folder Structures and Architecture Patterns: Organizing Large Next.js Applications for Teams, Scale, and Longevity

> **Goal of this appendix:** Learn how to organize a production-grade Next.js 16 application so that it remains understandable, maintainable, and scalable as features, developers, and complexity increase.

---

# Introduction

One of the first questions developers ask after building their first successful application is:

> "Where should I put my files?"

This seems like a simple organizational question.

It isn't.

Because the real question is:

```text
How do humans manage complexity?
```

---

# The Beginner Folder Structure

Most tutorials begin like this:

```text
app/
components/
utils/
hooks/
```

This works when your application contains:

```text
3 pages
5 components
1 developer
```

Unfortunately, real applications become:

```text
300 pages
500 components
20 developers
5 years of history
```

---

# Why Folder Structures Matter

Consider this project:

```text
components/

    Button.tsx
    Button2.tsx
    NewButton.tsx
    FinalButton.tsx
    FinalButton2.tsx
    BetterButton.tsx
```

This folder structure tells us:

```text
Nothing.
```

Folders are not merely containers.

They are:

```text
Maps
of human understanding.
```

---

# The Evolution Of Applications

Most applications evolve through predictable stages.

---

# Stage 1 — Tutorial Project

```text
app/

components/

lib/
```

Example:

```text
blog/

├── app
├── components
└── lib
```

Suitable for:

```text
1 developer
1 month
```

---

# Stage 2 — Small Production Application

```text
app/

components/

actions/

lib/

types/
```

Example:

```text
greymatter-journal/

├── app
├── components
├── actions
├── lib
└── types
```

Suitable for:

```text
1–3 developers
```

---

# Stage 3 — Feature-Based Architecture

Instead of:

```text
components/

    PostCard

    CommentCard

    LikeButton
```

we organize by:

```text
Features
```

Example:

```text
features/

    posts/

    comments/

    likes/
```

---

# Why Features?

Humans think:

```text
About problems.
```

Humans do not think:

```text
About file types.
```

---

# Bad Organization

```text
components/
hooks/
actions/
types/
```

Question:

> "Where is comment functionality?"

Answer:

```text
Everywhere.
```

---

# Better Organization

```text
features/

    comments/

        components/

        actions/

        hooks/

        types/
```

Now:

```text
Comments
=
One place.
```

---

# GreyMatter Journal Production Structure

```text
greymatter-journal/

├── app/
│
├── features/
│   ├── posts/
│   ├── comments/
│   ├── likes/
│   ├── auth/
│   └── analytics/
│
├── components/
│
├── lib/
│
├── types/
│
├── hooks/
│
├── actions/
│
├── studio/
│
├── public/
│
└── tests/
```

---

# App Router Structure

```text
app/

├── layout.tsx

├── page.tsx

├── posts/
│   ├── page.tsx
│   └── [slug]/
│       ├── page.tsx
│       ├── loading.tsx
│       ├── error.tsx
│       └── not-found.tsx

├── about/

└── admin/
```

---

# Route Groups

Next.js supports:

```text
(route groups)
```

Example:

```text
app/

├── (marketing)

├── (dashboard)

├── (auth)
```

---

# Why Route Groups Exist

Consider:

```text
Website

Admin Dashboard

Authentication
```

These are:

```text
Different applications
inside one application.
```

---

# Example

```text
app/

├── (site)
│   ├── page.tsx
│   ├── posts
│   └── about

├── (auth)
│   ├── sign-in
│   └── sign-up

└── (admin)
    ├── dashboard
    └── analytics
```

---

# Shared Components

Create:

```text
components/
```

Example:

```text
components/

├── Button.tsx

├── Card.tsx

├── Modal.tsx

├── Spinner.tsx
```

Rule:

> Shared components contain no business logic.

---

# Feature Components

Example:

```text
features/

└── comments/

    └── components/

        CommentList.tsx

        CommentForm.tsx

        CommentCard.tsx
```

Rule:

> Feature components contain business logic.

---

# Server Actions

Organize:

```text
actions/

    comments.ts

    likes.ts

    posts.ts
```

Or:

```text
features/

    comments/

        actions.ts
```

Both are acceptable.

---

# The Lib Folder

The most abused folder in software engineering:

```text
lib/
```

Many projects become:

```text
lib/

    everything.ts
```

This is known as:

```text
The Junk Drawer Pattern.
```

---

# Good Lib Folder

```text
lib/

├── sanity.ts

├── auth.ts

├── cache.ts

├── analytics.ts

├── logger.ts

└── image.ts
```

Rule:

```text
Infrastructure only.
```

---

# Types Folder

Create:

```text
types/

    post.ts

    comment.ts

    author.ts

    api.ts
```

Example:

```typescript
export interface Post {

  _id: string;

  title: string;

  slug: {
    current: string;
  };
}
```

---

# Hooks Folder

```text
hooks/

    useLike.ts

    useComment.ts

    useSearch.ts
```

Rule:

```text
Hooks encapsulate behavior.
```

---

# Testing Folder

```text
tests/

├── unit/

├── integration/

├── e2e/
```

Example:

```text
tests/

    unit/

        formatDate.test.ts

    integration/

        comments.test.ts

    e2e/

        login.spec.ts
```

---

# Configuration Folder

Large applications often create:

```text
config/

    auth.ts

    cache.ts

    constants.ts

    routes.ts
```

---

# Feature Slice Architecture

Modern frontend architecture increasingly favors:

```text
Feature Slices
```

Example:

```text
features/

└── comments/

    components/

    actions/

    hooks/

    types/

    validation/

    queries/

    constants/
```

Everything related to comments exists together.

---

# Vertical Versus Horizontal

Horizontal:

```text
components/

hooks/

types/

actions/
```

Vertical:

```text
comments/

posts/

likes/
```

Large systems increasingly prefer:

```text
Vertical organization.
```

---

# Why?

Because humans understand:

```text
Stories.
```

Humans struggle with:

```text
Taxonomies.
```

---

# Monorepo Architecture

As applications grow:

```text
apps/

packages/
```

Example:

```text
monorepo/

├── apps/

│   ├── website

│   └── admin

├── packages/

│   ├── ui

│   ├── auth

│   ├── database

│   └── analytics
```

---

# Shared Package Example

```text
packages/ui/

    Button.tsx

    Card.tsx

    Modal.tsx
```

Used by:

```text
Website

Admin

Dashboard
```

---

# The Hidden Architecture

When developers see:

```text
Folder Structure
```

they assume:

```text
Storage.
```

In reality:

```text
Folder Structure
         =
Organizational Structure
         =
Communication Structure
```

---

# Conway's Law

One of the most important laws in software engineering states:

> Organizations design systems that mirror their communication structures.

Example:

```text
Frontend Team

Backend Team

Platform Team
```

often creates:

```text
frontend/

backend/

platform/
```

---

# Architecture Layers

Large systems typically organize into:

```text
Presentation
       │
       ▼

Application
       │
       ▼

Domain
       │
       ▼

Infrastructure
```

---

# GreyMatter Journal Layering

```text
app/
    │
    ▼

features/
    │
    ▼

actions/
    │
    ▼

lib/
    │
    ▼

Sanity
```

---

# Wait...

Does This Look Familiar?

We've discovered:

```text
State Trees

Trust Trees

Identity Trees

Failure Trees

Cache Trees

Execution Trees

Time Trees
```

Folder structures introduce:

```text
Knowledge Trees
```

because every architecture ultimately asks:

```text
Where does
understanding
live?
```

---

# The Deep Secret Of Folder Structures

Most beginners think:

```text
Folder Structure
               =
Where Files Go
```

Professional engineers think:

```text
Folder Structure
               =
How Humans
               Think
```

---

# The Deep Secret Of Software Architecture

Software architecture is not primarily about:

```text
Frameworks

Patterns

Libraries
```

It is primarily about:

```text
Managing Human Complexity.
```

---

# Mental Model To Remember Forever

Beginners think:

```text
Code
    =
Software
```

Professional engineers think:

```text
Code
    =
A representation
of collective
human understanding.
```

A folder structure is not an implementation detail.

It is a map of:

```text
Responsibility,

Knowledge,

Communication,

Complexity,

and Time.
```

And ultimately, software engineering is the discipline of organizing all five.
