# Appendix B: The Evaluation Framework

> This Appendix is the thing referenced, by name, from more Parts of this series than any other single artifact: Part 5's escalation criteria, Part 6's cost watchdog, Part 7's tracing (which this Appendix's automated runs feed data into), and — most directly — Part 9a's entire trigger condition for Multi-Agent all point back here. It's worth building it with that in mind: this isn't a bolt-on testing chapter, it's the measurement layer every other architectural decision in this series has been implicitly assuming exists.

## 1. Why "It Worked in My Manual Test" Isn't Evaluation

Every Part in this series included a manual CLI run to sanity-check a change — `pnpm tsx src/run.ts`, first introduced in Part 1, section 8, and echoed with small variations through Part 7's Langfuse-instrumented version. That's necessary, and worth keeping as a fast, cheap first check on any change. But it is not sufficient, and it's worth being precise about exactly what gap it leaves open.

A manual run tells you one thing: for one specific input, on one specific run, with whatever the model happened to do on that particular invocation, the output looked right. It tells you nothing about the input you didn't happen to try, and — because this is a probabilistic system, per Part 1 section 1's opening framing — it doesn't even fully guarantee the *same* input will behave the same way on the next run. A probabilistic system needs evaluation against a fixed, repeatable set of cases, run automatically, precisely because "I tried it once and it looked fine" carries almost none of the guarantee it would carry for deterministic code. A prompt change or model swap that silently breaks one specific tool-use pattern — say, causes the agent to stop calling `lookup_order` for a phrasing of the question it used to handle correctly — can ship completely unnoticed through a process built only on manual spot-checks, because the specific case that broke was never the one someone happened to manually try after the change. Automated evaluation exists to make that kind of regression visible before it reaches production, not after.

## 2. The Golden Dataset

A curated set of realistic input/expected-outcome pairs, versioned like code — living in the repository, reviewed in pull requests, with a history you can `git blame` the same way you would any other source file. Start small (10-30 cases is a perfectly reasonable starting size, not a compromise), and grow it every time a real production failure surfaces. That growth discipline is worth calling out explicitly as a practice, not just a nice-to-have: every time a real user hits a genuine failure in production, that failure is free, high-signal raw material for a new golden case — it's a scenario you already know matters, that your current evaluation coverage already missed. Turning every production incident into a permanent regression test is one of the highest-leverage habits available for keeping this dataset's coverage actually representative of reality, rather than representative of whatever the original author happened to think of while writing it.

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

Notice that the schema itself, `GoldenCaseSchema`, is a Zod object — the exact same discipline Part 2 applied to tool inputs and Part 9a applied to inter-agent contracts, now applied to test *cases* themselves. That's not a coincidence or a stylistic flourish; it means a malformed golden case (a typo'd tool name, say) fails loudly at the moment it's added to the dataset, rather than silently passing every future eval run because it was checking for a tool that was never going to be called under any circumstances. The discipline this series has applied everywhere else — validate the shape, don't trust free-form structure — pays off here too.

Look closely at each of the three fields' *purpose*, because each one is catching a categorically different kind of regression. `expectedToolCalls` catches under-calling — the agent failing to use a tool it should have, which shows up as a wrong or incomplete answer. `forbiddenToolCalls` catches over-calling — the agent using a tool speculatively or inappropriately, which is often the more dangerous direction, since an unwanted `send_notification` call is a real-world side effect, not just an unhelpful answer. `expectedAnswerContains` is deliberately the loosest of the three — a substring check, not an exact match — because exact-matching a model's free-text output would make every test brittle against harmless rephrasing; the substring check asks only "did the answer contain the load-bearing fact it needed to," not "did the model phrase it identically to some reference answer."

Note the second case specifically, `"notify-without-confirmation-blocked"`: it directly encodes Part 2, Part 5, and Part 6's confirmation-gating requirement as a regression test — the `z.literal(true)` schema gate from Part 2, the Critique criterion 4 check from Part 5's exercise, and the n8n-backed `notifyTool` from Part 6 all converge on one guarantee: no notification without explicit confirmation. This one golden case is what turns that guarantee from "a property we designed the system to have" into "a property we automatically verify the system still has, on every single change." If a future prompt change causes the agent to call `send_notification` speculatively without confirmation — perhaps because someone rewrote the system prompt for an unrelated reason and inadvertently loosened its caution — this test catches it immediately, in CI, before the change ever reaches a real user with a real email address.

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

