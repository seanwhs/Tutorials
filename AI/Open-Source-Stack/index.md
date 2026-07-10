# Leveraging the Open-Source AI Stack: OpenCode CLI & Continue.dev
### A Staff-Engineer Tutorial Series — INDEX

**Prefix for all notes in this series:** ``

---

## 1. Premise

Every dev has "chatted with an LLM" in a browser tab. That is not engineering — it's a slow, copy-paste-driven side channel that never touches your actual file system, your actual terminal, or your actual git history. It breaks flow, forces context-switching, and produces code that has to be manually reconciled with what's already in your repo.

This series teaches the alternative: **agentic local development**, where the LLM is wired directly into your editor and your shell, reads your actual codebase as context, and can act on it (open files, propose diffs, run commands) — while you stay the reviewer and final decision-maker.

We use exactly two tools, both free/open-source, that together cover the two places developers actually spend time:

| Surface | Tool | Role |
|---|---|---|
| The editor (VS Code) | **Continue.dev** | Open-source AI coding assistant extension. Chat, autocomplete, custom slash commands, context providers, model-agnostic. |
| The terminal | **OpenCode CLI** | Open-source, model-agnostic agentic coding CLI. Project-wide analysis, refactors, automation, scriptable. |

Both tools are **model-agnostic by design** — they don't lock you into a vendor. You can point them at:

- **Ollama** running locally (Llama 3.1, Qwen2.5-Coder, DeepSeek-Coder-V2, etc.) — zero cost, zero data leaves your machine.
- **Free-tier hosted APIs** (Anthropic, OpenAI, or OpenRouter free models) when you need a stronger model for a hard problem.

Nothing in this series requires a paid subscription to either tool.

---

## 2. What We're Building Toward

1. VS Code fully wired to Continue.dev, switchable between a local Ollama model and a hosted API model, controlled by a single `config.yaml`.
2. A repository-aware assistant that correctly indexes your project and answers architecture questions without manual pasting.
3. A library of **custom slash commands** (`/refactor-to-async`, `/generate-tests`, `/explain-architecture`) encoding repetitive review/refactor patterns as reusable, versioned prompts.
4. Command-line fluency with **OpenCode CLI** — natural-language queries, boilerplate generation, scripting AI calls into shell pipelines.
5. A working **agentic loop**: OpenCode runs tests/linters, captures failures, and feeds them into a fix proposal — with human review before anything lands.
6. Production-grade discipline around secrets, architecture-change prompting, and non-negotiable human review points.

---

## 3. Stack & Prerequisites (Explicit, Free-Only)

| Component | Tool | Cost | Notes |
|---|---|---|---|
| Editor | VS Code | Free | Any recent version |
| AI extension | Continue.dev | Free, OSS (Apache 2.0) | `continue.continue` in Marketplace |
| CLI agent | OpenCode CLI | Free, OSS | `opencode-ai` on npm, or standalone binary |
| Local model runtime | Ollama | Free, OSS | Runs models on your own hardware |
| Local models | `qwen2.5-coder:7b`, `deepseek-coder-v2:16b`, `llama3.1:8b` | Free | Sized to your hardware |
| Hosted model (optional) | Anthropic Claude or OpenRouter free-tier | Free tier | Only for harder reasoning tasks |
| OS | macOS / Linux / Windows (WSL2 recommended) | — | Commands shown for bash |
| Sample repo | Any Node/TS project | — | Generic Express + React repo used throughout |

---

## 4. Series Structure

| Part | Title | Core Question Answered |
|---|---|---|
| 1 | The AI-Assisted IDE | How do I install Continue.dev and choose between local (Ollama) and API models? |
| 2 | Deep Context & Indexing | How does Continue actually "read" my repo, and how do I configure that? |
| 3 | Customizing the Workflow | How do I encode repetitive tasks as reusable slash commands? |
| 4 | OpenCode CLI Mastery | How do I use the terminal, not the GUI, for whole-codebase AI operations? |
| 5 | Agentic Loops | How do I chain CLI tool output back into an AI fix-it loop safely? |
| 6 | Production-Grade Habits | How do I use all this without leaking secrets or shipping unreviewed architecture changes? |

**Appendices** (in the final note):
- **Appendix A** — Codebase Reference: file tree of where every config file lives.
- **Appendix B** — Configuration Cheat Sheet: quick-reference tables.
- **Appendix C** — Deployment/Setup Checklist: syncing AI tooling config across machines via Git.

---

## 5. Note Index (This Series)

- `INDEX (Start Here)` *(this note)*
- `Part 1: The AI-Assisted IDE`
- `Part 2: Deep Context & Indexing`
- `Part 3: Customizing the Workflow`
- `Part 4: OpenCode CLI Mastery`
- `Part 5: Agentic Loops`
- `Part 6: Production-Grade Habits`
- `Appendices (A: File Tree, B: Cheat Sheet, C: Multi-Machine Sync)`

---

## 6. Reference Repo Layout Used Throughout

```text
acme-widgets/
├── .continue/                  # Continue.dev workspace config (Part 1-3)
│   ├── config.yaml
│   ├── rules/
│   │   └── project-conventions.md
│   └── prompts/
│       ├── refactor-to-async.prompt
│       ├── generate-tests.prompt
│       └── explain-architecture.prompt
├── .opencode/                  # OpenCode CLI workspace config (Part 4-5)
│   ├── opencode.json
│   └── commands/
│       └── fix-lint.sh
├── scripts/
│   └── ai/
│       ├── test-and-fix.sh     # Part 5 agentic loop script
│       └── lint-and-fix.sh
├── src/
│   ├── api/
│   │   ├── routes/
│   │   ├── controllers/
│   │   └── db/
│   └── web/
│       ├── components/
│       └── hooks/
├── .env.example
├── .env                        # gitignored — never synced (see Part 6 + Appendix C)
├── .gitignore
└── package.json
```

