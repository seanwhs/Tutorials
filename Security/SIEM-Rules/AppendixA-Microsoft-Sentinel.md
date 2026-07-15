# Appendix A: Microsoft Sentinel (KQL) 

### Rule: MFA Spamming / Fatigue Detection

*(This expands the version built and tested live in Part 3, Steps 3.8–3.9, into a full production-grade reference: real-world context, severity tiering, risk enrichment, a cross-platform variant, a complete investigation playbook, and automated response guidance.)*

---

## A.0 — Why This Rule Exists: The Real-World Incidents

**The Concept:** Before trusting any detection rule, a good engineer asks: *has this attack actually happened, or am I defending against a hypothetical?* MFA fatigue isn't theoretical — it's one of the most consequential initial-access techniques of the last few years, precisely because it attacks a **human**, not a technical control.

Think of MFA like a doorbell with a camera that asks "is this really you?" before letting someone in. The **fatigue attack** doesn't try to pick the lock — it just rings the doorbell fifty times at 2 AM until the exhausted homeowner, assuming it must be something legitimate (a delivery, a false alarm, IT support), taps "yes" just to make the noise stop.

Two well-documented breaches made this technique famous:

| Incident | Year | What Happened |
|---|---|---|
| **Uber breach** | Sept 2022 | An attacker (linked to the Lapsus$ group) obtained a contractor's credentials, then repeatedly triggered MFA push notifications for over an hour. The contractor eventually approved one, believing it would stop the notifications. The attacker gained access to internal Slack, and posted messages as the "confirmed compromise." |
| **Cisco breach** | May 2022 | An attacker used a compromised employee's Google account (which had saved credentials) combined with voice phishing ("vishing") — calling the employee while spamming MFA pushes, posing as tech support, to socially engineer an approval. |

**The lesson these incidents teach directly:** the failure isn't cryptographic — the MFA protocol worked exactly as designed. The failure is that **volume + urgency + human fatigue** can defeat any protocol that ultimately asks a tired human to click "approve." This is precisely why this detection rule matters, and precisely why "Tuning" (A.6) must be handled with more care than a typical volumetric rule — you are, in effect, building an early-warning system for social engineering, not just brute-force math.

---

## A.1 — Full MITRE ATT&CK Context

**The Concept:** A single technique ID rarely tells the whole story — real attacks are chains. Placing T1621 into its surrounding kill chain shows you what to look for *before* and *after* this alert fires, which is exactly what the Investigation Playbook (A.9) is built around.

| Stage | Technique | ID | Relevance to This Rule |
|---|---|---|---|
| Prerequisite | Valid Accounts | T1078 | The attacker must already have a valid username/password — MFA fatigue is a *second-factor bypass*, not an initial credential attack. This almost always means credentials were phished, stuffed, or purchased beforehand. |
| **This Rule** | **Multi-Factor Authentication Request Generation** | **T1621** | Repeatedly triggering MFA prompts hoping for accidental/fatigued approval. |
| Often paired with | Phishing for Information / Vishing | T1598 / (Vishing is commonly logged under T1566.004) | Attackers often call the victim directly, posing as IT/security, to socially engineer the approval rather than relying on fatigue alone. |
| Following success | Initial Access via Valid Accounts | T1078 (again, now realized) | The approved MFA prompt completes the sign-in — this is the exact moment Part 3's `MFA_Approvals == 1` condition captures. |
| Likely next steps | Persistence: Additional Cloud Credentials | T1098.001 | A common follow-on: attacker registers *their own* MFA device on the compromised account so they no longer need to spam prompts again. This is the single most important "what happened right after" check — see A.9. |

**Key insight for detection engineers:** T1621 sits at a pivot point in the kill chain — everything before it (credential theft) is often invisible to a SIEM, and everything after it (lateral movement, data access) can look like completely normal activity from an "authenticated" account. This narrow window is often your **only** high-fidelity opportunity to catch the intrusion before it blends into legitimate-looking traffic.

