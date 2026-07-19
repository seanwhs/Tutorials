# Phase 3 — Reference Section: Retrieval Architecture Trade-offs & Cost Modeling Deep Dive

Optional deep-dive material — nothing in Phase 4 requires reading this first.

## R3.1 When You *Should* Reach for Vector Embeddings After All

This entire phase deliberately emphasized vectorless patterns, but it would be a disservice to leave you thinking embeddings are never the right tool. It's worth being precise about exactly where the line sits, since real production systems very often use *both* approaches side by side (a **hybrid retrieval** architecture):

| Signal | Favors vectorless (what we built) | Favors vector embeddings |
|---|---|---|
| Corpus size | Dozens to low hundreds of documents | Thousands to millions of documents |
| Vocabulary overlap | Users tend to phrase things using similar words to the source docs, or tags/metadata are well-curated | Users phrase things very differently from how the source material is written (paraphrasing, jargon mismatch, cross-lingual queries) |
| Data shape | Structured, tagged, or key-value in nature | Long-form unstructured prose (research papers, transcripts, freeform notes) |
| Update frequency | Frequently changing data (embeddings need re-indexing on every meaningful change) | Relatively stable corpora where re-indexing cost is amortized over long periods |
| Infrastructure appetite | Want to avoid running/managing a vector database | Already have the infrastructure, or the scale genuinely demands it |

Our `agenticRetrieve()` function (Part 2) is actually a very natural place to introduce a hybrid strategy later: you could add a `vectorSearch()` alongside `searchKnowledgeBase()`, run both, and let the same judge-and-rewrite loop decide whether either path's results are sufficient — the *architecture* of "search, judge, retry" doesn't care which underlying search mechanism produced the candidates.

## R3.2 The Full Shape of "Agentic" Beyond Just Retrieval

We scoped "agentic RAG" narrowly to retrieval quality judgment and query rewriting in this phase, but it's worth naming the broader pattern family this belongs to, often grouped under **self-reflective agent patterns**:

- **Self-critique loops** — an agent generates an answer, then a second pass (sometimes the same model, sometimes a distinct "critic" call) evaluates that answer against the original request before it's returned. We'll use a close cousin of this in Phase 4 for output validation.
- **Multi-candidate generation + selection** — generating several candidate answers or search queries in parallel and picking the best one, rather than committing to a single attempt sequentially. This connects directly to Phase 6's parallel multi-agent patterns.
- **Tool-use reflection** — after calling a tool, judging not just "was this data sufficient" (what we built) but "did I even call the *right* tool for this situation" — a more advanced check we touched on informally in Part 3's tool-disambiguation tests, but didn't formalize into an automated judge.

## R3.3 Why the Judge Uses a Separate, Cheap, Low-Temperature Call

It's worth explaining a design choice that might look wasteful at first glance: `judgeRetrieval()` makes an entirely separate model call, rather than somehow bundling the judgment into the same call that does the searching or reasoning. Three deliberate reasons:

1. **Separation of concerns produces more reliable judgments.** A model asked to simultaneously "search AND judge AND answer" in one call tends to be less rigorous about self-criticism than a call whose *only* job is critique. This is the same reason human editorial workflows often use a separate proofreader rather than relying on the original author to catch their own mistakes.
2. **Low temperature (0.1) for judgment, distinct from the main loop's temperature (0.2).** A judge is a classifier, not a creative writer — we want it to be as consistent and decisive as possible across repeated identical inputs, which lower temperature directly promotes.
3. **Isolating cost.** Because this is a distinct, trackable call, our per-turn cost ledger (Part 4) captures its cost as a clearly attributable line item, rather than an invisible cost bundled into some larger, opaque call.

## R3.4 A Note on the Fail-Open vs. Fail-Closed Distinction

We flagged this briefly in Part 2, but it's important enough to restate as a standalone principle, because you will make this exact judgment call repeatedly throughout the rest of this course: **whenever a safety/quality-checking mechanism itself fails, you must explicitly decide whether the system should "fail open" (proceed anyway) or "fail closed" (block/reject).**

- Our retrieval **judge** fails *open* (defaults to `sufficient: true`) — the cost of a wrong "this is good enough" verdict is a possibly slightly worse answer, which is an acceptable, recoverable risk for a customer-support-style knowledge base.
- Phase 4's **security guardrails** will fail *closed* — if a PII-redaction or jailbreak-detection mechanism itself errors out, the correct choice is to block the request rather than let a potentially malicious or sensitive payload through unchecked. The cost of a false rejection (an annoyed legitimate user) is much smaller than the cost of a false pass-through (a security incident).

There is no universally "correct" choice between the two — it is a genuine risk-assessment decision specific to what the mechanism is protecting against, and you should make it *consciously and explicitly*, exactly as we've done here, rather than defaulting to one or the other out of habit.

## R3.5 Full Reference: Provider Pricing Model Nuances

Our `pricing.js` table is intentionally simplified for teaching clarity, but real-world provider billing has additional wrinkles worth knowing about before you build a production financial reporting system on top of this pattern:

- **Cached input pricing** — some providers offer a discounted rate for tokens that were part of a recently-repeated prompt prefix (closely related to, but distinct from, the Next.js `use cache` mechanism from Phase 2 — this is a provider-side cost optimization, not something our application code controls directly).
- **Batch API discounts** — several providers offer significantly cheaper rates for non-real-time, asynchronous batch processing, which doesn't apply to our synchronous chat-style agent use case but is worth knowing about if you build a background/offline agentic pipeline later.
- **Free-tier quota vs. pay-as-you-go transition** — our free-tier providers (Groq, Google AI Studio, DeepSeek) may report `$0.00` actual billed cost while you're within free quota, even though our `calculateCost()` function will still report a computed dollar estimate. This is intentional and useful: it lets you understand what your costs *would* be at paid-tier rates, so you're not caught off guard the moment your usage crosses into billed territory.
- **Currency and regional pricing variation** — published rates are typically USD; confirm your provider's actual billing currency and any regional pricing differences if you operate outside the US.

## R3.6 Reference: Full Retrieval Tool Comparison Table (This Phase's Three Patterns)

A consolidated summary of every retrieval pattern built in this phase, for quick future reference:

| Tool | Data shape | Retrieval mechanism | Ranking involved? | Failure mode handling |
|---|---|---|---|---|
| `searchKnowledgeBase` | Unstructured prose documents, tagged | Keyword/tag weighted scoring + agentic judge/rewrite loop | Yes — top-N by score | Empty result set returned honestly; judge retries up to 3x |
| `lookupOrderStatus` | Structured key-value records | Direct exact-key dictionary lookup | No — exact match only | Explicit "not found" for unknown IDs; no fuzzy matching by design |
| `trackShipment` | External third-party API | Live network call, response reshaping | No — carrier returns the definitive record | Distinguishes "not found" (404-style) from genuine service failure (network/exception) |
