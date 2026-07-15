# Appendix B: The FOSS Hunting Tool Directory

> **Blockquote — Purpose of This Appendix:** Parts 2 through 5 introduced six tools in the order you needed them, each explained just enough to keep the tutorial moving. This appendix consolidates all six into a single, standalone reference — a directory you can return to months from now when you've forgotten which tool sits where in the stack, or when you're explaining this architecture to a new team member who hasn't read the whole series.

---

## B.1 The Quick-Reference Capability Table

| Tool | Primary Use Case | Telemetry Output | Stack Position | License |
|---|---|---|---|---|
| **Auditd** | Kernel-level system call auditing (execution, file access, privilege changes) | Structured text log (`/var/log/audit/audit.log`), key-value pairs, `type=SYSCALL/PATH/...` records | Endpoint — kernel/OS layer | GPLv2 |
| **Osquery** | SQL-queryable live OS state (processes, sockets, users, packages, scheduled tasks) | JSON (via logger plugin), differential "added/removed" events | Endpoint — OS state/inventory layer | Apache 2.0 / GPLv2 (dual) |
| **Zeek** | Deep network protocol parsing into structured connection/application logs | Tab-separated (or JSON) log files: `conn.log`, `dns.log`, `ssh.log`, `http.log`, `ssl.log`, etc. | Network — wire/protocol layer | BSD 3-Clause |
| **Suricata** | Network intrusion detection/prevention via signature and protocol-anomaly rules | EVE JSON log (alerts, flow, DNS, TLS, HTTP records), unified alert stream | Network — wire/protocol + signature layer | GPLv2 |
| **Velociraptor** | Fleet-wide DFIR artifact collection and hunting orchestration | VQL query result sets (JSON), collected files/artifacts stored server-side | Endpoint orchestration — cross-host coordination layer | Apache 2.0 |
| **Sigma** | Vendor-agnostic detection-as-code rule format | N/A (a rule format, not a telemetry source) — converts to backend-native queries | Detection engineering — the top of the stack, consuming everything below | Detection Rule License (DRL) 1.1 (permissive, OSI-adjacent) |

### B.1.1 Reading the Table Correctly — A Note on "Stack Position"

The "Stack Position" column deserves a moment of explanation, because it's the single most useful mental model for deciding *which tool to reach for* when you're facing a new hunt hypothesis. Think of your entire detection capability as a vertical stack, similar to how networking people think of the OSI model:

```
┌─────────────────────────────────────────────────────┐
│  DETECTION ENGINEERING LAYER                          │
│  Sigma  — expresses "what counts as suspicious,"       │
│           independent of where the data lives           │
├─────────────────────────────────────────────────────┤
│  ORCHESTRATION LAYER                                   │
│  Velociraptor — dispatches collections/hunts across     │
│                 many endpoints at once                   │
├─────────────────────────────────────────────────────┤
│  TELEMETRY GENERATION LAYER                             │
│  Auditd (kernel/syscall)  │  Osquery (OS state)          │
│  Zeek (network metadata)  │  Suricata (network signatures)│
└─────────────────────────────────────────────────────┘
```

