# Tutorial: Setting Up Sanity CMS for Your Portfolio

*A complete beginner's guide to configuring Sanity CMS as the headless content backend for your portfolio website — aligned with the project's Software Requirements Document (SRD) and Architecture Document.*

---

## Before You Start

This tutorial is part of a multi-document system:
- **[Portfolio Website Tutorial](1-portfolio-tutorial.md)** — how to build the frontend
- **This tutorial** — how to set up the content management backend
- **[Blog Posts with Sanity Tutorial](3-blog-tutorial-revised.md)** — how to write blog posts and bridge frontend + backend
- **[Software Requirements Document (SRD)](srd-portfolio.md)** — what the system must do
- **[Architecture Document](architecture-portfolio.md)** — how the system is structured

> 💡 **Tip:** When you see a 🔗 **Architecture** or 🔗 **SRD** reference, that decision is formally documented there. You don't need to read them now, but they're available for deeper understanding.

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
10. [Connecting to Your Portfolio](#10-connecting-to-your-portfolio)
11. [Testing Your Setup](#11-testing-your-setup)
12. [Next Steps](#12-next-steps)

---

## 1. What is Sanity & Why Use It?

**Sanity** is a headless Content Management System (CMS). "Headless" means it manages content but doesn't care about how that content is displayed — your portfolio website (the "head") handles presentation.

### Why We Chose Sanity

| Reason | Benefit | 🔗 Architecture |
|--------|---------|----------------|
| **Structured content** | Define exactly what fields each piece of content has | [Content Model](sandbox:///mnt/agents/output/architecture.md#52-content-model-sanity-schemas) |
| **GROQ queries** | Powerful, flexible query language for fetching content | [Data Architecture](sandbox:///mnt/agents/output/architecture.md#53-groq-query-architecture) |
| **Image pipeline** | Automatic optimization, cropping, and format conversion | [Image Pipeline](sandbox:///mnt/agents/output/architecture.md#83-image-pipeline) |
| **Real-time collaboration** | Multiple editors can work simultaneously | — |
| **Generous free tier** | Perfect for personal portfolios | [Constraints](sandbox:///mnt/agents/output/srd.md#24-design--implementation-constraints) |
| **Portable Text** | Rich text stored as structured JSON, not HTML | [Constraints](sandbox:///mnt/agents/output/srd.md#24-design--implementation-constraints) |

### How It Fits in the Architecture

```
[You] → [Sanity Studio] → [Sanity Cloud] → [Content API] → [Your Portfolio]
  writes      manages         stores          serves           displays
```

> 🔗 **Architecture**: See the full [System Context Diagram](sandbox:///mnt/agents/output/architecture.md#21-high-level-architecture) for how Sanity fits into the broader system.

---

## 2. Prerequisites

- **Node.js** 18+ installed
- **npm** (comes with Node.js)
- A **Sanity account** ([Sign up free](https://www.sanity.io/get-started))
- Basic command line familiarity
- Your portfolio project created (from the [Portfolio Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-revised.md))

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
| Project name | `portfolio-cms` (or your preference) |
| Use default dataset? | **Yes** (creates `production` dataset) |
| Project output path | `studio` (this creates a `studio/` folder) |
| Select project template | **Clean project with no predefined schemas** |
| Would you like to add configuration files? | **Yes** |

This creates a `studio/` directory with:
- `sanity.config.ts` — main configuration
- `schemas/` — where content models live
- `package.json` — studio dependencies

### Step 3: Install Dependencies

```bash
cd studio
npm install
```

### Step 4: Start Sanity Studio Locally

```bash
npm run dev
```

Open `http://localhost:3333` in your browser. You should see the Sanity Studio interface — empty, because we haven't defined any content types yet.

> 🔗 **Architecture**: The studio runs locally during development. Later we'll deploy it so you can manage content from anywhere. See [Deployment Architecture](sandbox:///mnt/agents/output/architecture.md#6-deployment-architecture).

---

## 4. Defining Content Schemas

Schemas are the heart of Sanity. They define the structure of your content — what fields exist, what types they are, and how they're validated.

> 🔗 **SRD**: Content schemas must support blog posts, projects, and author information. See [Data Requirements](sandbox:///mnt/agents/output/srd.md#6-data-requirements).

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
        hotspot: true, // Enables cropping focal point
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
    defineField({
      name: "tags",
      title: "Tags",
      type: "array",
      of: [{ type: "string" }],
      options: {
        layout: "tags", // Display as tag chips in the studio
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

> 🔗 **SRD**: Blog posts must enforce required fields: title, slug, publishedAt, content. See [FR-37](sandbox:///mnt/agents/output/srd.md#37-feature-content-management-sanity-studio).

### Step 2: Create the Project Schema

Create `studio/schemas/project.ts`:

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

Create `studio/schemas/author.ts`:

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

Open `studio/schemas/index.ts` and register your schemas:

```typescript
// studio/schemas/index.ts
import blogPost from "./blogPost";
import project from "./project";
import author from "./author";

export const schemaTypes = [blogPost, project, author];
```

### Step 5: Restart Sanity Studio

Stop the studio (Ctrl+C) and restart:

```bash
npm run dev
```

You should now see **Blog Post**, **Project**, and **Author** in the left sidebar! 🎉

> 🔗 **Architecture**: These schemas define the [Content Model](sandbox:///mnt/agents/output/architecture.md#52-content-model-sanity-schemas) that your portfolio will query. Every field type, validation rule, and preview configuration is part of the formal data architecture.

---

## 5. Sanity Studio Configuration

Your `sanity.config.ts` should look like this:

```typescript
// studio/sanity.config.ts
import { defineConfig } from "sanity";
import { deskTool } from "sanity/desk";
import { visionTool } from "@sanity/vision";
import { schemaTypes } from "./schemas";

export default defineConfig({
  name: "portfolio-studio",
  title: "Portfolio CMS",

  projectId: "your-project-id", // You'll get this from Sanity
  dataset: "production",

  plugins: [deskTool(), visionTool()],

  schema: {
    types: schemaTypes,
  },
});
```

> 🔗 **Architecture**: The `projectId` and `dataset` are critical configuration values used by both the studio and your portfolio's API client. See [Environment Variables](sandbox:///mnt/agents/output/architecture.md#appendix-b-environment-variables).

### Where to Find Your Project ID

1. Go to [sanity.io/manage](https://sanity.io/manage)
2. Select your project
3. The Project ID is displayed at the top

Update `sanity.config.ts` with your real Project ID.

---

## 6. Setting Up the Content API

Sanity automatically exposes a Content API for fetching data. Your portfolio will use this API via the Sanity client.

### API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `https://{projectId}.api.sanity.io/v2026-06-28/data/query/{dataset}` | GROQ queries |
| `https://cdn.sanity.io/images/{projectId}/{dataset}/` | Image CDN |

> 🔗 **Architecture**: The Content API is the primary interface between Sanity and your portfolio. See [Communications Interfaces](sandbox:///mnt/agents/output/architecture.md#24-communications-interfaces).

### API Versioning

Always specify an API version date (e.g., `v2026-06-28`). This ensures your queries behave consistently even as Sanity evolves.

```typescript
// In your portfolio's sanity client
apiVersion: "2026-06-28", // Use today's date or your preferred version
```

> 🔗 **SRD**: API version must be specified for stability. See [SI-02](sandbox:///mnt/agents/output/srd.md#43-software-interfaces).

---

## 7. Image Handling & CDN

Sanity's Image CDN is one of its most powerful features. When you upload an image to Sanity, it:

1. Stores the original high-resolution image
2. Generates optimized versions on-demand (WebP, AVIF)
3. Crops around a focal point (if you set a hotspot)
4. Delivers from a global CDN

### How It Works

```
[Upload to Sanity] → [Original stored] → [Request with params] → [Optimized on-the-fly]
                                                          ↓
                                                    ?w=800&h=400&fit=crop&fm=webp
```

### Using the Image URL Builder

In your portfolio, you'll use `@sanity/image-url` to generate optimized URLs:

```typescript
import imageUrlBuilder from "@sanity/image-url";

const builder = imageUrlBuilder(client);

// Generate a URL with specific dimensions and format
const imageUrl = builder
  .image(coverImage)
  .width(800)
  .height(400)
  .format("webp")
  .url();
```

Available transformations:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `width()` | Resize width | `.width(800)` |
| `height()` | Resize height | `.height(400)` |
| `format()` | Output format | `.format("webp")` or `.format("auto")` |
| `quality()` | Compression quality | `.quality(80)` |
| `crop()` | Crop mode | `.crop("focalpoint")` |
| `fit()` | Fit mode | `.fit("crop")` or `.fit("max")` |

> 🔗 **Architecture**: The image pipeline is a critical performance optimization. See [Image Pipeline](sandbox:///mnt/agents/output/architecture.md#83-image-pipeline) and [Performance Requirements](sandbox:///mnt/agents/output/srd.md#51-performance-requirements).

---

## 8. Security & Access Control

### API Tokens

Your portfolio needs a token to fetch data from Sanity. Here's how to create one:

1. Go to [sanity.io/manage](https://sanity.io/manage) → Your Project → **API** → **Tokens**
2. Click **"Add API token"**
3. Name: `Portfolio Read Token`
4. Permissions: **Viewer** (read-only is safest for public sites)
5. Copy the token — you won't see it again!

> ⚠️ **Security Warning**: This token is like a password. Never commit it to Git or expose it in client-side code.

> 🔗 **SRD**: API tokens must be stored as environment variables and never exposed client-side. See [NFR-06, NFR-07](sandbox:///mnt/agents/output/srd.md#52-security-requirements).

### CORS Origins

Tell Sanity which domains are allowed to access your content:

1. Sanity Manage → **API** → **CORS Origins**
2. Add your development URL: `http://localhost:3000`
3. Add your production URL: `https://your-domain.com`
4. Add your Vercel preview URLs: `https://*.vercel.app` (optional)

> 🔗 **Architecture**: CORS configuration ensures only your domains can fetch content. See [Security Architecture](sandbox:///mnt/agents/output/architecture.md#7-security-architecture).

### Dataset Visibility

| Dataset | Visibility | Use Case |
|---------|------------|----------|
| `production` | Public (with token) | Live website content |
| `development` | Private | Testing, draft content |

For a portfolio, `production` is typically public-read. You can control this in Sanity Manage → **API** → **Datasets**.

---

## 9. Deploying Sanity Studio

### Why Deploy the Studio?

Right now, the studio only runs on your computer (`localhost:3333`). Deploying it lets you:
- Manage content from any device
- Collaborate with others (if needed)
- Have a permanent content management URL

### Deploy to Sanity's Hosting

Sanity provides free hosting for studios:

```bash
cd studio
npm run deploy
```

This will:
1. Build the studio
2. Deploy to `https://your-project-id.sanity.studio`
3. Give you a permanent URL to manage content

> 🔗 **Architecture**: The deployed studio is part of the Content Layer. See [System Architecture](sandbox:///mnt/agents/output/architecture.md#2-system-architecture).

### Alternative: Self-Host on Vercel

You can also embed the studio in your portfolio and deploy it alongside your site:

```typescript
// In your portfolio's next.config.js
// No special config needed — just import the studio as a route
```

For simplicity, we recommend Sanity's hosted studio for beginners.

---

## 10. Connecting to Your Portfolio

Now that Sanity is set up, your portfolio needs to connect to it.

### Step 1: Install Dependencies (in Portfolio)

```bash
cd ../portfolio  # Back to your portfolio directory
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
# .env.local (in your portfolio root)
NEXT_PUBLIC_SANITY_PROJECT_ID=your-project-id
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-06-28
SANITY_API_TOKEN=your-read-token
```

> 🔗 **Architecture**: See the [Environment Variable Security](sandbox:///mnt/agents/output/architecture.md#73-environment-variable-security) table for what should and shouldn't be public.

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

> 🔗 **Architecture**: GROQ queries are the primary data fetching mechanism. See [GROQ Query Architecture](sandbox:///mnt/agents/output/architecture.md#53-groq-query-architecture).

---

## 11. Testing Your Setup

### Test 1: Create Content in Studio

1. Open your deployed studio (`https://your-project-id.sanity.studio`)
2. Click **Blog Post** → **Create new Blog Post**
3. Fill in:
   - Title: "Hello World"
   - Slug: Click "Generate"
   - Published At: Now
   - Excerpt: "My first blog post"
   - Content: Write a few paragraphs
   - Tags: `web-dev`, `tutorial`
4. Click **Publish**

### Test 2: Query the API Directly

Visit this URL in your browser (replace `your-project-id`):

```
https://your-project-id.api.sanity.io/v2026-06-28/data/query/production?query=*[_type%20==%20%22blogPost%22]
```

You should see your blog post in JSON format!

### Test 3: Fetch from Your Portfolio

In your portfolio, create a test page:

```tsx
// app/test/page.tsx
import client from "@/lib/sanity";
import { allPostsQuery } from "@/lib/groq-queries";

export default async function TestPage() {
  const posts = await client.fetch(allPostsQuery);

  return (
    <div className="container-custom py-16">
      <h1>API Test</h1>
      <pre>{JSON.stringify(posts, null, 2)}</pre>
    </div>
  );
}
```

Visit `http://localhost:3000/test` — you should see your blog post data!

> 🔗 **SRD**: Content must be fetchable via GROQ queries and renderable in the portfolio. See [FR-16, FR-19](sandbox:///mnt/agents/output/srd.md#34-feature-blog-integrated-with-sanity-cms).

---

## 12. Next Steps

Your Sanity CMS is now configured and connected! Here's what to do next:

| Next Step | Resource |
|-----------|----------|
| **Write blog posts** | [Blog Posts with Sanity Tutorial](sandbox:///mnt/agents/output/blog-tutorial.md) |
| **Build the portfolio frontend** | [Portfolio Website Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-revised.md) |
| **Set up ISR webhooks** | [Architecture: Webhooks](sandbox:///mnt/agents/output/architecture.md#24-communications-interfaces) |
| **Add more content types** | Extend schemas in `studio/schemas/` |
| **Collaborate** | Add team members in Sanity Manage → **Members** |

---

## Quick Reference: Sanity Schema Cheat Sheet

```typescript
// Common field types
{
  name: "title",        type: "string"      // Text input
  name: "body",         type: "text"        // Textarea
  name: "count",        type: "number"      // Number input
  name: "isActive",     type: "boolean"     // Checkbox
  name: "publishedAt",   type: "datetime"    // Date/time picker
  name: "content",       type: "array"        // Rich text / blocks
  name: "image",         type: "image"        // Image upload
  name: "file",          type: "file"         // File upload
  name: "url",           type: "url"          // URL input
  name: "email",         type: "email"        // Email input
  name: "author",        type: "reference"    // Link to another document
  name: "tags",          type: "array"        // List of strings
}

// Validation
validation: (Rule) => Rule.required().min(10).max(100)

// Initial values
initialValue: () => new Date().toISOString()

// Conditional fields
hidden: ({ document }) => document?.type === "draft"
```

---

## Document Cross-References

| This Tutorial | References |
|---------------|------------|
| Why Sanity? | [Architecture: Technology Stack](sandbox:///mnt/agents/output/architecture.md#3-technology-stack), [SRD: Content Decoupling](sandbox:///mnt/agents/output/srd.md#24-design--implementation-constraints) |
| Schema design | [Architecture: Content Model](sandbox:///mnt/agents/output/architecture.md#52-content-model-sanity-schemas), [SRD: Data Requirements](sandbox:///mnt/agents/output/srd.md#6-data-requirements) |
| Image CDN | [Architecture: Image Pipeline](sandbox:///mnt/agents/output/architecture.md#83-image-pipeline) |
| Security | [SRD: Security Requirements](sandbox:///mnt/agents/output/srd.md#52-security-requirements), [Architecture: Security](sandbox:///mnt/agents/output/architecture.md#7-security-architecture) |
| GROQ queries | [Architecture: GROQ Query Architecture](sandbox:///mnt/agents/output/architecture.md#53-groq-query-architecture) |
| Portfolio connection | [Portfolio Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-revised.md), [Blog Tutorial](sandbox:///mnt/agents/output/blog-tutorial.md) |

---

*Your content backend is ready! 🎉 Next, write some content in Sanity Studio and watch it flow to your portfolio.*
