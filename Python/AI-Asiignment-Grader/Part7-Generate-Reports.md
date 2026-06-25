# Part 7 — Generating Professional PDF Grading Reports

At this stage, Markly has become a genuinely useful grading assistant.

Teachers can:

* Upload PDF assignments
* Upload Microsoft Word documents
* Upload scanned worksheets
* Upload handwritten assignments
* Select a subject
* Receive AI-generated grading feedback
* Grade both text and image-based submissions

However, there is still a major gap between a useful AI tool and a production-ready educational system.

The feedback currently exists only inside the browser.

Once the teacher closes the application:

* The feedback is lost
* There is no permanent record
* Results cannot easily be shared
* Students cannot receive a formal report
* Schools cannot archive assessment outcomes

Real educational workflows require durable grading artifacts.

Teachers need to:

* Download reports
* Email feedback to students
* Upload results to LMS platforms
* Store assessment records
* Maintain grading histories

To solve this, Markly needs a reporting layer.

In this chapter, we will build a professional PDF reporting system that transforms AI-generated feedback into structured grading reports suitable for real classroom use.

---

# Learning Objectives

By the end of this chapter, you will be able to:

* Understand why reporting is a separate architectural concern
* Generate PDF documents entirely in Python
* Build reusable report-generation utilities
* Use ReportLab's Platypus framework
* Create structured grading reports
* Generate reports directly in memory
* Integrate report downloads into Panel
* Prepare Markly for institutional and classroom workflows

---

# Why Reporting Matters

Many AI applications stop after generating text.

```text
Input
  ↓
AI
  ↓
Output
```

While this works for demonstrations, real systems require a final delivery layer.

Educational workflows look more like:

```text
Student Assignment
         ↓
    AI Evaluation
         ↓
 Structured Feedback
         ↓
   Formal Report
         ↓
 Download / Archive / Share
```

Without reporting:

* grading cannot be standardized
* records cannot be preserved
* audits become difficult
* teachers must manually copy content

The reporting layer converts temporary AI output into a durable educational artifact.

---

# Why PDF Is the Ideal Format

PDF stands for Portable Document Format.

It was specifically designed to ensure documents appear consistently regardless of:

* Operating system
* Browser
* Device
* Installed fonts
* Printer configuration

This makes PDFs ideal for assessment records.

Benefits include:

| Feature           | Benefit                          |
| ----------------- | -------------------------------- |
| Consistent layout | Same appearance everywhere       |
| Print-ready       | No formatting adjustments needed |
| Portable          | Easy to email and distribute     |
| Archivable        | Suitable for long-term storage   |
| Professional      | Familiar educational format      |

A grading report should look identical whether opened on:

* Windows
* macOS
* Linux
* iPad
* Android
* School LMS systems

PDF solves this problem elegantly.

---

# Introducing ReportLab

To generate PDFs from Python, we'll use ReportLab.

Install it if you haven't already:

```bash
pip install reportlab
```

ReportLab is one of the most mature PDF-generation libraries available.

It allows us to create:

* Reports
* Certificates
* Invoices
* Assessments
* Student feedback documents

without requiring external software.

---

# Creating a Dedicated Reporting Module

As Markly grows, keeping responsibilities separated becomes increasingly important.

Create a new file:

```text
report.py
```

Updated structure:

```text
markly/

├── app.py
├── engine.py
├── personas.py
├── utils.py
├── report.py
├── rubrics.py
├── requirements.txt
└── assets/
```

---

## Teacher's Note

Avoid placing PDF-generation code inside `app.py`.

Beginners often do this because it seems convenient.

```python
# app.py

# grading logic
# PDF logic
# UI logic
# file handling
# report formatting
```

This quickly becomes difficult to maintain.

Instead:

```text
app.py      → user interface
engine.py   → AI orchestration
utils.py    → document processing
report.py   → report generation
```

This separation makes future enhancements significantly easier.

---

# Understanding In-Memory PDF Generation

Many developers assume PDFs must be written to disk first.

For example:

```python
pdf.save("report.pdf")
```

While this works, it introduces unnecessary filesystem dependencies.

A better approach is:

```text
Generate PDF
      ↓
Store in memory
      ↓
Send to browser
      ↓
Download
```

This is especially important when deploying to:

* Hugging Face Spaces
* Cloud Run
* Docker containers
* Serverless platforms

---

# Using BytesIO

Python provides an in-memory file object called `BytesIO`.

```python
import io

buffer = io.BytesIO()
```

Think of it as:

```text
Virtual File
Stored in RAM
```

Instead of writing:

```text
report.pdf
```

to disk, ReportLab writes directly into memory.

---

# Building Our First PDF

Create a simple test in `report.py`:

```python
import io

from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph
)

from reportlab.lib.styles import getSampleStyleSheet


def create_demo_pdf():

    buffer = io.BytesIO()

    document = SimpleDocTemplate(buffer)

    styles = getSampleStyleSheet()

    content = [
        Paragraph(
            "Hello from Markly!",
            styles["Title"]
        )
    ]

    document.build(content)

    buffer.seek(0)

    return buffer
```

---

# Understanding Platypus

ReportLab contains two approaches:

## Canvas

Low-level drawing system.

```python
drawString(x, y)
```

You manually position everything.

---

## Platypus

High-level document framework.

