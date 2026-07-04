# Appendix B — Complete Source Code Structure and Reference Architecture

> **Goal of this appendix:** Provide the complete source code structure and reference architecture for **GreyMatter Journal**, including project organization, styling systems, design system foundations, production architecture patterns, and the rationale behind each major subsystem. This appendix serves both as a companion to the tutorial series and as a reference blueprint for building modern content-driven applications.

---

# Introduction

Throughout this tutorial series, we built **GreyMatter Journal** incrementally.

What started as a simple blog evolved into a production-grade distributed content platform featuring:

```text
✓ Next.js 16 App Router
✓ React Server Components
✓ Streaming & Suspense
✓ Server Actions
✓ Sanity CMS
✓ Portable Text
✓ Image Optimization
✓ Metadata & SEO
✓ Draft Mode
✓ Authentication
✓ Comments
✓ Likes
✓ Error Boundaries
✓ Loading States
✓ Caching & Revalidation
✓ Analytics
✓ Observability
✓ Dark Mode
✓ Design Tokens
✓ Design System Principles
✓ Production Architecture
```

Although GreyMatter Journal appears to be a blog, architecturally it is a distributed information system:

```text
Authors
    ↓
Sanity Studio
    ↓
Content Lake
    ↓
GROQ API
    ↓
Next.js Rendering Engine
    ↓
React Component Tree
    ↓
Browser
```

---

# Complete Repository Structure

```text
greymatter-journal/

├── app/
│
│   ├── (site)/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   │
│   │   ├── about/
│   │   │   └── page.tsx
│   │   │
│   │   ├── authors/
│   │   │   └── [slug]/
│   │   │       └── page.tsx
│   │   │
│   │   ├── categories/
│   │   │   └── [slug]/
│   │   │       └── page.tsx
│   │   │
│   │   └── posts/
│   │       ├── page.tsx
│   │       │
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
│   │
│   ├── comments/
│   │   ├── CommentForm.tsx
│   │   ├── CommentList.tsx
│   │   └── CommentCard.tsx
│   │
│   ├── layout/
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   └── ThemeToggle.tsx
│   │
│   ├── portable-text/
│   │   ├── PortableTextRenderer.tsx
│   │   ├── CodeBlock.tsx
│   │   └── ImageBlock.tsx
│   │
│   ├── posts/
│   │   ├── PostCard.tsx
│   │   ├── PostList.tsx
│   │   └── PostHero.tsx
│   │
│   ├── providers/
│   │   └── ThemeProvider.tsx
│   │
│   └── ui/
│       ├── Button.tsx
│       ├── Card.tsx
│       ├── Badge.tsx
│       └── Container.tsx
│
├── hooks/
│   ├── useTheme.ts
│   └── useLocalStorage.ts
│
├── lib/
│   ├── analytics.ts
│   ├── auth.ts
│   ├── cache.ts
│   ├── image.ts
│   ├── logger.ts
│   ├── queries.ts
│   ├── sanity.ts
│   ├── theme.ts
│   └── utils.ts
│
├── styles/
│   ├── tokens.css
│   ├── themes.css
│   └── prose.css
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
│   ├── schemaTypes/
│   ├── sanity.config.ts
│   └── package.json
│
├── middleware.ts
├── next.config.ts
├── tsconfig.json
├── postcss.config.js
└── package.json
```

---

# Understanding the Architecture

Professional engineers organize systems around responsibilities.

```text
app/
        =
Application Layer

components/
        =
Presentation Layer

actions/
        =
Mutation Layer

lib/
        =
Infrastructure Layer

types/
        =
Contracts

styles/
        =
Design System

studio/
        =
Content Management System
```

This separation allows complexity to scale without becoming chaos.

---

# Dependency Installation

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
@sanity/icons \
@sanity/vision \
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

Development:

```bash
npm install -D \
typescript \
tailwindcss \
@tailwindcss/postcss \
eslint \
eslint-config-next
```

---

# Styling Architecture

GreyMatter Journal follows a layered styling architecture:

```text
Design Tokens
        ↓
Themes
        ↓
Component Styles
        ↓
Page Layouts
        ↓
Content Presentation
```

---

# Design Tokens

```css
/* styles/tokens.css */

:root {
  --background: white;
  --foreground: #111827;

  --muted: #6b7280;

  --border: #e5e7eb;

  --accent: #2563eb;

  --radius: 0.75rem;

  --content-width: 75ch;
}
```

---

# Dark Theme

```css
/* styles/themes.css */

.dark {
  --background: #0f172a;

  --foreground: #f8fafc;

  --muted: #94a3b8;

  --border: #334155;

  --accent: #60a5fa;
}
```

---

# Global Styles

```css
/* app/globals.css */

@import "tailwindcss";

@import "../styles/tokens.css";
@import "../styles/themes.css";
@import "../styles/prose.css";

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

.prose {
  max-width:
    var(--content-width);
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

      <div className="
        mx-auto
        flex
        max-w-6xl
        items-center
        justify-between
        px-4
        py-6
      ">

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

      <div className="
        mx-auto
        max-w-6xl
        px-4
        py-8
      ">

        <p className="
          text-sm
          text-gray-500
        ">
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
    <article className="
      overflow-hidden
      rounded-xl
      border
    ">

      {post.heroImage && (
        <Image
          src={post.heroImage}
          alt={post.title}
          width={1200}
          height={600}
          className="
            h-64
            w-full
            object-cover
          "
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
    <article className="
      prose
      mx-auto
    ">

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

# Interactive Components

## Comment Form

```tsx
"use client";

export default function CommentForm() {
  return (
    <form className="space-y-4">
      {/* implementation */}
    </form>
  );
}
```

## Like Button

```tsx
"use client";

export default function LikeButton() {
  return (
    <button>
      ❤️
    </button>
  );
}
```

---

# Error Handling

```text
loading.tsx
        ↓
error.tsx
        ↓
not-found.tsx
```

Together, these create resilient user experiences.

---

# Final System Architecture

```text
Browser
    ↓
React Components
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
Caching
    +
Infrastructure
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

It is a map of how software systems, human understanding, and architectural decisions evolve together over time.
