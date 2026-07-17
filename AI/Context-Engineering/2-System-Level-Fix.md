# Part 2: Designing the Three-Layer Prompt Architecture

## Recap

In Part 1, we proved — with real numbers from your own terminal — that concatenating an entire codebase into one flat prompt causes latency blowouts, runaway costs, and a genuine "Lost in the Middle" failure where the model gave a **confidently wrong answer** about a real business rule that was sitting right there in the code.

The fix isn't a bigger context window. It's **structure**. This part builds that structure.

---

## The Concept: Registers, RAM, and Instruction Pointers

Recall our foundational metaphor: *the context window is volatile, high-latency RAM with unreliable attention.* Let's extend that metaphor properly, because it maps almost perfectly onto real CPU architecture — which is exactly why it works so well as a design pattern.

A CPU doesn't treat all memory equally. It has:

- **Firmware / boot ROM** — rules baked in that never change during operation, read once, trusted completely.
- **Registers** — a tiny amount of extremely fast, frequently-overwritten storage holding *only* what's needed for the current few operations.
- **The instruction pointer** — a single, precise reference to *exactly* which instruction is executing right now — not the whole program, just the current line.

We're going to build our prompt the same way, using three distinct layers:

| Layer | CPU Analogy | What It Holds | How Often It Changes |
|---|---|---|---|
| **System Frame** | Boot ROM / firmware | Hard rules: who the assistant is, what it must/must never do, output format | Almost never — set once per deployment |
| **Dynamic Memory** | CPU registers | The last 2–3 conversation turns — just enough short-term context to follow a conversation | Every turn |
| **Transient Fact** | Instruction pointer | The *one specific thing* relevant right now — e.g., the exact file the user is asking about | Every single message, sometimes every few seconds |

The critical insight: **each layer has a different lifetime, and mixing their lifetimes together is exactly what caused Part 1's failure.** When you dump 35 files and a chat history and a question into one undifferentiated blob, the model has no signal about which parts are stable ground truth (System Frame), which parts are recent context (Dynamic Memory), and which single fact actually answers the question (Transient Fact). Everything looks equally important — which, statistically, means nothing gets prioritized correctly.

This isn't just conceptually cleaner — it's the exact foundation Part 7 (context caching) depends on. Providers like OpenAI and Anthropic can cache the *unchanging* prefix of a prompt (System Frame) across requests, cutting cost and latency dramatically — but **only if that prefix is byte-for-byte identical across calls**. If you keep gluing everything into one giant blob that changes shape every time (like Part 1 did, where the entire codebase dump changes based on file count), caching is structurally impossible. Building this three-layer split now is what makes an 80%+ cost reduction possible five parts from now.

---

## Step 1 — Model the Three Layers as TypeScript Types

**The Target:** A new file, `src/context/types.ts`, defining the shape of each layer as a distinct, type-safe structure — before we write any logic that assembles them.

**The Concept:** We define the "shape of the boxes" before we decide what goes in them. This mirrors how a real database schema is designed before the application logic that populates it — get the shape wrong, and every downstream consumer inherits the mistake.

**The Implementation**

```bash
mkdir -p src/context
```

##### `opencode/src/context/types.ts`

