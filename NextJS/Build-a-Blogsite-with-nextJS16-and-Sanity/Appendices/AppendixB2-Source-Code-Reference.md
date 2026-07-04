# Appendix B — Part II

Appendix B is the **"Reference Implementation Appendix"**, and is split into two major sections:

```text
Appendix B
    ├── Part I
    │     Architecture & Repository Structure
    │
    └── **Part II**
          Core Source Code Reference
```

# Core Source Code Reference

> **Goal of this section:** Provide the canonical source code implementations for the major architectural subsystems of GreyMatter Journal. These files form the foundation of the application and illustrate how the various layers of the system work together.

---

# 1. Environment Variables

## `.env.local`

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID=xxxx
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-01-01

SANITY_API_READ_TOKEN=xxxx
SANITY_WEBHOOK_SECRET=xxxx

NEXT_PUBLIC_SITE_URL=http://localhost:3000

CLERK_SECRET_KEY=xxxx
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=xxxx
```

---

# 2. Sanity Client

## `lib/sanity.ts`

```typescript
import {
  createClient,
} from "next-sanity";

export const client =
  createClient({
    projectId:
      process.env
        .NEXT_PUBLIC_SANITY_PROJECT_ID,

    dataset:
      process.env
        .NEXT_PUBLIC_SANITY_DATASET,

    apiVersion:
      process.env
        .NEXT_PUBLIC_SANITY_API_VERSION,

    useCdn: true,

    perspective:
      "published",
  });
```

---

# 3. Sanity Image Builder

## `lib/image.ts`

```typescript
import imageUrlBuilder
  from "@sanity/image-url";

import { client }
  from "./sanity";

const builder =
  imageUrlBuilder(client);

export function urlFor(
  source: unknown
) {
  return builder.image(source);
}
```

---

# 4. GROQ Queries

## `lib/queries.ts`

```typescript
export const POSTS_QUERY = `
*[_type=="post"] | order(
  publishedAt desc
){
  _id,
  title,
  slug,
  excerpt,
  publishedAt,

  author->{
    name,
    slug
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
  excerpt,
  body,
  publishedAt,

  author->{
    name,
    bio,
    image
  },

  categories[]->{
    title
  },

  heroImage
}
`;
```

---

# 5. Type Definitions

## `types/post.ts`

```typescript
export interface Post {
  _id: string;

  title: string;

  excerpt: string;

  body: unknown[];

  publishedAt: string;

  slug: {
    current: string;
  };

  author: {
    name: string;
    bio?: string;
  };

  categories: {
    title: string;
  }[];
}
```

---

# 6. Design Tokens

## `styles/tokens.css`

```css
:root {
  --background: white;

  --foreground:
    #111827;

  --muted:
    #6b7280;

  --border:
    #e5e7eb;

  --accent:
    #2563eb;

  --radius:
    0.75rem;

  --content-width:
    75ch;

  --header-height:
    4rem;
}
```

---

# 7. Dark Theme

## `styles/themes.css`

```css
.dark {
  --background:
    #0f172a;

  --foreground:
    #f8fafc;

  --muted:
    #94a3b8;

  --border:
    #334155;

  --accent:
    #60a5fa;
}
```

---

# 8. Global Styles

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
  scroll-behavior:
    smooth;
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

# 9. Root Layout

## `app/layout.tsx`

```tsx
import "./globals.css";

export default function
RootLayout({
  children,
}: {
  children:
    React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        {children}
      </body>
    </html>
  );
}
```

---

# 10. Site Layout

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
          px-4
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

---

# 11. Header Component

## `components/layout/Header.tsx`

```tsx
import Link
  from "next/link";

import ThemeToggle
  from "./ThemeToggle";

export default function
Header() {
  return (
    <header
      className="
        border-b
      "
    >
      <div
        className="
          mx-auto
          flex
          max-w-6xl
          items-center
          justify-between
          px-4
          py-6
        "
      >
        <Link
          href="/"
          className="
            text-2xl
            font-bold
          "
        >
          GreyMatter Journal
        </Link>

        <nav
          className="
            flex
            gap-6
          "
        >
          <Link href="/">
            Home
          </Link>

          <Link href="/posts">
            Posts
          </Link>

          <Link href="/about">
            About
          </Link>
        </nav>

        <ThemeToggle />
      </div>
    </header>
  );
}
```

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

export default async function
HomePage() {

  const posts =
    await client.fetch(
      POSTS_QUERY
    );

  return (
    <div
      className="
        space-y-12
      "
    >
      <section
        className="
          py-12
        "
      >
        <h1
          className="
            text-5xl
            font-bold
          "
        >
          GreyMatter Journal
        </h1>

        <p
          className="
            mt-4
            text-xl
            text-gray-600
          "
        >
          Exploring
          software engineering,
          systems thinking,
          and architecture.
        </p>
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
import Link
  from "next/link";

import Image
  from "next/image";

export default function
PostCard({
  post,
}: any) {
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
            post.heroImage
          }
          alt={
            post.title
          }
          width={1200}
          height={600}
          className="
            h-64
            w-full
            object-cover
          "
        />
      )}

      <div
        className="p-6"
      >
        <Link
          href={
            `/posts/${post.slug.current}`
          }
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

        <p
          className="
            mt-4
            text-gray-600
          "
        >
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
  client,
} from "@/lib/sanity";

import {
  POST_QUERY,
} from "@/lib/queries";

import {
  notFound,
} from "next/navigation";

export default async function
PostPage({
  params,
}: {
  params:
    Promise<{
      slug:string;
    }>;
}) {

  const { slug } =
    await params;

  const post =
    await client.fetch(
      POST_QUERY,
      { slug }
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
    </article>
  );
}
```

---

# 15. Cache Revalidation

## `app/api/revalidate/route.ts`

```typescript
import {
  revalidateTag,
} from "next/cache";

export async function
POST() {

  revalidateTag(
    "posts"
  );

  return Response.json({
    revalidated:
      true,
  });
}
```

---

# 16. Theme Provider

## `components/providers/ThemeProvider.tsx`

```tsx
"use client";

import {
  createContext,
} from "react";

export const
ThemeContext =
  createContext(null);

export default function
ThemeProvider({
  children,
}: {
  children:
    React.ReactNode;
}) {

  return (
    <ThemeContext.Provider
      value={null}
    >
      {children}
    </ThemeContext.Provider>
  );
}
```

---

# 17. Portable Text Renderer

## `components/portable-text/PortableTextRenderer.tsx`

```tsx
import {
  PortableText,
} from "@portabletext/react";

export default function
PortableTextRenderer({
  value,
}: {
  value: unknown[];
}) {

  return (
    <PortableText
      value={value}
    />
  );
}
```

---

# 18. The Final System Diagram

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
