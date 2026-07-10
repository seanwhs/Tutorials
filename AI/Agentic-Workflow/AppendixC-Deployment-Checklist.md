# Appendix C: Deployment Checklist — Production Readiness

## How to Use This Checklist
Run through every item before an agentic workflow is given access to real user data or real irreversible actions. Each item links back to the Part that implements it.

## 1. Cost Caps
- [ ] Per-run step ceiling enforced in code — Part 1, §6-7
- [ ] Per-plan step-count cap enforced — Part 4, §2
- [ ] Refinement/critique retry ceiling enforced in the router — Part 5, §4
- [ ] Re-plan attempt ceiling enforced — Part 4, §6
- [ ] Daily org-wide spend cap checked before every new run — Part 8, §5
- [ ] Per-user daily spend cap checked, separate from org cap — Part 8, §9
- [ ] Automated cost-watchdog alert wired — Part 7, §7
- [ ] Every run's actual cost is recorded via Langfuse trace data — Part 7, §6; Part 8, §5

## 2. Hallucination Guardrails
- [ ] Every tool has a Zod schema — Part 2, §2
- [ ] Tool descriptions explicitly scope *when* to use the tool — Part 2, §3
- [ ] Critique node checks factual claims are traceable to conversation/tool-result content — Part 5, §3
- [ ] Grounding step injects relevant long-term memory with a similarity threshold — Part 3, §7
- [ ] Golden dataset includes cases catching fabricated tool calls/unsupported claims — Appendix B, §2
- [ ] Tool-use accuracy tracked as a standing metric — Appendix B, §4

## 3. Human-in-the-Loop (HITL) Confirmation
- [ ] Irreversible-side-effect tools require explicit `confirmed: z.literal(true)` — Part 2, §9
- [ ] Critique verifies confirmation was set from a real prior user statement, not model inference — Part 5, §9
- [ ] An escalation path exists for repeated Critique failures — routes to human review, no silent shipping — Part 5, §6
- [ ] The escalation path has a real destination (n8n workflow paging a human/on-call) — Part 6, §4
- [ ] No tool can execute unbounded/arbitrary actions without a narrow, parameterized interface — Part 2, §4

## 4. Audit Logging
- [ ] Every run traced end-to-end (reasoning + tool calls + external n8n actions) in one observability system — Part 7, §4-5
- [ ] Outbound actions to external systems carry a correlation ID back to the originating agent run — Part 6, §6; Part 7, §5
- [ ] Full message transcript (not just the trimmed model-visible window) preserved as the append-only audit record — Part 1, §4; Part 3, §2
- [ ] Every deployed agent version tagged and included in trace metadata — Part 8, §6
- [ ] Per-run cost, latency, and pass/fail against golden dataset queryable historically — Part 7, §6; Part 8, §5; Appendix B, §3

## 5. Security & Secrets
- [ ] No API keys/credentials committed to source control or baked into container images — Part 8, §2, §4
- [ ] Model client fails fast at startup if required credentials are missing — Part 8, §4
- [ ] Documented key-rotation procedure exists and is exercised on a schedule — Part 8, §4
- [ ] n8n and Langfuse admin interfaces not exposed without authentication — Part 6, §3; Part 7, §3; Part 8, §3
- [ ] Database access from tools is parameterized (no string-concatenated queries) — Part 2, §4

## 6. Reliability & Resilience
- [ ] Tools distinguish retryable vs. non-retryable failures in their return type — Part 2, §2
- [ ] Transient network failures retried with exponential backoff + jitter before surfacing to the model — Part 6, §8-9
- [ ] Model client is provider-agnostic (swap via env var, no code change) — Part 1, §5
- [ ] Redeploys don't unnecessarily restart dependent infra services — Part 8, §7

## 7. Evaluation Gate (Pre-Merge / Pre-Deploy)
- [ ] Golden dataset eval suite runs automatically in CI on any prompt/tool/graph change — Appendix B, §3
- [ ] A regression in tool-use accuracy or forbidden-tool-call blocks merge — Appendix B, §3-4
- [ ] LLM-as-judge scores used as triage signal only, never sole automated gate for safety-critical behavior — Appendix B, §5

## 8. Pattern-Fit Sanity Check
- [ ] Chosen pattern justified against Appendix A's decision heuristic — not defaulted to out of habit
- [ ] If Reflection is used, its measured latency/cost overhead weighed against measured first-pass-success benefit for this specific use case

---
**Sign-off rule of thumb:** if any item under sections 2 ("Hallucination Guardrails") or 3 ("HITL Confirmation") is unchecked for a workflow touching real user data or real external actions, treat that as blocking — those two sections are where an ungoverned agent causes real-world harm.
