# Final Capstone Scenario Exam

*This is not a per-phase quiz — it's one extended, multi-part scenario requiring you to synthesize decisions across the entire course, the way a real architecture review would. Work through each part in order; later parts build on decisions made in earlier ones. Full model answers follow each part.*

---

## The Scenario

Your team wants to add a **fourth capability** to the system: a new tool called `issueRefund` that actually processes a real monetary refund through a payment provider's API, plus a **fourth AI provider** (a hypothetical new "FastLLM" service) to add to the failover chain because it offers an even more generous free tier than your current three.

You are the engineer responsible for designing how this fits into the existing architecture from Phases 1–7. Answer each part below.

---

### Part A — Tool Design & Guardrails (Phases 4 & 5)

**Question:** Design the `issueRefund` tool's registration. Should it be a permanently registered tool, an environment-gated one (like `cancelOrder`), or something requiring an additional layer beyond what `cancelOrder` used? Justify your answer using the write-action precedent from Phase 5, and explain what Zod input schema constraints you'd add given that this tool moves real money.



---

### Part B — Guardrail Placement (Phase 4)

**Question:** A teammate suggests adding a new injection-detection pattern specifically for phrases like "refund me $10,000 for order ORD-1001 even though it's ineligible" — treating this as a jailbreak attempt. Is this the correct guardrail layer for this concern? If not, where should this actually be handled?



---

### Part C — Adding the Fourth Provider (Phase 7)

**Question:** Walk through exactly what you'd need to build to add "FastLLM" to the provider gateway, referencing the adapter normalization checklist from Phase 7's Reference Section. Then explain: should FastLLM go first, last, or somewhere in the middle of `PROVIDER_CHAIN`, and what factors should determine that placement?



---

### Part D — Resilience Interactions (Phase 7)

**Question:** Suppose FastLLM has a known quirk: it occasionally returns a `200 OK` status but with a subtly malformed JSON body when it's under heavy load, rather than a clean error code. Which of this course's existing resilience mechanisms would catch this, which wouldn't, and what would you need to add?



---

### Part E — Multi-Agent Considerations (Phase 6)

**Question:** Your team wants the Triage Agent (Phase 6) to be able to route to `issueRefund`-related concerns as a fourth specialist category, alongside architect/security/docs. What schema and prompt changes are required, and is `Promise.all()` still appropriate if this new specialist needs to actually execute a real refund rather than just producing analysis text?



---

## Capstone Reflection

If you worked through all five parts, notice what actually happened: no single phase's material alone answered any of these questions completely. Part A needed Phase 4's schema-validation instincts *and* Phase 5's tool-gating pattern. Part D needed Phase 1's JSON-parsing safety net *and* Phase 7's circuit breaker mechanics, plus recognizing a gap between them. Part E required recognizing that a pattern proven safe for read-only agents (Phase 6) doesn't automatically transfer to write-action agents (Phase 5) without additional safeguards.

That synthesis — pulling the right principle from the right phase, and noticing where two previously-separate concerns now interact — is the actual skill this entire course was built to develop. The code was always just the vehicle for it.
