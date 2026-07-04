# Appendix B — The Complete GreyMatter Journal Reference Architecture

> **Goal of this appendix:** Provide the complete reference architecture for **GreyMatter Journal**, including the production folder structure, design system organization, feature architecture, infrastructure layers, styling systems, and architectural reasoning behind every major subsystem.
>
> This appendix serves three purposes simultaneously:
>
> * A **source code map** for the entire GreyMatter Journal codebase
> * A **reference implementation** for future Next.js projects
> * A **systems blueprint** for understanding how modern web applications are organized

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
✓ Dynamic Routing
✓ Authentication
✓ Comments
✓ Likes
✓ Draft Mode
✓ Metadata & SEO
✓ Image Optimization
✓ Caching & Revalidation
✓ Error Boundaries
✓ Observability
✓ Analytics
✓ Design Systems
✓ Theme Architecture
✓ Dark Mode
✓ Production Deployment
```

At first glance, GreyMatter Journal appears to be a blog.

Architecturally, however, it is a distributed information system.

```text
Writers
    ↓

Sanity Studio
    ↓

Content Lake
    ↓

GROQ API
    ↓

Next.js Runtime
    ↓

React Server Components
    ↓

Design System
    ↓

Browser
    ↓

Readers
```

This appendix presents the final production architecture.

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
Observability
        +
Deployment
        +
Design Language
        +
Human Understanding
```

Software architecture is ultimately the discipline of organizing complexity.

---

# The Complete GreyMatter Journal Repository

```text
greymatter-journal/

├── app/                         # Application entry layer
│
│   ├── (site)/                 # Public website
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   │
│   │   ├── posts/
│   │   │   ├── page.tsx
│   │   │   └── [slug]/
│   │   │       ├── page.tsx
│   │   │       ├── loading.tsx
│   │   │       ├── error.tsx
│   │   │       └── not-found.tsx
│   │   │
│   │   ├── authors/
│   │   │   └── [slug]/
│   │   │
│   │   ├── categories/
│   │   │   └── [slug]/
│   │   │
│   │   ├── search/
│   │   └── about/
│   │
│   ├── (auth)/
│   │   ├── sign-in/
│   │   └── sign-up/
│   │
│   ├── (admin)/
│   │   ├── dashboard/
│   │   └── analytics/
│   │
│   ├── api/
│   │   ├── comments/
│   │   ├── likes/
│   │   ├── revalidate/
│   │   └── draft/
│   │
│   ├── globals.css
│   ├── layout.tsx
│   ├── loading.tsx
│   ├── error.tsx
│   └── not-found.tsx
│
├── features/                   # Business domains
│   │
│   ├── posts/
│   │   ├── actions/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── queries/
│   │   ├── types/
│   │   └── validation/
│   │
│   ├── comments/
│   │   ├── actions/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── types/
│   │   └── validation/
│   │
│   ├── likes/
│   │
│   ├── search/
│   │
│   └── analytics/
│
├── components/                # Shared presentation layer
│   │
│   ├── layout/
│   ├── portable-text/
│   ├── providers/
│   └── ui/
│
├── design/                    # Design system
│   │
│   ├── tokens.ts
│   ├── themes.ts
│   ├── typography.ts
│   ├── spacing.ts
│   ├── shadows.ts
│   ├── motion.ts
│   └── breakpoints.ts
│
├── actions/                   # Global server actions
│
├── hooks/
│
├── lib/                       # Infrastructure layer
│   │
│   ├── sanity.ts
│   ├── auth.ts
│   ├── cache.ts
│   ├── image.ts
│   ├── analytics.ts
│   ├── logger.ts
│   ├── telemetry.ts
│   ├── queries.ts
│   └── utils.ts
│
├── types/
│
├── public/
│
├── studio/                    # Sanity Studio
│   │
│   ├── schemaTypes/
│   ├── sanity.config.ts
│   └── package.json
│
├── middleware.ts
├── next.config.ts
├── tsconfig.json
├── postcss.config.js
└── package.json
```

---

# Architectural Layers

The folder structure is not arbitrary.

Each folder represents a layer of responsibility.

```text
Presentation Layer
        ↓
Application Layer
        ↓
Domain Layer
        ↓
Infrastructure Layer
        ↓
External Systems
```

---

## 1. Presentation Layer

```text
app/
components/
design/
```

Responsible for:

* Rendering
* Navigation
* Layouts
* Themes
* User interactions
* Visual consistency

Examples:

```text
Header
Footer
PostCard
CommentForm
LikeButton
Button
Card
Modal
```

---

## 2. Application Layer

```text
actions/
```

Responsible for:

