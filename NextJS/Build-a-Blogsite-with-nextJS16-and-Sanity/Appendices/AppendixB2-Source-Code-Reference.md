# Appendix B — Part II

# Core Source Code Reference

Appendix B is the **Reference Implementation Appendix**, and is divided into two complementary sections:

```text
Appendix B
    ├── Part I
    │     Architecture & Repository Structure
    │
    └── Part II
          Core Source Code Reference
```

> **Goal of this section:** Provide the canonical implementation patterns for GreyMatter Journal. These examples represent the architectural baseline for a modern content-driven application built with Next.js 16, React Server Components, Sanity CMS, and production-grade engineering practices.

---

# Introduction

Part I described the architecture.

Part II describes the implementation.

The purpose of this appendix is not to provide every line of source code. Rather, it provides the foundational implementations that define the major architectural subsystems:

```text
Configuration
        ↓
Infrastructure
        ↓
Domain Models
        ↓
Rendering
        ↓
Content
        ↓
Caching
        ↓
Authentication
        ↓
Observability
        ↓
Deployment
```

Together, these components form the executable architecture of GreyMatter Journal.

---

# 1. Environment Configuration

## `.env.local`

```bash
# Sanity
NEXT_PUBLIC_SANITY_PROJECT_ID=xxxx
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-01-01

SANITY_API_READ_TOKEN=xxxx
SANITY_WEBHOOK_SECRET=xxxx

# Site
NEXT_PUBLIC_SITE_URL=http://localhost:3000

# Authentication
CLERK_SECRET_KEY=xxxx
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=xxxx

# Analytics
VERCEL_ANALYTICS_ID=xxxx
```

---

# 2. Environment Validation

## `lib/env.ts`

```typescript
function required(
  value: string | undefined,
  name: string,
) {
  if (!value) {
    throw new Error(
      `Missing environment variable: ${name}`,
    );
  }

  return value;
}

export const env = {
  sanity: {
    projectId: required(
      process.env
        .NEXT_PUBLIC_SANITY_PROJECT_ID,
      "NEXT_PUBLIC_SANITY_PROJECT_ID",
    ),

    dataset: required(
      process.env
        .NEXT_PUBLIC_SANITY_DATASET,
      "NEXT_PUBLIC_SANITY_DATASET",
    ),

    apiVersion: required(
      process.env
        .NEXT_PUBLIC_SANITY_API_VERSION,
      "NEXT_PUBLIC_SANITY_API_VERSION",
    ),
  },
};
```

---

# 3. Sanity Client Architecture

## `lib/sanity.ts`

```typescript
import {
  createClient,
} from "next-sanity";

import { env }
  from "./env";

export const client =
  createClient({
    projectId:
      env.sanity.projectId,

    dataset:
      env.sanity.dataset,

    apiVersion:
      env.sanity.apiVersion,

    useCdn: true,

    perspective:
      "published",
  });

export const previewClient =
  client.withConfig({
    useCdn: false,

    perspective:
      "previewDrafts",

    token:
      process.env
        .SANITY_API_READ_TOKEN,
  });
```

This creates two realities:

```text
Published Reality
         ↓
client

Draft Reality
         ↓
previewClient
```

---

# 4. Image Pipeline

## `lib/image.ts`

```typescript
import imageUrlBuilder
  from "@sanity/image-url";

import {
  client,
} from "./sanity";

const builder =
  imageUrlBuilder(client);

export function urlFor(
  source: unknown,
) {
  return builder.image(source);
}
```

Images are not files.

They are:

```text
Asset
    +
Metadata
    +
Transformation Pipeline
```

---

# 5. GROQ Query Layer

## `lib/queries.ts`

```typescript
export const POSTS_QUERY = `
*[_type=="post"]
| order(publishedAt desc)
{
  _id,
  title,
  slug,
  excerpt,
  publishedAt,

  author->{
    name,
    slug,
    image
  },

  categories[]->{
    title,
    slug
  },

  heroImage
}
`;

export const POST_QUERY = `
*[
  _type=="post" &&
  slug.current==$slug
][0]{
  _id,
  title,
  slug,
  excerpt,
  body,
  publishedAt,

  author->{
    name,
    bio,
    image
  },

  categories[]->{
    title,
    slug
  },

  heroImage
}
`;

export const SEARCH_QUERY = `
*[
  _type=="post" &&
  (
    title match $search ||
    excerpt match $search
  )
]{
  _id,
  title,
  slug,
  excerpt
}
`;
```

---

# 6. Domain Models

## `types/post.ts`

