# 🧩 APPENDIX B — PLUGIN CONTRACT SPECIFICATION (AI WORKER STANDARD)

---

# 🧠 B.1 — Purpose of This Appendix

This appendix defines the **official interface contract** for all AI workers in Nexus LMS.

It answers one critical question:

> “What does it mean for something to be a valid AI plugin?”

Without this, the system becomes a loose collection of endpoints.

With this, it becomes a **true plugin ecosystem**.

---

# 🧩 B.2 — Core Concept: Workers Are Products, Not Code

In Nexus LMS:

* A worker is not a function
* A worker is not a file
* A worker is a **declared capability**

Defined in:

Sanity

---

# 🧠 B.3 — Canonical Plugin Contract

Every AI worker MUST conform to this schema:

```json id="b3_contract"
{
  "id": "string",
  "name": "string",
  "description": "string",

  "event": "string",

  "version": "string",

  "enabled": true,

  "priority": 1,

  "inputSchema": {
    "type": "object",
    "required": [],
    "properties": {}
  },

  "outputSchema": {
    "type": "object",
    "properties": {}
  },

  "execution": {
    "type": "http",
    "endpoint": "https://..."
  }
}
```

---

# 🧠 B.4 — Field-by-Field Meaning

---

## 🔹 id

Unique identifier of the plugin.

Example:

```text id="b4_id"
ai-grader-v1
```

---

## 🔹 event

Defines WHEN the worker triggers.

Examples:

```text id="b4_event"
assignment.submitted
lesson.completed
quiz.finished
```

---

## 🔹 version

Supports evolution without breaking system:

```text id="b4_version"
v1.0
v1.1
v2.0 (LLM upgrade)
```

---

## 🔹 priority

Controls execution order:

```text id="b4_priority"
1 = critical (grading)
2 = enhancement (feedback)
3 = analytics
```

---

# 🧠 B.5 — Input Schema Contract

Defines what the worker receives.

Example:

```json id="b5_input"
{
  "type": "object",
  "required": ["content", "assignmentId"],
  "properties": {
    "content": {
      "type": "string"
    },
    "assignmentId": {
      "type": "string"
    }
  }
}
```

---

## 🧠 RULE:

If input does not match schema:

> worker MUST NOT execute

---

# 🧠 B.6 — Output Schema Contract

Defines expected output structure.

Example:

```json id="b6_output"
{
  "type": "object",
  "properties": {
    "score": { "type": "number" },
    "feedback": { "type": "string" }
  }
}
```

---

## 🧠 RULE:

All outputs must be:

* deterministic OR structured
* JSON-safe
* stored in Supabase

---

# 🧠 B.7 — Execution Model

Workers follow this lifecycle:

```text id="b7_flow"
Event received
   ↓
Validate inputSchema
   ↓
Call endpoint (HTTP / AI / external system)
   ↓
Validate outputSchema
   ↓
Return structured result
   ↓
Log to observability layer
```

---

# 🧩 B.8 — Execution Types

Nexus supports multiple worker types:

---

## 1. HTTP Worker (default)

```text id="b8_http"
Next.js API route / external service
```

---

## 2. External AI Worker

Example:

OpenAI

Used for:

* grading
* summarization
* tutoring
* feedback generation

---

## 3. Python Worker (Advanced)

Example:

FastAPI

Used for:

* ML models
* evaluation pipelines
* scientific scoring systems

---

# 🧠 B.9 — Plugin Lifecycle

A plugin goes through:

---

## 1. Registration

Stored in Sanity:

* declared
* validated
* enabled

---

## 2. Discovery

System queries:

```text id="b9_discovery"
event → worker list
```

---

## 3. Execution

Fanout engine runs workers.

---

## 4. Observation

All execution is logged:

* input
* output
* latency
* errors

---

## 5. Evolution

Plugins can be updated via:

* version bump
* endpoint swap
* schema update

---

# 🧠 B.10 — Critical Design Rules

---

## ❗ Rule 1 — No Hidden Behavior

A worker must never:

* mutate unrelated state
* trigger silent side effects
* bypass schema validation

---

## ❗ Rule 2 — Idempotency Required

Same event → same result (logically)

---

## ❗ Rule 3 — Stateless Execution

Workers must not rely on memory.

All state lives in:

Supabase

---

## ❗ Rule 4 — Failure Transparency

If a worker fails:

* it must be logged
* it must not crash the system

---

# 🧠 B.11 — Why This Contract Matters

This contract enables:

---

## 1. AI Marketplace Model

Any developer can build:

* grading AI
* tutoring AI
* analytics AI

and plug it in.

---

## 2. Multi-Agent AI Systems

One event can trigger:

* multiple AI perspectives
* competing models
* ensemble reasoning

---

## 3. Enterprise Extensibility

Organizations can:

* replace AI engines
* version their logic
* audit every decision

---

# 🧠 FINAL INSIGHT

> The plugin contract is what turns Nexus LMS into a platform.

Without it:

* system = app

With it:

* system = ecosystem

---

If you want next, Appendix C will define something even more critical:

# 🧩 “Event Lifecycle Model (Guarantees, Retries, and Idempotency Rules)”

This is where we make the system **production-safe under failure conditions**.
