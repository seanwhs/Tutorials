# Part 5A: Introducing `@react-pdf/renderer` & Rendering the First Nodes

## What This Installment Covers
Installing `@react-pdf/renderer`, understanding its React-component-based PDF model, and building the first slice of `lib/converters/toPdf.tsx` — enough to correctly render `heading`, `paragraph`, `text`, `strong`, and `emphasis` nodes. We verify this in complete isolation (a standalone test script), before touching the Route Handler at all. Lists, code blocks, tables, and images arrive in 5B and 5C.

---

## Step 1 — Installing `@react-pdf/renderer`

### The Target
Add `@react-pdf/renderer` to our dependencies.

### The Concept

> **Analogy — A Word Processor Controlled Entirely by Code.** Most PDF libraries make you think in terms of pixel coordinates: "draw text at x=50, y=100." `@react-pdf/renderer` instead lets you describe a PDF using **React components** — `<Document>`, `<Page>`, `<View>`, `<Text>` — the same mental model you already use for web UIs. Behind the scenes, it uses a Flexbox-based layout engine (conceptually similar to CSS Flexbox on the web) to automatically figure out positioning, wrapping, and pagination for you. This is precisely why we chose it: it lets us reuse the "component that recursively renders itself" pattern from Part 3B's `AstTreeView`, just producing PDF primitives instead of debug HTML.

### The Implementation

```bash
npm install @react-pdf/renderer
```

### The Verification

```bash
ls node_modules/@react-pdf/renderer
```

Expected: the package folder's contents print with no error.

```bash
npx tsc --noEmit
```

