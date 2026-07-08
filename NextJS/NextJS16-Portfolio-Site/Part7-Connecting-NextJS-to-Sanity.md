# Part 7: Connecting Next.js to Sanity

Now we wire up the read side: a typed Sanity client, GROQ query helpers, and an image URL builder, all set up once in `lib/` and reused across every page.

## Step 1: Install the Client Library

We already installed `next-sanity` in Part 5. Also install the image URL builder:

```bash
npm install @sanity/image-url
```

## Step 2: Create the Sanity Client

```ts
// File: sanity/client.ts
import { createClient } from "next-sanity";

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2024-06-01",
  useCdn: true, // fast, cached reads — fine for public content
});
```

`useCdn: true` reads from Sanity's global CDN (fast, slightly eventually-consistent). We'll override this per-request later where freshness matters (e.g. after webhook revalidation in Part 15).

## Step 3: Create an Image URL Builder

Sanity stores images as references; we need a helper to turn them into real URLs, optionally resized/cropped.

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

Usage later will look like: `urlFor(project.coverImage).width(800).height(600).url()`.

## Step 4: Write Reusable GROQ Queries

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
    _id,
    title,
    slug,
    summary,
    coverImage,
    tags
  }
`;

export const allProjectsQuery = groq`
  *[_type == "project"] | order(publishedAt desc) {
    _id,
    title,
    slug,
    summary,
    coverImage,
    tags
  }
`;

export const projectBySlugQuery = groq`
  *[_type == "project" && slug.current == $slug][0]{
    _id,
    title,
    summary,
    coverImage,
    gallery,
    tags,
    liveUrl,
    repoUrl,
    publishedAt,
    body
  }
`;

export const allProjectSlugsQuery = groq`
  *[_type == "project" && defined(slug.current)][].slug.current
`;

export const allPostsQuery = groq`
  *[_type == "post"] | order(publishedAt desc) {
    _id,
    title,
    slug,
    excerpt,
    coverImage,
    publishedAt
  }
`;

export const postBySlugQuery = groq`
  *[_type == "post" && slug.current == $slug][0]{
    _id,
    title,
    excerpt,
    coverImage,
    publishedAt,
    body,
    "author": author->{name, photo}
  }
`;

export const allPostSlugsQuery = groq`
  *[_type == "post" && defined(slug.current)][].slug.current
`;

export const skillsQuery = groq`
  *[_type == "skill"] | order(category asc) {
    _id,
    name,
    category
  }
`;

export const experienceQuery = groq`
  *[_type == "experience"] | order(startDate desc) {
    _id,
    role,
    company,
    startDate,
    endDate,
    description
  }
`;
```

Each query only returns the fields we actually need — a GROQ best practice that keeps payloads small and fast.

## Step 5: A Typed Fetch Helper

To keep our page code clean, wrap `client.fetch` with a small helper that also sets caching behavior appropriate for Next.js 16's App Router:

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
    // Next.js data cache integration: tag responses so we can
    // surgically revalidate them later (see Part 15, webhooks).
    next: { tags },
  });
}
```

Passing `next: { tags: [...] }` into `client.fetch` (which forwards to `fetch` under the hood) lets us later call `revalidateTag("project")` from a webhook route and instantly refresh only the affected pages — without redeploying or waiting for a timed revalidation window.

## Step 6: Define TypeScript Types for Our Content

Create a lightweight types file so pages get autocomplete and type-checking:

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

## Step 7: Test the Connection

Let's temporarily verify everything works by fetching site settings on the homepage. Update `app/(site)/page.tsx`:

```tsx
// File: app/(site)/page.tsx
import Container from "@/components/ui/Container";
import { sanityFetch } from "@/sanity/fetch";
import { siteSettingsQuery } from "@/sanity/queries";
import type { SiteSettings } from "@/sanity/types";

export default async function Home() {
  const settings = await sanityFetch<SiteSettings | null>({
    query: siteSettingsQuery,
    tags: ["siteSettings"],
  });

  return (
    <main className="py-20">
      <Container>
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
          {settings?.title ?? "My Portfolio (fallback — check Sanity connection)"}
        </h1>
        <p className="mt-4 max-w-xl text-lg text-gray-600 dark:text-gray-300">
          {settings?.tagline ?? "Add a Site Settings document in /studio."}
        </p>
      </Container>
    </main>
  );
}
```

Note this is an `async` Server Component — Next.js's App Router lets page/layout components be `async` functions directly, which is how we fetch data without a separate `getServerSideProps`/`getStaticProps` (those were the old Pages Router APIs; we don't use them here).

Run:

```bash
npm run dev
```

Visit http://localhost:3000 — you should see the title/tagline from the Site Settings document you published in Part 6. If you see the fallback text, double check:
- You published (not just saved as draft) the Site Settings document in `/studio`
- `.env.local` has the correct Project ID/dataset
- Your terminal was restarted after adding/changing `.env.local` (Next.js only reads env files at server start)

## Checkpoint ✅

You now have:
- `sanity/client.ts` — configured Sanity client
- `sanity/image.ts` — image URL builder
- `sanity/queries.ts` — all GROQ queries the site needs
- `sanity/fetch.ts` — a tagged fetch helper for cache-tag based revalidation
- `sanity/types.ts` — TypeScript interfaces for our content
- A homepage successfully pulling live data from Sanity

Commit your progress:

```bash
git add .
git commit -m "Connect Next.js to Sanity: client, queries, image builder, types"
```

Next up: **Part 8: Building the Homepage**, where we flesh out the full homepage: hero, featured projects, and an about snippet.
