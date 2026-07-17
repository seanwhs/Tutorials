# Part 3: Why Keyword Matching Isn't Enough — Introducing Embeddings

## Recap

In Part 2, we fixed the architecture: System Frame, Dynamic Memory, Transient Fact. But the function that *chooses* which files go into Transient Fact — `selectRelevantFacts` — is embarrassingly crude. It literally counts overlapping words. Ask "how does authentication throttling work?" and it will likely select nothing useful, because the word "throttling" appears nowhere in `user.ts` — even though a human reader would instantly recognize the lockout logic as exactly what's being asked about.

This part fixes *that* specific problem — but, following our series' honest pattern, we'll build the **naive version of the fix** first, prove it's a real improvement over keyword matching, and then discover its own distinct failure mode (breaking code structure) — which Part 4 then fixes.

---

## The Concept: Meaning as Coordinates in Space

**The analogy:** Imagine a library where, instead of alphabetical order, every book is placed on a giant 3D shelf based on its *topic* — cookbooks cluster together in one corner, physics textbooks in another, and a book about "the physics of cooking" sits somewhere between the two clusters, closer to whichever topic it leans toward. To find books "like this one," you don't scan every title for shared words — you just look at what's physically nearby on the shelf.

This is exactly what an **embedding** is: a numerical representation of a piece of text — a list of numbers (a **vector**, typically hundreds or thousands of numbers long) that encodes its *meaning* as coordinates in a high-dimensional space. Text with similar meaning ends up with similar (nearby) coordinates, even if the words themselves are completely different. "Login attempt lockout" and "authentication throttling" will land near each other in this space, despite sharing zero literal words — solving exactly the problem our Part 2 keyword matcher couldn't.

To find "nearby" vectors, we use **cosine similarity** — a mathematical measure of the angle between two vectors, producing a score between -1 and 1, where 1 means "pointing in exactly the same direction" (highly similar meaning) and 0 means "unrelated." We'll implement this by hand in Step 3 — it's a handful of lines of math, not a mysterious black box.

This entire pipeline — turning text into vectors, then finding the closest ones to a query — is called **semantic search**, and it's the foundation of what's broadly known as **RAG (Retrieval-Augmented Generation)**: retrieving relevant information and augmenting the LLM's prompt with it, instead of relying on the model's memorized training data or an entire raw file dump.

---

## Step 1 — Naive Fixed-Size Chunking

**The Target:** A function, `src/retrieval/chunk.ts`, that splits file contents into fixed-size character chunks — the simplest, most common first approach to preparing text for embedding.

**The Concept:** You can't (and shouldn't) embed an entire file as one vector — a whole file mixes many different concepts (imports, one function, another unrelated function), and embedding it as a single point in space would blur all those distinct meanings into one blurry average, similar to photographing an entire bookshelf from far away instead of each book's cover individually. So we first **chunk** — break text into smaller pieces — and embed each chunk separately.

The naive, ubiquitous first approach: slice text into fixed-size windows of N characters, with some overlap between consecutive chunks so we don't lose context right at the boundary. This is genuinely the most common "quick start" approach in RAG tutorials — which is exactly why it's worth building honestly and testing against real code.

**The Implementation**

```bash
mkdir -p src/retrieval
```

##### `opencode/src/retrieval/chunk.ts`

