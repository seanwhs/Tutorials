# Part 8: Headless Office Document Conversion Engine

*(Phase 4 — Office Document Conversion and Practical Production Operations)*

## Why this part exists

Every part so far assumed the user's file already is a PDF. But real-world documents arrive as Word contracts, Excel budgets, and PowerPoint decks — the fourth pillar from Part 1's original breakdown, the **Conversion Engine**, exists specifically to bridge this gap: accept a `.docx`/`.xlsx`/`.pptx` upload, convert it to PDF, and hand the result to our existing Part 2 rendering pipeline, so users never need a separate tool just to preview an Office file.

Why we cannot do this conversion with pdf-lib (Part 6) or any pure-JavaScript library: rendering a Word document correctly requires implementing an enormous, genuinely complex layout engine — text flow, tables, embedded images, headers/footers, page breaks, font substitution — essentially reimplementing a significant chunk of Microsoft Word's own rendering logic. No practical, actively-maintained pure-JavaScript library does this reliably. Instead, we lean on **LibreOffice**, a mature, free, open-source office suite that already has a battle-tested layout engine, and run it "headless" (with no graphical window, controlled entirely via command line) inside its own isolated Docker container — a horizontally-scalable microservice we can call from Next.js over a simple HTTP request.

Analogy: think of this exactly like Part 3's `proxy.ts` pattern, but for format conversion instead of storage access — our Next.js app never touches LibreOffice's internals directly, just as it never touched MinIO's internals directly. Instead, it sends a request to a small, dedicated service whose only job is "give me this file as a PDF," and gets bytes back.

---

## 8.1 Why a separate microservice, not a library call

**The Concept:** LibreOffice is a large, heavyweight native application — not a JavaScript library you `npm install`. Running it requires a full LibreOffice installation with all its system dependencies, which does not belong inside our lightweight Next.js server process. By isolating it into its own Docker container with a minimal HTTP wrapper, we get three benefits: (1) our main Next.js app stays small and fast to build/deploy; (2) the conversion service can be scaled independently — if conversions become a bottleneck under load, we run more copies of just that container, without touching the rest of the app; (3) a crash or hang inside LibreOffice (which, being a large legacy codebase, can occasionally misbehave on malformed input files) is contained to its own container and cannot take down our main application process.

---

## 8.2 Building the LibreOffice conversion microservice

**The Target:** a new, separate directory `conversion-service/` at the project root, containing its own Dockerfile and a minimal HTTP server.

**The Concept:** we build a tiny Node.js Express server whose only endpoint accepts a file upload and shells out to LibreOffice's own command-line conversion tool (`soffice --headless --convert-to pdf`), then returns the resulting PDF bytes. This server runs inside a Docker image that already has LibreOffice installed, so we never need to install it on our development machine or main app server at all.

**The Implementation:**

### `conversion-service/Dockerfile`

```dockerfile
# We start from a Debian-based Node image specifically because LibreOffice
# has mature, well-tested Debian/Ubuntu packages -- using a Node image
# built on a different base OS would make installing LibreOffice's system
# dependencies significantly more error-prone.
FROM node:20-bookworm-slim

# Install LibreOffice's headless-capable core components. We install only
# the "writer," "calc," and "impress" components (covering .docx, .xlsx,
# .pptx respectively) plus core dependencies, rather than the full
# libreoffice meta-package, to keep the resulting image smaller and the
# build faster.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    libreoffice-core \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY server.js ./

# Port our small HTTP wrapper listens on -- deliberately different from
# Next.js's own port 3000, so both can run simultaneously without
# conflict during local development.
EXPOSE 4000

CMD ["node", "server.js"]
```

### `conversion-service/package.json`

```json
{
  "name": "greymatter-conversion-service",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "multer": "^1.4.5-lts.1"
  }
}
```

Why multer: this is a well-established Express middleware for handling multipart file uploads (the same underlying HTTP mechanism our Next.js FormData uploads from Part 6 use) — it parses an incoming file upload into a temporary location on disk, which we need because LibreOffice's command-line tool operates on real files on a filesystem, not in-memory byte buffers.

---

## 8.3 Writing the conversion server

**The Target:** `conversion-service/server.js`

