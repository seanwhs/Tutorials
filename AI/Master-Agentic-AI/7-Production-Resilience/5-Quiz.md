# Quiz: Phase 7 — Production Resilience, Quotas & Gateways

---

**Q1.** Explain why `withRetry()`'s `defaultIsRetryable()` function treats a `400` error completely differently from a `429` or `500` error, and what would go wrong in practice if all error types were retried identically.



---

**Q2.** Why does `computeDelay()` add random jitter on top of the calculated exponential delay, rather than using the pure exponential value directly? Construct a concrete scenario where omitting jitter would cause a real problem.



---

**Q3.** In `completionWithTimeout`, why is the whole-loop `outerSignal` passed *into* the retry wrapper's inner function (so a fresh `AbortController` is created per attempt) rather than the retry wrapper being placed *inside* a single, one-time-created timeout controller for the whole set of retries?



---

**Q4.** Explain why `isRetryable` in the whole-loop-deadline-aware version of `completionWithTimeout` explicitly excludes errors with `code === 'DEADLINE_EXCEEDED'` from being retried, even though such errors would otherwise superficially resemble a "transient failure worth retrying."



---

**Q5.** Trace through what happens, step by step, when Groq's API key is invalid and the ReAct loop calls `generateCompletion()`. Name every layer of resilience the request passes through before the user ultimately receives a response, and explain why the user still gets a normal, successful-looking answer despite an entire provider being completely down.



---

**Q6.** Why does the circuit breaker gate provider *selection* (skipping a broken provider before even attempting a call) rather than relying purely on `withRetry`'s per-call retry logic to eventually "give up" on a consistently broken provider each time it's tried?
