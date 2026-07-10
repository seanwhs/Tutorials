# Part 2: Deep Context & Indexing

**Series:** Leveraging the Open-Source AI Stack | **Prev:** Part 1 — The AI-Assisted IDE | **Next:** Part 3 — Customizing the Workflow

---

## 1. Concept: How Continue Actually "Reads" Your Project

Continue does not send your entire repository to the model on every request. That would blow context windows and cost/latency budgets immediately. Instead it builds a local index and pulls in only what is relevant per query, through three complementary mechanisms:

1. **Codebase embeddings index**: on first load (and incrementally after), Continue walks the workspace, chunks files, generates embeddings for each chunk using an embeddings model, and stores vectors locally (typically in a local LanceDB-backed store under a hidden Continue index directory). When you ask a question, it embeds your query and retrieves the most similar chunks, then injects those chunks into the prompt.
2. **Context providers**: explicit, deterministic ways to pull specific things into the prompt on demand, invoked with the `@` symbol in chat (for example `@file`, `@codebase`, `@diff`, `@terminal`, `@docs`, `@git-log`). These bypass semantic search and pull exactly what you ask for.
3. **Rules files**: always-on instructions (project conventions, style guide, architectural constraints) that get prepended to every request automatically, without you invoking anything.

Understanding which mechanism is firing matters because it explains both good answers and bad ones: a vague answer often means the embeddings retrieval missed the right chunk; the fix is usually to be more explicit with an `@` context provider rather than trusting semantic search alone.

## 2. Configuring the Embeddings Model

Indexing needs its own embeddings model, separate from your chat model. Add an `embed`-role model block. A local Ollama embeddings model keeps indexing fully offline.

Pull an embeddings model:

```bash
ollama pull nomic-embed-text
```

**File: `.continue/config.yaml`** (extending Part 1's file)

```yaml
models:
  - name: Qwen Coder 7B (Local Chat)
    provider: ollama
    model: qwen2.5-coder:7b
    roles:
      - chat
      - edit
  - name: Qwen Coder 1.5B (Local Autocomplete)
    provider: ollama
    model: qwen2.5-coder:1.5b-base
    roles:
      - autocomplete
  - name: Nomic Embed (Local Indexing)
    provider: ollama
    model: nomic-embed-text
    roles:
      - embed

context:
  - provider: file
  - provider: codebase
  - provider: diff
  - provider: terminal
  - provider: folder
  - provider: git-log
```

Reload with `Continue: Reload Config`, then trigger a fresh index build with `Continue: Rebuild Codebase Index` from the command palette. Watch progress in the Continue output channel (View → Output → select "Continue" from the dropdown).

## 3. Controlling What Gets Indexed

By default Continue respects your `.gitignore`, which is usually sufficient, but large repos benefit from an explicit ignore file to keep the index fast and relevant. Create `.continueignore` at the repo root — same syntax as `.gitignore`.

**File: `.continueignore`**

```text
node_modules/
dist/
build/
.next/
coverage/
*.lock
*.min.js
*.map
.env
.env.*
**/*.snap
public/vendor/
```

Rationale for each entry: `node_modules` and lockfiles are noise that dilutes semantic search with third-party code; build output is derived, not source of truth; snapshot test files and minified bundles are large and low-signal; `.env` files must never be embedded or retrievable at all (covered in depth in Part 6).

## 4. Explicit Context Providers in Practice

Semantic search is probabilistic. When you know exactly what you want in context, use an explicit provider instead of relying on retrieval.

Examples typed directly into the Continue chat input:

```text
@file src/api/controllers/userController.ts explain what happens if req.body.email is undefined

@codebase where is rate limiting implemented across this project

@diff write a commit message for these staged changes

@terminal explain this stack trace and point to the likely file

@folder src/api/routes summarize the responsibilities of every route file in this folder

@git-log summarize what changed in the last 10 commits related to auth
```

The `@codebase` provider is the one backed by the embeddings index from section 2; the others are deterministic and do not depend on indexing quality at all. When debugging why an answer feels off-target, switch from `@codebase` to a more specific provider like `@file` or `@folder` to rule out a bad retrieval.

## 5. Always-On Rules (Project Conventions)

Rules are instructions injected into every single request, used for durable facts the model should never "forget" mid-session: naming conventions, architectural boundaries, forbidden patterns.

**File: `.continue/rules/project-conventions.md`**

```markdown
---
name: Project Conventions
alwaysApply: true
---

This is the acme-widgets repository, an Express API plus a React frontend.

Conventions the assistant must follow in all suggestions:
- Backend code lives under src/api. Never suggest business logic inside route files; routes call controllers, controllers call services.
- All database access goes through src/api/db. Never suggest a raw SQL query outside that folder.
- Frontend components are functional components with hooks only. No class components.
- Use named exports everywhere. Default exports are not used in this codebase.
- All new async functions must have explicit error handling; do not suggest bare await without a try/catch or an error boundary equivalent.
- Tests use Vitest, not Jest. Do not suggest jest.mock; use vi.mock.
```

Reference this file from `config.yaml`:

```yaml
rules:
  - .continue/rules/project-conventions.md
```

This is the single highest-leverage file in the whole setup: a few dozen lines here eliminate a large fraction of "technically correct but wrong for this codebase" suggestions, because the model is reminded of your architecture on every single call rather than you re-explaining it each session.

## 6. Verifying the Index Is Actually Being Used

A quick trust-but-verify test: ask a question whose correct answer requires knowledge that only exists in a file you have not opened this session, using `@codebase`, and confirm the response cites or reflects the content of that file. If it does not, check the Continue output channel for indexing errors (a common cause is the embeddings model failing to pull, or `.continueignore` excluding the very folder you're asking about).

## 7. Exercise Challenge

The acme-widgets repo has a folder `src/api/middleware` that is currently un-excluded and un-highlighted. Write a rules file addition that tells the assistant middleware order matters (auth middleware must always run before rate-limiting middleware) and verify, via a chat prompt using `@folder src/api/middleware`, that the assistant reflects this ordering constraint back to you unprompted.

## 8. Solution

Append to `.continue/rules/project-conventions.md`:

```markdown
Middleware ordering constraint: in src/api/middleware, authentication middleware must always execute before rate-limiting middleware, because rate limits are applied per authenticated user id, not per IP. Any suggestion that reorders middleware registration must preserve auth-before-rate-limit ordering.
```

After reloading config, prompt:

```text
@folder src/api/middleware what would happen if I moved the rate limiter before the auth check
```

A correctly configured assistant will proactively state that this breaks per-user rate limiting because the user id would not yet be attached to the request — sourced directly from the always-on rule rather than from the folder contents alone, demonstrating that rules and context providers compose together in a single request.

---

**Next: Part 3 — Customizing the Workflow.**
