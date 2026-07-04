# **✅ Part 8 — Understanding Sanity Studio**

---

# GreyMatter Journal

## Part 8 — Understanding Sanity Studio: Why Content Modeling Is More Important Than Writing Code

> **Goal of this lesson:** Explore the Sanity Studio, understand schemas, and learn why designing your content model is one of the most important decisions in building a content platform.

---

### You Now Have Two Applications

After running:

```bash id="j5p8rm"
npx sanity@latest init
```

your project contains two distinct applications:

* **`app/`** → Next.js frontend for **readers**
* **`studio/`** → Sanity Studio for **writers & editors**

This separation is intentional and powerful.

```text id="r7m4tk"
Next.js
     =
Presentation Layer

Sanity Studio
     =
Content Layer
```

---

### Exploring the `studio/` Folder

```text id="c9v2wx"
studio/
├── sanity.config.ts
├── schemaTypes/
├── package.json
└── tsconfig.json
```

| File               | Purpose                               |
| ------------------ | ------------------------------------- |
| `sanity.config.ts` | Configures the Studio application     |
| `schemaTypes/`     | Defines the structure of your content |
| `package.json`     | Studio dependencies                   |
| `tsconfig.json`    | TypeScript configuration              |

The Studio itself is a **React application** that connects to your Content Lake.

This is one of the reasons Sanity feels so different from traditional CMS platforms:

```text id="b6n8qe"
CMS
    ≠
Database

CMS
    =
Application
        +
Database
        +
API
        +
Editor
```

---

### Run the Studio

```bash id="z2q7mk"
cd studio
npm run dev
```

Open:

```text id="p4w9sx"
http://localhost:3333
```

You now have two development servers running simultaneously:

| Application   | Port   | Users             |
| ------------- | ------ | ----------------- |
| Next.js       | `3000` | Readers           |
| Sanity Studio | `3333` | Writers & Editors |

---

### Two Applications, One System

This architecture can initially feel strange.

Most beginners expect:

```text id="m8r3ky"
One Folder
     ↓
One Application
```

Modern web systems typically look more like:

```text id="q5t2nb"
Content System
        ↓
Rendering System
        ↓
Users
```

For GreyMatter Journal:

```text id="w7k6rp"
Writers
    ↓
Sanity Studio
    ↓
Content Lake
    ↓
Next.js
    ↓
Readers
```

---

### Content-First Thinking

Most beginners design **pages** first.

```text id="e2m5vf"
Homepage

About Page

Blog Page

Contact Page
```

Professional content platforms design **content** first.

The key question Sanity asks is:

> **What types of content exist in your business?**

For GreyMatter Journal, we define:

* **Post**
* **Author**
* **Category**

Later we might add:

* Comments
* Likes
* Newsletter issues
* Tags
* Series
* Featured content

---

### Content Modeling = Domain Modeling

Before writing code, we model the business domain.

Our planned model looks like this:

```text id="h4p8zc"
          Post
       ┌────────┐
       │ Title  │
       │ Slug   │
       │ Body   │
       └────┬───┘
            │
   references
            │
     ┌──────┴──────┐
     │             │
   Author       Category
```

Relationships are the key to scalable content systems.

Examples:

```text id="t9m6qx"
One Author
        ↓
Many Posts


One Category
        ↓
Many Posts


One Post
        ↓
Many Categories
```

This means:

* Updating an author's biography updates every article automatically.
* Renaming a category updates every article automatically.
* Content relationships remain consistent.

---

### Why Relationships Matter

Imagine storing author information directly inside every article:

```text id="y6r2kv"
Post A
 └── John Smith

Post B
 └── John Smith

Post C
 └── John Smith
```

Now John changes his biography.

You must edit:

```text id="d8w5mp"
Post A
Post B
Post C
...
```

Instead, with references:

```text id="s3k9fy"
Author
  ↑
  │
Post A
Post B
Post C
```

You edit the author once.

