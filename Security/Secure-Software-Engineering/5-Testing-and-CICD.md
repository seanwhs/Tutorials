# Part 5: Testing & CI/CD Security

Picking up from Part 4: dependency vulnerabilities are now caught automatically before merge. But so far, every security check we've built (Semgrep, gitleaks, npm audit) inspects **code that never runs**. None of it has actually *executed* SecureTrade and tried to break in like a real attacker would. This part closes that gap and assembles everything into one continuous pipeline.

**Goal recap:** security tests run on every single commit — automatically, with no human required to remember to run them.

---

## Step 1 — Add Automated Tests for Critical Security Logic

### 🎯 The Target
Vitest installed, with unit tests covering the security-critical pure functions we've written since Part 3: Zod schemas, the RBAC `requireRole` check, and the SSRF guard.

### 💡 The Concept
Most tutorials teach "write tests for your features." We're doing something narrower and more deliberate first: **write tests specifically for your security logic** — the functions that, if they silently broke during a future refactor, would reopen a vulnerability we already fixed. Think of these tests like a bank's daily vault-lock inspection: nobody expects the lock to fail, but a of couple minutes of automated checking every single day is far cheaper than discovering it failed the hard way. A refactor six months from now that accidentally makes `requireRole` always return `true` should be caught in 2 seconds by CI — not discovered by an attacker in production.

We use **Vitest** (fast, TypeScript-native, near-zero config) rather than Jest, since our target functions are plain TypeScript modules with no dependency on Next.js's request/response runtime.

### 🛠️ The Implementation

```bash
npm install -D vitest @vitest/coverage-v8
```

