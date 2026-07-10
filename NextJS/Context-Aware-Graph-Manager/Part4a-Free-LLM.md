# Part 4a: Free LLM Provider Abstraction

Before we can build the extraction agent (Part 4b), we need a way to call an LLM that costs nothing to run through the entire tutorial, and that you can swap in one place without touching business logic.

## 1. Why an abstraction layer
The Vercel AI SDK's `createOpenAICompatible` adapter works with any provider exposing an OpenAI-style `/chat/completions` endpoint. Several genuinely free options exist:
- **Groq** — free API tier, extremely fast inference, hosts open models like Llama 3.1/3.3 and Gemma.
- **OpenRouter** — aggregates many providers; several models are explicitly free (`:free` suffix, subject to change — always check `openrouter.ai/models?max_price=0` for the current free list).
- **Ollama** — 100% free, runs entirely locally, no rate limits, no internet dependency, but requires Ollama installed wherever it runs.

For the extraction agent specifically, model choice matters more than in a typical chatbot: structured JSON extraction quality varies a lot between small local models and larger hosted ones. Keeping the model swappable in one file means you can start with local Ollama for free iteration, then flip to Groq's larger Llama 3.3 70B for a noticeably more accurate extraction pass, without touching the agent code at all.

## 2. The free model registry
`src/lib/ai/models.ts`:
```ts
export interface FreeModel {
  id: string;
  label: string;
  provider: "groq" | "openrouter" | "ollama";
  modelName: string;
  baseUrl: string;
  requiresApiKey: boolean;
}

// NOTE: Free-tier availability changes over time - this list reflects commonly
// available free options at the time of writing. Always double-check the
// provider's current pricing/model page before relying on one in production.
export const FREE_MODELS: FreeModel[] = [
  {
    id: "groq-llama-3.1-8b",
    label: "Llama 3.1 8B (Groq, free tier, fast)",
    provider: "groq",
    modelName: "llama-3.1-8b-instant",
    baseUrl: "https://api.groq.com/openai/v1",
    requiresApiKey: true,
  },
  {
    id: "groq-llama-3.3-70b",
    label: "Llama 3.3 70B (Groq, free tier, stronger - best for extraction)",
    provider: "groq",
    modelName: "llama-3.3-70b-versatile",
    baseUrl: "https://api.groq.com/openai/v1",
    requiresApiKey: true,
  },
  {
    id: "openrouter-free-llama",
    label: "Llama 3.1 (OpenRouter, free tier)",
    provider: "openrouter",
    modelName: "meta-llama/llama-3.1-8b-instruct:free",
    baseUrl: "https://openrouter.ai/api/v1",
    requiresApiKey: true,
  },
  {
    id: "ollama-llama3.1",
    label: "Llama 3.1 8B (Ollama, local, no API key)",
    provider: "ollama",
    modelName: "llama3.1",
    baseUrl: "http://localhost:11434/v1",
    requiresApiKey: false,
  },
];

export function getFreeModel(id: string): FreeModel {
  const model = FREE_MODELS.find((m) => m.id === id);
  if (!model) throw new Error(`Unknown model id: ${id}`);
  return model;
}

export const DEFAULT_MODEL_ID = "ollama-llama3.1";
export const EXTRACTION_MODEL_ID = process.env.EXTRACTION_MODEL_ID ?? DEFAULT_MODEL_ID;
```
`EXTRACTION_MODEL_ID` is separated from the general default so you can, for example, run chat/search UI on the fast local model while pointing the (less frequent, more accuracy-sensitive) extraction step at Groq's 70B model — just by setting one env var.

## 3. Getting free API keys
- **Groq**: console.groq.com -> sign up free -> API Keys -> create one. Generous free rate limits, no credit card required at time of writing.
- **OpenRouter**: openrouter.ai -> sign up free -> Keys -> create one. Filter models by `max_price=0` to see the current free list.
- **Ollama**: no key needed, runs locally (already installed in Part 3 for embeddings — the same install covers chat models, just `ollama pull llama3.1`).

```bash
ollama pull llama3.1
```

## 4. Environment variables
Add to `.env.local`:
```bash
GROQ_API_KEY=
OPENROUTER_API_KEY=
DEFAULT_MODEL_ID="ollama-llama3.1"
EXTRACTION_MODEL_ID="ollama-llama3.1"
```

## 5. Provider factory
`src/lib/ai/provider.ts`:
```ts
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";
import { getFreeModel } from "./models";

export function getModelInstance(modelId: string) {
  const model = getFreeModel(modelId);

  const apiKey =
    model.provider === "groq"
      ? process.env.GROQ_API_KEY
      : model.provider === "openrouter"
      ? process.env.OPENROUTER_API_KEY
      : "ollama";

  if (model.requiresApiKey && !apiKey) {
    throw new Error(`Missing API key for provider "${model.provider}"`);
  }

  const client = createOpenAICompatible({
    name: model.provider,
    baseURL: model.baseUrl,
    apiKey: apiKey!,
  });

  return client(model.modelName);
}
```
This is the single function every other part of the app calls to get a usable model instance — the extraction agent (Part 4b), and later any chat-style feature, both go through `getModelInstance()` and never touch provider-specific code directly.

## 6. Verification checkpoint
Quick standalone script to confirm the provider factory works before wiring it into the extraction agent. Create a throwaway file `src/scripts/test-model.ts`:
```ts
import { generateText } from "ai";
import { getModelInstance } from "@/lib/ai/provider";

async function main() {
  const model = getModelInstance(process.env.EXTRACTION_MODEL_ID ?? "ollama-llama3.1");
  const { text } = await generateText({
    model,
    prompt: "Say hello in exactly 3 words.",
  });
  console.log("Model responded:", text);
}

main();
```
Run it:
```bash
npx tsx src/scripts/test-model.ts
```
(If `tsx` isn't installed: `npm install -D tsx`.) Confirm you get a short text response back with no thrown errors. Delete the script once confirmed, or keep it around as a handy debugging tool when switching models later.

Next: Part 4b - AI-Agentic Extraction (Parsing Chunks into Nodes/Edges).
