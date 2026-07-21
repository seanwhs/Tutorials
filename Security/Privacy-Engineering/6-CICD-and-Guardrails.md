# Part 6: CI/CD & Guardrails

## 6.0 Where we are on the map

Every privacy control built across this series so far — the `ConsentCategory` enum and `CHECK` constraints (Part 2) [4], field-level encryption and RBAC/ABAC (Part 3) [3], the append-only consent ledger (Part 4), and the DSAR workflows (Part 5) — depends on one fragile assumption: that every future developer remembers to follow the pattern correctly. A rushed feature branch, a late-night hotfix, or a well-meaning new teammate unfamiliar with this codebase's conventions could add a new sensitive column as a plain `String` instead of a `*Ciphertext` field, and nothing today would stop it from merging.

Part 6 closes that gap by moving enforcement out of "hope everyone remembers" and into the CI/CD pipeline — the automated checks that run on every pull request, before code ever reaches production. This is the final piece named across the DPIA's own risk table: "a future developer adds a new sensitive column without encrypting it," mitigated by "a CI/CD guardrail... that statically scans migrations and fails the build if a sensitive-looking column lacks encryption" [1][5].

By the end of Part 6 you will have:
1. A standalone Node.js script that statically scans `prisma/schema.prisma` for sensitive-looking column names lacking a `Ciphertext` suffix or an explicit allow-list exemption.
2. A GitHub Actions workflow running that script, the test suite (Parts 2–3), and linting on every pull request.
3. A deliberate, verified failure case — proving the guardrail actually blocks a bad change, not just a hypothetical one.

---

## Step 6.1 — The static schema scanner

### The Target
`scripts/scan-schema-for-unencrypted-fields.mjs` — a script that parses the Prisma schema and fails with a nonzero exit code if it finds a suspicious column.

### The Concept
Think of this the way an airport scans checked luggage: not by asking every passenger to promise nothing dangerous is inside, but by mechanically inspecting every single bag against a known list of risk patterns, every time, without exception or fatigue. Our scanner does the same thing to the schema file: it doesn't trust a code reviewer to notice a suspicious field name in a 200-line diff at 6pm on a Friday — it greps for it, every time, automatically.

We define "sensitive-looking" as a column name containing any of a short list of risk keywords (`note`, `body`, `medication`, `diagnosis`, `journal`) that is **not** already suffixed `Ciphertext` and **not** explicitly listed in a small, reviewed exemption list — mirroring the same "closed list, deliberately extended" philosophy as the `ConsentCategory` enum from Part 2 [4].

### The Implementation

**File: `scripts/scan-schema-for-unencrypted-fields.mjs`**

```javascript
// scripts/scan-schema-for-unencrypted-fields.mjs
//
// Static guardrail: fails the build if a new column looks sensitive but
// isn't named with the *Ciphertext convention this project relies on to
// signal "this must be encrypted before it's queried directly." This is
// the CI-side enforcement of the DPIA's own risk mitigation for
// "a future developer adds a new sensitive column without encrypting it."

import { readFileSync } from "fs";

const SCHEMA_PATH = "prisma/schema.prisma";

// Keywords that, if found in a field name, suggest the field likely
// holds sensitive free text. Kept short and specific deliberately —
// broadening this list is a reviewed, deliberate PR, same as adding a
// new ConsentCategory enum value.
const RISK_KEYWORDS = ["note", "body", "medication", "diagnosis", "journal", "symptom"];

// Fields explicitly reviewed and confirmed safe despite matching a risk
// keyword — e.g., reminderHour/reminderMinute are just numbers, not
// free text, so they don't need encryption despite living on the
// medication_reminders table.
const EXEMPT_FIELDS = new Set(["reminderHour", "reminderMinute"]);

const schemaText = readFileSync(SCHEMA_PATH, "utf8");

// A simple field-line matcher: "  fieldName   Type" inside a model block.
const fieldLinePattern = /^\s{2}(\w+)\s+(\w+\??)/gm;

const violations = [];
let match;
while ((match = fieldLinePattern.exec(schemaText)) !== null) {
  const [, fieldName] = match;

  if (EXEMPT_FIELDS.has(fieldName)) continue;
  if (fieldName.endsWith("Ciphertext")) continue; // already correctly encrypted

  const looksRisky = RISK_KEYWORDS.some((keyword) =>
    fieldName.toLowerCase().includes(keyword),
  );

  if (looksRisky) {
    violations.push(fieldName);
  }
}

if (violations.length > 0) {
  console.error("❌ Potential unencrypted sensitive field(s) detected:\n");
  violations.forEach((v) => console.error(`   - ${v}`));
  console.error(
    "\nIf this field genuinely holds sensitive text, rename it with a " +
      "'Ciphertext' suffix and encrypt it via src/lib/encryption.ts before " +
      "writing to it. If it is a reviewed false positive, add it to " +
      "EXEMPT_FIELDS in this script with a comment explaining why.",
  );
  process.exit(1);
}

console.log("✅ No unencrypted sensitive fields detected.");
process.exit(0);
```

