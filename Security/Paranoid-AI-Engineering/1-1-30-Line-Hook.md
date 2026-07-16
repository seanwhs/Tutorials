**Phase 1, Module 1.1: The 30-Line Hook**

### 1. The Threat Model / The Challenge
Security teams receive thousands of raw log lines daily — SSH `auth.log` failures, Windows Event ID 4625 brute-force attempts, etc. Spotting real threats manually is impossible at scale. LLMs are excellent at understanding messy, human-written log text, but they produce inconsistent, non-structured output that cannot feed into SIEM systems or alerting pipelines.  

**Constraints**: Zero-config, local-only (no cloud APIs), minimal dependencies, immediate usable result in <50 lines of Python. We must respect context window limits (models "forget" middle content) and enforce output structure from day one.

### 2. The Architecture Blueprint
```
Raw Log File (.log) 
    ↓ (line-by-line reader with basic filtering)
Python CLI (Typer + Ollama client)
    ↓ (System Prompt + User Message per line)
Local Ollama Server (llama3.2 or similar)
    ↓ (JSON-forced response)
Structured Anomalies → Console Output (JSON)
```

Simple, observable, and debuggable. No databases yet.

### 3. The Lab (Code-First)

**Step 1: Project Setup**  
**The Target**: Create the project directory structure and install exact dependencies.  
**The Concept**: Like preparing a workshop — you need the right tools in the right place before building. A virtual environment isolates packages. A `.env` file stores configuration (model name) so you never hard-code secrets or settings.

```bash
mkdir -p sec-log-parse && cd sec-log-parse
python -m venv venv
source venv/bin/activate  # Windows: .\venv\Scripts\activate
pip install "typer[all]" ollama pydantic python-dotenv rich
echo "OLLAMA_MODEL=llama3.2" > .env
echo "__pycache__/" > .gitignore
echo "*.log" >> .gitignore
```

**Verification**:
```bash
ls -la
cat .env
pip list | grep -E 'typer|ollama|pydantic|dotenv|rich'
```

**Step 2: Create the Core CLI Script**  
**The Target**: `sec_log_parse.py` — the complete 30+ line working hook.  
**The Concept**: Imagine a paranoid detective who has a strict checklist (the system prompt). For each suspicious page (log line), the detective writes a structured incident report in a fixed format. The LLM is the detective; we force the format so the report is machine-usable. Line-by-line processing prevents overwhelming the model's memory.

Create the file with this **complete, production-ready code**:

```python
#!/usr/bin/env python3
"""
Paranoid AI Log Analyst CLI - Phase 1.1: The 30-Line Hook
Analyzes authentication logs and extracts structured anomalies using local LLM.
"""
import typer
import ollama
from dotenv import load_dotenv
import os
from typing import List, Dict, Any
import json
from rich.console import Console
from rich.panel import Panel

load_dotenv()

app = typer.Typer(
    help="sec-log-parse: Local LLM-powered log anomaly detector",
    add_completion=False
)

console = Console()

SYSTEM_PROMPT = """You are an extremely paranoid senior security analyst.
Analyze the provided log line for authentication-related anomalies ONLY.

Rules:
- Focus on failed logins, brute force indicators, impossible travel, suspicious IPs/usernames.
- Respond EXCLUSIVELY with valid JSON matching this schema. No explanations, no markdown.
{
  "anomalies": [
    {
      "timestamp": "string or null",
      "source_ip": "string or null",
      "username": "string or null",
      "event_type": "failed_login | successful_login | other",
      "severity": "low | medium | high",
      "reason": "one short sentence explaining why this is suspicious"
    }
  ]
}
If nothing suspicious, return {"anomalies": []}."""

@app.command()
def parse(
    log_file: str = typer.Argument(..., help="Path to the log file (e.g. auth.log)"),
    model: str = typer.Option(None, help="Override OLLAMA_MODEL from .env"),
    limit: int = typer.Option(0, help="Limit lines to process (0 = all)"),
):
    """Parse log file line-by-line and flag anomalies."""
    if not os.path.exists(log_file):
        console.print(f"[red]Error: File {log_file} not found.[/red]")
        raise typer.Exit(1)

    effective_model = model or os.getenv("OLLAMA_MODEL", "llama3.2")
    console.print(Panel(f"Using model: [bold]{effective_model}[/bold] on {log_file}", title="Starting Analysis"))

    anomalies: List[Dict[str, Any]] = []
    line_count = 0

    try:
        with open(log_file, "r", encoding="utf-8", errors="ignore") as f:
            for i, raw_line in enumerate(f, 1):
                line = raw_line.strip()
                if not line:
                    continue
                if limit > 0 and i > limit:
                    break

                # Quick heuristic filter - only suspicious lines (expandable)
                if not any(kw in line.lower() for kw in ["failed", "invalid", "sshd", "4625", "password"]):
                    continue

                line_count += 1
                console.print(f"[dim]Processing line {i}...[/dim]", end="\r")

                try:
                    response = ollama.chat(
                        model=effective_model,
                        messages=[
                            {"role": "system", "content": SYSTEM_PROMPT},
                            {"role": "user", "content": f"Log line {i}: {line}"}
                        ],
                        format="json",          # Critical: many models support this
                        options={"temperature": 0.0}  # Reduce creativity for consistency
                    )
                    content = response['message']['content']
                    result = json.loads(content)
                    new_anomalies = result.get("anomalies", [])
                    anomalies.extend(new_anomalies)
                except (json.JSONDecodeError, KeyError, Exception) as e:
                    console.print(f"[yellow]Warning on line {i}: {e}[/yellow]")
    except Exception as e:
        console.print(f"[red]Fatal error reading file: {e}[/red]")
        raise typer.Exit(1)

    # Final output
    output = {
        "file": log_file,
        "lines_processed": line_count,
        "total_anomalies": len(anomalies),
        "anomalies": anomalies
    }
    console.print(Panel(json.dumps(output, indent=2), title="Analysis Complete", border_style="green"))
    return output

if __name__ == "__main__":
    app()
```

