Let me pull all three saved Part 6 notes to assemble the complete content accurately.
All three pieces confirmed intact. Here is the complete, assembled Part 6 in full.

# Part 6: High-Performance Server Actions for Page Orchestration

*(Phase 3 — Server-Side Manipulation and Advanced Execution)*

## Why this part exists

Parts 1–5 built the Rendering Engine and Annotation Engine pillars from Part 1's four-pillar breakdown. This Part begins **Phase 3: the Manipulation Engine** — actually editing PDF files at the byte level. Merging three contracts into one, splitting a 50-page report into individual chapters, deleting a blank page, reordering pages before sending a document out — these are the "editor cutting and pasting pages of a paper document" tasks from Part 1's original analogy.

Recall Part 1's founding rule: never do byte-level file surgery in the browser. Here is the concrete reasoning now that we have real operations to point to: merging PDFs requires parsing the complete internal structure of every input file (fonts, images, page trees) and re-serializing them into a new, valid file — CPU and memory-intensive work that would freeze a phone browser tab for several seconds on a large file, and would also expose our merging logic to anyone with dev tools open. Instead, this work happens inside Next.js Server Actions, using **pdf-lib** — a pure JavaScript library (no native binary dependencies) that can create and modify PDF byte structures entirely in memory on the server.

---

## 6.1 Why pdf-lib, and how it differs from pdf.js

**The Concept:** it is worth being precise about why we need a second PDF library, having already used pdf.js since Part 2. **pdf.js is a reader** — it parses PDF bytes and produces pixels for display; it has no meaningful ability to modify a PDF's internal structure and write out a new, valid file. **pdf-lib is a writer** — it can load an existing PDF's internal structure into memory, let you add/remove/reorder pages, embed new content, and then serialize the result back into valid PDF bytes. Think of pdf.js as a book's reader who can flip through pages and describe what is on them, and pdf-lib as a bookbinder who can physically cut pages out, glue in new ones, and rebind the whole book — two different skills, two different tools, each used where it fits.

---

## 6.2 Installing pdf-lib

**The Target:** add the `pdf-lib` package to `greymatter-pdf`.

**The Implementation:**

```bash
npm install pdf-lib
```

Unlike `pdfjs-dist` (Part 2), pdf-lib requires no separate worker script or static asset copying — it runs as a normal Node.js library, entirely inside our Server Actions.

**The Verification:**

```bash
npm ls pdf-lib
```

Expected output:
```
greymatter-pdf@0.1.0
└── pdf-lib@1.17.1
```

---

## 6.3 Designing the upload flow

