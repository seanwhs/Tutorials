# Phase 2, Part 3: Serverless Context Tracking Across Requests

## The Target

Everything we've built so far only has memory *within* a single HTTP request — the moment our Route Handler finishes and sends its response, the `messages` array vanishes from memory completely. If a user asks a follow-up question in a second request, the agent currently has zero recollection of the first conversation. In this part, we build a **session-aware chat endpoint** at `app/api/agent/chat/route.js` that remembers conversation history *across* separate requests, using Next.js 16's async `cookies()` API to identify returning users and a pluggable session store to persist their transcript between calls.

Along the way, we'll also refactor the reasoning loop itself out of the route file and into a shared module — since we now have *two* endpoints (`react` and `chat`) that both need to run the same Think→Act→Observe cycle, just with different message-array setup around it.

## The Concept

Here's the core problem, and it's one of the most important things to understand about serverless architecture: **a serverless function has no memory of its own between invocations.** Picture a conference room that gets completely wiped clean — whiteboard erased, chairs reset, all notes shredded — the instant every single meeting ends, even if the *same* two people are about to walk back in five minutes later for a follow-up discussion. That's exactly what happens to the variables inside your Route Handler; each incoming request may even be served by a genuinely different underlying server instance, so you cannot rely on anything held only in that function's local memory to still be there next time.

The fix is the same one real offices use: **put the notes in a shared filing cabinet in the hallway, outside any single meeting room, that any room can retrieve them from.** In our case, that "filing cabinet" is a **session store** — something that lives outside the lifecycle of any single request. For this part of the course, we implement that store as a simple in-memory `Map`, with an explicit, honest callout that this specific implementation only works correctly on a single running server instance (fine for local development and for understanding the pattern) — and we design its *interface* so that swapping in a real, multi-instance-safe backing store (Redis, a database) later is a one-file change, not an architecture rewrite.

The second piece of this puzzle is: **how do we know which filing folder belongs to which visitor when they come back?** We need a stable identifier that persists across requests from the same browser/client. The standard mechanism for this on the web is a **cookie** — a small piece of data the server asks the browser to store and automatically send back with every future request. We generate a random session ID the first time we see a new visitor, hand it back as a cookie, and then use that same ID to look up their filing folder on every subsequent request.

This is precisely where **Next.js 16's asynchronous request APIs** come in, and it's worth pausing on *why* they changed. In earlier versions of Next.js, functions like `cookies()` and `headers()` returned their values synchronously and immediately. In Next.js 16, these are `async` functions that return **Promises**, which you must `await`. The reasoning behind this shift: modern Next.js increasingly wants to render and prepare as much of a page or response as possible *before* it even knows request-specific details like cookies — treating "give me the cookies" as an explicitly asynchronous operation lets the framework be smarter about what can be computed early versus what must wait for real request data. Practically, for us, this means every place we touch `cookies()` must use `await cookies()`, not a bare synchronous call — forgetting the `await` is one of the most common Next.js 16 migration bugs, so we'll be deliberate and explicit about it here.

## The Implementation

### Step 1 — A pluggable session store abstraction

**File: `lib/agent/sessionStore.js`**
```js
/**
 * A minimal, pluggable session store for conversation history.
 *
 * IMPORTANT PRODUCTION NOTE: this in-memory Map implementation only works
 * correctly when your application runs as a SINGLE server instance (e.g.
 * local development, or `next start` on one machine). In a real serverless
 * deployment, each invocation may run on a different physical instance with
 * its own separate memory — meaning one user's follow-up request could hit
 * an instance that never saw their first message, and this Map would be
 * empty for them. In production, swap this file's internals for a shared
 * external store (e.g. Redis, a database) that every instance can reach —
 * the function signatures below (get/set/delete) are deliberately kept
 * simple so that swap requires touching ONLY this file, nothing that calls it.
 */

const store = new Map();

const SESSION_TTL_MS = 30 * 60 * 1000; // sessions expire after 30 minutes of inactivity

export function getSession(sessionId) {
  const entry = store.get(sessionId);
  if (!entry) return null;

  // Expire stale sessions rather than letting memory grow unbounded forever.
  if (Date.now() - entry.lastAccessedAt > SESSION_TTL_MS) {
    store.delete(sessionId);
    return null;
  }

  return entry.messages;
}

export function saveSession(sessionId, messages) {
  store.set(sessionId, {
    messages,
    lastAccessedAt: Date.now(),
  });
}

export function deleteSession(sessionId) {
  store.delete(sessionId);
}

// Exposed purely for diagnostics/verification in this tutorial — lets us
// confirm from a debug endpoint how many sessions currently exist in memory.
export function getActiveSessionCount() {
  return store.size;
}
```

