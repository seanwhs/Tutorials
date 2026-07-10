# Part 3: File Ingestion Pipeline

Goal: user uploads a PDF/TXT/MD file -> we extract raw text -> split into chunks -> embed each chunk -> store `Document` + `Chunk` rows (embeddings included) in Postgres. This is the foundation both the extraction agent (Part 4) and semantic search (Part 6) build on.

## 1. Install/confirm Ollama for local embeddings
Embeddings need to be free and unlimited since ingestion can involve many chunks. Ollama running locally is the default; a hosted free equivalent can be swapped in later (same pattern as the LLM registry in Part 4).
```bash
# https://ollama.com/download
ollama pull nomic-embed-text
ollama serve
```
Verify it's up:
```bash
curl http://localhost:11434/api/embeddings -d '{"model": "nomic-embed-text", "prompt": "hello world"}'
```
You should get back a JSON object with an `embedding` array of 768 floats.

## 2. Text extraction
`src/lib/ingestion/extract-text.ts`:
```ts
import pdfParse from "pdf-parse";

export async function extractText(file: File): Promise<string> {
  const buffer = Buffer.from(await file.arrayBuffer());

  if (file.type === "application/pdf" || file.name.endsWith(".pdf")) {
    const result = await pdfParse(buffer);
    return result.text;
  }

  if (
    file.type === "text/plain" ||
    file.type === "text/markdown" ||
    file.name.endsWith(".txt") ||
    file.name.endsWith(".md")
  ) {
    return buffer.toString("utf-8");
  }

  throw new Error(`Unsupported file type: ${file.type || file.name}`);
}
```
Why check both `file.type` and the filename extension: browsers are inconsistent about setting MIME types for `.md` files (some report `text/markdown`, others report an empty string), so we fall back to extension checking.

## 3. Chunking strategy
`src/lib/ingestion/chunk.ts`:
```ts
export interface TextChunk {
  content: string;
  index: number;
}

const CHUNK_SIZE = 1000;      // characters, not tokens - simple and good enough for a beginner pipeline
const CHUNK_OVERLAP = 150;    // characters of overlap between consecutive chunks

export function chunkText(text: string): TextChunk[] {
  const cleaned = text.replace(/\s+/g, " ").trim();
  const chunks: TextChunk[] = [];

  let start = 0;
  let index = 0;

  while (start < cleaned.length) {
    const end = Math.min(start + CHUNK_SIZE, cleaned.length);
    const content = cleaned.slice(start, end).trim();

    if (content.length > 0) {
      chunks.push({ content, index });
      index++;
    }

    if (end === cleaned.length) break;
    start = end - CHUNK_OVERLAP;
  }

  return chunks;
}
```
Why overlap matters here specifically: unlike plain RAG where overlap mainly protects retrieval recall, in this project overlap also protects the **extraction agent** — a relationship stated right at a chunk boundary (e.g., "...Alice founded" | "Acme Corp in 2019...") would otherwise get silently split in half and never extracted at all. 150 characters of overlap is a reasonable default for 1000-character chunks; increase it if you notice entities/relationships going missing near chunk edges.

## 4. Embeddings helper
`src/lib/ai/embed.ts`:
```ts
const OLLAMA_BASE_URL = process.env.OLLAMA_BASE_URL ?? "http://localhost:11434";

export async function embedText(text: string): Promise<number[]> {
  const res = await fetch(`${OLLAMA_BASE_URL}/api/embeddings`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ model: "nomic-embed-text", prompt: text }),
  });

  if (!res.ok) {
    throw new Error(`Embedding request failed: ${res.status} ${await res.text()}`);
  }

  const data = (await res.json()) as { embedding: number[] };
  return data.embedding;
}
```

## 5. Raw-SQL vector write helper
Because Prisma treats the `embedding` column as `Unsupported`, we can't do `db.chunk.create({ data: { embedding: [...] } })`. We write it with `$executeRaw` instead.

`src/lib/vector.ts`:
```ts
import { db } from "@/lib/db";
import { Prisma } from "@prisma/client";

// pgvector expects the literal format '[0.1,0.2,0.3]' cast to ::vector
function toVectorLiteral(embedding: number[]): string {
  return `[${embedding.join(",")}]`;
}

export async function setChunkEmbedding(chunkId: string, embedding: number[]) {
  await db.$executeRaw`
    UPDATE chunks
    SET embedding = ${toVectorLiteral(embedding)}::vector
    WHERE id = ${chunkId}
  `;
}
```
We create the `Chunk` row normally through Prisma first (to get its `id`), then immediately run this raw update to attach the embedding. Two small writes are simpler and safer for a beginner codebase than hand-writing a full raw `INSERT`.

