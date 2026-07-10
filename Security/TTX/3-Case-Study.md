## Part 3 — Case Study Prep: Building Operation Red Horizon

Preparation is where the scenario becomes runnable, not just interesting. This is the phase where ACME turns a believable ransomware story into a controlled exercise package with timing, artifacts, roles, and a facilitator plan.

### Concept: Prep Is the Exercise Before the Exercise

A good tabletop does not start in the live session. It starts when the planning team agrees on what evidence the players will see, what decisions the exercise is meant to force, and where the boundaries are. That prep work is what gives the live session its realism without letting it become chaotic.

At this stage, your goal is to answer six questions:

1. What exactly are we testing?
2. Who is participating?
3. What will they be shown?
4. What will remain hidden?
5. How will the session be paced?
6. How will we capture observations cleanly?

If those questions are unclear, the exercise will drift. If they are clear, the live session can stay flexible without losing control.

### Case Study Walkthrough: ACME’s Two-Week Prep

ACME starts two weeks before the scheduled session. The senior IR lead acts as lead facilitator, while a small white cell handles scenario truth, artifacts, and timing. The goal is not just to make the exercise realistic; the goal is to make the exercise repeatable enough that they can run it again later with a different group or a different scenario.

#### 3.1 The Prep Team

ACME assigns roles early:

- **Lead Facilitator**: Drives the session, delivers injects, keeps the room moving.
- **White Cell**: Holds the canonical scenario truth and answers hard questions consistently.
- **Scribe**: Captures decisions, timestamps, and notable quotes.
- **Observers**: Watch silently and log behavior, assumptions, and delays.
- **Participants**: SOC, IR, IT, Legal, and Comms roles as appropriate.

They agree on one important rule: nobody improvises a new reality during the exercise. If a participant asks a question about the scenario, the white cell decides the answer in advance or has a fast decision rule for it.

#### 3.2 The Prep Folder

ACME creates a dedicated folder in their Obsidian vault:

`03-Prep/Operation-Red-Horizon/`

Inside it, they keep:

- `readme.md`
- `participants.md`
- `artifact-index.md`
- `msel-draft.md`
- `observer-notes-template.md`
- `white-cell-notes.md`
- `room-plan.md`
- `rehearsal-notes.md`

This folder becomes the working package for the entire exercise lifecycle. It also makes future reruns much easier, because they can clone the structure and swap in a new scenario.

#### 3.3 What ACME Prepares

ACME’s prep package includes several concrete assets:

- A concise scenario summary.
- A draft Master Scenario Events List.
- A set of safe, realistic artifacts.
- A communication plan for the live session.
- A room layout that supports the session structure.
- A participant briefing note.
- Observer instructions.
- A short white cell reference sheet.

The most important part is not the volume of files. It is the consistency between them. If the scenario says a vendor account was compromised, the artifacts, injects, room roles, and white cell answers all need to reinforce that same story.

#### 3.4 Artifact Discipline

ACME prepares artifacts that look operational but stay safe:

- Simulated SIEM screenshots.
- A fake or sanitized vendor access alert.
- A mock help-desk call note.
- A ransom note preview.
- A journalist inquiry email.
- A short executive status update draft.

The team intentionally prepares two versions of key artifacts:

- A clean version for the main path.
- A noisier version with extra distraction for adaptation if the room progresses faster or slower than expected.

That trick gives the facilitator pacing flexibility without rewriting the scenario live.

#### 3.5 Rehearsing the Unknowns

The white cell runs a short rehearsal before the actual session. They do not rehearse the whole exercise like actors. Instead, they rehearse the likely failure points:

- What if participants ask about the vendor MFA exception early?
- What if Legal joins before the ransomware stage?
- What if the SOC misclassifies the initial alert and gets stuck?
- What if the team wants to isolate systems before the scenario is ready for that step?

The point of rehearsal is to keep the response consistent. In a tabletop, inconsistency destroys trust faster than a bad inject.

### Action: Build Your Prep Package

Create a prep folder like this:

```text
03-Prep/
  Operation-Red-Horizon/
    readme.md
    participants.md
    artifact-index.md
    msel-draft.md
    observer-notes-template.md
    white-cell-notes.md
    room-plan.md
    rehearsal-notes.md
```

Use the following structure for `readme.md`:

```markdown
# Operation Red Horizon — Prep Package

## Purpose
Prepare and run a facilitated tabletop exercise focused on ransomware via compromised vendor VPN access.

## Exercise Level
L2 — Facilitated Table Read

## Participants
SOC, IR, IT Operations, Legal, Comms, Executive Observer

## Core Questions
- How do we detect the issue?
- Who owns escalation?
- How do we decide containment?
- How do we communicate internally and externally?

## Working Rules
- All exercise communication stays in designated channels.
- White cell holds canonical scenario truth.
- Observers do not intervene.
- Artifacts are sanitized and safe to share.
```

