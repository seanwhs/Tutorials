# Part 3: Memory & Context

> Recap: Part 1 built the loop and the state schema; Part 2 filled `toolDefinitions` with real, contract-first tools, including a `search_knowledge_base` stub that returned an empty array. This Part gives that stub a real backend, and — more importantly — draws a line that most agent tutorials blur right past: "memory" is not one system, it's two, and treating them as one is where a lot of production agents quietly go wrong.

## 1. Two Different Problems Called "Memory"

Staff Engineer distinction that most tutorials blur: "memory" for an agent is actually two unrelated systems, with different storage engines, different latency budgets, and different failure modes. Naming them separately up front is the whole point of this section — everything else in the Part is just implementation detail hanging off this distinction.

- **Short-term (session) memory** — the conversation transcript for the current task. It lives in `state.messages` from Part 1, already. It has a bounded lifetime (the current session), it needs to be fast (it's on the hot path of every single Reason call), and correctness matters more than recall breadth: you need the *exact* last N turns, verbatim, not a fuzzy approximation of "roughly what was discussed." There is no ranking problem here — order is already given, by time.
- **Long-term (semantic) memory** — facts, past conversations, and documents that outlive any single session. This is what RAG (retrieval-augmented generation) solves. It needs to survive process restarts, scale past what fits in a context window, and — unlike short-term memory — it explicitly trades exactness for relevance: you're asking "what's *related* to this," not "what happened right before this."

Conflating the two is a common and costly design mistake, and it tends to show up in one of two shapes. Teams either try to stuff long-term memory into the message array directly — which blows the context window and the per-call token cost, since now every single turn re-sends everything the system has ever learned about the user — or they try to vector-search short-term context, adding embedding-and-query latency to something that should be a simple, instant array slice. The fix for both is the same: keep the storage and access pattern for each system separate, and only bring them together deliberately, at a specific point in the loop (section 7).

## 2. Short-Term Memory: Session State with Trimming

Part 1's `AgentState.messages` reducer is `concat` — by design, it grows without bound, because that array is also your audit log (Part 1, section 4). But "the array we log from" and "the array we send to the model" don't have to be the same array at the point of the model call. Add a trimming strategy at exactly that boundary — where messages enter the model call — rather than by mutating the stored history. You still want the full, untrimmed transcript sitting in `state.messages` for observability and audit in Part 7; trimming is a read-time concern, not a write-time one.

**src/agent/memory/shortTerm.ts:**

```typescript
import type { BaseMessage } from "@langchain/core/messages";

const MAX_CONTEXT_MESSAGES = 12;

// Keeps the most recent N messages for the MODEL CALL only.
// The full transcript remains untouched in state.messages for logging.
export function windowForModel(messages: BaseMessage[]): BaseMessage[] {
  if (messages.length <= MAX_CONTEXT_MESSAGES) return messages;
  const systemMessages = messages.filter((m) => m.getType() === "system");
  const recent = messages.slice(-MAX_CONTEXT_MESSAGES);
  return [...systemMessages, ...recent];
}
```

Two details worth calling out. First, system messages are pulled out and re-prepended unconditionally, regardless of where they originally sat in the array — that's deliberate, because a system message (task instructions, persona, constraints) is exactly the kind of thing you don't want silently sliced away just because the conversation ran long. A dropped system message is a subtle, hard-to-debug behavior regression: the agent doesn't error, it just quietly stops following an instruction it used to follow, twelve turns in. Second, this is a pure function — `messages in, messages out`, no side effects, no state mutation — which is what makes it trivially unit-testable with a hand-built array of fake messages and no graph or model involved at all.

Update `reason.ts` (Part 1) to call `windowForModel(state.messages)` instead of passing `state.messages` directly into `model.invoke(...)`. It's a one-line change with an important consequence worth stating plainly: the agent's *audit trail* (what Langfuse sees in Part 7) and the agent's *working context* (what the model actually sees on this turn) are now deliberately, permanently different views over the same underlying data. That's not a compromise — that's correct. An audit log that shows less than what actually happened is a liability; a model context window that includes more than it needs is a cost and a distraction. Splitting the two views is how you get both properties at once.

## 3. Long-Term Memory: pgvector Setup

Why pgvector over a dedicated vector database (Pinecone, Weaviate, and similar): it's free, self-hostable, and — critically — it lives in the *same* database as your relational data (orders, users, sessions, everything Part 2's `lookup_order` tool queries). That co-location means one tool can, in principle, join a semantic search against relational facts in a single query, and you have one fewer service to operate, back up, secure, and pay for. For most agentic-workflow use cases, that operational simplicity outweighs raw ANN (approximate nearest neighbor) throughput.