```typescript
/**
 * SYSTEM FRAME
 * The "firmware" layer. Hard rules that define the assistant's identity,
 * boundaries, and output format. This should be static for long stretches
 * of the app's life — ideally identical across MANY requests, since that
 * identical-ness is exactly what enables prompt caching later (Part 7).
 */
export interface SystemFrame {
  /** Who the assistant is and its overall mandate. */
  identity: string;
  /** Hard constraints — things it must never do, framed as explicit rules. */
  rules: string[];
  /** How it should format its answers. */
  outputFormat: string;
}

/**
 * A single turn in a conversation — one user message and the
 * assistant's reply to it.
 */
export interface ConversationTurn {
  userMessage: string;
  assistantMessage: string;
}

/**
 * DYNAMIC MEMORY
 * The "registers" layer. A short, bounded window of recent conversation
 * history. Bounded on purpose — unlike a naive chatbot that resends the
 * ENTIRE conversation history forever (which would reintroduce Part 1's
 * exact cost/latency problem, just with chat messages instead of files),
 * we cap this at a small, fixed number of turns.
 */
export interface DynamicMemory {
  recentTurns: ConversationTurn[];
  maxTurns: number;
}

/**
 * TRANSIENT FACT
 * The "instruction pointer" layer. The one specific, concrete piece of
 * ground-truth information relevant to THIS message only — e.g. the
 * exact file contents the user is currently asking about. In Part 3/4,
 * this will be populated by a retrieval system instead of being chosen
 * manually — but the shape of the box doesn't need to change when we
 * upgrade what fills it.
 */
export interface TransientFact {
  /** Human-readable label, e.g. a file path, so the model knows what this is. */
  label: string;
  /** The actual content — file contents, a function body, a doc snippet, etc. */
  content: string;
}

/**
 * The full, assembled context passed into a single request. Three
 * layers, three distinct lifetimes, explicitly separated — this is
 * the type that replaces Part 1's single flat string.
 */
export interface AssembledContext {
  systemFrame: SystemFrame;
  dynamicMemory: DynamicMemory;
  transientFacts: TransientFact[];
}
```

**The Verification**

This file has no runtime behavior yet — it's pure structure — so "verification" here means proving it compiles cleanly and matches our strict TypeScript config from Part 0:

```bash
npx tsc --noEmit
```

Expected output: **no errors** (the command exits silently with status code 0). Confirm explicitly:

```bash
echo $?
```

Expected output:

```
0
```

If you see type errors instead, double check every interface field name matches exactly — a common typo trap is mismatching `recentTurns` vs `recentTurn`, which TypeScript will catch immediately (this is strict mode from Part 0 already paying for itself).

Continuing with the assembler logic.

## Step 2 — Build the Bounded Dynamic Memory Manager

**The Target:** A small class, `src/context/memory.ts`, that manages `DynamicMemory` — adding new turns and automatically dropping old ones once the cap is hit.

**The Concept:** This is a **ring buffer** in spirit — a fixed-size container where adding a new item past capacity pushes out the oldest one, exactly like a whiteboard with room for only 3 sticky notes: to add a 4th, you must remove the oldest first. We enforce this in code, not just in the type definition, because a type only describes shape — it does nothing to stop a developer from accidentally appending forever and silently recreating Part 1's cost blowout, just with chat turns instead of files.

**The Implementation**

##### `opencode/src/context/memory.ts`

```typescript
import type { ConversationTurn, DynamicMemory } from "./types.js";

/**
 * Manages a bounded conversation history — the "registers" layer.
 * Enforces the cap in code, so no caller can accidentally grow this
 * unbounded, no matter how long the conversation runs.
 */
export class DynamicMemoryManager {
  private turns: ConversationTurn[] = [];
  private readonly maxTurns: number;

  constructor(maxTurns: number = 3) {
    if (maxTurns < 1) {
      // Fail fast on invalid configuration, same philosophy as
      // Part 0's config.ts — bad setup should crash loudly, immediately,
      // not silently misbehave three requests from now.
      throw new Error("maxTurns must be at least 1");
    }
    this.maxTurns = maxTurns;
  }

  /**
   * Adds a completed turn (user message + assistant reply) to memory.
   * If we're at capacity, the OLDEST turn is dropped first — this is
   * the ring-buffer behavior that keeps token usage flat over time,
   * no matter how long the conversation goes on.
   */
  addTurn(turn: ConversationTurn): void {
    this.turns.push(turn);
    if (this.turns.length > this.maxTurns) {
      this.turns.shift(); // remove the oldest turn — FIFO eviction
    }
  }

  /**
   * Returns a read-only snapshot of the current memory state, shaped
   * exactly like the DynamicMemory type defined in Part 2 (1 of 3).
   */
  getMemory(): DynamicMemory {
    return {
      recentTurns: [...this.turns], // copy, so callers can't mutate our internal state
      maxTurns: this.maxTurns,
    };
  }

  /** Clears all history — used when starting a fresh conversation. */
  clear(): void {
    this.turns = [];
  }
}
```

**The Verification**

