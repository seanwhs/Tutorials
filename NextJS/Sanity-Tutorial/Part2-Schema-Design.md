# Sanity Mastery - Part 2: Schema Design

Throughout this series we build a running example: a **blog** with `post`, `author`, `category`, reusable `blockContent` (Portable Text), and a singleton `siteSettings`. Every later part (GROQ, fetching, rendering, preview) queries this exact content model.

## Two Kinds of Schema Types

| Kind | Helper | Has its own `_id`? | Example |
|---|---|---|---|
| **Document type** | `defineType({ type: "document", ... })` | Yes — top-level, editable in Studio's content list | `post`, `author`, `category` |
| **Object type** | `defineType({ type: "object", ... })` | No — embedded inside a document field | `blockContent`, `seo`, `socialLink` |

## Step 1: Reusable Portable Text schema (`blockContent`)

```ts
// src/sanity/schemaTypes/blockContent.ts
import { defineType, defineArrayMember } from "sanity";
import { ImageIcon } from "lucide-react"; // any icon lib works; Studio just renders it

// This defines the *shape* of rich text: which block styles, marks (bold/italic/link),
// and embedded custom types (images, code blocks) editors are allowed to use.
export const blockContent = defineType({
  title: "Block Content",
  name: "blockContent",
  type: "array",
  of: [
    defineArrayMember({
      type: "block",
      // Restrict which text styles editors can pick — keeps content consistent
      styles: [
        { title: "Normal", value: "normal" },
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
            // Custom "link" annotation — becomes a clickable mark in the editor
            title: "URL",
            name: "link",
            type: "object",
            fields: [
              {
                title: "URL",
                name: "href",
                type: "url",
                validation: (Rule) =>
                  Rule.uri({ scheme: ["http", "https", "mailto", "tel"] }),
              },
              {
                title: "Open in new tab",
                name: "blank",
                type: "boolean",
                initialValue: true,
              },
            ],
          },
        ],
      },
    }),
    // Embedded images directly inside rich text (not just at top of post)
    defineArrayMember({
      type: "image",
      icon: ImageIcon,
      options: { hotspot: true }, // lets editors pick a focal point — Part 6
      fields: [
        {
          name: "alt",
          type: "string",
          title: "Alternative text",
          description: "Important for SEO and accessibility.",
          validation: (Rule) => Rule.required(),
        },
      ],
    }),
    // Custom "code block" type for technical posts
    defineArrayMember({
      type: "object",
      name: "codeBlock",
      title: "Code Block",
      fields: [
        {
          name: "language",
          type: "string",
          options: {
            list: ["tsx", "ts", "js", "bash", "json", "css"],
          },
          initialValue: "tsx",
        },
        { name: "code", type: "text", rows: 10 },
      ],
      preview: {
        select: { language: "language", code: "code" },
        prepare({ language, code }) {
          return {
            title: `Code (${language})`,
            subtitle: code?.slice(0, 40),
          };
        },
      },
    }),
  ],
});
```

## Step 2: `author` document

```ts
// src/sanity/schemaTypes/author.ts
import { defineField, defineType } from "sanity";
import { UserIcon } from "lucide-react";

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
      // slugify the name automatically, editors can still override
      options: { source: "name", maxLength: 96 },
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "photo",
      title: "Photo",
      type: "image",
      options: { hotspot: true },
    }),
    defineField({
      name: "shortBio",
      title: "Short Bio",
      type: "text",
      rows: 3,
      validation: (Rule) => Rule.max(200),
    }),
    defineField({
      name: "longBio",
      title: "Long Bio",
      type: "blockContent",
    }),
  ],
  preview: {
    select: { title: "name", media: "photo" },
  },
});
```

## Step 3: `category` document

```ts
// src/sanity/schemaTypes/category.ts
import { defineField, defineType } from "sanity";
import { TagIcon } from "lucide-react";

export const category = defineType({
  name: "category",
  title: "Category",
  type: "document",
  icon: TagIcon,
  fields: [
    defineField({
      name: "title",
      type: "string",
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "slug",
      type: "slug",
      options: { source: "title" },
      validation: (Rule) => Rule.required(),
    }),
    defineField({ name: "description", type: "text", rows: 2 }),
  ],
});
```

## Step 4: `post` document — the centerpiece, using references