```text
Authentication
Authorization
Orchestration
State transitions
Workflows
```

Example:

```text
Submit Comment
      ↓
Validate
      ↓
Authenticate
      ↓
Persist
      ↓
Revalidate
      ↓
Return Result
```

---

## 3. Domain Layer

```text
features/
```

Responsible for business rules.

Example:

```text
features/posts/

components/
actions/
hooks/
queries/
types/
validation/
```

Humans think in terms of:

```text
Posts
Comments
Likes
Search
Analytics
```

not:

```text
tsx
ts
css
json
```

---

## 4. Infrastructure Layer

```text
lib/
```

Responsible for:

```text
Sanity
Authentication
Caching
Logging
Analytics
Telemetry
Image Processing
```

Rule:

```text
Business Logic
        ≠
lib/

Infrastructure
        =
lib/
```

---

# Design System Architecture

One of the biggest architectural shifts in modern frontend engineering is realizing:

```text
Styling
      ≠
Design System
```

Instead:

```text
Design Tokens
        ↓
Themes
        ↓
Components
        ↓
Patterns
        ↓
Applications
```

---

## Design Tokens

```text
design/

tokens.ts
spacing.ts
typography.ts
motion.ts
shadows.ts
```

Example:

```typescript
export const spacing = {
  xs: "0.25rem",
  sm: "0.5rem",
  md: "1rem",
  lg: "2rem",
};
```

---

## Theme System

```text
design/themes.ts
```

Example:

```typescript
export const lightTheme = {
  background: "#ffffff",
  foreground: "#111827",
};

export const darkTheme = {
  background: "#111827",
  foreground: "#ffffff",
};
```

---

## Dark Mode Architecture

```text
User Preference
        ↓
Theme Provider
        ↓
CSS Variables
        ↓
Tailwind Utilities
        ↓
Components
```

Example:

```tsx
<html
  suppressHydrationWarning
>
  <body className="
    bg-background
    text-foreground
  ">
```

---

# Content Architecture

GreyMatter Journal is fundamentally a content system.

```text
Author
    ↑
    │
Post
    │
    ↓
Category
```

The guiding principle:

```text
Content Model
        >
Page Model
```

---

# Caching Architecture

Modern applications do not have one cache.

They have multiple caches.

```text
Browser Cache
       ↓
Router Cache
       ↓
React Cache
       ↓
Next.js Data Cache
       ↓
CDN Cache
       ↓
Origin
```

---

# Observability Architecture

Production systems require visibility.

```text
User Request
       ↓
Logging
       ↓
Tracing
       ↓
Metrics
       ↓
Alerts
```

Tools:

```text
Vercel Analytics
Speed Insights
OpenTelemetry
Structured Logging
```

---

# Shared UI Components

```text
components/ui/

button.tsx
card.tsx
badge.tsx
input.tsx
textarea.tsx
modal.tsx
dropdown.tsx
avatar.tsx
```

Principle:

```text
Components
      =
Stateless Primitives
```

Never:

```text
Mega Components
```

Always:

```text
Composable Components
```

---

# The GreyMatter Journal Runtime

When a reader visits:

```text
/posts/understanding-nextjs
```

the actual system flow is:

```text
Browser
    ↓

App Router
    ↓

Route Matching
    ↓

React Server Components
    ↓

Sanity Query
    ↓

Content Lake
    ↓

Cache Layer
    ↓

Portable Text Renderer
    ↓

Design System
    ↓

HTML Stream
    ↓

Browser
```

---

# Design Philosophy

GreyMatter Journal intentionally prioritizes:

```text
Readability
Maintainability
Accessibility
Performance
Simplicity
Consistency
```

rather than:

```text
Animations
Visual Effects
Novelty
Complexity
Decoration
```

Because ultimately:

```text
Content
      >
Decoration
```

---

# The Final Architecture

```text
Writers
    ↓

Sanity Studio
    ↓

Content Lake
    ↓

GROQ API
    ↓

Next.js App Router
    ↓

React Server Components
    ↓

Server Actions
    ↓

Caching Layer
    ↓

Design System
    ↓

Browser
    ↓

Readers
```

---

# The Final Mental Model

Beginners think:

```text
Folder Structure
        =
Organization
```

Professional engineers think:

```text
Folder Structure
        =
Architecture
        =
Communication
        =
Knowledge Boundaries
```

GreyMatter Journal may appear to be a blog.

In reality, it is:

```text
A distributed
content platform

+

A design system

+

A cache hierarchy

+

A deployment system

+

An observability system

+

A human coordination system
```

This appendix is not merely a reference for files.

It is a map of how modern software systems are organized so that both machines and humans can evolve them safely over time.
