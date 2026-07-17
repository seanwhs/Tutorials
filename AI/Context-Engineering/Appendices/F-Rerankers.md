# Appendix F — Rerankers, Cross-Encoders, and MCP, in Depth

Part 4 built a lightweight LLM-based reranker and briefly noted that dedicated reranker APIs exist. Part 6 adopted MCP's schema conventions without implementing a full MCP server. This appendix expands both.

## Bi-Encoders vs. Cross-Encoders

Our vector search (Part 3) and our reranker (Part 4) represent two fundamentally different architectures for judging text relevance, and understanding the distinction clarifies why both stages are worth having rather than picking just one.

**Bi-encoder (what embeddings are):** the query and each candidate document are encoded *independently*, each producing its own vector, and similarity is computed afterward via cosine similarity. This is what `text-embedding-3-small` does — it has no idea, while encoding a chunk of code, what query it will eventually be compared against. The huge advantage: because each document's vector can be pre-computed once (at ingestion time, per Part 3's `ingestCodebase`), comparing against a new query at search time is just cheap arithmetic — no new model inference needed per document. This is what makes vector search fast enough to run over thousands of chunks in milliseconds.

**Cross-encoder (what a real reranker is):** the query and *one specific candidate* are fed into the model **together, jointly**, and the model directly outputs a relevance score for that specific pairing. This is dramatically more accurate because the model can reason about the actual interaction between the query and that specific text — but it's also far more expensive, because it requires a full model inference *per candidate*, and can't be precomputed ahead of time since it depends on the query, which isn't known until search time.

Our Part 4 reranker approximated a cross-encoder's behavior using a general-purpose chat model (`gpt-4o-mini`) prompted to output a relevance score — functionally similar in spirit, but not architecturally identical to a purpose-built cross-encoder model.

## Dedicated Reranker APIs

For production systems processing meaningful query volume, purpose-built reranker models are usually preferable to our LLM-prompting approach, for two reasons: they're trained specifically for the relevance-scoring task (rather than repurposing a general chat model), and they're typically far cheaper and faster per candidate since they're smaller, specialized models rather than a full general-purpose LLM call.

**Cohere Rerank** — a hosted API (`co.rerank(query, documents, top_n)`) purpose-built for this exact task, supporting both text and (in newer versions) code-aware reranking. Drop-in replacement conceptually for our `rerankChunks` function — same input (query + candidates), same output (scored, sorted, filtered list).

**BGE rerankers (BAAI General Embedding)** — an open-source family of cross-encoder models (e.g., `bge-reranker-v2-m3`) you can self-host via a library like `sentence-transformers` (Python) or run through a hosted inference endpoint (e.g., Hugging Face Inference Endpoints). Appropriate when you want to avoid per-call API costs entirely at high volume, at the cost of managing your own inference infrastructure.

The migration path from our Part 4 implementation to either option is narrow and contained: only `judgeRelevance`'s internals change (swap the OpenAI chat call for a Cohere/BGE API call); `rerankChunks`'s signature and the rest of the pipeline remain untouched — another payoff of having isolated reranking behind a clean function boundary from the start.

## Model Context Protocol (MCP), Expanded

Part 6 confirmed our tool schemas were structurally MCP-compatible without building an actual MCP server. Here's what that next step would concretely involve.

**The core idea:** MCP defines two roles — an **MCP server**, which exposes a set of tools (and optionally, resources and prompts) over a standardized JSON-RPC-based protocol, and an **MCP client**, which is the application (an IDE, an agent framework, our OpenCode CLI) that connects to one or more servers and calls their tools. The point is decoupling: a tool provider (say, a company's internal ticketing system) implements one MCP server once, and *any* MCP-compliant client — Claude Desktop, an internal agent tool, a teammate's custom CLI — can use it without custom integration code per client.

**What our `tools.ts` would need to become an actual MCP server:**

```typescript
// Conceptual sketch — not a full implementation, since building a
// production MCP server is a substantial follow-on project of its own.
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { allToolSchemas, toolImplementations } from "./tools.js";

const server = new Server({ name: "opencode-tools", version: "0.1.0" }, { capabilities: { tools: {} } });

// Register our existing tool schemas and implementations almost
// directly — this is the payoff of having designed them in MCP-shape
// from the start in Part 6.
server.setRequestHandler("tools/list", async () => ({ tools: allToolSchemas }));
server.setRequestHandler("tools/call", async (request) => {
  const { name, arguments: args } = request.params;
  const result = await toolImplementations[name](args);
  return { content: [{ type: "text", text: result }] };
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

**Why this matters beyond this series:** once tools live behind an MCP server instead of being hardcoded inside one agent's process, the same `run_tests` or `search_code` tool becomes reusable infrastructure — usable from Claude Desktop directly, from a separate internal dashboard, or from a completely different agent framework a teammate builds later — without re-implementing or re-debugging the underlying logic more than once. This is the direct realization of the "USB-C for AI tools" analogy from Part 6.
