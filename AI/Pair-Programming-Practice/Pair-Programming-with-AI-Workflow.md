# 🧠 AI-Native Engineering Workflow

## ⚙️ Full Runtime Kit v1 (Prompt + System Extensions)

This system defines a **closed-loop engineering runtime** for AI-assisted software development.

It formalizes:

* separation of reasoning vs execution
* contract-first development
* event-sourced system memory
* drift detection + circuit breaking
* reproducible architectural governance

---

# 🧱 System Composition (Core Capabilities)

This kit introduces a **governed AI engineering loop** with:

* 📚 Reusable prompt library (system intelligence layer)
* 🧠 OpenCode / Continue.dev role separation (brain vs executor)
* 📜 ADR automation (decision memory layer)
* 📡 Event-sourced runtime logging (audit trail)
* 🔁 Safe refactor protocols (behavioral invariance)
* 🧭 System-wide constraint enforcement (governance layer)
* ⚠️ Drift detection + circuit breaker (stability layer)

---

# 📁 1. `/docs/prompts.md`

## 🧠 Canonical Prompt Library (Execution Interface Layer)

This file is the **primary control surface** for AI agents.

It defines how the system reasons, validates, and executes work.

---

# 🧠 OpenCode — System Reasoning Layer (Brain Kernel)

OpenCode is responsible for:

* system reasoning
* architectural validation
* risk analysis
* contract definition
* drift detection

It NEVER writes production code.

---

## 1. System Reconstruction Prompt (State Load)

> Reconstruct full system state as a deterministic model.

### Inputs:

* `/docs/requirements.md`
* `/docs/adr/*`
* `/docs/history/system-history.md`
* `/docs/constraints/active_constraints.md`

### Output:

* Active constraints (truth layer)
* Architectural decisions in effect (ADR delta)
* System risks (categorized by severity)
* Hidden inconsistencies (non-obvious coupling)
* Assumption drift (diff vs baseline)

---

## 2. Contract Generator (Interface Definition Layer)

> Define a strict execution contract for `{FEATURE}`

### Must include:

* Inputs / Outputs (typed where possible)
* Data model (canonical schema)
* Invariants (system truths)
* Side effects (explicitly enumerated)
* Failure modes (expected + edge cases)
* Security constraints (threat model summary)
* Idempotency rules (retry safety model)

**Rule:** No implementation is valid without a contract.

---

## 3. Adversarial Review (Pre-Mortem Simulation)

> Assume system is operating at production scale under load.

Evaluate:

* concurrency failure modes
* race conditions
* data corruption vectors
* authentication/authorization flaws
* dependency fragility (external systems)

### Output format:

* Issue
* Severity (LOW / MEDIUM / HIGH / CRITICAL)
* Failure scenario
* Blast radius

---

## 4. Architecture Drift Detection (Consistency Engine)

> Compare system truth layers:

* Current implementation
* ADR baseline (ADR-001 + deltas)
* requirements.md

### Output:

* Drift points (explicit mismatches)
* Broken invariants
* Missing or violated assumptions
* Architectural entropy hotspots

---

# ⚙️ Continue.dev — Execution Kernel (Actuator Layer)

Continue.dev is responsible for:

* code generation
* file modification
* refactoring
* migrations
* test implementation

It NEVER defines system architecture.

---

## 5. Feature Implementation Prompt

> Implement `{FEATURE}` under strict system governance.

### Constraints:

* must follow ADR decisions
* must respect active constraints
* must preserve system invariants
* must follow existing code patterns
* must be idempotent where applicable

### Output:

* DB migrations (if needed)
* API routes (Next.js App Router)
* validation layer (Zod or equivalent)
* minimal test coverage (behavioral validation)

---

## 6. Safe Refactor Prompt (Behavior Preservation Mode)

> Refactor `{MODULE}` WITHOUT altering external behavior.

### Hard constraints:

* no API surface changes
* no schema changes
* no behavioral drift

### Allowed transformations:

* decomposition
* renaming
* modularization
* coupling reduction
* readability improvements

### Output:

* diff summary (semantic, not just line-level)
* modified files only
* risk assessment (if any hidden coupling exists)

---

## 7. Debugging Prompt (Fault Isolation Model)

> Analyze failure in `{FEATURE}` as a system-level fault.

### Output:

* Root cause hypothesis (ranked)
* Affected layer:

  * UI / API / DB / Event / Infra
* Minimal fix plan (lowest blast radius)
* Regression risk analysis

---

# 📡 2. Event-Sourced Memory System

## `/docs/events/schema.json`

The system is **event-driven and append-only in audit structure**.

