# Part 6 — Grading Images with Vision Models

So far, Markly has been able to grade assignments that contain **extractable text**.

For example:

* PDF worksheets
* Microsoft Word documents
* Typed reports
* Essays

These are relatively straightforward because we can extract the text before sending it to the language model.

However, many classroom assignments don't contain selectable text at all.

Teachers frequently receive:

* Handwritten mathematics worksheets
* Scanned examination papers
* Photos taken using a mobile phone
* Whiteboard exercises
* Science diagrams
* Geography maps
* Flowcharts
* Programming code written on paper

Traditional text extraction libraries cannot understand these documents.

Consider this assignment.

```
+------------------------------+
| Solve:                       |
|                              |
| 2x + 5 = 15                  |
|                              |
| Student's Working:           |
|                              |
| 2x = 15 + 5                  |
| 2x = 20                      |
| x = 10                       |
+------------------------------+
```

A human teacher immediately notices the mistake:

The student should have **subtracted** 5, not added it.

Unfortunately, a PDF text extractor cannot identify this reasoning if the work is handwritten.

This is where **vision-capable language models** become incredibly powerful.

Instead of extracting text ourselves, we'll allow the AI to "look" at the image directly.

---

# What is a Vision Model?

Most people think of Large Language Models as systems that only understand text.

Modern models are actually **multimodal**.

That means they can process multiple kinds of information.

For example:

* Text
* Images
* Charts
* Diagrams
* Tables
* Handwritten notes

Instead of asking:

```
Read this paragraph.
```

we can ask:

```
Look at this image and grade the student's work.
```

The model combines visual understanding with language understanding.

Think of it like giving the assignment directly to a teacher.

```text
Teacher
   │
Looks at worksheet
   │
Reads handwriting
   │
Understands diagrams
   │
Provides feedback
```

Vision models work in a remarkably similar way.

---

# How Do Vision Models Receive Images?

Unlike PDFs, we don't upload image files directly from Python.

Instead, the image must become part of the request.

The API expects something like this:

```
User Message

├── Text
└── Image
```

Both pieces are sent together.

The model then considers both when generating its response.

Fortunately, the OpenAI SDK makes this process straightforward.

---

# Understanding Base64

Before an image can travel across the internet, it must be converted into text.

This may sound impossible.

How can an image become text?

The answer is **Base64 encoding**.

Imagine you have a JPEG image.

```
assignment.jpg
```

Internally, it's just a sequence of bytes.

```
1010101000110101...
```

Base64 converts those bytes into characters.

```
/9j/4AAQSkZJRgABAQ...
```

Although this looks like random text, it completely represents the original image.

Later, the AI converts the Base64 data back into the original picture.

The workflow looks like this.

```text
Image
   │
   ▼
Raw Bytes
   │
   ▼
Base64 Encoding
   │
   ▼
JSON Request
   │
   ▼
Vision Model
```

---

# Creating an Image Helper

Open **utils.py**.

Let's create a reusable helper that converts uploaded images into Base64.

First, import the library.

```python
import base64
```

Now add a new function.

```python
import base64


def image_to_base64(file_bytes):
    """
    Convert uploaded image bytes into
    a Base64 string.
    """

    return base64.b64encode(
        file_bytes
    ).decode("utf-8")
```

Let's examine what happens.

The uploaded image already exists as bytes.

```python
file_bytes
```

We encode those bytes.

```python
base64.b64encode(file_bytes)
```

The result is still bytes.

To turn it into a normal Python string, we call

```python
.decode("utf-8")
```

The final result looks something like

```
/9j/4AAQSkZJRgABAQAAAQABAAD...
```

You never need to read or understand this string.

Its only purpose is to transport the image.

---

# Creating a Vision Grading Function

Our existing grading function assumes the assignment is plain text.

Images require a different API request.

Open **engine.py**.

Let's create another function.

```python
def grade_image(
    image_base64,
    subject
):
```

Notice that instead of receiving text,

it receives the encoded image.

---

# Building the Vision Prompt

Unlike text assignments, we cannot reference specific paragraphs or sentences directly.

Instead, we'll ask the AI to examine the image carefully.

Let's create a prompt.

```python
VISION_PROMPT = """
You are an experienced teacher.

Carefully examine this student assignment.

Look for:

• Correct answers
• Incorrect answers
• Missing working
• Conceptual misunderstandings
• Evidence of student reasoning

Provide:

## Strengths

## Mistakes

## Suggestions

## Final Grade
"""
```

