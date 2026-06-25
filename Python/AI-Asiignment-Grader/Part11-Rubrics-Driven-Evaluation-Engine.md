# Part 11 — Building a Rubric & Validation Layer (Making Markly Trustworthy)

Up to this point, Markly has grown into a surprisingly capable educational AI platform.

It can:

* Grade text-based assignments
* Analyze handwritten worksheets and scanned submissions
* Detect subjects automatically
* Apply subject-specific teacher personas
* Generate professional PDF reports
* Track student progress over time
* Maintain historical performance records

From a feature perspective, the system already feels complete.

However, there is a fundamental problem hiding underneath everything we have built so far:

> We are still allowing the LLM to decide the grade.

For demonstrations, prototypes, and personal projects, this may be acceptable.

For real educational environments, it is not.

---

# The Reliability Problem

Imagine two students submitting similar work.

Student A receives:

```text
8/10
```

Student B receives:

```text
10/10
```

A teacher immediately asks:

> Why?

Where did those numbers come from?

Which criteria were used?

Could another teacher arrive at the same result?

Could the same assignment receive a different score tomorrow?

Without explicit grading standards, these questions are impossible to answer.

And that creates a trust problem.

---

# Why LLMs Alone Are Not Enough

Large Language Models are excellent at:

* Understanding content
* Identifying mistakes
* Explaining concepts
* Generating feedback

But they are not naturally designed for:

* Consistent scoring
* Auditability
* Policy enforcement
* Institutional assessment standards

Even with temperature set to zero, models can still:

* Emphasize different weaknesses
* Weight criteria differently
* Interpret grading expectations differently

In other words:

> LLMs are strong evaluators, but weak authorities.

Educational systems require the opposite.

They require:

* Explicit criteria
* Repeatable decisions
* Transparent scoring

So we introduce a new architectural layer.

---

# The Core Design Principle

We separate:

### Evaluation

From

### Scoring

---

Before:

```text
Student Work
      │
      ▼
      LLM
      │
      ▼
Feedback + Grade
```

The model performs everything.

---

After:

```text
Student Work
      │
      ▼
LLM Evaluation
      │
      ▼
Rubric Validation Layer
      │
      ▼
Deterministic Scoring Engine
      │
      ▼
Teacher Feedback
```

The model no longer owns the final grade.

The system does.

This is one of the most important architectural upgrades in the entire Markly project.

---

# Introducing Rubrics

Teachers do not grade using intuition alone.

They grade using standards.

A rubric defines:

* what matters
* how much it matters
* how marks are allocated

Instead of asking:

> "What grade should this receive?"

We ask:

> "How well does this submission satisfy each criterion?"

This transforms grading from an opinion into a structured evaluation process.

---

# Creating `rubrics.py`

Create a dedicated module:

```text
markly/

app.py
engine.py
personas.py
utils.py
storage.py
report.py
rubrics.py
```

The responsibility of this file is simple:

> Define grading standards.

---

# Mathematics Rubric

```python
MATHEMATICS_RUBRIC = {
    "Calculation Accuracy": 4,
    "Methodology": 3,
    "Working Shown": 2,
    "Final Answer": 1
}
```

Total:

```text
10 Marks
```

---

# English Rubric

```python
ENGLISH_RUBRIC = {
    "Grammar": 3,
    "Structure": 3,
    "Argument": 2,
    "Vocabulary": 2
}
```

---

# Science Rubric

```python
SCIENCE_RUBRIC = {
    "Scientific Accuracy": 4,
    "Conceptual Understanding": 3,
    "Reasoning": 2,
    "Communication": 1
}
```

---

# Programming Rubric

```python
PROGRAMMING_RUBRIC = {
    "Correctness": 4,
    "Readability": 2,
    "Efficiency": 2,
    "Design": 2
}
```

---

# Centralized Rubric Registry

Just like personas, we create a registry.

```python
RUBRICS = {
    "Mathematics": MATHEMATICS_RUBRIC,
    "English": ENGLISH_RUBRIC,
    "Science": SCIENCE_RUBRIC,
    "Programming": PROGRAMMING_RUBRIC
}
```

This allows simple retrieval:

```python
rubric = RUBRICS[predicted_subject]
```

---

# Constraining the Model

The next challenge is preventing the model from inventing grades.

We want the model to evaluate evidence only.

Create a dedicated rubric prompt:

```python
RUBRIC_EVALUATION_PROMPT = """
You are a grading evaluator.

Evaluate the student submission using ONLY the rubric provided.

Rules:

- Score every category independently.
- Do not calculate totals.
- Do not assign a final grade.
- Base scoring only on visible evidence.
- Keep reasoning concise.

Rubric:

{rubric}

Student Work:

{assignment}

Return EXACTLY:

Category Scores:

- Category: score/max
- Category: score/max

Justification:

...
"""
```

Notice the wording.

We intentionally remove authority from the model.

The model becomes an assessor.

