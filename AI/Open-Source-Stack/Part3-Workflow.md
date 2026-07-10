# Part 3: Customizing the Workflow

**Series:** Leveraging the Open-Source AI Stack | **Prev:** Part 2 — Deep Context & Indexing | **Next:** Part 4 — OpenCode CLI Mastery

---

## 1. Concept: Slash Commands as Encoded Team Knowledge

A slash command in Continue is a named, reusable prompt template, invoked as `/command-name` in the chat input. The value is not "saving keystrokes" — it is encoding a repeatable review or refactor pattern once, as a versioned file in the repo, so every developer on the team gets the same rigor applied the same way, instead of everyone writing their own ad hoc prompt with varying quality.

Two mechanisms exist in current Continue:

1. **Prompt files**: markdown files with YAML frontmatter under `.continue/prompts/`, each becomes a slash command named after the file.
2. **Custom commands block** in `config.yaml`: inline definitions for very short commands, useful for quick one-liners that don't warrant their own file.

We'll build the three commands requested — `/refactor-to-async`, `/generate-tests`, `/explain-architecture` — as prompt files, because non-trivial commands benefit from being reviewable diffs in git like any other source file.

## 2. Anatomy of a Prompt File

Fields in the frontmatter:

- `name`: the slash command name (without the leading slash)
- `description`: shown in the command picker
- **Prompt body**: plain text/markdown, supports the same `@` context provider syntax as normal chat input, plus a special `{{{ input }}}` placeholder for whatever the user typed after the command name

## 3. Command 1: `/refactor-to-async`

Use case: you select or reference a chunk of callback-based or `.then()`-chained code and want it converted to async/await with your team's error-handling convention applied automatically.

**File: `.continue/prompts/refactor-to-async.prompt`**

```markdown
---
name: refactor-to-async
description: Convert callback or .then() chains to async/await with try/catch, following project error-handling conventions
---

You are refactoring code in the acme-widgets repository.

Task: rewrite the following code so that:
1. All Promise .then()/.catch() chains and callback-style async code are converted to async/await.
2. Every await is wrapped in a try/catch, following this repo's convention (see project-conventions.md rule).
3. Caught errors are passed to the existing error handler pattern used elsewhere in this file's folder — check @codebase for the nearest existing try/catch in a sibling file and match its error-response shape exactly, do not invent a new error shape.
4. Variable names and control flow are preserved as closely as possible; this is a mechanical refactor, not a redesign.
5. Output the full rewritten function(s) only, followed by a one-paragraph explanation of any edge case you had to make a judgment call on.

Code or file reference to refactor:
{{{ input }}}
```

Usage example in chat:

```text
/refactor-to-async @file src/api/services/emailService.ts
```

## 4. Command 2: `/generate-tests`

Use case: point at a file or function and get a Vitest test file scaffolded that actually matches your existing test conventions, not generic boilerplate.

**File: `.continue/prompts/generate-tests.prompt`**

```markdown
---
name: generate-tests
description: Generate a Vitest test file for the referenced code, matching existing test conventions in this repo
---

You are writing tests for the acme-widgets repository, which uses Vitest (not Jest — use vi.mock, vi.fn, not jest equivalents).

Before writing anything, look at @codebase for an existing test file in the same folder as the target code, or the nearest sibling folder, to match:
- Import style and test file naming pattern
- How mocks are set up (for example db calls, external HTTP calls)
- Assertion style (expect(...).toBe vs toEqual vs toMatchObject)

Task for the referenced code:
1. Identify every exported function and every branch (including error paths, empty-input paths, and boundary conditions).
2. Generate one describe block per exported function.
3. Include at least one test per branch identified in step 1 — do not only test the happy path.
4. Mock external dependencies (database, network, filesystem) rather than hitting them for real.
5. Output only the complete test file content, ready to save, with correct relative import paths based on where the source file actually lives.

Code or file to generate tests for:
{{{ input }}}
```

