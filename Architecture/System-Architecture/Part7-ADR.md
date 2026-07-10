# Part 7: Architectural Decision Records (ADRs)

## 1. Why ADRs: Preserving the "Why"

Every part of this series so far has justified decisions in prose — "we chose a Modular Monolith for the MVP," "we chose additive-only API versioning," "we chose manual DI over a framework." Six months from now, a new team member (or future-you) will see the *result* of these decisions in the code but have zero visibility into the *reasoning*, the *alternatives considered*, or the *conditions under which the decision should be revisited*. This is how "we've always done it this way" cargo-cult engineering is born — and it's entirely preventable.

An **Architecture Decision Record (ADR)** is a short, immutable document capturing one significant decision: the context that forced it, the options considered, the choice made, and the consequences accepted. ADRs are **free to produce** (plain Markdown, no tooling required) and belong **in the codebase itself**, versioned alongside the code they describe — never in a separate wiki that silently drifts out of sync.

## 2. What Counts as "ADR-Worthy"?

Not every decision deserves an ADR — that would produce noise, not signal. Write one when a decision:
- Is **expensive to reverse** (e.g., choosing a database, a module boundary, an auth strategy)
- Involves a **genuine trade-off** where a reasonable person could have chosen differently
- Will likely be **questioned later** ("why don't we just use a message queue here?")
- Establishes a **convention** the whole team must follow going forward

Do *not* write an ADR for: variable naming, which utility library to format dates, or anything easily reversible in an afternoon. The Cost of Change lens applies here too — ADR-writing itself has a cost, so reserve it for decisions where that cost is repaid many times over by future clarity.

## 3. ADR Structure (Michael Nygard's Format, the De Facto Free Standard)

```markdown
# ADR-0007: Use Manual Constructor Injection Instead of a DI Framework

## Status
Accepted

## Context
The core/ domain and application layers need external capabilities
(database access, payment processing, event publishing) without
depending on their concrete implementations, per the Dependency Rule
established in ADR-0001. We must choose a mechanism to wire concrete
adapters into use cases at runtime.

## Decision
We will use plain TypeScript constructor injection, wired manually in
a single composition root (infrastructure/container.ts), rather than
adopting a DI framework such as InversifyJS or tsyringe.

## Alternatives Considered
1. InversifyJS — decorator-based DI container.
   Rejected: requires reflect-metadata polyfill, adds a build-time
   dependency, and its runtime resolution makes wiring less
   grep-able/traceable than plain constructor calls.
2. tsyringe — similar decorator-based approach from Microsoft.
   Rejected: same reflect-metadata dependency; team has no existing
   familiarity, adds onboarding cost for a team of our current size.
3. Manual constructor injection (chosen).

## Consequences
- Positive: zero framework lock-in on the DI mechanism; wiring is
  fully visible in one file; works identically in Server Components,
  Server Actions, Route Handlers, and standalone scripts/tests.
- Negative: as the number of adapters grows past ~30-40, manual
  wiring in container.ts may become unwieldy and require reorganizing
  into per-module composition roots.
- Revisit trigger: if container.ts exceeds ~150 lines or onboarding
  friction around manual wiring is reported by 2+ engineers, revisit
  this decision and evaluate a lightweight DI container.

## Date
2025-01-14
```

This maps directly to the reasoning given informally back in Part 3, Section 7 — the difference is that now it's a permanent, discoverable artifact instead of tutorial prose that disappears once you've read it.

## 4. Where ADRs Live and How They're Versioned

```
docs/
  adr/
    0001-clean-architecture-layering.md
    0002-bounded-contexts-for-northwind-orders.md
    0003-modular-monolith-over-microservices-for-mvp.md
    0004-outbox-pattern-for-event-reliability.md
    0005-additive-only-api-versioning-by-default.md
    0006-rest-for-public-reads-rpc-for-internal-actions.md
    0007-manual-di-over-di-framework.md
    template.md          <- see Appendix B for the reusable template
```

