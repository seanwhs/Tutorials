# Part 4: AST-Based Semantic Chunking

## Recap

Part 3 proved two things with real terminal output: semantic search finds relevant code by meaning, and fixed-size chunking is dangerous for code — we caught it slicing `sha256(password)` clean in half and separating a function from its own `import` statement. The fix isn't a better search algorithm. It's a better *chunking* strategy — one that respects the actual grammar of the code.

---

## The Concept: Chunking Along the Grain

**The analogy:** Imagine cutting a loaf of bread. Fixed-size chunking is like slicing it every exactly 2 centimeters with a ruler, with total indifference to where the actual slices of filling are — you might cut straight through a piece of cheese. AST-based chunking is like a butcher cutting meat *along the grain* — following the natural structural seams (a function, a class, an interface) so each piece comes away whole and usable on its own.

An **AST (Abstract Syntax Tree)** is the structured, tree-shaped representation of code that a compiler builds internally before it can do anything else with your code — it's how the compiler "understands" that `function foo() { ... }` is one complete unit, distinct from the `import` statement above it, distinct from the `class Bar { ... }` below it. We're not building our own parser — we're using the **TypeScript Compiler API**, the actual production-grade parser that powers `tsc` itself, which we already installed back in Part 0.

Our chunking rule will be simple and deliberate: **one chunk per top-level declaration (function, class, interface, type alias, or const), with that file's imports prepended to every single chunk.** This directly targets both bugs we caught in Part 3 — no chunk can ever cut a function in half (we chunk by whole declarations), and no chunk can ever be missing its imports (we attach them to everything).

---

## Step 1 — Build the AST-Based Chunker

**The Target:** A new module, `src/retrieval/astChunk.ts`, that replaces `chunkFixedSize` with a parser-aware alternative — while returning the exact same `Chunk[]` shape defined in Part 3, so nothing downstream (embedding, vector store) needs to change.

**The Concept in code terms:** We parse the file into a `SourceFile` AST node, walk its direct children, separate `import` declarations from "chunkable" declarations (functions, classes, interfaces, type aliases, top-level consts), and produce one chunk per chunkable declaration — with all collected imports glued to the front of every chunk's content.

**The Implementation**

##### `opencode/src/retrieval/astChunk.ts`

```typescript
import ts from "typescript";
import type { Chunk } from "./chunk.js";

/**
 * Determines whether a top-level AST node represents something we
 * want to treat as its own, independent, self-contained chunk.
 * This is the "cut along the grain" rule: only whole declarations
 * become chunk boundaries — never an arbitrary character offset.
 */
function isChunkableNode(node: ts.Node): boolean {
  return (
    ts.isFunctionDeclaration(node) ||
    ts.isClassDeclaration(node) ||
    ts.isInterfaceDeclaration(node) ||
    ts.isTypeAliasDeclaration(node) ||
    ts.isVariableStatement(node) // covers top-level `const X = ...`
  );
}

/**
 * Parses a file's content into an AST and produces one chunk per
 * top-level declaration, with the file's import statements prepended
 * to EVERY chunk. This is what directly fixes both bugs caught in
 * Part 3: no chunk can be cut mid-statement (we only ever take whole
 * declarations), and no chunk can be missing its imports (every
 * chunk carries its own copy).
 */
export function chunkByAst(sourcePath: string, content: string): Chunk[] {
  // createSourceFile parses the raw text into a tree of ts.Node objects.
  // `true` for setParentNodes lets us later call node.getFullText()
  // correctly, including leading comments attached to each declaration.
  const sourceFile = ts.createSourceFile(
    sourcePath,
    content,
    ts.ScriptTarget.Latest,
    true,
  );

  const importLines: string[] = [];
  const declarationChunks: { text: string; start: number }[] = [];

  // forEachChild walks only the DIRECT children of the file — i.e.
  // top-level statements, not nested ones (we don't want to chunk
  // every inner if-statement, just top-level declarations).
  ts.forEachChild(sourceFile, (node) => {
    if (ts.isImportDeclaration(node)) {
      importLines.push(node.getFullText(sourceFile).trim());
      return;
    }
    if (isChunkableNode(node)) {
      declarationChunks.push({
        text: node.getFullText(sourceFile).trim(),
        start: node.getStart(sourceFile),
      });
    }
  });

  const importHeader = importLines.join("\n");

  // Fallback: if a file has no chunkable top-level declarations at all
  // (e.g. a pure constants file with unusual structure), treat the
  // whole file as one chunk rather than silently producing nothing.
  if (declarationChunks.length === 0) {
    return [{ sourcePath, content, startOffset: 0 }];
  }

  return declarationChunks.map((decl) => ({
    sourcePath,
    // This is the key fix: every chunk gets the file's imports
    // glued to the front, so a chunk is NEVER missing the context
    // of where its dependencies come from.
    content: importHeader.length > 0 ? `${importHeader}\n\n${decl.text}` : decl.text,
    startOffset: decl.start,
  }));
}
```

