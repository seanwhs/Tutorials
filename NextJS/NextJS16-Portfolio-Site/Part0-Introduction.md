# Build a Modern Personal Portfolio Site with Next.js 16, Tailwind CSS & Sanity

**Status: COMPLETE.** Full series built for Next.js 16.

A complete, beginner-friendly, code-heavy tutorial series that takes you from an empty folder to a fully deployed, content-managed personal portfolio website — using only free and open-source tools, built on **Next.js 16**.

## Tech Stack
- **Next.js 16 (App Router)** – Turbopack default bundler, Node.js 20.9+/22 LTS required
- **Tailwind CSS v4** – CSS-first `@theme` config, no tailwind.config.js
- **Sanity.io** – headless CMS, free tier, Studio embedded in-app at /studio
- **Vercel** – free Hobby tier hosting
- **Web3Forms** – free contact form backend
- **TypeScript** throughout

## Important Next.js 16 Notes (applies everywhere in this series)
- Dynamic APIs are async: always `await params`, `searchParams`, `cookies()`, `headers()`.
- Minimum Node.js version is 20.9.0 (22 LTS recommended).
- Tailwind v4 config lives in CSS via `@theme`, not tailwind.config.js.
- `next/image` uses `remotePatterns`, not the old `domains` option.

## Series Outline
1. Part 1: Introduction & Planning
2. Part 2: Environment Setup & Creating the Next.js 16 App
3. Part 3: Tailwind CSS v4 Setup & Base Layout
4. Part 4: Creating a Free Sanity Project & Core Concepts
5. Part 5: Embedding Sanity Studio Inside the Next.js App
6. Part 6: Designing Content Schemas
7. Part 7: Connecting Next.js to Sanity
8. Part 8: Building the Homepage
9. Part 9: Projects Listing & Dynamic Project Pages (async params)
10. Part 10: Blog with Portable Text (async params)
11. Part 11: About / Resume Page
12. Part 12: Contact Page with Free Form Handling
13. Part 13: Dark Mode, Navigation, Footer & UI Polish
14. Part 14: SEO, Metadata, Sitemap & OG Images
15. Part 15: On-Demand Revalidation with Sanity Webhooks
16. Part 16: Deploying to Vercel for Free
17. Conclusion

## Appendices (Canonical Set — Use These)
- **Appendix A: Full Codebase Reference** — split across 8 notes, all titled "Portfolio Tutorial - Appendix A: Full Codebase Reference (N of 8)":
  - (1 of 8): Project setup, .env.local, next.config.ts, sanity.config.ts, sanity/client.ts, sanity/image.ts, sanity/fetch.ts, sanity/types.ts, sanity/queries.ts, schemaTypes/index.ts, Studio route files
  - (2 of 8): ThemeProvider, ThemeToggle, Navbar, Footer
  - (3 of 8): Container, ProjectCard, BlogCard, SkillBadge, RichText, ExperienceItem
  - (4 of 8): Hero, FeaturedProjects, AboutSnippet, ContactForm
  - (5 of 8): Root layout, lib/metadata.ts, globals.css, site layout, homepage route
  - (6 of 8): Projects & blog pages (listing + detail)
  - (7 of 8): About page, contact page
  - (8 of 8): Revalidation API route, sitemap.ts, robots.ts, OG image routes, full folder structure
- **Appendix B: Complete Sanity Schema Reference**
- **Appendix C: Environment Variables Reference**
- **Appendix D: Troubleshooting Guide**
- **Appendix E: Further Resources & Next Steps**

> Note: a set of duplicate/redundant Appendix A and Appendix E notes exists, marked "DEPRECATED DUPLICATE" — safe to ignore.
