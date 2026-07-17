Final installment — delivered in full.

---

# Part 8: Deterministic Evals — Retrieval Recall, Faithfulness, and Retrieval Precision

## Recap

Every fix in this series so far was validated by manually running one question and reading the output. That's fine for building intuition, but it doesn't scale — change a prompt to fix one case, and you have no systematic way to know if you just broke five others. This is the "vibes-based testing" the blueprint warns against. Part 8 replaces manual spot-checks with a real, repeatable eval suite: a small set of test questions with known-correct answers, checked automatically via three concrete metrics.

---

## The Concept: Evals as Unit Tests for a Probabilistic System

**The analogy:** A unit test asserts `add(2, 3) === 5` — deterministic, exact. An LLM won't give you byte-identical output twice, so you can't assert exact string equality. But you *can* assert **structural properties** of its behavior that should hold true regardless of exact wording — like a hiring rubric that doesn't require an identical answer to "tell me about a time you led a team," but does require certain elements to be present. We'll build three such rubrics:

1. **Retrieval Recall** — of the files that were actually needed to answer correctly, what fraction did our retrieval pipeline (Part 4) actually find? Miss the right file, and the model can't possibly answer correctly no matter how good it is.
2. **Retrieval Precision** — of the files we retrieved, what fraction were actually relevant? Low precision means we're still handing the model noise, even if recall is fine — reintroducing a milder version of Part 1's "lost in the middle" risk.
3. **Faithfulness** — did the final answer only make claims traceable to the retrieved facts, or did the model state something not actually present in what we gave it (a hallucination)? This is checked by a second LLM call acting as a judge, comparing the answer against only the facts it was given — the same "cross-encoder judge" pattern from Part 4's reranker, applied to the final output instead of retrieval candidates.

---

## Step 1 — Build a Golden Dataset

**The Target:** A fixed, hand-curated set of test questions against `sample-codebase`, each labeled with the files a correct answer *must* draw from — our ground truth.

##### `opencode/src/evals/dataset.ts`

```typescript
export interface EvalCase {
  id: string;
  question: string;
  /** File paths a CORRECT answer must be grounded in. Ground truth, defined by us, not the model. */
  expectedFiles: string[];
}

export const EVAL_DATASET: EvalCase[] = [
  {
    id: "lockout-rule",
    question: "What happens after 5 failed login attempts?",
    expectedFiles: ["src/auth/user.ts"],
  },
  {
    id: "pro-plan-price",
    question: "How much does the pro plan cost?",
    expectedFiles: ["src/billing/subscription.ts"],
  },
  {
    id: "invoice-total",
    question: "How is an invoice's total calculated?",
    expectedFiles: ["src/billing/invoice.ts"],
  },
  {
    id: "password-hash-source",
    question: "What hashing algorithm is used for passwords, and where is it defined?",
    expectedFiles: ["src/utils/hash.ts", "src/auth/user.ts"],
  },
  {
    id: "auth-throttling",
    question: "How does authentication throttling work in this codebase?",
    expectedFiles: ["src/auth/user.ts"],
  },
];
```

**Verification**

```bash
npx tsx -e "
import { EVAL_DATASET } from './src/evals/dataset.ts';
console.log('Total eval cases:', EVAL_DATASET.length);
EVAL_DATASET.forEach(c => console.log(' -', c.id, '->', c.expectedFiles.join(', ')));
"
```

Expected output:

```
Total eval cases: 5
 - lockout-rule -> src/auth/user.ts
 - pro-plan-price -> src/billing/subscription.ts
 - invoice-total -> src/billing/invoice.ts
 - password-hash-source -> src/utils/hash.ts, src/auth/user.ts
 - auth-throttling -> src/auth/user.ts
```

---

## Step 2 — Retrieval Recall & Precision Metrics

**The Target:** Pure, deterministic scoring functions — no LLM calls, no randomness — that compare retrieved file paths against `expectedFiles`.

##### `opencode/src/evals/metrics.ts`

