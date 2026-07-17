# Appendix G — Provider Prompt Caching & Eval Design, in Depth

Part 7 measured OpenAI's automatic prompt caching via `cached_tokens`. Part 8 built a golden-dataset eval suite. This appendix covers provider-specific caching mechanics and how to scale the eval pattern beyond five hand-written cases.

## How Automatic Caching Actually Works (OpenAI)

OpenAI's prompt caching, as used in Part 7, works on **prefix matching at the token level**, with a few concrete mechanics worth knowing:

- **Minimum size:** caching only activates for prompts of roughly 1024 tokens or more — this is why Appendix-adjacent troubleshooting in Part 7 suggested padding `CODING_CONVENTIONS` if you saw zero cached tokens.
- **Cache lifetime:** cached prefixes typically persist for a matter of minutes (commonly cited as 5-10 minutes of inactivity before eviction, though this is not contractually guaranteed and can vary), and are automatically evicted from the provider's cache under memory pressure regardless of recency. This is why a real production system shouldn't *depend* on caching for correctness — only for a cost/latency optimization that may or may not be in effect on any given request.
- **Granularity:** caching works in fixed-size increments (commonly 128-token blocks), and only whole matching blocks are cached — a one-character difference early in the prompt invalidates caching for everything after that point, but doesn't affect blocks entirely before the change.
- **No special API flag required:** unlike some providers, OpenAI's Chat Completions API caches automatically based on prefix matching — you don't set a `cache: true` parameter; you simply structure your prompts to maximize stable, repeated prefixes, exactly as Part 7 did.

## How Anthropic's Caching Differs (Explicit, Not Automatic)

If you adapt this series' patterns to Anthropic's Claude models instead of OpenAI, the mechanism is meaningfully different: Anthropic requires **explicit cache breakpoints**, marked directly in the request via a `cache_control` field on a content block:

```typescript
// Anthropic-style request shape (illustrative, not literal OpenAI SDK syntax)
{
  role: "system",
  content: [
    {
      type: "text",
      text: renderStaticSystemFrame(context.systemFrame),
      cache_control: { type: "ephemeral" }, // explicit marker: cache everything up to here
    },
  ],
}
```

This is arguably a more deliberate design than OpenAI's fully automatic approach — you explicitly declare "cache up to this point," rather than relying on the provider to detect a repeated prefix implicitly. The architectural lesson from Part 7 transfers directly regardless of provider: static content first, contiguous, with nothing volatile injected before the cache boundary — only the mechanism for *declaring* that boundary differs.

## Scaling the Eval Dataset Beyond Five Hand-Written Cases

Part 8's `EVAL_DATASET` had five cases — enough to prove the pattern works, not enough for genuine production confidence. Growing it responsibly involves a few concrete practices:

**Mine real user questions.** Once OpenCode is in front of real users, log every question asked (with appropriate privacy handling) and periodically review them for cases where the model's answer was later corrected or flagged — each such case becomes a strong candidate for a new golden dataset entry, since it represents a *real* failure mode, not a hypothetical one.

**Cover negative cases, not just positive ones.** Every case in Part 8's dataset assumed the codebase *contains* the answer. An equally important category: questions where the correct answer is "I don't know" or "this isn't in the provided code" — testing whether the model appropriately declines rather than hallucinating a plausible-sounding but fabricated answer. Add cases like:

```typescript
{
  id: "unanswerable-question",
  question: "What programming language is the mobile app written in?",
  expectedFiles: [], // deliberately empty — nothing in sample-codebase answers this
}
```

with a corresponding metric checking that the model's answer explicitly states it cannot find this information, rather than confidently inventing "Swift" or "Kotlin."

**Track metrics over time, not just as a pass/fail gate.** Part 8's runner exits with a pass/fail code, appropriate for CI. A more mature setup also logs each run's recall/precision/faithfulness numbers to a persistent store (even a simple CSV or JSON log file) with a timestamp, so a gradual regression — recall slowly drifting from 95% to 80% over several weeks of small, individually-approved prompt tweaks — becomes visible as a trend, not just invisible until it crosses the hard failure threshold.

**Separate eval cases by category as the dataset grows.** Once you have dozens or hundreds of cases, tagging them (e.g., `category: "billing"`, `category: "auth"`, `category: "edge-case"`) lets you catch the exact regression pattern the blueprint warned about in Phase 4: "fixing a bug for React-based questions breaks Django-based answers." Running the full suite broken down by category after every prompt change turns that vague fear into a concrete, checkable diff.

## The Core Principle Tying Appendices F and G Together

Both reranking and caching are optimizations layered *on top of* an already-sound architecture — they don't fix a badly-structured system, and both depend on structural decisions made much earlier in the series (isolating retrieval behind a clean function boundary in Part 3/4; separating static from volatile prompt content in Part 2). This is the throughline of the entire series: production-grade AI systems aren't made reliable by a clever prompt or a bigger model — they're made reliable by disciplined software architecture that happens to have an LLM as one of its components.

---

**✅ All reference appendices are now complete**, closing out the full Context Engineering series — Parts 0 through 8, plus Appendices A through G. You have a working, measured, cost-aware, regression-tested AI coding assistant, and the underlying architectural reasoning to extend it, adapt it to other providers, or apply the same discipline to an entirely different LLM-backed system.
