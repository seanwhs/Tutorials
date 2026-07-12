# Part 2: The Tool Layer

> Recap: Part 1 built the skeleton — state, model client, Reason/Act nodes, the graph itself — around a placeholder `toolDefinitions` import. Everything in that skeleton worked, but it worked with an empty promise: no tools actually existed yet. This Part fills that promise in, and in doing so makes an argument that's easy to nod along with and hard to actually act on: the tools, not the model, are usually your real ceiling.

## 1. Why Tool Quality Is the Real Bottleneck

Staff Engineer framing: teams consistently over-invest in "better prompts" or "bigger models" and under-invest in tool design. It's an understandable mistake — swapping a model string or rewriting a system prompt feels like fast, high-leverage work, while redesigning a tool's schema feels like plumbing. But in practice, an agent's ceiling is set by three things, in roughly this order of impact:

1. **How unambiguous the tool's input schema is** — can the model even construct a valid call in the first place? A schema that accepts `city: string` for a weather lookup is ambiguous about format ("NYC"? "New York"? "New York, NY, USA"?) in a way that silently produces a worse hit rate than a schema that spells the expectation out.
2. **How informative the tool's error messages are** — can the model self-correct after a bad call, or does it just see `Error: 500` and either give up or blindly retry the identical broken call?
3. **How narrow the tool's blast radius is** — can a bad call do real damage? A read-only lookup failing badly is an annoyance; a write/side-effecting call failing badly (or *succeeding* on bad input) is an incident.

Put concretely: a GPT-4-class model wired to three vague, untyped tools will reliably underperform a much smaller, cheaper model wired to three tightly-typed, well-documented tools. If your instinct after a disappointing agent demo is "let's try a bigger model," it's worth first asking whether you've actually given the current model a fair contract to work with. This Part treats tools as first-class contracts, not glue code — every tool below is going to look almost aggressively over-specified relative to what a tutorial "hello world" tool would look like, and that's the point.

## 2. The Tool Contract

Every tool in this series follows the same three-part shape, and it's worth naming each part explicitly because they map to the three bullets above:

- A **Zod schema** — the contract, and the fix for bullet 1 (ambiguous input).
- A **description** — the model-facing documentation, and the fix for bullet 1's other half (does the model know *when* to call this).
- An **implementation that never throws raw errors** — it returns a structured success/failure so the agent can reason about failure instead of crashing, which is the fix for bullet 2.

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

The `retryable` flag is doing more work than its size suggests. It lets the Reason node — or a later Reflection node in Part 5 — distinguish two failure modes that look identical if you only log a generic `Error` string: "this failed because the input was wrong, so try genuinely different arguments" versus "this failed because the network blipped, so the exact same call is worth trying again." Collapsing both into one undifferentiated error type is a common, quiet cause of agents that loop forever retrying an input that was never going to succeed — the model has no signal telling it *retry* and *retry differently* are different actions, so it picks whichever pattern its training leans toward, which is often the wrong one.

Every tool from here on returns `ok(...)` or `fail(...)` — never a bare `throw`. Keep that discipline even when it feels like overkill for an obviously-fine code path; the moment you let one tool throw a raw error, the Reason node has to handle two different failure shapes instead of one, and that inconsistency compounds across a codebase with a dozen tools.

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

A few details worth slowing down on. First, `.describe("City name, e.g. 'Lisbon' or 'Austin, TX'")` on the schema field itself — not just the top-level tool description — is what actually shows up in the generated JSON schema the model sees for *that specific argument*. Field-level descriptions are cheap and routinely skipped; they're one of the highest leverage-per-character additions you can make to a tool.

Second, look at the `retryable` logic: `res.status >= 500`. That's not arbitrary — a 5xx is (usually) the server's problem and worth retrying, while a 4xx is (usually) the request's problem and retrying identically won't help. Encoding that distinction here, once, means every caller of this tool inherits correct retry semantics instead of having to re-derive HTTP status code conventions themselves.

