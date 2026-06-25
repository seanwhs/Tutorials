# Part 6 — Teaching Markly to See: Building a Multimodal Grading System

## Why Text Extraction Eventually Breaks

Until now, Markly has relied on text extraction.

This works well for:

* Essays
* Reports
* Typed assignments
* Digital worksheets

because the text already exists inside the file.

For example:

```text
The mitochondria is the powerhouse of the cell.
```

can be extracted directly.

However, many classroom submissions contain no machine-readable text at all.

Examples:

* Handwritten math homework
* Scanned exam papers
* Mobile phone photos
* Whiteboard solutions
* Mind maps
* Flowcharts
* Science diagrams

To a computer, these files are simply collections of coloured pixels.

```text
██████████████
██████████████
██████████████
```

The computer sees an image.

The teacher sees reasoning.

This difference is the central challenge of multimodal AI.

---

# Understanding Multimodal AI

Traditional language models process:

```text
Text → Text
```

Vision models process:

```text
Text + Images → Text
```

This is called **multimodal processing**.

The model can simultaneously examine:

* Written instructions
* Diagrams
* Tables
* Handwriting
* Equations
* Charts
* Drawings

and combine them into a single understanding.

Instead of asking:

```text
Grade this text.
```

we can now ask:

```text
Look at this worksheet and grade it.
```

This feels much closer to how a human teacher works.

---

# OCR vs Vision Models

Many beginners assume OCR and vision models are the same thing.

They are not.

---

## OCR

OCR means:

> Optical Character Recognition

OCR attempts to convert images into text.

Example:

Image:

```text
2x + 5 = 15
```

OCR Output:

```text
2x + 5 = 15
```

This works reasonably well for printed text.

---

### OCR Problem #1 — Handwriting

A student's writing may look like:

```text
2x + S = 15
```

OCR might read:

```text
2x + 5 = I5
```

Errors accumulate quickly.

---

### OCR Problem #2 — Layout

OCR struggles with:

* Arrows
* Diagrams
* Tables
* Flowcharts
* Mathematical working

A teacher understands relationships.

OCR only extracts characters.

---

## Vision Models

Vision models do not simply read text.

They understand:

* location
* layout
* structure
* visual relationships

A vision model can recognize:

```text
Student crossed out answer
       ↓
New answer written below
```

Something OCR completely loses.

---

# Why Markly Uses Both OCR and Vision

A common mistake is:

```text
Vision models exist
→ remove OCR
```

That would be a bad engineering decision.

OCR is still valuable because:

* It is faster
* It is cheaper
* It works well on clean documents
* It reduces model costs

So Markly follows a layered approach:

```text
Document
   │
   ├─ Text Exists?
   │      │
   │      ├─ Yes → Text Pipeline
   │      │
   │      └─ No → Vision Pipeline
   │
   └─ Image Assignment
          │
          ▼
      Vision Pipeline
```

This design balances:

* Cost
* Speed
* Accuracy

---

# How Images Travel Through APIs

A common beginner question is:

> "How do we send an image inside an API request?"

HTTP requests are text-based.

Images are binary data.

So we convert them into a transport-friendly format called Base64.

---

## Understanding Base64

Normal image:

```text
assignment.jpg
```

contains binary bytes.

Base64 converts those bytes into text:

```text
iVBORw0KGgoAAAANS...
```

This text can safely travel through an API.

Pipeline:

```text
Image
   ↓
Bytes
   ↓
Base64
   ↓
API Request
   ↓
Vision Model
```

---

# Building image_to_base64()

Create in `utils.py`:

```python
import base64

def image_to_base64(file_bytes):
    """
    Converts image bytes into a Base64 string.
    """

    return base64.b64encode(
        file_bytes
    ).decode("utf-8")
```

---

# Understanding Every Function Call

## base64.b64encode()

Input:

```python
b"\xff\xd8..."
```

Output:

```python
b"aVZCT1..."
```

Still bytes.

---

## decode("utf-8")

Converts:

```python
bytes
```

into:

```python
str
```

which can be embedded inside JSON.

---

# Designing the Vision Grading Engine

Text grading currently looks like:

```python
grade_assignment(text, subject)
```

Vision grading requires:

```python
grade_image(image_base64, subject)
```

Notice the difference.

Instead of sending extracted text:

```python
essay_text
```

we send:

```python
image_base64
```

---

# Why Vision Prompts Matter Even More

Without instructions:

```text
Describe this image.
```

The model may say:

```text
The image appears to contain handwriting.
```

That is useless for grading.

We must explicitly define the teacher's job.

---

# Building a Vision Prompt

```python
VISION_PROMPT = """
You are an experienced teacher.

Carefully examine the student's work.

Identify:

- correct answers
- incorrect answers
- reasoning mistakes
- missing working steps
- conceptual misunderstandings

Provide constructive educational feedback.

Use the following structure:

## Strengths

## Mistakes

## Suggestions

## Final Grade
"""
```

Notice that we are defining:

* Role
* Evaluation criteria
* Output format

This is prompt engineering.

---

# Injecting Teacher Personas Into Vision Grading

The generic prompt is useful.

But Markly already has personas.

Instead of:

```python
VISION_PROMPT
```

we combine:

```python
PERSONAS[subject]
```

with:

```python
Image-specific instructions
```

Example:

```python
persona = PERSONAS[subject]

prompt = f"""
{persona}

The student's work is provided as an image.

Carefully analyze all visible content.

Do not assume information that cannot be seen.

Base feedback only on visible evidence.
"""
```

Now:

* Math teachers inspect calculations
* English teachers inspect writing quality
* Programming teachers inspect code screenshots
* Science teachers inspect diagrams

---

# Understanding Multimodal Messages

Text-only requests look like:

```python
{
  "role": "user",
  "content": "Grade this assignment"
}
```

Vision requests look like:

```python
{
  "role": "user",
  "content": [
      {...text...},
      {...image...}
  ]
}
```

The message now contains multiple content types.

This is the origin of the word:

```text
Multimodal
```

Multiple modes of information.

---

# What Markly Is Becoming

At the start of this tutorial, Markly was:

```text
Upload File
      ↓
Extract Text
      ↓
Send To AI
```

After this chapter:

```text
Upload Assignment
        │
        ▼
 File Type Detection
        │
 ┌──────┴───────┐
 │              │
 ▼              ▼
Text         Image
 │              │
 ▼              ▼
LLM        Vision Model
 │              │
 └──────┬───────┘
        ▼
 Teacher Feedback
```

This is a major architectural milestone.

Markly is no longer just a document reader.

It is now a multimodal educational AI system capable of understanding both language and visual reasoning.

---

## What We've Built

By the end of this chapter, Markly can:

* Grade PDFs
* Grade DOCX assignments
* Grade handwritten worksheets
* Analyze diagrams
* Evaluate photographed assignments
* Apply teacher personas to visual submissions
* Support multimodal AI workflows

Most importantly, we have laid the foundation for a future feature:

> Teacher-style red-pen annotations directly on student work.

Because before Markly can write feedback onto a page, it must first learn how to see the page.
