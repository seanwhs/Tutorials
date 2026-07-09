## AI SaaS Tutorial - Part 7: Embeddings & Vector Storage

*Next.js 16 note: no dynamic route params or Next.js-version-specific APIs in this part — it's pure library/DB code, confirmed compatible as-is.*

### Goal
Turn text chunks into vector embeddings using a free, open-source embedding model, store them in pgvector, and mark the document READY.

### 1. Choosing a free embedding option

| Option | How it's free | Notes |
|---|---|---|
| Ollama (local) | 100% free, runs on your machine | Best for development; no API key, no rate limits |
| Free hosted API (OpenAI-compatible endpoint via OpenRouter or similar) | Free tier quota | Better for production/deployment where you can't run Ollama |

We standardize on the `nomic-embed-text` model family (768 dimensions — matching our `vector(768)` column from Part 2).

**Option A: Ollama (recommended for local dev)**
1. Install Ollama: ollama.com (free, open-source, runs locally).
2. Pull the embedding model:
```bash
ollama pull nomic-embed-text
```
3. Ollama exposes an OpenAI-compatible endpoint at `http://localhost:11434/v1` — no API key needed.

**Option B: Free hosted OpenAI-compatible endpoint**
If you can't run Ollama (e.g. deploying to Vercel), use any free-tier OpenAI-compatible embeddings endpoint you have access to. The code doesn't care which — it just needs an OpenAI-compatible `/embeddings` endpoint.

### 2. Environment variables
```bash
EMBEDDING_PROVIDER=ollama
EMBEDDING_BASE_URL=http://localhost:11434/v1
EMBEDDING_API_KEY=ollama
EMBEDDING_MODEL=nomic-embed-text
```
For deployment (Part 15), swap `EMBEDDING_PROVIDER=hosted` and point `EMBEDDING_BASE_URL`/`EMBEDDING_API_KEY` at your free hosted provider.

### 3. Embedding client
`src/lib/rag/embed-query.ts` (shared helper used by both storage and retrieval):
```ts
export async function getEmbeddingForQuery(text: string): Promise<number[]> {
  const baseUrl = process.env.EMBEDDING_BASE_URL!;
  const apiKey = process.env.EMBEDDING_API_KEY!;
  const model = process.env.EMBEDDING_MODEL!;

  const res = await fetch(`${baseUrl}/embeddings`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({ model, input: text }),
  });

  if (!res.ok) {
    throw new Error(`Embedding request failed: ${res.status} ${await res.text()}`);
  }

  const json = await res.json();
  return json.data[0].embedding;
}
```

`src/lib/rag/embed.ts`:
```ts
import { db } from "@/lib/db";
import { getEmbeddingForQuery as getEmbedding } from "./embed-query";

export async function embedAndStoreChunks(documentId: string, chunks: string[]) {
  for (const content of chunks) {
    const embedding = await getEmbedding(content);
    const vectorLiteral = `[${embedding.join(",")}]`;

    await db.$executeRawUnsafe(
      `INSERT INTO "Chunk" (id, "documentId", content, embedding, "createdAt")
       VALUES (gen_random_uuid()::text, $1, $2, $3::vector, now())`,
      documentId,
      content,
      vectorLiteral
    );
  }

  await db.document.update({ where: { id: documentId }, data: { status: "READY" } });
}
```
`gen_random_uuid()` requires the `pgcrypto` extension, already enabled in Part 2.

### 4. Wire the real import back into the processing route
Go back to `src/app/api/documents/process/route.ts` from Part 6 and make sure it imports the real function (remove the temporary stub if you added one):
```ts
import { embedAndStoreChunks } from "@/lib/rag/embed";
```

### 5. Why we picked 768 dimensions
`nomic-embed-text` outputs 768-dimensional vectors. If you choose a different free embedding model later, update **both** the `vector(768)` column definition in your Prisma migration (Part 2) and the `EMBEDDING_MODEL` env var here — they must always match, or inserts will fail with a dimension mismatch error.

**Checkpoint:** Upload a document. Within a few seconds its status should flip from PROCESSING to READY. Run `npx prisma studio` and confirm Chunk rows exist with non-null `embedding` values for that document.

**Next:** Part 8 — RAG Retrieval Logic.
