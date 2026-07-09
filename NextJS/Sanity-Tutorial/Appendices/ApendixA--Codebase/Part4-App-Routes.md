# Sanity Mastery - Appendix A (4 of 5): App Routes and Components
# Appendix A (4 of 5): App Routes and Components

Continues from Appendix A (3 of 5). Covers Studio embed route, blog routes (index, detail, search, pagination). See **Appendix A (5 of 5)** for API routes and shared components.

## src/app/studio/[[...tool]]/page.tsx

```tsx
"use client";

import { NextStudio } from "next-sanity/studio";
import config from "../../../../sanity.config";

export const dynamic = "force-static";

export default function StudioPage() {
  return <NextStudio config={config} />;
}
```

## src/app/studio/layout.tsx

```tsx
export const metadata = {
  title: "Studio - My Sanity App",
};

export default function StudioLayout({ children }: { children: React.ReactNode }) {
  return children;
}
```

## src/app/blog/page.tsx

```tsx
import Link from "next/link";
import { sanityFetch } from "@/sanity/fetch";
import { allPostsQuery } from "@/sanity/queries";
import type { PostListItem } from "@/sanity/types";

export default async function BlogIndexPage() {
  const posts = await sanityFetch<PostListItem[]>({
    query: allPostsQuery,
    tags: ["post"],
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
              {new Date(post.publishedAt).toLocaleDateString()} - {post.author.name}
            </p>
            <p className="mt-2 text-gray-700">{post.excerpt}</p>
          </article>
        ))}
      </div>
    </main>
  );
}
```

## src/app/blog/[slug]/page.tsx

```tsx
import { notFound } from "next/navigation";
import { sanityFetch } from "@/sanity/fetch";
import { postBySlugQuery, allPostSlugsQuery } from "@/sanity/queries";
import type { PostDetail } from "@/sanity/types";
import { PortableTextRenderer } from "@/components/PortableTextRenderer";
import { CoverImage } from "@/components/CoverImage";

type Props = {
  params: Promise<{ slug: string }>;
};

export async function generateStaticParams() {
  const slugs = await sanityFetch<string[]>({
    query: allPostSlugsQuery,
    tags: ["post"],
  });
  return slugs.map((slug) => ({ slug }));
}

export default async function PostPage({ params }: Props) {
  const { slug } = await params;

  const post = await sanityFetch<PostDetail | null>({
    query: postBySlugQuery,
    params: { slug },
    tags: ["post", `post:${slug}`],
  });

  if (!post) notFound();

  return (
    <main className="mx-auto max-w-3xl px-4 py-12">
      <CoverImage image={post.coverImage} alt={post.title} priority />
      <h1 className="text-3xl font-bold mt-6">{post.title}</h1>
      <p className="text-sm text-gray-500 mt-2">
        {new Date(post.publishedAt).toLocaleDateString()} - {post.author.name}
      </p>
      <div className="prose mt-8 max-w-none">
        <PortableTextRenderer value={post.body} />
      </div>
    </main>
  );
}
```

## src/app/blog/search/page.tsx

```tsx
import { sanityFetch } from "@/sanity/fetch";
import { searchPostsQuery } from "@/sanity/queries";
import type { PostListItem } from "@/sanity/types";

type Props = { searchParams: Promise<{ q?: string }> };

export default async function SearchPage({ searchParams }: Props) {
  const { q } = await searchParams;

  if (!q) {
    return <p className="p-8">Enter a search term in the URL: /blog/search?q=react</p>;
  }

  const results = await sanityFetch<PostListItem[]>({
    query: searchPostsQuery,
    params: { term: q },
    tags: ["post"],
  });

  return (
    <main className="mx-auto max-w-3xl px-4 py-12">
      <h1 className="text-2xl font-bold mb-6">Results for &quot;{q}&quot;</h1>
      {results.length === 0 && <p>No posts found.</p>}
      {results.map((post) => (
        <article key={post._id} className="mb-4">
          <a href={`/blog/${post.slug}`} className="font-semibold hover:underline">
            {post.title}
          </a>
        </article>
      ))}
    </main>
  );
}
```

## src/app/blog/page/[page]/page.tsx

```tsx
import { sanityFetch } from "@/sanity/fetch";
import { paginatedPostsQuery, postsTotalCountQuery } from "@/sanity/queries";
import type { PostListItem } from "@/sanity/types";
import Link from "next/link";

const PAGE_SIZE = 10;

type Props = { params: Promise<{ page: string }> };

export default async function PaginatedBlogPage({ params }: Props) {
  const { page } = await params;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const start = (pageNum - 1) * PAGE_SIZE;
  const end = start + PAGE_SIZE;

  const [posts, total] = await Promise.all([
    sanityFetch<PostListItem[]>({
      query: paginatedPostsQuery,
      params: { start, end },
      tags: ["post"],
    }),
    sanityFetch<number>({ query: postsTotalCountQuery, tags: ["post"] }),
  ]);

  const totalPages = Math.ceil(total / PAGE_SIZE);

  return (
    <main className="mx-auto max-w-3xl px-4 py-12">
      {posts.map((post) => (
        <article key={post._id} className="mb-4">
          <Link href={`/blog/${post.slug}`}>{post.title}</Link>
        </article>
      ))}
      <div className="flex gap-4 mt-8">
        {pageNum > 1 && <Link href={`/blog/page/${pageNum - 1}`}>Prev</Link>}
        {pageNum < totalPages && <Link href={`/blog/page/${pageNum + 1}`}>Next</Link>}
      </div>
    </main>
  );
}
```

Continue to **Appendix A (5 of 5)** for API routes and shared components.
