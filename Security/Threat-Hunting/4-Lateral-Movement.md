# Part 4: Hunting for Lateral Movement & C2 (Network Hunt) — Expanded Edition

> **Blockquote — Why This Part Exists:** This is the payoff Part 1 promised you. We are about to execute **Hunt HUNT-2024-001** — the SSH lateral-movement hypothesis you formally wrote, with success/failure criteria defined *before* you saw any data, back in §1.6.1. Every field we filter on below was chosen deliberately in Part 1; every log source we query was built and verified in Part 2. Nothing here is improvised.

---

## 4.1 Target Behaviors — What We're Actually Hunting

| Behavior | MITRE ATT&CK ID | Plain-English Description | Why Attackers Do It |
|---|---|---|---|
| **SSH hijacking / lateral movement** | T1021.004 (Remote Services: SSH) | An adversary uses stolen credentials or keys to SSH directly between internal hosts, bypassing designated jump/bastion infrastructure | Avoids the one chokepoint most organizations actually monitor closely (the bastion), and blends in with legitimate SSH — a protocol you can never simply "block" |
| **Abnormal internal connections** | T1021 (general) / T1046 (Network Service Discovery) | Any internal-to-internal connection pattern that deviates from an established baseline — new host pairs, unusual ports, unusual times | Reveals reconnaissance and staged movement even when the specific protocol isn't inherently suspicious |
| **DNS beaconing** | T1071.004 (Application Layer Protocol: DNS) / T1568 (Dynamic Resolution) | Malware "phoning home" to a C2 (Command and Control) server at regular, machine-generated intervals, often via DNS to blend in with normal traffic | DNS is almost universally allowed outbound through firewalls, making it an attractive low-friction C2 channel |

### 4.1.1 Why Network Telemetry Succeeds Where Endpoint Telemetry Cannot

Part 3 taught us to distrust any single vantage point. Here's the concrete reason network telemetry is *non-negotiable* for lateral movement specifically: if an attacker compromises **Host A**, then SSHs to **Host B**, Host A's own auditd log shows an outbound `ssh` client execution — normal-looking, since `ssh` is a completely legitimate binary run by real users constantly. Host B's auditd log shows an *inbound* authenticated session — also normal-looking in isolation. **Neither host's endpoint telemetry alone reveals the anomaly.** Only the network's view — "Host A talked to Host B on port 22, and that pairing has never happened before, and Host A isn't the bastion" — exposes the pattern. This is precisely why Part 1's hypothesis named Zeek logs, not host logs, as the primary evidence location.

---

## 4.2 The Hunt Tool: Zeek Logs, Revisited

Recall from Part 2 that Zeek is now actively running on our lab host, producing `conn.log`, `dns.log`, and `ssh.log` in `/opt/zeek/logs/current/`. Part 4's entire job is to become fluent in *querying* these logs for the specific patterns our hypothesis describes.

### 4.2.1 A Field-by-Field Tour of `conn.log`

Before writing any hunt queries, let's understand exactly what columns are available — this is reference material you'll return to constantly:

| Field | Meaning |
|---|---|
| `ts` | Connection start timestamp (Unix epoch, fractional seconds) |
| `uid` | Zeek's own unique connection identifier — use this to pivot into `dns.log`/`ssh.log`/`http.log` for the *same* connection |
| `id.orig_h` / `id.orig_p` | Originating (source) host IP and port |
| `id.resp_h` / `id.resp_p` | Responding (destination) host IP and port |
| `proto` | Transport protocol (`tcp`, `udp`, `icmp`) |
| `service` | Zeek's *inferred* application protocol (e.g., `ssh`, `dns`, `http`) — determined by content inspection, not just port number, which is important because attackers sometimes run services on non-standard ports specifically to evade port-based filtering |
| `duration` | Connection length in seconds |
| `orig_bytes` / `resp_bytes` | Bytes sent by originator / responder |
| `conn_state` | Connection state flag (e.g., `SF` = normal completion, `S0` = connection attempt, no reply — often reconnaissance/scanning) |
| `local_orig` / `local_resp` | Boolean — whether the originator/responder falls within the "local" networks we defined in `networks.cfg` back in §2.5.3. **This is the field our entire lateral-movement hunt depends on.** |

