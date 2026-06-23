# Part 3 — Uploading and Reading Student Assignments

Our user interface is now complete, but it doesn't actually *do* anything yet.

If you click **Grade Assignment**, nothing happens. If you upload a PDF, the application accepts it, but never opens or reads it.

In this chapter, we'll change that.

We'll learn how to:

* Understand how Panel uploads files
* Read PDF assignments
* Read Microsoft Word documents
* Prepare image files for AI vision models
* Organize our code into reusable helper functions
* Display the extracted text inside the application

By the end of this chapter, Markly will be able to **understand what was uploaded**, which is the first step toward intelligent grading.

---

# Understanding File Uploads in Panel

Let's begin by understanding how the `FileInput` widget works.

When a teacher uploads a file, Panel stores several pieces of information.

| Property    | Description                    |
| ----------- | ------------------------------ |
| `value`     | The uploaded file as raw bytes |
| `filename`  | Original filename              |
| `mime_type` | File type (PDF, image, etc.)   |

For example, suppose a teacher uploads:

```
math_assignment.pdf
```

Internally, Panel stores something similar to this:

```python
upload.filename
```

returns

```text
math_assignment.pdf
```

while

```python
upload.value
```

contains thousands of bytes representing the actual PDF document.

Those bytes are what we'll use to read the assignment.

---

# Why Everything is Stored as Bytes

This surprises many beginners.

When you upload a file, Panel **does not save it to your hard drive**.

Instead, it stores the uploaded file entirely in memory.

Imagine the upload process like this.

```text
Student Assignment
        │
        ▼
Browser Upload
        │
        ▼
Memory (Bytes)
        │
        ▼
Python Program
```

This has several advantages.

* Faster processing
* No temporary files
* Better security
* Easier deployment to cloud platforms

Instead of opening a filename, we'll work directly with bytes.

---

# Separating Responsibilities

Our `app.py` file should focus only on the user interface.

Reading PDFs has nothing to do with buttons or dropdown menus.

Instead, we'll create helper functions inside **utils.py**.

This follows an important software engineering principle called the **Single Responsibility Principle (SRP)**.

Each module should have one clear responsibility.

| File          | Responsibility   |
| ------------- | ---------------- |
| `app.py`      | User interface   |
| `utils.py`    | File processing  |
| `engine.py`   | AI communication |
| `personas.py` | Teacher prompts  |

Keeping these concerns separate makes the application easier to maintain as it grows.

---

# Creating Our First Helper Function

Open **utils.py**.

Let's begin with a very simple function.

```python
def extract_text_from_file(file_bytes, filename):
    """
    Extract text from an uploaded assignment.

    Parameters
    ----------
    file_bytes : bytes
        The uploaded file.

    filename : str
        Original filename.

    Returns
    -------
    str
        Extracted text.
    """

    return ""
```

This doesn't do anything yet, but it establishes the interface that the rest of our application will use.

Notice that the rest of Markly doesn't need to know *how* the extraction works.

It simply calls:

```python
text = extract_text_from_file(...)
```

This abstraction keeps our code clean.

---

# Reading PDF Documents

The majority of assignments are distributed as PDFs.

Fortunately, the **PyMuPDF** library makes reading PDFs remarkably straightforward.

First, import the library.

```python
import fitz
```

The package is installed as **PyMuPDF**, but imported using the name `fitz`.

This historical naming often confuses beginners, so don't worry if it seems unusual.

Now update the function.

```python
import fitz

def extract_pdf(file_bytes):

    document = fitz.open(
        stream=file_bytes,
        filetype="pdf"
    )

    text = ""

    for page in document:

        text += page.get_text()

    return text
```

Let's understand what's happening.

---

## Opening a PDF from Memory

Normally you might open a PDF like this.

```python
fitz.open("assignment.pdf")
```

But we don't have a filename.

Remember, Panel uploaded the file directly into memory.

Instead, we open the document using:

```python
fitz.open(
    stream=file_bytes,
    filetype="pdf"
)
```

The `stream` parameter tells PyMuPDF that the PDF already exists in memory.

---

## Reading Every Page

A PDF may contain multiple pages.

Rather than assuming there's only one, we loop through all pages.

```python
for page in document:
```

Each page is represented by a `Page` object.

We then ask that page to extract its text.

```python
page.get_text()
```

