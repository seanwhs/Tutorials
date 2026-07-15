# Part 0: Welcome to the Hunt (Series Introduction) — Expanded Edition

> **Blockquote — Series Mission Statement:** This series will teach you to hunt sophisticated adversaries using tools that cost $0 in licensing fees. Every configuration, query, and rule in this series is copy-pasteable and runs on hardware you probably already own. By the end of Part 5, you will have built a functioning, end-to-end detection pipeline — from raw kernel telemetry to an automated Sigma alert — using nothing but open-source software.

---

## 0.1 The FOSS Philosophy

There is a pervasive myth in the cybersecurity industry: that meaningful threat detection requires a six-figure Endpoint Detection and Response (EDR) contract, a proprietary SIEM (Security Information and Event Management platform), and a vendor's blessing. This is false, and it is a myth that primarily benefits vendors, not defenders.

Think of it like cooking. A five-star restaurant's expensive imported knife set doesn't make the chef good — it's their *understanding of heat, timing, and ingredients* that does. A skilled cook with a $20 knife will out-cook an amateur with a $2,000 knife set every time. Threat hunting is the same: the **telemetry** (the raw data describing what a computer or network is actually doing) and your **understanding of adversary behavior** are what matter. The vendor dashboard is just a knife. This series teaches you to sharpen the knife yourself, and — more importantly — to cook without needing anyone else's kitchen.

### 0.1.1 What "Open Telemetry" Actually Means

The word "open" gets thrown around loosely in security marketing, so let's define it precisely, because this series treats it as a load-bearing concept, not a buzzword.

**Open telemetry standards** are data formats and collection mechanisms whose specifications are:

1. **Publicly documented** — anyone can read exactly what each field means, with no NDA (Non-Disclosure Agreement) required.
2. **Freely implementable** — anyone can write a tool that produces or consumes the format without paying a licensing fee.
3. **Not tied to a single vendor's runtime** — the data outlives the tool. A Zeek `conn.log` from 2015 is still readable and analyzable today with nothing more than `awk` or Python, because it's plain, documented, delimited text.

Compare this to a **closed telemetry model**, where an EDR agent collects rich data on your endpoint, but that data is serialized into a proprietary binary or database format that only the vendor's own cloud backend can fully parse. If you stop paying, you don't just lose the dashboard — you often lose the ability to read your *own* historical security data at all. That is the barrier this series exists to eliminate.

