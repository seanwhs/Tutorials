# Master Answer Key — Comprehension Quizzes & Capstone Exam

Every quiz question already included its model answer inline (in the collapsible `<details>` blocks) at the point it was generated. This document exists as a **separate, standalone answer key** — useful if you want to attempt all questions first, across all phases, before checking any answers, or if you want one consolidated reference to review without re-reading each quiz's question framing.

Answers are numbered exactly as they appeared in each phase's quiz.

---

## Phase 1 Answer Key

**A1.** Free-text regex parsing has no enforced contract — the model can phrase its action differently than expected, causing silent misses. `response_format: { type: 'json_object' }` guarantees syntactically valid JSON, making `JSON.parse()` trustworthy rather than "usually works."

**A2.** An agent inventing a different fake tool name every step evades repeated-action detection (signature changes each time) and per-step timeouts (each call completes fine, just wrongly) — only `MAX_STEPS` catches this, since it doesn't care *why* convergence hasn't happened, only *how many tries* occurred.

**A3.** `AbortController` is single-use and tied to one specific operation; the Groq client holds no per-request state and is safe to share. A fresh controller per call guarantees each attempt gets its own independent timeout window.

**A4.** The fallback route only engages *after* the loop stops — it doesn't prevent unbounded execution. Step ceilings and repeated-action detection are what *guarantee* the fallback is reached in bounded time; without them, "deterministic termination" becomes "hopeful termination."

**A5.** A `try/catch` only handles expressions that fail to execute — it does nothing to stop a malicious expression from executing *successfully*. The regex whitelist prevents dangerous input from ever reaching the evaluator at all, regardless of whether it would throw.

**A6.** Standard chat APIs (without native function-calling) only recognize `system`/`user`/`assistant` roles; a custom `"tool"` role would be rejected or misinterpreted. `user` + an `"Observation: "` prefix is the correct fit within that constraint.

---

## Phase 2 Answer Key

**A1.** Without careful per-argument cache keying, one user's cached greeting could be served to every other caller — a real data leak. This is why `buildSystemPrompt()` was safe to cache (zero user-specific data) while a personalized function requires far more caution.

**A2.** Removing a single message could orphan its pair-partner (an observation with no preceding action, or vice versa), confusing the model. Trimming in matched pairs keeps every remaining exchange structurally complete.

**A3.** Without active expiration, the `Map` grows unbounded for the life of the server process — a genuine memory leak. Active TTL-based deletion bounds memory to roughly "currently active conversations only."

**A4.** Next.js 16 treats request-specific data access as an async boundary to enable more caching/optimization. Forgetting `await` means treating a pending Promise as if it were the resolved cookie store — leading to silent, unpredictable failures rather than a clear crash.

**A5.** Yes, achievable with zero changes to `chat/route.js` — the store exposes only three narrow functions (`getSession`/`saveSession`/`deleteSession`), and every caller only ever uses that interface, never the underlying `Map` directly.

**A6.** `httpOnly` blocks any JavaScript (including malicious XSS-injected scripts) from reading the cookie at all. `secure` only protects against network eavesdropping over unencrypted connections — a different threat entirely. Since the cookie never needs frontend access, `httpOnly` closes an attack surface `secure` alone wouldn't.

---

## Phase 3 Answer Key

**A1.** The decision hinges on corpus size, vocabulary overlap, data shape, and update frequency — not on "what tutorials default to." At 40 well-tagged documents, vectorless scoring is faster, cheaper, and more debuggable (via `matchedOn`) without needing embedding infrastructure that only earns its cost at real scale or severe vocabulary mismatch.

**A2.** No infinite loop — `judgeRetrieval()` fails open, defaulting to `sufficient: true` on any internal error, which immediately satisfies the stopping condition. The loop exits after one attempt with possibly lower quality, not endless retries.

**A3.** `lookupOrderStatus` is an exact key-value lookup with no ranking ambiguity — routing it through agentic retrieval adds needless latency/cost, and risks returning the *wrong* order entirely if a fuzzy match scores a different document higher — a real correctness bug, not just an inefficiency.

**A4.** Request A (1,900 prompt + 100 completion) vs. Request B (100 prompt + 1,900 completion) — both total 2,000 tokens, but B costs meaningfully more since output tokens are priced higher per-token than input tokens across virtually every provider. A blended rate would hide this difference entirely.

**A5.** Returning `0` would silently under-report cost (dangerous invisible bug); throwing would crash the whole request over a mere bookkeeping gap. A flagged (`isFallbackEstimate: true`) conservative non-zero rate keeps reporting functional, non-blocking, and transparently marked as an estimate.

**A6.** `response.ok === false` (clean "not found") returns `{ found: false }`; a genuine thrown exception (real service failure) returns `{ error }`. The agent needs to tell users different things in each case — "your tracking number looks wrong" vs. "try again later" — conflating them would misdirect users in at least one scenario.

