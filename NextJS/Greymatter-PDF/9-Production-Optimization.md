# Part 9: Production Optimizations, Caching, and Error Boundaries

*(Phase 4 — Office Document Conversion and Practical Production Operations)*

## Why this part exists

Parts 1–8 built every feature Greymatter PDF needs. This final part does not add new user-facing capability — instead, it hardens what already exists, so the application behaves well under real-world conditions: repeated requests for things that never change, large files that could exhaust server memory, and corrupted or unexpected data that could otherwise crash the entire app for every user, not just the one who triggered the problem.

Analogy: think of Parts 1–8 as building a complete, functioning restaurant — kitchen, dining room, menu, staff. This Part is the health inspection and fire-safety pass before opening night: making sure the walk-in fridge (caching) is not being restocked unnecessarily, that the kitchen does not catch fire if one dish is prepared badly (error boundaries), and that the kitchen does not grind to a halt if it receives a giant catering order (memory management for large files).

---

## 9.1 Applying `use cache` to invariant assets

**The Concept:** Next.js 16's `use cache` directive marks a function (or a whole file) so its return value is cached and reused across requests, rather than recomputed every single time. This is valuable specifically for data that is expensive to compute or fetch but rarely or never changes — Part 1's blueprint originally called out "corporate font tables, icons, and layout structural elements" as exactly this kind of invariant data.

**The Target:** apply `use cache` to a genuinely invariant, moderately expensive computation in Greymatter PDF — the list of a document's AcroForm field names and types (Part 7's `listFormFields`), which never changes for a given, already-uploaded document, yet currently re-parses the entire PDF from storage on every single call.

**The Implementation:**

### `src/server-actions/forms.ts` (add `"use cache"` to `listFormFields`, replacing the Part 7 version of this one function)

```typescript
// Add this import at the top of the file, alongside the existing imports:
import { unstable_cacheLife as cacheLife } from "next/cache";

// Replace Part 7's listFormFields with this cached version. The "use
// cache" directive as the FIRST LINE of the function body (not the top of
// the file, which would cache every export) tells Next.js to cache this
// specific function's return value, keyed automatically by its arguments
// (here, documentId) -- calling listFormFields("abc") a second time
// returns the cached result instantly instead of re-fetching and
// re-parsing the PDF from storage.
export async function listFormFields(documentId: string) {
  "use cache";
  cacheLife("days"); // a hint that this data is safe to keep cached for days,
                      // appropriate since a document's bytes never change
                      // once uploaded (Part 6 always creates a NEW document
                      // for any edit, never mutating an existing one)

  await getCurrentUserId();
  const bytes = await loadDocumentBytes(documentId);
  const pdfDoc = await PDFDocument.load(bytes);
  const form = pdfDoc.getForm();

  return form.getFields().map((field) => ({
    name: field.getName(),
    type: field.constructor.name,
  }));
}
```

Why this specific function is safe to cache, and why that safety matters: recall from Part 6 that every manipulation operation (merge, split, watermark, flatten) creates a **brand new** Document record with a new `documentId`, rather than mutating an existing document's bytes in place. This means "the set of form fields for documentId X" is truly invariant for the entire lifetime of that specific database row — there is no code path anywhere in Greymatter PDF that changes an existing document's bytes without also changing its ID. This invariant is precisely what makes caching here safe. Always verify this kind of true immutability before reaching for `use cache` — it is not a general-purpose speed-up switch, it is specifically for data that provably cannot change without also changing its cache key.

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors. To observe the caching behavior itself, add a temporary `console.log` at the top of the function body (after the cache directives) and call `listFormFields` twice with the same `documentId` within the cache's lifetime — the log should print only once, confirming the second call was served from cache without re-executing the function body.

---

## 9.2 Understanding where memory risk actually lives in Greymatter PDF

**The Concept:** recall from Part 6's `loadDocumentBytes` that we made a deliberate, explicitly-flagged exception to Part 3's streaming principle — pdf-lib requires a document's complete bytes in memory to parse its structure, so every merge/split/watermark/flatten/conversion operation holds at least one entire PDF file in server RAM at once. For a 5MB file, this is trivial. For a 500MB scanned archive or a merge of twenty large files simultaneously, this can genuinely exhaust a server's available memory, causing the Node.js process to crash — taking down every other user's in-progress request on that same server instance, not just the one large request. This section adds concrete, layered defenses against that risk.

---

## 9.3 Enforcing a maximum upload size at every entry point

**The Concept:** the cheapest, most effective memory protection is preventing dangerously large files from entering the system at all. We already raised Next.js's Server Action body size limit to 25mb back in Part 1 — that setting alone already rejects anything larger before our own code ever runs. This section adds an explicit, second layer of validation directly inside our own upload-handling code, so the limit is enforced with a clear, specific error message, and consistently across every upload path.