```typescript
import {
  PortableTextBlock,
} from "@portabletext/types";

export interface Slug {
  current: string;
}

export interface Author {
  name: string;

  bio?: string;

  image?: unknown;

  slug?: Slug;
}

export interface Category {
  title: string;

  slug?: Slug;
}

export interface Post {
  _id: string;

  title: string;

  slug: Slug;

  excerpt: string;

  body?: PortableTextBlock[];

  heroImage?: unknown;

  publishedAt: string;

  author: Author;

  categories: Category[];
}
```

Types represent executable contracts.

---

# 7. Design Tokens

## `styles/tokens.css`

```css
:root {
  --background: white;

  --foreground: #111827;

  --muted: #6b7280;

  --border: #e5e7eb;

  --accent: #2563eb;

  --radius: 0.75rem;

  --content-width: 75ch;

  --header-height: 4rem;
}
```

---

# 8. Theme System

## `styles/themes.css`

```css
.dark {
  --background: #0f172a;

  --foreground: #f8fafc;

  --muted: #94a3b8;

  --border: #334155;

  --accent: #60a5fa;
}
```

---

# 9. Global Styling

## `app/globals.css`

```css
@import "tailwindcss";

@import "../styles/tokens.css";
@import "../styles/themes.css";
@import "../styles/prose.css";
@import "../styles/code.css";

*,
*::before,
*::after {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
}

body {
  min-height: 100vh;

  background:
    var(--background);

  color:
    var(--foreground);
}

img {
  display: block;

  max-width: 100%;
}
```

---

# 10. Root Layout

## `app/layout.tsx`

```tsx
import "./globals.css";

import {
  ClerkProvider,
} from "@clerk/nextjs";

import ThemeProvider
  from "@/components/providers/ThemeProvider";

import {
  Analytics,
} from "@vercel/analytics/react";

export default function
RootLayout({
  children,
}: {
  children:
    React.ReactNode;
}) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>
          <ThemeProvider>
            {children}

            <Analytics />
          </ThemeProvider>
        </body>
      </html>
    </ClerkProvider>
  );
}
```

---

# 11. Site Layout

## `app/(site)/layout.tsx`

```tsx
import Header
  from "@/components/layout/Header";

import Footer
  from "@/components/layout/Footer";

export default function
SiteLayout({
  children,
}: {
  children:
    React.ReactNode;
}) {
  return (
    <>
      <Header />

      <main
        className="
          mx-auto
          max-w-6xl
          px-6
          py-10
        "
      >
        {children}
      </main>

      <Footer />
    </>
  );
}
```

This creates a persistent UI shell.

---

# 12. Homepage

## `app/(site)/page.tsx`

```tsx
import {
  client,
} from "@/lib/sanity";

import {
  POSTS_QUERY,
} from "@/lib/queries";

import PostCard
  from "@/components/posts/PostCard";

import {
  Post,
} from "@/types/post";

export default async function
HomePage() {

  const posts =
    await client.fetch<
      Post[]
    >(
      POSTS_QUERY
    );

  return (
    <div className="space-y-12">
      <section>
        <h1
          className="
            text-5xl
            font-bold
          "
        >
          GreyMatter Journal
        </h1>
      </section>

      <section
        className="
          grid
          gap-8
        "
      >
        {posts.map(
          (post) => (
            <PostCard
              key={post._id}
              post={post}
            />
          )
        )}
      </section>
    </div>
  );
}
```

---

# 13. Post Card

## `components/posts/PostCard.tsx`

```tsx
import Image
  from "next/image";

import Link
  from "next/link";

import {
  urlFor,
} from "@/lib/image";

import {
  Post,
} from "@/types/post";

type Props = {
  post: Post;
};

export default function
PostCard({
  post,
}: Props) {
  return (
    <article
      className="
        overflow-hidden
        rounded-xl
        border
      "
    >
      {post.heroImage && (
        <Image
          src={
            urlFor(
              post.heroImage,
            )
              .width(1200)
              .height(600)
              .url()
          }
          alt={post.title}
          width={1200}
          height={600}
        />
      )}

      <div className="p-6">
        <Link
          href={`/posts/${post.slug.current}`}
        >
          <h2
            className="
              text-2xl
              font-bold
            "
          >
            {post.title}
          </h2>
        </Link>

        <p>
          {post.excerpt}
        </p>
      </div>
    </article>
  );
}
```

---

# 14. Dynamic Article Page

## `app/(site)/posts/[slug]/page.tsx`

