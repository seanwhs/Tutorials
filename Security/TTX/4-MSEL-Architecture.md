## Part 4 — The Inject Engine & MSEL Architecture

This is the part where the tabletop stops being “a scenario” and becomes a timed decision engine. The MSEL is the facilitator’s private control surface: it defines what happens, when it happens, what the team is supposed to do, and what the facilitator should do if the room stalls.

### Concept: The MSEL Is the Clock

A Master Scenario Events List is not just a spreadsheet of events. It is the exercise’s rhythm section, keeping the live session moving at a pace that creates pressure without destroying clarity. Good injects create decisions; bad injects create noise.

The best way to think about an inject is this:

> An inject is a controlled piece of information that forces the team to interpret, prioritize, and act.

That means every inject should have a purpose. If an inject does not change the team’s understanding, sharpen a decision, or expose a gap, it probably does not belong in the exercise.

A strong MSEL usually includes:

- A planned time.
- The inject content.
- The delivery channel.
- The expected response.
- The ATT&CK or threat-model theme it supports.
- The actual response and any variance.
- A facilitator note for what to do next if the team stalls.

If your earlier parts were about deciding **what** to test, this part is about deciding **how the story unfolds in motion**.

### Why Inject Design Matters

Poor inject design produces one of two failures:

- The room gets too much information too quickly and starts guessing.
- The room gets too little structure and drifts into generic discussion.

Good inject design creates a clean escalation path:

1. Something looks odd.
2. Someone investigates.
3. New context appears.
4. Ownership becomes necessary.
5. Decisions have consequences.
6. The business impact becomes real.

That progression is what makes the tabletop useful. It shows how the team responds when the incident is still forming, not just when it is already obvious.

### Case Study Walkthrough: ACME’s Red Horizon MSEL

ACME’s exercise team wants the session to feel realistic, not theatrical. So they build the inject chain to mirror how a real vendor-compromise event might unfold inside a hybrid enterprise.

They deliberately avoid opening with ransomware. Instead, they start with something ambiguous and let the shape of the incident emerge.

#### The logic behind ACME’s ordering

- First: a suspicious but not conclusive signal.
- Next: a human report that adds texture.
- Then: a technical alert that supports correlation.
- Then: a clue that widens the impact.
- Finally: the business-altering event that forces executive involvement.

This sequence matters because it tests whether the SOC can recognize a pattern before the whole room becomes convinced by hindsight.

#### ACME’s inject philosophy

ACME’s lead facilitator wants each inject to do one of four things:

- Confirm a suspicion.
- Complicate the story.
- Force ownership.
- Force escalation.

If an inject does none of those, it is probably decorative. Decorative injects waste time.

### Anatomy of a Good Inject

A strong inject has a few essential properties:

#### 1. It is credible

The team should be able to imagine that this really happened in their environment. If it sounds like a movie plot, it will reduce the seriousness of the exercise.

#### 2. It is incomplete

Real incidents never arrive fully explained. An inject should create uncertainty, not remove it.

#### 3. It is actionable

Participants should be able to do something with it: triage it, escalate it, correlate it, or ignore it for a reason they can defend.

#### 4. It is sequenced

The order matters. The same inject can feel weak or powerful depending on when it appears.

#### 5. It has a fallback

If the room misses the point, the facilitator should know what nudge comes next.

### MSEL Structure in Practice

Here is a practical MSEL structure you can use in Markdown:

```markdown
# MSEL — Operation Red Horizon

| Time | Inject ID | Inject Content | Delivery Channel | Expected Response | ATT&CK Theme | Actual / Variance | Notes |
|------|-----------|----------------|------------------|-------------------|--------------|-------------------|-------|
| T+00:05 | INJ-01 | Impossible-travel login alert for vendor account | Chat | SOC triages, records, and begins correlation | Valid Accounts | | |
| T+00:15 | INJ-02 | Help-desk receives call about “IT support” from vendor context | Voice | Help desk verifies, logs, escalates | Initial Access / Social Engineering | | |
| T+00:30 | INJ-03 | Internal scan alert on a sensitive subnet | Chat | Team correlates with prior signals | Discovery | | |
| T+00:45 | INJ-04 | Privileged access anomaly appears in logs | Chat | IR leadership is engaged | Privilege Escalation / Credential Access | | |
| T+01:05 | INJ-05 | Ransom note appears on shared file system | Email / Chat | Incident response is formally activated | Impact | | |
```

