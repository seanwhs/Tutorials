# Part 6 — Grading Images with Vision Models

So far, Markly has been able to grade assignments that contain **extractable text**.

This includes:

* PDF worksheets
* Microsoft Word documents
* Typed essays
* Digital reports

These formats are relatively easy to handle because we can extract the text and send it to a language model.

But in real classrooms, not all assignments are digital.

Teachers often receive work that contains **no selectable text at all**.

For example:

* Handwritten mathematics solutions
* Scanned exam papers
* Photos taken from mobile phones
* Whiteboard exercises
* Science diagrams
* Flowcharts and sketches
* Geography maps

In these cases, traditional text extraction tools fail completely.

A PDF parser cannot understand reasoning like this:

```text
2x + 5 = 15  
2x = 15 + 5  
x = 10
```

A human teacher immediately notices the mistake:
the student added 5 instead of subtracting it.

But a text extraction tool only sees pixels—not reasoning.

To solve this, we need a different kind of model.

---

# Introducing Vision Models

Most people think Large Language Models only understand text.

Modern models are actually **multimodal**.

This means they can understand:

* Text
* Images
* Diagrams
* Tables
* Handwritten notes
* Charts and figures

Instead of asking:

> “Read this assignment”

we can now ask:

> “Look at this image and grade the student’s work.”

This brings the model much closer to how a human teacher works.

A teacher does not convert everything into text first—they directly observe the work.

---

# How Vision Models Work

Vision models do not receive image files directly.

Instead, we send:

* instructions (text)
* image data

together in a single request.

Conceptually:

```text
Teacher Instructions + Student Image → AI Model → Feedback
```

The model then interprets both at the same time.

---

# Preparing Images for the Model

Before sending an image to the model, we need to convert it into a format that can be transmitted over the internet.

This is where **Base64 encoding** comes in.

Base64 converts image bytes into a text representation.

For example:

```
Original image → binary data → Base64 string
```

This allows the image to be embedded directly inside an API request.

The workflow looks like this:

```text
Image File
   ↓
Bytes
   ↓
Base64 Encoding
   ↓
API Request
   ↓
Vision Model
```

---

# Creating a Helper Function

Let’s add a helper function in `utils.py` to handle image conversion.

```python
import base64

def image_to_base64(file_bytes):
    """
    Convert image bytes into a Base64 string.
    This allows the image to be sent to the model.
    """
    return base64.b64encode(file_bytes).decode("utf-8")
```

### What this does

* `file_bytes` → raw uploaded image data
* `base64.b64encode()` → converts it to encoded bytes
* `.decode("utf-8")` → converts bytes into a string

The final result is a long string that represents the image.

You don’t need to read or interpret it—it is only used for transport.

---

# Creating the Vision Grading Function

Now we extend Markly to support image-based grading.

In `engine.py`, create a new function:

```python
def grade_image(image_base64, subject):
```

Instead of extracting text, we directly send the image to the model.

---

# Designing the Vision Prompt

Unlike text-based grading, we cannot reference paragraphs or sentences.

Instead, we instruct the model to carefully analyze visual content.

```python
VISION_PROMPT = """
You are an experienced teacher.

Carefully examine the student's assignment.

Identify:
- Correct answers
- Incorrect reasoning
- Missing steps
- Conceptual misunderstandings

Provide feedback in the following format:

## Strengths

## Mistakes

## Suggestions

## Final Grade
"""
```

This ensures the model produces structured, consistent feedback.

---

# Sending Images to the Model

The OpenAI API allows us to send both text and images in the same request.

Here is the structure:

```python
response = client.chat.completions.create(
    model="gpt-4.1-mini",
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": VISION_PROMPT
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{image_base64}"
                    }
                }
            ]
        }
    ]
)
```

---

## Key Idea: Mixed Input Messages

Previously, messages were simple strings:

```python
"Grade this assignment"
```

Now, messages become a **list of inputs**:

```text
Text + Image → Single Request
```

This tells the model:

> “Here are instructions… and here is the assignment image.”

It processes both together.

---

## Why "image_url"?

Even though we are not using a real URL, the API accepts:

* web URLs
* cloud-hosted images
* Base64 data URLs

We use a **data URL format**:

```
data:image/jpeg;base64,...
```

This embeds the image directly inside the request.

---

# Combining Text and Visual Understanding

This step is important.

The model needs both:

* **instructions (what to do)**
* **image (what to analyze)**

Without instructions, the model may describe the image instead of grading it.

So we are effectively combining:

```text
Teacher Instructions + Student Work → Graded Feedback
```

---

# Updating the Application Logic

Now we update `app.py` to support both file types.

We detect the uploaded file type:

```python
filename = upload.filename.lower()
```

Then route it accordingly:

```python
if filename.endswith((".png", ".jpg", ".jpeg")):

    image = image_to_base64(upload.value)

    result = grade_image(
        image,
        subject.value
    )

else:

    assignment = extract_text_from_file(
        upload.value,
        upload.filename
    )

    result = grade_assignment(
        assignment,
        subject.value
    )
```

---

# Two Parallel Pipelines

Markly now supports two complete workflows:

```text
                 Upload Assignment
                         │
        ┌────────────────┴───────────────┐
        │                                │
        ▼                                ▼
   Text-based files                 Image-based files
        │                                │
   Extract text                  Convert to Base64
        │                                │
   Text model                    Vision model
        │                                │
        └──────────────┬─────────────────┘
                       ▼
                Teacher Feedback
```

This design pattern is called **dispatching**.

The system decides how to process input based on its type.

---

# Improving with Teacher Personas

We can now combine vision input with subject-specific teaching styles.

Instead of using a generic prompt, we inject a **teacher persona**.

```python
persona = PERSONAS[subject]

vision_prompt = f"""
{persona}

The student's work is provided as an image.

Carefully examine all visible writing, diagrams, and working steps.

Do not assume missing information.

Base your feedback only on what is visible.
"""
```

This ensures:

* Math teachers focus on reasoning
* Science teachers focus on concepts
* English teachers focus on clarity and structure

---

# Final Architecture

Markly is now a **multimodal AI grading system**.

```text
                    Teacher
                       │
              Upload Assignment
                       │
              File Type Detection
                       │
        ┌──────────────┴──────────────┐
        │                             │
     Text File                    Image File
        │                             │
   Extract Text               Base64 Encoding
        │                             │
     LLM                        Vision Model
        │                             │
        └──────────────┬──────────────┘
                       ▼
               Grading Feedback
```

---

# What We Have Built

At this stage, Markly can:

* Grade essays and typed assignments
* Analyze scanned worksheets
* Understand handwritten math solutions
* Interpret diagrams and visual reasoning
* Apply subject-specific teacher personas

This brings us significantly closer to a real classroom AI assistant.

---

# Next Step

In the next part, we will transform Markly’s output into a **professional PDF grading report**.

Instead of raw text in the browser, we will generate:

* structured reports
* formatted sections
* downloadable feedback documents
* printable teacher reports

This will make Markly suitable for real educational workflows.

---
