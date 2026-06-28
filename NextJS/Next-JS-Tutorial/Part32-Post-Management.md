# Next.js 16 for Absolute Beginners

# Part 32 — Building the Post Management System with Server Actions and Cache Components

> **Goal of this lesson:** Build the core content engine of Nexus CMS: creating, editing, deleting, publishing, and caching blog posts using Next.js 16 Server Actions and Cache Components.

---

# Why Posts Matter

Every content platform revolves around one thing:

```text
Content
```

Everything else exists to support it:

```text
Users
   |
Permissions
   |
Editor
   |
Publishing
   |
Caching
   |
Analytics
```

If your content system is poorly designed, the entire application becomes difficult to maintain.

---

# What We're Building

By the end of this chapter, we'll have:

```text
✓ Post creation
✓ Post editing
✓ Drafts
✓ Publishing
✓ Unpublishing
✓ Deletion
✓ Slug generation
✓ Validation
✓ Server Actions
✓ Cache Components
✓ Cache invalidation
```

---

# Post Lifecycle

Real content systems don't have:

```text
Create
Delete
```

They have:

```text
Draft
   |
Review
   |
Publish
   |
Update
   |
Archive
```

---

# Visualizing Post Workflow

```text
        DRAFT
           |
           V
        REVIEW
           |
           V
      PUBLISHED
           |
           V
       ARCHIVED
```

---

# Step 1 — Create Post Validation

Create:

```text
lib/validators/post.ts
```

---

```ts
import { z } from "zod";

export const postSchema = z.object({

  title:
    z.string()
      .min(3)
      .max(200),

  excerpt:
    z.string()
      .max(500),

  content:
    z.any(),

  status:
    z.enum([
      "DRAFT",
      "REVIEW",
      "PUBLISHED",
      "ARCHIVED",
    ]),
});
```

---

# Why Validation?

Never trust:

```text
Forms
APIs
Users
JavaScript
```

Always validate on the server.

---

# Step 2 — Create Slug Generator

Create:

```text
lib/slug.ts
```

---

```ts
export function slugify(
  text: string
) {

  return text
    .toLowerCase()
    .trim()
    .replaceAll(
      " ",
      "-"
    )
    .replace(
      /[^a-z0-9-]/g,
      ""
    );
}
```

---

# Example

```ts
slugify(
  "Learning Next.js 16"
);
```

Returns:

```text
learning-nextjs-16
```

---

# Why Slugs?

Bad:

```text
/posts/73f29f31
```

Good:

```text
/posts/learning-nextjs-16
```

---

# Step 3 — Create Server Action Folder

```text
actions/posts/

    create.ts

    update.ts

    delete.ts

    publish.ts
```

---

# Why Separate Actions?

Bad:

```text
actions.ts
```

5000 lines later:

```text
Chaos.
```

---

# Step 4 — Create Post Action

```text
actions/posts/create.ts
```

---

```ts
"use server";

import { db }
  from "@/db/client";

import {
  postSchema
} from "@/lib/validators/post";

import {
  slugify
} from "@/lib/slug";

export async function
createPost(
  formData: FormData
) {

  const parsed =
    postSchema.parse({

      title:
        formData.get(
          "title"
        ),

      excerpt:
        formData.get(
          "excerpt"
        ),

      content:
        {},

      status:
        "DRAFT",

    });

  const slug =
    slugify(
      parsed.title
    );

  const post =
    await db.post.create({

      data: {

        title:
          parsed.title,

        slug,

        excerpt:
          parsed.excerpt,

        content:
          parsed.content,

      },

    });

  return post;
}
```

---

# Visualizing Post Creation

```text
Form
   |
Validation
   |
Slug
   |
Database
   |
Success
```

---

# Step 5 — Build Create Form

Create:

```text
app/(dashboard)/
dashboard/posts/new/
page.tsx
```

---

```tsx
import {
  createPost
} from
  "@/actions/posts/create";

export default function
NewPostPage() {

  return (

    <form
      action={
        createPost
      }
    >

      <input
        name="title"
      />

      <textarea
        name="excerpt"
      />

      <button>

        Create

      </button>

    </form>

  );

}
```

---

# What Just Happened?

No:

```text
fetch()
axios()
REST API
GraphQL
```

Just:

```tsx
<form action={serverAction}>
```

---

# Visualizing Server Actions

```text
Browser
    |
Form Submit
    |
Server Action
    |
Database
    |
Response
```

---

# Step 6 — Create Update Action

```ts
"use server";

export async function
updatePost(

  id: string,

  formData:
    FormData

) {

  const title =
    formData.get(
      "title"
    );

  const excerpt =
    formData.get(
      "excerpt"
    );

  await db.post.update({

    where: {
      id,
    },

    data: {

      title,

      excerpt,

    },

  });

}
```

---

# Edit Flow

```text
Load Post
    |
Display Form
    |
User Changes
    |
Server Action
    |
Database Update
```

---

# Step 7 — Create Delete Action

```ts
"use server";

export async function
deletePost(
  id: string
) {

  await db.post.delete({

    where: {
      id,
    },

  });

}
```

---

# Why Soft Delete Is Often Better

Bad:

```text
Delete
   |
Gone forever
```

Good:

```text
Delete
   |
Archive
   |
Recoverable
```

---

# Example Soft Delete

```prisma
deletedAt DateTime?
```

---

# Step 8 — Publish Action