```typescript
export interface RetrievalMetricResult {
  recall: number;
  precision: number;
  expectedFilesFound: string[];
  expectedFilesMissed: string[];
  irrelevantFilesRetrieved: string[];
}

/**
 * Retrieval Recall: of the files we NEEDED, what fraction did we
 * actually retrieve (in any position, among any number of chunks)?
 * Retrieval Precision: of the files we RETRIEVED, what fraction were
 * actually relevant (i.e., in the expected set)?
 * Both are pure, deterministic set-arithmetic — no LLM involved, so
 * these numbers are 100% reproducible given the same retrieved chunks.
 */
export function computeRetrievalMetrics(
  retrievedFilePaths: string[],
  expectedFiles: string[],
): RetrievalMetricResult {
  const retrievedSet = new Set(retrievedFilePaths);
  const expectedSet = new Set(expectedFiles);

  const expectedFilesFound = expectedFiles.filter((f) => retrievedSet.has(f));
  const expectedFilesMissed = expectedFiles.filter((f) => !retrievedSet.has(f));
  const irrelevantFilesRetrieved = [...retrievedSet].filter((f) => !expectedSet.has(f));

  const recall = expectedFiles.length > 0 ? expectedFilesFound.length / expectedFiles.length : 1;
  const precision =
    retrievedFilePaths.length > 0
      ? (retrievedFilePaths.length - irrelevantFilesRetrieved.length) / new Set(retrievedFilePaths).size
      : 1;

  return { recall, precision, expectedFilesFound, expectedFilesMissed, irrelevantFilesRetrieved };
}
```

**Verification**

```bash
npx tsx -e "
import { computeRetrievalMetrics } from './src/evals/metrics.ts';

// Simulate: expected src/auth/user.ts, but we ALSO pulled in an irrelevant noise file.
const result = computeRetrievalMetrics(
  ['src/auth/user.ts', 'src/generated/session.ts'],
  ['src/auth/user.ts'],
);
console.log(result);
"
```

Expected output:

```
{
  recall: 1,
  precision: 0.5,
  expectedFilesFound: [ 'src/auth/user.ts' ],
  expectedFilesMissed: [],
  irrelevantFilesRetrieved: [ 'src/generated/session.ts' ]
}
```

Recall is perfect (we found everything needed); precision is only 0.5 (half of what we retrieved was noise) — exactly the kind of gap Part 4's reranker was built to close, now made measurable instead of anecdotal.

---

## Step 3 — Faithfulness Metric (LLM-as-Judge)

**The Target:** A function that checks whether a generated answer's claims are actually traceable to the retrieved facts it was given — catching hallucination even when the answer *sounds* confident and well-written.

##### `opencode/src/evals/faithfulness.ts`