---

## A.2 — Severity Tiering Model

**The Concept:** Not every rule match deserves the same pager alert. Think of a hospital triage nurse — a sprained ankle and a heart attack both technically "hurt," but they don't get the same response speed. We apply the same idea here: the *shape* of the denial/approval pattern tells us how urgent it really is.

| Tier | Condition | Rationale |
|---|---|---|
| **Low** | 3 denials, approval more than 10 minutes after first denial | Could still be user confusion/poor connectivity; watch, don't page |
| **Medium** | 3–5 denials, approval within 10 minutes | Matches the base rule's shape; worth an analyst look |
| **High** | 6+ denials in under 5 minutes | Rapid-fire spam — strongly resembles the Uber incident's pattern |
| **Critical** | 6+ denials AND the approval's sign-in IP differs from ALL of the denials' IPs | The approval didn't even come from the same network as the attack attempts — an extremely strong signal the attacker (not the user) is finishing the sign-in from their own location, or the user approved it while roaming/on a different network under active social engineering |

---

## A.3 — Enriched Detection Query (Severity + Geo/IP Divergence)

**The Target:** `mfa_fatigue_detection_enriched.kql` — extends the tuned Part 3 rule with severity tiering and the "approval IP differs from denial IPs" signal from A.2.

**The Implementation:**

**File: `siem-mastery-series/reference/appendix-a/mfa_fatigue_detection_enriched.kql`**

```kql
// ============================================================================
// MFA Fatigue Detection - Enriched (Severity Tiering + IP Divergence)
// MITRE ATT&CK: T1621 (MFA Request Generation)
// ============================================================================
let KnownServiceAccounts = dynamic(["svc_devicefarm@corp.onmicrosoft.com"]);
let LookbackWindow = 1h;
let CorrelationWindow = 15m;
// Raw sign-in events, scoped to the fields we need downstream. Keeping this
// as its own "let" (rather than inlining) makes the two summarize passes
// below re-use identical filtering logic -- avoiding subtle drift between
// the "denials" view and the "approval" view of the same underlying data.
let RawEvents = SigninLogs
    | where TimeGenerated > ago(LookbackWindow)
    | where ResultType in ("50074", "50076", "50140", "0")
    | where UserPrincipalName !in (KnownServiceAccounts);
// STATE TABLE #1: one row per (user, app) summarizing all denials --
// notice we deliberately do NOT group by IPAddress here, because a real
// fatigue attacker may rotate source IPs across the spam burst.
let Denials = RawEvents
    | where ResultType != "0"
    | summarize
        MFA_Denials = count(),
        FirstDenial = min(TimeGenerated),
        LastDenial = max(TimeGenerated),
        // make_set collects the DISTINCT source IPs seen across all denials,
        // which A.2's "IP divergence" check compares the approval IP against.
        DenialIPs = make_set(IPAddress)
        by UserPrincipalName, AppDisplayName;
// STATE TABLE #2: the single approval event per (user, app).
let Approvals = RawEvents
    | where ResultType == "0"
    | project ApprovalTime = TimeGenerated, ApprovalIP = IPAddress, UserPrincipalName, AppDisplayName;
Denials
| where MFA_Denials >= 3
| join kind=inner Approvals on UserPrincipalName, AppDisplayName
| where ApprovalTime between (FirstDenial .. FirstDenial + CorrelationWindow)
| extend TimeToApproval = ApprovalTime - LastDenial
| extend BurstDuration = LastDenial - FirstDenial
// The IP-divergence signal from A.2: true if the approval's IP was NEVER
// one of the denial IPs -- set_has_element checks array membership.
| extend ApprovalFromNewIP = not(set_has_element(DenialIPs, ApprovalIP))
| extend Severity = case(
    MFA_Denials >= 6 and ApprovalFromNewIP, "Critical",
    MFA_Denials >= 6 and BurstDuration < 5m, "High",
    MFA_Denials >= 3 and TimeToApproval < 10m, "Medium",
    "Low"
  )
| project UserPrincipalName, AppDisplayName, MFA_Denials, DenialIPs, ApprovalIP,
          ApprovalFromNewIP, BurstDuration, TimeToApproval, Severity
| order by Severity asc
```

