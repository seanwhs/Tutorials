## Part 0 — Orientation: What This Series Is (and Isn’t)

### 0.1 Who This Is For

This series is written for:

- **CISOs, Deputy CISOs, and Senior IR Leads** who are responsible for:
  - Owning the incident response program (IRP)
  - Reporting risk posture to executives and the board
  - Turning vague “we should run a tabletop” requests into concrete, repeatable exercises
- **Blue Team / IR Managers** who:
  - Run day-to-day detection and response
  - Need a structured way to turn incidents and near-misses into better playbooks
  - Want to level up from ad-hoc drills to a program aligned with NIST/CISA guidance [nvlpubs.nist](https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-84.pdf)

You don’t need to be a professional exercise planner. You do need:

- A basic incident response plan (IRP), even if imperfect
- Enough political capital to gather people from SOC, IT, Legal, Comms, and Business
- Willingness to treat TTX as a **control** you can own, measure, and improve, not a one-off event

### 0.2 What You Will Build by the End

This is not just a “how to run a tabletop” article. It’s a **coaching program in Markdown**.

By the end of the series, you will have:

1. **An Obsidian-based TTX program vault** with:
   - Rules of Engagement (RoE) per scenario
   - Scenario library (including “Operation Red Horizon” or your equivalent)
   - MSELs (Master Scenario Events Lists) with injects mapped to MITRE ATT&CK [attack.mitre](https://attack.mitre.org/techniques/enterprise/)
   - Incident logs, AARs, and hardening roadmaps
2. **A repeatable facilitation pattern**, with:
   - Clear roles (Lead Facilitator, White Cell, Observers, Scribe)
   - A nudge style that references your IRP instead of “giving the answer”
   - A cadence and KPI set for your TTX program (mean time to first action, % findings closed, etc.)
3. **One fully executed flagship exercise**, including:
   - Prep, live conduct, hot-wash, and formal AAR
   - Turned into an improvement plan with owners and dates, consistent with how CISA’s CTEP packages recommend organizing findings and improvement actions. [cisa](https://www.cisa.gov/resources-tools/training/cisa-tabletop-exercise-package-documentation)

The series is **tool-friendly** but **tool-agnostic**:

- Diagrams: Excalidraw
- Knowledge base: Obsidian/Markdown
- Live session: Jitsi or BigBlueButton
- Chat/comms: Slack, Matrix/Element, or equivalent

All examples assume free/OSS-friendly stacks so you can reproduce them internally without license drama.

***

## 0.3 Why Tabletop Exercises Matter More Than Ever

Several authoritative guides (e.g., NIST SP 800-84 and CISA’s Tabletop Exercise Packages) emphasize that tabletop exercises are one of the most cost-effective ways to validate and improve incident response and contingency plans. [cisa](https://www.cisa.gov/sites/default/files/publications/CTEP%2520Fact%2520Sheet%2520FBO_01%252006%25202022%2520v3_508%2520PDF.pdf)

For modern hybrid enterprises like ACME:

- **Attack surface grows faster than headcount.**  
  - On-prem + cloud + vendors → more ways to lose control.
- **IRPs are often written for compliance, not reality.**  
  - They look fine in audits but fail in the first 15 minutes of a real incident.
- **Most incidents are won or lost on coordination, not tools.**  
  - Who speaks? Who decides? Who can isolate? Who calls Legal?

Tabletop exercises, when done right:

- Expose the **gap between documented process and lived behavior** (“what the PDF says” vs “what people actually do”). [tysonmartin](https://tysonmartin.com/feeds/blog/nist-incident-response-preparation-tabletop-exercises)
- Provide a **safe environment** to practice decisions, communication, and escalation. [nvlpubs.nist](https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-84.pdf)
- Generate **structured findings** that feed your IR roadmap and board reporting.

The series assumes you want to move from:

> “We ran a one-off tabletop because the auditor suggested it”  
> **to**  
> “We run a structured TTX program, and I can show its effect on our resilience.”

***

## 0.4 The ACME Case Study: Operation Red Horizon

To make every concept concrete, the series follows a fictional but realistic company: **ACME Enterprise**.

### 0.4.1 ACME’s Context

ACME is:

- A mid-sized manufacturer with:
  - Factory networks (OT + IT)
  - Corporate HQ network
  - Hybrid workloads in Azure and AWS
- With:
  - A maturing SOC (mix of in-house analysts and MSSP)
  - A written IRP aligned roughly to NIST SP 800-61 [youtube](https://www.youtube.com/watch?v=I_K8zGDCgt4)
  - Growing third-party risk (multiple strategic vendors with VPN access)

Their flagship scenario:

> **Operation Red Horizon** — Ransomware introduced via a **compromised vendor VPN account**, propagating into production systems and cloud workloads.

ACME’s pain points:

- Vendor access policies are fragmented across Procurement, IT, and Security.
- MFA policies exist but have exceptions for “trusted” vendors.
- Backup and recovery policies were tested for hardware failures, not for ransomware acting through trusted identities.

Throughout the series, you will see:

- How ACME chooses maturity level and writes its RoE
- How it designs the Red Horizon scenario using MITRE ATT&CK
- How it builds and runs the exercise
- How it turns the logs and AAR into a roadmap
- How it institutionalizes the program into quarterly cycles

You can either:

- Follow ACME’s path step by step.
- Substitute ACME with your own org and replace “Red Horizon” with your highest-risk scenario.

***

## 0.5 How to Use This Series (Structure & Workflow)

Each main part uses a **Concept → Case Study → Action** pattern:

1. **Concept** — Concise explanation of one building block:
   - Foundations & RoE
   - Scenario design with MITRE ATT&CK  
   - MSEL architecture  
   - Facilitation techniques  
   - AAR and roadmap
2. **Case Study Walkthrough (ACME)** — Narrative:
   - What ACME did, why, and what broke
   - How they used tools (Excalidraw, Obsidian, Jitsi) to make it concrete
3. **Action** — A small, implementable unit:
   - A Markdown file to create
   - A diagram to draw
   - A meeting to run
   - A template to adapt

**Recommended way to follow the series:**

1. Create an Obsidian vault (e.g., `TTX-Program`).
2. Mirror the folder structure:
   - `00-RoE/`
   - `01-Scenarios/`
   - `02-MSEL/`
   - `03-Execution-Logs/`
   - `04-AAR/`
   - `05-Roadmap/`
   - `99-Appendices/`
3. At the end of each part, **actually create the deliverable** in your vault.
4. Use the ACME examples as a reference, but write everything in your org’s language.

This approach matches how CISA’s CTEP documentation encourages organizations to leverage templates and situation manuals and then customize them to their own environment. [cisa](https://www.cisa.gov/resources-tools/training/cisa-tabletop-exercise-package-documentation)

***

## 0.6 Series Roadmap (Parts 0–8) + Appendices

### 0.6.1 Main Parts

1. **Part 0 — Orientation & Roadmap (you’re here)**  
   - Why TTX matters  
   - Who this series is for  
   - ACME overview & Red Horizon  
   - How to set up your vault and follow along

2. **Part 1 — Foundations & Rules of Engagement**  
   - Maturity levels (L1–L4) and why they come first  
   - ACME choosing L2 for Red Horizon  
   - Writing `RoE-Operation-Red-Horizon.md` with scope, no-blame, STOP/PAUSE, artifact handling, and tagging

3. **Part 2 — Threat Modeling & Scenario Design**  
   - Mapping a credible attack chain with MITRE ATT&CK (vendor VPN → ransomware → exfiltration) [attack.mitre](https://attack.mitre.org/techniques/enterprise/)
   - Capturing this in `scenario-ransomware-vendor-vpn.md`  
   - Drawing the attack flow in Excalidraw

4. **Part 3 — Case Study (Prep) — Building Operation Red Horizon**  
   - Turning the scenario into an executable MSEL  
   - Preparing artifacts and virtual rooms  
   - Training observers and rehearsing ground truth

5. **Part 4 — The Inject Engine & MSEL Architecture**  
   - Designing injects that force decisions  
   - Building a Markdown MSEL with planned time, content, expected response, ATT&CK mapping, and variance tracking  
   - Keeping “the Clock” on your second monitor

6. **Part 5 — Case Study (Execution) — Running the Live Session**  
   - Conducting the 3.5-hour exercise step-by-step  
   - Handling silence, confusion, and red herrings  
   - Capturing observer logs

7. **Part 6 — Facilitation Mastery**  
   - White Cell configuration  
   - The 2-minute stall rule and “silence is data”  
   - Countering tunnel vision with structured nudges

8. **Part 7 — Case Study (AAR) — Turning Logs into a Hardening Roadmap**  
   - Cleaning messy incident logs into structured findings  
   - Separating Policy, Tooling, and Execution gaps  
   - Writing an AAR with owners and dates, similar in spirit to AAR/Improvement Plan templates in common exercise guidance. [cisa](https://www.cisa.gov/sites/default/files/publications/CTEP%2520Fact%2520Sheet%2520FBO_01%252006%25202022%2520v3_508%2520PDF.pdf)

9. **Part 8 — Institutionalizing the Program**  
   - Designing quarterly/annual cadences  
   - Defining metrics and maturity indicators  
   - Scaling from one flagship scenario to a library of TTXs

### 0.6.2 Appendices

The appendices are designed as reusable, forkable assets:

- **Appendix A — TTX Toolkit Reference**
  - Short notes on:
    - NIST SP 800-84 (TT&E guide) [nvlpubs.nist](https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-84.pdf)
    - CISA CTEP documentation and common templates [cisa](https://www.cisa.gov/resources-tools/training/cisa-tabletop-exercise-package-documentation)
    - MITRE ATT&CK Navigator [attack.mitre](https://attack.mitre.org/techniques/enterprise/)
    - Excalidraw usage patterns for attack flows  
    - Obsidian folder and note conventions  
    - Jitsi/BigBlueButton configurations for exercises

- **Appendix B — Templates Library**
  - `RoE.md` skeleton  
  - `scenario-[name].md` frontmatter + sections  
  - `msel-[scenario].md` table structure  
  - `incident-log.md` structure for observers  
  - `aar-[scenario].md` outline

- **Appendix C — Facilitator’s Checklist**
  - Timeline from **T-2 weeks** to **T+2 weeks**, inspired by common exercise planner handbooks:
    - Planning, invitations, artifact prep, rehearsal, conduct, hot-wash, formal AAR, roadmap updates [flawarn.pwd.aa.ufl](https://flawarn.pwd.aa.ufl.edu/wp-content/uploads/sites/12/2022/01/January-2022-CTEP-Workshop-Slide-Deck.pdf)
  - Checkpoints for:
    - Sponsor alignment  
    - Participant briefings  
    - Tooling tests  
    - Follow-through on findings

All appendices are meant to live in `99-Appendices/` in your vault and be cloned per exercise.

***

## 0.7 Conclusion: How to Start, Today

By reading Part 0, you’ve:

- Clarified **who** this series is for and what it aims to build.
- Met **ACME Enterprise** and the **Operation Red Horizon** scenario.
- Seen the **big picture roadmap** across Parts 1–8 and the appendices.
- Understood that this is a **build-along program**: each part ends with a file or artifact you create.

**Concrete starting steps before Part 1:**

1. Create an Obsidian vault (e.g., `TTX-Program`).
2. Add the base folders:
   - `00-RoE/`
   - `01-Scenarios/`
   - `02-MSEL/`
   - `03-Execution-Logs/`
   - `04-AAR/`
   - `05-Roadmap/`
   - `99-Appendices/`
3. Decide:  
   - Will you follow ACME’s “Operation Red Horizon” directly?  
   - Or substitute it with your own flagship scenario (e.g., “Cloud account takeover,” “Business email compromise,” “OT malware in factory”)?

Once you’ve done that, you’re ready for **Part 1**, where you will:

- Pick your maturity level (L1–L4)
- Write your first RoE
- Get sponsor sign-off so this becomes a real, owned control in your environment rather than a theoretical exercise

**Question for you before we move on:**  
If you imagine your own consulting/TTX offering, what kind of flagship scenario (like ACME’s vendor VPN → ransomware story) would resonate most with the clients or orgs you work with?