```ts
// src/sanity/schemaTypes/post.ts
import { defineField, defineType } from "sanity";
import { DocumentTextIcon } from "lucide-react";

export const post = defineType({
  name: "post",
  title: "Post",
  type: "document",
  icon: DocumentTextIcon,
  fields: [
    defineField({
      name: "title",
      type: "string",
      validation: (Rule) => Rule.required().min(5).max(120),
    }),
    defineField({
      name: "slug",
      type: "slug",
      options: { source: "title", maxLength: 96 },
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "author",
      type: "reference",
      // `to` is an array because references can theoretically point to multiple
      // document types — here we only allow "author".
      to: [{ type: "author" }],
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "categories",
      type: "array",
      of: [{ type: "reference", to: [{ type: "category" }] }],
    }),
    defineField({
      name: "coverImage",
      type: "image",
      options: { hotspot: true },
      fields: [{ name: "alt", type: "string", title: "Alt text" }],
    }),
    defineField({
      name: "excerpt",
      type: "text",
      rows: 3,
      validation: (Rule) => Rule.max(200),
    }),
    defineField({
      name: "publishedAt",
      type: "datetime",
      initialValue: () => new Date().toISOString(),
    }),
    defineField({
      name: "body",
      type: "blockContent", // reuse the object type from Step 1
    }),
    defineField({
      name: "seo",
      title: "SEO Overrides",
      type: "object",
      options: { collapsible: true, collapsed: true },
      fields: [
        { name: "metaTitle", type: "string" },
        { name: "metaDescription", type: "text", rows: 2 },
      ],
    }),
  ],
  // Controls how this doc appears in lists/search inside Studio
  preview: {
    select: { title: "title", media: "coverImage", authorName: "author.name" },
    prepare({ title, media }) {
      return { title, media };
    },
  },
});
```

## Step 5: Singleton `siteSettings` document

Some documents should only ever have **one instance** (e.g. global site title, nav links). Sanity has no built-in "singleton" concept — you enforce it via Studio's **structure customization** (Part 10) plus simply never letting editors create a second one from the default list. For now, define the schema:

```ts
// src/sanity/schemaTypes/siteSettings.ts
import { defineField, defineType } from "sanity";
import { CogIcon } from "lucide-react";

export const siteSettings = defineType({
  name: "siteSettings",
  title: "Site Settings",
  type: "document",
  icon: CogIcon,
  fields: [
    defineField({ name: "title", type: "string" }),
    defineField({ name: "tagline", type: "string" }),
    defineField({
      name: "socialLinks",
      type: "array",
      of: [
        {
          type: "object",
          name: "socialLink",
          fields: [
            {
              name: "platform",
              type: "string",
              options: { list: ["twitter", "github", "linkedin", "youtube"] },
            },
            { name: "url", type: "url" },
          ],
        },
      ],
    }),
  ],
});
```

## Step 6: Wire everything into the schema index

```ts
// src/sanity/schemaTypes/index.ts
import { type SchemaTypeDefinition } from "sanity";
import { post } from "./post";
import { author } from "./author";
import { category } from "./category";
import { blockContent } from "./blockContent";
import { siteSettings } from "./siteSettings";

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [post, author, category, blockContent, siteSettings],
};
```

Restart `npm run dev`, visit `/studio` — you'll now see **Post**, **Author**, **Category**, and **Site Settings** in the left sidebar. Create 1 author, 2 categories, and 2-3 posts now — later parts query this content.

## Validation Cheat Sheet

```ts
// Common Rule validators, chainable
Rule.required()                       // field cannot be empty
Rule.min(5).max(120)                  // string/number length or numeric bounds
Rule.uri({ scheme: ["https"] })       // restrict URL schemes
Rule.custom((value, context) => {     // fully custom logic
  if (value && value.includes("bad")) return "Cannot contain 'bad'";
  return true; // must return true (valid) or a string (error message)
})
Rule.unique()                         // for array items — no duplicate values
```

## Checkpoint ✅
- [ ] `blockContent`, `author`, `category`, `post`, `siteSettings` all created and registered
- [ ] Studio shows all four document types in the sidebar
- [ ] You've manually created at least 1 author, 2 categories, 2-3 posts as test data
- [ ] References (`post.author`, `post.categories`) resolve correctly in the Studio form (dropdown/search works)

**Next: Part 3 — GROQ, the Query Language**