**The Verification:** Using the same `dataset_kql_mfa.txt` literal built in Part 3 (Scenario G: `rjohnson`, Scenario I: `svc_devicefarm`), paste both blocks and run. Expected — `svc_devicefarm` no longer appears (still excluded by the known-service-account list), and `rjohnson` appears with `Severity: Medium` (3 denials, single consistent IP, approval within the window, but under the 6-denial "High" threshold).

To see a "Critical" row, add one more synthetic event to your dataset generator: an approval for `rjohnson` from a *different* IP than the denials — a copy-paste exercise directly extending Part 3's `mfa_fatigue_dataset.py`.

---

## A.4 — Cross-Platform Variant: Okta (SQL-like Query Language)

**The Concept:** T1621 isn't a Microsoft-only problem — Okta, Duo, and Ping Identity all log the exact same conceptual event (denied push, then approved push). Think of this the same way Part 4 treated Sigma: same logic, different dialect. Including this variant here (rather than waiting for a hypothetical "Part 5") shows the pattern-transfer skill this whole series is built to teach.

**File: `siem-mastery-series/reference/appendix-a/mfa_fatigue_detection_okta.sql`**

```sql
-- Okta System Log query, expressed for Okta's Event Hook / SIEM export
-- (queryable via Okta's own log search API, or once ingested, as SQL
-- against a data warehouse like Snowflake/BigQuery).
--
-- Okta's equivalent eventTypes:
--   "user.mfa.okta_verify.deny_push"  -> a denied/declined push
--   "user.authentication.auth_via_mfa" -> a successful MFA-backed sign-in
WITH denials AS (
    SELECT
        actor_alternate_id AS user_principal_name,
        client_ip_address AS ip_address,
        COUNT(*) AS mfa_denials,
        MIN(published) AS first_denial,
        MAX(published) AS last_denial
    FROM okta_system_log
    WHERE event_type = 'user.mfa.okta_verify.deny_push'
      AND published > NOW() - INTERVAL '1 hour'
    GROUP BY actor_alternate_id, client_ip_address
    HAVING COUNT(*) >= 3
),
approvals AS (
    SELECT
        actor_alternate_id AS user_principal_name,
        client_ip_address AS approval_ip,
        published AS approval_time
    FROM okta_system_log
    WHERE event_type = 'user.authentication.auth_via_mfa'
      AND outcome_result = 'SUCCESS'
      AND published > NOW() - INTERVAL '1 hour'
)
SELECT
    d.user_principal_name,
    d.ip_address AS denial_ip,
    d.mfa_denials,
    a.approval_ip,
    a.approval_time,
    (a.approval_time - d.last_denial) AS time_to_approval
FROM denials d
JOIN approvals a
  ON d.user_principal_name = a.user_principal_name
 AND a.approval_time BETWEEN d.first_denial AND d.first_denial + INTERVAL '15 minutes'
ORDER BY d.mfa_denials DESC;
```

**Note on portability:** this is precisely the kind of rule Part 4's Sigma approach was built to unify — the `selection`/`filter`/`condition` shape maps just as cleanly onto Okta's `eventType` fields as it did onto Sysmon's `Image`/`CommandLine` fields. Writing this as a Sigma **correlation rule** (Part 4, R4.5's forward pointer) is the natural next exercise once both Part 3 and Part 4 are complete.

---

## A.5 — Expanded Tuning & False Positive Playbook

