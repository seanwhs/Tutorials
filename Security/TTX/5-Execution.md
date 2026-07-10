## Part 5 — Case Study Execution: Running the Live Session

This is where the tabletop becomes real for the participants. The facilitator’s job is to preserve enough realism to generate useful behavior, while keeping the room safe, paced, and within the rules of engagement.

### Concept: Execution Is a Controlled Conversation

A live tabletop is not a performance. It is a structured conversation under pressure, with timed stimuli and visible decision points. The best sessions feel calm on the surface but are carefully orchestrated underneath.

Your goal in this phase is to observe how the organization actually behaves when:

- Multiple signals arrive at once.
- Ownership is unclear.
- Someone asks for authority that is not immediately present.
- Business impact starts to matter more than technical curiosity.

That means the facilitator must do three things at once:

- Keep the scenario moving.
- Keep the room in role.
- Keep the data useful for the AAR.

If you rescue the room too quickly, you lose the signal. If you let it drift too long, you lose the structure. The art is in that middle space.

### Case Study Walkthrough: ACME Goes Live

ACME’s live session lasts about three and a half hours. The lead facilitator opens with a short reminder of the purpose, the maturity level, the RoE, and the fact that this is a learning exercise, not a performance review. Observers are introduced, the scribe is visible, and the white cell is ready.

The room starts in a relatively relaxed state. That is intentional. The exercise should not begin in panic mode; it should begin like a real day that slowly becomes difficult.

#### 5.1 Opening the Exercise

The first few minutes are about setting rhythm:

- Confirm participant roles.
- Reiterate pause authority.
- Remind everyone where exercise communications will happen.
- Tell observers to stay silent and log only.

This opening matters because it establishes behavioral norms before the first inject arrives. Without that, the room can easily fracture into side conversations, premature solving, or “who’s driving?” confusion.

#### 5.2 Early Phase: Ambiguity

The first inject is a suspicious login event. The SOC treats it like a possible false positive. That is normal and, in fact, desirable. The exercise is supposed to show how the team handles uncertainty.

Then a help-desk call inject arrives. Now the incident has a human element. The room begins to connect signals. Some people want to declare a breach; others want more evidence. That tension is exactly what the facilitator wants to observe.

At this stage, the facilitator should resist the urge to clarify too much. Real incidents begin in ambiguity, and the exercise should preserve that feeling long enough to expose triage behavior.

#### 5.3 Middle Phase: Ownership Pressure

As the internal scan alert appears, the session moves from recognition to ownership. The central questions become:

- Who is leading?
- Who is documenting?
- Who is validating evidence?
- Who has authority to contain?
- Who needs to be informed now versus later?

This is where many teams slow down. That slowdown is valuable. It often reveals that the organization has a response plan, but not a shared mental model of how it activates in practice.

At ACME, this is where the facilitator notices a silence. Nobody wants to be the first to commit to containment. The facilitator lets the silence stand for a moment, then asks a narrow question rooted in the IRP: what does the plan say about isolation authority? The room moves again. The facilitator has not solved the problem; they have just nudged the team back toward its own documented process.

#### 5.4 Late Phase: Executive Impact

By the time the ransom note appears, the exercise shifts from technical investigation to business response. Legal is involved. Comms may be pulled in. Leadership wants a concise answer: how bad is it, what do we know, and what are we doing next?

This is where ACME learns whether the SOC can translate technical signals into business language. It is also where the team discovers whether its escalation path is actually usable under time pressure.

The facilitator should now watch for:

- Clear severity classification.
- A named incident lead.
- A coherent containment plan.
- A communication decision.
- A sense of what must happen in the next hour.

#### 5.5 Red Herrings and Decision Quality

ACME includes one unrelated phishing ticket as a red herring. The team correctly deprioritizes it. That sounds minor, but it is a strong signal of judgment. Good tabletop design should include at least one distraction so the team can demonstrate prioritization rather than just linear reaction.

A well-run live exercise often produces this kind of mixed result:

- Some decisions are excellent.
- Some are late.
- Some are blocked by missing authority.
- Some are technically right but operationally awkward.

That mix is normal. The exercise is not about perfection. It is about visibility.

### Action: Run the Session With Structure

Before the session:

- Confirm the schedule.
- Test all rooms and channels.
- Load the facilitator notes.
- Prepare the observer logs.
- Reconfirm pause/stop authority.
- Review the escalation path.

During the session:

- Deliver injects on time.
- Keep the room in role.
- Ask short, narrow questions.
- Log delays and assumptions.
- Do not over-explain.
- Use silence as a diagnostic tool.

After the session:

- Capture hot-wash notes immediately.
- Collect observer logs.
- Identify the biggest decision gaps.
- Flag anything that needs follow-up before the AAR.

***

## Part 6 — Facilitation Mastery

The quality of the exercise depends less on how dramatic the scenario is and more on how disciplined the facilitator is. A good facilitator is part referee, part conductor, and part note-taker. They do not dominate the room; they shape the conditions that let the room reveal itself.

### Concept: Facilitation Is Controlled Restraint

There are a few rules that make facilitation work:

- Do not answer for the team too early.
- Let confusion exist long enough to become visible.
- Keep the pace moving without rushing decisions.
- Use the IRP as a reference point instead of a script to read aloud.
- Separate what the team knows from what the facilitator knows.

In other words, the facilitator must know the whole story without becoming the story.

### Case Study Walkthrough: ACME’s Facilitation Choices

At ACME, one of the most revealing moments happens when the room pauses waiting for approval from a manager who is not present. The facilitator does not fill the silence. Instead, they ask who, according to the IRP, actually owns that decision if the manager is unavailable.

That question matters because it moves the room from dependence on a person to dependence on a process. That is the real test.

Later, when the team latches onto one alert and ignores broader signals, the facilitator introduces a carefully chosen contradiction. Not enough to derail the story, but enough to force a reassessment. The purpose is not to trick the participants. The purpose is to reveal whether they can widen their thinking when the evidence changes.

### The 2-Minute Stall Rule

A practical facilitation rule is the **2-minute stall rule**:

- If the room gets stuck on a process question, wait briefly.
- Let participants self-correct if they can.
- If the stall persists, nudge with a reference to the IRP or an obvious escalation question.
- Do not answer for them unless the exercise would collapse without help.

This keeps the room accountable while preventing dead air from becoming frustration.

### White Cell Discipline

The white cell is the guardian of consistency. It should be the only place where scenario truth is edited or clarified. If the facilitator, observer, or participants start inventing facts independently, the exercise loses coherence quickly.

The white cell should maintain:

- A canonical answer sheet.
- A list of facts that can be revealed immediately.
- A list of facts that can only be revealed after a trigger.
- A record of any improvisations made during the session.

That record becomes valuable later when you review why certain paths occurred.

### Action: Create a Facilitation Playbook

Create a note such as `06-Facilitation/facilitator-playbook.md` and include:

- Opening script.
- Pause/stop rules.
- Stall handling.
- Nudge patterns.
- White cell rules.
- Observer behavior rules.
- Escalation phrasing examples.

A few useful facilitation prompts:

- “What does your process say happens next?”
- “Who owns that decision if the named person is unavailable?”
- “What would you need to know before escalating?”
- “What assumption are you making right now?”
- “What would change your mind?”

These prompts keep the discussion analytical rather than speculative.

***

## Part 7 — Case Study AAR: Turning Logs Into a Roadmap

The exercise only becomes valuable when the observations are turned into action. That happens in the AAR. This is where raw notes become findings, and findings become accountable work.

### Concept: The AAR Is a Translation Layer

People often leave tabletop exercises with a lot of information but very little structure. The AAR translates that raw material into something the organization can execute.

A good AAR answers:

- What happened?
- What did the team do?
- Where did the process work?
- Where did it fail?
- What should change?
- Who owns the change?
- When will it be done?

If a finding does not lead to an owner and date, it is not really a finding yet.

