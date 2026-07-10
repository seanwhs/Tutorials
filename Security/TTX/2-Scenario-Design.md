## Part 2 — Threat Modeling & Scenario Design

### Concept: Build a Credible Story, Not a Movie Plot

A strong tabletop scenario is believable because it follows the way real attackers move through real environments, not because it is dramatic. The goal is to force useful decisions: what to confirm, who to call, what to contain, what to preserve, and what to delay. Your scenario should feel like an incident your organization could actually face next quarter, not something that only works in a cybersecurity conference slide deck.

For this series, the scenario design rule is simple:

> Start with a real threat pattern, then bend it to match your environment, business model, and weak points.

That means your scenario should be anchored in:

- A real adversary behavior pattern.
- A realistic initial access vector.
- A plausible path across identities, endpoints, networks, cloud, and backups.
- A business impact that leadership will care about.

If the scenario does not connect to real operations, it will produce generic answers and shallow lessons. If it is too narrow or too “perfect,” participants will solve it by guessing the story rather than reasoning from evidence.

### Case Study Walkthrough: Operation Red Horizon Takes Shape

ACME’s planning team starts with one question:

> “What kind of incident would be both plausible and painful for us?”

They do not begin with ransomware as a generic headline. They start with the sector pattern they keep seeing: vendors with remote access, exceptions around MFA, and trusted third-party connectivity into systems that touch manufacturing workflows. That immediately narrows the design space.

They then shape the exercise around a chain that feels familiar to defenders and attackers alike:

1. A vendor VPN account is compromised.
2. The attacker uses valid access to explore internal systems.
3. Privileged access boundaries are weaker than expected.
4. The attacker reaches systems that matter to operations.
5. Ransomware disrupts production, and backup confidence becomes a major question.
6. Leadership now has to decide what to shut down, what to isolate, and what to tell whom.

What makes ACME’s version effective is that every step maps to a real operational decision. The team is not just asking, “Did we detect ransomware?” They are asking:

- Who owns vendor access revocation?
- How quickly can we isolate an endpoint or segment?
- Can we trust the backup claims we make to leadership?
- What is the communication path to Legal, HR, Comms, and executives?
- Which systems are too critical to leave ambiguous during an incident?

That is the difference between a generic tabletop and a useful one: the scenario is built to reveal decision friction.

### Attack Chain Design

A practical scenario should be built as a chain of attacker objectives rather than a single event. For ACME, the chain includes identity abuse, discovery, lateral movement, credential exposure, and impact. The point is not to predict every attacker move with precision; the point is to create enough structure that injects feel connected rather than random.

A useful way to think about the chain is:

- **Initial access**: How did they get in?
- **Establishment**: How did they stay in?
- **Discovery**: What did they learn?
- **Expansion**: What else could they reach?
- **Impact**: What finally hurt the business?
- **Recovery pressure**: What made response harder?

For ACME, the attack chain is especially effective because it crosses several boundaries at once:

- Vendor trust boundary.
- Identity boundary.
- SOC detection boundary.
- IT operations boundary.
- Executive decision boundary.

That means the tabletop can test not only technical response, but also governance, escalation, and business continuity coordination.

### Scenario Quality Checks

Before locking a scenario, ask these questions:

- Is the initial compromise plausible for our environment?
- Would this attack path actually bypass some of our defenses?
- Does the scenario create ambiguity where real teams would have ambiguity?
- Will the business impact be meaningful enough to engage leadership?
- Can we run this safely at the chosen maturity level?

If the answer to any of those is “no,” refine the scenario until it becomes credible. If the answer to all of them is “yes,” you probably have a workable exercise.

### Action: Write the Scenario Like an Incident Brief

Create a scenario note in your vault, such as:

`01-Scenarios/scenario-ransomware-vendor-vpn.md`

Use a structure like this:

```markdown
# Scenario: Ransomware via Compromised Vendor VPN

## Summary
A strategic vendor account is suspected of being compromised, and attackers may be using the access path to move laterally into ACME’s internal environment. The incident escalates into ransomware impacting business-critical systems.

## Why This Scenario
- Vendor access is a known risk area.
- ACME has MFA exceptions for certain trusted vendors.
- The organization has not previously tested this scenario end-to-end.

## Business Impact
- Factory operations may be interrupted.
- Customer commitments may be delayed.
- Leadership may need to make containment decisions with incomplete information.

## Assumptions
- The initial alert originates from internal monitoring or a user report.
- The team has enough evidence to suspect compromise, but not enough to know the full blast radius.
- Some response actions will require cross-functional approval.

## Success Criteria
- The team identifies the incident as potentially high severity.
- Ownership is assigned clearly.
- Escalation and containment actions are initiated in time.
- Communications are controlled and documented.

## Key Tensions
- Speed vs confirmation.
- Containment vs business continuity.
- Trust in vendor statements vs internal evidence.
- Technical response vs executive communication.

## Candidate ATT&CK Themes
- Valid accounts.
- Internal discovery.
- Remote services abuse.
- Credential access.
- Data encryption for impact.
```

This note should be short enough to read, but structured enough to support future MSEL work.

### Excalidraw Guidance

Your attack-flow diagram should be simple and decision-oriented. Do not overcomplicate it with every possible branch. Instead, show the path from compromise to impact and mark the points where the organization can detect, decide, and intervene.

A good diagram usually includes:

- Vendor environment.
- VPN / remote access boundary.
- Identity systems.
- Internal network segments.
- Endpoint or server cluster.
- Backup / recovery systems.
- Business impact zone.

Add visual markers for:

- Detection points.
- Escalation points.
- Response actions.
- Uncertainty zones.

The diagram is not just decoration. It becomes a shared reference during prep, the live exercise, and the after-action review.

### Appendix Note

For this part of the series, your appendix material should begin to take shape as reusable reference assets:

- Scenario selection checklist.
- ATT&CK chain worksheet.
- Excalidraw attack-flow template.
- Scenario note template.
- Business impact mapping sheet.

These will become part of the appendices later in the series, but you can start drafting them now.

### Roadmap to Part 3

In Part 3, the scenario stops being a concept and becomes an executable exercise. We will turn the Red Horizon story into a prep package with injects, artifacts, rooms, and role assignments. That is where the exercise becomes real.

## Part 3 — Case Study Prep: Building Operation Red Horizon

### Concept Recap

Preparation is where a good idea becomes a controlled exercise. A scenario alone is not enough; you need a sequence of injects, a timing plan, a set of realistic artifacts, and a facilitator model that keeps the session moving. The prep phase is where you decide what the participants will see, what they will not see, and how the exercise will react when they ask the questions you did not predict.

### Case Study Walkthrough: ACME’s Prep Phase

ACME begins prep two weeks before the exercise. The senior IR lead acts as lead facilitator, while a small white cell handles scenario ground truth, timing, and artifact readiness. The team works backward from the desired exercise outcome: they want leadership, SOC, IT, Legal, and Comms to experience a realistic vendor-compromise-to-ransomware escalation without touching production.

They build a clean but realistic prep package:

- An Obsidian vault with scenario notes, RoE, and working templates.
- A draft MSEL with injects spaced to test prioritization.
- A set of artifacts that look operational but are safe to share.
- A Jitsi or BigBlueButton room structure that supports the main room and breakout rooms.
- An observer template for silent logging.
- A facilitator ground-truth sheet that answers likely questions consistently.

ACME also rehearses the dangerous part: ambiguity. They identify which facts the participants will likely misunderstand and decide in advance how much to reveal, when to reveal it, and when to let the silence work. That rehearsal matters because most tabletop failures are not caused by bad scenarios; they are caused by the facilitator improvising inconsistently.

### Prep Deliverables

ACME’s prep package includes:

- Exercise overview.
- RoE.
- Scenario note.
- Draft MSEL.
- Participant list.
- Observer instructions.
- Artifact pack.
- Comms plan.
- Ground-truth sheet.

The team also decides what is intentionally unknown. For example, they may know the vendor MFA exception exists, but they may not reveal that immediately. That “fault line” creates learning during the exercise instead of during a meeting.

