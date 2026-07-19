# Phase 6: Parallel Multi-Agent Cascades

## Phase 6, Part 1: Isolating Specializations — Building Focused, Single-Purpose Agents

### The Target

We're stepping back from our single, general-purpose ReAct agent and building three genuinely **specialized agents**, each with a narrow, focused job: an **Architect Agent** (reviews a proposed software design and suggests structural improvements), a **Security Auditor Agent** (reviews the same input specifically for security concerns), and a **Documentation Agent** (produces a clear, plain-English summary of the same input for non-technical stakeholders). Each will be its own small module with its own tightly-scoped system prompt — no tool loop needed for any of them, since their job is focused analysis, not multi-step task execution. This part builds the three agents in isolation; Part 2 will run them concurrently.

### The Concept

Think about how a real engineering organization reviews a significant design proposal before it ships. You don't hand the entire document to one overworked generalist and ask them to simultaneously evaluate the architecture, hunt for security holes, *and* write user-facing documentation, all in one pass, using one undivided train of thought. Real organizations split this across specialists — an architecture reviewer, a security auditor, a technical writer — precisely because **narrow focus produces better judgment.** A security auditor who is *only* thinking about security vulnerabilities, without simultaneously trying to also assess code structure or write friendly documentation, catches more real issues than a generalist splitting attention three ways.

This same principle applies directly to LLM-based agents, and it's the foundational idea of **Phase 6: multi-agent cascades**. Instead of building one increasingly bloated system prompt that tries to teach a single model persona to be an architect, a security expert, *and* a technical writer simultaneously — which tends to produce mediocre, generic results in all three areas, since the model has to hold too many competing concerns in its attention at once — we build three genuinely separate agents, each with its own narrowly-scoped system prompt, its own distinct temperature setting (a security audit benefits from low temperature and rigor; a documentation summary can tolerate slightly more stylistic freedom), and its own single, clear job.

Notice also that none of these three specialized agents needs the full ReAct tool-use loop from Phase 1. Their job isn't "accomplish a multi-step task using tools" — it's "analyze this input thoroughly and produce one well-formed piece of output." This is an important distinction to internalize: **not every agent needs to be a ReAct loop.** A ReAct loop is the right shape when a task requires iterative tool use and self-correction across multiple steps. A single, well-designed, single-shot call with a tightly-scoped prompt and (where appropriate) Zod-validated structured output is the right shape when a task is fundamentally single-purpose analysis — using the heavier looped-reasoning machinery here would just add latency and cost without adding real value.

### The Implementation

#### Step 1 — Shared plumbing: a generic single-shot "specialist call" helper

Since all three specialized agents share the same basic shape (system prompt + user content in, structured response out, with timeout protection), we build one small shared helper rather than triplicating this logic.

**File: `lib/agent/specialists/runSpecialist.js`**
```js
import Groq from 'groq-sdk';
import { completionWithTimeout } from '../timeoutCompletion.js';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || '' });

const MODEL_NAME = 'llama-3.3-70b-versatile';
const SPECIALIST_TIMEOUT_MS = 20000; // specialists may reason over longer input, so allow a bit more time than a single ReAct step

/**
 * A generic single-shot "specialist call" — no tool loop, no multi-step
 * reasoning, just: system prompt + input in, structured JSON out. Every
 * specialized agent in this phase (Architect, Security Auditor, Docs) is
 * built as a thin wrapper around this one shared function, differing only
 * in their system prompt, temperature, and expected output schema.
 */
export async function runSpecialist({ systemPrompt, userContent, temperature, outputSchema, specialistName }) {
  const startedAt = Date.now();

  try {
    const completion = await completionWithTimeout(
      groq,
      {
        model: MODEL_NAME,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userContent },
        ],
        response_format: { type: 'json_object' },
        temperature,
      },
      SPECIALIST_TIMEOUT_MS
    );

    const rawContent = completion.choices[0]?.message?.content ?? '{}';
    const parsed = JSON.parse(rawContent);

    const validation = outputSchema.safeParse(parsed);
    if (!validation.success) {
      return {
        specialistName,
        success: false,
        error: `Output validation failed: ${JSON.stringify(validation.error.flatten().fieldErrors)}`,
        elapsedMs: Date.now() - startedAt,
      };
    }

    return {
      specialistName,
      success: true,
      data: validation.data,
      usage: completion.usage,
      elapsedMs: Date.now() - startedAt,
    };
  } catch (error) {
    // A single specialist failing (timeout, malformed JSON, provider error)
    // must NEVER crash the whole cascade — Part 2 will run several of these
    // concurrently, and one failure should be isolated, not contagious.
    return {
      specialistName,
      success: false,
      error: error.message,
      elapsedMs: Date.now() - startedAt,
    };
  }
}
```

