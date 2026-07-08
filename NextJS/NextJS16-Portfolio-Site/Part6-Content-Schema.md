# Part 6: Designing Content Schemas

In this part we'll define the actual content types (schemas) that power the site: `siteSettings`, `author`, `skill`, `experience`, `project`, and `post` (blog). Each schema lives in its own file under `sanity/schemaTypes/`, and all six are registered together in `sanity/schemaTypes/index.ts` (started back in Part 5).

## Step 1: siteSettings Schema

Create `sanity/schemaTypes/siteSettings.ts`:

```ts
// File: sanity/schemaTypes/siteSettings.ts
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

This is a **singleton-style document** — there will only ever be one `siteSettings` document. It holds your site title, tagline, social links, and a PDF résumé upload (used later on the About page).

## Step 2: author Schema

Create `sanity/schemaTypes/author.ts`:

```ts
// File: sanity/schemaTypes/author.ts
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

This represents you, the portfolio owner. We'll typically only ever create one `author` document, but it's a real `document` type (not embedded) so it can be referenced from blog posts — this supports multi-author blogs later if you ever want them.

## Step 3: skill Schema

Create `sanity/schemaTypes/skill.ts`:

```ts
// File: sanity/schemaTypes/skill.ts
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

Create one document per skill (e.g. "React", "TypeScript", "Figma"). Add or remove categories in the `options.list` array as you see fit.

## Step 4: experience Schema

Create `sanity/schemaTypes/experience.ts`:

```ts
// File: sanity/schemaTypes/experience.ts
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

Leave `endDate` empty for a current role — the About page (Part 11) renders "Present" automatically when it's missing.

## Step 5: project Schema

This is the richest schema — it powers `/projects` and `/projects/[slug]`. Create `sanity/schemaTypes/project.ts`:

```ts
// File: sanity/schemaTypes/project.ts
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

Note: a project needs `featured: true` **and** a `publishedAt` date to show up in the homepage's featured projects section later (Part 8) — that query sorts by `publishedAt desc` and takes the first 3.

## Step 6: post Schema (Blog)

Create `sanity/schemaTypes/post.ts`:

```ts
// File: sanity/schemaTypes/post.ts
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

Note the `author` field is a `reference` — in the Studio you'll pick an existing Author document rather than re-typing their details. When we query posts later (Part 10), we "dereference" it with `author->{name, photo}` to pull those fields through.

## Step 7: Register All Six Schemas

Back in Part 5 we created an empty registry. Now fill it in — update `sanity/schemaTypes/index.ts`:

```ts
// File: sanity/schemaTypes/index.ts
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

## Step 8: Verify in the Studio

```bash
npm run dev
```

Visit http://localhost:3000/studio — you should now see six document types listed in the sidebar: **Site Settings**, **Author**, **Skill**, **Experience**, **Project**, **Blog Post**.

Create some starter content so later parts have real data to work with:

1. **Site Settings** → Create new → fill in a Title and Tagline → **Publish**. (Only ever create one of these.)
2. **Author** → Create new → fill in your Name and a Short Bio, upload a photo if you have one → **Publish**. (Only ever create one of these too.)
3. **Project** → Create new → fill in Title (slug auto-generates), Summary, toggle **Featured on Homepage** on, set **Published At** to today → **Publish**.
4. Optionally add a couple of **Skill** and **Experience** documents now, or wait until Part 11.

## Checkpoint ✅

You now have:
- Six fully defined Sanity schemas: `siteSettings`, `author`, `skill`, `experience`, `project`, `post`
- All schemas registered in `sanity/schemaTypes/index.ts`
- At least one published document for `siteSettings`, `author`, and `project` via the Studio UI

Commit your progress:

```bash
git add .
git commit -m "Add Sanity content schemas: siteSettings, author, skill, experience, project, post"
```

> These six schemas exactly match the reference copies in **Appendix B: Complete Sanity Schema Reference** — if you ever need to double-check a field name while building later parts, Appendix B is the canonical source.

Next up: **Part 7: Connecting Next.js to Sanity**, where we install the Sanity client, write our first GROQ queries, and render real content on the homepage.
