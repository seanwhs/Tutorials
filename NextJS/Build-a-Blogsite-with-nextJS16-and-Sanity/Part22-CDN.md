# GreyMatter Journal

# Part 22 — Images, Object Storage, CDNs, and Why the Internet Is Really a Global Content Delivery System

> **Goal of this lesson:** Add images to GreyMatter Journal while learning how binary data works, why databases don't store most files directly, how CDNs function, what image optimization actually does, and why the modern internet is fundamentally a giant distributed caching system.

***

# Our Blog Has Another Problem

Right now our articles look like:

```text
Title

Author

Date

Text
Text
Text
Text
```

Professional blogs look more like:

```text
Hero Image

Title

Author

Content

Images
Galleries
Media
```

To build this, we need to answer a deceptively simple question:

> Where do images actually live?

***

# The Beginner Mental Model

Most beginners imagine:

```text
Browser
    │
    ▼
Database
    │
    ▼
Image
```

Something like:

```sql
id | title | image
------------------
1  | React | photo.jpg
```

This model works for tiny projects, but becomes a disaster very quickly.

***

# Why Databases Hate Large Files

Suppose:

```text
Article text:
10 KB
```

Image:

```text
5 MB
```

Now imagine:

```text
1000 articles
```

Diagram:

```text
Text:
10 MB

Images:
5000 MB
```

Suddenly:

```text
Database
        =
File Server
```

Relational databases and document stores are optimized for **structured data**, not for storing and streaming gigabytes of binary blobs.

***

# Modern Architecture: Split Data and Files

Instead, modern systems separate:

```text
Structured Data

and

Binary Data
```

Diagram:

```text
Database
     │
     └── Metadata

Storage
     │
     └── Files
```

Example:

```json
{
  "title": "React",
  "image": "https://cdn.example.com/image.jpg"
}
```

The database stores **pointers** (URLs, keys, IDs); the actual bytes live in object storage or on a CDN.

***

# What Is Binary Data?

Everything on computers eventually becomes:

```text
0
1
0
1
0
1
```

Text:

```text
Hello
```

becomes:

```text
01001000
01100101
...
```

An image:

```text
Photo
```

also becomes:

```text
01010101
11001010
...
```

The difference isn’t the bits—it’s the:

```text
Interpretation
```

Text is interpreted as characters; images as pixels; audio as samples. The storage is generic; the meaning comes from how we decode it.

***

# Step 1 — Add a Hero Image

Open:

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

This gives each post a dedicated “hero” image field, stored as an image asset reference rather than a raw URL.

***

# Wait…

What Is `hotspot`?

Suppose we upload:

```text
Person Standing
```

Image:

```text
+----------------+
|                |
|      😀        |
|                |
+----------------+
```

When the image becomes:

```text
Mobile Size
```

the system needs to know:

```text
What part is important?
```

Hotspots allow editors to specify a:

```text
Focus Area
```

Diagram:

```text
Image

+----------------+

        ●

+----------------+

        ▲

     Keep This
```

When the image is cropped or resized, the hotspot guides which region should remain visible.

***

# Step 2 — Update the Query

Open:

```text
lib/queries.ts
```

Update:

```typescript
export const POSTS_QUERY = `
  *[_type == "post"]{
    _id,
    title,
    slug,
    excerpt,
    heroImage,
    author->{
      name
    }
  }
`;
```

Now our frontend has access to the `heroImage` field alongside the rest of the post metadata.

***

# Step 3 — Install the Image Library

In your terminal:

```bash
npm install @sanity/image-url
```

This helper library knows how to turn Sanity’s image references into real URLs with transformations applied.

***

# Why Another Library?

Suppose Sanity stores:

```json
{
  "_type": "image",
  "asset": {
    "_ref": "image-abc123"
  }
}
```

This is **not** a direct URL.

Instead, it is:

```text
Image Metadata
```

We need a translator that understands:

- which project and dataset to use,
- how to derive a URL from the asset ref,
- how to add parameters for resizing, cropping, and formats.

***

# Step 4 — Create the Image Builder

Create:

```text
lib/image.ts
```

Add:

```typescript
import imageUrlBuilder from "@sanity/image-url";
import { client } from "./sanity";

const builder = imageUrlBuilder(client);

export function urlFor(source: unknown) {
  return builder.image(source);
}
```

Now `urlFor(image)` returns a builder object that can produce optimized URLs.

***

# Wait…

What Is a Builder?

A builder is an object that progressively constructs something.

Example:

```typescript
urlFor(image)
  .width(800)
  .height(400)
  .url();
```

Diagram:

```text
Image
   │
   ▼

Builder

   │

   ├── Width
   ├── Height
   └── Format

   ▼

URL
```

Instead of manually concatenating query parameters, you compose transformations fluently and let the builder generate the correct URL.

***

# Step 5 — Render the Image

Open:

```text
components/PostCard.tsx
```

Import:

```typescript
import Image from "next/image";
import { urlFor } from "@/lib/image";
```

Add:

```tsx
{post.heroImage && (
  <Image
    src={urlFor(post.heroImage).width(800).height(400).url()}
    alt={post.title}
    width={800}
    height={400}
  />
)}
```

Now each post card displays a properly sized hero image with alt text for accessibility.

***

# Why Use `<Image>` Instead of `<img>`?

Traditional HTML:

```html
<img src="image.jpg" />
```

Modern Next.js:

```tsx
<Image />
```

because `<Image>` performs:

```text
Optimization
Caching
Compression
Resizing
Lazy Loading
```

automatically.

It integrates with Next.js’ image optimization pipeline so you get responsive, efficient images without writing your own transformation service.

***

# What Is Image Optimization?

Suppose you upload:

```text
4000×3000
10 MB
```

But mobile users only need:

```text
400×300
50 KB
```

Without optimization:

```text
Download:
10 MB
```

With optimization:

```text
Download:
50 KB
```

Diagram:

```text
Original
    │
    ▼

Resize

    │
    ▼

Compress

    │
    ▼

Deliver
```

The user sees the same image *visually*, but the network download is dramatically smaller.

***

# The Browser Never Needs the Original

Display sizes:

```text
Desktop:
1200px

Tablet:
800px

Mobile:
400px
```

Why send:

```text
4000px
```

to everyone?

Instead, we generate variants tailored to each viewport and device.

***

# Step 6 — Add Responsive Images

Update your image component:

```tsx
<Image
  src={imageUrl}
  alt={post.title}
  width={1200}
  height={600}
  sizes="(max-width: 768px) 100vw, 800px"
/>
```

This tells the browser:

- On small screens, the image should occupy the full viewport width (`100vw`).
- On larger screens, it will be about `800px` wide.

The browser can then choose the most appropriate image variant to download.

***

# What Is `sizes`?

`sizes` tells browsers:

```text
How large
the image
will appear.
```

Diagram:

```text
Mobile
   │
   ▼
100vw

Desktop
   │
   ▼
800px
```

Armed with `sizes` and `srcset`, the browser can download:

```text
Only what's needed.
```

No more 4K images for tiny phone screens.

***

# What Is a CDN?

Suppose your origin server lives in:

```text
Singapore
```

User:

```text
Brazil
```

Without a CDN:

```text
Brazil
   │
   ▼

Singapore
```

for every request.

Latency is high and bandwidth cross-continent.

***

# With a CDN

Diagram:

```text
User
   │
   ▼

Local CDN

   │

   ▼

Origin Server
```

Now:

```text
Brazil User
        │
        ▼

Brazil Cache
```

The first user in a region may hit the origin; subsequent users are served from nearby cache nodes.

***

# What Does CDN Mean?

CDN stands for:

```text
Content
Delivery
Network
```

Think:

```text
Thousands of tiny caches
around the planet.
```

It’s a geographically distributed layer whose only job is to deliver content quickly and cheaply.

***

# Example: With vs Without CDN

Without CDN:

```text
Singapore
      │
      ▼
Australia

Singapore
      │
      ▼
Brazil

Singapore
      │
      ▼
Europe
```

With CDN:

```text
Australia Cache

Brazil Cache

Europe Cache
```

Content fans out from the origin once, then fans out again from regional caches.

***

# Sanity Uses a CDN

When we configure:

```typescript
useCdn: true
```

we are saying:

```text
Use Cached Copies
```

Diagram:

```text
Browser
    │
    ▼

CDN
    │
    ▼

Sanity
```

Sanity’s CDN front-ends their APIs and image servers so most reads never touch the origin directly.

***

# Wait…

Haven’t We Seen This Before?

Yes.

Earlier, in Draft Mode, we saw:

```text
Draft Mode
        ↓
Disable Cache
```

because:

```text
Cache
      =
Potentially Stale Reality
```

Preview needs freshness; published sites can trade some freshness for speed.

***

# The Internet Is Mostly Caching

Most beginners imagine:

```text
User
   │
   ▼
Server
```

Reality:

```text
Browser Cache

CDN Cache

Server Cache

Database Cache

Filesystem Cache
```

Diagram:

```text
User

  │

Browser Cache

  │

CDN Cache

  │

Server Cache

  │

Database
```

Every layer tries to avoid recomputing or refetching data that it can cheaply reuse.

***

# Why Does This Work?

Because:

```text
Most data
does not
change often.
```

Example:

```text
React Logo

Downloaded:
10 million times

Uploaded:
1 time
```

Caching exploits this asymmetry: many reads, very few writes.

***

# Image Transformation Pipelines

When you request:

```typescript
urlFor(image)
  .width(800)
  .height(400)
  .format("webp")
```

the pipeline is:

```text
Original Image
       │
       ▼

Resize
       │
       ▼

Crop
       │
       ▼

Compress
       │
       ▼

Convert Format
       │
       ▼

Cache
       │
       ▼

Deliver
```

Once generated, the transformed image is cached, so the expensive work happens only once per variant.

***

# What Is WebP?

Traditional formats:

```text
JPEG
PNG
```

Modern formats:

```text
WebP
AVIF
```

Benefits:

```text
Same Visual Quality

Smaller Files
```

Example:

```text
JPEG:
500 KB

WebP:
180 KB
```

Modern browsers support these newer formats, so they become the default choice for optimized delivery.

***

# Lazy Loading

Suppose a page contains:

```text
50 images
```

Should browsers download:

```text
50 images immediately?
```

No.

Instead:

```text
Load Only Visible Images
```

Diagram:

```text
Screen

Image 1
Image 2
Image 3

---------

Image 20
Image 21
Image 22
```

Only:

```text
1
2
3
```

download initially; others load as the user scrolls. This saves bandwidth and speeds up first render.

***

# The Hidden Architecture of an Image

When a browser requests an image:

```text
Browser
    │
    ▼

Next.js Image

    │
    ▼

Sanity CDN

    │
    ▼

Image Pipeline

    │
    ▼

Cache

    │
    ▼

Optimized Image

    │
    ▼

Browser
```

What looks like “an image tag in HTML” is actually a pipeline of transforms, caches, and distributed systems working together.

***

# Cache Trees

We’ve already seen:

```text
Route Trees

Failure Trees

Reality Trees

Trust Trees

State Trees
```

Now we discover:

```text
Cache Trees
```

because the internet itself is essentially:

```text
Layers
of
cached realities.
```

Each layer stores its own partial view of the truth, with its own freshness rules.

***

# The Deep Secret of the Internet

Most beginners think:

```text
Internet
        =
Connected Computers
```

Professional engineers think:

```text
Internet
        =
Distributed
        Content
        Delivery
        System
```

Core questions:

```text
Where is the content?

Who has a copy?

How fresh is it?

Who serves it?

How quickly?
```

Everything from HTML to images to AI model weights gets delivered through this lens.

***

# Mental Model To Remember Forever

Beginners think:

```text
Images
      =
Files
```

Professional engineers think:

```text
Images
      =
Distributed
      Binary
      Data
      Pipelines
```

Or more generally:

```text
Modern Systems
              =
Machines
              For
              Moving
              Information
              Efficiently
```

Once you understand this, CDNs, caching, databases, object storage, AI vector stores, and distributed systems all start to look like variations of the same underlying architecture.

***

# Up Next

In **Part 23**, we’ll deploy GreyMatter Journal to production while exploring:

- build pipelines,
- CI/CD,
- environment promotion,
- edge networks,
- infrastructure as code,

and why modern software engineering is fundamentally the discipline of turning source code into running systems.
