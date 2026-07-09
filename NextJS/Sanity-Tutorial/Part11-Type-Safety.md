# Sanity Mastery - Part 11: Type Safety — Sanity TypeGen + Zod

Hand-written types (Parts 4-6) drift from reality as schemas evolve. Sanity's official **TypeGen** solves this by generating types directly from your schema *and* your actual GROQ queries.

## Step 1: Configure TypeGen

```ts
// sanity-typegen.json (project root)
{
  "path": "src/**/*.{ts,tsx}",
  "schema": "schema.json",
  "generates": "src/sanity/types.generated.ts"
}
```

## Step 2: Add scripts

```json
// package.json (relevant scripts)
{
  "scripts": {
    "typegen:schema": "sanity schema extract --path=schema.json",
    "typegen:types": "sanity typegen generate",
    "typegen": "npm run typegen:schema && npm run typegen:types"
  }
}
```

```bash
npm run typegen
```

This does two things:
1. `schema extract` — reads your live schema definitions (Part 2) and dumps them to `schema.json`
2. `typegen generate` — scans your codebase for every `` groq`...` `` tagged template literal it can find, and generates matching TypeScript types for **both the schema types and each query's exact return shape**

```ts
// src/sanity/types.generated.ts (excerpt of what gets auto-generated — do not hand-edit)
export type Post = {
  _id: string;
  _type: "post";
  title: string;
  slug: { _type: "slug"; current: string };
  author: { _type: "reference"; _ref: string };
  categories?: Array<{ _type: "reference"; _ref: string; _key: string }>;
  coverImage?: { asset?: { _type: "reference"; _ref: string }; hotspot?: unknown };
  excerpt?: string;
  publishedAt?: string;
  body?: Array<unknown>;
  seo?: { metaTitle?: string; metaDescription?: string };
};

// Generated from the exact shape of allPostsQuery in src/sanity/queries.ts
export type AllPostsQueryResult = Array<{
  _id: string;
  title: string;
  slug: string | null;
  excerpt: string | null;
  coverImage: /* ... */ null;
  publishedAt: string | null;
  author: { name: string | null } | null;
  categories: Array<{ title: string | null; slug: string | null }>;
}>;
```

## Step 3: Use generated types instead of hand-written ones

```ts
// src/sanity/fetch.ts (updated usage pattern — generated types replace src/sanity/types.ts)
import { sanityFetch } from "@/sanity/fetch";
import { allPostsQuery } from "@/sanity/queries";
import type { AllPostsQueryResult } from "@/sanity/types.generated";

const posts = await sanityFetch<AllPostsQueryResult>({
  query: allPostsQuery,
  tags: ["post"],
});
// `posts` is now precisely typed to match the real projection — if you add/remove
// a field in the GROQ query, re-running `npm run typegen` updates the type to match,
// and TypeScript will flag any component code that's now out of sync.
```

> Re-run `npm run typegen` any time you change a schema field or a query's projection. Consider adding it to a pre-commit hook or CI step so generated types never silently go stale.

## Step 4: Runtime Validation with Zod (defense against bad/legacy content)

TypeGen guarantees *compile-time* shape correctness assuming the query ran successfully — it does **not** protect you from a legacy document missing a field that's since become "required" in Studio, or malformed content entered before a validation rule existed. Zod adds a runtime check at the boundary where content enters your app.

```bash
npm install zod
```

```ts
// src/sanity/schemas.zod.ts
import { z } from "zod";

const sanityImageSchema = z.object({
  asset: z.object({ _ref: z.string(), _type: z.literal("reference") }),
  hotspot: z
    .object({ x: z.number(), y: z.number(), height: z.number(), width: z.number() })
    .optional(),
  alt: z.string().optional(),
});

export const postListItemSchema = z.object({
  _id: z.string(),
  title: z.string(),
  slug: z.string(),
  excerpt: z.string().nullable().default(""),
  coverImage: sanityImageSchema.nullable().optional(),
  publishedAt: z.string(),
  author: z.object({ name: z.string() }),
  categories: z.array(z.object({ title: z.string(), slug: z.string() })).default([]),
});

export const postListSchema = z.array(postListItemSchema);
```

```ts
// src/sanity/fetch.ts (validated wrapper, layered on top of the base sanityFetch)
import { z } from "zod";
import { sanityFetch } from "./fetch";

export async function sanityFetchValidated<T>({
  query,
  params,
  tags,
  schema,
}: {
  query: string;
  params?: Record<string, unknown>;
  tags?: string[];
  schema: z.ZodType<T>;
}): Promise<T> {
  const data = await sanityFetch<unknown>({ query, params, tags });
  const result = schema.safeParse(data);

  if (!result.success) {
    // Fail loudly in development, log-and-degrade in production rather than
    // crashing the whole page render on one bad legacy document.
    console.error("Sanity data validation failed:", result.error.flatten());
    if (process.env.NODE_ENV === "development") {
      throw new Error("Sanity data shape mismatch — check console for details");
    }
  }

  return result.success ? result.data : (data as T);
}
```

```tsx
// src/app/blog/page.tsx (using the validated fetch)
import { sanityFetchValidated } from "@/sanity/fetch";
import { allPostsQuery } from "@/sanity/queries";
import { postListSchema } from "@/sanity/schemas.zod";

export default async function BlogIndexPage() {
  const posts = await sanityFetchValidated({
    query: allPostsQuery,
    tags: ["post"],
    schema: postListSchema,
  });
  // posts is both TypeGen-typed AND runtime-verified to match this exact shape
  // ...
}
```

## When to Use Which

| Tool | Catches | When |
|---|---|---|
| **TypeGen** | Shape mismatches between your code and schema/queries | Compile time, during development |
| **Zod** | Actual malformed/missing data from real documents (legacy content, editor mistakes) | Runtime, on every fetch |

Use both together: TypeGen for developer ergonomics and autocomplete, Zod as the safety net for data that TypeScript can never fully guarantee at runtime.

## Checkpoint ✅
- [ ] `sanity-typegen.json` configured, `npm run typegen` produces `types.generated.ts`
- [ ] At least one page migrated from hand-written types to generated ones
- [ ] Zod schemas created for the most critical query result (e.g. post list)
- [ ] `sanityFetchValidated` wrapper in place for at least one high-traffic page

**Next: Part 12 — Deployment**
