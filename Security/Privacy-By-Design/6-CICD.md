# Part 6: Auditing, Monitoring, & Privacy CI/CD

---

## 6.1 The Core Principle: Privacy Guarantees Decay Without Active Enforcement

**Analogy:** Every previous Part built a genuine safety mechanism — encrypted columns, a fail-closed policy engine, an append-only consent ledger, a correctly-sequenced deletion cascade. But a building code doesn't just get written once and forgotten — a city needs *inspectors* who show up at every future construction site, not just the first one, to confirm nobody quietly poured a load-bearing wall in the wrong place while nobody was looking.

Software has an identical failure mode: six months from now, a well-meaning engineer adds a `notes: text` column to some new feature table (not `bytea`), never having read this series. Without automated enforcement, that plaintext column ships to production, gets discovered eighteen months later during a security audit, and every promise this series carefully built is retroactively broken for that one table. **Part 6 builds the automated inspectors** — CI/CD checks that catch these regressions at pull-request time, before they ever reach production, functioning independently of any individual engineer remembering the rules from Parts 1–5.

---

## 6.2 The Target: A PII-Leak Static Scanner in CI

**The Concept:** We write a script that scans every changed file in a pull request for patterns strongly correlated with accidental PII handling mistakes — most importantly, our own specific anti-pattern from this series: a new database column typed as `text`/`varchar` with a name suggesting sensitive content (`note`, `body`, `label`, `email`, `ssn`, etc.) that is *not* wrapped in our `bytea` custom type.

### The Implementation

**Step 1 — The scanner script itself**

**File: `scripts/privacy-scan/scan-schema-for-plaintext-pii.ts`**
```typescript
import { readFileSync } from "node:fs";
import { execSync } from "node:child_process";

/**
 * Column name fragments strongly associated with sensitive content in
 * THIS codebase's domain. This list is deliberately maintained by hand,
 * as a living document — every time this series (or a real team building
 * on it) introduces a new category of sensitive data, this list grows.
 * It is intentionally simple (substring matching) rather than a complex
 * NLP classifier: simple, auditable rules that a human reviewer can
 * read and verify in thirty seconds beat a "smart" system nobody can
 * explain when it produces a false negative.
 */
const SENSITIVE_NAME_FRAGMENTS = [
  "note",
  "body",
  "label",
  "email",
  "ssn",
  "address",
  "phone",
  "medical",
  "diagnosis",
  "password",
];

// Column-definition patterns that are SAFE — already wrapped in our
// custom `bytea` type, or a non-content type like a UUID/timestamp/enum
// that happens to share a name fragment coincidentally (e.g., a column
// literally named `email_verified_at` is a timestamp, not raw content).
const SAFE_TYPE_PATTERNS = [/bytea\(/, /uuid\(/, /timestamp\(/, /boolean\(/, /pgEnum/];

interface Finding {
  file: string;
  lineNumber: number;
  line: string;
}

function getChangedSchemaFiles(): string[] {
  // Compares the current branch against main, restricted to schema files —
  // this scanner intentionally does NOT scan the entire codebase on every
  // run; it scans what's ACTUALLY CHANGING in this pull request, keeping
  // CI runtime fast and focused.
  const output = execSync("git diff --name-only origin/main...HEAD -- '**/schema.ts'", {
    encoding: "utf-8",
  });
  return output.split("\n").filter((line) => line.trim().length > 0);
}

function scanFileForPlaintextPii(filePath: string): Finding[] {
  const findings: Finding[] = [];
  const lines = readFileSync(filePath, "utf-8").split("\n");

  lines.forEach((line, idx) => {
    const lowerLine = line.toLowerCase();

    const matchesSensitiveName = SENSITIVE_NAME_FRAGMENTS.some((fragment) =>
      lowerLine.includes(fragment)
    );
    if (!matchesSensitiveName) return;

    const isDeclaredSafe = SAFE_TYPE_PATTERNS.some((pattern) => pattern.test(line));
    if (isDeclaredSafe) return;

    // Only flag lines that look like an actual column definition (contain
    // a Drizzle column-builder call), to avoid false positives on comments
    // or unrelated code that happens to contain the word "note".
    const looksLikeColumnDefinition = /varchar\(|text\(/.test(line);
    if (!looksLikeColumnDefinition) return;

    findings.push({ file: filePath, lineNumber: idx + 1, line: line.trim() });
  });

  return findings;
}

function main() {
  const changedFiles = getChangedSchemaFiles();

  if (changedFiles.length === 0) {
    console.log("No schema.ts files changed in this PR. Skipping PII scan.");
    return;
  }

  let allFindings: Finding[] = [];
  for (const file of changedFiles) {
    allFindings = allFindings.concat(scanFileForPlaintextPii(file));
  }

  if (allFindings.length > 0) {
    console.error("Potential unencrypted PII column(s) detected:");
    console.error("");
    for (const finding of allFindings) {
      console.error(finding.file + ":" + finding.lineNumber);
      console.error("    " + finding.line);
      console.error("");
    }
    console.error(
      "If this is genuinely non-sensitive, rename the column to avoid the " +
        "flagged fragment, or wrap it in the bytea custom type from " +
        "src/db/schema.ts. This check exists to enforce the Part 2/3 rule " +
        "that sensitive free-text columns must be encrypted, not stored as " +
        "plain text or varchar."
    );
    process.exit(1); // non-zero exit code fails the CI job
  }

  console.log("No unencrypted PII columns detected in changed schema files.");
}

main();
```

