# Phase 6 — Reference Section: Concurrency Patterns, Race Conditions & Multi-Agent Topologies

Optional deep-dive material — nothing in Phase 7 requires reading this first.

## R6.1 The Full Family of JavaScript Promise Combinators

We used `Promise.all()` throughout this phase, but it's one of four related combinator functions, each with a genuinely different failure/completion semantic. Knowing all four well is essential for choosing the right one in future multi-agent work:

| Combinator | Resolves when | Rejects when | Best used for |
|---|---|---|---|
| `Promise.all()` | **Every** promise resolves | **Any single** promise rejects (immediately, discarding others) | Independent tasks where you need ALL results, and any single failure should halt the whole batch — appropriate when every specialist's success is treated as a **hard requirement** for proceeding to synthesis |
| `Promise.allSettled()` | **Every** promise settles (resolves OR rejects) — never rejects itself | Never — always resolves | Independent tasks where you want to **collect every outcome**, including failures, without losing the successful ones — often a SAFER default for multi-agent fan-out than `Promise.all()` |
| `Promise.race()` | **The first** promise to settle (win or lose) | If that first-to-settle promise happens to be a rejection | Timeout patterns (racing a real call against a timer promise), or "fastest available answer wins" scenarios |
| `Promise.any()` | **The first** promise to *resolve successfully* | Only if **all** promises reject | "Try several equivalent options, take whichever succeeds first" — directly relevant to Phase 7's provider failover pattern |

Here's an important nuance worth calling out explicitly: our specialists in this phase never actually reject their promises at all — `runSpecialist()` catches every internal failure and always resolves with `{ success: false, ... }`. Because of this design choice, using `Promise.all()` was actually *safe* for us, even though `Promise.all()`'s "any single rejection kills the whole batch" behavior sounds risky at first glance — we engineered around that risk at the specialist level rather than the orchestration level. If you ever build a multi-agent system where individual agent calls to a truly async function *can* genuinely throw/reject (e.g., you're calling a raw SDK function directly, without our `runSpecialist()` wrapper's internal try/catch), `Promise.allSettled()` would be the safer default combinator, since it guarantees you get back every result — successful or failed — without one bad apple discarding the rest.

## R6.2 A Direct Comparison: `Promise.all` vs. `Promise.allSettled` in Practice

To make the distinction completely concrete, here's what our Part 2 code would look like using each combinator, and how their behavior would genuinely differ if a specialist call *did* throw a raw, uncaught exception:

```js
// Promise.all() — if ANY of these three genuinely reject, the entire
// expression rejects immediately, and you get NOTHING back from the
// other two, even if they had already succeeded.
try {
  const [a, b, c] = await Promise.all([callA(), callB(), callC()]);
  // only reached if ALL THREE succeeded
} catch (err) {
  // triggered by a SINGLE failure — you have no idea which of the three
  // failed, and you've lost any successful results from the other two
}

// Promise.allSettled() — ALWAYS resolves, giving you an array of
// { status: 'fulfilled', value } or { status: 'rejected', reason }
// for EVERY promise, regardless of how many succeeded or failed.
const results = await Promise.allSettled([callA(), callB(), callC()]);
results.forEach((r, i) => {
  if (r.status === 'fulfilled') {
    console.log(`Call ${i} succeeded:`, r.value);
  } else {
    console.log(`Call ${i} failed:`, r.reason);
  }
});
```

Because we already built `runSpecialist()` to internally catch every failure and always resolve, our actual Part 2/3 code effectively behaves like the `allSettled` pattern already, just achieved through our own explicit error handling inside each specialist rather than relying on the combinator itself to provide that safety net. Both are valid ways to reach the same safety guarantee — ours pushes the responsibility down into each unit of work; `allSettled` provides it at the orchestration layer instead. Understanding both approaches lets you choose deliberately based on how much you trust the safety of the underlying async functions you're calling.

## R6.3 Race Conditions to Watch For in Concurrent Agent Systems

