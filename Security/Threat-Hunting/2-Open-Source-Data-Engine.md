# Part 2: The Open Source Data Engine (Osquery, Auditd, & Zeek) — Expanded Edition

> **Blockquote — Why This Part Exists:** You cannot hunt what you cannot see. Part 1 taught you *how to think*. Part 2 gives you *something to look at*. Every query in Parts 3, 4, and 5 — and the exact hypothesis you saved at the end of Part 1 — depends entirely on the telemetry pipelines we build right now. If you rush this Part, every later query will silently return empty results, and you'll wrongly blame the query instead of the missing data underneath it.

---

## 2.1 The Three Pillars of Endpoint & Network Visibility

Think of your infrastructure like a house you're trying to secure. You need three different types of sensors, because each one perceives a different "layer of reality," and an attacker leaves different evidence at each layer:

1. **Auditd** is like a **hidden microphone bolted to the doorframe** — it records every single time the door mechanism itself is touched (every **system call** — the fundamental request a running program makes to the Linux kernel, e.g., "open this file," "execute this program," "change this user ID," "connect to a network socket"). It is extremely detailed, kernel-level, and — if misconfigured — extremely noisy.
2. **Osquery** is like a **home inspector who can instantly answer any question about the house's current state**, by treating your entire operating system as if it were a SQL database — "list every running process," "show me everything in this user's crontab," "what process is listening on port 4444" — all expressed as ordinary `SELECT` statements.
3. **Zeek** is like a **security camera pointed at your driveway and street** — it doesn't care what happens inside the house, but it records every vehicle (network connection) that comes and goes, what it looked like, how long it stayed, and who it talked to.

You need all three because attackers create evidence at all three layers simultaneously, and no single layer sees everything an attacker does.

| Layer | Tool | Sees... | Doesn't See... |
|---|---|---|---|
| **Kernel / syscall** | Auditd | Every process execution, file access, and privilege change, with total fidelity | Network *content*, or the "current state" of a system at a glance — it's an event stream, not a snapshot |
| **OS state** | Osquery | The current, queryable state of processes, files, users, network sockets, kernel modules, etc. | Historical events that already ended before you queried (unless you've scheduled recurring snapshots — see §2.4) |
| **Network wire** | Zeek | Every connection's metadata: IPs, ports, duration, bytes transferred, protocol-specific details (DNS queries, SSH handshake metadata, HTTP headers) | Anything happening *inside* an encrypted payload, and nothing at all about a host's internal process state |

> **Blockquote — Conceptual Warning:** A very common beginner mistake is picking just one of these three tools and assuming it's "enough." It never is. Auditd without Zeek means you can prove a process ran, but not who it talked to over the network. Zeek without Auditd means you can prove a beacon existed, but not which specific process on the host originated it. This series deliberately builds all three, in this order, because Part 3 (endpoint hunting) leans on Auditd + Osquery, and Part 4 (network hunting) leans entirely on Zeek.

---

## 2.2 Pillar 1: Linux Auditd — System Call Auditing

### 2.2.1 The Concept

`auditd` is the userspace daemon component of the **Linux Audit Framework**, a subsystem compiled directly into the Linux kernel itself. Every time *any* process asks the kernel to do something security-relevant — open a file, execute a binary, change a user ID, load a kernel module, create a network socket — the kernel can optionally emit a record of that request. `auditd` is the background service that collects those kernel-emitted records and writes them to disk in a structured log.

**Extending the analogy:** if osquery is "asking the house a question right now" (a snapshot), auditd is "the hidden microphone that has been recording the doorframe continuously since the day it was installed" (a stream). You can't ask a microphone "what does the door currently look like" — but you *can* rewind it to the exact second someone jimmied the lock. That's the fundamental trade-off: auditd gives you **history and fidelity**, at the cost of **volume and noise**.

### 2.2.2 Why We Need Rules, Not Just the Daemon

By default, a freshly installed `auditd` records almost nothing interesting — the kernel audit subsystem only reports what it's explicitly told to watch via **audit rules**. Think of audit rules as *telling the microphone which specific rooms to actually record* — without rules, you've installed the recording equipment but pointed it at an empty closet.

Audit rules are written using a small, purpose-built syntax (managed by the `auditctl` command, or defined statically in rule files) that says things like: "watch every call to the `execve` syscall" (i.e., every time *any* program is executed on this machine) or "watch every write to `/etc/passwd`."

### 2.2.3 The Target: `/etc/audit/rules.d/hunt.rules`

We're building a single, production-ready rules file that captures the specific behaviors our Part 1 hypothesis (and Part 3's persistence hunts) will need: process execution, privilege escalation, and persistence-relevant file writes.

