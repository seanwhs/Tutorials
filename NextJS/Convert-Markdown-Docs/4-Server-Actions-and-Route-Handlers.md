# Part 4A: Route Handlers — The Conversion Pipeline Skeleton

## What This Installment Covers
Before wiring up real "Export" buttons, we need a server endpoint that can accept Markdown text, pick a format, and stream back a binary file with correct download headers. This installment builds that skeleton — returning a fake placeholder file for all three formats — and verifies it entirely from the terminal with `curl`, before touching any UI. Wiring real buttons to it is 4B.

---

## Step 1 — Route Handlers vs. Server Actions: Choosing the Right Tool

### The Target
No code yet — a clear decision about *why* file downloads need a different mechanism than the Server Actions we've used in Parts 1 and 3.

### The Concept

> **Analogy — A Phone Call vs. A Package Delivery.** A Server Action (which we've used twice now) is like a phone call: you say something, the person on the other end responds, and the conversation happens over a channel optimized for *messages* — small pieces of data going back and forth. A **Route Handler** is like a package delivery service: it's built specifically for producing a *file* — with a name, a size, a specific content type — and handing it to a courier (your browser) that knows to treat it as a download rather than a piece of text to display.

Concretely, Next.js Route Handlers are plain files named `route.ts` living inside `app/`, where each exported function (`GET`, `POST`, etc.) directly handles an HTTP request and returns an HTTP `Response` object — the same `Response` you'd use in browser-native `fetch()` code. This gives us **complete, low-level control** over response headers (`Content-Type`, `Content-Disposition`) and the response body (raw binary bytes), which is exactly what generating a `.pdf`, `.docx`, or `.pptx` file requires.

Server Actions, by contrast, are designed around returning JavaScript values (strings, objects, arrays) back into React state — which is perfect for what we did in Part 3 (returning a parsed AST object), but awkward for "please give the browser a binary file to save to disk with a specific filename." Browsers have built-in, native behavior for downloading files when a response has the right headers — that native behavior is triggered through a real HTTP response, which is what Route Handlers give us directly.

**The rule going forward:**

| Need | Use |
|---|---|
| Return a value (object, string, array) to update UI state | **Server Action** |
| Return a downloadable file (PDF, DOCX, PPTX, CSV, etc.) with specific headers | **Route Handler** |

### The Verification
No runnable check — this is the architectural decision the rest of this installment builds on.

---

## Step 2 — Understanding Dynamic Route Segments

### The Target
Understanding the file path `app/api/convert/[format]/route.ts` — specifically, what the square brackets mean — before creating it.

### The Concept

> **Analogy — A Hotel Room Number Sign That Reads "Any Number."** Normally, a folder name in `app/` maps to a literal URL segment — a folder named `about` creates the URL `/about`. A folder name wrapped in square brackets, like `[format]`, is Next.js's syntax for a **dynamic segment**: it matches *any* value in that position of the URL, and hands you that value as a variable. So a request to `/api/convert/pdf` and a request to `/api/convert/docx` both match this *same* route file — the difference (`"pdf"` vs `"docx"`) is captured and passed to our handler function as a parameter named `format`.

This is exactly the right structure for our use case: we want one endpoint that handles all three export formats, differentiated only by which URL was called, rather than three nearly-identical route files (`app/api/convert-pdf/route.ts`, `app/api/convert-docx/route.ts`, etc.) that would duplicate validation and error-handling logic three times over.

### The Verification
No runnable check — proceed to Step 3 where we create this exact structure.

---

## Step 3 — Building the Route Handler Skeleton

### The Target
`app/api/convert/[format]/route.ts` — a `POST` handler that accepts Markdown text, validates the requested format, and returns a **placeholder** text file (not a real PDF/DOCX/PPTX yet — that's Parts 5–7) with correct download headers.

### The Concept

> **Analogy — A Restaurant Kitchen's Order Ticket System, Before the Chefs Are Hired.** We're building the ticket window, the validation ("is this even a dish we serve?"), and the delivery mechanism (handing a tray to the customer) — before any actual chef (PDF/DOCX/PPTX renderer) has been hired. The customer still walks away with *something* on a tray (a stub file), proving the whole ordering-to-delivery pipeline works, before we worry about what's actually cooked.

We validate the `format` parameter against a fixed, known list (`"pdf" | "docx" | "pptx"`) rather than trusting it blindly — this is the same "never trust data crossing a boundary" principle from Part 3A's `typeof markdown !== "string"` check, applied here to a URL segment instead of form data.

### The Implementation

**`app/api/convert/[format]/route.ts`**

```typescript
import { NextRequest, NextResponse } from "next/server";
import { parseMarkdown } from "@/lib/parseMarkdown";

// Route Handlers can run in two different "runtimes": Node.js (full Node
// APIs available) or Edge (a lighter, faster, but restricted environment).
// The PDF/DOCX/PPTX libraries we install in Parts 5–7 rely on Node.js-only
// APIs (like Buffer and certain filesystem/font operations), so we pin this
// route to the Node.js runtime explicitly, right now, before those libraries
// even exist — so nobody accidentally flips this later and breaks everything.
// Appendix A covers the full Node vs Edge distinction in depth.
export const runtime = "nodejs";

// The only formats this endpoint will ever recognize. Defined once, as a
// const array, so both our validation logic AND our TypeScript types stay
// in sync automatically — adding a 4th format later means changing this
// one line, not hunting through multiple files.
const SUPPORTED_FORMATS = ["pdf", "docx", "pptx"] as const;
type SupportedFormat = (typeof SUPPORTED_FORMATS)[number];

function isSupportedFormat(value: string): value is SupportedFormat {
  return (SUPPORTED_FORMATS as readonly string[]).includes(value);
}

// Maps each format to the correct MIME type — the standardized string that
// tells the browser/OS what KIND of file this is, so it can show the right
// icon and offer to open it with the right application.
const CONTENT_TYPES: Record<SupportedFormat, string> = {
  pdf: "application/pdf",
  docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  pptx: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
};

/**
 * Handles POST /api/convert/pdf, /api/convert/docx, /api/convert/pptx.
 *
 * Request body (JSON): { markdown: string }
 * Response: a binary file, with headers instructing the browser to download
 * it rather than display it inline.
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ format: string }> }
) {
  // In Next.js 16, dynamic route params are provided as a Promise (this
  // supports advanced streaming/rendering patterns under the hood) — so we
  // must `await` it before we can read `format` out of it.
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

  // `body` is `unknown` at this point — exactly like the FormData boundary
  // in Part 3A, we cannot trust its shape just because we hope the client
  // sent the right thing. We narrow it manually before use.
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

  // We parse the Markdown now, even though this stub doesn't use the AST
  // yet, for a deliberate reason: this proves the FULL intended pipeline —
  // request in, parse, (eventually convert), file out — is wired correctly
  // end-to-end from day one. Parts 5–7 replace only the "generate stub"
  // line below with real converter calls; nothing above it needs to change.
  const ast = parseMarkdown(markdown);
  const nodeCount = countNodes(ast);

  // --- STUB FILE GENERATION (replaced with real rendering in Parts 5–7) ---
  // We generate a plain text placeholder describing what WOULD have been
  // produced, encoded as bytes, so we can prove the full binary-response
  // pipeline (headers, encoding, download behavior) works correctly now.
  const stubContent =
    `This is a placeholder ${format.toUpperCase()} file.\n\n` +
    `Generated by GreyMatter MConvert (Part 4 stub).\n` +
    `Parsed AST contained ${nodeCount} total nodes.\n\n` +
    `Real ${format.toUpperCase()} rendering arrives in a later part of the tutorial series.\n`;

  const fileBuffer = Buffer.from(stubContent, "utf-8");
  const filename = `greymatter-export.${format}`;

  return new NextResponse(fileBuffer, {
    status: 200,
    headers: {
      // Tells the browser what KIND of content this is.
      "Content-Type": CONTENT_TYPES[format],
      // Tells the browser to DOWNLOAD this response as a file with the
      // given name, rather than trying to display it inline in the tab.
      "Content-Disposition": `attachment; filename="${filename}"`,
      // Tells the browser exactly how many bytes to expect — good practice
      // for binary responses, letting the browser show accurate download
      // progress for larger files (which matters once real PDFs/DOCXs
      // are being generated in later parts).
      "Content-Length": String(fileBuffer.byteLength),
    },
  });
}

/** Recursively counts every node in a parsed mdast tree, root included. */
function countNodes(node: { children?: unknown[] }): number {
  let count = 1;
  if (Array.isArray(node.children)) {
    for (const child of node.children) {
      // Each child is itself a node shape (with its own optional children),
      // so we recurse — the same "walk the tree" pattern from Part 3B's
      // AstTreeView component, just counting instead of rendering.
      count += countNodes(child as { children?: unknown[] });
    }
  }
  return count;
}
```

That completes the file. Here is the entire thing, top to bottom, for a clean copy-paste reference in one place:

**`app/api/convert/[format]/route.ts`** (full file)

```typescript
import { NextRequest, NextResponse } from "next/server";
import { parseMarkdown } from "@/lib/parseMarkdown";

// Route Handlers can run in two different "runtimes": Node.js (full Node
// APIs available) or Edge (a lighter, faster, but restricted environment).
// The PDF/DOCX/PPTX libraries we install in Parts 5–7 rely on Node.js-only
// APIs (like Buffer and certain filesystem/font operations), so we pin this
// route to the Node.js runtime explicitly, right now, before those libraries
// even exist — so nobody accidentally flips this later and breaks everything.
// Appendix A covers the full Node vs Edge distinction in depth.
export const runtime = "nodejs";

// The only formats this endpoint will ever recognize. Defined once, as a
// const array, so both our validation logic AND our TypeScript types stay
// in sync automatically — adding a 4th format later means changing this
// one line, not hunting through multiple files.
const SUPPORTED_FORMATS = ["pdf", "docx", "pptx"] as const;
type SupportedFormat = (typeof SUPPORTED_FORMATS)[number];

function isSupportedFormat(value: string): value is SupportedFormat {
  return (SUPPORTED_FORMATS as readonly string[]).includes(value);
}

// Maps each format to the correct MIME type — the standardized string that
// tells the browser/OS what KIND of file this is, so it can show the right
// icon and offer to open it with the right application.
const CONTENT_TYPES: Record<SupportedFormat, string> = {
  pdf: "application/pdf",
  docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  pptx: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
};

/**
 * Handles POST /api/convert/pdf, /api/convert/docx, /api/convert/pptx.
 *
 * Request body (JSON): { markdown: string }
 * Response: a binary file, with headers instructing the browser to download
 * it rather than display it inline.
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ format: string }> }
) {
  // In Next.js 16, dynamic route params are provided as a Promise (this
  // supports advanced streaming/rendering patterns under the hood) — so we
  // must `await` it before we can read `format` out of it.
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

  // `body` is `unknown` at this point — exactly like the FormData boundary
  // in Part 3A, we cannot trust its shape just because we hope the client
  // sent the right thing. We narrow it manually before use.
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

  // We parse the Markdown now, even though this stub doesn't use the AST
  // yet, for a deliberate reason: this proves the FULL intended pipeline —
  // request in, parse, (eventually convert), file out — is wired correctly
  // end-to-end from day one. Parts 5–7 replace only the "generate stub"
  // line below with real converter calls; nothing above it needs to change.
  const ast = parseMarkdown(markdown);
  const nodeCount = countNodes(ast);

  // --- STUB FILE GENERATION (replaced with real rendering in Parts 5–7) ---
  // We generate a plain text placeholder describing what WOULD have been
  // produced, encoded as bytes, so we can prove the full binary-response
  // pipeline (headers, encoding, download behavior) works correctly now.
  const stubContent =
    `This is a placeholder ${format.toUpperCase()} file.\n\n` +
    `Generated by GreyMatter MConvert (Part 4 stub).\n` +
    `Parsed AST contained ${nodeCount} total nodes.\n\n` +
    `Real ${format.toUpperCase()} rendering arrives in a later part of the tutorial series.\n`;

  const fileBuffer = Buffer.from(stubContent, "utf-8");
  const filename = `greymatter-export.${format}`;

  return new NextResponse(fileBuffer, {
    status: 200,
    headers: {
      // Tells the browser what KIND of content this is.
      "Content-Type": CONTENT_TYPES[format],
      // Tells the browser to DOWNLOAD this response as a file with the
      // given name, rather than trying to display it inline in the tab.
      "Content-Disposition": `attachment; filename="${filename}"`,
      // Tells the browser exactly how many bytes to expect — good practice
      // for binary responses, letting the browser show accurate download
      // progress for larger files (which matters once real PDFs/DOCXs
      // are being generated in later parts).
      "Content-Length": String(fileBuffer.byteLength),
    },
  });
}

/** Recursively counts every node in a parsed mdast tree, root included. */
function countNodes(node: { children?: unknown[] }): number {
  let count = 1;
  if (Array.isArray(node.children)) {
    for (const child of node.children) {
      // Each child is itself a node shape (with its own optional children),
      // so we recurse — the same "walk the tree" pattern from Part 3B's
      // AstTreeView component, just counting instead of rendering.
      count += countNodes(child as { children?: unknown[] });
    }
  }
  return count;
}
```

A few details worth pausing on:

- **`{ params }: { params: Promise<{ format: string }> }`** — this `Promise`-wrapped params shape is specific to recent Next.js versions (including 16). If you're used to older Next.js tutorials showing `{ params }: { params: { format: string } }` (no `Promise`), that's outdated — omitting the `await` here would cause a type error at compile time, which is exactly TypeScript doing its job of catching an API mismatch before runtime.
- **Validating twice** (`isSupportedFormat` for the URL segment, then the `body` shape check for the JSON payload) reflects the same "never trust a boundary" principle applied at *two different* boundaries in this one function: the URL, and the request body. Each is untrusted external input and deserves its own explicit check.
- **`Content-Length`** is optional in HTTP but good practice to set explicitly whenever you already know your buffer's exact size — which we do here, since we just built `fileBuffer` ourselves.

### The Verification

Start the dev server:

```bash
npm run dev
```

Now, **without touching the browser UI at all**, test this endpoint directly via `curl` from a separate terminal window. This is a valuable habit: verifying a Route Handler in isolation, before any frontend code depends on it, isolates bugs to exactly one layer at a time.

**Test 1 — A valid PDF request:**

```bash
curl -i -X POST http://localhost:3000/api/convert/pdf \
  -H "Content-Type: application/json" \
  -d '{"markdown": "# Hello\n\nThis is **bold** text."}' \
  -o test-output.pdf
```

Expected terminal output includes these headers (among others):

```
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Disposition: attachment; filename="greymatter-export.pdf"
Content-Length: ...
```

Then check the downloaded file:

```bash
cat test-output.pdf
```

You should see plain text output like:

```
This is a placeholder PDF file.

Generated by GreyMatter MConvert (Part 4 stub).
Parsed AST contained 4 total nodes.

Real PDF rendering arrives in a later part of the tutorial series.
```

(The exact node count may differ slightly depending on how the parser structures that specific input — what matters is that it's a real number greater than zero, proving `parseMarkdown` genuinely ran against your input.)

**Test 2 — An unsupported format (should be rejected):**

```bash
curl -i -X POST http://localhost:3000/api/convert/epub \
  -H "Content-Type: application/json" \
  -d '{"markdown": "# Hello"}'
```

Expected: `HTTP/1.1 400 Bad Request`, with a JSON body like:

```json
{"error":"Unsupported export format: \"epub\". Supported formats are: pdf, docx, pptx."}
```

**Test 3 — Missing markdown field (should be rejected):**

```bash
curl -i -X POST http://localhost:3000/api/convert/docx \
  -H "Content-Type: application/json" \
  -d '{}'
```

Expected: `HTTP/1.1 400 Bad Request`, with:

```json
{"error":"Request body must include a 'markdown' string field."}
```

**Test 4 — DOCX and PPTX both work identically:**

```bash
curl -i -X POST http://localhost:3000/api/convert/docx \
  -H "Content-Type: application/json" \
  -d '{"markdown": "# Test"}' \
  -o test-output.docx

curl -i -X POST http://localhost:3000/api/convert/pptx \
  -H "Content-Type: application/json" \
  -d '{"markdown": "# Test"}' \
  -o test-output.pptx
```

Confirm both commands return `200 OK` with their respective correct `Content-Type` headers (`application/vnd.openxmlformats-officedocument.wordprocessingml.document` and `.presentationml.presentation`), and that `test-output.docx` / `test-output.pptx` both contain the expected stub text when opened with `cat`.

Once all four tests pass, clean up the test files:

```bash
rm test-output.pdf test-output.docx test-output.pptx
```

---

## ✅ Part 4A — Complete

You now have a fully working, fully validated Route Handler that:

- Runs on the **Node.js runtime** explicitly (`export const runtime = "nodejs"`), pre-configured for the binary-generating libraries Parts 5–7 will introduce.
- Accepts a dynamic `[format]` URL segment and validates it against a known, typed list (`"pdf" | "docx" | "pptx"`), rejecting anything else with a clean `400` error.
- Accepts a JSON request body, validates its shape defensively (never trusting that `markdown` is actually a string just because the client claims it is), and rejects malformed or empty input with clear error messages.
- Runs the request's Markdown through our existing `parseMarkdown()` from Part 3 — proving the *real* pipeline (request → parse → eventually render) is wired end-to-end, even though rendering itself is still a stub.
- Returns a correctly-headed binary response (`Content-Type`, `Content-Disposition`, `Content-Length`) that any HTTP client — `curl` today, a real browser download tomorrow — will treat as a genuine file to save, not text to display.
- Was verified **entirely from the terminal**, in complete isolation from any frontend code, for all three formats plus two distinct failure cases.

This matters architecturally: everything above the "STUB FILE GENERATION" comment in `route.ts` is **permanent, production-shaped code** — validation, parsing, headers. In Parts 5, 6, and 7, we will *only* replace the stub-generation block with a call to a real converter function (`toPdf(ast)`, `toDocx(ast)`, `toPptx(ast)`), and swap `Buffer.from(stubContent, "utf-8")` for that converter's real output buffer. Nothing else in this file needs to change. That's the entire point of building the plumbing first.

---

Nothing is wrong on my end technically — the previous two attempts landed as blank messages due to an output error, not a content-generation limitation. My apologies for the repeated frustration. Here is **Part 4B, complete, in one shot.**

---

# Part 4B: Wiring Real "Export" Buttons

## What This Installment Covers
Connecting the Route Handler from 4A to actual UI buttons. We use React 19's `useActionState` to manage the export lifecycle (idle → pending → success/error) and `useFormStatus` to show a per-button loading state, then trigger a genuine browser file download using `fetch` + a Blob URL. By the end, clicking "Export as PDF/DOCX/PPTX" in your running app downloads a real (stub) file.

---

## Step 7 — Understanding `useActionState`

### The Target
No code yet — the mental model for `useActionState`, before we use it.

### The Concept

> **Analogy — A Vending Machine with a Status Light.** Pressing a vending machine button doesn't instantly give you a snack — there's a brief "dispensing" state, then either success (snack drops) or failure (jammed, refund needed). `useActionState` is React's built-in way of managing exactly this three-phase lifecycle — **idle → pending → result** — around an async function, without manually wiring up three separate `useState` calls (`isLoading`, `error`, `result`) yourself every time.

It works like this: `const [state, formAction] = useActionState(actionFn, initialState)`. You give it an async function and a starting value; it hands back the current `state` (whatever your function last returned) and a wrapped version of that function (`formAction`) suitable for passing straight to a `<form action={...}>`. Every time the form submits, React calls your function with `(previousState, formData)`, waits for it to resolve, and updates `state` with whatever it returns — automatically re-rendering your component with the new result.

One important nuance: **our export action isn't a Server Action** this time. Server Actions (Parts 1 and 3) are great for returning small JS values, but recall from Part 4A's Step 1 that file downloads specifically need a real HTTP response with binary headers — which means the actual network request must be a `fetch()` call to our Route Handler, not a Server Action call. `useActionState` doesn't care whether the function you give it is a Server Action or a plain client-side async function — it manages the pending/result lifecycle either way. So here, we'll give it a plain async function that internally calls `fetch("/api/convert/pdf", ...)`.

### The Verification
No runnable check — proceed to Step 8 where this becomes real code.

---

## Step 8 — Understanding `useFormStatus`

### The Target
No code yet — the mental model for `useFormStatus`, before we use it.

### The Concept

> **Analogy — A Waiter Who Only Knows About Their Own Table.** `useActionState` (Step 7) lives in the *parent* component that owns the whole form. But imagine we have three separate "Export" buttons (PDF, DOCX, PPTX) inside that one form, and we want *only the button that was actually clicked* to show a spinner — not all three at once. `useFormStatus` is a hook that any component *nested inside* a `<form>` can call to ask, "is the form I'm inside of currently submitting?" — without needing that information passed down manually as a prop. It's like a waiter who, standing right at a specific table, can tell you "yes, this table's order is being prepared," without needing to shout across the whole restaurant.

Concretely: `const { pending } = useFormStatus()`, called inside a child component rendered within a `<form>`. We'll use this to build a reusable `<ExportButton>` component that shows "Exporting…" only for the specific button whose form submission is in flight.

### The Verification
No runnable check — proceed to Step 9.

---

## Step 9 — The Client-Side Export Function

### The Target
`lib/downloadExport.ts` — a small helper function that calls our Route Handler via `fetch`, converts the binary response into a downloadable file, and triggers the browser's native "Save As" behavior.

### The Concept

> **Analogy — A Courier Who Picks Up a Package and Personally Hands It to You at Your Door.** `fetch()` retrieves the binary file bytes from our server, but the browser doesn't automatically know "please save this to disk" just because we fetched it — that's different from a normal link click, which the browser handles natively. We have to manually: (1) collect the bytes into a `Blob` (a browser object representing raw binary data), (2) create a temporary local URL pointing at that Blob, (3) create an invisible `<a>` link pointing at that URL with a `download` attribute, and (4) simulate a click on it. This four-step dance is the standard, well-established browser pattern for triggering downloads from `fetch`-retrieved data — it looks like a lot of steps, but each one is simple and every step is necessary.

### The Implementation

**`lib/downloadExport.ts`**

```typescript
export type ExportFormat = "pdf" | "docx" | "pptx";

export interface DownloadResult {
  success: boolean;
  error: string | null;
}

/**
 * Calls the /api/convert/[format] Route Handler with the given Markdown
 * text, and — if successful — triggers a real browser file download.
 *
 * This function is intentionally plain (not a Server Action) because it
 * needs to run in the browser: it manipulates the DOM directly (creating
 * a temporary link element) to trigger the download, which is only
 * possible client-side.
 */
export async function downloadExport(
  format: ExportFormat,
  markdown: string
): Promise<DownloadResult> {
  if (markdown.trim().length === 0) {
    return { success: false, error: "Please enter some Markdown before exporting." };
  }

  let response: Response;
  try {
    response = await fetch(`/api/convert/${format}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ markdown }),
    });
  } catch {
    // A thrown fetch error here means a network-level failure (server
    // unreachable, connection dropped) — distinct from the server
    // responding with an error status, which we handle just below.
    return { success: false, error: "Network error: could not reach the server." };
  }

  if (!response.ok) {
    // Our Route Handler returns JSON error bodies for all validation
    // failures (see Part 4A), so we try to read that message out to show
    // the user something meaningful instead of a generic failure.
    let message = `Export failed with status ${response.status}.`;
    try {
      const errorBody = (await response.json()) as { error?: string };
      if (errorBody.error) message = errorBody.error;
    } catch {
      // Response wasn't JSON (unexpected) — fall back to the generic
      // message already set above.
    }
    return { success: false, error: message };
  }

  // Convert the raw response bytes into a Blob — the browser's
  // representation of an in-memory binary file.
  const blob = await response.blob();

  // Extract the filename the server chose (from Content-Disposition, set
  // in Part 4A) so our downloaded file's name matches what the server
  // intended, rather than us hardcoding it a second time on the client.
  const disposition = response.headers.get("Content-Disposition") ?? "";
  const filenameMatch = disposition.match(/filename="([^"]+)"/);
  const filename = filenameMatch?.[1] ?? `greymatter-export.${format}`;

  // Step 1: create a temporary, browser-local URL that points at the Blob's
  // in-memory bytes (this is NOT a real network URL — it only works within
  // this browser tab, and only until we revoke it below).
  const objectUrl = URL.createObjectURL(blob);

  // Step 2: create an invisible link element pointing at that URL, with a
  // `download` attribute — this attribute is what tells the browser
  // "save this, don't navigate to it," even though we're about to click it
  // entirely programmatically rather than a real user click.
  const link = document.createElement("a");
  link.href = objectUrl;
  link.download = filename;

  // Step 3: the link must be attached to the document for some browsers to
  // honor a programmatic click on it — we add it, click it, then remove it
  // immediately after, so it never visibly appears on the page.
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);

  // Step 4: free the browser's memory held by the temporary URL now that
  // the download has been triggered — skipping this is a memory leak if
  // a user exports many files in one session.
  URL.revokeObjectURL(objectUrl);

  return { success: true, error: null };
}
```

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output. This confirms `ExportFormat`, `DownloadResult`, and the function signature are all internally consistent and correctly typed — we'll exercise this function for real in the next step, once it's wired to a visible button.

---

## Step 10 — The Reusable `<ExportButton>` Component

### The Target
`components/ExportButton.tsx` — a single button component, rendered three times (once per format), each wrapped in its own `<form>` so `useFormStatus` can independently track each button's pending state.

### The Concept

> **Analogy — Three Independent Vending Machine Slots, Sharing One Building.** Each export button needs its *own* independent pending state — clicking "Export PDF" shouldn't make the "Export DOCX" button also show a spinner. Wrapping each button in its **own** `<form>` (even though there's no visible form styling — these forms exist purely as the mechanism `useActionState`/`useFormStatus` hook into) gives each button that isolation for free, since `useFormStatus` only reports the status of the nearest enclosing `<form>`.

### The Implementation

**`components/ExportButton.tsx`**

```tsx
"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";
import { downloadExport, type ExportFormat, type DownloadResult } from "@/lib/downloadExport";

