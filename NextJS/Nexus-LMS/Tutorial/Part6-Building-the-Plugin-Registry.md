# PART 6 — The Plug-in Registry (Sanity Worker System)

# Tutorial 06: Building the AI Worker Registry Layer

---

# Introduction

Up to this point, Nexus LMS can:

* emit events
* run workflows (Inngest)
* execute AI workers
* store results in Supabase

But one critical piece is still missing:

> How does the system *know which AI tools exist and when to run them?*

This is the role of the **Plug-in Registry**.

Instead of hardcoding integrations like:

```typescript
if (assignment.submitted) runMarkly();
```

We introduce a dynamic system:

```text
Event → Registry → Workers → Execution
```

The registry is the **brain of extensibility**.

---

# Learning Objectives

By the end of this tutorial, you will understand:

* How the Sanity-based worker registry works
* How AI workers are modeled as plug-ins
* How event subscriptions are dynamically resolved
* How input/output contracts enforce safety
* How third-party AI tools integrate without LMS changes
* How Nexus LMS becomes a plug-in marketplace system

---

# 1. Why a Registry Exists

Without a registry:

* integrations are hardcoded
* AI tools are tightly coupled
* system becomes unmaintainable

With a registry:

* AI tools become plug-ins
* LMS becomes a runtime platform
* features are installed, not coded

---

## Before (bad design)

```text
LMS Core → Markly → Tutor AI → Analytics
```

Every new tool requires:

* code change
* redeploy
* regression testing

---

## After (Nexus design)

```text
LMS Core → Registry → Workers (dynamic)
```

No code change required.

---

# 2. Sanity as the Registry Layer

We use Sanity not as CMS—but as:

> A real-time, queryable plug-in registry.

---

# 3. Worker Schema Design

Every AI tool is a **Worker Document**.

---

## Core Worker Schema

```typescript id="w1"
export default {
  name: "worker",
  type: "document",
  fields: [
    {
      name: "name",
      type: "string"
    },
    {
      name: "version",
      type: "string"
    },
    {
      name: "enabled",
      type: "boolean"
    },
    {
      name: "events",
      type: "array",
      of: [{ type: "string" }]
    },
    {
      name: "endpoint",
      type: "url"
    },
    {
      name: "capabilities",
      type: "array",
      of: [{ type: "string" }]
    },
    {
      name: "inputSchema",
      type: "json"
    },
    {
      name: "outputSchema",
      type: "json"
    },
    {
      name: "timeout",
      type: "number"
    }
  ]
};
```

---

# 4. Worker Document Example (Markly)

```json id="w2"
{
  "name": "Markly Grader",
  "version": "1.0.0",
  "enabled": true,
  "events": [
    "assignment.submitted"
  ],
  "endpoint": "https://markly.api/run",
  "capabilities": [
    "grading",
    "rubric-evaluation"
  ],
  "inputSchema": {
    "submissionId": "string",
    "assignmentId": "string"
  },
  "outputSchema": {
    "score": "number",
    "feedback": "string"
  },
  "timeout": 30000
}
```

---

# 5. Event → Worker Mapping Model

The registry answers one question:

> “Which workers should run for this event?”

---

## Query Logic

```typescript id="w3"
export async function findWorkers(eventName: string) {
  return sanity.fetch(`
    *[_type == "worker" &&
      "${eventName}" in events &&
      enabled == true
    ]
  `);
}
```

---

## Example Result

For event:

```text
assignment.submitted
```

Registry returns:

```text
- Markly Grader
- Plagiarism Checker
- Tutor AI
- Analytics Engine
```

---

# 6. Capability-Based Extension (Important Upgrade)

We don’t just match by event.

We also support capabilities.

---

## Example Query

```typescript id="w4"
*[_type == "worker" &&
  "assignment.submitted" in events &&
  "grading" in capabilities
]
```

---

## Why this matters

Now we can:

* replace grading engines without changing LMS
* run multiple graders in parallel
* compare AI models
* support experimentation

---

# 7. Worker Execution Contract

Every worker must obey a strict contract:

```typescript id="w5"
interface WorkerContract {
  execute(input: any): Promise<{
    success: boolean;
    data: any;
  }>;
}
```

But externally (HTTP API), it behaves like:

```text
POST /run
```

---

## Execution Payload

```json id="w6"
{
  "event": "assignment.submitted",
  "data": {
    "submissionId": "123",
    "assignmentId": "456"
  }
}
```

---

# 8. Registry → Execution Flow

```text id="flow1"
Event emitted
     ↓
Inngest triggers workflow
     ↓
Query Sanity registry
     ↓
Fetch enabled workers
     ↓
Call worker endpoints
     ↓
Store results in Supabase
```

---

# 9. Third-Party Worker Integration

This is where Nexus LMS becomes powerful.

A third-party tool (like a Python AI grading system) can register itself:

---

## Example External Worker

```json id="w7"
{
  "name": "External Python Grader",
  "endpoint": "https://python-ai/run",
  "events": ["assignment.submitted"],
  "capabilities": ["grading"],
  "enabled": true
}
```

No LMS code change required.

---

## Even more interesting:

A developer can deploy:

* Flask AI service
* FastAPI grading engine
* Node.js tutor bot
* external LLM pipeline

All plug into LMS instantly.

---

# 10. Versioning Strategy

Workers evolve independently.

```text
Markly v1 → Markly v2 → Markly v3
```

---

## Schema supports:

```json
{
  "version": "2.0.0"
}
```

We can:

* A/B test workers
* roll back broken AI
* compare models

---

# 11. Safety Layer (Critical for AI Systems)

We enforce:

---

## 11.1 Schema validation

Input must match:

```json
inputSchema
```

---

## 11.2 Output validation

Workers must conform to expected structure.

---

## 11.3 Timeout enforcement

```text
timeout: 30000ms
```

---

## 11.4 Disabled workers are ignored

```json
enabled: false
```

---

# 12. Why This Architecture Works

## 12.1 LMS becomes extensible

No code changes required for new features.

---

## 12.2 AI becomes modular

Each AI system is replaceable.

---

## 12.3 Marketplace model emerges

You can build:

* LMS App Store
* AI Worker Marketplace
* Educational plugin ecosystem

---

## 12.4 Experimentation becomes easy

Run multiple workers per event:

* GPT grader
* Claude grader
* local model grader

Compare outputs.

---

## 12.5 System becomes future-proof

Because:

> LMS logic is decoupled from intelligence logic.

---

# 13. Key Architectural Principle

> The LMS does not know what AI exists.
>
> It only knows what events occurred.

---

# Summary

In this tutorial, we built the plug-in registry system:

* Sanity-based worker registry
* event → worker mapping
* capability-based discovery
* worker execution contracts
* third-party integration model
* versioning strategy for AI tools
* safety validation layer
* foundation for AI marketplace architecture

We now have a **fully dynamic AI plug-in ecosystem**.

---

# Next Tutorial

## Tutorial 07 — Building the Worker SDK (External AI Integration Layer)

We will now design:

* official Worker SDK for third-party developers
* Python + Node worker templates
* secure authentication between LMS and workers
* signing requests (HMAC/JWT)
* local worker testing environment
* deploying AI tools like Markly into the ecosystem
* turning Nexus LMS into a developer platform
