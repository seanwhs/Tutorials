## Blog Tutorial - Part 2: Setting Up Sanity (Account, Project, Embedded Studio)

### What is Sanity?
Sanity is a **headless CMS** that stores your blog content in a hosted database and provides a beautiful editing interface called **Studio**. We will embed it directly inside your Next.js app at `/studio`.

---

### Step 1: Create a free Sanity account

1. Go to [https://www.sanity.io/get-started](https://www.sanity.io/get-started)
2. Sign up with GitHub (fastest)
3. Free plan is more than enough.

---

### Step 2: Install Sanity packages

```bash
npm install next-sanity sanity @sanity/vision
```

---

### Step 3: Initialize Sanity (Interactive Setup)

Run this command:

```bash
npx sanity@latest init --env .env.local
```

**Answer the prompts as follows:**

- Create a new project or select existing → **GreyMatter Journal** (or create new)
- Dataset → `production`
- Would you like to add configuration files…? → **`Y`**
- Use TypeScript? → **`Y`**
- Would you like an embedded Sanity Studio? → **`Y`**
- What route do you want to use for the Studio? → Press **Enter** (keep `/studio`)

This will automatically create `.env.local`, `sanity.config.ts`, `sanity.cli.ts`, and related files.

---

### Step 4: Verify `.env.local`

Open `.env.local` and make sure it looks similar to this:

```env
# Sanity Configuration
NEXT_PUBLIC_SANITY_PROJECT_ID=xdajrdsx
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-01-01

# Optional: Used later for draft/preview content
SANITY_API_READ_TOKEN=
```

> Your `Project ID` (`xdajrdsx`) should already be filled in correctly by the CLI.

---

### Step 5: Sanity Configuration Files

The `init` command should have created a `sanity/` folder. Check that these files exist and have the correct content:

#### `sanity/sanity.config.ts`
```ts
import { defineConfig } from 'sanity'
import { structureTool } from 'sanity/structure'
import { visionTool } from '@sanity/vision'
import { schema } from './schemaTypes'

export default defineConfig({
  name: 'default',
  title: 'GreyMatter Journal',
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  plugins: [structureTool(), visionTool()],
  schema,
  basePath: '/studio',
})
```

(You may need to update the `title` if it’s not already set to “GreyMatter Journal”.)

The other files (`sanity.cli.ts` and `sanity/schemaTypes/index.ts`) can stay as generated for now.

---

### Step 6: Create the Studio Route (if not auto-created)

Create the file: `src/app/studio/[[...tool]]/page.tsx`

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

### Step 7: Test It

```bash
npm run dev
```

Go to: **http://localhost:3000/studio**

You should see the Sanity Studio. Log in with the same account.

---

**Checkpoint ✅**

- [ ] `.env.local` has correct `NEXT_PUBLIC_SANITY_PROJECT_ID=xdajrdsx`
- [ ] Studio loads at `/studio`
- [ ] No major errors in console

---

**Next:** Part 3 — Designing Content Schemas (Post, Author, Category, Block Content)

---

This version is now tailored to your project. Let me know if the CLI created all the files correctly or if you need adjustments!
