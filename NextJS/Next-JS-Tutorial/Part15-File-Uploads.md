# Next.js 16 for Absolute Beginners

# Part 15 — File Uploads, Images, and Media: Handling Real User Content

> **Goal of this lesson:** Learn how to upload files, process images, store media, optimize images, and build production-ready media workflows in Next.js 16.

---

# Until Now, We've Only Worked With Text

Most of our examples have looked like this:

```text
Users
Posts
Comments
Products
```

But real applications contain:

```text
Profile Photos
Blog Images
Product Images
Videos
PDFs
Attachments
Documents
Audio Files
```

Eventually, every serious application becomes a media application.

---

# Why File Uploads Are Difficult

Text is easy.

```text
{
    "name": "Sean"
}
```

Images are different.

A photo might be:

```text
5 MB
20 MB
50 MB
```

Videos might be:

```text
500 MB
5 GB
```

This creates problems:

* large uploads
* slow networks
* storage costs
* security risks
* image optimization
* caching
* CDN distribution

---

# How File Uploads Work

Suppose a user uploads:

```text
avatar.jpg
```

The flow looks like:

```text
Browser
     |
Upload File
     |
Server
     |
Storage
     |
Database
     |
Return URL
```

---

# HTML Already Supports File Uploads

Basic upload:

```html
<form>

    <input
        type="file"
        name="image"
    />

    <button>
        Upload
    </button>

</form>
```

---

# Visualizing File Uploads

```text
User Selects File
          |
          V

Browser Creates FormData
          |
          V

HTTP Request
          |
          V

Server Receives File
```

---

# Next.js Forms Support Files Naturally

Example:

```tsx
<form action={uploadImage}>

    <input
        type="file"
        name="image"
    />

    <button>
        Upload
    </button>

</form>
```

---

# Server Action Upload

```tsx
"use server";

export async function uploadImage(
    formData: FormData
) {

    const file =
        formData.get(
            "image"
        ) as File;

    console.log(
        file.name
    );

}
```

---

# What Is File?

A browser file object contains:

```text
name
type
size
lastModified
data
```

Example:

```tsx
console.log(file.name);

console.log(file.type);

console.log(file.size);
```

Output:

```text
avatar.jpg

image/jpeg

523123
```

---

# Reading File Data

Convert file contents:

```tsx
const bytes =
    await file.arrayBuffer();
```

Convert to Node buffer:

```tsx
const buffer =
    Buffer.from(bytes);
```

---

# Visualizing File Processing

```text
File
   |
arrayBuffer()
   |
Buffer
   |
Save
```

---

# Saving Files Locally

Example:

```tsx
"use server";

import fs
    from "fs/promises";

export async function upload(
    formData: FormData
) {

    const file =
        formData.get(
            "image"
        ) as File;

    const bytes =
        await file.arrayBuffer();

    const buffer =
        Buffer.from(bytes);

    await fs.writeFile(
        `./uploads/${file.name}`,
        buffer
    );

}
```

---

# Project Structure

```text
project/

    uploads/

        photo.jpg
```

---

# Why Local Storage Is Usually Wrong

This works:

```text
Server
    |
    +--- uploads/
```

But production servers:

```text
Restart
Redeploy
Autoscale
```

can delete files.

---

# Production Architecture

Instead:

```text
Browser
     |
Upload
     |
Storage Service
     |
Database
```

Examples:

```text
AWS S3
Cloudflare R2
Google Cloud Storage
Azure Blob Storage
```

---

# Visualizing Cloud Storage

```text
Next.js
     |
Database
     |
Image URL
     |
Cloud Storage
```

---

# Database Storage Pattern

Never store:

```text
5 MB image
```

inside your database.

Store:

```text
https://cdn.example.com/avatar.jpg
```

instead.

Example:

```prisma
model Image {

    id Int
        @id
        @default(autoincrement())

    url String

    filename String

    createdAt DateTime
        @default(now())

}
```

