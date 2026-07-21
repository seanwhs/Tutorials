# Phase 2: Code & Dependency Security (SAST & SCA)

**Core Focus:** Automated Code Analysis & Supply Chain Defense.

In Phase 1 we secured the *developer's laptop*. But laptops can be misconfigured, hooks can be bypassed (`git commit --no-verify`), and teammates make mistakes. So in Phase 2 we build a **second, un-skippable wall**: the CI pipeline. Every push and pull request will automatically run:

- **SAST** — a deep scanner that reads *your* source code for vulnerable patterns.
- **SCA** — a scanner for vulnerable *third-party dependencies* (the 80–90% of modern apps that is open-source).

Crucially, these checks will **gate** the pipeline: a real finding *blocks the merge*.

> **The key insight:** Phase 1 controls are *advisory and local* (a developer could bypass them). CI controls are *mandatory and central* (nobody can bypass them). This is **defense in depth** — the same threat guarded at multiple layers.

Before we add scanning, we need real, scannable features. So we'll first build the actual notes API (with deliberate security controls), then point the scanners at it.

---

## Step 2.1 — Add a Real Feature: The Notes API with Safe Data Access

### 🎯 The Target
Build the notes data layer and routes using **parameterized queries** — giving the SAST scanner real code to analyze and proving golden rule #2.

### 🧠 The Concept
A **parameterized query** is like a **fill-in-the-blank form** instead of a hand-written letter. With a form, the database treats your input strictly as *data* to slot into a blank — it can never be mistaken for *commands*. The dangerous alternative, string concatenation, is like letting a stranger write directly onto your letter; they could add "...and also delete everything."

> **Definition — SQL Injection:** An attack where malicious input (e.g., `'; DROP TABLE users; --`) is interpreted as database *commands* instead of *data*. Parameterized queries make this structurally impossible.

We'll use an **in-memory store** for now (a simple `Map`) so the app runs without a database, but we write it in the *shape* of parameterized access so the security patterns are real. (Phase 3 swaps in PostgreSQL.)

### ⌨️ The Implementation

Install validation and ID tooling (Zod is already installed):

```bash
npm install uuid
npm install --save-dev @types/uuid
```

First, the data model and store:

**`src/notes/store.ts`**
```typescript
import { randomUUID } from "node:crypto";

// The shape of a Note. Types are our first line of defense against bad data.
export interface Note {
  id: string;
  userId: string; // CRITICAL: every note is owned by a user (golden rule #4)
  title: string;
  body: string;
  createdAt: string;
}

// In-memory store. Phase 3 replaces this with a real PostgreSQL-backed repo,
// but the METHOD SIGNATURES stay identical so callers never change.
class NoteStore {
  private notes = new Map<string, Note>();

  // Create a note owned by a specific user.
  create(userId: string, title: string, body: string): Note {
    const note: Note = {
      id: randomUUID(),
      userId,
      title,
      body,
      createdAt: new Date().toISOString(),
    };
    this.notes.set(note.id, note);
    return note;
  }

  // List ONLY the notes owned by this user — never anyone else's.
  listByUser(userId: string): Note[] {
    return [...this.notes.values()].filter((n) => n.userId === userId);
  }

  // Fetch a single note, but ONLY if the requesting user owns it.
  // Returning null (not the note) prevents "Information Disclosure" of
  // whether a note even exists — a subtle but important detail.
  findOwned(userId: string, noteId: string): Note | null {
    const note = this.notes.get(noteId);
    if (!note || note.userId !== userId) return null;
    return note;
  }

  // Delete a note ONLY if the requesting user owns it.
  deleteOwned(userId: string, noteId: string): boolean {
    const note = this.findOwned(userId, noteId);
    if (!note) return false;
    return this.notes.delete(noteId);
  }
}

// Single shared instance for the app.
export const noteStore = new NoteStore();
```

