# **Claude Certified Architect Foundations (CCAF)** exam Reference. 

This quick reference note treats agentic AI development as a rigorous branch of distributed systems engineering.

---

# I. The Philosophical Foundation: Deterministic AI

The CCAF exam distinguishes between "Casual Prompters" and "Architects." The core shift is from **probabilistic generation** to **programmatic orchestration**.

### 1. The Principle of Managed Autonomy

Agents are not "intelligent entities"—they are state machines interacting with tools.

* **The Architect’s Axiom:** If your system relies on the LLM "understanding" or "intending," it is fragile.
* **The Deterministic Shift:** You must wrap the LLM in a "Hard Shell" of code.
* **Hooks** are the laws (enforced by the runtime).
* **Prompts** are the culture (followed by the model).
* **Schemas** are the syntax (validated by the compiler/parser).



---

# II. Deep Architecture & Orchestration (Domain 1: 27%)

### 1. Advanced State Machine Engineering

* **The Loop Lifecycle:**
* *Observation Phase:* The agent consumes the state (History + Tool Outputs).
* *Reasoning Phase:* The agent determines the next transition.
* *Action Phase:* The agent emits `tool_use`.
* *Resolution Phase:* Your code intercepts, executes, validates, and re-injects the state.


* **Handling "Stuck" Agents:** If a loop exceeds the predicted cost or time, the Architect must implement a **Circuit Breaker**. This logic shouldn't be in the model—it must be in your orchestrator code.

### 2. The Hub-and-Spoke Topology

* **Hub (Orchestrator):** Operates on the "Master Context."
* **Spokes (Specialized Sub-agents):** Operate on "Ephemeral Context."
* **The Isolation Protocol:** When a Hub delegates to a Spoke, it uses a **Context Filter**.
* *Example:* If the user asks for a financial analysis of a property, the Hub (Architect) should **not** send the property’s architectural history. It should send only the parsed financial ledger JSON.


* **Anti-Pattern Alert:** Never allow direct peer-to-peer communication between sub-agents. This leads to recursive "hallucination loops" where agents reinforce each other's errors.

---

# III. Configuration & The Operating Environment (Domain 2: 20%)

### 1. `claude.md` Strategy (The Triple Layer)

* **Systemic Rules (User Level):** Defines the "Developer Persona" (e.g., "Always write clean code," "Use functional programming").
* **Domain Rules (Project Level):** Defines "Business Constraints" (e.g., "Use SQLite for this MVP," "Never leak API keys").
* **Contextual Rules (Path-Specific):** The most granular layer. Use these to solve the "Context Bloat" problem.
* *Tactic:* If your project has a `/contracts` directory, use a path-specific rule that only imports the `LegalTerminology.md` file when a user asks about a document in that folder.



### 2. CI/CD Pipeline Integration

* **Headless Operations:** The `-p` flag is critical. In a CI/CD environment, the agent must be "non-interactive."
* **Stateless Verification:** The exam emphasizes that **the model that generates code cannot be the one that reviews it.** You must have a secondary agent—with a distinct, clean context—performing the QA.

---

# IV. Reliability & Reliability Engineering (Domain 5: 15%)

### 1. The "Monkey in the Middle" (Context Window Management)

* **The Problem:** Information entropy in the middle of long sessions.
* **The Solution (Context Summarization):**
* Every $N$ turns, you must perform a `Context Snapshot`.
* The orchestrator saves the current state (summary of findings) and discards the intermediate "noisy" tool-use history.


* **The "Pinning" Technique:** Always keep the `Goal/Task Definition` at the very beginning of the context.

### 2. Escalation Logic

* **The "Full-Packet" Escalation:** When an agent fails, it must emit a data structure containing:
1. **State ID:** A UUID for the session.
2. **Breadcrumbs:** A JSON array of the last 5 successful tool steps.
3. **Failure Payload:** The precise stderr or malformed response.
4. **Recommended Action:** Based on the agent's internal analysis.



---

# V. Tool & MCP Integration (Domain 4: 18%)

### 1. The Interface of Tooling

* **Tool Descriptions are API Contracts:** If the description is "Get user info," the model will treat it as a black box. If the description is "Fetch user profile fields: {name, email, id} from SQL Table: users," the model performs **Parameter Inference** with 99% higher accuracy.
* **Force-Mode:** For critical pathing, use `tool_choice: {type: "tool", name: "auth_verify"}`. This forces the model to perform the security check *before* it can do anything else.

---

# VI. Exam Tactic: The "Architect’s Edge"

### The 3-Step Decision Algorithm

When answering exam questions, filter your choices through this pipeline:

1. **Does this solution require an LLM-level change?** (e.g., "Change the prompt.")
* *Result:* This is a **Weak/Distractor Answer**. LLMs are not reliable enforcement mechanisms.


2. **Does this solution require a Programmatic change?** (e.g., "Check the stop_reason," "Implement a hook," "Update the API schema.")
* *Result:* This is a **Strong/Correct Answer**. Deterministic code always beats probabilistic prompting.


3. **Does this solution maintain context isolation?**
* If a multi-agent scenario is described, choose the answer that **strips context** before delegating.



### Deep-Dive Study Checklist

* [ ] **Model Context Protocol:** Learn the difference between standard input (stdin) and standard output (stdout) for MCP.
* [ ] **Message Batching:** Know when to use the Batch API versus synchronous request-response.
* [ ] **Prompt Caching:** Understand how to use the prompt caching feature to reduce latency for project-level `claude.md` files.
* [ ] **Recursive Thought:** Study the "Chain-of-Thought" pattern and how to force the agent to "think" before it executes a tool.

### Crucial Definitions for the Exam

* **Hook:** An interceptor that returns an error code if validation fails.
* **Tool Choice:** The setting that defines how strictly you control the agent's ability to pick tools.
* **Stop Reason:** The absolute, definitive end-of-turn indicator.
* **Stateless:** An environment where the agent has no memory of the past (perfect for objective reviews).

**Final Reminder:** The CCAF exam is about **System Design.** Do not look for "smarter" ways to talk to the AI. Look for more robust ways to **constrain** the AI.
