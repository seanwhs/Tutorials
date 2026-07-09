# Sanity Mastery 

# Sanity Mastery: Headless Content for Next.js 16

All notes in this series use the prefix **"Sanity Mastery - "**. Read in order. Runs on a single running example (a blog: `post`, `author`, `category`, `siteSettings`) built up progressively across every part.

## Stack (standing requirement for entire series)
- **Next.js 16** — App Router, Turbopack default, Node.js 20.9+/22 LTS (Node 18 EOL/unsupported)
- **Sanity** (`sanity`, `next-sanity`, `@sanity/vision`, `@sanity/image-url`, `@portabletext/react`) — free "Growth/Free" tier, embedded Studio at `/studio` (no separate hosting)
- **TypeScript** throughout, **Tailwind CSS** for frontend styling, **Zod** for runtime validation (Part 11)
- **CRITICAL NEXT.JS 16 PATTERN**: `params`, `searchParams`, and `draftMode()`/`cookies()`/`headers()` are all `Promise`-based / async now. Every code sample awaits them: `const { slug } = await params;`, `const { q } = await searchParams;`, `const draft = await draftMode();`

## Main Series

| # | Note Title | Covers |
|---|---|---|
| 0 | Sanity Mastery - Part 0: Architecture Primer | Content Lake vs Studio vs API mental model, terminology glossary, two-client pattern |
| 1 | Sanity Mastery - Part 1: Project Setup (Embedded Studio) | create-next-app, `sanity init`, env vars, sanity.config.ts/sanity.cli.ts, `/studio` embed route |
| 2 | Sanity Mastery - Part 2: Schema Design | `blockContent`, `author`, `category`, `post`, `siteSettings` — documents, objects, references, validation |
| 3 | Sanity Mastery - Part 3: GROQ Query Language | Filters, projections, joins via `->`, ordering, slicing, params, counting, `references()` |
| 4 | Sanity Mastery - Part 4: Data Fetching in Next.js 16 | Typed `createClient`, `sanityFetch` wrapper, `next: {tags}`, async `params`, `generateStaticParams` |
| 5 | Sanity Mastery - Part 5: Rendering Portable Text | `@portabletext/react` custom components for marks/blocks/types, plain-text extraction |
| 6 | Sanity Mastery - Part 6: Images | `@sanity/image-url`, hotspot/crop, `next/image` integration, LQIP blur placeholders |
| 7 | Sanity Mastery - Part 7: Draft Mode & Live Preview | Next.js 16 async `draftMode()`, preview route handlers, Studio "Open Preview" button, preview banner |
| 8 | Sanity Mastery - Part 8: On-Demand Revalidation | Webhooks, signed requests, `revalidateTag`, GROQ-filtered webhook, tunnel testing |
| 9 | Sanity Mastery - Part 9: Auth, Tokens, CORS & Roles | Token roles, CORS origins, project member roles, secure write Server Actions, `/studio` gating |
| 10 | Sanity Mastery - Part 10: Advanced Patterns | Search, pagination, i18n content, custom Structure (singleton), custom Document Actions |
| 11 | Sanity Mastery - Part 11: Type Safety (TypeGen + Zod) | `sanity typegen`, generated types, runtime validation with Zod |
| 12 | Sanity Mastery - Part 12: Deployment | Vercel deploy (embedded Studio), CORS/webhook updates for prod, `sanity deploy` alternative |

## Appendices

| Appendix | Note Title | Covers |
|---|---|---|
| A (1/5) | Sanity Mastery - Appendix A (1 of 5): Config and Sanity Layer | Install commands, `.env.local`, `next.config.ts`, `sanity.config.ts`, `sanity.cli.ts`, typegen config/scripts |
| A (2/5) | Sanity Mastery - Appendix A (2 of 5): Schema Files | Full `blockContent.ts`, `author.ts`, `category.ts`, `post.ts`, `siteSettings.ts`, `schemaTypes/index.ts` |
| A (3/5) | Sanity Mastery - Appendix A (3 of 5): Client, Fetch, Image, Queries, Types | `client.ts`, `writeClient.ts`, `fetch.ts`, `image.ts`, `queries.ts`, `types.ts`, `schemas.zod.ts`, `structure.ts`, custom actions |
| A (4/5) | Sanity Mastery - Appendix A (4 of 5): App Routes and Components | Studio route, blog index/detail/search/pagination pages |
| A (5/5) | Sanity Mastery - Appendix A (5 of 5): API Routes and Components | Draft/revalidate API routes, Server Action, PortableTextRenderer, CoverImage, PreviewBanner, LikeButton, root layout, middleware |
| B | Sanity Mastery - Appendix B: Full Schema Files Reference | Schema type summary table, field-type cheat sheet, validation rules, "add a new document type" checklist |
| C | Sanity Mastery - Appendix C: Env Vars and Config Reference | Full env var table, `NEXT_PUBLIC_` rule of thumb, config file map, CORS/webhook/token checklists |
| D | Sanity Mastery - Appendix D: Troubleshooting and Common Errors | Errors organized by Part (setup, schema, GROQ, fetching/caching, preview, webhooks, images, auth/CORS, typegen) |
| E | Sanity Mastery - Appendix E: GROQ Cheat Sheet | One-page GROQ syntax reference + GROQ-vs-SQL mapping |

## Quick Start Path

1. Read **Part 0** for the mental model.
2. Follow **Parts 1–6** in order to build the working blog (setup → schema → GROQ → fetching → rendering → images).
3. Add **Parts 7–9** for a production-grade editorial workflow (preview, revalidation, security).
4. Explore **Part 10** for anything beyond the basics (search, pagination, i18n, custom Studio).
5. Add **Part 11** once the schema stabilizes, for end-to-end type safety.
6. Ship with **Part 12**.
7. Use the **Appendices** as a standing reference while building your own project — Appendix A (5 notes) is a full copy-pasteable codebase, B/C/D/E are cheat sheets.
