# Phase 6, Part 3: Shared Cross-Agent Storage — Building a Simple Event Bus

## The Target

Our three specialists in Part 2 all ran independently against the *same* raw input, with no awareness of each other. In this part, we build a scenario where agents genuinely need to **hand off information to one another**: a **Triage Agent** that reads an incoming support request and decides which specialist(s) should handle it, followed by a **coordinator** that runs the chosen specialists and lets a final **Synthesizer Agent** combine their outputs into one coherent response — using a simple, structured **event bus** (`lib/agent/eventBus.js`) as the shared mechanism through which each stage publishes its findings for the next stage to consume.

## The Concept

Picture a hospital emergency room. A patient doesn't walk in and simultaneously see every specialist in the building at once — a triage nurse first assesses the situation and decides which specialists are actually relevant (a broken arm doesn't need a cardiologist), those specialists then examine the patient and each write their findings into the patient's **shared chart**, and finally the attending physician reads that shared chart — not by re-examining the patient personally with each specialist standing over their shoulder, but by reading the structured notes each specialist already left behind — to produce one unified treatment plan.

That shared chart is the essence of an **event bus** (also sometimes called a shared blackboard or message bus in different variations of this pattern): a structured, append-only record that different independent stages write findings into and read prior findings from, without those stages needing any direct reference to or awareness of each other's code. The triage nurse doesn't need to know *how* the cardiologist forms their diagnosis — only that the cardiologist will eventually write a structured entry into the chart that the nurse's own recommendations can build on, and that the attending physician can later read.

This is architecturally significant for multi-agent systems because it avoids a tangled mess of every agent needing to directly call every other agent, passing bespoke data structures between them in an ad-hoc way that gets harder to maintain as you add more agents. Instead, every stage has exactly one relationship: publish structured findings to the shared bus, and/or read prior findings from it. Adding a fourth specialist later means teaching it to publish to the bus in the expected shape — it does not require rewiring how the triage agent or the synthesizer works at all, mirroring the same decoupling discipline from Phase 5's tool registry, now applied to inter-agent communication instead of tool invocation.

## The Implementation

### Step 1 — The event bus itself

**File: `lib/agent/eventBus.js`**
```js
/**
 * A simple, in-memory, per-run event bus. Each "run" (identified by a
 * runId) gets its own isolated list of published events — this is NOT a
 * persistent, cross-request store like our Phase 2 session store; it's
 * scoped to the lifetime of a SINGLE multi-agent cascade request, existing
 * purely to let different stages within that one request hand information
 * to each other cleanly, without direct references between agent modules.
 */
export function createEventBus() {
  const events = [];

  return {
    /**
     * Publishes a structured finding onto the bus. `source` identifies
     * WHICH stage produced this event (e.g. "triage", "security"),
     * `type` describes WHAT KIND of event it is, and `payload` carries
     * the actual structured data.
     */
    publish(source, type, payload) {
      events.push({
        source,
        type,
        payload,
        publishedAt: Date.now(),
      });
    },

    /**
     * Reads back every event published so far, optionally filtered by
     * source and/or type — this is how a later stage (like the
     * Synthesizer) retrieves prior stages' findings without needing any
     * direct reference to the modules that produced them.
     */
    read({ source, type } = {}) {
      return events.filter(
        (e) => (!source || e.source === source) && (!type || e.type === type)
      );
    },

    /**
     * Returns the full, raw event log — useful for debugging and for
     * returning a full audit trail to the API caller.
     */
    getFullLog() {
      return [...events];
    },
  };
}
```

### Step 2 — The Triage Agent: decides which specialists are relevant

Not every incoming request needs all three specialists — a documentation-only question doesn't need a security audit. The Triage Agent's job is purely to decide routing.

**File: `lib/agent/schemas/triageSchema.js`**
```js
import { z } from 'zod';

export const TriageOutputSchema = z.object({
  relevantSpecialists: z.array(z.enum(['architect', 'security', 'docs'])).min(1),
  reasoning: z.string().min(10).max(300),
});
```

**File: `lib/agent/specialists/triageAgent.js`**
```js
import { runSpecialist } from './runSpecialist.js';
import { TriageOutputSchema } from '../schemas/triageSchema.js';

const TRIAGE_SYSTEM_PROMPT = `
You are a Triage Coordinator. Given a description of a proposed system
design or a support request about one, decide which specialists are
actually relevant to review it:
- "architect": structural/architectural concerns
- "security": security vulnerabilities
- "docs": needs a plain-English summary for non-technical stakeholders

Only include a specialist if their expertise is genuinely relevant to this
specific input. Respond with a single JSON object:
{
  "relevantSpecialists": ["architect", "security", "docs"] (a subset, at least one),
  "reasoning": "one short sentence explaining your routing decision"
}
`.trim();

export async function runTriageAgent(designDescription) {
  return runSpecialist({
    specialistName: 'triage',
    systemPrompt: TRIAGE_SYSTEM_PROMPT,
    userContent: designDescription,
    temperature: 0.1, // routing decisions should be consistent and decisive
    outputSchema: TriageOutputSchema,
  });
}
```

