# Part 3A: Understanding `mdast` & Writing `lib/parseMarkdown.ts`

## What This Installment Covers
Back in Part 1, we called `unified().use(remarkParse).use(remarkGfm).parse(markdown)` directly inside a Server Action, as a quick proof-of-concept. Today we formalize that into a proper, reusable, typed module — `lib/parseMarkdown.ts` — and build a solid mental model of the tree shapes it produces. This installment is the foundation for every renderer we write in Parts 5, 6, and 7, so we're going to be thorough about it.

---

## Step 1 — What Exactly Is a Node?

### The Target
No code yet — building an accurate mental model of `mdast`'s tree shape before we touch the parser wrapper.

### The Concept

> **Analogy — A Family Tree, But Every Person Can Also Be a "Container" for Other People.** In `mdast` (**M**ark**d**own **A**bstract **S**yntax **T**ree), every single piece of your document — a heading, a paragraph, a bold word, even a single letter of plain text — is represented as a **node**: a plain JavaScript object with, at minimum, a `type` field (a string like `"heading"` or `"paragraph"`) telling you what kind of thing it is. Some nodes are "parents" that hold other nodes inside a `children` array (a heading node contains text nodes; a list node contains list-item nodes). Some nodes are "leaves" — they hold actual content directly (like a `value` field with a string) and have no `children` at all.

The single root of the entire tree is always one special node: `{ type: "root", children: [...] }` — think of it as the family tree's single ancestor from which every other node descends.

Here's a small, concrete example. This Markdown:

```markdown
# Hello

This is **bold**.
```

Parses into this tree shape (simplified, with `position` data omitted for readability — recall from Part 1 that `position` tracks source line/column and is safe to ignore for now):

```json
{
  "type": "root",
  "children": [
    {
      "type": "heading",
      "depth": 1,
      "children": [
        { "type": "text", "value": "Hello" }
      ]
    },
    {
      "type": "paragraph",
      "children": [
        { "type": "text", "value": "This is " },
        {
          "type": "strong",
          "children": [
            { "type": "text", "value": "bold" }
          ]
        },
        { "type": "text", "value": "." }
      ]
    }
  ]
}
```

Notice the `strong` (bold) node doesn't hold the word "bold" directly — it holds `children`, which contains a `text` node with `value: "bold"`. This is deliberate and important: it means **formatting is expressed as nesting, not as a flag on the text itself**. A `text` node never says "I am bold" — instead, a `text` node is *wrapped inside* a `strong` node. This single idea — that emphasis, bold, links, etc. are all just "wrapper" node types around plain `text` nodes — is what makes every renderer we write later possible: each renderer just needs to know "when I see a `strong` wrapper, make whatever's inside it bold," regardless of what's actually inside.

### The Verification
No runnable check yet — this mental model gets exercised directly in Step 2's reference table and Step 3's code.

---

## Step 2 — The Core `mdast` Node Type Reference

### The Target
A working reference table of every node type this series' converters will need to handle, to consult while reading Step 3's code and every future Part 5–7 renderer.

### The Concept

> **Analogy — A Field Guide to Birds.** You don't memorize every bird species before your first walk in the woods — you carry a field guide and look things up as you spot them. This table is that field guide for `mdast`. Keep it bookmarked; every renderer in Parts 5–7 will reference specific rows from this exact table.

| `type` | Meaning | Key fields | Has `children`? |
|---|---|---|---|
| `root` | The whole document | — | Yes |
| `heading` | `# ... ######` | `depth` (1–6) | Yes |
| `paragraph` | A block of normal text | — | Yes |
| `text` | Plain text content | `value` (string) | No |
| `strong` | `**bold**` | — | Yes |
| `emphasis` | `*italic*` | — | Yes |
| `delete` | `~~strikethrough~~` (GFM) | — | Yes |
| `inlineCode` | `` `code` `` | `value` (string) | No |
| `code` | ` ```fenced block``` ` | `value` (string), `lang` (string \| null) | No |
| `link` | `[text](url)` | `url`, `title` | Yes |
| `image` | `![alt](url)` | `url`, `alt`, `title` | No |
| `list` | `-`/`1.` list | `ordered` (bool), `start` (number \| null) | Yes |
| `listItem` | One `-`/`1.` entry | `checked` (bool \| null, for GFM task lists) | Yes |
| `blockquote` | `> quoted text` | — | Yes |
| `thematicBreak` | `---` (horizontal rule) | — | No |
| `table` | GFM table | `align` (array per column) | Yes |
| `tableRow` | One row of a table | — | Yes |
| `tableCell` | One cell of a row | — | Yes |
| `break` | A hard line break (two trailing spaces + newline) | — | No |

