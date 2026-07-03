# GreyMatter Journal

# Part 22 — Images, Object Storage, CDNs, and Why the Internet Is Really a Global Content Delivery System

> **Goal of this lesson:** Add images to GreyMatter Journal while learning how binary data works, why databases don't store most files directly, how CDNs function, what image optimization actually does, and why the modern internet is fundamentally a giant distributed caching system.

---

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

Professional blogs look like:

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

---

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

Unfortunately, this becomes a disaster very quickly.

---

# Why Databases Hate Large Files

Suppose:

```text
Article:
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

which databases are not optimized for.

---

# Modern Architecture

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

---

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

Image:

```text
Photo
```

also becomes:

```text
01010101
11001010
...
```

The difference is simply:

```text
Interpretation
```

---

# Step 1 — Add A Hero Image

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

---

# Wait...

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

Hotspots allow editors to specify:

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

---

# Step 2 — Update The Query

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

---

# Step 3 — Install The Image Library

Open terminal:

```bash
npm install @sanity/image-url
```

---

# Why Another Library?

Suppose Sanity stores:

```json
{
  "_type": "image",
  "asset": {
    "_ref":
      "image-abc123"
  }
}
```

This is not an image URL.

Instead, it is:

```text
Image Metadata
```

We need a translator.

---

# Step 4 — Create The Image Builder

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
  source: unknown
) {
  return builder.image(
    source
  );
}
```

---

# Wait...

What Is A Builder?

Builders are objects that progressively construct something.

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

---

# Step 5 — Render The Image

Open:

```text
components/PostCard.tsx
```

Import:

```typescript
import Image
  from "next/image";

import {
  urlFor,
} from "@/lib/image";
```

Add:

```tsx
{
  post.heroImage && (
    <Image
      src={
        urlFor(
          post.heroImage
        )
          .width(800)
          .height(400)
          .url()
      }
      alt={post.title}
      width={800}
      height={400}
    />
  );
}
```

---

# Wait...

Why Use `<Image>` Instead Of `<img>`?

Traditional HTML:

```html
<img
  src="image.jpg"
/>
```

Modern Next.js:

```tsx
<Image />
```

because Next.js performs:

```text
Optimization
Caching
Compression
Resizing
Lazy Loading
```

automatically.

---

# What Is Image Optimization?

Suppose you upload:

```text
4000×3000
10 MB
```

But mobile users need:

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

---

# The Browser Never Needs The Original

Desktop:

```text
1200px
```

Tablet:

```text
800px
```

Mobile:

```text
400px
```

Why send:

```text
4000px
```

to everyone?

---

# Step 6 — Add Responsive Images

Update:

```tsx
<Image
  src={imageUrl}
  alt={post.title}
  width={1200}
  height={600}
  sizes="
    (max-width:768px)
    100vw,
    800px
  "
/>
```

---

# Wait...

What Is `sizes`?

It tells browsers:

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

Then browsers download:

```text
Only what's needed.
```

---

# What Is A CDN?

Suppose your server lives in:

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

every request.

Slow.

---

# With A CDN

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

---

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

---

# Example

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

---

# Sanity Uses A CDN

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

---

# Wait...

Haven't We Seen This Before?

Yes.

Remember:

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

---

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

---

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

Caching exploits this asymmetry.

---

# Image Transformation Pipelines

When you request:

```typescript
urlFor(image)
  .width(800)
  .height(400)
  .format("webp")
```

Sanity performs:

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

---

# What Is WebP?

Traditional:

```text
JPEG
PNG
```

Modern:

```text
WebP
AVIF
```

Benefits:

```text
Same Quality

Smaller Files
```

Example:

```text
JPEG:
500 KB

WebP:
180 KB
```

---

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

download initially.

---

# The Hidden Architecture

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

---

# Wait...

Does This Look Familiar?

We've already seen:

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

---

# The Deep Secret Of The Internet

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

Questions become:

```text
Where is the content?

Who has a copy?

How fresh is it?

Who serves it?

How quickly?
```

---

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

Once you understand this, CDNs, caching, databases, object storage, AI vector stores, and distributed systems begin to look like variations of the same underlying architecture.

---

# Up Next

In **Part 23**, we'll deploy GreyMatter Journal to production while learning:

* build pipelines,
* CI/CD,
* environment promotion,
* edge networks,
* infrastructure as code,
* and why modern software engineering is fundamentally the discipline of turning source code into running systems.
