# Tutorial: Building a Production-Grade Content Platform with Sanity CMS and Next.js 16

## A Complete Beginner-to-Professional Guide for Building a Headless CMS Architecture for Your Portfolio Website

---

## Document Ecosystem

This tutorial is part of a **five-document system**:

| Document | Purpose | Link |
|----------|---------|------|
| **This Tutorial** | Hands-on, step-by-step building instructions | You are here |
| **[Portfolio Frontend Tutorial](1-portfolio-tutorial.md)** | Building the Next.js 16 frontend | [Download](sandbox:///mnt/agents/output/portfolio-tutorial-nextjs16.md) |
| **[Blog Posts Tutorial](3-blog-tutorial.md)** | Writing content and bridging frontend + backend | [Download](sandbox:///mnt/agents/output/blog-tutorial-nextjs16.md) |
| **[Software Requirements Document (SRD)](srd-portfolio.md)** | What the system must do (requirements) | [Download](sandbox:///mnt/agents/output/srd-nextjs16.md) |
| **[Architecture Document](architecture-portfolio.md)** | How the system is structured technically | [Download](sandbox:///mnt/agents/output/architecture-nextjs16.md) |

> 💡 **Tip**: When you see a 🔗 **Architecture** or 🔗 **SRD** reference, that decision is formally documented. You don't need to read them now, but they're available for deeper understanding.

---

# Table of Contents

1. [Introduction](#chapter-1-introduction)
2. [What Is a Headless CMS?](#chapter-2-what-is-a-headless-cms)
3. [Why We Chose Sanity](#chapter-3-why-we-chose-sanity)
4. [System Architecture Overview](#chapter-4-system-architecture-overview)
5. [Understanding Content Flow](#chapter-5-understanding-content-flow)
6. [Prerequisites](#chapter-6-prerequisites)
7. [Creating Your Sanity Project](#chapter-7-creating-your-sanity-project)
8. [Understanding Content Modeling](#chapter-8-understanding-content-modeling)
9. [Designing the Portfolio Content Architecture](#chapter-9-designing-the-portfolio-content-architecture)
10. [Building Your Schemas](#chapter-10-building-your-schemas)
11. [Understanding References and Relationships](#chapter-11-understanding-references-and-relationships)
12. [Configuring Sanity Studio](#chapter-12-configuring-sanity-studio)
13. [Working with GROQ](#chapter-13-working-with-groq)
14. [Understanding the Sanity Content API](#chapter-14-understanding-the-sanity-content-api)
15. [Image Pipeline Architecture](#chapter-15-image-pipeline-architecture)
16. [Security Architecture](#chapter-16-security-architecture)
17. [Environment Variables](#chapter-17-environment-variables)
18. [Connecting Sanity to Next.js 16](#chapter-18-connecting-sanity-to-nextjs-16)
19. [Explicit Caching in Next.js 16](#chapter-19-explicit-caching-in-nextjs-16)
20. [Cache Invalidation with Webhooks](#chapter-20-cache-invalidation-with-webhooks)
21. [Preview and Draft Mode](#chapter-21-preview-and-draft-mode)
22. [Multi-Environment Deployment](#chapter-22-multi-environment-deployment)
23. [Failure Handling](#chapter-23-failure-handling)
24. [Observability](#chapter-24-observability)
25. [Testing](#chapter-25-testing)
26. [SEO and Metadata](#chapter-26-seo-and-metadata)
27. [Accessibility Requirements](#chapter-27-accessibility-requirements)
28. [Performance Budgets](#chapter-28-performance-budgets)
29. [Production Checklist](#chapter-29-production-checklist)
30. [Capstone Exercise](#chapter-30-capstone-exercise)
31. [Next Steps](#chapter-31-next-steps)

---

# Chapter 1: Introduction

In this tutorial, you will build a complete content management backend for a professional portfolio website using:

* **Sanity CMS** — headless content management
* **Next.js 16** — React framework with explicit caching
* **React Server Components** — server-side rendering without client JS
* **Explicit caching** — `'use cache'`, `cacheTag`, `revalidateTag`
* **GROQ queries** — Sanity's powerful query language
* **Image optimization** — Sanity Image CDN + `next/image`
* **Webhooks** — instant cache invalidation
* **Draft previews** — preview unpublished content

This is not simply a "how to install Sanity" tutorial. Instead, this tutorial teaches:

* how content systems work,
* how modern headless CMS architectures operate,
* how Next.js 16 caching changes frontend architecture,
* and how to design a production-grade content platform.

> 🔗 **Architecture**: The system follows JAMstack with Headless CMS and explicit caching. See [Architecture §2.2](sandbox:///mnt/agents/output/architecture-nextjs16.md#22-architecture-pattern).

---

# Chapter 2: What Is A Headless CMS?

Traditional websites combine content management, storage, and presentation inside one application:

```text
Browser
    ↓
WordPress (CMS + Presentation + Database)
    ↓
MySQL
```

A **headless CMS** separates content management from presentation:

```text
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│     Browser     │────▶│     Next.js     │────▶│   Sanity API    │
│   (Visitor)     │◀────│   (Frontend)    │◀────│   (Content)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

The CMS manages content. Your frontend manages presentation. This separation enables:

* **Multiple frontends** — same content, different presentations (web, mobile, IoT)
* **Technology independence** — swap frontend without migrating content
* **Team specialization** — content editors work in Sanity, developers in Next.js
* **Better performance** — static generation, edge caching, CDN delivery

> 🔗 **SRD**: The system shall use Sanity as the headless CMS backend. See [Scope](sandbox:///mnt/agents/output/srd-nextjs16.md#13-scope).

---

# Chapter 3: Why We Chose Sanity

| Feature | Benefit | 🔗 Architecture |
|---------|---------|---------------|
| **Structured content** | Strong data modeling with schemas | [Content Model](sandbox:///mnt/agents/output/architecture-nextjs16.md#52-content-model-sanity-schemas) |
| **GROQ** | Powerful, flexible querying | [GROQ Queries](sandbox:///mnt/agents/output/architecture-nextjs16.md#53-groq-query-architecture) |
| **Portable Text** | Rich content as structured JSON, not HTML | [Data Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#5-data-architecture) |
| **Real-time editing** | Collaborative workflows | — |
| **Image CDN** | Automatic optimization, WebP/AVIF, hotspot cropping | [Image Pipeline](sandbox:///mnt/agents/output/architecture-nextjs16.md#103-image-pipeline) |
| **Webhooks** | Trigger `revalidateTag` for instant cache invalidation | [Cache Invalidation](sandbox:///mnt/agents/output/architecture-nextjs16.md#6-caching--revalidation-nextjs-16) |
| **Free tier** | Generous limits for personal portfolios | — |

---

# Chapter 4: System Architecture Overview

```text
                     AUTHOR
                        │
                        │ writes
                        ▼
              ┌─────────────────┐
              │  SANITY STUDIO  │  ← Content authoring interface
              └─────────────────┘
                        │
                        │ publishes
                        ▼
              ┌─────────────────┐
              │  SANITY DATASET │  ← Content storage (cloud)
              └─────────────────┘
                        │
                        │ GROQ query
                        ▼
              ┌─────────────────┐
              │  CONTENT API    │  ← HTTPS API endpoint
              └─────────────────┘
                        │
                        │ fetch + 'use cache'
                        ▼
              ┌─────────────────┐
              │   NEXT.JS 16    │  ← Explicit caching, Server Components
              │   (Vercel Edge) │  ← proxy.ts, revalidateTag
              └─────────────────┘
                        │
                        │ static HTML
                        ▼
                   ┌─────────┐
                   │ BROWSER │  ← Hydrated React app
                   └─────────┘
```

> 🔗 **Architecture**: See the full [System Context Diagram](sandbox:///mnt/agents/output/architecture-nextjs16.md#21-high-level-architecture) and [Data Flow](sandbox:///mnt/agents/output/architecture-nextjs16.md#52-data-flow).

---

# Chapter 5: Understanding Content Flow

Before writing code, understand the complete lifecycle:

```text
┌─────────────┐
│ 1. Create   │  ← Author writes in Sanity Studio
│   Content   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 2. Publish  │  ← Click "Publish" (not just "Save")
│   Content   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 3. Store    │  ← Sanity Cloud dataset + CDN
│   Dataset   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 4. Query    │  ← Next.js calls Sanity API with GROQ
│   API       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 5. Fetch    │  ← Data returned as JSON
│   Data      │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 6. Cache    │  ← 'use cache' + cacheTag('posts')
│   Result    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 7. Render   │  ← React Server Components → HTML
│   HTML      │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 8. Serve    │  ← Vercel Edge → Browser
│   Browser   │
└─────────────┘
```

> 🔗 **Architecture**: See [Data Flow Diagram](sandbox:///mnt/agents/output/architecture-nextjs16.md#52-data-flow).

---

## Teacher's Note

Many beginners think:

> "Sanity stores pages."

It does not.

Sanity stores **data**.

Next.js creates **pages**.

This distinction is fundamental to headless architecture.

---

# Chapter 6: Prerequisites

You should have:

* **Node.js 20.9+** (required for Next.js 16)
* **npm**
* **Git**
* **GitHub account**
* **Sanity account** ([Sign up](https://www.sanity.io/get-started))
* **Next.js 16 portfolio project** (from [Portfolio Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-nextjs16.md))

Verify:

```bash
node --version    # Should be v20.9.0 or higher
npm --version
git --version
```

> 🔗 **Architecture**: Next.js 16 requires Node.js 20.9+. See [Operating Environment](sandbox:///mnt/agents/output/srd-nextjs16.md#23-operating-environment).

---

# Chapter 7: Creating Your Sanity Project

### Step 1: Install Sanity CLI

```bash
npm install -g @sanity/cli
```

### Step 2: Initialize Your Project

```bash
sanity init
```

Choose:

| Prompt | Answer |
|--------|--------|
| Create project or select existing? | **Create new project** |
| Project name | `portfolio-cms` |
| Use default dataset? | **Yes** (creates `production` dataset) |
| Output path | `studio` |
| Template | **Empty project** |

### Step 3: Install Dependencies

```bash
cd studio
npm install
```

### Step 4: Start Sanity Studio

```bash
npm run dev
```

Open `http://localhost:3333`.

> 🔗 **Architecture**: The studio runs locally during development and is deployed separately for production. See [Deployment Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#9-deploying-sanity-studio).

---

# Chapter 8: Understanding Content Modeling

Poor content model:

```text
Post
    title
    body
```

Better:

```text
BlogPost
    title
    slug
    excerpt
    author
    tags
    coverImage
    content
    publishedAt
```

Production systems require:

* **Normalization** — separate entities for authors, categories, tags
* **Relationships** — references between documents
* **Metadata** — publish dates, SEO fields, slugs
* **Versioning** — drafts vs. published content

> 🔗 **SRD**: Content schemas must support blog posts, projects, and author information. See [Data Requirements](sandbox:///mnt/agents/output/srd-nextjs16.md#6-data-requirements).

---

# Chapter 9: Designing the Portfolio Content Architecture

```text
Author
    │
    │ 1:N (one author has many posts)
    ▼
BlogPost
    │
    │ N:N (many posts have many categories)
    ▼
Category

Project
    │
    │ N:N (many projects use many technologies)
    ▼
Technology
```

> 🔗 **Architecture**: See [Content Model](sandbox:///mnt/agents/output/architecture-nextjs16.md#52-content-model-sanity-schemas) for full schema definitions.

---

# Chapter 10: Building Your Schemas

## 10.1 Blog Post Schema

```typescript
// studio/schemas/blogPost.ts
import { defineField, defineType } from "sanity";

export default defineType({
  name: "blogPost",
  title: "Blog Post",
  type: "document",

  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: (Rule) => Rule.required().max(100),
    }),

    defineField({
      name: "slug",
      title: "Slug (URL)",
      type: "slug",
      options: {
        source: "title",
        maxLength: 96,
      },
      validation: (Rule) => Rule.required(),
    }),

    defineField({
      name: "excerpt",
      title: "Excerpt",
      type: "text",
      rows: 3,
      description: "Short summary shown on blog listing page",
    }),

    defineField({
      name: "coverImage",
      title: "Cover Image",
      type: "image",
      options: {
        hotspot: true,  // Enables focal point cropping
      },
    }),

    defineField({
      name: "publishedAt",
      title: "Published At",
      type: "datetime",
      initialValue: () => new Date().toISOString(),
      validation: (Rule) => Rule.required(),
    }),

    defineField({
      name: "author",
      title: "Author",
      type: "reference",
      to: [{ type: "author" }],
    }),

    defineField({
      name: "categories",
      title: "Categories",
      type: "array",
      of: [{ type: "reference", to: [{ type: "category" }] }],
    }),

    defineField({
      name: "tags",
      title: "Tags",
      type: "array",
      of: [{ type: "string" }],
      options: {
        layout: "tags",
      },
    }),

    defineField({
      name: "content",
      title: "Content",
      type: "array",
      of: [
        { type: "block" },      // Rich text paragraphs, headings, lists
        { type: "image" },      // Inline images
        { type: "code" },       // Code blocks with syntax highlighting
      ],
    }),
  ],

  preview: {
    select: {
      title: "title",
      publishedAt: "publishedAt",
      media: "coverImage",
      author: "author.name",
    },
    prepare({ title, publishedAt, media, author }) {
      return {
        title,
        subtitle: `${author || "No author"} — ${publishedAt ? new Date(publishedAt).toLocaleDateString() : "No date"}`,
        media,
      };
    },
  },
});
```

> 🔗 **SRD**: Blog posts must enforce required fields: title, slug, publishedAt, content. See [FR-38](sandbox:///mnt/agents/output/srd-nextjs16.md#37-feature-content-management-sanity-studio).

## 10.2 Author Schema

```typescript
// studio/schemas/author.ts
import { defineField, defineType } from "sanity";

export default defineType({
  name: "author",
  title: "Author",
  type: "document",

  fields: [
    defineField({
      name: "name",
      title: "Name",
      type: "string",
      validation: (Rule) => Rule.required(),
    }),

    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "name" },
      validation: (Rule) => Rule.required(),
    }),

    defineField({
      name: "bio",
      title: "Bio",
      type: "text",
      rows: 4,
    }),

    defineField({
      name: "avatar",
      title: "Avatar",
      type: "image",
      options: { hotspot: true },
    }),

    defineField({
      name: "email",
      title: "Email",
      type: "string",
      validation: (Rule) => Rule.email(),
    }),

    defineField({
      name: "socials",
      title: "Social Links",
      type: "array",
      of: [
        {
          type: "object",
          fields: [
            defineField({
              name: "platform",
              title: "Platform",
              type: "string",
              options: {
                list: [
                  { title: "GitHub", value: "github" },
                  { title: "LinkedIn", value: "linkedin" },
                  { title: "Twitter", value: "twitter" },
                  { title: "Website", value: "website" },
                ],
              },
            }),
            defineField({
              name: "url",
              title: "URL",
              type: "url",
              validation: (Rule) => Rule.required(),
            }),
          ],
        },
      ],
    }),

    defineField({
      name: "resume",
      title: "Resume",
      type: "file",
    }),
  ],
});
```

## 10.3 Category Schema

```typescript
// studio/schemas/category.ts
import { defineField, defineType } from "sanity";

export default defineType({
  name: "category",
  title: "Category",
  type: "document",

  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: (Rule) => Rule.required(),
    }),

    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title" },
      validation: (Rule) => Rule.required(),
    }),

    defineField({
      name: "description",
      title: "Description",
      type: "text",
      rows: 2,
    }),
  ],
});
```

## 10.4 Project Schema

```typescript
// studio/schemas/project.ts
import { defineField, defineType } from "sanity";

export default defineType({
  name: "project",
  title: "Project",
  type: "document",

  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: (Rule) => Rule.required(),
    }),

    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title", maxLength: 96 },
      validation: (Rule) => Rule.required(),
    }),

    defineField({
      name: "description",
      title: "Description",
      type: "text",
      rows: 3,
    }),

    defineField({
      name: "thumbnail",
      title: "Thumbnail",
      type: "image",
      options: { hotspot: true },
    }),

    defineField({
      name: "liveUrl",
      title: "Live URL",
      type: "url",
    }),

    defineField({
      name: "repoUrl",
      title: "Repository URL",
      type: "url",
    }),

    defineField({
      name: "techStack",
      title: "Tech Stack",
      type: "array",
      of: [{ type: "string" }],
      options: { layout: "tags" },
    }),

    defineField({
      name: "featured",
      title: "Featured",
      type: "boolean",
      initialValue: false,
      description: "Show prominently on home page",
    }),

    defineField({
      name: "completedAt",
      title: "Completed At",
      type: "date",
    }),
  ],

  preview: {
    select: {
      title: "title",
      media: "thumbnail",
      featured: "featured",
    },
    prepare({ title, media, featured }) {
      return {
        title,
        subtitle: featured ? "⭐ Featured" : "",
        media,
      };
    },
  },
});
```

## 10.5 Register All Schemas

```typescript
// studio/schemas/index.ts
import blogPost from "./blogPost";
import author from "./author";
import category from "./category";
import project from "./project";

export const schemaTypes = [blogPost, author, category, project];
```

> 🔗 **Architecture**: These schemas define the complete [Content Model](sandbox:///mnt/agents/output/architecture-nextjs16.md#52-content-model-sanity-schemas).

---

## Teacher's Note

Never generate URLs from titles at runtime.

**Bad:**

```text
Title: "My First Post"
URL:  /my-first-post

Later: Title changed to "My Updated Post"
URL breaks: /my-first-post no longer matches
```

**Good:**

```text
Persist the slug:
Title: "My First Post"
Slug:  "my-first-post" (persisted in database)
URL:   /blog/my-first-post

Title changes, but slug stays the same.
URL remains valid forever.
```

Always persist slugs.

---

# Chapter 11: Understanding References and Relationships

## One-to-Many (Author → Posts)

One author writes many posts:

```text
Author
   │
   │ 1:N
   ▼
Posts
```

```typescript
defineField({
  name: "author",
  type: "reference",
  to: [{ type: "author" }],
});
```

## Many-to-Many (Post ↔ Categories)

Many posts belong to many categories:

```text
Post
    │
    │ N:N
    ▼
Category
```

```typescript
defineField({
  name: "categories",
  type: "array",
  of: [
    {
      type: "reference",
      to: [{ type: "category" }],
    },
  ],
});
```

## GROQ Reference Expansion

When querying, expand references to get full document data:

```groq
*[_type == "blogPost"] {
  title,
  "author": author-> {      // Expand the reference
    name,
    bio,
    "avatar": avatar.asset->url
  },
  "categories": categories[]-> {  // Expand array of references
    title,
    slug
  }
}
```

---

# Chapter 12: Configuring Sanity Studio

```typescript
// studio/sanity.config.ts
import { defineConfig } from "sanity";
import { deskTool } from "sanity/desk";
import { visionTool } from "@sanity/vision";
import { schemaTypes } from "./schemas";

export default defineConfig({
  name: "portfolio-studio",
  title: "Portfolio CMS",

  projectId: "your-project-id",  // From sanity.io/manage
  dataset: "production",

  plugins: [
    deskTool(),   // Content editing interface
    visionTool(), // GROQ query playground
  ],

  schema: {
    types: schemaTypes,
  },
});
```

> 🔗 **Architecture**: The `projectId` and `dataset` are critical configuration values. See [Environment Variables](sandbox:///mnt/agents/output/architecture-nextjs16.md#appendix-b-environment-variables).

---

# Chapter 13: Working with GROQ

## Basic Query

```groq
*[_type == "blogPost"]
```

## Filter

```groq
*[_type == "blogPost" && publishedAt < now()]
```

## Sort

```groq
| order(publishedAt desc)
```

## Projection (select fields)

```groq
{
  _id,
  title,
  "slug": slug.current,
  publishedAt,
  excerpt
}
```

## Reference Expansion

```groq
author->{
  name,
  bio,
  "avatar": avatar.asset->url
}
```

## Complete Example

```groq
*[_type == "blogPost" && publishedAt < now()] | order(publishedAt desc) {
  _id,
  title,
  "slug": slug.current,
  publishedAt,
  excerpt,
  "coverImage": coverImage.asset->url,
  "author": author-> { name, "avatar": avatar.asset->url },
  "categories": categories[]-> { title, "slug": slug.current },
  tags
}
```

> 🔗 **Architecture**: GROQ queries are the primary data fetching mechanism. See [GROQ Query Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#53-groq-query-architecture).

---

# Chapter 14: Understanding the Sanity Content API

```text
Next.js
    │
    │ HTTPS GET
    ▼
Sanity Content API
    │
    │ GROQ Query
    ▼
Sanity Dataset
```

Endpoint format:

```text
https://{projectId}.api.sanity.io/{apiVersion}/data/query/{dataset}
```

Example:

```text
https://abc123.api.sanity.io/v2026-06-28/data/query/production
```

> 🔗 **Architecture**: The Content API is the primary interface between Sanity and your portfolio. See [Communications Interfaces](sandbox:///mnt/agents/output/architecture-nextjs16.md#24-communications-interfaces).

---

# Chapter 15: Image Pipeline Architecture

```text
Upload to Sanity
    ↓
Original Image Stored
    ↓
Sanity Image CDN
    ↓
On-Demand Transformations:
    • Resize (width, height)
    • Crop (focal point, hotspot)
    • Format (WebP, AVIF, JPEG)
    • Quality adjustment
    ↓
Browser receives optimized image
```

## Using the Image URL Builder

```typescript
import imageUrlBuilder from "@sanity/image-url";

const builder = imageUrlBuilder(client);

// Generate optimized URL
const imageUrl = builder
  .image(coverImage)
  .width(800)
  .height(400)
  .format("webp")
  .quality(80)
  .url();
```

Available transformations:

| Method | Description | Example |
|--------|-------------|---------|
| `width()` | Resize width | `.width(800)` |
| `height()` | Resize height | `.height(400)` |
| `format()` | Output format | `.format("webp")` or `.format("auto")` |
| `quality()` | Compression (1-100) | `.quality(80)` |
| `crop()` | Crop mode | `.crop("focalpoint")` |
| `fit()` | Fit mode | `.fit("crop")` or `.fit("max")` |

> 🔗 **Architecture**: The image pipeline is critical for performance. See [Image Pipeline](sandbox:///mnt/agents/output/architecture-nextjs16.md#103-image-pipeline) and [Performance Requirements](sandbox:///mnt/agents/output/srd-nextjs16.md#51-performance-requirements).

---

# Chapter 16: Security Architecture

## Safe vs. Unsafe Variables

| Safe (Public) | Unsafe (Private) |
|---------------|------------------|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | `SANITY_API_TOKEN` |
| `NEXT_PUBLIC_SANITY_DATASET` | `SANITY_WEBHOOK_SECRET` |
| `NEXT_PUBLIC_SANITY_API_VERSION` | `EMAIL_API_KEY` |

## Architecture

```text
┌─────────────────┐
│     Browser     │  ← Only sees NEXT_PUBLIC_* variables
│   (Client-Side) │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│   Next.js 16    │  ← Server Components can access all env vars
│   (Server-Side) │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│   Sanity API    │  ← Requires SANITY_API_TOKEN
│   (Protected)   │
└─────────────────┘
```

**Rule**: Never expose private tokens to the browser.

> 🔗 **SRD**: API tokens must be stored as environment variables and never exposed client-side. See [NFR-08](sandbox:///mnt/agents/output/srd-nextjs16.md#52-security-requirements).

> 🔗 **Architecture**: See [Security Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#9-security-architecture).

---

# Chapter 17: Environment Variables

Create `.env.local` in your portfolio root:

```env
# Public (embedded in client bundle)
NEXT_PUBLIC_SANITY_PROJECT_ID=your-project-id
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-06-28

# Private (server-only)
SANITY_API_TOKEN=your-read-token
SANITY_WEBHOOK_SECRET=your-webhook-secret
```

> ⚠️ **Never commit `.env.local` to Git!** It's already in `.gitignore` by default.

Add to Vercel:

```bash
vercel env add NEXT_PUBLIC_SANITY_PROJECT_ID
vercel env add NEXT_PUBLIC_SANITY_DATASET
vercel env add SANITY_API_TOKEN
vercel env add SANITY_WEBHOOK_SECRET
```

> 🔗 **Architecture**: See [Environment Variable Security](sandbox:///mnt/agents/output/architecture-nextjs16.md#93-environment-variable-security).

---

# Chapter 18: Connecting Sanity to Next.js 16

## Step 1: Install Dependencies

```bash
npm install @sanity/client @sanity/image-url @portabletext/react next-sanity
```

## Step 2: Create the Sanity Client

```typescript
// lib/sanity.ts
import { createClient } from "@sanity/client";
import imageUrlBuilder from "@sanity/image-url";

const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET || "production",
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2026-06-28",
  useCdn: true,
});

const builder = imageUrlBuilder(client);

export function urlFor(source: any) {
  return builder.image(source);
}

export default client;
```

## Step 3: Define GROQ Queries

```typescript
// lib/groq-queries.ts
import { groq } from "next-sanity";

export const allPostsQuery = groq`
  *[_type == "blogPost" && publishedAt < now()] | order(publishedAt desc) {
    _id,
    title,
    "slug": slug.current,
    publishedAt,
    excerpt,
    coverImage,
    tags,
    "author": author-> { name, "avatar": avatar.asset->url }
  }
`;

export const postBySlugQuery = groq`
  *[_type == "blogPost" && slug.current == $slug][0] {
    _id,
    title,
    "slug": slug.current,
    publishedAt,
    excerpt,
    coverImage,
    tags,
    "author": author-> { name, bio, "avatar": avatar.asset->url },
    "categories": categories[]-> { title, "slug": slug.current },
    content
  }
`;

export const allProjectsQuery = groq`
  *[_type == "project"] | order(completedAt desc) {
    _id,
    title,
    "slug": slug.current,
    description,
    thumbnail,
    liveUrl,
    repoUrl,
    techStack,
    featured
  }
`;

export const authorQuery = groq`
  *[_type == "author"][0] {
    name,
    bio,
    avatar,
    email,
    socials
  }
`;
```

> 🔗 **Architecture**: GROQ queries are the primary data fetching mechanism. See [GROQ Query Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#53-groq-query-architecture).

---

# Chapter 19: Explicit Caching in Next.js 16

## The Old Model (Next.js 14)

```text
fetch()
   ↓
[implicit magic cache]
   ↓
export const revalidate = 60
```

Problems:
- Unclear what's cached
- Unclear when cache invalidates
- Page-level granularity only

## The New Model (Next.js 16)

```text
"use cache"
cacheTag("posts")
revalidateTag("posts")
```

Benefits:
- Explicit opt-in
- Tag-level granularity
- Predictable behavior
- Developer-controlled

## Example: Cached Data Loader

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

## Example: Using in a Page

```tsx
// app/blog/page.tsx
import { loadPosts } from "@/lib/loadPosts";

export default async function BlogPage() {
  const posts = await loadPosts();  // Automatically cached!

  return (
    <div>
      {posts.map((post: any) => (
        <article key={post._id}>
          <h2>{post.title}</h2>
        </article>
      ))}
    </div>
  );
}
```

> 🔗 **Architecture**: See [Caching & Revalidation](sandbox:///mnt/agents/output/architecture-nextjs16.md#6-caching--revalidation-nextjs-16).

> 🔗 **SRD**: Blog posts must be fetched via cached data loaders using `'use cache'`. See [FR-23](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching).

---

# Chapter 20: Cache Invalidation with Webhooks

## The Flow

```text
Publish in Sanity
   ↓
Webhook fires
   ↓
POST /api/revalidate
   ↓
Verify signature
   ↓
revalidateTag("posts")
revalidateTag("post:slug")
   ↓
Cache cleared instantly
   ↓
Next request fetches fresh data
```

## Revalidation Handler

```typescript
// app/api/revalidate/route.ts
import { revalidateTag } from "next/cache";
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  const secret = request.headers.get("x-sanity-webhook-secret");

  // Verify webhook signature
  if (secret !== process.env.SANITY_WEBHOOK_SECRET) {
    return NextResponse.json(
      { message: "Invalid webhook secret" },
      { status: 401 }
    );
  }

  const body = await request.json();
  const { _type, slug } = body;

  if (_type === "blogPost") {
    // Invalidate all posts
    revalidateTag("posts", "max");

    // Invalidate specific post
    if (slug?.current) {
      revalidateTag(`post:${slug.current}`, "max");
    }

    return NextResponse.json({
      revalidated: true,
      tags: ["posts", slug?.current ? `post:${slug.current}` : null].filter(Boolean),
    });
  }

  return NextResponse.json(
    { message: "Unknown content type" },
    { status: 400 }
  );
}
```

## Configure Sanity Webhook

1. Go to [sanity.io/manage](https://sanity.io/manage) → API → Webhooks
2. URL: `https://your-domain.com/api/revalidate`
3. Secret: Your `SANITY_WEBHOOK_SECRET`
4. Trigger on: Create, Update, Delete
5. Filter: `_type == "blogPost"`
6. Projection: `{ "_type": _type, "slug": slug }`

> 🔗 **Architecture**: Webhooks enable instant cache invalidation. See [Integration Layer](sandbox:///mnt/agents/output/architecture-nextjs16.md#24-communications-interfaces).

> 🔗 **SRD**: The system shall invalidate cache tags when content changes. See [FR-44 through FR-48](sandbox:///mnt/agents/output/srd-nextjs16.md#38-feature-cache-invalidation-nextjs-16).

---

# Chapter 21: Preview and Draft Mode

## Public vs. Draft Content

```text
┌─────────────────┐     ┌─────────────────┐
│  Published      │     │  Draft          │
│  (everyone)     │     │  (editors only) │
└─────────────────┘     └─────────────────┘
```

## Enabling Draft Mode

```typescript
// app/api/preview/route.ts
import { draftMode } from "next/headers";
import { redirect } from "next/navigation";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const secret = searchParams.get("secret");

  if (secret !== process.env.PREVIEW_SECRET) {
    return new Response("Invalid token", { status: 401 });
  }

  const draft = await draftMode();
  draft.enable();

  redirect("/blog");
}
```

## Fetching Draft Content

```typescript
// lib/sanity.ts
export const client = createClient({
  projectId,
  dataset,
  apiVersion,
  useCdn: false,  // Disable CDN for drafts
  token: process.env.SANITY_API_TOKEN,  // Need token for drafts
});

export const previewClient = createClient({
  projectId,
  dataset,
  apiVersion,
  useCdn: false,
  token: process.env.SANITY_API_TOKEN,
  perspective: "previewDrafts",  // Fetch drafts instead of published
});
```

## Using in Pages

```tsx
import { draftMode } from "next/headers";
import { client, previewClient } from "@/lib/sanity";

export default async function BlogPage() {
  const draft = await draftMode();
  const isDraftMode = draft.isEnabled;

  // Use preview client if in draft mode
  const posts = isDraftMode
    ? await previewClient.fetch(allPostsQuery)
    : await loadPosts();  // Cached version for production

  return (...);
}
```

---

# Chapter 22: Multi-Environment Deployment

```text
┌─────────────────┐
│  development    │  ← Local testing, useCdn: false
├─────────────────┤
│  staging        │  ← PR previews, useCdn: true
├─────────────────┤
│  preview        │  ← Vercel preview deployments
├─────────────────┤
│  production     │  ← Live site, useCdn: true
└─────────────────┘
```

## Creating Datasets

```bash
sanity dataset create staging
sanity dataset create production
```

## Environment Configuration

| Environment | Dataset | useCdn | Caching |
|-------------|---------|--------|---------|
| Development | `development` | `false` | Minimal |
| Staging | `staging` | `true` | `'use cache'` with short profiles |
| Production | `production` | `true` | `'use cache'` with long profiles |

> 🔗 **Architecture**: See [Environment Configuration](sandbox:///mnt/agents/output/architecture-nextjs16.md#82-environment-configuration).

---

# Chapter 23: Failure Handling

## What Happens if Sanity Fails?

```text
Sanity API offline
      ↓
Fetch failure
      ↓
Fallback to cached data
      ↓
Graceful degradation
```

## Implementation

```typescript
// lib/loadPosts.ts
import { cacheTag } from "next/cache";

export async function loadPosts() {
  "use cache";
  cacheTag("posts");

  try {
    const posts = await client.fetch(allPostsQuery);
    return posts;
  } catch (error) {
    console.error("Failed to fetch posts:", error);
    // Return empty array or cached fallback
    return [];
  }
}
```

## Error Boundaries

```tsx
// app/error.tsx
"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="container-custom py-16">
      <h2 className="text-2xl font-bold mb-4">Something went wrong!</h2>
      <p className="text-gray-600 mb-4">{error.message}</p>
      <button
        onClick={reset}
        className="px-6 py-3 bg-primary-600 text-white rounded-lg"
      >
        Try again
      </button>
    </div>
  );
}
```

> 🔗 **SRD**: Failed Sanity API requests shall fallback to cached/stale content. See [NFR-14](sandbox:///mnt/agents/output/srd-nextjs16.md#53-reliability--availability).

---

# Chapter 24: Observability

## What to Monitor

| Metric | Why It Matters |
|--------|--------------|
| API latency | Sanity response times |
| Cache hits | Effectiveness of `'use cache'` |
| Cache misses | Opportunities for optimization |
| Webhook failures | Content not updating |
| Query performance | Slow GROQ queries |
| Build times | Turbopack optimization |

## Implementation

```typescript
// lib/loadPosts.ts
import { cacheTag } from "next/cache";

export async function loadPosts() {
  "use cache";
  cacheTag("posts");

  const start = performance.now();

  try {
    const posts = await client.fetch(allPostsQuery);

    const duration = performance.now() - start;
    console.log({
      operation: "loadPosts",
      duration: `${duration.toFixed(2)}ms`,
      cache: "miss",  // This is a fresh fetch
      postCount: posts.length,
    });

    return posts;
  } catch (error) {
    console.error({
      operation: "loadPosts",
      error: error instanceof Error ? error.message : "Unknown",
      timestamp: new Date().toISOString(),
    });
    throw error;
  }
}
```

## Vercel Analytics

```bash
npm install @vercel/analytics
```

```tsx
// app/layout.tsx
import { Analytics } from "@vercel/analytics/react";

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  );
}
```

---

# Chapter 25: Testing

## Test Checklist

| Test | How |
|------|-----|
| Content creation | Create post in Sanity Studio, verify fields |
| API querying | Run GROQ in Vision tool, verify results |
| Image delivery | Check image URLs, verify WebP/AVIF |
| Cache invalidation | Publish post, verify webhook fires, check cache clears |
| Preview mode | Enable draft mode, verify unpublished content visible |
| Webhook execution | Check Vercel function logs |
| Error handling | Disconnect internet, verify graceful fallback |
| Responsive design | Test on mobile, tablet, desktop |
| Accessibility | Run Lighthouse, verify WCAG AA |

## Automated Testing

```typescript
// __tests__/loadPosts.test.ts
import { loadPosts } from "@/lib/loadPosts";

describe("loadPosts", () => {
  it("returns array of posts", async () => {
    const posts = await loadPosts();
    expect(Array.isArray(posts)).toBe(true);
  });

  it("each post has required fields", async () => {
    const posts = await loadPosts();
    if (posts.length > 0) {
      expect(posts[0]).toHaveProperty("title");
      expect(posts[0]).toHaveProperty("slug");
      expect(posts[0]).toHaveProperty("publishedAt");
    }
  });
});
```

---

# Chapter 26: SEO and Metadata

## Dynamic Metadata per Post

```tsx
// app/blog/[slug]/page.tsx
import { Metadata } from "next";
import { loadPostBySlug } from "@/lib/loadPosts";
import { urlFor } from "@/lib/sanity";

export async function generateMetadata({
  params,
}: {
  params: { slug: string };
}): Promise<Metadata> {
  const post = await loadPostBySlug(params.slug);

  return {
    title: `${post.title} | Your Name`,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: post.coverImage
        ? [{ url: urlFor(post.coverImage).width(1200).url() }]
        : [],
      type: "article",
      publishedTime: post.publishedAt,
      authors: [post.author?.name],
    },
    twitter: {
      card: "summary_large_image",
      title: post.title,
      description: post.excerpt,
      images: post.coverImage
        ? [urlFor(post.coverImage).width(1200).url()]
        : [],
    },
  };
}
```

## Structured Data (JSON-LD)

```tsx
// Add to blog post page
<script
  type="application/ld+json"
  dangerouslySetInnerHTML={{
    __html: JSON.stringify({
      "@context": "https://schema.org",
      "@type": "BlogPosting",
      headline: post.title,
      description: post.excerpt,
      image: urlFor(post.coverImage).url(),
      datePublished: post.publishedAt,
      author: {
        "@type": "Person",
        name: post.author?.name,
      },
    }),
  }}
/>
```

> 🔗 **SRD**: Posts must generate SEO-friendly URLs and Open Graph meta tags. See [FR-22, FR-26](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching).

---

# Chapter 27: Accessibility Requirements

## WCAG 2.1 Level AA Checklist

| Requirement | Implementation |
|-------------|----------------|
| **Color contrast** | Minimum 4.5:1 for normal text |
| **Keyboard navigation** | All interactive elements focusable |
| **Alt text** | Meaningful descriptions for all images |
| **Semantic HTML** | `<nav>`, `<main>`, `<article>`, `<footer>` |
| **Focus indicators** | Visible focus rings on all interactive elements |
| **Form labels** | Every input has associated `<label>` |
| **Heading hierarchy** | Logical h1 → h2 → h3 structure |
| **Skip links** | "Skip to content" link for keyboard users |

## Testing Accessibility

```bash
# Install axe-core
npm install @axe-core/react

# Or use Lighthouse in Chrome DevTools
# Lighthouse tab → Accessibility → Analyze
```

> 🔗 **SRD**: Color contrast ratios shall meet WCAG 2.1 Level AA. See [UI-04](sandbox:///mnt/agents/output/srd-nextjs16.md#41-user-interfaces).

---

# Chapter 28: Performance Budgets

## Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| First Contentful Paint (FCP) | < 1.0s | Lighthouse |
| Largest Contentful Paint (LCP) | < 2.5s | Lighthouse |
| Time to Interactive (TTI) | < 3.8s | Lighthouse |
| Cumulative Layout Shift (CLS) | < 0.1 | Lighthouse |
| Total Blocking Time (TBT) | < 200ms | Lighthouse |
| Lighthouse Performance Score | ≥ 90 | Lighthouse |

## Achieving Targets

| Strategy | Implementation |
|----------|----------------|
| **Static generation** | `'use cache'` + Server Components |
| **Image optimization** | `next/image` + Sanity Image CDN |
| **Font optimization** | `next/font` for self-hosted fonts |
| **Code splitting** | Automatic with Next.js 16 |
| **Edge caching** | Vercel's global edge network |
| **Prefetching** | `<Link prefetch>` for navigation |

> 🔗 **SRD**: Target Lighthouse Performance score ≥ 90. See [NFR-01](sandbox:///mnt/agents/output/srd-nextjs16.md#51-performance-requirements).

> 🔗 **Architecture**: See [Performance Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#10-performance-architecture).

---

# Chapter 29: Production Checklist

## Pre-Launch

- [ ] Schemas validated and tested
- [ ] References configured correctly
- [ ] API tokens secured (never in client bundle)
- [ ] Webhooks installed and tested
- [ ] Cache tags defined for all data types
- [ ] Preview mode enabled for editors
- [ ] Error boundaries implemented
- [ ] Loading states designed
- [ ] Fallback content for empty states

## Performance

- [ ] Lighthouse score ≥ 90
- [ ] Images optimized (WebP/AVIF)
- [ ] Fonts self-hosted and subsetted
- [ ] Core Web Vitals passing
- [ ] Bundle size analyzed

## Security

- [ ] Environment variables in Vercel (not in code)
- [ ] Webhook secrets verified
- [ ] CORS origins configured
- [ ] Security headers in `proxy.ts`
- [ ] Content Security Policy implemented

## Monitoring

- [ ] Vercel Analytics installed
- [ ] Error tracking configured
- [ ] Webhook logs verified
- [ ] Cache hit rates monitored

## Accessibility

- [ ] WCAG 2.1 AA compliance
- [ ] Keyboard navigation tested
- [ ] Screen reader tested
- [ ] Color contrast verified

---

# Chapter 30: Capstone Exercise

Extend the CMS with the following features. Each requires schema, GROQ, cache tags, and webhooks.

## 30.1 Categories

**Schema:**

```typescript
// studio/schemas/category.ts
export default defineType({
  name: "category",
  title: "Category",
  type: "document",
  fields: [
    defineField({ name: "title", type: "string", validation: Rule => Rule.required() }),
    defineField({ name: "slug", type: "slug", options: { source: "title" } }),
    defineField({ name: "description", type: "text" }),
  ],
});
```

**GROQ:**

```groq
*[_type == "category"] | order(title asc) {
  title,
  "slug": slug.current,
  "postCount": count(*[_type == "blogPost" && references(^._id)])
}
```

**Cache tag:** `cacheTag("categories")`

## 30.2 Series (Grouped Posts)

```typescript
// studio/schemas/series.ts
export default defineType({
  name: "series",
  title: "Series",
  type: "document",
  fields: [
    defineField({ name: "title", type: "string" }),
    defineField({ name: "slug", type: "slug" }),
    defineField({
      name: "posts",
      type: "array",
      of: [{ type: "reference", to: [{ type: "blogPost" }] }],
    }),
  ],
});
```

## 30.3 Testimonials

```typescript
// studio/schemas/testimonial.ts
export default defineType({
  name: "testimonial",
  title: "Testimonial",
  type: "document",
  fields: [
    defineField({ name: "name", type: "string" }),
    defineField({ name: "role", type: "string" }),
    defineField({ name: "company", type: "string" }),
    defineField({ name: "quote", type: "text" }),
    defineField({ name: "avatar", type: "image" }),
    defineField({ name: "featured", type: "boolean" }),
  ],
});
```

## 30.4 Experience Timeline

```typescript
// studio/schemas/experience.ts
export default defineType({
  name: "experience",
  title: "Experience",
  type: "document",
  fields: [
    defineField({ name: "title", type: "string" }),
    defineField({ name: "company", type: "string" }),
    defineField({ name: "location", type: "string" }),
    defineField({ name: "startDate", type: "date" }),
    defineField({ name: "endDate", type: "date" }),
    defineField({ name: "current", type: "boolean" }),
    defineField({ name: "description", type: "array", of: [{ type: "block" }] }),
    defineField({ name: "skills", type: "array", of: [{ type: "string" }] }),
  ],
});
```

## Implementation Checklist for Each Feature

- [ ] Create schema file in `studio/schemas/`
- [ ] Register in `studio/schemas/index.ts`
- [ ] Create GROQ query in `lib/groq-queries.ts`
- [ ] Create cached loader in `lib/loadPosts.ts` (or new file)
- [ ] Add cache tag (e.g., `cacheTag("testimonials")`)
- [ ] Create page/component to display data
- [ ] Add webhook handler for cache invalidation
- [ ] Test creation, update, and deletion
- [ ] Verify cache invalidation works

---

# Chapter 31: Next Steps

Continue with:

| Resource | What You'll Learn |
|----------|-------------------|
| [Portfolio Frontend Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-nextjs16.md) | Building the Next.js 16 frontend with explicit caching |
| [Blog Posts Tutorial](sandbox:///mnt/agents/output/blog-tutorial-nextjs16.md) | Writing content and bridging frontend + backend |
| [SRD](sandbox:///mnt/agents/output/srd-nextjs16.md) | Complete requirements specification |
| [Architecture Document](sandbox:///mnt/agents/output/architecture-nextjs16.md) | Technical decisions and system design |

## Advanced Topics

| Topic | Resource |
|-------|----------|
| Search | Algolia or Fuse.js client-side search |
| Comments | Giscus (GitHub Discussions) or Disqus |
| Newsletter | ConvertKit / Mailchimp signup |
| i18n | Next.js internationalized routing + Sanity localized fields |
| RSS Feed | Dynamic API route generating XML |
| Sitemap | Dynamic API route generating sitemap.xml |
| Open Graph Images | `@vercel/og` with cached dynamic generation |

---

# Final Thoughts

You have not merely installed a CMS.

You have built a modern content platform consisting of:

* a **content management system** (Sanity Studio),
* a **content API** (Sanity Content API + GROQ),
* a **caching layer** (Next.js 16 `'use cache'`),
* a **rendering engine** (React Server Components),
* a **revalidation system** (webhooks + `revalidateTag`),
* and a **production deployment architecture** (Vercel edge).

This architecture is the same fundamental pattern used by modern enterprise content platforms.

---

## Document Cross-References

| This Tutorial | References |
|---------------|------------|
| Why Sanity? | [Architecture: Technology Stack](sandbox:///mnt/agents/output/architecture-nextjs16.md#3-technology-stack) |
| Schema design | [Architecture: Content Model](sandbox:///mnt/agents/output/architecture-nextjs16.md#52-content-model-sanity-schemas) |
| Image CDN | [Architecture: Image Pipeline](sandbox:///mnt/agents/output/architecture-nextjs16.md#103-image-pipeline) |
| Security | [SRD: Security Requirements](sandbox:///mnt/agents/output/srd-nextjs16.md#52-security-requirements) |
| GROQ queries | [Architecture: GROQ Query Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#53-groq-query-architecture) |
| Caching | [Architecture: Caching & Revalidation](sandbox:///mnt/agents/output/architecture-nextjs16.md#6-caching--revalidation-nextjs-16) |
| Webhooks | [Architecture: Communications](sandbox:///mnt/agents/output/architecture-nextjs16.md#24-communications-interfaces) |
| Performance | [SRD: Performance Requirements](sandbox:///mnt/agents/output/srd-nextjs16.md#51-performance-requirements) |
| Portfolio connection | [Portfolio Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-nextjs16.md) |
| Blog posts | [Blog Tutorial](sandbox:///mnt/agents/output/blog-tutorial-nextjs16.md) |

---

*Happy building! 🚀 You now have a production-grade content platform powering your Next.js 16 portfolio.*
