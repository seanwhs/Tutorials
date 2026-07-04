# **✅ Part 8 — Understanding Sanity Studio**

---

# GreyMatter Journal  
## Part 8 — Understanding Sanity Studio: Why Content Modeling Is More Important Than Writing Code

> **Goal of this lesson:** Explore the Sanity Studio, understand schemas, and learn why designing your content model is one of the most important decisions in building a content platform.

---

### You Now Have Two Applications

After running `npx sanity@latest init`, your project contains two distinct applications:

- **`app/`** → Next.js frontend for **readers**
- **`studio/`** → Sanity Studio for **writers & editors**

This separation is intentional and powerful.

---

### Exploring the `studio/` Folder

```text
studio/
├── sanity.config.ts
├── schemaTypes/
├── package.json
└── tsconfig.json
```

The Studio itself is a **React application** that connects to your Content Lake.

---

### Run the Studio

```bash
cd studio
npm run dev
```

Open `http://localhost:3333`

You now have two development servers running:
- Next.js (`3000`) — Readers
- Sanity Studio (`3333`) — Editors

---

### Content-First Thinking

Most beginners design **pages** first.

Professional content systems design **content** first.

**Key question:**

> What types of content exist in my business?

For GreyMatter Journal:

- **Post**
- **Author**
- **Category**

---

### Content Modeling = Domain Modeling

Our planned model:

```text
          Post
       ┌────────┐
       │ Title  │
       │ Body   │
       └────┬───┘
            │
   references
            │
     ┌──────┴──────┐
     │             │
   Author       Category
```

**Relationships matter**:
- One Author → Many Posts
- One Post → Multiple Categories

---

### Creating Schemas

**Category** (`schemas/category.ts`):

```typescript
import { defineField, defineType } from "sanity";

export const categoryType = defineType({
  name: "category",
  title: "Category",
  type: "document",
  fields: [
    defineField({ name: "title", type: "string" }),
    defineField({
      name: "slug",
      type: "slug",
      options: { source: "title" },
    }),
    defineField({ name: "description", type: "text" }),
  ],
});
```

Similar schemas for `author` and `post`.

Register them in `schemaTypes/index.ts`.

---

### Mental Model To Remember Forever

**Content modeling is more important than writing code.**

A good model:
- Reduces duplication
- Enables relationships
- Supports future features
- Reflects real business concepts

Schemas are **contracts** describing reality — very similar to TypeScript types.

---

### Up Next — Part 9: Connecting Next.js to Sanity

We’ll install `next-sanity`, set up environment variables, create the client, and finally connect the two systems.
