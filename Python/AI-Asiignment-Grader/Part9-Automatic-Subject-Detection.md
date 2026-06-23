# Part 9 — Automatic Subject Detection (AI Classification Layer)

Up to this point, Markly requires the teacher to manually select a subject:

* Mathematics
* English
* Science
* Programming

That works, but in real classroom workflows, it introduces friction.

Teachers don’t always want to think about classification. They just want to upload a file and get feedback.

Also, manual selection creates a subtle but important problem:

* A math worksheet might be accidentally graded as English
* A programming assignment might be graded as Science
* Handwritten work might be misclassified

Even with good personas, the *wrong subject = wrong grading lens*

In this chapter, we’ll remove that responsibility from the teacher.

We’ll teach Markly to automatically detect the subject of an assignment using the same LLM we already use for grading.

This introduces a new capability:

> **AI-as-a-classifier before AI-as-a-grader**

---

# The New Architecture

We are adding a new step in the pipeline:

```text id="cls_arch_1"
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

Instead of asking:

> “Which subject is this?”

we will ask the AI:

> “What subject does this look like?”

---

# Why This Works Surprisingly Well

LLMs are very strong at pattern recognition.

Even without explicit rules, they can infer subject type from:

### Mathematics

* equations
* symbols
* step-by-step working

### English

* paragraphs
* essays
* grammar structure

### Programming

* syntax like `def`, `for`, `{}`, indentation

### Science

* diagrams
* terminology
* experimental structure

So we are essentially using the model as a **semantic classifier**.

---

# Step 1 — Creating a Subject Classifier Prompt

Open `engine.py`.

We will create a dedicated function.

```python id="cls_fn_1"
def detect_subject(content):
```

Now we need a prompt that forces structured output.

LLMs are naturally verbose, so we must constrain them.

---

## The Classification Prompt

```python id="cls_prompt_1"
SUBJECT_DETECTION_PROMPT = """
You are an academic subject classifier.

Your task is to determine the subject of a student assignment.

Choose ONLY one of the following:

- Mathematics
- English
- Science
- Programming

Rules:
- Output ONLY the subject name.
- Do not explain.
- Do not add punctuation.
- Do not add extra text.

Assignment:
"""
```

---

# Why We Force “Only One Word Output”

Without strict constraints, the model might respond like:

```text
This appears to be a mathematics assignment because...
```

That breaks our pipeline.

We want clean machine-readable output:

```text
Mathematics
```

This is critical for automation.

---

# Step 2 — Implementing Subject Detection

Now we implement the function.

```python id="cls_fn_2"
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

## Why `temperature=0`?

This is important.

We are switching from:

* creative generation ❌
  to
* classification / deterministic output ✅

Setting:

```python
temperature=0
```

forces:

* consistency
* repeatability
* reduced randomness

This is exactly what we want for classification.

---

# Step 3 — Connecting It to the Grading Pipeline

Now open `app.py`.

Previously we had:

```python
result = grade_assignment(
    assignment,
    subject.value
)
```

We will replace this logic.

---

## Step 3.1 Remove Manual Subject Selection (Optional UI Change)

You can either:

### Option A (recommended now)

Keep dropdown as fallback

### Option B (better UX)

Hide it completely later

For now, we keep it for debugging.

---

## Step 3.2 Inject Subject Detection

Update the callback:

```python id="cls_ui_1"
from engine import grade_assignment, detect_subject
```

Now modify the grading flow:

```python id="cls_ui_2"
content = extract_text_from_file(
    upload.value,
    upload.filename
)

status.object = "Detecting subject..."
status.alert_type = "primary"

predicted_subject = detect_subject(content)

status.object = f"Detected subject: {predicted_subject}"
```

---

# Step 4 — Using the Detected Subject

Now we pass it into the grading engine:

```python id="cls_ui_3"
result = grade_assignment(
    content,
    predicted_subject
)
```

That’s it.

We’ve removed manual classification from the teacher entirely.

---

# Step 5 — Handling Image Assignments

We must also handle vision inputs.

Modify logic:

```python id="cls_img_1"
if filename.endswith((".png", ".jpg", ".jpeg")):

    image = image_to_base64(upload.value)

    # For images, we can still classify using text prompt fallback
    # OR reuse vision model later (we keep simple for now)

    content = "[IMAGE_ASSIGNMENT]"

    predicted_subject = detect_subject(content)

    result = grade_image(image, predicted_subject)
```

---

# Important Design Insight

We are now using the LLM in **two different roles**:

### 1. Classifier

```text
Input: assignment
Output: subject
```

### 2. Teacher

```text
Input: assignment + persona
Output: grading feedback
```

This is a powerful architectural pattern:

> **Multi-stage LLM pipelines**

---

# Step 6 — Improving Classification Accuracy

Right now, classification uses raw text only.

We can improve it with stronger prompting:

```python id="cls_prompt_2"
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

This reduces ambiguity significantly.

---

# Step 7 — Confidence Debugging (Optional Enhancement)

We can also ask for confidence:

```python id="cls_conf_1"
Return format:

Subject: <one word>
Confidence: <0-1>
```

But we do NOT use this in production yet.

We only log it:

```python id="cls_log_1"
print("Detected:", predicted_subject)
```

This helps debugging misclassifications.

---

# What We Just Built

Markly is now capable of:

### Before

* Teacher manually selects subject

### Now

* AI automatically determines subject
* Routes to correct persona
* Applies correct grading strategy

---

# Updated System Architecture

```text id="cls_arch_2"
                    Teacher
                       │
                       ▼
              Upload Assignment
                       │
                       ▼
           Extract Text / Image
                       │
                       ▼
        ┌─────────────────────────┐
        │  Subject Classification │
        │        (LLM)           │
        └─────────────────────────┘
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

This chapter introduces something important:

> Markly is no longer a fixed pipeline.
> It is now an adaptive AI system.

We are no longer telling the system:

* “This is Mathematics”

We are asking:

* “What *is* this?”

This shift is what makes modern AI applications feel intelligent.

---

# What’s Next

At this point, Markly is already a fairly complete system:

* Multimodal input (text + images)
* Subject-aware grading
* Automatic classification
* PDF report generation
* Professional UI experience

But there is still one major limitation:

> The system is stateless.

Every assignment is treated independently.

There is no memory of:

* previous submissions
* student progress
* recurring mistakes
* improvement over time

In the next instalment, we will upgrade Markly into a **student-aware system**, where the AI tracks performance trends and generates longitudinal feedback like a real teacher would over a semester.
