# GreyMatter Journal

## Part 22 — Images, Object Storage, CDNs, and Why the Modern Web Is Really a Distributed Content System

> **Goal of this lesson:** Implement image handling in GreyMatter Journal while developing a deep understanding of how modern software systems store, transform, cache, optimize, and deliver binary assets at global scale.

---

# Images Are Much Harder Than Text

Throughout most of this series, we have worked with text.

Text is relatively easy to manage.

```text
Title
Author
Date
Body
Category
```

Text is:

* Small
* Compressible
* Searchable
* Structured
* Cheap to store
* Cheap to transfer

Images are fundamentally different.

An image is not merely:

```text
Data
```

An image is:

```text
Large Binary Data
```

and large binary data introduces an entirely different class of engineering problems:

```text
Storage

Bandwidth

Compression

Caching

Transformation

Latency

Distribution

Cost
```

This is why image handling has become one of the largest engineering challenges on the modern web.

---

# The Beginner Mental Model

Most beginners imagine images like this:

```text
Website Folder

/images
    logo.png
    hero.jpg
    avatar.jpg
```

The application simply loads:

```html
<img src="/images/hero.jpg" />
```

This works for small websites.

Unfortunately, modern applications operate under very different constraints.

Consider a single uploaded image:

```text
hero-photo.jpg
```

Immediately, numerous questions appear:

```text
Is the user on mobile?

Is the user on desktop?

Does the device support WebP?

Does the device support AVIF?

Should the image be compressed?

Should it be cropped?

Should it be cached?

Should it be lazy loaded?

Which continent is the user in?
```

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
Transformations
    +
Caching
    +
Distribution
```

---

# Why Databases Rarely Store Images

When developers first encounter file uploads, they often imagine:

```text
Database
      ↓
Everything
```

After all, databases already store:

```text
Users

Posts

Comments

Orders

Products
```

Why not images?

Because databases are optimized for:

```text
Structured Data
```

Large binary assets introduce serious problems:

```text
Large backups

Slow replication

Expensive storage

Poor query performance

Increased operational complexity
```

Instead, modern systems separate:

```text
Structured Data
           +
Binary Data
```

This separation is one of the most important architectural patterns in modern software.

---

# The Modern Asset Architecture

Most modern applications follow an architecture similar to this:

```text
Application Database
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
Post

title:
"Understanding React"

heroImage:
"image-abc123"
```

The database stores only:

```text
Reference
```

while the actual image exists elsewhere.

---

# Images Become References

Suppose an editor uploads:

```text
react-architecture.png
```

Many beginners imagine:

```text
Post
     ↓
Contains Image
```

But modern systems work differently.

The uploaded image becomes:

```text
Binary Asset
        ↓
Object Storage
```

while the post stores:

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

Notice something important:

```text
The image itself
never exists
inside the post.
```

Instead:

```text
Post
     ↓
Reference
     ↓
Asset Store
```

This pattern appears everywhere:

```text
Relational Databases

Object Storage

CDNs

Graph Databases

Cloud Systems
```

Modern software is largely the management of relationships between systems.

---

# Adding Hero Images

Update:

```text
studio/schemaTypes/post.ts
```

Add:

```typescript
defineField({
  name: "heroImage",

  title: "Hero Image",

  type: "image",

  options: {
    hotspot: true,
  },
});
```

This introduces one of the most powerful concepts in content management systems:

```text
Editorial Metadata
```

---

# What Is a Hotspot?

Suppose an editor uploads:

```text
Landscape Photo
```

```text
+----------------------------------+
|                                  |
|           PERSON                 |
|                                  |
+----------------------------------+
```

Later, we need to generate:

```text
Desktop Banner

Tablet Card

Mobile Thumbnail
```

Without additional information:

```text
Crop
     ↓
Random Result
```

The important content may disappear.

Instead, editors specify:

```text
Focus Point
```

```text
+----------------------------------+
|                                  |
|           (X) PERSON             |
|                                  |
+----------------------------------+
```

Now image processing systems can preserve:

```text
Human Intent
```

during automatic transformations.

This is a beautiful example of:

```text
Human Knowledge
        +
Machine Automation
```

working together.

---

# Object Storage

Modern applications rarely use traditional file systems.

Instead, they use:

```text
Object Storage
```

Examples include:

* Amazon S3
* Google Cloud Storage
* Cloudflare R2
* Azure Blob Storage
* Sanity Asset Store

Traditional file systems organize data like this:

```text
folder/
    image.jpg
```

Object storage organizes data like this:

```text
Unique Identifier
          ↓
      Binary Object
```

For example:

```text
asset-4f9ac1e8
          ↓