Expected: no output (nothing has changed yet that could break type-checking, but this confirms the install itself didn't corrupt anything).

---

## Step 2 — The Core Mental Model: Four Primitives

### The Target
No code yet — understanding the four building blocks we'll use for nearly everything in this converter.

### The Concept

> **Analogy — Building With Four LEGO Brick Shapes.** Nearly every visual PDF library gives you dozens of specialized shapes. `@react-pdf/renderer` deliberately gives you a small, composable set instead — much like how LEGO builds enormously complex models from a handful of brick shapes, combined cleverly.

| Component | Plain-English Job |
|---|---|
| `<Document>` | The entire PDF file. Everything else lives inside exactly one of these. |
| `<Page>` | One page. `@react-pdf/renderer` automatically starts new pages when content overflows — we rarely create `<Page>` elements manually beyond the first. |
| `<View>` | A generic box/container — the PDF equivalent of an HTML `<div>`. Used for grouping, indentation, backgrounds, borders. |
| `<Text>` | The **only** component allowed to contain actual text content. Unlike HTML, you cannot put raw text directly inside a `<View>` — it must be wrapped in `<Text>`. |

This last rule — **text must always be wrapped in `<Text>`, never placed loose inside a `<View>`** — is the single most common mistake beginners make with this library, so we call it out here before writing a line of converter code: any time you see raw string content in our AST, it must land inside a `<Text>` element, not directly inside a `<View>`.

### The Verification
No runnable check — proceed to Step 3.

---

## Step 3 — Styling with `StyleSheet.create`

### The Target
No new files yet — understanding how styles work in this library before we write our first real styles in Step 4.

### The Concept

> **Analogy — A CSS-Like Dictionary, But Camel-Cased and Pre-Registered.** `StyleSheet.create({...})` looks and behaves almost exactly like writing CSS — properties like `fontSize`, `marginBottom`, `color` — except property names are camelCase (`fontSize` not `font-size`, matching React's convention elsewhere), and you register your styles once as a named dictionary, then reference them by key (`styles.heading1`) on any component's `style` prop. This upfront registration lets `@react-pdf/renderer` optimize how styles get applied during PDF generation, rather than recalculating raw style objects for every element.

A critical, sharp difference from web CSS: **there is no cascading/inheritance of most properties** the way there is in a browser (e.g., setting `color` on a `<View>` does not automatically color the `<Text>` inside it, the way it would with a CSS parent-child relationship on the web). Every `<Text>` element generally needs its own explicit styling for text-related properties. We'll see this concretely in Step 4's code.

### The Verification
No runnable check — proceed to Step 4.

---

## Step 4 — Building the First Slice of `lib/converters/toPdf.tsx`

### The Target
`lib/converters/toPdf.tsx` — a recursive component, `MdastNodeToPdf`, that currently knows how to handle exactly five node types: `root`, `heading`, `paragraph`, `text`, `strong`, and `emphasis`. Every other node type will (for now) render nothing, with a console warning — we'll expand coverage in 5B and 5C.

### The Concept

> **Analogy — Teaching One Translator a Few Words at a Time.** Rather than trying to teach our AST-to-PDF translator every possible Markdown construct in one sitting (a recipe for an unreadable, error-prone wall of code), we teach it a handful of the most common node types first, verify each works correctly in isolation, and expand its vocabulary incrementally. This mirrors exactly how Part 3B's `AstTreeView` handled *any* node type generically for *display* purposes — except now, each node type needs its own specific, deliberate mapping to a PDF primitive, since "what a heading looks like in a PDF" is a real design decision, not just a debug label.

Notice the filename extension: **`.tsx`**, not `.ts`. This is required because this file contains JSX (`<View>`, `<Text>`, angle-bracket syntax) — TypeScript's compiler needs the `.tsx` extension to know to parse JSX syntax within it, exactly the same reason `.tsx` is used for our React components elsewhere in this project.

### The Implementation

**`lib/converters/toPdf.tsx`**

```tsx
import { Document, Page, View, Text, StyleSheet } from "@react-pdf/renderer";
import type { Root, RootContent, PhrasingContent } from "mdast";

// StyleSheet.create registers our visual design once. Every value here is a
// deliberate design decision mapping Markdown semantics to a printed look:
// e.g., a depth-1 heading is visually much larger/bolder than a depth-3 one,
// mirroring how a reader intuitively expects heading hierarchy to look.
const styles = StyleSheet.create({
  page: {
    padding: 40,
    fontSize: 11,
    fontFamily: "Helvetica",
    color: "#1a1a1a",
  },
  heading1: { fontSize: 24, fontWeight: 700, marginBottom: 12, marginTop: 4 },
  heading2: { fontSize: 19, fontWeight: 700, marginBottom: 10, marginTop: 10 },
  heading3: { fontSize: 15, fontWeight: 700, marginBottom: 8, marginTop: 8 },
  heading4: { fontSize: 13, fontWeight: 700, marginBottom: 6, marginTop: 6 },
  heading5: { fontSize: 12, fontWeight: 700, marginBottom: 6, marginTop: 6 },
  heading6: { fontSize: 11, fontWeight: 700, marginBottom: 6, marginTop: 6 },
  paragraph: { marginBottom: 8, lineHeight: 1.5 },
  bold: { fontWeight: 700 },
  italic: { fontStyle: "italic" },
});

// Maps a heading's `depth` (1–6) to the correct style key. Kept as a small
// lookup table rather than a chain of if/else — easy to scan, easy to
// extend if our design ever needs a 7th tier (it won't, since Markdown
// itself caps at 6, but the pattern stays clean either way).
const HEADING_STYLES = [
  styles.heading1,
  styles.heading2,
  styles.heading3,
  styles.heading4,
  styles.heading5,
  styles.heading6,
];

/**
 * Recursively renders a single mdast INLINE node (text, strong, emphasis)
 * into React-PDF <Text> content. Inline nodes never start a new block —
 * they always live INSIDE a parent <Text> element (see renderBlockNode's
 * paragraph/heading cases below), which is why this function returns plain
 * strings/fragments rather than its own wrapping <Text>.
 */
function renderInline(node: PhrasingContent): React.ReactNode {
  switch (node.type) {
    case "text":
      return node.value;

    case "strong":
      // A <Text> nested inside another <Text> is valid in React-PDF, and is
      // exactly how inline style changes (like going bold mid-sentence) are
      // expressed — the inner <Text> just adds additional styling on top.
      return (
        <Text style={styles.bold}>
          {node.children.map((child, i) => (
            <Text key={i}>{renderInline(child)}</Text>
          ))}
        </Text>
      );

    case "emphasis":
      return (
        <Text style={styles.italic}>
          {node.children.map((child, i) => (
            <Text key={i}>{renderInline(child)}</Text>
          ))}
        </Text>
      );

    default:
      // Node types we haven't taught this renderer yet (links, inline code,
      // images, etc. — arriving in 5B/5C). We fail SAFELY: log a warning for
      // developer visibility, but render nothing rather than crashing the
      // whole PDF generation over one unsupported node.
      console.warn(`[toPdf] Unsupported inline node type: "${node.type}"`);
      return null;
  }
}

/**
 * Recursively renders a single mdast BLOCK node (heading, paragraph) into
 * a React-PDF element. Block nodes each become their own <Text> or <View>,
 * stacked vertically on the page.
 */
function renderBlockNode(node: RootContent, key: number): React.ReactNode {
  switch (node.type) {
    case "heading": {
      const style = HEADING_STYLES[node.depth - 1] ?? styles.heading6;
      return (
        <Text key={key} style={style}>
          {node.children.map((child, i) => (
            <Text key={i}>{renderInline(child)}</Text>
          ))}
        </Text>
      );
    }

    case "paragraph":
      return (
        <Text key={key} style={styles.paragraph}>
          {node.children.map((child, i) => (
            <Text key={i}>{renderInline(child)}</Text>
          ))}
        </Text>
      );

    default:
      // Same "fail safely" philosophy as renderInline above: block-level
      // node types we haven't taught this renderer yet (lists, code blocks,
      // tables, images, blockquotes — arriving in 5B/5C) render nothing for
      // now, with a warning, rather than crashing the entire PDF.
      console.warn(`[toPdf] Unsupported block node type: "${node.type}"`);
      return null;
  }
}

/**
 * Converts a parsed mdast Root node into a complete React-PDF <Document>
 * element, ready to be passed to @react-pdf/renderer's rendering functions
 * (renderToBuffer, renderToStream, etc. — used starting in 5C once this
 * converter is wired into the Route Handler).
 */
export function toPdf(ast: Root): React.ReactElement {
  return (
    <Document>
      <Page size="A4" style={styles.page}>
        {ast.children.map((node, i) => renderBlockNode(node, i))}
      </Page>
    </Document>
  );
}
```

A few details worth pausing on:

- **`renderInline` vs `renderBlockNode` are two separate functions**, not one combined switch statement. This mirrors a real, structural distinction in `mdast` itself: block nodes (`heading`, `paragraph`, `list`, etc.) always stack vertically down the page, while inline nodes (`text`, `strong`, `emphasis`, `link`) always flow horizontally *within* a single block. Keeping these as two functions — rather than one giant switch handling both kinds — makes the code's structure mirror the AST's own structure, which will make it much easier to extend correctly in 5B when we add lists (a block concept) and links (an inline concept) without confusing the two.
- **Nested `<Text>` for `strong`/`emphasis`** — recall Step 3's warning that styles don't cascade automatically. Wrapping inline formatting nodes in their own `<Text style={...}>` is precisely how React-PDF *does* support "bold in the middle of a sentence" — each nested `<Text>` contributes its own additional styling on top of its parent's, purely through this explicit nesting, not through any implicit inheritance.
- **The `default` cases in both functions returning `null` with a `console.warn`** is a deliberate design decision worth calling out by name: this is **graceful degradation** — when our renderer doesn't yet understand something, we skip it silently (from the end user's point of view) rather than throwing an exception that would abort the *entire* PDF generation over one unsupported node. Part 8 will build on this exact philosophy formally; here in Part 5 we're establishing the pattern from the very first line of converter code.
- **`React.ReactNode` / `React.ReactElement` return types** — note we're relying on the global `React` namespace for these types without an explicit `import React from "react"` at the top. This works because our project's TypeScript configuration (generated by `create-next-app` in Part 1A) uses the modern JSX transform, which makes these types available globally. If your editor underlines `React` as undefined, add `import type { ReactNode, ReactElement } from "react";` at the top and use those names directly instead — functionally identical, just spelled differently.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output. This confirms every node type we've handled (`heading`, `paragraph`, `text`, `strong`, `emphasis`) correctly matches the real `mdast` types from `@types/mdast`, and that our `default` cases correctly cover every *other* possible node type without TypeScript complaining about a non-exhaustive switch.

Now let's actually **generate a real PDF file**, in complete isolation from the Route Handler — using a small, throwaway Node.js script. This proves `toPdf()` genuinely produces a valid PDF buffer before we wire it into any HTTP plumbing, isolating any bugs to exactly this one new file.

Create a temporary test script:

**`scripts/test-pdf.tsx`**

```tsx
import { writeFileSync } from "fs";
import { renderToBuffer } from "@react-pdf/renderer";
import { parseMarkdown } from "../lib/parseMarkdown";
import { toPdf } from "../lib/converters/toPdf";

async function main() {
  const markdown = `# Hello GreyMatter

This is **bold text**, this is *italic text*, and this is **bold with *nested italic* inside**.

## A Second Heading

Another paragraph to confirm multiple blocks render correctly, one after another.
`;

  const ast = parseMarkdown(markdown);
  const pdfElement = toPdf(ast);
  const buffer = await renderToBuffer(pdfElement);

  writeFileSync("test-output.pdf", buffer);
  console.log(`✅ Wrote test-output.pdf (${buffer.byteLength} bytes)`);
}

main().catch((err) => {
  console.error("❌ Failed to generate test PDF:", err);
  process.exit(1);
});
```

Run it directly with `npx tsx` (a tool that runs TypeScript files directly in Node without a separate build step — install it as a one-off if you don't have it):

```bash
npx tsx scripts/test-pdf.tsx
```

Expected terminal output:

```
✅ Wrote test-output.pdf (XXXX bytes)
```

Now open `test-output.pdf` in your terminal directory with a **real PDF viewer** (double-click it in your file explorer, or `open test-output.pdf` on macOS / `start test-output.pdf` on Windows). Confirm:

1. **"Hello GreyMatter"** appears as a large, bold, level-1-sized heading at the top.
2. The first paragraph shows **"bold text"** genuinely bold, *"italic text"* genuinely italicized, and the nested case ("bold with *nested italic* inside") shows both bold and italic styling simultaneously on the innermost words — proving our recursive nested-`<Text>` approach correctly composes multiple simultaneous inline styles.
3. **"A Second Heading"** appears smaller than the first heading (level-2 sizing) but still clearly bold and larger than body text.
4. The final paragraph renders as ordinary, non-bold, non-italic body text below it.

Once confirmed, delete the test artifacts so they don't linger in your project:

```bash
rm test-output.pdf
```

(Keep `scripts/test-pdf.tsx` around — we'll extend it in 5B and 5C as we add more node type coverage, rather than recreating it from scratch each time.)

---

## ✅ Part 5A — Complete

You now have:

- `@react-pdf/renderer` installed and understood at a conceptual level: `<Document>` / `<Page>` / `<View>` / `<Text>` as four composable primitives, with the critical rule that all text content must live inside `<Text>`.
- The beginning of `lib/converters/toPdf.tsx` — a working recursive renderer correctly handling `heading` (all six depths), `paragraph`, `text`, `strong`, and `emphasis`, including correctly nested/composed inline styles.
- Proof, via a real generated and visually inspected PDF file, that this first slice of the converter works correctly end-to-end — entirely isolated from the Route Handler, so any future bugs in later steps can be isolated to exactly what changed.
- An established "graceful degradation" pattern (`console.warn` + render nothing) for node types we haven't taught the renderer yet — the same philosophy Part 8 will later formalize project-wide.

---
# Part 5B: Lists, Code Blocks, and Blockquotes

## What This Installment Covers
Extending `lib/converters/toPdf.tsx` to handle three more block-level node types: `list`/`listItem` (with proper indentation, bullet/number glyphs, and nesting support), `code` (monospace text in a shaded box), and `blockquote` (indented with a left border accent). We also add `inlineCode` and `link` to our inline renderer. By the end, a much more realistic document renders correctly as a real PDF.

---

## Step 5 — Understanding the List Rendering Challenge

### The Target
No code yet — understanding why lists need more thought than headings/paragraphs did, before writing the code.

### The Concept

> **Analogy — Nested Folders on a Filesystem.** A heading or paragraph is a "flat" concept — render it, move on. A list is different: a `list` node contains `listItem` children, and each `listItem` can itself contain *another* `list` node (a nested sub-list), which can contain more `listItem`s, and so on — exactly like folders that can contain other folders, arbitrarily deep. Our renderer needs to handle this **recursively**, tracking how deep we currently are, so we can indent each level a little further than its parent, exactly like how a nested folder's contents are visually indented further in a file explorer.

We also need to track **two different pieces of "list context"** as we recurse:
1. **Depth** — how far to indent (each nesting level pushes content further right).
2. **Ordered vs. unordered, and item number** — a `list` node's `ordered: true` field means we render `1.`, `2.`, `3.` glyphs instead of bullet (`•`) glyphs, and we need to track *which* number each item is.

Rather than passing these as separate function parameters that multiply awkwardly, we'll bundle them into one small "list rendering context" object passed down through the recursion — a clean, standard pattern for passing "ambient" state through a recursive tree walk.

### The Verification
No runnable check — proceed to Step 6.

---

## Step 6 — Extending the Renderer: Lists, Code, Blockquotes

### The Target
The full, updated `lib/converters/toPdf.tsx`, adding `list`, `listItem`, `code`, `blockquote` to `renderBlockNode`, and `inlineCode`, `link` to `renderInline`.

### The Implementation

**`lib/converters/toPdf.tsx`** (full file, replacing the previous version)

```tsx
import { Document, Page, View, Text, StyleSheet } from "@react-pdf/renderer";
import type { Root, RootContent, PhrasingContent, ListItem } from "mdast";

const styles = StyleSheet.create({
  page: {
    padding: 40,
    fontSize: 11,
    fontFamily: "Helvetica",
    color: "#1a1a1a",
  },
  heading1: { fontSize: 24, fontWeight: 700, marginBottom: 12, marginTop: 4 },
  heading2: { fontSize: 19, fontWeight: 700, marginBottom: 10, marginTop: 10 },
  heading3: { fontSize: 15, fontWeight: 700, marginBottom: 8, marginTop: 8 },
  heading4: { fontSize: 13, fontWeight: 700, marginBottom: 6, marginTop: 6 },
  heading5: { fontSize: 12, fontWeight: 700, marginBottom: 6, marginTop: 6 },
  heading6: { fontSize: 11, fontWeight: 700, marginBottom: 6, marginTop: 6 },
  paragraph: { marginBottom: 8, lineHeight: 1.5 },
  bold: { fontWeight: 700 },
  italic: { fontStyle: "italic" },
  inlineCode: {
    fontFamily: "Courier",
    backgroundColor: "#f0f0f0",
    fontSize: 10,
  },
  link: {
    color: "#2563eb",
    textDecoration: "underline",
  },

  // --- List styles ---
  // A single list ROW: bullet/number glyph + item content, side by side.
  listItemRow: {
    flexDirection: "row",
    marginBottom: 4,
  },
  listItemBullet: {
    width: 18,
    fontSize: 11,
  },
  listItemContent: {
    flex: 1,
    lineHeight: 1.5,
  },

  // --- Code block styles ---
  codeBlock: {
    backgroundColor: "#1f2937",
    borderRadius: 4,
    padding: 10,
    marginBottom: 8,
  },
  codeBlockText: {
    fontFamily: "Courier",
    fontSize: 9.5,
    color: "#f9fafb",
    lineHeight: 1.4,
  },

  // --- Blockquote styles ---
  blockquote: {
    borderLeftWidth: 3,
    borderLeftColor: "#d1d5db",
    borderLeftStyle: "solid",
    paddingLeft: 10,
    marginBottom: 8,
  },
  blockquoteText: {
    fontStyle: "italic",
    color: "#4b5563",
    lineHeight: 1.5,
  },
});

const HEADING_STYLES = [
  styles.heading1,
  styles.heading2,
  styles.heading3,
  styles.heading4,
  styles.heading5,
  styles.heading6,
];

/**
 * Carries "ambient" state down through recursive list rendering: how deeply
 * nested we currently are (for indentation) and whether the immediately
 * enclosing list is ordered (numbers) or unordered (bullets).
 */
interface ListContext {
  depth: number;
  ordered: boolean;
}

function renderInline(node: PhrasingContent): React.ReactNode {
  switch (node.type) {
    case "text":
      return node.value;

    case "strong":
      return (
        <Text style={styles.bold}>
          {node.children.map((child, i) => (
            <Text key={i}>{renderInline(child)}</Text>
          ))}
        </Text>
      );

    case "emphasis":
      return (
        <Text style={styles.italic}>
          {node.children.map((child, i) => (
            <Text key={i}>{renderInline(child)}</Text>
          ))}
        </Text>
      );

    case "inlineCode":
      // inlineCode is a LEAF node (no children — see Part 3A's reference
      // table), so we read its `value` field directly rather than mapping
      // over children like strong/emphasis do.
      return <Text style={styles.inlineCode}>{node.value}</Text>;

    case "link":
      // React-PDF's <Text> component supports a `src` prop... actually, for
      // clickable links specifically, @react-pdf/renderer provides a
      // dedicated <Link> component — but to keep our inline renderer's
      // return type consistent (React.ReactNode, always nested inside a
      // parent <Text>), we style it visually as a link here and note that
      // full click-through behavior can be added via the dedicated <Link>
      // component if needed. For our purposes, styling it distinctly
      // (blue, underlined) already correctly signals "this was a link" in
      // the printed output.
      return (
        <Text style={styles.link}>
          {node.children.map((child, i) => (
            <Text key={i}>{renderInline(child)}</Text>
          ))}
        </Text>
      );

    default:
      console.warn(`[toPdf] Unsupported inline node type: "${node.type}"`);
      return null;
  }
}

/** Renders a single `listItem`, including any nested sub-lists inside it. */
function renderListItem(
  item: ListItem,
  index: number,
  context: ListContext,
  key: number
): React.ReactNode {
  // Per Part 3A's reference table: `checked` is null for a normal item,
  // true/false for a GFM task list item (`- [x]` / `- [ ]`).
  const bulletGlyph =
    item.checked === true
      ? "☑"
      : item.checked === false
      ? "☐"
      : context.ordered
      ? `${index + 1}.`
      : "•";

  return (
    <View key={key} style={{ marginLeft: context.depth * 16 }}>
      <View style={styles.listItemRow}>
        <Text style={styles.listItemBullet}>{bulletGlyph}</Text>
        <View style={styles.listItemContent}>
          {/* A listItem's children are typically `paragraph` nodes (per
              standard mdast structure) and/or a nested `list` node. We walk
              them here directly rather than calling the generic
              renderBlockNode, since a listItem's paragraph shouldn't get
              the normal paragraph's bottom margin (it would create uneven,
              overly-spaced-out list rows). */}
          {item.children.map((child, i) => {
            if (child.type === "paragraph") {
              return (
                <Text key={i}>
                  {child.children.map((inline, j) => (
                    <Text key={j}>{renderInline(inline)}</Text>
                  ))}
                </Text>
              );
            }
            if (child.type === "list") {
              // THE RECURSIVE STEP: a nested list inside this item is
              // rendered by calling renderList again, with depth+1 so its
              // items indent one level further than their parent.
              return renderList(child.children as ListItem[], {
                depth: context.depth + 1,
                ordered: child.ordered ?? false,
              }, i);
            }
            console.warn(`[toPdf] Unsupported listItem child type: "${child.type}"`);
            return null;
          })}
        </View>
      </View>
    </View>
  );
}

/** Renders an entire `list` node's items, given the current nesting context. */
function renderList(
  items: ListItem[],
  context: ListContext,
  key: number
): React.ReactNode {
  return (
    <View key={key}>
      {items.map((item, i) => renderListItem(item, i, context, i))}
    </View>
  );
}

function renderBlockNode(node: RootContent, key: number): React.ReactNode {
  switch (node.type) {
    case "heading": {
      const style = HEADING_STYLES[node.depth - 1] ?? styles.heading6;
      return (
        <Text key={key} style={style}>
          {node.children.map((child, i) => (
            <Text key={i}>{renderInline(child)}</Text>
          ))}
        </Text>
      );
    }

    case "paragraph":
      return (
        <Text key={key} style={styles.paragraph}>
          {node.children.map((child, i) => (
            <Text key={i}>{renderInline(child)}</Text>
          ))}
        </Text>
      );

    case "list":
      // Top-level list: starts at depth 0.
      return renderList(
        node.children as ListItem[],
        { depth: 0, ordered: node.ordered ?? false },
        key
      );

    case "code":
      return (
        <View key={key} style={styles.codeBlock}>
          <Text style={styles.codeBlockText}>{node.value}</Text>
        </View>
      );

    case "blockquote":
      return (
        <View key={key} style={styles.blockquote}>
          {node.children.map((child, i) => {
            // A blockquote typically contains paragraph children — we
            // render them with the italic blockquote text style rather
            // than the normal paragraph style.
            if (child.type === "paragraph") {
              return (
                <Text key={i} style={styles.blockquoteText}>
                  {child.children.map((inline, j) => (
                    <Text key={j}>{renderInline(inline)}</Text>
                  ))}
                </Text>
              );
            }
            console.warn(`[toPdf] Unsupported blockquote child type: "${child.type}"`);
            return null;
          })}
        </View>
      );

    default:
      console.warn(`[toPdf] Unsupported block node type: "${node.type}"`);
      return null
  }
}

/**
 * Converts a parsed mdast Root node into a complete React-PDF <Document>
 * element, ready to be passed to @react-pdf/renderer's rendering functions.
 */
export function toPdf(ast: Root): React.ReactElement {
  return (
    <Document>
      <Page size="A4" style={styles.page}>
        {ast.children.map((node, i) => renderBlockNode(node, i))}
      </Page>
    </Document>
  );
}
```

That completes the file. A few details worth pausing on before we test it:

- **`ListContext` as a small carried-down object** (`{ depth, ordered }`) is the concrete implementation of Step 5's "ambient state through recursion" idea. Every recursive call into `renderList`/`renderListItem` either passes the *same* context along unchanged, or creates a new one with `depth + 1` — exactly like how a file explorer keeps track of "how many folders deep am I" as it recurses into subfolders.
- **Why `renderListItem` handles `paragraph` and `list` children manually, instead of calling the generic `renderBlockNode`** — a `listItem`'s inner paragraph needs *different* styling than a normal top-level paragraph (no extra bottom margin, since that would make list rows look unevenly spaced). Rather than adding special-case flags into `renderBlockNode` to handle "am I inside a list item right now," we keep that logic scoped locally to `renderListItem`, which is easier to reason about in isolation.
- **The bullet glyph logic** (`☑` / `☐` / numbered / bulleted) directly reads the `checked` and `ordered` fields from Part 3A's reference table — this is a direct, traceable line from "the AST has this field" to "the PDF shows this specific glyph."

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output — confirming every new node type (`list`, `listItem`, `code`, `blockquote`, `inlineCode`, `link`) type-checks correctly against `@types/mdast`.

Now extend our isolated test script from 5A to exercise everything new:

**`scripts/test-pdf.tsx`** (replace the `markdown` variable's content with this richer sample; everything else in the file stays the same)

```tsx
import { writeFileSync } from "fs";
import { renderToBuffer } from "@react-pdf/renderer";
import { parseMarkdown } from "../lib/parseMarkdown";
import { toPdf } from "../lib/converters/toPdf";

async function main() {
  const markdown = `# Hello GreyMatter

This is **bold text**, this is *italic text*, and this is \`inline code\`.

Here's a [link to somewhere](https://example.com).

## A Bulleted List

- First item
- Second item with **bold** inside
  - A nested sub-item
  - Another nested sub-item
- Third top-level item

## A Numbered List

1. Step one
2. Step two
3. Step three

## A Task List

- [x] Completed task
- [ ] Incomplete task

## A Code Block

\`\`\`typescript
function greet(name: string): string {
  return \`Hello, \${name}!\`;
}
\`\`\`

## A Blockquote

> This is a blockquote. It should appear indented, italicized, with a
> vertical accent line on its left edge.
`;

  const ast = parseMarkdown(markdown);
  const pdfElement = toPdf(ast);
  const buffer = await renderToBuffer(pdfElement);

  writeFileSync("test-output.pdf", buffer);
  console.log(`✅ Wrote test-output.pdf (${buffer.byteLength} bytes)`);
}

main().catch((err) => {
  console.error("❌ Failed to generate test PDF:", err);
  process.exit(1);
});
```

Run it:

```bash
npx tsx scripts/test-pdf.tsx
```

Expected terminal output:

```
✅ Wrote test-output.pdf (XXXX bytes)
```

Open `test-output.pdf` in a real PDF viewer and confirm, section by section:

1. **Top section** — bold, italic, and inline code (shown in a shaded monospace font) all render distinctly; the link text appears blue and underlined.
2. **Bulleted List section** — three top-level bullets (`•`), with the second item's two sub-items visibly indented further right and also bulleted — confirming nested-list recursion and indentation both work.
3. **Numbered List section** — items show `1.`, `2.`, `3.` instead of bullets, confirming the `ordered` flag is read correctly.
4. **Task List section** — a filled checkbox glyph (☑) next to "Completed task" and an empty one (☐) next to "Incomplete task."
5. **Code Block section** — the TypeScript function appears in a monospace font, light text on a dark shaded background box, with original line breaks and indentation preserved.
6. **Blockquote section** — the quoted text appears indented from the left margin, italicized, with a visible vertical line running along its left edge.

Once confirmed, clean up:

```bash
rm test-output.pdf
```

---

## ✅ Part 5B — Complete

`lib/converters/toPdf.tsx` now correctly handles: `heading` (×6 depths), `paragraph`, `text`, `strong`, `emphasis`, `inlineCode`, `link`, `list`/`listItem` (ordered, unordered, nested, and GFM task-list variants), `code`, and `blockquote` — verified visually in a real generated PDF.

Remaining from our Part 3A reference table: `image` and `table`. Both introduce genuinely new challenges — `image` requires fetching remote bytes before rendering, and `table` requires a grid layout with per-column alignment — which is exactly why Part 0's philosophy of "small, deliberate increments" holds here too.

---

No technical problem — that was another blank-send error on my part, not a generation issue. Here is **Part 5C, complete, in full.**

---

# Part 5C: Tables, Images, and Wiring `toPdf` into the Route Handler

## What This Installment Covers
The final two node types our PDF renderer needs — `table` and `image` — plus retiring the Part 4 stub entirely: replacing it with a real call to `toPdf()`, so clicking "Export as PDF" in the live app finally downloads a genuine, correctly formatted PDF.

---

## Step 7 — Rendering Tables

### The Target
Add `table`, `tableRow`, `tableCell` handling to `renderBlockNode`, producing a proper grid layout with borders and a shaded header row.

### The Concept

> **Analogy — A Grid of Labeled Boxes, Not a Spreadsheet Widget.** `@react-pdf/renderer` has no built-in `<Table>` component — recall from Step 2 that everything is built from just `<View>` and `<Text>`. A table, then, is simply **nested `<View>`s**: an outer `<View>` (the table), containing row `<View>`s (each with `flexDirection: "row"`), each containing cell `<View>`s with a fixed or flexible width. This is the same Flexbox mental model web developers already use for grid layouts — we're just building it from primitives instead of using a pre-made widget.

The one genuinely new piece of information we need from the AST is `table.align` — recall from Part 3A's reference table, this is an array like `["left", "center", null]`, one entry per column, telling us how to justify each column's text.

### The Implementation

**`lib/converters/toPdf.tsx`** — add these new styles to the existing `StyleSheet.create({...})` call (insert them alongside the other style keys, anywhere inside the object):

```tsx
  table: {
    marginBottom: 8,
    borderWidth: 1,
    borderColor: "#d1d5db",
  },
  tableRow: {
    flexDirection: "row",
  },
  tableHeaderRow: {
    backgroundColor: "#f3f4f6",
  },
  tableCell: {
    flex: 1,
    padding: 5,
    fontSize: 10,
    borderRightWidth: 1,
    borderBottomWidth: 1,
    borderColor: "#d1d5db",
  },
  tableCellHeader: {
    fontWeight: 700,
  },
```

Next, add this new import at the top of the file (extending the existing `import type { Root, RootContent, PhrasingContent, ListItem } from "mdast";` line):

```tsx
import type { Root, RootContent, PhrasingContent, ListItem, Table, AlignType } from "mdast";
```

Now add the table-rendering logic. Insert this new helper function anywhere above `renderBlockNode` (e.g., directly after `renderList`):

```tsx
/** Maps mdast's column alignment values to React-PDF's text-align values. */
function alignToTextAlign(align: AlignType): "left" | "center" | "right" {
  if (align === "center") return "center";
  if (align === "right") return "right";
  return "left"; // covers both "left" and null (no alignment specified)
}

/** Renders a full `table` node as a grid of nested <View>s. */
function renderTable(node: Table, key: number): React.ReactNode {
  const align = node.align ?? [];

  return (
    <View key={key} style={styles.table}>
      {node.children.map((row, rowIndex) => {
        const isHeaderRow = rowIndex === 0; // mdast's first tableRow is always the header
        return (
          <View
            key={rowIndex}
            style={[styles.tableRow, ...(isHeaderRow ? [styles.tableHeaderRow] : [])]}
          >
            {row.children.map((cell, cellIndex) => {
              const textAlign = alignToTextAlign(align[cellIndex] ?? null);
              return (
                <View key={cellIndex} style={styles.tableCell}>
                  <Text
                    style={[
                      { textAlign },
                      ...(isHeaderRow ? [styles.tableCellHeader] : []),
                    ]}
                  >
                    {cell.children.map((inline, i) => (
                      <Text key={i}>{renderInline(inline)}</Text>
                    ))}
                  </Text>
                </View>
              );
            })}
          </View>
        );
      })}
    </View>
  );
}
```

Finally, add a `case "table":` to `renderBlockNode`'s switch statement (insert it alongside the existing `case "blockquote":` block):

```tsx
    case "table":
      return renderTable(node, key);
```

A detail worth pausing on: **`style={[styles.tableRow, ...(isHeaderRow ? [styles.tableHeaderRow] : [])]}`** — React-PDF's `style` prop accepts either a single style object *or* an array of style objects, which get merged together in order (later entries override earlier ones for any overlapping properties). We use this array form to conditionally layer the header-row shading on top of the base row style, only when `isHeaderRow` is true — the same pattern we repeat for `tableCellHeader`.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

---

## Step 8 — Rendering Images

### The Target
Add `image` handling to `renderBlockNode`. Since `mdast`'s `image` node only gives us a URL (not actual image bytes), and images in Markdown can appear as remote URLs, we need to fetch those bytes ourselves before React-PDF can embed them.

### The Concept

> **Analogy — Ordering a Photo Print from a Web Link.** A Markdown `![alt](https://example.com/photo.png)` node is like a note that says "print this photo" with a web address on it — it is *not* the photo itself. Before we can put an actual image into our PDF, we must first **download** those bytes into memory, exactly like a photo print shop would need to first download the picture from that link before printing it. `@react-pdf/renderer`'s `<Image>` component conveniently accepts either a URL string directly (fetching it internally) or raw bytes — for remote URLs, we can actually let it fetch directly, but we'll fetch manually ourselves so we can **fail gracefully** with a clear fallback if the image is unreachable, rather than letting the whole PDF generation crash over one bad link.

Since fetching is asynchronous (it takes time and can fail), and our current `renderBlockNode`/`renderInline` functions are all synchronous, we need to introduce a small architectural change: **pre-fetch all images before rendering begins**, storing their bytes in a lookup map keyed by URL, so the actual synchronous render pass can just look up already-downloaded bytes instead of awaiting anything mid-render.

### The Implementation

**`lib/converters/toPdf.tsx`** — add this new style to the `StyleSheet.create({...})` object:

```tsx
  image: {
    maxWidth: "100%",
    marginBottom: 8,
  },
  imageFallback: {
    padding: 8,
    backgroundColor: "#fef2f2",
    borderWidth: 1,
    borderColor: "#fecaca",
    marginBottom: 8,
  },
  imageFallbackText: {
    fontSize: 9,
    color: "#b91c1c",
  },
```

Add `Image` to the top import:

```tsx
import { Document, Page, View, Text, Image, StyleSheet } from "@react-pdf/renderer";
```

Add a new import for walking the tree to collect image URLs — we'll write this small helper ourselves:

Now add this pre-fetching logic. Insert it near the top of the file, below the styles:

```tsx
/** Recursively collects every image URL present anywhere in the AST. */
function collectImageUrls(node: RootContent | Root, urls: Set<string>): void {
  if (node.type === "image") {
    urls.add(node.url);
  }
  if ("children" in node && Array.isArray(node.children)) {
    for (const child of node.children) {
      collectImageUrls(child as RootContent, urls);
    }
  }
}

/**
 * Downloads every image referenced in the AST ahead of time, returning a
 * map from URL to raw bytes (or `null` if that specific image failed to
 * download, so we can render a clear fallback instead of crashing).
 */
async function fetchImages(ast: Root): Promise<Map<string, Buffer | null>> {
  const urls = new Set<string>();
  collectImageUrls(ast, urls);

  const results = new Map<string, Buffer | null>();

  await Promise.all(
    Array.from(urls).map(async (url) => {
      try {
        const response = await fetch(url);
        if (!response.ok) {
          console.warn(`[toPdf] Image fetch failed (status ${response.status}): ${url}`);
          results.set(url, null);
          return;
        }
        const arrayBuffer = await response.arrayBuffer();
        results.set(url, Buffer.from(arrayBuffer));
      } catch (err) {
        console.warn(`[toPdf] Image fetch threw an error for ${url}:`, err);
        results.set(url, null);
      }
    })
  );

  return results;
}
```

Now update `renderBlockNode` to accept the pre-fetched image map as a parameter, and add the `image` case. Change its signature:

```tsx
function renderBlockNode(
  node: RootContent,
  key: number,
  images: Map<string, Buffer | null>
): React.ReactNode {
```

Add this case inside the switch statement (alongside `case "table":`):

```tsx
    case "image": {
      const bytes = images.get(node.url);

      if (!bytes) {
        // Graceful fallback: instead of a broken/missing image (or crashing
        // the entire PDF), we render a small, clearly labeled notice.
        return (
          <View key={key} style={styles.imageFallback}>
            <Text style={styles.imageFallbackText}>
              [Image could not be loaded: {node.alt || node.url}]
            </Text>
          </View>
        );
      }

      return (
        <Image key={key} src={bytes} style={styles.image} />
      );
    }
```

Since `renderBlockNode` now takes three arguments, every place it's called must be updated too. Update the two call sites — first, inside `renderListItem`'s nested-list handling, this line stays the same (it calls `renderList`, not `renderBlockNode`, so no change needed there). Second, update the final `toPdf` export, which is where the real change happens:

```tsx
export async function toPdf(ast: Root): Promise<React.ReactElement> {
  // Pre-fetch every image in the document BEFORE we begin the synchronous
  // render walk, so renderBlockNode never needs to `await` mid-recursion.
  const images = await fetchImages(ast);

  return (
    <Document>
      <Page size="A4" style={styles.page}>
        {ast.children.map((node, i) => renderBlockNode(node, i, images))}
      </Page>
    </Document>
  );
}
```

Notice **`toPdf` is now `async` and returns `Promise<React.ReactElement>`** instead of returning the element directly — this is a meaningful, deliberate signature change, and every caller of `toPdf` (our test script, and soon the Route Handler) must now `await` it.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

Update `scripts/test-pdf.tsx` to `await toPdf(...)` and add an image to the sample markdown:

```tsx
import { writeFileSync } from "fs";
import { renderToBuffer } from "@react-pdf/renderer";
import { parseMarkdown } from "../lib/parseMarkdown";
import { toPdf } from "../lib/converters/toPdf";

async function main() {
  const markdown = `# Hello GreyMatter

This is **bold text**, this is *italic text*, and this is \`inline code\`.

Here's a [link to somewhere](https://example.com).

## A Table

| Feature | Supported | Notes |
| :--- | :---: | ---: |
| Tables | Yes | Aligned per column |
| Images | Yes | Fetched remotely |

## An Image

![A placeholder image](https://placehold.co/300x150.png)

## A Broken Image (fallback test)

![This should fail gracefully](https://this-domain-does-not-exist-12345.example/photo.png)

## A Bulleted List

- First item
- Second item with **bold** inside
  - A nested sub-item
- Third top-level item

## A Code Block

\`\`\`typescript
function greet(name: string): string {
  return \`Hello, \${name}!\`;
}
\`\`\`

## A Blockquote

> This is a blockquote, indented and italicized with a left accent line.
`;

  const ast = parseMarkdown(markdown);

  // toPdf is now async (Step 8 introduced image pre-fetching), so we must
  // await it before passing its result to renderToBuffer.
  const pdfElement = await toPdf(ast);
  const buffer = await renderToBuffer(pdfElement);

  writeFileSync("test-output.pdf", buffer);
  console.log(`✅ Wrote test-output.pdf (${buffer.byteLength} bytes)`);
}

main().catch((err) => {
  console.error("❌ Failed to generate test PDF:", err);
  process.exit(1);
});
```

Run it:

```bash
npx tsx scripts/test-pdf.tsx
```

Expected terminal output includes both a success line and two warnings printed to the console (from our `console.warn` calls in `fetchImages`/`renderBlockNode`'s fallback path) — this is **expected and correct**, not a bug:

```
[toPdf] Image fetch threw an error for https://this-domain-does-not-exist-12345.example/photo.png: ...
✅ Wrote test-output.pdf (XXXX bytes)
```

Open `test-output.pdf` in a real PDF viewer and confirm:

1. **Table section** — a bordered grid with a shaded header row ("Feature / Supported / Notes"), the "Supported" column's text centered, and the "Notes" column's text right-aligned — confirming `table.align` is read correctly per column.
2. **Image section** — the placeholder image genuinely appears, embedded in the PDF (not just a link).
3. **Broken Image section** — instead of a crash or a blank gap, you should see a small, clearly labeled red-tinted box reading something like *"[Image could not be loaded: This should fail gracefully]"* — confirming our graceful-fallback path works exactly as designed.
4. Everything from 5A/5B (headings, lists, code blocks, blockquotes) still renders correctly, unaffected by these additions.

Clean up:

```bash
rm test-output.pdf
```

---

## Step 9 — Wiring `toPdf` into the Route Handler

### The Target
Update `app/api/convert/[format]/route.ts` from Part 4A: replace the stub-generation block with a real call to `toPdf()` when `format === "pdf"`. DOCX and PPTX continue returning stubs for now — they get their own real implementations in Parts 6 and 7.

### The Concept

> **Analogy — Finally Hiring the First Chef.** Recall Part 4A's restaurant analogy: we built the ticket window, validation, and delivery tray before any chef existed. Today, we hire our first chef — the PDF renderer — and plug them into the *exact same* ticket-to-tray pipeline that already existed. Nothing about the ordering process changes; only the specific dish now being genuinely cooked, instead of a placeholder.

### The Implementation

**`app/api/convert/[format]/route.ts`** (full file, replacing the previous version)

```typescript
import { NextRequest, NextResponse } from "next/server";
import { renderToBuffer } from "@react-pdf/renderer";
import { parseMarkdown } from "@/lib/parseMarkdown";
import { toPdf } from "@/lib/converters/toPdf";

export const runtime = "nodejs";

const SUPPORTED_FORMATS = ["pdf", "docx", "pptx"] as const;
type SupportedFormat = (typeof SUPPORTED_FORMATS)[number];

function isSupportedFormat(value: string): value is SupportedFormat {
  return (SUPPORTED_FORMATS as readonly string[]).includes(value);
}

const CONTENT_TYPES: Record<SupportedFormat, string> = {
  pdf: "application/pdf",
  docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  pptx: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
};

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ format: string }> }
) {
  const { format } = await params;

  if (!isSupportedFormat(format)) {
    return NextResponse.json(
      {
        error: `Unsupported export format: "${format}". Supported formats are: ${SUPPORTED_FORMATS.join(", ")}.`,
      },
      { status: 400 }
    );
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { error: "Request body must be valid JSON." },
      { status: 400 }
    );
  }

  if (
    typeof body !== "object" ||
    body === null ||
    !("markdown" in body) ||
    typeof (body as { markdown: unknown }).markdown !== "string"
  ) {
    return NextResponse.json(
      { error: "Request body must include a 'markdown' string field." },
      { status: 400 }
    );
  }

  const markdown = (body as { markdown: string }).markdown;

  if (markdown.trim().length === 0) {
    return NextResponse.json(
      { error: "Markdown content cannot be empty." },
      { status: 400 }
    );
  }

  const ast = parseMarkdown(markdown);

  let fileBuffer: Buffer;

  try {
    if (format === "pdf") {
      // THE REAL IMPLEMENTATION: parse → build the React-PDF element tree
      // (including pre-fetching any images) → render it to actual PDF
      // bytes. This replaces the Part 4 stub entirely for this format.
      const pdfElement = await toPdf(ast);
      fileBuffer = await renderToBuffer(pdfElement);
    } else {
      // DOCX and PPTX remain stubs until Parts 6 and 7 give them their own
      // real converter implementations, following this exact same pattern.
      const nodeCount = countNodes(ast);
      const stubContent =
        `This is a placeholder ${format.toUpperCase()} file.\n\n` +
        `Generated by GreyMatter MConvert (Part 5 checkpoint).\n` +
        `Parsed AST contained ${nodeCount} total nodes.\n\n` +
        `Real ${format.toUpperCase()} rendering arrives in a later part of the tutorial series.\n`;
      fileBuffer = Buffer.from(stubContent, "utf-8");
    }
  } catch (err) {
    // A rendering failure (e.g., an unexpected error deep inside
    // @react-pdf/renderer) is caught here so it becomes a clean 500 JSON
    // error response, rather than an opaque server crash.
    const message = err instanceof Error ? err.message : "Unknown rendering error.";
    console.error(`[convert/${format}] Rendering failed:`, err);
    return NextResponse.json(
      { error: `Failed to generate ${format.toUpperCase()} file: ${message}` },
      { status: 500 }
    );
  }

  const filename = `greymatter-export.${format}`;

  return new NextResponse(fileBuffer, {
    status: 200,
    headers: {
      "Content-Type": CONTENT_TYPES[format],
      "Content-Disposition": `attachment; filename="${filename}"`,
      "Content-Length": String(fileBuffer.byteLength),
    },
  });
}