First, a small refactor for testability — extract the typosquat distance function into its own reusable module (good practice: pure logic shouldn't be trapped inside a script that also does I/O):

##### 📄 File: `lib/levenshtein.ts`
```typescript
// lib/levenshtein.ts
//
// Extracted from scripts/check-typosquats.ts so it can be unit tested in
// isolation, independent of file-system reads or process.exit() calls.

export function levenshteinDistance(a: string, b: string): number {
  const matrix: number[][] = Array.from({ length: a.length + 1 }, (_, i) =>
    Array.from({ length: b.length + 1 }, (_, j) => (i === 0 ? j : j === 0 ? i : 0))
  );

  for (let i = 1; i <= a.length; i++) {
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost
      );
    }
  }
  return matrix[a.length][b.length];
}
```

##### 📄 File: `scripts/check-typosquats.ts` (edit — replace the local function with the import)
```typescript
// scripts/check-typosquats.ts
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { levenshteinDistance } from "@/lib/levenshtein"; // <-- now imported, not duplicated

function main() {
  const pkgJson = JSON.parse(readFileSync(join(process.cwd(), "package.json"), "utf-8"));
  const ourDeps: string[] = [
    ...Object.keys(pkgJson.dependencies ?? {}),
    ...Object.keys(pkgJson.devDependencies ?? {}),
  ];
  const popular: string[] = JSON.parse(
    readFileSync(join(process.cwd(), "data", "popular-packages.json"), "utf-8")
  );

  const suspicious: { ours: string; similarTo: string; distance: number }[] = [];
  for (const dep of ourDeps) {
    for (const famous of popular) {
      if (dep === famous) continue;
      const distance = levenshteinDistance(dep, famous);
      const threshold = famous.length <= 4 ? 1 : 2;
      if (distance > 0 && distance <= threshold) {
        suspicious.push({ ours: dep, similarTo: famous, distance });
      }
    }
  }

  console.log("\nSecureTrade — Typosquatting Heuristic Check\n");
  if (suspicious.length === 0) {
    console.log("✅ No suspiciously-named dependencies found.\n");
    process.exit(0);
  }
  console.log("⚠️  Review these dependencies manually before trusting them:\n");
  for (const s of suspicious) {
    console.log(`  "${s.ours}" is very similar to popular package "${s.similarTo}" (edit distance ${s.distance})`);
  }
  process.exit(1);
}

main();
```

##### 📄 File: `vitest.config.ts`
```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";
import path from "node:path";

export default defineConfig({
  test: {
    environment: "node", // our security logic is server-side, no DOM needed
    coverage: {
      provider: "v8",
      reporter: ["text", "json-summary"],
      // Security-critical modules must meet a HIGHER bar than "some
      // coverage exists somewhere" — we enforce this per-file, not just
      // as a vague project-wide average.
      thresholds: {
        "lib/auth-helpers.ts": { statements: 90, branches: 90 },
        "lib/ssrf-guard.ts": { statements: 90, branches: 90 },
        "lib/validation/*.ts": { statements: 90, branches: 90 },
      },
    },
  },
  resolve: {
    alias: { "@": path.resolve(__dirname, "./") },
  },
});
```

##### 📄 File: `tests/unit/validation.test.ts`
```typescript
// tests/unit/validation.test.ts
import { describe, it, expect } from "vitest";
import { registerSchema, loginSchema } from "@/lib/validation/auth";
import { createOrderSchema } from "@/lib/validation/order";
import { updateProfileSchema } from "@/lib/validation/user";

describe("registerSchema", () => {
  it("accepts a valid registration payload", () => {
    const result = registerSchema.safeParse({
      email: "trader@example.com",
      name: "Tom Trader",
      password: "SuperSecure123",
    });
    expect(result.success).toBe(true);
  });

  it("rejects a password missing an uppercase letter", () => {
    const result = registerSchema.safeParse({
      email: "trader@example.com",
      name: "Tom",
      password: "lowercase123",
    });
    expect(result.success).toBe(false);
  });

  it("rejects a password shorter than 12 characters", () => {
    const result = registerSchema.safeParse({
      email: "trader@example.com",
      name: "Tom",
      password: "Short1A",
    });
    expect(result.success).toBe(false);
  });

  it("lower-cases and trims the email", () => {
    const result = registerSchema.safeParse({
      email: "  Trader@Example.COM  ",
      name: "Tom",
      password: "SuperSecure123",
    });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.email).toBe("trader@example.com");
    }
  });
});

describe("loginSchema", () => {
  it("rejects a missing password", () => {
    const result = loginSchema.safeParse({ email: "a@b.com", password: "" });
    expect(result.success).toBe(false);
  });
});

describe("createOrderSchema — regression guard for Bug 4 (Part 3)", () => {
  it("has NO price field in its shape at all", () => {
    // This test exists specifically to catch a future regression: if
    // someone re-adds a `price` field to this schema (re-introducing the
    // client-trusted-price vulnerability we fixed in Part 3), this test
    // fails immediately.
    const shapeKeys = Object.keys(createOrderSchema.shape);
    expect(shapeKeys).not.toContain("price");
    expect(shapeKeys.sort()).toEqual(
      ["idempotencyKey", "instrumentId", "quantity", "side"].sort()
    );
  });

  it("rejects a negative quantity", () => {
    const result = createOrderSchema.safeParse({
      instrumentId: "clx0000000000000000000000",
      side: "BUY",
      quantity: -5,
      idempotencyKey: "9f9a9a9a-9a9a-4a9a-8a9a-9a9a9a9a9a9a",
    });
    expect(result.success).toBe(false);
  });
});

describe("updateProfileSchema — regression guard for Bug 3 (Part 3)", () => {
  it("has NO role field in its shape at all", () => {
    const shapeKeys = Object.keys(updateProfileSchema.shape);
    expect(shapeKeys).not.toContain("role");
    expect(shapeKeys).toEqual(["name"]);
  });
});
```

##### 📄 File: `tests/unit/auth-helpers.test.ts`
```typescript
// tests/unit/auth-helpers.test.ts
import { describe, it, expect } from "vitest";
import { requireRole, AuthorizationError } from "@/lib/auth-helpers";
import type { Session } from "next-auth";

function fakeSession(role: "USER" | "ADMIN" | "AUDITOR"): Session {
  return {
    user: { id: "user_123", role, name: "Test", email: "t@example.com" },
    expires: new Date(Date.now() + 1000 * 60).toISOString(),
  } as Session;
}

describe("requireRole — the core RBAC enforcement function", () => {
  it("allows a role that IS in the allowed list", () => {
    expect(() => requireRole(fakeSession("ADMIN"), ["ADMIN", "AUDITOR"])).not.toThrow();
  });

  it("throws AuthorizationError for a role NOT in the allowed list", () => {
    expect(() => requireRole(fakeSession("USER"), ["ADMIN", "AUDITOR"])).toThrow(
      AuthorizationError
    );
  });

  it("throws for an empty allowed-roles list (fail closed, never fail open)", () => {
    // This is a deliberate Secure Defaults test: if a route handler is
    // ever written with an accidentally-empty allowed list, NOBODY should
    // be let through — the safe failure mode is "deny everyone," not
    // "allow everyone."
    expect(() => requireRole(fakeSession("ADMIN"), [])).toThrow(AuthorizationError);
  });
});
```

##### 📄 File: `tests/unit/ssrf-guard.test.ts`
```typescript
// tests/unit/ssrf-guard.test.ts
import { describe, it, expect } from "vitest";
import { assertSafeWebhookUrl, UnsafeUrlError } from "@/lib/ssrf-guard";

describe("assertSafeWebhookUrl — regression guard for Bug 6 (Part 3)", () => {
  it("rejects plain http:// URLs", async () => {
    await expect(assertSafeWebhookUrl("http://example.com")).rejects.toThrow(UnsafeUrlError);
  });

  it("rejects localhost explicitly", async () => {
    await expect(assertSafeWebhookUrl("https://localhost/")).rejects.toThrow(UnsafeUrlError);
  });

  it("rejects the AWS/GCP cloud metadata IP directly", async () => {
    await expect(assertSafeWebhookUrl("https://169.254.169.254/")).rejects.toThrow(
      UnsafeUrlError
    );
  });

  it("rejects a malformed URL gracefully, without throwing an uncaught exception", async () => {
    await expect(assertSafeWebhookUrl("not-a-url-at-all")).rejects.toThrow(UnsafeUrlError);
  });

  it("accepts a legitimate public https URL", async () => {
    // github.com is a stable, real, public HTTPS host — safe to resolve
    // in a test without needing a mock DNS server for this one case.
    await expect(assertSafeWebhookUrl("https://github.com")).resolves.toBeInstanceOf(URL);
  });
});
```

##### 📄 File: `tests/unit/levenshtein.test.ts`
```typescript
// tests/unit/levenshtein.test.ts
import { describe, it, expect } from "vitest";
import { levenshteinDistance } from "@/lib/levenshtein";

describe("levenshteinDistance — powers the typosquatting guard (Part 4)", () => {
  it("returns 0 for identical strings", () => {
    expect(levenshteinDistance("express", "express")).toBe(0);
  });

  it("detects a classic 1-character typosquat", () => {
    expect(levenshteinDistance("expres", "express")).toBe(1);
  });

  it("returns a large distance for genuinely unrelated names", () => {
    expect(levenshteinDistance("zod", "webpack")).toBeGreaterThan(4);
  });
});
```

##### 📄 File: `package.json` (edit — add scripts)
```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage"
  }
}
```

### ✅ The Verification

```bash
npm run test
```
Expected output ends with something like:
```
Test Files  5 passed (5)
     Tests  17 passed (17)
```

```bash
npm run test:coverage
```
Confirm `lib/auth-helpers.ts`, `lib/ssrf-guard.ts`, and `lib/validation/*.ts` all show ≥90% coverage in the printed table — if any is below threshold, the command exits non-zero, exactly as we'll require in CI.

---

## Step 2 — Add CodeQL as a Second, Independent SAST Layer

### 🎯 The Target
`.github/workflows/codeql.yml` — GitHub's own semantic code analysis engine, running alongside (not replacing) Semgrep from Part 3.

### 💡 The Concept
Semgrep matches *syntactic patterns* — "this specific shape of code." **CodeQL** goes a level deeper: it treats your code as queryable data and can trace *data flow* across many function calls — e.g., "does any value that originated from `req.body` eventually reach a database query, through any chain of function calls, without passing through a sanitizer?" This is like the difference between a proofreader checking for specific misspelled words (Semgrep) versus a fact-checker who can trace a claim in paragraph 5 all the way back to a source cited in paragraph 1, however many pages apart (CodeQL). Different strengths, which is exactly why real engineering teams run both rather than picking one.

### 🛠️ The Implementation

##### 📄 File: `.github/workflows/codeql.yml`
```yaml
# .github/workflows/codeql.yml
#
# GitHub's semantic SAST engine. Free for public repos, and free for
# private repos on GitHub Team/Enterprise plans (GitHub Advanced Security).

name: CodeQL

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  schedule:
    - cron: "30 4 * * 3" # Weekly Wednesday scan — catches newly-published query rules against unchanged code

permissions:
  contents: read
  security-events: write # required to upload findings to the Security tab

jobs:
  analyze:
    name: CodeQL Analysis
    runs-on: ubuntu-latest
    strategy:
      matrix:
        language: ["javascript-typescript"]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
          # "security-extended" adds additional query packs beyond the
          # default set — more thorough, at the cost of a few extra
          # minutes of scan time, which is an acceptable trade-off for a
          # financial app.
          queries: security-extended

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
        with:
          category: "/language:${{ matrix.language }}"
```

### ✅ The Verification

```bash
git add -A
git commit -m "ci: add CodeQL as a second, independent SAST layer"
git push
```

```bash
gh workflow run codeql.yml
gh run watch
```
Expected: the run completes with a green check. Then visit **your repo → Security tab → Code scanning alerts** in the browser — confirm it shows "CodeQL" as an active analysis tool with 0 (or a reviewed list of) findings.

---

## Step 3 — Move Secret Scanning Into CI

### 🎯 The Target
`.github/workflows/secret-scan.yml` — running Gitleaks (introduced locally in Part 3) and adding TruffleHog, both now scanning **every pull request automatically**, not just when a developer remembers to run them locally.

### 💡 The Concept
A local `gitleaks detect` (Part 3) only protects you if you personally remember to run it, on every machine, every time, forever. That's the same "supervisor has to remember to check" weakness we solved for dependency scanning in Part 4. We add **TruffleHog** alongside Gitleaks for the same "second opinion" reasoning as Snyk-plus-OSV in Part 4 — TruffleHog's standout feature is **live credential verification**: for many secret types (AWS keys, Stripe keys, GitHub tokens), it doesn't just pattern-match a string that *looks* like a secret, it actually attempts a harmless authenticated API call to confirm the credential is real and currently active — dramatically cutting down on false positives that waste a reviewer's time.

### 🛠️ The Implementation

##### 📄 File: `.github/workflows/secret-scan.yml`
```yaml
# .github/workflows/secret-scan.yml

name: Secret Scanning

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  gitleaks:
    name: Gitleaks
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0 # full history — a secret committed 50 commits ago is still a leak today

      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_CONFIG: .gitleaks.toml

  trufflehog:
    name: TruffleHog (with live credential verification)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run TruffleHog
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.pull_request.base.sha }}
          head: ${{ github.event.pull_request.head.sha }}
          # --only-verified: only FAIL the build for secrets TruffleHog
          # could actually confirm are live/active credentials — reduces
          # noisy false positives from random high-entropy strings that
          # merely LOOK like secrets but aren't (e.g. a test fixture UUID).
          extra_args: --only-verified
```

### ✅ The Verification

```bash
git add -A
git commit -m "ci: move secret scanning (Gitleaks + TruffleHog) into GitHub Actions"
git push
```

Prove it actually catches something — open a throwaway branch and commit a fake-but-realistic-looking secret:

```bash
git checkout -b test/secret-scan-check
echo "AWS_SECRET_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE" >> /tmp/fake-secret.env
cp /tmp/fake-secret.env leaked-test.env
git add leaked-test.env
git commit -m "test: intentional fake secret to verify scanning catches it"
git push -u origin test/secret-scan-check
gh pr create --title "Test: secret scan" --body "Verifying secret-scan.yml catches a planted fake secret" --base main
gh pr checks --watch
```
Expected: the `gitleaks` job fails (Gitleaks pattern-matches the well-known AWS key format regardless of verification). Clean up immediately:
```bash
gh pr close --delete-branch
git checkout main
git branch -D test/secret-scan-check
```

---

## Step 4 — Connect the App to Vercel for Preview Deployments

### 🎯 The Target
SecureTrade linked to a Vercel project, with automatic preview deployments firing on every pull request — giving us a real, running target for DAST in Step 6.

### 💡 The Concept
Everything we've tested so far (SAST, unit tests, secret scanning) inspects code **at rest**. DAST needs a real, running, network-reachable copy of the app to attack — you can't port-scan a PDF. Vercel's **preview deployments** feature automatically builds and hosts a live, unique URL for every single pull request, completely separate from production — like a contractor building a full-scale demo room in a side lot before ever touching the real building, so inspectors can test it without any risk to the occupied structure.

### 🛠️ The Implementation

```bash
npm install -D vercel
npx vercel login
npx vercel link
```
Follow the prompts: **Set up and link "securetrade"?** → Yes → select your Vercel account/team → **Link to existing project?** → No → project name `securetrade`.

This creates a `.vercel/` folder locally — **never commit this**, it contains project/org IDs tied to your account:

```bash
grep -q "^\.vercel" .gitignore || echo ".vercel" >> .gitignore
```

Now connect the actual GitHub repository so Vercel deploys automatically (do this in the browser, since it's a one-time OAuth-style connection, not something scriptable via CLI):

1. Go to your Vercel dashboard → your `securetrade` project → **Settings → Git**.
2. Click **Connect Git Repository**, select GitHub, authorize access, choose your `securetrade` repo.
3. Under **Ignored Build Step**, leave default (build every push).

Set the environment variables the app needs, scoped correctly per environment (never reuse production secrets in Preview):

```bash
# Each of these prompts you to paste a value — nothing is written to any
# file Git can see; Vercel stores these encrypted, server-side only.
npx vercel env add DATABASE_URL preview
npx vercel env add DIRECT_URL preview
npx vercel env add AUTH_SECRET preview
npx vercel env add NEXTAUTH_URL preview   # set to a placeholder for now; Vercel injects the real preview URL automatically via VERCEL_URL, wired up in Part 6
```

Generate a scoped Vercel API token for CI to query deployment status (Settings → your avatar → **Tokens** → Create, scope it to this one project only if your plan tier supports project-scoped tokens):

```bash
gh secret set VERCEL_TOKEN --body "PASTE_YOUR_SCOPED_VERCEL_TOKEN"
gh secret set VERCEL_PROJECT_ID --body "$(cat .vercel/project.json | python3 -c 'import json,sys;print(json.load(sys.stdin)["projectId"])')"
gh secret set VERCEL_ORG_ID --body "$(cat .vercel/project.json | python3 -c 'import json,sys;print(json.load(sys.stdin)["orgId"])')"
```

### ✅ The Verification

```bash
git checkout -b test/vercel-preview
git commit --allow-empty -m "test: trigger first Vercel preview deployment"
git push -u origin test/vercel-preview
gh pr create --title "Test: Vercel preview" --body "Verifying automatic preview deployment" --base main
```

Wait ~60 seconds, then check:
```bash
gh pr checks
```
Expected: a check named `Vercel` (or `Vercel – securetrade`) appears and eventually shows ✅, with a **Details** link pointing to a live `https://securetrade-git-test-vercel-preview-yourusername.vercel.app` URL. Open it — confirm the Next.js homepage loads over a real internet connection. Keep this PR branch open — we use it again in Step 6.

---

## Step 5 — Script to Locate the Ready Preview Deployment URL

### 🎯 The Target
`scripts/wait-for-vercel-preview.ts` — a script CI can run to reliably find the exact preview URL for the current commit, and wait until it's actually finished building before attacking it.

### 💡 The Concept
Vercel's deployment isn't instantaneous — there's a build step that takes anywhere from 30 seconds to a few minutes. If our DAST scan starts attacking the URL too early, it'll hit a "Building..." placeholder page, not the real app, and produce a meaningless report. This script is like a chef who doesn't plate a dish for the food critic to review until the oven timer has actually finished — polling patiently instead of guessing a fixed wait time that might be too short (flaky) or too long (wastes CI minutes).

### 🛠️ The Implementation

##### 📄 File: `scripts/wait-for-vercel-preview.ts`
```typescript
// scripts/wait-for-vercel-preview.ts
//
// Polls the Vercel API for the deployment matching the current commit SHA,
// waits until its state is READY, then prints the URL to stdout — so CI
// can capture it with `$(...)` and pass it straight to the DAST scanner.

const VERCEL_TOKEN = process.env.VERCEL_TOKEN;
const PROJECT_ID = process.env.VERCEL_PROJECT_ID;
const COMMIT_SHA = process.env.GITHUB_SHA;

const POLL_INTERVAL_MS = 10_000;
const MAX_WAIT_MS = 5 * 60 * 1000; // 5 minutes — generous, but bounded so CI never hangs forever

type VercelDeployment = {
  uid: string;
  url: string;
  readyState: "QUEUED" | "BUILDING" | "READY" | "ERROR" | "CANCELED";
  meta?: { githubCommitSha?: string };
};

function requireEnv(name: string, value: string | undefined): string {
  if (!value) {
    console.error(`Missing required environment variable: ${name}`);
    process.exit(1);
  }
  return value;
}

async function findDeployment(): Promise<VercelDeployment | null> {
  const token = requireEnv("VERCEL_TOKEN", VERCEL_TOKEN);
  const projectId = requireEnv("VERCEL_PROJECT_ID", PROJECT_ID);

  const res = await fetch(
    `https://api.vercel.com/v6/deployments?projectId=${projectId}&limit=20`,
    { headers: { Authorization: `Bearer ${token}` } }
  );

  if (!res.ok) {
    console.error(`Vercel API error: ${res.status} ${await res.text()}`);
    process.exit(1);
  }

  const data = (await res.json()) as { deployments: VercelDeployment[] };
  return data.deployments.find((d) => d.meta?.githubCommitSha === COMMIT_SHA) ?? null;
}

