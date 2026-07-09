# Sanity Mastery - Part 1: Project Setup — Embedding Studio in Next.js 16

## Step 1: Scaffold Next.js 16

```bash
npx create-next-app@latest my-sanity-app
```

```text
✔ TypeScript?              Yes
✔ ESLint?                  Yes
✔ Tailwind CSS?            Yes
✔ src/ directory?          Yes
✔ App Router?              Yes   (required for embedding Studio via a catch-all route)
✔ Turbopack?               Yes   (default & required in Next.js 16)
✔ import alias (@/*)?      Yes
```

```bash
cd my-sanity-app
node -v   # MUST print v20.9.0+ or v22.x — Next.js 16 dropped Node 18 support entirely
```

## Step 2: Install Sanity packages

```bash
npm install sanity next-sanity @sanity/vision @sanity/image-url @portabletext/react
```

| Package | Purpose |
|---|---|
| `sanity` | Core Studio engine, schema type helpers (`defineType`, `defineField`) |
| `next-sanity` | Official glue: typed `createClient`, `<NextStudio>` embed component, `groq` tag |
| `@sanity/vision` | In-Studio GROQ query playground plugin (dev tool for editors/devs) |
| `@sanity/image-url` | Builds responsive, cropped image URLs from Sanity image references |
| `@portabletext/react` | Renders Sanity's structured rich-text ("Portable Text") as React components |

## Step 3: Create the Sanity project (Content Lake)

```bash
npx sanity@latest init
```

```text
? Select project to use          → Create new project
? Your project name              → my-sanity-app
? Use the default dataset config → Yes   (creates a "production" dataset)
? Would you like to add configuration files for a Sanity project in this Next.js folder?
   → No   (we wire everything manually so every file's purpose is explicit)
```

> Note the **Project ID** printed at the end (e.g. `abc123xy`). If you skip the CLI, create the project manually at https://www.sanity.io/manage → "Create project", name it, and note the Project ID. Dataset name: `production`.

## Step 4: Environment variables

```bash
# .env.local (project root — already gitignored by create-next-app)
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id_here
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2025-01-01

# Filled in later parts — leave blank for now:
SANITY_API_READ_TOKEN=
SANITY_REVALIDATE_SECRET=
```

> `NEXT_PUBLIC_*` vars are safe to expose client-side — a project ID/dataset name are addresses, not secrets. The read token (Part 7/9) and revalidate secret (Part 8) are real secrets and stay unprefixed so they never ship to the browser bundle.

## Step 5: Root Sanity config files

```ts
// sanity.config.ts (project root)
import { defineConfig } from "sanity";
import { structureTool } from "sanity/structure";
import { visionTool } from "@sanity/vision";
import { schema } from "./src/sanity/schemaTypes";

export default defineConfig({
  name: "default",
  title: "My Sanity App",

  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,

  // structureTool = the default content tree (left sidebar) in Studio
  // visionTool = an in-browser GROQ playground, handy while learning Part 3
  plugins: [structureTool(), visionTool()],

  schema,

  basePath: "/studio", // Studio will be reachable at yourapp.com/studio
});
```

```ts
// sanity.cli.ts (project root) — used by the `sanity` CLI (deploy, migrations, typegen)
import { defineCliConfig } from "sanity/cli";

export default defineCliConfig({
  api: {
    projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
    dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  },
});
```

## Step 6: Schema folder (empty placeholder — filled in Part 2)

```ts
// src/sanity/schemaTypes/index.ts
import { type SchemaTypeDefinition } from "sanity";

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [], // we'll add post, author, category, blockContent, etc. in Part 2
};
```

## Step 7: Mount the embedded Studio route

```tsx
// src/app/studio/[[...tool]]/page.tsx
"use client"; // Studio is a fully client-rendered React app — it needs the browser

import { NextStudio } from "next-sanity/studio";
import config from "../../../../sanity.config";

// Studio manages its own internal routing/rendering; tell Next.js not to
// try to statically optimize or dynamically render this shell itself.
export const dynamic = "force-static";

export default function StudioPage() {
  return <NextStudio config={config} />;
}
```

> **Why `[[...tool]]`?** This is an *optional* catch-all route. Studio needs to handle its own sub-navigation internally (e.g. `/studio/structure`, `/studio/vision`) without Next.js's router getting involved. Because this route reads no dynamic `params` itself (Studio parses the URL client-side), it is **unaffected** by Next.js 16's async-`params` change — but keep this route excluded from any middleware matchers you add later (Part 9), since Sanity manages its own auth/session state independently of your app's auth.

```tsx
// src/app/studio/layout.tsx — optional, gives the Studio tab its own page title
export const metadata = {
  title: "Studio - My Sanity App",
};

export default function StudioLayout({ children }: { children: React.ReactNode }) {
  return children;
}
```

## Step 8: Run it

```bash
npm run dev
```

Visit **http://localhost:3000/studio** — you should see the Sanity Studio login screen embedded inside your Next.js app. Log in with the same account used to create the project. You'll see an empty Studio (no content types defined yet) — that's Part 2.

## Common Gotchas

| Symptom | Fix |
|---|---|
| Blank white screen at `/studio` | Confirm `"use client"` is at the very top of `page.tsx`, above imports |
| `projectId is required` error | `.env.local` not loaded — restart `npm run dev` after creating/editing it |
| Studio loads but shows "Unauthorized" | You're logged into a different Sanity account than the one that owns the project |
| Turbopack fails to resolve `sanity.config` | Make sure the relative import path matches your actual folder depth (`src/app/studio/[[...tool]]/page.tsx` → 4 levels up to root) |

## Checkpoint ✅
- [ ] `npm install` succeeded with all 5 Sanity-related packages
- [ ] `.env.local` has your real Project ID and dataset name
- [ ] `sanity.config.ts` and `sanity.cli.ts` exist at project root
- [ ] Visiting `/studio` shows the embedded Sanity Studio login UI, no console errors

**Next: Part 2 — Schema Design (documents, objects, Portable Text, references, validation)**