You define content:

```python
Paragraph(...)
Spacer(...)
Table(...)
```

and ReportLab handles layout automatically.

For reports, Platypus is almost always the better choice.

---

## Teacher's Note

Canvas is useful for:

* Forms
* Labels
* Certificates
* Precise layouts

Platypus is better for:

* Reports
* Essays
* Assessments
* AI-generated content

Since grading feedback can vary dramatically in length, Platypus prevents many formatting headaches.

---

# Creating the Report Generator

Now build the real report function.

```python
import io

from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer
)

from reportlab.lib.styles import getSampleStyleSheet
```

---

```python
def create_pdf_report(
    student,
    subject,
    filename,
    feedback
):

    buffer = io.BytesIO()

    document = SimpleDocTemplate(buffer)

    styles = getSampleStyleSheet()

    story = []

    story.append(
        Paragraph(
            "Markly Grading Report",
            styles["Title"]
        )
    )

    story.append(Spacer(1, 12))

    story.append(
        Paragraph(
            f"<b>Student:</b> {student}",
            styles["BodyText"]
        )
    )

    story.append(
        Paragraph(
            f"<b>Subject:</b> {subject}",
            styles["BodyText"]
        )
    )

    story.append(
        Paragraph(
            f"<b>Assignment:</b> {filename}",
            styles["BodyText"]
        )
    )

    story.append(Spacer(1, 20))

    story.append(
        Paragraph(
            feedback.replace("\n", "<br/>"),
            styles["BodyText"]
        )
    )

    document.build(story)

    buffer.seek(0)

    return buffer
```

---

# Understanding the Story Object

One of the most important Platypus concepts is the **story**.

Think of it as a list of document elements.

```python
story = []
```

We gradually add components:

```python
story.append(...)
```

Example:

```python
story = [
    Title,
    Metadata,
    Spacer,
    Feedback
]
```

ReportLab then assembles everything into a complete document.

---

## Teacher's Note

This is similar to building a Panel layout.

Panel:

```python
pn.Column(
    widget1,
    widget2,
    widget3
)
```

ReportLab:

```python
story = [
    element1,
    element2,
    element3
]
```

Both are component-based approaches.

---

# Formatting AI Feedback

AI-generated feedback typically contains:

```text
## Strengths

Good reasoning.

## Weaknesses

Calculation errors.
```

PDFs do not automatically understand newline characters.

Therefore:

```python
feedback.replace(
    "\n",
    "<br/>"
)
```

converts line breaks into HTML-compatible formatting that ReportLab can render.

Without this step, feedback may appear as a single block of text.

---

# Adding a Download Button

Now integrate PDF generation into the UI.

Create a download widget:

```python
download = pn.widgets.FileDownload(
    label="Download Report",
    button_type="success",
    filename="grading_report.pdf"
)
```

---

# Updating the Grading Pipeline

After grading completes:

```python
from report import create_pdf_report
```

Generate the report:

```python
pdf_buffer = create_pdf_report(
    student="Unknown",
    subject=subject.value,
    filename=upload.filename,
    feedback=result
)
```

Attach it:

```python
download.file = pdf_buffer
```

---

# Updating the Interface

Add the widget to the layout:

```python
app = pn.Column(
    title,
    description,
    upload,
    subject,
    grade_button,
    feedback,
    download,
    width=700
)
```

Workflow becomes:

```text
Upload Assignment
        ↓
Grade Assignment
        ↓
View Feedback
        ↓
Download Report
```

---

# Enhancing the Report

A basic report works, but schools often require more structure.

Typical additions include:

* School name
* Organization logo
* Teacher name
* Class information
* Date generated
* Rubric results
* Final score
* Footer information

Example:

```text
Pinnacle@Duxton Builder School

MARKLY GRADING REPORT

Student: John Tan
Class: Secondary 2A
Subject: Mathematics

--------------------------------

Strengths
...

Areas for Improvement
...

Final Grade
8 / 10

Generated:
25 June 2026

Powered by Markly AI
```

---

## Teacher's Note

Keep presentation logic inside `report.py`.

Do not modify:

```python
engine.py
```

to change formatting.

The AI should generate educational feedback.

The reporting layer should decide how that feedback is displayed.

This separation prevents tight coupling between AI and presentation.

---

# Updated Architecture

Markly now contains a complete end-to-end workflow.

```text
Teacher
   │
   ▼
Upload Assignment
   │
   ▼
File Processing
   │
   ▼
Teacher Persona
   │
   ▼
AI Grading Engine
   │
   ▼
Feedback
   │
   ├─────────────► Browser Display
   │
   ▼
PDF Generator
   │
   ▼
Downloadable Report
```

---

# What We've Accomplished

Markly can now:

* Process assignments
* Grade using AI
* Apply subject-specific teacher personas
* Understand images and text
* Generate structured feedback
* Produce professional PDF reports
* Allow report downloads directly from the browser

This is a major transition.

Markly is no longer simply an AI-powered grading interface.

It is becoming a complete educational workflow platform.

---

# What's Next?

The next chapter focuses on improving the user experience and responsiveness of the application.

We will introduce:

* Loading indicators
* Non-blocking asynchronous grading
* Error handling
* Status updates
* Better user feedback during long-running AI operations

These improvements will make Markly feel like a polished production application rather than a prototype.