Third, and most important for the section's thesis: the description explicitly scopes *when* to use the tool — "Use ONLY when the user explicitly asks about weather/temperature/forecast." Vague descriptions ("gets weather info") are a leading cause of agents calling tools speculatively on unrelated turns — the model sees a plausible-looking tool and a plausible-looking user message, and without an explicit scope constraint, "plausible" is often enough to trigger a call that wastes a step and a dollar on a turn that didn't need it. Tool descriptions are prompts. Review them with the same rigor you'd apply to a system prompt, including testing what happens on *adjacent* but out-of-scope requests.

## 4. Tool 2 — Type-Safe DB Access

Never give an agent a raw SQL-execution tool in production — that is an unbounded blast radius, full stop, regardless of how good your prompt is at telling the model to "only run safe queries." Instead, expose narrow, parameterized operations, each of which can only do the one specific thing it was built to do.

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

Notice the query itself: `SELECT id, status, total_cents FROM orders WHERE id = $1` is parameterized (`$1`), not string-interpolated. That's standard SQL-injection hygiene, but it's worth naming explicitly in an agent context because the *input* to this query is model-generated — arguably even more reason to be rigorous about parameterization than in a typical human-triggered form submission, since a model's output space, while constrained by the Zod schema, is still less predictable than a fixed UI form field.

Why a regex-constrained input (`/^ORD-\d{6}$/`) instead of a bare `z.string()`: rejecting malformed IDs before they ever reach the database is cheaper — in both latency and literal query cost — than letting the model send garbage into a live query and then reasoning about a DB error afterward. This is the same "push validation as far left as possible" principle you'd apply to any user-facing form, just applied to a form whose only user is the model. The regex failure also produces a *specific, actionable* Zod error ("Must match ORD-123456 format") rather than an opaque database error, which materially increases the odds the model self-corrects on the next attempt instead of repeating the same malformed call.

The description's second sentence — "Does not support searching by customer name or partial ID" — is doing defensive work too: it preempts a plausible but unsupported use of the tool, so the model doesn't burn a step discovering that limitation empirically via a failed call.

## 5. Tool 3 — Search (RAG Preview)

A minimal semantic search tool signature is introduced here; Part 3 builds its real pgvector-backed implementation. This stub keeps Part 2 self-contained — you can compile, run, and register the full tool set today — while making the *interface* concrete now, so Part 3 is purely a body swap with zero changes to the schema, the description, or anything that calls this tool.

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

The `topK` bound (`min(1).max(10)`) is a small but deliberate cost/quality control: an unbounded top-K lets the model request an arbitrarily large context dump back into `state.messages`, which both inflates token cost on every subsequent Reason call (remember, the whole transcript gets re-sent each turn) and dilutes the signal-to-noise ratio of what's actually relevant. Capping it at the schema level means this constraint holds regardless of what the model asks for — it can't accidentally or adversarially request `topK: 500`.

## 6. Assembling the Tool Registry

**src/tools/index.ts:**

```typescript
import { weatherTool } from "./weather.js";
import { lookupOrderTool } from "./db.js";
import { searchTool } from "./search.js";

export const toolDefinitions = [weatherTool, lookupOrderTool, searchTool];
```

This is the exact import Part 1's `reason.ts` and `act.ts` already reference — go back and check, nothing in either file needs to change. Part 1's placeholder array is now a real, typed tool layer, and the graph is completely unaware of the difference. That decoupling — the graph doesn't know or care what tools exist beyond the shape of this array — is the practical payoff of treating tools as a swappable registry from day one, in the same spirit as Part 1's swappable model client. Adding a fourth tool later (as the exercise below does) is purely additive: one new file, one new line in this array, zero changes anywhere in `src/agent/`.

## 7. Handling Tool Errors in the Loop