Let's prove the eviction behavior works exactly as described, with a cap of 2:

```bash
npx tsx -e "
import { DynamicMemoryManager } from './src/context/memory.ts';

const mem = new DynamicMemoryManager(2);
mem.addTurn({ userMessage: 'Q1', assistantMessage: 'A1' });
mem.addTurn({ userMessage: 'Q2', assistantMessage: 'A2' });
console.log('After 2 turns:', mem.getMemory().recentTurns.map(t => t.userMessage));

mem.addTurn({ userMessage: 'Q3', assistantMessage: 'A3' });
console.log('After 3rd turn (should have evicted Q1):', mem.getMemory().recentTurns.map(t => t.userMessage));
"
```

Expected output:

```
After 2 turns: [ 'Q1', 'Q2' ]
After 3rd turn (should have evicted Q1): [ 'Q2', 'Q3' ]
```

`Q1` is gone even though we never explicitly deleted it — the manager enforced the cap automatically. This is the mechanism that keeps a long-running conversation's token cost flat, instead of growing linearly forever the way Part 1's naive file-dump did.

---

## Step 3 — Build the Prompt Assembler

**The Target:** A function, `src/context/assemble.ts`, that takes a `SystemFrame`, `DynamicMemory`, and a list of `TransientFact`s, and turns them into the actual `messages` array the OpenAI API expects — with clear, labeled boundaries between layers instead of one undifferentiated blob.

**The Concept:** This is the literal opposite of Part 1's `concatenateFiles` + one giant string. Instead of one blob, we build a **layered message array**, each layer clearly delimited and placed according to its role — system rules first (stable, cacheable), then relevant facts, then recent history, then the live question. Think of this like a well-organized doctor's chart: allergies and chronic conditions (System Frame) always on the cover page, recent visit notes (Dynamic Memory) in a clearly dated section, and today's specific test results (Transient Fact) clipped on top where the doctor will look first — never all typed into one undifferentiated paragraph.

**The Implementation**

##### `opencode/src/context/assemble.ts`

```typescript
import type OpenAI from "openai";
import type {
  AssembledContext,
  SystemFrame,
  TransientFact,
  DynamicMemory,
} from "./types.js";

type ChatMessage = OpenAI.Chat.Completions.ChatCompletionMessageParam;

/**
 * Renders the SystemFrame into a single system message. This text
 * should be as STABLE as possible across requests — every dynamic
 * detail (files, history, the live question) belongs in later layers,
 * never here. This stability is exactly what enables prompt caching
 * in Part 7 — a cache only helps if this text is byte-identical
 * across many requests.
 */
function renderSystemFrame(frame: SystemFrame): string {
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

/**
 * Renders TransientFacts into a clearly labeled block. Each fact is
 * explicitly tagged with its label (e.g. a file path) so the model
 * can cite WHERE information came from — this becomes important in
 * Part 8 when we measure "faithfulness" (did the model actually use
 * what we gave it, or did it make something up?).
 */
function renderTransientFacts(facts: TransientFact[]): string {
  if (facts.length === 0) {
    return "(No specific files or facts were retrieved for this question.)";
  }
  return facts
    .map((fact) => `--- ${fact.label} ---\n${fact.content}`)
    .join("\n\n");
}

/**
 * Renders DynamicMemory into alternating user/assistant messages —
 * NOT flattened into a single string. Keeping them as distinct
 * ChatCompletionMessage objects preserves the model's native
 * understanding of turn-taking, which a flattened "User said X, then
 * I said Y" paragraph would blur.
 */
function renderDynamicMemory(memory: DynamicMemory): ChatMessage[] {
  const messages: ChatMessage[] = [];
  for (const turn of memory.recentTurns) {
    messages.push({ role: "user", content: turn.userMessage });
    messages.push({ role: "assistant", content: turn.assistantMessage });
  }
  return messages;
}

/**
 * The core assembler: takes our three distinct, typed layers and
 * produces the final `messages` array sent to the LLM. Notice the
 * ORDER is deliberate and fixed:
 *   1. System Frame      (stable, first, cacheable)
 *   2. Transient Facts    (the specific grounding for THIS question)
 *   3. Dynamic Memory     (recent conversational context)
 *   4. The live question  (what we're actually answering right now)
 *
 * This order is not arbitrary — placing the retrieved facts BEFORE
 * the chat history means the model reads "here is ground truth" before
 * "here is what we've been chatting about," reducing the chance it
 * treats casual conversation as more authoritative than actual code.
 */
export function assembleMessages(
  context: AssembledContext,
  liveQuestion: string,
): ChatMessage[] {
  const messages: ChatMessage[] = [];

  messages.push({
    role: "system",
    content: renderSystemFrame(context.systemFrame),
  });

  messages.push({
    role: "system",
    content: `Relevant context for this question:\n\n${renderTransientFacts(context.transientFacts)}`,
  });

  messages.push(...renderDynamicMemory(context.dynamicMemory));

  messages.push({
    role: "user",
    content: liveQuestion,
  });

  return messages;
}
```