---

## Phase 4 Answer Key

**A1.** Injection detection runs first and matches `INSTRUCTION_OVERRIDE` immediately, returning a `403` before `redactPii()` is ever called. Cheapest, most decisive checks run first — no reason to redact a message about to be rejected outright.

**A2.** Fail open = proceed as if the check passed when the mechanism itself breaks (retrieval judge — low-stakes risk of a mediocre answer). Fail closed = block by default (injection detector — high-stakes risk of a real security incident). The correct choice is a deliberate, case-by-case risk assessment, never a universal default.

**A3.** Global-flagged regex objects retain `lastIndex` state across calls, which can cause a subsequent call to silently skip matches. Resetting costs nothing today and protects against a future contributor adding a global-flagged pattern without knowing this gotcha.

**A4.** The concern is reasonable in instinct but already addressed: `samples` is server-side-only audit data, never returned to the client (`chat/route.js` only returns counts/categories). Removing it entirely would reduce debugging/compliance value without adding real protection, since protection comes from never externally exposing it.

**A5.** Specific field-level errors tell the model exactly what to fix, meaningfully improving self-correction odds — mirroring Phase 3's judge-feedback pattern. A vague "try again" gives no new information and risks repeating the same mistake.

**A6.** Relaxing the schema on the final attempt would break the exact guarantee this mechanism exists to provide, precisely when it matters most. The retry loop only ever grants more *chances* to meet the bar — never a lower bar — which is why exhausted retries produce an honest failure, not an unvalidated guess.

---

## Phase 5 Answer Key

**A1.** `defineTool()` validates its own arguments at creation time (module load / server startup) and throws immediately and loudly if `description` is missing — the server fails to boot with a clear error, rather than silently registering a tool with a blank description that would confuse the model later in a much harder-to-trace way.

**A2.** Centralized validation in `execute()` guarantees every handler can trust its input completely with zero internal defensive checks. Per-handler validation would vary in quality and could be forgotten entirely for a new tool, silently reintroducing unchecked-input risk.

**A3.** Only `orderLookup.js` (internals) and `orderLookupTool.js` (one `await` keyword) changed. The registry/prompt/loop only ever depend on the tool's external contract (`name`/`description`/`inputSchema`), none of which changed — proof that internal swaps are invisible above the tool boundary.

**A4.** Gating inside the handler would still list the tool in the system prompt, risking the model confidently claiming a cancellation succeeded when it was actually silently refused. Gating at registration time removes the tool from existence entirely from the registry's perspective — no prompt mention, no possible call attempt.

**A5.** Relying on an implicit `undefined !== providedKey` comparison to "happen to" block requests is fragile and easy to break in a future refactor. An explicit check with a loud `500` and `console.error` makes a genuine deployment misconfiguration immediately visible rather than safe only by coincidence.

**A6.** Edge Runtime supports Web APIs but not the full Node.js surface, including many traditional database drivers. Our simple string-comparison auth works fine at the Edge; a real per-customer DB-backed key lookup would need an Edge-compatible client, a separate API-route call, or moving that logic to a Node.js-runtime handler instead.

---

## Phase 6 Answer Key

**A1.** `runSpecialist()`'s internal try/catch guarantees every specialist call always *resolves* (never rejects), neutralizing `Promise.all()`'s "any rejection kills the batch" risk at the unit level rather than by choosing a different combinator.

**A2.** Without that internal safety net, a genuine uncaught exception would reject the whole `Promise.all()`, discarding other successful results. `Promise.allSettled()` would be the safer choice, since it always resolves with per-promise fulfilled/rejected outcomes.

**A3.** Reading from the bus means the Synthesizer has zero dependency on how/why findings were produced — adding a fourth specialist requires zero Synthesizer changes. Direct-argument passing would require modifying the function signature and every call site — a far more brittle coupling.

**A4.** The bus holds genuinely request-scoped data. A shared module-level instance would let concurrent requests' events mix together, causing one user's cascade to see another's findings — an explicitly flagged race-condition risk (R6.3).

**A5.** The triage call's small, fixed cost is paid on every request, but its savings come from the requests that *don't* need all specialists — skipping one or two unnecessary full specialist calls. As long as a meaningful fraction of requests are narrowly scoped, aggregate savings outwelong as a meaningful fraction of real-world requests are narrowly scoped, aggregate savings outweigh the aggregate small overhead of always running triage first.

**A6.** The three specialists aren't disagreeing about the same question — each answers a genuinely different question about the same input, so there's no adversarial tension to stage. A debate pattern earns its complexity only when there's a single, genuinely contested question with legitimate opposing perspectives (e.g., "should we approve this migration this quarter") — forcing debate onto non-competing concerns adds complexity without surfacing anything a simple fan-out doesn't already capture.

---

## Phase 7 Answer Key