"Concurrency is easy to get *working*, but easy to get subtly *wrong*" is a genuinely important engineering maxim, and it's worth naming the specific failure modes to watch for as you extend multi-agent patterns beyond what we built:

- **Shared mutable state across concurrent calls.** Our `eventBus` is safe specifically because each request gets its **own fresh instance** (`createEventBus()` is called fresh inside each `POST` handler) — if we had instead used one single, module-level shared bus instance across *all* requests, concurrent requests from different users could interleave their published events into the same log, causing one user's cascade to see another user's specialist findings. Always ask, for any shared data structure: "is this genuinely scoped to one request, or could two concurrent requests collide inside it?"
- **Non-atomic read-modify-write patterns.** Our Phase 3 cost ledger (`recordTurnCost`) reads the existing ledger entry, mutates it, and writes it back — if two requests for the *same session* happened to race each other at the exact same moment (a genuine possibility with fast, concurrent tool calls or rapid double-submission from a client), you could theoretically lose an update in a true multi-instance production environment. Our single in-memory `Map` happens to avoid this specific issue on a single Node.js instance because JavaScript's event loop won't interleave two separate `async` functions' synchronous code sections arbitrarily mid-statement — but this guarantee **evaporates** the moment you move to a real distributed store like Redis across multiple instances, where you'd need to reach for atomic increment operations or transactions instead.
- **Ordering assumptions on concurrently-produced results.** We relied on `Promise.all()`'s documented guarantee that result array order matches input array order, not completion order — this is a genuine, reliable guarantee in the JavaScript specification, not a coincidence, but it's worth knowing it's specifically *this* guarantee you're leaning on, rather than assuming "things probably come back in a sensible order" without a concrete basis for that assumption.

## R6.4 Beyond This Course's Topology: Other Multi-Agent Shapes

We built one specific multi-agent topology in this phase — **triage → parallel fan-out → synthesis** — but it's worth knowing the names and shapes of other common patterns you'll encounter in more advanced systems:

- **Sequential pipeline (chain-of-agents):** Agent A's full output becomes Agent B's input, becomes Agent C's input, in strict sequence — appropriate when each stage genuinely *depends* on the previous stage's specific output, unlike our specialists, which all analyzed the same shared original input independently.
- **Fan-out / fan-in (what we built):** One input triggers multiple independent parallel analyses, whose results are then combined by a final aggregating stage.
- **Debate / adversarial pattern:** Two or more agents are deliberately given opposing goals or perspectives on the *same* question (e.g., one agent argues for approving a design, another argues against), and a judge agent evaluates both arguments — useful for surfacing considerations a single-perspective review might miss.
- **Hierarchical delegation (manager/worker):** A "manager" agent doesn't just triage a fixed set of specialists — it dynamically decides *how many* worker agents to spawn and what specific sub-task to assign each one, based on the complexity of the input, rather than choosing from a fixed enum of pre-built specialists.

Our Triage → Fan-out → Synthesis pattern is an excellent, genuinely production-relevant default for the vast majority of practical multi-agent use cases — it's simple to reason about, easy to debug via the event bus's audit trail, and scales cleanly as you add more specialists. The more exotic topologies above are worth knowing about, but should generally be reached for only when your specific problem genuinely calls for their added complexity, not by default.

## R6.5 Cost and Latency Implications of Fan-Out Architectures

A quick, important practical note connecting this phase back to Phase 3's cost auditing work: **every specialist you fan out to is a separate, independently-billed model call.** Our triage-gated approach (only running specialists actually relevant to a given input) isn't just a nice architectural touch — it's a genuine, meaningful cost optimization. A naive system that always runs all three specialists regardless of relevance would pay for three calls on every single request, even when two of them contribute nothing useful; our triage stage's entire value proposition is spending one small, cheap classification call up front to potentially save two full specialist calls' worth of cost and latency on requests that don't need them. This is a pattern worth generalizing: **whenever you're paying for optional or conditionally-relevant work, a cheap upfront routing decision is almost always worth its own small cost.**


Say "next" whenever you're ready to continue into the final phase.
