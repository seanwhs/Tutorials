# **✅ Part 17 — TypeScript, Data Contracts, and Reliable Systems**

---

# GreyMatter Journal  
## Part 17 — TypeScript, Data Contracts, and Building Reliable Software Systems

> **Goal of this lesson:** Replace `any` with proper types, understand why type systems exist, and see how interfaces and generics help build reliable applications.

---

### The Cost of `any`

Using `any` disables TypeScript’s protection. It’s convenient short-term but dangerous as projects grow.

---

### Define Our Domain Types

Create `types/post.ts`:

```typescript
export interface Slug {
  current: string;
}

export interface Author {
  name: string;
  slug?: Slug;
  image?: any; // We'll refine this later
}

export interface Category {
  title: string;
  slug?: Slug;
}

export interface Post {
  _id: string;
  title: string;
  slug: Slug;
  excerpt: string;
  body?: any[]; // Portable Text
  mainImage?: any;
  publishedAt: string;
  author: Author;
  categories: Category[];
}
```

---

### Update Components and Pages

**Example in `PostCard.tsx`:**

```tsx
import { Post } from "@/types/post";

type Props = {
  post: Post;
};

export default function PostCard({ post }: Props) { ... }
```

**In data fetching:**

```tsx
const posts = await client.fetch<Post[]>(POSTS_QUERY);
const post = await client.fetch<Post | null>(POST_QUERY, { slug });
```

---

### Understanding Key TypeScript Concepts

- **Interfaces** → Contracts defining object shapes
- **Union Types** (`Post | null`) → Modeling multiple possibilities
- **Generics** (`<T>`) → Reusable code that works with different types

---

### Mental Model To Remember Forever

**TypeScript’s true purpose:**

> Creating **executable contracts** between different parts of your system.

Software engineering is largely about **managing assumptions**. Types make those assumptions explicit and enforceable.

---

### Up Next — Part 18: Loading States, Error Handling, and Reliability

We’ll implement loading skeletons, error boundaries, and `not-found` pages while exploring how to build resilient applications.