**The Concept:** this file's only job is: receive an uploaded file, run LibreOffice's `soffice` command-line tool against it with `--convert-to pdf`, read back the resulting PDF file, send it as the HTTP response, and clean up all temporary files afterward regardless of success or failure.

**The Implementation:**

### `conversion-service/server.js`

```javascript
import express from "express";
import multer from "multer";
import { exec } from "node:child_process";
import { promisify } from "node:util";
import { readFile, unlink, mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, basename, extname } from "node:path";

const execAsync = promisify(exec);
const app = express();

// multer writes uploaded files to a temporary directory on disk rather
// than holding them in memory -- appropriate here since soffice's
// command-line tool needs an actual file path to read from, not an
// in-memory buffer.
const upload = multer({ dest: join(tmpdir(), "greymatter-uploads") });

const ALLOWED_EXTENSIONS = new Set([".docx", ".xlsx", ".pptx", ".doc", ".xls", ".ppt"]);

app.post("/convert", upload.single("file"), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "No file was uploaded." });
  }

  const originalExtension = extname(req.file.originalname).toLowerCase();
  if (!ALLOWED_EXTENSIONS.has(originalExtension)) {
    await unlink(req.file.path).catch(() => {});
    return res.status(400).json({
      error: `Unsupported file type: ${originalExtension}. Supported: ${[...ALLOWED_EXTENSIONS].join(", ")}`,
    });
  }

  // soffice infers the input format from the file's extension, so we
  // rename multer's extension-less temp file to include the original
  // extension before invoking the conversion.
  const workingDir = await mkdtemp(join(tmpdir(), "greymatter-convert-"));
  const inputPath = join(workingDir, `input${originalExtension}`);
  const outputPath = join(workingDir, "input.pdf"); // soffice names output after the input's base name

  try {
    const { rename } = await import("node:fs/promises");
    await rename(req.file.path, inputPath);

    // --headless: no graphical window. --convert-to pdf: output format.
    // --outdir: where to write the result. LibreOffice's own internal
    // process management means this single command handles launching,
    // converting, and exiting cleanly for a single file.
    await execAsync(
      `soffice --headless --convert-to pdf --outdir "${workingDir}" "${inputPath}"`,
      { timeout: 60_000 } // guard against a hung conversion blocking this worker forever
    );

    const pdfBytes = await readFile(outputPath);

    res.setHeader("Content-Type", "application/pdf");
    res.send(pdfBytes);
  } catch (error) {
    console.error("Conversion failed:", error);
    res.status(500).json({ error: "Failed to convert the document." });
  } finally {
    // Clean up every temporary file/directory regardless of success or
    // failure, so a busy conversion service does not slowly fill up its
    // container's disk with leftover files.
    await unlink(inputPath).catch(() => {});
    await unlink(outputPath).catch(() => {});
  }
});

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`Conversion service listening on port ${PORT}`);
});
```

---

## 8.4 Adding the conversion service to docker-compose

**The Target:** update `docker-compose.yml` (from Part 5) to build and run this new service alongside MinIO and PostgreSQL.

**The Implementation:**

### `docker-compose.yml` (add this service to the existing file from Part 5)

```yaml
# Add this alongside the existing minio and postgres services:
  conversion-service:
    build:
      context: ./conversion-service
    container_name: greymatter-conversion-service
    ports:
      - "4000:4000"
    # No volumes needed -- this service is entirely stateless; every
    # request is self-contained (upload in, PDF out, temp files cleaned
    # up), so it has nothing that needs to persist across restarts.
```

**The Verification:**

```bash
docker compose up -d --build conversion-service
docker compose ps
```

