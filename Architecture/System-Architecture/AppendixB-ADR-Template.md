# Appendix B: Decision Record Template

Copy this file to `docs/adr/template.md` in the project root of any new system. When starting a new ADR, copy the template to a new sequentially-numbered file (e.g., `docs/adr/0010-title-in-kebab-case.md`) and fill in every section — do not leave sections blank; write "N/A" explicitly if a section truly doesn't apply, so future readers know it was considered, not skipped.

## The Template

```markdown
# ADR-NNNN: <Short, Descriptive Title in Imperative Mood>

## Status
<One of: Proposed | Accepted | Rejected | Superseded by ADR-NNNN | Deprecated>

## Context
<What is the issue we're facing? What forces are at play (technical,
business, team, timeline)? Describe the problem neutrally — this
section should be understandable by someone with no prior context,
and should NOT yet reveal which option was chosen.>

## Decision
<State the decision clearly, in one or two sentences, in active voice:
"We will..." Avoid hedging language here — the Context section is
where nuance lives; the Decision section should be unambiguous.>

## Alternatives Considered
<List every option seriously considered, including the one chosen
(numbered, chosen option clearly marked). For each REJECTED option,
state the specific reason it was rejected — not just "didn't fit,"
but the concrete trade-off that tipped the decision.>

1. <Option A> — Rejected: <specific reason>
2. <Option B> — Rejected: <specific reason>
3. <Option C (chosen)> — <one-line justification>

## Consequences
<What becomes easier? What becomes harder? Be honest about the
negative consequences — an ADR that only lists benefits is not
trustworthy and won't help anyone later evaluate whether the
trade-off still holds.>

- Positive: <...>
- Negative: <...>
- Revisit trigger: <the SPECIFIC, ideally measurable condition under
  which this decision should be reconsidered — e.g., "if X exceeds Y,"
  "if team size grows beyond Z," "if consumer telemetry shows W.">

## Date
<YYYY-MM-DD>

## Author(s)
<Name(s) or team>
```

## Field-by-Field Guidance

**Status field discipline:** never delete or silently rewrite an old ADR's Decision when circumstances change. Instead:
1. Write a brand-new ADR with the next sequential number
2. In the new ADR's Context, explicitly reference the old ADR number and explain what changed
3. Go back and edit *only* the old ADR's Status line to `Superseded by ADR-NNNN` — leave everything else in the old ADR untouched, as a historical record

**Revisit trigger is the most-skipped, most-valuable field.** Without it, ADRs age into either (a) being blindly followed forever regardless of changed circumstances, or (b) being blindly ignored as "outdated" without evidence that circumstances actually changed. A concrete trigger ("if container.ts exceeds 150 lines," "if p99 latency on this endpoint exceeds 500ms for 2 consecutive weeks") turns a subjective future argument into an objective, checkable condition.

## Minimal Worked Example (Filled In)

```markdown
# ADR-0001: Adopt Clean Architecture Layering for core/

## Status
Accepted

## Context
The system needs business logic (order placement rules, payment
orchestration) that will outlive the current choice of web framework
and database. We need a structural convention that prevents business
rules from becoming entangled with framework-specific code, so the
framework and database can be swapped later without rewriting
business logic.

## Decision
We will structure the codebase using Clean Architecture's concentric
layering: domain -> application -> infrastructure -> frameworks/drivers,
with the Dependency Rule enforced (dependencies only point inward).
Business logic lives in a framework-agnostic core/ directory.

## Alternatives Considered
1. Framework-first structure (organize by Next.js conventions only,
   e.g., all logic directly in Server Actions/Route Handlers) —
   Rejected: ties business rules directly to Next.js API shapes,
   making a future framework migration require re-deriving business
   logic from scattered handler code.
2. Full hexagonal architecture with explicit adapters directory from
   day one for every possible port — Rejected as premature for MVP
   scale; we adopt the layering principle now, and add explicit
   adapters incrementally as real external dependencies appear (see
   Part 3 of the Architecting Modern Systems series).
3. Clean Architecture layering, feature-first folder organization
   (chosen) — balances the Dependency Rule with Locality of Behavior.

## Consequences
- Positive: business rules are unit-testable without a database,
  browser, or network; framework upgrades and swaps are isolated to
  outer layers.
- Negative: adds initial structural overhead and a learning curve for
  engineers unfamiliar with layered architecture; requires discipline
  in code review to prevent accidental inward leakage of framework
  imports into core/.
- Revisit trigger: if core/ needs to import anything from Next.js or
  a specific database driver to function, that signals a Dependency
  Rule violation requiring immediate refactor, not a reason to abandon
  the pattern.

## Date
2025-01-02

## Author(s)
Platform Architecture Team
```

Use this worked example as the calibration bar for level of detail — every ADR in the project should be at least this specific, especially in the Alternatives and Revisit Trigger sections.

---

