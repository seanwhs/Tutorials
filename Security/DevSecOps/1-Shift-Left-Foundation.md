# Phase 1: The Shift Left Foundation

**Core Focus:** Culture, Threat Modeling, IDE Integration & Pre-Commit Defense.

In Phase 1 we lay the groundwork for everything that follows. We will (1) scaffold the `securenotes` application, (2) do lightweight **threat modeling** *before* writing features, (3) build a minimal but securely-configured API, and (4) turn your laptop into the **first automated security checkpoint** — IDE linting plus pre-commit hooks that *physically refuse* to let a hardcoded secret leave your machine.

By the end of this phase you'll have a running, hardened API and a Git repository that blocks secret leaks at the source. That is "shift left" made real.

---

## Step 1.1 — Initialize the Project & Git Repository

### 🎯 The Target
Create the project folder, initialize `git`, and create the Node.js project manifest (`package.json`).

### 🧠 The Concept
Think of `package.json` as the **recipe card** for your application: it lists the dish's name, its ingredients (dependencies), and cooking instructions (scripts). `git` is your **time machine + save history** — it records every change, and it's the thing our security hooks will plug into later.

### ⌨️ The Implementation

```bash
# Create and enter the project directory
mkdir securenotes
cd securenotes

# Initialize a git repository (creates a hidden .git folder to track history)
git init

# Initialize a Node.js project with defaults (-y accepts all prompts)
npm init -y
```

Replace the generated file with this cleaner manifest:

**`package.json`**
```json
{
  "name": "securenotes",
  "version": "0.1.0",
  "description": "A secure notes REST API — the demo app for the DevSecOps series",
  "main": "dist/server.js",
  "type": "module",
  "engines": {
    "node": ">=20.0.0"
  },
  "scripts": {
    "build": "tsc",
    "start": "node dist/server.js",
    "dev": "tsx watch src/server.ts",
    "lint": "eslint .",
    "test": "vitest run"
  },
  "keywords": ["devsecops", "security", "express", "typescript"],
  "author": "",
  "license": "MIT"
}
```

> **Why `"type": "module"`?** It tells Node to use modern `import`/`export` syntax (ES Modules) instead of the older `require()`. It's the current standard and keeps our code clean.

### ✅ The Verification
```bash
cat package.json      # confirm the manifest exists and is valid JSON
git status            # confirm git is tracking the folder ("On branch main")
```
You should see your manifest printed and git listing untracked files.

---

## Step 1.2 — Threat Modeling Before Code

### 🎯 The Target
Produce a lightweight **threat model** document. No code — this is a thinking exercise that shapes every later decision.

### 🧠 The Concept
Threat modeling is a **pre-flight checklist for a pilot.** Before taking off (writing code) you calmly ask: *What could go wrong? Who might attack? What are we protecting?* Minutes on paper now save millions in production later.

We use **STRIDE**, an industry framework where each letter is a threat category:

> **Definition — STRIDE:**
> - **S**poofing — pretending to be someone else (faking a login).
> - **T**ampering — modifying data you shouldn't (editing another user's note).
> - **R**epudiation — denying an action because there's no record of it.
> - **I**nformation disclosure — leaking data (dumping the database).
> - **D**enial of service — overwhelming the app so real users can't use it.
> - **E**levation of privilege — a normal user gaining admin powers.

### ⌨️ The Implementation

Storing this *in the repo* is itself a DevSecOps practice ("docs as code" — the plan lives beside the code it governs).

