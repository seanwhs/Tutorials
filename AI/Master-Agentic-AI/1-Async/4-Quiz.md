# Quiz: Phase 1 — Foundations of the Asynchronous Agentic Loop

*Scenario-based questions testing architectural judgment, not memorization. Answers and rationale follow each question — try answering before revealing them.*

---

**Q1.** You're debugging a version of the ReAct loop where a colleague removed the `response_format: { type: 'json_object' }` option to "make the model's responses more natural," and replaced the JSON parsing with a regex that scans for the word "ACTION:" in the model's reply. Two weeks later, the loop starts silently failing for about 5% of requests, with no clear pattern. What's the most likely root cause, and why did this course avoid this design from the start?



---

**Q2.** The loop has three independent termination guarantees: `MAX_STEPS`, a per-step `AbortController` timeout, and repeated-action detection. Explain a specific failure scenario that only ONE of these three would catch, and why the other two would miss it.



---

**Q3.** Why does `completionWithTimeout`'s `AbortController` get created *inside* the function on every call, rather than once at the module level like the Groq client itself?



---

**Q4.** A teammate suggests: "Since we already have a fallback route that always produces a real answer, let's remove the step ceiling and repeated-action detection entirely — the fallback will catch everything eventually anyway." What's wrong with this reasoning?



---

**Q5.** In the calculator tool, why does the course use a strict regex whitelist (`/^[0-9+\-*/().\s]+$/`) *before* calling `new Function(...)`, rather than just wrapping `new Function(...)` in a `try/catch` and treating any thrown error as an invalid expression?



---

**Q6.** Why does the course push tool observations into the `messages` array using the `user` role, prefixed with the literal string `"Observation: "`, rather than inventing a custom role like `"tool"`?

