## Blog Tutorial — Part 10: SEO & Open Graph

In this part, we implement dynamic sitemaps, robots configuration, and per-post Open Graph (OG) images generated on-the-fly using Next.js.

### Step 1: Environment & Root Metadata

Add your base URL to your `.env.local` file:

```bash
NEXT_PUBLIC_SITE_URL=http://localhost:3000

```

Update `src/app/layout.tsx` to set default SEO templates, ensuring every page has consistent branding:

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

type PageProps = { params: Promise<{ slug: string }> };

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

Create `src/app/posts/[slug]/opengraph-image.tsx` to generate high-quality, title-branded PNGs dynamically.

```tsx
import { ImageResponse } from "next/og";
import { client } from "@/sanity/lib/client";
import { POST_QUERY } from "@/sanity/lib/queries";
import type { Post } from "@/sanity/lib/types";

export const runtime = "nodejs"; 
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function OpengraphImage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });

  return new ImageResponse(
    (
      <div style={{ display: "flex", flexDirection: "column", width: "100%", height: "100%", background: "#0f172a", color: "white", padding: "80px", justifyContent: "center" }}>
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

### What to expect at `localhost:3000`

1. **Search Indexing:** You can now access `http://localhost:3000/sitemap.xml` and `http://localhost:3000/robots.txt` to see your site's SEO configuration in action.
2. **Metadata Injection:** View the source of any post page. You will see `<meta property="og:image" ... />` and `<link rel="canonical" ... />` tags correctly injected by Next.js.
3. **The OG Image Route:** Note that `.../opengraph-image` is a virtual route. If you attempt to visit the URL directly in your browser, you may receive a 404 or an error, as this route is specifically designed to be requested by social media crawlers (like LinkedIn or Twitter) to fetch metadata. **Success is defined by the existence of the `<meta>` tag in your page source, not by the browser navigation to the image URL.**

### Checkpoint ✅

* [ ] **Sitemap:** `/sitemap.xml` automatically aggregates all current posts and categories.
* [ ] **Social:** Post-specific OG images are linked in the page metadata for social sharing.
* [ ] **Robots:** The CMS admin interface (`/studio`) is protected from public indexing.
* [ ] **SEO:** Canonical URLs are set, ensuring search engines always point to your primary content.

**Part 10 is complete.** You have successfully built an SEO-optimized, production-ready blog. 
