# Appendix A: The MITRE ATT&CK Framework — An Operator's Guide (Expanded Edition)

> **Blockquote — Purpose of This Appendix:** Part 1 introduced ATT&CK's three-level hierarchy (Tactic → Technique → Sub-Technique) just enough to support our running SSH example. This appendix is the deeper, standalone reference you'll return to for *every future hunt* you ever conduct — covering how to navigate the full matrix, prioritize where to focus, avoid the common traps that make ATT&CK feel overwhelming, and use it as a living operational tool rather than a poster on a wall.

---

## A.1 Why ATT&CK Exists — The Problem It Was Built to Solve

Before ATT&CK existed (MITRE released it publicly in 2015), the security industry had a language problem. One vendor's report might describe an attacker's behavior as "living-off-the-land technique," another might call the same thing "fileless lateral movement," a third might just call it "suspicious PowerShell activity." These all could describe the *exact same underlying adversary action*, but no two organizations could easily confirm they were talking about the same thing, compare notes, or measure their defenses against it consistently.

**Analogy:** Imagine if every hospital in the world used a different name for the same disease. Doctors couldn't compare treatment outcomes, researchers couldn't pool data, and a patient transferring hospitals might get a completely different diagnosis label for the identical condition. Medicine solved this with standardized taxonomies (ICD codes, for instance) — a shared vocabulary that lets completely unrelated institutions describe the same phenomenon identically. **ATT&CK is that standardized taxonomy for adversary behavior.**

MITRE ATT&CK (Adversarial Tactics, Techniques, and Common Knowledge) is a free, globally-accessible knowledge base of adversary behavior, built and maintained from thousands of real-world incident reports, red team engagements, and open-source intelligence. It functions as a **periodic table of attacker behavior** — every known technique has a name, a unique ID, and a defined position within the overall "attack lifecycle."

### A.1.1 Who Maintains It, and Why You Can Trust It

ATT&CK is maintained by the **MITRE Corporation**, a U.S. non-profit that operates federally funded research centers. Critically for our FOSS philosophy (Part 0), ATT&CK itself is:

- **Free to access, in full**, with no login, paywall, or licensing agreement required (attack.mitre.org).
- **Openly contributed to** — security researchers, vendors, and practitioners worldwide submit new techniques, procedure examples, and detection guidance via a public GitHub-adjacent contribution process.
- **Versioned and changelogged** — MITRE publishes structured release notes for every update, so you can track exactly what changed between matrix versions, critical for auditability if you're tracking coverage over time.
- **Vendor-neutral by design** — no single company controls its content or can bias it toward their own product's strengths.

This is precisely the same trust model this entire series has applied to every tool we've used — open, documented, and free of any single vendor's commercial incentives.

---

## A.2 Tactics vs. Techniques vs. Sub-Techniques — The Hierarchy, In Depth

### A.2.1 The Three-Level Structure, Revisited

| Level | Definition | Analogy | Example |
|---|---|---|---|
| **Tactic** | The adversary's **goal** — the *why* | The chapter title in a heist movie ("Getting Past Security," "Cracking the Vault") | `TA0008` — Lateral Movement |
| **Technique** | The general **method** used to achieve that goal — the *how*, at a moderate level of detail | The specific scene ("They used the guard's stolen keycard") | `T1021` — Remote Services |
| **Sub-Technique** | The **specific implementation** of that method | The exact tool used in the scene ("...specifically, a cloned RFID keycard, not a stolen physical one") | `T1021.004` — SSH |

### A.2.2 Why a Technique Can Belong to Multiple Tactics

A subtlety that confuses many beginners: **the same Technique ID can appear under more than one Tactic**, because a single method can serve multiple adversary goals depending on context. For example, `T1053` (Scheduled Task/Job) appears under **both** `TA0002` (Execution — "I need to run code right now") **and** `TA0003` (Persistence — "I need this code to keep running after reboot"). The technique — creating a scheduled task — is mechanically identical either way; what differs is the adversary's *intent* at that moment, which is exactly what the Tactic layer is meant to capture.

