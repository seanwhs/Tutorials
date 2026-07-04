# **✅ Part 11 — Building Our First Real Blog Homepage**

---

# GreyMatter Journal  
## Part 11 — Building Our First Real Blog Homepage: Turning Content Into User Interfaces

> **Goal of this lesson:** Build a dynamic homepage that displays real posts from Sanity and understand how Server Components transform data into UI.

---

### Everything Comes Together

We now have content in Sanity. Let’s build the homepage readers will see.

---

### Step 1: Create the Query

Create `lib/queries.ts`:

```typescript
export const POSTS_QUERY = `
  *[_type == "post"]
  | order(publishedAt desc)
  {
    _id,
    title,
    slug,
    excerpt,
    publishedAt,
    author->{
      name
    },
    categories[]->{
      title
    }
  }
`;
```

---

### Step 2: Create PostCard Component

Create `components/posts/PostCard.tsx`:

```tsx
import Link from "next/link";

type Post = {
  _id: string;
  title: string;
  slug: { current: string };
  excerpt: string;
  publishedAt: string;
  author: { name: string };
  categories: { title: string }[];
};

export default function PostCard({ post }: { post: Post }) {
  return (
    <article className="border border-gray-200 rounded-2xl p-8 hover:shadow-lg transition">
      <div className="flex gap-2 mb-4">
        {post.categories.map((cat) => (
          <span
            key={cat.title}
            className="text-xs uppercase tracking-widest text-blue-600"
          >
            {cat.title}
          </span>
        ))}
      </div>

      <Link href={`/posts/${post.slug.current}`}>
        <h2 className="text-3xl font-bold tracking-tight mb-4 hover:underline">
          {post.title}
        </h2>
      </Link>

      <p className="text-gray-600 mb-6 line-clamp-3">{post.excerpt}</p>

      <div className="text-sm text-gray-500">
        By {post.author.name} •{" "}
        {new Date(post.publishedAt).toLocaleDateString()}
      </div>
    </article>
  );
}
```

---

### Step 3: Build the Homepage

Update `app/(site)/page.tsx`:

```tsx
import { client } from "@/lib/sanity";
import { POSTS_QUERY } from "@/lib/queries";
import PostCard from "@/components/posts/PostCard";

export default async function HomePage() {
  const posts = await client.fetch(POSTS_QUERY);

  return (
    <div className="max-w-4xl mx-auto px-6 py-12">
      <div className="text-center mb-16">
        <h1 className="text-6xl font-bold tracking-tight mb-6">
          GreyMatter Journal
        </h1>
        <p className="text-xl text-gray-600 max-w-md mx-auto">
          Exploring software engineering, systems thinking, and architecture.
        </p>
      </div>

      <section>
        <h2 className="text-3xl font-semibold mb-10">Latest Articles</h2>

        {posts.length === 0 ? (
          <p className="text-center py-12 text-gray-500">No posts yet.</p>
        ) : (
          <div className="space-y-12">
            {posts.map((post: any) => (
              <PostCard key={post._id} post={post} />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
```

---

### Mental Model To Remember Forever

**Modern React:**

```text
Data (from Sanity)
     ↓
Server Component
     ↓
React Elements
     ↓
HTML
```

React components are functions that turn data into user interfaces.

---

### Up Next — Part 12: Dynamic Article Pages

We’ll build individual post pages with dynamic routes (`[slug]`).
