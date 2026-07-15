# Part 1A: Scaffolding the Project & Folder Structure

## What This Installment Covers
Just two things: creating the Next.js project correctly, and understanding/creating the folders we'll use for the rest of the series. Nothing else. Small, verifiable, done.

---

## Step 1 — Scaffold the Project

### The Target
A running Next.js 16 project with TypeScript, Tailwind, ESLint, and App Router.

### The Concept
> **Analogy — The Empty Apartment with Utilities Already Connected.** `create-next-app` is a new-construction apartment: plumbing and wiring (build tooling, TypeScript config) already work, so you spend your time arranging furniture (your actual app), not running electrical cable.

### The Implementation

Run this in your terminal:

```bash
npx create-next-app@latest greymatter-mconvert
```

Answer the prompts **exactly** as below — this determines the file layout every later step assumes:

```
✔ Would you like to use TypeScript? … Yes
✔ Which linter would you like to use? › ESLint
✔ Would you like to use Tailwind CSS? … Yes
✔ Would you like your code inside a `src/` directory? … No
✔ Would you like to use App Router? (recommended) … Yes
✔ Would you like to use Turbopack? (recommended) … Yes
✔ Would you like to customize the import alias (`@/*` by default)? … No
```

Then enter the project:

```bash
cd greymatter-mconvert
```

### The Verification

```bash
npm run dev
```

Open **http://localhost:3000** — you should see the default Next.js welcome page. Once confirmed, stop the server with `Ctrl+C`.

---

## Step 2 — Create Our Two Extra Folders

### The Target
Add `lib/` (and `lib/converters/`) and `components/` — folders `create-next-app` doesn't generate, but that our architecture needs.

### The Concept
> **Analogy — Rooms Labeled by Purpose.** `app/` is reserved by Next.js for routing — every folder inside it maps to a URL. Our Markdown-parsing and file-converting logic has nothing to do with routing, so it needs its own room: `lib/`. Mixing business logic into `app/` risks future routing-convention collisions and makes code harder to find.

| Folder | Purpose | First used in |
|---|---|---|
| `lib/` | Framework-agnostic logic: parsing, helpers | Part 1 (this part) |
| `lib/converters/` | One file per output format | Part 5 |
| `components/` | Reusable React UI pieces | Part 2 |

### The Implementation

macOS/Linux/WSL:
```bash
mkdir -p lib/converters components
```

Windows PowerShell:
```powershell
mkdir lib\converters, components
```

### The Verification

```bash
find lib components -type d
```

Expected output:
```
lib
lib/converters
components
```

---

# Part 1B: Installing the Parsing Packages

## What This Installment Covers
Just one thing: adding the four packages our parser needs, and confirming they actually installed. No application code yet — that's 1C.

---

## Step 3 — Install the Parsing Dependencies

### The Target
Add `unified`, `remark-parse`, `remark-gfm`, and `@types/mdast` to `package.json`.

### The Concept

> **Analogy — Buying the Specific Tool Before Starting the Job.** You wouldn't buy a power drill for a job that only needs a screwdriver. Each package below has exactly one narrow job in Stage 1 of our pipeline (Markdown → AST) — nothing related to rendering yet.

| Package | Its One Job |
|---|---|
| `unified` | The **engine** that runs a chain of plugins over content. It doesn't know what Markdown *is* — it just knows how to pass text through a pipeline of plugins attached to it. |
| `remark-parse` | A **plugin** that teaches the engine to read standard Markdown syntax (`#`, `**`, `` ` ``, `-`) and produce a tree. |
| `remark-gfm` | A **plugin** that extends `remark-parse` with GitHub-Flavored-Markdown extras: tables, strikethrough (`~~text~~`), task lists (`- [x]`). Without it, a Markdown table would just parse as plain paragraph text. |
| `@types/mdast` | Not a plugin — a **TypeScript dictionary** describing the exact shape of each node (`heading`, `paragraph`, etc.), so TypeScript catches typos like `node.deph` while you type, not at runtime. |

> Recap: `unified` is the conveyor belt. `remark-parse` and `remark-gfm` are stations bolted onto it. `@types/mdast` is the labeled parts catalog on the wall.

### The Implementation

With the dev server stopped (`Ctrl+C` if running), install the three runtime packages:

```bash
npm install unified remark-parse remark-gfm
```

Then install the type definitions as a dev dependency (`-D`) — needed only while *writing* code, never at runtime:

```bash
npm install -D @types/mdast
```

### The Verification

Open `package.json` and confirm all four now appear (exact version numbers may differ):

```json
{
  "dependencies": {
    "next": "16.0.0",
    "react": "19.0.0",
    "react-dom": "19.0.0",
    "unified": "^11.0.5",
    "remark-parse": "^11.0.0",
    "remark-gfm": "^4.0.0"
  },
  "devDependencies": {
    "@types/mdast": "^4.0.4",
    "typescript": "^5",
    "tailwindcss": "^4"
  }
}
```

Then confirm the files actually landed on disk:

```bash
ls node_modules/unified node_modules/remark-parse node_modules/remark-gfm node_modules/@types/mdast
```

Each command should print that package's folder contents (`package.json`, `index.js`, `lib/`, etc.) with no "No such file or directory" errors. If any error appears, re-run the relevant `npm install` command above before continuing — every later step depends on these packages existing.

---

# Part 1C: Writing the Server Action — `app/actions.ts`

## What This Installment Covers
Just one file: the Server Action that receives Markdown text and parses it into an AST. We verify it compiles cleanly. Wiring it up to a visible UI happens in the next installment (1D).

---

## Step 4 — The Server Action: Where Parsing Actually Happens

### The Target
`app/actions.ts` — a new file containing a single **Server Action**: a function that runs exclusively on the server, callable directly from a form in the browser, with no hand-written API endpoint needed.

### The Concept

> **Analogy — The Drop-Off Counter at a Dry Cleaner.** When you drop off a shirt at a dry cleaner, you don't clean it yourself, and you don't need to know *how* their machines work. You hand over the shirt (data), get a claim ticket, and walk away. Later, you're handed back a clean shirt. A **Server Action** is exactly this counter: your browser "hands over" form data to a function guaranteed to run on the server — never shipped to, or executed in, the browser — and hands back a result.

This matters for two concrete reasons:

1. **Consistency.** Later, our PDF/DOCX/PPTX converters (Parts 5–7) run in Node.js only — they cannot run in a browser at all. If parsing happened in the browser but converting happened on the server, we'd have to re-send the raw Markdown to the server anyway. By parsing on the server from this very first step, our whole pipeline lives in one consistent place from day one.
2. **Trust boundary.** Anything running in the browser can be inspected or tampered with via DevTools. A Server Action's actual logic **never** ships to the browser — only a callable network reference does. This is the same reason you'd never trust a browser to calculate a final checkout price; the server always re-validates.

The magic that turns a plain function into a Server Action is a single string at the top of the file: `"use server"`. Think of it as a locked-door sign telling Next.js's compiler: "everything below this line stays inside the building; only a remote-control switch is handed out to visitors."

### The Implementation

**`app/actions.ts`**

```typescript
// This directive MUST be the very first line of the file (before imports,
// before comments even). It tells Next.js's compiler: "never bundle this
// code for the browser — keep it on the server, and only expose a callable
// network reference to clients."
"use server";

import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkGfm from "remark-gfm";

/**
 * Parses raw Markdown text into an mdast Abstract Syntax Tree and logs it.
 *
 * This is intentionally the SIMPLEST possible version of our pipeline.
 * It accepts a FormData object because it's wired up as a <form action={...}>
 * target in the next installment — React 19 lets Server Actions receive the
 * browser's native FormData directly, with zero manual JSON.stringify/fetch
 * plumbing required.
 */
