## Blog Tutorial - Part 10: SEO (Metadata, Sitemap, Robots.txt, Open Graph Images)

## What we're doing
We'll add a dynamic sitemap.xml, robots.txt, per-page canonical/OG metadata, and dynamically generated Open Graph share images using Next.js's built-in ImageResponse API (free, no external service needed).

## ⚠️ Next.js 16 reminder: the opengraph-image route is also a dynamic [slug] route

Since `opengraph-image.tsx` lives under `posts/[slug]/`, it receives the same `params: Promise<{ slug: string }>` shape as our page and metadata functions — it must be awaited too.

## Step 1: Add a site URL environment variable

Add to .env.local:

```bash
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

Later in Part 12 we'll set this to your real Vercel URL in production.

## Step 2: Improve root metadata with Open Graph defaults

Update src/app/layout.tsx metadata export:

```tsx
export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000"),
  title: {
    default: "My Blog",
    template: "%s | My Blog",
  },
  description: "A blog built with Next.js, Tailwind CSS, Sanity, and Clerk",
  openGraph: {
    type: "website",
    siteName: "My Blog",
  },
  twitter: {
    card: "summary_large_image",
  },
};
```

The `template: "%s | My Blog"` means any page that sets its own title (like our post pages) automatically gets " | My Blog" appended.

## Step 3: Add per-post Open Graph metadata (async params)

Update generateMetadata in src/app/posts/[slug]/page.tsx — this already awaits `params` per Part 5's pattern; we're just enriching what it returns:

```tsx
export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });
  if (!post) return {};

  return {
    title: post.title,
    description: post.excerpt,
    alternates: {
      canonical: `/posts/${post.slug.current}`,
    },
    openGraph: {
      title: post.title,
      description: post.excerpt,
      type: "article",
      publishedTime: post.publishedAt,
      authors: post.author?.name ? [post.author.name] : undefined,
      images: [`/posts/${post.slug.current}/opengraph-image`],
    },
    twitter: {
      card: "summary_large_image",
      title: post.title,
      description: post.excerpt,
    },
  };
}
```

## Step 4: Generate dynamic Open Graph images per post (async params)

Next.js can auto-generate an OG image file per route using a special file convention. Create src/app/posts/[slug]/opengraph-image.tsx:

```tsx
import { ImageResponse } from "next/og";
import { client } from "@/sanity/lib/client";
import { POST_QUERY } from "@/sanity/lib/queries";
import type { Post } from "@/sanity/lib/types";

export const runtime = "edge";
export const alt = "Blog post cover image";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function OpengraphImage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });

  return new ImageResponse(
    (
      <div
        style={{
          height: "100%",
          width: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "center",
          background: "linear-gradient(135deg, #1e293b, #0f172a)",
          color: "white",
          padding: "80px",
          textAlign: "center",
        }}
      >
        <div style={{ fontSize: 56, fontWeight: 700, lineHeight: 1.2 }}>
          {post?.title || "My Blog"}
        </div>
        <div style={{ marginTop: 24, fontSize: 28, color: "#94a3b8" }}>
          {post?.author?.name ? `By ${post.author.name}` : "My Blog"}
        </div>
      </div>
    ),
    { ...size }
  );
}
```

Next.js automatically wires this file up so that requests to /posts/[slug]/opengraph-image return a generated PNG — no external image hosting or design tool required. This works entirely on Vercel's free tier via Edge Functions. Just like our page and generateMetadata functions, `params` here is a Promise and must be awaited before destructuring `slug`.

## Step 5: Add a dynamic sitemap

Create src/app/sitemap.ts:

```ts
import type { MetadataRoute } from "next";
import { client } from "@/sanity/lib/client";
import { POST_SLUGS_QUERY, CATEGORY_SLUGS_QUERY } from "@/sanity/lib/queries";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";

  const [postSlugs, categorySlugs] = await Promise.all([
    client.fetch<string[]>(POST_SLUGS_QUERY),
    client.fetch<string[]>(CATEGORY_SLUGS_QUERY),
  ]);

  const postUrls = postSlugs.map((slug) => ({
    url: `${baseUrl}/posts/${slug}`,
    lastModified: new Date(),
  }));

  const categoryUrls = categorySlugs.map((slug) => ({
    url: `${baseUrl}/categories/${slug}`,
    lastModified: new Date(),
  }));

  return [
    { url: baseUrl, lastModified: new Date() },
    ...postUrls,
    ...categoryUrls,
  ];
}
```

`sitemap()` here takes no `params` argument at all (it's a whole-site file, not a dynamic route), so there's nothing to await here beyond our own Sanity fetches.

Visiting /sitemap.xml in the browser will now show a generated XML sitemap — Next.js handles the XML formatting automatically from this file.

## Step 6: Add robots.txt

Create src/app/robots.ts:

```ts
import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";

  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
        disallow: ["/studio", "/sign-in", "/sign-up"],
      },
    ],
    sitemap: `${baseUrl}/sitemap.xml`,
  };
}
```

We disallow /studio so search engines don't try to crawl and index your CMS editor.

## Step 7: Test it

Run the dev server. Visit:
- http://localhost:3000/sitemap.xml — should list your homepage, posts, categories
- http://localhost:3000/robots.txt — should show the rules above
- http://localhost:3000/posts/YOUR-SLUG/opengraph-image — should show a generated PNG image
- View page source on a post page and confirm `<meta property="og:title">` etc. are present

You can also paste your (eventually public) post URL into https://www.opengraph.xyz/ after deployment to preview how it'll look when shared on social media.

## Checkpoint ✅
- [ ] /sitemap.xml lists all posts and categories
- [ ] /robots.txt excludes /studio
- [ ] Each post has a unique generated OG image
- [ ] Post pages show correct title/description meta tags
- [ ] `opengraph-image.tsx` awaits `params` before reading `slug`, matching the pattern used in `page.tsx` and `generateMetadata`

Next: **Part 11 — Styling Polish: Tailwind v4 Typography, Dark Mode Toggle**