hero-image.jpg
```

Object storage provides:

```text
Massive Scale

Replication

Durability

Versioning

Global Distribution

Low Cost
```

This architecture allows systems to store billions of objects efficiently.

---

# Installing the Image Builder

Install the image URL builder:

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

At first glance, this appears to be a simple utility.

In reality, it introduces one of the deepest ideas in modern web engineering.

---

# Images Become Functions

Historically:

```text
Image
     =
File
```

Modern systems think differently:

```text
Image
     =
Original Asset
             +
Transformation Function
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
Apply Operations
         ↓
Generate Variant
```

This means:

```text
Image
      =
Function(Image)
```

The same original asset can produce:

```text
Desktop Version

Mobile Version

Thumbnail

Preview

Avatar

Banner
```

without storing multiple files.

---

# Rendering Images in Next.js

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
        w-full
        rounded-xl
        object-cover
      "
    />
  );
}
```

The component appears simple.

Underneath, however, an enormous amount of infrastructure is working on our behalf.

---

# The Modern Image Pipeline

Suppose an editor uploads:

```text
8000 × 6000 JPEG
```

The actual processing pipeline resembles:

```text
Editor Upload
        ↓
Object Storage
        ↓
Metadata Extraction
        ↓
Asset Reference
        ↓
Image Request
        ↓
Transformation Service
        ↓
Resize
        ↓
Crop
        ↓
Compress
        ↓
Format Conversion
        ↓
CDN Cache
        ↓
Browser
```

This entire pipeline exists to answer one question:

> What is the smallest possible image that still looks good?

---

# Why Optimization Matters

Consider an uploaded image:

```text
8000 × 6000
```

File size:

```text
18 MB
```

A mobile device may only require:

```text
400 × 300
```

which might be:

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

This difference affects:

* Performance
* Battery life
* Network costs
* User experience
* Carbon footprint

Image optimization is therefore not merely a performance problem.

It is an economics problem.

---

# What Does `next/image` Actually Do?

Many beginners assume:

```tsx
<Image />
```

is simply:

```tsx
<img />
```

It is not.

`next/image` provides:

```text
Responsive Images

Lazy Loading

Priority Loading

Layout Stability

Image Optimization

Caching

Browser-Specific Delivery
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
This image is critical.

Load it immediately.
```

while ordinary images remain:

```text
Lazy Loaded
```

until needed.

---

# Understanding CDNs

Suppose your application is hosted in:

```text
Singapore
```

and your user is located in:

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

Every request travels across the planet.

With a CDN:

```text
Singapore Origin
         ↓

Tokyo Edge

Sydney Edge

London Edge

Toronto Edge
```

Canadian users receive:

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

This dramatically reduces:

```text
Latency
```

which is one of the primary goals of modern distributed systems.

---

# The Internet Is Mostly Caching

One of the most surprising truths in software engineering is:

> Most of the internet exists to avoid doing work twice.

Examples include:

```text
Browser Cache

CDN Cache

DNS Cache

Redis Cache

Application Cache

Database Cache

Edge Cache
```

Much of performance engineering is actually:

```text
Cache Engineering
```

rather than:

```text
Compute Engineering
```

---

# Immutable Assets

Images have a useful property:

```text
They rarely change.
```

This allows systems to treat them as:

```text
Immutable Assets
```

For example:

```text
hero-abc123.webp
```

can safely be cached:

```text
Forever
```

because if the image changes:

```text
The filename changes.
```

This principle powers:

* CDNs
* Browser caches
* Build systems
* Package managers
* Content-addressable storage

---

# Image Delivery Is Actually a Distributed Systems Problem

At small scale:

```text
Server
     ↓
Image
```

At internet scale:

```text
Upload
      ↓
Replication
      ↓
Storage
      ↓
Transformation
      ↓
Caching
      ↓
Geographic Routing
      ↓
Edge Distribution
      ↓
Browser Rendering
```

Image delivery becomes a classic distributed systems problem involving:

```text
Latency

Availability

Consistency

Replication

Caching

Fault Tolerance
```

---

# The Deeper Pattern

Throughout this series, we have repeatedly encountered the same architectural transformation:

```text
Simple Thing
         ↓
Distributed System
```

Examples:

```text
Content
      ↓
CMS

Search
      ↓
Information Retrieval

Authentication
      ↓
Trust Management

Comments
      ↓
State Transitions

Images
      ↓
Distributed Asset Delivery
```

This pattern appears throughout modern software engineering.

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

It is a planetary-scale system optimized to move information efficiently across space, time, and uncertainty.

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

and discover one of the most important truths in software engineering:

> Software development ends when the code compiles.
>
> Software engineering begins when the software leaves your laptop.