> **Blockquote — Conceptual Warning:** If `local_orig` and `local_resp` are both showing incorrect values, go back to §2.5.3 right now and fix `/opt/zeek/etc/networks.cfg` before continuing. Every query in this Part filters on these two booleans — if they're wrong, every result below will be wrong too, silently.

---

## 4.3 Hunt #1: Isolating Internal SSH Sessions Bypassing the Bastion

### 4.3.1 The Concept

Our Part 1 hypothesis, restated precisely: *"internal-to-internal SSH connections where the source is not our known bastion host."* This translates directly into a `conn.log` filter: `service == ssh`, `local_orig == true`, `local_resp == true`, and `id.orig_h != <bastion IP>`.

### 4.3.2 The Target: A `zeek-cut`/`awk` Pipeline for Ad-Hoc Hunting

**The Implementation:**

```bash
cd /opt/zeek/logs/current

# Step 1: Extract only the fields we need, tab-separated, for readability
# and for piping into awk in the next step.
/opt/zeek/bin/zeek-cut ts id.orig_h id.orig_p id.resp_h id.resp_p service local_orig local_resp \
  < conn.log > /tmp/ssh_candidates_raw.tsv

# Step 2: Filter for SSH service, both sides local, and NOT our bastion IP.
# awk is ideal here because Zeek's TSV output is exactly the kind of
# simple, well-defined column format awk was designed to process -
# no need for a heavier tool for a single-pass filter like this.
awk -F'\t' '
  $6 == "ssh" && $7 == "T" && $8 == "T" && $2 != "10.10.0.5" {
    print $1, $2, $3, $4, $5
  }
' /tmp/ssh_candidates_raw.tsv
```

