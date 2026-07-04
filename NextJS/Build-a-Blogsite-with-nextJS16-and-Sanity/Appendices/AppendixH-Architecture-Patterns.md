# Appendix H — Production Folder Structures and Architecture Patterns

> **Goal of this appendix:** Understand how production-grade Next.js applications are organized so they remain understandable, maintainable, and scalable as features, developers, and organizational complexity grow over time.

---

# Introduction

One of the biggest misconceptions in software engineering is that folder structures are merely organizational preferences.

They are not.

A folder structure is an architectural decision.

It defines:

* How developers think
* How teams communicate
* How features evolve
* How complexity spreads
* How systems survive long-term maintenance

Small projects can survive with poor organization.

Large systems cannot.

As applications grow, the primary challenge stops being "writing code" and becomes:

> **Managing complexity while preserving understanding.**

This appendix explores the architectural patterns used by professional engineering teams to build software systems that remain maintainable years after their initial release.

---

# 1. Conway's Law: Why Folder Structures Matter

One of the most important principles in software engineering is **Conway's Law**:

> Organizations design systems that mirror their own communication structures.

In practice, this means:

```text
Team Structure
        ↓
Communication Patterns
        ↓
System Architecture
        ↓
Code Organization
```

A poorly organized team often produces:

```text
Messy Teams
        ↓
Messy Architecture
        ↓
Messy Code
```

Conversely:

```text
Clear Ownership
        ↓
Clear Architecture
        ↓
Maintainable Systems
```

When you create folders, you are not merely organizing files.

You are creating:

* boundaries of responsibility
* ownership domains
* communication contracts
* mental models for future developers

A folder structure is ultimately a **map of organizational understanding**.

---

# 2. The Evolution of Application Structure

Most applications evolve through predictable architectural stages.

---

## Stage 1 — Tutorial Architecture

**Best for:**

* Learning
* Prototypes
* Single developer projects
* Applications under a few thousand lines of code

```text
app/
components/
lib/
```

This architecture works because the developer can keep the entire system in their head.

Unfortunately, it scales poorly.

After several months, `components/` often becomes:

```text
components/

Button.tsx
PostCard.tsx
AdminDashboard.tsx
PaymentForm.tsx
CommentSystem.tsx
SearchBar.tsx
AnalyticsWidget.tsx
```

Eventually:

```text
components/
       =
Everything
```

This is the first architectural trap.

---

## Stage 2 — Layered Production Architecture

**Best for:**

* Small teams
* Early production systems
* Medium-sized applications

```text
app/
components/
actions/
lib/
types/
hooks/
```

Benefits:

```text
UI
    separated from

Business Logic
    separated from

Infrastructure
```

This improves maintainability considerably.

However, a new problem emerges.

Suppose you want to modify comments.

You now search through:

```text
components/comments/
actions/comments.ts
types/comment.ts
hooks/useComments.ts
lib/comments.ts
```

The feature becomes fragmented.

This leads to the next evolutionary step.

---

## Stage 3 — Feature-Based Architecture (Vertical Slices)

Modern systems increasingly organize by business capability rather than file type.

Instead of:

```text
components/
actions/
hooks/
types/
```

we organize by:

```text
features/

  comments/
    components/
    actions/
    hooks/
    types/
    validation/

  posts/
    components/
    actions/
    hooks/
    types/

  search/
    components/
    actions/
    hooks/
```

This approach is called:

* Vertical Slices
* Feature Modules
* Domain-Based Architecture

---

### Why Vertical Slices Work

Humans naturally think in terms of problems:

```text
"I need to fix comments."
```

Humans do not think:

```text
"I need to inspect comments.ts,
comment-card.tsx,
useComments.ts,
comment.schema.ts,
and comment.types.ts."
```

Vertical organization aligns software architecture with human cognition.

---

# 3. The GreyMatter Journal Production Architecture

GreyMatter Journal uses a hybrid architecture that balances:

* Next.js App Router requirements
* Feature encapsulation
* Infrastructure separation
* Team scalability

```text
greymatter-journal/

├── app/
├── features/
├── components/
├── actions/
├── lib/
├── studio/
├── types/
└── public/
```

Each layer serves a distinct architectural purpose.

---

## app/ — The Entry Layer

```text
app/
```

The App Router defines:

* URLs
* layouts
* loading boundaries
* error boundaries
* route composition

This layer should contain very little business logic.

Think of it as:

```text
Request
      ↓
Route
      ↓
Feature
```

---

## features/ — The Domain Layer

```text
features/

  comments/
  posts/
  search/
  likes/
```

This is the heart of the application.

Features contain:

```text
Business Rules
Validation
UI
Server Actions
Types
State Management
```

Examples:

```text
features/
    comments/
        components/
        actions/
        validation/
        hooks/
        types/
```

This creates ownership boundaries.

---

## components/ — Shared Presentation

Only place truly reusable UI here.

Examples:

```text
components/

Button
Card
Dialog
Modal
Container
Spinner
```

