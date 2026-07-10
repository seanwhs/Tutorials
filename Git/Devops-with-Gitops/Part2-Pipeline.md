# Part 2: Advanced Pipeline Logic

**Module Goal:** Master caching strategy, matrix builds across Node versions/OS, and workflow composition through reusable workflows and composite actions.

---

## 1. Concept Explanation

### Why Composition Matters at Scale

A single `ci-test.yml` is fine for one repo. A Principal Engineer thinks in terms of an *organization* with 30 repos, all needing the same "checkout, setup Node, install, lint, test" sequence. Copy-pasting that YAML 30 times is a maintenance nightmare — one security patch to `actions/checkout` means editing 30 files. GitHub Actions solves this with two composition primitives:

- **Composite Actions** — package a sequence of steps into a single reusable "action" (like a function). Lives in `.github/actions/name/action.yml`. Called with `uses: ./.github/actions/name`.
- **Reusable Workflows** — package an entire *workflow* (multiple jobs) that other workflows can call with `uses: ./.github/workflows/name.yml` and `with:` inputs. This is the more powerful primitive — think of it as "workflow as a function," including secrets passing.

### Matrix Strategy

A **matrix** runs the same job multiple times with different variable combinations — e.g., testing against Node 18, 20, and 22, on both Ubuntu and Windows, all in parallel, all from one job definition.

### Caching, Precisely

Caching in Actions is keyed. You give it a `key` (usually a hash of your lockfile) and a `path`. On cache hit, Actions restores the directory before your steps run. Get the key wrong (too broad = stale deps; too narrow = no cache ever hits) and you either ship broken builds or waste minutes reinstalling dependencies every run.

---

## 2. Implementation

### Step 1 — Matrix Testing Across Node Versions and OS

`.github/workflows/ci-matrix.yml`:

```yaml
name: CI - Matrix Test

on:
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  test-matrix:
    name: Test (Node ${{ matrix.node-version }} on ${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest]
        node-version: ["18", "20", "22"]
        exclude:
          - os: windows-latest
            node-version: "18"
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test
```

**Design notes:**
- `fail-fast: false` — without this, the *first* failing matrix combination cancels all others. You want to see every failing (OS, Node version) pair in one run, not fix-and-rerun five times.
- `exclude:` prunes combinations you don't support (e.g., dropping Node 18 support on Windows runners specifically). You can also use `include:` to add one-off extra combinations not covered by the cartesian product.
- This spins up **5 parallel jobs** (2 OS × 3 Node versions, minus 1 excluded) from ~15 lines of YAML.

### Step 2 — Precision Caching (Beyond setup-node's built-in cache)

For more control (e.g., caching build output, not just `node_modules`), use `actions/cache` directly:

```yaml
      - name: Cache Next.js build cache
        uses: actions/cache@v4
        with:
          path: |
            ~/.npm
            .next/cache
          key: ${{ runner.os }}-nextjs-${{ hashFiles('**/package-lock.json') }}-${{ hashFiles('**/*.js', '**/*.jsx', '**/*.ts', '**/*.tsx') }}
          restore-keys: |
            ${{ runner.os }}-nextjs-${{ hashFiles('**/package-lock.json') }}-
```

`restore-keys` is a fallback list — if the exact key misses (because source files changed), it falls back to the most recent cache matching the prefix, giving you a *partial* cache hit (deps cached, build cache stale-but-present) instead of a full cold start.

### Step 3 — A Reusable Workflow

Extract "setup + install + lint + typecheck" into a callable reusable workflow.

`.github/workflows/reusable-node-setup.yml`:

```yaml
name: Reusable - Node Setup and Lint

on:
  workflow_call:
    inputs:
      node-version:
        required: false
        type: string
        default: "20"
    secrets:
      NPM_TOKEN:
        required: false

jobs:
  setup-and-lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: "npm"

      - name: Install dependencies
        run: npm ci
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npm run typecheck
```

