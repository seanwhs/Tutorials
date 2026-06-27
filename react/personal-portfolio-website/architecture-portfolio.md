# Architecture Document

## Personal Portfolio Website

---

### Document Control

| **Field** | **Value** |
|-----------|-----------|
| **Document Title** | Architecture Document — Personal Portfolio Website |
| **Version** | 1.0 |
| **Date** | 2026-06-28 |
| **Author** | [Your Name] |
| **Status** | Final |

---

## Table of Contents

1. [Overview](#1-overview)
2. [System Architecture](#2-system-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Component Architecture](#4-component-architecture)
5. [Data Architecture](#5-data-architecture)
6. [Deployment Architecture](#6-deployment-architecture)
7. [Security Architecture](#7-security-architecture)
8. [Performance Architecture](#8-performance-architecture)
9. [Scalability & Future Considerations](#9-scalability--future-considerations)

---

## 1. Overview

### 1.1 Purpose

This document describes the architecture of the Personal Portfolio Website — a statically-generated, content-managed web application that serves as the central online presence for the portfolio owner. It bridges the Vercel-hosted frontend (built in the first tutorial) with the Sanity CMS backend (configured in the second tutorial).

### 1.2 Architecture Principles

| **Principle** | **Description** |
|---------------|-----------------|
| **Static First** | Pages are pre-rendered at build time for maximum performance and reliability |
| **Content Decoupling** | Content lives in Sanity CMS; presentation logic lives in the frontend |
| **Edge-Optimized** | Assets and pages are served from Vercel's global edge network |
| **Incremental Updates** | Content changes trigger targeted revalidation rather than full rebuilds |
| **Type Safety** | TypeScript is used throughout for compile-time correctness |

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
│  │  │              Next.js Application (App Router)            │    │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │    │   │
│  │  │  │   Pages     │  │  Components │  │   Assets    │    │    │   │
│  │  │  │  (RSC/SSC)  │  │  (React)    │  │  (Images)   │    │    │   │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘    │    │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │    │   │
│  │  │  │  API Routes │  │  ISR Cache  │  │  Middleware │    │    │   │
│  │  │  │  (Handlers) │  │  (Vercel)   │  │  (Edge)     │    │    │   │
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
│  │              (/api/revalidate)                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Architecture Pattern

The system follows the **JAMstack architecture** with **Headless CMS** pattern:

- **J**avaScript: Next.js (React)
- **A**PIs: Sanity Content API (GROQ)
- **M**arkup: Static HTML generated at build time

**Key Characteristics:**
- Content is authored in Sanity Studio and stored in Sanity's cloud datastore
- Next.js fetches content at build time and generates static pages
- Vercel serves pre-built pages from edge locations globally
- Content updates trigger ISR revalidation for near-instant updates

---

## 3. Technology Stack

### 3.1 Frontend

| **Layer** | **Technology** | **Purpose** |
|-----------|----------------|-------------|
| Framework | Next.js 14+ (App Router) | React framework with SSG, SSR, ISR |
| Language | TypeScript | Type safety and developer experience |
| Styling | Tailwind CSS | Utility-first CSS framework |
| UI Components | React + shadcn/ui (optional) | Component library |
| Animation | Framer Motion (optional) | Page transitions and micro-interactions |
| Icons | Lucide React | Consistent icon system |
| Fonts | Next.js Font Optimization | Self-hosted Google Fonts |

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
| Sanity Webhooks | Instant content revalidation | POST to `/api/revalidate` |

---

## 4. Component Architecture

### 4.1 Directory Structure

```
portfolio-website/
├── app/                          # Next.js App Router
│   ├── (routes)/                 # Route groups
│   │   ├── page.tsx              # Home / Landing
│   │   ├── about/
│   │   │   └── page.tsx          # About page
│   │   ├── projects/
│   │   │   └── page.tsx          # Projects listing
│   │   ├── blog/
│   │   │   ├── page.tsx          # Blog listing (ISR)
│   │   │   └── [slug]/
│   │   │       └── page.tsx      # Individual blog post (ISR)
│   │   └── contact/
│   │       └── page.tsx          # Contact page
│   ├── api/
│   │   └── revalidate/
│   │       └── route.ts          # Webhook handler for ISR
│   ├── layout.tsx                # Root layout (metadata, providers)
│   └── globals.css               # Global styles
│
├── components/                   # Reusable React components
│   ├── ui/                       # Primitive UI components (Button, Card, Badge)
│   ├── layout/                   # Layout components (Navbar, Footer, Container)
│   ├── sections/                 # Page section components (Hero, ProjectsGrid, BlogList)
│   └── shared/                   # Shared components (SocialLinks, ThemeToggle)
│
├── lib/                          # Utility libraries
│   ├── sanity.ts                 # Sanity client configuration
│   ├── sanity-image.ts           # Image URL builder utilities
│   ├── groq-queries.ts           # GROQ query definitions
│   └── utils.ts                  # General utilities (cn, formatDate, etc.)
│
├── types/                        # TypeScript type definitions
│   ├── sanity.ts                 # Sanity-generated types
│   └── index.ts                # Application types
│
├── public/                       # Static assets
│   ├── images/                   # Local images (fallbacks, logos)
│   └── resume.pdf                # Downloadable resume
│
├── sanity.config.ts              # Sanity Studio configuration (if embedded)
├── next.config.js                # Next.js configuration
├── tailwind.config.ts            # Tailwind CSS configuration
├── tsconfig.json                 # TypeScript configuration
└── package.json
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

| **Route** | **Strategy** | **Rationale** |
|-----------|--------------|---------------|
| `/` (Home) | Static | Content rarely changes; maximum performance |
| `/about` | Static | Content rarely changes |
| `/projects` | Static + ISR | Content may be updated via Sanity |
| `/blog` | Static + ISR | Content changes frequently; revalidate every 60s |
| `/blog/[slug]` | Static + ISR | Individual posts; `generateStaticParams` for build-time generation |
| `/contact` | Static | Form is client-side; page is static |
| `/api/revalidate` | Serverless Function | Webhook endpoint for on-demand revalidation |

---

## 5. Data Architecture

### 5.1 Data Flow Diagram

```
┌─────────────────┐
│  Sanity Studio  │
│  (Author writes) │
└────────┬────────┘
         │ Publish
         ▼
┌─────────────────┐
│  Sanity Cloud   │
│  (Data Store)   │
└────────┬────────┘
         │ GROQ Query
         ▼
┌─────────────────────────────────────────┐
│         Next.js Build / Runtime         │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Build Time (SSG)               │   │
│  │  • fetch blog posts             │   │
│  │  • generate static pages       │   │
│  │  • store in ISR cache          │   │
│  └─────────────────────────────────┘   │
│              OR                        │
│  ┌─────────────────────────────────┐   │
│  │  Runtime (ISR Revalidation)     │   │
│  │  • webhook triggers revalidate  │   │
│  │  • fetch fresh content          │   │
│  │  • update cache                │   │
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
│  Visitor Browser│
│  (Hydrate React)│
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
│ socials: array({platform, url})         │
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
    "coverImage": coverImage.asset->url,
    "blurDataUrl": coverImage.asset->metadata.lqip,
    tags,
    "estimatedReadTime": round(length(pt::text(content)) / 5 / 180)
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
    content[]{
      ...,
      _type == "image" => {
        ...,
        "asset": asset->
      }
    }
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

### 5.4 Caching Strategy

| **Cache Layer** | **Scope** | **TTL** | **Invalidation** |
|-----------------|-----------|---------|------------------|
| Vercel Edge Cache | Static HTML | Per deployment | Full redeploy |
| ISR Cache | Dynamic pages | 60 seconds | Time-based or webhook |
| Sanity CDN | API responses | 60 seconds | Automatic |
| Browser Cache | Static assets | 1 year | Hash in filename |
| Image Cache | Optimized images | 1 year | URL-based |

---

## 6. Deployment Architecture

### 6.1 Vercel Deployment Pipeline

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
│  • Static gen   │
│  • Upload edge  │
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

### 6.2 Environment Configuration

| **Environment** | **Purpose** | **Dataset** | `useCdn` |
|-----------------|-------------|-------------|----------|
| **Development** | Local development | `development` | `false` |
| **Preview** | PR deployments | `development` | `true` |
| **Production** | Live site | `production` | `true` |

### 6.3 Domain & Routing

```
┌─────────────────────────────────────────┐
│           Domain: yourname.dev          │
│           (or custom domain)            │
├─────────────────────────────────────────┤
│  /           →  Home page               │
│  /about      →  About page              │
│  /projects   →  Projects listing        │
│  /blog       →  Blog listing (ISR)      │
│  /blog/[slug]→  Blog post (ISR)         │
│  /contact    →  Contact page            │
│  /api/*      →  Serverless functions    │
└─────────────────────────────────────────┘
```

---

## 7. Security Architecture

### 7.1 Threat Model

| **Threat** | **Mitigation** |
|------------|----------------|
| API token exposure | Store in Vercel env vars; never commit to Git |
| XSS attacks | React's automatic escaping; sanitize Portable Text |
| CSRF on contact form | Implement CSRF tokens or use service with built-in protection |
| Webhook spoofing | Validate Sanity webhook signature with `SANITY_WEBHOOK_SECRET` |
| Content injection | Sanity validates schema; only approved fields are rendered |
| Image abuse | Use Sanity Image CDN with signed URLs (optional) |

### 7.2 Security Layers

```
┌─────────────────────────────────────────┐
│  Layer 1: DNS / HTTPS                   │
│  • Vercel-managed SSL certificate       │
│  • HSTS headers                         │
├─────────────────────────────────────────┤
│  Layer 2: Edge / CDN                    │
│  • DDoS protection (Vercel)             │
│  • Rate limiting on API routes          │
├─────────────────────────────────────────┤
│  Layer 3: Application                   │
│  • Content Security Policy (CSP)        │
│  • Secure headers (X-Frame-Options, etc.)│
│  • Input validation on contact form     │
├─────────────────────────────────────────┤
│  Layer 4: API / Data                    │
│  • Authenticated Sanity API requests    │
│  • Webhook signature verification       │
│  • Principle of least privilege         │
└─────────────────────────────────────────┘
```

### 7.3 Environment Variable Security

| **Variable** | **Client-Side?** | **Storage** |
|--------------|------------------|-------------|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | Yes | Vercel env (build-time) |
| `NEXT_PUBLIC_SANITY_DATASET` | Yes | Vercel env (build-time) |
| `NEXT_PUBLIC_SANITY_API_VERSION` | Yes | Vercel env (build-time) |
| `SANITY_API_TOKEN` | **No** | Vercel env (server-only) |
| `SANITY_WEBHOOK_SECRET` | **No** | Vercel env (server-only) |
| `EMAIL_API_KEY` | **No** | Vercel env (server-only) |

---

## 8. Performance Architecture

### 8.1 Performance Budget

| **Metric** | **Target** | **Measurement** |
|------------|------------|-----------------|
| First Contentful Paint (FCP) | < 1.0s | Lighthouse |
| Largest Contentful Paint (LCP) | < 2.5s | Lighthouse |
| Time to Interactive (TTI) | < 3.8s | Lighthouse |
| Cumulative Layout Shift (CLS) | < 0.1 | Lighthouse |
| Total Blocking Time (TBT) | < 200ms | Lighthouse |
| Lighthouse Performance Score | ≥ 90 | Lighthouse |

### 8.2 Optimization Strategies

| **Strategy** | **Implementation** |
|--------------|--------------------|
| **Static Generation** | Pre-render pages at build time |
| **ISR** | Revalidate stale content without full rebuild |
| **Image Optimization** | `next/image` + Sanity Image CDN (WebP/AVIF) |
| **Font Optimization** | `next/font` for self-hosted, subsetted fonts |
| **Code Splitting** | Automatic route-based splitting by Next.js |
| **Prefetching** | `<Link prefetch>` for anticipated navigation |
| **Edge Caching** | Vercel's global edge network for static assets |
| **Streaming** | React Server Components for partial hydration |

### 8.3 Image Pipeline

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

## 9. Scalability & Future Considerations

### 9.1 Current Scale Assumptions

| **Metric** | **Assumed Scale** | **Architecture Support** |
|------------|-------------------|--------------------------|
| Blog posts | < 500 | Static generation + ISR |
| Monthly visitors | < 50,000 | Vercel free tier |
| Concurrent visitors | < 1,000 | Edge caching |
| Images | < 5,000 | Sanity Image CDN |

### 9.2 Future Extension Points

| **Feature** | **Architecture Approach** |
|-------------|---------------------------|
| **Search** | Add Algolia or Fuse.js client-side search |
| **Comments** | Integrate Giscus (GitHub Discussions) or Disqus |
| **Newsletter** | Add ConvertKit / Mailchimp signup form |
| **Analytics** | Vercel Analytics + Plausible (privacy-focused) |
| **Multi-language** | i18n routing + Sanity localized fields |
| **RSS Feed** | Dynamic API route generating XML |
| **Sitemap** | Dynamic API route generating sitemap.xml |
| **Open Graph Images** | `@vercel/og` for dynamic social cards |

### 9.3 Migration Considerations

| **Scenario** | **Approach** |
|--------------|--------------|
| Migrate to different CMS | Abstract data layer in `lib/cms.ts`; swap adapter |
| Migrate from Next.js | Export static build; host on any static CDN |
| Add server-side features | Upgrade to Vercel Pro for longer function timeouts |

---

## Appendix A: Decision Log

| **Decision** | **Rationale** | **Date** |
|--------------|---------------|----------|
| Next.js App Router | Server Components, streaming, nested layouts | 2026-06-28 |
| Sanity over Strapi/Contentful | Developer experience, GROQ flexibility, generous free tier | 2026-06-28 |
| Vercel over Netlify | First-class Next.js support, superior ISR | 2026-06-28 |
| ISR over SSR | Better performance, lower compute costs, still dynamic | 2026-06-28 |
| Tailwind over CSS Modules | Rapid development, design system consistency | 2026-06-28 |
| TypeScript over JavaScript | Type safety, IDE autocomplete, fewer runtime bugs | 2026-06-28 |

---

## Appendix B: Glossary

| **Term** | **Definition** |
|----------|----------------|
| **App Router** | Next.js 13+ routing system using React Server Components |
| **GROQ** | Graph-Relational Object Queries — Sanity's query language |
| **ISR** | Incremental Static Regeneration — update static pages without rebuild |
| **JAMstack** | JavaScript, APIs, Markup — architecture for static sites |
| **Portable Text** | Sanity's structured rich text format (JSON-based) |
| **RSC** | React Server Component — renders on server, zero client JS |
| **SSG** | Static Site Generation — HTML generated at build time |
| **SSR** | Server-Side Rendering — HTML generated on each request |

---

This architecture document serves as the definitive technical blueprint for your personal portfolio website, connecting your Vercel-hosted Next.js frontend with your Sanity CMS backend. It should be referenced during development, code review, and future architectural decisions.