> **Blockquote — Conceptual Warning:** Never assume a Technique ID uniquely identifies a Tactic. When citing a technique in a hunt hypothesis or Sigma rule tag, always specify *both* the Tactic and Technique ID together (e.g., "`TA0003`/`T1053.003`" rather than just "`T1053.003`") if the distinction matters for your documentation — this avoids ambiguity for anyone reading your hunt report later.

### A.2.3 Sub-Techniques — Why the ".004" Matters

Many Techniques have no sub-techniques at all; others have a dozen or more. `T1021` (Remote Services) has at least six documented sub-techniques as of this writing:

| Sub-Technique ID | Name | Relevance |
|---|---|---|
| `T1021.001` | Remote Desktop Protocol (RDP) | Primarily Windows-focused — out of scope for this Linux-centric series |
| `T1021.002` | SMB/Windows Admin Shares | Primarily Windows-focused |
| `T1021.003` | Distributed Component Object Model | Windows-specific |
| `T1021.004` | **SSH** | **Our series' running example throughout Parts 1–5** |
| `T1021.005` | VNC | Cross-platform, relevant if VNC is deployed in your environment |
| `T1021.006` | Windows Remote Management | Windows-specific |

Notice how, without sub-techniques, "T1021 — Remote Services" would force you to write detection logic broad enough to cover RDP, SMB, DCOM, SSH, VNC, and WinRM all at once — an impossible, incoherent single rule. The sub-technique layer is what makes ATT&CK **actionable at the level of granularity a real Sigma rule or hunt hypothesis actually needs** (recall our own rule in Part 5 was tagged precisely `attack.t1021.004`, never the bare parent).

---

## A.3 The Full Tactic List (Enterprise Matrix)

ATT&CK's Enterprise matrix (the one relevant to this series' Linux/network focus — MITRE also maintains separate Mobile and ICS/OT matrices, out of scope here) organizes all techniques under 14 tactics. Although MITRE's own website lists them alphabetically by ID for reference, they map roughly to the typical *progression* of an intrusion, which is the more useful way to internalize them as a hunter:

| Order | Tactic ID | Tactic Name | Plain-English Meaning | Example Technique |
|---|---|---|---|---|
| 1 | TA0043 | Reconnaissance | Attacker is gathering information before the intrusion | `T1595` — Active Scanning |
| 2 | TA0042 | Resource Development | Attacker is building infrastructure (C2 servers, malware, domains) | `T1583` — Acquire Infrastructure |
| 3 | TA0001 | Initial Access | Attacker gets their first foothold | `T1566` — Phishing |
| 4 | TA0002 | Execution | Attacker runs malicious code | `T1059` — Command and Scripting Interpreter |
| 5 | TA0003 | Persistence | Attacker ensures they survive reboots/patches | `T1053.003` — Cron |
| 6 | TA0004 | Privilege Escalation | Attacker gains higher-level permissions | `T1548` — Abuse Elevation Control Mechanism |
| 7 | TA0005 | Defense Evasion | Attacker avoids detection | `T1036` — Masquerading |
| 8 | TA0006 | Credential Access | Attacker steals account credentials | `T1552` — Unsecured Credentials |
| 9 | TA0007 | Discovery | Attacker maps out the environment | `T1046` — Network Service Discovery |
| 10 | TA0008 | Lateral Movement | Attacker moves between systems | `T1021.004` — SSH |
| 11 | TA0009 | Collection | Attacker gathers data of interest | `T1005` — Data from Local System |
| 12 | TA0011 | Command and Control | Attacker communicates with compromised systems | `T1071.004` — DNS |
| 13 | TA0010 | Exfiltration | Attacker steals data out of the environment | `T1041` — Exfiltration Over C2 Channel |
| 14 | TA0040 | Impact | Attacker disrupts, destroys, or manipulates systems/data | `T1486` — Data Encrypted for Impact (ransomware) |

> **Blockquote — Conceptual Warning:** This ordering is a *common* narrative flow, not a mandatory sequence. Real intrusions loop back and forth constantly — an attacker might perform Discovery, then Lateral Movement, then more Discovery on the new host, then Privilege Escalation, then Persistence. Never assume an intrusion investigation is "over" just because you've found evidence of a later-stage tactic; always check for earlier and later stages too. A single confirmed cron persistence entry (Part 3) should always prompt the question: "how did they get in, and where else have they been?" — not just "how do I remove this cron job?"