Make executable: `chmod +x sec_log_parse.py`

**Verification**:
1. Start Ollama if not running: `ollama serve` (in another terminal).
2. Pull model: `ollama pull llama3.2` (or `llama3.1:8b` if preferred).
3. Create test log:
   ```bash
   cat > sample_auth.log << 'EOF'
   Jan 17 10:23:45 server sshd[1234]: Failed password for invalid user hacker from 192.168.1.100 port 22 ssh2
   Jan 17 10:24:01 server sshd[5678]: Accepted password for admin from 10.0.0.5 port 22
   Jan 17 10:25:10 server sshd[9999]: Failed password for root from 185.22.45.12
   EOF
   ```
4. Run: `./sec_log_parse.py sample_auth.log --limit 10`
5. Expected: Rich-formatted JSON output showing high-severity anomalies for failed logins, especially from external IPs. No crashes.

**Step 3: Add a Simple Test Helper (Optional but Recommended)**  
**The Target**: `test_parse.py` for quick regression checks.  
**The Concept**: Like a smoke detector — run it after changes to ensure the core still works.

```python
# test_parse.py
import subprocess
import json

def test_basic_parsing():
    result = subprocess.run(
        ["./sec_log_parse.py", "sample_auth.log", "--limit", "5"],
        capture_output=True,
        text=True
    )
    assert result.returncode == 0
    # Look for JSON in output
    output = result.stdout
    assert "total_anomalies" in output
    print("✅ Basic parsing test passed")

if __name__ == "__main__":
    test_basic_parsing()
```

Run: `python test_parse.py`

### 4. The Failure Mode
**The Trap**: 
- Model outputs free-form text instead of JSON → downstream breakage.
- Very long files → context overflow, silent middle-event drops ("lost in the middle").
- High temperature → inconsistent severity ratings on same input.

**Early Hardening** (already in code): `format="json"`, `temperature=0.0`, try/except per line, heuristic filters.

**Next Module Teaser**: Pydantic models will validate every response strictly.

---

### Reference Section (Isolated Deep Dives)

**Ollama Python Library Key Points**:
- `ollama.chat()` is preferred for structured conversations.
- `format="json"` (when supported) + low temperature dramatically improves reliability.
- Responses contain `['message']['content']` and usage metadata. Always wrap in try/except.

**Typer Best Practices**:
- Use `typer.Option` for flags, `typer.Argument` for required inputs.
- `rich` makes CLI output beautiful and readable.

**Token & Context Awareness (Beginner Explanation)**: Models have a maximum "attention span" measured in tokens (~4 characters each). Exceeding it silently truncates. We start small (one line) to build intuition.

**Next**: When ready, reply with **"Phase 1.2"** for Pydantic structural control.

You now have a fully working, copy-pasteable foundation. Test it thoroughly before proceeding!
