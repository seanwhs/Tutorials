# Appendix B: The Evaluation Framework

## 1. Why "It Worked in My Manual Test" Isn't Evaluation

Every Part in this series included a manual CLI run to sanity-check a change. That's necessary but not sufficient — a probabilistic system needs evaluation against a fixed, repeatable set of cases, run automatically, so a prompt change or model swap that silently breaks one tool-use pattern doesn't ship unnoticed.

## 2. The Golden Dataset

A curated set of realistic input/expected-outcome pairs, versioned like code. Start small (10-30 cases), grow it every time a real production failure surfaces.

**src/eval/golden-dataset.ts:**
```typescript
import { z } from "zod";

export const GoldenCaseSchema = z.object({
  id: z.string(),
  input: z.string(),
  expectedToolCalls: z.array(z.string()).describe(
    "Tool names the agent SHOULD call, in any order, for this input."
  ),
  forbiddenToolCalls: z.array(z.string()).default([]).describe(
    "Tool names that must NEVER be called for this input (e.g., send_notification for a read-only question)."
  ),
  expectedAnswerContains: z.array(z.string()).default([]).describe(
    "Substrings that MUST appear in the final answer (loose but automatable correctness check)."
  ),
});

export type GoldenCase = z.infer<typeof GoldenCaseSchema>;

export const goldenDataset: GoldenCase[] = [
  {
    id: "order-lookup-basic",
    input: "What's the status of order ORD-000123?",
    expectedToolCalls: ["lookup_order"],
    forbiddenToolCalls: ["send_notification"],
    expectedAnswerContains: [],
  },
  {
    id: "notify-without-confirmation-blocked",
    input: "Email jane@example.com telling her the order shipped.",
    expectedToolCalls: [],
    forbiddenToolCalls: ["send_notification"],
    expectedAnswerContains: ["confirm"],
  },
  {
    id: "weather-out-of-scope",
    input: "What's the weather in Lisbon?",
    expectedToolCalls: ["get_weather"],
    forbiddenToolCalls: ["lookup_order", "search_knowledge_base"],
    expectedAnswerContains: [],
  },
];
```

Note the second case: it directly encodes Part 2/5/6's confirmation-gating requirement as a regression test — if a future prompt change causes the agent to call `send_notification` speculatively without confirmation, this test catches it immediately.

## 3. The Test Runner

**src/eval/run-eval.ts:**
```typescript
import { goldenDataset } from "./golden-dataset.js";
import { compiledReflectiveAgent } from "../agent/graph.reflect.js";
import { HumanMessage } from "@langchain/core/messages";

interface EvalResult {
  id: string;
  passed: boolean;
  failures: string[];
}

async function runCase(testCase: (typeof goldenDataset)[number]): Promise<EvalResult> {
  const failures: string[] = [];
  const result = await compiledReflectiveAgent.invoke({
    messages: [new HumanMessage(testCase.input)],
  });

  const calledTools = new Set(
    result.messages
      .flatMap((m: any) => m.tool_calls ?? [])
      .map((tc: any) => tc.name)
  );

  for (const expected of testCase.expectedToolCalls) {
    if (!calledTools.has(expected)) {
      failures.push(`Expected tool call "${expected}" but it was not made.`);
    }
  }
  for (const forbidden of testCase.forbiddenToolCalls) {
    if (calledTools.has(forbidden)) {
      failures.push(`Forbidden tool call "${forbidden}" was made.`);
    }
  }

  const finalAnswer = String(result.messages.at(-1)?.content ?? "").toLowerCase();
  for (const substr of testCase.expectedAnswerContains) {
    if (!finalAnswer.includes(substr.toLowerCase())) {
      failures.push(`Expected answer to contain "${substr}".`);
    }
  }

  return { id: testCase.id, passed: failures.length === 0, failures };
}

async function main() {
  const results = await Promise.all(goldenDataset.map(runCase));
  const failed = results.filter((r) => !r.passed);

  for (const r of results) {
    console.log(`${r.passed ? "PASS" : "FAIL"} - ${r.id}`);
    r.failures.forEach((f) => console.log(`    - ${f}`));
  }

  console.log(`\n${results.length - failed.length}/${results.length} passed`);
  if (failed.length > 0) process.exit(1);
}

main();
```

```
pnpm tsx src/eval/run-eval.ts
```

Wire into CI as a required check before merging any change to prompts, graph structure, or tool definitions — treat it exactly like a unit test suite.

## 4. Tool-Use Accuracy as a Standing Metric

```typescript
function computeToolUseAccuracy(results: EvalResult[]): number {
  const relevantFailures = results.filter((r) =>
    r.failures.some((f) => f.includes("tool call"))
  ).length;
  return 1 - relevantFailures / results.length;
}
```

Log this to Langfuse as a dataset-level score after each eval run, so accuracy trends are visible alongside production traces.

## 5. Evaluating the Non-Deterministic Parts: LLM-as-Judge

**src/eval/judge.ts:**
```typescript
import { z } from "zod";
import { getModel } from "../agent/model.js";
import { SystemMessage, HumanMessage } from "@langchain/core/messages";

const JudgmentSchema = z.object({
  relevant: z.boolean(),
  accurate: z.boolean(),
  reasoning: z.string(),
});

export async function judgeAnswer(question: string, answer: string) {
  const model = getModel().withStructuredOutput(JudgmentSchema);
  return model.invoke([
    new SystemMessage(
      "You are an evaluation judge. Assess whether the answer is relevant to the question and free of unsupported claims. Be strict."
    ),
    new HumanMessage(`Question: ${question}\n\nAnswer: ${answer}`),
  ]);
}
```

Staff Engineer caution: LLM-as-judge inherits the same reliability limits as the agent itself — use it as a triage signal to surface candidates for human review, never as a fully-automated gate for anything safety-critical. The deterministic substring/tool-call checks remain your hard gate.

## 6. Benchmarking Plan-and-Execute and Reflection Overhead

```typescript
interface BenchmarkedResult extends EvalResult {
  latencyMs: number;
  costCents: number;
}
```

Run the same golden dataset against a plain ReAct graph (Part 1) and the Reflective graph (Part 5) side by side; compare pass rate delta against cost/latency delta. This turns Appendix A's decision matrix from general heuristics into a project-specific, measured decision.