Use `artifact-index.md` to list every artifact, its purpose, and where it appears in the session.

***

## Part 4 — The Inject Engine & MSEL Architecture

### Concept: The MSEL Is the Facilitator’s Clock

The Master Scenario Events List is the hidden engine behind the tabletop. It tells the facilitator what to deliver, when to deliver it, what response to look for, and what to do if the room goes off script. Without it, the exercise becomes improvised storytelling.

A strong MSEL is not just a timeline. It is a decision structure.

Each inject should have:

- A planned time.
- A delivery channel.
- A clear purpose.
- An expected response.
- A likely variance.
- A follow-up action if the team stalls.

If you design injects well, the exercise will feel natural. If you design them poorly, it will feel like a random stream of bad news.

### Case Study Walkthrough: ACME’s Inject Logic

ACME deliberately front-loads ambiguity. The first inject is not the ransomware note. It is a suspicious login event that could be benign, noisy, or serious. That forces the SOC to interpret rather than react automatically.

As the session continues, ACME stacks injects in a way that tests prioritization:

- First, a login anomaly.
- Then, a help-desk report.
- Then, an internal scan alert.
- Then, signs of broader compromise.
- Finally, the ransom note and business impact.

That sequence matters because it tells the facilitator where the room is mentally. If the team is still treating the first clue as a one-off, the later injects should widen the frame. If the team is already escalating correctly, the facilitator can move faster.

### Action: Build the MSEL in Markdown

Use a table like this:

```markdown
# MSEL — Operation Red Horizon

| Time | Inject | Channel | Expected Response | ATT&CK Theme | Actual / Variance |
|------|--------|---------|-------------------|--------------|-------------------|
| T+00:05 | Impossible-travel login alert | Chat | SOC triages and correlates | Valid accounts | |
| T+00:15 | Help desk call about vendor request | Voice | Record, verify, escalate | Initial access | |
| T+00:30 | Internal scan alert | Chat | Correlate with prior signal | Discovery | |
| T+01:05 | Ransom note appears | Email / chat | Activate leadership response | Impact | |
```

For each inject, also note:

- What assumption it is designed to challenge.
- What decision it forces.
- What “good enough” response looks like.
- What the next clue should be if the room stalls.

If you want the exercise to stay useful, every inject must earn its place.

***

## Part 5 — Case Study Execution: Running the Live Session

### Concept: Execution Is About Discipline, Not Drama

The live session is where the preparation gets tested. This is not the time to improvise the scenario for excitement. It is the time to hold the room steady, let the participants think, and record what actually happens.

A skilled facilitator does three things well:

- Keeps the pacing coherent.
- Preserves realism.
- Prevents confusion from turning into chaos.

### Case Study Walkthrough: ACME Goes Live

ACME opens the session with a brief recap of the Rules of Engagement. The lead facilitator reminds everyone that the goal is learning, not scoring. The scribe starts logging. Observers stay quiet. The white cell is ready.

#### 5.1 Early Session

The first inject arrives: a suspicious login alert. The SOC initially treats it like a noisy false positive. That is expected. The exercise is not about whether they guess right instantly; it is about whether they can recognize a pattern before it becomes obvious.

A few minutes later, a help-desk report arrives about a vendor asking for remote access help. The room begins to connect the dots. Some participants still focus on the first alert, while others widen the frame. That tension is useful because it shows whether the team can share context quickly.

#### 5.2 Mid-Session

The next inject is an internal scan alert. Now ACME has enough signals to test ownership. Who should lead? Who escalates? Who decides whether to involve Legal? Who decides whether the vendor is contacted?

At one point, the room goes quiet. Nobody wants to be the first to claim authority. The facilitator waits. Silence is data. Then the facilitator asks a restrained question: what does the IRP say about escalation and containment authority? That nudges the room back into action without giving them the answer.

#### 5.3 Late Session

When the ransom note inject arrives, the room shifts into executive mode. Legal joins. Comms gets pulled in. The team now has to think about business continuity, internal messaging, and whether the story should be treated as a confirmed compromise or a still-developing event.

ACME also includes one red herring inject: an unrelated phishing report. The team deprioritizes it correctly. That is a small win, but it matters because it shows they can separate signal from noise.

### Action: Use a Live-Run Checklist

Before the session:

- Test room links and audio.
- Confirm the white cell has the latest scenario notes.
- Ensure observers have the logging template.
- Confirm sponsor and pause authority.
- Make sure all artifacts are ready.

During the session:

- Deliver injects on schedule.
- Log responses and delays.
- Note assumptions explicitly.
- Watch for ownership gaps.
- Use gentle nudges rather than answers.