async function main() {
  requireEnv("GITHUB_SHA", COMMIT_SHA);

  const startTime = Date.now();

  while (Date.now() - startTime < MAX_WAIT_MS) {
    const deployment = await findDeployment();

    if (deployment) {
      if (deployment.readyState === "READY") {
        // Vercel's API returns the url WITHOUT a protocol — add https://
        // explicitly, since that's what every downstream consumer expects.
        console.log(`https://${deployment.url}`);
        return;
      }
      if (deployment.readyState === "ERROR" || deployment.readyState === "CANCELED") {
        console.error(`Deployment failed with state: ${deployment.readyState}`);
        process.exit(1);
      }
      console.error(`Deployment state: ${deployment.readyState}, waiting...`);
    } else {
      console.error("No matching deployment found yet, waiting...");
    }

    await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
  }

  console.error(`Timed out after ${MAX_WAIT_MS / 1000}s waiting for a ready deployment.`);
  process.exit(1);
}

main();
```

### ✅ The Verification

Run it locally against the real preview PR from Step 4 (export the same secrets locally, temporarily, for this one test):

```bash
export VERCEL_TOKEN="your-token"
export VERCEL_PROJECT_ID="your-project-id"
export GITHUB_SHA=$(git rev-parse HEAD)
npx tsx scripts/wait-for-vercel-preview.ts
```
Expected: after the deployment is already `READY` (from Step 4), this prints the `https://...vercel.app` URL immediately to stdout, with no error output.

