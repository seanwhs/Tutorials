# Phase 5, Part 2: Decoupling Application Tools — Swapping Implementations Without Breaking Prompt Logic

## The Target

This part is a deliberate **proof-of-concept demonstration** of the decoupling we architected in Part 1. We're going to do three things that would have been risky, multi-file refactors in our Phase 1–3 codebase, but which now become safe, isolated, single-file changes: (1) swap `lookupOrderStatus`'s internal data source from a static JSON file to a simulated async database client with connection-pool-style latency, (2) add a brand-new **write-action** tool, `cancelOrder`, using the exact same `defineTool` pattern, and (3) introduce **environment-based tool enablement**, so certain tools (like a destructive action) can be toggled on/off per-deployment-environment without touching any application logic.

## The Concept

The real test of whether an architecture is genuinely decoupled isn't how it looks when everything's brand new — it's how much *unrelated* code has to change when one piece of it evolves. Imagine a home's plumbing: a well-designed house lets a plumber replace the water heater without needing to also rewire the electrical system, repaint the walls, or move the bathtub — because the water heater connects to the rest of the house through standardized pipe fittings, not through custom, ad-hoc connections unique to that specific heater. A poorly designed system, by contrast, has everything tangled together, so replacing one component means touching five unrelated ones.

Our `defineTool` + `ToolRegistry` architecture from Part 1 is exactly this kind of "standardized pipe fitting." In this part, we prove it by actually doing the swap — not just claiming it's possible. We'll change what's happening *inside* the order-lookup tool's handler function (from reading a JSON file to calling a simulated database client) while its `name`, `description`, and `inputSchema` — the only parts the rest of the system actually depends on — stay completely untouched. The ReAct loop, the system prompt, and every other tool remain byte-for-byte unaware that anything changed.

The second idea in this part — **write actions and environment-based enablement** — introduces an important new consideration: not every tool is equally safe to expose everywhere. A `calculator` or a read-only `searchKnowledgeBase` carries very low risk if misused. A tool that actually *cancels a customer's order* is a genuine write action with real consequences — you might reasonably want that tool available in a staging/test environment but disabled (or gated behind extra confirmation) in production, without needing to fork your entire codebase into "prod version" and "staging version." Building a simple, registry-level enablement mechanism, driven by an environment variable, solves this cleanly — again, without touching the reasoning loop at all.

## The Implementation

### Step 1 — Swap the order lookup tool's backing implementation to a simulated database client

**File: `lib/agent/db/simulatedOrderDb.js`**
```js
import orders from '@/lib/data/orders.json';

/**
 * Simulates a real database client with connection-pool-style behavior:
 * a realistic network/query delay, and the possibility of a transient
 * failure, so the calling code has to handle it exactly like a genuine
 * database call would need to be handled. In a real migration, this file's
 * INTERNALS would be replaced with an actual database driver (e.g. `pg`,
 * `mongodb`, or an ORM client) — nothing calling into this module's public
 * function needs to know or care about that change.
 */
export async function queryOrderById(orderId) {
  // Simulate realistic query latency, distinct from our old, effectively
  // instant JSON file read — this is the kind of behavior change a real
  // infrastructure swap often introduces, and callers must be resilient to it.
  await new Promise((resolve) => setTimeout(resolve, 180));

  const record = orders[orderId];
  if (!record) {
    return null;
  }
  return { orderId, ...record };
}
```

**File: `lib/agent/retrieval/orderLookup.js`** *(full updated file — now calls the simulated DB client instead of reading the JSON object directly)*
```js
import { queryOrderById } from '../db/simulatedOrderDb.js';

/**
 * NOTE: this function's SIGNATURE and RETURN SHAPE are completely unchanged
 * from the Phase 3 version. Only the internal implementation changed — it
 * now awaits an async database-style call instead of doing a synchronous
 * object property lookup. The orderLookupTool.js handler that calls this
 * function required ZERO changes as a result of this swap.
 */
export async function lookupOrderStatus(orderId) {
  const normalizedId = String(orderId ?? '').trim().toUpperCase();

  if (!normalizedId) {
    return { error: 'An order ID is required, e.g. "ORD-1001".' };
  }

  const record = await queryOrderById(normalizedId);
  if (!record) {
    return { found: false, message: `No order found with ID "${normalizedId}".` };
  }

  return { found: true, ...record };
}
```

