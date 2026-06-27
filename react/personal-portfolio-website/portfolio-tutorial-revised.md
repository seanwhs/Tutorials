# Tutorial: Building Your Personal Portfolio Website (Revised)

*A complete beginner's guide to building a modern, performant portfolio with Next.js, TypeScript, Tailwind CSS, and Sanity CMS — aligned with the project's Software Requirements Document (SRD) and Architecture Document.*

---

## Before You Start

This tutorial is part of a three-document system:
- **This tutorial** — hands-on, step-by-step building instructions
- **[Software Requirements Document (SRD)](sandbox:///mnt/agents/output/srd.md)** — what the system must do (requirements)
- **[Architecture Document](sandbox:///mnt/agents/output/architecture.md)** — how the system is structured technically

> 💡 **Tip:** When you see a 🔗 **Architecture** or 🔗 **SRD** reference, it means that decision is documented formally in those documents. You don't need to read them now, but they're there if you want to understand *why* we make certain choices.

---

## Table of Contents

1. [Introduction & Goals](#1-introduction--goals)
2. [Prerequisites & Setup](#2-prerequisites--setup)
3. [Project Structure](#3-project-structure)
4. [Building the Foundation](#4-building-the-foundation)
5. [Creating Pages](#5-creating-pages)
6. [Styling with Tailwind CSS](#6-styling-with-tailwind-css)
7. [Connecting to Sanity CMS](#7-connecting-to-sanity-cms)
8. [Adding the Blog](#8-adding-the-blog)
9. [Contact Form](#9-contact-form)
10. [Performance & Accessibility](#10-performance--accessibility)
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
- Lightning-fast performance
- SEO-friendly structure

### Why This Stack?

| Technology | Why We Use It | 🔗 Architecture |
|------------|---------------|----------------|
| **Next.js 14+ (App Router)** | Server Components, automatic code splitting, ISR | [Rendering Strategy](sandbox:///mnt/agents/output/architecture.md#43-rendering-strategy-by-route) |
| **TypeScript** | Catch errors before they happen, better IDE support | [Technology Stack](sandbox:///mnt/agents/output/architecture.md#31-frontend) |
| **Tailwind CSS** | Rapid styling without leaving your HTML | [Technology Stack](sandbox:///mnt/agents/output/architecture.md#31-frontend) |
| **Sanity CMS** | Headless CMS for blog content — you write, it serves | [Content Layer](sandbox:///mnt/agents/output/architecture.md#23-backend--cms) |
| **Vercel** | Zero-config deployment, global edge network, ISR | [Deployment](sandbox:///mnt/agents/output/architecture.md#6-deployment-architecture) |

---

## 2. Prerequisites & Setup

### What You Need

- **Node.js** 18+ installed ([Download](https://nodejs.org/))
- **npm** (comes with Node.js)
- A **GitHub** account
- A **Vercel** account ([Sign up](https://vercel.com/signup))
- Basic knowledge of HTML, CSS, and JavaScript
- A code editor (VS Code recommended)

### Step 1: Create a New Next.js Project

Open your terminal and run:

```bash
npx create-next-app@latest portfolio --typescript --tailwind --eslint --app --src-dir --no-import-alias
```

When prompted, select:
- **TypeScript**: Yes
- **Tailwind CSS**: Yes
- **ESLint**: Yes
- **App Router**: Yes (this is critical!)
- **src/ directory**: Yes
- **Customize import alias**: No

> 🔗 **Architecture**: We use the App Router because it enables React Server Components, which reduce JavaScript sent to the browser. See [Component Architecture](sandbox:///mnt/agents/output/architecture.md#42-component-hierarchy).

```bash
cd portfolio
npm run dev
```

Open `http://localhost:3000` in your browser. You should see the default Next.js page.

### Step 2: Initialize Git

```bash
git init
git add .
git commit -m "Initial commit: Next.js + TypeScript + Tailwind"
```

---

## 3. Project Structure

Let's organize our code according to the [Architecture Document](sandbox:///mnt/agents/output/architecture.md#41-directory-structure):

```
portfolio/
├── app/                    # Next.js App Router (pages live here)
│   ├── page.tsx            # Home page (route: /)
│   ├── layout.tsx          # Root layout (wraps all pages)
│   ├── globals.css         # Global styles
│   ├── about/
│   │   └── page.tsx        # About page (route: /about)
│   ├── projects/
│   │   └── page.tsx        # Projects page (route: /projects)
│   ├── blog/
│   │   ├── page.tsx        # Blog listing (route: /blog)
│   │   └── [slug]/
│   │       └── page.tsx    # Individual blog post (route: /blog/hello-world)
│   ├── contact/
│   │   └── page.tsx        # Contact page (route: /contact)
│   └── api/
│       └── revalidate/
│           └── route.ts    # Webhook for instant updates
│
├── components/             # Reusable React components
│   ├── ui/                 # Primitive UI (Button, Card, Badge)
│   ├── layout/             # Navbar, Footer, Container
│   └── sections/           # Page sections (Hero, ProjectsGrid, etc.)
│
├── lib/                    # Utility code
│   ├── sanity.ts           # Sanity client configuration
│   ├── sanity-image.ts     # Image URL builder
│   ├── groq-queries.ts     # GROQ queries
│   └── utils.ts            # Helper functions
│
├── types/                  # TypeScript type definitions
│   └── index.ts
│
├── public/                 # Static assets (images, resume.pdf)
│   └── images/
│
├── next.config.js          # Next.js configuration
├── tailwind.config.ts      # Tailwind configuration
└── tsconfig.json           # TypeScript configuration
```

Create these directories now:

```bash
mkdir -p components/ui components/layout components/sections
mkdir -p lib types public/images
mkdir -p app/about app/projects app/blog app/blog/\[slug\] app/contact app/api/revalidate
```

> 🔗 **Architecture**: This structure separates concerns: `app/` for routing, `components/` for UI, `lib/` for utilities, and `types/` for shared TypeScript definitions. See [Directory Structure](sandbox:///mnt/agents/output/architecture.md#41-directory-structure).

---

## 4. Building the Foundation

### Step 1: Configure Tailwind

Your `tailwind.config.ts` should already exist. Update it to include your custom colors and fonts:

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
  plugins: [],
};

export default config;
```

### Step 2: Set Up the Root Layout

The root layout wraps every page. It sets up fonts, metadata, and global structure.

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

> 🔗 **Architecture**: Using `next/font` optimizes font loading — it self-hosts the font, subsets it, and prevents layout shift. See [Performance Architecture](sandbox:///mnt/agents/output/architecture.md#82-optimization-strategies).

### Step 3: Global Styles

```css
/* app/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html {
    scroll-behavior: smooth;
  }

  body {
    @apply text-gray-900 bg-white;
  }

  h1, h2, h3, h4, h5, h6 {
    @apply font-bold tracking-tight;
  }
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

Install the dependencies:

```bash
npm install clsx tailwind-merge
```

---

## 5. Creating Pages

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

        {/* Desktop Navigation */}
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

        {/* Mobile Menu Button */}
        <button
          className="md:hidden p-2"
          onClick={() => setIsOpen(!isOpen)}
          aria-label="Toggle menu"
        >
          {isOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>

      {/* Mobile Navigation */}
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

Install Lucide icons:

```bash
npm install lucide-react
```

> 🔗 **SRD**: The navigation must be persistent across all pages and include links to Home, About, Projects, Blog, and Contact. See [FR-31, FR-32](sandbox:///mnt/agents/output/srd.md#35-feature-navigation--layout).

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
            View My Work
            <ArrowRight size={18} />
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
              <span
                key={skill}
                className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm font-medium"
              >
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
          <article
            key={project.title}
            className="group border rounded-xl overflow-hidden hover:shadow-lg transition-shadow"
          >
            <div className="relative h-48 bg-gray-100">
              <Image
                src={project.image}
                alt={project.title}
                fill
                className="object-cover"
              />
            </div>

            <div className="p-6">
              <h2 className="text-xl font-bold mb-2 group-hover:text-primary-600 transition-colors">
                {project.title}
              </h2>

              <p className="text-gray-600 mb-4">{project.description}</p>

              <div className="flex flex-wrap gap-2 mb-4">
                {project.tags.map((tag) => (
                  <span
                    key={tag}
                    className="px-3 py-1 bg-primary-50 text-primary-700 rounded-full text-xs font-medium"
                  >
                    {tag}
                  </span>
                ))}
              </div>

              <div className="flex gap-4">
                <Link
                  href={project.liveUrl}
                  className="inline-flex items-center gap-1 text-sm font-medium text-primary-600 hover:underline"
                >
                  <ExternalLink size={14} />
                  Live Demo
                </Link>
                <Link
                  href={project.repoUrl}
                  className="inline-flex items-center gap-1 text-sm font-medium text-gray-600 hover:text-gray-900"
                >
                  <Github size={14} />
                  Source
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

> 🔗 **SRD**: Projects must display title, description, thumbnail, tech stack tags, and links to live/demo URLs. See [FR-11 through FR-14](sandbox:///mnt/agents/output/srd.md#33-feature-projects-showcase).

---

## 6. Styling with Tailwind CSS

Tailwind CSS is a utility-first framework. Instead of writing CSS classes like `.hero-title`, you use utility classes directly in your JSX:

```html
<!-- Traditional CSS -->
<h1 className="hero-title">Hello</h1>

<!-- Tailwind CSS -->
<h1 className="text-4xl font-bold text-gray-900 mb-6">Hello</h1>
```

### Key Tailwind Concepts

| Concept | Example | Description |
|---------|---------|-------------|
| **Responsive prefixes** | `md:text-6xl` | Larger text on medium screens and up |
| **Hover states** | `hover:bg-primary-700` | Changes color on mouse hover |
| **Flexbox** | `flex items-center justify-between` | Center items horizontally and vertically |
| **Spacing** | `px-6 py-3` | Padding: 6 units horizontal, 3 units vertical |
| **Colors** | `text-primary-600` | Use your custom primary color |

### Custom Container

We defined `.container-custom` in our global CSS. It provides consistent horizontal padding and centers content:

```tsx
<div className="container-custom">
  {/* Content is centered with max-width and responsive padding */}
</div>
```

---

## 7. Connecting to Sanity CMS

> 📚 **Prerequisite**: This section assumes you've completed the [Sanity CMS Setup Tutorial](sandbox:///mnt/agents/output/sanity-tutorial.md). If not, set up your Sanity project first.

### Step 1: Install Sanity Client

```bash
npm install @sanity/client @sanity/image-url @portabletext/react
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

> 🔗 **Architecture**: The Sanity client is configured with `useCdn: true` for production to leverage Sanity's CDN for faster reads. See [Data Architecture](sandbox:///mnt/agents/output/architecture.md#54-caching-strategy).

> 🔗 **SRD**: API tokens must never be exposed client-side. Only `NEXT_PUBLIC_` variables are embedded in the browser bundle. See [Security Requirements](sandbox:///mnt/agents/output/srd.md#52-security-requirements).

### Step 3: Create Environment Variables

Create a `.env.local` file in your project root:

```bash
# .env.local
NEXT_PUBLIC_SANITY_PROJECT_ID=your-project-id
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-06-28
SANITY_API_TOKEN=your-sanity-read-token
```

> ⚠️ **Important**: Never commit `.env.local` to Git! It's already in `.gitignore` by default.

> 🔗 **Architecture**: See the [Environment Variable Security](sandbox:///mnt/agents/output/architecture.md#73-environment-variable-security) table for what should and shouldn't be public.

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

Install the groq helper:

```bash
npm install next-sanity
```

---

## 8. Adding the Blog

### Step 1: Create the Blog Listing Page

```tsx
// app/blog/page.tsx
import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import client, { urlFor } from "@/lib/sanity";
import { allPostsQuery } from "@/lib/groq-queries";
import { formatDate } from "@/lib/utils";

export const metadata: Metadata = {
  title: "Blog | Your Name",
  description: "Thoughts on web development, design, and technology.",
};

// Revalidate this page every 60 seconds
export const revalidate = 60;

async function getPosts() {
  return client.fetch(allPostsQuery);
}

export default async function BlogPage() {
  const posts = await getPosts();

  return (
    <div className="container-custom py-16">
      <h1 className="text-4xl font-bold mb-4">Blog</h1>
      <p className="text-gray-600 mb-12 text-lg">
        Thoughts on web development, design, and technology.
      </p>

      <div className="grid md:grid-cols-2 gap-8">
        {posts.map((post: any) => (
          <article
            key={post._id}
            className="group border rounded-xl overflow-hidden hover:shadow-lg transition-shadow"
          >
            {post.coverImage && (
              <div className="relative h-56">
                <Image
                  src={urlFor(post.coverImage).width(800).height(400).url()}
                  alt={post.title}
                  fill
                  className="object-cover"
                />
              </div>
            )}

            <div className="p-6">
              <div className="text-sm text-gray-500 mb-2">
                {formatDate(post.publishedAt)}
              </div>

              <h2 className="text-xl font-bold mb-2 group-hover:text-primary-600 transition-colors">
                <Link href={`/blog/${post.slug}`}>
                  {post.title}
                </Link>
              </h2>

              {post.excerpt && (
                <p className="text-gray-600 mb-4">{post.excerpt}</p>
              )}

              {post.tags && (
                <div className="flex flex-wrap gap-2">
                  {post.tags.map((tag: string) => (
                    <span
                      key={tag}
                      className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-xs font-medium"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              )}
            </div>
          </article>
        ))}
      </div>
    </div>
  );
}
```

> 🔗 **Architecture**: `export const revalidate = 60` enables ISR — the page is statically generated at build time, but Vercel revalidates it in the background every 60 seconds. See [ISR](sandbox:///mnt/agents/output/architecture.md#43-rendering-strategy-by-route).

> 🔗 **SRD**: Blog listing must show all published posts ordered by date, with title, excerpt, cover image, and tags. See [FR-16, FR-17](sandbox:///mnt/agents/output/srd.md#34-feature-blog-integrated-with-sanity-cms).

### Step 2: Create Individual Blog Post Pages

```tsx
// app/blog/[slug]/page.tsx
import { Metadata } from "next";
import Image from "next/image";
import { PortableText } from "@portabletext/react";
import client, { urlFor } from "@/lib/sanity";
import { postBySlugQuery, allPostsQuery } from "@/lib/groq-queries";
import { formatDate } from "@/lib/utils";

// Revalidate every 60 seconds
export const revalidate = 60;

// Generate static pages for all posts at build time
export async function generateStaticParams() {
  const posts = await client.fetch(allPostsQuery);
  return posts.map((post: any) => ({
    slug: post.slug,
  }));
}

async function getPost(slug: string) {
  return client.fetch(postBySlugQuery, { slug });
}

export async function generateMetadata({ params }: { params: { slug: string } }): Promise<Metadata> {
  const post = await getPost(params.slug);
  return {
    title: `${post.title} | Your Name`,
    description: post.excerpt,
  };
}

export default async function BlogPostPage({ params }: { params: { slug: string } }) {
  const post = await getPost(params.slug);

  if (!post) {
    return (
      <div className="container-custom py-16">
        <h1 className="text-2xl font-bold">Post not found</h1>
      </div>
    );
  }

  return (
    <article className="container-custom py-16 max-w-3xl">
      <header className="mb-8">
        <div className="text-sm text-gray-500 mb-2">
          {formatDate(post.publishedAt)}
        </div>

        <h1 className="text-4xl font-bold mb-4">{post.title}</h1>

        {post.excerpt && (
          <p className="text-xl text-gray-600 italic">{post.excerpt}</p>
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

      <div className="prose prose-lg max-w-none">
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
            },
          }}
        />
      </div>
    </article>
  );
}
```

> 🔗 **Architecture**: `generateStaticParams` creates static pages for all blog posts at build time. When a new post is published, ISR adds it to the cache on first visit. See [Static Generation](sandbox:///mnt/agents/output/architecture.md#43-rendering-strategy-by-route).

> 🔗 **SRD**: Individual posts must render full Portable Text content including images, code blocks, and rich text. See [FR-19, FR-20](sandbox:///mnt/agents/output/srd.md#34-feature-blog-integrated-with-sanity-cms).

---

## 9. Contact Form

### Step 1: Create the Contact Page

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
          <p>LinkedIn: <a href="https://linkedin.com/in/yourusername" className="text-primary-600 hover:underline">yourusername</a></p>
        </div>
      </div>
    </div>
  );
}
```

### Step 2: Create the Contact Form Component

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

    // Replace with your email service API endpoint
    // Example: Resend, SendGrid, Formspree, or a custom API route
    try {
      const response = await fetch("/api/contact", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });

      if (response.ok) {
        setIsSubmitted(true);
      }
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
        <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">
          Name
        </label>
        <input
          type="text"
          id="name"
          name="name"
          required
          className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition-all"
          placeholder="Your name"
        />
      </div>

      <div>
        <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
          Email
        </label>
        <input
          type="email"
          id="email"
          name="email"
          required
          className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition-all"
          placeholder="you@example.com"
        />
      </div>

      <div>
        <label htmlFor="subject" className="block text-sm font-medium text-gray-700 mb-1">
          Subject
        </label>
        <input
          type="text"
          id="subject"
          name="subject"
          required
          className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition-all"
          placeholder="What's this about?"
        />
      </div>

      <div>
        <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-1">
          Message
        </label>
        <textarea
          id="message"
          name="message"
          required
          rows={5}
          className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition-all resize-none"
          placeholder="Your message..."
        />
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full inline-flex items-center justify-center gap-2 px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {isSubmitting ? "Sending..." : "Send Message"}
        <Send size={18} />
      </button>
    </form>
  );
}
```

> 🔗 **SRD**: Contact form must have Name, Email, Subject, and Message fields with validation. See [FR-26 through FR-30](sandbox:///mnt/agents/output/srd.md#35-feature-contact).

---

## 10. Performance & Accessibility

### Performance Checklist

Before deploying, ensure you've implemented these optimizations:

| Optimization | How | 🔗 Architecture |
|--------------|-----|----------------|
| Image optimization | Use `next/image` with proper `width`/`height` | [Image Pipeline](sandbox:///mnt/agents/output/architecture.md#83-image-pipeline) |
| Font optimization | Use `next/font` | [Font Optimization](sandbox:///mnt/agents/output/architecture.md#82-optimization-strategies) |
| Code splitting | Automatic with Next.js App Router | [Code Splitting](sandbox:///mnt/agents/output/architecture.md#82-optimization-strategies) |
| Static generation | Use Server Components where possible | [SSG](sandbox:///mnt/agents/output/architecture.md#82-optimization-strategies) |
| Lazy loading | Images load as user scrolls | `next/image` default behavior |

### Accessibility Checklist

| Requirement | Implementation | 🔗 SRD |
|-------------|------------------|--------|
| Semantic HTML | Use `<nav>`, `<main>`, `<article>`, `<footer>` | [UI-01](sandbox:///mnt/agents/output/srd.md#41-user-interfaces) |
| Alt text for images | Always include meaningful `alt` attributes | [UI-01](sandbox:///mnt/agents/output/srd.md#41-user-interfaces) |
| Keyboard navigation | All interactive elements are focusable | [UI-03](sandbox:///mnt/agents/output/srd.md#41-user-interfaces) |
| Color contrast | Use Tailwind's default palette (WCAG AA compliant) | [UI-04](sandbox:///mnt/agents/output/srd.md#41-user-interfaces) |
| ARIA labels | Add `aria-label` to icon buttons | Navbar mobile menu |

### Test with Lighthouse

Run a Lighthouse audit in Chrome DevTools:

1. Open DevTools (F12)
2. Go to the **Lighthouse** tab
3. Select **Performance**, **Accessibility**, **Best Practices**, **SEO**
4. Click **Analyze page load**

> 🔗 **SRD**: Target Lighthouse Performance score ≥ 90. See [NFR-01](sandbox:///mnt/agents/output/srd.md#51-performance-requirements).

---

## 11. Deploying to Vercel

### Step 1: Push to GitHub

```bash
git add .
git commit -m "Add portfolio pages, blog, and contact form"
git branch -M main
git remote add origin https://github.com/yourusername/portfolio.git
git push -u origin main
```

### Step 2: Connect to Vercel

1. Go to [vercel.com](https://vercel.com) and sign in
2. Click **"Add New Project"**
3. Import your GitHub repository
4. Vercel will auto-detect Next.js — keep the default settings

### Step 3: Add Environment Variables

In the Vercel dashboard:

1. Go to your project → **Settings** → **Environment Variables**
2. Add all variables from your `.env.local`:

| Name | Value | Environment |
|------|-------|-------------|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | your-project-id | Production, Preview, Development |
| `NEXT_PUBLIC_SANITY_DATASET` | production | Production, Preview, Development |
| `NEXT_PUBLIC_SANITY_API_VERSION` | 2026-06-28 | Production, Preview, Development |
| `SANITY_API_TOKEN` | your-read-token | Production, Preview |

3. Click **Deploy**

> 🔗 **Architecture**: Environment variables prefixed with `NEXT_PUBLIC_` are embedded at build time. Server-only variables (like tokens) are kept secure. See [Environment Configuration](sandbox:///mnt/agents/output/architecture.md#62-environment-configuration).

### Step 4: Set Up Custom Domain (Optional)

1. In Vercel dashboard, go to **Settings** → **Domains**
2. Add your domain (e.g., `yourname.dev`)
3. Follow Vercel's DNS instructions

### Step 5: Set Up ISR Webhook (Optional but Recommended)

For instant blog updates when you publish in Sanity, create a revalidation API route:

```tsx
// app/api/revalidate/route.ts
import { revalidatePath } from "next/cache";
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  const secret = request.headers.get("x-sanity-webhook-secret");

  if (secret !== process.env.SANITY_WEBHOOK_SECRET) {
    return NextResponse.json({ message: "Invalid secret" }, { status: 401 });
  }

  const body = await request.json();
  const { _type, slug } = body;

  if (_type === "blogPost") {
    revalidatePath("/blog");
    if (slug?.current) {
      revalidatePath(`/blog/${slug.current}`);
    }
    return NextResponse.json({ revalidated: true });
  }

  return NextResponse.json({ message: "Unknown type" }, { status: 400 });
}
```

Then configure the webhook in Sanity:

1. Go to [sanity.io/manage](https://sanity.io/manage)
2. Select your project → **API** → **Webhooks**
3. Add webhook: `https://your-domain.com/api/revalidate`
4. Set secret to match `SANITY_WEBHOOK_SECRET`
5. Trigger on: Create, Update, Delete

> 🔗 **Architecture**: Webhooks enable instant cache invalidation without waiting for the ISR interval. See [Integration Layer](sandbox:///mnt/agents/output/architecture.md#24-communications-interfaces).

---

## 12. Next Steps

Congratulations! You've built a modern, performant portfolio website. Here's what you can explore next:

| Next Step | Resource |
|-----------|----------|
| **Write blog posts** | [Blog Posts with Sanity Tutorial](sandbox:///mnt/agents/output/blog-tutorial.md) |
| **Add search** | Fuse.js or Algolia client-side search |
| **Add comments** | Giscus (GitHub Discussions) or Disqus |
| **Add analytics** | Vercel Analytics or Plausible |
| **Add RSS feed** | Dynamic API route generating XML |
| **Add Open Graph images** | `@vercel/og` for dynamic social cards |
| **Multi-language support** | Next.js i18n routing |

---

## Document Cross-References

| This Tutorial | References |
|---------------|------------|
| Why this stack? | [Architecture: Technology Stack](sandbox:///mnt/agents/output/architecture.md#3-technology-stack) |
| Project structure | [Architecture: Directory Structure](sandbox:///mnt/agents/output/architecture.md#41-directory-structure) |
| Rendering strategy | [Architecture: Rendering Strategy](sandbox:///mnt/agents/output/architecture.md#43-rendering-strategy-by-route) |
| Security (env vars) | [SRD: Security Requirements](sandbox:///mnt/agents/output/srd.md#52-security-requirements), [Architecture: Security](sandbox:///mnt/agents/output/architecture.md#7-security-architecture) |
| Performance targets | [SRD: Performance Requirements](sandbox:///mnt/agents/output/srd.md#51-performance-requirements), [Architecture: Performance](sandbox:///mnt/agents/output/architecture.md#8-performance-architecture) |
| Blog integration | [SRD: Blog Features](sandbox:///mnt/agents/output/srd.md#34-feature-blog-integrated-with-sanity-cms) |
| Deployment | [Architecture: Deployment](sandbox:///mnt/agents/output/architecture.md#6-deployment-architecture) |
| Sanity setup | [Sanity CMS Tutorial](sandbox:///mnt/agents/output/sanity-tutorial.md) |
| Blog posts tutorial | [Blog Posts with Sanity Tutorial](sandbox:///mnt/agents/output/blog-tutorial.md) |

---

*Happy building! 🚀 Your portfolio is now a solid foundation that can grow with your career.*
