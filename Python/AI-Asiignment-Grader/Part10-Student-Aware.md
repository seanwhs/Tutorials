# Part 10 — Making Markly “Student-Aware” (Memory + Progress Tracking)

Right now, Markly is already powerful:

* It reads assignments
* Detects the subject
* Applies the correct teacher persona
* Grades using AI
* Generates PDF reports
* Handles images and documents

But there’s still one critical limitation:

> **It treats every submission as if the student is starting from zero.**

Real teachers don’t work this way.

They build an understanding over time:

* “This student keeps making sign errors in algebra”
* “Their essay structure is improving, but vocabulary is still weak”
* “Their Python indentation is inconsistent”
* “They are improving compared to last submission”

Right now, Markly forgets everything after each run.

In this chapter, we fix that.

We introduce **persistent student memory + progress tracking**.

---

# The New Capability: Persistent Student Profiles

We introduce a simple but powerful concept:

```text
Student Profile
│
├── Assignments Submitted
├── Past Feedback
├── Common Mistakes
└── Progress Trend
```

This shifts Markly from:

> a stateless grading tool

to:

> a longitudinal learning assistant

---

# Step 1 — Storage Strategy (Keep It Simple)

We will NOT use a database yet.

Instead, we use:

> **JSON files per system (students.json)**

Why this approach works:

* Zero setup
* Easy debugging
* Works in Hugging Face Spaces
* Human-readable
* Enough for MVP-level persistence

---

# Step 2 — Create `storage.py`

Create a new file:

```python
storage.py
```

---

## Core Imports

```python
import os
import json
from datetime import datetime
```

---

## Data Format

Each student is stored like this:

```json
{
  "John Tan": {
    "history": [
      {
        "subject": "Mathematics",
        "grade": "8/10",
        "feedback": "...",
        "timestamp": "2026-06-24T10:00:00"
      }
    ]
  }
}
```

---

## Load & Save Functions

```python
DB_FILE = "students.json"


def load_db():
    if not os.path.exists(DB_FILE):
        return {}

    with open(DB_FILE, "r") as f:
        return json.load(f)


def save_db(db):
    with open(DB_FILE, "w") as f:
        json.dump(db, f, indent=2)
```

---

## Add Student Record

```python
def add_record(student, subject, grade, feedback):

    db = load_db()

    if student not in db:
        db[student] = {"history": []}

    db[student]["history"].append({
        "subject": subject,
        "grade": grade,
        "feedback": feedback,
        "timestamp": datetime.now().isoformat()
    })

    save_db(db)
```

Now Markly can remember.

---

# Step 3 — Extract Grades from AI Output

We need structured data from unstructured text.

In `engine.py`:

```python
import re


def extract_grade(text):
    match = re.search(r"(\d+)\s*/\s*(\d+)", text)
    return match.group(0) if match else "N/A"
```

This allows:

* "8/10"
* "85 / 100"
* similar formats

---

# Step 4 — Student Identity (Minimal Version)

In `app.py`, add:

```python
student_name = pn.widgets.TextInput(
    name="Student Name",
    placeholder="Enter student name"
)
```

Then include it in UI controls:

```python
controls.insert(0, student_name)
```

---

# Step 5 — Retrieve Student History

We now expose memory back into the system.

```python
from storage import load_db


def get_student_history(name):

    db = load_db()

    if name not in db:
        return "No previous records."

    history = db[name]["history"]

    output = "## Previous Performance\n\n"

    for h in history[-5:]:
        output += f"""
- Subject: {h['subject']}
- Grade: {h['grade']}
- Date: {h['timestamp'][:10]}
---
"""

    return output
```

We only show the **last 5 records** to avoid prompt overload.

---

# Step 6 — Display History in UI

```python
history_pane = pn.pane.Markdown("")
```

Update after grading:

```python
history_pane.object = get_student_history(student_name.value)
```

Add to layout:

```python
results.append(history_pane)
```

---

# Step 7 — Make the AI Student-Aware (Critical Upgrade)

Now we inject memory into the model.

In `engine.py`:

```python
def grade_assignment(assignment, subject, history=""):

    prompt = f"""
You are a teacher grading a student's work.

## Student History
{history}

## Current Assignment
{assignment}

Provide:
- strengths
- weaknesses
- improvement over time (if applicable)
- final grade
"""
```

---

# Step 8 — Pass History Into the Model

In `app.py`:

```python
from storage import add_record
from engine import extract_grade
```

---

## Before calling AI:

```python
history = get_student_history(student_name.value)

result = grade_assignment(
    assignment,
    predicted_subject,
    history
)
```

---

## After AI returns result:

```python
grade = extract_grade(result)

add_record(
    student=student_name.value,
    subject=predicted_subject,
    grade=grade,
    feedback=result
)
```

---

# Step 9 — System Architecture (Now Stateful)

```text
Upload Assignment
        │
        ▼
Extract Content
        │
        ▼
Detect Subject
        │
        ▼
Fetch Student History ───────┐
        │                    │
        ▼                    │
Grade Assignment             │
        │                    │
        ▼                    │
AI (Current + History) ◄─────┘
        │
        ▼
Generate Feedback
        │
        ▼
Store Updated Record
        │
        ▼
PDF Report
```

---

# What We Just Built

Markly now has **memory across time**.

It can:

* Track student progress
* Detect recurring mistakes
* Compare performance across submissions
* Provide longitudinal feedback
* Personalize grading contextually

---

# Why This Is a Major Upgrade

### Before (Stateless System)

* Each assignment is isolated
* No continuity
* No learning trajectory

### Now (Stateful System)

* Persistent student profiles
* History-aware feedback
* Progress tracking
* Early form of “educational intelligence”

---

# What This Enables Next

This is where Markly starts behaving like a real pedagogical system.

But there is still a missing layer:

> The system currently **trusts the AI completely**

There is:

* No rubric enforcement
* No scoring validation
* No consistency checks across students

In the next stage, we will build a:

> **Grading Validator Layer**

This will enforce structure, reliability, and consistency—turning Markly from a helpful assistant into a **trustworthy assessment system**.