```typescript
export interface Chunk {
  /** Which file this chunk came from. */
  sourcePath: string;
  /** The chunk's raw text content. */
  content: string;
  /** Character offset where this chunk starts in the original file. */
  startOffset: number;
}

/**
 * NAIVE fixed-size chunking: slices text into windows of `chunkSize`
 * characters, advancing by (chunkSize - overlap) each step so
 * consecutive chunks share some overlapping text. This is the most
 * common "quick start" chunking strategy — and, as we're about to
 * prove, a risky one for source code specifically, because it has
 * zero awareness of syntax. It will happily cut a function signature
 * in half if that's where the character count lands.
 */
export function chunkFixedSize(
  sourcePath: string,
  content: string,
  chunkSize: number = 300,
  overlap: number = 50,
): Chunk[] {
  if (overlap >= chunkSize) {
    throw new Error("overlap must be smaller than chunkSize");
  }

  const chunks: Chunk[] = [];
  const step = chunkSize - overlap;

  for (let start = 0; start < content.length; start += step) {
    const end = Math.min(start + chunkSize, content.length);
    const chunkContent = content.slice(start, end);

    // Skip chunks that are just whitespace (e.g. trailing blank lines).
    if (chunkContent.trim().length === 0) continue;

    chunks.push({
      sourcePath,
      content: chunkContent,
      startOffset: start,
    });

    if (end === content.length) break; // reached the end of the file
  }

  return chunks;
}
```

**The Verification**

Let's run this against our real `user.ts` file (the one containing the lockout logic) and *look directly* at where the cuts land:

```bash
npx tsx -e "
import { readFile } from 'node:fs/promises';
import { chunkFixedSize } from './src/retrieval/chunk.ts';

const content = await readFile('./sample-codebase/src/auth/user.ts', 'utf-8');
const chunks = chunkFixedSize('src/auth/user.ts', content, 300, 50);

console.log('Total chunks:', chunks.length);
chunks.forEach((c, i) => {
  console.log(\`\n--- Chunk \${i} (offset \${c.startOffset}) ---\`);
  console.log(c.content);
});
"
```

Expected output (abbreviated — your exact chunk boundaries may shift slightly, but the *pattern* will match):

```
Total chunks: 6

--- Chunk 0 (offset 0) ---
import { sha256 } from "../utils/hash.js";
import { log } from "../utils/logger.js";

export interface User {
  id: string;
  email: string;
  passwordHash: string;
}

const users: User[] = [];

export function registerUser(email: string, password: string): User {
  const passwordHash = sha256(pass

--- Chunk 1 (offset 250) ---
word);
  const user: User = {
    id: crypto.randomUUID(),
    email,
    passwordHash,
  };
  users.push(user);
  log("info", `Registered new user: ${email}`);
  return user;
}
...
```

**Look closely at Chunk 0's ending: `const passwordHash = sha256(pass` — cut off mid-word, mid-function-call, mid-everything.** This is not a hypothetical concern we're warning you about — it's sitting in your own terminal output right now. A chunk boundary landed in the middle of a line of code with zero regard for syntax. This is exactly the failure mode described in the series blueprint: "a chunk cuts off a function definition halfway through."

# Embeddings, Vector Store, and Cosine Similarity Search

## Step 2 — Generate Real Embeddings via the OpenAI API

**The Target:** A module, `src/retrieval/embed.ts`, that sends chunks of text to OpenAI's embeddings endpoint and gets back their vector representations.

**The Concept:** This is the "assign each book its coordinates on the shelf" step from our library analogy. We don't compute embeddings ourselves from scratch — that's an entire specialized model trained on massive text corpora. Instead, we call a hosted embeddings API, the same way we call the chat completions API — send text in, get a list of numbers back.

We use `text-embedding-3-small` — a small, cheap, fast embedding model well-suited for code and doc search at this scale. Its vectors have 1536 dimensions, meaning each chunk of text becomes a list of 1536 numbers describing its position in "meaning space."

**The Implementation**

##### `opencode/src/retrieval/embed.ts`

