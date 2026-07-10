# Appendix A: Full Codebase Reference and Environment Variables

## 1. Simplified project file tree
```
cortex-kg-manager/
├── prisma/
│   ├── schema.prisma                      # Document/Chunk/Node/Edge + provenance join tables (Part 2)
│   └── migrations/
│       └── <timestamp>_init/migration.sql
│
├── src/
│   ├── app/
│   │   ├── layout.tsx                     # root layout + global nav (Part 7)
│   │   ├── page.tsx                       # upload + document list + search (Parts 3, 6, 7)
│   │   ├── globals.css                    # Tailwind v4 CSS-first theme (Part 1)
│   │   │
│   │   ├── graph/
│   │   │   ├── page.tsx                   # graph visualization page (Part 5)
│   │   │   └── error.tsx                  # route-level error boundary (Part 7)
│   │   │
│   │   └── api/
│   │       ├── graph/route.ts             # GET nodes+links for react-force-graph (Part 5)
│   │       ├── search/route.ts            # POST semantic search (Part 6)
│   │       └── documents/route.ts         # GET document processing status (Part 7)
│   │
│   ├── components/
│   │   ├── ui/                            # shadcn/ui generated components (Part 1)
│   │   ├── upload-form.tsx                # file upload form (Part 3)
│   │   ├── document-list.tsx              # polling status list (Part 7)
│   │   ├── graph-view.tsx                 # react-force-graph-2d wrapper (Part 5)
│   │   ├── node-context-panel.tsx         # click-to-inspect side panel (Part 5)
│   │   └── search-bar.tsx                 # semantic search UI (Part 6)
│   │
│   ├── lib/
│   │   ├── db.ts                          # Prisma client singleton + env check (Parts 2, 7)
│   │   ├── env-check.ts                   # required env var guard (Part 7)
│   │   ├── vector.ts                      # raw-SQL pgvector read/write helpers (Parts 3, 6)
│   │   ├── graph-colors.ts                # node type -> hex color map (Part 5)
│   │   │
│   │   ├── ingestion/
│   │   │   ├── extract-text.ts            # PDF/TXT/MD text extraction (Part 3)
│   │   │   └── chunk.ts                   # fixed-size overlapping chunker (Part 3)
│   │   │
│   │   └── ai/
│   │       ├── models.ts                  # FREE_MODELS registry (Part 4a)
│   │       ├── provider.ts                # getModelInstance() factory (Part 4a)
│   │       ├── embed.ts                   # Ollama embeddings client (Part 3)
│   │       ├── extraction-schema.ts       # Zod schema for nodes/edges (Part 4b)
│   │       ├── extract-graph-data.ts      # generateObject extraction agent (Part 4b)
│   │       └── persist-graph-data.ts      # de-dup + provenance persistence (Part 4b)
│   │
│   └── actions/
│       ├── ingest-document.ts             # server action: full ingestion pipeline (Parts 3, 4b)
│       └── extract-graph.ts               # server action: standalone extraction test (Part 4b)
│
├── .env.local                             # local secrets, gitignored (Part 1)
├── package.json
└── tsconfig.json
```

## 2. Full environment variable reference
Set these in `.env.local` for local dev, and mirror every one of them into Vercel (`vercel env add <NAME>`, or via the Vercel dashboard → Project → Settings → Environment Variables) before deploying, per Part 7.

```bash
# ── Database (Part 2) ────────────────────────────────────────────────
# Neon pooled connection string - used by the app at runtime.
DATABASE_URL="postgresql://user:password@ep-xxxx-pooler.region.aws.neon.tech/dbname?sslmode=require"

# Neon direct (non-pooled) connection string - used by Prisma migrations.
DIRECT_URL="postgresql://user:password@ep-xxxx.region.aws.neon.tech/dbname?sslmode=require"

# ── Free LLM providers (Part 4a) ─────────────────────────────────────
# Only fill in the key(s) for provider(s) you actually use.
GROQ_API_KEY=""
OPENROUTER_API_KEY=""

# Which model id (from src/lib/ai/models.ts FREE_MODELS) powers general use
# vs. the extraction agent specifically. Can be the same value.
DEFAULT_MODEL_ID="ollama-llama3.1"
EXTRACTION_MODEL_ID="ollama-llama3.1"

# ── Embeddings (Part 3) ───────────────────────────────────────────────
# Local Ollama URL for dev. MUST be changed to a publicly reachable
# Ollama-compatible endpoint (or swapped for a hosted free embeddings API)
# before deploying to Vercel - Vercel's servers cannot reach your localhost.
OLLAMA_BASE_URL="http://localhost:11434"
```

## 3. Free-tier signup quick reference
| Service | URL | What you need from it |
|---|---|---|
| Neon | neon.tech | `DATABASE_URL` + `DIRECT_URL` (Connection Details panel) |
| Groq | console.groq.com | `GROQ_API_KEY` (API Keys page) |
| OpenRouter | openrouter.ai | `OPENROUTER_API_KEY` (Keys page); check `openrouter.ai/models?max_price=0` for current free models |
| Ollama | ollama.com/download | No key - install locally, `ollama pull nomic-embed-text` and `ollama pull llama3.1` |
| Vercel | vercel.com | Hosting + env var management + `vercel` CLI login |

## 4. Model/dimension consistency reminder
If you ever swap the embedding model away from `nomic-embed-text`, you must update **both**:
1. `prisma/schema.prisma` — the `vector(768)` dimension on `Chunk.embedding`, matched to the new model's output size.
2. A new migration (`npx prisma migrate dev`) to alter the column, since pgvector enforces a fixed dimension per column and will reject mismatched vectors at write time.

## 5. What "done" looks like
A fully working local + deployed instance of Cortex should let you: upload a document → watch its status move `PENDING → CHUNKING → EXTRACTING → DONE` → see new colored nodes and directional labeled edges appear on `/graph` → click any node for a description + connections panel → type a natural-language query on the home page and get back ranked, semantically relevant chunks plus linked graph nodes → all of this reproducible on a fresh clone with nothing but the env vars above filled in.
