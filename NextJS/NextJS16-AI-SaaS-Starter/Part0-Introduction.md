## AI SaaS Tutorial - INDEX (Start Here) - COMPLETE & VALIDATED FOR NEXT.JS 16

### What we're building
**"Acme Docs AI"** — a "Notion + ChatGPT" mini SaaS: users sign up, create workspaces (multi-tenant), upload documents, and chat with those documents using Retrieval-Augmented Generation (RAG). Includes Stripe billing (subscription plans that gate usage) and multi-tenancy (workspaces with roles/members).

### Stack (all free/open-source tiers, targets Next.js 16)
- Next.js 16 (App Router, Turbopack default) + TypeScript + Tailwind CSS v4 (CSS-first config, no `tailwind.config.js`) — requires Node.js 20.9+ or 22 LTS
- Postgres (Neon free tier) + Prisma 6+ ORM + pgvector for embeddings
- Auth: Clerk (free tier), Organizations = Workspaces
- AI: Vercel AI SDK — free model list in code (Groq free API, OpenRouter free models, local Ollama)
- Embeddings: open-source `nomic-embed-text`
- Billing: Stripe (test mode)
- File storage: UploadThing free tier
- Hosting: Vercel free tier

### Critical Next.js 16 pattern
Every dynamic `[workspaceId]` page/route uses Promise-based params: `{ params }: { params: Promise<{ workspaceId: string }> }` → `const { workspaceId } = await params;`. Clerk's `auth()` and Next.js's `headers()` are awaited everywhere used.

### All 25 notes in this series
1. Part 0: Introduction & Architecture
2. Part 1: Project Setup
3. Part 2: Database Schema (Prisma + pgvector)
4. Part 3: Auth & Multi-Tenancy (Clerk Organizations)
5. Part 4: Workspace CRUD, Roles & Access Control
6. Part 5: Document Upload Pipeline
7. Part 6: Text Extraction & Chunking
8. Part 7: Embeddings & Vector Storage (Free Model Selection)
9. Part 8: RAG Retrieval Logic
10. Part 9: Chat UI with Vercel AI SDK
11. Part 10: Wiring RAG into Chat End-to-End
12. Part 11: Free LLM Provider Abstraction (Model List in Code)
13. Part 12: Stripe Billing & Subscription Plans
14. Part 13: Enforcing Plan Limits per Workspace
15. Part 14: Polish (Loading, Error & Empty States)
16. Part 15: Deployment to Vercel (Free Tier)
17. Conclusion & Next Steps
18. Appendix A (1 of 4): Config, Schema & Core Lib
19. Appendix A (2 of 4): Auth, Middleware & Webhooks
20. Appendix A (3 of 4): Upload & RAG Pipeline
21. Appendix A (4 of 4): Chat UI and AI Provider Registry
22. Appendix A (4b of 4): Chat Component, Billing Actions and Pages
23. Appendix B: Environment Variables and Free-Tier Signup Guide
24. Appendix C: Troubleshooting Guide
25. Appendix D: Phase 2 Roadmap