### Case Study Walkthrough: ACME’s AAR

ACME’s incident log is messy in the way real human logs always are. It contains timing notes, assumptions, hesitations, and a few fragments of dialogue. During the AAR, those fragments are cleaned up and grouped into meaningful categories.

A sample transformation looks like this:

- Raw note: “Team waited for manager approval before isolation.”
- Clean finding: Isolation authority was not clearly delegated in the IRP.
- Category: Policy / Governance gap.
- Impact: Slowed containment decision-making during a realistic exercise.
- Owner: IR Lead.
- Due date: A specific, near-term date.
- Validation: Re-test in a micro-TTX or targeted drill.

ACME also discovers:

- Handoff between SOC and IR was less clean than expected.
- Backup recovery confidence was assumed rather than verified.
- Legal was engaged effectively once the trigger threshold was clear.
- The team benefited from a red herring because it showed prioritization discipline.

These are not all equally severe, but they are all useful.

### Finding Quality

Strong findings have a few properties:

- They describe behavior, not just symptoms.
- They point to a root cause or process gap.
- They are actionable.
- They are measurable.
- They can be assigned to someone specific.

Weak findings sound like this:

- “Communication needs improvement.”
- “The team should be faster.”
- “More training is needed.”

Those are not yet findings. They are categories of disappointment. A better AAR converts them into concrete deltas.

### Action: Turn Notes Into a Roadmap

Use a note structure like this:

```markdown
# AAR — Operation Red Horizon

## Exercise Summary
- Date:
- Participants:
- Maturity level:
- Scenario:
- Duration:

## Key Observations
- ...

## Findings
### F-01 — Isolation authority unclear
- Category: Policy / Governance
- Impact: Delayed containment decision
- Owner: IR Lead
- Due date: YYYY-MM-DD
- Validation: Micro-TTX

### F-02 — SOC to IR handoff lacked context
- Category: Execution
- Impact: Slowed shared understanding
- Owner: SOC Manager
- Due date: YYYY-MM-DD
- Validation: Handoff drill
```

Then convert findings into a roadmap note that your leadership team can review.

***

## Part 8 — Institutionalizing the Program

The real goal is not to run one good exercise. The goal is to make tabletop exercises part of the organization’s normal resilience practice.

### Concept: Turn the Exercise Into a Control

Once a single exercise is complete, the organization should not think, “We did that once.” It should think, “We now have a repeatable control that tells us where we are getting stronger and where we still rely on luck.”

A mature program has:

- A cadence.
- A backlog of findings.
- A method for verifying closure.
- A repeatable way to introduce new scenarios.
- A maturity path from discussion to operations-based exercises.

### Case Study Walkthrough: ACME’s Program Mindset

After Red Horizon, ACME does not stop. They schedule smaller follow-up sessions to validate the most important findings. They also plan their next tabletop around a different scenario family so they do not overfit the organization to one storyline.

They track:

- Whether the same gap reappears.
- Whether the new process is actually used.
- Whether people remember the last exercise.
- Whether response speed improves.
- Whether ownership is clearer the second time.

That is how a tabletop program starts to behave like a living control.

### Action: Define Your Cadence

Create a note like `05-Roadmap/program-plan.md` with:

- Quarterly L1/L2 exercises.
- Semiannual follow-up validation.
- Ad-hoc micro-exercises for high-severity findings.
- Annual maturity review.
- Metrics:
  - Time to first action.
  - Time to escalation.
  - Percent of findings closed on time.
  - Repeat finding rate.

***

## Conclusion and Roadmap

Part 5 showed how a tabletop actually runs, from opening script to live injects to hot-wash behavior. Part 6 showed why facilitation discipline matters so much. Part 7 converted the exercise into findings and a hardening roadmap. Part 8 turned the whole thing into a repeatable program rather than a one-time event.

The series is now at the point where the remaining work is about **institutionalization**:

- Make the lessons visible.
- Close the findings.
- Re-run targeted validations.
- Build the next scenario with better realism and tighter ownership.