### Step 3 — The Synthesizer Agent: reads the bus and produces one unified verdict

**File: `lib/agent/schemas/synthesisSchema.js`**
```js
import { z } from 'zod';

export const SynthesisOutputSchema = z.object({
  unifiedVerdict: z.enum(['approve', 'approve_with_changes', 'reject']),
  executiveSummary: z.string().min(30).max(600),
  priorityActionItems: z.array(z.string()).max(6),
});
```

**File: `lib/agent/specialists/synthesizerAgent.js`**
```js
import { runSpecialist } from './runSpecialist.js';
import { SynthesisOutputSchema } from '../schemas/synthesisSchema.js';

const SYNTHESIZER_SYSTEM_PROMPT = `
You are a Lead Reviewer producing a FINAL, unified verdict by combining the
findings of one or more specialist reviewers (architect, security, docs)
that have already analyzed a proposed design. You will be given their
findings as structured JSON. Combine them into ONE coherent recommendation.

Respond with a single JSON object:
{
  "unifiedVerdict": "approve" | "approve_with_changes" | "reject",
  "executiveSummary": "a clear paragraph combining the key points across all provided specialist findings",
  "priorityActionItems": ["...", "..."]
}

If a specialist flagged critical or high security risk, or recommended
major architectural rework, the verdict must NOT be "approve".
`.trim();

export async function runSynthesizerAgent(specialistFindings) {
  return runSpecialist({
    specialistName: 'synthesizer',
    systemPrompt: SYNTHESIZER_SYSTEM_PROMPT,
    userContent: JSON.stringify(specialistFindings, null, 2),
    temperature: 0.2,
    outputSchema: SynthesisOutputSchema,
  });
}
```

### Step 4 — The full cascade: triage → concurrent specialists → synthesis, wired through the event bus

**File: `app/api/agent/design-cascade/route.js`**
```js
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createEventBus } from '@/lib/agent/eventBus.js';
import { runTriageAgent } from '@/lib/agent/specialists/triageAgent.js';
import { runArchitectAgent } from '@/lib/agent/specialists/architectAgent.js';
import { runSecurityAgent } from '@/lib/agent/specialists/securityAgent.js';
import { runDocsAgent } from '@/lib/agent/specialists/docsAgent.js';
import { runSynthesizerAgent } from '@/lib/agent/specialists/synthesizerAgent.js';

const RequestSchema = z.object({
  designDescription: z.string().min(10).max(3000),
});

// Maps a specialist's routing name to its actual runner function — this
// lookup table is what lets the Triage Agent's dynamic decision (a list
// of strings) drive WHICH functions actually get invoked, without a large
// hardcoded if/else chain.
const SPECIALIST_RUNNERS = {
  architect: runArchitectAgent,
  security: runSecurityAgent,
  docs: runDocsAgent,
};

export async function POST(request) {
  try {
    const rawBody = await request.json().catch(() => null);
    const parsed = RequestSchema.safeParse(rawBody);
    if (!parsed.success) {
      return NextResponse.json(
        { success: false, error: 'Invalid request body', details: parsed.error.flatten().fieldErrors },
        { status: 400 }
      );
    }

    const { designDescription } = parsed.data;
    const bus = createEventBus(); // one fresh, isolated event bus for this single request

    // --- STAGE 1: TRIAGE ------------------------------------------------------
    const triageResult = await runTriageAgent(designDescription);
    bus.publish('triage', 'routing_decision', triageResult);

    if (!triageResult.success) {
      // If triage itself fails, we cannot safely proceed — we don't know
      // which specialists to run. Fail the whole cascade explicitly rather
      // than guessing a default routing.
      return NextResponse.json({
        success: false,
        stage: 'triage',
        error: triageResult.error,
        eventLog: bus.getFullLog(),
      }, { status: 502 });
    }

    const chosenSpecialists = triageResult.data.relevantSpecialists;

    // --- STAGE 2: CONCURRENT SPECIALIST EXECUTION (only the ones triage chose) -
    const specialistPromises = chosenSpecialists.map((name) => {
      const runner = SPECIALIST_RUNNERS[name];
      return runner(designDescription);
    });
    const specialistResults = await Promise.all(specialistPromises);

    // Each specialist publishes its OWN finding onto the shared bus, tagged
    // by its own name — this is the moment analogous to a specialist
    // "writing into the shared chart" from our hospital analogy.
    specialistResults.forEach((result, index) => {
      bus.publish(chosenSpecialists[index], 'specialist_finding', result);
    });

    // --- STAGE 3: SYNTHESIS ----------------------------------------------------
    // The Synthesizer reads EVERYTHING published so far from the bus,
    // rather than receiving hand-passed arguments directly from Stage 2 —
    // this is the key decoupling property: the synthesizer doesn't call
    // the specialists directly, it only reads what they already published.
    const allFindings = bus.read({ type: 'specialist_finding' });
    const synthesisResult = await runSynthesizerAgent(
      allFindings.map((e) => ({ specialist: e.source, finding: e.payload }))
    );
    bus.publish('synthesizer', 'final_verdict', synthesisResult);

    return NextResponse.json({
      success: true,
      triageDecision: triageResult.data,
      specialistResults: Object.fromEntries(
        chosenSpecialists.map((name, i) => [name, specialistResults[i]])
      ),
      finalSynthesis: synthesisResult,
      eventLog: bus.getFullLog(),
    });
  } catch (error) {
    console.error('[design-cascade] Unexpected failure:', error);
    return NextResponse.json({ success: false, error: error.message || 'Unknown error' }, { status: 500 });
  }
}
```

