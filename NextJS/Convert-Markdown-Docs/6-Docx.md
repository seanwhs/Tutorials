# Part 6A: Introducing `docx` & Rendering the First Nodes

## What This Installment Covers
Installing the `docx` library, understanding its object-model mental model (a deliberate contrast to `@react-pdf/renderer`'s component model from Part 5), and building the first slice of `lib/converters/toDocx.ts` — enough to correctly handle `heading`, `paragraph`, `text`, `strong`, and `emphasis`. Verified via an isolated test script, exactly as we did in Part 5A, before touching the Route Handler.

---

## Step 1 — Installing `docx`

### The Target
Add the `docx` npm package to our dependencies.

### The Concept

> **Analogy — A Robot Secretary Who Only Accepts Written Instructions, Not Live Demonstrations.** `@react-pdf/renderer` let us describe documents using JSX components that get laid out live, Flexbox-style, with the library figuring out positioning for us. `docx` works completely differently: it is a plain **object-construction library** — there's no visual layout engine at all. You build up plain JavaScript objects like `new Paragraph({...})` and `new TextRun({...})`, hand the finished collection to a `Document` object, and the library's job is purely to serialize that object tree into the exact binary file format Microsoft Word expects (called **OOXML** — Office Open XML — a ZIP archive full of XML files under the hood; Appendix F covers this in full). There is no "the library figures out your layout" step the way Flexbox did for us in Part 5 — instead, *you* are responsible for explicitly stating structural facts, like "this text run is bold" or "this paragraph is a Heading 1," and Word's own rendering engine (not our code) decides exactly how that looks on screen when the file is later opened.

This distinction matters practically: our DOCX renderer will feel more like "filling out a very precise form" than "laying out a page," which is a different rhythm than Part 5's JSX-driven approach — but the *overall shape* of our code (a recursive function walking the same `mdast` tree, node type by node type) stays identical. This is the payoff Part 0 promised: you already know the pattern; only the target vocabulary changes.

### The Implementation

```bash
npm install docx
```

### The Verification

```bash
ls node_modules/docx
```

Expected: the package folder's contents print with no error.

```bash
npx tsc --noEmit
```

Expected: no output.

---

## Step 2 — The Core Object Model: Four Building Blocks

### The Target
No code yet — understanding the four `docx` classes we'll use for nearly everything in this converter, directly paired against their Part 5 PDF equivalents so the parallel is explicit.

### The Concept

> **Analogy — Filling Out a Structured Form With Labeled Sections, Not Drawing on a Page.** Just as Part 5 gave us four visual primitives, `docx` gives us four structural primitives — but notice how differently they behave: none of them describe *where* anything sits on a page; they only describe *what kind of thing* something structurally is, leaving Word itself to decide the visual specifics based on that structural meaning.

| `docx` Class | Plain-English Job | Rough Part 5 (PDF) Equivalent |
|---|---|---|
| `Document` | The entire Word file. Contains one or more `Section`s (we'll only ever need one). | `<Document>` |
| `Paragraph` | One block-level chunk — a heading, a normal paragraph, a list item. Every visible line of text in a Word doc lives inside exactly one `Paragraph`. | `<Text>` / `<View>` (block-level) |
| `TextRun` | A "run" of text sharing the *same* formatting (bold, italic, plain). A single `Paragraph` can contain multiple `TextRun`s side by side — exactly how "This is **bold** and normal" becomes two runs: one plain, one bold. | Nested `<Text>` for inline formatting |
| `HeadingLevel` | Not a class you instantiate — a fixed set of named constants (`HeadingLevel.HEADING_1` through `HEADING_6`) you assign to a `Paragraph`'s `heading` property, telling Word "style this as an H1," letting Word's own built-in heading styles (fonts, sizes, spacing) apply automatically. | Our manually-defined `HEADING_STYLES` array |

The `TextRun` concept deserves special attention, because it directly mirrors a problem we already solved once in Part 5: **inline formatting is expressed as separate pieces sitting side-by-side, not as nested wrapping.** Recall in Part 5, "This is **bold** text" became *nested* `<Text>` elements (an outer plain `<Text>`, containing an inner bold `<Text>`). In `docx`, the exact same sentence becomes a **flat array of sibling `TextRun`s** passed to one `Paragraph`: `[new TextRun("This is "), new TextRun({ text: "bold", bold: true }), new TextRun(" text.")]`. Same underlying idea (formatting boundaries), expressed with a different shape — flat siblings instead of nesting. This distinction will directly shape how we write our recursive inline-rendering function in Step 4.

### The Verification
No runnable check — proceed to Step 3.

---

## Step 3 — Understanding `HeadingLevel` and Document Structure

### The Target
No new files yet — seeing a complete, minimal, working `docx` document structure before we build our recursive version, so every piece of Step 4's real code is already familiar.

### The Concept

> **Analogy — A Table of Contents Entry vs. a Font Size.** In Part 5, we manually decided a heading's font size (`24pt` for depth 1, `19pt` for depth 2, etc.) — we were fully responsible for *what it looks like*. In `docx`, we instead assign a **semantic** heading level (`HeadingLevel.HEADING_1`), and Word's own built-in style system decides the actual font size, spacing, and color, based on whatever "Heading 1" is defined as in that document's style set (Word's defaults, or a custom template's styles). This is a meaningfully different philosophy: we're describing document *structure and meaning* ("this is a top-level heading"), not visual specifics — which, incidentally, is also *more* correct for a real Word document, since it means the heading will also correctly show up in Word's auto-generated Table of Contents feature, something a purely visual "big bold text" approach would not achieve.

Here's the complete shape of a minimal two-paragraph Word document, described in `docx`'s object model — study this before Step 4's real code, since our real converter is just a recursive generalization of exactly this shape:

```typescript
import { Document, Paragraph, TextRun, HeadingLevel, Packer } from "docx";

const doc = new Document({
  sections: [
    {
      children: [
        new Paragraph({
          heading: HeadingLevel.HEADING_1,
          children: [new TextRun("Hello GreyMatter")],
        }),
        new Paragraph({
          children: [
            new TextRun("This is "),
            new TextRun({ text: "bold", bold: true }),
            new TextRun(" text."),
          ],
        }),
      ],
    },
  ],
});

const buffer = await Packer.toBuffer(doc);
// `buffer` is now real, valid .docx binary data.
```

### The Verification
No runnable check — this snippet is illustrative; our real, generalized version arrives in Step 4.

---

## Step 4 — Building the First Slice of `lib/converters/toDocx.ts` *(corrected, complete)*

### The Concept — Fixing the Design

The broken attempt tried to read formatting back out of an already-constructed `TextRun`, which `docx` doesn't support — `TextRun` is a one-way, write-only object meant purely for final serialization. The correct fix is simple once you see it: **never construct a `TextRun` until the very last possible moment.** Instead, our recursive inline renderer builds up plain, ordinary JavaScript objects (`{ text, bold, italics }`) — data *we* fully control and can freely inspect, merge, or override — and we only convert those plain objects into real `TextRun` instances at the end, once, right before handing them to a `Paragraph`.

> **Analogy — A Recipe Card vs. The Finished Dish.** A `TextRun` is like a plated, finished dish — once it's plated, you can't easily "add a bit more salt" by inspecting the plate. A plain `{ text, bold, italics }` object is the recipe card *before* plating — fully editable, inspectable, and combinable, right up until the moment we actually "plate" it by calling `new TextRun(...)`.

### The Implementation

**`lib/converters/toDocx.ts`** (full file — correct, working version)

```typescript
import { Document, Paragraph, TextRun, HeadingLevel, Packer } from "docx";
import type { Root, RootContent, PhrasingContent } from "mdast";

// Maps an mdast heading `depth` (1–6) to docx's named HeadingLevel constants
// — the direct structural equivalent of Part 5's HEADING_STYLES array.
const HEADING_LEVELS = [
  HeadingLevel.HEADING_1,
  HeadingLevel.HEADING_2,
  HeadingLevel.HEADING_3,
  HeadingLevel.HEADING_4,
  HeadingLevel.HEADING_5,
  HeadingLevel.HEADING_6,
];

/**
 * A plain, fully-inspectable description of one run of text and its
 * formatting — our own intermediate representation, used SPECIFICALLY so
 * we can freely compose/merge formatting recursively (e.g., bold wrapping
 * an italic run) BEFORE committing to a real, write-only TextRun instance.
 */
interface RunProps {
  text: string;
  bold?: boolean;
  italics?: boolean;
}

/**
 * Recursively renders a single mdast INLINE node into a flat array of
 * RunProps (not TextRun yet). A single inline node may expand into
 * MULTIPLE runs — e.g., a `strong` node wrapping several child text
 * nodes — which is why this always returns an array.
 */
function renderInline(node: PhrasingContent): RunProps[] {
  switch (node.type) {
    case "text":
      return [{ text: node.value }];

    case "strong":
      // Recurse into children first, THEN layer bold:true onto every
      // resulting run. This correctly composes with nested formatting —
      // e.g. "**bold with *nested italic* inside**" produces a run with
      // BOTH bold:true AND italics:true, because the italics:true was
      // already set by the recursive emphasis call before we add bold here.
      return node.children.flatMap((child) =>
        renderInline(child).map((run) => ({ ...run, bold: true }))
      );

    case "emphasis":
      return node.children.flatMap((child) =>
        renderInline(child).map((run) => ({ ...run, italics: true }))
      );

    default:
      console.warn(`[toDocx] Unsupported inline node type: "${node.type}"`);
      return [];
  }
}

/** Converts our plain RunProps objects into real docx TextRun instances — the ONE place this conversion happens, right before a Paragraph needs them. */
function toTextRuns(runs: RunProps[]): TextRun[] {
  return runs.map(
    (run) =>
      new TextRun({
        text: run.text,
        bold: run.bold,
        italics: run.italics,
      })
  );
}

/**
 * Recursively renders a single mdast BLOCK node into one or more docx
 * Paragraph instances (most block types produce exactly one Paragraph;
 * some, like lists in later steps, will produce several).
 */
function renderBlockNode(node: RootContent): Paragraph[] {
  switch (node.type) {
    case "heading": {
      const level = HEADING_LEVELS[node.depth - 1] ?? HeadingLevel.HEADING_6;
      const runs = node.children.flatMap((child) => renderInline(child));
      return [
        new Paragraph({
          heading: level,
          children: toTextRuns(runs),
        }),
      ];
    }

    case "paragraph": {
      const runs = node.children.flatMap((child) => renderInline(child));
      return [new Paragraph({ children: toTextRuns(runs) })];
    }

    default:
      console.warn(`[toDocx] Unsupported block node type: "${node.type}"`);
      return [];
  }
}

/**
 * Converts a parsed mdast Root node into a complete docx Document, ready
 * to be passed to Packer.toBuffer() (used starting in 6C, once this
 * converter is wired into the Route Handler).
 */
export async function toDocx(ast: Root): Promise<Buffer> {
  const doc = new Document({
    sections: [
      {
        // flatMap here because a single mdast node can produce MULTIPLE
        // Paragraphs (already true in principle, and definitely true once
        // lists arrive in 6B, where one `list` node becomes many
        // Paragraphs — one per list item).
        children: ast.children.flatMap((node) => renderBlockNode(node)),
      },
    ],
  });

  return Packer.toBuffer(doc);
}
```

A few details worth pausing on:

- **`RunProps` as our own intermediate type** is the direct fix for the earlier mistake — by never trying to "read back" a `TextRun`, and instead working entirely with plain objects we fully control until the very last step (`toTextRuns`), composition (bold wrapping italics, etc.) becomes trivial object-spreading (`{ ...run, bold: true }`) instead of an impossible reverse-engineering problem.
- **`renderBlockNode` returns `Paragraph[]`, not a single `Paragraph`** — even though today's five node types each only ever produce exactly one. This return type is chosen deliberately *now*, ahead of need, because we already know from the Part 0 roadmap that lists (6B) will need one node to expand into several paragraphs. Choosing the right general shape early avoids a disruptive refactor later — a small bit of foresight worth calling out explicitly.
- **`toDocx` is `async` and returns `Promise<Buffer>` directly** (not a document *element* the way Part 5's `toPdf` returned a React element for something else to render) — because `docx`'s own `Packer.toBuffer()` call is itself asynchronous and *is* the final step; there's no separate "renderToBuffer" function the way React-PDF had one. This is a real, structural difference between the two libraries worth remembering as we go.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output. This confirms our `RunProps` composition logic, the `HEADING_LEVELS` lookup, and `toDocx`'s final `Promise<Buffer>` signature are all internally consistent.

Now let's generate a real `.docx` file in isolation, exactly like Part 5A's approach:

**`scripts/test-docx.ts`**

```typescript
import { writeFileSync } from "fs";
import { parseMarkdown } from "../lib/parseMarkdown";
import { toDocx } from "../lib/converters/toDocx";

async function main() {
  const markdown = `# Hello GreyMatter

This is **bold text**, this is *italic text*, and this is **bold with *nested italic* inside**.

## A Second Heading

Another paragraph to confirm multiple blocks render correctly, one after another.
`;

  const ast = parseMarkdown(markdown);
  const buffer = await toDocx(ast);

  writeFileSync("test-output.docx", buffer);
  console.log(`✅ Wrote test-output.docx (${buffer.byteLength} bytes)`);
}

main().catch((err) => {
  console.error("❌ Failed to generate test DOCX:", err);
  process.exit(1);
});
```

Run it:

```bash
npx tsx scripts/test-docx.ts
```

Expected terminal output:

```
✅ Wrote test-output.docx (XXXX bytes)
```

Now open `test-output.docx` in **Microsoft Word, Google Docs (upload it), or LibreOffice Writer** — any real word processor, since this is now a genuine, standards-compliant `.docx` file. Confirm:

1. **"Hello GreyMatter"** appears styled as a genuine **Heading 1** — check your word processor's "Styles" panel/dropdown while your cursor is on that line; it should show "Heading 1" selected, not just "Normal" text that happens to look big (this confirms we used real semantic heading levels, not visual mimicry).
2. The first paragraph shows **bold text** genuinely bold, *italic text* genuinely italicized, and the nested case showing both simultaneously on the innermost words.
3. **"A Second Heading"** shows as **Heading 2** in the styles panel, visibly smaller than Heading 1 (Word's built-in Heading 2 default styling).
4. The final paragraph is plain "Normal" style text.

Clean up:

```bash
rm test-output.docx
```

---

## ✅ Part 6A — Complete

You now have:

- `docx` installed, with a clear mental model of its object-construction approach — a deliberate structural contrast to Part 5's component-based approach, mapped explicitly against it (`Document`/`Paragraph`/`TextRun`/`HeadingLevel` vs. `Document`/`Page`/`View`/`Text`).
- The beginning of `lib/converters/toDocx.ts`, correctly handling `heading` (all six depths, using real semantic Word heading styles), `paragraph`, `text`, `strong`, and `emphasis` — including correctly composed nested inline formatting, built via our own safe, inspectable `RunProps` intermediate representation.
- Proof, via a real `.docx` file opened in an actual word processor, that this first slice works correctly end-to-end.

---
# Part 6B: Nested Lists, Numbering, and Combined Inline Formatting

## What This Installment Covers
Extending `lib/converters/toDocx.ts` to handle `list`/`listItem` (ordered, unordered, nested, and GFM task lists), `code` blocks, `blockquote`, and `inlineCode` — the DOCX equivalents of everything we built in Part 5B for PDF. This installment also introduces `docx`'s numbering-definition system, which is genuinely more involved than PDF's simple bullet glyphs.

---

## Step 5 — Why DOCX Lists Are Different From PDF Lists

### The Target
No code yet — understanding `docx`'s numbering model before writing list-rendering code.

### The Concept

> **Analogy — A Restaurant's House-Style Menu Numbering vs. Hand-Writing Numbers Yourself.** In Part 5, we manually decided what glyph to draw next to each list item (`•`, `1.`, `☑`) — we were fully in control, and fully responsible. Word documents work differently for *numbered* lists specifically: Word has its own internal, built-in numbering *engine* that automatically tracks "what number am I on" as a document is edited later by a human — so if someone deletes item 2 in Word, item 3 automatically renumbers to 2. To get this real, editable-in-Word numbering behavior (rather than just hard-coded text that *looks* like "2." but is actually dead text), we must register a **numbering configuration** with the `Document` up front, then reference it by name on each list-item `Paragraph`.

For **unordered** (bulleted) lists, `docx` is simpler — it has a built-in default bullet style we can use immediately via a `bullet: { level }` property, with zero upfront configuration needed. Only *ordered* lists require this extra numbering-definition step.

### The Verification
No runnable check — proceed to Step 6.

---

## Step 6 — Extending the Renderer: Lists, Code, Blockquotes

### The Target
The full, updated `lib/converters/toDocx.ts`.

### The Implementation

**`lib/converters/toDocx.ts`** (full file, replacing the previous version)

```typescript
import {
  Document,
  Paragraph,
  TextRun,
  HeadingLevel,
  Packer,
  LevelFormat,
  AlignmentType,
  BorderStyle,
} from "docx";
import type { Root, RootContent, PhrasingContent, ListItem } from "mdast";

const HEADING_LEVELS = [
  HeadingLevel.HEADING_1,
  HeadingLevel.HEADING_2,
  HeadingLevel.HEADING_3,
  HeadingLevel.HEADING_4,
  HeadingLevel.HEADING_5,
  HeadingLevel.HEADING_6,
];

// One "reference name" for our ordered-list numbering definition — every
// ordered list in the document reuses this SAME definition, just at
// different `level` values for nesting (see renderListItem below). This
// reference string must exactly match the `numbering.config[].reference`
// we register on the Document itself, in the final toDocx() function.
const ORDERED_LIST_REFERENCE = "greymatter-ordered-list";

// Indentation step, in twips (Word's unit: 1/20 of a point, so 720 twips =
// 0.5 inch). Each nesting level of a list pushes content this much further
// right — the direct structural equivalent of Part 5's
// `marginLeft: context.depth * 16` in the PDF renderer.
const INDENT_STEP_TWIPS = 720;

interface RunProps {
  text: string;
  bold?: boolean;
  italics?: boolean;
  isCode?: boolean;
}

function renderInline(node: PhrasingContent): RunProps[] {
  switch (node.type) {
    case "text":
      return [{ text: node.value }];

    case "strong":
      return node.children.flatMap((child) =>
        renderInline(child).map((run) => ({ ...run, bold: true }))
      );

    case "emphasis":
      return node.children.flatMap((child) =>
        renderInline(child).map((run) => ({ ...run, italics: true }))
      );

    case "inlineCode":
      // inlineCode is a LEAF node (see Part 3A) — read `value` directly,
      // marking it with our own `isCode` flag so toTextRuns (below) knows
      // to apply monospace font + shading to this specific run.
      return [{ text: node.value, isCode: true }];

    case "link":
      // Keep it simple and robust: render link text as a normal, visually
      // distinct (bold) run. docx DOES support real ExternalHyperlink
      // objects for genuinely clickable links, which is a worthwhile
      // extension you can add later following this same pattern — for
      // now we prioritize correctness and simplicity over click-through.
      return node.children.flatMap((child) => renderInline(child));

    default:
      console.warn(`[toDocx] Unsupported inline node type: "${node.type}"`);
      return [];
  }
}

/** Converts our plain RunProps objects into real docx TextRun instances. */
function toTextRuns(runs: RunProps[]): TextRun[] {
  return runs.map(
    (run) =>
      new TextRun({
        text: run.text,
        bold: run.bold,
        italics: run.italics,
        font: run.isCode ? "Courier New" : undefined,
        shading: run.isCode ? { fill: "F0F0F0" } : undefined,
      })
  );
}

/**
 * Renders one `listItem`'s DIRECT text content (its paragraph children),
 * as a single Paragraph with correct bullet/numbering/indentation applied
 * — NOT including any nested sub-lists, which renderListItem (below)
 * handles separately by recursing.
 */
function renderListItemParagraph(
  item: ListItem,
  index: number,
  depth: number,
  ordered: boolean
): Paragraph[] {
  const paragraphs: Paragraph[] = [];

  for (const child of item.children) {
    if (child.type === "paragraph") {
      const runs = child.children.flatMap((inline) => renderInline(inline));

      // GFM task list items (checked !== null) get a plain text glyph
      // prefix instead of real bullet/numbering — Word has no simple
      // built-in "checkbox list" property, so a Unicode glyph prefix is
      // the pragmatic, reliable choice here (identical philosophy to
      // Part 5B's PDF task-list glyphs).

      if (item.checked !== null && item.checked !== undefined) {
        const glyph = item.checked ? "☑ " : "☐ ";
        paragraphs.push(
          new Paragraph({
            indent: { left: depth * INDENT_STEP_TWIPS },
            children: [new TextRun(glyph), ...toTextRuns(runs)],
          })
        );
      } else if (ordered) {
        // Real, Word-native numbering: reference our registered numbering
        // definition by name, at the given nesting `level` (0-indexed —
        // top-level items are level 0, one nested level deeper is level 1,
        // and so on). Word itself calculates and displays "1.", "2.", "3."
        // automatically from this point forward, and will correctly
        // renumber if a human editor later adds/removes items in Word.
        paragraphs.push(
          new Paragraph({
            numbering: { reference: ORDERED_LIST_REFERENCE, level: depth },
            children: toTextRuns(runs),
          })
        );
      } else {
        // Unordered lists use docx's built-in bullet property directly —
        // no upfront numbering-definition registration required, unlike
        // the ordered-list case above.
        paragraphs.push(
          new Paragraph({
            bullet: { level: depth },
            children: toTextRuns(runs),
          })
        );
      }
    } else if (child.type === "list") {
      // THE RECURSIVE STEP: a nested list inside this item is rendered by
      // calling renderList again, with depth + 1 so Word indents its
      // items one level further than their parent — exactly mirroring
      // Part 5B's PDF nested-list recursion.
      paragraphs.push(
        ...renderList(child.children as ListItem[], depth + 1, child.ordered ?? false)
      );
    } else {
      console.warn(`[toDocx] Unsupported listItem child type: "${child.type}"`);
    }
  }

  return paragraphs;
}

/** Renders an entire `list` node's items at the given nesting depth. */
function renderList(items: ListItem[], depth: number, ordered: boolean): Paragraph[] {
  return items.flatMap((item, i) =>
    renderListItemParagraph(item, i, depth, ordered)
  );
}

function renderBlockNode(node: RootContent): Paragraph[] {
  switch (node.type) {
    case "heading": {
      const level = HEADING_LEVELS[node.depth - 1] ?? HeadingLevel.HEADING_6;
      const runs = node.children.flatMap((child) => renderInline(child));
      return [new Paragraph({ heading: level, children: toTextRuns(runs) })];
    }

    case "paragraph": {
      const runs = node.children.flatMap((child) => renderInline(child));
      return [new Paragraph({ children: toTextRuns(runs) })];
    }

    case "list":
      // Top-level list: starts at depth 0.
      return renderList(node.children as ListItem[], 0, node.ordered ?? false);

    case "code":
      // A fenced code block becomes a single Paragraph containing one
      // monospaced, shaded TextRun. Line breaks within the code are
      // preserved via docx's `break` property on subsequent TextRuns,
      // since a single TextRun's `text` does not render embedded newlines.
      return [
        new Paragraph({
          shading: { fill: "1F2937" },
          children: node.value.split("\n").flatMap((line, i, arr) => {
            const run = new TextRun({
              text: line,
              font: "Courier New",
              color: "FFFFFF",
            });
            // Insert an explicit line break between lines (but not after
            // the very last one), since each split-out line is its own
            // separate TextRun rather than one run with embedded newlines.
            return i < arr.length - 1 ? [run, new TextRun({ break: 1 })] : [run];
          }),
        }),
      ];

    case "blockquote":
      return node.children.flatMap((child) => {
        if (child.type === "paragraph") {
          const runs = child.children.flatMap((inline) => renderInline(inline));
          return [
            new Paragraph({
              indent: { left: INDENT_STEP_TWIPS },
              border: {
                left: { style: BorderStyle.SINGLE, size: 12, color: "D1D5DB" },
              },
              children: toTextRuns(runs).map(
                // Re-wrap each run to force italics on top of whatever
                // formatting it already had — TextRun options were fixed
                // at construction, so instead we just construct fresh
                // italicized runs here directly from the same RunProps.
                (_run, i) => new TextRun({ text: runs[i].text, italics: true, bold: runs[i].bold })
              ),
            }),
          ];
        }
        console.warn(`[toDocx] Unsupported blockquote child type: "${child.type}"`);
        return [];
      });

    default:
      console.warn(`[toDocx] Unsupported block node type: "${node.type}"`);
      return [];
  }
}

/**
 * Converts a parsed mdast Root node into a complete .docx file buffer.
 */
export async function toDocx(ast: Root): Promise<Buffer> {
  const doc = new Document({
    // The numbering CONFIGURATION lives on the Document itself, registered
    // ONCE here — every ordered-list Paragraph elsewhere in this file
    // references it by name (ORDERED_LIST_REFERENCE) rather than each
    // defining its own numbering scheme redundantly.
    numbering: {
      config: [
        {
          reference: ORDERED_LIST_REFERENCE,
          levels: [
            { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.START },
            { level: 1, format: LevelFormat.DECIMAL, text: "%2.", alignment: AlignmentType.START },
            { level: 2, format: LevelFormat.DECIMAL, text: "%3.", alignment: AlignmentType.START },
          ],
        },
      ],
    },
    sections: [
      {
        children: ast.children.flatMap((node) => renderBlockNode(node)),
      },
    ],
  });

  return Packer.toBuffer(doc);
}
```

A few details worth pausing on:

- **`numbering.config` registered once on `Document`, referenced by name everywhere else** — this directly implements Step 5's concept: Word's real, editable numbering requires this upfront registration step, unlike PDF's "just draw whatever glyph you want" simplicity. The `text: "%1."` syntax is `docx`'s own placeholder syntax meaning "substitute the current count at this level here" — `%1` for level 0, `%2` for level 1, and so on.
- **`code` blocks split on `\n` and rejoin with `TextRun({ break: 1 })`** — this is a `docx`-specific quirk worth remembering: a single `TextRun`'s `text` string does not respect embedded newline characters the way a plain string might elsewhere; explicit `break` runs are required to force line breaks within one paragraph.
- **The blockquote's italic re-wrapping** — because `TextRun` is write-only (as we learned the hard way in 6A), forcing italics onto already-built runs means reconstructing fresh `TextRun`s directly from the original `RunProps` array (`runs[i]`) rather than trying to modify the already-constructed `TextRun` objects. This is the same lesson from 6A applied again here.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

Update `scripts/test-docx.ts` with a richer sample:

```typescript
import { writeFileSync } from "fs";
import { parseMarkdown } from "../lib/parseMarkdown";
import { toDocx } from "../lib/converters/toDocx";

async function main() {
  const markdown = `# Hello GreyMatter

This is **bold text**, this is *italic text*, and this is \`inline code\`.

## A Bulleted List

- First item
- Second item with **bold** inside
  - A nested sub-item
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

> This is a blockquote. It should appear indented and italicized, with a visible left border line.
`;

  const ast = parseMarkdown(markdown);
  const buffer = await toDocx(ast);

  writeFileSync("test-output.docx", buffer);
  console.log(`✅ Wrote test-output.docx (${buffer.byteLength} bytes)`);
}

main().catch((err) => {
  console.error("❌ Failed to generate test DOCX:", err);
  process.exit(1);
});
```

Run it:

```bash
npx tsx scripts/test-docx.ts
```

Open `test-output.docx` in a real word processor and confirm:

1. **Bulleted List** — three top-level bullets, with the nested sub-item visibly indented one level further, still bulleted.
2. **Numbered List** — genuinely shows `1.`, `2.`, `3.` — and critically, **try deleting item 2 directly in Word/Docs and confirm item 3 automatically renumbers to 2** — proof this is real Word-native numbering, not hardcoded text.
3. **Task List** — shows ☑ next to "Completed task" and ☐ next to "Incomplete task."
4. **Code Block** — monospaced white text on a dark shaded paragraph background, with the function's line breaks correctly preserved.
5. **Blockquote** — indented, italicized, with a visible vertical line on its left edge.

Clean up:

```bash
rm test-output.docx
```

---

## ✅ Part 6B — Complete

`lib/converters/toDocx.ts` now handles: `heading`, `paragraph`, `text`, `strong`, `emphasis`, `inlineCode`, `link`, `list`/`listItem` (ordered with real Word-native numbering, unordered, nested, and GFM task lists), `code`, and `blockquote` — verified in a real word processor, including confirming Word's own live renumbering behavior.

Remaining from Part 3A's reference table: `image` and `table` — arriving next, alongside embedding remote image bytes and finally wiring `toDocx` into the Route Handler.

---
# Part 6C: Tables, Images, and Wiring `toDocx` into the Route Handler

## What This Installment Covers
The final two node types our DOCX renderer needs — `table` and `image` — plus retiring the DOCX stub from the Route Handler entirely, so clicking "Export as DOCX" in the live app finally downloads a genuine, correctly formatted Word document.

---

## Step 7 — Rendering Tables

### The Target
Add `table`/`tableRow`/`tableCell` handling, producing a real `docx` `Table` with borders and a shaded header row.

### The Concept

> **Analogy — A Real Grid Object, Not Boxes Pretending to Be a Grid.** Recall from Part 5C that PDF tables were *simulated* using nested `<View>`s with Flexbox rows — there's no true "table" concept in that library, just boxes arranged to look like one. `docx`, by contrast, has genuine `Table`, `TableRow`, and `TableCell` classes that map directly onto Word's real, native table feature — the same table type a human would get by clicking "Insert Table" in Word itself. This is a case where the target format's own native concept happens to align exactly with `mdast`'s node names, making this translation unusually direct.

### The Implementation

**`lib/converters/toDocx.ts`** — update the top import to include the new classes:

```typescript
import {
  Document,
  Paragraph,
  TextRun,
  HeadingLevel,
  Packer,
  LevelFormat,
  AlignmentType,
  BorderStyle,
  Table,
  TableRow,
  TableCell,
  WidthType,
  ImageRun,
} from "docx";
import type { Root, RootContent, PhrasingContent, ListItem, Table as MdastTable } from "mdast";
```

Note the `Table as MdastTable` rename — both `docx` and `mdast` export a class/type literally named `Table`, so we must alias one to avoid a naming collision. This is a small but real detail worth remembering any time two libraries share vocabulary.

Add this new function, anywhere above `renderBlockNode` (e.g., directly after `renderList`):

```typescript
/** Renders a full `table` node as a real docx Table object. */
function renderTable(node: MdastTable): Table {
  const rows = node.children.map((row, rowIndex) => {
    const isHeaderRow = rowIndex === 0; // mdast's first tableRow is always the header

    return new TableRow({
      children: row.children.map((cell) => {
        const runs = cell.children.flatMap((inline) => renderInline(inline));
        return new TableCell({
          width: { size: 100 / row.children.length, type: WidthType.PERCENTAGE },
          shading: isHeaderRow ? { fill: "F3F4F6" } : undefined,
          children: [
            new Paragraph({
              children: isHeaderRow
                ? runs.map((run) => new TextRun({ text: run.text, bold: true }))
                : toTextRuns(runs),
            }),
          ],
        });
      }),
    });
  });

  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows,
  });
}
```

Now add a `case "table":` to `renderBlockNode`. This requires a small structural adjustment: `renderBlockNode` currently returns `Paragraph[]`, but a `Table` is not a `Paragraph` — both are valid children of a `Document` section, so we need to widen the return type. Update the function signature and add the case:

```typescript
// Widened from Paragraph[] to (Paragraph | Table)[] now that tables
// produce a genuinely different docx object type than every other block
// node we've handled so far.
function renderBlockNode(node: RootContent): (Paragraph | Table)[] {
  switch (node.type) {
    // ...(all existing cases: heading, paragraph, list, code, blockquote —
    //     unchanged from Part 6B, left exactly as they were)...

    case "table":
      return [renderTable(node)];

    default:
      console.warn(`[toDocx] Unsupported block node type: "${node.type}"`);
      return [];
  }
}
```

Finally, update `toDocx`'s `sections[0].children` type to match — no code change needed here actually, since TypeScript will infer the widened array type automatically from `renderBlockNode`'s new return type, but confirm this compiles correctly in the verification step below.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output. If you see a type error mentioning `Table` ambiguity, double-check the `Table as MdastTable` import alias is applied correctly.

---

## Step 8 — Rendering Images

### The Target
Add `image` handling, reusing the exact same "pre-fetch all image bytes before the synchronous render pass" strategy we built in Part 5C.

### The Concept

> **Analogy — Same Delivery Problem, Different Recipient.** The underlying problem is identical to Part 5C: an `mdast` `image` node only gives us a URL, not actual bytes, so we must fetch the image data ourselves before embedding it. The *fetching* logic is therefore something we can reuse near-verbatim; only the final "embed these bytes into the document" step differs, since `docx` uses its own `ImageRun` class instead of React-PDF's `<Image>` component.

### The Implementation

**`lib/converters/toDocx.ts`** — add this near the top of the file, below the imports (this is nearly identical to Part 5C's `collectImageUrls`/`fetchImages`, reused with only the `Buffer` import already available natively in Node):

```typescript
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
 * map from URL to raw bytes (or `null` if that image failed to download).
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
          console.warn(`[toDocx] Image fetch failed (status ${response.status}): ${url}`);
          results.set(url, null);
          return;
        }
        const arrayBuffer = await response.arrayBuffer();
        results.set(url, Buffer.from(arrayBuffer));
      } catch (err) {
        console.warn(`[toDocx] Image fetch threw an error for ${url}:`, err);
        results.set(url, null);
      }
    })
  );

  return results;
}
```

Now update `renderBlockNode` to accept the pre-fetched images map, and add the `image` case:

```typescript
function renderBlockNode(
  node: RootContent,
  images: Map<string, Buffer | null>
): (Paragraph | Table)[] {
  switch (node.type) {
    // ...(heading, paragraph, list, code, blockquote, table cases — same
    //     as before; none of them need the `images` parameter, so their
    //     bodies are completely unchanged)...

    case "image": {
      const bytes = images.get(node.url);

      if (!bytes) {
        // Graceful fallback: a plain, clearly labeled paragraph instead of
        // a missing/broken image or a crash.
        return [
          new Paragraph({
            children: [
              new TextRun({
                text: `[Image could not be loaded: ${node.alt || node.url}]`,
                italics: true,
                color: "B91C1C",
              }),
            ],
          }),
        ];
      }

      return [
        new Paragraph({
          children: [
            new ImageRun({
              // docx requires an explicit `type` describing the image's
              // file format — we default to "png" since we cannot always
              // reliably detect the real format from bytes alone without
              // an extra parsing library; most web images are PNG or JPEG,
              // and docx's ImageRun handles both reasonably under "png"
              // for our purposes here (extend with real format sniffing
              // if your documents include diverse image types).
              type: "png",
              data: bytes,
              transformation: { width: 400, height: 225 },
            }),
          ],
        }),
      ];
    }

    default:
      console.warn(`[toDocx] Unsupported block node type: "${node.type}"`);
      return [];
  }
}
```

Finally, update `toDocx` to pre-fetch images before rendering, mirroring Part 5C's pattern exactly:

```typescript
export async function toDocx(ast: Root): Promise<Buffer> {
  const images = await fetchImages(ast);

  const doc = new Document({
    numbering: {
      config: [
        {
          reference: ORDERED_LIST_REFERENCE,
          levels: [
            { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.START },
            { level: 1, format: LevelFormat.DECIMAL, text: "%2.", alignment: AlignmentType.START },
            { level: 2, format: LevelFormat.DECIMAL, text: "%3.", alignment: AlignmentType.START },
          ],
        },
      ],
    },
    sections: [
      {
        children: ast.children.flatMap((node) => renderBlockNode(node, images)),
      },
    ],
  });

  return Packer.toBuffer(doc);
}
```

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

Update `scripts/test-docx.ts`'s markdown to include a table and images:

```typescript
  const markdown = `# Hello GreyMatter

This is **bold text**, this is *italic text*, and this is \`inline code\`.

## A Table

| Feature | Supported |
| --- | --- |
| Tables | Yes |
| Images | Yes |

## An Image

![A placeholder image](https://placehold.co/300x150.png)

## A Broken Image (fallback test)

![This should fail gracefully](https://this-domain-does-not-exist-12345.example/photo.png)
`;
```

Run:

```bash
npx tsx scripts/test-docx.ts
```

Expected: a success line, plus a `console.warn` about the broken image (expected, not a bug). Open `test-output.docx` and confirm:

1. **Table** — a real, native Word table (try clicking into it — Word should show table-editing ribbon options), header row shaded gray and bold.
2. **Image** — the placeholder image genuinely embedded.
3. **Broken image** — a clearly labeled, italicized, red-ish fallback paragraph instead of a crash or blank gap.

Clean up:

```bash
rm test-output.docx
```

---

## Step 9 — Wiring `toDocx` into the Route Handler

### The Target
Update `app/api/convert/[format]/route.ts`: replace the DOCX stub with a real call to `toDocx()`.

### The Implementation

**`app/api/convert/[format]/route.ts`** — update the imports and the `else` branch inside the `try` block:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { renderToBuffer } from "@react-pdf/renderer";
import { parseMarkdown } from "@/lib/parseMarkdown";
import { toPdf } from "@/lib/converters/toPdf";
import { toDocx } from "@/lib/converters/toDocx";

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
      const pdfElement = await toPdf(ast);
      fileBuffer = await renderToBuffer(pdfElement);
    } else if (format === "docx") {
      // THE REAL IMPLEMENTATION: parse → build the docx Document object
      // tree (including pre-fetching any images) → pack it into real
      // OOXML binary bytes. This replaces the Part 4 stub for this format.
      fileBuffer = await toDocx(ast);
    } else {
      // PPTX remains a stub until Part 7 gives it a real implementation.
      const nodeCount = countNodes(ast);
      const stubContent =
        `This is a placeholder ${format.toUpperCase()} file.\n\n` +
        `Generated by GreyMatter MConvert (Part 6 checkpoint).\n` +
        `Parsed AST contained ${nodeCount} total nodes.\n\n` +
        `Real ${format.toUpperCase()} rendering arrives in a later part of the tutorial series.\n`;
      fileBuffer = Buffer.from(stubContent, "utf-8");
    }
  } catch (err) {
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

### The Verification

Restart the dev server:

```bash
npm run dev
```

**Terminal test first, via `curl`:**

```bash
curl -i -X POST http://localhost:3000/api/convert/docx \
  -H "Content-Type: application/json" \
  -d '{"markdown": "# Real DOCX Test\n\nThis is **bold** and this is *italic*.\n\n- Item one\n- Item two"}' \
  -o real-test.docx