### Step 2 — Resolving a stable session ID via cookies (the Next.js 16 async API)

**File: `lib/agent/session.js`**
```js
import { cookies } from 'next/headers';

const SESSION_COOKIE_NAME = 'agent_session_id';

/**
 * Resolves the current visitor's session ID from their cookies, creating
 * a brand new one if this is their first request. Also ensures the cookie
 * is (re)written on the response so the browser keeps sending it back.
 *
 * NEXT.JS 16 NOTE: cookies() returns a PROMISE in Next.js 16 — it must be
 * awaited before you can call .get()/.set() on it. This is a deliberate
 * framework change from earlier versions where cookies() was synchronous.
 * Forgetting the `await` here is a common migration mistake — the code
 * would still technically run (JS lets you access properties on a pending
 * Promise without erroring in some cases), but you'd get incorrect,
 * unpredictable behavior instead of the real cookie jar.
 */
export async function resolveSessionId() {
  const cookieStore = await cookies(); // must await — this is a Promise in Next.js 16

  const existing = cookieStore.get(SESSION_COOKIE_NAME);
  if (existing?.value) {
    return { sessionId: existing.value, isNewSession: false };
  }

  // crypto.randomUUID() is a built-in Node.js/Web API — no extra package
  // needed — and produces a cryptographically strong, effectively-unique ID.
  const newSessionId = crypto.randomUUID();

  cookieStore.set(SESSION_COOKIE_NAME, newSessionId, {
    httpOnly: true, // JavaScript in the browser cannot read this cookie — mitigates XSS token theft
    secure: process.env.NODE_ENV === 'production', // only sent over HTTPS in production
    sameSite: 'lax', // sensible default CSRF protection without breaking normal navigation
    maxAge: 60 * 60 * 24 * 7, // 7 days, in seconds
    path: '/',
  });

  return { sessionId: newSessionId, isNewSession: true };
}
```

> **Why `httpOnly: true` matters here:** marking the cookie `httpOnly` means client-side JavaScript running in the user's browser (including any malicious script injected via an XSS vulnerability elsewhere on your site) cannot read this cookie's value at all — only the browser itself can send it back to your server automatically. Since this cookie is purely an internal session pointer and never needs to be read by frontend code, there is no reason to expose it, so we lock it down by default.

### Step 3 — Extract the reasoning loop into a shared, reusable module

Both our original one-shot `react` endpoint and our new stateful `chat` endpoint need to run the exact same Think→Act→Observe cycle — the only difference is how the initial `messages` array is assembled before the loop starts, and what happens to it afterward. Let's pull the loop itself out of the route file.

