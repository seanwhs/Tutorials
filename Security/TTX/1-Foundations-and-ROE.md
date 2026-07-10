## Part 1 — Foundations & Rules of Engagement

### 1. Concept: Why Maturity Level Comes First

A tabletop exercise (TTX) is a **facilitated, discussion-based simulation** of a hypothetical incident, built to test how your people, processes, and plans perform under stress. [wiz](https://www.wiz.io/academy/detection-and-response/tabletop-exercises)

For this series, think of a TTX as a **controlled experiment**:

> Hypothesis: “Our IRP and supporting processes handle scenario X reasonably well.”  
> Experiment: Run X as a narrative, with realistic artifacts, and see what breaks.

The **first design decision** is choosing your **maturity level**. That choice:

- Sets expectations for participants (“we will talk” vs “we will operate”).
- Constrains your injects (narrative-only vs tool-based).
- Drives logistics (rooms, artifacts, time).

#### 1.1 The Four Levels in Detail

We’ll keep your original four levels but add practical flavor for each.

| Level | Description | Typical Duration | Best For |
|-------|-------------|------------------|---------|
| L1 — Discussion-Based | Purely verbal “what would you do?” walkthroughs; facilitator presents scenario modules and questions; no artifacts, no logins.  [nvlpubs.nist](https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-84.pdf) | 2–3 hours | New IRPs, compliance-driven organizations, leadership alignment sessions |
| L2 — Facilitated Table Read | Players see real or sanitized artifacts (screenshots, emails, tickets) and talk through decisions; still no logins to real systems.  [nvlpubs.nist](https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-84.pdf) | 3–4 hours | Organizations with a documented IRP and some SOC maturity who want to expose “paper vs reality” gaps |
| L3 — Operations-Based | Players use tools in sandbox or tightly controlled environments (lab SIEM, test tenants, fake VPN); they execute playbooks live.  [nvlpubs.nist](https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-84.pdf) | 4–8 hours | Mature SOCs with reliable test environments and strong governance |
| L4 — Full-Scale | Live red team and real telemetry, potentially touching production or near-prod; may involve cross-org coordination and external parties.  [cisa](https://www.cisa.gov/sites/default/files/2023-02/ctep_fact_sheet_v._11_16_2021_final.pdf) | 1–3 days | Highest maturity organizations with robust exercise governance and prior L1–L3 learnings closed |

**Series principle:**  
> **Never run L3 or L4 until your L1/L2 findings are closed and owned.**

NIST and CISA guidance treat exercises as part of a program: you scale complexity as you learn, not as a one-off stunt. [cisa](https://www.cisa.gov/sites/default/files/2023-02/ctep_fact_sheet_v._11_16_2021_final.pdf)

#### 1.2 How to Gauge Your Current Maturity Honestly

You can quickly approximate your maturity with a few diagnostic questions:

1. **IRP Reality Check**
   - Is your incident response plan:
     - Known by name only?
     - Occasionally referenced in real incidents?
     - Regularly used and updated?

2. **Exercise History**
   - Have you ever run:
     - An ad-hoc “war room” with no structure (L0)?
     - A structured tabletop with documented outcomes (L1/L2)?
     - A tool-based simulation in lab/production (L3/L4)?

3. **Tooling & Sandbox**
   - Do you have:
     - A lab that mirrors production?
     - Synthetic or historical data for SIEM and EDR?
     - Clear rules for using tools in exercises?

4. **Organizational Risk Appetite**
   - How comfortable are executives with:
     - Simulated disruption?
     - People “failing” in front of peers?
     - Dedicating half a day or more to exercises?

Rough mapping:

- Low IRP usage + no prior exercises → Start at **L1**.
- IRP exists, sometimes used + no sandbox → Start at **L2**.
- IRP used often + lab environments + some TTX experience → Consider **L3**.
- Multiple exercises, strong governance, real red team history → Gradually move towards **L4**.

This matters because the rest of the series (scenario design, MSEL, facilitation) will assume a specific level.

***

### 2. Case Study Walkthrough: ACME Chooses L2 and Writes Its RoE

Now let’s see how ACME navigates this decision and how it leads directly into their **Rules of Engagement (RoE)**.

#### 2.1 ACME’s Maturity Snapshot

Recall ACME’s profile from Part 0:

- Hybrid infrastructure (on-prem factories + Azure/AWS workloads).
- Maturing SOC:
  - Tier 1–2 coverage, some MSSP involvement.
  - SIEM in place, but documentation of incidents is inconsistent.
- IRP:
  - Written with reference to NIST-style incident handling guidance. [youtube](https://www.youtube.com/watch?v=I_K8zGDCgt4)
  - Shared with managers but not deeply socialized with all operators.
- No prior **formal** tabletop program:
  - They’ve done “floor drills” and informal incident reviews.
  - Nothing with a structured MSEL and AAR.

ACME’s threat intel (internal + sector reports) shows:

- Multiple incidents in their sector involving **compromised vendor VPN accounts** leading to ransomware and OT impact. [cisa](https://www.cisa.gov/sites/default/files/2023-02/ctep_fact_sheet_v._11_16_2021_final.pdf)

The CISO convenes a small planning group:

- Senior IR Lead (future Lead Facilitator)
- SOC Manager
- Head of IT Operations
- Legal Counsel
- Comms/PR Lead

They walk through the diagnostic questions:

- IRP reality: “We use it lightly, mostly for major incidents.”
- Exercise history: “We’ve done ad-hoc drills but no properly logged tabletop.”
- Sandbox: “We have labs but they don’t resemble production well enough for realistic tool-based execution.”
- Risk appetite: “Execs are supportive, but we’re not ready to run full red-teamed chaos.”

Conclusion: **L2 — Facilitated Table Read** is the right starting point.

#### 2.2 ACME’s RoE: The Social Contract of Operation Red Horizon

The planning group drafts a **Rules of Engagement (RoE)** file in Obsidian:

`00-RoE/RoE-Operation-Red-Horizon.md`

Key elements they include (paraphrased from general exercise planning best practices): [cisa](https://www.cisa.gov/resources-tools/training/cisa-tabletop-exercise-package-documentation)

1. **Purpose and Objectives**

   - Purpose:
     - Validate ACME’s IRP against a vendor VPN ransomware scenario.
     - Identify gaps in roles, authorities, communication, and tooling.
   - Objectives (e.g.):
     - Assess how quickly the SOC recognizes and escalates a vendor-origin incident.
     - Validate decision-making around host isolation and vendor access revocation.
     - Practice internal and external communication flows (Legal, Comms).

2. **Scope & Boundaries**

   - In scope:
     - SOC Tier 1–2
     - IR leadership
     - Legal and Comms
     - Vendor VPN access, corporate AD, core business systems (conceptual, not live)
   - Out of scope:
     - Live changes to production
     - Real customer/regulator communication
     - HR actions or disciplinary measures

3. **No-Blame Clause**

   - Emphasize:
     - This is a learning exercise.
     - Findings apply to processes and systems, not individuals.
     - “Failure” is data, not a career risk.

   This mirrors common practice in TTX guidance: making psychological safety explicit encourages honest participation. [wiz](https://www.wiz.io/academy/detection-and-response/tabletop-exercises)

4. **STOP/PAUSE Authority**

   - Lead Facilitator and CISO can:
     - **Pause** the exercise: temporary halt to address confusion or risk.
     - **Stop** the exercise: end early if necessary (e.g., discovery of a real live incident).
   - Participants can request a pause through the Facilitator.

5. **Artifact Handling**

   - Only sanitized screenshots and log excerpts.
   - No real credentials, URLs, or sensitive internal details.
   - Participants do not log into production or lab systems.

6. **Communication & Tagging Rules**

   - All exercise-related comms:
     - Use dedicated channels, e.g. `#ttx-red-horizon` in Slack or a specific Matrix room.
     - Include `[TTX-EXERCISE]` in email subjects or calendar invites.
   - This prevents confusion between exercise traffic and real incidents.

7. **Roles and Responsibilities**

   - Lead Facilitator:
     - Drives the exercise, delivers injects, enforces RoE.
   - White Cell (small group with scenario ground truth):
     - Provides consistent answers to participant questions.
   - Observers/Evaluators:
     - Log actions, decisions, and notable moments.
   - Participants:
     - Play their real roles (SOC analyst, IR lead, Legal counsel, etc.).

CISA’s CTEP materials provide similar role-oriented structures (exercise planners, facilitators, evaluators, participants). [cisa](https://www.cisa.gov/resources-tools/training/cisa-tabletop-exercise-package-documentation)

The RoE gives everyone **shared language** before they ever see a ransom note or log screenshot.

***

### 3. Action: Assess Maturity, Draft Your RoE, Get Sign-Off

Now let’s turn this into concrete steps and files in your Obsidian vault.

#### 3.1 Step 1 — Assess Your Maturity (Short Workshop)

Schedule a **60–90 minute virtual workshop** with:

- IR or SOC lead
- IT operations leader
- At least one business representative (depending on scenario)
- Optional: Legal/Comms early, or later in the process

Agenda:

1. **Review IRP reality**
   - How often is the IRP referenced?
   - Which parts are routinely ignored or improvised?
2. **Review exercise history**
   - Have you done any prior tabletop or drills?
   - How were outcomes captured (if at all)?
3. **Discuss tooling and sandbox capabilities**
   - What lab/test environments exist?
   - How close are they to production?
4. **Discuss risk appetite**
   - Are leaders comfortable with simulated crises?
   - How much time can they realistically commit?

Deliverable: A one-paragraph maturity summary + chosen level (L1–L4).

Create a note:

`00-RoE/maturity-assessment.md`

Example structure:

```markdown
# Maturity Assessment – [Org Name]

## Summary
We currently use our IRP occasionally in major incidents and have not run formal tabletop exercises. Our lab environments are limited and do not closely mirror production. Executive stakeholders support exercises but prefer minimal operational risk.

## Chosen Maturity Level
maturity_level: L2 – Facilitated Table Read

## Rationale
- IRP exists but is not widely practiced.
- No realistic sandbox for tool-based operations.
- Desire to test vendor-origin scenarios with real artifacts but low operational impact.
```

#### 3.2 Step 2 — Draft Your RoE in Markdown

Create:

`00-RoE/RoE-[Scenario-Name].md` (e.g., `RoE-Operation-Red-Horizon.md`)

Suggested outline:

```markdown
# Rules of Engagement – [Scenario Name]

## 1. Metadata
exercise_name: [Scenario Name]
version: 1.0
owner: [IR Lead]
approved_by: [CISO or Sponsor]
maturity_level: L2 – Facilitated Table Read
date: [YYYY-MM-DD]

## 2. Purpose and Objectives
- Purpose: ...
- Objectives:
  - ...
  - ...

## 3. Scope and Boundaries
### In Scope
- ...
### Out of Scope
- ...

## 4. No-Blame Clause
- This exercise is for learning and improvement.
- Findings will focus on processes, tools, and governance—not individuals.

## 5. STOP/PAUSE Authority
- Lead Facilitator and [Sponsor] may pause or stop the exercise.
- Participants may request a pause via the Lead Facilitator.

## 6. Artifact Handling
- Only sanitized screenshots and synthetic logs will be used.
- No logins to production or lab systems will occur during the exercise.

## 7. Communication Rules
- All exercise communications use [channel names].
- Email subjects include [TTX-EXERCISE].
- Real incident channels are not used.

## 8. Roles and Responsibilities
- Lead Facilitator: ...
- White Cell: ...
- Observers/Evaluators: ...
- Participants: ...

## 9. Expectations
- Active participation.
- Respectful disagreement.
- Focus on learning, not performance scoring.
```

This mirrors the kind of structure you see in situation manuals and planner handbooks, but adapted for your Markdown-centric approach. [cisa](https://www.cisa.gov/sites/default/files/2023-02/ctep_fact_sheet_v._11_16_2021_final.pdf)

#### 3.3 Step 3 — Get Sponsor Sign-Off and Version-Control It

Finally:

1. Share the RoE with:
   - CISO / equivalent
   - Key stakeholders (IR, SOC, IT Ops, Legal/Comms)
2. Capture feedback:
   - Are any boundaries too strict or too loose?
   - Are objectives aligned with current risk priorities?
3. Once agreed:
   - Mark `approved_by` and `date`.
   - Optionally, store the vault in Git (private repo) to keep history.

After sign-off, **this exercise is real**—not hypothetical. Future parts assume this RoE exists and has authority behind it.

***

You now have:

- A chosen maturity level.
- A maturity assessment note.
- A drafted and (ideally) approved RoE for your flagship scenario.

This sets the stage for **Part 2 — Threat Modeling & Scenario Design**, where you’ll:

- Choose a concrete attack chain using MITRE ATT&CK (like ACME’s vendor VPN → ransomware progression). [attack.mitre](https://attack.mitre.org/techniques/enterprise/)
- Encode it in `01-Scenarios/scenario-[name].md`.
- Draw the attack flow in Excalidraw so participants can visualize the path from vendor account to impact.

**Question before we continue:**  
If you imagine using this series with your consulting clients, how would you adjust the RoE template to make it clearly “client-facing” while still keeping the technical depth you’d want in your own internal vault?