Notice that the wording is intentionally different.

Instead of

> Read the assignment

we say

> Examine this student assignment.

This encourages the model to analyze visual information.

---

# Sending Images to the Model

The request format is slightly different from ordinary text.

```python
response = client.chat.completions.create(

    model="...",

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

At first glance, this looks much more complicated than our earlier requests.

Let's break it down.

---

## The Content List

Previously,

our message looked like this.

```python
{
    "role":"user",
    "content":"Grade this assignment."
}
```

Now,

`content`

is no longer a string.

Instead,

it's a **list**.

```python
content = [

    text,

    image

]
```

This tells the model:

> Here is some text...

followed by

> ...and here is an image.

The AI considers both together.

---

## The Image URL

You might wonder why we're using something called

```
image_url
```

when we don't actually have a URL.

The OpenAI API uses the same field whether the image comes from:

* a website
* cloud storage
* Base64 data

In our case,

the "URL" is actually a **data URL**.

```
data:image/jpeg;base64,...
```

Everything after the comma is the Base64 image.

---

# Combining Text and Images

Notice that our prompt still contains text.

This is important.

Without instructions,

the AI wouldn't know what we expect.

We're effectively saying

```
Teacher Instructions

+

Student Assignment Image

↓

Teacher Feedback
```

The prompt provides context,

while the image provides evidence.

---

# Updating the User Interface

Our application now needs to decide

whether the uploaded assignment is

* text-based

or

* image-based.

Return to **app.py**.

Instead of always calling

```python
grade_assignment()
```

we'll inspect the filename.

```python
filename = upload.filename.lower()
```

If the file is an image,

we'll call the vision model.

```python
if filename.endswith(
    (
        ".png",
        ".jpg",
        ".jpeg"
    )
):

    image = image_to_base64(
        upload.value
    )

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

This simple conditional creates two completely different grading pipelines.

---

# The Two Pipelines

Markly now supports both text and images.

```text
                 Upload Assignment
                         │
        ┌────────────────┴───────────────┐
        │                                │
        ▼                                ▼
   PDF / DOCX                        Image
        │                                │
        ▼                                ▼
 Extract Text                  Convert to Base64
        │                                │
        ▼                                ▼
 Text Grading                  Vision Grading
        │                                │
        └──────────────┬─────────────────┘
                       ▼
             Teacher Feedback
```

This branching workflow is an example of a design pattern known as **dispatching**. The application examines the uploaded file and dispatches it to the most appropriate processing pipeline.

---

# Improving the Vision Prompt with Subject Personas

Earlier, we introduced subject-specific personas for text assignments. We don't want to lose that capability when grading images.

Instead of using a single generic vision prompt, we can combine the teacher persona with image-specific instructions.

```python
persona = PERSONAS[subject]

vision_prompt = f"""
{persona}

The student's work is provided as an image rather than text.

Carefully inspect every visible answer, calculation,
diagram, annotation, and handwritten note.

Do not assume missing information.

Base your feedback only on what is visible.
"""
```

This approach gives the model two kinds of guidance:

1. **How to think** (the teacher persona).
2. **How to interpret the input** (the image instructions).

The result is more accurate and more consistent feedback across different subjects.

---

# Current Architecture

Markly has now evolved into a genuinely **multimodal AI application**.

```text
                    Teacher
                       │
                       ▼
              Upload Assignment
                       │
             Detect File Type
                       │
         ┌─────────────┴─────────────┐
         ▼                           ▼
    PDF / DOCX                    Image
         │                           │
         ▼                           ▼
   Extract Text            Convert to Base64
         │                           │
         ▼                           ▼
   Teacher Persona          Teacher Persona
         │                           │
         ▼                           ▼
      Text Model              Vision Model
         │                           │
         └─────────────┬─────────────┘
                       ▼
              Teacher Feedback
```

At this stage, Markly can successfully grade typed documents, scanned worksheets, and handwritten assignments using subject-aware prompts. It already resembles a practical classroom tool.

However, the feedback still appears as plain Markdown inside the browser. Teachers often need something they can download, print, archive, or share with students and parents.

In the next instalment, we'll build a **professional PDF report generator** using ReportLab. We'll transform the AI's feedback into a polished grading report complete with headings, metadata, and formatting, making Markly's output suitable for real classroom workflows.
