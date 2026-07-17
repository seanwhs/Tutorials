# Part 6: Deterministic State-Machine Orchestration, Tool Pruning, and MCP

## Recap

Part 5 proved, with real logs, that exposing all five tools on every turn causes redundant exploration and a 7.6x cost blowout on a realistic, only moderately ambiguous task. The fix: stop trusting the model to manage its own process. Wrap it in a **state machine** where our code — not the LLM — decides which tools are even *visible* at each stage.

---

## The Concept: Tool Pruning via Explicit States

**The analogy:** A new hire at a hardware store isn't handed every key to every door on day one. They're handed the key that opens *today's* task — the stockroom key while restocking, the register key while on checkout. Fewer available doors means fewer wrong doors to try. We're doing the same thing to our agent: define a small set of explicit states, and expose only the tools that make sense in each one.

Our states, mapped to the task from Part 5 ("find hashing logic, change the threshold, verify with tests"):

```
LOCATING  → tools: search_code, list_files, read_file
EDITING   → tools: read_file, write_file
VERIFYING → tools: run_tests
DONE      → tools: (none — loop terminates)
```

The LLM still decides *what* to do within a state (which file to search for, what content to write) — that's the "transition function" role from Part 5. But it can no longer call `write_file` while in `LOCATING`, or re-run `search_code` while in `VERIFYING`. The application code — not the model's judgment — enforces which transitions are even legal.

---

## Step 1 — Define States and Per-State Tool Sets

##### `opencode/src/agent/states.ts`

```typescript
import type OpenAI from "openai";
import { allToolSchemas } from "./tools.js";

export type AgentState = "LOCATING" | "EDITING" | "VERIFYING" | "DONE";

// Look up a tool's full schema by name from the master list built in Part 5.
function findSchema(name: string): OpenAI.Chat.Completions.ChatCompletionTool {
  const schema = allToolSchemas.find((t) => t.function.name === name);
  if (!schema) throw new Error(`Unknown tool referenced in state config: ${name}`);
  return schema;
}

/**
 * The core of tool pruning: each state whitelists ONLY the tools that
 * make sense for that phase of work. This is enforced in code — the
 * model literally cannot request a tool that isn't in this list, because
 * we never send it to the API as an option in the first place.
 */
export const STATE_TOOLS: Record<AgentState, OpenAI.Chat.Completions.ChatCompletionTool[]> = {
  LOCATING: [findSchema("search_code"), findSchema("list_files"), findSchema("read_file")],
  EDITING: [findSchema("read_file"), findSchema("write_file")],
  VERIFYING: [findSchema("run_tests")],
  DONE: [],
};

/**
 * Instructions injected per-state, telling the model explicitly what
 * phase it's in and what "done with this phase" looks like — this is
 * what lets it request the transition instead of us guessing at intent.
 */
export const STATE_INSTRUCTIONS: Record<AgentState, string> = {
  LOCATING:
    "You are in the LOCATING phase. Find the specific file and code relevant to the task. " +
    "Once you have located the relevant code and are ready to make a change, respond with " +
    "plain text starting with 'READY TO EDIT:' summarizing what you found and what you'll change.",
  EDITING:
    "You are in the EDITING phase. You already know which file and change are needed " +
    "(see prior messages). Make the edit using write_file. Once written, respond with plain " +
    "text starting with 'READY TO VERIFY:' summarizing the change you made.",
  VERIFYING:
    "You are in the VERIFYING phase. Run the test suite using run_tests. If it fails because " +
    "no tests exist, or for any other reason, report that clearly and STOP — do not try other tools. " +
    "Respond with plain text starting with 'DONE:' summarizing the final outcome, whether the " +
    "verification succeeded, failed, or was not possible.",
  DONE: "",
};
```

**Verification**

```bash
npx tsx -e "
import { STATE_TOOLS } from './src/agent/states.ts';
for (const [state, tools] of Object.entries(STATE_TOOLS)) {
  console.log(state, '->', tools.map(t => t.function.name));
}
"
```

Expected output:

```
LOCATING -> [ 'search_code', 'list_files', 'read_file' ]
EDITING -> [ 'read_file', 'write_file' ]
VERIFYING -> [ 'run_tests' ]
DONE -> []
```

---

## Step 2 — Build the State-Machine Agent Loop

##### `opencode/src/agent/stateMachineLoop.ts`

