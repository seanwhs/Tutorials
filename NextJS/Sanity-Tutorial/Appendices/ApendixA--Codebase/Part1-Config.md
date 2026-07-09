# Sanity Mastery - Appendix A (1 of 5): Config and Sanity Layer
# Appendix A (1 of 5): Config & Sanity Layer

Consolidates every file created across Parts 0-12, covering project config and the entire `src/sanity/` layer. See **Appendix A (2 of 5)** for schema files, and (3-5 of 5) for the rest.

## Install Commands

```bash
npx create-next-app@latest my-sanity-app
# TypeScript: Yes | ESLint: Yes | Tailwind: Yes | src/: Yes | App Router: Yes | Turbopack: Yes | alias: Yes

cd my-sanity-app
npm install sanity next-sanity @sanity/vision @sanity/image-url @portabletext/react
npm install zod
npx sanity@latest init
```

## .env.local

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id_here
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2025-01-01
NEXT_PUBLIC_SITE_URL=http://localhost:3000

SANITY_API_READ_TOKEN=
SANITY_PREVIEW_SECRET=
SANITY_REVALIDATE_SECRET=
SANITY_WRITE_TOKEN=
```

## next.config.ts

```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "cdn.sanity.io" },
    ],
  },
};

export default nextConfig;
```

## sanity.config.ts

```ts
import { defineConfig } from "sanity";
import { structureTool } from "sanity/structure";
import { visionTool } from "@sanity/vision";
import { schema } from "./src/sanity/schemaTypes";
import { structure } from "./src/sanity/structure";
import { preventDeleteIfPublished } from "./src/sanity/actions/preventDeleteIfPublished";

export default defineConfig({
  name: "default",
  title: "My Sanity App",

  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,

  plugins: [structureTool({ structure }), visionTool()],

  schema,

  basePath: "/studio",

  document: {
    productionUrl: async (prev, { document }) => {
      if (document._type !== "post") return prev;
      const slug = (document.slug as { current?: string } | undefined)?.current;
      if (!slug) return prev;

      const params = new URLSearchParams({
        secret: process.env.SANITY_PREVIEW_SECRET!,
        slug,
        type: "post",
      });
      return `${process.env.NEXT_PUBLIC_SITE_URL}/api/draft?${params.toString()}`;
    },
    actions: (prevActions, context) => {
      if (context.schemaType !== "post") return prevActions;
      return prevActions.map((action) =>
        action.action === "delete" ? preventDeleteIfPublished(action) : action
      );
    },
  },
});
```

## sanity.cli.ts

```ts
import { defineCliConfig } from "sanity/cli";

export default defineCliConfig({
  api: {
    projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
    dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  },
});
```

## sanity-typegen.json

```json
{
  "path": "src/**/*.{ts,tsx}",
  "schema": "schema.json",
  "generates": "src/sanity/types.generated.ts"
}
```

## package.json (relevant scripts)

```json
{
  "scripts": {
    "typegen:schema": "sanity schema extract --path=schema.json",
    "typegen:types": "sanity typegen generate",
    "typegen": "npm run typegen:schema && npm run typegen:types"
  }
}
```

Continue to **Appendix A (2 of 5)** for schema files.
