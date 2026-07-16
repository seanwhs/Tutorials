**Phase 3, Module 3.2: Strict Tool Separation**

### 1. The Threat Model / The Challenge
Allowing the LLM to directly execute tools or run arbitrary code is extremely dangerous (code execution vulnerabilities, prompt injection leading to shell access). We must enforce strict separation: LLM only proposes JSON tool calls; a separate deterministic executor runs them.

**Challenge**: Refactor the agent to use a clean interface where the planner has zero direct access to system resources.

### 2. The Architecture Blueprint
```
LLM Planner (JSON only)
    ↓ (ToolCall schema)
Orchestrator / Executor (Python only, sanitized)
    ↓ (Run actual tools: nmap, requests, etc.)
Observation → Back to Planner State
```

This is the core of secure agent design.

### 3. The Lab (Code-First)

**Step 1: Enhanced Tool Executor**  
**The Target**: `executor.py` — isolated, sanitized tool runner.  
**The Concept**: Analogy — the LLM is the boss giving orders on paper. The executor is the trusted worker who actually does the dangerous physical work, but only follows exact instructions and wears safety gear (input sanitization).

Create `executor.py` (complete):

```python
import re
from typing import Dict, Any
import requests  # For API calls

def sanitize_ip(ip: str) -> str:
    """Basic sanitization."""
    if not re.match(r"^\d{1,3}(\.\d{1,3}){3}$", ip):
        raise ValueError("Invalid IP format")
    return ip

class ToolExecutor:
    def __init__(self):
        self.tools = {}

    def register(self, name: str, func):
        self.tools[name] = func

    def execute(self, tool_name: str, args: Dict[str, Any]) -> str:
        if tool_name not in self.tools:
            return f"Unknown tool: {tool_name}"
        
        try:
            # Sanitize inputs
            if "ip" in args:
                args["ip"] = sanitize_ip(args["ip"])
            
            result = self.tools[tool_name](**args)
            return str(result)
        except Exception as e:
            return f"Execution error: {str(e)}"

# Global executor
executor = ToolExecutor()

# Register deterministic tools
def shodan_lookup(ip: str) -> str:
    # Mock for demo
    return f"Shodan intel for {ip}: Ports 22/80 open, reputation: suspicious"

def nmap_scan(ip: str) -> str:
    return f"Nmap quick scan {ip}: SSH open"

executor.register("shodan_lookup", shodan_lookup)
executor.register("nmap_scan", nmap_scan)
```

**Verification**:
```bash
python -c "
from executor import executor
print(executor.execute('shodan_lookup', {'ip': '8.8.8.8'}))
"
```

**Step 2: Updated Agent with Strict Separation**  
**The Target**: Final `agent.py` for 3.2.  
**The Concept**: The planner never imports or calls `subprocess`, `requests`, or file I/O. All real work goes through the executor. This prevents many attack vectors.

Replace `agent.py` with this complete version:

```python
#!/usr/bin/env python3
"""
SecOps Agent - Phase 3.2: Strict Tool Separation
"""
import typer
import ollama
from dotenv import load_dotenv
from rich.console import Console
import json

from models import Incident, AgentStep, ToolCall
from executor import executor

load_dotenv()
app = typer.Typer(help="SecOps Agent with Strict Separation")
console = Console()

SYSTEM_PROMPT = """You are a security incident response agent.
Output ONLY JSON in this format:
{
  "thought": "reasoning",
  "tool_call": {"tool_name": "name", "args": {...}} or null
}
When done, set thought to 'FINAL REPORT'."""

class SecureAgent:
    def __init__(self):
        self.state: list[AgentStep] = []
        self.max_steps = 6

    def run(self, incident: Incident):
        console.print(f"[bold]Secure Agent investigating {incident.ip}[/bold]")
        
        for step in range(self.max_steps):
            history = "\n".join([f"Step {i}: {s.thought} → {s.observation or ''}" for i, s in enumerate(self.state)])
            
            response = ollama.chat(
                model=os.getenv("OLLAMA_MODEL", "llama3.2"),
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": f"Incident: {incident.model_dump_json()}\nHistory:\n{history}\nNext JSON step:"}
                ],
                format="json",
                options={"temperature": 0.0}
            )
            
            try:
                data = json.loads(response['message']['content'])
                step_obj = AgentStep.model_validate(data)
                self.state.append(step_obj)
                
                if step_obj.tool_call:
                    obs = executor.execute(step_obj.tool_call.tool_name, step_obj.tool_call.args)
                    step_obj.observation = obs
                    console.print(f"[cyan]Executed: {step_obj.tool_call.tool_name}[/cyan]")
                
                console.print(f"Step {step+1}: {step_obj.thought[:120]}...")
                
                if "FINAL" in step_obj.thought.upper():
                    break
            except Exception as e:
                console.print(f"[red]Parsing/execution error: {e}[/red]")
        
        console.print(Panel(json.dumps([s.model_dump() for s in self.state], indent=2), title="Final Secure Incident Log"))
        return self.state

@app.command()
def investigate(ip: str = typer.Argument(...)):
    incident = Incident(ip=ip, alert_type="brute_force", timestamp="now")
    agent = SecureAgent()
    agent.run(incident)

if __name__ == "__main__":
    app()
```

**Verification**:
```bash
python agent.py investigate 192.168.1.100
```
Expected: Clean steps, tool executions via executor only, no direct LLM access to tools.

### 4. The Failure Mode
**The Trap**: LLM tries to output raw Python or bypasses JSON. Executor still vulnerable if sanitization is weak.  
**The Fix**: Strict JSON mode + Pydantic + input sanitization (expanded in 3.3).

---

### Reference Section (Isolated Deep Dives)

**Strict Separation Benefits**:
- LLM cannot execute arbitrary code.
- Easy auditing of every tool call.
- Tools can be rate-limited, logged, or run in sandboxes.

**ToolCall Schema**: Forces the LLM into a contract.

**Phase 3.2 Complete**. Reply **"next"** for 3.3 Runaway Loops & Hardening.

Your agent is now architecturally sound! Test both modes and inspect the executor.