**`docs/threat-model.md`**
```markdown
# Threat Model: securenotes API

## 1. What are we building?
A REST API where authenticated users create, read, update, and delete their
own private notes. Data lives in PostgreSQL. Auth uses JSON Web Tokens (JWTs).

## 2. What are we protecting? (Assets)
| Asset                | Why it matters                                |
|----------------------|-----------------------------------------------|
| User note content    | Private, potentially sensitive personal data  |
| User credentials     | Password hashes — breach = account takeover   |
| JWT signing secret   | Leak = attacker can forge ANY user's identity |
| Database credentials | Leak = full data breach                       |

## 3. Trust boundaries (where untrusted data enters trusted zones)
- Internet     -> API server          (ALL client input is UNTRUSTED)
- API server   -> Database            (must use parameterized queries)
- CI pipeline  -> Container registry  (artifacts must be signed)

## 4. STRIDE analysis
| Threat                 | Example scenario                     | Mitigation (phase)                     |
|------------------------|--------------------------------------|----------------------------------------|
| Spoofing               | Attacker forges a login              | JWT auth + bcrypt hashing (P1)         |
| Tampering              | User A edits User B's note           | Ownership checks on every query (P1)   |
| Repudiation            | "I never deleted that note"          | Structured audit logging (P5)          |
| Information disclosure | SQL injection dumps all notes        | Parameterized queries + validation (P1)|
| Denial of service      | Flood of requests                    | Rate limiting + helmet (P1)            |
| Elevation of privilege | Normal user hits admin route         | Role checks + least privilege (P1)     |
| Supply chain           | Malicious npm dependency             | SCA scanning (P2), signed images (P4)  |
| Secrets leak           | DB password hardcoded & pushed       | Secret scan + pre-commit hooks (P1/P3) |

## 5. Security decisions locked in NOW
1. All secrets come from environment variables — NEVER hardcoded.
2. All DB access uses parameterized queries — NEVER string concatenation.
3. All input is validated at the edge before use.
4. Every note query is scoped to the authenticated user's ID.
```

### ✅ The Verification
```bash
head -n 5 docs/threat-model.md
```
You now have a written contract guiding every code choice — the "culture" of DevSecOps made concrete.

---

## Step 1.3 — TypeScript & the `.gitignore` Safety Net

### 🎯 The Target
Add TypeScript (type safety) and — critically — a `.gitignore` so we *never accidentally commit secrets or junk*.

### 🧠 The Concept
`.gitignore` is a **bouncer at the club door** holding a list of who's *not* allowed in. Files matching its patterns (like `.env` secret files or the huge `node_modules` folder) become invisible to git and can never be committed. This is our simplest security control: the best way to never leak a secret file is to make git blind to it.

> **Definition — TypeScript:** JavaScript with *types* — labels on your data (`string`, `number`, `User`) that catch mistakes *before* the program runs, like a spell-checker for code.

### ⌨️ The Implementation

```bash
# --save-dev = build-time tools, not shipped to production
npm install --save-dev typescript tsx vitest @types/node
```

**`tsconfig.json`**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "node",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
```

> **Why `"strict": true`?** It enables all of TypeScript's safety checks. `noUncheckedIndexedAccess` is security-relevant: it forces you to handle the case where a lookup could be `undefined`, closing logic holes attackers exploit.

**`.gitignore`**
```gitignore
# Dependencies (huge, regenerated by `npm install`)
node_modules/

# Build output
dist/

# Secrets and environment files — NEVER commit these
.env
.env.*
!.env.example
*.pem
*.key

# Logs
*.log
npm-debug.log*

