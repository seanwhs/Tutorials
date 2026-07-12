## Blog Tutorial - Part 2: Setting Up Sanity

In this part, we will embed the **Sanity Studio** directly into your Next.js project. We will also configure the API clients for reading and writing data, and ensure our middleware correctly ignores the Studio route to maintain performance.

### Step 1: Install Dependencies

```bash
npm install next-sanity sanity @sanity/vision @sanity/client @sanity/image-url @portabletext/react groq

```

### Step 2: Initialize Sanity

Run the official initializer in your root directory:

```bash
npx sanity@latest init --env .env.local

```

* **Prompts:** Select your project, dataset (`production`), and when asked for the **Studio path**, enter `/studio`.

### Step 3: Configure Environment Variables & Write Token

1. **Generate Token:** Run `npx sanity manage` to open your project dashboard in the browser. Navigate to the **API** tab, create a new token, and select **Editor** permissions.
2. **Update `.env.local`:** Ensure your `.env.local` contains the following:

```env
NEXT_PUBLIC_SANITY_PROJECT_ID=[your-project-id]
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2024-01-01
SANITY_API_WRITE_TOKEN=[your-token-from-sanity-dashboard]

```

### Step 4: The Studio Route (Split Pattern)

To ensure the Studio (a Client Component) doesn't conflict with server-side metadata, we split it into two files in `src/app/studio/[[...tool]]/`:

**`studio-component.tsx` (Client):**

```tsx
'use client';
import { NextStudio } from 'next-sanity/studio';
import config from '../../../../sanity.config'; 

export default function StudioComponent() {
  return <NextStudio config={config} />;
}

```

**`page.tsx` (Server):**

```tsx
import { metadata, viewport } from 'next-sanity/studio';
import StudioComponent from './studio-component';

export { metadata, viewport };
export const dynamic = 'force-static';

export default function StudioPage() {
  return <StudioComponent />;
}

```

### Step 5: Sanity Client Orchestration

Create the following files in `src/sanity/lib/`:

**`client.ts` (Read-only):**

```tsx
import { createClient } from "next-sanity";
export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  apiVersion: "2024-01-01",
  useCdn: process.env.NODE_ENV === "production",
});

```

**`writeClient.ts` (For Comments/Auth):**

```tsx
import { createClient } from "next-sanity";
export const writeClient = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  apiVersion: "2024-01-01",
  useCdn: false,
  token: process.env.SANITY_API_WRITE_TOKEN,
});

```

### Step 6: Protecting Middleware

Update `middleware.ts` to ensure Clerk ignores the `/studio` route completely, preventing auth redirects from breaking your admin dashboard:

```tsx
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isPublicRoute = createRouteMatcher([
  "/", "/sign-in(.*)", "/sign-up(.*)", "/categories(.*)", "/posts(.*)"
]);

export default clerkMiddleware(async (auth, request) => {
  if (!isPublicRoute(request)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    // This regex matches everything EXCEPT static files and the /studio route
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)|studio).*)",
    "/(api|trpc)(.*)",
  ],
};

```

### Step 7: Final Config Tweaks

Ensure `next.config.ts` handles Sanity's ESM modules:

```ts
import type { NextConfig } from "next";
const nextConfig: NextConfig = {
  transpilePackages: ['next-sanity', 'sanity'],
};
export default nextConfig;

```

### Checkpoint ✅

* [ ] **Studio Routing:** Successfully split into `studio-component` and `page`.
* [ ] **Middleware:** Confirmed that `/studio` is explicitly ignored by Clerk.
* [ ] **Clients:** Read-only (`client.ts`) and Write-enabled (`writeClient.ts`) are ready for use.
* [ ] **Verification:** `http://localhost:3000/studio` loads without auth prompts or errors.
