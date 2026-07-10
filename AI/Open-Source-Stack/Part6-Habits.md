# Part 6: Production-Grade Habits

**Series:** Leveraging the Open-Source AI Stack | **Prev:** Part 5 — Agentic Loops | **Next:** Appendices

---

## 1. Concept: Where AI Assistance Ends and Engineering Judgment Begins

Everything in Parts 1-5 made you faster. Speed without discipline is how secrets end up in prompts, how a "quick refactor" silently changes public API behavior, and how a team ends up with fifteen slightly-different auth implementations because everyone's AI assistant improvised its own pattern. This part is the counterweight: concrete rules for secrets, for prompting architectural changes safely, and for what must always get human review regardless of how good the tool is.

## 2. Secrets: The Non-Negotiable Rules

Both Continue and OpenCode read your file system and, for indexing/context, may include file contents in prompts sent to a model (local or remote). A hardcoded secret in a source file is one `@codebase` query or one `opencode run` away from being transmitted to an API provider, even accidentally.

**Rule 1** — Secrets never live in files the tools can read as source. Use environment variables loaded at runtime, not literals.

Bad, never do this, in any file under version control:

```javascript
const apiKey = "sk-live-abc123realkeyhere";
```

Correct:

```javascript
const apiKey = process.env.STRIPE_SECRET_KEY;
if (!apiKey) {
  throw new Error("STRIPE_SECRET_KEY is not set");
}
```

**Rule 2** — Exclude all secret-bearing files from both tools' indexing, not just from git.

Confirm these three files agree with each other (they are easy to let drift out of sync):

**File: `.gitignore`** (relevant lines)

```text
.env
.env.*
!.env.example
secrets/
*.pem
*.key
```

**File: `.continueignore`** (from Part 2, relevant lines)

```text
.env
.env.*
secrets/
*.pem
*.key
```

**File: `.opencode/opencode.json`** (relevant addition to the permission block from Part 4)

```json
{
  "permission": {
    "edit": "ask",
    "bash": "ask"
  },
  "instructions": [".opencode/AGENTS.md"],
  "ignore": [
    ".env",
    ".env.*",
    "secrets/**",
    "*.pem",
    "*.key"
  ]
}
```

**Rule 3** — Never paste a real secret into a chat prompt "just this once" to debug an auth issue. Use a clearly fake placeholder value with the same shape (same prefix, same length pattern) instead — the model only needs the shape/format to reason about a bug, never the real value.

**Rule 4** — Treat chat history and any generated log/report files (like the audit reports from Part 4 section 9) as potentially sensitive. If an audit prompt could cause the model to echo back a secret it found (for example, while explaining a misconfigured env loader), review generated reports before committing them to a repo, and never commit raw captured tool output files like `.continue/.last-test-failure.txt` (already gitignored per Part 5).

**Rule 5** — Rotate any secret you have strong reason to believe was ever pasted into a hosted API model's chat, even once, even by accident. Local Ollama models never send data anywhere, which is the strongest argument for defaulting to local models (Part 1) for anything touching code near secrets, credentials, or customer data, and reserving hosted API models for genuinely secret-free reasoning tasks.

## 3. Prompting for Architectural Changes Safely

Small refactors (Part 3's `/refactor-to-async`) are low-risk because the blast radius is one function. Architectural changes — changing how modules communicate, introducing a new dependency, altering a data model — need a different prompting discipline because a plausible-looking, confidently-explained answer can still be structurally wrong for reasons the model has no way to know (team roadmap, an unwritten constraint, a deprecated-but-not-yet-removed system it doesn't know about).

**Habit 1 — Always require a plan before a diff**, for anything touching more than one module. Do not let the assistant jump straight to code for architectural asks.

Example prompt discipline, usable in Continue chat or as an `opencode run` invocation:

```text
I want to move session storage from in-memory to Redis. Before writing any code, give me: 1) every file that currently touches session state and would need to change, 2) the specific interface/contract you'd introduce so callers don't need to change, 3) a list of behavioral risks (session expiry semantics, multi-instance consistency) that differ between in-memory and Redis, 4) what you are NOT confident about and would want a human to confirm. Do not write implementation code yet.
```

Only after reviewing that plan, in a second prompt, ask for the implementation, scoped explicitly to the plan just agreed on.

