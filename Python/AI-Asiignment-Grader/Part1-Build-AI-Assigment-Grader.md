# Part 1 — Setting Up Markly

## Building an AI-Powered Context-Aware Grading Assistant

---

# Introduction

Before we start writing code, we need to understand what we're building.

Many beginners make the mistake of jumping straight into programming.

Professional software engineers do the opposite.

They first understand:

* What problem the system solves
* What components are needed
* How those components communicate
* Where each responsibility belongs

Markly may look like a simple grading application from the outside, but internally it consists of several independent systems working together.

By the end of this tutorial, you'll build a complete AI-powered grading platform capable of:

* Reading assignments
* Understanding documents
* Detecting subjects automatically
* Applying grading rubrics
* Generating teacher-style feedback
* Producing annotated assignments
* Tracking student progress
* Generating PDF reports

---

# What Happens When A Teacher Uploads An Assignment?

Imagine a teacher uploads:

```text
math_homework.pdf
```

and clicks:

```text
Grade Assignment
```

Many things happen behind the scenes.

---

## Step 1 — Upload

The file enters the system.

```text
Teacher
   │
   ▼
Upload Assignment
```

---

## Step 2 — Content Extraction

Markly must determine:

```text
What kind of file is this?
```

Possible formats:

* PDF
* DOCX
* JPG
* PNG

Each format requires a different extraction strategy.

```text
PDF  → PyMuPDF
DOCX → python-docx
Image → OCR / Vision AI
```

---

## Step 3 — Subject Detection

Once text has been extracted:

```text
Solve the equation 2x + 5 = 11
```

Markly asks:

```text
What subject is this?
```

The AI classifies the content.

Possible results:

* Mathematics
* English
* Science
* Programming

---

## Step 4 — Rubric Selection

Every subject uses different grading criteria.

Mathematics rubric:

```text
Calculation Accuracy
Method
Final Answer
```

English rubric:

```text
Grammar
Structure
Argument Quality
```

Programming rubric:

```text
Correctness
Code Quality
Testing
```

Markly automatically selects the appropriate rubric.

---

## Step 5 — Teacher Persona

This is one of the most important ideas in the entire system.

A mathematics teacher thinks differently from an English teacher.

Therefore we create:

```text
Teacher Personas
```

Examples:

### Mathematics Teacher

Focuses on:

* calculations
* formulas
* working steps

---

### English Teacher

Focuses on:

* grammar
* sentence structure
* argument quality

---

### Programming Instructor

Focuses on:

* correctness
* readability
* maintainability

---

The AI adopts the correct persona before grading.

---

## Step 6 — AI Evaluation

The assignment is sent to the AI.

The AI receives:

```text
Student Submission
+
Subject
+
Rubric
+
Teacher Persona
```

The model then generates:

* score
* feedback
* corrections
* recommendations

---

## Step 7 — Visual Marking

For image-based assignments, Markly goes beyond plain text feedback.

It creates teacher-style annotations.

Examples:

```text
✓ Correct
✗ Incorrect
Excellent work!
Show working.
Check calculation.
```

These annotations are drawn directly onto the assignment image.

---

## Step 8 — Student Memory

Real teachers remember students.

Markly does too.

Before grading, the system can retrieve:

```text
Previous Assignments
Previous Grades
Recurring Mistakes
```

This allows feedback such as:

> "You have improved significantly in algebra since your previous submission."

---

## Step 9 — Report Generation

Finally, the system generates:

### Marked Assignment

```text
Annotated Worksheet
```

and

### Teacher Report

```text
Grade
Strengths
Weaknesses
Recommendations
```

Both are exported into PDF format.

---

# The Complete Markly Architecture

At a high level, Markly looks like this:

```text
                    Assignment
                         │
                         ▼
                  File Upload
                         │
                         ▼
                Content Extraction
                         │
                         ▼
                Subject Detection
                         │
                         ▼
                 Rubric Selection
                         │
                         ▼
                 Teacher Persona
                         │
                         ▼
                  AI Evaluation
                         │
                         ▼
                Annotation Engine
                         │
                         ▼
                 Student Memory
                         │
                         ▼
                 Report Builder
                         │
                         ▼
                     Teacher
```

---

# Understanding The Project Structure

Now that we understand the architecture, let's create the project.

Our final project structure will look like this:

```text
markly/

├── app.py
├── engine.py
├── utils.py
├── personas.py
├── rubrics.py
├── markup.py
├── report.py
├── storage.py
├── install_fonts.py
│
├── students.json
├── .env
├── requirements.txt
│
├── fonts/
│   ├── Caveat-Regular.ttf
│   └── PatrickHand-Regular.ttf
│
└── assets/
```

---

# What Does Each File Do?

Beginners often ask:

> Why do we need so many files?

Because each file should have a single responsibility.

---

## app.py

The user interface.

Responsible for:

* buttons
* forms
* uploads
* displaying results

Think of this as:

```text
The Front Desk
```

---

## engine.py

The AI brain.

Responsible for:

* OpenRouter calls
* subject detection
* grading requests
* feedback generation

Think of this as:

```text
The Teacher
```

---

## utils.py

Handles document processing.

Responsible for:

* PDF extraction
* DOCX extraction
* OCR
* image conversion

Think of this as:

```text
The Reader
```

---

## personas.py

Stores teacher personalities.

Examples:

```text
Math Teacher
English Teacher
Science Teacher
Programming Instructor
```

Think of this as:

```text
Teaching Styles
```

---

## rubrics.py

Stores grading criteria.

Examples:

```text
Accuracy
Grammar
Code Quality
```

Think of this as:

```text
Marking Guidelines
```

---

## markup.py

Creates handwritten-style annotations.

Responsible for:

```text
Ticks
Crosses
Comments
Scores
Highlights
```

Think of this as:

```text
The Red Pen
```

---

## report.py

Generates PDF reports.

Responsible for:

```text
Marked Assignment PDFs
Teacher Reports
```

Think of this as:

```text
The Report Writer
```

---

## storage.py

Stores student history.

Responsible for:

```text
Previous Grades
Previous Feedback
Progress Tracking
```

Think of this as:

```text
The Filing Cabinet
```

---

# Creating The Project Folder

Now create:

```bash
mkdir markly
cd markly
```

---

# Creating A Virtual Environment

Windows:

```bash
python -m venv venv
```

Mac/Linux:

```bash
python3 -m venv venv
```

Activate it:

### Windows

```bash
venv\Scripts\activate
```

### macOS/Linux

```bash
source venv/bin/activate
```

You should now see:

```text
(venv)
```

in your terminal.

---

# Installing Dependencies

Install the core libraries:

```bash
pip install panel
pip install openai
pip install python-dotenv
pip install pymupdf
pip install python-docx
pip install pillow
pip install pytesseract
pip install reportlab
```

---

# Creating The Initial Files

Create:

```text
markly/

├── app.py
├── engine.py
├── utils.py
├── personas.py
├── rubrics.py
├── markup.py
├── report.py
├── storage.py
├── .env
└── requirements.txt
```

Don't worry if these files are empty for now.

Throughout the tutorial we will implement them one at a time.

---

# What We've Accomplished

Even though we haven't written any application logic yet, we've already done something important:

We designed the architecture before writing code.

You now understand:

* what Markly does
* how grading flows through the system
* why each module exists
* where future code will live

This architectural understanding will make the rest of the tutorial significantly easier because every new feature will fit into a structure you already understand.

---

# Next Part

In **Part 2 — Building The User Interface**, we'll create the first working version of Markly using Panel and build the teacher dashboard where assignments can be uploaded, subjects selected, and grading initiated.
