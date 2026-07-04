# **✅ Part 22 — Images, Object Storage, CDNs, and the Global Content Delivery System**

---

# GreyMatter Journal  
## Part 22 — Images, Object Storage, CDNs, and Why the Internet Is a Giant Content Delivery System

> **Goal of this lesson:** Properly handle images in GreyMatter Journal while understanding binary data, asset pipelines, and the distributed nature of the modern web.

---

### Why Databases Don't Store Large Files

Databases excel at structured data. Large binary files (images, videos) cause performance and cost issues.

**Modern pattern:** Store **metadata** in the database, **binary assets** in object storage + CDN.

---

### Add Hero Images

**Schema update** (`post.ts`):

```typescript
defineField({
  name: "heroImage",
  title: "Hero Image",
  type: "image",
  options: { hotspot: true },
}),
```

**Query updates** to include `heroImage`.

---

### Image URL Builder

Install `@sanity/image-url` and create `lib/image.ts`:

```typescript
import imageUrlBuilder from "@sanity/image-url";
import { client } from "./sanity";

const builder = imageUrlBuilder(client);

export function urlFor(source: any) {
  return builder.image(source);
}
```

---

### Render with `next/image`

Example in `PostCard.tsx`:

```tsx
import Image from "next/image";
import { urlFor } from "@/lib/image";

{post.heroImage && (
  <Image
    src={urlFor(post.heroImage).width(800).height(450).url()}
    alt={post.title}
    width={800}
    height={450}
    className="rounded-xl object-cover"
  />
)}
```

---

### Key Concepts

- **Object Storage**: Scalable storage for binary data (Sanity handles this)
- **CDN**: Distributed cache network for fast global delivery
- **Image Optimization**: Resize, compress, format conversion (WebP/AVIF), lazy loading
- **Hotspot**: Editor-defined focal point for intelligent cropping

---

### Mental Model To Remember Forever

> An image is not a file — it is **metadata + transformation pipeline + distributed delivery**.

The internet is fundamentally a **global content delivery system** built on layers of caching and intelligent routing.

---

### Up Next — Part 23: Deployment and Production Architecture

We’ll cover build pipelines, CI/CD, hosting, and turning code into a live production system.