A few entries worth a specific, plain-English callout:

- **`code` vs `inlineCode`** are easy to confuse by name alone. `inlineCode` is `` `like this` `` sitting inside a sentence. `code` is a full fenced block (\`\`\`) that stands alone as its own block — and only `code` carries a `lang` field (e.g., `"lang": "typescript"`), which our PDF/DOCX renderers will later use to decide things like syntax-appropriate monospace styling.
- **`listItem.checked`** is `null` for an ordinary list item, but `true` or `false` for GFM task list items (`- [x]` / `- [ ]`) — this is exactly the field our preview's checkboxes in Part 2B were built from, and it's what our future PDF/DOCX/PPTX renderers will inspect to decide whether to draw a checked or unchecked box glyph.
- **`table.align`** is an array like `["left", "center", null]` — one entry per column, describing the `:---:`-style alignment syntax GFM tables support. Every renderer that draws tables (Parts 5–7) will need to read this to align cell content correctly.

### The Verification
No runnable check yet — proceed to Step 3, where we build the module this table informs.

---

## Step 3 — Writing `lib/parseMarkdown.ts`

### The Target
A single, typed, reusable function: `parseMarkdown(markdown: string): Root`, wrapping the `unified` pipeline we first used inline back in Part 1's Server Action.

### The Concept

> **Analogy — Moving From a Handwritten Note to a Standardized Form.** In Part 1, we called `unified().use(remarkParse).use(remarkGfm).parse(markdown)` directly inside `app/actions.ts` — a fine "handwritten note" for a quick proof-of-concept. But we're about to need this exact same operation in at least four more places: the AST Inspector (this Part), the conversion Route Handler (Part 4), and all three format converters (Parts 5–7). Repeating the same three-line `unified()` chain in five different files is how subtle bugs creep in — if we ever needed to add a fifth plugin, we'd have to remember to update it in five places. Instead, we write it once, as a proper typed function, and *every other file just calls `parseMarkdown(text)`.* This is the single-responsibility idea: one file's whole job is "turn a string into a tree," and it does that job correctly for the rest of the app to depend on.

### The Implementation

**`lib/parseMarkdown.ts`**

```typescript
import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkGfm from "remark-gfm";
import type { Root } from "mdast";

// Building the unified processor is a small amount of setup work (attaching
// plugins). We build it ONCE, at module load time, and reuse the same
// `processor` instance for every call to parseMarkdown() below — rather than
// reconstructing the plugin chain from scratch on every single parse.
const processor = unified().use(remarkParse).use(remarkGfm);

/**
 * Parses a raw Markdown string into a typed mdast Root node.
 *
 * This is the ONE place in the entire application where Markdown text is
 * turned into a tree. Every converter (PDF, DOCX, PPTX) and every debugging
 * tool (the AST Inspector, Part 3B) calls this same function, guaranteeing
 * all three exported formats are built from an identical interpretation of
 * the source text.
 *
 * @param markdown - The raw Markdown source text (e.g. from the editor's
 *                   textarea, or an uploaded .md file).
 * @returns A typed mdast Root node — the top of the parsed tree.
 * @throws Will throw if `markdown` is not a string, or if remark's parser
 *         itself throws on catastrophically malformed input (rare, since
 *         Markdown parsers are designed to be extremely permissive).
 */
export function parseMarkdown(markdown: string): Root {
  if (typeof markdown !== "string") {
    // Defensive guard: this function is a boundary between "untrusted input
    // from a form/file/request" and "typed internal data." Failing loudly
    // and immediately here is much easier to debug than letting a
    // non-string value silently corrupt a converter three files away.
    throw new Error(
      `parseMarkdown() expected a string, but received: ${typeof markdown}`
    );
  }

  // `processor.parse()` runs SYNCHRONOUSLY and only performs the parsing
  // stage — it does not run any "transformer" plugins that might otherwise
  // be attached via `.use()` for other purposes (like rehype/HTML output).
  // Since remark-parse and remark-gfm are both parser-stage plugins, this
  // is exactly the operation we want: text in, tree out, nothing else.
  const ast = processor.parse(markdown);

  return ast;
}
```

A few details worth pausing on:

- **`import type { Root } from "mdast"`** uses the `@types/mdast` package we installed back in Part 1B. `Root` is the TypeScript type describing exactly the `{ type: "root", children: [...] }` shape from Step 1 — this is what lets your editor autocomplete `ast.children[0].type` and catch typos before you ever run the code.
- **The module-level `processor` constant** (built once, outside the function) versus rebuilding it inside `parseMarkdown` on every call is a small but real performance and correctness habit: constructing a `unified()` pipeline involves registering plugins, which is unnecessary repeated work if done on every single parse call. Building it once at module load time and reusing it is the standard `unified` usage pattern.
- **The explicit `typeof markdown !== "string"` check** looks redundant in a TypeScript file (TypeScript's compiler would normally stop you from passing a non-string at compile time). But remember from Part 1C: this function will eventually receive data that originated from `FormData.get()`, which returns `FormDataEntryValue | null` — a type TypeScript *cannot* fully guarantee is a string at compile time when it crosses that browser-to-server boundary, or when data arrives from an uploaded file, a fetch request body, or any other external source in later parts. TypeScript's type system only protects code *within* the type system — the instant data crosses a boundary like a network request or file upload, all bets are off until you re-verify it yourself. This runtime check is that re-verification, and it's a professional habit worth keeping at every such boundary throughout this series, not just here.

### The Verification

Run the TypeScript compiler check:

```bash
npx tsc --noEmit
```

Expected output: nothing (no type errors). If you see an error referencing `Root` or `mdast`, confirm `@types/mdast` is still installed (`ls node_modules/@types/mdast` from Part 1B's verification).

Next, let's actually exercise this function with real input, without yet building a UI for it (that's Part 3B). We'll do this by temporarily and safely reusing our existing Server Action from Part 1 to call the new function instead of its old inline `unified()` chain — proving `parseMarkdown` produces identical results to what we already verified works.

Update **`app/actions.ts`** to use our new module:

```typescript
"use server";

import { parseMarkdown } from "@/lib/parseMarkdown";

/**
 * Parses raw Markdown text into an mdast Abstract Syntax Tree and logs it.
 *
 * Updated in Part 3 to delegate to the shared lib/parseMarkdown.ts module
 * instead of calling unified() directly — every other converter and tool
 * in this app now goes through that same single function.
 */
export async function parseMarkdownAction(formData: FormData): Promise<void> {
  const markdown = formData.get("markdown");

  if (typeof markdown !== "string" || markdown.trim().length === 0) {
    console.error(
      "[parseMarkdownAction] Rejected: no non-empty 'markdown' field was submitted."
    );
    return;
  }

  const ast = parseMarkdown(markdown);

  console.log("\n===== Parsed Markdown AST (via lib/parseMarkdown.ts) =====");
  console.log(JSON.stringify(ast, null, 2));
  console.log("============================================================\n");
}
```

Since Part 2 replaced our old `<form>` UI with the `Editor` component, we don't currently have a page wired up to call `parseMarkdownAction` anymore — that's expected and fine. This step's goal is purely to prove `lib/parseMarkdown.ts` compiles correctly and is a drop-in replacement for our Part 1 logic. We'll give it a proper, permanent home in the UI in the very next installment (3B), via the AST Inspector tool, which is a far more useful place to trigger parsing than a disconnected form.

Run:

```bash
npx tsc --noEmit
```

Expected output: still nothing (no errors) — confirming `app/actions.ts` correctly imports and calls `parseMarkdown` from our new module with matching types throughout.

---

## ✅ Part 3A — Complete

# Part 3B: Building the AST Inspector

## What This Installment Covers
A dedicated debug page where you paste Markdown and see the exact parsed tree rendered as a readable, collapsible view in the browser — reusing `parseMarkdown()` from 3A. This tool becomes essential starting in Part 5, any time a renderer produces unexpected output and you need to check "what does the tree actually look like here?"

---

## Step 4 — Exposing `parseMarkdown` to the Browser via a Server Action

### The Target
A small, dedicated Server Action — `app/inspector/actions.ts` — that accepts Markdown text and returns the parsed AST as data, instead of just logging it.

### The Concept

> **Analogy — A Lab Sample vs. a Lab Report.** Part 1's `parseMarkdownAction` was like a lab technician who runs a test and just shouts the result out loud in the hallway (a `console.log` only you, standing at the server terminal, can hear). What we need now is a technician who **writes the result on a report and hands it back to whoever ordered the test** — so the *browser* can receive the tree and display it, not just the terminal.

Server Actions can return values, not just perform side effects — recall from Part 1C ours returned `Promise<void>`. This time, we return the parsed tree itself, so the calling Client Component can put it in state and render it.

We're placing this in `app/inspector/actions.ts` (not reusing `app/actions.ts`) because it's a distinct concern: `app/actions.ts` was our original Part 1 proof-of-concept, whereas this new file is specifically dedicated to the Inspector tool's route. Keeping route-specific server logic colocated with the route that uses it is a clean, scalable convention we'll repeat later for `app/api/convert/`.

### The Implementation

**`app/inspector/actions.ts`**

```typescript
"use server";

import { parseMarkdown } from "@/lib/parseMarkdown";
import type { Root } from "mdast";

/**
 * Parses Markdown text and returns the resulting AST directly to the caller,
 * instead of just logging it. Used exclusively by the AST Inspector page.
 *
 * @param markdown - Raw Markdown source text from the inspector's textarea.
 * @returns The parsed mdast Root node, or an error message if parsing failed
 *          or input was invalid.
 */
export async function inspectMarkdownAction(
  markdown: string
): Promise<{ ast: Root | null; error: string | null }> {
  if (typeof markdown !== "string") {
    return { ast: null, error: "Input must be a string." };
  }

  if (markdown.trim().length === 0) {
    return { ast: null, error: "Please enter some Markdown to parse." };
  }

  try {
    const ast = parseMarkdown(markdown);
    return { ast, error: null };
  } catch (err) {
    // Defensive: even though remark's parser is very permissive and rarely
    // throws, we never want an unexpected server-side exception to surface
    // as an opaque 500 error in the browser. We catch it here and return a
    // clean, readable message instead.
    const message = err instanceof Error ? err.message : "Unknown parsing error.";
    return { ast: null, error: `Failed to parse Markdown: ${message}` };
  }
}
```

Notice this Server Action takes a plain `string` argument directly, rather than a `FormData` object like Part 1C's did. Server Actions support both calling conventions — passing `FormData` (useful when wired to a `<form action={...}>`) or passing plain, ordinary arguments (useful when called manually from a button's `onClick`, which is exactly what we'll do in Step 6). We'll use the plain-argument style here since the Inspector doesn't need an actual HTML `<form>` element — just a textarea and a button, with JavaScript calling the action directly.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output. This confirms the function's return type (`Promise<{ ast: Root | null; error: string | null }>`) is valid and correctly typed against the `Root` type from `@types/mdast`.

---

## Step 5 — A Tiny, Recursive Tree-Rendering Component

### The Target
`components/AstTreeView.tsx` — a component that takes any `mdast` node and displays it as an indented, collapsible tree, recursively rendering its children.

### The Concept

> **Analogy — Russian Nesting Dolls, Each Doll Able to Open Its Own Children.** A tree is naturally recursive: a `root` node contains children, some of which (like `heading` or `list`) also contain their own children, which might *themselves* contain children (a `listItem` containing a `paragraph` containing a `strong`). Rather than writing separate code for "render a root," "render a heading," "render a list," etc., we write **one component that renders one node**, and have it call *itself* for each of that node's children. This single pattern — a component recursively rendering itself — is the exact same shape our real PDF/DOCX/PPTX renderers will use in Parts 5–7, just producing visual debug output here instead of a file.

We use HTML's native `
  );
}
```

A few details worth pausing on:

- **`interface GenericNode extends Node`** — `Node` is the base type from the `unist` package (the even-more-generic "universal syntax tree" spec that `mdast` itself is built on top of; `unified` installs it automatically as a dependency, so no separate install step is needed here). We extend it with the *optional* fields we personally care about displaying (`depth`, `ordered`, `checked`, `lang`, `url`, `value`), each marked with `?` since not every node type has every field.
- **`<details open>`** — starting every node expanded by default means you see the *entire* tree at a glance the first time you parse something; you then collapse the branches you don't care about, rather than starting fully collapsed and having to hunt.
- **The unique `key` prop** (`${keyPrefix}-${index}-${child.type}`) matters because React requires stable, unique keys for list items to correctly track them across re-renders — using just `index` alone can cause subtle rendering bugs if the tree's shape changes between renders (e.g., switching between two different parsed documents).

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output. This confirms `GenericNode`'s shape is compatible with the real `Root`/node types we'll pass into it from `lib/parseMarkdown.ts` in the next step.

---

## Step 6 — The Inspector Page

### The Target
`app/inspector/page.tsx` — a Client Component page with a textarea, a "Parse" button, and the `AstTreeView` rendering the result live.

### The Concept

> **Analogy — An X-Ray Machine.** The main editor (Part 2) shows you the "skin" of your document — how it looks. The Inspector is an X-ray machine: point it at the same Markdown, and instead of pretty formatting, you see the literal skeletal structure underneath — every bone (node), exactly as `parseMarkdown()` produced it. You'll come back to this exact page in Parts 5–7 any time a converter's output looks subtly wrong, to check whether the *tree* itself matches your expectation before assuming the bug is in your renderer code.

We give the Inspector its own route (`/inspector`, via the `app/inspector/` folder — this is Next.js's file-based routing: any folder inside `app/` with a `page.tsx` becomes a real, navigable URL) rather than cramming it into the homepage, keeping the main editor experience clean for end users while still giving us, the developers, a dedicated diagnostic tool.

### The Implementation

**`app/inspector/page.tsx`**

```tsx
"use client";