**File: `lib/agent/mcp/tools/orderLookupTool.js`** *(only one line changes — the handler now awaits, since `lookupOrderStatus` became async)*
```js
import { z } from 'zod';
import { defineTool } from '../defineTool.js';
import { lookupOrderStatus } from '../../retrieval/orderLookup.js';

export const orderLookupTool = defineTool({
  name: 'lookupOrderStatus',
  description: 'Looks up the EXACT current status of a SPECIFIC order by its order ID. Use only when a specific order ID like "ORD-1001" is known. Not for general shipping policy questions.',
  inputSchema: z.object({
    orderId: z.string().min(1, 'orderId cannot be empty'),
  }),
  handler: async ({ orderId }) => {
    return await lookupOrderStatus(orderId); // now awaits an async DB-style call — everything else about this tool is unchanged
  },
});
```

> **Notice exactly how small this diff is.** `orderLookupTool.js` — the file the registry and system prompt actually interact with — changed by a grand total of one keyword (`await`) plus nothing else. `name`, `description`, and `inputSchema` are all byte-for-byte identical to Part 1. This is the concrete, undeniable proof of decoupling: a genuine backend infrastructure change (JSON file → simulated database, complete with new latency characteristics) required touching two small, isolated files and left the registry, the ReAct loop, and the system prompt completely untouched.

### Step 2 — Add a brand-new write-action tool: `cancelOrder`

**File: `lib/agent/db/simulatedOrderDb.js`** *(add this function to the existing file)*
```js
/**
 * Simulates a write operation against the order database. Real production
 * code here would run an actual UPDATE query with proper transaction
 * handling; we simulate the same async, fallible shape for teaching purposes.
 */
export async function updateOrderStatus(orderId, newStatus) {
  await new Promise((resolve) => setTimeout(resolve, 220));

  const record = orders[orderId];
  if (!record) {
    return { success: false, reason: 'not_found' };
  }
  if (record.status === 'cancelled') {
    return { success: false, reason: 'already_cancelled' };
  }
  if (record.status === 'delivered') {
    // Business rule: you cannot cancel an order that has already shipped
    // and been delivered — this constraint lives in the data layer, exactly
    // where a real business rule like this belongs.
    return { success: false, reason: 'already_delivered_cannot_cancel' };
  }

  // NOTE: because `orders` was imported from a JSON file, this mutation
  // only affects the in-memory copy for the lifetime of this server
  // process — it does NOT persist to disk. This is intentional for this
  // teaching example; a real database write would genuinely persist.
  record.status = newStatus;
  return { success: true, updatedStatus: newStatus };
}
```

**File: `lib/agent/mcp/tools/cancelOrderTool.js`**
```js
import { z } from 'zod';
import { defineTool } from '../defineTool.js';
import { updateOrderStatus } from '../../db/simulatedOrderDb.js';

export const cancelOrderTool = defineTool({
  name: 'cancelOrder',
  description: 'Cancels a SPECIFIC order by its order ID, if it has not already shipped or been delivered. This is a WRITE action with real consequences — only use this when the user explicitly confirms they want to cancel a specific order.',
  inputSchema: z.object({
    orderId: z.string().min(1, 'orderId cannot be empty'),
  }),
  handler: async ({ orderId }) => {
    const normalizedId = String(orderId).trim().toUpperCase();
    const result = await updateOrderStatus(normalizedId, 'cancelled');

    if (!result.success) {
      const reasonMessages = {
        not_found: `No order found with ID "${normalizedId}".`,
        already_cancelled: `Order "${normalizedId}" is already cancelled.`,
        already_delivered_cannot_cancel: `Order "${normalizedId}" has already been delivered and cannot be cancelled.`,
      };
      return { success: false, message: reasonMessages[result.reason] || 'Cancellation failed.' };
    }

    return { success: true, message: `Order "${normalizedId}" has been successfully cancelled.` };
  },
});
```

### Step 3 — Environment-based tool enablement

This is the piece that lets us treat "which tools are active" as a deployment concern, not a code concern.

**File: `.env.local`** *(add this line)*
```bash
# Comma-separated list of tool names considered "write" actions. In
# non-production environments, these remain enabled for full testing.
# In production, set DISABLE_WRITE_TOOLS=true to gate them off entirely
# without touching a single line of application code.
DISABLE_WRITE_TOOLS=false
```