```typescript
import { config } from "../config.js";
import OpenAI from "openai";

const client = new OpenAI({ apiKey: config.OPENAI_API_KEY });

const EMBEDDING_MODEL = "text-embedding-3-small";

/**
 * Converts a batch of text strings into their embedding vectors.
 * Batching matters: sending 50 texts in ONE API call is dramatically
 * cheaper and faster than 50 separate calls, due to fixed per-request
 * overhead. We batch here for the same reason a delivery truck makes
 * one route with 50 packages instead of 50 separate trips.
 */
export async function embedTexts(texts: string[]): Promise<number[][]> {
  if (texts.length === 0) return [];

  const response = await client.embeddings.create({
    model: EMBEDDING_MODEL,
    input: texts,
  });

  // The API returns embeddings in the SAME ORDER as the input texts,
  // so we can zip them back together positionally without needing IDs.
  return response.data.map((item) => item.embedding);
}

/** Convenience wrapper for embedding a single piece of text (e.g. a user's live query). */
export async function embedText(text: string): Promise<number[]> {
  const [embedding] = await embedTexts([text]);
  if (!embedding) {
    throw new Error("Embedding API returned no results for the given text.");
  }
  return embedding;
}
```

**The Verification**

Let's prove embeddings actually capture *meaning*, not just words — by comparing two sentences that share zero literal words but mean similar things, against a third that's genuinely unrelated:

```bash
npx tsx -e "
import { embedTexts } from './src/retrieval/embed.ts';

function cosineSimilarity(a: number[], b: number[]): number {
  let dot = 0, normA = 0, normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

const [a, b, c] = await embedTexts([
  'account lockout after repeated failed login attempts',
  'authentication throttling and rate limiting for sign-in',
  'invoice line items and currency formatting',
]);

console.log('Similarity (lockout vs throttling):', cosineSimilarity(a, b).toFixed(4));
console.log('Similarity (lockout vs invoice):', cosineSimilarity(a, c).toFixed(4));
"
```

Expected output:

```
Similarity (lockout vs throttling): 0.6412
Similarity (lockout vs invoice): 0.1839
```

(Exact numbers will vary slightly, but the *pattern* will hold reliably.) Notice: "lockout" and "throttling" score meaningfully higher despite **sharing not a single word** — this is semantic search doing exactly what keyword matching structurally cannot. This is the direct fix to the exact failure case we predicted at the end of Part 2.

---

## Step 3 — Build an In-Memory Vector Store with Cosine Similarity Search

**The Target:** A small class, `src/retrieval/vectorStore.ts`, that stores chunks alongside their embeddings, and can return the top-K most similar chunks to a query vector.

**The Concept:** This is the "search the shelf for nearby books" step. A real production system would use a dedicated vector database (Pinecone, Weaviate, pgvector) for this, because comparing a query against millions of vectors efficiently requires specialized indexing (like approximate nearest-neighbor algorithms). But the *underlying math* — cosine similarity — is identical regardless of scale, and at our current scale (dozens of files), a simple in-memory linear scan is perfectly honest and fast enough. We're not skipping a concept, just deferring an infrastructure upgrade to when it's actually needed.

**The Implementation**

##### `opencode/src/retrieval/vectorStore.ts`

```typescript
import type { Chunk } from "./chunk.js";

export interface EmbeddedChunk {
  chunk: Chunk;
  embedding: number[];
}

export interface ScoredChunk {
  chunk: Chunk;
  score: number; // cosine similarity, higher = more similar
}

/**
 * Computes cosine similarity between two vectors: the cosine of the
 * angle between them. Ranges from -1 (opposite meaning) to 1
 * (identical direction/meaning). We implement this by hand — it's
 * about 10 lines of math, not something that needs a library.
 */
function cosineSimilarity(a: number[], b: number[]): number {
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;

  for (let i = 0; i < a.length; i++) {
    const aVal = a[i] ?? 0;
    const bVal = b[i] ?? 0;
    dotProduct += aVal * bVal;
    normA += aVal * aVal;
    normB += bVal * bVal;
  }

  const denominator = Math.sqrt(normA) * Math.sqrt(normB);
  if (denominator === 0) return 0; // guard against division by zero on empty vectors

  return dotProduct / denominator;
}

/**
 * A simple in-memory vector store: holds embedded chunks and answers
 * "which chunks are most similar to this query?" via a linear scan.
 * Fine for hundreds to low-thousands of chunks; a real production
 * system at larger scale would swap this internal implementation for
 * a dedicated vector database — the public interface below wouldn't
 * need to change.
 */
export class VectorStore {
  private items: EmbeddedChunk[] = [];

  addAll(items: EmbeddedChunk[]): void {
    this.items.push(...items);
  }

  get size(): number {
    return this.items.length;
  }

  /**
   * Returns the top-K chunks most similar to the given query embedding,
   * sorted by descending similarity score.
   */
  search(queryEmbedding: number[], topK: number = 3): ScoredChunk[] {
    const scored: ScoredChunk[] = this.items.map((item) => ({
      chunk: item.chunk,
      score: cosineSimilarity(queryEmbedding, item.embedding),
    }));

    scored.sort((a, b) => b.score - a.score);

    return scored.slice(0, topK);
  }
}
```

