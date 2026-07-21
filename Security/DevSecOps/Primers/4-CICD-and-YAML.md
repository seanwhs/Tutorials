# Primer 4: CI/CD & YAML Mental Models

**Feeds into:** Phase 2 (the first `security.yml` workflow), Phase 3 (adding IaC & secret jobs), Phase 4 (the build/scan/sign/deploy pipeline), and Phase 5 (the scheduled compliance report).
**You'll be ready when:** you can open any workflow file in this series, point to where it triggers, what jobs run, in what order, and where the *security gate* is.

**Prerequisite primers:** none strictly, though this is where all the scanners from the other primers get *automated*, so it ties them together.

---

## Why this matters

Here's the thing that separates a *nice idea* from a *real security program*: **automation and enforcement.** In Primers 1–3 you learned about validating input, hashing passwords, and scanning images. But if running those scanners depends on a human *remembering* to do it — someone will forget, someone will be rushed, someone will skip it "just this once." Security that relies on human discipline eventually fails.

CI/CD is the machine that runs all of it *automatically, every single time*, and — crucially — can **block bad code from ever advancing.** It's the difference between "we have a security scanner" and "no vulnerable code can reach production." Nearly every guardrail in Phases 2–5 lives inside a CI pipeline. So before you can read those phases, you need to read the pipeline.

Two of our foundational principles depend entirely on this:
- **Central enforcement** — CI is the un-skippable checkpoint (unlike a local pre-commit hook, which a developer can bypass with `--no-verify`).
- **Defense in depth** — the *same* checks run locally *and* in CI, so a slip at one layer is caught at the next.

Let's demystify both halves: first the *concept* (CI/CD), then the *language* it's written in (YAML).

---

## Part A: What CI/CD actually means

The acronym scares people. It's two simple ideas:

> **Definition — CI (Continuous Integration):** Automatically running your checks — tests, scans, builds — *every time* code is pushed, so problems are caught immediately instead of piling up.
>
> **Definition — CD (Continuous Delivery/Deployment):** Automatically taking code that *passed* those checks and moving it toward (or all the way into) production.

### CI: the always-on quality inspector

> **The factory-conveyor-belt analogy:** Picture a factory assembly line. Every product coming off the belt passes through an automated inspection station — it checks the weld, the paint, the dimensions. A product that fails is *pulled off the line* before it can be boxed and shipped. The inspector never gets tired, never takes a lunch break, never "lets one slide because it's Friday."
>
> **CI is that inspection station for your code.** Every push runs through the checks. Code that fails gets pulled off the line (the pipeline goes red) before it can advance.

