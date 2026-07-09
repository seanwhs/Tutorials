## AI SaaS Tutorial - Part 11: Free/Open LLM Provider Abstraction

*Next.js 16 note: no dynamic route params here for the registry/provider files; the chat route stays plain Request/Response. The client dropdown is a standard client component, no version-specific concerns.*

### Goal
Replace the single hardcoded model from Parts 9-10 with a proper in-code list of free models the user (or admin) can pick from, all accessed through one OpenAI-compatible interface via the Vercel AI SDK.

### 1. Why an abstraction layer
The Vercel AI SDK's `createOpenAICompatible` works with any provider exposing an OpenAI-style `/chat/completions` endpoint. That includes several genuinely free options:
- **Groq** — free API tier, extremely fast inference, hosts open models like Llama 3.1/3.3 and Gemma
- **OpenRouter** — aggregates many providers; several models are explicitly free (`:free` suffix models, subject to change — always check openrouter.ai/models?max_price=0 for the current free list)
- **Ollama** — 100% free, runs entirely locally, no rate limits, no internet dependency, but requires the user's machine (or server) to have Ollama installed

We define a single typed list in code so switching providers/models is a one-line config change, not a rewrite.

### 2. The free model registry
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
// available free options at the time of writing. Always double check the
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
    label: "Llama 3.3 70B (Groq, free tier, stronger)",
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
```

### 3. Getting free API keys
- **Groq**: console.groq.com → sign up free → API Keys → create one. Free tier includes generous request-per-minute limits, no credit card required at time of writing.
- **OpenRouter**: openrouter.ai → sign up free → Keys → create one. Filter models by `max_price=0` to see current free models.
- **Ollama**: no key needed, runs locally.

### 4. Environment variables
```bash
GROQ_API_KEY=xxx
OPENROUTER_API_KEY=xxx
DEFAULT_CHAT_MODEL_ID=ollama-llama3.1
```

### 5. Provider factory
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

### 6. Update the chat route to use the registry
`src/app/api/chat/route.ts` (relevant change from Part 10):
```ts
import { getModelInstance } from "@/lib/ai/provider";
import { DEFAULT_MODEL_ID } from "@/lib/ai/models";

const { messages, workspaceId, modelId }: {
  messages: UIMessage[];
  workspaceId: string;
  modelId?: string;
} = await req.json();

// ...

const result = streamText({
  model: getModelInstance(modelId ?? DEFAULT_MODEL_ID),
  system: systemPrompt,
  messages: convertToModelMessages(messages),
  onFinish: async ({ text }) => { /* unchanged from Part 10 */ },
});
```

### 7. Let users pick a model in the UI
```tsx
import { FREE_MODELS, DEFAULT_MODEL_ID } from "@/lib/ai/models";

const [modelId, setModelId] = useState(DEFAULT_MODEL_ID);

sendMessage({ text: input }, { body: { workspaceId, modelId } });

<select
  value={modelId}
  onChange={(e) => setModelId(e.target.value)}
  className="mb-2 rounded border px-2 py-1 text-sm"
>
  {FREE_MODELS.map((m) => (
    <option key={m.id} value={m.id}>
      {m.label}
    </option>
  ))}
</select>
```

**Checkpoint:** Switch the dropdown between Ollama and Groq (with a valid `GROQ_API_KEY` set), ask the same question, and confirm both return grounded answers. If a model errors, check that its provider's API key env var is set and that `requiresApiKey` matches reality.

**Next:** Part 12 — Stripe Billing & Subscription Plans.
