# Appendix C: Deployment Checklist — Production Readiness

> This is the last document in the series, and it's built to be used differently from every Part before it. Parts 1-9b taught the *why* behind each guardrail, at length. Appendices A and B gave you decision frameworks for choosing a pattern and measuring whether it's working. This Appendix assumes all of that reading has already happened, and compresses it into the one artifact you actually want open in a second window while you're about to flip an agent live: a checklist, with every item traceable back to the Part that explains and implements it, so "why is this here" is always one click away but never blocks you from just running down the list.

## How to Use This Checklist

Run through every item before an agentic workflow is given access to real user data or real irreversible actions — not once, at launch, and then forgotten, but as a standing gate revisited any time the workflow's capabilities meaningfully expand (a new tool added, a new external system wired in, a new class of user given access). Each item links back to the Part that implements it, so an unchecked item isn't just a flag, it's a pointer to exactly where in this series to go build the missing piece. Treat a "no" answer to any item not as a note for later, but as an open task with a known, specific fix already written up elsewhere in this series.

## 1. Cost Caps

- [ ] Per-run step ceiling enforced in code — Part 1, §6-7
- [ ] Per-plan step-count cap enforced — Part 4, §2
- [ ] Refinement/critique retry ceiling enforced in the router — Part 5, §4
- [ ] Re-plan attempt ceiling enforced — Part 4, §6
- [ ] Daily org-wide spend cap checked before every new run — Part 8, §5
- [ ] Per-user daily spend cap checked, separate from org cap — Part 8, §9
- [ ] Automated cost-watchdog alert wired — Part 7, §7
- [ ] Every run's actual cost is recorded via Langfuse trace data — Part 7, §6; Part 8, §5