### A.3.1 Mapping This Series' Content Onto the Full Tactic List

It's useful to see, at a glance, exactly which tactics this series' hands-on hunts actually covered — and, just as importantly, which ones we deliberately left as an exercise for you to extend:

| Tactic | Covered in This Series? | Where |
|---|---|---|
| Reconnaissance | ❌ Not covered | Would require external-facing telemetry (e.g., WAF logs) outside this series' Linux-endpoint/network scope |
| Resource Development | ❌ Not covered | Primarily a threat-intel research activity, not a telemetry-based hunt |
| Initial Access | ❌ Not covered | Assumed as the "given" starting point of our Part 1 hypothetical actor profile |
| **Execution** | ✅ Covered | Part 3 (web shell process ancestry hunt) |
| **Persistence** | ✅ Covered | Part 2 (audit rules) + Part 3 (cron persistence hunt) |
| Privilege Escalation | ⚠️ Partially covered | Part 2's audit rules watch for it (`priv_escalation` key); no dedicated hunt query was built — a natural "next hunt" exercise |
| **Defense Evasion** | ✅ Covered | Part 3 (binary masquerading hunt) |
| Credential Access | ❌ Not covered | Implied as a precondition of our SSH hypothesis, but no dedicated credential-theft-detection hunt was built |
| Discovery | ❌ Not covered | A strong candidate for your own follow-up hunt using the osquery pack from Part 2 |
| **Lateral Movement** | ✅ Covered | Part 4 (SSH bastion-bypass hunt — our entire running example) |
| Collection | ❌ Not covered | — |
| **Command and Control** | ✅ Covered | Part 4 (DNS beaconing hunt) |
| Exfiltration | ❌ Not covered | Part 4's §4.6 session volume analysis lays groundwork, but no dedicated rule was built |
| Impact | ❌ Not covered | — |

> **Blockquote — An Honest Note on Scope:** This table is not a confession of failure — it's a demonstration of exactly the kind of **coverage gap awareness** that makes a hunting program mature (recall the Maturity Model, §1.1.3). A team that can produce a table like this for their *own* environment, honestly, is already operating at a higher level of self-awareness than most. Use the blank rows above as a literal to-do list: each one is a legitimate "Part 6, 7, 8..." you could write for yourself using the exact same six-step methodology from §1.5.

---

## A.4 A Practical Navigation Workflow

When you receive a new piece of threat intelligence or observe an anomaly, use this workflow to find the right ATT&CK ID(s) — this is the concrete, step-by-step process referenced back in Part 1, §1.5, Step 2:

### Step 1 — Search, Don't Guess
Go to **attack.mitre.org** and use the search bar in plain English (e.g., "cron persistence," "SSH lateral movement," "web shell") rather than trying to guess an ID directly. MITRE's search indexes technique descriptions, not just titles, so natural-language phrasing usually surfaces the right page within the first few results.

### Step 2 — Read the Full Technique Page, Not Just the Title
Every technique page includes several sections worth reading in full, not skimming:

- **Description** — the general behavior definition.
- **Sub-techniques tab** — check this *every time*, even if the parent technique looks specific enough; as shown in §A.2.3, the parent is often too broad to act on directly.
- **Procedure Examples** — a table of real, named threat groups and malware families documented using this exact technique in confirmed incidents. This table is gold for justifying a hunt hypothesis's "Actor" field (Part 1, §1.4.1) with real-world precedent rather than pure speculation.
- **Mitigations** — MITRE's suggested preventive controls; useful context even though this series focuses on *detection*, not prevention.
- **Detection** — MITRE's own suggested data sources and analytic approaches. This section frequently validates (or expands) your own Part 2-style telemetry planning.

### Step 3 — Cross-Reference the "Data Sources" Section

Since ATT&CK version 10, MITRE has maintained a structured **Data Sources** and **Data Components** taxonomy directly tied to each technique — essentially MITRE's own answer to "what telemetry would I need to detect this?" For `T1021.004` (SSH), the listed data sources include things like `Logon Session: Logon Session Creation`, `Network Traffic: Network Connection Creation`, and `Command: Command Execution` — which map almost one-to-one onto the exact telemetry pillars (auditd, Zeek, osquery) this series built in Part 2. This is not a coincidence: MITRE's Data Sources framework and this series' three-pillar architecture are both derived from the same underlying reality of what's actually observable on a Linux host and network.

