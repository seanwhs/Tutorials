# Appendix E — Threat Model & Security Reference

This appendix consolidates the security and threat-model material scattered across the Greymatter LMS series into a single reference — the appendix you'd hand to someone auditing the system independently of the tutorial narrative.

---

## E.1 The Foundational Isolation Principle

Every security concern in Greymatter LMS traces back to one absolute rule:

> "Every piece of data belongs to: `organization_id`. No exceptions." [1]

This is restated later as a summary principle, phrased even more simply:

> "Data is always scoped. Everything is organization-bound." [1]

There is no carve-out, no "internal admin" exception, no "just for analytics" exception mentioned anywhere in the source material — the rule is stated as unconditional both times it appears [1].

---

## E.2 Defense-in-Depth Architecture

Rather than relying on a single security boundary, Greymatter LMS is designed as a layered chain, where each stage independently narrows what's allowed to pass through to the next:

```text
Client Layer (untrusted)
↓
Server Actions (validated)
↓
Supabase (RLS enforced)
↓
Inngest (controlled execution)
↓
Registry (sanitized worker discovery)
↓
Workers (isolated execution)
```
[1]

Reading this chain top to bottom is itself a security model:

- **Client Layer** — assumed untrusted by default, no exceptions.
- **Server Actions** — the first validation checkpoint.
- **Database (Supabase in the original spec)** — enforces Row-Level Security, tying back directly to the isolation principle in E.1.
- **Inngest** — executes workflows in a controlled manner rather than freely.
- **Registry** — worker discovery is sanitized before being handed off.
- **Workers** — execute in isolation from each other and from the core.

*(Greymatter LMS note: if you're following the Neon Postgres adaptation rather than Supabase, the "RLS enforced" stage becomes "manual `organization_id` checks," since Neon does not provide Row-Level Security natively — see Appendix C.2 and D.2 for the full adaptation detail.)*

---

## E.3 What This Model Explicitly Prevents

Although the source material doesn't provide an exhaustive attacker-scenario list beyond the isolation principle itself, the chain in E.2 tells you precisely what each layer is responsible for stopping:

| Layer | What it must stop |
|---|---|
| Server Actions | Unvalidated or unauthenticated requests reaching the data layer |
| Database (RLS / manual checks) | Cross-organization data access — the core violation the isolation principle exists to prevent [1] |
| Inngest | Uncontrolled or arbitrary workflow execution |
| Registry | Untrusted or unsanitized worker discovery results reaching execution |
| Workers | One worker's execution affecting another's, or affecting the LMS core |

---

## E.4 Why Worker Isolation Is a Security Boundary, Not Just an Architecture Choice

Several principles from earlier appendices double as security guarantees once you view them through this lens:

> "Workers do not depend on LMS internals." [3]

> "AI is fully decoupled. Workers evolve independently." [7]

> "Each AI system is replaceable." [4]

Read architecturally, these are modularity benefits. Read as security properties, they mean a compromised or misbehaving worker cannot reach into LMS internals it was never given a reference to — its blast radius is limited to its own execution sandbox and whatever the registry explicitly discovered it for.

---

## E.5 Registry as a Security Gatekeeper

The registry (Sanity) isn't just a discovery mechanism — per the Defense-in-Depth chain, it's explicitly the "sanitized worker discovery" checkpoint sitting between Inngest and the workers themselves [1]. This means the registry's job includes ensuring that only legitimate, versioned, capability-matched workers [4] are ever handed a request — not an arbitrary or spoofed endpoint.

---

## E.6 Source of Truth vs. Source of Interpretation

A subtler but important security-adjacent principle governs how much trust AI output itself is given:

> "Supabase is the source of truth. AI is the source of interpretation." [6]

This distinction matters for a threat model because it means AI-generated output (grades, feedback, analytics) is never treated as unquestionable fact — it's interpretation, layered on top of the actual system of record. Practically, this is also why AI outputs are normalized into their own artifact tables rather than mixed into core system data:

> "To avoid mixing raw AI output with system data, we normalize artifacts." [6]

This separation limits the damage a compromised or hallucinating AI worker can do — it can pollute its own artifact records, but it was never designed to overwrite the system's actual source-of-truth tables directly.

---

## E.7 Traceability as a Security Control

Observability, covered in Appendix B.13, is also a legitimate security control, not just a debugging convenience:

> "If you cannot trace it, you cannot trust it." [11]

> "Full traceability. Every decision is logged." [11]

> "Each Inngest workflow generates a trace ID." [11]

From a threat-model perspective, this means every worker invocation, every event, and every workflow decision leaves an auditable trail — a prerequisite for detecting misuse, misbehaving workers, or unauthorized access patterns after the fact.

---

## E.8 Known Gaps (Honest Assessment)

The source material available in this series documents the isolation principle and the defense-in-depth chain explicitly [1], but does not provide further granular detail (e.g., specific rate-limiting configuration, secret-rotation procedures, or replay-attack mitigations) beyond what's captured above. If you need those specifics, treat E.1–E.7 as the architectural foundation to build additional, more detailed security hardening on top of — the source material establishes the *principles* (organization-scoping, layered validation, worker isolation, traceability) rather than exhaustive implementation-level security procedures.

---

## E.9 How to Use This Appendix

When auditing or reasoning about a security concern in Greymatter LMS:

1. **Does it involve data access?** → Start at E.1; confirm `organization_id` scoping is enforced.
2. **Are you tracing a request's path through the system?** → Use E.2's chain to identify which layer should have stopped a given issue.
3. **Is a worker behaving unexpectedly?** → Check E.4–E.5; confirm it was properly discovered via the registry and isn't reaching into internals it shouldn't have access to.
4. **Is AI output being trusted somewhere it shouldn't be?** → Check E.6 — AI is interpretation, not truth.
5. **Are you investigating an incident after the fact?** → Check E.7 — trace IDs and logged decisions should be your first stop.
