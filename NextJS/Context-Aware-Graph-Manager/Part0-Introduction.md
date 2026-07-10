# Context-Aware Knowledge Graph Manager ("Cortex") — Part 0: Introduction & Architecture

## What we're building
"Cortex" — a web app where a user uploads documents (PDF/TXT/MD), the system reads them, uses an LLM to extract **entities** (nodes) and **relationships** (edges) between those entities, stores everything in Postgres, and renders an interactive, force-directed **knowledge graph** in the browser. Users can also do semantic search over the underlying document chunks (vector search) and click a node to see the graph "context" around it (its neighbors), not just a flat search result list — hence "Context-Aware."

Think of it as a mini, self-hosted version of tools like Obsidian's graph view or Neo4j Bloom, but built from scratch with an LLM doing the entity/relationship extraction instead of the user manually linking notes.

## Why this project is a good AI-engineering teaching vehicle
Most "chat with your docs" tutorials stop at RAG (chunk -> embed -> retrieve -> stuff into prompt). This project goes one step further and teaches **structured extraction**: forcing an LLM to emit a strict, typed shape (nodes + edges) that a downstream system (a graph renderer, a database) can consume reliably. That is one of the most valuable and most requested real-world AI engineering skills, and it forces you to learn:
- Why raw LLM text output is dangerous to trust and how Zod schemas + the AI SDK's structured-output helpers fix that.
- Why graphs need both a relational store (nodes/edges as rows, for querying/joins) AND a vector store (chunk embeddings, for semantic search) living side by side in the same Postgres database.
- Why streaming matters for perceived responsiveness even when the final output is a structured JSON object, not a chat message.
- How to visualize non-trivial data (a graph) in React without reinventing a physics engine.

## Tech stack (all free-tier friendly)
| Layer | Choice | Why |
|---|---|---|
| Framework | Next.js 16 (App Router, Turbopack) | Server Actions + Route Handlers in one project, Promise-based dynamic params (Next.js 16 requirement) |
| AI orchestration | Vercel AI SDK (`ai` package, latest) | Unified `generateObject`/`streamObject`/`embed` API across providers |
| LLM access | Free LLM registry (Groq free tier, OpenRouter free models, local Ollama) | Zero cost to complete the whole tutorial; swappable in one file |
| Database | PostgreSQL via **Neon** (free tier, serverless Postgres) | Free, scales to zero, supports the `pgvector` extension |
| Vector store | `pgvector` extension inside the same Neon Postgres | No second database to manage — nodes, edges, chunks, and embeddings all live together and can be joined in one SQL query |
| ORM | Prisma 6+ | Type-safe schema, migrations, works with pgvector via `Unsupported("vector(768)")` column type + raw SQL for similarity search |
| Styling/UI | Tailwind CSS v4 (CSS-first `@theme`) + shadcn/ui | Fast, accessible, minimal-boilerplate components |
| Graph rendering | `react-force-graph` (force-graph-2d under the hood, WebGL via three.js for the 3D variant) | Purpose-built force-directed graph renderer, no need to hand-roll physics |
| Deployment | Vercel free/Hobby tier | Native Next.js hosting, one-command deploy |

## High-level architecture

```
                    ┌─────────────────────────────────────────────┐
                    │                Browser (Next.js)             │
                    │  Upload UI   Search UI   Graph View (Canvas)  │
                    └───────────────┬───────────────┬──────────────┘
                                    │ Server Actions │ fetch()
                                    ▼               ▼
                    ┌─────────────────────────────────────────────┐
                    │              Next.js Server (App Router)      │
                    │                                                │
                    │  1. Ingestion Pipeline (Phase 3)               │
                    │     file -> text -> chunks -> embeddings       │
                    │                                                │
                    │  2. Extraction Agent (Phase 4)                 │
                    │     chunk text -> LLM (structured output)      │
                    │     -> { nodes[], edges[] } (Zod-validated)    │
                    │                                                │
                    │  3. Retrieval (Phase 6)                        │
                    │     query -> embedding -> pgvector similarity  │
                    │     search -> matching chunks + linked nodes   │
                    └───────────────┬────────────────────────────────┘
                                    ▼
                    ┌─────────────────────────────────────────────┐
                    │        Neon Postgres (+ pgvector extension)   │
                    │  documents | chunks(+embedding) | nodes | edges│
                    └─────────────────────────────────────────────┘
```

## The data model in one paragraph
A `Document` is what the user uploads. It's split into `Chunk`s (each with a 768-dim embedding for semantic search). Each chunk is fed to the extraction agent, which proposes `Node`s (entities: people, places, concepts, organizations — whatever the domain calls for) and `Edge`s (typed, directed relationships between two nodes, e.g. `(Alice) -[WORKS_AT]-> (Acme Corp)`). Nodes are de-duplicated by name+type so the graph doesn't end up with five separate "Alice" nodes. Every node and edge keeps a reference back to the source chunk(s) it was extracted from — that provenance link is what makes clicking a graph node "context-aware": you can always answer "why does the graph think this relationship exists?"

## Series structure (7 phases + appendix)
1. **Phase 1 - Environment Setup**: Next.js 16 project scaffold, Tailwind v4, shadcn/ui, folder structure, all env vars stubbed.
2. **Phase 2 - Database Schema**: Prisma schema for Document/Chunk/Node/Edge, enabling pgvector on Neon, migration workflow, raw-SQL vector similarity helper.
3. **Phase 3 - File Ingestion Pipeline**: upload UI, server action, text extraction (PDF/TXT/MD), chunking strategy, embedding generation.
4. **Phase 4 - AI-Agentic Extraction**: free LLM provider registry, Zod schema for nodes/edges, `generateObject` extraction agent, de-duplication + persistence.
5. **Phase 5 - Graph Visualization**: `react-force-graph` integration, data-fetching API route, node click -> context panel.
6. **Phase 6 - Search & Retrieval UI**: semantic search bar, vector similarity query, results linked back into the graph view.
7. **Phase 7 - Final Polish & Deployment**: loading/error/empty states, environment variable checklist, Vercel deployment.
8. **Appendix A - Full Codebase Reference**: complete file tree + all env vars in one place.

## Notes naming convention
Every note in this series is prefixed `"KG Manager - "`. Start with `"KG Manager - INDEX (Start Here)"` for the master list and reading order.

Next: Part 1 - Environment Setup.
