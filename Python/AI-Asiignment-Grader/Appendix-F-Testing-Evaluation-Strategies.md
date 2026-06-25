# Appendix F — Testing & Evaluation Strategies for AI Grading Systems

One of the biggest mistakes in AI application development is assuming:

> “The output looks reasonable, therefore the system works.”

For a grading system, this mindset is dangerous.

Educational software operates in a high-trust environment.

Students, teachers, schools, and administrators rely on assessment outcomes.

A grading system that appears correct 95% of the time can still create serious problems if the remaining 5% contains:

* incorrect grades
* inconsistent scoring
* unfair feedback
* subject misclassification
* rubric violations

This appendix focuses on an often-overlooked discipline:

> **AI System Evaluation**

The goal is not to ask:

> “Does the AI seem good?”

The goal is to ask:

> “Can we measure whether the system is improving or regressing over time?”

---

# Why Testing AI Systems Is Different

Traditional software is deterministic.

Example:

```python
2 + 2
```

Expected:

```python
4
```

Always.

---

AI systems behave differently.

Given the same prompt:

```text
Grade this essay.
```

You might receive:

Run 1:

```text
8/10
```

Run 2:

```text
7/10
```

Run 3:

```text
9/10
```

All responses may appear reasonable.

But this variability introduces a challenge:

> How do we know whether the system is stable?

---

# What Are We Actually Testing?

Markly is not a single component.

It is a pipeline.

```text
Upload
   │
   ▼
Extraction
   │
   ▼
Subject Detection
   │
   ▼
Rubric Evaluation
   │
   ▼
Score Computation
   │
   ▼
Feedback Generation
   │
   ▼
PDF Reporting
```

Each layer can fail independently.

Testing must therefore be layered.

---

# Layer 1 — File Processing Tests

The first requirement is ensuring assignments are read correctly.

---

## Test Cases

### PDF

Input:

```text
math_worksheet.pdf
```

Expected:

```text
Extracted text contains equations
```

---

### DOCX

Input:

```text
essay.docx
```

Expected:

```text
Paragraph structure preserved
```

---

### Image

Input:

```text
worksheet.jpg
```

Expected:

```text
Base64 conversion succeeds
```

---

### Invalid File

Input:

```text
archive.zip
```

Expected:

```text
Graceful error message
```

Not:

```python
Traceback...
```

---

# Layer 2 — Subject Classification Tests

Subject detection is one of the easiest places for silent failure.

---

## Benchmark Dataset

Create:

```text
test_subjects/
```

Example:

```text
math_1.txt
math_2.txt
english_1.txt
science_1.txt
programming_1.txt
```

Each file has a known label.

---

## Evaluation

```python
predicted = detect_subject(content)
```

Compare:

```python
predicted == actual
```

Track accuracy.

---

Example:

```text
100 samples tested

Mathematics: 96%
English: 98%
Science: 92%
Programming: 99%

Overall Accuracy: 96.25%
```

Now classification quality becomes measurable.

---

# Layer 3 — Persona Consistency Testing

Personas should produce different evaluation styles.

---

## Mathematics Test

Input:

```text
2x + 5 = 15
2x = 20
x = 10
```

Expected feedback should discuss:

```text
reasoning
working steps
conceptual mistake
```

---

Not:

```text
Grammar improvements needed.
```

---

## Programming Test

Input:

```python
for i in range(10):
print(i)
```

Expected:

```text
indentation
syntax
readability
```

---

Not:

```text
Essay structure is weak.
```

---

This validates persona alignment.

---

# Layer 4 — Rubric Evaluation Tests

Part 11 introduced rubric-based scoring.

This layer is critical.

---

## Example Rubric

```python
{
    "accuracy": 4,
    "working": 3,
    "clarity": 2,
    "final_answer": 1
}
```

Maximum:

```text
10 points
```

---

## Validation Rules

### Rule 1

No category exceeds maximum.

Bad:

```text
accuracy: 5/4
```

Must fail validation.

---

### Rule 2

No negative scores.

Bad:

```text
working: -1/3
```

Must fail validation.

---

### Rule 3

Total score must be valid.

```text
Obtained ≤ Maximum
```

Always.

---

# Layer 5 — Grade Stability Testing

This is one of the most important AI tests.

---

## Repeatability Test

Run the same assignment:

```text
50 times
```

Measure:

```text
score variance
```

