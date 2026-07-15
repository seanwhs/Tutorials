# Mastering SIEM Detection Rules — Part 0: Introduction & Lab Setup

## Why This Part Exists

Before Part 1 gets into decoding logs, we need a Part 0 — the "orientation day" of this series. Think of starting a new job: before anyone hands you a task, you get a building tour, a badge, and an explanation of what the company actually does. That's what this installment is. No detection logic yet — just the map, the vocabulary, and the toolbox everyone in the rest of the series will assume you already have.

By the end of Part 0 you will have:

1. A clear mental model of *why* most detection rules are bad, and what "good" looks like.
2. Fluency in the vocabulary used for the rest of the series (SIEM, false positive, IOC vs. TTP, MITRE ATT&CK).
3. A working local project structure and toolchain shared by every future part.
4. A running local sandbox (via Docker) so you can test real queries instead of just reading about them.

---

## Step 0.1 — The Problem: Why "Alerts" Aren't the Same as "Detections"

**The Target:** No code yet — a conceptual foundation everything else depends on.

**The Concept:**

Imagine a smoke detector in your kitchen. A **cheap smoke detector** screams the instant it senses *any* particles in the air — burnt toast, steam from boiling pasta, an actual fire. It has one condition: "particles detected → alarm." It's technically working, but everyone in the house has learned to ignore it, because it's usually toast. Eventually, nobody reacts fast enough when there's a *real* fire. This is called **alert fatigue** — when analysts (the people watching security alerts) become numb to alarms because most of them are false alarms, called **false positives**.

A **good smoke detector system** instead correlates multiple signals: smoke density rising steadily (not a quick puff), combined with a heat sensor crossing a threshold, combined with *no* stove-usage signal from the kitchen. That's a **stateful, high-fidelity detection** — it holds "state" (what happened over the last few minutes) and combines multiple weak signals into one strong, trustworthy signal.

This is precisely the gap this series closes:

| Term | Plain-English Definition |
|---|---|
| **SIEM** (Security Information and Event Management) | A central system that collects logs from every computer, firewall, and app in a company, and lets you search/alert on them — think of it as the security team's search engine over "everything that happened." |
| **Detection Rule** | A saved search/query that runs automatically and fires an alert when its condition is met — like a recipe: "if X and Y happen within Z minutes, notify someone." |
| **False Positive (FP)** | An alert that fired, but nothing bad actually happened (the burnt-toast alarm). |
| **False Negative (FN)** | The dangerous one: an attack happened, and *no* alert fired at all. |
| **True Positive (TP)** | An alert fired, and it correctly caught a real bad event. |
| **IOC** (Indicator of Compromise) | A specific, disposable clue — like a malicious IP address or file hash. Attackers change these constantly, so IOCs go stale fast. |
| **TTP** (Tactics, Techniques, and Procedures) | The attacker's *behavior pattern* — much harder for them to change than an IOC. This series focuses on detecting TTPs, not just IOCs. |
| **MITRE ATT&CK®** | A public, shared dictionary of attacker TTPs (e.g., "T1110 = Brute Force"), maintained by MITRE. Every rule in this series is labeled with the ATT&CK technique it detects, so you always know *why* the rule exists, not just *what* it matches. |

**The Implementation:** Nothing to build yet — this step is pure orientation, intentionally.

**The Verification:** Ask yourself: *"Can I explain to a non-technical friend the difference between an IOC and a TTP using the smoke-detector analogy?"* If yes, you're ready for Step 0.2.

---

## Step 0.2 — The Series Roadmap

**The Target:** Understand exactly what gets built, in what order, and why each part depends on the one before it.

**The Concept:** This series is built like a staircase, not a pile of disconnected blog posts. You can't correlate events (Part 3) if you don't know what fields exist in a log (Part 1). You can't write a portable Sigma rule (Part 4) if you don't already know the native query languages it compiles down to (Part 2).

