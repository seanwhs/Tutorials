## Blog Tutorial - Part 6: Categories & Author Pages, Static Generation, ISR

### What we're doing

We will expand the blog to include:

* A **Category Archive Page** (`/categories/[slug]`) listing all posts in a specific category.
* An **Author Page** (`/authors/[slug]`) showing a biography and all posts by that author.
* A **Shared Navigation Header** that dynamically lists all categories.
* Confirmation of our **ISR (Incremental Static Regeneration)** strategy for high performance.

All dynamic routes here use the Next.js 16 asynchronous `params` pattern (`params: Promise<{ slug: string }>`).

---

### Step 1: Add New Queries

Add these to `src/sanity/lib/queries.ts`:

```ts
export const AUTHOR_QUERY = groq`
  *[_type == "author" && slug.current == $slug][0] {
    _id, name, slug, image, bio
  }
`;

export const AUTHOR_SLUGS_QUERY = groq`
  *[_type == "author" && defined(slug.current)][].slug.current
`;

export const POSTS_BY_AUTHOR_QUERY = groq`
  *[_type == "post" && author->slug.current == $slug] | order(publishedAt desc) {
    _id, title, slug, excerpt, mainImage, publishedAt, isMembersOnly,
    author->{name, slug, image},
    categories[]->{title, slug}
  }
`;

export const CATEGORY_QUERY = groq`
  *[_type == "category" && slug.current == $slug][0] {
    _id, title, slug, description
  }
`;

export const CATEGORY_SLUGS_QUERY = groq`
  *[_type == "category" && defined(slug.current)][].slug.current
`;

```

---

### Step 2: Build the Category Page

Create `src/app/categories/[slug]/page.tsx`:

```tsx
import { notFound } from "next/navigation";
import { client } from "@/sanity/lib/client";
import { CATEGORY_QUERY, CATEGORY_SLUGS_QUERY, POSTS_BY_CATEGORY_QUERY } from "@/sanity/lib/queries";
import type { Category, Post } from "@/sanity/lib/types";
import PostCard from "@/components/PostCard";

export const revalidate = 60;
type PageProps = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const slugs = await client.fetch<string[]>(CATEGORY_SLUGS_QUERY);
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const category = await client.fetch<Category>(CATEGORY_QUERY, { slug });
  return category ? { title: `${category.title} — My Blog` } : {};
}

export default async function CategoryPage({ params }: PageProps) {
  const { slug } = await params;
  const category = await client.fetch<Category>(CATEGORY_QUERY, { slug });
  if (!category) notFound();

  const posts = await client.fetch<Post[]>(POSTS_BY_CATEGORY_QUERY, { category: slug });

  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <h1 className="text-4xl font-bold tracking-tight">{category.title}</h1>
      {category.description && <p className="mt-2 text-gray-600 dark:text-gray-300">{category.description}</p>}
      
      <div className="mt-10 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {posts.map((post) => <PostCard key={post._id} post={post} />)}
      </div>
    </main>
  );
}

```

---

### Step 3: Build the Author Page

Create `src/app/authors/[slug]/page.tsx`:

```tsx
import { notFound } from "next/navigation";
import Image from "next/image";
import { client } from "@/sanity/lib/client";
import { urlForImage } from "@/sanity/lib/image";
import { AUTHOR_QUERY, AUTHOR_SLUGS_QUERY, POSTS_BY_AUTHOR_QUERY } from "@/sanity/lib/queries";
import type { Author, Post } from "@/sanity/lib/types";
import PostCard from "@/components/PostCard";

export const revalidate = 60;
type PageProps = { params: Promise<{ slug: string }> };

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
            <Image src={urlForImage(author.image).width(160).height(160).url()} alt={author.name} fill className="object-cover" />
          </div>
        )}
        <div>
          <h1 className="text-3xl font-bold">{author.name}</h1>
          <p className="mt-1 max-w-xl text-gray-600 dark:text-gray-300">{author.bio}</p>
        </div>
      </div>
      <h2 className="mt-12 text-2xl font-semibold">Posts by {author.name}</h2>
      <div className="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {posts.map((post) => <PostCard key={post._id} post={post} />)}
      </div>
    </main>
  );
}

```

---

### Step 4: Build a Shared Navigation Header

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
        <Link href="/" className="text-lg font-bold">My Blog</Link>
        <nav className="flex gap-4 text-sm">
          {categories.map((cat) => (
            <Link key={cat.slug.current} href={`/categories/${cat.slug.current}`} className="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white">
              {cat.title}
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}

```

---

### Step 5: Update Root Layout

Update `src/app/layout.tsx`:

```tsx
import Header from "@/components/Header";
import "./globals.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Header />
        {children}
      </body>
    </html>
  );
}

```

---

### Checkpoint ✅

* [ ] **Navigation:** Header dynamically lists categories.
* [ ] **Categories:** Archive page correctly filters posts.
* [ ] **Authors:** Bio and filtered posts display correctly.
* [ ] **Architecture:** All routes use `await params`.
* [ ] **Performance:** ISR is consistent across the site.

**Next:** **Part 7 — Authentication: Clerk Setup, Sign In/Up, Header UI.**

---

Are you ready to proceed to Part 7?
