# GreyMatter Journal

# Part 8 — Understanding Sanity Studio: Why Content Modeling Is More Important Than Writing Code

> **Goal of this lesson:** Understand what the `studio` folder actually contains, what schemas are, why content modeling matters, and how to design a blog as a system of relationships rather than a collection of pages.

---

# Congratulations — You Now Have Two Applications

After running:

```bash
npx sanity@latest init
```

your project should look something like this:

```text
greymatter-journal/

app/
public/

studio/

package.json
next.config.ts
tsconfig.json
```

Many beginners look at this and think:

> "Did I accidentally create another project?"

The answer is:

```text
Yes.
```

And that's exactly what we wanted.

---

# GreyMatter Journal Is Actually Two Applications

Your architecture now looks like this:

```text
Greymatter Journal

├── Next.js App
│
└── Sanity Studio
```

These applications serve completely different users.

---

## Next.js Application

Users:

```text
Readers
```

Responsibilities:

```text
Render articles
Render authors
Render categories
Render pages
```

---

## Sanity Studio

Users:

```text
Writers
Editors
Administrators
```

Responsibilities:

```text
Create content
Edit content
Review content
Publish content
Manage media
```

---

# Think About Netflix Again

Netflix actually has two applications:

```text
Netflix Editor Portal
            ↓
Editors upload content

Netflix Application
            ↓
Users watch content
```

Similarly:

```text
Sanity Studio
        ↓
Editors create content

Next.js
        ↓
Readers consume content
```

---

# Let's Explore The Studio Folder

Open:

```text
studio/
```

You'll see something similar to:

```text
studio/

sanity.config.ts
schemaTypes/
package.json
tsconfig.json
```

At first glance, this doesn't look like a CMS.

That's because:

```text
Sanity Studio
       =
React Application
```

The Studio itself is built with React.

---

# Running The Studio

Open another terminal:

```bash
cd studio
npm run dev
```

You'll see something like:

```text
http://localhost:3333
```

Open it.

You should see your Sanity dashboard.

Congratulations.

You are now running:

```text
Next.js
      +
React
      +
Sanity Studio
      +
Content Lake
```

simultaneously.

---

# The First Question Sanity Asks

Sanity doesn't ask:

> "What pages do you want?"

Instead, it asks:

> "What content do you have?"

This is an enormous shift.

---

# How Beginners Design Blogs

Most beginners think:

```text
Home Page

About Page

Blog Page

Author Page
```

This is:

```text
UI-first thinking
```

---

# How CMS Architects Think

Instead they ask:

```text
What information exists?
```

Example:

```text
Article
Author
Category
Tag
Image
```

This is:

```text
Content-first thinking
```

---

# Why This Difference Matters

Suppose we have:

```text
Article

Title
Body
Author
Category
Image
```

One article can appear on:

```text
Homepage

Category Page

Author Page

Search Results

RSS Feed

Newsletter
```

If you design pages first:

```text
Duplicate Data
```

If you design content first:

```text
Reuse Data
```

---

# What Is A Schema?

A schema defines the structure of content.

Think of it as a contract.

Example:

```text
Blog Post

must have:

Title
Slug
Body
Author
Published Date
```

In TypeScript terms:

```typescript
type Post = {
  title: string;
  slug: string;
  body: string;
  author: Author;
};
```

Sanity schemas work similarly.

---

# Our First Content Model

GreyMatter Journal will contain:

```text
Post
Author
Category
```

Diagram:

```text
Category
     ▲
     │
     │
Post ─────► Author
```

---

# Designing A Post

Let's think like editors.

When writing an article, editors need:

```text
Title

Slug

Excerpt

Body

Cover Image

Author

Categories

Published Date
```

Diagram:

```text
Post

├── Title
├── Slug
├── Excerpt
├── Body
├── Cover Image
├── Author
├── Categories
└── Published Date
```

---

# Designing Authors

Authors require:

```text
Name

Slug

Biography

Avatar

Social Links
```

Diagram:

```text
Author

├── Name
├── Slug
├── Biography
├── Avatar
└── Social Links
```

---

# Designing Categories

Categories require:

```text
Name

Slug

Description
```

Diagram:

```text
Category

├── Name
├── Slug
└── Description
```

---

# Why Relationships Matter

