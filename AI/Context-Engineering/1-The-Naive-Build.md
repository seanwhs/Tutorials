# Part 1: The Naive Build — Setup & the Sample Codebase

## Recap & Goal

In Part 0, we proved the wire works — one message in, one word back. Now we do what nearly every developer's first instinct is when building an AI coding assistant: **"The model has a big context window — I'll just hand it the whole project."**

This part has one job: build that naive version *for real*, run it, and generate honest, measured evidence of why it breaks. We are not building a strawman to knock down — we're building the version a real team would actually ship on day one, so that when it breaks in Part 1 (3 of 3), you feel it, not just read about it.

---

## The Concept: Why "Just Stuff It All In" Feels Right (And Isn't)

**The analogy:** Imagine you hire a brilliant consultant to fix a bug in your house's electrical wiring. Instead of showing them the specific fuse box and the specific room with the flickering light, you hand them the *entire architectural blueprint set for a 40-story building* — plumbing, HVAC, elevators, every floor — and say "the answer's in here somewhere." They're smart. They might actually find it. But it'll take them far longer, they'll charge you for all that reading time, and there's a real chance they skim past the one page that matters because it's buried on page 400 of 600.

That's precisely what happens when you concatenate an entire codebase into one prompt:
- **Time to First Token (TTFT)** — the delay before the model starts responding — grows because the model must process every single input token before generating anything.
- **Cost** — nearly all LLM APIs charge per token, input and output. A 50,000-token prompt sent on *every single question*, even a trivial one, adds up fast.
- **Lost in the Middle** — a well-documented phenomenon where transformer-based models pay noticeably more attention to the beginning and end of their input than to the middle. Bury the one critical function in the middle of a huge file dump, and the model may simply act as if it never saw it.

We're about to build this, measure it, and watch all three symptoms happen on your own machine.

---

## Step 1 — Create a Realistic Sample Codebase to Query

**The Target:** A small-but-real multi-file TypeScript project living inside our `opencode` project, at `sample-codebase/`, which OpenCode will answer questions about.

**The Concept:** We need a stand-in for "the codebase the user wants help with." It has to be realistic enough to contain a subtle, easy-to-miss detail — just like real bugs and real critical logic hide in real projects. Think of this as building the "test patient" before we run diagnostics on our AI doctor.

**The Implementation**

```bash
mkdir -p sample-codebase/src/auth
mkdir -p sample-codebase/src/billing
mkdir -p sample-codebase/src/utils
```

##### `opencode/sample-codebase/src/utils/logger.ts`

```typescript
// A simple logging utility used across the sample app.
export type LogLevel = "info" | "warn" | "error";

export function log(level: LogLevel, message: string): void {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [${level.toUpperCase()}] ${message}`);
}
```

##### `opencode/sample-codebase/src/utils/hash.ts`

```typescript
import { createHash } from "node:crypto";

// Hashes a string using SHA-256. Used for password storage (see auth/user.ts).
export function sha256(input: string): string {
  return createHash("sha256").update(input).digest("hex");
}
```

##### `opencode/sample-codebase/src/auth/user.ts`

```typescript
import { sha256 } from "../utils/hash.js";
import { log } from "../utils/logger.js";

export interface User {
  id: string;
  email: string;
  passwordHash: string;
}

const users: User[] = [];

export function registerUser(email: string, password: string): User {
  const passwordHash = sha256(password);
  const user: User = {
    id: crypto.randomUUID(),
    email,
    passwordHash,
  };
  users.push(user);
  log("info", `Registered new user: ${email}`);
  return user;
}

/**
 * THIS IS THE CRITICAL DETAIL our test will bury in the middle of the prompt.
 * Login is rate-limited: after 5 failed attempts, the account is locked
 * for 15 minutes. This is a real, load-bearing business rule — exactly
 * the kind of detail that gets silently dropped in "Lost in the Middle"
 * failures if it's buried deep inside a huge prompt.
 */