function countNodes(node: { children?: unknown[] }): number {
  let count = 1;
  if (Array.isArray(node.children)) {
    for (const child of node.children) {
      count += countNodes(child as { children?: unknown[] });
    }
  }
  return count;
}
```

A detail worth pausing on: **the new `try/catch` wrapping the rendering step specifically** — this is distinct from, and in addition to, the earlier validation checks (bad format, malformed JSON, missing markdown). Those earlier checks guard against *bad input*; this new `try/catch` guards against *rendering failures on otherwise-valid input* (e.g., a genuinely corrupt image byte stream slipping past our fetch check, or an unexpected edge case inside the PDF library itself). Separating these concerns — input validation vs. processing failure — means our error messages stay precise and honest about what actually went wrong.

### The Verification

Restart the dev server:

```bash
npm run dev
```

**Terminal test first, via `curl`, exactly like Part 4A's verification style:**

```bash
curl -i -X POST http://localhost:3000/api/convert/pdf \
  -H "Content-Type: application/json" \
  -d '{"markdown": "# Real PDF Test\n\nThis is **bold** and this is *italic*.\n\n- Item one\n- Item two"}' \
  -o real-test.pdf
```

Expected: `HTTP/1.1 200 OK` with `Content-Type: application/pdf`. Open `real-test.pdf` in a real PDF viewer and confirm it shows a properly formatted heading, bold/italic text, and a bulleted list — no longer the plain-text stub from Part 4.

```bash
rm real-test.pdf
```

**Now test through the actual live app UI:**

Open **http://localhost:3000**. Load the **Report** template from the dropdown (it contains headings, a table, a blockquote, and a task list — a good comprehensive test). Click **Export as PDF**.

Confirm:
1. The button briefly shows "Exporting…" then a file downloads.
2. Opening the downloaded PDF shows the Q3 Engineering Report, fully formatted — metrics table with borders, a blockquote with the left accent line, a numbered highlights list, and an unchecked task list at the bottom.
3. Click **Export as DOCX** or **Export as PPTX** — confirm these still correctly download the *stub* text file, unaffected by today's changes, exactly as expected until Parts 6 and 7.

---

# Part 5D: Custom Fonts & Pagination

## What This Installment Covers
Two things the blueprint explicitly requires that we haven't covered yet: registering a custom font (so headings aren't stuck with the built-in Helvetica), and understanding/controlling how `@react-pdf/renderer` paginates long documents. This closes out Part 5 completely.

---

## Step 10 — Registering Custom Fonts

### The Target
Register a real, downloadable font family (Inter, a popular open-source typeface) and apply it across our PDF — regular weight for body text, bold weight for headings — replacing the default built-in Helvetica.

### The Concept

> **Analogy — Hiring a Specific Sign Painter Instead of Using the Building's Default Stencil Kit.** `@react-pdf/renderer` ships with a handful of built-in "standard" fonts (Helvetica, Times-Roman, Courier) that work with zero setup — that's what we've used so far. But these are generic, dated defaults available in effectively every PDF viewer, not fonts you'd choose for a polished, branded document. `Font.register()` lets us tell the library, "before you draw any text, first download and load *this specific* font file, and let me refer to it by a name I choose" — much like commissioning a specific sign painter with their own distinct lettering style, rather than using whatever stencil kit came with the building.

A crucial detail: **font registration must happen once, at module load time, before any PDF rendering occurs** — not inside a component or a function that runs per-request. This is because `Font.register()` is a *global* registration into React-PDF's internal font system; registering it repeatedly on every request would be wasteful, and registering it too late (after rendering has already started) can cause fonts to silently fail to apply.

### The Implementation

**`lib/converters/toPdf.tsx`** — add this near the very top of the file, immediately after the imports and before the `StyleSheet.create({...})` call:

```tsx
import { Document, Page, View, Text, Image, StyleSheet, Font } from "@react-pdf/renderer";
import type { Root, RootContent, PhrasingContent, ListItem, Table, AlignType } from "mdast";

