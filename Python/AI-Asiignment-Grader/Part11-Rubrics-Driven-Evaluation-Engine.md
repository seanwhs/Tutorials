# Part 11 — Building a Rubric & Validation Layer (Making Markly Reliable)

At this stage, Markly is already doing a lot:

* Multimodal grading (text + images)
* Subject detection
* Persona-based evaluation
* PDF report generation
* UI polish and status handling
* Student memory and progress tracking

But there’s a hidden problem in everything built so far:

> We are still fully trusting the LLM’s judgment.

That works for demos, but not for real educational environments where grading must be consistent, defensible, and repeatable.

Teachers expect:

* Stable scoring criteria across students
* Justifiable marks tied to explicit standards
* Consistent grading across runs
* Auditability of how marks were derived

LLMs, however:

* can vary in strictness across runs
* may shift emphasis between criteria
* can over/under-weight implicit signals
* sometimes produce unstructured reasoning

So we introduce a critical system layer:

> **A rubric-driven validation engine**

This is what moves Markly from a “smart assistant” to a **reliable assessment system**.

---

# The Core Idea: Separate Thinking from Scoring

Before:

```text
Student Work → LLM → Feedback + Grade
```

After:

```text
Student Work → LLM Analysis → Rubric Scoring Engine → Final Grade
```

The key shift:

* The LLM no longer “decides the grade”
* It only evaluates evidence against criteria
* The system computes the final score deterministically

---

# Step 1 — Defining a Rubric System

Create:

```text
rubrics.py
```

Each subject now has explicit, structured scoring dimensions.

---

## Mathematics Rubric

```python
MATHEMATICS_RUBRIC = {
    "accuracy": 4,
    "working": 3,
    "clarity": 2,
    "final_answer": 1
}
```

---

## English Rubric

```python
ENGLISH_RUBRIC = {
    "grammar": 3,
    "structure": 3,
    "argument": 3,
    "vocabulary": 1
}
```

---

## Programming Rubric

```python
PROGRAMMING_RUBRIC = {
    "correctness": 4,
    "readability": 2,
    "efficiency": 2,
    "design": 2
}
```

---

# Why This Matters

Instead of asking:

> “What grade should this get?”

We now define:

> “What dimensions define a good answer?”

This is a shift from:

* subjective grading → structured evaluation
* implicit criteria → explicit scoring rules
* model opinion → system-defined standards

---

# Step 2 — Forcing the LLM into Rubric Evaluation Mode

In `engine.py`, introduce a strict evaluation prompt:

```python
RUBRIC_EVALUATION_PROMPT = """
You are a strict grading assistant.

You must evaluate the student work using ONLY the rubric provided.

IMPORTANT RULES:
- Do NOT assign a final grade
- Evaluate each rubric category independently
- Provide a score per category
- Base scoring only on evidence in the submission
- Keep reasoning short and factual

Rubric:
{rubric}

Student Work:
{assignment}

Return format:

Category Scores:
- category: score/maximum
- category: score/maximum

Short Justification:
...
"""
```

This is crucial: it constrains the model to structured evaluation rather than narrative grading.

---

# Step 3 — LLM as an Evaluator (Not a Judge)

```python
def evaluate_with_rubric(assignment, rubric):
```

### LLM Call

```python
response = client.chat.completions.create(
    model="openai/gpt-oss-20b:free",
    messages=[
        {
            "role": "user",
            "content": RUBRIC_EVALUATION_PROMPT.format(
                rubric=rubric,
                assignment=assignment
            )
        }
    ],
    temperature=0
)
```

Key design choice:

* temperature = 0 → reduces variability in scoring behavior

---

# Step 4 — Parsing Structured Scores

We extract numeric values from the LLM output:

```python
import re

def parse_scores(text):
    scores = re.findall(r"(\d+)\s*/\s*(\d+)", text)
    return [(int(a), int(b)) for a, b in scores]
```

This converts:

```text
accuracy: 3/4
working: 2/3
```

into structured numeric data:

```python
[(3, 4), (2, 3)]
```

---

# Step 5 — Deterministic Grade Computation

Now grading is fully system-controlled:

```python
def compute_final_grade(parsed_scores):
    total_obtained = sum(a for a, b in parsed_scores)
    total_max = sum(b for a, b in parsed_scores)
    return total_obtained, total_max
```

At this point:

> The grade is no longer “generated” — it is computed.

---

# Step 6 — LLM for Feedback Only

We reintroduce the LLM, but with a restricted role:

> It explains results, not determines them.

```python
FINAL_FEEDBACK_PROMPT = """
You are a teacher.

Based on the rubric scores below, provide feedback.

Rubric Scores:
{scores}

Include:
- strengths
- weaknesses
- improvement advice
- summary
"""
```

This separation is important:

* Scoring → deterministic system
* Feedback → language model

---

# Step 7 — Full Rubric-Based Pipeline

```python
def grade_with_rubric(assignment, rubric):

    raw = evaluate_with_rubric(assignment, rubric)

    parsed = parse_scores(raw)

    obtained, total = compute_final_grade(parsed)

    feedback = client.chat.completions.create(
        model="openai/gpt-oss-20b:free",
        messages=[
            {
                "role": "user",
                "content": FINAL_FEEDBACK_PROMPT.format(
                    scores=raw
                )
            }
        ],
        temperature=0
    )

    return {
        "score": f"{obtained}/{total}",
        "feedback": feedback.choices[0].message.content
    }
```

---

# Step 8 — Integrating Into Markly

Replace:

```python
result = grade_assignment(...)
```

With:

```python
result = grade_with_rubric(
    assignment,
    rubrics[predicted_subject]
)
```

---

# What This Solves

### Before (Unstructured AI Grading)

* Inconsistent scoring
* Hidden reasoning
* No clear grading standard
* Hard to audit

### After (Rubric-Based System)

* Consistent evaluation criteria
* Transparent scoring breakdown
* Deterministic final grade computation
* Explainable feedback layer

---

# Updated System Architecture

```text
Student Work
      │
      ▼
LLM: Evidence Extraction
      │
      ▼
Rubric Evaluation Layer (Structured Output)
      │
      ▼
Deterministic Scoring Engine
      │
      ▼
LLM: Feedback Generator (Explanation Only)
      │
      ▼
PDF Report Generator
```

---

# Why This Is a Major Engineering Upgrade

This introduces three key production-grade properties:

### 1. Consistency

Same input → same scoring breakdown

### 2. Auditability

Every mark maps to a rubric dimension

### 3. Control

The system, not the model, owns grading logic

---

# Final Evolution of Markly (So Far)

* **Early version:** simple LLM grading tool
* **Multimodal version:** handles text + images
* **UX version:** professional reporting pipeline
* **Memory version:** tracks student progress
* **Rubric version (now):** structured, reliable evaluation system

---

# What Markly Has Become

At this stage, Markly is no longer a demo.

It is a structured AI-assisted assessment system with:

* multimodal understanding
* subject-aware reasoning
* student memory tracking
* rubric-based scoring
* deterministic grading logic
* explainable feedback generation
* professional report output

---

# Next Step Preview

The next evolution is operational and production-focused:

We will add:

* grading audit trails (who/what produced each score)
* analytics dashboards for teachers
* bias detection across student groups
* role-based access control (teacher vs admin)
* dataset export for institutional analysis

This is where Markly transitions from a project into a **real educational AI system architecture**.
