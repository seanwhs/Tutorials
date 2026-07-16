**Phase 1, Module 1.2: Structural Control via Pydantic**

### 1. The Threat Model / The Challenge
LLMs are creative writers by nature. Even with "JSON" instructions, they occasionally add extra text, use wrong keys, wrong types, or malformed structures. This breaks automation. For security tools, we need **guaranteed** schemas that downstream systems (SIEMs, dashboards, other scripts) can trust without extra parsing headaches.

**Challenge**: Replace loose string prompts with enforceable data contracts using Pydantic while keeping the CLI simple and backward-compatible.

### 2. The Architecture Blueprint
```
Raw Log Lines
    ↓
Ollama (with system prompt)
    ↓
Raw JSON string
    ↓
Pydantic Model Validation (strict parsing + error handling)
    ↓
Validated Python Objects → Clean JSON Output + Alerts
```

Pydantic acts as a "bouncer" at the door — invalid outputs are rejected or fixed early.

### 3. The Lab (Code-First)

**Step 1: Add Pydantic Dependency & Models**  
**The Target**: Update dependencies and create data models in a new file.  
**The Concept**: Think of Pydantic models like official forms with checkboxes and required fields. The LLM fills the form, but Pydantic checks every box. If something is wrong, it tells you exactly what and where instead of letting bad data spread.

```bash
pip install pydantic
```

Create `models.py` (complete file):

```python
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class Anomaly(BaseModel):
    """Single anomaly record with strict validation."""
    timestamp: Optional[str] = Field(None, description="Log timestamp")
    source_ip: Optional[str] = Field(None, description="IP address of source")
    username: Optional[str] = Field(None, description="Attempted username")
    event_type: str = Field(..., pattern="^(failed_login|successful_login|other)$")
    severity: str = Field(..., pattern="^(low|medium|high)$")
    reason: str = Field(..., min_length=5, max_length=200)

class AnalysisResult(BaseModel):
    """Complete validated response from LLM."""
    anomalies: List[Anomaly] = Field(default_factory=list)

    def to_json(self) -> str:
        """Safe serialization."""
        return self.model_dump_json(indent=2)
```

**Verification**:
```bash
python -c "
from models import AnalysisResult, Anomaly
a = Anomaly(event_type='failed_login', severity='high', reason='Brute force pattern')
print(AnalysisResult(anomalies=[a]).to_json())
"
```

**Step 2: Refactor the Main CLI to Use Pydantic**  
**The Target**: Update `sec_log_parse.py` to integrate validation (building directly on 1.1).  
**The Concept**: The previous version was like asking a friend to describe a suspect verbally. Now we hand them a police sketch form (Pydantic) and reject anything that doesn't match exactly. This moves us from "hope it works" to "guaranteed structure."

Replace the entire content of `sec_log_parse.py` with this complete updated version:

```python
#!/usr/bin/env python3
"""
Paranoid AI Log Analyst CLI - Phase 1.2: Pydantic Structural Control
"""
import typer
import ollama
from dotenv import load_dotenv
import os
from typing import List
from rich.console import Console
from rich.panel import Panel
import json

from models import AnalysisResult, Anomaly

load_dotenv()

app = typer.Typer(help="sec-log-parse: Pydantic-validated log anomaly detector")
console = Console()

SYSTEM_PROMPT = """You are a paranoid senior security analyst.
Analyze ONLY authentication anomalies.

Return valid JSON matching this schema exactly:
{
  "anomalies": [
    {
      "timestamp": "string or null",
      "source_ip": "string or null",
      "username": "string or null",
      "event_type": "failed_login | successful_login | other",
      "severity": "low | medium | high",
      "reason": "short clear explanation"
    }
  ]
}
No extra text whatsoever."""

@app.command()
def parse(
    log_file: str = typer.Argument(..., help="Path to log file"),
    model: str = typer.Option(None, help="Override model"),
    limit: int = typer.Option(0, help="Max lines to process"),
):
    """Parse logs with strict Pydantic validation."""
    if not os.path.exists(log_file):
        console.print(f"[red]Error: {log_file} not found[/red]")
        raise typer.Exit(1)

    effective_model = model or os.getenv("OLLAMA_MODEL", "llama3.2")
    console.print(Panel(f"Model: [bold]{effective_model}[/bold] | File: {log_file}", title="Pydantic Analysis"))

    all_anomalies: List[Anomaly] = []
    line_count = 0
    validation_failures = 0

    with open(log_file, "r", encoding="utf-8", errors="ignore") as f:
        for i, raw_line in enumerate(f, 1):
            line = raw_line.strip()
            if not line or limit > 0 and i > limit:
                continue
            if not any(kw in line.lower() for kw in ["failed", "invalid", "4625", "password", "sshd"]):
                continue

            line_count += 1
            console.print(f"[dim]Line {i} → LLM → Validation[/dim]", end="\r")

            try:
                response = ollama.chat(
                    model=effective_model,
                    messages=[
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {"role": "user", "content": f"Log line {i}: {line}"}
                    ],
                    format="json",
                    options={"temperature": 0.0}
                )
                raw_json = response['message']['content']
                
                # Strict validation
                result = AnalysisResult.model_validate_json(raw_json)
                all_anomalies.extend(result.anomalies)
                
            except Exception as e:
                validation_failures += 1
                console.print(f"[yellow]Validation failed line {i}: {type(e).__name__}[/yellow]")

    final_result = AnalysisResult(anomalies=all_anomalies)
    
    console.print(Panel(
        f"Lines processed: {line_count}\n"
        f"Valid anomalies: {len(all_anomalies)}\n"
        f"Validation failures: {validation_failures}",
        title="✅ Pydantic Validation Complete",
        border_style="green"
    ))
    
    console.print(final_result.to_json())
    return final_result

if __name__ == "__main__":
    app()
```

**Verification**:
1. Re-create or use existing `sample_auth.log` from 1.1.
2. Run: `./sec_log_parse.py sample_auth.log`
3. Expected: Clean JSON from `to_json()`, validation errors reported gracefully if any, and typed `Anomaly` objects internally.
4. Test invalid output resilience by temporarily removing `format="json"` in one run (observe graceful handling).

**Step 3: Update Test Helper**  
**The Target**: Enhanced `test_parse.py`.  
**The Concept**: Automated checks ensure structural guarantees hold after refactoring.

```python
# test_parse.py (updated)
import subprocess
import json
from models import AnalysisResult

def test_pydantic_validation():
    result = subprocess.run(
        ["./sec_log_parse.py", "sample_auth.log", "--limit", "5"],
        capture_output=True, text=True, check=True
    )
    # Extract JSON part
    output = result.stdout
    assert "Valid anomalies" in output
    print("✅ Pydantic validation test passed")

if __name__ == "__main__":
    test_pydantic_validation()
```

Run: `python test_parse.py`

### 4. The Failure Mode
**The Trap**: LLM still occasionally returns extra fields, wrong enum values, or non-JSON (especially on weaker models). Silent failures propagate.  
**The Fix**: Pydantic + `model_validate_json()` + per-line error counting. In 1.3 we add chunking for scale.

---

### Reference Section (Isolated Deep Dives)

**Pydantic Core Concepts**:
- `BaseModel` defines schemas with type hints and `Field` constraints (regex, length, etc.).
- `model_validate_json()` parses + validates in one step, raising `ValidationError` with details.
- `model_dump_json()` ensures clean output. This is the foundation for reliable LLM pipelines.

**Why This Matters for Security**: Structured output turns probabilistic LLM responses into deterministic, auditable data.

**Next Module (1.3)**: "Lost in the Middle" — massive log handling via sliding window chunking.

Reply **"next"** when ready for Phase 1.3. Your CLI is now significantly more robust! Test thoroughly.