// Font.register runs ONCE at module load time (this file is only ever
// imported, never re-executed per request within the same server process),
// registering a font FAMILY name ("Inter") with multiple weighted variants.
// We point at Google Fonts' raw, direct .ttf file URLs — @react-pdf/renderer
// fetches and embeds these bytes directly into the generated PDF, so the
// font displays correctly even on a machine that doesn't have Inter
// installed locally.
Font.register({
  family: "Inter",
  fonts: [
    {
      src: "https://cdn.jsdelivr.net/fontsource/fonts/inter@latest/latin-400-normal.ttf",
      fontWeight: 400,
    },
    {
      src: "https://cdn.jsdelivr.net/fontsource/fonts/inter@latest/latin-700-normal.ttf",
      fontWeight: 700,
    },
    {
      src: "https://cdn.jsdelivr.net/fontsource/fonts/inter@latest/latin-400-italic.ttf",
      fontWeight: 400,
      fontStyle: "italic",
    },
  ],
});
```

Now update the `styles.page` entry inside `StyleSheet.create({...})` to use this newly registered family instead of `"Helvetica"`:

```tsx
  page: {
    padding: 40,
    fontSize: 11,
    fontFamily: "Inter", // was "Helvetica" — now uses our registered font
    color: "#1a1a1a",
  },