> **Why does this helper return a consistent `{ specialistName, success, ... }` shape, win or lose?** This uniform envelope is what will make Part 2's parallel orchestration clean: when we run three specialists concurrently and collect their results, we want to be able to iterate over an array of results and handle each one identically — checking `.success`, reading `.data` or `.error` — regardless of which specialist produced it or whether it succeeded or failed. A consistent shape here removes the need for special-casing logic later.

#### Step 2 — The Architect Agent

**File: `lib/agent/schemas/architectSchema.js`**
```js
import { z } from 'zod';

export const ArchitectOutputSchema = z.object({
  overallAssessment: z.enum(['solid', 'needs_minor_changes', 'needs_major_rework']),
  strengths: z.array(z.string()).max(5),
  concerns: z.array(z.string()).max(5),
  recommendedNextStep: z.string().min(10).max(300),
});
```

**File: `lib/agent/specialists/architectAgent.js`**
```js
import { runSpecialist } from './runSpecialist.js';
import { ArchitectOutputSchema } from '../schemas/architectSchema.js';

const ARCHITECT_SYSTEM_PROMPT = `
You are a Senior Software Architect reviewing a proposed system design.
Focus ONLY on structural soundness: separation of concerns, scalability,
maintainability, and appropriate use of architectural patterns. Do NOT
comment on security vulnerabilities or documentation quality — those are
handled by other specialists.

Respond with a single JSON object in exactly this shape:
{
  "overallAssessment": "solid" | "needs_minor_changes" | "needs_major_rework",
  "strengths": ["...", "..."],
  "concerns": ["...", "..."],
  "recommendedNextStep": "one specific, actionable next step"
}
`.trim();

export async function runArchitectAgent(designDescription) {
  return runSpecialist({
    specialistName: 'architect',
    systemPrompt: ARCHITECT_SYSTEM_PROMPT,
    userContent: designDescription,
    temperature: 0.2, // structural analysis benefits from consistency over creativity
    outputSchema: ArchitectOutputSchema,
  });
}
```

#### Step 3 — The Security Auditor Agent

**File: `lib/agent/schemas/securitySchema.js`**
```js
import { z } from 'zod';

export const SecurityAuditOutputSchema = z.object({
  riskLevel: z.enum(['low', 'medium', 'high', 'critical']),
  vulnerabilitiesFound: z.array(
    z.object({
      category: z.string().min(1),
      description: z.string().min(5),
      severity: z.enum(['low', 'medium', 'high', 'critical']),
    })
  ),
  recommendedMitigations: z.array(z.string()).max(5),
});
```

**File: `lib/agent/specialists/securityAgent.js`**
```js
import { runSpecialist } from './runSpecialist.js';
import { SecurityAuditOutputSchema } from '../schemas/securitySchema.js';

const SECURITY_SYSTEM_PROMPT = `
You are a Senior Security Auditor reviewing a proposed system design.
Focus ONLY on security concerns: authentication, authorization, data
exposure, injection risks, and unsafe handling of untrusted input. Do NOT
comment on general architecture quality or documentation — those are
handled by other specialists. Be strict and skeptical.

Respond with a single JSON object in exactly this shape:
{
  "riskLevel": "low" | "medium" | "high" | "critical",
  "vulnerabilitiesFound": [
    { "category": "...", "description": "...", "severity": "low" | "medium" | "high" | "critical" }
  ],
  "recommendedMitigations": ["...", "..."]
}
If no vulnerabilities are found, return an empty array for vulnerabilitiesFound and riskLevel "low".
`.trim();

export async function runSecurityAgent(designDescription) {
  return runSpecialist({
    specialistName: 'security',
    systemPrompt: SECURITY_SYSTEM_PROMPT,
    userContent: designDescription,
    temperature: 0.1, // security review demands maximum consistency and rigor, minimal creative variance
    outputSchema: SecurityAuditOutputSchema,
  });
}
```

#### Step 4 — The Documentation Agent

**File: `lib/agent/schemas/docsSchema.js`**
```js
import { z } from 'zod';

export const DocsOutputSchema = z.object({
  plainEnglishSummary: z.string().min(30).max(500),
  keyTakeaways: z.array(z.string()).min(1).max(6),
});
```

**File: `lib/agent/specialists/docsAgent.js`**
```js
import { runSpecialist } from './runSpecialist.js';
import { DocsOutputSchema } from '../schemas/docsSchema.js';

const DOCS_SYSTEM_PROMPT = `
You are a Technical Writer producing a plain-English summary of a proposed
system design for NON-TECHNICAL stakeholders (e.g. product managers,
executives). Focus ONLY on clarity and accessibility — avoid jargon where
possible, and do NOT evaluate architecture quality or security concerns;
those are handled by other specialists.

Respond with a single JSON object in exactly this shape:
{
  "plainEnglishSummary": "a clear paragraph explaining what this system does and why, in plain English",
  "keyTakeaways": ["...", "..."]
}
`.trim();

export async function runDocsAgent(designDescription) {
  return runSpecialist({
    specialistName: 'docs',
    systemPrompt: DOCS_SYSTEM_PROMPT,
    userContent: designDescription,
    temperature: 0.4, // a documentation summary benefits from slightly more natural, varied phrasing than a strict technical audit
    outputSchema: DocsOutputSchema,
  });
}
```

