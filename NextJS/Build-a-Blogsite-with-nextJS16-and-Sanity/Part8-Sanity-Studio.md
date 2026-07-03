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

**Next.js** = Presentation layer  
**Sanity Studio** = Content layer

---

### Exploring the `studio/` Folder

```text
studio/
├── sanity.config.ts          # Studio configuration
├── schemaTypes/              # Content model definitions
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

You now have two development servers running simultaneously:
- Next.js on port 3000 (readers)
- Sanity Studio on port 3333 (editors)

---

### Content-First Thinking

Most beginners design **pages** first.

Professional content platforms design **content** first.

**Key Question Sanity asks:**
> What *types* of content exist in your business?

For GreyMatter Journal, we define:

- **Post**
- **Author**
- **Category**

---

### Content Modeling = Domain Modeling

Here’s our planned model:

```text
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

**Relationships** are key:
- One Author → Many Posts
- One Post → Multiple Categories
- Changing an author’s bio updates everywhere automatically

---

### Creating the Schemas

Inside `studio/schemaTypes/`, create these files:

#### 1. `category.ts`

```typescript
import { defineField, defineType } from "sanity";

export const categoryType = defineType({
  name: "category",
  title: "Category",
  type: "document",
  fields: [
    defineField({ name: "title", title: "Title", type: "string" }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title" },
    }),
    defineField({ name: "description", title: "Description", type: "text" }),
  ],
});
```

#### 2. `author.ts` and `post.ts` (similar structure)

I can provide the full code for `author.ts` and `post.ts` if needed — they follow the same pattern with references between documents.

---

### Register Schemas

Update `studio/schemaTypes/index.ts`:

```typescript
import { postType } from "./post";
import { authorType } from "./author";
import { categoryType } from "./category";

export const schemaTypes = [postType, authorType, categoryType];
```

After saving, the Studio automatically updates with new content types.

---

### Mental Model To Remember Forever

> **Content modeling is more important than writing code.**

A good content model:
- Reduces duplication
- Enables powerful relationships
- Makes future features easier
- Reflects your actual business/domain

**Bad model → Painful website**  
**Good model → Flexible, maintainable system**

Schemas are **contracts** describing your reality — very similar to TypeScript types.

---

### Up Next — Part 9: Connecting Next.js to Sanity

We’ll:
- Install `next-sanity`
- Set up environment variables
- Create the Sanity client
- Learn how Next.js fetches content from the Content Lake

This is where the two systems start working together.
