# **✅ Part 13 — Rendering Portable Text**

# GreyMatter Journal

## Part 13 — Rendering Portable Text: Rich Content, Abstract Syntax Trees, and Custom Renderers

> **Goal of this lesson:** Render rich content from Sanity using Portable Text, understand why structured content is superior to raw HTML, and learn how modern publishing systems transform abstract data structures into user interfaces.

---

# We've Built the Container. Now We Need the Content.

Our article page now renders:

* Title
* Author
* Publication date
* Excerpt

However, the most important part of an article is still missing:

```text
The article body itself.
```

A traditional CMS would simply return HTML:

```html
<h1>Hello World</h1>

<p>This is an article.</p>

<ul>
  <li>Item A</li>
  <li>Item B</li>
</ul>
```

Modern content systems like Sanity take a fundamentally different approach.

Instead of storing HTML, they store structured content.

This structure is called:

```text
Portable Text
```

---

# Why Modern CMS Systems Avoid Storing HTML

At first glance, HTML seems perfect:

```html
<h2>Introduction</h2>

<p>Hello world.</p>
```

The problem is that HTML describes presentation.

It does not describe meaning.

Consider:

```html
<h2>Introduction</h2>
```

Questions immediately arise:

* Is this a chapter title?
* A section heading?
* A navigation element?
* A card title?
* A mobile heading?

HTML doesn't know.

It only knows how something should appear.

Portable Text takes a different approach.

Instead of storing presentation, it stores structure and semantics.

---

# Portable Text Is Structured Content

Imagine writing this article:

```markdown
# Understanding React

React is a UI library.

- Components
- State
- Props
```

Portable Text stores something conceptually similar to:

```json
[
  {
    "_type": "block",
    "style": "h1",
    "children": [
      {
        "text": "Understanding React"
      }
    ]
  },
  {
    "_type": "block",
    "style": "normal",
    "children": [
      {
        "text": "React is a UI library."
      }
    ]
  },
  {
    "_type": "block",
    "listItem": "bullet",
    "children": [
      {
        "text": "Components"
      }
    ]
  }
]
```

Notice something important:

```text
No HTML exists.
```

Instead, we have:

```text
Content
       +
Structure
       +
Meaning
```

---

# Portable Text Is An Abstract Syntax Tree

One of the major ideas in modern software engineering is:

> Everything eventually becomes a tree.

Examples include:

```text
HTML
     ↓
DOM Tree

React
     ↓
Component Tree

Next.js
     ↓
Route Tree

Operating Systems
     ↓
File System Tree

Compilers
     ↓
Syntax Tree

Sanity
     ↓
Portable Text Tree
```

Portable Text is an example of an:

```text
AST
```

or:

```text
Abstract Syntax Tree
```

Conceptually:

```text
Article

    Heading

    Paragraph

    Paragraph

    List

        Item

        Item

        Item

    Quote

    Code Block
```

Our job is to transform this tree into React components.

---

# Installing the Portable Text Renderer

Install Sanity's official React renderer:

```bash
npm install @portabletext/react
```

This package understands how to walk the Portable Text tree.

---

# Our Component Architecture

Following our GreyMatter Journal structure:

```text
components/

└── portable-text/
    ├── PortableTextRenderer.tsx
    ├── CodeBlock.tsx
    ├── ImageBlock.tsx
    ├── QuoteBlock.tsx
    └── CalloutBlock.tsx
```

For now, we'll implement the main renderer.

Later we'll extend it with specialized blocks.

---

# Creating Our First Portable Text Renderer

Create:

```text
components/portable-text/PortableTextRenderer.tsx
```

