# Sanity Mastery - Appendix A (3 of 5): Client, Fetch, Image, Queries, Types

Continues from Appendix A (2 of 5). Covers `src/sanity/client.ts`, `fetch.ts`, `image.ts`, `writeClient.ts`, `queries.ts`, `types.ts`, `schemas.zod.ts`, and `structure.ts` / custom actions.

## src/sanity/client.ts

```ts
import { createClient } from "next-sanity";

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2025-01-01",
  useCdn: true,
});

export const previewClient = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2025-01-01",
  useCdn: false,
  token: process.env.SANITY_API_READ_TOKEN,
  perspective: "previewDrafts",
});
```

## src/sanity/writeClient.ts

```ts
import { createClient } from "next-sanity";

export const writeClient = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2025-01-01",
  useCdn: false,
  token: process.env.SANITY_WRITE_TOKEN,
});
```

## src/sanity/fetch.ts

```ts
import { draftMode } from "next/headers";
import { client, previewClient } from "./client";
import type { QueryParams } from "next-sanity";
import { z } from "zod";

export async function sanityFetch<T>({
  query,
  params = {},
  tags = [],
}: {
  query: string;
  params?: QueryParams;
  tags?: string[];
}): Promise<T> {
  const { isEnabled } = await draftMode(); // Next.js 16: draftMode() is async

  if (isEnabled) {
    return previewClient.fetch<T>(query, params, { cache: "no-store" });
  }

  return client.fetch<T>(query, params, { next: { tags } });
}

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
    console.error("Sanity data validation failed:", result.error.flatten());
    if (process.env.NODE_ENV === "development") {
      throw new Error("Sanity data shape mismatch — check console for details");
    }
  }

  return result.success ? result.data : (data as T);
}
```

## src/sanity/image.ts

```ts
import createImageUrlBuilder from "@sanity/image-url";
import type { Image } from "sanity";
import { client } from "./client";

const builder = createImageUrlBuilder(client);

export function urlFor(source: Image) {
  return builder.image(source);
}

export function urlForBlur(source: Image) {
  return builder.image(source).width(20).height(12).blur(10).quality(20).url();
}
```

## src/sanity/queries.ts

```ts
import { groq } from "next-sanity";

export const allPostsQuery = groq`
  *[_type == "post" && defined(publishedAt) && publishedAt < now()]
    | order(publishedAt desc) {
      _id,
      title,
      "slug": slug.current,
      excerpt,
      coverImage,
      publishedAt,
      "author": author->{ name },
      "categories": categories[]->{ title, "slug": slug.current }
    }
`;

export const postBySlugQuery = groq`
  *[_type == "post" && slug.current == $slug][0]{
    _id,
    title,
    body,
    coverImage,
    publishedAt,
    seo,
    "author": author->{ name, photo, shortBio },
    "categories": categories[]->{ title, "slug": slug.current }
  }
`;

export const allPostSlugsQuery = groq`
  *[_type == "post" && defined(slug.current)][].slug.current
`;

export const searchPostsQuery = groq`
  *[_type == "post" && (title match $term + "*" || excerpt match $term + "*")]
    | order(publishedAt desc) {
      _id, title, "slug": slug.current, excerpt, publishedAt
    }
`;

export const paginatedPostsQuery = groq`
  *[_type == "post" && defined(publishedAt)] | order(publishedAt desc) [$start...$end]{
    _id, title, "slug": slug.current, excerpt, publishedAt
  }
`;

export const postsTotalCountQuery = groq`count(*[_type == "post" && defined(publishedAt)])`;
```

## src/sanity/types.ts (hand-written; see Part 11 for TypeGen alternative)

```ts
export interface SanityImage {
  asset: { _ref: string; _type: "reference" };
  hotspot?: { x: number; y: number; height: number; width: number };
}

export interface PostListItem {
  _id: string;
  title: string;
  slug: string;
  excerpt: string;
  coverImage?: SanityImage;
  publishedAt: string;
  author: { name: string };
  categories: { title: string; slug: string }[];
}

export interface PostDetail extends Omit<PostListItem, "excerpt" | "categories"> {
  body: unknown[];
  seo?: { metaTitle?: string; metaDescription?: string };
  author: { name: string; photo?: SanityImage; shortBio?: string };
  categories: { title: string; slug: string }[];
}
```

## src/sanity/schemas.zod.ts

```ts
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

## src/sanity/structure.ts

```ts
import type { StructureResolver } from "sanity/structure";

export const structure: StructureResolver = (S) =>
  S.list()
    .title("Content")
    .items([
      S.listItem()
        .title("Site Settings")
        .child(S.document().schemaType("siteSettings").documentId("siteSettings")),
      S.divider(),
      S.documentTypeListItem("post").title("Posts"),
      S.documentTypeListItem("author").title("Authors"),
      S.documentTypeListItem("category").title("Categories"),
    ]);
```

## src/sanity/actions/preventDeleteIfPublished.ts

```ts
import type { DocumentActionComponent, DocumentActionProps } from "sanity";

export const preventDeleteIfPublished =
  (originalAction: DocumentActionComponent) =>
  (props: DocumentActionProps) => {
    const original = originalAction(props);
    if (!original || original.type !== "dialog") return original;

    if (props.published) {
      return {
        ...original,
        disabled: true,
        title: "Cannot delete a published post — unpublish it first",
      };
    }
    return original;
  };
```

Continue to **Appendix A (4 of 5)** for app routes (studio, blog, api) and components.
