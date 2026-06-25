# Appendix E — AI System Design Patterns Used Throughout Markly

One of the most valuable lessons from building Markly is that successful AI systems are rarely built around a single model call.

Beginners often imagine AI applications like this:

```text
User Input
    │
    ▼
LLM
    │
    ▼
Output
```

This works for prototypes.

It does not scale well into production systems.

As Markly evolved, we gradually introduced a collection of architectural patterns commonly found in real-world AI products.

Without explicitly calling them out, we implemented:

* Classifiers
* Routers
* Personas
* Multi-stage pipelines
* Validators
* Memory systems
* Artifact generators

This appendix explains these patterns and why they matter.

---

# Pattern 1 — The Classifier Pattern

The first major AI pattern introduced was:

> Classification before generation.

Instead of immediately grading the assignment:

```text
Assignment
     │
     ▼
Grade
```

we inserted a classification stage:

```text
Assignment
     │
     ▼
Subject Detection
     │
     ▼
Grade
```

---

In Markly:

```python
predicted_subject = detect_subject(content)
```

Possible outputs:

```text
Mathematics
English
Science
Programming
```

---

Why this matters:

The grading process depends on context.

A mathematics worksheet and an English essay require completely different evaluation criteria.

Classification allows downstream behavior to adapt automatically.

---

This pattern appears everywhere in AI systems:

### Email Systems

```text
Email
 │
 ▼
Spam Classifier
 │
 ▼
Route
```

---

### Customer Support

```text
Ticket
 │
 ▼
Intent Classifier
 │
 ▼
Department
```

---

### Markly

```text
Assignment
 │
 ▼
Subject Classifier
 │
 ▼
Teacher Persona
```

---

# Pattern 2 — The Router Pattern

Once classification exists, we can route work.

A router decides:

> Which processing path should handle this input?

---

Example:

```text
Upload
   │
   ▼
Router
```

---

If file is text:

```text
PDF
DOCX
TXT
```

↓

```text
Text Pipeline
```

---

If file is image:

```text
PNG
JPG
JPEG
```

↓

```text
Vision Pipeline
```

---

Markly uses routing here:

```python
if filename.endswith(
    (".png", ".jpg", ".jpeg")
):
    ...
else:
    ...
```

---

Architecture:

```text
Input
  │
  ▼
Router
  │
 ┌───────────────┐
 ▼               ▼
Text         Vision
Pipeline      Pipeline
```

---

This is one of the most common AI design patterns.

---

# Pattern 3 — The Persona Pattern

A persona changes model behavior without changing the model.

---

Input:

```text
Same model
```

---

Different personas:

```text
Math Teacher
English Teacher
Science Teacher
Programming Teacher
```

---

Result:

```text
Different behavior
```

---

Architecture:

```text
Assignment
      │
      ▼
Persona Selection
      │
      ▼
LLM
      │
      ▼
Subject-Specific Feedback
```

---

This pattern is often called:

> Role-based prompting

or

> Behavioral conditioning

---

Many AI products use personas:

* tutors
* interview coaches
* legal assistants
* sales assistants

Markly uses teacher personas.

---

# Pattern 4 — The Pipeline Pattern

A pipeline breaks a large problem into smaller stages.

---

Bad approach:

```text
One giant prompt
```

asking the model to:

* detect subject
* evaluate work
* score rubric
* generate report

all at once.

---

Better approach:

```text
Stage 1 → Classify
Stage 2 → Evaluate
Stage 3 → Score
Stage 4 → Generate Feedback
```

---

Markly gradually evolved into:

```text
Assignment
      │
      ▼
Subject Detection
      │
      ▼
Persona Selection
      │
      ▼
Rubric Evaluation
      │
      ▼
Score Calculation
      │
      ▼
Feedback Generation
      │
      ▼
PDF Report
```

---

This is a classic AI pipeline architecture.

---

Benefits:

* easier debugging
* easier testing
* easier validation
* lower prompt complexity

---

# Pattern 5 — The Validator Pattern

One of the most important upgrades in Markly came with rubrics.

---

Originally:

```text
Assignment
     │
     ▼
LLM
     │
     ▼
Grade
```

---

Problem:

The model owns grading.

---

Rubric architecture:

```text
Assignment
      │
      ▼
LLM Evaluation
      │
      ▼
Validator
      │
      ▼
Final Grade
```

