# Part 9 — Automatic Subject Detection (AI Classification Layer)

Up to this point, Markly requires the teacher to manually select a subject before grading:

* Mathematics
* English
* Science
* Programming

This works, but it introduces unnecessary friction in real classroom workflows.

Teachers don’t want to think about classification. They just want to upload a file and get meaningful feedback.

More importantly, manual selection introduces a subtle but critical risk:

* A math worksheet might be graded as English
* A programming assignment might be graded as Science
* A handwritten response might be misinterpreted entirely

Even if the grading system is strong, **the wrong subject means the wrong grading lens**.

In this chapter, we remove that responsibility from the teacher.

We introduce a new capability:

> **AI as a classifier before AI as a grader**

---

# The New Architecture

We are inserting a new step into the pipeline: subject classification.

```text
Upload Assignment
        │
        ▼
Extract Content (Text / Image)
        │
        ▼
🧠 Subject Detection (NEW)
        │
        ▼
Select Persona Automatically
        │
        ▼
Grade Assignment
        │
        ▼
Generate Report
```

Instead of asking the teacher:

> “Which subject is this?”

We now ask the model:

> “What subject does this appear to be?”

---

# Why This Works

LLMs are surprisingly strong at semantic classification, even without explicit rules.

They infer subject type from patterns in the content:

### Mathematics

* Equations and symbols
* Step-by-step derivations
* Structured problem solving

### English

* Paragraphs and essays
* Grammar structures
* Narrative or argumentative writing

### Programming

* Keywords like `def`, `for`, `class`
* Syntax and indentation
* Logical code structure

### Science

* Experimental descriptions
* Technical terminology
* Diagrams or structured explanations

In effect, we are using the model as a **semantic classifier**, not just a generator.

---

# Step 1 — Create a Subject Classification Prompt

Open `engine.py` and add a dedicated prompt for classification.

```python
SUBJECT_DETECTION_PROMPT = """
You are an academic subject classifier.

Your task is to determine the subject of a student assignment.

Choose ONLY one of the following:
- Mathematics
- English
- Science
- Programming

Rules:
- Output ONLY the subject name
- Do not explain
- Do not add punctuation
- Do not include any extra text

Assignment:
"""
```

---

## Why Strict Output Matters

Without constraints, the model might respond like:

```text
This appears to be a Mathematics assignment because it contains equations...
```

That breaks automation.

We need a clean, machine-readable output:

```text
Mathematics
```

This is what allows downstream components to function reliably.

---

# Step 2 — Implement Subject Detection

Now implement the classification function.

```python
def detect_subject(content):

    prompt = SUBJECT_DETECTION_PROMPT + content

    response = client.chat.completions.create(
        model="openai/gpt-oss-20b:free",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ],
        temperature=0
    )

    return response.choices[0].message.content.strip()
```

---

## Why `temperature = 0`

We are no longer generating creative text.

We are performing classification.

Setting:

```python
temperature = 0
```

ensures:

* deterministic output
* consistent classification
* reduced randomness between identical inputs

This is essential for production-grade pipelines.

---

# Step 3 — Integrate Into the Grading Pipeline

Previously, Markly relied on manual subject selection:

```python
result = grade_assignment(content, subject.value)
```

We now replace this with automatic detection.

---

## Update App Logic

```python
from engine import grade_assignment, detect_subject
```

---

## Step 3.1 Extract Content First

```python
content = extract_text_from_file(upload.value, upload.filename)
```

---

## Step 3.2 Detect Subject Automatically

```python
status.object = "Detecting subject..."
status.alert_type = "primary"

predicted_subject = detect_subject(content)

status.object = f"Detected subject: {predicted_subject}"
```

---

## Step 3.3 Pass Into Grading Engine

```python
result = grade_assignment(
    content,
    predicted_subject
)
```

At this point, the teacher is no longer involved in classification.

---

# Step 4 — Handling Image-Based Assignments

For images, we follow a simplified fallback approach:

```python
if filename.endswith((".png", ".jpg", ".jpeg")):

    image = image_to_base64(upload.value)

    # Placeholder content for classification
    content = "[IMAGE_ASSIGNMENT]"

    predicted_subject = detect_subject(content)

    result = grade_image(image, predicted_subject)
```

Later, this can be upgraded to full vision-based classification, but this keeps the system simple for now.

---

# Step 5 — The Architectural Shift

We are now using the LLM in two distinct roles:

### 1. Classifier (Pre-processing Layer)

```text
Input: assignment
Output: subject
```

### 2. Teacher (Grading Layer)

```text
Input: assignment + persona
Output: feedback
```

This is a key architectural pattern:

> **Multi-stage LLM pipeline design**

Instead of one large prompt doing everything, we decompose intelligence into stages.

---

# Step 6 — Improving Classification Accuracy

We can refine the prompt further for better accuracy:

```python
SUBJECT_DETECTION_PROMPT = """
You are an expert academic curriculum classifier.

Determine the most likely subject of this assignment.

Subjects:
- Mathematics (numbers, equations, formulas)
- English (essays, paragraphs, writing)
- Science (experiments, theory, diagrams)
- Programming (code, syntax, algorithms)

Return ONLY one word:
Mathematics, English, Science, or Programming.

Assignment:
"""
```

This improves decision boundaries and reduces ambiguity between subjects.

---

# Step 7 — Optional Debugging Enhancement

For development purposes, you may log confidence:

```python
print("Detected subject:", predicted_subject)
```

You can also extend later to:

```text
Subject: Mathematics
Confidence: 0.92
```

But for now, we keep production output simple.

---

# What We Just Built

Markly has evolved significantly:

### Before

* Teacher manually selects subject
* System is static and rule-driven

### Now

* AI automatically detects subject
* System adapts based on input
* Persona is assigned dynamically
* Grading becomes context-aware

---

# Updated System Architecture

```text
                    Teacher
                       │
                       ▼
              Upload Assignment
                       │
                       ▼
        Extract Text / Image Content
                       │
                       ▼
        🧠 Subject Classification (LLM)
                       │
                       ▼
        Select Persona Automatically
                       │
                       ▼
              Grade Assignment
                       │
                       ▼
            Generate PDF Report
```

---

# Why This Is a Big Step

Markly is no longer a fixed workflow system.

It is now an **adaptive AI system**.

Instead of asking the user:

> “What is this?”

We now ask:

> “What does this look like?”

That shift—from explicit instruction to inference—is what defines modern AI-native applications.

---

# What’s Next

So far, Markly can:

* Process text and images
* Detect subject automatically
* Apply persona-based grading
* Generate structured feedback reports

But there is still a major limitation:

> The system has no memory.

Each submission is treated independently.

It does not know:

* whether a student improved
* repeated mistakes
* long-term learning patterns
* historical performance

In the next chapter, we will evolve Markly into a **student-aware system**, capable of tracking learning over time and generating longitudinal feedback like a real teacher.
