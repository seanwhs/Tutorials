# Next.js 16 for Absolute Beginners

# Part 38 — File Uploads, Storage, Images, and Asset Pipelines

> **Goal of this lesson:** Build a production-grade file upload and media management system using Next.js 16, Server Actions, file validation, image optimization, object storage, and asset pipelines.

---

# Beginners Think Files Are Simple

Most beginners think:

```text
User
   |
Upload
   |
Save File
```

Unfortunately, real systems look more like this:

```text
User
   |
Validation
   |
Security Scan
   |
Metadata Extraction
   |
Storage
   |
CDN
   |
Optimization
   |
Caching
   |
Delivery
```

Because files are one of the largest attack surfaces in any application.

---

# What We're Building

By the end of this chapter, we'll have:

```text
✓ File uploads
✓ Image uploads
✓ File validation
✓ MIME checking
✓ Metadata extraction
✓ Object storage
✓ Image optimization
✓ Asset management
✓ CDN architecture
✓ Cache invalidation
✓ Media pipelines
```

---

# Why Not Store Files In The Database?

Beginners often try:

```sql
INSERT INTO posts
(
    image
)
VALUES
(
    binary_data
)
```

This is usually a bad idea.

---

# Problems With Database Storage

```text
❌ Huge backups
❌ Slow replication
❌ Large memory usage
❌ Expensive storage
❌ Poor CDN integration
```

---

# Modern File Architecture

Instead:

```text
Database
     |
     +---- Metadata
     |
     +---- URLs
```

and:

```text
Object Storage
     |
     +---- Actual Files
```

---

# Visualizing Media Architecture

```text
Browser
    |
Upload
    |
Application
    |
Object Storage
    |
CDN
    |
User
```

---

# Step 1 — Create Media Model

Open:

```text
schema.prisma
```

---

```prisma
model Media {

  id String
     @id
     @default(uuid())

  filename String

  originalName String

  mimeType String

  size Int

  width Int?

  height Int?

  url String

  createdAt DateTime
            @default(now())

}
```

---

# Why Store Metadata?

Because media isn't just:

```text
image.jpg
```

Media contains:

```text
✓ Dimensions
✓ Size
✓ Type
✓ Owner
✓ Upload date
✓ Variants
✓ Permissions
```

---

# Step 2 — Create Upload Form

Create:

```text
app/dashboard/upload/page.tsx
```

---

```tsx
export default function
UploadPage() {

  return (

    <form
      action={
        uploadFile
      }
    >

      <input
        type="file"
        name="file"
      />

      <button>

        Upload

      </button>

    </form>

  );

}
```

---

# What Happens?

```text
Browser
    |
FormData
    |
Server Action
```

---

# Step 3 — Create Server Action

```ts
"use server";

export async function
uploadFile(

  formData:
    FormData

) {

  const file =

    formData.get(
      "file"
    ) as File;

}
```

---

# The Browser Sends

```text
multipart/form-data
```

which Next.js automatically parses.

---

# Visualizing Upload Flow

```text
Browser
    |
Multipart
    |
Server Action
    |
File Object
```

---

# Step 4 — Validate File Exists

```ts
if (!file)

  throw Error(
    "Missing file"
  );
```

---

# Step 5 — Validate Size

Example:

```ts
const MAX_SIZE =

  5 * 1024 * 1024;
```

---

```ts
if (

  file.size >
  MAX_SIZE

)

  throw Error(
    "Too large"
  );
```

---

# Why?

Because attackers upload:

```text
50 GB
```

files.

---

# Step 6 — Validate MIME Type

Allowed:

```ts
const allowed = [

  "image/png",

  "image/jpeg",

  "image/webp",

];
```

---

Validation:

```ts
if (

  !allowed.includes(
    file.type
  )

)

  throw Error(
    "Invalid file"
  );
```

---

# Why?

Attackers upload:

```text
virus.exe
```

and rename it:

```text
cute-cat.jpg
```

---

# Visualizing Validation

```text
Upload
   |
Exists?
   |
Size?
   |
Type?
   |
Accept
```

---

# Step 7 — Convert To Buffer

```ts
const bytes =

  await file
    .arrayBuffer();

const buffer =

  Buffer.from(
    bytes
  );
```

---

# Why?

Because object storage systems expect:

```text
Binary data.
```

---

# Step 8 — Save Locally

Temporary example:

```ts
import fs
  from "fs";

await fs.promises
  .writeFile(

    `uploads/${file.name}`,

    buffer

  );
```

---

# But Wait...

Local storage works only during development.

---

# Production Problem

```text
Server A
    |
uploads/

Server B
    |
uploads/
```

Files disappear.

---

# Modern Solution

Use object storage.

Examples:

```text
AWS S3

Cloudflare R2

Google Cloud Storage

Azure Blob

Vercel Blob
```

---

# Visualizing Object Storage

```text
Application
     |
     V
Object Storage
     |
     V
CDN
```

---

# Step 9 — Upload To S3

Install:

```bash
npm install @aws-sdk/client-s3
```

---

Create client:

```ts
import {

  S3Client,

} from
  "@aws-sdk/client-s3";

export const s3 =

  new S3Client({

    region:
      "us-east-1",

  });
```

