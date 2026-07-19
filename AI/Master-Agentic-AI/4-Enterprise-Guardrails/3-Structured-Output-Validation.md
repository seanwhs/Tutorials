# Phase 4, Part 3: Structured Output Validation with Zod

## The Target

Every guardrail so far has protected the **input** side of our pipeline. This part protects the **output** side. We're going to formalize our request/response contracts using **Zod schemas** — starting with strict validation of the incoming request body (replacing our current manual `String(body?.message ?? '')` checks with a proper schema), and then, more importantly, validating the *shape of the model's own final answer* when we need it to be structured data rather than free text (for example, a future feature where the agent needs to return a machine-readable object, not just a sentence). We'll build this using a concrete, realistic example: a new endpoint that asks the agent to classify and structure a support ticket, and we'll guarantee the response is *always* valid, well-typed JSON — never a string that merely looks like JSON.

## The Concept

Up to this point, whenever we asked the model for JSON (like our `{ thought, action, action_input }` shape in the ReAct loop), we trusted `JSON.parse()` to succeed and then used the resulting object directly, with only informal assumptions about which fields it would contain. That's fine when a slightly malformed field just causes a slightly awkward reasoning step — annoying, but not dangerous. It becomes a real problem the moment that structured output is going to be used for something consequential: populating a database record, triggering a downstream workflow, deciding whether to approve a refund, or being displayed directly in a UI that expects specific fields to always exist.

This is where **Zod** earns its place as more than just "a nice-to-have." Zod lets you define a schema — a precise, executable description of exactly what shape a piece of data *must* have — and then **validate** any candidate data against that schema at runtime, receiving back either a fully-typed, guaranteed-correct object, or a clear, structured description of exactly what didn't match. Think of it like a mechanical parts inspector at a factory: raw JSON parsing is like confirming a delivered part is made of metal and roughly the right size; Zod validation is like measuring it against exact engineering tolerances and rejecting it — with a precise defect report — the instant it deviates, before it's installed into anything downstream that depends on it being exactly right.

Why is this especially important for AI-generated output specifically, as opposed to output from ordinary application code? Because a language model, no matter how well-instructed, is fundamentally a text predictor — it can produce a field with the wrong type (a string where you expected a number), an unexpected extra field, a missing required field, or a value outside an expected enum of choices, all while still technically producing "valid JSON" that `JSON.parse()` happily accepts without complaint. Zod is the layer that catches *semantic* correctness — "this is the right shape and the right types and the right constraints" — which raw `JSON.parse()` can never verify on its own.

We'll also introduce Zod's `safeParse()` method specifically (rather than `parse()`), because it never throws an exception on failure — it returns a result object you check, which fits naturally into our established pattern throughout this course of explicit, checked failure paths rather than relying on `try/catch` for expected, routine validation failures.

## The Implementation

### Step 1 — Define a strict request schema and apply it to the chat endpoint

**File: `lib/agent/schemas/chatRequestSchema.js`**
```js
import { z } from 'zod';

/**
 * Defines the exact, required shape of an incoming chat request body.
 * Using Zod here replaces ad-hoc manual checks (String(body?.message ?? ''))
 * with a single, declarative, reusable definition of what "valid input"
 * actually means — including length constraints that our manual checks
 * never enforced at all until now.
 */
export const ChatRequestSchema = z.object({
  message: z
    .string({ required_error: 'message is required', invalid_type_error: 'message must be a string' })
    .min(1, 'message cannot be empty')
    .max(4000, 'message cannot exceed 4000 characters'), // prevents pathologically huge inputs from reaching the model
});
```

### Step 2 — Apply the request schema in the chat endpoint