**The Concept:** Appendix A's original tuning only covered one exception (a noisy service account). A mature rule needs a broader taxonomy of *why* legitimate denials happen, because MFA fatigue's biggest risk as a rule is **desensitizing analysts to real pushes-gone-wrong** if it's tuned poorly — the exact alert-fatigue failure mode this whole series opened with in Part 0.

| False Positive Category | Root Cause | Recommended Handling |
|---|---|---|
| **Automated/service accounts** | Scheduled tasks or device-provisioning flows configured with legacy MFA requirements | Exclude by UPN via a maintained, ticketed watchlist (as built in A.3/Part 3) |
| **Poor connectivity / dropped notifications** | User's phone repeatedly fails to receive the push due to network issues, retries manually | Usually produces 1–2 denials, not 3+ — the threshold itself is the primary defense; do not lower it |
| **Conditional Access misconfiguration** | A CA policy re-prompts MFA on every request due to a session-persistence bug | Fix the underlying CA policy — do not silence the rule, since this is a real (if non-malicious) problem worth remediating |
| **Shared/kiosk devices** | Multiple legitimate users share one physical device, triggering prompts for the "wrong" pending session | Exclude by device ID / AAD Device ID rather than by user, if your log source captures it |
| **User self-inflicted confusion** | User has multiple sessions open (laptop + phone) and denies pushes meant for their *other* session, then approves the right one | Legitimate, if messy — still worth a Low-severity, non-paging log entry rather than full suppression, since the pattern is indistinguishable from a real attack without human judgment |

**Never do this:** raise the `MFA_Denials >= 3` threshold globally to reduce noise. Every documented real-world incident (A.0) involved 3+ denials as the *minimum*, not the maximum — raising the floor directly increases your false-negative risk on the exact attack this rule exists to catch.

---

## A.6 — Expanded Raw Log Samples

**The Concept:** Appendix A's original single JSON sample only covered a Push Notification denial. A real environment sees multiple authentication methods, each shaped slightly differently — your field mappings must handle all of them, not just the common case.

**Push notification denial** (original, Part 3):
```json
{
  "TimeGenerated": "2024-06-26T11:02:10.0000000Z",
  "UserPrincipalName": "rjohnson@corp.onmicrosoft.com",
  "IPAddress": "203.0.113.140",
  "AppDisplayName": "Office 365 Exchange Online",
  "ResultType": "50074",
  "ResultDescription": "Strong Authentication is required.",
  "AuthenticationDetails": [{
    "authenticationMethod": "Push Notification",
    "authenticationStepResultDetail": "MFA denied; user declined the authentication",
    "succeeded": false
  }]
}
```

**Phone call MFA, unanswered/rejected** (a variant attackers use when push is unavailable):
```json
{
  "TimeGenerated": "2024-06-26T11:03:45.0000000Z",
  "UserPrincipalName": "rjohnson@corp.onmicrosoft.com",
  "IPAddress": "203.0.113.140",
  "AppDisplayName": "Office 365 Exchange Online",
  "ResultType": "50076",
  "ResultDescription": "User did not respond to mobile app notification in time allotted",
  "AuthenticationDetails": [{
    "authenticationMethod": "Phone",
    "authenticationStepResultDetail": "Call not answered",
    "succeeded": false
  }]
}
```

**Successful approval (the event that completes the correlation):**
```json
{
  "TimeGenerated": "2024-06-26T11:06:10.0000000Z",
  "UserPrincipalName": "rjohnson@corp.onmicrosoft.com",
  "IPAddress": "203.0.113.140",
  "AppDisplayName": "Office 365 Exchange Online",
  "ResultType": "0",
  "ResultDescription": "None",
  "AuthenticationDetails": [{
    "authenticationMethod": "Push Notification",
    "authenticationStepResultDetail": "MFA requirement satisfied by claim in the token",
    "succeeded": true
  }]
}
```