# OS / editor cruft
.DS_Store
.vscode/*
!.vscode/settings.json
!.vscode/extensions.json

# Test / coverage output
coverage/
```

> **The `!.env.example` line is intentional.** `!` means "un-ignore this one." We *do* commit `.env.example` (a template with fake values) but *never* the real `.env`.

### ✅ The Verification
```bash
# Create a fake secret file and prove git ignores it
echo "SECRET=super-secret-value" > .env
git status
```
The `.env` file should **NOT** appear in git's file list. If it's absent, your bouncer works. (Leave the `.env` — we replace it next.)

---

## Step 1.4 — Build the Minimal Secure App

### 🎯 The Target
Write a minimal but *securely-configured* Express server that loads secrets from environment variables — never hardcoded.

### 🧠 The Concept
Express is a **waiter framework**: it takes incoming HTTP requests (orders) and routes them to the right handler (kitchen station). We immediately add **middleware** — functions that inspect every request as it passes through, like guards in a hallway everyone must walk down.

> **Definition — Middleware:** A function sitting *between* the incoming request and the final handler. It can inspect, modify, block, or log the request. Middleware runs top-to-bottom, in order.

- **Helmet** sets protective HTTP headers (tells browsers to behave defensively).
- **express-rate-limit** caps requests per client — our **Denial of Service** mitigation.
- **dotenv** loads `.env` into the environment; **Zod** validates that required variables exist, so the app *refuses to start* if misconfigured.

### ⌨️ The Implementation

```bash
# Runtime dependencies (shipped to production)
npm install express helmet express-rate-limit dotenv zod

# Type definitions for Express (dev-only)
npm install --save-dev @types/express
```

Centralized, validated configuration — parse and check *all* env vars in one place at startup:

**`src/config.ts`**
```typescript
import { z } from "zod";
import dotenv from "dotenv";

// Load variables from .env into process.env.
// In production these come from the real environment, never a file.
dotenv.config();

// The schema defines EXACTLY which env vars are needed and their types.
// If anything is missing/malformed, the app fails fast with a clear error.
const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),

  // coerce turns the env string "3000" into a real number.
  PORT: z.coerce.number().int().positive().default(3000),

  // Enforce a minimum length so a weak signing secret can't sneak in.
  JWT_SECRET: z
    .string()
    .min(32, "JWT_SECRET must be at least 32 characters for safety"),

  DATABASE_URL: z.string().url().optional(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  // Print what's wrong and exit non-zero. Non-zero exit = "I failed",
  // which stops broken deploys from proceeding.
  console.error("❌ Invalid environment configuration:");
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

// Export the validated, fully-typed config for the whole app.
export const config = parsed.data;
```

> **Why this matters:** validating `JWT_SECRET` length here enforces golden rule #1 *and* prevents a classic weakness (a short, guessable secret) before we write any feature.

**`src/server.ts`**
```typescript
import express, { type Request, type Response, type NextFunction } from "express";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import { config } from "./config.js"; // .js extension required for compiled ESM

// Create the Express application instance — our "restaurant".
const app = express();

// ── SECURITY MIDDLEWARE (runs on EVERY request, in this order) ──────────────

// 1) Helmet sets ~15 protective headers and hides "X-Powered-By".
app.use(helmet());

// 2) Parse JSON bodies but cap the size — prevents huge-payload DoS.
app.use(express.json({ limit: "10kb" }));

// 3) Rate limit: 100 requests per IP per 15 minutes (DoS mitigation).
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests, please try again later." },
});
app.use(limiter);

// ── ROUTES ──────────────────────────────────────────────────────────────────

// Health check for load balancers/ops. Leaks NO sensitive info.
app.get("/health", (_req: Request, res: Response) => {
  res.status(200).json({ status: "ok", uptime: process.uptime() });
});

// ── ERROR HANDLING (must be LAST, and have exactly 4 arguments) ─────────────

// Express identifies error handlers by their 4 params. This NEVER sends the
// raw stack trace to the client (that would be Information Disclosure).
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error("Unhandled error:", err.message); // full detail server-side
  res.status(500).json({ error: "Internal server error" }); // generic to client
});

// ── STARTUP ───────────────────────────────────────────────────────────────

app.listen(config.PORT, () => {
  console.log(`🚀 securenotes running on port ${config.PORT} [${config.NODE_ENV}]`);
});

export default app; // exported so tests can import it later
```

Replace the fake `.env`, and create the safe-to-commit template:

**`.env`** (real values — git-ignored, stays local)
```dotenv
NODE_ENV=development
PORT=3000
JWT_SECRET=dev-only-super-long-secret-change-me-in-production-1234
```

**`.env.example`** (committed template — fake values, documents required vars)
```dotenv
# Copy to `.env` and fill in real values. NEVER put real secrets here.
NODE_ENV=development
PORT=3000
# Min 32 chars. Generate with: openssl rand -hex 32
JWT_SECRET=replace-with-a-long-random-secret-min-32-chars
DATABASE_URL=postgres://user:password@localhost:5432/securenotes
```

### ✅ The Verification

```bash
npm run dev
```
Expect: `🚀 securenotes running on port 3000 [development]`

In a second terminal:
```bash
curl -s http://localhost:3000/health
# → {"status":"ok","uptime":<number>}

curl -sI http://localhost:3000/health   # -I = headers only
```
Look for Helmet's headers and the *absence* of `X-Powered-By`:
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
RateLimit-Limit: 100
```

Prove fail-fast config works:
```bash
JWT_SECRET=short npm run dev
```
The app should **refuse to start** with a clear `JWT_SECRET` error. Restore `.env`, stop with `Ctrl+C`.

---

## Step 1.5 — IDE Security Linting (ESLint)

### 🎯 The Target
Configure **ESLint** with a security plugin so your editor flags dangerous patterns *as you type* — the leftmost possible check.

### 🧠 The Concept
A **linter** is a **grammar-and-spell-checker for code.** Just as a word processor underlines misspellings, a security linter underlines risky code — like `eval()` (executes attacker-supplied strings) or building shell commands from user input.

> **Definition — SAST (previewed):** IDE linting is a lightweight, real-time flavor of **Static Application Security Testing** — analyzing code *without running it*. Phase 2 scales this same idea into CI.

### ⌨️ The Implementation

```bash
npm install --save-dev eslint @eslint/js typescript-eslint eslint-plugin-security globals
```

**`eslint.config.js`**
```javascript
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import security from "eslint-plugin-security";
import globals from "globals";

export default tseslint.config(
  // Base recommended JavaScript rules
  js.configs.recommended,

  // Recommended TypeScript rules
  ...tseslint.configs.recommended,

  // The security plugin's recommended rules — the key part for us
  security.configs.recommended,

  {
    files: ["src/**/*.ts"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: { ...globals.node }, // teaches ESLint about `process`, etc.
    },
    rules: {
      // Elevate security rules to "error" so they can BLOCK later, not just nag.
      "security/detect-eval-with-expression": "error",
      "security/detect-child-process": "error",
      "no-eval": "error",
      // Disallow stray debug logs (often leak info). Allow warn/error.
      "no-console": ["warn", { allow: ["warn", "error"] }],
    },
  },

  // Never lint build output or dependencies
  { ignores: ["dist/**", "node_modules/**", "coverage/**"] }
);
```

Make VS Code surface these inline (recall `.gitignore` un-ignored these two files):

**`.vscode/settings.json`**
```json
{
  "editor.codeActionsOnSave": { "source.fixAll.eslint": "explicit" },
  "eslint.validate": ["typescript"],
  "editor.formatOnSave": true
}
```

**`.vscode/extensions.json`**
```json
{
  "recommendations": ["dbaeumer.vscode-eslint"]
}
```

### ✅ The Verification

Run the linter on the clean codebase — it should pass:
```bash
npm run lint
```

Now **plant a vulnerability** to prove the scanner works. Create:

**`src/danger.ts`** (temporary)
```typescript
export function run(userInput: string) {
  // eval() executes arbitrary strings — a classic RCE vulnerability.
  return eval(userInput);
}
```

Lint again:
```bash
npm run lint
```
ESLint should now **fail** with an error like `no-eval` / `security/detect-eval-with-expression`. That's your IDE-level SAST catching a real flaw. Delete the file before continuing:
```bash
rm src/danger.ts
npm run lint   # back to passing
```

---

## Step 1.6 — Pre-Commit Hooks: Block Secrets at the Door

### 🎯 The Target
Install **Husky** (git hook manager) + **lint-staged** and a **secret detector** so committing is *blocked* if code has lint errors or contains a hardcoded secret.

### 🧠 The Concept
A **git hook** is an **automatic tripwire** that fires at a moment in the git workflow. A *pre-commit* hook runs the instant you type `git commit` — *before* the snapshot is saved. If our tripwire finds a problem, it aborts the commit. This is the single most effective "shift left" control: a leaked secret that never gets committed can never be pushed, and a secret never pushed can never be breached.

> **Definition — Husky:** A tool that makes git hooks easy to install and share across a team via the repo itself.
> **Definition — lint-staged:** Runs checks only on the files you're *actually committing* (the "staged" files) — fast, because it skips untouched files.

We'll pair this with **detect-secrets** style scanning using the popular open-source **gitleaks**.

### ⌨️ The Implementation

```bash
npm install --save-dev husky lint-staged
npx husky init      # creates the .husky/ folder and wires up git
```

Configure which checks run on staged files. Add this block to **`package.json`**:

```json
{
  "lint-staged": {
    "*.ts": ["eslint --fix"],
    "*": ["gitleaks protect --staged --no-banner"]
  }
}
```

> `eslint --fix` auto-repairs staged TypeScript; `gitleaks protect --staged` scans staged content for secrets before the commit is written.

Now replace the generated hook so it runs lint-staged:

**`.husky/pre-commit`**
```sh
# Run lint-staged: lint TS + scan staged files for secrets.
# If any check exits non-zero, the commit is aborted.
npx lint-staged
```

Install **gitleaks** (the secret scanner):
```bash
# macOS
brew install gitleaks
# Linux (or if no brew): download from https://github.com/gitleaks/gitleaks/releases
# Verify install:
gitleaks version
```

Add a config so scans are consistent and tunable:

**`.gitleaks.toml`**
```toml
# Extend gitleaks' built-in rule set (detects AWS keys, tokens, etc.)
[extend]
useDefault = true