| Part | Title | What You Physically Build | Depends On |
|---|---|---|---|
| **0** | Introduction & Lab Setup *(this part)* | Shared project folder, Python toolchain, local Docker sandbox | — |
| **1** | The Anatomy of a Log | A Python CLI (`normalize.py`) that parses raw Windows Security (4624/4625) & Sysmon logs into ECS/CIM-normalized JSON | Part 0's environment |
| **2** | Writing Your First Rules (KQL vs. SPL vs. Lucene) | A "Brute Force" (T1110) rule, written twice: Splunk SPL and Sentinel KQL | Part 1's normalized field names |
| **3** | Advanced Correlation & State | Multi-stage correlation rule (brute force → successful login), plus the full **MFA Fatigue** rule | Part 2's query syntax |
| **4** | Write Once, Run Anywhere (Sigma) | A vendor-neutral Sigma YAML rule for **PowerShell WebClient abuse**, compiled to Splunk/Sentinel/Elastic | Parts 1–3 combined |
| **Ref** | Living Reference Library | Field dictionaries, the full **Common SIEM Rules Matrix**, tuning playbooks | Referenced throughout |

Every step, in every part, will always follow the same four beats so you always know where you are:

1. **The Target** — the exact file or artifact we're producing.
2. **The Concept** — the analogy behind the logic.
3. **The Implementation** — full, runnable code (never `// todo`).
4. **The Verification** — a command or output you can check against your own screen.

**The Verification (for this step):** No code — just confirm you can name, in order, what Parts 1 through 4 each produce, and why Part 2 can't be written before Part 1.

---

## Step 0.3 — Prerequisites Checklist

**The Target:** Confirm your machine has everything the series needs before we install anything.

**The Concept:** This is the "ingredients list" you check *before* you start cooking — nothing worse than getting to step 5 of a recipe and realizing you don't have an oven.

**The Implementation:**

You need:

| Requirement | Why | How to Check |
|---|---|---|
| A terminal (macOS/Linux Terminal, or Windows Terminal/WSL) | All commands in this series are shell commands | Open it — that's the whole test |
| Python 3.9 or newer | Powers our log-normalization tooling in Part 1 | `python3 --version` |
| Docker Desktop | Runs a free local Elastic sandbox so you can test queries without paying for cloud SIEM licenses | `docker --version` |
| A free Microsoft Azure account (for Sentinel, used in Parts 2–3) | Sentinel has no fully-offline equivalent; Microsoft's free tier is sufficient | Sign up at `https://azure.microsoft.com/free/` if you don't have one — no code needed yet |
| (Optional) Splunk Free trial or Splunk Free single-instance license | Used for the SPL side of Parts 2–3 | Sign up at `https://www.splunk.com/en_us/download.html` |

Run this quick sanity check in your terminal:

```bash
python3 --version
docker --version
docker compose version
```

**The Verification:** You should see output similar to:

```
Python 3.11.4
Docker version 24.0.6, build ed223bc
Docker Compose version v2.21.0
```

If `python3` or `docker` are "command not found," install them now:
- Python: `https://www.python.org/downloads/`
- Docker Desktop: `https://www.docker.com/products/docker-desktop/`

Do not proceed to Step 0.4 until both version commands succeed — every later part assumes this works.

---

## Step 0.4 — Build the Shared Project Root & Python Toolchain

**The Target:** `siem-mastery-series/` — the root folder every future part will live inside, plus an isolated Python environment.

**The Concept:** We create one **root folder** (the "evidence locker" for the whole series) with a **virtual environment** inside it. A virtual environment is a sealed box for Python packages — so the tools we install for this series (like `pandas` or `lxml`) never collide with unrelated Python projects already on your machine. Think of it like a labeled tackle box just for this fishing trip, separate from your everyday toolbox at home.

**The Implementation:**

```bash
# Create the root directory that will hold every part of the series
mkdir siem-mastery-series
cd siem-mastery-series

# Create an isolated Python environment named ".venv"
python3 -m venv .venv

# Activate it (macOS/Linux)
source .venv/bin/activate

# Activate it instead like this on Windows PowerShell:
# .venv\Scripts\Activate.ps1
```

Once activated, your terminal prompt should now be prefixed with `(.venv)`. Every `pip install` from this point in the series installs *only* inside this sealed box.

Now create the shared dependency file. This isn't just a convenience — pinning versions here means the exact code in this series behaves identically on your machine as it did when written.

**File: `siem-mastery-series/requirements.txt`**

```text
# Used starting in Part 1 to parse Windows Event Log XML exports
lxml==5.2.2

# Used starting in Part 1 to work with structured log data as tables
pandas==2.2.2

# Used for readable, colorized CLI output across all Python tools in this series
rich==13.7.1
```