**FIDO2/hardware key sign-in (should generally be EXCLUDED from this rule entirely):**
```json
{
  "TimeGenerated": "2024-06-26T11:10:00.0000000Z",
  "UserPrincipalName": "csmith@corp.onmicrosoft.com",
  "IPAddress": "203.0.113.55",
  "AppDisplayName": "Office 365 Exchange Online",
  "ResultType": "0",
  "AuthenticationDetails": [{
    "authenticationMethod": "FIDO2 Security Key",
    "succeeded": true
  }]
}
```
> **Why this matters:** FIDO2/hardware-key authentication is **phishing-resistant by design** — there is no "prompt to approve," so it can never be fatigued. If your organization has rolled out FIDO2 keys, add `AuthenticationDetails has "FIDO2"` as an explicit exclusion, since these sign-ins have no meaningful "denial" state to correlate against and would only ever appear as noise.

---

## A.7 — Expanded Test Dataset (7 Scenarios)

**The Target:** Extends Part 3's 3-scenario `mfa_fatigue_dataset.py` with 4 additional scenarios covering A.5's tuning categories and A.2's severity tiers.

**File: `siem-mastery-series/reference/appendix-a/mfa_fatigue_dataset_expanded.py`**

```python
"""
mfa_fatigue_dataset_expanded.py

Extends Part 3's 3-scenario MFA fatigue dataset to 7 scenarios, covering
every severity tier (A.2) and tuning category (A.5):

  G - True fatigue attack, Medium severity (from Part 3)
  H - Benign poor-connectivity retry, below threshold (from Part 3)
  I - Noisy service account, tuning candidate (from Part 3)
  K - High severity: 6+ denials in under 5 minutes, single IP
  L - Critical severity: 6+ denials, approval from a DIFFERENT IP
  M - Low severity: 3 denials, but approval 12 minutes later (slow trickle)
  N - FIDO2 sign-in: should never appear in ANY tier of this rule
"""
from datetime import datetime, timedelta, timezone
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent
BASE_TIME = datetime(2024, 7, 10, 9, 0, 0, tzinfo=timezone.utc)


def iso(seconds_offset: int) -> str:
    return (BASE_TIME + timedelta(seconds=seconds_offset)).isoformat().replace("+00:00", "Z")


def build_rows() -> list[str]:
    rows = []

    events_g = [
        (0, "rjohnson@corp.onmicrosoft.com", "203.0.113.140", "Office 365 Exchange Online", "50074", "MFA request denied by user"),
        (60, "rjohnson@corp.onmicrosoft.com", "203.0.113.140", "Office 365 Exchange Online", "50076", "User declined the MFA prompt"),
        (130, "rjohnson@corp.onmicrosoft.com", "203.0.113.140", "Office 365 Exchange Online", "50074", "MFA request denied by user"),
        (240, "rjohnson@corp.onmicrosoft.com", "203.0.113.140", "Office 365 Exchange Online", "0", "Sign-in approved"),
    ]

    events_h = [
        (400, "asmith2@corp.onmicrosoft.com", "192.168.1.55", "Office 365 Exchange Online", "50074", "MFA request denied by user"),
        (450, "asmith2@corp.onmicrosoft.com", "192.168.1.55", "Office 365 Exchange Online", "0", "Sign-in approved"),
    ]

    events_i = [
        (600, "svc_devicefarm@corp.onmicrosoft.com", "192.168.1.90", "Device Provisioning Portal", "50074", "MFA request denied by user"),
        (630, "svc_devicefarm@corp.onmicrosoft.com", "192.168.1.90", "Device Provisioning Portal", "50076", "User declined the MFA prompt"),
        (665, "svc_devicefarm@corp.onmicrosoft.com", "192.168.1.90", "Device Provisioning Portal", "50074", "MFA request denied by user"),
        (700, "svc_devicefarm@corp.onmicrosoft.com", "192.168.1.90", "Device Provisioning Portal", "50074", "MFA request denied by user"),
        (740, "svc_devicefarm@corp.onmicrosoft.com", "192.168.1.90", "Device Provisioning Portal", "0", "Sign-in approved"),
    ]

    # Scenario K: High severity -- 6 denials packed into under 5 minutes,
    # all from the same IP, matching the Uber-incident shape from A.0.
    events_k = [
        (900, "dking@corp.onmicrosoft.com", "198.51.100.201", "VPN Portal", "50074", "MFA request denied by user"),
        (925, "dking@corp.onmicrosoft.com", "198.51.100.201", "VPN Portal", "50074", "MFA request denied by user"),
        (950, "dking@corp.onmicrosoft.com", "198.51.100.201", "VPN Portal", "50074", "MFA request denied by user"),
        (975, "dking@corp.onmicrosoft.com", "198.51.100.201", "VPN Portal", "50074", "MFA request denied by user"),
        (1000, "dking@corp.onmicrosoft.com", "198.51.100.201", "VPN Portal", "50074", "MFA request denied by user"),
        (1025, "dking@corp.onmicrosoft.com", "198.51.100.201", "VPN Portal", "50074", "MFA request denied by user"),
        (1080, "dking@corp.onmicrosoft.com", "198.51.100.201", "VPN Portal", "0", "Sign-in approved"),
    ]

    # Scenario L: Critical severity -- 6 denials from one IP, but the
    # APPROVAL comes from a totally different IP (attacker finishing the
    # sign-in from their own machine after the victim gave in on a call).
    events_l = [
        (1200, "efoster@corp.onmicrosoft.com", "198.51.100.55", "Office 365 Exchange Online", "50074", "MFA request denied by user"),
        (1225, "efoster@corp.onmicrosoft.com", "198.51.100.55", "Office 365 Exchange Online", "50074", "MFA request denied by user"),
        (1250, "efoster@corp.onmicrosoft.com", "198.51.100.55", "Office 365 Exchange Online", "50074", "MFA request denied by user"),
        (1275, "efoster@corp.onmicrosoft.com", "198.51.100.55", "Office 365 Exchange Online", "50074", "MFA request denied by user"),
        (1300, "efoster@corp.onmicrosoft.com", "198.51.100.55", "Office 365 Exchange Online", "50074", "MFA request denied by user"),
        (1325, "efoster@corp.onmicrosoft.com", "198.51.100.55", "Office 365 Exchange Online", "50074", "MFA request denied by user"),
        (1400, "efoster@corp.onmicrosoft.com", "203.0.113.250", "Office 365 Exchange Online", "0", "Sign-in approved"),
    ]

    # Scenario M: Low severity -- exactly 3 denials, but the approval comes
    # 12 minutes after the FIRST denial (inside the 15m window, but a slow,
    # low-urgency trickle rather than a rapid-fire burst).
    events_m = [
        (1500, "ctate@corp.onmicrosoft.com", "192.168.1.30", "Salesforce", "50074", "MFA request denied by user"),
        (1560, "ctate@corp.onmicrosoft.com", "192.168.1.30", "Salesforce", "50074", "MFA request denied by user"),
        (1620, "ctate@corp.onmicrosoft.com", "192.168.1.30", "Salesforce", "50074", "MFA request denied by user"),
        (2220, "ctate@corp.onmicrosoft.com", "192.168.1.30", "Salesforce", "0", "Sign-in approved"),
    ]

    # Scenario N: FIDO2 sign-in -- should NEVER match this rule at all,
    # since ResultType == "0" with no preceding denials means it never
    # crosses the "Denials.MFA_Denials >= 3" gate in the first place.
    events_n = [
        (2400, "csmith@corp.onmicrosoft.com", "203.0.113.55", "Office 365 Exchange Online", "0", "Sign-in approved (FIDO2)"),
    ]

    all_events = (events_g + events_h + events_i + events_k + events_l + events_m + events_n)
    for offset, upn, ip, app, result_type, description in all_events:
        rows.append(
            f'    datetime({iso(offset)}), "{upn}", "{ip}", "{app}", '
            f'"{result_type}", "{description}"'
        )
    return rows


if __name__ == "__main__":
    rows = build_rows()
    body = ",\n".join(rows)
    literal = (
        "let SigninLogs = datatable(TimeGenerated: datetime, UserPrincipalName: string, "
        "IPAddress: string, AppDisplayName: string, ResultType: string, "
        "ResultDescription: string) [\n"
        f"{body}\n];"
    )
    output_path = OUTPUT_DIR / "dataset_kql_mfa_expanded.txt"
    output_path.write_text(literal + "\n")
    print(f"Wrote {len(rows)} synthetic sign-in rows across 7 scenarios to {output_path.name}")
```