Calling it from another workflow:

`.github/workflows/ci-test.yml` (revised to call the reusable workflow):

```yaml
name: CI - Test Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  quality-gate:
    uses: ./.github/workflows/reusable-node-setup.yml
    with:
      node-version: "20"
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}

  unit-tests:
    needs: quality-gate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
      - run: npm ci
      - run: npm test
```

### Step 4 — A Composite Action (for smaller, in-repo step bundles)

`.github/actions/setup-project/action.yml`:

```yaml
name: "Setup Project"
description: "Checkout, install Node, and install dependencies"
inputs:
  node-version:
    description: "Node.js version"
    required: false
    default: "20"
runs:
  using: "composite"
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: "npm"
    - run: npm ci
      shell: bash
```

Usage inside any job:

```yaml
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-project
        with:
          node-version: "20"
```

**Composite Action vs. Reusable Workflow — when to use which:**

| | Composite Action | Reusable Workflow |
|---|---|---|
| Scope | A handful of steps | One or more full jobs |
| Can define `runs-on`? | No — inherits caller's runner | Yes — controls its own runner |
| Can use secrets directly? | Only what's passed via `with:` | Full `secrets:` block support |
| Best for | Small, shared step sequences (setup, teardown) | Entire reusable pipelines (e.g., "the standard test suite") |

---

## 3. Exercise Challenge

1. Modify `ci-matrix.yml` so that only the `ubuntu-latest` + Node `20` combination uploads a coverage artifact (the other matrix legs are for compatibility testing only, and uploading 5 redundant coverage reports wastes storage).
2. Convert the coverage-upload logic into a reusable workflow that takes the artifact name as an input.
3. Add a matrix `include` entry that adds a one-off `node-version: "22"` + `os: macos-latest` leg, without expanding the full cartesian product to include all Node versions on macOS.

---

## 4. Solution & Explanation

**1 & 3 — Conditional artifact upload + surgical matrix include:**

```yaml
jobs:
  test-matrix:
    name: Test (Node ${{ matrix.node-version }} on ${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest]
        node-version: ["18", "20", "22"]
        exclude:
          - os: windows-latest
            node-version: "18"
        include:
          - os: macos-latest
            node-version: "22"
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: "npm"
      - run: npm ci
      - run: npm test -- --coverage

      - name: Upload coverage (canonical leg only)
        if: matrix.os == 'ubuntu-latest' && matrix.node-version == '20'
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/
```

`include` adds `{os: macos-latest, node-version: "22"}` as a single explicit extra combination — it does *not* cross macOS against 18/20 as well, because `include` entries that introduce a new value for an existing matrix key are added as one-off legs, not merged into the cartesian product.

**2 — Reusable workflow for artifact upload:**

`.github/workflows/reusable-upload-coverage.yml`:

```yaml
name: Reusable - Upload Coverage

on:
  workflow_call:
    inputs:
      artifact-name:
        required: true
        type: string
      artifact-path:
        required: false
        type: string
        default: coverage/

jobs:
  upload:
    runs-on: ubuntu-latest
    steps:
      - name: Download coverage from calling job context
        uses: actions/download-artifact@v4
        with:
          name: ${{ inputs.artifact-name }}
          path: ${{ inputs.artifact-path }}
      - name: Re-upload with retention policy
        uses: actions/upload-artifact@v4
        with:
          name: ${{ inputs.artifact-name }}
          path: ${{ inputs.artifact-path }}
          retention-days: 30
```

**Explanation:** Reusable workflows can't directly "reach into" a sibling job's filesystem — artifacts are the transport mechanism between jobs (and between calling/called workflows). This solution treats the reusable workflow as a post-processing stage: the calling job uploads first, this reusable workflow downloads-then-re-uploads with a standardized retention policy, centralizing that policy in one file instead of repeating `retention-days: 30` across every workflow in the org.

---

**Next:** Part 3 — Containerization & Registry (Docker builds + GHCR) →