**File: `lib/agent/reactLoop.js`**
```js
import Groq from 'groq-sdk';
import { completionWithTimeout } from './timeoutCompletion.js';
import { generateFallbackAnswer } from './fallbackAnswer.js';
import { TOOLS } from './tools.js';
import { trimMessagesToBudget } from './tokenBudget.js';
import { createUsageTracker } from './usageTracker.js';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || '',
});

const MAX_STEPS = 6;
const STEP_TIMEOUT_MS = 15000;
const MAX_CONTEXT_TOKENS = 4000;

/**
 * Runs the Think -> Act -> Observe loop starting from an ALREADY-ASSEMBLED
 * messages array (system prompt + full prior history + new user turn already
 * appended by the caller). This function no longer cares whether that
 * history came from a single request (Phase 1 style) or was loaded from a
 * persisted session (this part) — it just keeps reasoning until it stops.
 *
 * Returns the final result AND the full updated messages array, so the
 * caller can persist that array back into session storage if it wants to.
 */
export async function runReactLoop(initialMessages) {
  let messages = [...initialMessages]; // defensive copy — never mutate the caller's array directly

  const trace = [];
  const recentActionSignatures = [];
  const usageTracker = createUsageTracker();

  for (let step = 1; step <= MAX_STEPS; step++) {
    const { trimmedMessages, wasTrimmed, removedCount } = trimMessagesToBudget(
      messages,
      MAX_CONTEXT_TOKENS
    );
    messages = trimmedMessages;
    if (wasTrimmed) {
      trace.push({
        step,
        systemNote: `Trimmed ${removedCount} oldest transcript messages to stay within ${MAX_CONTEXT_TOKENS} token budget.`,
      });
    }

    let completion;
    try {
      completion = await completionWithTimeout(
        groq,
        {
          model: 'llama-3.3-70b-versatile',
          messages,
          response_format: { type: 'json_object' },
          temperature: 0.2,
        },
        STEP_TIMEOUT_MS
      );
    } catch (error) {
      trace.push({ step, error: error.message, code: error.code || 'PROVIDER_ERROR' });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'provider_call_failed');
      messages.push({ role: 'assistant', content: fallbackAnswer });
      return {
        finalAnswer: fallbackAnswer,
        stopReason: 'provider_call_failed',
        trace,
        usage: usageTracker.getSummary(),
        messages,
      };
    }

    usageTracker.record(completion);
    const rawContent = completion.choices[0]?.message?.content ?? '{}';

    let parsed;
    try {
      parsed = JSON.parse(rawContent);
    } catch (err) {
      trace.push({ step, error: 'Model returned invalid JSON', rawContent });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'malformed_json');
      messages.push({ role: 'assistant', content: fallbackAnswer });
      return {
        finalAnswer: fallbackAnswer,
        stopReason: 'malformed_json',
        trace,
        usage: usageTracker.getSummary(),
        messages,
      };
    }

    const { thought, action, action_input } = parsed;
    trace.push({ step, thought, action, action_input });

    if (action === 'final_answer') {
      // Push the model's own final assistant turn into the transcript
      // (as plain text, not the raw JSON) so future turns in this session
      // see a natural conversation history, not internal JSON scaffolding.
      messages.push({ role: 'assistant', content: action_input });
      return {
        finalAnswer: action_input,
        stopReason: 'final_answer',
        trace,
        usage: usageTracker.getSummary(),
        messages,
      };
    }

    const signature = `${action}::${action_input}`;
    recentActionSignatures.push(signature);
    const repeatsOfThisSignature = recentActionSignatures.filter((s) => s === signature).length;
    if (repeatsOfThisSignature >= 2) {
      trace.push({ step, warning: 'Detected repeated action, halting loop early.' });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'stuck_loop_detected');
      messages.push({ role: 'assistant', content: fallbackAnswer });
      return {
        finalAnswer: fallbackAnswer,
        stopReason: 'stuck_loop_detected',
        trace,
        usage: usageTracker.getSummary(),
        messages,
      };
    }

    const tool = TOOLS[action];
    let observation;
    if (!tool) {
      observation = { error: `Unknown tool "${action}". Available tools: ${Object.keys(TOOLS).join(', ')}` };
    } else {
      observation = await tool(action_input);
    }

    messages.push({ role: 'assistant', content: rawContent });
    messages.push({ role: 'user', content: `Observation: ${JSON.stringify(observation)}` });
  }

  trace.push({ warning: `Exceeded MAX_STEPS (${MAX_STEPS}) without reaching final_answer.` });
  const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'max_steps_exceeded');
  messages.push({ role: 'assistant', content: fallbackAnswer });
  return {
    finalAnswer: fallbackAnswer,
    stopReason: 'max_steps_exceeded',
    trace,
    usage: usageTracker.getSummary(),
    messages,
  };
}
```

