# Part 7A: The Slide-Splitting Strategy & Sectionizing the AST

## What This Installment Covers
Installing `pptxgenjs`, understanding the fundamental conceptual shift this format requires (documents *flow*, slide decks *chunk*), and building the "sectionize AST by heading" pre-pass — a function that transforms our flat, flowing `mdast` tree into a list of discrete slide-sized sections, before we generate a single slide.

---

## Step 1 — Installing `pptxgenjs`

### The Target
Add `pptxgenjs` to our dependencies.

### The Concept

> **Analogy — A Photo Album vs. A Scroll.** Every renderer we've built so far (PDF, DOCX) treats a document as one continuous, flowing scroll — content just keeps pouring downward, and pagination happens automatically wherever it happens to land (recall Part 5D's "pouring water into the next glass" analogy). A slide deck is fundamentally *not* a scroll — it's a **photo album**: a fixed sequence of discrete, self-contained frames, each with its own boundaries, and content does not "flow" from one frame into the next the way it flows from one PDF page to the next. `pptxgenjs` gives us the tools to build individual slides (`addSlide()`, `addText()`, `addImage()`, `addTable()`), but it has **no built-in concept of "where should a new slide start"** — that decision is entirely ours to make, which is the genuinely new problem this part solves.

### The Implementation

```bash
npm install pptxgenjs
```

### The Verification

```bash
ls node_modules/pptxgenjs
```

Expected: the package folder's contents print with no error.

```bash
npx tsc --noEmit
```

Expected: no output.

---

## Step 2 — The Slide-Splitting Problem, Concretely

### The Target
No code yet — working through, on paper, exactly *what rule* decides where one slide ends and the next begins.

### The Concept

> **Analogy — Chaptering a Book Into Separate Postcards.** Imagine you're given a book manuscript and asked to rewrite it as a stack of postcards, one idea per card, using the book's own chapter headings as your natural dividing lines. You wouldn't split a postcard mid-sentence — you'd look for the book's *own* structural markers (chapter breaks) and use those as your cut points. We do exactly this with Markdown: **every `##` (depth-2) heading starts a brand new slide.** Everything between one `##` heading and the next — paragraphs, lists, code blocks, images, tables — becomes the *content* of that one slide.

We deliberately choose **depth-2** (`##`) as our slide-boundary marker, not depth-1 (`#`), for a specific, considered reason: we reserve a single depth-1 heading (if present) as the **document title**, generating one dedicated title slide from it — mirroring how a real presentation typically opens with one title slide, followed by many content slides, each introduced by its own `##` section heading. This is a deliberate design decision that directly reuses our "Slide Deck Outline" template from Part 2C, which was written with exactly this structure in mind.

Let's trace through a concrete example before writing any code:

```markdown
# Product Launch Overview

Welcome slide — presented by the Product team.

## The Problem

- Users juggle three tools
- Costs 5 hours/week

## Our Solution

- One unified workspace
```

This should sectionize into **three slides**:

| Slide | Title | Content |
|---|---|---|
| 1 (Title slide) | "Product Launch Overview" | "Welcome slide — presented by the Product team." |
| 2 | "The Problem" | The two-item bulleted list |
| 3 | "Our Solution" | The one-item bulleted list |

Notice something important: the paragraph "Welcome slide — presented by the Product team" appears **before** the first `##` heading in the source text, but it doesn't get lost — it becomes the *content* of the title slide itself, since it comes after the `#` (depth-1) title heading and before the first `##` boundary.

### The Verification
No runnable check yet — proceed to Step 3, where we encode exactly this logic.

---

## Step 3 — Building the Sectionizer

### The Target
`lib/converters/sectionizeMarkdown.ts` — a standalone function, `sectionizeAst(ast)`, that walks a flat `mdast` tree and groups its children into an array of `Section` objects, following the rule from Step 2. Kept as its own file, separate from `toPptx.ts` itself, since "deciding where slides break" and "drawing a slide's contents" are two genuinely separate concerns — the same single-responsibility instinct we applied back in Part 3A when we pulled parsing into its own file.

### The Implementation

**`lib/converters/sectionizeMarkdown.ts`**

```typescript
import type { Root, RootContent, Heading } from "mdast";

/**
 * One slide's worth of source material: an optional title (from the
 * heading that started this section, if any) and the block-level nodes
 * that belong to it — everything between this heading and the next
 * depth-2-or-shallower heading.
 */
export interface Section {
  /** The heading node that introduced this section, or null for content
   *  that appeared before ANY heading in the document (rare, but possible
   *  if a user's Markdown starts directly with a paragraph). */
  heading: Heading | null;
  /** Every non-heading block node belonging to this section, in order. */
  content: RootContent[];
  /** True only for the very first section, when it was introduced by a
   *  depth-1 (#) heading — used by toPptx.ts to render it as a distinct,
   *  visually different TITLE slide rather than an ordinary content slide. */
  isTitleSection: boolean;
}

/**
 * Splits a flat mdast Root's children into an array of slide-sized
 * Sections, using depth-2 (##) headings as the primary boundary, with a
 * special case for a single leading depth-1 (#) heading acting as the
 * overall document title.
 */
export function sectionizeAst(ast: Root): Section[] {
  const sections: Section[] = [];

  // `current` tracks the section we're actively building as we walk
  // through the document's top-level children in order. We start with an
  // "untitled" section to safely capture any content that appears before
  // the very first heading of any kind.
  let current: Section = { heading: null, content: [], isTitleSection: false };

  for (const node of ast.children) {
    if (node.type === "heading" && node.depth <= 2) {
      // We've hit a new section boundary (a depth-1 OR depth-2 heading).
      // Push whatever we were building so far — UNLESS it's our very
      // first, still-empty placeholder section with no heading and no
      // content yet, which we simply discard rather than emitting an
      // empty, pointless slide.
      if (current.heading !== null || current.content.length > 0) {
        sections.push(current);
      }

      current = {
        heading: node,
        content: [],
        // A depth-1 heading ONLY counts as the title section if it's the
        // very first section we've encountered in the whole document —
        // guarding against a document that (unusually) uses multiple
        // depth-1 headings throughout, which should NOT each become a
        // special title slide.
        isTitleSection: node.depth === 1 && sections.length === 0,
      };
    } else if (node.type === "heading" && node.depth > 2) {
      // Depth-3+ headings do NOT start a new slide — per our Step 2 rule,
      // only depth-1/2 headings are slide boundaries. A depth-3 heading
      // becomes ordinary CONTENT within the current section (toPptx.ts
      // will render it as a bolded sub-heading text line within the slide).
      current.content.push(node);
    } else {
      // Any other block node (paragraph, list, code, table, image,
      // blockquote) is just content belonging to the current section.
      current.content.push(node);
    }
  }

  // Don't forget the final section being built when the loop ends.
  if (current.heading !== null || current.content.length > 0) {
    sections.push(current);
  }

  return sections;
}
```

