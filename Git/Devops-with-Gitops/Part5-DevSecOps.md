# Part 5: DevSecOps & Shift-Left

**Module Goal:** Integrate automated security scanning — static analysis (CodeQL), dependency auditing, and secret scanning — directly into the pull request process, so vulnerabilities are caught before merge, not after deploy.

---

## 1. Concept Explanation

### "Shift-Left" Means Moving the Cost Curve

The cost of fixing a security issue rises exponentially the later it's caught: cheapest as a red squiggly line in an IDE, cheap as a failed PR check, expensive as a production incident, catastrophic as a breach disclosure. Shift-left security means pushing every check as far left (early) in the pipeline as technically possible — ideally blocking the PR itself, before a human reviewer even spends time reading the diff.

### The Three Pillars We'll Automate

1. **Static Application Security Testing (SAST)** — CodeQL, GitHub's free, native semantic code analysis engine. It doesn't just pattern-match strings; it builds a queryable database of your code's data flow to find real vulnerability classes (SQL injection, XSS, path traversal, insecure deserialization).
2. **Dependency Auditing** — your `node_modules` tree is also your attack surface. `npm audit` plus Dependabot catches known CVEs in third-party packages, automatically.
3. **Secret Scanning** — catching hardcoded API keys, tokens, and credentials *before* they land in Git history (where, functionally, they live forever even if you delete the file in a later commit).

---

## 2. Implementation

### Step 1 — CodeQL Analysis

`.github/workflows/security-scan.yml`:

```yaml
name: Security Scan

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: "0 3 * * 1"   # weekly Monday 3am UTC — catches newly disclosed query rules

permissions:
  contents: read
  security-events: write   # required for CodeQL to upload SARIF results
  actions: read

jobs:
  codeql-analysis:
    name: CodeQL Analysis
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        language: ["javascript-typescript"]
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
          queries: security-extended   # broader ruleset than the default

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
        with:
          category: "/language:${{ matrix.language }}"
```

**Design notes:**
- `security-extended` query pack catches more than the default `security-and-quality` set — worth the extra scan time for production apps.
- Results surface natively in the **Security tab** of your repo, and as inline PR annotations on the exact vulnerable line — no third-party dashboard needed.
- The weekly `schedule` trigger matters because CodeQL's query packs are updated independently of your code — a dependency that was "clean" last month might match a newly added query rule today.

### Step 2 — Dependency Auditing (npm audit + Dependabot)

CI-time audit gate, added as a job in the same workflow:

```yaml
  dependency-audit:
    name: Dependency Vulnerability Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
      - run: npm ci

      - name: Run npm audit (fail on high/critical)
        run: npm audit --audit-level=high
```

`dependabot.yml` (config file, not a workflow — lives at `.github/dependabot.yml`) automates *proactive* PRs that bump vulnerable dependencies before you even notice:

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    groups:
      minor-and-patch:
        patterns: ["*"]
        update-types: ["minor", "patch"]

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

**Why the second block matters:** Dependabot also patches your *workflow files themselves* — pinned action versions (`actions/checkout@v4`) get bumped automatically when a new release fixes a vulnerability in the action's own supply chain. This closes a commonly overlooked attack surface: your CI pipeline's own dependencies.

### Step 3 — Secret Scanning

GitHub's native **Secret Scanning** (push protection) is enabled at the repo/org settings level (Settings → Code security → Secret scanning → enable "Push protection"), not via workflow YAML — it intercepts `git push` server-side and rejects pushes containing recognizable credential patterns (AWS keys, GitHub PATs, Slack tokens, etc.) before they ever enter history.

As a defense-in-depth **workflow-level** backstop (useful for public repos, forks, or catching custom secret patterns GitHub's native scanner doesn't recognize), add [Gitleaks](https://github.com/gitleaks/gitleaks) — free and open-source:

```yaml
  secret-scan:
    name: Gitleaks Secret Scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository (full history for scanning)
        uses: actions/checkout@v4
        with:
          fetch-depth: 0   # scan full history, not just the latest commit

      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Step 4 — Making Security a Hard Gate, Not a Suggestion

The single most important architectural decision in this module: security jobs must be added as **required status checks** on the branch protection rule for `main` (Settings → Branches → Branch protection rules → Require status checks to pass before merging → select `codeql-analysis`, `dependency-audit`, `secret-scan`). Without this, a red X is just a suggestion a developer can ignore and merge anyway. With it, GitHub's merge button is *physically disabled* until the checks pass — this is what "shift-left" means in enforced practice, not just in intention.

---

## 3. Exercise Challenge

1. `npm audit --audit-level=high` will still let a PR merge if a *moderate* severity vulnerability exists in a package your app doesn't actually import at runtime (e.g., a devDependency-only tool). Research and implement a refinement using `npm audit --omit=dev` to scope the audit to production dependencies only.
2. Add a step that fails CI if any dependency has a license outside an approved allowlist (a common enterprise compliance requirement) using `license-checker`.
3. Configure the CodeQL job so PR runs only scan *changed* files for faster feedback, while the `push`-to-`main` and scheduled runs do a full scan.

---

## 4. Solution & Explanation

**1 — Production-scoped audit:**

```yaml
      - name: Run npm audit (production dependencies only, fail on high/critical)
        run: npm audit --omit=dev --audit-level=high
```

**Explanation:** `--omit=dev` excludes devDependencies from the audit's dependency graph entirely. A vulnerable version of, say, a test runner or a linter plugin that never ships in your production bundle shouldn't block a merge with the same urgency as a vulnerable runtime dependency — this refinement reduces false-urgency alert fatigue while keeping the gate strict where it actually matters.

**2 — License compliance gate:**

```yaml
  license-audit:
    name: License Compliance Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - run: npm ci
      - name: Check licenses against allowlist
        run: |
          npx license-checker --onlyAllow \
            "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;0BSD" \
            --excludePrivatePackages
```

**Explanation:** `license-checker` exits non-zero if any dependency's declared license isn't in the `--onlyAllow` list, failing the job. This matters because a copyleft license (e.g. AGPL) pulled in transitively by a dependency-of-a-dependency can create real legal exposure for a commercial product — catching it in CI, at PR time, is dramatically cheaper than catching it during a legal audit.

**3 — Diff-scoped CodeQL for faster PR feedback:**

```yaml
  codeql-analysis:
    name: CodeQL Analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2   # need at least the parent commit to diff against

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
          queries: security-extended
          # CodeQL doesn't natively support "changed files only" scanning —
          # instead we gate whether the *job* runs at all based on changed paths.

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
        with:
          category: "/language:javascript-typescript"
```

Combined with a path filter at the workflow trigger level:

```yaml
on:
  pull_request:
    branches: [main]
    paths:
      - "src/**"
      - "package*.json"
```

**Explanation:** CodeQL's analysis engine always builds a whole-project database (it needs full context to trace data flow correctly — true "changed lines only" scanning would produce false negatives by missing cross-file taint paths). The realistic optimization is scoping *whether the job runs at all* via `paths:` filtering at the trigger level — if a PR only touches `README.md`, there's no reason to spin up a multi-minute CodeQL job. This is a subtly important distinction: don't fake partial security scanning to save time; instead, skip the entire scan only when you're certain no scannable code changed.

---

**Next:** Part 6 — GitOps Deployment Strategy (Vercel) →