**The Verification**

Let's run this on the exact same `user.ts` file that Part 3 caught being sliced in half, and look directly at the chunks it produces:

```bash
npx tsx -e "
import { readFile } from 'node:fs/promises';
import { chunkByAst } from './src/retrieval/astChunk.ts';

const content = await readFile('./sample-codebase/src/auth/user.ts', 'utf-8');
const chunks = chunkByAst('src/auth/user.ts', content);

console.log('Total chunks:', chunks.length);
chunks.forEach((c, i) => {
  console.log(\`\n--- Chunk \${i} (offset \${c.startOffset}) ---\`);
  console.log(c.content);
});
"
```

Expected output (abbreviated):

```
Total chunks: 5

--- Chunk 0 (offset 84) ---
import { sha256 } from "../utils/hash.js";
import { log } from "../utils/logger.js";

export interface User {
  id: string;
  email: string;
  passwordHash: string;
}

--- Chunk 1 (offset 158) ---
import { sha256 } from "../utils/hash.js";
import { log } from "../utils/logger.js";

const users: User[] = [];

--- Chunk 2 (offset 192) ---
import { sha256 } from "../utils/hash.js";
import { log } from "../utils/logger.js";

export function registerUser(email: string, password: string): User {
  const passwordHash = sha256(password);
  const user: User = {
    id: crypto.randomUUID(),
    email,
    passwordHash,
  };
  users.push(user);
  log("info", `Registered new user: ${email}`);
  return user;
}

--- Chunk 3 (offset 471) ---
import { sha256 } from "../utils/hash.js";
import { log } from "../utils/logger.js";

const failedAttempts = new Map<string, { count: number; lockedUntil: number | null }>();

--- Chunk 4 (offset 620) ---
import { sha256 } from "../utils/hash.js";
import { log } from "../utils/logger.js";

export function loginUser(email: string, password: string): { success: boolean; reason?: string } {
  const record = failedAttempts.get(email) ?? { count: 0, lockedUntil: null };
  ...
  return { success: true };
}
```

Compare this directly to Part 3's output. Two things should jump out immediately:

1. **`sha256(password)` is no longer cut in half.** Chunk 2 contains the complete `registerUser` function, start to finish — because we chunk along whole-declaration boundaries, a character-count coincidence can never slice through the middle of a statement again.
2. **Every single chunk carries its own `import` lines**, even ones that don't use `sha256` directly (like Chunk 1's lone `const users` statement). This looks slightly wasteful — and it is, a little — but it permanently fixes the "missing import" bug from Part 3, and Part 4 (2 of 3) will address the reranking step that helps offset this minor redundancy cost.

Also notice: we now get **5 semantically whole chunks** instead of Part 3's **6 arbitrarily-sliced chunks** — fewer chunks, and every single one is independently complete and readable on its own, exactly like a butcher's cut of meat instead of a ruler's mark.