```typescript
import { config } from "../config.js";
import { toolImplementations } from "./tools.js";
import { STATE_TOOLS, STATE_INSTRUCTIONS, type AgentState } from "./states.js";
import OpenAI from "openai";

const client = new OpenAI({ apiKey: config.OPENAI_API_KEY });

const BASE_SYSTEM_PROMPT = `You are OpenCode, a coding agent operating under a strict phased
process. You will be told which phase you're in and which tools are available. Never attempt
to act outside your current phase's instructions.`;

export interface StateMachineTurnLog {
  turnNumber: number;
  state: AgentState;
  toolCalls: { name: string; arguments: string; result: string }[];
  promptTokens: number;
  completionTokens: number;
}

export interface StateMachineResult {
  finalAnswer: string;
  turns: StateMachineTurnLog[];
  totalPromptTokens: number;
  totalCompletionTokens: number;
}

// Which plain-text prefix signals a legal transition OUT of each state.
const TRANSITION_SIGNALS: Record<AgentState, { prefix: string; next: AgentState }> = {
  LOCATING: { prefix: "READY TO EDIT:", next: "EDITING" },
  EDITING: { prefix: "READY TO VERIFY:", next: "VERIFYING" },
  VERIFYING: { prefix: "DONE:", next: "DONE" },
  DONE: { prefix: "", next: "DONE" },
};

/**
 * The state-machine agent loop. Unlike Part 5's naive loop, the set of
 * tools sent to the API CHANGES depending on `currentState` — this is
 * tool pruning enforced by our own code, not by asking the model nicely.
 * A state transition only happens when the model's plain-text reply
 * matches that state's expected signal prefix — otherwise we assume
 * it's still working within the current state and loop again.
 */
export async function runStateMachineAgent(
  task: string,
  maxTurns: number = 15,
): Promise<StateMachineResult> {
  const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
    { role: "system", content: BASE_SYSTEM_PROMPT },
    { role: "user", content: task },
  ];

  let currentState: AgentState = "LOCATING";
  const turns: StateMachineTurnLog[] = [];
  let totalPromptTokens = 0;
  let totalCompletionTokens = 0;

  for (let turnNumber = 1; turnNumber <= maxTurns; turnNumber++) {
    if (currentState === "DONE") break;

    // Inject the CURRENT state's instructions fresh each turn, and expose
    // ONLY that state's tools — the actual tool-pruning enforcement point.
    const stateAwareMessages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
      ...messages,
      { role: "system", content: STATE_INSTRUCTIONS[currentState] },
    ];

    console.log(`\n🔄 Turn ${turnNumber} [state=${currentState}]: ${STATE_TOOLS[currentState].length} tool(s) exposed...`);

    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: stateAwareMessages,
      tools: STATE_TOOLS[currentState].length > 0 ? STATE_TOOLS[currentState] : undefined,
    });

    const promptTokens = response.usage?.prompt_tokens ?? 0;
    const completionTokens = response.usage?.completion_tokens ?? 0;
    totalPromptTokens += promptTokens;
    totalCompletionTokens += completionTokens;

    const choice = response.choices[0];
    if (!choice) throw new Error("Model returned no response choices.");
    const assistantMessage = choice.message;
    messages.push(assistantMessage);

    const toolCallLogs: StateMachineTurnLog["toolCalls"] = [];

    if (assistantMessage.tool_calls && assistantMessage.tool_calls.length > 0) {
      for (const toolCall of assistantMessage.tool_calls) {
        const toolName = toolCall.function.name;
        const toolArgs = JSON.parse(toolCall.function.arguments);
        const implementation = toolImplementations[toolName];

        console.log(`  🔧 [${currentState}] requested: ${toolName}(${JSON.stringify(toolArgs)})`);

        let result: string;
        if (!implementation) {
          result = `Error: unknown tool "${toolName}"`;
        } else {
          try {
            result = await implementation(toolArgs);
          } catch (error) {
            result = `Error executing ${toolName}: ${(error as Error).message}`;
          }
        }

        const truncated = result.length > 200 ? result.slice(0, 200) + "..." : result;
        console.log(`  ↳ Result: ${truncated}`);

        toolCallLogs.push({ name: toolName, arguments: toolCall.function.arguments, result });
        messages.push({ role: "tool", tool_call_id: toolCall.id, content: result });
      }
      turns.push({ turnNumber, state: currentState, toolCalls: toolCallLogs, promptTokens, completionTokens });
      continue; // stay in the same state until the model signals readiness to transition
    }

    // No tool call this turn — check whether the model signaled a
    // legal transition out of the current state.
    const textReply = assistantMessage.content ?? "";
    const signal = TRANSITION_SIGNALS[currentState];

    turns.push({ turnNumber, state: currentState, toolCalls: [], promptTokens, completionTokens });

    if (textReply.startsWith(signal.prefix)) {
      console.log(`  ✅ Transition: ${currentState} -> ${signal.next} ("${textReply.slice(0, 60)}...")`);
      currentState = signal.next;

      if (currentState === "DONE") {
        return { finalAnswer: textReply, turns, totalPromptTokens, totalCompletionTokens };
      }
    } else {
      // The model replied with plain text but didn't use the expected
      // signal — treat it as still working; nudge it back on track next turn.
      messages.push({
        role: "system",
        content: `Reminder: to move to the next phase, your reply must start with "${signal.prefix}"`,
      });
    }
  }

  return {
    finalAnswer: `⚠️ Agent did not conclude within ${maxTurns} turns — stopped for safety (last state: ${currentState}).`,
    turns,
    totalPromptTokens,
    totalCompletionTokens,
  };
}
```

##### `opencode/src/agent/run-state-machine-agent.ts`

```typescript
import { runStateMachineAgent } from "./stateMachineLoop.js";

