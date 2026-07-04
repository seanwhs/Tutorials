# **✅ Part 22 — Images, Object Storage, CDNs, and the Global Content Delivery System**

# GreyMatter Journal

## Part 22 — Images, Object Storage, CDNs, and Why the Internet Is a Giant Content Delivery System

> **Goal of this lesson:** Implement image handling in GreyMatter Journal while learning how modern systems store, transform, cache, and deliver binary assets at planetary scale.

---

# The Hidden Complexity of Images

So far, we've been working primarily with text.

Text is relatively simple:

```text
Title
Author
Content
Date
```

Images are different.

An image is:

```text
Binary Data
```

And binary data introduces entirely different engineering challenges:

* Storage
* Bandwidth
* Compression
* Latency
* Caching
* Distribution
* Transformation
* Cost

This is why image handling has become one of the largest engineering problems on the modern web.

---

# Why Databases Don't Store Images

Many beginners assume this architecture:

```text
Database
      ↓
Store Everything
```

For small projects, this can work.

However, databases are optimized for:

```text
Structured Data
```

such as:

```sql
Users
Posts
Comments
Orders
Transactions
```

Large binary files create problems:

```text
Larger backups

Slower queries

More expensive storage

Poor scalability
```

Instead, modern systems separate:

```text
Structured Data
           +
Binary Data
```

---

# The Modern Asset Architecture

Today, most applications use this pattern:

```text
Database
    ↓
Metadata

Object Storage
    ↓
Binary Assets

CDN
    ↓
Global Delivery
```

For example:

```text
Post Record

title:
"Understanding React"

heroImage:
"asset-abc123"
```

while the actual image exists elsewhere.

---

# Images Are References

Suppose an editor uploads:

```text
react-architecture.png
```

Sanity stores:

```text
Binary File
```

inside its asset storage.

The post itself only stores:

```json
{
  "heroImage": {
    "_type": "image",
    "asset": {
      "_ref": "image-abc123"
    }
  }
}
```

This separation is extremely important.

The post contains:

```text
Metadata
```

while the asset storage contains:

```text
Binary Data
```

---

# Adding Hero Images

Update:

```text
studio/schemaTypes/post.ts
```

```typescript
defineField({
  name: "heroImage",

  title: "Hero Image",

  type: "image",

  options: {
    hotspot: true,
  },
}),
```

Notice:

```typescript
hotspot: true
```

This enables one of the most useful features in modern CMS systems.

---

# What Is a Hotspot?

Suppose an editor uploads:

```text
Landscape Image
```

```text
+--------------------------------+
|                                |
|          Person                |
|                                |
+--------------------------------+
```

Now imagine displaying:

```text
Mobile Thumbnail
```

Without additional information:

```text
Crop
 ↓
Random Result
```

The important content may disappear.

Instead, editors can define:

```text
Focus Point
```

```text
+--------------------------------+
|                                |
|         (X) Person             |
|                                |
+--------------------------------+
```

This metadata allows image systems to crop intelligently.

---

# Object Storage

Modern applications use:

```text
Object Storage
```

rather than:

```text
Traditional File Systems
```

Examples include:

* Amazon S3
* Google Cloud Storage
* Cloudflare R2
* Azure Blob Storage
* Sanity Asset Store

Object storage provides:

```text
Massive Scale

Durability

Replication

Low Cost

Global Distribution
```

Unlike file systems:

```text
folder/
    image.jpg
```

object storage works more like:

```text
Unique ID
      ↓
Binary Object
```

---

# Installing the Image Builder

Install:

```bash
npm install @sanity/image-url
```

Create:

```text
lib/image.ts
```

```typescript
import imageUrlBuilder
  from "@sanity/image-url";

import {
  client,
} from "./sanity";

const builder =
  imageUrlBuilder(client);

export function urlFor(
  source: any
) {
  return builder.image(source);
}
```

This utility builds image transformation URLs.

---

# Images as Functions

This is one of the most profound ideas in modern web development:

An image is no longer:

```text
File
```

Instead:

```text
Image
     =
Asset
     +
Transformation
```

For example:

```typescript
urlFor(image)
  .width(800)
  .height(450)
  .format("webp")
  .url();
```

Conceptually:

```text
Original Image
         ↓
Apply Transformations
         ↓
Generate New Image
```