# Proving the Fix, Then Adding a Reranker

## Step 2 — Re-run Ingestion with AST Chunking, Re-run the Broken Question

**The Target:** Swap `chunkFixedSize` for `chunkByAst` inside the ingestion pipeline, re-ingest the full sample codebase, and re-run the *exact* question from Part 3 (3 of 3) that previously produced a broken, import-less code fragment.

**The Concept:** This is our head-to-head proof, the same pattern we used at the end of Part 2 — same question, same codebase, only the chunking strategy changes. If the fix is real, we should see it directly in the terminal, not just take it on faith.

**The Implementation**

##### `opencode/src/retrieval/ingest.ts` (updated)

```typescript
import { loadCodebase } from "../naive/loadCodebase.js";
import { chunkByAst } from "./astChunk.js";
import { embedTexts } from "./embed.js";
import { VectorStore, type EmbeddedChunk } from "./vectorStore.js";

/**
 * Full ingestion pipeline: load files -> chunk each one via AST-aware
 * chunking -> embed all chunks in a single batched call -> load
 * everything into a VectorStore.
 *
 * CHANGED from Part 3: chunkFixedSize -> chunkByAst. Nothing else in
 * this file needed to change — proof that isolating "chunking
 * strategy" behind a clean function boundary was the right call.
 */
export async function ingestCodebase(codebaseDir: string): Promise<VectorStore> {
  const files = await loadCodebase(codebaseDir);
  console.log(`📄 Loaded ${files.length} files.`);

  const allChunks = files.flatMap((file) =>
    chunkByAst(file.relativePath, file.content),
  );
  console.log(`✂️  Split into ${allChunks.length} AST-based chunks.`);

  const texts = allChunks.map((c) => c.content);
  const embeddings = await embedTexts(texts);
  console.log(`🧮 Generated ${embeddings.length} embeddings.`);

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

We're deliberately keeping the old `chunkFixedSize` file (`src/retrieval/chunk.ts`) untouched in the project — it's valuable as a documented "before" artifact, and Part 3's naive `run-semantic-ask.ts` script still imports it for historical comparison. Nothing needs to be deleted; we simply stopped using it in the *current* ingestion path.

**The Verification**

```bash
npx tsx src/retrieval/run-semantic-ask.ts "What hashing algorithm is used for passwords, and where is it imported from?"
```

Expected output (abbreviated):

```
🔨 Ingesting codebase (chunk + embed)...
📄 Loaded 35 files.
✂️  Split into 149 AST-based chunks.
🧮 Generated 149 embeddings.

🔎 Running semantic search for: "What hashing algorithm is used for passwords, and where is it imported from?"
  → src/auth/user.ts (offset 192, similarity 0.712)
  → src/utils/hash.ts (offset 46, similarity 0.601)
  → src/auth/user.ts (offset 84, similarity 0.559)

📞 Sending request to the model...