After the session:

- Capture hot-wash notes while memory is fresh.
- Collect observer logs.
- Identify high-value findings for the AAR.

***

## Part 6 — Facilitation Mastery

### Concept: Good Facilitation Is Controlled Restraint

Facilitation is the art of helping people think without taking over their thinking. The best facilitators are calm, consistent, and slightly boring in the best possible way. They do not chase excitement. They protect the learning.

The core techniques are simple:

- Hold the room.
- Ask fewer, better questions.
- Let silence reveal ownership gaps.
- Resist the urge to rescue too early.
- Keep the white cell aligned.

### Case Study Walkthrough: ACME’s Facilitation Choices

At ACME, the facilitator notices that the team repeatedly waits for one manager who is not in the room. Instead of answering for them, the facilitator asks who has delegated authority in the IRP. That forces the organization to confront whether its process actually works without that person present.

Later, when the room locks onto one alert and misses broader evidence, the facilitator introduces a contradictory clue. Not to trick the team, but to help them see the limits of their current mental model.

The result is that the team learns something subtle but important: the problem was not just technical detection. It was fragmented ownership and overconfidence in a single interpretation of events.

### Action: Write Your Facilitation Rules

Create a short `facilitation-notes.md` with rules like:

- Do not answer for the team unless the exercise would stall completely.
- Use the IRP as a reference point.
- Let silence run long enough to reveal uncertainty.
- Ask who owns the next action.
- Keep the exercise within scope.
- Record confusion as a finding, not a failure.

That document becomes part of your personal facilitator playbook.

***

## Part 7 — Case Study AAR: Turning Logs Into a Roadmap

### Concept: The AAR Is Where Learning Becomes Change

An after-action review should not be a recap. It should be a conversion process. You take raw observations, organize them into findings, classify them, assign owners, and set dates. Without that step, the exercise might feel productive but leave no lasting improvement.

A useful AAR separates findings into categories such as:

- Policy gap.
- Tooling gap.
- Execution gap.
- Communication gap.
- Governance gap.

That makes it easier to decide what changes are needed and who should own them.

### Case Study Walkthrough: ACME’s AAR

ACME’s incident logs contain messy but valuable observations:

- The team waited for approval that was never clearly delegated.
- The SOC did not know who should make the first containment decision.
- Backup confidence was assumed, not verified.
- Handoff between SOC and IR lost context.
- Legal joined late but effectively once invited.

During the AAR, these are rewritten as findings with structure:

- **Finding F-01**: Host isolation authority was not clearly delegated in the IRP.
- **Finding F-02**: Handoff context between SOC and IR was inconsistent.
- **Finding F-03**: Backup immutability verification was not part of the response runbook.

Then each finding gets:

- Category.
- Severity.
- Owner.
- Due date.
- Validation method.

That is what turns a tabletop into improvement work.

### Action: Turn Notes Into Findings

Use an AAR template with these fields:

- Observation.
- Finding.
- Category.
- Impact.
- Owner.
- Due date.
- Validation step.

Store the resulting roadmap in your vault and review it before the next exercise.

***

## Part 8 — Institutionalizing the Program

### Concept: Make TTX a Control, Not a Ceremony

The final goal is not a great single exercise. It is a sustainable program. A strong program repeats, measures, and improves. It becomes part of how the organization manages risk, not an occasional event that everyone forgets.

You want the exercise program to answer:

- Are we getting better?
- Are we repeating the same failures?
- Are we closing findings on time?
- Are our scenarios still relevant?

### Case Study Walkthrough: ACME’s Program View

After Red Horizon, ACME stops treating exercises as one-offs. They schedule regular discussion-based sessions, follow-up checks on critical findings, and periodic deeper tests once readiness improves. They also track whether earlier issues reappear. Repeat findings become one of their most important program health signals.

This is the shift from “we ran a tabletop” to “we run a tabletop program.”

### Action: Define Your Roadmap

Create a `05-Roadmap/program-plan.md` note that includes:

- Quarterly tabletop cadence.
- Semiannual deeper validation.
- Micro-exercises for specific findings.
- Annual maturity review.
- Metrics:
  - Time to first action.
  - Time to containment decision.
  - % findings closed by due date.
  - Repeat finding rate.

***

## Conclusion and Roadmap

This part turned the scenario into an executable exercise package. You now have a prep structure, inject logic, live-session discipline, facilitation boundaries, AAR conversion, and the start of a repeatable program model.

The next steps in the series are straightforward:

1. Build the prep folder.
2. Draft the MSEL.
3. Prepare safe artifacts.
4. Rehearse the white cell.
5. Run the live session.
6. Capture the AAR.
7. Convert findings into a roadmap.
