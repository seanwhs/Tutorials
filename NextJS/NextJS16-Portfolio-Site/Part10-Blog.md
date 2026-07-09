# Part 10: Blog with Portable Text

Now we add a blog: `/blog` (listing) and `/blog/[slug]` (post detail), reusing the `RichText` component from Part 9.

## Step 1: A BlogCard Component

```tsx
// File: components/ui/BlogCard.tsx
import Image from "next/image";
import Link from "next/link";
import { urlFor } from "@/sanity/image";
import type { Post } from "@/sanity/types";

function formatDate(dateStr?: string) {
  if (!dateStr) return "";
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

export default function BlogCard({ post }: { post: Post }) {
  return (
    <Link
      href={`/blog/${post.slug.current}`}
      className="group block overflow-hidden rounded-xl border border-gray-200 transition-shadow hover:shadow-lg dark:border-gray-800"
    >
      {post.coverImage && (
        <div className="relative aspect-video w-full overflow-hidden bg-gray-100 dark:bg-gray-900">
          <Image
            src={urlFor(post.coverImage).width(800).height(450).url()}
            alt={post.title}
            fill
            className="object-cover transition-transform duration-300 group-hover:scale-105"
            sizes="(max-width: 768px) 100vw, 33vw"
          />
        </div>
      )}
      <div className="p-5">
        <p className="text-xs font-medium uppercase tracking-wide text-gray-500">
          {formatDate(post.publishedAt)}
        </p>
        <h3 className="mt-1 text-lg font-semibold">{post.title}</h3>
        <p className="mt-2 line-clamp-2 text-sm text-gray-600 dark:text-gray-300">
          {post.excerpt}
        </p>
      </div>
    </Link>
  );
}
```

## Step 2: Build the Blog Listing Page

```tsx
// File: app/(site)/blog/page.tsx
import type { Metadata } from "next";
import Container from "@/components/ui/Container";
import BlogCard from "@/components/ui/BlogCard";
import { sanityFetch } from "@/sanity/fetch";
import { allPostsQuery } from "@/sanity/queries";
import type { Post } from "@/sanity/types";

export const metadata: Metadata = {
  title: "Blog | My Portfolio",
  description: "Thoughts on web development, design, and more.",
};

export default async function BlogPage() {
  const posts = await sanityFetch<Post[]>({
    query: allPostsQuery,
    tags: ["post"],
  });

  return (
    <main className="py-16">
      <Container>
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">Blog</h1>
        <p className="mt-3 max-w-2xl text-gray-600 dark:text-gray-300">
          Notes on things I&apos;m learning and building.
        </p>

        {posts.length === 0 ? (
          <p className="mt-10 text-gray-500">
            No posts published yet — add some in /studio!
          </p>
        ) : (
          <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {posts.map((post) => (
              <BlogCard key={post._id} post={post} />
            ))}
          </div>
        )}
      </Container>
    </main>
  );
}
```

## Step 3: Build the Dynamic Post Detail Page

Same async `params` pattern as Part 9's project page:

```tsx
// File: app/(site)/blog/[slug]/page.tsx
import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import Container from "@/components/ui/Container";
import RichText from "@/components/ui/RichText";
import { urlFor } from "@/sanity/image";
import { sanityFetch } from "@/sanity/fetch";
import { postBySlugQuery, allPostSlugsQuery } from "@/sanity/queries";
import type { Post } from "@/sanity/types";

type Props = {
  params: Promise<{ slug: string }>;
};

export async function generateStaticParams() {
  const slugs = await sanityFetch<string[]>({ query: allPostSlugsQuery });
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const post = await sanityFetch<Post | null>({
    query: postBySlugQuery,
    params: { slug },
    tags: [`post:${slug}`],
  });

  if (!post) return { title: "Post Not Found" };

  return {
    title: `${post.title} | My Portfolio Blog`,
    description: post.excerpt,
  };
}

function formatDate(dateStr?: string) {
  if (!dateStr) return "";
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

export default async function BlogPostPage({ params }: Props) {
  const { slug } = await params;

  const post = await sanityFetch<Post | null>({
    query: postBySlugQuery,
    params: { slug },
    tags: [`post:${slug}`],
  });

  if (!post) {
    notFound();
  }

  return (
    <main className="py-16">
      <Container>
        <article className="mx-auto max-w-3xl">
          <p className="text-sm font-medium uppercase tracking-wide text-gray-500">
            {formatDate(post.publishedAt)}
          </p>
          <h1 className="mt-1 text-3xl font-bold tracking-tight sm:text-4xl">
            {post.title}
          </h1>

          {post.author && (
            <div className="mt-4 flex items-center gap-3">
              {post.author.photo && (
                <Image
                  src={urlFor(post.author.photo).width(40).height(40).url()}
                  alt={post.author.name}
                  width={40}
                  height={40}
                  className="rounded-full"
                />
              )}
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                {post.author.name}
              </span>
            </div>
          )}

          {post.coverImage && (
            <div className="relative mt-8 aspect-video w-full overflow-hidden rounded-xl">
              <Image
                src={urlFor(post.coverImage).width(1200).url()}
                alt={post.title}
                fill
                className="object-cover"
                priority
              />
            </div>
          )}

          {post.body && <RichText value={post.body} />}
        </article>
      </Container>
    </main>
  );
}
```

## Step 4: Add Test Blog Content

Go to http://localhost:3000/studio → **Blog Post** → **Create new**. Fill in:
- Title, slug (auto-generated from title)
- Excerpt
- Cover image
- Author (reference your existing Author document)
- Published At (pick today's date)
- Body — write a couple of paragraphs, add a heading, try a bullet list

Click **Publish**.

## Step 5: Test It

```bash
npm run dev
```

Visit http://localhost:3000/blog — you should see your post card. Click into it to see the full rendered post with author byline, cover image, and formatted body content.

## Checkpoint ✅

You now have:
- `/blog` — a listing page of all published posts
- `/blog/[slug]` — a dynamic post page reusing `RichText`, with author byline and formatted dates
- Consistent async `params` handling matching Next.js 16's requirements

Commit your progress:

```bash
git add .
git commit -m "Add blog listing and post detail pages"
```

Next up: **Part 11: About / Resume Page**, where we bring together the Author, Skill, and Experience content into a full bio/resume page.
