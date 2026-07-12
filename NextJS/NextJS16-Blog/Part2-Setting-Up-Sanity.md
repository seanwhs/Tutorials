**Here's the clean, updated full Part 2 tutorial** based on what the Sanity CLI actually generated for you:

---

## Blog Tutorial - Part 2: Setting Up Sanity (Account, Project, Embedded Studio)

### What is Sanity?
Sanity is a **headless CMS** that stores your blog content (posts, authors, images, etc.) in a hosted database and gives you a powerful editing interface called **Studio**. We are embedding it directly inside your Next.js app at `/studio`.

---

### Step 1: Create a free Sanity account

1. Go to [https://www.sanity.io/get-started](https://www.sanity.io/get-started)
2. Sign up (GitHub recommended)
3. Free plan is sufficient for this project.

---

### Step 2: Install required packages

```bash
npm install next-sanity sanity @sanity/vision
```

---

### Step 3: Initialize Sanity

Run the following command:

```bash
npx sanity@latest init --env .env.local
```

**Answer the prompts like this:**
- Select project → **GreyMatter Journal** (`xdajrdsx`)
- Dataset → `production`
- Add configuration files? → `Y`
- Use TypeScript? → `Y`
- Embedded Sanity Studio? → `Y`
- Studio route? → Press **Enter** (`/studio`)

---

### Step 4: Check your `.env.local`

Open `.env.local` and verify it contains:

```env
NEXT_PUBLIC_SANITY_PROJECT_ID=xdajrdsx
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-01-01

# Optional - we'll add this later for draft content
SANITY_API_READ_TOKEN=
```

---

### Step 5: Sanity Config Files (CLI Generated)

The init command should have created these files in the **root** of your project:

- `sanity.config.ts`
- `sanity.cli.ts`

**Update `sanity.config.ts` title:**

```ts
import { defineConfig } from 'sanity'
import { structureTool } from 'sanity/structure'
import { visionTool } from '@sanity/vision'
import { schema } from './src/sanity/schemaTypes'   // adjust path if needed

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

---

### Step 6: Studio Route (CLI Generated)

Open this file (it should already exist):

**`src/app/studio/[[...tool]]/page.tsx`**

Make sure it looks like this:

```tsx
/**
 * This route is responsible for the built-in authoring environment using Sanity Studio.
 */

import { NextStudio } from 'next-sanity/studio'
import config from '../../../../sanity.config'

export const dynamic = 'force-static'

export { metadata, viewport } from 'next-sanity/studio'

export default function StudioPage() {
  return <NextStudio config={config} />
}
```

---

### Step 7: Test Everything

```bash
npm run dev
```

Visit: **http://localhost:3000/studio**

Log in with your Sanity account. You should now see the Studio interface.

---

### Checkpoint ✅

- [ ] `.env.local` has correct Project ID (`xdajrdsx`)
- [ ] `sanity.config.ts` title updated to "GreyMatter Journal"
- [ ] `/studio` loads without errors
- [ ] You can log into the embedded Studio

---

**Next:** Part 3 — Creating your content schemas (Post, Author, etc.)

---

Let me know if any file is missing or if you get an error when visiting `/studio`, and I’ll help you fix it right away.
