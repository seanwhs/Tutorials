## Blog Tutorial — Part 10: SEO & Open Graph

In this part, we implement dynamic sitemaps, robots configuration, and per-post OG images generated on-the-fly using Next.js Edge functions.

### Step 1: Environment & Root Metadata

Add your base URL to `.env.local`:

```bash
NEXT_PUBLIC_SITE_URL=http://localhost:3000

```

Update `src/app/layout.tsx` to set default SEO templates:

```tsx
export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000"),
  title: { default: "My Blog", template: "%s | My Blog" },
  description: "A blog built with Next.js, Tailwind CSS, Sanity, and Clerk",
  openGraph: { type: "website", siteName: "My Blog" },
};

```

### Step 2: Post-Specific Metadata

Update `generateMetadata` in `src/app/posts/[slug]/page.tsx` to handle the asynchronous `params` pattern:

```tsx
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

Create `src/app/posts/[slug]/opengraph-image.tsx` to generate PNGs at build/request time:

```tsx
import { ImageResponse } from "next/og";

export const runtime = "edge";
export const size = { width: 1200, height: 630 };

export default async function OpengraphImage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });

  return new ImageResponse(
    (
      <div style={{ display: "flex", background: "#0f172a", color: "white", padding: "80px" }}>
        <h1>{post?.title || "My Blog"}</h1>
      </div>
    ),
    { ...size }
  );
}

```

### Step 4: Sitemap & Robots

Create `src/app/sitemap.ts`:

```tsx
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";
  const [postSlugs, categorySlugs] = await Promise.all([
    client.fetch<string[]>(POST_SLUGS_QUERY),
    client.fetch<string[]>(CATEGORY_SLUGS_QUERY),
  ]);

  return [
    { url: baseUrl, lastModified: new Date() },
    ...postSlugs.map((slug) => ({ url: `${baseUrl}/posts/${slug}`, lastModified: new Date() })),
  ];
}

```

Create `src/app/robots.ts`:

```tsx
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

* [ ] **Sitemap:** `/sitemap.xml` automatically includes all routes.
* [ ] **Social:** Each post generates a unique OG image.
* [ ] **Robots:** CMS admin paths are successfully hidden from crawlers.
