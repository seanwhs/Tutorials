# Phase 5: Testing the Agent

<Step number="5.1" title="Vitest Configuration">
<Explanation>
We configure Vitest to run in a Node environment (matching our Route Handlers' `runtime = "nodejs"`), load `.env.local` automatically so tests can reference the same env vars as dev (though, as Step 5.2-5.4 show, well-designed tests mock network calls rather than hitting real free-tier APIs), and resolve the `@/*` path alias identically to `tsconfig.json` so test files can import application code with the same import paths used everywhere else in the app. Keeping test config minimal and dependency-light matters here — we intentionally avoid jsdom/browser-environment setup entirely, since everything under test (tools, agent loop) is server-side logic with no DOM dependency.
</Explanation>

<Code language="typescript" title="vitest.config.ts">
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "node",
    setupFiles: ["dotenv/config"],
    include: ["src/**/*.test.ts"],
    globals: false,
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
</Code>

<Explanation>
`globals: false` is a deliberate style choice: every test file explicitly imports `describe`, `it`, `expect`, and `vi` from `"vitest"` rather than relying on injected globals. This keeps test files self-documenting about their dependencies and avoids needing a separate `vitest/globals` types entry in `tsconfig.json`. Run `npm run test` for a single CI-style run or `npm run test:watch` during local development of new tests.
</Explanation>
</Step>

---

**Step 5.2: Unit Testing the Tavily Search Tool**.

---

<Step number="5.2" title="Unit Testing the Tavily Search Tool">
<Explanation>
Recall from Step 2.2 that `performTavilySearch` is exported separately from the `tool()` wrapper specifically to enable this kind of test: we mock the global `fetch` function with `vi.stubGlobal`, control exactly what the "Tavily API" returns, and assert that `performTavilySearch` correctly transforms that response into our `TavilySearchResponse` shape. No real network call, no real API key needed, no consumption of Tavily's free-tier credits — the test suite can run unlimited times in CI at zero cost. We cover three cases: a successful search with results, an API error response (non-2xx), and a missing API key, matching the three distinct code paths in `performTavilySearch`.
</Explanation>

<Code language="typescript" title="src/lib/agent/tools/tavily-search.test.ts">
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { performTavilySearch } from "./tavily-search";

describe("performTavilySearch", () => {
  beforeEach(() => {
    vi.stubEnv("TAVILY_API_KEY", "test-tavily-key");
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
  });

  it("returns parsed results on a successful search", async () => {

    const mockResponse = {

      results: [

        {

          title: "Solid-State Batteries Explained",

          url: "https://example.com/solid-state",

          content: "Solid-state batteries use a solid electrolyte...",

          score: 0.95,

        },

      ],

    };


    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => mockResponse,
      })
    );

    const result = await performTavilySearch("solid-state batteries", 5);

    expect(result.query).toBe("solid-state batteries");
    expect(result.results).toHaveLength(1);
    expect(result.results[0]).toEqual({
      title: "Solid-State Batteries Explained",
      url: "https://example.com/solid-state",
      content: "Solid-state batteries use a solid electrolyte...",
      score: 0.95,
    });

    expect(fetch).toHaveBeenCalledWith(
      "https://api.tavily.com/search",
      expect.objectContaining({ method: "POST" })
    );
  });

  it("throws a descriptive error when the API responds with a non-2xx status", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: false,
        status: 401,
        text: async () => "Invalid API key",
      })
    );

    await expect(performTavilySearch("test query")).rejects.toThrow(
      /Tavily search failed \(401\): Invalid API key/
    );
  });

  it("throws immediately when TAVILY_API_KEY is not set", async () => {
    vi.unstubAllEnvs();
    vi.stubEnv("TAVILY_API_KEY", "");

    await expect(performTavilySearch("test query")).rejects.toThrow(
      /TAVILY_API_KEY is not set/
    );
  });
});
</Code>