A few points worth highlighting about this final wiring:

- **The Synthesizer never receives `specialistResults` directly as a function argument from Stage 2's code.** It only ever calls `bus.read({ type: 'specialist_finding' })` — meaning the Synthesizer module has zero direct dependency on how or why those findings were produced, only that they exist on the bus in the expected shape. If we later added a fourth specialist, the Synthesizer's own code requires no changes at all — it will simply see one more entry when it reads the bus.
- **`chosenSpecialists.map((name) => SPECIALIST_RUNNERS[name])`** is what lets the Triage Agent's *dynamic, model-generated decision* directly control which specialist functions actually execute — this is a clean, data-driven way to let an LLM's structured output influence real control flow in your application, exactly the same pattern our ReAct loop used to decide which tool to call, just applied here at the level of "which whole agent to invoke" rather than "which tool."
- **`Promise.all()` is still doing exactly what it did in Part 2** — the chosen specialists still all run concurrently, not sequentially — but now the *set* of specialists actually invoked is dynamic, decided per-request by the Triage Agent, rather than a fixed hardcoded trio every time.

## The Verification

### Test 1 — Confirm triage correctly narrows the specialist set for a docs-only question

```bash
curl -s -X POST http://localhost:3000/api/agent/design-cascade \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"designDescription": "We use a message queue to decouple order placement from inventory updates. Can you explain this system in simple terms for our new product manager who has no technical background?"}' \
  | python3 -m json.tool
```

**Expected behavior:** `triageDecision.relevantSpecialists` should contain **only** `["docs"]` (or perhaps `docs` plus one other if the model reasonably judges more context helpful, but should clearly exclude an unnecessary full security audit for a purely explanatory request). `specialistResults` should contain only the entries for the specialists that were actually chosen — confirming we didn't waste time or cost running specialists the triage stage correctly determined were irrelevant.

### Test 2 — Confirm the full cascade runs all three specialists when genuinely warranted, and the synthesizer combines their findings coherently

```bash
curl -s -X POST http://localhost:3000/api/agent/design-cascade \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"designDescription": "Please do a full review of our new checkout system design before we ship it: it stores card numbers in plaintext logs, uses one giant monolithic file, and we also need a summary for our non-technical stakeholders."}' \
  | python3 -m json.tool
```

**Expected behavior:**
- `triageDecision.relevantSpecialists` should include all three: `architect`, `security`, and `docs` — since the request explicitly touches all three domains.
- `specialistResults` should contain three populated entries, each independently produced.
- `finalSynthesis.unifiedVerdict` should be `"reject"` or `"approve_with_changes"` — **never** `"approve"` — since the security agent should have flagged the plaintext card logging as `high` or `critical` risk, and our synthesizer's prompt explicitly instructs it that such findings must block an outright "approve" verdict.
- `finalSynthesis.executiveSummary` should read as a coherent paragraph that draws on **all three** specialists' findings combined — not just one of them repeated — proving the synthesis stage genuinely integrated multiple independent inputs rather than just passing one through.
- `eventLog` should show a chronological sequence: one `routing_decision` event from `triage`, three `specialist_finding` events (one from each specialist), and one final `final_verdict` event from `synthesizer` — a complete, inspectable audit trail of the entire cascade.

### Test 3 — Confirm the event bus is genuinely isolated per request (no cross-contamination between separate cascade runs)

Run two cascade requests back-to-back with very different inputs, and confirm each response's `eventLog` only contains events relevant to *that specific request* — not a mixture of both:

```bash
curl -s -X POST http://localhost:3000/api/agent/design-cascade \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"designDescription": "A simple read-only internal dashboard with no user data and no write operations at all."}' \
  | python3 -m json.tool | grep -A2 '"source"'
```

Confirm the returned `eventLog` entries only reference specialists relevant to *this* request's own triage decision, with no leftover events from the previous, unrelated request — validating that `createEventBus()` truly creates a fresh, isolated bus scoped to each individual HTTP request, rather than an accidentally shared global instance.

Once all three tests pass, you've completed the full multi-agent cascade architecture for this course: a dynamic Triage stage that decides routing, a concurrent execution stage that runs only the relevant specialists via `Promise.all()`, and a Synthesis stage that combines their independently-published findings into one coherent final verdict — all coordinated through a clean, decoupled, per-request event bus that lets every stage communicate without any stage needing direct knowledge of any other stage's internals.
