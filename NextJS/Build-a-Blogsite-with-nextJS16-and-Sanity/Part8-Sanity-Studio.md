# **✅ Part 8 — Understanding Sanity Studio**

# GreyMatter Journal

## Part 8 — Understanding Sanity Studio: Why Content Modeling Is More Important Than Writing Code

> **Goal of this lesson:** Explore the Sanity Studio, understand schemas, documents, and references, and discover why designing your content model is one of the most important architectural decisions you'll make when building a content platform.

---

# Congratulations — You Now Have Two Applications

After running:

```bash
npx sanity@latest init
```

your repository changed fundamentally.

Before:

```text
greymatter-journal/

└── app/
```

After:

```text
greymatter-journal/

├── app/
└── studio/
```

Most beginners see:

```text
Two folders
```

Professional engineers see:

```text
Two applications
```

More specifically:

```text
Reader Application
            +
Editorial Application
```

These applications serve different users:

```text
Readers
       ↓
Next.js

Editors
       ↓
Sanity Studio
```

This separation is one of the most important architectural decisions in modern content systems.

---

# Understanding The Two Systems

Our architecture now looks like this:

```text
Writers
      ↓

Sanity Studio
      ↓

Content Lake
      ↓

API
      ↓

Next.js
      ↓

Readers
```

Notice something important.

The editor never touches the frontend.

The frontend never edits the content.

Each system has a single responsibility.

---

# Exploring The `studio/` Folder

Your generated studio will look something like this:

```text
studio/

├── sanity.config.ts
├── sanity.cli.ts
│
├── schemaTypes/
│   └── index.ts
│
├── package.json
├── tsconfig.json
└── node_modules/
```

At first glance, this resembles another React application.

That's because it is.

---

# Sanity Studio Is Actually A React Application

Many beginners think:

```text
Sanity
      =
Database
```

This is only partially true.

Sanity Studio itself is a React application that provides:

```text
Forms

Editors

Validation

Relationships

Publishing

Media Management

Content Navigation
```

Visually:

```text
React Application
          ↓

Content Editor
          ↓

Content Lake
```

In other words:

> Sanity Studio is the user interface for your data model.

---

# Running The Studio

Navigate into the studio directory:

```bash
cd studio
npm run dev
```

Open:

```text
http://localhost:3333
```

You now have two development servers running:

```text
localhost:3000
        ↓
Reader Experience

localhost:3333
        ↓
Editor Experience
```

This separation mirrors how real production systems operate.

---

# The Biggest Beginner Mistake

When building content applications, beginners often start by designing pages.

For example:

```text
Homepage

About Page

Blog Page

Contact Page
```

Professional engineers rarely begin here.

Instead they ask:

> What information exists in the business domain?

This is called:

```text
Domain Modeling
```

Or:

```text
Content Modeling
```

---

# Content Modeling Before Coding

Before writing a single line of frontend code, we should ask:

```text
What things exist?
```

For GreyMatter Journal, we identify:

```text
Post

Author

Category
```

Immediately we can begin describing reality.

---

# The First Version Of Our Domain Model

Our application contains:

```text
Authors

Categories

Posts
```

Visually:

```text
          Post
             │
             │
     ┌───────┴───────┐
     │               │
 Author         Category
```

This is already architecture.

Because architecture is fundamentally:

```text
Relationships
```

---

# Understanding Documents

In Sanity, everything is stored as a document.

For example:

```json
{
  "_type": "author",
  "name": "Sean Wong",
  "bio": "Software architect"
}
```

Or:

```json
{
  "_type": "category",
  "title": "Next.js"
}
```

Or:

```json
{
  "_type": "post",
  "title": "Understanding RSC"
}
```

You can think of documents as:

```text
Objects
        +
Persistence
        +
Relationships
```

---

# Understanding Schemas

If documents represent data,

then schemas represent rules.

For example:

```text
Document
        =
Reality

Schema
        =
Description of Reality
```

A schema answers questions like:

```text
What fields exist?

What types exist?

What relationships exist?

What validations exist?
```

---

# Creating Our First Schema

Let's begin with categories.

Create:

```text
studio/schemaTypes/category.ts
```