**File: `app/api/agent/chat/route.js`** *(relevant section updated — full file shown)*
```js
import { NextResponse } from 'next/server';
import { buildSystemPrompt } from '@/lib/agent/systemPrompt.js';
import { runReactLoop } from '@/lib/agent/reactLoop.js';
import { resolveSessionId } from '@/lib/agent/session.js';
import { getSession, saveSession } from '@/lib/agent/sessionStore.js';
import { recordTurnCost } from '@/lib/agent/cost/costLedger.js';
import { redactPii } from '@/lib/agent/security/piiRedaction.js';
import { detectInjectionAttempt } from '@/lib/agent/security/injectionDetection.js';
import { ChatRequestSchema } from '@/lib/agent/schemas/chatRequestSchema.js';

export async function POST(request) {
  try {
    const rawBody = await request.json().catch(() => null);

    // ZOD VALIDATION: replaces manual ad-hoc checks with a single declarative
    // schema check. safeParse() never throws — it returns a result object we
    // explicitly inspect, matching this course's established pattern of
    // checked, predictable failure paths rather than exception-driven control flow.
    const parsedBody = ChatRequestSchema.safeParse(rawBody);
    if (!parsedBody.success) {
      // .flatten() converts Zod's internal error tree into a simple,
      // API-friendly shape: { fieldErrors: { message: ["..."] } }
      return NextResponse.json(
        { success: false, error: 'Invalid request body', details: parsedBody.error.flatten().fieldErrors },
        { status: 400 }
      );
    }

    const rawUserMessage = parsedBody.data.message.trim();

    const { blocked, violations } = detectInjectionAttempt(rawUserMessage);
    if (blocked) {
      console.warn('[chat] Blocked request due to injection detection:', violations);
      return NextResponse.json(
        { success: false, securityAlert: true, reasons: violations, message: 'This request was blocked due to a detected policy violation.' },
        { status: 403 }
      );
    }

    const { sanitizedText, piiDetected, detections } = redactPii(rawUserMessage);
    if (piiDetected) {
      console.warn('[chat] PII redacted from user input:', detections.map((d) => ({ category: d.category, count: d.count })));
    }

    const { sessionId, isNewSession } = await resolveSessionId();
    const existingMessages = getSession(sessionId);

    let messages;
    if (existingMessages) {
      messages = [...existingMessages, { role: 'user', content: sanitizedText }];
    } else {
      const systemPrompt = await buildSystemPrompt();
      messages = [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: sanitizedText },
      ];
    }

    const { finalAnswer, stopReason, trace, usage, messages: updatedMessages } = await runReactLoop(messages);

    saveSession(sessionId, updatedMessages);
    const sessionCostSummary = recordTurnCost(sessionId, usage);

    return NextResponse.json({
      success: true,
      sessionId,
      isNewSession,
      finalAnswer,
      stopReason,
      securityNotice: piiDetected
        ? { piiRedacted: true, categoriesRedacted: detections.map((d) => d.category) }
        : { piiRedacted: false },
      turnCount: updatedMessages.filter((m) => m.role === 'user' || m.role === 'assistant').length,
      trace,
      thisTurnCost: { promptTokens: usage.promptTokens, completionTokens: usage.completionTokens, totalCostUsd: usage.totalCostUsd },
      cumulativeSessionCost: { turnCount: sessionCostSummary.turnCount, totalCostUsd: sessionCostSummary.totalCostUsd },
    });
  } catch (error) {
    console.error('[chat] Loop failed:', error);
    return NextResponse.json({ success: false, error: error.message || 'Unknown error' }, { status: 500 });
  }
}
```

> **Why `request.json().catch(() => null)` instead of letting a malformed-JSON body throw?** If the client sends a body that isn't valid JSON at all (e.g., empty body, or plain text), `request.json()` throws before we ever reach our Zod validation. Catching that and converting it to `null` lets it flow into `ChatRequestSchema.safeParse(null)`, which fails predictably through our *same* validation error path — one unified "bad request" response shape, instead of two different failure code paths (a JSON-parse crash vs. a schema-validation failure) that a client would have to handle differently.

### Step 3 — A realistic case for validating *model output*: a structured support-ticket classifier

This is the more important half of this part. We'll build a new endpoint that asks the model to classify a support message into a strict, predictable structure — and we will **never** trust its raw output, no matter how well-instructed the prompt is.