---

Upload:

```ts
import {

  PutObjectCommand,

} from
  "@aws-sdk/client-s3";

await s3.send(

  new PutObjectCommand({

    Bucket:
      "uploads",

    Key:
      file.name,

    Body:
      buffer,

  })

);
```

---

# Visualizing Upload

```text
Browser
    |
Server
    |
S3
    |
CDN
```

---

# Step 10 — Save Metadata

```ts
await db.media.create({

  data: {

    filename:
      file.name,

    mimeType:
      file.type,

    size:
      file.size,

    url:
      url,

  },

});
```

---

# Why Metadata Matters

Later you can:

```text
Search

Filter

Analyze

Resize

Audit
```

---

# Step 11 — Use next/image

Never use:

```html
<img>
```

Prefer:

```tsx
import Image
  from "next/image";

<Image

  src={media.url}

  alt=""

  width={800}

  height={600}

/>
```

---

# Why next/image?

Benefits:

```text
✓ Compression
✓ Lazy loading
✓ Responsive
✓ Optimization
✓ CDN caching
✓ Format conversion
```

---

# Visualizing Optimization

```text
Original
   |
Optimize
   |
Compress
   |
Cache
   |
Deliver
```

---

# Step 12 — Responsive Images

Example:

```tsx
<Image

  src={image}

  width={1200}

  height={800}

  sizes="
    (max-width:768px)
    100vw,

    50vw
  "

/>
```

---

# Browser Behavior

Desktop:

```text
1200px image
```

Mobile:

```text
400px image
```

Saving bandwidth.

---

# Step 13 — Generate Thumbnails

Create:

```text
Original
     |
Thumbnail
     |
Small
     |
Medium
     |
Large
```

---

Example database:

```prisma
model MediaVariant {

  id String
     @id

  mediaId String

  size String

  url String
}
```

---

# Why Variants?

Because:

```text
Avatar
```

should not load:

```text
10 MB image.
```

---

# Step 14 — Asset Pipeline

Real systems do:

```text
Upload
   |
Validate
   |
Virus Scan
   |
Optimize
   |
Generate Variants
   |
Store
   |
CDN
```

---

# Example Queue

```text
User Upload
       |
       V
Upload Queue
       |
       V
Worker
       |
       V
Processing
```

---

# Step 15 — Cache Uploaded Assets

Example:

```http
Cache-Control:

public,
max-age=31536000,
immutable
```

---

# Why?

Because images rarely change.

---

# Visualizing CDN

```text
Browser
    |
CDN
    |
Origin
```

Second request:

```text
Browser
    |
CDN
```

---

# Step 16 — Delete Assets

Never:

```ts
delete file;
```

Instead:

```text
Database
     |
Delete metadata
     |
Delete storage
     |
Invalidate cache
```

---

# Visualizing Delete

```text
Media
   |
Metadata
   |
Storage
   |
CDN
```

---

# Step 17 — Secure Uploads

Never trust:

```text
filename
extension
mime
size
```

Always validate:

```text
✓ Type
✓ Size
✓ Signature
✓ Ownership
✓ Permissions
```

---

# Example Attack

User uploads:

```text
invoice.pdf.exe
```

and browser shows:

```text
invoice.pdf
```

Oops.

---

# Step 18 — Full Asset Architecture

```text
                    Browser
                        |
                     Upload
                        |
                        V
                  Server Action
                        |
                 Validation
                        |
                  Object Store
                        |
                  Asset Worker
                        |
                 Optimization
                        |
                     CDN
                        |
                     Browser
```

---

# Production Architecture

```text
User
   |
Upload
   |
API
   |
Queue
   |
Workers
   |
Storage
   |
CDN
```

---

# What We've Built

```text
✓ File uploads

✓ Validation

✓ Metadata

✓ Object storage

✓ S3

✓ Image optimization

✓ CDN

✓ Asset pipeline

✓ Variants

✓ Security
```

---

# File Upload Philosophy

Beginners think:

```text
File
    =
Blob
```

Professional engineers think:

```text
File
    =
Asset
    +
Metadata
    +
Pipeline
    +
Security
```

Because files are not data.

They are distributed systems.

---

# Exercises

## Exercise 1

Add:

```text
PDF upload support.
```

---

## Exercise 2

Generate:

```text
Thumbnail variants.
```

---

## Exercise 3

Add:

```text
Avatar uploads.
```

---

## Exercise 4

Implement:

```text
Delete media.
```

with cache invalidation.

---

# Mental Model

Beginners build:

```text
Upload forms.
```

Professional engineers build:

```text
Media platforms.
```

Because the hardest part of uploads isn't receiving files.

It's managing them forever.

---

# Part 39 Preview

In the next chapter we'll build:

# Search, Filtering, Pagination, and Query Architecture

Including:

```text
✓ Search
✓ Full-text search
✓ Filters
✓ Sorting
✓ Pagination
✓ Cursor pagination
✓ Query optimization
✓ Search indexing
✓ Facets
✓ Performance engineering
```

This is where Next.js becomes an information retrieval system.