---

## Step 6 — DAST: Scan the Vercel Preview with OWASP ZAP

### 🎯 The Target
`.github/workflows/dast.yml` — a workflow that finds the ready preview URL and launches OWASP ZAP to actually attack it, exactly like a real adversary would.

### 💡 The Concept
**OWASP ZAP** (Zed Attack Proxy) is a DAST tool that behaves like an automated, tireless penetration tester: it crawls your live application the way a browser would, then systematically tries hundreds of known attack payloads against every form field, URL parameter, and header it discovers — SQL injection strings, XSS payloads, checking for missing security headers, and more — entirely from the *outside*, with zero knowledge of your source code. This is the "mystery shopper actually trying to shoplift" analogy from Part 4, made real: ZAP doesn't know we fixed Bug 1's SQL injection in Part 3 by reading our code — it finds out by actually trying the attack against the running app and observing the response.

We use ZAP's **baseline scan** — a fast, passive-plus-light-active scan appropriate for running on every PR (a "full active scan" is more thorough but much slower and more aggressive; we reserve that for a scheduled, less frequent job in the Reference section).

### 🛠️ The Implementation

First, tune which ZAP rules should actually fail the build — some default rules (like "missing X-Powered-By removal") are low-value noise at this stage; we want CI to fail loudly on things that actually matter (reflected XSS, SQL injection, missing critical security headers) and just warn on the rest:

##### 📄 File: `.zap/rules.tsv`
```
# .zap/rules.tsv
# Format: RULE_ID	THRESHOLD	{IGNORE, WARN, FAIL}
# Full rule ID reference: https://www.zaproxy.org/docs/alerts/

# --- FAIL: these must block the pipeline if found ---
40018	FAIL	# SQL Injection
40012	FAIL	# Cross Site Scripting (Reflected)
40014	FAIL	# Cross Site Scripting (Persistent)
90019	FAIL	# Server Side Code Injection
90020	FAIL	# Remote OS Command Injection

# --- WARN: worth knowing about, but shouldn't block a PR merge yet ---
# (Security headers are fully addressed in Part 6 — expected to still be
# incomplete at this stage of the series, so we don't fail the build for
# them yet, only make them visible in the report.)
10038	WARN	# Content Security Policy Header Not Set
10035	WARN	# Strict-Transport-Security Header Not Set
10063	WARN	# Permissions Policy Header Not Set

# --- IGNORE: known non-issues for a preview deployment specifically ---
10004	IGNORE	# Vercel preview URLs are inherently unguessable/random, not
                # a real information disclosure concern the way a
                # predictable production hostname would be.
```