You can expand this table with columns for:

- Owner.
- Severity.
- Decision required.
- Escalation path.
- Triggered artifact.
- Freeze / pause point.

### Expected Response Is the Real Heart of the MSEL

The “expected response” column is more important than the inject itself. It tells you what the exercise is trying to prove.

For example:

- If the inject is an impossible-travel alert, the expected response might be:
  - Triage it.
  - Verify whether it matches a vendor account.
  - Correlate with prior alerts.
  - Escalate if evidence strengthens.

That means the exercise is not just checking whether someone notices the alert. It is checking whether they know what to do with it.

For ACME, the expected response also reveals process maturity:

- Do they have clear triage ownership?
- Do they know when SOC hands off to IR?
- Do they have a threshold for vendor access escalation?
- Do they document assumptions, or do they speak in vague guesses?

### Delivering Injects Without Breaking the Room

An inject should feel like a normal signal entering the organization, not like a narrator stepping into the room. That means the delivery channel matters.

Use channels that match the artifact:

- Chat for SIEM-style alerts.
- Email for external contact or executive messages.
- Voice for help-desk calls or urgent escalation.
- Shared document for logs or status updates.
- Breakout room message for role-specific events.

A good facilitator keeps the channel believable. If every inject arrives through the same obvious channel, the exercise starts feeling artificial.

### How to Handle Variance

Variance is the gap between what you expected and what actually happened. Do not treat it as failure by default. Sometimes variance is where the most valuable learning lives.

Common examples:

- The team escalates too slowly.
- The team escalates too quickly.
- The wrong person owns the next step.
- The team asks for evidence you did not plan to provide.
- The team correctly spots the issue but misreads its severity.

A healthy facilitator does not fight variance. They log it, understand it, and decide whether it requires a nudge, a reveal, or a later AAR finding.

### Facilitator Notes: The Hidden Layer

The MSEL should include private notes only the facilitator sees. These notes are not for participants; they are your pacing safety net.

For each inject, write down:

- Why the inject exists.
- What the likely wrong path is.
- What clue comes next if the room stalls.
- Whether you should hold, push, or pivot.
- Whether the inject is optional if the room is already ahead.

Those notes are what keep the exercise adaptable without losing discipline.

### Action: Build the MSEL as a Decision Map

Create a file like:

`02-MSEL/msel-operation-red-horizon.md`

Use a structure like this:

```markdown
# MSEL — Operation Red Horizon

## Session Goal
Validate how ACME detects, escalates, and responds to a vendor VPN compromise that develops into ransomware.

## Design Principles
- Front-load ambiguity.
- Escalate pressure gradually.
- Tie every inject to a decision point.
- Keep all delivery channels believable.
- Record variance, not just outcomes.

## Inject Table
| Time | Inject ID | Inject Content | Channel | Expected Response | Variance | Facilitator Notes |
|------|-----------|----------------|---------|-------------------|----------|-------------------|
| T+00:05 | INJ-01 | Suspicious vendor login from unusual geography | Chat | SOC triages and correlates | | If stalled, ask what the IRP says about initial triage. |
```

Then extend it for the full exercise.

### What to Avoid

Avoid injects that are:

- Purely decorative.
- Too obscure to act on.
- Too obvious to create thought.
- Too many in a row without a decision point.
- So technical that only one role understands them.

A tabletop should force collaboration. If only one person can decode the inject, the rest of the room becomes passive.

### Case Study Detail: ACME’s First Inject Sequence

ACME’s first few injects are intentionally modest:

1. Suspicious login event.
2. Help-desk call about vendor support activity.
3. Internal scan alert.

Why start small? Because ACME wants to see whether the team will connect signals or treat them as unrelated noise. If the room cannot connect the early dots, later injects won’t teach much beyond “the incident got worse.”

That is why the MSEL must be designed like a staircase, not a cliff.

### Roadmap to the Live Session

Once the MSEL is built, you are ready for the live exercise. The next part will show how ACME runs the session, how the facilitator paces it, and how the room behaves when the incident becomes real enough to matter.

The next focus will be:

- Opening the session cleanly.
- Delivering injects on schedule.
- Handling silence and confusion.
- Managing executive attention.
- Capturing useful observational data without derailing the room.