This concept is called **normalization**, and it is one of the foundations of scalable software systems.

---

### Creating the Schemas

Inside:

```text id="f7q2jd"
studio/schemaTypes/
```

we'll create our content definitions.

---

#### 1. `category.ts`

```typescript id="n5m8qt"
import {
  defineField,
  defineType,
} from "sanity";

export const categoryType =
  defineType({
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
          source:
            "title",
        },
      }),

      defineField({
        name:
          "description",

        title:
          "Description",

        type:
          "text",
      }),
    ],
  });
```

---

#### 2. `author.ts`

```typescript id="v4p7rm"
import {
  defineField,
  defineType,
} from "sanity";

export const authorType =
  defineType({
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
          source:
            "name",
        },
      }),

      defineField({
        name: "bio",
        title: "Bio",
        type: "text",
      }),

      defineField({
        name: "image",
        title: "Image",
        type: "image",
      }),
    ],
  });
```

---

#### 3. `post.ts`

```typescript id="k8r2vx"
import {
  defineField,
  defineType,
} from "sanity";

export const postType =
  defineType({
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
          source:
            "title",
        },
      }),

      defineField({
        name: "excerpt",
        title: "Excerpt",
        type: "text",
      }),

      defineField({
        name: "author",
        title: "Author",
        type: "reference",
        to: [
          {
            type:
              "author",
          },
        ],
      }),

      defineField({
        name:
          "categories",

        title:
          "Categories",

        type:
          "array",

        of: [
          {
            type:
              "reference",

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
        name:
          "publishedAt",

        title:
          "Published At",

        type:
          "datetime",
      }),

      defineField({
        name:
          "body",

        title:
          "Body",

        type:
          "array",

        of: [
          {
            type:
              "block",
          },
        ],
      }),
    ],
  });
```

---

### Register Schemas

Update:

```text id="u5p9kc"
studio/schemaTypes/index.ts
```

```typescript id="r8v4md"
import {
  postType,
} from "./post";

import {
  authorType,
} from "./author";

import {
  categoryType,
} from "./category";

export const
  schemaTypes = [
    postType,
    authorType,
    categoryType,
  ];
```

After saving, the Studio automatically updates with the new content types.

---

### Schemas Are Contracts

If you've been following our TypeScript discussions, this should feel familiar.

A TypeScript type:

```typescript id="g2w7qy"
type Post = {
  title: string;
  body: string;
};
```

is a contract.

A Sanity schema:

```typescript id="x9m3pv"
defineType({
  name: "post",
  fields: [...]
});
```

is also a contract.

Both answer the same question:

> **What does a valid Post look like?**

---

### Content Modeling Is More Important Than Writing Code

One of the biggest lessons in software engineering is:

```text id="m6q4kt"
Bad model
     ↓
Bad system
```

while:

```text id="w3r8fn"
Good model
     ↓
Flexible system
```

A good content model:

* Reduces duplication
* Enables relationships
* Supports future features
* Simplifies maintenance
* Reflects the real business domain

---

### A Small Preview of What Comes Next

In the next part, we'll finally connect our two applications.

```text id="c7v2wp"
Sanity Studio
        ↓
Content Lake
        ↓
GROQ API
        ↓
Next.js
        ↓
React Server Components
        ↓
Browser
```

This is where GreyMatter Journal starts becoming a real distributed application.

---

### Mental Model To Remember Forever

> **Content modeling is more important than writing code.**

Professional engineers don't begin with:

```text id="p8n5my"
What page
should I build?
```

They begin with:

```text id="z4k7qb"
What reality
am I modeling?
```

Schemas are contracts describing that reality.

---

### Up Next — Part 9: Connecting Next.js to Sanity

We'll:

* Install `next-sanity`
* Configure environment variables
* Create the Sanity client
* Learn how Next.js fetches content from the Content Lake
* Understand how two separate applications become one unified system

This is where the two systems start working together.