### Step 4 — Check the Software/Groups Pages for Additional Context

Every technique page links to specific **Groups** (named, tracked threat actors) and **Software** (named malware/tools) known to have used it. Clicking into a Group's own page shows their *entire* known technique repertoire — useful when your threat intelligence names a specific actor and you want to build out a comprehensive set of hunt hypotheses covering everything that group is known to do, not just the one technique your initial report mentioned.

---

## A.5 The ATT&CK Navigator — Visualizing Your Coverage

### A.5.1 What the Navigator Actually Is

MITRE provides a free, browser-based tool called the **ATT&CK Navigator** (available at `mitre-attack.github.io/attack-navigator/`, or self-hostable via its open-source GitHub repository for air-gapped environments) that renders the entire matrix as an interactive heat-map grid — every Tactic as a column, every Technique/Sub-Technique as a cell within it.

**Analogy:** If the ATT&CK matrix itself is a giant reference textbook, the Navigator is a **highlighter and sticky-note system** you use directly on top of it — marking which chapters you've already secured, which you're worried about, and which specific real-world threat's "reading list" you're currently comparing yourself against.

### A.5.2 Core Navigator Use Cases for a Hunter

- **Color-code techniques by detection coverage.** A common convention: green = "we have a deployed Sigma rule," yellow = "we have telemetry but no rule yet," orange = "partial telemetry, real gaps," red = "no visibility at all." This is the single most useful artifact for reporting detection maturity to leadership — a picture is worth a thousand hunt reports.
- **Overlay a specific threat group's known technique list** (selectable directly from ATT&CK's own Groups database within the Navigator's "create layer from other CTI" feature) against your own coverage layer, instantly revealing exactly which of *that group's* specific techniques you'd currently miss.
- **Layer comparison/subtraction.** The Navigator supports mathematically combining multiple layers (e.g., "Layer A minus Layer B") — useful for a "gap analysis" showing precisely which techniques a relevant threat actor uses that your current coverage layer does *not* address.
- **Export/import layers as JSON**, making this a version-controllable artifact just like our Sigma rules in Part 5. This means your team's ATT&CK coverage map can live in the same Git repository as your detection rules, reviewed and updated via the same pull-request workflow from §5.6.3.

### A.5.3 Hands-On Exercise: Building Your Own Coverage Layer

**Step 1:** Navigate to the Navigator, select "Create New Layer" → "Enterprise ATT&CK" → the current matrix version.

**Step 2:** Using the search/select tool, locate `T1505.003` (Web Shell, under Persistence) and `T1021.004` (SSH, under Lateral Movement).

**Step 3:** For each, set the cell's background color to green and add a comment (the Navigator supports per-technique annotations) reading something like:

```
T1505.003: Detected via Sigma rule 'webshell-process-ancestry.yml'
           (process ancestry - web server parent spawning shell child).
           Deployed as OpenSearch monitor. Ref: HUNT-2024-002.

T1021.004: Detected via Sigma rule 'ssh-bastion-bypass.yml'
           (internal SSH bypassing bastion host, non-bastion source).
           Deployed as OpenSearch monitor. Ref: HUNT-2024-001.
           KNOWN GAP: does not yet incorporate novel-pairing baseline
           logic from hunt_rare_host_pairings.py - see Part 5 §5.7.4.
```

**Step 4:** Optionally, set every *other* technique's cell to a neutral gray with no score, honestly representing "not yet assessed" rather than falsely implying "confirmed no coverage" — an important honesty distinction, since "not assessed" and "assessed and found lacking" are very different states that leadership needs to be able to tell apart.

**The Verification:** Export this layer as JSON (`Layer Controls → Download Layer as JSON`). Confirm the resulting file is valid JSON containing your two scored techniques with their annotations intact by re-importing it into a fresh Navigator tab (`Open Existing Layer → Upload from Local`) and confirming both cells render with your chosen color and comment text. This single exported JSON file is a legitimate, presentable artifact of everything this entire series has accomplished — commit it to your `sigma-rules/` repository alongside the rules themselves.

