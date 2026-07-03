# **✅ Part 16 — Building Search and Filtering**

---

# GreyMatter Journal  
## Part 16 — Building Search and Filtering: Queries, URL Parameters, and Information Retrieval

> **Goal of this lesson:** Implement search and category filtering while understanding how query languages, filtering, and modern information retrieval systems work.

---

### The Scaling Problem

As content grows, readers need ways to discover it. Search and filtering become essential.

---

### Create the Search Page

Create `app/search/page.tsx`:

```tsx
import { client } from "@/lib/sanity";
import { SEARCH_QUERY } from "@/lib/queries";

type Props = {
  searchParams: Promise<{ q?: string }>;
};

export default async function SearchPage({ searchParams }: Props) {
  const { q } = await searchParams;
  const query = q?.trim() ?? "";

  const posts = query
    ? await client.fetch(SEARCH_QUERY, { search: `${query}*` })
    : [];

  return (
    <div className="max-w-3xl mx-auto px-6 py-12">
      <h1 className="text-4xl font-bold mb-8">Search</h1>

      <form className="mb-12">
        <input
          type="text"
          name="q"
          defaultValue={query}
          placeholder="Search articles..."
          className="w-full px-6 py-4 border rounded-2xl text-lg focus:outline-none focus:ring-2"
        />
      </form>

      {query && (
        <p className="mb-8 text-gray-600">
          Results for <span className="font-medium">"{query}"</span>
        </p>
      )}

      <div className="space-y-8">
        {posts.length > 0 ? (
          posts.map((post: any) => (
            <article key={post._id} className="border-b pb-8">
              <h2 className="text-2xl font-semibold mb-2">
                <a href={`/posts/${post.slug.current}`}>{post.title}</a>
              </h2>
              <p className="text-gray-600">{post.excerpt}</p>
            </article>
          ))
        ) : query ? (
          <p>No results found.</p>
        ) : null}
      </div>
    </div>
  );
}
```

---

### Add Search Query (`lib/queries.ts`)

```typescript
export const SEARCH_QUERY = `
  *[
    _type == "post" &&
    (title match $search || excerpt match $search)
  ] | order(publishedAt desc) {
    _id,
    title,
    slug,
    excerpt,
    author->{
      name
    }
  }
`;
```

---

### Add to Navigation

Update your `Navbar` to include a link to `/search`.

---

### Mental Model To Remember Forever

**Search is not magic.** It is:

```text
Data
   ↓
Filtering + Pattern Matching
   ↓
Projection + Sorting
   ↓
Results
```

Modern databases and search engines are sophisticated systems for **traversing and transforming structured data**.

---

### Up Next — Part 17: TypeScript for Content

We’ll add proper TypeScript types to our Sanity data layer, understand interfaces, and explore why strong typing makes large applications maintainable.
