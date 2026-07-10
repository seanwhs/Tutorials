# Appendix A: The Agentic Pattern Matrix

## Purpose
A decision reference for choosing an agentic pattern for a new problem, rather than defaulting to whichever pattern you built most recently. Each pattern has a distinct cost/reliability/latency profile — picking the wrong one is a common source of over-engineered or under-engineered systems.

## The Matrix

| Pattern | Best For | Reliability Profile | Latency | Cost | Series Reference |
|---|---|---|---|---|---|
| **Simple Chain** (one model call) | Fixed-shape tasks: classification, extraction, single-step transformation | Highest — no branching to go wrong | Lowest | Lowest | Not covered as its own Part — the "do you even need an agent?" baseline |
| **ReAct** (Reason-Act loop) | Task-based, single-session goals, small unknown step count | Medium — can loop or pick wrong tools; bounded by step ceiling | Medium — scales with steps taken | Medium — pay per step | Part 1, Part 2 |
| **Plan-and-Execute** | Long-running, multi-step goals where upfront decomposition reduces drift | Medium-High — plan reduces drift but is "sticky" until re-planned | Higher — planning adds latency upfront | Higher — planning call + N execution calls | Part 4 |
| **Reflective (Generation-Critique-Refinement)** | Layered on top of any pattern, when correctness/safety matters more than speed | Highest achievable with LLMs | Highest — doubles+ calls per gated step | Highest — same multiplier as latency | Part 5 |
| **Multi-Agent** (Planner delegates to specialized agents) | Specialized-role tasks where a single prompt can't hold all necessary context/expertise | Variable — depends on inter-agent protocol design; new failure mode (miscommunication) | Highest — multiple independent agent loops | Highest — N agents each with own call budget | Part 9/9b |
| **Deterministic Workflow (n8n)** | Anything with a fixed, enumerable sequence of steps | Highest for the steps it covers — no reasoning to go wrong | Predictable | Predictable (no token cost, just infra) | Part 6 |

## Decision Heuristic (apply in this order)

1. **Can this be a fixed sequence of steps a human could flowchart without knowing what an LLM "thinks"?** → Deterministic workflow (n8n). Do not reach for an agent.
2. **Is the task small enough to complete in a handful of steps, where the model deciding "what's next" each step is genuinely useful?** → ReAct (Part 1-2).
3. **Does the task span enough steps/time that re-deriving strategy every step causes drift or excessive cost?** → Plan-and-Execute (Part 4).
4. **Is being wrong expensive (irreversible action, compliance-sensitive output, user-facing claim)?** → Add Reflection (Part 5) on top of whichever pattern you chose.
5. **Does the task require genuinely different expertise/context per sub-problem that a single prompt can't hold well?** → Consider Multi-Agent (Part 9/9b).

## Where This Series Stops (and the Multi-Agent Question)

*(Note: the text below was written before Part 9/9b existed, when Multi-Agent was still a hypothetical follow-up. It's preserved as-is since it documents the original reasoning, but see the flag after this section.)*

This series deliberately treats Part 5's Critique node as the simplest possible instance of "multiple reasoning roles cooperating" — one Generator role, one Critic role, communicating through shared state. A full Multi-Agent architecture is the natural next escalation once you have concrete evidence — from Part 7's traces and Appendix B's evaluation framework — that a single agent's context or role-mixing is the actual bottleneck, not before.

**The staff-engineer caution on Multi-Agent specifically:** it is the most expensive pattern in this matrix along every dimension (latency, cost, and — counterintuitively — reliability, because inter-agent handoffs are a new class of failure that doesn't exist in a single-agent system). Reach for it only when you have a measured, specific reason Plan-and-Execute-with-Reflection isn't sufficient.

---

⚠️ **Heads up:** this note's "Where This Series Stops" section is now slightly stale — it was written when Multi-Agent was still unbuilt and framed as a hypothetical "Part 9" follow-up. Since then, Part 9/9b was actually built. I've updated the table above (row now points to Part 9/9b) and the decision heuristic, but the closing prose section still reads as if Multi-Agent doesn't exist yet in this series. Want me to clean that section up to reflect that it's now a completed reference implementation?
