## AI SaaS Tutorial - Part 6: Text Extraction & Chunking

*Next.js 16 note: this route handler (`src/app/api/documents/process/route.ts`) uses only standard Request/Response — no dynamic params, no Next.js-version-specific APIs. Confirmed compatible as-is.*

### Goal
Build the `/api/documents/process` route that: downloads the uploaded file, extracts raw text, splits it into overlapping chunks, and saves them as Chunk rows (embeddings added in Part 7).

### 1. Parsing library
`pdf-parse` was already installed in Part 1 (it's free/open-source and handles PDF text extraction). Plain `.txt`/`.md` files need no parsing library.

### 2. Text extraction helper
`src/lib/rag/extract.ts`:
```ts
import pdfParse from "pdf-parse";

export async function extractText(fileUrl: string, fileName: string): Promise<string> {
  const res = await fetch(fileUrl);
  const buffer = Buffer.from(await res.arrayBuffer());

  if (fileName.toLowerCase().endsWith(".pdf")) {
    const parsed = await pdfParse(buffer);
    return parsed.text;
  }

  return buffer.toString("utf-8");
}
```

### 3. Chunking helper
`src/lib/rag/chunk.ts`:
```ts
interface ChunkOptions {
  chunkSize?: number;
  overlap?: number;
}

export function chunkText(text: string, options: ChunkOptions = {}): string[] {
  const { chunkSize = 1000, overlap = 150 } = options;

  const cleaned = text.replace(/\s+/g, " ").trim();
  if (!cleaned) return [];

  const chunks: string[] = [];
  let start = 0;

  while (start < cleaned.length) {
    const end = Math.min(start + chunkSize, cleaned.length);
    chunks.push(cleaned.slice(start, end));
    if (end === cleaned.length) break;
    start = end - overlap;
  }

  return chunks;
}
```
**Why overlap?** Without it, a sentence that spans a chunk boundary can get cut in half, losing meaning for both chunks. A ~15% overlap is a common, simple starting point.

### 4. The processing route
`src/app/api/documents/process/route.ts`:
```ts
import { db } from "@/lib/db";
import { extractText } from "@/lib/rag/extract";
import { chunkText } from "@/lib/rag/chunk";
import { embedAndStoreChunks } from "@/lib/rag/embed";

export async function POST(req: Request) {
  const { documentId } = await req.json();

  const document = await db.document.findUnique({ where: { id: documentId } });
  if (!document) {
    return new Response("Document not found", { status: 404 });
  }

  try {
    const text = await extractText(document.fileUrl, document.name);
    const chunks = chunkText(text);

    if (chunks.length === 0) {
      await db.document.update({ where: { id: documentId }, data: { status: "FAILED" } });
      return new Response("No extractable text", { status: 200 });
    }

    await embedAndStoreChunks(documentId, chunks);

    return new Response("ok", { status: 200 });
  } catch (err) {
    console.error("Document processing failed", err);
    await db.document.update({ where: { id: documentId }, data: { status: "FAILED" } });
    return new Response("Processing failed", { status: 500 });
  }
}
```
Note: this route references `embedAndStoreChunks`, built in Part 7. If you want to test extraction/chunking in isolation right now, temporarily stub it:
```ts
async function embedAndStoreChunks(documentId: string, chunks: string[]) {
  console.log(`Would store ${chunks.length} chunks for doc ${documentId}`);
  await db.document.update({ where: { id: documentId }, data: { status: "READY" } });
}
```

**Checkpoint:** Upload a document again. Check your terminal logs (if using the stub) or move on to Part 7 to see real chunks land in the Chunk table via `npx prisma studio`.

**Next:** Part 7 — Embeddings & Vector Storage (free model selection).
