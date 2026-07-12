## Blog Tutorial - Part 3: Designing Content Schemas

In this part, we will define our content architecture using Sanity’s schema definitions. We will be building five core types: `post`, `author`, `category`, `blockContent` (for rich text), and `comment`.

> **Note:** Sanity schema files use the Sanity SDK and are unaffected by Next.js server/client component boundaries. You can define these freely in your `src/sanity/schemaTypes/` directory.

### Step 1: File Structure

Create the following files in `src/sanity/schemaTypes/`:

* `index.ts` (Registry)
* `post.ts`
* `author.ts`
* `category.ts`
* `blockContent.ts`
* `comment.ts`

### Step 2: Schema Definitions

Create your files with the following code:

**`blockContent.ts`** (Rich Text configuration)

```ts
import { defineType, defineArrayMember } from "sanity";
import { ImageIcon } from "@sanity/icons/Image";

export const blockContent = defineType({
  title: "Block Content",
  name: "blockContent",
  type: "array",
  of: [
    defineArrayMember({
      type: "block",
      styles: [
        { title: "Normal", value: "normal" },
        { title: "H1", value: "h1" },
        { title: "H2", value: "h2" },
        { title: "H3", value: "h3" },
        { title: "Quote", value: "blockquote" },
      ],
      marks: {
        decorators: [
          { title: "Strong", value: "strong" },
          { title: "Emphasis", value: "em" },
          { title: "Code", value: "code" },
        ],
      },
    }),
    defineArrayMember({ type: "image", icon: ImageIcon, options: { hotspot: true } }),
    defineArrayMember({
      type: "object",
      name: "codeBlock",
      title: "Code Block",
      fields: [
        { name: "language", type: "string" },
        { name: "code", type: "text", rows: 10 },
      ],
    }),
  ],
});

```

**`author.ts` & `category.ts**`
*Create these as standard documents.*

* **Author** uses `UserIcon`.
* **Category** uses `TagIcon`.
* Both include `name`, `slug` (auto-generated), and descriptive fields.

**`comment.ts`** (Supporting User Interactions)

```ts
import { defineField, defineType } from "sanity";

const ChatIcon = () => (
  <svg width="1em" height="1em" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
  </svg>
);

export const comment = defineType({
  name: "comment",
  title: "Comment",
  type: "document",
  icon: ChatIcon,
  fields: [
    defineField({ name: "post", type: "reference", to: [{ type: "post" }] }),
    defineField({ name: "userId", type: "string" }),
    defineField({ name: "userName", type: "string" }),
    defineField({ name: "userImageUrl", type: "url" }),
    defineField({ name: "text", type: "text" }),
    defineField({ name: "approved", type: "boolean", initialValue: true }),
    defineField({ name: "createdAt", type: "datetime" }),
  ],
});

```

**`post.ts`**
*Include the fields for `author` (reference), `mainImage`, `categories` (array of references), and `isMembersOnly` (boolean).*

### Step 3: Registering Schemas

Update `src/sanity/schemaTypes/index.ts` to include your new files:

```ts
import { type SchemaTypeDefinition } from "sanity";
import { post } from "./post";
import { author } from "./author";
import { category } from "./category";
import { blockContent } from "./blockContent";
import { comment } from "./comment"; 

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [post, author, category, blockContent, comment],
};

```

### Step 4: Verification

1. **Run Development:** `npm run dev`.
2. **Verify Studio:** Navigate to `/studio`. You should now see **Post**, **Author**, **Category**, and **Comment** in your sidebar.
3. **Test Data:** Create one instance of each type to ensure your validation rules (like `required()`) are working correctly.

---

**Checkpoint ✅**

* [ ] Schema files created and exported.
* [ ] `index.ts` updated with all 5 types.
* [ ] Studio interface reflects the updated data model.
