## Building a Modern Blog with Next.js 16, Tailwind CSS v4, Clerk & Sanity

# Series Introduction

Welcome! In this series, you will build a complete, production-ready **blog application** from the ground up, utilizing a modern, high-performance tech stack built on open-source foundations.

### The Stack

* **Next.js 16 (App Router)** — Powered by React 19 and Turbopack. We prioritize async-first architecture and efficient route grouping.
* **Tailwind CSS v4** — The latest CSS-first paradigm. No bloated config files—just clean, performant, utility-first styling.
* **Sanity.io** — A flexible Headless CMS that we will embed directly into your application for a seamless content management experience.
* **Clerk** — Enterprise-grade authentication that handles session management, gated content, and user identity.
* **Vercel** — The gold standard for hosting, providing instant CI/CD for your project.

### What You Will Build

By the end of this series, you will have a fully deployed application featuring:

* **Dynamic Content:** A homepage and archive pages featuring live data from Sanity.
* **Rich Media:** Portable Text rendering with support for code blocks, images, and nested metadata.
* **Interactive Features:** A Clerk-gated comment system and "Premium" members-only content.
* **Modern Architecture:** A structured codebase using Next.js **Route Groups** to optimize performance (separating the CMS Studio from your main app UI).
* **SEO & Polish:** Automatic Metadata, Open Graph images, sitemaps, dark mode, and optimized deployment.

## Who This Is For

This series is designed for developers who want to master the **Next.js 16 App Router**. While basic React knowledge is helpful, we emphasize the *why*—explaining architectural decisions like async dynamic APIs and provider orchestration to ensure you understand how to build for scale.

## IMPORTANT: The Next.js 16 Baseline

Next.js 16 introduces fundamental changes that deviate from older tutorials. We enforce these standards in every part of this series:

* **Node.js 22 LTS:** Required for compatibility. Node 18 is EOL and will not work.
* **Turbopack Default:** We leverage the high-speed bundler natively—no flags required.
* **Async Dynamic APIs:** `params`, `searchParams`, and Clerk’s `auth()` are now **Promises**. Every dynamic route follows the pattern:

```tsx
{ params }: { params: Promise<{ slug: string }> }
const { slug } = await params;

```

* **Tailwind v4 CSS-First:** Styling is handled via `@import "tailwindcss"` and `@plugin` directly in `globals.css`.
* **Provider Architecture:** We use **Route Groups** (e.g., `(main)`) to ensure heavy providers like `ClerkProvider` do not bloat your CMS Studio or lightweight administrative routes.

## Prerequisites

* **Node.js 22 LTS** (Verify with `node -v`)
* A GitHub account for version control and Vercel deployment.
* Free accounts at [Sanity.io](https://sanity.io) and [Clerk.com](https://clerk.com).
* A modern code editor (VS Code recommended).

## Tech Stack Summary

| Layer | Tool |
| --- | --- |
| **Framework** | Next.js 16 (App Router, React 19, Turbopack) |
| **Styling** | Tailwind CSS v4 (CSS-first) + @tailwindcss/typography |
| **CMS** | Sanity.io (Embedded Studio) |
| **Auth** | Clerk (Async `auth()` API) |
| **Hosting** | Vercel (Hobby Tier) |
| **Language** | TypeScript |

## Table of Contents

1. ✅ **Part 1** — Project Setup: Next.js 16, TypeScript, & Tailwind v4
2. ✅ **Part 2** — Sanity Integration: Project Scaffolding & Embedded Studio
3. ✅ **Part 3** — Content Modeling: Schemas for Posts, Authors, & Categories
4. ✅ **Part 4** — Data Fetching: GROQ queries & Homepage implementation
5. ✅ **Part 5** — Post Detail Pages: Portable Text & async `params`
6. ✅ **Part 6** — Archive Pages: Static Generation & ISR
7. ✅ **Part 7** — Authentication: Clerk Setup & Header Orchestration
8. ✅ **Part 8** — Community: Building a Clerk-gated Comment System
9. ✅ **Part 9** — Premium Content: Content Gating with `auth()`
10. ✅ **Part 10** — SEO Strategy: Metadata, Sitemap, & OG Images
11. ✅ **Part 11** — UI Polish: Typography & Dark Mode Implementation
12. ✅ **Part 12** — Deployment: Shipping to Vercel
13. ✅ **Conclusion** — Beyond the Blog: Next Steps