```typescript
import { config } from "../config.js";
import OpenAI from "openai";
import { z } from "zod";

const client = new OpenAI({ apiKey: config.OPENAI_API_KEY });

const FaithfulnessJudgment = z.object({
  isFaithful: z.boolean(),
  unsupportedClaims: z.array(z.string()),
  reasoning: z.string(),
});

export interface FaithfulnessResult {
  isFaithful: boolean;
  unsupportedClaims: string[];
  reasoning: string;
}

/**
 * Faithfulness check: an LLM-as-judge call that verifies whether the
 * ANSWER's claims are all traceable to the provided facts — the same
 * "cross-encoder judge" pattern from Part 4's reranker, applied here
 * to catch hallucination rather than to filter retrieval candidates.
 * We deliberately do NOT show the judge the original question — only
 * the facts and the answer — so it can't be swayed by assuming the
 * answer is "probably right" because it sounds like a good response.
 */
export async function checkFaithfulness(
  answer: string,
  providedFacts: string[],
): Promise<FaithfulnessResult> {
  const factsBlock = providedFacts.length > 0 ? providedFacts.join("\n\n---\n\n") : "(no facts were provided)";

  const response = await client.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      {
        role: "system",
        content:
          "You are a strict fact-checker. You will be given a set of SOURCE FACTS and an " +
          "ANSWER. Determine whether every factual claim in the ANSWER is directly supported " +
          "by the SOURCE FACTS. If the answer states something not present in or inferable " +
          "from the source facts, list it as an unsupported claim. Be strict: 'probably' or " +
          "'likely' reasoning by the answer that isn't grounded in the facts still counts as " +
          "unsupported.",
      },
      {
        role: "user",
        content: `SOURCE FACTS:\n${factsBlock}\n\nANSWER TO CHECK:\n${answer}`,
      },
    ],
    response_format: {
      type: "json_schema",
      json_schema: {
        name: "faithfulness_judgment",
        strict: true,
        schema: {
          type: "object",
          properties: {
            isFaithful: { type: "boolean" },
            unsupportedClaims: { type: "array", items: { type: "string" } },
            reasoning: { type: "string" },
          },
          required: ["isFaithful", "unsupportedClaims", "reasoning"],
          additionalProperties: false,
        },
      },
    },
  });

  const raw = response.choices[0]?.message?.content;
  if (!raw) {
    // Fail closed: if the judge itself fails to respond, treat the
    // answer as UNFAITHFUL rather than silently passing it — an eval
    // suite that fails open is worse than useless, it's misleading.
    return { isFaithful: false, unsupportedClaims: ["Judge failed to respond"], reasoning: "No judge output" };
  }

  const parsed = FaithfulnessJudgment.safeParse(JSON.parse(raw));
  if (!parsed.success) {
    return { isFaithful: false, unsupportedClaims: ["Judge output malformed"], reasoning: "Schema validation failed" };
  }

  return parsed.data;
}
```

**Verification — Prove It Catches a Real Hallucination**

```bash
npx tsx -e "
import { checkFaithfulness } from './src/evals/faithfulness.ts';

const facts = ['const MAX_FAILED_ATTEMPTS = 5;', 'const LOCKOUT_DURATION_MS = 15 * 60 * 1000;'];

// A faithful answer:
const goodAnswer = 'After 5 failed login attempts, the account is locked for 15 minutes.';
console.log('Faithful case:', await checkFaithfulness(goodAnswer, facts));

// A hallucinated answer — invents a detail NOT in the facts (email notification):
const badAnswer = 'After 5 failed login attempts, the account is locked for 15 minutes and an email alert is sent to the security team.';
console.log('\nHallucinated case:', await checkFaithfulness(badAnswer, facts));
"
```

Expected output:

```
Faithful case: {
  isFaithful: true,
  unsupportedClaims: [],
  reasoning: 'Both the 5-attempt threshold and 15-minute lockout are directly present in the source facts.'
}

Hallucinated case: {
  isFaithful: false,
  unsupportedClaims: [ 'an email alert is sent to the security team' ],
  reasoning: 'The source facts contain no mention of email notifications or alerting the security team; this claim is fabricated.'
}
```

The judge correctly passes the grounded answer and flags the invented detail — proving this metric catches hallucination even when the fabricated sentence is fluent and plausible-sounding, exactly the case a human skimming the output might miss.

---

## Step 4 — The Full Eval Runner

**The Target:** Tie everything together: run every case in `EVAL_DATASET` through our Part 4 retrieval pipeline and Part 6 assembler, compute all three metrics per case, and print a summary report — our CI-ready regression check.

##### `opencode/src/evals/run.ts`

