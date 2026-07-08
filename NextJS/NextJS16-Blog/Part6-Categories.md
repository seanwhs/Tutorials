## Blog Tutorial - Part 6: Categories & Author Pages, Static Generation, ISR

## What we're doing
We'll add:
- A category archive page at `/categories/[slug]` listing all posts in that category
- An author page at `/authors/[slug]` showing bio + their posts
- A simple top navigation bar linking to categories
- Confirm/deepen our understanding of ISR (Incremental Static Regeneration), which we've been using since Part 4

Both dynamic routes use the Next.js 16 async `params` pattern introduced in Part 5 — `params: Promise<{ slug: string }>`, then `await params`.

## Step 1: Add an author query

Add to `src/sanity/lib/queries.ts`:

```ts
export const AUTHOR_QUERY = groq`
  *[_type == "author" && slug.current == $slug][0] {
    _id,
    name,
    slug,
    image,
    bio
  }
`;

export const AUTHOR_SLUGS_QUERY = groq`
  *[_type == "author" && defined(slug.current)][].slug.current
`;

export const POSTS_BY_AUTHOR_QUERY = groq`
  *[_type == "post" && author->slug.current == $slug] | order(publishedAt desc) {
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

export const CATEGORY_QUERY = groq`
  *[_type == "category" && slug.current == $slug][0] {
    _id,
    title,
    slug,
    description
  }
`;

export const CATEGORY_SLUGS_QUERY = groq`
  *[_type == "category" && defined(slug.current)][].slug.current
`;
```

(`CATEGORIES_QUERY` and `POSTS_BY_CATEGORY_QUERY` already exist from Part 4.)

## Step 2: Build the category page (async params)

Create `src/app/categories/[slug]/page.tsx`:

```tsx
import { notFound } from "next/navigation";
import { client } from "@/sanity/lib/client";
import {
  CATEGORY_QUERY,
  CATEGORY_SLUGS_QUERY,
  POSTS_BY_CATEGORY_QUERY,
} from "@/sanity/lib/queries";
import type { Category, Post } from "@/sanity/lib/types";
import PostCard from "@/components/PostCard";

export const revalidate = 60;

type PageProps = {
  params: Promise<{ slug: string }>;
};

export async function generateStaticParams() {
  const slugs = await client.fetch<string[]>(CATEGORY_SLUGS_QUERY);
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const category = await client.fetch<Category>(CATEGORY_QUERY, { slug });
  if (!category) return {};
  return { title: `${category.title} — My Blog` };
}

export default async function CategoryPage({ params }: PageProps) {
  const { slug } = await params;

  const category = await client.fetch<Category>(CATEGORY_QUERY, { slug });

  if (!category) notFound();

  const posts = await client.fetch<Post[]>(POSTS_BY_CATEGORY_QUERY, {
    category: slug,
  });

  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <h1 className="text-4xl font-bold tracking-tight">{category.title}</h1>
      {category.description && (
        <p className="mt-2 text-gray-600 dark:text-gray-300">
          {category.description}
        </p>
      )}

      {posts.length === 0 ? (
        <p className="mt-10 text-gray-500">No posts in this category yet.</p>
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

## Step 3: Build the author page (async params)

Create `src/app/authors/[slug]/page.tsx`:

```tsx
import { notFound } from "next/navigation";
import Image from "next/image";
import { client } from "@/sanity/lib/client";
import { urlForImage } from "@/sanity/lib/image";
import {
  AUTHOR_QUERY,
  AUTHOR_SLUGS_QUERY,
  POSTS_BY_AUTHOR_QUERY,
} from "@/sanity/lib/queries";
import type { Author, Post } from "@/sanity/lib/types";
import PostCard from "@/components/PostCard";

export const revalidate = 60;

type PageProps = {
  params: Promise<{ slug: string }>;
};

export async function generateStaticParams() {
  const slugs = await client.fetch<string[]>(AUTHOR_SLUGS_QUERY);
  return slugs.map((slug) => ({ slug }));
}

export default async function AuthorPage({ params }: PageProps) {
  const { slug } = await params;

  const author = await client.fetch<Author>(AUTHOR_QUERY, { slug });

  if (!author) notFound();

  const posts = await client.fetch<Post[]>(POSTS_BY_AUTHOR_QUERY, { slug });

  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <div className="flex items-center gap-4">
        {author.image && (
          <div className="relative h-20 w-20 overflow-hidden rounded-full">
            <Image
              src={urlForImage(author.image).width(160).height(160).url()}
              alt={author.name}
              fill
              className="object-cover"
            />
          </div>
        )}
        <div>
          <h1 className="text-3xl font-bold">{author.name}</h1>
          {author.bio && (
            <p className="mt-1 max-w-xl text-gray-600 dark:text-gray-300">
              {author.bio}
            </p>
          )}
        </div>
      </div>

      <h2 className="mt-12 text-2xl font-semibold">Posts by {author.name}</h2>
      <div className="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {posts.map((post) => (
          <PostCard key={post._id} post={post} />
        ))}
      </div>
    </main>
  );
}
```

## Step 4: Author link on the post page

This was already added directly in Part 5's final `posts/[slug]/page.tsx` snippet — no further changes needed here.

## Step 5: Build a shared navigation header

Create `src/components/Header.tsx`:

```tsx
import Link from "next/link";
import { client } from "@/sanity/lib/client";
import { CATEGORIES_QUERY } from "@/sanity/lib/queries";
import type { Category } from "@/sanity/lib/types";

export default async function Header() {
  const categories = await client.fetch<Category[]>(CATEGORIES_QUERY);

  return (
    <header className="border-b border-gray-200 dark:border-gray-800">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
        <Link href="/" className="text-lg font-bold">
          My Blog
        </Link>
        <nav className="flex gap-4 text-sm">
          {categories.map((cat) => (
            <Link
              key={cat.slug.current}
              href={`/categories/${cat.slug.current}`}
              className="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white"
            >
              {cat.title}
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}
```

## Step 6: Add the Header to the root layout

Update `src/app/layout.tsx`:

```tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import Header from "@/components/Header";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "My Blog",
  description: "A blog built with Next.js, Tailwind CSS, Sanity, and Clerk",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Header />
        {children}
      </body>
    </html>
  );
}
```

## Step 7: Test it

```bash
npm run dev
```

- Click a category in the nav — you should land on `/categories/web-development` and see the matching posts.
- Click an author name on a post — you should land on `/authors/jane-doe` with bio + their posts.

## A note on ISR
Every page we've built (`page.tsx` at homepage, post, category, author level) uses `export const revalidate = 60`. This means:
- Next.js generates the page as **static HTML** at build time for every known slug (`generateStaticParams`)
- Vercel serves that static HTML instantly from its edge network (free, fast)
- In the background, at most once every 60 seconds, Next.js quietly re-fetches from Sanity and swaps in updated content if anything changed
- New posts created after deployment still get pages generated on-demand the first time they're visited (Next.js "fallback" behavior), then cached

This ISR behavior is unchanged in Next.js 16 — the only difference from Next.js 14 is that reading `params` inside these route files now requires `await`, which we've applied consistently throughout.

## Checkpoint ✅
- [ ] Header shows category links dynamically pulled from Sanity
- [ ] Clicking a category shows filtered posts
- [ ] Clicking an author shows their bio and posts
- [ ] No hydration or console errors
- [ ] Both `[slug]` routes type `params` as `Promise<{ slug: string }>` and `await` it before use

Next: **Part 7 — Authentication: Clerk Setup, Sign In/Up, Header UI**
