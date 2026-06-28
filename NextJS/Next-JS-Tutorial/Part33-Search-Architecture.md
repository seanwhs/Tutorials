# Next.js 16 for Absolute Beginners

# Part 33 — Categories, Tags, Taxonomies, and Search Architecture

> **Goal of this lesson:** Build the information architecture layer of Nexus CMS by implementing categories, tags, taxonomies, filtering, search, navigation, and cache-aware content discovery.

---

# Why Taxonomies Matter

Beginners think content platforms look like this:

```text
Posts
   |
   +--- Post
   +--- Post
   +--- Post
```

Professional systems look like this:

```text
Content
    |
    +---- Categories
    |
    +---- Tags
    |
    +---- Search
    |
    +---- Navigation
    |
    +---- Recommendations
```

Because creating content is only half the problem.

The other half is:

> Helping people find it.

---

# What We're Building

By the end of this chapter, we'll have:

```text
✓ Categories
✓ Tags
✓ Category pages
✓ Tag pages
✓ Filtering
✓ Search
✓ SEO URLs
✓ Navigation
✓ Breadcrumbs
✓ Cache tagging
✓ Taxonomy architecture
```

---

# Information Architecture

Consider a bookstore.

You don't organize books like this:

```text
Book
Book
Book
Book
Book
```

You organize them by:

```text
Genre
   |
Topic
   |
Author
   |
Popularity
```

Content systems work exactly the same way.

---

# Visualizing Taxonomies

```text
                    Posts
                       |
            +----------+----------+
            |                     |
            V                     V
      Categories              Tags
            |                     |
            V                     V
       Navigation            Search
```

---

# Categories vs Tags

Many beginners ask:

> Aren't they the same?

No.

---

# Categories

Categories answer:

> What broad area does this belong to?

Example:

```text
Programming
    |
    +--- JavaScript
    +--- Python
    +--- Rust
```

---

# Tags

Tags answer:

> What specific concepts are involved?

Example:

```text
nextjs
react
typescript
performance
caching
```

---

# Visualizing the Difference

```text
Post:
Learning Next.js Cache Components

Category:
    Web Development

Tags:
    nextjs
    react
    cache
    performance
```

---

# Step 1 — Extend Category Model

Open:

```text
prisma/schema.prisma
```

---

```prisma
model Category {

  id String
     @id
     @default(uuid())

  name String
       @unique

  slug String
       @unique

  description String?

  icon String?

  createdAt DateTime
            @default(now())

  posts PostCategory[]

}
```

---

# Extend Tag Model

```prisma
model Tag {

  id String
     @id
     @default(uuid())

  name String
       @unique

  slug String
       @unique

  createdAt DateTime
            @default(now())

  posts PostTag[]

}
```

---

# Run Migration

```bash
npx prisma migrate dev \
--name taxonomy
```

---

# Step 2 — Create Category Server Action

Create:

```text
actions/categories/create.ts
```

---

```ts
"use server";

import { db }
  from "@/db/client";

import {
  slugify
} from "@/lib/slug";

export async function
createCategory(
  name: string
) {

  return db.category.create({

    data: {

      name,

      slug:
        slugify(name),

    },

  });

}
```

---

# Create Tag Action

```ts
"use server";

export async function
createTag(
  name: string
) {

  return db.tag.create({

    data: {

      name,

      slug:
        slugify(name),

    },

  });

}
```

---

# Step 3 — Attach Categories to Posts

Example:

```ts
await db.post.update({

  where: {

    id:
      postId,

  },

  data: {

    categories: {

      create: [

        {
          categoryId:
            category.id,
        },

      ],

    },

  },

});
```

---

# Visualizing Many-to-Many

```text
Post
   |
   +---- Category
   |
   +---- Category
   |
   +---- Category
```

---

# Step 4 — Attach Tags

```ts
await db.post.update({

  where: {
    id: postId,
  },

  data: {

    tags: {

      create: [

        {
          tagId:
            tag.id,
        },

      ],

    },

  },

});
```

---

# Step 5 — Build Cached Category Queries

Create:

```text
lib/categories.ts
```

---

```ts
import {
  cacheTag,
  cacheLife,
} from "next/cache";

export async function
getCategories() {

  "use cache";

  cacheTag(
    "categories"
  );

  cacheLife(
    "hours"
  );

  return db.category.findMany({

    include: {

      posts: true,

    },

  });

}
```

---

# Visualizing Category Cache

```text
Request
   |
Cache?
   |
YES ---> Return
   |
NO
   |
Database
```

---

# Step 6 — Build Category Navigation

Create:

```text
components/navigation/categories.tsx
```

---

```tsx
import Link
  from "next/link";

import {
  getCategories
} from
  "@/lib/categories";

export async function
CategoryNav() {

  const categories =

    await getCategories();

  return (

    <nav>

      {categories.map(

        category => (

          <Link

            key={
              category.id
            }

            href={

              `/categories/${
                category.slug
              }`

            }

          >

            {
              category.name
            }

          </Link>

        )

      )}

    </nav>

  );

}
```

---

# Visualizing Navigation

```text
Programming

Web Development

DevOps

Cloud

AI
```

---

# Step 7 — Create Category Pages

Create:

```text
app/
(public)/
categories/
[slug]/
page.tsx
```

---

