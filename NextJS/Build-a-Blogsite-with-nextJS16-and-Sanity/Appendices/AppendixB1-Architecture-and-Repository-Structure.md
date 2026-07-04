# Appendix B1 — Architecture & Repository Structure

Appendix B is the **"Reference Implementation Appendix"**, and is split into two major sections:

```text
Appendix B
    ├── **Part I**
    │     Architecture & Repository Structure
    │
    └── Part II
          Core Source Code Reference
```

> **Goal of this appendix:** Provide the complete reference architecture for **GreyMatter Journal**, including repository organization, architectural layers, styling systems, design system foundations, production engineering patterns, and the rationale behind every major subsystem. This appendix serves as both the culmination of the tutorial series and a reusable blueprint for building modern content-driven applications.

---

# Introduction

Throughout this tutorial series, we built **GreyMatter Journal** incrementally.

What began as a simple blog evolved into a modern, production-grade distributed content platform featuring:

```text
✓ Next.js 16 App Router
✓ React Server Components
✓ Streaming & Suspense
✓ Server Actions
✓ Sanity CMS
✓ Portable Text Rendering
✓ Image Optimization
✓ Metadata & SEO
✓ Draft Mode
✓ Authentication
✓ Comments & Likes
✓ Error Boundaries
✓ Loading States
✓ Caching & Revalidation
✓ Analytics & Observability
✓ Design Tokens
✓ Theme Systems
✓ Dark Mode
✓ Design System Principles
✓ Production Architecture
✓ Systems Thinking
```

Although GreyMatter Journal appears to be "just a blog," architecturally it is a distributed information system:

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

Professional engineering requires understanding that applications are not merely collections of files:

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
```

The repository is organized around responsibilities rather than convenience.

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
│   └── not-found.tsx
│
│   ├── (site)/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │
│   │   ├── about/
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
│   ├── theme.ts
│   ├── metadata.ts
│   ├── seo.ts
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
├── public/
│   ├── logo.svg
│   ├── favicon.ico
│   ├── og-image.png
│   └── images/
│
├── studio/
│   ├── sanity.config.ts
│   ├── sanity.cli.ts
│   ├── schemaTypes/
│   │   ├── index.ts
│   │   ├── post.ts
│   │   ├── author.ts
│   │   └── category.ts
│   └── plugins/
│
├── middleware.ts
├── next.config.ts
├── tsconfig.json
├── package.json
├── postcss.config.js
├── eslint.config.mjs
├── .env.local
├── .gitignore
└── README.md
```

---

# Architectural Layer Mapping

Every file belongs to a specific architectural layer.

```text
Presentation Layer
──────────────────
app/
components/
styles/

Application Layer
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

This layering reduces coupling and allows the system to evolve safely.

---

# Styling System Architecture

GreyMatter Journal uses a layered styling model:

```text
Design Tokens
        ↓
Visual Themes
        ↓
Primitive Components
        ↓
Feature Components
        ↓
Application Composition
        ↓
Content Presentation
```

This mirrors how professional design systems operate.

---

# Design Tokens

```text
styles/tokens.css
```

Design tokens represent visual facts:

```text
Color
Spacing
Typography
Radius
Shadow
Layout
Motion
```

Example:

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

---

# Theme System

GreyMatter Journal supports multiple visual themes through CSS custom properties.

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
  --muted: #94a3b8;
  --border: #334155;
  --accent: #60a5fa;
}
```

This allows themes to evolve independently from components.

---

# Design System Architecture

The UI system follows a layered design:

```text
Tokens
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
```

Examples:

```text
Button
Card
Badge
Input
Avatar
Separator
Skeleton
Spinner
```

Feature components compose primitives rather than duplicating them.

---

# Content Architecture

GreyMatter Journal models content relationally:

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
Next.js Data Cache
        ↓
CDN Cache
        ↓
Sanity CDN
```

Performance engineering is largely the discipline of managing these layers correctly.

---

# Deployment Architecture

```text
Developer
      ↓
Git Repository
      ↓
CI/CD Pipeline
      ↓
Vercel Build
      ↓
Next.js Runtime
      ↓
React Server Components
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

# Error Recovery Architecture

Next.js provides resilience through layered recovery:

```text
loading.tsx
        ↓
error.tsx
        ↓
not-found.tsx
        ↓
global-error.tsx
```

This ensures failures remain localized rather than catastrophic.

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
Deployment
    +
Observability
    +
Human Understanding
```

GreyMatter Journal may appear to be a blog.

In reality, it is a production-grade distributed information system built using modern web engineering principles.

This appendix is not merely a folder reference.

It is a map of the system itself.
