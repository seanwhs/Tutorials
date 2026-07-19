# Phase 3, Part 2: Upgrading to Agentic RAG — Query Rewriting & Self-Judged Retrieval

## The Target

The `searchKnowledgeBase` tool from Part 1 is a classic **traditional RAG** step: it runs once, returns whatever it finds, and blindly hands that back to the agent — even if the results are weak, off-topic, or based on a poorly-phrased query. In this part, we build `lib/agent/retrieval/agenticRetrieve.js`, a self-contained retrieval loop that **judges its own search quality** using the model itself, and — if the results are judged insufficient — **rewrites the query** and tries again, up to a small retry budget. We then swap this in as the engine behind our `searchKnowledgeBase` tool, so the upgrade is transparent to the outer ReAct loop.

## The Concept

Imagine two different research assistants. The first one — traditional RAG — searches your request exactly as typed, hands you the top three results from the shelf, and walks away, regardless of whether those results actually answer your question. The second — agentic RAG — searches, *looks at what came back*, asks themselves "does this actually answer what was asked, or did I just retrieve the closest-sounding but wrong shelf?", and if the answer is "this isn't good enough," they rephrase the search in their head and try again before ever bringing you anything.

That second behavior — **retrieve, judge, rewrite, retry** — is what separates agentic RAG from traditional RAG. It directly addresses a very real failure mode: users often phrase questions in ways that don't share vocabulary with the source documents. Someone might ask *"can I get my money back?"* when our knowledge base document is titled "Refund Policy" and tagged with `refund`, `money-back`, `returns`, `billing` — our simple keyword-overlap search might miss this if the exact word "refund" or a tagged synonym never appears in the query. A traditional pipeline would just return nothing (or worse, an irrelevant document) and give up. An agentic pipeline notices the retrieval was weak, rewrites the query to something more likely to match the actual vocabulary in the corpus (e.g., "refund money-back policy return"), and searches again.

This is a small, self-contained instance of the exact same ReAct pattern from Phase 1 — Think (judge the results) → Act (rewrite and re-search) → Observe (new results) — just scoped specifically to the retrieval problem rather than the whole user goal. It's a great illustration of how the ReAct pattern isn't a single, one-off thing we built in Phase 1 — it's a *reusable shape* you can nest inside any sub-problem that benefits from iterative self-correction.

## The Implementation

### Step 1 — A judge function: does this retrieval actually answer the question?

We use a small, focused, low-temperature model call whose *only* job is to output a structured verdict — not to answer the user's question itself.

**File: `lib/agent/retrieval/judgeRetrieval.js`**
```js
import Groq from 'groq-sdk';
import { completionWithTimeout } from '../timeoutCompletion.js';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || '' });

const JUDGE_SYSTEM_PROMPT = `
You are a strict retrieval quality judge. You will be given a user's original
question and a set of search results retrieved from a knowledge base.

Your ONLY job is to decide whether these results contain enough information
to properly answer the question. You do not answer the question yourself.

Respond with a single JSON object, and nothing else, in this exact shape:
{
  "sufficient": <true or false>,
  "reasoning": "<one short sentence explaining your verdict>",
  "improvedQuery": "<if insufficient, a rewritten search query more likely to find relevant results; otherwise an empty string>"
}

Be strict: if the results are only loosely related, tangential, or missing
the specific detail the question asks for, mark sufficient as false.
`.trim();

/**
 * Judges whether a set of retrieved documents sufficiently answers the
 * original question, and if not, proposes a rewritten query.
 */
export async function judgeRetrieval(originalQuery, searchResults) {
  const resultsSummary = searchResults.length === 0
    ? 'No results were found at all.'
    : searchResults.map((r, i) => `${i + 1}. [${r.title}] ${r.content}`).join('\n');

  try {
    const completion = await completionWithTimeout(
      groq,
      {
        model: 'llama-3.3-70b-versatile',
        messages: [
          { role: 'system', content: JUDGE_SYSTEM_PROMPT },
          {
            role: 'user',
            content: `Original question: "${originalQuery}"\n\nRetrieved results:\n${resultsSummary}`,
          },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.1, // we want a consistent, decisive judge, not a creative one
      },
      10000
    );

    const raw = completion.choices[0]?.message?.content ?? '{}';
    const parsed = JSON.parse(raw);

    return {
      sufficient: Boolean(parsed.sufficient),
      reasoning: String(parsed.reasoning || ''),
      improvedQuery: String(parsed.improvedQuery || ''),
    };
  } catch (error) {
    // FAIL-SAFE DEFAULT: if the judge itself fails (bad JSON, timeout, etc.),
    // we default to "sufficient: true" rather than risking an infinite
    // retry cycle caused by a broken judge. Better to hand back imperfect
    // real results than to loop forever chasing a perfect judgment.
    console.error('[judgeRetrieval] Judge call failed, defaulting to sufficient=true:', error);
    return { sufficient: true, reasoning: 'Judge unavailable; defaulting to accept.', improvedQuery: '' };
  }
}
```

