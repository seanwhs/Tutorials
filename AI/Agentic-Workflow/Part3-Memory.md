# Part 3: Memory & Context

## 1. Two Different Problems Called "Memory"

Staff Engineer distinction that most tutorials blur: "memory" for an agent is actually two unrelated systems with different storage, different latency budgets, and different failure modes.

- **Short-term (session) memory** — the conversation transcript for the current task. Lives in `state.messages` from Part 1. Bounded lifetime, needs to be fast, and correctness matters more than recall breadth — you need the exact last N turns, not a fuzzy approximation.
- **Long-term (semantic) memory** — facts, past conversations, and documents that outlive any single session. This is what RAG solves. It needs to survive process restarts, scale past what fits in a context window, and trades exactness for relevance.

Conflating the two is a common design mistake: teams try to stuff long-term memory into the message array (blowing the context window and cost) or try to vector-search short-term context (adding latency to something that should be a simple array slice).

## 2. Short-Term Memory: Session State with Trimming

Part 1's `AgentState.messages` reducer (`concat`) grows unbounded. Add a trimming strategy at the boundary where messages enter the model call — not by mutating stored history (you still want the full transcript for observability/audit in Part 7).

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

Update `reason.ts` (Part 1) to call `windowForModel(state.messages)` instead of passing `state.messages` directly into `model.invoke(...)`. One-line change, important consequence: the agent's *audit trail* (what Langfuse sees in Part 7) and the agent's *working context* (what the model sees) are now deliberately different — and that's correct.

## 3. Long-Term Memory: pgvector Setup

Why pgvector over a dedicated vector DB (Pinecone/Weaviate/etc.): it's free, self-hostable, and lives in the same database as your relational data (orders, users, sessions). One tool can join semantic search against relational facts in one query, and you have one fewer service to operate/back up/secure. Trade-off: pgvector's ANN performance falls behind purpose-built vector DBs at very large scale (tens of millions+ vectors) — far beyond most agentic-workflow use cases.

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

```
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

Note on `VECTOR(1536)`: matches OpenAI's `text-embedding-3-small`. If you swap to a local embedding model (e.g., `nomic-embed-text` via Ollama, 768 dims), the column dimension must match — a common integration bug when swapping providers.

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

`<=>` is pgvector's cosine-distance operator; `1 - distance` converts it to a similarity score. Always order by distance ascending (closest first).

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

No changes to the graph, tool registry import, or Reason node were needed — the payoff of Part 2's tool-contract decoupling.

## 6. When Should the Agent Write to Long-Term Memory?

A deterministic post-processing check, not an inline reasoning decision:

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

Intentionally simple (regex, not an LLM call): an LLM-based classifier is more flexible but adds a full extra model call on every turn. Start with cheap heuristics; escalate only with evidence (see Appendix B).

## 7. Grounding: Injecting Recalled Memory Before Reasoning

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

Wire in before "reason": `.addEdge("__start__", "ground").addEdge("ground", "reason")`. The `similarity > 0.75` threshold guards against grounding with irrelevant memories — tune empirically per embedding model.

## 8. Exercise Challenge

`groundNode` always queries long-term memory, even for a simple "hello" — wasted latency and an unnecessary DB round trip. Add a cheap pre-check to skip grounding for turns unlikely to need historical context.

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

Why this is the right layer to optimize: skipping an unnecessary vector query is a pure latency/cost win with zero behavior change for the cases that matter — tightening the deterministic scaffolding around the agent rather than touching the probabilistic reasoning itself.

## Next
Part 4 uses this same state/memory foundation to build a Plan-and-Execute agent — moving beyond single-step ReAct to multi-step task decomposition for longer-running goals.
