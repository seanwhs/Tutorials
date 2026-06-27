# Tutorial: Writing Blog Posts with Sanity & Connecting Them to Your Portfolio

*A complete beginner's guide to creating content in Sanity Studio and displaying it on your Vercel-hosted portfolio — bridging the frontend and backend tutorials, aligned with the SRD and Architecture Document.*

---

## Before You Start

This tutorial is the **bridge** between two prior tutorials:
- **[Portfolio Website Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-revised.md)** — built the frontend (Next.js, Vercel)
- **[Sanity CMS Tutorial](sandbox:///mnt/agents/output/sanity-tutorial-revised.md)** — set up the content backend
- **This tutorial** — connects the two: write content → see it on your site

Formal reference documents:
- **[Software Requirements Document (SRD)](sandbox:///mnt/agents/output/srd.md)** — what the blog feature must do
- **[Architecture Document](sandbox:///mnt/agents/output/architecture.md)** — how data flows between Sanity and your portfolio

> 💡 **Tip:** 🔗 references point to formal documentation for deeper understanding.

---

## Table of Contents

1. [What You'll Build](#1-what-youll-build)
2. [Prerequisites](#2-prerequisites)
3. [The Data Flow: How It All Works](#3-the-data-flow-how-it-all-works)
4. [Part 1: Writing Your First Blog Post](#part-1-writing-your-first-blog-post)
5. [Part 2: Fetching Posts in Your Portfolio](#part-2-fetching-posts-in-your-portfolio)
6. [Part 3: Building the Blog Listing Page](#part-3-building-the-blog-listing-page)
7. [Part 4: Building Individual Post Pages](#part-4-building-individual-post-pages)
8. [Part 5: Adding Navigation](#part-5-adding-navigation)
9. [Part 6: ISR & Instant Updates](#part-6-isr--instant-updates)
10. [Part 7: Deploying to Vercel](#part-7-deploying-to-vercel)
11. [Common Issues & Solutions](#common-issues--solutions)
12. [Next Steps](#next-steps)

---

## 1. What You'll Build

A complete blogging system where:
- You write posts in **Sanity Studio** (rich text editor)
- Posts automatically appear on your **Vercel-hosted portfolio**
- New posts go live within **60 seconds** (or instantly with webhooks)
- Images are automatically optimized
- URLs are SEO-friendly

---

## 2. Prerequisites

Before starting, ensure you have:

- ✅ **Portfolio website** built with Next.js 14+ (App Router) and deployed on Vercel
- ✅ **Sanity project** with schemas configured (blogPost, project, author)
- ✅ **Sanity client** installed in your portfolio (`@sanity/client`, `@sanity/image-url`)
- ✅ **Environment variables** set up in `.env.local`
- ✅ Basic familiarity with React, TypeScript, and Tailwind CSS

> Haven't completed the prior tutorials? Go back to:
> - [Portfolio Website Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-revised.md)
> - [Sanity CMS Setup Tutorial](sandbox:///mnt/agents/output/sanity-tutorial-revised.md)

---

## 3. The Data Flow: How It All Works

Before writing code, understand how data moves from your brain to your visitor's screen:

```
┌─────────────────┐
│   You (Author)  │
│  Write in Studio│
└────────┬────────┘
         │ Click "Publish"
         ▼
┌─────────────────┐
│  Sanity Cloud   │
│  Content Stored │
│  + CDN Cached   │
└────────┬────────┘
         │ GROQ Query (HTTPS)
         ▼
┌─────────────────────────────────────────┐
│         Next.js Build / Runtime          │
│                                         │
│  Option A: Build Time (SSG)             │
│  • npm run build                        │
│  • fetch all posts from Sanity          │
│  • generate static HTML pages           │
│  • store in Vercel's edge cache        │
│                                         │
│  Option B: Runtime (ISR)               │
│  • visitor requests /blog               │
│  • serve cached version instantly       │
│  • revalidate in background (60s)       │
│  • update cache with fresh content     │
│                                         │
│  Option C: Webhook (Instant)           │
│  • publish in Sanity → trigger webhook  │
│  • Vercel revalidates specific pages   │
│  • new content visible immediately      │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  Vercel Edge    │
│  (Global CDN)   │
└────────┬────────┘
         │ Static HTML
         ▼
┌─────────────────┐
│ Visitor Browser │
│ (React hydrates)│
└─────────────────┘
```

> 🔗 **Architecture**: See the full [Data Flow Diagram](sandbox:///mnt/agents/output/architecture.md#52-data-flow) and [System Architecture](sandbox:///mnt/agents/output/architecture.md#2-system-architecture) for deeper technical details.

### Key Concepts

| Concept | What It Means | Why It Matters |
|---------|---------------|----------------|
| **SSG** (Static Site Generation) | HTML generated at build time | Fastest possible load times |
| **ISR** (Incremental Static Regeneration) | Rebuild pages in background without full redeploy | Content updates without waiting for build |
| **GROQ** | Sanity's query language | Fetch exactly the data you need |
| **Portable Text** | Rich text as structured JSON | Render flexibly in React |
| **CDN** | Content Delivery Network | Global, fast image/asset delivery |

---

## Part 1: Writing Your First Blog Post

### Step 1: Open Sanity Studio

Navigate to your deployed Sanity Studio URL:
```
https://your-project-id.sanity.studio
```

Or run locally:
```bash
cd studio
npm run dev
# Open http://localhost:3333
```

### Step 2: Create a New Post

1. Click **"Blog Post"** in the left sidebar
2. Click **"Create new Blog Post"** (top right)
3. Fill in each field:

| Field | What to Enter | Why It Matters |
|-------|---------------|----------------|
| **Title** | "My First Blog Post" | Displayed in listings and SEO |
| **Slug** | Click "Generate" → `my-first-blog-post` | URL: `/blog/my-first-blog-post` |
| **Published At** | Select now | Controls visibility and ordering |
| **Excerpt** | "A short summary..." | Shown on blog listing page |
| **Cover Image** | Upload an image (drag & drop) | Featured image, social sharing |
| **Content** | Write in the rich text editor | Full article body |
| **Tags** | `web-dev`, `tutorial` | Filtering and organization |

### Step 3: Using the Rich Text Editor

The content field uses **Portable Text** — Sanity's structured rich text format. You can:

- **Type paragraphs** — just start typing
- **Add headings** — select text, click the heading icon (H1, H2, H3)
- **Format text** — bold, italic, underline, code
- **Add lists** — bullet or numbered
- **Insert links** — select text, click link icon, enter URL
- **Add images** — click the image icon, upload or select existing
- **Add code blocks** — click the code icon, select language

> 🔗 **SRD**: Content must support paragraphs, headings, lists, links, inline images, and code blocks. See [FR-20](sandbox:///mnt/agents/output/srd.md#34-feature-blog-integrated-with-sanity-cms).

### Step 4: Publish

1. Review your post in the preview panel (if visible)
2. Click **"Publish"** (bottom right)
3. The post is now live in Sanity's database!

> 💡 **Draft vs. Publish**: Unpublished posts (saved as drafts) won't appear on your website. Only published posts are public.

> 🔗 **SRD**: Sanity Studio must support draft/publish workflow. See [FR-41](sandbox:///mnt/agents/output/srd.md#37-feature-content-management-sanity-studio).

### Step 5: Create a Few More Posts

For testing, create 2-3 posts with different content:
- One with a cover image
- One with inline images in the content
- One with a code block
- One with multiple tags

---

## Part 2: Fetching Posts in Your Portfolio

### Step 1: Verify Your Sanity Client

Ensure your portfolio has the Sanity client configured:

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

> 🔗 **Architecture**: The client configuration is documented in [Data Architecture](sandbox:///mnt/agents/output/architecture.md#5-data-architecture).

### Step 2: Define GROQ Queries

```typescript
// lib/groq-queries.ts
import { groq } from "next-sanity";

// Fetch all published blog posts, newest first
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

// Fetch a single post by slug (with full content)
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

> 🔗 **Architecture**: GROQ queries are the primary data fetching mechanism. See [GROQ Query Architecture](sandbox:///mnt/agents/output/architecture.md#53-groq-query-architecture).

### Step 3: Test the Query

Create a temporary test page to verify data flows correctly:

```tsx
// app/test-blog/page.tsx
import client from "@/lib/sanity";
import { allPostsQuery } from "@/lib/groq-queries";

export default async function TestBlogPage() {
  const posts = await client.fetch(allPostsQuery);

  return (
    <div className="container-custom py-16">
      <h1 className="text-2xl font-bold mb-4">API Test</h1>
      <p className="mb-4">Found {posts.length} posts:</p>
      <ul className="space-y-2">
        {posts.map((post: any) => (
          <li key={post._id} className="p-4 border rounded">
            <strong>{post.title}</strong>
            <span className="text-gray-500 ml-2">({post.slug})</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
```

Visit `http://localhost:3000/test-blog` — you should see your published posts!

If you see posts here but not on the actual blog pages, the issue is in the rendering code, not the data fetching.

---

## Part 3: Building the Blog Listing Page

The blog listing page (`/blog`) shows all your posts as cards.

### Step 1: Create the Page

```tsx
// app/blog/page.tsx
import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import client, { urlFor } from "@/lib/sanity";
import { allPostsQuery } from "@/lib/groq-queries";
import { formatDate } from "@/lib/utils";

export const metadata: Metadata = {
  title: "Blog | Your Name",
  description: "Thoughts on web development, design, and technology.",
};

// ISR: Revalidate this page every 60 seconds
export const revalidate = 60;

export default async function BlogPage() {
  const posts = await client.fetch(allPostsQuery);

  return (
    <div className="container-custom py-16">
      <h1 className="text-4xl font-bold mb-4">Blog</h1>
      <p className="text-gray-600 mb-12 text-lg">
        Thoughts on web development, design, and technology.
      </p>

      {posts.length === 0 ? (
        <p className="text-gray-500">No posts yet. Write your first one in Sanity Studio!</p>
      ) : (
        <div className="grid md:grid-cols-2 gap-8">
          {posts.map((post: any) => (
            <article
              key={post._id}
              className="group border rounded-xl overflow-hidden hover:shadow-lg transition-all duration-300"
            >
              {post.coverImage && (
                <div className="relative h-56 overflow-hidden">
                  <Image
                    src={urlFor(post.coverImage).width(800).height(400).url()}
                    alt={post.title}
                    fill
                    className="object-cover group-hover:scale-105 transition-transform duration-500"
                  />
                </div>
              )}

              <div className="p-6">
                <div className="text-sm text-gray-500 mb-2">
                  {formatDate(post.publishedAt)}
                </div>

                <h2 className="text-xl font-bold mb-2 group-hover:text-primary-600 transition-colors">
                  <Link href={`/blog/${post.slug}`}>
                    {post.title}
                  </Link>
                </h2>

                {post.excerpt && (
                  <p className="text-gray-600 mb-4 line-clamp-3">{post.excerpt}</p>
                )}

                {post.tags && (
                  <div className="flex flex-wrap gap-2">
                    {post.tags.map((tag: string) => (
                      <span
                        key={tag}
                        className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-xs font-medium"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
```

### Key Features Explained

| Feature | Code | Purpose |
|---------|------|---------|
| **ISR** | `export const revalidate = 60` | Page updates automatically every 60s |
| **Image optimization** | `urlFor(post.coverImage).width(800).height(400).url()` | Serve optimized WebP from Sanity CDN |
| **Hover effects** | `group-hover:scale-105` | Subtle zoom on card hover |
| **Empty state** | `posts.length === 0` | Friendly message when no posts exist |
| **Line clamp** | `line-clamp-3` | Limit excerpt to 3 lines |

> 🔗 **SRD**: Blog listing must show all published posts ordered by date with title, excerpt, cover image, and tags. See [FR-16, FR-17](sandbox:///mnt/agents/output/srd.md#34-feature-blog-integrated-with-sanity-cms).

> 🔗 **Architecture**: ISR strategy is documented in [Rendering Strategy](sandbox:///mnt/agents/output/architecture.md#43-rendering-strategy-by-route).

---

## Part 4: Building Individual Post Pages

Each blog post needs its own page at `/blog/[slug]`.

### Step 1: Create the Dynamic Route

```tsx
// app/blog/[slug]/page.tsx
import { Metadata } from "next";
import Image from "next/image";
import { PortableText } from "@portabletext/react";
import client, { urlFor } from "@/lib/sanity";
import { postBySlugQuery, allPostsQuery } from "@/lib/groq-queries";
import { formatDate } from "@/lib/utils";

// ISR: Revalidate every 60 seconds
export const revalidate = 60;

// Generate static pages for all posts at build time
export async function generateStaticParams() {
  const posts = await client.fetch(allPostsQuery);
  return posts.map((post: any) => ({
    slug: post.slug,
  }));
}

// Dynamic metadata for each post
export async function generateMetadata({
  params,
}: {
  params: { slug: string };
}): Promise<Metadata> {
  const post = await client.fetch(postBySlugQuery, { slug: params.slug });
  return {
    title: `${post.title} | Your Name`,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: post.coverImage ? [urlFor(post.coverImage).width(1200).url()] : [],
    },
  };
}

export default async function BlogPostPage({
  params,
}: {
  params: { slug: string };
}) {
  const post = await client.fetch(postBySlugQuery, { slug: params.slug });

  if (!post) {
    return (
      <div className="container-custom py-16">
        <h1 className="text-2xl font-bold">Post not found</h1>
        <p className="text-gray-600 mt-2">
          The post you're looking for doesn't exist or hasn't been published yet.
        </p>
      </div>
    );
  }

  return (
    <article className="container-custom py-16 max-w-3xl">
      {/* Post Header */}
      <header className="mb-8">
        <div className="text-sm text-gray-500 mb-2">
          {formatDate(post.publishedAt)}
        </div>

        <h1 className="text-4xl md:text-5xl font-bold mb-4">{post.title}</h1>

        {post.excerpt && (
          <p className="text-xl text-gray-600 italic leading-relaxed">{post.excerpt}</p>
        )}
      </header>

      {/* Cover Image */}
      {post.coverImage && (
        <div className="relative h-96 w-full mb-8 rounded-xl overflow-hidden">
          <Image
            src={urlFor(post.coverImage).width(1200).height(600).url()}
            alt={post.title}
            fill
            className="object-cover"
            priority
          />
        </div>
      )}

      {/* Tags */}
      {post.tags && (
        <div className="flex flex-wrap gap-2 mb-8">
          {post.tags.map((tag: string) => (
            <span
              key={tag}
              className="px-3 py-1 bg-primary-100 text-primary-800 rounded-full text-sm font-medium"
            >
              {tag}
            </span>
          ))}
        </div>
      )}

      {/* Post Content (Portable Text) */}
      <div className="prose prose-lg max-w-none prose-headings:font-bold prose-a:text-primary-600 prose-img:rounded-lg">
        <PortableText
          value={post.content}
          components={{
            types: {
              image: ({ value }: { value: any }) => (
                <div className="relative h-64 w-full my-6">
                  <Image
                    src={urlFor(value).width(800).url()}
                    alt={value.alt || "Blog image"}
                    fill
                    className="object-cover rounded-lg"
                  />
                </div>
              ),
              code: ({ value }: { value: any }) => (
                <pre className="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto my-6">
                  <code className="text-sm">{value.code}</code>
                </pre>
              ),
            },
          }}
        />
      </div>

      {/* Back to Blog Link */}
      <div className="mt-12 pt-8 border-t">
        <a
          href="/blog"
          className="text-primary-600 hover:text-primary-700 font-medium"
        >
          ← Back to all posts
        </a>
      </div>
    </article>
  );
}
```

### Key Features Explained

| Feature | Code | Purpose |
|---------|------|---------|
| **Static params** | `generateStaticParams` | Pre-build pages for known posts at build time |
| **Dynamic metadata** | `generateMetadata` | SEO title, description, OG image per post |
| **Portable Text** | `<PortableText>` | Renders rich text from Sanity's JSON format |
| **Custom components** | `components={{ types: { image, code } }}` | Override how images and code blocks render |
| **Prose styling** | `prose prose-lg` | Tailwind Typography plugin for article styling |

> 🔗 **SRD**: Individual posts must render full Portable Text content with images and code blocks. See [FR-19, FR-20](sandbox:///mnt/agents/output/srd.md#34-feature-blog-integrated-with-sanity-cms).

> 🔗 **SRD**: Posts must generate SEO-friendly URLs and Open Graph meta tags. See [FR-22, FR-25](sandbox:///mnt/agents/output/srd.md#34-feature-blog-integrated-with-sanity-cms).

### Install Tailwind Typography Plugin

```bash
npm install @tailwindcss/typography
```

Add to `tailwind.config.ts`:

```typescript
plugins: [require("@tailwindcss/typography")],
```

---

## Part 5: Adding Navigation

Don't forget to let visitors find your blog! Update your navbar:

```tsx
// components/layout/Navbar.tsx (add to navLinks array)
const navLinks = [
  { href: "/", label: "Home" },
  { href: "/about", label: "About" },
  { href: "/projects", label: "Projects" },
  { href: "/blog", label: "Blog" },      // ← ADD THIS
  { href: "/contact", label: "Contact" },
];
```

> 🔗 **SRD**: Navigation must include a link to the blog section. See [FR-32](sandbox:///mnt/agents/output/srd.md#35-feature-navigation--layout).

---

## Part 6: ISR & Instant Updates

### Understanding ISR

With `export const revalidate = 60`:

1. Visitor requests `/blog`
2. Vercel serves the cached version instantly (fast!)
3. In the background, Vercel checks if content is stale (> 60 seconds old)
4. If stale, Vercel fetches fresh data from Sanity and updates the cache
5. Next visitor gets the updated version

This means:
- ✅ **Fast**: Visitors never wait for data fetching
- ✅ **Fresh**: Content updates within 60 seconds
- ✅ **Efficient**: No full rebuild needed

### The Problem with ISR Alone

If you publish a post and immediately share the link, the first visitor might see the old version (while revalidation happens in the background). The second visitor sees the new version.

### Solution: On-Demand Revalidation with Webhooks

For instant updates, set up a webhook that triggers revalidation immediately when you publish.

#### Step 1: Create the Revalidation API Route

```tsx
// app/api/revalidate/route.ts
import { revalidatePath } from "next/cache";
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  const secret = request.headers.get("x-sanity-webhook-secret");

  // Verify the webhook secret
  if (secret !== process.env.SANITY_WEBHOOK_SECRET) {
    return NextResponse.json(
      { message: "Invalid webhook secret" },
      { status: 401 }
    );
  }

  const body = await request.json();
  const { _type, slug } = body;

  if (_type === "blogPost") {
    // Revalidate the blog listing page
    revalidatePath("/blog");

    // Revalidate the specific post page
    if (slug?.current) {
      revalidatePath(`/blog/${slug.current}`);
    }

    return NextResponse.json({
      revalidated: true,
      paths: ["/blog", slug?.current ? `/blog/${slug.current}` : null].filter(Boolean),
    });
  }

  return NextResponse.json(
    { message: "Unknown content type" },
    { status: 400 }
  );
}
```

#### Step 2: Add the Webhook Secret to Vercel

```bash
vercel env add SANITY_WEBHOOK_SECRET
```

Generate a random secret:
```bash
openssl rand -base64 32
```

#### Step 3: Configure the Webhook in Sanity

1. Go to [sanity.io/manage](https://sanity.io/manage)
2. Select your project → **API** → **Webhooks**
3. Click **"Add webhook"**
4. Configure:

| Setting | Value |
|---------|-------|
| **URL** | `https://your-domain.com/api/revalidate` |
| **Secret** | Your `SANITY_WEBHOOK_SECRET` value |
| **Dataset** | `production` |
| **Trigger on** | ✅ Create, ✅ Update, ✅ Delete |
| **Filter** | `_type == "blogPost"` (optional, recommended) |
| **Projection** | Leave default or set to `{ "_type": _type, "slug": slug }` |

5. Save!

#### Step 4: Test the Webhook

1. Publish a new blog post in Sanity Studio
2. Check your Vercel function logs (Dashboard → Functions → `/api/revalidate`)
3. Visit your blog page — the new post should appear immediately!

> 🔗 **Architecture**: Webhooks are part of the Integration Layer. See [Communications Interfaces](sandbox:///mnt/agents/output/architecture.md#24-communications-interfaces) and [Deployment Architecture](sandbox:///mnt/agents/output/architecture.md#6-deployment-architecture).

> 🔗 **SRD**: Webhook communication must validate signatures. See [SI-04](sandbox:///mnt/agents/output/srd.md#43-software-interfaces) and [NFR-06](sandbox:///mnt/agents/output/srd.md#52-security-requirements).

---

## Part 7: Deploying to Vercel

### Step 1: Commit Your Changes

```bash
git add .
git commit -m "Add blog functionality with Sanity CMS integration"
git push origin main
```

### Step 2: Verify Environment Variables

In the Vercel dashboard:

1. Go to your project → **Settings** → **Environment Variables**
2. Ensure these are set:

| Variable | Environment |
|----------|-------------|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | Production, Preview, Development |
| `NEXT_PUBLIC_SANITY_DATASET` | Production, Preview, Development |
| `NEXT_PUBLIC_SANITY_API_VERSION` | Production, Preview, Development |
| `SANITY_API_TOKEN` | Production, Preview |
| `SANITY_WEBHOOK_SECRET` | Production, Preview |

> 🔗 **Architecture**: See [Environment Configuration](sandbox:///mnt/agents/output/architecture.md#62-environment-configuration) for environment-specific settings.

### Step 3: Deploy

Vercel will automatically deploy on push. Visit your live URL to verify:

1. `/blog` — listing page shows your posts
2. `/blog/your-post-slug` — individual post renders correctly
3. Images load and are optimized
4. Navigation works

### Step 4: Test the Full Flow

1. Write a new post in Sanity Studio
2. Publish it
3. Check that the webhook fired (Vercel logs)
4. Visit `/blog` — new post should appear
5. Click the post — full content should render

---

## Common Issues & Solutions

| Problem | Cause | Solution |
|---------|-------|----------|
| **Posts not showing** | Posts are drafts, not published | Click "Publish" in Sanity Studio |
| **Images not loading** | `urlFor()` not imported or image missing | Check `lib/sanity.ts` and verify image exists in Sanity |
| **Slug conflicts** | Two posts with same slug | Each slug must be unique; Sanity warns you |
| **Content not rendering** | `@portabletext/react` not installed | `npm install @portabletext/react` |
| **Environment variables not working** | Missing on Vercel or wrong prefix | Only `NEXT_PUBLIC_*` are client-side; redeploy after changes |
| **Webhook not triggering** | Wrong URL or secret mismatch | Check webhook URL and compare secrets character-by-character |
| **ISR not updating** | `revalidate` not exported or caching issue | Verify `export const revalidate = 60` is in the page file |
| **CORS errors** | Domain not allowed in Sanity | Add your Vercel domain to Sanity CORS origins |
| **Build fails** | TypeScript errors or missing dependencies | Run `npm run build` locally to catch errors early |

> 🔗 **SRD**: See [Common Issues & Solutions](sandbox:///mnt/agents/output/srd.md#common-issues--solutions) for additional troubleshooting.

---

## Next Steps

Your blog is live! Here's what you can explore next:

| Feature | How To |
|---------|--------|
| **Add pagination** | Use GROQ slice: `[0...10]`, `[10...20]` |
| **Add search** | Fuse.js client-side or Algolia |
| **Add comments** | Giscus (GitHub Discussions) or Disqus |
| **Add newsletter** | ConvertKit/Mailchimp signup form |
| **RSS feed** | Dynamic API route at `/api/rss` |
| **Sitemap** | Dynamic API route at `/api/sitemap` |
| **Open Graph images** | `@vercel/og` for dynamic social cards |
| **Reading time** | Calculate from `pt::text(content)` length |
| **Related posts** | GROQ query matching tags |
| **Draft previews** | Preview mode with Sanity's draft API |

---

## Document Cross-References

| This Tutorial | References |
|---------------|------------|
| Data flow | [Architecture: Data Flow](sandbox:///mnt/agents/output/architecture.md#52-data-flow), [System Architecture](sandbox:///mnt/agents/output/architecture.md#2-system-architecture) |
| ISR strategy | [Architecture: Rendering Strategy](sandbox:///mnt/agents/output/architecture.md#43-rendering-strategy-by-route) |
| GROQ queries | [Architecture: GROQ Query Architecture](sandbox:///mnt/agents/output/architecture.md#53-groq-query-architecture) |
| Image handling | [Architecture: Image Pipeline](sandbox:///mnt/agents/output/architecture.md#83-image-pipeline) |
| Security | [SRD: Security Requirements](sandbox:///mnt/agents/output/srd.md#52-security-requirements), [Architecture: Security](sandbox:///mnt/agents/output/architecture.md#7-security-architecture) |
| Blog requirements | [SRD: Blog Features](sandbox:///mnt/agents/output/srd.md#34-feature-blog-integrated-with-sanity-cms) |
| Webhooks | [Architecture: Communications](sandbox:///mnt/agents/output/architecture.md#24-communications-interfaces) |
| Deployment | [Architecture: Deployment](sandbox:///mnt/agents/output/architecture.md#6-deployment-architecture) |
| Portfolio tutorial | [Portfolio Website Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-revised.md) |
| Sanity tutorial | [Sanity CMS Tutorial](sandbox:///mnt/agents/output/sanity-tutorial-revised.md) |

---

*Happy blogging! 📝 Your portfolio is now a living platform where content flows seamlessly from Sanity Studio to your Vercel-hosted website.*
