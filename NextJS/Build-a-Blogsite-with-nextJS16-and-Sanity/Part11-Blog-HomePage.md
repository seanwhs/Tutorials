# **✅ Part 11 — Building Our First Real Blog Homepage**

---

# GreyMatter Journal  
## Part 11 — Building Our First Real Blog Homepage: Server Components, Data Fetching, and Lists

> **Goal of this lesson:** Create a dynamic homepage that displays real posts from Sanity and understand how Next.js Server Components, data fetching, and React lists work.

---

### Everything Comes Together

We now have layouts, a content system, and a working connection. It’s time to build the homepage that readers will actually see.

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
      name,
      slug
    },
    categories[]->{
      title,
      slug
    }
  }
`;
```

This query fetches the newest posts with resolved relationships.

---

### Step 2: Create the PostCard Component

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
    <article className="border border-gray-200 rounded-xl p-8 hover:shadow-lg transition">
      <div className="flex gap-2 mb-3">
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
        <h2 className="text-3xl font-bold tracking-tight mb-3 hover:underline">
          {post.title}
        </h2>
      </Link>

      <p className="text-gray-600 mb-4 line-clamp-3">{post.excerpt}</p>

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

Update `app/page.tsx`:

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
          Exploring software engineering, systems thinking, and modern architecture.
        </p>
      </div>

      <section>
        <h2 className="text-3xl font-semibold mb-8">Latest Articles</h2>

        {posts.length === 0 ? (
          <p className="text-center text-gray-500 py-12">No posts yet. Start writing in Sanity Studio!</p>
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

### Why `async` Components Work

In **Server Components**, you can use `await` directly inside the component. Next.js handles data fetching on the server before sending HTML to the browser.

This is much simpler than the old `useEffect` + `useState` pattern.

---

### Key Concepts Explained

- **`map()`**: Transforms an array of data into an array of React elements
- **`key` prop**: Helps React efficiently update lists when data changes
- **Conditional Rendering**: Using ternaries (`condition ? A : B`) for empty states
- **Server Components**: Fetch → Render → HTML (no client-side waterfalls)

---

### Mental Model To Remember Forever

**Modern React:**

```text
Data (from Sanity)
     ↓
Server Component (async function)
     ↓
React Elements (UI description)
     ↓
HTML sent to browser
```

React components are **functions that turn data into user interfaces**.

---

### Up Next — Part 12: Dynamic Article Pages

We’ll build individual post pages using dynamic routes (`[slug]`), learn how to fetch a single post, and render rich Portable Text content.
