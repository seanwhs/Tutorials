# GreyMatter Journal

## Part 0 — Understanding Modern Blog Architecture

> **Series Goal:** Build a production-grade blog using **Next.js 16** and **Sanity** while learning how modern content-driven web applications actually work.

> **Part 0 Goal:** Before writing a single line of code, understand what a modern blog is, why technologies like Next.js and Sanity exist, and how content flows from a writer's keyboard to a reader's browser.

---

# Welcome to GreyMatter Journal

If you've searched for:

> *"How do I build a blog with Next.js and Sanity?"*

you've probably encountered tutorials that begin like this:

```bash
npx create-next-app@latest my-blog
npx sanity@latest init

# copy this file
# paste this code
# run this command
```

Thirty minutes later, you have a working blog.

But if someone asks:

* What exactly did `create-next-app` create?
* What exactly did `npx sanity init` create?
* Where is the database?
* Why doesn't Next.js store blog posts?
* What is a Content Lake?
* Why do we need a Headless CMS?
* What problem do Server Components solve?
* What actually happens when someone visits a page?

Most tutorials simply move on.

This tutorial series takes a different approach.

Before we build **GreyMatter Journal**, we're going to understand the architecture first.

Because once you understand the architecture, the code becomes dramatically easier to learn.

---

# What Are We Actually Building?

When beginners think about a blog, they usually imagine something like this:

```text
A website with articles.
```

But modern blogs are not simply websites.

A modern content-driven application is actually composed of several independent systems:

```text
Content Creation System
           +
Content Storage System
           +
Content API
           +
Rendering Engine
           +
Browser Application
```

For GreyMatter Journal, these systems will be:

```text
Sanity Studio
        +
Sanity Content Lake
        +
GROQ API
        +
Next.js 16
        +
React
        +
Browser
```

---

# The Three Jobs Of Every Blog

At its core, every blog only performs three jobs:

```text
Store content
        ↓
Organize content
        ↓
Display content
```

Consider a simple article:

```text
Article
 ├── Title
 ├── Author
 ├── Date
 ├── Categories
 ├── Cover Image
 └── Body
```

When a reader visits:

```text
https://greymatterjournal.com/articles/why-nextjs-matters
```

the system performs four basic operations:

```text
Find article
        ↓
Retrieve article
        ↓
Render article
        ↓
Display article
```

Everything else is engineering.

---

# How Blogs Traditionally Worked

For nearly two decades, websites were built using what we now call a **monolithic architecture**.

A typical blog looked like this:

```text
Browser
    ↓
Web Server
    ↓
Application Code
    ↓
Database
```

For example:

```text
Browser
    ↓
PHP
    ↓
MySQL
```

Suppose a visitor requests:

```text
https://myblog.com/post/123
```

The server performs these steps:

```text
Receive request
        ↓
Execute application code
        ↓
Query database
        ↓
Generate HTML
        ↓
Return HTML
```

Diagram:

```text
                Browser
                    │
                    ▼
            ┌─────────────┐
            │ Application │
            │   Server    │
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │  Database   │
            └─────────────┘
```

This architecture powered:

* WordPress
* Drupal
* Joomla
* Magento
* Most websites built before 2015

---

# The Problem With Traditional CMS Systems

Traditional CMS platforms attempt to solve many problems simultaneously.

For example, WordPress contains:

```text
WordPress

├── Content Editor
├── Database
├── Themes
├── Frontend Rendering
├── Plugin System
└── Administration Dashboard
```

Everything lives inside one application.

This creates several problems.

---

## Problem 1: Content And Presentation Become Tightly Coupled

Traditional CMS architecture looks like this:

```text
CMS
 ├── Content
 ├── Database
 └── Website
```

Suppose you want to redesign your website.

You risk breaking:

* templates,
* themes,
* plugins,
* content rendering,
* integrations.

Your content becomes tightly coupled to your frontend.

---

## Problem 2: Frontend Innovation Becomes Difficult

Traditional CMS systems were designed before modern frontend frameworks existed.

Their architecture assumes:

```text
CMS
     ↓
HTML
```

But modern frontend engineering wants:

* React
* Next.js
* Vue
* Svelte
* Component systems
* Client-side interactivity
* Server rendering
* Streaming

Traditional CMS platforms struggle to adapt to these new models.

---

## Problem 3: Scaling Becomes Expensive

Imagine one million visitors arrive at your website.

Traditional architectures often perform:

```text
1,000,000 visitors
          ↓
1,000,000 requests
          ↓
1,000,000 database queries
```

This creates performance and scalability challenges.

---

# The Idea That Changed Modern Web Development

Eventually developers asked a simple question:

> Why should the system that stores content also be responsible for displaying it?

Instead of this:

```text
CMS
 ├── Content
 ├── Database
 └── Frontend
```

What if we separated the responsibilities?

```text
CMS
     ↓
   API
     ↓
Frontend
```

This architectural pattern became known as:

# Headless CMS

---

# What Does "Headless" Actually Mean?

Imagine a restaurant.

A traditional restaurant contains:

```text
Kitchen
Dining Room
Cashier
Menu
```

Everything happens in one building.

A headless restaurant would only provide:

```text
Kitchen
```

The kitchen prepares food.

Someone else decides:

* where the food is served,
* how it is presented,
* who delivers it.