<Explanation>
Note the `beforeEach`/`afterEach` pair carefully resetting both stubbed globals and stubbed env vars between tests — without this, the "missing API key" test could pass or fail depending on test execution order, a classic source of flaky test suites. `vi.stubGlobal("fetch", ...)` replaces `fetch` for the duration of a single test only, which is safer than mutating `global.fetch` directly and forgetting to restore it.
</Explanation>
</Step>

---
**Step 5.3: Unit Testing the Firecrawl Scrape Tool**.

---

<Step number="5.3" title="Unit Testing the Firecrawl Scrape Tool">
<Explanation>
Mirroring Step 5.2's approach, we test `performFirecrawlScrape` directly with a mocked `fetch`, covering: a successful scrape, the truncation behavior for oversized Markdown content (the `MAX_MARKDOWN_LENGTH` guard from Step 2.3), an API error response, and a missing API key. The truncation test is the most valuable one here — it's the kind of edge case that's easy to introduce a silent bug in during refactors (e.g. an off-by-one in the slice boundary) and is exactly the sort of thing that's tedious to verify manually against a real long article but trivial to assert precisely with a synthetic oversized string.
</Explanation>

<Code language="typescript" title="src/lib/agent/tools/firecrawl-scrape.test.ts">
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { performFirecrawlScrape } from "./firecrawl-scrape";

describe("performFirecrawlScrape", () => {
  beforeEach(() => {
    vi.stubEnv("FIRECRAWL_API_KEY", "test-firecrawl-key");
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
  });

  it("returns parsed markdown and title on a successful scrape", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          data: {
            markdown: "# Solid-State Batteries\n\nContent here.",
            metadata: { title: "Solid-State Batteries" },
          },
        }),
      })
    );

    const result = await performFirecrawlScrape("https://example.com/article");

    expect(result).toEqual({
      url: "https://example.com/article",
      title: "Solid-State Batteries",
      markdown: "# Solid-State Batteries\n\nContent here.",
    });

    expect(fetch).toHaveBeenCalledWith(
      "https://api.firecrawl.dev/v1/scrape",
      expect.objectContaining({
        method: "POST",
        headers: expect.objectContaining({ Authorization: "Bearer test-firecrawl-key" }),
      })
    );
  });

  it("truncates markdown content longer than the configured maximum", async () => {
    const longMarkdown = "x".repeat(10000);

    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          data: { markdown: longMarkdown, metadata: { title: "Long Article" } },
        }),
      })
    );

    const result = await performFirecrawlScrape("https://example.com/long-article");

    expect(result.markdown.length).toBeLessThan(longMarkdown.length);
    expect(result.markdown.endsWith("[...truncated]")).toBe(true);
  });

  it("throws a descriptive error when the API responds with a non-2xx status", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: false,
        status: 403,
        text: async () => "Forbidden",
      })
    );

    await expect(performFirecrawlScrape("https://example.com/blocked")).rejects.toThrow(
      /Firecrawl scrape failed \(403\): Forbidden/
    );
  });

  it("throws immediately when FIRECRAWL_API_KEY is not set", async () => {
    vi.unstubAllEnvs();
    vi.stubEnv("FIRECRAWL_API_KEY", "");

    await expect(performFirecrawlScrape("https://example.com")).rejects.toThrow(
      /FIRECRAWL_API_KEY is not set/
    );
  });
});
</Code>

<Explanation>
Asserting `result.markdown.endsWith("[...truncated]")` rather than checking an exact character count keeps the test resilient to the precise `MAX_MARKDOWN_LENGTH` value changing later — it verifies the *behavior* (truncation happens, and is clearly marked) rather than over-specifying an implementation detail that has no product-level significance. This is a general principle worth calling out: good tests assert on outcomes a developer actually cares about, not on incidental implementation constants.
</Explanation>
</Step>

---

**Step 5.4: Integration Testing the Agent Loop with `MockLanguageModelV2`**.

---