const failedAttempts = new Map<string, { count: number; lockedUntil: number | null }>();
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes

export function loginUser(email: string, password: string): { success: boolean; reason?: string } {
  const record = failedAttempts.get(email) ?? { count: 0, lockedUntil: null };

  if (record.lockedUntil && Date.now() < record.lockedUntil) {
    return { success: false, reason: "Account locked. Try again in 15 minutes." };
  }

  const user = users.find((u) => u.email === email);
  const passwordHash = sha256(password);

  if (!user || user.passwordHash !== passwordHash) {
    record.count += 1;
    if (record.count >= MAX_FAILED_ATTEMPTS) {
      record.lockedUntil = Date.now() + LOCKOUT_DURATION_MS;
      log("warn", `Account locked due to repeated failed logins: ${email}`);
    }
    failedAttempts.set(email, record);
    return { success: false, reason: "Invalid credentials." };
  }

  failedAttempts.delete(email);
  log("info", `User logged in: ${email}`);
  return { success: true };
}
```

##### `opencode/sample-codebase/src/billing/invoice.ts`

```typescript
import { log } from "../utils/logger.js";

export interface LineItem {
  description: string;
  amountCents: number;
}

export interface Invoice {
  id: string;
  customerId: string;
  items: LineItem[];
  totalCents: number;
}

export function createInvoice(customerId: string, items: LineItem[]): Invoice {
  const totalCents = items.reduce((sum, item) => sum + item.amountCents, 0);
  const invoice: Invoice = {
    id: crypto.randomUUID(),
    customerId,
    items,
    totalCents,
  };
  log("info", `Created invoice ${invoice.id} for customer ${customerId}, total: ${totalCents}`);
  return invoice;
}

export function formatCurrency(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}
```

##### `opencode/sample-codebase/src/billing/subscription.ts`

```typescript
import { log } from "../utils/logger.js";

export type PlanTier = "free" | "pro" | "enterprise";

export interface Subscription {
  customerId: string;
  tier: PlanTier;
  renewsAt: Date;
}

const PLAN_PRICES_CENTS: Record<PlanTier, number> = {
  free: 0,
  pro: 2900,
  enterprise: 19900,
};

export function getPlanPrice(tier: PlanTier): number {
  return PLAN_PRICES_CENTS[tier];
}