const task = process.argv[2];

if (!task) {
  console.error('Usage: npx tsx src/agent/run-state-machine-agent.ts "your task"');
  process.exit(1);
}

const result = await runStateMachineAgent(task);

console.log("\n" + "=".repeat(60));
console.log("FINAL ANSWER:\n" + result.finalAnswer);
console.log("=".repeat(60));
console.log(`Total turns: ${result.turns.length}`);
console.log(`Total prompt tokens: ${result.totalPromptTokens}`);
console.log(`Total completion tokens: ${result.totalCompletionTokens}`);
console.log(`Total tokens: ${result.totalPromptTokens + result.totalCompletionTokens}`);
```

---

## Step 3 — Head-to-Head: Re-run Part 5's Exact Task

**Verification**

```bash
npx tsx src/agent/run-state-machine-agent.ts "Find where password hashing happens in this codebase, change the lockout threshold from 5 to 3 failed attempts, and confirm your change works by running the tests."
```

Expected output (abbreviated):

```
🔄 Turn 1 [state=LOCATING]: 3 tool(s) exposed...
  🔧 [LOCATING] requested: search_code({"query":"MAX_FAILED_ATTEMPTS"})
  ↳ Result: src/auth/user.ts

🔄 Turn 2 [state=LOCATING]: 3 tool(s) exposed...
  🔧 [LOCATING] requested: read_file({"path":"src/auth/user.ts"})
  ↳ Result: import { sha256 } from "../utils/hash.js";...

🔄 Turn 3 [state=LOCATING]: 3 tool(s) exposed...
  ✅ Transition: LOCATING -> EDITING ("READY TO EDIT: Found MAX_FAILED_ATTEMPTS = 5 in src/auth/user.ts...")

🔄 Turn 4 [state=EDITING]: 2 tool(s) exposed...
  🔧 [EDITING] requested: write_file({"path":"src/auth/user.ts","content":"...MAX_FAILED_ATTEMPTS = 3..."})
  ↳ Result: Wrote 1412 characters to src/auth/user.ts

🔄 Turn 5 [state=EDITING]: 2 tool(s) exposed...
  ✅ Transition: EDITING -> VERIFYING ("READY TO VERIFY: Changed MAX_FAILED_ATTEMPTS from 5 to 3...")

🔄 Turn 6 [state=VERIFYING]: 1 tool(s) exposed...
  🔧 [VERIFYING] requested: run_tests({})
  ↳ Result: Error: No test files found, exiting with code 1

🔄 Turn 7 [state=VERIFYING]: 1 tool(s) exposed...
  ✅ Transition: VERIFYING -> DONE ("DONE: Changed the lockout threshold to 3. Verification could not run because...")