Images become functions.

---

# Rendering Images with Next.js

Update:

```text
components/posts/PostCard.tsx
```

```tsx
import Image
  from "next/image";

import {
  urlFor,
} from "@/lib/image";

{
  post.heroImage && (
    <Image
      src={
        urlFor(
          post.heroImage
        )
          .width(800)
          .height(450)
          .url()
      }

      alt={post.title}

      width={800}

      height={450}

      className="
        rounded-xl
        object-cover
        w-full
      "
    />
  );
}
```

This looks simple.

Underneath, however, a remarkable amount of work occurs.

---

# The Modern Image Pipeline

Consider what actually happens:

```text
Original Image
      ↓
Sanity Asset Store
      ↓
Sanity Image CDN
      ↓
Resize
      ↓
Crop
      ↓
Compress
      ↓
Convert Format
      ↓
Cache
      ↓
Next.js
      ↓
Browser
```

This entire pipeline exists to answer one question:

> What is the smallest image that still looks good?

---

# Why Image Optimization Exists

Suppose a photographer uploads:

```text
8000 × 6000 image
```

The file size might be:

```text
18 MB
```

But your mobile device only needs:

```text
400 × 300
```

Perhaps:

```text
40 KB
```

Without optimization:

```text
18 MB transferred
```

With optimization:

```text
40 KB transferred
```

This difference dramatically affects:

* Performance
* Battery life
* Bandwidth cost
* User experience

---

# What Does `next/image` Actually Do?

Many beginners think:

```tsx
<Image />
```

is simply:

```tsx
<img />
```

It isn't.

`next/image` adds:

```text
Responsive Sizing

Lazy Loading

Priority Loading

Caching

Optimization

Layout Stability
```

For example:

```tsx
<Image
  priority
  ...
/>
```

tells Next.js:

```text
Load this image immediately.
```

This is useful for:

```text
Hero Images
```

while ordinary images remain:

```text
Lazy Loaded
```

until needed.

---

# Understanding CDNs

Suppose your server exists in:

```text
Singapore
```

but your reader lives in:

```text
Canada
```

Without a CDN:

```text
Canada
    ↓
Singapore
    ↓
Canada
```

Every request crosses the planet.

A CDN changes this:

```text
Singapore Origin
          ↓

Tokyo Cache

Sydney Cache

London Cache

Toronto Cache
```

Now Canadian readers receive:

```text
Toronto
     ↓
Browser
```

instead of:

```text
Singapore
     ↓
Browser
```

This dramatically reduces latency.

---

# The Internet Is Mostly Caching

One of the surprising truths about modern computing is:

> The internet is largely a giant caching system.

Examples include:

```text
Browser Cache

CDN Cache

DNS Cache

Application Cache

Database Cache

Redis Cache

Edge Cache
```

Most performance engineering is actually:

```text
Cache Engineering
```

rather than:

```text
Compute Engineering
```

---

# Immutable Assets

Images have another useful property:

```text
They rarely change.
```

This allows systems to treat them as:

```text
Immutable Assets
```

For example:

```text
hero-v2-abc123.webp
```

can safely be cached:

```text
Forever
```

because if the image changes:

```text
The URL changes.
```

This principle powers most modern CDNs.

---

# Why Image Delivery Is a Distributed Systems Problem

At small scale:

```text
Server
    ↓
Image
```

At global scale:

```text
Upload
      ↓
Replication
      ↓
Transformation
      ↓
Caching
      ↓
Geographic Routing
      ↓
Edge Delivery
      ↓
Browser Rendering
```

Suddenly, image delivery becomes a distributed systems problem.

---

# Mental Model To Remember Forever

Beginners think:

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
Caching Strategy
    +
Distributed Delivery
```

More fundamentally:

```text
Modern Web
        =
Content
        +
Caching
        +
Distribution
```

The internet is not merely a network.

It is a planetary-scale content delivery system optimized to move information efficiently across space and time.

---

# Up Next — Part 23: Deployment, CI/CD, and Production Architecture

We'll finally deploy GreyMatter Journal and explore:

* Build pipelines
* Continuous Integration
* Continuous Deployment
* Hosting platforms
* Edge infrastructure
* Environment variables
* Production observability

and discover that software engineering only truly begins once software leaves your laptop.