Not a grader.

---

# Stage 1 — Evidence Extraction

Implement:

```python
async def evaluate_with_rubric(
    assignment,
    rubric
):
```

The model now produces something like:

```text
Category Scores:

Calculation Accuracy: 3/4
Methodology: 2/3
Working Shown: 2/2
Final Answer: 1/1

Justification:

Minor arithmetic mistake in Question 4.
```

This output is structured.

That means software can process it.

---

# Parsing Scores

Add a parser:

```python
import re

def parse_scores(text):

    matches = re.findall(
        r"(\d+)\s*/\s*(\d+)",
        text
    )

    return [
        (int(a), int(b))
        for a, b in matches
    ]
```

Example:

```python
[(3,4), (2,3), (2,2), (1,1)]
```

---

# Deterministic Grade Computation

This is where control returns to the system.

```python
def compute_final_score(scores):

    obtained = sum(
        score
        for score, maximum in scores
    )

    maximum = sum(
        maximum
        for score, maximum in scores
    )

    return obtained, maximum
```

Output:

```python
(8, 10)
```

The grade is now calculated by code.

Not generated by AI.

---

# Why This Matters

Before:

```text
LLM decides score
```

After:

```text
LLM supplies evidence

System computes score
```

This distinction is subtle but enormously important.

The grading standard now belongs to Markly.

Not the model provider.

---

# Stage 2 — Feedback Generation

Now we reuse the model for what it does best:

Language.

Create a second prompt:

```python
FEEDBACK_PROMPT = """
You are a teacher.

Using the rubric evaluation below,
generate constructive feedback.

Rubric Results:

{rubric_results}

Include:

## Strengths

## Areas for Improvement

## Suggestions

## Summary
"""
```

The model now explains results.

It no longer determines them.

---

# Building the Validation Layer

We can now create a complete grading workflow:

```python
async def grade_with_rubric(
    assignment,
    subject
):

    rubric = RUBRICS[subject]

    evaluation = await evaluate_with_rubric(
        assignment,
        rubric
    )

    scores = parse_scores(evaluation)

    obtained, total = compute_final_score(
        scores
    )

    feedback = await generate_feedback(
        evaluation
    )

    return {
        "subject": subject,
        "score": f"{obtained}/{total}",
        "evaluation": evaluation,
        "feedback": feedback
    }
```

---

# Adding Validation Checks

Once scoring becomes structured, we can validate results automatically.

Example:

```python
def validate_scores(scores):

    for score, maximum in scores:

        if score > maximum:
            raise ValueError(
                "Invalid rubric score detected."
            )

        if score < 0:
            raise ValueError(
                "Negative score detected."
            )
```

This catches malformed model output before it reaches teachers.

---

# Architecture After Validation

Markly now contains multiple intelligence layers.

```text
Upload Assignment
         │
         ▼
Content Extraction
         │
         ▼
Subject Detection
         │
         ▼
Teacher Persona
         │
         ▼
Rubric Evaluation
         │
         ▼
Validation Layer
         │
         ▼
Deterministic Scoring
         │
         ▼
Feedback Generation
         │
         ▼
Student Memory Update
         │
         ▼
PDF Report
```

Notice something important:

The LLM appears multiple times.

But each usage has a narrowly defined responsibility.

This is how production AI systems are built.

---

# What We Have Achieved

Before this chapter, Markly was:

```text
AI-assisted grading
```

After this chapter, Markly becomes:

```text
AI-assisted evaluation
+
System-controlled scoring
```

That distinction is what makes the platform trustworthy.

---

# Why This Is One of the Most Important Chapters

This chapter introduces three characteristics that educational institutions care deeply about:

### Consistency

The same rubric is applied every time.

### Auditability

Every mark maps to an explicit criterion.

### Control

The grading policy belongs to the application, not the model.

These three properties are foundational for any serious assessment platform.

---

# Markly's Evolution So Far

```text
Part 1–3
Document Processing

Part 4
Multi-Model AI Orchestration

Part 5
Teacher Personas

Part 6
Vision-Based Grading

Part 7
PDF Reporting

Part 8
Professional UX

Part 9
Automatic Subject Detection

Part 10
Student Memory

Part 11
Rubric Validation & Deterministic Scoring
```

Markly is no longer a grading demo.

It is now a layered educational AI system with:

* multimodal understanding
* adaptive subject awareness
* teacher personas
* persistent student memory
* rubric-driven assessment
* deterministic scoring
* explainable feedback
* professional reporting

---

# Next Chapter Preview

Even with rubric validation in place, there is still an unanswered question:

> Can we explain exactly how every grade was produced months later?

To solve that, the next chapter introduces:

**Audit Trails, Analytics, and Educational Observability**

where Markly will begin tracking:

* grading decisions
* rubric evaluations
* model responses
* score distributions
* teacher-level analytics
* institutional reporting

This is the final step that transforms Markly from an AI grading application into a full educational assessment platform.