# Allowlist: things that LOOK like secrets but are safe (avoids false positives).
[allowlist]
description = "Global allowlist"
paths = [
  '''\.env\.example$''',   # our template file uses fake placeholder values
  '''docs/threat-model\.md$'''
]
```

### ✅ The Verification

First, a clean commit should succeed:
```bash
git add .
git commit -m "chore: bootstrap secure securenotes app with tooling"
```
lint-staged runs, gitleaks finds nothing, commit succeeds. ✅

Now **prove the tripwire fires.** Plant a fake AWS key in a real source file:

**`src/leak.ts`** (temporary)
```typescript
// A realistic-looking hardcoded credential — exactly what must NEVER be committed.
const awsKey = "AKIAIOSFODNN7EXAMPLE";
const awsSecret = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";
export { awsKey, awsSecret };
```

Try to commit it:
```bash
git add src/leak.ts
git commit -m "test: this should be BLOCKED"
```
The commit is **ABORTED** — gitleaks reports a detected secret and exits non-zero. Your laptop just refused to leak a credential. 🎉

Clean up:
```bash
git reset src/leak.ts
rm src/leak.ts
```

---

## Step 1.7 — Lock In the Baseline

### 🎯 The Target
Commit the clean, working, secured baseline so every later phase builds on solid ground.

### 🧠 The Concept
A **baseline** is **base camp on the mountain.** It's a known-good state you can always return to. Committing here means our entire Phase 1 security posture — validated config, security headers, rate limiting, IDE linting, and secret-blocking hooks — is captured in history.

### ⌨️ The Implementation
```bash
git add .
git commit -m "feat(security): Phase 1 shift-left foundation complete"
```

### ✅ The Verification
```bash
git log --oneline
```
You should see your Phase 1 commits. Run the full local check suite one final time:
```bash
npm run lint && npm run build
```
Both should succeed with no errors. Base camp established. 🏕️

---

## 📚 Phase 1 Reference Section

*Deep dives — skip on first pass, return for mastery.*

### R1.1 — Why "10x cheaper to fix left" is real
A bug caught in the IDE costs one developer a few seconds. The same bug caught in code review costs two people ~15 minutes. In QA it costs a ticket, a re-test cycle, and a redeploy. In production it can cost an incident bridge, customer notifications, and regulatory fines. Each rightward step multiplies the number of people and processes involved — hence the ~10x figure per stage.

### R1.2 — Helmet header cheat-sheet
| Header | Protects against |
|---|---|
| `X-Content-Type-Options: nosniff` | MIME-sniffing attacks |
| `X-Frame-Options` | Clickjacking (embedding your page in a hostile iframe) |
| `Strict-Transport-Security` | Downgrade to insecure HTTP |
| `Content-Security-Policy` | XSS / injected scripts (configure per-app) |
| (removed) `X-Powered-By` | Tech-stack fingerprinting |

### R1.3 — The pre-commit hook lifecycle
1. `git commit` invoked → 2. `.husky/pre-commit` runs → 3. `npx lint-staged` picks staged files → 4. ESLint `--fix` + gitleaks run → 5. any non-zero exit **aborts** the commit → 6. on success, the snapshot is written. Because the hook lives in the repo, every teammate who runs `npm install` inherits the same protection (defense in depth: local + CI).

### R1.4 — Zod config schema notes
`safeParse` returns `{ success, data | error }` instead of throwing — letting us print a friendly message and `process.exit(1)`. `z.coerce.number()` handles env vars always being strings. `.optional()` marks vars not yet needed (like `DATABASE_URL`) so the app runs before the DB exists.
