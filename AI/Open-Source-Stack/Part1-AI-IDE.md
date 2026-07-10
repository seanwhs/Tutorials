# Part 1: The AI-Assisted IDE

**Series:** Leveraging the Open-Source AI Stack | **Prev:** [INDEX] | **Next:** Part 2 — Deep Context & Indexing

---

## 1. Concept

Continue.dev is an open source VS Code (and JetBrains) extension that turns your editor into a model-agnostic AI pair programmer. It is not tied to any single vendor: you configure it to talk to whatever model you want, local or remote.

Two integration modes matter most:

- **Chat panel**: ask questions about code, request refactors, get explanations.
- **Inline autocomplete**: fill-in-the-middle suggestions as you type, powered by a separate (usually smaller, faster) model.

## 2. Installing Continue.dev

Steps:

1. Open VS Code Extensions panel (Ctrl+Shift+X or Cmd+Shift+X).
2. Search for "Continue".
3. Install the extension published by Continue Dev Inc, id `continue.continue`.
4. Reload VS Code.
5. A new Continue icon appears in the Activity Bar (left sidebar).

Command line install alternative:

```bash
code --install-extension continue.continue
```

## 3. Installing Ollama and Pulling Models

Ollama runs models entirely on your machine.

**macOS / Linux:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Windows:** download the installer from ollama.com/download

Verify:
```bash
ollama --version
```

Pull two models: one for chat/reasoning, one small and fast for autocomplete.

```bash
ollama pull qwen2.5-coder:7b
ollama pull qwen2.5-coder:1.5b-base
```

Confirm they are present:
```bash
ollama list
```

Start the Ollama server if it is not already running as a background service:
```bash
ollama serve
```

By default Ollama listens on `http://localhost:11434`.

## 4. Configuring Continue for Local Models

Continue reads a workspace or global config file. Modern Continue uses YAML at `.continue/config.yaml` (project-level) or `~/.continue/config.yaml` (global). Create the project-level file so config travels with the repo.

**File: `.continue/config.yaml`**

```yaml
name: acme-widgets-assistant
version: 1.0.0
schema: v1
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
```

Save the file, then reload the Continue panel (command palette: `Continue: Reload Config`). Open the chat panel, select **Qwen Coder 7B** from the model dropdown, and ask a test question such as "What does this repo do." You should get a response with zero network calls leaving your machine.

## 5. Configuring an API-Based Model (Free Tier Path)

Local models are private and free but weaker at hard multi-step reasoning. For those moments, wire in a hosted model using a free tier or free credits, without hardcoding the key in the file.

Add a second model block. Continue supports environment variable expansion for API keys.

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
  - name: Claude (API - Hard Problems)
    provider: anthropic
    model: claude-3-5-sonnet-latest
    apiKey: ${{ secrets.ANTHROPIC_API_KEY }}
    roles:
      - chat
```

Set the actual secret **outside** the tracked config, in Continue's local secrets store or a gitignored env file, never inline. In VS Code, run `Continue: Open Local Secrets` or edit `~/.continue/.env` directly:

```bash
ANTHROPIC_API_KEY=sk-ant-your-key-here
```

An OpenRouter free-model path works the same way and avoids needing a credit card at all:

```yaml
  - name: Llama 3.1 Free (OpenRouter)
    provider: openrouter
    model: meta-llama/llama-3.1-8b-instruct:free
    apiKey: ${{ secrets.OPENROUTER_API_KEY }}
    roles:
      - chat
```

## 6. Switching Models Mid-Session

The model dropdown at the top of the Continue chat panel lists every model block by its `name` field. Switching is instant, no restart required. This is the core workflow habit for Part 1: **default to the local model** for everyday work (privacy, zero cost, fast), and manually switch to the API model only when you hit a problem the local model struggles with (deep architectural reasoning, large multi-file refactors, ambiguous specs).

## 7. Sanity-Check Checklist

- `ollama list` shows both pulled models.
- `ollama serve` is running (or running as a system service).
- `.continue/config.yaml` is committed to the repo (secrets are not — see Part 6).
- `Continue: Reload Config` runs without error.
- Chat panel model dropdown shows all configured models by name.
- A test prompt against the local model returns a response with your machine offline from the API's perspective (airplane-mode test is a good sanity check).

## 8. Exercise Challenge

Add a third model entry pointing at a different local Ollama model of your choice (for example `deepseek-coder-v2:16b` if your hardware supports it) assigned **only** the `edit` role, and confirm it appears as a distinct selectable option in the Continue chat panel without affecting the existing chat or autocomplete role assignments.

## 9. Solution

```yaml
models:
  - name: DeepSeek Coder V2 (Local Edit)
    provider: ollama
    model: deepseek-coder-v2:16b
    roles:
      - edit
```

Append this block under the existing `models` list in `.continue/config.yaml`, run `Continue: Reload Config`, and verify the new name appears in the model picker. Because `roles` is scoped to `edit` only, it will not appear as an option for plain chat or for autocomplete — demonstrating that Continue treats each model block as independently addressable per capability rather than a single global model switch.

---

**Next: Part 2 — Deep Context & Indexing.**
