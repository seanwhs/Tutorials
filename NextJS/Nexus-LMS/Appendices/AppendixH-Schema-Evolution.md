# 🧩 APPENDIX H — SCHEMA EVOLUTION & MIGRATION STRATEGY

# (HOW NEXUS LMS SURVIVES CHANGE OVER TIME)

---

# 🧠 H.1 — Purpose of This Appendix

This appendix defines how Nexus LMS evolves safely over time:

* database schema changes
* plugin contract updates
* AI worker version upgrades
* event format evolution
* backward compatibility rules

In short:

> “How do you change everything without breaking production?”

---

# 🧠 H.2 — Core Principle

Nexus LMS assumes:

> **Change is constant, and backward compatibility is mandatory**

No part of the system is ever truly “final.”

---

# 🧱 H.3 — Layers Affected by Evolution

Schema evolution impacts 5 system layers:

---

## 1. Database Schema

Supabase

* tables evolve
* columns are added/removed
* indexes change

---

## 2. Event Schema

* event payload structure evolves
* new fields added
* old fields deprecated

Handled by:

Inngest

---

## 3. Plugin Schema

Sanity

* worker definitions evolve
* endpoints change
* schema contracts updated

---

## 4. Worker APIs

* internal AI logic changes
* external AI services upgraded
* versioned endpoints introduced

---

## 5. UI Layer

* new fields rendered
* old fields hidden
* fallback UI added

---

# 🧠 H.4 — Versioning Strategy (CORE MODEL)

Everything in Nexus LMS is versioned:

---

## 1. Event Versioning

```text id="h4_event"
assignment.submitted.v1
assignment.submitted.v2
```

---

## Rule:

* old events are never deleted
* new versions are additive

---

## 2. Plugin Versioning

```json id="h4_plugin"
{
  "name": "AI Grader",
  "version": "2.0"
}
```

---

## Rule:

> multiple versions can coexist

---

## 3. API Versioning

```text id="h4_api"
POST /api/workers/grade/v1
POST /api/workers/grade/v2
```

---

# 🧠 H.5 — Migration Strategy Types

---

## 🔁 1. Additive Migration (SAFE)

Example:

* adding new column
* adding new event field

✔ No breaking changes

---

## ⚠️ 2. Transformative Migration

Example:

* changing schema structure
* modifying event payload format

Requires:

* dual-write strategy
* backward compatibility layer

---

## 💥 3. Breaking Migration (AVOID)

Example:

* removing fields
* renaming events without aliasing

Only allowed with version bump.

---

# 🧱 H.6 — Database Migration Model

In Supabase:

Supabase

---

## Strategy:

### Step 1 — Add new field

```sql id="h6_step1"
ALTER TABLE submissions ADD COLUMN score_v2 int;
```

---

### Step 2 — Dual write

* write to old + new field

---

### Step 3 — Migrate reads

* UI gradually switches to new field

---

### Step 4 — Deprecate old field

* remove after full migration

---

# 🧠 H.7 — Event Evolution Strategy

Handled by:

Inngest

---

## Strategy:

### Option A — Versioned events

```text id="h7_v1"
assignment.submitted.v1
assignment.submitted.v2
```

---

### Option B — Schema extension (preferred)

```json id="h7_extension"
{
  "assignmentId": "123",
  "content": "...",
  "metadata": {
    "version": "2"
  }
}
```

---

# 🧠 H.8 — Plugin Evolution Strategy

Managed via:

Sanity

---

## Strategy:

### 1. Parallel versions

```text id="h8_parallel"
AI Grader v1 → active
AI Grader v2 → testing
```

---

### 2. Gradual rollout

* enable v2 for subset of traffic

---

### 3. Full cutover

* disable v1 after validation

---

# 🧠 H.9 — Safe Migration Pattern (3-Step Model)

---

## Step 1 — Extend

* add new structure
* do not remove old

---

## Step 2 — Dual Run

* both old and new systems operate

---

## Step 3 — Switch

* migrate reads to new system

---

# 🧠 H.10 — Backward Compatibility Rules

Nexus LMS enforces:

---

## Rule 1 — Never delete fields immediately

---

## Rule 2 — Never rename events without alias

---

## Rule 3 — Never break worker contracts silently

---

## Rule 4 — Old events must always be processable

---

# 🧠 H.11 — AI Evolution Strategy (CRITICAL)

AI workers evolve independently:

---

## Example:

```text id="h11_ai"
v1 → rule-based grading
v2 → LLM grading
v3 → multimodal grading
```

---

## Strategy:

* keep same input schema
* improve internal logic only
* never break output contract

---

# 🧠 H.12 — Migration Failure Modes

---

## ❌ 1. Partial migration

* some workers use old schema
* others use new schema

Fix:

* enforce version gating

---

## ❌ 2. Event mismatch

* old events not recognized

Fix:

* event alias mapping

---

## ❌ 3. Plugin incompatibility

* worker expects old payload

Fix:

* version pinning in registry

---

# 🧠 H.13 — Long-Term System Stability Model

Nexus LMS remains stable through:

---

## 1. Additive evolution

Nothing breaks immediately

---

## 2. Parallel systems

Old + new coexist

---

## 3. Controlled deprecation

Old systems removed only after validation

---

# 🧠 FINAL INSIGHT

> In Nexus LMS, evolution is not a risk — it is a designed workflow

The system is built so that:

* change is safe
* upgrades are gradual
* rollback is always possible
* history is never lost

---

If you want next, Appendix I will be the final technical deep dive:

# 🧩 “Real LLM Integration Strategy (Replacing Fake AI with Production-Grade Models like GPT / Claude)”

This is where Nexus LMS becomes a **real AI-powered production system instead of a simulated one**.
