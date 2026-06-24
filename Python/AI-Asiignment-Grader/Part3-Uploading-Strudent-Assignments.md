# Part 3 — Uploading and Reading Student Assignments

At this point, our user interface is complete—but still passive.

Teachers can upload assignments and click **Grade Assignment**, but nothing meaningful happens yet.

Uploads are accepted, but never interpreted.

In this chapter, we fix that.

We will turn raw file uploads into **readable text that our AI can understand**.

By the end of this section, Markly will be able to:

* Understand how Panel handles file uploads
* Extract text from PDF documents
* Extract text from Microsoft Word files
* Read images using OCR (Optical Character Recognition)
* Build a unified file-processing pipeline
* Display extracted assignment content inside the app

This is the foundation of every AI grading system: **document understanding before intelligence**.

---

# Understanding File Uploads in Panel

Let’s revisit how the `FileInput` widget works.

When a teacher uploads a file, Panel stores it in memory with three important properties:

| Property    | Meaning            |
| ----------- | ------------------ |
| `value`     | Raw file bytes     |
| `filename`  | Original file name |
| `mime_type` | Detected file type |

For example, uploading:

```
essay.docx
```

gives us:

```python
upload.filename
```

```text
essay.docx
```

and:

```python
upload.value
```

```text
(b'...binary file data...')
```

That byte data is what we must process.

---

# Why Everything Becomes Bytes

This design surprises many beginners.

Panel does **not save files to disk**.

Instead, everything is stored in memory as bytes.

Think of it like this:

```text
User Upload
     ↓
Browser
     ↓
Memory (bytes)
     ↓
Python application
```

This approach is useful because:

* No temporary files needed
* Faster processing
* Easier cloud deployment
* Safer file handling

So instead of working with file paths, we work directly with **binary data streams**.

---

# Designing a Clean File Processing System

Before writing code, let’s structure our responsibilities properly.

We follow a key principle:

> Each module should do one thing well.

| File          | Responsibility                 |
| ------------- | ------------------------------ |
| `app.py`      | UI and user interaction        |
| `utils.py`    | File parsing and extraction    |
| `engine.py`   | AI / LLM communication (later) |
| `personas.py` | Teacher feedback styles        |

This separation keeps Markly scalable as it grows.

---

# Our File Processing Pipeline

Before diving into code, here’s what we are building:

```text
Uploaded File
     ↓
Detect File Type
     ↓
Route to Extractor
     ↓
Convert to Text
     ↓
Return Clean String
```

We will support three input types:

* PDF → text extraction
* DOCX → paragraph extraction
* Images → OCR (text recognition)

---

# Installing Required Tools (Important)

To handle images, we use:

* `pytesseract` (OCR engine wrapper)
* `Pillow` (image processing)

Make sure you have installed:

```bash
pip install pytesseract pillow
```

You also need **Tesseract OCR engine** installed on your system.

Without it, image extraction will not work.

---

# Building the PDF Extractor

Let’s start with PDFs.

We use **PyMuPDF (`fitz`)**, which is fast and reliable.

```python
import fitz

def extract_pdf(file_bytes):
    document = fitz.open(stream=file_bytes, filetype="pdf")

    return "\n".join(
        page.get_text() for page in document
    )
```

### What’s happening here?

* We open the PDF directly from memory (`stream=file_bytes`)
* We loop through every page
* We extract text from each page
* We join everything into one clean string

Result:

```text
Page 1 text
Page 2 text
Page 3 text
```

Becomes:

```text
Full assignment content in one string
```

---

# Building the DOCX Extractor

Now let’s handle Microsoft Word files.

We use `python-docx`.

```python
from docx import Document
import io
```

DOCX files require a file-like object, so we convert bytes using `BytesIO`.

```python
def extract_docx(file_bytes):
    document = Document(io.BytesIO(file_bytes))

    return "\n".join(
        paragraph.text for paragraph in document.paragraphs
    )
```

