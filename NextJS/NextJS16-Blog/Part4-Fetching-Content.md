## Blog Tutorial — Part 4: Fetching & Displaying Content

### What we're doing

We will wire up the Sanity client, create reusable GROQ queries, define our TypeScript types, and render a live grid of posts on the homepage using **Next.js Server Components**. This ensures data is fetched at build/request time on the server, eliminating the need for client-side loading spinners.

---

### Step 1: Create the Sanity Client

Create `src/sanity/lib/client.ts`. We use `next-sanity` to handle the heavy lifting of client instantiation.

```ts
import { createClient } from "next-sanity";

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  apiVersion: "2024-01-01",
  useCdn: process.env.NODE_ENV === "production",
});

```

### Step 2: Create the Image URL Builder

Create `src/sanity/lib/image.ts`. This helper transforms raw Sanity image objects into optimized, responsive URLs.

```ts
import { createImageUrlBuilder } from "@sanity/image-url";
import { type SanityImageSource } from "@sanity/image-url";
import { client } from "./client";

const builder = createImageUrlBuilder(client);

export function urlForImage(source: SanityImageSource) {
  return builder.image(source);
}

```

### Step 3: Define Reusable GROQ Queries

Create `src/sanity/lib/queries.ts`. Using `->` allows us to "dereference" and fetch author/category details automatically.

```ts
import { groq } from "next-sanity";

export const POSTS_QUERY = groq`
  *[_type == "post"] | order(publishedAt desc) {
    _id, title, slug, excerpt, mainImage, publishedAt, isMembersOnly,
    author->{name, slug, image},
    categories[]->{title, slug}
  }
`;

export const POST_QUERY = groq`
  *[_type == "post" && slug.current == $slug][0] {
    ..., author->, categories[]->
  }
`;

```

### Step 4: Define TypeScript Types

Create `src/sanity/lib/types.ts`. This ensures type safety across your entire application.

```ts
import { type PortableTextBlock } from "next-sanity";
import { type SanityImageSource } from "@sanity/image-url";

export interface Post {
  _id: string;
  title: string;
  slug: { current: string };
  excerpt: string;
  mainImage: SanityImageSource & { alt?: string };
  publishedAt: string;
  isMembersOnly: boolean;
  author: { 
    name: string; 
    image?: SanityImageSource 
  };
  categories: { 
    title: string; 
    slug: { current: string } 
  }[];
  body?: PortableTextBlock[];
}

```

### Step 5: Build the `PostCard` Component

Create `src/components/PostCard.tsx`. Note how we use `post.mainImage.alt` directly, now that the type is fully defined.

```tsx
import Image from "next/image";
import Link from "next/link";
import { urlForImage } from "@/sanity/lib/image";
import type { Post } from "@/sanity/lib/types";

export default function PostCard({ post }: { post: Post }) {
  return (
    <Link href={`/posts/${post.slug.current}`} className="group block rounded-xl border border-gray-200 p-4 transition hover:shadow-lg dark:border-gray-700">
      <div className="relative h-48 w-full overflow-hidden rounded-lg">
        {post.mainImage && (
          <Image
            src={urlForImage(post.mainImage).width(600).height(400).url()}
            alt={post.mainImage.alt || post.title}
            fill
            className="object-cover transition group-hover:scale-105"
          />
        )}
        {post.isMembersOnly && (
          <span className="absolute right-2 top-2 rounded bg-black/70 px-2 py-1 text-xs font-medium text-white">
            Members Only
          </span>
        )}
      </div>
      <h2 className="mt-4 text-xl font-semibold group-hover:underline">{post.title}</h2>
      <p className="mt-2 line-clamp-2 text-sm text-gray-600">{post.excerpt}</p>
    </Link>
  );
}

```

### Step 6: Configure Next.js Image Optimization

Update `next.config.ts` to allow fetching images from the Sanity CDN.

```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: { remotePatterns: [{ protocol: "https", hostname: "cdn.sanity.io" }] },
};

export default nextConfig;

```

### Step 7: Update Homepage

Replace `src/app/page.tsx` with this ISR-enabled implementation.

```tsx
import { client } from "@/sanity/lib/client";
import { POSTS_QUERY } from "@/sanity/lib/queries";
import PostCard from "@/components/PostCard";
import type { Post } from "@/sanity/lib/types";

export const revalidate = 60; // ISR: Refresh data at most once a minute

export default async function HomePage() {
  const posts = await client.fetch<Post[]>(POSTS_QUERY);

  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <h1 className="text-4xl font-bold">GreyMatter Journal</h1>
      <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {posts.map((post) => <PostCard key={post._id} post={post} />)}
      </div>
    </main>
  );
}

```

---

### Checkpoint ✅

* [ ] **Data Fetching:** Home page successfully pulls from Sanity.
* [ ] **Types:** TypeScript recognizes the `Post` schema.
* [ ] **UI:** `PostCard` correctly renders the "Members Only" badge.
* [ ] **Optimization:** Images and ISR (`revalidate = 60`) are configured.

**Next:** **Part 5 — Post Detail Pages: Implementing Portable Text and Clerk Authentication.**

---

Are you ready to begin Part 5 and set up your dynamic post routes and authentication guards?