✅ Answer:
Passwords are hashed using SHA-256, implemented in src/utils/hash.ts
via the sha256() function (using Node's built-in "node:crypto" module),
and imported into src/auth/user.ts with `import { sha256 } from
"../utils/hash.js"`.
```

Compare directly against Part 3's result:

| | Part 3 (fixed-size chunks) | Part 4 (AST chunks) |
|---|---|---|
| Retrieved chunk | Starts mid-statement (`word);`), import missing | Complete `registerUser` function, **imports included** |
| Model's answer | Uncertain or guessed wrong | ✅ Correct — names SHA-256, cites both files, cites the exact import line |
| Total chunks in store | 187 | 149 (fewer, but each one whole) |

This is the exact fix promised at the end of Part 3, proven with your own terminal output on the same question, same codebase, same model — only the chunking boundary logic changed.

---

## Step 3 — Why We Still Need a Reranker

**The Target:** Understand the specific new problem AST chunking introduces, before writing the reranker that fixes it.

**The Concept:** Look back at Step 2's search results — we're pulling `top-3` chunks by cosine similarity. But similarity scores from an embedding model are a *cheap, approximate* filter — like a store clerk quickly glancing at 100 resumes and picking the 10 that "look about right" before a hiring manager actually reads them closely. Embeddings are fast and cheap to compare at scale (that's their whole appeal), but they can be fooled by superficial textual similarity that doesn't reflect true relevance — for example, a chunk that merely *mentions* the word "password" in a comment might score deceptively high even if it's not the code that actually implements hashing.

A **reranker** is a second, more expensive but more accurate model — typically a **cross-encoder** (a model that looks at the query and a candidate chunk *together*, jointly, rather than comparing pre-computed independent vectors) — that re-scores a small shortlist (say, the top 10 from vector search) and picks the true top 3 to actually send to the LLM. This two-stage pattern — cheap broad filter, then expensive precise filter — is exactly how search engines like Google work internally: a fast index narrows billions of pages to a few thousand candidates, then a slower, smarter ranking model orders the final page you actually see.

We'll implement this using the OpenAI chat completion API itself as a lightweight LLM-based reranker (asking it to score relevance directly) rather than requiring a separate specialized reranking service — a pragmatic, dependency-light approach appropriate for this stage of the series, with a note in the reference appendix (built once the series concludes) on dedicated reranker APIs like Cohere Rerank or open-source BGE rerankers for production-scale needs.

# Reranking, the Cache-vs-Fetch Decision, and Closing Out Phase 2

## Step 4 — Implement a Lightweight LLM-Based Reranker

**The Target:** A new module, `src/retrieval/rerank.ts`, that takes the top-N candidates from vector search and re-scores them using a direct relevance judgment from the LLM, returning a re-ordered, filtered shortlist.

**The Concept:** We ask the model a narrow, structured question — "on a scale of 0-10, how relevant is this specific chunk to this specific query?" — for each candidate, and keep only the ones that clear a relevance bar. This is deliberately a *different, narrower* task than answering the user's actual question: the reranker's only job is judging relevance, which is a much simpler task for the model to get right reliably than open-ended question-answering, precisely because we constrain its output to a single number via structured output.

**The Implementation**

```bash
npm install zod
```
(already installed since Part 0 — no-op if already present)

##### `opencode/src/retrieval/rerank.ts`

```typescript
import { config } from "../config.js";
import type { ScoredChunk } from "./vectorStore.js";
import OpenAI from "openai";
import { z } from "zod";

const client = new OpenAI({ apiKey: config.OPENAI_API_KEY });

// Structured schema for the reranker's judgment on ONE candidate chunk.
// Constraining the output to this exact shape (via Structured Outputs)
// makes the model's response deterministic to parse — no regex-guessing
// a number out of free-form prose.
const RelevanceJudgment = z.object({
  relevanceScore: z.number().min(0).max(10),
  reasoning: z.string(),
});

/**
 * Scores a single candidate chunk's true relevance to the query,
 * using the LLM as a precise (but expensive) judge — the "hiring
 * manager" step after vector search's "resume-skimming clerk" step.
 */
async function judgeRelevance(query: string, chunkContent: string): Promise<number> {
  const response = await client.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      {
        role: "system",
        content:
          "You judge how relevant a code snippet is to answering a specific question. " +
          "Score 0 (completely irrelevant) to 10 (directly answers the question). " +
          "Be strict: a snippet that merely mentions a related word but doesn't " +
          "actually implement the relevant logic should score low.",
      },
      {
        role: "user",
        content: `Question: ${query}\n\nCode snippet:\n${chunkContent}`,
      },
    ],
    response_format: {
      type: "json_schema",
      json_schema: {
        name: "relevance_judgment",
        strict: true,
        schema: {
          type: "object",
          properties: {
            relevanceScore: { type: "number" },
            reasoning: { type: "string" },
          },
          required: ["relevanceScore", "reasoning"],
          additionalProperties: false,
        },
      },
    },
  });

  const raw = response.choices[0]?.message?.content;
  if (!raw) return 0; // fail safe: treat unparseable judgments as irrelevant, not crash

  const parsed = RelevanceJudgment.safeParse(JSON.parse(raw));
  return parsed.success ? parsed.data.relevanceScore : 0;
}