export async function parseMarkdownAction(formData: FormData): Promise<void> {
  // FormData.get() returns `FormDataEntryValue | null` — it could technically
  // be a File (if someone submitted a file input) or null (if the field is
  // missing). We narrow it to a string explicitly so TypeScript — and we —
  // know exactly what we're working with before passing it to the parser.
  const markdown = formData.get("markdown");

  if (typeof markdown !== "string" || markdown.trim().length === 0) {
    // In Part 8 we'll surface this as a real UI error/toast. For now, a
    // clear server-side log is enough to prove our validation logic runs.
    console.error(
      "[parseMarkdownAction] Rejected: no non-empty 'markdown' field was submitted."
    );
    return;
  }

  // This is Stage 1 from our Part 0 diagram, written as actual code:
  //   unified()          -> create a new, empty processing pipeline
  //   .use(remarkParse)  -> teach the pipeline to understand Markdown syntax
  //   .use(remarkGfm)    -> extend it with GitHub-flavored extras (tables, etc.)
  //   .parse(markdown)   -> actually run the text through the pipeline,
  //                         producing the root mdast tree node ("root")
  const processor = unified().use(remarkParse).use(remarkGfm);
  const ast = processor.parse(markdown);

  // Because this function runs on the SERVER, this console.log appears in
  // the terminal where you ran `npm run dev` — NOT in the browser's DevTools
  // console. This is the single most common point of confusion for
  // newcomers to Server Actions, so we call it out explicitly here and
  // verify it concretely in the next installment.
  console.log("\n===== Parsed Markdown AST =====");
  console.log(JSON.stringify(ast, null, 2));
  console.log("================================\n");
}
```

### The Verification (Type-Safety Check)

We can't fully exercise this function yet — it needs a `<form>` in the browser to call it, which we build in the next installment. But we *can* immediately verify the file is free of TypeScript errors and correctly recognized as a valid Server Action module:

```bash
npx tsc --noEmit
```

Expected output: **nothing at all**. A silent, zero-length response means zero type errors. If you see an error mentioning `FormDataEntryValue` or `unified`, double-check that:
- Part 1B's four packages actually installed (`ls node_modules/unified` etc.)
- `"use server";` is the literal first line of the file, with no blank line or comment above it

---

# Part 1D: Wiring the UI — `app/page.tsx`

## What This Installment Covers
The final piece of Part 1: a minimal page with a `<textarea>` and "Parse" button, wired directly to the Server Action from Part 1C. This is the finish line — by the end of this installment, typing Markdown and clicking a button will print a real AST in your terminal.

---

## Step 5 — Building the Page

### The Target
Replace the default `create-next-app` homepage (`app/page.tsx`) with a minimal page containing a `<textarea>` and a submit button, connected directly to `parseMarkdownAction`.

### The Concept

> **Analogy — The Envelope and the Mailbox Slot.** A `<form>` element is like an envelope: it collects everything inside it (our `<textarea>`'s content) and seals it up for delivery. The `action` prop is the mailbox slot it gets dropped into. Normally in plain HTML, that slot is a URL your server has to manually handle — you'd write a route, parse the request body yourself, etc. With a Server Action, React 19 lets us point the `action` prop **directly at a server function reference** — `action={parseMarkdownAction}` — and React generates all the networking plumbing (the request, the encoding, the response handling) for us automatically. No `fetch()`, no hand-written API route, no manual JSON serialization.

Notice something important: `app/page.tsx` as written below stays a **Server Component** (the default in the App Router — no `"use client"` directive needed). We don't need any client-side interactivity yet (no live preview, no loading spinners — those arrive in Parts 2 and 4), so keeping this a Server Component means **zero extra JavaScript is shipped to the browser** for this page. That's a deliberate, minimal first step — we only reach for client-side code when we actually need it.

### The Implementation

**`app/page.tsx`**

```tsx
import { parseMarkdownAction } from "./actions";

