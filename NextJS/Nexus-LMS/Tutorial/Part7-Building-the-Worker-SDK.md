# PART 7 — Worker SDK & External AI Integration Layer

# Tutorial 07: Building the Developer Interface for AI Plug-ins

---

# Introduction

At this stage, Nexus LMS already has:

* an event system (Inngest)
* a worker registry (Sanity)
* a multi-tenant LMS core (Supabase)
* a frontend that emits events

But there is still one missing layer:

> How do external developers safely build AI tools that plug into Nexus LMS?

Right now, workers exist conceptually—but not as a **developer-friendly ecosystem**.

This tutorial solves that by introducing:

> The Nexus Worker SDK — the official way to build AI plug-ins.

---

# Learning Objectives

By the end of this tutorial, you will understand:

* How external developers build AI workers
* How the Worker SDK standardizes integration
* How secure communication between LMS and workers works
* How to support Python, Node, and external AI services
* How authentication and request signing works
* How Nexus LMS becomes a true developer platform

---

# 1. Why We Need a Worker SDK

Without an SDK:

* every AI tool is custom-built
* integrations are inconsistent
* security is fragile
* onboarding developers is difficult

With an SDK:

> Every AI tool becomes a standardized plug-in.

---

## Before (fragmented ecosystem)

```text id="bad1"
Markly API (custom)
Tutor API (different format)
Analytics API (different auth)
```

Each system:

* uses different payloads
* uses different authentication
* uses different response formats

---

## After (Nexus Worker SDK)

```text id="good1"
Worker SDK → Standard Interface → LMS
```

All workers:

* follow same contract
* use same auth model
* use same execution format

---

# 2. Worker Runtime Model

Every worker is:

> A stateless execution service triggered by LMS events

```text id="runtime1"
Event → LMS → Worker Registry → Worker → Response
```

---

## Worker execution flow

```text id="runtime2"
1. LMS sends request
2. Worker verifies signature
3. Worker processes payload
4. Worker returns structured output
5. LMS stores result
```

---

# 3. Worker SDK Design

We define a standard SDK interface.

---

## 3.1 Base Worker Interface (TypeScript)

```typescript id="sdk1"
export interface NexusWorker {
  metadata(): {
    name: string;
    version: string;
    events: string[];
  };

  execute(input: WorkerInput): Promise<WorkerOutput>;
}
```

---

## 3.2 Worker Input Contract

```typescript id="sdk2"
export interface WorkerInput {
  event: string;
  timestamp: string;
  data: any;
  context: {
    organizationId: string;
    userId?: string;
  };
}
```

---

## 3.3 Worker Output Contract

```typescript id="sdk3"
export interface WorkerOutput {
  success: boolean;
  data: any;
  meta?: {
    processingTime?: number;
    model?: string;
  };
}
```

---

# 4. Example Worker (Markly)

```typescript id="worker1"
import { NexusWorker } from "@nexus/sdk";

export class MarklyWorker implements NexusWorker {
  metadata() {
    return {
      name: "Markly Grader",
      version: "1.0.0",
      events: ["assignment.submitted"]
    };
  }

  async execute(input) {
    const { submission } = input.data;

    const score = await gradeWithLLM(submission);

    return {
      success: true,
      data: {
        score,
        feedback: "Well structured answer"
      }
    };
  }
}
```

---

# 5. Python Worker SDK (Important for AI Ecosystem)

Because many AI tools are Python-based.

---

## Python SDK Example

```python id="py1"
class NexusWorker:
    def metadata(self):
        return {
            "name": "Python Grader",
            "events": ["assignment.submitted"]
        }

    async def execute(self, input):
        return {
            "success": True,
            "data": {
                "score": 92
            }
        }
```

---

## Python advantage

* supports ML pipelines
* integrates with HuggingFace
* supports local models

---

# 6. Worker Communication Protocol

Workers are not imported.

They are called via HTTP.

---

## Request format

```http id="http1"
POST /run
```

```json id="http2"
{
  "event": "assignment.submitted",
  "data": {
    "submissionId": "123"
  },
  "context": {
    "organizationId": "org_1"
  }
}
```

---

## Response format

```json id="http3"
{
  "success": true,
  "data": {
    "score": 87,
    "feedback": "Good work"
  }
}
```

---

# 7. Security Model (Critical)

We must secure worker execution.

---

## 7.1 HMAC Signing

Each request is signed:

```text id="sec1"
X-Nexus-Signature: sha256=...
```

---

## 7.2 Worker verifies signature

```typescript id="sec2"
function verifySignature(payload, signature) {
  return hmac(payload) === signature;
}
```

---

## 7.3 Prevents:

* spoofed requests
* unauthorized execution
* data injection attacks

---

# 8. Worker Registration Flow

To register a worker:

---

## Step 1 — Deploy worker service

Example:

```text id="reg1"
https://markly-worker.com/run
```

---

## Step 2 — Add to Sanity registry

```json id="reg2"
{
  "name": "Markly",
  "endpoint": "https://markly-worker.com/run",
  "events": ["assignment.submitted"],
  "enabled": true
}
```

---

## Step 3 — LMS automatically discovers it

No LMS code changes required.

---

# 9. Local Development Mode

Developers need a local testing system.

---

## CLI tool

```bash id="cli1"
nexus worker dev
```

Simulates:

```text id="cli2"
assignment.submitted → worker execution
```

---

## Test payload

```json id="cli3"
{
  "event": "assignment.submitted",
  "data": {
    "submissionId": "test_123"
  }
}
```

---

# 10. Worker Marketplace Foundation

Now we unlock a major concept:

> LMS becomes a platform, not a product.

---

## Possible ecosystem:

* grading AI tools
* tutoring agents
* plagiarism detectors
* analytics engines
* exam proctors

All plug in via SDK.

---

## Example ecosystem

```text id="eco1"
Nexus Marketplace
   |
   +-- Markly (grading)
   +-- TutorAI
   +-- ExamGuard
   +-- InsightAI
```

---

# 11. Why This Architecture Works

## 11.1 Developer-friendly

Any developer can build a worker in:

* Node.js
* Python
* Go
* any HTTP service

---

## 11.2 Fully decoupled

Workers do not depend on LMS internals.

---

## 11.3 Secure by design

* signed requests
* isolated execution
* stateless workers

---

## 11.4 Scalable ecosystem

Workers scale independently.

---

## 11.5 Enables AI marketplace

This is the foundation of:

> “App Store for Education AI”

---

# 12. Key Architectural Principle

> The LMS does not integrate with AI tools.
>
> AI tools integrate with the LMS.

---

# Summary

In this tutorial, we built the Worker SDK layer:

* standardized worker interface (TypeScript + Python)
* execution contract model
* HTTP-based worker runtime
* secure HMAC signing system
* local development tooling
* worker registration pipeline
* foundation for AI marketplace ecosystem

We now have a **fully extensible AI plug-in platform**.

---

# Next Tutorial

## Tutorial 08 — Inngest Deep Dive: Fan-Out, Fan-In, and AI Workflow Composition

We will now design:

* advanced orchestration patterns
* parallel AI execution strategies
* result aggregation systems
* conditional workflows
* adaptive learning pipelines
* retry + compensation flows
* production-grade AI workflow design patterns