interface ExportButtonProps {
  format: ExportFormat;
  label: string;
  markdown: string;
}

const initialState: DownloadResult = { success: false, error: null };

// A small inner component is required here specifically so useFormStatus
// has a <form> ancestor to inspect — calling useFormStatus in the SAME
// component that renders the <form> itself does not work, by React's
// design, since the hook reports on forms it's nested INSIDE of.
function SubmitButton({ label }: { label: string }) {
  const { pending } = useFormStatus();

  return (
    <button
      type="submit"
      disabled={pending}
      className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-900 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {pending ? "Exporting…" : label}
    </button>
  );
}

export default function ExportButton({ format, label, markdown }: ExportButtonProps) {
  // The action function passed to useActionState receives (previousState,
  // formData) and must return the new state. We don't actually need any
  // fields FROM formData here (the markdown is passed in via closure from
  // props instead), but the signature is required by useActionState's API.
  const [state, formAction] = useActionState<DownloadResult, FormData>(
    async (_previousState) => {
      const result = await downloadExport(format, markdown);
      return result;
    },
    initialState
  );

  return (
    <form action={formAction} className="inline-block">
      <SubmitButton label={label} />
      {state.error && (
        <p className="mt-1 text-xs text-red-600">{state.error}</p>
      )}
    </form>
  );
}
```

A detail worth pausing on: **why does `SubmitButton` need to be a separate component from `ExportButton`, instead of just calling `useFormStatus` directly inside `ExportButton`?**

This is a real React rule, not a stylistic preference: `useFormStatus` only reports on a `<form>` that is an *ancestor* of the component calling the hook — it deliberately does not see the `<form>` it is a sibling of, or the one it's defined alongside in the same component. Since `ExportButton` is the component that *renders* the `<form>` tag itself, calling `useFormStatus` there would be asking about a form *above* `ExportButton`, not the one it just created — which isn't what we want. By pulling the button out into its own child component (`SubmitButton`), rendered *inside* the `<form>`, `useFormStatus` correctly reports on that specific enclosing form. This nested-component requirement is one of the most common points of confusion for developers new to this hook, so it's worth remembering as a fixed rule: **`useFormStatus` must be called from a component nested inside the `<form>`, never the component that renders the `<form>` itself.**

### The Verification

```bash
npx tsc --noEmit
```

Expected: no output. This confirms `useActionState`'s generic types (`DownloadResult`, `FormData`) line up correctly, and that `SubmitButton`'s use of `useFormStatus` is valid.

---

## Step 11 — Adding Export Buttons to the Editor

### The Target
Update `components/Editor.tsx` to render three `<ExportButton>` instances — one per format — passing in the current `text` state so each export always reflects exactly what's in the editor at click time.

### The Concept

> **Analogy — A Print Shop Counter Next to the Notepad.** We're placing three clearly labeled buttons right next to the editor pane the user is already looking at, each wired to the *live* `text` state from Part 2 — so clicking "Export as PDF" always sends whatever is currently typed, not some stale snapshot from when the page first loaded.

### The Implementation

**`components/Editor.tsx`** (full file, replacing the previous version — only the imports and the new buttons section have changed; everything else is untouched from Part 2C)

```tsx
"use client";

