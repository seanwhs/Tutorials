# **✅ Part 12 — Building Dynamic Article Pages**

---

# GreyMatter Journal

## Part 12 — Building Dynamic Article Pages: Routes, Parameters, and Tree Traversal

> **Goal of this lesson:** Create individual article pages using dynamic routes and understand how Next.js routing really works.

---

### From List to Detail View

Our homepage now shows a list of posts.

Clicking a title should take readers to the full article.

```text id="h5r8qp"
Homepage
    ↓
Post List
    ↓
Individual Article
```

This transition—from collections to individual resources—is one of the fundamental patterns of web applications.

---

### Step 1: Update PostCard Links

Make sure your `PostCard` links to the correct dynamic route:

```tsx id="p4m7ws"
<Link
  href={`/posts/${post.slug.current}`}
  className="hover:underline"
>
  {post.title}
</Link>
```

When rendered, this becomes:

```text id="z9k3vt"
/posts/understanding-react-server-components
```

or:

```text id="w2f6rm"
/posts/why-nextjs-matters
```

---

### Step 2: Create the Dynamic Route

Create the folder structure:

```bash id="u8p2nx"
mkdir -p app/posts/[slug]
```

Then create:

```text id="g4r7kc"
app/posts/[slug]/page.tsx
```

```tsx id="n3v8qm"
import { client } from "@/lib/sanity";
import { POST_QUERY } from "@/lib/queries";
import { notFound } from "next/navigation";

export default async function PostPage({
  params,
}: {
  params: Promise<{
    slug: string;
  }>;
}) {
  const { slug } =
    await params;

  const post =
    await client.fetch(
      POST_QUERY,
      { slug }
    );

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
          <span>
            By {post.author.name}
          </span>

          <span>•</span>

          <time
            dateTime={
              post.publishedAt
            }
          >
            {new Date(
              post.publishedAt
            ).toLocaleDateString(
              "en-US",
              {
                year:
                  "numeric",
                month:
                  "long",
                day:
                  "numeric",
              }
            )}
          </time>
        </div>
      </header>

      <div>
        <p className="text-xl text-gray-600 mb-10">
          {post.excerpt}
        </p>

        {/* Body rendered in Part 13 */}
      </div>
    </article>
  );
}
```

---

### Step 3: Add the Single Post Query

Update:

```text id="r7m4wy"
lib/queries.ts
```

```typescript id="k2p9vx"
export const
  POST_QUERY = `
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

The folder:

```text id="f9q3rm"
[slug]
```

tells Next.js:

* This URL segment is dynamic
* Capture its value
* Pass it to the page component

For example:

```text id="d6k8wp"
/posts/understanding-react-server-components
```

becomes:

```typescript id="m4v7qy"
params = {
  slug:
    "understanding-react-server-components"
};
```

---

### Dynamic Segments Are Variables

Think of:

```text id="q2r5nb"
posts/[slug]
```

as:

```text id="s8k4mp"
posts/{variable}
```

or:

```text id="z5p7rc"
/posts/:slug
```

from other frameworks.

Examples:

| URL                              | Value of `slug`             |
| -------------------------------- | --------------------------- |
| `/posts/hello-world`             | `"hello-world"`             |
| `/posts/nextjs-16`               | `"nextjs-16"`               |
| `/posts/react-server-components` | `"react-server-components"` |

---

### How Next.js Finds the Route

Suppose the browser requests:

```text id="t4m9qy"
/posts/understanding-react-server-components
```

Next.js walks the `app/` directory:

```text id="y7p2vk"
app/
├── page.tsx
├── about/
├── posts/
│   ├── page.tsx
│   └── [slug]/
│       └── page.tsx
```

The routing engine performs something similar to:

```text id="e3r6wf"
Look for "posts"
         ↓
Found
         ↓
Look for
"understanding-react-server-components"
         ↓
No exact match
         ↓
Found [slug]
         ↓
Capture value
         ↓
Render page.tsx
```

---

### Routing Is Tree Traversal

One of the deepest ideas in the App Router is that routing is fundamentally a tree traversal problem.

```text id="j5v8xp"
URL
  ↓
Segment
  ↓
Folder
  ↓
Segment
  ↓
Folder
  ↓
Page
```

Example:

```text id="u2m7qc"
/posts/react/hooks
```

becomes:

```text id="p8k4vy"
app
 ↓
posts
 ↓
react
 ↓
hooks
```

This is why the App Router feels so natural:

```text id="c4q9rm"
Folder Structure
         =
Application Structure
```

---

### Why `params` Is a Promise

In Next.js 16, route parameters are asynchronous:

```tsx id="v6r2wn"
export default async function Page({
  params,
}: {
  params:
    Promise<{
      slug: string;
    }>;
}) {
  const { slug } =
    await params;
}
```

This allows Next.js to integrate routing with:

* Streaming
* React Server Components
* Suspense
* Partial rendering
* Future rendering optimizations

Although it may look unusual at first, treating route data as asynchronous enables a more flexible rendering pipeline.

---

### Styling Long-Form Content

Our article page uses:

```tsx id="b9m4qx"
className="
  prose
  prose-lg
"
```

Soon, we'll extend our global typography system in:

```text id="a3p7kv"
app/globals.css
```

For example:

```css id="w5r8nm"
.prose {
  max-width: 70ch;
}
```

Later we'll add:

```css id="n7q2xp"
pre {
  overflow-x: auto;
  padding: 1rem;
}

code {
  font-family:
    "JetBrains Mono",
    monospace;
}
```

This helps create the clean, highly readable experience that defines GreyMatter Journal.

---

### Mental Model To Remember Forever

**Traditional thinking:**

```text id="m8k5rw"
URL
   ↓
Page
```

**Modern thinking:**

```text id="h4q7yp"
URL
   ↓
Route Parameters
   ↓
Data Fetching
   ↓
React Tree
   ↓
UI
```

And underneath it all:

```text id="r2v9kc"
Routing
     =
Tree Traversal
```

---

### Up Next — Part 13: Rendering Portable Text

We'll tackle rich content rendering:

* What Portable Text actually is
* Building a custom Portable Text renderer
* Handling headings, paragraphs, lists, images, and code blocks
* Extending our typography system in `globals.css`
* Why structured content is superior to raw HTML