> **Why default to `sufficient: true` on failure, rather than `false`?** This is a deliberate fail-safe design decision. If the judge itself breaks and we defaulted to `false`, we'd trigger a retry — and if the judge keeps failing, we could burn through our entire retry budget on judge failures rather than genuine retrieval quality issues, ultimately still returning to the caller no better off, just slower and more expensive. Defaulting to "accept what we have" fails toward *availability* over *strictness* — a reasonable trade-off for a retrieval quality gate, though not universally correct for every guardrail (compare this to Phase 4, where security guardrails will default to the opposite: fail closed, not open, when in doubt).

### Step 2 — The agentic retrieval loop itself

**File: `lib/agent/retrieval/agenticRetrieve.js`**
```js
import { searchKnowledgeBase } from './vectorlessSearch.js';
import { judgeRetrieval } from './judgeRetrieval.js';

const MAX_RETRIEVAL_ATTEMPTS = 3;

/**
 * The full agentic retrieval loop: search, judge, and — if the judge deems
 * the results insufficient — rewrite the query and try again, up to a
 * bounded number of attempts. Returns the best available results along
 * with a full attempt trace, so callers (and our own debugging) can see
 * exactly how many tries it took and why.
 */
export async function agenticRetrieve(originalQuery) {
  let currentQuery = originalQuery;
  const attempts = [];

  for (let attempt = 1; attempt <= MAX_RETRIEVAL_ATTEMPTS; attempt++) {
    const { results } = searchKnowledgeBase(currentQuery, { topN: 3, minScore: 1 });

    const verdict = await judgeRetrieval(originalQuery, results);

    attempts.push({
      attempt,
      queryUsed: currentQuery,
      resultCount: results.length,
      resultTitles: results.map((r) => r.title),
      judgeVerdict: verdict,
    });

    // Stop as soon as the judge is satisfied — no reason to keep searching
    // once we have what we need. This mirrors the ReAct loop's final_answer
    // short-circuit from Phase 1: stop the instant the goal is met.
    if (verdict.sufficient) {
      return {
        results,
        finalQueryUsed: currentQuery,
        attemptsTaken: attempt,
        attempts,
        stopReason: 'judged_sufficient',
      };
    }

    // If the judge thinks results are insufficient but didn't propose a
    // usable rewritten query, we have nothing productive to change — stop
    // here rather than retrying with an identical, already-failed query.
    if (!verdict.improvedQuery || verdict.improvedQuery.trim() === currentQuery.trim()) {
      return {
        results,
        finalQueryUsed: currentQuery,
        attemptsTaken: attempt,
        attempts,
        stopReason: 'no_improved_query_available',
      };
    }

    // Otherwise, adopt the judge's rewritten query and loop again.
    currentQuery = verdict.improvedQuery;
  }

  // Exhausted our retry budget — return whatever the LAST attempt found,
  // rather than nothing. Even an imperfect result is more useful to the
  // outer agent than an empty-handed failure.
  const lastAttempt = attempts[attempts.length - 1];
  const { results } = searchKnowledgeBase(lastAttempt.queryUsed, { topN: 3, minScore: 1 });
  return {
    results,
    finalQueryUsed: lastAttempt.queryUsed,
    attemptsTaken: MAX_RETRIEVAL_ATTEMPTS,
    attempts,
    stopReason: 'max_attempts_exhausted',
  };
}
```

Notice this function has its own three deterministic stopping conditions — `judged_sufficient`, `no_improved_query_available`, and `max_attempts_exhausted` — echoing the exact same "always terminate deterministically" discipline from Phase 1, Part 3. Every loop we build in this course, no matter how small or specialized, gets this same guarantee: it cannot run forever, and it always returns something usable.

### Step 3 — Swap the tool to use agentic retrieval instead of raw search

```js
import { agenticRetrieve } from './retrieval/agenticRetrieve.js';

export const TOOLS = {
  calculator: async (input) => {
    const expression = String(input ?? '');
    const isSafeExpression = /^[0-9+\-*/().\s]+$/.test(expression);
    if (!isSafeExpression) {
      return { error: `Rejected unsafe expression: "${expression}"` };
    }
    try {
      const result = new Function(`return (${expression});`)();
      return { result };
    } catch (err) {
      return { error: `Could not evaluate expression: ${err.message}` };
    }
  },

  getCurrentTime: async () => {
    return { isoTimestamp: new Date().toISOString() };
  },

  // UPGRADED: this tool now runs the full agentic retrieval loop —
  // search, judge, rewrite, retry — instead of a single fixed search pass.
  // The outer ReAct loop calling this tool doesn't need to know or care
  // about that internal complexity; it still just calls one tool and gets
  // one observation back, exactly like before. This is intentional —
  // agentic RAG is an implementation detail hidden BEHIND the tool
  // interface, not a change to the outer loop's contract.
  searchKnowledgeBase: async (input) => {
    const query = String(input ?? '').trim();
    if (!query) {
      return { error: 'searchKnowledgeBase requires a non-empty query string as action_input.' };
    }

    const { results, finalQueryUsed, attemptsTaken, stopReason } = await agenticRetrieve(query);

    if (results.length === 0) {
      return {
        found: false,
        message: `No relevant documents found after ${attemptsTaken} attempt(s) (final query: "${finalQueryUsed}").`,
      };
    }

    return {
      found: true,
      // Surface retrieval metadata transparently — this is genuinely useful
      // for the outer agent's own reasoning (e.g. it can mention "I had to
      // refine my search" if relevant) and invaluable for our own debugging.
      retrievalMeta: { attemptsTaken, finalQueryUsed, stopReason },
      results: results.map((r) => ({ title: r.title, content: r.content, relevanceScore: r.relevanceScore })),
    };
  },
};

export const TOOL_METADATA = [
  {
    name: 'calculator',
    description: 'Evaluates a basic arithmetic expression.',
    inputHint: 'A string like "42 * 17"',
  },
  {
    name: 'getCurrentTime',
    description: 'Returns the current UTC timestamp.',
    inputHint: 'An empty string',
  },
  {
    name: 'searchKnowledgeBase',
    description: 'Searches internal company policy documents (refunds, shipping, passwords, vacation, support hours) for relevant information. Automatically retries with improved queries if initial results are weak.',
    inputHint: 'A search query string, e.g. "how long do refunds take"',
  },
];
```