**The Concept:** before we can merge or split documents, users need a way to get PDF files into our system. Recall Part 5's `documents.ts` already has a `createDocument` function, written ahead of time specifically for this moment. We build a Server Action that accepts uploaded file bytes, stores them in MinIO (Part 3's `s3-client.ts`), and creates a matching Document database row (Part 5's Prisma schema).

**The Implementation:**

### `src/server-actions/documents.ts`

```typescript
"use server";

import { randomUUID } from "node:crypto";
import { getCurrentUserId } from "@/lib/auth/session";
import { createDocument, findDocumentById, userCanAccessDocument } from "@/lib/db/documents";
import { putObjectBytes, getObjectStream } from "@/lib/storage/s3-client";

// Accepts a raw file upload from the browser (sent as FormData, the
// standard way to transmit binary file data through a Server Action) and
// stores it as a new Document. FormData is used here instead of a plain
// object because Server Actions receiving file input from an HTML <input
// type="file"> element must accept FormData -- this is a Next.js/React
// convention, not a Greymatter-specific choice.
export async function uploadDocument(formData: FormData) {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");

  const file = formData.get("file");
  if (!(file instanceof File)) {
    throw new Error("No file was provided in the upload.");
  }
  if (file.type !== "application/pdf") {
    throw new Error("Only PDF files can be uploaded.");
  }

  // Convert the browser's File object into raw bytes suitable for our
  // storage client's putObjectBytes function (Part 3).
  const arrayBuffer = await file.arrayBuffer();
  const bytes = new Uint8Array(arrayBuffer);

  // Generate a unique storage key so two different uploads (even with the
  // same original filename) never collide inside the bucket.
  const storageKey = `documents/${randomUUID()}.pdf`;

  await putObjectBytes(storageKey, bytes, "application/pdf");

  const document = await createDocument({
    ownerId: userId,
    storageKey,
    fileName: file.name,
  });

  return document;
}

// A small internal helper used by the manipulation Server Actions below:
// given a documentId, verifies access and returns the document's raw PDF
// bytes as a Uint8Array, ready to hand to pdf-lib. Centralizing this here
// avoids repeating the same "check access, then fetch bytes" sequence in
// every manipulation function that follows.
export async function loadDocumentBytes(documentId: string): Promise<Uint8Array> {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");

  const canAccess = await userCanAccessDocument(userId, documentId);
  if (!canAccess) throw new Error("Access denied.");

  const document = await findDocumentById(documentId);
  if (!document) throw new Error("Document not found.");

  const { stream } = await getObjectStream(document.storageKey);

  // Unlike proxy.ts (Part 3), which forwards the stream directly to the
  // browser without buffering, here we DO need the complete bytes in
  // memory at once -- pdf-lib's PDFDocument.load() requires the entire
  // file upfront to parse its internal cross-reference table correctly;
  // there is no meaningful way to "stream-parse" a PDF's structure
  // incrementally. This is an intentional, necessary exception to Part
  // 3's general streaming principle, scoped narrowly to this one
  // operation.
  const reader = stream.getReader();
  const chunks: Uint8Array[] = [];
  let totalLength = 0;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    totalLength += value.length;
  }

  const combined = new Uint8Array(totalLength);
  let offset = 0;
  for (const chunk of chunks) {
    combined.set(chunk, offset);
    offset += chunk.length;
  }

  return combined;
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## 6.4 Building the page manipulation Server Actions

**The Target:** `src/server-actions/page-operations.ts`

**The Concept:** each function below follows the same three-step pattern: (1) load the source document(s)' bytes using Part 6's `loadDocumentBytes` helper, (2) use pdf-lib to perform the actual page-level surgery, (3) save the resulting bytes as a **brand new** Document (never overwriting the original — preserving the source file is a deliberate safety choice, similar to "Save As" rather than silently overwriting in a word processor).

**The Implementation:**

### `src/server-actions/page-operations.ts`

```typescript
"use server";

import { PDFDocument } from "pdf-lib";
import { randomUUID } from "node:crypto";
import { getCurrentUserId } from "@/lib/auth/session";
import { createDocument } from "@/lib/db/documents";
import { putObjectBytes } from "@/lib/storage/s3-client";
import { loadDocumentBytes } from "@/server-actions/documents";

// Small shared helper: takes a finished pdf-lib PDFDocument, serializes
// it to bytes, stores those bytes, and creates a new Document database
// row pointing at them. Every operation below ends by calling this, so
// the "save the result" step is written once instead of four times.
async function saveResultAsNewDocument(
  pdfDoc: PDFDocument,
  ownerId: string,
  fileName: string
) {
  // .save() walks the entire in-memory PDF structure pdf-lib has built up
  // and serializes it into a valid, complete PDF byte array -- the
  // "rebinding" step from our bookbinder analogy in Section 6.1.
  const bytes = await pdfDoc.save();

  const storageKey = `documents/${randomUUID()}.pdf`;
  await putObjectBytes(storageKey, bytes, "application/pdf");

  return createDocument({ ownerId, storageKey, fileName });
}

// Merges multiple existing documents into one new document, in the exact
// order their IDs are given in documentIds.
export async function mergeDocuments(documentIds: string[]) {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");
  if (documentIds.length < 2) {
    throw new Error("At least two documents are required to merge.");
  }

  // A brand new, empty PDFDocument that will accumulate pages copied in
  // from each source document, in order.
  const mergedPdf = await PDFDocument.create();

  for (const documentId of documentIds) {
    const bytes = await loadDocumentBytes(documentId); // enforces access check per document
    const sourcePdf = await PDFDocument.load(bytes);

    // copyPages copies every page from sourcePdf into mergedPdf's own
    // internal structure (fonts, images, and all), returning references
    // we then append via addPage. This deep-copies everything needed so
    // the merged file has no lingering dependency on the original files.
    const copiedPages = await mergedPdf.copyPages(
      sourcePdf,
      sourcePdf.getPageIndices() // every page, in original order
    );
    copiedPages.forEach((page) => mergedPdf.addPage(page));
  }

  return saveResultAsNewDocument(mergedPdf, userId, "merged.pdf");
}

// Splits a single document into one new document per page. Returns an
// array of the newly created Document records, one per original page.
export async function splitDocument(documentId: string) {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");

  const bytes = await loadDocumentBytes(documentId);
  const sourcePdf = await PDFDocument.load(bytes);
  const pageCount = sourcePdf.getPageCount();

  const results = [];
  for (let pageIndex = 0; pageIndex < pageCount; pageIndex++) {
    const newPdf = await PDFDocument.create();
    const [copiedPage] = await newPdf.copyPages(sourcePdf, [pageIndex]);
    newPdf.addPage(copiedPage);

    const document = await saveResultAsNewDocument(
      newPdf,
      userId,
      `page-${pageIndex + 1}.pdf`
    );
    results.push(document);
  }

  return results;
}

// Extracts a specific subset of pages (by 1-indexed page numbers,
// matching the convention established in Part 2 and Part 4) into a
// single new document, in the order the page numbers are given -- this
// also naturally supports reordering, since the caller controls the
// order of pageNumbers.
export async function extractPages(documentId: string, pageNumbers: number[]) {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");
  if (pageNumbers.length === 0) {
    throw new Error("At least one page number must be provided.");
  }

  const bytes = await loadDocumentBytes(documentId);
  const sourcePdf = await PDFDocument.load(bytes);
  const totalPages = sourcePdf.getPageCount();

  // Convert our 1-indexed page numbers into pdf-lib's 0-indexed page
  // indices, and validate each one is actually within range -- pdf-lib
  // throws an unhelpful low-level error if given an out-of-range index,
  // so we check upfront and produce a clear message instead.
  const pageIndices = pageNumbers.map((pageNumber) => {
    const index = pageNumber - 1;
    if (index < 0 || index >= totalPages) {
      throw new Error(
        `Page ${pageNumber} does not exist in this document (it has ${totalPages} pages).`
      );
    }
    return index;
  });

  const newPdf = await PDFDocument.create();
  const copiedPages = await newPdf.copyPages(sourcePdf, pageIndices);
  copiedPages.forEach((page) => newPdf.addPage(page));

  return saveResultAsNewDocument(newPdf, userId, "extracted.pdf");
}

// Reordering is really just "extract every page, but in a new order" --
// we express it as a thin, clearly-named wrapper around extractPages
// rather than duplicating the same pdf-lib logic a third time. Passing
// every original page number in a new order achieves reordering; passing
// only a subset achieves combined reorder+delete in one operation.
export async function reorderPages(documentId: string, newPageOrder: number[]) {
  return extractPages(documentId, newPageOrder);
}
```

Why every operation creates a new Document rather than modifying the original in place: this mirrors how professional document tools behave (Acrobat's "Organize Pages" exports a new file rather than silently overwriting your original scan or contract), and it also means our Prisma Annotation records (Part 5), which are tied to a specific `documentId`, are never silently invalidated by an in-place edit that changes page numbering underneath them. A future part could add an explicit "replace original" step as a deliberate, separate user action built on top of these primitives, rather than baking irreversible overwrites into the primitives themselves.

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 1: A minimal document management page

**The Target:** `src/app/documents/page.tsx` and `src/components/documents/DocumentManager.tsx`

**The Concept:** we need a browser-facing page where a user can upload PDFs, see their existing documents, and trigger merge/split/extract operations. We keep this UI intentionally simple and functional in this Part — polishing the visual design is not the point here, proving the Server Actions work end-to-end from a real browser is.

**The Implementation:**

### `src/components/documents/DocumentManager.tsx`

```typescript
"use client";

import { useState, useTransition } from "react";
import { uploadDocument } from "@/server-actions/documents";
import {
  mergeDocuments,
  splitDocument,
  extractPages,
} from "@/server-actions/page-operations";

interface DocumentSummary {
  id: string;
  fileName: string;
}

interface DocumentManagerProps {
  initialDocuments: DocumentSummary[];
}

export function DocumentManager({ initialDocuments }: DocumentManagerProps) {
  const [documents, setDocuments] = useState(initialDocuments);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  // useTransition marks the Server Action calls below as non-blocking UI
  // updates -- isPending lets us show a loading state without manually
  // managing a separate boolean for every single action.
  const [isPending, startTransition] = useTransition();

  function toggleSelected(id: string) {
    setSelectedIds((current) =>
      current.includes(id)
        ? current.filter((existingId) => existingId !== id)
        : [...current, id]
    );
  }

  async function handleUpload(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);

    startTransition(async () => {
      try {
        const newDocument = await uploadDocument(formData);
        setDocuments((current) => [...current, newDocument]);
        setStatusMessage(`Uploaded "${newDocument.fileName}" successfully.`);
        event.currentTarget.reset();
      } catch (error) {
        setStatusMessage(
          error instanceof Error ? error.message : "Upload failed."
        );
      }
    });
  }

  function handleMerge() {
    if (selectedIds.length < 2) {
      setStatusMessage("Select at least two documents to merge.");
      return;
    }
    startTransition(async () => {
      try {
        const merged = await mergeDocuments(selectedIds);
        setDocuments((current) => [...current, merged]);
        setStatusMessage(`Merged into "${merged.fileName}".`);
        setSelectedIds([]);
      } catch (error) {
        setStatusMessage(
          error instanceof Error ? error.message : "Merge failed."
        );
      }
    });
  }

  function handleSplit(documentId: string) {
    startTransition(async () => {
      try {
        const pages = await splitDocument(documentId);
        setDocuments((current) => [...current, ...pages]);
        setStatusMessage(`Split into ${pages.length} single-page documents.`);
      } catch (error) {
        setStatusMessage(
          error instanceof Error ? error.message : "Split failed."
        );
      }
    });
  }

  function handleExtractFirstPage(documentId: string) {
    startTransition(async () => {
      try {
        const extracted = await extractPages(documentId, [1]);
        setDocuments((current) => [...current, extracted]);
        setStatusMessage(`Extracted page 1 into "${extracted.fileName}".`);
      } catch (error) {
        setStatusMessage(
          error instanceof Error ? error.message : "Extract failed."
        );
      }
    });
  }

  return (
    <div className="mx-auto max-w-2xl p-6">
      <h1 className="mb-4 text-xl font-semibold">Documents</h1>

      <form onSubmit={handleUpload} className="mb-6 flex items-center gap-2">
        <input
          type="file"
          name="file"
          accept="application/pdf"
          required
          className="text-sm"
        />
        <button
          type="submit"
          disabled={isPending}
          className="rounded bg-blue-600 px-3 py-1.5 text-sm font-medium text-white disabled:opacity-50"
        >
          Upload
        </button>
      </form>

      {statusMessage && (
        <div className="mb-4 rounded bg-gray-100 p-2 text-sm text-gray-700">
          {statusMessage}
        </div>
      )}

      <ul className="mb-4 divide-y divide-gray-200 rounded border border-gray-200">
        {documents.map((doc) => (
          <li key={doc.id} className="flex items-center justify-between p-2">
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={selectedIds.includes(doc.id)}
                onChange={() => toggleSelected(doc.id)}
              />
              {doc.fileName}
            </label>
            <div className="flex gap-2">
              <button
                onClick={() => handleSplit(doc.id)}
                disabled={isPending}
                className="text-xs text-blue-600 hover:underline disabled:opacity-50"
              >
                Split
              </button>
              <button
                onClick={() => handleExtractFirstPage(doc.id)}
                disabled={isPending}
                className="text-xs text-blue-600 hover:underline disabled:opacity-50"
              >
                Extract page 1
              </button>
            </div>
          </li>
        ))}
      </ul>

      <button
        onClick={handleMerge}
        disabled={isPending || selectedIds.length < 2}
        className="rounded bg-green-600 px-3 py-1.5 text-sm font-medium text-white disabled:opacity-50"
      >
        Merge selected ({selectedIds.length})
      </button>
    </div>
  );
}
```

### `src/app/documents/page.tsx`

```typescript
import { DocumentManager } from "@/components/documents/DocumentManager";
import { getCurrentUserId } from "@/lib/auth/session";
import { prisma } from "@/lib/db/prisma";
import { redirect } from "next/navigation";