### Action: Build the Prep Folder

Create a folder like:

`03-Prep/Operation-Red-Horizon/`

Inside it, store:

- `readme.md`
- `participants.md`
- `artifact-index.md`
- `msel-draft.md`
- `observer-notes-template.md`
- `white-cell-notes.md`

Use this as your working package for the live exercise.

## Part 4 — The Inject Engine & MSEL Architecture

### Concept

An inject is a controlled stimulus that forces the team to make a decision. The MSEL is the facilitator’s clock, script, and pacing tool all in one. Good injects are not random; they are sequenced to expose gaps in triage, ownership, escalation, and business coordination.

A strong MSEL has a few properties:

- Each inject has a purpose.
- Each inject maps to a decision point.
- Injects are timed to create pressure, but not confusion.
- Expected responses are written before the exercise begins.
- The facilitator can adapt without losing the structure.

### Case Study Walkthrough: ACME’s Inject Logic

ACME’s first inject is not the ransomware note. It is a suspicious signal that requires interpretation. That forces the team to decide whether the event is noise, a phishing issue, a vendor-access issue, or the start of something larger.

As the exercise progresses, the injects increase in urgency and cross-functional complexity. The team first receives a login anomaly, then a support call, then a network alert, then an internal escalation clue, and only later the impact signal. That ordering matters because it tests whether they can recognize a pattern before the situation becomes obvious.

The white cell watches for three things:

- Who notices first.
- Who claims ownership.
- Whether decisions are tied to evidence or assumptions.

The best injects create enough ambiguity to provoke discussion, but not so much that the exercise becomes a guessing game.

### Action: Build Your MSEL Structure

Your MSEL can live in Markdown like this:

```markdown
# MSEL — Operation Red Horizon

| Time | Inject | Channel | Expected Response | ATT&CK Theme | Actual / Variance |
|------|--------|---------|-------------------|--------------|-------------------|
| T+00:05 | Impossible travel login alert | Chat | SOC triages and escalates | Valid accounts | |
| T+00:15 | Help desk call from user about vendor request | Voice | Verify, log, and correlate | Initial access | |
| T+00:30 | Internal scan alert | Chat | Correlate with prior signals | Discovery | |
| T+01:05 | Ransom note | Email / chat | Activate incident response leadership | Impact | |
```

For every inject, define:

- What the participant sees.
- What you expect them to do.
- What common wrong turns you want to observe.
- What clue comes next if they stall.

That final point is critical. A facilitator should always know the next nudge.

## Part 5 — Case Study Execution: Running the Live Session

### Concept Recap

The live session is where facilitation discipline matters more than scenario creativity. Your job is not to perform outrage or hand out the answers. Your job is to maintain realism, protect the room, and collect evidence of how the organization behaves under pressure.

### Case Study Walkthrough: ACME Live

ACME runs the session with the lead facilitator, a scribe, observers, and a white cell. The exercise begins with a calm opening, a reminder of the RoE, and a clear description of how participants should communicate. Then the injects start.

At first, the team treats the event as a routine false positive. That is useful data. When the next inject arrives, some participants still anchor on the original alert and miss the broader pattern. That is also useful data. Later, once the ransomware signal arrives, the room shifts from analysis to action, and the real issue becomes authority: who can isolate, who can approve, and who must be informed.

The facilitator does not rescue the team too early. Silence is allowed to exist. Confusion is logged. Good questions are answered only at the level the role would reasonably know at that moment.

### Action: Prepare Your Live-Run Checklist

Before the exercise, confirm:

- Room links and backups.
- Audio/video testing.
- Observer templates ready.
- White cell ground-truth sheet ready.
- Participants know their roles.
- Stop/pause authority is visible.
- Escalation contacts are available.

During the run, use a short checklist for every inject:

- Delivered on time.
- Response observed.
- Decision recorded.
- Variance noted.
- Follow-up clue prepared if needed.

## Part 6 — Facilitation Mastery

### Concept