```typescript
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
        type: "string",
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

Let's analyze what happened.

---

# Understanding `defineType`

This line:

```typescript
defineType({
  ...
})
```

means:

> Create a new content type.

In our case:

```text
Category
```

becomes a first-class entity inside our system.

---

# Understanding Document Types

This line:

```typescript
type: "document"
```

tells Sanity:

> This thing should be stored independently.

Examples:

```text
Post

Author

Category
```

all become top-level documents.

---

# Understanding Fields

Fields describe the structure of the document.

For example:

```typescript
fields: [
  {
    name: "title",
    type: "string",
  },
];
```

creates:

```text
Category

    Title
```

Likewise:

```typescript
{
  name: "description",
  type: "text",
}
```

creates:

```text
Category

    Description
```

---

# Understanding Slugs

One of the most important fields is:

```typescript
{
  name: "slug",
  type: "slug",
}
```

This transforms:

```text
React Server Components
```

into:

```text
react-server-components
```

which eventually becomes:

```text
/posts/react-server-components
```

Slugs connect:

```text
Content
        ↓

URLs
        ↓

Routing
```

---

# Our Future Author Schema

We'll eventually create:

```text
Author
```

containing:

```text
Name

Slug

Biography

Profile Image

Social Links
```

Visually:

```text
Author

├── name
├── slug
├── bio
└── image
```

---

# Our Future Post Schema

Our most important document will be:

```text
Post
```

containing:

```text
Title

Slug

Excerpt

Body

Author

Categories

Hero Image

Published Date
```

Visually:

```text
Post

├── title
├── slug
├── excerpt
├── body
├── author
├── categories
├── heroImage
└── publishedAt
```

---

# Content Modeling Is Relationship Modeling

Most beginners think:

```text
Fields
```

Professional engineers think:

```text
Relationships
```

For example:

```text
One Author
        ↓
Many Posts
```

and:

```text
One Post
        ↓
Many Categories
```

Visually:

```text
          Post
             │
             │
     ┌───────┴───────┐
     │               │
 Author         Category
```

These relationships determine:

```text
Queries

Performance

Scalability

Features

Maintainability
```

---

# Registering Schemas

Eventually, we'll register all schemas in:

```text
studio/schemaTypes/index.ts
```

```typescript
import { authorType }
  from "./author";

import { categoryType }
  from "./category";

import { postType }
  from "./post";

export const schemaTypes = [
  authorType,
  categoryType,
  postType,
];
```

This becomes the master description of our content domain.

---

# Schemas Are Surprisingly Similar To TypeScript

Earlier, we learned:

```typescript
interface Post {
  title: string;
}
```

describes:

```text
Application Data
```

Now we're learning:

```typescript
defineType({
  name: "post",
})
```

describes:

```text
Persistent Data
```

Visually:

```text
TypeScript
          ↓
Application Contracts

Sanity Schemas
          ↓
Content Contracts
```

Both solve the same problem:

> Describing reality.

---

# Why Content Modeling Is Architecture

Many developers believe architecture starts with:

```text
Frameworks

Microservices

Databases

Cloud Platforms
```

In reality, architecture often starts much earlier:

```text
What things exist?

How do they relate?

What rules govern them?
```

Because once you define:

```text
Post

Author

Category
```

you have already defined:

```text
Relationships

Responsibilities

Boundaries

Constraints
```

In other words:

```text
You have already defined the architecture.
```

---

# The Correct Mental Model

Beginners think:

```text
CMS
      =
Admin Panel
```

Professional engineers think:

```text
CMS
      =
Domain Model
      +
Relationships
      +
Contracts
      +
Business Reality
```

Or, even more fundamentally:

```text
Content Model
          =
Business Model
```

---

# The Most Important Idea To Remember

Writing code is usually not the hardest part of building software.

Understanding reality is.

And content modeling is simply the process of answering one question:

> What does reality look like in this system?

Everything else—queries, APIs, pages, components, caching, and rendering—follows from that answer.

---

# Up Next — Part 9: Connecting Next.js to Sanity

Next, we'll finally connect our two applications.

We'll learn:

* Environment variables
* `next-sanity`
* Creating the Sanity client
* Authentication tokens
* API configuration
* Why clients are infrastructure, not business logic
