# Appendix B — Complete Source Code Structure and Reference Architecture

> **Goal of this appendix:** Provide the final reference architecture for **GreyMatter Journal**, including project structure, source organization, styling conventions, and the architectural reasoning behind each major folder. This appendix serves as both a companion to the tutorial series and a blueprint for future content-driven applications.

---

# Introduction

Throughout this tutorial series, we gradually built **GreyMatter Journal**.

What began as a simple blog evolved into a modern, production-grade content platform featuring:

```text
✓ Next.js 16 App Router
✓ React Server Components
✓ Streaming & Suspense
✓ Server Actions
✓ Sanity CMS
✓ Portable Text Rendering
✓ Image Optimization
✓ Draft Mode & Preview
✓ SEO & Metadata
✓ Error Boundaries
✓ Loading States
✓ Caching & Revalidation
✓ Comments & Likes
✓ Authentication
✓ Analytics & Observability
✓ Production Deployment
```

At first glance, it may still appear to be "just a blog."

Architecturally, however, it is a distributed information system consisting of multiple cooperating subsystems:

```text
Writers
    ↓
Sanity Studio
    ↓
Content Lake
    ↓
GROQ API
    ↓
Next.js Rendering Engine
    ↓
React Components
    ↓
Browser
```

This appendix presents the final recommended project structure and explains why it is organized this way.

---

# The Final Project Structure

```text
greymatter-journal/

├── app/
│   ├── (site)/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── about/
│   │   │   └── page.tsx
│   │   ├── authors/
│   │   │   └── [slug]/
│   │   │       └── page.tsx
│   │   ├── categories/
│   │   │   └── [slug]/
│   │   │       └── page.tsx
│   │   └── posts/
│   │       ├── page.tsx
│   │       └── [slug]/
│   │           ├── page.tsx
│   │           ├── loading.tsx
│   │           ├── error.tsx
│   │           └── not-found.tsx
│   │
│   ├── api/
│   │   ├── comments/
│   │   ├── likes/
│   │   ├── draft/
│   │   └── revalidate/
│   │
│   ├── globals.css
│   ├── layout.tsx
│   ├── loading.tsx
│   ├── error.tsx
│   └── not-found.tsx
│
├── actions/
│   ├── comments.ts
│   ├── likes.ts
│   └── posts.ts
│
├── components/
│   ├── comments/
│   ├── layout/
│   ├── portable-text/
│   ├── posts/
│   ├── ui/
│   └── providers/
│
├── hooks/
│
├── lib/
│   ├── analytics.ts
│   ├── auth.ts
│   ├── cache.ts
│   ├── image.ts
│   ├── logger.ts
│   ├── queries.ts
│   ├── sanity.ts
│   └── utils.ts
│
├── public/
│
├── types/
│   ├── author.ts
│   ├── category.ts
│   ├── comment.ts
│   ├── post.ts
│   └── index.ts
│
├── studio/
│
├── middleware.ts
├── next.config.ts
├── tsconfig.json
├── postcss.config.js
└── package.json
```

---

# Understanding the Structure

Professional engineers do not organize folders randomly.

Each directory has a specific responsibility.

```text
app/
    =
Application Shell
    +
Routes
    +
Layouts

components/
    =
Reusable UI

lib/
    =
Infrastructure
    +
External Systems

actions/
    =
Server-side Mutations

types/
    =
Application Contracts

studio/
    =
Content Management System
```

This separation keeps the application maintainable as it grows.

---

# Recommended Dependencies

Core dependencies:

```bash
npm install \
next \
react \
react-dom \
sanity \
next-sanity \
@sanity/image-url \
@portabletext/react \
@sanity/vision \
@sanity/icons \
zod \
clsx \
tailwind-merge
```

Optional:

```bash
npm install \
@clerk/nextjs \
@vercel/analytics \
@vercel/speed-insights
```

Development dependencies:

```bash
npm install -D \
typescript \
tailwindcss \
@tailwindcss/postcss \
eslint \
eslint-config-next
```

---

# Tailwind CSS in Next.js 16

With modern versions of Next.js and Tailwind, configuration is intentionally minimal.

Most projects no longer need extensive theme configuration.

Our styling philosophy is:

```text
Simple
Minimal
Readable
Composable
```

---

# Global Styles

```css
@import "tailwindcss";

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
}

img {
  display: block;
  max-width: 100%;
}

.prose {
  max-width: 75ch;
}
```

As the application grows, we may add:

```css
pre {
  overflow-x: auto;
  padding: 1rem;
}

code {
  font-family:
    "JetBrains Mono",
    monospace;
}
```

---

# Root Layout

```tsx
import "./globals.css";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
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

Remember:

```text
Root Layout
        =
Application Shell
```

It persists across every route in the application.

---

# Site Layout

```tsx
import Header from "@/components/layout/Header";
import Footer from "@/components/layout/Footer";

export default function SiteLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <Header />

      <main className="mx-auto max-w-6xl px-4 py-10">
        {children}
      </main>

      <Footer />
    </>
  );
}
```

This gives us:

```text
Persistent Header
        +
Persistent Footer
        +
Dynamic Content Area
```

which is the foundation of modern application architecture.

---

# Header Component

```tsx
import Link from "next/link";

