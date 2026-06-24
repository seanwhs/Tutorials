# Part 5 — Teaching the AI How to Grade: Building Teacher Personas

At this point, Markly is already capable of grading student assignments using a Large Language Model.

You can upload a file, select a subject, and receive structured feedback.

But after trying it across different types of work, something becomes obvious very quickly.

Whether you upload:

* a mathematics worksheet
* a history essay
* a Python programming assignment
* or a science report

the feedback often feels surprisingly *generic*.

You might see responses like:

> “Good work overall.”

or

> “Some improvements are needed in clarity.”

These statements are not incorrect — but they are not how real teachers evaluate student work.

A mathematics teacher focuses on reasoning steps.
An English teacher focuses on expression and structure.
A programming instructor focuses on correctness and design.

Each subject has a completely different evaluation mindset.

---

# The Core Idea: The Model Doesn’t “Know” How to Teach

A common misconception is that the model automatically adapts its teaching style based on the subject.

In reality, it doesn’t.

The model only follows instructions.

This means:

> If you don’t explicitly tell the model how to behave, it defaults to a generic assistant.

The good news is that this is also what makes LLMs powerful.

We don’t need to retrain anything.

We only need to change instructions.

---

# What is a Persona?

A **persona** is a structured set of instructions that defines how the AI should behave.

Instead of saying:

> Grade this assignment.

we say:

> You are an experienced secondary school mathematics teacher. Evaluate each step carefully, identify conceptual errors, and provide structured feedback.

These two prompts produce radically different outputs.

---

### Without Persona

```text
AI → Generic Assistant
```

### With Persona

```text
AI → Domain-Specific Teacher (Math / English / Programming / Science)
```

The model itself hasn’t changed.

Only the *instruction layer* has changed.

This technique is known as **prompt engineering**, and it is one of the most important foundations of practical AI application design.

---

# Why We Move Personas Into Their Own File

In early versions of Markly, the grading instructions were embedded directly inside `engine.py`.

```python
prompt = f"""
Please grade this assignment...
"""
```

This works for a single subject.

But it quickly becomes unmanageable when you scale to multiple disciplines.

Imagine supporting:

* 10 subjects
* multiple grade levels
* different marking rubrics

Your engine would become a mess of mixed responsibilities.

So we isolate all teaching behavior into a dedicated module:

```text
personas.py
```

---

### Final Project Structure

```
markly/
│
├── app.py
├── engine.py
├── utils.py
├── personas.py
```

Each file now has a clear responsibility:

| File        | Responsibility                         |
| ----------- | -------------------------------------- |
| app.py      | UI (Panel interface)                   |
| engine.py   | AI orchestration (async + multi-model) |
| utils.py    | File extraction (PDF, DOCX, images)    |
| personas.py | Subject-specific teaching behavior     |

This is not just organization — it is **architecture design for AI systems**.

---

# Designing Teacher Personas

A persona is not just a description.

It is a **behavior contract** for the model.

It defines:

* what to evaluate
* what to ignore
* how to structure feedback
* what “good grading” means for that subject

---

## Mathematics Persona

```python
MATHEMATICS_PERSONA = """
You are an experienced secondary school mathematics teacher.

Evaluate student work by carefully examining:

- each calculation step
- mathematical accuracy
- conceptual understanding
- logical reasoning

Identify:

- arithmetic mistakes
- conceptual misunderstandings
- missing steps

Provide structured feedback:

## Strengths
## Mistakes
## Suggestions
## Final Grade
"""
```

A key detail here is that we explicitly force **step-by-step reasoning evaluation**, which is critical for math grading.

---

## English Persona

```python
ENGLISH_PERSONA = """
You are an experienced English language teacher.

Evaluate the student's writing based on:

- grammar
- spelling
- punctuation
- sentence structure
- vocabulary usage
- clarity of expression
- argument structure

Do not only list mistakes.

Provide constructive, educational feedback.

Structure your response as:

## Strengths
## Areas for Improvement
## Suggestions
## Final Grade
"""
```

This shifts the model from “error detection” to **communication coaching**.

---

## Programming Persona