**The Target:** update `src/server-actions/documents.ts` and `src/server-actions/conversion.ts` to explicitly check file size.

**The Implementation:**

### `src/lib/pdf/limits.ts` (new shared constant, used by both upload paths)

```typescript
// Centralizing this number in one file means updating our size policy in
// the future requires changing exactly one line, not hunting across
// multiple Server Action files for hardcoded numbers.
export const MAX_UPLOAD_BYTES = 25 * 1024 * 1024; // 25 MB, matching Part 1's Server Action config

export function assertFileSizeAllowed(fileSizeBytes: number, fileLabel: string) {
  if (fileSizeBytes > MAX_UPLOAD_BYTES) {
    const maxMb = (MAX_UPLOAD_BYTES / (1024 * 1024)).toFixed(0);
    const actualMb = (fileSizeBytes / (1024 * 1024)).toFixed(1);
    throw new Error(
      `${fileLabel} is too large (${actualMb}MB). Maximum allowed size is ${maxMb}MB.`
    );
  }
}
```

### `src/server-actions/documents.ts` (add this check inside `uploadDocument`, right after the existing `file.type` check from Part 6)

```typescript
import { assertFileSizeAllowed } from "@/lib/pdf/limits";

// ... inside uploadDocument, after the existing "Only PDF files..." check:
assertFileSizeAllowed(file.size, "The uploaded PDF");
```

### `src/server-actions/conversion.ts` (add the same check inside `convertOfficeDocument`)

```typescript
import { assertFileSizeAllowed } from "@/lib/pdf/limits";

// ... inside convertOfficeDocument, after the existing SUPPORTED_OFFICE_TYPES check:
assertFileSizeAllowed(file.size, "The uploaded Office document");
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors. To test behaviorally, attempt to upload a file larger than 25MB through either upload form built in Part 6/Part 8 — confirm you now see this function's specific, human-readable error message in the status area, rather than a generic Next.js framework error.

---

## 9.4 Guarding merge operations against unbounded accumulation

**The Concept:** Part 6's `mergeDocuments` loop loads each source document's bytes one at a time, which is good — but the growing `mergedPdf` object itself still accumulates every page from every source document in memory as the loop proceeds. Merging twenty 20MB files could still peak at several hundred megabytes of combined in-memory structure, even though no single file exceeds our per-file limit. We add an explicit cap on the number of documents mergeable in one operation.

**The Target:** update `src/server-actions/page-operations.ts`

**The Implementation:**

### `src/server-actions/page-operations.ts` (add this check inside `mergeDocuments`, replacing the Part 6 version's initial validation)

```typescript
const MAX_MERGE_DOCUMENT_COUNT = 10;

// ... inside mergeDocuments, replacing Part 6's simple "at least two" check:
if (documentIds.length < 2) {
  throw new Error("At least two documents are required to merge.");
}
if (documentIds.length > MAX_MERGE_DOCUMENT_COUNT) {
  throw new Error(
    `Cannot merge more than ${MAX_MERGE_DOCUMENT_COUNT} documents in a single operation.`
  );
}
```

Why a count-based cap rather than a total-byte-size cap: a byte-total check would technically be more precise, but requires fetching every file's size upfront (an extra round trip per file before any real work starts). A simple count cap combined with the existing Section 9.3 per-file size cap achieves a predictable worst-case bound (10 files × 25MB max each = 250MB theoretical ceiling) with much simpler code — a reasonable, explicit tradeoff for this series, and one you could tighten further in a real production deployment based on your server's actual available memory.

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## 9.5 Monitoring Node.js memory in development

**The Concept:** it is useful to actually observe memory behavior rather than just reason about it abstractly. Node.js exposes `process.memoryUsage()`, letting us log how much memory a heavy operation actually consumes.

**The Implementation:**

```typescript
// Temporary diagnostic code -- remove before shipping, or gate behind a
// debug environment variable if you want to keep it available for
// future troubleshooting.
function logMemoryUsage(label: string) {
  const usage = process.memoryUsage();
  console.log(
    `[memory:${label}] heapUsed=${(usage.heapUsed / 1024 / 1024).toFixed(1)}MB rss=${(usage.rss / 1024 / 1024).toFixed(1)}MB`
  );
}