The honest trade-off, stated rather than glossed over: pgvector's ANN performance falls behind purpose-built vector databases at very large scale — tens of millions of vectors and up. If your long-term memory table is going to hold hundreds of millions of chunks across thousands of tenants, this Part's setup is a starting point you'll eventually outgrow, not a permanent architecture. For the scale most agent projects actually operate at, it's the right default, and it's the one we're building here.

**docker-compose.yml:**

```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_USER: agent
      POSTGRES_PASSWORD: agent
      POSTGRES_DB: agent_memory
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

```bash
docker compose up -d postgres
```

**SQL migration:**

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE memory_chunks (
  id BIGSERIAL PRIMARY KEY,
  session_id TEXT NOT NULL,
  content TEXT NOT NULL,
  embedding VECTOR(1536) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX ON memory_chunks USING hnsw (embedding vector_cosine_ops);
```

A note on the index choice: `hnsw` (Hierarchical Navigable Small World) trades a small amount of recall accuracy for substantially faster approximate nearest-neighbor queries compared to a brute-force scan, and it's the right default for this table's access pattern — frequent reads, infrequent bulk writes. `vector_cosine_ops` matches the distance operator (`<=>`) used in section 4's query below; if you change the distance metric later (say, to Euclidean/L2 for a different embedding model's geometry), the index operator class needs to change with it, or your queries will silently ignore the index and fall back to a full scan.

