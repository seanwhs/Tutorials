# Architecture Document

## Personal Portfolio Website (Next.js 16)

---

### Document Control

| **Field** | **Value** |
|-----------|-----------|
| **Document Title** | Architecture Document — Personal Portfolio Website |
| **Version** | 1.0 |
| **Date** | 2026-06-28 |
| **Author** | Sean Wong |
| **Status** | Final |

---

## Table of Contents

1. [Overview](#1-overview)
2. [System Architecture](#2-system-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Component Architecture](#4-component-architecture)
5. [Data Architecture](#5-data-architecture)
6. [Caching & Revalidation (Next.js 16)](#6-caching--revalidation-nextjs-16)
7. [Proxy & Request Interception](#7-proxy--request-interception)
8. [Deployment Architecture](#8-deployment-architecture)
9. [Security Architecture](#9-security-architecture)
10. [Performance Architecture](#10-performance-architecture)
11. [Scalability & Future Considerations](#11-scalability--future-considerations)

---

## 1. Overview

### 1.1 Purpose

This document describes the architecture of the Personal Portfolio Website — a statically optimized, content-managed web application that bridges a Vercel-hosted Next.js 16 frontend with a Sanity CMS backend using explicit caching, tag-based invalidation, and the App Router's Server Component model.

### 1.2 Architecture Principles

| **Principle** | **Description** |
|---------------|-----------------|
| **Static First** | Pages and components are precomputed and cached where appropriate via explicit cache directives for predictable performance. |
| **Content Decoupling** | Sanity stores content; the frontend owns presentation and caching rules. |
| **Edge-Optimized** | Assets and cached responses are served from Vercel's global edge network. |
| **Explicit Invalidation** | Use cache tags and `revalidateTag` / `updateTag` for targeted refreshes rather than implicit ISR behavior. |
| **Type Safety** | TypeScript is used across the stack for compile-time correctness. |

### 1.3 Key Next.js 16 Changes

Next.js 16 introduces significant changes from Next.js 14:

| Feature | Next.js 14 | Next.js 16 |
|---------|-----------|------------|
| Caching | Implicit (`export const revalidate = 60`) | Explicit (`'use cache'` directive) |
| Invalidation | `revalidatePath` | `revalidateTag(tag, profile)` / `updateTag` |
| Middleware | `middleware.ts` | `proxy.ts` |
| Control | Framework decides caching | Developer explicitly opts in |

> **Reference**: [Next.js 16 Announcement](https://nextjs.org/blog/next-16), [Cache API Reference](https://nextjs.org/docs/app/api-reference/functions/revalidateTag)

---

## 2. System Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        Browser (Visitor)                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │   │
│  │  │   Chrome    │  │   Firefox   │  │   Safari / Edge / Mobile │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼ HTTPS
┌─────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      Vercel Edge Network                         │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │              Next.js 16 Application (App Router)         │    │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │    │   │
│  │  │  │   Pages     │  │  Components │  │   Assets    │    │    │   │
│  │  │  │  (RSC/SSC)  │  │  (React)    │  │  (Images)   │    │    │   │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘    │    │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │    │   │
│  │  │  │  API Routes │  │  Data Cache │  │   proxy.ts   │    │    │   │
│  │  │  │  (Handlers) │  │  (Explicit) │  │  (Edge)     │    │    │   │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘    │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼ HTTPS / API
┌─────────────────────────────────────────────────────────────────────────┐
│                           CONTENT LAYER                                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                         Sanity CMS                               │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │   │
│  │  │  Content API │  │  Image CDN  │  │     Sanity Studio      │  │   │
│  │  │  (GROQ)      │  │  (Hotspot)  │  │  (Content Management)  │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼ Webhook
┌─────────────────────────────────────────────────────────────────────────┐
│                         INTEGRATION LAYER                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │              Vercel Revalidation API Route                      │   │
│  │              (/api/revalidate) — uses revalidateTag               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Architecture Pattern

The system follows the **JAMstack architecture** with **Headless CMS** and **explicit caching**:

- **J**avaScript: Next.js 16 (React)
- **A**PIs: Sanity Content API (GROQ)
- **M**arkup: Static HTML generated at build time or cached via `'use cache'`

**Key Characteristics:**
- Content is authored in Sanity Studio and stored in Sanity's cloud datastore
- Next.js 16 fetches content via cached Server Component functions with `'use cache'`
- Vercel serves pre-built pages and cached data from edge locations globally
- Content updates trigger `revalidateTag` for precise, targeted cache invalidation

> **Reference**: [Next.js 16 Features](https://strapi.io/blog/next-js-16-features)

---

## 3. Technology Stack

### 3.1 Frontend

| **Layer** | **Technology** | **Purpose** |
|-----------|----------------|-------------|
| Framework | Next.js 16 (App Router) | Server Components, streaming, explicit caching, `proxy.ts` |
| Language | TypeScript | Type safety and developer experience |
| Styling | Tailwind CSS | Utility-first CSS framework |
| UI Components | React + shadcn/ui (optional) | Component library |
| Animation | Framer Motion (optional) | Page transitions and micro-interactions |
| Icons | Lucide React | Consistent icon system |
| Fonts | `next/font` | Self-hosted, subsetted fonts |

> **Reference**: [Next.js 16 App Router](https://nextjs.org/blog/next-16)

### 3.2 Backend / CMS

| **Layer** | **Technology** | **Purpose** |
|-----------|----------------|-------------|
| CMS Platform | Sanity.io | Headless content management |
| Query Language | GROQ | Content fetching from Sanity |
| Image Pipeline | Sanity Image URL Builder | On-demand image transformation |
| Rich Text | Portable Text | Structured content format |
| Studio | Sanity Studio | Content authoring interface |

### 3.3 Infrastructure

| **Layer** | **Technology** | **Purpose** |
|-----------|----------------|-------------|
| Hosting | Vercel | Edge deployment and serverless functions |
| CDN | Vercel Edge Network | Global static asset delivery |
| Image CDN | Sanity Image CDN | Image optimization and delivery |
| CI/CD | GitHub → Vercel | Automatic deployments on push |
| Analytics | Vercel Analytics (optional) | Web vitals and performance monitoring |

### 3.4 Third-Party Services

| **Service** | **Purpose** | **Integration** |
|-------------|-------------|-----------------|
| Resend / SendGrid / Formspree | Contact form email delivery | API Route handler |
| Sanity Webhooks | Instant content revalidation | POST to `/api/revalidate` with tag payload |

---

## 4. Component Architecture

### 4.1 Directory Structure

```
portfolio-website/
├── app/                          # Next.js 16 App Router
│   ├── (routes)/                 # Route groups
│   │   ├── page.tsx              # Home page (route: /)
│   │   ├── about/
│   │   │   └── page.tsx          # About page
│   │   ├── projects/
│   │   │   └── page.tsx          # Projects listing
│   │   ├── blog/
│   │   │   ├── page.tsx          # Blog listing (cached via 'use cache')
│   │   │   └── [slug]/
│   │   │       └── page.tsx      # Individual blog post (cached via 'use cache')
│   │   └── contact/
│   │       └── page.tsx          # Contact page
│   ├── api/
│   │   └── revalidate/
│   │       └── route.ts          # Tag invalidation handler
│   ├── proxy.ts                  # Request interception (replaces middleware.ts)
│   ├── layout.tsx                # Root layout (metadata, providers)
│   └── globals.css               # Global styles
│
├── components/                   # Reusable React components
│   ├── ui/                       # Primitive UI components (Button, Card, Badge)
│   ├── layout/                   # Layout components (Navbar, Footer, Container)
│   └── sections/                 # Page section components (Hero, ProjectsGrid, BlogList)
│
├── lib/                          # Utility libraries
│   ├── sanity.ts                 # Sanity client configuration
│   ├── sanity-image.ts           # Image URL builder utilities
│   ├── groq-queries.ts           # GROQ query definitions
│   ├── loadPosts.ts              # Cached data loaders ('use cache')
│   └── utils.ts                  # General utilities (cn, formatDate, etc.)
│
├── types/                        # TypeScript type definitions
│   ├── sanity.ts                 # Sanity-generated types
│   └── index.ts                  # Application types
│
├── public/                       # Static assets
│   ├── images/                   # Local images (fallbacks, logos)
│   └── resume.pdf                # Downloadable resume
│
├── sanity.config.ts              # Sanity Studio configuration (if embedded)
├── next.config.ts                # Next.js 16 configuration
├── tailwind.config.ts            # Tailwind CSS configuration
└── tsconfig.json                 # TypeScript configuration
```

### 4.2 Component Hierarchy

```
┌─────────────────────────────────────────┐
│           RootLayout                      │
│  (Metadata, ThemeProvider, FontProvider) │
└─────────────────────────────────────────┘
                    │
        ┌──────────┴──────────┐
        ▼                     ▼
┌──────────────┐      ┌──────────────┐
│   Navbar     │      │    Footer    │
│  (Sticky)    │      │  (Socials)   │
└──────────────┘      └──────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│              Page Content               │
│  (Server Component by default)           │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│           Section Components              │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
│  │  Hero   │ │ Projects│ │  Blog    │  │
│  │Section  │ │ Grid    │ │ Listing  │  │
│  └─────────┘ └─────────┘ └──────────┘  │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
│  │  About  │ │ Contact │ │  Skills  │  │
│  │Section  │ │ Form    │ │  List    │  │
│  └─────────┘ └─────────┘ └──────────┘  │
└─────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────┐
│            UI Primitives                │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
│  │ Button  │ │  Card   │ │  Badge   │  │
│  └─────────┘ └─────────┘ └──────────┘  │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
│  │  Input  │ │  Image  │ │  Link    │  │
│  └─────────┘ └─────────┘ └──────────┘  │
└─────────────────────────────────────────┘
```

### 4.3 Rendering Strategy by Route

| **Route** | **Strategy** | **Caching** | **Rationale** |
|-----------|--------------|-------------|---------------|
| `/` (Home) | Static | `'use cache'` in data loaders | Content rarely changes; explicit cache control |
| `/about` | Static | `'use cache'` in data loaders | Content rarely changes |
| `/projects` | Static | `'use cache'` with `cacheTag('projects')` | Content may be updated via Sanity |
| `/blog` | Server Component | `'use cache'` with `cacheTag('posts')` | Content changes; invalidate via tag |
| `/blog/[slug]` | Server Component | `'use cache'` with `cacheTag('posts')` and `cacheTag('post:{slug}')` | Individual post invalidation |
| `/contact` | Static | None needed | Form is client-side; page is static |
| `/api/revalidate` | Serverless Function | None | Webhook endpoint for tag invalidation |

> **Note**: Next.js 16 removes `export const revalidate`. Caching is controlled entirely through `'use cache'` directives and `cacheTag` / `revalidateTag` APIs.

> **Reference**: [Next.js 16 Directives](https://nextjs.org/docs/app/api-reference/directives)

---

## 5. Data Architecture

### 5.1 Data Flow Diagram

```
[Sanity Studio] --(publishes)--> [Sanity Cloud]
                                      │
                                      │ GROQ Query (HTTPS)
                                      ▼
┌─────────────────────────────────────────┐
│         Next.js 16 Build / Runtime       │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Build Time (SSG)               │   │
│  │  • fetch all posts from Sanity  │   │
│  │  • generate static HTML pages   │   │
│  │  • cache with 'use cache'       │   │
│  └─────────────────────────────────┘   │
│              OR                        │
│  ┌─────────────────────────────────┐   │
│  │  Runtime (Explicit Cache)       │   │
│  │  • visitor requests /blog        │   │
│  │  • serve from cache if fresh     │   │
│  │  • revalidateTag clears stale     │   │
│  │    cache on Sanity webhook        │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  Vercel Edge    │
│  (Serve HTML)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Visitor Browser │
│ (React hydrates)│
└─────────────────┘
```

### 5.2 Content Model (Sanity Schemas)

```
┌─────────────────────────────────────────┐
│           blogPost (Document)            │
├─────────────────────────────────────────┤
│ _id: string (auto)                      │
│ _type: "blogPost"                       │
│ title: string        [required]         │
│ slug: slug           [required]         │
│ publishedAt: datetime [required]        │
│ excerpt: text                           │
│ coverImage: image (hotspot)             │
│ content: array(block | image | code)    │
│ tags: array(string)                     │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│           project (Document)            │
├─────────────────────────────────────────┤
│ _id: string (auto)                      │
│ _type: "project"                        │
│ title: string        [required]         │
│ slug: slug           [required]         │
│ description: text                       │
│ thumbnail: image (hotspot)              │
│ liveUrl: url                            │
│ repoUrl: url                            │
│ techStack: array(string)                │
│ featured: boolean                       │
│ completedAt: date                       │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│           author (Document)             │
├─────────────────────────────────────────┤
│ _id: string (auto)                      │
│ _type: "author"                         │
│ name: string                            │
│ bio: text                               │
│ avatar: image                           │
│ email: string                           │
│ socials: array({platform, url})       │
│ resume: file                            │
└─────────────────────────────────────────┘
```

### 5.3 GROQ Query Architecture

```typescript
// lib/groq-queries.ts

// Blog listing: all published posts, newest first
export const allPostsQuery = groq`
  *[_type == "blogPost" && publishedAt < now()] | order(publishedAt desc) {
    _id,
    title,
    "slug": slug.current,
    publishedAt,
    excerpt,
    coverImage,
    tags
  }
`;

// Single post: full content with resolved image references
export const postBySlugQuery = groq`
  *[_type == "blogPost" && slug.current == $slug][0] {
    _id,
    title,
    "slug": slug.current,
    publishedAt,
    excerpt,
    coverImage,
    tags,
    content
  }
`;

// Related posts: same tags, excluding current
export const relatedPostsQuery = groq`
  *[_type == "blogPost" && slug.current != $slug && count(tags[@ in $tags]) > 0]
  | order(publishedAt desc)[0...3] {
    _id,
    title,
    "slug": slug.current,
    publishedAt,
    excerpt,
    coverImage
  }
`;
```

### 5.4 Cached Data Loaders

```typescript
// lib/loadPosts.ts
import { cacheTag } from "next/cache";
import client from "./sanity";
import { allPostsQuery, postBySlugQuery } from "./groq-queries";

export async function loadPosts() {
  "use cache";
  cacheTag("posts");

  const posts = await client.fetch(allPostsQuery);
  return posts;
}

export async function loadPostBySlug(slug: string) {
  "use cache";
  cacheTag(`post:${slug}`);
  cacheTag("posts");

  const post = await client.fetch(postBySlugQuery, { slug });
  return post;
}
```

> **Reference**: [Cache Components & revalidateTag](https://www.rabinarayanpatra.com/snippets/nextjs/cache-components-revalidate-tag)

---

## 6. Caching & Revalidation (Next.js 16)

### 6.1 Caching Model Summary

Next.js 16 is **explicit** — nothing is cached unless you opt-in with `'use cache'` or pass `next: { tags: [...] }` to fetch. Tag-based invalidation via `revalidateTag` / `updateTag` gives precise control over cache lifetime.

> **Reference**: [Next.js 16 Caching](https://www.youtube.com/watch?v=RAVL4-0PkmE)

### 6.2 Cache Layers and Responsibilities

| **Cache Layer** | **Scope** | **Control** | **Invalidation** |
|-----------------|-----------|-------------|------------------|
| Vercel Edge Cache | Static assets and deployed output | Deployment | Full redeploy |
| Next.js Data Cache | Cached Server Components / functions | `'use cache'`, `cacheTag` | `revalidateTag(tag, profile)` |
| Sanity CDN | API responses and image delivery | Sanity-managed | Automatic |
| Browser Cache | Static assets | Hash in filename | Filename change |
| Image Cache | Optimized images | URL-based | URL change |

### 6.3 Explicit Caching Patterns

#### Pattern 1: Basic Cached Function

```typescript
import { cacheTag } from "next/cache";

export async function loadPosts() {
  "use cache";
  cacheTag("posts");

  // fetch from Sanity...
  const posts = await client.fetch(allPostsQuery);
  return posts;
}
```

#### Pattern 2: Multiple Tags for Granular Invalidation

```typescript
export async function loadPostBySlug(slug: string) {
  "use cache";
  cacheTag(`post:${slug}`);   // Individual post tag
  cacheTag("posts");           // All posts tag

  const post = await client.fetch(postBySlugQuery, { slug });
  return post;
}
```

#### Pattern 3: Revalidation via Route Handler

```typescript
// app/api/revalidate/route.ts
import { revalidateTag } from "next/cache";
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  const secret = request.headers.get("x-sanity-webhook-secret");

  if (secret !== process.env.SANITY_WEBHOOK_SECRET) {
    return NextResponse.json({ message: "Invalid secret" }, { status: 401 });
  }

  const body = await request.json();
  const { _type, slug } = body;

  if (_type === "blogPost") {
    revalidateTag("posts", "max");
    if (slug?.current) {
      revalidateTag(`post:${slug.current}`, "max");
    }
    return NextResponse.json({ revalidated: true });
  }

  return NextResponse.json({ message: "Unknown type" }, { status: 400 });
}
```

> **Reference**: [revalidateTag API](https://nextjs.org/docs/app/api-reference/functions/revalidateTag)

### 6.4 Cache Invalidation Strategies

| **Strategy** | **Use Case** | **API** |
|--------------|--------------|---------|
| **Invalidate all posts** | New post published, post deleted | `revalidateTag('posts', 'max')` |
| **Invalidate single post** | Post updated | `revalidateTag('post:slug', 'max')` |
| **Update without clearing** | Replace cached value immediately | `updateTag('posts', newData)` |
| **Stale-while-revalidate** | Serve stale, refresh in background | `revalidateTag('posts')` |

> **Reference**: [Advanced Cache Management](https://dev.to/mericcintosun/advanced-cache-management-in-nextjs-16-updatetag-and-revalidatetag-50j2)

### 6.5 Comparison: Next.js 14 ISR vs Next.js 16 Explicit Caching

| **Aspect** | **Next.js 14 (ISR)** | **Next.js 16 (Explicit)** |
|------------|----------------------|---------------------------|
| Opt-in | `export const revalidate = 60` | `'use cache'` directive |
| Invalidation | `revalidatePath('/blog')` | `revalidateTag('posts', 'max')` |
| Granularity | Page-level | Tag-level (any granularity) |
| Control | Framework-managed | Developer-managed |
| Predictability | Implicit behavior | Explicit, traceable |

---

## 7. Proxy & Request Interception

### 7.1 `proxy.ts` Replaces `middleware.ts`

In Next.js 16, `proxy.ts` replaces `middleware.ts` for global request interception.

```typescript
// app/proxy.ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export default async function proxy(req: NextRequest) {
  // Example: Redirect unauthenticated admin routes
  if (req.nextUrl.pathname.startsWith("/admin")) {
    const token = req.cookies.get("session");
    if (!token) {
      return NextResponse.redirect(new URL("/login", req.url));
    }
  }

  // Example: Add security headers to all responses
  const response = NextResponse.next();
  response.headers.set("X-Frame-Options", "DENY");
  response.headers.set("X-Content-Type-Options", "nosniff");

  return response;
}

export const config = {
  matcher: ["/admin/:path*", "/api/:path*", "/blog/:path*"],
};
```

### 7.2 Proxy Design Principles

| **Principle** | **Guideline** |
|---------------|---------------|
| **Keep it minimal** | Heavy logic belongs in Route Handlers or Server Actions |
| **Focus on routing** | URL rewrites, redirects, auth gating |
| **Header hygiene** | Security headers, CORS handling |
| **Cookie management** | Session validation, auth token refresh |

> **Reference**: [Next.js 16 proxy.ts vs middleware.ts](https://johnkavanagh.co.uk/articles/next-js-proxy-replaces-middleware/), [BFF Guide](https://u11d.com/blog/nextjs-16-proxy-vs-middleware-bff-guide/)

---

## 8. Deployment Architecture

### 8.1 Vercel Deployment Pipeline

```
┌─────────────────┐
│   Git Push      │
│   (main branch) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  GitHub Actions │
│  (CI Pipeline)  │
│  • Lint         │
│  • Type Check   │
│  • Build Test   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Vercel Build   │
│  • npm install  │
│  • next build   │
│  • Turbopack    │
│  • Cache warm   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Vercel Deploy  │
│  • Atomic       │
│  • Zero-downtime│
│  • Global edge  │
└─────────────────┘
```

### 8.2 Environment Configuration

| **Environment** | **Purpose** | **Dataset** | `useCdn` | Caching |
|-----------------|-------------|-------------|----------|---------|
| **Development** | Local development | `development` | `false` | Minimal / none |
| **Preview** | PR deployments | `development` | `true` | `'use cache'` with short profiles |
| **Production** | Live site | `production` | `true` | `'use cache'` with long profiles |

### 8.3 Domain & Routing

```
┌─────────────────────────────────────────┐
│           Domain: yourname.dev          │
│           (or custom domain)            │
├─────────────────────────────────────────┤
│  /           →  Home page               │
│  /about      →  About page              │
│  /projects   →  Projects listing        │
│  /blog       →  Blog listing (cached)   │
│  /blog/[slug]→  Blog post (cached)      │
│  /contact    →  Contact page            │
│  /api/*      →  Serverless functions    │
│  /proxy      →  Request interception    │
└─────────────────────────────────────────┘
```

---

## 9. Security Architecture

### 9.1 Threat Model

| **Threat** | **Mitigation** |
|------------|----------------|
| API token exposure | Store in Vercel env vars; never commit to Git |
| XSS attacks | React's automatic escaping; sanitize Portable Text |
| CSRF on contact form | Implement CSRF tokens or use service with built-in protection |
| Webhook spoofing | Validate Sanity webhook signature before calling `revalidateTag` |
| Content injection | Sanity validates schema; only approved fields are rendered |
| Image abuse | Use Sanity Image CDN with signed URLs (optional) |

### 9.2 Security Layers

```
┌─────────────────────────────────────────┐
│  Layer 1: DNS / HTTPS                   │
│  • Vercel-managed SSL certificate       │
│  • HSTS headers                         │
├─────────────────────────────────────────┤
│  Layer 2: Edge / CDN                    │
│  • DDoS protection (Vercel)           │
│  • Rate limiting on API routes          │
├─────────────────────────────────────────┤
│  Layer 3: Application                   │
│  • Content Security Policy (CSP)        │
│  • Secure headers (via proxy.ts)        │
│  • Input validation on contact form     │
├─────────────────────────────────────────┤
│  Layer 4: API / Data                    │
│  • Authenticated Sanity API requests    │
│  • Webhook signature verification       │
│  • Principle of least privilege         │
└─────────────────────────────────────────┘
```

### 9.3 Environment Variable Security

| **Variable** | **Client-Side?** | **Storage** | **Used For** |
|--------------|------------------|-------------|--------------|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | Yes | Vercel env (build-time) | Sanity client config |
| `NEXT_PUBLIC_SANITY_DATASET` | Yes | Vercel env (build-time) | Dataset selection |
| `NEXT_PUBLIC_SANITY_API_VERSION` | Yes | Vercel env (build-time) | API stability |
| `SANITY_API_TOKEN` | **No** | Vercel env (server-only) | Authenticated API reads |
| `SANITY_WEBHOOK_SECRET` | **No** | Vercel env (server-only) | Webhook validation |
| `EMAIL_API_KEY` | **No** | Vercel env (server-only) | Contact form delivery |

---

## 10. Performance Architecture

### 10.1 Performance Budget

| **Metric** | **Target** | **Measurement** |
|------------|------------|-----------------|
| First Contentful Paint (FCP) | < 1.0s | Lighthouse |
| Largest Contentful Paint (LCP) | < 2.5s | Lighthouse |
| Time to Interactive (TTI) | < 3.8s | Lighthouse |
| Cumulative Layout Shift (CLS) | < 0.1 | Lighthouse |
| Total Blocking Time (TBT) | < 200ms | Lighthouse |
| Lighthouse Performance Score | ≥ 90 | Lighthouse |

### 10.2 Optimization Strategies

| **Strategy** | **Implementation** |
|--------------|--------------------|
| **Server Components** | Default to Server Components; use `'use cache'` for expensive reads |
| **Explicit Caching** | Cache stable data with `'use cache'` and `cacheTag` |
| **Image Optimization** | `next/image` + Sanity Image CDN (WebP/AVIF) |
| **Font Optimization** | `next/font` for self-hosted, subsetted fonts |
| **Code Splitting** | Automatic route-based splitting by Next.js 16 |
| **Prefetching** | `<Link prefetch>` for anticipated navigation |
| **Edge Caching** | Vercel's global edge network for static assets |
| **Streaming** | React Server Components for partial hydration |

### 10.3 Image Pipeline

```
[Sanity Asset] ──► [Sanity Image CDN] ──► [next/image] ──► [Browser]
                        │                      │
                        ▼                      ▼
                ┌──────────────┐      ┌──────────────┐
                │  Auto-format │      │  Responsive  │
                │  (WebP/AVIF) │      │  srcset      │
                │  Quality opt │      │  Lazy loading│
                │  Hotspot crop│      │  Blur placeholder│
                └──────────────┘      └──────────────┘
```

---

## 11. Scalability & Future Considerations

### 11.1 Current Scale Assumptions

| **Metric** | **Assumed Scale** | **Architecture Support** |
|------------|-------------------|--------------------------|
| Blog posts | < 500 | Explicit caching scales linearly |
| Monthly visitors | < 50,000 | Vercel edge + cache tags |
| Concurrent visitors | < 1,000 | Edge caching + Server Components |
| Images | < 5,000 | Sanity Image CDN |

### 11.2 Future Extension Points

| **Feature** | **Architecture Approach** |
|-------------|---------------------------|
| **Search** | Add Algolia or Fuse.js client-side search |
| **Comments** | Integrate Giscus (GitHub Discussions) or Disqus |
| **Newsletter** | Add ConvertKit / Mailchimp signup form |
| **Analytics** | Vercel Analytics + Plausible (privacy-focused) |
| **Multi-language** | i18n routing + Sanity localized fields |
| **RSS Feed** | Dynamic API route generating XML |
| **Sitemap** | Dynamic API route generating sitemap.xml |
| **Open Graph Images** | `@vercel/og` with cached dynamic generation |

### 11.3 Migration Considerations

| **Scenario** | **Approach** |
|--------------|--------------|
| Migrate to different CMS | Abstract data layer in `lib/cms.ts`; swap adapter |
| Migrate from Next.js 16 | Export static build; host on any static CDN |
| Add server-side features | Upgrade to Vercel Pro for longer function timeouts |
| Downgrade to Next.js 14 | Replace `'use cache'` with `export const revalidate` |

---

## Appendix A: Decision Log

| **Decision** | **Rationale** | **Date** |
|--------------|---------------|----------|
| Next.js 16 App Router | Explicit caching, `proxy.ts`, Cache Components model | 2026-06-28 |
| `'use cache'` over ISR | Developer-controlled, predictable, tag-based invalidation | 2026-06-28 |
| `proxy.ts` over `middleware.ts` | Next.js 16 standard for request interception | 2026-06-28 |
| Sanity over Strapi/Contentful | Developer experience, GROQ flexibility, generous free tier | 2026-06-28 |
| Vercel over Netlify | First-class Next.js 16 support, Turbopack, edge caching | 2026-06-28 |
| Tailwind over CSS Modules | Rapid development, design system consistency | 2026-06-28 |
| TypeScript over JavaScript | Type safety, IDE autocomplete, fewer runtime bugs | 2026-06-28 |

## Appendix B: Glossary

| **Term** | **Definition** |
|----------|----------------|
| **App Router** | Next.js 13+ router using Server Components; Next.js 16 builds on it with Cache Components |
| **cacheTag** | Registers a cache entry with a tag for later invalidation |
| **revalidateTag** | Invalidates all cached entries matching a given tag |
| **updateTag** | Replaces cached data for a tag without clearing the cache |
| **proxy.ts** | Next.js 16 replacement for `middleware.ts` for request interception |
| **'use cache'** | File/function-level directive that opts a server function into caching |
| **GROQ** | Graph-Relational Object Queries — Sanity's query language |
| **Portable Text** | Sanity's structured rich text format (JSON-based) |
| **RSC** | React Server Component — renders on server, zero client JS |

## Appendix C: Example Code Patterns

### Cached Data Loader

```typescript
// lib/loadPosts.ts
import { cacheTag } from "next/cache";
import client from "./sanity";
import { allPostsQuery } from "./groq-queries";

export async function loadPosts() {
  "use cache";
  cacheTag("posts");

  const res = await client.fetch(allPostsQuery);
  return res;
}
```

### Revalidation Route Handler

```typescript
// app/api/revalidate/route.ts
import { revalidateTag } from "next/cache";
import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  const secret = req.headers.get("x-sanity-webhook-secret");

  if (secret !== process.env.SANITY_WEBHOOK_SECRET) {
    return NextResponse.json({ ok: false }, { status: 401 });
  }

  const { tag } = await req.json();
  if (!tag) {
    return NextResponse.json({ ok: false, message: "missing tag" }, { status: 400 });
  }

  revalidateTag(tag, "max");
  return NextResponse.json({ revalidated: true });
}
```

### Proxy Configuration

```typescript
// app/proxy.ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export default async function proxy(req: NextRequest) {
  if (req.nextUrl.pathname.startsWith("/admin")) {
    const token = req.cookies.get("session");
    if (!token) return NextResponse.redirect("/login");
  }
  return NextResponse.next();
}

export const config = { matcher: ["/admin/:path*", "/api/:path*"] };
```

---

## Appendix D: References

- [Next.js 16 Announcement](https://nextjs.org/blog/next-16)
- [Next.js Cache API Reference](https://nextjs.org/docs/app/api-reference/functions/revalidateTag)
- [Next.js Directives](https://nextjs.org/docs/app/api-reference/directives)
- [proxy.ts vs middleware.ts](https://johnkavanagh.co.uk/articles/next-js-proxy-replaces-middleware/)
- [BFF Guide with proxy.ts](https://u11d.com/blog/nextjs-16-proxy-vs-middleware-bff-guide/)
- [Cache Components & revalidateTag](https://www.rabinarayanpatra.com/snippets/nextjs/cache-components-revalidate-tag)
- [Advanced Cache Management](https://dev.to/mericcintosun/advanced-cache-management-in-nextjs-16-updatetag-and-revalidatetag-50j2)

---

This architecture document serves as the definitive technical blueprint for your personal portfolio website using Next.js 16, connecting your Vercel-hosted frontend with your Sanity CMS backend through explicit, developer-controlled caching.
