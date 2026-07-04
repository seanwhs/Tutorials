# Appendix B1 — Architecture & Repository Structure

> **Appendix B — Reference Implementation Appendix**
>
> ```text
> Appendix B
>     ├── Part I
>     │     Architecture & Repository Structure
>     │
>     └── Part II
>           Core Source Code Reference
> ```
>
> **Goal of this appendix:** Provide the complete reference architecture for **GreyMatter Journal**, including repository organization, architectural layers, design systems, content modeling, caching, deployment, observability, and production engineering principles. This appendix serves both as the culmination of the tutorial series and as a reusable blueprint for building modern content-driven applications.

---

# Introduction

Throughout this tutorial series, we built **GreyMatter Journal** incrementally.

What began as a simple blog evolved into a modern, production-grade content platform featuring:

```text
✓ Next.js 16 App Router
✓ React Server Components
✓ Streaming & Suspense
✓ Server Actions
✓ Sanity CMS
✓ Portable Text
✓ Image Optimization
✓ Metadata & SEO
✓ Draft Mode
✓ Authentication
✓ Search & Filtering
✓ Comments & Likes
✓ Error Boundaries
✓ Loading States
✓ Caching & Revalidation
✓ Analytics & Observability
✓ Design Tokens
✓ Theme Systems
✓ Dark Mode
✓ Production Architecture
✓ Systems Thinking
```

Although GreyMatter Journal appears to be "just a blog," architecturally it is a distributed information system.

```text
Authors
    ↓
Sanity Studio
    ↓
Content Lake
    ↓
GROQ API
    ↓
Next.js Rendering Engine
    ↓
React Component Tree
    ↓
Browser
```

Professional engineering requires understanding that applications are not merely collections of files.

```text
Application
       =
Code
       +
Data
       +
Infrastructure
       +
Caching
       +
Security
       +
Deployment
       +
Observability
       +
Human Understanding
```

This appendix documents the complete architecture.

---

# Architectural Philosophy

GreyMatter Journal follows several core engineering principles:

```text
Separation of Concerns

Composition over Inheritance

Content First

Systems Thinking

Single Responsibility

Progressive Enhancement

Production-First Architecture

Explicit Boundaries

Reliability Engineering
```

The repository is organized around responsibilities rather than convenience.

---

# The Most Important Architectural Shift

Beginners often think:

```text
Website
    =
Pages
```

Modern engineers think:

```text
Application
    =
Persistent UI Tree
    +
Data Flow Graph
    +
Distributed Infrastructure
```

This mental model explains why modern frameworks are organized around layouts, routes, data fetching, caching, and composition.

---

# Complete Repository Structure

