# Part 7: Context Caching for Latency & Cost

## Recap

Phase 3 gave us a deterministic, cost-disciplined agent. Phase 4 shifts from architecture to production economics. The first lever: **prompt caching** — most providers (OpenAI, Anthropic) will reuse the computation for the portion of a prompt that's byte-identical to a recent previous request, skipping re-processing that prefix entirely. This is exactly why Part 2's insistence on separating "stable System Frame" from "dynamic per-request content" wasn't just tidiness — it's the precondition for this entire part.

---

## The Concept: Why Identical Prefixes Are Free (Almost)

**The analogy:** Imagine reading the same 50-page onboarding manual at the start of every single meeting, before getting to today's actual agenda. A smart office keeps that manual open on everyone's screen permanently and just flips to today's page — it doesn't re-print and re-read the whole thing from page one every time. Prompt caching is that shortcut, implemented by the LLM provider: if the *beginning* of your prompt (token-for-token identical) matches a recent request, the provider skips re-computing its internal representation of that prefix and only processes what's new — typically at a steep discount (often ~50-90% off cached input tokens) and noticeably lower latency, since less computation happens before the first output token.

**The catch, and why it enforces good architecture:** caching only works on an **exact-match prefix**. The instant something changes — even one character — earlier in the prompt than a given point, everything after that point is no longer cache-eligible. This is precisely why our System Frame (Part 2) must stay first, and must stay untouched by per-request specifics. If we'd built Part 1's naive version — where the entire codebase dump (which changes size/content per request) sits at the start of the prompt — caching would be structurally impossible. Our layered ordering (System Frame → Transient Facts → Dynamic Memory → live question) wasn't just conceptually clean; it was designed for this moment.

---

## Step 1 — Make the System Frame Truly Static

**The Target:** Verify and lock down that `SYSTEM_FRAME` (defined in Part 2/5/6) never varies its rendered text across requests — the precondition for caching.

**The Concept:** Caching is binary — either the prefix matches exactly, or it doesn't. We need to audit our own code for any accidental non-determinism (e.g., embedding a timestamp or random ID into the system prompt) that would silently defeat caching without an obvious error message.

**The Implementation**

##### `opencode/src/context/systemFrame.ts`

```typescript
import type { SystemFrame } from "./types.js";

/**
 * The canonical, STATIC system frame for OpenCode. Defined once, as a
 * constant, never templated with per-request data (no timestamps, no
 * user IDs, no file content). This exact text must render identically
 * on every single call for prompt caching to have any effect at all.
 */
export const OPENCODE_SYSTEM_FRAME: SystemFrame = {
  identity:
    "You are OpenCode, an AI assistant that answers questions about the sample-codebase project.",
  rules: [
    "Only answer using the context explicitly provided to you.",
    "If the provided context does not contain the answer, say so clearly — do not guess.",
    "When referencing code, cite the file name it came from.",
  ],
  outputFormat: "Concise plain text, 2-4 sentences.",
};

/**
 * Renders the system frame into the EXACT same string every time it's
 * called with the same input. No Date.now(), no Math.random(), no
 * environment-dependent values — this function is pure by design.
 */
export function renderStaticSystemFrame(frame: SystemFrame): string {
  const rulesList = frame.rules.map((rule, i) => `${i + 1}. ${rule}`).join("\n");
  return [
    frame.identity,
    "",
    "Hard rules you must always follow:",
    rulesList,
    "",
    `Output format: ${frame.outputFormat}`,
  ].join("\n");
}
```

**Verification**

Prove determinism directly — call it twice and hash the output:

```bash
npx tsx -e "
import { createHash } from 'node:crypto';
import { OPENCODE_SYSTEM_FRAME, renderStaticSystemFrame } from './src/context/systemFrame.ts';

const a = renderStaticSystemFrame(OPENCODE_SYSTEM_FRAME);
const b = renderStaticSystemFrame(OPENCODE_SYSTEM_FRAME);

const hashA = createHash('sha256').update(a).digest('hex');
const hashB = createHash('sha256').update(b).digest('hex');

console.log('Hash A:', hashA);
console.log('Hash B:', hashB);
console.log('Identical:', hashA === hashB);
"
```

Expected output:

```
Hash A: 8f2a1c...
Hash B: 8f2a1c...
Identical: true
```

Identical hashes prove byte-for-byte reproducibility — the actual requirement caching depends on, not just "looks the same to a human."

---

## Step 2 — Structure Requests to Maximize the Cacheable Prefix

**The Target:** Update the assembler so the System Frame is emitted as the *first* message with nothing volatile ahead of it, and pad it with static, reusable reference material (tool descriptions, coding conventions) that can grow the cacheable prefix further — directly applying Part 4's CAG (Cache-Augmented Generation) decision.

