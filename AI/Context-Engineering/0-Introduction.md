# Part 0: Series Roadmap & Mental Model

## 1. Why This Series Exists

Almost every AI tutorial teaches you to write a clever sentence (a "prompt") and hope the model behaves. That works fine for a demo. It collapses the moment you have a real codebase, real concurrent users, and a real invoice from an AI provider at the end of the month.

This series teaches a different discipline: **context engineering**.

> **Context engineering** is the practice of treating the LLM's **context window** — the total amount of text it can "see" at once — as a scarce, expensive, and unreliable hardware resource, and building deterministic software *around* it so the overall system behaves predictably, cheaply, and quickly, even though the component doing the "thinking" is a probabilistic model.

The metaphor we'll keep returning to throughout the series:

> **The context window is not a chat box. It is volatile, high-latency RAM with unreliable attention.**

- **Volatile** — nothing persists between requests unless you explicitly re-send it (like RAM losing its contents when the power cuts).
- **High-latency** — the more you cram in, the slower and more expensive every single request becomes.
- **Unreliable attention** — the model doesn't weigh every word in the prompt equally. Information buried in the middle of a huge prompt often gets silently ignored — a phenomenon researchers call **"Lost in the Middle."**

A junior engineer pastes an entire codebase into a chat window and hopes for the best. A senior engineer designs a **memory hierarchy** — deciding what always stays visible (like a CPU's L1 cache), what gets fetched only when needed (like RAM), and what stays untouched until explicitly requested (like disk storage). By the end of this series, you'll think and build like the second engineer.

---

## 2. The Running Build: OpenCode

Every part of this series adds exactly one deliberate, load-bearing layer to a single, continuously evolving application: **OpenCode** — a command-line AI assistant that answers questions about a real codebase and its documentation, in the same category as tools like Cursor or Aider, except we're building the engine ourselves so you understand every layer inside it.

We picked this project because it forces us to need *every* layer we're going to build:

- It has to read source code and docs correctly → **Knowledge Layer**
- It has to run tests and fix its own mistakes → **Control Layer**
- It has to not be slow or bankrupt whoever's paying the API bill → **Production Layer**
- All of the above sits on top of a disciplined prompt structure → **Mental Model**

By the end of the series you won't have a toy chatbot. You'll have a working, instrumented, cost-aware CLI tool that happens to have an LLM as one of its components — not its entire personality.

---

## 3. The Full Series Map

```
Part 0  → Roadmap + Dev Environment Setup                         (you are here)

PHASE 1 — THE MENTAL MODEL (Context over Prompts)
  Part 1  → Naive build: stuffing a whole codebase into one prompt, and watching it break
  Part 2  → The fix: System Frame / Dynamic Memory / Transient Fact prompt architecture

PHASE 2 — THE KNOWLEDGE LAYER (Retrieval Systems)
  Part 3  → Naive fixed-size chunking + vector search, and watching retrieval mangle code
  Part 4  → AST-based semantic chunking, reranking, and the Cache-vs-Fetch (CAG) decision

PHASE 3 — THE CONTROL LAYER (Agents & Tools)
  Part 5  → Naive "20 tools at once" agent loop, and watching it spiral into cost/loop chaos
  Part 6  → The fix: deterministic state-machine orchestration, tool pruning, and MCP

PHASE 4 — THE PRODUCTION LAYER (Performance & Evals)
  Part 7  → Context caching for latency & cost (structuring prompts for provider-side caching)
  Part 8  → Deterministic evals: retrieval recall, faithfulness, retrieval precision
```

Every "How It Breaks" section is not filler — you will **run the broken version yourself**, see the bad latency/cost/output with your own eyes, and then fix it in the following part.

---

## 4. The Architecture We're Building Toward

```
┌─────────────────────────────────────────────────────────┐
│                    PRODUCTION LAYER                      │  Phase 4 — Caching, Pruning, Evals
├─────────────────────────────────────────────────────────┤
│                     CONTROL LAYER                        │  Phase 3 — State Machine, Tools, MCP
├─────────────────────────────────────────────────────────┤
│                     KNOWLEDGE LAYER                      │  Phase 2 — Chunking, Vector DB, Reranking
├─────────────────────────────────────────────────────────┤
│                     MENTAL MODEL                         │  Phase 1 — Prompt Framework, Registers
└─────────────────────────────────────────────────────────┘
```

Every layer sits directly on top of the one below it. You cannot skip layers — a caching strategy (Phase 4) is meaningless if your prompt structure (Phase 1) changes on every request, and tool-calling (Phase 3) is dangerous if your retrieval (Phase 2) hands the model garbage. That's why we build bottom-up, and why this series must be followed in order.

## 5. What We're Building Right Now: The Ground Floor

Before we can write a single line of "AI" code, we need solid ground to build on. In this part, we will, in strict dependency order:

1. Verify the machine has the right tools installed (you can't build on unstable ground)
2. Scaffold the project skeleton (a foundation slab before walls)
3. Configure TypeScript (the rulebook that keeps our code safe as it grows across 8 parts)
4. Set up environment/secret configuration safely (never hardcode API keys)

Step 5 (the "dial tone" verification script) comes in the next message — it depends on everything here being done first.

---

### Step 1 — Verify Prerequisites

**The Target:** A working Node.js + npm installation, and Git.

**The Concept:** Before an electrician wires a house, they test that the breaker panel actually has power. We're doing the same sanity check on your machine — if Node isn't installed correctly, every future step in this series fails in confusing, hard-to-debug ways. Catching it now saves hours later.

**The Implementation**

Open a terminal and run:

```bash
node -v
npm -v
git --version
```

You need:
- **Node.js v18.18.0 or newer** (we rely on the native `fetch` API built into Node 18+, and modern JavaScript syntax)
- **npm v9 or newer** (ships bundled with Node)
- **Git** (any recent version, for version control as the project grows)

If Node isn't installed, or your version is older, install it via [nvm](https://github.com/nvm-sh/nvm) (Node Version Manager) — this lets you switch Node versions per-project without messing up your system:

```bash
# macOS / Linux
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install 20
nvm use 20
```

On Windows, use [nvm-windows](https://github.com/coreybutler/nvm-windows) or install Node directly from [nodejs.org](https://nodejs.org).

**The Verification**

```bash
node -v
# should print v18.18.0 or higher, e.g. v20.11.0

npm -v
# should print 9.x or higher

git --version
# should print git version 2.x
```

If all three commands print version numbers with no "command not found" errors, you're clear to proceed.

---

### Step 2 — Scaffold the Project Skeleton

**The Target:** A new project directory called `opencode` with a `package.json` file — the "birth certificate" of any Node.js project.

**The Concept:** `package.json` is like a recipe card taped to the front of your kitchen — it lists exactly what ingredients (dependencies) the project needs and what commands (scripts) are available to "cook" it (run, build, test). Every tool in the Node ecosystem — npm, TypeScript, your bundler — reads this file first to understand the project.

**The Implementation**

```bash
mkdir opencode
cd opencode
git init
npm init -y
```

This creates a default `package.json`. We'll now replace it with a deliberately configured version instead of the auto-generated placeholder, because we know exactly what we need:

##### `opencode/package.json`

```json
{
  "name": "opencode",
  "version": "0.1.0",
  "description": "A from-scratch AI coding assistant CLI, built part-by-part to teach context engineering.",
  "type": "module",
  "main": "dist/index.js",
  "bin": {
    "opencode": "dist/index.js"
  },
  "scripts": {
    "dev": "tsx src/index.ts",
    "build": "tsc -p tsconfig.json",
    "start": "node dist/index.js"
  },
  "engines": {
    "node": ">=18.18.0"
  },
  "license": "MIT"
}
```

**Line-by-line, why each field exists:**

- `"type": "module"` — tells Node to treat `.js` files as native ES Modules (`import`/`export` syntax) instead of the older CommonJS (`require`). We're building a new project in 2024+, so we use the modern standard from day one — retrofitting this later is painful.
- `"main": "dist/index.js"` — points to the *compiled* JavaScript output, not our TypeScript source. `dist/` will be generated by the TypeScript compiler in Step 3.
- `"bin": { "opencode": "dist/index.js" }` — registers a CLI command named `opencode`, pointing at the compiled entry file. This is what lets this project eventually be invoked as a real terminal command (e.g., `opencode ask "..."`) instead of only ever being run via `node`. We won't wire up full CLI argument parsing until it's needed in a later part, but declaring this now means the project structure never has to be reshuffled to support it.
- `"scripts.dev"` — uses `tsx` (a fast TypeScript executor) so we can run `.ts` files directly during development without a manual compile step, exactly like `nodemon` but TypeScript-aware.
- `"scripts.build"` / `"scripts.start"` — the production path: compile TypeScript to plain JavaScript, then run the compiled output. Production tools should never run raw `.ts` files directly — compiling first catches type errors before the tool ever ships.
- `"engines"` — a guardrail that documents the minimum Node version, so a teammate — or future you — doesn't run this on an incompatible Node version and get baffling errors.

**The Verification**

```bash
cat package.json
```

You should see the exact JSON above echoed back. If the file is malformed JSON (e.g., missing a comma), `npm install` in the next step will fail immediately with a parse error — so this is a good moment to double-check it visually.

---

### Step 3 — Install and Configure TypeScript

**The Target:** TypeScript installed as a dev dependency, plus a `tsconfig.json` file.

**The Concept:** JavaScript has no built-in "spellchecker" — it happily lets you call `.toUpperCase()` on a number and only crashes at runtime, often in production, in front of a user. TypeScript adds a static type system on top of JavaScript: a compile-time check that catches these mistakes *before* the code ever runs — like a building inspector checking blueprints before construction starts, not after the building is already standing. Since we're building an increasingly complex system across 8 parts — with LLM API responses, vector embeddings, and agent state all flowing through our code — we want the compiler catching shape mismatches early, not a confused `undefined is not a function` error at 2am.

We'll also install `tsx` (lets us run `.ts` files directly in development, without a manual compile step) and `@types/node` (type definitions for Node's built-in APIs like `fs` and `process`, so TypeScript understands them).

**The Implementation**

```bash
npm install --save-dev typescript tsx @types/node
```

##### `opencode/tsconfig.json`

```json
{
  "compilerOptions": {
    /* --- Module system: match package.json's "type": "module" --- */
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "target": "ES2022",

    /* --- Output --- */
    "outDir": "dist",
    "rootDir": "src",

    /* --- Strictness: catch mistakes at compile time, not runtime --- */
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,

    /* --- Interop & safety --- */
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,

    /* --- Developer experience --- */
    "resolveJsonModule": true,
    "declaration": false,
    "sourceMap": true
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
```

**Why each block exists (not decoration — every line has a job):**

- `"module": "NodeNext"` / `"moduleResolution": "NodeNext"` — tells TypeScript to compile using Node's native ESM rules, matching the `"type": "module"` we set in `package.json` in Step 2. If these two settings disagree, imports silently fail at runtime with cryptic `ERR_MODULE_NOT_FOUND` errors — a classic beginner trap we're avoiding by wiring it correctly from day one.
- `"target": "ES2022"` — compiles down to modern JavaScript syntax that Node 18+ understands natively, so we don't waste compile time transpiling to ancient JS nobody needs.
- `"outDir"` / `"rootDir"` — draws a clean line between source code (`src/`, what we write) and compiled output (`dist/`, what actually runs in production). This mirrors the `main`/`bin` fields we set in `package.json`.
- `"strict": true` — the single most important flag. It bundles on ~8 stricter checks (like disallowing implicit `any` types). Think of it as the difference between a spellchecker that only catches misspelled words versus one that also catches grammar and logic errors.
- `"noUncheckedIndexedAccess": true` — when we later index into arrays of retrieved documents or chunks (Phase 2), this forces TypeScript to acknowledge that `array[i]` might be `undefined` (e.g., empty search results) rather than assuming it always exists. This single setting prevents a huge class of "cannot read property of undefined" crashes later in the series.
- `"skipLibCheck": true` — skips type-checking inside `node_modules` dependencies (which we don't control and can trust are already checked), keeping our compile times fast.

**The Verification**

```bash
npx tsc --version
# Should print: Version 5.x.x

npx tsc --noEmit
```

`--noEmit` type-checks the project without writing any files. Since we haven't created `src/` yet, you should see an error like:

```
error TS18003: No inputs were found in config file '...tsconfig.json'.
```

**This error is expected and good** — it confirms TypeScript is correctly reading your config and looking in the right place (`src/`). It'll disappear the moment we add our first file in Step 4.

---

### Step 4 — Environment & Secret Configuration

**The Target:** A safe, validated way to load secrets (like your LLM API key) without ever hardcoding them into source code.

**The Concept:** Never write an API key directly into a `.ts` file. If you did, and later pushed this code to GitHub, that key would be exposed to the entire internet within minutes — bots constantly scan public repos for exactly this mistake. Instead, we use **environment variables**: values injected into the process from *outside* the code, like a hotel key card that's issued at check-in and works only for your stay, rather than a key permanently welded into the door.

We'll use two small, well-established libraries:
- **`dotenv`** — loads variables from a local `.env` file into `process.env` during development (in real production deployments, the hosting platform injects these directly, so `.env` files are a dev-only convenience).
- **`zod`** — validates that required environment variables actually exist and are the right shape *before* our app does anything else. This is a **fail-fast** pattern: better to crash immediately with a clear "Missing OPENAI_API_KEY" message than to fail two hours later mid-request with an obscure `401 Unauthorized`.

**The Implementation**

```bash
npm install dotenv zod openai
mkdir src
```

We install the `openai` SDK now because Step 5's dial-tone script needs it — we're using OpenAI as our LLM provider for this series (the same patterns apply directly to Anthropic, Google, or any other provider; we'll note where they diverge).

##### `opencode/.env.example`

```bash
# Copy this file to .env and fill in your real key.
# .env is gitignored — .env.example is the template that IS committed,
# so teammates (or future you) know exactly what variables are required.

OPENAI_API_KEY=sk-your-key-here
```

##### `opencode/.env`

```bash
OPENAI_API_KEY=sk-REPLACE_WITH_YOUR_REAL_KEY
```

> Get a real key from https://platform.openai.com/api-keys. If you don't have an OpenAI account, create one — new accounts typically get a small free credit grant, which is plenty for this entire series if you're mindful (Part 7 specifically teaches you how to keep costs low).

##### `opencode/.gitignore`

```
# Dependencies
node_modules/

# Compiled output
dist/

# Secrets — never commit these
.env

# OS/editor noise
.DS_Store
*.log
```

This is the single most important file in the whole setup from a security standpoint: it tells Git to never track `node_modules` (huge, regenerable), `dist` (regenerable build output), or `.env` (your actual secret key). Create this **before** your first `git add`, or your key could end up in Git history permanently — simply deleting the file later doesn't erase it from history.

##### `opencode/src/config.ts`

```typescript
import "dotenv/config"; // side-effect import: reads .env and populates process.env
import { z } from "zod";

/**
 * Schema describing every environment variable our app needs.
 * Think of this as a bouncer's checklist at the door: if a required
 * ID (env var) is missing or malformed, nobody gets in — the app
 * refuses to start rather than limping along and failing later,
 * deep inside an API call, with a confusing error.
 */
const envSchema = z.object({
  OPENAI_API_KEY: z
    .string()
    .min(1, "OPENAI_API_KEY is required")
    .startsWith("sk-", "OPENAI_API_KEY should start with 'sk-'"),
});

// safeParse (not parse) lets us handle the failure case ourselves
// with a clean, readable error instead of an unhandled exception.
const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error("❌ Invalid environment configuration:");
  // .flatten() turns Zod's error tree into a simple, readable object
  console.error(parsedEnv.error.flatten().fieldErrors);
  process.exit(1); // stop immediately — do not let the app run half-configured
}

// From this point on, `config.OPENAI_API_KEY` is typed as `string`,
// guaranteed non-empty, guaranteed to start with "sk-" — every other
// file in the project can trust this value without re-checking it.
export const config = parsedEnv.data;
```

**The Verification**

Temporarily break your `.env` on purpose to prove the safety net actually works before trusting it:

```bash
echo "OPENAI_API_KEY=garbage" > .env
npx tsx -e "import('./src/config.ts')"
```

Expected output:

```
❌ Invalid environment configuration:
{ OPENAI_API_KEY: [ "OPENAI_API_KEY should start with 'sk-'" ] }
```

The process should also exit with a non-zero status code (confirm with `echo $?` on macOS/Linux immediately after — it should print `1`, not `0`).

Now restore your real key:

```bash
echo "OPENAI_API_KEY=sk-REPLACE_WITH_YOUR_REAL_KEY" > .env
npx tsx -e "import('./src/config.ts').then(m => console.log('✅ Config loaded OK'))"
```

Expected output:

```
✅ Config loaded OK
```

If you see that, edit `.env` one more time and paste your **actual** OpenAI key in — Step 5 needs it to make a real network call.

### Step 5 — The "Dial Tone" Script

**The Target:** A single minimal script, `src/index.ts`, that makes one real call to the OpenAI API and prints the response.

**The Concept:** Before you build a phone system, you pick up the receiver and check for a dial tone — a simple, boring confirmation that the wire is connected and the line works. We're doing the same thing here: before Part 1 introduces any complexity (prompt structure, retrieval, agents), we need rock-solid proof that (a) your API key is valid, (b) your network/firewall allows the request through, and (c) the SDK is wired up correctly. If this fails, nothing else in the series can possibly work — so we isolate and verify it now, alone, with nothing else to blame.

**The Implementation**

##### `opencode/src/index.ts`

```typescript
import { config } from "./config.js";
// Note the ".js" extension on a ".ts" import — this looks wrong but is
// correct and required. Node's native ESM resolver (which we configured
// via "moduleResolution": "NodeNext" in tsconfig.json) resolves imports
// based on the COMPILED output file names, not the source file names.
// TypeScript understands this convention and rewrites nothing — the
// ".ts" file is compiled to "config.js", so we import it as such.
import OpenAI from "openai";

/**
 * A minimal, single-purpose "dial tone" check.
 * No prompt engineering, no retrieval, no agents — just proof that
 * the wire between our code and the LLM provider is live.
 */
async function checkDialTone(): Promise<void> {
  const client = new OpenAI({
    apiKey: config.OPENAI_API_KEY,
  });

  console.log("📞 Dialing OpenAI...");

  const startTime = Date.now(); // crude latency measurement — we'll formalize this in Part 4/7

  try {
    const response = await client.chat.completions.create({
      model: "gpt-4o-mini", // small, cheap, fast model — perfect for a connectivity check
      messages: [
        { role: "user", content: "Reply with exactly one word: 'pong'." },
      ],
      max_tokens: 5, // hard cap — we only expect one short word back
    });

    const elapsedMs = Date.now() - startTime;
    const reply = response.choices[0]?.message?.content ?? "(empty response)";
    // The "?? " (nullish coalescing) matters here: TypeScript's
    // "noUncheckedIndexedAccess" (set in Step 3) forces us to handle
    // the case where choices[0] might not exist — e.g. if the API
    // returns an empty array unexpectedly. We never assume the shape
    // of external data is guaranteed.

    console.log(`✅ Response: "${reply.trim()}"`);
    console.log(`⏱️  Latency: ${elapsedMs}ms`);
    console.log(`🔢 Tokens used: ${response.usage?.total_tokens ?? "unknown"}`);
  } catch (error) {
    // Fail loudly and specifically — a vague "it didn't work" is
    // useless for debugging. We distinguish between an API-reported
    // error (bad key, rate limit, etc.) and an unexpected local error
    // (network down, bug in our code).
    if (error instanceof OpenAI.APIError) {
      console.error(`❌ OpenAI API error [${error.status}]: ${error.message}`);
    } else {
      console.error("❌ Unexpected error:", error);
    }
    process.exit(1);
  }
}

checkDialTone();
```

**The Verification**

Run the script in development mode using the `dev` script we defined in `package.json`:

```bash
npm run dev
```

Expected output (latency and token count will vary slightly):

```
📞 Dialing OpenAI...
✅ Response: "pong"
⏱️  Latency: 612ms
🔢 Tokens used: 24
```

If you instead see:

```
❌ OpenAI API error [401]: Incorrect API key provided...
```

→ your `.env` key is wrong or has extra whitespace/quotes — re-copy it directly from the OpenAI dashboard.

If you see a timeout or `ENOTFOUND` error → check your internet connection or corporate firewall/proxy settings.

Now prove the **production path** also works, not just the dev shortcut:

```bash
npm run build
npm run start
```

`npm run build` compiles every `.ts` file in `src/` into plain `.js` inside `dist/` (per our `tsconfig.json`), and `npm run start` runs that compiled output directly with `node`, with no TypeScript tooling involved at all — exactly how this tool will run once packaged/deployed in later parts. You should see the identical `pong` output. If both the `dev` and `build`/`start` paths work identically, your entire foundation for the rest of the series is solid.

---

## 6. Project Structure Checkpoint

At the end of Part 0, your directory should look exactly like this:

```
opencode/
├── .env                  (gitignored — your real secret key)
├── .env.example          (committed — template for others)
├── .gitignore
├── package.json
├── tsconfig.json
├── dist/                 (generated by `npm run build`, gitignored)
│   ├── config.js
│   └── index.js
└── src/
    ├── config.ts
    └── index.ts
```

Commit this now, before moving on:

```bash
git add .
git status
# Confirm .env is NOT listed — only .env.example should appear
git commit -m "Part 0: project scaffold, TypeScript config, secrets, dial-tone check"
```

---

## 7. What's Next: Part 1

Right now, `index.ts` does something almost embarrassingly simple: it sends one hardcoded sentence and gets one word back. In **Part 1**, we push this same dial-tone connection to its breaking point on purpose — we'll point it at a real, multi-file codebase, write code that recursively reads every file into one giant string, and stuff the *entire thing* into a single prompt alongside a user's question.

It will appear to work at first, on a small folder. Then we'll scale it up and watch it fail in exactly the ways experienced engineers warn about: ballooning latency before the first token even arrives, a shockingly large token bill for one single question, and — most damning of all — the model confidently ignoring a critical function definition because it was buried in the middle of a 50,000-token wall of text. You'll see this "Lost in the Middle" failure with your own eyes, on your own machine, using your own API key — not as an abstract claim in a blog post.

---

**✅ Part 0 is now complete.** Foundation is poured: Node/TypeScript environment verified, `opencode` project scaffolded, strict TypeScript configured, secrets safely loaded and validated, and a working end-to-end call to the OpenAI API proven on both the dev and production paths.

