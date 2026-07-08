# Part 10: Documentation with Fumadocs

Goal: build a `/docs` site with Fumadocs explaining how to authenticate and call the API.

Fumadocs' exact setup APIs can shift between releases — if something below doesn't match your installed version exactly, check the current Fumadocs docs, but keep the MDX content and page structure from this part.

---

## 1. Source config

Create `source.config.ts` in the project root:

```ts
import { defineDocs, defineConfig } from "fumadocs-mdx/config";

export const docs = defineDocs({
  dir: "content/docs",
});

export default defineConfig({
  mdxOptions: {},
});
```

---

## 2. Docs source loader

Create `src/lib/source.ts`:

```ts
import { loader } from "fumadocs-core/source";
import { docs } from "@/.source";

export const source = loader({
  baseUrl: "/docs",
  source: docs.toFumadocsSource(),
});
```

---

## 3. Update Next config

Replace `next.config.ts`:

```ts
import { createMDX } from "fumadocs-mdx/next";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {};

const withMDX = createMDX();

export default withMDX(nextConfig);
```

Restart the dev server after this change.

---

## 4. Docs layout

Create `src/app/docs/layout.tsx`:

```tsx
import type { ReactNode } from "react";
import { DocsLayout } from "fumadocs-ui/layouts/docs";
import { RootProvider } from "fumadocs-ui/provider";
import { source } from "@/lib/source";
import "fumadocs-ui/style.css";

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <RootProvider>
      <DocsLayout tree={source.pageTree} nav={{ title: "HDB Resale API" }}>
        {children}
      </DocsLayout>
    </RootProvider>
  );
}
```

---

## 5. Docs page route

Create `src/app/docs/[[...slug]]/page.tsx`:

```tsx
import { notFound } from "next/navigation";
import { DocsPage, DocsBody, DocsTitle, DocsDescription } from "fumadocs-ui/page";
import { source } from "@/lib/source";

export default async function Page({ params }: { params: Promise<{ slug?: string[] }> }) {
  const { slug } = await params;
  const page = source.getPage(slug);
  if (!page) notFound();

  const MDX = page.data.body;

  return (
    <DocsPage toc={page.data.toc} full={page.data.full}>
      <DocsTitle>{page.data.title}</DocsTitle>
      <DocsDescription>{page.data.description}</DocsDescription>
      <DocsBody>
        <MDX />
      </DocsBody>
    </DocsPage>
  );
}

export function generateStaticParams() {
  return source.generateParams();
}

export async function generateMetadata({ params }: { params: Promise<{ slug?: string[] }> }) {
  const { slug } = await params;
  const page = source.getPage(slug);
  if (!page) return {};

  return {
    title: page.data.title,
    description: page.data.description,
  };
}
```

This uses the Next.js 16 pattern: `params` is a Promise, so we `await params` before reading `slug`.

---

## 6. Docs content

Create `content/docs/index.mdx`:

```mdx
---
title: HDB Resale API
description: Query Singapore HDB resale transaction data with a simple API key.
---

# HDB Resale API

The HDB Resale API provides developer-friendly access to Singapore HDB resale flat
transaction data, sourced from data.gov.sg.

## Base URL

```txt
http://localhost:3000
```

Replace this with your deployed Vercel URL in production.

## Authentication

Send your API key in the `x-api-key` header:

```bash
curl "http://localhost:3000/api/v1/resale-prices?town=ANG%20MO%20KIO&limit=5" \
  -H "x-api-key: hdb_live_your_key_here"
```

## Endpoint

```txt
GET /api/v1/resale-prices
```

## Query parameters

| Name | Type | Description |
| --- | --- | --- |
| `town` | string | Example: `ANG MO KIO` |
| `flat_type` | string | Example: `4 ROOM` |
| `month` | string | Format: `YYYY-MM` |
| `min_price` | number | Minimum resale price |
| `max_price` | number | Maximum resale price |
| `limit` | number | 1 to 100, default 20 |
| `offset` | number | Pagination offset, default 0 |

## Example response

```json
{
  "data": [],
  "meta": {
    "count": 0,
    "total": 0,
    "limit": 20,
    "offset": 0,
    "cached": false
  }
}
```

## Rate limits

Free tutorial keys are limited to 60 requests per minute per key.
```

---

## 7. Generate Fumadocs source if needed

If TypeScript complains that `@/.source` doesn't exist:

```bash
npx fumadocs-mdx
```

Then restart:

```bash
npm run dev
```

Visit `http://localhost:3000/docs`.

---

## Checkpoint

- [ ] `/docs` renders a documentation page with a sidebar layout.
- [ ] The page explains auth, the endpoint, params, and rate limits.
- [ ] The rest of the app still builds and runs after the `next.config.ts` change.

---

## Troubleshooting

**`Cannot find module '@/.source'`**
Run `npx fumadocs-mdx`, then restart the dev server. Check the installed Fumadocs version's docs if this generation step has changed.

**Docs page has no styling**
Confirm `import "fumadocs-ui/style.css";` is present in `src/app/docs/layout.tsx`.

**Fumadocs API doesn't match exactly**
Fumadocs iterates quickly. Keep this part's MDX content and adapt only the layout/loader files to whatever the current Fumadocs starter recommends.

---

Ready for **Part 11 — End-to-End Testing**?
