# Appendix C: Common SIEM Rules 

*(This expands the 7-rule matrix built for Appendix C into full production references, following the same depth established in Appendices A and B. Rather than repeat identical boilerplate seven times, C.0 establishes a shared severity/investigation/health-metrics framework used consistently across all seven rules, and each rule section (C.1–C.7) then adds its own real-world incident context, enriched detection logic with tiering, expanded tuning, additional raw log samples, expanded test data, and rule-specific investigation steps.)*

---

## C.0 — Shared Framework (Applies to All Seven Rules Below)

**The Concept:** Appendices A and B each built a bespoke severity model from scratch. Looking across all seven Appendix C rules, a pattern emerges: severity almost always comes down to the same three questions, just answered with different fields each time. Building that shared model *once* here — like a hospital adopting one universal triage scale across every department instead of reinventing it per specialty — means each rule below only needs to say "medium unless X, high if Y, critical if Z," instead of re-deriving triage logic from scratch every time.

### C.0.1 — The Universal Severity Model

| Tier | Universal Definition | Applied Meaning |
|---|---|---|
| **Low** | Matches the base pattern, but a mitigating factor is present (internal-only, known tooling nearby, low volume) | Log for trend analysis; do not page |
| **Medium** | Matches the base pattern cleanly, no mitigating factor, no aggravating factor | The rule's original baseline shape (what Appendix C originally shipped) |
| **High** | Matches the base pattern **and** one aggravating factor (external origin, privileged target, evasion behavior) | Analyst review within the shift |
| **Critical** | Matches the base pattern **and** two or more aggravating factors, or a factor tied to a documented real-world attacker TTP combination | Immediate triage, potential automated containment |

### C.0.2 — The Universal Investigation Playbook Template