**The Verification**

Let's assemble a small example context and print the resulting message array, to see the structure with our own eyes before wiring it to a real API call:

```bash
npx tsx -e "
import { assembleMessages } from './src/context/assemble.ts';

const context = {
  systemFrame: {
    identity: 'You are OpenCode, an AI assistant for the sample-codebase project.',
    rules: ['Only answer using the provided context.', 'Cite the file name when referencing code.'],
    outputFormat: 'Concise plain text, 2-4 sentences.',
  },
  dynamicMemory: {
    recentTurns: [{ userMessage: 'What plans are available?', assistantMessage: 'free, pro, and enterprise.' }],
    maxTurns: 3,
  },
  transientFacts: [
    { label: 'src/auth/user.ts', content: 'const MAX_FAILED_ATTEMPTS = 5;' },
  ],
};

const messages = assembleMessages(context, 'What happens after 5 failed logins?');
console.log(JSON.stringify(messages, null, 2));
"
```

Expected output:

```json
[
  {
    "role": "system",
    "content": "You are OpenCode, an AI assistant for the sample-codebase project.\n\nHard rules you must always follow:\n1. Only answer using the provided context.\n2. Cite the file name when referencing code.\n\nOutput format: Concise plain text, 2-4 sentences."
  },
  {
    "role": "system",
    "content": "Relevant context for this question:\n\n--- src/auth/user.ts ---\nconst MAX_FAILED_ATTEMPTS = 5;"
  },
  {
    "role": "user",
    "content": "What plans are available?"
  },
  {
    "role": "assistant",
    "content": "free, pro, and enterprise."
  },
  {
    "role": "user",
    "content": "What happens after 5 failed logins?"
  }
]
```

Look closely at what just happened: instead of Part 1's single wall of text containing 35 files, the model now receives **exactly one targeted fact** (`MAX_FAILED_ATTEMPTS = 5` from `user.ts`) instead of every generated noise file. This is the direct structural fix to "Lost in the Middle" — there's no longer a "middle" to get lost in.

(For now, we're picking `transientFacts` manually — we don't have a real retrieval system yet. That's the entire subject of Part 3/4. Here in Phase 1, we're proving the *architecture* works; Phase 2 will make fact-selection automatic and smart.)

## Step 4 — Build the Structured `ask` Pipeline

**The Target:** A new script, `src/structured/ask.ts`, that replaces Part 1's `naiveAsk` — using `SystemFrame`, `DynamicMemoryManager`, and `assembleMessages` together, with `transientFacts` selected by a simple (temporary) keyword match instead of dumping the entire codebase.

**The Concept:** This is where the architecture from Steps 1–3 becomes a working pipeline. Crucially, the *only* thing that changes between this and Part 1's `naiveAsk` is *what gets sent* — the API call itself (`client.chat.completions.create`) is identical. This proves the fix is architectural, not a different model or a bigger budget.

For selecting `transientFacts`, we use an intentionally simple placeholder: a keyword-overlap scorer that ranks files by how many question-words appear in them. This is **not** a real retrieval system — it's a deliberately naive stand-in, clearly labeled as such, so Part 3 has an honest, motivated reason to exist: replacing this crude keyword match with real semantic search.