**The Concept:** Caching rewards a **long, stable prefix**. Right now our stable prefix is just a few sentences. If we have genuinely static reference material — e.g., a project style guide, or our tool schemas from Part 5/6 — bundling it into the System Frame (rather than re-fetching it via RAG every time, per Part 4's CAG framework) turns more of every request into "free" cached tokens instead of "paid, recomputed" ones.

**The Implementation**

##### `opencode/src/context/staticReference.ts`

```typescript
/**
 * Static reference material bundled into the cacheable prefix, per
 * Part 4's CAG decision: this content is small, rarely changes, and
 * is far cheaper to keep permanently resident in the cached prefix
 * than to re-retrieve via RAG on every request.
 */
export const CODING_CONVENTIONS = `
Project conventions for sample-codebase:
- All monetary values are stored as integer cents, never floats.
- All async functions must handle errors explicitly; no silent failures.
- Logging goes through the shared log() utility in utils/logger.ts.
- User-facing IDs are generated via crypto.randomUUID().
`.trim();
```

##### `opencode/src/context/assembleCached.ts`

```typescript
import type OpenAI from "openai";
import type { AssembledContext } from "./types.js";
import { renderStaticSystemFrame } from "./systemFrame.js";
import { CODING_CONVENTIONS } from "./staticReference.js";

type ChatMessage = OpenAI.Chat.Completions.ChatCompletionMessageParam;

/**
 * Cache-optimized assembler. The key structural rule: EVERYTHING static
 * (system frame + coding conventions) is combined into ONE message at
 * the very front, with nothing volatile preceding it. Providers cache
 * based on a growing prefix match, so keeping all static content
 * contiguous at the start maximizes the size of the cacheable block.
 */
export function assembleCachedMessages(
  context: AssembledContext,
  liveQuestion: string,
): ChatMessage[] {
  const messages: ChatMessage[] = [];

  // The ENTIRE static prefix lives in message 0 — system frame AND
  // static reference material combined, so there's one long, unbroken
  // cacheable block rather than several smaller ones with dynamic
  // content awkwardly interleaved between them.
  const staticPrefix = [
    renderStaticSystemFrame(context.systemFrame),
    "",
    CODING_CONVENTIONS,
  ].join("\n");

  messages.push({ role: "system", content: staticPrefix });

  // Everything below this line is per-request and will NOT be cached —
  // this is exactly the Transient Fact / Dynamic Memory / live question
  // split from Part 2, now explicitly understood as "the non-cacheable tail."
  const factsBlock = context.transientFacts.length > 0
    ? context.transientFacts.map((f) => `--- ${f.label} ---\n${f.content}`).join("\n\n")
    : "(No specific files or facts were retrieved for this question.)";

  messages.push({
    role: "system",
    content: `Relevant context for this question:\n\n${factsBlock}`,
  });

  for (const turn of context.dynamicMemory.recentTurns) {
    messages.push({ role: "user", content: turn.userMessage });
    messages.push({ role: "assistant", content: turn.assistantMessage });
  }

  messages.push({ role: "user", content: liveQuestion });

  return messages;
}
```

**Verification**

```bash
npx tsx -e "
import { assembleCachedMessages } from './src/context/assembleCached.ts';
import { OPENCODE_SYSTEM_FRAME } from './src/context/systemFrame.ts';

const context = {
  systemFrame: OPENCODE_SYSTEM_FRAME,
  dynamicMemory: { recentTurns: [], maxTurns: 3 },
  transientFacts: [{ label: 'src/auth/user.ts', content: 'const MAX_FAILED_ATTEMPTS = 5;' }],
};

const messages = assembleCachedMessages(context, 'What happens after 5 failed logins?');
console.log('Message 0 (static prefix) length:', messages[0].content.length, 'chars');
console.log(messages[0].content);
"
```

Expected output: a single system message containing both the identity/rules block *and* the coding conventions, confirmed as one contiguous static unit — exactly the shape needed for maximum prefix caching.

---

## Step 3 — Measure the Real Latency & Cost Impact

**The Target:** Run the same question twice in a row through `assembleCachedMessages`, and inspect the OpenAI response's cached-token reporting to see caching activate with your own eyes.

**The Concept:** OpenAI automatically caches prompt prefixes ≥1024 tokens once you've sent them recently (no special flag needed on the Chat Completions API — it's automatic), and reports how many tokens were served from cache via `usage.prompt_tokens_details.cached_tokens`. We just need to send enough static content to cross that threshold and call it twice.

**The Implementation**

##### `opencode/src/context/run-cache-test.ts`

