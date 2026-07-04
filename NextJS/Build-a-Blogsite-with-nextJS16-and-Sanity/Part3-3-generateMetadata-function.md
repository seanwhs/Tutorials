# **✅ Part 3-3 — Understanding `generateMetadata()`**

# GreyMatter Journal

## Part 3-3 — Understanding `generateMetadata()`: Metadata, SEO, and the Invisible Architecture of the Web

> **Goal of this lesson:** Understand what metadata actually is, learn how Next.js generates metadata dynamically, and discover why modern web applications maintain two separate realities: the user interface humans see and the metadata machines consume.

---

# The Part of Your Website Nobody Sees

After building pages, layouts, and routes, many developers eventually discover a strange function:

```tsx
export async function generateMetadata() {
  return {
    title: "My Article",
    description: "My article description",
  };
}
```

At first glance, this seems odd.

Questions immediately arise:

* What exactly is metadata?
* Why isn't it part of the page?
* Why does Next.js generate it separately?
* Why is it asynchronous?
* Why do search engines care about it?
* Why do social media sites care about it?

To understand this, we must first understand a fundamental truth:

> Websites have two audiences.

---

# Every Website Has Two Readers

Most beginners think websites are built for humans.

```text
Human
    ↓
Browser
    ↓
Website
```

This is only partially true.

Modern websites are consumed by many different systems:

```text
Human Visitors

Google

Bing

Social Media Crawlers

AI Systems

Accessibility Tools

Search Indexers

Link Preview Systems

Analytics Systems
```

Therefore, every webpage actually contains two realities:

```text
Human Reality
        +
Machine Reality
```

---

# Human Reality

Humans see:

```text
Title

Navigation

Images

Articles

Buttons

Comments
```

For example:

```text
GreyMatter Journal

Understanding React Server Components

Lorem ipsum...
```

---

# Machine Reality

Machines see:

```html
<title>
Understanding React Server Components
</title>

<meta
  name="description"
  content="Deep dive into React Server Components"
/>

<meta
  property="og:title"
  content="Understanding React Server Components"
/>

<meta
  property="og:image"
  content="/og-image.jpg"
/>
```

Humans never see these tags.

But machines depend on them.

---

# What Is Metadata?

Metadata literally means:

> Data about data.

For example:

```text
Book
    ↓
Title
Author
ISBN
Publisher
Language
```

The actual book is the data.

The information describing the book is metadata.

Similarly:

```text
Article
      ↓
Title
Description
Author
Image
Keywords
Publish Date
```

The article is data.

The information describing the article is metadata.

---

# The Old Way

Traditionally, websites managed metadata manually:

```html
<head>
  <title>
    GreyMatter Journal
  </title>

  <meta
    name="description"
    content="Software engineering blog"
  />
</head>
```

This quickly became difficult:

```text
100 pages

100 titles

100 descriptions

100 social images
```

Manual management doesn't scale.

---

# The Next.js Metadata System

Next.js solves this by turning metadata into structured data.

Instead of writing HTML:

```html
<title>
  GreyMatter Journal
</title>
```

we write:

```tsx
export const metadata = {
  title:
    "GreyMatter Journal",
};
```

Next.js generates:

```html
<title>
  GreyMatter Journal
</title>
```

automatically.

---

# Static Metadata

Our root layout already contains metadata:

```tsx
import type {
  Metadata,
} from "next";

export const metadata:
  Metadata = {
    title:
      "GreyMatter Journal",

    description:
      "Exploring software engineering, systems thinking, and architecture.",
};
```

This metadata applies globally.

Think of it as:

```text
Application Metadata
```

---

# Dynamic Metadata

The real power appears when metadata depends on data.

Consider our article page:

```text
/posts/react-server-components
```

The page title should become:

```text
Understanding React Server Components
```

The description should become:

```text
Deep dive into React Server Components
```

We cannot hardcode this.

Instead, we generate it.

---

# Introducing `generateMetadata()`

Next.js provides:

```tsx
export async function
generateMetadata() {
}
```

Example:

```tsx
import {
  client,
} from "@/lib/sanity";

import {
  POST_QUERY,
} from "@/lib/queries";

export async function
generateMetadata({
  params,
}: {
  params: Promise<{
    slug: string;
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
    return {
      title:
        "Not Found",
    };
  }

  return {
    title:
      post.title,

    description:
      post.excerpt,
  };
}
```

---

# Wait—The Page Gets Fetched Twice?

Many beginners notice:

```text
generateMetadata()
         ↓

fetch post
         ↓

page.tsx
         ↓

fetch post again
```

and ask:

> Isn't this inefficient?

Fortunately:

```text
No.
```

Next.js automatically deduplicates identical requests.

Conceptually:

```text
Request Cache

      ↓

generateMetadata()
      ↓
      fetch

      ↓

page.tsx
      ↓
      fetch

      ↓

Single request
```

This is one of the hidden optimizations of React Server Components.

---

# Dynamic Metadata Flow

For article pages, the execution flow becomes:

```text
User Request
       ↓

Router
       ↓

params
       ↓

generateMetadata()
       ↓

Fetch Content
       ↓

Generate <head>
       ↓

Render Page
       ↓

Send HTML
```

Notice:

```text
Metadata
        and
Page Content
```

are generated together.

---

# Social Media Metadata

Suppose someone shares:

```text
https://greymatter.com/posts/react
```

on LinkedIn.

LinkedIn doesn't render React.

Instead, it downloads metadata:

```html
<meta
  property="og:title"
/>

<meta
  property="og:description"
/>

<meta
  property="og:image"
/>
```

This produces:

```text
┌────────────────────────┐
│ React Server Components│
│ Deep dive into RSC     │
│                        │
│ [preview image]        │
└────────────────────────┘
```

This system is called:

```text
Open Graph Metadata
```

---

# Rich Metadata Example

Our future implementation might look like this:

```tsx
export async function
generateMetadata({
  params,
}: {
  params: Promise<{
    slug: string;
  }>;
}) {
  const { slug } =
    await params;

  const post =
    await client.fetch(
      POST_QUERY,
      { slug }
    );

  return {
    title:
      post.title,

    description:
      post.excerpt,

    openGraph: {
      title:
        post.title,

      description:
        post.excerpt,

      type:
        "article",
    },

    twitter: {
      card:
        "summary_large_image",
    },
  };
}
```

---

# Metadata Is Another UI Tree

Most developers think:

```text
Page
```

is the output.

Professional engineers think:

```text
Visible UI Tree
         +

Invisible Metadata Tree
```

Visually:

```text
Application

       ↓

┌───────────────┐
│ React UI Tree │
└───────────────┘

       +

┌─────────────────┐
│ Metadata Tree   │
└─────────────────┘
```

Both trees are generated simultaneously.

---

# Why Is Metadata Typed?

Notice:

```tsx
import type {
  Metadata,
} from "next";
```

This provides a contract.

Instead of:

```tsx
{
  something:
    "whatever"
}
```

we get:

```tsx
Metadata
```

which guarantees:

```text
title

description

keywords

openGraph

twitter

robots

icons
```

TypeScript ensures we generate valid metadata.

---

# The Real Mental Model

Beginners think:

```text
Metadata
      =
SEO
```

Professional engineers think:

```text
Metadata
      =
Machine Interface
```

Or more deeply:

```text
Application

       =

Human Interface

       +

Machine Interface
```

---

# The Most Important Idea To Remember

Your React components are not the entire application.

Your application actually produces two outputs:

```text
Visible User Experience
            +

Invisible Machine Experience
```

Or:

```text
Page Content
        +

Metadata
```

Modern software engineering is often the discipline of building systems that communicate effectively with both humans and machines.

---

# Up Next — Part 3-4: Understanding `generateStaticParams()`

Next we'll explore:

```tsx
export async function
generateStaticParams()
```

You'll learn:

* Static Site Generation
* Build-time rendering
* Dynamic route pre-generation
* Caching strategies
* Incremental Static Regeneration
* Why modern web frameworks continuously trade time for performance