#### Step 5 — A test endpoint to exercise each specialist individually

Before we run these concurrently in Part 2, we need to confirm each one works correctly **in isolation** — exactly the same "verify each piece before combining them" discipline we've followed since Phase 1.

**File: `app/api/agent/specialist-test/route.js`**
```js
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { runArchitectAgent } from '@/lib/agent/specialists/architectAgent.js';
import { runSecurityAgent } from '@/lib/agent/specialists/securityAgent.js';
import { runDocsAgent } from '@/lib/agent/specialists/docsAgent.js';

const RequestSchema = z.object({
  designDescription: z.string().min(10).max(3000),
  which: z.enum(['architect', 'security', 'docs']),
});

const AGENT_RUNNERS = {
  architect: runArchitectAgent,
  security: runSecurityAgent,
  docs: runDocsAgent,
};

export async function POST(request) {
  const rawBody = await request.json().catch(() => null);
  const parsed = RequestSchema.safeParse(rawBody);

  if (!parsed.success) {
    return NextResponse.json(
      { success: false, error: 'Invalid request body', details: parsed.error.flatten().fieldErrors },
      { status: 400 }
    );
  }

  const { designDescription, which } = parsed.data;
  const runner = AGENT_RUNNERS[which];
  const result = await runner(designDescription);

  return NextResponse.json(result);
}
```

### The Verification

Every request from here on needs the `x-api-key` header, per Phase 5's middleware.

#### Test 1 — Confirm the Architect Agent produces valid, focused output

```bash
curl -s -X POST http://localhost:3000/api/agent/specialist-test \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{
    "designDescription": "We plan to store all application state, including user sessions and business logic, inside a single global JavaScript variable shared across every serverless function instance, with no database at all.",
    "which": "architect"
  }' \
  | python3 -m json.tool
```

**Expected output shape** (exact wording varies):
```json
{
    "specialistName": "architect",
    "success": true,
    "data": {
        "overallAssessment": "needs_major_rework",
        "strengths": ["Simple to reason about for a single-instance prototype"],
        "concerns": [
            "Global in-memory state does not persist or share correctly across serverless instances",
            "No durability — data is lost on cold start or restart",
            "No clear separation between session state and business logic"
        ],
        "recommendedNextStep": "Introduce a proper external data store (e.g. a database or managed session store) shared across all function instances."
    },
    "usage": { ... },
    "elapsedMs": 1240
}
```

Confirm `overallAssessment` is a valid enum value and the response focuses purely on structural/architectural concerns — notice it should **not** mention anything about security vulnerabilities or documentation quality, since we explicitly scoped its prompt away from those concerns.

#### Test 2 — Confirm the Security Agent independently flags a different class of concern for the same input

```bash
curl -s -X POST http://localhost:3000/api/agent/specialist-test \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{
    "designDescription": "Our API accepts a raw SQL WHERE clause fragment directly from the user'\''s search box and appends it to our backend query string without any sanitization, in order to give users maximum search flexibility.",
    "which": "security"
  }' \
  | python3 -m json.tool
```

**Expected:** `riskLevel` should be `"critical"` or `"high"`, and `vulnerabilitiesFound` should identify SQL injection specifically. Confirm this response focuses purely on the security dimension — no commentary about documentation clarity or general architecture patterns.

#### Test 3 — Confirm the Docs Agent produces an accessible, jargon-light summary of the same input

```bash
curl -s -X POST http://localhost:3000/api/agent/specialist-test \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{
    "designDescription": "The system uses a message queue to decouple order placement from inventory updates, processing them asynchronously via worker processes that poll the queue.",
    "which": "docs"
  }' \
  | python3 -m json.tool
```

**Expected:** `plainEnglishSummary` should be a readable paragraph a non-technical stakeholder could understand (avoiding terms like "asynchronous" or "polling" without explanation), and `keyTakeaways` should be a short bulleted list. Confirm neither field mentions security risk or architectural critique — purely a clear, friendly summary.

#### Test 4 — Confirm isolated failure handling: a genuinely malformed input doesn't crash the endpoint

```bash
curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST http://localhost:3000/api/agent/specialist-test \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"designDescription": "short", "which": "architect"}'
```
**Expected:** a clean `400` from our Zod request validation (`designDescription` fails the `.min(10)` constraint) — confirming even our specialist test harness benefits from the same input-validation discipline established in Phase 4, rather than letting an under-specified request reach the model at all.

Once all four tests pass, you've built three genuinely independent, narrowly-scoped specialist agents — each producing focused, schema-validated output relevant only to its own domain of expertise, each fully isolated from the others' concerns, and each verified to fail gracefully and predictably on its own. This isolation is exactly what makes them safe and sensible to run **concurrently** against the same input, which is the subject of the next part.