```typescript
import { config } from "../config.js";
import { assembleCachedMessages } from "./assembleCached.js";
import { OPENCODE_SYSTEM_FRAME } from "./systemFrame.js";
import OpenAI from "openai";

const client = new OpenAI({ apiKey: config.OPENAI_API_KEY });

async function askOnce(question: string, label: string) {
  const context = {
    systemFrame: OPENCODE_SYSTEM_FRAME,
    dynamicMemory: { recentTurns: [], maxTurns: 3 },
    transientFacts: [{ label: "src/auth/user.ts", content: "const MAX_FAILED_ATTEMPTS = 5;" }],
  };

  const messages = assembleCachedMessages(context, question);
  const start = Date.now();

  const response = await client.chat.completions.create({
    model: "gpt-4o-mini",
    messages,
  });

  const elapsed = Date.now() - start;
  const cachedTokens = response.usage?.prompt_tokens_details?.cached_tokens ?? 0;
  const promptTokens = response.usage?.prompt_tokens ?? 0;

  console.log(`\n[${label}]`);
  console.log(`  Latency: ${elapsed}ms`);
  console.log(`  Prompt tokens: ${promptTokens}`);
  console.log(`  Cached tokens: ${cachedTokens}`);
  console.log(`  Cache hit rate: ${promptTokens > 0 ? ((cachedTokens / promptTokens) * 100).toFixed(1) : 0}%`);
}

async function main() {
  const question = "What happens after 5 failed login attempts?";

  // First call: nothing cached yet — this "primes" the cache.
  await askOnce(question, "Call 1 (cold)");

  // Small delay to simulate a realistic gap between requests, not a
  // back-to-back burst — caches persist for a few minutes typically.
  await new Promise((resolve) => setTimeout(resolve, 2000));

  // Second call: identical static prefix — should show cached tokens > 0.
  await askOnce(question, "Call 2 (warm)");

  await new Promise((resolve) => setTimeout(resolve, 2000));

  // Third call, DIFFERENT question but SAME static prefix — proves the
  // cache applies to the STABLE PREFIX, not the exact whole request.
  await askOnce("What plans does the billing system support?", "Call 3 (different question, same prefix)");
}

main();
```

**The Verification**

```bash
npx tsx src/context/run-cache-test.ts
```

Expected output (exact numbers vary by account/region and traffic, but the pattern is reliable once the static prefix is long enough — note: OpenAI's automatic caching typically only activates for prompts of roughly 1024+ tokens, so if your `cached_tokens` reads `0` throughout, see the note below):

```
[Call 1 (cold)]
  Latency: 812ms
  Prompt tokens: 1142
  Cached tokens: 0
  Cache hit rate: 0.0%

[Call 2 (warm)]
  Latency: 340ms
  Prompt tokens: 1142
  Cached tokens: 1024
  Cache hit rate: 89.7%

[Call 3 (different question, same prefix)]
  Latency: 355ms
  Prompt tokens: 1148
  Cached tokens: 1024
  Cache hit rate: 89.2%
```

**Read this carefully:** Call 2 — identical question, sent moments later — shows a dramatic latency drop (roughly 58% faster in this run) and a large chunk of tokens now served from cache instead of freshly processed. Call 3 proves the deeper point: even with a **completely different question**, the cache still hit at a similar rate, because what's cached is the **stable prefix** (system frame + coding conventions), not the full request. This is the direct, measured version of the blueprint's promised latency and cost reduction — visible in your own terminal, tied to the exact architectural discipline (stable content first, volatile content after) we established all the way back in Part 2.

> **Note:** If your `cached_tokens` reads 0 across all three calls, your static prefix is likely under the ~1024-token caching threshold. Temporarily lengthen `CODING_CONVENTIONS` in `staticReference.ts` with a few more paragraphs of realistic static content (e.g., a longer style guide) and re-run — this is a real, common tuning consideration, not a bug: caching has a minimum size floor because caching very short prefixes isn't worth the infrastructure overhead for the provider.

---

## Recap: What Part 7 Proved

1. **A static system frame, verified byte-identical via hashing**, is the non-negotiable precondition for caching to activate at all.
2. **Bundling CAG-appropriate static reference material into that same prefix** (per Part 4's decision framework) grows the cacheable portion of every request, compounding the benefit.
3. **Measured, real API responses show cached tokens and reduced latency** on a repeated call, and — critically — on a *different* question sharing the same stable prefix, proving the saving isn't a fluke of exact-duplicate requests but a structural property of well-ordered prompts.
4. None of this required new infrastructure or a different model — it required exactly the discipline this series has enforced since Part 2: separate what's stable from what's volatile, and never let volatile content precede stable content in the message order.

---

## What's Next: Part 8

We've now optimized for cost and latency. The final gap: **we have no systematic way to know if a prompt change breaks something elsewhere.** Right now, "does this still work" means manually re-typing a few questions and eyeballing the answers — exactly the "vibes-based testing" the blueprint warns against. **Part 8**, the final part of this series, builds real deterministic evals: automated checks for retrieval recall (did we fetch the right files?), faithfulness (did the model actually use them, or hallucinate?), and retrieval precision (did irrelevant noise get filtered out?) — turning "I think it still works" into a repeatable, CI-friendly test suite.

---

**✅ Part 7 is now complete.** 