### The Verification

Run it against the current, correct schema:

```bash
node scripts/scan-schema-for-unencrypted-fields.mjs
```

Expect:

```
✅ No unencrypted sensitive fields detected.
```

Now prove it actually catches a real violation. Temporarily add a bad field to `prisma/schema.prisma`:

```prisma
model JournalEntry {
  # ...existing fields...
  moodNote String  # deliberately added WITHOUT the Ciphertext suffix
}
```

Re-run the script:

```bash
node scripts/scan-schema-for-unencrypted-fields.mjs
```

Expect a nonzero exit and:

```
❌ Potential unencrypted sensitive field(s) detected:

   - moodNote
```

Revert the temporary bad field before continuing:

```bash
git checkout prisma/schema.prisma
```

Commit the scanner itself:

```bash
git add -A
git commit -m "feat: add static CI scanner detecting unencrypted sensitive schema fields"
```

---

## Step 6.2 — Wiring it into GitHub Actions

### The Target
`.github/workflows/ci.yml` — a workflow running the schema scanner, the test suite, and linting on every pull request.

### The Concept
A guardrail sitting only on your local machine is a guardrail anyone can simply skip by not running it. **CI (Continuous Integration)** means these checks run automatically, on a neutral server, every single time code is proposed for merging — nobody can "forget" to run it, because it isn't optional. This is the mechanism that finally closes the loop between the DPIA's written policy and code that mechanically enforces it, exactly as promised back in Part 0's architecture overview [2].

### The Implementation

**File: `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  guardrails:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: greymatter
          POSTGRES_PASSWORD: ci_password
          POSTGRES_DB: greymatter_ci
        ports: ["5432:5432"]
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      # This is the guardrail step named in our DPIA: it fails the
      # entire pipeline — blocking the merge — the moment a sensitive
      # column lacks encryption, regardless of who wrote it or how
      # rushed the PR was.
      - name: Scan schema for unencrypted sensitive fields
        run: node scripts/scan-schema-for-unencrypted-fields.mjs

      - name: Generate Prisma client
        run: npx prisma generate

      - name: Run migrations against CI database
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: postgresql://greymatter:ci_password@localhost:5432/greymatter_ci

      - name: Run test suite
        run: npm test
        env:
          FIELD_ENCRYPTION_KEY: ${{ secrets.CI_FIELD_ENCRYPTION_KEY }}
```

### The Verification

Push this file to a branch and open a pull request against `main`. Confirm the **Checks** tab shows the `guardrails` job running each step in order, ending in green. Then, as a deliberate negative test, push a second commit re-adding the unencrypted `moodNote` field from Step 6.1's test, and confirm the pull request now shows a **red ❌** on the "Scan schema for unencrypted sensitive fields" step, with the merge button blocked or clearly flagged as failing — proof the guardrail runs in a context no individual developer controls. Revert the bad field and confirm the check turns green again.

Commit:

```bash
git add -A
git commit -m "ci: add GitHub Actions pipeline running lint, schema guardrail, and tests on every PR"
```

## Part 6 Reference Section: Why a Static Scan, Not Just Code Review *(continued)*

A static scan and a human code reviewer both try to catch the same mistake, but they fail differently. A reviewer gets tired at the end of a long day, gets rushed by a deadline, or simply reviews a 40-file pull request where one new column, buried in a migration file, doesn't stand out. A reviewer's attention is finite and inconsistent — precisely the failure mode the DPIA's own risk table names: "a future developer adds a new sensitive column without encrypting it" is flagged as **medium likelihood**, specifically because "this is the single most common way real-world privacy incidents happen — an innocent, rushed schema change."

A static scan, by contrast, has no bad days. It runs identically on the 1st pull request of the project and the 10,000th, with the same keyword list, the same exemption list, and the same exit code logic every time. It doesn't replace human review — a reviewer can still catch things a keyword list can't (e.g., a column named `userFeedback` that turns out to contain sensitive free text, which wouldn't trip any of our current risk keywords) — but it guarantees a *minimum floor* of protection that never depends on any individual person's alertness that day. This is the same "belt and suspenders" philosophy already established with database `CHECK` constraints backing up application-layer validation [3][4]: human judgment for nuance, mechanical enforcement for the baseline that must never slip.
