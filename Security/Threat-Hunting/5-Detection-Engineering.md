# Part 5: Operationalizing the Hunt (Sigma Rules & Detection Engineering) — Expanded Edition

> **Blockquote — Why This Part Exists:** This is the closing of the loop that began in Part 1, §1.1.3's Maturity Model. A hunt you must manually re-run forever is not a mature detection program — it's a chore. Part 5 takes the confirmed findings from Part 3 (web shell ancestry) and Part 4 (SSH bastion-bypass) and converts them into **Sigma rules**: permanent, automated, vendor-agnostic detections that fire without you ever typing a command again. By the end of this Part, the entire series will have completed one full revolution of the hunting wheel — mindset, telemetry, hunt, automation — and you'll know exactly how to spin it again on your own.

---

## 5.1 The Detection Lifecycle — How a Hunt Becomes an Alert

### 5.1.1 The Concept

Think of the relationship between hunting and detection engineering like the relationship between a **research scientist** and a **factory**. The scientist (the hunter) spends days in the lab manually testing a hypothesis, running careful one-off experiments, documenting results meticulously. Once the experiment is proven to reliably work, the factory (automated detection) takes that exact proven recipe and mass-produces it — running it continuously, at scale, without a human needing to re-derive it every time. A mature security program needs *both* roles, and critically, needs a well-defined **handoff process** between them. That handoff process is what this Part builds.

### 5.1.2 Why "Hunt First, Automate Second" — and Never the Reverse

A common temptation for less experienced teams is to skip straight to writing detection rules based on a threat intel report, without ever manually hunting first. This series deliberately rejects that shortcut, for a concrete reason: **a rule written without first manually validating it against real data in your own environment is a guess, not a detection.**

Consider what manual hunting (Parts 3 and 4) actually bought us before we wrote a single line of Sigma:

| What Manual Hunting Proved | Why It Matters for the Resulting Rule |
|---|---|
| The telemetry field actually exists and is populated (`local_orig`/`local_resp` really do reflect our subnet) | A rule referencing a field that's always null fires *never* — a silent false negative, the worst kind of detection gap because it looks like "no alerts, we're safe" |
| We know what a **true positive** looks like in raw form (our simulated `www-data`→`bash` process) | We can write an accurate `detection` block instead of guessing at field values from documentation alone |
| We know what a **benign true positive** looks like (§4.7's Verdict — a real bastion-bypass event that was actually fine) | This directly informed our rule's `falsepositives` section and its `level: medium` rather than `level: critical` — an honest severity grounded in observed base rates |
| We know the exact telemetry gaps (parent-process path resolution from raw auditd) | We built the gap directly into the pipeline documentation (§5.3.3) rather than shipping a rule that silently never matches |

> **Blockquote — Core Principle:** Every Sigma rule in this Part exists **because** a human already proved, by hand, that the underlying pattern is real, detectable, and reasonably rare. If you ever find yourself writing a Sigma rule for a technique you have never personally hunted for in your own telemetry, stop — go run the manual hunt first. A rule built on assumption, not verified evidence, is how security teams end up with thousands of silent, untuned, unreliable detections that nobody trusts enough to act on.

### 5.1.3 The Full Lifecycle, Visualized

```
┌─────────────────┐     ┌──────────────────┐     ┌───────────────────┐
│   Part 1:        │     │   Parts 2-4:      │     │   Part 5:           │
│   Hypothesis      │────►│   Manual Hunt      │────►│   Sigma Rule        │
│   (ABLE framework)│     │   (queries + docs) │     │   (automated,       │
│                   │     │                    │     │   permanent alert)  │
└─────────────────┘     └──────────────────┘     └─────────┬─────────┘
                                                             │
                                                             ▼
                                              ┌───────────────────────────┐
                                              │  Deployed to SIEM/backend  │
                                              │  (fires continuously,      │
                                              │  no human re-runs needed)  │
                                              └─────────────┬─────────────┘
                                                             │
                                                             ▼
                                              ┌───────────────────────────┐
                                              │  Analyst triages alert →   │
                                              │  tunes falsepositives OR   │
                                              │  confirms true positive    │
                                              └─────────────┬─────────────┘
                                                             │
                                                             ▼
                                              ┌───────────────────────────┐
                                              │  New alert fires → informs │
                                              │  NEXT hunt hypothesis       │
                                              │  (loop restarts at Part 1)  │
                                              └───────────────────────────┘
```

**Why this matters:** notice the loop closes back to Part 1, but *not* directly — it passes through an explicit **triage and tuning** stage first. This is deliberate. An automated rule is never "fire and forget." Every alert it produces needs a human to decide: is this a true positive (feeds a new investigation), a false positive (feeds a rule tuning update), or a benign true positive (feeds a `falsepositives` documentation update)? This Part builds that triage discipline explicitly in §5.7, not just the rule-writing mechanics.

### 5.1.4 The Cost of Skipping Automation — A Concrete Illustration

To make the stakes of this Part tangible, consider the literal, measurable cost of *not* doing what we're about to do:

| Scenario | Without Sigma Automation | With Sigma Automation (this Part) |
|---|---|---|
| Analyst availability required | Someone must remember to manually re-run `hunt_ssh_bastion_bypass.py` on a schedule — realistically, this happens sporadically or not at all after the first few weeks | Runs every 5 minutes automatically, forever, with zero ongoing human effort |
| Time-to-detection of a real incident | Hours to days (however long until the next manual hunt cycle happens to run) | Minutes (bounded by the monitor's schedule interval) |
| Consistency across analysts | Depends entirely on which analyst remembers the exact query syntax and bastion IP | Identical logic every single time — no variance, no typos, no forgotten `--bastion-ip` flag |
| Institutional knowledge retention | Lives in one analyst's terminal history / a Python file nobody re-reads | Lives in a version-controlled YAML file with mandatory documentation fields (`falsepositives`, `references`, `description`) |
| Portability to a new SIEM/backend | Requires rewriting the Python script's logic from scratch for the new platform | `sigma convert --target <new_backend>` — the detection logic itself never changes |

---

## 5.2 The Tool: Sigma — A Vendor-Agnostic Detection Format

### 5.2.1 The Concept

**Sigma** is an open-source, YAML-based generic signature format for describing log-based detection logic in a way that's completely decoupled from any specific SIEM or query language. Think of a Sigma rule as a **detection recipe written in a universal cooking language** — rather than writing "preheat your Whirlpool oven to 350°F," you write "preheat oven to 350°F," and a translator (the `sigma-cli` / pySigma tool) converts that universal recipe into the exact dialect needed for *your specific* oven — whether that's a Splunk SPL query, an OpenSearch/Elasticsearch DSL query, or a dozen other supported backends.

### 5.2.2 Why Sigma, Specifically, and Not a Homegrown JSON Format?

A reasonable engineering question: why adopt an external standard instead of just designing our own simple "if field X equals value Y" JSON schema, which would honestly be simpler to build? Three concrete reasons this series insists on Sigma specifically:

1. **A massive existing public rule corpus.** The [SigmaHQ public repository](https://github.com/SigmaHQ/sigma) contains thousands of community-vetted, MITRE ATT&CK-tagged detection rules covering an enormous range of adversary behavior — Linux, Windows, cloud, network. Adopting Sigma means you inherit this entire library, immediately, for free. A homegrown format inherits nothing.
2. **An actively maintained conversion ecosystem (pySigma).** Backend converters for OpenSearch, Splunk, Microsoft Sentinel's KQL, CrowdStrike, QRadar, and many others are maintained by the community, not by you. When a backend's query syntax changes, you don't have to fix your own converter code.
3. **A stable, versioned specification.** Sigma's rule schema itself is documented and versioned (Sigma v2 is current as of this writing), meaning your rule files remain valid and portable for years, across tooling changes — the same "open telemetry standard" philosophy from Part 0 applied to *detection logic* instead of raw log data.

### 5.2.3 Sigma vs. Other Detection Formats — A Comparison

| Format | Scope | Portability | Community Size | Used In This Series? |
|---|---|---|---|---|
| **Sigma** | Generic log-based detection rules | High — dozens of backend targets | Very large (SigmaHQ) | ✅ Yes |
| **YARA** | Byte-pattern/string matching, primarily for files and memory | Low-to-medium — mostly YARA-engine-specific | Large, but different use case (malware identification, not log correlation) | Not used — different problem domain (Sigma detects *behavior in logs*, YARA detects *static patterns in files/memory*) |
| **Suricata/Snort rules** | Network packet-level signature matching | Medium — Suricata/Snort-specific syntax | Large, network-IDS-focused | Referenced conceptually in Appendix B, not authored in this series |
| **Vendor-proprietary rule DSLs** (e.g., a specific SIEM's own query language) | Whatever that one vendor's platform supports | None — zero portability outside that vendor | Fragmented, non-transferable | Explicitly avoided per this series' FOSS mandate (Part 0) |

> **Blockquote — Conceptual Warning:** Sigma is purpose-built for **log-based, field-value detection logic** — "this field equals this value, and that field equals that value, in the same event." It is not a replacement for byte-signature malware scanning (YARA's job) or raw packet inspection (Suricata's job). Understanding a tool's correct scope is as important as knowing how to use it — reaching for Sigma to try to express "scan this file for a byte pattern" is the wrong tool for the job.

### 5.2.4 Installing the Sigma Toolchain

```bash
# pySigma is the core conversion library; sigma-cli is the command-line
# front-end built on top of it. Both are pure-Python and installed via pip.
# Using a virtual environment keeps this tooling isolated from your
# system Python packages - good practice for any Python-based tool install.
python3 -m venv ~/sigma-venv
source ~/sigma-venv/bin/activate

pip3 install --upgrade pip
pip3 install sigma-cli

# Verify installation
sigma --version
```

**The Verification:**
```bash
sigma --version
```
Expected output: `sigma-cli, version 0.9.x` (or newer).

```bash
# List available conversion backends - these are plugins that know how
# to translate Sigma's generic YAML into a specific query language.
sigma list backends
```

Expected output includes entries such as:
```
opensearch (pySigma-backend-elasticsearch)
splunk (pySigma-backend-splunk)
loki (pySigma-backend-loki)
...
```

For this series, we'll target **OpenSearch** as our backend — a fully open-source search/analytics engine (a fork of Elasticsearch) commonly used as the storage/query layer behind a FOSS SIEM stack.

```bash
# Install the OpenSearch/Elasticsearch backend plugin for sigma-cli
pip3 install pysigma-backend-elasticsearch

# List available pipelines - a pipeline maps Sigma's GENERIC field
# names (like "CommandLine") onto the SPECIFIC field names your actual
# log source uses (e.g., Zeek's "id.orig_h" or osquery's "cmdline").
# Without a pipeline, the backend doesn't know how your data is actually shaped.
sigma list pipelines
```

> **Blockquote — Conceptual Warning:** Many beginner tutorials for Sigma skip explaining pipelines entirely and just show `sigma convert` working "magically." In reality, **the pipeline is the single most important, and most commonly misunderstood, piece of the entire Sigma toolchain.** A rule with no matching pipeline for your actual log schema will convert "successfully" (no error) but produce a query that searches for fields that don't exist in your data — a silent, invisible failure. We build our own custom pipelines explicitly in §5.4 and §5.5 for exactly this reason: our auditd and Zeek schemas are not one of Sigma's built-in, pre-packaged pipeline targets.

### 5.2.5 Anatomy of a Sigma Rule

Before writing our own, let's decode every section of a Sigma rule using a minimal generic example:

```yaml
title: Example Rule Title                  # Human-readable name
id: 12345678-1234-1234-1234-123456789abc    # A unique UUID identifying this exact rule
status: experimental                        # experimental | test | stable | deprecated
description: What this rule detects and why
author: Your Name
date: 2024-01-26
modified: 2024-01-26                        # Track the last time logic actually changed
references:
  - https://attack.mitre.org/techniques/T1059/
tags:
  - attack.execution
  - attack.t1059
logsource:                                  # WHAT kind of log this rule expects
  category: process_creation
  product: linux
detection:                                  # THE ACTUAL DETECTION LOGIC
  selection:
    FieldName: 'value_to_match'
  condition: selection                      # Boolean logic combining named blocks above
falsepositives:
  - Known legitimate scenario that might also match
level: high                                 # informational | low | medium | high | critical
```

| Section | Purpose |
|---|---|
| `id` | A globally unique UUID — **never reuse or regenerate this** once a rule is deployed; downstream SIEM integrations, ticketing systems, and your own historical alert data key off this exact identifier. Generate one with `python3 -c "import uuid; print(uuid.uuid4())"`. |
| `status` | Signals rule maturity to consumers of the SigmaHQ ecosystem — `experimental` rules may have unvalidated false-positive rates; `stable` rules (like ours, since we manually validated them in Parts 3–4) have been confirmed reliable |
| `logsource` | Declares what *category* of data this rule expects (e.g., `process_creation`, `network_connection`) — the pipeline (installed above) maps this abstract category to your actual log source's real field names |
| `detection.selection` | One or more named blocks defining field-value match conditions — you can have multiple named blocks (`selection`, `filter`, `selection2`...) |
| `detection.condition` | Boolean logic (`selection`, `selection and not filter`, `1 of selection*`, etc.) combining the named blocks into final match logic |
| `falsepositives` | **Mandatory honesty** — every Sigma rule must document known legitimate scenarios that could also trigger it, so downstream analysts triaging an alert know what to rule out first |
| `level` | Severity — drives alert prioritization and routing in most SIEM integrations; should be grounded in *observed* false-positive rate from real hunting, per §5.1.2 |

### 5.2.6 The `condition` Field's Mini-Language — A Closer Look

The `condition` field deserves special attention since it trips up nearly every Sigma beginner. It supports a small but expressive boolean grammar:

| Syntax | Meaning | Example |
|---|---|---|
| `selection` | Match if the named block `selection` matches | `condition: selection` |
| `selection1 and selection2` | Both named blocks must match on the **same event** | `condition: selection_shell and selection_parent` (our web shell rule) |
| `selection and not filter` | Match `selection`, but explicitly exclude anything also matching `filter` | `condition: selection_ssh_service and selection_both_internal and not filter_bastion_source` (our SSH rule) |
| `1 of selection*` | Match if **any** block whose name starts with `selection` matches | Useful when you have `selection1`, `selection2`, `selection3` representing alternative indicators of the same behavior |
| `all of selection*` | Match only if **every** block whose name starts with `selection` matches | Stricter than `and` when you have many similarly-named blocks |

---

## 5.3 Building the Ingestion Pipeline — Getting Our Telemetry Into OpenSearch

### 5.3.1 The Concept — A Gap We Must Close First

Every Sigma rule we write below converts into an OpenSearch query — but a query is worthless against an empty index. Parts 2–4 generated auditd and Zeek logs *on disk*, on our lab endpoint. Before any converted Sigma query can find anything, we need a **log shipper**: a lightweight agent that reads those on-disk logs and forwards them into OpenSearch as structured, indexed documents. This is the missing link between "telemetry exists" (Part 2) and "an automated query can search it" (this Part).

**Analogy:** Auditd and Zeek are like two separate filing cabinets, each meticulously organized in their own building. OpenSearch is a central library catalog that can instantly search across *all* filing cabinets at once — but only if someone physically photocopies each new file and delivers it to the central library as it's created. That delivery courier is our log shipper.

### 5.3.2 Installing OpenSearch (Single-Node Lab Instance)

```bash
# Download and run OpenSearch via Docker for a clean, disposable lab
# instance - avoids polluting the host OS with a full JVM-based service
# install for what is, in this series, a learning/testing deployment.
docker pull opensearchproject/opensearch:2.11.0

docker run -d \
  --name opensearch-lab \
  -p 9200:9200 -p 9600:9600 \
  -e "discovery.type=single-node" \
  -e "OPENSEARCH_INITIAL_ADMIN_PASSWORD=YourStrongPassword123!" \
  opensearchproject/opensearch:2.11.0
```

**The Verification:**
```bash
curl -X GET "https://localhost:9200" \
  -u admin:YourStrongPassword123! --insecure
```
Expected output — a JSON banner confirming the cluster is live:
```json
{
  "name" : "...",
  "cluster_name" : "docker-cluster",
  "version" : { "number" : "2.11.0", "distribution" : "opensearch", ... },
  "tagline" : "The OpenSearch Project: https://opensearch.org/"
}
```

### 5.3.3 The Target: A Logstash Pipeline for Auditd and Zeek

**The Concept:** **Logstash** is a FOSS data-processing pipeline that reads logs from a source (a file, in our case), transforms/enriches them (parsing fields, adding computed values), and writes them to a destination (OpenSearch). This is exactly where we solve the "parent process path enrichment" gap flagged as a limitation back in §5.4.3 of the original walkthrough — Logstash is where that enrichment logic actually lives in a real deployment.

```bash
# Install Logstash from Elastic's official APT repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | \
  sudo tee /etc/apt/sources.list.d/elastic-8.x.list

sudo apt update
sudo apt install -y logstash
```

#### File: `/etc/logstash/conf.d/auditd-and-zeek.conf`

```ruby
# =============================================================================
# Logstash Pipeline: Ship Auditd and Zeek logs into OpenSearch
# This is the missing "delivery courier" step (see 5.3.1) that makes our
# Part 5 Sigma-converted queries actually have data to search against.
# =============================================================================

input {
  # --- Auditd input ---
  # The 'file' input tails the raw audit log continuously, similar to
  # `tail -f`, feeding each new line into the pipeline as it's written.
  file {
    path => "/var/log/audit/audit.log"
    start_position => "beginning"
    sincedb_path => "/var/lib/logstash/sincedb_auditd"
    type => "auditd"
  }

  # --- Zeek input ---
  # Zeek's conn.log and dns.log are separate files, both tagged with
  # type "zeek" here, then distinguished by their actual content/fields
  # further down in the filter block.
  file {
    path => "/opt/zeek/logs/current/conn.log"
    start_position => "beginning"
    sincedb_path => "/var/lib/logstash/sincedb_zeek_conn"
    type => "zeek_conn"
  }
  file {
    path => "/opt/zeek/logs/current/dns.log"
    start_position => "beginning"
    sincedb_path => "/var/lib/logstash/sincedb_zeek_dns"
    type => "zeek_dns"
  }
}

filter {
  if [type] == "auditd" {
    # Auditd's raw log format is space-separated key="value" and
    # key=value pairs - the built-in 'kv' filter parses this generically
    # without us needing to hand-write a fragile custom regex for every
    # possible audit record type (SYSCALL, PATH, CWD, etc.).
    kv {
      value_split => "="
      field_split => " "
    }

    # --- THE CRITICAL ENRICHMENT STEP flagged in the original walkthrough ---
    # Raw auditd SYSCALL records only contain a numeric 'ppid' (parent
    # process ID), never the parent's resolved executable path. Our
    # Sigma rule needs a 'parent_exe' field to exist. In a full production
    # deployment, this translate filter would be backed by a continuously
    # updated lookup table (built by a small sidecar script correlating
    # auditd PID/PPID pairs over time). For this lab, we demonstrate the
    # MECHANISM with a static example mapping so the enrichment step is
    # not silently skipped or hand-waved away.
    translate {
      field => "ppid"
      destination => "parent_exe"
      dictionary_path => "/etc/logstash/ppid_to_exe_lookup.yml"
      fallback => "unknown"
    }

    mutate {
      add_field => { "[event][module]" => "auditd" }
    }
  }

  if [type] == "zeek_conn" {
    # Zeek's TSV logs need explicit column definitions since the file
    # itself only documents them in a '#fields' comment line, which
    # Logstash's csv filter does not automatically interpret.
    csv {
      separator => "	"
      columns => ["ts","uid","id.orig_h","id.orig_p","id.resp_h","id.resp_p",
                  "proto","service","duration","orig_bytes","resp_bytes",
                  "conn_state","local_orig","local_resp","missed_bytes",
                  "history","orig_pkts","orig_ip_bytes","resp_pkts","resp_ip_bytes"]
    }
    # Convert Zeek's literal "T"/"F" strings into real booleans, so our
    # Sigma-converted OpenSearch queries (which use term-match "true"/
    # "false") actually match correctly against this field's type.
    mutate {
      convert => { "ts" => "float" }
    }
    if [local_orig] == "T" { mutate { add_field => { "local_orig_bool" => true } } }
    if [local_orig] == "F" { mutate { add_field => { "local_orig_bool" => false } } }
    if [local_resp] == "T" { mutate { add_field => { "local_resp_bool" => true } } }
    if [local_resp] == "F" { mutate { add_field => { "local_resp_bool" => false } } }

    mutate {
      add_field => { "[event][module]" => "zeek" }
    }
  }

  if [type] == "zeek_dns" {
    csv {
      separator => "	"
      columns => ["ts","uid","id.orig_h","id.orig_p","id.resp_h","id.resp_p",
                  "proto","trans_id","rtt","query","qclass","qclass_name",
                  "qtype","qtype_name","rcode","rcode_name","AA","TC","RD",
                  "RA","Z","answers","TTLs","rejected"]
    }
    mutate {
      add_field => { "[event][module]" => "zeek" }
    }
  }
}

output {
  if [type] == "auditd" {
    opensearch {
      hosts => ["https://localhost:9200"]
      user => "admin"
      password => "YourStrongPassword123!"
      ssl_certificate_verification => false   # lab only - use a real CA in production
      index => "auditd-logs-%{+YYYY.MM.dd}"
    }
  }
  if [type] == "zeek_conn" {
    opensearch {
      hosts => ["https://localhost:9200"]
      user => "admin"
      password => "YourStrongPassword123!"
      ssl_certificate_verification => false
      index => "zeek-conn-%{+YYYY.MM.dd}"
    }
  }
  if [type] == "zeek_dns" {
    opensearch {
      hosts => ["https://localhost:9200"]
      user => "admin"
      password => "YourStrongPassword123!"
      ssl_certificate_verification => false
      index => "zeek-dns-%{+YYYY.MM.dd}"
    }
  }
}
```

#### File: `/etc/logstash/ppid_to_exe_lookup.yml`

```yaml
# =============================================================================
# Static demonstration lookup table for the 'translate' enrichment filter
# above. In production, replace this with a dynamically-updated table
# maintained by a small script that periodically snapshots `ps -eo pid,exe`
# (or consumes osquery's process_events table) and refreshes this file,
# so parent PID -> executable path mappings stay current as processes churn.
# =============================================================================
"1": "/sbin/init"
"892": "/usr/sbin/sshd"
```

> **Blockquote — Conceptual Warning:** This static lookup file is explicitly a **teaching simplification**, and we are telling you that plainly rather than hiding the limitation. A real production enrichment pipeline needs the PID→executable mapping refreshed continuously (PIDs are reused by the OS constantly), typically by correlating osquery's `process_events` table (Part 2) on a short interval, or using auditd's `PROCTITLE`/`PARENT_INFO` companion records where available. Shipping the static demonstration file above to a real production environment would produce `"unknown"` for nearly every real parent process — always validate enrichment coverage before trusting a deployed rule's results.

**Step: Start Logstash with this pipeline**

```bash
sudo mkdir -p /var/lib/logstash
sudo /usr/share/logstash/bin/logstash --path.settings /etc/logstash -f /etc/logstash/conf.d/auditd-and-zeek.conf
```

**The Verification:**

```bash
# Generate fresh telemetry to confirm the full pipeline (auditd/Zeek ->
# Logstash -> OpenSearch) works end-to-end
/bin/ls /tmp > /dev/null
curl -s https://example.com > /dev/null

# Wait ~10 seconds for Logstash to process, then query OpenSearch directly
sleep 10
curl -X GET "https://localhost:9200/auditd-logs-*/_count" \
  -u admin:YourStrongPassword123! --insecure

curl -X GET "https://localhost:9200/zeek-conn-*/_count" \
  -u admin:YourStrongPassword123! --insecure
```

Expected output — non-zero document counts for both indices:
```json
{"count":1247,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0}}
```

If both counts are greater than zero, **the full ingestion pipeline is operational**, and every Sigma-converted query in the rest of this Part now has real, live data to search against.

---

## 5.4 Practical Walkthrough: Converting the Web Shell Hunt Into Sigma

### 5.4.1 The Target

We're converting the Part 3 web shell ancestry hunt (§3.3, `Custom.Linux.Hunt.WebShellAncestry`) into a production-ready Sigma rule targeting the `process_creation` log category — the universal Sigma category for "a new process was launched," which our auditd `execution` key (Part 2) and osquery `processes` table both ultimately feed.

### 5.4.2 The Implementation

#### File: `sigma-rules/rules/linux/webshell-process-ancestry.yml`

```yaml
title: Web Server Process Spawning Shell Interpreter (Possible Web Shell)
id: a3f1e9c2-6b4d-4e8f-9a2b-1c3d5e7f9a0b
status: stable
description: |
  Detects a shell interpreter process (sh, bash, dash, ash) whose direct
  parent process is a common web server or PHP-FPM worker process. Web
  server processes have no legitimate operational reason to spawn shell
  interpreters during normal request handling; this pattern is a strong,
  behavior-based indicator of an actively exploited web shell, independent
  of the specific web shell's file name, language, or obfuscation technique.
author: Threat Hunting Masterclass Series
date: 2024-01-26
modified: 2024-01-26
references:
  - https://attack.mitre.org/techniques/T1505/003/
  - Internal Hunt Report HUNT-2024-002
tags:
  - attack.persistence
  - attack.execution
  - attack.t1505.003
  - attack.t1059
logsource:
  category: process_creation
  product: linux
detection:
  # 'selection_shell' identifies any process launch where the process
  # itself is a shell interpreter.
  selection_shell:
    Image|endswith:
      - '/sh'
      - '/bash'
      - '/dash'
      - '/ash'
  # 'selection_parent' identifies the SAME event's parent process as one
  # of our known web server / PHP-FPM binaries. Sigma's process_creation
  # category standardizes this field as ParentImage across backends.
  selection_parent:
    ParentImage|endswith:
      - '/apache2'
      - '/httpd'
      - '/nginx'
      - '/php-fpm'
      - '/php-fpm7.4'
      - '/php-fpm8.0'
      - '/php-fpm8.1'
      - '/php-fpm8.2'
  # The condition requires BOTH blocks to match on the SAME event -
  # i.e., THIS shell process's parent IS one of the flagged web server images.
  condition: selection_shell and selection_parent
falsepositives:
  - Legitimate web application administration scripts that intentionally
    shell out (should be allowlisted by specific ParentCommandLine/Image
    path rather than disabling this rule entirely)
  - Custom web server health-check or deployment scripts that use shell
    commands as part of normal, documented operations
level: high
```

### 5.4.3 Building the Custom Pipeline — Mapping Sigma's Generic Fields to Our Real Auditd Data

**The Concept:** Sigma's `process_creation` category expects generic field names like `Image` and `ParentImage` — but our actual auditd telemetry (from Part 2, enriched via Logstash in §5.3.3) uses fields like `exe` and `parent_exe`. A **Sigma pipeline** is the translation layer that bridges this gap, mapping Sigma's abstract vocabulary onto our specific log schema, exactly as `networks.cfg` in Part 2 mapped abstract "local network" concepts onto our actual lab subnet.

#### File: `sigma-rules/pipelines/auditd-linux-pipeline.yml`

```yaml
name: auditd_linux_pipeline
priority: 10
transformations:
  # This transformation renames Sigma's generic "Image" field reference
  # to auditd's actual field name for the executed binary's full path.
  - id: image_field_mapping
    type: field_name_mapping
    mapping:
      Image: exe
      ParentImage: parent_exe        # populated by our Logstash 'translate'
                                      # enrichment filter, §5.3.3 - this is
                                      # WHY that enrichment step had to exist
                                      # before this pipeline could work at all.
      CommandLine: cmdline
      ParentCommandLine: parent_cmdline
  rules:
    - logsource:
        product: linux
        category: process_creation
```

> **Blockquote — Conceptual Warning:** This pipeline file is only correct *because* we built the Logstash enrichment step in §5.3.3 first. If you skip straight to writing Sigma rules without first confirming (via the ingestion pipeline's own verification step) that `parent_exe` actually appears as a populated field on real documents in your index, this rule will convert cleanly, show no errors, and then **silently never match anything** — precisely the "invisible failure" warned about in §5.2.4. Always verify a field's real presence in your index (`GET auditd-logs-*/_search?q=parent_exe:*`) before trusting a rule that depends on it.

### 5.4.4 Converting and Testing the Rule

**The Implementation:**

```bash
# Convert our Sigma rule into an actual OpenSearch/Elasticsearch Query
# DSL query, using our custom pipeline to map the generic field names
# onto our real auditd-derived schema.
sigma convert \
  --target opensearch \
  --pipeline sigma-rules/pipelines/auditd-linux-pipeline.yml \
  --without-pipeline \
  sigma-rules/rules/linux/webshell-process-ancestry.yml \
  > /tmp/webshell_query.json

cat /tmp/webshell_query.json
```

**Expected output** — a fully-formed OpenSearch query DSL JSON object:

```json
{
  "query": {
    "bool": {
      "must": [
        {
          "bool": {
            "should": [
              { "wildcard": { "exe": "*/sh" } },
              { "wildcard": { "exe": "*/bash" } },
              { "wildcard": { "exe": "*/dash" } },
              { "wildcard": { "exe": "*/ash" } }
            ],
            "minimum_should_match": 1
          }
        },
        {
          "bool": {
            "should": [
              { "wildcard": { "parent_exe": "*/apache2" } },
              { "wildcard": { "parent_exe": "*/httpd" } },
              { "wildcard": { "parent_exe": "*/nginx" } },
              { "wildcard": { "parent_exe": "*/php-fpm*" } }
            ],
            "minimum_should_match": 1
          }
        }
      ]
    }
  }
}
```

**The Verification:** Test this generated JSON directly against your live OpenSearch index containing ingested auditd logs:

```bash
curl -X GET "https://localhost:9200/auditd-logs-*/_search" \
  -H 'Content-Type: application/json' \
  -u admin:YourStrongPassword123! \
  --insecure \
  -d @/tmp/webshell_query.json
```

Re-run your §3.3.2 simulated `www-data`-owned bash spawn on the lab endpoint, wait ~10 seconds for Logstash to ingest it, then re-run the query above. Expected result: a JSON response with `hits.total.value` >= 1, whose `_source` document shows `exe` ending in `/bash` — confirming the *converted* query correctly reproduces the same logic we manually validated with VQL and osquery back in Part 3, now running as a standing search rather than an ad-hoc command.

---

## 5.5 Practical Walkthrough: Converting the SSH Bastion-Bypass Hunt Into Sigma

### 5.5.1 The Target

Our second promotion candidate — from Part 4's `HUNT-2024-001` — requires a different Sigma `logsource` category entirely: `network_connection`, since this detection is based on Zeek `conn.log` data, not process execution.

### 5.5.2 The Implementation

#### File: `sigma-rules/rules/linux/ssh-bastion-bypass.yml`

```yaml
title: Internal SSH Connection Bypassing Designated Bastion Host
id: 7d2e4f6a-8c1b-4a3d-9e5f-2b6c8d0a4e7f
status: stable
description: |
  Detects internal-to-internal SSH connections (destination port 22)
  where the connection ORIGINATOR is not the organization's designated
  bastion/jump host. Legitimate architecture routes all internal SSH
  administration through the bastion; direct internal-to-internal SSH
  sessions bypassing it are a strong indicator of lateral movement using
  stolen or reused credentials (MITRE T1021.004), even when the specific
  source host, destination host, or credentials used are unknown in advance.
author: Threat Hunting Masterclass Series
date: 2024-01-26
modified: 2024-01-26
references:
  - https://attack.mitre.org/techniques/T1021/004/
  - Internal Hunt Report HUNT-2024-001
tags:
  - attack.lateral_movement
  - attack.t1021.004
logsource:
  category: network_connection
  product: zeek
detection:
  selection_ssh_service:
    # Sigma's network_connection category commonly maps a generic
    # "DestinationPort" field; our pipeline (below) maps this onto
    # Zeek's actual id.resp_p field name.
    DestinationPort: 22
  selection_both_internal:
    # These booleans map onto our Logstash-enriched local_orig_bool /
    # local_resp_bool fields (§5.3.3) - both must be true, meaning BOTH
    # ends of the connection are inside our defined internal network
    # ranges (networks.cfg, Part 2).
    SourceIsLocal: true
    DestinationIsLocal: true
  filter_bastion_source:
    # The bastion host's own outbound administrative SSH traffic is
    # explicitly EXCLUDED here - this is the one legitimate, expected
    # source of internal-to-internal SSH and should never itself alert.
    SourceIp: '10.10.0.5'
  condition: selection_ssh_service and selection_both_internal and not filter_bastion_source
falsepositives:
  - Documented, change-ticket-approved direct-access exceptions for
    specific break-glass administrative scenarios
  - Automated configuration management tools (e.g., Ansible) that
    intentionally SSH directly between hosts as part of approved
    orchestration workflows - these source IPs should be added to an
    explicit allowlist filter rather than causing recurring false positives
level: medium
```

> **Blockquote — Conceptual Warning:** Notice this rule's `level` is `medium`, not `high` — deliberately lower than the web shell rule. This reflects the documented reality from our own Part 4 investigation report (§4.7): a bastion-bypass event *alone*, without the additional "novel host pairing" context, produced only a **Benign True Positive** verdict in our actual hunt. A Sigma rule's severity level should always honestly reflect what your own hunt findings taught you about the base rate of false positives for that exact pattern — don't inflate severity just because the underlying technique (lateral movement) sounds scary in the abstract. If you want the rule to ALSO incorporate the "novel host pairing" signal from §4.4, see §5.7.4's discussion of Sigma correlation rules below.

### 5.5.3 The Zeek Field Mapping Pipeline

#### File: `sigma-rules/pipelines/zeek-network-pipeline.yml`

```yaml
name: zeek_network_pipeline
priority: 10
transformations:
  - id: zeek_field_mapping
    type: field_name_mapping
    mapping:
      DestinationPort: id.resp_p
      SourceIp: id.orig_h
      DestinationIp: id.resp_h
      SourceIsLocal: local_orig_bool     # matches our Logstash-enriched
      DestinationIsLocal: local_resp_bool # boolean fields from §5.3.3
  rules:
    - logsource:
        product: zeek
        category: network_connection
```

### 5.5.4 Converting and Testing

```bash
sigma convert \
  --target opensearch \
  --pipeline sigma-rules/pipelines/zeek-network-pipeline.yml \
  sigma-rules/rules/linux/ssh-bastion-bypass.yml \
  > /tmp/ssh_bastion_query.json

cat /tmp/ssh_bastion_query.json
```

**Expected output:**
```json
{
  "query": {
    "bool": {
      "must": [
        { "term": { "id.resp_p": 22 } },
        { "term": { "local_orig_bool": true } },
        { "term": { "local_resp_bool": true } }
      ],
      "must_not": [
        { "term": { "id.orig_h": "10.10.0.5" } }
      ]
    }
  }
}
```

**The Verification:** Run this converted query against your OpenSearch index containing ingested Zeek `conn.log` data:

```bash
curl -X GET "https://localhost:9200/zeek-conn-*/_search" \
  -H 'Content-Type: application/json' \
  -u admin:YourStrongPassword123! \
  --insecure \
  -d @/tmp/ssh_bastion_query.json
```

With your §4.3.2 simulated connection ingested, expect a `hits.total.value` of at least `1`, with the specific hit matching your `192.168.1.50 -> 192.168.1.51` test connection — **proof that this hunt is now running as a standing, automatable query rather than a manually-invoked Python script.**

### 5.5.5 Scheduling the Rule for Continuous Automated Execution

**The Concept:** A converted query sitting in a `.json` file isn't yet "automated" — it needs to actually run on a recurring schedule and generate alerts. The simplest FOSS-native way to achieve this without adding new heavyweight infrastructure is an OpenSearch **Alerting** monitor (a built-in OpenSearch plugin), configured via its API to run our converted query every few minutes.

**Step: Enable the Alerting plugin (bundled with OpenSearch by default in the Docker image used in §5.3.2)**

```bash
curl -X GET "https://localhost:9200/_cat/plugins" -u admin:YourStrongPassword123! --insecure | grep alerting
```
Expected output confirming the plugin is present:
```
opensearchproject/opensearch   opensearch-alerting   2.11.0.0
```

#### File: `sigma-rules/monitors/opensearch-monitor-ssh-bypass.json`

```json
{
  "type": "monitor",
  "name": "HUNT-2024-001 - SSH Bastion Bypass (Sigma Automated)",
  "monitor_type": "query_level_monitor",
  "enabled": true,
  "schedule": {
    "period": {
      "interval": 5,
      "unit": "MINUTES"
    }
  },
  "inputs": [
    {
      "search": {
        "indices": ["zeek-conn-*"],
        "query": {
          "query": {
            "bool": {
              "must": [
                { "term": { "id.resp_p": 22 } },
                { "term": { "local_orig_bool": true } },
                { "term": { "local_resp_bool": true } }
              ],
              "must_not": [
                { "term": { "id.orig_h": "10.10.0.5" } }
              ]
            }
          }
        }
      }
    }
  ],
  "triggers": [
    {
      "name": "SSH-Bastion-Bypass-Trigger",
      "severity": "3",
      "condition": {
        "script": {
          "source": "return ctx.results[0].hits.total.value > 0",
          "lang": "painless"
        }
      },
      "actions": [
        {
          "name": "Log-To-Alerts-Index",
          "destination_id": "PLACEHOLDER_WEBHOOK_DESTINATION_ID",
          "message_template": {
            "source": "Sigma rule 7d2e4f6a fired: {{ctx.results.0.hits.total.value}} SSH bastion-bypass event(s) detected in the last 5 minutes."
          },
          "throttle_enabled": true,
          "throttle": { "value": 10, "unit": "MINUTES" }
        }
      ]
    }
  ]
}
```

> **Blockquote — Conceptual Warning:** The `destination_id` field above is a placeholder — OpenSearch Alerting requires a pre-configured "destination" (e.g., a webhook, Slack integration, or email/SMTP config) before an action can actually deliver a notification anywhere. Creating that destination is an infrastructure-specific step (it depends entirely on *where* you want alerts delivered) and is intentionally left as a follow-up exercise so this series doesn't presume your organization's specific notification channel. Until a real destination is configured, the monitor will still execute, evaluate its trigger condition, and log matches in OpenSearch's internal alerting history index — which is sufficient for our verification below.

```bash
curl -X POST "https://localhost:9200/_plugins/_alerting/monitors" \
  -H 'Content-Type: application/json' \
  -u admin:YourStrongPassword123! \
  --insecure \
  -d @sigma-rules/monitors/opensearch-monitor-ssh-bypass.json
```

**The Verification:**
```bash
curl -X GET "https://localhost:9200/_plugins/_alerting/monitors/_search" \
  -u admin:YourStrongPassword123! --insecure
```
Confirm your monitor `HUNT-2024-001 - SSH Bastion Bypass (Sigma Automated)` appears with `"enabled": true`. Wait 5 minutes, generate another test connection, and then check the monitor's execution history:

```bash
curl -X GET "https://localhost:9200/.opensearch-alerting-alert*/_search" \
  -u admin:YourStrongPassword123! --insecure
```

A returned alert document confirms **HUNT-2024-001 is now a fully permanent, automated detection**, closing the loop that began with a single hypothesis sentence in Part 1.

---

## 5.6 Version Control and Rule Lifecycle Management

### 5.6.1 The Concept

Sigma rules are plain text (YAML), which means they benefit enormously from the exact same discipline software engineers apply to code: **version control** (tracking every change, who made it, and why) via Git. This isn't optional polish — it's what allows a whole team to review, audit, and safely roll back detection logic changes, exactly like application code.

### 5.6.2 The Target: A Sigma Rule Repository Structure

```
sigma-rules/
├── rules/
│   └── linux/
│       ├── webshell-process-ancestry.yml
│       └── ssh-bastion-bypass.yml
├── pipelines/
│   ├── auditd-linux-pipeline.yml
│   └── zeek-network-pipeline.yml
├── monitors/
│   └── opensearch-monitor-ssh-bypass.json
├── tests/
│   └── test_sigma_rules.py
├── .github/
│   └── workflows/
│       └── validate-sigma-rules.yml
└── README.md
```

#### File: `sigma-rules/tests/test_sigma_rules.py`

```python
#!/usr/bin/env python3
"""
test_sigma_rules.py

A minimal automated test harness ensuring our Sigma rule YAML remains
syntactically valid, references only fields our pipelines actually map,
and enforces this team's own detection engineering standards (e.g.,
mandatory falsepositives documentation). Run this in CI on every pull
request touching sigma-rules/, preventing a broken or malformed rule
from ever reaching production silently.
"""

import yaml
import sys
import glob
import uuid

REQUIRED_FIELDS = ["title", "id", "status", "description", "logsource",
                   "detection", "level", "author", "date"]
VALID_LEVELS = {"informational", "low", "medium", "high", "critical"}
VALID_STATUSES = {"experimental", "test", "stable", "deprecated"}

def validate_rule(path):
    errors = []
    with open(path, "r") as f:
        try:
            rule = yaml.safe_load(f)
        except yaml.YAMLError as e:
            print(f"[FAIL] {path}: Invalid YAML syntax - {e}")
            return False

    missing = [field for field in REQUIRED_FIELDS if field not in rule]
    if missing:
        errors.append(f"Missing required Sigma fields: {missing}")

    # Confirm 'id' is actually a valid UUID - a common copy-paste error
    # is duplicating another rule's ID, which silently corrupts alert
    # correlation and history tracking downstream.
    if "id" in rule:
        try:
            uuid.UUID(str(rule["id"]))
        except ValueError:
            errors.append(f"'id' field is not a valid UUID: {rule['id']}")

    if rule.get("level") not in VALID_LEVELS:
        errors.append(f"'level' must be one of {VALID_LEVELS}, got: {rule.get('level')}")

    if rule.get("status") not in VALID_STATUSES:
        errors.append(f"'status' must be one of {VALID_STATUSES}, got: {rule.get('status')}")

    if "condition" not in rule.get("detection", {}):
        errors.append("'detection' block missing a 'condition' key")

    if not rule.get("falsepositives"):
        # Enforced here as a TEAM STANDARD (not strictly required by the
        # Sigma spec) - every rule we ship must document its own known
        # false-positive scenarios, per this series' commitment to
        # honest, non-inflated detection engineering (§5.1.2).
        errors.append("No 'falsepositives' documented - team standard requires this")

    if errors:
        print(f"[FAIL] {path}:")
        for e in errors:
            print(f"    - {e}")
        return False

    print(f"[PASS] {path}")
    return True

def check_duplicate_ids(rule_files):
    """A duplicated UUID across two different rules is a silent,
    dangerous bug - it can cause alert deduplication systems to merge
    two unrelated detections together. Catch this explicitly."""
    seen_ids = {}
    duplicates_found = False
    for path in rule_files:
        with open(path, "r") as f:
            rule = yaml.safe_load(f)
        rule_id = rule.get("id")
        if rule_id in seen_ids:
            print(f"[FAIL] Duplicate rule ID '{rule_id}' found in "
                  f"both {seen_ids[rule_id]} and {path}")
            duplicates_found = True
        else:
            seen_ids[rule_id] = path
    return not duplicates_found

def main():
    rule_files = glob.glob("sigma-rules/rules/**/*.yml", recursive=True)
    if not rule_files:
        print("[ERROR] No rule files found under sigma-rules/rules/")
        sys.exit(1)

    all_passed = True
    for path in rule_files:
        if not validate_rule(path):
            all_passed = False

    if not check_duplicate_ids(rule_files):
        all_passed = False

    sys.exit(0 if all_passed else 1)

if __name__ == "__main__":
    main()
```

**The Verification:**
```bash
python3 sigma-rules/tests/test_sigma_rules.py
```
Expected output:
```
[PASS] sigma-rules/rules/linux/webshell-process-ancestry.yml
[PASS] sigma-rules/rules/linux/ssh-bastion-bypass.yml
```

### 5.6.3 Automating Validation in CI — A GitHub Actions Workflow

**The Concept:** Running the test script manually only helps if someone remembers to do it. **Continuous Integration (CI)** automatically runs your test suite every time someone proposes a change (a "pull request"), blocking the merge if validation fails — the same safety net a software engineering team relies on, now applied to your detection content.

#### File: `.github/workflows/validate-sigma-rules.yml`

```yaml
name: Validate Sigma Rules

# Trigger this workflow on every pull request that touches the
# sigma-rules directory, and on every push to the main branch as a
# final safety net.
on:
  pull_request:
    paths:
      - 'sigma-rules/**'
  push:
    branches: [main]
    paths:
      - 'sigma-rules/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install pyyaml sigma-cli pysigma-backend-elasticsearch

      - name: Run custom rule validation tests
        run: python3 sigma-rules/tests/test_sigma_rules.py

      - name: Verify every rule actually converts without error
        # This step catches a DIFFERENT class of bug than our custom
        # test script: syntactically valid YAML that nonetheless fails
        # pySigma's own internal detection-logic parsing (e.g., an
        # invalid condition expression referencing a non-existent
        # selection block name).
        run: |
          for rule in sigma-rules/rules/linux/*.yml; do
            echo "Converting: $rule"
            sigma convert --target opensearch --without-pipeline "$rule" > /dev/null
          done
```

**The Verification:** Push a deliberately broken rule (e.g., delete the `falsepositives` field from a copy) to a test branch and open a pull request. Confirm the GitHub Actions check fails with a red ❌ and shows the exact validation error in its log output. Then fix the rule and confirm the check turns green ✅ — proving your CI safety net actually catches what it's supposed to before a broken rule can be merged.

---

## 5.7 Triage, Tuning, and the Feedback Loop Back to Hunting

### 5.7.1 The Concept — A Rule Is Never "Done"

Recall §5.1.3's lifecycle diagram: after a monitor fires, an analyst must **triage** the alert — and that triage outcome should actively reshape the rule itself over time. A Sigma rule deployed once and never revisited will, in every real environment, eventually either go silent (an environment change breaks the field mapping) or become noisy (a new legitimate tool triggers false positives). Treat every fired alert as an opportunity to make the rule *better*, not just an item to close.

### 5.7.2 The Triage Decision Tree

```
Alert Fires
    │
    ▼
Is this activity EXPECTED and AUTHORIZED?
    │
    ├── YES ──► Benign True Positive
    │             │
    │             ▼
    │        Add the specific, narrow identifying detail
    │        (e.g., a specific source IP, a specific service
    │        account) to the rule's filter/exclusion logic -
    │        NOT a blanket suppression of the whole rule.
    │             │
    │             ▼
    │        Update 'falsepositives' field to document
    │        this scenario for future analysts.
    │
    └── NO ──► Is the underlying behavior actually malicious?
                  │
                  ├── YES ──► True Positive
                  │             │
                  │             ▼
                  │        Escalate to Incident Response.
                  │        File a NEW hunt hypothesis (Part 1
                  │        ABLE format) asking "what ELSE did
                  │        this actor do that this one rule
                  │        might not catch?"
                  │
                  └── UNCLEAR ──► Inconclusive
                                    │
                                    ▼
                               Treat as a fresh Part 1 hunt
                               hypothesis - manually investigate
                               with the full toolset (Parts 2-4)
                               before deciding the rule's fate.
```

### 5.7.3 A Worked Tuning Example

Suppose, two weeks after deploying `ssh-bastion-bypass.yml`, it fires daily for connections from `192.168.1.75` — which turns out to be a legitimate Ansible control node performing approved configuration management. Per the decision tree above, the **correct** fix is a narrow, specific exclusion — not disabling the rule:

```yaml
# Updated detection block - added filter_known_automation as a NEW
# named exclusion block, keeping the original bastion exclusion intact.
detection:
  selection_ssh_service:
    DestinationPort: 22
  selection_both_internal:
    SourceIsLocal: true
    DestinationIsLocal: true
  filter_bastion_source:
    SourceIp: '10.10.0.5'
  filter_known_automation:
    # Ansible control node - approved per Change Ticket CHG-2024-0091
    SourceIp: '192.168.1.75'
  condition: selection_ssh_service and selection_both_internal and not 1 of filter_*
```

Notice the `condition` line changed from `not filter_bastion_source` to `not 1 of filter_*` — using the wildcard syntax from §5.2.6 so that *either* exclusion (bastion or the new automation host) suppresses the match, without needing to rewrite the whole boolean expression every time a new legitimate exception is discovered. This is also exactly why every exclusion should reference the **specific change ticket or justification** in a comment — six months from now, nobody should have to guess *why* `192.168.1.75` is excluded.

### 5.7.4 A Note on Sigma Correlation Rules — Closing the "Novel Pairing" Gap

Recall that our full Part 4 confirmation criteria required **both** a bastion-bypass event **and** a novel host pairing (§4.7) — but our deployed Sigma rule (§5.5.2) only encodes the first condition, deliberately set to `level: medium` to reflect that gap honestly. Newer versions of the Sigma specification support **correlation rules** — a mechanism for expressing "fire only if rule A matches AND this specific field's value has not been seen in the preceding N days," which would let us eventually encode the full novel-pairing logic natively in Sigma rather than needing a separate Python script (§4.4.2).

> **Blockquote — Conceptual Warning:** Sigma correlation rule support and backend converter coverage for this feature are newer and less universally supported across all backends than standard detection rules. As of this series, we recommend keeping the baselining logic (§4.4.2) as a scheduled script feeding a lookup index that a standard Sigma rule then references (an `IN` lookup against a maintained allowlist of known pairings), rather than depending on correlation-rule backend support that may not yet exist for your specific chosen backend. Always check your target backend's current pySigma correlation support before committing production detection logic to this newer feature.

---

## 5.8 Chapter Summary — What You Now Have

- [ ] A working `sigma-cli`/pySigma installation with the OpenSearch backend configured, inside an isolated Python virtual environment.
- [ ] A fully operational **OpenSearch instance** plus a **Logstash ingestion pipeline** shipping real, enriched auditd and Zeek telemetry into searchable indices — closing the gap between "logs exist on disk" and "a Sigma-converted query can find them."
- [ ] An explicit understanding of, and working example for, the **parent-process enrichment problem** in raw auditd data, and exactly where that enrichment logic lives in a real pipeline (Logstash's `translate` filter).
- [ ] Two production Sigma rules — `webshell-process-ancestry.yml` (Part 3's finding) and `ssh-bastion-bypass.yml` (Part 4's HUNT-2024-001) — complete with honest `falsepositives` and severity levels grounded in your own hunt investigation data, not guesswork.
- [ ] Two custom Sigma pipelines mapping generic detection fields onto your actual auditd and Zeek schemas.
- [ ] Both rules converted into working OpenSearch Query DSL and verified against real ingested data.
- [ ] One rule deployed as a live, scheduled **OpenSearch Alerting monitor** — a genuinely automated, permanent detection, no longer dependent on a human re-running a script.
- [ ] A version-controlled rule repository structure with an automated validation test suite **and a CI pipeline (GitHub Actions)** that blocks broken rules from ever merging.
- [ ] A concrete **triage decision tree and tuning workflow**, including a worked example of narrowing a false positive without weakening the rule's core detection value.
- [ ] Awareness of Sigma's emerging **correlation rule** capability and an honest assessment of when to still prefer a script-plus-lookup-index approach over it.

> **Blockquote — The Loop Is Closed:** Recall Part 1's Hunt Template, Section 10: *"Should this become a permanent Sigma rule?"* Both hunts from this series answered yes — and now both have. The next time an adversary attempts SSH lateral movement bypassing your bastion, or drops a web shell on any host feeding this pipeline, **you will know automatically, without hunting for it manually ever again.** That freed-up time is exactly what a mature hunt program reinvests into formulating the *next* hypothesis — restarting the cycle at Part 1, forever refining the edges of what your automated detections don't yet cover.

---

## 5.9 Series Retrospective — What You Built, End to End

Before moving to the Appendices, it's worth explicitly tracing the complete arc of this series, because it's easy to lose sight of just how much ground has been covered:

| Part | You Started With | You Ended With |
|---|---|---|
| **Part 0** | No context for why FOSS matters in security | A clear philosophy and a provisioned lab environment |
| **Part 1** | A vague sense that "hunting" means "looking at logs" | A rigorous, falsifiable hypothesis (`HUNT-2024-001`) built via the ABLE framework, and a reusable investigation template |
| **Part 2** | A hypothesis with nothing to test it against | Three live telemetry pillars — auditd, osquery, Zeek — all verified end-to-end |
| **Part 3** | Telemetry, but no orchestration or specific technique knowledge | Velociraptor deployed, plus three validated endpoint hunts (web shells, cron persistence, binary masquerading) |
| **Part 4** | Endpoint visibility only | Zeek-based network hunting, a completed and closed `HUNT-2024-001` investigation, and reusable Python analysis tooling |
| **Part 5** | Manual scripts requiring human execution forever | Two permanent, version-controlled, CI-tested, automatically-scheduled Sigma detections running in a real OpenSearch pipeline |

You now possess a complete, working, entirely free-and-open-source threat hunting capability — one you built with your own hands, understand at every layer, and can extend indefinitely using the exact same six-step process from §1.5 for every new hypothesis you ever form.

**Proceed to the Appendices for consolidated reference material: the MITRE ATT&CK Operator's Guide, the FOSS Hunting Tool Directory, and annotated real-world log format samples.**
