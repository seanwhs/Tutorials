## Blog Tutorial - Part 6: Categories & Author Pages

In this part, we expand the blog architecture to include dynamic archive pages, an author biography system, and a global navigation header that fetches data directly from Sanity.

### Step 1: Infrastructure & Types

Update `src/sanity/lib/types.ts` to include your new content models:

```typescript
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

export interface Category { _id: string; title: string; slug: { current: string }; description?: string; }
export interface Author { _id: string; name: string; slug: { current: string }; image?: SanityImageSource; bio?: string; }

```

### Step 2: Advanced GROQ Queries

Update `src/sanity/lib/queries.ts` to support cross-referencing authors and categories:

```typescript
import { groq } from "next-sanity";

export const CATEGORIES_QUERY = groq`*[_type == "category"]{title, slug}`;
export const CATEGORY_QUERY = groq`*[_type == "category" && slug.current == $slug][0] { _id, title, slug, description }`;
export const CATEGORY_SLUGS_QUERY = groq`*[_type == "category" && defined(slug.current)].slug.current`;

export const POSTS_BY_CATEGORY_QUERY = groq`
  *[_type == "post" && references(*[_type=="category" && slug.current == $category]._id)] | order(publishedAt desc) {
    _id, title, slug, excerpt, mainImage, publishedAt, isMembersOnly,
    author->{name, slug, image}, categories[]->{title, slug}
  }
`;

export const AUTHOR_QUERY = groq`*[_type == "author" && slug.current == $slug][0] { _id, name, slug, image, bio }`;
export const AUTHOR_SLUGS_QUERY = groq`*[_type == "author" && defined(slug.current)].slug.current`;
export const POSTS_BY_AUTHOR_QUERY = groq`*[_type == "post" && author->slug.current == $slug] | order(publishedAt desc) { ... }`;

```

### Step 3: Dynamic Page Implementation

Both routes utilize the `async` promise pattern for `params`.

**Category Archive:** `src/app/categories/[slug]/page.tsx`

```tsx
export default async function CategoryPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const category = await client.fetch<Category>(CATEGORY_QUERY, { slug });
  if (!category) notFound();

  const posts = await client.fetch<Post[]>(POSTS_BY_CATEGORY_QUERY, { category: slug });
  
  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <h1 className="text-4xl font-bold">{category.title}</h1>
      <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {posts.map((post) => <PostCard key={post._id} post={post} />)}
      </div>
    </main>
  );
}

```

### Step 4: Shared Navigation

**Header Component:** `src/components/Header.tsx`

```tsx
export default async function Header() {
  const categories = await client.fetch<Category[]>(CATEGORIES_QUERY);
  return (
    <header className="border-b px-4 py-4">
      <nav className="mx-auto flex max-w-5xl justify-between">
        <Link href="/" className="font-bold">My Blog</Link>
        <div className="flex gap-4">
          {categories.map((cat) => (
            <Link key={cat.slug.current} href={`/categories/${cat.slug.current}`}>{cat.title}</Link>
          ))}
        </div>
      </nav>
    </header>
  );
}

```

---

### Checkpoint ✅

* [ ] **Navigation:** Header dynamically lists categories.
* [ ] **Types:** Interfaces (`Post`, `Category`, `Author`) are fully typed.
* [ ] **Routes:** All dynamic routes correctly await `params` as a promise.