```

Because we registered **both** a `fontWeight: 400` (regular) and `fontWeight: 700` (bold) variant under the same `"Inter"` family name, our existing `styles.bold = { fontWeight: 700 }` and every heading style (`fontWeight: 700`) automatically pick up the correct bold *file* — React-PDF matches the closest registered weight for the family currently in effect, so no other style changes are needed. Similarly, `styles.italic = { fontStyle: "italic" }` will now correctly resolve to the italic variant we registered, rather than a synthetically slanted regular font.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

Re-run our isolated test script from 5C (no changes needed to the script itself):

```bash
npx tsc --noEmit && npx tsx scripts/test-pdf.tsx
```

Open `test-output.pdf` in a real PDF viewer. Compare it against your memory of earlier tests — text should now visibly look like a modern sans-serif (Inter's distinct, slightly rounded letterforms), not the more dated-looking default Helvetica. Bold headings and italic blockquote text should both look like *genuine* bold/italic font files, not a mechanically slanted or thickened version of the regular weight (look closely at italic letters like "a" and "e" — a true italic font redraws these letterforms distinctly, while a "fake" slant just tilts the regular shape).

```bash
rm test-output.pdf
```

> **A note on production reliability:** fetching a font from a CDN over the network on every cold server start (or, in some deployment setups, on every request) introduces a dependency on that external CDN being available. For a production app, a more robust approach is to download the `.ttf` files once, commit them into a local `public/fonts/` folder, and point `Font.register`'s `src` at that local path instead. We flag this now, in the spirit of "production-grade code," and revisit deployment-specific concerns like this fully in Part 9.

---

## Step 11 — Understanding & Controlling Pagination

### The Target
No new node-rendering logic — instead, verifying and demonstrating `@react-pdf/renderer`'s automatic pagination behavior, and learning the one prop (`break`) that lets us force a new page deliberately.

### The Concept

> **Analogy — Pouring Water Between Glasses, Automatically Grabbing a New One When Full.** You never manually decide "this sentence goes on page 2" with `@react-pdf/renderer` — the library's Flexbox-based layout engine automatically measures content as it lays it out, and the moment a `<Page>` fills up, it starts a new page and continues pouring the remaining content into it, exactly like pouring water and automatically reaching for the next empty glass once the current one is full. This is why we've never had to think about page breaks at all so far — it simply works, by design, for ordinary flowing content.

Sometimes, though, you want **deliberate** control — for example, always starting a new page before a top-level heading, so major sections don't awkwardly begin three lines from the bottom of a page. React-PDF exposes this via a `break` prop on any element: `<Text break>` or `<View break>` forces that specific element to start on a fresh page, regardless of how much room was left on the previous one.

### The Implementation

Let's add this as an *optional* enhancement to our heading rendering — forcing depth-1 headings (`#`) specifically to always start a new page, since these typically represent major new sections in a document (a natural, sensible default; depth-2 and deeper headings continue flowing normally within a page).

