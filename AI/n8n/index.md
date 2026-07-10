# Mastering Workflow Orchestration: n8n for Production-Grade Automation

**Series prefix for all notes:** `n8n Mastery - `

**Perspective:** Senior Automation Architect. We do not treat n8n as a "no-code toy" — we treat every workflow as a **software artifact**: versioned, tested, observable, and deployed via Infrastructure as Code (IaC).

---

## Why This Series Exists

Most n8n tutorials show you how to drag three nodes together and call it a day. This series is different. We build a **production backbone**: a self-hosted n8n Community Edition instance that can safely sit behind your Next.js app, your internal tools, and your AI agents — with retries, audit logs, database persistence, Git-based change tracking, and horizontal scaling via Queue Mode.

By the end, you will have:
- A fully containerized n8n stack (Docker Compose: n8n + Postgres + Redis)
- A library of reusable, defensively-coded workflows
- A CI/CD pipeline that exports/imports workflows as versioned JSON in Git
- A production deployment topology (Queue Mode with Workers) ready for a VPS
- A security-hardened credential and network model

---

## Tooling Constraint (Strict, Applies to Entire Series)

| Category | Choice | Why |
|---|---|---|
| Automation engine | **n8n Community Edition** (self-hosted, fair-code license) | Free, no execution caps, full node access, Docker-native |
| Database | **PostgreSQL 16** | Free, production-grade; both n8n's own backing store AND the "business" DB in Part 4 |
| Queue broker | **Redis 7** | Free, required for Queue Mode / scaling in Part 8 |
| AI/LLM | **Ollama** (local models, e.g. `llama3.1`, `nomic-embed-text`) w/ optional notes for Anthropic/OpenAI | Zero-cost default; swappable |
| Vector store (RAG) | **Postgres + pgvector** | Reuses the same free Postgres instance |
| Reverse proxy (prod) | **Caddy** or **Nginx** (free) | TLS termination, free Let's Encrypt certs |
| CI/CD | **GitHub Actions** (free tier) + **n8n CLI** | Git-based workflow versioning |
| Hosting target | **Any VPS** (Hetzner/DigitalOcean-style, generic) | Front-end on Vercel, n8n engine on a VPS/Docker host |

> **Architecture note:** n8n Cloud is a managed SaaS (subscription, no server ops). n8n Community is the fair-code, self-hosted, free-forever core used here — you own the server, the data, the uptime, and the scaling decisions. This series is 100% Community Edition.

---

## Series Map

| Part | Title | Core Deliverable |
|---|---|---|
| 1 | The Automation Engine | `docker-compose.yml` for n8n + Postgres + Redis, persistent volumes, execution model deep-dive |
| 2 | Triggers & Hooks | Webhook node hardening, Cron patterns, polling trigger design, dedup strategies |
| 3 | Data Transformation (The "Code" Philosophy) | Code node (JS + Python) patterns: parsing, normalization, array reshaping |
| 4 | Database Integration | Postgres CRUD workflow acting as a secure API backend for a Next.js form |
| 5 | AI Agentic Workflows | Ollama-backed AI Agent node, memory, RAG via pgvector, custom Tool nodes |
| 6 | Resilience & Observability | Error Trigger workflows, retry policies, structured logging/audit trail table |
| 7 | Git-Based Versioning | n8n CLI export/import, GitHub Actions pipeline, PR-based workflow review |
| 8 | Production Deployment & Scaling | VPS deployment, Queue Mode + Workers, Caddy TLS, credential/CORS/API-key hardening |
| A | Codebase Reference | Full repo folder structure for an n8n IaC project |
| B | Node Library Cheat Sheet | Quick-reference tables: mapping, Code node hygiene, branching logic |
| C | Automation Checklist | Local → Production migration checklist |

---

## Prerequisites
- Docker + Docker Compose v2 installed
- Basic JavaScript comfort (Python optional, used only in Part 3's comparison)
- A free GitHub account (Part 7)
- Nothing paid is required anywhere in this series

## How to Use This Series
Read Parts 1–8 in order — each part builds on and imports artifacts from the previous part (e.g., Part 4's CRUD workflow is called as a sub-workflow by Part 5's AI agent; Part 6 wraps error-handling around Part 2's webhook). Appendices are standalone references you'll return to constantly.