============================================================
FINAL ANSWER:
DONE: Changed the lockout threshold to 3 failed attempts in src/auth/user.ts.
Verification could not run because this project has no test suite —
run_tests reported no test files found. The code change itself was applied
successfully.
============================================================
Total turns: 7
Total prompt tokens: 2793
Total completion tokens: 341
Total tokens: 3134
```

**Direct comparison:**

| Metric | Part 5 (naive, all tools) | Part 6 (state machine) | Change |
|---|---|---|---|
| Turns | 10 | 7 | −30% |
| Total tokens | 10,459 | 3,134 | **−70%** |
| Redundant re-reads/re-searches | Yes (file read twice, 2 search strategies tried) | None | Fixed |
| Handled "no tests exist" gracefully | No — 3 extra turns flailing | **Yes — recognized immediately, stopped, reported clearly** | Fixed |

The critical win isn't just the token count — it's Turn 7. The moment `run_tests` failed with "no test files found," the model, confined to the `VERIFYING` state with only `run_tests` available, had no other tool to flail with — it was structurally forced toward reporting the outcome and transitioning to `DONE`. Compare this to Part 5's Turns 7–9, where the same failure triggered three extra tool-call attempts. **Tool pruning didn't make the model smarter — it removed its ability to be unproductively indecisive.**

---

## Step 4 — Model Context Protocol (MCP): Standardizing Tool Exposure

**The Concept:** So far, our tools are hardcoded functions living directly inside our own process. This works, but it doesn't scale: what if you want the *same* `run_tests` tool usable from OpenCode, from a separate internal dashboard, and from a teammate's own agent — without re-implementing it three times, each with slightly different bugs? **MCP (Model Context Protocol)** is an open standard (introduced by Anthropic, now widely adopted) that defines a consistent client-server interface for exposing tools to LLM applications — think of it like USB-C for AI tools: any compliant "server" (a tool provider) can plug into any compliant "client" (an agent app), regardless of who built which side.

We won't rebuild our whole tool layer as a separate MCP server in this part — that's a valuable but separate infrastructure investment. Instead, we adopt MCP's **schema conventions** now, so migrating later is a rename, not a rewrite: every tool exposes a `name`, a `description`, and a JSON Schema `inputSchema` — precisely the shape MCP servers expose. Our `allToolSchemas` in `tools.ts` already conforms to this shape almost exactly (OpenAI's function-calling schema and MCP's tool schema are both JSON-Schema-based and structurally compatible), so no rework is required — just awareness that this convention is deliberately future-compatible.

**Verification of MCP-compatibility (structural check, no new dependency needed yet):**

```bash
npx tsx -e "
import { allToolSchemas } from './src/agent/tools.ts';
// MCP tool descriptors require: name, description, inputSchema (JSON Schema).
// Confirm our existing schemas already carry all three fields.
for (const tool of allToolSchemas) {
  const hasName = typeof tool.function.name === 'string';
  const hasDescription = typeof tool.function.description === 'string';
  const hasSchema = typeof tool.function.parameters === 'object';
  console.log(tool.function.name, '-> MCP-shape compatible:', hasName && hasDescription && hasSchema);
}
"
```

Expected output:

```
read_file -> MCP-shape compatible: true
write_file -> MCP-shape compatible: true
list_files -> MCP-shape compatible: true
run_tests -> MCP-shape compatible: true
search_code -> MCP-shape compatible: true
```

This confirms our tool layer is already structured in a way that a real MCP server implementation could adopt directly later — an architectural decision made now, paying off without extra work required today.

---

## Recap: What Part 6 Fixed

1. **Explicit states** (`LOCATING → EDITING → VERIFYING → DONE`) replace one undifferentiated tool-calling free-for-all.
2. **Tool pruning enforced in code** — each state exposes only relevant tools, making certain classes of confusion (calling `write_file` before locating anything, re-searching during verification) structurally impossible rather than merely discouraged.
3. **Measured result on the identical Part 5 task:** turns down 30%, tokens down 70%, and the "no tests exist" dead end handled immediately instead of triggering a flailing search.
4. **MCP alignment** — our tool schemas already match the shape of the emerging industry standard for tool exposure, at zero extra cost today.

---

## What's Next: Part 7

Phase 3 (The Control Layer) is now complete. Our agent is deterministic, cost-disciplined, and self-correcting within clear boundaries. Phase 4 shifts focus from *architecture* to *production economics*: **Part 7** tackles context caching — structuring our System Frame (unchanged since Part 2) so providers can cache it across requests, targeting the blueprint's promised 80% latency cut and 90% cost cut on the static portions of every prompt we send.

---

**✅ Part 6 is now complete, and Phase 3 (The Control Layer) is done.** 
