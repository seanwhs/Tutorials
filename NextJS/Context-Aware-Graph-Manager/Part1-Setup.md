# Part 1: Environment Setup

Next.js 16 requires Node.js 20.9+ or 22 LTS. Check first:
```bash
node -v
```

## 1. Scaffold the project
```bash
npx create-next-app@latest cortex-kg-manager
```
Prompts — answer exactly like this:
```
Would you like to use TypeScript?      Yes
Would you like to use ESLint?          Yes
Would you like to use Tailwind CSS?    Yes
Would you like to use `src/` directory? Yes
Would you like to use App Router?      Yes (default, no other option in Next.js 16)
Would you like to use Turbopack?       Yes (default in Next.js 16)
Would you like to customize import alias? No (keep @/*)
```
```bash
cd cortex-kg-manager
```

## 2. Why Tailwind v4 changes your mental model
Next.js 16 ships Tailwind CSS v4 by default, which is **CSS-first config** — there is no `tailwind.config.js` to edit. Your theme lives directly in `src/app/globals.css`:
```css
@import "tailwindcss";

@theme {
  --color-graph-node: #6366f1;
  --color-graph-edge: #94a3b8;
  --font-sans: "Inter", sans-serif;
}
```
This matters later because when we style graph nodes/edges we'll reference these custom theme tokens directly as Tailwind classes (`bg-graph-node`) or read them in JS via `getComputedStyle` when configuring `react-force-graph` (which needs raw color strings, not Tailwind classes, since it renders to `<canvas>`).

## 3. Install dependencies
```bash
npm install ai @ai-sdk/openai-compatible zod
npm install prisma @prisma/client --save-dev
npm install pdf-parse
npm install react-force-graph-2d
npm install clsx lucide-react
npm install @radix-ui/react-slot @radix-ui/react-dialog @radix-ui/react-label
```

Why each one:
- **`ai` + `@ai-sdk/openai-compatible`**: Vercel AI SDK core, plus the OpenAI-compatible adapter so we can point at Groq, OpenRouter, or a local Ollama server through one interface (Part 4).
- **`zod`**: defines the exact shape we force the LLM to return (nodes/edges). Without this, the LLM can return malformed JSON, hallucinated fields, or plain prose, and your graph-rendering code will crash on production data you can't control. Zod turns "hope the LLM behaves" into "guarantee the shape or throw a caught, handleable error."
- **`prisma` / `@prisma/client`**: type-safe ORM + migrations against Neon Postgres.
- **`pdf-parse`**: lightweight, dependency-free PDF text extraction for the ingestion pipeline.
- **`react-force-graph-2d`**: the graph renderer (Phase 5). We use the 2D canvas variant, not the 3D/WebGL variant, for beginner-friendliness and lower resource use — the 3D variant is a drop-in swap later if you want it.
- **`clsx`, `lucide-react`, Radix primitives**: shadcn/ui's usual dependencies.

## 4. Initialize shadcn/ui
```bash
npx shadcn@latest init
```
Prompts:
```
Which style would you like to use?     Default
Which color would you like to use?     Slate
Would you like to use CSS variables?   Yes
```
Add the components we'll use across the series now, so later parts just import them:
```bash
npx shadcn@latest add button input card dialog label badge tabs skeleton sonner
```

## 5. Folder structure
```
cortex-kg-manager/
├── prisma/
│   └── schema.prisma
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── graph/route.ts          # GET nodes+edges for visualization
│   │   │   ├── search/route.ts         # POST semantic search
│   │   │   └── ingest/route.ts         # POST file upload + pipeline trigger
│   │   ├── graph/page.tsx              # main graph view page
│   │   ├── layout.tsx
│   │   ├── page.tsx                    # upload/dashboard landing page
│   │   └── globals.css
│   ├── components/
│   │   ├── ui/                         # shadcn components (auto-generated)
│   │   ├── upload-form.tsx
│   │   ├── graph-view.tsx
│   │   ├── search-bar.tsx
│   │   └── node-context-panel.tsx
│   ├── lib/
│   │   ├── ai/
│   │   │   ├── models.ts               # free LLM registry
│   │   │   ├── provider.ts             # provider factory
│   │   │   └── extraction-schema.ts    # Zod schema for nodes/edges
│   │   ├── db.ts                       # Prisma client singleton
│   │   ├── ingestion/
│   │   │   ├── extract-text.ts
│   │   │   └── chunk.ts
│   │   └── vector.ts                   # raw-SQL pgvector helpers
│   └── actions/
│       ├── ingest-document.ts          # server action: full pipeline
│       └── extract-graph.ts            # server action: run extraction agent
├── .env.local
└── package.json
```

## 6. Stub environment variables now
Create `.env.local` in the project root:
```bash
# Database (Part 2 fills this in with your real Neon connection string)
DATABASE_URL="postgresql://user:password@host/dbname?sslmode=require"

# Free LLM providers (Part 4 - fill in the ones you actually use)
GROQ_API_KEY=
OPENROUTER_API_KEY=
DEFAULT_MODEL_ID="ollama-llama3.1"

# Embeddings (Part 3 - local Ollama by default, no key needed)
OLLAMA_BASE_URL="http://localhost:11434"
```
`.env.local` is already gitignored by `create-next-app` — verify with:
```bash
cat .gitignore | grep env
```
You should see `.env*.local` in the output.

## 7. Verification checkpoint
```bash
npm run dev
```
Visit `http://localhost:3000` — you should see the default Next.js 16 starter page with no console errors. Stop the server (Ctrl+C) once confirmed; we'll replace `src/app/page.tsx` in Phase 3.

Next: Part 2 - Database Schema (Prisma + pgvector on Neon).
