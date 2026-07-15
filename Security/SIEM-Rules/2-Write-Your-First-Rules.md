# Part 2: Writing Your First Rules — KQL vs. SPL vs. Lucene

*(Builds directly on Part 1's normalized ECS/CIM field names — `source.ip`/`src`, `user.name`/`user`, `event.outcome`/`action` — and Part 0's Docker sandbox. If you haven't completed those, do so first.)*

## Why This Part Exists

Analogy: three chefs in three different countries can all make the exact same dish — say, a tomato sauce — but one writes the recipe in grams, one in cups, one in ounces. The *technique* (simmer, reduce, season) is identical; only the *units and phrasing* differ. Splunk's SPL, Microsoft Sentinel's KQL, and Elasticsearch's Lucene syntax are exactly this: three different "recipe languages" for asking the same underlying question — *"show me events matching this condition."* Once you see the same brute-force logic expressed in all three, you stop being a "Splunk person" or a "Sentinel person" and become a detection engineer who happens to be fluent in multiple dialects.

**MITRE ATT&CK Mapping for this part:** T1110 (Brute Force), including sub-techniques T1110.001 (Password Guessing) and T1110.003 (Password Spraying).

---

## Step 2.1 — Create the Part 2 Workspace

**The Target:** `siem-mastery-series/part-2-first-rules/` — a fresh folder alongside Part 1's, per the shared project root from Part 0.

**The Concept:** Same "one room per topic, one house for the whole series" structure established in Part 0 — Part 2 gets its own room, but lives in the same house so nothing has to be reinstalled.

**The Implementation:**

```bash
cd siem-mastery-series
mkdir part-2-first-rules
cd part-2-first-rules
```

**The Verification:**

```bash
pwd
```

Expected output ends with:

```
siem-mastery-series/part-2-first-rules
```

---

## Step 2.2 — Generate a Realistic Test Dataset

**The Target:** `siem-mastery-series/part-2-first-rules/generate_brute_force_dataset.py` — a script that produces one consistent dataset in three formats: NDJSON for Elasticsearch, CSV for Splunk, and a KQL literal for Sentinel/Azure Data Explorer.

**The Concept:** Think of this like a **mock crime scene** built by a police training academy — real enough to practice on, controlled enough that instructors know exactly what "correct" looks like. We hand-craft four scenarios: a real single-account brute force, a real password spray, a benign human typo, and a **noisy-but-innocent service account** (this last one is the seed for the "Tuning & False Positives" section later — a good detection engineer always builds their test data to include false-positive traps, not just attacks).

In a real pipeline, this data would flow continuously out of Part 1's `normalize.py` as raw XML is collected. We generate it directly here so this part can focus entirely on the query languages, not re-parsing XML.

**The Implementation:**

**File: `siem-mastery-series/part-2-first-rules/generate_brute_force_dataset.py`**

```python
"""
generate_brute_force_dataset.py

Produces a synthetic but realistic authentication dataset covering four
scenarios inside one 10-minute window, used to test the Brute Force (T1110)
detection rule in Splunk SPL, Sentinel KQL, and raw Lucene filtering.

Outputs:
  - dataset_ecs.ndjson   -> Elasticsearch bulk-ingest format (ECS fields)
  - dataset_cim.csv      -> Splunk-ingestible CSV (CIM fields)
  - dataset_kql.txt      -> KQL `datatable` literal for offline Sentinel/ADX testing
"""
import csv
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent
BASE_TIME = datetime(2024, 6, 20, 14, 20, 0, tzinfo=timezone.utc)


def iso(seconds_offset: int) -> str:
    """Converts a relative offset in seconds into a full ISO-8601 UTC timestamp."""
    return (BASE_TIME + timedelta(seconds=seconds_offset)).isoformat().replace("+00:00", "Z")


def build_events() -> list[dict]:
    events: list[dict] = []

    # --- Scenario A: classic single-account brute force (SHOULD ALERT) ---
    # One external IP hammering ONE username with rapid failed logins.
    for i in range(6):
        events.append({
            "timestamp": iso(i * 40),
            "event_code": "4625",
            "outcome": "failure",
            "src": "198.51.100.23",
            "src_port": 51300 + i,
            "user": "jdoe",
            "dest": "WIN-DC01.corp.local",
            "logon_type": "3",
        })

    # --- Scenario B: password spray (SHOULD ALERT) ---
    # One external IP, ONE failed attempt each against FIVE different users --
    # a different attack shape than Scenario A, even though the volume
    # (5+ failures) looks similar at first glance.
    spray_users = ["asmith2", "bwayne", "ctate", "dking", "efoster"]
    for i, user in enumerate(spray_users):
        events.append({
            "timestamp": iso(60 + i * 30),
            "event_code": "4625",
            "outcome": "failure",
            "src": "198.51.100.77",
            "src_port": 52000 + i,
            "user": user,
            "dest": "WIN-DC01.corp.local",
            "logon_type": "3",
        })

    # --- Scenario C: benign human typo (SHOULD NOT ALERT) ---
    # Internal workstation, 2 failed logins then a success -- normal human
    # error, well under any reasonable threshold.
    for i in range(2):
        events.append({
            "timestamp": iso(150 + i * 20),
            "event_code": "4625",
            "outcome": "failure",
            "src": "10.1.2.50",
            "src_port": 53000 + i,
            "user": "asmith",
            "dest": "WIN-DC01.corp.local",
            "logon_type": "3",
        })
    events.append({
        "timestamp": iso(200),
        "event_code": "4624",
        "outcome": "success",
        "src": "10.1.2.50",
        "src_port": 53010,
        "user": "asmith",
        "dest": "WIN-DC01.corp.local",
        "logon_type": "3",
    })

    # --- Scenario D: noisy-but-benign service account (TUNING CANDIDATE) ---
    # An internal backup service with an expired password, hammering the
    # threshold purely through broken automation, not an attacker. This is
    # exactly the kind of false positive the "Tuning" section addresses.
    for i in range(7):
        events.append({
            "timestamp": iso(100 + i * 25),
            "event_code": "4625",
            "outcome": "failure",
            "src": "10.1.2.99",
            "src_port": 54000 + i,
            "user": "svc_backup",
            "dest": "WIN-FILE02.corp.local",
            "logon_type": "3",
        })

    return events


def write_ecs_ndjson(events: list[dict], path: Path) -> None:
    """Writes Elasticsearch's `_bulk` API format: one metadata line followed
    by one document line, repeated per event."""
    with path.open("w") as f:
        for idx, ev in enumerate(events):
            action_line = {"index": {"_index": "siem-lab-logs", "_id": f"evt-{idx}"}}
            source_doc = {
                "@timestamp": ev["timestamp"],
                "event": {"code": ev["event_code"], "outcome": ev["outcome"]},
                "source": {"ip": ev["src"], "port": ev["src_port"]},
                "user": {"name": ev["user"]},
                "host": {"name": ev["dest"]},
                "winlog": {"logon": {"type": ev["logon_type"]}},
            }
            f.write(json.dumps(action_line) + "\n")
            f.write(json.dumps(source_doc) + "\n")


def write_cim_csv(events: list[dict], path: Path) -> None:
    """Writes a flat CSV using CIM field names, ready for Splunk's
    'Add Data > Upload' wizard."""
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(
            f, fieldnames=["_time", "src", "src_port", "user", "dest", "logon_type", "action"]
        )
        writer.writeheader()
        for ev in events:
            writer.writerow({
                "_time": ev["timestamp"],
                "src": ev["src"],
                "src_port": ev["src_port"],
                "user": ev["user"],
                "dest": ev["dest"],
                "logon_type": ev["logon_type"],
                "action": "success" if ev["outcome"] == "success" else "failure",
            })


def write_kql_datatable(events: list[dict], path: Path) -> None:
    """Writes a KQL `let ... = datatable(...)` literal -- this lets us test
    real KQL logic without needing a live Sentinel workspace, by pasting
    this block directly into Azure Data Explorer's free query editor."""
    rows = []
    for ev in events:
        # AAD sign-in logs use "0" for success and a non-zero code for any
        # failure reason; 50126 is the real code for "invalid credentials".
        result_type = "0" if ev["outcome"] == "success" else "50126"
        rows.append(
            f'    datetime({ev["timestamp"]}), "{ev["user"]}", "{ev["src"]}", '
            f'"{ev["dest"]}", "{result_type}"'
        )
    body = ",\n".join(rows)
    literal = (
        "let SignInEvents = datatable(TimeGenerated: datetime, UserPrincipalName: string, "
        "IPAddress: string, Dest: string, ResultType: string) [\n"
        f"{body}\n];"
    )
    path.write_text(literal + "\n")


if __name__ == "__main__":
    events = build_events()
    write_ecs_ndjson(events, OUTPUT_DIR / "dataset_ecs.ndjson")
    write_cim_csv(events, OUTPUT_DIR / "dataset_cim.csv")
    write_kql_datatable(events, OUTPUT_DIR / "dataset_kql.txt")
    print(f"Generated {len(events)} events across 4 scenarios.")
    print("Wrote: dataset_ecs.ndjson, dataset_cim.csv, dataset_kql.txt")
```

Run it:

```bash
python3 generate_brute_force_dataset.py
```

**The Verification:**

```
Generated 21 events across 4 scenarios.
Wrote: dataset_ecs.ndjson, dataset_cim.csv, dataset_kql.txt
```

```bash
ls -la
wc -l dataset_cim.csv     # expect 22 (21 events + 1 header row)
```

---

## Step 2.3 — Load Data Into Elasticsearch (for Lucene)

**The Target:** All 21 events indexed into the `siem-lab-logs` index in the Elasticsearch container from Part 0.

**The Concept:** Elasticsearch's `_bulk` API is like a **mail sorting machine** — instead of mailing 21 separate letters (slow, one HTTP request each), you hand the machine one big stack with sorting instructions already attached to each item, and it files all 21 in a single pass.

**The Implementation:**

Make sure your sandbox from Part 0 is running:

```bash
cd ../  # back to siem-mastery-series/
docker compose up -d
cd part-2-first-rules
```

Bulk-load the data:

```bash
curl -s -H "Content-Type: application/x-ndjson" \
  -XPOST "http://localhost:9200/siem-lab-logs/_bulk" \
  --data-binary @dataset_ecs.ndjson | python3 -m json.tool | tail -20
```

**The Verification:**

```bash
curl -s "http://localhost:9200/siem-lab-logs/_count"
```

Expected output:

```json
{"count":21,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0}}
```

If `count` is not `21`, re-run the bulk load — a partial index usually means the container wasn't fully warmed up yet (see Part 0, Step 0.5).

---

## Step 2.4 — Lucene Syntax Basics (via Kibana)

**The Target:** A working filtered view in Kibana Discover using raw Lucene query syntax.

**The Concept:** Lucene syntax is the oldest and most "bare metal" of the three languages — it's essentially `field:value` pairs joined by `AND`/`OR`/`NOT`. Think of it like the terse shorthand on a police radio ("10-4, suspect vehicle, blue sedan") — efficient, but limited: Lucene alone can't calculate counts or averages, it can only **filter**, not **aggregate**. That's an important, deliberate limitation to understand before we move to SPL and KQL, which can do both.

**The Implementation:**

1. Open `http://localhost:5601` (Kibana, from Part 0).
2. Go to **Stack Management → Index Patterns/Data Views → Create data view**.
   - Name: `siem-lab-logs`
   - Index pattern: `siem-lab-logs*`
   - Timestamp field: `@timestamp`
3. Go to **Discover**, select the `siem-lab-logs` data view.
4. In the query bar, switch the language toggle (left of the search bar) to **Lucene**.
5. Enter:

```
event.outcome:failure AND source.ip:"198.51.100.23"
```

**The Verification:** The results table should show exactly **6 rows** — all from Scenario A (`user.name: jdoe`). Now try:

```
event.outcome:failure AND source.ip:"10.1.2.99"
```

Expected: **7 rows** — this is Scenario D, our noisy-but-benign service account. Keep this number in mind; we'll revisit it in the Tuning section.

---

## Step 2.5 — Load Data Into Splunk (for SPL)

**The Target:** All 21 events searchable inside a Splunk index named `siem_lab`.

**The Concept:** Same mail-sorting idea as Step 2.3, but through Splunk's upload wizard instead of a bulk API call — the human-friendly, point-and-click version of the same task.

**The Implementation:**

*(Requires the optional Splunk Free/trial instance from Part 0's prerequisites checklist. If you skipped it, install it now from `https://www.splunk.com/en_us/download.html`.)*

1. Log into Splunk (typically `http://localhost:8000`).
2. Go to **Settings → Indexes → New Index**. Name it `siem_lab`, leave defaults, click **Save**.
3. Go to **Settings → Add Data → Upload**.
4. Select `dataset_cim.csv` from your `part-2-first-rules` folder → **Next**.
5. Under **Set Source Type**, choose **csv**. Splunk should auto-detect the `_time` column as the timestamp — confirm the preview shows correct dates (`2024-06-20`), not the upload date.
6. Under **Input Settings**, set the destination index to `siem_lab` → **Review** → **Submit**.

**The Verification:**

In the Splunk search bar, run:

```spl
index=siem_lab
| stats count
```

Expected: **21**.

Then run:

```spl
index=siem_lab action=failure src="198.51.100.23"
| table _time, src, user, dest, action
```

Expected: a table with exactly **6 rows**, all `user=jdoe`.

---

## Step 2.6 — KQL Syntax Basics (via Azure Data Explorer, No Sentinel Required)

**The Target:** The same filter, expressed in KQL, verified without needing a paid or fully-provisioned Sentinel workspace.

**The Concept:** Real Sentinel detection rules query live tables like `SigninLogs`. But you don't need a live Sentinel deployment just to *learn KQL syntax* — Microsoft provides a **free Azure Data Explorer (ADX) cluster** that runs the exact same KQL engine in your browser, for free, with no Azure subscription required. We use KQL's `datatable` operator to paste in our own literal test rows — think of it as writing a specific test case directly into a unit test, instead of provisioning an entire staging server just to test one function.

**The Implementation:**

1. Go to `https://dataexplorer.azure.com/freecluster` and sign in with any Microsoft account (free).
2. Create a free cluster/database if prompted (one-time setup, a few minutes).
3. Open a new query tab and paste the **entire contents** of `dataset_kql.txt`, followed immediately by this query:

```kql
SignInEvents
| where ResultType != "0"
| where IPAddress == "198.51.100.23"
| project TimeGenerated, UserPrincipalName, IPAddress, Dest, ResultType
```

4. Click **Run**.

**The Verification:** You should see exactly **6 rows** returned, all with `UserPrincipalName: jdoe` and `IPAddress: 198.51.100.23` — matching Steps 2.4 and 2.5 exactly. Three different query languages, three different engines, same answer. That consistency check is the entire point of this step.

---

## Step 2.7 — Build the Full Brute Force Detection in Splunk SPL

**The Target:** A complete, threshold-based SPL detection rule that flags any source IP with 5+ failed logons in a 10-minute window.

**The Concept:** Filtering (Steps 2.4–2.6) answers "show me events matching X." A **detection rule** answers a harder question: "show me *groups* of events whose combined *count* crosses a dangerous threshold." This requires **aggregation** — grouping many rows into one summary row per attacker IP, the same way a bank statement doesn't show every card swipe individually when flagging "5 transactions in 60 seconds" as suspicious — it groups, counts, and compares against a limit.

**The Implementation:**

**File: `siem-mastery-series/part-2-first-rules/brute_force_detection.spl`**

```spl
index=siem_lab action=failure
| bucket _time span=10m
| stats count as failed_attempts, dc(user) as distinct_users, min(_time) as first_attempt, max(_time) as last_attempt by src, _time
| where failed_attempts >= 5
| eval attack_pattern=if(distinct_users >= 3, "Password Spray (T1110.003)", "Single-Account Brute Force (T1110.001)")
| eval first_attempt=strftime(first_attempt, "%Y-%m-%d %H:%M:%S")
| eval last_attempt=strftime(last_attempt, "%Y-%m-%d %H:%M:%S")
| table first_attempt, last_attempt, src, failed_attempts, distinct_users, attack_pattern
```

**Line-by-line intent:**
- `bucket _time span=10m` — rounds every event's timestamp down to the nearest 10-minute mark, creating fixed windows to group by (Part 3 replaces this with true sliding windows).
- `stats ... by src, _time` — one summary row per unique (attacker IP, time bucket) pair — this is the "bank statement" grouping described above.
- `dc(user)` — **distinct count** of usernames targeted; this single field is what lets us tell a focused brute force apart from a password spray.
- `where failed_attempts >= 5` — the actual threshold. This number isn't arbitrary — see the Tuning section below for how to choose it.
- `eval attack_pattern=if(...)` — labels the *shape* of the attack based on `distinct_users`, directly mapping to two different MITRE sub-techniques.

**The Verification:**

Run the search in Splunk (paste the file's contents into the search bar):

```spl
index=siem_lab action=failure
| bucket _time span=10m
| stats count as failed_attempts, dc(user) as distinct_users, min(_time) as first_attempt, max(_time) as last_attempt by src, _time
| where failed_attempts >= 5
| eval attack_pattern=if(distinct_users >= 3, "Password Spray (T1110.003)", "Single-Account Brute Force (T1110.001)")
| eval first_attempt=strftime(first_attempt, "%Y-%m-%d %H:%M:%S")
| eval last_attempt=strftime(last_attempt, "%Y-%m-%d %H:%M:%S")
| table first_attempt, last_attempt, src, failed_attempts, distinct_users, attack_pattern
```

Expected output (3 rows):

| first_attempt | last_attempt | src | failed_attempts | distinct_users | attack_pattern |
|---|---|---|---|---|---|
| 2024-06-20 14:20:00 | 2024-06-20 14:23:20 | 198.51.100.23 | 6 | 1 | Single-Account Brute Force (T1110.001) |
| 2024-06-20 14:21:00 | 2024-06-20 14:23:00 | 198.51.100.77 | 5 | 5 | Password Spray (T1110.003) |
| 2024-06-20 14:21:40 | 2024-06-20 14:24:10 | 10.1.2.99 | 7 | 1 | Single-Account Brute Force (T1110.001) |

Notice `10.1.2.99` (our benign backup service, Scenario D) shows up here as a false positive — **this is expected at this stage**, and exactly what the Tuning section fixes next.

---

## Step 2.8 — Build the Same Detection in Sentinel KQL

**The Target:** A KQL equivalent of Step 2.7, runnable against the same `dataset_kql.txt` literal in Azure Data Explorer, or against real `SigninLogs` in a live Sentinel workspace.

**The Concept:** Same logic, different verbs — `summarize` is KQL's word for SPL's `stats`, and `bin()` is KQL's word for SPL's `bucket`. Once you recognize these as *synonyms*, not different concepts, switching between platforms stops being intimidating.

**The Implementation:**

**File: `siem-mastery-series/part-2-first-rules/brute_force_detection.kql`**

```kql
let LookbackWindow = 10m;
let FailureThreshold = 5;
SignInEvents
| where ResultType != "0" // any non-zero AAD result code indicates a failure
| summarize
    FailedAttempts = count(),
    DistinctUsers = dcount(UserPrincipalName),
    FirstAttempt = min(TimeGenerated),
    LastAttempt = max(TimeGenerated)
    by IPAddress, bin(TimeGenerated, LookbackWindow)
| where FailedAttempts >= FailureThreshold
| extend AttackPattern = iff(DistinctUsers >= 3, "Password Spray (T1110.003)", "Single-Account Brute Force (T1110.001)")
| project FirstAttempt, LastAttempt, IPAddress, FailedAttempts, DistinctUsers, AttackPattern
```

**Line-by-line intent:**
- `let LookbackWindow = 10m;` / `let FailureThreshold = 5;` — KQL lets you name constants up front, like variables in code — makes the threshold easy to find and tune later without hunting through the query body.
- `bin(TimeGenerated, LookbackWindow)` — KQL's version of SPL's `bucket`, rounding timestamps into fixed windows.
- `dcount(...)` — KQL's version of SPL's `dc(...)`.
- `iff(...)` — KQL's version of SPL's `if(...)` (note the double "f" — a common typo source when switching languages).

**The Verification:**

In your ADX free cluster query tab, paste `dataset_kql.txt`'s contents followed by the query above, then **Run**.

Expected output (3 rows, matching Step 2.7 exactly):

| FirstAttempt | LastAttempt | IPAddress | FailedAttempts | DistinctUsers | AttackPattern |
|---|---|---|---|---|---|
| 2024-06-20 14:20:00 | 2024-06-20 14:23:20 | 198.51.100.23 | 6 | 1 | Single-Account Brute Force (T1110.001) |
| 2024-06-20 14:21:00 | 2024-06-20 14:23:00 | 198.51.100.77 | 5 | 5 | Password Spray (T1110.003) |
| 2024-06-20 14:21:40 | 2024-06-20 14:24:10 | 10.1.2.99 | 7 | 1 | Single-Account Brute Force (T1110.001) |

If deploying this against a real Sentinel workspace instead of the offline literal, replace the `SignInEvents` reference with the real `SigninLogs` table and adjust column names per Appendix A's schema (`SigninLogs`, `UserPrincipalName`, `IPAddress`, `ResultType` are already correct real column names in that table).

---

## Step 2.9 — Tuning & False Positives

**The Target:** A refined version of both rules that removes the `10.1.2.99` false positive without weakening real detection.

**The Concept:** A smoke detector that also triggers on steam from your shower isn't "more sensitive" — it's *miscalibrated*. Tuning means adding specific, documented exceptions for **known** benign automation, not lowering the threshold (which would just make the rule blind to real attacks too).

**Root cause:** `svc_backup` is a legitimate internal service account with an expired password on a scheduled task — internal source IP, single consistent username, no external exposure. A real attacker profile (Scenario A) shares the "single user" shape but comes from an **external** IP.

**Recommended tuning approach (apply in this order):**

1. **Scope to external IPs only** — the single highest-value fix here, since both Scenario A and B originate outside the corporate network:

```spl
index=siem_lab action=failure
| where NOT cidrmatch("10.0.0.0/8", src)   " excludes internal RFC1918 space
| bucket _time span=10m
| stats count as failed_attempts, dc(user) as distinct_users by src, _time
| where failed_attempts >= 5
```

```kql
SignInEvents
| where ResultType != "0"
| where IPAddress !startswith "10."   // excludes internal RFC1918 space (simplified for demo data)
| summarize FailedAttempts = count(), DistinctUsers = dcount(UserPrincipalName) by IPAddress, bin(TimeGenerated, 10m)
| where FailedAttempts >= 5
```

2. **Maintain an explicit service-account exception list** as a lookup table (SPL) or watchlist (Sentinel) — never hardcode exceptions inline, since that list changes often and should be owned by IT, not buried in query logic:

```spl
| lookup known_service_accounts.csv user OUTPUT is_known_service_account
| where is_known_service_account != "true"
```

3. **Document every exception with an expiration/review date** — an exception added today to silence `svc_backup` should be reviewed in 90 days, not left forever; stale exceptions are a common way real attackers hide (by compromising an already-excluded account).

**Testing procedure (safe, benign trigger):**

On a lab/test Windows machine only — never on production infrastructure — you can safely reproduce a benign version of Scenario A's shape using an intentionally wrong password against your own test account:

```powershell
# Run this 5+ times within 10 minutes from the SAME test machine,
# against a disposable test account you control -- this safely
# generates real 4625 events without touching any real credentials.
net use \\localhost\IPC$ /user:testlabaccount WrongPassword123!
```

Each failed attempt generates a genuine local 4625 event, letting you validate that your real log pipeline (Sysmon/Windows Event Forwarding → SIEM) actually delivers and triggers the rule end-to-end — not just that the query syntax is correct in isolation.

---

## Step 2.10 — Final Verification: Cross-Platform Consistency Check

**The Target:** Confirm all three platforms agree after tuning.

**The Concept:** The final "taste test" — three chefs, three kitchens, same finished dish.

**The Implementation & Verification:**

Re-run the Step 2.9 tuned SPL query in Splunk and tuned KQL query in ADX. Both should now return **exactly 2 rows** (Scenarios A and B only — `10.1.2.99` is gone because it's internal):

| src/IPAddress | failed_attempts | distinct_users | attack_pattern |
|---|---|---|---|
| 198.51.100.23 | 6 | 1 | Single-Account Brute Force (T1110.001) |
| 198.51.100.77 | 5 | 5 | Password Spray (T1110.003) |

If you see this on both platforms, Part 2 is complete — you've built the same validated detection logic twice, in two industry-standard languages, and proven they agree.

---

# Reference Section — Part 2

## R2.1 — Lucene vs. SPL vs. KQL: Side-by-Side Cheat Sheet

| Task | Lucene | SPL (Splunk) | KQL (Kusto/Sentinel) |
|---|---|---|---|
| Exact field match | `field:value` | `field=value` | `field == "value"` |
| Wildcard/contains | `field:*value*` | `field="*value*"` | `field contains "value"` |
| Logical AND | `A AND B` | `A B` (implicit) or `A AND B` | `A and B` |
| Logical OR | `A OR B` | `A OR B` | `A or B` |
| Negation | `NOT field:value` | `NOT field=value` | `field != "value"` |
| Group & count | *(not supported — filtering only)* | `stats count by field` | `summarize count() by field` |
| Distinct count | *(not supported)* | `dc(field)` | `dcount(field)` |
| Time bucketing | *(not supported)* | `bucket _time span=10m` | `bin(TimeGenerated, 10m)` |
| Conditional/if-else | *(not supported)* | `if(condition, a, b)` | `iff(condition, a, b)` |
| Rename field | *(n/a)* | `... as newname` | `NewName = ...` |
| Comment | *(n/a)* | `` `` (backtick comment) or `#` | `//` |

## R2.2 — MITRE ATT&CK: T1110 Sub-Techniques Referenced

| Sub-technique | ID | Signature Pattern | Detected By |
|---|---|---|---|
| Password Guessing | T1110.001 | Many attempts, one username | `distinct_users == 1` branch |
| Password Cracking | T1110.002 | Offline — not visible in auth logs | Not detectable via this rule |
| Password Spraying | T1110.003 | Few attempts per user, many usernames | `distinct_users >= 3` branch |
| Credential Stuffing | T1110.004 | Valid-looking creds tried across many accounts, often lower failure rate | Requires baseline comparison — introduced in Part 3 |

## R2.3 — Raw Log Sample: Real Azure AD `SigninLogs` Shape

*(Provided so you can verify your own field mappings against the real production schema, not just our synthetic test literal.)*

```json
{
  "TimeGenerated": "2024-06-20T14:20:00.0000000Z",
  "UserPrincipalName": "jdoe@corp.onmicrosoft.com",
  "IPAddress": "198.51.100.23",
  "AppDisplayName": "Office 365 Exchange Online",
  "ResultType": "50126",
  "ResultDescription": "Invalid username or password",
  "Location": {
    "city": "Ashburn",
    "countryOrRegion": "US"
  },
  "DeviceDetail": {
    "browser": "Chrome 125.0",
    "operatingSystem": "Windows 10"
  }
}
```

## R2.4 — Why Thresholds Aren't One-Size-Fits-All

A threshold of "5 failures in 10 minutes" is a reasonable *starting point*, not a universal constant. Before deploying any brute-force rule in a real environment:

- Run the aggregation query (without the `where failed_attempts >= 5` filter) over 7–30 days of historical data first.
- Look at the natural distribution — if legitimate users regularly hit 4 failures during password rotations, your threshold needs to sit meaningfully above that baseline, not just above zero.
- Re-check the threshold quarterly — user population, VPN configurations, and MFA policies all shift the "normal" baseline over time.

## R2.5 — Full File Tree After Part 2

```
siem-mastery-series/
├── .venv/
├── docker-compose.yml
├── requirements.txt
├── part-1-log-anatomy/
│   ├── explore.py
│   ├── normalize.py
│   └── raw_logs/
│       ├── 4624_successful_logon.xml
│       ├── 4625_failed_logon.xml
│       └── sysmon_event_1_process_creation.xml
└── part-2-first-rules/
    ├── generate_brute_force_dataset.py
    ├── dataset_ecs.ndjson
    ├── dataset_cim.csv
    ├── dataset_kql.txt
    ├── brute_force_detection.spl
    └── brute_force_detection.kql
```

---

Ready for **Part 3: Advanced Correlation & State** whenever you are — it picks up exactly where the Tuning section left off, chaining Scenario A's failed logons to an *immediately following successful login from the same IP* using sliding time windows and state tables, plus a full build-out of Appendix A's **MFA Fatigue (T1621)** rule.
