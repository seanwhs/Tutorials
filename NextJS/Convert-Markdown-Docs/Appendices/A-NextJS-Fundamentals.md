# Appendix A: Next.js 16 Fundamentals

## Purpose of This Appendix
This is a standalone reference — read it independently of the tutorial flow, whenever you want to go deeper than a given part's pace allowed. It consolidates every Next.js architectural concept referenced throughout the series into one place.

---

## The App Router: What It Actually Is

Next.js's **App Router** (the `app/` directory convention we used starting in Part 1A) is a **file-based routing system**: the folder structure inside `app/` directly maps to URLs. A folder named `app/inspector/` containing a `page.tsx` (Part 3B) becomes the route `/inspector`. A folder with square brackets, `app/api/convert/[format]/` (Part 4A), becomes a **dynamic segment** — matching any value in that URL position and handing it to your code as a parameter.

This is a deliberate architectural shift from the older "Pages Router" (Next.js's previous convention, `pages/` directory) — the App Router was built specifically to support two ideas that matter throughout this series:

1. **Server Components by default.** Every component in `app/` is a Server Component (rendered on the server, sending zero JavaScript to the browser for that component) *unless* it explicitly opts into being a Client Component via `"use client"` (as we did in Part 2A for `Editor.tsx`, since it needed `useState`).
2. **Colocation of routing and server logic.** A `route.ts` file (Part 4A) and a `page.tsx` file can live in the same folder, each handling a different concern for the same URL segment — routing (`page.tsx`) versus a raw HTTP API (`route.ts`).

---

## Server Components vs. Client Components — The Real Distinction

This distinction came up first in Part 2A and recurred throughout the series, so it's worth stating with full precision here:

| | Server Component (default) | Client Component (`"use client"`) |
|---|---|---|
| Where it runs | Only on the server, during the request | Both on the server (for the initial HTML) *and* in the browser (for interactivity afterward) |
| Can use `useState`/`useEffect`/event handlers | No | Yes |
| Can be `async` and directly `await` data | Yes | No (must use `useEffect` or a library like SWR/TanStack Query instead) |
| JavaScript sent to the browser | None, for that component | Yes — the component's code, plus React itself |
| Example from this series | `app/page.tsx` (Part 1D, before Part 2 added interactivity) | `components/Editor.tsx` (Part 2A onward) |

A common beginner misconception worth directly correcting: **"use client" does not mean "this only runs in the browser."** It means "this component needs the interactivity APIs that only work in the browser, so also send its code there." Next.js still renders a Client Component's *first* pass on the server too (for fast initial page loads), then "hydrates" it in the browser — attaching real event listeners and enabling `useState` to take over from that point forward.

---

## Route Handlers vs. Server Actions — Revisited in Full

Part 4A introduced the practical rule ("return a value → Server Action; return a downloadable file → Route Handler"). Here's the fuller picture:

**Server Actions** (`"use server"`, first used in Part 1C) are async functions that:
- Can be called directly from a form's `action` prop, or invoked like a normal function from client-side event handlers (as we did in Part 3B's `inspectMarkdownAction`).
- Are compiled by Next.js into a hidden, auto-generated network endpoint — you never see or write the URL yourself.
- Return plain JavaScript values (objects, strings, arrays) — not raw HTTP responses.
- Are the right tool when the *result* of the action is "a piece of data my UI should react to."

**Route Handlers** (`route.ts` files, first used in Part 4A) are:
- Plain functions (`GET`, `POST`, `PUT`, `DELETE`, etc.) that receive a real `NextRequest` and must return a real `Response`/`NextResponse`.
- Full, explicit control over headers, status codes, and binary response bodies — which is why every file-generating endpoint in this series (`/api/convert/[format]`) was built as a Route Handler, not a Server Action.
- The correct tool any time an external, non-browser client (a `curl` command, a mobile app, a third-party integration) needs to call your endpoint directly — a Server Action's auto-generated endpoint isn't designed for that kind of direct, arbitrary access the way a Route Handler explicitly is.

---

## Streaming Responses

Although GreyMatter MConvert's Route Handler builds its entire file buffer in memory before responding (`fileBuffer = await toPdf(...)`, then `new NextResponse(fileBuffer, ...)`), Next.js Route Handlers *can* stream a response incrementally — sending chunks of data to the client as they become available, rather than waiting for the entire response body to be ready. This matters for very large responses or slow, incremental data sources.

For our specific use case, streaming wasn't necessary: PDF/DOCX/PPTX generation for realistic document sizes (bounded by Part 8A's `MAX_MARKDOWN_LENGTH`) completes well within acceptable time, and all three underlying libraries (`@react-pdf/renderer`, `docx`, `pptxgenjs`) are designed around producing a complete in-memory buffer rather than incremental output. If you extend this project to handle much larger documents, investigate each library's own streaming APIs (`@react-pdf/renderer`'s `renderToStream`, for instance, exists specifically for this) paired with Next.js's `ReadableStream`-based `Response` support.

---

## Runtime Configuration: Node.js vs. Edge

This is the single most operationally important concept for this specific application, first introduced in Part 4A and re-emphasized in Part 9A.

Next.js can execute a Route Handler in one of two runtimes:

- **Node.js runtime** (`export const runtime = "nodejs"`) — the full, familiar Node.js environment: complete access to `Buffer`, the full `fs` module, native npm packages with C++ bindings, and — critically for us — full compatibility with `@react-pdf/renderer`, `docx`, and `pptxgenjs`, none of which were built with Edge compatibility in mind.
- **Edge runtime** (the default for Route Handlers unless overridden, in some Next.js configurations) — a lighter, faster-starting, more restricted environment (based on web-standard APIs, similar to what runs inside a Cloudflare Worker or browser service worker) that deliberately **excludes** much of Node.js's API surface, including reliable, full `Buffer` support and native binary modules.

Our explicit `export const runtime = "nodejs";` line, set in Part 4A and re-verified in Part 9A before deployment, is not a stylistic preference — it is a **hard requirement**. Attempting to run any of our three converters under the Edge runtime would very likely fail, either immediately (a missing API) or in confusing, hard-to-reproduce ways. If you ever see mysterious `Buffer is not defined` or similar errors after modifying this route, check this line first.

---

**Official documentation:** [nextjs.org/docs/app](https://nextjs.org/docs/app) — specifically the "Routing," "Rendering," and "Route Handlers" sections cover everything above in exhaustive detail, and are worth bookmarking for whenever Next.js itself releases new features beyond what this series covered.
