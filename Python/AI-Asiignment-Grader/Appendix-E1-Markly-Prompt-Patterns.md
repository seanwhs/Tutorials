# Appendix E — Prompt Engineering Patterns Used in Markly

Throughout this tutorial, we have repeatedly modified prompts to influence model behavior.

At first glance, this may seem like a minor implementation detail.

In reality:

> Prompt design is one of the most important engineering disciplines in AI-native systems.

The difference between a useful grading system and an unreliable grading system is often not the model.

It is the prompt.

This appendix consolidates the prompt engineering techniques used throughout Markly and explains why they work.

---

# Why Prompt Engineering Matters

A common beginner assumption is:

```text
Better model = Better application
```

In practice:

```text
Model Quality × Prompt Quality
```

determines output quality.

Even powerful models can produce poor results if instructions are vague.

For example:

```text
Grade this assignment.
```

versus:

```text
You are an experienced secondary mathematics teacher.

Evaluate:

- reasoning
- methodology
- conceptual understanding

Provide:

## Strengths
## Mistakes
## Suggestions
## Final Grade
```

Both prompts use the same model.

Outputs are dramatically different.

---

# The Four Prompt Layers in Markly

Markly eventually evolves into a multi-layer prompting system.

```text
System Role
      +
Subject Persona
      +
Rubric Constraints
      +
Student Context
```

Together these create grading behavior.

---

# Pattern 1 — Role Prompting

Role prompting assigns an identity.

Example:

```text
You are an experienced mathematics teacher.
```

This changes:

* tone
* evaluation style
* terminology
* reasoning approach

Without a role:

```text
Generic AI assistant
```

With a role:

```text
Domain expert
```

---

## Mathematics Example

```text
You are an experienced mathematics teacher.

Evaluate:

- calculation accuracy
- logical reasoning
- methodology
```

The model begins thinking like a mathematics instructor.

---

## Programming Example

```text
You are a software engineering instructor.

Evaluate:

- correctness
- readability
- maintainability
- efficiency
```

Now the same model behaves like a code reviewer.

---

# Pattern 2 — Task Specification

Never assume the model knows what you want.

Bad:

```text
Review this assignment.
```

Good:

```text
Review this assignment.

Identify:

- strengths
- weaknesses
- misconceptions
- improvement opportunities
```

Specific instructions reduce ambiguity.

---

# Pattern 3 — Output Formatting

One of the biggest sources of AI integration failures is inconsistent output.

Bad:

```text
Grade this assignment.
```

Possible outputs:

```text
Great work!

8/10
```

or

```text
The student demonstrates...
```

or

```text
Final score: 80%
```

All are valid.

All are difficult to automate.

---

## Structured Output Pattern

Instead:

```text
Provide:

## Strengths

## Weaknesses

## Suggestions

## Final Grade
```

Now outputs become predictable.

---

# Why This Matters

Later systems depend on structure.

Examples:

* PDF generation
* Grade extraction
* Analytics
* Validation

Structured prompts create machine-friendly outputs.

---

# Pattern 4 — Constraint Prompting

Sometimes the most important instruction is what the model must NOT do.

Example from subject classification:

```text
Return ONLY one of:

Mathematics
English
Science
Programming

Do not explain.
Do not add punctuation.
Do not add extra text.
```

Without constraints:

```text
This appears to be a mathematics assignment because...
```

With constraints:

```text
Mathematics
```

Much easier to automate.

---

# Pattern 5 — Rubric Grounding

One of the most important reliability techniques in Markly.

Instead of:

```text
Assign a grade.
```

We use:

```text
Evaluate only against this rubric.
```

Example:

```text
Accuracy (4 points)
Working (3 points)
Clarity (2 points)
Final Answer (1 point)
```

This constrains scoring.

Benefits:

* consistency
* transparency
* auditability

---

# Pattern 6 — Context Injection

Later versions of Markly introduce student memory.

We inject historical context.

Example:

```text
Student History:

- Previous grade: 6/10
- Common issue: sign errors

Current Assignment:
...
```

Now the model can identify:

```text
Improvement since last submission
```

rather than treating every assignment independently.

---

# Pattern 7 — Multimodal Prompting

Vision models require a different pattern.

Bad:

```text
What is in this image?
```

Good:

```text
You are an experienced teacher.

Examine the assignment image.

Identify:

- correct answers
- incorrect reasoning
- missing steps
- misconceptions
```

The image provides evidence.

The prompt provides purpose.

Both are required.

---

# Pattern 8 — Deterministic Prompting

Certain tasks should be predictable.

Examples:

* subject detection
* rubric scoring
* classification

For these tasks:

```python
temperature=0
```

Combined with:

```text
Return ONLY the answer.
```

This minimizes randomness.

---

# Pattern 9 — Chain-of-Responsibility Prompting

A major architectural shift occurs in Part 11.

Instead of:

```text
Assignment
    ↓
Model
    ↓
Grade
```

We split responsibility.

### Prompt 1

```text
Evaluate rubric criteria.
```

Output:

```text
accuracy: 3/4
working: 2/3
```

---

### System Layer

```text
Compute final score.
```

---

### Prompt 2

```text
Explain results.
```

Output:

```text
Feedback narrative
```

The model no longer owns everything.

Responsibilities are separated.

---

# Pattern 10 — Prompt Templates

Hardcoding prompts is manageable initially.

Eventually:

```python
prompt = f"..."
```

becomes difficult to maintain.

Instead:

```python
PROMPTS = {
    "subject_detection": "...",
    "rubric_evaluation": "...",
    "feedback_generation": "...",
    "vision_grading": "..."
}
```

Benefits:

* central management
* version control
* easier testing
* easier experimentation

---

# Common Prompt Engineering Mistakes

## Mistake 1 — Asking Multiple Tasks at Once

Bad:

```text
Detect subject, grade assignment,
create rubric, generate score,
and write feedback.
```

This overloads the model.

Prefer:

```text
Subject Detection
      ↓
Rubric Evaluation
      ↓
Score Computation
      ↓
Feedback Generation
```

---

## Mistake 2 — Vague Criteria

Bad:

```text
Grade fairly.
```

Fair means different things to different models.

Use explicit criteria.

---

## Mistake 3 — Missing Output Structure

Bad:

```text
Review this work.
```

Good:

```text
Return:

## Strengths
## Weaknesses
## Suggestions
## Final Grade
```

---

## Mistake 4 — Letting the Model Control Everything

Avoid:

```text
Determine criteria.
Determine score.
Determine feedback.
```

Instead:

```text
System defines criteria.
Model evaluates evidence.
```

This is the philosophy behind Markly's rubric layer.

---

# The Evolution of Prompting in Markly

| Stage   | Prompt Style           | Purpose             |
| ------- | ---------------------- | ------------------- |
| Part 4  | Generic prompts        | Basic grading       |
| Part 5  | Teacher personas       | Subject expertise   |
| Part 6  | Vision prompts         | Image understanding |
| Part 9  | Classification prompts | Subject detection   |
| Part 10 | Context prompts        | Student memory      |
| Part 11 | Rubric prompts         | Reliable evaluation |

This progression mirrors how real AI systems mature.

---

# Key Takeaway

The most important lesson from Markly is:

> AI behavior is not stored inside your application. It emerges from the interaction between model capabilities, system architecture, and prompt design.

A stronger model helps.

A better prompt often helps more.

And a well-designed architecture ensures that prompts are used consistently, predictably, and safely.

---

**Next Appendix:**
**Appendix F — Testing & Evaluation Strategies for AI Grading Systems** (how to measure grading quality, detect regressions, benchmark prompts, and validate rubric consistency).