**Step 2 — A package.json script entry**

**File: `package.json`** (add to the `"scripts"` section)
```json
{
  "scripts": {
    "privacy:scan-schema": "tsx scripts/privacy-scan/scan-schema-for-plaintext-pii.ts"
  }
}
```

### The Verification (Local, Before Wiring Into CI)

**Step 1 — Confirm it passes on your current, correct schema**
```bash
git checkout -b test-privacy-scan
npm run privacy:scan-schema
```
Expected: `No unencrypted PII columns detected in changed schema files.` — but note this only works meaningfully once compared against a real `main` branch with actual diffs, so for this manual check, temporarily test the function directly:
```bash
npx tsx -e "
import { readFileSync } from 'node:fs';
console.log('Manually verifying schema.ts has no bare text/varchar PII columns...');
const content = readFileSync('src/db/schema.ts', 'utf-8');
console.log(content.includes('noteCiphertext: bytea') ? 'note OK' : 'note FAILED');
console.log(content.includes('bodyCiphertext: bytea') ? 'body OK' : 'body FAILED');
console.log(content.includes('labelCiphertext: bytea') ? 'label OK' : 'label FAILED');
"
```

**Step 2 — Deliberately introduce the exact bug this scanner exists to catch**

```typescript
// TEMPORARILY add this to schema.ts to prove the scanner works:
export const scratchTable = pgTable("scratch_table", {
  id: uuid("id").defaultRandom().primaryKey(),
  medicalNote: varchar("medical_note", { length: 500 }), // intentionally insecure
});
```

```bash
git add src/db/schema.ts
git commit -m "test: intentionally insecure column to verify scanner"
npm run privacy:scan-schema
```
Expected: the script should **fail** (non-zero exit code) and print the exact file, line number, and offending line containing `medicalNote: varchar`. Confirm this, then **revert the change**:
```bash
git reset --hard HEAD~1
```

This deliberate "break it on purpose, confirm the alarm sounds, then fix it" verification step is the single most important test in this entire Part — a scanner that's never been proven to actually catch its target bug is worse than no scanner at all, because it creates false confidence.

---

## 6.3 The Target: Wiring the Scanner into GitHub Actions

**The Concept:** A script sitting in `scripts/` does nothing on its own — it must run automatically on every pull request, blocking merges when it fails, exactly like a building inspector who shows up unannounced at every construction site rather than waiting to be invited.

### The Implementation

