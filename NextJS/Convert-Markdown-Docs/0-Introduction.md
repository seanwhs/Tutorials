# GreyMatter MConvert — Tutorial Series

## Part 0: Introduction — What We're Building, and Why It's Built This Way

---

### A Note Before We Start

Before we write a single line of code, we need to build something more important: a **mental model**. Every engineer who has ever debugged a confusing codebase at 2 AM knows this truth — code without a mental model is just memorization. Code *with* a mental model is understanding you can extend forever.

This Part 0 has zero application code in it. That's intentional. Think of it like the instruction manual page that shows you a picture of the fully-assembled bookshelf before you open the bag of screws. You need to know what you're building and why the pieces are shaped the way they are, *before* the pieces start showing up in your hands.

By the end of this Part 0, you will know:

1. What GreyMatter MConvert actually does, from a user's point of view.
2. The one core architectural idea that makes the entire 10-part series possible (and why the "naive" approach fails).
3. Every tool in the stack, and — in plain English — the single job each one does.
4. The full roadmap of the series, so you always know where you are and where you're headed.
5. Exactly what to install on your machine before Part 1 begins.

---

## 1. What Are We Building?

**GreyMatter MConvert** is a web application with one job: you paste or upload **Markdown** — the lightweight, plain-text formatting language you've seen in GitHub READMEs (`# Heading`, `**bold**`, `- list item`) — and the app lets you:

- **Preview it live**, rendered as nicely formatted text, side-by-side with the raw text you're typing.
- **Export it** as a real, professional-quality:
  - **PDF** (for printing, sharing, archiving)
  - **DOCX** (a real Microsoft Word file, editable in Word or Google Docs)
  - **PPTX** (a real PowerPoint slide deck, with each major heading becoming its own slide)

Picture a user writing meeting notes in Markdown because it's fast to type, then clicking one button to hand their boss a polished Word document, and another button to instantly get a slide deck for the stand-up presentation — all from the *same source text*. That's the product.

> **Analogy — The Universal Translator.** Imagine you write a letter once, in English, and then hand it to three different translators: one produces a French version, one a spoken audio recording, one a sign-language video. Each translator is highly specialized and doesn't know or care how the *other* translators work. But all three start from the exact same original English letter. That original letter is the concept we build in this series: **the AST**.

---

## 2. The Core Insight (Read This Twice)

Here is the single most important idea in this entire series. Everything we build for the next nine parts is in service of this one idea.

### The Naive (Bad) Approach

A beginner's instinct is often: "I need to convert Markdown to PDF, so I'll find a `markdown-to-pdf` library. Then for DOCX, I'll find a `markdown-to-docx` library. Then for PPTX, a `markdown-to-pptx` library."

This feels reasonable, but it's a trap. Each of those three hypothetical libraries would have to *independently* solve the hard problem — "what does `**bold text**` even mean, structurally?" — and each would likely interpret edge cases (nested lists, tables inside blockquotes, images with titles) slightly differently. You'd be maintaining three inconsistent black boxes. Fixing a bug in how nested lists render in your PDF would teach you nothing about fixing the same bug in your PPTX.

### The Approach This Series Teaches

Instead, we split the problem into two completely independent stages:

```
┌─────────────────┐        ┌───────────────────────┐        ┌──────────────────────────────┐
│   Markdown Text   │  ──▶   │   Parse into an AST    │  ──▶   │   Walk the AST 3 separate     │
│  (what the user   │        │  (Abstract Syntax Tree) │        │   times, once per renderer:   │
│   typed/pasted)   │        │  "structured LEGO       │        │                               │
│                   │        │   instructions, not      │        │   ├─▶ PDF Renderer  ─▶ .pdf   │
│  "# Hello\n\n     │        │   a flat wall of text"   │        │   ├─▶ DOCX Renderer ─▶ .docx  │
│   **world**"      │        │                         │        │   └─▶ PPTX Renderer ─▶ .pptx  │
└─────────────────┘        └───────────────────────┘        └──────────────────────────────┘
        Stage 0                    Stage 1 (ONE TIME)              Stage 2 (THREE TIMES)
```

**Stage 1 happens exactly once**, no matter how many output formats we support. A **parser** (a program that reads text and figures out its grammatical structure) reads the raw Markdown string and produces a **tree** — a nested data structure — that says, in precise, unambiguous terms: *"This document has one heading node of depth 1 containing the text 'Hello', followed by one paragraph node containing one 'strong' (bold) node containing the text 'world'."*

