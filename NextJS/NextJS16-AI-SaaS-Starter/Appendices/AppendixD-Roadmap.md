## AI SaaS Tutorial - Appendix D: Phase 2 Roadmap

This is a suggested list of next features, roughly ordered from easiest to most involved, for extending Acme Docs AI beyond this tutorial series. All of this builds on the Next.js 16 codebase from Parts 0–15 and Appendix A.

### Quick wins (UI/UX layer, no new infrastructure)
- Show cited sources under each chat answer (`retrieveRelevantChunks` already returns `documentName` per chunk — thread it through the API response as metadata and render it)
- Per-document chat mode: let users click into a single document and scope retrieval to just that document's chunks (add a `documentId` filter to the retrieval SQL)
- Message editing/regeneration in chat
- Dark mode via Tailwind v4's `dark:` variant
- Workspace-level settings page (rename workspace, delete workspace with confirmation)

### Data pipeline improvements
- Support more file types: DOCX (via mammoth), HTML, and direct URL ingestion (fetch + strip tags)
- Smarter chunking: sentence/paragraph-boundary-aware splitting instead of a fixed character sliding window
- OCR support for scanned PDFs (e.g. via a free-tier OCR API or an open-source OCR model)
- De-duplication: skip re-embedding identical or near-identical chunks across re-uploads of the same document

### RAG quality improvements
- Re-ranking: after initial vector similarity search, re-rank the top ~20 candidates with a cheaper cross-encoder step before picking the final top-5
- Hybrid search: combine vector similarity with plain keyword/full-text search (Postgres `tsvector`) for queries with exact terms (names, codes, numbers)
- Query rewriting: use the LLM itself to expand/clarify a short or ambiguous user question before embedding it
- Conversation-aware retrieval: factor recent chat history into the retrieval query, not just the latest message

### Multi-tenancy and collaboration
- Team invitations via Clerk's built-in organization invite flow (add an "Invite members" UI using Clerk's `<OrganizationProfile />` component)
- Per-document sharing/permissions within a workspace (not just workspace-wide access)
- Audit log of who uploaded/deleted/asked what, scoped per workspace

### Billing and growth
- Usage-based billing add-on (e.g. charge for messages beyond the Pro plan's included quota using Stripe metered billing)
- Multiple paid tiers (Team/Enterprise) with higher limits and additional features
- Free trial period on the Pro plan via Stripe's `trial_period_days` on the Checkout session

### Analytics and ops
- Workspace owner dashboard: documents processed, messages sent over time, most-asked topics
- Error/alerting integration (e.g. a free-tier logging service) so failed document processing or webhook failures surface automatically
- Rate limiting on the chat API beyond plan quotas, to protect against abuse/runaway costs on the LLM provider side

### Model/infra flexibility
- Add more entries to the `FREE_MODELS` registry (Part 11) as new free-tier models become available, or add a simple admin UI to manage the list instead of hardcoding it
- Support swapping the vector store to a dedicated vector DB if pgvector's performance becomes a bottleneck at large scale — the retrieval interface in `retrieve.ts` is intentionally isolated to make this swap contained to one file

### Framework maintenance
- Keep Next.js, Clerk, and the Vercel AI SDK updated — all three ship frequent releases, and staying current avoids accumulating a large async-API migration later, similar to the Next.js 14/15 → 16 shift this series already navigated
- Watch for further Tailwind v4.x updates to the `@theme` CSS-first config conventions

None of these are required to have a working, deployed product — the 15-part series plus appendices already gets you a complete, functioning AI SaaS starter on Next.js 16. This roadmap is here for when you are ready to grow it into something more.

---

That's the **entire series** — all 15 parts, the Conclusion, and all 4 Appendices (A split across 5 notes, B, C, D). This completes the AI-Powered SaaS Starter tutorial series (Next.js 16 edition). You now have the complete walkthrough for building **Acme Docs AI** from an empty folder to a live, multi-tenant, billed, RAG-powered SaaS app. 