export default function HomePage() {
  return (
    <main className="mx-auto max-w-2xl px-6 py-16">
      <h1 className="text-2xl font-semibold text-gray-900">
        GreyMatter MConvert
      </h1>
      <p className="mt-2 text-sm text-gray-600">
        Part 1 checkpoint: type Markdown below, click Parse, and check your{" "}
        <strong>terminal</strong> (not the browser console) for the printed
        AST.
      </p>

      {/*
        The `action` prop pointed at a Server Action is the entire trick
        here. When this form is submitted (Enter key or button click), React:
          1. Serializes this form's fields into a FormData object.
          2. Sends it to the server, invoking parseMarkdownAction(formData).
          3. Never executes parseMarkdownAction's body in the browser at all.
      */}
      <form action={parseMarkdownAction} className="mt-8 space-y-4">
        <textarea
          name="markdown"
          rows={10}
          defaultValue={
            "# Hello GreyMatter\n\nThis is **bold** and this is *italic*.\n\n- First item\n- Second item"
          }
          className="w-full rounded-md border border-gray-300 p-3 font-mono text-sm text-gray-900 shadow-sm focus:border-gray-500 focus:outline-none"
          placeholder="Type or paste Markdown here..."
        />

        <button
          type="submit"
          className="rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-700"
        >
          Parse
        </button>
      </form>
    </main>
  );
}
```

A few deliberate, beginner-relevant notes on this file:

- **`name="markdown"` on the `<textarea>`** is not decorative — it's the exact key our Server Action reads back out with `formData.get("markdown")` in `app/actions.ts`. If these two strings ever mismatch, the action would receive `null` and silently reject the input. This is the single most common bug beginners hit with Server Actions, so keep the names in sync as you extend this later.
- **`defaultValue` instead of `value`** — `value` would make this a *controlled* input, which requires a Client Component with `"use client"` and `useState` to manage it (that's exactly what Part 2 introduces). For now, `defaultValue` just pre-fills the box with sample text without requiring any client-side JavaScript at all.
- **Tailwind classes** (`mx-auto`, `max-w-2xl`, `rounded-md`, etc.) are the "pre-cut adhesive labels" from our Part 0 analogy — short utility names instead of a separate CSS file. You don't need to memorize them; we'll explain the ones that matter as we go, and Appendix H covers the full rationale later in the series.

### The Verification

Start (or restart) your dev server:

```bash
npm run dev
```

Open **http://localhost:3000** in your browser. You should see:

- A heading: **GreyMatter MConvert**
- A textarea pre-filled with sample Markdown (`# Hello GreyMatter`, some bold/italic text, a two-item list)
- A dark **Parse** button below it