**File: `.github/workflows/privacy-ci.yml`**
```yaml
name: Privacy CI Checks

# Runs on every PR targeting main — this is the "inspector visits every
# single construction site" behavior, not an opt-in the author could skip.
on:
  pull_request:
    branches: [main]

jobs:
  privacy-schema-scan:
    name: Scan for unencrypted PII columns
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          # fetch-depth: 0 ensures the full git history is available, since
          # our scanner diffs against origin/main — a shallow checkout
          # would make that diff incomplete or fail outright.
          fetch-depth: 0

      - uses: actions/setup-node@v4
        with:
          node-version: "20"

      - name: Install dependencies
        run: npm ci

      - name: Run PII schema scanner
        run: npm run privacy:scan-schema

  dpia-diff-check:
    name: Verify DPIA updated alongside schema changes
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check DPIA was updated if schema changed
        run: |
          SCHEMA_CHANGED=$(git diff --name-only origin/main...HEAD -- 'src/db/schema.ts' | wc -l)
          DPIA_CHANGED=$(git diff --name-only origin/main...HEAD -- 'docs/dpia/' | wc -l)

          if [ "$SCHEMA_CHANGED" -gt 0 ] && [ "$DPIA_CHANGED" -eq 0 ]; then
            echo "schema.ts was modified in this PR, but no file under docs/dpia/ was updated."
            echo "Per docs/engineering/privacy-defaults.md rule #3, every new personal data column must be justified in the DPIA before merge."
            exit 1
          fi

          echo "DPIA check passed."

  secret-scan:
    name: Scan for leaked secrets
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      # gitleaks is a widely-used, battle-tested open-source secret
      # scanner — rather than writing our own regex-based key detector
      # (which we've already shown the risks of getting subtly wrong in
      # Section 6.2), we lean on a purpose-built, actively-maintained tool
      # for this specific job. This is a deliberate contrast: WE write the
      # domain-specific scanner (our own column-naming conventions), but
      # we DELEGATE generic secret detection (API keys, private keys) to
      # an established tool built exactly for that.
      - name: Run gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### The Verification

**Step 1 — Push a branch and open a real PR against `main`**

```bash
git checkout -b test-ci-pipeline
git commit --allow-empty -m "test: trigger CI pipeline"
git push origin test-ci-pipeline
```
Open a pull request on GitHub. Within a minute, you should see three separate check runs appear: **Scan for unencrypted PII columns**, **Verify DPIA updated alongside schema changes**, and **Scan for leaked secrets** — each with its own pass/fail status directly in the PR UI.

**Step 2 — Prove the DPIA-diff check actually blocks a real PR**

On this same branch, re-introduce the scratch column from Section 6.2 into `schema.ts` **without** touching any file in `docs/dpia/`, then push:
```bash
git add src/db/schema.ts
git commit -m "feat: add scratch column without DPIA update (should fail CI)"
git push origin test-ci-pipeline
```
Confirm on GitHub that **both** the PII scanner and the DPIA-diff check now show a red ✗, and — if your repository has branch protection rules enabled requiring these checks — that the PR's merge button is disabled. Then fix it properly:
```bash
git reset --hard HEAD~2  # remove both test commits
git push origin test-ci-pipeline --force
```

---

## 6.4 The Target: A PII-Redacting Logger

**The Concept:** Even with a perfect database encryption layer, a single careless `console.log(user)` or an overly verbose error-tracking integration (Sentry, Datadog) can leak decrypted plaintext into a *completely different* storage system — one that was never designed with the same encryption, retention, or access-control guarantees as your primary database. Recall Part 1's DPIA Risk table: "PII leaks into application logs or error trackers" was flagged as **High likelihood** — this is not a theoretical risk, it's one of the most common real-world causes of data exposure.

### The Implementation

**File: `src/lib/logging/redact.ts`**
```typescript
/**
 * Field names that must NEVER appear unredacted in any log line, error
 * report, or trace span — regardless of which part of the codebase is
 * doing the logging. This list intentionally mirrors the DPIA's Data
 * Inventory table (Part 1) — every category of personal/special-category
 * data we identified there gets a corresponding redaction rule here.
 */
const SENSITIVE_KEYS = [
  "email",
  "note",
  "body",
  "label",
  "clerkUserId",
  "ipHash",
  "password",
  "authorization",
  "cookie",
];

const REDACTED_VALUE = "[REDACTED]";

/**
 * Recursively walks an arbitrary object (e.g., a caught error, a request
 * payload, a database row someone accidentally passed to console.log)
 * and replaces any value whose KEY matches our sensitive list, regardless
 * of nesting depth. This is intentionally conservative: it's far better
 * to over-redact a field that turns out to be harmless than to under-
 * redact one that turns out to be a diary entry.
 */
export function redactSensitiveData(input: unknown, depth = 0): unknown {
  if (depth > 10) return "[MAX_DEPTH_EXCEEDED]"; // guards against circular refs / huge objects

  if (input === null || input === undefined) return input;

  if (Array.isArray(input)) {
    return input.map((item) => redactSensitiveData(item, depth + 1));
  }

  if (input instanceof Buffer) {
    // Ciphertext buffers are already safe, but we still redact their
    // display to avoid printing large blobs of binary noise into logs.
    return `[BUFFER:${input.length}bytes]`;
  }

  if (typeof input === "object") {
    const result: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(input as Record<string, unknown>)) {
      const isSensitive = SENSITIVE_KEYS.some((sensitiveKey) =>
        key.toLowerCase().includes(sensitiveKey.toLowerCase())
      );
      result[key] = isSensitive
        ? REDACTED_VALUE
        : redactSensitiveData(value, depth + 1);
    }
    return result;
  }

  return input;
}

