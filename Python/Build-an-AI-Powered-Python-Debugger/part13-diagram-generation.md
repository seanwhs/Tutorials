# Part 13 — Diagram Generation & Visual Debugging (Seeing Code Instead of Just Reading It)

At this point, your system is already quite powerful:

```text id="d1a9aa"
✔ AI debugging engine
✔ Structured Markdown reports
✔ PDF export
✔ Conversation memory
✔ Streaming responses
✔ UI interaction
```

But there’s still a gap between how humans understand bugs and how your system presents them.

Humans don’t just read code.

They *visualize it*.

So we upgrade again:

> From text-based debugging → to visual debugging

---

# The Core Problem

Even a perfect explanation like:

```text id="d2b9bb"
The error happens because the index is out of range.
```

is still:

* abstract
* linear
* hard to mentally simulate

But what we actually want is:

```text id="d3c9cc"
Code → Execution Flow → Failure Point → Fix Path
```

This is where diagrams matter.

---

# What We Are Building

We are adding a new output layer:

```text id="d4d9dd"
AI → Analysis → Diagram Data → Visual Rendering
```

So now the system becomes:

```text id="d5e9ee"
Code
 ↓
AI Reasoning
 ↓
Structured Explanation
 ↓
Diagram Generator
 ↓
Visual Debug View
```

---

# Why Visual Debugging Matters

Humans understand systems through:

* flow
* movement
* relationships

not just text.

---

## Example

Instead of:

```text id="d6f9ff"
IndexError in list access
```

We want:

```text id="d7g9gg"
[Start]
   ↓
Loop over list
   ↓
Access index 10 ❌
   ↓
Crash: IndexError
```

---

# Step 1 — What Is a Diagram in Our System?

We define a diagram as:

> A structured representation of execution flow

Not an image yet.

Just data.

---

## Example diagram structure

```python id="d8h9hh"
diagram = {
    "nodes": [
        "Start",
        "Loop",
        "Access Index",
        "Error"
    ],
    "edges": [
        ("Start", "Loop"),
        ("Loop", "Access Index"),
        ("Access Index", "Error")
    ]
}
```

---

# Step 2 — Extending the AI Output Contract

We now update our system prompt:

```python id="d9i9ii"
SYSTEM_PROMPT = """
You are a Python debugging engine.

You must output:

## Problem
## Root Cause
## Explanation
## Fix
## Execution Flow Diagram (in structured format)

For diagrams, output:

Nodes:
- step 1
- step 2

Edges:
- step1 -> step2

Be precise and structured.
"""
```

---

# Why This Works

We are forcing the AI to produce:

```text id="e1j9jj"
Text explanation + Machine-readable diagram data
```

This is crucial.

---

# Step 3 — Extracting Diagram Section

Inside `ui.py`:

```python id="e2k9kk"
diagram_output = ""
```

We store diagram separately.

---

## Why separate?

Because:

```text id="e3l9ll"
Explanation → PDF
Diagram → Visual renderer
```

Different consumers.

---

# Step 4 — Parsing Diagram Data

We extract:

```text id="e4m9mm"
Nodes:
Edges:
```

From AI output.

---

## Simple parsing logic

```python id="e5n9nn"
def parse_diagram(text):
```

We scan line by line:

```text id="e6o9oo"
if "->" in line:
    edge list
elif line starts with "-":
    node list
```

---

# Step 5 — Using Bokeh for Visualization

We already have:

* Bokeh

We use it to draw graphs.

---

## Why Bokeh?

Because it supports:

* interactive graphs
* node-link diagrams
* web rendering
* real-time updates

---

# Step 6 — Building the Graph

We convert parsed data into:

```python id="e7p9pp"
from bokeh.models import GraphRenderer
```

Then:

```text id="e8q9qq"
Nodes → Circles
Edges → Lines
```

---

# Step 7 — Visual Flow Example

For this code:

```python id="e9r9rr"
numbers = [1, 2, 3]
print(numbers[10])
```

We generate:

```text id="f1s9ss"
[Start]
   ↓
Create List
   ↓
Access Index 10
   ↓
IndexError ❌
```

---

# Step 8 — Connecting Diagram to UI

In `ui.py`:

```python id="f2t9tt"
def on_diagram():
```

We:

```python id="f3u9uu"
code = code_input.value
diagram_data = generate_text(...)
```

Then:

```python id="f4v9vv"
parsed = parse_diagram(diagram_data)
render_graph(parsed)
```

---

# Step 9 — Rendering Flow in UI

We now have two outputs:

```text id="f5w9ww"
output → Markdown explanation
diagram_output → Visual flowchart
```

---

# Step 10 — Final System Architecture

Now everything connects:

```text id="f6x9xx"
User Code
   ↓
AI Engine
   ↓
Structured Markdown
   ↓
Diagram Data
   ↓
UI Renderer (Panel)
   ↓
Graph Renderer (Bokeh)
   ↓
PDF Export System
```

---

# Step 11 — Why This Is a Major Upgrade

We are no longer building:

```text id="f7y9yy"
a text-based assistant
```

We are building:

```text id="f8z9zz"
a multi-modal debugging system
```

---

# Step 12 — Key Engineering Insight

The system now separates:

| Type          | Output       |
| ------------- | ------------ |
| Reasoning     | Markdown     |
| Structure     | Diagram data |
| Visualization | Graph UI     |
| Documentation | PDF          |

---

# What We’ve Learned

In this chapter:

### What visual debugging is

Turning code execution into flow diagrams.

---

### Why diagrams matter

They match how humans think about systems.

---

### How AI can generate structured diagrams

Using node-edge representations.

---

### How Bokeh fits in

Rendering interactive graphs in Python.

---

### Why separation of outputs matters

Different formats serve different consumers.

---

# What Comes Next?

Now your system can:

```text id="f9a0aa"
✔ Explain code
✔ Generate structured reports
✔ Export PDFs
✔ Show execution diagrams
```

But we still haven’t connected everything into a *real debugging workflow*.

In **Part 14 — Full Debugging Pipeline Integration (End-to-End System Design)**, we will learn:

* How all modules connect into one system
* How UI triggers full multi-step processing
* How to unify text, diagrams, and PDFs
* How to manage complexity cleanly
* How production-grade AI tools are structured
* How to design scalable AI architecture

This is where your project becomes a **complete AI engineering system**, not just individual features.
