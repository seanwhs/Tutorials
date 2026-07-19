# Phase 4: Enterprise Guardrails & Prompt Injection Blocking

## Phase 4, Part 1: Input-Layer Redaction — Masking PII Before It Reaches the Model

### The Target

We're building a dedicated **redaction module** at `lib/agent/security/piiRedaction.js` that detects and masks common categories of Personally Identifiable Information (PII) — emails, phone numbers, credit-card-like number sequences, and Social Security Number-like patterns — inside any user-supplied text, *before* that text is ever placed into a message sent to a model provider. We'll wire this into our `chat` endpoint as a mandatory first step, and build a small test harness that lets us directly observe exactly what gets redacted and why.

### The Concept

Picture a company's mailroom that receives every incoming letter before it's distributed to any employee's desk. A well-run mailroom doesn't just pass letters straight through — sensitive ones (say, containing someone's account number) get certain details blacked out with a marker before the letter is forwarded onward, especially if that letter is about to be photocopied and filed somewhere with looser access control. That's exactly the role our redaction layer plays: it sits between "raw text the user typed" and "text that becomes part of a permanent, external record" — in our case, a request sent to a third-party AI provider's servers, which may log, cache, or otherwise retain that data according to their own policies, entirely outside our control.

This matters for a very concrete reason: **once you send data to an external API, you generally cannot guarantee what happens to it afterward.** Many providers state they don't use API data for training, but logs for abuse monitoring, debugging, and legal compliance are extremely common and often required by law regardless of a provider's training policy. A responsible system minimizes what sensitive data even leaves your own infrastructure in the first place — the best way to protect data from a third party's potential mishandling is to simply never send it to them at all, when it isn't necessary for the task at hand. If a user says *"my email is jane@example.com, can you help me draft a refund request?"*, the model doesn't actually need the literal email address to help draft a refund request message — it needs to know *that an email address was mentioned*, which a placeholder like `[EMAIL_REDACTED]` communicates perfectly well without ever exposing the real value externally.

We use **regular expressions (regex)** for detection here — a regex is a pattern-matching language for finding text that fits a particular shape (like "some digits, then a dash, then more digits" for a phone number). This is a deliberately blunt but reliable and fast tool: regex won't understand *meaning*, but PII like email addresses and phone numbers already follow very recognizable, describable shapes, making pattern matching a genuinely appropriate technique here, distinct from the *meaning*-based judgment we needed in Phase 3's retrieval quality checks.

### The Implementation

#### Step 1 — The redaction patterns and masking function

**File: `lib/agent/security/piiRedaction.js`**
```js
/**
 * A registry of PII detection patterns. Each entry has a regex and a
 * placeholder label used to replace any match. Kept as a flat, inspectable
 * table (rather than scattered logic) so adding a new PII category later is
 * a one-entry addition, and so this list can be reviewed/audited on its own
 * by a security team without reading through unrelated application code.
 */
const PII_PATTERNS = [
  {
    label: 'EMAIL',
    // Matches standard email address shapes: local-part@domain.tld
    regex: /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g,
  },
  {
    label: 'PHONE',
    // Matches common phone number formats, with optional country code,
    // parentheses, dashes, dots, or spaces as separators.
    regex: /\+?\d{1,3}?[-.\s]?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}\b/g,
  },
  {
    label: 'SSN',
    // Matches US Social Security Number shape: XXX-XX-XXXX
    regex: /\b\d{3}-\d{2}-\d{4}\b/g,
  },
  {
    label: 'CREDIT_CARD',
    // Matches 13-16 digit sequences, optionally separated by spaces or
    // dashes every 4 digits — the common visual grouping of card numbers.
    regex: /\b(?:\d[ -]?){13,16}\b/g,
  },
];

/**
 * Scans input text for every registered PII pattern and replaces each match
 * with a clearly labeled placeholder. Returns both the sanitized text AND a
 * structured audit log of exactly what was found — critical for compliance
 * reporting and for debugging false positives/negatives during development.
 */
export function redactPii(inputText) {
  let sanitized = String(inputText ?? '');
  const detections = [];

  for (const { label, regex } of PII_PATTERNS) {
    // Reset lastIndex explicitly: regex objects with the global flag (`g`)
    // maintain internal state across calls to .test()/.exec(), which can
    // cause subtle, hard-to-diagnose bugs if the same regex object is reused
    // across multiple redactPii() calls without resetting it first.
    regex.lastIndex = 0;

    const matches = sanitized.match(regex);
    if (matches && matches.length > 0) {
      detections.push({ category: label, count: matches.length, samples: matches.slice(0, 3) });
      sanitized = sanitized.replace(regex, `[${label}_REDACTED]`);
    }
  }

  return {
    sanitizedText: sanitized,
    piiDetected: detections.length > 0,
    detections,
  };
}
```

> **Why capture `samples` in the detection log, even though we're about to redact them?** This might look contradictory at first — aren't we trying to avoid exposing PII? The key distinction is *where* this detection log is used: it's meant for your own server-side audit logging and this tutorial's verification steps, never sent onward to the model or returned in the final client-facing response body in a real production deployment. Having the actual matched values available server-side is valuable for compliance auditing (proving exactly what was caught and redacted) and for tuning your regex patterns during development. We'll be careful in Step 3 to only return a redaction *count*, not the raw samples, to the actual API caller.

#### Step 2 — A dedicated test harness to observe redaction behavior directly

**File: `app/api/agent/redaction-test/route.js`**
```js
import { NextResponse } from 'next/server';
import { redactPii } from '@/lib/agent/security/piiRedaction.js';

export async function POST(request) {
  const body = await request.json();
  const inputText = String(body?.text ?? '');

  const result = redactPii(inputText);

  return NextResponse.json(result);
}
```

#### Step 3 — Wire redaction into the stateful chat endpoint

**File: `app/api/agent/chat/route.js`** *(full updated file)*
```js
import { NextResponse } from 'next/server';
import { buildSystemPrompt } from '@/lib/agent/systemPrompt.js';
import { runReactLoop } from '@/lib/agent/reactLoop.js';
import { resolveSessionId } from '@/lib/agent/session.js';
import { getSession, saveSession } from '@/lib/agent/sessionStore.js';
import { recordTurnCost } from '@/lib/agent/cost/costLedger.js';
import { redactPii } from '@/lib/agent/security/piiRedaction.js';

export async function POST(request) {
  try {
    const body = await request.json();
    const rawUserMessage = String(body?.message ?? '').trim();

    if (!rawUserMessage) {
      return NextResponse.json(
        { success: false, error: 'Request body must include a non-empty "message" string.' },
        { status: 400 }
      );
    }

    // GUARDRAIL STEP 1: redact PII from the raw user input BEFORE it ever
    // becomes part of any message array sent to a model provider. This runs
    // unconditionally, on every single request, with no opt-out — sensitive
    // data minimization should never depend on the caller remembering to ask for it.
    const { sanitizedText, piiDetected, detections } = redactPii(rawUserMessage);

    if (piiDetected) {
      // Server-side audit log only — never echoed back to the client as raw values.
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

    const { finalAnswer, stopReason, trace, usage, messages: updatedMessages } =
      await runReactLoop(messages);

    saveSession(sessionId, updatedMessages);
    const sessionCostSummary = recordTurnCost(sessionId, usage);

    return NextResponse.json({
      success: true,
      sessionId,
      isNewSession,
      finalAnswer,
      stopReason,
      // Surface ONLY the fact that redaction occurred and how many items,
      // never the raw matched values themselves, in the client-facing response.
      securityNotice: piiDetected
        ? { piiRedacted: true, categoriesRedacted: detections.map((d) => d.category) }
        : { piiRedacted: false },
      turnCount: updatedMessages.filter((m) => m.role === 'user' || m.role === 'assistant').length,
      trace,
      thisTurnCost: {
        promptTokens: usage.promptTokens,
        completionTokens: usage.completionTokens,
        totalCostUsd: usage.totalCostUsd,
      },
      cumulativeSessionCost: {
        turnCount: sessionCostSummary.turnCount,
        totalCostUsd: sessionCostSummary.totalCostUsd,
      },
    });
  } catch (error) {
    console.error('[chat] Loop failed:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Unknown error' },
      { status: 500 }
    );
  }
}
```

### The Verification

#### Test 1 — Confirm each PII category is detected and masked correctly in isolation

```bash
curl -s -X POST http://localhost:3000/api/agent/redaction-test \
  -H "Content-Type: application/json" \
  -d '{"text": "Hi, my email is jane.doe@example.com and you can call me at (555) 234-9871. My SSN is 123-45-6789."}' \
  | python3 -m json.tool
```

**Expected output:**
```json
{
    "sanitizedText": "Hi, my email is [EMAIL_REDACTED] and you can call me at [PHONE_REDACTED]. My SSN is [SSN_REDACTED].",
    "piiDetected": true,
    "detections": [
        { "category": "EMAIL", "count": 1, "samples": ["jane.doe@example.com"] },
        { "category": "PHONE", "count": 1, "samples": ["(555) 234-9871"] },
        { "category": "SSN", "count": 1, "samples": ["123-45-6789"] }
    ]
}
```

Confirm all three categories were detected independently, and that `sanitizedText` no longer contains any of the original raw values.

Now confirm clean text with no PII passes through completely untouched:

```bash
curl -s -X POST http://localhost:3000/api/agent/redaction-test \
  -H "Content-Type: application/json" \
  -d '{"text": "Can you help me understand the refund policy?"}' \
  | python3 -m json.tool
```

**Expected output:**
```json
{
    "sanitizedText": "Can you help me understand the refund policy?",
    "piiDetected": false,
    "detections": []
}
```

This confirms our patterns are precise enough to avoid false positives on ordinary conversational text — an important check, since overly aggressive regex patterns could otherwise mangle innocent phrases (for example, a poorly-scoped digit pattern might accidentally flag an order number or a date as a phone number).

#### Test 2 — Confirm the credit-card-shaped pattern works, and check for a realistic false-positive edge case

```bash
curl -s -X POST http://localhost:3000/api/agent/redaction-test \
  -H "Content-Type: application/json" \
  -d '{"text": "My card number is 4532 0151 1283 0366, please charge it."}' \
  | python3 -m json.tool
```

**Expected:** `CREDIT_CARD` detected, with the sequence replaced by `[CREDIT_CARD_REDACTED]`.

It's worth deliberately testing a known limitation here too — this is good practice for any regex-based system: confirm what happens with a long order ID that happens to be mostly digits:

```bash
curl -s -X POST http://localhost:3000/api/agent/redaction-test \
  -H "Content-Type: application/json" \
  -d '{"text": "My order reference is 1234567890123."}' \
  | python3 -m json.tool
```

**Expected:** this 13-digit sequence will also get flagged as `CREDIT_CARD` — a legitimate false positive, given our pattern's broad digit-run matching. This is worth explicitly acknowledging rather than hiding: **regex-based PII detection trades some false positives for reliable coverage of the shapes that matter most.** In a real production system, you'd likely narrow the credit-card pattern with a checksum validation step (the **Luhn algorithm**, a standard checksum used by real card numbers) to reduce false positives — we flag this as a worthwhile hardening exercise in the Phase 4 Reference Section, but keep the simpler pattern here to stay focused on the core masking mechanism itself.

#### Test 3 — Confirm redaction is enforced end-to-end through the live chat endpoint

```bash
curl -s -c cookies.txt -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "My email is test.user@company.com — can you confirm you received it, and then tell me the refund policy?"}' \
  | python3 -m json.tool
```

**Expected behavior:**
- `securityNotice.piiRedacted` should be `true`, with `categoriesRedacted` including `"EMAIL"`.
- Critically, inspect `finalAnswer` closely: the agent's response should **not** contain the literal email address `test.user@company.com` anywhere — because the model never actually saw it. If you check your **server terminal logs** (not the API response), you should see the `console.warn` line showing the redaction occurred, confirming the audit trail exists server-side even though the raw value never appears in the client-facing JSON.

Also confirm the agent still correctly answers the *non-sensitive* part of the request (the refund policy question), proving that redaction doesn't break the agent's ability to reason about the rest of a mixed message — only the sensitive substring is altered, everything else passes through normally.

Once all three tests pass — individual PII categories correctly detected and masked, a known regex trade-off explicitly acknowledged and understood, and the full chat pipeline confirmed to never forward raw sensitive data to the model provider — you have a working, verified input-layer redaction system sitting in front of every conversation your agent has, exactly as a responsible enterprise system should.
