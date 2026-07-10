# Phase 2: The Agentic Core 

<Step number="2.1" title="The Free-Tier Model Registry (Provider Abstraction)">
<Explanation>
This is the heart of the "model agility" pillar. Groq, Together AI, and Hugging Face's Inference API all speak the OpenAI Chat Completions wire format, so instead of writing three separate SDK integrations we use ONE package — `@ai-sdk/openai-compatible` — and parameterize it per-provider with just a `baseURL` and an API key env var name. `MODEL_REGISTRY` is a flat array of UI-selectable options; each entry knows its own provider, display label, and underlying model id string. `resolveModel(modelValue)` turns a registry `value` (e.g. `"groq:llama-3.3-70b-versatile"`) into a live AI SDK `LanguageModel` instance. Every other file in the agent (system prompt, agent loop, API route, tests) depends only on this function — never on a specific provider SDK directly. Adding a fourth free provider later means adding one entry to `PROVIDERS` and a few lines to `MODEL_REGISTRY`. No other file changes.
</Explanation>

<Code language="typescript" title="src/lib/agent/models.ts">
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";
import type { LanguageModel } from "ai";

export type ProviderId = "groq" | "together" | "huggingface";

interface ProviderConfig {
  id: ProviderId;
  label: string;
  baseURL: string;
  apiKeyEnvVar: string;
}

// One entry per free-tier provider. To add a new OpenAI-compatible free
// provider, add a config here and one or more MODEL_REGISTRY entries below —
// nothing else in the codebase needs to change.
const PROVIDERS: Record<ProviderId, ProviderConfig> = {
  groq: {
    id: "groq",
    label: "Groq",
    baseURL: "https://api.groq.com/openai/v1",
    apiKeyEnvVar: "GROQ_API_KEY",
  },
  together: {
    id: "together",
    label: "Together AI",
    baseURL: "https://api.together.xyz/v1",
    apiKeyEnvVar: "TOGETHER_API_KEY",
  },
  huggingface: {
    id: "huggingface",
    label: "Hugging Face",
    baseURL: "https://api-inference.huggingface.co/v1",
    apiKeyEnvVar: "HUGGINGFACE_API_KEY",
  },
};

export interface ModelOption {
  /** Stable id sent from the client, format "<providerId>:<modelId>" */
  value: string;
  /** Human-readable label for the UI dropdown */
  label: string;
  provider: ProviderId;
  modelId: string;
  /** Short blurb shown in the UI to help users pick */
  description: string;
}

// The list that powers the <ModelSelector /> dropdown in Phase 3.
// Every value here MUST be provider:modelId so resolveModel() can parse it.
export const MODEL_REGISTRY: ModelOption[] = [
  {

    value: "groq:llama-3.3-70b-versatile",

    label: "Llama 3.3 70B (Groq)",

    provider: "groq",

    modelId: "llama-3.3-70b-versatile",

    description: "Best all-round quality/speed balance. Recommended default.",

  },

  {

    value: "groq:llama-3.1-8b-instant",

    label: "Llama 3.1 8B Instant (Groq)",

    provider: "groq",

    modelId: "llama-3.1-8b-instant",

    description: "Fastest option, lower reasoning quality. Good for quick tests.",

  },

  {

    value: "together:meta-llama/Llama-3.3-70B-Instruct-Turbo-Free",

    label: "Llama 3.3 70B Turbo (Together, Free)",

    provider: "together",

    modelId: "meta-llama/Llama-3.3-70B-Instruct-Turbo-Free",

    description: "Together AI's always-free Turbo endpoint.",

  },

  {

    value: "huggingface:meta-llama/Llama-3.1-8B-Instruct",

    label: "Llama 3.1 8B Instruct (Hugging Face)",

    provider: "huggingface",

    modelId: "meta-llama/Llama-3.1-8B-Instruct",

    description: "Runs on HF's serverless Inference API free tier.",

  },

];

export function getDefaultModelValue(): string {
  return process.env.DEFAULT_MODEL_ID ?? MODEL_REGISTRY[0].value;
}