---

# Upload Validation

Never trust uploaded files.

Bad:

```tsx
await save(file);
```

Good:

```tsx
if (
    file.size >
    5000000
) {

    throw new Error(
        "File too large"
    );

}
```

---

# Validating File Types

Example:

```tsx
const allowed = [

    "image/png",

    "image/jpeg",

    "image/webp",

];

if (
    !allowed.includes(
        file.type
    )
) {

    throw new Error(
        "Invalid file"
    );

}
```

---

# Visualizing Validation

```text
File
   |
Validate Size
   |
Validate Type
   |
Save
```

---

# Multiple File Uploads

HTML:

```tsx
<input
    type="file"
    multiple
    name="photos"
/>
```

---

Server:

```tsx
const files =
    formData.getAll(
        "photos"
    );
```

---

Process:

```tsx
for (
    const file of files
) {

    console.log(
        file
    );

}
```

---

# Visualizing Multiple Uploads

```text
photo1.jpg
photo2.jpg
photo3.jpg
        |
        V
Loop
        |
        V
Save
```

---

# The Next.js Image Component

Images are expensive.

A raw image:

```text
4000 × 3000
15 MB
```

is terrible for users.

Next.js provides:

```tsx
import Image
    from "next/image";
```

---

# Basic Example

```tsx
import Image
    from "next/image";

export default function Page() {

    return (

        <Image
            src="/cat.jpg"
            alt="Cat"
            width={400}
            height={300}
        />

    );

}
```

---

# What Does Image Actually Do?

Instead of:

```text
Original Image
```

Next.js automatically:

```text
Resize
Optimize
Compress
Lazy Load
Cache
Serve Modern Formats
```

---

# Visualizing Image Optimization

```text
Original
   |
Optimize
   |
Resize
   |
Compress
   |
Browser
```

---

# Example HTML Image

```tsx
<img
    src="/photo.jpg"
/>
```

Problems:

```text
No optimization
No lazy loading
No compression
```

---

# Example Next.js Image

```tsx
<Image
    src="/photo.jpg"
    alt=""
    width={800}
    height={600}
/>
```

Benefits:

```text
✓ optimized
✓ lazy loaded
✓ responsive
✓ cached
```

---

# Responsive Images

Example:

```tsx
<Image
    src="/hero.jpg"
    alt=""
    fill
    sizes="
        (max-width:768px)
        100vw,
        50vw
    "
/>
```

---

# Visualizing Responsive Images

```text
Phone
   |
Small Image

Desktop
   |
Large Image
```

---

# Lazy Loading

Suppose a page has:

```text
100 images
```

Without lazy loading:

```text
Load 100 images
```

Bad.

With lazy loading:

```text
Load visible images only
```

---

# Visualizing Lazy Loading

```text
Screen
   |
Image 1  -> loaded
Image 2  -> loaded
Image 3  -> loaded
Image 40 -> waiting
Image 80 -> waiting
```

---

# Remote Images

Suppose images live on:

```text
cdn.example.com
```

Configure:

```js
// next.config.ts

export default {

    images: {

        remotePatterns: [

            {
                protocol:
                    "https",

                hostname:
                    "cdn.example.com",
            },

        ],

    },

};
```

---

# Example

```tsx
<Image
    src="https://cdn.example.com/photo.jpg"
    alt=""
    width={500}
    height={300}
/>
```

---

# Image Placeholders

Large images can feel slow.

Use:

```tsx
<Image
    src="/hero.jpg"
    alt=""
    width={500}
    height={300}
    placeholder="blur"
    blurDataURL="..."
/>
```

---

# Visualizing Blur Placeholders

```text
Blurred Image
        |
        V
Full Image
```

---

# Drag and Drop Uploads

Modern applications support:

```text
Drag File
      |
      V
Drop Zone
      |
      V
Upload
```

