# Phase 3, Part 3: Vectorless Retrieval Over Key-Value & API-Backed Sources

## The Target

So far our retrieval layer only touches one kind of source: a static JSON file of documents. Real systems almost always need to pull from **multiple, structurally different backends** in the same request — a live order-status lookup keyed by ID (a key-value pattern), and a simulated third-party API (a shipping carrier's tracking service). In this part, we build two new tools — `lookupOrderStatus` and `trackShipment` — that demonstrate vectorless retrieval over fundamentally different data shapes than our document-search case, and we teach the agent, via its system prompt, to choose the *right* retrieval tool for the *right* kind of question.

## The Concept

It's worth being precise about what "vectorless retrieval" actually spans, because it's easy to think of it as only meaning "keyword search over documents" — that was just our Part 1 example. The real defining trait of vectorless retrieval is **direct, structured access suited to the shape of the underlying data**, as opposed to converting everything into embeddings and searching by similarity regardless of shape. Different data shapes call for genuinely different direct access patterns:

- **Document search** (Part 1/2): unstructured prose, ranked by relevance — keyword/tag scoring is the right tool.
- **Key-value lookup** (this part, `lookupOrderStatus`): you have an exact identifier (an order ID) and you want an exact record — there's no "relevance ranking" needed at all here; it's a direct dictionary lookup, like looking up a word in an actual dictionary by its exact spelling rather than "searching" for it.
- **Live API calls** (this part, `trackShipment`): the data doesn't live in your system at all — it lives behind a third party's API, and "retrieval" means making a real-time network call and shaping the response, not searching anything you already hold.

The engineering lesson here: **don't force every retrieval problem through the same mechanism just because you have a working search function.** A key-value lookup wrapped in a "relevance scoring" search would be needlessly slow and could even introduce ambiguity (what if a fuzzy match returns the *wrong* order?) where a direct, exact lookup is faster, cheaper, and unambiguous. Part of building a mature agentic system is recognizing which retrieval shape a given tool actually needs, rather than reflexively building "one big search function" for everything.

The other concept this part reinforces: **the agent itself must be taught, through tool descriptions, which tool fits which kind of question.** This is why our `TOOL_METADATA` descriptions matter so much — they're not just documentation for humans, they're the *only* signal the model has for choosing correctly between "search the knowledge base" vs. "look up this exact order" vs. "call the tracking API." Vague or overlapping tool descriptions lead directly to the model picking the wrong tool; specific, differentiated descriptions are a real engineering lever you control.

## The Implementation

### Step 1 — A simulated key-value order store

**File: `lib/data/orders.json`**
```json
{
  "ORD-1001": { "customerName": "Jane Rivera", "status": "delivered", "deliveredOn": "2025-04-02", "itemCount": 3 },
  "ORD-1002": { "customerName": "Marcus Chen", "status": "in_transit", "estimatedDelivery": "2025-05-20", "itemCount": 1 },
  "ORD-1003": { "customerName": "Priya Nair", "status": "processing", "estimatedShipDate": "2025-05-18", "itemCount": 5 },
  "ORD-1004": { "customerName": "Tom Okafor", "status": "cancelled", "cancelledOn": "2025-04-28", "itemCount": 2 }
}
```

**File: `lib/agent/retrieval/orderLookup.js`**
```js
import orders from '@/lib/data/orders.json';

/**
 * A pure key-value lookup — no ranking, no scoring, no "closest match".
 * Either the exact order ID exists, or it doesn't. This is deliberately
 * the SIMPLEST possible retrieval function in the whole course, because
 * that simplicity is exactly the right fit for this data shape.
 */
export function lookupOrderStatus(orderId) {
  const normalizedId = String(orderId ?? '').trim().toUpperCase();

  if (!normalizedId) {
    return { error: 'An order ID is required, e.g. "ORD-1001".' };
  }

  const record = orders[normalizedId];
  if (!record) {
    // We deliberately do NOT try to "fuzzy match" a typo'd order ID here —
    // returning the wrong order's data because it superficially resembles
    // the requested ID would be a serious correctness bug, not a helpful
    // feature. When in doubt for exact-identifier lookups, fail clearly.
    return { found: false, message: `No order found with ID "${normalizedId}".` };
  }

  return { found: true, orderId: normalizedId, ...record };
}
```

### Step 2 — A simulated external API call (shipment tracking)

In a real system, this would be a genuine `fetch()` call to a shipping carrier's API. We simulate the network round-trip explicitly (including a realistic delay and the possibility of failure) so the pattern you learn here transfers directly to a real integration later — only the body of `fetchFromCarrierApi` would need to change.

**File: `lib/agent/retrieval/shipmentTracking.js`**
```js
/**
 * Simulates a real third-party carrier tracking API call. In production,
 * this function's BODY would be replaced with a genuine `fetch()` call to
 * the carrier's real endpoint — everything calling INTO this function
 * (the tool wrapper below) would not need to change at all, since the
 * function's return shape is what matters to the rest of the system, not
 * its internal implementation.
 */
async function fetchFromCarrierApi(trackingNumber) {
  // Simulate realistic network latency.
  await new Promise((resolve) => setTimeout(resolve, 250));

  // Simulate a small, deterministic "database" of tracking numbers, keyed
  // by a simple pattern, so results are reproducible for testing purposes.
  const knownTrackingNumbers = {
    TRK-9001: { carrier: 'FastShip', status: 'out_for_delivery', lastLocation: 'Local distribution center' },
    TRK-9002: { carrier: 'FastShip', status: 'in_transit', lastLocation: 'Regional hub, Denver CO' },
  };

  const normalized = String(trackingNumber ?? '').trim().toUpperCase();
  const record = knownTrackingNumbers[normalized];

  if (!record) {
    // Simulate the carrier API's own "not found" response shape.
    return { ok: false, statusCode: 404, body: null };
  }

  return { ok: true, statusCode: 200, body: { trackingNumber: normalized, ...record } };
}

/**
 * The tool-facing wrapper: calls the (simulated) external API and shapes
 * its response into our system's consistent observation format, including
 * proper handling of the "not found" and unexpected-failure cases.
 */
export async function trackShipment(trackingNumber) {
  const normalized = String(trackingNumber ?? '').trim();
  if (!normalized) {
    return { error: 'A tracking number is required, e.g. "TRK-9001".' };
  }

  try {
    const response = await fetchFromCarrierApi(normalized);

    if (!response.ok) {
      return { found: false, message: `No tracking information found for "${normalized}".` };
    }

    return { found: true, ...response.body };
  } catch (error) {
    // A genuine network/API failure (in a real integration: DNS failure,
    // carrier API downtime, etc.) is handled distinctly from a clean
    // "not found" response — this distinction matters for the agent's
    // own reasoning (a temporary outage vs. a genuinely invalid number).
    return { error: `Carrier tracking service unavailable: ${error.message}` };
  }
}
```

### Step 3 — Register both new tools

**File: `lib/agent/tools.js`** *(full updated file)*
```js
import { agenticRetrieve } from './retrieval/agenticRetrieve.js';
import { lookupOrderStatus } from './retrieval/orderLookup.js';
import { trackShipment } from './retrieval/shipmentTracking.js';

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
      retrievalMeta: { attemptsTaken, finalQueryUsed, stopReason },
      results: results.map((r) => ({ title: r.title, content: r.content, relevanceScore: r.relevanceScore })),
    };
  },

  // NEW: exact key-value lookup, distinct in kind from document search above.
  lookupOrderStatus: async (input) => {
    return lookupOrderStatus(input);
  },

  // NEW: simulated live third-party API call.
  trackShipment: async (input) => {
    return trackShipment(input);
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
    description: 'Searches internal company POLICY documents (general rules about refunds, shipping, passwords, vacation, support hours). Use this for questions about RULES and POLICIES in general — NOT for looking up a specific customer\'s order or a specific tracking number.',
    inputHint: 'A search query string, e.g. "how long do refunds take"',
  },
  {
    name: 'lookupOrderStatus',
    description: 'Looks up the EXACT current status of a SPECIFIC order by its order ID. Use this when the user provides (or you already know) a specific order ID like "ORD-1001". Do NOT use this for general questions about shipping policy — use searchKnowledgeBase for that instead.',
    inputHint: 'An exact order ID string, e.g. "ORD-1001"',
  },
  {
    name: 'trackShipment',
    description: 'Calls the external shipping carrier API to get real-time tracking status for a SPECIFIC tracking number. Use this only when the user provides a tracking number like "TRK-9001". This is a live external API call, distinct from lookupOrderStatus (which checks our own internal order records, not the carrier).',
    inputHint: 'An exact tracking number string, e.g. "TRK-9001"',
  },
];
```

Notice how deliberately differentiated these four descriptions are now, especially the three retrieval-related ones. Each description explicitly states not just what the tool *does*, but what it should **not** be used for, and how it differs from its closest sibling tool. This is a direct, practical response to the concept discussed above: since tool descriptions are the *only* signal the model uses to disambiguate between similar-sounding capabilities, vague descriptions ("searches for information") would leave the model guessing between `searchKnowledgeBase` and `lookupOrderStatus` on any order-related question — explicit, contrastive descriptions remove that ambiguity directly at the source.

### The Verification

#### Test 1 — Confirm the key-value lookup tool works correctly in isolation

**File: `app/api/agent/order-test/route.js`**
```js
import { NextResponse } from 'next/server';
import { lookupOrderStatus } from '@/lib/agent/retrieval/orderLookup.js';

export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const orderId = searchParams.get('id') || 'ORD-1002';
  return NextResponse.json(lookupOrderStatus(orderId));
}
```

```bash
curl -s "http://localhost:3000/api/agent/order-test?id=ORD-1002" | python3 -m json.tool
```
Expected:
```json
{
    "found": true,
    "orderId": "ORD-1002",
    "customerName": "Marcus Chen",
    "status": "in_transit",
    "estimatedDelivery": "2025-05-20",
    "itemCount": 1
}
```

Confirm the "not found" path behaves correctly with a nonexistent ID:
```bash
curl -s "http://localhost:3000/api/agent/order-test?id=ORD-9999" | python3 -m json.tool
```
Expected: `{"found": false, "message": "No order found with ID \"ORD-9999\"."}`

#### Test 2 — Confirm the simulated API tool works correctly in isolation

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "Can you track my shipment TRK-9001?"}' \
  | python3 -m json.tool