##### 📄 File: `.github/workflows/dast.yml`
```yaml
# .github/workflows/dast.yml
#
# Waits for the PR's Vercel preview deployment to be ready, then runs an
# OWASP ZAP baseline scan against it — real, live attack traffic against a
# real, running copy of the app.

name: DAST — OWASP ZAP

on:
  pull_request:
    branches: [main]

permissions:
  contents: read
  issues: write # ZAP action can post findings as a PR comment

jobs:
  dast:
    name: ZAP Baseline Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"

      - run: npm ci

      - name: Wait for Vercel preview deployment to be ready
        id: wait-for-preview
        env:
          VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
          VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
        run: |
          PREVIEW_URL=$(npx tsx scripts/wait-for-vercel-preview.ts)
          echo "preview_url=$PREVIEW_URL" >> "$GITHUB_OUTPUT"
          echo "Scanning: $PREVIEW_URL"

      - name: Run OWASP ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: ${{ steps.wait-for-preview.outputs.preview_url }}
          rules_file_name: ".zap/rules.tsv"
          # Fails the GitHub Actions job (not just posts a warning comment)
          # if any rule marked FAIL above is triggered.
          fail_action: true
          cmd_options: "-a" # include light active scanning, not just passive crawling
          allow_issue_writing: true # posts a summary comment directly on the PR

      - name: Upload full ZAP report
        if: always() # capture the report even if the scan step failed, for debugging
        uses: actions/upload-artifact@v4
        with:
          name: zap-report
          path: |
            report_html.html
            report_md.md
          retention-days: 90
```

### ✅ The Verification

Reuse the open PR from Step 4 (or open a fresh one), push a trivial commit to re-trigger:

```bash
git checkout test/vercel-preview
git commit --allow-empty -m "test: trigger DAST workflow run"
git push
```

```bash
gh pr checks --watch
```
Expected: a `ZAP Baseline Scan` check appears, waits (visible in logs: "Deployment state: BUILDING, waiting..." then eventually the printed preview URL), runs the scan, and finishes ✅ green (assuming Part 3's fixes hold — no reflected XSS or injection is actually present). Open the PR in the browser — confirm ZAP posted an automated comment summarizing the scan (informational + warning findings, e.g. the still-pending security headers from Part 6, exactly as configured to WARN not FAIL). Download the `zap-report` artifact from the run summary and open `report_html.html` locally to see the full, detailed findings report.

Close the test PR when done:
```bash
gh pr close --delete-branch
```

---

## Step 7 — Secure CI/CD Authentication: OIDC to AWS, No Long-Lived Tokens

### 🎯 The Target
GitHub Actions authenticating to AWS to upload the SBOM (Part 4) and ZAP reports (Step 6) to a private S3 bucket for long-term audit retention — **without ever storing an AWS access key or secret anywhere**.

### 💡 The Concept
Every credential we've stored as a GitHub secret so far (`VERCEL_TOKEN`, `SNYK_TOKEN`) is a **long-lived static credential** — if it ever leaks, it remains valid and exploitable until someone manually revokes it, possibly weeks or months later. **OIDC (OpenID Connect) federation** solves this differently: instead of GitHub Actions holding a permanent AWS password, GitHub issues a short-lived, cryptographically signed identity token *specific to that exact workflow run* (valid for minutes, tied to the specific repo and branch), and AWS is configured to trust GitHub's signature directly and hand back **temporary** credentials (valid ~1 hour) in exchange. It's the difference between giving a contractor a permanent key to your building (a static access key — if lost, you must physically re-key every lock) versus a receptionist who verifies the contractor's ID badge fresh at the front desk every single morning and issues a visitor pass that expires that evening (OIDC — nothing permanent ever changes hands, and a leaked visitor pass is worthless within hours).

**Important transparency:** the `VERCEL_TOKEN` we created in Step 4 is *not* OIDC-based — as of this writing, Vercel's deployment API requires a standard bearer token, a real-world limitation worth naming honestly rather than glossing over (see the Reference section for how we mitigate this specific exception).

### 🛠️ The Implementation

Create an AWS account if you don't have one ([aws.amazon.com/free](https://aws.amazon.com/free)), then run these one-time setup commands using the AWS CLI:

```bash
# Install the AWS CLI if needed, then configure it ONCE with your own
# personal admin credentials — this is the ONLY place a long-lived AWS
# credential is ever used in this entire series, and only on your local
# machine to perform initial setup, never inside CI.
aws configure
```

**1. Register GitHub as a trusted OIDC identity provider in AWS IAM (one-time, account-wide):**

```bash
aws iam create-open-id-connect-provider \
  --url "https://token.actions.githubusercontent.com" \
  --client-id-list "sts.amazonaws.com" \
  --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1"
```

**2. Create an S3 bucket for security artifacts, with public access fully blocked and encryption enforced:**

```bash
aws s3api create-bucket \
  --bucket securetrade-security-artifacts \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1

aws s3api put-public-access-block \
  --bucket securetrade-security-artifacts \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws s3api put-bucket-encryption \
  --bucket securetrade-security-artifacts \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'
```

**3. Create an IAM role that GitHub Actions can assume — with a trust policy scoped to ONLY this exact repository and ONLY the `main` branch:**

##### 📄 File: `aws/trust-policy.json` (local file, used once for setup — not deployed anywhere)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/securetrade:ref:refs/heads/main"
        }
      }
    }
  ]
}
```
⚠️ Replace `YOUR_ACCOUNT_ID` and `YOUR_GITHUB_USERNAME` before running. The `sub` condition is the critical Least Privilege control here — it means this role can **only** ever be assumed by a workflow run triggered from `main` in *this specific repository*, not from a fork, not from a different branch, not from any other repo on GitHub.

```bash
aws iam create-role \
  --role-name securetrade-github-actions-artifacts \
  --assume-role-policy-document file://aws/trust-policy.json
