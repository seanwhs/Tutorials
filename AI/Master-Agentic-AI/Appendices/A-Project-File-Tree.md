# Appendix A: Full Project File Tree

Here's the complete, consolidated directory structure of the application as it stands after all seven phases. A few notes before the tree itself:

- **Files marked `(diagnostic — delete after verifying)`** were built purely as throwaway test harnesses during a specific part's Verification step, and the tutorial explicitly instructed removing them once confirmed working (e.g., `timeout-test`). If you followed along and cleaned up as instructed, your project won't have these.
- **Files marked `(superseded)`** existed briefly but were fully rewritten or deleted later in the series as the architecture evolved (e.g., `lib/agent/tools.js` was replaced entirely by the `lib/agent/mcp/` registry system in Phase 5). They're listed at the point they were introduced, with a note on what replaced them.
- Everything else is a **permanent, final-state file** that should exist in your finished project.

```
agentic-nextjs-course/
├── .env.local                                  # All API keys + config flags (never committed)
├── .gitignore                                  # Default from create-next-app (already ignores .env*.local)
├── next.config.mjs                             # Enables `use cache` via experimental.useCache
├── middleware.js                                # Global API key auth + request tracing (Phase 5)
├── package.json
│
├── app/
│   └── api/
│       └── agent/
│           ├── ping/route.js                            # Phase 1 — first provider connection test
│           ├── react/route.js                           # Phase 1–7 — core one-shot ReAct endpoint
│           ├── timeout-test/route.js                     # (diagnostic — deleted end of Phase 1, Part 3)
│           ├── prompt-timing/route.js                    # Phase 2 — observes `use cache` behavior
│           ├── trim-test/route.js                        # Phase 2 — unit tests token trimming
│           ├── chat/route.js                             # Phase 2–7 — stateful, guarded, cost-tracked chat endpoint
│           ├── session-debug/route.js                    # Phase 2 — inspects session store directly
│           ├── search-test/route.js                      # Phase 3 — unit tests vectorless search
│           ├── agentic-retrieve-test/route.js            # Phase 3 — observes search→judge→retry loop
│           ├── order-test/route.js                       # Phase 3 — unit tests key-value order lookup
│           ├── cost-test/route.js                         # Phase 3 — unit tests pricing calculations
│           ├── cost-summary/route.js                      # Phase 3 — per-session cumulative cost report
│           ├── redaction-test/route.js                    # Phase 4 — unit tests PII redaction
│           ├── injection-test/route.js                    # Phase 4 — unit tests jailbreak detection
│           ├── classify-ticket/route.js                   # Phase 4 — Zod-validated structured output demo
│           ├── registry-test/route.js                     # Phase 5 — unit tests the MCP tool registry
│           ├── whoami/route.js                            # Phase 5 — proves middleware→handler data flow
│           ├── specialist-test/route.js                   # Phase 6 — tests one specialist agent in isolation
│           ├── design-review/route.js                     # Phase 6 — concurrent 3-agent fan-out (Promise.all)
│           ├── design-review-sequential/route.js          # Phase 6 — sequential comparison (timing proof only)
│           ├── design-cascade/route.js                    # Phase 6 — full triage→fan-out→synthesis cascade
│           ├── retry-test/route.js                        # Phase 7 — unit tests exponential backoff
│           └── gateway-status/route.js                    # Phase 7 — circuit breaker / provider health check
│
└── lib/
    ├── data/
    │   ├── knowledgeBase.json                  # Phase 3 — policy documents corpus
    │   └── orders.json                          # Phase 3 — simulated order records
    │
    └── agent/
        ├── tools.js                             # (superseded — Phase 3; fully replaced by lib/agent/mcp/ in Phase 5)
        ├── timeoutCompletion.js                  # Phase 1 → rewritten in Phase 7 (adds retry + deadline signal)
        ├── fallbackAnswer.js                     # Phase 1 → rewritten in Phase 7 (routes through provider gateway)
        ├── systemPrompt.js                       # Phase 2 → rewritten in Phase 5 (generates from tool registry)
        ├── tokenBudget.js                        # Phase 2 — token estimation + history trimming
        ├── usageTracker.js                       # Phase 2 → rewritten in Phase 3 (adds cost calculation)
        ├── sessionStore.js                       # Phase 2 — in-memory cross-request session Map
        ├── session.js                            # Phase 2 — cookie-based session ID resolution
        ├── reactLoop.js                          # Phase 2 → rewritten in Phases 3, 5, 7 (final: gateway + deadline + registry)
        ├── eventBus.js                            # Phase 6 — per-request pub/sub for multi-agent handoff
        ├── classifyTicket.js                      # Phase 4 — validate-and-retry structured output loop
        │
        ├── retrieval/
        │   ├── vectorlessSearch.js                # Phase 3 — keyword/tag scoring search engine
        │   ├── judgeRetrieval.js                  # Phase 3 — LLM-based retrieval quality judge
        │   ├── agenticRetrieve.js                 # Phase 3 — search→judge→rewrite→retry loop
        │   ├── orderLookup.js                     # Phase 3 → updated in Phase 5 (calls simulated DB, not JSON directly)
        │   └── shipmentTracking.js                # Phase 3 — simulated external carrier API call
        │
        ├── cost/
        │   ├── pricing.js                          # Phase 3 — per-model $/million-token rate table
        │   ├── calculateCost.js                    # Phase 3 — token counts → dollar cost conversion
        │   └── costLedger.js                       # Phase 3 — per-session cumulative cost accumulator
        │
        ├── security/
        │   ├── piiRedaction.js                     # Phase 4 — regex-based PII detection + masking
        │   └── injectionDetection.js               # Phase 4 — jailbreak/prompt-injection pattern blocking
        │
        ├── schemas/
        │   ├── chatRequestSchema.js                # Phase 4 — Zod schema for /chat request body
        │   ├── ticketClassificationSchema.js       # Phase 4 — Zod schema for structured ticket output
        │   ├── architectSchema.js                  # Phase 6 — Zod schema for Architect Agent output
        │   ├── securitySchema.js                   # Phase 6 — Zod schema for Security Auditor output
        │   ├── docsSchema.js                       # Phase 6 — Zod schema for Documentation Agent output
        │   ├── triageSchema.js                     # Phase 6 — Zod schema for Triage Agent routing decision
        │   └── synthesisSchema.js                  # Phase 6 — Zod schema for Synthesizer Agent verdict
        │
        ├── specialists/
        │   ├── runSpecialist.js                    # Phase 6 — shared single-shot specialist call helper
        │   ├── architectAgent.js                   # Phase 6 — structural/architecture review agent
        │   ├── securityAgent.js                    # Phase 6 — security vulnerability audit agent
        │   ├── docsAgent.js                        # Phase 6 — plain-English summary agent
        │   ├── triageAgent.js                      # Phase 6 — decides which specialists are relevant
        │   └── synthesizerAgent.js                 # Phase 6 — combines specialist findings into one verdict
        │
        ├── mcp/
        │   ├── defineTool.js                        # Phase 5 — formal tool definition factory function
        │   ├── ToolRegistry.js                      # Phase 5 — central tool registration/dispatch class
        │   ├── registry.js                          # Phase 5 — single assembled registry instance (+ env gating)
        │   └── tools/
        │       ├── calculatorTool.js                # Phase 5 — arithmetic tool (MCP-wrapped)
        │       ├── currentTimeTool.js                # Phase 5 — UTC timestamp tool (MCP-wrapped)
        │       ├── knowledgeBaseTool.js              # Phase 5 — agentic RAG tool (MCP-wrapped)
        │       ├── orderLookupTool.js                # Phase 5 — key-value order lookup (MCP-wrapped)
        │       ├── shipmentTrackingTool.js           # Phase 5 — external API tracking tool (MCP-wrapped)
        │       └── cancelOrderTool.js                # Phase 5 — write-action tool, environment-gated
        │
        ├── db/
        │   └── simulatedOrderDb.js                  # Phase 5 — simulated async DB client (query + update)
        │
        ├── resilience/
        │   ├── withRetry.js                          # Phase 7 — exponential backoff + jitter retry wrapper
        │   └── deadline.js                            # Phase 7 — whole-loop AbortController deadline utility
        │
        └── providers/
            ├── groqAdapter.js                        # Phase 7 — normalizes Groq SDK to common response shape
            ├── deepseekAdapter.js                    # Phase 7 — normalizes DeepSeek SDK to common response shape
            ├── geminiAdapter.js                      # Phase 7 — normalizes Gemini SDK to common response shape
            ├── circuitBreaker.js                     # Phase 7 — per-provider failure tracking + cool-down
            └── providerGateway.js                    # Phase 7 — unified entry point: failover + retry + circuit breaking
```

