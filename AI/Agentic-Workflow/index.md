# Architecting Intelligence: Building Production-Grade Agentic Workflows

**Series goal:** Move from "an LLM call with a prompt" to autonomous systems that reason, act, remember, self-correct, and are observable/operable in production.

**Stack decisions (locked for this series — all free/open-source):**
- **Orchestration:** LangGraph.js (`@langchain/langgraph`) — TypeScript, so the agent runtime and the Next.js app layer share one language and one type system.
- **Visual/Integration layer:** n8n (self-hosted, open-source) — for deterministic, external-system "action" workflows (Slack, CRM, email, webhooks).
- **App layer:** Next.js 16 (App Router) — chat UI, Server Actions as the agent's HTTP boundary, streaming responses.
- **LLM access:** OpenAI-compatible Chat Completions API syntax throughout, via a thin adapter — swap in Ollama, vLLM, Groq, or OpenAI itself by changing `baseURL`/model name only. No code in the tutorials is locked to a paid vendor.
- **Vector store (Part 3):** open-source, self-hostable (pgvector on Postgres) — no managed vector DB dependency.
- **Observability (Part 7):** Langfuse, self-hosted via Docker Compose — the open-source LangSmith equivalent.
- **Deployment (Part 8):** Docker + docker-compose on a plain VPS — no PaaS lock-in.

**Why this stack (Staff Engineer framing):** every choice above optimizes for *portability and no vendor lock-in* over "fastest to a demo." That trade-off costs you a bit of setup time and buys you: no per-seat billing surprises, full data residency control, and the ability to swap any single layer without a rewrite.

## Series Structure

| Part | Title | Core Deliverable |
|---|---|---|
| 1 | The Anatomy of an Agent | LangGraph execution graph, ReAct loop, `StateGraph` fundamentals |
| 2 | The Tool Layer | Zod-validated, type-safe tools (API, DB, Search) |
| 3 | Memory & Context | Session (short-term) + pgvector RAG (long-term) memory |
| 4 | Task Decomposition & Planning | Plan-and-Execute agent architecture |
| 5 | Reflection & Self-Correction | Generation-Critique-Refinement loop |
| 6 | Visual Orchestration with n8n | Hybrid system: n8n = Action, LangGraph = Reasoning |
| 7 | Observability & Tracing | Self-hosted Langfuse, trace/token/latency analysis |
| 8 | Deployment & Governance | Docker/VPS deployment, key rotation, lifecycle mgmt |
| 9 | Multi-Agent Orchestration (+ 9b) | Planner delegating to a Coder agent and a Reviewer agent, each an isolated LangGraph subgraph with its own tools/model |
| A | Appendix: The Agentic Pattern Matrix | ReAct vs Plan-and-Execute vs Multi-Agent — when to use which |
| B | Appendix: The Evaluation Framework | Golden datasets, tool-use accuracy benchmarks |
| C | Appendix: Deployment Checklist | Production readiness checklist |

## Architectural North Star

**Deterministic Workflows vs. Probabilistic Agents** — the single most important distinction in this series:
- **Deterministic workflow:** fixed sequence at design time. Near-100% reliability, predictable latency/cost, no generalization to novel inputs.
- **Probabilistic agent (ReAct):** model decides next step at runtime. Generalizes to unanticipated inputs, at the cost of variable latency/cost and non-zero risk of an incorrect or looping decision.

**Staff Engineer rule used throughout:** push as much as possible into the deterministic category; reserve probabilistic reasoning only where judgment is genuinely required. This is why Part 6 splits n8n (deterministic action) from LangGraph (probabilistic reasoning), and why Part 9 extends the same rule into multi-agent — mechanical fixes should never be routed through another full agent invocation.

## Prerequisites
- Node.js 20+, pnpm (or npm)
- Docker + Docker Compose (Postgres/pgvector, Langfuse, n8n)
- An OpenAI-compatible API endpoint (OpenAI key or local Ollama)
- Basic async TypeScript / React Server Components familiarity

## Note on Part 9
Part 9 was added as a confirmed follow-up, per Appendix A's guidance to only build Multi-Agent with a measured need. Due to a note-length constraint hit mid-draft, it's split across two notes:
- **Part 9: Multi-Agent Orchestration** — sections 1-5 (trigger condition, distributed-systems framing, shared contracts, role isolation, Coder agent's graph)
- **Part 9b: Reviewer, Planner, and Orchestration** — sections 6-11 (Reviewer agent, Planner orchestration loop, n8n escalation, cross-agent observability, exercise+solution)

Read Part 9 immediately followed by 9b as one continuous unit.

---
*Notes in this series are prefixed "Agentic Workflows - ". Read in order.*