**`lib/converters/toPdf.tsx`** — update the `"heading"` case inside `renderBlockNode`:

```tsx
    case "heading": {
      const style = HEADING_STYLES[node.depth - 1] ?? styles.heading6;
      return (
        <Text
          key={key}
          style={style}
          // Force top-level (depth 1) headings to always start a fresh
          // page — a common, sensible convention for major document
          // sections (chapters, major report headings, etc.). Deeper
          // headings (##, ###, ...) are left to flow naturally.
          break={node.depth === 1}
        >
          {node.children.map((child, i) => (
            <Text key={i}>{renderInline(child)}</Text>
          ))}
        </Text>
      );
    }
```

### The Verification

Update `scripts/test-pdf.tsx`'s markdown content to include enough text to force genuine multi-page output, plus a second depth-1 heading to test the forced break:

```tsx
  const markdown = `# First Section

This is the first section. ${"Repeated filler text to push content further down the page. ".repeat(20)}

## A Sub-heading (should NOT force a new page)

More content here. ${"More filler text to add length. ".repeat(20)}

# Second Section

This heading is depth 1, so it should always start on a fresh page, regardless of how much room was left on the previous page.
`;
```

Run:

```bash
npx tsx scripts/test-pdf.tsx
```

Open `test-output.pdf` and confirm:

1. **"First Section"** starts on page 1, and the repeated filler text naturally flows and — if it's long enough — automatically continues onto page 2 mid-paragraph,

Continuing exactly from there — finishing Step 11's verification and closing out Part 5 completely and properly this time.

---

## Step 11 — Understanding & Controlling Pagination *(verification, continued)*

Run:

```bash
npx tsx scripts/test-pdf.tsx
```

Open `test-output.pdf` and confirm:

1. **"First Section"** starts on page 1, and the repeated filler text naturally flows and — if it's long enough — automatically continues onto page 2 mid-paragraph, with no manual intervention from us. This confirms the "pouring water into the next glass" automatic pagination behavior from Step 11's concept explanation.
2. **"A Sub-heading"** (depth 2) appears wherever it naturally falls in the flow — it does **not** force a page break, even if it happens to land near the bottom of a page. This confirms our `break={node.depth === 1}` condition correctly only applies to depth-1 headings.
3. **"Second Section"** (depth 1) always begins at the very top of a fresh page, **regardless of how much room was left** on the page before it — even if there was plenty of empty space remaining. This is the concrete, visible proof that the `break` prop is working: without it, "Second Section" would have simply continued flowing wherever the previous content left off, similar to how "A Sub-heading" behaved.

As a final sanity check, temporarily remove `break={node.depth === 1}` (change it to `break={false}`), re-run the script, and regenerate the PDF. Confirm "Second Section" now flows naturally instead of forcing a new page — then restore `break={node.depth === 1}` back to its working state before moving on, since this is the behavior we want to keep.

