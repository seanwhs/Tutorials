**Phase 2, Module 2.2: The Action Track & Signature Generation**

### 1. The Threat Model / The Challenge
Understanding malware (Analysis Track) is useless without generating actionable defenses. The **Action Track** translates grounded analysis into concrete detection rules (YARA or Sigma).  

**Challenge**: The LLM must produce syntactically valid signatures. Non-determinism (different outputs on same input) and invalid syntax are common. We enforce structure and prepare for validation in 2.3.

### 2. The Architecture Blueprint
```
Grounded Analysis (from 2.1 RAG)
    ↓
Action Prompt (strict template + examples)
    ↓
Ollama → Structured JSON
    ↓
Pydantic Models (YARA/Sigma)
    ↓
Output: Ready-to-use Detection Rules
```

Dual-track separation: Analysis = understanding; Action = generation.

### 3. The Lab (Code-First)

**Step 1: Extend Models for Signatures**  
**The Target**: Update `models.py` with Action Track schemas.  
**The Concept**: Separate models per track keep concerns clean — like having different report forms for "investigation notes" vs. "arrest warrant."

Append to `models.py` (full updated file recommended — replace with this):

```python
from pydantic import BaseModel, Field
from typing import List, Optional

# Phase 1 reuse
class Anomaly(BaseModel):
    timestamp: Optional[str] = None
    source_ip: Optional[str] = None
    username: Optional[str] = None
    event_type: str = Field(..., pattern="^(failed_login|successful_login|other)$")
    severity: str = Field(..., pattern="^(low|medium|high)$")
    reason: str = Field(..., min_length=5, max_length=200)

class AnalysisResult(BaseModel):
    anomalies: List[Anomaly] = Field(default_factory=list)
    def to_json(self) -> str:
        return self.model_dump_json(indent=2)

# New for Phase 2 Action Track
class YARARule(BaseModel):
    rule_name: str
    meta: dict = Field(default_factory=dict)
    strings: List[str] = Field(default_factory=list)
    condition: str

class SigmaRule(BaseModel):
    title: str
    detection: dict
    level: str = Field(..., pattern="^(low|medium|high|critical)$")

class ActionResult(BaseModel):
    """Output of Action Track."""
    yara_rules: List[YARARule] = Field(default_factory=list)
    sigma_rules: List[SigmaRule] = Field(default_factory=list)
    explanation: str = ""
```

**Verification**:
```bash
python -c "
from models import YARARule
rule = YARARule(rule_name='TestRule', strings=['malicious'], condition='any of them')
print(rule.model_dump_json(indent=2))
"
```

**Step 2: Implement the Action Track CLI**  
**The Target**: `malware_action.py` — complete Action Track.  
**The Concept**: Feed the RAG analysis as context into a new strict prompt that demands valid rule syntax. This is "generation with guardrails" — the model is told exactly what to output.

Create `malware_action.py` (complete):

```python
#!/usr/bin/env python3
"""
Malware Action Track - Signature Generation (Phase 2.2)
"""
import typer
import ollama
from dotenv import load_dotenv
import os
from rich.console import Console
from rich.panel import Panel

from knowledge_base import kb
from models import ActionResult, YARARule

load_dotenv()
app = typer.Typer(help="Malware Action Track - Rule Generation")
console = Console()

ACTION_PROMPT = """You are an expert detection engineer.
Given the malware analysis and MITRE context, generate valid YARA and/or Sigma rules.

Return ONLY valid JSON:
{
  "yara_rules": [{"rule_name": "...", "strings": ["..."], "condition": "..."}],
  "sigma_rules": [...],
  "explanation": "..."
}
Use real syntax. Be conservative and precise."""

@app.command()
def generate(
    snippet_file: str = typer.Argument(..., help="Pseudo-code file"),
    n_results: int = typer.Option(3, help="Retrieval depth")
):
    """Generate detection rules from analysis."""
    if not os.path.exists(snippet_file):
        console.print("[red]Snippet file not found[/red]")
        raise typer.Exit(1)

    with open(snippet_file, "r") as f:
        snippet = f.read()

    # Reuse RAG from Analysis Track
    retrieved = kb.query(snippet, n_results)
    context = "\n".join(retrieved.get('documents', [[]])[0])

    full_prompt = f"Context:\n{context}\n\nAnalysis Target:\n{snippet}"

    response = ollama.chat(
        model=os.getenv("OLLAMA_MODEL", "llama3.2"),
        messages=[
            {"role": "system", "content": ACTION_PROMPT},
            {"role": "user", "content": full_prompt}
        ],
        format="json",
        options={"temperature": 0.1}  # Slight creativity for rule creativity but controlled
    )

    try:
        action_result = ActionResult.model_validate_json(response['message']['content'])
        console.print(Panel(action_result.model_dump_json(indent=2), title="✅ Generated Detection Rules", border_style="green"))
        
        # Save rules to files
        for i, rule in enumerate(action_result.yara_rules):
            with open(f"generated_rule_{i}.yara", "w") as f:
                f.write(f"rule {rule.rule_name} {{\n    meta:\n        author = \"Paranoid AI\"\n    strings:\n")
                for s in rule.strings:
                    f.write(f'        $s = "{s}"\n')
                f.write(f"    condition:\n        {rule.condition}\n}}")
        console.print("[green]YARA rules saved to disk.[/green]")
    except Exception as e:
        console.print(f"[red]Action validation failed: {e}[/red]")
        console.print(response['message']['content'])

if __name__ == "__main__":
    app()
```

**Verification**:
1. Use the same `malware_sample.txt` from 2.1.
2. Run: `python malware_action.py malware_sample.txt`
3. Expected: Valid-looking YARA rules saved as files + JSON output. Open the `.yara` file to inspect.

### 4. The Failure Mode
**The Trap**: LLM invents invalid YARA operators (e.g. wrong condition syntax) or inconsistent structures across runs.  
**The Fix**: Strict Pydantic + low temperature. Full validation gate (yara-python) comes in 2.3.

---

### Reference Section (Isolated Deep Dives)

**Action vs Analysis Track**: Clear separation prevents the model from mixing reasoning and generation, reducing errors. Prompts become more focused.

**YARA Basics (in code)**: Rules have `strings` and `condition`. We generate minimal valid skeletons.

**Phase 2.2 Complete**. The dual-track is now functional.

Reply **"next"** for **2.3 Rule Validation & Non-Determinism**. Your malware engine can now generate rules! Test and inspect the output files.