Never place business logic in shared components.

Bad:

```text
CommentCard.tsx
UserDashboard.tsx
ProductCheckout.tsx
```

Good:

```text
Button.tsx
Card.tsx
Input.tsx
Avatar.tsx
```

---

## lib/ — Infrastructure Layer

The `lib/` folder is one of the most abused folders in software engineering.

A simple rule:

> If it contains business logic, it does not belong in `lib/`.

Examples of legitimate infrastructure:

```text
lib/

sanity.ts
auth.ts
logger.ts
cache.ts
analytics.ts
email.ts
image.ts
```

These files wrap:

* external APIs
* SDKs
* databases
* infrastructure services

They do not implement business rules.

---

## actions/ — Application Layer

Server Actions act as orchestration logic.

Examples:

```text
actions/

comments.ts
likes.ts
posts.ts
```

Responsibilities:

```text
Authentication
Authorization
Transactions
Orchestration
Mutations
```

This layer coordinates systems.

It should not contain domain complexity.

---

# 4. Architectural Layers

Large software systems naturally evolve into layers.

```text
Presentation
        ↓
Application
        ↓
Domain
        ↓
Infrastructure
```

---

## Presentation Layer

```text
app/
components/
```

Responsibilities:

* rendering
* layouts
* styling
* interaction

---

## Application Layer

```text
actions/
```

Responsibilities:

* workflows
* orchestration
* transactions
* permissions

---

## Domain Layer

```text
features/
```

Responsibilities:

* business rules
* validation
* domain concepts
* feature behavior

---

## Infrastructure Layer

```text
lib/
```

Responsibilities:

* databases
* CMS
* logging
* caching
* analytics
* external APIs

---

# 5. Next.js App Router Patterns

Next.js introduces architectural patterns that do not exist in traditional frameworks.

---

## Route Groups

Route groups allow multiple applications to coexist.

```text
app/

(marketing)
(auth)
(dashboard)
(admin)
(api)
```

Examples:

```text
(marketing)
    Landing Pages

(auth)
    Authentication

(admin)
    Internal Tools

(dashboard)
    User Application
```

This creates architectural boundaries without affecting URLs.

---

## Layout Hierarchies

Layouts create persistent UI trees.

```text
Root Layout
        ↓
Marketing Layout
        ↓
Dashboard Layout
        ↓
Page
```

This is fundamentally different from page-based applications.

Modern applications are:

```text
Persistent Trees
```

rather than:

```text
Independent Pages
```

---

# 6. Monorepo Architecture

Eventually, applications outgrow a single project.

This leads to:

```text
apps/
packages/
```

structures.

Example:

```text
apps/
    website/
    admin/
    docs/

packages/
    ui/
    auth/
    database/
    analytics/
```

Benefits:

* shared design systems
* shared business logic
* independent deployments
* versioned internal packages

---

# 7. Design Systems

As applications grow, visual consistency becomes a systems problem.

A design system consists of three layers.

---

## Tokens

Primitive values:

```text
Colors
Spacing
Typography
Radius
Shadows
```

---

## Components

Reusable primitives:

```text
Button
Input
Card
Dialog
Table
```

---

## Patterns

Composition rules:

```text
Search Form
Login Flow
Comment Editor
Article Header
```

---

# Building a Shared UI Package

```text
packages/

  ui/
    src/
      components/
        button.tsx
        card.tsx
        dialog.tsx

      index.ts
```

The critical principle:

> Expose only stable interfaces.

Your `index.ts` becomes the public API.

Consumers should never import internal implementation files directly.

---

# The Principle of Composition

Professional design systems avoid:

```text
Mega Components
```

Instead, they build:

```text
Small
Composable
Stateless
Primitives
```

Example:

```tsx
<Button variant="destructive">
```

The button does not know:

* users
* permissions
* business rules
* workflows

It only knows how to render itself.

---

# 8. GreyMatter Journal System Design Index

| Domain        | Technology          | Pattern              |
| ------------- | ------------------- | -------------------- |
| Identity      | Clerk               | Middleware Auth      |
| Content       | Sanity              | Content Lake         |
| Rendering     | Next.js             | Server Components    |
| Mutations     | Server Actions      | RPC Pattern          |
| Performance   | Next.js Cache       | ISR + Revalidation   |
| Architecture  | Feature Slices      | Vertical Ownership   |
| Design System | packages/ui         | Stateless Primitives |
| Observability | Analytics + Logging | Feedback Loops       |

---

# The Most Important Lesson

Beginners think software architecture is about:

```text
Folders
Frameworks
Patterns
Libraries
```

Professional engineers understand:

```text
Architecture
        =
Managing Human Complexity
```

A folder structure is not merely an implementation detail.

It is:

```text
A Map
        of
Understanding
```

The best architectures optimize for:

* comprehension
* ownership
* communication
* maintainability
* evolution

Because ultimately:

> Software engineering is not the art of writing code.

It is the art of building systems that humans can continue to understand.