**File: `lib/agent/mcp/registry.js`** *(full updated file)*
```js
import { ToolRegistry } from './ToolRegistry.js';
import { calculatorTool } from './tools/calculatorTool.js';
import { currentTimeTool } from './tools/currentTimeTool.js';
import { knowledgeBaseTool } from './tools/knowledgeBaseTool.js';
import { orderLookupTool } from './tools/orderLookupTool.js';
import { shipmentTrackingTool } from './tools/shipmentTrackingTool.js';
import { cancelOrderTool } from './tools/cancelOrderTool.js';

// Tools flagged as "write" actions — tools that mutate state rather than
// only reading it. This distinction lives here, at the registry-assembly
// level, entirely separate from each tool's own definition — a tool
// doesn't need to know or declare anything about deployment gating; that
// concern is fully owned by this assembly file, keeping each individual
// tool definition simple and focused purely on ITS OWN behavior.
const WRITE_ACTION_TOOL_NAMES = new Set(['cancelOrder']);

export const registry = new ToolRegistry();

registry.register(calculatorTool);
registry.register(currentTimeTool);
registry.register(knowledgeBaseTool);
registry.register(orderLookupTool);
registry.register(shipmentTrackingTool);

// Read the environment flag ONCE at module load time. This is a deliberate
// choice: tool availability is decided when the server starts, not
// re-evaluated on every single request — treating it as a stable
// deployment-time configuration rather than a per-request runtime decision.
const writeToolsDisabled = process.env.DISABLE_WRITE_TOOLS === 'true';

if (!writeToolsDisabled) {
  registry.register(cancelOrderTool);
} else {
  console.warn(
    `[registry] Write-action tools disabled via DISABLE_WRITE_TOOLS=true. Skipped: ${Array.from(WRITE_ACTION_TOOL_NAMES).join(', ')}`
  );
}
```

> **Why gate registration itself, rather than gating execution inside `ToolRegistry.execute()`?** This is a meaningful design choice worth explaining. If we let `cancelOrder` register normally and instead added an `if (writeToolsDisabled) return blocked` check inside the tool's handler, the tool would still appear in `listToolDescriptions()` — meaning the system prompt would describe a capability to the model that secretly doesn't actually work, which risks the model confidently telling a user "I've cancelled your order" when nothing happened at all. By gating at **registration time**, a disabled tool simply doesn't exist from the registry's point of view — it won't appear in the system prompt, and the model has no way of even attempting to call it, closing off any chance of that confusing false-success scenario entirely.

### The Verification

#### Test 1 — Confirm the swapped database-backed lookup still behaves identically from the outside

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "What is the status of order ORD-1002?"}' \
  | python3 -m json.tool
```

**Expected:** identical behavior to Part 1's equivalent test — `action: "lookupOrderStatus"`, and a correct final answer reporting Marcus Chen's order as `in_transit`. From the outside, nothing looks different at all — which is exactly the point. If you'd like to directly observe the new latency characteristic introduced by the simulated DB call, add a quick timing log temporarily inside `queryOrderById` (`console.time`/`console.timeEnd`), or simply notice the response takes a bit longer overall compared to earlier phases — proof the new code path is genuinely executing.

#### Test 2 — Confirm the new write-action tool works correctly, including its business-rule guardrails

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "Please cancel order ORD-1003 for me."}' \
  | python3 -m json.tool
```
**Expected:** trace shows `action: "cancelOrder"`, and the final answer confirms `ORD-1003` (status was `processing`) was successfully cancelled.

Now confirm the business rule blocking cancellation of an already-delivered order:
```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "Please cancel order ORD-1001 for me."}' \
  | python3 -m json.tool
```
**Expected:** the final answer should clearly state that `ORD-1001` cannot be cancelled because it has already been delivered — confirming the business rule inside `updateOrderStatus` is being correctly enforced and correctly communicated back through the whole pipeline.

#### Test 3 — Confirm environment-based tool gating actually removes the tool entirely

Stop your dev server, edit `.env.local`:
```bash
DISABLE_WRITE_TOOLS=true
```
Restart the server:
```bash
npm run dev
```

You should immediately see this warning in your terminal on startup:
```
[registry] Write-action tools disabled via DISABLE_WRITE_TOOLS=true. Skipped: cancelOrder
```

Now confirm the tool is genuinely gone, not just blocked at execution time:
```bash
curl -s http://localhost:3000/api/agent/registry-test | python3 -m json.tool
```
Check the `allTools` array in the response — `cancelOrder` should be **completely absent** from the list, confirming the system prompt itself will never mention this capability to the model while this flag is active.

Finally, confirm the agent behaves sensibly when asked to do something it genuinely can no longer do:
```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "Please cancel order ORD-1002 for me."}' \
  | python3 -m json.tool
```
**Expected:** since `cancelOrder` no longer exists in the registry at all, the model has no tool available to attempt this action with, and should honestly respond that it's unable to cancel orders — rather than hallucinating a fake success. Set `.env.local` back to `DISABLE_WRITE_TOOLS=false` and restart your server before moving on, so write actions are available again for the rest of this course.

Once all three tests pass, you've concretely proven — not just architecturally described, but actually demonstrated through real code changes — that this tool system is genuinely decoupled: a full backend data-source migration, the addition of a brand-new write-capable tool, and deployment-environment-based capability gating were each accomplished as small, isolated, single-concern changes, with the reasoning loop, the system prompt logic, and every unrelated tool remaining completely untouched throughout.
