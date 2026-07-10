# Part 2: The Tool Layer

## 1. Why Tool Quality Is the Real Bottleneck

Staff Engineer framing: teams consistently over-invest in "better prompts" or "bigger models" and under-invest in tool design. In practice, an agent's ceiling is set by:

1. How unambiguous the tool's input schema is (can the model even construct a valid call?)
2. How informative the tool's error messages are (can the model self-correct after a bad call?)
3. How narrow the tool's blast radius is (can a bad call do real damage?)

A GPT-4-class model with three vague, untyped tools will underperform a much smaller model with three tightly-typed, well-documented tools. This Part treats tools as first-class contracts, not glue code.

## 2. The Tool Contract

Every tool in this series follows the same shape: a Zod schema (the contract), a description (the model-facing documentation), and an implementation that never throws raw errors — it returns structured success/failure so the agent can reason about failure instead of crashing.

**src/tools/types.ts:**
```typescript
import { z } from "zod";

export type ToolResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: string; retryable: boolean };

export function ok<T>(data: T): ToolResult<T> {
  return { ok: true, data };
}

export function fail<T>(error: string, retryable = false): ToolResult<T> {
  return { ok: false, error, retryable };
}
```

The `retryable` flag matters: it lets the Reason node (or a later Reflection node in Part 5) distinguish "this failed because the input was wrong — try different arguments" from "this failed because the network blipped — try the exact same call again." Collapsing both into a generic Error string is a common cause of agents that loop forever retrying an unfixable call.

## 3. Tool 1 — Type-Safe API Call (Weather Lookup)

**src/tools/weather.ts:**
```typescript
import { z } from "zod";
import { tool } from "@langchain/core/tools";
import { ok, fail } from "./types.js";

const WeatherInput = z.object({
  city: z.string().min(1).describe("City name, e.g. 'Lisbon' or 'Austin, TX'"),
  units: z.enum(["metric", "imperial"]).default("metric"),
});

export const weatherTool = tool(
  async (input) => {
    const parsed = WeatherInput.parse(input);
    try {
      const res = await fetch(
        `https://api.open-meteo.com/v1/forecast?latitude=0&longitude=0&current_weather=true`,
        { signal: AbortSignal.timeout(5000) }
      );
      if (!res.ok) {
        return fail(`Weather API returned ${res.status}`, res.status >= 500);
      }
      const data = await res.json();
      return ok({ city: parsed.city, ...data.current_weather });
    } catch (err) {
      // Network/timeout errors are retryable; the caller decides policy.
      return fail(`Network error: ${(err as Error).message}`, true);
    }
  },
  {
    name: "get_weather",
    description:
      "Get current weather for a city. Use ONLY when the user explicitly asks about weather/temperature/forecast.",
    schema: WeatherInput,
  }
);
```

Design note: the description explicitly scopes when to use the tool ("ONLY when..."). Vague descriptions ("gets weather info") are a leading cause of agents calling tools speculatively on unrelated turns, wasting steps and money. Tool descriptions are prompts — treat them with the same rigor.

## 4. Tool 2 — Type-Safe DB Access

Never give an agent a raw SQL-execution tool in production — that is an unbounded blast radius. Instead, expose narrow, parameterized operations.

**src/tools/db.ts:**
```typescript
import { z } from "zod";
import { tool } from "@langchain/core/tools";
import { ok, fail } from "./types.js";
import { db } from "../infra/db.js"; // your Postgres client (Part 3 introduces the schema)

const LookupOrderInput = z.object({
  orderId: z.string().regex(/^ORD-\d{6}$/, "Must match ORD-123456 format"),
});

export const lookupOrderTool = tool(
  async (input) => {
    const parsed = LookupOrderInput.parse(input);
    try {
      const row = await db.query(
        "SELECT id, status, total_cents FROM orders WHERE id = $1",
        [parsed.orderId]
      );
      if (row.rowCount === 0) {
        return fail(`No order found with id ${parsed.orderId}`, false);
      }
      return ok(row.rows[0]);
    } catch (err) {
      return fail(`DB error: ${(err as Error).message}`, true);
    }
  },
  {
    name: "lookup_order",
    description:
      "Look up a single order by its exact order ID (format ORD-123456). Does not support searching by customer name or partial ID.",
    schema: LookupOrderInput,
  }
);
```

Why a regex-constrained input instead of `z.string()`: rejecting malformed IDs before they ever reach the database is cheaper (in latency and cost) than letting the model send garbage to a live query and reason about a DB error afterward. Push validation as far left as possible.

## 5. Tool 3 — Search (RAG Preview)

A minimal semantic search tool signature is introduced here; Part 3 builds its real pgvector-backed implementation. This stub keeps Part 2 self-contained while making the interface concrete.

**src/tools/search.ts:**
```typescript
import { z } from "zod";
import { tool } from "@langchain/core/tools";
import { ok } from "./types.js";

