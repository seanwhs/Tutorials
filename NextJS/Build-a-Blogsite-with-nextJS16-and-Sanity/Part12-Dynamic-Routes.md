# **✅ Part 12 — Building Dynamic Article Pages**

---

# GreyMatter Journal

## Part 12 — Building Dynamic Article Pages: Routes, Parameters, and Tree Traversal

> **Goal of this lesson:** Build individual article pages using dynamic routes, understand how Next.js routing really works, and learn why routing in modern applications is fundamentally a problem of tree traversal.

---

## From Collections to Individual Resources

Our homepage now displays a collection of articles.

The next step is allowing readers to navigate from a list of posts to an individual article page.

```text
Homepage
    ↓
List of Posts
    ↓
Individual Post
```

This pattern appears everywhere in software:

```text
Products
    ↓
Product Detail

Users
    ↓
User Profile

Movies
    ↓
Movie Detail

Articles
    ↓
Article Page
```

What changes is the data.

The architectural pattern remains the same.

---

## Step 1 — Update the Post Links

Our `PostCard` component already displays the post title.

Now we'll make each title clickable.

```tsx
import Link from "next/link";

<Link
  href={`/posts/${post.slug.current}`}
  className="hover:underline"
>
  {post.title}
</Link>
```

If a post has the slug:

```text
understanding-react-server-components
```

the generated URL becomes:

```text
/posts/understanding-react-server-components
```

Similarly:

```text
why-nextjs-matters
```

becomes:

```text
/posts/why-nextjs-matters
```

This URL structure is important because URLs become part of your application's public API.

Good URLs should be:

* Readable
* Predictable
* Stable
* SEO-friendly

---

## Step 2 — Create the Dynamic Route

Create the route folder:

```bash
mkdir -p app/'(site)'/posts/[slug]
```

Our application structure now becomes:

```text
app/
├── layout.tsx
├── globals.css
└── (site)/
    ├── page.tsx
    └── posts/
        ├── page.tsx
        └── [slug]/
            └── page.tsx
```

Notice something important:

```text
(site)
```

does not appear in the URL.

The route:

```text
app/(site)/posts/[slug]/page.tsx
```

still produces:

```text
/posts/my-article
```

This is because route groups exist purely for organization.

---

## Step 3 — Create the Article Page

Create:

```text
app/(site)/posts/[slug]/page.tsx
```

```tsx
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
  const { slug } = await params;

  const post = await client.fetch(
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

          <time dateTime={post.publishedAt}>
            {new Date(
              post.publishedAt
            ).toLocaleDateString(
              "en-US",
              {
                year: "numeric",
                month: "long",
                day: "numeric",
              }
            )}
          </time>
        </div>
      </header>

      <div>
        <p className="text-xl text-gray-600 mb-10">
          {post.excerpt}
        </p>

        {/* Portable Text in Part 13 */}
      </div>
    </article>
  );
}
```

---

## Step 4 — Create the Post Query

Update:

```text
lib/queries.ts
```

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

Let's understand what's happening.

```groq
slug.current == $slug
```

means:

> Find the post whose slug matches the value passed from the URL.

If the URL is:

```text
/posts/why-nextjs-matters
```

then:

```text
$slug
       =
why-nextjs-matters
```

---

## How Dynamic Routes Work

The folder:

```text
[slug]
```

tells Next.js:

```text
This segment of the URL
is not fixed.
```

Instead:

```text
Capture whatever appears here
and provide it to the page.
```

Example:

```text
/posts/react-server-components
```

produces:

```typescript
{
  slug:
    "react-server-components"
}
```

Likewise:

```text
/posts/why-nextjs-matters
```

becomes:

```typescript
{
  slug:
    "why-nextjs-matters"
}
```

---

## Dynamic Segments Are Variables

You can mentally translate:

```text
posts/[slug]
```

into:

```text
posts/{variable}
```

or:

```text
/posts/:slug
```

