# **✅ Appendix C — Complete Sanity Studio Source Code and Schema Definitions**

---

# Appendix C — Complete Sanity Studio Source Code and Schema Definitions

> **Goal of this appendix:** Provide the full Sanity Studio implementation for GreyMatter Journal, including schemas, structure, and configuration, while explaining how headless CMS systems model content, relationships, and editorial workflows.

---

### Introduction

Sanity is not just a database — it is a **structured content operating system**.

It separates:
- **Content creation** (Studio)
- **Content storage** (Content Lake)
- **Content delivery** (GROQ + APIs)

This separation enables rich editorial experiences while giving developers full control over presentation.

---

### Final Studio Folder Structure

```text
studio/
├── sanity.config.ts
├── schemaTypes/
│   └── index.ts
├── schemas/
│   ├── author.ts
│   ├── category.ts
│   ├── post.ts
│   ├── comment.ts
│   └── blockContent.ts
├── structure/
│   └── structure.ts
└── plugins/ (optional)
```

---

### 1. Studio Configuration (`sanity.config.ts`)

```typescript
import { defineConfig } from "sanity";
import { structureTool } from "sanity/structure";
import { schemaTypes } from "./schemaTypes";

export default defineConfig({
  name: "default",
  title: "GreyMatter Journal",
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: "production",

  plugins: [structureTool()],

  schema: {
    types: schemaTypes,
  },
});
```

---

### 2. Schema Registration (`schemaTypes/index.ts`)

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

### 3. Author Schema (`schemas/author.ts`)

```typescript
import { defineField, defineType } from "sanity";

export default defineType({
  name: "author",
  title: "Author",
  type: "document",
  fields: [
    defineField({
      name: "name",
      title: "Name",
      type: "string",
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "name" },
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
      options: { hotspot: true },
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

### 4. Category Schema (`schemas/category.ts`)

```typescript
import { defineField, defineType } from "sanity";

export default defineType({
  name: "category",
  title: "Category",
  type: "document",
  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title" },
    }),
    defineField({
      name: "description",
      title: "Description",
      type: "text",
    }),
  ],
});
```

---

### 5. Block Content (Portable Text) (`schemas/blockContent.ts`)

```typescript
export default {
  name: "blockContent",
  title: "Block Content",
  type: "array",
  of: [
    { type: "block" },
    {
      type: "image",
      options: { hotspot: true },
    },
  ],
};
```

---

### 6. Post Schema (`schemas/post.ts`)

```typescript
import { defineField, defineType } from "sanity";

export default defineType({
  name: "post",
  title: "Post",
  type: "document",
  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title" },
    }),
    defineField({
      name: "excerpt",
      title: "Excerpt",
      type: "text",
    }),
    defineField({
      name: "heroImage",
      title: "Hero Image",
      type: "image",
      options: { hotspot: true },
    }),
    defineField({
      name: "author",
      title: "Author",
      type: "reference",
      to: [{ type: "author" }],
    }),
    defineField({
      name: "categories",
      title: "Categories",
      type: "array",
      of: [{ type: "reference", to: [{ type: "category" }] }],
    }),
    defineField({
      name: "body",
      title: "Body",
      type: "blockContent",
    }),
    defineField({
      name: "publishedAt",
      title: "Published At",
      type: "datetime",
    }),
    defineField({
      name: "likes",
      title: "Likes",
      type: "number",
      initialValue: 0,
    }),
  ],
});
```

---

### 7. Comment Schema (`schemas/comment.ts`)

```typescript
import { defineField, defineType } from "sanity";

export default defineType({
  name: "comment",
  title: "Comment",
  type: "document",
  fields: [
    defineField({ name: "author", type: "string" }),
    defineField({ name: "email", type: "string" }),
    defineField({ name: "content", type: "text" }),
    defineField({
      name: "approved",
      type: "boolean",
      initialValue: false,
    }),
    defineField({
      name: "post",
      type: "reference",
      to: [{ type: "post" }],
    }),
  ],
});
```

---

### 8. Custom Studio Structure (`structure/structure.ts`)

```typescript
import { StructureBuilder } from "sanity/structure";

export const structure = (S: StructureBuilder) =>
  S.list()
    .title("GreyMatter Journal")
    .items([
      S.documentTypeListItem("post"),
      S.documentTypeListItem("author"),
      S.documentTypeListItem("category"),
      S.documentTypeListItem("comment"),
    ]);
```

---

### Final Thoughts

Sanity gives you:
- Rich content modeling
- Powerful relationships
- Editorial workflows
- Structured data (Portable Text)

Next.js gives you:
- Beautiful rendering
- Performance
- Developer experience

Together, they form a complete modern content platform.