| Property | Closed/Proprietary Telemetry | Open Telemetry (this series) |
|---|---|---|
| **Format documentation** | Often undocumented / reverse-engineered by researchers | Fully published (e.g., Zeek's log field docs, the Linux Audit man pages) |
| **Vendor lock-in** | High — data often unusable outside vendor's platform | None — plain JSON/TSV/syslog, readable by any tool |
| **Cost to retain historical data** | Often billed per-GB-ingested by the vendor's cloud | Whatever your own disk costs |
| **Community rule-sharing** | Rules are vendor IP, rarely shared publicly | Sigma rules, Zeek scripts, osquery packs shared openly on GitHub |
| **Auditability of detection logic** | "Trust our ML model" — logic is a black box | Every query, every rule is human-readable text you can review line by line |

> **Blockquote — Conceptual Warning:** Being FOSS does not automatically mean "worse" or "hobbyist-grade." Zeek was born out of Lawrence Berkeley National Laboratory and is used today inside Fortune 500 SOCs and national intelligence agencies. Osquery was created inside Facebook to monitor a fleet of hundreds of thousands of production servers. Velociraptor was built by DFIR (Digital Forensics and Incident Response) practitioners who got frustrated with commercial tooling gaps. FOSS in this space is not the "budget tier" — in many cases, it is the *reference implementation* that commercial products imitate.

### 0.1.2 The Real Cost Comparison

Let's be concrete about the economics, because "it's free" is only half the story — there is no such thing as a truly free security program, only a program where you trade **licensing dollars** for **engineering time**. Understanding this trade-off honestly is part of being a good security architect.

| Cost Category | Typical Commercial EDR/SIEM Stack | FOSS Stack (this series) |
|---|---|---|
| **Per-endpoint licensing** | $5–$15/endpoint/month, often with annual minimums | $0 |
| **Log ingestion/storage** | Billed per GB, frequently the largest line item | Cost of your own disk (commodity, ~$0.02/GB/month on cheap storage) |
| **Detection content (rules)** | Usually included but closed-source / unauditable | Community Sigma rules (free) + your own custom rules |
| **Engineering/tuning time** | Lower — vendor manages the backend | Higher — you own the pipeline, so you own the maintenance |
| **Portability if you switch jobs/vendors** | Low — skills are vendor-specific query languages | High — MITRE ATT&CK, Sigma, osquery SQL are universal |
| **Ability to audit false-negative causes** | Usually impossible (black-box ML) | Fully possible — every rule is inspectable text |

The honest takeaway: **FOSS threat hunting trades subscription cost for engineering ownership.** This series is designed to make that ownership approachable, not intimidating — which is precisely why every configuration file below is complete and copy-pasteable, not a fragment you have to reverse-engineer.

### 0.1.3 Why Proprietary Tools Shouldn't Be a Barrier to *Entry*

Note the careful wording: proprietary EDRs are not "bad" — many are excellent, well-engineered products. The problem this series solves is one of **entry**. Consider who is locked out if the only path into this discipline runs through expensive tooling:

- The **university student** who wants to learn threat hunting before their first job.
- The **three-person startup security team** who cannot justify a six-figure annual EDR contract but still faces real adversaries.
- The **solo consultant or freelance analyst** building a home lab to practice for a certification.
- The **defender in a resource-constrained region or organization** — a hospital, a school district, a local government — where budget realities are non-negotiable.

Every one of these people can install `auditd`, `osquery`, `zeek`, and `velociraptor` on a spare laptop tonight, for free, and be running real hunts by this time tomorrow. That accessibility is the entire premise of this series.

---

## 0.2 The Series Roadmap

### 0.2.1 High-Level Breakdown

| Part | Title | What You'll Build | Core Question It Answers |
|---|---|---|---|
| **Part 0** | Welcome to the Hunt | This introduction — mindset, roadmap, lab prerequisites | "Why FOSS, and what am I about to build?" |
| **Part 1** | The Threat Hunting Mindset & Hypothesis Generation | A repeatable hunt methodology (ABLE framework) + a Markdown Hunt Investigation Template | "How do I turn intelligence into a testable hypothesis, instead of randomly poking at logs?" |
| **Part 2** | The Open Source Data Engine | A working `auditd` ruleset, an osquery query pack, and a live Zeek sensor emitting logs | "Where does the evidence I'll hunt through in Parts 3–4 actually come from?" |
| **Part 3** | Hunting for Execution & Persistence | Velociraptor artifact collection + VQL/osquery queries catching web shells and cron persistence | "How do I find an adversary who is already running code or trying to survive a reboot?" |
| **Part 4** | Hunting for Lateral Movement & C2 | Zeek log analysis to detect SSH hijacking and DNS beaconing, with Python/awk parsers | "How do I find an adversary moving between my hosts or phoning home?" |
| **Part 5** | Operationalizing the Hunt | A production Sigma rule converting a manual Part 3/4 hunt into an automated, permanent detection | "How do I make sure I never have to manually hunt for the *same* thing twice?" |
| **Appendix A** | MITRE ATT&CK Operator's Guide | A navigable mental model of the ATT&CK matrix | "How do I use ATT&CK as a working tool, not just a poster on the wall?" |
| **Appendix B** | The FOSS Hunting Tool Directory | Quick-reference table of every tool used in this series | "Which tool do I reach for, and where does it sit in my stack?" |
| **Appendix C** | Essential Log Formats | Annotated real-world malicious log samples from Auditd, Zeek, and Osquery | "What does *evil* actually look like in raw JSON, key by key?" |

### 0.2.2 The Dependency Chain — Why Order Matters

This is not a series of disconnected blog posts — it is a single, cumulative build, and skipping a part will leave a gap later. Here is the exact dependency chain, so you understand *why* the order is fixed:

```
Part 1 (Mindset)
   │  gives us: a hypothesis about SSH lateral movement (T1021.004)
   ▼
Part 2 (Data Engine)
   │  gives us: auditd + osquery + Zeek actually installed and logging
   │  WITHOUT this, Parts 3 & 4 have nothing to query against.
   ▼
   ├──► Part 3 (Endpoint Hunt: Execution & Persistence)
   │        uses: osquery + Velociraptor, consuming Part 2's endpoint telemetry
   │
   └──► Part 4 (Network Hunt: Lateral Movement & C2)
            uses: Zeek conn.log/ssh.log/dns.log, consuming Part 2's network telemetry
            ALSO: resolves the exact hypothesis formulated in Part 1 (§1.4)
   │
   ▼
Part 5 (Operationalize)
   takes: ONE confirmed finding pattern from Part 3 or Part 4
   produces: a permanent Sigma rule — closing the loop back to Part 1's
             "Detection Engineering Follow-Up" section of the hunt template
```

Notice the loop: Part 1 ends with a template section literally titled *"Should this become a permanent Sigma rule?"* — and Part 5 is the answer to that exact question. This series is a circle, not a line: **mindset → telemetry → hunt → automation → back to mindset for the next hunt.**

### 0.2.3 Estimated Effort Per Part

To set realistic expectations for your own pacing:

| Part | Reading Time | Hands-On Lab Time | Difficulty |
|---|---|---|---|
| Part 0 | 15 min | — | ⭐ Orientation |
| Part 1 | 30 min | 20 min (fill out template) | ⭐ Conceptual |
| Part 2 | 45 min | 1.5–2 hrs (installing 3 tools) | ⭐⭐ Foundational |
| Part 3 | 60 min | 2–3 hrs (Velociraptor + VQL practice) | ⭐⭐⭐ Applied |
| Part 4 | 60 min | 2–3 hrs (Zeek log analysis + scripting) | ⭐⭐⭐ Applied |
| Part 5 | 40 min | 1–1.5 hrs (Sigma authoring + testing) | ⭐⭐⭐⭐ Synthesis |
| Appendices | Reference — read as needed throughout | — | Reference |

> **Blockquote — Pacing Advice:** Do not binge this series in one sitting. Part 2's lab environment is the foundation every later part depends on — if you rush the installs and your telemetry pipeline is broken, every query in Parts 3–5 will silently return nothing, and you'll wrongly conclude the *queries* are broken when it's actually the *pipeline*. Verify each step's output before moving on. The Verification sub-sections are not optional — they are how you catch a broken foundation before you've built three more floors on top of it.

---

## 0.3 Prerequisites

### 0.3.1 Knowledge Prerequisites

Before continuing, you should be comfortable with the following. None of these require mastery — just familiarity:

| Skill Area | What You Should Already Know | What This Series Will Teach You On Top Of It |
|---|---|---|
| **Basic Linux CLI** | Navigating directories (`cd`, `ls`), reading files (`cat`, `less`, `tail`), editing text (`vim`/`nano`), installing packages (`apt`) | How to read audit logs, write query packs, and parse Zeek logs at the command line |
| **Networking fundamentals** | What an IP address, port, and DNS query are; the general idea of a TCP handshake | How adversaries abuse these fundamentals (beaconing, SSH pivoting) and how to spot it in logs |
| **General curiosity** | You don't need prior SOC (Security Operations Center — a team that monitors security alerts) experience | We define every acronym (VQL, ATT&CK, IOC, TTP, etc.) the first time it appears |

**Explicitly NOT required:** prior malware analysis experience, a security certification, programming fluency (a small amount of Python and `awk` is introduced gradually and explained line-by-line in Part 4), or any commercial tool experience.

### 0.3.2 The Lab Environment We Will Build Together

Throughout this series, we assume access to a small lab. You have two options — both are fully supported by this series' instructions:

**Option A — Two Virtual Machines (Recommended for clarity)**
A "target" endpoint and a "sensor" network box, so endpoint telemetry (Part 2's auditd/osquery) and network telemetry (Part 2's Zeek) are conceptually and physically separated — closer to how a real environment is architected.

**Option B — One Single VM/Machine (Fine for learning, less realistic)**
All three tools (auditd, osquery, Zeek) installed on one box. Perfectly adequate for following every query and concept in this series; just know that in production, Zeek typically lives on a network tap or span port, not on the endpoint itself.

```
                     ┌───────────────────────────────────────────┐
                     │              YOUR HUNT LAB                 │
                     │                                             │
   ┌───────────┐     │   ┌─────────────────────┐                  │
   │  Analyst  │◄────┼───┤   Linux Endpoint      │                 │
   │ Workstation│    │   │  - auditd (Part 2)    │                 │
   │ (queries   │    │   │  - osquery (Part 2)   │                 │
   │  from here)│    │   │  - Velociraptor client │                │
   └───────────┘     │   │    (Part 3)            │                │
                     │   └──────────┬────────────┘                  │
                     │              │ network traffic                │
                     │              ▼                                │
                     │   ┌─────────────────────┐                    │
                     │   │  Network Sensor       │                  │
                     │   │  - Zeek (Part 2 & 4)  │                  │
                     │   │  - sees traffic via    │                 │
                     │   │    span/mirror port    │                 │
                     │   │    or same-host bridge │                 │
                     │   └─────────────────────┘                    │
                     └───────────────────────────────────────────┘
```

### 0.3.3 Minimum Hardware/VM Specifications

| Component | Minimum Spec | Recommended Spec | Notes |
|---|---|---|---|
| **OS** | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS | All Part 2 install commands are written for Debian/Ubuntu (`apt`). RHEL/CentOS equivalents noted where package names differ. |
| **CPU** | 2 vCPU | 4 vCPU | Zeek is the most CPU-hungry component under real traffic load. |
| **RAM** | 2 GB | 4–8 GB | Osquery and Zeek both hold in-memory state; more RAM = longer log retention windows without swapping. |
| **Disk** | 20 GB | 40+ GB | Auditd and Zeek logs grow quickly under verbose rulesets — see Part 2's log rotation guidance. |
| **Network** | 1 NIC | 1 NIC (endpoint) + 1 NIC in promiscuous mode (sensor) | Promiscuous mode is required for Zeek to see traffic that isn't destined for its own IP — we configure this explicitly in Part 2. |

### 0.3.4 Exact Software Versions Used In This Series

Pinning versions matters for reproducibility — security tooling behavior (especially rule syntax) can shift between major versions. Every command in this series was validated against the following:

| Tool | Version Used | Install Method |
|---|---|---|
| Ubuntu | 22.04 LTS (Jammy) | Base OS |
| auditd | 3.0.7 (Ubuntu package) | `apt install auditd audispd-plugins` |
| osquery | 5.11.0 | Official osquery APT repository |
| Zeek | 6.0.x (LTS) | Official Zeek OpenSUSE Build Service repo |
| Velociraptor | 0.72.x | Official signed binary release from GitHub |
| Sigma / `sigma-cli` (pySigma) | pySigma 0.10.x / sigma-cli 0.9.x | `pip install sigma-cli` |

> **Blockquote — Conceptual Warning:** Do not `apt install zeek` from Ubuntu's default repositories — as of this writing, Ubuntu's default repos often carry outdated or renamed (`bro`) packages. Part 2 will give you the exact, current, official repository commands. Following outdated tutorials found elsewhere online is one of the most common reasons beginners get "stuck" before they even start hunting — always prefer official project documentation for install steps, and treat this series' Part 2 as that official, current path.

### 0.3.5 A Note on Permissions

Every tool in this series (`auditd`, `osquery`, `zeek`, `velociraptor`) requires elevated privileges to install and, in most cases, to run — because they hook into kernel-level interfaces (syscalls, raw network sockets) that are, by design, inaccessible to unprivileged users. You will need `sudo` or `root` access on your lab machine(s). This is expected and safe **within an isolated lab environment**; it is not something you should do on a production system you don't fully control until you've completed this series and understand exactly what each configuration does.

---

## 0.4 How This Series Is Structured — Reading Conventions

To make this series maximally practical, every hands-on step (starting in Part 1) follows a strict four-part pattern. Recognizing this pattern now will make the rest of the series easier to navigate:

| Marker | Meaning |
|---|---|
| **The Target** | The exact file, configuration, or feature being built in this step — stated as a file path or feature name. |
| **The Concept** | A plain-language analogy explaining the underlying logic *before* you see any code. |
| **The Implementation** | Complete, unabbreviated, copy-pasteable code/config — never a fragment, never a "...". |
| **The Verification** | An explicit command or expected output you can check *right now*, before moving to the next step. |

Additionally, throughout the series:

- **`> Blockquote` callouts** are used exclusively for conceptual warnings, common pitfalls, or "don't skip this" emphasis — treat every blockquote as a flag to slow down and re-read.
- **Code block labels** (e.g., `#### File: /etc/audit/rules.d/hunt.rules`) always state the exact file path — if a code block has no path label, it is a terminal command to run interactively, not a file to save.
- **Tables** are used any time we're comparing options, mapping tool capabilities, or summarizing a reference (e.g., Appendix B).

---

## 0.5 A Preview of Your Toolkit

You'll meet each of these properly in later parts, but here is the cast of characters so the names aren't a surprise when they first appear:

| Tool | One-Line Purpose | First Appears In |
|---|---|---|
| **Auditd** | Records raw Linux system calls (kernel-level "who did what") | Part 2 |
| **Osquery** | Lets you query your OS's live state using SQL | Part 2 |
| **Zeek** | Turns raw network packets into structured, analyzable connection/protocol logs | Part 2 |
| **Velociraptor** | Open-source DFIR orchestrator — remotely collects forensic artifacts at scale | Part 3 |
| **Sigma** | A vendor-agnostic YAML format for writing detection rules once, deploying anywhere | Part 5 |
| **MITRE ATT&CK** | The shared vocabulary/knowledge base for describing adversary behavior | Part 1 (used throughout, detailed in Appendix A) |

Full capability breakdowns, telemetry outputs, and stack placement for every one of these tools are consolidated in **Appendix B: The FOSS Hunting Tool Directory** for quick reference once you've met them all.

---

## 0.6 Readiness Checklist

Before moving on to Part 1, confirm the following. This is intentionally lightweight — it's a sanity check, not a gate:

- [ ] I understand *why* this series uses only FOSS tools (§0.1), and I'm not expecting a GUI dashboard to do the thinking for me.
- [ ] I know the six parts and roughly what each one produces (§0.2.1).
- [ ] I understand the dependency chain — Part 2's telemetry is required before Parts 3–5 make sense (§0.2.2).
- [ ] I have (or am about to provision) at least one Linux VM matching the specs in §0.3.3.
- [ ] I'm comfortable with basic Linux CLI navigation and know that root/sudo access will be required.
- [ ] I understand the "Target / Concept / Implementation / Verification" pattern I'll see in every hands-on step from Part 1 onward (§0.4).

> **Blockquote — Final Note Before We Begin:** Threat hunting is a discipline built on humility, not heroics. The best hunters aren't the ones who find something exciting every single time — they're the ones who follow a rigorous, repeatable process, document their negative results as carefully as their positive ones, and constantly feed their findings back into automated detection so they never have to manually chase the same ghost twice. That entire discipline — mindset, telemetry, hunting, and automation — is what this series builds, one part at a time, starting now.

**Proceed to Part 1: The Threat Hunting Mindset & Hypothesis Generation.**
