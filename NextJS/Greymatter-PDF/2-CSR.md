# Part 2: Multi-Threaded Client-Side Rendering via Web Workers

*(Phase 1 — Core Architecture & High-Performance Rendering)*

---

## Why this part exists

In Part 1 we drew a rule: **never parse PDF vector graphics on the browser's main thread**. Here's why that rule matters in practice, with an analogy.

Imagine a single waiter (the main thread) who must do two jobs at once: take orders from customers (respond to clicks, scrolling, typing) *and* personally chop vegetables in the back (parse thousands of PDF drawing instructions). If the waiter is chopping vegetables, they cannot hear a customer calling for the bill — the whole restaurant appears frozen from the customer's point of view. A **Web Worker** is like hiring a second person dedicated only to chopping vegetables, in a separate room, who hands finished plates back to the waiter when ready. The waiter stays free to serve customers the entire time.

Technically: a Web Worker is a background JavaScript thread the browser provides. It cannot touch the DOM (the page's visual elements) directly, but it can do CPU-heavy computation and message the main thread when done. We'll use one to run **pdf.js** (Mozilla's PDF parsing/rendering engine, distributed as the npm package `pdfjs-dist`), so parsing a 300-page PDF never freezes scrolling or clicking.

---

## Step 1: Install pdfjs-dist

**The Target:** add the `pdfjs-dist` package to `greymatter-pdf`.

**The Concept:** `pdfjs-dist` is the packaged, npm-installable build of Mozilla's PDF.js — the same engine that powers PDF viewing inside Firefox. It has two halves: a **core** that parses PDF bytes into drawing instructions (this is the CPU-heavy part we push into the Worker), and a **display layer** that paints those instructions onto an HTML `<canvas>`.

**The Implementation:**

```bash
cd greymatter-pdf
npm install pdfjs-dist@4.6.82
```

We pin an exact version (rather than `^4.6.82`) because pdf.js ships a matching internal "API version" between its main package and its worker script — mismatches between them throw a hard runtime error. Pinning avoids that entirely during this tutorial.

**The Verification:**

```bash
npm ls pdfjs-dist
```

Expected output:
```
greymatter-pdf@0.1.0
└── pdfjs-dist@4.6.82
```

---

## Step 2: Copy the pdf.js worker script into `public/`

**The Target:** make pdf.js's own internal worker file available as a static asset.

**The Concept:** pdf.js *itself* internally uses a worker script (`pdf.worker.min.mjs`) to do its byte-parsing math. This is separate from — and runs inside — the Web Worker we're about to build; think of it as pdf.js bringing its own specialized tool that we mount inside our workshop. Next.js needs this file served as a plain static asset (not bundled/transformed) at a predictable URL, so we copy it into the `public/` directory, which Next.js serves as-is.

**The Implementation:**

```bash
mkdir -p public/pdf
cp node_modules/pdfjs-dist/build/pdf.worker.min.mjs public/pdf/pdf.worker.min.mjs
```

Add this copy step to `package.json` so it survives fresh installs (e.g., on a teammate's machine or in CI). Open `package.json` and update the `scripts` block:

### `greymatter-pdf/package.json` (scripts section only — merge into your existing file)

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "npm run copy:pdf-worker && next build",
    "start": "next start",
    "lint": "eslint",
    "copy:pdf-worker": "node scripts/copy-pdf-worker.mjs"
  }
}
```

Now create the small Node.js script that performs the copy (so it's cross-platform, unlike a raw `cp` shell command which fails on Windows):

### `greymatter-pdf/scripts/copy-pdf-worker.mjs`

```javascript
// This script copies pdf.js's internal worker file into the public/
// directory so Next.js can serve it as a static asset at a stable URL
// (/pdf/pdf.worker.min.mjs). We run it before every build and also once
// manually right now, so local development has the file immediately.
import { copyFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, "..");

const source = join(
  projectRoot,
  "node_modules/pdfjs-dist/build/pdf.worker.min.mjs"
);
const destinationDir = join(projectRoot, "public/pdf");
const destination = join(destinationDir, "pdf.worker.min.mjs");

async function main() {
  await mkdir(destinationDir, { recursive: true });
  await copyFile(source, destination);
  console.log(`[copy:pdf-worker] Copied pdf.js worker to ${destination}`);
}

main().catch((error) => {
  console.error("[copy:pdf-worker] Failed to copy pdf.js worker:", error);
  process.exit(1);
});
```

**The Verification:**

```bash
npm run copy:pdf-worker
ls -la public/pdf/
```

Expected output: a file listing showing `pdf.worker.min.mjs` with a non-zero file size (it should be several hundred KB).

---

## Step 3: Define shared TypeScript types for worker messages

**The Target:** `src/types/pdf-worker.ts`

**The Concept:** Our Web Worker and our React component will talk to each other by sending plain JavaScript objects back and forth (this is literally the only way threads communicate — there's no shared memory by default). Think of it like two people passing notes under a door: they need to agree in advance on the note's format, or neither side can understand what's written. We define that "note format" as TypeScript types now, so both sides of the door — the worker file (Step 4) and the React hook (Step 5) — share one source of truth and the compiler catches mismatches for us.

**The Implementation:**

### `src/types/pdf-worker.ts`

```typescript
// Messages sent FROM the main thread TO the worker.
export type PdfWorkerRequest =
  | {
      type: "LOAD_DOCUMENT";
      requestId: string;
      // We pass the raw PDF bytes as a Transferable ArrayBuffer rather than
      // a copy, so the (potentially large) buffer moves ownership to the
      // worker instantly instead of being cloned in memory twice.
      arrayBuffer: ArrayBuffer;
    }
  | {
      type: "RENDER_PAGE";
      requestId: string;
      pageNumber: number; // 1-indexed, matching pdf.js's own convention
      scale: number; // zoom level multiplier, e.g. 1.5 = 150%
      devicePixelRatio: number; // screen sharpness multiplier, explained in Step 6
    };

// Messages sent FROM the worker BACK TO the main thread.
export type PdfWorkerResponse =
  | {
      type: "DOCUMENT_LOADED";
      requestId: string;
      numPages: number;
    }
  | {
      type: "PAGE_RENDERED";
      requestId: string;
      pageNumber: number;
      // ImageBitmap is a highly efficient, GPU-friendly image format that
      // can be transferred between threads almost for free (no copying),
      // unlike a regular array of pixel data.
      bitmap: ImageBitmap;
      widthCss: number; // the CSS pixel width the <canvas> element should be
      heightCss: number; // the CSS pixel height the <canvas> element should be
    }
  | {
      type: "ERROR";
      requestId: string;
      message: string;
    };
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors printed (a clean TypeScript compile check). If you see an error about `ImageBitmap` not being found, confirm your `tsconfig.json`'s `lib` array includes `"DOM"` (it does by default in a fresh `create-next-app` project).

---

## Step 4: Write the Web Worker itself

**The Target:** `src/workers/pdf.worker.ts`

**The Concept:** This file is the "second chef in the back room" from our earlier analogy. It never touches React, never touches the DOM directly — it only knows how to (a) receive a request, (b) do the heavy lifting with pdf.js, and (c) send a response back. Because it runs on a separate thread, any amount of computation here — even for a huge document — cannot freeze the buttons and scrollbars the user is touching.

**The Implementation:**

### `src/workers/pdf.worker.ts`

```typescript
// This file runs in a dedicated Web Worker thread, NOT in the browser's
// main thread. It has no access to the DOM (no document, no window.alert,
// etc.) but it can do heavy computation freely without affecting UI
// responsiveness.
import * as pdfjsLib from "pdfjs-dist";
import type {
  PdfWorkerRequest,
  PdfWorkerResponse,
} from "@/types/pdf-worker";

// pdf.js needs to know where its own internal worker script lives. Even
// though WE are already inside a worker, pdf.js's core library still wants
// this configured — it uses it to spin up further internal parsing logic.
pdfjsLib.GlobalWorkerOptions.workerSrc = "/pdf/pdf.worker.min.mjs";

// We keep the loaded PDF document in memory here, inside the worker, across
// multiple render requests -- re-parsing the whole file on every single
// page scroll would be wasteful.
let loadedDocument: pdfjsLib.PDFDocumentProxy | null = null;

// Type-safe helper to post a message back to the main thread. The second
// argument (`transfer`) is a list of objects to hand over by reference
// instead of copying -- critical for performance with large ImageBitmaps.
function respond(message: PdfWorkerResponse, transfer: Transferable[] = []) {
  // `self` refers to the worker's own global scope (its version of `window`).
  self.postMessage(message, { transfer });
}

self.onmessage = async (event: MessageEvent<PdfWorkerRequest>) => {
  const request = event.data;

  try {
    if (request.type === "LOAD_DOCUMENT") {
      // pdfjsLib.getDocument accepts the raw bytes and returns a "loading
      // task" we must await to get the actual document proxy object.
      const loadingTask = pdfjsLib.getDocument({
        data: request.arrayBuffer,
      });
      loadedDocument = await loadingTask

      // pdfjsLib.getDocument accepts the raw bytes and returns a "loading
      // task" we must await to get the actual document proxy object.
      const loadingTask = pdfjsLib.getDocument({
        data: request.arrayBuffer,
      });
      loadedDocument = await loadingTask.promise;

      respond({
        type: "DOCUMENT_LOADED",
        requestId: request.requestId,
        numPages: loadedDocument.numPages,
      });
      return;
    }

    if (request.type === "RENDER_PAGE") {
      if (!loadedDocument) {
        throw new Error(
          "RENDER_PAGE was requested before any document finished loading."
        );
      }

      // Fetch the specific page object. pdf.js pages are 1-indexed to match
      // how humans refer to "page 1", not how arrays are indexed.
      const page = await loadedDocument.getPage(request.pageNumber);

      // A "viewport" in pdf.js describes the pixel dimensions and transform
      // matrix needed to render the page at a given zoom (scale). We
      // multiply by devicePixelRatio here so the bitmap has enough real
      // pixels to look sharp on high-density ("Retina") screens -- more on
      // this in Step 6, where we explain devicePixelRatio in depth.
      const viewport = page.getViewport({
        scale: request.scale * request.devicePixelRatio,
      });

      // OffscreenCanvas is a canvas-like object usable inside a Worker
      // (a regular <canvas> DOM element cannot exist here, since Workers
      // have no DOM access at all).
      const offscreenCanvas = new OffscreenCanvas(
        viewport.width,
        viewport.height
      );
      const context = offscreenCanvas.getContext("2d");
      if (!context) {
        throw new Error("Could not acquire a 2D rendering context.");
      }

      // This is the actual heavy lifting: pdf.js walks the page's vector
      // drawing instructions (lines, curves, text glyphs, images) and
      // paints them onto our OffscreenCanvas. This is the exact operation
      // that would freeze the main thread if we ran it there directly.
      await page.render({
        canvasContext: context as unknown as CanvasRenderingContext2D,
        viewport,
      }).promise;

      // Convert the finished drawing into an ImageBitmap -- a format
      // optimized for cheap, zero-copy transfer between threads.
      const bitmap = await offscreenCanvas.transferToImageBitmap();

      respond(
        {
          type: "PAGE_RENDERED",
          requestId: request.requestId,
          pageNumber: request.pageNumber,
          bitmap,
          // We report back the CSS size (unscaled by devicePixelRatio) so
          // the main thread knows what size to set the <canvas> element's
          // CSS width/height to, keeping it visually correct on screen
          // regardless of how many actual pixels the bitmap contains.
          widthCss: viewport.width / request.devicePixelRatio,
          heightCss: viewport.height / request.devicePixelRatio,
        },
        [bitmap] // transfer ownership of the bitmap, not a copy
      );
      return;
    }
  } catch (error) {
    respond({
      type: "ERROR",
      requestId: request.requestId,
      message: error instanceof Error ? error.message : "Unknown worker error.",
    });
  }
};

// This empty export turns the file into an ES module, which is required
// for the `import * as pdfjsLib` syntax at the top to work correctly when
// this file is loaded as a module-type Worker (see Step 5 for how we
// instantiate it with { type: "module" }).
export {};
```

**The Verification:** we can't fully test a Worker file in isolation yet — it needs a component to talk to it. Skip ahead to Step 6's verification, which exercises this file end-to-end. For now, just confirm it compiles cleanly:

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 5: Build a React hook that owns the Worker's lifecycle

**The Target:** `src/lib/pdf/use-pdf-worker.ts`

**The Concept:** Somebody needs to be responsible for *starting* the worker, sending it messages, and *shutting it down* when the user navigates away (otherwise we'd leak background threads forever, like leaving the kitchen's oven on after closing). A React **custom hook** is a reusable function that lets us package this "worker lifecycle management" logic once and reuse it in any component. Think of it as a dedicated phone line installed between our React component and the worker's back room — this hook wires up the phone and hands the receiver to whoever needs it.

**The Implementation:**

### `src/lib/pdf/use-pdf-worker.ts`

```typescript
"use client";

import { useEffect, useRef, useCallback } from "react";
import type {
  PdfWorkerRequest,
  PdfWorkerResponse,
} from "@/types/pdf-worker";

// Each request we send gets a unique ID so that when a response comes back,
// we know exactly which pending request it answers -- similar to a coat
// check ticket number, since messages can arrive out of order.
function createRequestId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

type PendingResolvers = Map<
  string,
  {
    resolve: (response: PdfWorkerResponse) => void;
    reject: (error: Error) => void;
  }
>;

export function usePdfWorker() {
  const workerRef = useRef<Worker | null>(null);
  const pendingRef = useRef<PendingResolvers>(new Map());

  useEffect(() => {
    // `new URL(..., import.meta.url)` combined with `{ type: "module" }` is
    // the standard, bundler-friendly way to construct a Worker in a modern
    // Next.js / Turbopack project. Turbopack detects this exact pattern at
    // build time and bundles src/workers/pdf.worker.ts as its own separate
    // JavaScript file, then wires up the URL correctly for production.
    const worker = new Worker(
      new URL("../../workers/pdf.worker.ts", import.meta.url),
      { type: "module" }
    );

    worker.onmessage = (event: MessageEvent<PdfWorkerResponse>) => {
      const response = event.data;
      const pending = pendingRef.current.get(response.requestId);
      if (!pending) return; // response for a request we no longer care about

      pendingRef.current.delete(response.requestId);

      if (response.type === "ERROR") {
        pending.reject(new Error(response.message));
      } else {
        pending.resolve(response);
      }
    };

    worker.onerror = (event) => {
      // A top-level worker crash (e.g. a syntax error) has no requestId to
      // match, so we reject every currently pending request.
      pendingRef.current.forEach(({ reject }) =>
        reject(new Error(event.message))
      );
      pendingRef.current.clear();
    };

    workerRef.current = worker;

    // Cleanup: terminate the worker thread when the component using this
    // hook unmounts, so we never leak background threads.
    return () => {
      worker.terminate();
      workerRef.current = null;
    };
  }, []);

  // A generic "send request, await matching response" helper. Every actual
  // call site (loadDocument, renderPage below) is built on top of this.
  const sendRequest = useCallback(
    (request: PdfWorkerRequest, transfer: Transferable[] = []) => {
      return new Promise<PdfWorkerResponse>((resolve, reject) => {
        const worker = workerRef.current;
        if (!worker) {
          reject(new Error("PDF worker is not initialized yet."));
          return;
        }
        pendingRef.current.set(request.requestId, { resolve, reject });
        worker.postMessage(request, { transfer });
      });
    },
    []
  );

  const loadDocument = useCallback(
    async (arrayBuffer: ArrayBuffer) => {
      const requestId = createRequestId();
      const response = await sendRequest(
        { type: "LOAD_DOCUMENT", requestId, arrayBuffer },
        [arrayBuffer] // transfer the buffer, not copy it -- see Step 6 note
      );
      if (response.type !== "DOCUMENT_LOADED") {
        throw new Error("Unexpected response type for LOAD_DOCUMENT.");
      }
      return response.numPages;
    },
    [sendRequest]
  );

  const renderPage = useCallback(
    async (pageNumber: number, scale: number, devicePixelRatio: number) => {
      const requestId = createRequestId();
      const response = await sendRequest({
        type: "RENDER_PAGE",
        requestId,
        pageNumber,
        scale,
        devicePixelRatio,
      });
      if (response.type !== "PAGE_RENDERED") {
        throw new Error("Unexpected response type for RENDER_PAGE.");
      }
      return response;
    },
    [sendRequest]
  );

  return { loadDocument, renderPage };
}
```

Note for readers coming from older React tutorials: you'll notice we still used `useCallback` here, even though Part 1 said the React Compiler removes the *need* for manual memoization in components. This file is a plain hook, not a component the compiler analyzes for render-skipping — and more importantly, these functions are returned to consumers and used inside other hooks' dependency arrays (like `useEffect` in Step 6), where stable function identity still matters for correctness, not just performance. The compiler optimizes *rendering*; it doesn't remove the general usefulness of `useCallback` for API design. From Part 4 onward, inside actual *components*, you'll see us lean on the compiler and stop hand-writing these.

**The Verification:** again, this hook needs a consuming component to be testable — continue to Step 6.

---

## Step 6: The canvas-rendering React component

**The Target:** `src/components/viewer/PdfPageCanvas.tsx`

**The Concept:** This is where pixels finally hit the screen. Two tricky ideas need explaining before the code:

1. **`devicePixelRatio`**: Your screen has a certain number of *actual* physical pixels, but CSS/browser layout talks in "CSS pixels," which on high-density ("Retina"/4K) screens represent *multiple* physical pixels each. `window.devicePixelRatio` tells us that multiplier (commonly 1, 2, or 3). If we render our PDF bitmap at only 1x resolution but display it on a 2x screen, text looks blurry — like stretching a small photo to fill a big frame. So we ask the worker to render at `scale * devicePixelRatio` real pixels, then use CSS to display it back down at the correct on-screen size, giving us crisp, sharp text.

2. **Canvas arrays for scroll-heavy layouts**: rather than one giant canvas for an entire multi-page document (which would be enormous and slow to redraw), we render one `<canvas>` element *per page*, and only actually render (fill with pixels) the pages that are near the visible scroll position, using a technique called **windowing** or **lazy rendering**. Think of it like a photo album where you only actually develop the photos on the pages you're currently looking at, plus a couple pages ahead/behind — not the entire 300-page album at once.

For this Part, we'll build the single-page canvas component and a basic multi-page container that renders every page's canvas element up front, but only triggers the actual worker `renderPage` call when a page scrolls near the viewport (using the browser's built-in `IntersectionObserver` API — a tool that tells you when an element enters or leaves the visible screen area).

**The Implementation:**

### `src/components/viewer/PdfPageCanvas.tsx`

```typescript
"use client";

import { useEffect, useRef, useState } from "react";
import { usePdfWorker } from "@/lib/pdf/use-pdf-worker";

interface PdfPageCanvasProps {
  pageNumber: number;
  scale: number;
  renderPage: ReturnType<typeof usePdfWorker>["renderPage"];
}

// Renders exactly one PDF page into its own <canvas> element. It only
// triggers the (expensive) worker render call once the canvas scrolls
// near the visible viewport, using IntersectionObserver.
export function PdfPageCanvas({
  pageNumber,
  scale,
  renderPage,
}: PdfPageCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const [hasRendered, setHasRendered] = useState(false);
  const [isNearViewport, setIsNearViewport] = useState(false);

  // Step A: watch whether this page's placeholder div is near the screen.
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0];
        if (entry.isIntersecting) {
          setIsNearViewport(true);
        }
      },
      {
        // rootMargin extends the "visible" zone by 600px above and below
        // the actual screen edges, so pages start rendering just before
        // the user scrolls to them -- avoiding a visible blank flash.
        rootMargin: "600px 0px 600px 0px",
      }
    );

    observer.observe(container);
    return () => observer.disconnect();
  }, []);

  // Step B: once near the viewport (and not already rendered), ask the
  // worker to render this page, then paint the returned bitmap onto our
  // real, on-screen <canvas> element.
  useEffect(() => {
    if (!isNearViewport || hasRendered) return;

    let cancelled = false;

    async function renderThisPage() {
      const devicePixelRatio = window.devicePixelRatio || 1;
      const result = await renderPage(pageNumber, scale, devicePixelRatio);

      // If the component unmounted or scrolled away while we were waiting
      // on the worker, discard the result instead of touching a stale DOM node.
      if (cancelled) return;

      const canvas = canvasRef.current;
      if (!canvas) return;

      // Set the canvas's actual pixel buffer size to the full-resolution
      // bitmap dimensions (this is the "physical pixels" count)...
      canvas.width = result.bitmap.width;
      canvas.height = result.bitmap.height;

      // ...but set its CSS display size back down to the intended
      // on-screen size, so it appears correctly sized despite containing
      // extra pixels for sharpness.
      canvas.style.width = `${result.widthCss}px`;
      canvas.style.height = `${result.heightCss}px`;

      const context = canvas.getContext("2d");
      if (!context) return;
      context.drawImage(result.bitmap, 0, 0);

      // ImageBitmap objects hold GPU/graphics memory that must be
      // explicitly released once we're done painting it, otherwise we leak
      // memory on every page render.
      result.bitmap.close();

      setHasRendered(true);
    }

    renderThisPage().catch((error) => {
      console.error(`Failed to render page ${pageNumber}:`, error);
    });

    return () => {
      cancelled = true;
    };
  }, [isNearViewport, hasRendered, pageNumber, scale, renderPage]);

  return (
    <div
      ref={containerRef}
      className="mb-4 flex justify-center bg-gray-100 min-h-[400px]"
      data-page-number={pageNumber}
    >
      <canvas ref={canvasRef} className="shadow-md bg-white" />
    </div>
  );
}
```

### `src/components/viewer/PdfDocumentViewer.tsx`

```typescript
"use client";

import { useEffect, useState } from "react";
import { usePdfWorker } from "@/lib/pdf/use-pdf-worker";
import { PdfPageCanvas } from "./PdfPageCanvas";

interface PdfDocumentViewerProps {
  // For this Part, we accept a direct URL to fetch bytes from. Part 3
  // replaces this with a request through our secure proxy.ts layer instead
  // of a raw public URL.
  fileUrl: string;
}

export function PdfDocumentViewer({ fileUrl }: PdfDocumentViewerProps) {
  const { loadDocument, renderPage } = usePdfWorker();
  const [numPages, setNumPages] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const scale = 1.25; // a fixed baseline zoom for this Part; Part 4 makes this adjustable

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        const response = await fetch(fileUrl);
        if (!response.ok) {
          throw new Error(`Failed to fetch PDF: ${response.status}`);
        }
        const arrayBuffer = await response.arrayBuffer();
        const pages = await loadDocument(arrayBuffer);
        if (!cancelled) setNumPages(pages);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Unknown error loading PDF.");
        }
      }
    }

    load();
    return () => {
      cancelled = true;
    };
  }, [fileUrl, loadDocument]);

  if (error) {
    return (
      <div className="p-4 text-red-600 bg-red-50 rounded">
        Could not load document: {error}
      </div>
    );
  }

  if (numPages === null) {
    return <div className="p-4 text-gray-500">Loading document…</div>;
  }

  return (
    <div className="w-full overflow-y-auto" style={{ height: "100vh" }}>
      {Array.from({ length: numPages }, (_, index) => (
        <PdfPageCanvas
          key={index + 1}
          pageNumber={index + 1}
          scale={scale}
          renderPage={renderPage}
        />
      ))}
    </div>
  );
}
```

## Step 7: Wire it into a route

**The Target:** `src/app/viewer/[documentId]/page.tsx`

**The Concept:** This is a Server Component (no `"use client"` directive) — it runs on the server, and its only job here is to pass a URL down into our Client Component. Keeping this file server-only matters later: Part 3 will have this Server Component look up permissions and build a signed proxy URL server-side before ever handing anything to the browser.

**The Implementation:**

```typescript
import { PdfDocumentViewer } from "@/components/viewer/PdfDocumentViewer";

export default async function ViewerPage({
  params,
}: {
  params: Promise<{ documentId: string }>;
}) {
  const { documentId } = await params;

  // Temporary for this Part only: a hardcoded public sample PDF, so we can
  // verify our rendering pipeline end-to-end before Part 3 introduces real,
  // secured document storage.
  const fileUrl = `/sample-pdfs/${documentId}.pdf`;

  return (
    <main className="min-h-screen bg-gray-50">
      <PdfDocumentViewer fileUrl={fileUrl} />
    </main>
  );
}
```

**The Verification (end-to-end test of this entire Part):**

1. Download any small sample PDF and place it at `public/sample-pdfs/demo.pdf`.
2. Run:
```bash
npm run dev
```
3. Open `http://localhost:3000/viewer/demo` in your browser.
4. **Expected result:** the PDF's pages render as sharp images on screen, scrolling is smooth, and if you open your browser's DevTools → Performance tab and scroll while recording, the "Main" thread track shows little to no long "Task" blocks during rendering — confirming the heavy work happened on the Worker thread instead.
5. Open DevTools → Application/Sources → check for a separate `pdf.worker.ts` (or its compiled equivalent) thread listed, confirming the Worker is genuinely active.

---

## Part 2 Summary

We installed `pdfjs-dist`, served its internal worker script as a static asset, defined a typed message contract between threads, wrote a dedicated Web Worker that parses and rasterizes PDF pages entirely off the main thread, built a React hook to manage that worker's lifecycle safely, and rendered pages into individually-observed `<canvas>` elements that respect device pixel ratio and only render near the viewport. Part 3 replaces our temporary public `fileUrl` with a secure, authenticated `proxy.ts` byte-streaming layer.