export function isKnownModelValue(value: string): boolean {
  return MODEL_REGISTRY.some((m) => m.value === value);
}

/**
 * Turns a registry value like "groq:llama-3.3-70b-versatile" into a live
 * AI SDK LanguageModel, wiring up the correct base URL and API key for
 * whichever free provider it belongs to.
 */
export function resolveModel(modelValue: string): LanguageModel {
  const option = MODEL_REGISTRY.find((m) => m.value === modelValue);

  if (!option) {
    throw new Error(
      `Unknown model "${modelValue}". Must be one of: ${MODEL_REGISTRY.map((m) => m.value).join(", ")}`
    );
  }

  const providerConfig = PROVIDERS[option.provider];
  const apiKey = process.env[providerConfig.apiKeyEnvVar];

  if (!apiKey) {
    throw new Error(
      `Missing ${providerConfig.apiKeyEnvVar}. Set it in .env.local to use ${providerConfig.label} models.`
    );
  }

  const provider = createOpenAICompatible({
    name: providerConfig.id,
    baseURL: providerConfig.baseURL,
    apiKey,
  });

  return provider.chatModel(option.modelId);
}
</Code>

<Explanation>
Note that `resolveModel` throws a clear, actionable error the moment a required key is missing — this fails fast during development instead of surfacing as an opaque 401 deep inside a streamed response. The `value` strings (`"groq:llama-3.3-70b-versatile"`) are the exact same strings sent from the client-side `<ModelSelector />` in Phase 3 and validated again server-side in the `/api/chat` route in Step 2.5 — never trust the client blindly, always re-validate with `isKnownModelValue`.
</Explanation>
</Step>

---

**Step 2.2: The Tavily Web Search Tool**.

---

<Step number="2.2" title="The Tavily Web Search Tool">
<Explanation>
This is the agent's first tool: a Zod-validated, typed AI SDK `tool()` definition wrapping the Tavily Search API. Tavily is purpose-built for LLM agents — it returns clean, pre-summarized web results (rather than raw HTML), which reduces token usage and keeps the model's context focused. The `execute` function is a plain async function; the Vercel AI SDK's tool loop calls it automatically whenever the model emits a tool call for `"webSearch"`, then feeds the return value back into the conversation as a tool result. We keep this function pure and side-effect-free (aside from the network call) so it is trivially unit-testable in Phase 5 by mocking `fetch`.
</Explanation>

<Code language="typescript" title="src/lib/agent/tools/tavily-search.ts">
import { tool } from "ai";
import { z } from "zod";

export interface TavilySearchResultItem {
  title: string;
  url: string;
  content: string;
  score: number;
}

export interface TavilySearchResponse {
  query: string;
  results: TavilySearchResultItem[];
}

const TAVILY_API_URL = "https://api.tavily.com/search";

/**
 * Calls the Tavily Search API directly. Extracted from the tool definition
 * so it can be unit tested in isolation (see Phase 5).
 */