export default function Header() {
  return (
    <header className="border-b">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-6">

        <Link
          href="/"
          className="text-2xl font-bold"
        >
          GreyMatter Journal
        </Link>

        <nav className="flex gap-6">
          <Link href="/">Home</Link>
          <Link href="/posts">Posts</Link>
          <Link href="/about">About</Link>
        </nav>

      </div>
    </header>
  );
}
```

---

# Footer Component

```tsx
export default function Footer() {
  return (
    <footer className="mt-16 border-t">
      <div className="mx-auto max-w-6xl px-4 py-8">

        <p className="text-sm text-gray-500">
          © 2026 GreyMatter Journal
        </p>

      </div>
    </footer>
  );
}
```

---

# Homepage

```tsx
import { getPosts } from "@/lib/sanity";
import PostCard from "@/components/posts/PostCard";

export default async function HomePage() {
  const posts = await getPosts();

  return (
    <div className="space-y-12">

      <section className="py-12">

        <h1 className="text-5xl font-bold">
          GreyMatter Journal
        </h1>

        <p className="mt-4 text-xl text-gray-600">
          Exploring software engineering,
          systems thinking,
          and architecture.
        </p>

      </section>

      <section className="grid gap-8">
        {posts.map((post) => (
          <PostCard
            key={post._id}
            post={post}
          />
        ))}
      </section>

    </div>
  );
}
```

---

# Post Card

```tsx
import Image from "next/image";
import Link from "next/link";

export default function PostCard({
  post,
}: any) {
  return (
    <article className="overflow-hidden rounded-xl border">

      {post.heroImage && (
        <Image
          src={post.heroImage}
          alt={post.title}
          width={1200}
          height={600}
          className="h-64 w-full object-cover"
        />
      )}

      <div className="p-6">

        <Link
          href={`/posts/${post.slug.current}`}
        >
          <h2 className="text-2xl font-bold">
            {post.title}
          </h2>
        </Link>

        <p className="mt-4 text-gray-600">
          {post.excerpt}
        </p>

      </div>
    </article>
  );
}
```

---

# Dynamic Article Page

```tsx
export default async function PostPage({
  params,
}: {
  params: Promise<{
    slug: string;
  }>;
}) {
  const { slug } =
    await params;

  const post =
    await getPostBySlug(slug);

  return (
    <article className="prose mx-auto">

      <h1>{post.title}</h1>

      <p>{post.excerpt}</p>

      <PortableText
        value={post.body}
      />

    </article>
  );
}
```

---

# Comment Form

```tsx
"use client";

export default function CommentForm() {
  return (
    <form className="space-y-4">

      <input
        placeholder="Name"
        className="
          w-full
          rounded-lg
          border
          p-3
        "
      />

      <textarea
        className="
          h-40
          w-full
          rounded-lg
          border
          p-3
        "
      />

      <button
        className="
          rounded-lg
          bg-black
          px-4
          py-2
          text-white
        "
      >
        Submit
      </button>

    </form>
  );
}
```

---

# Like Button

```tsx
"use client";

import { useState } from "react";

export default function LikeButton() {
  const [likes, setLikes] =
    useState(0);

  return (
    <button
      onClick={() =>
        setLikes(likes + 1)
      }
      className="
        rounded-lg
        border
        px-4
        py-2
      "
    >
      ❤️ {likes}
    </button>
  );
}
```

---

# Error Boundary

```tsx
"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error;
  reset: () => void;
}) {
  return (
    <div>

      <h2>
        Something went wrong.
      </h2>

      <button
        onClick={reset}
      >
        Retry
      </button>

    </div>
  );
}
```

---

# Loading State

```tsx
export default function Loading() {
  return (
    <div className="animate-pulse">

      <div className="h-10 bg-gray-200" />

      <div className="mt-4 h-6 bg-gray-200" />

    </div>
  );
}
```

---

# Not Found

```tsx
export default function NotFound() {
  return (
    <div className="py-20">

      <h1 className="text-4xl font-bold">
        404
      </h1>

      <p>
        Article not found.
      </p>

    </div>
  );
}
```

---

# Design Philosophy

GreyMatter Journal intentionally prioritizes:

```text
Readability
Maintainability
Accessibility
Performance
Simplicity
```

rather than:

```text
Heavy animations
Complex interactions
Visual effects
Over-engineered interfaces
```

The goal is to maximize the reading experience.

Because ultimately:

```text
Content
     >
Decoration
```

---

# Final Architecture

```text
Browser
    ↓
React Components
    ↓
Next.js App Router
    ↓
React Server Components
    ↓
Server Actions
    ↓
Sanity Content Lake
    ↓
CDN
    ↓
Storage
```

---

# The Most Important Mental Model

Beginners think:

```text
Source Code
        =
Application
```

Professional engineers think:

```text
Source Code
        =
Blueprint
```

The real application consists of:

```text
Code
    +
Data
    +
Infrastructure
    +
Caching
    +
Deployment
    +
Observability
    +
Human Understanding
```

GreyMatter Journal may appear to be a blog.

In reality, it is a production-grade distributed information system built using modern web engineering principles.

This appendix is not merely a folder reference.

It is a reminder that architecture is ultimately about organizing complexity so that both humans and systems can evolve safely over time.
