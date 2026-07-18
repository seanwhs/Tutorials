# Part 1: The Hybrid Architecture Blueprint

*(Phase 1 — Core Architecture and High-Performance Rendering)*

## 1.1 Deconstructing Apryse — the pillars of an enterprise document suite

Enterprise document SDKs like Apryse (formerly PDFTron) bundle four separate jobs into one product:

| Pillar | Plain-English job | Analogy |
|---|---|---|
| Rendering Engine | Turn PDF byte-code into pixels on a screen, fast | A projector turning a film reel into a picture on a wall |
| Annotation Engine | Let users draw/type/highlight on top of that picture | A transparent sheet of glass laid over a painting |
| Manipulation Engine | Directly edit the underlying file bytes | An editor cutting and pasting pages of a paper document |
| Conversion Engine | Turn other file types into PDF and back | A translator converting a book from French to English |

Greymatter PDF re-implements all four pillars using open-source libraries, one pillar per Phase:

- Phase 1 (Parts 1-3): Rendering Engine foundations
- Phase 2 (Parts 4-5): Annotation Engine
- Phase 3 (Parts 6-7): Manipulation Engine
- Phase 4 (Parts 8-9): Conversion Engine plus production hardening

## 1.2 Designing the network and execution topology

A topology describes which part of the system runs where, and how those parts talk to each other.

**BROWSER (Client):** React UI (Client Components) for toolbar/buttons; a Web Worker running pdf.js parsing off the main thread; canvas elements, one per PDF page; the Annotation Overlay (SVG + Canvas, built in Part 4).

**SERVER (Node.js runtime):** Server Components render initial page HTML; `proxy.ts` (Node runtime) checks auth and streams PDF bytes; Object Storage (S3-compatible) stores the original PDF files; `pdf-lib` manipulation functions merge/split/stamp; PostgreSQL (via Prisma) stores documents, annotations, and users.

The browser and server talk over three channels: normal HTTP fetches, Next.js Server Actions (functions that look local but execute remotely), and a raw byte stream for PDF delivery through `proxy.ts`.

Three rules fall out of this diagram and every future part obeys them:

1. **Never send a whole PDF's raw bytes to a browser tab in one shot.** It must come through `proxy.ts` (Part 3), which checks permissions and streams it in chunks.
2. **Never parse or render PDF vector graphics on the browser's main thread.** The main thread also handles clicks, scrolling, and typing — blocking it freezes the tab. Part 2 moves this work into a Web Worker (a background thread).
3. **Never do byte-level file surgery (merge/split/stamp) in the browser.** This happens through Server Actions, which execute securely on the server (Part 6).

## 1.3 Why Next.js 16 and React 19.2 fit this topology

Next.js's App Router makes every file a Server Component by default — its code runs only on the server and is never shipped to the browser as JavaScript. Developers must opt in to browser execution by adding the exact string `"use client"` at the top of a file. This default-server, opt-in-client model is a structural safety rail.

React 19.2 ships the React Compiler, an automatic build-time tool that rewrites component code to skip unnecessary re-renders without manually wrapping things in `useMemo` or `useCallback`. We enable it today and lean on it heavily from Part 4 onward.

---

## Step 1: Verify your toolchain

**The Target:** confirm Node.js and npm are ready before scaffolding anything.

**The Concept:** this is like checking your oven works before starting a recipe.

**The Implementation:**

```bash
node -v
npm -v
```

You need Node.js v20.9.0 or later.

**The Verification:** both commands print version numbers without error (Node >= v20.9.0, npm >= 10.x.x).

## Step 2: Scaffold the Next.js 16 project

**The Target:** create the initial `greymatter-pdf` project using the official scaffolding tool.

**The Concept:** `create-next-app` is like ordering a pre-built house foundation instead of pouring concrete by hand.

**The Implementation:**

```bash
npx create-next-app@latest greymatter-pdf
```

Answer prompts: TypeScript **Yes**, ESLint **Yes**, Tailwind **Yes**, `src/` directory **Yes**, App Router **Yes**, Turbopack **Yes**, custom import alias **No**.

**The Verification:**

```bash
cd greymatter-pdf
npm run dev
```

Open http://localhost:3000 — confirm the default Next.js welcome page loads. Stop with Ctrl+C.

## Step 3: Design the folder structure

**The Target:** lay out the `src/` directory so every future part has an obvious home for its files.

**The Concept:** like labeling drawers in a new kitchen before buying ingredients — deciding which drawer holds knives (server-only logic) versus napkins (client-only UI) prevents a messy junk drawer later.