A Headless CMS works exactly the same way.

It only performs two jobs:

```text
Store content
        ↓
Expose content through APIs
```

It does not care:

* what frontend framework you use,
* how your website looks,
* where your application runs.

---

# Enter Sanity

Sanity is a Headless CMS.

Sanity does not build websites.

Instead, it specializes in:

```text
Content modeling
        ↓
Content storage
        ↓
Content relationships
        ↓
Content APIs
```

Suppose an editor writes:

```json
{
  "title": "Understanding Server Components",
  "author": "Sean Wong",
  "category": "Architecture",
  "publishedAt": "2026-07-03"
}
```

Sanity stores this information in a system called the:

# Content Lake

---

# What Is A Content Lake?

Traditional databases store rows and columns:

```text
posts

id
title
body
author_id
```

A Content Lake stores structured documents:

```text
Post
 ├── title
 ├── body
 ├── author
 └── category

Author
 ├── name
 └── bio

Category
 └── title
```

Think of a Content Lake as:

```text
Database
       +
Document Store
       +
Relationship Engine
       +
API Layer
```

This makes content much more flexible than traditional relational databases.

---

# So What Does Next.js Do?

If Sanity stores content, then what is Next.js responsible for?

Next.js is our rendering engine.

```text
Sanity
     ↓
Content API
     ↓
Next.js
     ↓
HTML
     ↓
Browser
```

Diagram:

```text
            Writer
               │
               ▼
        ┌─────────────┐
        │   Sanity    │
        └──────┬──────┘
               │
               ▼
        ┌─────────────┐
        │  Next.js    │
        └──────┬──────┘
               │
               ▼
            Browser
```

Next.js decides:

* what content to fetch,
* when to fetch it,
* how to cache it,
* how to render it,
* how to optimize it.

---

# Why Doesn't The Browser Fetch Directly From Sanity?

Many beginners imagine this architecture:

```text
Browser
     ↓
Sanity API
```

Modern applications usually work like this:

```text
Browser
     ↓
Next.js Server
     ↓
Sanity API
```

Why?

Because the server can:

* protect secrets,
* cache content,
* optimize performance,
* generate SEO-friendly HTML,
* reduce browser JavaScript,
* improve user experience.

---

# Why Next.js 16?

Next.js 16 provides several important architectural advantages.

---

## Server Components

Traditional React applications typically work like this:

```text
Browser downloads JavaScript
            ↓
JavaScript executes
            ↓
Data fetched
            ↓
UI rendered
```

Server Components reverse the process:

```text
Server fetches data
            ↓
Server renders UI
            ↓
Browser receives HTML
```

Example:

```tsx
export default async function HomePage() {
  const posts = await getPosts();

  return <PostList posts={posts} />;
}
```

Notice what's missing:

* `useEffect`
* loading spinners
* API routes
* client-side data fetching

Instead:

```text
fetch
   ↓
render
```

---

## Streaming

Traditional applications often behave like this:

```text
wait
wait
wait
wait
show page
```

Next.js can progressively stream content:

```text
show header
show hero
show article
show sidebar
show comments
```

This makes applications feel dramatically faster.

---

## Intelligent Caching

Instead of:

```text
Visit page
      ↓
Query CMS
      ↓
Visit page
      ↓
Query CMS
```

Next.js can perform:

```text
Query once
      ↓
Cache result
      ↓
Reuse result
```

This significantly improves performance and scalability.

---

# The Architecture Of GreyMatter Journal

By the end of this series, our application architecture will look like this:

```text
                    Writers
                       │
                       ▼
              ┌────────────────┐
              │ Sanity Studio  │
              └───────┬────────┘
                      │
                      ▼
              ┌────────────────┐
              │ Content Lake   │
              └───────┬────────┘
                      │
                   GROQ
                      │
                      ▼
              ┌────────────────┐
              │ Next.js 16     │
              │ App Router     │
              │ Server Comp.   │
              └───────┬────────┘
                      │
                  HTML + RSC
                      │
                      ▼
                   Browser
```

---

# What We'll Build

Throughout this series, we'll build:

```text
Homepage
      ↓
Article Listing
      ↓
Article Detail Pages
      ↓
Author Pages
      ↓
Category Pages
      ↓
Search
      ↓
Related Articles
      ↓
SEO
      ↓
Draft Preview
      ↓
Caching
      ↓
Deployment
```

Along the way, you'll learn:

* React
* Next.js 16
* App Router
* Server Components
* TypeScript
* Sanity CMS
* Content Modeling
* GROQ
* SEO
* Caching
* Image Optimization
* Server Actions
* Production Deployment

---

# Mental Model To Remember Forever

A modern blog is **not**:

```text
Website
```

A modern blog is:

```text
Content System
        +
Content API
        +
Rendering Engine
        +
Browser Application
```

For GreyMatter Journal, that becomes:

```text
Sanity
      +
Content Lake
      +
Next.js 16
      +
React
      +
Browser
```

---

# Up Next

In **Part 1**, we'll create our first Next.js 16 application and learn:

* What Node.js actually is
* What npm actually is
* What npx actually is
* What `create-next-app` actually does
* What `npx sanity@latest init` actually creates
* Why Next.js projects are structured the way they are

Because before we can build a modern application, we need to understand the machine we're building it on.