---

# Example

```tsx
"use client";

export default function Dropzone() {

    function handleDrop(
        event: DragEvent
    ) {

        event.preventDefault();

        const files =
            event.dataTransfer
                ?.files;

        console.log(
            files
        );
    }

    return (

        <div
            onDrop={handleDrop}
            onDragOver={
                e =>
                    e.preventDefault()
            }
        >

            Drop files here

        </div>

    );

}
```

---

# Upload Progress

Users hate uncertainty.

Bad:

```text
Uploading...
```

Better:

```text
63%
```

---

# Visualizing Progress

```text
0%
25%
50%
75%
100%
```

---

# Image Galleries

Suppose we store:

```prisma
model Image {

    id Int
        @id
        @default(autoincrement())

    url String

    title String

}
```

Fetch:

```tsx
const images =
    await db.image.findMany();
```

---

Render:

```tsx
<div>

    {
        images.map(
            image => (

                <Image
                    key={image.id}
                    src={image.url}
                    alt=""
                    width={300}
                    height={200}
                />

            )
        )
    }

</div>
```

---

# Caching Images

Remember Next.js 16 cache components.

Example:

```tsx
export async function getImages() {

    "use cache";

    cacheLife("hours");

    cacheTag(
        "images"
    );

    return db.image.findMany();

}
```

---

# After Uploading

Invalidate:

```tsx
"use server";

import {
    revalidateTag
} from "next/cache";

export async function upload() {

    await save();

    revalidateTag(
        "images"
    );

}
```

---

# Visualizing Full Upload Flow

```text
Upload
    |
Store File
    |
Store Metadata
    |
Invalidate Cache
    |
Refresh Gallery
```

---

# Security Checklist

Always:

```text
✓ Validate size
✓ Validate type
✓ Generate unique filenames
✓ Scan uploads
✓ Limit upload count
✓ Restrict permissions
✓ Store URLs only
```

Never:

```text
✗ Trust file extensions
✗ Trust filenames
✗ Store giant blobs in databases
✗ Allow unlimited uploads
```

---

# Professional Folder Structure

```text
app/

    gallery/

    upload/

    actions/

components/

    UploadForm.tsx
    Gallery.tsx
    ImageCard.tsx

lib/

    storage.ts
    images.ts
    uploads.ts
```

---

# The Professional Rule

Don't think:

```text
Upload file
```

Think:

```text
Validate
     |
Store
     |
Persist Metadata
     |
Invalidate Cache
     |
Optimize Delivery
```

---

# Exercises

## Exercise 1

Build:

```text
Profile Photo Upload
```

with:

* file validation
* size validation
* image preview

---

## Exercise 2

Create:

```text
Image Gallery
```

using:

```tsx
<Image />
```

---

## Exercise 3

Add:

```tsx
"use cache";
cacheTag("images");
cacheLife("hours");
```

to:

```tsx
getImages()
```

---

## Exercise 4

Add:

```tsx
revalidateTag(
    "images"
);
```

after uploading.

---

# What You've Learned

You now understand:

✅ file uploads

✅ multipart forms

✅ file validation

✅ cloud storage architecture

✅ image optimization

✅ the Image component

✅ responsive images

✅ lazy loading

✅ galleries

✅ media pipelines

---

# Mental Model

Don't think:

```text
File
    |
Server
```

Think:

```text
File
    |
Validation
    |
Storage
    |
Database Metadata
    |
Cache Invalidation
    |
Optimized Delivery
```

This architecture powers nearly every modern application that handles user-generated content.

---

# Part 16 Preview

In the next chapter we'll learn:

# Loading UI, Error Handling, and Streaming

Including:

* `loading.tsx`
* `error.tsx`
* `not-found.tsx`
* React Suspense
* streaming UI
* skeleton screens
* graceful failures
* retry mechanisms
* production resilience

This is where our applications start feeling truly professional.