**File: `lib/agent/schemas/ticketClassificationSchema.js`**
```js
import { z } from 'zod';

/**
 * Defines the exact, non-negotiable shape the model's classification output
 * must conform to. Using z.enum() for `category` and `priority` is doing a
 * lot of protective work here: even if the model tries to invent a category
 * that isn't in our list (e.g. "miscellaneous" instead of one of our five
 * approved categories), Zod will reject it rather than silently accepting
 * an unrecognized value that downstream code (e.g. a ticket routing system)
 * wouldn't know how to handle.
 */
export const TicketClassificationSchema = z.object({
  category: z.enum(['billing', 'shipping', 'technical', 'account', 'other'], {
    errorMap: () => ({ message: 'category must be one of: billing, shipping, technical, account, other' }),
  }),
  priority: z.enum(['low', 'medium', 'high', 'urgent']),
  summary: z.string().min(10, 'summary must be at least 10 characters').max(200, 'summary must not exceed 200 characters'),
  requiresHumanEscalation: z.boolean(),
});
```

### Step 4 — The ticket classification endpoint, with a validate-and-retry loop

**File: `lib/agent/classifyTicket.js`**
```js
import Groq from 'groq-sdk';
import { completionWithTimeout } from './timeoutCompletion.js';
import { TicketClassificationSchema } from './schemas/ticketClassificationSchema.js';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || '' });

const CLASSIFIER_SYSTEM_PROMPT = `
You are a support ticket classifier. Given a customer message, respond with
a single JSON object with EXACTLY these fields and nothing else:

{
  "category": one of "billing", "shipping", "technical", "account", "other",
  "priority": one of "low", "medium", "high", "urgent",
  "summary": a plain-English summary of the issue, between 10 and 200 characters,
  "requiresHumanEscalation": true or false
}

Return ONLY the JSON object, no extra commentary.
`.trim();

const MAX_CLASSIFICATION_ATTEMPTS = 3;

/**
 * Asks the model to classify a ticket, and STRICTLY validates the result
 * against TicketClassificationSchema. If validation fails — whether from
 * malformed JSON or a schema mismatch (wrong enum value, summary too short,
 * etc.) — we feed the SPECIFIC validation errors back to the model and ask
 * it to correct itself, up to a bounded retry limit. This gives the model
 * a genuine chance to self-correct using concrete, actionable feedback
 * ("priority must be one of...") rather than us silently discarding a
 * near-miss response or crashing the request outright.
 */
export async function classifyTicket(ticketText) {
  const messages = [
    { role: 'system', content: CLASSIFIER_SYSTEM_PROMPT },
    { role: 'user', content: ticketText },
  ];

  for (let attempt = 1; attempt <= MAX_CLASSIFICATION_ATTEMPTS; attempt++) {
    let completion;
    try {
      completion = await completionWithTimeout(
        groq,
        {
          model: 'llama-3.3-70b-versatile',
          messages,
          response_format: { type: 'json_object' },
          temperature: 0.1, // classification should be consistent, not creative
        },
        10000
      );
    } catch (error) {
      return { success: false, error: `Provider call failed: ${error.message}`, attempt };
    }

    const rawContent = completion.choices[0]?.message?.content ?? '{}';

    let candidate;
    try {
      candidate = JSON.parse(rawContent);
    } catch (err) {
      // Malformed JSON entirely — feed this failure back and retry.
      messages.push({ role: 'assistant', content: rawContent });
      messages.push({ role: 'user', content: 'Your response was not valid JSON. Please respond with ONLY a valid JSON object matching the required shape.' });
      continue;
    }

    // THE CRITICAL STEP: validate the parsed candidate against our strict
    // Zod schema. JSON.parse() succeeding only proves it's syntactically
    // valid JSON — it proves NOTHING about whether the fields, types, or
    // allowed values are actually correct. safeParse() is what verifies that.
    const validation = TicketClassificationSchema.safeParse(candidate);

    if (validation.success) {
      // validation.data is now a GUARANTEED-correct, fully-typed object —
      // every field is present, every enum value is one of our approved
      // options, and the summary length constraint is satisfied. Downstream
      // code can trust this object completely, with zero further checking.
      return { success: true, data: validation.data, attempt };
    }

    // Validation failed — extract Zod's structured error details and feed
    // them back to the model as SPECIFIC, actionable correction instructions,
    // rather than a vague "try again" — this meaningfully improves the odds
    // of a successful self-correction on the next attempt.
    const fieldErrors = validation.error.flatten().fieldErrors;
    messages.push({ role: 'assistant', content: rawContent });
    messages.push({
      role: 'user',
      content: `Your JSON had validation errors: ${JSON.stringify(fieldErrors)}. Please correct these specific issues and respond again with ONLY the corrected JSON object.`,
    });
  }

  // Exhausted all retries without producing valid, schema-conformant output.
  // We do NOT return a best-guess, unvalidated object here — that would
  // defeat the entire purpose of this guardrail. We return an honest failure.
  return { success: false, error: `Failed to produce valid classification after ${MAX_CLASSIFICATION_ATTEMPTS} attempts.` };
}
```

