# Sanity Mastery - Part 10: Advanced Patterns

## 1. Search (GROQ `match` + Next.js Search Params)

```ts
// src/sanity/queries.ts (add)
import { groq } from "next-sanity";

export const searchPostsQuery = groq`
  *[_type == "post" && (title match $term + "*" || excerpt match $term + "*")]
    | order(publishedAt desc) {
      _id, title, "slug": slug.current, excerpt, publishedAt
    }
`;
```

```tsx
// src/app/blog/search/page.tsx
import { sanityFetch } from "@/sanity/fetch";
import { searchPostsQuery } from "@/sanity/queries";
import type { PostListItem } from "@/sanity/types";

// CRITICAL Next.js 16 pattern: searchParams is also a Promise now.
type Props = { searchParams: Promise<{ q?: string }> };

export default async function SearchPage({ searchParams }: Props) {
  const { q } = await searchParams; // must await, same rule as `params`

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

## 2. Pagination

```ts
// src/sanity/queries.ts (add) — a parameterized page-size query
export const paginatedPostsQuery = groq`
  *[_type == "post" && defined(publishedAt)] | order(publishedAt desc) [$start...$end]{
    _id, title, "slug": slug.current, excerpt, publishedAt
  }
`;

export const postsTotalCountQuery = groq`count(*[_type == "post" && defined(publishedAt)])`;
```

```tsx
// src/app/blog/page/[page]/page.tsx
import { sanityFetch } from "@/sanity/fetch";
import { paginatedPostsQuery, postsTotalCountQuery } from "@/sanity/queries";
import type { PostListItem } from "@/sanity/types";
import Link from "next/link";

const PAGE_SIZE = 10;

type Props = { params: Promise<{ page: string }> };

export default async function PaginatedBlogPage({ params }: Props) {
  const { page } = await params; // Next.js 16 async params
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
        {pageNum > 1 && <Link href={`/blog/page/${pageNum - 1}`}>← Prev</Link>}
        {pageNum < totalPages && <Link href={`/blog/page/${pageNum + 1}`}>Next →</Link>}
      </div>
    </main>
  );
}
```

## 3. Internationalized (i18n) Content

Two common Sanity i18n strategies:

| Strategy | Pattern |
|---|---|
| **Field-level** | Each translatable field becomes an object: `{ en: "...", fr: "..." }` |
| **Document-level** | Separate documents per locale, linked via a shared `translations` array or the official i18n plugin |

Field-level example (simplest, good for small sites):

```ts
// src/sanity/schemaTypes/post.ts (i18n variant of the `title` field)
defineField({
  name: "title",
  type: "object",
  fields: [
    { name: "en", type: "string", title: "English" },
    { name: "fr", type: "string", title: "French" },
  ],
});
```

```groq
// Query resolves the right locale field directly
*[_type == "post"]{ "title": title[$locale] }
```

```ts
client.fetch(query, { locale: "fr" });
```

## 4. Custom Studio Structure (Enforcing the `siteSettings` Singleton from Part 2)

```ts
// src/sanity/structure.ts
import type { StructureResolver } from "sanity/structure";

// Custom desk structure: pins Site Settings as a single, non-list item,
// and groups content types logically instead of Studio's flat A-Z default list.
export const structure: StructureResolver = (S) =>
  S.list()
    .title("Content")
    .items([
      S.listItem()
        .title("Site Settings")
        .child(
          S.document()
            .schemaType("siteSettings")
            .documentId("siteSettings") // fixed ID -> there can only ever be one
        ),
      S.divider(),
      S.documentTypeListItem("post").title("Posts"),
      S.documentTypeListItem("author").title("Authors"),
      S.documentTypeListItem("category").title("Categories"),
    ]);
```

```ts
// sanity.config.ts (extended)
import { structureTool } from "sanity/structure";
import { structure } from "./src/sanity/structure";

export default defineConfig({
  // ...
  plugins: [structureTool({ structure }), /* visionTool() */],
});
```

## 5. Custom Document Actions (e.g. "Duplicate as Draft" / Block Delete-If-Published)

```ts
// src/sanity/actions/preventDeleteIfPublished.ts
import type { DocumentActionComponent, DocumentActionProps } from "sanity";

export const preventDeleteIfPublished =
  (originalAction: DocumentActionComponent) =>
  (props: DocumentActionProps) => {
    const original = originalAction(props);
    if (!original || original.type !== "dialog") return original;

    // If the document has ever been published (has a non-draft version), block delete
    if (props.published) {
      return {
        ...original,
        disabled: true,
        title: "Cannot delete a published post — unpublish it first",
      };
    }
    return original;
  };
```

```ts
// sanity.config.ts (extended)
import { preventDeleteIfPublished } from "./src/sanity/actions/preventDeleteIfPublished";

export default defineConfig({
  // ...
  document: {
    actions: (prevActions, context) => {
      if (context.schemaType !== "post") return prevActions;
      return prevActions.map((action) =>
        action.action === "delete" ? preventDeleteIfPublished(action) : action
      );
    },
  },
});
```

## Checkpoint ✅
- [ ] Search page correctly awaits `searchParams` and uses GROQ `match`
- [ ] Pagination page correctly awaits `params` and slices with `[$start...$end]`
- [ ] `siteSettings` locked to a single document via custom structure + fixed `documentId`
- [ ] (Optional) i18n field pattern understood; custom document action wired if desired

**Next: Part 11 — Type Safety (TypeGen + Zod)**
