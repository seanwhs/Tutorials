## Blog Tutorial - Part 6: Categories & Author Pages, Static Generation, ISR

### What we're doing

We will expand the blog to include:

* **Dynamic Routing:** Category archive pages (`/categories/[slug]`) and Author pages (`/authors/[slug]`).
* **Global Navigation:** A shared header that fetches categories dynamically.
* **Infrastructure:** Updated types and queries to support these new relationships.
* **ISR:** Maintaining our 60-second revalidation strategy.

---

### Step 1: Update Types and Queries

**`src/sanity/lib/types.ts`**
Ensure your types file includes the interfaces for `Category` and `Author`:

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
  author: { name: string; slug: { current: string }; image?: SanityImageSource };
  categories: { title: string; slug: { current: string } }[];
  body?: PortableTextBlock[];
}

export interface Category {
  _id: string;
  title: string;
  slug: { current: string };
  description?: string;
}

export interface Author {
  _id: string;
  name: string;
  slug: { current: string };
  image?: SanityImageSource;
  bio?: string;
}

```

**`src/sanity/lib/queries.ts`**
Add these new exports to your existing query file:

```ts
export const CATEGORIES_QUERY = groq`*[_type == "category"]{title, slug}`;

export const CATEGORY_QUERY = groq`
  *[_type == "category" && slug.current == $slug][0] { _id, title, slug, description }
`;

export const CATEGORY_SLUGS_QUERY = groq`
  *[_type == "category" && defined(slug.current)].slug.current
`;

export const POSTS_BY_CATEGORY_QUERY = groq`
  *[_type == "post" && references(*[_type=="category" && slug.current == $category]._id)] | order(publishedAt desc) {
    _id, title, slug, excerpt, mainImage, publishedAt, isMembersOnly,
    author->{name, slug, image},
    categories[]->{title, slug}
  }
`;

export const AUTHOR_QUERY = groq`
  *[_type == "author" && slug.current == $slug][0] { _id, name, slug, image, bio }
`;

export const AUTHOR_SLUGS_QUERY = groq`
  *[_type == "author" && defined(slug.current)].slug.current
`;

export const POSTS_BY_AUTHOR_QUERY = groq`
  *[_type == "post" && author->slug.current == $slug] | order(publishedAt desc) {
    _id, title, slug, excerpt, mainImage, publishedAt, isMembersOnly,
    author->{name, slug, image},
    categories[]->{title, slug}
  }
`;

```

---

### Step 2: Build the Pages

**`src/app/categories/[slug]/page.tsx`**

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

**`src/app/authors/[slug]/page.tsx`**

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

### Step 3: Shared Header and Layout

**`src/components/Header.tsx`**

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
            <Link key={cat.slug.current} href={`/categories/${cat.slug.current}`} className="text-gray-600 hover:text-gray-900">
              {cat.title}
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}

```

**`src/app/layout.tsx`**

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

**Checkpoint ✅**

* [ ] Navigation: Header dynamically lists categories.
* [ ] Types: All interfaces exported correctly.
* [ ] Queries: New query exports match page requirements.
* [ ] Routes: Correctly handling Next.js 16 `async params`.

**Are you ready to proceed to Part 7: Authentication with Clerk?**