Once again, because both the ReAct loop and the system prompt only ever interact with `TOOLS.searchKnowledgeBase` as a single async function — never with `agenticRetrieve` or `judgeRetrieval` directly — this upgrade is a **drop-in replacement**. Nothing in `reactLoop.js`, `systemPrompt.js`, or either route handler needed to change at all. This is the tool-interface decoupling principle paying real, tangible dividends already, well before we formalize it further in Phase 5.

### The Verification

#### Test 1 — Directly exercise the agentic retrieval loop with a deliberately mismatched query

Build a diagnostic endpoint that lets us watch the full attempt trace, so we can *see* the rewrite-and-retry behavior happen, rather than just trust it.

**File: `app/api/agent/agentic-retrieve-test/route.js`**
```js
import { NextResponse } from 'next/server';
import { agenticRetrieve } from '@/lib/agent/retrieval/agenticRetrieve.js';

export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const query = searchParams.get('q') || 'can I get my money back';

  const result = await agenticRetrieve(query);
  return NextResponse.json(result);
}
```

Run it with a query that deliberately avoids the exact vocabulary in our knowledge base (`"refund"`), to force the judge to notice a mismatch and rewrite:

```bash
curl -s "http://localhost:3000/api/agent/agentic-retrieve-test?q=can%20I%20get%20my%20money%20back" | python3 -m json.tool
```

**Expected behavior** (exact wording of `reasoning`/`improvedQuery` will vary, since these are model-generated, but the *shape* should match):

```json
{
    "finalQueryUsed": "refund policy money back returns",
    "attemptsTaken": 2,
    "attempts": [
        {
            "attempt": 1,
            "queryUsed": "can I get my money back",
            "resultCount": 1,
            "resultTitles": ["Refund Policy"],
            "judgeVerdict": {
                "sufficient": true,
                "reasoning": "The retrieved refund policy directly addresses getting money back.",
                "improvedQuery": ""
            }
        }
    ],
    "stopReason": "judged_sufficient"
}
```

*(Note: depending on how well our keyword-overlap search happens to match "money back" against the "money-back" tag already in the knowledge base, you may see it succeed on attempt 1 — that's a perfectly valid and expected outcome, since our tags file was deliberately designed with common synonyms included. To reliably force a multi-attempt retry for verification purposes, try an even more indirect query:)*

```bash
curl -s "http://localhost:3000/api/agent/agentic-retrieve-test?q=I%20am%20locked%20out%20and%20cant%20get%20back%20in" | python3 -m json.tool
```

This phrasing avoids the words "password," "login," and "account" entirely, which should more reliably force the judge to reject a weak or empty first-pass result and propose a rewritten query like `"password reset login account locked"` — confirm your output shows `attemptsTaken` of 2 or more, with the `attempts` array showing an initial `sufficient: false` verdict followed by a later `sufficient: true` verdict once the rewritten query lands on the Password Reset Procedure document.

#### Test 2 — Confirm the full ReAct loop still works, now backed by agentic retrieval

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "I forgot my password and keep getting locked out, what should I do?"}' \
  | python3 -m json.tool
```

**Expected behavior:** the trace should show a `searchKnowledgeBase` action, and the observation for that step should now include a `retrievalMeta` object showing `attemptsTaken` and `finalQueryUsed` — confirming the outer loop is transparently benefiting from the upgraded retrieval logic underneath, without any changes needed at the outer-loop level. The `finalAnswer` should correctly describe the password reset procedure, including the 15-minute link expiry and 5-failed-attempts lockout details from our knowledge base.

Once both tests pass, you've built and verified genuine agentic RAG: a retrieval process that doesn't just fetch and forget, but actively evaluates its own output quality and iteratively improves its search strategy — all cleanly hidden behind the exact same tool interface the rest of your system already relies on.
**File: `lib/agent/tools.js`** *(updated — only the `searchKnowledgeBase` tool entry changes)*
```js
import { agentic
