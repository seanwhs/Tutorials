Here is a complete **Software Requirements Document (SRD)** for your personal portfolio website. I've tailored it to the context of your existing tutorials (portfolio built on Vercel, Sanity CMS integration, blog functionality) and followed standard SRD structure conventions.

---

# Software Requirements Document (SRD)

## Personal Portfolio Website

---

### Document Control

| **Field** | **Value** |
|-----------|-----------|
| **Document Title** | Software Requirements Document — Personal Portfolio Website |
| **Version** | 1.0 |
| **Date** | 2026-06-28 |
| **Author** | [Your Name] |
| **Status** | Draft |

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

This document specifies the software requirements for a **Personal Portfolio Website**. The system is a statically-generated, content-managed web application designed to showcase professional work, skills, and blog content. It serves as the central online presence for the portfolio owner and bridges the previously built portfolio frontend (hosted on Vercel) with the Sanity CMS backend.

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

The system will **not** include:
- User authentication for visitors
- E-commerce or payment processing
- Real-time chat or messaging

### 1.4 Definitions & Acronyms

| **Term** | **Definition** |
|----------|----------------|
| **CMS** | Content Management System (Sanity) |
| **ISR** | Incremental Static Regeneration (Next.js feature) |
| **GROQ** | Graph-Relational Object Queries (Sanity's query language) |
| **SRD** | Software Requirements Document |
| **CDN** | Content Delivery Network |
| **SEO** | Search Engine Optimization |
| **WCAG** | Web Content Accessibility Guidelines |

### 1.5 References

- [1] Sanity CMS Documentation — https://www.sanity.io/docs
- [2] Next.js Documentation — https://nextjs.org/docs
- [3] Vercel Platform Documentation — https://vercel.com/docs
- [4] Tutorial: Building Personal Portfolio Website (prior work)
- [5] Tutorial: Sanity CMS Setup (prior work)

---

## 2. Overall Description

### 2.1 Product Perspective

The portfolio website is a standalone web application that integrates with Sanity CMS as a headless backend for content management. It is hosted on Vercel's edge network and uses Next.js for static site generation with ISR capabilities.

**System Context Diagram:**

```
┌─────────────────┐     HTTP/API      ┌─────────────────┐
│   Visitor       │◄────────────────►│  Portfolio Site │
│  (Browser)      │                   │  (Next.js/Vercel)│
└─────────────────┘                   └────────┬────────┘
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
```

### 2.2 User Classes and Characteristics

| **User Class** | **Description** | **Technical Skill** |
|----------------|-----------------|---------------------|
| **Visitor** | Browses the portfolio and reads blog posts | None required |
| **Content Author** | Creates and manages blog posts via Sanity Studio | Basic (CMS interface) |
| **Developer** | Maintains code, deploys updates, configures integrations | Advanced |

### 2.3 Operating Environment

- **Frontend Framework:** Next.js 14+ (App Router)
- **Hosting Platform:** Vercel
- **CMS Backend:** Sanity.io
- **Styling:** Tailwind CSS (or preferred framework)
- **Browser Support:** Chrome, Firefox, Safari, Edge (last 2 versions)

### 2.4 Design & Implementation Constraints

- **CON-1:** The site must be deployable on Vercel's free tier
- **CON-2:** Content must be fetched from Sanity's CDN API (not direct database)
- **CON-3:** All images must be served via Sanity's image CDN with optimization
- **CON-4:** The site must comply with WCAG 2.1 Level AA accessibility standards
- **CON-5:** Blog content must use Portable Text format for rich text rendering

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

### 3.4 Feature: Blog (Integrated with Sanity CMS)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-16 | The system shall display a blog listing page with all published posts ordered by date (newest first) | High |
| FR-17 | Each blog post card shall display: title, publish date, excerpt, cover image, and tags | High |
| FR-18 | The system shall support pagination or "Load More" for the blog listing | Medium |
| FR-19 | The system shall display individual blog post pages with full rich-text content | High |
| FR-20 | The system shall render Portable Text content including: paragraphs, headings, lists, links, inline images, and code blocks | High |
| FR-21 | The system shall display blog post tags and allow filtering by tag | Medium |
| FR-22 | The system shall generate SEO-friendly URLs using post slugs | High |
| FR-23 | Blog posts shall be fetched dynamically from Sanity CMS at build time and revalidated via ISR | High |
| FR-24 | The system shall display an estimated reading time for each blog post | Low |
| FR-25 | The system shall support Open Graph meta tags for social sharing | Medium |

### 3.5 Feature: Contact

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-26 | The system shall display contact information (email, social links) | High |
| FR-27 | The system shall provide a contact form with fields: Name, Email, Subject, Message | Medium |
| FR-28 | The contact form shall validate all required fields before submission | Medium |
| FR-29 | The system shall send form submissions to a designated email address (via email service API) | Medium |
| FR-30 | The system shall display a success message after form submission | Medium |

### 3.6 Feature: Navigation & Layout

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-31 | The system shall provide a persistent navigation bar on all pages | High |
| FR-32 | The navigation bar shall include links to: Home, About, Projects, Blog, Contact | High |
| FR-33 | The system shall provide a responsive mobile hamburger menu | High |
| FR-34 | The system shall display a footer with copyright notice and social links | Medium |
| FR-35 | The system shall support smooth scrolling to page sections | Low |

### 3.7 Feature: Content Management (Sanity Studio)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-36 | Sanity Studio shall support creating, editing, and publishing blog posts | High |
| FR-37 | Sanity Studio shall enforce required fields: title, slug, publishedAt, content | High |
| FR-38 | Sanity Studio shall auto-generate URL slugs from post titles | Medium |
| FR-39 | Sanity Studio shall support uploading and managing images (cover images, inline images) | High |
| FR-40 | Sanity Studio shall support tagging blog posts with multiple tags | Medium |
| FR-41 | Sanity Studio shall support draft/publish workflow for blog posts | High |
| FR-42 | Sanity Studio shall support managing project entries (title, description, links, tech stack, images) | Medium |

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

### 4.4 Communications Interfaces

| ID | Requirement | Priority |
|----|-------------|----------|
| CI-01 | The system shall communicate with Sanity API over HTTPS | High |
| CI-02 | The system shall use GROQ queries to fetch content from Sanity | High |
| CI-03 | The system shall support webhook communication from Sanity to Vercel for on-demand revalidation | Medium |

---

## 5. Non-Functional Requirements

### 5.1 Performance Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-01 | The system shall achieve a Lighthouse Performance score of 90+ | High |
| NFR-02 | Initial page load time shall not exceed 3 seconds on a 3G connection | High |
| NFR-03 | Time to First Byte (TTFB) shall not exceed 200ms | Medium |
| NFR-04 | Images shall be served in modern formats (WebP/AVIF) with lazy loading | High |
| NFR-05 | ISR revalidation shall complete within 60 seconds of content change | Medium |

### 5.2 Security Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-06 | All API communications shall use HTTPS | High |
| NFR-07 | Sanity API tokens shall be stored as environment variables and never exposed client-side | High |
| NFR-08 | The contact form shall implement basic spam protection (honeypot or CAPTCHA) | Medium |
| NFR-09 | The system shall implement Content Security Policy (CSP) headers | Medium |

### 5.3 Reliability & Availability

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-10 | The system shall achieve 99.9% uptime (leveraging Vercel's edge network) | High |
| NFR-11 | Failed Sanity API requests shall fallback to cached/stale content rather than error pages | Medium |
| NFR-12 | The system shall handle 404 errors gracefully with a custom error page | Medium |

### 5.4 Maintainability

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-13 | The codebase shall follow a component-based architecture | High |
| NFR-14 | All components shall be documented with JSDoc comments | Low |
| NFR-15 | The project shall use TypeScript for type safety (recommended) | Medium |

### 5.5 Scalability

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-16 | The system shall support up to 500 blog posts without performance degradation | Medium |
| NFR-17 | The system shall support traffic spikes up to 10,000 concurrent visitors (Vercel edge caching) | Medium |

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
                           [Next.js / Vercel Edge]
                                      |
                                      | Static HTML
                                      ▼
                                [Visitor Browser]
```

### 6.3 Data Retention

- Blog posts and projects: Persistent (managed in Sanity)
- Contact form submissions: 12 months (or per email service policy)

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

| **Variable** | **Description** | **Required** |
|--------------|-----------------|--------------|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | Sanity project identifier | Yes |
| `NEXT_PUBLIC_SANITY_DATASET` | Sanity dataset name (e.g., `production`) | Yes |
| `NEXT_PUBLIC_SANITY_API_VERSION` | Sanity API version date | Yes |
| `SANITY_API_TOKEN` | Sanity read token (for server-side fetching) | Yes |
| `SANITY_WEBHOOK_SECRET` | Secret for validating Sanity webhooks | No (recommended) |
| `EMAIL_API_KEY` | API key for email service | No (if using contact form) |

### 7.3 GROQ Query Examples

```javascript
// Fetch all published blog posts
`*[_type == "blogPost" && publishedAt < now()] | order(publishedAt desc)`

// Fetch single post by slug
`*[_type == "blogPost" && slug.current == $slug][0]`

// Fetch posts by tag
`*[_type == "blogPost" && "web-dev" in tags] | order(publishedAt desc)`
```

### 7.4 Revision History

| **Version** | **Date** | **Author** | **Changes** |
|-------------|----------|------------|-------------|
| 1.0 | 2026-06-28 | [Your Name] | Initial draft |

---

This SRD serves as the authoritative specification for your personal portfolio website, bridging your prior work on the Vercel-hosted frontend and Sanity CMS backend. It can be referenced during development, testing, and future enhancements.
