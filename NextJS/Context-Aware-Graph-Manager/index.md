# Cortex: Context-Aware Knowledge Graph Manager

## What we're building
"Cortex" — upload documents, an LLM extracts entities (nodes) and relationships (edges) from them into a shared knowledge graph, stored in Postgres alongside vector embeddings for semantic search. Users explore the graph visually (force-directed, clickable nodes with full context) and search their documents semantically, with search results linked back into the graph. Every extracted fact keeps a provenance link back to the exact source text chunk it came from.

## Stack (all free-tier friendly)
- Next.js 16 (App Router, Turbopack default) + TypeScript + Tailwind CSS v4 (CSS-first `@theme`, no tailwind.config.js) + shadcn/ui
- Vercel AI SDK (`ai` + `@ai-sdk/openai-compatible`) for both structured extraction (`generateObject`) and general model calls
- Free LLM registry in code: Groq free tier, OpenRouter free models, local Ollama — swappable via one config file, no vendor lock-in
- PostgreSQL via Neon (free tier, serverless) + `pgvector` extension — relational graph data and vector embeddings live in the same database
- Prisma 6+ ORM, with the vector column managed via `Unsupported("vector(768)")` + raw SQL
- Embeddings via `nomic-embed-text` (768 dims) run locally through Ollama in dev
- Graph rendering via `react-force-graph-2d` (canvas-based force-directed layout)
- Deployment: Vercel free/Hobby tier

## Critical patterns used throughout
- **Structured LLM output via Zod + `generateObject`**, never raw-text JSON parsing — the extraction agent's entire reliability rests on this (Part 4b).
- **One Postgres database for both relational rows and vectors** via `pgvector` — no second vector-DB service to manage (Part 2).
- **Provenance join tables** (`NodeSourceChunk`/`EdgeSourceChunk`) so every node/edge traces back to its source text — this is what makes the system "context-aware," not just "a graph" (Part 2, surfaced in Parts 5 and 6).
- **Node de-duplication via a `[name, type]` unique constraint + `upsert`** — repeated mentions of the same entity across documents converge onto one graph node (Part 4b).
- **Free LLM provider abstraction** — a single `getModelInstance(modelId)` factory swaps between Groq/OpenRouter/Ollama with zero changes to business logic (Part 4a).
- **Canvas-based graph rendering requires raw hex colors, not Tailwind classes**, and must be dynamically imported with `ssr: false` since it depends on browser-only globals (Part 5).

## All notes in this series (10 total)
1. "Part 0: Introduction & Architecture"
2. "Part 1: Environment Setup"
3. "Part 2: Database Schema (Prisma + pgvector on Neon)"
4. "Part 3: File Ingestion Pipeline"
5. "Part 4a: Free LLM Provider Abstraction"
6. "Part 4b: AI-Agentic Extraction (Nodes and Edges)"
7. "Part 5: Graph Visualization (react-force-graph)"
8. "Part 6: Search and Retrieval UI"
9. "Part 7: Final Polish and Deployment"
10. "Appendix A: Full Codebase Reference and Environment Variables"

## Recommended reading order
Read in numeric order above — each part builds directly on artifacts (files, schema, functions) created in the previous one. Part 4 is split into 4a (provider abstraction) and 4b (the actual extraction agent) because the abstraction is a reusable prerequisite the extraction agent depends on.

## Suggested next steps beyond this series (not included)
- Background job queue (e.g. Inngest, Vercel Cron, or a simple database-backed job table) so ingestion/extraction don't block the upload request for large documents.
- Multi-user auth + per-user graphs (this series builds a single shared graph, matching a personal-tool scope).
- Graph-aware re-ranking: using node/edge structure, not just raw chunk similarity, to improve search relevance.
- A "merge nodes" admin UI for manually fixing any de-duplication misses the LLM's naming inconsistency causes (e.g. "Bob Smith" vs "Robert Smith" not auto-merging since they differ by name+type key).
- Swapping `react-force-graph-2d` for the 3D/WebGL variant for larger graphs.
