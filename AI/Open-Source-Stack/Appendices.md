# Appendices

**Series:** Leveraging the Open-Source AI Stack | **Prev:** Part 6 — Production-Grade Habits

---

## Appendix A — Codebase Reference: File Tree

Full reference tree combining everything built across Parts 1-6, with a comment on each file's origin and sync status (git-tracked vs. local-only).

```text
acme-widgets/
├── .continue/                              # Continue.dev workspace config
│   ├── config.yaml                         # [Part 1/2] models, context providers, rules reference — TRACKED
│   ├── .last-test-failure.txt              # [Part 5] transient capture output — GITIGNORED, never tracked
│   ├── rules/
│   │   └── project-conventions.md          # [Part 2] always-on architecture rules — TRACKED
│   └── prompts/
│       ├── refactor-to-async.prompt        # [Part 3] custom slash command — TRACKED
│       ├── generate-tests.prompt           # [Part 3] custom slash command — TRACKED
│       ├── explain-architecture.prompt     # [Part 3] custom slash command — TRACKED
│       ├── security-review.prompt          # [Part 3 exercise] custom slash command — TRACKED
│       └── fix-last-test-failure.prompt    # [Part 5] bridges CLI capture into Continue — TRACKED
├── .continueignore                         # [Part 2] excludes noise + secrets from indexing — TRACKED
├── .opencode/                              # OpenCode CLI workspace config
│   ├── opencode.json                       # [Part 4/6] provider, model, permission, ignore config — TRACKED
│   └── AGENTS.md                           # [Part 4] project conventions for the CLI agent — TRACKED
├── scripts/
│   └── ai/
│       ├── scaffold-route.sh               # [Part 4] boilerplate automation — TRACKED
│       ├── explain-file.sh                 # [Part 4 exercise] doc generation — TRACKED
│       ├── test-and-fix.sh                 # [Part 5] agentic test-fix loop — TRACKED
│       ├── lint-and-fix.sh                 # [Part 5] agentic lint-fix loop — TRACKED
│       ├── capture-test-failure.sh         # [Part 5] CLI-to-GUI bridge, capture half — TRACKED
│       └── test-and-fix-retry.sh           # [Part 5 exercise] capped retry loop — TRACKED
├── docs/
│   └── generated/
│       └── *.explained.md                  # [Part 4] AI-generated docs — TRACKED once reviewed, see Appendix C
├── reports/
│   └── unvalidated-input-audit.json        # [Part 4] AI-generated audit artifact — TRACKED once reviewed
├── src/
│   ├── api/
│   │   ├── routes/
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── middleware/
│   │   └── db/
│   └── web/
│       ├── components/
│       └── hooks/
├── .env.example                            # [Part 6] placeholder keys only — TRACKED
├── .env                                    # [Part 6] real secrets — GITIGNORED, never tracked, never synced
├── .gitignore                              # [Part 6] must agree with .continueignore + opencode.json ignore
└── package.json
```

Rule of thumb encoded in this tree: every file whose job is "tell the AI tooling how to behave" is tracked in git and reviewed like any other source file. Every file whose job is "hold a secret or hold transient/generated scratch output" is excluded from both git and from the AI tools' own indexing (Part 6).

---

## Appendix B — Configuration Cheat Sheet

### B.1 Adding a Custom Slash Command (Continue.dev)

| Step | Action |
|---|---|
| 1 | Create a new file at `.continue/prompts/<command-name>.prompt` |
| 2 | Add YAML frontmatter with `name:` (must match filename, no leading slash) and `description:` |
| 3 | Write the prompt body in plain markdown; use `{{{ input }}}` where the user's typed argument should be inserted |
| 4 | Use `@file`, `@codebase`, `@folder`, `@diff`, `@terminal`, `@git-log` inside the prompt body freely — they resolve at call time |
| 5 | Run `Continue: Reload Config` from the command palette |
| 6 | Type `/` in the chat input to confirm it appears in the picker |
| Short one-liner alternative | Add an inline block under `prompts:` in `config.yaml` instead of a file |

### B.2 Swapping Models in Continue.dev

| Step | Action |
|---|---|
| 1 | Open `.continue/config.yaml` |
| 2 | Add a new entry under `models:` with `name`, `provider`, `model`, and `roles` (`chat`, `edit`, `autocomplete`, `embed`) |
| 3 | For local models: `provider: ollama`, and first run `ollama pull <model>` in the terminal |
| 4 | For API models: `provider: anthropic` / `openrouter` / etc., set `apiKey: ${{ secrets.YOUR_KEY_NAME }}`, then set the real value in Continue's local secrets store or `~/.continue/.env`, never inline |
| 5 | Run `Continue: Reload Config` |
| 6 | Use the model dropdown at the top of the chat panel to switch per-conversation; role assignment (`roles:`) controls which dropdown/feature the model appears under |

