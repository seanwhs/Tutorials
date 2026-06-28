# Appendix A9 — Next.js 16 Project Structure & Architecture Cheat Sheet

## The Complete Guide to Organizing Real-World Next.js Applications

> **Purpose:** This appendix is the definitive reference for organizing Next.js 16 applications. Most beginner tutorials stop at "how to build features." Professional engineering begins with understanding how to organize complexity.

---

# Introduction

The biggest mistake beginners make is:

```text
My application works.
```

Professional engineers ask:

```text
Will my application
still work after
500 files,
20 developers,
and 2 years?
```

Because architecture is not about making software work.

It is about making software continue to work.

---

# The Evolution of Next.js Architecture

## Stage 1

Beginner project:

```text
app/
    page.tsx
```

---

## Stage 2

Small project:

```text
app/
    about/
    blog/
    dashboard/
```

---

## Stage 3

Medium project:

```text
app/
components/
lib/
actions/
```

---

## Stage 4

Production project:

```text
app/
modules/
shared/
infrastructure/
```

---

# The Core Rule

Organize by:

```text
Business capability
```

Not by:

```text
Technology.
```

---

# Bad Structure

```text
components/

hooks/

services/

utils/

types/

helpers/
```

---

# Why?

Because eventually:

```text
Everything
goes
everywhere.
```

---

# Better Structure

```text
modules/

    posts/

    users/

    billing/

    analytics/
```

---

# The Next.js App Router Structure

Default:

```text
app/

    page.tsx

    layout.tsx

    loading.tsx

    error.tsx

    not-found.tsx
```

---

# Visualizing

```text
app
 |
 +-- layout
 |
 +-- page
 |
 +-- loading
 |
 +-- error
```

---

# Example Project

```text
app/

    page.tsx

    blog/

    dashboard/

    account/
```

---

# Route Groups

Example:

```text
app/

    (marketing)/

    (dashboard)/
```

---

# Visualizing

```text
URL
 |
No change
 |
Organization only
```

---

# Example

```text
app/

    (public)/

        about/

        blog/

    (private)/

        dashboard/

        settings/
```

---

# Why Route Groups?

They allow:

```text
Different layouts

Different middleware

Different concerns
```

---

# Layout Hierarchy

Example:

```text
app/

    layout.tsx

    dashboard/

        layout.tsx

        analytics/
```

---

# Visualizing

```text
Root Layout
       |
Dashboard Layout
       |
Page
```

---

# Example

Root:

```tsx
export default function Layout({
  children,
}) {

  return children;

}
```

---

Dashboard:

```tsx
export default function DashboardLayout({
  children,
}) {

  return (
    <Dashboard>
      {children}
    </Dashboard>
  );

}
```

---

# Colocation

Store files:

```text
Near where
they are used.
```

---

Example:

```text
blog/

    page.tsx

    loading.tsx

    error.tsx

    components.tsx
```

---

# Benefits

```text
✓ Easier navigation

✓ Easier deletion

✓ Easier refactoring
```

---

# Shared Components

Example:

```text
components/

    button.tsx

    modal.tsx

    card.tsx
```

---

# Shared UI Structure

```text
components/

    ui/

        button.tsx

        dialog.tsx

        input.tsx
```

---

# Feature-Based Architecture

Example:

```text
modules/

    posts/

    comments/

    users/
```

---

# Visualizing

```text
Application
      |
      +---- Posts
      |
      +---- Users
      |
      +---- Billing
```

---

# Module Structure

Example:

```text
modules/

    posts/

        actions.ts

        queries.ts

        types.ts

        validators.ts

        components/

        hooks/
```

---

# Why?

Because everything related to:

```text
Posts
```

lives together.

---

# Example

```text
modules/

    users/

        actions.ts

        queries.ts

        permissions.ts

        components/
```

---

# Data Layer

Example:

```text
lib/

    db.ts

    auth.ts

    cache.ts
```

---

# Infrastructure Layer

Example:

```text
infrastructure/

    prisma/

    redis/

    stripe/

    github/
```

---

# Visualizing

```text
Business Logic
        |
Infrastructure
        |
External Systems
```

---

# Server Actions Organization

Bad:

```text
actions/

    everything.ts
```

---

Better:

```text
modules/

    posts/

        actions.ts

    users/

        actions.ts
```

---

# Example

```text
modules/

    posts/

        create.ts

        update.ts

        delete.ts
```

---

# Route Handlers

Example:

```text
app/

    api/

        auth/

        stripe/

        webhooks/
```

---

# API Organization

```text
api/

    auth/

    billing/

    cms/

    uploads/

    webhooks/
```