Finally, we concatenate all pages into one long string.

```
Page 1

+
Page 2

+
Page 3

↓

Complete Assignment Text
```

This combined text is what we'll eventually send to the language model.

---

# Reading Microsoft Word Documents

Many teachers ask students to submit essays in Microsoft Word format.

We'll use the `python-docx` library to read these files.

Import the library.

```python
from docx import Document
import io
```

Unlike PyMuPDF, `Document()` expects a file-like object rather than raw bytes.

That's where `io.BytesIO` becomes useful.

Create another helper.

```python
from docx import Document
import io

def extract_docx(file_bytes):

    document = Document(
        io.BytesIO(file_bytes)
    )

    text = ""

    for paragraph in document.paragraphs:

        text += paragraph.text + "\n"

    return text
```

---

# What is BytesIO?

This line deserves a closer look.

```python
io.BytesIO(file_bytes)
```

Imagine that `python-docx` expects to read from a normal file.

Something like this.

```
essay.docx
```

But our uploaded assignment only exists as bytes.

`BytesIO` creates an in-memory file that behaves just like a normal file.

```text
Raw Bytes
     │
     ▼
 BytesIO Object
     │
     ▼
 python-docx
```

It's one of the most useful tools when working with uploaded files.

---

# What About Images?

Images are different.

Unlike PDFs or DOCX files, we usually don't extract text ourselves.

Instead, we'll send the image directly to a **vision-capable language model**.

For now, our helper function only needs to recognize image files.

```python
def is_image(filename):

    filename = filename.lower()

    return filename.endswith(
        (
            ".png",
            ".jpg",
            ".jpeg"
        )
    )
```

Later, we'll convert these images into Base64 before sending them to the AI.

---

# Combining Everything Together

Now let's update our main helper.

```python
import fitz
import io

from docx import Document


def extract_pdf(file_bytes):

    document = fitz.open(
        stream=file_bytes,
        filetype="pdf"
    )

    text = ""

    for page in document:

        text += page.get_text()

    return text


def extract_docx(file_bytes):

    document = Document(
        io.BytesIO(file_bytes)
    )

    text = ""

    for paragraph in document.paragraphs:

        text += paragraph.text + "\n"

    return text


def extract_text_from_file(file_bytes, filename):

    filename = filename.lower()

    if filename.endswith(".pdf"):

        return extract_pdf(file_bytes)

    elif filename.endswith(".docx"):

        return extract_docx(file_bytes)

    elif filename.endswith(
        (
            ".png",
            ".jpg",
            ".jpeg"
        )
    ):

        return "[IMAGE FILE]"

    else:

        raise ValueError(
            f"Unsupported file type: {filename}"
        )
```

Notice that we have divided the work into several smaller functions.

This makes each function easier to understand, test, and reuse.

---

# Connecting the Helper to the User Interface

Let's return to **app.py**.

Import the helper.

```python
from utils import extract_text_from_file
```

Next, we'll define what happens when the teacher clicks the **Grade Assignment** button.

At the moment, we won't call the AI yet. Instead, we'll simply extract the text and display it.

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

Finally, register the function with the button.

```python
grade_button.on_click(
    preview_assignment
)
```

This creates our first interactive application.

Now, when the teacher clicks **Grade Assignment**, Panel calls `preview_assignment()` automatically.

---

# Trying It Out

Restart the application.

```bash
panel serve app.py --autoreload
```

Upload a PDF or DOCX file.

Click **Grade Assignment**.

Instead of displaying "Waiting for assignment...", the application should now show the extracted text.

Congratulations! 🎉

Markly is officially reading student submissions.

---

# Current Application Workflow

Our application has become much smarter.

```text
Teacher
    │
    ▼
Upload Assignment
    │
    ▼
Read PDF / DOCX
    │
    ▼
Extract Text
    │
    ▼
Display Preview
```

This may not seem like a huge change, but it's a significant milestone. Before an AI can evaluate a student's work, it first needs access to the assignment's content. We've now built a reliable document ingestion pipeline that supports multiple file formats while keeping our code modular and maintainable.

In the next instalment, we'll take the next major step: connecting Markly to an LLM through the OpenRouter API. You'll learn how to securely load your API key, send prompts to the model, receive responses, and display AI-generated feedback inside the application. This is where Markly transforms from a document reader into an intelligent grading assistant.
