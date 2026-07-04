# **✅ Part 14 — Images in Modern Web Applications**

# GreyMatter Journal

## Part 14 — Images: Asset Pipelines, CDNs, and `next/image`

> **Goal of this lesson:** Understand how modern web applications handle images using Sanity and Next.js, and learn why images are fundamentally distributed assets processed through transformation pipelines.

---

# Images Are Harder Than They Look

At first glance, displaying an image appears trivial:

```html
<img src="photo.jpg" />
```

This worked reasonably well in the early days of the web.

However, modern applications face a very different reality.

Consider a single image uploaded by an editor:

```text
hero-photo.jpg
```

Questions immediately arise:

* Is the user on mobile or desktop?
* Is the screen Retina or standard density?
* Should we serve JPEG, WebP, or AVIF?
* Should we crop or resize?
* Should we lazy load?
* Should we cache globally?
* Which CDN edge location should serve it?

Suddenly:

```text
Image
    ≠
File
```

Instead:

```text
Image
    =
Asset
    +
Metadata
    +
Transformation Pipeline
    +
CDN Delivery
```

---

# The Modern Image Pipeline

Modern web applications rarely serve original images directly.

Instead, they use an asset pipeline:

```text
Editor Upload
       ↓
Asset Storage
       ↓
Image Metadata
       ↓
Transformation Service
       ↓
CDN Cache
       ↓
Browser Optimization
       ↓
User
```

This is precisely what Sanity and Next.js provide together.

---

# Step 1 — Add Images to Our Schemas

Let's begin by extending our content model.

Update:

```text
studio/schemaTypes/post.ts
```

Add a featured image:

```typescript
defineField({
  name: "mainImage",
  title: "Featured Image",
  type: "image",
  options: {
    hotspot: true,
  },
});
```

The `hotspot` option is extremely important.

It allows editors to specify:

```text
The important part
of the image.
```

For example:

```text
Landscape Photo

 -------------------
|                   |
|      PERSON       |
|                   |
 -------------------

       ↑
    Hotspot
```

When the image is cropped responsively, Sanity attempts to preserve this focal point.

---

Update:

```text
studio/schemaTypes/author.ts
```

Add profile images:

```typescript
defineField({
  name: "image",
  title: "Profile Image",
  type: "image",
  options: {
    hotspot: true,
  },
});
```

After updating the schemas:

```bash
npm run dev
```

inside the Studio project and publish the changes.

---

# What Does Sanity Actually Store?

Many beginners assume Sanity stores:

```text
photo.jpg
```

It doesn't.

Instead, Sanity stores something closer to:

```json
{
  "_type": "image",
  "asset": {
    "_ref":
      "image-abc123-2400x1600-jpg"
  }
}
```

Notice:

```text
No actual image exists
inside your document.
```

Instead, the document contains:

```text
Reference
        ↓
Asset Store
```

This is another example of one of our recurring architectural themes:

> Everything becomes a graph of relationships.

---

# Step 2 — Install the Image Builder

Install Sanity's image URL builder:

```bash
npm install @sanity/image-url
```

This package allows us to construct image transformation requests.

---

# Step 3 — Create the Image Helper

Create:

```text
lib/image.ts
```

```typescript
import imageUrlBuilder
  from "@sanity/image-url";

import { client }
  from "./sanity";

const builder =
  imageUrlBuilder(client);

export function urlFor(
  source: unknown
) {
  return builder.image(source);
}
```

This helper creates a fluent API:

```typescript
urlFor(post.mainImage)
  .width(800)
  .height(450)
  .url();
```

---

# What Is Really Happening?

Consider:

```typescript
urlFor(post.mainImage)
  .width(800)
  .height(450)
  .url();
```

This does not resize the image.

Instead, it generates a URL:

```text
https://cdn.sanity.io/...
    ?w=800
    &h=450
```

When requested:

```text
Browser
      ↓
Sanity CDN
      ↓
Resize Image
      ↓
Compress Image
      ↓
Convert Format
      ↓
Cache Result
      ↓
Return Response
```

This process is called:

```text
On-demand image transformation.
```

---

# Step 4 — Configure Next.js

Open:

```text
next.config.ts
```

Add:

```typescript
import type {
  NextConfig,
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

This tells Next.js:

> These external image sources are trusted.

Without this configuration, Next.js blocks external images.

---

# Step 5 — Update Our Queries

Update:

```text
lib/queries.ts
```

Add the featured image:

```groq
mainImage,
```

Add author images:

```groq
author->{
    name,
    image
}
```

Our query now returns:

```text
Post
     ↓
Title
Slug
Excerpt
Featured Image
Author
Author Image
Categories
```

---

# Step 6 — Render Images in Post Cards

Open:

```text
components/posts/PostCard.tsx
```

Import:

```tsx
import Image
  from "next/image";

import { urlFor }
  from "@/lib/image";
```

Then render:

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
      className="
        mb-6
        h-64
        w-full
        rounded-xl
        object-cover
      "
    />
  );
}
```

---

# Why Use `next/image`?

Many beginners ask:

> Why not just use `<img>`?

Traditional HTML:

```html
<img src="image.jpg" />
```

provides:

```text
✓ Display image
```

`next/image` provides:

```text
✓ Lazy loading
✓ Responsive sizing
✓ Automatic optimization
✓ Layout stability
✓ Blur placeholders
✓ CDN integration
✓ Modern image formats
✓ Browser optimization
```

In modern applications:

```text
Image rendering
       =
Performance engineering
```

---

# Hero Images

On article pages, we often want the main image to load immediately.

Example:

```tsx
<Image
  src={urlFor(post.mainImage)
    .width(1600)
    .height(900)
    .url()}
  alt={post.title}
  width={1600}
  height={900}
  priority
  className="
    mb-10
    rounded-2xl
    object-cover
  "
/>
```

Notice:

```tsx
priority
```

This tells Next.js:

```text
Load immediately.

Do not lazy load.
```

Use this only for:

* Hero images
* Above-the-fold content
* Largest Contentful Paint elements

---

# The Full Image Pipeline

Our final image architecture becomes:

```text
Editor Upload
       ↓
Sanity Asset Store
       ↓
Asset Reference
       ↓
Portable Content
       ↓
GROQ Query
       ↓
Image Builder
       ↓
Sanity CDN
       ↓
Resize
Compress
Convert
Cache
       ↓
next/image
       ↓
Browser
```

Notice that nowhere do we manually:

* Resize images
* Compress images
* Convert formats
* Generate thumbnails
* Create mobile versions

The system does this automatically.

---

# Images Are Distributed Systems

One of the biggest lessons in modern web engineering is:

```text
Images
      ≠
Files
```

Instead:

```text
Images
      =
Distributed Systems
```

They involve:

```text
Storage
    +
Metadata
    +
Transformation
    +
Caching
    +
CDNs
    +
Rendering
    +
Performance Optimization
```

This is why image optimization remains one of the hardest problems in web development.

---

# Mental Model To Remember Forever

Traditional thinking:

```text
Image
     =
File
```

Modern thinking:

```text
Image
     =
Asset
     +
Metadata
     +
Transformation Pipeline
     +
Distributed Delivery Network
```

Or more fundamentally:

```text
Original Asset
         ↓
Transformation
         ↓
Optimization
         ↓
Caching
         ↓
Delivery
         ↓
User Experience
```

Modern web performance is largely the art of transforming data efficiently.

---

# Up Next — Part 15: Navigation, Route Groups, and Layout Composition

We'll return to one of the most important ideas in the App Router:

* Route groups
* Nested layouts
* Layout composition
* Persistent UI trees
* Shared state
* Application shells
* Why modern applications are fundamentally hierarchical systems

This is where GreyMatter Journal begins to feel like a true application rather than a collection of pages.