Expected output: `greymatter-conversion-service` shows as running (the first build may take several minutes, since it downloads and installs LibreOffice's packages).

```bash
curl http://localhost:4000/health
```

Expected output:
```json
{"status":"ok"}
```

---

## 8.5 Configuring the conversion service URL

**The Target:** add an environment variable pointing at the conversion service.

**The Implementation:**

### `greymatter-pdf/.env.local` (add this line to the existing file)

```bash
CONVERSION_SERVICE_URL=http://localhost:4000
```

---

## 8.6 Building the conversion Server Action

**The Target:** `src/server-actions/conversion.ts`

**The Concept:** this Server Action accepts an uploaded Office file (via the same FormData pattern established in Part 6's `uploadDocument`), forwards it to our conversion microservice over a plain HTTP fetch request, and stores the resulting PDF bytes exactly the way any other document is stored — from this point onward, a converted document is indistinguishable from a natively-uploaded PDF anywhere else in Greymatter PDF.

**The Implementation:**

### `src/server-actions/conversion.ts`

```typescript
"use server";

import { randomUUID } from "node:crypto";
import { getCurrentUserId } from "@/lib/auth/session";
import { createDocument } from "@/lib/db/documents";
import { putObjectBytes } from "@/lib/storage/s3-client";

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

const SUPPORTED_OFFICE_TYPES = new Set([
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document", // .docx
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", // .xlsx
  "application/vnd.openxmlformats-officedocument.presentationml.presentation", // .pptx
]);

export async function convertOfficeDocument(formData: FormData) {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");

  const file = formData.get("file");
  if (!(file instanceof File)) {
    throw new Error("No file was provided.");
  }
  if (!SUPPORTED_OFFICE_TYPES.has(file.type)) {
    throw new Error(
      "Unsupported file type. Please upload a .docx, .xlsx, or .pptx file."
    );
  }

  // Re-package the browser's File into a fresh FormData addressed to our
  // conversion microservice -- Next.js's Server Action FormData and the
  // conversion service's own multer-based FormData parsing are separate,
  // independent HTTP requests, so we construct a new request body here
  // rather than forwarding the original one directly.
  const conversionFormData = new FormData();
  conversionFormData.append("file", file, file.name);

  const conversionServiceUrl = requireEnv("CONVERSION_SERVICE_URL");

  const response = await fetch(`${conversionServiceUrl}/convert`, {
    method: "POST",
    body: conversionFormData,
  });

  if (!response.ok) {
    const errorBody = await response.json().catch(() => ({}));
    throw new Error(
      errorBody.error || `Conversion service returned status ${response.status}.`
    );
  }

  const pdfArrayBuffer = await response.arrayBuffer();
  const pdfBytes = new Uint8Array(pdfArrayBuffer);

  // From here onward, this is identical to Part 6's uploadDocument --
  // store the (now-converted) bytes in MinIO and register a Document row,
  // exactly like any natively-uploaded PDF.
  const storageKey = `documents/${randomUUID()}.pdf`;
  await putObjectBytes(storageKey, pdfBytes, "application/pdf");

  const convertedFileName = file.name.replace(/\.(docx|xlsx|pptx)$/i, ".pdf");

  return createDocument({
    ownerId: userId,
    storageKey,
    fileName: convertedFileName,
  });
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 1: Add an Office file upload option to DocumentManager

**The Target:** update `src/components/documents/DocumentManager.tsx` from Part 6/Part 7

**The Concept:** we add a second upload form, visually distinct from the existing PDF upload form, specifically for Office files, wired to our new `convertOfficeDocument` Server Action instead of Part 6's `uploadDocument`.

**The Implementation** (additions to the existing component):

### `src/components/documents/DocumentManager.tsx` (additions)

```typescript
// Add this import alongside the existing imports:
import { convertOfficeDocument } from "@/server-actions/conversion";

// Add this handler function inside the DocumentManager component:
async function handleOfficeUpload(event: React.FormEvent<HTMLFormElement>) {
  event.preventDefault();
  const formData = new FormData(event.currentTarget);

  startTransition(async () => {
    try {
      const converted = await convertOfficeDocument(formData);
      setDocuments((current) => [...current, converted]);
      setStatusMessage(`Converted and uploaded "${converted.fileName}".`);
      event.currentTarget.reset();
    } catch (error) {
      setStatusMessage(
        error instanceof Error ? error.message : "Conversion failed."
      );
    }
  });
}
```

```jsx
{/* Add this second form below the existing PDF upload form from Part 6 */}
<form onSubmit={handleOfficeUpload} className="mb-6 flex items-center gap-2">
  <input
    type="file"
    name="file"
    accept=".docx,.xlsx,.pptx"
    required
    className="text-sm"
  />
  <button
    type="submit"
    disabled={isPending}
    className="rounded bg-purple-600 px-3 py-1.5 text-sm font-medium text-white disabled:opacity-50"
  >
    Upload & Convert Office File
  </button>
</form>
```

**The Verification:** this needs the full stack running — continue to Step 2.

---

## Step 2: Full end-to-end verification

**Step 1** — start everything, including the conversion service:

```bash
docker compose up -d --build
npm run dev
```

Confirm all three containers are running:

```bash
docker compose ps
```

Expected output: `greymatter-minio`, `greymatter-postgres`, and `greymatter-conversion-service` all show as running.

**Step 2** — sign in and navigate to the documents page:

Visit http://localhost:3000/dev-sign-in, then http://localhost:3000/documents.

**Step 3** — test .docx conversion:

Prepare or locate any `.docx` Word document. Use the new "Upload & Convert Office File" form to select and submit it. Confirm the status message reports "Converted and uploaded ..." and a new entry with a `.pdf` extension appears in the document list.

**Step 4** — confirm the converted PDF renders correctly:

Open the newly converted document in the viewer (`/viewer/<new-document-id>`). Confirm the text, formatting, and any images/tables from the original Word document appear correctly — this proves LibreOffice's layout engine correctly translated the document, and that our existing Part 2 rendering pipeline treats it identically to any natively-uploaded PDF, with zero special-case code required anywhere in the viewer.

**Step 5** — test .xlsx and .pptx conversion:

Repeat Steps 3–4 with an Excel spreadsheet and a PowerPoint presentation, confirming both convert and render successfully. Note that spreadsheet conversion in particular can produce multi-page PDFs if the sheet is wide/tall — this is expected LibreOffice behavior, not a bug in our integration.

**Step 6** — test that converted documents work with every other Part's features:

Confirm a converted document can be annotated (Part 4/5), merged with another document (Part 6), and watermarked (Part 7) — exercising each without any errors confirms that "a converted document is indistinguishable from a natively-uploaded PDF" is not just a claim, but genuinely true throughout the codebase.

**Step 7** — test error handling for unsupported file types:

Attempt to upload a plain `.txt` file through the Office upload form (browsers may prevent this via the `accept` attribute's file picker filtering, but you can test the Server Action's own validation by temporarily removing the `accept` attribute, or via a direct API testing tool). Confirm `convertOfficeDocument`'s `SUPPORTED_OFFICE_TYPES` check rejects it with a clear error message rather than forwarding a nonsensical file to the conversion service.

**Step 8** — confirm the conversion service handles a malformed/corrupted file gracefully:

Create a corrupted "fake" `.docx` file (e.g. rename a plain text file to have a `.docx` extension) and attempt to upload it. Confirm the conversion service's 60-second timeout and error handling (Section 8.3) return a clean error response rather than hanging indefinitely or crashing the container — then confirm `docker compose ps` still shows `greymatter-conversion-service` running normally afterward, proving the isolation benefit described in Section 8.1: a problematic file affects only that one request, not the service's overall availability.

---

## Part 8 Summary

By this point you have: a fully isolated, horizontally-scalable LibreOffice conversion microservice running in its own Docker container, with a minimal Express HTTP wrapper around LibreOffice's headless command-line conversion tool; that service properly cleaning up temporary files and guarding against hung conversions via a timeout; a `docker-compose.yml` now orchestrating three services together (MinIO, PostgreSQL, and this conversion service) with a single `docker compose up -d` command; a Next.js Server Action (`convertOfficeDocument`) that forwards uploads to this service and stores the result using the exact same storage/database pattern as every other document in the system; and a UI extension proving the entire pipeline end-to-end, including confirmation that converted documents integrate seamlessly with every previously-built feature — viewing, annotating, merging, and watermarking — with zero special-case code.

This completes Phase 4's first half and the fourth and final pillar from Part 1's original four-pillar breakdown: Rendering (Parts 1–3), Annotation (Parts 4–5), Manipulation (Parts 6–7), and now Conversion (Part 8). Every core capability of an enterprise document suite outlined at the very start of this series now exists in Greymatter PDF, built entirely from open-source tools.

Part 9, the final part of this series, shifts focus from building new features to production hardening: applying `use cache` directives for invariant assets, handling low-memory constraints during large file parsing, and implementing React 19 Error Boundaries so a single corrupted document stream can never crash the entire application shell.
