**Here's the updated Part 2 with a much clearer `.env.local` setup section:**

---

## Blog Tutorial - Part 2: Setting Up Sanity (Account, Project, Embedded Studio)

### What is Sanity?
Sanity is a **headless CMS** that stores your blog content in a hosted database and provides a great editing interface (Studio). We’ll embed the Studio directly inside our Next.js 16 app at `/studio`.

---

### Step 1: Create a free Sanity account

1. Go to [https://www.sanity.io/get-started](https://www.sanity.io/get-started)
2. Sign up (GitHub is fastest)
3. Free plan is sufficient for this tutorial.

---

### Step 2: Install required packages

```bash
npm install next-sanity sanity @sanity/vision
```

---

### Step 3: Initialize Sanity

Run this command in your project root:

```bash
npx sanity@latest init --env .env.local
```

Follow the prompts:
- Choose **Create new project**
- Project name: `my-blog` (or your preferred name)
- Use default dataset (`production`)
- Use TypeScript: Yes

This command will automatically create `.env.local` with your Project ID.

---

### Step 4: Verify / Create `.env.local`

After initialization, open (or create) the file **`.env.local`** in your project root and make sure it contains at least these values:

```env
# Sanity Configuration
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id_here
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-01-01

# Optional: Will be used later for draft content
SANITY_API_READ_TOKEN=
```

**How to find your Project ID:**
- Go to [https://sanity.io/manage](https://sanity.io/manage)
- Click on your project → copy the **Project ID**

> **Important**: Never commit `.env.local` to Git. It should already be ignored by default in Next.js projects.

---

### Step 5: Create Sanity configuration files

Create the folder structure:

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

#### `sanity/schemaTypes/index.ts`
```ts
import { type SchemaTypeDefinition } from 'sanity'

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [],
}
```

---

### Step 6: Create the Embedded Studio Route

Create: `src/app/studio/[[...tool]]/page.tsx`

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

### Step 7: Test it

```bash
npm run dev
```

Visit: **http://localhost:3000/studio**

Log in with your Sanity account. You should see the Studio interface.

---

### Checkpoint ✅

- [ ] `.env.local` created and contains your `NEXT_PUBLIC_SANITY_PROJECT_ID`
- [ ] Sanity packages installed
- [ ] Studio loads correctly at `/studio`
- [ ] No major console errors

---

**Next:** Part 3 — Creating Content Schemas (Post, Author, etc.)

---

This version now has a dedicated, explicit section for `.env.local`. Let me know if you want a troubleshooting section added too!
