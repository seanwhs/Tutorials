**Building a Permission-Aware AI Research Assistant**  
*A performant, secure, and framework-agnostic approach using React, Supabase (PostgreSQL + pgvector), and RAG.*

Modern AI applications need more than a simple LLM wrapper. The core challenge is **secure data isolation**: users must only receive responses grounded in documents they have permission to access. This tutorial shows a robust architecture that enforces permissions at the database level using PostgreSQL's Row Level Security (RLS), making the system resilient even if the frontend is compromised.

### 1. Core Architecture: "Thin Client, Smart Backend"

Decouple the UI from heavy logic and offload security, orchestration, and LLM calls to the backend/database layer for maintainability, security, and scalability.

- **Frontend**: React (Vite) + Tailwind CSS + TanStack Query (for data fetching/caching) + shadcn/ui or similar for polished components.
- **Backend/Database**: Supabase (PostgreSQL + pgvector extension + built-in Auth + Storage).
- **Security**: RLS policies on tables — the database becomes the single source of truth for authorization.
- **Orchestration**: Vercel Serverless Functions (or Supabase Edge Functions) as a secure gateway to LLMs (e.g., via OpenRouter or direct providers). Avoid exposing API keys or bypassing RLS in the client.
- **Optional Enhancements**: Hybrid search (vector + full-text), metadata filtering, conversation history, and streaming responses.

This setup keeps costs low (free tiers for most components) while scaling well.

### 2. Database Design & Security

Separate metadata (`documents`) from content/chunks (`document_sections`) for performance. Use foreign keys + cascade deletes.

#### Schema Setup (SQL)

Run this in the Supabase SQL Editor:

```sql
-- Enable extensions
create extension if not exists vector;
create extension if not exists "uuid-ossp"; -- if needed

-- Documents table (metadata)
create table documents (
  id bigint primary key generated always as identity,
  name text not null,
  owner_id uuid not null references auth.users(id) default auth.uid(),
  access_level text check (access_level in ('private', 'public', 'shared')) default 'private',
  file_path text, -- e.g., Supabase Storage path
  created_at timestamptz not null default now(),
  metadata jsonb default '{}'
);

-- Document sections/chunks with embeddings
create table document_sections (
  id bigint primary key generated always as identity,
  document_id bigint not null references documents(id) on delete cascade,
  content text not null,
  embedding vector(1536) not null, -- Match your embedding model (e.g., text-embedding-3-large)
  chunk_index int default 0,
  metadata jsonb default '{}'
);

-- Enable RLS
alter table documents enable row level security;
alter table document_sections enable row level security;

-- Grant necessary privileges (for authenticated users)
grant select, insert on documents to authenticated;
grant select, insert on document_sections to authenticated;
```

#### RLS Policies (Source of Truth)

```sql
-- Documents policies
create policy "Users can view own or public documents" on documents
  for select using (
    access_level = 'public' or owner_id = auth.uid()
  );

create policy "Users can insert own documents" on documents
  for insert with check (owner_id = auth.uid());

create policy "Users can update/delete own documents" on documents
  for all using (owner_id = auth.uid());

-- Sections policies (via join to documents)
create policy "Users can read permitted sections" on document_sections
  for select using (
    exists (
      select 1 from documents 
      where documents.id = document_sections.document_id
      and (documents.access_level = 'public' or documents.owner_id = auth.uid())
    )
  );

create policy "Users can insert sections for own documents" on document_sections
  for insert with check (
    exists (
      select 1 from documents 
      where documents.id = document_sections.document_id
      and documents.owner_id = auth.uid()
    )
  );
```