Install them:

```bash
pip install -r requirements.txt
```

**The Verification:**

```bash
python3 -c "import lxml, pandas, rich; print('All core libraries loaded successfully')"
```

Expected output:

```
All core libraries loaded successfully
```

If you see a `ModuleNotFoundError`, re-run `pip install -r requirements.txt` and confirm `(.venv)` is still showing in your prompt (if it disappeared, re-run the `source .venv/bin/activate` command — venvs deactivate when you close the terminal).

---

## Step 0.5 — Stand Up a Local SIEM Sandbox (Elastic Stack via Docker)

**The Target:** `siem-mastery-series/docker-compose.yml` — a one-command local Elasticsearch + Kibana environment.

**The Concept:** Cloud SIEMs (Sentinel, Splunk Cloud) are great, but you shouldn't need to pay for or provision cloud infrastructure just to follow a tutorial. Docker Compose lets us describe a small "mini data center" — one container running the search engine (Elasticsearch), one running the UI (Kibana) — in a single text file, then boot the whole thing with one command. Think of `docker-compose.yml` as a furniture assembly instruction sheet: it lists every piece and exactly how they connect, so anyone (including future-you) can rebuild the identical setup from scratch.

**The Implementation:**

**File: `siem-mastery-series/docker-compose.yml`**

```yaml
# This defines two services that together form a minimal local SIEM:
# - elasticsearch: stores and searches the log data (the "database + search engine")
# - kibana: the web UI used to query and visualize that data (used heavily in Part 4)
version: "3.8"

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.14.1
    container_name: siem-lab-elasticsearch
    environment:
      - discovery.type=single-node   # Tells ES it's running standalone, not in a multi-server cluster
      - xpack.security.enabled=false # Disables login auth for local learning only — NEVER do this in production
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m" # Caps memory usage so it runs comfortably on a laptop
    ports:
      - "9200:9200"   # Exposes ES's REST API to your host machine at localhost:9200
    volumes:
      - siem-lab-es-data:/usr/share/elasticsearch/data  # Persists data across container restarts
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:9200 || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 10

  kibana:
    image: docker.elastic.co/kibana/kibana:8.14.1
    container_name: siem-lab-kibana
    depends_on:
      - elasticsearch
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200  # Tells Kibana where to find its data source
    ports:
      - "5601:5601"   # Exposes the Kibana web UI at localhost:5601

volumes:
  siem-lab-es-data:   # Named volume so log data survives "docker compose down"
```

> **Security note (beginner-friendly but important):** `xpack.security.enabled=false` disables authentication. This is only acceptable because this stack runs *locally, on your own machine, for learning purposes*. A real production SIEM must always have authentication enabled — we call this out explicitly so the habit doesn't accidentally carry over into real deployments.

Start the sandbox:

```bash
docker compose up -d
```

**The Verification:**

Wait about 30–60 seconds for Elasticsearch to fully initialize, then run:

```bash
curl http://localhost:9200
```

Expected output (version numbers may vary slightly):

```json
{
  "name" : "elasticsearch",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "AbCdEfGhIjKlMnOpQrStUv",
  "version" : {
    "number" : "8.14.1",
    "build_flavor" : "default"
  },
  "tagline" : "You Know, for Search"
}
```

Then open a browser to:

```
http://localhost:5601
```

You should see the **Kibana** welcome screen load. If it instead shows a "Kibana server is not ready yet" message, wait another 30 seconds and refresh — Elasticsearch is likely still finishing startup.

To stop the sandbox later (data is preserved):

```bash
docker compose down
```

---

## Step 0.6 — Final Project Structure Checkpoint

**The Target:** Confirm the exact folder layout before Part 1 begins.

**The Concept:** A quick "packing list check" before leaving for the trip.

**The Implementation:**

Run:

```bash
find . -maxdepth 2 -not -path '*/.venv/*'
```

**The Verification:** You should see this structure:

```
.
./docker-compose.yml
./requirements.txt
./.venv
```

If this matches, your environment is fully ready. In Part 1, we will create a new subfolder, `part-1-log-anatomy/`, directly inside this same `siem-mastery-series/` root — nothing from Step 0.4–0.5 gets rebuilt, only extended.

---

# Reference Section — Part 0