Example:

```text
Run 1: 8/10
Run 2: 8/10
Run 3: 8/10
...
```

Excellent stability.

---

Bad:

```text
6/10
8/10
9/10
7/10
```

Indicates prompt or rubric issues.

---

## Why This Matters

Teachers expect:

```text
Same work
=
Same grade
```

A grading system should not behave like a lottery.

---

# Layer 6 — Feedback Quality Evaluation

Grades alone are insufficient.

Feedback quality matters.

---

Evaluate:

### Specificity

Bad:

```text
Needs improvement.
```

Good:

```text
The student consistently loses negative signs when rearranging equations.
```

---

### Actionability

Bad:

```text
Practice more.
```

Good:

```text
Review solving linear equations involving negative coefficients.
```

---

### Educational Value

Feedback should teach.

Not merely criticize.

---

# Building a Golden Dataset

Professional AI teams use:

> Golden Evaluation Sets

These are manually reviewed examples.

---

Example:

```text
Assignment
Expected Subject
Expected Score Range
Expected Feedback Characteristics
```

---

Sample:

```json
{
  "subject": "Mathematics",
  "score_range": [7, 8],
  "must_mention": [
    "sign error",
    "working steps"
  ]
}
```

---

Now every update can be compared against known expectations.

---

# Regression Testing

Every time you change:

* prompts
* models
* personas
* rubrics

Run evaluation again.

---

Example:

```text
Version 1:
Accuracy = 95%

Version 2:
Accuracy = 89%
```

Even if outputs look better:

> The system regressed.

Without testing, you would never know.

---

# Measuring Hallucinations

AI occasionally invents information.

This is especially dangerous in grading.

---

Example:

Student writes:

```text
Newton's First Law
```

AI says:

```text
You misunderstood photosynthesis.
```

Hallucination.

---

Evaluation metric:

```text
Feedback claims supported by evidence?
```

Track:

```text
Supported
Unsupported
```

Percentage.

---

# Human-in-the-Loop Evaluation

The most reliable benchmark remains teachers.

---

Create review categories:

| Metric      | Score |
| ----------- | ----- |
| Accuracy    | 1–5   |
| Fairness    | 1–5   |
| Clarity     | 1–5   |
| Helpfulness | 1–5   |

---

Example:

```text
Teacher A

Accuracy: 5
Fairness: 4
Clarity: 5
Helpfulness: 5
```

Average across reviewers.

---

# Measuring Prompt Changes

Prompt modifications should be treated like code changes.

---

Before:

```text
Prompt Version 1
```

After:

```text
Prompt Version 2
```

Run both against:

```text
same dataset
```

Compare:

* classification accuracy
* score variance
* feedback quality
* rubric adherence

This is called:

> Prompt Benchmarking

---

# Evaluation Dashboard Metrics

As Markly grows, consider tracking:

| Metric                 | Meaning                        |
| ---------------------- | ------------------------------ |
| Subject Accuracy       | Classification correctness     |
| Average Grade Variance | Stability                      |
| Rubric Compliance      | Structured scoring reliability |
| Hallucination Rate     | Unsupported claims             |
| Feedback Length        | Response quality               |
| PDF Success Rate       | Reporting reliability          |
| Processing Time        | UX performance                 |

These metrics reveal system health.

---

# Testing the Entire Pipeline

Eventually we need end-to-end testing.

---

Input:

```text
Upload Assignment
```

Expected:

```text
Correct Subject
Correct Rubric
Valid Score
Feedback Generated
PDF Created
History Saved
```

This verifies system integration.

---

# Recommended Testing Pyramid

```text
          Human Review
               ▲
               │
       Golden Dataset Tests
               ▲
               │
      Rubric Validation Tests
               ▲
               │
    Classification Accuracy Tests
               ▲
               │
      File Processing Tests
```

Lower layers catch most failures cheaply.

Upper layers validate educational quality.

---

# The Most Important Principle

A powerful AI model is not evidence of a reliable grading system.

Reliability comes from:

* measurement
* validation
* benchmarking
* regression testing
* human review

The purpose of evaluation is not to prove the system is good.

The purpose is to detect when it becomes worse.

---

# Key Takeaway

Markly becomes trustworthy not when it can generate grades, but when it can consistently justify, reproduce, and validate those grades across time.

A grading system without evaluation is a demo.

A grading system with systematic testing is an educational platform.