**File: `app/api/agent/classify-ticket/route.js`**
```js
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { classifyTicket } from '@/lib/agent/classifyTicket.js';

const RequestSchema = z.object({
  ticketText: z.string().min(1).max(2000),
});

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

    const result = await classifyTicket(parsed.data.ticketText);

    if (!result.success) {
      return NextResponse.json({ success: false, error: result.error }, { status: 502 });
    }

    return NextResponse.json({ success: true, classification: result.data, attemptsNeeded: result.attempt });
  } catch (error) {
    console.error('[classify-ticket] Unexpected failure:', error);
    return NextResponse.json({ success: false, error: error.message || 'Unknown error' }, { status: 500 });
  }
}
```

## The Verification

### Test 1 — Confirm request-body validation rejects malformed input on the chat endpoint

```bash
curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": ""}'
```
**Expected:**
```json
{"success":false,"error":"Invalid request body","details":{"message":["message cannot be empty"]}}
HTTP_STATUS:400
```

```bash
curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"wrongField": "hello"}'
```
**Expected:** a `400` with a `details.message` array indicating the field is required — confirming Zod correctly identifies the *specific* missing field, not just a generic "bad request."

### Test 2 — Confirm valid requests still flow through normally

```bash
curl -s -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is 9 times 9?"}' \
  | python3 -m json.tool
```
Confirm a normal `"success": true` response — proving the new schema layer doesn't interfere with legitimate traffic.

### Test 3 — Confirm the ticket classifier always returns guaranteed-valid structured output

```bash
curl -s -X POST http://localhost:3000/api/agent/classify-ticket \
  -H "Content-Type: application/json" \
  -d '{"ticketText": "I was charged twice for my last order and I need this fixed immediately, this is unacceptable."}' \
  | python3 -m json.tool
```

**Expected output:**
```json
{
    "success": true,
    "classification": {
        "category": "billing",
        "priority": "urgent",
        "summary": "Customer was charged twice for their last order and wants an immediate fix.",
        "requiresHumanEscalation": true
    },
    "attemptsNeeded": 1
}
```

Run this same request several times, and with different ticket texts (a shipping question, a vague technical complaint, a calm account question). In every single run, regardless of wording, confirm:
1. `classification.category` is **always** one of exactly the five approved enum values — never anything else, even if you try oddly-phrased inputs designed to tempt a different category name.
2. `classification.priority` is **always** one of the four approved values.
3. `classification.summary` length is always between 10 and 200 characters.
4. `classification.requiresHumanEscalation` is always a genuine boolean (`true`/`false`), never a string like `"true"`.

Because these guarantees are enforced by Zod rather than merely hoped for via prompt instructions, they hold **even if the underlying model's behavior varies slightly across calls** — which is precisely the point: the schema, not the prompt wording, is what provides the actual guarantee.

Once all three tests pass, you've completed the two-sided guardrail story for this phase: incoming requests are now validated against explicit, declarative schemas rather than informal manual checks, and — more importantly — any model-generated structured output your system depends on is guaranteed, by runtime validation rather than by trust, to match an exact contract before it's ever used downstream.
