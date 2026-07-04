# **✅ Part 16-2 — Category Pages and URL-Based Filtering**

# GreyMatter Journal

## Part 16-2 — Category Pages and URL-Based Filtering: Taxonomies, URL State, and Structured Navigation

> **Goal of this lesson:** Build category pages using dynamic routes, understand why URLs are application state, and learn how modern systems organize information through taxonomies and filtering.

---

# Search Is Not Enough

In Part 16, we built search.

Search allows users to ask:

```text
Find something specific.
```

But many users don't know exactly what they're looking for.

Instead, they want to browse.

Examples:

```text
Show me React articles.

Show me Architecture posts.

Show me System Design tutorials.

Show me TypeScript content.
```

This introduces another fundamental concept in information systems:

```text
Search
       +
Classification
       +
Filtering
       =
Content Discovery
```

---

# Information Architecture

Nearly every information system organizes data using categories.

Examples:

```text
Amazon
    ↓
Product Categories

Netflix
    ↓
Genres

GitHub
    ↓
Topics

YouTube
    ↓
Channels + Categories

Blogs
    ↓
Tags + Categories
```

This process is called:

```text
Taxonomy
```

A taxonomy is simply:

> A system for organizing information into meaningful groups.

---

# Our Content Taxonomy

Our posts already contain categories:

```text
Post
    ├── Title
    ├── Excerpt
    ├── Author
    └── Categories
```

Example:

```text
Understanding React Server Components

Categories:
    • React
    • Next.js
    • Architecture
```

This allows us to create filtered views.

---

# URL State Again

Remember our rule from Part 16:

> State that users should bookmark or share belongs in the URL.

Examples:

```text
/search?q=react
```

and:

```text
/category/react
```

Both represent:

```text
Application State
```

encoded inside the URL.

Advantages:

* Bookmarkable
* Shareable
* SEO-friendly
* Cacheable
* Server-renderable

---

# Step 1 — Create the Category Route

Create:

```text
app/(site)/category/[slug]/page.tsx
```

Our application tree now becomes:

```text
app/
└── (site)/
    ├── page.tsx
    ├── search/
    ├── posts/
    └── category/
        └── [slug]/
            └── page.tsx
```

---

# Step 2 — Create the Category Query

Add to:

```text
lib/queries.ts
```

```typescript
export const CATEGORY_QUERY = `
  *[
    _type == "post" &&
    $slug in categories[]->slug.current
  ]
  | order(publishedAt desc)
  {
    _id,
    title,
    slug,
    excerpt,
    publishedAt,

    author->{
      name
    },

    categories[]->{
      title,
      slug
    }
  }
`;
```

Let's understand the important part:

```groq
$slug in categories[]->slug.current
```

This means:

> Return all posts whose category slugs contain the requested category.

For example:

```text
URL:
/category/react

becomes

$slug = "react"
```

---

# Step 3 — Create a Category Result Type

```typescript
type CategoryPost = {
  _id: string;

  title: string;

  slug: {
    current: string;
  };

  excerpt: string;

  publishedAt: string;

  author: {
    name: string;
  };

  categories: {
    title: string;
    slug: {
      current: string;
    };
  }[];
};
```

Remember:

```text
Types
      =
Contracts
```

---

# Step 4 — Build the Category Page

Create:

```text
app/(site)/category/[slug]/page.tsx
```

```tsx
import { client } from "@/lib/sanity";
import { CATEGORY_QUERY } from "@/lib/queries";

import PostCard
  from "@/components/posts/PostCard";

type Props = {
  params: Promise<{
    slug: string;
  }>;
};

export default async function CategoryPage({
  params,
}: Props) {
  const { slug } =
    await params;

  const posts: any[] =
    await client.fetch(
      CATEGORY_QUERY,
      {
        slug,
      }
    );

  return (
    <div className="mx-auto max-w-4xl px-6 py-12">

      <header className="mb-12">

        <p className="mb-2 text-sm uppercase tracking-widest text-gray-500">
          Category
        </p>

        <h1 className="text-5xl font-bold tracking-tight">
          {slug}
        </h1>

      </header>

      {posts.length === 0 ? (
        <div className="py-12 text-center text-gray-500">
          No posts found.
        </div>
      ) : (
        <div className="space-y-12">
          {posts.map((post) => (
            <PostCard
              key={post._id}
              post={post}
            />
          ))}
        </div>
      )}

    </div>
  );
}
```

---

# Step 5 — Make Categories Clickable

Update:

```text
components/posts/PostCard.tsx
```

Replace:

```tsx
<span>
  {cat.title}
</span>
```

with:

```tsx
import Link from "next/link";

<Link
  href={`/category/${cat.slug.current}`}
  className="
    text-xs
    uppercase
    tracking-widest
    text-blue-600
    hover:underline
  "
>
  {cat.title}
</Link>
```

Now:

```text
React
```

becomes:

```text
/category/react
```

---

# Dynamic Filtering

When a user clicks:

```text
/category/react
```

the application performs:

```text
URL
     ↓

Route Parameter
     ↓

GROQ Query
     ↓

Filter Posts
     ↓

Render Results
```

This pattern appears everywhere:

```text
Amazon
      ↓
Category Page

Netflix
      ↓
Genre Page

GitHub
      ↓
Topic Page

Blogs
      ↓
Tag Page
```

---

# Categories Are Graph Traversal

One of the deeper ideas here is:

```text
Post
      ↓
References
      ↓
Categories
```

Our content model is actually a graph:

```text
Post
 ├── Author
 └── Category
```

The GROQ query:

```groq
categories[]->slug.current
```

is performing graph traversal.

This means:

```text
Content Management
            =
Graph Navigation
```

---

# Search vs Filtering

Search and filtering solve different problems.

| Search                    | Filtering            |
| ------------------------- | -------------------- |
| User knows what they want | User wants to browse |
| Pattern matching          | Classification       |
| Free text                 | Structured data      |
| Flexible                  | Predictable          |

Modern applications combine both:

```text
Search
      +
Categories
      +
Tags
      +
Sorting
      +
Recommendations
```

to create effective discovery systems.

---

# URLs Are Application APIs

One of the most important architectural ideas in web development is:

```text
URLs
    =
Public APIs
```

These URLs:

```text
/category/react

/category/typescript

/category/architecture
```

become part of your application's contract.

Good URLs should be:

* Stable
* Predictable
* Readable
* Shareable
* Human-friendly

---

# Mental Model To Remember Forever

Beginners think:

```text
Category
       =
Menu Item
```

Professional engineers think:

```text
Category
       =
Information Taxonomy
```

More broadly:

```text
URL
    ↓
Route Parameter
    ↓
Filter
    ↓
Graph Traversal
    ↓
UI
```

Modern applications are fundamentally systems for organizing, traversing, and presenting structured information.

---

# Up Next — Part 17: TypeScript for Content Models

We'll introduce proper TypeScript contracts for our Sanity content layer and discover why large software systems scale through contracts rather than conventions.
