# Sanity Mastery - Appendix B: Full Schema Files Reference

# Appendix B: Full Schema Files Reference

Quick-reference table of every schema type built across the series (defined in full in Part 2 and Appendix A 2/5), plus the complete `schemaTypes/index.ts` wiring.

## Schema Type Summary Table

| File | Type | Kind | Key Fields |
|---|---|---|---|
| `blockContent.ts` | `blockContent` | object (array) | block styles, marks (`strong`,`em`,`code`,`link`), embedded `image`, custom `codeBlock` |
| `author.ts` | `author` | document | `name`, `slug`, `photo`, `shortBio`, `longBio` (blockContent) |
| `category.ts` | `category` | document | `title`, `slug`, `description` |
| `post.ts` | `post` | document | `title`, `slug`, `author` (ref), `categories` (ref array), `coverImage`, `excerpt`, `publishedAt`, `body` (blockContent), `seo` (object) |
| `siteSettings.ts` | `siteSettings` | document (singleton via structure) | `title`, `tagline`, `socialLinks` (array of objects) |

## Field-Type Cheat Sheet (used across schemas)

| Sanity field type | Example use in this series |
|---|---|
| `string` | `title`, `name` |
| `text` | `excerpt`, `shortBio` (multi-line, no rich formatting) |
| `slug` | `slug` (auto-generates URL-safe id from a source field) |
| `image` | `coverImage`, `photo` (with `hotspot: true`) |
| `reference` | `author` on `post` (single), `categories` (array of references) |
| `array` | `categories`, `socialLinks`, `blockContent` itself |
| `object` | `seo`, `socialLink` (inline, non-document reusable shape) |
| `datetime` | `publishedAt` |
| `url` | `href` in link annotation, `url` in socialLink |
| `boolean` | `blank` (open link in new tab) |

## Validation Rules Used

```ts
Rule.required()                          // author.name, post.title, post.slug, post.author
Rule.min(5).max(120)                     // post.title length bounds
Rule.max(200)                            // excerpt / shortBio length caps
Rule.uri({ scheme: ["http","https","mailto","tel"] })  // link annotation href
```

## Full `schemaTypes/index.ts` (final wiring)

```ts
import { type SchemaTypeDefinition } from "sanity";
import { post } from "./post";
import { author } from "./author";
import { category } from "./category";
import { blockContent } from "./blockContent";
import { siteSettings } from "./siteSettings";

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [post, author, category, blockContent, siteSettings],
};
```

> Full individual schema file contents (`blockContent.ts`, `author.ts`, `category.ts`, `post.ts`, `siteSettings.ts`) are reproduced verbatim in **Appendix A (2 of 5)** — this appendix is a summary/index, not a duplicate copy, to keep the series navigable.

## Extending the Model — Adding a New Document Type Checklist

```text
[ ] Create src/sanity/schemaTypes/<newType>.ts using defineType/defineField
[ ] Import and add it to the `types` array in schemaTypes/index.ts
[ ] Restart `npm run dev` (or hot-reload should pick it up in Studio automatically)
[ ] Add any needed GROQ queries to src/sanity/queries.ts
[ ] Add tags matching the new `_type` to any sanityFetch calls (Part 4)
[ ] Add `_type == "<newType>"` to the Part 8 webhook's GROQ filter if it needs revalidation
[ ] Re-run `npm run typegen` (Part 11) to regenerate types for the new type/queries
```

**Next:** Appendix C — Environment Variables & Config Reference