```tsx
import {
  PortableText,
  type PortableTextComponents,
} from "@portabletext/react";

const components: PortableTextComponents = {
  block: {
    h1: ({ children }) => (
      <h1 className="mt-12 mb-6 text-4xl font-bold tracking-tight">
        {children}
      </h1>
    ),

    h2: ({ children }) => (
      <h2 className="mt-10 mb-5 text-3xl font-semibold tracking-tight">
        {children}
      </h2>
    ),

    h3: ({ children }) => (
      <h3 className="mt-8 mb-4 text-2xl font-semibold">
        {children}
      </h3>
    ),

    normal: ({ children }) => (
      <p className="mb-6 leading-8 text-gray-700">
        {children}
      </p>
    ),

    blockquote: ({ children }) => (
      <blockquote className="my-8 border-l-4 border-gray-300 pl-6 italic">
        {children}
      </blockquote>
    ),
  },

  list: {
    bullet: ({ children }) => (
      <ul className="mb-6 list-disc space-y-2 pl-6">
        {children}
      </ul>
    ),

    number: ({ children }) => (
      <ol className="mb-6 list-decimal space-y-2 pl-6">
        {children}
      </ol>
    ),
  },

  marks: {
    strong: ({ children }) => (
      <strong className="font-semibold">
        {children}
      </strong>
    ),

    em: ({ children }) => (
      <em className="italic">
        {children}
      </em>
    ),

    link: ({
      children,
      value,
    }) => (
      <a
        href={value?.href}
        target="_blank"
        rel="noopener noreferrer"
        className="
          text-blue-600
          underline
          underline-offset-4
          hover:text-blue-800
        "
      >
        {children}
      </a>
    ),
  },
};

type Props = {
  value: unknown;
};

export default function PortableTextRenderer({
  value,
}: Props) {
  return (
    <PortableText
      value={value}
      components={components}
    />
  );
}
```

---

# Updating Our Article Page

Open:

```text
app/(site)/posts/[slug]/page.tsx
```

Import the renderer:

```tsx
import PortableTextRenderer
  from "@/components/portable-text/PortableTextRenderer";
```

Then replace the placeholder:

```tsx
<PortableTextRenderer
  value={post.body}
/>
```

Our article page now becomes:

```text
Sanity Content
        ↓
Portable Text
        ↓
Renderer
        ↓
React Components
        ↓
HTML
        ↓
Browser
```

---

# What Is Actually Happening?

Suppose Sanity returns:

```json
{
  "_type": "block",
  "style": "h1",
  "children": [
    {
      "text": "Understanding React"
    }
  ]
}
```

The renderer performs:

```text
Look up:
"h1"
        ↓

Find:
components.block.h1
        ↓

Execute React component
        ↓

Return HTML
```

Conceptually:

```text
Portable Text Node
           ↓
Renderer Lookup
           ↓
React Component
           ↓
Rendered UI
```

This is an example of a pattern you'll encounter repeatedly:

```text
Data
     ↓
Interpreter
     ↓
Execution
```

---

# Why This Is More Powerful Than HTML

Suppose tomorrow we build:

* A website
* An iOS application
* An Android application
* A newsletter system
* A search engine
* An AI summarization pipeline

HTML locks us into:

```text
Web Browser
```

Portable Text allows:

```text
Structured Content
            ↓
Multiple Renderers
            ↓
Multiple Platforms
```

For example:

```text
Portable Text
        ↓
React Renderer

Portable Text
        ↓
iOS Renderer

Portable Text
        ↓
Email Renderer

Portable Text
        ↓
AI Processor
```

This separation between content and presentation is one of the fundamental principles of modern software architecture.

---

# Styling Long-Form Content

Our article page already uses:

```tsx
className="
  prose
  prose-lg
"
```

Over time, our typography system will evolve into:

```text
styles/

tokens.css
themes.css
prose.css
code.css
animations.css
```

For example:

```css
.prose {
  max-width: 70ch;
}

.prose pre {
  overflow-x: auto;
  padding: 1rem;
}

.prose code {
  font-family:
    "JetBrains Mono",
    monospace;
}
```

Technical publications live or die based on typography quality.

Good typography is infrastructure.

---

# The Bigger Idea

Throughout this course, we keep discovering the same pattern:

```text
File System
        =
Tree

Router
        =
Tree

React
        =
Tree

DOM
        =
Tree

Portable Text
        =
Tree
```

Modern software systems are fundamentally systems that transform trees into other trees.

Portable Text simply makes this reality visible.

---

# Mental Model To Remember Forever

Traditional thinking:

```text
Rich Text
       =
HTML
```

Modern thinking:

```text
Rich Text
       =
Structured Data
       +
Semantics
       +
Rendering Pipeline
```

More fundamentally:

```text
Portable Text
        ↓
Abstract Syntax Tree
        ↓
React Components
        ↓
User Interface
```

Everything in modern software engineering eventually becomes:

```text
Data
     ↓
Tree
     ↓
Transformation
     ↓
User Experience
```

---

# Up Next — Part 14: Image Optimization with Sanity and Next.js

Next we'll tackle one of the hardest problems in web publishing:

* How Sanity stores images
* Image asset references
* Building image URLs
* Using `next/image`
* Responsive images
* Image optimization pipelines
* Why images are one of the biggest performance challenges on the web

This is where GreyMatter Journal starts becoming a truly production-grade publication platform.