This tree is called an **AST — Abstract Syntax Tree**. Don't let the fancy name intimidate you:

> **Analogy — The AST is a LEGO instruction booklet, not a photo of the finished model.** A photo of a finished LEGO castle tells you what it *looks like*, but not how it's built piece by piece. An instruction booklet, on the other hand, precisely lists: "1 red 2x4 brick on top of 1 blue 4x4 brick," etc. Three different people could take that *same* instruction booklet and build the castle out of Lego bricks, out of wooden blocks, or out of Minecraft voxels — because the booklet describes *structure*, not a specific material. Our Markdown AST is that instruction booklet. The PDF renderer builds it "out of PDF bricks," the DOCX renderer builds the identical structure "out of Word bricks," and the PPTX renderer builds it "out of PowerPoint bricks."

**Stage 2 happens three times**, but each time it's solving the *exact same kind* of problem: "given this tree, walk through it node by node, and for each node type (heading, paragraph, list, image, etc.), produce the equivalent chunk in my target format." Once you understand how to walk a tree once (Part 5, for PDF), Parts 6 and 7 (DOCX and PPTX) will feel like variations on a theme you already know — not new mountains to climb.

This is why the series is structured the way it is: **Part 3 teaches you the AST deeply, one time, in isolation** — before any rendering logic exists — so that Parts 5, 6, and 7 are just "apply the thing you already learned, three times, to three different libraries."

---

## 3. Meet the Toolbox 

| Tool | Plain-English Job | Analogy | Deep dive |
|---|---|---|---|
| **Next.js 16** | The overall web app framework: routing, server code, client code, the dev server. | The building itself — floors, wiring, plumbing — that everything else gets installed into. | Appendix A |
| **React 19** | Builds the interactive UI (buttons, text areas, live previews) and manages what happens while we wait for slow things (like generating a PDF) to finish. | The building's smart light switches and elevators — things that react to what you do. | Appendix B |
| **TypeScript** | Adds a strict "type checker" on top of JavaScript so mistakes (like passing a number where text is expected) are caught while you type, not when a user's download crashes. | Spell-check for the *shape* of your data, not just the words. | — (woven throughout) |
| **Tailwind CSS** | Lets us style the app (colors, spacing, layout) using short utility class names directly in the markup, without writing separate CSS files. | Pre-cut adhesive labels instead of hand-painting every sign. | Appendix H |
| **`unified` + `remark-parse` + `remark-gfm`** | The Stage 1 parser described above. `unified` is the plugin engine; `remark-parse` teaches it to read Markdown; `remark-gfm` adds GitHub-flavored extras (tables, strikethrough, task lists). | The instruction-booklet printer. | Appendix C |
| **`react-markdown`** | Renders the AST as live-preview HTML **in the browser**, safely (it never injects raw HTML strings, which prevents an entire category of security bugs called XSS). This is what powers the "preview" pane — it is *not* used for the actual PDF/DOCX/PPTX exports. | A shop window display — shows you what's inside, but isn't the actual product you take home. | Appendix D |
| **`@react-pdf/renderer`** | Builds real `.pdf` files by describing pages using React-like components (`<View>`, `<Text>`, `<Image>`) instead of drawing pixel-by-pixel. | A word processor that only ever outputs PDF, controlled entirely by code instead of a mouse. | Appendix E |
| **`docx`** | Builds real `.docx` (Word) files in Node.js by describing paragraphs, headings, and tables as JavaScript objects. | A robot secretary that types a perfectly formatted Word document from a list of instructions you give it. | Appendix F |
| **`pptxgenjs`** | Builds real `.pptx` (PowerPoint) files, slide by slide, positioning text/images/tables by coordinates. | A robot slide-deck designer that places each element on a slide using an x/y ruler. | Appendix G |
| **Vitest / Playwright** | Automated tests: Vitest checks small pieces of logic (like "does my AST walker correctly convert a heading node?"); Playwright checks the *whole app* by literally clicking buttons in a real browser. | Vitest is a mechanic checking one engine part on a bench; Playwright is a test driver taking the whole car around the block. | Appendix I |