Run it:

```bash
mkdir -p ../reference/appendix-a  # if not already created
python3 mfa_fatigue_dataset_expanded.py
```

**The Verification:** Expected console output:

```
Wrote 27 synthetic sign-in rows across 7 scenarios to dataset_kql_mfa_expanded.txt
```

Paste the generated file's contents followed by **A.3's enriched query** into your ADX free cluster. Expected result — **4 rows** (H is below threshold and correctly absent; N is a bare success with no denials and correctly absent):

| UserPrincipalName | AppDisplayName | MFA_Denials | ApprovalFromNewIP | Severity |
|---|---|---|---|---|
| ctate@corp.onmicrosoft.com | Salesforce | 3 | false | Low |
| rjohnson@corp.onmicrosoft.com | Office 365 Exchange Online | 3 | false | Medium |
| dking@corp.onmicrosoft.com | VPN Portal | 6 | false | High |
| efoster@corp.onmicrosoft.com | Office 365 Exchange Online | 6 | true | Critical |

Confirm `svc_devicefarm` (Scenario I) is still absent — the `KnownServiceAccounts` exclusion from Part 3 carries forward unchanged into this enriched query.

---

## A.8 — SOC Investigation Playbook

**The Concept:** A detection rule firing is the *start* of an investigation, not the end. This playbook is the checklist an analyst follows the moment this alert lands in their queue — think of it as the hospital triage nurse's actual procedure manual, not just the severity label.