A hunt hypothesis always starts by asking "what layer does my evidence live in?" (exactly Part 1's Step 3 — Identify Required Telemetry), then picks the appropriate tool from the bottom layer, optionally orchestrates its collection with the middle layer, and — once validated — encodes the final logic at the top layer for permanent automation. This is the literal architecture of Parts 2 through 5, made explicit as a single diagram.

---

## B.2 Auditd — Deep Reference

### B.2.1 Capability Summary

| Attribute | Detail |
|---|---|
| **What it fundamentally is** | The userspace daemon for the Linux kernel's built-in Audit Framework |
| **Granularity** | System call level — the lowest-level, highest-fidelity telemetry available on Linux without custom kernel modules |
| **Configuration mechanism** | Static rule files (`/etc/audit/rules.d/*.rules`) loaded via `augenrules`, or live rules via `auditctl` |
| **Query interface** | `ausearch` (event search) and `aureport` (summarized reporting) — no native SQL-like interface |
| **Performance overhead** | Low-to-moderate; scales with rule verbosity and system call volume — always tune backlog buffer size (`-b`) for busy hosts |
| **Where we used it in this series** | Part 2 (`hunt.rules` — execution, persistence, privilege escalation, account manipulation watches); Part 3 (querying the `cron_persistence` key); Part 5 (Logstash ingestion pipeline feeding OpenSearch) |
| **Key strength** | Tamper-evidence (`-e 2` immutable mode) and the `auid` field's unbroken attribution through privilege escalation chains (§2.3) |
| **Key limitation** | Raw records lack resolved parent-process paths natively (requires enrichment — see §5.3.3); can be very noisy if rules aren't scoped carefully; Linux-only |

### B.2.2 When to Reach for Auditd First

Choose auditd as your primary evidence source when your hunt hypothesis specifically requires:
- Proof that a *specific system call* occurred (execution, file write, privilege change), with kernel-level certainty.
- Attribution back to an *original login session*, even through `sudo`/`su` chains (the `auid` field).
- A tamper-evident historical record that survives even a compromised root account (with `-e 2` set).

### B.2.3 When Auditd Is the Wrong Tool

- You need to know the **current state** of the system right now (use osquery instead — auditd is an event stream, not a snapshot).
- You need **network-layer** visibility between hosts (use Zeek — auditd has no visibility once a packet leaves the local kernel).
- You're on Windows or macOS (auditd is Linux-specific; Windows Event Logs/Sysmon and macOS's Endpoint Security Framework are the respective platform analogs, both out of scope for this series' FOSS-Linux focus).

---

## B.3 Osquery — Deep Reference

### B.3.1 Capability Summary

| Attribute | Detail |
|---|---|
| **What it fundamentally is** | An OS instrumentation framework that exposes system state as virtual SQL tables |
| **Granularity** | OS-state snapshot level — process lists, socket tables, file metadata, package inventories, etc. |
| **Configuration mechanism** | JSON config (`osquery.conf`) plus JSON query packs defining scheduled queries |
| **Query interface** | Full SQL (`osqueryi` for interactive/ad-hoc, `osqueryd` for scheduled/logged execution) |
| **Performance overhead** | Low for infrequent/simple queries; can spike for expensive table joins run too frequently — tune `interval` per query based on data volatility (§2.4.3) |
| **Where we used it in this series** | Part 2 (`hunt-pack.json` — six scheduled queries); Part 3 (ad-hoc web shell ancestry self-join, suspicious cron query, kernel-thread masquerading query) |
| **Key strength** | SQL familiarity dramatically lowers the learning curve versus memorizing dozens of platform-specific CLI tools; cross-platform (Linux, macOS, Windows) with a single query language |
| **Key limitation** | A snapshot-based model means short-lived processes/connections between scheduled intervals can be missed entirely — always pair with an event-based source (auditd) for anything transient |

### B.3.2 When to Reach for Osquery First

Choose osquery when your hunt hypothesis is phrased as a **"show me the current state of X"** question: "what's currently listening on unusual ports," "what SUID binaries currently exist," "what's currently in every user's crontab." Its SQL interface also makes it the fastest tool in this series for quick, ad-hoc exploratory hunting during initial hypothesis validation, before committing to a heavier orchestration or automation step.

### B.3.3 When Osquery Is the Wrong Tool

- You need guaranteed capture of a process that started and exited entirely *between* your query intervals (use auditd's continuous event stream instead).
- You need to correlate behavior across many hosts simultaneously with a purpose-built collection UI (use Velociraptor to orchestrate osquery-style logic at fleet scale).
- You need network packet/protocol-level detail beyond what `process_open_sockets` exposes (use Zeek).

---

## B.4 Zeek — Deep Reference

### B.4.1 Capability Summary

| Attribute | Detail |
|---|---|
| **What it fundamentally is** | A passive network security monitor that parses raw packets into structured, protocol-aware logs |
| **Granularity** | Per-connection and per-protocol-transaction level (one line per connection, one per DNS query, one per SSH handshake, etc.) |
| **Configuration mechanism** | `node.cfg` (deployment topology), `networks.cfg` (local/remote network definitions), plus an extensible scripting language for custom analyzers |
| **Query interface** | No built-in query language — logs are plain TSV/JSON, queried via `zeek-cut`, `awk`, Python, or ingested into a SIEM/OpenSearch (as in Part 5) |
| **Performance overhead** | Scales with network throughput and enabled protocol analyzers; CPU-bound at high traffic volumes — the most resource-intensive tool in this series under real load |
| **Where we used it in this series** | Part 2 (installation, `conn.log`/`ssh.log`/`dns.log` verification); Part 4 (bastion-bypass hunt, rare pairing baseline, DNS beaconing analysis, session volume analysis); Part 5 (Logstash ingestion, Sigma `network_connection` rules) |
| **Key strength** | Protocol-aware parsing (distinguishes `service=ssh` from a literal port-22 match) makes it resilient to attackers running services on non-standard ports; extremely information-dense, compact logs compared to raw packet captures |
| **Key limitation** | Zero visibility into encrypted payload content (by design — it's metadata-focused); requires correct placement (SPAN/mirror port or inline tap) to see traffic it isn't itself a party to |

### B.4.2 When to Reach for Zeek First

Choose Zeek whenever your hunt hypothesis involves a relationship **between two or more hosts**, or involves protocol-level behavior (DNS query patterns, TLS certificate details, HTTP header anomalies) that no single endpoint's local logs could reveal in isolation. Recall §4.1.1's core lesson: lateral movement is fundamentally invisible to any one host's endpoint telemetry — only the network's view exposes the pattern.

### B.4.3 When Zeek Is the Wrong Tool

- You need to know exactly *which process* on a host originated a connection (Zeek sees the network flow, not the local process — pair with osquery's `process_open_sockets` table, as we did in Part 2's query pack, for that correlation).
- You need pre-built, signature-based alerting out of the box (Zeek's strength is flexible scripting and rich logging, not a pre-packaged signature ruleset — that's Suricata's niche, see below).
- Your network architecture doesn't provide a tap/mirror point for Zeek to observe the relevant traffic — no amount of clever querying compensates for a sensor that was never able to see the packets in the first place.

---

## B.5 Suricata — Deep Reference

> **Blockquote — A Note on Scope:** Suricata was introduced in Part 5's comparison table (§5.2.3) but not built hands-on in this series' lab exercises, since Zeek already served our network-metadata needs for Parts 2 and 4. It is included here in full because it is a core member of the FOSS network security stack, and any serious hunting program should understand where it fits alongside Zeek.

### B.5.1 Capability Summary

| Attribute | Detail |
|---|---|
| **What it fundamentally is** | A network intrusion detection and prevention system (IDS/IPS) combining rule-based signature matching with protocol anomaly detection |
| **Granularity** | Per-packet and per-flow, evaluated against a loaded ruleset (commonly Emerging Threats Open rules, or custom rules) |
| **Configuration mechanism** | `suricata.yaml` (main config), plus `.rules` files defining signatures in Suricata's own rule syntax |
| **Query interface** | EVE JSON output — a unified, structured event log ingestible by any JSON-aware log pipeline (including our Part 5 Logstash/OpenSearch stack) |
| **Performance overhead** | Similar to Zeek — scales with traffic volume and ruleset size; supports multi-threading for higher-throughput deployments |
| **Where it fits in this series** | Not deployed hands-on, but complementary to Zeek — see §B.5.2 |
| **Key strength** | Purpose-built for signature-based alerting ("this exact byte pattern/exploit signature was seen") — something Zeek does not natively provide without custom scripting |
| **Key limitation** | Signature-based detection inherently sits lower on the Pyramid of Pain (§1.2) than Zeek's behavioral/metadata approach — signatures are trivially bypassed by minor payload changes, though Suricata's protocol-anomaly features partially offset this |

### B.5.2 Zeek vs. Suricata — A Direct Comparison

A common point of confusion for beginners: "don't Zeek and Suricata do the same thing?" They're complementary, not redundant, and many mature FOSS network security stacks run **both simultaneously** off the same network tap:

| Aspect | Zeek | Suricata |
|---|---|---|
| **Primary output** | Rich, structured *metadata* about every connection/transaction | *Alerts* when a specific signature or anomaly matches |
| **Best for** | Hunting (open-ended, exploratory analysis of "what happened") | Alerting (closed-ended, "did this known-bad pattern occur") |
| **Pyramid of Pain position** | Naturally supports top-of-pyramid behavioral hunting (our Part 4 approach) | Naturally supports bottom/middle-of-pyramid signature matching, unless anomaly-based rules are emphasized |
| **Extensibility model** | Turing-complete scripting language for custom analyzers | Declarative rule syntax, less flexible for novel custom logic |
| **Typical role in this series' architecture** | The evidence source for Part 4's hunts | Would serve as an additional automated alerting layer, complementary to our Part 5 Sigma/OpenSearch monitors |

> **Blockquote — Conceptual Warning:** Do not treat Suricata as a "replacement" for the manual hunting workflow this series taught. A Suricata alert firing tells you a known pattern matched — valuable, but it's still fundamentally the "Guard A" reactive alerting model from §1.1. Zeek's rich metadata (and the manual hunting discipline built around it in Part 4) is what lets you find the adversary behaviors *no signature was ever written for* — Guard B's proactive walk down the hallway.

---

## B.6 Velociraptor — Deep Reference

### B.6.1 Capability Summary

| Attribute | Detail |
|---|---|
| **What it fundamentally is** | An open-source Digital Forensics and Incident Response (DFIR) orchestration platform for fleet-wide artifact collection and hunting |
| **Granularity** | Whatever its underlying VQL query targets — process state, filesystem artifacts, registry (on Windows), memory, and more |
| **Configuration mechanism** | Server config (`server.config.yaml`) and client config (`client.config.yaml`), plus reusable YAML **Artifact** definitions |
| **Query interface** | VQL (Velociraptor Query Language) — SQL-like syntax extended with forensic-specific plugins (`pslist()`, `GetParent()`, file-parsing functions, YARA scanning, etc.) |
| **Performance overhead** | Client agent overhead is minimal at idle; collection/hunt overhead scales with the complexity and fleet-size of a dispatched hunt |
| **Where we used it in this series** | Part 3 (server/client deployment, `Custom.Linux.Hunt.WebShellAncestry` and `Custom.Linux.Hunt.SuspiciousCron` artifacts) |
| **Key strength** | Turns a single-host query into a fleet-wide operation with one dispatch, via a proper web GUI, without needing to SSH into every machine individually |
| **Key limitation** | Adds an additional piece of infrastructure (server + enrolled clients) to deploy and maintain versus "just running osquery locally"; VQL has its own learning curve distinct from plain SQL |

### B.6.2 When to Reach for Velociraptor First

Choose Velociraptor when your hunt hypothesis needs to be tested **across many endpoints simultaneously**, not just the one lab machine we used throughout this series, or when you need Velociraptor's specific forensic capabilities (timeline reconstruction, file carving, memory analysis, YARA scanning) that go beyond what plain osquery or auditd expose.

### B.6.3 When Velociraptor Is the Wrong Tool

- You're validating a hypothesis on a single lab machine during initial hunt development (plain `osqueryi` or `ausearch` is faster and simpler — reserve Velociraptor for scaling a *validated* hunt across a fleet, exactly as Part 3 demonstrated by validating the web shell query manually first, then wrapping it as a reusable Artifact).
- You need permanent, always-on detection rather than on-demand collection (that's Sigma's job, deployed via Part 5's OpenSearch monitors — Velociraptor is fundamentally a pull/dispatch model, not a continuous background alerting engine, though its "Hunt" scheduling feature can approximate recurring collection).

---

## B.7 Sigma — Deep Reference

### B.7.1 Capability Summary

| Attribute | Detail |
|---|---|
| **What it fundamentally is** | A YAML-based, vendor-agnostic format for expressing log-based detection logic, paired with the pySigma/sigma-cli conversion toolchain |
| **Granularity** | Whatever the underlying `logsource` category represents (`process_creation`, `network_connection`, etc.) — Sigma itself holds no telemetry, it only describes match logic against telemetry that already exists elsewhere |
| **Configuration mechanism** | Individual rule YAML files, plus **pipelines** that map Sigma's generic field vocabulary onto a specific backend's real schema |
| **Query interface** | N/A directly — `sigma convert` transforms a rule into a backend-native query (OpenSearch DSL, Splunk SPL, etc.), which is then executed by that backend |
| **Performance overhead** | Negligible — Sigma itself is a build-time/conversion-time tool; runtime performance is entirely determined by the backend executing the converted query |
| **Where we used it in this series** | Part 5 (both rules — `webshell-process-ancestry.yml` and `ssh-bastion-bypass.yml` — plus custom pipelines and a CI validation pipeline) |
| **Key strength** | Complete decoupling of detection *logic* from detection *infrastructure* — the exact same rule file could be pointed at a different backend in the future with zero logic rewrites, only a pipeline/backend swap |
| **Key limitation** | Entirely dependent on an accurate pipeline mapping to your real schema (§5.2.4's "silent failure" warning) — a rule is only as good as the field mapping and ingestion pipeline underneath it; newer features like correlation rules have inconsistent backend support (§5.7.4) |

### B.7.2 When to Reach for Sigma First

You should never reach for Sigma *first* — by design, per this series' entire methodology (§5.1.2). Sigma is always the **last** step, applied only after a hunt hypothesis has been manually validated against real data using the appropriate telemetry-layer tool (auditd, osquery, Zeek) and, where fleet-scale validation is needed, Velociraptor. Reaching for Sigma first means writing detection logic on assumption rather than evidence — precisely the anti-pattern this series warned against.

### B.7.3 When Sigma Is the Wrong Tool

- For genuinely one-off, exploratory hunting during initial hypothesis testing (the ad-hoc `awk`/Python scripts and `osqueryi`/VQL queries from Parts 3–4 are the right tool at that stage — Sigma is for what you've *already proven* deserves permanence).
- For byte-pattern file/memory scanning (that's YARA's specific niche, not Sigma's — see §5.2.3's comparison table).

---

## B.8 Choosing the Right Tool — A Decision Flowchart

To consolidate everything above into a single practical tool, use this flowchart the next time you're formulating a new hunt hypothesis (Part 1, Step 3 — Identify Required Telemetry):

```
START: "What does my hunt hypothesis's Evidence (ABLE) actually require?"
   │
   ├─► "The CURRENT state of one or more hosts" ──────────► OSQUERY
   │     (e.g., "what's listening on port X right now")      (§B.3)
   │
   ├─► "A HISTORICAL record of a specific kernel-level
   │    event, with attribution" ─────────────────────────► AUDITD
   │     (e.g., "who wrote to this file, and when")            (§B.2)
   │
   ├─► "A relationship or pattern BETWEEN two or more
   │    hosts over the network" ──────────────────────────► ZEEK
   │     (e.g., "did Host A talk to Host B unexpectedly")       (§B.4)
   │
   ├─► "A known-bad signature/pattern in network traffic" ─► SURICATA
   │     (e.g., "does this match a published exploit sig")     (§B.5)
   │
   └─► "I need to run ANY of the above across MANY hosts
        at once, from a central console" ─────────────────► VELOCIRAPTOR
              (§B.6)

THEN, once the hunt above is manually validated and confirmed valuable:

   "I never want to manually re-run this again" ───────────► SIGMA
         (convert the validated logic into a permanent,        (§B.7)
          automated, portable detection rule)
```

---

## B.9 Cross-Tool Data Correlation Reference

A hunter's real power comes not from any single tool, but from correlating outputs *across* tools for the same incident. This table shows, concretely, which field in one tool corresponds to which field in another — the exact correlation logic this series relied on repeatedly (e.g., Part 3's dual VQL/osquery web shell validation, Part 5's `auid`-to-process correlation):

| Concept | Auditd Field | Osquery Field/Table | Zeek Field | Velociraptor (VQL) |
|---|---|---|---|---|
| Process ID | `pid` | `processes.pid` | N/A (no process visibility) | `pslist().Pid` |
| Parent Process ID | `ppid` | `processes.parent` | N/A | `pslist().Ppid` |
| Executable path | `exe` | `processes.path` | N/A | `pslist().Exe` |
| Original logged-in user (survives sudo) | `auid` | Not directly exposed (must join `logged_in_users`) | N/A | Requires custom VQL join against `Artifact.Linux.Sys.Users` |
| Source/Destination IP | N/A (host-local only) | `process_open_sockets.remote_address` | `id.orig_h` / `id.resp_h` | `Artifact.Linux.Network.*` plugins |
| Listening port | N/A | `listening_ports.port` | `id.resp_p` (if connection observed) | `Artifact.Linux.Network.Netstat` |
| Cron entry | `PATH` record referencing cron file | `crontab.command` | N/A | `Artifact.Linux.Sys.Crontab()` |
| Timestamp | `msg=audit(<epoch>.<ms>:<event_id>)` | Query execution time (not event time, unless using `time` column in event-based tables) | `ts` (connection start) | Collection timestamp (server-side) |

> **Blockquote — Practical Tip:** When writing a hunt investigation report (Part 1's template, Section 7 — Findings), always try to populate your timeline table using **at least two independently-sourced fields** for the same event where possible (e.g., an auditd `PATH` record's implied timestamp *and* an osquery `crontab` snapshot's presence/absence across two consecutive 5-minute intervals). Independent corroboration across tools, using this table's field mappings, is what elevates a finding from "plausible" to "confirmed" in your Verdict section.

---

## B.10 Appendix Summary — The Complete Toolchain at a Glance

| Layer | Tool(s) | One-Sentence Summary |
|---|---|---|
| Kernel/Syscall Telemetry | Auditd | Records every security-relevant kernel request, with unbroken user attribution via `auid` |
| OS State Telemetry | Osquery | Turns "what is my OS currently doing" into a SQL question |
| Network Metadata Telemetry | Zeek | Turns raw packets into structured, protocol-aware connection logs |
| Network Signature Telemetry | Suricata | Flags known-bad patterns and protocol anomalies directly on the wire |
| Cross-Host Orchestration | Velociraptor | Dispatches any of the above styles of query across an entire fleet from one GUI |
| Permanent Detection Encoding | Sigma | Converts a manually-validated hunt into a portable, vendor-agnostic, automatically-scheduled rule |

This is the complete, six-tool, entirely-FOSS architecture this series built by hand, piece by piece, from Part 2 through Part 5 — and the exact reference table to return to the next time you're deciding where a new hunt hypothesis should begin.
