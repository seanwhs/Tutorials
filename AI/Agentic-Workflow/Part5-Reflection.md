# Part 5: Reflection & Self-Correction

> Recap: Parts 1-4 built a system that reasons, acts, remembers, and plans — but at no point does it stop and ask "was that actually right?" before moving forward. Every node so far has the same shape: produce an output, act on it. This Part introduces the one node type that breaks that shape on purpose — a node whose entire job is to doubt the previous node's output before anything downstream trusts it.

## 1. Why Generation Alone Isn't Enough

Every node built so far — Reason (Part 1), Execute (Part 4) — produces an output and moves forward. None of them ask "was that output actually correct, safe, or complete?" before acting on it or returning it to the user. That's not an oversight in the earlier Parts; it's a deliberate deferral, because the fix — Reflection — is expensive enough that it deserves its own Part, and cheap enough in the wrong places that bolting it onto every single step from Part 1 onward would have made the whole series harder to follow.

Reflection introduces a dedicated **Critique** phase between generation and action — the "Generation-Critique-Refinement" cycle, and it's worth understanding all three steps as genuinely distinct responsibilities, not one blurred step:

1. **Generate** — produce a candidate output. This is everything you've already built: Reason, Execute, a plan step's result.
2. **Critique** — a *separate* reasoning pass evaluates the candidate against explicit, stated criteria and returns a structured verdict (pass/fail, plus specific reasons). Separate is the operative word — more on why in section 3.
3. **Refine** — if critique fails, generate again, informed by the critique's specific feedback, not from scratch. Loop back to step 2, bounded by a retry ceiling — the same "hard ceiling in code, not just a prompt" discipline every prior Part has insisted on.

Staff Engineer framing: this is the highest-leverage pattern available for reducing hallucination-driven failures, and it's worth being precise about *why* it works rather than treating it as folklore. A single generation pass has no mechanism to catch its own mistakes — the model that produced a wrong answer has no special access to knowing it's wrong, because the error, if there is one, is baked into the same reasoning process that produced the rest of the output. A second, differently-framed pass — one explicitly instructed to look for problems rather than to solve the task — engages a different mode of the same model, and empirically catches a meaningful fraction of errors the first pass missed. It is not a guarantee (a model can still fail to catch its own systematic blind spots even on a second pass), but it materially improves on doing nothing.

The cost is real and worth stating in the same breath as the benefit: doubling, or more, of token spend and latency per action, since you're now paying for at least two model calls (generate, critique) instead of one, and potentially several more if refinement loops. Reserve Reflection for steps where being wrong is expensive — irreversible actions, user-facing final answers, anything that closes a loop the system can't easily reopen — not for every micro-step in a long plan. Applying it uniformly everywhere is the same mistake Part 2 and Part 3 both warned against in different forms: reaching for the expensive tool before you've established the cheap one isn't sufficient.

## 2. Critique as a Structured Output (Not a Vibe)

**src/agent/critique.ts:**

```typescript
import { z } from "zod";

export const CritiqueSchema = z.object({
  verdict: z.enum(["pass", "fail"]),
  issues: z.array(z.string()).default([]),
  suggestion: z.string().optional().describe(
    "Concrete instruction for how to fix the issues, if verdict is fail."
  ),
});

export type Critique = z.infer<typeof CritiqueSchema>;
```

The section title is doing real work: "not a vibe" is a pointed contrast with the naive version of this pattern, where you'd ask a model "does this look right to you?" and parse a free-text response for something that sounds like approval or disapproval. That version is fragile in two specific ways this schema closes off. First, a free-text critique has no forced structure — the model might hedge, partially approve, or bury a real problem in a paragraph of otherwise-positive language, and your downstream routing logic (section 4) would have to do brittle string-matching to extract a decision from prose. Second, and more importantly, a `verdict` enum with exactly two values (`"pass"` or `"fail"`) forces a binary decision — there is no schema-valid way for the model to say "mostly fine, I guess," which is exactly the kind of soft, unforceful judgment that lets bad outputs slip through in practice. The `issues` array and optional `suggestion` field then carry the *texture* of the critique — what's wrong, and how to fix it — separately from the forced binary decision, which is what section 4's `refineNode` actually consumes.

## 3. The Critique Node

**src/agent/nodes/critique.ts:**

```typescript
import { getModel } from "../model.js";
import { CritiqueSchema } from "../critique.js";
import type { AgentStateType } from "../state.js";
import { SystemMessage } from "@langchain/core/messages";

const CRITIQUE_PROMPT = `You are a strict reviewer, not the original author.
Evaluate the candidate output against these criteria:
1. Does it directly address the user's actual request?
2. Are all factual claims traceable to information present in the conversation
   or tool results (no invented facts)?