**Explaining the `awk` logic:** `-F'\t'` tells awk our fields are tab-separated (matching Zeek's native log format). `$6`, `$7`, `$8` refer to the 6th, 7th, and 8th columns we extracted via `zeek-cut` — respectively `service`, `local_orig`, and `local_resp`. Zeek encodes booleans as literal `T`/`F` characters in its logs, which is why we compare against the string `"T"` rather than a numeric `1`.

**The Verification — Generate a Realistic Test Case**

```bash
# Simulate an internal, non-bastion SSH connection (adjust IPs to match
# YOUR actual lab subnet from networks.cfg).
ssh -o StrictHostKeyChecking=no 192.168.1.51 exit   # from 192.168.1.50, NOT the bastion
```

Re-run the pipeline above. Expected output — a line showing your simulated connection:
```
1706310881.552013 192.168.1.50 51882 192.168.1.51 22
```

If this line appears, **your ad-hoc bastion-bypass hunt query is working correctly.**

### 4.3.3 Elevating This to a Reusable Python Script

**The Concept:** One-off `awk` pipelines are great for quick checks, but a hunt you'll run repeatedly (e.g., weekly) deserves a proper script with clear output, error handling, and the ability to easily adjust the bastion IP or time window — exactly the kind of production-quality code this series insists on, even for "just a hunting script."

#### File: `scripts/hunt_ssh_bastion_bypass.py`

```python
#!/usr/bin/env python3
"""
hunt_ssh_bastion_bypass.py

Executes HUNT-2024-001 from the Part 1 Hunt Investigation Template:
detects internal-to-internal SSH connections that bypass the designated
bastion host, using Zeek's conn.log as the evidence source.

MITRE ATT&CK: TA0008 (Lateral Movement) / T1021.004 (Remote Services: SSH)
"""

import csv
import sys
import argparse
from datetime import datetime, timezone

def parse_zeek_log(log_path):
    """
    Zeek's default TSV logs include a commented header block (lines
    starting with '#') describing the field names and types, followed
    by the actual tab-separated data rows. We must parse this header
    ourselves rather than assuming a fixed column order, because
    enabling/disabling Zeek scripts can add or remove columns over time.
    """
    fields = []
    rows = []
    with open(log_path, "r") as f:
        for line in f:
            if line.startswith("#fields"):
                # The #fields line itself is tab-separated, e.g.:
                # #fields	ts	uid	id.orig_h	id.orig_p ...
                fields = line.strip().split("\t")[1:]
            elif line.startswith("#"):
                continue  # skip all other header/comment lines
            else:
                rows.append(line.strip().split("\t"))
    return fields, rows

def hunt_bastion_bypass(conn_log_path, bastion_ip, exclude_ports=None):
    """
    Core detection logic: filters conn.log rows for SSH service,
    both endpoints local, and originator NOT the bastion IP.
    Returns a list of dicts for easy downstream reporting.
    """
    exclude_ports = exclude_ports or []
    fields, rows = parse_zeek_log(conn_log_path)

    # Build a lookup from field name -> column index, so the rest of
    # this function is readable ("row[idx['service']]") rather than
    # relying on brittle hardcoded numeric indices.
    idx = {name: i for i, name in enumerate(fields)}

    required = ["ts", "id.orig_h", "id.orig_p", "id.resp_h",
                "id.resp_p", "service", "local_orig", "local_resp"]
    missing = [f for f in required if f not in idx]
    if missing:
        # Fail loudly and specifically rather than silently returning
        # zero results, which would be indistinguishable from "no
        # findings" - a dangerous ambiguity in a security tool.
        raise ValueError(f"conn.log is missing required fields: {missing}. "
                          f"Check Zeek's SSH analyzer / networks.cfg configuration.")

    findings = []
    for row in rows:
        # Zeek uses a literal "-" to represent an unset/empty value.
        if len(row) < len(fields):
            continue  # skip malformed/truncated lines defensively

        if row[idx["service"]] != "ssh":
            continue
        if row[idx["local_orig"]] != "T" or row[idx["local_resp"]] != "T":
            continue
        if row[idx["id.orig_h"]] == bastion_ip:
            continue
        if row[idx["id.resp_p"]] in exclude_ports:
            continue

        findings.append({
            "timestamp": datetime.fromtimestamp(
                float(row[idx["ts"]]), tz=timezone.utc
            ).isoformat(),
            "source_ip": row[idx["id.orig_h"]],
            "source_port": row[idx["id.orig_p"]],
            "dest_ip": row[idx["id.resp_h"]],
            "dest_port": row[idx["id.resp_p"]],
        })
    return findings

def main():
    parser = argparse.ArgumentParser(
        description="Hunt for internal SSH sessions bypassing the bastion host."
    )
    parser.add_argument("--conn-log", required=True,
                         help="Path to Zeek's conn.log (e.g., /opt/zeek/logs/current/conn.log)")
    parser.add_argument("--bastion-ip", required=True,
                         help="The known bastion/jump host's internal IP address")
    args = parser.parse_args()

    try:
        findings = hunt_bastion_bypass(args.conn_log, args.bastion_ip)
    except (FileNotFoundError, ValueError) as e:
        # Explicit, actionable error handling - a hallmark of
        # production-grade code, even for a hunting utility.
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(1)

    if not findings:
        print("[RESULT] No bastion-bypassing internal SSH sessions found. "
              "Hypothesis HUNT-2024-001 REFUTED for this dataset.")
        sys.exit(0)

    print(f"[RESULT] {len(findings)} bastion-bypassing SSH session(s) found. "
          f"Hypothesis HUNT-2024-001 requires further CONFIRMATION review:\n")
    for f in findings:
        print(f"  {f['timestamp']}  {f['source_ip']}:{f['source_port']} "
              f"-> {f['dest_ip']}:{f['dest_port']}")

if __name__ == "__main__":
    main()
```

**The Verification:**

```bash
chmod +x scripts/hunt_ssh_bastion_bypass.py
python3 scripts/hunt_ssh_bastion_bypass.py \
  --conn-log /opt/zeek/logs/current/conn.log \
  --bastion-ip 10.10.0.5
```

With your §4.3.2 simulated connection still present in the current log, expected output:
```
[RESULT] 1 bastion-bypassing SSH session(s) found. Hypothesis HUNT-2024-001 requires further CONFIRMATION review:

  2024-01-26T18:34:41.552013+00:00  192.168.1.50:51882 -> 192.168.1.51:22
```

**This is the moment HUNT-2024-001 goes from a Part 1 hypothesis to real, executed, documented evidence.** Go update your saved template file's Section 6 (Queries Executed) and Section 7 (Findings) right now with this exact output.

---

## 4.4 Hunt #2: Establishing a Baseline for "Rare" Host Pairings

### 4.4.1 The Concept

A single bastion-bypass event might be a one-time approved exception (an admin's documented direct-access workflow). Our Part 1 success criteria specifically required checking whether the host pairing was **new/rare in the prior 30 days** — this is what separates a *true positive* from a *benign true positive* in our Verdict section. This requires **baselining**: establishing what "normal" looks like before you can recognize "abnormal."

**Analogy:** A security guard who's worked the same building for a year knows that the cleaning crew's van always arrives at 6 AM — that's baseline. If a random van shows up at 3 AM, it's not the *van* that's suspicious, it's the fact that **this specific pattern has never happened before**. Baselining converts "is this bad?" into "have I seen this before?" — an objective, data-driven question rather than a subjective gut feeling.

### 4.4.2 The Target: A Python Baseline Comparison Script

#### File: `scripts/hunt_rare_host_pairings.py`

```python
#!/usr/bin/env python3
"""
hunt_rare_host_pairings.py

Extends HUNT-2024-001 by comparing today's internal SSH host pairings
against a historical baseline window, flagging pairings that have
NEVER been observed before - the strongest possible signal for
credential-based lateral movement, since legitimate admin workflows
are almost always repetitive and habitual.

MITRE ATT&CK: T1021.004
"""

import argparse
import sys
from collections import defaultdict

# Reuse the parsing logic from our first script rather than duplicating
# it - in a real deployment, this would be a shared module, but is
# inlined here for a single-file, fully copy-pasteable script.
def parse_zeek_log(log_path):
    fields = []
    rows = []
    with open(log_path, "r") as f:
        for line in f:
            if line.startswith("#fields"):
                fields = line.strip().split("\t")[1:]
            elif line.startswith("#"):
                continue
            else:
                rows.append(line.strip().split("\t"))
    return fields, rows

def extract_ssh_pairings(conn_log_path):
    """Returns a set of (source_ip, dest_ip) tuples for all internal SSH sessions."""
    fields, rows = parse_zeek_log(conn_log_path)
    idx = {name: i for i, name in enumerate(fields)}
    pairings = set()
    for row in rows:
        if len(row) < len(fields):
            continue
        if row[idx["service"]] != "ssh":
            continue
        if row[idx.get("local_orig", -1)] != "T" or row[idx.get("local_resp", -1)] != "T":
            continue
        pairings.add((row[idx["id.orig_h"]], row[idx["id.resp_h"]]))
    return pairings

def main():
    parser = argparse.ArgumentParser(
        description="Flag internal SSH host pairings never seen in a baseline window."
    )
    parser.add_argument("--baseline-logs", nargs="+", required=True,
                         help="One or more archived conn.log files representing "
                              "the trailing 30-day baseline period (e.g., "
                              "/opt/zeek/logs/2024-01-*/conn.*.log)")
    parser.add_argument("--current-log", required=True,
                         help="Today's conn.log to evaluate against the baseline")
    args = parser.parse_args()

    # Build the historical baseline set from every provided archive file.
    # A defaultdict isn't strictly required here (a plain set suffices),
    # but using one keeps this extensible if we later want COUNT of
    # occurrences rather than just presence/absence.
    baseline_pairings = set()
    for path in args.baseline_logs:
        try:
            baseline_pairings |= extract_ssh_pairings(path)
        except FileNotFoundError:
            print(f"[WARN] Baseline file not found, skipping: {path}", file=sys.stderr)

    try:
        current_pairings = extract_ssh_pairings(args.current_log)
    except FileNotFoundError as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(1)

    # The core baselining logic: set difference. Anything in today's
    # pairings that does NOT exist in the historical baseline set is,
    # by definition, "never seen before in the last 30 days."
    novel_pairings = current_pairings - baseline_pairings

    if not novel_pairings:
        print("[RESULT] No novel SSH host pairings today. "
              "All observed pairings match the established 30-day baseline.")
        sys.exit(0)

    print(f"[RESULT] {len(novel_pairings)} NOVEL SSH host pairing(s) detected "
          f"(not present in 30-day baseline):\n")
    for src, dst in sorted(novel_pairings):
        print(f"  {src} -> {dst}   <-- NEW PAIRING, investigate")

if __name__ == "__main__":
    main()
```

**The Verification:**

```bash
# In a real deployment, /opt/zeek/logs/ contains one rotated directory
# per day (e.g., 2024-01-01/, 2024-01-02/...). For this lab verification,
# simulate a baseline by copying today's log as a stand-in "history" that
# does NOT contain our simulated connection, proving the diff logic works.
mkdir -p /tmp/baseline_sim
grep -v "192.168.1.51" /opt/zeek/logs/current/conn.log > /tmp/baseline_sim/conn.log

python3 scripts/hunt_rare_host_pairings.py \
  --baseline-logs /tmp/baseline_sim/conn.log \
  --current-log /opt/zeek/logs/current/conn.log
```

Expected output:
```
[RESULT] 1 NOVEL SSH host pairing(s) detected (not present in 30-day baseline):

  192.168.1.50 -> 192.168.1.51   <-- NEW PAIRING, investigate
```

This confirms **HUNT-2024-001's full success criteria are now met**: a bastion-bypassing session (§4.3) that is *also* a novel host pairing (§4.4) — exactly the confirmation condition we wrote in Part 1, §1.6.1, before we ever looked at data.

---

## 4.5 Hunt #3: DNS Beaconing Detection

### 4.5.1 The Concept

**Beaconing** is when malware "phones home" to a C2 server at regular intervals to check for new instructions. Because these check-ins are typically generated by code (not a human), they tend to occur at suspiciously **regular time intervals** — a pattern human-driven traffic almost never produces. If you plot the time gaps between a host's repeated connections to the same destination, legitimate human/application traffic looks like noisy, irregular scatter; beaconing malware looks like an eerily consistent, low-variance rhythm — like a metronome instead of a heartbeat.

### 4.5.2 The Target: A Python Beacon Interval Analyzer

#### File: `scripts/hunt_dns_beaconing.py`

```python
#!/usr/bin/env python3
"""
hunt_dns_beaconing.py

Analyzes Zeek's dns.log for beaconing patterns: repeated queries to the
SAME domain from the SAME internal host at suspiciously regular time
intervals - a strong indicator of C2 (Command and Control) callback
activity, per MITRE ATT&CK T1071.004 / T1568.

Method: for each (source_ip, query_domain) pair, compute the standard
deviation of inter-query time gaps. Low standard deviation relative to
the mean interval indicates machine-regular (beaconing) behavior, as
opposed to the high-variance timing of human-driven traffic.
"""

import argparse
import sys
import statistics
from collections import defaultdict

def parse_zeek_log(log_path):
    fields = []
    rows = []
    with open(log_path, "r") as f:
        for line in f:
            if line.startswith("#fields"):
                fields = line.strip().split("\t")[1:]
            elif line.startswith("#"):
                continue
            else:
                rows.append(line.strip().split("\t"))
    return fields, rows

def analyze_beaconing(dns_log_path, min_occurrences=5, max_coefficient_of_variation=0.15):
    """
    coefficient_of_variation = stdev / mean of inter-query intervals.
    A LOW coefficient of variation means intervals are highly consistent
    (i.e., "every 60 seconds, almost exactly") - the hallmark of
    machine-generated beaconing rather than organic human browsing.

    min_occurrences filters out one-off queries that don't have enough
    data points to meaningfully assess regularity - you cannot call
    something "regular" from only two samples.
    """
    fields, rows = parse_zeek_log(dns_log_path)
    idx = {name: i for i, name in enumerate(fields)}

    for required_field in ["ts", "id.orig_h", "query"]:
        if required_field not in idx:
            raise ValueError(f"dns.log missing required field: {required_field}")

    # Group every query timestamp by (source host, queried domain)
    query_times = defaultdict(list)
    for row in rows:
        if len(row) < len(fields):
            continue
        src = row[idx["id.orig_h"]]
        domain = row[idx["query"]]
        if domain == "-" or not domain:
            continue
        query_times[(src, domain)].append(float(row[idx["ts"]]))

    suspects = []
    for (src, domain), timestamps in query_times.items():
        if len(timestamps) < min_occurrences:
            continue

        timestamps.sort()
        # Compute the gap between each consecutive pair of queries -
        # this list of "intervals" is what we actually analyze for regularity.
        intervals = [t2 - t1 for t1, t2 in zip(timestamps, timestamps[1:])]

        mean_interval = statistics.mean(intervals)
        if mean_interval == 0:
            continue  # avoid division by zero for near-simultaneous queries

        stdev_interval = statistics.stdev(intervals) if len(intervals) > 1 else 0
        coefficient_of_variation = stdev_interval / mean_interval

        if coefficient_of_variation <= max_coefficient_of_variation:
            suspects.append({
                "source_ip": src,
                "domain": domain,
                "occurrence_count": len(timestamps),
                "mean_interval_seconds": round(mean_interval, 2),
                "coefficient_of_variation": round(coefficient_of_variation, 4),
            })

    # Sort by lowest coefficient of variation first - i.e., the MOST
    # metronomic, most suspicious patterns surface at the top of the report.
    return sorted(suspects, key=lambda s: s["coefficient_of_variation"])

def main():
    parser = argparse.ArgumentParser(description="Hunt for DNS beaconing patterns.")
    parser.add_argument("--dns-log", required=True,
                         help="Path to Zeek's dns.log")
    parser.add_argument("--min-occurrences", type=int, default=5,
                         help="Minimum query count required to assess regularity (default: 5)")
    parser.add_argument("--max-cv", type=float, default=0.15,
                         help="Maximum coefficient of variation to flag as beaconing (default: 0.15)")
    args = parser.parse_args()

    try:
        suspects = analyze_beaconing(args.dns_log, args.min_occurrences, args.max_cv)
    except (FileNotFoundError, ValueError) as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(1)

    if not suspects:
        print("[RESULT] No beaconing-pattern DNS queries detected.")
        sys.exit(0)

    print(f"[RESULT] {len(suspects)} suspected beaconing pattern(s) detected:\n")
    print(f"{'Source IP':<16}{'Domain':<40}{'Count':<8}{'Avg Interval(s)':<18}{'CoV':<8}")
    for s in suspects:
        print(f"{s['source_ip']:<16}{s['domain']:<40}{s['occurrence_count']:<8}"
              f"{s['mean_interval_seconds']:<18}{s['coefficient_of_variation']:<8}")

if __name__ == "__main__":
    main()
```

**The Verification — Simulate a Beaconing Pattern**

```bash
# Simulate a machine-regular DNS beacon: query the same subdomain
# every 5 seconds, 10 times, mimicking C2 check-in behavior.
for i in $(seq 1 10); do
  dig +short beacon-test.example.com > /dev/null
  sleep 5
done
```

```bash
python3 scripts/hunt_dns_beaconing.py \
  --dns-log /opt/zeek/logs/current/dns.log \
  --min-occurrences 5 \
  --max-cv 0.15
```

Expected output (your exact interval/CoV numbers will vary slightly due to real-world timing jitter, but CoV should be low):
```
[RESULT] 1 suspected beaconing pattern(s) detected:

Source IP       Domain                                  Count   Avg Interval(s)   CoV
192.168.1.50    beacon-test.example.com                 10      5.02              0.031
```

A `CoV` (coefficient of variation) of `0.031` means the intervals varied by only about 3% around the mean — an extremely regular, metronomic pattern, exactly what real beaconing malware produces. Compare this against normal human browsing traffic (e.g., repeatedly querying a news site's domain over an hour), which should show a much higher, more erratic CoV.

> **Blockquote — Conceptual Warning:** Beacon detection via coefficient of variation is a **statistical heuristic**, not a certainty — sophisticated malware deliberately adds **jitter** (small randomized delays) specifically to defeat this exact detection method. A CoV threshold of 0.15 is a reasonable starting point for a lab, but in production you should tune it against your own environment's legitimate periodic traffic (NTP syncs, health checks, monitoring agents all beacon too — you must baseline and allowlist these first, or you'll drown in false positives).

---

## 4.6 Hunt #4: SSH Session Duration & Data Volume Anomalies

### 4.6.1 The Concept

Beyond *who* connects to *whom*, Zeek's `conn.log` also tells us *how much data* moved and *for how long*. A legitimate interactive SSH admin session typically shows a duration correlated with actual human typing (minutes, irregular byte flow). A **file exfiltration** or **automated lateral movement toolkit** session, by contrast, often shows either unusually large `resp_bytes`/`orig_bytes` (bulk data transfer) or unusually short, scripted session durations inconsistent with human interaction.

### 4.6.2 The Target: An Awk-Based Statistical Outlier Query

```bash
# Compute basic statistics (min/max/avg duration and bytes) across all
# internal SSH sessions, to establish what "typical" looks like on
# YOUR network before flagging outliers.
/opt/zeek/bin/zeek-cut ts id.orig_h id.resp_h duration orig_bytes resp_bytes service local_orig local_resp \
  < /opt/zeek/logs/current/conn.log | \
awk -F'\t' '
  $6 == "ssh" && $7 == "T" && $8 == "T" {
    count++
    dur_sum += $4
    bytes_sum += ($5 + $6)
    if ($4 > max_dur) max_dur = $4
    if (min_dur == "" || $4 < min_dur) min_dur = $4
  }
  END {
    if (count > 0) {
      printf "SSH Sessions: %d\n", count
      printf "Avg Duration: %.2fs\n", dur_sum/count
      printf "Min Duration: %.2fs\n", min_dur
      printf "Max Duration: %.2fs\n", max_dur
    } else {
      print "No internal SSH sessions found in this log window."
    }
  }
'
```

**The Verification:** Run this against your current `conn.log` after generating a few test SSH sessions of varying length (e.g., one `ssh host exit` — near-instant — and one where you stay logged in typing for 30 seconds before exiting). Confirm the `Min Duration` and `Max Duration` values reasonably reflect those two distinct sessions, proving the aggregation pipeline correctly separates and measures session length — a prerequisite for meaningfully flagging *future* outliers once you have a real baseline of normal admin session lengths.

---

## 4.7 Completing HUNT-2024-001 — The Full Investigation Report

We now have everything needed to close out the hypothesis first written in Part 1. Here is the completed template, Sections 6 through 11, appended to what we already filled in during §1.6.1:

```markdown
## 6. Queries Executed

### Query 1
```
python3 scripts/hunt_ssh_bastion_bypass.py --conn-log /opt/zeek/logs/current/conn.log --bastion-ip 10.10.0.5
```
**Purpose:** Identify internal SSH sessions where source ≠ bastion IP
**Result Summary:** 1 session found: 192.168.1.50:51882 -> 192.168.1.51:22 at 2024-01-26T18:34:41Z

### Query 2
```
python3 scripts/hunt_rare_host_pairings.py --baseline-logs /tmp/baseline_sim/conn.log --current-log /opt/zeek/logs/current/conn.log
```
**Purpose:** Determine whether the flagged pairing is novel vs. an established/approved pattern
**Result Summary:** Pairing (192.168.1.50 -> 192.168.1.51) confirmed NOVEL - zero occurrences in baseline window

## 7. Findings
- **Summary of findings:** A single internal SSH session was identified originating from a
  non-bastion host (192.168.1.50) to another internal host (192.168.1.51), representing a
  host pairing with no precedent in the established baseline window.
- **Affected hosts/users/assets:** 192.168.1.50 (source), 192.168.1.51 (destination)
- **Timeline of events:**

| Timestamp (UTC) | Host | Event | Source |
|---|---|---|---|
| 2024-01-26T18:34:41Z | 192.168.1.50 | Initiated SSH connection to 192.168.1.51:22, bypassing bastion (10.10.0.5) | Zeek conn.log |

## 8. Verdict
- [x] Benign True Positive — Activity confirmed but authorized/expected
  (NOTE: In this lab walkthrough, this was a deliberately simulated test
  connection, not a real intrusion. In a production hunt, this verdict box
  would instead be checked as True Positive pending further IR escalation,
  UNLESS the finding is cross-referenced against a documented change ticket.)

## 9. Response Actions Taken
- Verified simulated nature of the test connection; no IR escalation required for lab exercise.
- In production: would immediately cross-reference against change management records,
  and if unauthorized, proceed to credential rotation and host isolation per IR process.

## 10. Detection Engineering Follow-Up
- **Should this become a permanent Sigma rule?** Yes
- **If yes, link to Sigma rule PR/file:** Part 5, `sigma-rules/ssh-bastion-bypass.yml`
- **Gaps in telemetry identified:** Need automated daily baseline regeneration (currently manual
  simulation) - recommend a scheduled job maintaining a rolling 30-day host-pairing database.

## 11. Lessons Learned / Notes for Future Hunts
- The combination of "bypasses known chokepoint" + "novel pairing" is a much stronger signal
  than either condition alone - avoid alerting on bastion-bypass alone, as legitimate
  exceptions exist and would cause excessive false positives.
- Beaconing detection (CoV method) requires environment-specific tuning before production use.
```

> **Blockquote — Core Principle, Revisited:** Notice the Verdict in Section 8 required **judgment**, not just query output — the query tells you *what happened*, but only cross-referencing against organizational context (change tickets, known admin workflows) tells you *whether it's actually bad*. This is exactly why threat hunting remains a human discipline even with excellent tooling: the tools narrow millions of events down to a handful of specific, explainable findings — but the final verdict is yours to make.

---

## 4.8 Chapter Summary — What You Now Have

- [ ] A validated ad-hoc `awk` pipeline and a production-quality Python script (`hunt_ssh_bastion_bypass.py`) executing the exact bastion-bypass detection named in Part 1's hypothesis.
- [ ] A working baselining script (`hunt_rare_host_pairings.py`) that distinguishes "never seen before" host pairings from routine, repeated administrative traffic — turning a single event into a properly contextualized finding.
- [ ] A statistical DNS beaconing detector (`hunt_dns_beaconing.py`) using coefficient-of-variation analysis to flag machine-regular check-in patterns, with explicit understanding of its jitter-evasion limitation.
- [ ] An `awk`-based session duration/volume outlier baseline for SSH connections, laying groundwork for exfiltration detection.
- [ ] **HUNT-2024-001 — fully closed out**, from a Part 1 hypothesis through Part 4 execution, with a documented verdict and an explicit hand-off to Part 5 for permanent automation.

> **Blockquote — Bridge to Part 5:** We have now manually executed two confirmed, reusable detection patterns: the web shell process-ancestry hunt (Part 3) and the SSH bastion-bypass + novel-pairing hunt (Part 4). Both hunt reports explicitly flagged themselves for Sigma promotion in their "Detection Engineering Follow-Up" sections. Manually re-running these Python scripts and VQL queries every single day, forever, does not scale and relies on a human remembering to do it. Part 5 closes the loop: we convert one of these hunts into **Sigma** — a vendor-agnostic detection rule format — so it runs automatically, permanently, without you ever having to type these commands again.

**Proceed to Part 5: Operationalizing the Hunt (Sigma Rules & Detection Engineering).**
