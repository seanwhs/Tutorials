# Appendix B — Complete Source Code Structure (with Tailwind CSS Styling)

> **Goal of this appendix:** Provide a complete reference architecture for GreyMatter Journal, including the recommended folder structure, major source files, Tailwind CSS organization, and production-grade project layout. This appendix serves as both a companion to the tutorial series and a reference implementation for future projects.

---

# Introduction

Throughout this tutorial series, we built GreyMatter Journal incrementally.

By the end of the project, our application evolved far beyond a simple blog. It became a modern, production-grade web application featuring:

```text
✓ Next.js 16 App Router
✓ React Server Components
✓ Server Actions
✓ Sanity CMS
✓ Authentication
✓ Comments
✓ Likes
✓ Image optimization
✓ SEO
✓ Metadata
✓ Caching
✓ Draft mode
✓ Error boundaries
✓ Security
✓ Analytics
✓ Production architecture
```

This appendix presents the final recommended project structure.

---

# Final Project Structure

```text
greymatter-journal/

├── app/
│   ├── (site)/
│   │   ├── page.tsx
│   │   ├── posts/
│   │   │   ├── page.tsx
│   │   │   └── [slug]/
│   │   │       ├── page.tsx
│   │   │       ├── loading.tsx
│   │   │       ├── error.tsx
│   │   │       └── not-found.tsx
│   │   └── about/
│   │       └── page.tsx
│   │
│   ├── api/
│   │   ├── comments/
│   │   ├── likes/
│   │   └── revalidate/
│   │
│   ├── admin/
│   │
│   ├── globals.css
│   ├── layout.tsx
│   └── not-found.tsx
│
├── components/
│   ├── layout/
│   ├── posts/
│   ├── comments/
│   ├── ui/
│   └── providers/
│
├── lib/
│   ├── sanity.ts
│   ├── image.ts
│   ├── auth.ts
│   ├── cache.ts
│   ├── logger.ts
│   └── analytics.ts
│
├── actions/
│   ├── comments.ts
│   ├── likes.ts
│   └── posts.ts
│
├── hooks/
│
├── types/
│
├── public/
│
├── studio/
│
├── middleware.ts
├── next.config.ts
├── tailwind.config.ts
├── postcss.config.js
└── package.json
```

---

# Required Dependencies

Install all dependencies:

```bash
npm install \
next \
react \
react-dom \
sanity \
next-sanity \
@sanity/image-url \
@sanity/vision \
@sanity/icons \
tailwindcss \
@tailwindcss/postcss \
zod \
clsx \
tailwind-merge
```

Optional:

```bash
npm install \
@clerk/nextjs \
@vercel/analytics
```

---

# Tailwind Configuration

Create:

```text
tailwind.config.ts
```

```typescript
import type { Config } from "tailwindcss";

export default {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],

  theme: {
    extend: {
      colors: {
        primary: "#111827",
        secondary: "#6b7280",
        accent: "#2563eb",
      },

      maxWidth: {
        prose: "75ch",
      },
    },
  },

  plugins: [],
} satisfies Config;
```

---

# Global Styles

Create:

```text
app/globals.css
```

```css
@import "tailwindcss";

* {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
}

body {
  background: white;
  color: #111827;
}

.prose {
  max-width: 75ch;
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
      <body className="bg-white text-gray-900">
        {children}
      </body>
    </html>
  );
}
```

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
    <footer className="border-t mt-16">
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
    <div className="space-y-8">

      <section className="py-12">

        <h1 className="text-5xl font-bold">
          GreyMatter Journal
        </h1>

        <p className="mt-4 text-xl text-gray-600">
          Exploring software engineering,
          systems thinking, and architecture.
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

# Post Card Component

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

        <Link href={`/posts/${post.slug.current}`}>

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

# Article Page

```tsx
export default async function PostPage({
  params,
}: {
  params: Promise<{
    slug: string;
  }>;
}) {
  const { slug } = await params;

  const post =
    await getPostBySlug(slug);

  return (
    <article className="prose mx-auto">

      <h1>
        {post.title}
      </h1>

      <p>
        {post.excerpt}
      </p>

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
        className="
          w-full
          rounded-lg
          border
          p-3
        "
        placeholder="Name"
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
        setLikes(
          likes + 1
        )
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

GreyMatter Journal intentionally uses:

```text
Minimal
Readable
Content-focused
Responsive
Accessible
```

rather than:

```text
Heavy animations
Complex interactions
Visual effects
```

The goal is to maximize:

```text
Readability

Maintainability

Performance

Accessibility
```

---

# Final Architecture

```text
Browser
    │
    ▼

React Components
    │
    ▼

Next.js App Router
    │
    ▼

Server Components
    │
    ▼

Server Actions
    │
    ▼

Sanity CMS
    │
    ▼

CDN
    │
    ▼

Storage
```

---

# Mental Model To Remember Forever

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

The actual application consists of:

```text
Code

+
Data

+
Infrastructure

+
Deployment

+
Caching

+
Observability

+
Human Understanding
```

GreyMatter Journal may appear to be a blog.

In reality, it is a production-grade distributed information system built using modern web engineering principles.

A future **Appendix C** could cover **"Complete Sanity Studio Source Code and Schema Definitions"**, which would nicely complement this appendix.
