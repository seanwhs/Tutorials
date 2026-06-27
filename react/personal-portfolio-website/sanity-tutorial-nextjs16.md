# Tutorial: Setting Up Sanity CMS for Your Portfolio (Next.js 16)

*A complete beginner's guide to configuring Sanity CMS as the headless content backend for your Next.js 16 portfolio website — aligned with the project's Software Requirements Document (SRD) and Architecture Document.*

---

## Before You Start

This tutorial is part of a multi-document system:
- **[Portfolio Website Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-nextjs16.md)** — how to build the Next.js 16 frontend
- **This tutorial** — how to set up the content management backend
- **[Blog Posts with Sanity Tutorial](sandbox:///mnt/agents/output/blog-tutorial-nextjs16.md)** — how to write blog posts and bridge frontend + backend
- **[Software Requirements Document (SRD)](sandbox:///mnt/agents/output/srd-nextjs16.md)** — what the system must do
- **[Architecture Document](sandbox:///mnt/agents/output/architecture-nextjs16.md)** — how the system is structured

> 💡 **Key context**: Next.js 16 uses **explicit caching** (`'use cache'`, `cacheTag`, `revalidateTag`). This tutorial sets up Sanity to work with that caching model.

---

## Table of Contents

1. [What is Sanity & Why Use It?](#1-what-is-sanity--why-use-it)
2. [Prerequisites](#2-prerequisites)
3. [Creating Your Sanity Project](#3-creating-your-sanity-project)
4. [Defining Content Schemas](#4-defining-content-schemas)
5. [Sanity Studio Configuration](#5-sanity-studio-configuration)
6. [Setting Up the Content API](#6-setting-up-the-content-api)
7. [Image Handling & CDN](#7-image-handling--cdn)
8. [Security & Access Control](#8-security--access-control)
9. [Deploying Sanity Studio](#9-deploying-sanity-studio)
10. [Connecting to Your Next.js 16 Portfolio](#10-connecting-to-your-nextjs-16-portfolio)
11. [Testing Your Setup](#11-testing-your-setup)
12. [Next Steps](#12-next-steps)

---

## 1. What is Sanity & Why Use It?

**Sanity** is a headless Content Management System (CMS). "Headless" means it manages content but doesn't care about how that content is displayed — your portfolio website (the "head") handles presentation.

### Why We Chose Sanity

| Reason | Benefit |
|--------|---------|
| **Structured content** | Define exactly what fields each piece of content has |
| **GROQ queries** | Powerful, flexible query language for fetching content |
| **Image pipeline** | Automatic optimization, cropping, and format conversion |
| **Real-time collaboration** | Multiple editors can work simultaneously |
| **Generous free tier** | Perfect for personal portfolios |
| **Portable Text** | Rich text stored as structured JSON, not HTML |
| **Webhook support** | Trigger Next.js 16 `revalidateTag` on content changes |

### How It Fits with Next.js 16

```
[You] → [Sanity Studio] → [Sanity Cloud] → [Content API] → [Next.js 16 Portfolio]
  writes      manages         stores          serves           displays
                                                   │
                                                   ▼ Webhook
                                            [revalidateTag]
                                            ['posts', 'post:slug']
```

> 🔗 **Architecture**: See the full [System Context Diagram](sandbox:///mnt/agents/output/architecture-nextjs16.md#21-high-level-architecture).

---

## 2. Prerequisites

- **Node.js 20.9+** (required for Next.js 16)
- **npm**
- A **Sanity account** ([Sign up free](https://www.sanity.io/get-started))
- Basic command line familiarity
- Your portfolio project created (from the [Portfolio Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-nextjs16.md))

---

## 3. Creating Your Sanity Project

### Step 1: Install Sanity CLI

```bash
npm install -g @sanity/cli
```

### Step 2: Initialize a New Sanity Project

In your portfolio project's root directory (or a sibling directory), run:

```bash
sanity init
```

Follow the prompts:

| Prompt | Recommended Answer |
|--------|-------------------|
| Create new project or select existing? | **Create new project** |
| Project name | `portfolio-cms` |
| Use default dataset? | **Yes** (creates `production` dataset) |
| Project output path | `studio` |
| Select project template | **Clean project with no predefined schemas** |
| Would you like to add configuration files? | **Yes** |

### Step 3: Install Dependencies

```bash
cd studio
npm install
```

### Step 4: Start Sanity Studio Locally

```bash
npm run dev
```

Open `http://localhost:3333`.

---

## 4. Defining Content Schemas

> 🔗 **SRD**: Content schemas must support blog posts, projects, and author information. See [Data Requirements](sandbox:///mnt/agents/output/srd-nextjs16.md#6-data-requirements).

### Step 1: Create the Blog Post Schema

Create `studio/schemas/blogPost.ts`:

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
      name: "publishedAt",
      title: "Published At",
      type: "datetime",
      initialValue: () => new Date().toISOString(),
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "excerpt",
      title: "Excerpt",
      type: "text",
      rows: 3,
      description: "A short summary shown on the blog listing page",
    }),
    defineField({
      name: "coverImage",
      title: "Cover Image",
      type: "image",
      options: {
        hotspot: true,
      },
    }),
    defineField({
      name: "content",
      title: "Content",
      type: "array",
      of: [
        { type: "block" },
        { type: "image" },
        { type: "code" },
      ],
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
  ],
  preview: {
    select: {
      title: "title",
      publishedAt: "publishedAt",
      media: "coverImage",
    },
    prepare({ title, publishedAt, media }) {
      return {
        title,
        subtitle: publishedAt
          ? new Date(publishedAt).toLocaleDateString()
          : "No date",
        media,
      };
    },
  },
});
```

> 🔗 **SRD**: Blog posts must enforce required fields: title, slug, publishedAt, content. See [FR-38](sandbox:///mnt/agents/output/srd-nextjs16.md#37-feature-content-management-sanity-studio).

### Step 2: Create the Project Schema

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
      description: "Show this project prominently on the home page",
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

### Step 3: Create the Author Schema

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

### Step 4: Register All Schemas

```typescript
// studio/schemas/index.ts
import blogPost from "./blogPost";
import project from "./project";
import author from "./author";

export const schemaTypes = [blogPost, project, author];
```

### Step 5: Restart Sanity Studio

```bash
npm run dev
```

You should now see **Blog Post**, **Project**, and **Author** in the left sidebar! 🎉

> 🔗 **Architecture**: These schemas define the [Content Model](sandbox:///mnt/agents/output/architecture-nextjs16.md#52-content-model-sanity-schemas).

---

## 5. Sanity Studio Configuration

```typescript
// studio/sanity.config.ts
import { defineConfig } from "sanity";
import { deskTool } from "sanity/desk";
import { visionTool } from "@sanity/vision";
import { schemaTypes } from "./schemas";

export default defineConfig({
  name: "portfolio-studio",
  title: "Portfolio CMS",
  projectId: "your-project-id",
  dataset: "production",
  plugins: [deskTool(), visionTool()],
  schema: {
    types: schemaTypes,
  },
});
```

> 🔗 **Architecture**: The `projectId` and `dataset` are critical configuration values. See [Environment Variables](sandbox:///mnt/agents/output/architecture-nextjs16.md#appendix-b-environment-variables).

---

## 6. Setting Up the Content API

### API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `https://{projectId}.api.sanity.io/v2026-06-28/data/query/{dataset}` | GROQ queries |
| `https://cdn.sanity.io/images/{projectId}/{dataset}/` | Image CDN |

> 🔗 **Architecture**: The Content API is the primary interface between Sanity and your portfolio. See [Communications Interfaces](sandbox:///mnt/agents/output/architecture-nextjs16.md#24-communications-interfaces).

---

## 7. Image Handling & CDN

Sanity's Image CDN automatically:
1. Stores the original high-resolution image
2. Generates optimized versions on-demand (WebP, AVIF)
3. Crops around a focal point (hotspot)
4. Delivers from a global CDN

### Using the Image URL Builder

```typescript
import imageUrlBuilder from "@sanity/image-url";

const builder = imageUrlBuilder(client);

const imageUrl = builder
  .image(coverImage)
  .width(800)
  .height(400)
  .format("webp")
  .url();
```

> 🔗 **Architecture**: The image pipeline is critical for performance. See [Image Pipeline](sandbox:///mnt/agents/output/architecture-nextjs16.md#103-image-pipeline).

---

## 8. Security & Access Control

### API Tokens

1. Go to [sanity.io/manage](https://sanity.io/manage) → Your Project → **API** → **Tokens**
2. Click **"Add API token"**
3. Name: `Portfolio Read Token`
4. Permissions: **Viewer** (read-only)
5. Copy the token — you won't see it again!

> ⚠️ **Security Warning**: Never commit tokens to Git.

> 🔗 **SRD**: API tokens must be stored as environment variables and never exposed client-side. See [NFR-08](sandbox:///mnt/agents/output/srd-nextjs16.md#52-security-requirements).

### CORS Origins

Add your domains in Sanity Manage → **API** → **CORS Origins**:
- `http://localhost:3000` (development)
- `https://your-domain.com` (production)
- `https://*.vercel.app` (Vercel previews, optional)

---

## 9. Deploying Sanity Studio

```bash
cd studio
npm run deploy
```

This deploys to `https://your-project-id.sanity.studio`.

---

## 10. Connecting to Your Next.js 16 Portfolio

### Step 1: Install Dependencies (in Portfolio)

```bash
cd ../portfolio
npm install @sanity/client @sanity/image-url @portabletext/react next-sanity
```

### Step 2: Create the Sanity Client

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

### Step 3: Create Environment Variables

```bash
# .env.local
NEXT_PUBLIC_SANITY_PROJECT_ID=your-project-id
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-06-28
SANITY_API_TOKEN=your-read-token
SANITY_WEBHOOK_SECRET=your-webhook-secret
```

> 🔗 **Architecture**: See [Environment Variable Security](sandbox:///mnt/agents/output/architecture-nextjs16.md#93-environment-variable-security).

### Step 4: Define GROQ Queries

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
    tags
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
    content
  }
`;
```

### Step 5: Create Cached Data Loaders

```typescript
// lib/loadPosts.ts
import { cacheTag } from "next/cache";
import client from "./sanity";
import { allPostsQuery, postBySlugQuery } from "./groq-queries";

export async function loadPosts() {
  "use cache";
  cacheTag("posts");
  return client.fetch(allPostsQuery);
}

export async function loadPostBySlug(slug: string) {
  "use cache";
  cacheTag(`post:${slug}`);
  cacheTag("posts");
  return client.fetch(postBySlugQuery, { slug });
}
```

> 🔗 **Architecture**: Cached data loaders are the Next.js 16 pattern for fetching content. See [Data Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#54-cached-data-loaders).

---

## 11. Testing Your Setup

### Test 1: Create Content in Studio

1. Open your deployed studio
2. Click **"Blog Post"** → **"Create new Blog Post"**
3. Fill in all fields and click **Publish**

### Test 2: Query the API Directly

```
https://your-project-id.api.sanity.io/v2026-06-28/data/query/production?query=*[_type%20==%20%22blogPost%22]
```

### Test 3: Fetch from Your Portfolio

```tsx
// app/test/page.tsx
import { loadPosts } from "@/lib/loadPosts";

export default async function TestPage() {
  const posts = await loadPosts();

  return (
    <div className="container-custom py-16">
      <h1>API Test</h1>
      <p>Found {posts.length} posts:</p>
      <ul>
        {posts.map((post: any) => (
          <li key={post._id}>{post.title} ({post.slug})</li>
        ))}
      </ul>
    </div>
  );
}
```

> 🔗 **SRD**: Content must be fetchable via GROQ queries and renderable in the portfolio. See [FR-16, FR-19](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching).

---

## 12. Next Steps

| Next Step | Resource |
|-----------|----------|
| **Write blog posts** | [Blog Posts with Sanity Tutorial](sandbox:///mnt/agents/output/blog-tutorial-nextjs16.md) |
| **Build the portfolio frontend** | [Portfolio Website Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-nextjs16.md) |
| **Set up webhooks** | [Architecture: Webhooks](sandbox:///mnt/agents/output/architecture-nextjs16.md#24-communications-interfaces) |
| **Add more content types** | Extend schemas in `studio/schemas/` |

---

## Document Cross-References

| This Tutorial | References |
|---------------|------------|
| Why Sanity? | [Architecture: Technology Stack](sandbox:///mnt/agents/output/architecture-nextjs16.md#3-technology-stack) |
| Schema design | [Architecture: Content Model](sandbox:///mnt/agents/output/architecture-nextjs16.md#52-content-model-sanity-schemas) |
| Image CDN | [Architecture: Image Pipeline](sandbox:///mnt/agents/output/architecture-nextjs16.md#103-image-pipeline) |
| Security | [SRD: Security Requirements](sandbox:///mnt/agents/output/srd-nextjs16.md#52-security-requirements) |
| GROQ queries | [Architecture: GROQ Query Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#53-groq-query-architecture) |
| Cached loaders | [Architecture: Cached Data Loaders](sandbox:///mnt/agents/output/architecture-nextjs16.md#54-cached-data-loaders) |
| Portfolio connection | [Portfolio Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-nextjs16.md) |

---

*Your content backend is ready! 🎉 Next, write some content in Sanity Studio and watch it flow to your Next.js 16 portfolio.*
