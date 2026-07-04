# **Part 14 — Images in Modern Web Applications**

# GreyMatter Journal

## Part 14 — Images: Asset Pipelines, Distributed Systems, and the Architecture of Modern Media Delivery

> **Goal of this lesson:** Understand how modern web applications handle images using Sanity and Next.js, and discover why images are no longer simple files, but distributed assets processed through global transformation pipelines.

---

# The Great Lie of Web Development

One of the first things every web developer learns is this:

```html
<img src="photo.jpg" />
```

This creates a dangerous illusion.

It suggests that images are simple.

For many years, that illusion was mostly acceptable. Websites were smaller, screens were simpler, and users expected pages to load slowly.

But modern web applications live in a very different world.

Consider a single image uploaded by an editor:

```text
hero-photo.jpg
```

Immediately, dozens of questions emerge:

* Is the visitor using a phone or a desktop?
* Is the screen standard density or Retina?
* Should we deliver JPEG, WebP, or AVIF?
* Should the image be resized?
* Should it be cropped?
* Should it be compressed?
* Should it be lazy loaded?
* Which CDN edge location should serve it?
* Has this version already been cached?
* How do we preserve visual quality while reducing bandwidth?

Suddenly, something profound becomes apparent:

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
Transformation Rules
    +
Caching Strategy
    +
Global Distribution Network
```

Modern image handling is not a frontend problem.

It is a distributed systems problem.

---

# Images Are One of the Hardest Problems on the Web

Text is easy.

A blog post containing:

```text
Hello World
```

is:

```text
11 bytes
```

An image, however, might be:

```text
5 MB
10 MB
20 MB
```

And unlike text:

```text
The same image
must exist in many forms.
```

For example:

```text
Original
     ↓
Desktop Version
     ↓
Tablet Version
     ↓
Mobile Version
     ↓
Retina Version
     ↓
Thumbnail Version
     ↓
Preview Version
```

This is why modern image systems rarely store or serve images directly.

Instead, they build image pipelines.

---

# The Modern Image Pipeline

When an editor uploads an image, the browser rarely receives that original file.

Instead, the image travels through an entire processing pipeline:

```text
Editor Upload
       ↓
Asset Storage
       ↓
Metadata Extraction
       ↓
Transformation Engine
       ↓
CDN Distribution
       ↓
Browser Optimization
       ↓
User
```

This is exactly what happens when Sanity and Next.js work together.

---

# Step 1 — Extend Our Content Model

Let's begin by teaching our content model that posts have images.

Open:

```text
studio/schemaTypes/post.ts
```

Add:

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

Similarly, add profile images to authors:

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

---

# Why Is `hotspot` Important?

Suppose an editor uploads:

```text
 -------------------------
|                         |
|        PERSON           |
|                         |
 -------------------------
```

The editor knows the important part of the image is:

```text
PERSON
```

Without additional information, a cropping algorithm might do this:

```text
 -------------------------
|                         |
|                         |
 -------------------------
```

The subject disappears.

The `hotspot` feature allows editors to communicate intent:

```text
This region matters.
Protect it.
```

Modern image systems are not merely storing pixels.

They are storing meaning.

---

# What Does Sanity Actually Store?

Many beginners imagine that Sanity stores this:

```text
post
    ↓
photo.jpg
```

But that's not what happens.

Instead, Sanity stores something closer to:

```json
{
  "_type": "image",
  "asset": {
    "_ref": "image-abc123-2400x1600-jpg"
  }
}
```

Notice something surprising:

```text
The image itself
is not inside the document.
```

Instead:

```text
Document
      ↓
Reference
      ↓
Asset Store
```

This should feel familiar.

Throughout modern software engineering, we repeatedly discover the same pattern:

```text
Systems
       =
Objects
       +
Relationships
```

Content management systems are no different.

---

# Step 2 — Install the Image Builder

Install Sanity's image URL builder:

```bash
npm install @sanity/image-url
```

This package doesn't manipulate images.

Instead, it constructs image transformation requests.

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

This helper gives us a fluent API:

```typescript
urlFor(post.mainImage)
  .width(800)
  .height(450)
  .url();
```

At first glance, this appears to resize an image.

It doesn't.

---

# What Is Actually Happening?

Consider:

```typescript
urlFor(post.mainImage)
  .width(800)
  .height(450)
  .url();
