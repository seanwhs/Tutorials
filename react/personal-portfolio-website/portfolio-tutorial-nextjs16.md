# Tutorial: Building Your Personal Portfolio Website (Next.js 16)

*A complete beginner's guide to building a modern, performant portfolio with Next.js 16, TypeScript, Tailwind CSS, Sanity CMS, and explicit caching — aligned with the project's Software Requirements Document (SRD) and Architecture Document.*

---

## Before You Start

This tutorial is part of a multi-document system:
- **This tutorial** — hands-on, step-by-step building instructions
- **[Software Requirements Document (SRD)](sandbox:///mnt/agents/output/srd-nextjs16.md)** — what the system must do (requirements)
- **[Architecture Document](sandbox:///mnt/agents/output/architecture-nextjs16.md)** — how the system is structured technically

> 💡 **Key difference from older tutorials**: Next.js 16 uses **explicit caching**. Nothing is cached unless you add `'use cache'`. This gives you precise control but requires intentional opt-in. Next.js 16 also replaces `middleware.ts` with `proxy.ts` and makes all request APIs (`params`, `cookies`, `headers`) fully asynchronous.

---

## Table of Contents

1. [Introduction & Goals](#1-introduction--goals)
2. [Prerequisites & Setup](#2-prerequisites--setup)
3. [Project Structure](#3-project-structure)
4. [Next.js 16 Concepts](#4-nextjs-16-concepts)
5. [Building the Foundation](#5-building-the-foundation)
6. [Creating Pages](#6-creating-pages)
7. [Connecting to Sanity CMS](#7-connecting-to-sanity-cms)
8. [Adding the Blog with Explicit Caching](#8-adding-the-blog-with-explicit-caching)
9. [Contact Form](#9-contact-form)
10. [Proxy (Request Interception)](#10-proxy-request-interception)
11. [Deploying to Vercel](#11-deploying-to-vercel)
12. [Next Steps](#12-next-steps)

---

## 1. Introduction & Goals

### What You'll Build

A professional portfolio website with:
- A stunning home/landing page
- An about page with your bio and skills
- A projects showcase
- A blog (content managed via Sanity CMS)
- A contact form
- Fully responsive design (mobile, tablet, desktop)
- Lightning-fast performance with explicit caching
- SEO-friendly structure

### Why This Stack?

| Technology | Why We Use It |
|------------|---------------|
| **Next.js 16 (App Router)** | Explicit caching (`'use cache'`), `proxy.ts`, Turbopack, async request APIs |
| **TypeScript** | Type safety (required for Next.js 16) |
| **Tailwind CSS** | Rapid styling without leaving your HTML |
| **Sanity CMS** | Headless CMS for blog content |
| **Vercel** | Zero-config deployment, global edge network, native Next.js 16 support |

---

## 2. Prerequisites & Setup

### What You Need

- **Node.js 20.9+** installed (required for Next.js 16)
- **npm** (comes with Node.js)
- A **GitHub** account
- A **Vercel** account
- Basic knowledge of HTML, CSS, and JavaScript

### Step 1: Create a New Next.js 16 Project

Open your terminal and run:

```bash
npx create-next-app@latest portfolio --typescript --tailwind --eslint --app --src-dir --no-import-alias
```

When prompted, select:
- **TypeScript**: Yes
- **Tailwind CSS**: Yes
- **ESLint**: Yes
- **App Router**: Yes (required for Next.js 16)
- **src/ directory**: Yes
- **Customize import alias**: No

> 🔗 **Architecture**: We use the App Router because it enables React Server Components and the explicit caching model. See [Architecture §4.3](sandbox:///mnt/agents/output/architecture-nextjs16.md#43-rendering-strategy-by-route).

```bash
cd portfolio
npm run dev
```

Open `http://localhost:3000` in your browser.

### Step 2: Verify Next.js 16

Check your `package.json`:

```json
"dependencies": {
  "next": "^16.0.0",
  "react": "^19.0.0",
  "react-dom": "^19.0.0"
}
```

If you see Next.js 15 or lower, upgrade:

```bash
npm install next@latest react@latest react-dom@latest
```

### Step 3: Initialize Git

```bash
git init
git add .
git commit -m "Initial commit: Next.js 16 + TypeScript + Tailwind"
```

---

## 3. Project Structure

Let's organize our code according to the [Architecture Document](sandbox:///mnt/agents/output/architecture-nextjs16.md#41-directory-structure):

```
portfolio/
├── app/                          # Next.js 16 App Router
│   ├── page.tsx                  # Home page (route: /)
│   ├── layout.tsx                # Root layout
│   ├── globals.css               # Global styles
│   ├── about/
│   │   └── page.tsx              # About page (route: /about)
│   ├── projects/
│   │   └── page.tsx              # Projects page (route: /projects)
│   ├── blog/
│   │   ├── page.tsx              # Blog listing (route: /blog)
│   │   └── [slug]/
│   │       └── page.tsx          # Individual blog post (route: /blog/hello-world)
│   ├── contact/
│   │   └── page.tsx              # Contact page (route: /contact)
│   ├── api/
│   │   └── revalidate/
│   │       └── route.ts          # Tag invalidation webhook
│   └── proxy.ts                  # Request interception (replaces middleware.ts)
│
├── components/                   # Reusable React components
│   ├── ui/                       # Buttons, Cards, Badges
│   ├── layout/                   # Navbar, Footer
│   └── sections/                 # Hero, ProjectsGrid, BlogList
│
├── lib/                          # Utility code
│   ├── sanity.ts                 # Sanity client configuration
│   ├── sanity-image.ts           # Image URL builder
│   ├── groq-queries.ts           # GROQ queries
│   ├── loadPosts.ts              # Cached data loaders ('use cache')
│   └── utils.ts                  # Helper functions
│
├── types/                        # TypeScript type definitions
│   └── index.ts
│
├── public/                       # Static assets
│   └── images/
│
├── next.config.ts                # Next.js 16 configuration
├── tailwind.config.ts            # Tailwind configuration
└── tsconfig.json                 # TypeScript configuration
```

Create these directories:

```bash
mkdir -p components/ui components/layout components/sections
mkdir -p lib types public/images
mkdir -p app/about app/projects app/blog app/blog/\[slug\] app/contact app/api/revalidate
```

> 🔗 **Architecture**: This structure separates concerns. Note `proxy.ts` replaces `middleware.ts` in Next.js 16. See [Architecture §7](sandbox:///mnt/agents/output/architecture-nextjs16.md#7-proxy--request-interception).

---

## 4. Next.js 16 Concepts

Before writing code, understand these key Next.js 16 changes from Next.js 14/15:

### Explicit Caching

In Next.js 16, **nothing is cached by default**. You must opt-in:

```typescript
// ❌ Next.js 14: implicit caching with ISR
export const revalidate = 60;

// ✅ Next.js 16: explicit caching with 'use cache'
async function getData() {
  'use cache';
  cacheTag('posts');
  // ... fetch data
}
```

### Async Request APIs

All request APIs are now **asynchronous** in Next.js 16:

```typescript
// ❌ Next.js 14/15: synchronous access
export default function Page({ params }) {
  const { slug } = params;  // This no longer works!
}

// ✅ Next.js 16: asynchronous access
export default async function Page({ params }) {
  const { slug } = await params;  // Must await!
}
```

This applies to:
- `params` in pages, layouts, routes
- `searchParams` in pages
- `cookies()`
- `headers()`
- `draftMode()`

> **Reference**: [Next.js 16 Async Request APIs](https://nextjs.org/docs/app/guides/upgrading/version-16)

### Cache Tags

Tag cached data so you can invalidate it later:

```typescript
import { cacheTag } from 'next/cache';

async function loadPosts() {
  'use cache';
  cacheTag('posts');        // Tag this cache entry
  // fetch from Sanity...
}
```

Invalidate when content changes:

```typescript
import { revalidateTag } from 'next/cache';

// In a route handler or webhook:
revalidateTag('posts', 'max');  // Clear all 'posts' cache entries
```

### `proxy.ts` Replaces `middleware.ts`

```typescript
// app/proxy.ts — replaces middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export default async function proxy(req: NextRequest) {
  // Request interception logic
  return NextResponse.next();
}
```

> 🔗 **Architecture**: See [Architecture §6-7](sandbox:///mnt/agents/output/architecture-nextjs16.md#6-caching--revalidation-nextjs-16) for full caching and proxy details.

---

## 5. Building the Foundation

### Step 1: Configure Tailwind

```typescript
// tailwind.config.ts
import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: "#eff6ff",
          100: "#dbeafe",
          500: "#3b82f6",
          600: "#2563eb",
          700: "#1d4ed8",
        },
      },
      fontFamily: {
        sans: ["var(--font-inter)", "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [require("@tailwindcss/typography")],
};

export default config;
```

### Step 2: Set Up the Root Layout

```tsx
// app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Navbar from "@/components/layout/Navbar";
import Footer from "@/components/layout/Footer";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata: Metadata = {
  title: "Your Name | Portfolio",
  description: "Full-stack developer, designer, and writer.",
  openGraph: {
    title: "Your Name | Portfolio",
    description: "Full-stack developer, designer, and writer.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="font-sans antialiased bg-white text-gray-900 min-h-screen flex flex-col">
        <Navbar />
        <main className="flex-grow">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
```

> 🔗 **Architecture**: Using `next/font` optimizes font loading. See [Performance Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#102-optimization-strategies).

### Step 3: Global Styles

```css
/* app/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html { scroll-behavior: smooth; }
  body { @apply text-gray-900 bg-white; }
  h1, h2, h3, h4, h5, h6 { @apply font-bold tracking-tight; }
}

@layer components {
  .container-custom {
    @apply max-w-6xl mx-auto px-4 sm:px-6 lg:px-8;
  }
}
```

### Step 4: Create Utility Functions

```typescript
// lib/utils.ts
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(date: string): string {
  return new Date(date).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}
```

```bash
npm install clsx tailwind-merge
```

---

## 6. Creating Pages

### Step 1: Build the Navigation Component

```tsx
// components/layout/Navbar.tsx
"use client";

import Link from "next/link";
import { useState } from "react";
import { Menu, X } from "lucide-react";

const navLinks = [
  { href: "/", label: "Home" },
  { href: "/about", label: "About" },
  { href: "/projects", label: "Projects" },
  { href: "/blog", label: "Blog" },
  { href: "/contact", label: "Contact" },
];

export default function Navbar() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <nav className="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b">
      <div className="container-custom flex items-center justify-between h-16">
        <Link href="/" className="text-xl font-bold text-primary-600">
          Your Name
        </Link>

        <div className="hidden md:flex items-center gap-8">
          {navLinks.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="text-gray-600 hover:text-primary-600 transition-colors font-medium"
            >
              {link.label}
            </Link>
          ))}
        </div>

        <button
          className="md:hidden p-2"
          onClick={() => setIsOpen(!isOpen)}
          aria-label="Toggle menu"
        >
          {isOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>

      {isOpen && (
        <div className="md:hidden border-t bg-white">
          <div className="container-custom py-4 flex flex-col gap-4">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className="text-gray-600 hover:text-primary-600 py-2"
                onClick={() => setIsOpen(false)}
              >
                {link.label}
              </Link>
            ))}
          </div>
        </div>
      )}
    </nav>
  );
}
```

```bash
npm install lucide-react
```

> 🔗 **SRD**: The navigation must be persistent across all pages and include links to Home, About, Projects, Blog, and Contact. See [FR-32, FR-33](sandbox:///mnt/agents/output/srd-nextjs16.md#36-feature-navigation--layout).

### Step 2: Build the Footer

```tsx
// components/layout/Footer.tsx
import Link from "next/link";
import { Github, Linkedin, Twitter } from "lucide-react";

export default function Footer() {
  return (
    <footer className="border-t bg-gray-50">
      <div className="container-custom py-8">
        <div className="flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-gray-600 text-sm">
            © {new Date().getFullYear()} Your Name. All rights reserved.
          </p>
          <div className="flex items-center gap-4">
            <Link href="https://github.com/yourusername" className="text-gray-400 hover:text-gray-900">
              <Github size={20} />
            </Link>
            <Link href="https://linkedin.com/in/yourusername" className="text-gray-400 hover:text-gray-900">
              <Linkedin size={20} />
            </Link>
            <Link href="https://twitter.com/yourusername" className="text-gray-400 hover:text-gray-900">
              <Twitter size={20} />
            </Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
```

### Step 3: Create the Home Page (Hero Section)

```tsx
// app/page.tsx
import Link from "next/link";
import { ArrowRight } from "lucide-react";

export default function HomePage() {
  return (
    <section className="container-custom py-20 md:py-32">
      <div className="max-w-3xl">
        <h1 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
          Hi, I'm <span className="text-primary-600">Your Name</span>
        </h1>
        <p className="text-xl md:text-2xl text-gray-600 mb-8 leading-relaxed">
          I'm a full-stack developer who builds accessible, performant, and beautiful web experiences.
        </p>
        <div className="flex flex-wrap gap-4">
          <Link
            href="/projects"
            className="inline-flex items-center gap-2 px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium"
          >
            View My Work <ArrowRight size={18} />
          </Link>
          <Link
            href="/contact"
            className="inline-flex items-center gap-2 px-6 py-3 border-2 border-gray-300 text-gray-700 rounded-lg hover:border-primary-600 hover:text-primary-600 transition-colors font-medium"
          >
            Get In Touch
          </Link>
        </div>
      </div>
    </section>
  );
}
```

### Step 4: Create the About Page

```tsx
// app/about/page.tsx
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "About | Your Name",
  description: "Learn more about my background, skills, and experience.",
};

const skills = [
  "React", "Next.js", "TypeScript", "Tailwind CSS", "Node.js",
  "Sanity CMS", "PostgreSQL", "Docker", "AWS", "Vercel"
];

const experiences = [
  {
    title: "Senior Frontend Developer",
    company: "Tech Company",
    period: "2023 - Present",
    description: "Leading frontend architecture and building scalable React applications.",
  },
  {
    title: "Full Stack Developer",
    company: "Startup Inc",
    period: "2021 - 2023",
    description: "Built and deployed full-stack applications using Next.js and Node.js.",
  },
];

export default function AboutPage() {
  return (
    <div className="container-custom py-16">
      <h1 className="text-4xl font-bold mb-8">About Me</h1>
      <div className="grid md:grid-cols-2 gap-12">
        <div>
          <p className="text-lg text-gray-600 mb-6 leading-relaxed">
            I'm a passionate developer with 5+ years of experience building web applications.
            I specialize in the React ecosystem and love creating accessible, performant user interfaces.
          </p>
          <p className="text-lg text-gray-600 mb-6 leading-relaxed">
            When I'm not coding, you'll find me writing technical blog posts, contributing to open source,
            or exploring new web technologies.
          </p>
          <a
            href="/resume.pdf"
            download
            className="inline-flex items-center px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
          >
            Download Resume
          </a>
        </div>
        <div>
          <h2 className="text-2xl font-bold mb-4">Skills</h2>
          <div className="flex flex-wrap gap-2 mb-8">
            {skills.map((skill) => (
              <span key={skill} className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm font-medium">
                {skill}
              </span>
            ))}
          </div>
          <h2 className="text-2xl font-bold mb-4">Experience</h2>
          <div className="space-y-6">
            {experiences.map((exp) => (
              <div key={exp.title} className="border-l-2 border-primary-600 pl-4">
                <h3 className="font-bold text-lg">{exp.title}</h3>
                <p className="text-primary-600 font-medium">{exp.company}</p>
                <p className="text-gray-500 text-sm mb-2">{exp.period}</p>
                <p className="text-gray-600">{exp.description}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
```

### Step 5: Create the Projects Page

```tsx
// app/projects/page.tsx
import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { ExternalLink, Github } from "lucide-react";

export const metadata: Metadata = {
  title: "Projects | Your Name",
  description: "A collection of my recent projects and work.",
};

const projects = [
  {
    title: "E-Commerce Platform",
    description: "A full-stack e-commerce solution built with Next.js, Stripe, and Sanity CMS.",
    image: "/images/project-1.jpg",
    tags: ["Next.js", "Stripe", "Sanity"],
    liveUrl: "https://example.com",
    repoUrl: "https://github.com/yourusername/project",
  },
  {
    title: "Task Management App",
    description: "A collaborative task manager with real-time updates using WebSockets.",
    image: "/images/project-2.jpg",
    tags: ["React", "Node.js", "Socket.io"],
    liveUrl: "https://example.com",
    repoUrl: "https://github.com/yourusername/project",
  },
  {
    title: "AI Content Generator",
    description: "An AI-powered tool for generating blog posts and social media content.",
    image: "/images/project-3.jpg",
    tags: ["Next.js", "OpenAI", "Tailwind"],
    liveUrl: "https://example.com",
    repoUrl: "https://github.com/yourusername/project",
  },
];

export default function ProjectsPage() {
  return (
    <div className="container-custom py-16">
      <h1 className="text-4xl font-bold mb-4">Projects</h1>
      <p className="text-gray-600 mb-12 text-lg">
        A selection of projects I've worked on. Each one taught me something new.
      </p>
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
        {projects.map((project) => (
          <article key={project.title} className="group border rounded-xl overflow-hidden hover:shadow-lg transition-shadow">
            <div className="relative h-48 bg-gray-100">
              <Image src={project.image} alt={project.title} fill className="object-cover" />
            </div>
            <div className="p-6">
              <h2 className="text-xl font-bold mb-2 group-hover:text-primary-600 transition-colors">
                {project.title}
              </h2>
              <p className="text-gray-600 mb-4">{project.description}</p>
              <div className="flex flex-wrap gap-2 mb-4">
                {project.tags.map((tag) => (
                  <span key={tag} className="px-3 py-1 bg-primary-50 text-primary-700 rounded-full text-xs font-medium">
                    {tag}
                  </span>
                ))}
              </div>
              <div className="flex gap-4">
                <Link href={project.liveUrl} className="inline-flex items-center gap-1 text-sm font-medium text-primary-600 hover:underline">
                  <ExternalLink size={14} /> Live Demo
                </Link>
                <Link href={project.repoUrl} className="inline-flex items-center gap-1 text-sm font-medium text-gray-600 hover:text-gray-900">
                  <Github size={14} /> Source
                </Link>
              </div>
            </div>
          </article>
        ))}
      </div>
    </div>
  );
}
```

> 🔗 **SRD**: Projects must display title, description, thumbnail, tech stack tags, and links to live/demo URLs. See [FR-11 through FR-14](sandbox:///mnt/agents/output/srd-nextjs16.md#33-feature-projects-showcase).

---

## 7. Connecting to Sanity CMS

### Step 1: Install Sanity Client

```bash
npm install @sanity/client @sanity/image-url @portabletext/react next-sanity
```

### Step 2: Create the Sanity Client

```typescript
// lib/sanity.ts
import { createClient } from "@sanity/client";
import imageUrlBuilder from "@sanity/image-url";

const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET || "production",
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2026-06-28",
  useCdn: true,
});

const builder = imageUrlBuilder(client);

export function urlFor(source: any) {
  return builder.image(source);
}

export default client;
```

> 🔗 **Architecture**: The Sanity client is configured with `useCdn: true` for production. See [Data Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#52-data-flow).

> 🔗 **SRD**: API tokens must never be exposed client-side. Only `NEXT_PUBLIC_` variables are embedded in the browser bundle. See [Security Requirements](sandbox:///mnt/agents/output/srd-nextjs16.md#52-security-requirements).

### Step 3: Create Environment Variables

```bash
# .env.local
NEXT_PUBLIC_SANITY_PROJECT_ID=your-project-id
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-06-28
SANITY_API_TOKEN=your-sanity-read-token
SANITY_WEBHOOK_SECRET=your-webhook-secret
```

> ⚠️ **Important**: Never commit `.env.local` to Git! It's already in `.gitignore` by default.

> 🔗 **Architecture**: See the [Environment Variable Security](sandbox:///mnt/agents/output/architecture-nextjs16.md#93-environment-variable-security) table.

### Step 4: Define GROQ Queries

```typescript
// lib/groq-queries.ts
import { groq } from "next-sanity";

export const allPostsQuery = groq`
  *[_type == "blogPost" && publishedAt < now()] | order(publishedAt desc) {
    _id,
    title,
    "slug": slug.current,
    publishedAt,
    excerpt,
    coverImage,
    tags
  }
`;

export const postBySlugQuery = groq`
  *[_type == "blogPost" && slug.current == $slug][0] {
    _id,
    title,
    "slug": slug.current,
    publishedAt,
    excerpt,
    coverImage,
    tags,
    content
  }
`;
```

---

## 8. Adding the Blog with Explicit Caching

This is where Next.js 16 differs most from earlier versions. We use **`'use cache'`** and **`cacheTag`** for explicit, controllable caching.

### Step 1: Create Cached Data Loaders

```typescript
// lib/loadPosts.ts
import { cacheTag } from "next/cache";
import client from "./sanity";
import { allPostsQuery, postBySlugQuery } from "./groq-queries";

export async function loadPosts() {
  "use cache";
  cacheTag("posts");

  const posts = await client.fetch(allPostsQuery);
  return posts;
}

export async function loadPostBySlug(slug: string) {
  "use cache";
  cacheTag(`post:${slug}`);
  cacheTag("posts");

  const post = await client.fetch(postBySlugQuery, { slug });
  return post;
}
```

> 🔗 **Architecture**: `'use cache'` opts this function into Next.js 16's cache. `cacheTag` registers it for targeted invalidation. See [Caching Architecture](sandbox:///mnt/agents/output/architecture-nextjs16.md#6-caching--revalidation-nextjs-16).

> 🔗 **SRD**: Blog posts must be fetched via cached data loaders using `'use cache'` and `cacheTag`. See [FR-23, FR-24](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching).

### Step 2: Create the Blog Listing Page

```tsx
// app/blog/page.tsx
import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { urlFor } from "@/lib/sanity";
import { loadPosts } from "@/lib/loadPosts";
import { formatDate } from "@/lib/utils";

export const metadata: Metadata = {
  title: "Blog | Your Name",
  description: "Thoughts on web development, design, and technology.",
};

export default async function BlogPage() {
  const posts = await loadPosts();  // Cached via 'use cache'

  return (
    <div className="container-custom py-16">
      <h1 className="text-4xl font-bold mb-4">Blog</h1>
      <p className="text-gray-600 mb-12 text-lg">
        Thoughts on web development, design, and technology.
      </p>

      {posts.length === 0 ? (
        <p className="text-gray-500">No posts yet. Write your first one in Sanity Studio!</p>
      ) : (
        <div className="grid md:grid-cols-2 gap-8">
          {posts.map((post: any) => (
            <article
              key={post._id}
              className="group border rounded-xl overflow-hidden hover:shadow-lg transition-all duration-300"
            >
              {post.coverImage && (
                <div className="relative h-56 overflow-hidden">
                  <Image
                    src={urlFor(post.coverImage).width(800).height(400).url()}
                    alt={post.title}
                    fill
                    className="object-cover group-hover:scale-105 transition-transform duration-500"
                  />
                </div>
              )}

              <div className="p-6">
                <div className="text-sm text-gray-500 mb-2">
                  {formatDate(post.publishedAt)}
                </div>

                <h2 className="text-xl font-bold mb-2 group-hover:text-primary-600 transition-colors">
                  <Link href={`/blog/${post.slug}`}>{post.title}</Link>
                </h2>

                {post.excerpt && (
                  <p className="text-gray-600 mb-4 line-clamp-3">{post.excerpt}</p>
                )}

                {post.tags && (
                  <div className="flex flex-wrap gap-2">
                    {post.tags.map((tag: string) => (
                      <span key={tag} className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-xs font-medium">
                        {tag}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
```

> **Key difference from Next.js 14**: No `export const revalidate = 60`. Caching is handled by `'use cache'` in `loadPosts()`.

> 🔗 **SRD**: Blog listing must show all published posts ordered by date with title, excerpt, cover image, and tags. See [FR-16, FR-17](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching).

### Step 3: Create Individual Blog Post Pages

```tsx
// app/blog/[slug]/page.tsx
import { Metadata } from "next";
import Image from "next/image";
import { PortableText } from "@portabletext/react";
import { urlFor } from "@/lib/sanity";
import { loadPostBySlug, loadPosts } from "@/lib/loadPosts";
import { formatDate } from "@/lib/utils";

// Generate static params at build time
export async function generateStaticParams() {
  const posts = await loadPosts();
  return posts.map((post: any) => ({
    slug: post.slug,
  }));
}

// Dynamic metadata
export async function generateMetadata({
  params,
}: {
  params: { slug: string };
}): Promise<Metadata> {
  const post = await loadPostBySlug(params.slug);
  return {
    title: `${post.title} | Your Name`,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: post.coverImage ? [urlFor(post.coverImage).width(1200).url()] : [],
    },
  };
}

export default async function BlogPostPage({
  params,
}: {
  params: { slug: string };
}) {
  const post = await loadPostBySlug(params.slug);

  if (!post) {
    return (
      <div className="container-custom py-16">
        <h1 className="text-2xl font-bold">Post not found</h1>
        <p className="text-gray-600 mt-2">
          The post you're looking for doesn't exist or hasn't been published yet.
        </p>
      </div>
    );
  }

  return (
    <article className="container-custom py-16 max-w-3xl">
      <header className="mb-8">
        <div className="text-sm text-gray-500 mb-2">
          {formatDate(post.publishedAt)}
        </div>
        <h1 className="text-4xl md:text-5xl font-bold mb-4">{post.title}</h1>
        {post.excerpt && (
          <p className="text-xl text-gray-600 italic leading-relaxed">{post.excerpt}</p>
        )}
      </header>

      {post.coverImage && (
        <div className="relative h-96 w-full mb-8 rounded-xl overflow-hidden">
          <Image
            src={urlFor(post.coverImage).width(1200).height(600).url()}
            alt={post.title}
            fill
            className="object-cover"
            priority
          />
        </div>
      )}

      {post.tags && (
        <div className="flex flex-wrap gap-2 mb-8">
          {post.tags.map((tag: string) => (
            <span key={tag} className="px-3 py-1 bg-primary-100 text-primary-800 rounded-full text-sm font-medium">
              {tag}
            </span>
          ))}
        </div>
      )}

      <div className="prose prose-lg max-w-none prose-headings:font-bold prose-a:text-primary-600 prose-img:rounded-lg">
        <PortableText
          value={post.content}
          components={{
            types: {
              image: ({ value }: { value: any }) => (
                <div className="relative h-64 w-full my-6">
                  <Image
                    src={urlFor(value).width(800).url()}
                    alt={value.alt || "Blog image"}
                    fill
                    className="object-cover rounded-lg"
                  />
                </div>
              ),
              code: ({ value }: { value: any }) => (
                <pre className="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto my-6">
                  <code className="text-sm">{value.code}</code>
                </pre>
              ),
            },
          }}
        />
      </div>

      <div className="mt-12 pt-8 border-t">
        <a href="/blog" className="text-primary-600 hover:text-primary-700 font-medium">
          ← Back to all posts
        </a>
      </div>
    </article>
  );
}
```

> 🔗 **SRD**: Individual posts must render full Portable Text content with images and code blocks. See [FR-19, FR-20](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching).

> 🔗 **SRD**: Posts must generate SEO-friendly URLs and Open Graph meta tags. See [FR-22, FR-26](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching).

### Install Tailwind Typography Plugin

```bash
npm install @tailwindcss/typography
```

Add to `tailwind.config.ts`:

```typescript
plugins: [require("@tailwindcss/typography")],
```

---

## 9. Contact Form

```tsx
// app/contact/page.tsx
import { Metadata } from "next";
import ContactForm from "@/components/sections/ContactForm";

export const metadata: Metadata = {
  title: "Contact | Your Name",
  description: "Get in touch for collaborations, opportunities, or just to say hello.",
};

export default function ContactPage() {
  return (
    <div className="container-custom py-16 max-w-2xl">
      <h1 className="text-4xl font-bold mb-4">Get In Touch</h1>
      <p className="text-gray-600 mb-8">
        Have a project in mind or just want to chat? I'd love to hear from you.
      </p>
      <ContactForm />
      <div className="mt-12 pt-8 border-t">
        <h2 className="text-lg font-bold mb-4">Other ways to reach me</h2>
        <div className="space-y-2 text-gray-600">
          <p>Email: <a href="mailto:you@example.com" className="text-primary-600 hover:underline">you@example.com</a></p>
          <p>GitHub: <a href="https://github.com/yourusername" className="text-primary-600 hover:underline">@yourusername</a></p>
        </div>
      </div>
    </div>
  );
}
```

```tsx
// components/sections/ContactForm.tsx
"use client";

import { useState } from "react";
import { Send, CheckCircle } from "lucide-react";

export default function ContactForm() {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setIsSubmitting(true);

    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData);

    try {
      const response = await fetch("/api/contact", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });

      if (response.ok) setIsSubmitted(true);
    } catch (error) {
      console.error("Failed to send message:", error);
    } finally {
      setIsSubmitting(false);
    }
  }

  if (isSubmitted) {
    return (
      <div className="text-center py-12">
        <CheckCircle className="mx-auto h-16 w-16 text-green-500 mb-4" />
        <h2 className="text-2xl font-bold mb-2">Message Sent!</h2>
        <p className="text-gray-600">Thanks for reaching out. I'll get back to you soon.</p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div>
        <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">Name</label>
        <input type="text" id="name" name="name" required
          className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none"
          placeholder="Your name" />
      </div>
      <div>
        <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">Email</label>
        <input type="email" id="email" name="email" required
          className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none"
          placeholder="you@example.com" />
      </div>
      <div>
        <label htmlFor="subject" className="block text-sm font-medium text-gray-700 mb-1">Subject</label>
        <input type="text" id="subject" name="subject" required
          className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none"
          placeholder="What's this about?" />
      </div>
      <div>
        <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-1">Message</label>
        <textarea id="message" name="message" required rows={5}
          className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none resize-none"
          placeholder="Your message..." />
      </div>
      <button type="submit" disabled={isSubmitting}
        className="w-full inline-flex items-center justify-center gap-2 px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 font-medium disabled:opacity-50">
        {isSubmitting ? "Sending..." : "Send Message"} <Send size={18} />
      </button>
    </form>
  );
}
```

> 🔗 **SRD**: Contact form must have Name, Email, Subject, and Message fields with validation. See [FR-28 through FR-31](sandbox:///mnt/agents/output/srd-nextjs16.md#35-feature-contact).

---

## 10. Proxy (Request Interception)

In Next.js 16, `proxy.ts` replaces `middleware.ts`:

```typescript
// app/proxy.ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export default async function proxy(req: NextRequest) {
  // Example: Redirect unauthenticated admin routes
  if (req.nextUrl.pathname.startsWith("/admin")) {
    const token = req.cookies.get("session");
    if (!token) {
      return NextResponse.redirect(new URL("/login", req.url));
    }
  }

  // Example: Add security headers to all responses
  const response = NextResponse.next();
  response.headers.set("X-Frame-Options", "DENY");
  response.headers.set("X-Content-Type-Options", "nosniff");

  return response;
}

export const config = {
  matcher: ["/admin/:path*", "/api/:path*", "/blog/:path*"],
};
```

> 🔗 **Architecture**: `proxy.ts` handles global request interception. Keep it minimal — heavy logic belongs in Route Handlers. See [Architecture §7](sandbox:///mnt/agents/output/architecture-nextjs16.md#7-proxy--request-interception).

> 🔗 **SRD**: The system shall use `proxy.ts` (not `middleware.ts`) for global request interception. See [FR-49](sandbox:///mnt/agents/output/srd-nextjs16.md#39-feature-request-interception-proxyts).

---

## 11. Deploying to Vercel

### Step 1: Set Up Revalidation Webhook

```typescript
// app/api/revalidate/route.ts
import { revalidateTag } from "next/cache";
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  const secret = request.headers.get("x-sanity-webhook-secret");

  if (secret !== process.env.SANITY_WEBHOOK_SECRET) {
    return NextResponse.json({ message: "Invalid secret" }, { status: 401 });
  }

  const body = await request.json();
  const { _type, slug } = body;

  if (_type === "blogPost") {
    // Invalidate the posts listing
    revalidateTag("posts", "max");

    // Invalidate the specific post
    if (slug?.current) {
      revalidateTag(`post:${slug.current}`, "max");
    }

    return NextResponse.json({
      revalidated: true,
      tags: ["posts", slug?.current ? `post:${slug.current}` : null].filter(Boolean),
    });
  }

  return NextResponse.json({ message: "Unknown type" }, { status: 400 });
}
```

> 🔗 **Architecture**: `revalidateTag(tag, 'max')` immediately clears cached entries with that tag. See [Architecture §6](sandbox:///mnt/agents/output/architecture-nextjs16.md#6-caching--revalidation-nextjs-16).

> 🔗 **SRD**: The system shall invalidate the `posts` cache tag and specific `post:{slug}` tags when content changes. See [FR-44 through FR-48](sandbox:///mnt/agents/output/srd-nextjs16.md#38-feature-cache-invalidation-nextjs-16).

### Step 2: Push to GitHub

```bash
git add .
git commit -m "Add portfolio with Next.js 16 explicit caching"
git push origin main
```

### Step 3: Configure Vercel

1. Import your GitHub repo on [vercel.com](https://vercel.com)
2. Add environment variables:

| Variable | Environment |
|----------|-------------|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | Production, Preview, Development |
| `NEXT_PUBLIC_SANITY_DATASET` | Production, Preview, Development |
| `NEXT_PUBLIC_SANITY_API_VERSION` | Production, Preview, Development |
| `SANITY_API_TOKEN` | Production, Preview |
| `SANITY_WEBHOOK_SECRET` | Production, Preview |

3. Deploy!

### Step 4: Configure Sanity Webhook

1. Go to [sanity.io/manage](https://sanity.io/manage) → API → Webhooks
2. URL: `https://your-domain.com/api/revalidate`
3. Secret: Your `SANITY_WEBHOOK_SECRET`
4. Trigger on: Create, Update, Delete
5. Filter: `_type == "blogPost"`

---

## 12. Next Steps

| Feature | How To |
|---------|--------|
| **Add pagination** | GROQ slice: `[0...10]`, `[10...20]` |
| **Add search** | Fuse.js or Algolia |
| **Add comments** | Giscus |
| **RSS feed** | Dynamic route at `/api/rss` |
| **Sitemap** | Dynamic route at `/api/sitemap` |
| **Open Graph images** | `@vercel/og` with cached dynamic generation |

---

## Key Differences from Next.js 14

| Aspect | Next.js 14 | Next.js 16 |
|--------|-----------|------------|
| Caching | Implicit (`export const revalidate`) | Explicit (`'use cache'`) |
| Invalidation | `revalidatePath` | `revalidateTag` / `updateTag` |
| Middleware | `middleware.ts` | `proxy.ts` |
| Request APIs | Synchronous (`params.slug`) | Asynchronous (`await params`) |
| Bundler | webpack (default) | Turbopack (default) |
| Control | Framework decides | Developer decides |

---

## Document Cross-References

| This Tutorial | References |
|---------------|------------|
| Why this stack? | [Architecture: Technology Stack](sandbox:///mnt/agents/output/architecture-nextjs16.md#3-technology-stack) |
| Project structure | [Architecture: Directory Structure](sandbox:///mnt/agents/output/architecture-nextjs16.md#41-directory-structure) |
| Caching strategy | [Architecture: Caching & Revalidation](sandbox:///mnt/agents/output/architecture-nextjs16.md#6-caching--revalidation-nextjs-16) |
| Security (env vars) | [SRD: Security Requirements](sandbox:///mnt/agents/output/srd-nextjs16.md#52-security-requirements), [Architecture: Security](sandbox:///mnt/agents/output/architecture-nextjs16.md#9-security-architecture) |
| Performance targets | [SRD: Performance Requirements](sandbox:///mnt/agents/output/srd-nextjs16.md#51-performance-requirements), [Architecture: Performance](sandbox:///mnt/agents/output/architecture-nextjs16.md#10-performance-architecture) |
| Blog integration | [SRD: Blog Features](sandbox:///mnt/agents/output/srd-nextjs16.md#34-feature-blog-integrated-with-sanity-cms--nextjs-16-caching) |
| Deployment | [Architecture: Deployment](sandbox:///mnt/agents/output/architecture-nextjs16.md#8-deployment-architecture) |
| Proxy | [Architecture: Proxy](sandbox:///mnt/agents/output/architecture-nextjs16.md#7-proxy--request-interception) |

---

*Happy building with Next.js 16! 🚀 Your portfolio now uses explicit, predictable caching that you control.*