Now, **watch the terminal window where `npm run dev` is running** (not the browser DevTools console — this is the exact distinction the code comments called out in Part 1C). Click **Parse**.

You should see output appear in your terminal that looks like this:

```
===== Parsed Markdown AST =====
{
  "type": "root",
  "children": [
    {
      "type": "heading",
      "depth": 1,
      "children": [
        {
          "type": "text",
          "value": "Hello GreyMatter",
          "position": { ... }
        }
      ],
      "position": { ... }
    },
    {
      "type": "paragraph",
      "children": [
        { "type": "text", "value": "This is " },
        {
          "type": "strong",
          "children": [{ "type": "text", "value": "bold" }]
        },
        { "type": "text", "value": " and this is " },
        {
          "type": "emphasis",
          "children": [{ "type": "text", "value": "italic" }]
        },
        { "type": "text", "value": "." }
      ]
    },
    {
      "type": "list",
      "ordered": false,
      "children": [
        {
          "type": "listItem",
          "children": [
            {
              "type": "paragraph",
              "children": [{ "type": "text", "value": "First item" }]
            }
          ]
        },
        {
          "type": "listItem",
          "children": [
            {
              "type": "paragraph",
              "children": [{ "type": "text", "value": "Second item" }]
            }
          ]
        }
      ]
    }
  ],
  "position": { ... }
}
================================
```

Try one more test to prove the pipeline is genuinely reading *your* input, not just always printing the sample text: clear the textarea, type just:

```
## A totally different test
```

Click **Parse** again. Your terminal should now print a much smaller tree, with a single `heading` node whose `"depth": 2` (because `##` is a level-2 heading, versus `#` being level-1) — confirming that live, real input is flowing all the way from the browser, across the network, into server-side code, through the `unified`/`remark-parse`/`remark-gfm` pipeline, and out as a structured tree.

---

## ✅ Part 1 — Complete

Let's confirm what you've actually built, end to end:

- A scaffolded Next.js 16 + TypeScript + Tailwind project, with `lib/`, `lib/converters/`, and `components/` folders reserved for their future purposes.
- Four parsing packages installed and verified on disk.
- `app/actions.ts` — a real Server Action that validates input and runs it through the exact `unified().use(remarkParse).use(remarkGfm).parse()` pipeline described back in Part 0.
- `app/page.tsx` — a Server Component with a form that calls that action with zero hand-written networking code.
- **Concrete proof**, via your own terminal output, that Markdown text you type in a browser is correctly becoming a structured AST on the server.

This is precisely the "Stage 1, happens once" box from our Part 0 architecture diagram — alive and working. Every part from here builds on top of this exact pipe without ever needing to touch it again until Part 3, where we formalize it into a proper reusable `lib/parseMarkdown.ts`.

---

### A Quick Reference Aside (isolated from the tutorial flow, as promised)

**Why did the AST print `position` data everywhere, and can I ignore it?**
Yes — for now, ignore it. `position` tracks the exact line/column in the original source text each node came from (useful for future features like "click here in the preview to jump to that line in the editor"). It clutters the JSON output but has zero effect on parsing correctness. We'll show how to strip it for cleaner debugging in Part 3's AST Inspector tool.

**What if `npx tsc --noEmit` or `npm run dev` shows an error I didn't expect?**
Two most common causes at this stage:
1. Package install didn't fully complete — re-run `npm install unified remark-parse remark-gfm` and `npm install -D @types/mdast` from Part 1B.
2. `"use server";` isn't the literal first line of `app/actions.ts` — even a blank line above it can break this in some setups.