```ts
"use server";

export async function
publishPost(
  id: string
) {

  await db.post.update({

    where: {
      id,
    },

    data: {

      status:
        "PUBLISHED",

      publishedAt:
        new Date(),

    },

  });

}
```

---

# Publishing Workflow

```text
Draft
   |
Review
   |
Published
```

---

# Step 9 — Build Dashboard Listing

```tsx
export default async function
PostsPage() {

  const posts =
    await db.post.findMany({

      orderBy: {

        createdAt:
          "desc",

      },

    });

  return (

    <div>

      {posts.map(

        post => (

          <div
            key={
              post.id
            }
          >

            {post.title}

          </div>

        )

      )}

    </div>

  );

}
```

---

# Visualizing Data Flow

```text
Database
    |
Server Component
    |
HTML
    |
Browser
```

---

# Step 10 — Dynamic Routes

Create:

```text
app/
(public)/
posts/
[slug]/
page.tsx
```

---

```tsx
export default async function
PostPage({

  params,

}: {

  params:
    Promise<{
      slug:
        string;
    }>;

}) {

  const {
    slug
  } =
    await params;

  const post =
    await db.post.findUnique({

      where: {
        slug,
      },

    });

  return (

    <article>

      {post?.title}

    </article>

  );

}
```

---

# Visualizing Dynamic Routes

```text
/posts/react
/posts/nextjs
/posts/typescript
```

---

# Step 11 — Add Cache Components

Create:

```text
lib/posts.ts
```

---

```ts
import {
  cacheTag,
  cacheLife,
} from "next/cache";

export async function
getPosts() {

  "use cache";

  cacheTag(
    "posts"
  );

  cacheLife(
    "hours"
  );

  return db.post.findMany({

    where: {

      status:
        "PUBLISHED",

    },

  });

}
```

---

# What Happens?

```text
First request
      |
Database
      |
Cache
      |
Subsequent requests
      |
Memory
```

---

# Visualizing Cache Components

```text
Request
   |
Cache?
   |
YES ------> Return
   |
NO
   |
Database
   |
Store Cache
```

---

# Step 12 — Use Cached Function

```tsx
import {
  getPosts
} from
  "@/lib/posts";

export default async function
BlogPage() {

  const posts =
    await getPosts();

  return (

    <div>

      {posts.map(

        post => (

          <div
            key={
              post.id
            }
          >

            {post.title}

          </div>

        )

      )}

    </div>

  );

}
```

---

# Why Cache Components?

Without cache:

```text
1000 visitors
      |
1000 queries
```

With cache:

```text
1000 visitors
      |
1 query
```

---

# Step 13 — Revalidate Cache

After publishing:

```ts
import {
  revalidateTag
} from
  "next/cache";

export async function
publishPost(
  id: string
) {

  await db.post.update({

    where: {
      id,
    },

    data: {

      status:
        "PUBLISHED",

    },

  });

  revalidateTag(
    "posts"
  );

}
```

---

# Visualizing Revalidation

```text
Cache
   |
Content changes
   |
Invalidate
   |
Next request
   |
Fresh content
```

---

# Step 14 — Build Post Metadata

```tsx
import type {
  Metadata,
} from "next";

export async function
generateMetadata({

  params,

}) : Promise<
  Metadata
> {

  const {
    slug
  } =
    await params;

  const post =
    await db.post.findUnique({

      where: {
        slug,
      },

    });

  return {

    title:
      post?.title,

    description:
      post?.excerpt,

  };

}
```

---

# Why Metadata?

Because:

```text
SEO
Social sharing
Search engines
```

---

# Step 15 — Add Not Found Handling

```tsx
import {
  notFound
} from
  "next/navigation";

if (!post) {

  notFound();

}
```

---

# Visualizing Error Handling

```text
Find Post
    |
Exists?
    |
YES ------> Render
    |
NO
    |
404
```

---

# Final Post Architecture

```text
Browser
    |
Server Component
    |
Cache Components
    |
Database
    |
Cache
```

---

# Final Publishing Architecture

```text
Editor
   |
Publish
   |
Database
   |
revalidateTag()
   |
Cache Cleared
   |
Fresh Content
```

---

# What We've Built

```text
✓ Post creation

✓ Editing

✓ Publishing

✓ Drafts

✓ Slugs

✓ Validation

✓ Dynamic routes

✓ Server Actions

✓ Cache Components

✓ Cache invalidation
```

---

# Post Management Philosophy

Beginners think:

```text
Posts
   =
CRUD
```

Professionals think:

```text
Posts
   =
Workflow
   +
Permissions
   +
Caching
   +
Publishing
   +
SEO
```

Because content management is not about editing text.

It's about managing the lifecycle of information.

---

# Exercises

## Exercise 1

Implement:

```text
Archive post
```

workflow.

---

## Exercise 2

Add:

```text
Featured posts
```

support.

---

## Exercise 3

Add:

```text
Scheduled publishing.
```

---

## Exercise 4

Add:

```text
Version history.
```

---

# Mental Model

Beginners build:

```text
Forms.
```

Professional engineers build:

```text
Content workflows.
```

---

# Part 33 Preview

In the next chapter we'll build:

# Categories, Tags, Taxonomies, and Search Architecture

Including:

```text
✓ Categories
✓ Tags
✓ Hierarchies
✓ Taxonomies
✓ Filtering
✓ Search
✓ Indexing
✓ Cache tagging
✓ SEO URLs
✓ Navigation systems
```

This is where content management becomes information architecture.