```

**4. Attach a minimal permissions policy — write access to this one bucket only, nothing else in the AWS account:**

##### 📄 File: `aws/permissions-policy.json`
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": "arn:aws:s3:::securetrade-security-artifacts/*"
    }
  ]
}
```

```bash
aws iam put-role-policy \
  --role-name securetrade-github-actions-artifacts \
  --policy-name s3-upload-only \
  --policy-document file://aws/permissions-policy.json

# Note the Role ARN printed here — needed for the workflow file below.
aws iam get-role --role-name securetrade-github-actions-artifacts --query 'Role.Arn'
```

Store the role ARN as a GitHub Actions variable (not a secret — an ARN isn't sensitive on its own, since the trust policy above is what actually restricts access):

```bash
gh variable set AWS_ARTIFACTS_ROLE_ARN --body "arn:aws:iam::YOUR_ACCOUNT_ID:role/securetrade-github-actions-artifacts"
```

Now add the upload step to our dependency and DAST workflows:

##### 📄 File: `.github/workflows/dependency-security.yml` (edit — add a new job)
```yaml
  upload-sbom-to-audit-store:
    name: Upload SBOM to audit S3 bucket (OIDC)
    runs-on: ubuntu-latest
    needs: [sbom]
    if: github.ref == 'refs/heads/main' # only archive from real, merged main-branch runs
    permissions:
      contents: read
      id-token: write # REQUIRED for OIDC — this permission is what lets
                       # this job request a signed identity token from
                       # GitHub in the first place.
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: sbom

      # No access key, no secret key, anywhere in this step. GitHub issues
      # a short-lived OIDC token; AWS verifies it against the trust policy
      # from Step 7 and hands back temporary (≈1 hour) credentials.
      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ARTIFACTS_ROLE_ARN }}
          aws-region: ap-southeast-1

      - name: Upload SBOM
        run: |
          aws s3 cp sbom.json \
            "s3://securetrade-security-artifacts/sbom/$(date +%Y-%m-%d)-${{ github.sha }}.json"
```

##### 📄 File: `.github/workflows/dast.yml` (edit — add a new job)
```yaml
  upload-zap-report-to-audit-store:
    name: Upload ZAP report to audit S3 bucket (OIDC)
    runs-on: ubuntu-latest
    needs: [dast]
    if: always() && github.ref == 'refs/heads/main'
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: zap-report

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ARTIFACTS_ROLE_ARN }}
          aws-region: ap-southeast-1

      - name: Upload ZAP report
        run: |
          aws s3 cp report_html.html \
            "s3://securetrade-security-artifacts/zap-reports/$(date +%Y-%m-%d)-${{ github.sha }}.html"
```

### ✅ The Verification

Merge a small change to `main` (or push directly if you're the sole contributor at this stage) to trigger a `main`-branch run of both workflows:

```bash
gh run list --branch main --limit 3
```

```bash
aws s3 ls s3://securetrade-security-artifacts/sbom/ --recursive
aws s3 ls s3://securetrade-security-artifacts/zap-reports/ --recursive
```
Expected: both list a recently-uploaded file matching today's date and the latest commit SHA. Then confirm the security boundary actually holds — attempt an action the role was **not** granted:

```bash
# Using the SAME role's temporary credentials (captured during a workflow
# run's logs would show only that IT succeeded at PutObject — but let's
# confirm the DENY explicitly via the policy simulator instead, which is
# safer than trying to actually assume the role from your own machine):
aws iam simulate-principal-policy \
  --policy-source-arn "arn:aws:iam::YOUR_ACCOUNT_ID:role/securetrade-github-actions-artifacts" \
  --action-names "s3:DeleteObject" "s3:GetObject" \
  --resource-arns "arn:aws:s3:::securetrade-security-artifacts/sbom/test.json"
```
Expected: both `s3:DeleteObject` and `s3:GetObject` show `"EvalDecision": "implicitDeny"` — proving this role really can *only* write new objects, and cannot read, modify, or delete anything, even its own uploads. That's Least Privilege, verified, not just assumed.

---

## Step 8 — Assemble the Full Pipeline & Enforce Branch Protection

### 🎯 The Target
A consolidated view of how all our workflows chain together, plus GitHub branch protection rules that make every one of these checks **mandatory** before any PR can merge — turning "we have security tooling" into "it is structurally impossible to bypass our security tooling."

### 💡 The Concept
All the workflows we've built (`dependency-security.yml`, `codeql.yml`, `secret-scan.yml`, `dast.yml`, plus Part 3's implicit Semgrep/ESLint/test run) already execute automatically. But right now, a determined (or careless) team member could still click "Merge" on a PR even if every single check shows a red ❌ — the checks currently only *inform*, they don't *enforce*. **Branch protection rules** are the difference between a smoke detector that just beeps (informational) and one wired directly to the fire suppression system that won't let the fire spread regardless of whether anyone hears the beep (enforced).

We also add one final workflow tying test execution to the same PR trigger as everything else, since Step 1's tests haven't been wired into CI yet.

### 🛠️ The Implementation

##### 📄 File: `.github/workflows/test.yml`
```yaml
# .github/workflows/test.yml

name: Unit Tests

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  test:
    name: Vitest
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: "npm"
      - run: npm ci
      - name: Run unit tests with coverage thresholds
        run: npm run test:coverage
      - name: Run ESLint (including security plugin rules)
        run: npm run lint:security
      - name: Run Semgrep
        run: npm run semgrep
      - name: Type-check
        run: npx tsc --noEmit
```

Now set up branch protection via the GitHub CLI, requiring every one of these named checks to pass:

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/{owner}/securetrade/branches/main/protection \
  -f required_status_checks[strict]=true \
  -f 'required_status_checks[contexts][]=Vitest' \
  -f 'required_status_checks[contexts][]=SCA — npm audit' \
  -f 'required_status_checks[contexts][]=SCA — Snyk' \
  -f 'required_status_checks[contexts][]=SCA — OSV Scanner' \
  -f 'required_status_checks[contexts][]=CodeQL Analysis' \
  -f 'required_status_checks[contexts][]=Gitleaks' \
  -f 'required_status_checks[contexts][]=TruffleHog (with live credential verification)' \
  -f 'required_status_checks[contexts][]=ZAP Baseline Scan' \
  -f enforce_admins=true \
  -f 'required_pull_request_reviews[required_approving_review_count]=1' \
  -f 'required_pull_request_reviews[dismiss_stale_reviews]=true' \
  -f restrictions=null \
  -f allow_force_pushes=false \
  -f allow_deletions=false
```

Replace `{owner}` with your GitHub username. This single API call encodes an enormous amount of security policy: every listed check must be green, `enforce_admins=true` means **even repository admins cannot bypass this** (a crucial detail — "the rules apply to everyone, no exceptions, including me" is itself a security control), at least one human review is required, stale approvals are dismissed if new commits are pushed (preventing a reviewer's approval on version A from silently rubber-stamping a completely different version C), and force-pushes/deletions of `main` are blocked outright (protecting the audit trail Part 1 designed for).

##### 📄 File: `docs/CI-CD-PIPELINE.md`
```markdown
# SecureTrade — CI/CD Pipeline Overview

## Pipeline Stages (all run automatically on every pull request to `main`)

```
┌─────────────┐   ┌──────────────┐   ┌───────────────┐
│ SAST         │   │ Tests         │   │ Secret Scan   │
│ Semgrep      │   │ Vitest        │   │ Gitleaks      │
│ ESLint-sec   │   │ (unit)        │   │ TruffleHog    │
│ CodeQL       │   │               │   │               │
└──────┬───────┘   └───────┬───────┘   └───────┬───────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                            │
                    (all must pass)
                            │
                            ▼
                  ┌───────────────────┐
                  │ DAST              │
                  │ OWASP ZAP scan of │
                  │ Vercel Preview    │
                  └─────────┬─────────┘
                            │
                    (must pass)
                            │
                            ▼
                  ┌───────────────────┐
                  │ SCA (Part 4)      │
                  │ npm audit, Snyk,  │
                  │ OSV, SBOM gen     │
                  └─────────┬─────────┘
                            │
                            ▼
                 Human review required (1 approval)
                            │
                            ▼
                     Merge to main
                            │
                            ▼
              ┌─────────────────────────┐
              │ Artifact archival (OIDC)│
              │ SBOM + ZAP report → S3  │
              └─────────────────────────┘
```

## Branch Protection Enforcement
All checks above are configured as REQUIRED status checks on `main`
(see `docs/CI-CD-PIPELINE.md` setup command in Part 5, Step 8).
`enforce_admins=true` — no one, including repository owners, can bypass
these checks via a direct push or admin merge override.

## Secrets and Their Scope
| Secret/Variable | Type | Scope | Rotation |
|---|---|---|---|
| `VERCEL_TOKEN` | Static bearer token (Vercel limitation — no OIDC support yet) | Read deployment status only | Every 90 days (see docs/SECRETS-POLICY.md) |
| `SNYK_TOKEN` | Static bearer token | Snyk scan only | Every 90 days |
| `AWS_ARTIFACTS_ROLE_ARN` | Public identifier, NOT a secret | N/A — access is controlled entirely by the IAM trust policy, not by this value's secrecy | N/A |
| AWS credentials for artifact upload | OIDC-issued, ~1 hour lifetime | `s3:PutObject` to one bucket only | Automatic — never stored |
```

### ✅ The Verification

```bash
gh api /repos/{owner}/securetrade/branches/main/protection --jq '.required_status_checks.contexts'
```
Expected: a JSON array listing all 8 check names you configured. Then prove enforcement actually works — try to push directly to `main`:

```bash
git checkout main
echo "test" >> README.md
git add -A
git commit -m "test: attempt direct push to protected main"
git push origin main
```
Expected: **rejected** with an error like `remote: error: GH006: Protected branch update failed... Changes must be made through a pull request.` Revert:
```bash
git checkout README.md
```

---

## Step 9 — Automate Verification of Part 5

### 🎯 The Target
`scripts/verify-part5.ts` — confirming every workflow file, test file, and branch protection setting from this part is in place.

### 🛠️ The Implementation

##### 📄 File: `scripts/verify-part5.ts`
```typescript
// scripts/verify-part5.ts

import { existsSync, readFileSync } from "node:fs";
import { execSync } from "node:child_process";
import { join } from "node:path";

type Check = { label: string; pass: boolean; detail?: string };
const checks: Check[] = [];

function fileExists(p: string): boolean {
  return existsSync(join(process.cwd(), p));
}

function main() {
  const requiredFiles = [
    "vitest.config.ts",
    "tests/unit/validation.test.ts",
    "tests/unit/auth-helpers.test.ts",
    "tests/unit/ssrf-guard.test.ts",
    "lib/levenshtein.ts",
    ".github/workflows/codeql.yml",
    ".github/workflows/secret-scan.yml",
    ".github/workflows/dast.yml",
    ".github/workflows/test.yml",
    ".zap/rules.tsv",
    "scripts/wait-for-vercel-preview.ts",
    "docs/CI-CD-PIPELINE.md",
  ];
  for (const f of requiredFiles) {
    checks.push({ label: `File exists: ${f}`, pass: fileExists(f) });
  }

  try {
    execSync("npm run test", { stdio: "pipe" });
    checks.push({ label: "Unit test suite passes", pass: true });
  } catch {
    checks.push({ label: "Unit test suite passes", pass: false });
  }

  // Confirm branch protection is actually configured on GitHub, not just
  // that local files exist — the real enforcement lives server-side.
  try {
    const output = execSync(
      "gh api repos/:owner/:repo/branches/main/protection --jq '.required_status_checks.contexts | length'",
      { encoding: "utf-8" }
    ).trim();
    checks.push({
      label: "Branch protection requires at least 6 status checks",
      pass: Number(output) >= 6,
      detail: `found ${output}`,
    });
  } catch {
    checks.push({ label: "Branch protection requires at least 6 status checks", pass: false });
  }

  try {
    const enforceAdmins = execSync(
      "gh api repos/:owner/:repo/branches/main/protection --jq '.enforce_admins.enabled'",
      { encoding: "utf-8" }
    ).trim();
    checks.push({
      label: "Branch protection applies to admins too (no bypass)",
      pass: enforceAdmins === "true",
    });
  } catch {
    checks.push({ label: "Branch protection applies to admins too (no bypass)", pass: false });
  }

  console.log("\nSecureTrade — Part 5 Verification\n");
  let allPassed = true;
  for (const c of checks) {
    const icon = c.pass ? "✅" : "❌";
    console.log(`${icon} ${c.label}${c.detail ? ` (${c.detail})` : ""}`);
    if (!c.pass) allPassed = false;
  }
  console.log(
    allPassed
      ? "\nAll Part 5 checks passed. Ready for Part 6.\n"
      : "\nSome checks failed — fix the items above before continuing.\n"
  );
  process.exit(allPassed ? 0 : 1);
}

main();
```

##### 📄 File: `package.json` (edit — add script)
```json
{
  "scripts": {
    "verify:part5": "tsx scripts/verify-part5.ts"
  }
}
```

### ✅ The Verification

```bash
npm run verify:part5
```
All checks should print ✅. Commit:

```bash
git add -A
git commit -m "feat: full CI/CD security pipeline — SAST (CodeQL), tests, secret scanning, DAST (ZAP on Vercel previews), OIDC artifact archival, branch protection"
git push
```

---

## ✅ Part 5 Completion Checklist

- [ ] Unit tests cover critical security logic with ≥90% coverage on key files
- [ ] CodeQL runs as a second SAST layer alongside Semgrep
- [ ] Gitleaks + TruffleHog run automatically in CI on every PR
- [ ] Vercel preview deployments fire automatically per PR
- [ ] OWASP ZAP scans every preview deployment and fails the build on Critical findings
- [ ] SBOM and ZAP reports archive to S3 via OIDC — zero long-lived AWS credentials anywhere
- [ ] Branch protection requires all checks green + 1 human review, with no admin bypass
- [ ] `npm run verify:part5` exits all green

---

# 📚 Reference Section — Deep Dives for Part 5

### R1. ZAP Baseline vs. Full Active Scan

| | Baseline Scan (what we used) | Full Active Scan |
|---|---|---|
| Speed | ~1-3 minutes | Can take 30+ minutes depending on app size |
| Technique | Passive analysis + light, safe active checks | Aggressive, exhaustive attack payload attempts against every discovered input |
| Risk to target | Very low — safe to run against any environment repeatedly | Can be disruptive (large payloads, many requests) — never run against production |
| Best fit | Every single PR (what we configured) | A scheduled weekly job against a dedicated staging environment only |

A mature pipeline (worth adding as you grow past this series) runs baseline scans on every PR as we did, plus a separate, scheduled full active scan against a long-lived staging environment during low-traffic hours.

### R2. SAST vs. DAST — Concrete Example of What Each Catches

Recall Bug 2 (IDOR) from Part 3 — Semgrep couldn't catch it because nothing was *syntactically* wrong. Could ZAP have caught it? Also **no** — ZAP, as configured here, has no concept of "which order ID belongs to which user" without being taught your specific business logic (this requires an authenticated, business-logic-aware DAST configuration, a more advanced setup than our baseline scan). This is an important, humbling lesson: **no automated tool catches everything.** SAST catches code patterns. DAST catches network-observable behaviors (injection, missing headers, verbose errors). Neither reliably catches authorization logic errors — that remains the job of the abuse cases (Part 1), code review, and the unit tests we wrote in Step 1 specifically to lock in the fixes once a human found them.

### R3. Why We Chose JWT-Session-Compatible Coverage Thresholds Per-File, Not Project-Wide

A single project-wide coverage percentage (e.g., "80% overall") can be dangerously misleading — a project could hit 80% purely by heavily testing simple UI components while leaving `auth-helpers.ts` at 10% coverage, hidden by the average. Per-file thresholds on security-critical modules (as configured in `vitest.config.ts`) close this blind spot directly: `lib/auth-helpers.ts` specifically cannot silently regress, regardless of how well-tested the rest of the app is.

### R4. OIDC Federation — How the Trust Actually Works, Step by Step

1. A GitHub Actions workflow run requests a signed JSON Web Token (JWT) from GitHub's own OIDC token endpoint, automatically, when `id-token: write` permission is granted.
2. This JWT contains claims like `repo:yourusername/securetrade:ref:refs/heads/main` and is signed by GitHub's private key.
3. `aws-actions/configure-aws-credentials` sends this JWT to AWS STS (Security Token Service), requesting to assume the specified role.
4. AWS independently verifies the JWT's signature against GitHub's published public keys (via the OIDC provider registered in Step 7), and separately checks the token's claims against the role's trust policy `Condition` block.
5. If both checks pass, STS issues temporary credentials (an access key, secret key, and session token) valid for a short, configurable duration (default up to 1 hour).
6. These credentials are used for the remaining workflow steps, then simply expire — there is nothing to "revoke" because nothing permanent was ever issued.

### R5. Why Vercel's Token Is a Necessary, Documented Exception

Not every third-party service supports OIDC federation yet — Vercel's deployment/preview-status API, as of this writing, requires a standard bearer token. Rather than pretending this doesn't matter, we handle it with compensating controls, all documented in `docs/CI-CD-PIPELINE.md`: (1) the token is scoped to read-only deployment status wherever the platform allows project-level scoping, (2) it's rotated on a fixed schedule (documented in `SECRETS-POLICY.md` from Part 3), (3) it's stored exclusively as an encrypted GitHub secret, never in code, and (4) TruffleHog/Gitleaks (Step 3) would catch it immediately if it were ever accidentally exposed in logs or committed. This is honest, layered risk management — not every system will support the ideal solution, and pretending otherwise would be worse than transparently documenting the trade-off.

### R6. Sigstore / Cosign — A Preview of Where Supply Chain + CI/CD Security Is Heading

Beyond what we've built, an emerging practice worth knowing about: **artifact signing**. Tools like **Sigstore/Cosign** let a CI pipeline cryptographically sign a build artifact (a Docker image, an SBOM) using the same short-lived OIDC identity concept from this part, so that anyone downloading that artifact later can verify "this genuinely came from SecureTrade's official CI pipeline, on this exact commit, and hasn't been tampered with since" — without any team member managing a traditional signing key at all. This directly extends the "no long-lived credentials" philosophy from authentication into artifact integrity itself, and is a natural next step for a team maturing past this series.

### R7. Required Reviewers vs. CODEOWNERS

Our branch protection requires "1 approving review" from *any* collaborator. A more mature setup uses a `CODEOWNERS` file to require review specifically from the person/team responsible for the changed area — e.g., any change touching `middleware.ts`, `auth.ts`, or anything under `lib/validation/` could require sign-off specifically from a designated "security reviewer," rather than any teammate. Worth adding as a team grows past a single contributor.

---

**Next up: Part 6 — Secure Deployment & Cloud Config**, where we finally close out the WARN-level ZAP findings from this part by implementing real CSP/HSTS security headers, harden Vercel's configuration with a WAF and rate limits, wire up Terraform for infrastructure-as-code, and connect Sentry for production error monitoring.