**The Implementation**

##### `opencode/src/structured/selectFacts.ts`

```typescript
import type { LoadedFile } from "../naive/loadCodebase.js";
import type { TransientFact } from "../context/types.js";

/**
 * PLACEHOLDER fact selection: naive keyword overlap scoring.
 *
 * This is intentionally crude — it just counts how many words from
 * the question appear in each file, and returns the top N files.
 * It has no understanding of code structure, semantics, or synonyms.
 * We're using it here ONLY to prove the three-layer architecture
 * works when facts are targeted rather than exhaustive. Part 3 replaces
 * this function's internals with real vector-based semantic search —
 * the rest of the pipeline (assembleMessages, memory, etc.) will not
 * need to change at all, because we designed TransientFact as a stable
 * interface in Part 2 (1 of 3).
 */
export function selectRelevantFacts(
  files: LoadedFile[],
  question: string,
  topN: number = 3,
): TransientFact[] {
  const questionWords = question
    .toLowerCase()
    .split(/\W+/)
    .filter((w) => w.length > 2); // skip tiny/noise words like "a", "is"

  const scored = files.map((file) => {
    const contentLower = file.content.toLowerCase();
    const score = questionWords.reduce((sum, word) => {
      // Count occurrences of this word in the file content.
      const matches = contentLower.split(word).length - 1;
      return sum + matches;
    }, 0);
    return { file, score };
  });

  scored.sort((a, b) => b.score - a.score);

  return scored
    .slice(0, topN)
    .filter((s) => s.score > 0) // don't include totally irrelevant files
    .map((s) => ({
      label: s.file.relativePath,
      content: s.file.content,
    }));
}
```

##### `opencode/src/structured/ask.ts`

```typescript
import { config } from "../config.js";
import { loadCodebase } from "../naive/loadCodebase.js";
import { selectRelevantFacts } from "./selectFacts.js";
import { assembleMessages } from "../context/assemble.js";
import { DynamicMemoryManager } from "../context/memory.js";
import type { SystemFrame } from "../context/types.js";
import OpenAI from "openai";

const client = new OpenAI({ apiKey: config.OPENAI_API_KEY });

// The System Frame is defined ONCE, here, as a stable constant —
// not rebuilt per-request. This is the "firmware" — it does not
// change based on which question is asked.
const SYSTEM_FRAME: SystemFrame = {
  identity: "You are OpenCode, an AI assistant that answers questions about the sample-codebase project.",
  rules: [
    "Only answer using the context explicitly provided to you.",
    "If the provided context does not contain the answer, say so clearly — do not guess.",
    "When referencing code, cite the file name it came from.",
  ],
  outputFormat: "Concise plain text, 2-4 sentences.",
};

// One shared memory manager for this process — in a real multi-user
// app, you'd have one instance per conversation/session, not a single
// global one. We'll address that properly once we introduce a server
// in a later part; for this CLI demo, a single instance is sufficient.
const memory = new DynamicMemoryManager(3);

export async function structuredAsk(codebaseDir: string, question: string): Promise<void> {
  console.log(`📂 Loading codebase from: ${codebaseDir}`);
  const files = await loadCodebase(codebaseDir);
  console.log(`📄 Loaded ${files.length} files (will select only relevant ones below).`);

  // KEY DIFFERENCE from Part 1: instead of concatenating ALL files,
  // we select only the ones relevant to THIS specific question.
  const transientFacts = selectRelevantFacts(files, question, 3);
  console.log(`🎯 Selected ${transientFacts.length} relevant file(s): ${transientFacts.map(f => f.label).join(", ") || "(none matched)"}`);

  const context = {
    systemFrame: SYSTEM_FRAME,
    dynamicMemory: memory.getMemory(),
    transientFacts,
  };

  const messages = assembleMessages(context, question);

  console.log(`\n📞 Sending request to the model...`);
  const startTime = Date.now();

  const response = await client.chat.completions.create({
    model: "gpt-4o-mini",
    messages,
  });

  const elapsedMs = Date.now() - startTime;
  const answer = response.choices[0]?.message?.content ?? "(empty response)";

  console.log(`\n✅ Answer:\n${answer}`);
  console.log(`\n⏱️  Latency: ${elapsedMs}ms`);
  console.log(`🔢 Prompt tokens: ${response.usage?.prompt_tokens ?? "unknown"}`);
  console.log(`🔢 Completion tokens: ${response.usage?.completion_tokens ?? "unknown"}`);
  console.log(`🔢 Total tokens: ${response.usage?.total_tokens ?? "unknown"}`);

  // Record this turn into Dynamic Memory for the next question.
  memory.addTurn({ userMessage: question, assistantMessage: answer });
}
```

