## Blog Tutorial — Part 5: Post Detail Pages

In this part, we implement the dynamic route `src/app/posts/[slug]/page.tsx`. We will leverage the Sanity Portable Text renderer to transform JSON document blocks into styled React components, including syntax-highlighted code blocks.

### Step 1: Install Dependencies

```bash
npm install @portabletext/react react-syntax-highlighter
npm install -D @types/react-syntax-highlighter

```

### Step 2: Code Highlighting

Create `src/components/CodeBlock.tsx` to handle code rendering:

```tsx
"use client";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { oneDark } from "react-syntax-highlighter/dist/esm/styles/prism";

export default function CodeBlock({ language, code }: { language?: string; code: string }) {
  return (
    <SyntaxHighlighter language={language || "text"} style={oneDark} customStyle={{ borderRadius: "0.5rem", padding: "1rem" }}>
      {code}
    </SyntaxHighlighter>
  );
}

```

### Step 3: Portable Text Components

Create `src/components/PortableTextComponents.tsx` to map your Sanity blocks to custom UI components:

```tsx
import Image from "next/image";
import type { PortableTextComponents } from "@portabletext/react";
import { urlForImage } from "@/sanity/lib/image";
import CodeBlock from "./CodeBlock";

export const portableTextComponents: PortableTextComponents = {
  types: {
    image: ({ value }) => (
      <div className="relative my-8 h-96 w-full overflow-hidden rounded-lg">
        <Image src={urlForImage(value).width(1200).url()} alt={value.alt || " "} fill className="object-cover" />
      </div>
    ),
    codeBlock: ({ value }) => (
      <div className="my-6">
        <CodeBlock language={value.language} code={value.code} />
      </div>
    ),
  },
  block: {
    h1: ({ children }) => <h1 className="mt-8 text-3xl font-bold">{children}</h1>,
    h2: ({ children }) => <h2 className="mt-8 text-2xl font-bold">{children}</h2>,
    blockquote: ({ children }) => <blockquote className="border-l-4 border-blue-500 pl-4 italic">{children}</blockquote>,
  },
};

```

### Step 4: Dynamic Detail Page

Create `src/app/posts/[slug]/page.tsx` using the `Promise` pattern for `params`:

```tsx
import { notFound } from "next/navigation";
import { PortableText } from "@portabletext/react";
import { client } from "@/sanity/lib/client";
import { POST_QUERY, POST_SLUGS_QUERY } from "@/sanity/lib/queries";
import type { Post } from "@/sanity/lib/types";
import { portableTextComponents } from "@/components/PortableTextComponents";

type PageProps = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const slugs = await client.fetch<string[]>(POST_SLUGS_QUERY);
  return slugs.map((slug) => ({ slug }));
}

export default async function PostPage({ params }: PageProps) {
  const { slug } = await params; // Awaiting the params promise
  const post = await client.fetch<Post>(POST_QUERY, { slug });

  if (!post) notFound();

  return (
    <main className="mx-auto max-w-3xl px-4 py-16">
      <h1 className="text-4xl font-bold">{post.title}</h1>
      <article className="prose prose-lg mt-10">
        <PortableText value={post.body || []} components={portableTextComponents} />
      </article>
    </main>
  );
}

```

---

### Checkpoint ✅

* [ ] **Next.js 16 Compatibility:** `params` is correctly handled as a `Promise`.
* [ ] **Rich Text:** `PortableText` is configured to handle images and code blocks.
* [ ] **SEO:** `generateStaticParams` ensures your post pages are pre-rendered.
