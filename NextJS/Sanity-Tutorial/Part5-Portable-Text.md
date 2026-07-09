# Sanity Mastery - Part 5: Rendering Portable Text

Portable Text is Sanity's JSON representation of rich text (from the `blockContent` field in Part 2). It's **not HTML** — this is intentional, so the same content can render as React, native mobile UI, plain text, etc. `@portabletext/react` converts it into React elements.

## Anatomy of a Portable Text Value

```json
[
  {
    "_type": "block",
    "style": "h2",
    "children": [{ "_type": "span", "text": "Section Title" }]
  },
  {
    "_type": "block",
    "style": "normal",
    "children": [
      { "_type": "span", "text": "Some " },
      { "_type": "span", "text": "bold", "marks": ["strong"] },
      { "_type": "span", "text": " text with a " },
      { "_type": "span", "text": "link", "marks": ["link1"] }
    ],
    "markDefs": [
      { "_key": "link1", "_type": "link", "href": "https://sanity.io" }
    ]
  },
  { "_type": "image", "asset": { "_ref": "image-abc-800x600-jpg", "_type": "reference" }, "alt": "A photo" },
  { "_type": "codeBlock", "language": "tsx", "code": "const x = 1;" }
]
```

## Step 1: Basic renderer

```tsx
// src/components/PortableTextRenderer.tsx
import { PortableText, type PortableTextComponents } from "@portabletext/react";
import Image from "next/image";
import { urlFor } from "@/sanity/image"; // built in Part 6

// Components map controls how every block/mark/type renders — this is where
// Portable Text's "structured, not HTML" design pays off: full control, no dangerouslySetInnerHTML.
const components: PortableTextComponents = {
  block: {
    // Custom heading styles defined in our blockContent schema (Part 2)
    h2: ({ children }) => <h2 className="text-2xl font-bold mt-8 mb-4">{children}</h2>,
    h3: ({ children }) => <h3 className="text-xl font-semibold mt-6 mb-3">{children}</h3>,
    blockquote: ({ children }) => (
      <blockquote className="border-l-4 border-gray-300 pl-4 italic my-4">
        {children}
      </blockquote>
    ),
    normal: ({ children }) => <p className="mb-4 leading-relaxed">{children}</p>,
  },
  marks: {
    strong: ({ children }) => <strong className="font-semibold">{children}</strong>,
    em: ({ children }) => <em className="italic">{children}</em>,
    code: ({ children }) => (
      <code className="bg-gray-100 rounded px-1 py-0.5 text-sm">{children}</code>
    ),
    // Custom "link" annotation from Part 2's schema
    link: ({ value, children }) => {
      const target = value?.blank ? "_blank" : undefined;
      return (
        <a
          href={value?.href}
          target={target}
          rel={target ? "noopener noreferrer" : undefined}
          className="text-blue-600 underline hover:text-blue-800"
        >
          {children}
        </a>
      );
    },
  },
  types: {
    // Embedded image type from blockContent's array `of`
    image: ({ value }) => (
      <div className="my-6">
        <Image
          src={urlFor(value).width(800).height(450).fit("crop").url()}
          alt={value.alt || ""}
          width={800}
          height={450}
          className="rounded-lg"
        />
      </div>
    ),
    // Custom codeBlock object type
    codeBlock: ({ value }) => (
      <pre className="bg-gray-900 text-gray-100 rounded-lg p-4 overflow-x-auto my-6">
        <code className={`language-${value.language}`}>{value.code}</code>
      </pre>
    ),
  },
  list: {
    bullet: ({ children }) => <ul className="list-disc pl-6 mb-4">{children}</ul>,
    number: ({ children }) => <ol className="list-decimal pl-6 mb-4">{children}</ol>,
  },
  listItem: {
    bullet: ({ children }) => <li className="mb-1">{children}</li>,
    number: ({ children }) => <li className="mb-1">{children}</li>,
  },
};

export function PortableTextRenderer({ value }: { value: unknown[] }) {
  return <PortableText value={value as never} components={components} />;
}
```

## Step 2: Use it on the post page (replacing the `JSON.stringify` stub from Part 4)

```tsx
// src/app/blog/[slug]/page.tsx (relevant excerpt — replaces the body rendering line)
import { PortableTextRenderer } from "@/components/PortableTextRenderer";

// ...inside the component, replace:
// <div className="prose mt-8">{JSON.stringify(post.body)}</div>
// with:
<div className="prose mt-8 max-w-none">
  <PortableTextRenderer value={post.body} />
</div>
```

## Why Not Just Render Raw HTML?

| Approach | Risk / Limitation |
|---|---|
| Store HTML in Sanity, `dangerouslySetInnerHTML` | XSS risk, no structured editing, hard to reuse across platforms |
| Portable Text + `@portabletext/react` | Fully typed, React-native rendering, safe by construction, portable to any renderer |

## Extracting Plain Text (for excerpts, search indexing, SEO description fallback)

```ts
// src/lib/portableTextToPlainText.ts
// Useful when you need a plain string (e.g. auto-generating an SEO description
// if an editor didn't fill in the `seo.metaDescription` override field from Part 2).
export function portableTextToPlainText(blocks: any[]): string {
  return blocks
    .filter((block) => block._type === "block")
    .map((block) =>
      block.children
        .map((child: { text: string }) => child.text)
        .join("")
    )
    .join("\n\n");
}
```

```ts
// Usage example, e.g. inside generateMetadata (Part 6/9 touch on metadata too)
const fallbackDescription = post.seo?.metaDescription
  ?? portableTextToPlainText(post.body).slice(0, 155);
```

## Checkpoint ✅
- [ ] `PortableTextRenderer` component created with block/mark/type/list handlers matching every custom type from Part 2's schema (`link`, `image`, `codeBlock`)
- [ ] Post detail page renders real formatted rich text, not raw JSON
- [ ] Links, bold/italic, headings, embedded images, and code blocks all render correctly from your test posts

**Next: Part 6 — Images**