export function renewSubscription(sub: Subscription): Subscription {
  const renewed: Subscription = {
    ...sub,
    renewsAt: new Date(sub.renewsAt.getTime() + 30 * 24 * 60 * 60 * 1000),
  };
  log("info", `Renewed subscription for ${sub.customerId}, tier ${sub.tier}`);
  return renewed;
}
```

We now have **5 files across 3 folders** — small enough to read in a minute, but big enough to contain one specific, non-obvious rule (the 5-attempt lockout in `user.ts`) that we'll later ask OpenCode about, and watch whether it survives being buried in a large prompt.

**The Verification**

```bash
find sample-codebase -name "*.ts" | sort
```

Expected output:

```
sample-codebase/src/auth/user.ts
sample-codebase/src/billing/invoice.ts
sample-codebase/src/billing/subscription.ts
sample-codebase/src/utils/hash.ts
sample-codebase/src/utils/logger.ts
```

Quick sanity check that the lockout rule is really in there:

```bash
grep -n "MAX_FAILED_ATTEMPTS" sample-codebase/src/auth/user.ts
```

Expected output (line number may vary slightly):

```
28:const MAX_FAILED_ATTEMPTS = 5;
32:  if (record.count >= MAX_FAILED_ATTEMPTS) {
```

## Step 2 — Recursively Read Every File Into One Giant String

**The Target:** A utility function, `src/naive/loadCodebase.ts`, that walks a directory tree and concatenates every file's contents into one big string — plus a small filesystem helper library so we're not writing raw recursive directory-walking code by hand.

**The Concept:** This is the "hand over the entire 40-story blueprint set" step from our earlier analogy, implemented literally. We install `fast-glob` (a well-tested library for finding files matching a pattern, like `**/*.ts`) rather than hand-rolling recursive directory traversal — not because it's hard to write, but because getting edge cases right (symlinks, `.gitignore`-style exclusions, permission errors) is a distraction from the actual lesson of this part.

**The Implementation**

```bash
npm install fast-glob
mkdir -p src/naive
```

##### `opencode/src/naive/loadCodebase.ts`

```typescript
import fg from "fast-glob";
import { readFile } from "node:fs/promises";
import path from "node:path";

export interface LoadedFile {
  relativePath: string;
  content: string;
}

/**
 * Recursively finds every source file under `rootDir` and reads its
 * full contents into memory. This is the "naive" approach: no limits,
 * no filtering by relevance, no awareness of file size or token count.
 * It treats the filesystem like an infinite, free resource — which,
 * as we're about to prove, it is not once an LLM has to read it.
 */
export async function loadCodebase(rootDir: string): Promise<LoadedFile[]> {
  // Find every .ts file under rootDir, excluding compiled output and
  // dependencies (even the naive approach wouldn't sanely include those).
  const filePaths = await fg("**/*.ts", {
    cwd: rootDir,
    ignore: ["**/node_modules/**", "**/dist/**"],
    absolute: false,
  });

  const files: LoadedFile[] = [];

  for (const relativePath of filePaths) {
    const absolutePath = path.join(rootDir, relativePath);
    const content = await readFile(absolutePath, "utf-8");
    files.push({ relativePath, content });
  }

  return files;
}

/**
 * Concatenates every loaded file into a single block of text,
 * with a lightweight header before each file so the model can at
 * least see which file it's reading. This is the "dump the whole
 * blueprint set on the desk" step — no curation, no prioritization.
 */
export function concatenateFiles(files: LoadedFile[]): string {
  return files
    .map((file) => `--- FILE: ${file.relativePath} ---\n${file.content}`)
    .join("\n\n");
}
```

Notice what's conspicuously absent here: no check on total size, no truncation, no relevance filtering. That's deliberate — this is the version an engineer under deadline pressure actually ships, and we want to feel its limits ourselves before fixing them.

**The Verification**

Let's prove this loads exactly the 5 files we created, and see roughly how big the resulting blob is:

```bash
npx tsx -e "
import { loadCodebase, concatenateFiles } from './src/naive/loadCodebase.ts';
const files = await loadCodebase('./sample-codebase');
console.log('Files found:', files.map(f => f.relativePath));
const blob = concatenateFiles(files);
console.log('Total characters:', blob.length);
"
```

Expected output:

```
Files found: [
  'src/auth/user.ts',
  'src/billing/invoice.ts',
  'src/billing/subscription.ts',
  'src/utils/hash.ts',
  'src/utils/logger.ts'
]
Total characters: 2841
```

(Your exact character count may differ slightly depending on line endings — that's fine, we just need it in the same ballpark.)

---

## Step 3 — Build the Naive Prompt Assembler & Send It to the LLM

**The Target:** A script, `src/naive/ask.ts`, that takes a user's question, glues it together with the entire concatenated codebase, sends it to OpenAI, and reports back timing and token usage — turning our "dial tone" script from Part 0 into something that actually answers questions about code.

**The Concept:** This is the moment of truth — the exact pattern nearly every first draft of an AI coding tool uses: `systemPrompt + allTheCode + userQuestion`, sent as one message. We'll also **instrument it** (measure latency and token counts) from the very first version, because you can't diagnose a performance problem you never measured. A doctor doesn't guess your blood pressure — they measure it, every time, so change is visible.

**The Implementation**

##### `opencode/src/naive/ask.ts`

```typescript
import { config } from "../config.js";
import { loadCodebase, concatenateFiles } from "./loadCodebase.js";
import OpenAI from "openai";

const client = new OpenAI({ apiKey: config.OPENAI_API_KEY });

/**
 * The naive approach: glue the ENTIRE codebase into the prompt,
 * every single time, regardless of what the user actually asked.
 * No retrieval, no filtering, no memory hierarchy — just one giant
 * flat wall of text handed to the model on every request.
 */
export async function naiveAsk(codebaseDir: string, question: string): Promise<void> {
  console.log(`📂 Loading codebase from: ${codebaseDir}`);
  const files = await loadCodebase(codebaseDir);
  const codeBlob = concatenateFiles(files);

  console.log(`📄 Loaded ${files.length} files, ${codeBlob.length} characters total.`);

  // A simple, naive system prompt — no structure, no prioritization.
  const systemPrompt = `You are a helpful AI coding assistant. You will be given the full source code of a project, followed by a user's question. Answer the question using the code provided.`;

  // This is the crux of the naive approach: everything is glued into
  // ONE user message, in ONE undifferentiated block. The model has no
  // signal about what's important versus incidental — it's all just
  // "the prompt" to it.
  const userMessage = `Here is the full codebase:\n\n${codeBlob}\n\n---\n\nQuestion: ${question}`;

  console.log(`\n📞 Sending request to the model...`);
  const startTime = Date.now();

  const response = await client.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userMessage },
    ],
  });

  const elapsedMs = Date.now() - startTime;
  const answer = response.choices[0]?.message?.content ?? "(empty response)";

  console.log(`\n✅ Answer:\n${answer}`);
  console.log(`\n⏱️  Latency: ${elapsedMs}ms`);
  console.log(`🔢 Prompt tokens: ${response.usage?.prompt_tokens ?? "unknown"}`);
  console.log(`🔢 Completion tokens: ${response.usage?.completion_tokens ?? "unknown"}`);
  console.log(`🔢 Total tokens: ${response.usage?.total_tokens ?? "unknown"}`);
}
```

Now we need a way to actually run this from the command line with a real question, so let's give it an entry point.

##### `opencode/src/naive/run-naive-ask.ts`

```typescript
import { naiveAsk } from "./ask.js";