---

# Database Layer

Example:

```text
database/

    schema/

    migrations/

    seeds/
```

---

# Validation Layer

Example:

```text
modules/

    posts/

        schema.ts
```

---

Example:

```ts
export const postSchema =
  z.object({

    title:
      z.string(),

  });
```

---

# Type Definitions

Example:

```text
modules/

    posts/

        types.ts
```

---

Example:

```ts
export interface Post {

  id: number;

  title: string;

}
```

---

# Queries

Example:

```text
modules/

    posts/

        queries.ts
```

---

Example:

```ts
export async function
getPosts() {

  "use cache";

}
```

---

# Mutations

Example:

```text
modules/

    posts/

        actions.ts
```

---

Example:

```ts
"use server";

export async function
createPost() {

}
```

---

# Components

Example:

```text
modules/

    posts/

        components/

            post-card.tsx
```

---

# Feature Encapsulation

```text
posts/

    everything
```

belongs here.

---

# Enterprise Structure

```text
src/

    app/

    modules/

    shared/

    infrastructure/

    tests/

    scripts/
```

---

# Shared Layer

Example:

```text
shared/

    ui/

    hooks/

    constants/

    utils/
```

---

# Example

```text
shared/

    constants/

        routes.ts

        permissions.ts
```

---

# Configuration

Example:

```text
config/

    auth.ts

    cache.ts

    database.ts
```

---

# Environment Variables

Example:

```text
.env

.env.local

.env.production
```

---

# Testing Structure

Example:

```text
tests/

    unit/

    integration/

    e2e/
```

---

# Alternative

```text
posts/

    __tests__/
```

---

# Scripts

Example:

```text
scripts/

    seed.ts

    migrate.ts

    backup.ts
```

---

# Public Assets

Example:

```text
public/

    images/

    fonts/

    icons/
```

---

# Large Project Example

```text
src/

├── app/
│
├── modules/
│   ├── auth/
│   ├── posts/
│   ├── users/
│   ├── billing/
│   └── analytics/
│
├── shared/
│   ├── ui/
│   ├── hooks/
│   └── constants/
│
├── infrastructure/
│   ├── prisma/
│   ├── redis/
│   ├── stripe/
│   └── github/
│
├── tests/
│
└── scripts/
```

---

# Monolith Architecture

```text
Application

     |

Modules

     |

Infrastructure
```

---

# Dependency Direction

Correct:

```text
UI
 |
Business
 |
Infrastructure
```

---

Wrong:

```text
Infrastructure
 |
Business
 |
UI
```

---

# Architecture Layers

```text
Presentation

       |

Application

       |

Domain

       |

Infrastructure
```

---

# Example

```text
Page
 |
Server Action
 |
Service
 |
Repository
 |
Database
```

---

# Caching Organization

Example:

```text
modules/

    posts/

        cache.ts
```

---

Example:

```ts
export const TAGS = {

  POSTS:
    "posts",

  AUTHORS:
    "authors",

};
```

---

# Error Handling

Example:

```text
shared/

    errors/
```

---

# Logging

Example:

```text
shared/

    logger/
```

---

# Security

Example:

```text
shared/

    auth/

    permissions/
```

---

# Feature Flags

Example:

```text
shared/

    feature-flags/
```

---

# Common Beginner Mistakes

---

## Mistake 1

```text
utils/
```

containing:

```text
500 files.
```

---

## Mistake 2

```text
helpers/
```

containing:

```text
Everything.
```

---

## Mistake 3

Putting business logic in:

```text
Components.
```

---

## Mistake 4

One giant:

```text
actions.ts
```

---

## Mistake 5

One giant:

```text
lib.ts
```

---

## Mistake 6

Organizing by technology.

---

# Architecture Decision Tree

Need:

```text
Feature-specific?
```

Place in:

```text
modules/
```

---

Need:

```text
Reusable UI?
```

Place in:

```text
shared/ui
```

---

Need:

```text
External service?
```

Place in:

```text
infrastructure
```

---

Need:

```text
Global configuration?
```

Place in:

```text
config
```

---

Need:

```text
Testing?
```

Place in:

```text
tests
```

---

# The Complete Next.js Architecture

```text
                    UI
                     |
                     |
                 Modules
                     |
                     |
                Services
                     |
                     |
              Infrastructure
                     |
                     |
              External Systems
```

---

# Mental Model

Beginners think:

```text
Folders
=
Organization.
```

Professional engineers think:

```text
Folders
=
Boundaries.
```

Because good architecture is not about where files live.

It is about controlling:

```text
Dependencies

Complexity

Coupling

Change
```

over the lifetime of the system.