Because tools return `ToolResult` instead of throwing, LangChain's `ToolNode` serializes that object into a `ToolMessage` and hands it straight back to Reason — the model literally sees `{ ok: false, error: "...", retryable: true }` in its next turn's context, as plain structured data, and can decide to retry with adjusted arguments, pick a different tool entirely, or give up and surface the failure to the user in its final answer. This is the payoff of section 2's contract: failure is *information the model can act on*, not an exception that unwinds the whole call stack.

Verify this behavior with a quick manual test before wiring everything into the full graph — isolating the tool layer from the graph layer when debugging saves a lot of guesswork about which layer a bug lives in:

```bash
pnpm tsx -e "
import { lookupOrderTool } from './src/tools/db.js';
const result = await lookupOrderTool.invoke({ orderId: 'bad-id' });
console.log(result);
"
```

Expect a Zod validation error surfaced *before* the DB is ever touched — that's the validation-first ordering from section 4 confirmed empirically, not just asserted. If you instead see a database error, that's a sign the schema validation isn't actually running ahead of the query, and it's worth tracing why before moving on.

## 8. Exercise Challenge

Add a fourth tool, `send_notification`, that calls a (mocked) messaging API. Because sending a message is an irreversible side effect — unlike the read-only weather lookup, DB lookup, and search tool built above — give it a schema that requires an explicit `confirmed: z.literal(true)` field, and have the tool `fail()` with a clear, non-retryable message if `confirmed` is missing or false.

Before jumping to the solution, notice what makes this exercise different in kind from the first three tools: this isn't about getting a *better* result from a well-formed call, it's about making an entire class of call *impossible to form* without an extra, explicit signal of intent. That's a safety property, not a correctness property, and it calls for a different design instinct.

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

Walk through why `z.literal(true)` specifically, rather than `z.boolean()`: a plain boolean field defaults, in a lot of model-generated JSON, toward `false` or gets omitted entirely when the model isn't sure — and `z.boolean().optional()` would happily accept `confirmed: false` as valid input, at which point the *tool body* has to remember to check the value. `z.literal(true)` folds that check into the schema itself: the only value that type-checks at all is `true`. Omit the field, send `false`, or send anything else, and Zod's `safeParse` fails before the mocked send ever runs — the failure path in this code isn't a business-logic `if` statement the author might forget to write correctly, it's a structural consequence of the schema.

Why this matters beyond this one tool: this is the first appearance of a pattern Part 5 (Reflection) and Part 8 (Governance) both build on directly — using the **schema itself**, not just a prompt instruction, to make an unsafe call impossible to construct without satisfying a required precondition. It's worth restating the closing line from Part 1's exercise here, because it's really the throughline connecting both Parts so far: a model can forget an instruction, drift from it over a long conversation, or be prompt-injected into ignoring it — but it cannot bypass a `z.literal(true)` requirement it doesn't satisfy. Every time you're tempted to handle a safety requirement with "and tell the model to only do X when Y," pause and ask whether X can instead be made to structurally *require* Y.

## Tool Design Checklist

A quick reference to carry into every new tool you write for the rest of this series:

- **Schema first.** Every field typed, bounded, and `.describe()`d — not just top-level, but per-field.
- **Scope the description.** State explicitly when the tool should and shouldn't be called; test adjacent, out-of-scope phrasings.
- **Structured failure, never a raw throw.** Use `ok()` / `fail()` so the model receives failure as reasoning material, not a crash.
- **Mark retryability honestly.** Network/5xx → retryable; malformed input/4xx/not-found → not retryable.
- **Match blast radius to friction.** Read-only tools can be low-friction; side-effecting tools should require an explicit, schema-enforced confirmation signal.
- **Validate left, not right.** Reject bad input before it reaches a network call or a database — cheaper, faster, and produces a more actionable error for the model to act on.

## Next

Part 3 gives `search_knowledge_base` a real backend: pgvector-based long-term memory, plus a separate short-term session memory layer, and explains when an agent should consult each.
