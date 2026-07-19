# Phase 3: Advanced Retrieval Architectures: Agentic & Vectorless RAG

## Phase 3, Part 1: Traditional vs. Agentic RAG — Building the Vectorless Retrieval Foundation

### The Target

We're giving our agent a genuine knowledge source to search, instead of relying purely on whatever facts happen to be baked into the model's training data. We'll build a small structured **knowledge base** (a JSON file of company-policy-style documents), a **vectorless search function** that ranks those documents by relevance to a query using plain scoring logic (no embeddings, no vector database), and wire it in as a new tool the ReAct loop can call — `searchKnowledgeBase`.

### The Concept

**RAG** stands for **Retrieval-Augmented Generation** — the general idea of fetching relevant external information and handing it to the model as context, rather than trusting the model to already "know" the answer. It exists because language models have two fundamental limitations: their training data has a cutoff date, and they have no visibility at all into *your* private data (your company's policies, your database records, your documents) unless you explicitly hand it to them at request time.

The most common implementation of RAG uses **vector embeddings**: you convert every document into a list of numbers (a vector) that captures its *meaning*, convert the user's query into a vector the same way, and then find documents whose vectors are mathematically "close" to the query's vector — even if they don't share any exact words. This is genuinely powerful for large, unstructured text corpora (think: millions of support tickets, or a whole library of PDFs) where meaning-based matching across huge scale is the whole point.

But here's the thing most tutorials skip: **building and maintaining a vector pipeline is real infrastructure** — you need an embedding model, a vector database, a re-indexing strategy for when documents change, and it all adds latency and cost. If your actual data is a few dozen structured JSON records, a small config table, or a handful of well-organized key-value entries, running the full vector machinery is like hiring a professional research librarian with a card-catalog system to help you find a book on a shelf that only has twelve books on it — you could just *look at the shelf*. That's the essence of **vectorless retrieval**: when the underlying data is small, structured, or naturally key-value/tag-shaped, a well-designed direct scoring/filtering search is often faster, cheaper, easier to debug, and just as accurate as a full embedding pipeline — no less "real" a retrieval strategy for being simpler.

The second idea in this part's title — **"Traditional vs. Agentic RAG"** — is about *when* the search happens and who's in control of it. Traditional RAG is typically a single, fixed step wired directly into the pipeline: query comes in, search runs exactly once, top results get stuffed into the prompt, model answers. There's no judgment involved — the system doesn't ask "was that search actually good?" It just proceeds regardless. In this Part, we're only building the foundation — the search tool itself — using that traditional, single-shot pattern, wired into our existing ReAct loop as just another tool the agent can call. In Part 2, we'll upgrade this into genuinely **agentic** RAG, where the agent itself judges whether the search results were actually good enough, and rewrites its query and tries again if not — exactly the kind of judgment a traditional fixed pipeline lacks.

### The Implementation

#### Step 1 — Create a small, structured knowledge base

**File: `lib/data/knowledgeBase.json`**
```json
[
  {
    "id": "refund-policy",
    "title": "Refund Policy",
    "tags": ["refund", "money-back", "returns", "billing"],
    "content": "Customers may request a full refund within 30 days of purchase, provided the product is unused and in its original packaging. Refunds are processed within 5-7 business days to the original payment method. Digital products and gift cards are non-refundable except where required by local law."
  },
  {
    "id": "shipping-policy",
    "title": "Shipping Policy",
    "tags": ["shipping", "delivery", "tracking"],
    "content": "Standard shipping takes 5-8 business days within the continental US. Express shipping (2-3 business days) is available for an additional fee at checkout. Tracking numbers are emailed automatically once an order ships. International shipping times vary by destination and customs processing."
  },
  {
    "id": "password-reset",
    "title": "Password Reset Procedure",
    "tags": ["password", "account", "login", "security"],
    "content": "Users can reset their password from the login page by clicking 'Forgot Password' and entering their registered email address. A reset link is valid for 15 minutes. If the link expires, users must request a new one. After 5 failed login attempts, accounts are temporarily locked for 30 minutes as a security measure."
  },
  {
    "id": "vacation-policy",
    "title": "Employee Vacation Policy",
    "tags": ["vacation", "pto", "time-off", "hr"],
    "content": "Full-time employees accrue 15 days of paid vacation per year, credited monthly. Unused vacation days roll over up to a maximum of 5 days into the following year. Vacation requests must be submitted at least 2 weeks in advance through the HR portal and require manager approval."
  },
  {
    "id": "office-hours",
    "title": "Office Hours and Support Availability",
    "tags": ["hours", "support", "contact", "availability"],
    "content": "Customer support is available Monday through Friday, 9 AM to 6 PM Eastern Time, excluding federal holidays. Live chat responses typically arrive within 10 minutes during business hours. Email support tickets are answered within 24 hours on business days."
  }
]
```

> **Why JSON on disk, rather than a database, for this part?** We're isolating the *retrieval logic* from *storage infrastructure* concerns on purpose — the scoring/ranking algorithm we're about to write doesn't care whether the raw documents came from a JSON file, a database table, or an API response; it only cares that it receives an array of `{ id, title, tags, content }` objects. This keeps the part focused on the retrieval pattern itself. Swapping this file for a real database query later is a one-function change, not a rewrite.

#### Step 2 — The vectorless search engine

**File: `lib/agent/retrieval/vectorlessSearch.js`**
```js
import knowledgeBase from '@/lib/data/knowledgeBase.json';

// A small, deliberately conservative stopword list — common English words
// that carry little search-relevance signal on their own, so we exclude
// them from scoring to avoid every document matching on words like "the".
const STOPWORDS = new Set([
  'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'to', 'of',
  'and', 'or', 'for', 'in', 'on', 'at', 'my', 'what', 'how', 'do', 'does',
  'i', 'me', 'can', 'you', 'it', 'this', 'that',
]);

/**
 * Breaks a string into lowercase, stopword-filtered word tokens.
 * This is intentionally simple — no stemming, no lemmatization — because
 * our knowledge base is small enough that exact/near-exact keyword overlap
 * is a perfectly reliable relevance signal. If your real corpus grows large
 * or vocabulary-diverse enough that this stops being true, that's precisely
 * the signal to consider adding a vector-embedding-based layer alongside
 * (not necessarily instead of) this one — see the Reference Section for
 * a discussion of hybrid approaches.
 */
function tokenize(text) {
  return String(text)
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ') // strip punctuation down to plain words
    .split(/\s+/)
    .filter((word) => word.length > 1 && !STOPWORDS.has(word));
}

/**
 * Scores a single document against a query's tokens using a simple,
 * transparent weighted-overlap heuristic:
 *   - A query word found in the document's `tags` scores highest (tags are
 *     curated, high-signal metadata — an exact match there is very strong
 *     evidence of relevance).
 *   - A query word found in the `title` scores moderately.
 *   - A query word found in the `content` body scores lowest per occurrence,
 *     but accumulates with repeated mentions.
 * This is deliberately explainable — you can look at any score and trace
 * exactly which words contributed to it, which matters a lot for debugging
 * "why did the agent retrieve THIS document" during development.
 */
function scoreDocument(doc, queryTokens) {
  const titleTokens = tokenize(doc.title);
  const contentTokens = tokenize(doc.content);
  const tagTokens = doc.tags.map((t) => t.toLowerCase());

  let score = 0;
  const matchedOn = { tags: [], title: [], content: 0 };

  for (const qToken of queryTokens) {
    if (tagTokens.includes(qToken)) {
      score += 5;
      matchedOn.tags.push(qToken);
    }
    if (titleTokens.includes(qToken)) {
      score += 3;
      matchedOn.title.push(qToken);
    }
    const contentOccurrences = contentTokens.filter((t) => t === qToken).length;
    if (contentOccurrences > 0) {
      score += contentOccurrences * 1;
      matchedOn.content += contentOccurrences;
    }
  }

  return { score, matchedOn };
}

/**
 * The main exported search function. Ranks every document in the knowledge
 * base against the query and returns the top N matches above a minimum
 * relevance threshold — documents that score 0 (no keyword overlap at all)
 * are excluded entirely, rather than padding results with irrelevant noise.
 */
export function searchKnowledgeBase(query, { topN = 3, minScore = 1 } = {}) {
  const queryTokens = tokenize(query);

  if (queryTokens.length === 0) {
    return { query, results: [], note: 'Query contained no searchable terms after filtering.' };
  }

  const scored = knowledgeBase
    .map((doc) => {
      const { score, matchedOn } = scoreDocument(doc, queryTokens);
      return { doc, score, matchedOn };
    })
    .filter((entry) => entry.score >= minScore)
    .sort((a, b) => b.score - a.score) // highest relevance first
    .slice(0, topN);

  return {
    query,
    results: scored.map((entry) => ({
      id: entry.doc.id,
      title: entry.doc.title,
      content: entry.doc.content,
      relevanceScore: entry.score,
      matchedOn: entry.matchedOn,
    })),
  };
}
```

> **Why compute and return `matchedOn`?** Beyond just the numeric score, we surface *which specific words matched, and where* (tags vs. title vs. content). This is enormously valuable for debugging — when you later ask "why did my agent think the vacation policy was relevant to a question about refunds," you can look directly at `matchedOn` and see exactly which token caused the match, rather than treating the scoring function as an unexplainable black box.

#### Step 3 — Register the search function as a new tool

Update the shared tool registry to add `searchKnowledgeBase` alongside our existing `calculator` and `getCurrentTime` tools.

**File: `lib/agent/tools.js`** *(full updated file)*
```js
import { searchKnowledgeBase } from './retrieval/vectorlessSearch.js';

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

  // NEW: gives the agent the ability to search our internal knowledge base
  // for policy/documentation content, instead of relying solely on
  // whatever the model happened to memorize during training.
  searchKnowledgeBase: async (input) => {
    const query = String(input ?? '').trim();
    if (!query) {
      return { error: 'searchKnowledgeBase requires a non-empty query string as action_input.' };
    }
    const { results, note } = searchKnowledgeBase(query, { topN: 3, minScore: 1 });
    if (results.length === 0) {
      return {
        found: false,
        message: note || 'No relevant documents found in the knowledge base for this query.',
      };
    }
    return {
      found: true,
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
    description: 'Searches internal company policy documents (refunds, shipping, passwords, vacation, support hours) for relevant information.',
    inputHint: 'A search query string, e.g. "how long do refunds take"',
  },
];
```

Because both `TOOLS` and `TOOL_METADATA` live in this single shared file, and both `reactLoop.js` and `systemPrompt.js` already import from it, **no other file needs to change** for the agent to gain this new capability — the system prompt will automatically describe the new tool, and the loop will automatically be able to execute it. This is the direct payoff of the single-source-of-truth registry pattern we set up back in Phase 2.

### The Verification

#### Test 1 — Unit-test the search function directly

**File: `app/api/agent/search-test/route.js`**
```js
import { NextResponse } from 'next/server';
import { searchKnowledgeBase } from '@/lib/agent/retrieval/vectorlessSearch.js';

export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const query = searchParams.get('q') || 'how do I reset my password';

  const result = searchKnowledgeBase(query, { topN: 3, minScore: 1 });
  return NextResponse.json(result);
}
```

Run it:
```bash
curl -s "http://localhost:3000/api/agent/search-test?q=how%20long%20does%20shipping%20take" | python3 -m json.tool
```

**Expected output** — the Shipping Policy document should rank first, with `matchedOn.tags` showing `"shipping"` as a direct hit:
```json
{
    "query": "how long does shipping take",
    "results": [
        {
            "id": "shipping-policy",
            "title": "Shipping Policy",
            "content": "Standard shipping takes 5-8 business days...",
            "relevanceScore": 8,
            "matchedOn": {
                "tags": ["shipping"],
                "title": ["shipping"],
                "content": 1
            }
        }
    ]
}
```

Try a query with zero relevant matches, to confirm the empty-result path works correctly:
```bash
curl -s "http://localhost:3000/api/agent/search-test?q=what%20is%20the%20weather%20like%20on%20mars" | python3 -m json.tool
```
Expected: `"results": []` — correctly returning nothing rather than forcing an irrelevant top match onto the caller.

#### Test 2 — Confirm the ReAct loop can use the new tool end-to-end

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "How many days do I have to request a refund, and is it a full refund?"}' \
  | python3 -m json.tool
```

**Expected behavior:** the `trace` array should show a step where `action` is `"searchKnowledgeBase"` with an `action_input` like `"refund policy days"`, followed by an observation containing the Refund Policy document's content, and a final answer stating **30 days** and confirming it's a **full refund** (assuming original packaging and unused condition) — information that exists only in our `knowledgeBase.json` file, not in the model's general training data. This is proof the agent is genuinely grounding its answer in retrieved data rather than guessing.

Once both tests pass — the search function correctly ranks and filters documents in isolation, and the full agent correctly chooses to invoke it and grounds its final answer in the real retrieved content — you have a working, vectorless RAG foundation wired directly into your existing reasoning loop, ready to be upgraded with judgment and self-correction in the next part.