**Numbering is sequential and append-only.** ADRs are **never edited to reverse a decision** — instead, a new ADR is written that supersedes the old one, and the old one's Status is updated to `Superseded by ADR-0012`. This preserves the *history* of reasoning, which is often as valuable as the current decision itself — it shows *why* something that seemed reasonable at the time was later found wanting, which prevents the same mistake from being reconsidered blindly in the future.

```markdown
# ADR-0003: Modular Monolith Over Microservices for MVP

## Status
Superseded by ADR-0012 (see: Migrating Inventory to a standalone service)

...
```

## 5. ADRs as Living Governance, Not Bureaucracy

A common failure mode: ADRs get written once during a big design phase and never touched again, becoming as stale as the wiki they were meant to replace. To avoid this:

1. **Require an ADR in the PR that implements the decision** — not after the fact. If a PR introduces a new architectural pattern (a new bounded context, a new external dependency, a new cross-cutting concern), the ADR is part of the same review, so reviewers evaluate the reasoning, not just the diff.
2. **Link ADRs from code comments** at the exact point of implementation:
```ts
// See docs/adr/0007-manual-di-over-di-framework.md for why this
// composition root uses plain constructor injection.
export const placeOrderUseCase = new PlaceOrderUseCase(/* ... */);
```
3. **Review ADRs at major milestones** (e.g., before a significant scale-up, or annually) — mark stale ones as Superseded rather than deleting them.

## 6. Free Tooling for ADR Management

- **adr-tools** (CLI, MIT license) — `adr new "Title"` scaffolds a numbered file from the template automatically
- **log4brains** (OSS) — generates a browsable static site from your `docs/adr/` folder, with search and status filtering, deployable for free on GitHub Pages
- Plain Markdown + `grep`/full-text search — the zero-dependency fallback that always works and requires no tooling adoption at all

See **Appendix A (The Architect's Toolkit)** for setup notes on all three, and **Appendix B** for the copy-paste ADR template used throughout this series.

## 7. Design Exercise

**Step 1:** Write ADR-0008 for the decision made in Part 4: "Use a single physical database with logically separated schemas (no cross-schema FKs) instead of database-per-service." Include at least two alternatives considered.

**Step 2:** Write ADR-0009 for the decision made in Part 6: "Prefer additive-only API evolution over URI versioning by default." Define an explicit "revisit trigger" — what condition would justify introducing `/v2`?

**Step 3:** Identify one decision from Part 5 (Resilience) that you have *not* yet formalized as an ADR, and explain in one sentence why it is or isn't ADR-worthy using the criteria from Section 2.

## 8. Solution & Discussion

**Step 1 key points:** Context = need for context-isolated schemas without the operational overhead of N databases at MVP scale. Alternatives = (a) full database-per-service from day one, rejected as premature operational complexity; (b) fully shared schema with cross-context FKs, rejected as violating bounded context isolation established in Part 2. Consequence/revisit trigger = "if Inventory's read/write load becomes disproportionate and threatens to degrade Ordering's performance on the same physical database, extract Inventory to its own database first, as the schema separation already makes this a low-risk extraction."

**Step 2 key points:** Revisit trigger should be concrete and measurable, e.g., "introduce /v2 only when a change cannot be expressed as an additive field, such as fundamentally restructuring the `lineItems` array shape, and after confirming via telemetry that at least one active consumer would break under an additive-only approach."

**Step 3 discussion:** "Choosing exponential backoff with jitter over fixed-delay retries" is a good example of something that is *reasonable but debatable*, and arguably *is* ADR-worthy because a future engineer might "simplify" it back to fixed-delay retries without understanding the retry-storm risk it was designed to avoid — exactly the kind of decision this section warns is easy to silently regress without a written record.

## Up Next

**Part 8 (The Full System)** assembles every part of this series — Clean Architecture layering, DDD bounded contexts, DI-based decoupling, the Outbox pattern, resilience decorators, API versioning, and the ADR log itself — into one cohesive, runnable Modular Monolith architecture for Northwind Orders.