---

## A.6 Prioritization — You Cannot Hunt Everything At Once

### A.6.1 The Prioritization Problem

As of this writing, the Enterprise ATT&CK matrix documents over 200 techniques and 400+ sub-techniques. No individual analyst, and no organization regardless of size, achieves meaningful hunting coverage across all of them simultaneously — nor should that be the goal. A common and serious beginner mistake is treating the matrix as a checklist to "complete," which leads to shallow, box-ticking coverage rather than deep, well-validated detections for the techniques that actually matter to your specific environment.

### A.6.2 A Practical Prioritization Framework

Use these four lenses, in combination, to decide where to focus your *next* hunt hypothesis:

| Lens | Guiding Question | Practical Method |
|---|---|---|
| **Threat Relevance** | Which techniques do adversaries who actually target organizations like mine actually use? | Pull your industry's relevant threat groups from ATT&CK's Groups pages; cross-reference with ISAC (Information Sharing and Analysis Center) reporting for your sector |
| **Telemetry Feasibility** | Do I even have (or can I reasonably build) the data source this technique requires? | Cross-reference the technique's "Data Sources" section (§A.4, Step 3) against your actual Part 2-style telemetry inventory |
| **Pyramid of Pain Value** | Does hunting this technique produce a durable detection, or one an attacker trivially bypasses? | Revisit §1.2 — prioritize behavior/TTP-level techniques over IOC-level ones |
| **Historical Incident Relevance** | Has this technique, or something like it, actually happened to us (or a very similar organization) before? | Review internal incident post-mortems (§1.4.1) — your own history is your single best prioritization signal |

### A.6.3 A Worked Prioritization Example

Suppose you have limited hunting time this quarter and must choose between three candidate techniques: `T1071.004` (DNS-based C2, already covered in Part 4), `T1003` (OS Credential Dumping — Windows-focused, and you're an all-Linux shop), and `T1548.001` (Setuid/Setgid privilege escalation abuse, already partially instrumented by Part 2's `hunt.rules`). Applying the framework:

- `T1003` fails the **Telemetry Feasibility** lens immediately — it's fundamentally a Windows-specific technique family (LSASS memory access, SAM database, etc.) with no direct Linux analog, so pursuing it in an all-Linux environment is close to a wasted effort, regardless of how "important-sounding" credential dumping is in general industry discourse.
- `T1548.001` scores well on **Telemetry Feasibility** (Part 2's `hunt.rules` already has a `priv_escalation` audit key ready to query) and reasonably well on **Pyramid of Pain Value** (a behavior, not an IOC) — making it a strong, low-effort-to-start candidate for your *next* hunt hypothesis, directly extending this series' existing foundation.
- `T1071.004` is already covered — re-hunting it without new intelligence suggesting evasion of your existing detection wouldn't be the best use of limited time this quarter.

**Conclusion of the worked example:** `T1548.001` (Setuid/Setgid privilege escalation) is the clear next hunt hypothesis to formulate using the Part 1 ABLE framework, since it scores well across telemetry feasibility and detection durability, and directly builds on infrastructure you already have.

---

## A.7 Common Beginner Mistakes When Using ATT&CK

| Mistake | Why It's a Problem | Correction |
|---|---|---|
| Treating ATT&CK as a checklist to "complete" | The matrix has 200+ techniques and 400+ sub-techniques; no organization achieves 100% coverage, nor should that be the goal | Prioritize using the four-lens framework in §A.6.2, focused on relevance to your actual environment |
| Confusing a Tactic with a Technique | "Lateral Movement" is a *goal*, not a specific detectable action — you cannot write a detection rule for a Tactic | Always hunt and write detections at the Technique/Sub-Technique level — that's where concrete, queryable telemetry patterns exist |
| Mapping one hunt to a Tactic ID instead of a Technique ID | Loses specificity needed for actual detection engineering and coverage tracking | Always cite the most specific Sub-Technique ID available (e.g., `T1021.004`, not just `T1021` or `TA0008`) |
| Assuming ATT&CK coverage = actual detection quality | A Sigma rule tagged `T1021.004` might only catch one narrow variant of SSH lateral movement (as our own Part 5 rule's documented gap shows) | Coverage tags indicate *intent to detect*, not a guarantee of catching every possible technique variant — validate rule efficacy via red-teaming/purple-teaming where possible, and document known gaps honestly (as we did in §5.7.4) |
| Ignoring the Sub-techniques tab | Parent techniques are often far too broad to build a coherent, low-noise detection around (§A.2.3) | Always check for and prefer the most specific sub-technique that matches your observed behavior |
| Forgetting that one technique can span multiple tactics | Leads to miscategorized hunt documentation and confused coverage layers | Always specify both Tactic and Technique together when precision matters (§A.2.2) |
| Building detections only for "exciting" late-stage tactics (Impact, Exfiltration) | Ignores that earlier-stage detections (Initial Access, Execution, Persistence) are typically higher-value — they catch an intrusion *before* damage occurs | Weight prioritization toward earlier kill-chain stages where feasible; recall our own series deliberately focused on Execution/Persistence (Part 3) and Lateral Movement (Part 4), not Impact |
| Never updating a coverage layer after the matrix itself is updated | MITRE periodically restructures techniques (merges, splits, renumbers sub-techniques) between major matrix versions | Re-validate your Navigator layer's technique IDs against the current matrix version at least annually, and whenever MITRE publishes a major version changelog |

---

## A.8 ATT&CK as a Shared Language Across This Entire Series — A Full Recap

To cement how thoroughly this framework threads through everything you've built, here is every single ATT&CK reference made across Parts 1–5, consolidated in one place:

| Part | Hunt/Artifact | Tactic(s) | Technique/Sub-Technique(s) |
|---|---|---|---|
| Part 1 | Running hypothesis example (HUNT-2024-001) | TA0008 (Lateral Movement) | T1021.004 (SSH) |
| Part 2 | `hunt.rules` — cron/systemd/SSH watches | TA0003 (Persistence) | T1053.003 (Cron), T1543.002 (Systemd Service) |
| Part 2 | `hunt.rules` — account manipulation watch | TA0003 (Persistence) | T1136 (Create Account) |
| Part 2 | `hunt-pack.json` — SUID binaries query | TA0004 (Privilege Escalation) | T1548.001 (Setuid/Setgid) |
| Part 2 | `hunt-pack.json` — open sockets query | TA0011 (Command and Control) | T1071 (Application Layer Protocol) |
| Part 3 | Web shell ancestry hunt | TA0002 (Execution), TA0003 (Persistence) | T1059 (Command/Scripting Interpreter), T1505.003 (Web Shell) |
| Part 3 | Cron persistence hunt | TA0003 (Persistence) | T1053.003 (Cron) |
| Part 3 | Binary masquerading hunt | TA0005 (Defense Evasion) | T1036.004 (Masquerade Task or Service) |
| Part 4 | SSH bastion-bypass hunt (HUNT-2024-001 executed) | TA0008 (Lateral Movement) | T1021.004 (SSH) |
| Part 4 | Rare host pairing baseline | TA0008 (Lateral Movement) | T1021.004 (SSH) |
| Part 4 | DNS beaconing detection | TA0011 (Command and Control) | T1071.004 (DNS), T1568 (Dynamic Resolution) |
| Part 5 | `webshell-process-ancestry.yml` Sigma rule | TA0002, TA0003 | T1059, T1505.003 |
| Part 5 | `ssh-bastion-bypass.yml` Sigma rule | TA0008 | T1021.004 |

> **Blockquote — The Real Takeaway:** Notice that a single technique ID — `T1021.004` — appears consistently from the very first sentence of Part 1 all the way through the final deployed OpenSearch monitor in Part 5. That consistency is not a stylistic choice; it is the entire *point* of adopting ATT&CK as your organization's shared vocabulary. Every artifact in this table — a hypothesis, an audit rule, a VQL query, a Python script, a Sigma rule, a Navigator layer — can be instantly cross-referenced by anyone on your team, or in the broader security community, because they all speak the same standardized language. This is the operational payoff of treating ATT&CK not as trivia to memorize, but as the connective tissue binding your entire detection program together.
