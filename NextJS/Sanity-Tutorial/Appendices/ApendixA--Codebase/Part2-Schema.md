# Sanity Mastery - Appendix A (2 of 5): Schema Files
# Appendix A (2 of 5): Schema Files

Continues from Appendix A (1 of 5). Covers `src/sanity/schemaTypes/*` in full.

## src/sanity/schemaTypes/blockContent.ts

```ts
import { defineType, defineArrayMember } from "sanity";
import { ImageIcon } from "lucide-react";

export const blockContent = defineType({
  title: "Block Content",
  name: "blockContent",
  type: "array",
  of: [
    defineArrayMember({
      type: "block",
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
            title: "URL",
            name: "link",
            type: "object",
            fields: [
              {
                title: "URL",
                name: "href",
                type: "url",
                validation: (Rule) => Rule.uri({ scheme: ["http", "https", "mailto", "tel"] }),
              },
              { title: "Open in new tab", name: "blank", type: "boolean", initialValue: true },
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
          validation: (Rule) => Rule.required(),
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
          type: "string",
          options: { list: ["tsx", "ts", "js", "bash", "json", "css"] },
          initialValue: "tsx",
        },
        { name: "code", type: "text", rows: 10 },
      ],
      preview: {
        select: { language: "language", code: "code" },
        prepare({ language, code }) {
          return { title: `Code (${language})`, subtitle: code?.slice(0, 40) };
        },
      },
    }),
  ],
});
```

## src/sanity/schemaTypes/author.ts

```ts
import { defineField, defineType } from "sanity";
import { UserIcon } from "lucide-react";

export const author = defineType({
  name: "author",
  title: "Author",
  type: "document",
  icon: UserIcon,
  fields: [
    defineField({ name: "name", title: "Name", type: "string", validation: (Rule) => Rule.required() }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "name", maxLength: 96 },
      validation: (Rule) => Rule.required(),
    }),
    defineField({ name: "photo", title: "Photo", type: "image", options: { hotspot: true } }),
    defineField({ name: "shortBio", title: "Short Bio", type: "text", rows: 3, validation: (Rule) => Rule.max(200) }),
    defineField({ name: "longBio", title: "Long Bio", type: "blockContent" }),
  ],
  preview: { select: { title: "name", media: "photo" } },
});
```

## src/sanity/schemaTypes/category.ts

```ts
import { defineField, defineType } from "sanity";
import { TagIcon } from "lucide-react";

export const category = defineType({
  name: "category",
  title: "Category",
  type: "document",
  icon: TagIcon,
  fields: [
    defineField({ name: "title", type: "string", validation: (Rule) => Rule.required() }),
    defineField({ name: "slug", type: "slug", options: { source: "title" }, validation: (Rule) => Rule.required() }),
    defineField({ name: "description", type: "text", rows: 2 }),
  ],
});
```

## src/sanity/schemaTypes/post.ts

```ts
import { defineField, defineType } from "sanity";
import { DocumentTextIcon } from "lucide-react";

export const post = defineType({
  name: "post",
  title: "Post",
  type: "document",
  icon: DocumentTextIcon,
  fields: [
    defineField({ name: "title", type: "string", validation: (Rule) => Rule.required().min(5).max(120) }),
    defineField({
      name: "slug",
      type: "slug",
      options: { source: "title", maxLength: 96 },
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "author",
      type: "reference",
      to: [{ type: "author" }],
      validation: (Rule) => Rule.required(),
    }),
    defineField({ name: "categories", type: "array", of: [{ type: "reference", to: [{ type: "category" }] }] }),
    defineField({
      name: "coverImage",
      type: "image",
      options: { hotspot: true },
      fields: [{ name: "alt", type: "string", title: "Alt text" }],
    }),
    defineField({ name: "excerpt", type: "text", rows: 3, validation: (Rule) => Rule.max(200) }),
    defineField({ name: "publishedAt", type: "datetime", initialValue: () => new Date().toISOString() }),
    defineField({ name: "body", type: "blockContent" }),
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
  preview: {
    select: { title: "title", media: "coverImage", authorName: "author.name" },
    prepare({ title, media }) {
      return { title, media };
    },
  },
});
```

## src/sanity/schemaTypes/siteSettings.ts

```ts
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
            { name: "platform", type: "string", options: { list: ["twitter", "github", "linkedin", "youtube"] } },
            { name: "url", type: "url" },
          ],
        },
      ],
    }),
  ],
});
```

## src/sanity/schemaTypes/index.ts

```ts
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

Continue to **Appendix A (3 of 5)** for client/fetch/image/queries/types.