Read this section top to bottom and notice it's ordered from the smallest, tightest scope to the largest, loosest one: a per-run step ceiling bounds a single loop iteration's blast radius (Part 1's original guardrail against runaway loops); a per-plan cap and re-plan cap bound a single multi-step task; a daily cap bounds an entire day's worth of traffic across every user; a watchdog alert is the safety net that catches whatever the hard caps, for whatever reason, didn't. That progression matters because these caps are not redundant with each other — each one closes a gap the others structurally cannot see. A per-run ceiling has no visibility into how many *other* runs are happening concurrently; only the daily cap from Part 8 can see that. A hard cap enforced in code has no mechanism to notify a human that it's being approached; only the watchdog from Part 7 does that. Checking every box in this section isn't over-engineering — each one is guarding a genuinely different failure surface.

## 2. Hallucination Guardrails

- [ ] Every tool has a Zod schema — Part 2, §2
- [ ] Tool descriptions explicitly scope *when* to use the tool — Part 2, §3
- [ ] Critique node checks factual claims are traceable to conversation/tool-result content — Part 5, §3
- [ ] Grounding step injects relevant long-term memory with a similarity threshold — Part 3, §7
- [ ] Golden dataset includes cases catching fabricated tool calls/unsupported claims — Appendix B, §2
- [ ] Tool-use accuracy tracked as a standing metric — Appendix B, §4

This section is explicitly called out in the sign-off rule at the bottom of this document as one of the two blocking categories, and it's worth understanding why hallucination specifically earns that treatment rather than being just one more quality concern among many. A hallucinated fact in an agent's answer isn't a bug that degrades gracefully — it's confidently, plausibly wrong output that a user has no independent way to distinguish from correct output, which is precisely what makes it dangerous in exactly the domains (real user data, real external actions) this checklist gates. Every item in this section attacks the problem from a different angle: schema and scoped descriptions (Part 2) reduce the odds a tool is even called inappropriately in the first place; the Critique traceability check (Part 5) catches a hallucinated claim after generation but before it reaches the user; grounding with a similarity threshold (Part 3) reduces the odds the model has to fabricate in the first place, by giving it real relevant context to draw from; and the golden dataset plus standing metric (Appendix B) is what tells you, on an ongoing basis, whether all of the above is actually holding up under real traffic, not just working in the specific cases someone thought to test manually.

## 3. Human-in-the-Loop (HITL) Confirmation

- [ ] Irreversible-side-effect tools require explicit `confirmed: z.literal(true)` — Part 2, §9
- [ ] Critique verifies confirmation was set from a real prior user statement, not model inference — Part 5, §9
- [ ] An escalation path exists for repeated Critique failures — routes to human review, no silent shipping — Part 5, §6
- [ ] The escalation path has a real destination (n8n workflow paging a human/on-call) — Part 6, §4
- [ ] No tool can execute unbounded/arbitrary actions without a narrow, parameterized interface — Part 2, §4

The other blocking category, and it's worth reading these five items as two related but distinct concerns rather than one undifferentiated list. The first two items are about *confirmation* — making sure an irreversible action only happens when a real human genuinely authorized it, checked at two independent layers (the schema itself, per Part 2, and a separate reasoning pass verifying the schema's confirmation was earned honestly, per Part 5's defense-in-depth argument). The last three items are about *escalation and scope* — making sure that when the system can't confidently proceed on its own, it has somewhere real to hand off to, and that no tool exists in the system with a blast radius wide enough to make that handoff insufficient in the first place (the narrow, parameterized interface requirement from Part 2, section 4, echoed again for exactly this reason). A workflow can pass every item in section 2 — never hallucinating a single fact — and still cause real, irreversible harm if it correctly, accurately decides to take an action nobody actually authorized. That's precisely why this section is separate from section 2 in the checklist, and why both are named explicitly in the sign-off rule below rather than folded into one generic "safety" bucket.

## 4. Audit Logging

- [ ] Every run traced end-to-end (reasoning + tool calls + external n8n actions) in one observability system — Part 7, §4-5
- [ ] Outbound actions to external systems carry a correlation ID back to the originating agent run — Part 6, §6; Part 7, §5
- [ ] Full message transcript (not just the trimmed model-visible window) preserved as the append-only audit record — Part 1, §4; Part 3, §2
- [ ] Every deployed agent version tagged and included in trace metadata — Part 8, §6
- [ ] Per-run cost, latency, and pass/fail against golden dataset queryable historically — Part 7, §6; Part 8, §5; Appendix B, §3

Notice this section isn't really about preventing anything at the moment it happens — every item here is about being able to answer questions *after the fact*, which is a different, complementary kind of safety than sections 1-3 provide. Sections 1-3 are about stopping bad outcomes before they occur; this section is about guaranteeing that if something goes wrong anyway — and in a probabilistic system, per Part 7's opening argument, something eventually will — there's a complete, honest record of what actually happened, not a partial one reconstructed after the fact from fragments. The third item is worth flagging specifically: it insists on the *full*, untrimmed transcript as the audit record, explicitly not the windowed view Part 3's `windowForModel` sends to the model on any given turn. Those two views were deliberately built to diverge back in Part 3 precisely so this requirement could be satisfied — an audit log that only contained what the model happened to see on its last turn would be missing everything that got trimmed away, at exactly the moment someone needs the complete history to understand what went wrong.

## 5. Security & Secrets

- [ ] No API keys/credentials committed to source control or baked into container images — Part 8, §2, §4
- [ ] Model client fails fast at startup if required credentials are missing — Part 8, §4
- [ ] Documented key-rotation procedure exists and is exercised on a schedule — Part 8, §4
- [ ] n8n and Langfuse admin interfaces not exposed without authentication — Part 6, §3; Part 7, §3; Part 8, §3
- [ ] Database access from tools is parameterized (no string-concatenated queries) — Part 2, §4

This is the one section in the checklist whose items aren't specific to agentic systems at all — every item here is standard, unglamorous application-security hygiene that would apply equally to any web service. It's included anyway, deliberately and without apology, because it's exactly the category of item that's easiest to assume "someone else already handled" on a project where most of the interesting engineering effort went into the reasoning layer. An agent with perfect Reflection, airtight confirmation gating, and a beautifully instrumented Langfuse trace is still a serious liability if its Postgres credentials are sitting in a committed `.env` file. Don't let the sophistication of sections 1-4 create a false sense that section 5's more mundane items matter less.

## 6. Reliability & Resilience

- [ ] Tools distinguish retryable vs. non-retryable failures in their return type — Part 2, §2
- [ ] Transient network failures retried with exponential backoff + jitter before surfacing to the model — Part 6, §8-9
- [ ] Model client is provider-agnostic (swap via env var, no code change) — Part 1, §5
- [ ] Redeploys don't unnecessarily restart dependent infra services — Part 8, §7

This section is about a different kind of failure than sections 1-5: not "the agent did something wrong," but "the agent, or its infrastructure, stopped working, or degraded, for reasons entirely outside its own reasoning." A `retryable` flag that's honestly set, a real backoff-with-jitter implementation, a swappable model provider, and a redeploy process that doesn't cause unnecessary collateral downtime are all, in their own way, about the system's ability to absorb the ordinary, expected friction of operating real infrastructure — network blips, provider outages, routine deploys — without that friction becoming a user-visible incident or an unnecessary reasoning-layer cost, per the "push solved problems into deterministic code" principle this series returned to at every layer, most recently in Part 9b's mechanical-fix exercise.

## 7. Evaluation Gate (Pre-Merge / Pre-Deploy)

- [ ] Golden dataset eval suite runs automatically in CI on any prompt/tool/graph change — Appendix B, §3
- [ ] A regression in tool-use accuracy or forbidden-tool-call blocks merge — Appendix B, §3-4
- [ ] LLM-as-judge scores used as triage signal only, never sole automated gate for safety-critical behavior — Appendix B, §5

Every other section in this checklist is a property of the *running system*; this section is a property of the *process that changes it*. It's worth including as its own category rather than folding it into any of the above, because a system that satisfies every item in sections 1-6 today can still silently regress on any of them tomorrow, the moment someone ships a prompt tweak that wasn't run against Appendix B's golden dataset first. This section is what keeps the rest of the checklist true over time, not just at the moment it was last checked — it's the mechanism, not just one more property.

## 8. Pattern-Fit Sanity Check

- [ ] Chosen pattern justified against Appendix A's decision heuristic — not defaulted to out of habit
- [ ] If Reflection is used, its measured latency/cost overhead weighed against measured first-pass-success benefit for this specific use case

The final section, and deliberately the least mechanical item on the entire checklist — there's no code snippet to point to here, only a question to have genuinely asked and answered. It exists as a check against a very specific failure mode that everything else in this checklist can't catch: a system that is *safe* by every measure above, but *needlessly expensive or slow*, because it's running Reflection, or Plan-and-Execute, or Multi-Agent, out of habit or ambition rather than measured need. This is the checklist's one explicit callback to Appendix B, section 6's benchmarking discipline — before signing off, have you actually run the comparison, or are you trusting an assumption that the more sophisticated pattern must be the safer or better choice? Appendix A argued at length that more expensive does not mean more reliable; this item is where that argument gets checked against your specific system's actual numbers, one last time, before it goes live.

---

**Sign-off rule of thumb:** if any item under sections 2 ("Hallucination Guardrails") or 3 ("HITL Confirmation") is unchecked for a workflow touching real user data or real external actions, treat that as blocking — those two sections are where an ungoverned agent causes real-world harm. Every other section in this document matters, and an unchecked item elsewhere should be treated seriously and fixed promptly — but sections 2 and 3 are qualitatively different from the rest: a gap in cost caps produces a bigger bill; a gap in audit logging produces a harder debugging session after the fact; a gap in security produces a real but bounded, and eventually detectable, exposure. A gap in hallucination guardrails or HITL confirmation produces a system that can confidently tell a user something false, or take an action nobody actually wanted, in the moment, with no opportunity to catch it before it happens. That asymmetry — between harms that are costly or inconvenient to discover later, and harms that are simply already done the instant they occur — is the entire reason this rule of thumb singles out exactly these two sections, and it's the last, and arguably the most important, piece of judgment this entire series is trying to leave you with: not every guardrail is equally urgent, and knowing which ones genuinely cannot wait is itself part of the job.

## Closing Note

This checklist closes out the series. Parts 1 through 9b built a working system, piece by piece, each addition justified by a specific, named failure mode it closed off. Appendix A gave that system's next builder a way to choose *which* pieces a new problem actually needs. Appendix B gave them a way to *measure* whether those choices were right, on their own data, rather than trusting a general heuristic on faith. And this Appendix compresses everything both of those taught into the one document meant to be open, literally, at the moment a real workflow is about to touch real data or take a real irreversible action — the moment where all the careful reasoning from the previous thirteen documents either gets applied, or doesn't.