<Step number="5.4" title="Integration Testing the Agent Loop with MockLanguageModelV2">
<Explanation>
This is the most valuable test in the entire suite: a full integration test of `runAgentLoop` (Step 2.5) that exercises the real tool-calling machinery of the Vercel AI SDK — real `stopWhen` step counting, real tool `execute` invocation, real message assembly — while completely replacing the LLM itself with `MockLanguageModelV2` from `ai/test`. This is possible because of the `modelOverride` seam we deliberately built into `runAgentLoop`. `MockLanguageModelV2` lets us script a sequence of model responses: first "call the webSearch tool," then "call the scrapeUrl tool," then "here is my final answer" — simulating exactly the search-then-scrape-then-answer workflow the system prompt (Step 2.4) instructs the real model to follow, but fully deterministically and with zero real API calls to Groq/Together/HF, Tavily, or Firecrawl. We still mock `fetch` for the tools themselves (as in Steps 5.2/5.3) so the *entire* test runs offline.
</Explanation>

<Code language="typescript" title="src/lib/agent/agent-loop.test.ts">
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { MockLanguageModelV2 } from "ai/test";
import { convertArrayToReadableStream } from "ai/test";
import { runAgentLoop } from "./agent-loop";

describe("runAgentLoop", () => {
  beforeEach(() => {
    vi.stubEnv("TAVILY_API_KEY", "test-tavily-key");
    vi.stubEnv("FIRECRAWL_API_KEY", "test-firecrawl-key");
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
  });

  it("runs a full search -> scrape -> answer loop and produces a final report", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockImplementation((url: string) => {
        if (url.includes("tavily.com")) {
          return Promise.resolve({
            ok: true,
            json: async () => ({
              results: [
                {
                  title: "Solid-State Battery Breakthrough",
                  url: "https://example.com/breakthrough",
                  content: "Researchers announced a new solid-state battery design.",
                  score: 0.97,
                },
              ],
            }),
          });
        }
        if (url.includes("firecrawl.dev")) {
          return Promise.resolve({
            ok: true,
            json: async () => ({
              data: {
                markdown: "Full article: the new design doubles energy density.",
                metadata: { title: "Solid-State Battery Breakthrough" },
              },
            }),
          });
        }
        return Promise.reject(new Error(`Unexpected fetch call to ${url}`));
      })
    );

    const mockModel = new MockLanguageModelV2({
      doStream: async () => {
        return {
          stream: convertArrayToReadableStream(
            getScriptedStepParts(mockModel.callCount)
          ),
          rawCall: { rawPrompt: null, rawSettings: {} },
        };
      },
    });

    (mockModel as any).callCount = 0;
    const originalDoStream = mockModel.doStream.bind(mockModel);
    mockModel.doStream = async (...args) => {
      const result = await originalDoStream(...args);
      (mockModel as any).callCount += 1;
      return result;
    };

    function getScriptedStepParts(step: number) {
      if (step === 0) {
        return [
          { type: "tool-call", toolCallId: "call-1", toolName: "webSearch", input: JSON.stringify({ query: "solid-state battery breakthroughs", maxResults: 5 }) },
          { type: "finish", finishReason: "tool-calls", usage: { inputTokens: 10, outputTokens: 10 } },
        ];
      }
      if (step === 1) {
        return [
          { type: "tool-call", toolCallId: "call-2", toolName: "scrapeUrl", input: JSON.stringify({ url: "https://example.com/breakthrough" }) },
          { type: "finish", finishReason: "tool-calls", usage: { inputTokens: 10, outputTokens: 10 } },
        ];
      }
      return [
        { type: "text-delta", id: "t1", delta: "Solid-state batteries just got better.\n\n## Key Findings\n- Energy density doubled.\n\n## Sources\n- https://example.com/breakthrough" },
        { type: "finish", finishReason: "stop", usage: { inputTokens: 10, outputTokens: 20 } },
      ];
    }

    const result = runAgentLoop({
      messages: [{ role: "user", content: "What's new in solid-state batteries?" }],
      modelValue: "groq:llama-3.3-70b-versatile",
      modelOverride: mockModel,
    });

    const finalText = await result.text;
    const toolCalls = await result.toolCalls;

    expect(toolCalls).toHaveLength(2);
    expect(toolCalls[0].toolName).toBe("webSearch");
    expect(toolCalls[1].toolName).toBe("scrapeUrl");
    expect(finalText).toContain("## Key Findings");
    expect(finalText).toContain("https://example.com/breakthrough");
  });

  it("respects the MAX_AGENT_STEPS cap even if the model keeps requesting tool calls", async () => {
    const mockModel = new MockLanguageModelV2({
      doStream: async () => ({
        stream: convertArrayToReadableStream([
          { type: "tool-call", toolCallId: "call-loop", toolName: "webSearch", input: JSON.stringify({ query: "loop forever", maxResults: 1 }) },
          { type: "finish", finishReason: "tool-calls", usage: { inputTokens: 5, outputTokens: 5 } },
        ]),
        rawCall: { rawPrompt: null, rawSettings: {} },
      }),
    });

    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ results: [] }),
      })
    );

    const result = runAgentLoop({
      messages: [{ role: "user", content: "test runaway loop" }],
      modelValue: "groq:llama-3.3-70b-versatile",
      modelOverride: mockModel,
    });

    const toolCalls = await result.toolCalls;

    expect(toolCalls.length).toBeLessThanOrEqual(8);
  });
});
</Code>