---

The validator checks:

* scoring structure
* rubric compliance
* numerical consistency

---

Example:

```text
Accuracy 3/4
Working 2/3
Clarity 2/2
Answer 1/1
```

↓

```text
8/10
```

computed by code.

---

This pattern shifts control from:

```text
Model
```

to

```text
System
```

---

# Pattern 6 — The Memory Pattern

Memory was introduced in Part 10.

---

Without memory:

```text
Submission A
```

↓

```text
Feedback
```

↓

```text
Forget Everything
```

---

Next submission:

```text
Submission B
```

treated as brand new.

---

With memory:

```text
Submission A
      │
      ▼
Student Profile
      │
      ▼
Submission B
```

---

Now the system knows:

* recurring mistakes
* improvement trends
* historical grades
* learning trajectory

---

Architecture:

```text
Current Assignment
        │
        ▼
Student History
        │
        ▼
Combined Context
        │
        ▼
LLM
```

---

This is called:

> Retrieval-Augmented Context

a simplified form of memory augmentation.

---

# Pattern 7 — The Orchestrator Pattern

Markly's engine is not simply calling a model.

It orchestrates multiple models.

---

Traditional:

```text
Prompt
   │
   ▼
Model
```

---

Markly:

```text
Prompt
   │
   ▼
Orchestrator
   │
 ┌────┬────┬────┐
 ▼    ▼    ▼    ▼
GPT Claude Gemma Llama
```

---

The orchestrator manages:

* execution
* cancellation
* failure recovery
* timeout handling

---

This is a common enterprise AI pattern.

---

Examples:

* AI gateways
* agent platforms
* multi-model routers
* enterprise copilots

---

# Pattern 8 — The Artifact Pattern

Most AI demos stop here:

```text
Input
 │
 ▼
LLM
 │
 ▼
Text Output
```

---

Markly goes further.

It produces artifacts.

---

Example:

```text
Feedback
     │
     ▼
PDF Report
```

---

Artifacts are persistent outputs.

Examples:

* PDFs
* spreadsheets
* dashboards
* presentations
* reports

---

Architecture:

```text
AI Output
      │
      ▼
Artifact Generator
      │
      ▼
Downloadable File
```

---

This is often the difference between:

```text
Demo
```

and

```text
Workflow Tool
```

---

# Pattern 9 — Human-in-the-Loop Pattern

Even though Markly automates grading, teachers remain in control.

---

Teacher:

```text
Uploads assignment
Reviews feedback
Downloads report
```

---

Future versions may allow:

```text
Approve
Edit
Override
Reject
```

---

Architecture:

```text
AI Suggestion
       │
       ▼
Teacher Review
       │
       ▼
Final Decision
```

---

This is called:

> Human-in-the-Loop (HITL)

and is common in regulated environments.

---

# Putting All Patterns Together

By Part 11, Markly's architecture looks like:

```text
Assignment
      │
      ▼

Router
(Text / Vision)

      │
      ▼

Classifier
(Subject Detection)

      │
      ▼

Persona Selection

      │
      ▼

Rubric Evaluation

      │
      ▼

Validator

      │
      ▼

Scoring Engine

      │
      ▼

Feedback Generator

      │
      ▼

Student Memory

      │
      ▼

PDF Artifact Generator

      │
      ▼

Teacher
```

---

# Why These Patterns Matter

The biggest lesson from Markly is:

> AI applications are not model architectures.

They are system architectures.

The model is only one component.

Most production engineering effort goes into:

* routing
* orchestration
* validation
* memory
* artifacts
* workflow integration

rather than the model itself.

---

# Key Takeaways

Markly demonstrates several foundational AI system design patterns:

| Pattern            | Purpose                    |
| ------------------ | -------------------------- |
| Classifier         | Determine subject          |
| Router             | Select processing path     |
| Persona            | Control behavior           |
| Pipeline           | Decompose complexity       |
| Validator          | Enforce consistency        |
| Memory             | Maintain context over time |
| Orchestrator       | Manage multiple models     |
| Artifact Generator | Produce usable outputs     |
| Human-in-the-Loop  | Preserve teacher control   |

These patterns appear repeatedly in modern AI systems.
Understanding them is more valuable than learning any individual model API because models change frequently, but architectural patterns endure.

