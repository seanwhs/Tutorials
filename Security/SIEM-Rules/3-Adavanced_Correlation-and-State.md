# Part 3: Advanced Correlation & State — The Logic Engine

*(Builds directly on Part 2's SPL/KQL fluency and Part 0's Docker/Splunk sandbox. If you haven't completed those, do so first.)*

## Why This Part Exists

Analogy: Part 2's brute-force rule was like a bouncer who only counts how many times someone tried the door handle. That catches noisy attackers, but it misses the scarier case: someone who tries the handle five times, fails, *and then gets in.* A good bouncer doesn't just count failed attempts — they **remember** who recently failed, so that if that same person later succeeds, alarm bells go off immediately. That memory-plus-comparison is what "state" means in detection engineering, and the rolling time window they use to decide "recently" is a **sliding time window**. This part builds exactly that: a rule that correlates a failed-login sequence with an *immediately following* success from the same IP — a far higher-fidelity signal than either event alone.

**MITRE ATT&CK Mapping for this part:** T1110 (Brute Force) escalating to successful **Initial Access**, plus a full build of Appendix A's **T1621 (Multi-Factor Authentication Request Generation)** — MFA fatigue/spamming.

---

## Step 3.1 — Create the Part 3 Workspace

**The Target:** `siem-mastery-series/part-3-correlation-state/`

**The Concept:** Same "one room, one house" pattern from Parts 0–2.

**The Implementation:**

```bash
cd siem-mastery-series
mkdir part-3-correlation-state
cd part-3-correlation-state
```

**The Verification:**

```bash
pwd
```

Expected output ends with:

```
siem-mastery-series/part-3-correlation-state
```

---

## Step 3.2 — The Concept: State Tables and Sliding Windows

**The Target:** No code yet — the mental model this entire part depends on.

**The Concept:**

- A **state table** is the bouncer's mental notebook — a temporary record of "who failed, when, and from where," kept around just long enough to compare against future events.
- A **sliding time window** is the rule "only remember the last 15 minutes" — old entries fall out of the notebook automatically so the bouncer isn't comparing today's login attempt against something that happened three weeks ago.

Part 2's rule had *no* memory across event types — it only ever looked at failures, in isolation, inside one fixed 10-minute bucket. Today's rule needs to answer a two-part question that spans event types: **"Did this (IP, user) pair fail repeatedly, AND did a success immediately follow?"** That "AND...immediately follow" is correlation, and it requires holding state.

**The Verification:** Confirm you can restate, in your own words, the difference between "count events matching X" (Part 2) and "compare an earlier group of events to a later single event" (this part). If yes, proceed.

---

## Step 3.3 — Generate the Correlation Test Dataset

**The Target:** `siem-mastery-series/part-3-correlation-state/generate_correlation_dataset.py`

**The Concept:** Same "mock crime scene" idea as Part 2, but now with three scenarios specifically designed to test *sequence*, not just *volume*:

- **Scenario E — Successful Brute Force (SHOULD ALERT):** an external IP fails 5 times against one account, then succeeds 90 seconds later. This is the highest-fidelity signal in this entire part — a real compromise, not just noisy scanning.
- **Scenario F — Same Shape, Internal IP (SHOULD NOT ALERT):** identical failure/success pattern, but from an internal IP — deliberately built to prove that *only* the external-IP filter (not the counting logic) is what saves this from a false positive.
- **Scenario J — The "Low and Slow" Attacker (a deliberate edge case):** 5 failures spread across ~40 minutes, then a success 60 seconds after the last failure. This tests whether our correlation window is wide enough to catch a patient attacker — spoiler: it exposes a real, important limitation we'll discuss explicitly in Step 3.6.

**The Implementation:**

**File: `siem-mastery-series/part-3-correlation-state/generate_correlation_dataset.py`**

```python
"""
generate_correlation_dataset.py

Produces a synthetic authentication dataset built specifically to test
SEQUENCE-based correlation (failures followed by a success), not just
volume-based thresholds. Three scenarios:

  E - Successful brute force: external IP, 5 failures then a success (ALERT)
  F - Same shape, internal IP (NO ALERT -- proves IP filter, not count, saves us)
  J - "Low and slow": failures spread across 40 minutes (tests window limits)

Outputs:
  - dataset_ecs.ndjson   -> Elasticsearch bulk-ingest format (ECS fields)
  - dataset_cim.csv      -> Splunk-ingestible CSV (CIM fields)
  - dataset_kql.txt      -> KQL `datatable` literal for offline testing
"""
import csv
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent
BASE_TIME = datetime(2024, 6, 25, 9, 0, 0, tzinfo=timezone.utc)


def iso(seconds_offset: int) -> str:
    return (BASE_TIME + timedelta(seconds=seconds_offset)).isoformat().replace("+00:00", "Z")


def build_events() -> list[dict]:
    events: list[dict] = []

    # --- Scenario E: successful brute force (SHOULD ALERT) ---
    # 5 failures, 45s apart, then a success 90s after the last failure.
    # Total span (first failure -> success) = 270s = 4.5 minutes.
    fail_offsets_e = [0, 45, 90, 135, 180]
    for offset in fail_offsets_e:
        events.append({
            "timestamp": iso(offset), "event_code": "4625", "outcome": "failure",
            "src": "203.0.113.140", "user": "khall", "dest": "WIN-DC01.corp.local",
        })
    events.append({
        "timestamp": iso(270), "event_code": "4624", "outcome": "success",
        "src": "203.0.113.140", "user": "khall", "dest": "WIN-DC01.corp.local",
    })

    # --- Scenario F: identical shape, internal IP (SHOULD NOT ALERT) ---
    fail_offsets_f = [400, 445, 490, 535, 580]
    for offset in fail_offsets_f:
        events.append({
            "timestamp": iso(offset), "event_code": "4625", "outcome": "failure",
            "src": "10.1.5.20", "user": "mgarcia", "dest": "WIN-DC01.corp.local",
        })
    events.append({
        "timestamp": iso(670), "event_code": "4624", "outcome": "success",
        "src": "10.1.5.20", "user": "mgarcia", "dest": "WIN-DC01.corp.local",
    })

    # --- Scenario J: "low and slow" attacker (edge case, discussed in Step 3.6) ---
    # 5 failures spread ~10 minutes apart (40 minutes total), success 60s after
    # the last failure. Total span (first failure -> success) = ~41 minutes.
    fail_offsets_j = [1000, 1600, 2200, 2800, 3400]
    for offset in fail_offsets_j:
        events.append({
            "timestamp": iso(offset), "event_code": "4625", "outcome": "failure",
            "src": "203.0.113.201", "user": "pchen", "dest": "WIN-DC01.corp.local",
        })
    events.append({
        "timestamp": iso(3460), "event_code": "4624", "outcome": "success",
        "src": "203.0.113.201", "user": "pchen", "dest": "WIN-DC01.corp.local",
    })

    return events


def write_ecs_ndjson(events: list[dict], path: Path) -> None:
    with path.open("w") as f:
        for idx, ev in enumerate(events):
            action_line = {"index": {"_index": "siem-lab-corr", "_id": f"evt-{idx}"}}
            source_doc = {
                "@timestamp": ev["timestamp"],
                "event": {"code": ev["event_code"], "outcome": ev["outcome"]},
                "source": {"ip": ev["src"]},
                "user": {"name": ev["user"]},
                "host": {"name": ev["dest"]},
            }
            f.write(json.dumps(action_line) + "\n")
            f.write(json.dumps(source_doc) + "\n")


def write_cim_csv(events: list[dict], path: Path) -> None:
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["_time", "src", "user", "dest", "action"])
        writer.writeheader()
        for ev in events:
            writer.writerow({
                "_time": ev["timestamp"],
                "src": ev["src"],
                "user": ev["user"],
                "dest": ev["dest"],
                "action": "success" if ev["outcome"] == "success" else "failure",
            })


def write_kql_datatable(events: list[dict], path: Path) -> None:
    rows = []
    for ev in events:
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
    print(f"Generated {len(events)} events across 3 correlation scenarios.")
```

Run it:

```bash
python3 generate_correlation_dataset.py
```

**The Verification:**

```
Generated 18 events across 3 correlation scenarios.
```

```bash
wc -l dataset_cim.csv   # expect 19 (18 events + 1 header)
```

---

## Step 3.4 — Load Data Into a Dedicated Splunk Index

**The Target:** A new Splunk index, `siem_lab_corr`, isolated from Part 2's `siem_lab` index.

**The Concept:** Real SOCs separate data by purpose (auth logs, network logs, correlation-test scratch data) the same way a hospital doesn't file X-rays in the same drawer as lab bloodwork — different retention needs, different access controls, different query patterns. We isolate this dataset the same way, so Part 2's IPs never accidentally mix into Part 3's correlation logic.

**The Implementation:**

1. In Splunk: **Settings → Indexes → New Index** → name it `siem_lab_corr` → **Save**.
2. **Settings → Add Data → Upload** → select `dataset_cim.csv` → **Next**.
3. Set source type to **csv**, confirm the timestamp preview correctly shows `2024-06-25` dates.
4. Set destination index to `siem_lab_corr` → **Review** → **Submit**.

**The Verification:**

```spl
index=siem_lab_corr
| stats count
```

Expected: **18**.

---

## Step 3.5 — Build the Correlation Rule in Splunk SPL (`transaction`)

**The Target:** `siem-mastery-series/part-3-correlation-state/brute_force_success_correlation.spl`

**The Concept:** SPL has a purpose-built command for exactly this job: `transaction`. Think of it as literally stapling together every event that shares a common key (here, `src` + `user`) into one folder, as long as the folder's first page starts with a failure, its last page ends with a success, and the whole folder doesn't span longer than a set time limit. That time limit — `maxspan` — **is** the sliding window from Step 3.2, made concrete.

**The Implementation:**

**File: `siem-mastery-series/part-3-correlation-state/brute_force_success_correlation.spl`**

```spl
index=siem_lab_corr
" Exclude internal RFC1918 space -- this is what actually saves Scenario F,
" not the event counting logic (proven in Step 3.7's side-by-side test).
| where NOT cidrmatch("10.0.0.0/8", src)
" transaction staples together every event sharing the same (src, user) pair
" into one grouped record, ONLY IF the group starts with a failure, ends
" with a success, and the ENTIRE group's time span fits inside maxspan.
| transaction src, user startswith=(action="failure") endswith=(action="success") maxspan=15m
" eventcount is auto-generated by transaction: total events stapled together.
| where eventcount >= 6
| eval failed_count = eventcount - 1
| eval attack_pattern = "Successful Brute Force (T1110 -> Initial Access)"
| table _time, src, user, duration, eventcount, failed_count, attack_pattern
```

**The Verification:**

Run the query in Splunk:

```spl
index=siem_lab_corr
| where NOT cidrmatch("10.0.0.0/8", src)
| transaction src, user startswith=(action="failure") endswith=(action="success") maxspan=15m
| where eventcount >= 6
| eval failed_count = eventcount - 1
| eval attack_pattern = "Successful Brute Force (T1110 -> Initial Access)"
| table _time, src, user, duration, eventcount, failed_count, attack_pattern
```

Expected output — **exactly 1 row**:

| _time | src | user | duration | eventcount | failed_count | attack_pattern |
|---|---|---|---|---|---|---|
| 2024-06-25 09:04:30 | 203.0.113.140 | khall | 270 | 6 | 5 | Successful Brute Force (T1110 -> Initial Access) |

Notice **Scenario J (pchen) does not appear.** Keep this in mind — we address exactly why in Step 3.6.

---

## Step 3.6 — Build the Same Correlation in KQL — and a Real Discrepancy

**The Target:** `siem-mastery-series/part-3-correlation-state/brute_force_success_correlation.kql`

**The Concept:** KQL has no direct equivalent of `transaction`, so we build the same idea from two more primitive parts: summarize the failures first (the "state table"), then `join` that summary against successes, checking that the success timestamp falls inside a window *measured from the last failure* — not from the first. This single design difference matters more than it sounds like, as you're about to see.

**The Implementation:**

**File: `siem-mastery-series/part-3-correlation-state/brute_force_success_correlation.kql`**

```kql
let FailureThreshold = 5;
let CorrelationWindow = 15m;
// STATE TABLE: one summary row per (user, IP) that crossed the failure
// threshold, remembering only the LAST failure's timestamp.
let Failures = SignInEvents
| where ResultType != "0"
| where IPAddress !startswith "10."
| summarize FailedAttempts = count(), LastFailure = max(TimeGenerated) by UserPrincipalName, IPAddress
| where FailedAttempts >= FailureThreshold;
let Successes = SignInEvents
| where ResultType == "0"
| project SuccessTime = TimeGenerated, UserPrincipalName, IPAddress;
Failures
| join kind=inner Successes on UserPrincipalName, IPAddress
// The window is measured from LastFailure forward -- NOT from the first
// failure. This is the key design difference from SPL's transaction maxspan.
| where SuccessTime between (LastFailure .. LastFailure + CorrelationWindow)
| extend AttackPattern = "Successful Brute Force (T1110 -> Initial Access)"
| project UserPrincipalName, IPAddress, FailedAttempts, LastFailure, SuccessTime, AttackPattern
```

**The Verification:**

Paste `dataset_kql.txt` followed by the query above into your ADX free cluster (Step 2.6's environment) and run it.

Expected output — **2 rows, not 1**:

| UserPrincipalName | IPAddress | FailedAttempts | LastFailure | SuccessTime | AttackPattern |
|---|---|---|---|---|---|
| khall | 203.0.113.140 | 5 | 09:03:00 | 09:04:30 | Successful Brute Force... |
| pchen | 203.0.113.201 | 5 | 09:56:40 | 09:57:40 | Successful Brute Force... |

### Why These Differ — And Why That's the Real Lesson

This isn't a bug or a mistranslation — it's a genuine semantic difference between two ways of implementing "state":

- **SPL's `transaction maxspan=15m`** caps the span of the *entire* group — from the very first failure all the way to the success. Scenario J's first failure to its success spans ~41 minutes, so `transaction` refuses to staple it into one group at all, and it never reaches the `eventcount >= 6` threshold.
- **Our KQL `join`** only checks the gap between the **last** failure and the success — it doesn't care how long the whole campaign took. Scenario J's last failure and its success are only 60 seconds apart, so it passes easily.

Neither behavior is "wrong" — they're answering subtly different questions: *"was this whole sequence fast?"* versus *"did a success immediately follow the most recent failure, no matter how long the campaign took?"* The second question is arguably the better brute-force indicator, since a patient attacker who fails slowly across 40 minutes and then gets in is at least as dangerous as a noisy one.

**Prove it's a parameter, not a platform limitation** — re-run the SPL query with a wider window:

```spl
index=siem_lab_corr
| where NOT cidrmatch("10.0.0.0/8", src)
| transaction src, user startswith=(action="failure") endswith=(action="success") maxspan=45m
| where eventcount >= 6
| eval failed_count = eventcount - 1
| table _time, src, user, duration, eventcount, failed_count
```

**Verification:** With `maxspan=45m`, Scenario J (`pchen`) now appears too — confirming the discrepancy in Step 3.6 was a **configuration choice**, not a fundamental engine limitation. This is exactly the kind of subtlety a detection engineer needs to reason about explicitly, not something a syntax cheat sheet alone would ever reveal.

---

## Step 3.7 — Tuning & False Positives

**The Target:** Documented guidance for safely running this correlation rule in production.

**The Concept:** Same principle as Part 2 — tune with specific, documented exceptions, never by loosening the core logic.

**Root cause analysis for this rule's likely false positives:**

- **Shared/NAT'd corporate egress IPs:** if many employees exit to the internet through one corporate proxy IP, and one employee mistypes a password while others succeed nearby in time, this rule could pair an unrelated failure with an unrelated success under the *same IP* (though still the same `user`, which limits this significantly — the `user` key in both `transaction ... by src, user` and the KQL `join ... on UserPrincipalName, IPAddress` requires the *same account* to fail and then succeed, which is the main defense here).
- **Password rotation days:** users who just changed their password often fail 1–2 times with the old password before succeeding — usually well under the `>= 6` (5 failures) threshold, but worth widening your historical baseline check (per Part 2's R2.4) after any company-wide password reset.

**Recommended tuning approach:**

1. **Keep the external-IP scope** (already applied) — this is the single highest-value control, since it eliminates nearly all legitimate same-user typo-then-success traffic (Scenario F).
2. **Add a lower secondary alert tier** for 2–4 failures + success from an external IP (below this rule's threshold) routed to a lower-priority queue for trend-watching, rather than raising it to full-severity — avoids both alert fatigue and blind spots.
3. **Cross-reference geolocation** between the failed attempts and the successful login (both platforms support IP-to-geo enrichment) — a success from a wildly different country than the failures is a much stronger signal than IP match alone, since attackers often succeed from a *different* proxy than the one that was brute-forcing.

**Testing procedure (safe, benign trigger):**

```powershell
# Run against a disposable LAB test account only. Deliberately fail 5 times,
# then succeed on the 6th attempt with the correct password -- reproduces
# this rule's exact trigger shape without touching real credentials.
net use \\localhost\IPC$ /user:testlabaccount WrongPassword1!
net use \\localhost\IPC$ /user:testlabaccount WrongPassword2!
net use \\localhost\IPC$ /user:testlabaccount WrongPassword3!
net use \\localhost\IPC$ /user:testlabaccount WrongPassword4!
net use \\localhost\IPC$ /user:testlabaccount WrongPassword5!
net use \\localhost\IPC$ /user:testlabaccount CorrectPasswordHere!
```

---

## Step 3.8 — Full Build-Out: MFA Fatigue Detection (Appendix A)

**The Target:** A fully explained, tested version of the series' Appendix A rule — MFA Spamming/Fatigue detection (T1621).

**The Concept:** This is the *exact same pattern* as Steps 3.5–3.6 (failures followed by a success, correlated by identity), applied to a different log source. Instead of "5 password failures then a success," it's "3+ denied push notifications then one approval" — the human giving in and tapping "Approve" out of sheer annoyance, even though they never initiated the login. Recognizing this as the *same underlying pattern* as the brute-force rule is exactly the kind of pattern-transfer skill this series is built to teach.

**The Implementation:**

**File: `siem-mastery-series/part-3-correlation-state/mfa_fatigue_dataset.py`**

```python
"""
mfa_fatigue_dataset.py

Produces a synthetic Azure AD SigninLogs-shaped dataset to test Appendix A's
MFA Fatigue detection rule, covering three scenarios:

  G - True MFA fatigue attack (SHOULD ALERT): 3 denials then 1 approval, 4 min window
  H - Benign poor-connectivity retry (SHOULD NOT ALERT): only 2 denials, below threshold
  I - Noisy shared/helpdesk account (TUNING CANDIDATE): 4 denials then approval,
      but from a known non-human test account -- a real false positive until excluded
"""
from datetime import datetime, timedelta, timezone
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent
BASE_TIME = datetime(2024, 6, 26, 11, 0, 0, tzinfo=timezone.utc)


def iso(seconds_offset: int) -> str:
    return (BASE_TIME + timedelta(seconds=seconds_offset)).isoformat().replace("+00:00", "Z")


def build_rows() -> list[str]:
    rows = []

    # --- Scenario G: true fatigue attack (SHOULD ALERT) ---
    events_g = [
        (0, "rjohnson@corp.onmicrosoft.com", "203.0.113.140", "Office 365 Exchange Online",
         "50074", "MFA request denied by user"),
        (60, "rjohnson@corp.onmicrosoft.com", "203.0.113.140", "Office 365 Exchange Online",
         "50076", "User declined the MFA prompt"),
        (130, "rjohnson@corp.onmicrosoft.com", "203.0.113.140", "Office 365 Exchange Online",
         "50074", "MFA request denied by user"),
        (240, "rjohnson@corp.onmicrosoft.com", "203.0.113.140", "Office 365 Exchange Online",
         "0", "Sign-in approved"),
    ]

    # --- Scenario H: benign poor-signal retry (SHOULD NOT ALERT, denials < 3) ---
    events_h = [
        (400, "asmith2@corp.onmicrosoft.com", "192.168.1.55", "Office 365 Exchange Online",
         "50074", "MFA request denied by user"),
        (450, "asmith2@corp.onmicrosoft.com", "192.168.1.55", "Office 365 Exchange Online",
         "0", "Sign-in approved"),
    ]

    # --- Scenario I: noisy shared/helpdesk account (TUNING CANDIDATE) ---
    events_i = [
        (600, "svc_devicefarm@corp.onmicrosoft.com", "192.168.1.90", "Device Provisioning Portal",
         "50074", "MFA request denied by user"),
        (630, "svc_devicefarm@corp.onmicrosoft.com", "192.168.1.90", "Device Provisioning Portal",
         "50076", "User declined the MFA prompt"),
        (665, "svc_devicefarm@corp.onmicrosoft.com", "192.168.1.90", "Device Provisioning Portal",
         "50074", "MFA request denied by user"),
        (700, "svc_devicefarm@corp.onmicrosoft.com", "192.168.1.90", "Device Provisioning Portal",
         "50074", "MFA request denied by user"),
        (740, "svc_devicefarm@corp.onmicrosoft.com", "192.168.1.90", "Device Provisioning Portal",
         "0", "Sign-in approved"),
    ]

    for offset, upn, ip, app, result_type, description in events_g + events_h + events_i:
        rows.append(
            f'    datetime({iso(offset)}), "{upn}", "{ip}", "{app}", '
            f'"{result_type}", "{description}"'
        )
    return rows


if __name__ == "__main__":
    rows = build_rows()
    body = ",\n".join(rows)
    # NOTE: naming this "let SigninLogs" allows it to locally shadow the real
    # SigninLogs table name for this query session in Azure Data Explorer --
    # meaning Appendix A's ORIGINAL query text works completely unmodified.
    literal = (
        "let SigninLogs = datatable(TimeGenerated: datetime, UserPrincipalName: string, "
        "IPAddress: string, AppDisplayName: string, ResultType: string, "
        "ResultDescription: string) [\n"
        f"{body}\n];"
    )
    output_path = OUTPUT_DIR / "dataset_kql_mfa.txt"
    output_path.write_text(literal + "\n")
    print(f"Wrote {len(rows)} synthetic sign-in rows to {output_path.name}")
```

Run it:

```bash
python3 mfa_fatigue_dataset.py
```

**The Verification:**

```
Wrote 11 synthetic sign-in rows to dataset_kql_mfa.txt
```

Now paste the entire contents of `dataset_kql_mfa.txt`, followed immediately by **Appendix A's original, unmodified query**:

```kql
SigninLogs
| where TimeGenerated > ago(1h)
| where ResultType in ("50074", "50076", "50140")
| summarize 
    MFA_Denials = countif(ResultDescription has "denied" or ResultDescription has "declined"),
    MFA_Approvals = countif(ResultDescription has "approved" or ResultType == "0"),
    FirstAttempt = min(TimeGenerated),
    LastAttempt = max(TimeGenerated)
    by UserPrincipalName, IPAddress, AppDisplayName
| where MFA_Denials >= 3 and MFA_Approvals == 1
| extend TimeDifference = LastAttempt - FirstAttempt
| where TimeDifference <= 15m
| project UserPrincipalName, IPAddress, AppDisplayName, MFA_Denials, TimeDifference
```

> **A subtle bug this exposes:** the `| where ResultType > ago(1h)` line and the `ResultType in (...)` filter only look at *denial* codes — but the final `| where TimeDifference <= 15m` step still needs the **approval row's** `TimeGenerated` in `LastAttempt`. Since `ResultType == "0"` (a full success) is *not* in the `("50074", "50076", "50140")` filter list, **the approval row gets filtered out before the `summarize` even runs**, meaning `MFA_Approvals` will always compute as `0`, and this rule as written will never fire! This is exactly the kind of subtle, easy-to-miss bug that "looks right" in a quick read-through. Real Appendix content should be tested before trusting it — which is exactly what we're doing right now.

**Corrected version:**

**File: `siem-mastery-series/part-3-correlation-state/mfa_fatigue_detection.kql`**

```kql
SigninLogs
| where TimeGenerated > ago(1h)
// FIX: include "0" (success/approval) alongside the denial codes, so the
// approval row survives into the summarize step below.
| where ResultType in ("50074", "50076", "50140", "0")
| summarize 
    MFA_Denials = countif(ResultDescription has "denied" or ResultDescription has "declined"),
    MFA_Approvals = countif(ResultDescription has "approved" or ResultType == "0"),
    FirstAttempt = min(TimeGenerated),
    LastAttempt = max(TimeGenerated)
    by UserPrincipalName, IPAddress, AppDisplayName
| where MFA_Denials >= 3 and MFA_Approvals == 1
| extend TimeDifference = LastAttempt - FirstAttempt
| where TimeDifference <= 15m
| project UserPrincipalName, IPAddress, AppDisplayName, MFA_Denials, TimeDifference
```

**The Verification:** Run the corrected query against the same pasted dataset.

Expected output — **2 rows** (Scenario G, the real attack, and Scenario I, the tuning candidate — Scenario H correctly does not appear, since its 1 denial never reaches the `>= 3` threshold):

| UserPrincipalName | IPAddress | AppDisplayName | MFA_Denials | TimeDifference |
|---|---|---|---|---|
| rjohnson@corp.onmicrosoft.com | 203.0.113.140 | Office 365 Exchange Online | 3 | 00:04:00 |
| svc_devicefarm@corp.onmicrosoft.com | 192.168.1.90 | Device Provisioning Portal | 3 | 00:02:20 |

---

## Step 3.9 — Tune the MFA Fatigue Rule

**The Target:** Remove the `svc_devicefarm` false positive without weakening real detection.

**The Concept:** `svc_devicefarm` isn't a person being fatigued into approving — it's an automated device-provisioning account with a known noisy MFA prompt from a misconfigured Conditional Access policy. Same underlying lesson as Part 2's `svc_backup`: exclude *known, documented* automation — never lower the threshold globally.

**File: `siem-mastery-series/part-3-correlation-state/mfa_fatigue_detection_tuned.kql`**

```kql
// Maintain this list as a Sentinel Watchlist in production, NOT hardcoded --
// this inline version is for local testing only.
let KnownServiceAccounts = dynamic(["svc_devicefarm@corp.onmicrosoft.com"]);
SigninLogs
| where TimeGenerated > ago(1h)
| where ResultType in ("50074", "50076", "50140", "0")
| where UserPrincipalName !in (KnownServiceAccounts)
| summarize 
    MFA_Denials = countif(ResultDescription has "denied" or ResultDescription has "declined"),
    MFA_Approvals = countif(ResultDescription has "approved" or ResultType == "0"),
    FirstAttempt = min(TimeGenerated),
    LastAttempt = max(TimeGenerated)
    by UserPrincipalName, IPAddress, AppDisplayName
| where MFA_Denials >= 3 and MFA_Approvals == 1
| extend TimeDifference = LastAttempt - FirstAttempt
| where TimeDifference <= 15m
| project UserPrincipalName, IPAddress, AppDisplayName, MFA_Denials, TimeDifference
```

**Exception list (document, review every 90 days):**

- `svc_devicefarm@corp.onmicrosoft.com` — known noisy provisioning automation; ticket #SEC-4471; review by 2024-09-26.

**Testing procedure (safe, benign trigger):** Using a disposable Azure AD test tenant and a test user with Microsoft Authenticator enrolled: trigger a sign-in, **deny** the push notification 3 times in a row from the Authenticator app, then on the 4th prompt, **approve** it. This generates genuine `50074`/`0` result-type sign-in log rows end-to-end, letting you validate real log delivery, not just the query's offline logic.

**The Verification:** Re-run `mfa_fatigue_detection_tuned.kql` against the same dataset — expect **exactly 1 row** now (Scenario G only):

| UserPrincipalName | IPAddress | AppDisplayName | MFA_Denials | TimeDifference |
|---|---|---|---|---|
| rjohnson@corp.onmicrosoft.com | 203.0.113.140 | Office 365 Exchange Online | 3 | 00:04:00 |

---

# Reference Section — Part 3

## R3.1 — Raw Log Sample: Real Azure AD MFA-Relevant `SigninLogs` Fields

```json
{
  "TimeGenerated": "2024-06-26T11:02:10.0000000Z",
  "UserPrincipalName": "rjohnson@corp.onmicrosoft.com",
  "IPAddress": "203.0.113.140",
  "AppDisplayName": "Office 365 Exchange Online",
  "ResultType": "50074",
  "ResultDescription": "Strong Authentication is required.",
  "AuthenticationRequirement": "multiFactorAuthentication",
  "AuthenticationDetails": [
    {
      "authenticationMethod": "Push Notification",
      "authenticationStepResultDetail": "MFA denied; user declined the authentication",
      "succeeded": false
    }
  ],
  "ConditionalAccessStatus": "success",
  "DeviceDetail": {
    "operatingSystem": "iOS 17.4",
    "browser": "Mobile Safari"
  }
}
```

## R3.2 — SPL `transaction` vs. `stats`-based Correlation: Production Tradeoffs

| Approach | Pros | Cons |
|---|---|---|
| `transaction` (used in this part) | Reads naturally, purpose-built for start/end sequences | Memory-intensive at scale; Splunk docs explicitly recommend `stats`/`streamstats` for high-volume production searches |
| `stats` + `streamstats` (production-grade alternative) | Scales far better across millions of events | Requires more manual work to express "starts with X, ends with Y" logic |

**Production-scale rewrite using `streamstats`** (conceptually equivalent to Step 3.5, but far more scalable):

```spl
index=siem_lab_corr
| where NOT cidrmatch("10.0.0.0/8", src)
| sort 0 src, user, _time
| streamstats current=t window=0 count(eval(action="failure")) as running_failures by src, user
| streamstats current=t window=0 reset_on_change=1 last(running_failures) as failures_before_this_event by src, user
| where action="success" AND failures_before_this_event >= 5
| table _time, src, user, failures_before_this_event
```

## R3.3 — KQL vs. SPL Correlation Cheat Sheet

| Task | SPL | KQL |
|---|---|---|
| Group sequential events into one record | `transaction key1, key2 startswith=... endswith=... maxspan=...` | `summarize` + `join` (no single equivalent command) |
| Cap total group duration | `maxspan` (applies to whole group) | Must be built manually via `datetime_diff()` on first/last timestamps |
| Cap gap between two specific events | Not directly separable from `maxspan` | `where SuccessTime between (LastFailure .. LastFailure + window)` |
| Count events in a group | `eventcount` (automatic) | `count()` inside `summarize` |

## R3.4 — MITRE ATT&CK Mapping Recap

| Rule | Technique(s) |
|---|---|
| Brute force → success correlation | T1110 (Brute Force) escalating into Initial Access |
| MFA Fatigue | T1621 (Multi-Factor Authentication Request Generation) |

## R3.5 — Connection to Appendix C's Matrix

The exact pattern built in this part — *"event A repeated N times, immediately followed by event B"* — is the same shape behind several rows in the series' **Common SIEM Rules Matrix**, most directly:

> **New Local Admin Creation** — Security Event 4720 (user creation) immediately followed by Event 4732 (added to local Administrators group). The same `transaction`/`join`-style correlation from Steps 3.5–3.6 applies directly — only the event codes and grouping key change.

Rows like **LSASS Memory Dumping** and **DNS Tunneling Detection** use a *different* detection shape (single-event anomaly scoring rather than sequence correlation) and are left as self-study exercises using the techniques from Parts 1–2.

## R3.6 — Full File Tree After Part 3

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
├── part-2-first-rules/
│   ├── generate_brute_force_dataset.py
│   ├── dataset_ecs.ndjson
│   ├── dataset_cim.csv
│   ├── dataset_kql.txt
│   ├── brute_force_detection.spl
│   └── brute_force_detection.kql
└── part-3-correlation-state/
    ├── generate_correlation_dataset.py
    ├── dataset_ecs.ndjson
    ├── dataset_cim.csv
    ├── dataset_kql.txt
    ├── brute_force_success_correlation.spl
    ├── brute_force_success_correlation.kql
    ├── mfa_fatigue_dataset.py
    ├── dataset_kql_mfa.txt
    ├── mfa_fatigue_detection.kql
    └── mfa_fatigue_detection_tuned.kql
```

---

Ready for **Part 4: Write Once, Run Anywhere (Sigma)** whenever you are — it takes Appendix B's PowerShell/`Net.WebClient` detection and shows you how to express its logic *once*, in vendor-neutral YAML, then compile that single definition into native Splunk SPL, Sentinel KQL, and Elastic queries.