### Reading This Tree: Three Things Worth Noticing

**1. The `mcp/` folder is where the tool ecosystem "graduated."** Everything under `lib/agent/mcp/` didn't exist until Phase 5 — before that, tools were plain functions sitting in the now-superseded `lib/agent/tools.js`. If your project still has that old file lying around alongside the `mcp/` folder, it's dead code and safe to delete (the tutorial explicitly calls this out at the end of Phase 5, Part 1).

**2. Several files appear "rewritten" multiple times across phases** — `reactLoop.js` is the clearest example, touched in Phases 2, 3, 5, and 7. This isn't churn for its own sake; it's the natural consequence of the course's incremental-build philosophy. Each phase's version was fully verified before the next phase modified it further. If you're auditing your own project against this tree, what matters is that your **current, final version** of each of these files matches the last full listing given for it in the series — not that you kept every intermediate draft.

**3. The `retrieval/`, `cost/`, `security/`, `schemas/`, `specialists/`, `mcp/`, `db/`, `resilience/`, and `providers/` subfolders each map to exactly one phase's core contribution.** If you ever lose track of "which phase introduced this concept," this tree doubles as a quick lookup: the subfolder name is almost always the phase's theme (retrieval → Phase 3, security → Phase 4, mcp → Phase 5, specialists → Phase 6, resilience/providers → Phase 7).

### Quick Sanity-Check Commands

To confirm your own project matches this structure, run from your project root:

```bash
find lib/agent -type f -name "*.js" | sort
```

This should output every file under `lib/agent/` and its subfolders, which you can diff mentally (or with a text comparison) against the tree above. Similarly:

```bash
find app/api/agent -type f -name "route.js" | sort
```

will list every endpoint currently in your project — useful for confirming you've either kept or properly cleaned up the diagnostic-only routes flagged in the tree.