if you've used other frameworks.

Examples:

| URL                              | Captured Value              |
| -------------------------------- | --------------------------- |
| `/posts/hello-world`             | `"hello-world"`             |
| `/posts/nextjs-16`               | `"nextjs-16"`               |
| `/posts/react-server-components` | `"react-server-components"` |

---

## How Next.js Finds the Route

Suppose a reader visits:

```text
/posts/understanding-react-server-components
```

Next.js walks the application tree:

```text
app/
├── layout.tsx
└── (site)/
    └── posts/
        └── [slug]/
            └── page.tsx
```

Internally, the router performs something conceptually similar to:

```text
Find "posts"
         ↓
Found
         ↓
Find
"understanding-react-server-components"
         ↓
No exact folder exists
         ↓
Found [slug]
         ↓
Capture value
         ↓
Render page.tsx
```

---

## Routing Is Really Tree Traversal

One of the deepest ideas in the App Router is this:

```text
Routing
      =
Tree Traversal
```

The browser URL:

```text
/posts/react/hooks
```

becomes:

```text
app
 ↓
posts
 ↓
react
 ↓
hooks
```

This explains why file-system routing feels so natural.

Your application architecture becomes:

```text
Folder Structure
         =
Application Structure
```

---

## Dynamic Routes and Persistent UI

Remember what we learned in Part 2:

Modern applications are not collections of pages.

They are persistent UI trees.

When navigating from:

```text
/posts/why-nextjs-matters
```

to:

```text
/posts/react-server-components
```

Next.js does not destroy the entire application.

Instead:

```text
Root Layout
       ↓
Site Layout
       ↓
Posts Layout
       ↓
Article Page
```

only the article page changes.

Everything else remains mounted.

This provides:

* Faster navigation
* Less JavaScript execution
* Preserved state
* Better user experience

This is one of the major reasons modern applications feel "native."

---

## Why Is `params` a Promise?

You may have noticed:

```tsx
params: Promise<{
  slug: string;
}>
```

instead of:

```tsx
params: {
  slug: string;
}
```

In Next.js 16, route parameters are asynchronous.

```tsx
const { slug } =
  await params;
```

This enables integration with:

* React Server Components
* Streaming
* Suspense
* Partial rendering
* Future rendering optimizations

Although it initially feels strange, asynchronous routing gives Next.js a much more flexible rendering pipeline.

---

## Styling Long-Form Content

Our article page currently uses:

```tsx
className="
  prose
  prose-lg
"
```

As GreyMatter Journal evolves, we'll gradually build our typography system inside:

```text
app/globals.css
```

For example:

```css
.prose {
  max-width: 70ch;
}
```

Later we'll extend this further:

```css
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

This typography layer is one of the key ingredients behind highly readable technical publications.

---

## A Preview of Static Generation

Later in this series, we'll optimize article pages using:

```tsx
export async function generateStaticParams() {
  const slugs =
    await client.fetch(`
      *[_type == "post"]{
        "slug": slug.current
      }
    `);

  return slugs;
}
```

This allows Next.js to:

```text
Build Time
      ↓
Generate HTML
      ↓
Deploy to CDN
      ↓
Serve Globally
```

For content-heavy websites like blogs, this provides:

* Better SEO
* Faster page loads
* Lower infrastructure costs
* Greater reliability

We'll explore this in depth when we study rendering strategies and caching.

---

## Mental Model To Remember Forever

**Traditional thinking:**

```text
URL
   ↓
Page
```

**Modern thinking:**

```text
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

And underneath everything:

```text
Routing
     =
Tree Traversal
```

---

## Up Next — Part 13: Rendering Portable Text

We'll finally tackle rich content rendering:

* What Portable Text actually is
* Why structured content is superior to HTML
* Building custom Portable Text renderers
* Rendering headings, lists, images, and code blocks
* Extending our typography system in `globals.css`

This is where GreyMatter Journal begins to feel like a real publishing platform.