<Explanation>
The second test is arguably the more important one from a reliability standpoint: it proves the `stopWhen: stepCountIs(MAX_AGENT_STEPS)` safeguard from Step 2.5 actually works against an adversarial model that never wants to stop calling tools — exactly the "runaway loop" failure mode the cap exists to prevent, and exactly the kind of scenario that's dangerous to test manually against a real free-tier model (you'd either need to get lucky reproducing it, or burn real API credits deliberately trying to trigger it). Scripting `doStream` responses by step count is somewhat manual, but it mirrors precisely how `MockLanguageModelV2` is intended to be used for multi-step agent testing per the AI SDK's own testing guidance — each call represents one full "step" in the tool-calling loop.
</Explanation>
</Step>

---
**Step 5.5: Phase 5 Wrap-up**. 

---

<Step number="5.5" title="Phase 5 Wrap-up">
<Explanation>
Step back and look at what the test suite as a whole actually guarantees. The unit tests (Steps 5.2, 5.3) verify each tool's HTTP contract in isolation: correct request shape sent, correct response shape parsed, correct error handling on failures, correct truncation behavior. The integration test (Step 5.4) verifies the layer above that: given *any* sequence of model decisions (scripted here, but structurally identical to what a real free-tier model would produce), the AI SDK's tool-calling loop correctly invokes our tools, correctly assembles conversation state across steps, and correctly respects our safety cap. Together, these tests cover the entire agentic core end-to-end without a single real network call to Groq, Together AI, Hugging Face, Tavily, or Firecrawl — meaning this suite can run in a CI pipeline, on every commit, indefinitely, at exactly $0 marginal cost. This is the practical payoff of the `ai/test` package and the `modelOverride`/exported-network-function design patterns established back in Phase 2: testability was designed in from the start, not retrofitted.

A note on what these tests deliberately do NOT cover: actual output quality from a real free-tier model (is the final report actually well-written and accurate?), real end-to-end latency against live Tavily/Firecrawl APIs, and UI rendering correctness (Phase 3's components). The first is inherently non-deterministic and better suited to manual spot-checks or a separate, deliberately-not-CI-gated "eval" script; the third would call for component/E2E tools (e.g. Playwright) which are out of scope for this series but a natural extension — noted in the Conclusion.
</Explanation>

<Explanation>
**Phase 5 is now complete.** InsightAgent's agentic core — model registry, both tools, the system prompt's implicit contract, and the orchestrating agent loop with its safety cap — is now backed by a deterministic, offline, zero-cost automated test suite. Phase 6 is the final phase: deploying this application to Vercel's free Hobby tier, correctly configuring every environment variable across all three free model providers plus Clerk/Neon/Tavily/Firecrawl, understanding Hobby's serverless function duration and Edge limits as they apply to our `maxDuration = 60` Node.js route, and a production readiness checklist.
</Explanation>
</Step>

