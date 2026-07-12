## Blog Tutorial — Part 4: Fetching & Displaying Content

In this part, we will wire up the Sanity client, create reusable GROQ queries, define TypeScript types, and render a live grid of posts on the homepage using **Next.js Server Components**. This ensures data is fetched at build or request time on the server, eliminating the need for client-side loading spinners.

### Step 1: Client Orchestration

Create `src/sanity/lib/client.ts` to instantiate the Sanity client:

```ts
import { createClient } from "next-sanity";

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  apiVersion: "2024-01-01",
  useCdn: process.env.NODE_ENV === "production",
});

```

Create `src/sanity/lib/image.ts` to transform raw images into optimized URLs:

```ts
import { createImageUrlBuilder } from "@sanity/image-url";
import { type SanityImageSource } from "@sanity/image-url";
import { client } from "./client";

const builder = createImageUrlBuilder(client);

export function urlForImage(source: SanityImageSource) {
  return builder.image(source);
}

```

### Step 2: Queries & Types

Create `src/sanity/lib/queries.ts` for reusable GROQ fetching:

```ts
import { groq } from "next-sanity";

export const POSTS_QUERY = groq`
  *[_type == "post"] | order(publishedAt desc) {
    _id, title, slug, excerpt, mainImage, publishedAt, isMembersOnly,
    author->{name, slug, image},
    categories[]->{title, slug}
  }
`;

```

Create `src/sanity/lib/types.ts` to enforce strict type safety across the app:

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
  author: { name: string; image?: SanityImageSource };
  categories: { title: string; slug: { current: string } }[];
  body?: PortableTextBlock[];
}

```

### Step 3: Components & Configuration

1. **PostCard Component:** Create `src/components/PostCard.tsx` to display individual blog cards, including the "Members Only" logic.
2. **Image Optimization:** Update `next.config.ts` to allow Sanity’s CDN as a remote image source:

```ts
const nextConfig: NextConfig = {
  images: { remotePatterns: [{ protocol: "https", hostname: "cdn.sanity.io" }] },
};

```

### Step 4: Homepage Implementation

Replace `src/app/page.tsx` with this ISR-enabled implementation to ensure content stays fresh:

```tsx
import { client } from "@/sanity/lib/client";
import { POSTS_QUERY } from "@/sanity/lib/queries";
import PostCard from "@/components/PostCard";
import type { Post } from "@/sanity/lib/types";

export const revalidate = 60; // Refresh data every minute

export default async function HomePage() {
  const posts = await client.fetch<Post[]>(POSTS_QUERY);
  return (
    <main className="mx-auto max-w-5xl px-4 py-20">
      <h1 className="text-6xl font-bold">Greymatter Journal</h1>
      <section className="mt-20 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {posts.map((post) => <PostCard key={post._id} post={post} />)}
      </section>
    </main>
  );
}

```

---

### Checkpoint ✅

* [ ] **Data Fetching:** Home page successfully pulls from Sanity.
* [ ] **Types:** TypeScript recognizes the `Post` schema.
* [ ] **Optimization:** Images and ISR (`revalidate = 60`) are configured.
