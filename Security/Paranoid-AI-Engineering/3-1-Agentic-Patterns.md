**Phase 3, Module 3.1: Agentic Patterns (ReAct vs. Plan-and-Execute)**

### 1. The Threat Model / The Challenge
Simple prompt-response is not enough for real incident response. Agents must reason, use tools, and maintain state across steps. Two main patterns exist:

- **ReAct** (Reason + Act): Step-by-step interleaved thinking and tool use.
- **Plan-and-Execute**: Up-front multi-step plan, then deterministic execution.

**Challenge**: Build both using clean Python classes (no heavy frameworks) to understand the trade-offs. Keep LLM only for planning/reasoning.

### 2. The Architecture Blueprint
```
Incident Alert (e.g. suspicious IP)
    ↓
Orchestrator (State + Loop Control)
    ├── LLM Planner (Non-Deterministic: choose ReAct or Plan)
    └── Tool Executor (Deterministic: nmap, shodan, etc.)
    ↓
Incident Response Log
```

Explicit separation is key to safety.

### 3. The Lab (Code-First)

**Step 1: Project Setup for Phase 3**  
**The Target**: New directory structure and base dependencies.  
**The Concept**: Like upgrading from a bicycle (Phase 2) to a car — add an engine (agent loop), steering wheel (planner), and brakes (executor + state).

```bash
cd ..  # Go back to parent if needed
mkdir -p secops-agent && cd secops-agent
cp -r ../sec-log-parse/venv .  # Reuse or recreate
source venv/bin/activate
pip install typer ollama pydantic python-dotenv rich requests
```

**Step 2: Core Models & Tools**  
**The Target**: `models.py` and `tools.py`.  
**The Concept**: Tools are deterministic functions the LLM can "call" via JSON. The model never executes them directly.

Create `models.py` (complete):

```python
from pydantic import BaseModel, Field
from typing import List, Dict, Literal

class ToolCall(BaseModel):
    tool_name: str
    args: Dict = Field(default_factory=dict)

class AgentStep(BaseModel):
    thought: str
    tool_call: ToolCall | None = None
    observation: str | None = None

class Incident(BaseModel):
    ip: str
    alert_type: Literal["brute_force", "c2", "exfil"]
    timestamp: str
```

Create `tools.py` (complete, deterministic executor):

```python
import requests
from typing import Dict

def shodan_lookup(ip: str) -> str:
    """Mock/Shodan-like lookup. Replace with real API key in prod."""
    try:
        # Mock response for demo (real: use Shodan API)
        return f"Shodan data for {ip}: Open ports 22,80. Last seen: recent."
    except Exception as e:
        return f"Tool error: {e}"

def nmap_scan(ip: str) -> str:
    """Mock Nmap. In prod: subprocess with sanitized input."""
    return f"Nmap scan {ip}: 22/tcp open ssh, 80/tcp open http."

TOOLS = {
    "shodan_lookup": shodan_lookup,
    "nmap_scan": nmap_scan,
}
```

**Verification**:
```bash
python -c "
from tools import TOOLS
print(TOOLS['shodan_lookup']('8.8.8.8'))
"
```

**Step 3: Implement ReAct and Plan-and-Execute Engines**  
**The Target**: `agent.py` — both patterns in one file.  
**The Concept**: ReAct is like a detective thinking out loud while investigating. Plan-and-Execute is making a full investigation checklist first, then following it step-by-step. The orchestrator manages state for both.

Create `agent.py` (complete):

```python
#!/usr/bin/env python3
"""
SecOps Agent - Phase 3.1: ReAct vs Plan-and-Execute
"""
import typer
import ollama
from dotenv import load_dotenv
from rich.console import Console
import json

from models import Incident, AgentStep
from tools import TOOLS

load_dotenv()
app = typer.Typer(help="SecOps Stateful Agent")
console = Console()

SYSTEM_PROMPT_REACT = """You are a ReAct security agent. Think step-by-step. Output JSON with 'thought' and optional 'tool_call'."""

SYSTEM_PROMPT_PLAN = """Create a multi-step plan for incident response. Then execute it."""

class Agent:
    def __init__(self, mode: str = "react"):
        self.mode = mode
        self.state: list[AgentStep] = []
        self.max_steps = 5

    def run(self, incident: Incident):
        console.print(f"[bold]Starting {self.mode.upper()} Agent on {incident.ip}[/bold]")
        
        for step_num in range(self.max_steps):
            context = "\n".join([f"Step {i}: {s.thought}" for i, s in enumerate(self.state)])
            
            prompt = f"Incident: {incident.model_dump_json()}\nHistory: {context}\nNext step?"
            
            response = ollama.chat(
                model=os.getenv("OLLAMA_MODEL", "llama3.2"),
                messages=[{"role": "system", "content": SYSTEM_PROMPT_REACT if self.mode == "react" else SYSTEM_PROMPT_PLAN},
                          {"role": "user", "content": prompt}],
                format="json"
            )
            
            try:
                data = json.loads(response['message']['content'])
                step = AgentStep(**data)
                self.state.append(step)
                
                if step.tool_call:
                    tool_func = TOOLS.get(step.tool_call.tool_name)
                    if tool_func:
                        obs = tool_func(**step.tool_call.args)
                        step.observation = obs
                        console.print(f"[blue]Tool {step.tool_call.tool_name} executed[/blue]")
                
                console.print(f"Step {step_num+1}: {step.thought[:100]}...")
                
                if "final" in step.thought.lower() or step_num == self.max_steps-1:
                    break
            except Exception as e:
                console.print(f"[red]Step error: {e}[/red]")
        
        console.print(Panel(json.dumps([s.model_dump() for s in self.state], indent=2), title="Incident Response Log"))
        return self.state

@app.command()
def investigate(ip: str, mode: str = typer.Option("react", help="react or plan")):
    incident = Incident(ip=ip, alert_type="brute_force", timestamp="now")
    agent = Agent(mode=mode)
    agent.run(incident)

if __name__ == "__main__":
    app()
```

**Verification**:
```bash
python agent.py investigate 192.168.1.100 --mode react
python agent.py investigate 8.8.8.8 --mode plan
```
Expected: Step-by-step output, tool calls, final log.

### 4. The Failure Mode
**The Trap**: Infinite loops, tool misuse, or ignoring state.  
**The Fix**: Hard `max_steps`, isolated executor, JSON-only LLM interface (next module).

---

### Reference Section (Isolated Deep Dives)

**ReAct vs Plan-and-Execute**:
- ReAct: Flexible, good for open-ended investigation.
- Plan-and-Execute: More predictable, better for compliance-heavy environments.

**Key Principle**: LLM only outputs plans/calls. Execution is 100% deterministic Python.

**Phase 3.1 Complete**. Reply **"next"** for 3.2 Strict Tool Separation. Your agent now reasons and acts!