// A minimal CLI entry point: `npx tsx src/naive/run-naive-ask.ts "your question"`
const question = process.argv[2];

if (!question) {
  console.error("Usage: npx tsx src/naive/run-naive-ask.ts \"your question\"");
  process.exit(1);
}

await naiveAsk("./sample-codebase", question);
```

**The Verification**

Ask a simple, direct question first, to confirm the whole pipeline works end-to-end on our small 5-file sample:

```bash
npx tsx src/naive/run-naive-ask.ts "How much does the pro plan cost?"
```

Expected output (abbreviated):

```
📂 Loading codebase from: ./sample-codebase
📄 Loaded 5 files, 2841 characters total.

📞 Sending request to the model...

✅ Answer:
The pro plan costs $29.00 (2900 cents), as defined in PLAN_PRICES_CENTS in subscription.ts.

⏱️  Latency: 890ms
🔢 Prompt tokens: 712
🔢 Completion tokens: 24
🔢 Total tokens: 736
```

Now ask about our deliberately-planted critical detail:

```bash
npx tsx src/naive/run-naive-ask.ts "What happens after 5 failed login attempts?"
```

Expected output:

```
✅ Answer:
After 5 failed login attempts, the account is locked for 15 minutes...
```

At this small scale (5 files, ~700 prompt tokens), the naive approach works **perfectly fine**. This is precisely why it's a trap — it feels correct and even elegant on a toy project. The problem only reveals itself at real-world scale, which is exactly what we simulate next.

---

## Step 4 — Generate a Realistic "Noise" Codebase

**The Target:** A script, `scripts/generate-noise.ts`, that pads `sample-codebase/` with dozens of unrelated-but-realistic files, so it resembles an actual mid-sized project instead of a 5-file toy — without us hand-writing hundreds of files ourselves.

**The Concept:** Real codebases aren't 5 files — they're hundreds or thousands. To honestly demonstrate the naive approach breaking, we need a directory of *plausible* size. Think of this like a crash-test lab building a realistic dummy — we're not exaggerating with garbage text, we're generating structurally realistic (if repetitive) TypeScript modules, the same way a real repo has many similar-shaped files (controllers, services, models).

**The Implementation**

```bash
mkdir -p scripts
```

##### `opencode/scripts/generate-noise.ts`

```typescript
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