// Call logMemoryUsage("before-merge") right before the merge loop starts,
// and logMemoryUsage("after-merge") right after saveResultAsNewDocument
// completes, to observe the actual memory delta a real merge operation
// causes on your machine.
```

**The Verification:** run a merge operation with the logging above in place and confirm the terminal output shows `heapUsed` and `rss` (resident set size — the total memory the OS has allocated to the Node.js process) increasing by a plausible amount proportional to the input files' combined size, then decreasing again after garbage collection runs on a subsequent request (Node.js does not always immediately reclaim memory the instant an operation finishes — this is normal, expected behavior, not a leak).

---

## 9.6 Understanding Error Boundaries

**The Concept:** by default, an uncaught JavaScript error thrown anywhere inside a React component tree unmounts the **entire tree** — a single corrupted PDF byte stream causing pdf.js (Part 2) to throw partway through parsing could otherwise blank out the whole application shell, not just the one broken viewer. An **Error Boundary** is a special React component that catches errors thrown by its children during rendering, and displays a fallback UI instead of letting the crash propagate further up the tree. Next.js's App Router has a built-in convention for this: a file named `error.tsx` placed alongside a route's `page.tsx` automatically wraps that route in an Error Boundary.

Analogy: think of an Error Boundary as a fuse box for one specific room in a house — if something short-circuits inside that room, the fuse for that room trips and cuts power there, but every other room's lights stay on. Without fuse boxes (Error Boundaries), a single short circuit anywhere would black out the entire house.

---

## 9.7 Adding a route-level Error Boundary for the viewer

**The Target:** `src/app/viewer/[documentId]/error.tsx`

**The Concept:** this file automatically wraps our Part 3 viewer route. If anything inside `PdfViewer`, `PdfPageCanvas`, or the Web Worker communication throws an uncaught error during rendering, this fallback UI displays instead of a blank white screen, and the rest of the application (navigation, other open tabs, etc.) remains completely unaffected.

**The Implementation:**

### `src/app/viewer/[documentId]/error.tsx`

```typescript
"use client";

// error.tsx files MUST be Client Components -- Next.js's error boundary
// mechanism relies on React lifecycle features only available in the
// browser, so "use client" is required here even though most of our
// route files default to Server Components.
import { useEffect } from "react";

interface ErrorPageProps {
  error: Error & { digest?: string };
  reset: () => void; // provided by Next.js -- calling this attempts to re-render the route from scratch
}

