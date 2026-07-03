# GreyMatter Journal

# Part 14 — Images in Modern Web Applications: Understanding Asset Pipelines, CDNs, and `next/image`

> **Goal of this lesson:** Learn how Sanity stores images, why images are references instead of files, how image transformation CDNs work, and how to properly render optimized images using Next.js 16.

---

# Our Blog Articles Need Images

At this point, our blog works:

```text
✓ Homepage
✓ Dynamic Routes
✓ Portable Text
✓ Authors
✓ Categories
✓ Articles
```

But every modern blog needs:

```text
Featured Images
Author Avatars
Inline Article Images
```

Before we add images, however, we need to understand something important:

> Modern websites almost never serve raw image files.

---

# How Beginners Think Images Work

Most beginners imagine:

```text
Image File
     ↓
Browser
```

For example:

```html
<img src="photo.jpg" />
```

This worked twenty years ago.

But modern websites have a problem:

```text
Desktop: 2560px
Tablet: 1024px
Phone: 390px
Retina: 2x
4K: 3840px
```

Should we serve:

```text
4000px image
```

to every device?

Of course not.

---

# The Modern Image Pipeline

Modern websites use:

```text
Original Image
        ↓
Image CDN
        ↓
Resize
        ↓
Compress
        ↓
Optimize
        ↓
Browser
```

Diagram:

```text
Photographer
       │
       ▼
Original Image
       │
       ▼
Asset Storage
       │
       ▼
Transformation CDN
       │
       ▼
Optimized Browser Image
```

This is exactly what Sanity provides.

---

# Step 1 — Add Featured Images To Posts

Open:

```text
studio/schemaTypes/post.ts
```

Add a new field:

```typescript
defineField({
  name: "mainImage",

  title: "Featured Image",

  type: "image",

  options: {
    hotspot: true,
  },
}),
```

---

# Wait...

What Is `hotspot`?

Suppose your image is:

```text
+------------------+
|                  |
|      PERSON      |
|                  |
+------------------+
```

When viewed on mobile:

```text
+------+
| PER  |
| SON  |
+------+
```

The image may crop incorrectly.

Hotspot allows editors to specify:

```text
This area matters.
```

Diagram:

```text
Image

+-----------------------+
|                       |
|       PERSON          |
|          X            |
|                       |
+-----------------------+

         ↑
      Hotspot
```

---

# Step 2 — Add Author Images

Open:

```text
studio/schemaTypes/author.ts
```

Add:

```typescript
defineField({
  name: "image",

  title: "Profile Image",

  type: "image",

  options: {
    hotspot: true,
  },
}),
```

---

# Publish New Content

Return to:

```text
http://localhost:3333
```

Edit:

```text
Authors
Posts
```

Upload:

```text
✓ Author Avatar
✓ Featured Image
```

Publish everything.

---

# What Happens Internally?

You uploaded:

```text
photo.jpg
```

But Sanity stores:

```json
{
  "_type": "image",
  "asset": {
    "_ref":
      "image-abc123"
  }
}
```

Notice:

```text
No actual image exists
inside your post.
```

---

# Why?

Imagine:

```text
5 MB image
```

used in:

```text
100 articles
```

Bad design:

```text
5 MB × 100
```

Good design:

```text
One image
      +
100 references
```

Diagram:

```text
Article
   │
   ├──────► Image
   │
Article
   │
   ├──────► Image
   │
Article
```

This is database normalization.

---

# Step 3 — Install The Image Library

Return to your project:

```bash
npm install @sanity/image-url
```

---

# What Does This Package Do?

Many beginners think:

```text
Image Reference
        ↓
Image File
```

Not quite.

Instead:

```text
Image Reference
        ↓
Image Builder
        ↓
Transformation URL
        ↓
Image CDN
```

Diagram:

```text
Reference
     │
     ▼
Builder
     │
     ▼
URL
     │
     ▼
CDN
```

---

# Create The Image Builder

Create:

```text
lib/image.ts
```

Add:

```typescript
import imageUrlBuilder
  from "@sanity/image-url";

import { client }
  from "./sanity";

const builder =
  imageUrlBuilder(client);

export function urlFor(
  source: any
) {
  return builder.image(source);
}
```

---

# What Is A Builder?

Suppose we want:

```text
Image
width=400
height=300
quality=80
```

We could write:

```typescript
buildImage(
  image,
  400,
  300,
  80
);
```

Instead, builders allow:

```typescript
urlFor(image)
  .width(400)
  .height(300)
  .quality(80)
```

This is called:

# Fluent Interface Pattern

Diagram:

```text
Object
   │
   ▼
.method()
   │
   ▼
.method()
   │
   ▼
.method()
```

---

