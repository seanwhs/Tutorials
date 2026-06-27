# Software Requirements Document (SRD)

## Personal Portfolio Website

---

### Document Control

| **Field** | **Value** |
|-----------|-----------|
| **Document Title** | Software Requirements Document — Personal Portfolio Website |
| **Version** | 1.0 |
| **Date** | 2026-06-28 |
| **Author** | Sean Wong |
| **Status** | Final |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [System Features & Functional Requirements](#3-system-features--functional-requirements)
4. [External Interface Requirements](#4-external-interface-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Data Requirements](#6-data-requirements)
7. [Appendix](#7-appendix)

---

## 1. Introduction

### 1.1 Purpose

This document specifies the software requirements for a **Personal Portfolio Website**. The system is a statically-optimized, content-managed web application built with **Next.js 16**, designed to showcase professional work, skills, and blog content. It serves as the central online presence for the portfolio owner and bridges the previously built portfolio frontend (hosted on Vercel) with the Sanity CMS backend using **explicit caching** and **tag-based invalidation**.

### 1.2 Intended Audience

- **Developer** — the primary builder and maintainer of the site
- **Content Author** — the portfolio owner who writes blog posts and updates content via Sanity Studio
- **Visitors** — potential employers, clients, and readers browsing the site

### 1.3 Scope

The portfolio website will:
- Display a personal introduction, skills, and projects
- Host a blog with dynamically fetched content from Sanity CMS
- Provide contact functionality
- Be fully responsive and accessible
- Be deployed and hosted on Vercel
- Use **Next.js 16 explicit caching** for predictable performance

The system will **not** include:
- User authentication for visitors
- E-commerce or payment processing
- Real-time chat or messaging

### 1.4 Definitions & Acronyms

| **Term** | **Definition** |
|----------|----------------|
| **CMS** | Content Management System (Sanity) |
| **GROQ** | Graph-Relational Object Queries (Sanity's query language) |
| **SRD** | Software Requirements Document |
| **CDN** | Content Delivery Network |
| **SEO** | Search Engine Optimization |
| **WCAG** | Web Content Accessibility Guidelines |
| **'use cache'** | Next.js 16 directive to opt a function into caching |
| **cacheTag** | Next.js 16 API to register a cache entry with a tag |
| **revalidateTag** | Next.js 16 API to invalidate cached entries by tag |
| **proxy.ts** | Next.js 16 replacement for middleware.ts for request interception |
| **Turbopack** | Next.js 16 default bundler (replaces webpack) |

### 1.5 References

- [1] Sanity CMS Documentation — https://www.sanity.io/docs
- [2] Next.js 16 Documentation — https://nextjs.org/docs
- [3] Vercel Platform Documentation — https://vercel.com/docs
- [4] Next.js 16 Upgrade Guide — https://nextjs.org/docs/app/guides/upgrading/version-16
- [5] Tutorial: Building Personal Portfolio Website (prior work)
- [6] Tutorial: Sanity CMS Setup (prior work)

---

## 2. Overall Description

### 2.1 Product Perspective

The portfolio website is a standalone web application that integrates with Sanity CMS as a headless backend for content management. It is hosted on Vercel's edge network and uses **Next.js 16** with explicit caching via the `'use cache'` directive and `cacheTag` / `revalidateTag` APIs.

**System Context Diagram:**

```
┌─────────────────┐     HTTP/API      ┌─────────────────┐
│   Visitor       │◄────────────────►│  Portfolio Site │
│  (Browser)      │                   │ (Next.js 16/   │
└─────────────────┘                   │    Vercel)      │
                                      └────────┬────────┘
                                               │
                                               │ GROQ/API
                                               ▼
                                      ┌─────────────────┐
                                      │  Sanity CMS     │
                                      │  (Content API)  │
                                      └─────────────────┘
                                               │
                                               ▼
                                      ┌─────────────────┐
                                      │  Sanity Studio  │
                                      │  (Content Mgmt) │
                                      └─────────────────┘
                                               │
                                               ▼ Webhook
                                      ┌─────────────────┐
                                      │ /api/revalidate │
                                      │ (revalidateTag) │
                                      └─────────────────┘
```

### 2.2 User Classes and Characteristics

| **User Class** | **Description** | **Technical Skill** |
|----------------|-----------------|---------------------|
| **Visitor** | Browses the portfolio and reads blog posts | None required |
| **Content Author** | Creates and manages blog posts via Sanity Studio | Basic (CMS interface) |
| **Developer** | Maintains code, deploys updates, configures integrations | Advanced |

### 2.3 Operating Environment

- **Frontend Framework:** Next.js 16 (App Router)
- **Bundler:** Turbopack (default in Next.js 16)
- **Hosting Platform:** Vercel
- **CMS Backend:** Sanity.io
- **Styling:** Tailwind CSS
- **Browser Support:** Chrome, Firefox, Safari, Edge (last 2 versions)
- **Node.js Version:** 20.9+ (required for Next.js 16)

### 2.4 Design & Implementation Constraints

- **CON-1:** The site must be deployable on Vercel
- **CON-2:** Content must be fetched from Sanity's CDN API (not direct database)
- **CON-3:** All images must be served via Sanity's image CDN with optimization
- **CON-4:** The site must comply with WCAG 2.1 Level AA accessibility standards
- **CON-5:** Blog content must use Portable Text format for rich text rendering
- **CON-6:** Caching must use Next.js 16 explicit model (`'use cache'`, `cacheTag`, `revalidateTag`)
- **CON-7:** Request interception must use `proxy.ts` (not `middleware.ts`)
- **CON-8:** All async request APIs (`params`, `searchParams`, `cookies`, `headers`) must be awaited in Next.js 16

---

## 3. System Features & Functional Requirements

### 3.1 Feature: Home / Landing Page

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | The system shall display the portfolio owner's name and professional title prominently | High |
| FR-02 | The system shall display a brief personal introduction / bio | High |
| FR-03 | The system shall display a professional headshot or avatar | Medium |
| FR-04 | The system shall provide navigation links to all major sections (About, Projects, Blog, Contact) | High |
| FR-05 | The system shall display social media links (GitHub, LinkedIn, Twitter/X, etc.) | Medium |

### 3.2 Feature: About Page

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-06 | The system shall display a detailed personal biography | High |
| FR-07 | The system shall display a list of technical skills with proficiency indicators | Medium |
| FR-08 | The system shall display work experience in a timeline or list format | Medium |
| FR-09 | The system shall display education background | Medium |
| FR-10 | The system shall allow downloading a resume/CV PDF | Low |

### 3.3 Feature: Projects Showcase

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-11 | The system shall display a grid or list of project cards | High |
| FR-12 | Each project card shall display: title, short description, thumbnail image, and tech stack tags | High |
| FR-13 | Each project card shall link to the live project URL and/or source code repository | High |
| FR-14 | The system shall support filtering projects by technology tag | Medium |
| FR-15 | Project data shall be manageable via Sanity CMS | Medium |

### 3.4 Feature: Blog (Integrated with Sanity CMS & Next.js 16 Caching)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-16 | The system shall display a blog listing page with all published posts ordered by date (newest first) | High |
| FR-17 | Each blog post card shall display: title, publish date, excerpt, cover image, and tags | High |
| FR-18 | The system shall support pagination or "Load More" for the blog listing | Medium |
| FR-19 | The system shall display individual blog post pages with full rich-text content | High |
| FR-20 | The system shall render Portable Text content including: paragraphs, headings, lists, links, inline images, and code blocks | High |
| FR-21 | The system shall display blog post tags and allow filtering by tag | Medium |
| FR-22 | The system shall generate SEO-friendly URLs using post slugs | High |
| FR-23 | Blog posts shall be fetched via **cached data loaders** using `'use cache'` and `cacheTag('posts')` | High |
| FR-24 | Individual post pages shall use **granular cache tags** (`cacheTag('post:{slug}')`) for targeted invalidation | High |
| FR-25 | The system shall display an estimated reading time for each blog post | Low |
| FR-26 | The system shall support Open Graph meta tags for social sharing | Medium |

### 3.5 Feature: Contact

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-27 | The system shall display contact information (email, social links) | High |
| FR-28 | The system shall provide a contact form with fields: Name, Email, Subject, Message | Medium |
| FR-29 | The contact form shall validate all required fields before submission | Medium |
| FR-30 | The system shall send form submissions to a designated email address (via email service API) | Medium |
| FR-31 | The system shall display a success message after form submission | Medium |

### 3.6 Feature: Navigation & Layout

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-32 | The system shall provide a persistent navigation bar on all pages | High |
| FR-33 | The navigation bar shall include links to: Home, About, Projects, Blog, Contact | High |
| FR-34 | The system shall provide a responsive mobile hamburger menu | High |
| FR-35 | The system shall display a footer with copyright notice and social links | Medium |
| FR-36 | The system shall support smooth scrolling to page sections | Low |

### 3.7 Feature: Content Management (Sanity Studio)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-37 | Sanity Studio shall support creating, editing, and publishing blog posts | High |
| FR-38 | Sanity Studio shall enforce required fields: title, slug, publishedAt, content | High |
| FR-39 | Sanity Studio shall auto-generate URL slugs from post titles | Medium |
| FR-40 | Sanity Studio shall support uploading and managing images (cover images, inline images) | High |
| FR-41 | Sanity Studio shall support tagging blog posts with multiple tags | Medium |
| FR-42 | Sanity Studio shall support draft/publish workflow for blog posts | High |
| FR-43 | Sanity Studio shall support managing project entries (title, description, links, tech stack, images) | Medium |

### 3.8 Feature: Cache Invalidation (Next.js 16)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-44 | The system shall provide an API route (`/api/revalidate`) that accepts webhook calls from Sanity | High |
| FR-45 | The revalidation handler shall verify the Sanity webhook signature before processing | High |
| FR-46 | The system shall invalidate the `posts` cache tag when any blog post is created, updated, or deleted | High |
| FR-47 | The system shall invalidate the specific `post:{slug}` cache tag when an individual post is updated | High |
| FR-48 | The revalidation API shall return confirmation of which tags were invalidated | Medium |

### 3.9 Feature: Request Interception (proxy.ts)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-49 | The system shall use `proxy.ts` (not `middleware.ts`) for global request interception | High |
| FR-50 | The proxy shall add security headers (X-Frame-Options, X-Content-Type-Options) to all responses | Medium |
| FR-51 | The proxy shall remain minimal — heavy logic shall be delegated to Route Handlers | Medium |

---

## 4. External Interface Requirements

### 4.1 User Interfaces

| ID | Requirement | Priority |
|----|-------------|----------|
| UI-01 | The interface shall be responsive and adapt to mobile, tablet, and desktop viewports | High |
| UI-02 | The interface shall maintain consistent typography, color scheme, and spacing across all pages | High |
| UI-03 | All interactive elements shall have visible focus states for keyboard navigation | High |
| UI-04 | Color contrast ratios shall meet WCAG 2.1 Level AA standards (minimum 4.5:1 for normal text) | High |
| UI-05 | The interface shall support dark mode toggle (optional) | Low |

### 4.2 Hardware Interfaces

- No direct hardware interfaces required. The system operates entirely through standard web browsers.

### 4.3 Software Interfaces

| ID | Requirement | Priority |
|----|-------------|----------|
| SI-01 | The system shall integrate with Sanity Client API (`@sanity/client`) for content fetching | High |
| SI-02 | The system shall integrate with Sanity Image URL builder (`@sanity/image-url`) for image optimization | High |
| SI-03 | The system shall integrate with Portable Text React (`@portabletext/react`) for rich text rendering | High |
| SI-04 | The system shall integrate with an email service (e.g., Resend, SendGrid, or Formspree) for contact form submissions | Medium |
| SI-05 | The system shall integrate with Vercel Analytics (optional) for traffic monitoring | Low |
| SI-06 | The system shall use Next.js 16 `cacheTag` and `revalidateTag` APIs for cache management | High |

### 4.4 Communications Interfaces

| ID | Requirement | Priority |
|----|-------------|----------|
| CI-01 | The system shall communicate with Sanity API over HTTPS | High |
| CI-02 | The system shall use GROQ queries to fetch content from Sanity | High |
| CI-03 | The system shall support webhook communication from Sanity to Vercel for on-demand cache invalidation via `revalidateTag` | High |
| CI-04 | The system shall use `proxy.ts` for edge-level request interception and routing | High |

---

## 5. Non-Functional Requirements

### 5.1 Performance Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-01 | The system shall achieve a Lighthouse Performance score of 90+ | High |
| NFR-02 | Initial page load time shall not exceed 3 seconds on a 3G connection | High |
| NFR-03 | Time to First Byte (TTFB) shall not exceed 200ms | Medium |
| NFR-04 | Images shall be served in modern formats (WebP/AVIF) with lazy loading | High |
| NFR-05 | Cache invalidation via `revalidateTag` shall complete within 2 seconds of webhook receipt | Medium |
| NFR-06 | Build time shall be optimized using Turbopack (Next.js 16 default bundler) | Medium |

### 5.2 Security Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-07 | All API communications shall use HTTPS | High |
| NFR-08 | Sanity API tokens shall be stored as environment variables and never exposed client-side | High |
| NFR-09 | The contact form shall implement basic spam protection (honeypot or CAPTCHA) | Medium |
| NFR-10 | The system shall implement Content Security Policy (CSP) headers | Medium |
| NFR-11 | Webhook endpoints shall validate Sanity webhook signatures before calling `revalidateTag` | High |
| NFR-12 | `proxy.ts` shall not expose sensitive server logic to the client | Medium |

### 5.3 Reliability & Availability

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-13 | The system shall achieve 99.9% uptime (leveraging Vercel's edge network) | High |
| NFR-14 | Failed Sanity API requests shall fallback to cached/stale content rather than error pages | Medium |
| NFR-15 | The system shall handle 404 errors gracefully with a custom error page | Medium |

### 5.4 Maintainability

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-16 | The codebase shall follow a component-based architecture | High |
| NFR-17 | All components shall be documented with JSDoc comments | Low |
| NFR-18 | The project shall use TypeScript for type safety (required for Next.js 16) | High |

### 5.5 Scalability

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-19 | The system shall support up to 500 blog posts without performance degradation | Medium |
| NFR-20 | The system shall support traffic spikes up to 10,000 concurrent visitors (Vercel edge caching) | Medium |

---

## 6. Data Requirements

### 6.1 Data Entities

| **Entity** | **Description** | **Source** |
|------------|-----------------|------------|
| `blogPost` | Blog post content (title, slug, body, images, tags, publish date) | Sanity CMS |
| `project` | Project showcase entries (title, description, links, tech stack, images) | Sanity CMS (or static) |
| `author` | Portfolio owner profile information | Sanity CMS (or static) |
| `contactSubmission` | Contact form submissions | Email service / database |

### 6.2 Data Flow

```
[Sanity Studio] --(publishes)--> [Sanity Content API]
                                      |
                                      | GROQ Query
                                      ▼
                           [Next.js 16 / Vercel Edge]
                                      |
                                      | 'use cache' + cacheTag
                                      ▼
                                [Visitor Browser]
```

### 6.3 Data Retention

- Blog posts and projects: Persistent (managed in Sanity)
- Contact form submissions: 12 months (or per email service policy)
- Cache entries: Controlled by `revalidateTag` / cache lifetime profiles

---

## 7. Appendix

### 7.1 Sanity Schema Reference (Blog Post)

```javascript
// schemas/blogPost.js
export default {
  name: 'blogPost',
  title: 'Blog Post',
  type: 'document',
  fields: [
    { name: 'title', title: 'Title', type: 'string', validation: Rule => Rule.required() },
    { name: 'slug', title: 'Slug', type: 'slug', options: { source: 'title' }, validation: Rule => Rule.required() },
    { name: 'publishedAt', title: 'Published At', type: 'datetime', initialValue: () => new Date().toISOString() },
    { name: 'excerpt', title: 'Excerpt', type: 'text', rows: 3 },
    { name: 'coverImage', title: 'Cover Image', type: 'image', options: { hotspot: true } },
    { name: 'content', title: 'Content', type: 'array', of: [{ type: 'block' }, { type: 'image' }, { type: 'code' }] },
    { name: 'tags', title: 'Tags', type: 'array', of: [{ type: 'string' }], options: { layout: 'tags' } }
  ]
}
```

### 7.2 Environment Variables

| **Variable** | **Description** | **Required** | **Client-Side?** |
|--------------|-----------------|--------------|------------------|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | Sanity project identifier | Yes | Yes |
| `NEXT_PUBLIC_SANITY_DATASET` | Sanity dataset name (e.g., `production`) | Yes | Yes |
| `NEXT_PUBLIC_SANITY_API_VERSION` | Sanity API version date | Yes | Yes |
| `SANITY_API_TOKEN` | Sanity read token (for server-side fetching) | Yes | **No** |
| `SANITY_WEBHOOK_SECRET` | Secret for validating Sanity webhooks | Yes | **No** |
| `EMAIL_API_KEY` | API key for email service | No (if using contact form) | **No** |

### 7.3 GROQ Query Examples

```javascript
// Fetch all published blog posts
`*[_type == "blogPost" && publishedAt < now()] | order(publishedAt desc)`

// Fetch single post by slug
`*[_type == "blogPost" && slug.current == $slug][0]`

// Fetch posts by tag
`*[_type == "blogPost" && "web-dev" in tags] | order(publishedAt desc)`
```

### 7.4 Next.js 16 Caching Patterns

```typescript
// Cached data loader
export async function loadPosts() {
  "use cache";
  cacheTag("posts");
  return client.fetch(allPostsQuery);
}

// Revalidation handler
import { revalidateTag } from "next/cache";
revalidateTag("posts", "max");
```

### 7.5 Revision History

| **Version** | **Date** | **Author** | **Changes** |
|-------------|----------|------------|-------------|
| 1.0 | 2026-06-28 | [Your Name] | Initial draft (Next.js 14) |
| 2.0 | 2026-06-28 | [Your Name] | Updated for Next.js 16: explicit caching, proxy.ts, Turbopack, async APIs |

---

This SRD serves as the authoritative specification for your personal portfolio website using Next.js 16, bridging your Vercel-hosted frontend and Sanity CMS backend with explicit, developer-controlled caching.
