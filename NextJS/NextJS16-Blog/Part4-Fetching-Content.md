## Blog Tutorial - Part 4: Fetching Content (Sanity Client, GROQ, Homepage Post List)

## What we're doing
We'll create a typed Sanity client, write GROQ queries, and render a live list of posts on the homepage using Next.js Server Components (so it's fetched at build/request time on the server, no client-side loading spinners needed).

> Note: the homepage has no dynamic route segment (no `[slug]`), so it is unaffected by Next.js 16's async `params` change — that starts in Part 5.

## Step 1: Create the Sanity client

Create `src/sanity/lib/client.ts`:

```ts
import { createClient } from "next-sanity";

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2024-01-01",
  useCdn: process.env.NODE_ENV === "production",
});
```

`useCdn: true` in production serves cached, fast, free CDN responses. In development we bypass the cache so edits show up immediately.

## Step 2: Create an image URL builder helper

Create `src/sanity/lib/image.ts`:

```ts
import createImageUrlBuilder from "@sanity/image-url";
import type { SanityImageSource } from "@sanity/image-url/lib/types/types";
import { client } from "./client";

const builder = createImageUrlBuilder(client);

export function urlForImage(source: SanityImageSource) {
  return builder.image(source);
}
```

Usage later will look like: `urlForImage(post.mainImage).width(800).height(400).url()`

## Step 3: Create reusable GROQ queries

Create `src/sanity/lib/queries.ts`:

```ts
import { groq } from "next-sanity";

// All published posts, newest first, with author + category names resolved
export const POSTS_QUERY = groq`
  *[_type == "post"] | order(publishedAt desc) {
    _id,
    title,
    slug,
    excerpt,
    mainImage,
    publishedAt,
    isMembersOnly,
    author->{name, slug, image},
    categories[]->{title, slug}
  }
`;

// A single post by slug, including full body content
export const POST_QUERY = groq`
  *[_type == "post" && slug.current == $slug][0] {
    _id,
    title,
    slug,
    excerpt,
    mainImage,
    publishedAt,
    isMembersOnly,
    body,
    author->{name, slug, image, bio},
    categories[]->{title, slug}
  }
`;

// All slugs, used for generateStaticParams
export const POST_SLUGS_QUERY = groq`
  *[_type == "post" && defined(slug.current)][].slug.current
`;

// Posts filtered by category slug
export const POSTS_BY_CATEGORY_QUERY = groq`
  *[_type == "post" && $category in categories[]->slug.current] | order(publishedAt desc) {
    _id,
    title,
    slug,
    excerpt,
    mainImage,
    publishedAt,
    isMembersOnly,
    author->{name, slug, image}
  }
`;

// All categories, for nav/archive listing
export const CATEGORIES_QUERY = groq`
  *[_type == "category"] | order(title asc) {
    _id,
    title,
    slug
  }
`;
```

`->` in GROQ means "follow this reference and expand it" — so `author->{name}` gives us the actual author document's name instead of just an ID.

## Step 4: Define TypeScript types for our content

Create `src/sanity/lib/types.ts`:

```ts
export interface SanityImage {
  asset: {
    _ref: string;
    _type: string;
  };
  alt?: string;
}

export interface Author {
  name: string;
  slug: { current: string };
  image?: SanityImage;
  bio?: string;
}

export interface Category {
  title: string;
  slug: { current: string };
}

export interface Post {
  _id: string;
  title: string;
  slug: { current: string };
  excerpt: string;
  mainImage: SanityImage;
  publishedAt: string;
  isMembersOnly: boolean;
  author: Author;
  categories: Category[];
  body?: any[]; // Portable Text blocks
}
```

## Step 5: Build a PostCard component

Create `src/components/PostCard.tsx`:

```tsx
import Image from "next/image";
import Link from "next/link";
import { urlForImage } from "@/sanity/lib/image";
import type { Post } from "@/sanity/lib/types";

export default function PostCard({ post }: { post: Post }) {
  return (
    <Link
      href={`/posts/${post.slug.current}`}
      className="group block overflow-hidden rounded-xl border border-gray-200 transition hover:shadow-lg dark:border-gray-700"
    >
      {post.mainImage && (
        <div className="relative h-48 w-full overflow-hidden">
          <Image
            src={urlForImage(post.mainImage).width(600).height(400).url()}
            alt={post.mainImage.alt || post.title}
            fill
            className="object-cover transition group-hover:scale-105"
          />
          {post.isMembersOnly && (
            <span className="absolute right-2 top-2 rounded-full bg-black/70 px-3 py-1 text-xs font-medium text-white">
              Members Only
            </span>
          )}
        </div>
      )}
      <div className="p-4">
        <div className="flex flex-wrap gap-2">
          {post.categories?.map((cat) => (
            <span
              key={cat.slug.current}
              className="rounded-full bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-700 dark:bg-blue-900 dark:text-blue-200"
            >
              {cat.title}
            </span>
          ))}
        </div>
        <h2 className="mt-2 text-xl font-semibold group-hover:underline">
          {post.title}
        </h2>
        <p className="mt-2 line-clamp-2 text-gray-600 dark:text-gray-300">
          {post.excerpt}
        </p>
        <div className="mt-4 flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
          {post.author?.name && <span>{post.author.name}</span>}
          <span>&middot;</span>
          <time dateTime={post.publishedAt}>
            {new Date(post.publishedAt).toLocaleDateString("en-US", {
              year: "numeric",
              month: "long",
              day: "numeric",
            })}
          </time>
        </div>
      </div>
    </Link>
  );
}
```

## Step 6: Allow Sanity's CDN as an image source in Next.js

Update `next.config.ts` (Next.js 16's create-next-app generates a `.ts` config file by default):

```ts
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

## Step 7: Update the homepage to fetch and list posts

Replace `src/app/page.tsx`:

```tsx
import { client } from "@/sanity/lib/client";
import { POSTS_QUERY } from "@/sanity/lib/queries";
import type { Post } from "@/sanity/lib/types";
import PostCard from "@/components/PostCard";

export const revalidate = 60; // re-fetch from Sanity at most once every 60s

export default async function HomePage() {
  const posts = await client.fetch<Post[]>(POSTS_QUERY);

  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <h1 className="text-4xl font-bold tracking-tight">My Blog</h1>
      <p className="mt-2 text-gray-600 dark:text-gray-300">
        Thoughts on web development, design, and more.
      </p>

      {posts.length === 0 ? (
        <p className="mt-10 text-gray-500">
          No posts yet. Create one in{" "}
          <a href="/studio" className="underline">
            the Studio
          </a>
          .
        </p>
      ) : (
        <div className="mt-10 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {posts.map((post) => (
            <PostCard key={post._id} post={post} />
          ))}
        </div>
      )}
    </main>
  );
}
```

`revalidate = 60` uses Next.js **Incremental Static Regeneration**: the page is served statically (fast, free, cacheable) but automatically refreshes its data at most once per minute — perfect for a free-tier blog that doesn't need instant real-time updates. This behavior is unchanged in Next.js 16.

## Step 8: Test it

```bash
npm run dev
```

Visit http://localhost:3000 — you should see your "Hello World" post card with image, category badge, author, and date.

## Checkpoint ✅
- [ ] Homepage displays post(s) fetched live from Sanity
- [ ] Images load correctly (no broken image icons)
- [ ] Category badge and author/date show correctly
- [ ] Creating a new post in `/studio` and refreshing (may take up to 60s due to revalidate) shows it

Next: **Part 5 — Post Detail Pages: Portable Text, Images, Code Blocks**
