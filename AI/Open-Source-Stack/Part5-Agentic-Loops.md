# Part 5: Agentic Loops

**Series:** Leveraging the Open-Source AI Stack | **Prev:** Part 4 — OpenCode CLI Mastery | **Next:** Part 6 — Production-Grade Habits

---

## 1. Concept: Closing the Loop Between Tool Output and AI Fix

Everything so far has been human-initiated: you ask, the assistant answers or proposes a diff, you approve. An **agentic loop** adds one more stage: a deterministic tool (test runner, linter, type checker) produces machine output (pass/fail, stack trace, lint errors), and that output is fed automatically as context into an AI call that proposes a fix — closing the loop from "code changed" to "verified or diagnosed" without you manually copy-pasting a stack trace into a chat window.

The critical design constraint, restated up front because it governs every script in this part: **the loop proposes, it does not auto-apply and auto-commit**. OpenCode's `permission.edit: "ask"` setting from Part 4 is what keeps a human in the loop at the exact moment code is about to change. We are automating the tedious middle step (running the tool, capturing output, constructing a good prompt), not the judgment step.

## 2. Architecture of the Loop

Step by step, for a test-fixing loop:

1. A shell script runs the test suite and captures both the pass/fail status and full output (stdout+stderr) to a variable/file.
2. If tests failed, the script constructs a prompt that includes the actual failure output (not a summary — the literal stack trace/assertion diff) plus a pointer to the relevant source file.
3. The script invokes `opencode run` non-interactively with that prompt, permission still set to `ask`, so OpenCode pauses for approval before writing anything.
4. You review the proposed diff, approve or reject, then re-run the script to confirm green.

## 3. The Core Script: Test-and-Fix Loop

**File: `scripts/ai/test-and-fix.sh`**

```bash
#!/usr/bin/env bash
set -uo pipefail

echo "==> Running test suite..."
TEST_OUTPUT=$(npm test 2>&1)
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "==> Tests passed. Nothing to fix."
  exit 0
fi

echo "==> Tests failed (exit code ${TEST_EXIT_CODE}). Handing failure output to OpenCode..."

PROMPT="The test suite for this project just failed. Here is the exact captured output (stdout and stderr combined):

---BEGIN TEST OUTPUT---
${TEST_OUTPUT}
---END TEST OUTPUT---

Task:
1. Identify which specific test(s) failed and the root cause in the source code (not the test file, unless the test itself is actually wrong).
2. Propose the minimal fix to the source file(s) that makes the failing test(s) pass, without changing unrelated code.
3. Do not modify the test file unless you can clearly justify that the test itself asserts incorrect behavior — state that justification explicitly if you do.
4. Show me the diff and explain your reasoning before making any change."

opencode run "$PROMPT" --cwd "$(pwd)"

echo "==> Review the proposed changes above. Re-run this script after approving to confirm green."
```

Usage:

```bash
chmod +x scripts/ai/test-and-fix.sh
./scripts/ai/test-and-fix.sh
```

Because this invokes `opencode run` while `permission.edit` is `"ask"`, you still get an interactive approval prompt for any file OpenCode wants to change, even though the test-running and prompt-construction steps were fully automated.

## 4. Variant: Lint-and-Fix Loop

**File: `scripts/ai/lint-and-fix.sh`**

```bash
#!/usr/bin/env bash
set -uo pipefail

echo "==> Running linter..."
LINT_OUTPUT=$(npm run lint 2>&1)
LINT_EXIT_CODE=$?

if [ $LINT_EXIT_CODE -eq 0 ]; then
  echo "==> Lint clean."
  exit 0
fi

echo "==> Lint errors found. Handing off to OpenCode..."

PROMPT="ESLint just reported the following errors/warnings on this project:

---BEGIN LINT OUTPUT---
${LINT_OUTPUT}
---END LINT OUTPUT---

Fix every error listed (not warnings, unless a warning is trivially one-line to resolve). For each fix, briefly state which rule was violated and why your fix satisfies it. Do not disable rules with eslint-disable comments unless a fix is genuinely impossible without a broader refactor — in that case, flag it instead of suppressing it."

opencode run "$PROMPT" --cwd "$(pwd)"
```

Same shape as the test loop, different tool, same non-negotiable human-approval gate.

## 5. Bridging to Continue.dev: The GUI Side of the Loop

The CLI is ideal for the "run tool, capture output" half. Sometimes you'd rather review and iterate on the fix inside the editor, with full file context and diff view, using Continue instead of the CLI's own diff view. Two practical bridges:

**Bridge A — CLI captures, Continue fixes**: run just the capture half of the script, write output to a file, then reference that file from Continue chat with `@file`.

**File: `scripts/ai/capture-test-failure.sh`**

```bash
#!/usr/bin/env bash
set -uo pipefail

OUT_FILE=".continue/.last-test-failure.txt"
npm test > "$OUT_FILE" 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "Tests passed."
  rm -f "$OUT_FILE"
else
  echo "Tests failed. Output captured to ${OUT_FILE}"
  echo "In Continue chat, run: @file ${OUT_FILE} explain and fix these failures"
fi
```

Add `.continue/.last-test-failure.txt` to `.gitignore` since it's a transient artifact, not source. Then in the Continue chat panel:

```text
@file .continue/.last-test-failure.txt explain these failures and propose a fix using the same reasoning approach as /refactor-to-async where applicable
```

This gets you the CLI's automation for the tedious capture step, and Continue's richer inline-diff editing experience for the actual fix — best of both tools rather than picking one.

**Bridge B** — a custom Continue slash command that expects this file to exist, so the workflow becomes muscle memory:

**File: `.continue/prompts/fix-last-test-failure.prompt`**

```markdown
---
name: fix-last-test-failure
description: Read .continue/.last-test-failure.txt and propose a fix for the captured failure
---

Read the file .continue/.last-test-failure.txt in this workspace (if it does not exist, tell me to run scripts/ai/capture-test-failure.sh first and stop).

Identify the root cause of the failure(s) in the source code, propose the minimal fix, and follow this repo's error-handling and test conventions from project-conventions.md. Show the diff and your reasoning before I approve any change.
```

Now the full loop from a developer's perspective is: run one script, then type one slash command in the editor.

## 6. Guardrails Specific to Automated Loops

Three rules that apply specifically because these scripts can be run unattended or in quick succession, distinct from the general safety rules covered fully in Part 6:

1. **Never chain a fix-loop script directly into `git commit` or `git push`** in the same script. Fixing and committing must be separate, human-gated steps.
2. **Cap iteration**: if you build a "retry until green" wrapper loop, hard-limit it (for example 3 attempts) and exit with a clear failure message rather than looping indefinitely against a test the AI cannot actually fix (common when the failure is an environment/infra issue, not a code bug).
3. **Always run the fix-loop against a clean git working tree**, or at minimum a tree where existing changes are already staged/committed separately, so that if you need to `git diff` or `git checkout -- .` to bail out, you don't lose unrelated in-progress work.

## 7. Exercise Challenge

Extend `scripts/ai/test-and-fix.sh` into a capped retry loop: after OpenCode proposes and you approve a fix, automatically re-run the test suite, and if it still fails, feed the new failure output back in for attempt 2, up to a maximum of 3 attempts total, printing a clear final status either way.

## 8. Solution

**File: `scripts/ai/test-and-fix-retry.sh`**

```bash
#!/usr/bin/env bash
set -uo pipefail

MAX_ATTEMPTS=3
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo "==> Attempt ${ATTEMPT}/${MAX_ATTEMPTS}: running test suite..."
  TEST_OUTPUT=$(npm test 2>&1)
  TEST_EXIT_CODE=$?

  if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "==> Tests passed on attempt ${ATTEMPT}. Done."
    exit 0
  fi

  echo "==> Tests failed on attempt ${ATTEMPT}. Requesting fix from OpenCode (you will be asked to approve any file changes)..."

  PROMPT="Attempt ${ATTEMPT} of ${MAX_ATTEMPTS}. The test suite failed with this output:

---BEGIN TEST OUTPUT---
${TEST_OUTPUT}
---END TEST OUTPUT---

Propose the minimal fix to source (not test files, unless clearly justified). Show diff and reasoning before any change."

  opencode run "$PROMPT" --cwd "$(pwd)"

  echo "==> If you approved a change above, press Enter to re-run tests. Press Ctrl+C to stop here."
  read -r _

  ATTEMPT=$((ATTEMPT + 1))
done

echo "==> Reached maximum of ${MAX_ATTEMPTS} attempts. Tests are still failing — this likely needs human investigation, not another AI attempt. Stopping."
exit 1
```

This keeps the human-approval gate on every single attempt (via OpenCode's own edit prompt plus the explicit `read -r` pause before re-running), while automating the repetitive capture-prompt-recapture cycle, and refuses to loop forever against an unfixable failure.

---

**Next: Part 6 — Production-Grade Habits.**