export async function performTavilySearch(
  query: string,
  maxResults: number = 5
): Promise<TavilySearchResponse> {
  const apiKey = process.env.TAVILY_API_KEY;

  if (!apiKey) {
    throw new Error("TAVILY_API_KEY is not set. Add it to .env.local.");
  }

  const response = await fetch(TAVILY_API_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      api_key: apiKey,
      query,
      max_results: maxResults,
      search_depth: "basic",
      include_answer: false,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Tavily search failed (${response.status}): ${errorText}`);
  }

  const data = await response.json();

  return {
    query,
    results: (data.results ?? []).map((r: any) => ({
      title: r.title,
      url: r.url,
      content: r.content,
      score: r.score,
    })),
  };
}

export const webSearchTool = tool({
  description:
    "Search the live web for up-to-date information on a topic. Returns a list of relevant pages with titles, URLs, and short content snippets. Use this first before scraping a specific page.",
  inputSchema: z.object({
    query: z.string().describe("The search query, phrased as a specific question or topic."),
    maxResults: z
      .number()
      .int()
      .min(1)
      .max(10)
      .default(5)
      .describe("Maximum number of results to return (1-10)."),
  }),
  execute: async ({ query, maxResults }) => {
    const result = await performTavilySearch(query, maxResults);
    return result;
  },
});
</Code>

<Explanation>
Two deliberate design choices: (1) `performTavilySearch` is exported separately from the `tool()` wrapper so Phase 5's tests can call it directly with a mocked `fetch`, without needing to spin up the full AI SDK tool-calling machinery. (2) The Zod `inputSchema` description strings aren't just documentation — the model reads them verbatim as part of deciding how and when to call this tool, so precise wording here directly affects agent behavior.
</Explanation>
</Step>

---
**Step 2.3: The Firecrawl Web Scrape Tool**.

---

<Step number="2.3" title="The Firecrawl Web Scrape Tool">
<Explanation>
The second tool gives the agent the ability to go deeper than a search snippet: fetch and read the full content of a specific URL, converted to clean Markdown. Firecrawl handles JS-rendered pages, paywalls-permitting content, and boilerplate stripping, which raw `fetch` + HTML parsing cannot reliably do. The agent typically calls `webSearchTool` first, inspects the returned URLs, then calls `scrapeUrlTool` on the one or two most promising links before synthesizing an answer — this two-step pattern (search → scrape) is what makes it a genuine agentic loop rather than a single RAG lookup, and is reinforced in the system prompt (Step 2.4).
</Explanation>

<Code language="typescript" title="src/lib/agent/tools/firecrawl-scrape.ts">
import { tool } from "ai";
import { z } from "zod";

export interface FirecrawlScrapeResult {
  url: string;
  title: string | null;
  markdown: string;
}

const FIRECRAWL_API_URL = "https://api.firecrawl.dev/v1/scrape";

// Cap content length so a single scraped page can't blow out the model's
// context window or waste tool-loop tokens.
const MAX_MARKDOWN_LENGTH = 8000;

/**
 * Calls the Firecrawl Scrape API directly. Extracted from the tool
 * definition so it can be unit tested in isolation (see Phase 5).
 */
export async function performFirecrawlScrape(
  url: string
): Promise<FirecrawlScrapeResult> {
  const apiKey = process.env.FIRECRAWL_API_KEY;

  if (!apiKey) {
    throw new Error("FIRECRAWL_API_KEY is not set. Add it to .env.local.");
  }

  const response = await fetch(FIRECRAWL_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      url,
      formats: ["markdown"],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Firecrawl scrape failed (${response.status}): ${errorText}`);
  }

  const data = await response.json();
  const rawMarkdown: string = data?.data?.markdown ?? "";
  const title: string | null = data?.data?.metadata?.title ?? null;

  return {
    url,
    title,
    markdown:
      rawMarkdown.length > MAX_MARKDOWN_LENGTH
        ? `${rawMarkdown.slice(0, MAX_MARKDOWN_LENGTH)}\n\n[...truncated]`
        : rawMarkdown,
  };
}

export const scrapeUrlTool = tool({
  description:
    "Fetch the full content of a specific web page as clean Markdown. Use this after webSearch to read the full text of a promising result, rather than relying on the short snippet alone.",
  inputSchema: z.object({
    url: z.string().url().describe("The exact URL to scrape, typically taken from a prior webSearch result."),
  }),
  execute: async ({ url }) => {
    const result = await performFirecrawlScrape(url);
    return result;
  },
});
</Code>

<Explanation>
Truncating scraped Markdown to `MAX_MARKDOWN_LENGTH` is a deliberate cost/reliability control: free-tier model context windows and Firecrawl's own free credits are both finite, so capping per-scrape content prevents one long article from derailing an entire agent run. This constant is intentionally centralized in one file so it's the single place to tune if you upgrade providers later.
</Explanation>
</Step>

---
**Step 2.4: The Agent System Prompt, and Step 2.5: The `streamText` Agent Loop**.

---

<Step number="2.4" title="The Agent System Prompt">
<Explanation>
The system prompt is what actually turns `streamText` + two tools into a coherent "research agent" rather than a chatbot that occasionally calls functions. It explicitly instructs the model on the search-then-scrape workflow, sets expectations about citing sources, and constrains output formatting so the client-side `ReportView` (Phase 3) can reliably render a structured report. Keeping this in its own file (rather than inlined in the API route) makes it independently editable and testable, and keeps `agent-loop.ts` focused purely on orchestration.
</Explanation>