Note on `VECTOR(1536)`: this dimension matches OpenAI's `text-embedding-3-small`. If you swap to a local embedding model — `nomic-embed-text` via Ollama, for instance, at 768 dimensions — the column dimension must match the new model's output exactly, or every insert will fail at the database layer. This is a common integration bug when swapping providers, precisely because it fails loudly and confusingly at write time rather than at the point where the provider was actually swapped (section 5's `model.ts`-style client), so keep the embedding model and the column dimension changing together as a single, deliberate migration, never independently.

## 4. Writing to Long-Term Memory

**src/agent/memory/longTerm.ts:**

```typescript
import { OpenAIEmbeddings } from "@langchain/openai";
import { db } from "../../infra/db.js";

const embeddings = new OpenAIEmbeddings({ model: "text-embedding-3-small" });

export async function storeMemory(sessionId: string, content: string) {
  const [vector] = await embeddings.embedDocuments([content]);
  await db.query(
    "INSERT INTO memory_chunks (session_id, content, embedding) VALUES ($1, $2, $3)",
    [sessionId, content, JSON.stringify(vector)]
  );
}

export async function recallMemory(query: string, topK = 4) {
  const [vector] = await embeddings.embedDocuments([query]);
  const result = await db.query(
    `SELECT content, 1 - (embedding <=> $1) AS similarity
     FROM memory_chunks
     ORDER BY embedding <=> $1
     LIMIT $2`,
    [JSON.stringify(vector), topK]
  );
  return result.rows as { content: string; similarity: number }[];
}
```

`<=>` is pgvector's cosine-distance operator — it returns *distance*, where 0 means identical direction and larger values mean less similar. `1 - (embedding <=> $1)` converts that distance into a similarity score running the other way (closer to 1 is more similar, closer to 0 or negative is less), which is the more intuitive number to reason about and threshold against, as section 7 does. Always order by distance ascending (closest first) — ordering by the derived similarity descending would be equivalent in theory but the distance-ascending form is what lets Postgres actually use the `hnsw` index from section 3 efficiently, since the index is built against the distance operator directly.

Note that `storeMemory` and `recallMemory` both call `embeddings.embedDocuments` — the same embedding model, on both the write path and the read path. That symmetry isn't incidental: cosine similarity is only meaningful when both vectors being compared were produced by the same model with the same normalization. Embed your stored content with one model and your queries with another, and the similarity scores become meaningless noise, not just "slightly worse" — this is a correctness requirement, not a quality tuning knob.

## 5. Wiring recallMemory into the Search Tool

**src/tools/search.ts (replaces the Part 2 placeholder body):**

```typescript
import { z } from "zod";
import { tool } from "@langchain/core/tools";
import { ok, fail } from "./types.js";
import { recallMemory } from "../agent/memory/longTerm.js";

const SearchInput = z.object({
  query: z.string().min(3),
  topK: z.number().int().min(1).max(10).default(4),
});

export const searchTool = tool(
  async (input) => {
    const parsed = SearchInput.parse(input);
    try {
      const results = await recallMemory(parsed.query, parsed.topK);
      return ok({ query: parsed.query, results });
    } catch (err) {
      return fail(`Memory recall failed: ${(err as Error).message}`, true);
    }
  },
  {
    name: "search_knowledge_base",
    description:
      "Semantic search over long-term memory (past conversations, stored facts, documents). Use when the current conversation lacks information the user references from before.",
    schema: SearchInput,
  }
);
```

Look closely at what changed from Part 2's version and what didn't: the schema is byte-for-byte identical, the tool name is identical, the description is nearly identical, and the `ok()`/`fail()` contract from Part 2's `types.ts` is unchanged. Only the body's implementation swapped from a hardcoded empty array to a real `recallMemory` call. No changes to the graph, no changes to the tool registry import in `src/tools/index.ts`, no changes to the Reason node — this is the payoff, made concrete, of Part 2's tool-contract decoupling. If you'd wired the Reason node or the graph directly to the *shape* of the search results rather than through this stable tool interface, this swap would have rippled outward; instead it stayed contained to one file.

## 6. When Should the Agent Write to Long-Term Memory?

Writing to memory is a decision, and it deserves the same deterministic-vs-probabilistic scrutiny as everything else in this series. It's tempting to let the model itself decide, inline, whether something is worth remembering — but that's an extra reasoning burden on every single turn, for a decision that, for a large fraction of turns, is obviously "no." Handle the common case cheaply and deterministically; escalate only when the cheap approach demonstrably falls short.

**src/agent/memory/writeDecision.ts:**

```typescript
const MEMORY_WORTHY_PATTERNS = [
  /my name is/i,
  /i prefer/i,
  /remember that/i,
  /always (use|do|avoid)/i,
];

export function isMemoryWorthy(userMessage: string): boolean {
  return MEMORY_WORTHY_PATTERNS.some((p) => p.test(userMessage));
}
```

Intentionally simple — a handful of regexes, not an LLM call. An LLM-based classifier ("is this message worth remembering long-term? yes/no") is more flexible and will catch phrasing these patterns miss, but it adds a full extra model call on *every single turn* of *every single conversation*, purely to make a binary decision that a cheap heuristic gets right most of the time. The right posture here is: start with cheap heuristics, measure how often they're wrong (false negatives you catch by spot-checking sessions, false positives you catch by noticing junk in `memory_chunks`), and escalate to a model-based classifier only once you have evidence the regex approach's error rate is actually costing you something (see Appendix B for how to set up that measurement). Reaching for the more powerful, more expensive tool by default — before you know you need it — is the same mistake section 1 of Part 2 warned against, just applied to your own pipeline instead of the model.

## 7. Grounding: Injecting Recalled Memory Before Reasoning

This is where the two memory systems from section 1 actually meet: long-term memory gets pulled in and folded into the short-term context, once, deliberately, at a specific point in the graph — not on every tool call, and not by the model deciding to call `search_knowledge_base` itself every time.

**src/agent/nodes/ground.ts:**

```typescript
import { recallMemory } from "../memory/longTerm.js";
import type { AgentStateType } from "../state.js";
import { SystemMessage } from "@langchain/core/messages";

export async function groundNode(state: AgentStateType) {
  const lastUserMessage = [...state.messages]
    .reverse()
    .find((m) => m.getType() === "human");
  if (!lastUserMessage) return {};

  const memories = await recallMemory(lastUserMessage.content as string, 3);
  if (memories.length === 0) return {};

  const relevant = memories.filter((m) => m.similarity > 0.75);
  if (relevant.length === 0) return {};

  const context = relevant.map((m) => `- ${m.content}`).join("\n");
  return {
    messages: [
      new SystemMessage(
        `Relevant context from long-term memory:\n${context}`
      ),
    ],
  };
}
```

Wire it in before Reason: `.addEdge("__start__", "ground").addEdge("ground", "reason")`. This replaces Part 1's `.addEdge("__start__", "reason")` — grounding now runs first, unconditionally, on every invocation, and Reason always sees whatever `ground` decided (including nothing at all, when the early returns above fire).

Walk through the three early-exit conditions, because each guards against a distinct failure mode: no human message found (defensive — shouldn't happen in normal operation, but a graph node should never assume its inputs are well-formed), zero memories returned (the vector table might simply be empty for a new user), and — the interesting one — memories *found* but none above the `similarity > 0.75` threshold. That last check exists because `recallMemory` with `topK = 3` will return its three nearest neighbors *no matter how far away they actually are* — nearest-neighbor search doesn't have a built-in notion of "not similar enough," it just ranks whatever's in the table. Without the threshold filter, a brand-new topic with no genuinely related history would still get "grounded" with the three least-irrelevant things in the database, actively misleading the model rather than helping it. The `0.75` threshold guards against exactly that — tune it empirically per embedding model, since cosine-similarity distributions aren't perfectly comparable across different embedding models or even different versions of the same model family.

## 8. Exercise Challenge

`groundNode` always queries long-term memory, even for a simple "hello" — a wasted latency hit and an unnecessary database round trip on a turn that structurally cannot benefit from historical context. Add a cheap pre-check to skip grounding for turns unlikely to need it.

Think about where this fits relative to section 6's `isMemoryWorthy` before writing the fix: that function gates *writes* to memory; this exercise is about gating *reads*. They're mirror-image problems — cheap-heuristic-first, escalate-only-with-evidence applies to both — but they run at different points in the loop and guard different costs (an unnecessary embedding-plus-write vs. an unnecessary embedding-plus-query).

## 9. Solution

```typescript
const SKIP_GROUNDING_PATTERNS = [/^(hi|hello|hey|thanks|ok|okay)\.?$/i];

export async function groundNode(state: AgentStateType) {
  const lastUserMessage = [...state.messages]
    .reverse()
    .find((m) => m.getType() === "human");
  if (!lastUserMessage) return {};

  const text = (lastUserMessage.content as string).trim();
  if (SKIP_GROUNDING_PATTERNS.some((p) => p.test(text))) {
    return {}; // short-circuit — no DB round trip for trivial turns
  }

  // ...rest unchanged
}
```

Why this is the right layer to optimize: skipping an unnecessary vector query is a pure latency and cost win with zero behavior change for the cases that actually matter — every turn that *isn't* a bare greeting or acknowledgment still gets grounded exactly as before. This is, again, tightening the deterministic scaffolding around the agent rather than touching the probabilistic reasoning itself — the same move Part 1 made with the hard step ceiling and Part 2 made with schema-enforced confirmation. Notice the pattern across all three Parts so far: the model's job gets narrower and more reliable precisely because more and more of the surrounding decision-making has been pulled out into plain, testable, deterministic code.

One caution on the regex itself: it's intentionally conservative — a handful of exact greeting/acknowledgment phrases, anchored with `^`/`$` so it won't accidentally match "hey, can you also check my order status" (a message that happens to start with a greeting but clearly needs grounding). Resist the temptation to loosen the pattern for broader coverage; a false-positive skip (grounding a turn that needed it) is a worse outcome than an occasional false-negative (grounding a turn that didn't strictly need it, at the cost of one extra DB round trip).

## Memory Layer Checklist

- **Two systems, two code paths.** Short-term is an array slice; long-term is a vector query. Don't make one do the other's job.
- **Trim at read time, not write time.** `state.messages` stays complete for audit; `windowForModel` is what the model actually sees.
- **Keep system messages exempt from trimming.** A silently dropped instruction is a worse bug than a slightly longer context window.
- **Embed writes and reads with the same model.** Cosine similarity across mismatched embedding spaces is meaningless, not just noisy.
- **Threshold your recall.** Nearest-neighbor search always returns *something* — filter on similarity, don't trust rank alone.
- **Gate both reads and writes with cheap heuristics first.** Escalate to an LLM-based classifier only with measured evidence, on either side.

## Next

Part 4 uses this same state/memory foundation to build a Plan-and-Execute agent — moving beyond single-step ReAct to multi-step task decomposition for longer-running goals.