```python
PROGRAMMING_PERSONA = """
You are an experienced software engineering instructor.

Evaluate the code based on:

- correctness
- readability
- naming conventions
- modularity
- code duplication
- algorithm efficiency
- maintainability

If bugs exist:
explain the cause clearly.

Suggest improvements following software engineering best practices.

Do not rewrite the entire solution unless necessary.

Structure your response:

## Strengths
## Bugs
## Code Quality
## Suggestions
## Final Grade
"""
```

This persona turns the model into a **code reviewer**, not a solution generator.

---

## Science Persona

```python
SCIENCE_PERSONA = """
You are an experienced science teacher.

Evaluate based on:

- scientific accuracy
- conceptual understanding
- clarity of explanation
- use of scientific terminology
- logical reasoning

Identify misconceptions clearly and correct them.

Encourage curiosity while maintaining scientific rigor.

Structure your response:

## Strengths
## Misconceptions
## Suggestions
## Final Grade
"""
```

This encourages conceptual understanding rather than memorization.

---

# Organizing Personas for Easy Expansion

Instead of importing each persona individually, we group them into a dictionary:

```python
PERSONAS = {
    "Mathematics": MATHEMATICS_PERSONA,
    "English": ENGLISH_PERSONA,
    "Science": SCIENCE_PERSONA,
    "Programming": PROGRAMMING_PERSONA
}
```

Now retrieval becomes trivial:

```python
PERSONAS["Programming"]
```

This design allows us to scale Markly effortlessly.

To add a new subject:

1. define persona
2. register in dictionary
3. update dropdown

No changes to core engine logic required.

---

# Updating the AI Engine (Real Architecture)

Your actual `engine.py` does something more powerful than a simple API call.

Instead of querying one model, it:

> Runs multiple models concurrently and returns the first successful response.

This is an important production-grade design pattern.

### Key Idea:

> “We don’t wait for the best model — we take the fastest correct one.”

---

The engine:

* launches multiple async tasks
* queries different models in parallel
* returns the first successful result
* cancels remaining tasks automatically

This improves:

* latency
* reliability
* fault tolerance

---

# Integrating Personas into the Pipeline

Once personas exist, the engine only needs one change:

Instead of:

```python
prompt = f"Grade this assignment..."
```

we build subject-aware prompts in `app.py`.

---

# Updated App Flow (Current Design)

Your `app.py` now defines the full grading pipeline:

### 1. Upload file

```python
upload = pn.widgets.FileInput(...)
```

### 2. Select subject

```python
subject = pn.widgets.Select(...)
```

### 3. Extract text

```python
text = extract_text_from_file(...)
```

### 4. Build subject-aware prompt

```python
prompt = f"""
You are an experienced {subject.value} teacher.

Grade the following student assignment.

Provide:
- strengths
- weaknesses
- suggestions
- final grade

Assignment:
{text}
"""
```

### 5. Run AI engine asynchronously

```python
result = run_async(get_ai_response_concurrently(prompt))
```

### 6. Display feedback in UI

```python
feedback.object = result
```

---

# Why Personas Dramatically Improve Output

Let’s compare behavior:

### Without personas

* generic feedback
* inconsistent tone
* mixed evaluation criteria

### With personas

* subject-specific reasoning
* consistent grading style
* structured educational feedback
* realistic teacher behavior

---

# The Key Insight

The most important idea in this chapter is:

> The model is not the teacher. The prompt defines the teacher.

Or more precisely:

> AI behavior is an emergent property of instruction design.

---

# Architecture After Personas

```text
Teacher
  │
  ▼
Upload Assignment (Panel UI)
  │
  ▼
Select Subject
  │
  ▼
Extract Text (utils.py)
  │
  ▼
Build Prompt (persona-influenced behavior)
  │
  ▼
Async Multi-Model Engine (engine.py)
  │
  ▼
AI Response
  │
  ▼
Display Feedback (Panel UI)
```

---

# What You’ve Achieved So Far

At this stage, Markly is no longer a simple grading script.

It is now:

* multi-subject aware
* persona-driven
* async distributed across multiple models
* modular and extensible
* UI-driven via Panel

This is already a **real AI application architecture**, not a demo script.

---

# Next Step: Beyond Text — Multimodal Grading

So far, Markly only understands:

* PDFs
* Word documents
* extracted text

But real classroom submissions are often:

* handwritten worksheets
* diagrams
* photos of work
* scanned pages

In the next chapter, we’ll upgrade Markly into a **multimodal grading system** that can interpret images directly using vision-capable models.

---
