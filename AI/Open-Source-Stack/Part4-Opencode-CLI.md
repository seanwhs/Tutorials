# Part 4: OpenCode CLI Mastery

**Series:** Leveraging the Open-Source AI Stack | **Prev:** Part 3 — Customizing the Workflow | **Next:** Part 5 — Agentic Loops

---

## 1. Concept: Why the Terminal, Not Just the GUI

Continue.dev is excellent for interactive, in-context work while you're actively looking at a file. But a large class of tasks are better suited to a terminal-native agent: whole-repo analysis you kick off and walk away from, scripted/automated operations, CI-adjacent tasks, and anything you want to pipe into other Unix tools or chain into a shell script. That is OpenCode CLI's job.

OpenCode CLI is an open-source, model-agnostic agentic coding agent that runs in your terminal, reads your project, can propose and apply file edits, run shell commands (with permission gating), and be scripted non-interactively. Like Continue, it is not tied to one model vendor — same Ollama-first, API-optional philosophy applies.

## 2. Installation

Via npm (works cross-platform, requires Node 18+):

```bash
npm install -g opencode-ai
```

Or via the install script (macOS/Linux):

```bash
curl -fsSL https://opencode.ai/install | bash
```

Verify:

```bash
opencode --version
```

Windows users: run inside WSL2 for the smoothest experience; native support varies by release, WSL2 avoids path/permission edge cases entirely.

## 3. First Run and Auth

From inside your project root:

```bash
cd acme-widgets
opencode
```

On first launch OpenCode prompts you to configure a model provider. Choose Ollama for a fully local, zero-cost setup, or add an API key for a hosted provider. This creates a config file.

## 4. The `opencode.json` Configuration File

Project-level config lives at `.opencode/opencode.json` (global fallback at `~/.config/opencode/opencode.json`). This is the CLI equivalent of Continue's `config.yaml` from Part 1.

**File: `.opencode/opencode.json`**

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "ollama",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen2.5-coder:7b": {
          "name": "Qwen Coder 7B (Local)"
        },
        "deepseek-coder-v2:16b": {
          "name": "DeepSeek Coder V2 (Local, Heavy)"
        }
      }
    },
    "anthropic": {
      "models": {
        "claude-3-5-sonnet-latest": {
          "name": "Claude Sonnet (API, Hard Problems)"
        }
      }
    }
  },
  "model": "ollama/qwen2.5-coder:7b",
  "autoshare": false,
  "permission": {
    "edit": "ask",
    "bash": "ask"
  },
  "instructions": [".opencode/AGENTS.md"]
}
```

Key fields explained:

- **`provider`**: declares which backends are available and how to reach them; Ollama points at the local OpenAI-compatible endpoint, Anthropic relies on an API key found in the environment (`ANTHROPIC_API_KEY`), never inlined here.
- **`model`**: the default model reference for this project, in `provider/model` form; anyone cloning the repo gets the same sane local-first default.
- **`permission`**: the safety-critical field. `"ask"` means OpenCode must prompt you before editing a file or running a shell command — never set this to `"allow"` for `bash` without deliberately reading Part 6 first.
- **`instructions`**: points at a markdown file (like Continue's rules file) with project conventions, loaded on every session.

Set the API key outside the file, in your shell profile or a local-only `.env` sourced by your shell, never committed:

```bash
export ANTHROPIC_API_KEY="sk-ant-your-key-here"
```

## 5. Project Conventions for OpenCode

**File: `.opencode/AGENTS.md`**

```markdown
# acme-widgets — Agent Instructions

This is an Express API (src/api) plus a React frontend (src/web).

Rules:
- Routes call controllers, controllers call services, only services/db call the database.
- Use Vitest, not Jest, for all tests.
- Named exports only, no default exports.
- Every new async function needs explicit try/catch error handling.
- Never modify files under .env, .env.*, or anything in secrets/ — refuse and explain instead.
- Never run destructive git commands (push --force, reset --hard, branch -D) without explicit human confirmation restated in the same session.
```

This mirrors Continue's `project-conventions.md` from Part 2 deliberately: both tools should be told the same architectural truths, so switching between GUI and CLI never gives you contradictory suggestions.

## 6. Interactive Mode: Natural-Language Codebase Queries

Launch interactive TUI mode:

```bash
opencode
```

Example queries typed at the prompt, no flags needed:

```text
Where is rate limiting implemented in this codebase?

