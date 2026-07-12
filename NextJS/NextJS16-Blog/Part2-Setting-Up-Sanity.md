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

Answer:
- Select your project **GreyMatter Journal**
- Dataset: `production`
- Add config files: `Y`
- TypeScript: `Y`
- Embedded Studio: `Y`
- Route: `/studio` (press Enter)

---

### Step 4: Verify `.env.local`

Make sure `.env.local` contains:

```env
NEXT_PUBLIC_SANITY_PROJECT_ID=xdajrdsx
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2026-01-01

SANITY_API_READ_TOKEN=
```

---

### Step 5: Sanity Config Files (Updated)

The CLI created a `src/sanity/` folder structure. Update your main config file:

**`sanity.config.ts`** (in project root):

```ts
'use client'

/**
 * This configuration is used for the Sanity Studio mounted at /studio
 */

import { visionTool } from '@sanity/vision'
import { defineConfig } from 'sanity'
import { structureTool } from 'sanity/structure'

import { apiVersion, dataset, projectId } from './src/sanity/env'
import { schema } from './src/sanity/schemaTypes'
import { structure } from './src/sanity/structure'

export default defineConfig({
  basePath: '/studio',
  projectId,
  dataset,

  schema,
  plugins: [
    structureTool({ structure }),
    visionTool({ defaultApiVersion: apiVersion }),
  ],
})
```

---

### Step 6: Studio Route

Your file `src/app/studio/[[...tool]]/page.tsx` should look like this:

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

### Step 7: Test

```bash
npm run dev
```

Visit → **http://localhost:3000/studio**

---

### Quick Checklist

- [ ] `.env.local` has correct Project ID (`xdajrdsx`)
- [ ] `sanity.config.ts` is updated with your blog title (optional but recommended)
- [ ] No import errors when running `npm run dev`

Would you like me to also show you the contents of the other generated files (`env.ts`, `schemaTypes/index.ts`, `structure.ts`) so you can verify them?

Just say the word and I’ll give you the full set.
