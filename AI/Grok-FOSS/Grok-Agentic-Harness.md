# Project Charter: Grok Build CLI — Agentic Harness

## 1. Problem Statement
You're using GPT-4o/Claude for everything today, which means every task — cheap or complex, sensitive or not — goes through an expensive, US-hosted, vendor-locked API. With Grok weights now open-sourced, there's an opportunity to **own** part of your model stack: self-host for cost/privacy-sensitive workloads, keep managed APIs for complex reasoning. But nothing currently exists to *decide* which task goes where. This harness is that missing routing layer.

## 2. Objective
Build a CLI tool that takes a task as input, automatically routes it to either a self-hosted grok-oss model or a managed API (Claude/GPT-4o) based on cost/complexity/sensitivity rules, executes it (including tool calls), verifies the output, and logs the result — so routing logic is written once and reused across SGX Dashboard, TTX Facilitator Tool, and the Tutorial app.

## 3. Scope
**In scope:** CLI entrypoint, task classifier, routing logic, execution loop, output verification, logging/telemetry, documentation, test suite, containerized deployment.
**Out of scope (v1):** GUI/web interface, multi-user auth, fine-tuning pipeline (separate follow-on project).

## 4. The Four Phases

| Phase | Name | Activity | Key Output | Value Type |
|---|---|---|---|---|
| **1** | **Design** | Documentation + system/sequence diagrams, ADRs, interface spec | Architecture doc, config schema | IP / teachable asset |
| **2** | **Build** | Prototype from scratch, incremental layering | Working CLI repo | Product / portfolio piece |
| **3** | **Verify** | Unit, integration, and benchmark testing | Test suite, benchmark report | Credibility / proof |
| **4** | **Harden & Ship** | Containerize, validate config, package for reuse | Docker image, internal package (npm/PyPI) | Reusable infrastructure |

**Important:** these are a loop, not a line. Design → Build → Verify → feed learnings back into Design → Build v2 → Verify v2 → Harden. Don't treat Phase 1 docs as final until at least one loop has run.

---

### Phase 1 — Design
- System diagram: `CLI entrypoint → task classifier → router (local/grok-oss vs managed/Claude-GPT4o) → tool-execution loop → verifier → output`
- Sequence diagrams: (a) happy path, (b) fallback path (grok-oss fails confidence check → escalate to GPT-4o)
- ADR: why CLI (not API route), why this routing threshold logic
- Interface spec: input/output schema, config file format (model, baseURL, API keys)

### Phase 2 — Build
- v0: single command, one hardcoded route, no config
- v1: add config file → routing logic → tool-calling → logging
- Maintain a build log/`CHANGELOG.md` as you go (this becomes Phase 1 doc content for free)

### Phase 3 — Verify
- Unit: router picks correct model given input characteristics
- Integration: full task (e.g. "summarize this SGX report") completes end-to-end on both paths
- Benchmark: latency, cost/task, output quality diff — reuse as the "benchmark comparison chart" deliverable

### Phase 4 — Harden & Ship
- Dockerize, add config validation
- Publish as internal package so SGX Dashboard and TTX Facilitator Tool import it instead of rebuilding routing logic
- Add ADR log for every routing decision (audit trail for compliance-sensitive clients)
- Turn Phase 3 into a recurring (e.g. weekly) benchmark job — a living scorecard, not a one-off

---

## 5. Success Criteria
- [ ] Harness routes a real task correctly between grok-oss and managed API without manual intervention
- [ ] Test suite passes on both paths (unit + integration)
- [ ] Benchmark report shows quantified cost/latency/quality tradeoffs
- [ ] Packaged and importable by at least one other project (SGX or TTX)
- [ ] Documentation is sufficient for someone else (or future-you) to rebuild it from scratch

## 6. How This Pays Off Beyond the Build
1. **Portfolio proof** — a working, documented, tested harness for client conversations (TTX, SDLC, SGX)
2. **Shared infrastructure** — build once, reuse in SGX Dashboard + TTX Facilitator Tool
3. **Teaching content** — becomes Tutorial app "Lesson 8" with minimal rework
4. **Client due-diligence artifact** — system diagram + verification report satisfies compliance asks directly

## 7. Risks / Open Questions
- Routing thresholds are guesses until real benchmark data exists — expect to revise after Phase 3
- Self-hosting adds DevOps burden — confirm you have bandwidth before committing to Phase 4 packaging
- Grok-oss quality gap (~5–10%) may make some "cheap" tasks fail verification and escalate anyway — track this rate
