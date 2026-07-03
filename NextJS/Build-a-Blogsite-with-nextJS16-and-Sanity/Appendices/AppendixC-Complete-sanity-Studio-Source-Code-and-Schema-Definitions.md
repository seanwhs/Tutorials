# Appendix C — Complete Sanity Studio Source Code and Schema Definitions

> **Goal of this appendix:** Build the complete Sanity Studio powering GreyMatter Journal while learning how headless CMS systems model content, relationships, editorial workflows, and structured information.

---

# Introduction

Throughout this tutorial series, we treated Sanity as a "database for content."

This description is partially true.

However, Sanity is actually:

```text
A structured content operating system.
```

Unlike traditional CMS platforms, Sanity separates:

```text
Content
     ≠
Presentation
```

This means:

```text
Authors create content.

Developers build experiences.

Both evolve independently.
```

---

# Our Final Content Model

GreyMatter Journal contains:

```text
Author
    │
    ├── Profile
    └── Social Links

Category
    │
    └── Metadata

Post
    │
    ├── Author
    ├── Categories
    ├── Body
    ├── Images
    ├── SEO
    └── Publishing Data

Comment
    │
    ├── Author
    └── Post
```

---

# Studio Folder Structure

```text
studio/

├── sanity.config.ts
├── schemaTypes/
│
├── schemas/
│   ├── author.ts
│   ├── category.ts
│   ├── post.ts
│   ├── comment.ts
│   └── blockContent.ts
│
├── structure/
│   └── structure.ts
│
└── plugins/
```

---

# Installing Studio

Inside your project root:

```bash
npx sanity@latest init
```

Choose:

```text
Project:
Create New

Dataset:
production

Output Path:
studio

Language:
TypeScript
```

---

# Studio Configuration

Create:

```text
studio/sanity.config.ts
```

```typescript
import { defineConfig } from "sanity";
import { structureTool } from "sanity/structure";

import { schemaTypes } from "./schemaTypes";

export default defineConfig({
  name: "default",

  title: "GreyMatter Journal",

  projectId:
    process.env
      .NEXT_PUBLIC_SANITY_PROJECT_ID,

  dataset: "production",

  plugins: [
    structureTool(),
  ],

  schema: {
    types: schemaTypes,
  },
});
```

---

# Schema Registration

Create:

```text
schemaTypes/index.ts
```

```typescript
import post from "../schemas/post";
import author from "../schemas/author";
import category from "../schemas/category";
import comment from "../schemas/comment";
import blockContent from "../schemas/blockContent";

export const schemaTypes = [
  post,
  author,
  category,
  comment,
  blockContent,
];
```

---

# Author Schema

Create:

```text
schemas/author.ts
```

```typescript
import {
  defineField,
  defineType,
} from "sanity";

export default defineType({
  name: "author",

  title: "Authors",

  type: "document",

  fields: [
    defineField({
      name: "name",

      title: "Name",

      type: "string",

      validation: Rule =>
        Rule.required(),
    }),

    defineField({
      name: "slug",

      title: "Slug",

      type: "slug",

      options: {
        source: "name",
      },
    }),

    defineField({
      name: "bio",

      title: "Biography",

      type: "text",
    }),

    defineField({
      name: "image",

      title: "Profile Image",

      type: "image",
    }),

    defineField({
      name: "twitter",

      title: "Twitter",

      type: "url",
    }),

    defineField({
      name: "github",

      title: "GitHub",

      type: "url",
    }),
  ],
});
```

---

# Category Schema

Create:

```text
schemas/category.ts
```

```typescript
import {
  defineField,
  defineType,
} from "sanity";

export default defineType({
  name: "category",

  title: "Categories",

  type: "document",

  fields: [
    defineField({
      name: "title",

      type: "string",

      validation: Rule =>
        Rule.required(),
    }),

    defineField({
      name: "slug",

      type: "slug",

      options: {
        source: "title",
      },
    }),

    defineField({
      name: "description",

      type: "text",
    }),
  ],
});
```

---

# Portable Text

Create:

```text
schemas/blockContent.ts
```

```typescript
export default {
  name: "blockContent",

  title: "Block Content",

  type: "array",

  of: [
    {
      type: "block",
    },

    {
      type: "image",
    },
  ],
};
```