const SearchInput = z.object({
  query: z.string().min(3),
  topK: z.number().int().min(1).max(10).default(4),
});

export const searchTool = tool(
  async (input) => {
    const parsed = SearchInput.parse(input);
    // Placeholder — Part 3 replaces this body with a pgvector similarity query.
    return ok({ query: parsed.query, results: [] as string[] });
  },
  {
    name: "search_knowledge_base",
    description:
      "Semantic search over internal documents. Use when the user references past conversations, internal docs, or historical decisions not present in the current conversation.",
    schema: SearchInput,
  }
);
```

## 6. Assembling the Tool Registry

**src/tools/index.ts:**
```typescript
import { weatherTool } from "./weather.js";
import { lookupOrderTool } from "./db.js";
import { searchTool } from "./search.js";

export const toolDefinitions = [weatherTool, lookupOrderTool, searchTool];
```

This is the exact import Part 1's `reason.ts` and `act.ts` already reference — Part 1's placeholder is now a real, typed tool layer with zero changes needed to the graph itself. That decoupling (graph doesn't know or care what tools exist beyond the array) is the "Modularity" objective from the series brief made concrete.

## 7. Handling Tool Errors in the Loop

Because tools return `ToolResult` instead of throwing, LangChain's `ToolNode` will serialize that object into a `ToolMessage` and hand it back to Reason — the model literally sees `{ ok: false, error: "...", retryable: true }` and can decide to retry with adjusted arguments, pick a different tool, or surface the failure to the user. Verify this behavior with a quick manual test:

```
pnpm tsx -e "
import { lookupOrderTool } from './src/tools/db.js';
const result = await lookupOrderTool.invoke({ orderId: 'bad-id' });
console.log(result);
"
```

Expect a Zod validation error surfaced before the DB is ever touched — confirming validation-first ordering.

## 8. Exercise Challenge

Add a fourth tool, `send_notification`, that calls a (mocked) messaging API. Because sending a message is an irreversible side effect (unlike read-only weather/DB-lookup/search), give it a schema that requires an explicit `confirmed: z.literal(true)` field, and have the tool `fail()` with a clear, non-retryable message if `confirmed` is missing or false.

## 9. Solution

**src/tools/notify.ts:**
```typescript
import { z } from "zod";
import { tool } from "@langchain/core/tools";
import { ok, fail } from "./types.js";

const NotifyInput = z.object({
  recipient: z.string().email(),
  message: z.string().min(1).max(500),
  confirmed: z.literal(true).describe(
    "Must be explicitly true. Set this only after the user has confirmed sending."
  ),
});

export const notifyTool = tool(
  async (input) => {
    const parse = NotifyInput.safeParse(input);
    if (!parse.success) {
      return fail(
        "Notification blocked: this action requires explicit user confirmation (confirmed=true) before sending.",
        false
      );
    }
    // Mocked send — replace with real provider (email/SMS/Slack) API call.
    console.log(`[MOCK SEND] to=${parse.data.recipient}: ${parse.data.message}`);
    return ok({ sent: true, recipient: parse.data.recipient });
  },
  {
    name: "send_notification",
    description:
      "Send a notification message to a user. IRREVERSIBLE side effect — requires confirmed=true, which must only be set after the user has explicitly approved sending in this conversation.",
    schema: NotifyInput,
  }
);
```

Why this matters structurally: this is the first appearance of a pattern Part 5 (Reflection) and Part 8 (Governance) both depend on — using the **schema itself**, not just prompt instructions, to make an unsafe call impossible to construct without the required confirmation flag. A model can forget an instruction; it cannot bypass a `z.literal(true)` requirement it doesn't satisfy.

## Next
Part 3 gives `search_knowledge_base` a real backend: pgvector-based long-term memory, plus a separate short-term session memory layer, and explains when an agent should consult each.
