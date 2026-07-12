## Blog Tutorial — Part 10: SEO & Open Graph

In this part, we implement dynamic sitemaps, robots configuration, and per-post Open Graph (OG) images generated on-the-fly using Next.js Edge functions.

### Step 1: Environment & Root Metadata

First, add your base URL to `.env.local`:

```bash
NEXT_PUBLIC_SITE_URL=http://localhost:3000

```

Update `src/app/layout.tsx` to set default SEO metadata:

```tsx
import type { Metadata } from "next";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000"),
  title: { default: "My Blog", template: "%s | My Blog" },
  description: "A blog built with Next.js, Tailwind CSS, Sanity, and Clerk",
  openGraph: { type: "website", siteName: "My Blog" },
};

```

### Step 2: Post-Specific Metadata

Update the `generateMetadata` function in `src/app/posts/[slug]/page.tsx` to handle the asynchronous `params` pattern. This ensures each post has unique titles, descriptions, and canonical URLs.

```tsx
import { client } from "@/sanity/lib/client";
import { POST_QUERY } from "@/sanity/lib/queries";
import type { Post } from "@/sanity/lib/types";

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });
  if (!post) return {};

  return {
    title: post.title,
    description: post.excerpt,
    alternates: { canonical: `/posts/${slug}` },
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [`/posts/${slug}/opengraph-image`],
    },
  };
}

```

### Step 3: Dynamic OG Images

Create `src/app/posts/[slug]/opengraph-image.tsx` to generate high-quality PNGs dynamically.

```tsx
import { ImageResponse } from "next/og";
import { client } from "@/sanity/lib/client";
import { POST_QUERY } from "@/sanity/lib/queries";
import type { Post } from "@/sanity/lib/types";

export const runtime = "edge";
export const size = { width: 1200, height: 630 };

export default async function OpengraphImage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });

  return new ImageResponse(
    (
      <div style={{ display: "flex", width: "100%", height: "100%", background: "#0f172a", color: "white", padding: "80px", justifyContent: "center", flexDirection: "column" }}>
        <h1 style={{ fontSize: "64px", fontWeight: "bold" }}>{post?.title || "My Blog"}</h1>
      </div>
    ),
    { ...size }
  );
}

```

### Step 4: Sitemap & Robots

Create `src/app/sitemap.ts` to automate search engine discovery:

```tsx
import { MetadataRoute } from "next";
import { client } from "@/sanity/lib/client";
import { POST_SLUGS_QUERY, CATEGORY_SLUGS_QUERY } from "@/sanity/lib/queries";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";
  const [postSlugs, categorySlugs] = await Promise.all([
    client.fetch<string[]>(POST_SLUGS_QUERY),
    client.fetch<string[]>(CATEGORY_SLUGS_QUERY),
  ]);

  return [
    { url: baseUrl, lastModified: new Date() },
    ...postSlugs.map((slug: string) => ({ url: `${baseUrl}/posts/${slug}`, lastModified: new Date() })),
    ...categorySlugs.map((slug: string) => ({ url: `${baseUrl}/categories/${slug}`, lastModified: new Date() })),
  ];
}

```

Create `src/app/robots.ts` to guide crawlers:

```tsx
import { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";
  return {
    rules: [{ userAgent: "*", allow: "/", disallow: ["/studio"] }],
    sitemap: `${baseUrl}/sitemap.xml`,
  };
}

```

---

### Checkpoint ✅

* [ ] **Sitemap:** `/sitemap.xml` automatically aggregates all routes.
* [ ] **Social:** Each post now generates a unique Open Graph image on-the-fly.
* [ ] **Robots:** The CMS admin interface (`/studio`) is protected from public search indexing.
* [ ] **SEO:** Canonical URLs are set, preventing duplicate content penalties.

**Part 10 is complete.** You have successfully built an SEO-optimized, production-ready blog. Are you ready for the final project wrap-up and deployment checklist?