> **Why push `action_input` (plain text) instead of the raw JSON into `messages` on `final_answer`?** Within a single request, the model benefited from seeing its own prior JSON turns verbatim — that's the format it's reasoning in. But once we start persisting history *across* requests for a natural multi-turn conversation, we want the stored transcript to read like a normal dialogue (`"assistant: 15% of 640 is 96."`) rather than internal scaffolding (`"assistant: {\"thought\":...,\"action\":\"final_answer\"...}"`), since that plain-text version is what actually gets shown to the user across turns and is cheaper (fewer tokens) to carry forward as history.

### Step 4 — Update `app/api/agent/react/route.js` to use the extracted loop

**File: `app/api/agent/react/route.js`** *(full updated file — now much shorter)*
```js
import { NextResponse } from 'next/server';
import { buildSystemPrompt } from '@/lib/agent/systemPrompt.js';
import { runReactLoop } from '@/lib/agent/reactLoop.js';

export async function POST(request) {
  try {
    const body = await request.json();
    const userGoal = String(body?.goal ?? '').trim();

    if (!userGoal) {
      return NextResponse.json(
        { success: false, error: 'Request body must include a non-empty "goal" string.' },
        { status: 400 }
      );
    }

    const systemPrompt = await buildSystemPrompt();
    const initialMessages = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userGoal },
    ];

    const { finalAnswer, stopReason, trace, usage } = await runReactLoop(initialMessages);

    return NextResponse.json({ success: true, goal: userGoal, finalAnswer, stopReason, trace, usage });
  } catch (error) {
    console.error('[react] Loop failed:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Unknown error' },
      { status: 500 }
    );
  }
}
```

### Step 5 — The new stateful chat endpoint

**File: `app/api/agent/chat/route.js`**
```js
import { NextResponse } from 'next/server';
import { buildSystemPrompt } from '@/lib/agent/systemPrompt.js';
import { runReactLoop } from '@/lib/agent/reactLoop.js';
import { resolveSessionId } from '@/lib/agent/session.js';
import { getSession, saveSession } from '@/lib/agent/sessionStore.js';

export async function POST(request) {
  try {
    const body = await request.json();
    const userMessage = String(body?.message ?? '').trim();

    if (!userMessage) {
      return NextResponse.json(
        { success: false, error: 'Request body must include a non-empty "message" string.' },
        { status: 400 }
      );
    }

    // Resolve (or create) this visitor's stable session ID from their cookies.
    const { sessionId, isNewSession } = await resolveSessionId();

    // Look up any prior conversation history for this session ID. Returns
    // null if this is a new session OR if their previous session expired.
    const existingMessages = getSession(sessionId);

    let messages;
    if (existingMessages) {
      // Returning visitor: reuse their full prior transcript, and simply
      // append their new message onto the end of it.
      messages = [...existingMessages, { role: 'user', content: userMessage }];
    } else {
      // Brand new visitor (or expired session): start a fresh transcript.
      const systemPrompt = await buildSystemPrompt();
      messages = [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage },
      ];
    }

    const { finalAnswer, stopReason, trace, usage, messages: updatedMessages } =
      await runReactLoop(messages);

    // Persist the FULL updated transcript (including this turn's exchange)
    // back into the session store, so the NEXT request from this same
    // browser can pick up right where this one left off.
    saveSession(sessionId, updatedMessages);

    return NextResponse.json({
      success: true,
      sessionId,
      isNewSession,
      finalAnswer,
      stopReason,
      turnCount: updatedMessages.filter((m) => m.role === 'user' || m.role === 'assistant').length,
      trace,
      usage,
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

A few details worth pausing on in this handler:

- **We never expose the raw `messages` array in the response.** We return `finalAnswer`, `trace`, and a computed `turnCount` — but the actual transcript stays server-side, inside our session store. This is a small but meaningful security habit: there's no reason for a client to see (or be able to tamper with, if it were ever echoed back and resubmitted) the full internal conversation state.
- **`isNewSession` is surfaced explicitly in the response.** This is useful both for our own verification in a moment, and in a real frontend, to decide whether to show a "Welcome!" greeting versus resuming an existing chat UI.
- **The session cookie is set as a side effect of calling `resolveSessionId()`**, which calls `cookieStore.set(...)` internally. Next.js automatically attaches any cookies set during a Route Handler's execution onto the outgoing `NextResponse` for us — we don't need to manually copy cookie headers onto the response object ourselves.

### Step 6 — A diagnostic endpoint to inspect the session store directly

**File: `app/api/agent/session-debug/route.js`**
```js
import { NextResponse } from 'next/server';
import { getActiveSessionCount } from '@/lib/agent/sessionStore.js';
import { resolveSessionId } from '@/lib/agent/session.js';
import { getSession } from '@/lib/agent/sessionStore.js';

