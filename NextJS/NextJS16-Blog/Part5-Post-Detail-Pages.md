## Blog Tutorial - Part 5: Post Detail Pages (Portable Text, Images, Code Blocks)

### What we're doing

We will build the individual post page at `/posts/[slug]`, render the rich text body ("Portable Text") including headings, images, and custom code blocks, and pre-generate all post pages at build time for maximum speed and SEO.

---

### ⚠️ Next.js 16 Change: `params` is now a Promise

In Next.js 16, dynamic route parameters (`params`) are **asynchronous**. They are a `Promise` that must be `await`-ed before you can read properties from them. This applies to page components, layouts, and `generateMetadata`.

The pattern we will use consistently:

```tsx
{ params }: { params: Promise<{ slug: string }> }
const { slug } = await params;

```

---

### Step 1: Install Dependencies

We need the official Sanity portable text renderer and a syntax highlighter for your code blocks.

```bash
npm install @portabletext/react react-syntax-highlighter
npm install -D @types/react-syntax-highlighter

```

### Step 2: Create a Syntax-Highlighted Code Block Component

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

### Step 3: Create Portable Text Rendering Components

Create `src/components/PortableTextComponents.tsx`. This maps your Sanity JSON blocks to React components.

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
    h1: ({ children }) => <h1 className="mt-8 text-3xl font-bold">{children}</h1>,
    h2: ({ children }) => <h2 className="mt-8 text-2xl font-bold">{children}</h2>,
    h3: ({ children }) => <h3 className="mt-6 text-xl font-bold">{children}</h3>,
    blockquote: ({ children }) => (
      <blockquote className="border-l-4 border-blue-500 pl-4 italic text-gray-600 dark:text-gray-300">
        {children}
      </blockquote>
    ),
  },
};

```

### Step 4: Create the Post Detail Page

Create `src/app/posts/[slug]/page.tsx`. This page uses the `async` pattern required by Next.js 16.

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

type PageProps = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const slugs = await client.fetch<string[]>(POST_SLUGS_QUERY);
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });
  if (!post) return {};
  return { title: post.title, description: post.excerpt };
}

export default async function PostPage({ params }: PageProps) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });

  if (!post) notFound();

  return (
    <main className="mx-auto max-w-3xl px-4 py-16">
      <h1 className="text-4xl font-bold tracking-tight">{post.title}</h1>
      
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

---

### Checkpoint ✅

* [ ] `@portabletext/react` installed.
* [ ] `CodeBlock` component implemented and styled.
* [ ] `PortableTextComponents` configured for rich text types.
* [ ] Dynamic route `[slug]` correctly implements the `Promise` pattern for `params`.
* [ ] Post detail page correctly fetches and renders content.

**Next:** **Part 6 — Categories & Author Pages, Static Generation, and ISR.**

---

Are you ready to proceed to Part 6 and handle categorization and author linking?