## 6. The upload UI
`src/components/upload-form.tsx`:
```tsx
"use client";

import { useState, useTransition } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ingestDocument } from "@/actions/ingest-document";
import { toast } from "sonner";

export function UploadForm() {
  const [file, setFile] = useState<File | null>(null);
  const [isPending, startTransition] = useTransition();

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!file) return;

    const formData = new FormData();
    formData.append("file", file);

    startTransition(async () => {
      const result = await ingestDocument(formData);
      if (result.success) {
        toast.success(`Ingested "${result.fileName}" - ${result.chunkCount} chunks created`);
        setFile(null);
      } else {
        toast.error(result.error);
      }
    });
  }

  return (
    <form onSubmit={handleSubmit} className="flex items-center gap-2">
      <Input
        type="file"
        accept=".pdf,.txt,.md"
        onChange={(e) => setFile(e.target.files?.[0] ?? null)}
        disabled={isPending}
      />
      <Button type="submit" disabled={!file || isPending}>
        {isPending ? "Processing..." : "Upload & Ingest"}
      </Button>
    </form>
  );
}
```
Why a Server Action instead of a `route.ts` upload endpoint here: this form has no need for streaming progress (that's what Part 4's extraction step will need, and we'll use a route handler there instead), so a plain Server Action keeps the code simpler — one async function, no manual `fetch`, automatic pending state via `useTransition`.

## 7. The server action: full pipeline orchestration
`src/actions/ingest-document.ts`:
```ts
"use server";

import { db } from "@/lib/db";
import { extractText } from "@/lib/ingestion/extract-text";
import { chunkText } from "@/lib/ingestion/chunk";
import { embedText } from "@/lib/ai/embed";
import { setChunkEmbedding } from "@/lib/vector";

interface IngestResult {
  success: boolean;
  fileName?: string;
  chunkCount?: number;
  documentId?: string;
  error?: string;
}

export async function ingestDocument(formData: FormData): Promise<IngestResult> {
  const file = formData.get("file") as File | null;
  if (!file) {
    return { success: false, error: "No file provided." };
  }

  try {
    const document = await db.document.create({
      data: {
        fileName: file.name,
        mimeType: file.type || "text/plain",
        status: "CHUNKING",
      },
    });

    const rawText = await extractText(file);
    if (rawText.trim().length === 0) {
      await db.document.update({ where: { id: document.id }, data: { status: "FAILED" } });
      return { success: false, error: "No extractable text found in file." };
    }

    const chunks = chunkText(rawText);

    for (const chunk of chunks) {
      const created = await db.chunk.create({
        data: {
          content: chunk.content,
          chunkIndex: chunk.index,
          documentId: document.id,
        },
      });

      const embedding = await embedText(chunk.content);
      await setChunkEmbedding(created.id, embedding);
    }

    await db.document.update({
      where: { id: document.id },
      data: { status: "EXTRACTING" }, // Part 4 picks up from here
    });

    return {
      success: true,
      fileName: file.name,
      chunkCount: chunks.length,
      documentId: document.id,
    };
  } catch (err) {
    console.error("Ingestion failed:", err);
    return {
      success: false,
      error: err instanceof Error ? err.message : "Unknown ingestion error.",
    };
  }
}
```
Note the `status` field walks through the `DocumentStatus` enum from Part 2 (`PENDING -> CHUNKING -> EXTRACTING -> DONE/FAILED`). Part 4's extraction agent will flip `EXTRACTING -> DONE` once nodes/edges are persisted, and the graph/search UIs can use this status to show "still processing" states (Part 7 wires this into the UI polish pass).

## 8. Wire it into the landing page
`src/app/page.tsx`:
```tsx
import { UploadForm } from "@/components/upload-form";

export default function HomePage() {
  return (
    <main className="mx-auto max-w-2xl px-6 py-16">
      <h1 className="text-2xl font-semibold">Cortex - Knowledge Graph Manager</h1>
      <p className="mt-2 text-sm text-muted-foreground">
        Upload a document to extract entities and relationships into a knowledge graph.
      </p>
      <div className="mt-8">
        <UploadForm />
      </div>
    </main>
  );
}
```

## 9. Verification checkpoint
```bash
npm run dev
```
Upload a small `.txt` file with a couple of sentences mentioning named entities (e.g., "Marie Curie discovered polonium while working in Paris."). Confirm:
1. Toast shows a success message with a chunk count ≥ 1.
2. `npx prisma studio` shows a new `Document` row with `status = EXTRACTING`, and one or more `Chunk` rows.
3. Run this in the Neon SQL editor to confirm the embedding actually landed:
```sql
SELECT id, chunk_index, embedding IS NOT NULL AS has_embedding
FROM chunks
ORDER BY id DESC LIMIT 5;
```
`has_embedding` should read `true` for your new rows.

Next: Part 4 - AI-Agentic Extraction (Free LLM Provider Abstraction + Parsing into Nodes/Edges).
