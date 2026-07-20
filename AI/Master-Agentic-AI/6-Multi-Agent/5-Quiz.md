# Quiz: Phase 6 — Parallel Multi-Agent Cascades

---

**Q1.** Explain precisely why it was *safe* for this course to use `Promise.all()` for the three specialist agents, given that `Promise.all()` normally rejects entirely the moment any single promise rejects, discarding the other results. What specific design decision made in `runSpecialist()` neutralizes this risk?



---

**Q2.** If you removed the `runSpecialist()` wrapper's internal try/catch entirely, and a raw, uncaught exception could propagate from inside `runArchitectAgent()`, would `Promise.all()` still be a safe choice for the concurrent fan-out in `design-review/route.js`? What combinator would you switch to instead, and why?



---

**Q3.** The design-cascade endpoint's Synthesizer Agent reads specialist findings via `bus.read({ type: 'specialist_finding' })` rather than receiving them as direct function arguments from the Stage 2 code that produced them. Why does this specific detail matter architecturally, even though functionally it accomplishes the same outcome as passing the array directly?



---

**Q4.** Why is `createEventBus()` called freshly inside every single `POST` handler invocation, rather than being created once at module load time and reused across all requests (similar to how the Groq client itself is created once at module level)?



---

**Q5.** The Triage Agent decides which specialists actually run for a given request. Beyond the obvious latency benefit of running fewer model calls, what specific *cost* argument from this phase justifies paying for an extra triage call on every single request, even ones that end up needing all three specialists anyway?



---

**Q6.** A "debate" or adversarial multi-agent pattern (mentioned in this phase's Reference Section) has two agents deliberately given opposing positions on the same question. Explain why this topology would be a poor fit for the specific problem this course's Architect/Security/Docs specialists solve, and describe a scenario where it genuinely would be the better choice.
