# Part 1: The Threat Hunting Mindset & Hypothesis Generation — Expanded Edition

> **Blockquote — Why This Part Exists:** Every query, every rule, every tool in this entire series is worthless without a disciplined process guiding *what* you point them at. Part 1 is the operating system your brain runs before your fingers ever touch a keyboard. Skip this, and Parts 2–5 become a random walk through logs rather than a hunt.

---

## 1.1 From Alerting to Hunting: A Mental Model Shift

Imagine two security guards at a museum.

**Guard A** sits at a desk watching motion-sensor alarms. When a sensor trips, they respond. If no sensor trips, they assume all is well. This is **alerting** — reactive, and entirely dependent on someone else (a vendor, a rule author, a past version of yourself) having predicted the exact tripwire an intruder would hit.

**Guard B** walks the halls every night with a flashlight. They don't wait for an alarm — they look for a smudge on a display case, a misplaced ladder, a vent cover with fresh scratch marks, a window latch that's slightly ajar. They are actively searching for the *residue* of an intrusion that never tripped an alarm at all. This is **threat hunting**: a proactive, analyst-driven search for evidence of malicious activity that existing automated detections did not catch.

> **Blockquote — Core Principle:** Threat hunting exists because you must assume detection gaps exist. Every automated alert is a hypothesis someone already tested and encoded into a rule. A hunt is a *new* hypothesis, tested by a human, using raw telemetry the existing rules never looked at in that particular way.

### 1.1.1 Why Detection Gaps Are Inevitable, Not a Failure

It's worth internalizing *why* Guard A's alarms can never be complete, because this is the entire philosophical justification for hunting as a discipline:

1. **Rules are written for known behavior.** An alert can only fire on a pattern someone has already anticipated and coded. Novel or slightly-modified attacker behavior — a new persistence mechanism, a renamed process, a slightly different beacon interval — simply won't match any existing signature.
2. **Tuning creates blind spots on purpose.** Every SOC (Security Operations Center) that has ever existed has had to suppress noisy rules to stay usable. Every suppression is a deliberately created gap — a trade-off between "fewer false positives" and "slightly less visibility."
3. **Attackers study defenses.** Sophisticated adversaries actively test their tooling against common EDR/SIEM products before deploying it, specifically to avoid tripping alerts. Living-off-the-land techniques (using an OS's own legitimate tools, like `ssh` or `cron`, instead of malware) are popular precisely *because* they don't look abnormal to a rule that's watching for "known-bad" signatures.

This means a mature security program cannot be 100% alert-driven. It needs a human periodically asking, "If I were an attacker who *knew* about all our current alerts, how would I get past them?" — and then going and checking. That question, formalized, is a hunt.

### 1.1.2 Hunting vs. Alerting vs. Incident Response — Untangling the Terms

Beginners often conflate three related-but-distinct security activities. Let's separate them cleanly, because this series deliberately lives in exactly one of these three lanes:

| Activity | Trigger | Goal | Example |
|---|---|---|---|
| **Alerting (Detection)** | Automated — a rule matches | Notify a human that a *known* bad pattern occurred | "SIEM fires because a host connected to a known malicious IP." |
| **Threat Hunting** | Human-initiated — a hypothesis | Proactively find evidence of *unknown or unalerted* malicious activity | "I suspect SSH lateral movement is happening even though no alert fired — let me check Zeek logs manually." |
| **Incident Response (IR)** | An alert *or* a hunt has already confirmed something bad | Contain, eradicate, and recover from a *confirmed* incident | "We found lateral movement — now we isolate the host, rotate credentials, and rebuild." |

This series lives entirely in the middle column. We will occasionally reference what you'd *do* if a hunt confirms something bad (see the Hunt Template's "Response Actions" section from your existing template), but full incident response process is out of scope — our job is to find the smudge on the glass, not to run the whole museum's emergency protocol.

### 1.1.3 The Hunting Maturity Model

Not all organizations — or individual analysts — hunt the same way. It helps to know where you're starting and where this series is taking you:

| Maturity Level | Description | Where This Series Leaves You |
|---|---|---|
| **Level 0 — None** | Purely reactive; only responds to vendor/SIEM alerts | *(Starting point for most readers)* |
| **Level 1 — Ad Hoc** | Analysts occasionally poke around logs based on gut feeling, with no consistent process or documentation | *(Where most self-taught analysts get stuck)* |
| **Level 2 — Procedural** | Hunts follow a repeatable methodology (like our ABLE framework below) and are documented consistently | **✅ Part 1 gets you here** |
| **Level 3 — Data-Driven** | Hunts are informed by rich, purpose-built telemetry (auditd/osquery/Zeek) rather than whatever logs happen to exist | **✅ Part 2 gets you here** |
| **Level 4 — Automated Feedback Loop** | Every confirmed hunt finding is converted into a permanent detection (Sigma rule), so the organization's baseline automated coverage constantly improves | **✅ Part 5 gets you here** |

By the end of this series, you will have personally walked through every rung of this ladder — this is the actual, tangible outcome of following all six parts, not just an abstract maturity chart.

---

## 1.2 The Pyramid of Pain

Coined by security researcher David Bianco, the **Pyramid of Pain** ranks types of indicators by how much *discomfort* it causes an attacker when you detect and block them.

```
                /\
               /  \      TTPs (Tactics, Techniques, Procedures)
              /----\     <- Highest pain: forces attacker to retrain/rebuild
             / Tools \
            /----------\
           /  Network/  \
          /  Host Artif. \
         /------------------\
        /   Domain Names     \
       /------------------------\
      /      IP Addresses        \
     /------------------------------\
    /         Hash Values            \  <- Lowest pain: trivial to change
   /------------------------------------\
```

| Layer | Indicator Type | Attacker Pain If You Detect It | How Fast Attacker Can Change It |
|---|---|---|---|
| Bottom | **Hash Values** (MD5/SHA256 of a file) | Trivial — recompile and the hash changes instantly | Seconds |
| | **IP Addresses** | Easy — spin up a new VPS in minutes | Minutes |
| | **Domain Names** | Mildly annoying — needs a new domain registration | Hours |
| | **Network/Host Artifacts** (registry keys, user-agent strings, file paths, mutex names) | Annoying — must change tooling configuration | Days |
| | **Tools** | Painful — must find/build a new tool entirely | Weeks–Months |
| Top | **TTPs (Tactics, Techniques, Procedures)** | Maximum pain — forces the attacker to change their fundamental *methodology*, which took years of tradecraft to develop | Months–Years, if ever |

### 1.2.1 A Worked Illustration of the Pyramid in Practice

Let's make this concrete with a single, evolving scenario, so the abstract pyramid becomes tangible:

**Scenario:** An attacker uses a specific SSH lateral-movement toolkit against your environment.

