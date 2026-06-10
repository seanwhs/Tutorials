# 🚀 From Zero to Published  
## Part 3: Building a Modern Portfolio Blog with Next.js 16 & Sanity (Continued)

### Part IV–XI: Connecting Next.js and Sanity, Dynamic Routing, Rich Content, Type-Safe Engineering, Performance, SEO, Deployment, and Operating a Real Content Platform

This is the complete continuation of your tutorial, covering **all remaining parts** (IV through XI) in the same beginner-friendly, step-by-step style for developers who know HTML/CSS/JS but are new to React/Next/Sanity.

***

# Part IV

## Connecting Next.js and Sanity

Now you will connect the frontend (Next.js) to the CMS (Sanity).

This is the moment your portfolio blog becomes **truly dynamic**:

* Home page fetches recent posts
* Blog index lists all posts
* Individual post pages are generated from Sanity documents

***

# Chapter 13

## Environment Variables and Security

You will configure environment variables like:

```env
NEXT_PUBLIC_SANITY_PROJECT_ID
NEXT_PUBLIC_SANITY_DATASET
SANITY_API_READ_TOKEN
```

### What are Environment Variables?

Environment variables are like configuration values your app reads at runtime, instead of hard-coding them into your source files.

They are stored in a special file called `.env.local` on your computer, and in your deployment platform's settings (like Vercel) when you deploy.

### Public vs Secret Variables

In Next.js:

* Variables prefixed with `NEXT_PUBLIC_` are **exposed to the browser**.  
  Example: `NEXT_PUBLIC_SANITY_PROJECT_ID`
* Variables **without** that prefix are **server-side only** and not sent to the browser.  
  Example: `SANITY_API_READ_TOKEN`

For Sanity:

* Your project ID and dataset name are public (they don't compromise security).
* Your API tokens are secrets and should **not** be exposed to the browser.

**Common security mistakes:**

* Putting secret tokens in `.env.local` but then accidentally committing them to Git.
* Using `NEXT_PUBLIC_` prefix on secret tokens.
* Hard-coding tokens directly in your source code.

### Creating Your `.env.local` File

In your Next.js project (`my-portfolio-blog`), create a new file in the root:

```text
.env.local
```

Inside, add:

```env
NEXT_PUBLIC_SANITY_PROJECT_ID=your-project-id
NEXT_PUBLIC_SANITY_DATASET=your-dataset
SANITY_API_READ_TOKEN=your-read-token
```

Replace the placeholder values with your actual Sanity project details:

1. Go to your Sanity management dashboard.
2. Open your project.
3. Find your **Project ID** (it's in the project URL or settings).
4. Find your **Dataset** name (often `production` if you used a template).
5. Generate a **Read Token** in the API settings (you only need read access for the public site).

Open your terminal and run:

```bash
npm run dev
```

Next.js will automatically load `.env.local` when the dev server starts.

**Checkpoint:** `.env.local` is loaded

* You should not see any errors about missing environment variables.
* If you do, double-check that:
  * The file is named `.env.local` exactly.
  * It's in the root of your Next.js project (not inside `src`).
  * There are no spaces around `=`.

***

# Chapter 14

## Creating Sanity Clients

A "Sanity client" is a JavaScript object that helps you talk to Sanity's API.

You will build:

* A **public client** for anonymous, cached reads (for the public site).
* A **private client** for authenticated reads (draft mode, preview).

### Installing Sanity Packages

In your Next.js project terminal, install the Sanity client SDK:

```bash
npm install sanity
```

Now create a file to hold your Sanity client configuration.

In `src/`, create a new folder called `lib`, and inside it a file called `sanity.ts`:

```text
src/lib/sanity.ts
```

### Public Client Configuration

Add this to `src/lib/sanity.ts`:

```tsx
import { createClient } from 'sanity'

export const publicClient = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  useCdn: true, // Use the CDN for faster, cached reads
  token: process.env.SANITY_API_READ_TOKEN,
})
```

What this means:

* `projectId`: your Sanity project ID.
* `dataset`: your dataset name (often `production`).
* `useCdn: true`: tells Sanity to use their **Content Delivery Network**, which is faster for public reads and cached.
* `token`: your read token for authentication.

For most public pages (homepage, blog index, article pages), you will use `publicClient`.

### Private Client Configuration

Below the public client, add a private client:

```tsx
export const privateClient = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  useCdn: false, // Use the primary API, not the CDN
  token: process.env.SANITY_API_READ_TOKEN,
})
```

What `useCdn: false` means:

* You get **fresh data**, including drafts if preview mode is enabled.
* This is slower but more up-to-date.
* You use this when you need to see unpublished content (e.g., in preview mode).

### Edge Caching

Sanity's CDN (used when `useCdn: true`) caches your content at edge locations around the world.

This means:

* Readers in different countries get content from a nearby cache.
* Your site loads faster.
* You don't hit Sanity's API as often.

For your portfolio blog, you'll mostly use the public client with `useCdn: true` for performance.

***

# Chapter 15

## Understanding GROQ

Before writing queries, you must understand **GROQ** (Graph-Relational Object Queries).

GROQ is Sanity's query language.

Think of it as a more readable, JSON-flavored version of SQL that's designed specifically for documents instead of rows and tables.

GROQ lets you:

* Filter documents (e.g., only posts)
* Sort them (e.g., by published date)
* Select only the fields you need
* Dereference references (e.g., get the author's name from a post)
* Compute new fields (e.g., build a slug or date string)

### Basic GROQ Structure

A simple query looks like this:

```groq
*[_type == "post"] {
  title,
  slug,
  excerpt,
}
```

Breakdown:

* `*` means "all documents".
* `[_type == "post"]` filters to only documents where `_type` is `"post"`.
* `{ title, slug, excerpt }` is a **projection**: it selects only those fields.

### Filters

You can filter in many ways:

```groq
*[_type == "post" && publishedAt < now] {
  title,
  slug,
  publishedAt,
}
```

This selects posts where `publishedAt` is before the current time (`now`).

### Sorting

Add sorting after the filter:

```groq
*[_type == "post" && publishedAt < now] {
  title,
  slug,
  publishedAt,
} | order(publishedAt desc)
```

* `order(publishedAt desc)` sorts by `publishedAt` in descending order (newest first).

### Projections

Projections select specific fields:

```groq
{
  title,
  slug,
  excerpt,
  body,
}
```

You can also compute fields:

```groq
{
  title,
  slug,
  publishedAtLabel: formatDateTime(publishedAt),
}
```

### References

If your `Post` schema has a reference to `Author`, like:

```ts
{
  name: 'author',
  type: 'reference',
  to: [{ type: 'author' }],
}
```

Then in GROQ you can dereference it:

```groq
{
  title,
  slug,
  author -> { name, bio },
}
```

* `author ->` means "follow the reference and get these fields from the author document".
* `{ name, bio }` selects those fields from the author.

### Parameters

You can pass parameters into queries:

```groq
*[_type == "post" && slug == $slug] {
  title,
  slug,
  body,
}
```

Then in your JS code, you pass `slug` as a parameter.

You'll see this in action when you fetch a single post by its slug.

### GROQ in Practice

You will write GROQ queries in your Next.js code as strings, then pass them to the Sanity client.

Example:

```tsx
const query = `*[_type == "post"] { title, slug } | order(publishedAt desc)`

const posts = await publicClient.fetch(query)
```

You'll build up queries gradually: simple first, then more complex relational queries.

Every symbol and operator will be explained as you go.

***

# Chapter 16

## Fetching Blog Posts

Now you will create queries that fetch real content from Sanity and display it on your portfolio blog.

You will create:

* A **homepage** query to fetch featured or latest posts.
* A **single article** query to fetch a post by its slug.
* A **category** query to fetch posts by category.

### Step 1: Create a Post Query File

In `src/lib/`, create a new file:

```text
src/lib/queries.ts
```

### Step 2: Homepage Query (Latest Posts)

Add this to `queries.ts`:

```tsx
import { publicClient } from './sanity'

const latestPostsQuery = `
  *[_type == "post" && publishedAt < now] {
    title,
    slug,
    excerpt,
    coverImage,
    publishedAt,
    author -> { name }
  } | order(publishedAt desc) [0...6]
`

export async function getLatestPosts() {
  const posts = await publicClient.fetch(latestPostsQuery)
  return posts
}
```

Breakdown:

* `*[_type == "post" && publishedAt < now]` filters to published posts.
* `{ title, slug, ... }` selects specific fields.
* `author -> { name }` dereferences the author reference.
* `| order(publishedAt desc)` sorts newest first.
* `[0...6]` limits to the first 6 posts.

### Step 3: Update Your Homepage

Open `src/app/page.tsx` and update it:

```tsx
import { getLatestPosts } from '../lib/queries'

export default async function Home() {
  const posts = await getLatestPosts()

  return (
    <main>
      <h1>My Portfolio Blog</h1>

      {posts.length === 0 ? (
        <p>No posts yet. Check back soon!</p>
      ) : (
        <section>
          <h2>Latest Posts</h2>
          <ul>
            {posts.map((post: any) => (
              <li key={post.slug}>
                <a href={`/blog/${post.slug}`}>{post.title}</a>
              </li>
            ))}
          </ul>
        </section>
      )}
    </main>
  )
}
```

**Checkpoint:** Homepage shows posts

* Restart your dev server if needed: `npm run dev`.
* Visit `http://localhost:3000`.
* You should see a list of your latest posts from Sanity, with links to each post.

If you don't see any posts:

* Double-check that you published at least one post in Sanity Studio.
* Confirm your environment variables are correct.
* Check your terminal for errors.

### Step 4: Single Article Query

In `queries.ts`, add:

```tsx
const postBySlugQuery = `
  *[_type == "post" && slug == $slug] {
    title,
    slug,
    body,
    coverImage,
    publishedAt,
    author -> { name, bio, profileImage },
    categories -> { name }
  } [0]
`

export async function getPostBySlug(slug: string) {
  const post = await publicClient.fetch(postBySlugQuery, { slug })
  return post
}
```

* `slug == $slug` uses a parameter.
* `{ slug }` after the query passes the parameter.
* `[0]` returns the first match (or `null` if none).

### Step 5: Blog Index Page

Create a new folder and file:

```text
src/app/blog/page.tsx
```

Add:

```tsx
import { getLatestPosts } from '../lib/queries'

export default async function BlogIndex() {
  const posts = await getLatestPosts()

  return (
    <main>
      <h1>All Posts</h1>

      {posts.length === 0 ? (
        <p>No posts yet.</p>
      ) : (
        <ul>
          {posts.map((post: any) => (
            <li key={post.slug}>
              <a href={`/blog/${post.slug}`}>{post.title}</a>
              <p>{post.excerpt}</p>
            </li>
          ))}
        </ul>
      )}
    </main>
  )
}
```

Now you have:

* `/` → homepage with latest posts
* `/blog` → blog index with all posts
* `/blog/{slug}` → single post page (you'll create this next)

***

# Part V

## Dynamic Routing and Content Pages

Now you will build routes like:

```text
/blog/my-first-post
```

and understand:

* Route segments (`app/blog/page.tsx`)
* Dynamic routes (`app/blog/[slug]/page.tsx`)
* Nested routes (e.g., `/blog/category/[slug]`)
* Catch-all routes when needed

### Step 1: Create a Dynamic Route Folder

Inside `src/app/blog/`, create a new folder with square brackets:

```text
src/app/blog/[slug]/page.tsx
```

The folder name `[slug]` is a **dynamic segment**.

### Step 2: Implement the Single Post Page

In `src/app/blog/[slug]/page.tsx`:

```tsx
import { getPostBySlug } from '../../lib/queries'
import Link from 'next/link'

type Props = {
  params: Promise<{ slug: string }>
}

export default async function PostPage(props: Props) {
  const { slug } = await props.params

  const post = await getPostBySlug(slug)

  if (!post) {
    return (
      <main>
        <h1>Post Not Found</h1>
        <Link href="/blog">Back to all posts</Link>
      </main>
    )
  }

  return (
    <main>
      <h1>{post.title}</h1>
      <p>
        By {post.author?.name} on {new Date(post.publishedAt).toLocaleDateString()}
      </p>

      <article>
        {/* You'll render rich body content in Part VI */}
        <p>{post.body}</p>
      </article>

      <Link href="/blog">Back to all posts</Link>
    </main>
  )
}
```

**Checkpoint:** Single post page works

* Visit `http://localhost:3000` and click a post link.
* You should see the post's title, author, date, and body.
* If the post doesn't exist, you'll see "Post Not Found".

At this point, your blog displays **real content from Sanity**.

***

# Part VI

## Rich Content and Images

Now you will render:

* Headings
* Paragraphs
* Lists
* Images
* Links

You will:

* Introduce **Portable Text** and why structured content is superior to raw HTML blobs.
* Build image rendering using the Sanity image pipeline and the Next.js `Image` component.
* Take advantage of CDNs and responsive images for performance.

### What is Portable Text?

Portable Text is Sanity's way of representing rich text (headings, paragraphs, lists, etc.) as structured data instead of raw HTML.

This lets you:

* Render the same content in different ways on different platforms.
* Add custom rendering logic (e.g., different styles for headings).
* Avoid messy HTML strings.

A Portable Text body looks like:

```json
[
  {
    "_type": "block",
    "style": "normal",
    "children": [{ "text": "Hello world" }]
  },
  {
    "_type": "block",
    "style": "h2",
    "children": [{ "text": "Heading 2" }]
  }
]
```

### Step 1: Install Portable Text Renderer

Install the Portable Text renderer:

```bash
npm install @sanity/react-typed
```

(Or use the official Sanity Portable Text package if recommended in their docs.)

### Step 2: Create a Body Renderer Component

In `src/components/`, create:

```text
src/components/BodyRenderer.tsx
```

Add a simple renderer that maps Portable Text blocks to HTML elements:

```tsx
import { Poe } from '@sanity/react-typed'

export function BodyRenderer({ value }: { value: any }) {
  return <Poe value={value} />
}
```

(You'll refine this as you learn more about Portable Text.)

### Step 3: Update Your Post Page

In `src/app/blog/[slug]/page.tsx`, update:

```tsx
import { BodyRenderer } from '../../components/BodyRenderer'

// ... inside component:
<article>
  {post.body ? (
    <BodyRenderer value={post.body} />
  ) : (
    <p>No content yet.</p>
  )}
</article>
```

Now your post body renders as rich content with headings, paragraphs, and lists.

### Images

Sanity provides an image pipeline that:

* Resizes images
* Generates multiple sizes
* Optimizes formats

You combine this with Next.js `<Image>` for responsive images.

Example:

```tsx
import Image from 'next/image'

export function PostCoverImage({ image }: { image: any }) {
  if (!image) return null

  const url = `https://cdn.sanity.io/images/${process.env.NEXT_PUBLIC_SANITY_PROJECT_ID}/${process.env.NEXT_PUBLIC_SANITY_DATASET}/${image.filename}?w=1200&auto=format`

  return (
    <Image
      src={url}
      alt={image.alt || 'Cover image'}
      width={1200}
      height={600}
      style={{ width: '100%', height: 'auto' }}
    />
  )
}
```

You'll add this to your post page and homepage.

***

# Part VII

## Type-Safe Content Engineering

Now you will generate TypeScript types from your Sanity schemas.

This makes your code safer and your editor smarter.

### Step 1: Install Sanity Typegen

In your Next.js project:

```bash
npm install sanity-typegen
```

Then run:

```bash
npx sanity typegen generate
```

This scans your Sanity schemas and generates a TypeScript file, usually:

```text
src/generated/types.ts
```

### What You Get

* TypeScript types for all your documents (Post, Author, Category, etc.).
* Types for your GROQ queries (if configured).
* Better autocompletion in your editor.

### Refactoring Queries with Types

Now your queries can use types:

```tsx
import { Post } from '../../generated/types'

export async function getLatestPosts() {
  const posts = await publicClient.fetch<Post[]>(latestPostsQuery)
  return posts
}
```

Instead of `any`, you now have `Post[]`.

This means:

* Your editor knows what fields exist.
* If you remove a field from your schema, TypeScript will warn you.
* Refactoring is safer.

***

# Part VIII

## Performance Engineering

Now that the blog works, you will make it **fast** and **smooth**.

Topics:

* `Promise.all` and concurrent data fetching
* Streaming and `Suspense` in Next.js 16
* Core Web Vitals:
  * CLS (Cumulative Layout Shift)
  * LCP (Largest Contentful Paint)
  * FCP (First Contentful Paint)
* How these metrics apply to your portfolio blog pages

### Concurrent Fetching

Instead of fetching data one by one:

```tsx
const posts = await getLatestPosts()
const categories = await getCategories()
```

You can fetch in parallel:

```tsx
const [posts, categories] = await Promise.all([
  getLatestPosts(),
  getCategories(),
])
```

This reduces total wait time.

### Streaming and Suspense

Next.js 16 supports streaming, where parts of your page load independently.

You can wrap slow sections in `<Suspense>`:

```tsx
import { Suspense } from 'react'

<Suspense fallback={<p>Loading posts...</p>}>
  <LatestPostsList />
</Suspense>
```

The rest of the page loads first, and the posts list appears when ready.

This improves perceived performance.

***

# Part IX

## SEO Engineering

You will implement:

* Page-level metadata using the Next.js `metadata` API
* OpenGraph tags for social sharing
* Twitter cards
* Canonical URLs
* `sitemap.xml`
* `robots.txt`

### Metadata

In `src/app/page.tsx`:

```tsx
import { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'My Portfolio Blog',
  description: 'A modern portfolio blog built with Next.js 16 and Sanity.',
}
```

This sets the page's `<title>` and `<meta description>`.

### OpenGraph and Twitter Cards

Add:

```tsx
export const metadata: Metadata = {
  title: 'My Portfolio Blog',
  description: 'A modern portfolio blog built with Next.js 16 and Sanity.',
  openGraph: {
    title: 'My Portfolio Blog',
    description: 'A modern portfolio blog built with Next.js 16 and Sanity.',
    images: ['/cover.jpg'],
  },
  twitter: {
    card: 'summary_large_image',
  },
}
```

### Sitemap and robots.txt

Create:

```text
src/app/sitemap.ts
src/app/robots.ts
```

Implement them to generate `sitemap.xml` and `robots.txt` based on your posts.

***

# Part X

## Deployment

You will deploy your application using:

* Git for version control
* GitHub for repository hosting
* Vercel for builds and production hosting

The pipeline looks like:

```text
Git Push
   │
   ▼
GitHub
   │
   ▼
Vercel Build
   │
   ▼
Production
```

### Step 1: Create a GitHub Repository

In your terminal:

```bash
git init
git add .
git commit -m "Initial commit"
```

Then create a repo on GitHub and push:

```bash
git remote add origin https://github.com/yourusername/your-repo.git
git branch -M main
git push -u origin main
```

### Step 2: Connect to Vercel

1. Go to Vercel and log in.
2. Click "Add New Project".
3. Import your GitHub repo.
4. Add environment variables:
   * `NEXT_PUBLIC_SANITY_PROJECT_ID`
   * `NEXT_PUBLIC_SANITY_DATASET`
   * `SANITY_API_READ_TOKEN`
5. Deploy.

### Step 3: Verify Deployment

* Visit your Vercel URL.
* Check homepage, blog index, and single post pages.
* Confirm Sanity Studio works at `/studio` if you exposed it.

***

# Part XI

## Operating a Real Content Platform

Finally, you will move beyond "it works on my machine" and think like a content platform operator.

You will discuss:

* Editorial workflows (draft → review → publish)
* Draft workflows and how to preview drafts safely
* Preview mode integration in Next.js
* Content governance (who can publish what)
* Category and author management as content grows
* Publishing strategy for a personal portfolio (what to write, how often)

At this point, you will have built more than a demo—you will have a maintainable publishing platform you can keep using and evolving.

***

# Final Production Checklist

## Security

- [ ] Environment variables protected (in `.env.local` and Vercel, not in Git)
- [ ] Tokens hidden and rotated if accidentally leaked
- [ ] CORS configured for both development and production domains
- [ ] Draft mode and previews secured

## Content

- [ ] Schema validation rules in place
- [ ] Generated types up to date
- [ ] Content review workflow defined

## Performance

- [ ] Images optimized and using the CDN
- [ ] `useCdn` correctly configured for production reads
- [ ] Suspense boundaries implemented where needed
- [ ] Concurrent fetching used on high-traffic pages

## SEO

- [ ] Metadata configured for key pages
- [ ] OpenGraph and Twitter cards configured
- [ ] Sitemap generated
- [ ] `robots.txt` configured

## Operations

- [ ] GitHub repository created and synchronized
- [ ] Vercel deployment completed and tested
- [ ] Analytics enabled
- [ ] Basic monitoring or error reporting enabled

***

Congratulations.

You have built far more than a blog.

You have built a modern **portfolio content platform** using the same architectural principles found in production-grade publishing systems—something you can proudly link to on your resume and keep evolving as your skills grow.

This completes **Part 3**, covering **all remaining parts (IV–XI)** of your tutorial series.