The magic word here is **"continuous."** Not "before release." Not "once a sprint." *Every single push.* This is the automated embodiment of "shift left" from Phase 1 — catching problems the instant they're introduced, when they're cheapest to fix (Primer... well, the whole series' thesis).

### CD: the automated shipping department

Once CI says "this passed all inspections," CD handles getting it to users. In our series, Phase 4's `release.yml` is CD: it builds the image, scans it, signs it, and deploys it to staging — but *only* for code that already passed CI. CD without CI is just "shipping untested code faster," which is worse. They work as a pair: **CI proves it's good; CD ships the good thing.**

### The most important concept: the gate

Everything above is nice, but here's the part that makes CI/CD a *security* tool rather than just a convenience:

> **Definition — Gate:** A required check that *blocks progress* if it fails. A red gate stops the merge, stops the deploy, stops the pipeline.

> **The turnstile analogy:** A suggestion is a sign that says "please have your ticket ready." A *gate* is a physical turnstile that won't rotate until you scan a valid ticket. You can ignore a sign; you cannot walk through a locked turnstile.
>
> Our Phase 2 branch protection makes the security scans into turnstiles: the "Merge" button is *physically disabled* until SAST, SCA, and the build all pass green. Even a repo admin can't force it. That's what turns scanners from *advice* into *policy*.

This is the whole point. A scanner that merely *warns* gets ignored. A scanner wired to a *gate* gets *fixed*, because the code literally cannot proceed until it's clean.

---

## Part B: Where it runs — GitHub Actions

CI/CD needs a machine to run on. There are many CI systems (Jenkins, GitLab CI, CircleCI); we use **GitHub Actions** because it's built into GitHub, free for our needs, and configured with simple files right in the repo.

> **Definition — GitHub Actions:** GitHub's built-in CI/CD system. You describe your pipeline in YAML files placed in the special folder `.github/workflows/`, and GitHub automatically runs them on the events you specify (a push, a pull request, a schedule).

Two things to internalize:

1. **It's triggered by events.** You don't run it manually (usually) — it fires *automatically* when something happens: you push code, you open a pull request, or a scheduled time arrives. This is what makes it "continuous."

2. **It runs on a fresh, disposable machine.** Each run spins up a brand-new, clean virtual machine (a "runner"), does its work, and throws the machine away. This is a *security feature*: no leftover state from previous runs, no contamination, a clean-room every time. It's also why every workflow has to *install its own tools* — the machine starts empty.

> **The temp-worker analogy:** Each CI run is like hiring a brand-new temp worker who's never seen your project. You hand them a checklist (the YAML), they show up to an empty desk (the fresh runner), follow the checklist step by step, report the result, and then leave forever. Next run = a different temp, another empty desk. That's why the checklist must be *complete and self-contained* — "check out the code, install Node, install deps, run the scan" — because the worker knows nothing and keeps nothing.

---

## Part C: The language — YAML, gently

CI pipelines are written in **YAML**, and for many beginners the format itself is a bigger obstacle than the concepts. Let's remove that obstacle completely.

> **Definition — YAML (YAML Ain't Markup Language):** A human-friendly text format for configuration, built entirely around **key-value pairs** and **indentation**. If you understand "a label, then a value" and "indentation shows what belongs to what," you understand YAML.

### Rule 1: Key-value pairs
The atom of YAML is `key: value`:
```yaml
name: Security CI
runs-on: ubuntu-latest
```
Read it as plain English: "the *name* is Security CI; this *runs on* ubuntu-latest." That's it. A label, a colon, a value.

### Rule 2: Indentation shows nesting (this is the big one)
YAML uses **spaces** (never tabs) to show that something *belongs inside* something else — like a bulleted outline.
```yaml
jobs:              # a key whose value is a group of things nested below it
  build:           # "build" is INSIDE jobs (2 spaces in)
    runs-on: ubuntu-latest   # "runs-on" is INSIDE build (4 spaces in)
```

> **The nested-folders analogy:** Indentation in YAML works exactly like folders on your computer. `jobs/` contains a folder `build/`, which contains a file `runs-on`. The deeper the indentation, the deeper inside you are. Mis-indent a line and you've put a file in the wrong folder — YAML will misread the whole structure.

⚠️ **The #1 beginner mistake:** inconsistent indentation, or using tabs. YAML is strict about this. Two spaces per level, always spaces, never tabs. When a workflow "won't run" or errors on syntax, indentation is the usual culprit.

### Rule 3: Lists use dashes
When a key holds *multiple* items, each gets a `-`:
```yaml
branches:
  - main
  - develop
```
Read the `-` as a bullet point: "branches: • main • develop." You'll see this constantly for the *steps* in a job (a list of things to do, in order).

### Rule 4: Comments start with `#`
```yaml
runs-on: ubuntu-latest   # this is a comment, ignored by the machine
```
We use these heavily in the series to explain *why* each line exists.

That's genuinely all the YAML you need. Key-value, indentation-for-nesting, dashes-for-lists, hash-for-comments. Four rules.

---

## Part D: The anatomy of a workflow — top to bottom

Now let's read a real workflow structure — the skeleton of Phase 2's `security.yml` — using only the four YAML rules and the CI concepts above. There's a strict hierarchy: **Workflow → Triggers → Jobs → Steps.**

```yaml
name: Security CI          # ① The workflow's name (shows up in the Actions tab)

on:                        # ② TRIGGERS: when should this run?
  push:
    branches: [main]       #    run on pushes to main
  pull_request:            #    AND run on every pull request

permissions:               # ③ least-privilege: what can this workflow touch?
  contents: read           #    only allowed to READ the code

jobs:                      # ④ JOBS: the units of work (run in PARALLEL by default)
  build:                   #    a job named "build"
    runs-on: ubuntu-latest #    the fresh machine it runs on
    steps:                 #    STEPS: an ordered list of commands (run TOP to BOTTOM)
      - name: Checkout code
        uses: actions/checkout@v4          # grab the repo onto the empty machine

      - name: Install dependencies
        run: npm ci                        # a shell command

      - name: Run the security scan
        run: npm run lint
```

Let's name each layer, because the vocabulary is what unlocks reading *any* workflow:

| Layer | What it is | Analogy |
|---|---|---|
| **Workflow** (the whole file) | One complete pipeline | The entire recipe |
| **`on:` (triggers)** | The events that start it | "Bake when the timer rings" |
| **Jobs** | Units of work, **parallel by default** | Different cooks working simultaneously |
| **Steps** | Ordered commands within a job | The numbered steps one cook follows |

### Two subtleties that matter for the series

**Jobs run in *parallel*; steps run in *sequence*.** By default, all jobs start at once (our SAST, SCA, and secret-scan jobs run simultaneously — faster feedback). But *within* a job, steps run strictly top-to-bottom (you can't run the scan before you've installed the tools). This is why our workflows have several independent *jobs* but carefully ordered *steps*.

**`uses:` vs `run:`** — the two kinds of steps you'll see everywhere:
- `run:` executes a shell command you write (`npm ci`, `npm run lint`).
- `uses:` pulls in a pre-built, reusable action someone published (`actions/checkout@v4` to fetch your code, `aquasecurity/trivy-action` to run Trivy). It's like importing a library instead of writing it yourself. The `@v4` pins the version — same reasoning as pinning a Docker base image (Primer 3): reproducibility and supply-chain safety.

---

## Part E: Making a step a *gate* — the exit code

How does a step "fail" and stop the pipeline? Through the **exit code** — and understanding this one concept unlocks *why our scanners are configured the way they are* across every phase.

> **Definition — Exit code:** A number a command returns when it finishes. **`0` means success**; **any non-zero number means failure.** CI treats a non-zero exit from any step as "this step failed," which fails the job, which (with branch protection) blocks the merge.

> **The thumbs-up / thumbs-down analogy:** Every command, when it finishes, gives either a thumbs-up (0, "all good") or a thumbs-down (non-zero, "problem"). CI watches for the thumbs-down and stops the line.

This is *exactly* why, throughout the series, our scanners are configured with settings like:
```yaml
exit-code: "1"              # tell the scanner: exit non-zero (fail) if you find something
severity: "HIGH,CRITICAL"   # ...but ONLY for HIGH/CRITICAL findings
```
We're deliberately telling the scanner: "give a thumbs-down (fail the gate) *only* when you find something serious." That single configuration choice is what turns a scanner from a passive reporter into an active gate — *and* keeps it from crying wolf on trivial findings (our developer-friction principle from Phase 2/5). The exit code is the mechanism behind every security gate in this series.

---

## Part F: The other triggers you'll meet

Phase 2's workflow triggers on `push` and `pull_request`, but the series uses two more trigger types worth knowing:

**Scheduled runs (Phase 5's compliance report):**
```yaml
on:
  schedule:
    - cron: "0 6 * * 1"   # every Monday at 06:00 UTC
```
`cron` is a classic time-schedule syntax (the five fields mean minute, hour, day-of-month, month, day-of-week). This is how Phase 5 generates its compliance report automatically every week — no human needed. "Continuous" applies to *time*, not just code changes.

**Manual runs:**
```yaml
on:
  workflow_dispatch: {}    # adds a "Run workflow" button in the Actions tab
```
Lets you trigger a workflow by hand when you want to.

**Job dependencies (Phase 4's build → scan → sign → deploy):**
```yaml
jobs:
  scan:
    needs: build           # this job WAITS for "build" to finish successfully
```
`needs:` overrides the default parallelism to *force an order*. Phase 4 uses this to guarantee you can't sign an image before it's scanned, or deploy before it's signed — the pipeline stages line up like the security lifecycle itself. This one keyword is what turns a pile of parallel jobs into a disciplined, sequential *gate chain*.

---

## Part G: Putting it together — reading a whole phase

With everything above, you can now read Phase 4's `release.yml` as a *sentence*:

> "**On** a push to main *(trigger)*, run these **jobs**: first `build` the image and push it to the registry; **then** (`needs: build`) `scan` it and fail if there are HIGH/CRITICAL CVEs *(exit-code gate)*; **then** (`needs: [build, scan]`) `sign` it; **then** (`needs: [build, scan, sign]`) `deploy` it — but first *verify the signature* and fail the deploy if verification returns non-zero *(the final gate)*."

That's the entire Phase 4 pipeline, and you can now trace every arrow in the diagram:
```
build ──▶ scan ──▶ sign ──▶ deploy(verify ▶ ship)
        (each ▶ is a `needs:`; each stage can thumbs-down and stop the line)
```

No magic left — just triggers, jobs, steps, `needs:`, and exit codes.

---

## The six things to carry into Phases 2–5

1. **CI runs your checks automatically on every push; CD ships what passes.** Automation removes reliance on human memory.
2. **A gate blocks progress on failure** — that's what turns a scanner from advice into enforced policy (branch protection = the turnstile).
3. **Each run is a fresh, empty, disposable machine** — which is why every workflow checks out code and installs its own tools.
4. **YAML is just key-value + indentation-for-nesting + dashes-for-lists.** Watch your spaces; never tabs.
5. **Jobs run in parallel; steps run in order; `needs:` forces a sequence** — this is how Phase 4's build→scan→sign→deploy chain works.
6. **Exit codes are the gate mechanism:** `0` = pass, non-zero = fail. `exit-code: "1"` + `severity: "HIGH,CRITICAL"` is how we make scanners fail *only* on serious findings.

---

## ✅ Self-check

1. Why is a *gate* (like branch protection) fundamentally more powerful than a scanner that just prints warnings?
2. In YAML, what does indentation express, and what's the most common beginner mistake with it?
3. Every CI workflow starts by "checking out the code" and "installing dependencies." Why can't it just skip that and use what's already there?
4. Your workflow has three jobs with no `needs:` between them. Do they run one after another, or all at once? What about the steps *inside* one job?
5. A Trivy step is configured with `exit-code: "1"` and `severity: "HIGH,CRITICAL"`. Describe exactly when this step will fail the pipeline — and when it won't.
6. Phase 4 needs to guarantee an image is scanned *before* it's signed. Which YAML keyword makes that happen?
