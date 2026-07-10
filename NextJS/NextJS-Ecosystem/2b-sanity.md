## Part 2 (continued): Sanity CMS Setup

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
This note continues directly from "Ecosystem Tutorial - Part 2: Identity & Content" (Clerk section). Read that first.

---

### 2.8 Install Sanity

```bash
pnpm create sanity@latest -- --project orbit-cms --dataset production --template clean --typescript --output-path sanity
pnpm add next-sanity@latest sanity@latest @sanity/image-url@latest
```

### 2.9 Sanity env vars

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id
NEXT_PUBLIC_SANITY_DATASET=production
SANITY_API_TOKEN=your_write_token
```

Generate the write token from sanity.io/manage, under API > Tokens, with Editor permissions. Server-only — never prefix with `NEXT_PUBLIC_`.

### 2.10 Define schemas

```ts
// sanity/schemaTypes/servicePackage.ts
import { defineType, defineField } from "sanity";

export const servicePackage = defineType({
  name: "servicePackage",
  title: "Service Package",
  type: "document",
  fields: [
    defineField({ name: "name", type: "string", validation: (r) => r.required() }),
    defineField({ name: "slug", type: "slug", options: { source: "name" } }),
    defineField({ name: "description", type: "text" }),
    defineField({ name: "priceUsd", title: "Price (USD)", type: "number" }),
    defineField({ name: "features", type: "array", of: [{ type: "string" }] }),
  ],
});
```

```ts
// sanity/schemaTypes/article.ts
import { defineType, defineField } from "sanity";

export const article = defineType({
  name: "article",
  title: "Article",
  type: "document",
  fields: [
    defineField({ name: "title", type: "string", validation: (r) => r.required() }),
    defineField({ name: "slug", type: "slug", options: { source: "title" } }),
    defineField({ name: "body", type: "array", of: [{ type: "block" }] }),
    defineField({ name: "publishedAt", type: "datetime" }),
  ],
});
```

```ts
// sanity/schemaTypes/index.ts
import { type SchemaTypeDefinition } from "sanity";
import { servicePackage } from "./servicePackage";
import { article } from "./article";

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [servicePackage, article],
};
```

Reference `schema` from the root `sanity.config.ts` that the CLI scaffolded (its `schema.types` field should import `{ schema } from "./sanity/schemaTypes"` and spread `schema.types`).

### 2.11 The one Sanity client — lib/sanity/client.ts

```ts
// src/lib/sanity/client.ts
import { createClient } from "next-sanity";

const projectId = process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!;
const dataset = process.env.NEXT_PUBLIC_SANITY_DATASET!;
const apiVersion = "2025-01-01";

// Public reads — fast, CDN-cached
export const sanityClient = createClient({
  projectId,
  dataset,
  apiVersion,
  useCdn: true,
});

// Authenticated writes / draft previews — server-only, never import into client components
export const sanityWriteClient = createClient({
  projectId,
  dataset,
  apiVersion,
  useCdn: false,
  token: process.env.SANITY_API_TOKEN,
});
```

### 2.12 Typed GROQ queries — lib/sanity/queries.ts

```ts
// src/lib/sanity/queries.ts
import { sanityClient } from "./client";

export interface ServicePackage {
  _id: string;
  name: string;
  slug: { current: string };
  description: string;
  priceUsd: number;
  features: string[];
}

export interface Article {
  _id: string;
  title: string;
  slug: { current: string };
  body: unknown[];
  publishedAt: string;
}

const SERVICE_PACKAGES_QUERY = `*[_type == "servicePackage"] | order(priceUsd asc)`;
const ARTICLE_BY_SLUG_QUERY = `*[_type == "article" && slug.current == $slug][0]`;

export async function getServicePackages(): Promise<ServicePackage[]> {
  return sanityClient.fetch(SERVICE_PACKAGES_QUERY);
}

export async function getArticleBySlug(slug: string): Promise<Article | null> {
  return sanityClient.fetch(ARTICLE_BY_SLUG_QUERY, { slug });
}
```

### 2.13 Embed the Studio

```tsx
// src/app/studio/[[...tool]]/page.tsx
"use client";

import { NextStudio } from "next-sanity/studio";
import config from "../../../../sanity.config";

export default function StudioPage() {
  return <NextStudio config={config} />;
}
```

Leave `/studio` behind Clerk auth (do not add it to `isPublicRoute` in `proxy.ts`), and additionally gate it inside a layout using `requireRole(["ADMIN", "MEMBER"])` from Part 2's roles helper.

```tsx
// src/app/studio/layout.tsx
import { requireRole } from "@/lib/clerk/roles";

export default async function StudioLayout({ children }: { children: React.ReactNode }) {
  await requireRole(["ADMIN", "MEMBER"]);
  return <>{children}</>;
}
```

### 2.14 First content fetch on the frontend

```tsx
// src/app/page.tsx
import { getServicePackages } from "@/lib/sanity/queries";

export default async function HomePage() {
  const packages = await getServicePackages();

  return (
    <main className="mx-auto max-w-4xl p-8">
      <h1 className="text-3xl font-bold">Orbit Service Packages</h1>
      <div className="mt-6 grid gap-4 sm:grid-cols-2">
        {packages.map((pkg) => (
          <div key={pkg._id} className="rounded-lg border p-4">
            <h2 className="text-xl font-semibold">{pkg.name}</h2>
            <p className="mt-2 text-sm text-gray-600">{pkg.description}</p>
            <p className="mt-2 font-mono">${pkg.priceUsd}</p>
          </div>
        ))}
      </div>
    </main>
  );
}
```

---

### 3. Checkpoint

- Sign up via `/sign-up`, land in the app, session recognized by `proxy.ts`.
- Promote yourself to `ADMIN` via Clerk dashboard metadata editor.
- Open `/studio`, create a `servicePackage` document.
- Refresh `/` and see it rendered.

### 4. Troubleshooting

- `sessionClaims.publicMetadata.role` undefined after setting it → sign out/in; the JWT only refreshes on new session issuance.
- `/studio` 404s → confirm `sanity.config.ts` `basePath` matches the folder name (`studio`) and the catch-all page path is exact.
- GROQ queries return empty arrays → check `NEXT_PUBLIC_SANITY_DATASET` matches the dataset documents were created in (`production` vs `development` mismatch is the most common cause).

---

Next: **"Ecosystem Tutorial - Part 3: The Persistence Layer"**

---

Ready for Part 3 whenever you say next.
