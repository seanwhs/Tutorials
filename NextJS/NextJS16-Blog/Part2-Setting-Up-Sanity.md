## Blog Tutorial - Part 2: Setting Up Sanity (Account, Project, Embedded Studio)

### What is Sanity?
Sanity is a **headless CMS** that stores your blog content (posts, authors, images, categories) in a hosted database. It provides a beautiful editing interface called **Studio**. In this tutorial, we’ll **embed the Studio directly inside our Next.js 16 app** at `/studio`.

---

### Step 1: Create a free Sanity account

1. Go to [https://www.sanity.io/get-started](https://www.sanity.io/get-started)
2. Sign up (GitHub login is fastest)
3. No credit card required. The free plan is more than enough for this project.

---

### Step 2: Install Sanity packages

In your project root, run:

```bash
npm install next-sanity sanity @sanity/vision
```

---

### Step 3: Initialize Sanity in your Next.js project

Run this command:

```bash
npx sanity@latest init --env .env.local
```

**Follow the prompts:**
- **Select project**: `Create new project`
- **Project name**: `my-blog` (or whatever you like)
- **Dataset**: Use default (`production`)
- **TypeScript**: Yes
- **Output path**: Accept default (current folder)

The command will automatically create `.env.local` with your `Project ID` and other values.

---

### Step 4: Create the Sanity folder structure

Create the following folders and files:

```
sanity/
├── sanity.config.ts
├── sanity.cli.ts
└── schemaTypes/
    └── index.ts
```

#### `sanity/sanity.config.ts`
```ts
import { defineConfig } from 'sanity'
import { structureTool } from 'sanity/structure'
import { visionTool } from '@sanity/vision'
import { schema } from './schemaTypes'

export default defineConfig({
  name: 'default',
  title: "Sean's Blog",
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  plugins: [structureTool(), visionTool()],
  schema,
  basePath: '/studio',
})
```

#### `sanity/sanity.cli.ts`
```ts
import { defineCliConfig } from 'sanity/cli'

export default defineCliConfig({
  api: {
    projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
    dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  },
})
```

#### `sanity/schemaTypes/index.ts` (placeholder for now)
```ts
import { type SchemaTypeDefinition } from 'sanity'

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [],
}
```

---

### Step 5: Set up the embedded Studio route

Create the file:  
`src/app/studio/[[...tool]]/page.tsx`

```tsx
'use client'

import { NextStudio } from 'next-sanity/studio'
import config from '../../../sanity/sanity.config'

export const dynamic = 'force-static'

export default function StudioPage() {
  return <NextStudio config={config} />
}
```

---

### Step 6: Update your environment variables

Open `.env.local` and make sure it looks similar to this:

```env
NEXT_PUBLIC_SANITY_PROJECT_ID=your_actual_project_id
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-01-01   # Update to current year
```

> Leave `SANITY_API_READ_TOKEN` empty for now. We'll add it later when we need draft content support.

Make sure `.env.local` is listed in your `.gitignore`.

---

### Step 7: Run and test

Start your dev server:

```bash
npm run dev
```

Go to: **http://localhost:3000/studio**

You should see the Sanity Studio embedded in your app. Log in with the same account you used to create the project.

---

### Checkpoint ✅

- [ ] Sanity packages installed
- [ ] `.env.local` created with your Project ID
- [ ] Studio loads at `/studio`
- [ ] No console errors on `/studio`
- [ ] Folder structure follows modern conventions (`sanity/` folder)

---

**Next:** Part 3 — Designing Content: Schemas for Post, Author, Category, and Block Content

---

This version is cleaner, more reliable, follows current best practices (as of 2026), and avoids the common pitfalls that trip up most people.

Would you like me to also provide a short **Troubleshooting** section at the end?