3. If the output proposes an action, is that action safe and reversible,
   or explicitly confirmed if irreversible?
Return "fail" if ANY criterion is not met, with specific issues listed.`;

export async function critiqueNode(state: AgentStateType) {
  const candidate = state.messages[state.messages.length - 1];
  const model = getModel().withStructuredOutput(CritiqueSchema);

  const critique = await model.invoke([
    new SystemMessage(CRITIQUE_PROMPT),
    ...state.messages.slice(0, -1),
    new SystemMessage(`Candidate output to review:\n${candidate.content}`),
  ]);

  return { lastCritique: critique };
}
```

Notice the message construction: the candidate output is deliberately pulled out of `state.messages` (via `.slice(0, -1)` for everything before it) and re-presented as an explicit, separately-labeled block — "Candidate output to review:" — rather than just letting it sit as the last message in an otherwise-normal transcript. This framing shift matters more than it might look: a model reading its own prior output as simply "the last thing in the conversation" tends to treat it the way a writer treats their own freshly-written paragraph — as settled, not as a thing actively up for scrutiny. Re-presenting it as a labeled artifact under review nudges the model into evaluation mode rather than continuation mode.

That same instinct is why the prompt opens with "You are a strict reviewer, not the original author" — a deliberate prompt-engineering technique to reduce **self-agreement bias**: an LLM asked to critique its own immediately-prior output tends to rubber-stamp it unless explicitly instructed to adopt an adversarial stance. This isn't a minor stylistic flourish; without it, the Critique node's pass rate tends to run suspiciously close to 100%, which defeats the entire purpose of the phase. If you're tuning this prompt for your own use case, that framing line is one of the last things you should consider cutting, even under pressure to shorten the prompt.

Also worth reading closely: the three numbered criteria aren't arbitrary — they map to three different failure modes. Criterion 1 (does it address the actual request) catches drift — a competent-sounding answer to the wrong question. Criterion 2 (traceable factual claims) catches hallucination specifically, and ties directly back to Part 3's memory work: a claim is only "traceable" if it's actually grounded in something retrieved or stated, not something the model plausibly inferred. Criterion 3 (safe/reversible or confirmed) is a direct callback to Part 2's `send_notification` tool and its `confirmed: z.literal(true)` field — and gets its own dedicated treatment in section 9's exercise, because schema enforcement and critique review turn out to be checking two different things about the same field.

Add `lastCritique` to state:

```typescript
lastCritique: Annotation<Critique | null>({
  reducer: (_current, update) => update,
  default: () => null,
}),
refinementCount: Annotation<number>({
  reducer: (_current, update) => update,
  default: () => 0,
}),
```

Both fields replace on update, following the same rule established in Part 1 (`stepCount`) and Part 4 (`plan`, `currentStepIndex`): the *current* critique and the *current* refinement count are what matter for routing decisions, not a running history of every critique ever produced. (The full history of critiques still exists implicitly, in the transcript, if you ever need to audit it — this state field is a fast-access pointer to the *latest* one, not the only record of it.)

## 4. The Refine Node and Routing

**src/agent/nodes/refine.ts:**

```typescript
import { getModel } from "../model.js";
import type { AgentStateType } from "../state.js";
import { SystemMessage } from "@langchain/core/messages";

const MAX_REFINEMENTS = 2;

export async function refineNode(state: AgentStateType) {
  const critique = state.lastCritique!;
  const model = getModel();

  const response = await model.invoke([
    ...state.messages,
    new SystemMessage(
      `Your previous output failed review. Issues: ${critique.issues.join("; ")}. ${
        critique.suggestion ?? ""
      }\nProduce a corrected output.`
    ),
  ]);

  return {
    messages: [response],
    refinementCount: state.refinementCount + 1,
  };
}
```

The refine call is invoked with the *full* transcript (`...state.messages`) plus one appended instruction — a deliberate contrast with Part 4's Executor, which invoked its model with a deliberately narrow, near-empty context. That's not an inconsistency between Parts; it's the right call in each context. Part 4's Executor wanted to prevent drift across plan steps by withholding irrelevant history. Refinement wants the *opposite*: the model needs everything it had the first time, plus the specific critique feedback, in order to produce a corrected version of the same output — withholding context here would make the correction worse, not more focused, because the model would be re-deriving context it already had rather than refining a known answer.

Routing function:

```typescript
import { END } from "@langchain/langgraph";
import type { AgentStateType } from "../state.js";

export function routeAfterCritique(state: AgentStateType): "refine" | typeof END {
  const critique = state.lastCritique!;
  if (critique.verdict === "pass") return END;
  if (state.refinementCount >= MAX_REFINEMENTS) {
    // Ceiling reached — accept the last candidate rather than looping forever.
    // Section 6 covers escalation instead of silent acceptance.
    return END;
  }
  return "refine";
}
```