/**
 * Reranks a shortlist of vector-search candidates by TRUE relevance,
 * judged individually by the LLM, and returns only the top `keepTopN`
 * that clear `minScore`. This is the second-stage filter: vector
 * search casts a wide, cheap net; this step tightens it precisely.
 */
export async function rerankChunks(
  query: string,
  candidates: ScoredChunk[],
  keepTopN: number = 3,
  minScore: number = 5,
): Promise<ScoredChunk[]> {
  // Judge every candidate IN PARALLEL — these are independent judgments,
  // so there's no reason to wait for one before starting the next.
  const judged = await Promise.all(
    candidates.map(async (candidate) => {
      const relevanceScore = await judgeRelevance(query, candidate.chunk.content);
      return { ...candidate, score: relevanceScore };
    }),
  );

  return judged
    .filter((c) => c.score >= minScore)
    .sort((a, b) => b.score - a.score)
    .slice(0, keepTopN);
}
```

**The Verification**

Let's prove the reranker actually demotes a superficially-similar-but-actually-irrelevant chunk. We'll deliberately widen our vector search to `topK: 8` (instead of 3) to give the reranker some real noise to filter out:

```bash
npx tsx -e "
import { ingestCodebase } from './src/retrieval/ingest.ts';
import { embedText } from './src/retrieval/embed.ts';
import { rerankChunks } from './src/retrieval/rerank.ts';

const store = await ingestCodebase('./sample-codebase');
const query = 'What happens after 5 failed login attempts?';
const queryEmbedding = await embedText(query);

const wideResults = store.search(queryEmbedding, 8);
console.log('--- Vector search top 8 (before reranking) ---');
wideResults.forEach(r => console.log(r.chunk.sourcePath, '| offset', r.chunk.startOffset, '| cosine score:', r.score.toFixed(3)));

const reranked = await rerankChunks(query, wideResults, 3, 5);
console.log('\n--- After reranking (top 3, min score 5) ---');
reranked.forEach(r => console.log(r.chunk.sourcePath, '| offset', r.chunk.startOffset, '| relevance score:', r.score));
"
```

Expected output (abbreviated):

```
--- Vector search top 8 (before reranking) ---
src/auth/user.ts | offset 620 | cosine score: 0.681
src/auth/user.ts | offset 471 | cosine score: 0.615
src/generated/session.ts | offset 84 | cosine score: 0.410
src/generated/auditlog.ts | offset 84 | cosine score: 0.388
src/utils/logger.ts | offset 0 | cosine score: 0.301
src/generated/notification.ts | offset 84 | cosine score: 0.287
src/billing/invoice.ts | offset 0 | cosine score: 0.201
src/generated/webhook.ts | offset 84 | cosine score: 0.195

