# Tutorial: Writing Blog Posts with Sanity & Connecting Them to Your Vercel-Hosted Portfolio

*A beginner-friendly guide for absolute beginners — this tutorial bridges your Vercel-hosted portfolio website and your Sanity CMS setup.*

---

## What You'll Learn

By the end of this tutorial, you will:

1. Create a new blog post schema in Sanity
2. Write and publish your first blog post
3. Fetch those blog posts from your Vercel-hosted portfolio
4. Display them beautifully on your site
5. Set up **automatic revalidation** so new posts appear instantly without rebuilding

---

## Prerequisites

Before starting, make sure you have:

- ✅ Your **personal portfolio website** built and deployed on **Vercel** (from the first tutorial)
- ✅ **Sanity Studio** set up and running (from the second tutorial)
- ✅ Basic familiarity with JavaScript/TypeScript and React (or your framework of choice)

---

## Part 1: Setting Up the Blog Schema in Sanity

Sanity uses **schemas** to define what your content looks like. Think of a schema as a blueprint or template for your blog posts.

### Step 1: Create a Blog Post Schema

In your Sanity project, navigate to the `schemas` folder (usually at `/studio/schemas/` or similar).

Create a new file called `blogPost.js` (or `blogPost.ts` if using TypeScript):

```javascript
// schemas/blogPost.js
export default {
  name: 'blogPost',
  title: 'Blog Post',
  type: 'document',
  fields: [
    {
      name: 'title',
      title: 'Title',
      type: 'string',
      validation: Rule => Rule.required().max(100)
    },
    {
      name: 'slug',
      title: 'Slug (URL)',
      type: 'slug',
      options: {
        source: 'title',
        maxLength: 96
      },
      validation: Rule => Rule.required()
    },
    {
      name: 'publishedAt',
      title: 'Published At',
      type: 'datetime',
      initialValue: () => new Date().toISOString()
    },
    {
      name: 'excerpt',
      title: 'Excerpt',
      type: 'text',
      rows: 3,
      description: 'A short summary of the post (shown on the blog listing page)'
    },
    {
      name: 'coverImage',
      title: 'Cover Image',
      type: 'image',
      options: {
        hotspot: true
      }
    },
    {
      name: 'content',
      title: 'Content',
      type: 'array',
      of: [
        { type: 'block' },           // Rich text paragraphs
        { type: 'image' },           // Inline images
        { type: 'code' }             // Code blocks (optional)
      ]
    },
    {
      name: 'tags',
      title: 'Tags',
      type: 'array',
      of: [{ type: 'string' }],
      options: {
        layout: 'tags'
      }
    }
  ],
  preview: {
    select: {
      title: 'title',
      publishedAt: 'publishedAt',
      media: 'coverImage'
    },
    prepare({ title, publishedAt, media }) {
      return {
        title,
        subtitle: publishedAt ? new Date(publishedAt).toLocaleDateString() : 'No date',
        media
      };
    }
  }
};
```

### Step 2: Register the Schema

Open your schema configuration file (usually `schemas/index.js` or `index.ts`) and add your new blog post schema:

```javascript
// schemas/index.js
import blogPost from './blogPost'

export const schemaTypes = [blogPost]
// If you have other schemas, add them to the array:
// export const schemaTypes = [blogPost, project, aboutPage]
```

### Step 3: Restart Sanity Studio

If your Sanity Studio is running, stop it and restart:

```bash
cd studio
npm run dev
```

You should now see **"Blog Post"** in your Sanity Studio sidebar! 🎉

---

## Part 2: Writing Your First Blog Post

### Step 1: Open Sanity Studio

Navigate to `http://localhost:3333` (or your deployed studio URL).

### Step 2: Create a New Post

1. Click **"Blog Post"** in the left sidebar
2. Click the **"Create new Blog Post"** button (top right)
3. Fill in the fields:

| Field | What to Enter |
|-------|---------------|
| **Title** | Your blog post title (e.g., "My First Blog Post") |
| **Slug** | Click "Generate" to auto-create from the title |
| **Published At** | Select today's date and time |
| **Excerpt** | A 1-2 sentence summary |
| **Cover Image** | Upload an image (optional but recommended) |
| **Content** | Write your post using the rich text editor |
| **Tags** | Add relevant tags like "web-dev", "tutorial" |

### Step 3: Publish

Click the **"Publish"** button in the bottom right corner. Your post is now live in the Sanity database!

> 💡 **Pro Tip:** You can create multiple posts as drafts and publish them when ready. Unpublished posts won't appear on your website.

---

## Part 3: Connecting Sanity to Your Vercel Portfolio

Now for the exciting part — making your blog posts appear on your Vercel-hosted portfolio!

### Step 1: Install the Sanity Client