Find every place we make an outbound HTTP call without a timeout configured.

Explain the relationship between src/api/db and src/api/services.
```

OpenCode reads relevant files itself (you'll see it list which files it opened) rather than you pasting anything — similar in spirit to Continue's `@codebase` provider from Part 2, but without needing a pre-built embeddings index. OpenCode's agent loop searches and reads files on demand each session.

## 7. Non-Interactive / Scriptable Mode

For automation, pipelines, or quick one-shot terminal use, run OpenCode non-interactively with a single prompt and exit:

```bash
opencode run "Summarize the purpose of every file in src/api/routes" --quiet
```

Useful flags:

```bash
opencode run "<prompt>" \
  --model ollama/qwen2.5-coder:7b \
  --cwd ./acme-widgets \
  --quiet \
  --output-format json
```

- `--model`: override the default model for this one invocation, handy for forcing the heavier API model on a specific hard task without editing config.
- `--cwd`: run against a specific directory without `cd`-ing first, useful in scripts operating on multiple repos.
- `--quiet`: suppress the interactive TUI chrome, print only the result — required for piping into other tools.
- `--output-format json`: machine-parseable output, essential for the agentic loop scripts in Part 5.

## 8. Automating Boilerplate Creation

A concrete example: generating a new Express route + controller + service triple that matches the existing pattern, entirely from the terminal.

**File: `scripts/ai/scaffold-route.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

RESOURCE_NAME="${1:?Usage: scaffold-route.sh <resourceName>}"

opencode run "Create a new Express resource named '${RESOURCE_NAME}' following the exact existing pattern in src/api/routes, src/api/controllers, and src/api/services (look at the userController/userService/userRoutes trio as the reference pattern). Create three new files: src/api/routes/${RESOURCE_NAME}Routes.ts, src/api/controllers/${RESOURCE_NAME}Controller.ts, src/api/services/${RESOURCE_NAME}Service.ts, with basic CRUD (list, get by id, create, update, delete) stubbed following the same error handling and export conventions as the reference trio. Also register the new router in the main app router file. Ask before writing any file." \
  --cwd "$(pwd)"
```

Usage:

```bash
chmod +x scripts/ai/scaffold-route.sh
./scripts/ai/scaffold-route.sh widget
```

Because `permission.edit` is set to `"ask"` in `opencode.json`, OpenCode will show you a diff for each of the three new files and the router registration change, and wait for your approval before writing anything — automation of the boilerplate, not automation of the review.

## 9. Project-Wide Analysis Example

```bash
opencode run "Audit src/api for any route handler that reads req.body or req.query without any validation library (zod, joi, or manual checks) being applied, and list them as a table with file path and the specific field that is unvalidated" --output-format json > reports/unvalidated-input-audit.json
```

Piping structured output to a file turns an ad hoc question into a repeatable, diffable audit artifact you can re-run after every sprint and track in git history.

## 10. Exercise Challenge

Write a script `scripts/ai/explain-file.sh` that takes a file path as an argument and runs OpenCode non-interactively to produce a concise, staff-engineer-level explanation of that single file, saving the output to a markdown file named after the source file in a `docs/generated/` folder.

## 11. Solution

**File: `scripts/ai/explain-file.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="${1:?Usage: explain-file.sh <path/to/file>}"
BASENAME=$(basename "$TARGET_FILE")
OUT_DIR="docs/generated"
OUT_FILE="${OUT_DIR}/${BASENAME}.explained.md"

mkdir -p "$OUT_DIR"

opencode run "Read ${TARGET_FILE} and produce a concise staff-engineer explanation: 1) purpose in one paragraph, 2) exported functions/classes and what each does, 3) any non-obvious edge cases handled, 4) any risk or tech debt visible. Output clean markdown only, no preamble." \
  --quiet \
  --output-format text > "$OUT_FILE"

echo "Explanation written to ${OUT_FILE}"
```

Usage:

```bash
chmod +x scripts/ai/explain-file.sh
./scripts/ai/explain-file.sh src/api/services/emailService.ts
cat docs/generated/emailService.ts.explained.md
```

This pattern — CLI call redirected to a file — is the building block Part 5 extends into a full agentic loop that also feeds command output (not just file content) back into an AI call.

---

**Next: Part 5 — Agentic Loops.**