> **Why ownership checks live in the store:** by making it *impossible* to fetch a note without passing a `userId`, we structurally prevent the "Tampering" and "Elevation of privilege" threats. A developer literally cannot write code that reads another user's note by accident.

Now the input validation schemas (the "edge validation" of golden rule #3):

**`src/notes/schemas.ts`**
```typescript
import { z } from "zod";

// Validate the body of a "create note" request. Untrusted input becomes
// trusted, typed data ONLY after passing this gate.
export const createNoteSchema = z.object({
  // Trim whitespace, require 1–200 chars — prevents empty or giant titles.
  title: z.string().trim().min(1).max(200),
  // Body capped to prevent memory-exhaustion DoS.
  body: z.string().trim().min(1).max(10_000),
});

// Validate a note ID in the URL is a proper UUID (not arbitrary input).
export const noteIdSchema = z.string().uuid();

// TypeScript type inferred directly from the schema — one source of truth.
export type CreateNoteInput = z.infer<typeof createNoteSchema>;
```

The router that ties it together:

**`src/notes/routes.ts`**
```typescript
import { Router, type Request, type Response } from "express";
import { noteStore } from "./store.js";
import { createNoteSchema, noteIdSchema } from "./schemas.js";

export const notesRouter = Router();

// NOTE: authentication is added in Step 2.2. For now we read a userId from a
// header so we can exercise the ownership logic. This is a TEMPORARY stand-in.
function getUserId(req: Request): string {
  const userId = req.header("x-user-id");
  return userId ?? "anonymous";
}

// POST /notes — create a note
notesRouter.post("/", (req: Request, res: Response) => {
  // Validate input at the edge. safeParse never throws.
  const result = createNoteSchema.safeParse(req.body);
  if (!result.success) {
    // Return the validation issues (safe: they describe the client's own input).
    return res.status(400).json({ error: result.error.flatten().fieldErrors });
  }
  const userId = getUserId(req);
  const note = noteStore.create(userId, result.data.title, result.data.body);
  return res.status(201).json(note);
});

// GET /notes — list the caller's notes
notesRouter.get("/", (req: Request, res: Response) => {
  const userId = getUserId(req);
  return res.status(200).json(noteStore.listByUser(userId));
});

// GET /notes/:id — fetch one owned note
notesRouter.get("/:id", (req: Request, res: Response) => {
  const idResult = noteIdSchema.safeParse(req.params.id);
  if (!idResult.success) {
    return res.status(400).json({ error: "Invalid note id" });
  }
  const note = noteStore.findOwned(getUserId(req), idResult.data);
  if (!note) return res.status(404).json({ error: "Not found" });
  return res.status(200).json(note);
});

// DELETE /notes/:id — delete one owned note
notesRouter.delete("/:id", (req: Request, res: Response) => {
  const idResult = noteIdSchema.safeParse(req.params.id);
  if (!idResult.success) {
    return res.status(400).json({ error: "Invalid note id" });
  }
  const deleted = noteStore.deleteOwned(getUserId(req), idResult.data);
  if (!deleted) return res.status(404).json({ error: "Not found" });
  return res.status(204).send();
});
```

Wire the router into the server. Update **`src/server.ts`** — add the import near the top and mount the router *after* the middleware, *before* the error handler:

```typescript
// ... existing imports ...
import { notesRouter } from "./notes/routes.js"; // ADD THIS

// ... after app.use(limiter); and the /health route, ADD: ...
app.use("/notes", notesRouter);

// (the error-handling middleware stays LAST, unchanged)
```

### ✅ The Verification

```bash
npm run dev
```

In a second terminal, exercise the API and prove ownership isolation:

```bash
# Create a note as user "alice"
curl -s -X POST http://localhost:3000/notes \
  -H "Content-Type: application/json" \
  -H "x-user-id: alice" \
  -d '{"title":"Alice note","body":"secret stuff"}'
# → returns the created note with an id; COPY that id.

# Alice lists her notes — sees it
curl -s http://localhost:3000/notes -H "x-user-id: alice"

# Bob lists HIS notes — sees NOTHING (ownership isolation works)
curl -s http://localhost:3000/notes -H "x-user-id: bob"

# Bob tries to fetch Alice's note by id — gets 404, NOT the note
curl -s http://localhost:3000/notes/<PASTE-ALICE-NOTE-ID> -H "x-user-id: bob"
# → {"error":"Not found"}

# Validation works: empty title is rejected with 400
curl -s -X POST http://localhost:3000/notes \
  -H "Content-Type: application/json" -H "x-user-id: alice" \
  -d '{"title":"","body":""}'
# → 400 with fieldErrors
```

Ownership isolation and edge validation both work. Stop the server.

---

## Step 2.2 — Add Authentication (JWT + bcrypt)

### 🎯 The Target
Replace the temporary `x-user-id` header with real **JWT authentication** and **bcrypt** password hashing — closing the "Spoofing" threat.

### 🧠 The Concept
- **bcrypt** is a **one-way paper shredder for passwords.** You can shred a password into a hash, but you can never un-shred the hash back into the password. To check a login, you shred the attempt and compare shreds. This means even if the database leaks, raw passwords don't.
- **JWT (JSON Web Token)** is a **tamper-proof wristband** at a festival. When you log in, we give you a signed wristband encoding *who you are*. On each request you show the wristband; because it's signed with our secret `JWT_SECRET`, nobody can forge or alter it.

> **Definition — JWT:** A signed, base64-encoded token containing claims (like `userId`). The signature (created with `JWT_SECRET`) proves it was issued by us and hasn't been tampered with.

### ⌨️ The Implementation

```bash
npm install bcryptjs jsonwebtoken
npm install --save-dev @types/bcryptjs @types/jsonwebtoken
```

A tiny user store (in-memory for now; Phase 3 moves it to PostgreSQL):

**`src/auth/userStore.ts`**
```typescript
import { randomUUID } from "node:crypto";
import bcrypt from "bcryptjs";

export interface User {
  id: string;
  email: string;
  passwordHash: string; // we store the HASH, never the raw password
}

class UserStore {
  private byEmail = new Map<string, User>();

  async register(email: string, password: string): Promise<User> {
    if (this.byEmail.has(email)) {
      throw new Error("Email already registered");
    }
    // Hash with a work factor of 12 — deliberately slow to resist brute force.
    const passwordHash = await bcrypt.hash(password, 12);
    const user: User = { id: randomUUID(), email, passwordHash };
    this.byEmail.set(email, user);
    return user;
  }

  // Verify a login attempt. Returns the user only if the password matches.
  async verify(email: string, password: string): Promise<User | null> {
    const user = this.byEmail.get(email);
    // Note: we run compare even when user is missing? bcrypt needs a hash.
    if (!user) return null;
    const ok = await bcrypt.compare(password, user.passwordHash);
    return ok ? user : null;
  }
}

export const userStore = new UserStore();
```

The JWT helpers and auth middleware:

**`src/auth/jwt.ts`**
```typescript
import jwt from "jsonwebtoken";
import { config } from "../config.js";

export interface TokenPayload {
  userId: string;
  email: string;
}

// Issue a signed token that expires in 1 hour (short-lived = safer).
export function signToken(payload: TokenPayload): string {
  return jwt.sign(payload, config.JWT_SECRET, { expiresIn: "1h" });
}

// Verify + decode a token. Throws if the signature or expiry is invalid.
export function verifyToken(token: string): TokenPayload {
  // jwt.verify checks the signature against JWT_SECRET AND the expiry.
  const decoded = jwt.verify(token, config.JWT_SECRET) as TokenPayload;
  return decoded;
}
```

**`src/auth/middleware.ts`**
```typescript
import type { Request, Response, NextFunction } from "express";
import { verifyToken, type TokenPayload } from "./jwt.js";

// Augment Express's Request type to carry the authenticated user.
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}

// Middleware that requires a valid "Authorization: Bearer <token>" header.
export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.header("authorization");
  if (!header?.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing or malformed token" });
  }
  const token = header.slice("Bearer ".length);
  try {
    // If verification fails (bad signature / expired), it throws → 401.
    req.user = verifyToken(token);
    return next();
  } catch {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}
```

The auth routes (register + login):

**`src/auth/routes.ts`**
```typescript
import { Router, type Request, type Response } from "express";
import { z } from "zod";
import { userStore } from "./userStore.js";
import { signToken } from "./jwt.js";

export const authRouter = Router();

// Strong credential validation at the edge (golden rule #3).
const credsSchema = z.object({
  email: z.string().email(),
  password: z.string().min(12).max(128), // enforce a strong minimum length
});

authRouter.post("/register", async (req: Request, res: Response) => {
  const result = credsSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ error: result.error.flatten().fieldErrors });
  }
  try {
    const user = await userStore.register(result.data.email, result.data.password);
    const token = signToken({ userId: user.id, email: user.email });
    return res.status(201).json({ token });
  } catch {
    // Generic message — don't reveal whether the email already exists
    // (prevents user-enumeration, an Information Disclosure threat).
    return res.status(409).json({ error: "Could not register" });
  }
});

authRouter.post("/login", async (req: Request, res: Response) => {
  const result = credsSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ error: "Invalid credentials" });
  }
  const user = await userStore.verify(result.data.email, result.data.password);
  if (!user) {
    // Same generic message for "no such user" and "wrong password".
    return res.status(401).json({ error: "Invalid credentials" });
  }
  const token = signToken({ userId: user.id, email: user.email });
  return res.status(200).json({ token });
});
```

Now replace the temporary `getUserId` in **`src/notes/routes.ts`**. Update the top of the file and the mount. First, remove the `getUserId` function and change each usage to read `req.user!.userId`:

**`src/notes/routes.ts`** (updated — full file)
```typescript
import { Router, type Request, type Response } from "express";
import { noteStore } from "./store.js";
import { createNoteSchema, noteIdSchema } from "./schemas.js";

export const notesRouter = Router();

// POST /notes — create a note (req.user is guaranteed by requireAuth)
notesRouter.post("/", (req: Request, res: Response) => {
  const result = createNoteSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ error: result.error.flatten().fieldErrors });
  }
  const note = noteStore.create(req.user!.userId, result.data.title, result.data.body);
  return res.status(201).json(note);
});

// GET /notes — list the caller's notes
notesRouter.get("/", (req: Request, res: Response) => {
  return res.status(200).json(noteStore.listByUser(req.user!.userId));
});

// GET /notes/:id — fetch one owned note
notesRouter.get("/:id", (req: Request, res: Response) => {
  const idResult = noteIdSchema.safeParse(req.params.id);
  if (!idResult.success) {
    return res.status(400).json({ error: "Invalid note id" });
  }
  const note = noteStore.findOwned(req.user!.userId, idResult.data);
  if (!note) return res.status(404).json({ error: "Not found" });
  return res.status(200).json(note);
});

// DELETE /notes/:id — delete one owned note
notesRouter.delete("/:id", (req: Request, res: Response) => {
  const idResult = noteIdSchema.safeParse(req.params.id);
  if (!idResult.success) {
    return res.status(400).json({ error: "Invalid note id" });
  }
  const deleted = noteStore.deleteOwned(req.user!.userId, idResult.data);
  if (!deleted) return res.status(404).json({ error: "Not found" });
  return res.status(204).send();
});
```

Finally, wire auth into **`src/server.ts`** — mount the auth router openly, and protect `/notes` with `requireAuth`:

```typescript
// ADD these imports near the top:
import { authRouter } from "./auth/routes.js";
import { requireAuth } from "./auth/middleware.js";
import { notesRouter } from "./notes/routes.js";

// REPLACE the previous `app.use("/notes", notesRouter);` with:
app.use("/auth", authRouter);                 // register/login are public
app.use("/notes", requireAuth, notesRouter);  // notes require a valid token
```

### ✅ The Verification

```bash
npm run dev
```

```bash
# Register a user → returns a token
TOKEN=$(curl -s -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","password":"supersecret123"}' \
  | node -pe 'JSON.parse(require("fs").readFileSync(0)).token')
echo "Token: $TOKEN"

# Accessing /notes WITHOUT a token → 401
curl -s http://localhost:3000/notes
# → {"error":"Missing or malformed token"}

# WITH the token → 200 and an (empty) list
curl -s http://localhost:3000/notes -H "Authorization: Bearer $TOKEN"
# → []

# Create a note WITH the token
curl -s -X POST http://localhost:3000/notes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"My first secure note","body":"hello"}'
# → 201 with the created note

# A garbage token → 401
curl -s http://localhost:3000/notes -H "Authorization: Bearer not.a.real.token"
# → {"error":"Invalid or expired token"}
```

Spoofing mitigated: no valid signed wristband, no entry. Stop the server and commit:
```bash
git add . && git commit -m "feat(auth): JWT auth + bcrypt, owned notes API"
```

---

## Step 2.3 — SAST in CI with Semgrep

### 🎯 The Target
Add a **GitHub Actions** workflow that runs **Semgrep** (an open-source SAST scanner) on every push and pull request, failing the build on real findings.

### 🧠 The Concept
> **Definition — CI (Continuous Integration):** An automated server that runs your checks (tests, scans, builds) every time code is pushed. **GitHub Actions** is GitHub's built-in CI, configured with YAML files in `.github/workflows/`.

> **Definition — SAST:** Static Application Security Testing — scanning source code *without running it* to find vulnerable patterns. Where our IDE linter was a quick spell-check, **Semgrep** is a **thorough copy-editor** with thousands of security rules (SQL injection, hardcoded secrets, unsafe deserialization, etc.).

Think of CI as a **security guard who never sleeps and can't be talked into looking the other way** — unlike a local hook, nobody can `--no-verify` their way past it.

### ⌨️ The Implementation

**`.github/workflows/security.yml`**
```yaml
name: Security CI

# Run on every push to main and on every pull request.
on:
  push:
    branches: [main]
  pull_request:

# Least privilege: this workflow only needs to READ the code.
permissions:
  contents: read

jobs:
  # ── Job 1: Static Application Security Testing ──────────────────────────
  sast:
    name: SAST (Semgrep)
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Semgrep
        uses: semgrep/semgrep-action@v1
        with:
          # Curated rule packs: security audit + common JS/TS mistakes +
          # secret detection. Semgrep fails the job (non-zero exit) on findings.
          config: >-
            p/security-audit
            p/javascript
            p/typescript
            p/secrets

  # ── Job 2: lint + build + test (fast feedback, runs in parallel) ────────
  build:
    name: Lint, Build & Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies (clean, reproducible install)
        run: npm ci

      - name: Lint (IDE-level SAST, now enforced in CI)
        run: npm run lint

      - name: Type-check & build
        run: npm run build

      - name: Run tests
        run: npm test --if-present
```

> **`npm ci` vs `npm install`:** `ci` installs *exactly* the versions in `package-lock.json` and fails if the lockfile is out of sync — reproducible and tamper-evident, which matters for supply-chain integrity.

Let's also make it easy to run Semgrep locally before pushing (optional but developer-friendly):

**`docs/running-scans-locally.md`**
```markdown
# Running the security scans locally

## Semgrep (SAST)
    pip install semgrep      # or: brew install semgrep
    semgrep --config p/security-audit --config p/typescript src/

## gitleaks (secrets)
    gitleaks detect --source . --no-banner

## npm audit (SCA)
    npm audit --audit-level=high
```

### ✅ The Verification

Push to a branch and open a pull request:
```bash
git add .
git commit -m "ci: add Semgrep SAST + build workflow"
git push origin HEAD
```
On GitHub, open the **Actions** tab — you should see the **Security CI** workflow running two jobs (`SAST (Semgrep)` and `Lint, Build & Test`), both passing green on the clean codebase.

**Prove the gate blocks real vulnerabilities.** On a scratch branch, add:

**`src/vuln.ts`** (temporary — will be caught)
```typescript
import { exec } from "node:child_process";

// UNSAFE: builds a shell command from user input → command injection.
export function ping(host: string) {
  exec("ping -c 1 " + host); // Semgrep + ESLint both flag this
}
```
Commit and push it. The **SAST job fails red**, Semgrep annotates the exact line as a command-injection finding, and (if branch protection is on) the PR *cannot be merged*. Delete the file, push again, watch it go green:
```bash
rm src/vuln.ts
git add . && git commit -m "revert: remove intentional vuln" && git push
```

---

## Step 2.4 — SCA: Scanning Your Dependencies

### 🎯 The Target
Add **Software Composition Analysis** to CI — scanning third-party packages for known vulnerabilities and risky licenses — using `npm audit` plus **Trivy** for depth.

### 🧠 The Concept
Your app is an **iceberg**: your code is the visible tip; the `node_modules` dependencies are the massive hidden bulk below the waterline. A vulnerability in *any* of those hundreds of packages is *your* vulnerability. **SCA** inventories that hidden mass and cross-references it against public vulnerability databases (the **CVE** list).

> **Definition — SCA (Software Composition Analysis):** Scanning your dependencies (direct and transitive) for known vulnerabilities and license risks.
> **Definition — CVE:** Common Vulnerabilities and Exposures — a public catalog of known security flaws, each with an ID like `CVE-2023-12345`.
> **Definition — SBOM:** Software Bill of Materials — a machine-readable inventory of every component in your app. Increasingly required for compliance.

### ⌨️ The Implementation

Add an SCA job. Append this job to **`.github/workflows/security.yml`** (under `jobs:`, same indentation as `sast` and `build`):

```yaml
  # ── Job 3: Software Composition Analysis ────────────────────────────────
  sca:
    name: SCA (Dependencies)
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      # npm's built-in audit: fast, catches high/critical advisories.
      - name: npm audit (fail on high or critical)
        run: npm audit --audit-level=high

      # Trivy: deeper scanner that also produces an SBOM.
      - name: Trivy dependency & config scan
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: "fs"          # scan the filesystem (deps + config)
          scan-ref: "."
          severity: "HIGH,CRITICAL" # only fail on serious issues (low noise)
          exit-code: "1"            # non-zero → fails the CI job (gate)
          ignore-unfixed: true      # don't block on vulns with no fix yet

      - name: Generate SBOM (CycloneDX format)
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: "fs"
          scan-ref: "."
          format: "cyclonedx"
          output: "sbom.cdx.json"

      - name: Upload SBOM as build artifact
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: sbom.cdx.json
```

To let developers manage *accepted* risks (a vuln with no fix, or a false positive) without disabling the whole scanner, add a Trivy ignore file:

**`.trivyignore`**
```gitignore
# Format: one CVE ID per line, with a comment explaining WHY it's accepted.
# Example (remove if not applicable):
# CVE-2024-00000  # No fix available; not exploitable in our usage. Review 2025-Q3.
```

### ✅ The Verification

Push and check the **Actions** tab — the new **SCA (Dependencies)** job runs `npm audit` and Trivy, then uploads an `sbom` artifact (downloadable from the workflow run page).

Run SCA locally to see it in action:
```bash
npm audit --audit-level=high
# → "found 0 vulnerabilities" on a clean tree
```

**Prove the SCA gate works** by installing a deliberately old, vulnerable package:
```bash
npm install lodash@4.17.11   # a version with known CVEs
npm audit
```
`npm audit` now **reports high-severity CVEs**, and in CI the SCA job fails. Remove it:
```bash
npm uninstall lodash
npm audit   # back to clean
```

---

## Step 2.5 — Enforce the Gate with Branch Protection

### 🎯 The Target
Make the CI checks **mandatory** by requiring them to pass before any merge to `main`.

### 🧠 The Concept
Writing the scanners is useless if people can merge around a red build. **Branch protection** is the **locked turnstile** at the platform gate: the door physically won't open until every required check is green. This converts our scanners from *suggestions* into *enforced policy*.

### ⌨️ The Implementation

This is configured in the GitHub UI (or via API). Document it in the repo so the policy is explicit:

**`docs/branch-protection.md`**
```markdown
# Branch protection policy for `main`

Configured under: Repo → Settings → Branches → Add branch ruleset.

Required settings:
- [x] Require a pull request before merging
- [x] Require status checks to pass before merging
      Required checks:
        - SAST (Semgrep)
        - Lint, Build & Test
        - SCA (Dependencies)
- [x] Require branches to be up to date before merging
- [x] Do not allow bypassing the above settings (applies to admins too)

Result: no code reaches `main` unless SAST + SCA + build all pass.
This is our un-skippable, central security gate (defense in depth atop
the Phase 1 local hooks).
```

> If you use the GitHub CLI, you can apply a ruleset via `gh api` — but the UI is the clearest path for a first setup, so we document the exact checkboxes.

### ✅ The Verification

1. In GitHub, apply the settings above (mark the three jobs as **required status checks**).
2. Open a PR containing the intentional `src/vuln.ts` from Step 2.3.
3. Observe: the **Merge button is disabled**, showing "Required statuses must pass." Even a repo admin cannot merge.
4. Remove the vuln, push, watch checks go green — the **Merge button enables**.

The gate is now enforced. Commit the docs:
```bash
git add . && git commit -m "ci: add SCA + document enforced branch protection"
git push
```

---

## 📚 Phase 2 Reference Section

*Deep dives — skip on first pass.*

### R2.1 — SAST vs SCA vs DAST at a glance
| | Scans what? | Runs code? | Catches | Phase |
|---|---|---|---|---|
| **SAST** | Your source code | No | Injection, unsafe APIs, hardcoded secrets | 2 |
| **SCA** | Third-party deps | No | Known CVEs in packages, bad licenses | 2 |
| **DAST** | The running app | Yes | Runtime flaws (auth bypass, XSS in responses) | 4 |

### R2.2 — Why bcrypt uses a "work factor"
The `12` in `bcrypt.hash(password, 12)` means 2¹² (4096) rounds of hashing. This makes each hash deliberately slow (~100ms), so an attacker who steals the hash database can only test a few thousand guesses per second instead of billions. As hardware improves, you raise the factor. This is called being **adaptively slow** — a feature, not a bug.

### R2.3 — Semgrep rule packs used
- `p/security-audit` — general security anti-patterns.
- `p/javascript` / `p/typescript` — language-specific bug classes.
- `p/secrets` — hardcoded credentials (belt-and-suspenders with gitleaks).
You can write custom rules in `.semgrep.yml` for org-specific policies (e.g., "never call `res.send(err.stack)`").

### R2.4 — Tuning noise vs coverage
The two dials that keep developers happy:
1. **`severity: HIGH,CRITICAL`** — ignore informational noise, fail only on serious issues.
2. **`ignore-unfixed: true`** — don't block on vulnerabilities that have no patch yet (you can't fix what upstream hasn't fixed). Track these in `.trivyignore` with review dates. A scanner that cries wolf gets disabled; a tuned scanner gets trusted.

### R2.5 — The SBOM's future role
The `sbom.cdx.json` artifact we generate becomes valuable in Phase 4/5: when a new CVE drops (like Log4Shell), you can instantly query *every* deployed SBOM to answer "are we affected?" in minutes instead of days.
