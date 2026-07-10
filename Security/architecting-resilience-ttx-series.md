# Architecting Resilience: Facilitating Professional Cybersecurity Tabletop Exercises (TTX)

**A CISO/Senior IR Lead Field Guide**
**Scenario Focus:** General Enterprise (on-prem + hybrid cloud)
**Tooling:** Excalidraw · Obsidian/Markdown · Jitsi/BigBlueButton (all free/OSS)

> A tabletop exercise is not a training video. It is a controlled experiment designed to find the delta between your documented Incident Response Plan (IRP) and what your people, tools, and processes will actually do at 2 a.m. under pressure. Every part of this series is built around exposing and closing that delta.

---

## Table of Contents

1. [Part 1 — The Anatomy of a TTX](#part-1)
2. [Part 2 — Scenario Design](#part-2)
3. [Part 3 — The Inject Architecture](#part-3)
4. [Part 4 — Facilitation Mastery](#part-4)
5. [Part 5 — Documentation & Evidence](#part-5)
6. [Part 6 — After-Action Review (AAR)](#part-6)
7. [Part 7 — Virtual Facilitation](#part-7)
8. [Part 8 — Iteration & Improvement](#part-8)
9. [Appendix A — The TTX Toolkit](#appendix-a)
10. [Appendix B — The Inject Matrix](#appendix-b)
11. [Appendix C — Facilitator's Checklist](#appendix-c)

---

<a name="part-1"></a>
## Part 1 — The Anatomy of a TTX

### 1.1 Why maturity level comes first

Every TTX design decision — inject volume, facilitator style, evidence capture — flows from one early decision: **how operational does this exercise need to be?**

| Level | Description | Player Interaction | Typical Duration | Best For |
|---|---|---|---|---|
| **L1 — Discussion-Based** | Verbal walkthrough of a scenario; no tools touched | "What would you do?" | 2–3 hrs | New IRP, executive orientation, annual compliance |
| **L2 — Facilitated Table Read** | Scenario + real artifacts (log excerpts, screenshots) shown, decisions still verbal | "Here's the alert — what's your call?" | 3–4 hrs | Mid-maturity teams, cross-functional onboarding |
| **L3 — Operations-Based (Functional)** | Players physically operate tools in a sandboxed/staging environment (SIEM queries, EDR isolation, IAM revocation) | "Go isolate the host. Show me the query." | 4–8 hrs, often multi-session | Mature SOC/IR teams validating muscle memory |
| **L4 — Full-Scale / Hybrid Red Team Integration** | Live adversary simulation feeding real telemetry into real tools, TTX facilitator manages narrative around it | Full operational tempo | 1–3 days | Highest-maturity orgs, regulatory/board-mandated validation |

**Architectural principle:** Do not attempt L3/L4 until an L1/L2 has been run and its AAR findings closed. Running an operations-based exercise against an IRP that hasn't survived a discussion-based pass wastes the organization's most expensive resource — subject-matter-expert time — exposing gaps you already could have found cheaply.

### 1.2 Defining the Rules of Engagement (RoE)

The RoE document is the contract that keeps a TTX safe, honest, and useful. It must be published to all participants **before** the exercise and referenced explicitly by the facilitator at kickoff. Minimum contents:

- **Scope boundary:** which systems, business units, and third parties are "in scenario" vs. explicitly out of bounds.
- **No-blame clause:** exercise outcomes are used to improve controls and playbooks, not for individual performance review. State this in writing; restate it verbally at kickoff.
- **STOP/PAUSE authority:** who can halt the exercise (facilitator only, or also the CISO/on-call lead) and under what real-world trigger (e.g., an actual incident occurs mid-exercise).
- **Artifact handling:** whether real production credentials, real customer data, or real ticket systems may be touched. Default answer for anything above L2: **no** — use a sandboxed/staging clone.
- **Communication guardrail:** an explicit rule that no message, email, or page sent as part of the exercise leaves the exercise channel (see Part 3, "Inject Channel Isolation") without a `[TTX-EXERCISE]` tag, to prevent a real page-out or customer notification being triggered by mistake.
- **Time-boxing:** hard start/stop times, and what happens if the exercise clock runs over (park remaining injects for the AAR discussion rather than rushing).

> **Deliverable:** An `RoE.md` file, version-controlled in your Obsidian vault, signed off (as a Git commit or explicit sign-off note) by the exercise sponsor before scheduling.

---

<a name="part-2"></a>
## Part 2 — Scenario Design

### 2.1 Building the threat model on MITRE ATT&CK

A credible scenario is not "a hacker gets in." It is a **chained sequence of ATT&CK techniques** that mirrors how your actual threat model (from threat intel, past incidents, or industry ISAC reporting) behaves. Anchor the scenario narrative to specific technique IDs so that:

- Injects can be mapped to a defensible technical event.
- The AAR can assess control coverage per technique (a natural bridge to a **Detection Coverage / ATT&CK Navigator heatmap**, which you can render in Excalidraw or export from the open-source ATT&CK Navigator tool).

**Example chain — "Ransomware via Compromised Vendor VPN"**

| Stage | ATT&CK Technique | ID | Narrative Beat |
|---|---|---|---|
| Initial Access | Valid Accounts (vendor VPN) | T1078 | Third-party support account reused with a leaked password |
| Discovery | Network Service Discovery | T1046 | Adversary scans internal subnets |
| Lateral Movement | Remote Services (RDP) | T1021.001 | Pivot to a jump host |
| Credential Access | OS Credential Dumping | T1003 | Domain admin hash captured |
| Privilege Escalation | Valid Accounts (Domain Admin) | T1078.002 | Full domain compromise |
| Impact | Data Encrypted for Impact | T1486 | Ransomware deployed to file shares |
| Exfiltration (double-extortion) | Exfiltration Over C2 Channel | T1041 | Data staged and exfiltrated pre-encryption |

### 2.2 Mapping to current infrastructure

For each stage above, the scenario designer must pre-answer: **"What does our actual architecture do here?"** This is where the TTX starts doing real architectural work rather than tabletop theater.

| Stage | Architectural Question to Pre-Validate | Control Owner |
|---|---|---|
| Valid Accounts (vendor) | Does our IAM enforce MFA + conditional access for all third-party accounts, no exceptions? | IAM/Identity team |
| Network Discovery | Would our NDR/IDS actually alert on internal east-west scanning, or only north-south? | Network Security |
| Lateral Movement (RDP) | Is RDP segmented/disabled by default per our Zero Trust network policy? | Network/Infra |
| Credential Dumping | Do we have LSASS protection (Credential Guard) and EDR alerting configured, or just logging? | Endpoint/EDR team |
| Domain Admin Compromise | Is there a break-glass procedure to force domain-wide credential rotation? Has it ever been tested? | IAM/AD team |
| Encryption/Impact | Do backups pass the 3-2-1 rule and are they *immutable* / offline from the domain? | Backup/BCDR team |
| Exfiltration | Does DLP/egress monitoring have visibility into the staging destination, or only known-bad IOCs? | SOC/DLP team |

**Scenario library starters (general enterprise):**
- Ransomware via third-party/vendor access compromise
- Business Email Compromise (BEC) → wire fraud
- Insider threat: privileged user data exfiltration before resignation
- Supply-chain compromise (malicious update from a trusted software vendor)
- Cloud IAM misconfiguration leading to public data exposure

> **Deliverable:** A `scenario-[name].md` file per scenario in your Obsidian vault with YAML frontmatter (`attack_techniques:`, `maturity_level:`, `business_units_in_scope:`) so scenarios are searchable and reusable across exercise cycles.

---

<a name="part-3"></a>
## Part 3 — The Inject Architecture

### 3.1 The "Clock" — designing the inject timeline

An **inject** is any piece of information deliberately introduced to advance the scenario and force a decision. The inject timeline ("the Clock") is the spine of the exercise. Design principles:

1. **Front-load ambiguity, not answers.** Early injects should look like normal noise (a single suspicious login alert) — realistic exercises rarely start with "you have been breached."
2. **Pace to force triage, not sequential processing.** Real incidents don't wait for teams to finish discussing inject #1 before #2 arrives. Stack 2–3 injects within a 10–15 minute window at least once per exercise to test prioritization under load.
3. **Every inject needs an "Expected Response" hypothesis** (see Appendix B) — this is what makes the AAR evidence-based rather than a vibe check. If the team's actual response diverges from the hypothesis, that divergence *is* your finding, not a failure.
4. **Alternate inject sources** to test the full communication graph: SIEM alert → SOC analyst → IR Lead → legal → comms → executive. A scenario that only ever delivers injects through one channel never tests the handoffs where real incidents actually break down.

### 3.2 Inject Channel Isolation

To satisfy the RoE communication guardrail from Part 1, run all injects through a clearly labeled **exercise channel**, separate from production channels:

- A dedicated Jitsi/BigBlueButton "war room" for verbal injects and role-play (e.g., a facilitator playing "external legal counsel" or "a journalist calling for comment").
- A dedicated chat channel (Matrix/Element is a good free/OSS option, or a clearly labeled channel in your existing chat tool) prefixed `[TTX-EXERCISE]` on every message.
- Simulated "log" and "alert" injects delivered as static Markdown/CSV files or screenshots, not by actually writing to production SIEM/ticketing — unless you are deliberately running an L3 exercise in a sandboxed clone.

### 3.3 Inject content types

| Type | Example | Tests |
|---|---|---|
| Technical artifact | SIEM alert screenshot, EDR detection, firewall log excerpt | Technical triage, correct tool usage, escalation threshold |
| Human/verbal | A "user" calls the help desk describing odd behavior | Front-line intake process, ticket creation, escalation SLA |
| External pressure | A journalist emails asking about "reports of a breach" | Comms/legal coordination, executive notification chain |
| Escalating stakes | "Ransom note" artifact appears | Executive decision-making, legal/law-enforcement engagement, backup restoration decision |
| Red herring | A second, unrelated low-severity alert | Tests whether the team fragments focus or correctly triages priority |
| Time-pressure injects | "The board wants an update in 15 minutes" | Communication cadence, drafting under pressure |

> **Deliverable:** A single `MSEL-[scenario].md` (Master Scenario Events List) file — see the full template in Appendix B — that is the facilitator's only script during execution.

---

<a name="part-4"></a>
## Part 4 — Facilitation Mastery

### 4.1 Managing the room

The facilitator's job is to hold the scenario's realism steady while keeping the room productive. Concrete techniques:

- **The "White Cell" role.** Designate one facilitator as the sole voice of "ground truth" (what's actually happening in the simulated environment) so players don't get inconsistent answers from multiple facilitators improvising differently.
- **Silence is data.** If a team goes quiet for 60+ seconds when an inject lands, that's often the actual finding (no one owns this decision in the real IRP) — note it in the observer log rather than immediately rescuing them with a hint.
- **The 2-minute rule for stalls.** If a team is stuck longer than ~2 minutes on *process* (not technical content — e.g., "who has authority to call this a P1?"), the facilitator injects a nudge ("Your IRP section 4.2 — who signs off on severity?") rather than letting the whole exercise stall. Log that a nudge was required; it's an AAR finding.

### 4.2 Countering tunnel vision

Tunnel vision (fixation on the first hypothesis, ignoring contradicting evidence) is one of the most valuable failure modes a TTX can surface, but only if the facilitator manages it deliberately rather than letting the exercise clock run out around it.

- **Plant a contradicting data point** as a scheduled inject (e.g., a technique earlier attributed to "insider" that gets a new external-IP data point) and watch whether the team updates its hypothesis.
- **Use a devil's-advocate observer** whose sole job is to ask, once per major decision, "What data would prove this hypothesis wrong?"
- **Time-box hypothesis lock-in.** If 20+ minutes pass without a team revisiting its initial theory despite new injects, that is flagged directly in the observer log as a candidate AAR finding, not silently corrected by the facilitator.

### 4.3 Facilitator vs. Observer roles

| Role | Responsibility | Should NOT |
|---|---|---|
| Lead Facilitator / White Cell | Delivers injects, maintains ground truth, enforces RoE and time-box | Answer "what should we do" — that's the players' job |
| Technical Facilitator (for L3/L4) | Operates the sandbox environment players interact with | Pre-solve the technical problem for them |
| Observer(s) | Silently logs decisions, timestamps, communication gaps on the Incident Log template (Part 5) | Speak during the exercise except for safety/RoE violations |
| Scribe | Captures verbatim key statements and decision points for the AAR | Interpret or editorialize in real time |

---

<a name="part-5"></a>
## Part 5 — Documentation & Evidence

### 5.1 Why Markdown + version control

Treating exercise materials as version-controlled Markdown (Obsidian vault backed by Git, or any Git repo) gives you:

- A diffable history of how scenarios evolve exercise-over-exercise.
- Cross-linking between the IRP, the scenario, the MSEL, and prior AARs using `[[wikilink]]` style references.
- Tagging (`#ttx/ransomware`, `#gap/iam`, `#status/open`) that turns your exercise history into a queryable knowledge base rather than a folder of disconnected Word docs.

### 5.2 Recommended vault structure

```
/TTX-Vault
  /00-RoE
    RoE-template.md
  /01-Scenarios
    scenario-ransomware-vendor-vpn.md
    scenario-bec-wire-fraud.md
  /02-MSEL
    MSEL-ransomware-2026-Q3.md
  /03-Execution-Logs
    incident-log-2026-Q3-exercise.md
    observer-notes-2026-Q3.md
  /04-AAR
    AAR-2026-Q3-ransomware.md
  /05-Roadmap
    roadmap-hardening-tasks.md
  /99-Diagrams
    comm-flow-ransomware.excalidraw
```

### 5.3 Incident Log template (used live by observers)

```markdown
# Incident Log — [Scenario Name] — [Date]

| Timestamp | Inject/Event | Team Action Taken | Decision Owner | Tool/Artifact Referenced | Assumption Made | Observer Note |
|---|---|---|---|---|---|---|
| T+00:05 | INJ-01 delivered | SOC analyst opened ticket | SOC L1 | SIEM console | Assumed alert was a false positive | 4 min to acknowledge — within SLA |
| T+00:12 | INJ-02 (escalation) | Escalated to IR Lead | SOC L1 → IR Lead | Slack #ir-oncall | — | Handoff had no context — IR Lead had to re-read alert |
| T+00:25 | Team requests EDR isolation | Waited for approval from manager not present | IR Lead | EDR console (verbal, not executed) | Assumed isolation needs manager sign-off | **Gap candidate: isolation authority undocumented** |
```

> Capture **assumptions made** explicitly — these are often the richest AAR material, because an assumption made under pressure that turns out to be wrong is a policy gap, not a people failure.

---

<a name="part-6"></a>
## Part 6 — After-Action Review (AAR)

### 6.1 From findings to a Roadmap of Improvements

The AAR's job is to convert raw observation data into a small number of **prioritized, owned, dated** hardening tasks. A good AAR explicitly separates three categories of finding:

1. **Policy gap** — the IRP didn't say what to do (e.g., no documented isolation authority).
2. **Tooling gap** — the IRP said what to do, but the tool couldn't do it (e.g., EDR isolation requires an integration that doesn't exist).
3. **Execution gap** — the policy and tooling were both fine, but the team didn't know/use them (training issue).

Each finding type routes to a different owner and remediation type — conflating them produces vague "improve communication" action items that never get closed.

### 6.2 AAR Report template

```markdown
# After-Action Review — [Scenario Name] — [Date]

## 1. Exercise Summary
- Maturity level: L2
- Duration: 3h 15m (planned 3h)
- Participants: SOC (3), IR Lead, IT Ops, Legal, Comms, 1 Executive observer
- Scenario: Ransomware via compromised vendor VPN (T1078 → T1486)

## 2. Objectives vs. Outcomes
| Objective | Met? | Evidence |
|---|---|---|
| Validate escalation SLA (SOC→IR Lead <15 min) | Partially | 12 min actual, but context was lost in handoff |
| Validate EDR host-isolation authority | **No** | No documented authority; team stalled 8 min |
| Validate legal/comms coordination on ransom note | Yes | Legal engaged within 5 min of inject |

## 3. Findings Register
| ID | Finding | Type (Policy/Tooling/Execution) | Evidence (Incident Log ref) | Severity | Owner | Target Date |
|---|---|---|---|---|---|---|
| F-01 | Host isolation authority undocumented in IRP §4 | Policy | T+00:25 | High | IR Lead | 2026-08-15 |
| F-02 | SOC→IR Lead handoff lacks a standard context template | Execution | T+00:12 | Medium | SOC Manager | 2026-08-01 |
| F-03 | Backup immutability not verifiable during exercise (no read-only proof step in runbook) | Tooling | Scenario design note | High | Backup/BCDR | 2026-09-01 |

## 4. Roadmap of Improvements (prioritized)
1. **[High] F-01** — Draft and ratify isolation-authority delegation in IRP §4; re-test in next L2 exercise.
2. **[High] F-03** — Add automated immutability-verification step to backup runbook; validate in next L3 exercise.
3. **[Medium] F-02** — Create a standard "handoff card" (Markdown template) SOC must fill before escalating.

## 5. Sign-off
- Exercise Sponsor: ______________
- IR Lead: ______________
- Date closed for tracking: ______________
```

### 6.3 Facilitating the debrief conversation

- Start with **what worked** — this isn't morale management, it's data; a control that worked under pressure is evidence for your next risk assessment.
- Ask **"What would you have needed to know/have to respond faster?"** rather than "What did you do wrong?" — this reliably surfaces policy/tooling gaps instead of defensive answers.
- Close every finding with a **named owner and date** before the room disperses. An AAR with unowned action items is a document that will not survive contact with next quarter's priorities.

---

<a name="part-7"></a>
## Part 7 — Virtual Facilitation

### 7.1 Scaling to distributed teams with OSS platforms

| Need | OSS Tool | Notes |
|---|---|---|
| Main war room / plenary | Jitsi Meet or BigBlueButton | Self-hostable, no account required for participants; BigBlueButton has native breakout rooms and a shared whiteboard |
| Breakout team rooms | Jitsi breakout rooms / BBB breakout rooms | Mirror your real incident bridge structure — one room per response team |
| Live scenario diagram / comm-flow map | Excalidraw (self-hosted or excalidraw.com) | Multiplayer canvas — facilitator can draw the live communication graph as it unfolds and share the link |
| Scenario docs / MSEL / injects | Obsidian vault, synced via Git or Obsidian Sync (or a self-hosted alternative) | Keep a "player-visible" folder separate from the facilitator's full MSEL to avoid spoiling future injects |
| Async inject delivery / chat-based injects | Element/Matrix (or your org's existing chat tool, isolated channel) | Use the `[TTX-EXERCISE]` tag discipline from Part 3 |

### 7.2 Virtual-specific facilitation adjustments

- **Recording ground rule:** decide upfront whether the session is recorded (useful for AAR evidence) and disclose it explicitly — treat this like any recorded meeting for consent purposes.
- **Silence reads differently on video.** In-person, a quiet team is visibly deliberating; on video, a muted team can look disengaged. Build in a lightweight "status check" inject (facilitator asks each breakout room for a 10-second verbal status) every 15–20 minutes rather than assuming silence = stall.
- **Screen-share discipline.** When a technical facilitator shares a sandbox environment, make sure only the intended players see it — accidentally screen-sharing the full MSEL (which reveals future injects) is the most common virtual-facilitation mistake. Keep the MSEL open only on the facilitator's private screen/second monitor, never shared.
- **Latency-aware pacing.** Add ~20% buffer to your inject timing versus an in-person exercise; distributed teams take longer to reach the same shared understanding over chat/video than around a table.

---

<a name="part-8"></a>
## Part 8 — Iteration & Improvement

### 8.1 Closing the loop back into the architecture

A TTX that doesn't change anything downstream was a training exercise, not an architectural validation. Concretely route each AAR finding type from Part 6 into a system of record:

| Finding Type | Feeds Into | Concrete Action |
|---|---|---|
| Policy gap | IRP document (version-controlled) | Redline the specific IRP section, get sign-off, publish new version, note the TTX finding ID in the changelog |
| Tooling gap | SIEM/EDR/IAM engineering backlog | File as an engineering ticket referencing the AAR finding ID; treat with the same priority discipline as a real incident postmortem action item |
| Execution gap | Training/runbook backlog | Update the specific runbook step; schedule a shorter, targeted "micro-TTX" (30–45 min, single-inject) to re-validate before the next full exercise cycle |

### 8.2 The exercise cadence

- **Quarterly:** L1/L2 discussion-based exercises rotating through your scenario library (Part 2) so every major ATT&CK chain gets revisited roughly annually.
- **Semi-annually or annually:** one L3 operations-based exercise on your highest-risk scenario, gated on prior AAR findings being closed.
- **Ad hoc micro-TTX:** 30-minute single-inject re-tests targeted directly at a specific closed finding, to verify the fix actually works rather than just trusting the ticket status.

### 8.3 Measuring program maturity over time

Track, per exercise cycle, in your Obsidian vault (a simple dataview-style table or CSV):

- Mean time-to-first-action per inject type (trending down = good)
- % of findings closed before the next exercise (your real "debt paydown rate")
- Recurrence of the same finding across cycles (a repeat finding is a strong signal of an unaddressed root cause, not a facilitation failure)

> **Architectural bottom line:** the TTX program itself should be treated like any other control — it has an owner, a cadence, a maturity model, and it should show measurable improvement in your organization's actual incident response capability, not just a stack of completed slide decks.

---

<a name="appendix-a"></a>
## Appendix A — The TTX Toolkit (Open-Source & Public-Domain Frameworks)

| Framework/Resource | Publisher | Use |
|---|---|---|
| **NIST SP 800-84** — Guide to Test, Training, and Exercise Programs for IT Plans and Capabilities | NIST | Foundational federal guidance on TTX design, from discussion-based through full-scale |
| **NIST SP 800-61 Rev. 2** — Computer Security Incident Handling Guide | NIST | The IR lifecycle your scenario should map back to |
| **MITRE ATT&CK Framework & Navigator** | MITRE | Technique library and heatmap tool for scenario design and post-exercise coverage mapping |
| **CISA Tabletop Exercise Packages (CTEP)** | CISA | Free, sector-specific pre-built scenario packages (ransomware, insider threat, cloud, industrial control systems) |
| **ENISA Good Practice Guide on Exercise Scenarios** | ENISA | EU-oriented scenario design guidance, useful for cross-border/GDPR-relevant scenarios |
| **SANS Incident Handler's Handbook** | SANS | Reference for the phases (Prep, ID, Containment, Eradication, Recovery, Lessons Learned) your MSEL/AAR should mirror |
| **Excalidraw** | OSS (excalidraw.com / self-hostable) | Communication-flow diagrams, architecture-under-attack diagrams |
| **Obsidian** | Freeware, Markdown-based | Vault for scenarios, MSEL, AAR, versioned via Git |
| **Jitsi Meet** | OSS, self-hostable | Virtual facilitation, war room |
| **BigBlueButton** | OSS, self-hostable | Virtual facilitation with native breakout rooms and whiteboard, well suited to education-style facilitation |
| **Element / Matrix** | OSS | Isolated exercise chat channel for inject delivery |

---

<a name="appendix-b"></a>
## Appendix B — The Inject Matrix Template

Use one row per inject. This is the facilitator's operational script — keep it private from players and share only the "player-visible" artifact referenced in each row.

```markdown
# MSEL — [Scenario Name] — [Date]

| # | Planned Time (T+) | Inject Content | Delivery Channel | Source (in-narrative) | Expected Team Response | ATT&CK Technique | Actual Response (filled live) | Variance/Notes |
|---|---|---|---|---|---|---|---|---|
| INJ-01 | 00:05 | SIEM alert: impossible-travel login on vendor VPN account | Screenshot in exercise chat | "SIEM" | SOC opens ticket, checks account owner, escalates if unconfirmed | T1078 | | |
| INJ-02 | 00:15 | Help-desk call: user reports "IT" asked them to install remote-access software | Verbal (facilitator role-plays caller) | "Employee" | Help desk flags as suspicious, routes to security, does NOT approve install | T1566/T1204 | | |
| INJ-03 | 00:30 | Internal network scan alert on subnet adjacent to finance | Log excerpt (Markdown table) | "IDS/NDR" | Team correlates with INJ-01, considers lateral movement hypothesis | T1046 | | |
| INJ-04 | 00:45 | Domain controller shows new privileged account created after hours | Screenshot | "SIEM/AD logs" | Team escalates to IR Lead, considers privilege escalation, begins containment discussion | T1136/T1078.002 | | |
| INJ-05 | 01:00 | Ransom note artifact found on a file share | Simulated document (Markdown) | "IT Ops" | Executive notification triggered, legal engaged, backup restoration path discussed | T1486 | | |
| INJ-06 | 01:10 | Journalist email: "We understand you've had a data breach — comment?" | Simulated email (delivered in chat) | "External press" | Comms/Legal coordinate a holding statement; no unapproved response sent | — (comms test) | | |
| INJ-07 | 01:25 | (Red herring) Unrelated low-severity phishing report from a different department | Ticket excerpt | "Help desk" | Team correctly deprioritizes without abandoning main incident | — | | |

**Column notes:**
- *Expected Team Response* must be written **before** the exercise — this is your hypothesis, and any deviation is AAR evidence, not a scoring failure.
- *Actual Response* and *Variance/Notes* are filled live by the observer/scribe (see Part 5 Incident Log) and cross-referenced into the AAR Findings Register.
```

---

<a name="appendix-c"></a>
## Appendix C — Facilitator's Checklist

### C.1 — T-minus 2 weeks (Preparation)
- [ ] Scenario selected and mapped to ATT&CK chain (Part 2)
- [ ] Maturity level (L1–L4) confirmed with sponsor
- [ ] RoE drafted and signed off (Part 1)
- [ ] MSEL drafted with Expected Team Response hypotheses for every inject (Appendix B)
- [ ] Participant list finalized: players, observers, scribe, White Cell facilitator identified
- [ ] Virtual platform provisioned (Jitsi/BBB rooms created, Excalidraw board pre-seeded with the org chart / network diagram skeleton)
- [ ] Obsidian vault folder created for this exercise cycle (Part 5 structure)

### C.2 — T-minus 3 days
- [ ] RoE circulated to all participants
- [ ] Calendar holds confirmed; breakout room assignments communicated
- [ ] Observers briefed on the Incident Log template and told explicitly: **log, don't speak**
- [ ] Technical facilitator (if L3) confirms sandbox environment is live and isolated from production
- [ ] Recording/consent decision made and communicated (Part 7.2)

### C.3 — Day of, before start
- [ ] Confirm no live production incident is in progress that would conflict with running a simulated one
- [ ] Re-state the RoE verbally, including STOP/PAUSE authority and no-blame clause
- [ ] Confirm exercise-channel tagging discipline (`[TTX-EXERCISE]`) with all participants
- [ ] Start the Incident Log with T+00:00 timestamp

### C.4 — During execution
- [ ] Facilitator delivers injects per the MSEL clock, adjusting pace live if a team is significantly ahead/behind
- [ ] Observers log every decision, timestamp, and stated assumption
- [ ] White Cell maintains a single consistent "ground truth" for any player question not covered by a scripted inject
- [ ] Facilitator applies the 2-minute stall rule and tunnel-vision countermeasures (Part 4) as needed, logging every nudge given

### C.5 — Immediately after (same day)
- [ ] Hot-wash: 10–15 minute immediate verbal debrief capturing top-of-mind reactions before memory fades
- [ ] Incident Log and observer notes committed to the Obsidian vault
- [ ] Facilitator schedules the formal AAR session within 5 business days

### C.6 — AAR session (within 1 week)
- [ ] Findings Register drafted from Incident Log evidence, categorized Policy/Tooling/Execution (Part 6)
- [ ] Each finding assigned a named owner and target date
- [ ] AAR report committed to the vault, linked from the scenario file
- [ ] Roadmap of Improvements shared with exercise sponsor and relevant control owners

### C.7 — Follow-through (ongoing)
- [ ] Findings tracked to closure in the appropriate system (IRP redline, engineering backlog, or training backlog — Part 8.1)
- [ ] Micro-TTX scheduled for any High-severity finding to validate the fix
- [ ] Exercise cadence log updated with this cycle's metrics (Part 8.3)

---

*End of series. This document is designed to live as a version-controlled Markdown file in your own Obsidian vault — fork it, adapt the scenario library to your actual threat model, and treat the templates in Appendices B and C as living documents that improve with every exercise cycle.*
