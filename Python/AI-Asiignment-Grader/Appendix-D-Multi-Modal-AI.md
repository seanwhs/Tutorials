# Appendix D — Multimodal AI Fundamentals (How Vision Models Understand Student Assignments)

One of the most significant upgrades in Markly was the transition from:

```text
Text-Based Grading
```

to

```text
Multimodal Grading
```

This single change transformed the system from something that could grade essays and digital worksheets into something that could evaluate:

* handwritten mathematics solutions
* scanned examination papers
* photographs of assignments
* science diagrams
* flowcharts
* whiteboard exercises
* annotated worksheets

In practical educational environments, this capability is essential.

Many student submissions never exist as clean digital text.

This appendix explains how multimodal AI works, why it differs from traditional OCR systems, and how Markly leverages vision models for educational assessment.

---

# The Traditional Approach: OCR

Before modern vision models existed, document understanding usually relied on:

> OCR (Optical Character Recognition)

OCR attempts to convert images into text.

---

Example:

Student submits:

```text
2x + 5 = 15
2x = 15 + 5
x = 10
```

OCR extracts:

```text
2x + 5 = 15
2x = 15 + 5
x = 10
```

---

The extraction itself is correct.

However:

OCR has no understanding.

It only converts pixels into characters.

---

OCR cannot answer:

```text
Is this mathematically correct?
```

Nor can it answer:

```text
Which step contains the mistake?
```

It simply copies symbols.

---

# OCR vs Understanding

Consider this worksheet:

```text
2x + 5 = 15
2x = 20
x = 10
```

OCR output:

```text
2x + 5 = 15
2x = 20
x = 10
```

Perfect extraction.

---

But a teacher immediately notices:

```text
2x = 15 - 5

not

2x = 20
```

---

The issue isn't recognition.

The issue is reasoning.

---

# Enter Vision Models

Modern multimodal models work differently.

They do not simply convert images into text.

Instead they learn relationships between:

* pixels
* words
* objects
* diagrams
* visual structures

---

Conceptually:

```text
Image
  │
  ▼
Visual Understanding
  │
  ▼
Reasoning
  │
  ▼
Response
```

---

This means the model can answer questions such as:

```text
Which step contains an algebra mistake?
```

or

```text
Which diagram label is incorrect?
```

without requiring explicit OCR first.

---

# What Does "Multimodal" Mean?

A modality is a type of information.

Examples:

| Modality | Example           |
| -------- | ----------------- |
| Text     | Essay             |
| Image    | Photograph        |
| Audio    | Speech            |
| Video    | Lecture recording |

---

Traditional LLM:

```text
Text Only
```

---

Multimodal LLM:

```text
Text
+
Images
+
Visual Layout
+
Tables
+
Diagrams
```

---

This allows a single model to process different forms of information simultaneously.

---

# How Markly Uses Vision Models

When grading images, Markly sends:

```text
Teacher Instructions
+
Student Assignment Image
```

together.

---

Conceptually:

```text
Teacher Persona
       +
Student Work
       │
       ▼
Vision Model
       │
       ▼
Feedback
```

---

The model receives both pieces of information in the same request.

This is extremely important.

---

Without instructions:

```text
Describe this image.
```

the model may simply summarize.

---

With instructions:

```text
Act as a mathematics teacher.

Evaluate the student's reasoning.
```

the model performs assessment instead.

---

# The Role of Teacher Personas

Vision models do not automatically know what to look for.

The persona guides attention.

---

Mathematics persona:

```text
Focus on:
- calculations
- working steps
- reasoning
```

---

Science persona:

```text
Focus on:
- scientific accuracy
- terminology
- explanations
```

---

Programming persona:

```text
Focus on:
- code correctness
- design
- readability
```

---

Same image.

Different interpretation lens.

---

# Image Encoding: Why Base64 Exists

Images cannot be inserted directly into JSON requests.

Instead they must be encoded.

Markly uses:

```text
Base64 Encoding
```

---

Workflow:

```text
Image File
     │
     ▼
Binary Data
     │
     ▼
Base64 String
     │
     ▼
API Request
```

---

The resulting string may look like:

```text
/9j/4AAQSkZJRgABAQAAAQABAAD...
```

Thousands of characters long.

Humans never read this.

It exists purely for transport.

---

# Mixed-Content Requests

A multimodal request contains both:

```text
Text Instructions
```

and

```text
Image Data
```

---

Conceptually:

```text
[
  Teacher Instructions,
  Student Assignment Image
]
```

---

This is fundamentally different from traditional prompts:

```text
"Grade this assignment."
```

because the model now receives visual context.

---

# Understanding Layout Awareness

One major advantage of vision models is:

> Layout understanding.

---

Consider:

```text
Question 1
Answer A

Question 2
Answer B
```

A text extractor might lose positioning information.

---

A vision model sees:

```text
Question beside answer
```

which often preserves meaning.

---

This is especially useful for:

* worksheets
* examination papers
* tables
* forms
* diagrams

---

# Handwriting Recognition

One of the most impressive capabilities of modern vision models is handwriting interpretation.

---

Example:

```text
Student handwriting
```

↓

```text
Model understands content
```

↓

```text
Model evaluates reasoning
```

---

This is what allows Markly to assess:

* handwritten algebra
* handwritten science answers
* notebook submissions

without requiring typed text.

---

# Why Vision Models Are Not Perfect

Many beginners assume:

```text
Vision Model
=
Perfect Teacher
```

Not true.

---

Common challenges include:

### Poor Image Quality

```text
Blurred photo
Low resolution
Bad lighting
```

---

### Cropped Content

```text
Half of question missing
```

---

### Messy Handwriting

```text
Unreadable characters
```

---

### Multiple Pages

```text
Page order ambiguity
```

---

Good input quality still matters.

---

# Best Practices for Educational Images

When using Markly:

### Good

```text
Clear photo
Entire page visible
Good lighting
Readable handwriting
```

---

### Bad

```text
Blurry image
Dark shadows
Partial page
Tilted camera angle
```

---

The quality of visual input directly affects grading reliability.

---

# Why Multimodal Matters for Education

Most educational work is not purely text.

Students often communicate through:

* equations
* diagrams
* sketches
* annotations
* tables
* handwritten notes

---

Traditional text-based systems struggle with these formats.

Vision models dramatically expand what can be assessed.

---

# Markly's Multimodal Pipeline

The complete image workflow looks like:

```text
Student Submission
         │
         ▼
Image Upload
         │
         ▼
Base64 Encoding
         │
         ▼
Teacher Persona
         │
         ▼
Vision Model
         │
         ▼
Structured Feedback
         │
         ▼
PDF Report
```

---

# OCR + Vision: The Future Pattern

Many production systems increasingly use:

```text
OCR
+
Vision Models
```

together.

---

OCR provides:

```text
Fast text extraction
```

---

Vision provides:

```text
Context
Layout
Reasoning
Understanding
```

---

Combining both often produces the strongest results.

---

# What Multimodal Enabled in Markly

Before vision support:

```text
PDFs
DOCX
Essays
Reports
```

---

After vision support:

```text
Handwritten worksheets
Scanned exams
Photos
Diagrams
Sketches
Flowcharts
Visual reasoning
```

---

This dramatically increased the range of assignments Markly can assess.

---

# Key Takeaways

Multimodal AI is not simply OCR with better accuracy.

The critical difference is:

```text
OCR extracts text
Vision models understand content
```

Markly uses vision models to evaluate:

* reasoning
* diagrams
* handwritten work
* visual structure

in addition to traditional text.

This capability is what transformed Markly from a document grader into a genuine **multimodal educational assessment system**.

**Next:** Appendix E — AI System Design Patterns Used Throughout Markly (Classifiers, Routers, Pipelines, Validators, and Memory Systems)