```tsx
import {
  draftMode,
} from "next/headers";

import {
  notFound,
} from "next/navigation";

import {
  client,
  previewClient,
} from "@/lib/sanity";

import {
  POST_QUERY,
} from "@/lib/queries";

import PortableTextRenderer
  from "@/components/portable-text/PortableTextRenderer";

export default async function
PostPage({
  params,
}: {
  params:
    Promise<{
      slug: string;
    }>;
}) {

  const {
    slug,
  } = await params;

  const {
    isEnabled,
  } =
    await draftMode();

  const post =
    await (
      isEnabled
        ? previewClient
        : client
    ).fetch(
      POST_QUERY,
      { slug },
    );

  if (!post) {
    notFound();
  }

  return (
    <article
      className="
        prose
        prose-lg
        mx-auto
      "
    >
      <h1>
        {post.title}
      </h1>

      <p>
        {post.excerpt}
      </p>

      <PortableTextRenderer
        value={
          post.body
        }
      />
    </article>
  );
}
```

---

# 15. Portable Text Rendering

## `components/portable-text/PortableTextRenderer.tsx`

```tsx
import {
  PortableText,
} from "@portabletext/react";

const components = {
  block: {
    h1: ({ children }) =>
      <h1>{children}</h1>,

    h2: ({ children }) =>
      <h2>{children}</h2>,

    normal:
      ({ children }) =>
        <p>{children}</p>,
  },

  marks: {
    strong:
      ({ children }) =>
        <strong>
          {children}
        </strong>,
  },
};

export default function
PortableTextRenderer({
  value,
}: {
  value: unknown[];
}) {
  return (
    <PortableText
      value={value}
      components={
        components
      }
    />
  );
}
```

---

# 16. Draft Mode

## `app/api/draft/enable/route.ts`

```typescript
import {
  draftMode,
} from "next/headers";

import {
  redirect,
} from "next/navigation";

export async function
GET(
  request:
    Request,
) {

  const draft =
    await draftMode();

  draft.enable();

  const url =
    new URL(
      request.url,
    );

  const slug =
    url.searchParams.get(
      "slug",
    );

  redirect(
    slug
      ? `/posts/${slug}`
      : "/",
  );
}
```

---

# 17. Authentication

## `app/admin/page.tsx`

```tsx
import {
  auth,
} from "@clerk/nextjs/server";

export default async function
AdminPage() {

  const {
    userId,
  } =
    await auth();

  if (!userId) {
    return (
      <div>
        Unauthorized
      </div>
    );
  }

  return (
    <div>
      Admin Dashboard
    </div>
  );
}
```

---

# 18. Cache Revalidation

## `app/api/revalidate/route.ts`

```typescript
import {
  revalidateTag,
  revalidatePath,
} from "next/cache";

export async function
POST() {

  revalidateTag(
    "posts",
  );

  revalidatePath(
    "/",
  );

  revalidatePath(
    "/posts",
  );

  return Response.json({
    revalidated:
      true,
  });
}
```

---

# 19. Structured Logging

## `lib/logger.ts`

```typescript
export function log(
  message: string,
  metadata?: unknown,
) {
  console.log(
    JSON.stringify({
      timestamp:
        new Date()
          .toISOString(),

      message,

      metadata,
    }),
  );
}
```

---

# 20. Theme Provider

## `components/providers/ThemeProvider.tsx`

```tsx
"use client";

import {
  ThemeProvider
    as Provider,
} from "next-themes";

export default function
ThemeProvider({
  children,
}: {
  children:
    React.ReactNode;
}) {
  return (
    <Provider
      attribute="class"
      defaultTheme="system"
      enableSystem
    >
      {children}
    </Provider>
  );
}
```

---

# 21. Error Recovery

```text
Request
    ↓
loading.tsx
    ↓
page.tsx
    ↓
error.tsx
    ↓
not-found.tsx
    ↓
global-error.tsx
```

Failures should remain localized.

---

# 22. Cache Architecture

```text
Browser Cache
        ↓
Router Cache
        ↓
React Cache
        ↓
Next.js Data Cache
        ↓
CDN Cache
        ↓
Sanity CDN
```

Performance engineering is cache engineering.

---

# 23. System Architecture

```text
Browser
    ↓
React Tree
    ↓
App Router
    ↓
React Server Components
    ↓
Server Actions
    ↓
Cache Layer
    ↓
Authentication
    ↓
Sanity Content Lake
    ↓
CDN
    ↓
Storage
```

---

# Final Mental Model

Beginners see:

```text
Files

Folders

Frameworks
```

Professional engineers see:

```text
Boundaries

Contracts

Relationships

Caches

Flows

Constraints

Tradeoffs
```

GreyMatter Journal is not a collection of pages.

It is a collection of interacting systems.

And software architecture is ultimately the discipline of making those systems understandable.