Same hard-ceiling discipline as every prior Part: `MAX_REFINEMENTS` is enforced in the router — a plain, deterministic function of state — not left to the model's own judgment about when to "give up." By now this should feel like a familiar rhythm across the series: Part 1 capped loop steps, Part 4 capped plan length and (in its own exercise) re-plan attempts, and here the same discipline caps refinement attempts. Every one of these ceilings exists for the identical underlying reason — an LLM's willingness to keep trying is not, by itself, a safe substitute for an externally enforced stopping condition. The comment flagging that this version silently accepts the last candidate on ceiling breach is itself a flag for section 6 — silent acceptance is a placeholder, not the intended final behavior.

## 5. Wiring Generation-Critique-Refinement

**src/agent/graph.reflect.ts:**

```typescript
import { StateGraph, END } from "@langchain/langgraph";
import { AgentState } from "./state.js";
import { reasonNode } from "./nodes/reason.js";
import { actNode } from "./nodes/act.js";
import { critiqueNode } from "./nodes/critique.js";
import { refineNode } from "./nodes/refine.js";
import { routeAfterCritique } from "./nodes/routeAfterCritique.js";

const graph = new StateGraph(AgentState)
  .addNode("reason", reasonNode)
  .addNode("act", actNode)
  .addNode("critique", critiqueNode)
  .addNode("refine", refineNode)
  .addEdge("__start__", "reason")
  .addConditionalEdges("reason", (state) => {
    const last = state.messages[state.messages.length - 1] as any;
    return last?.tool_calls?.length > 0 ? "act" : "critique";
  })
  .addEdge("act", "reason")
  .addConditionalEdges("critique", routeAfterCritique)
  .addEdge("refine", "critique");

export const compiledReflectiveAgent = graph.compile();
```

Control flow, traced step by step: tool-calling loops exactly as in Part 1 (`reason` ↔ `act`) until the model produces a final answer with no tool calls — the same `tool_calls.length > 0` check from Part 1's `routeAfterReason`, just inlined here — but now, instead of routing straight to `END` the moment tool calls stop, it routes to `critique`. That's the one-line structural change that turns Part 1's plain ReAct graph into a reflective one: the "are we done" check no longer means "route to END," it means "route to review."

The second thing to notice: `refine` loops back to `critique`, *not* back to `reason`. That's deliberate and mirrors the Part 4 distinction drawn in section 4 above — refinement is "fix this specific, already-critiqued output," a narrower task than "re-reason about the whole request from scratch," which is what re-entering `reason` would mean. Keeping refine's loop tight (refine → critique → refine → critique...) rather than routing back through the full reasoning node keeps each refinement pass focused on the actual, specific feedback rather than reopening decisions that were never in question.

## 6. Escalation Instead of Silent Acceptance

Silently shipping an output that failed review twice — the ceiling-breach branch flagged in section 4 — is a governance gap, not just a minor rough edge. An agent that quietly returns a candidate its own Critique node rejected, with no record that this happened, has produced output that's indistinguishable, from the outside, from output that passed review cleanly. That's a real problem for anyone downstream trying to trust the system's outputs differentially — a human reviewing agent output needs to know which answers came with a clean bill of health and which ones are "best effort, unverified." Prefer explicit escalation instead:

```typescript
export function routeAfterCritique(
  state: AgentStateType
): "refine" | "escalate" | typeof END {
  const critique = state.lastCritique!;
  if (critique.verdict === "pass") return END;
  if (state.refinementCount >= MAX_REFINEMENTS) return "escalate";
  return "refine";
}
```

**src/agent/nodes/escalate.ts:**

```typescript
import type { AgentStateType } from "../state.js";
import { AIMessage } from "@langchain/core/messages";

export async function escalateNode(state: AgentStateType) {
  // In production: write to a review queue, notify a human (Part 6's n8n
  // integration is the natural home for this side effect), and halt.
  return {
    messages: [
      new AIMessage(
        "I was unable to produce output that passed review after multiple attempts. This has been flagged for human review rather than returned as a final answer."
      ),
    ],
  };
}
```

This is the first explicit **human-in-the-loop (HITL) checkpoint** in the series, and it's worth marking as a distinct category from everything built so far. Every guardrail up to this point — step ceilings, schema validation, structured tool failures — has been about the *agent* catching and handling its own limits. Escalation is different in kind: it's the point where the system stops trying to solve the problem autonomously and explicitly hands control to a human, with an honest statement that it couldn't get there on its own. That honesty is the whole value of the pattern — an agent that never admits defeat, and always ships *something* dressed up as a final answer, is strictly less trustworthy than one that sometimes says "I couldn't verify this, a person needs to look at it." Part 6 gives this escalation path a real destination (an actual review queue, an actual notification), and Appendix C requires at least one HITL escalation path before any agent handling irreversible actions ships to production — this is not an optional nicety once real side effects (Part 2's notification tool, anything resembling it) are in play.

