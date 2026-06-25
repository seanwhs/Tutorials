# Part 9 — Automatic Subject Detection (AI Classification Layer)

Up to this point, Markly has become a capable grading assistant.

It can:

* Read PDFs
* Read Microsoft Word documents
* Analyze scanned worksheets
* Grade handwritten assignments
* Generate teacher-style feedback
* Produce professional PDF reports

However, there is still a small workflow problem.

The teacher must tell Markly what subject the assignment belongs to.

For example:

```text
Upload Assignment
        ↓
Select Subject
        ↓
Grade Assignment
```

This works, but it introduces unnecessary friction.

Teachers should not have to classify assignments manually.

A modern AI system should be able to infer context automatically.

---

# The Problem with Manual Subject Selection

Manual classification creates several issues.

### Extra Work

Teachers already know what subject the assignment belongs to.

Being asked to select it again is redundant.

---

### Human Error

The wrong subject may be selected accidentally.

For example:

```text
Math worksheet
        ↓
Selected as English
        ↓
Incorrect grading persona
```

The grading engine may still generate feedback, but it will be using the wrong evaluation framework.

---

### Poor User Experience

Every additional decision increases cognitive load.

A better workflow is:

```text
Upload Assignment
        ↓
Markly identifies subject
        ↓
Grade Assignment
```

The teacher simply uploads the work.

Markly handles the rest.

---

# AI as a Classifier

Most people think LLMs only generate text.

In reality, they are also excellent classifiers.

Before Markly grades an assignment, it first asks:

> "What subject does this work belong to?"

Possible outputs:

```text
Mathematics
English
Science
Programming
```

This classification becomes the foundation for the rest of the grading pipeline.

---

# The New Workflow

Subject detection now becomes a dedicated stage.

```text
Assignment
      ↓
Content Extraction
      ↓
Subject Detection
      ↓
Persona Selection
      ↓
Rubric Selection
      ↓
Grading
      ↓
Report Generation
```

This allows Markly to adapt automatically.

---

# Detecting Subjects from Text

When the uploaded file contains readable text:

* PDF
* DOCX
* OCR output

Markly extracts the content and sends a classification request.

Conceptually:

```python
subject = predict_subject(text)
```

Example:

```text
Solve for x:

2x + 5 = 15
```

Output:

```text
Mathematics
```

---

# Detecting Subjects from Images

Modern assignments are not always text documents.

Teachers often upload:

* Handwritten worksheets
* Photos from mobile phones
* Scanned papers
* Whiteboard exercises

For these submissions, Markly uses a vision-capable model.

Instead of extracting text first, the model analyzes the image directly.

```python
subject = predict_subject_from_image(
    image_base64
)
```

This enables classification from:

```text
Handwriting
Diagrams
Charts
Tables
Mathematical notation
Code screenshots
```

without requiring OCR first.

---

# Why Vision-Based Classification Matters

Consider a handwritten mathematics worksheet.

OCR may produce:

```text
2x+5=15
2x=15+5
x=10
```

The OCR text exists.

But the layout, annotations, and visual structure may contain additional clues.

Vision models can leverage:

* equations
* diagrams
* formatting
* handwritten notation

to improve classification accuracy.

---

# Reusing the Existing AI Engine

One of the strengths of Markly's architecture is that subject detection does not require a separate infrastructure.

The same concurrent orchestration engine is reused.

```text
Subject Detection
        ↓
Multi-Model Engine
        ↓
Fastest Successful Response
```

This means classification benefits from:

* model redundancy
* timeout protection
* automatic failover
* task cancellation

just like grading itself.

---

# Classification Prompt Design

The classifier prompt is intentionally strict.

Instead of allowing free-form responses:

```text
This appears to be a mathematics assignment because...
```

we constrain the model:

```text
Return ONLY one subject:

Mathematics
English
Science
Programming
```

This ensures predictable downstream automation.

---

# Why Subject Detection Happens First

Subject detection drives nearly every intelligent component in Markly.

Once the subject is known:

```text
Subject
    ↓
Teacher Persona
    ↓
Rubric
    ↓
Evaluation Strategy
```

For example:

### Mathematics

```text
Focus on:
- calculations
- reasoning steps
- methodology
```

### English

```text
Focus on:
- grammar
- structure
- argument quality
```

### Programming

```text
Focus on:
- correctness
- maintainability
- code quality
```

### Science

```text
Focus on:
- scientific accuracy
- conceptual understanding
```

Without correct classification, the rest of the pipeline becomes less reliable.

---

# The Updated Architecture

Markly now performs two separate AI tasks.

### Stage 1 — Classification

```text
Assignment
      ↓
Determine Subject
```

### Stage 2 — Grading

```text
Assignment
      ↓
Teacher Persona
      ↓
Rubric
      ↓
Feedback
```

This is an example of a **multi-stage AI workflow**.

Instead of one giant prompt doing everything, intelligence is decomposed into smaller, focused tasks.

---

# Full System Flow

```text
Teacher
    ↓
Upload Assignment
    ↓
PDF / DOCX / Image Processing
    ↓
AI Subject Detection
    ↓
Automatic Persona Selection
    ↓
Automatic Rubric Selection
    ↓
Concurrent Multi-Model Grading
    ↓
Feedback Generation
    ↓
Teacher Annotations
    ↓
PDF Report Generation
    ↓
Downloadable Results
```

---

# What We Have Achieved

Markly is no longer a static grading tool.

It now:

* Understands text documents
* Understands images
* Detects subjects automatically
* Selects grading personas dynamically
* Chooses appropriate rubrics
* Produces context-aware feedback

The teacher no longer needs to tell the system what the assignment is.

Markly infers it automatically.

That shift—from explicit configuration to intelligent inference—is one of the defining characteristics of AI-native applications.

---

# What's Next

At this point, Markly can analyze and grade individual submissions extremely well.

However, every submission is still treated in isolation.

The system has no memory of:

* previous assignments
* recurring mistakes
* learning progress
* improvement trends

In the next chapter, we will introduce **Student Memory and Progress Tracking**, transforming Markly from a grading assistant into a system that can monitor learning development over time—much closer to how real teachers evaluate students across an entire semester.
