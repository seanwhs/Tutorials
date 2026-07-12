## Building a Modern Blog with Next.js 16, Tailwind CSS v4, Clerk & Sanity

# Series Introduction

Welcome! In this tutorial series you will build a complete, production-ready **blog application** from absolute zero, using only free and open-source tools:

- **Next.js 16 (App Router)** — React 19, Turbopack by default, async dynamic APIs
- **Tailwind CSS v4** — CSS-first configuration, utility-first styling
- **Sanity.io** — headless CMS (free tier) for content (posts, authors, categories), with an **embedded Studio** running right inside your Next.js app
- **Clerk** — authentication (free tier) for sign-up/sign-in, member-only content, and a commenting system
- **Vercel** — free hosting/deployment at the end

By the end of this series you will have a real, working, deployed blog with:
- A homepage listing all blog posts (fetched live from Sanity)
- Individual post pages with rich text, images, and code blocks (Portable Text)
- Category and author archive pages
- User sign-up/sign-in via Clerk
- A comments system where only logged-in users can comment
- "Members-only" premium posts that are gated behind login
- SEO metadata, sitemap, robots.txt, and Open Graph images
- Dark mode
- A live production deployment on Vercel, connected to a live Sanity dataset and a live Clerk instance

## Who this is for
Absolute beginners to this specific stack are welcome. Basic familiarity with JavaScript/React helps, but every step includes full code and explanations of *why*, not just *what*.

## IMPORTANT: This series targets Next.js 16 specifically
Next.js 16 changed several fundamentals compared to Next.js 14/15 tutorials you may find elsewhere:

- **Node.js 20.9+ required** (Node 22 LTS recommended). Node 18 is EOL and will not work. Part 1 verifies your version before anything else.
- **Turbopack is the default** dev and build bundler — `next dev` and `next build` use it automatically, no flags needed.
- **Dynamic APIs are async.** `params`, `searchParams`, `headers()`, `cookies()`, and Clerk's `auth()` all now return Promises and must be `await`-ed. Every dynamic route in this series (`/posts/[slug]`, `/categories/[slug]`, `/authors/[slug]`) uses the pattern:
  ```tsx
  { params }: { params: Promise<{ slug: string }> }
  const { slug } = await params;
  ```
- **Tailwind CSS v4 CSS-first config.** No `tailwind.config.ts` file — configuration and the typography plugin are wired up directly inside `globals.css` using `@import "tailwindcss"` and `@plugin`.
- **React 19** — used automatically by Next.js 16; no extra setup needed, but relevant for some peer-dependency version choices.

Treat these as the baseline for every part and appendix below.

## Prerequisites
- Node.js 20.9+ installed (Node 22 LTS recommended) — check with `node -v`
- A code editor (VS Code recommended)
- A free GitHub account (for deployment)
- A free Sanity.io account (sign up at sanity.io — no credit card required)
- A free Clerk.com account (no credit card required)
- A free Vercel account (can sign up with GitHub)

All services used have generous free tiers sufficient for this entire tutorial and small real-world blogs.

## Tech Stack Summary
| Layer | Tool |
|---|---|
| Framework | Next.js 16 (App Router, React 19, Turbopack default) |
| Styling | Tailwind CSS v4 (CSS-first config) + @tailwindcss/typography |
| CMS / Content | Sanity.io (embedded Studio + hosted dataset) |
| Auth | Clerk (async `auth()`) |
| Hosting | Vercel (free/hobby tier) |
| Language | TypeScript |

## Table of Contents (all parts complete ✅ — regenerated for Next.js 16)
1. ✅ **Part 1** — Project Setup: Next.js 16 + TypeScript + Tailwind CSS v4
2. ✅ **Part 2** — Setting Up Sanity: Account, Project, Embedded Studio
3. ✅ **Part 3** — Designing Content: Schemas for Post, Author, Category, Block Content
4. ✅ **Part 4** — Fetching Content: Sanity Client, GROQ, Homepage Post List
5. ✅ **Part 5** — Post Detail Pages: Portable Text, Images, Code Blocks (async params)
6. ✅ **Part 6** — Categories & Author Pages, Static Generation, ISR (async params)
7. ✅ **Part 7** — Authentication: Clerk Setup, Sign In/Up, Header UI (async auth())
8. ✅ **Part 8** — Comments System (Clerk-gated, stored in Sanity)
9. ✅ **Part 9** — Members-Only Premium Posts (gating content with Clerk, async auth())
10. ✅ **Part 10** — SEO: Metadata, Sitemap, Robots.txt, Open Graph Images
11. ✅ **Part 11** — Styling Polish: Tailwind v4 Typography, Dark Mode Toggle
12. ✅ **Part 12** — Deployment: Shipping to Vercel for Free
13. ✅ **Conclusion** — Recap & Where to Go Next