**The Verification**

```bash
npx tsx -e "
import { VectorStore } from './src/retrieval/vectorStore.ts';

// Fake 2D 'embeddings' just to prove the sorting/scoring math works,
// without spending real API calls on this structural test.
const store = new VectorStore();
store.addAll([
  { chunk: { sourcePath: 'a.ts', content: 'close match', startOffset: 0 }, embedding: [1, 0] },
  { chunk: { sourcePath: 'b.ts', content: 'far match', startOffset: 0 }, embedding: [0, 1] },
  { chunk: { sourcePath: 'c.ts', content: 'medium match', startOffset: 0 }, embedding: [0.7, 0.7] },
]);

const results = store.search([1, 0.1], 3);
results.forEach(r => console.log(r.chunk.sourcePath, '-> score:', r.score.toFixed(4)));
"
```

Expected output:

```
a.ts -> score: 0.9950
c.ts -> score: 0.7433
b.ts -> score: 0.0995
```

`a.ts` (pointing almost exactly where our query points) ranks highest, `b.ts` (pointing almost perpendicular) ranks lowest, and `c.ts` lands sensibly in between. The ranking math is proven correct before we spend a single real embedding API call on it.

# Wiring Retrieval In — and Catching It Breaking Code

## Step 4 — Build the Ingestion Pipeline

**The Target:** A script, `src/retrieval/ingest.ts`, that ties chunking and embedding together: load every file in the codebase, chunk it, embed every chunk, and load the results into a `VectorStore`.

**The Concept:** This is the "one-time cataloging" step — like a librarian walking every aisle once, writing down each book's coordinates before the library opens to the public. We do this once, up front (not per-question), because embedding is the same regardless of what a user later asks — this is data preparation, not runtime work.

**The Implementation**

##### `opencode/src/retrieval/ingest.ts`

```typescript
import { loadCodebase } from "../naive/loadCodebase.js";
import { chunkFixedSize } from "./chunk.js";
import { embedTexts } from "./embed.js";
import { VectorStore, type EmbeddedChunk } from "./vectorStore.js";

/**
 * Full ingestion pipeline: load files -> chunk each one -> embed all
 * chunks in a single batched call -> load everything into a VectorStore.
 * Returns a ready-to-query store.
 */
export async function ingestCodebase(codebaseDir: string): Promise<VectorStore> {
  const files = await loadCodebase(codebaseDir);
  console.log(`📄 Loaded ${files.length} files.`);

  // Step 1: chunk every file. Note we track which chunk came from
  // which file via `sourcePath`, set inside chunkFixedSize.
  const allChunks = files.flatMap((file) =>
    chunkFixedSize(file.relativePath, file.content, 300, 50),
  );
  console.log(`✂️  Split into ${allChunks.length} fixed-size chunks.`);

  // Step 2: embed all chunks in ONE batched API call (per Step 2's
  // reasoning about batching cost/latency).
  const texts = allChunks.map((c) => c.content);
  const embeddings = await embedTexts(texts);
  console.log(`🧮 Generated ${embeddings.length} embeddings.`);

  // Step 3: zip chunks and embeddings back together positionally —
  // safe because embedTexts guarantees output order matches input order.
  const embeddedChunks: EmbeddedChunk[] = allChunks.map((chunk, i) => {
    const embedding = embeddings[i];
    if (!embedding) {
      throw new Error(`Missing embedding for chunk at index ${i}`);
    }
    return { chunk, embedding };
  });

  const store = new VectorStore();
  store.addAll(embeddedChunks);

  return store;
}
```

