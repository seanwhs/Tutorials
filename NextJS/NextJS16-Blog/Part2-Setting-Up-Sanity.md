## Blog Tutorial - Part 2: Setting Up Sanity (Account, Project, Embedded Studio)

## What is Sanity?
Sanity is a headless CMS: it stores your content (posts, authors, images) in a hosted, free-tier database and gives you a content editing UI ("Studio"). We will **embed the Studio directly inside our Next.js 16 app** at `/studio`, so you don't need a separate project or deployment for content editing.

## Step 1: Create a free Sanity account
1. Go to https://www.sanity.io/get-started
2. Sign up (GitHub login is fastest) — no credit card required
3. The free "Sanity Growth/Free" plan includes plenty of API requests, 3 users, and unlimited content types for personal/small projects — more than enough for this tutorial.

## Step 2: Initialize Sanity inside your existing Next.js project

In your project root:

```bash
npx sanity@latest init --env
```

Follow the prompts:
```
Select project to use: Create new project
Project name: my-blog
Use the default dataset configuration? Yes  (creates a "production" dataset)
Would you like to add configuration files for a Sanity project in this Next.js folder? 
  -> If asked this, choose "No" — we will wire it up manually so we understand every piece.
```

If the CLI insists on scaffolding files automatically, that's fine too — just note the **Project ID** and **dataset name** ("production") it prints out; we'll need them.

> If you don't have the CLI prompt available or prefer full manual control, instead just create a project at https://www.sanity.io/manage → "Create project", name it `my-blog`, and note the **Project ID**. Dataset name: `production`.

## Step 3: Add environment variables

Create a file `.env.local` in your project root:

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id_here
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2024-01-01
SANITY_API_READ_TOKEN=
```

(We'll fill in `SANITY_API_READ_TOKEN` in a later part when we need authenticated reads for draft/private content. For now leave it blank.)

Also add `.env.local` to `.gitignore` if it isn't already there (Next.js adds this by default).

## Step 4: Create the Sanity config files

Create `sanity.config.ts` in the project root:

```ts
import { defineConfig } from "sanity";
import { structureTool } from "sanity/structure";
import { visionTool } from "@sanity/vision";
import { schema } from "./src/sanity/schemaTypes";

export default defineConfig({
  name: "default",
  title: "My Blog",

  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,

  plugins: [structureTool(), visionTool()],

  schema,

  basePath: "/studio",
});
```

Create `sanity.cli.ts` in the project root:

```ts
import { defineCliConfig } from "sanity/cli";

export default defineCliConfig({
  api: {
    projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
    dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  },
});
```

## Step 5: Create the schema folder (empty placeholder for now)

Create `src/sanity/schemaTypes/index.ts`:

```ts
import { type SchemaTypeDefinition } from "sanity";

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [],
};
```

We'll fill this in with real schemas (post, author, category, block content) in Part 3.

## Step 6: Mount the embedded Studio route

Create the file `src/app/studio/[[...tool]]/page.tsx`:

```tsx
"use client";

import { NextStudio } from "next-sanity/studio";
import config from "../../../../sanity.config";

export const dynamic = "force-static";

export default function StudioPage() {
  return <NextStudio config={config} />;
}
```

> The `[[...tool]]` catch-all route lets the Studio handle its own internal routing (e.g. `/studio/desk`, `/studio/vision`). This route has no dynamic `params` we need to read ourselves, so it's unaffected by Next.js 16's async-params change — but note it for later: in Part 7 we'll explicitly exclude `/studio` from Clerk's middleware matcher so Sanity's own auth/session handling isn't interfered with.

## Step 7: Run it

```bash
npm run dev
```

Visit http://localhost:3000/studio — you should see the Sanity Studio login screen embedded in your app. Log in with the same account you used to create the project. You'll see an empty Studio (no content types yet — that's next).

## Checkpoint ✅
- [ ] You have a Sanity project + "production" dataset
- [ ] `.env.local` has your Project ID and dataset name
- [ ] Visiting `/studio` shows the embedded Sanity Studio UI
- [ ] No console errors

Next: **Part 3 — Designing Content: Schemas for Post, Author, Category, Block Content**