import { useState, type ChangeEvent } from "react";
import type { Root } from "mdast";
import { inspectMarkdownAction } from "./actions";
import AstTreeView from "@/components/AstTreeView";

const SAMPLE = `# Sample Document

This is **bold**, this is *italic*, and this is \`inline code\`.

## A List

- First item
- Second item with **nested bold**
  - A nested item

## A Table

| Col A | Col B |
| --- | --- |
| 1 | 2 |

> A blockquote for good measure.
`;

export default function InspectorPage() {
  const [markdown, setMarkdown] = useState<string>(SAMPLE);
  const [ast, setAst] = useState<Root | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);

  function handleChange(event: ChangeEvent<HTMLTextAreaElement>) {
    setMarkdown(event.target.value);
  }

  // Unlike the editor's live preview (Part 2), we do NOT re-parse on every
  // keystroke here. Inspecting a tree is a deliberate, occasional debugging
  // action, not something that needs to feel instantaneous like typing —
  // so a button click, calling the Server Action manually, is the right fit.
  async function handleParseClick() {
    setIsLoading(true);
    setError(null);

    const result = await inspectMarkdownAction(markdown);

    if (result.error) {
      setError(result.error);
      setAst(null);
    } else {
      setAst(result.ast);
    }

    setIsLoading(false);
  }

  return (
    <main className="mx-auto max-w-5xl px-6 py-16">
      <h1 className="text-2xl font-semibold text-gray-900">AST Inspector</h1>
      <p className="mt-2 text-sm text-gray-600">
        Paste Markdown, click Parse, and inspect the exact tree structure
        produced by <code className="rounded bg-gray-100 px-1">lib/parseMarkdown.ts</code>.
        Keep this page bookmarked — you&apos;ll use it constantly in later parts
        whenever a converter&apos;s output looks wrong.
      </p>

      <div className="mt-8 grid grid-cols-1 gap-6 md:grid-cols-2">
        <div>
          <label
            htmlFor="inspector-input"
            className="mb-2 block text-sm font-medium text-gray-700"
          >
            Markdown Source
          </label>
          <textarea
            id="inspector-input"
            rows={18}
            value={markdown}
            onChange={handleChange}
            className="w-full rounded-md border border-gray-300 p-3 font-mono text-sm text-gray-900 shadow-sm focus:border-gray-500 focus:outline-none"
          />

          <button
            type="button"
            onClick={handleParseClick}
            disabled={isLoading}
            className="mt-3 rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-700 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isLoading ? "Parsing…" : "Parse"}
          </button>

          {error && (
            <p className="mt-3 rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">
              {error}
            </p>
          )}
        </div>

        <div>
          <span className="mb-2 block text-sm font-medium text-gray-700">
            Parsed AST
          </span>
          <div className="h-[calc(100%-1.75rem)] w-full overflow-auto rounded-md border border-gray-300 bg-white p-3">
            {ast ? (
              <AstTreeView node={ast} />
            ) : (
              <p className="p-2 text-sm text-gray-400">
                Click &quot;Parse&quot; to see the tree here.
              </p>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
```

A few details worth pausing on:

- **`await inspectMarkdownAction(markdown)`** — this is calling our Server Action directly as a plain async function, from inside an `onClick` handler, rather than via a `<form action={...}>` as we did in Part 1. Both styles are valid uses of Server Actions; this style is a better fit here because we want to control exactly *when* parsing happens (a deliberate button click) and handle the returned `{ ast, error }` data ourselves in local state, rather than relying on form submission semantics.
- **`disabled={isLoading}`** on the button, paired with the `isLoading` state, prevents a user from firing off multiple overlapping parse requests by clicking rapidly — a small but genuine piece of defensive UI polish.
- **Error rendering** — if `inspectMarkdownAction` returns an error (e.g., empty input), we show it in a clearly styled red banner rather than silently failing or throwing an uncaught exception. This mirrors the `{ ast, error }` result-object pattern we defined back in Step 4, and previews the more thorough error-handling philosophy Part 8 will formalize app-wide.

### The Verification

Start (or restart) the dev server:

```bash
npm run dev
```

Navigate directly to **http://localhost:3000/inspector** (note: this is a *new page*, separate from the homepage editor — Next.js automatically created this route the moment we added `app/inspector/page.tsx`).

You should see:
- A heading: **AST Inspector**
- A textarea pre-filled with the sample document (headings, bold, a nested list, a table, a blockquote)
- A **Parse** button

Click **Parse**. Within a moment, the right pane should populate with a collapsible tree, starting with `root (N children)`, expandable down through `heading depth=1`, `paragraph`, `strong`, `list ordered=false`, `listItem`, `table`, `tableRow`, `tableCell`, `blockquote`, etc. — matching exactly the reference table from Step 2 in installment 3A.

Try these specific checks to confirm correctness:

1. **Expand the nested list.** Find the `listItem` containing "Second item with **nested bold**" and confirm you can drill down into a `strong` node showing `value="nested bold"` — proving deeply nested structures render correctly, not just top-level ones.
2. **Check the table's alignment data.** Expand `table` and confirm you see `tableRow` → `tableCell` nodes nested correctly, three levels deep.
3. **Test the error path.** Delete all the text from the textarea and click **Parse** again. You should see the red error banner: *"Please enter some Markdown to parse."* — confirming Step 4's validation logic surfaces correctly all the way to the browser.
4. **Test with your own content.** Paste in something novel, e.g. an image: `![alt text](https://example.com/photo.png)`, click Parse, and confirm an `image` leaf node appears with `url="https://example.com/photo.png"` and `alt="alt text"` shown directly in its summary line — exactly matching the reference table's `image` row from 3A.

---

## ✅ Part 3 — Complete

Checking this against the Part 0 roadmap promise for Part 3 — **"`parseMarkdown(text)` returns a typed, predictable AST; devs can visualize it"** — you now have both halves fully working:

- **3A:** `lib/parseMarkdown.ts` — the single, typed, defensively-guarded function every future converter and tool in this app will call.
- **3B:** A dedicated `/inspector` route with a recursive `AstTreeView` component, letting you visually explore any Markdown document's exact parsed structure, with real error handling for invalid input.

This Inspector isn't a throwaway learning exercise — it's a permanent, load-bearing tool in this project. Starting in Part 5, whenever a PDF renders a list with the wrong indentation, or a DOCX table looks malformed, your very first debugging step will be: *paste the same Markdown into `/inspector` and confirm the tree looks the way you expect* — isolating whether the bug is in parsing (unlikely, since remark is battle-tested) or in your renderer's node-handling logic (much more likely).