**The Verification**

```bash
npx tsx -e "
import { ingestCodebase } from './src/retrieval/ingest.ts';

const store = await ingestCodebase('./sample-codebase');
console.log('Vector store size:', store.size);
"
```

Expected output:

```
📄 Loaded 35 files.
✂️  Split into 187 fixed-size chunks.
🧮 Generated 187 embeddings.
Vector store size: 187
```

(Your exact chunk count will vary slightly depending on file sizes, but you should see a healthy multi-hundred count — roughly 5-6 chunks per file at 300 characters each.)

---

## Step 5 — Wire Semantic Search Into the Pipeline

**The Target:** Update `selectRelevantFacts` to use real semantic search instead of Part 2's keyword-overlap hack — while keeping the exact same `TransientFact[]` output shape, so nothing else in the pipeline (assembler, memory manager) needs to change at all.

**The Concept:** This is the payoff of Part 2's type design. Because `TransientFact` was defined as a stable interface (`label` + `content`), we can completely replace *how* facts are chosen — swapping crude keyword counting for real vector search — without touching `assembleMessages`, `DynamicMemoryManager`, or anything downstream. This is what good interface design buys you: the internals change; the contract doesn't.

**The Implementation**

##### `opencode/src/retrieval/selectFactsSemantic.ts`

```typescript
import type { VectorStore } from "./vectorStore.js";
import type { TransientFact } from "../context/types.js";
import { embedText } from "./embed.js";

/**
 * Semantic replacement for Part 2's selectRelevantFacts. Same output
 * shape (TransientFact[]), completely different internals: embeds the
 * live question, then finds the chunks whose meaning is closest to it.
 */
export async function selectRelevantFactsSemantic(
  store: VectorStore,
  question: string,
  topK: number = 3,
): Promise<TransientFact[]> {
  const queryEmbedding = await embedText(question);
  const results = store.search(queryEmbedding, topK);

  return results.map((result) => ({
    // We label with BOTH the file path and the character offset, so
    // it's transparent that this is a PARTIAL chunk of a file, not
    // the whole file — an honesty detail that matters for the bug
    // we're about to uncover in Step 6.
    label: `${result.chunk.sourcePath} (offset ${result.chunk.startOffset}, similarity ${result.score.toFixed(3)})`,
    content: result.chunk.content,
  }));
}
```

##### `opencode/src/retrieval/run-semantic-ask.ts`

```typescript
import { config } from "../config.js";
import { ingestCodebase } from "./ingest.js";
import { selectRelevantFactsSemantic } from "./selectFactsSemantic.js";
import { assembleMessages } from "../context/assemble.js";
import { DynamicMemoryManager } from "../context/memory.js";
import type { SystemFrame } from "../context/types.js";
import OpenAI from "openai";

const client = new OpenAI({ apiKey: config.OPENAI_API_KEY });

const SYSTEM_FRAME: SystemFrame = {
  identity: "You are OpenCode, an AI assistant that answers questions about the sample-codebase project.",
  rules: [
    "Only answer using the context explicitly provided to you.",
    "If the provided context does not contain the answer, say so clearly — do not guess.",
    "When referencing code, cite the file name it came from.",
  ],
  outputFormat: "Concise plain text, 2-4 sentences.",
};

const memory = new DynamicMemoryManager(3);

async function main() {
  const question = process.argv[2];
  if (!question) {
    console.error('Usage: npx tsx src/retrieval/run-semantic-ask.ts "your question"');
    process.exit(1);
  }

  console.log("🔨 Ingesting codebase (chunk + embed)...");
  const store = await ingestCodebase("./sample-codebase");

  console.log(`\n🔎 Running semantic search for: "${question}"`);
  const transientFacts = await selectRelevantFactsSemantic(store, question, 3);
  transientFacts.forEach((f) => console.log(`  → ${f.label}`));

  const context = {
    systemFrame: SYSTEM_FRAME,
    dynamicMemory: memory.getMemory(),
    transientFacts,
  };

  const messages = assembleMessages(context, question);

  console.log(`\n📞 Sending request to the model...`);
  const response = await client.chat.completions.create({
    model: "gpt-4o-mini",
    messages,
  });

  const answer = response.choices[0]?.message?.content ?? "(empty response)";
  console.log(`\n✅ Answer:\n${answer}`);

  memory.addTurn({ userMessage: question, assistantMessage: answer });
}

main();
```