Suppose Sean writes 200 articles.

Bad design:

```text
Article 1
Author: Sean Wong

Article 2
Author: Sean Wong

Article 3
Author: Sean Wong
```

Repeated hundreds of times.

Good design:

```text
Author
   ▲
   │
   │
Articles
```

Diagram:

```text
Author Document

        ▲
        │
        │

Post A
Post B
Post C
Post D
```

Now changing the author's biography updates everything.

---

# Let's Create Our Schema Folder

Inside:

```text
studio/schemaTypes/
```

create:

```text
schemaTypes/

post.ts
author.ts
category.ts
index.ts
```

---

# Our First Schema

Create:

```text
studio/schemaTypes/category.ts
```

```typescript
import { defineField, defineType } from "sanity";

export const categoryType = defineType({
  name: "category",
  title: "Category",
  type: "document",

  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
    }),

    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",

      options: {
        source: "title",
      },
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

# What Are We Looking At?

This code may look intimidating.

But we're simply describing data.

Equivalent diagram:

```text
Category

├── title
├── slug
└── description
```

Nothing more.

---

# Creating The Author Schema

Create:

```text
studio/schemaTypes/author.ts
```

```typescript
import { defineField, defineType } from "sanity";

export const authorType = defineType({
  name: "author",
  title: "Author",
  type: "document",

  fields: [
    defineField({
      name: "name",
      title: "Name",
      type: "string",
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
      name: "avatar",
      title: "Avatar",
      type: "image",
    }),
  ],
});
```

---

# Creating The Post Schema

Create:

```text
studio/schemaTypes/post.ts
```

```typescript
import { defineField, defineType } from "sanity";

export const postType = defineType({
  name: "post",
  title: "Post",
  type: "document",

  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
    }),

    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",

      options: {
        source: "title",
      },
    }),

    defineField({
      name: "excerpt",
      title: "Excerpt",
      type: "text",
    }),

    defineField({
      name: "coverImage",
      title: "Cover Image",
      type: "image",
    }),

    defineField({
      name: "body",
      title: "Body",
      type: "array",

      of: [
        {
          type: "block",
        },
      ],
    }),

    defineField({
      name: "author",
      title: "Author",
      type: "reference",

      to: [
        {
          type: "author",
        },
      ],
    }),

    defineField({
      name: "categories",
      title: "Categories",
      type: "array",

      of: [
        {
          type: "reference",
          to: [
            {
              type: "category",
            },
          ],
        },
      ],
    }),

    defineField({
      name: "publishedAt",
      title: "Published At",
      type: "datetime",
    }),
  ],
});
```

---

# What Just Happened?

We didn't create pages.

We didn't create components.

We didn't create routes.

Instead, we created:

```text
Business Objects
```

Diagram:

```text
Author
    ▲
    │
    │
Post
    │
    ▼
Category
```

This is called:

# Domain Modeling

---

# Registering The Schemas

Open:

```text
studio/schemaTypes/index.ts
```

Add:

```typescript
import { authorType } from "./author";
import { categoryType } from "./category";
import { postType } from "./post";

export const schemaTypes = [
  postType,
  authorType,
  categoryType,
];
```

---

# What Happens Next?

After saving, Sanity automatically builds:

```text
Content Editor

├── Posts
├── Authors
└── Categories
```

without us writing:

* forms,
* validation,
* CRUD pages,
* upload systems,
* admin dashboards.

---

# The Big Secret Of CMS Architecture

Most beginners think:

```text
Build Website
       ↓
Add CMS
```

Experienced architects think:

```text
Model Domain
       ↓
Create Content
       ↓
Build Website
```

Because:

```text
Bad Content Model
        =
Bad Website
```

---

# Mental Model To Remember Forever

A schema is not code.

A schema is not a form.

A schema is not a database table.

A schema is:

```text
A description of reality.
```

Or more specifically:

```text
Reality
      ↓
Content Model
      ↓
Database
      ↓
API
      ↓
Frontend
```

This is one of the most important ideas in software architecture.

---

# Up Next

In **Part 9**, we'll connect **Next.js 16** to **Sanity** and learn:

* what `next-sanity` actually does,
* what environment variables are,
* how the Sanity client works,
* what `createClient()` really creates,
* and how modern applications communicate with external systems.