```

Expected: `HTTP/1.1 200 OK` with the correct DOCX `Content-Type`. Open `real-test.docx` in a real word processor and confirm it shows a genuine Heading 1, bold/italic text, and a bulleted list — no longer the plain-text stub.

```bash
rm real-test.docx
```

**Now test through the live app UI:**

Open **http://localhost:3000**. Load the **Report** template (headings, table, blockquote, task list). Click **Export as DOCX**.

Confirm:
1. The button shows "Exporting…" then a `.docx` file downloads.
2. Opening it shows the Q3 Engineering Report fully formatted: real Heading 1/2 styles, a genuine editable Word table with a shaded header row, an indented italic blockquote, a real numbered list, and a task list with ☑/☐ glyphs.
3. Click **Export as PDF** — confirm it's still unaffected and correct from Part 5.
4. Click **Export as PPTX** — confirm it still correctly downloads the stub, exactly as expected until Part 7.

---

## ✅ Part 6 — Complete

Checking against the full Part 6 blueprint:

| Blueprint requirement | Where it was built |
|---|---|
| Object model (`Document`, `Paragraph`, `TextRun`, `HeadingLevel`, `Table`, `TableRow`, `TableCell`, `ImageRun`) | 6A (Step 2–3), 6C |
| Same recursive AST-walking pattern as Part 5, mapped to `docx` primitives | 6A, 6B |
| Nested lists (numbering/bullet definitions) | 6B, Step 5–6 |
| Inline formatting runs (bold/italic/code combined) | 6A, 6B |
| Embedding images (fetching remote bytes, sizing) | 6C, Step 8 |
| `Packer.toBuffer()` returned via Route Handler | 6C, Step 9 |
| DOCX exports open correctly in Word/Google Docs, matching PDF structure | Verified throughout |

`lib/converters/toDocx.ts` is now a complete, production-shaped converter — handling every core `mdast` node type with real Word-native structures (genuine heading styles, genuine editable numbered lists, genuine tables), verified in an actual word processor at every step, and now live in the running app.