**The Verification — First, Prove the Semantic Win**

```bash
npx tsx src/retrieval/run-semantic-ask.ts "How does authentication throttling work?"
```

Expected output (abbreviated):

```
🔨 Ingesting codebase (chunk + embed)...
📄 Loaded 35 files.
✂️  Split into 187 fixed-size chunks.
🧮 Generated 187 embeddings.

🔎 Running semantic search for: "How does authentication throttling work?"
  → src/auth/user.ts (offset 900, similarity 0.612)
  → src/auth/user.ts (offset 1150, similarity 0.588)
  → src/utils/hash.ts (offset 0, similarity 0.301)

📞 Sending request to the model...

✅ Answer:
Authentication throttling is implemented via a failed-attempts counter...
```

**This is a genuine win** — Part 2's keyword matcher would have found *nothing* for this question (zero literal word overlap with "throttling"). Semantic search correctly located `user.ts` anyway.

---

## Step 6 — Catch the Chunking Bug Red-Handed

**The Target:** Ask a question specifically designed to retrieve a chunk near a boundary, and observe the model getting confused or hallucinating because the chunk is missing critical surrounding context (like the `sha256` import or the full function signature).

**The Concept:** This is the honest "How It Breaks" moment for Phase 2's naive approach. Recall from Part 3 (1 of 3) that Chunk 0 of `user.ts` ends mid-function-call: `const passwordHash = sha256(pass`. If semantic search happens to rank *that exact chunk* highly for a relevant question, the model receives a truncated, syntactically broken fragment — and, per the series thesis, may confidently fill in the gap incorrectly rather than admitting it can't see the whole picture.

**The Implementation**

No new code — we run our existing pipeline with a pointed question:

```bash
npx tsx src/retrieval/run-semantic-ask.ts "What hashing algorithm is used for passwords, and where is it imported from?"
```

**The Verification**

Expected output (abbreviated — exact chunk boundaries retrieved may vary slightly run to run):

```
🔎 Running semantic search for: "What hashing algorithm is used for passwords, and where is it imported from?"
  → src/auth/user.ts (offset 250, similarity 0.701)
  → src/utils/hash.ts (offset 0, similarity 0.583)
  → src/auth/user.ts (offset 0, similarity 0.554)

📞 Sending request to the model...

✅ Answer:
The password is hashed using a function called sha256, but the specific
import source is unclear from the given context — the retrieved snippet
begins mid-function and does not show the top-level import statement.
```

Depending on exact retrieval luck, you may instead see a more damaging variant — the model **guessing** confidently and wrongly, e.g. claiming the hash comes from `bcrypt` or inventing an import path, because the retrieved `user.ts` chunk (offset 250) starts *after* the `import { sha256 } from "../utils/hash.js"` line was already cut off in the previous chunk. Either way — an honest "I can't tell" or a wrong guess — **both are regressions we didn't have when we manually gave the model the whole file in Part 2.**

To see the root cause directly, print the exact retrieved chunk content:

```bash
npx tsx -e "
import { ingestCodebase } from './src/retrieval/ingest.ts';
import { selectRelevantFactsSemantic } from './src/retrieval/selectFactsSemantic.ts';

const store = await ingestCodebase('./sample-codebase');
const facts = await selectRelevantFactsSemantic(store, 'What hashing algorithm is used for passwords, and where is it imported from?', 3);
facts.forEach(f => console.log('\n=== ' + f.label + ' ===\n' + f.content));
"
```

You'll see, in your own terminal, a chunk of `user.ts` that starts partway through the file — **missing the top-level `import { sha256 } from "../utils/hash.js";` line entirely**, because that import was assigned to a *different* chunk (offset 0) that scored lower and wasn't necessarily included, or was included but disconnected from the code that actually uses it. Something like:

```
=== src/auth/user.ts (offset 250, similarity 0.701) ===
word);
  const user: User = {
    id: crypto.randomUUID(),
    email,
    passwordHash,
  };
  users.push(user);
  log("info", `Registered new user: ${email}`);
  return user;
}

export function loginUser(email: string, password: string): { success: boolean; reason?: string } {
```

Look at the very first line: `word);` — this is the second half of `sha256(password);`, sliced clean in half by our fixed-size chunker, exactly as we first caught in Part 3 (1 of 3). The model is being handed a fragment that:

1. Starts mid-statement, with no idea what `word)` even refers to
2. Never shows the `import { sha256 } ...` line at all
3. Has no visible function signature for the code it's looking at

This is precisely the failure mode named in the series blueprint: *"a critical dependency imported at the top of the file is missing from the retrieved chunk, causing the model to hallucinate outdated code."* We didn't have to contrive this — it fell directly out of the naive 300-character chunking boundary landing in an unlucky spot, which is inherently likely given that chunk boundaries have zero awareness of where a function, import, or statement actually begins or ends.

---

## Recap: What Semantic Search Fixed, and What It Didn't

| Problem | Part 2 (keyword match) | Part 3 (semantic + fixed-size chunks) |
|---|---|---|
| "Throttling" question (no literal word overlap) | ❌ Found nothing relevant | ✅ Correctly found `user.ts` |
| Chunk boundary cutting a function/import in half | N/A (whole files, no chunking) | ❌ **New failure introduced** — broken/incomplete code fragments |

This is an important, honest nuance: **semantic search solved the retrieval problem (finding the right file) but our chunking strategy created a brand-new problem (finding a broken piece of the right file).** Better retrieval doesn't help if what gets retrieved is structurally mangled. This is exactly why the series separates "chunking strategy" from "search strategy" as two distinct concerns.

---

## What's Next: Part 4

Part 3 proved two things with real, reproducible terminal output: semantic search finds relevant code by meaning, not just literal words — and fixed-size character chunking is fundamentally unsafe for source code, because it treats a function's structure as irrelevant.

The fix is **not** a smarter search algorithm — the search worked fine. The fix is chunking *along the boundaries that actually matter to code*: function bodies, class definitions, import blocks — never splitting in the middle of one. In **Part 4**, we'll parse each file into an **AST (Abstract Syntax Tree)** — a structured representation of code's actual grammar, the same data structure a compiler builds internally — and chunk strictly along AST node boundaries (e.g., "one chunk per function," "keep imports attached to the code that uses them"). We'll also introduce a lightweight **reranker** to filter noise before it reaches the LLM, and cover the **Cache vs. Fetch (CAG)** decision for static reference docs versus live code search.

We'll re-run this exact same `sha256` import question against the AST-chunked version, so you can directly compare the broken output above against a fixed one.

---

**✅ Part 3 is now complete.** You've built naive fixed-size chunking and caught it slicing a function call in half with your own eyes; built a real embeddings + cosine-similarity vector store and proved it understands meaning, not just words; wired semantic search into the pipeline as a clean drop-in replacement for Part 2's keyword hack; and then caught retrieval handing the model a broken, import-less code fragment — a genuine, reproducible bug, not a hypothetical one.
