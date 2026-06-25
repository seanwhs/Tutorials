# Part 3 — Uploading and Understanding Student Assignments

## Building Markly's Content Extraction Layer

In Part 2, we built the Markly Teacher Dashboard.

Teachers can now:

✓ Upload assignments

✓ Enter student information

✓ Select grading options

✓ Start the grading process

However, there is still a major problem.

The system cannot actually understand the uploaded files.

Imagine a teacher uploads:

```text
essay.docx
```

or

```text
math_homework.pdf
```

or even:

```text
worksheet.jpg
```

At the moment, Markly only sees:

```text
Raw Binary Data
```

Computers do not automatically understand documents.

Before we can grade an assignment, we must first answer a fundamental question:

> How do we transform a file into information that an AI can understand?

This chapter introduces the **Content Extraction Layer**, one of the most important components in the entire Markly architecture.

By the end of this chapter, Markly will be able to:

* Accept uploaded files
* Understand how uploads are represented internally
* Extract text from PDFs
* Extract text from DOCX documents
* Process image-based assignments
* Build a unified extraction pipeline
* Display extracted content inside the application

Most importantly, we will build the foundation that every future AI feature depends upon.

---

# Why Content Extraction Comes Before AI

Many beginners imagine AI systems working like this:

```text
Upload Assignment
        │
        ▼
      AI
        │
        ▼
    Feedback
```

In reality, production systems almost never work this way.

Instead:

```text
Upload Assignment
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
```

The AI cannot grade a document it cannot read.

Content extraction is therefore the first stage of intelligence.

---

# Understanding File Uploads In Panel

Let's revisit the upload widget.

In Part 2 we created:

```python
upload = pn.widgets.FileInput(
    accept=".pdf,.docx,.png,.jpg,.jpeg"
)
```

When a teacher uploads a file, Panel stores several pieces of information.

---

## upload.value

Contains the file contents.

Example:

```python
upload.value
```

Output:

```text
b'...binary data...'
```

These are raw bytes.

---

## upload.filename

Contains the original filename.

Example:

```python
upload.filename
```

Output:

```text
essay.docx
```

---

## upload.mime_type

Contains the detected content type.

Example:

```python
upload.mime_type
```

Output:

```text
application/vnd.openxmlformats-officedocument.wordprocessingml.document
```

---

# Why Files Become Bytes

This surprises many new developers.

When a user uploads a file, Panel does not automatically save it to disk.

Instead:

```text
Teacher Upload
        │
        ▼
 Browser Memory
        │
        ▼
 Python Application
```

The file is represented entirely as bytes.

For example:

```python
upload.value
```

might contain:

```python
b'\x89PNG\r\n\x1a\n...'
```

for an image.

Or:

```python
b'%PDF-1.7...'
```

for a PDF.

---

# Why This Is Actually Useful

Working with bytes gives us several advantages:

### Faster Processing

No temporary files are required.

### Better Security

Files don't need to be written to disk.

### Cloud Friendly

Perfect for:

* Hugging Face Spaces
* Docker Containers
* Cloud Deployments

### Easier Integration

Most modern AI systems already work with:

```text
Bytes
Streams
Buffers
```

rather than local file paths.

---

# Designing The Content Extraction Layer

Before writing code, let's think like software engineers.

We already decided in Part 1 that each module should have a single responsibility.

Our extraction logic belongs in:

```text
utils.py
```

Why?

Because:

```text
app.py
```

should focus on:

* widgets
* layouts
* user interaction

not document processing.

---

# Our Extraction Pipeline

The pipeline we are building looks like this:

```text
Uploaded File
      │
      ▼
Detect File Type
      │
      ▼
Select Extractor
      │
      ▼
Extract Content
      │
      ▼
Return Unified Text
```

The key idea is:

No matter what file type the teacher uploads, the rest of Markly should receive:

```python
str
```

A single clean text string.

---

# Creating utils.py

Open:

```text
utils.py
```

This module will eventually contain:

* PDF extraction
* DOCX extraction
* OCR helpers
* Image processing
* Assignment utilities

For now, we'll focus on extraction.

---

# Reading PDF Assignments

Many educational resources are distributed as PDFs.

Examples:

```text
Worksheets
Homework
Lab Reports
Research Essays
```

To process PDFs, we use:

```python
import fitz
```

This library comes from:

```text
PyMuPDF
```

which we installed earlier.

---

# Building extract_pdf()

Add:

```python
import fitz

def extract_pdf(file_bytes):
    """
    Extract text from a PDF.
    """

    document = fitz.open(
        stream=file_bytes,
        filetype="pdf"
    )

    text = []

    for page in document:
        text.append(page.get_text())

    return "\n".join(text)
```

---

# Understanding The Function

## Open The PDF

```python
fitz.open(
    stream=file_bytes,
    filetype="pdf"
)
```

Notice:

```python
stream=file_bytes
```

We're opening directly from memory.

No temporary files needed.

---

## Loop Through Pages

```python
for page in document:
```

A PDF may contain:

* one page
* ten pages
* one hundred pages

We must process all of them.

---

## Extract Text

```python
page.get_text()
```

returns the text found on the page.

---

## Merge Everything Together

```python
"\n".join(text)
```

converts:

```python
[
  "Page One",
  "Page Two",
  "Page Three"
]
```

into:

```text
Page One

Page Two

Page Three
```

---

# Reading DOCX Assignments

Many teachers prefer Microsoft Word.

Examples:

```text
Essays
Reflection Papers
Research Reports
```

To process DOCX files we use:

```python
python-docx
```

---

# Building extract_docx()

Add:

```python
from docx import Document
import io

def extract_docx(file_bytes):
    """
    Extract text from DOCX files.
    """

    document = Document(
        io.BytesIO(file_bytes)
    )

    paragraphs = []

    for paragraph in document.paragraphs:
        paragraphs.append(paragraph.text)

    return "\n".join(paragraphs)
```

---

# Understanding BytesIO

This is one of the most important concepts for beginners.

We only have:

```python
file_bytes
```

But:

```python
Document(...)
```

expects something that behaves like a file.

`BytesIO` creates an in-memory file.

Think of it as:

```text
Raw Bytes
     │
     ▼
BytesIO Wrapper
     │
     ▼
File-Like Object
```

No actual file is created.

Everything remains in memory.

---

# Images: OCR Versus Vision AI

Historically, systems used OCR:

```text
Image
   │
   ▼
Tesseract OCR
   │
   ▼
Extracted Text
```

OCR works well for:

* printed worksheets
* typed documents

but struggles with:

* messy handwriting
* diagrams
* mathematics notation
* arrows
* drawings

Modern versions of Markly increasingly rely on Vision LLMs instead.

---

# Why Vision Models Are Better

Consider this image:

```text
✓ Correct

2x + 3 = 9

Student writes:

x = 4
```

OCR may only see:

```text
2x+3=9
x=4
```

A Vision LLM can understand:

* the question
* the answer
* the layout
* annotations
* handwritten marks

This becomes important later when we build AI-powered grading.

For now, we'll still implement OCR as a baseline extractor.

---

# Building extract_image()

Add:

```python
import pytesseract
from PIL import Image
import io

def extract_image(file_bytes):
    """
    Extract text from images using OCR.
    """

    image = Image.open(
        io.BytesIO(file_bytes)
    )

    return pytesseract.image_to_string(image)
```

---

# Building A Unified Extraction Function

Instead of forcing the rest of Markly to understand:

* PDFs
* DOCX
* Images

we create one function.

This is a common software engineering pattern called a **Facade**.

A Facade hides complexity behind a simple interface.

---

# Building extract_text_from_file()

Add:

```python
def extract_text_from_file(
    file_bytes,
    filename
):
    """
    Unified extraction entry point.
    """

    extension = (
        filename.lower()
        .split(".")[-1]
    )

    if extension == "pdf":
        return extract_pdf(file_bytes)

    if extension == "docx":
        return extract_docx(file_bytes)

    if extension in (
        "png",
        "jpg",
        "jpeg"
    ):
        return extract_image(file_bytes)

    raise ValueError(
        f"Unsupported file type: {filename}"
    )
```

---

# Why This Function Matters

The rest of Markly can now simply call:

```python
text = extract_text_from_file(
    file_bytes,
    filename
)
```

without caring about file types.

This dramatically simplifies future development.

---

# Connecting The Extraction Layer To The UI

Open:

```text
app.py
```

Import:

```python
from utils import (
    extract_text_from_file
)
```

---

# Creating A Preview Handler

Add:

```python
def preview_assignment(event):

    if upload.value is None:

        feedback.object = """
## Feedback

Please upload an assignment first.
"""
        return

    extracted_text = (
        extract_text_from_file(
            upload.value,
            upload.filename
        )
    )

    feedback.object = f"""
## Assignment Preview

{extracted_text}
"""
```

---

# Connecting The Button

Add:

```python
grade_button.on_click(
    preview_assignment
)
```

Now the interface becomes interactive.

---

# Testing The System

Run:

```bash
panel serve app.py --autoreload
```

Upload:

* a PDF
* a DOCX document
* a PNG image

Then click:

```text
Grade Assignment
```

You should now see the extracted content displayed inside the feedback area.

---

# Where We Are In The Architecture

Our system now looks like:

```text
Teacher
   │
   ▼
Upload Assignment
   │
   ▼
Content Extraction Layer
   │
   ▼
Assignment Preview
```

This may seem simple, but it represents a major milestone.

Markly can now understand documents.

Everything that follows:

* subject detection
* rubric selection
* grading
* annotation generation
* student memory

depends on the extraction layer we built in this chapter.

---

# What We've Accomplished

We now have:

✓ PDF extraction

✓ DOCX extraction

✓ OCR support

✓ Unified extraction interface

✓ Separation of concerns

✓ Working assignment preview pipeline

Most importantly, we've built the first true intelligence-enabling layer of Markly.

The system is no longer just accepting files.

It is beginning to understand them.

---

# Next Part

In **Part 4 — Connecting Markly to AI**, we'll introduce OpenRouter and Vision LLMs.

You'll learn:

* how LLM APIs work
* how Markly communicates with AI models
* how to send assignments for evaluation
* how to receive structured grading feedback
* why prompts are the most important component of AI-powered educational software

For the first time, Markly will move beyond document understanding and begin performing actual educational analysis.
