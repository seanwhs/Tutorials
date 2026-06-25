# Part 10 — Making Markly Student-Aware (Memory, Progress Tracking & Educational Intelligence)

At this point, Markly has evolved far beyond a simple grading application.

It can:

* Process PDFs, DOCX files, and images
* Understand handwritten assignments
* Detect subjects automatically
* Apply subject-specific teacher personas
* Generate grading feedback
* Produce professional PDF reports

But there is still one major difference between Markly and a real teacher.

A real teacher remembers.

---

# The Missing Ingredient: Educational Memory

Imagine two students submitting the same assignment.

Student A:

```text
Previous grade: 4/10
Current grade: 8/10
```

Student B:

```text
Previous grade: 9/10
Current grade: 8/10
```

A traditional grading system sees:

```text
8/10
8/10
```

A teacher sees:

```text
Student A improved dramatically.

Student B regressed.
```

The score is identical.

The educational meaning is completely different.

---

# Why Stateless Grading Is Not Enough

Today, Markly treats every submission independently.

```text
Submission
    ↓
Grade
    ↓
Forget
```

There is no continuity.

No context.

No memory.

This creates several limitations.

Markly cannot determine:

* Whether the student is improving
* Whether mistakes are recurring
* Whether interventions are working
* Whether learning objectives are being achieved

Real education is longitudinal.

Assessment is not about a single assignment.

It is about progression across time.

---

# Introducing Student Profiles

We introduce a new concept:

```text
Student
    │
    ├── Assignment History
    ├── Grade History
    ├── Common Mistakes
    ├── Strength Areas
    ├── Weakness Areas
    └── Learning Trends
```

This transforms Markly from:

```text
AI Grader
```

into:

```text
AI Learning Assistant
```

---

# Designing the Memory Layer

We create a dedicated module:

```text
storage.py
```

Updated architecture:

```text
markly/

app.py
engine.py
utils.py
personas.py
rubrics.py
report.py
storage.py
```

Responsibilities:

| Module      | Responsibility      |
| ----------- | ------------------- |
| app.py      | UI                  |
| engine.py   | AI orchestration    |
| personas.py | Teacher behavior    |
| rubrics.py  | Assessment criteria |
| report.py   | PDF generation      |
| storage.py  | Student memory      |

---

# What Should We Store?

A common beginner mistake is storing entire AI outputs forever.

Instead, store structured educational signals.

Bad:

```json
{
  "feedback": "Very long AI response..."
}
```

Better:

```json
{
  "grade": "8/10",
  "subject": "Mathematics",
  "strengths": [
    "Algebraic manipulation"
  ],
  "weaknesses": [
    "Sign errors"
  ]
}
```

This makes future analysis much easier.

---

# Student Record Structure

A student profile might look like:

```json
{
  "John Tan": {
    "history": [
      {
        "timestamp": "2026-06-24T10:00:00",
        "subject": "Mathematics",
        "grade": "8/10",
        "strengths": [
          "Equation solving"
        ],
        "weaknesses": [
          "Negative numbers"
        ]
      }
    ]
  }
}
```

Notice that we are storing educational metadata, not just raw text.

---

# Building the Storage Layer

Create:

```python
# storage.py

import os
import json

DB_FILE = "students.json"
```

---

## Load Database

```python
def load_db():

    if not os.path.exists(DB_FILE):
        return {}

    with open(DB_FILE, "r", encoding="utf-8") as f:
        return json.load(f)
```

---

## Save Database

```python
def save_db(db):

    with open(DB_FILE, "w", encoding="utf-8") as f:
        json.dump(
            db,
            f,
            indent=2,
            ensure_ascii=False
        )
```

---

# Recording Student Activity

Every completed grading cycle generates a record.

```python
def add_record(
    student,
    subject,
    grade,
    feedback
):
```

The record becomes part of the student's learning history.

---

# Creating Student Identity

Markly needs a way to identify the learner.

Add a new field:

```python
student_name = pn.widgets.TextInput(
    name="Student Name"
)
```

The workflow becomes:

```text
Student Name
      ↓
Upload Assignment
      ↓
Grade
```

This allows history to be associated with a specific learner.

---

# Retrieving Student History

Before grading, Markly loads prior context.

```python
history = get_student_history(
    student_name.value
)
```

Example:

```text
Mathematics — 6/10
Mathematics — 7/10
Mathematics — 8/10
```

The system now has context.

---

# Making the AI History-Aware

This is the most important upgrade.

Previously:

```python
grade_assignment(
    assignment,
    subject
)
```

Now:

```python
grade_assignment(
    assignment,
    subject,
    history
)
```

The prompt becomes:

```text
Previous Performance:

- Algebra: recurring sign errors
- Fractions: improved significantly

Current Assignment:
...
```

The model can now reason about growth.

---

# Detecting Learning Trends

Once history exists, trend analysis becomes possible.

Example:

```python
grades = [4, 5, 6, 8]
```

Trend:

```text
Improving
```

Or:

```python
grades = [9, 8, 8, 7]
```

Trend:

```text
Declining
```

Markly can now identify:

* Consistent improvement
* Plateauing performance
* Regression
* Volatile learning patterns

---

# Recurring Mistake Detection

One powerful capability emerges naturally.

Suppose three submissions contain:

```text
Sign errors
Sign errors
Sign errors
```

Markly can infer:

```text
Persistent weakness:
Negative number operations
```

This mirrors how teachers identify long-term learning gaps.

---

# Progress Summaries

Markly can generate summaries such as:

```text
Student Progress Summary

Subject:
Mathematics

Trend:
Improving

Recurring Weakness:
Negative numbers

Strongest Area:
Algebra

Recommendation:
Additional practice with signed arithmetic.
```

This is far more valuable than isolated assignment feedback.

---

# Updated Architecture

```text
Upload Assignment
        │
        ▼
Detect Subject
        │
        ▼
Retrieve Student History
        │
        ▼
AI Grading
(Current + Historical Context)
        │
        ▼
Feedback
        │
        ▼
Update Student Profile
        │
        ▼
Generate Report
```

---

# The Educational Intelligence Layer

This chapter introduces a fundamental architectural shift.

Before:

```text
Assignment
    ↓
Grade
```

After:

```text
Assignment
    ↓
Student Context
    ↓
Grade
    ↓
Learning Insight
```

Markly is no longer simply evaluating work.

It is beginning to understand the learner.

---

# What We Have Built

Markly now supports:

* Persistent student profiles
* Historical assignment tracking
* Learning trend analysis
* Recurring mistake detection
* Context-aware grading
* Progress-aware feedback

This is the first step toward educational intelligence.

The system no longer asks:

> "How good is this assignment?"

It can now ask:

> "How is this student developing over time?"

---

# What's Next

Memory introduces a new challenge.

Once Markly remembers students, teachers will begin relying on its evaluations more heavily.

That means consistency becomes critical.

Questions naturally emerge:

* Did the AI apply the rubric correctly?
* Is grading consistent across students?
* Are scores justified by evidence?
* Would the same assignment receive the same score tomorrow?

In the next chapter, we will introduce a **Rubric-Driven Validation Layer**, ensuring that every grade produced by Markly is explainable, auditable, and aligned with defined assessment criteria.
