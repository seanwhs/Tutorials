## Blog Tutorial - Part 5: Post Detail Pages (Portable Text, Images, Code Blocks)

## What we're doing
We'll build the individual post page at `/posts/[slug]`, render the rich text body ("Portable Text") including headings, images, and our custom code blocks, and pre-generate all post pages at build time for speed.

## ⚠️ Next.js 16 change: params is now a Promise

This is the first dynamic route (`[slug]`) in our project. In Next.js 16, `params` passed into page components, layouts, and `generateMetadata` is **asynchronous** — it's a `Promise` that must be `await`-ed before you can read properties off it. This applies to every dynamic route we build for the rest of this series. The old synchronous `{ params: { slug: string } }` shape from Next.js 14 will cause type errors and runtime bugs in Next.js 16.

The pattern we'll use everywhere:

```tsx
{ params }: { params: Promise<{ slug: string }> }
const { slug } = await params;
```

## Step 1: Create a syntax-highlighted code block component

Install a lightweight highlighter:

```bash
npm install react-syntax-highlighter
npm install -D @types/react-syntax-highlighter
```

Create `src/components/CodeBlock.tsx`:

```tsx
"use client";

import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { oneDark } from "react-syntax-highlighter/dist/esm/styles/prism";

export default function CodeBlock({
  language,
  code,
}: {
  language?: string;
  code: string;
}) {
  return (
    <SyntaxHighlighter
      language={language || "text"}
      style={oneDark}
      customStyle={{ borderRadius: "0.5rem", padding: "1rem" }}
    >
      {code}
    </SyntaxHighlighter>
  );
}
```

## Step 2: Create Portable Text rendering components

Create `src/components/PortableTextComponents.tsx`:

```tsx
import Image from "next/image";
import type { PortableTextComponents } from "@portabletext/react";
import { urlForImage } from "@/sanity/lib/image";
import CodeBlock from "./CodeBlock";

export const portableTextComponents: PortableTextComponents = {
  types: {
    image: ({ value }) => (
      <div className="relative my-8 h-96 w-full overflow-hidden rounded-lg">
        <Image
          src={urlForImage(value).width(1200).url()}
          alt={value.alt || " "}
          fill
          className="object-cover"
        />
      </div>
    ),
    codeBlock: ({ value }) => (
      <div className="my-6">
        <CodeBlock language={value.language} code={value.code} />
      </div>
    ),
  },
  marks: {
    link: ({ children, value }) => (
      <a
        href={value.href}
        target="_blank"
        rel="noopener noreferrer"
        className="text-blue-600 underline hover:text-blue-800 dark:text-blue-400"
      >
        {children}
      </a>
    ),
  },
  block: {
    h1: ({ children }) => (
      <h1 className="mt-8 text-3xl font-bold">{children}</h1>
    ),
    h2: ({ children }) => (
      <h2 className="mt-8 text-2xl font-bold">{children}</h2>
    ),
    h3: ({ children }) => (
      <h3 className="mt-6 text-xl font-bold">{children}</h3>
    ),
    blockquote: ({ children }) => (
      <blockquote className="border-l-4 border-blue-500 pl-4 italic text-gray-600 dark:text-gray-300">
        {children}
      </blockquote>
    ),
  },
};
```

`@portabletext/react`'s `PortableText` component walks the JSON block array from Sanity and calls the matching renderer above for each block type/mark — this is how "rich text stored as JSON" becomes real React/HTML.

## Step 3: Create the post detail page with static generation (Next.js 16 async params)

Create `src/app/posts/[slug]/page.tsx`:

```tsx
import { notFound } from "next/navigation";
import Image from "next/image";
import { PortableText } from "@portabletext/react";
import { client } from "@/sanity/lib/client";
import { urlForImage } from "@/sanity/lib/image";
import { POST_QUERY, POST_SLUGS_QUERY } from "@/sanity/lib/queries";
import type { Post } from "@/sanity/lib/types";
import { portableTextComponents } from "@/components/PortableTextComponents";

export const revalidate = 60;

type PageProps = {
  params: Promise<{ slug: string }>;
};

export async function generateStaticParams() {
  const slugs = await client.fetch<string[]>(POST_SLUGS_QUERY);
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });
  if (!post) return {};
  return {
    title: post.title,
    description: post.excerpt,
  };
}

export default async function PostPage({ params }: PageProps) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });

  if (!post) {
    notFound();
  }

  return (
    <main className="mx-auto max-w-3xl px-4 py-16">
      <div className="mb-6 flex flex-wrap gap-2">
        {post.categories?.map((cat) => (
          <span
            key={cat.slug.current}
            className="rounded-full bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-700 dark:bg-blue-900 dark:text-blue-200"
          >
            {cat.title}
          </span>
        ))}
      </div>

      <h1 className="text-4xl font-bold tracking-tight">{post.title}</h1>

      <div className="mt-4 flex items-center gap-3 text-sm text-gray-500 dark:text-gray-400">
        {post.author?.name && (
          <a href={`/authors/${post.author.slug.current}`} className="hover:underline">
            By {post.author.name}
          </a>
        )}
        <span>&middot;</span>
        <time dateTime={post.publishedAt}>
          {new Date(post.publishedAt).toLocaleDateString("en-US", {
            year: "numeric",
            month: "long",
            day: "numeric",
          })}
        </time>
      </div>

      {post.mainImage && (
        <div className="relative mt-8 h-96 w-full overflow-hidden rounded-xl">
          <Image
            src={urlForImage(post.mainImage).width(1200).height(675).url()}
            alt={post.mainImage.alt || post.title}
            fill
            className="object-cover"
            priority
          />
        </div>
      )}

      <article className="prose prose-lg mt-10 max-w-none dark:prose-invert">
        {post.body && (
          <PortableText
            value={post.body}
            components={portableTextComponents}
          />
        )}
      </article>
    </main>
  );
}
```

Key Next.js 16 details:
- We define a shared `PageProps` type with `params: Promise<{ slug: string }>`.
- Both `generateMetadata` and the page component `await params` before destructuring `slug`.
- `generateStaticParams` itself is unaffected — it still returns a plain array of `{ slug }` objects synchronously (from awaited data); Next.js uses these to know which `params` Promises to pre-resolve at build time.
- We've already linked the author name directly in this snippet (previously this link was added in Part 6 — it's included here now since it's simple and avoids an extra edit pass).

## Step 4: Link post cards correctly

We already linked to `/posts/${post.slug.current}` in `PostCard.tsx` back in Part 4 — no changes needed there.

## Step 5: Test it

```bash
npm run dev
```

Go to homepage, click your post card — you should land on `/posts/hello-world-my-first-post` (or similar) with the full title, image, and rendered body content. Try adding a code block and an inline image to the post body in the Studio and confirm they render correctly with syntax highlighting.

## Checkpoint ✅
- [ ] Clicking a post card opens its detail page
- [ ] Headings, paragraphs, bold/italic, and links render properly
- [ ] Inline images render
- [ ] Code blocks render with syntax highlighting
- [ ] Page `<title>` in the browser tab matches the post title (metadata working)
- [ ] No TypeScript errors related to `params` — confirm it's typed as `Promise<{ slug: string }>` and awaited

Next: **Part 6 — Categories & Author Pages, Static Generation, ISR**