**The Implementation:**

```bash
mkdir -p src/app/viewer/[documentId]
mkdir -p src/components/viewer
mkdir -p src/components/annotations
mkdir -p src/workers
mkdir -p src/lib/pdf
mkdir -p src/lib/storage
mkdir -p src/lib/db
mkdir -p src/server-actions
mkdir -p src/types
```

Each directory's future purpose:
- `src/app/viewer/[documentId]`: the Next.js route that displays a single PDF (Part 2)
- `src/components/viewer`: client-side React components for the PDF canvas (Part 2)
- `src/components/annotations`: the annotation overlay UI (Part 4)
- `src/workers`: our Web Worker source file that runs pdf.js off the main thread (Part 2)
- `src/lib/pdf`: shared PDF helper functions used by both client and server code (Part 2, Part 6)
- `src/lib/storage`: object storage client helpers (Part 3)
- `src/lib/db`: Prisma client setup (Part 5)
- `src/server-actions`: Next.js Server Action functions (Part 5, Part 6, Part 7)
- `src/types`: shared TypeScript types used across the app (all parts)

**The Verification:**

```bash
find src -type d | sort
```

Expected output:

```
src
src/app
src/app/viewer
src/app/viewer/[documentId]
src/components
src/components/annotations
src/components/viewer
src/lib
src/lib/db
src/lib/pdf
src/lib/storage
src/server-actions
src/types
src/workers
```

## Step 4: Enable the React Compiler

**The Target:** turn on the React Compiler inside `next.config.ts`.

**The Concept:** think of the React Compiler as a proofreading editor that automatically tightens up your writing (component code) before it is published (built), removing wasted repetition, so you do not have to manually mark every sentence that should not be re-read.

**The Implementation:** install the compiler plugin as a dev dependency:

```bash
npm install --save-dev babel-plugin-react-compiler
```

Then replace the contents of `next.config.ts` at the project root:

### `greymatter-pdf/next.config.ts`

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // The React Compiler automatically memoizes components and hooks at build
  // time, which is why later parts of this series (especially the
  // annotation canvas in Part 4) do not need manual useMemo/useCallback calls.
  experimental: {
    reactCompiler: true,
  },
  // We will stream large PDF byte payloads through Server Actions in Part 6.
  // Next.js caps the body size of a Server Action request by default (1MB),
  // which is too small for real-world PDF files, so we raise it here now
  // rather than discovering the limit mid-way through Part 6.
  serverActions: {
    bodySizeLimit: "25mb",
  },
};

export default nextConfig;
```

Why we raise `bodySizeLimit` now, in Part 1: it is a global config file we will not revisit often, and setting it up front avoids a confusing "Payload Too Large" error appearing many steps from now, disconnected from its actual cause.

**The Verification:**

```bash
npm run build
```

Expected output: the build completes successfully and prints a route summary table. If you see an error mentioning "reactCompiler", run `npm ls babel-plugin-react-compiler` to confirm it installed correctly.

## Step 5: Environment variables and version control

**The Target:** create a `.env.local` file for secrets, and confirm git ignores it.

**The Concept:** `.env.local` is like a physical key you keep in your own pocket, never handed to anyone else — it holds values (database passwords, storage keys) that must never be committed to a shared code repository, since a repository is like a photocopied binder everyone on the team can read.

**The Implementation:** create the file at the project root:

### `greymatter-pdf/.env.local`

```bash
# This file holds local secrets and must never be committed to git.
# We will populate real values here starting in Part 3 (storage keys)
# and Part 5 (database connection string). It is intentionally minimal
# right now - we are only wiring up the safety mechanism first.
GREYMATTER_ENV=development
```

Verify `.gitignore` already excludes it:

```bash
cat .gitignore | grep env
```

Expected output: `.env*.local`

If missing, append manually:

```bash
echo ".env*.local" >> .gitignore
```

**The Verification:**

```bash
git init
git add .
git status
```

Confirm `.env.local` does **NOT** appear in the list of files staged for commit. Then commit:

```bash
git commit -m "chore: scaffold greymatter-pdf with Next.js 16, React Compiler, and folder structure"
```

---

## Part 1 Summary

By this point you have: a running Next.js 16 + React 19.2 project named `greymatter-pdf`, with the React Compiler enabled, a purposeful `src/` folder layout that anticipates every future Part, a raised Server Action body size limit ready for PDF byte payloads, and a safe `.env.local` pattern with git already ignoring secrets. Part 2 begins filling in `src/workers` and `src/components/viewer` with the actual PDF rendering pipeline.