### B.3 Common OpenCode CLI Flags

| Flag | Effect |
|---|---|
| `opencode` | Launch interactive TUI session in the current directory |
| `opencode run "<prompt>"` | Non-interactive, one-shot prompt, exits after responding |
| `--model <provider/model>` | Override the default model for this one invocation |
| `--cwd <path>` | Run against a directory other than the current one |
| `--quiet` | Suppress TUI chrome/progress noise, print result only — needed for piping |
| `--output-format json` \| `text` | Control output shape for scripting vs. human reading |
| `opencode auth login` | Configure/refresh an API provider's credentials |
| (config) `permission.edit` / `permission.bash` | `"ask"` (default, safe) vs. `"allow"` — see Part 6, do not set to allow lightly |
| (config) `ignore: [...]` | Excludes paths from the agent's file reads, same purpose as `.continueignore` |

---

## Appendix C — Deployment/Setup Checklist: Syncing AI Tooling Across Machines via Git

Goal: a second machine (new laptop, teammate's machine, CI runner) should be able to clone the repo and have an equivalent AI-assisted setup in minutes, with zero secrets ever transiting through git.

### C.1 What Gets Committed to the Repo (once, by whoever sets it up first)

- [ ] `.continue/config.yaml` — models list uses `${{ secrets.* }}` placeholders for any API key field, never a literal key
- [ ] `.continue/rules/project-conventions.md`
- [ ] `.continue/prompts/*.prompt` — all custom slash commands
- [ ] `.continueignore`
- [ ] `.opencode/opencode.json` — same rule: provider blocks reference env vars, never literal keys
- [ ] `.opencode/AGENTS.md`
- [ ] `scripts/ai/*.sh` — and confirm they are executable (`git update-index --chmod=+x scripts/ai/*.sh` if needed, since file mode bits can be lost across some transfer methods)
- [ ] `.gitignore` updated to exclude `.env`, `.env.*` (except `.env.example`), `secrets/`, `*.pem`, `*.key`, and `.continue/.last-test-failure.txt`
- [ ] `.env.example` — lists every required variable name with a placeholder value, so a new machine knows exactly what to provision

### C.2 What Never Gets Committed (per-machine, per-developer)

- [ ] Real API keys (`ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, etc.) — set via shell profile export or a local `.env` sourced by your shell
- [ ] Continue's local secrets store (`~/.continue/.env` or the local secrets UI) — this lives outside the repo entirely, at the user/global level, by design
- [ ] The local Continue codebase index cache (LanceDB store) — regenerated automatically per machine, never portable/needed in git
- [ ] `.opencode` session/auth state written outside `.opencode/opencode.json` (check `opencode auth` docs for the exact local credentials path on your OS) — re-authenticate per machine instead

### C.3 New Machine Setup Sequence

1. Clone the repo: `git clone <repo-url> && cd acme-widgets`
2. Install Ollama, then pull the models referenced in `.continue/config.yaml` and `.opencode/opencode.json`:
   `ollama pull qwen2.5-coder:7b && ollama pull qwen2.5-coder:1.5b-base && ollama pull nomic-embed-text`
3. Install the Continue.dev VS Code extension: `code --install-extension continue.continue`
4. Open the repo in VS Code, run `Continue: Reload Config`, confirm the model picker shows the expected names from `config.yaml`
5. If using any API model: set the real key locally (shell export or Continue's local secrets store), never paste it into a tracked file
6. Install OpenCode CLI: `npm install -g opencode-ai`
7. From the repo root, run `opencode` once; confirm it picks up `.opencode/opencode.json` and `.opencode/AGENTS.md`
8. If using an API provider with OpenCode, run `opencode auth login` and authenticate; this stores credentials outside the repo
9. Run `Continue: Rebuild Codebase Index` to build the local embeddings index fresh on this machine (Part 2) — this step is always per-machine, never synced
10. Sanity check both tools with a trivial prompt each (`@codebase what does this repo do` in Continue; `opencode run "what does this repo do" --quiet` in the terminal) and confirm both return sensible, repo-specific answers
11. Confirm `chmod +x` is intact on every file under `scripts/ai/` (`ls -l scripts/ai/`); re-apply if git stripped execute bits during transfer

### C.4 Periodic Drift Check (Run Monthly or After Onboarding Anyone New)

- [ ] Diff `.continueignore`, `.gitignore`, and `.opencode/opencode.json`'s `ignore` block against each other — they must always agree on what's excluded, per Part 6
- [ ] Confirm `.continue/rules/project-conventions.md` and `.opencode/AGENTS.md` haven't drifted apart in stated conventions — they should say the same things about the same codebase
- [ ] Re-pull local models if newer versions have been released (`ollama pull <model>` is safe to re-run, it updates in place)
- [ ] Spot-check that no one has accidentally loosened `permission.edit` or `permission.bash` to `"allow"` in a committed `opencode.json`