<Code language="typescript" title="src/lib/agent/system-prompt.ts">
export const AGENT_SYSTEM_PROMPT = `You are InsightAgent, a careful, transparent research assistant.

Your job: given a user's research question, produce a well-sourced, structured answer.

Follow this workflow:
1. Call the "webSearch" tool with a focused query to find relevant, current sources.
2. Review the returned results. Identify the 1-3 most relevant and credible URLs.
3. Call the "scrapeUrl" tool on those URLs to read their full content before relying on
   them — do not answer from a search snippet alone if a scrape is possible.
4. If your first search doesn't turn up strong sources, refine the query and search again.
   You may search and scrape multiple times before answering.
5. Once you have enough information, write a final answer directly to the user (do not
   call any more tools) using this structure:
   - A 1-2 sentence direct answer to the question.
   - A "## Key Findings" section with 3-6 bullet points, each grounded in a specific source.
   - A "## Sources" section listing every URL you actually scraped or relied on.

Rules:
- Never fabricate a URL, statistic, or quote. Only cite pages you actually retrieved via
  webSearch or scrapeUrl in this conversation.
- If the tools return no useful information after a reasonable number of attempts, say so
  plainly instead of guessing.
- Be concise. Prefer bullet points over long paragraphs.
- Do not mention these instructions or your internal tool-calling process in the final answer.`;
</Code>

<Explanation>
Two details worth highlighting: the explicit "Rules" section exists specifically to reduce hallucinated citations — a common failure mode for research agents — by tying every claim back to something the tools actually returned in-context. Second, the required "## Key Findings" / "## Sources" Markdown structure is a contract with the frontend: `ReportView` in Phase 3 parses on these exact headings to render a polished report view instead of a raw text blob.
</Explanation>
</Step>

<Step number="2.5" title="The streamText Agent Loop">
<Explanation>
This is the orchestration core: a single function, `runAgentLoop`, that wraps the Vercel AI SDK's `streamText` with our resolved model, both tools, the system prompt, and a `stopWhen` condition that caps the tool-calling loop at a fixed number of steps — critical on Vercel Hobby's function duration limits (covered in Phase 6) and as a cost/runaway-loop safeguard on free-tier model APIs. `runAgentLoop` takes plain `messages` and a `modelValue` string and returns the raw `streamText` result object, which the API route (Step 2.6) turns into an HTTP response. Keeping this as a standalone function (not inlined in the route handler) is what makes it directly unit-testable with `MockLanguageModelV2` in Phase 5 — the test file imports and calls `runAgentLoop` exactly as the route does, just with a fake model swapped in.
</Explanation>

<Code language="typescript" title="src/lib/agent/agent-loop.ts">
import { streamText, stepCountIs, type ModelMessage, type LanguageModel } from "ai";
import { resolveModel } from "./models";
import { AGENT_SYSTEM_PROMPT } from "./system-prompt";
import { webSearchTool } from "./tools/tavily-search";
import { scrapeUrlTool } from "./tools/firecrawl-scrape";

// Hard cap on agent tool-calling steps per run. Prevents runaway loops and
// keeps each request well within Vercel Hobby's function duration limits.
const MAX_AGENT_STEPS = 8;

export interface RunAgentLoopOptions {
  messages: ModelMessage[];
  modelValue: string;
  /** Allows tests to inject a fake LanguageModel directly, bypassing resolveModel(). */
  modelOverride?: LanguageModel;
}

export function runAgentLoop({ messages, modelValue, modelOverride }: RunAgentLoopOptions) {
  const model = modelOverride ?? resolveModel(modelValue);

  return streamText({
    model,
    system: AGENT_SYSTEM_PROMPT,
    messages,
    tools: {
      webSearch: webSearchTool,
      scrapeUrl: scrapeUrlTool,
    },
    stopWhen: stepCountIs(MAX_AGENT_STEPS),
  });
}
</Code>