**The Target:** Install `auditd`, then author `/etc/audit/rules.d/hunt.rules` — a static rule file that's loaded automatically on boot and immediately via `augenrules`.

**The Concept:** Audit rules come in two flavors we'll use: **syscall rules** (watch every time a specific kernel function is called, optionally filtered by argument) and **file watch rules** (watch a specific file/directory for access, regardless of which syscall touches it). We use syscall rules for "watch every program execution" and file watches for "alert me if anyone touches the cron configuration" — because cron manipulation is one of the exact persistence techniques we'll hunt for in Part 3.

**Step 1 — Install auditd**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y auditd audispd-plugins

# RHEL/CentOS/Rocky equivalent (for reference — this series' commands target Ubuntu)
# sudo yum install -y audit audit-libs
```

**Verification (Step 1):**
```bash
sudo systemctl status auditd
```
Expected output should show `Active: active (running)`. If it shows `inactive` or `failed`, run `sudo systemctl start auditd` and re-check before proceeding.

**Step 2 — Author the production rules file**

#### File: `/etc/audit/rules.d/hunt.rules`

```bash
## =============================================================================
## Threat Hunting Masterclass - Part 2 - Production Auditd Ruleset
## Purpose: Capture execution, persistence, and privilege-escalation telemetry
## required for the hunts in Part 3 (Execution & Persistence).
## =============================================================================

## --- Buffer & Failure Mode Settings ---
## -D deletes all prior rules first, so this file is always applied cleanly
## from a known-empty state, rather than stacking on top of leftover rules.
-D

## -b sets the kernel audit backlog buffer size (in number of outstanding
## audit events waiting to be read by auditd). Raise this above the default
## (usually 64/320) because a busy host generating many syscalls per second
## can otherwise silently DROP audit events if the buffer fills up — a
## dropped event is a blind spot you won't even know exists.
-b 8192

## -f sets the "failure mode" for when the audit system itself has a
## problem (e.g., disk full). 1 = print a kernel panic-level warning but
## keep the machine running. (0 = silent, 2 = panic the whole machine —
## far too aggressive for a lab, and even for most production fleets.)
-f 1

## --- Rule 1: Monitor All Process Execution (execve) ---
## WHY: Nearly every attacker action - running a reverse shell, a
## reconnaissance command, a persistence script - ultimately results in a
## new process being executed. This is our single highest-value rule.
## -a always,exit: log this event both on syscall entry AND on exit
## (we want exit, which includes the return code / success-failure).
## -F arch=b64: only match 64-bit syscall table (avoids duplicate 32-bit
## compatibility layer noise on most modern servers).
## -S execve,execveat: watch both the classic exec syscall and its newer
## "execveat" variant (used by some loaders/interpreters).
## -k execution: tags every event this rule generates with the searchable
## key "execution", so we can later grep for exactly `key=execution`.
-a always,exit -F arch=b64 -S execve,execveat -k execution

## --- Rule 2: Monitor Privilege Escalation (setuid/setgid family) ---
## WHY: An attacker escalating from a low-privilege web shell user to root
## MUST call one of these syscalls. Legitimate use exists (sudo, su), so
## this rule alone isn't proof of compromise - but it's essential
## correlation data for Part 3's web shell hunt.
-a always,exit -F arch=b64 -S setuid,setreuid,setresuid -k priv_escalation
-a always,exit -F arch=b64 -S setgid,setregid,setresgid -k priv_escalation

## --- Rule 3: Watch Cron Configuration for Persistence ---
## WHY: Cron is one of the oldest and still most common Linux persistence
## mechanisms (MITRE T1053.003). Any WRITE to these paths is highly
## actionable - normal system operation rarely modifies these files
## outside of a scheduled maintenance window or an explicit admin action.
## -w: "watch" this exact path (file watch, not syscall watch).
## -p wa: watch for (w)rite and (a)ttribute-change access.
-w /etc/crontab -p wa -k cron_persistence
-w /etc/cron.d/ -p wa -k cron_persistence
-w /etc/cron.daily/ -p wa -k cron_persistence
-w /etc/cron.hourly/ -p wa -k cron_persistence
-w /etc/cron.weekly/ -p wa -k cron_persistence
-w /etc/cron.monthly/ -p wa -k cron_persistence
-w /var/spool/cron/ -p wa -k cron_persistence

