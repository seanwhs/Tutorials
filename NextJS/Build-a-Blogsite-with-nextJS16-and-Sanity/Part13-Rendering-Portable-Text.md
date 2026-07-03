# GreyMatter Journal

# Part 13 — Rendering Portable Text: Understanding Rich Text, Abstract Syntax Trees, and Custom Renderers

> **Goal of this lesson:** Learn how to render Sanity Portable Text in Next.js 16, understand why Sanity stores rich text as structured data instead of HTML, and discover that modern rich text editors actually produce abstract syntax trees (ASTs).

---

# Our Blog Posts Have A Problem

Currently, our article page renders:

```text id="szv9pl"
Title

Author

Excerpt
```

But the actual article body:

```text id="uh0khn"
body
```

is never displayed.

Why?

Because Sanity doesn't store:

```html id="7dj1u2"
<h1>Hello</h1>

<p>
  Welcome to my article.
</p>
```

Instead, it stores:

```json id="3knf9o"
[
  {
    "_type": "block",
    "style": "normal",
    "children": [
      {
        "text":
          "Welcome to my article."
      }
    ]
  }
]
```

---

# Why Doesn't Sanity Store HTML?

This confuses almost every beginner.

You might think:

```text id="4u0gfe"
Rich Text
       ↓
HTML
```

But HTML assumes:

```text id="jgmj1a"
Website
```

What about:

* mobile apps,
* newsletters,
* RSS feeds,
* PDFs,
* APIs,
* AI systems?

HTML becomes limiting.

---

# Think About Word Documents

Suppose Microsoft Word stored:

```html id="4v4l2u"
<h1>
  My Report
</h1>
```

That would be strange.

Instead, Word stores:

```text id="u5m55t"
Document Structure
```

Example:

```text id="2k7pnm"
Heading

Paragraph

Paragraph

List

Paragraph
```

Sanity works the same way.

---

# Portable Text Is Structured Data

Suppose we write:

```text id="6yjlwm"
Why Server Components Matter

Server Components reduce
JavaScript bundle size.
```

Sanity stores:

```json id="1dz1jw"
[
  {
    "_type": "block",
    "style": "h2",
    "children": [
      {
        "text":
          "Why Server Components Matter"
      }
    ]
  },

  {
    "_type": "block",
    "style": "normal",
    "children": [
      {
        "text":
          "Server Components reduce JavaScript bundle size."
      }
    ]
  }
]
```

Diagram:

```text id="2rnwxe"
Document

├── Heading
└── Paragraph
```

---

# Wait...

This structure looks familiar.

Consider JavaScript:

```javascript id="hhm8z2"
2 + 3 * 4
```

Computers don't store:

```text id="1xjlwm"
2 + 3 * 4
```

Instead they build:

```text id="uwngn5"
      +
     / \
    2   *
       / \
      3   4
```

This is called:

# Abstract Syntax Tree (AST)

---

# Portable Text Is Also An AST

Diagram:

```text id="4jjlwm"
Document
    │
    ├── Heading
    │      └── Text
    │
    └── Paragraph
           └── Text
```

This is why Portable Text is so powerful.

It stores:

```text id="u8ktnd"
Meaning
```

instead of:

```text id="1rjlwm"
Presentation
```

---

# Installing The Renderer

Return to your project root:

```bash id="zjlwm7"
npm install @portabletext/react
```

---

# What Does This Package Do?

Many beginners think:

```text id="pu5mdf"
Portable Text
       ↓
HTML
```

Not exactly.

Instead:

```text id="40z6c8"
Portable Text
       ↓
React Components
       ↓
HTML
```

Diagram:

```text id="j0twyx"
Portable Text AST
         │
         ▼
Renderer
         │
         ▼
React Tree
         │
         ▼
HTML
```

---

# Our First Renderer

Create:

```text id="8jlwmq"
components/

PortableTextRenderer.tsx
```

Add:

```tsx id="kl7qmf"
import { PortableText }
  from "@portabletext/react";

export default function
PortableTextRenderer({
  value,
}: {
  value: any;
}) {
  return (
    <PortableText
      value={value}
    />
  );
}
```

---

# Wait...

That's it?

Yes.

Sanity already understands:

```text id="jjjlwm"
Paragraphs
Headings
Lists
Quotes
```

out of the box.

---

# Rendering The Body

Open:

```text id="njjlwm"
app/posts/[slug]/page.tsx
```

Import:

```tsx id="jlwm2g"
import PortableTextRenderer
  from "@/components/PortableTextRenderer";
```

Add:

```tsx id="yjlwm5"
<PortableTextRenderer
  value={post.body}
/>
```

Example:

```tsx id="jlwm9t"
return (
  <article>
    <h1>
      {post.title}
    </h1>

    <p>
      By {post.author.name}
    </p>

    <p>
      {post.excerpt}
    </p>

    <PortableTextRenderer
      value={post.body}
    />
  </article>
);
```

Refresh.

Congratulations.

