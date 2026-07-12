## Blog Tutorial - Part 2: Setting Up Sanity (Account, Project, Embedded Studio)

### What is Sanity?

Sanity is a headless CMS. We’re embedding the Studio directly into your Next.js app at `/studio`.

---

### Step 1: Create a free Sanity account

1. Go to [https://www.sanity.io/get-started](https://www.sanity.io/get-started)
2. Sign up (GitHub recommended).

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

**Prompts:** Select your project (**GreyMatter Journal**), Dataset (`production`), Add config files (`Y`), TypeScript (`Y`), Embedded Studio (`Y`), and Studio route (`/studio`).

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

### Step 5: Configure `sanity.config.ts`

Replace **`sanity.config.ts`** (root) with:

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

### Step 6: Create Schema Index

Create the folder and file: **`src/sanity/schemaTypes/index.ts`**

```ts
import { type SchemaTypeDefinition } from 'sanity'

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [],
}

```

---

### Step 7: Configure the Studio Route (The "Split" Pattern)

To avoid build errors, we must separate the Client Component (Studio) from the Server Component (Metadata).

**File A: The Client Wrapper (`src/app/studio/[[...tool]]/studio-component.tsx`)**

```tsx
'use client';

import { NextStudio } from 'next-sanity/studio';
import config from '../../../../sanity.config';

export default function StudioComponent() {
  return <NextStudio config={config} />;
}

```

**File B: The Server Page (`src/app/studio/[[...tool]]/page.tsx`)**

```tsx
import { metadata, viewport } from 'next-sanity/studio';
import StudioComponent from './studio-component';

export { metadata, viewport };

export const dynamic = 'force-static';

export default function StudioPage() {
  return <StudioComponent />;
}

```

---

### Step 8: Update `next.config.ts`

Ensure your configuration handles Sanity’s ESM modules correctly:

```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactCompiler: false,
  transpilePackages: ['next-sanity', 'sanity'],
};

export default nextConfig;

```

---

### Step 9: Test

```bash
npm run dev

```

Navigate to **http://localhost:3000/studio**. The studio should now load perfectly.

---

**Checkpoint ✅**

* [ ] `.env.local` configured
* [ ] `sanity.config.ts` points to `src/sanity/schemaTypes`
* [ ] Studio route is split into two files to handle Next.js Server/Client boundaries
* [ ] `transpilePackages` added to `next.config.ts`