<Explanation>
The `modelOverride` parameter is the key testability seam for Phase 5: production code (the API route) never passes it, always relying on `resolveModel(modelValue)`, but `agent-loop.test.ts` passes a `MockLanguageModelV2` instance directly, completely bypassing real network calls, real API keys, and any free-tier rate limits. `stepCountIs(MAX_AGENT_STEPS)` is the AI SDK's built-in stop condition — once the model has taken 8 steps (a step = either a tool call or a final text response) the loop force-stops even if the model wants to keep calling tools, guaranteeing an upper bound on latency and cost per request.
</Explanation>
</Step>

---

**Step 2.6: The `/api/chat` Route Handler.** 

---

<Step number="2.6" title="The /api/chat Route Handler">
<Explanation>
This Route Handler is the HTTP boundary that ties everything in Phase 2 together: it authenticates the request with Clerk's async `auth()`, parses and validates the incoming model selection against `MODEL_REGISTRY` (never trusting the client value blindly — see Step 2.1), converts the incoming UI messages to the AI SDK's model message format, invokes `runAgentLoop`, and streams the response back using `toUIMessageStreamResponse()` so the client's `useChat` hook (Phase 3) can consume it incrementally, including tool-call/tool-result parts that power the live `ThoughtDashboard`. We deliberately run this on the Node.js runtime (not Edge) because the Tavily/Firecrawl fetch calls plus multi-step tool loop can exceed Edge's stricter execution model in some configurations — Phase 6 revisits this tradeoff for Vercel Hobby's limits.
</Explanation>

<Code language="typescript" title="src/app/api/chat/route.ts">
import { auth } from "@clerk/nextjs/server";
import { convertToModelMessages, type UIMessage } from "ai";
import { NextResponse } from "next/server";
import { runAgentLoop } from "@/lib/agent/agent-loop";
import { getDefaultModelValue, isKnownModelValue } from "@/lib/agent/models";

export const runtime = "nodejs";
export const maxDuration = 60;

interface ChatRequestBody {
  messages: UIMessage[];
  modelValue?: string;
}

export async function POST(req: Request) {
  const { userId } = await auth();

  if (!userId) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let body: ChatRequestBody;

  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return NextResponse.json({ error: "messages must be a non-empty array" }, { status: 400 });
  }

  const requestedModel = body.modelValue;
  const modelValue =
    requestedModel && isKnownModelValue(requestedModel)
      ? requestedModel
      : getDefaultModelValue();

  try {
    const result = runAgentLoop({
      messages: convertToModelMessages(body.messages),
      modelValue,
    });

    return result.toUIMessageStreamResponse();
  } catch (error) {
    console.error("Agent loop failed:", error);
    const message = error instanceof Error ? error.message : "Unknown agent error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
</Code>

<Explanation>
Note the silent fallback behavior: if a client sends an unrecognized or missing `modelValue`, the route does not error — it falls back to `getDefaultModelValue()` and proceeds. This is a deliberate UX choice (a stale client-side dropdown value should never hard-fail a request) but it does mean the actually-used model may differ from what the client requested; Phase 3's `ThoughtDashboard` surfaces which model was used per-run so this is never silently invisible to the user. `maxDuration = 60` explicitly documents our assumption about Vercel Hobby's serverless function timeout, revisited and justified in Phase 6.
</Explanation>
</Step>

<Explanation>
This completes Phase 2. You now have a fully functional, provider-agnostic agentic core: a model registry spanning three free-tier providers, two working tools (Tavily search, Firecrawl scrape), a system prompt enforcing a search-then-scrape research workflow with citation discipline, an orchestrating agent loop with a hard step cap, and an authenticated streaming API route. At this point you can test the backend directly with a tool like `curl` or Postman (POST to `/api/chat` with a Clerk session cookie and a `messages` array) and watch a real multi-step agent run happen server-side.
</Explanation>

---

**Phase 2 complete.** Ready for Phase 3: UI & Streaming (Chat UI, `ModelSelector`, `ThoughtDashboard`, `ReportView`) 