---

# Post Schema

Create:

```text
schemas/post.ts
```

```typescript
import {
  defineField,
  defineType,
} from "sanity";

export default defineType({
  name: "post",

  title: "Posts",

  type: "document",

  fields: [

    defineField({
      name: "title",

      type: "string",

      validation: Rule =>
        Rule.required(),
    }),

    defineField({
      name: "slug",

      type: "slug",

      options: {
        source: "title",
      },
    }),

    defineField({
      name: "excerpt",

      type: "text",
    }),

    defineField({
      name: "heroImage",

      type: "image",
    }),

    defineField({
      name: "author",

      type: "reference",

      to: [
        {
          type: "author",
        },
      ],
    }),

    defineField({
      name: "categories",

      type: "array",

      of: [
        {
          type: "reference",

          to: [
            {
              type:
                "category",
            },
          ],
        },
      ],
    }),

    defineField({
      name: "body",

      type:
        "blockContent",
    }),

    defineField({
      name: "publishedAt",

      type: "datetime",
    }),

    defineField({
      name: "featured",

      type: "boolean",

      initialValue: false,
    }),

    defineField({
      name: "seoTitle",

      type: "string",
    }),

    defineField({
      name:
        "seoDescription",

      type: "text",
    }),
  ],
});
```

---

# Comment Schema

Create:

```text
schemas/comment.ts
```

```typescript
import {
  defineField,
  defineType,
} from "sanity";

export default defineType({
  name: "comment",

  title: "Comments",

  type: "document",

  fields: [

    defineField({
      name: "author",

      type: "string",
    }),

    defineField({
      name: "email",

      type: "string",
    }),

    defineField({
      name: "content",

      type: "text",
    }),

    defineField({
      name: "approved",

      type: "boolean",

      initialValue: false,
    }),

    defineField({
      name: "post",

      type: "reference",

      to: [
        {
          type: "post",
        },
      ],
    }),
  ],
});
```

---

# Why References Matter

Suppose we write:

```text
John Smith
```

inside every article.

Problem:

```text
John changes name.
```

Now:

```text
100 articles
must change.
```

Instead:

```text
Post
   │
   ▼
Author
```

Diagram:

```text
Post A
     │

Post B
     │

Post C
     │

     ▼

Author
```

This is called:

```text
Normalization.
```

---

# Custom Studio Structure

Create:

```text
structure/structure.ts
```

```typescript
import { StructureBuilder }
from "sanity/structure";

export const structure = (
  S: StructureBuilder
) =>
  S.list()
    .title(
      "GreyMatter Journal"
    )
    .items([

      S.documentTypeListItem(
        "post"
      ),

      S.documentTypeListItem(
        "author"
      ),

      S.documentTypeListItem(
        "category"
      ),

      S.documentTypeListItem(
        "comment"
      ),
    ]);
```

---

# Drafts And Publishing

Sanity automatically supports:

```text
Draft
     │
     ▼
Review
     │
     ▼
Publish
```

This allows editors to:

```text
Write

Edit

Preview

Approve

Publish
```

without affecting production.

---

# Why Portable Text Exists

Traditional CMS systems store:

```html
<h1>Hello</h1>

<p>World</p>
```

Sanity stores:

```json
{
  "_type": "block",
  "children": [
    {
      "text":
        "Hello"
    }
  ]
}
```

Why?

Because:

```text
Content
      ≠
HTML
```

The same content can render as:

```text
Website

Mobile App

PDF

Email

API

AI Context
```

---

# The Hidden Architecture

When an author writes an article:

```text
Editor
    │
    ▼

Sanity Studio
    │
    ▼

Structured Content
    │
    ▼

Content Lake
    │
    ▼

API
    │
    ▼

Next.js
    │
    ▼

React
    │
    ▼

Browser
```

What appears to be:

```text
A CMS
```

is actually:

```text
A distributed
structured
information system.
```

---

# Mental Model To Remember Forever

Beginners think:

```text
CMS
   =
Website Builder
```

Professional engineers think:

```text
CMS
   =
Structured
Knowledge
Repository
```

Sanity does not store:

```text
Pages.
```

It stores:

```text
Meaning.
```

And that distinction is what enables modern headless architectures.
