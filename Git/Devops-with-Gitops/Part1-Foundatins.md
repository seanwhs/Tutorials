# Part 1: The CI/CD Foundations

**Module Goal:** Understand the architecture of GitHub Actions and ship your first automated test pipeline.

---

## 1. Concept Explanation

### The Core Vocabulary

GitHub Actions has four nested concepts. Get this hierarchy wrong and every YAML file you write afterward will fight you.

- **Workflow** — a YAML file in `.github/workflows/`. One repo can have many workflows. Each is triggered independently by events (push, pull_request, schedule, manual dispatch, etc).
- **Job** — a unit of work inside a workflow. Jobs run in **parallel by default**, on their own fresh virtual machine (runner). You opt into sequencing with `needs:`.
- **Step** — a single command or action inside a job. Steps in the same job run **sequentially**, on the **same runner**, sharing filesystem state.
- **Runner** — the actual VM (or container) that executes the job. GitHub provides free-tier hosted runners (`ubuntu-latest`, `windows-latest`, `macos-latest`); Part 8 covers self-hosted alternatives.

Mental model: **Workflow = a recipe file. Job = an appliance. Step = one action at that appliance.** Two jobs in the same workflow are two separate appliances (VMs) — they don't share memory or disk unless you explicitly pass data via `artifacts` or `outputs`.

### Why the Pipeline is "Living Documentation"

A README can lie. A workflow file cannot — it is the literal, executed truth of what happens between "developer pushes code" and "code runs in production." When a new engineer joins the team and asks "how do we deploy?", the answer is never a wiki page that's six months stale. The answer is: `cat .github/workflows/deploy-vercel.yml`. This is the foundational principle of GitOps, and it starts here, in Part 1, with the humble test workflow.

### Anatomy of a Trigger

Every workflow starts with `on:`, which declares what causes it to run:

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:   # adds a manual "Run workflow" button in the UI
```

`push` + `pull_request` together is the classic CI combo: run checks on every PR *and* re-run them when merged to `main` (belt and suspenders — a PR could be merged via a method that bypasses the PR check, e.g. a direct push by an admin).

---

## 2. Implementation: Your First Automated Test Pipeline

We'll build a CI pipeline for a Node.js/Next.js app that lints, type-checks, and runs unit tests on every push and pull request.

### Step 1 — Repository Assumptions

```
my-app/
├── .github/
│   └── workflows/
│       └── ci-test.yml
├── src/
├── tests/
├── package.json
├── tsconfig.json
└── .eslintrc.json
```

`package.json` should expose the scripts our pipeline will call:

```json
{
  "scripts": {
    "lint": "eslint . --max-warnings=0",
    "typecheck": "tsc --noEmit",
    "test": "vitest run --coverage"
  }
}
```

### Step 2 — The Workflow File

`.github/workflows/ci-test.yml`:

```yaml
name: CI - Test Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch: {}

# Cancel superseded runs on the same branch/PR to save minutes
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint-and-typecheck:
    name: Lint & Type Check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Run TypeScript compiler check
        run: npm run typecheck

  unit-tests:
    name: Unit Tests
    runs-on: ubuntu-latest
    needs: lint-and-typecheck   # only run tests if static checks pass — fail fast
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Run test suite
        run: npm test

      - name: Upload coverage report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/
          retention-days: 14
```

### Step 3 — Dissecting the Design Decisions (Principal Engineer Notes)

1. **`concurrency` block** — without this, every `git push --amend` + force-push to the same PR spawns a *new* full pipeline run while the old one is still running, burning minutes on stale commits. `cancel-in-progress: true` kills the outdated run automatically.

2. **`permissions: contents: read`** — the principle of least privilege. By default, the `GITHUB_TOKEN` used internally by Actions gets broad permissions. We explicitly scope it down at the workflow level and only elevate it (e.g., `pull-requests: write`) on jobs that actually need it. We'll do this again in Part 5 and Part 7.

3. **`needs: lint-and-typecheck`** — this creates a dependency graph. `unit-tests` will not even provision a runner until `lint-and-typecheck` succeeds. This is "fail fast": don't spend 3 minutes running a test suite if there's an obvious lint error.

4. **`cache: "npm"` in `setup-node`** — caches `~/.npm` keyed by your lockfile hash. First run: slow. Every run after: `npm ci` drops from ~40s to ~5s. We go much deeper on caching strategy in Part 2.

5. **`actions/checkout@v4` on every job** — remember, jobs run on isolated VMs. `lint-and-typecheck` checking out the repo does **not** mean `unit-tests` has the repo. Every job starts from zero and must explicitly `checkout` again.

6. **`if: always()` on the artifact upload** — ensures coverage reports upload even if tests fail, so you can inspect *why* directly in the Actions UI without re-running locally.

### Step 4 — Reading Pipeline Results

Once pushed, navigate to the **Actions** tab of your repo. You'll see:
- A run per push/PR event.
- Two jobs (`Lint & Type Check`, `Unit Tests`) rendered as nodes in a dependency graph.
- Green check ✅ or red X ❌ surfaced directly on the PR itself, next to the commit SHA — this is the **Status Check** that Part 7 builds on.

---

## 3. Exercise Challenge

Extend `ci-test.yml` so that:

1. A third job, `build`, runs `npm run build` — but only after **both** `lint-and-typecheck` AND `unit-tests` succeed.
2. The `build` job should skip entirely (not even queue) on `workflow_dispatch` manual runs — it should only run for `push`/`pull_request` events.
3. Add a step that fails the whole job gracefully with a clear error message if `package-lock.json` is missing (a common "works on my machine" bug when someone deletes the lockfile).

---

## 4. Solution & Explanation

```yaml
  build:
    name: Build Application
    runs-on: ubuntu-latest
    needs: [lint-and-typecheck, unit-tests]
    if: github.event_name != 'workflow_dispatch'
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Verify lockfile exists
        run: |
          if [ ! -f package-lock.json ]; then
            echo "::error::package-lock.json is missing. Commit your lockfile to guarantee reproducible installs."
            exit 1
          fi

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build
```

**Explanation:**

- `needs: [lint-and-typecheck, unit-tests]` (an array) means *both* upstream jobs must succeed — not just one. This is an AND relationship by default in Actions.
- `if: github.event_name != 'workflow_dispatch'` is evaluated by the Actions runner **before** provisioning the VM for that job — this is why the job "skips" (shown as a grey dash, not a failure) rather than running and doing nothing. This distinction matters for minute-billing: a skipped job costs zero minutes.
- The lockfile check uses `::error::` — a special GitHub Actions **workflow command** that pins the message to the specific line in the Actions UI's annotation panel, rather than burying it in raw log text. This is a small but very "principal engineer" touch: make failures instantly diagnosable without scrolling logs.
- `exit 1` is what actually fails the step (and cascades to fail the job). A `run:` step's exit code *is* its pass/fail signal — this is worth internalizing early since every future part relies on this same mechanic (scanners, linters, and deployment scripts all communicate success/failure purely through process exit codes).

---

**Next:** Part 2 — Advanced Pipeline Logic (caching, matrix builds, reusable workflows) →
