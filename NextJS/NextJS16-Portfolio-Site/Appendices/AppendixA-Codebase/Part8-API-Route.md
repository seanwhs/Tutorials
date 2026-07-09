# Appendix A: Full Codebase Reference (8 of 8)

This final note covers: the revalidation API route, sitemap, robots.txt, and dynamic Open Graph image routes.

## app/api/revalidate/route.ts

```ts
// File: app/api/revalidate/route.ts
import { revalidateTag } from "next/cache";
import { NextRequest, NextResponse } from "next/server";
import { parseBody } from "next-sanity/webhook";

type WebhookPayload = {
  _type: string;
  slug?: { current?: string };
};

export async function POST(req: NextRequest) {
  try {
    const { isValidSignature, body } = await parseBody<WebhookPayload>(
      req,
      process.env.SANITY_REVALIDATE_SECRET
    );

    if (!isValidSignature) {
      return NextResponse.json(
        { message: "Invalid signature" },
        { status: 401 }
      );
    }

    if (!body?._type) {
      return NextResponse.json({ message: "Bad request" }, { status: 400 });
    }

    revalidateTag(body._type);

    if (body.slug?.current) {
      revalidateTag(`${body._type}:${body.slug.current}`);
    }

    return NextResponse.json({
      revalidated: true,
      type: body._type,
      slug: body.slug?.current ?? null,
      now: Date.now(),
    });
  } catch (err) {
    console.error(err);
    return NextResponse.json(
      { message: "Error revalidating", error: `${err}` },
      { status: 500 }
    );
  }
}
```

## app/sitemap.ts

```ts
// File: app/sitemap.ts
import type { MetadataRoute } from "next";
import { sanityFetch } from "@/sanity/fetch";
import { allProjectSlugsQuery, allPostSlugsQuery } from "@/sanity/queries";

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [projectSlugs, postSlugs] = await Promise.all([
    sanityFetch<string[]>({ query: allProjectSlugsQuery, tags: ["project"] }),
    sanityFetch<string[]>({ query: allPostSlugsQuery, tags: ["post"] }),
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

## app/robots.ts

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

## app/(site)/projects/[slug]/opengraph-image.tsx

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

## app/(site)/blog/[slug]/opengraph-image.tsx

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

## Full Folder Structure (Final)

```txt
my-portfolio/
├── app/
│   ├── (site)/
│   │   ├── about/page.tsx
│   │   ├── blog/
│   │   │   ├── [slug]/
│   │   │   │   ├── opengraph-image.tsx
│   │   │   │   └── page.tsx
│   │   │   └── page.tsx
│   │   ├── contact/page.tsx
│   │   ├── projects/
│   │   │   ├── [slug]/
│   │   │   │   ├── opengraph-image.tsx
│   │   │   │   └── page.tsx
│   │   │   └── page.tsx
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── api/
│   │   └── revalidate/route.ts
│   ├── studio/
│   │   ├── [[...tool]]/page.tsx
│   │   └── layout.tsx
│   ├── globals.css
│   ├── layout.tsx
│   ├── robots.ts
│   └── sitemap.ts
├── components/
│   ├── about/ExperienceItem.tsx
│   ├── contact/ContactForm.tsx
│   ├── home/
│   │   ├── AboutSnippet.tsx
│   │   ├── FeaturedProjects.tsx
│   │   └── Hero.tsx
│   ├── layout/
│   │   ├── Footer.tsx
│   │   ├── Navbar.tsx
│   │   └── ThemeToggle.tsx
│   ├── providers/ThemeProvider.tsx
│   └── ui/
│       ├── BlogCard.tsx
│       ├── Container.tsx
│       ├── ProjectCard.tsx
│       ├── RichText.tsx
│       └── SkillBadge.tsx
├── lib/
│   └── metadata.ts
├── sanity/
│   ├── schemaTypes/
│   │   ├── author.ts
│   │   ├── experience.ts
│   │   ├── index.ts
│   │   ├── post.ts
│   │   ├── project.ts
│   │   ├── siteSettings.ts
│   │   └── skill.ts
│   ├── client.ts
│   ├── fetch.ts
│   ├── image.ts
│   ├── queries.ts
│   └── types.ts
├── .env.local
├── next.config.ts
├── sanity.config.ts
└── package.json
```

This completes the full reference codebase. Refer back to Parts 1-16 for the step-by-step build order and explanations, and Appendix B for the six schema files in full.

---

That's the complete Appendix A (all 8 parts)! 