**Habit 2** — For architectural asks, always pin the model manually to your strongest available option (the hosted API model from Part 1, or the heaviest local model your hardware supports) rather than the fast default model used for everyday autocomplete/chat. Speed is the wrong optimization target for a decision that's expensive to unwind.

**Habit 3** — Ask explicitly for the disagree case: "what would make this the wrong approach" or "what's the strongest argument against this design" as a follow-up, before implementing. Models tend to elaborate confidently on the path you proposed; a direct request for counter-argument surfaces risks that a purely affirmative answer would not.

**Habit 4** — Never let an agentic loop (Part 5) touch architectural-scope changes unattended. The capped-retry pattern from Part 5 is appropriate for a failing unit test with a narrow, mechanical fix. It is not appropriate for "the integration tests are failing because the new Redis session store isn't wired up right" — that failure mode needs a human back at the plan stage, not another automated attempt.

## 4. What Must Always Get Human Review, No Exceptions

A concrete, non-exhaustive checklist — code review effort should scale up, never down to zero, for anything on this list, regardless of how confident the AI-authored diff looks:

- Anything touching authentication, authorization, or session handling.
- Anything touching payment/billing logic.
- Database migrations, especially ones with data backfills or column drops.
- Changes to rate limiting, CORS configuration, or any security header.
- Dependency additions (a new package is a new supply-chain trust decision, not just a refactor).
- Anything the AI itself flagged low confidence on (see Habit 3 above) — do not treat a hedge as something to just accept anyway.
- Any change generated by an unattended/scripted agentic loop, before it is merged, even if tests pass — passing tests confirm the tests are satisfied, not that the change is architecturally sound.

## 5. Reviewing AI-Authored Diffs Efficiently

A fast, consistent review pass for AI-proposed diffs, whether from Continue's inline edit view or OpenCode's terminal diff:

1. Read the stated reasoning first, before the diff. If the reasoning doesn't match what the diff actually does, stop and ask for clarification before approving — this mismatch is the single strongest predictor of a subtly wrong change.
2. Check the blast radius: did it only touch what you asked it to touch, or did it "helpfully" reformat/rename things nearby? Unrequested changes outside the stated scope are a yellow flag, not an automatic rejection, but they need their own justification.
3. For anything on the Section 4 checklist, diff against the rules file (Part 2's `project-conventions.md` / Part 4's `AGENTS.md`) explicitly: did this change violate a stated convention, and if so, was that a deliberate, explained exception or an oversight?
4. Run the actual test suite yourself after approving, even when the tool reports success — tool-reported success reflects what the tool ran, not necessarily your full CI matrix.

## 6. Exercise Challenge

Your team lead asks you to let OpenCode automatically apply and commit fixes from the lint-and-fix loop (Part 5) without any human approval step, to "save time in CI." Write a short, direct explanation of why this violates the production-grade habits in this part, and propose the minimal safe alternative that still saves meaningful time.

## 7. Solution

Why full auto-apply-and-commit is unsafe here: even though lint fixes feel mechanical, `opencode.json`'s `permission.edit: "ask"` exists specifically because "looks mechanical" and "is safe" are not the same thing — a lint autofix can still change runtime behavior (for example a `no-unused-vars` fix that deletes a variable actually used via closure, or an import-order fix that triggers a side-effect-import ordering bug). Removing the human gate here sets the precedent that "this category of change doesn't need review," which is exactly the drift Section 4 warns against, and CI is the worst place to discover a subtly-wrong autofix because it's furthest from the developer with full context.

Minimal safe alternative that still saves real time: run `lint-and-fix.sh`'s capture-and-propose step automatically in CI (or a pre-commit hook) so the diff is generated and posted as a PR suggestion/comment automatically, with `permission.edit` left at `"ask"` so nothing is written without a human explicitly approving the specific suggested diff, either locally or via a one-click "apply suggestion" in the PR review UI. This keeps the toil (running lint, constructing the fix prompt, generating the diff) fully automated exactly as intended in Part 5, while keeping the actual file write gated behind a human decision — the one step this entire six-part series has consistently refused to automate away.

---

This concludes the core six parts. Next up: **Appendices** (A: File Tree, B: Cheat Sheet, C: Multi-Machine Sync).
