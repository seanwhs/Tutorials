# **✅ Part 14 — Images in Modern Web Applications**

---

# GreyMatter Journal  
## Part 14 — Images: Asset Pipelines, CDNs, and `next/image`

> **Goal of this lesson:** Master how modern web applications handle images using Sanity + Next.js image optimization.

---

### The Modern Image Problem

Raw images are large and slow. Modern websites use sophisticated pipelines to deliver the right image, at the right size, in the right format, to every device.

---

### Step 1: Add Images to Schemas

**Update `studio/schemaTypes/post.ts`** (add featured image):

```typescript
defineField({
  name: "mainImage",
  title: "Featured Image",
  type: "image",
  options: {
    hotspot: true, // Allows editors to set focal point
  },
}),
```

**Update `studio/schemaTypes/author.ts`** (add avatar):

```typescript
defineField({
  name: "image",
  title: "Profile Image",
  type: "image",
  options: { hotspot: true },
}),
```

Re-deploy/publish your changes in Studio.

---

### Step 2: Install Image URL Builder

```bash
npm install @sanity/image-url
```

---

### Step 3: Create Image Helper

Create `lib/image.ts`:

```typescript
import imageUrlBuilder from "@sanity/image-url";
import { client } from "./sanity";

const builder = imageUrlBuilder(client);

export function urlFor(source: any) {
  return builder.image(source);
}
```

---

### Step 4: Configure Next.js for External Images

Update `next.config.ts`:

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "cdn.sanity.io",
      },
    ],
  },
};

export default nextConfig;
```

---

### Step 5: Update Queries

Add `mainImage` and author `image` to your `POSTS_QUERY` and `POST_QUERY`.

---

### Step 6: Render Optimized Images

**In `PostCard.tsx` (using `next/image`):**

```tsx
import Image from "next/image";
import { urlFor } from "@/lib/image";

{post.mainImage && (
  <Image
    src={urlFor(post.mainImage).width(800).height(450).url()}
    alt={post.title}
    width={800}
    height={450}
    className="rounded-xl object-cover w-full"
  />
)}
```

**In Article Page (`app/posts/[slug]/page.tsx`):**

Use `priority` for hero images.

---

### How the Pipeline Works

```text
Original Image (Sanity Asset Store)
        ↓
Sanity Image CDN (Transformation Service)
        ↓
Resize + Compress + Format Conversion (WebP/AVIF)
        ↓
next/image (Client-side optimizations + lazy loading)
        ↓
Browser
```

---

### Mental Model To Remember Forever

> An image is not a file.  
> It is an **asset** + **metadata** + **transformation pipeline**.

Modern web performance is largely about intelligent data transformation.

---

### Up Next — Part 15: Navigation & Layout Composition

We’ll refine the application shell, explore nested layouts, and deepen our understanding of React composition.
