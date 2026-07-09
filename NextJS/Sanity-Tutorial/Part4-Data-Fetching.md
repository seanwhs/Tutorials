# Sanity Mastery - Part 4: Data Fetching in Next.js 16

## Step 1: The typed Sanity client

```ts
// src/sanity/client.ts
import { createClient } from "next-sanity";

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2025-01-01",
  // useCdn: true = read from Sanity's global CDN, fast but can lag ~seconds
  // behind the source of truth. Perfect for public, published content.
  useCdn: true,
});
```

## Step 2: A `sanityFetch` wrapper — the single chokepoint for all reads

Centralizing every query through one function means caching/tagging behavior is consistent everywhere, and Part 8 (revalidation) only needs to touch this one file.

```ts
// src/sanity/fetch.ts
import { client } from "./client";
import type { QueryParams } from "next-sanity";

export async function sanityFetch<T>({
  query,
  params = {},
  tags = [],
}: {
  query: string;
  params?: QueryParams;
  tags?: string[];
}): Promise<T> {
  return client.fetch<T>(query, params, {
    // `next.tags` plugs Sanity reads into Next.js's fetch cache tagging system.
    // Part 8's webhook handler calls revalidateTag(tag) to bust exactly this data,
    // without needing a full page rebuild or blanket cache clear.
    next: { tags },
  });
}
```

> Under the hood, `next-sanity`'s `client.fetch` forwards Next.js-specific options (like `next: { tags }`) straight into the underlying `fetch()` call, so Next.js's Data Cache treats each GROQ query exactly like any other cached fetch.

## Step 3: Centralize queries

```ts
// src/sanity/queries.ts
import { groq } from "next-sanity";

export const allPostsQuery = groq`
  *[_type == "post" && defined(publishedAt) && publishedAt < now()]
    | order(publishedAt desc) {
      _id,
      title,
      "slug": slug.current,
      excerpt,
      coverImage,
      publishedAt,
      "author": author->{ name },
      "categories": categories[]->{ title, "slug": slug.current }
    }
`;

export const postBySlugQuery = groq`
  *[_type == "post" && slug.current == $slug][0]{
    _id,
    title,
    body,
    coverImage,
    publishedAt,
    seo,
    "author": author->{ name, photo, shortBio },
    "categories": categories[]->{ title, "slug": slug.current }
  }
`;

export const allPostSlugsQuery = groq`
  *[_type == "post" && defined(slug.current)][].slug.current
`;
```

## Step 4: Types for query results

```ts
// src/sanity/types.ts
export interface SanityImage {
  asset: { _ref: string; _type: "reference" };
  hotspot?: { x: number; y: number; height: number; width: number };
}

export interface PostListItem {
  _id: string;
  title: string;
  slug: string;
  excerpt: string;
  coverImage?: SanityImage;
  publishedAt: string;
  author: { name: string };
  categories: { title: string; slug: string }[];
}

export interface PostDetail extends Omit<PostListItem, "excerpt" | "categories"> {
  body: unknown[]; // Portable Text blocks — typed properly in Part 5
  seo?: { metaTitle?: string; metaDescription?: string };
  author: { name: string; photo?: SanityImage; shortBio?: string };
  categories: { title: string; slug: string }[];
}
```

## Step 5: The blog index page (Server Component, static + tagged)

```tsx
// src/app/blog/page.tsx
import Link from "next/link";
import { sanityFetch } from "@/sanity/fetch";
import { allPostsQuery } from "@/sanity/queries";
import type { PostListItem } from "@/sanity/types";

// This page has no dynamic segments, so it's fully static by default in
// Next.js 16 — it will be revalidated only when Part 8's webhook fires
// revalidateTag("post"), not on a timer and not on every request.
export default async function BlogIndexPage() {
  const posts = await sanityFetch<PostListItem[]>({
    query: allPostsQuery,
    tags: ["post"], // tag every post-list read so it can be busted precisely later
  });

  return (
    <main className="mx-auto max-w-3xl px-4 py-12">
      <h1 className="text-3xl font-bold mb-8">Blog</h1>
      <div className="space-y-6">
        {posts.map((post) => (
          <article key={post._id} className="border-b pb-6">
            <Link href={`/blog/${post.slug}`} className="text-xl font-semibold hover:underline">
              {post.title}
            </Link>
            <p className="text-sm text-gray-500">
              {new Date(post.publishedAt).toLocaleDateString()} · {post.author.name}
            </p>
            <p className="mt-2 text-gray-700">{post.excerpt}</p>
          </article>
        ))}
      </div>
    </main>
  );
}
```