```

**Expected behavior:** the trace shows `action: "trackShipment"` with `action_input: "TRK-9001"`, an observation containing `"status": "out_for_delivery"` and `"lastLocation": "Local distribution center"`, and a `finalAnswer` correctly reporting that the shipment is out for delivery.

#### Test 3 — The critical test: confirm the agent picks the *correct* tool among similar options

This is the real test of this part's work — not whether each tool works alone, but whether the model reliably **disambiguates** between them based on the tool descriptions alone.

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "What is the status of my order ORD-1003?"}' \
  | python3 -m json.tool
```
**Expected:** the trace should show `action: "lookupOrderStatus"`, **not** `searchKnowledgeBase` — even though the word "status" and general shipping-adjacent phrasing might otherwise tempt a poorly-described tool set toward the policy-search tool. The final answer should report `"processing"` and an estimated ship date.

Now test the general-policy case to make sure it *still* correctly avoids the order-lookup tool when there's no specific order ID involved:

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "In general, how long does shipping usually take?"}' \
  | python3 -m json.tool
```
**Expected:** the trace should show `action: "searchKnowledgeBase"`, correctly retrieving the general Shipping Policy document, rather than mistakenly invoking `lookupOrderStatus` with a missing or fabricated order ID.

If all three tools behave correctly in isolation, and — most importantly — the agent reliably selects the *right* tool for each distinct kind of question in Test 3, you've confirmed the core lesson of this part: vectorless retrieval isn't one algorithm, it's a *family* of direct-access patterns matched to the shape of the underlying data, and a well-engineered agent can be taught to navigate between them correctly through nothing more than clear, contrastive tool descriptions.
