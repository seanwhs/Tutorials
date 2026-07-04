# **✅ Part 16-1 — Building Search and Filtering**

# GreyMatter Journal

## Part 16 — Building Search and Filtering: Queries, URL State, and Information Retrieval

> **Goal of this lesson:** Build a search experience for GreyMatter Journal while understanding how modern applications use URL state, server-side filtering, and information retrieval systems.

---

# The Content Discovery Problem

Our blog now has:

* Layouts
* Navigation
* Dynamic routes
* Rich content
* Images

But every content system eventually encounters the same problem:

```text
More Content
       ↓
More Complexity
       ↓
Harder Discovery
```

Readers need ways to answer questions like:

* Show me articles about React
* Find posts about architecture
* Search for TypeScript tutorials
* Browse content by category

This is where search and filtering become essential.

---

# Search Is Really Data Transformation

Many developers think search is a special feature.

In reality:

```text
Search
     =
Filtering
     +
Pattern Matching
     +
Sorting
     +
Projection
```

For example:

```text
All Posts
      ↓
Filter matching titles
      ↓
Sort by date
      ↓
Return selected fields
      ↓
Render results
```

Modern search systems—from SQL databases to Elasticsearch to GROQ—follow this same fundamental pattern.

---

# Step 1 — Create the Search Route

Create:

```text
app/(site)/search/page.tsx
```

Our application structure now becomes:

```text
app/
└── (site)/
    ├── page.tsx
    ├── posts/
    ├── about/
    └── search/
        └── page.tsx
```

---

# Understanding URL State

One of the most important ideas in modern web applications is:

> State that users should share, bookmark, or refresh belongs in the URL.

Instead of:

```text
Application State
       ↓
React State
```

search works better as:

```text
Application State
       ↓
URL Parameters
```

Example:

```text
/search?q=react
```

or:

```text
/search?q=typescript
```

Advantages:

* Shareable
* Bookmarkable
* SEO-friendly
* Browser history compatible
* Survives refreshes

---

# Step 2 — Create the Search Query

Create inside:

```text
lib/queries.ts
```

```typescript
export const SEARCH_QUERY = `
  *[
    _type == "post" &&
    (
      title match $search ||
      excerpt match $search
    )
  ]
  | order(publishedAt desc)
  {
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

Let's examine the query.

```groq
title match $search
```

means:

> Return posts whose title matches the search pattern.

Likewise:

```groq
excerpt match $search
```

searches article summaries.

---

# Step 3 — Create a Search Result Type

Avoid using:

```typescript
any
```

Instead:

```typescript
type SearchResult = {
  _id: string;

  title: string;

  slug: {
    current: string;
  };

  excerpt: string;

  author: {
    name: string;
  };
};
```

Remember:

```text
Types
      =
Contracts
```

---

# Step 4 — Build the Search Page

```tsx
import Link from "next/link";

import { client } from "@/lib/sanity";
import { SEARCH_QUERY } from "@/lib/queries";

type SearchResult = {
  _id: string;

  title: string;

  slug: {
    current: string;
  };

  excerpt: string;

  author: {
    name: string;
  };
};

type Props = {
  searchParams: Promise<{
    q?: string;
  }>;
};

export default async function SearchPage({
  searchParams,
}: Props) {
  const { q } =
    await searchParams;

  const query =
    q?.trim() ?? "";

  const posts: SearchResult[] =
    query
      ? await client.fetch(
          SEARCH_QUERY,
          {
            search: `${query}*`,
          }
        )
      : [];

  return (
    <div className="mx-auto max-w-4xl px-6 py-12">

      <header className="mb-12">
        <h1 className="mb-4 text-5xl font-bold tracking-tight">
          Search
        </h1>

        <p className="text-gray-600">
          Search articles across
          GreyMatter Journal.
        </p>
      </header>

      <form className="mb-12">

        <input
          type="search"
          name="q"
          defaultValue={query}
          placeholder="Search articles..."
          className="
            w-full
            rounded-2xl
            border
            px-6
            py-4
            text-lg
            outline-none
            focus:ring-2
          "
        />

      </form>

      {query && (
        <p className="mb-8 text-sm text-gray-500">
          Found {posts.length}
          {" "}
          result(s) for
          {" "}
          <strong>{query}</strong>
        </p>
      )}

      <div className="space-y-8">

        {posts.length > 0 ? (

          posts.map((post) => (
            <article
              key={post._id}
              className="border-b pb-8"
            >
              <Link
                href={`/posts/${post.slug.current}`}
              >
                <h2 className="mb-3 text-2xl font-semibold hover:underline">
                  {post.title}
                </h2>
              </Link>

              <p className="mb-3 text-gray-600">
                {post.excerpt}
              </p>

              <p className="text-sm text-gray-500">
                By {post.author.name}
              </p>
            </article>
          ))

        ) : query ? (

          <div className="py-12 text-center text-gray-500">
            No articles found.
          </div>

        ) : null}

      </div>
    </div>
  );
}
```

---

# Why Is `searchParams` a Promise?

Just like `params`, Next.js 16 treats URL state asynchronously:

```tsx
type Props = {
  searchParams: Promise<{
    q?: string;
  }>;
};
```

This allows integration with:

* React Server Components
* Suspense
* Streaming
* Partial rendering
* Future rendering optimizations

This is why we write:

```tsx
const { q } =
  await searchParams;
```

---

# Why Search Happens on the Server

Traditional React applications often did this:

```text
Browser
      ↓
Fetch everything
      ↓
Filter locally
```

Modern applications prefer:

```text
Browser
      ↓
Request search
      ↓
Server filters data
      ↓
Send only results
```

Benefits:

* Less JavaScript
* Smaller payloads
* Better performance
* Better SEO
* More secure data access

---

# GROQ Search vs Search Engines

Our current search:

```groq
title match $search
```

is not a full search engine.

It performs:

```text
Pattern Matching
```

rather than:

```text
Full Text Search
```

As GreyMatter Journal grows, we might later integrate:

* Algolia
* Meilisearch
* Elasticsearch
* Typesense

But the architectural principle remains identical:

```text
Data
      ↓
Filter
      ↓
Rank
      ↓
Sort
      ↓
Return Results
```

---

# Mental Model To Remember Forever

Beginners think:

```text
Search
     =
Magic
```

Professional engineers think:

```text
Search
     =
Data Transformation
```

More concretely:

```text
URL
    ↓
Parameters
    ↓
Query
    ↓
Filtering
    ↓
Sorting
    ↓
Projection
    ↓
UI
```

Modern applications are fundamentally systems for transforming structured data into user experiences.

---

# Up Next — Part 17: TypeScript for Content Models

Next we'll introduce proper TypeScript contracts for our content layer and learn why large applications scale through contracts rather than conventions.