You just rendered your first Portable Text document.

---

# But It Doesn't Look Very Pretty

That's because Portable Text is currently rendering:

```html id="jlwmz1"
<h2>

<p>

<ul>

<blockquote>
```

using default HTML elements.

We can customize everything.

---

# Creating Custom Renderers

Update:

```tsx id="jlwmz2"
import { PortableText }
  from "@portabletext/react";

const components = {
  block: {
    h1: ({
      children,
    }: any) => (
      <h1>
        {children}
      </h1>
    ),

    h2: ({
      children,
    }: any) => (
      <h2>
        {children}
      </h2>
    ),

    normal: ({
      children,
    }: any) => (
      <p>
        {children}
      </p>
    ),
  },
};

export default function
PortableTextRenderer({
  value,
}: {
  value: any;
}) {
  return (
    <PortableText
      value={value}
      components={components}
    />
  );
}
```

---

# What Are We Doing Here?

Suppose Sanity encounters:

```json id="jlwmz3"
{
  "style": "h2"
}
```

The renderer asks:

```text id="jlwmz4"
How should I render h2?
```

We answer:

```tsx id="jlwmz5"
h2: ({ children }) =>
  <h2>{children}</h2>
```

Diagram:

```text id="jlwmz6"
Portable Text

      │
      ▼

style = h2

      │
      ▼

Custom Renderer

      │
      ▼

React Component

      │
      ▼

HTML
```

---

# Adding Images

Soon we'll want:

```text id="jlwmz7"
Text

Image

Text
```

Portable Text supports this.

Add:

```tsx id="jlwmz8"
types: {
  image: ({
    value,
  }: any) => {
    return (
      <img
        src={value.asset.url}
        alt=""
      />
    );
  },
},
```

---

# Wait...

Why Are Images "Types"?

Because Portable Text thinks:

```text id="jlwmz9"
Document

├── Paragraph
├── Paragraph
├── Image
├── Paragraph
└── Quote
```

Everything is simply a node.

This is exactly how compilers work.

---

# Rendering Links

Suppose your article contains:

```text id="jlwm10"
Visit Next.js
```

with a hyperlink.

Portable Text stores:

```json id="jlwm11"
{
  "_type": "link",
  "href":
    "https://nextjs.org"
}
```

We render it:

```tsx id="jlwm12"
marks: {
  link: ({
    children,
    value,
  }: any) => (
    <a
      href={value.href}
      target="_blank"
    >
      {children}
    </a>
  ),
},
```

---

# The Hidden Architecture

Suppose our article contains:

```text id="jlwm13"
Heading

Paragraph

Image

Paragraph
```

Internally:

```text id="jlwm14"
Portable Text

      │
      ▼

Abstract Syntax Tree

      │
      ▼

React Components

      │
      ▼

React Tree

      │
      ▼

HTML
```

---

# Why Modern Editors Use ASTs

Traditional editors:

```html id="jlwm15"
<h1>
Title
</h1>
```

Problem:

```text id="jlwm16"
Presentation only
```

AST editors:

```json id="jlwm17"
{
  "type": "heading",
  "level": 1,
  "text": "Title"
}
```

Benefits:

```text id="jlwm18"
✓ Multiple outputs
✓ Validation
✓ Transformations
✓ Search
✓ AI processing
✓ Analytics
```

---

# Wait...

Does React Also Use Trees?

Yes.

Suppose we write:

```tsx id="jlwm19"
<Article>
  <Title />
  <Body />
</Article>
```

React builds:

```text id="jlwm20"
Article
   │
   ├── Title
   │
   └── Body
```

Portable Text builds:

```text id="jlwm21"
Document
    │
    ├── Heading
    │
    └── Paragraph
```

Notice something?

```text id="jlwm22"
Everything
      is
      a
      tree.
```

---

# Our Full Rendering Pipeline

We now have:

```text id="jlwm23"
Editor
   │
   ▼
Sanity Studio
   │
   ▼
Portable Text AST
   │
   ▼
Content Lake
   │
   ▼
GROQ
   │
   ▼
Next.js
   │
   ▼
PortableText Renderer
   │
   ▼
React Tree
   │
   ▼
HTML
   │
   ▼
Browser
```

---

# Mental Model To Remember Forever

Beginners think:

```text id="jlwm24"
Rich Text
       =
HTML
```

Modern systems think:

```text id="jlwm25"
Rich Text
       =
Structured Document Tree
```

Or even more generally:

```text id="jlwm26"
Everything in software
            =
Trees
```

Examples:

```text id="jlwm27"
HTML DOM
React
Portable Text
Compilers
File Systems
Routers
JSON
ASTs
```

Once you begin seeing trees, you begin understanding software architecture.

---

# Up Next

In **Part 14**, we'll build images properly and learn:

* how Sanity asset storage works,
* why images are references,
* what image transformation CDNs are,
* how `next/image` works,
* how image optimization pipelines function,
* and why modern websites never serve raw images.