```tsx
export default async function
CategoryPage({

  params,

}) {

  const {
    slug
  } =
    await params;

  const category =

    await db.category.findUnique({

      where: {

        slug,

      },

      include: {

        posts: {

          include: {

            post: true,

          },

        },

      },

    });

  return (

    <div>

      <h1>

        {
          category?.name
        }

      </h1>

    </div>

  );

}
```

---

# URL Structure

```text
/categories/web-development

/categories/programming

/categories/cloud
```

---

# Step 8 — Create Tag Pages

```text
/tags/react

/tags/nextjs

/tags/typescript
```

---

```tsx
export default async function
TagPage({

  params,

}) {

  const {
    slug
  } =
    await params;

  const tag =

    await db.tag.findUnique({

      where: {

        slug,

      },

      include: {

        posts: {

          include: {

            post: true,

          },

        },

      },

    });

  return (

    <div>

      {
        tag?.name
      }

    </div>

  );

}
```

---

# Step 9 — Build Search

Create:

```text
lib/search.ts
```

---

```ts
export async function
searchPosts(
  query: string
) {

  return db.post.findMany({

    where: {

      OR: [

        {
          title: {

            contains:
              query,

            mode:
              "insensitive",

          },

        },

        {
          excerpt: {

            contains:
              query,

            mode:
              "insensitive",

          },

        },

      ],

    },

  });

}
```

---

# Visualizing Search

```text
Search:
    nextjs

        |
        V

Find:

Next.js 16

Next.js Cache

Next.js Routing
```

---

# Step 10 — Add Cache Components to Search

```ts
export async function
popularPosts() {

  "use cache";

  cacheTag(
    "popular"
  );

  cacheLife(
    "hours"
  );

  return db.post.findMany({

    take: 10,

  });

}
```

---

# Why Not Cache Everything?

Because search is usually:

```text
User-specific
```

while navigation is:

```text
Globally shared
```

---

# Step 11 — Build Search Form

```tsx
export function
SearchForm() {

  return (

    <form
      action="/search"
    >

      <input

        name="q"

        placeholder=
          "Search"

      />

    </form>

  );

}
```

---

# Search Page

```tsx
export default async function
SearchPage({

  searchParams,

}) {

  const query =

    searchParams.q;

  const posts =

    await searchPosts(
      query
    );

  return (

    <div>

      {posts.map(

        post => (

          <div
            key={
              post.id
            }
          >

            {
              post.title
            }

          </div>

        )

      )}

    </div>

  );

}
```

---

# Visualizing Search Flow

```text
User
   |
Query
   |
Database
   |
Results
```

---

# Step 12 — Build Breadcrumbs

Example:

```text
Home
  >
Programming
  >
Next.js
  >
Cache Components
```

---

```tsx
export function
Breadcrumbs({

  items,

}) {

  return (

    <nav>

      {items.map(

        item => (

          <span
            key={
              item.href
            }
          >

            {
              item.label
            }

          </span>

        )

      )}

    </nav>

  );

}
```

---

# Step 13 — Category Cache Invalidation

After updating:

```ts
import {
  revalidateTag
} from "next/cache";

revalidateTag(
  "categories"
);
```

---

# Visualizing Cache Invalidation

```text
Editor
   |
Category change
   |
Invalidate
   |
Fresh category tree
```

---

# Step 14 — SEO Metadata

```tsx
export async function
generateMetadata({

  params,

}) {

  const category =

    await db.category
      .findUnique({

      where: {

        slug:
          params.slug,

      },

    });

  return {

    title:
      category?.name,

    description:
      category?.description,

  };

}
```

---

# Step 15 — Final Taxonomy Architecture

```text
                    Posts
                       |
          +------------+------------+
          |                         |
          V                         V
      Categories                Tags
          |                         |
          V                         V
      Navigation               Search
          |                         |
          +------------+------------+
                       |
                       V
                     SEO
```

---

# Search Architecture

```text
User
   |
Search
   |
Database
   |
Filter
   |
Ranking
   |
Results
```

---

# Information Architecture Philosophy

Beginners ask:

```text
How do I store content?
```

Professionals ask:

```text
How do people
discover content?
```

Because content nobody can find is content that effectively doesn't exist.

---

# What We've Built

```text
✓ Categories

✓ Tags

✓ Taxonomies

✓ Navigation

✓ Search

✓ Filtering

✓ SEO URLs

✓ Breadcrumbs

✓ Cache tags

✓ Invalidation
```

---

# Exercises

## Exercise 1

Implement:

```text
Nested categories
```

Example:

```text
Programming
    |
    JavaScript
        |
        Next.js
```

---

## Exercise 2

Implement:

```text
Related posts
```

using shared tags.

---

## Exercise 3

Implement:

```text
Trending tags
```

feature.

---

## Exercise 4

Add:

```text
Search suggestions
```

autocomplete.

---

# Mental Model

Beginners build:

```text
Data structures.
```

Professionals build:

```text
Information systems.
```

Because software isn't about storing information.

It's about helping humans navigate information.

---

# Part 34 Preview

In the next chapter we'll build:

# Rich Text Editing, Content Blocks, and Media Architecture

Including:

```text
✓ Rich text editor
✓ Content blocks
✓ Images
✓ Embeds
✓ Markdown
✓ JSON content
✓ Serialization
✓ Rendering
✓ Validation
✓ Media uploads
✓ Content architecture
```

This is where content management becomes document engineering.