Good facilitation is quiet confidence. The facilitator keeps the exercise moving, keeps people in role, and keeps the learning useful without turning the session into a lecture. The key skills are pacing, restraint, and the ability to redirect without dominating.

### Case Study Walkthrough: ACME Facilitation

In ACME’s run, the facilitator notices a classic stall: the room wants approval from someone who is not present. Rather than answer for them, the facilitator asks what the IRP says and who has delegated authority. That single move turns an awkward pause into a learning moment.

The facilitator also watches for tunnel vision. When the team locks onto one alert and ignores broader evidence, a well-timed contradicting clue helps them widen the frame. The goal is not to trick them; the goal is to keep them honest.

### Action: Create Your Facilitation Rules

Write a short facilitation playbook with rules like:

- Do not answer for the team too early.
- Let silence run long enough to reveal ownership gaps.
- Use the IRP as a reference point, not as a crutch.
- Ask what evidence each decision is based on.
- Log uncertainty explicitly.

## Part 7 — Case Study AAR: Turning Logs Into a Roadmap

### Concept

The after-action review is where exercise data becomes organizational improvement. A good AAR turns messy observations into structured findings with owners, due dates, and priorities. If the exercise ends without this step, it becomes theater rather than control improvement.

### Case Study Walkthrough: ACME AAR

ACME’s observer notes are full of detail: hesitation, assumptions, confusion over isolation authority, uncertainty around vendor comms, and concern about backup integrity. In the AAR, these are translated into clean findings:

- A policy gap where isolation authority was unclear.
- An execution gap where the team waited for absent approval.
- A tooling gap where backup validation confidence was weak.

The team does not stop at “lesson learned.” Each finding gets an owner, a due date, and a follow-up action. That is what makes the exercise operationally useful.

### Action: Convert Notes Into Findings

Use an AAR structure like this:

- Observation.
- Finding.
- Category.
- Severity.
- Owner.
- Due date.
- Follow-up validation method.

## Part 8 — Institutionalizing the Program

### Concept

A tabletop program should behave like a control, not a one-time event. That means cadence, ownership, measurement, and iterative improvement. Once the first flagship exercise is complete, the work shifts from “running an event” to “running a program.”

### Case Study Walkthrough: ACME’s Program View

ACME uses the Red Horizon exercise as the first benchmark. Over time, they schedule quarterly discussion-based sessions, periodic more technical drills, and targeted micro-exercises to validate closure on key findings. They track repeat issues carefully because repeated findings are often more important than the original ones.

### Action: Define Your Program Cadence

Create a roadmap note that includes:

- Quarterly L1/L2 exercises.
- Semiannual deeper validation where appropriate.
- Post-AAR follow-up checks.
- Annual maturity review.
- Metrics such as time to first action and closure rate.

## Conclusion and Roadmap

This series is designed to move from **foundations** to **execution** to **institutional maturity**. Part 0 introduced the series and its structure, Part 1 established maturity and RoE, Part 2 built the scenario, and the later parts turn that scenario into a live exercise, an AAR, and a repeatable program.

The roadmap is simple:

1. Define the exercise program and its audience.
2. Choose the right maturity level.
3. Write a strong RoE.
4. Design a credible scenario.
5. Build a clean MSEL.
6. Run the exercise with discipline.
7. Convert observations into a roadmap.
8. Repeat until tabletop thinking becomes part of the organization’s operating rhythm.

## Appendix Framework

When the full series is complete, the appendices should include:

- **Appendix A — TTX Toolkit**
  - What each tool is for.
  - When to use it.
  - What not to use it for.
- **Appendix B — Templates**
  - RoE template.
  - Scenario template.
  - MSEL template.
  - Observer log template.
  - AAR template.
- **Appendix C — Facilitator Checklist**
  - T-2 weeks through T+2 weeks.
  - Pre-run, live-run, and follow-through tasks.
- **Appendix D — Sample Artifacts**
  - Example screenshots.
  - Sample inject text.
  - Example findings and roadmap entries.
- **Appendix E — Glossary**
  - TTX terms.
  - Facilitation terms.
  - IR and exercise-program terminology.
