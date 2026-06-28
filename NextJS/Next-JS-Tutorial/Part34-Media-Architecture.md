# Next.js 16 for Absolute Beginners

# Part 34 — Rich Text Editing, Content Blocks, and Media Architecture

> **Goal of this lesson:** Build a modern content editing system for Nexus CMS using structured content blocks, rich text editing, media uploads, and server-side rendering.

---

# Why Rich Text Is Hard

Beginners think rich text looks like this:

```text
"This is my blog post."
```

In reality, modern content systems store documents like this:

```text
Document
    |
    +---- Headings
    |
    +---- Paragraphs
    |
    +---- Images
    |
    +---- Videos
    |
    +---- Quotes
    |
    +---- Code blocks
    |
    +---- Tables
```

Because content is not text.

Content is structured data.

---

# What We're Building

By the end of this chapter, we'll have:

```text
✓ Rich text editor
✓ Structured content blocks
✓ Headings
✓ Paragraphs
✓ Images
✓ Quotes
✓ Code blocks
✓ Media uploads
✓ Document rendering
✓ Serialization
✓ Validation
✓ Cache support
```

---

# Why Not Store HTML?

Many beginners try:

```html
<h1>Hello</h1>

<p>World</p>
```

This creates problems:

```text
❌ Security
❌ Validation
❌ Portability
❌ Versioning
❌ Search
❌ Transformations
```

---

# Modern CMS Architecture

Instead:

```json
{
  "type": "heading",
  "level": 1,
  "content": "Hello"
}
```

---

# Visualizing Document Architecture

```text
Document
     |
     +---- Block
     |
     +---- Block
     |
     +---- Block
```

---

# Step 1 — Create Content Block Types

Create:

```text
types/editor.ts
```

---

```ts
export interface ParagraphBlock {

  type:
    "paragraph";

  content:
    string;

}

export interface HeadingBlock {

  type:
    "heading";

  level:
    number;

  content:
    string;

}
```

---

# Add Image Blocks

```ts
export interface ImageBlock {

  type:
    "image";

  url:
    string;

  alt:
    string;

  width:
    number;

  height:
    number;

}
```

---

# Add Quote Blocks

```ts
export interface QuoteBlock {

  type:
    "quote";

  content:
    string;

  author?:
    string;

}
```

---

# Add Code Blocks

```ts
export interface CodeBlock {

  type:
    "code";

  language:
    string;

  code:
    string;

}
```

---

# Create Union Type

```ts
export type ContentBlock =

    ParagraphBlock
  | HeadingBlock
  | ImageBlock
  | QuoteBlock
  | CodeBlock;
```

---

# Visualizing Blocks

```text
Post

  Heading

  Paragraph

  Image

  Quote

  Code
```

---

# Step 2 — Update Database Model

Open:

```text
schema.prisma
```

---

```prisma
model Post {

  id String
     @id
     @default(uuid())

  title String

  content Json

}
```

---

# Why JSON?

Because:

```text
Document
      |
Flexible
      |
Structured
      |
Searchable
```

---

# Example Stored Document

```json
[
  {
    "type": "heading",
    "level": 1,
    "content": "Next.js 16"
  },

  {
    "type": "paragraph",
    "content": "Welcome."
  }
]
```

---

# Step 3 — Build Editor Component

Create:

```text
components/editor/
```

---

```tsx
"use client";

export function
Editor() {

  return (

    <textarea

      rows={20}

      cols={80}

    />

  );

}
```

---

# Wait...

This isn't a rich editor.

Correct.

---

# Why Start With a Textarea?

Because engineers build:

```text
Working
    |
Correct
    |
Beautiful
```

Not:

```text
Fancy
    |
Broken
```

---

# Step 4 — Add State

```tsx
"use client";

import {
  useState
} from "react";

export function
Editor() {

  const [

    content,

    setContent

  ] = useState("");

  return (

    <textarea

      value={
        content
      }

      onChange={
        e =>

          setContent(
            e.target
             .value
          )
      }

    />

  );

}
```

---

# Step 5 — Parse Content Blocks

Create:

```text
lib/editor.ts
```

---

```ts
export function
parseEditor(
  text: string
) {

  return text

    .split("\n")

    .filter(Boolean)

    .map(

      line => ({

        type:
          "paragraph",

        content:
          line,

      })

    );

}
```

---

# Example

Input:

```text
Hello

World
```

Output:

```json
[
  {
    "type":"paragraph",
    "content":"Hello"
  },

  {
    "type":"paragraph",
    "content":"World"
  }
]
```

---

# Step 6 — Save Structured Content

Update:

```ts
await db.post.create({

  data: {

    title,

    content:
      parseEditor(
        content
      ),

  },

});
```

---

# Visualizing Storage

```text
Editor
    |
Parse
    |
JSON
    |
Database
```

---

# Step 7 — Render Blocks

Create:

```text
components/render/
PostRenderer.tsx
```

---

```tsx
export function
PostRenderer({

  blocks,

}) {

  return (

    <>

      {blocks.map(

        (block, i) => (

          <Block

            key={i}

            block={
              block
            }

          />

        )

      )}

    </>

  );

}
```

---

# Create Block Renderer

```tsx
export function
Block({

  block,

}) {

  switch (
    block.type
  ) {

    case
      "paragraph":

      return (

        <p>

          {
            block
              .content
          }

        </p>

      );

    default:

      return null;

  }

}
```

---

# Step 8 — Render Headings

```tsx
case "heading":

  return (

    <h1>

      {
        block
          .content
      }

    </h1>

  );
```

---

# Step 9 — Render Quotes

```tsx
case "quote":

  return (

    <blockquote>

      {
        block
          .content
      }

    </blockquote>

  );
```

---

# Step 10 — Render Code

```tsx
case "code":

  return (

    <pre>

      <code>

        {
          block.code
        }

      </code>

    </pre>

  );
```

---

# Visualizing Rendering

```text
Database
    |
JSON Blocks
    |
Renderer
    |
React Components
    |
HTML
```

---

# Step 11 — Create Media Upload Model

```prisma
model Media {

  id String
     @id
     @default(uuid())

  filename String

  mimeType String

  size Int

  width Int?

  height Int?

  url String

}
```

---

# Why Store Metadata?

Because images aren't just files.

They're:

```text
File
   +
Metadata
   +
Dimensions
   +
Security
```

---

# Step 12 — Build Upload Form

```tsx
<form>

  <input

    type="file"

    name="image"

  />

</form>
```

---

# Upload Flow

```text
Browser
   |
File
   |
Server
   |
Storage
   |
Database
```

---

# Step 13 — Validate Uploads

```ts
if (

  file.size >

  5_000_000

)

  throw Error(
    "Too large"
  );
```

---

# Validate MIME Types

```ts
const allowed = [

  "image/png",

  "image/jpeg",

  "image/webp",

];
```

---

# Why Validate?

Because attackers upload:

```text
virus.exe
```

and rename it:

```text
cat.jpg
```

---

# Step 14 — Render Images

```tsx
import Image
  from "next/image";

case "image":

  return (

    <Image

      src={
        block.url
      }

      alt={
        block.alt
      }

      width={
        block.width
      }

      height={
        block.height
      }

    />

  );
```

---

# Why Use Next Image?

Benefits:

```text
✓ Optimization

✓ Compression

✓ Responsive

✓ Lazy loading

✓ Caching
```

---

# Step 15 — Cache Documents

Create:

```ts
import {

  cacheTag,

  cacheLife,

} from
  "next/cache";

export async function
getPost(
  slug: string
) {

  "use cache";

  cacheTag(
    `post:${slug}`
  );

  cacheLife(
    "hours"
  );

  return db.post
    .findUnique({

      where: {
        slug,
      },

    });

}
```

---

# Visualizing Cache

```text
Request
    |
Cache
    |
Database
```

---

# Invalidate Cache

```ts
revalidateTag(
  `post:${slug}`
);
```

---

# Final Document Architecture

```text
Editor
    |
Blocks
    |
JSON
    |
Database
    |
Cache
    |
Renderer
    |
HTML
```

---

# Why Modern CMS Systems Use Blocks

Examples:

```text
Notion

Sanity

Contentful

Portable Text

Editor.js

Lexical

Slate
```

All use:

```text
Structured content.
```

---

# What We've Built

```text
✓ Rich text

✓ Content blocks

✓ JSON documents

✓ Rendering

✓ Images

✓ Quotes

✓ Code blocks

✓ Uploads

✓ Validation

✓ Cache Components
```

---

# Content Architecture Philosophy

Beginners think:

```text
Content
    =
String
```

Professionals think:

```text
Content
    =
Structured Document
```

Because documents evolve.

Strings don't.

---

# Exercises

## Exercise 1

Add:

```text
VideoBlock
```

support.

---

## Exercise 2

Add:

```text
TableBlock
```

support.

---

## Exercise 3

Add:

```text
EmbedBlock
```

for YouTube.

---

## Exercise 4

Add:

```text
CalloutBlock
```

like Notion.

---

# Mental Model

Beginners build:

```text
Text editors.
```

Professional engineers build:

```text
Document systems.
```

Because content management isn't about editing text.

It's about modeling human knowledge.

---

# Part 35 Preview

In the next chapter we'll begin the most important Next.js 16 topic:

# Cache Components and the New Caching Architecture

Including:

```text
✓ cacheComponents
✓ "use cache"
✓ cacheLife()
✓ cacheTag()
✓ Dynamic rendering
✓ Partial prerendering
✓ Cache boundaries
✓ Cache invalidation
✓ Revalidation
✓ Performance engineering
```

This is where Next.js becomes a performance engineering framework.
