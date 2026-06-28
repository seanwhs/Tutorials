# Tutorial: Writing Blog Posts with Sanity & Connecting Them to Your Next.js 16 Portfolio

*A complete beginner's guide to creating content in Sanity Studio and displaying it on your Vercel-hosted Next.js 16 portfolio — bridging the frontend and backend tutorials, aligned with the SRD and Architecture Document.*

---

## Before You Start

This tutorial is the **bridge** between two prior tutorials:
- **[Portfolio Website Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-nextjs16.md)** — built the Next.js 16 frontend (Vercel)
- **[Sanity CMS Tutorial](sandbox:///mnt/agents/output/sanity-tutorial-nextjs16.md)** — set up the content backend
- **This tutorial** — connects the two: write content → see it on your site

Formal reference documents:
- **[Software Requirements Document (SRD)](sandbox:///mnt/agents/output/srd-nextjs16.md)** — what the blog feature must do
- **[Architecture Document](sandbox:///mnt/agents/output/architecture-nextjs16.md)** — how data flows between Sanity and your portfolio

> 💡 **Key difference from older tutorials**: Next.js 16 uses **explicit caching** (`'use cache'`, `cacheTag`, `revalidateTag`) instead of ISR (`export const revalidate`). This tutorial shows the Next.js 16 patterns.

---

## Table of Contents

1. [What You'll Build](#1-what-youll-build)
2. [Prerequisites](#2-prerequisites)
3. [The Data Flow: How It All Works](#3-the-data-flow-how-it-all-works)
4. [Part 1: Writing Your First Blog Post](#part-1-writing-your-first-blog-post)
5. [Part 2: Fetching Posts with Explicit Caching](#part-2-fetching-posts-with-explicit-caching)
6. [Part 3: Building the Blog Listing Page](#part-3-building-the-blog-listing-page)
7. [Part 4: Building Individual Post Pages](#part-4-building-individual-post-pages)
8. [Part 5: Adding Navigation](#part-5-adding-navigation)
9. [Part 6: Cache Invalidation with Webhooks](#part-6-cache-invalidation-with-webhooks)
10. [Part 7: Deploying to Vercel](#part-7-deploying-to-vercel)
11. [Common Issues & Solutions](#common-issues--solutions)
12. [Next Steps](#next-steps)

---

## 1. What You'll Build

A complete blogging system where:
- You write posts in **Sanity Studio** (rich text editor)
- Posts automatically appear on your **Vercel-hosted Next.js 16 portfolio**
- New posts go live **instantly** via `revalidateTag` webhooks
- Images are automatically optimized
- URLs are SEO-friendly

---

## 2. Prerequisites

Before starting, ensure you have:

- ✅ **Portfolio website** built with Next.js 16 and deployed on Vercel
- ✅ **Sanity project** with schemas configured (blogPost, project, author)
- ✅ **Sanity client** installed in your portfolio (`@sanity/client`, `@sanity/image-url`)
- ✅ **Environment variables** set up in `.env.local`
- ✅ Basic familiarity with React, TypeScript, and Tailwind CSS

> Haven't completed the prior tutorials? Go back to:
> - [Portfolio Website Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-nextjs16.md)
> - [Sanity CMS Setup Tutorial](sandbox:///mnt/agents/output/sanity-tutorial-nextjs16.md)

---

## 3. The Data Flow: How It All Works

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
│         Next.js 16 Build / Runtime       │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Build Time (SSG)               │   │
│  │  • fetch all posts from Sanity  │   │
│  │  • generate static HTML pages   │   │
│  │  • cache with 'use cache'       │   │
│  │    + cacheTag('posts')           │   │
│  └─────────────────────────────────┘   │
│              OR                        │
│  ┌─────────────────────────────────┐   │
│  │  Runtime (Explicit Cache)       │   │
│  │  • visitor requests /blog        │   │
│  │  • serve from cache if fresh     │   │
│  │  • webhook calls revalidateTag   │   │
│  │    to clear stale cache          │   │
│  └─────────────────────────────────┘   │
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

> 🔗 **Architecture**: See the full [Data Flow Diagram](sandbox:///mnt/agents/output/architecture-nextjs16.md#52-data-flow) and [System Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#2-system-architecture).

### Key Next.js 16 Concepts

| Concept | What It Means | Why It Matters |
|---------|---------------|----------------|
| **'use cache'** | Opts a function into caching | Explicit control over what gets cached |
| **cacheTag** | Labels cached data for later invalidation | Target specific cache entries |
| **revalidateTag** | Clears cached entries by tag | Instant updates without full rebuild |
| **GROQ** | Sanity's query language | Fetch exactly the data you need |
| **Portable Text** | Rich text as structured JSON | Render flexibly in React |

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

The content field uses **Portable Text**. You can:
- **Type paragraphs** — just start typing
- **Add headings** — select text, click the heading icon
- **Format text** — bold, italic, underline, code
- **Add lists** — bullet or numbered
- **Insert links** — select text, click link icon
- **Add images** — click the image icon
- **Add code blocks** — click the code icon, select language

> 🔗 **SRD**: Content must support paragraphs, headings, lists, links, inline images, and code blocks. See [FR-20](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching).

### Step 4: Publish

1. Review your post
2. Click **"Publish"** (bottom right)
3. The post is now live in Sanity's database!

> 🔗 **SRD**: Sanity Studio must support draft/publish workflow. See [FR-42](sandbox:///mnt/agents/output/srd-nextjs16.md#37-feature-content-management-sanity-studio).

### Step 5: Create a Few More Posts

For testing, create 2-3 posts with different content.

---

## Part 2: Fetching Posts with Explicit Caching

### Step 1: Verify Your Cached Data Loaders

Ensure your portfolio has cached data loaders:

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

> 🔗 **Architecture**: Cached data loaders are the Next.js 16 pattern. See [Data Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#54-cached-data-loaders).

### Step 2: Test the Query

Create a temporary test page:

```tsx
// app/test-blog/page.tsx
import { loadPosts } from "@/lib/loadPosts";

export default async function TestBlogPage() {
  const posts = await loadPosts();

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

---

## Part 3: Building the Blog Listing Page

```tsx
// app/blog/page.tsx
import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { urlFor } from "@/lib/sanity";
import { loadPosts } from "@/lib/loadPosts";
import { formatDate } from "@/lib/utils";

export const metadata: Metadata = {
  title: "Blog | Your Name",
  description: "Thoughts on web development, design, and technology.",
};

export default async function BlogPage() {
  const posts = await loadPosts();  // Cached via 'use cache'

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
                  <Link href={`/blog/${post.slug}`}>{post.title}</Link>
                </h2>

                {post.excerpt && (
                  <p className="text-gray-600 mb-4 line-clamp-3">{post.excerpt}</p>
                )}

                {post.tags && (
                  <div className="flex flex-wrap gap-2">
                    {post.tags.map((tag: string) => (
                      <span key={tag} className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-xs font-medium">
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

> **Key difference from Next.js 14**: No `export const revalidate = 60`. Caching is in `loadPosts()` via `'use cache'`.

> 🔗 **SRD**: Blog listing must show all published posts ordered by date with title, excerpt, cover image, and tags. See [FR-16, FR-17](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching).

---

## Part 4: Building Individual Post Pages

```tsx
// app/blog/[slug]/page.tsx
import { Metadata } from "next";
import Image from "next/image";
import { PortableText } from "@portabletext/react";
import { urlFor } from "@/lib/sanity";
import { loadPostBySlug, loadPosts } from "@/lib/loadPosts";
import { formatDate } from "@/lib/utils";

// Generate static params at build time
export async function generateStaticParams() {
  const posts = await loadPosts();
  return posts.map((post: any) => ({
    slug: post.slug,
  }));
}

// Dynamic metadata
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
      images: post.coverImage ? [urlFor(post.coverImage).width(1200).url()] : [],
    },
  };
}

export default async function BlogPostPage({
  params,
}: {
  params: { slug: string };
}) {
  const post = await loadPostBySlug(params.slug);

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
      <header className="mb-8">
        <div className="text-sm text-gray-500 mb-2">
          {formatDate(post.publishedAt)}
        </div>
        <h1 className="text-4xl md:text-5xl font-bold mb-4">{post.title}</h1>
        {post.excerpt && (
          <p className="text-xl text-gray-600 italic leading-relaxed">{post.excerpt}</p>
        )}
      </header>

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

      {post.tags && (
        <div className="flex flex-wrap gap-2 mb-8">
          {post.tags.map((tag: string) => (
            <span key={tag} className="px-3 py-1 bg-primary-100 text-primary-800 rounded-full text-sm font-medium">
              {tag}
            </span>
          ))}
        </div>
      )}

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

      <div className="mt-12 pt-8 border-t">
        <a href="/blog" className="text-primary-600 hover:text-primary-700 font-medium">
          ← Back to all posts
        </a>
      </div>
    </article>
  );
}
```

> 🔗 **SRD**: Individual posts must render full Portable Text content with images and code blocks. See [FR-19, FR-20](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching).

> 🔗 **SRD**: Posts must generate SEO-friendly URLs and Open Graph meta tags. See [FR-22, FR-26](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching).

---

## Part 5: Adding Navigation

Update your navbar:

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

> 🔗 **SRD**: Navigation must include a link to the blog section. See [FR-33](sandbox:///mnt/agents/output/srd-nextjs16.md#36-feature-navigation--layout).

---

## Part 6: Cache Invalidation with Webhooks

This is the key Next.js 16 difference. Instead of ISR revalidation intervals, we use **tag-based invalidation** triggered by Sanity webhooks.

### Understanding the Flow

```
[Publish in Sanity] → [Webhook fires] → [POST /api/revalidate]
                                              │
                                              ▼
                                    [Verify signature]
                                              │
                                              ▼
                                    [revalidateTag('posts', 'max')]
                                    [revalidateTag('post:slug', 'max')]
                                              │
                                              ▼
                                    [Cache cleared instantly]
```

### Step 1: Create the Revalidation API Route

```tsx
// app/api/revalidate/route.ts
import { revalidateTag } from "next/cache";
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
    // Invalidate the posts listing
    revalidateTag("posts", "max");

    // Invalidate the specific post
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

> 🔗 **Architecture**: `revalidateTag(tag, 'max')` immediately clears cached entries. See [Caching Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#6-caching--revalidation-nextjs-16).

> 🔗 **SRD**: The system shall invalidate the `posts` cache tag and specific `post:{slug}` tags when content changes. See [FR-44 through FR-48](sandbox:///mnt/agents/output/srd-nextjs16.md#38-feature-cache-invalidation-nextjs-16).

### Step 2: Add the Webhook Secret to Vercel

```bash
vercel env add SANITY_WEBHOOK_SECRET
```

Generate a random secret:
```bash
openssl rand -base64 32
```

### Step 3: Configure the Webhook in Sanity

1. Go to [sanity.io/manage](https://sanity.io/manage)
2. Select your project → **API** → **Webhooks**
3. Click **"Add webhook"**
4. Configure:

| Setting | Value |
|---------|-------|
| **URL** | `https://your-domain.com/api/revalidate` |
| **Secret** | Your `SANITY_WEBHOOK_SECRET` |
| **Dataset** | `production` |
| **Trigger on** | ✅ Create, ✅ Update, ✅ Delete |
| **Filter** | `_type == "blogPost"` |
| **Projection** | `{ "_type": _type, "slug": slug }` |

5. Save!

### Step 4: Test the Webhook

1. Publish a new blog post in Sanity Studio
2. Check your Vercel function logs (Dashboard → Functions → `/api/revalidate`)
3. Visit your blog page — the new post should appear **immediately**!

> 🔗 **Architecture**: Webhooks enable instant cache invalidation. See [Integration Layer](sandbox:///mnt/agents/output/architecture-nextjs16.md#24-communications-interfaces).

---

## Part 7: Deploying to Vercel

### Step 1: Commit Your Changes

```bash
git add .
git commit -m "Add blog with Next.js 16 explicit caching and webhooks"
git push origin main
```

### Step 2: Verify Environment Variables

In the Vercel dashboard:

| Variable | Environment |
|----------|-------------|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | Production, Preview, Development |
| `NEXT_PUBLIC_SANITY_DATASET` | Production, Preview, Development |
| `NEXT_PUBLIC_SANITY_API_VERSION` | Production, Preview, Development |
| `SANITY_API_TOKEN` | Production, Preview |
| `SANITY_WEBHOOK_SECRET` | Production, Preview |

> 🔗 **Architecture**: See [Environment Configuration](sandbox:///mnt/agents/output/architecture-nextjs16.md#82-environment-configuration).

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
4. Visit `/blog` — new post should appear **instantly**
5. Click the post — full content should render

---

## Common Issues & Solutions

| Problem | Cause | Solution |
|---------|-------|----------|
| **Posts not showing** | Posts are drafts, not published | Click "Publish" in Sanity Studio |
| **Images not loading** | `urlFor()` not imported or image missing | Check `lib/sanity.ts` |
| **Slug conflicts** | Two posts with same slug | Each slug must be unique |
| **Content not rendering** | `@portabletext/react` not installed | `npm install @portabletext/react` |
| **Environment variables not working** | Missing on Vercel or wrong prefix | Only `NEXT_PUBLIC_*` are client-side |
| **Webhook not triggering** | Wrong URL or secret mismatch | Check webhook URL and secrets |
| **Cache not invalidating** | `revalidateTag` not called | Check Vercel function logs |
| **CORS errors** | Domain not allowed in Sanity | Add your Vercel domain to CORS origins |
| **Build fails** | TypeScript errors or missing dependencies | Run `npm run build` locally |

> 🔗 **SRD**: See [Common Issues](sandbox:///mnt/agents/output/srd-nextjs16.md#common-issues--solutions).

---

## Next Steps

Your blog is live! Here's what you can explore next:

| Feature | How To |
|---------|--------|
| **Add pagination** | Use GROQ slice: `[0...10]`, `[10...20]` |
| **Add search** | Fuse.js or Algolia |
| **Add comments** | Giscus |
| **RSS feed** | Dynamic route at `/api/rss` |
| **Sitemap** | Dynamic route at `/api/sitemap` |
| **Open Graph images** | `@vercel/og` with cached dynamic generation |

---

## Document Cross-References

| This Tutorial | References |
|---------------|------------|
| Data flow | [Architecture: Data Flow](sandbox:///mnt/agents/output/architecture-nextjs16.md#52-data-flow) |
| Caching strategy | [Architecture: Caching & Revalidation](sandbox:///mnt/agents/output/architecture-nextjs16.md#6-caching--revalidation-nextjs-16) |
| GROQ queries | [Architecture: GROQ Query Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#53-groq-query-architecture) |
| Image handling | [Architecture: Image Pipeline](sandbox:///mnt/agents/output/architecture-nextjs16.md#103-image-pipeline) |
| Security | [SRD: Security Requirements](sandbox:///mnt/agents/output/srd-nextjs16.md#52-security-requirements) |
| Blog requirements | [SRD: Blog Features](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching) |
| Webhooks | [Architecture: Communications](sandbox:///mnt/agents/output/architecture-nextjs16.md#24-communications-interfaces) |
| Deployment | [Architecture: Deployment](sandbox:///mnt/agents/output/architecture-nextjs16.md#8-deployment-architecture) |
| Portfolio tutorial | [Portfolio Website Tutorial](sandbox:///mnt/agents/output/portfolio-tutorial-nextjs16.md) |
| Sanity tutorial | [Sanity CMS Tutorial](sandbox:///mnt/agents/output/sanity-tutorial-nextjs16.md) |

---

*Happy blogging with Next.js 16! 📝 Your portfolio uses explicit, developer-controlled caching for instant, predictable content updates.*
