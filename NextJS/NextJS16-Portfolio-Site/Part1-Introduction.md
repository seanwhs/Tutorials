# Part 1: Introduction & Planning

Welcome! This is Part 1 of a multi-part, hands-on tutorial series where you'll build a modern, content-managed personal portfolio website from scratch using:

- **Next.js 16** (App Router) — the React framework for production
- **Tailwind CSS v4** — utility-first CSS for fast, clean styling
- **Sanity.io** — a headless CMS so you can edit your content (projects, blog posts, bio) without touching code
- **Vercel** — free hosting with automatic deployments
- **Web3Forms** — a free, no-backend way to handle contact form submissions

By the end of this series you will have a live, public portfolio site at a URL like `your-name.vercel.app` (or your own custom domain), fully manageable through a CMS dashboard, with a homepage, projects section, blog, about/resume page, and contact form — all for **$0**.

This tutorial is **code-heavy and beginner-friendly**. You don't need prior Next.js or Sanity experience, but you should be comfortable with:
- Basic HTML/CSS
- Basic JavaScript (variables, functions, arrays)
- Using a terminal (copy-pasting commands is fine)

## A Note on Next.js 16

This series specifically targets **Next.js 16**, the current major version. A few things that changed from older tutorials you may have seen:

- **Node.js 20.9+ or 22 LTS is required.** Node 18 is no longer supported.
- **Turbopack is the default bundler** for `next dev` and `next build` — you don't need to opt in.
- **Dynamic route params, `searchParams`, `cookies()`, and `headers()` are all asynchronous** and must be `await`ed. You'll see `await params` throughout this series wherever we build a page like `/projects/[slug]`. This trips up a lot of people following older tutorials, so pay attention whenever you see `async function Page({ params })`.
- **Tailwind CSS v4** configures itself mostly through CSS (`@theme` blocks in `globals.css`) rather than a big `tailwind.config.js` file.

If any of the above is unfamiliar, don't worry — we'll explain it in context when we get there.

## What We're Building

A single site with these pages:

| Route | Purpose |
|---|---|
| `/` | Homepage — hero intro, featured projects, short about blurb |
| `/projects` | Grid of all projects |
| `/projects/[slug]` | Individual project case study page |
| `/blog` | List of blog posts |
| `/blog/[slug]` | Individual blog post (rich text) |
| `/about` | Full bio, skills, work experience/resume |
| `/contact` | Contact form |

All of the *content* (project descriptions, images, blog posts, bio text, skills) will live in **Sanity**, not hard-coded in your React components. This means once it's built, you (or anyone) can update the site's content from a nice web dashboard — no redeploying code required for content changes.

## Why This Stack?

- **Next.js 16**: Industry-standard React framework. Free, open-source, excellent docs, built-in routing/image optimization/SEO tools, and deploys seamlessly to Vercel.
- **Tailwind CSS v4**: Lets us style fast directly in JSX without writing/naming separate CSS files. Free and open-source.
- **Sanity**: A "headless CMS" — meaning it only manages content and gives you an API; you build the front end however you like. Sanity's free tier ("Free plan") includes:
  - Unlimited public datasets on 1 project
  - Generous API request & bandwidth limits, enough for a personal site with real-world traffic
  - A free, open-source Studio (the CMS dashboard) that you can even run embedded inside your own Next.js app
- **Vercel**: Made by the creators of Next.js. Free "Hobby" tier gives you unlimited personal projects, HTTPS, a global CDN, and automatic deployments from GitHub.
- **Web3Forms**: A free API that emails you form submissions without needing your own backend or server — perfect for a static-ish portfolio contact form.

No credit card is required for any of these services at the tier we'll use.

## Architecture Overview

```
┌─────────────────┐        GROQ queries        ┌──────────────────┐
│                  │ ───────────────────────►  │                  │
│  Next.js 16 App  │                            │   Sanity.io      │
│  (Vercel)        │ ◄─────────────────────── │   (Content API)   │
│                  │        JSON content        │                  │
└─────────┬────────┘                            └────────┬─────────┘
          │                                              │
          │  Studio embedded at /studio route            │
          └──────────────────────────────────────────────┘
                     (edit content in-browser)
```

- Your Next.js app fetches content from Sanity at build time / request time using **GROQ** (Sanity's query language).
- The Sanity Studio — the actual CMS editing UI — will be embedded right inside your Next.js app at a route like `/studio`, so you don't need a separate app or hosting for it.
- Everything ships to Vercel as one deployable Next.js project.

## Prerequisites (Install These Before Part 2)

1. **Node.js version 20.9 or later** (22 LTS recommended). Download from https://nodejs.org. Verify with:
   ```bash
   node -v
   npm -v
   ```
   If you see a version starting with 18 or lower, upgrade before continuing — Next.js 16 will refuse to run otherwise.
2. **A code editor** — VS Code is recommended (free): https://code.visualstudio.com
3. **Git** installed: https://git-scm.com
4. **A free GitHub account** — https://github.com (needed for deploying to Vercel)
5. **A free Sanity account** — we'll create this in Part 4, no need to sign up yet
6. **A free Vercel account** — we'll create this in Part 16, no need to sign up yet

That's it — no paid tools anywhere in this series.

## How to Follow This Series

- Each part builds directly on the previous one. Follow them in order.
- Code blocks are meant to be copied exactly. File paths are always given above each code block, like this:

```txt
// File: app/page.tsx
```

- At the end of most parts there's a **"Checkpoint"** section telling you what you should be able to see/do at that point.
- If something breaks, check Appendix D (Troubleshooting Guide), or re-read the relevant step carefully — copy-paste errors and mismatched Node versions are the top causes of issues.

## Series Roadmap

1. ~~Part 1: Introduction & Planning~~ (you are here)
2. Part 2: Environment Setup & Creating the Next.js 16 App
3. Part 3: Tailwind CSS v4 Setup & Base Layout
4. Part 4: Creating a Free Sanity Project & Core Concepts
5. Part 5: Embedding Sanity Studio Inside the Next.js App
6. Part 6: Designing Content Schemas
7. Part 7: Connecting Next.js to Sanity
8. Part 8: Building the Homepage
9. Part 9: Projects Listing & Dynamic Project Pages
10. Part 10: Blog with Portable Text
11. Part 11: About / Resume Page
12. Part 12: Contact Page with Free Form Handling
13. Part 13: Dark Mode, Navigation, Footer & UI Polish
14. Part 14: SEO, Metadata, Sitemap & OG Images
15. Part 15: On-Demand Revalidation with Sanity Webhooks
16. Part 16: Deploying to Vercel for Free
17. Conclusion
- Appendices A–E: full code reference, schema reference, env var reference, troubleshooting, further resources

Let's get started. Head to **Part 2: Environment Setup & Creating the Next.js 16 App**.

---

Ready to move to Part 2, or would you like anything changed here first?