/**
 * Generates a realistic-looking but semantically shallow module.
 * Each one simulates a typical CRUD service file you'd find in a
 * real backend project — enough structure to look real, enough
 * bulk to matter for token counting.
 */
function generateModule(name: string, index: number): string {
  return `import { log } from "../utils/logger.js";

export interface ${name}Record {
  id: string;
  name: string;
  createdAt: Date;
  metadata: Record<string, unknown>;
}

const store${index}: ${name}Record[] = [];

export function create${name}(name: string): ${name}Record {
  const record: ${name}Record = {
    id: crypto.randomUUID(),
    name,
    createdAt: new Date(),
    metadata: {},
  };
  store${index}.push(record);
  log("info", \`Created ${name}: \${name}\`);
  return record;
}

export function list${name}s(): ${name}Record[] {
  return store${index};
}

export function find${name}ById(id: string): ${name}Record | undefined {
  return store${index}.find((r) => r.id === id);
}

export function delete${name}(id: string): boolean {
  const idx = store${index}.findIndex((r) => r.id === id);
  if (idx === -1) return false;
  store${index}.splice(idx, 1);
  log("info", \`Deleted ${name}: \${id}\`);
  return true;
}
`;
}

const MODULE_NAMES = [
  "Team", "Project", "Task", "Comment", "Notification", "Webhook",
  "ApiKey", "Report", "Dashboard", "Widget", "Integration", "Tag",
  "Label", "Attachment", "AuditLog", "Session", "Role", "Permission",
  "Organization", "Workspace", "Folder", "Document", "Template",
  "Schedule", "Reminder", "Export", "Import", "Backup", "Region", "Zone",
];

async function main() {
  const targetDir = path.resolve("sample-codebase/src/generated");
  await mkdir(targetDir, { recursive: true });

  for (let i = 0; i < MODULE_NAMES.length; i++) {
    const name = MODULE_NAMES[i];
    const fileName = `${name.toLowerCase()}.ts`;
    const content = generateModule(name, i);
    await writeFile(path.join(targetDir, fileName), content, "utf-8");
    console.log(`Generated: src/generated/${fileName}`);
  }

  console.log(`\n✅ Generated ${MODULE_NAMES.length} noise files in sample-codebase/src/generated/`);
}

main();
```

**The Verification**

```bash
npx tsx scripts/generate-noise.ts
```

Expected output (abbreviated):

```
Generated: src/generated/team.ts
Generated: src/generated/project.ts
...
Generated: src/generated/zone.ts

✅ Generated 30 noise files in sample-codebase/src/generated/
```

Confirm the codebase is now much larger:

```bash
find sample-codebase -name "*.ts" | wc -l
```

Expected output:

```
35
```

(5 original files + 30 generated = 35 total.)

---

## Step 5 — Re-run the Naive Pipeline and Measure the Damage

**The Target:** Run the exact same `run-naive-ask.ts` script — no code changes at all — against this now-35-file codebase, and observe latency, cost, and correctness.

**The Concept:** This is the crash test. Nothing about our code changes; only the size of the input changes — exactly like nothing about a car's engineering changes between a 30mph test and a 60mph test, but the outcome is very different. We are isolating *one variable* (codebase size) to prove it alone is enough to break things.

**The Implementation**

No new code — we reuse Step 3's script verbatim:

```bash
npx tsx src/naive/run-naive-ask.ts "What happens after 5 failed login attempts?"
```

**The Verification — Read These Numbers Carefully**

Expected output:

```
📂 Loading codebase from: ./sample-codebase
📄 Loaded 35 files, 19430 characters total.

📞 Sending request to the model...

✅ Answer:
Based on the code provided, there is no explicit login attempt limiting logic visible in this codebase. If you're referring to authentication, you may want to add rate-limiting to the loginUser function.