export default function ViewerError({ error, reset }: ErrorPageProps) {
  useEffect(() => {
    // Log the error for our own visibility. In a real production
    // deployment, this is exactly where you would forward the error to a
    // monitoring service (e.g. Sentry) instead of just the console.
    console.error("Viewer route error:", error);
  }, [error]);

  return (
    <div className="flex h-screen w-screen flex-col items-center justify-center gap-4 bg-gray-50 p-6 text-center">
      <div className="text-4xl">⚠️</div>
      <h1 className="text-lg font-semibold text-gray-900">
        This document could not be displayed
      </h1>
      <p className="max-w-md text-sm text-gray-600">
        The file may be corrupted, incomplete, or in a format our viewer
        does not support. Your other documents and data are completely
        unaffected by this issue.
      </p>
      <div className="flex gap-3">
        <button
          onClick={reset}
          className="rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white"
        >
          Try again
        </button>
        <a
          href="/documents"
          className="rounded bg-gray-200 px-4 py-2 text-sm font-medium text-gray-800"
        >
          Back to documents
        </a>
      </div>
    </div>
  );
}
```

Why "Your other documents and data are completely unaffected" is a true, verifiable claim and not just reassuring copy: because this Error Boundary is scoped to exactly the `/viewer/[documentId]` route segment, any error thrown while rendering this specific document's viewer cannot propagate to and unmount the `DocumentManager` page (Part 6), the annotation Server Actions (Part 5), or any other document's own viewer instance open in a different tab — each is an entirely separate React tree/request, not sharing any in-memory state that a crash here could corrupt.

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## 9.8 Making the Web Worker's errors actually catchable

**The Concept:** there is a subtlety worth calling out explicitly: React Error Boundaries only catch errors thrown **during React's own rendering process**. Recall from Part 2 that our Web Worker communicates via asynchronous `postMessage` callbacks — an error thrown inside an async callback (like our `worker.onerror` handler, or a rejected Promise from `renderPage`) does **NOT** automatically propagate to React's rendering cycle, and so does **NOT** get caught by an Error Boundary on its own. Part 2's `PdfPageCanvas` already handles this correctly by catching the rejected Promise and storing the message in its own error state (rendered as an inline message, not a full crash) — but it is worth explicitly confirming why this matters: if `PdfPageCanvas` did NOT catch that rejection itself, the error would become an "unhandled promise rejection" that might not trigger the Error Boundary at all, potentially leaving a silently broken UI with no visible error message whatsoever — which is worse than a full crash, because it is undiagnosable by the user.

**The Target:** confirm (no new code needed — this is a verification of existing Part 2 code) that `PdfPageCanvas`'s existing try/catch around `renderPage` correctly surfaces errors without relying on the new `error.tsx` boundary at all for this specific failure mode, and that `error.tsx` exists as a second, deeper safety net for errors that occur elsewhere in the render tree (e.g. a bug in `AnnotationOverlay`'s coordinate math causing a rendering-time exception, which **is** the kind of error React Error Boundaries directly catch).

**The Verification:** temporarily introduce a deliberate bug into `AnnotationOverlay.tsx` (from Part 4) — for example, change `pageWidthCss` to `pageWidthCss.nonExistentProperty` in the JSX, which throws a `TypeError` during React's render. Reload the viewer page and confirm `error.tsx`'s fallback UI appears (rather than a blank white screen or a raw browser error page), then revert the deliberate bug and confirm the viewer renders normally again.

---

## Step 1: Full end-to-end verification for this Part

**Step 1** — verify caching (Section 9.1):

With the dev server running, add the temporary `console.log` described in Section 9.1 inside `listFormFields`, then call it twice in a row with the same `documentId`. Confirm the log prints only once.

**Step 2** — verify upload size limits (Section 9.3):

Attempt to upload a PDF or Office file larger than 25MB. Confirm the specific, human-readable error message from `assertFileSizeAllowed` appears in the `DocumentManager` status area.

**Step 3** — verify the merge count cap (Section 9.4):

Attempt to select and merge more than 10 documents at once (upload several small test files if you don't already have that many). Confirm the specific error message about the maximum merge count appears.

**Step 4** — verify the Error Boundary (Sections 9.7–9.8):

Follow the deliberate-bug test described in Section 9.8. Confirm the custom fallback UI in `error.tsx` appears, with both the "Try again" and "Back to documents" options working correctly, and confirm navigating to `/documents` in a separate tab while the broken viewer tab is still open shows the document list working completely normally — direct, hands-on proof of the Error Boundary's isolation guarantee.

---

## Part 9 Summary

By this point you have: a correctly-scoped `use cache` application on `listFormFields`, backed by an explicit, verified justification for why that specific function's output is truly invariant; a centralized `MAX_UPLOAD_BYTES` constant and `assertFileSizeAllowed` helper enforced consistently across both the native PDF upload path (Part 6) and the Office conversion path (Part 8); an explicit document-count cap on merge operations, layered together with the per-file size cap to produce a predictable worst-case memory ceiling; a temporary but genuinely useful memory-monitoring technique using `process.memoryUsage()`; a route-level `error.tsx` Error Boundary isolating viewer crashes to only the specific document being viewed; and a clear understanding of the important distinction between React-render-time errors (which Error Boundaries catch automatically) and asynchronous callback errors like Web Worker message handlers (which must be explicitly caught in application code, as Part 2's `PdfPageCanvas` already correctly did).

---

## Series Conclusion

This completes the full nine-part Greymatter PDF series. Starting from an empty folder in Part 1, we built, in order: a hybrid client/server architecture separating interactive rendering from secure byte-level processing (Part 1); a multi-threaded PDF rendering pipeline using Web Workers so heavy parsing never freezes the browser (Part 2); an authenticated, streaming document delivery layer protecting raw files from unauthorized access (Part 3); a coordinate-accurate SVG annotation overlay supporting zoom-correct highlights (Part 4); a real PostgreSQL-backed persistence layer for those annotations, plus XFDF export for interoperability with enterprise tools like Adobe Acrobat (Part 5); server-side page orchestration — merge, split, extract, reorder — using pdf-lib inside Next.js Server Actions (Part 6); programmatic watermarking and PDF form field filling/flattening for compliance-ready document finalization (Part 7); a horizontally-scalable, isolated LibreOffice microservice converting Word/Excel/PowerPoint files into PDFs indistinguishable from natively-uploaded ones (Part 8); and finally, production-hardening passes covering invariant-data caching, upload/merge memory safeguards, and React Error Boundaries preventing isolated failures from cascading into full application crashes (Part 9).

Every one of Apryse's four foundational pillars from Part 1's very first section — Rendering, Annotation, Manipulation, and Conversion — now exists in Greymatter PDF, built entirely from openly available, well-documented, actively-maintained open-source tools, with every architectural decision explained and justified as it was introduced. From here, natural next steps for a reader wanting to continue building include: a real multi-user authentication system (replacing the deliberately simplified session stand-in from Part 3/5), collaborative real-time annotation syncing between multiple simultaneous viewers of the same document, deeper PDF/A archival conformance tooling (flagged as explicitly out of scope in Part 7), and horizontal scaling/deployment configuration for running every piece of this stack (Next.js app, PostgreSQL, MinIO/S3, and the conversion microservice) in a real production cloud environment.