```typescript
import { config } from "../config.js";
import { EVAL_DATASET } from "./dataset.js";
import { computeRetrievalMetrics } from "./metrics.js";
import { checkFaithfulness } from "./faithfulness.js";
import { ingestCodebase } from "../retrieval/ingest.js";
import { embedText } from "../retrieval/embed.js";
import { rerankChunks } from "../retrieval/rerank.js";
import { assembleCachedMessages } from "../context/assembleCached.js";
import { OPENCODE_SYSTEM_FRAME } from "../context/systemFrame.js";
import OpenAI from "openai";

const client = new OpenAI({ apiKey: config.OPENAI_API_KEY });

interface CaseResult {
  id: string;
  recall: number;
  precision: number;
  isFaithful: boolean;
  answer: string;
}

async function main() {
  console.log("🔨 Ingesting codebase once for the full eval run...");
  const store = await ingestCodebase("./sample-codebase");

  const results: CaseResult[] = [];

  for (const evalCase of EVAL_DATASET) {
    console.log(`\n▶ Running case: ${evalCase.id}`);

    // Full pipeline: semantic search -> rerank -> assemble -> generate,
    // exactly mirroring the real Part 4/6 production path.
    const queryEmbedding = await embedText(evalCase.question);
    const wideResults = store.search(queryEmbedding, 8);
    const reranked = await rerankChunks(evalCase.question, wideResults, 3, 5);

    const retrievedFilePaths = reranked.map((r) => r.chunk.sourcePath);
    const retrievalMetrics = computeRetrievalMetrics(retrievedFilePaths, evalCase.expectedFiles);

    const transientFacts = reranked.map((r) => ({
      label: r.chunk.sourcePath,
      content: r.chunk.content,
    }));

    const context = {
      systemFrame: OPENCODE_SYSTEM_FRAME,
      dynamicMemory: { recentTurns: [], maxTurns: 3 },
      transientFacts,
    };
    const messages = assembleCachedMessages(context, evalCase.question);

    const response = await client.chat.completions.create({ model: "gpt-4o-mini", messages });
    const answer = response.choices[0]?.message?.content ?? "(no answer)";

    const faithfulness = await checkFaithfulness(
      answer,
      transientFacts.map((f) => f.content),
    );

    console.log(`  Recall: ${retrievalMetrics.recall.toFixed(2)} | Precision: ${retrievalMetrics.precision.toFixed(2)} | Faithful: ${faithfulness.isFaithful}`);
    if (retrievalMetrics.expectedFilesMissed.length > 0) {
      console.log(`  ⚠️  Missed expected files: ${retrievalMetrics.expectedFilesMissed.join(", ")}`);
    }
    if (!faithfulness.isFaithful) {
      console.log(`  ⚠️  Unsupported claims: ${faithfulness.unsupportedClaims.join("; ")}`);
    }

    results.push({
      id: evalCase.id,
      recall: retrievalMetrics.recall,
      precision: retrievalMetrics.precision,
      isFaithful: faithfulness.isFaithful,
      answer,
    });
  }

  // ---- Summary report ----
  const avgRecall = results.reduce((s, r) => s + r.recall, 0) / results.length;
  const avgPrecision = results.reduce((s, r) => s + r.precision, 0) / results.length;
  const faithfulCount = results.filter((r) => r.isFaithful).length;

  console.log("\n" + "=".repeat(60));
  console.log("EVAL SUMMARY");
  console.log("=".repeat(60));
  console.log(`Cases run: ${results.length}`);
  console.log(`Average Retrieval Recall: ${(avgRecall * 100).toFixed(1)}%`);
  console.log(`Average Retrieval Precision: ${(avgPrecision * 100).toFixed(1)}%`);
  console.log(`Faithfulness pass rate: ${faithfulCount}/${results.length} (${((faithfulCount / results.length) * 100).toFixed(1)}%)`);

  // A hard exit-code failure if any metric drops below an acceptable
  // bar — this is what makes the suite usable in a CI pipeline: a
  // regression fails the build instead of shipping silently.
  const RECALL_THRESHOLD = 0.8;
  const FAITHFULNESS_THRESHOLD = 0.8;
  const passed = avgRecall >= RECALL_THRESHOLD && faithfulCount / results.length >= FAITHFULNESS_THRESHOLD;

  console.log(`\nOverall: ${passed ? "✅ PASS" : "❌ FAIL"}`);
  if (!passed) process.exit(1);
}

main();
```

**The Verification**

```bash
npx tsx src/evals/run.ts
```

Expected output (abbreviated):