**Best Practices**:
- Index the `owner_id` and foreign keys for RLS performance.
- For complex policies, consider security definer functions.
- Test policies thoroughly with different user sessions (use Supabase's Row Level Security tester or multiple browser profiles).
- Add indexes on embeddings: `create index on document_sections using hnsw (embedding vector_cosine_ops);` (after data insertion for best results).

### 3. Vector Search Function (`match_documents`)

Create this RPC function for efficient, RLS-aware similarity search:

```sql
create or replace function match_documents(
  query_embedding vector(1536),
  match_threshold float default 0.5,
  match_count int default 10
)
returns table (
  id bigint,
  document_id bigint,
  content text,
  similarity float
)
language sql stable
as $$
  select 
    document_sections.id,
    document_sections.document_id,
    document_sections.content,
    1 - (document_sections.embedding <=> query_embedding) as similarity
  from document_sections
  where 1 - (document_sections.embedding <=> query_embedding) > match_threshold
  order by document_sections.embedding <=> query_embedding
  limit match_count;
$$;
```

This automatically respects RLS. You can extend it with filters (e.g., JSONB metadata) later.

### 4. Document Upload & Ingestion Pipeline

**Frontend (React example)**: Use Supabase Storage for files + client-side or server-side chunking/embedding.

Key steps:
1. User uploads file → Supabase Storage (with RLS or signed URLs).
2. Extract text (e.g., via pdf.js, mammoth.js, or server-side with pdf-lib/unstructured).
3. Chunk text (e.g., recursive character splitter, ~500-1000 tokens per chunk).
4. Generate embeddings (server-side recommended to avoid exposing keys).
5. Insert document metadata + sections.

**Serverless Ingestion Function** (Vercel or Supabase Edge): Handle sensitive embedding generation here.

### 5. Secure AI Gateway (Vercel Function or Supabase Edge)

Never expose LLM keys or bypass RLS client-side.

```js
// api/agent.js (Vercel) or equivalent Edge Function
import { createClient } from '@supabase/supabase-js';

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).end();

  const { query, conversationHistory = [] } = req.body;
  const authHeader = req.headers.authorization;

  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY, // For admin ops if needed, but use user JWT for RLS
    { global: { headers: { Authorization: authHeader } } } // Pass user JWT for RLS
  );

  // Get query embedding (call embedding API securely)
  const embeddingRes = await fetch('https://api.openrouter.ai/...', { /* ... */ });
  const queryEmbedding = (await embeddingRes.json()).data[0].embedding;

  // RLS-enforced vector search
  const { data: results, error } = await supabase
    .rpc('match_documents', {
      query_embedding: queryEmbedding,
      match_threshold: 0.45,
      match_count: 8
    });

  if (error) return res.status(500).json({ error: error.message });

  // Enhanced prompt with context + history
  const context = results.map(r => r.content).join('\n\n');
  const messages = [
    { role: 'system', content: 'You are a helpful research assistant. Answer based ONLY on the provided context. Cite sources.' },
    ...conversationHistory,
    { role: 'user', content: `Context:\n${context}\n\nQuestion: ${query}` }
  ];

  const llmRes = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ model: 'meta-llama/llama-3.1-70b-instruct', messages, stream: true /* for streaming */ })
  });

  // Handle streaming or full response
  const json = await llmRes.json();
  return res.status(200).json({ 
    answer: json.choices[0].message.content,
    sources: results.map(r => ({ id: r.document_id, snippet: r.content.substring(0, 150) + '...' }))
  });
}
```

**Frontend Integration (TanStack Query example)**:

```tsx
const { mutate: askQuestion, isPending } = useMutation({
  mutationFn: async (query) => {
    const { data } = await axios.post('/api/agent', { query }, {
      headers: { Authorization: `Bearer ${session.access_token}` }
    });
    return data;
  }
});
```

Add loading spinners, error handling, source citations in UI, and conversation persistence.

### 6. Production & Deployment Checklist

**Deployment**:
- **Frontend**: Vercel/Netlify (connect Git repo).
- **Supabase**: Production project with custom domain + SSL.
- **Env Vars**: Never commit secrets. Use Vercel Dashboard + Supabase secrets.
- **Redirects**: For SPAs, handle client-side routing (`/*` → `/index.html`).

**Security Checklist**:
- Add allowed redirect URLs in Supabase Auth.
- Use Service Role Key **only** server-side (bypasses RLS — be careful).
- Enable Rate Limiting (Supabase or Vercel).
- Validate & sanitize inputs.
- Audit logs: Use Supabase logs or add custom audit tables.
- HTTPS everywhere; CORS properly configured.

**Costs** (approximate, scales with usage):
- Frontend/Hosting: Free on Vercel/Netlify.
- Supabase: Free tier (500MB DB, generous compute) → scales affordably.
- Embeddings/LLM: OpenRouter or provider free tiers; monitor token usage.
- Storage: Supabase Storage for originals.

**Performance Tips**:
- Use HNSW indexes for vectors.
- Chunk intelligently (overlap for context).
- Cache frequent queries (TanStack Query + Redis if needed).
- Hybrid search for better recall (vector + `to_tsquery`).
- Monitor with Supabase Analytics.

**Advanced Enhancements**:
- Multi-user sharing / team access levels.
- Realtime updates with Supabase Realtime.
- Evaluation: RAGAS or manual metrics for answer quality.
- UI/UX: Markdown rendering, copy buttons, feedback thumbs.
- File support: PDFs, docs, web scraping (with permissions).
- Observability: LangSmith or custom logging.

This architecture delivers a **secure, production-ready** permission-aware RAG assistant. Start with the schema + RLS, then layer on ingestion and the AI gateway. The database-enforced security is the biggest differentiator — it protects against many common vulnerabilities. 

Fork a starter repo (search Supabase RAG templates), deploy, and iterate. Happy building! Questions or extensions? Let me know.
