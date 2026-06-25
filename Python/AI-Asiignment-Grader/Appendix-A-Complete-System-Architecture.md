# Appendix A — Complete System Architecture

By the end of Part 11, Markly has evolved far beyond a simple grading application.

What began as a document-upload interface connected to a language model has become a layered educational AI system with multiple independent subsystems working together.

Understanding the complete architecture is important because modern AI applications are not built around a single prompt.

They are built around **pipelines of specialized components**, each responsible for a specific task.

This appendix provides a holistic view of how all Markly components interact.

---

# The Big Picture

The complete system can be visualized as:

```text
                        Teacher
                           │
                           ▼
                  Upload Assignment
                           │
                           ▼
                  File Processing Layer
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
      PDF               DOCX              Images
        │                  │                  │
        └──────────────────┼──────────────────┘
                           ▼
                  Content Extraction
                           │
                           ▼
                Subject Detection Layer
                           │
                           ▼
                Persona Selection Layer
                           │
                           ▼
                 Rubric Selection Layer
                           │
                           ▼
               Rubric Evaluation Engine
                           │
                           ▼
                 Validation & Scoring
                           │
                           ▼
                Feedback Generation
                           │
                           ▼
                 Student Memory Layer
                           │
                           ▼
                PDF Report Generation
                           │
                           ▼
                  Teacher Download
```

Each box represents an independent subsystem.

This separation is intentional.

---

# Architectural Philosophy

Markly follows a simple engineering principle:

> One component, one responsibility.

Instead of creating a massive AI function that does everything, the system is decomposed into layers.

Each layer solves one problem.

```text
Input
  ↓
Classification
  ↓
Evaluation
  ↓
Validation
  ↓
Reporting
```

This makes the application:

* easier to debug
* easier to scale
* easier to test
* easier to replace components later

---

# Layer 1 — User Interface Layer

File:

```text
app.py
```

Responsibility:

```text
Human Interaction
```

The UI layer handles:

* file uploads
* subject display
* student names
* status messages
* spinners
* feedback display
* report downloads

The UI does not perform grading.

The UI only coordinates workflow.

---

## UI Responsibilities

```text
Teacher Uploads File
       │
       ▼
Validate Input
       │
       ▼
Call Backend Services
       │
       ▼
Display Results
```

The UI should never contain grading logic.

That belongs elsewhere.

---

# Layer 2 — File Processing Layer

File:

```text
utils.py
```

Responsibility:

```text
Convert files into usable content
```

Supported inputs:

```text
PDF
DOCX
PNG
JPG
JPEG
```

Examples:

### PDF

```text
PDF
 ↓
Extract Text
 ↓
String
```

### Image

```text
Image
 ↓
Base64 Encoding
 ↓
Vision Model Input
```

This layer hides file complexity from the rest of the system.

---

# Layer 3 — Subject Detection Layer

File:

```text
engine.py
```

Responsibility:

```text
Determine assignment subject
```

Example:

```text
Student Submission
        │
        ▼
Subject Classifier
        │
        ▼
Mathematics
```

Supported classifications:

* Mathematics
* English
* Science
* Programming

This layer determines which educational lens will be used.

---

# Why Subject Detection Matters

The same content can be interpreted differently depending on context.

For example:

```text
for i in range(10):
```

To an English teacher:

```text
Meaningless text
```

To a Programming teacher:

```text
Python loop
```

Classification ensures the correct evaluator is selected.

---

# Layer 4 — Persona Layer

File:

```text
personas.py
```

Responsibility:

```text
Define teacher behavior
```

Example:

```text
Subject
    │
    ▼
Programming Persona
```

Result:

```text
Evaluate:
- correctness
- readability
- design
- efficiency
```

Personas influence reasoning style.

They do not determine scores.

---

# Layer 5 — Rubric Layer

File:

```text
rubrics.py
```

Responsibility:

```text
Define grading standards
```

Example:

```python
{
    "Correctness": 4,
    "Readability": 2,
    "Efficiency": 2,
    "Design": 2
}
```

This layer defines:

* what matters
* how much it matters

The rubric belongs to the system, not the AI.

---

# Layer 6 — AI Evaluation Layer

File:

```text
engine.py
```

Responsibility:

```text
Evaluate evidence
```

Input:

```text
Assignment
+
Rubric
+
Persona
```

Output:

```text
Category Scores

Correctness: 4/4
Readability: 2/2
Efficiency: 1/2
Design: 2/2
```

Notice:

The model does not produce a final grade.

It only evaluates categories.

---

# Layer 7 — Validation Layer

File:

```text
engine.py
```

Responsibility:

```text
Verify AI output
```

Examples:

### Valid

```text
3/4
```

### Invalid

```text
5/4
```

Validation protects against:

* malformed outputs
* hallucinated scores
* parsing errors

This layer increases trustworthiness.

---

# Layer 8 — Deterministic Scoring Layer

Responsibility:

```text
Compute Final Grade
```

Example:

```text
Accuracy      3/4
Working       2/3
Clarity       2/2
Final Answer  1/1
```

System computes:

```text
8/10
```

This score comes from code.

Not from AI.

This is one of the most important design decisions in Markly.

---

# Layer 9 — Feedback Generation Layer

Responsibility:

```text
Explain Results
```

Input:

```text
Rubric Evaluation
```

Output:

```text
Strengths

Areas for Improvement

Suggestions
```

The AI returns to its strongest role:

```text
Communication
```

Not scoring.

---

# Layer 10 — Student Memory Layer

File:

```text
storage.py
```

Responsibility:

```text
Long-Term Learning History
```

Stored data:

```json
{
  "John Tan": {
    "history": [...]
  }
}
```

Capabilities:

* progress tracking
* repeated mistake detection
* longitudinal feedback
* historical records

This makes grading contextual.

---

# Layer 11 — Reporting Layer

File:

```text
report.py
```

Responsibility:

```text
Generate Deliverables
```

Outputs:

```text
PDF Report
```

Contains:

* feedback
* scores
* metadata
* grading date
* student information

This transforms grading into a reusable artifact.

---

# Multi-Model AI Infrastructure

Markly uses concurrent model orchestration.

```text
Prompt
   │
   ├── GPT OSS
   ├── Gemma
   ├── Llama
   └── Qwen
```

All execute simultaneously.

```text
First Successful Result
        │
        ▼
Returned
```

Remaining tasks:

```text
Cancelled
```

Benefits:

* lower latency
* fault tolerance
* model redundancy

---

# Complete Runtime Flow

A single assignment follows this lifecycle:

```text
Teacher Uploads File
         │
         ▼
File Processing
         │
         ▼
Subject Detection
         │
         ▼
Persona Selection
         │
         ▼
Rubric Selection
         │
         ▼
Rubric Evaluation
         │
         ▼
Validation
         │
         ▼
Deterministic Scoring
         │
         ▼
Feedback Generation
         │
         ▼
Student History Update
         │
         ▼
PDF Report Creation
         │
         ▼
Download
```

This entire flow happens automatically.

---

# Final Architectural View

Markly is no longer a single AI prompt.

It is a layered AI-native application composed of:

* User Interface Layer
* File Processing Layer
* Subject Classification Layer
* Teacher Persona Layer
* Rubric Layer
* AI Evaluation Layer
* Validation Layer
* Deterministic Scoring Layer
* Student Memory Layer
* Reporting Layer

Together, these components create a system that is:

* Explainable
* Auditable
* Extensible
* Maintainable
* Educationally meaningful

Most importantly:

> Markly demonstrates a fundamental AI engineering principle: successful AI applications are systems of cooperating components, not isolated model calls.