Notice the pattern: **three separate, unrelated libraries** (`@react-pdf/renderer`, `docx`, `pptxgenjs`) each know nothing about Markdown. None of them can read a `.md` file. What they *do* know how to do is build a document from **structured JavaScript objects/components**. Our job, across Parts 5–7, is to write the "translator" code that turns one shared AST into the specific structured objects each library expects. That translator code is what we call a **renderer** or **converter** throughout this series.

---

## 4. The Full Roadmap

Here is the complete journey. Each part produces a working, runnable increment — you will never be left with code that doesn't run.

| Part | What You'll Build | You'll Be Able To... |
|---|---|---|
| **0** (this part) | Nothing but understanding | Explain the AST-centric architecture to someone else |
| **1** | Project scaffold + a "Parse" button | Type Markdown, click a button, see a raw AST printed in the console |
| **2** | Two-pane live editor | Type Markdown on the left, see a formatted preview on the right, instantly |
| **3** | `lib/parseMarkdown.ts` + AST Inspector tool | Understand every `mdast` node type by inspecting real trees visually |
| **4** | Route Handler + Server Action plumbing | Click "Export as PDF/DOCX/PPTX" and download a *stub* file (proves the wiring works) |
| **5** | `lib/converters/toPdf.tsx` | Download a real, correctly formatted **PDF** |
| **6** | `lib/converters/toDocx.ts` | Download a real, correctly formatted **DOCX** |
| **7** | `lib/converters/toPptx.ts` | Download a real, correctly formatted **PPTX** slide deck |
| **8** | Error handling, validation, tests | Trust the app not to crash on bad input, and have a test suite proving it |
| **9** | Deployment config | Have a live URL you can share with anyone |
| **10** | Recap + extension ideas | Know exactly how to keep extending the app on your own |

Plus nine standalone **Appendices** (A–I) that you can read in any order, whenever you want to go deeper than the tutorial pace allows.

---

## 5. Before You Start Part 1 — What To Have Installed

You don't need to run any commands yet — Part 1 will walk you through project creation from scratch. But make sure these are ready on your machine so Part 1 has zero friction:

1. **Node.js version 20.9 or later** (Next.js 16 requires this). Check with:
   ```bash
   node --version
   ```
   If that prints something below `v20.9.0`, install a newer version from [nodejs.org](https://nodejs.org) or via a version manager like `nvm`.

2. **A package manager** — we'll use `npm` (comes bundled with Node) throughout this series for consistency, but `pnpm` or `yarn` work equivalently if you prefer; just substitute commands where relevant.

3. **A code editor** — VS Code is recommended because its TypeScript integration will visibly underline errors as we write type-safe converter code in later parts, which is a genuinely helpful safety net for this project.

4. **A terminal you're comfortable in** — every part includes exact terminal commands to copy-paste.

5. *(Optional but recommended)* **Git**, so you can commit your progress after each part and always roll back if something breaks:
   ```bash
   git --version
   ```

That's it. No accounts, no API keys, no external services — this entire application runs 100% locally, and later deploys to a standard Node.js host with no special credentials required.

---

## 6. A Word on How to Read This Series

Each part from here on follows the same strict format, so you always know what kind of content you're looking at:

- **The Target** — the exact file or feature we're building right now.
- **The Concept** — a plain-English explanation with an analogy, *before* any code, so you understand *why* before you type *what*.
- **The Implementation** — complete, unabbreviated, copy-pasteable code. No `// ...rest of the code`. If a file has 80 lines, you'll see all 80.
- **The Verification** — a concrete way to prove the step worked: a terminal command, a browser action, a console log you should see. You should never move to the next step uncertain whether the current one worked.

Deep conceptual tangents and full library API tours are deliberately **kept out of the main tutorial flow** and pushed into the Appendices, so the main path stays fast-moving and practical. If you're the type who wants to understand *everything* about how `@react-pdf/renderer` lays out flexbox before touching it, Appendix E will be there waiting when you reach Part 5 — but you can also safely ignore it and come back later.

---

### Ready?

You now know:
- **What** we're building (a Markdown → PDF/DOCX/PPTX converter called GreyMatter MConvert)
- **Why** it's architected around a single shared AST rather than three separate converters
- **Which** tools do which job
- **Where** the series is headed, part by part
- **What** to have installed before we begin

In **Part 1**, we scaffold the actual Next.js 16 project, install our first dependencies, and write just enough code to prove the very first link in the chain: turning typed Markdown into a printed AST in your terminal. No styling, no UI polish — just proof that the pipeline is alive.
