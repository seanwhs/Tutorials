# Appendix C — Prompt Engineering Patterns Used in Markly

One of the most common misconceptions about AI systems is:

> "The intelligence comes from the model."

In reality:

> The usefulness of the model often comes from the quality of the instructions surrounding it.

Markly is a good example of this principle.

Throughout the project, we never trained a custom model.

We never fine-tuned GPT.

We never built a specialized educational model.

Instead, we transformed a general-purpose LLM into:

* a mathematics teacher
* an English teacher
* a programming instructor
* a science teacher
* a subject classifier
* a rubric evaluator
* a feedback generator

using nothing but prompt design.

This appendix explains the prompt engineering techniques used throughout Markly and why they matter.

---

# Prompt Engineering Is Interface Design

Most beginners think prompts are simply:

```text
Ask question → Get answer
```

Professional AI systems work differently.

A prompt is more accurately:

```text
Behavior Specification
```

or

```text
Software Configuration for an LLM
```

In Markly:

```text
Prompt = Teacher Personality
```

The model itself remains unchanged.

The instructions define its role.

---

# The Four Prompt Layers in Markly

Markly uses multiple prompt types.

Each serves a different purpose.

```text
1. Persona Prompts
2. Classification Prompts
3. Evaluation Prompts
4. Feedback Prompts
```

This separation is intentional.

---

# Layer 1 — Persona Prompts

Personas define:

> Who the model should behave as.

Example:

```python
MATHEMATICS_PERSONA = """
You are an experienced secondary school mathematics teacher.

Evaluate:
- calculations
- reasoning
- methodology
- final answers

Provide:
- strengths
- mistakes
- suggestions
- final grade
"""
```

---

Without persona:

```text
Grade this work.
```

Output:

```text
The work is generally good.
```

---

With persona:

```text
You are an experienced mathematics teacher.
```

Output:

```text
The student incorrectly applied
the distributive property in step 3.
```

Much more useful.

---

# Why Personas Work

LLMs learn patterns from enormous datasets.

Within those datasets are examples of:

* teachers
* tutors
* examiners
* reviewers
* professors

A persona acts as a retrieval signal.

It tells the model:

```text
Use teacher-like behavior
```

instead of:

```text
Use assistant-like behavior
```

---

# Good Persona Design

Good personas define:

### Identity

```text
You are an experienced teacher.
```

---

### Evaluation Criteria

```text
Focus on:
- reasoning
- accuracy
- methodology
```

---

### Output Structure

```text
Return:

Strengths
Mistakes
Suggestions
Final Grade
```

---

The combination creates stable behavior.

---

# Bad Persona Design

Example:

```text
Grade this assignment.
```

Problems:

* vague
* no criteria
* no structure
* inconsistent output

This creates prompt drift.

---

# Layer 2 — Classification Prompts

Markly uses AI before grading.

We first classify the assignment.

---

Goal:

```text
Input:
Assignment

Output:
Mathematics
```

Nothing else.

---

Prompt:

```python
SUBJECT_DETECTION_PROMPT = """
Determine the subject.

Choose ONLY:

- Mathematics
- English
- Science
- Programming

Output only the subject.
"""
```

---

# Why Classification Prompts Must Be Strict

Consider:

```text
What subject is this?
```

Possible output:

```text
This appears to be Mathematics because...
```

That breaks automation.

---

Instead:

```text
Output ONLY one subject name.
```

Produces:

```text
Mathematics
```

Machine-readable.

Reliable.

---

# Classification vs Generation

These are fundamentally different tasks.

---

Generation:

```text
Write feedback.
```

Many valid outputs.

---

Classification:

```text
Choose one category.
```

Only one valid output.

---

This is why Markly sets:

```python
temperature=0
```

for classification.

---

# Layer 3 — Rubric Evaluation Prompts

This is where prompt engineering becomes architecture.

Earlier versions asked:

```text
What grade should this get?
```

---

Problem:

The model becomes judge, jury, and executioner.

---

Instead:

```text
Evaluate evidence using rubric criteria.
Do not assign final grade.
```

---

Example:

```python
RUBRIC_PROMPT = """
Evaluate using ONLY the rubric.

Do not assign final grade.

Provide:

accuracy: x/4
working: x/3
clarity: x/2
final_answer: x/1
"""
```

---

This dramatically reduces variability.

---

# Why Rubrics Improve Reliability

Without rubric:

```text
Teacher A:
8/10

Teacher B:
6/10
```

---

With rubric:

```text
Accuracy: 3/4
Working: 2/3
Clarity: 2/2
Final Answer: 1/1
```

The scoring process becomes explicit.

---

Prompt engineering is enforcing a reasoning structure.

---

# Layer 4 — Feedback Prompts

Once scoring is complete:

```text
Scores computed
```

Now the model's job changes.

---

Old role:

```text
Grade student
```

---

New role:

```text
Explain results
```

---

Example:

```python
FINAL_FEEDBACK_PROMPT = """
Based on these rubric scores:

{scores}

Provide:

- strengths
- weaknesses
- improvement advice
- summary
"""
```

---

Notice:

The model no longer controls scoring.

Only communication.

This is safer.

---

# Structured Output Prompting

A major technique used throughout Markly is:

> Structured outputs.

---

Bad:

```text
Tell me what you think.
```

---

Good:

```text
Return:

## Strengths

## Weaknesses

## Suggestions

## Final Grade
```

---

Benefits:

* easier parsing
* predictable UI rendering
* easier PDF generation
* lower hallucination risk

---

# Prompt Constraints

Another recurring pattern is constraints.

Example:

```text
IMPORTANT:

Output ONLY one word.
```

---

Or:

```text
Do not explain.
```

---

Or:

```text
Do not assign a final grade.
```

---

Constraints narrow behavior.

The narrower the task:

```text
Less creativity
More consistency
```

---

# Temperature and Prompt Design

Many developers attempt to solve inconsistency by changing temperature.

This is only partially correct.

---

Bad prompt:

```text
Grade this.
```

Temperature:

```python
0
```

Still vague.

---

Good prompt:

```text
Evaluate only these rubric dimensions.
```

Temperature:

```python
0
```

Reliable.

---

Prompt quality matters more than temperature.

---

# The Markly Prompt Hierarchy

The complete prompt system now looks like:

```text
Assignment
      │
      ▼

Subject Classifier
      │
      ▼

Teacher Persona
      │
      ▼

Rubric Evaluation
      │
      ▼

Deterministic Scoring
      │
      ▼

Feedback Generator
```

Notice something important:

No single prompt does everything.

---

Instead:

```text
Many small prompts
```

replace:

```text
One giant prompt
```

This is a common production pattern.

---

# Why Small Prompts Scale Better

Large prompt:

```text
Determine subject,
grade assignment,
apply rubric,
provide feedback,
generate score,
write summary.
```

Problems:

* difficult to debug
* difficult to validate
* unpredictable behavior

---

Smaller prompts:

```text
Classifier
Evaluator
Scorer
Feedback Generator
```

Benefits:

* easier testing
* easier maintenance
* better reliability

---

# Prompt Engineering Is System Design

The biggest lesson from Markly is:

> Prompt engineering is not writing clever instructions.

It is designing responsibilities.

We used prompts to create:

* teachers
* classifiers
* evaluators
* explainers

Each prompt has a single job.

Each job has clear boundaries.

This is why Markly remains maintainable as the system grows.

---

# Key Takeaways

Prompt engineering in production systems is about:

### Defining Roles

```text
Teacher
Classifier
Evaluator
Explainer
```

---

### Defining Constraints

```text
Output only one word
Do not assign grades
Use rubric only
```

---

### Defining Structure

```text
Strengths
Weaknesses
Suggestions
```

---

### Separating Responsibilities

```text
Classification
Evaluation
Scoring
Feedback
```

The most reliable AI systems are not built from bigger prompts.

They are built from **smaller, well-defined prompts working together in a pipeline**.