**A1.** `429`/`5xx` are typically transient — the same request might succeed on retry. `400` is fundamentally invalid — retrying fails identically every time. Retrying all error types identically would waste the entire retry budget (with growing backoff delays) on requests that were never going to succeed, needlessly delaying the user and consuming provider quota.

**A2.** Without jitter, multiple simultaneously-rate-limited requests (e.g., three concurrent Phase 6 specialist calls hitting a shared limit) would all back off on the identical schedule and retry in lockstep, potentially re-colliding repeatedly. Jitter spreads retries across a slightly different timing window per request, reducing synchronized collisions.

**A3.** Creating a fresh controller per attempt (inside the function `withRetry` calls) ensures each attempt gets its own full, fair `STEP_TIMEOUT_MS` window, rather than a shrinking remainder of one shared outer timeout. The genuinely single, shared `outerSignal` (whole-loop deadline) is layered independently on top, correctly enforcing an aggregate ceiling across all attempts combined.

**A4.** Once the whole-loop deadline has passed, there's no "wait and try again" that makes sense — any further attempt is additional time spent past a ceiling meant to be hard. Retrying here would be actively counterproductive, delaying the user's response even further and defeating the entire purpose of having a hard deadline.

**A5.** `withRetry()` attempts Groq, fails (invalid key); the gateway's chain loop catches this, calls `recordFailure('groq')`, logs the fallthrough, and does *not* throw — proceeding to Gemini, which succeeds and returns the identical normalized shape. The ReAct loop never branches on which provider answered, so the user gets a completely normal response; only `trace.servedBy` reveals Gemini actually handled it.

**A6.** Without the circuit breaker, every new request during a sustained outage would still pay the full retry cost (multiple attempts, growing backoff) before falling through — even though the odds of success are very low given recent history. The circuit breaker operates at a different timescale than retries: it prevents *every subsequent request* from repeatedly re-discovering that the same provider is still down, letting failover happen faster during a sustained outage.

---

## Capstone Exam Answer Key

**Part A.** `issueRefund` should follow the environment-gated write-action pattern (`cancelOrder` precedent), but deserves an *additional* safeguard given it moves real money: a `maxAutoApprovalAmount` threshold, enforced in the handler or via a Zod `.refine()`, routing anything above the threshold to a "requires human approval" response rather than auto-executing. The Zod schema should require `orderId`, a positive bounded `amount`, and a `reason` string with a minimum length, for auditability — directly extending Phase 4's "guarantee validated structure before consequential action" principle to a financial action.

**Part B.** No — this is a business-rule validation concern, not a jailbreak/injection concern. The user isn't manipulating the model's instructions; they're making a request that may violate policy. This belongs inside `issueRefund`'s own handler (mirroring `updateOrderStatus`'s "cannot cancel a delivered order" business rule), not the injection pattern registry. Misclassifying it would pollute the security layer with domain logic it wasn't designed for, and would incorrectly serve a legitimate customer a `403` security rejection instead of an honest ineligibility explanation.

**Part C.** Build `fastllmAdapter.js` exposing the standard `{ messages, temperature, responseFormatJson, signal }` input and returning the exact common shape (`content`, normalized `usage`, `providerName`, `modelName`); translate message shapes if FastLLM's API differs (per the Gemini adapter precedent); ensure `signal` is genuinely forwarded for deadline propagation; add FastLLM's pricing to `pricing.js`; add one entry to `PROVIDER_CHAIN`. Placement should start *last* in the chain, since it's unproven — earning promotion earlier only after a real-world track record of reliability, rather than trusting an unproven provider as primary from day one.

**Part D.** Neither `withRetry()` nor the circuit breaker would catch this, since both key off thrown errors/status codes, and a `200 OK` with malformed JSON looks like a technical success to the HTTP layer. The ReAct loop's existing `JSON.parse()` try/catch *would* eventually catch it (routing to `malformed_json`/fallback), but this happens too late to be attributed back to FastLLM in the circuit breaker's tracking — meaning FastLLM could keep getting selected as "successful" by the gateway. The fix: move JSON-shape validation into the adapter itself, treating malformed output as an adapter-level thrown error so `recordFailure('fastllm')` correctly fires.

**Part E.** `TriageOutputSchema`'s enum needs a `'refund'` value added, with a corresponding system prompt update. But critically: the existing three specialists are all read-only/side-effect-free, while a refund specialist has genuine real-world consequences. Running it via `Promise.all()` alongside the others is only safe if it's gated by the same human-approval-above-threshold pattern from Part A — an agent should never autonomously execute a real refund purely because Triage routed to it and `Promise.all()` happened to include it in a concurrent batch. This reveals a genuine architectural gap: write-action specialists belong in a different trust tier than read-only analysis specialists, and likely need an explicit confirmation step before ever being included in a concurrent fan-out.
