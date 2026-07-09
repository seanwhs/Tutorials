# Appendix B: Complete Sanity Schema Reference

All six schemas defined in Part 6, consolidated here for quick reference.

## sanity/schemaTypes/index.ts

```ts
import { type SchemaTypeDefinition } from "sanity";

import siteSettings from "./siteSettings";
import author from "./author";
import skill from "./skill";
import experience from "./experience";
import project from "./project";
import post from "./post";

export const schemaTypes: SchemaTypeDefinition[] = [
  siteSettings,
  author,
  skill,
  experience,
  project,
  post,
];
```

## sanity/schemaTypes/siteSettings.ts

```ts
import { defineField, defineType } from "sanity";

export default defineType({
  name: "siteSettings",
  title: "Site Settings",
  type: "document",
  fields: [
    defineField({ name: "title", title: "Site Title", type: "string" }),
    defineField({ name: "tagline", title: "Tagline", type: "string" }),
    defineField({
      name: "socialLinks",
      title: "Social Links",
      type: "array",
      of: [
        {
          type: "object",
          fields: [
            { name: "platform", type: "string", title: "Platform" },
            { name: "url", type: "url", title: "URL" },
          ],
        },
      ],
    }),
    defineField({
      name: "resumeFile",
      title: "Resume (PDF)",
      type: "file",
      options: { accept: ".pdf" },
    }),
  ],
});
```

**Notes**: Singleton in practice — only ever create one document. Query with `*[_type == "siteSettings"][0]`.

## sanity/schemaTypes/author.ts

```ts
import { defineField, defineType } from "sanity";

export default defineType({
  name: "author",
  title: "Author",
  type: "document",
  fields: [
    defineField({ name: "name", title: "Name", type: "string" }),
    defineField({
      name: "photo",
      title: "Photo",
      type: "image",
      options: { hotspot: true },
    }),
    defineField({ name: "shortBio", title: "Short Bio", type: "text", rows: 3 }),
    defineField({
      name: "longBio",
      title: "Long Bio",
      type: "array",
      of: [{ type: "block" }],
    }),
  ],
});
```

**Notes**: Also singleton in this series (one author = you), but referenced from `post.author` — so it's a real `document` type, not embedded, to support future multi-author use.

## sanity/schemaTypes/skill.ts

```ts
import { defineField, defineType } from "sanity";

export default defineType({
  name: "skill",
  title: "Skill",
  type: "document",
  fields: [
    defineField({ name: "name", title: "Name", type: "string" }),
    defineField({
      name: "category",
      title: "Category",
      type: "string",
      options: {
        list: ["Languages", "Frameworks", "Tools", "Design", "Other"],
      },
    }),
  ],
});
```

**Notes**: Create one document per skill. Add/remove categories in the `options.list` array as needed.

## sanity/schemaTypes/experience.ts

```ts
import { defineField, defineType } from "sanity";

export default defineType({
  name: "experience",
  title: "Experience",
  type: "document",
  fields: [
    defineField({ name: "role", title: "Role", type: "string" }),
    defineField({ name: "company", title: "Company", type: "string" }),
    defineField({ name: "startDate", title: "Start Date", type: "date" }),
    defineField({ name: "endDate", title: "End Date", type: "date" }),
    defineField({
      name: "description",
      title: "Description",
      type: "array",
      of: [{ type: "block" }],
    }),
  ],
});
```

**Notes**: Leave `endDate` empty for a current role — the `formatRange` helper in `ExperienceItem.tsx` renders "Present" when it's missing.

## sanity/schemaTypes/project.ts

```ts
import { defineField, defineType } from "sanity";

export default defineType({
  name: "project",
  title: "Project",
  type: "document",
  fields: [
    defineField({ name: "title", title: "Title", type: "string" }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title", maxLength: 96 },
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "summary",
      title: "Summary",
      type: "text",
      rows: 3,
      description: "Short 1-2 sentence summary shown on cards",
    }),
    defineField({
      name: "coverImage",
      title: "Cover Image",
      type: "image",
      options: { hotspot: true },
    }),
    defineField({
      name: "gallery",
      title: "Gallery",
      type: "array",
      of: [{ type: "image", options: { hotspot: true } }],
    }),
    defineField({
      name: "tags",
      title: "Tags / Tech Stack",
      type: "array",
      of: [{ type: "string" }],
      options: { layout: "tags" },
    }),
    defineField({ name: "liveUrl", title: "Live URL", type: "url" }),
    defineField({ name: "repoUrl", title: "Repository URL", type: "url" }),
    defineField({
      name: "featured",
      title: "Featured on Homepage",
      type: "boolean",
      initialValue: false,
    }),
    defineField({
      name: "publishedAt",
      title: "Published At",
      type: "datetime",
    }),
    defineField({
      name: "body",
      title: "Case Study Body",
      type: "array",
      of: [
        { type: "block" },
        { type: "image", options: { hotspot: true } },
      ],
    }),
  ],
  preview: {
    select: { title: "title", media: "coverImage" },
  },
});
```

**Notes**: `featured: true` + a `publishedAt` date is required for a project to appear in the homepage's `featuredProjectsQuery` (which sorts by `publishedAt desc` and takes the first 3).

## sanity/schemaTypes/post.ts

```ts
import { defineField, defineType } from "sanity";

export default defineType({
  name: "post",
  title: "Blog Post",
  type: "document",
  fields: [
    defineField({ name: "title", title: "Title", type: "string" }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title", maxLength: 96 },
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "excerpt",
      title: "Excerpt",
      type: "text",
      rows: 3,
    }),
    defineField({
      name: "coverImage",
      title: "Cover Image",
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
      name: "publishedAt",
      title: "Published At",
      type: "datetime",
    }),
    defineField({
      name: "body",
      title: "Body",
      type: "array",
      of: [
        { type: "block" },
        { type: "image", options: { hotspot: true } },
      ],
    }),
  ],
  preview: {
    select: { title: "title", media: "coverImage" },
  },
});
```

**Notes**: `author` is a `reference` field — in the Studio you pick an existing Author document rather than re-typing details. Queries use `author->{name, photo}` to "dereference" (follow the reference and pull fields).

## Extending the Schemas

Some ideas if you want to grow beyond this series:
- Add a `testimonial` document type (`quote`, `personName`, `personTitle`, `personPhoto`) and a homepage section for it
- Add a `category` reference field to `post` for multi-category blogs
- Add an `order` number field to `skill`/`experience` if you want manual control over display order instead of date-based sorting
- Add a `seoTitle`/`seoDescription` override field to `project`/`post` for per-document SEO control beyond the auto-generated defaults from Part 14