**Step-by-step, in order:**

1. **Confirm the user's own account of events.** Contact the user directly (via a channel *other* than the account potentially compromised, e.g., phone, not email) and ask: "Did you receive several MFA prompts around [time] and eventually approve one?" A "no, that wasn't me at all" answer immediately escalates severity regardless of the automated tier.
2. **Check for T1098.001 follow-on activity** (A.1's "likely next step"): query for any *new* MFA method registered on this account in the hours following the approval:
   ```kql
   AuditLogs
   | where TimeGenerated > ago(6h)
   | where OperationName == "User registered security info"
   | where TargetResources has "efoster@corp.onmicrosoft.com"
   ```
   A new device registration immediately after a Critical-tier alert is one of the strongest possible confirmations of real compromise.
3. **Pull the full session's subsequent activity** — what did this account actually do after the approval? Look specifically for data access outside the user's normal pattern (unusual SharePoint sites, mail forwarding rule creation, admin portal access).
4. **If confirmed malicious:** immediately revoke all active sessions (`Revoke-AzureADUserAllRefreshToken` or the Entra portal equivalent), force a password reset, and require MFA re-registration under supervision.
5. **If confirmed benign** (user error/connectivity): document the root cause against this specific alert (not just generically) — this feeds directly back into A.5's tuning table for future occurrences of the *same* root cause.

---

## A.9 — Automated Response (SOAR Playbook Sketch)

**The Concept:** For **Critical**-tier alerts specifically (A.2), waiting for a human analyst to start Step 1 of A.8 may take too long — every minute of delay is a minute the attacker has an active session. A **SOAR** (Security Orchestration, Automation, and Response) playbook can take an immediate, reversible containment action automatically, before a human even looks at it.

**File: `siem-mastery-series/reference/appendix-a/soar_playbook_sketch.md`**

```markdown
# Automated Response Playbook: Critical MFA Fatigue Alert

Trigger: mfa_fatigue_detection_enriched.kql produces a row with Severity == "Critical"

Automated actions (via Logic App / Azure Function, executed within seconds of the alert):
1. Revoke all active refresh tokens for UserPrincipalName immediately
   (Microsoft Graph API: Invoke-MgInvalidateUserRefreshToken)
2. Temporarily disable the account (NOT delete) pending analyst review
3. Post a message to the #soc-critical Slack/Teams channel with:
   - UserPrincipalName, DenialIPs, ApprovalIP, Severity, BurstDuration
   - A direct link to the pre-built investigation query (A.8, Step 3)
4. Send an SMS (not email, in case email is compromised) to the user's
   registered phone number: "Your account was just automatically locked
   due to suspicious MFA activity. Contact the Help Desk at [number]."

Explicitly OUT of scope for automation (human judgment required):
- Permanent account deletion or termination actions
- Notifying the user's manager or HR
- Law enforcement or legal escalation
```

**Why this step is deliberately a sketch, not runnable code:** SOAR automation wiring is highly specific to your organization's identity provider, ticketing system, and change-management policy — the series' code-heavy principle applies to *portable, testable logic* (the KQL, the Python), not to one-off infrastructure glue that would be wrong for most readers' actual environments. Use this as a requirements checklist when building your own Logic App/Function, not as copy-paste code.

---

## A.10 — Rule Health Metrics

**The Concept:** A detection rule is a living thing that needs a checkup, the same way you'd periodically check that a smoke detector's battery still works — not just install it once and forget it. Track these metrics monthly:

| Metric | How to Calculate | Healthy Target |
|---|---|---|
| **True Positive Rate** | Confirmed-malicious alerts ÷ total alerts (via A.8's Step 1 outcome, logged each time) | Track trend, not an absolute number — rising TP rate over time means tuning is working |
| **Mean Time to Triage** | Average time from alert creation to analyst Step-1 contact | < 15 minutes for Critical tier |
| **Exception List Staleness** | Days since each entry in `KnownServiceAccounts` was last reviewed | 0 entries older than 90 days (per A.5's review cadence) |
| **Severity Distribution** | Count of alerts per tier per month | A sudden spike in "Critical" tier warrants immediate attention regardless of individual triage outcomes |
| **False Negative Estimate** | Cross-reference confirmed incidents (from any source) against whether this rule fired | Any confirmed T1621 incident that this rule *missed* is a priority tuning bug, not just a data point |

---

## A.11 — Reference: Azure AD `ResultType` Codes Relevant to This Rule

| ResultType | Meaning | Relevant To |
|---|---|---|
| `0` | Success | The approval event this rule correlates against |
| `50074` | Strong auth (MFA) required / prompt denied | Primary denial signal |
| `50076` | User did not respond / declined MFA prompt | Secondary denial signal |
| `50140` | User interaction required (session/CA re-prompt) | Included per Appendix A's original filter |
| `500121` | Authentication failed during strong auth request | Additional denial variant worth adding to your own environment's filter list |
| `50097` | Device is not compliant / not registered | Not a denial — a Conditional Access block; do not conflate with MFA fatigue |

---

## A.12 — Consolidated File Tree for This Appendix

```
siem-mastery-series/
└── reference/
    └── appendix-a/
        ├── mfa_fatigue_detection_enriched.kql
        ├── mfa_fatigue_detection_okta.sql
        ├── mfa_fatigue_dataset_expanded.py
        ├── dataset_kql_mfa_expanded.txt
        └── soar_playbook_sketch.md