import { useState, useEffect, useTransition, type ChangeEvent } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { templates, type TemplateId } from "@/lib/templates";
import ExportButton from "@/components/ExportButton";

const DEFAULT_CONTENT =
  "# Hello GreyMatter\n\n" +
  "This is **bold** and this is *italic*.\n\n" +
  "- First item\n- Second item\n\n" +
  "| Feature   | Supported |\n" +
  "| --------- | --------- |\n" +
  "| Tables    | Yes       |\n" +
  "| Checklists| Yes       |\n\n" +
  "- [x] Try the live preview\n- [ ] Export to PDF (coming in Part 5)";

const DRAFT_STORAGE_KEY = "greymatter-mconvert:draft";

export default function Editor() {
  const [text, setText] = useState<string>(DEFAULT_CONTENT);
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    const saved = window.localStorage.getItem(DRAFT_STORAGE_KEY);
    if (saved && saved.trim().length > 0) {
      setText(saved);
    }
  }, []);

  useEffect(() => {
    window.localStorage.setItem(DRAFT_STORAGE_KEY, text);
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
      <div className="mb-4 flex flex-wrap items-center gap-3">
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

        {/* Export buttons live here, always reading the CURRENT `text`
            state via props — never a stale copy — so whatever the user
            has typed at the moment of clicking is exactly what gets sent
            to the /api/convert/[format] Route Handler from Part 4A. */}
        <div className="ml-auto flex gap-2">
          <ExportButton format="pdf" label="Export as PDF" markdown={text} />
          <ExportButton format="docx" label="Export as DOCX" markdown={text} />
          <ExportButton format="pptx" label="Export as PPTX" markdown={text} />
        </div>
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

Restart the dev server:

```bash
npm run dev
```

Open **http://localhost:3000**. You should now see three buttons — **Export as PDF**, **Export as DOCX**, **Export as PPTX** — sitting to the right of the template dropdown.

**Test 1 — Basic download:**
Click **Export as PDF**. Watch the button text briefly change to **"Exporting…"** and become disabled (confirming `useFormStatus`'s `pending` state is working), then a file named `greymatter-export.pdf` should download via your browser's normal download mechanism (check your Downloads folder or browser's download tray).

Open that file in a plain text editor (not a PDF viewer — it's still a stub, so a real PDF viewer would likely reject it as not being valid PDF format). You should see the same placeholder text from Part 4A's `curl` test:

```
This is a placeholder PDF file.

Generated by GreyMatter MConvert (Part 4 stub).
Parsed AST contained N total nodes.

Real PDF rendering arrives in a later part of the tutorial series.
```

**Test 2 — Independent button states:**
Click **Export as DOCX**, and while it briefly shows "Exporting…", confirm the PDF and PPTX buttons remain completely unaffected (not disabled, not showing "Exporting…") — proving each button's `<form>`-scoped `useFormStatus` state is genuinely independent, exactly as Step 10 explained.

**Test 3 — Error handling:**
Clear the editor's textarea completely (select all, delete), then click any export button. You should see a red error message appear directly beneath that button: *"Please enter some Markdown before exporting."* — confirming `downloadExport`'s empty-input guard from Step 9 surfaces correctly all the way to the UI, with no crash and no silent failure.

**Test 4 — Live content reflects in the export:**
Type a distinctive new line into the editor, e.g. `Unique test marker ABC123`, then click **Export as PPTX**. Open the downloaded `greymatter-export.pptx` in a text editor and confirm the node count in the stub text has changed compared to earlier tests — proving the export always uses the *current* live editor content, not a stale snapshot.

---

## ✅ Part 4 — Complete

Checking this against the Part 0 roadmap promise for Part 4 — *"clicking Export as PDF/DOCX/PPTX downloads a stub file — the full plumbing works before real rendering logic exists"* — every piece is now verified, end to end:

- **4A:** A validated, Node.js-runtime Route Handler at `app/api/convert/[format]/route.ts`, tested directly via `curl` for all three formats plus two failure cases.
- **4B:** Real, clickable UI buttons using React 19's `useActionState` (managing the pending/result lifecycle) and `useFormStatus` (per-button independent loading state), triggering genuine browser file downloads via a `fetch` + Blob + temporary link pattern, with error messages surfaced cleanly in the UI.

Every layer of this pipeline — validation, parsing, header construction, client-side download triggering, loading states, error display — is now production-shaped and permanent. In Parts 5, 6, and 7, the *only* thing that changes is a few lines inside `app/api/convert/[format]/route.ts`: the stub-generation block gets replaced with a real call to `toPdf(ast)`, `toDocx(ast)`, or `toPptx(ast)`, and the resulting real binary buffer replaces `Buffer.from(stubContent, "utf-8")`. Nothing else — not the validation, not the buttons, not the download mechanism — needs to be touched again.