```text
greymatter-journal/

├── app/
│
│   ├── layout.tsx
│   ├── globals.css
│   ├── loading.tsx
│   ├── error.tsx
│   ├── global-error.tsx
│   └── not-found.tsx
│
│   ├── (site)/
│   │
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │
│   │   ├── about/
│   │   │   └── page.tsx
│   │
│   │   ├── search/
│   │   │   └── page.tsx
│   │
│   │   ├── authors/
│   │   │   └── [slug]/
│   │   │       └── page.tsx
│   │
│   │   ├── categories/
│   │   │   └── [slug]/
│   │   │       └── page.tsx
│   │
│   │   └── posts/
│   │       ├── page.tsx
│   │       └── [slug]/
│   │           ├── page.tsx
│   │           ├── loading.tsx
│   │           ├── error.tsx
│   │           └── not-found.tsx
│   │
│   ├── sign-in/
│   │   └── [[...sign-in]]/
│   │       └── page.tsx
│   │
│   ├── admin/
│   │   └── page.tsx
│   │
│   └── api/
│       ├── comments/
│       │   └── route.ts
│       ├── likes/
│       │   └── route.ts
│       ├── draft/
│       │   ├── enable/
│       │   │   └── route.ts
│       │   └── disable/
│       │       └── route.ts
│       └── revalidate/
│           └── route.ts
│
├── actions/
│   ├── comments.ts
│   ├── likes.ts
│   ├── posts.ts
│   └── analytics.ts
│
├── components/
│
│   ├── layout/
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   ├── Navigation.tsx
│   │   ├── ThemeToggle.tsx
│   │   └── Container.tsx
│   │
│   ├── posts/
│   │   ├── PostCard.tsx
│   │   ├── PostList.tsx
│   │   ├── PostHero.tsx
│   │   ├── PostMeta.tsx
│   │   ├── AuthorBadge.tsx
│   │   └── CategoryBadge.tsx
│   │
│   ├── comments/
│   │   ├── CommentForm.tsx
│   │   ├── CommentList.tsx
│   │   ├── CommentCard.tsx
│   │   └── LikeButton.tsx
│   │
│   ├── portable-text/
│   │   ├── PortableTextRenderer.tsx
│   │   ├── CodeBlock.tsx
│   │   ├── ImageBlock.tsx
│   │   ├── QuoteBlock.tsx
│   │   └── CalloutBlock.tsx
│   │
│   ├── providers/
│   │   ├── ThemeProvider.tsx
│   │   ├── AnalyticsProvider.tsx
│   │   └── AuthProvider.tsx
│   │
│   └── ui/
│       ├── Button.tsx
│       ├── Card.tsx
│       ├── Badge.tsx
│       ├── Input.tsx
│       ├── Textarea.tsx
│       ├── Avatar.tsx
│       ├── Separator.tsx
│       ├── Skeleton.tsx
│       └── Spinner.tsx
│
├── hooks/
│   ├── useTheme.ts
│   ├── useLocalStorage.ts
│   ├── useAnalytics.ts
│   └── useIntersection.ts
│
├── lib/
│   ├── sanity.ts
│   ├── queries.ts
│   ├── image.ts
│   ├── auth.ts
│   ├── analytics.ts
│   ├── logger.ts
│   ├── cache.ts
│   ├── revalidate.ts
│   ├── metadata.ts
│   ├── seo.ts
│   ├── theme.ts
│   ├── env.ts
│   ├── constants.ts
│   ├── dates.ts
│   └── utils.ts
│
├── styles/
│   ├── tokens.css
│   ├── themes.css
│   ├── prose.css
│   ├── code.css
│   └── animations.css
│
├── types/
│   ├── author.ts
│   ├── category.ts
│   ├── comment.ts
│   ├── portable-text.ts
│   ├── post.ts
│   └── index.ts
│
├── studio/
│   ├── sanity.config.ts
│   ├── sanity.cli.ts
│   ├── schemaTypes/
│   └── plugins/
│
├── middleware.ts
├── next.config.ts
├── tsconfig.json
├── package.json
└── README.md
```

---

# Understanding Route Groups

Throughout this tutorial series, we used:

```text
app/
    (site)/
```

This raises an important architectural question:

> Why create folders that do not appear in the URL?

For example:

```text
app/
    (site)/
        posts/
            [slug]/
```

still produces:

```text
/posts/my-article
```

not:

```text
/site/posts/my-article
```

This is because route groups are architectural boundaries rather than URL boundaries.

For larger applications, route groups often evolve into:

```text
(marketing)
(content)
(auth)
(admin)
(api)
```

For example:

```text
app/

├── (marketing)
├── (content)
├── (auth)
└── (admin)
```

These groups allow engineers to organize systems around responsibilities rather than URLs.

GreyMatter Journal intentionally keeps:

```text
(site)
```

to maintain conceptual consistency throughout the tutorial series while introducing the architectural idea.

---

# Architectural Layer Mapping

Every file belongs to a specific architectural layer.

```text
Presentation Layer
──────────────────
app/
components/
styles/

Interaction Layer
─────────────────
actions/

Domain Layer
────────────
types/

Infrastructure Layer
────────────────────
lib/
middleware.ts

Content Layer
─────────────
studio/
```

This layering reduces coupling and allows systems to evolve safely.

---

# Presentation Architecture

The presentation layer itself contains multiple nested layers:

```text
Layout Tree
        ↓
Page Tree
        ↓
Feature Components
        ↓
UI Components
        ↓
HTML
```

Examples:

```text
Root Layout
       ↓
Site Layout
       ↓
Page
       ↓
PostCard
       ↓
Button
```

This composition model is one of React's most powerful ideas.

---

# Styling System Architecture

GreyMatter Journal uses layered styling.

```text
Design Tokens
        ↓
Themes
        ↓
Primitives
        ↓
Components
        ↓
Features
        ↓
Pages
        ↓
Content
```

This mirrors how professional design systems operate.

---

# Design Tokens

Design tokens represent visual facts.