```bash
pnpm tsx src/eval/run-eval.ts
```

A few implementation details worth reading closely, beyond the overall shape. `Promise.all(goldenDataset.map(runCase))` runs every case concurrently — the same instinct as Part 8's `Promise.all` for the global and per-user budget queries, applied here for the same reason: these cases are entirely independent of each other, and there's no correctness reason to force them through one at a time when the eval suite's own wall-clock time is a real cost to whoever's waiting on CI. The `failures` array accumulates *every* problem with a case, rather than stopping at the first one — a case that both called a forbidden tool *and* missed an expected substring reports both issues in one run, which matters for debugging efficiency: nobody wants to fix one failure, re-run the whole suite, and discover a second unrelated failure that could have been reported the first time.

The most operationally important line is the last one: `if (failed.length > 0) process.exit(1)`. A non-zero exit code is what turns this script from "a thing a developer can run and read" into "a thing CI can actually gate on" — most CI systems key their pass/fail determination directly off the process exit code, so without this line, the script could print `"2/3 passed"` in bright red text and CI would still report a green checkmark, because the process itself exited successfully regardless of what it printed. Wire this into CI as a required check before merging any change to prompts, graph structure, or tool definitions — the framing worth internalizing is "treat it exactly like a unit test suite," not "treat it like a nice-to-have quality signal." A prompt change is a code change with exactly as much power to break behavior as a logic change, and it deserves exactly the same gate before merging.

## 4. Tool-Use Accuracy as a Standing Metric

```typescript
function computeToolUseAccuracy(results: EvalResult[]): number {
  const relevantFailures = results.filter((r) =>
    r.failures.some((f) => f.includes("tool call"))
  ).length;
  return 1 - relevantFailures / results.length;
}
```

