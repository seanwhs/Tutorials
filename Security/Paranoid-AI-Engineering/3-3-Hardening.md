**Phase 3, Module 3.3: Runaway Loops & Tool Misinterpretation (Failure Modes)**

### 1. The Threat Model / The Challenge
Agents can:
- Fall into infinite loops (same tool repeatedly).
- Misinterpret tool errors as successes or new threats.
- Burn resources (API keys, CPU) or leak data.

**Challenge**: Implement hard circuit breakers, step limits, sanitization, and clear final reporting.

### 2. The Architecture Blueprint
```
Orchestrator Loop
    ├── Max Steps (hard limit)
    ├── Circuit Breaker (no repeat tools > N times)
    ├── Input Sanitization + Error Classification
    └── State Persistence + Final Report
```

Deterministic containment around non-deterministic core.

### 3. The Lab (Code-First)

**Step 1: Enhanced Executor with Safeguards**  
**The Target**: Update `executor.py` with rate limiting and logging.  
**The Concept**: Add "safety valves" — like a car's governor that prevents over-revving the engine.

Update `executor.py` (add to existing file or replace relevant parts):

```python
import time
from collections import defaultdict

class ToolExecutor:
    def __init__(self):
        self.tools = {}
        self.call_counts = defaultdict(int)
        self.max_calls_per_tool = 3

    # ... previous register and sanitize_ip ...

    def execute(self, tool_name: str, args: dict) -> str:
        self.call_counts[tool_name] += 1
        if self.call_counts[tool_name] > self.max_calls_per_tool:
            return f"Circuit breaker: {tool_name} exceeded max calls"

        # ... existing sanitization and execution ...
        try:
            result = self.tools[tool_name](**args)
            return str(result)
        except Exception as e:
            return f"Tool error (classified): {str(e)}"
```

**Step 2: Hardened Agent with Circuit Breakers**  
**The Target**: Final `agent.py` for Phase 3.  
**The Concept**: The orchestrator is the "adult in the room" — it enforces rules no matter what the LLM suggests.

Replace `agent.py` with this complete hardened version:

```python
#!/usr/bin/env python3
"""
SecOps Agent - Phase 3.3: Hardened with Circuit Breakers
"""
import typer
import ollama
from dotenv import load_dotenv
from rich.console import Console
import json
from collections import Counter

from models import Incident, AgentStep
from executor import executor

load_dotenv()
app = typer.Typer(help="Hardened SecOps Agent")
console = Console()

SYSTEM_PROMPT = """Security agent. Use tools wisely. Output strict JSON only. End with FINAL REPORT."""

class HardenedAgent:
    def __init__(self):
        self.state: list[AgentStep] = []
        self.max_steps = 5
        self.tool_history = Counter()

    def run(self, incident: Incident):
        console.print(f"[bold red]HARDENED AGENT[/bold red] on {incident.ip} (max {self.max_steps} steps)")

        for step_num in range(self.max_steps):
            history_str = "\n".join([f"{s.thought}" for s in self.state])

            response = ollama.chat(
                model=os.getenv("OLLAMA_MODEL", "llama3.2"),
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": f"Incident: {incident.model_dump_json()}\nHistory:\n{history_str}\nNext JSON:"}
                ],
                format="json",
                options={"temperature": 0.0}
            )

            try:
                step = AgentStep.model_validate_json(response['message']['content'])
                self.state.append(step)

                if step.tool_call:
                    tool_name = step.tool_call.tool_name
                    self.tool_history[tool_name] += 1
                    
                    if self.tool_history[tool_name] > 3:
                        step.observation = "Circuit breaker activated: too many repeats"
                    else:
                        step.observation = executor.execute(tool_name, step.tool_call.args)

                console.print(f"Step {step_num+1}: {step.thought[:100]}...")

                if "FINAL REPORT" in step.thought.upper():
                    break
            except Exception as e:
                console.print(f"[red]Step {step_num} failed: {e}[/red]")

        # Final summary
        console.print(Panel(
            json.dumps({
                "incident": incident.model_dump(),
                "steps_taken": len(self.state),
                "tool_usage": dict(self.tool_history),
                "summary": [s.thought for s in self.state if "FINAL" in s.thought.upper()]
            }, indent=2),
            title="🛡️ Hardened Incident Response Complete",
            border_style="red"
        ))
        return self.state

@app.command()
def investigate(ip: str = typer.Argument(...)):
    incident = Incident(ip=ip, alert_type="brute_force", timestamp="now")
    agent = HardenedAgent()
    agent.run(incident)

if __name__ == "__main__":
    app()
```

**Verification**:
```bash
python agent.py investigate 185.22.45.12
```
Expected: Limited steps, circuit breaker triggers on repeats, clean final report.

### 4. The Failure Mode
**The Trap**: LLM ignores instructions and loops anyway, or misclassifies errors. Resource exhaustion on weak models.  
**The Fix**: Hard limits, counters, low temperature, and human oversight hooks.

---

### Reference Section (Isolated Deep Dives)

**Circuit Breaker Pattern**: Prevents cascading failures. Essential for agent safety.

**State Management**: Simple list + Counter is sufficient for most cases. For production, use persistent storage (SQLite).

**Phase 3 Complete!** You now have a stateful, hardened SecOps Agent.

Reply **"next"** for **Phase 4.1: Exploit Simulation**. Phase 3 is production-ready for many use cases. Great work!