```css
:root {
  --background: white;
  --foreground: #111827;
  --accent: #2563eb;
  --border: #e5e7eb;
  --radius: 0.75rem;
  --content-width: 75ch;
}
```

Tokens define:

```text
Color
Typography
Spacing
Radius
Shadow
Motion
Layout
```

---

# Theme Architecture

Themes override tokens.

```text
Light Theme
       ↓
Dark Theme
       ↓
Future Themes
```

Example:

```css
.dark {
  --background: #0f172a;
  --foreground: #f8fafc;
  --accent: #60a5fa;
}
```

This separation allows visual systems to evolve independently from components.

---

# Content Architecture

GreyMatter Journal models content relationally.

```text
Author
    ↑
    │
Post
    │
    ↓
Category
```

This provides:

```text
Normalization

Relationship Integrity

Single Source of Truth

Scalable Content Modeling
```

---

# Search Architecture

Search is fundamentally a data transformation problem.

```text
Content
      ↓
Filtering
      ↓
Pattern Matching
      ↓
Projection
      ↓
Sorting
      ↓
Results
```

This same architecture scales from blogs to search engines.

---

# State Transition Architecture

Modern applications are machines for transforming state.

```text
User Action
       ↓
UI State
       ↓
Optimistic Update
       ↓
Server Action
       ↓
Mutation
       ↓
Persistence
       ↓
Revalidation
       ↓
Updated UI
```

Examples include:

```text
Comments
Likes
Authentication
Draft Mode
Search
```

---

# Trust Boundary Architecture

Authentication introduced another important concept:

```text
Browser
    ↓
Authentication
    ↓
Middleware
    ↓
Server Components
    ↓
Server Actions
    ↓
CMS/API
```

Professional systems continuously answer:

```text
Who are you?

Can I trust you?

What may you access?

How certain am I?
```

---

# Caching Architecture

Modern applications do not have one cache.

They have many caches.

```text
Browser Cache
        ↓
Router Cache
        ↓
React Cache
        ↓
RSC Payload Cache
        ↓
Next.js Data Cache
        ↓
Edge Cache
        ↓
Sanity CDN
        ↓
Content Lake
```

Performance engineering is largely the discipline of managing these layers correctly.

---

# Error Recovery Architecture

Modern applications are designed around failure.

```text
loading.tsx
        ↓
error.tsx
        ↓
not-found.tsx
        ↓
global-error.tsx
```

Failures remain localized rather than catastrophic.

---

# Observability Architecture

Production systems are invisible.

Observability makes them visible.

```text
Application
      ↓
Metrics
      ↓
Logs
      ↓
Traces
      ↓
Dashboards
      ↓
Human Understanding
```

The three pillars of observability are:

```text
Metrics
Logs
Traces
```

---

# Deployment Architecture

Deployment transforms source code into a running system.

```text
Developer
      ↓
Git Repository
      ↓
CI Pipeline
      ↓
Build System
      ↓
Next.js Runtime
      ↓
Edge Network
      ↓
Cache Layer
      ↓
Sanity Content Lake
      ↓
CDN
      ↓
Browser
```

---

# GreyMatter Journal as a Distributed System

GreyMatter Journal is not merely a website.

It is a distributed system.

```text
Browser
    ↓
CDN
    ↓
Edge Network
    ↓
Next.js Runtime
    ↓
React Server Components
    ↓
Server Actions
    ↓
Sanity API
    ↓
Content Lake
    ↓
Asset CDN
```

Each layer introduces:

```text
Latency
Caching
Failure
Consistency
Security
Observability
```

---

# Systems Thinking

Beginners often see:

```text
Files
Folders
Components
Frameworks
```

Professional engineers see:

```text
Boundaries

Responsibilities

Contracts

Relationships

Flows

Constraints

Tradeoffs
```

Architecture is not the organization of files.

Architecture is the organization of complexity.

---

# The Most Important Mental Model

Beginners think:

```text
Source Code
        =
Application
```

Professional engineers think:

```text
Source Code
        =
Blueprint
```

The actual application consists of:

```text
Code
    +
Data
    +
Infrastructure
    +
Caching
    +
Security
    +
Deployment
    +
Observability
    +
Operations
    +
Human Understanding
```

GreyMatter Journal may appear to be a blog.

In reality, it is a production-grade distributed information system built using modern web engineering principles.

This appendix is not merely a folder reference.

It is a map of the system itself.
