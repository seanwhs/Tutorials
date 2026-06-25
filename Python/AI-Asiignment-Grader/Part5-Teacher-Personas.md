# Part 5 — Teaching Markly How to Think Like a Teacher

## From Generic AI Responses to Educational Judgment

At this point, Markly can:

* Upload assignments
* Read PDFs, Word documents, and images
* Send content to AI models through OpenRouter
* Receive intelligent responses

This is already impressive.

However, if you test the system with different assignment types, a problem quickly appears.

Consider these submissions:

* A mathematics worksheet
* An English essay
* A science report
* A Python programming assignment

Even though they are completely different subjects, the feedback often sounds surprisingly similar.

You might receive comments such as:

> Good work overall.

or:

> Consider improving clarity and providing more detail.

These responses are not wrong.

But they are not how real teachers grade.

A mathematics teacher evaluates reasoning.

An English teacher evaluates communication.

A science teacher evaluates understanding.

A programming instructor evaluates correctness and software quality.

The AI needs to learn these differences.

---

# The Most Important Lesson About AI

Many beginners assume:

> The model already knows how to grade every subject.

This is only partially true.

The model has knowledge.

What it does not have is educational intent.

An LLM does not automatically decide:

* what matters
* what should be rewarded
* what should be penalized
* how feedback should be structured

Those decisions come from instructions.

In other words:

> The model supplies knowledge. The prompt supplies judgment.

This is one of the most important ideas in AI application development.

---

# Understanding Personas

A persona is a set of instructions that tells the model:

* who it is
* what role it should play
* what criteria matter
* how to communicate

Without a persona:

```text
Assignment
      ↓
Generic Assistant
      ↓
Generic Feedback
```

With a persona:

```text
Assignment
      ↓
Teacher Persona
      ↓
Subject-Specific Evaluation
```

The model remains the same.

Only the instructions change.

Yet the quality difference can be dramatic.

---

# Why Personas Belong in Their Own Module

A common beginner mistake is placing prompts directly inside application code.

For example:

```python
prompt = f"""
You are a teacher.
Grade this assignment.
"""
```

This works initially.

But as the application grows, the prompt becomes larger and larger.

Soon it contains:

* grading instructions
* rubrics
* output formatting
* scoring rules
* subject-specific behavior

Eventually `engine.py` becomes impossible to maintain.

Instead, we separate responsibilities.

```text
markly/

├── app.py
├── engine.py
├── utils.py
├── personas.py
├── rubrics.py
```

Each file now has a clear purpose.

| File        | Responsibility    |
| ----------- | ----------------- |
| app.py      | User Interface    |
| engine.py   | AI Communication  |
| utils.py    | File Processing   |
| personas.py | Teaching Behavior |
| rubrics.py  | Scoring Criteria  |

This is an example of Separation of Concerns.

---

# Designing Teacher Personas

A good persona is not a paragraph of marketing text.

It is a behavioral specification.

A persona should define:

* evaluation priorities
* feedback style
* educational goals
* output structure

Let's build several personas.

---

# Mathematics Persona

Create `personas.py`.

```python
MATHEMATICS_PERSONA = """
You are an experienced mathematics teacher.

Evaluate:

- calculation accuracy
- mathematical reasoning
- conceptual understanding
- logical progression of steps

Identify:

- arithmetic mistakes
- incorrect formulas
- missing working
- conceptual misunderstandings

Provide constructive educational feedback.
"""
```

Notice something important.

We are not asking:

> Is the answer correct?

We are asking:

> How did the student arrive at the answer?

This mirrors real mathematics assessment.

---

# English Persona

```python
ENGLISH_PERSONA = """
You are an experienced English teacher.

Evaluate:

- grammar
- spelling
- sentence structure
- vocabulary
- clarity
- argument development

Provide educational feedback that helps
the student become a better writer.
"""
```

English grading is fundamentally different.

A mathematically correct answer is either correct or incorrect.

Writing exists on a spectrum.

The persona must reflect this.

---

# Science Persona

```python
SCIENCE_PERSONA = """
You are an experienced science teacher.

Evaluate:

- scientific accuracy
- conceptual understanding
- terminology usage
- reasoning quality

Identify misconceptions clearly.

Correct misunderstandings while encouraging curiosity.
"""
```

Science assessment focuses heavily on conceptual correctness.

