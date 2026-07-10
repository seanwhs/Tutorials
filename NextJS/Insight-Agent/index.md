# InsightAgent — Personalized Agentic Research Dashboard
## Tutorial Series Index

### Stack (canonical)
Next.js 16 · Tailwind CSS v4 (CSS-first) · Clerk (auth) · Neon Postgres + Drizzle ORM · Vercel AI SDK (`streamText` tool loop) · **Free-tier model agility via Groq / Together AI / Hugging Face Inference (`@ai-sdk/openai-compatible`)** · Tavily (search tool) · Firecrawl (scrape tool) · Vitest + `ai/test` `MockLanguageModelV2` · Vercel Hobby hosting

### Consolidated env vars
Clerk keys/URLs, `DATABASE_URL`, `GROQ_API_KEY`, `TOGETHER_API_KEY`, `HUGGINGFACE_API_KEY`, `DEFAULT_MODEL_ID`, `TAVILY_API_KEY`, `FIRECRAWL_API_KEY`, `NEXT_PUBLIC_APP_URL`

### Series Map

| Phase | Title | Status |
|---|---|---|
| 1 | Setup & Infrastructure | ✅ Complete |
| 2 | The Agentic Core | ⬜ Not started |
| 3 | UI & Streaming | ⬜ Not started |
| 4 | Persistent Chat History | ⬜ Not started |
| 5 | Testing the Agent | ⬜ Not started |
| 6 | Deploy | ⬜ Not started |
| — | Conclusion | ⬜ Not started |
| — | Appendix A | ⬜ Not started |
| — | Additional Resources | ⬜ Not started |

### Phase 1 (complete) — split across 6 notes
"...Phase 1 - Setup & Infrastructure" (Intro/Series Map/Steps 1.1–1.2) · "...Step 1.3 Tailwind v4" · "...Step 1.4 Clerk Auth" · "...Step 1.5 Neon + Drizzle" · "...Step 1.6 Folder Structure"

### Canonical file paths locked in for the rest of the series
`src/lib/agent/models.ts`, `system-prompt.ts`, `agent-loop.ts` (+`.test.ts`), `tools/tavily-search.ts` (+`.test.ts`), `tools/firecrawl-scrape.ts` (+`.test.ts`), `src/app/api/chat/route.ts`, `src/components/ThoughtDashboard.tsx`, `ReportView.tsx`, `ModelSelector.tsx`, `ChatInput.tsx`, `src/app/dashboard/page.tsx`, `src/db/schema.ts`/`index.ts`, `drizzle.config.ts`, `vitest.config.ts`