### Key idea

Word documents are structured as paragraphs, so we simply iterate through them.

---

# Understanding BytesIO (Critical Concept)

This line is important:

```python
io.BytesIO(file_bytes)
```

It creates an **in-memory file wrapper**.

Why is this needed?

Because `python-docx` expects something like:

```
file.docx (on disk)
```

But we only have:

```
raw bytes in memory
```

So `BytesIO` acts like a bridge:

```text
Bytes → File-like object → python-docx
```

---

# Extracting Text from Images (OCR)

Now we reach the most interesting part.

Images do not contain text directly.

So we use **OCR (Optical Character Recognition)**.

We use:

* `Pillow` → loads images
* `pytesseract` → extracts text

```python
import pytesseract
from PIL import Image
import io
```

Now the extractor:

```python
def extract_image(file_bytes):
    image = Image.open(io.BytesIO(file_bytes))
    return pytesseract.image_to_string(image)
```

---

## How OCR Works (Simple Explanation)

```text
Image of handwriting or printed text
              ↓
        Tesseract OCR
              ↓
       Recognized text output
```

So an image like:

```
Math assignment written on paper
```

Becomes:

```text
Student's handwritten answer converted into text
```

This is extremely powerful for real-world grading systems.

---

# Unified File Extraction Function

Now we combine everything into one entry point.

This is the function the rest of Markly will use.

```python
def extract_text_from_file(file_bytes, filename):

    ext = filename.lower().split('.')[-1]

    if ext == "pdf":
        return extract_pdf(file_bytes)

    elif ext == "docx":
        return extract_docx(file_bytes)

    elif ext in ("png", "jpg", "jpeg"):
        return extract_image(file_bytes)

    else:
        raise ValueError(f"Unsupported file type: {filename}")
```

---

# Why This Design Is Powerful

Instead of scattering logic across the app, we now have:

### One function to rule them all:

```python
extract_text_from_file()
```

This gives us:

* Clean abstraction
* Easy testing
* Easy extension (e.g., TXT, HTML later)
* Simple AI integration

---

# Connecting to the UI

Now let’s plug this into `app.py`.

First import the function:

```python
from utils import extract_text_from_file
```

---

# Creating the Preview Function

When a teacher clicks **Grade Assignment**, we:

1. Check if a file exists
2. Extract text
3. Display it in the UI

```python
def preview_assignment(event):

    if upload.value is None:
        feedback.object = """
## Feedback

Please upload an assignment first.
"""
        return

    text = extract_text_from_file(
        upload.value,
        upload.filename
    )

    feedback.object = f"""
## Assignment Preview

{text}
"""
```

---

# Connecting the Button

```python
grade_button.on_click(preview_assignment)
```

Now the UI becomes interactive.

---

# Testing the System

Run the app:

```bash
panel serve app.py --autoreload
```

Then:

1. Upload a PDF
2. Upload a Word document
3. Upload an image
4. Click **Grade Assignment**

You should now see:

* Extracted PDF text
* Paragraphs from DOCX
* OCR results from images

---

# System Workflow (Current State)

```text
Teacher
   ↓
Upload File
   ↓
Panel stores bytes
   ↓
File type detected
   ↓
Extractor selected
   ↓
Text extracted (PDF / DOCX / OCR)
   ↓
Displayed in UI
```

---

# Why This Is a Major Milestone

At first, Markly could only **accept files**.

Now it can:

* Read documents
* Interpret multiple formats
* Extract meaningful content
* Prepare data for AI analysis

This is the critical bridge between:

> “File upload system” → “AI-powered grading system”

---

# What’s Next

In the next chapter, we’ll connect Markly to an LLM using **OpenRouter**.

You will learn how to:

* Send extracted text to a model
* Design grading prompts
* Receive structured feedback
* Render AI responses in the UI

This is where Markly stops being a document reader—and becomes a **real grading assistant**.