A few details worth pausing on:

- **Why `depth <= 2` rather than checking `depth === 2` specifically** — this single condition elegantly handles *both* our slide-boundary rules at once: a depth-1 heading only ever appears as the very first section's title (guarded by `sections.length === 0`), and every depth-2 heading after that starts an ordinary new slide. Combining both cases into one condition, rather than writing separate `if` blocks for depth 1 and depth 2, keeps the loop's control flow easy to follow in one pass.
- **The "discard an empty placeholder section" guard** (`if (current.heading !== null || current.content.length > 0)`) matters for a subtle edge case: if a document's very first line is immediately a `##` heading (no leading content at all), our initial `current` placeholder would otherwise get pushed as a pointless, totally empty slide before the real first section. This guard prevents that.
- **Depth-3+ headings intentionally become content, not new slides** — this is the direct code implementation of the "chaptering a book into postcards" analogy from Step 2: we only cut new postcards at the *chapter* level (`##`), while sub-headings within a chapter (`###`) stay together on the same postcard as regular emphasized text.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

Let's verify this function's actual output directly, using a small standalone script — we're not generating any slides yet, just confirming the *sectionizing decision* is correct in isolation, before building any rendering logic on top of it.

**`scripts/test-sectionize.ts`**

```typescript
import { parseMarkdown } from "../lib/parseMarkdown";
import { sectionizeAst } from "../lib/converters/sectionizeMarkdown";

const markdown = `# Product Launch Overview

Welcome slide — presented by the Product team.

## The Problem

- Users juggle three tools
- Costs 5 hours/week

## Our Solution

- One unified workspace

### A sub-point (should NOT become its own slide)

More detail on the solution.
`;

const ast = parseMarkdown(markdown);
const sections = sectionizeAst(ast);

console.log(`\nFound ${sections.length} sections:\n`);

sections.forEach((section, i) => {
  const title = section.heading
    ? section.heading.children.map((c) => ("value" in c ? c.value : "")).join("")
    : "(no heading)";
  console.log(
    `Section ${i + 1}: title="${title}", isTitleSection=${section.isTitleSection}, contentNodeCount=${section.content.length}`
  );
});
```

Run it:

```bash
npx tsx scripts/test-sectionize.ts
```

Expected terminal output:

```
Found 3 sections:

Section 1: title="Product Launch Overview", isTitleSection=true, contentNodeCount=1
Section 2: title="The Problem", isTitleSection=false, contentNodeCount=1
Section 3: title="Our Solution", isTitleSection=false, contentNodeCount=3
```

Let's verify each line matches our Step 2 rules exactly:

1. **Section 1** — `"Product Launch Overview"`, `isTitleSection=true` — confirms the depth-1 heading was correctly recognized as the document's title section (since it's the very first section encountered), and `contentNodeCount=1` correctly captures the single "Welcome slide..." paragraph that followed it, before the first `##`.
2. **Section 2** — `"The Problem"`, `isTitleSection=false`, `contentNodeCount=1` — a single content node here is the `list` node containing both bullet items (recall from Part 3A: a whole bulleted list is *one* `list` node in the tree, holding multiple `listItem` children inside it — not two separate top-level nodes).
3. **Section 3** — `"Our Solution"`, `isTitleSection=false`, `contentNodeCount=3` — this is the interesting one to check closely: it should contain **three** content nodes, not one. Count them: the `list` node (the "One unified workspace" bullet), the depth-3 `heading` node ("A sub-point..." — correctly folded into this section as content, per our rule that depth-3+ headings don't start new slides), and the final `paragraph` node ("More detail on the solution."). If your output shows `contentNodeCount=3` here, this is concrete proof that depth-3 headings are correctly absorbed as content rather than incorrectly triggering a fourth section.

If any count doesn't match, the most common cause is an off-by-one in the `depth <= 2` condition — double check it wasn't accidentally written as `depth < 2` (which would treat depth-2 headings as content instead of boundaries) or `depth === 2` alone (which would fail to correctly special-case the depth-1 title).

---

## ✅ Part 7A — Complete

You now have:

- A clear understanding of *why* PPTX rendering is a fundamentally different problem than PDF/DOCX — flowing documents vs. discrete, chunked slides — and the specific "chaptering" analogy that guides our solution.
- A concrete, considered rule: depth-1 headings become a title slide (only when they're the very first section), depth-2 headings start new content slides, and depth-3+ headings stay as content within whichever slide they fall inside.
- `lib/converters/sectionizeMarkdown.ts` — a standalone, single-responsibility function (`sectionizeAst`) that performs exactly this split, kept deliberately separate from any actual slide-drawing logic.
- Verified, via direct console inspection of its output (not yet any generated slides), that the sectionizing logic correctly handles a title section, ordinary sections, and the depth-3 "absorbed as content" edge case.

This pre-pass is the foundation everything in the rest of Part 7 builds on: from this point forward, `toPptx.ts` will never look at the flat, flowing AST directly — it will only ever consume the clean, already-chunked `Section[]` array this function produces, one slide per section.

---
# Part 7B: Generating Slides — Title Slides, Bullets, and Basic Theming

## What This Installment Covers
Turning each `Section` from 7A into an actual slide using `pptxgenjs`'s real API: `addSlide()`, `addText()`. We build a consistent color/font "master" theme, render the special title slide, and render ordinary content slides with headings and bulleted text. Nested lists, code blocks, tables, and images arrive in 7C.

---

## Step 4 — The `pptxgenjs` Coordinate Model

### The Target
No code yet — understanding how `pptxgenjs` positions things on a slide, since it's meaningfully different from both Part 5's Flexbox-auto-layout and Part 6's "just describe structure" approach.

### The Concept

> **Analogy — Placing Furniture With a Tape Measure, Not Letting a Room Arrange Itself.** Neither React-PDF's Flexbox engine nor `docx`'s semantic-styles system apply here. `pptxgenjs` uses **absolute coordinate positioning** — you say "put this text box starting at 0.5 inches from the left, 0.3 inches from the top, 9 inches wide, 1 inch tall." Nothing automatically flows or wraps to avoid collisions the way Flexbox did; if you place two text boxes at overlapping coordinates, they will visually overlap in the output. This mirrors exactly how presentation software like PowerPoint itself works — every element on a slide has an explicit `x`, `y`, `w`, `h` (width, height) position, typically measured in **inches** by default (the library also supports points/percentages, but inches are the default and what we'll use throughout).

This means our converter needs to make **explicit, considered layout decisions** — e.g., "the slide title always sits at the top 15% of the slide; body content always starts below that and fills the remaining space" — decisions that Parts 5 and 6 never had to make so deliberately, since their layout engines handled positioning for us.

### The Verification
No runnable check — proceed to Step 5.

---

## Step 5 — Establishing a Theme

### The Target
`lib/converters/pptxTheme.ts` — a small file of shared constants (colors, fonts, slide dimensions) used consistently across every slide we generate, so the whole deck looks like one coherent design rather than a patchwork.

### The Concept

> **Analogy — A Restaurant's Brand Guidelines Sheet.** Before a restaurant designs any individual menu page, they typically settle on one consistent color palette and font pairing — applied uniformly across every page. We do the same thing here, once, in a dedicated file — exactly the same instinct as Part 5A's `StyleSheet.create` or Part 6's shared `HEADING_LEVELS` constant, just for slide-deck-specific values this time.

### The Implementation

**`lib/converters/pptxTheme.ts`**

```typescript
/**
 * Shared visual constants for every slide generated by toPptx.ts — the
 * single source of truth for colors/fonts, so the whole deck looks
 * consistently designed rather than each slide inventing its own palette.
 */
export const theme = {
  // Slide dimensions in inches — "LAYOUT_16x9" (set on the Pptx instance
  // itself in toPptx.ts) corresponds to a 13.33" x 7.5" widescreen slide.
  slideWidth: 13.33,
  slideHeight: 7.5,

  colors: {
    background: "FFFFFF",
    titleSlideBackground: "1F2937", // dark slate — visually distinct from content slides
    primaryText: "1A1A1A",
    titleSlideText: "FFFFFF",
    accent: "2563EB", // a blue accent, used for section slide titles
    mutedText: "6B7280",
    codeBackground: "111827",
    codeText: "F9FAFB",
    tableHeaderBackground: "F3F4F6",
    tableBorder: "D1D5DB",
  },

  fonts: {
    heading: "Helvetica",
    body: "Helvetica",
    code: "Courier New",
  },

  fontSizes: {
    titleSlideTitle: 40,
    titleSlideSubtitle: 18,
    slideTitle: 28,
    body: 16,
    bullet: 16,
    code: 13,
  },

  // Standard margins used across most content placement — keeping this in
  // one place means adjusting overall slide "breathing room" later is a
  // one-line change, not a hunt through every addText() call.
  margins: {
    left: 0.6,
    right: 0.6,
    top: 0.5,
  },
} as const;
```

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

---

## Step 6 — Rendering the Title Slide

### The Target
The beginning of `lib/converters/toPptx.ts`: a function that takes the special title `Section` (from 7A, where `isTitleSection === true`) and produces one visually distinct opening slide.

### The Concept

> **Analogy — The Cover Page of a Book, Different Paper Stock From the Rest.** A presentation's title slide conventionally looks deliberately different from its content slides — often a dark or bold background, large centered text — signaling "this is the cover, not a content page" before the audience has read a single bullet point. We encode that convention directly: the title slide gets our theme's dark `titleSlideBackground` and large centered white text, while every other slide (built in Step 7) uses a plain white background with dark text.

### The Implementation

**`lib/converters/toPptx.ts`**

```typescript
import PptxGenJS from "pptxgenjs";
import type { Heading, PhrasingContent } from "mdast";
import type { Section } from "./sectionizeMarkdown";
import { theme } from "./pptxTheme";

/**
 * Flattens an inline mdast node (text, strong, emphasis, etc.) down to a
 * PLAIN STRING. Unlike Part 5/6's renderInline (which preserved bold/italic
 * as separate structured runs), pptxgenjs's addText() DOES support rich,
 * per-run formatting via an array of {text, options} objects — we build
 * that richer structure in Step 7 below for body content. For the title
 * slide specifically, we keep it simple with plain flattened text, since a
 * title rarely needs inline bold/italic mixed within it.
 */
function flattenInlineText(nodes: PhrasingContent[]): string {
  return nodes
    .map((node) => {
      if (node.type === "text") return node.value;
      if ("children" in node && Array.isArray(node.children)) {
        return flattenInlineText(node.children as PhrasingContent[]);
      }
      return "";
    })
    .join("");
}

/** Renders the special opening title slide from the document's title Section. */
function renderTitleSlide(pptx: PptxGenJS, titleHeading: Heading | null): void {
  const slide = pptx.addSlide();
  slide.background = { color: theme.colors.titleSlideBackground };

  const titleText = titleHeading
    ? flattenInlineText(titleHeading.children)
    : "Untitled Document";

  slide.addText(titleText, {
    x: 0.5,
    y: theme.slideHeight / 2 - 0.75, // vertically centered on the slide
    w: theme.slideWidth - 1,
    h: 1.5,
    align: "center",
    valign: "middle",
    fontFace: theme.fonts.heading,
    fontSize: theme.fontSizes.titleSlideTitle,
    color: theme.colors.titleSlideText,
    bold: true,
  });
}
```

A few details worth pausing on:

- **`flattenInlineText` recursively unwraps `strong`/`emphasis` wrappers down to plain strings** — this is a deliberate simplification specific to title-slide text, contrasting directly with Parts 5 and 6's approach of preserving bold/italic as distinct structured pieces. We're allowed to make this simplification here because a document title is rarely formatted with inline bold/italic in practice, and keeping the title slide's code simple is a reasonable trade-off — while body content (Step 7 below) still deserves full formatting fidelity.
- **`slide.background = { color: ... }`** sets a solid fill for the entire slide canvas — this is `pptxgenjs`'s equivalent of Part 5's `styles.page` background or Part 6's default white canvas, just set per-slide rather than globally, since we specifically want the title slide to look different from every other slide.
- **Coordinates computed from `theme.slideHeight`** (rather than hardcoded numbers) mean if we ever change the overall slide size in `pptxTheme.ts`, this centering math automatically stays correct — a small but real payoff of Step 5's shared-constants approach.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output. We'll fully exercise `renderTitleSlide` once `toPptx`'s outer function exists — that's Step 7 below, where content slides join it and we generate our first real `.pptx` file.

---

## Step 7 — Rendering Content Slides with Bulleted Text

### The Target
Extend `toPptx.ts` with `renderContentSlide`, handling a `Section`'s heading (as the slide title) and its `paragraph`/`list` content nodes (as bulleted body text), plus the outer `toPptx()` function that ties everything together into a real `.pptx` buffer.

### The Concept

> **Analogy — One Slide, One Index Card.** Recall from 7A: each `Section` becomes exactly one slide. This step is where we actually draw that slide's two zones: a title area at the top (the section's heading text), and a body area beneath it (everything else). For body content specifically, `pptxgenjs`'s `addText()` function has a genuinely convenient built-in feature for our use case: you can pass an **array** of `{ text, options }` objects, each with its own `bullet` option, and the library automatically stacks them as a bulleted list within one text box — no manual y-coordinate math per bullet required, unlike if we were positioning each line individually.

### The Implementation

**`lib/converters/toPptx.ts`** — add this below `renderTitleSlide` (everything above stays as written):

```typescript
import type { RootContent, ListItem } from "mdast";

/**
 * One line of body content, ready for pptxgenjs's addText() array form:
 * plain text plus per-line formatting options (bullet level, bold, etc.)
 */
interface TextLine {
  text: string;
  options: {
    bullet?: boolean | { indent: number };
    bold?: boolean;
    breakLine?: boolean;
  };
}

/**
 * Recursively flattens a list's items (including nested sub-lists) into a
 * flat array of TextLines, each carrying the correct indentation level via
 * `bullet.indent` — pptxgenjs uses indent VALUE (in points) rather than a
 * simple depth number, so we multiply our depth by a fixed step.
 */
function flattenListToLines(items: ListItem[], depth: number): TextLine[] {
  const lines: TextLine[] = [];

  for (const item of items) {
    for (const child of item.children) {
      if (child.type === "paragraph") {
        lines.push({
          text: flattenInlineText(child.children),
          options: { bullet: { indent: depth * 20 }, breakLine: true },
        });
      } else if (child.type === "list") {
        // THE RECURSIVE STEP: a nested list's items get folded into the
        // SAME flat array, just at depth + 1 — pptxgenjs doesn't have a
        // native "nested list" object the way docx did; indentation level
        // alone is what visually communicates nesting in a slide.
        lines.push(...flattenListToLines(child.children as ListItem[], depth + 1));
      }
    }
  }

  return lines;
}

/**
 * Converts one Section's content nodes (paragraphs, lists — code/tables/
 * images arrive in 7C) into a flat array of TextLines ready for a single
 * addText() call. This is the per-slide equivalent of Parts 5/6's
 * renderBlockNode, just producing a flat line array instead of nested
 * PDF/DOCX primitives — the natural shape for pptxgenjs's bullet API.
 */
function renderContentNodes(nodes: RootContent[]): TextLine[] {
  const lines: TextLine[] = [];

  for (const node of nodes) {
    if (node.type === "paragraph") {
      lines.push({
        text: flattenInlineText(node.children),
        options: { breakLine: true },
      });
    } else if (node.type === "list") {
      lines.push(...flattenListToLines(node.children as ListItem[], 0));
    } else if (node.type === "heading") {
      // Depth-3+ headings absorbed as content by our 7A sectionizer —
      // rendered here as bold, slightly larger-feeling text (we don't
      // have per-line font-size control in this simple array form, so
      // bold is our signal for "this is a sub-heading," consistent with
      // how we handled links in Part 6B's DOCX renderer).
      lines.push({
        text: flattenInlineText(node.children as PhrasingContent[]),
        options: { bold: true, breakLine: true },
      });
    } else {
      console.warn(`[toPptx] Unsupported content node type: "${node.type}"`);
    }
  }

  return lines;
}

/** Renders one ordinary (non-title) content slide from a Section. */
function renderContentSlide(pptx: PptxGenJS, section: Section): void {
  const slide = pptx.addSlide();
  slide.background = { color: theme.colors.background };

  const titleText = section.heading
    ? flattenInlineText(section.heading.children)
    : "";

  if (titleText) {
    slide.addText(titleText, {
      x: theme.margins.left,
      y: theme.margins.top,
      w: theme.slideWidth - theme.margins.left - theme.margins.right,
      h: 0.9,
      fontFace: theme.fonts.heading,
      fontSize: theme.fontSizes.slideTitle,
      color: theme.colors.accent,
      bold: true,
    });
  }

  const lines = renderContentNodes(section.content);

  if (lines.length > 0) {
    // pptxgenjs's addText() accepts an ARRAY of {text, options} objects as
    // its first argument (instead of a single string) specifically to
    // support exactly this case: multiple distinctly-formatted lines
    // stacked automatically within one text box, no manual y-math needed.
    slide.addText(
      lines.map((line) => ({ text: line.text, options: line.options })),
      {
        x: theme.margins.left,
        y: theme.margins.top + 1.1,
        w: theme.slideWidth - theme.margins.left - theme.margins.right,
        h: theme.slideHeight - theme.margins.top - 1.6,
        fontFace: theme.fonts.body,
        fontSize: theme.fontSizes.body,
        color: theme.colors.primaryText,
        valign: "top",
      }
    );
  }
}

/**
 * Converts a Section[] (from sectionizeAst, Part 7A) into a complete .pptx
 * file buffer — the final export of this module, wired into the Route
 * Handler in 7C.
 */
export async function toPptx(sections: Section[]): Promise<Buffer> {
  const pptx = new PptxGenJS();

  // LAYOUT_16x9 sets the slide dimensions to match theme.slideWidth/Height
  // (13.33" x 7.5") — a modern widescreen aspect ratio, matching what most
  // current presentation software defaults to.
  pptx.defineLayout({ name: "GREYMATTER_16x9", width: theme.slideWidth, height: theme.slideHeight });
  pptx.layout = "GREYMATTER_16x9";

  for (const section of sections) {
    if (section.isTitleSection) {
      renderTitleSlide(pptx, section.heading);
      // A title section can ALSO carry leading content (recall 7A's
      // example: "Welcome slide — presented by the Product team." lived
      // inside the title section). If present, we give it its own
      // additional slide immediately after the title slide, rather than
      // silently dropping it or awkwardly cramming it onto the cover.
      if (section.content.length > 0) {
        renderContentSlide(pptx, { ...section, isTitleSection: false });
      }
    } else {
      renderContentSlide(pptx, section);
    }
  }

  // pptxgenjs's write() method, given "nodebuffer", returns a real Node.js
  // Buffer directly — the PPTX equivalent of Part 5's renderToBuffer and
  // Part 6's Packer.toBuffer().
  const buffer = (await pptx.write({ outputType: "nodebuffer" })) as Buffer;
  return buffer;
}
```

A few details worth pausing on:

- **The title section's leftover content becomes its own extra slide** — this is a deliberate design decision resolving the exact edge case flagged back in 7A's worked example. Rather than the "Welcome slide..." paragraph vanishing silently (a correctness bug) or being crammed awkwardly onto the title slide itself (a visual design compromise), we give it a clean, dedicated slide of its own, immediately following the cover.
- **`bullet: { indent: depth * 20 }`** — unlike Part 5's PDF renderer (which multiplied depth by *pixels* for a `marginLeft`) or Part 6's DOCX renderer (which used *twips* for `indent.left`), `pptxgenjs` expects its indent value in **points**, a third different unit for conceptually the same "how far right should this line start" idea. This is worth noting explicitly: every library in this series measures space slightly differently, and checking each library's own documented unit (Appendix G covers this in full for `pptxgenjs`) is a genuine, recurring task when integrating multiple rendering libraries.
- **`pptx.write({ outputType: "nodebuffer" })`** — `pptxgenjs` can also write directly to disk or return a browser-oriented `Blob`, depending on the `outputType` you request; we explicitly request `"nodebuffer"` because our Route Handler (wired up in 7C) needs a genuine Node.js `Buffer`, exactly like Part 5 and Part 6's converters both ultimately produced.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

Let's generate our first real `.pptx` file, combining both installments 7A and 7B end to end:

**`scripts/test-pptx.ts`**

```typescript
import { writeFileSync } from "fs";
import { parseMarkdown } from "../lib/parseMarkdown";
import { sectionizeAst } from "../lib/converters/sectionizeMarkdown";
import { toPptx } from "../lib/converters/toPptx";

async function main() {
  const markdown = `# Product Launch Overview

Welcome slide — presented by the Product team.

## The Problem

- Users currently juggle three disconnected tools
- Switching costs slow teams down by an estimated 5 hours/week
- Existing solutions are expensive and hard to customize

## Our Solution

- One unified workspace
- Real-time collaboration built in
  - Live cursors
  - Instant comments
- Priced for teams of any size

### A sub-point (should stay on this same slide)

More detail on the solution, folded into the same slide as ordinary content.
`;

  const ast = parseMarkdown(markdown);
  const sections = sectionizeAst(ast);
  const buffer = await toPptx(sections);

  writeFileSync("test-output.pptx", buffer);
  console.log(`✅ Wrote test-output.pptx (${buffer.byteLength} bytes), ${sections.length} sections`);
}

main().catch((err) => {
  console.error("❌ Failed to generate test PPTX:", err);
  process.exit(1);
});
```

Run it:

```bash
npx tsx scripts/test-pptx.ts
```

Expected terminal output:

```
✅ Wrote test-output.pptx (XXXX bytes), 3 sections
```

Open `test-output.pptx` in **PowerPoint, Google Slides (upload it), or Keynote**. Confirm:

1. **Slide 1** — a dark background, large centered white bold title: "Product Launch Overview."
2. **Slide 2** — a plain white background, "Welcome slide — presented by the Product team." as the body text — confirming the title section's leftover content correctly became its own dedicated slide.
3. **Slide 3** — titled "The Problem" (in the blue accent color, top-left), with three bulleted lines beneath it.
4. **Slide 4** — titled "Our Solution," with bullets including a visibly further-indented nested sub-bullet ("Live cursors," "Instant comments"), followed by a bold "A sub-point..." line and its accompanying plain paragraph — both correctly appearing on this *same* slide rather than spawning a new one, confirming depth-3 headings are still correctly absorbed as content per our 7A rule.

Clean up:

```bash
rm test-output.pptx
```

---

## ✅ Part 7B — Complete

You now have a fully working slide generator: a themed title slide, automatically generated content slides with correctly nested bulleted text, and confirmed handling of the "leftover title-section content" and "depth-3 heading absorption" edge cases — all verified in a real presentation application.

Remaining from Part 3A's reference table, specific to slides: code blocks (as monospace text boxes) and tables/images — plus wiring `toPptx` into the Route Handler to finally retire the last stub.

---
# Part 7C: Code Blocks, Tables, Images, and Wiring `toPptx` into the Route Handler

## What This Installment Covers
The final three content types our slide renderer needs — `code` blocks (as monospace text boxes), `table` (via `addTable`), and `image` (via `addImage`) — plus wiring `toPptx` into the Route Handler, finally retiring the last remaining stub. By the end, all three export formats work end-to-end from the same UI, completing the entire converter series.

---

## Step 8 — Rendering Code Blocks as Monospace Text Boxes

### The Target
Extend `renderContentNodes` to handle `code` nodes, rendering them as their own dedicated, separately-positioned monospace text box rather than folding them into the same flowing bullet-line array everything else uses.

### The Concept

> **Analogy — A Quoted Excerpt Gets Its Own Inset Box, Not Just Another Paragraph.** So far, every content type (`paragraph`, `list`, absorbed `heading`) has been flattened into one shared array of `TextLine`s, all living inside a single `addText()` call. A code block deserves different visual treatment — a distinct shaded background box, a monospace font, and no bullet styling — which means it can't simply be another entry in that same flat array (recall from Step 7 that the *entire* array shares one set of font/color options passed to a single `addText()` call). Instead, we treat a `code` node as a **fully separate slide element**, added via its own dedicated `addText()` call at its own coordinates — conceptually similar to how Part 5B's PDF renderer gave code blocks their own shaded `<View>`, separate from ordinary paragraph `<Text>` styling.

This requires a small architectural shift: `renderContentSlide` needs to track a **running vertical position** (`currentY`) as it places each distinct element down the slide, rather than relying on one single text box to hold everything.

### The Implementation

**`lib/converters/toPptx.ts`** — add this new style entry to `pptxTheme.ts` first:

**`lib/converters/pptxTheme.ts`** — no changes needed; `theme.colors.codeBackground`, `theme.colors.codeText`, and `theme.fonts.code`/`theme.fontSizes.code` were already defined back in Step 5, anticipating this exact use.

Now update `toPptx.ts`. Replace the `renderContentNodes` function and `renderContentSlide` function with the versions below — this is a structural rewrite of how slide content gets positioned, so read through the changes carefully:

```typescript
/**
 * Represents ONE positioned element to be placed on a slide — either a
 * flowing text block (bullets/paragraphs, same as Step 7) or a dedicated
 * code block. Kept as a tagged union so renderContentSlide (below) can
 * walk through a slide's content once, placing each element at its own
 * Y position, growing `currentY` as it goes.
 */
type SlideElement =
  | { kind: "text"; lines: TextLine[] }
  | { kind: "code"; code: string };

/**
 * Converts one Section's content nodes into an ordered array of
 * SlideElements. Consecutive paragraph/list/heading nodes are BATCHED
 * together into one "text" element (so they still share one addText bullet
 * list, exactly as Step 7 built), but a `code` node always breaks that
 * batch and becomes its own separate "code" element.
 */
function renderContentNodes(nodes: RootContent[]): SlideElement[] {
  const elements: SlideElement[] = [];
  let currentBatch: TextLine[] = [];

  function flushBatch() {
    if (currentBatch.length > 0) {
      elements.push({ kind: "text", lines: currentBatch });
      currentBatch = [];
    }
  }

  for (const node of nodes) {
    if (node.type === "paragraph") {
      currentBatch.push({
        text: flattenInlineText(node.children),
        options: { breakLine: true },
      });
    } else if (node.type === "list") {
      currentBatch.push(...flattenListToLines(node.children as ListItem[], 0));
    } else if (node.type === "heading") {
      currentBatch.push({
        text: flattenInlineText(node.children as PhrasingContent[]),
        options: { bold: true, breakLine: true },
      });
    } else if (node.type === "code") {
      // A code block ALWAYS breaks the current text batch, since it needs
      // its own distinctly-styled, separately-positioned box.
      flushBatch();
      elements.push({ kind: "code", code: node.value });
    } else {
      console.warn(`[toPptx] Unsupported content node type: "${node.type}"`);
    }
  }

  flushBatch();
  return elements;
}

/** Renders one ordinary (non-title) content slide from a Section. */
function renderContentSlide(pptx: PptxGenJS, section: Section): void {
  const slide = pptx.addSlide();
  slide.background = { color: theme.colors.background };

  const titleText = section.heading ? flattenInlineText(section.heading.children) : "";

  if (titleText) {
    slide.addText(titleText, {
      x: theme.margins.left,
      y: theme.margins.top,
      w: theme.slideWidth - theme.margins.left - theme.margins.right,
      h: 0.9,
      fontFace: theme.fonts.heading,
      fontSize: theme.fontSizes.slideTitle,
      color: theme.colors.accent,
      bold: true,
    });
  }

  const elements = renderContentNodes(section.content);

  // `currentY` tracks how far down the slide we've placed content so far —
  // the manual "tape measure" bookkeeping this coordinate-based library
  // requires (see Step 4's furniture-placement analogy), since nothing
  // here auto-flows the way Part 5's Flexbox engine did.
  let currentY = theme.margins.top + 1.1;
  const contentWidth = theme.slideWidth - theme.margins.left - theme.margins.right;
  const maxY = theme.slideHeight - 0.4;

  for (const element of elements) {
    if (currentY >= maxY) {
      // Simple overflow guard: once we run out of vertical room on this
      // slide, stop placing further elements rather than drawing them
      // off-slide or overlapping existing content. A more advanced
      // implementation could start an ADDITIONAL overflow slide here —
      // a great extension exercise, flagged explicitly rather than
      // silently truncating without acknowledgment.
      console.warn(
        `[toPptx] Slide "${titleText}" has more content than fits — remaining elements were skipped.`
      );
      break;
    }

    if (element.kind === "text") {
      // Rough height estimate: ~0.35" per line, so taller text blocks
      // correctly push subsequent elements further down the slide.
      const estimatedHeight = Math.max(0.5, element.lines.length * 0.35);

      slide.addText(
        element.lines.map((line) => ({ text: line.text, options: line.options })),
        {
          x: theme.margins.left,
          y: currentY,
          w: contentWidth,
          h: estimatedHeight,
          fontFace: theme.fonts.body,
          fontSize: theme.fontSizes.body,
          color: theme.colors.primaryText,
          valign: "top",
        }
      );

      currentY += estimatedHeight + 0.15;
    } else {
      // "code" element: its own shaded, monospace box.
      const codeLines = element.code.split("\n");
      const codeHeight = Math.max(0.6, codeLines.length * 0.28);

      slide.addText(element.code, {
        x: theme.margins.left,
        y: currentY,
        w: contentWidth,
        h: codeHeight,
        fontFace: theme.fonts.code,
        fontSize: theme.fontSizes.code,
        color: theme.colors.codeText,
        fill: { color: theme.colors.codeBackground },
        valign: "top",
      });

      currentY += codeHeight + 0.2;
    }
  }
}
```

A detail worth pausing on: **the `SlideElement` tagged union, and batching consecutive text nodes together** — rather than giving every single paragraph and list its own separate `addText()` call (which would work, but would waste vertical space with inconsistent line spacing, since each call is a fully independent text box), we keep Step 7's "one shared bullet list" behavior intact for *runs* of ordinary content, and only break out into a separate element when a genuinely different visual treatment (a code block) requires it. This distinction — many small `renderX` functions for genuinely different concerns, vs. batching when it doesn't matter — is a real design judgment call, not a mechanical rule, and worth developing an instinct for as you write your own converters later.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

---

## Step 9 — Rendering Tables and Images

### The Target
Add `table` and `image` handling to `renderContentNodes`/`renderContentSlide`, using `pptxgenjs`'s native `addTable()` and `addImage()` methods.

### The Concept

> **Analogy — Two More Specialized Furniture Pieces for the Same Room.** Exactly like the code block in Step 8, tables and images are each their own distinct `SlideElement` kind, positioned and sized independently rather than folded into the flowing bullet-text batch. `pptxgenjs`'s `addTable()` accepts a 2D array of row data directly (no manual `View` nesting the way Part 5's PDF renderer needed, and no separate `TableRow`/`TableCell` object construction the way Part 6's DOCX renderer needed) — it's the most concise table API of all three libraries in this series. `addImage()`, similarly, accepts raw image bytes directly.

### The Implementation

**`lib/converters/toPptx.ts`** — update the `SlideElement` union and imports:

```typescript
import type { RootContent, ListItem, Table as MdastTable } from "mdast";
```

```typescript
type SlideElement =
  | { kind: "text"; lines: TextLine[] }
  | { kind: "code"; code: string }
  | { kind: "table"; rows: string[][] }
  | { kind: "image"; bytes: Buffer | null; alt: string };
```

Update `renderContentNodes` to accept the pre-fetched images map (reusing the exact fetch strategy from Parts 5C/6C) and add the new cases:

```typescript
function renderContentNodes(
  nodes: RootContent[],
  images: Map<string, Buffer | null>
): SlideElement[] {
  const elements: SlideElement[] = [];
  let currentBatch: TextLine[] = [];

  function flushBatch() {
    if (currentBatch.length > 0) {
      elements.push({ kind: "text", lines: currentBatch });
      currentBatch = [];
    }
  }

  for (const node of nodes) {
    if (node.type === "paragraph") {
      currentBatch.push({
        text: flattenInlineText(node.children),
        options: { breakLine: true },
      });
    } else if (node.type === "list") {
      currentBatch.push(...flattenListToLines(node.children as ListItem[], 0));
    } else if (node.type === "heading") {
      currentBatch.push({
        text: flattenInlineText(node.children as PhrasingContent[]),
        options: { bold: true, breakLine: true },
      });
    } else if (node.type === "code") {
      flushBatch();
      elements.push({ kind: "code", code: node.value });
    } else if (node.type === "table") {
      flushBatch();
      const mdastTable = node as MdastTable;
      const rows = mdastTable.children.map((row) =>
        row.children.map((cell) => flattenInlineText(cell.children))
      );
      elements.push({ kind: "table", rows });
    } else if (node.type === "image") {
      flushBatch();
      const bytes = images.get(node.url) ?? null;
      elements.push({ kind: "image", bytes, alt: node.alt || node.url });
    } else {
      console.warn(`[toPptx] Unsupported content node type: "${node.type}"`);
    }
  }

  flushBatch();
  return elements;
}
```

Now update `renderContentSlide` to accept and thread through the `images` map, and to handle the two new `SlideElement` kinds inside its placement loop:

```typescript
/** Renders one ordinary (non-title) content slide from a Section. */
function renderContentSlide(
  pptx: PptxGenJS,
  section: Section,
  images: Map<string, Buffer | null>
): void {
  const slide = pptx.addSlide();
  slide.background = { color: theme.colors.background };

  const titleText = section.heading ? flattenInlineText(section.heading.children) : "";

  if (titleText) {
    slide.addText(titleText, {
      x: theme.margins.left,
      y: theme.margins.top,
      w: theme.slideWidth - theme.margins.left - theme.margins.right,
      h: 0.9,
      fontFace: theme.fonts.heading,
      fontSize: theme.fontSizes.slideTitle,
      color: theme.colors.accent,
      bold: true,
    });
  }

  const elements = renderContentNodes(section.content, images);

  let currentY = theme.margins.top + 1.1;
  const contentWidth = theme.slideWidth - theme.margins.left - theme.margins.right;
  const maxY = theme.slideHeight - 0.4;

  for (const element of elements) {
    if (currentY >= maxY) {
      console.warn(
        `[toPptx] Slide "${titleText}" has more content than fits — remaining elements were skipped.`
      );
      break;
    }

    if (element.kind === "text") {
      const estimatedHeight = Math.max(0.5, element.lines.length * 0.35);
      slide.addText(
        element.lines.map((line) => ({ text: line.text, options: line.options })),
        {
          x: theme.margins.left,
          y: currentY,
          w: contentWidth,
          h: estimatedHeight,
          fontFace: theme.fonts.body,
          fontSize: theme.fontSizes.body,
          color: theme.colors.primaryText,
          valign: "top",
        }
      );
      currentY += estimatedHeight + 0.15;
    } else if (element.kind === "code") {
      const codeLines = element.code.split("\n");
      const codeHeight = Math.max(0.6, codeLines.length * 0.28);
      slide.addText(element.code, {
        x: theme.margins.left,
        y: currentY,
        w: contentWidth,
        h: codeHeight,
        fontFace: theme.fonts.code,
        fontSize: theme.fontSizes.code,
        color: theme.colors.codeText,
        fill: { color: theme.colors.codeBackground },
        valign: "top",
      });
      currentY += codeHeight + 0.2;
    } else if (element.kind === "table") {
      // addTable expects a 2D array, where the OUTER array is rows and
      // each inner array is that row's cells — a plain 2D array is all
      // that's required, notably simpler than Part 5's nested <View>
      // grids or Part 6's TableRow/TableCell object construction.
      const tableHeight = Math.max(0.8, element.rows.length * 0.4);
      slide.addTable(
        element.rows.map((row, rowIndex) =>
          row.map((cellText) => ({
            text: cellText,
            options: {
              bold: rowIndex === 0,
              fill: rowIndex === 0 ? { color: theme.colors.tableHeaderBackground } : undefined,
              fontFace: theme.fonts.body,
              fontSize: theme.fontSizes.body - 2,
              color: theme.colors.primaryText,
            },
          }))
        ),
        {
          x: theme.margins.left,
          y: currentY,
          w: contentWidth,
          h: tableHeight,
          border: { type: "solid", color: theme.colors.tableBorder, pt: 1 },
        }
      );
      currentY += tableHeight + 0.2;
    } else {
      // "image" element
      if (!element.bytes) {
        slide.addText(`[Image could not be loaded: ${element.alt}]`, {
          x: theme.margins.left,
          y: currentY,
          w: contentWidth,
          h: 0.4,
          italic: true,
          color: "B91C1C",
          fontSize: theme.fontSizes.body - 2,
        });
        currentY += 0.6;
      } else {
        const imageHeight = 2.5;
        slide.addImage({
          data: `data:image/png;base64,${element.bytes.toString("base64")}`,
          x: theme.margins.left,
          y: currentY,
          w: 4,
          h: imageHeight,
        });
        currentY += imageHeight + 0.2;
      }
    }
  }
}
```

Finally, update `toPptx` itself to pre-fetch images (reusing the identical `collectImageUrls`/`fetchImages` helpers from Parts 5C/6C) and pass the map through:

```typescript
/** Recursively collects every image URL present anywhere across all sections. */
function collectImageUrls(sections: Section[], urls: Set<string>): void {
  for (const section of sections) {
    for (const node of section.content) {
      collectFromNode(node, urls);
    }
  }
}

function collectFromNode(node: RootContent, urls: Set<string>): void {
  if (node.type === "image") {
    urls.add(node.url);
  }
  if ("children" in node && Array.isArray(node.children)) {
    for (const child of node.children) {
      collectFromNode(child as RootContent, urls);
    }
  }
}

async function fetchImages(sections: Section[]): Promise<Map<string, Buffer | null>> {
  const urls = new Set<string>();
  collectImageUrls(sections, urls);

  const results = new Map<string, Buffer | null>();

  await Promise.all(
    Array.from(urls).map(async (url) => {
      try {
        const response = await fetch(url);
        if (!response.ok) {
          console.warn(`[toPptx] Image fetch failed (status ${response.status}): ${url}`);
          results.set(url, null);
          return;
        }
        const arrayBuffer = await response.arrayBuffer();
        results.set(url, Buffer.from(arrayBuffer));
      } catch (err) {
        console.warn(`[toPptx] Image fetch threw an error for ${url}:`, err);
        results.set(url, null);
      }
    })
  );

  return results;
}

export async function toPptx(sections: Section[]): Promise<Buffer> {
  const pptx = new PptxGenJS();

  pptx.defineLayout({ name: "GREYMATTER_16x9", width: theme.slideWidth, height: theme.slideHeight });
  pptx.layout = "GREYMATTER_16x9";

  const images = await fetchImages(sections);

  for (const section of sections) {
    if (section.isTitleSection) {
      renderTitleSlide(pptx, section.heading);
      if (section.content.length > 0) {
        renderContentSlide(pptx, { ...section, isTitleSection: false }, images);
      }
    } else {
      renderContentSlide(pptx, section, images);
    }
  }

  const buffer = (await pptx.write({ outputType: "nodebuffer" })) as Buffer;
  return buffer;
}
```

A detail worth pausing on: **`addImage`'s `data` field uses a base64 data URL** (`data:image/png;base64,...`), rather than accepting a raw `Buffer` directly the way React-PDF's `<Image>` did in Part 5 — this is `pptxgenjs`'s own specific API requirement, and a good concrete example of why checking each library's documented expectations individually (Appendix G) matters even when the underlying problem (embed some image bytes) is conceptually identical across all three converters.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output.

Update `scripts/test-pptx.ts`'s markdown to include a table, an image, and a code block:

```typescript
  const markdown = `# Product Launch Overview

Welcome slide — presented by the Product team.

## The Problem

- Users currently juggle three disconnected tools
- Switching costs slow teams down

## Feature Comparison

| Feature | Us | Them |
| --- | --- | --- |
| Real-time sync | Yes | No |
| Price | $$ | $$$$ |

## Architecture

\`\`\`typescript
function connect(): void {
  console.log("connected");
}
\`\`\`

## Our Logo

![Logo](https://placehold.co/300x150.png)
`;
```

Run:

```bash
npx tsx scripts/test-pptx.ts
```

Open `test-output.pptx` in a real presentation app and confirm: the comparison table renders as a genuine, bordered table with a shaded header row; the code block appears as a dark, monospace text box; the logo image genuinely appears embedded on its slide.

Clean up:

```bash
rm test-output.pptx
```

---

## Step 10 — Wiring `toPptx` into the Route Handler

### The Target
Update `app/api/convert/[format]/route.ts`: replace the final PPTX stub with real calls to `sectionizeAst()` and `toPptx()`.

### The Implementation

**`app/api/convert/[format]/route.ts`** 

```typescript
import { NextRequest, NextResponse } from "next/server";
import { renderToBuffer } from "@react-pdf/renderer";
import { parseMarkdown } from "@/lib/parseMarkdown";
import { toPdf } from "@/lib/converters/toPdf";
import { toDocx } from "@/lib/converters/toDocx";
import { sectionizeAst } from "@/lib/converters/sectionizeMarkdown";
import { toPptx } from "@/lib/converters/toPptx";

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
      fileBuffer = await toDocx(ast);
    } else {
      // THE FINAL REAL IMPLEMENTATION: sectionize the flowing AST into
      // slide-sized chunks (Part 7A), then render each chunk into a real
      // slide (Part 7B/7C). This retires the last remaining stub — every
      // format now produces genuine output.
      const sections = sectionizeAst(ast);
      fileBuffer = await toPptx(sections);
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
```

Notice `countNodes` has been removed entirely — it was only ever used by the stub-content messages, which no longer exist now that every format has a real implementation. Deleting dead code like this once it's no longer needed is good hygiene, not an oversight.

### The Verification

Restart the dev server:

```bash
npm run dev
```

**Terminal test first, via `curl`:**

```bash
curl -i -X POST http://localhost:3000/api/convert/pptx \
  -H "Content-Type: application/json" \
  -d '{"markdown": "# Real PPTX Test\n\nIntro slide content.\n\n## Section One\n\n- Point A\n- Point B"}' \
  -o real-test.pptx
```

Expected: `HTTP/1.1 200 OK` with the correct PPTX `Content-Type`. Open `real-test.pptx` in a real presentation app and confirm a title slide, an intro-content slide, and a bulleted "Section One" slide all appear correctly.

```bash
rm real-test.pptx
```

**Now the full, final test through the live app UI — all three formats, back to back:**

Open **http://localhost:3000**. Load the **Slide Deck Outline** template from the dropdown (recall from Part 2C, this template was deliberately written with `##` section breaks in mind).

1. Click **Export as PPTX** — confirm a real, multi-slide deck downloads: a dark title slide ("Product Launch Overview"), followed by content slides for "The Problem," "Our Solution," "Roadmap," and "Thank You," each with correctly bulleted content.
2. Click **Export as PDF** — confirm this same document downloads as a correctly formatted, flowing PDF (headings, bullets, all in one continuous document — a genuinely different visual shape from the slide deck, as expected).
3. Click **Export as DOCX** — confirm this same document downloads as a correctly formatted Word document.
4. As a final combined test, load the **Report** template (with its table and blockquote), and export all three formats again — confirming tables render correctly as a PDF grid, a native Word table, and a bordered slide table respectively; and that the blockquote appears correctly in the PDF and DOCX outputs (blockquotes were never part of our PPTX slide-content handling — check your terminal for the expected `console.warn("[toPptx] Unsupported content node type: "blockquote"")` message, a deliberately graceful, visible gap rather than a silent one, and a good real example of Part 8's error-handling philosophy already at work).

---

## ✅ Part 7 — Complete

Checking against the full Part 7 blueprint:

| Blueprint requirement | Where it was built |
|---|---|
| Conceptual shift: slide-splitting strategy | 7A, Step 2 |
| "Sectionize AST by heading" pre-pass | 7A, Step 3 |
| Per-section slide generation (`addSlide`, `addText`, `addImage`, `addTable`) | 7B, 7C |
| Basic theming (title slide, consistent color/font master) | 7B, Step 5–6 |
| Wired into export pipeline, returns `.pptx` binary via Route Handler | 7C, Step 10 |
| All three export formats work end-to-end from the same UI | Verified live, this installment |

---

## 🎉 The Core Converter Series Is Complete

Stepping back to the very beginning: Part 0 promised one core insight — **parse once, render three times** — and every part since has been in service of that single idea. Let's see the whole arc, end to end:

- **Parts 1–4** built the foundation: a real Next.js project, a live two-pane editor, a typed and inspectable `parseMarkdown()` function, and a fully validated, production-shaped Route Handler + download pipeline — all *before* a single real converter existed.
- **Part 5** taught the core pattern once, deeply: a recursive AST walker mapped to `@react-pdf/renderer`'s component model, covering every major `mdast` node type, with fonts and pagination.
- **Part 6** applied that exact same pattern to `docx`'s object model — different vocabulary, same recursive shape, plus a real lesson in debugging a flawed design (the `TextRun` read-back mistake) the honest way.
- **Part 7** applied the pattern a third time to `pptxgenjs`, but honestly confronted the one place where the analogy needed to bend: slides require a sectionizing pre-pass that flowing documents never needed — and we built that as its own clean, isolated concern rather than complicating either renderer.

Three formats. One shared AST. One pattern, learned once and reinforced three times, exactly as Part 0 promised.