1. **You block based on a file hash** of their custom SSH-key-harvesting script. *Attacker response:* changes one comment in the source code, recompiles. New hash. **Cost to attacker: seconds. Your defense is now worthless.**
2. **You block based on their C2 (Command and Control) server's IP address.** *Attacker response:* spins up a new VPS at a different cloud provider. **Cost to attacker: minutes.**
3. **You block based on their C2 domain name.** *Attacker response:* registers a new domain, possibly through a bulletproof registrar. **Cost to attacker: hours, maybe a small fee.**
4. **You detect the specific file paths or process names their tool always creates.** *Attacker response:* renames the binary, changes the drop path. **Cost to attacker: a day of retooling.**
5. **You detect and fingerprint the *tool itself* (e.g., a specific SSH library's behavioral signature, or a known open-source post-exploitation framework).** *Attacker response:* must abandon the tool entirely and find or build a replacement. **Cost to attacker: weeks.**
6. **You detect the *behavior*: "credentials obtained via phishing are being used to directly SSH between internal hosts, bypassing the bastion."** *Attacker response:* This is now nearly impossible to avoid without abandoning lateral movement via SSH altogether — because the *behavior itself*, not any specific artifact of it, is what's being watched. **Cost to attacker: fundamentally re-architecting their entire operational methodology.**

**Why this matters for hunting:** Hunting at the hash/IP level is what legacy antivirus signature-matching does — and adversaries route around it in seconds, which is precisely why that model is losing relevance. Effective threat hunting focuses on the **top of the pyramid**: behaviors and techniques an attacker cannot easily change, regardless of which specific tool, IP, or hash they happen to be using *this week*. Every hunt hypothesis we build in this series (and the Sigma rule in Part 5) deliberately targets levels 5 and 6 of this pyramid — never levels 1 or 2.

> **Blockquote — Conceptual Warning:** If you ever catch yourself writing a hunt hypothesis of the form "look for connections to IP X," stop — you've slid down to the bottom of the pyramid. Rewrite it as "look for the *behavior* that IP happened to exhibit" (e.g., beaconing at fixed intervals) so your hunt still has value after the attacker rotates infrastructure next week.

---

## 1.3 The MITRE ATT&CK Framework — A Working Introduction

**MITRE ATT&CK** (Adversarial Tactics, Techniques, and Common Knowledge) is a free, globally-accessible knowledge base of adversary behavior, maintained by the MITRE Corporation and built from thousands of real-world incident reports. Think of it as a **periodic table of attacker behavior** — every known technique has a name, a unique ID, and a defined position within the overall "attack lifecycle."

### 1.3.1 Tactics vs. Techniques vs. Sub-Techniques

ATT&CK is organized in a three-level hierarchy. Understanding this hierarchy precisely matters, because we'll use IDs from all three levels throughout this series:

| Level | Definition | Analogy | Example |
|---|---|---|---|
| **Tactic** | The adversary's **goal** — the *why* | The chapter title in a heist movie ("Getting Past Security," "Cracking the Vault") | `TA0008` — Lateral Movement |
| **Technique** | The general **method** used to achieve that goal — the *how*, at a moderate level of detail | The specific scene ("They used the guard's stolen keycard") | `T1021` — Remote Services |
| **Sub-Technique** | The **specific implementation** of that method | The exact tool used in the scene ("...specifically, a cloned RFID keycard, not a stolen physical one") | `T1021.004` — SSH |

Every technique and sub-technique page on the public ATT&CK website (attack.mitre.org) includes: a description, real-world examples of groups who've used it, and — critically for us — **suggested data sources for detecting it**. This last part is what makes ATT&CK directly actionable for a hunter, not just an academic reference.

### 1.3.2 Why ATT&CK IDs Matter More Than They Seem

A beginner might reasonably ask: "Why not just describe the behavior in plain English instead of memorizing codes like `T1021.004`?" Three concrete reasons:

1. **Unambiguous communication.** "Lateral movement" in plain English could mean fifteen different things to fifteen different analysts. `T1021.004` means exactly one thing, to everyone, everywhere, forever.
2. **Cross-tool interoperability.** Sigma rules (Part 5), threat intel reports, Velociraptor artifacts (Part 3), and MITRE's own ATT&CK Navigator tool all tag content with these same IDs — meaning a rule, a hunt, and a threat report can all be linked together programmatically.
3. **Coverage measurement.** Once you start tagging your hunts and detections with ATT&CK IDs (as our Hunt Template already does in Section 3), you can eventually build a heat map of your *entire* organization's detection coverage across the whole matrix — instantly showing leadership and auditors exactly where your blind spots are.

### 1.3.3 Our Running Example, Formally Placed in the Matrix

For this Part, and indeed for the rest of the series, we'll anchor everything to one tactic-technique pair:

- **Tactic:** Lateral Movement (`TA0008`) — the adversary is trying to move through your environment, hopping from system to system.
- **Technique:** Remote Services (`T1021`) — using legitimate remote access services (SSH, RDP, VNC, WinRM, etc.) to move between hosts, rather than exploiting a vulnerability.
- **Sub-Technique:** SSH (`T1021.004`) — specifically abusing the Secure Shell protocol, typically with stolen or reused credentials/keys.

> **Blockquote — Why We Chose This Example:** SSH-based lateral movement is nearly universal across Linux-heavy environments, requires no exotic malware (making it a textbook "living-off-the-land" technique — see §1.1.1), and sits near the *top* of the Pyramid of Pain because it's pure behavior abuse of a legitimate, essential protocol you can't simply "block." We deliberately chose it because it appears again in Part 4 (as real Zeek log analysis) and Part 5 (as a finished Sigma rule) — giving you one continuous thread demonstrating the entire hunt lifecycle from hypothesis to automated detection.

A full, general-purpose navigation guide to the entire ATT&CK matrix — including how to use the official ATT&CK Navigator tool, how techniques map to platforms, and how to prioritize which techniques to hunt first — is provided in **Appendix A**, so as not to derail this Part's momentum.

---

## 1.4 Methodology: Turning Threat Intelligence Into a Hypothesis

A **hunt hypothesis** is a specific, testable statement of the form:

> *"I believe [adversary/actor type] is using [technique] against [asset/log source], and I can find evidence of it by looking for [specific observable]."*

This is not a guess — it is engineered from **threat intelligence**: information about real adversary behavior, gathered from incident reports, honeypots, industry sharing groups (ISACs — Information Sharing and Analysis Centers), open-source reporting, or even your own organization's past incidents.

### 1.4.1 Where Does Threat Intelligence Actually Come From? (For Beginners)

If you've never consumed threat intelligence before, here are legitimate, free sources a beginner can start pulling hypothesis-worthy content from immediately:

| Source Type | Example | What You'd Extract From It |
|---|---|---|
| **Government advisories** | CISA (Cybersecurity and Infrastructure Security Agency) alerts, e.g., joint advisories on specific ransomware groups | Named techniques (often already ATT&CK-tagged) and specific behavioral indicators |
| **Vendor threat research blogs** | Public write-ups from security vendors (many publish detailed, free technical breakdowns even without a customer relationship) | Step-by-step attacker methodology narratives |
| **MITRE ATT&CK Groups pages** | attack.mitre.org's "Groups" section, documenting real named adversary groups and their historically observed techniques | A ready-made list of techniques a specific actor type favors |
| **Internal incident post-mortems** | Your own organization's past confirmed incidents | The most relevant intelligence you'll ever have — it already happened to *you* |
| **Honeypot/telemetry anomalies** | Something a colleague flagged as "weird" during routine monitoring | An informal but often highly valuable hypothesis seed |

### 1.4.2 The ABLE Framework — Structuring Raw Intelligence Into a Hypothesis

Raw threat intelligence is usually narrative prose — readable, but not directly actionable as a query target. We need a lightweight structuring method to convert prose into something queryable. This series uses the **ABLE framework**: **A**ctor, **B**ehavior, **L**ocation, **E**vidence.

**Worked Example — Building a Hypothesis from an Actor Profile**

Suppose a public threat intel report (e.g., a CISA advisory) states:

> *"The threat actor, after obtaining initial credentials via phishing, commonly pivots through the environment using stolen SSH keys, connecting directly from one compromised Linux host to another, bypassing the jump-box/bastion host architecture."*

Let's decompose this sentence, phrase by phrase, into the four ABLE components:

| ABLE Component | Guiding Question | Content Extracted From The Report |
|---|---|---|
| **A**ctor | *Who* is the presumed adversary? (Be generic if not formally attributed — most commodity intrusions are.) | Generic post-phishing intrusion actor — this behavior is commodity, not tied to one named group |
| **B**ehavior | *What* technique, precisely, with an ATT&CK ID? | Lateral movement via SSH (`T1021.004`) using valid, stolen credentials/keys — **not** an exploit of a vulnerability, which matters because it means signature-based detection is useless here |
| **L**ocation | *Where* (which log source) will evidence of this behavior actually appear? | SSH authentication logs (`/var/log/auth.log`), Zeek `ssh.log`, and Zeek `conn.log` for internal-to-internal traffic |
| **E**vidence | *What specific, observable data point* proves or disproves this? | SSH sessions between two *internal* hosts that do **not** traverse the designated bastion/jump-host IP, especially outside business hours or between hosts with no prior connection history |

This gives us our formal, testable hypothesis:

> **Hunt Hypothesis #2024-H01:** *"An adversary with valid stolen SSH credentials is moving laterally between internal Linux hosts, bypassing our bastion host. This will manifest as direct internal-to-internal SSH connections (destination port 22) in Zeek `conn.log` where the source IP is not our known bastion host IP (10.10.0.5), potentially correlated with a new/rare SSH client-server pairing never observed in the prior 30 days."*

### 1.4.3 What Makes This a *Good* Hypothesis — A Quality Checklist

Not every ABLE statement produces a usable hypothesis. Run every hypothesis you ever write through this checklist before spending time hunting on it:

- [ ] **Falsifiable** — Is there a concrete way this could turn out to be *wrong*? (Ours: yes — if no non-bastion internal SSH traffic exists, the hypothesis is refuted.)
- [ ] **Specific** — Does it name exact log fields/sources, not vague categories like "check the logs"? (Ours: names `conn.log`, `ssh.log`, `auth.log`, and even a specific bastion IP.)
- [ ] **Behavior-anchored, not IOC-anchored** — Does it sit near the top of the Pyramid of Pain (§1.2), targeting a TTP rather than a hash/IP? (Ours: yes — it targets the *pattern* of bypassing a bastion, not any specific attacker IP.)
- [ ] **Scoped to available telemetry** — Can you actually *get* the data named in "Location" with tools you have? (We confirm this is possible starting in Part 2.)
- [ ] **Time-bound** — Does it imply or state a reasonable time window to search, so the hunt doesn't become "search all data since the dawn of time"? (Ours: implies a rolling 30-day baseline comparison.)

> **Blockquote — Conceptual Warning:** A hypothesis that fails the "Falsifiable" check is not a hypothesis — it's a fishing expedition. "I believe something bad might be happening somewhere in our SSH traffic" cannot be proven wrong, and therefore can never be *concluded*. You will hunt forever and produce nothing documentable. Always force yourself to write the specific, falsifiable version, even if it takes several rewrites.

---

## 1.5 Hands-On: The Hypothesis Formulation Workflow

Here is the repeatable, six-step process you should follow for every hunt you ever conduct, for the rest of your career. We'll walk through each step using our running SSH example so it's not abstract.

### Step 1 — Ingest Intelligence
Read a threat report, honeypot finding, or even just an anomaly a colleague mentioned informally.

*Our example:* The CISA-style advisory quoted in §1.4.2.

### Step 2 — Map to ATT&CK
Identify the Tactic and Technique ID(s) involved, using attack.mitre.org's search function if you're unsure of the exact ID (Appendix A covers this navigation in depth).

*Our example:* `TA0008` (Lateral Movement) / `T1021.004` (SSH).

### Step 3 — Identify Required Telemetry
Ask: *"What log source would even contain evidence of this?"* This is the step most beginners skip, and it's the single most important one — a hypothesis you cannot actually test with available data is a dead end before you start.

*Our example:* Zeek `conn.log`, Zeek `ssh.log`, and host `auth.log`.

### Step 4 — Write the ABLE Statement
Actor, Behavior, Location, Evidence — as demonstrated in §1.4.2 — then compress it into the single-sentence hypothesis format.

### Step 5 — Define Success/Failure Conditions *Before* Hunting
Decide, in writing, in advance, what result would **confirm** vs. **refute** the hypothesis. This is a deliberate discipline against **confirmation bias** — the well-documented human tendency to interpret ambiguous evidence as supporting whatever you already suspected. If you decide *after* you've seen some data what counts as "suspicious," you will nearly always talk yourself into finding something, whether or not it's actually there.

*Our example, made explicit:*
- **Confirms:** ≥1 internal-to-internal SSH session (port 22) where source IP ≠ `10.10.0.5` (the bastion), AND that specific client→server host pairing has zero occurrences in the preceding 30 days of `conn.log`.
- **Refutes:** Zero such sessions found, OR all non-bastion internal SSH sessions correspond to documented/approved exceptions (e.g., a known admin's direct-access workflow, verified against a change ticket).
- **Inconclusive:** Zeek `conn.log` retention doesn't actually cover a full 30-day baseline window (a telemetry gap, not a hunt failure — this gets logged as a finding for Part 2-style engineering improvement, per the Hunt Template's Section 10).

### Step 6 — Execute and Document
Run your queries (Part 2 builds the telemetry pipeline; Part 4 runs this exact hunt against real Zeek logs), and record **everything** — including negative results.

> **Blockquote — Core Principle:** A hunt that finds nothing is not a failure; it is evidence that a specific attack path is currently not present in your environment, which is valuable, documentable, auditable information. Never let "we found nothing" become "so we didn't bother writing it up" — undocumented negative hunts get silently re-run by someone else next quarter, wasting everyone's time twice over.

### 1.5.1 A Common Beginner Failure Mode, and How to Avoid It

The most common mistake new hunters make is starting at **Step 6** — jumping straight into a tool and running broad, unfocused queries ("let me just look at all the SSH logs and see if anything looks weird") without ever completing Steps 1–5. This *feels* productive because you're staring at real data, but it almost always produces one of two bad outcomes:

1. **Analysis paralysis** — so much raw data with no specific question in mind that you close the terminal an hour later having "seen a lot of stuff" but concluded nothing.
2. **False-positive chasing** — without a pre-defined success/failure condition (Step 5), you'll eventually see *something* that looks slightly unusual (all real data has natural variance) and spend hours chasing it, only to realize it was a documented, benign administrative pattern.

The fix is mechanical, not clever: **always write out Steps 1–5 on paper (or directly into the Hunt Template below) before you type a single query.** This costs you five extra minutes and saves you hours.

---

## 1.6 Deliverable: The Hunt Investigation Template

Below is a complete, standalone Markdown template. Copy this into your hunt team's wiki or a plain `.md` file — every hunt you conduct for the rest of this series (and your career) should produce one of these documents.

#### File: `templates/hunt-investigation-template.md`

```markdown
# Hunt Investigation Report

## 1. Metadata
- **Hunt ID:** HUNT-YYYY-NNN
- **Analyst(s):**
- **Date Started:** YYYY-MM-DD
- **Date Concluded:** YYYY-MM-DD
- **Status:** [ Draft | In Progress | Concluded - Confirmed | Concluded - False Positive | Concluded - Inconclusive ]

## 2. Hypothesis (ABLE Format)
- **Actor:** (Who is the presumed adversary? Be generic if not attributed, e.g., "post-phish commodity actor")
- **Behavior:** (What technique — include MITRE ATT&CK ID, e.g., T1021.004)
- **Location:** (Which log source(s) will contain evidence?)
- **Evidence:** (What specific observable proves/disproves the hypothesis?)

> Full hypothesis statement:
> "I believe [Actor] is using [Behavior] against [Location], and I can find evidence of it by looking for [Evidence]."

## 3. MITRE ATT&CK Mapping
| Tactic ID | Tactic Name | Technique ID | Technique Name |
|---|---|---|---|
| | | | |

## 4. Required Telemetry & Data Sources
| Source | Tool/Log Path | Time Range Queried | Available? (Y/N) |
|---|---|---|---|
| | | | |

## 5. Success / Failure Criteria (defined BEFORE hunting)
- **Confirms hypothesis if:**
- **Refutes hypothesis if:**
- **Inconclusive if:**

## 6. Queries Executed
### Query 1
```
<paste exact query/command here>
```
**Purpose:**
**Result Summary:**

### Query 2
```
<paste exact query/command here>
```
**Purpose:**
**Result Summary:**

## 7. Findings
- **Summary of findings:**
- **Affected hosts/users/assets:**
- **Timeline of events (if applicable):**

| Timestamp (UTC) | Host | Event | Source |
|---|---|---|---|
| | | | |

## 8. Verdict
- [ ] True Positive — Malicious activity confirmed
- [ ] Benign True Positive — Activity confirmed but authorized/expected
- [ ] False Positive — No evidence found
- [ ] Inconclusive — Insufficient telemetry

## 9. Response Actions Taken
-

## 10. Detection Engineering Follow-Up
> If this hunt found something real, it should NEVER be a one-time manual query again.
- **Should this become a permanent Sigma rule?** [ Yes | No ]
- **If yes, link to Sigma rule PR/file:**
- **Gaps in telemetry identified (for Part 2-style engine improvements):**

## 11. Lessons Learned / Notes for Future Hunts
-
```

### 1.6.1 A Fully Completed Example — Sections 1–5 Filled In

To remove any ambiguity about how this template should actually be used, here is our running SSH example filled into Sections 1–5 (Sections 6–11 remain blank until we execute the hunt in Part 4, once real telemetry exists):

```markdown
# Hunt Investigation Report

## 1. Metadata
- **Hunt ID:** HUNT-2024-001
- **Analyst(s):** (your name here)
- **Date Started:** 2024-01-15
- **Date Concluded:** (pending — completed in Part 4)
- **Status:** Draft

## 2. Hypothesis (ABLE Format)
- **Actor:** Generic post-phishing intrusion actor (commodity behavior, not attributed to one named group)
- **Behavior:** Lateral movement via SSH using stolen/valid credentials (T1021.004)
- **Location:** Zeek conn.log, Zeek ssh.log, host /var/log/auth.log
- **Evidence:** Internal-to-internal SSH sessions (port 22) where source IP is not the known bastion (10.10.0.5), especially involving a client-server pairing never seen in the prior 30 days

> Full hypothesis statement:
> "I believe a post-phishing intrusion actor is using SSH-based lateral movement (T1021.004)
> against our internal Linux fleet, and I can find evidence of it by looking for direct
> internal-to-internal SSH connections in Zeek conn.log that bypass our bastion host
> (10.10.0.5), particularly new/rare host pairings never observed in the prior 30 days."

## 3. MITRE ATT&CK Mapping
| Tactic ID | Tactic Name       | Technique ID | Technique Name  |
|-----------|-------------------|--------------|------------------|
| TA0008    | Lateral Movement  | T1021.004    | Remote Services: SSH |

## 4. Required Telemetry & Data Sources
| Source              | Tool/Log Path                | Time Range Queried | Available? (Y/N) |
|---------------------|-------------------------------|---------------------|-------------------|
| Network connections  | Zeek /opt/zeek/logs/conn.log  | Trailing 30 days    | Pending Part 2 build |
| SSH protocol detail  | Zeek /opt/zeek/logs/ssh.log   | Trailing 30 days    | Pending Part 2 build |
| Host auth events     | /var/log/auth.log             | Trailing 30 days    | Pending Part 2 build |

## 5. Success / Failure Criteria (defined BEFORE hunting)
- **Confirms hypothesis if:** ≥1 internal-to-internal SSH session where source IP ≠ 10.10.0.5,
  AND that specific client→server pairing has zero occurrences in the preceding 30 days.
- **Refutes hypothesis if:** Zero such sessions exist, OR all non-bastion internal SSH sessions
  correspond to a documented/approved exception (verified against a change ticket).
- **Inconclusive if:** Zeek conn.log retention does not cover a full 30-day baseline window.
```

**Verification:** Save this file, then fill in Section 2 and 3 right now using our worked example if you haven't already. If you can complete Sections 1–4 without needing to stop and ask "wait, what log do I even check for this?" — your hypothesis is specific enough to proceed. If you get stuck on Section 4 ("Required Telemetry"), that is a direct signal your hypothesis is too vague and needs to go back to Step 3 of §1.5 before you write a single query. Keep this exact filled-in document open — we will complete Sections 6 through 11 together, with real data and real queries, in **Part 4**.

---

## 1.7 Chapter Summary — What You Now Have

Before moving to Part 2, confirm you're walking away from this Part with the following concrete assets and mental models:

- [ ] A clear distinction between **alerting**, **hunting**, and **incident response** (§1.1.2), and an understanding of *why* detection gaps are structurally inevitable (§1.1.1).
- [ ] The **Pyramid of Pain** as a lens for evaluating whether any hunt or detection is durable, or trivially bypassed (§1.2).
- [ ] Working fluency in ATT&CK's three-level hierarchy — **Tactic → Technique → Sub-Technique** — and our anchor example, `TA0008` / `T1021.004` (§1.3).
- [ ] The **ABLE framework** (Actor, Behavior, Location, Evidence) as a repeatable method for converting narrative threat intel into a structured, falsifiable hypothesis (§1.4).
- [ ] The full **six-step hypothesis formulation workflow**, and awareness of the "jumping to Step 6" failure mode to avoid (§1.5).
- [ ] A completed, saved copy of `templates/hunt-investigation-template.md`, with Sections 1–5 already filled in for **Hunt HUNT-2024-001** — our SSH lateral movement hypothesis, ready to be executed the moment real telemetry exists.

> **Blockquote — Bridge to Part 2:** Notice that Section 4 of our filled-in template currently says "Pending Part 2 build" for every single telemetry source. That is not an oversight — it's the entire point. We have a rigorous, falsifiable hypothesis and nothing yet to test it against. **Part 2 exists solely to fix that gap:** we will install and configure auditd, osquery, and Zeek so that the exact log sources named in Section 4 — `conn.log`, `ssh.log`, and `auth.log` — actually exist and are actively collecting data on your lab machine.

**Proceed to Part 2: The Open Source Data Engine (Osquery, Auditd, & Zeek).**