##### `opencode/src/structured/run-structured-ask.ts`

```typescript
import { structuredAsk } from "./ask.js";

const question = process.argv[2];

if (!question) {
  console.error("Usage: npx tsx src/structured/run-structured-ask.ts \"your question\"");
  process.exit(1);
}

await structuredAsk("./sample-codebase", question);
```

---

## Step 5 — The Head-to-Head Comparison

**The Target:** Run the exact same question, against the exact same 35-file codebase from Part 1, through both pipelines, and compare the numbers directly.

**The Verification**

```bash
npx tsx src/structured/run-structured-ask.ts "What happens after 5 failed login attempts?"
```

Expected output:

```
📂 Loading codebase from: ./sample-codebase
📄 Loaded 35 files (will select only relevant ones below).
🎯 Selected 1 relevant file(s): src/auth/user.ts

📞 Sending request to the model...

✅ Answer:
After 5 failed login attempts, the account is locked for 15 minutes, as enforced in src/auth/user.ts by the MAX_FAILED_ATTEMPTS check.

⏱️  Latency: 640ms
🔢 Prompt tokens: 318
🔢 Completion tokens: 34
🔢 Total tokens: 352
```

Now the full comparison table, using your own real numbers from Part 1 (3 of 3) and this run:

| Metric | Part 1: Naive (35 files) | Part 2: Structured (35 files) | Change |
|---|---|---|---|
| Prompt tokens | 5,187 | 318 | **−94%** |
| Latency | 2,740ms | 640ms | **−77%** |
| Answer correctness | ❌ Wrong — claimed logic didn't exist | ✅ **Correct**, with file citation | Fixed |

This is the entire thesis of Phase 1 proven with numbers you generated yourself, on your own machine: **the fix was never "a smarter model" or "a bigger context window."** It was refusing to treat the context window as an infinite dumping ground, and instead engineering exactly what goes in, in exactly what order, with exactly what lifetime.

Try a second question to confirm memory carries over correctly:

```bash
npx tsx src/structured/run-structured-ask.ts "What plans are available and how much do they cost?"
```

You should see `subscription.ts` selected as the relevant fact, a correct answer listing free/pro/enterprise pricing, and — if you inspect the assembled messages by temporarily adding a `console.log(JSON.stringify(messages))` line in `ask.ts` — you'd see the previous lockout Q&A now present as a `user`/`assistant` message pair in Dynamic Memory, exactly as designed in Step 3.

---

## What's Next: Part 3

Our `selectRelevantFacts` function is still crude — it's naive keyword counting, not real understanding. It will fail the moment a user asks "how does authentication throttling work?" (no literal word overlap with `MAX_FAILED_ATTEMPTS`, `lockedUntil`, etc.) even though the file is obviously relevant to a human reader.

**Part 3** replaces this keyword hack with a real **retrieval system**: chunking code, embedding it into vectors, and performing semantic similarity search — so the system finds relevant code by *meaning*, not just literal word matches. And, following this series' pattern, we'll build the naive version first (fixed-size character chunking) and watch it break in its own specific way — chunks that cut a function definition in half, or separate an import from the code that depends on it — before fixing it with AST-aware semantic chunking in Part 4.

---

**✅ Part 2 is now complete.** You've built a type-safe, three-layer context architecture (System Frame / Dynamic Memory / Transient Fact), a bounded memory manager that prevents unbounded growth, a real assembler enforcing deliberate message ordering, and proven — with a direct before/after comparison on identical input — a 94% token reduction, 77% latency reduction, and a correctness fix, all from architecture alone.