Clean up:

```bash
rm test-output.pdf
```

---

## ✅ Part 5 — Complete

Let's do a full, honest accounting against every single bullet point in the original Part 5 blueprint, so nothing else is missed:

| Blueprint requirement | Where it was built |
|---|---|
| React-component-based PDF model (`Document`, `Page`, `View`, `Text`, `Image`, `StyleSheet`) | 5A, Step 2–3 |
| Recursive component mapping mdast → PDF primitives | 5A–5C |
| Headings → sized `Text` | 5A |
| Lists → indented `View`s with bullet glyphs | 5B |
| Code blocks → monospace `Text` in a shaded `View` | 5B |
| Tables → `View` grids | 5C, Step 7 |
| Images → `Image` with remote handling | 5C, Step 8 |
| Styling via `StyleSheet.create` | 5A, Step 3 (used throughout) |
| **Pagination** | **5D, Step 11** |
| **Fonts (registering custom fonts for headings)** | **5D, Step 10** |
| Hooked into Part 4 Route Handler, streaming the buffer | 5C, Step 9 |
| Real PDFs download with correct formatting | Verified live in 5C |

Every blueprint item for Part 5 is now genuinely, verifiably complete. `lib/converters/toPdf.tsx` is a full, production-shaped converter: it registers a real embedded font family with distinct weights, handles ten `mdast` node types (headings, paragraphs, text, strong, emphasis, inline code, links, lists/list items with nesting and task-list support, code blocks, blockquotes, tables, and images), fails gracefully on unsupported node types and broken images, and controls pagination deliberately for major section breaks — all wired live into the Route Handler and verified both via `curl` and the running app's UI.
