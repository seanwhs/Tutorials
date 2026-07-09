## AI SaaS Tutorial - Part 8: RAG Retrieval Logic

*Next.js 16 note: no dynamic route params or version-specific APIs here — pure DB/query logic, confirmed compatible as-is. The optional debug route uses plain Request/Response too.*

### Goal
Given a user's question, embed it, run a cosine-similarity search against pgvector scoped to their workspace, and return the top-K most relevant chunks.

### 1. Retrieval function
`src/lib/rag/retrieve.ts`:
```ts
import { db } from "@/lib/db";
import { getEmbeddingForQuery } from "./embed-query";

interface RetrievedChunk {
  id: string;
  content: string;
  documentId: string;
  documentName: string;
  similarity: number;
}

export async function retrieveRelevantChunks(
  workspaceId: string,
  question: string,
  topK = 5,
  minSimilarity = 0.65
): Promise<RetrievedChunk[]> {
  const queryEmbedding = await getEmbeddingForQuery(question);
  const vectorLiteral = `[${queryEmbedding.join(",")}]`;

  // <=> is pgvector's cosine distance operator (lower = more similar).
  const results = await db.$queryRawUnsafe<RetrievedChunk[]>(
    `
    SELECT
      c.id,
      c.content,
      c."documentId",
      d.name AS "documentName",
      1 - (c.embedding <=> $1::vector) AS similarity
    FROM "Chunk" c
    JOIN "Document" d ON d.id = c."documentId"
    WHERE d."workspaceId" = $2
      AND d.status = 'READY'
    ORDER BY c.embedding <=> $1::vector
    LIMIT $3
    `,
    vectorLiteral,
    workspaceId,
    topK
  );

  return results.filter((r) => r.similarity >= minSimilarity);
}
```

### 2. Why a similarity threshold
Without a minimum similarity cutoff, the query would still return "top 5" results even when none of them are actually relevant, potentially causing the model to answer confidently from irrelevant chunks. `minSimilarity = 0.65` is a reasonable starting point for `nomic-embed-text` — tune based on testing with your own documents.

### 3. Quick manual test route (optional, remove before deploying)
`src/app/api/debug/retrieve/route.ts`:
```ts
import { retrieveRelevantChunks } from "@/lib/rag/retrieve";

export async function POST(req: Request) {
  const { workspaceId, question } = await req.json();
  const chunks = await retrieveRelevantChunks(workspaceId, question);
  return Response.json(chunks);
}
```
Test with curl:
```bash
curl -X POST http://localhost:3000/api/debug/retrieve \
  -H "Content-Type: application/json" \
  -d '{"workspaceId":"<your-workspace-id>","question":"What does this document say about pricing?"}'
```

**Checkpoint:** You get back an array of chunks with similarity scores, all belonging to READY documents in the given workspace, ordered highest-similarity first. Delete/guard the debug route before deploying (Part 15 reminds you again).

**Next:** Part 9 — Chat UI with Vercel AI SDK (streaming).