*(Isolated here per the series' design principle: deep background material lives separately so the step-by-step flow above stays uninterrupted.)*

## R0.1 — Glossary of Core Terms

| Term | Definition |
|---|---|
| **SIEM** | Security Information and Event Management — centralized log collection, search, and alerting platform. |
| **SOC** | Security Operations Center — the team of analysts who monitor SIEM alerts around the clock. |
| **Detection Rule** | A saved, automated query that triggers an alert when its logic matches incoming data. |
| **Alert Fatigue** | Analyst desensitization caused by an overwhelming volume of low-quality (false positive) alerts. |
| **True/False Positive/Negative** | See table in Step 0.1 — the four possible outcomes of any detection rule firing (or not firing). |
| **IOC** | Indicator of Compromise — a specific artifact (IP, hash, domain) tied to an attack; short-lived and easy for attackers to rotate. |
| **TTP** | Tactics, Techniques, and Procedures — the durable behavioral pattern behind an attack; harder to evade detection on. |
| **MITRE ATT&CK®** | A public knowledge base of adversary TTPs, organized into Tactics (the "why," e.g. Credential Access) and Techniques (the "how," e.g. T1110 Brute Force). |
| **ECS** | Elastic Common Schema — Elastic's standardized field-naming convention (e.g., `source.ip`, `user.name`) used to normalize logs from different sources into one consistent shape. |
| **CIM** | Splunk's Common Information Model — Splunk's equivalent standardized field-naming convention. |
| **Sigma** | An open-source, YAML-based generic rule format that can be "compiled" into native SPL, KQL, or Lucene queries — covered fully in Part 4. |
| **Sliding Time Window** | A moving time boundary (e.g., "the last 15 minutes, recalculated every minute") used to correlate events that happen close together in time — covered in Part 3. |
| **State Table** | A temporary storage mechanism a detection rule uses to "remember" earlier events (like failed logins) so it can compare them against a later event (like a success). |

## R0.2 — MITRE ATT&CK Tactics at a Glance

*(You'll see these tactic names repeatedly as we tag rules throughout the series.)*

| Tactic | Plain-English Meaning |
|---|---|
| Reconnaissance | Attacker is scouting/researching the target. |
| Initial Access | Attacker is getting their first foothold (e.g., phishing, brute force). |
| Execution | Attacker is running malicious code on a system. |
| Persistence | Attacker is making sure they can get back in later. |
| Privilege Escalation | Attacker is gaining higher permissions. |
| Defense Evasion | Attacker is avoiding detection tools. |
| Credential Access | Attacker is stealing usernames/passwords/tokens. |
| Discovery | Attacker is mapping out the environment. |
| Lateral Movement | Attacker is moving to other machines in the network. |
| Collection | Attacker is gathering data of interest. |
| Command and Control (C2) | Attacker's malware is "phoning home" for instructions. |
| Exfiltration | Attacker is stealing data out of the network. |
| Impact | Attacker is causing damage (e.g., ransomware, deletion). |

## R0.3 — SIEM Platform Cheat Sheet (Preview for Part 2)

| Platform | Query Language | Local/Free Option Used in This Series |
|---|---|---|
| Splunk | SPL (Search Processing Language) | Splunk Free single-instance trial |
| Microsoft Sentinel | KQL (Kusto Query Language) | Azure free-tier account |
| Elastic Stack | Lucene / KQL / ES\|QL | Local Docker sandbox (built in Step 0.5) |

## R0.4 — Full Prerequisites Checklist (Copy This Before Part 1)

- [ ] Terminal access confirmed
- [ ] `python3 --version` returns 3.9+
- [ ] `docker --version` and `docker compose version` succeed
- [ ] `siem-mastery-series/.venv` created and activated
- [ ] `requirements.txt` installed with no errors
- [ ] `docker compose up -d` successfully starts Elasticsearch + Kibana
- [ ] `curl http://localhost:9200` returns a JSON cluster response
- [ ] `http://localhost:5601` loads the Kibana UI in a browser
- [ ] (Optional, needed by Part 2) Azure account created for Sentinel
- [ ] (Optional, needed by Part 2) Splunk Free trial account created

---

**You're fully set up.** When you're ready, say the word and we'll move into **Part 1: The Anatomy of a Log**, where we start decoding real Windows Event ID 4624/4625 and Sysmon Event ID 1 logs inside the environment you just built.