In your **portfolio website project** (not the Sanity studio), install the Sanity client:

```bash
npm install @sanity/client @sanity/image-url
```

### Step 2: Create a Sanity Client File

Create a new file in your portfolio project to connect to Sanity:

```javascript
// lib/sanity.js
import { createClient } from '@sanity/client'
import imageUrlBuilder from '@sanity/image-url'

// Use environment variables for security
const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET || 'production',
  apiVersion: '2026-06-28',         // Use today's date or your preferred version
  useCdn: true,                     // true for faster reads, false for freshest data
})

// Helper for image URLs
const builder = imageUrlBuilder(client)
export function urlFor(source) {
  return builder.image(source)
}

export default client
```

### Step 3: Add Environment Variables on Vercel

Since your site is hosted on **Vercel**, you need to add your Sanity credentials as environment variables.

**Option A: Via Vercel Dashboard**

1. Go to [vercel.com](https://vercel.com) and open your project
2. Navigate to **Settings → Environment Variables**
3. Add the following variables:

| Name | Value | Environment |
|------|-------|-------------|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | Your Sanity project ID | Production, Preview, Development |
| `NEXT_PUBLIC_SANITY_DATASET` | `production` (or your dataset name) | Production, Preview, Development |
| `SANITY_API_TOKEN` | Your Sanity read token (see below) | Production, Preview |

**Option B: Via CLI**

```bash
vercel env add NEXT_PUBLIC_SANITY_PROJECT_ID
vercel env add NEXT_PUBLIC_SANITY_DATASET
vercel env add SANITY_API_TOKEN
```

> 🔍 **Where to find your Project ID:** Open `sanity.config.js` (or `sanity.config.ts`) in your Sanity studio project. It looks like:
> ```javascript
> export default defineConfig({
>   projectId: 'abc123xyz',
>   dataset: 'production',
>   // ...
> })
> ```

> 🔑 **How to get a Sanity API Token:**
> 1. Go to [sanity.io/manage](https://sanity.io/manage)
> 2. Select your project → **API** → **Tokens**
> 3. Click **"Add API token"**
> 4. Name it "Vercel Read Token" and set **Viewer** permissions
> 5. Copy the token and paste it into Vercel

---

## Part 4: Fetching Blog Posts with Revalidation

Because your site is on **Vercel** using Next.js, you can use **Incremental Static Regeneration (ISR)** — this means your pages are statically generated for speed, but they automatically update when you publish new content!

### Step 1: Create Fetch Functions

```javascript
// lib/getBlogPosts.js
import client from './sanity'

export async function getBlogPosts() {
  const query = `*[_type == "blogPost"] | order(publishedAt desc) {
    _id,
    title,
    slug,
    publishedAt,
    excerpt,
    coverImage,
    tags,
    "content": content[]{
      ...,
      _type == "image" => {
        "asset": asset->
      }
    }
  }`
  
  const posts = await client.fetch(query)
  return posts
}

export async function getBlogPostBySlug(slug) {
  const query = `*[_type == "blogPost" && slug.current == $slug][0] {
    _id,
    title,
    slug,
    publishedAt,
    excerpt,
    coverImage,
    tags,
    content
  }`
  
  const post = await client.fetch(query, { slug })
  return post
}
```

### Step 2: Create the Blog Listing Page with ISR

```jsx
// app/blog/page.jsx (Next.js App Router)
import { getBlogPosts } from '@/lib/getBlogPosts'
import { urlFor } from '@/lib/sanity'
import Link from 'next/link'
import Image from 'next/image'

// Revalidate this page every 60 seconds
export const revalidate = 60

export default async function BlogPage() {
  const posts = await getBlogPosts()

  return (
    <div className="max-w-4xl mx-auto px-4 py-12">
      <h1 className="text-4xl font-bold mb-8">My Blog</h1>
      
      <div className="grid gap-8">
        {posts.map((post) => (
          <article 
            key={post._id} 
            className="border rounded-lg overflow-hidden hover:shadow-lg transition-shadow"
          >
            {post.coverImage && (
              <div className="relative h-64 w-full">
                <Image
                  src={urlFor(post.coverImage).width(800).height(400).url()}
                  alt={post.title}
                  fill
                  className="object-cover"
                />
              </div>
            )}
            
            <div className="p-6">
              <div className="text-sm text-gray-500 mb-2">
                {new Date(post.publishedAt).toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric'
                })}
              </div>
              
              <h2 className="text-2xl font-semibold mb-2">
                <Link href={`/blog/${post.slug.current}`} className="hover:text-blue-600">
                  {post.title}
                </Link>
              </h2>
              
              {post.excerpt && (
                <p className="text-gray-600 mb-4">{post.excerpt}</p>
              )}
              
              {post.tags && (
                <div className="flex gap-2">
                  {post.tags.map((tag) => (
                    <span 
                      key={tag} 
                      className="px-3 py-1 bg-gray-100 text-sm rounded-full"
                    >
                      #{tag}
                    </span>
                  ))}
                </div>
              )}
            </div>
          </article>
        ))}
      </div>
    </div>
  )
}
```

> 🔄 **What is `revalidate = 60`?** This tells Vercel to regenerate this page in the background every 60 seconds. So if you publish a new post, it will appear on your site within a minute — no full redeploy needed!

---

## Part 5: Creating Individual Blog Post Pages

```jsx
// app/blog/[slug]/page.jsx (Next.js App Router)
import { getBlogPostBySlug, getBlogPosts } from '@/lib/getBlogPosts'
import { urlFor } from '@/lib/sanity'
import { PortableText } from '@portabletext/react'
import Image from 'next/image'

// Revalidate every 60 seconds
export const revalidate = 60

// Generate static pages for all blog posts at build time
export async function generateStaticParams() {
  const posts = await getBlogPosts()
  return posts.map((post) => ({
    slug: post.slug.current,
  }))
}

export default async function BlogPostPage({ params }) {
  const post = await getBlogPostBySlug(params.slug)

  if (!post) {
    return <div>Post not found</div>
  }

  return (
    <article className="max-w-3xl mx-auto px-4 py-12">
      {/* Header */}
      <header className="mb-8">
        <div className="text-sm text-gray-500 mb-2">
          {new Date(post.publishedAt).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
          })}
        </div>
        
        <h1 className="text-4xl font-bold mb-4">{post.title}</h1>
        
        {post.excerpt && (
          <p className="text-xl text-gray-600 italic">{post.excerpt}</p>
        )}
      </header>

      {/* Cover Image */}
      {post.coverImage && (
        <div className="relative h-96 w-full mb-8 rounded-lg overflow-hidden">
          <Image
            src={urlFor(post.coverImage).width(1200).height(600).url()}
            alt={post.title}
            fill
            className="object-cover"
            priority
          />
        </div>
      )}

      {/* Tags */}
      {post.tags && (
        <div className="flex gap-2 mb-8">
          {post.tags.map((tag) => (
            <span key={tag} className="px-3 py-1 bg-blue-100 text-blue-800 text-sm rounded-full">
              {tag}
            </span>
          ))}
        </div>
      )}

      {/* Content */}
      <div className="prose prose-lg max-w-none">
        <PortableText 
          value={post.content}
          components={{
            types: {
              image: ({ value }) => (
                <div className="relative h-64 w-full my-6">
                  <Image
                    src={urlFor(value).width(800).url()}
                    alt={value.alt || 'Blog image'}
                    fill
                    className="object-cover rounded-lg"
                  />
                </div>
              ),
              code: ({ value }) => (
                <pre className="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto">
                  <code>{value.code}</code>
                </pre>
              )
            }
          }}
        />
      </div>
    </article>
  )
}
```

### Install Portable Text Renderer

```bash
npm install @portabletext/react
```

> **What is Portable Text?** It's Sanity's way of storing rich text content. Instead of HTML, it stores content as structured JSON. The `<PortableText>` component converts that JSON into React components.

---

## Part 6: Adding a "Blog" Link to Your Portfolio Navigation

Update your navigation to include the new blog section:

```jsx
// components/Navbar.jsx
import Link from 'next/link'

export default function Navbar() {
  return (
    <nav className="flex items-center justify-between px-8 py-4">
      <Link href="/" className="text-xl font-bold">Your Name</Link>
      
      <div className="flex gap-6">
        <Link href="/" className="hover:text-blue-600">Home</Link>
        <Link href="/about" className="hover:text-blue-600">About</Link>
        <Link href="/projects" className="hover:text-blue-600">Projects</Link>
        <Link href="/blog" className="hover:text-blue-600">Blog</Link> {/* NEW! */}
        <Link href="/contact" className="hover:text-blue-600">Contact</Link>
      </div>
    </nav>
  )
}
```

---

## Part 7: Deploying to Vercel

### Step 1: Deploy Sanity Studio

If you made schema changes, deploy your updated studio:

```bash
cd studio
npm run deploy
```

### Step 2: Push Your Portfolio Code

Commit and push your changes to GitHub (or your Git provider):

```bash
git add .
git commit -m "Add blog functionality with Sanity CMS"
git push origin main
```

Vercel will automatically detect the push and redeploy your site!

### Step 3: Verify Environment Variables

Double-check that all environment variables are set in the Vercel dashboard:
- `NEXT_PUBLIC_SANITY_PROJECT_ID`
- `NEXT_PUBLIC_SANITY_DATASET`
- `SANITY_API_TOKEN` (if using server-side fetching with a token)

---

## Part 8: (Optional but Recommended) Instant Updates with Webhooks

The `revalidate = 60` approach works well, but what if you want new posts to appear **immediately**? You can set up a **Sanity webhook** to trigger Vercel revalidation on demand.

### Step 1: Create a Revalidation API Route

```javascript
// app/api/revalidate/route.js
import { revalidatePath } from 'next/cache'
import { isValidSignature, SIGNATURE_HEADER_NAME } from '@sanity/webhook'

const secret = process.env.SANITY_WEBHOOK_SECRET

export async function POST(request) {
  const signature = request.headers.get(SIGNATURE_HEADER_NAME)
  const body = await request.text()
  
  if (!isValidSignature(body, signature, secret)) {
    return new Response('Invalid signature', { status: 401 })
  }

  const json = JSON.parse(body)
  const { _type, slug } = json

  if (_type === 'blogPost') {
    // Revalidate the blog listing page
    revalidatePath('/blog')
    
    // Revalidate the specific post page if slug exists
    if (slug?.current) {
      revalidatePath(`/blog/${slug.current}`)
    }
    
    return new Response('Revalidated successfully', { status: 200 })
  }

  return new Response('Unknown type', { status: 400 })
}
```

Install the webhook helper:

```bash
npm install @sanity/webhook
```

### Step 2: Add the Webhook Secret to Vercel

```bash
vercel env add SANITY_WEBHOOK_SECRET
```

Generate a random secret string (you can use `openssl rand -base64 32`).

### Step 3: Configure the Webhook in Sanity

1. Go to [sanity.io/manage](https://sanity.io/manage)
2. Select your project → **API** → **Webhooks**
3. Click **"Add webhook"**
4. Set the URL to: `https://your-domain.com/api/revalidate`
5. Set the **Secret** to match your `SANITY_WEBHOOK_SECRET`
6. Select **Dataset**: `production`
7. Check **"Create"**, **"Update"**, and **"Delete"** under **Trigger on**
8. Filter to `_type == "blogPost"` (optional but recommended)
9. Save!

Now, every time you publish, edit, or delete a blog post, your Vercel site will instantly revalidate the affected pages. No waiting, no manual redeploy! 🚀

---

## Common Issues & Solutions

| Problem | Solution |
|---------|----------|
| **Posts not showing up** | Check that posts are published (not just saved as drafts). Also verify `revalidate` is set. |
| **Images not loading** | Make sure `urlFor()` is imported correctly and the image asset exists. |
| **Slug conflicts** | Each slug must be unique. Sanity will warn you if there's a duplicate. |
| **Content not rendering** | Ensure `@portabletext/react` is installed and `<PortableText>` is configured. |
| **Environment variables not working** | Remember: variables prefixed with `NEXT_PUBLIC_` are only embedded at build time. If you change them, you must redeploy. |
| **Webhook not triggering** | Check the webhook URL is correct and the secret matches. Look at Vercel function logs for errors. |
| **CORS errors** | In your Sanity project settings, add your Vercel domain to the CORS origins. |

---

## What You've Built

You now have a complete blogging system integrated with your Vercel-hosted portfolio:

1. ✅ **Sanity Studio** — A beautiful CMS where you write and manage posts
2. ✅ **Vercel-Hosted Portfolio** — Fetches and displays your blog posts dynamically
3. ✅ **Blog Listing Page** — Shows all posts with excerpts and images (ISR-enabled)
4. ✅ **Individual Post Pages** — Full rich-text rendering with images and code blocks
5. ✅ **Navigation** — Easy access to your blog from your portfolio
6. ✅ **Instant Updates** — Optional webhook for immediate revalidation on publish

---

## Next Steps

- **Add pagination** if you plan to write many posts
- **Add a search bar** to help readers find posts
- **Add comments** using a service like Giscus or Disqus
- **Add an RSS feed** at `/api/rss` for subscribers
- **Add Open Graph images** for social sharing
- **Set up a sitemap** for better SEO

---

## Quick Reference: Sanity GROQ Query

The query language used to fetch content from Sanity is called **GROQ**. Here's a cheat sheet:

```javascript
// Get all published blog posts, newest first
`*[_type == "blogPost" && publishedAt < now()] | order(publishedAt desc)`

// Get posts with a specific tag
`*[_type == "blogPost" && "web-dev" in tags]`

// Get only 5 most recent posts
`*[_type == "blogPost"] | order(publishedAt desc)[0...5]`

// Get post by slug
`*[_type == "blogPost" && slug.current == "my-first-post"][0]`
```

---

*Happy blogging! 📝 Your Vercel-hosted portfolio is now a living, breathing platform where you can share your thoughts, projects, and journey with the world — instantly updated from Sanity!*
