# Appendix A: Full Codebase Reference (1 of 8)

This appendix consolidates every file created across the series, split into 8 notes due to length. This note (1 of 8) covers: project config, environment variables, and all Sanity setup files (client, schemas, queries).

**Notes in this set:**
- 1 of 8 (this note): Config + Sanity setup + schemas + queries
- 2 of 8: Shared components (layout, ui, providers)
- 3 of 8: More UI components
- 4 of 8: Home-section components + ContactForm
- 5 of 8: Root layout, globals.css, lib/metadata, site layout + homepage
- 6 of 8: Projects and blog pages
- 7 of 8: About and contact pages
- 8 of 8: API revalidate route, sitemap, robots.txt, OG image routes, full folder structure

## Project Setup Command (Part 2)

```bash
npx create-next-app@latest my-portfolio
# TypeScript: Yes | ESLint: Yes | Tailwind: Yes
# src/ directory: No | App Router: Yes | Turbopack: Yes | import alias: No

cd my-portfolio
npm install sanity next-sanity @sanity/vision styled-components
npm install @sanity/image-url
npm install @portabletext/react
npm install next-themes
```

## .env.local (Appendix C has full details)

```bash
# File: .env.local
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2024-06-01
NEXT_PUBLIC_WEB3FORMS_ACCESS_KEY=your_web3forms_access_key
SANITY_REVALIDATE_SECRET=your_generated_secret
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

## next.config.ts

```ts
// File: next.config.ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "cdn.sanity.io",
      },
    ],
  },
};

export default nextConfig;
```

## sanity.config.ts

```ts
// File: sanity.config.ts
import { defineConfig } from "sanity";
import { structureTool } from "sanity/structure";
import { visionTool } from "@sanity/vision";
import { schemaTypes } from "./sanity/schemaTypes";

const projectId = process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!;
const dataset = process.env.NEXT_PUBLIC_SANITY_DATASET!;

export default defineConfig({
  name: "default",
  title: "My Portfolio CMS",
  basePath: "/studio",
  projectId,
  dataset,
  plugins: [structureTool(), visionTool()],
  schema: {
    types: schemaTypes,
  },
});
```

## sanity/client.ts

```ts
// File: sanity/client.ts
import { createClient } from "next-sanity";

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2024-06-01",
  useCdn: true,
});
```

## sanity/image.ts

```ts
// File: sanity/image.ts
import createImageUrlBuilder from "@sanity/image-url";
import type { Image } from "sanity";
import { client } from "./client";

const builder = createImageUrlBuilder(client);

export function urlFor(source: Image) {
  return builder.image(source);
}
```

## sanity/fetch.ts

```ts
// File: sanity/fetch.ts
import { client } from "./client";

export async function sanityFetch<T>({
  query,
  params = {},
  tags = [],
}: {
  query: string;
  params?: Record<string, unknown>;
  tags?: string[];
}): Promise<T> {
  return client.fetch<T>(query, params, {
    next: { tags },
  });
}
```

## sanity/types.ts

```ts
// File: sanity/types.ts
export interface SanityImage {
  asset: { _ref: string; _type: "reference" };
  hotspot?: { x: number; y: number; height: number; width: number };
}

export interface Project {
  _id: string;
  title: string;
  slug: { current: string };
  summary: string;
  coverImage?: SanityImage;
  gallery?: SanityImage[];
  tags?: string[];
  liveUrl?: string;
  repoUrl?: string;
  publishedAt?: string;
  body?: unknown[];
}

export interface Post {
  _id: string;
  title: string;
  slug: { current: string };
  excerpt: string;
  coverImage?: SanityImage;
  publishedAt?: string;
  body?: unknown[];
  author?: { name: string; photo?: SanityImage };
}

export interface Skill {
  _id: string;
  name: string;
  category: string;
}

export interface Experience {
  _id: string;
  role: string;
  company: string;
  startDate?: string;
  endDate?: string;
  description?: unknown[];
}

export interface SiteSettings {
  title: string;
  tagline: string;
  socialLinks?: { platform: string; url: string }[];
  resumeUrl?: string;
}

export interface Author {
  name: string;
  photo?: SanityImage;
  shortBio: string;
  longBio?: unknown[];
}
```

## sanity/queries.ts

```ts
// File: sanity/queries.ts
import { groq } from "next-sanity";

export const siteSettingsQuery = groq`
  *[_type == "siteSettings"][0]{
    title,
    tagline,
    socialLinks,
    "resumeUrl": resumeFile.asset->url
  }
`;

export const authorQuery = groq`
  *[_type == "author"][0]{
    name,
    photo,
    shortBio,
    longBio
  }
`;

export const featuredProjectsQuery = groq`
  *[_type == "project" && featured == true] | order(publishedAt desc) [0...3] {
    _id, title, slug, summary, coverImage, tags
  }
`;

export const allProjectsQuery = groq`
  *[_type == "project"] | order(publishedAt desc) {
    _id, title, slug, summary, coverImage, tags
  }
`;

export const projectBySlugQuery = groq`
  *[_type == "project" && slug.current == $slug][0]{
    _id, title, summary, coverImage, gallery, tags, liveUrl, repoUrl, publishedAt, body
  }
`;

export const allProjectSlugsQuery = groq`
  *[_type == "project" && defined(slug.current)][].slug.current
`;

export const allPostsQuery = groq`
  *[_type == "post"] | order(publishedAt desc) {
    _id, title, slug, excerpt, coverImage, publishedAt
  }
`;

export const postBySlugQuery = groq`
  *[_type == "post" && slug.current == $slug][0]{
    _id, title, excerpt, coverImage, publishedAt, body,
    "author": author->{name, photo}
  }
`;

export const allPostSlugsQuery = groq`
  *[_type == "post" && defined(slug.current)][].slug.current
`;

export const skillsQuery = groq`
  *[_type == "skill"] | order(category asc) {
    _id, name, category
  }
`;

export const experienceQuery = groq`
  *[_type == "experience"] | order(startDate desc) {
    _id, role, company, startDate, endDate, description
  }
`;
```

## sanity/schemaTypes/index.ts

```ts
// File: sanity/schemaTypes/index.ts
import { type SchemaTypeDefinition } from "sanity";
import siteSettings from "./siteSettings";
import author from "./author";
import skill from "./skill";
import experience from "./experience";
import project from "./project";
import post from "./post";

export const schemaTypes: SchemaTypeDefinition[] = [
  siteSettings,
  author,
  skill,
  experience,
  project,
  post,
];
```

The individual schema files (`siteSettings.ts`, `author.ts`, `skill.ts`, `experience.ts`, `project.ts`, `post.ts`) are reproduced in full in **Appendix B**, not repeated here to avoid duplication — refer there for their complete code.

## app/studio/[[...tool]]/page.tsx

```tsx
// File: app/studio/[[...tool]]/page.tsx
import { NextStudio } from "next-sanity/studio";
import config from "../../../sanity.config";

export const dynamic = "force-static";

export default function StudioPage() {
  return <NextStudio config={config} />;
}
```

## app/studio/layout.tsx

```tsx
// File: app/studio/layout.tsx
export const metadata = {
  title: "Studio - My Portfolio CMS",
};

export default function StudioLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
```

Continue to **Appendix A (2 of 8)** for shared components.

---

Want me to continue to Appendix A (2 of 8)?