/**
 * A drop-in replacement for console.log/error that ALWAYS redacts before
 * printing. Every logging call site in the application should

It does **not** guarantee that every possible privacy failure is caught — a fundamentally new *kind* of mistake, one that doesn't match any pattern we've thought to encode, will sail through CI with a clean green checkmark. This is precisely why Section 6.6's recurring human audit checklist exists alongside the automation, not instead of it. The correct mental model is a layered defense: automated checks catch the *known, recurring* failure modes cheaply and instantly on every single PR; scheduled human review catches the *novel, contextual* failure modes that no script could reasonably be expected to encode. Treat a fully green CI pipeline as necessary, never sufficient, evidence that your privacy posture is sound.

### Reference 6.D — Extending This Pipeline Beyond MindfulLog

Every pattern built in this Part generalizes directly to any codebase, regardless of domain:
1. **Identify your own domain's sensitive-name fragments** (Section 6.2's `SENSITIVE_NAME_FRAGMENTS` list) — for an e-commerce app this might be `cardNumber`, `cvv`, `shippingAddress` instead of `note`/`body`/`label`.
2. **Wire the DPIA-diff check to whatever document your organization uses** for data inventory — it doesn't need to be exactly our Markdown file format, only structurally present and diffable.
3. **Reuse `gitleaks` (or an equivalent) unmodified** — secret-scanning is domain-agnostic by nature.
4. **Reuse the redaction-key list pattern in `safeLogger`**, expanding `SENSITIVE_KEYS` to match your own schema's column names.

Nothing in this Part is MindfulLog-specific in its *mechanism* — only the specific lists of names and column types are.

---

## Part 6 — Summary & What Carries Forward

By completing Part 6, your repository now contains:

- ✅ `scripts/privacy-scan/scan-schema-for-plaintext-pii.ts` — a custom, PR-diff-scoped scanner catching unencrypted sensitive columns, verified against a deliberately-introduced bug
- ✅ `.github/workflows/privacy-ci.yml` — three automated CI jobs (PII schema scan, DPIA-diff enforcement, secret scanning) blocking merges on failure
- ✅ `src/lib/logging/redact.ts` — a fully tested, recursive PII-redacting logger (`safeLogger`), now used throughout the application's error-handling paths
- ✅ An ESLint rule structurally preventing raw `console.*` calls, enforced both locally and in CI
- ✅ `docs/engineering/privacy-audit-checklist.md` — a recurring, human-owned audit process explicitly scoped to catch what automation cannot

**This closes the full arc of the series.** Every artifact built across all six parts now forms a single, coherent, continuously self-defending system:

| Part | Core Artifact | Enforced By Part 6 |
|---|---|---|
| 1 | DPIA & data-flow map | DPIA-diff CI check |
| 2 | Minimized, `bytea`-typed schema | PII schema scanner |
| 3 | Envelope encryption + RBAC/ABAC | PII schema scanner + policy code review discipline |
| 4 | Append-only consent ledger | Consent-default review in the audit checklist |
| 5 | DSAR export + deletion cascade | Manual end-to-end audit checklist items |
| 6 | This Part itself | The recurring quarterly audit, auditing the auditors |

---

# Series Closing: What You've Built

```
[COMPLETED: Part 6 — Auditing, Monitoring, & Privacy CI/CD]
[COMPLETED: Privacy by Design: Engineering the Default — Full Series]
```

Across six parts, you took MindfulLog from a blank repository to a system where:

- Every sensitive field is **structurally incapable** of being stored as plaintext (Part 2's type system + Part 3's encryption).
- Every cross-user data access **fails closed by default** and requires an explicit, testable policy rule to succeed (Part 3).
- Every consent decision is **permanently auditable** and propagates automatically to every downstream system that needs to know (Part 4).
- A user can retrieve **everything** the system knows about them, or have it **permanently and correctly erased across every system, including a third-party vendor**, both through fully automated, durable pipelines (Part 5).
- The entire system **actively defends its own guarantees** against future regression, on every single pull request, without relying on any individual engineer's memory (Part 6).

This is what "Privacy by Design" means as an engineering discipline rather than a compliance slogan: not a checklist bolted onto a finished product, but an architecture where the *safe* behavior is the *only* behavior the code allows — verified, tested, and continuously re-verified, one deliberate decision at a time, starting from the very first line.