// A Server Component (no "use client") that fetches the current user's
// documents on the server before the page ever reaches the browser, then
// hands that initial list down to the Client Component above for
// interactivity -- the same Server/Client split established in Part 1.
export default async function DocumentsPage() {
  const userId = await getCurrentUserId();
  if (!userId) {
    redirect("/dev-sign-in");
  }

  const documents = await prisma.document.findMany({
    where: { ownerId: userId },
    select: { id: true, fileName: true },
    orderBy: { createdAt: "desc" },
  });

  return <DocumentManager initialDocuments={documents} />;
}
```

**The Verification:** this needs the dev server running and a signed-in session — continue to Step 2.

---

## Step 2: Full end-to-end verification

**Step 1** — start everything and sign in:

```bash
docker compose up -d
npm run dev
```

Visit http://localhost:3000/dev-sign-in, then navigate to http://localhost:3000/documents.

**Step 2** — confirm upload works:

Choose a PDF file (any multi-page PDF works) and click Upload. Confirm the status message shows "Uploaded ... successfully" and the file appears in the list below.

**Step 3** — confirm split works:

Click "Split" next to your uploaded document. Confirm the status message reports the correct page count, and that new entries named `page-1.pdf`, `page-2.pdf`, etc. appear in the list.

**Step 4** — confirm extract works:

Click "Extract page 1" next to any multi-page document. Confirm a new `extracted.pdf` entry appears.

**Step 5** — confirm merge works:

Check the checkboxes next to two or more documents in the list, then click "Merge selected". Confirm a new `merged.pdf` entry appears, and that opening it (via `/viewer/<merged-document-id>`, using the id visible in your database) shows all the source documents' pages concatenated in the order you selected them.

**Step 6** — confirm database records match storage:

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_pdf -c "SELECT id, \"fileName\", \"storageKey\" FROM \"Document\" ORDER BY \"createdAt\" DESC LIMIT 5;"
```

