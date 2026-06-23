# Part 11 — Building a Rubric & Validation Layer (Making Markly Reliable)

At this stage, Markly is already doing a lot:

* Multimodal grading (text + images)
* Subject detection
* Persona-based evaluation
* PDF report generation
* UI polish and status handling
* Student memory and progress tracking

But there’s a hidden problem in everything we’ve built so far:

> We are still fully trusting the LLM’s judgment.

That might be fine for casual use, but in real educational settings, it becomes risky.

Teachers typically expect:

* Consistent grading across students
* Stable scoring criteria
* Justifiable marks
* Reproducible evaluations

LLMs, on the other hand:

* can be inconsistent
* may drift in scoring strictness
* sometimes overpraise or overpenalize
* occasionally miss rubric structure

So in this chapter, we add a critical system layer:

> **A rubric-driven validation engine**

This is what turns Markly from “smart assistant” into something closer to a **reliable grading system**.

---

# The Core Idea: Separate Thinking from Scoring

Right now, Markly does this:

```text id="rb_1"
Student Work → LLM → Feedback + Grade
```

We will upgrade it to:

```text id="rb_2"
Student Work → LLM Analysis → Rubric Scoring Engine → Final Grade
```

So the LLM becomes:

* an evaluator of evidence
* not the final authority on marks

---

# Step 1 — Defining a Rubric System

Create a new file:

```text id="rb_file"
rubrics.py
```

We will define structured scoring rules per subject.

---

## Mathematics Rubric

```python id="rb_math"
MATHEMATICS_RUBRIC = {
    "accuracy": 4,
    "working": 3,
    "clarity": 2,
    "final_answer": 1
}
```

---

## English Rubric

```python id="rb_eng"
ENGLISH_RUBRIC = {
    "grammar": 3,
    "structure": 3,
    "argument": 3,
    "vocabulary": 1
}
```

---

## Programming Rubric

```python id="rb_code"
PROGRAMMING_RUBRIC = {
    "correctness": 4,
    "readability": 2,
    "efficiency": 2,
    "design": 2
}
```

---

# Why This Matters

Instead of:

> “Give a grade”

we now define:

> “What counts toward a grade”

This is a fundamental shift from:

* subjective grading → structured evaluation

---

# Step 2 — Forcing the LLM to Follow a Rubric

We now modify the prompt.

Open `engine.py`.

---

## New Structured Prompt

```python id="rb_prompt"
RUBRIC_EVALUATION_PROMPT = """
You are a strict grading assistant.

You must evaluate the student work using the rubric provided.

IMPORTANT RULES:
- Do NOT assign a final grade yet.
- Only evaluate each category.
- Provide a score for each category.
- Keep reasoning short and evidence-based.

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

---

# Step 3 — Getting Structured Output from the LLM

We now modify our grading function:

```python id="rb_fn"
def evaluate_with_rubric(assignment, rubric):
```

---

## LLM Call

```python id="rb_call"
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

---

# Step 4 — Parsing the Scores

We must extract numbers from structured text.

Example output:

```text id="rb_out"
accuracy: 3/4
working: 2/3
clarity: 1/2
final_answer: 1/1
```

---

## Parser Function

```python id="rb_parse"
import re

def parse_scores(text):

    scores = re.findall(r"(\d+)\s*/\s*(\d+)", text)

    parsed = [(int(a), int(b)) for a, b in scores]

    return parsed
```

---

# Step 5 — Calculating Final Grade

Now we compute a weighted score.

```python id="rb_grade"
def compute_final_grade(parsed_scores):

    total_obtained = sum([a for a, b in parsed_scores])
    total_max = sum([b for a, b in parsed_scores])

    return total_obtained, total_max
```

---

# Step 6 — Reintroducing the LLM for Feedback (Safely)

Now we use the LLM again—but only for explanation.

```python id="rb_feedback"
FINAL_FEEDBACK_PROMPT = """
You are a teacher.

Based on the rubric scores below, write clear feedback.

Rubric Scores:
{scores}

Provide:
- strengths
- weaknesses
- improvement advice
- summary
"""
```

---

# Step 7 — Full Pipeline

Now combine everything:

```python id="rb_pipeline"
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

```python id="rb_replace"
result = grade_assignment(...)
```

With:

```python id="rb_replace2"
result = grade_with_rubric(
    assignment,
    rubrics[predicted_subject]
)
```

---

# What We Just Solved

We introduced **consistency control**.

Now Markly:

### Before

* LLM decides grades freely

### After

* LLM evaluates evidence
* System computes score
* LLM only explains results

---

# Why This Is a Major Engineering Upgrade

This design prevents:

* inflated grades
* inconsistent marking
* hallucinated scoring
* subjective drift across subjects

And introduces:

* repeatability
* auditability
* structured reasoning
* explainable scoring

---

# Updated System Architecture

```text id="rb_arch"
Student Work
      │
      ▼
LLM Analysis (Evidence Extraction)
      │
      ▼
Rubric Scoring Engine (Deterministic)
      │
      ▼
Final Score Computation
      │
      ▼
LLM Feedback Generator (Explanation Only)
      │
      ▼
PDF Report Generator
```

---

# Final Evolution of Markly

Across all chapters, Markly has evolved from:

### Instalment 1

Simple AI grading script

### Instalments 5–6

Multimodal assistant (text + images)

### Instalment 7

Professional report generator

### Instalment 8

Polished UX with status + reliability

### Instalment 9

Automatic subject detection

### Instalment 10

Student memory system

### Instalment 11 (now)

Rubric-driven evaluation engine

---

# What Markly Has Become

At this point, Markly is no longer just a demo project.

It is:

> A structured AI-assisted assessment system with:

* multimodal understanding
* subject-aware reasoning
* memory of student progress
* rubric-based scoring
* explainable evaluation
* professional reporting

---

# Final Instalment Preview

In the final instalment, we will push Markly into a production-ready direction:

We’ll add:

* role-based access (teacher vs admin)
* dataset export for analytics
* grading analytics dashboard
* bias detection in grading patterns
* and a simple evaluation “audit trail”

This is where Markly transitions from a project into a **real educational AI system design**.
