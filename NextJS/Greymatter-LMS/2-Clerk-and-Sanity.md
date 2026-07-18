# Part 2: Multi-Threaded Client-Side Rendering via Web Workers

*(Phase 1 — Core Architecture and High-Performance Rendering)*

## Why this part exists

In Part 1 we established a rule: never parse PDF vector graphics on the browser's main thread. Here is why, with an analogy.

Imagine a single waiter (the main thread) who must do two jobs at once: take orders from customers (respond to clicks, scrolling, typing) and personally chop vegetables in the back (parse thousands of PDF drawing instructions). If the waiter is chopping vegetables, they cannot hear a customer calling for the bill — the whole restaurant appears frozen. A Web Worker is like hiring a second person dedicated only to chopping vegetables, in a separate room, who hands finished plates back to the waiter when ready. The waiter stays free to serve customers the entire time.

Technically: a Web Worker is a background JavaScript thread the browser provides. It cannot touch the DOM directly, but it can do CPU-heavy computation and message the main thread when done. We use one to run pdf.js (Mozilla's PDF parsing/rendering engine, distributed as the npm package `pdfjs-dist`), so parsing a 300-page PDF never freezes scrolling or clicking.

---

## Step 1: Install pdfjs-dist

**The Target:** add the `pdfjs-dist` package to `greymatter-pdf`.

**The Concept:** `pdfjs-dist` is the packaged, npm-installable build of Mozilla's PDF.js. It has two halves: a core that parses PDF bytes into drawing instructions (the CPU-heavy part we push into the Worker), and a display layer that paints those instructions onto an HTML canvas.

**The Implementation:**

```bash
cd greymatter-pdf
npm install pdfjs-dist@4.6.82
```

We pin an exact version because pdf.js ships a matching internal API version between its main package and its worker script — mismatches throw a hard runtime error.

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

## Step 2: Copy the pdf.js worker script into public/

**The Target:** make pdf.js's own internal worker file available as a static asset.

**The Concept:** pdf.js internally uses a worker script (`pdf.worker.min.mjs`) to do its byte-parsing math. This is separate from the Web Worker we are about to build. Next.js needs this file served as a plain static asset at a predictable URL, so we copy it into `public/`, which Next.js serves as-is.

**The Implementation:**

```bash
mkdir -p public/pdf
cp node_modules/pdfjs-dist/build/pdf.worker.min.mjs public/pdf/pdf.worker.min.mjs
```

Add this copy step to `package.json` so it survives fresh installs on any machine or CI:

### `greymatter-pdf/package.json` (scripts section only)

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

### `greymatter-pdf/scripts/copy-pdf-worker.mjs`

```javascript
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

Expected output: `pdf.worker.min.mjs` listed with a non-zero file size.

---

## Step 3: Define shared TypeScript types for worker messages

**The Target:** `src/types/pdf-worker.ts`

**The Concept:** our Web Worker and React component talk to each other by sending plain JavaScript objects — the only way threads communicate, since there is no shared memory by default. Like two people passing notes under a door, both sides need to agree on the note's format in advance. We define that format as TypeScript types now.

**The Implementation:**

### `src/types/pdf-worker.ts`

```typescript
// Messages sent FROM the main thread TO the worker.
export type PdfWorkerRequest =
  | {
      type: "LOAD_DOCUMENT";
      requestId: string;
      arrayBuffer: ArrayBuffer;
    }
  | {
      type: "RENDER_PAGE";
      requestId: string;
      pageNumber: number;
      scale: number;
      devicePixelRatio: number;
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
      bitmap: ImageBitmap;
      widthCss: number;
      heightCss: number;
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

Expected output: no errors printed.

---

## Step 4: Write the Web Worker itself

**The Target:** `src/workers/pdf.worker.ts`

**The Concept:** this file is the second chef in the back room. It never touches React or the DOM directly — it only receives a request, does the heavy lifting with pdf.js, and sends a response back. Because it runs on a separate thread, any amount of computation here cannot freeze the buttons and scrollbars the user is touching.

**The Implementation:**

### `src/workers/pdf.worker.ts`

```typescript
// This file runs in a dedicated Web Worker thread, NOT in the browser's
// main thread. It has no access to the DOM but can do heavy computation
// freely without affecting UI responsiveness.
import * as pdfjsLib from "pdfjs-dist";
import type {
  PdfWorkerRequest,
  PdfWorkerResponse,
} from "@/types/pdf-worker";

// pdf.js needs to know where its own internal worker script lives.
pdfjsLib.GlobalWorkerOptions.workerSrc = "/pdf/pdf.worker.min.mjs";

// We keep the loaded PDF document in memory here, across multiple render
// requests -- re-parsing the whole file on every page scroll would waste
// CPU time.
let loadedDocument: pdfjsLib.PDFDocumentProxy | null = null;

function respond(message: PdfWorkerResponse, transfer: Transferable[] = []) {
  self.postMessage(message, { transfer });
}

self.onmessage = async (event: MessageEvent<PdfWorkerRequest>) => {
  const request = event.data;

  try {
    if (request.type === "LOAD_DOCUMENT") {
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

      const page = await loadedDocument.getPage(request.pageNumber);

      // Multiply by devicePixelRatio so the bitmap has enough real pixels
      // to look sharp on high-density screens -- explained in depth in
      // Step 6.
      const viewport = page.getViewport({
        scale: request.scale * request.devicePixelRatio,
      });

      // OffscreenCanvas is a canvas-like object usable inside a Worker;
      // a regular <canvas> DOM element cannot exist here.
      const offscreenCanvas = new OffscreenCanvas(
        viewport.width,
        viewport.height
      );
      const context = offscreenCanvas.getContext("2d");
      if (!context) {
        throw new Error("Could not acquire a 2D rendering context.");
      }

      // This is the heavy lifting: pdf.js walks the page's vector drawing
      // instructions and paints them onto our OffscreenCanvas.
      await page.render({
        canvasContext: context as unknown as CanvasRenderingContext2D,
        viewport,
      }).promise;

      const bitmap = await offscreenCanvas.transferToImageBitmap();

      respond(
        {
          type: "PAGE_RENDERED",
          requestId: request.requestId,
          pageNumber: request.pageNumber,
          bitmap,
          widthCss: viewport.width / request.devicePixelRatio,
          heightCss: viewport.height / request.devicePixelRatio,
        },
        [bitmap]
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

// This empty export turns the file into an ES module, required for the
// import syntax above to work when this file is loaded as a module-type
// Worker (see Step 5).
export {};
```

**The Verification:** a Worker file cannot be fully tested in isolation — it needs a component to talk to it (Step 6). For now, confirm it compiles cleanly:

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 5: Build a React hook that owns the Worker's lifecycle

**The Target:** `src/lib/pdf/use-pdf-worker.ts`

**The Concept:** somebody needs to be responsible for starting the worker, sending it messages, and shutting it down when the user navigates away, otherwise we would leak background threads forever, like leaving an oven on after closing. A React custom hook is a reusable function that packages this lifecycle management once, for reuse in any component. Think of it as a dedicated phone line installed between our React component and the worker's back room — this hook wires up the phone and hands the receiver to whoever needs it.

**The Implementation:**

### `src/lib/pdf/use-pdf-worker.ts`

```typescript
"use client";

import { useEffect, useRef, useCallback } from "react";
import type {
  PdfWorkerRequest,
  PdfWorkerResponse,
} from "@/types/pdf-worker";

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
    // new URL(..., import.meta.url) combined with { type: "module" } is the
    // standard, bundler-friendly way to construct a Worker in a modern
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
        [arrayBuffer] // transfer the buffer, not copy it
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

Note for readers: we still use `useCallback` here even though Part 1 said the React Compiler removes the need for manual memoization inside components. This file is a plain hook, not a component the compiler analyzes for render-skipping — these functions are returned to consumers and used inside other hooks' dependency arrays (like `useEffect` in Step 7), where stable function identity still matters for correctness, not just performance. From Part 4 onward, inside actual components, we lean on the compiler and stop hand-writing these.

**The Verification:** this hook needs a consuming component to be testable — continue to Step 6 and Step 7 below.

---

## Step 6: The canvas-rendering React component

**The Target:** `src/components/viewer/PdfPageCanvas.tsx`

**The Concept:** this is where pixels finally hit the screen. Two tricky ideas need explaining first.

**devicePixelRatio:** your screen has a certain number of actual physical pixels, but CSS/browser layout talks in "CSS pixels," which on high-density (Retina/4K) screens represent multiple physical pixels each. `window.devicePixelRatio` tells us that multiplier (commonly 1, 2, or 3). If we render our PDF bitmap at only 1x resolution but display it on a 2x screen, text looks blurry, like stretching a small photo to fill a big frame. So we ask the worker to render at `scale × devicePixelRatio` real pixels, then use CSS to display it back down at the correct on-screen size, giving us crisp, sharp text.

**Canvas arrays for scroll-heavy layouts:** rather than one giant canvas for an entire multi-page document (which would be enormous and slow to redraw), we render one canvas element per page. Each page component manages its own render lifecycle independently.

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

// One instance of this component is rendered per PDF page. Each owns a
// single <canvas> element and is responsible only for painting its own
// page -- this keeps memory and redraw cost proportional to visible pages,
// not the whole document.
export function PdfPageCanvas({
  pageNumber,
  scale,
  renderPage,
}: PdfPageCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [isRendering, setIsRendering] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function draw() {
      setIsRendering(true);
      setError(null);
      try {
        // window.devicePixelRatio is only available in the browser, which
        // is exactly why this whole component must be a Client Component
        // ("use client" at the top) -- Server Components never run in a
        // browser context and would have no such value.
        const devicePixelRatio = window.devicePixelRatio || 1;
        const result = await renderPage(pageNumber, scale, devicePixelRatio);

        if (cancelled) return;

        const canvas = canvasRef.current;
        if (!canvas) return;

        // The bitmap itself contains devicePixelRatio-multiplied real
        // pixels (e.g. 2x as many on a Retina screen), but we set the
        // canvas's CSS width/height to the un-multiplied "widthCss"/
        // "heightCss" values, so it occupies the correct amount of visual
        // space on the page while still rendering crisply.
        canvas.width = result.bitmap.width;
        canvas.height = result.bitmap.height;
        canvas.style.width = `${result.widthCss}px`;
        canvas.style.height = `${result.heightCss}px`;

        const context = canvas.getContext("2d");
        if (!context) {
          throw new Error("Could not acquire a 2D context for the canvas.");
        }
        // Paints the already-rendered bitmap onto the visible <canvas> --
        // a cheap operation, since all the expensive parsing/drawing math
        // already happened inside the worker thread.
        context.drawImage(result.bitmap, 0, 0);
        result.bitmap.close(); // release the bitmap's memory once painted
      } catch (caughtError) {
        if (!cancelled) {
          setError(
            caughtError instanceof Error
              ? caughtError.message
              : "Failed to render page."
          );
        }
      } finally {
        if (!cancelled) setIsRendering(false);
      }
    }

    draw();

    return () => {
      cancelled = true;
    };
  }, [pageNumber, scale, renderPage]);

  return (
    <div className="relative mb-4 flex justify-center">
      {isRendering && (
        <div className="absolute inset-0 flex items-center justify-center bg-gray-100 text-sm text-gray-500">
          Rendering page {pageNumber}...
        </div>
      )}
      {error && (
        <div className="absolute inset-0 flex items-center justify-center bg-red-50 text-sm text-red-600">
          Error on page {pageNumber}: {error}
        </div>
      )}
      <canvas
        ref={canvasRef}
        className="border border-gray-200 shadow-sm"
        aria-label={`PDF page ${pageNumber}`}
      />
    </div>
  );
}
```

**The Verification:** this component still needs a parent that loads a document and passes down `renderPage` — continue to Step 7.

---

## Step 7: The multi-page viewer container

**The Target:** `src/components/viewer/PdfViewer.tsx`

**The Concept:** we need one top-level component that (a) loads the worker via `usePdfWorker`, (b) fetches the PDF's raw bytes, (c) tells the worker to parse the document once, and (d) renders one `PdfPageCanvas` per page in a scrollable list. Think of this component as the restaurant's host: it greets the incoming document, finds out how many pages (tables) exist, and seats a `PdfPageCanvas` at every one, letting each table (page) independently order and receive its own food (rendered bitmap) without waiting on the others.

**The Implementation:**

### `src/components/viewer/PdfViewer.tsx`

```typescript
"use client";

import { useEffect, useState } from "react";
import { usePdfWorker } from "@/lib/pdf/use-pdf-worker";
import { PdfPageCanvas } from "@/components/viewer/PdfPageCanvas";

interface PdfViewerProps {
  // For this Part, we accept a direct URL to a PDF file (e.g. something
  // temporarily placed in /public for testing). Part 3 replaces this with
  // a secure, authenticated proxy.ts URL instead of a raw public file path.
  fileUrl: string;
}

export function PdfViewer({ fileUrl }: PdfViewerProps) {
  const { loadDocument, renderPage } = usePdfWorker();
  const [numPages, setNumPages] = useState<number | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  // A fixed zoom level for this Part; Part 4 wires this up to a zoom
  // control the user can change.
  const [scale] = useState(1.25);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        // fetch() retrieves the PDF bytes over HTTP. We convert the
        // response to an ArrayBuffer because that is the exact format our
        // worker's LOAD_DOCUMENT message expects (see src/types/pdf-worker.ts).
        const response = await fetch(fileUrl);
        if (!response.ok) {
          throw new Error(
            `Failed to fetch PDF: ${response.status} ${response.statusText}`
          );
        }

        const arrayBuffer = await response.arrayBuffer();

        if (cancelled) return;

        const pages = await loadDocument(arrayBuffer);
        if (!cancelled) setNumPages(pages);
      } catch (error) {
        if (!cancelled) {
          setLoadError(
            error instanceof Error ? error.message : "Failed to load PDF."
          );
        }
      }
    }

    load();

    return () => {
      cancelled = true;
    };
  }, [fileUrl, loadDocument]);

  if (loadError) {
    return (
      <div className="p-4 text-sm text-red-600">
        Could not load document: {loadError}
      </div>
    );
  }

  if (numPages === null) {
    return <div className="p-4 text-sm text-gray-500">Loading document...</div>;
  }

  return (
    <div className="flex flex-col items-center overflow-y-auto p-4">
      {/* One canvas per page, in a simple vertical scroll -- Part 9 revisits
          this with virtualization (only rendering pages near the viewport)
          for very long documents, but a plain list is the right starting
          point for correctness first. */}
      {Array.from({ length: numPages }, (_, index) => index + 1).map(
        (pageNumber) => (
          <PdfPageCanvas
            key={pageNumber}
            pageNumber={pageNumber}
            scale={scale}
            renderPage={renderPage}
          />
        )
      )}
    </div>
  );
}
```

Now wire this into an actual route so we have something to open in a browser. Recall from Part 1 that `src/app/viewer/[documentId]` was already created as an empty directory reserved for this exact purpose.

### `src/app/viewer/[documentId]/page.tsx`

```typescript
// This file is a Server Component by default (no "use client" at the top).
// Its only job here is to render the page shell and hand off to the
// PdfViewer Client Component for actual interactivity -- exactly the
// division of responsibility established in Part 1.
import { PdfViewer } from "@/components/viewer/PdfViewer";

export default async function ViewerPage({
  params,
}: {
  params: Promise<{ documentId: string }>;
}) {
  const { documentId } = await params;

  // For this Part only, we point directly at a test file placed in public/.
  // Part 3 replaces this hardcoded path with a real lookup: documentId will
  // be used to find the correct file via our secure proxy.ts layer instead.
  const fileUrl = `/test-pdfs/${documentId}.pdf`;

  return (
    <main className="h-screen w-screen bg-gray-50">
      <PdfViewer fileUrl={fileUrl} />
    </main>
  );
}
```

**The Verification:**

1. Add a sample PDF for testing:

```bash
mkdir -p public/test-pdfs
# Copy any PDF file you have locally, naming it sample.pdf
cp ~/Downloads/some-file.pdf public/test-pdfs/sample.pdf
```

(If you don't have a sample PDF handy, any multi-page PDF works — an emailed invoice, a downloaded ebook sample, or a printed-to-PDF document from your OS all work fine for this test.)

2. Start the dev server:

```bash
npm run dev
```

3. Open your browser to:

```
http://localhost:3000/viewer/sample
```

Expected result: you should see "Loading document..." briefly, then each page of your PDF should appear one after another, rendered as sharp images inside bordered boxes, with a brief "Rendering page N..." placeholder flashing per page as it loads.

4. Confirm the main thread is not blocked: while the PDF is loading/rendering, try scrolling the page or resizing the browser window. It should remain responsive throughout, even for a large file — this is the entire point of Part 2's architecture.

5. Open your browser's DevTools (F12), go to the Network tab, and reload. You should see a request for `pdf.worker.min.mjs` succeed (status 200) — this confirms Step 2's static asset copy worked correctly.

6. In DevTools, go to the Console tab and confirm there are no red errors. A common early mistake is forgetting Step 2 (copying the `pdf.worker.min.mjs` file), which shows up as a 404 error for that file and a blank/broken viewer.

---

## Part 2 Summary

By this point you have: `pdfjs-dist` installed and correctly configured with its own internal worker script served as a static asset; a fully-typed message contract between the main thread and a Web Worker; the Web Worker itself, which loads PDF documents and renders individual pages to `ImageBitmap`s entirely off the main thread; a `usePdfWorker` hook that manages the worker's lifecycle safely (including cleanup on unmount); a `PdfPageCanvas` component that paints rendered bitmaps crisply regardless of screen pixel density; and a `PdfViewer` container that ties it all together into a scrollable, multi-page document view, reachable at `/viewer/[documentId]`.

Critically, you have now proven experimentally (not just in theory) that heavy PDF parsing does not freeze the browser tab — the core promise of the hybrid architecture from Part 1.

Part 3 replaces the temporary hardcoded `/test-pdfs/` file path with a secure, authenticated `proxy.ts` layer, so real PDF files are never exposed as raw public URLs, and are instead streamed through a permission-checked Node.js route.