Expected output: your most recently created documents (`merged.pdf`, `extracted.pdf`, `page-N.pdf`), each with a distinct `storageKey`.

**Step 7** — confirm access control still applies to manipulation actions:

Note that `mergeDocuments`, `splitDocument`, and `extractPages` all internally call `loadDocumentBytes`, which enforces the same `userCanAccessDocument` check from Part 3/Part 5. To verify this, you would need a second user account attempting to reference another user's `documentId` — this is straightforward to test once a real multi-user sign-up flow exists, which is outside this series' current scope; for now, trust that the shared `loadDocumentBytes` helper is exercised identically to the already-verified `proxy.ts` checks from Part 3.

---

## Part 6 Summary

By this point you have: `pdf-lib` installed and understood as the "writer" counterpart to pdf.js's "reader" role from Part 2; a complete upload flow storing new PDF files in MinIO and registering them in Prisma; a `loadDocumentBytes` helper centralizing the "check access, then fetch full bytes" pattern every manipulation function needs; four Server Actions — `mergeDocuments`, `splitDocument`, `extractPages`, and `reorderPages` — each producing a brand new Document rather than overwriting the original; and a working, minimal browser UI proving all of this end-to-end, from file upload through page-level surgery back to a viewable result.

Critically, every one of these operations enforces the exact same authentication and authorization checks established in Part 3 and reused in Part 5, because they all route through the same underlying helper functions — there is no separate, parallel security model for file manipulation that could accidentally diverge from the viewing security model.

Part 7 continues Phase 3 (the Manipulation Engine) by adding programmatic stamping and watermarking (embedding text, logos, and structural marks onto a PDF's vector matrices), interactive form field injection, and flattening — converting fillable forms into permanent, non-editable content for long-term compliance archiving.