This is a deliberately narrow slice of the pass/fail data — it filters specifically for failures whose message contains `"tool call"`, meaning it isolates the `expectedToolCalls` and `forbiddenToolCalls` checks from section 2, ignoring `expectedAnswerContains` failures entirely. That narrowing is the point: a single aggregate pass rate tells you *something* went wrong on a given run, but conflates "the agent used the wrong tool" (a reasoning/tool-selection problem, likely fixable by better tool descriptions, per Part 2's checklist) with "the agent's phrasing didn't include an expected substring" (which might be a genuinely harmless rephrasing, or a real content-accuracy problem — a different investigation entirely). Separating tool-use accuracy out as its own tracked number lets you watch that specific, mechanistically-meaningful metric over time, independent of noise from the loosest, most rephrasing-sensitive check in the dataset.

Log this to Langfuse as a dataset-level score after each eval run, so accuracy trends are visible alongside production traces — the same instrumentation instinct Part 7 built for individual runs (recall the `first_pass_success` score from Part 7, section 9), now applied at the level of an entire eval suite's aggregate result rather than a single trace. Seeing this trend line move over weeks, correlated against the `AGENT_VERSION` tag from Part 8, section 6, is what actually answers "did our last prompt change help or hurt" with data, rather than with the impression left by however many manual spot-checks someone happened to run right after shipping it.

## 5. Evaluating the Non-Deterministic Parts: LLM-as-Judge

Sections 2 through 4 all evaluate things that are mechanically checkable — was a specific tool called, does a string contain a specific substring. A real evaluation suite eventually needs to grade something softer: is this answer actually *good*, not just structurally compliant. That's a job the deterministic checks above genuinely cannot do, and it's where LLM-as-judge comes in — deliberately introduced last in this Appendix, after the deterministic checks, not first, because the ordering itself carries an argument about which one should be trusted more.

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

Notice this is, structurally, nearly identical to Part 5's Critique node — a `withStructuredOutput` call against a small Zod schema, evaluating a candidate against explicit criteria, told explicitly to "be strict." That similarity is not incidental; it's worth naming directly, because it's also exactly the source of this technique's central limitation.

Staff Engineer caution, and the reason this section is placed after, not before, the deterministic checks: LLM-as-judge inherits the *same* reliability limits as the agent itself, because it's built from the same kind of component — an LLM call, subject to the same imperfect judgment, the same possibility of being fooled by confident-sounding but wrong output, the same inability to independently verify facts it wasn't given. Using a model to judge a model is not an escape from the trust problem this whole series has been building guardrails around since Part 1; it's the same trust problem, one level removed. Use it as a *triage signal* — a way to surface candidates for human review, flag likely-bad outputs for closer inspection, spot patterns across a large volume of eval runs that would be too slow to review manually — never as a fully-automated gate for anything safety-critical. The deterministic substring and tool-call checks from sections 2-4 remain your hard gate, the thing that actually blocks a merge in CI; LLM-as-judge augments that hard gate with a softer, broader signal, but it should never replace it for anything where being wrong actually matters. This is, in the end, the exact same "schema enforcement and model judgment are complementary layers, not substitutes" argument from Part 5, section 9 — restated once more, now applied to the evaluation layer itself rather than to the agent being evaluated.

## 6. Benchmarking Plan-and-Execute and Reflection Overhead

```typescript
interface BenchmarkedResult extends EvalResult {
  latencyMs: number;
  costCents: number;
}
```

This is the smallest code snippet in the Appendix and arguably the most consequential, because it's what turns everything else in this Appendix from "does the agent behave correctly" into "is the *architecture* actually worth what it costs" — a genuinely different, higher-level question. Run the *same* golden dataset — unchanged, same cases, same expected outcomes — against a plain ReAct graph (Part 1) and the Reflective graph (Part 5) side by side, capturing not just pass/fail per section 3 but `latencyMs` and `costCents` per run as well. Then compare the *pass rate delta* against the *cost/latency delta* between the two runs.

This is the concrete, empirical mechanism that Appendix A's decision matrix and decision heuristic have been gesturing toward in the abstract the whole way through: Appendix A said "add Reflection when being wrong is expensive" and "consider Multi-Agent only with measured evidence" — this section is what actually produces that measurement, for your specific system, on your specific golden dataset, rather than asking you to trust the general heuristic on faith. If the Reflective graph's pass rate on your golden dataset is only marginally higher than plain ReAct's — say, 94% versus 91% — while its latency and cost run 2-3x higher, that's a genuine, project-specific data point suggesting Reflection's cost isn't earning its keep for *this* particular agent's task profile, regardless of what the general heuristic in Appendix A recommends in the abstract. If the delta is instead 65% versus 93%, that's an equally strong, equally specific data point in the other direction. Either way, this turns Appendix A's decision matrix from general heuristics — useful for a first pass, before you have any data of your own — into a project-specific, measured decision, backed by the same golden dataset discipline this entire Appendix has been building since section 2. That's the throughline worth carrying forward past this series: every architectural escalation this series has walked through — ReAct to Plan-and-Execute, plain generation to Reflection, single-agent to Multi-Agent — should ultimately be justified the same way, with a number from a benchmark like this one, not with an intuition about which pattern sounds more sophisticated.

## Evaluation Framework Checklist

- **Treat prompt and graph changes as code changes**, gated by a required, automated CI check — not just a manual spot-check before merging.
- **Grow the golden dataset from real production failures**, not just from what you can imagine in advance — every incident is a free, high-signal test case.
- **Separate what a check is actually catching.** Under-calling, over-calling, and content correctness are three different failure modes; don't collapse them into one undifferentiated pass/fail.
- **Fail loudly with a real exit code.** A test runner CI can't gate on isn't a test runner CI actually uses.
- **Use LLM-as-judge for triage, never as the hard gate.** It inherits the exact reliability limits of the system it's grading.
- **Benchmark architectural choices on your own golden dataset before trusting a general heuristic.** Appendix A tells you what to try first; this Appendix is how you find out whether it was actually worth it, for your system specifically.
