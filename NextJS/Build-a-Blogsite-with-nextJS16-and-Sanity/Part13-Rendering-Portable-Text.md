# **✅ Part 13 — Rendering Portable Text**

---

# GreyMatter Journal  
## Part 13 — Rendering Portable Text: Rich Text, Abstract Syntax Trees, and Custom Renderers

> **Goal of this lesson:** Render rich content from Sanity using Portable Text and understand why structured data is superior to raw HTML.

---

### The Rich Text Challenge

Our article pages currently show title, author, and excerpt — but not the main body.

Sanity stores rich text as **Portable Text** — a structured, JSON-based format (an Abstract Syntax Tree).

---

### Why Not Store HTML?

Storing raw HTML limits content to web pages. Portable Text stores **meaning** (structure + semantics), allowing the same content to be used across many platforms.

---

### Install the Renderer

```bash
npm install @portabletext/react
```

---

### Create the Portable Text Renderer

Create `components/PortableTextRenderer.tsx`:

```tsx
import { PortableText } from "@portabletext/react";

const components = {
  block: {
    // Custom heading styles
    h1: ({ children }: any) => <h1 className="text-4xl font-bold mt-12 mb-6">{children}</h1>,
    h2: ({ children }: any) => <h2 className="text-3xl font-semibold mt-10 mb-5">{children}</h2>,
    normal: ({ children }: any) => <p className="mb-6 leading-relaxed">{children}</p>,
  },
  list: {
    bullet: ({ children }: any) => <ul className="list-disc pl-6 mb-6 space-y-2">{children}</ul>,
  },
  marks: {
    strong: ({ children }: any) => <strong className="font-semibold">{children}</strong>,
    em: ({ children }: any) => <em className="italic">{children}</em>,
    link: ({ children, value }: any) => (
      <a 
        href={value?.href} 
        target="_blank" 
        rel="noopener noreferrer"
        className="text-blue-600 hover:underline"
      >
        {children}
      </a>
    ),
  },
};

export default function PortableTextRenderer({ value }: { value: any }) {
  return <PortableText value={value} components={components} />;
}
```

---

### Use It in the Article Page

Update `app/posts/[slug]/page.tsx`:

```tsx
import PortableTextRenderer from "@/components/PortableTextRenderer";

// Inside the return statement, after excerpt:
<PortableTextRenderer value={post.body} />
```

---

### How It Works

1. Sanity returns a **Portable Text AST** (array of blocks)
2. `@portabletext/react` walks the tree
3. Your custom `components` map block styles and marks to React components
4. React renders the final HTML

---

### Mental Model To Remember Forever

**Rich Text Architecture:**

```text
Editor Input
     ↓
Portable Text AST (Structured Data)
     ↓
Custom Renderer
     ↓
React Components
     ↓
HTML
```

Everything in modern software is built on **trees** — DOM, React, file systems, routers, and now content.

---

### Up Next — Part 14: Image Optimization with Sanity & Next.js

We’ll handle images properly:
- Sanity image references
- Using `next/image` with Sanity assets
- Image transformation pipelines
- Responsive images and performance
