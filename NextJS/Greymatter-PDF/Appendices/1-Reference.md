Let me pull the saved Part 1 Reference Appendix content in full.
# Part 1 — Reference Appendix

Deep-dive material for Part 1, isolated from the step-by-step tutorial flow. Read this when you want to understand the "why" more deeply; skip it if you just want to keep building toward Part 2.

## A.1 The Next.js App Router: Server Components vs Client Components, in depth

When Next.js introduced the App Router (the routing system based on the `app/` directory), it changed the default execution location of a React component from "always the browser" to "the server, unless told otherwise."

Concretely: any `.tsx` file inside `src/app` is a Server Component by default. Its code:
- Runs only on the Node.js server.
- Can directly access server-only resources (databases, file systems, environment variables without any special prefix) because it never gets bundled into the JavaScript sent to the browser.
- Cannot use browser-only APIs like `useState`, `useEffect`, `onClick` handlers, or `window`.

To use any of those browser-only features, a file must start with the exact string:

```typescript
"use client";
```

This must be the very first line of the file (before imports). It flags the file as a Client Component. Next.js's build system then bundles that file's code into JavaScript the browser downloads and runs.

Why this matters architecturally for Greymatter PDF: our PDF file bytes, storage credentials, and database queries must only ever be reachable from Server Components, Server Actions, or Route Handlers (all server-only constructs). The moment code needs interactivity — clicking a "next page" button, dragging an annotation — it must live in a Client Component. Part 2 draws this line precisely: the page shell that fetches document metadata is a Server Component, while the actual `<canvas>`-rendering component is a Client Component.

## A.2 The React Compiler: what it actually does under the hood

Historically, React re-renders a component whenever its parent re-renders, even if none of that component's own inputs (props) changed. For a small app this is invisible. For an app with a canvas that redraws on every mouse pixel movement (our annotation layer, Part 4), unnecessary re-renders can visibly stutter the UI.

The traditional fix is manual memoization:
- `useMemo(() => computeSomething(a, b), [a, b])` — cache an expensive calculation, only recompute when `a` or `b` change.
- `useCallback(() => doSomething(), [dep])` — cache a function reference so child components do not think a new function was passed on every render.
- `React.memo(Component)` — skip re-rendering a component entirely if its props are unchanged (shallow comparison).

These tools work, but they require the developer to correctly track every dependency by hand — miss one, and you get a subtle bug (stale data); add one unnecessarily, and you get a performance regression.

The **React Compiler** (a build-time Babel plugin, which is why we installed `babel-plugin-react-compiler`) statically analyzes your component code during the build step and automatically inserts the equivalent of these memoizations wherever it determines they are safe and beneficial. It essentially does the bookkeeping a careful senior engineer would do by hand, but automatically and consistently across the entire codebase.

Practical implication for this series: from Part 4 onward, when we write the annotation canvas component that recalculates coordinates on every mouse move, we will **not** manually wrap those calculations in `useMemo`. We rely on the compiler. This is a deliberate simplification that keeps our code shorter and more readable, matching the "beginner-friendly" goal of this series without sacrificing production performance.

## A.3 Why serverActions.bodySizeLimit matters early

Next.js Server Actions (introduced in Part 6, configured here in Part 1) are, by default, capped at accepting request bodies up to 1MB. This default exists to protect servers from accidental or malicious oversized payloads clogging up memory.

A single-page PDF might be under 1MB, but any real-world multi-page document (contracts, reports, scanned books) routinely exceeds that — a 50-page scanned PDF can easily be 10–20MB. Because Greymatter PDF's Part 6 functionality (merge, split, extract) accepts uploaded PDF bytes through Server Actions, we must raise this limit before we ever hit it, otherwise the symptom (a cryptic "Body exceeded 1MB limit" error) would appear disconnected from its actual cause, deep into Part 6.

We chose 25mb as a reasonable ceiling: generous enough for the vast majority of real-world business documents, while still protecting the server from truly unbounded uploads (which, in Part 3, we further protect using authenticated, size-checked upload flows through object storage rather than raw Server Action payloads for the largest files).

## A.4 Glossary of terms introduced in Part 1

- **App Router**: Next.js's file-system-based routing system rooted at `src/app`, which supports Server Components, Server Actions, and nested layouts.
- **Server Component**: A React component whose code runs only on the server; never shipped to the browser as JavaScript.
- **Client Component**: A React component marked with `"use client"` at the top of the file; its code is bundled and executed in the browser, enabling interactivity.
- **Server Action**: An async function, marked with `"use server"`, that can be called directly from a Client Component as though it were local, but actually executes on the server over a hidden network request.
- **Web Worker**: A background JavaScript execution thread provided by the browser, separate from the main thread that handles UI events; used in Part 2 to keep PDF parsing from freezing the interface.
- **React Compiler**: A build-time Babel plugin (React 19.2+) that automatically memoizes components and values, removing the need for manual `useMemo`/`useCallback` in most cases.
- **Topology** (as used in this series): the arrangement of which parts of an application run on the client vs the server, and how they communicate.
- **.env.local**: A Next.js convention file for local environment variables/secrets, automatically excluded from git by the default `.gitignore`, and never bundled into client-side JavaScript unless a variable name is explicitly prefixed with `NEXT_PUBLIC_`.

## A.5 Command reference for Part 1

| Command | Purpose |
|---|---|
| `node -v` / `npm -v` | Check toolchain versions |
| `npx create-next-app@latest greymatter-pdf` | Scaffold the project |
| `npm run dev` | Start local dev server (default: http://localhost:3000) |
| `npm run build` | Produce a production build; also validates config like `reactCompiler` |
| `npm install --save-dev babel-plugin-react-compiler` | Install the compiler's Babel plugin |
| `git init && git add . && git commit -m "..."` | Initialize version control for the project |

## A.6 Common pitfalls at this stage

1. **Forgetting `"use client"`**: if you later see an error like "useState can only be used in a Client Component," it means a file using browser-only hooks is missing the directive at its very top.
2. **Committing .env.local by accident**: always run `git status` before your first commit and confirm secrets files are excluded, especially once Part 3 and Part 5 add real credentials to that file.
3. **Skipping the bodySizeLimit change**: if you skip Step 4 now, revisit this appendix when Part 6 throws a payload-too-large error on PDF uploads.
4. **Node version too old**: Next.js 16 requires Node >= 20.9.0; running an older Node version can cause obscure build errors unrelated to your actual code.