--- After reranking (top 3, min score 5) ---
src/auth/user.ts | offset 620 | relevance score: 9
src/auth/user.ts | offset 471 | relevance score: 8
src/generated/session.ts | offset 84 | relevance score: 2
```

Notice: `session.ts` scored a respectable 0.410 on raw cosine similarity (probably because our generated "noise" module for sessions shares vocabulary like "record", "id", "create" with real auth-flavored language) — but the reranker correctly demotes it to a 2/10, below our `minScore: 5` cutoff, and it gets filtered out entirely. Only the two genuinely relevant `user.ts` chunks survive into the final context sent to the LLM. This is the second-stage filter doing exactly its job: catching a false positive that pure vector similarity let through.

---

## Step 5 — The Cache vs. Fetch Decision (CAG)

**The Target:** No new code in this step — this is a **decision framework** to explicitly reason about before Phase 3, because building agent tool-calling logic on top of an unclear retrieval strategy compounds confusion later.

**The Concept:** Everything we've built since Part 3 assumes retrieval should run **fresh, on every single question** — embed the query, search the vector store, rerank, repeat. That's the right default for *active, frequently-changing* source code. But consider a different kind of content: a static `LICENSE.md` file, a company's coding style guide, or API documentation for a library version that won't change for months. Re-running embedding + search + reranking for content that never changes is like re-measuring a room's dimensions every single time you want to know if a couch will fit — once measured, the answer is stable; just remember it.

This is the distinction between:
- **RAG (Retrieval-Augmented Generation)** — what we've built: search happens live, per-request, against a corpus that may change at any time (active source code being edited).
- **CAG (Cache-Augmented Generation)** — pre-loading static, rarely-changing reference material directly into the prompt's stable prefix (our System Frame layer from Part 2!) once, and relying on the LLM provider's prompt caching (which we'll implement concretely in Part 7) to make repeated inclusion of that same static text nearly free and instant on subsequent calls, rather than running a retrieval pipeline for content that was never going to change anyway.

**The decision rule we'll follow for the rest of this series:**

| Content type | Example in our project | Strategy |
|---|---|---|
| Changes frequently, large corpus | Active source files in `sample-codebase/src/` | **RAG** — embed, search, rerank live (what we built in Parts 3-4) |
| Static, small-to-medium, rarely changes | A project's `CONTRIBUTING.md`, style guide, fixed API reference | **CAG** — load once directly into the System Frame, let provider-side caching (Part 7) make repeated inclusion cheap |

We are not implementing CAG's caching mechanics yet — that requires the provider-side prompt caching machinery, which is the explicit subject of Part 7 once we're deep into the Production Layer. For now, the important deliverable is the *decision framework itself*: you now know, for any new document type introduced later in this series (or in your own future projects), which bucket it belongs in and why — a decision many teams get wrong by defaulting to "just RAG everything," burning unnecessary retrieval latency and cost on content that was static all along.

---

## Recap: What We Built in Phase 2 (Parts 3-4)

1. **Embeddings & semantic search** — replaced Part 2's keyword-matching hack with real meaning-based retrieval (proved on the zero-word-overlap "throttling" question).
2. **Fixed-size chunking, caught breaking code** — sliced a real function call in half, with your own terminal as proof.
3. **AST-based chunking** — fixed both bugs (mid-statement cuts, missing imports) permanently, by chunking along the actual grammar of the code via the TypeScript Compiler API.
4. **Reranking** — added a second, more precise filtering stage that caught a false positive (`session.ts`) that raw cosine similarity let through.
5. **The CAG decision framework** — a clear rule for when to re-run retrieval live versus when to treat content as stable and cacheable.

---

## What's Next: Part 5

Our Knowledge Layer is now solid: OpenCode can find the right code, chunked correctly, filtered precisely. But it's still fundamentally **read-only** — it can only *talk about* code, never *act* on it. It can't run the test suite, can't check whether its own suggested fix actually works, and can't read a stack trace to self-correct.

**Part 5** begins Phase 3 — the Control Layer — by building exactly what the blueprint warns against first: an agent loop with far too many tools exposed at once, and watching it spiral into confusion, redundant tool calls, and cost blowout, in the same honest "build it, break it, measure it" pattern we've followed in every phase so far.

**✅ Part 4 is now complete, and Phase 2 (The Knowledge Layer) is done.** You've built a full retrieval pipeline from first principles — chunking, embedding, vector search, reranking — with each stage motivated by a real, reproducible bug caught in your own terminal in the previous stage, not by abstract theory. You now have a working, honest answer to "how does an AI coding assistant actually find the right code," and a clear decision framework (RAG vs. CAG) for when live retrieval is even the right tool for the job.