Students often use correct terminology while misunderstanding the underlying concept.

The persona should detect that.

---

# Programming Persona

```python
PROGRAMMING_PERSONA = """
You are an experienced software engineering instructor.

Evaluate:

- correctness
- readability
- naming conventions
- modularity
- maintainability
- efficiency

Identify bugs and explain them clearly.

Suggest improvements using software engineering best practices.
"""
```

Notice that programming evaluation is closer to code review than traditional marking.

---

# Organizing Personas

Instead of importing many variables individually, create a lookup table.

```python
PERSONAS = {
    "Mathematics": MATHEMATICS_PERSONA,
    "English": ENGLISH_PERSONA,
    "Science": SCIENCE_PERSONA,
    "Programming": PROGRAMMING_PERSONA,
}
```

Now retrieving a persona is simple:

```python
persona = PERSONAS["Programming"]
```

This design scales very well.

Adding a new subject becomes:

1. Create persona
2. Register persona
3. Done

No engine changes required.

---

# Why Personas Alone Are Not Enough

Early AI grading systems often stop here.

They provide:

* assignment
* persona
* grading request

Example:

```text
You are a mathematics teacher.

Grade this assignment:

[student work]
```

This is better than generic AI.

But it still has a major weakness.

Different teachers may produce different scores.

Why?

Because we have not defined a grading standard.

We have defined behavior.

We have not defined measurement.

---

# Introducing Rubrics

A rubric defines:

* what is being scored
* how many points each area is worth
* what good performance looks like

Real schools use rubrics because they improve consistency.

We should do the same.

Create:

```text
rubrics.py
```

Example:

```python
RUBRICS = {
    "Mathematics": """
    1. Calculation Accuracy (5 points)
    2. Correct Methodology (3 points)
    3. Final Answer Correctness (2 points)
    """,

    "English": """
    1. Grammar & Syntax (4 points)
    2. Clarity & Flow (3 points)
    3. Argument Strength (3 points)
    """,

    "Science": """
    1. Scientific Accuracy (4 points)
    2. Conceptual Understanding (3 points)
    3. Explanation Quality (3 points)
    """,

    "Programming": """
    1. Correctness (4 points)
    2. Code Quality (3 points)
    3. Maintainability (3 points)
    """
}
```

Now grading becomes more objective.

---

# Combining Persona + Rubric

The real power comes from combining both.

Persona:

```text
How should I think?
```

Rubric:

```text
How should I score?
```

Together:

```text
Assignment
      ↓
Persona
      ↓
Rubric
      ↓
AI Model
      ↓
Structured Evaluation
```

This is significantly more reliable than personas alone.

---

# Building the Grading Prompt

Inside the engine:

```python
prompt = f"""
{persona}

Use the following rubric:

{rubric}

Grade this assignment:

{assignment_text}

Provide:

## Strengths
## Weaknesses
## Suggestions
## Rubric Breakdown
## Final Grade
"""
```

This prompt contains:

* subject expertise
* grading standards
* output structure

Everything the model needs.

---

# Architecture Evolution

Originally Markly looked like this:

```text
Assignment
      ↓
AI
      ↓
Feedback
```

Now it becomes:

```text
Assignment
      ↓
Teacher Persona
      ↓
Rubric
      ↓
AI Model
      ↓
Structured Evaluation
```

This is much closer to how real educators work.

Teachers do not simply "give feedback."

They apply standards.

Rubrics encode those standards.

---

# The Big Idea

The most important concept from this chapter is:

> Good AI grading is not created by choosing a better model.

It is created by designing better evaluation systems.

The model supplies intelligence.

Personas supply expertise.

Rubrics supply consistency.

Together they create educational judgment.

---

# What We've Built

Markly is now capable of:

* Subject-specific evaluation
* Teacher-style feedback
* Consistent scoring criteria
* Rubric-driven assessment
* Extensible educational behavior

This moves the application from:

> AI chatbot

toward:

> AI grading platform

---

# What's Next?

So far Markly primarily works with extracted text.

But real classrooms contain:

* handwritten worksheets
* scanned assignments
* diagrams
* photographs of work
* annotated papers

In the next chapter, we will upgrade Markly into a multimodal system capable of understanding images directly using vision-capable AI models.

This is where Markly begins to move beyond OCR and into true visual assessment.
