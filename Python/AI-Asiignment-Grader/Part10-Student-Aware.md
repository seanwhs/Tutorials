# Part 10 — Making Markly “Student-Aware” (Memory + Progress Tracking)

Right now, Markly is impressive:

* It reads assignments
* Detects the subject
* Applies the correct teacher persona
* Grades using AI
* Generates PDF reports
* Handles images and documents

But there’s still something missing that real teachers rely on every day:

> **Memory of the student over time**

A real teacher doesn’t grade assignments in isolation. They notice patterns:

* “This student always makes sign errors in algebra”
* “Their essays are improving in structure but weak in vocabulary”
* “They are inconsistent with indentation in Python”
* “They’ve improved compared to last submission”

Right now, Markly forgets everything after each submission.

In this chapter, we’ll add a lightweight memory layer so Markly can begin tracking student progress.

---

# The New Capability: Persistent Student Profiles

We are introducing a new concept:

```text id="mem_1"
Student Profile
│
├── Assignments Submitted
├── Past Feedback
├── Common Mistakes
└── Progress Trend
```

This turns Markly from:

> “a grading tool”

into:

> “a learning assistant over time”

---

# Step 1 — Choosing a Simple Storage Strategy

We will NOT use a database yet.

To keep things beginner-friendly, we’ll start with:

* JSON files per student

Why JSON?

* Simple
* Human-readable
* No setup required
* Works in Hugging Face Spaces
* Easy to debug

---

# Step 2 — Creating a Storage Layer

Create a new file:

```text id="mem_file"
storage.py
```

---

## Basic Structure

```python id="mem_2"
import os
import json
from datetime import datetime
```

We will store data like this:

```json id="mem_json"
{
  "John Tan": {
    "history": [
      {
        "subject": "Mathematics",
        "grade": "8/10",
        "feedback": "...",
        "timestamp": "2026-06-24"
      }
    ]
  }
}
```

---

# Step 3 — Load & Save Functions

```python id="mem_3"
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

# Step 4 — Adding a Student Record

```python id="mem_4"
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

# Step 5 — Extracting Grade from Feedback

Our AI currently returns text like:

```text id="mem_5"
## Final Grade: 8/10
```

We need to extract this.

Add helper in `engine.py`:

```python id="mem_6"
import re

def extract_grade(text):

    match = re.search(r"(\d+)\s*/\s*(\d+)", text)

    if match:
        return match.group(0)

    return "N/A"
```

---

# Step 6 — Updating the Grading Pipeline

Now modify `app.py`.

Import storage:

```python id="mem_7"
from storage import add_record
from engine import extract_grade
```

---

## After AI returns result:

```python id="mem_8"
grade = extract_grade(result)

student_name = "Unknown"  # later we improve this

add_record(

    student=student_name,

    subject=predicted_subject,

    grade=grade,

    feedback=result

)
```

---

# Step 7 — Adding Student Identity (Simple Version)

For now, we add a simple input box.

In `app.py`:

```python id="mem_9"
student_name = pn.widgets.TextInput(
    name="Student Name",
    placeholder="Enter student name"
)
```

Add it to UI:

```python id="mem_10"
controls.insert(0, student_name)
```

---

# Step 8 — Showing Student History

Now we make Markly more intelligent.

Add function:

```python id="mem_11"
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

---

# Step 9 — Display History in UI

In `app.py`:

```python id="mem_12"
history_pane = pn.pane.Markdown("")
```

Update when grading:

```python id="mem_13"
history_pane.object = get_student_history(student_name.value)
```

Add to layout:

```python id="mem_14"
results.append(history_pane)
```

---

# Step 10 — Upgrading the AI Prompt (Critical Step)

Now we make the AI “aware” of past performance.

Modify `grade_assignment` in `engine.py`:

```python id="mem_15"
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

# Step 11 — Passing History into AI

In `app.py`:

```python id="mem_16"
history = get_student_history(student_name.value)

result = grade_assignment(

    assignment,
    predicted_subject,
    history

)
```

---

# What We Just Built

Markly now has **memory**.

It can:

* Remember past submissions
* Track grades over time
* Identify recurring mistakes
* Provide longitudinal feedback

---

# Updated System Architecture

```text id="mem_arch"
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
AI (Context + History) ◄─────┘
        │
        ▼
Generate Feedback
        │
        ▼
Store New Record
        │
        ▼
PDF Report
```

---

# Why This Is a Major Upgrade

We’ve now crossed an important threshold:

### Before

* Stateless grading
* No memory
* Each assignment independent

### Now

* Persistent student profiles
* Performance tracking
* Context-aware feedback
* Progress-based evaluation

---

# What’s Next

At this point, Markly is no longer just a tool.

It is becoming a **system**.

But there is still one final limitation:

> It still trusts the AI completely.

There is no verification layer.

No consistency checks.

No rubric enforcement.

In the final instalment, we will build a **grading validator layer** that reviews AI output, enforces structured rubrics, and ensures consistent scoring across all subjects—bringing Markly from a useful assistant to a reliable assessment system suitable for real educational environments.