## Step 6: The post detail page — Next.js 16 async `params` in action

```tsx
// src/app/blog/[slug]/page.tsx
import { notFound } from "next/navigation";
import { sanityFetch } from "@/sanity/fetch";
import { postBySlugQuery, allPostSlugsQuery } from "@/sanity/queries";
import type { PostDetail } from "@/sanity/types";

// CRITICAL Next.js 16 pattern: `params` is now a Promise, not a plain object.
// You must `await` it before reading any dynamic segment.
type Props = {
  params: Promise<{ slug: string }>;
};

// Pre-render every known post at build time (SSG). This still works exactly
// the same way in Next.js 16 — generateStaticParams itself is synchronous
// and returns plain (non-Promise) objects; only the *consumer* side (page props) changed.
export async function generateStaticParams() {
  const slugs = await sanityFetch<string[]>({
    query: allPostSlugsQuery,
    tags: ["post"],
  });
  return slugs.map((slug) => ({ slug }));
}

export default async function PostPage({ params }: Props) {
  const { slug } = await params; // <- must await in Next.js 16

  const post = await sanityFetch<PostDetail | null>({
    query: postBySlugQuery,
    params: { slug },
    tags: ["post", `post:${slug}`], // fine-grained tag for single-document revalidation
  });

  if (!post) notFound();

  return (
    <main className="mx-auto max-w-3xl px-4 py-12">
      <h1 className="text-3xl font-bold">{post.title}</h1>
      <p className="text-sm text-gray-500 mt-2">
        {new Date(post.publishedAt).toLocaleDateString()} · {post.author.name}
      </p>
      {/* Portable Text rendering built out fully in Part 5 */}
      <div className="prose mt-8">{JSON.stringify(post.body)}</div>
    </main>
  );
}
```

## Static vs Dynamic: How Next.js 16 Decides

| Scenario | Behavior |
|---|---|
| No dynamic `params`/`searchParams` read, no `cookies()`/`headers()` call | Page renders **statically** at build time, cached indefinitely until tag-revalidated |
| `generateStaticParams` provided | All listed slugs pre-rendered at build; unlisted ones render on-demand and get cached (ISR-like) on first visit |
| `await draftMode()` returns `isEnabled: true` (Part 7) | Page forced dynamic for that request only — preview always fresh |
| `cache: "no-store"` passed to fetch, or `export const dynamic = "force-dynamic"` | Full page opts out of caching entirely |

## Time-Based Revalidation (Alternative to Tags)

```ts
// If you'd rather revalidate on a timer instead of (or in addition to) webhooks:
export const revalidate = 60; // seconds — put at top of a page.tsx file

// Or per-fetch:
client.fetch(query, params, { next: { revalidate: 60 } });
```

> We use **tag-based** revalidation as the primary strategy in this series (Part 8) because it's instant and precise — no stale window, no wasted rebuilds of unrelated pages.

## Checkpoint ✅
- [ ] `client.ts`, `fetch.ts`, `queries.ts`, `types.ts` created under `src/sanity/`
- [ ] `/blog` renders your test posts from Part 2
- [ ] `/blog/[slug]` renders individual posts, with `params` properly awaited
- [ ] `generateStaticParams` pre-builds all known slugs
- [ ] You understand the tag strategy (`post`, `post:<slug>`) — it's reused verbatim in Part 8

**Next: Part 5 — Rendering Portable Text**
