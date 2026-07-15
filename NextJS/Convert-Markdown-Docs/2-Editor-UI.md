# Part 2A: Converting to a Client Component & Building the Two-Pane Shell

## What This Installment Covers
Before we can render a *live* Markdown preview, we need a page that can hold and react to changing state as the user types. Right now, `app/page.tsx` is a Server Component — it renders once on the server and has no memory of what you type afterward. This installment converts our editing UI into a **Client Component** and builds the empty two-pane skeleton (raw text left, mirrored text right) — proving state flows correctly *before* we add real Markdown rendering in 2B.

---

## Step 1 — Why We Need a Client Component Now

### The Target
Understand the Server vs. Client Component distinction well enough to know exactly why our editor needs `"use client"`, before writing any code.

### The Concept

> **Analogy — A Printed Newsletter vs. a Live Whiteboard.** A Server Component is like a newsletter printed at a print shop: it's assembled once (on the server) and mailed out as a finished page. It's fast and cheap to produce, but it can't change after it's printed — if you scribble on your copy, nobody else's copy updates, and the printer isn't watching. A Client Component is like a whiteboard in a live meeting: every stroke you make is immediately visible, because the whiteboard (running in *your* browser, via JavaScript) is actively watching for changes and redrawing itself in real time.

Our two-pane editor needs the "whiteboard" behavior: the instant you type a character on the left, the right pane must update — with no round trip to the server, no page reload. That kind of instant, in-browser reactivity is exactly what React's `useState` (a way to give a component memory that, when changed, automatically triggers a re-render) provides — and `useState` is **only allowed in Client Components**. Server Components render once and can't hold this kind of live, changing memory.

This is why in Part 1 we were careful to note that `app/page.tsx` stayed a Server Component — it didn't need memory yet. Today it does, so we introduce the `"use client"` directive: the exact mirror-image of Part 1C's `"use server"`. Where `"use server"` said "this code never ships to the browser," `"use client"` says "this code (and everything it imports) *must* ship to the browser, because it needs to run there."

### The Implementation

No code yet for this step — it's purely conceptual grounding. But let's make it concrete with one rule you can always fall back on for the rest of this series:

| Ask yourself... | If yes → | If no → |
|---|---|---|
| "Does this need to remember something that changes while the user interacts (typed text, a toggle, a loading state)?" | **Client Component** (`"use client"`, can use `useState`, `useEffect`, event handlers like `onChange`) | **Server Component** (default, no directive needed, can be `async`, can talk directly to databases/filesystems) |

### The Verification
No runnable check for this step — proceed to Step 2, where this rule gets applied for the first time.

---

## Step 2 — Installing `react-markdown` (Preparing, Not Using It Yet)

### The Target
Add `react-markdown` to our dependencies now, so it's ready for 2B — even though this installment's right pane won't use it yet (we're mirroring raw text first, to isolate "does state flow correctly" from "does rendering work correctly").

### The Concept

> **Analogy — Buying Groceries Before You Start Cooking.** We're installing the ingredient now so that in the very next installment, we can dive straight into using it — without a mid-cookbook trip back to the store.

### The Implementation

```bash
npm install react-markdown
```

Note: we do **not** need to separately install `remark-gfm` again — it's already in our `dependencies` from Part 1B, and `react-markdown` will reuse it directly (we wire this connection explicitly in 2B).

### The Verification

```bash
ls node_modules/react-markdown
```

Expected: the package's folder contents print with no "No such file or directory" error.

Confirm `package.json` now lists it:

```json
{
  "dependencies": {
    "react-markdown": "^9.0.1"
  }
}
```