## --- Rule 4: Watch Systemd Service Unit Files for Persistence ---
## WHY: Modern Linux persistence increasingly favors creating a malicious
## systemd service (T1543.002) over legacy cron, because it blends in
## with hundreds of legitimate unit files.
-w /etc/systemd/system/ -p wa -k systemd_persistence
-w /usr/lib/systemd/system/ -p wa -k systemd_persistence

## --- Rule 5: Watch SSH Configuration and Authorized Keys ---
## WHY: Directly relevant to our Part 1 SSH lateral-movement hypothesis.
## An attacker adding their own public key to a victim's authorized_keys
## file is one of the most common ways stolen access becomes PERSISTENT
## access, and it's a file legitimate users rarely touch after initial setup.
-w /etc/ssh/sshd_config -p wa -k ssh_config_change
-a always,exit -F dir=/root/.ssh -F perm=wa -k ssh_keys_root
-a always,exit -F dir=/home -F perm=wa -k ssh_keys_home

## --- Rule 6: Watch Shadow/Passwd for Account Manipulation ---
## WHY: New account creation or password hash changes are a classic
## persistence and privilege-escalation indicator (T1136 - Create Account).
-w /etc/passwd -p wa -k account_manipulation
-w /etc/shadow -p wa -k account_manipulation
-w /etc/sudoers -p wa -k account_manipulation
-w /etc/sudoers.d/ -p wa -k account_manipulation

## --- Rule 7: Make the Audit Configuration Itself Tamper-Evident ---
## WHY: A sophisticated attacker's first move after gaining root is often
## to disable or blind the very audit system watching them. This rule
## logs any attempt to alter audit configuration, and -e 2 (below) makes
## the running rules IMMUTABLE until next reboot - so even root cannot
## silently disable auditing without a reboot event, which is itself
## a loud, logged, suspicious action.
-w /etc/audit/ -p wa -k audit_config_change
-w /etc/audit/rules.d/ -p wa -k audit_config_change

## --- Lock the configuration (MUST be the final line in the file) ---
## -e 2 makes the running ruleset immutable until reboot. This is commented
## out for now during our LAB/LEARNING phase, because you'll want to
## iterate on rules without rebooting. Uncomment this line only once your
## ruleset is finalized for a production deployment.
# -e 2
```

> **Blockquote — Conceptual Warning:** Notice the final `-e 2` line is commented out. In a real production deployment, this line is critical — it prevents an attacker with root access from simply running `auditctl -D` to blind your entire audit trail before doing damage. We leave it disabled during this lab/learning series purely so you can iterate on the rules file without needing to reboot the VM after every change. Never ship this file to production with that line still commented out.

**Step 3 — Load the rules**

```bash
# augenrules reads every file in /etc/audit/rules.d/ and compiles them
# into the single active ruleset at /etc/audit/audit.rules, then loads it.
sudo augenrules --load

# Restart the daemon to guarantee a fully clean state
sudo systemctl restart auditd
```

**The Verification:**

```bash
# List all currently active rules - you should see every -w and -a
# line from hunt.rules echoed back, confirming the kernel accepted them.
sudo auditctl -l
```

Expected output (abbreviated):
```
-w /etc/crontab -p wa -k cron_persistence
-w /etc/cron.d -p wa -k cron_persistence
...
-a always,exit -F arch=b64 -S execve,execveat -F key=execution
```

Now generate a real event and confirm it's captured:

```bash
# Generate a trivial process execution event
/bin/ls /tmp > /dev/null

