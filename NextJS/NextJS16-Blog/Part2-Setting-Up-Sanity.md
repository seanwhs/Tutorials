## Blog Tutorial - Part 2: Setting Up Sanity (Account, Project, Embedded Studio)

### What is Sanity?
Sanity is a headless CMS. We’re embedding the Studio directly into your Next.js app at `/studio`.

---

### Step 1: Create a free Sanity account

1. Go to [https://www.sanity.io/get-started](https://www.sanity.io/get-started)
2. Sign up (GitHub recommended)

---

### Step 2: Install packages

```bash
npm install next-sanity sanity @sanity/vision
```

---

### Step 3: Initialize Sanity

```bash
npx sanity@latest init --env .env.local
```

Answer the prompts:
- Select your project → **GreyMatter Journal**
- Dataset → `production`
- Add configuration files? → `Y`
- Use TypeScript? → `Y`
- Embedded Sanity Studio? → `Y`
- Studio route? → Press Enter (`/studio`)

---

### Step 4: Verify `.env.local`

Open `.env.local` and ensure it has:

```env
NEXT_PUBLIC_SANITY_PROJECT_ID=xdajrdsx
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-01-01

SANITY_API_READ_TOKEN=
```

---

### Step 5: Fix Sanity Config Files

#### Replace the content of **`sanity.config.ts`** (in root) with this:

```ts
import { defineConfig } from 'sanity'
import { structureTool } from 'sanity/structure'
import { visionTool } from '@sanity/vision'

import { schema } from './src/sanity/schemaTypes'

export default defineConfig({
  name: 'default',
  title: 'GreyMatter Journal',
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  basePath: '/studio',
  plugins: [structureTool(), visionTool()],
  schema,
})
```

---

### Step 6: Create Missing Schema Folder

Create the folder and file:

**`src/sanity/schemaTypes/index.ts`**

```ts
import { type SchemaTypeDefinition } from 'sanity'

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [],
}
```

---

### Step 7: Studio Route

Make sure **`src/app/studio/[[...tool]]/page.tsx`** contains:

```tsx
'use client'

import { NextStudio } from 'next-sanity/studio'
import config from '../../../../sanity.config'

export const dynamic = 'force-static'

export { metadata, viewport } from 'next-sanity/studio'

export default function StudioPage() {
  return <NextStudio config={config} />
}
```

---

### Step 8: Test

```bash
npm run dev
```

Go to: **http://localhost:3000/studio**

You should now see the Sanity Studio without import errors.

---

**Checkpoint ✅**

- [ ] `.env.local` is correct
- [ ] `sanity.config.ts` updated (simple version)
- [ ] `src/sanity/schemaTypes/index.ts` created
- [ ] Studio loads at `/studio`

---

This version is now aligned with your actual file structure. Try these steps and let me know if you get any new errors!