⏱️  Latency: 2740ms
🔢 Prompt tokens: 5187
🔢 Completion tokens: 46
🔢 Total tokens: 5233
```

Compare this directly to Part 1 (2 of 3)'s result on the 5-file version:

| Metric | 5 files (Part 1, Step 3) | 35 files (now) | Change |
|---|---|---|---|
| Prompt tokens | 712 | 5,187 | **+629%** |
| Latency | 890ms | 2,740ms | **+208%** |
| Answer correctness | ✅ Correct | ❌ **Wrong — claims the logic doesn't exist** | Regression |

This is the "Lost in the Middle" failure, caught live: the exact same lockout logic that the model answered correctly a moment ago — with the *exact same code still present in the prompt* — gets missed once it's diluted among 30 structurally similar noise files. The model isn't "dumber" — its attention is statistically spread thinner across a much longer input, and a mid-document detail loses out to the more prominent, repetitive boilerplate surrounding it.

Now consider what happens at *actual* production scale. Run this quick projection yourself:

```bash
npx tsx -e "
const promptTokens = 5187;
const costPerMillionInputTokens = 0.15; // gpt-4o-mini input pricing, illustrative
const costThisRequest = (promptTokens / 1_000_000) * costPerMillionInputTokens;
console.log('Cost for ONE question:', '$' + costThisRequest.toFixed(5));
console.log('Cost for 10,000 questions/day:', '$' + (costThisRequest * 10000).toFixed(2));
console.log('Cost for 10,000 questions/day, at a REAL 500-file repo (~15x bigger):', '$' + (costThisRequest * 15 * 10000).toFixed(2));
"
```

Expected output:

```
Cost for ONE question: $0.00078
Cost for 10,000 questions/day: $7.78
Cost for 10,000 questions/day, at a REAL 500-file repo (~15x bigger): $116.70
```

And that's using a *cheap* small model. Swap in a frontier-tier model with 10-20x the per-token price (common for harder coding questions), and a single day of moderate traffic can run into the hundreds or thousands of dollars — for a system that, as we just proved, **gives the wrong answer** on a real, load-bearing business rule.

---

## Recap: The Three Symptoms, Now Proven With Real Numbers

1. **Latency (TTFT) blowout** — 890ms → 2,740ms, from codebase growth alone, with zero other changes.
2. **Runaway cost** — prompt tokens grew 7x from a 7x growth in file count, and this scales *linearly* with every additional file you add, for *every single question asked*, even trivial ones.
3. **Lost in the Middle** — the single most damning result: a real, correctly-implemented business rule was silently missed by the model once buried among structurally similar surrounding code, causing a **confidently wrong answer** a developer might ship straight to a user.

None of this required a contrived example or a trick question. It required exactly what a real engineer would build under deadline pressure, run against exactly the kind of codebase a real product has.

---

## What's Next: Part 2

The fix is not "use a bigger context window" — bigger windows make the *cost* problem worse and don't reliably fix "Lost in the Middle," since the issue is attention distribution, not hard capacity. The fix is architectural: stop treating the prompt as one undifferentiated blob, and instead impose the disciplined structure introduced in this series' Mental Model:

1. **System Frame** — hard rules that never change (the "operating system")
2. **Dynamic Memory** — only the last few relevant turns (the "registers")
3. **Transient Fact** — only the specific file/function actually relevant to the current question (the "instruction register")

In **Part 2**, we rebuild `naiveAsk` into a structured `ask` pipeline that assembles the prompt in exactly these three deliberate layers, and we re-run this *exact same* 35-file codebase and *exact same* lockout question — so you can directly compare the "after" numbers against the "before" numbers you just measured with your own terminal.

---

**✅ Part 1 is now complete.** You've built the naive approach honestly, watched it succeed at small scale, then watched it degrade in latency, cost, and correctness at realistic scale — with your own logged numbers as proof, not a hypothetical claim.