export async function GET() {
  const { sessionId, isNewSession } = await resolveSessionId();
  const messages = getSession(sessionId);

  return NextResponse.json({
    yourSessionId: sessionId,
    isNewSession,
    activeSessionCountAcrossAllUsers: getActiveSessionCount(),
    yourStoredMessageCount: messages ? messages.length : 0,
  });
}
```

## The Verification

### Test 1 — Confirm a session cookie is created and persisted

Because cookies are involved, we need `curl`'s cookie jar feature (`-c` to save cookies, `-b` to send them back) to simulate a real browser's behavior across multiple requests.

**First message (brand new visitor):**
```bash
curl -s -c cookies.txt -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "My favorite number is 27. Remember that."}' \
  | python3 -m json.tool
```

**Expected output:**
```json
{
    "success": true,
    "sessionId": "a1b2c3d4-...",
    "isNewSession": true,
    "finalAnswer": "Got it — I'll remember that your favorite number is 27.",
    "stopReason": "final_answer",
    "turnCount": 2,
    "trace": [ ... ],
    "usage": { ... }
}
```

Confirm `isNewSession` is `true`, and check that a cookie was actually saved:
```bash
cat cookies.txt
```
You should see a line referencing `agent_session_id` with a UUID value.

**Second message (same visitor, using the saved cookie jar with `-b`):**
```bash
curl -s -b cookies.txt -c cookies.txt -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is my favorite number?"}' \
  | python3 -m json.tool
```

**Expected output:**
```json
{
    "success": true,
    "sessionId": "a1b2c3d4-...",
    "isNewSession": false,
    "finalAnswer": "Your favorite number is 27.",
    "stopReason": "final_answer",
    "turnCount": 4,
    ...
}
```

This is the critical proof point: confirm three things —
1. `sessionId` in the second response is **identical** to the first response's `sessionId`.
2. `isNewSession` is now `false`.
3. `finalAnswer` correctly recalls **27** — information that only exists in memory because it was persisted from the *first*, completely separate HTTP request. This is genuine cross-request memory, not a lucky guess or coincidence.

### Test 2 — Confirm session isolation between different visitors

Without using the saved `cookies.txt`, simulate a brand-new visitor:

```bash
curl -s -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is my favorite number?"}' \
  | python3 -m json.tool
```

**Expected behavior:** `isNewSession` should be `true` (a fresh cookie, since we sent none), and `finalAnswer` should indicate the agent has **no idea** what the favorite number is — proving sessions are correctly isolated per visitor, and one user's history never leaks into another's.

### Test 3 — Inspect the store directly

```bash
curl -s -b cookies.txt http://localhost:3000/api/agent/session-debug | python3 -m json.tool
```

**Expected output** — should reflect at least 2 active sessions now (your original test visitor plus the "new visitor" from Test 2), and your specific session should show 4 stored messages (2 user turns + 2 assistant turns) if you're using `cookies.txt`:

```json
{
    "yourSessionId": "a1b2c3d4-...",
    "isNewSession": false,
    "activeSessionCountAcrossAllUsers": 2,
    "yourStoredMessageCount": 5
}
```

*(Note: `yourStoredMessageCount` will be 5, not 4, because it also includes the original system prompt message at index 0.)*

With all three tests passing, you've now built and verified genuine cross-request memory for a serverless application — a non-trivial architectural achievement, given that each request may be handled by an entirely fresh, memory-isolated function invocation. You've also confirmed correct session isolation between different visitors, and you've done all of this using Next.js 16's async `cookies()` API correctly, with proper `await` usage throughout.