# Search the audit log for it, filtered by our "execution" key
sudo ausearch -k execution -ts recent | tail -n 20
```

You should see a raw audit record resembling:
```
type=SYSCALL msg=audit(1706300000.123:456): arch=c000003e syscall=59 success=yes exit=0 ... comm="ls" exe="/bin/ls" key="execution"
```

If you see this output, **auditd is correctly capturing execution telemetry.** If `ausearch` returns nothing, re-run Step 3 and confirm `sudo systemctl status auditd` shows `active (running)` before proceeding — everything in Part 3 depends on this working.

---

## 2.3 Interlude: Making Sense of Raw Audit Log Syntax

Raw `ausearch`/`auditd` output looks intimidating the first time you see it, but it's just space-separated `key=value` pairs. Since Part 3 will require you to read these logs fluently, let's decode one fully, right now, field by field:

```
type=SYSCALL msg=audit(1706300000.123:456): arch=c000003e syscall=59 success=yes exit=0 a0=55d1... a1=7ffd... items=2 ppid=3211 pid=3344 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="ls" exe="/bin/ls" key="execution"
```

| Field | Meaning |
|---|---|
| `type=SYSCALL` | This record describes a system call event (as opposed to `type=PATH`, `type=CWD`, etc., which are companion records for the *same* event) |
| `msg=audit(1706300000.123:456)` | Unix timestamp `1706300000.123` + a unique event ID `456` — use the event ID to correlate multiple record lines from the same single action |
| `syscall=59` | The numeric syscall ID (59 = `execve` on x86_64 — a lookup table exists via `ausyscall 59 --exact`) |
| `success=yes` / `exit=0` | Whether the syscall succeeded, and its return code — **`success=no` combined with repeated attempts is itself a strong signal of brute-forcing or reconnaissance** |
| `ppid` / `pid` | Parent Process ID and Process ID — **this parent-child relationship is exactly how we'll detect web shells in Part 3** (e.g., `apache2` as a parent of `bash` is abnormal) |
| `auid` | **Audit UID** — the *original login* user ID, which persists even through `su`/`sudo`. This is one of auditd's most powerful features: it tells you who *actually logged in*, even if they escalated privileges afterward. |
| `uid` / `euid` | Current real and effective user ID at time of execution — `euid=0` means the process executed *as root*, regardless of who originally logged in |
| `comm="ls"` | The process's short command name (max 16 characters — can be misleading/truncated for long names, a fact malware sometimes abuses) |
| `exe="/bin/ls"` | The full resolved path to the actual executable file — more reliable than `comm` for hunting, since a masquerading binary can rename its own `comm` but this path is filesystem ground-truth |
| `key="execution"` | The searchable tag we defined ourselves in `hunt.rules` — this is why tagging every rule with a distinct `-k` value pays off enormously at hunt time |

> **Blockquote — Conceptual Warning:** `auid` (Audit UID) is one of the most under-appreciated fields in all of Linux security telemetry. If an attacker phishes `alice`'s credentials, then uses `sudo` to become root, then spawns a hundred processes as root — every single one of those hundred processes will still carry `auid=<alice's original UID>`. This field survives privilege escalation, `su`, and `sudo` chains, giving you an unbroken chain of attribution back to the original compromised login session. Always pivot on `auid`, never just `uid`, when tracing "who really did this."

---

## 2.4 Pillar 2: Osquery — Your OS as a SQL Database

### 2.4.1 The Concept

**Osquery** is an open-source tool, originally built inside Facebook, that exposes operating system state — running processes, listening sockets, installed packages, scheduled tasks, kernel modules, USB devices, and dozens of other categories — as a set of **virtual SQL tables**. Instead of memorizing a dozen different Linux commands (`ps`, `netstat`, `crontab -l`, `lsmod`...) each with their own inconsistent output format, you ask osquery a single, structured `SELECT` question, and it returns clean, structured rows.

**Analogy:** if `auditd` is a continuous audio recording, `osquery` is like walking into the house right now and asking a knowledgeable inspector, "How many windows are currently open?" — a snapshot of current state, expressed as a question, not a stream of history.

### 2.4.2 Installing Osquery

**The Target:** A running `osqueryd` daemon (the persistent background service) plus the `osqueryi` interactive shell for ad-hoc hunting.

```bash
# Add osquery's official APT repository and GPG signing key
export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $OSQUERY_KEY

sudo add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
sudo apt update
sudo apt install -y osquery
```

**The Verification:**

```bash
# Launch the interactive shell
osqueryi --version
```
Expected output: `osqueryi version 5.11.0` (or your installed version).

Now run your very first hunt-relevant query, directly at the interactive prompt:

```bash
osqueryi
```
```sql
-- List every currently running process, its parent, and the executable path.
-- This single query replaces `ps aux` + manually cross-referencing `/proc/*/exe`.
SELECT pid, name, path, parent, cmdline FROM processes LIMIT 5;
```

Expected output (yours will vary, but should be non-empty and clearly tabular):
```
+------+---------+---------------+--------+------------------------+
| pid  | name    | path          | parent | cmdline                |
+------+---------+---------------+--------+------------------------+
| 1    | systemd | /usr/lib/systemd/systemd | 0 | /sbin/init            |
| 892  | sshd    | /usr/sbin/sshd | 1     | /usr/sbin/sshd -D      |
...
```

If you see structured rows like this, **osquery is correctly reading live OS state.** Type `.exit` to leave the shell.

### 2.4.3 Snapshot Queries vs. The Query Pack — Why We Need Scheduling

Running `osqueryi` interactively is fine for on-demand hunting (and this is exactly what we'll do throughout Part 3), but it only tells you what's true **at the exact moment you typed the query**. A process that ran for 30 seconds and exited an hour ago is invisible to an interactive query run now.

The fix is a **query pack**: a JSON configuration file defining a set of queries that `osqueryd` (the persistent daemon, not the interactive shell) runs automatically on a schedule, logging every result over time — turning osquery from a "snapshot" tool into a genuine historical telemetry source, much like auditd.

**The Target:** `/etc/osquery/osquery.conf` (the daemon's main config) and `/etc/osquery/packs/hunt-pack.json` (our scheduled query definitions).

**The Concept:** Think of the query pack as a set of standing instructions to a night-shift guard: "every 5 minutes, walk past the crontab and write down what you see; every 60 seconds, note every open network listening port." Over time, this produces a searchable history, not just a single glance.

#### File: `/etc/osquery/packs/hunt-pack.json`

```json
{
  "queries": {
    "listening_ports_hunt": {
      "query": "SELECT pid, port, protocol, address, path FROM listening_ports lp JOIN processes p ON lp.pid = p.pid;",
      "interval": 60,
      "description": "Every 60s, capture every listening network port and the exact process/binary path behind it. Attacker-planted backdoors and reverse shells frequently open unexpected listening ports.",
      "value": "Detects unauthorized listening services (T1571 - Non-Standard Port)"
    },
    "crontab_state_hunt": {
      "query": "SELECT * FROM crontab;",
      "interval": 300,
      "description": "Every 5 minutes, snapshot the full state of every user's crontab. Combined with auditd's cron_persistence file-watch (Part 2.2), this gives us BOTH the 'someone wrote to cron' event AND the resulting 'here's exactly what the crontab now says' state.",
      "value": "Detects cron-based persistence (T1053.003)"
    },
    "suid_binaries_hunt": {
      "query": "SELECT path, permissions, uid, gid FROM suid_bin;",
      "interval": 3600,
      "description": "Hourly snapshot of every SUID/SGID binary on disk. A newly appearing SUID binary in an unusual path (e.g., /tmp or /dev/shm) is a classic privilege-escalation persistence technique.",
      "value": "Detects SUID-based privilege escalation persistence (T1548.001)"
    },
    "startup_items_hunt": {
      "query": "SELECT name, path, source, status FROM startup_items;",
      "interval": 3600,
      "description": "Hourly snapshot of everything configured to run at system startup.",
      "value": "Detects boot/logon persistence (T1547)"
    },
    "process_open_sockets_hunt": {
      "query": "SELECT pid, family, protocol, local_address, local_port, remote_address, remote_port, state FROM process_open_sockets WHERE remote_port != 0;",
      "interval": 30,
      "description": "Every 30s, capture every active outbound/inbound network socket tied to a specific process ID. This is our OSQUERY-side view of C2 (Command and Control) connections, complementary to Zeek's network-side view built later in this Part.",
      "value": "Detects active C2 connections and unusual outbound traffic per-process (T1071)"
    },
    "shell_history_hunt": {
      "query": "SELECT uid, history_file, command, time FROM shell_history WHERE time > (strftime('%s','now') - 300);",
      "interval": 300,
      "description": "Every 5 minutes, capture any new shell history entries written in the last 5 minutes across all users. Useful for catching manually-typed reconnaissance commands even before they're correlated with auditd's execve events.",
      "value": "Detects manual attacker reconnaissance/interaction (T1059.004)"
    }
  }
}
```

> **Blockquote — Conceptual Warning:** Notice the `interval` values differ significantly — 30 seconds for sockets, but 3600 seconds (1 hour) for SUID binaries. This is a deliberate design decision, not an oversight: **network sockets are highly transient** (a C2 beacon may only connect for a few seconds), so we sample frequently. **SUID binaries rarely change on a healthy system**, so hourly sampling is sufficient and avoids wasting CPU/disk on redundant snapshots of unchanged data. Always tune interval to the *volatility* of what you're watching, not a single blanket default.

#### File: `/etc/osquery/osquery.conf`

```json
{
  "options": {
    "config_plugin": "filesystem",
    "logger_plugin": "filesystem",
    "logger_path": "/var/log/osquery",
    "disable_logging": "false",
    "log_result_events": "true",
    "schedule_splay_percent": "10",
    "pidfile": "/var/osquery/osquery.pidfile",
    "events_expiry": "3600",
    "database_path": "/var/osquery/osquery.db",
    "verbose": "false",
    "worker_threads": "2",
    "enable_monitor": "true",
    "disable_events": "false",
    "audit_allow_config": "true"
  },
  "schedule": {},
  "packs": {
    "hunt-pack": "/etc/osquery/packs/hunt-pack.json"
  }
}
```

**Configuration explained, field by field:**

| Field | Purpose |
|---|---|
| `logger_plugin: filesystem` | Write results to local flat files rather than requiring a remote fleet-management server — appropriate for our single-lab-host setup; production fleets typically swap this for a TLS or Kafka logger plugin |
| `log_result_events: true` | Log each query's results as individual differential events (new/removed rows) rather than one giant snapshot blob — critical for making results greppable later |
| `schedule_splay_percent: 10` | Randomly jitters scheduled query start times by ±10% — prevents every query pack query from firing at the *exact* same second and causing a CPU spike, a subtle but important operational detail on real fleets |
| `events_expiry: 3600` | How long (seconds) audit/event data is retained in osquery's internal buffer before eviction — tune upward if you have disk to spare and want longer local retention |
| `audit_allow_config: true` | Grants osquery permission to use the Linux audit subsystem for certain event-based tables (like `process_events`), letting osquery and auditd **share the same kernel audit feed** rather than fighting over it |

**Step 3 — Enable and start the daemon with our config**

```bash
sudo systemctl enable osqueryd
sudo systemctl restart osqueryd
```

**The Verification:**

```bash
sudo systemctl status osqueryd
```
Expect `Active: active (running)`.

Now confirm the scheduled pack is actually executing and writing results:

```bash
# Watch the results log live - wait ~60 seconds for the first
# listening_ports_hunt interval to fire
sudo tail -f /var/log/osquery/osqueryd.results.log
```

You should see JSON lines appear, resembling:
```json
{"name":"pack_hunt-pack_listening_ports_hunt","hostIdentifier":"lab-endpoint-01","calendarTime":"...","unixTime":1706300100,"columns":{"pid":"892","port":"22","protocol":"6","address":"0.0.0.0","path":"/usr/sbin/sshd"},"action":"added"}
```

If lines like this are appearing, **your osquery pack is live and generating historical telemetry.** Press `Ctrl+C` to stop tailing.

---

## 2.5 Pillar 3: Zeek — Network Metadata at Scale

### 2.5.1 The Concept

**Zeek** (formerly Bro) is a network security monitor that sits passively on a network link, observes raw packets, and — critically — does **not** simply dump raw packet captures like a tool such as `tcpdump`. Instead, Zeek *understands* dozens of network protocols well enough to parse them and emit structured, high-level log files: one line per connection, one line per DNS query, one line per SSH session, etc.

**Analogy:** a raw packet capture (`.pcap` file) is like a security camera's raw, unedited video footage — technically complete, but you'd have to watch hours of tape to find anything. Zeek is like a smart security guard who *watches that footage for you* and writes a structured logbook entry every time a car enters the driveway: license plate, time in, time out, which car it talked to. You almost never need the raw footage — the logbook is enough, and it's a thousand times smaller and faster to search.

### 2.5.2 Installing Zeek

> **Blockquote — Conceptual Warning:** Do **not** `sudo apt install zeek` from Ubuntu's default repositories — as of this writing, Ubuntu's default repos often carry outdated or renamed (`bro`) packages that lag years behind. Always use Zeek's official OpenSUSE Build Service (OBS) repository, shown below, which is the officially blessed distribution channel maintained by the Zeek Project itself.

```bash
# Add Zeek's official repository signing key and source for Ubuntu 22.04
echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_22.04/ /' | \
  sudo tee /etc/apt/sources.list.d/security:zeek.list

curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_22.04/Release.key | \
  gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null

sudo apt update
sudo apt install -y zeek

# Add Zeek's binaries to PATH for convenience
echo 'export PATH=/opt/zeek/bin:$PATH' | sudo tee -a /etc/profile.d/zeek.sh
source /etc/profile.d/zeek.sh
```

**Verification (Install):**
```bash
zeek --version
```
Expected output: `zeek version 6.0.x`.

### 2.5.3 Identifying Your Monitoring Interface

**The Concept:** Zeek needs to be told *which network interface* to listen on, and that interface ideally needs to be in **promiscuous mode** — a network card setting that allows it to capture *all* traffic passing by, not just traffic addressed directly to its own IP. In production, this interface is typically connected to a **SPAN/mirror port** on a switch (a port configured to receive a copy of all traffic from other ports) or a network TAP (a passive hardware splitter). In our single-VM lab, we'll simply monitor the VM's primary interface, which is sufficient to see the VM's own traffic for learning purposes.

```bash
# Identify your primary network interface name
ip -brief link show
```
Expected output (interface name will vary — commonly `eth0`, `ens33`, or `enp0s3`):
```
lo               UNKNOWN        00:00:00:00:00:00
eth0             UP             08:00:27:aa:bb:cc
```

**Step: Configure Zeek's node.cfg**

#### File: `/opt/zeek/etc/node.cfg`

```ini
# =============================================================================
# Zeek Node Configuration - Standalone Deployment (single lab host)
# In production, this file defines a distributed cluster (manager, proxy,
# multiple workers). For our single-lab setup, "standalone" mode runs
# every Zeek component (logging, analysis, capture) as one process - simpler
# to reason about while learning, and entirely adequate for a lab or
# small single-sensor deployment.
# =============================================================================

[zeek]
type=standalone
host=localhost
# CHANGE 'eth0' below to match YOUR interface name from `ip -brief link show`
interface=eth0
```

**Step: Configure network definitions**

#### File: `/opt/zeek/etc/networks.cfg`

```
# Define which IP ranges Zeek should consider "local" vs "remote".
# This distinction is CRITICAL for hunting - it's what lets us later write
# a query like "show me connections where the ORIGINATOR is local but the
# RESPONDER is also local" (our exact Part 1 hypothesis: internal-to-internal
# SSH bypassing the bastion). Without correct network definitions here,
# Zeek can't tell "internal-to-internal" traffic apart from "internal-to-internet."

10.0.0.0/8          Private IP space, RFC 1918
172.16.0.0/12       Private IP space, RFC 1918
192.168.0.0/16      Private IP space, RFC 1918
```

> **Blockquote — Conceptual Warning:** Adjust the CIDR ranges above to match YOUR actual lab's subnet (check with `ip addr show` — most home/lab VM networks use `192.168.x.x` or `10.x.x.x`). If this file doesn't match your real subnet, every log entry's `local_orig` and `local_resp` fields will be wrong, silently breaking the exact internal-vs-internal filtering logic Part 4's SSH lateral-movement hunt depends on.

**Step: Deploy and start Zeek**

```bash
# Zeek's own deployment tool - validates config and (re)starts all
# configured nodes cleanly, equivalent to a "compile + restart" step
sudo /opt/zeek/bin/zeekctl deploy
```

**The Verification:**

```bash
sudo /opt/zeek/bin/zeekctl status
```
Expected output:
```
Name         Type       Host          Status    Pid    Peers  Started
zeek         standalone localhost     running   4821   0      ...
```

Now generate real traffic and confirm Zeek logs it:

```bash
# From the Zeek host itself, generate an outbound connection
curl -s https://example.com > /dev/null

# Zeek writes logs into the current log directory, symlinked as "current"
cd /opt/zeek/logs/current
ls -la
```

Expected output — you should see (at minimum) `conn.log`, `dns.log`, `ssl.log`, and `weird.log`:
```
-rw-r--r-- 1 zeek zeek  4821 Jan 26 14:32 conn.log
-rw-r--r-- 1 zeek zeek  1203 Jan 26 14:32 dns.log
-rw-r--r-- 1 zeek zeek   980 Jan 26 14:32 ssl.log
-rw-r--r-- 1 zeek zeek   112 Jan 26 14:32 weird.log
```

Inspect the connection you just generated (Zeek logs are tab-separated, but `zeek-cut` is the officially provided tool for readably extracting specific fields):

```bash
cat conn.log | /opt/zeek/bin/zeek-cut ts id.orig_h id.orig_p id.resp_h id.resp_p proto service duration orig_bytes resp_bytes | tail -n 5
```

Expected output (fields: timestamp, source IP, source port, dest IP, dest port, protocol, service, duration, bytes sent, bytes received):
```
1706300245.112384    192.168.1.50    51234    93.184.216.34    443    tcp    ssl    0.245123    517    6821
```

If you see a populated line like this, **Zeek is correctly capturing and parsing your network traffic.** This exact `conn.log` — with these exact fields — is what powers our entire Part 4 lateral-movement and beaconing hunt.

### 2.5.4 A First Look at `ssh.log` — Setting Up Part 4

Since our Part 1 hypothesis specifically concerns SSH, let's confirm right now that Zeek's SSH analyzer is active and generate a sample record.

```bash
# From your Zeek host (or another lab machine on the same network),
# initiate an SSH connection to generate an ssh.log entry.
# (Replace with any reachable host - even localhost works to test the pipeline.)
ssh -o StrictHostKeyChecking=no localhost exit
```

```bash
cat /opt/zeek/logs/current/ssh.log | /opt/zeek/bin/zeek-cut ts id.orig_h id.resp_h id.resp_p auth_success client server
```

Expected output:
```
1706300512.881233    192.168.1.50    192.168.1.50    22    -    SSH-2.0-OpenSSH_8.9    SSH-2.0-OpenSSH_8.9
```

> **Blockquote — Conceptual Warning:** Notice the `auth_success` field shows `-` (unknown/unset) rather than `T` or `F` in many lab setups. This is expected and **extremely important to understand**: Zeek can only determine authentication success by observing specific unencrypted handshake byte patterns before SSH's encryption fully engages — with modern SSH versions, this is sometimes ambiguous. This is precisely *why* Part 4 correlates Zeek's `ssh.log` with the host's own `/var/log/auth.log` (captured via our auditd/rsyslog setup) rather than trusting network metadata alone for authentication outcomes. Network telemetry and host telemetry are complementary, never a full substitute for one another.

---

## 2.6 Bringing It All Together — A Combined Verification Checklist

Before proceeding to Part 3, run this complete health check. Every single line should succeed — if any fail, stop and revisit that tool's section above before continuing, since Parts 3–5 assume all three pillars are live.

```bash
echo "=== AUDITD STATUS ==="
sudo systemctl is-active auditd
sudo auditctl -l | wc -l          # should be > 0 (our hunt.rules lines loaded)

echo "=== OSQUERY STATUS ==="
sudo systemctl is-active osqueryd
sudo test -f /var/log/osquery/osqueryd.results.log && echo "results log exists"

echo "=== ZEEK STATUS ==="
sudo /opt/zeek/bin/zeekctl status | grep running
sudo test -f /opt/zeek/logs/current/conn.log && echo "conn.log exists"
```

Expected combined output:
```
=== AUDITD STATUS ===
active
23
=== OSQUERY STATUS ===
active
results log exists
=== ZEEK STATUS ===
zeek   standalone localhost   running   4821   0   ...
conn.log exists
```

### 2.6.1 Updating Our Hunt Template — Section 4 Is No Longer "Pending"

Recall from Part 1 that our saved `HUNT-2024-001` document had every row in Section 4 marked "Pending Part 2 build." Go back to that file right now and update it:

```markdown
## 4. Required Telemetry & Data Sources
| Source              | Tool/Log Path                | Time Range Queried | Available? (Y/N) |
|---------------------|-------------------------------|---------------------|-------------------|
| Network connections  | Zeek /opt/zeek/logs/current/conn.log  | Trailing 30 days | Y - confirmed live |
| SSH protocol detail  | Zeek /opt/zeek/logs/current/ssh.log   | Trailing 30 days | Y - confirmed live |
| Host auth events     | /var/log/auth.log             | Trailing 30 days    | Y - confirmed live |
```

This is not busywork — it's the entire payoff of Part 2. Your hypothesis from Part 1 is no longer theoretical; every log source it names now demonstrably exists and is actively collecting on your lab machine.

---

## 2.7 Chapter Summary — What You Now Have

- [ ] **Auditd** installed, with a production-grade `hunt.rules` file watching execution, privilege escalation, cron/systemd/SSH persistence paths, and account manipulation — verified via `auditctl -l` and `ausearch`.
- [ ] A working mental model for reading raw audit records field-by-field, especially the critical `auid` (Audit UID) field that survives privilege escalation.
- [ ] **Osquery** installed, with a custom `hunt-pack.json` scheduling six purpose-built queries (listening ports, crontab state, SUID binaries, startup items, open sockets, shell history) — verified via a live-tailed `osqueryd.results.log`.
- [ ] **Zeek** installed from the official repository (not Ubuntu's default), configured with correct interface and local-network definitions, and verified to produce `conn.log` and `ssh.log` entries from real traffic you generated yourself.
- [ ] A fully updated Part 1 Hunt Template, with Section 4 now showing **confirmed live** telemetry sources instead of "Pending."

> **Blockquote — Bridge to Part 3:** You now have a continuous stream of kernel-level execution events (auditd), a scheduled SQL-queryable view of OS state (osquery), and structured network connection logs (Zeek). Part 3 picks up auditd and osquery exactly where we left them here, adding **Velociraptor** — an open-source DFIR orchestrator — to remotely collect and analyze these artifacts at scale, and to hunt for two concrete adversary behaviors: **web shells** and **cron-based persistence**, both of which our rules and query pack were specifically engineered, in this Part, to detect.

**Proceed to Part 3: Hunting for Execution & Persistence (Endpoint Hunt).**
