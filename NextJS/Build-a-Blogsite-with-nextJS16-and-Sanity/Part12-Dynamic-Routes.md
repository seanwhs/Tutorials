# **✅ Part 12 — Building Dynamic Article Pages**

---

# GreyMatter Journal  
## Part 12 — Building Dynamic Article Pages: Routes, Parameters, and Tree Traversal

> **Goal of this lesson:** Create individual article pages using dynamic routes and understand how Next.js routing really works.

---

### From List to Detail View

Our homepage now shows a list of posts. Clicking a title should take readers to the full article.

---

### Step 1: Update PostCard Links

Make sure your `PostCard` links to the correct dynamic route:

```tsx
<Link 
  href={`/posts/${post.slug.current}`}
  className="hover:underline"
>
  {post.title}
</Link>
```

---

### Step 2: Create the Dynamic Route

Create the folder structure:

```bash
mkdir -p app/posts/[slug]
```

Then create `app/posts/[slug]/page.tsx`:

```tsx
import { client } from "@/lib/sanity";
import { POST_QUERY } from "@/lib/queries";
import { notFound } from "next/navigation";

export default async function PostPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;

  const post = await client.fetch(POST_QUERY, { slug });

  if (!post) {
    notFound();
  }

  return (
    <article className="max-w-3xl mx-auto px-6 py-12 prose prose-lg">
      <header className="mb-12">
        <h1 className="text-5xl font-bold tracking-tight mb-4">
          {post.title}
        </h1>
        
        <div className="flex items-center gap-4 text-sm text-gray-500">
          <span>By {post.author.name}</span>
          <span>•</span>
          <time dateTime={post.publishedAt}>
            {new Date(post.publishedAt).toLocaleDateString("en-US", {
              year: "numeric",
              month: "long",
              day: "numeric",
            })}
          </time>
        </div>
      </header>

      <div>
        <p className="text-xl text-gray-600 mb-10">{post.excerpt}</p>
        {/* Body will be rendered next */}
      </div>
    </article>
  );
}
```

---

### Step 3: Add the Single Post Query

Update `lib/queries.ts`:

```typescript
export const POST_QUERY = `
  *[
    _type == "post" && 
    slug.current == $slug
  ][0] {
    _id,
    title,
    excerpt,
    body,
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

### How Dynamic Routes Work

The folder `[slug]` tells Next.js:
- This part of the URL is dynamic
- Capture its value and pass it as `params.slug`

**Routing as Tree Traversal:**

Next.js walks your `app/` folder tree to match URLs.

**Example:**

URL: `/posts/understanding-react-server-components`

→ Matches `app/posts/[slug]/page.tsx`  
→ `params.slug = "understanding-react-server-components"`

---

### Mental Model To Remember Forever

**Modern Routing:**

```text
URL
   ↓
Route Parameters
   ↓
Data Fetching
   ↓
Component
   ↓
UI
```

Routing is fundamentally **tree traversal** over your file system.

---

### Up Next — Part 13: Rendering Portable Text

We’ll tackle rich content rendering:
- What Portable Text actually is
- Building a custom Portable Text renderer
- Handling headings, paragraphs, lists, and more
- Why structured content is superior to raw HTML