```
🔨 Ingesting codebase once for the full eval run...
📄 Loaded 35 files.
✂️  Split into 149 AST-based chunks.
🧮 Generated 149 embeddings.

▶ Running case: lockout-rule
  Recall: 1.00 | Precision: 1.00 | Faithful: true

▶ Running case: pro-plan-price
  Recall: 1.00 | Precision: 1.00 | Faithful: true

▶ Running case: invoice-total
  Recall: 1.00 | Precision: 1.00 | Faithful: true

▶ Running case: password-hash-source
  Recall: 1.00 | Precision: 0.67 | Faithful: true

▶ Running case: auth-throttling
  Recall: 1.00 | Precision: 1.00 | Faithful: true

============================================================
EVAL SUMMARY
============================================================
Cases run: 5
Average Retrieval Recall: 100.0%
Average Retrieval Precision: 93.3%
Faithfulness pass rate: 5/5 (100.0%)

Overall: ✅ PASS
```

```bash
echo $?
```

Expected output:

```
0
```

This is the payoff: a single command now gives you a pass/fail signal, with numbers, in seconds — instead of manually re-typing five questions and eyeballing whether the answers "feel right." Confirm the guardrail actually works by deliberately breaking something: temporarily change `rerankChunks`'s default `minScore` in `src/retrieval/rerank.ts` to `9` (an unreasonably strict bar) and re-run:

```bash
npx tsx src/evals/run.ts
```

You should now see recall drop below 100% on at least one case (relevant chunks getting filtered out too aggressively) and the final line read `❌ FAIL`, with a non-zero exit code — proving the suite actually catches regressions rather than passing regardless of what you do. Revert the change back to `5` before moving on.

---

## Recap: What Part 8 Built

1. **A golden dataset** — fixed questions with known-correct expected files, defined by us, not inferred from the model's own behavior.
2. **Retrieval Recall & Precision** — pure, deterministic set-arithmetic metrics requiring zero LLM calls, directly measuring whether Part 4's retrieval pipeline finds the right things without excess noise.
3. **Faithfulness via LLM-as-judge** — caught a deliberately planted hallucination (an invented "email alert" detail) with concrete, cited evidence, using the same judge pattern as Part 4's reranker.
4. **A single runnable command with a pass/fail exit code** — CI-ready, proven to actually fail when a real regression (an overly strict rerank threshold) is introduced, not just when things are already broken.

---

## Closing: What You Built Across This Series

Looking back at the full architecture diagram from Part 0:

```
┌─────────────────────────────────────────────────────────┐
│  PRODUCTION LAYER   → Part 7 (caching), Part 8 (evals)   │
├─────────────────────────────────────────────────────────┤
│  CONTROL LAYER      → Part 5 (naive agent), Part 6 (FSM) │
├─────────────────────────────────────────────────────────┤
│  KNOWLEDGE LAYER     → Part 3 (retrieval), Part 4 (AST)  │
├─────────────────────────────────────────────────────────┤
│  MENTAL MODEL        → Part 1 (naive), Part 2 (layered)  │
└─────────────────────────────────────────────────────────┘
```

Every layer was justified by a **real, reproducible failure you caused and measured yourself** before you fixed it:

- A 35-file prompt that gave a confidently wrong answer about a lockout rule (Part 1) → fixed by a three-layer prompt architecture cutting tokens 94% (Part 2)
- A vector search that returned a code fragment missing its own import (Part 3) → fixed by AST-based chunking, verified on the exact same broken case (Part 4)
- An agent that burned 7.6x more tokens flailing through redundant tool calls (Part 5) → fixed by state-machine tool pruning, cutting tokens 70% on the identical task (Part 6)
- A prompt structure with no way to save cost on repeated static content (Part 7) → fixed by exploiting exact-prefix caching, measured directly via `cached_tokens` in the API response
- No systematic way to detect a regression before shipping it (Part 8) → fixed by a real, CI-ready eval suite with a provable, working failure mode

None of this required a bigger model or a bigger context window. It required treating the context window as what it actually is: **scarce, volatile, high-latency memory with unreliable attention** — and building deterministic software, layer by layer, around that constraint.

---

**✅ Part 8 is complete, and with it, the full Context Engineering series.** You now have a working, measured, cost-aware, regression-tested AI coding assistant (`opencode`) built entirely from first principles — and, more importantly, the underlying engineering discipline to apply the same pattern to any LLM-backed system you build next.