```

This simply produces a URL:

```text
https://cdn.sanity.io/...
    ?w=800
    &h=450
```

The real work happens later:

```text
Browser
      ↓
Sanity CDN
      ↓
Fetch Original Asset
      ↓
Resize
      ↓
Crop
      ↓
Compress
      ↓
Convert Format
      ↓
Cache Result
      ↓
Return Response
```

This architecture is called:

```text
On-demand image transformation.
```

Rather than storing every possible image size:

```text
photo-small.jpg
photo-medium.jpg
photo-large.jpg
photo-mobile.jpg
photo-retina.jpg
```

we store:

```text
One original image
```

and generate everything else dynamically.

---

# Step 4 — Teach Next.js to Trust Sanity

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

Why?

Because Next.js intentionally distrusts external image sources.

This is a security feature.

By configuring `remotePatterns`, we're telling Next.js:

> Images from this domain are trusted.

---

# Step 5 — Extend Our Queries

Update our GROQ query:

```groq
mainImage,

author->{
  name,
  image
}
```

Now our application receives:

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

Notice something important:

```text
UI components
never fetch images directly.
```

Instead:

```text
Content
      ↓
Query
      ↓
Data Model
      ↓
Component
      ↓
Rendered UI
```

---

# Step 6 — Render Images

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

# Why Not Just Use `<img>`?

This is one of the best beginner questions.

Traditional HTML gives us:

```html
<img src="image.jpg" />
```

Which essentially means:

```text
Show image.
```

The `next/image` component provides much more:

```text
✓ Automatic lazy loading
✓ Layout stability
✓ Responsive sizing
✓ Browser optimization
✓ CDN integration
✓ Modern formats
✓ Performance optimization
✓ Reduced bandwidth
✓ Better Core Web Vitals
```

In modern web engineering:

```text
Rendering images
        =
Performance engineering
```

---

# Hero Images Are Different

Not every image should be lazy loaded.

Consider an article hero image:

```tsx
<Image
  src={
    urlFor(post.mainImage)
      .width(1600)
      .height(900)
      .url()
  }
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

The important property here is:

```tsx
priority
```

This tells Next.js:

```text
This image is critical.

Load it immediately.
```

Use `priority` sparingly:

* Hero images
* Above-the-fold content
* Largest Contentful Paint elements

Everything else should remain lazy.

---

# The Complete Image Architecture

Our image pipeline now looks like this:

```text
Editor Upload
       ↓
Sanity Asset Store
       ↓
Asset Reference
       ↓
Document Database
       ↓
GROQ Query
       ↓
Server Component
       ↓
Image Builder
       ↓
Sanity CDN
       ↓
Resize
Crop
Compress
Convert
Cache
       ↓
next/image
       ↓
Browser
```

Notice what we never manually do:

```text
✗ Resize images
✗ Generate thumbnails
✗ Create mobile versions
✗ Compress assets
✗ Convert formats
✗ Build responsive variants
✗ Manage CDN caches
```

The platform does this for us.

---

# Images Are Distributed Systems

One of the most important realizations in modern web development is this:

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
Distributed System
```

Because every image involves:

```text
Storage
     +
Metadata
     +
Transformation
     +
Caching
     +
Global Distribution
     +
Optimization
     +
Rendering
     +
Performance Engineering
```

This is why image optimization remains one of the most challenging areas of frontend engineering.

---

# The Deepest Mental Model

Beginners think:

```text
Image
     =
Picture
```

Intermediate developers think:

```text
Image
     =
File
```

Professional engineers think:

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

Or even more fundamentally:

```text
Original Reality
          ↓
Digital Asset
          ↓
Transformation
          ↓
Optimization
          ↓
Distribution
          ↓
Rendering
          ↓
User Experience
```

Modern web performance is largely the art of transforming information efficiently.

---

# Up Next — Part 15: Navigation, Route Groups, and Layout Composition

Next, we'll return to one of the deepest ideas in the App Router:

* Route groups
* Nested layouts
* Layout composition
* Persistent UI trees
* Shared state
* Application shells
* Hierarchical rendering systems

This is where GreyMatter Journal finally begins to feel less like a website and more like a modern application architecture.