Usage example in chat:

```text
/generate-tests @file src/api/controllers/userController.ts
```

## 5. Command 3: `/explain-architecture`

Use case: onboarding a new teammate, or re-orienting yourself after time away, without manually re-reading every file.

**File: `.continue/prompts/explain-architecture.prompt`**

```markdown
---
name: explain-architecture
description: Produce a staff-engineer-level architecture explanation of a folder, module, or the whole repo
---

You are explaining the architecture of the acme-widgets repository, or a specific area of it if one is referenced below, to a competent engineer who has never seen this codebase.

Structure your answer exactly as:

1. One-paragraph summary of the purpose of this area of the code.
2. Key files and what each one owns (list format, most important first).
3. Data flow: trace one representative request or operation end to end through the referenced area, naming actual files and functions from @codebase, not generic placeholders.
4. Dependencies and boundaries: what this area depends on, and what depends on it.
5. Notable patterns or deviations: anything unusual, any TODOs or tech debt visible in the code, any place the code contradicts the stated project conventions.
6. If nothing was referenced below, do this for the repository as a whole at the top-level folder granularity.

Area to explain (folder, file, or leave blank for whole repo):
{{{ input }}}
```

Usage example in chat:

```text
/explain-architecture @folder src/api
```

or for the whole repo:

```text
/explain-architecture
```

## 6. Registering the Commands

Prompt files under `.continue/prompts/` are auto-discovered; no `config.yaml` change is required. Confirm registration by typing `/` in the Continue chat input — `refactor-to-async`, `generate-tests`, and `explain-architecture` should appear in the autocomplete dropdown alongside Continue's built-in commands.

If a command does not appear, check: filename must end in `.prompt`, frontmatter `name` must be present and unique, and you must run `Continue: Reload Config` after adding new files.

## 7. Short Inline Commands (Alternative Mechanism)

For very short, no-frills commands, you can skip the file entirely and define them directly in `config.yaml` under a `prompts` block, useful for quick team-wide shortcuts:

```yaml
prompts:
  - name: commit-message
    description: Write a conventional-commit style message for staged changes
    prompt: "@diff Write a concise conventional-commit formatted commit message for these staged changes. Output only the commit message, no explanation."
```

This is the right tool for one-liners; anything with multi-step instructions (like our three commands above) should live in its own reviewable `.prompt` file.

## 8. Exercise Challenge

Create a fourth command, `/security-review`, that reviews a referenced file specifically for: hardcoded secrets, missing input validation, and SQL injection risk in any raw query, outputting findings as a markdown checklist with severity levels, and register it as a prompt file.

## 9. Solution

**File: `.continue/prompts/security-review.prompt`**

```markdown
---
name: security-review
description: Review referenced code for hardcoded secrets, missing input validation, and SQL injection risk
---

You are performing a focused security review of the referenced code in acme-widgets. Do not comment on style, formatting, or performance — security findings only.

Check specifically for:
1. Hardcoded secrets, API keys, tokens, passwords, or connection strings anywhere in the referenced code (not just obvious ones — check string literals passed to config/env-like function calls too).
2. Missing or insufficient input validation on any function that accepts external input (request body, query params, path params, file uploads).
3. SQL injection risk in any raw query construction — specifically string concatenation or template literals building SQL, as opposed to parameterized queries.

Output format: a markdown checklist, one item per finding, each prefixed with a severity tag of [HIGH], [MEDIUM], or [LOW], followed by the file and approximate line/function, followed by a one-sentence explanation and a one-sentence fix suggestion. If no findings in a category, state "No findings" under that category explicitly rather than omitting it.

Code or file to review:
{{{ input }}}
```

After saving the file and reloading config, `/security-review @file src/api/controllers/userController.ts` appears in the command picker and produces a checklist rather than free-form prose, because the structured output format was specified explicitly in the prompt rather than left to the model's default style.

---

**Next: Part 4 — OpenCode CLI Mastery.**
