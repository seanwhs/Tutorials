## Blog Tutorial - Part 3: Designing Content (Post, Author, Category, Block Content Schemas)

## What we're doing

We'll define the shape of our content in Sanity using schema definitions written in TypeScript. We need four schema types:

* `post` — a blog post
* `author` — who wrote it
* `category` — topic tags
* `blockContent` — the rich text body definition (reusable)

> **Note:** Sanity schema files are plain TypeScript/Sanity SDK code and are unaffected by the Next.js 16 upgrade — no async/await changes needed here. The Next.js 16-specific changes (async `params`) begin in Part 5 and Part 6 when we build the pages that read these documents.

## Step 1: Create the folder structure

```text
src/sanity/schemaTypes/
  index.ts
  post.ts
  author.ts
  category.ts
  blockContent.ts

```

## Step 2: Block Content schema

Create `src/sanity/schemaTypes/blockContent.ts`:

```ts
import { defineType, defineArrayMember } from "sanity";
import { ImageIcon } from "@sanity/icons/Image";

export const blockContent = defineType({
  title: "Block Content",
  name: "blockContent",
  type: "array",
  of: [
    defineArrayMember({
      title: "Block",
      type: "block",
      styles: [
        { title: "Normal", value: "normal" },
        { title: "H1", value: "h1" },
        { title: "H2", value: "h2" },
        { title: "H3", value: "h3" },
        { title: "H4", value: "h4" },
        { title: "Quote", value: "blockquote" },
      ],
      lists: [
        { title: "Bullet", value: "bullet" },
        { title: "Numbered", value: "number" },
      ],
      marks: {
        decorators: [
          { title: "Strong", value: "strong" },
          { title: "Emphasis", value: "em" },
          { title: "Code", value: "code" },
        ],
        annotations: [
          {
            title: "URL",
            name: "link",
            type: "object",
            fields: [
              {
                title: "URL",
                name: "href",
                type: "url",
              },
            ],
          },
        ],
      },
    }),
    defineArrayMember({
      type: "image",
      icon: ImageIcon,
      options: { hotspot: true },
      fields: [
        {
          name: "alt",
          type: "string",
          title: "Alternative text",
          description: "Important for SEO and accessibility.",
        },
      ],
    }),
    defineArrayMember({
      type: "object",
      name: "codeBlock",
      title: "Code Block",
      fields: [
        {
          name: "language",
          title: "Language",
          type: "string",
          options: {
            list: [
              "javascript", "typescript", "jsx", "tsx", "bash",
              "json", "css", "html", "python",
            ],
          },
        },
        {
          name: "code",
          title: "Code",
          type: "text",
          rows: 10,
        },
      ],
      preview: {
        select: { language: "language", code: "code" },
        prepare({ language, code }) {
          return {
            title: `Code (${language || "plain"})`,
            subtitle: code?.slice(0, 40),
          };
        },
      },
    }),
  ],
});

```

## Step 3: Author schema

Create `src/sanity/schemaTypes/author.ts`:

```ts
import { defineField, defineType } from "sanity";
import { UserIcon } from "@sanity/icons/User";

export const author = defineType({
  name: "author",
  title: "Author",
  type: "document",
  icon: UserIcon,
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
      options: { source: "name", maxLength: 96 },
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "image",
      title: "Photo",
      type: "image",
      options: { hotspot: true },
    }),
    defineField({
      name: "bio",
      title: "Bio",
      type: "text",
      rows: 4,
    }),
  ],
  preview: {
    select: { title: "name", media: "image" },
  },
});

```

## Step 4: Category schema

Create `src/sanity/schemaTypes/category.ts`:

```ts
import { defineField, defineType } from "sanity";
import { TagIcon } from "@sanity/icons/Tag";

export const category = defineType({
  name: "category",
  title: "Category",
  type: "document",
  icon: TagIcon,
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
      options: { source: "title", maxLength: 96 },
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "description",
      title: "Description",
      type: "text",
      rows: 3,
    }),
  ],
  preview: {
    select: { title: "title" },
  },
});

```

## Step 5: Post schema

Create `src/sanity/schemaTypes/post.ts`:

```ts
import { defineField, defineType } from "sanity";
import { DocumentTextIcon } from "@sanity/icons/DocumentText";

export const post = defineType({
  name: "post",
  title: "Post",
  type: "document",
  icon: DocumentTextIcon,
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
      options: { source: "title", maxLength: 96 },
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "author",
      title: "Author",
      type: "reference",
      to: [{ type: "author" }],
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "mainImage",
      title: "Main Image",
      type: "image",
      options: { hotspot: true },
      fields: [
        {
          name: "alt",
          type: "string",
          title: "Alternative text",
        },
      ],
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "categories",
      title: "Categories",
      type: "array",
      of: [{ type: "reference", to: { type: "category" } }],
    }),
    defineField({
      name: "publishedAt",
      title: "Published at",
      type: "datetime",
      initialValue: () => new Date().toISOString(),
    }),
    defineField({
      name: "excerpt",
      title: "Excerpt",
      type: "text",
      rows: 3,
      description: "Short summary shown on the homepage and in SEO previews.",
      validation: (Rule) => Rule.max(200),
    }),
    defineField({
      name: "body",
      title: "Body",
      type: "blockContent",
    }),
    defineField({
      name: "isMembersOnly",
      title: "Members Only",
      type: "boolean",
      description: "If enabled, only signed-in users can read the full post.",
      initialValue: false,
    }),
  ],
  preview: {
    select: {
      title: "title",
      author: "author.name",
      media: "mainImage",
    },
    prepare(selection) {
      const { author } = selection;
      return { ...selection, subtitle: author && `by ${author}` };
    },
  },
});

```

## Step 6: Register all schemas

Update `src/sanity/schemaTypes/index.ts`:

```ts
import { type SchemaTypeDefinition } from "sanity";

import { post } from "./post";
import { author } from "./author";
import { category } from "./category";
import { blockContent } from "./blockContent";

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [post, author, category, blockContent],
};

```

## Step 7: View it in the Studio

```bash
npm run dev

```

Go to `http://localhost:3000/studio` — you should now see **Post**, **Author**, and **Category** in the left sidebar.

## Step 8: Create sample content

1. Click **Author** → Create new → fill in Name "Jane Doe", upload a photo, add a bio → **Publish**
2. Click **Category** → Create new → Title "Web Development" → **Publish**
3. Click **Post** → Create new:
* Title: "Hello World: My First Post"
* Slug: Click "Generate"
* Author: select Jane Doe
* Main Image: upload any image
* Categories: select "Web Development"
* Excerpt: "This is my very first blog post!"
* Body: write a few paragraphs, try adding a heading and a code block
* Members Only: leave unchecked
* **Publish**



## Checkpoint ✅

* [ ] Studio shows Post/Author/Category types
* [ ] You created 1 author, 1 category, and 1 published post
* [ ] Content is saved (visible again after refreshing the Studio)

---

Next: **Part 4 — Fetching Content: Sanity Client, GROQ, Homepage Post List**