Every rule below follows this same five-step shape (mirroring A.8 and B.8's structure), so an analyst who has triaged *any* Appendix C alert already knows the shape of triaging all the others:

1. **Confirm scope** — is this one host/account/IP, or part of a wider pattern? (Always re-run the query with the time window widened to 24h before deciding.)
2. **Pivot on the strongest indicator** — the specific IP, account, hash, or domain this rule surfaced, searched across *other* log sources, not just the one this rule reads from.
3. **Check the technique immediately before this one in the kill chain** — what got the attacker to this point?
4. **Check the technique immediately after this one in the kill chain** — what would the attacker logically do next, and has it already started?
5. **Document the outcome against this rule's tuning table** — every false positive becomes a permanent, dated exception; every true positive becomes a case study for the next tabletop exercise.

### C.0.3 — Shared Health Metrics (Track for Every Rule Below)

| Metric | Healthy Target |
|---|---|
| True Positive Rate (trend, not absolute) | Improving month-over-month |
| Mean Time to Triage (Critical tier) | < 15 minutes |
| Exception list staleness | 0 entries older than 90 days |
| Severity distribution drift | Investigate any sudden spike in High/Critical share |

---

## C.1 — Password Spraying (Expanded)

**Real-World Context:** Password spraying is the technique behind some of the most consequential nation-state campaigns publicly attributed by CISA and Microsoft — notably the pattern Microsoft has repeatedly documented from actors like **Peach Sandstorm**, who used low-and-slow spraying (one or two passwords per account, spread across thousands of accounts, over weeks) specifically to stay under simple per-account lockout thresholds. This is why C.1's original rule windows on **IP + time**, not on any single account — a sprayer deliberately never fails enough against one account to look like Part 2's brute-force rule.

**Enriched query (adds severity tiering — geo-impossible travel and privileged-account targeting as aggravating factors):**

```kql
let LookbackWindow = 10m;
let MinDistinctUsers = 10;
let PrivilegedAccounts = dynamic(["admin@corp.onmicrosoft.com", "breakglass@corp.onmicrosoft.com"]);
SigninLogs
| where ResultType != "0"
| summarize
    FailedAttempts = count(),
    DistinctUsers = dcount(UserPrincipalName),
    TargetedPrivilegedAccounts = countif(UserPrincipalName in (PrivilegedAccounts)),
    Countries = make_set(LocationDetails.countryOrRegion)
    by IPAddress, bin(TimeGenerated, LookbackWindow)
| where DistinctUsers >= MinDistinctUsers and FailedAttempts <= DistinctUsers * 2
| extend Severity = case(
    TargetedPrivilegedAccounts > 0 and array_length(Countries) > 2, "Critical",
    TargetedPrivilegedAccounts > 0, "High",
    array_length(Countries) > 2, "High",
    "Medium"
  )
| project TimeGenerated = bin(now(), LookbackWindow), IPAddress, FailedAttempts, DistinctUsers, TargetedPrivilegedAccounts, Countries, Severity
```

**Expanded Tuning:** Add known, ticketed penetration-testing source IPs (dated, time-boxed to the engagement window — never left indefinitely); exclude corporate VPN egress ranges only in combination with the privileged-account check, since a sprayer riding through a legitimate VPN range specifically to target `admin@` accounts is the exact Critical-tier scenario this rule should never silently drop.

**Additional raw log sample (privileged-account target, aggravating factor):**
```json
{
  "TimeGenerated": "2024-07-20T04:00:00Z",
  "UserPrincipalName": "admin@corp.onmicrosoft.com",
  "IPAddress": "198.51.100.77",
  "ResultType": "50126",
  "LocationDetails": { "countryOrRegion": "RO" }
}
```

**Investigation specifics (per C.0.2):** Step 3 (before) — check for any prior recon/OSINT signal (e.g., a spike in LinkedIn/corporate-directory scraping isn't SIEM-visible, but note it in the case file if reported). Step 4 (after) — check whether *any* of the sprayed accounts subsequently succeeded from the same IP within 24h (this is literally Part 3's correlation rule, applied here as the natural next query).

---

## C.2 — External Port Scanning (Expanded)

**Real-World Context:** Mass internet-wide scanning (via tools like Masscan/ZMap, or services like Shodan/Censys performing continuous background scanning) is so constant that a naive version of this rule pages the SOC dozens of times a day for scanning that a huge fraction of the internet receives constantly. The real skill isn't detecting scanning — it's distinguishing **opportunistic mass scanning** from **targeted reconnaissance that precedes an actual intrusion attempt** against your organization specifically.

**Enriched query (adds sequential-port-order detection, an aggravating factor mass-scanners rarely bother avoiding, and a "scan-then-connect" correlation):**

```spl
index=firewall_logs action=blocked
| bucket _time span=1m
| stats dc(dest_port) as distinct_ports_hit, values(dest_port) as ports_targeted, dc(dest) as distinct_hosts_targeted by src, _time
| where distinct_ports_hit > 10
" Sequential/low-jitter port order (e.g., 1,2,3,4...) is a lower-effort,
" more "automated mass scanner" signature; scans hitting SPECIFIC,
" non-sequential, service-relevant ports (22, 3389, 445, 5985) suggest a
" more deliberate, targeted actor who already knows what they're after.
| eval targets_high_value_ports=if(
    match(ports_targeted, "22") OR match(ports_targeted, "3389") OR
    match(ports_targeted, "445") OR match(ports_targeted, "5985"),
    1, 0)
| eval severity=case(
    distinct_hosts_targeted > 1 AND targets_high_value_ports=1, "Critical",
    targets_high_value_ports=1, "High",
    distinct_hosts_targeted > 1, "High",
    true(), "Medium"
  )
| table _time, src, distinct_hosts_targeted, distinct_ports_hit, ports_targeted, severity
```

**Expanded Tuning:** Maintain a documented allowlist of known internet-wide research scanners (Shodan, Censys, GreyNoise-classified benign scanners publish their ranges) — this single exclusion typically removes the majority of this rule's raw noise without touching real targeted-recon detection at all.

**Investigation specifics:** Step 4 (after) is the single highest-value check for this rule — cross-reference the scanning IP against subsequent **successful** connections (not just blocked ones) in the following hour. A scan immediately followed by a successful connection on one of the *same* ports it probed is a materially different, higher-confidence case than the scan alone.

---

## C.3 — Living off the Land / LotL (Expanded)

**Real-World Context:** This exact `w3wp.exe → cmd.exe` shape is the signature of countless real web-shell incidents, most visibly the mass exploitation of on-premises Microsoft Exchange servers (ProxyShell/ProxyLogon, 2021) — attackers dropped a web shell, then used the compromised IIS worker process to spawn a command shell for reconnaissance and further tooling deployment, exactly the pattern this rule targets.

**Enriched query (adds a "known LOLBin chain" reference list beyond just cmd/powershell, and flags encoded PowerShell as an aggravating factor — directly reusing Appendix B's B.3 obfuscation logic):**

```spl
index=windows_logs sourcetype="XmlWinEventLog:Microsoft-Windows-Sysmon/Operational" EventCode=1
(ParentImage="*w3wp.exe" OR ParentImage="*sqlservr.exe" OR ParentImage="*httpd.exe" OR ParentImage="*tomcat*.exe")
(Image="*cmd.exe" OR Image="*powershell.exe" OR Image="*wscript.exe" OR Image="*certutil.exe" OR Image="*regsvr32.exe")
| eval cmd_lower=lower(CommandLine)
" Reuses Appendix B's obfuscation heuristic -- an encoded command spawned
" from a web-server process is a much stronger signal than either factor
" (unusual parent, encoding) considered alone.
| eval has_encoded_command=if(match(cmd_lower, "-enc(odedcommand)?\s+[a-z0-9+/=]{20,}"), 1, 0)
| eval severity=if(has_encoded_command=1, "Critical", "High")
| table _time, host, ParentImage, Image, CommandLine, has_encoded_command, User, severity
```

**Investigation specifics:** Step 2 (pivot) — the web application's own access logs (not the SIEM's Windows logs) for the exact timestamp of the spawned shell almost always show the malicious HTTP request that triggered it; this is frequently the single fastest way to identify the specific vulnerability/web shell file involved.

---

## C.4 — New Local Admin Creation (Expanded)

**Real-World Context:** This 4720→4732 sequence is the most common **persistence** mechanism observed after almost any successful initial-access technique in this entire series — brute force (Part 2/3), MFA fatigue (Appendix A), or PowerShell download-cradle execution (Appendix B) all frequently end with the attacker creating exactly this kind of backup account, precisely so they can get back in even if the original compromised credential is later reset. This makes C.4 one of the highest-value **downstream** checks referenced throughout this entire appendix (see the "Step 4/after" note in C.1, B.1, and A.1).

**Enriched query (adds the specific tie-back to a suspicious *subject* — i.e., who performed the creation — cross-referenced against recent brute-force/MFA alerts using a state table, directly reusing Part 3's correlation pattern):**

```spl
index=windows_logs (EventCode=4720 OR EventCode=4732)
| transaction TargetUserName startswith=(EventCode=4720) endswith=(EventCode=4732) maxspan=5m
| where eventcount=2
" Cross-reference: was the ACCOUNT THAT PERFORMED this action (SubjectUserName)
" also flagged by a brute-force or MFA-fatigue alert recently? This lookup
" would be populated by the outputs of Part 2/3's rules and Appendix A's
" rule, written to a shared "recent_high_risk_accounts" lookup table.
| lookup recent_high_risk_accounts.csv account AS SubjectUserName OUTPUT is_recently_flagged
| eval severity=if(is_recently_flagged="true", "Critical", "High")
| table _time, TargetUserName, SubjectUserName, dest, duration, is_recently_flagged, severity
```

**Expanded Tuning:** Exclude documented IT provisioning automation accounts by `SubjectUserName` — but flag (never silently drop) any occurrence where `SubjectUserName` differs from the single expected provisioning account, since that mismatch alone is a stronger indicator than the base sequence.

**Investigation specifics:** Step 3 (before) is this rule's single most important check — pull every authentication event for `SubjectUserName` in the preceding hour; if `SubjectUserName` itself shows up as the *target* of Appendix A's MFA fatigue rule or Part 3's brute-force-success correlation, you likely have a complete, provable attack chain from initial access through to persistence.

---

## C.5 — LSASS Memory Dumping (Expanded)

**Real-World Context:** This is the exact technique behind **Mimikatz**, the most widely referenced credential-theft tool in security literature, and its behavior is directly codified into Sysmon's own default configuration guidance (SwiftOnSecurity's popular Sysmon config explicitly recommends monitoring Event ID 10 against `lsass.exe` for this reason). This rule's access-mask list (`0x1010`, `0x1038`, etc.) corresponds to the specific Windows API permission combinations Mimikatz's `sekurlsa::logonpasswords` module requests.

**Enriched query (adds a check for the source process's file-system reputation — unsigned binaries in user-writable paths are a strong aggravating factor):**

```spl
index=windows_logs sourcetype="XmlWinEventLog:Microsoft-Windows-Sysmon/Operational" EventCode=10
TargetImage="*\\lsass.exe"
(GrantedAccess="0x1010" OR GrantedAccess="0x1038" OR GrantedAccess="0x1438" OR GrantedAccess="0x143a" OR GrantedAccess="0x1fffff")
" A source binary running from a user-writable, non-standard path
" (Downloads, Temp, AppData) is a much stronger signal than one running
" from Program Files/System32, where legitimate signed software normally lives.
| eval source_in_suspicious_path=if(
    match(SourceImage, "(?i)\\\\(downloads|temp|appdata|users\\\\public)\\\\"),
    1, 0)
| eval severity=if(source_in_suspicious_path=1, "Critical", "High")
| table _time, host, SourceImage, TargetImage, GrantedAccess, source_in_suspicious_path, User, severity
```

**Investigation specifics:** Step 2 (pivot) — hash the `SourceImage` binary (via your EDR, not directly through Splunk) and check it against VirusTotal/organizational threat intel immediately; this single lookup very often resolves the entire triage in one step, since genuine credential-dumping tools are heavily signatured.

---

## C.6 — DNS Tunneling Detection (Expanded)

**Real-World Context:** DNS tunneling is the technique behind numerous documented C2 frameworks (including `dnscat2` and Cobalt Strike's DNS beacon mode) specifically because DNS traffic is almost never blocked by egress firewalls — it's considered "boring" infrastructure traffic, which is exactly why attackers hide inside it.

**Enriched query (adds a Shannon-entropy-style proxy for randomness beyond simple length, and a query-type aggravating factor — TXT/NULL records are disproportionately used by tunneling tools versus normal DNS traffic):**

```spl
index=dns_logs
| rex field=query "^(?<subdomain>[^\.]+)\.(?<root_domain>.+)$"
| eval subdomain_length=len(subdomain)
" Simple entropy proxy: count of DISTINCT characters used relative to
" length. Real words reuse common letters heavily (low distinct-char
" ratio); randomly generated tunneling labels use a near-uniform spread
" of characters (high distinct-char ratio).
| eval distinct_chars=len(mvcount(split(subdomain, "")))
| eval entropy_proxy=round(distinct_chars / subdomain_length, 2)
| where subdomain_length > 30
| bucket _time span=5m
| stats count as query_count, dc(subdomain) as distinct_subdomains, avg(entropy_proxy) as avg_entropy, values(query_type) as query_types by src, root_domain, _time
| where query_count > 50 AND distinct_subdomains > 40
| eval severity=case(
    avg_entropy > 0.6 AND (match(query_types, "TXT") OR match(query_types, "NULL")), "Critical",
    avg_entropy > 0.6, "High",
    true(), "Medium"
  )
| table _time, src, root_domain, query_count, distinct_subdomains, avg_entropy, query_types, severity
```

**Investigation specifics:** Step 2 (pivot) — decode a sample of the flagged subdomains as Base32/Base64 (tunneling tools almost always encode data this way to stay within valid DNS label characters) — this often directly reveals exfiltrated data fragments or C2 command text, turning a statistical anomaly into a confirmed, readable finding.

---

## C.7 — Massive Cloud Data Copy (Expanded)

**Real-World Context:** Bulk cloud-storage exfiltration via misused or stolen API credentials is the mechanism behind numerous publicly reported cloud breaches where a single leaked access key (often accidentally committed to a public code repository) was used to enumerate and copy entire S3 buckets. The "non-standard API key" framing in the original rule name reflects this: the access pattern itself, not just the volume, is often the strongest tell.

**Enriched query (adds a check for the credential's typical historical baseline — a brand-new or rarely-used key suddenly performing bulk operations is a much stronger signal than an established key's volume simply increasing):**

```kql
AWSCloudTrail
| where EventName in ("GetObject", "CopyObject")
| where UserIdentityType != "AssumedRole" or UserIdentityArn !contains "expected-etl-role"
| summarize
    ObjectCount = count(),
    DistinctBuckets = dcount(RequestParameters_bucketName),
    FirstEverSeen = min(TimeGenerated)
    by UserIdentityArn, SourceIpAddress, bin(TimeGenerated, 10m)
| where ObjectCount > 1000
" A key whose FIRST EVER recorded activity is itself part of this bulk
" spike (i.e., no established history before the incident window) is a
" strong indicator of a recently created or recently stolen credential.
| extend KeyAgeAtIncident = bin(now(), 10m) - FirstEverSeen
| extend Severity = case(
    KeyAgeAtIncident < 1h and DistinctBuckets > 5, "Critical",
    KeyAgeAtIncident < 1h, "High",
    DistinctBuckets > 5, "High",
    true(), "Medium"
  )
| project TimeGenerated = bin(now(), 10m), UserIdentityArn, SourceIpAddress, ObjectCount, DistinctBuckets, KeyAgeAtIncident, Severity
```

**Investigation specifics:** Step 3 (before) — check CloudTrail for the exact moment this API key was *created* (`CreateAccessKey` event) — a key created minutes or hours before a multi-thousand-object copy operation is close to definitive proof of a stolen or attacker-provisioned credential, not a legitimate automation account whose usage simply spiked.

---

## Consolidated Reference: Cross-Rule MITRE ATT&CK Kill-Chain Map

**The Concept:** Appendices A and B each showed one rule's position in a kill chain. Seeing all seven Appendix C rules on one chain at once reveals *why* a real SOC treats them as one connected detection program, not seven unrelated alerts — an attacker who trips C.1 today and C.4 next week is very likely the same intrusion, and your case-management process should connect them automatically.

| Kill Chain Stage | Appendix C Rule(s) | Also Connects To |
|---|---|---|
| Reconnaissance | C.2 (Port Scanning) | — |
| Initial Access | C.1 (Password Spraying) | Part 2/3's Brute Force rules, Appendix A (MFA Fatigue) |
| Execution | C.3 (Living off the Land) | Appendix B (PowerShell Download) |
| Persistence | C.4 (New Local Admin) | — |
| Credential Access | C.5 (LSASS Dumping) | — |
| Command & Control | — | (DNS Tunneling doubles as both C2 and Exfil, see C.6) |
| Exfiltration | C.6 (DNS Tunneling), C.7 (Cloud Data Copy) | — |

**Practical takeaway:** build a single shared `recent_high_risk_accounts`/`recent_high_risk_ips` lookup table (referenced directly in C.4's enriched query above) populated by the outputs of *every* rule in this series — Parts 2–4 and all three appendices. This turns seven isolated detections into one connected detection program, which is the actual operational goal this entire series has been building toward.