## 7. Applying Reflection to Part 4's Plan-and-Execute Steps

Insert a `critique` node after `execute` in the Part 4 graph, before marking a step `"done"`. The reason this catches a distinct failure mode worth naming: it's not primarily about catching a tool call that *fails* — Part 2's `ToolResult` contract and Part 4's `"failed"` status already surface that case cleanly. It's about catching an Executor that calls a tool *successfully*, gets a perfectly valid result back, and then **misinterprets or misreports** that result when summarizing it into `step.result`. That's a failure mode neither the tool contract nor the plan schema can catch on their own, because from their point of view, nothing went wrong — the tool returned `ok(...)`, the step got marked `"done"`. Only a pass that re-reads the step's stated goal against the tool's *actual raw output* — not the Executor's summary of it — can catch a summary that quietly drifted from what the data actually said. That's precisely why Critique should be handed the raw tool output alongside the Executor's summary, rather than just the summary alone: the summary is exactly the thing that might be wrong.

## 8. Exercise Challenge

Extend the Critique prompt so that for candidate outputs containing a `send_notification`-style tool call, Critique specifically verifies that `confirmed: true` was only set after an explicit user confirmation appears earlier in the message history — not merely assumed by the model.

Before writing the fix, it's worth being precise about what gap this closes that Part 2's schema alone doesn't. Reread Part 2's `NotifyInput` schema: `confirmed: z.literal(true)` guarantees the field is present and is exactly `true` — nothing more, nothing less. It says nothing at all about *why* the model set it to `true`. A model could set `confirmed: true` because a user genuinely confirmed the action three turns ago, or because the model inferred — plausibly, even reasonably, but wrongly — that confirmation was implied by something the user said. The schema can't tell those two cases apart; only something that reads the actual conversation history can.

## 9. Solution

```typescript
const CRITIQUE_PROMPT_WITH_CONFIRMATION_CHECK = `${CRITIQUE_PROMPT}
4. If the candidate includes a tool call with a "confirmed" field set to true,
   verify that an earlier message in the conversation contains an explicit
   user statement approving that specific action. If no such explicit
   approval exists in the history, this is an automatic FAIL, regardless of
   how reasonable the action seems.`;
```

Read the last clause closely: "regardless of how reasonable the action seems." That's not a throwaway qualifier — it's closing a specific loophole a weaker version of this criterion would leave open. Without it, a critique model might reason "well, the action does seem like something the user would obviously want, so this is probably fine" — which is exactly the inference failure mode the whole check exists to catch. The instruction deliberately removes "does this seem reasonable" as an acceptable basis for passing criterion 4; the only acceptable basis is a verifiable, explicit approval actually present in the transcript. This is the same instinct as Part 2's "never trust a prompt alone to enforce a hard constraint" applied one layer up — here the constraint being hardened is the critique criterion itself, made resistant to the critique model's own reasonable-sounding rationalizations.

Why this belongs in Critique rather than the tool schema alone, stated as the general principle it actually is: Part 2's `z.literal(true)` guarantees the *field* can't be missing or false; it cannot, and structurally never could, verify the *reason* the model set it to true was a real user confirmation rather than the model's own inference. Schema validation and critique review are complementary layers, not substitutes for one another — the schema closes off an entire category of malformed input at zero marginal reasoning cost, while critique catches a category of *well-formed but unjustified* input at the cost of an extra reasoning pass. This is defense in depth applied to agent safety: two independent layers, each catching what the other structurally cannot, stacked rather than chosen between.

## Reflection Checklist

- **Separate the critique pass, framing-wise, from the generation pass.** Present the candidate as an artifact under review, and explicitly instruct an adversarial stance — self-agreement bias is real and will quietly neutralize an under-specified critique prompt.
- **Force a binary verdict via schema**, not a free-text judgment you have to parse for sentiment.
- **Reserve Reflection for high-stakes outputs.** It roughly doubles cost per action; apply it where being wrong is expensive, not uniformly.
- **Cap refinement attempts in code**, exactly like every other loop in this series.
- **Never let a ceiling breach resolve to silent acceptance.** Escalate explicitly, and say so honestly in the output, rather than shipping an unverified answer indistinguishable from a verified one.
- **Treat schema enforcement and critique review as complementary, not redundant.** A schema constrains *shape*; critique can inspect *justification* a schema structurally cannot see.

## Next

Part 6 moves from pure-code orchestration to a hybrid architecture: n8n takes over deterministic, external-system actions (the "Act" side), while everything built in Parts 1-5 continues to own reasoning, planning, and reflection.