(Exact version may differ — that's fine.)

---

## Step 3 — Building `components/Editor.tsx`

### The Target
A new Client Component, `components/Editor.tsx`, containing a two-pane layout: a controlled `<textarea>` on the left, and a right pane that — for now — simply mirrors the same raw text back, proving that keystrokes on the left are immediately reflected on the right via React state.

### The Concept

> **Analogy — A Controlled Input is a Thermostat, Not a Thermometer.** An uncontrolled `<textarea>` (what Part 1 used, via `defaultValue`) is like a thermometer: it just reports its own value when asked, but nothing else in the room reacts to it automatically. A **controlled** input ties the textarea's displayed value directly to a piece of React state (`value={text}`) and updates that state on every keystroke (`onChange={...}`). Now the textarea behaves like a thermostat: the moment you change the setting, everything wired to it (in our case, the right-hand preview pane) reacts immediately, because they're both reading from the *same* single source of truth — the `text` state variable.

This "single source of truth" idea is the foundation the live preview in 2B depends on entirely: once `text` state exists and updates correctly, feeding it into a Markdown renderer instead of a plain mirror is a one-line change.

### The Implementation

**`components/Editor.tsx`**

```tsx
"use client";
// This directive is required because this component uses useState, which
// gives it "memory" that changes over time in response to user typing.
// Server Components (the default) render once and cannot hold this kind
// of live, changing state — so anything with useState/onChange must be
// a Client Component.

import { useState, type ChangeEvent } from "react";

export default function Editor() {
  // `text` is our single source of truth: the current raw Markdown string.
  // `setText` is the only function allowed to change it. React re-renders
  // this component automatically whenever setText is called with a new value.
  const [text, setText] = useState<string>(
    "# Hello GreyMatter\n\nThis is **bold** and this is *italic*.\n\n- First item\n- Second item"
  );

  // This handler runs on every single keystroke inside the textarea.
  // `event.target.value` is the textarea's up-to-the-millisecond content.
  function handleChange(event: ChangeEvent<HTMLTextAreaElement>) {
    setText(event.target.value);
  }

  return (
    <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
      {/* LEFT PANE: the raw Markdown source, as a controlled textarea */}
      <div>
        <label
          htmlFor="markdown-input"
          className="mb-2 block text-sm font-medium text-gray-700"
        >
          Markdown Source
        </label>
        <textarea
          id="markdown-input"
          rows={16}
          value={text}
          onChange={handleChange}
          className="w-full rounded-md border border-gray-300 p-3 font-mono text-sm text-gray-900 shadow-sm focus:border-gray-500 focus:outline-none"
          placeholder="Type or paste Markdown here..."
        />
      </div>

      {/*
        RIGHT PANE: for THIS installment only, we mirror the raw text back
        verbatim inside a <pre> tag. This deliberately does NOT render
        Markdown yet — it exists purely to prove that `text` state updates
        are reaching a second, independent part of the UI instantly. In 2B,
        this exact spot gets replaced with a real <ReactMarkdown> renderer.
      */}
      <div>
        <span className="mb-2 block text-sm font-medium text-gray-700">
          Live Mirror (raw text, no rendering yet)
        </span>
        <pre className="h-[calc(100%-1.75rem)] w-full overflow-auto rounded-md border border-gray-300 bg-gray-50 p-3 font-mono text-sm text-gray-900 whitespace-pre-wrap">
          {text}
        </pre>
      </div>
    </div>
  );
}
```

A couple of details worth pausing on:

- **`value={text}` + `onChange={handleChange}`** together are what make this a *controlled* component. If you only set `value` without `onChange`, React would lock the textarea — you'd be unable to type in it at all, because nothing would ever update `text`. This pairing is a rule to memorize: controlled inputs always need both halves.
- **Why a `<pre>` tag for the mirror pane, not a `<div>`?** `<pre>` ("preformatted text") preserves whitespace and line breaks exactly as written, without needing extra CSS. Since we're mirroring raw Markdown text (which relies on blank lines and indentation to mean things), `<pre>` displays it faithfully. A plain `<div>` would collapse all your line breaks into one continuous line, making it look broken even though the state itself is working correctly.
- **`type ChangeEvent<HTMLTextAreaElement>`** is TypeScript telling us exactly what shape the browser's change event has for a `<textarea>` specifically (as opposed to, say, a checkbox, which has a different event shape). This is the "spell-check for the shape of your data" idea from Part 0 — if you accidentally typed `event.target.checked` here (a property that exists on checkboxes, not textareas), TypeScript would immediately underline it as an error, before you ever ran the app.

---

## Step 4 — Using `Editor` from the Page

### The Target
Update `app/page.tsx` to render our new `Editor` component instead of the plain form from Part 1.

### The Concept

> **Analogy — The Page is the Picture Frame, the Editor is the Painting.** `app/page.tsx` stays a simple Server Component whose only job is layout: a title, some instructional text, and a frame to hold the actual interactive content. The `Editor` component is the "painting" — the part that actually moves and changes. Keeping this split matters: it means the heavy, interactive JavaScript is scoped to exactly the component that needs it, not the whole page.

### The Implementation

**`app/page.tsx`**

```tsx
import Editor from "@/components/Editor";

export default function HomePage() {
  return (
    <main className="mx-auto max-w-5xl px-6 py-16">
      <h1 className="text-2xl font-semibold text-gray-900">
        GreyMatter MConvert
      </h1>
      <p className="mt-2 text-sm text-gray-600">
        Part 2 checkpoint: type in the left pane and confirm the right pane
        mirrors your text instantly, with no page reload.
      </p>

      <div className="mt-8">
        <Editor />
      </div>
    </main>
  );
}
```

Notice we're using the `@/components/Editor` import alias here — this is exactly the payoff from the "customize the import alias?" question we accepted the default on back in Part 1A. It resolves to `components/Editor.tsx` from the project root, regardless of how deeply nested `app/page.tsx` itself might become later.

You can now safely delete the `app/actions.ts` form-based UI reliance from Part 1 — note that `app/actions.ts` itself still exists and is untouched; we're just no longer rendering the old plain `<form>` UI on the page. We'll reconnect a real "Parse" trigger to our new editor in Part 3, once we've formalized the parsing logic into its own reusable module.

### The Verification

Start the dev server:

```bash
npm run dev
```

Open **http://localhost:3000**. You should see:

- A page titled **GreyMatter MConvert**
- Two side-by-side panes (stacked vertically on narrow/mobile screens, side-by-side on wider screens — that's what the `md:grid-cols-2` Tailwind class does)
- The left pane pre-filled with the sample Markdown text
- The right pane showing the **exact same raw text**, inside a shaded box

Now, **type something new** in the left pane — for example, add a line: `Testing live state!`

**Expected result:** the right pane updates **instantly**, character by character, with zero page reload, zero network request, zero flicker. Open your browser's Network tab in DevTools while typing to confirm this concretely — you should see **no new requests firing** as you type, proving this update is happening entirely inside the browser via React state, not by talking to the server at all.

If the right pane does *not* update as you type, check:
1. `"use client"` is the literal first line of `components/Editor.tsx`.
2. `value={text}` and `onChange={handleChange}` are both present on the `<textarea>` (missing either one breaks the controlled-component pairing described above).

---

## ✅ Part 2A — Complete

You've now proven the two things this installment set out to prove:

- Your project correctly supports Client Components with live, changing state (`"use client"` + `useState`).
- That state can drive two independent parts of the UI simultaneously and instantly, with the textarea and mirror pane always in sync.

This "single source of truth" pattern — one `text` state variable feeding multiple outputs — is the exact mechanism the real live preview will use in the next installment. The only change coming in 2B is *what* the right pane does with `text`: instead of mirroring it verbatim in a `<pre>` tag, it will hand `text` to `react-markdown` and display fully rendered, formatted output.

---

# Part 2B: The Real Live Preview — Rendering Markdown with `react-markdown`

## What This Installment Covers
We replace the placeholder "mirror" pane from 2A with a genuine, formatted Markdown preview using `react-markdown` and `remark-gfm`. By the end, typing `**bold**` on the left will show actual **bold** text on the right — live, with every keystroke.

---

## Step 5 — Understanding How `react-markdown` Fits In

### The Target
No new files yet — just enough of a mental model to safely wire `react-markdown` into `Editor.tsx` in the next step.

### The Concept

> **Analogy — A Restaurant Menu Translated for a Photo Display.** Recall from Part 0: `react-markdown` is the "shop window display," not the actual product. It takes raw Markdown text, parses it internally (using the very same `unified`/`remark-parse` machinery we used by hand in Part 1!), and directly renders the result as real HTML elements on the page — an `# Heading` becomes an actual `<h1>`, `**bold**` becomes an actual `<strong>`.

Two details matter here, and both are deliberate safety/architecture decisions, not accidents:

1. **It never uses `dangerouslySetInnerHTML`.** A naive Markdown-to-HTML approach might convert Markdown to an HTML *string* and inject it directly into the page. That's dangerous — if a user pastes Markdown containing a hidden `<script>` tag, that script could execute in the browser (a security hole called **XSS — Cross-Site Scripting**). `react-markdown` instead walks the parsed AST and constructs real React elements node by node, so raw HTML strings are never blindly trusted. We cover this in full in Appendix D.
2. **It's browser-only rendering, separate from our future export pipeline.** Nothing this component does will be reused by our PDF/DOCX/PPTX converters in Parts 5–7 — those will walk the *same kind* of AST directly, using completely different rendering libraries. `react-markdown` exists purely to give the user instant visual feedback while typing.

The API surface we need today is small: pass raw Markdown as `children`, and pass `remarkGfm` in a `remarkPlugins` array so tables, strikethrough, and task lists parse correctly (without it, GFM syntax would be ignored, exactly as it would if we forgot `.use(remarkGfm)` in Part 1's Server Action).

### The Verification
No runnable check for this step — it's conceptual grounding for Step 6.

---

## Step 6 — Updating `components/Editor.tsx`

### The Target
Replace the `<pre>` mirror pane with a real `<ReactMarkdown>` renderer, fed by the exact same `text` state we built in 2A.

### The Concept

> **Analogy — Swapping the Speaker, Keeping the Microphone.** In 2A we proved the "microphone" (the `text` state) correctly captures every keystroke and broadcasts it. Now we're just swapping out what's plugged into the *output* — instead of a plain echo speaker (`<pre>{text}</pre>`), we plug in a full audio processor (`<ReactMarkdown>`) that intelligently interprets the signal before playing it back. The wiring in between (`text` state → right pane) doesn't change at all.

### The Implementation

**`components/Editor.tsx`**

```tsx
"use client";
// Still required: useState gives this component the live, changing memory
// (the current Markdown text) that both panes depend on.

import { useState, type ChangeEvent } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

export default function Editor() {
  // Same single source of truth from 2A — untouched.
  const [text, setText] = useState<string>(
    "# Hello GreyMatter\n\n" +
      "This is **bold** and this is *italic*.\n\n" +
      "- First item\n- Second item\n\n" +
      "| Feature   | Supported |\n" +
      "| --------- | --------- |\n" +
      "| Tables    | Yes       |\n" +
      "| Checklists| Yes       |\n\n" +
      "- [x] Try the live preview\n- [ ] Export to PDF (coming in Part 5)"
  );

  function handleChange(event: ChangeEvent<HTMLTextAreaElement>) {
    setText(event.target.value);
  }

  return (
    <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
      {/* LEFT PANE: unchanged from 2A */}
      <div>
        <label
          htmlFor="markdown-input"
          className="mb-2 block text-sm font-medium text-gray-700"
        >
          Markdown Source
        </label>
        <textarea
          id="markdown-input"
          rows={18}
          value={text}
          onChange={handleChange}
          className="w-full rounded-md border border-gray-300 p-3 font-mono text-sm text-gray-900 shadow-sm focus:border-gray-500 focus:outline-none"
          placeholder="Type or paste Markdown here..."
        />
      </div>

      {/*
        RIGHT PANE: now a genuine rendered preview. `remarkPlugins={[remarkGfm]}`
        is the equivalent of Part 1's `.use(remarkGfm)` call — without it,
        the table and checklist syntax above would render as plain, broken
        paragraph text instead of an actual <table> and checkboxes.
      */}
      <div>
        <span className="mb-2 block text-sm font-medium text-gray-700">
          Live Preview
        </span>
        <div className="markdown-preview h-[calc(100%-1.75rem)] w-full overflow-auto rounded-md border border-gray-300 bg-white p-4 text-sm text-gray-900">
          <ReactMarkdown remarkPlugins={[remarkGfm]}>{text}</ReactMarkdown>
        </div>
      </div>
    </div>
  );
}
```

Two things worth calling out:

- **`children={text}` (written here as `{text}` between the tags)** is the *only* required prop — `react-markdown` treats its `children` as the raw Markdown source string to parse and render, unlike normal React components where `children` is usually already-rendered JSX.
- **`className="markdown-preview"`** on the wrapping `<div>` is not a Tailwind utility class — it's a plain CSS hook we're about to define ourselves in the next step, because `react-markdown` outputs bare, unstyled HTML tags (`<h1>`, `<ul>`, `<table>`, etc.) with no visual styling at all by default.

### The Verification (Partial — Do Not Skip Step 7 First)

If you run the dev server right now, the preview *will* technically work — headings, bold, and lists will structurally render as real `<h1>`, `<strong>`, `<ul>` tags. But they'll look almost identical to plain paragraph text, because Tailwind's default styles intentionally strip default browser styling from headings/lists (this is called a "CSS reset," and it's normal, expected behavior — not a bug). We fix the visual styling in Step 7 before doing our full verification.

---

## Step 7 — Styling the Preview Pane

### The Target
Add scoped CSS rules to `app/globals.css` so headings, bold text, lists, tables, and code blocks inside `.markdown-preview` actually look distinct from one another.

### The Concept

> **Analogy — Labeled Shelves in a Pantry.** Right now, every item in our rendered preview (headings, paragraphs, list items) is technically a different, correctly-typed "container" — but they're all sitting on identical, unlabeled shelves, so visually everything blurs together. We're adding labels: make `<h1>` shelves bigger and bolder than `<h2>` shelves, make `<code>` shelves shaded and monospaced, and so on. We scope every rule under a single `.markdown-preview` parent class so these styles **only** affect our rendered preview pane, never any other part of the app.

### The Implementation

**`app/globals.css`** — add the following block to the **end** of the existing file (keep everything already generated by `create-next-app` above it, including the `@import "tailwindcss";` line):

```css
/* ============================================================
   Markdown Preview Styling
   Scoped under .markdown-preview so it NEVER leaks into the rest
   of the app — only components/Editor.tsx's preview pane uses it.
   ============================================================ */

.markdown-preview h1 {
  font-size: 1.75rem;
  font-weight: 700;
  margin-top: 1rem;
  margin-bottom: 0.75rem;
  line-height: 1.2;
}

.markdown-preview h2 {
  font-size: 1.4rem;
  font-weight: 700;
  margin-top: 1rem;
  margin-bottom: 0.6rem;
  line-height: 1.25;
}

.markdown-preview h3 {
  font-size: 1.15rem;
  font-weight: 600;
  margin-top: 0.9rem;
  margin-bottom: 0.5rem;
}

.markdown-preview p {
  margin-bottom: 0.75rem;
  line-height: 1.6;
}

.markdown-preview strong {
  font-weight: 700;
}

.markdown-preview em {
  font-style: italic;
}

.markdown-preview ul {
  list-style-type: disc;
  padding-left: 1.5rem;
  margin-bottom: 0.75rem;
}

.markdown-preview ol {
  list-style-type: decimal;
  padding-left: 1.5rem;
  margin-bottom: 0.75rem;
}

.markdown-preview li {
  margin-bottom: 0.25rem;
}

.markdown-preview code {
  background-color: #f3f4f6;
  padding: 0.15rem 0.35rem;
  border-radius: 0.25rem;
  font-family: ui-monospace, monospace;
  font-size: 0.85em;
}

.markdown-preview pre {
  background-color: #1f2937;
  color: #f9fafb;
  padding: 0.75rem 1rem;
  border-radius: 0.375rem;
  overflow-x: auto;
  margin-bottom: 0.75rem;
}

/* When code sits inside a <pre> block, remove the inline-code background
   so we don't get a double-boxed look (shaded <pre> AND shaded <code>). */
.markdown-preview pre code {
  background-color: transparent;
  padding: 0;
  font-size: 0.85rem;
}

.markdown-preview blockquote {
  border-left: 3px solid #d1d5db;
  padding-left: 1rem;
  color: #4b5563;
  font-style: italic;
  margin-bottom: 0.75rem;
}

.markdown-preview table {
  border-collapse: collapse;
  width: 100%;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}

.markdown-preview th,
.markdown-preview td {
  border: 1px solid #d1d5db;
  padding: 0.4rem 0.6rem;
  text-align: left;
}

.markdown-preview th {
  background-color: #f3f4f6;
  font-weight: 600;
}

.markdown-preview a {
  color: #2563eb;
  text-decoration: underline;
}

.markdown-preview hr {
  border: none;
  border-top: 1px solid #d1d5db;
  margin: 1rem 0;
}

/* GFM task list checkboxes (from `- [x]` / `- [ ]` syntax) render as real
   <input type="checkbox"> elements. We disable interaction with them here
   since this is a read-only preview, not an editable checklist. */
.markdown-preview input[type="checkbox"] {
  margin-right: 0.4rem;
  pointer-events: none;
}
```

A quick note on *why* we chose plain CSS here instead of Tailwind utility classes: `react-markdown` generates its HTML tags dynamically (we never write `<h1 className="...">` ourselves — `react-markdown` does), so there's no JSX line for us to attach a Tailwind class to per-tag. Scoped plain CSS selectors like `.markdown-preview h1` are the correct tool for styling content whose exact markup we don't hand-author ourselves. This is a good example of using the right tool per situation, rather than forcing Tailwind everywhere.

### The Verification

Restart the dev server if it isn't already running:

```bash
npm run dev
```

Open **http://localhost:3000**. The right pane should now show a **fully, visually formatted document**, not raw text:

- "Hello GreyMatter" as a large, bold heading
- "bold" rendered visibly bold, "italic" rendered visibly slanted
- A real bulleted list with "First item" / "Second item"
- A real HTML **table** with a border, header row shaded gray, showing "Feature | Supported"
- Two checkbox items, one checked ("Try the live preview"), one unchecked ("Export to PDF")

Now run the live-update test again: click into the left pane and type a new line, e.g.:

```
### A brand new sub-heading
```

**Expected result:** the right pane instantly shows a new, medium-sized bold heading — smaller than "Hello GreyMatter" (which is `h1`) but larger than normal paragraph text — updating on every keystroke, with no page reload and no network requests (confirm again via DevTools → Network tab if you want to be thorough).

As a final structural check, type a GFM-specific feature to confirm `remark-gfm` is genuinely active (not just `react-markdown`'s default parser):

```
~~strikethrough test~~
```

**Expected result:** the words "strikethrough test" appear with a line through them in the preview. If they instead appear as plain text with literal `~~` characters still visible, `remarkGfm` isn't wired correctly — double check `remarkPlugins={[remarkGfm]}` is present exactly as shown in Step 6's code.

---

## ✅ Part 2B — Complete

You now have a fully working, real-time, two-pane Markdown editor:

- Left pane: a controlled `<textarea>`, the single source of truth.
- Right pane: a true rendered preview via `react-markdown` + `remark-gfm`, safely constructed from real React elements (never raw injected HTML), styled clearly and legibly.
- Confirmed: standard Markdown *and* GitHub-flavored extras (tables, checklists, strikethrough) all render correctly, live, with zero network calls per keystroke.

This is the payoff of the "single source of truth" architecture from 2A — we only had to change what consumes `text`, never how `text` itself is captured.

---
# Part 2C: Templates & Draft Persistence

## What This Installment Covers
The final two features that complete Part 2's end state: a dropdown to load sample documents ("Resume," "Report," "Slide Deck Outline") for instant test content, and automatic saving of whatever the user typed to `localStorage`, so a refresh never loses their work. We'll also introduce `useTransition` here — our first real React 19 feature — to keep large-document preview updates from ever feeling janky.

---

## Step 8 — Defining the Sample Templates

### The Target
A new file, `lib/templates.ts`, holding three ready-made Markdown documents as plain data — kept separate from `Editor.tsx` so the component's logic doesn't get buried under walls of sample text.

### The Concept

> **Analogy — A Restaurant's Pre-Set Combo Meals.** Rather than making every customer build an order item-by-item from scratch, a restaurant offers a few combo meals ("The Classic," "The Deluxe") so people can start eating immediately and customize from there. Our templates are exactly this: instant starting points a user can immediately export or tweak, rather than facing a blank textarea.

We put this data in `lib/`, not `components/`, because it's **not UI** — it's just data (strings). Keeping data separate from the component that displays it means we could reuse these same templates later (e.g., a future "seed a new document" API) without dragging any React code along with them.

### The Implementation

**`lib/templates.ts`**

```typescript
/**
 * Sample Markdown documents used to seed the editor via the "Load Template"
 * dropdown. Kept as plain data (no React/JSX here) so this file can be
 * reused by any future feature — UI, tests, API routes — without pulling
 * in component code it doesn't need.
 */

export type TemplateId = "resume" | "report" | "slides";

export interface Template {
  id: TemplateId;
  label: string;
  content: string;
}

export const templates: Template[] = [
  {
    id: "resume",
    label: "Resume",
    content: `# Jordan Rivera
**Software Engineer** · jordan.rivera@email.com · (555) 012-3456

## Summary

Backend-focused engineer with 6 years of experience building reliable, well-tested APIs and data pipelines.

## Experience

### Senior Engineer — Northwind Systems (2022–Present)

- Led migration of a monolithic billing service into three independently deployable services
- Reduced average API response time by **40%** through query optimization and caching
- Mentored two junior engineers through onboarding and their first production releases

### Software Engineer — Contoso Labs (2019–2022)

- Built an internal reporting dashboard used by 200+ employees daily
- Wrote integration tests that caught *3 critical bugs* before they reached production

## Skills

| Category | Tools |
| --- | --- |
| Languages | TypeScript, Python, Go |
| Infra | Docker, PostgreSQL, AWS |

## Education

- B.S. Computer Science, State University, 2019
`,
  },
  {
    id: "report",
    label: "Report",
    content: `# Q3 Engineering Report

## Overview

This report summarizes engineering output, incidents, and priorities for Q3.

## Key Metrics

| Metric | Q2 | Q3 | Change |
| --- | --- | --- | --- |
| Deploys per week | 12 | 19 | +58% |
| Incident count | 5 | 2 | -60% |
| Avg. PR review time | 14h | 9h | -36% |

## Highlights

1. Completed migration to the new deployment pipeline
2. Reduced incident response time via improved on-call runbooks
3. Shipped the **v2 public API**, now in limited beta

## Risks & Blockers

> The current staging environment is under-provisioned and occasionally causes flaky test failures. Recommend increasing staging resources before Q4.

## Next Quarter Priorities

- [ ] Finish v2 API general availability rollout
- [ ] Reduce median build time below 3 minutes
- [ ] Complete on-call rotation training for 2 new hires
`,
  },
  {
    id: "slides",
    label: "Slide Deck Outline",
    content: `# Product Launch Overview

Welcome slide — presented by the Product team.

## The Problem

- Users currently juggle three disconnected tools
- Switching costs slow teams down by an estimated 5 hours/week
- Existing solutions are expensive and hard to customize

## Our Solution

- One unified workspace
- Real-time collaboration built in
- Priced for teams of any size

## Roadmap

- **Now:** Core editing + sharing
- **Next quarter:** Offline mode
- **Later:** Public API for integrations

## Thank You

Questions? Reach out at team@example.com
`,
  },
];
```

Notice the `## Slide Deck Outline` template uses `##` headings as clear section breaks — that's not accidental. When we build the PPTX converter in Part 7, our "sectionize by heading" strategy will use exactly this pattern (each `##` starts a new slide), so this template doubles as a preview of that later feature.

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output (no type errors). This confirms the `Template[]` array is correctly typed and every object matches the `Template` interface (e.g., you can't accidentally misspell `id` or use a `TemplateId` value outside `"resume" | "report" | "slides"` without TypeScript flagging it).

---

## Step 9 — Wiring the Template Dropdown (with `useTransition`)

### The Target
Update `components/Editor.tsx` to add a `<select>` dropdown that, when changed, loads the chosen template's content into the editor — using React 19's `useTransition` to mark this update as non-urgent.

### The Concept

> **Analogy — Fast Lane vs. Regular Checkout.** Imagine a grocery store where every single item scan — no matter how small — is treated with maximum urgency, potentially blocking the whole line. `useTransition` lets us tell React: "this particular update (swapping in a whole new document, potentially thousands of characters) doesn't need to block the browser from staying responsive — mark it as a background update, and if something more urgent comes in, prioritize that first." For a single keystroke, this is barely noticeable. But swapping in an entire large document (or, later in the series, re-rendering a huge preview) is exactly the kind of "big enough it matters" update `useTransition` is designed for — it keeps typing and UI responsiveness smooth even while a bigger re-render is happening underneath.

Concretely, `useTransition` gives us two things:
1. `startTransition(fn)` — wraps a state update, telling React it's low-priority/interruptible.
2. `isPending` — a boolean, true while that transition is still being applied, letting us show a subtle loading indicator.

### The Implementation

**`components/Editor.tsx`** (full file, replacing the previous version)

```tsx
"use client";

import { useState, useTransition, type ChangeEvent } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { templates, type TemplateId } from "@/lib/templates";

const DEFAULT_CONTENT =
  "# Hello GreyMatter\n\n" +
  "This is **bold** and this is *italic*.\n\n" +
  "- First item\n- Second item\n\n" +
  "| Feature   | Supported |\n" +
  "| --------- | --------- |\n" +
  "| Tables    | Yes       |\n" +
  "| Checklists| Yes       |\n\n" +
  "- [x] Try the live preview\n- [ ] Export to PDF (coming in Part 5)";

export default function Editor() {
  const [text, setText] = useState<string>(DEFAULT_CONTENT);

  // isPending tells us whether a transition-wrapped update is still being
  // processed. startTransition is the function we wrap "big" updates in.
  const [isPending, startTransition] = useTransition();

  function handleChange(event: ChangeEvent<HTMLTextAreaElement>) {
    // Individual keystrokes are cheap and urgent — we do NOT wrap this one
    // in startTransition, so every character feels instantaneous.
    setText(event.target.value);
  }

  function handleTemplateChange(event: ChangeEvent<HTMLSelectElement>) {
    const selectedId = event.target.value as TemplateId | "";
    if (!selectedId) return;

    const template = templates.find((t) => t.id === selectedId);
    if (!template) return;

    // Swapping in an entire template can be a large chunk of text, which
    // means the preview pane has a lot more to parse and render at once
    // than a single keystroke does. Wrapping it in startTransition tells
    // React: "this is allowed to take a moment — don't let it block more
    // urgent things (like the user immediately typing something else)."
    startTransition(() => {
      setText(template.content);
    });
  }

  return (
    <div>
      <div className="mb-4 flex items-center gap-3">
        <label htmlFor="template-select" className="text-sm font-medium text-gray-700">
          Load Template:
        </label>
        <select
          id="template-select"
          defaultValue=""
          onChange={handleTemplateChange}
          className="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-900 focus:border-gray-500 focus:outline-none"
        >
          <option value="" disabled>
            Choose a sample document...
          </option>
          {templates.map((template) => (
            <option key={template.id} value={template.id}>
              {template.label}
            </option>
          ))}
        </select>

        {/* A subtle, honest loading indicator — only visible while the
            transition triggered by picking a template is still resolving. */}
        {isPending && (
          <span className="text-xs text-gray-500">Loading template…</span>
        )}
      </div>

      <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
        <div>
          <label
            htmlFor="markdown-input"
            className="mb-2 block text-sm font-medium text-gray-700"
          >
            Markdown Source
          </label>
          <textarea
            id="markdown-input"
            rows={18}
            value={text}
            onChange={handleChange}
            className="w-full rounded-md border border-gray-300 p-3 font-mono text-sm text-gray-900 shadow-sm focus:border-gray-500 focus:outline-none"
            placeholder="Type or paste Markdown here..."
          />
        </div>

        <div>
          <span className="mb-2 block text-sm font-medium text-gray-700">
            Live Preview
          </span>
          <div className="markdown-preview h-[calc(100%-1.75rem)] w-full overflow-auto rounded-md border border-gray-300 bg-white p-4 text-sm text-gray-900">
            <ReactMarkdown remarkPlugins={[remarkGfm]}>{text}</ReactMarkdown>
          </div>
        </div>
      </div>
    </div>
  );
}
```

### The Verification

Restart the dev server if needed and open **http://localhost:3000**. You should now see a **"Load Template"** dropdown above the two panes.

1. Select **Resume** — both panes should instantly update: the left pane fills with the resume Markdown, and the right pane renders a formatted resume (name as a large heading, a bold job title line, a skills table with borders, bulleted experience lists).
2. Select **Report** — both panes swap to the Q3 report content, including a rendered metrics table and a blockquote (shown with the left border and italic styling from our 2B CSS).
3. Select **Slide Deck Outline** — both panes swap to the slide outline content, with each `##` section clearly visible as its own heading.

While a template is loading, watch closely for the small **"Loading template…"** text next to the dropdown — on most machines this will flash by almost too fast to see (because our sample templates are small), which is actually the *correct*, expected result: `useTransition` is working, it's just that the transition resolves quickly for small documents. To see it more clearly, you can temporarily test with a much larger pasted document (e.g., paste the same template's content 20 times in a row into the textarea) and observe the indicator staying visible slightly longer while the preview catches up — then remove that test content afterward.

As a final check, confirm ordinary typing still feels completely instant (not routed through any transition delay): click into the left textarea after loading a template, and type a new character. It should appear immediately, with no lag and no "Loading template…" flicker — because `handleChange` intentionally does **not** use `startTransition`, exactly as commented in the code.

---

## Step 10 — Persisting Drafts to `localStorage`

### The Target
Update `Editor.tsx` so that whatever the user has typed is automatically saved in the browser and restored automatically the next time they open the page — surviving refreshes and browser restarts.

### The Concept

> **Analogy — A Notepad That Remembers, Even After You Close It.** Right now, our `text` state is like writing on a whiteboard: the moment you close the tab (erase the board), everything is gone. `localStorage` is a small, persistent storage locker built into every browser, tied to your specific website, that survives page reloads and even closing the browser entirely. We're going to write the current draft into that locker every time it changes, and read it back out the locker the moment the page first loads — giving our app "memory" across sessions, with no backend database required at all.

We use React's `useEffect` (a way to run code in response to something changing, *after* React has updated the screen) for two specific jobs here:
1. **Once, when the component first mounts** — check the locker for a previously saved draft and load it in, *instead of* the hardcoded `DEFAULT_CONTENT`, if one exists.
2. **Every time `text` changes afterward** — write the latest value back into the locker.

A subtlety worth flagging honestly, in the spirit of "beginner-friendly, no hand-waving": `localStorage` does not exist during server-side rendering (there is no "browser" on the server). We must only ever touch it inside `useEffect`, which — by design — only ever runs in the browser, after the component has mounted. Reading or writing `localStorage` directly in the component body (outside `useEffect`) would crash the app during server rendering.

### The Implementation

**`components/Editor.tsx`** (full file, replacing the previous version)

```tsx
"use client";

import { useState, useEffect, useTransition, type ChangeEvent } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { templates, type TemplateId } from "@/lib/templates";

const DEFAULT_CONTENT =
  "# Hello GreyMatter\n\n" +
  "This is **bold** and this is *italic*.\n\n" +
  "- First item\n- Second item\n\n" +
  "| Feature   | Supported |\n" +
  "| --------- | --------- |\n" +
  "| Tables    | Yes       |\n" +
  "| Checklists| Yes       |\n\n" +
  "- [x] Try the live preview\n- [ ] Export to PDF (coming in Part 5)";

// A single, unique key identifying our saved draft inside localStorage.
// Namespacing it with the app name avoids accidentally colliding with
// some other unrelated key a browser extension or other script might set.
const DRAFT_STORAGE_KEY = "greymatter-mconvert:draft";

export default function Editor() {
  const [text, setText] = useState<string>(DEFAULT_CONTENT);
  const [isPending, startTransition] = useTransition();

  // --- EFFECT 1: Load a saved draft ONCE, when the component first mounts ---
  useEffect(() => {
    // This code only ever runs in the browser (useEffect never runs during
    // server-side rendering), so `localStorage` is guaranteed to exist here.
    const saved = window.localStorage.getItem(DRAFT_STORAGE_KEY);

    // Only override the default content if we actually found a non-empty
    // saved draft — otherwise a brand-new visitor still sees our friendly
    // sample content instead of a blank editor.
    if (saved && saved.trim().length > 0) {
      setText(saved);
    }

    // The empty dependency array [] means: run this effect exactly once,
    // right after the very first render — never again after that.
  }, []);

  // --- EFFECT 2: Save the draft EVERY TIME `text` changes afterward ---
  useEffect(() => {
    window.localStorage.setItem(DRAFT_STORAGE_KEY, text);

    // Listing `text` as a dependency means: re-run this effect whenever
    // `text` changes. Since setText is called on every keystroke, this
    // effectively autosaves continuously as the user types.
  }, [text]);

  function handleChange(event: ChangeEvent<HTMLTextAreaElement>) {
    setText(event.target.value);
  }

  function handleTemplateChange(event: ChangeEvent<HTMLSelectElement>) {
    const selectedId = event.target.value as TemplateId | "";
    if (!selectedId) return;

    const template = templates.find((t) => t.id === selectedId);
    if (!template) return;

    startTransition(() => {
      setText(template.content);
    });
  }

  return (
    <div>
      <div className="mb-4 flex items-center gap-3">
        <label htmlFor="template-select" className="text-sm font-medium text-gray-700">
          Load Template:
        </label>
        <select
          id="template-select"
          defaultValue=""
          onChange={handleTemplateChange}
          className="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-900 focus:border-gray-500 focus:outline-none"
        >
          <option value="" disabled>
            Choose a sample document...
          </option>
          {templates.map((template) => (
            <option key={template.id} value={template.id}>
              {template.label}
            </option>
          ))}
        </select>

        {isPending && (
          <span className="text-xs text-gray-500">Loading template…</span>
        )}
      </div>

      <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
        <div>
          <label
            htmlFor="markdown-input"
            className="mb-2 block text-sm font-medium text-gray-700"
          >
            Markdown Source
          </label>
          <textarea
            id="markdown-input"
            rows={18}
            value={text}
            onChange={handleChange}
            className="w-full rounded-md border border-gray-300 p-3 font-mono text-sm text-gray-900 shadow-sm focus:border-gray-500 focus:outline-none"
            placeholder="Type or paste Markdown here..."
          />
        </div>

        <div>
          <span className="mb-2 block text-sm font-medium text-gray-700">
            Live Preview
          </span>
          <div className="markdown-preview h-[calc(100%-1.75rem)] w-full overflow-auto rounded-md border border-gray-300 bg-white p-4 text-sm text-gray-900">
            <ReactMarkdown remarkPlugins={[remarkGfm]}>{text}</ReactMarkdown>
          </div>
        </div>
      </div>
    </div>
  );
}
```

### The Verification

Restart the dev server if needed and open **http://localhost:3000**.

1. Clear the left textarea completely and type something distinctive and easy to recognize, e.g.:
   ```
   # Draft persistence test 12345
   ```
2. **Refresh the browser page** (a full reload — F5 or Cmd+R, not just re-clicking in the tab).
3. **Expected result:** the textarea should reload with **"Draft persistence test 12345" still present** — not the original `DEFAULT_CONTENT` sample text. This confirms Effect 1 correctly restored your saved draft on mount.

Now confirm the storage mechanism directly in DevTools:

1. Open DevTools → **Application** tab (Chrome/Edge) or **Storage** tab (Firefox).
2. Navigate to **Local Storage → http://localhost:3000**.
3. You should see a key named `greymatter-mconvert:draft` whose value is exactly the Markdown text currently in your editor.
4. Type one more character into the textarea and watch that value update in DevTools in real time — confirming Effect 2 is saving on every change.

Finally, confirm templates still correctly override your draft: select **Report** from the dropdown, then refresh the page again. The Report content should persist across the refresh too — because loading a template calls `setText`, which triggers Effect 2 to save it, exactly like typing does.

---

## ✅ Part 2 — Complete

Let's confirm the full end state promised back in the Part 0 roadmap: **"Type Markdown on the left, see a formatted preview on the right, instantly"** — plus the extra features from this installment. You now have:

- A controlled, two-pane live editor (2A) — proven to update instantly via a single `text` state source of truth.
- A real, safely-rendered Markdown preview using `react-markdown` + `remark-gfm` (2B), styled clearly via scoped CSS.
- A template dropdown offering three realistic starting documents (2C), using React 19's `useTransition` to keep large-content swaps from blocking the UI.
- Automatic `localStorage` draft persistence (2C) — refreshing the page, or even closing the browser, never loses the user's work.

No export functionality exists yet — that's still ahead of us, deliberately, per the Part 0 roadmap. In **Part 3**, we go back underneath the hood of this same editor and formalize the informal parsing we did by hand in Part 1 into a proper, typed, reusable `lib/parseMarkdown.ts` module — plus build a dedicated **AST Inspector** debugging tool that you'll keep reaching for in every later part when a render looks wrong.
