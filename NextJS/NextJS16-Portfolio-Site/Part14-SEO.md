# Part 14: SEO, Metadata, Sitemap & OG Images

Now we make the site discoverable by search engines and attractive when shared on social media, using Next.js's built-in, free SEO primitives — no third-party SEO plugin needed.

## Step 1: Set a Site-Wide Base URL

Add to `.env.local` (and later to Vercel's environment variables in Part 16):

```bash
# File: .env.local (add this line)
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

In production this will become your real Vercel URL (e.g. `https://my-portfolio.vercel.app`), which we'll set in Part 16.

## Step 2: Centralize Metadata Defaults

```ts
// File: lib/metadata.ts
import type { Metadata } from "next";

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";

export const defaultMetadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "My Portfolio",
    template: "%s | My Portfolio",
  },
  description:
    "Personal portfolio site built with Next.js, Tailwind CSS, and Sanity.",
  openGraph: {
    type: "website",
    siteName: "My Portfolio",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
  },
};
```

`metadataBase` lets every page's relative Open Graph/Twitter image URLs resolve correctly without repeating the full domain everywhere.

## Step 3: Apply Defaults in the Root Layout

```tsx
// File: app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import ThemeProvider from "@/components/providers/ThemeProvider";
import { defaultMetadata } from "@/lib/metadata";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = defaultMetadata;

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={inter.variable} suppressHydrationWarning>
      <body className="antialiased font-sans">
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
```

Since `title` uses a `template`, any page that sets `metadata.title = "Projects"` will render as `"Projects | My Portfolio"` automatically — you can now simplify per-page metadata across the site (optional cleanup, not required).

## Step 4: Add Dynamic Open Graph Images per Project/Post

Next.js supports generating OG images with `ImageResponse` at zero cost (rendered on-demand, cached automatically) — no external image generation service needed.

```tsx
// File: app/(site)/projects/[slug]/opengraph-image.tsx
import { ImageResponse } from "next/og";
import { sanityFetch } from "@/sanity/fetch";
import { projectBySlugQuery } from "@/sanity/queries";
import type { Project } from "@/sanity/types";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function OgImage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const project = await sanityFetch<Project | null>({
    query: projectBySlugQuery,
    params: { slug },
  });

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-start",
          justifyContent: "center",
          padding: "80px",
          background: "#111827",
          color: "white",
        }}
      >
        <div style={{ fontSize: 24, color: "#60a5fa", fontWeight: 600 }}>
          My Portfolio
        </div>
        <div
          style={{
            fontSize: 64,
            fontWeight: 700,
            marginTop: 20,
            lineHeight: 1.1,
          }}
        >
          {project?.title ?? "Project"}
        </div>
        <div style={{ fontSize: 28, marginTop: 20, color: "#d1d5db" }}>
          {project?.summary ?? ""}
        </div>
      </div>
    ),
    size
  );
}
```

Do the same for blog posts:

```tsx
// File: app/(site)/blog/[slug]/opengraph-image.tsx
import { ImageResponse } from "next/og";
import { sanityFetch } from "@/sanity/fetch";
import { postBySlugQuery } from "@/sanity/queries";
import type { Post } from "@/sanity/types";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function OgImage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const post = await sanityFetch<Post | null>({
    query: postBySlugQuery,
    params: { slug },
  });

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-start",
          justifyContent: "center",
          padding: "80px",
          background: "#111827",
          color: "white",
        }}
      >
        <div style={{ fontSize: 24, color: "#60a5fa", fontWeight: 600 }}>
          My Portfolio Blog
        </div>
        <div
          style={{
            fontSize: 64,
            fontWeight: 700,
            marginTop: 20,
            lineHeight: 1.1,
          }}
        >
          {post?.title ?? "Blog Post"}
        </div>
      </div>
    ),
    size
  );
}
```

Files named `opengraph-image.tsx` inside a route folder are a Next.js convention: Next.js automatically generates the image and wires up the correct `<meta property="og:image">` tag for that route — no manual linking needed.

## Step 5: Generate a Sitemap

```ts
// File: app/sitemap.ts
import type { MetadataRoute } from "next";
import { sanityFetch } from "@/sanity/fetch";
import { allProjectSlugsQuery, allPostSlugsQuery } from "@/sanity/queries";

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [projectSlugs, postSlugs] = await Promise.all([
    sanityFetch<string[]>({ query: allProjectSlugsQuery }),
    sanityFetch<string[]>({ query: allPostSlugsQuery }),
  ]);

  const staticRoutes = ["", "/projects", "/blog", "/about", "/contact"].map(
    (path) => ({
      url: `${siteUrl}${path}`,
      lastModified: new Date(),
    })
  );

  const projectRoutes = projectSlugs.map((slug) => ({
    url: `${siteUrl}/projects/${slug}`,
    lastModified: new Date(),
  }));

  const postRoutes = postSlugs.map((slug) => ({
    url: `${siteUrl}/blog/${slug}`,
    lastModified: new Date(),
  }));

  return [...staticRoutes, ...projectRoutes, ...postRoutes];
}
```

Next.js automatically serves this at `/sitemap.xml` — no extra routing needed.

## Step 6: Generate a robots.txt

```ts
// File: app/robots.ts
import type { MetadataRoute } from "next";

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/studio"],
    },
    sitemap: `${siteUrl}/sitemap.xml`,
  };
}
```

We explicitly `disallow: ["/studio"]` so search engines don't try to index your CMS editing UI.

## Step 7: Test It

```bash
npm run dev
```

Visit:
- http://localhost:3000/sitemap.xml — should list your homepage and all published project/post URLs
- http://localhost:3000/robots.txt — should show the allow/disallow rules and sitemap link
- http://localhost:3000/projects/your-slug/opengraph-image — should render the generated OG image directly in the browser

You can verify OG tags are wired up correctly using a browser's "View Page Source" and searching for `og:image`, or a tool like https://www.opengraph.xyz once deployed.

## Checkpoint ✅

You now have:
- Centralized, template-based metadata defaults
- Dynamic, auto-generated Open Graph images per project and blog post
- An auto-generated `sitemap.xml` including all dynamic routes
- A `robots.txt` that excludes `/studio` from indexing

Commit your progress:

```bash
git add .
git commit -m "Add SEO metadata, dynamic OG images, sitemap, and robots.txt"
```

Next up: **Part 15: On-Demand Revalidation with Sanity Webhooks**, where we make content updates in Sanity appear on the live site instantly.