```json
{
  "event": {
    "id": "string",
    "type": "CONTEXT_LOADED | CONTRACT_DEFINED | IMPLEMENTATION_APPLIED | VALIDATION_FAILED | MEMORY_UPDATED | CIRCUIT_BROKEN",
    "timestamp": "ISO-8601",
    "actor": "OpenCode | Continue | Human | CI | Observer",
    "feature": "string",
    "payload": {},
    "severity": "LOW | MEDIUM | HIGH | CRITICAL"
  }
}
```

---

## 🔁 Canonical Event Lifecycle

```text
CONTEXT_LOADED
→ CONTRACT_DEFINED
→ ADVERSARIAL_REVIEW_EXECUTED
→ IMPLEMENTATION_APPLIED
→ VALIDATION_EXECUTED
→ MEMORY_UPDATED
→ (optional) CIRCUIT_BROKEN
```

---

# 🧠 3. Observer Agent (System Integrity Engine)

The Observer is not an agent.

It is a **continuous evaluation function over system state**.

---

## 🧮 Drift Equation (Conceptual Model)

```text
Entropy =
  divergence(ADR, Implementation)
+ divergence(Requirements, Code)
+ unresolved HIGH severity risks
```

---

## 🚨 Circuit Breaker Trigger

```pseudo
if Entropy > threshold:
    trigger CIRCUIT_BREAKER
```

---

## 🔒 Circuit Breaker Behavior

When triggered:

* pause all Continue.dev execution
* freeze write operations
* force OpenCode reconstruction
* require human approval for resumption
* re-establish system baseline

---

# 🧱 4. Refactor Safety Protocol (State Transition Model)

Refactoring is treated as a **controlled state transition**, not code editing.

---

## Phase 1 — System Analysis (OpenCode)

* dependency graph of `{MODULE}`
* coupling map
* hidden side effects
* invariants potentially at risk

---

## Phase 2 — Contract Freeze

Lock:

* API surface
* DB schema
* event contracts
* external integrations

---

## Phase 3 — Execution (Continue.dev)

Allowed only:

* internal restructuring
* decomposition
* abstraction improvements

Forbidden:

* behavior changes
* interface changes

---

## Phase 4 — Validation Gate

System is valid only if:

* tests pass
* invariants preserved
* no behavioral deviation detected

---

# 🧾 5. ADR System (Decision Memory Layer)

Stored in:

```text
/docs/adr/ADR-{NNN}.md
```

---

## ADR Structure (Canonical)

```md
# ADR-{NNN}: {Title}

## Context
System condition that triggered decision

## Decision
Chosen architectural path

## Alternatives
- Option A
- Option B

## Consequences
### Positive
### Negative

## Risks
- enumerated risks

## Mitigation Strategy
- controls and safeguards

## System Impact
- affected modules
- changed invariants
```

---

## 🧠 ADR Principle

> ADRs are immutable system truth once created.

They are **higher priority than implementation**.

---

# 🔁 6. System Evolution Rules (Global Invariants)

These rules define **runtime correctness constraints**.

---

## Rule 1 — Contract First Enforcement

No contract → no implementation.

---

## Rule 2 — ADR Compliance Gate

If ADR conflict exists → execution is blocked.

---

## Rule 3 — Context Load Requirement

No OpenCode reconstruction → system state is invalid.

---

## Rule 4 — Validation Supremacy

Failing tests override all perceived success.

System state = invalid until resolved.

---

## Rule 5 — Memory Consistency Requirement

Every change must update:

```text
/docs/history/system-history.md
```

Failure = incomplete system state.

---

# 🧠 7. Unified Runtime Model (Execution Architecture)

```text
Human (Intent / Authority Layer)
        ↓
OpenCode (Reasoning Kernel / System Brain)
        ↓
Contract Layer (Interface Specification)
        ↓
Continue.dev (Execution Kernel / Actuator)
        ↓
Validation Layer (Truth Enforcement)
        ↓
Git + Docs (Persistent Memory Layer)
        ↓
Observer (Entropy + Drift Controller)
        ↓
Circuit Breaker (Safety Interlock)
        ↓
Human (Approval / Oversight)
```

---

# 🚀 8. System Characteristics (What This Becomes)

This is no longer a workflow.

It is a:

## 🧠 AI-Native Engineering Operating System

With:

* deterministic execution rules
* explicit role separation
* event-sourced architecture memory
* architectural drift detection
* controlled refactor transitions
* runtime safety interlocks

---

# ⚠️ Key Upgrade Over Original System

### Before:

* structured prompt toolkit
* manual discipline required

### Now:

* **governed execution runtime**
* **state machine for engineering decisions**
* **entropy-controlled AI development system**

Just tell me which direction you want.