# Step 4 — Update The Query

Open:

```text
lib/queries.ts
```

Update:

```groq
export const POSTS_QUERY = `
  *[_type=="post"]
  | order(publishedAt desc)
  {
    _id,

    title,

    slug,

    excerpt,

    mainImage,

    publishedAt,

    author->{
      name,
      image
    },

    categories[]->{
      title
    }
  }
`;
```

Similarly update:

```groq
POST_QUERY
```

to include:

```groq
mainImage
```

---

# Step 5 — Configure Next.js

Open:

```text
next.config.ts
```

Add:

```typescript
import type {
  NextConfig
} from "next";

const nextConfig:
  NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",

        hostname:
          "cdn.sanity.io",
      },
    ],
  },
};

export default nextConfig;
```

Restart the server.

---

# Wait...

Why Do We Need This?

Because Next.js assumes:

```text
External Image
       =
Potentially Unsafe
```

You must explicitly trust:

```text
cdn.sanity.io
```

---

# Step 6 — Render The Featured Image

Open:

```text
components/PostCard.tsx
```

Import:

```tsx
import Image from "next/image";

import { urlFor }
  from "@/lib/image";
```

Add:

```tsx
{
  post.mainImage && (
    <Image
      src={
        urlFor(
          post.mainImage
        )
          .width(800)
          .height(450)
          .url()
      }
      alt={post.title}
      width={800}
      height={450}
    />
  )
}
```

---

# Wait...

Why So Complicated?

Why not:

```html
<img src="..." />
```

Because `next/image` performs:

```text
✓ Lazy Loading
✓ Responsive Images
✓ Compression
✓ Caching
✓ Format Conversion
✓ Performance Optimization
```

---

# What Happens Internally?

Suppose:

```typescript
urlFor(image)
  .width(800)
  .height(450)
```

creates:

```text
https://cdn.sanity.io/...
?w=800&h=450
```

Then:

```text
Browser
     │
     ▼
Sanity CDN
     │
     ▼
Resize
     │
     ▼
Compress
     │
     ▼
WebP/AVIF
     │
     ▼
Browser
```

---

# Step 7 — Render The Hero Image

Open:

```text
app/posts/[slug]/page.tsx
```

Import:

```tsx
import Image from "next/image";

import { urlFor }
  from "@/lib/image";
```

Add:

```tsx
{
  post.mainImage && (
    <Image
      src={
        urlFor(
          post.mainImage
        )
          .width(1200)
          .height(675)
          .url()
      }
      alt={post.title}
      width={1200}
      height={675}
      priority
    />
  )
}
```

---

# Wait...

What Does `priority` Mean?

Normally:

```text
Page Loads
      ↓
Image Loads Later
```

But hero images are important.

So:

```tsx
priority
```

tells Next.js:

```text
Load immediately.
```

Diagram:

```text
Normal Image

Page
   ↓
Image

Priority Image

Page + Image
```

---

# Understanding Responsive Images

Suppose your image is:

```text
1200px
```

A phone only needs:

```text
400px
```

Modern browsers negotiate:

```text
Desktop → 1200px
Tablet  → 800px
Phone   → 400px
```

Diagram:

```text
Original

     4000px

        ↓

CDN

        ↓

1200
800
400
```

---

# Why Image Optimization Matters

Suppose:

```text
Homepage:

10 images

500 KB each
```

Total:

```text
5 MB
```

Optimized:

```text
10 images

50 KB each
```

Total:

```text
500 KB
```

Result:

```text
10x faster.
```

---

# The Hidden Architecture

When you see:

```tsx
<Image
  src={url}
  width={800}
  height={450}
/>
```

You should mentally picture:

```text
Original Image
       │
       ▼
Sanity Asset Store
       │
       ▼
Transformation CDN
       │
       ▼
Next.js Image
       │
       ▼
Browser Optimization
       │
       ▼
Rendered Pixels
```

---

# Wait...

Does This Look Familiar?

Just like:

```text
Portable Text
        ↓
Renderer
        ↓
HTML
```

we now have:

```text
Image Asset
        ↓
Image Pipeline
        ↓
Pixels
```

Modern software is mostly:

```text
Data
      ↓
Transformation
      ↓
Presentation
```

---

# Mental Model To Remember Forever

Beginners think:

```text
Image
    =
File
```

Modern systems think:

```text
Image
    =
Asset
      +
Metadata
      +
Transformation Pipeline
```

Or more generally:

```text
Everything in software
          =
Data
          +
Transformations
```

---

# Up Next

In **Part 15**, we'll build our navigation system and learn:

* layouts versus pages,
* persistent UI trees,
* nested layouts,
* React composition,
* shared application state,
* and why Next.js applications are actually trees of trees.
