# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 19)

# Human Factors, Cognitive Biases, Organizational Failure, and Why Systems Ultimately Fail Because Humans Build Them

> *"Every system is perfectly designed to produce the results it produces."*
>
> — often attributed to systems thinking practitioners

---

# Introduction

Suppose you investigate a major outage.

You discover:

```text
Engineer deployed bad code.
```

Case closed?

Not quite.

Because the next question is:

> Why did the engineer deploy bad code?

Answer:

```text
They were tired.
```

Why?

```text
They were on-call for 14 hours.
```

Why?

```text
The team was understaffed.
```

Why?

```text
Management delayed hiring.
```

Why?

```text
The company optimized for growth over reliability.
```

Suddenly:

```text
Engineer error
```

became:

```text
organizational design
```

This is one of the deepest discoveries in modern reliability engineering:

> **Most failures are human.**
>
> But very few failures are caused by individual humans.

Welcome to:

# Human Factors Engineering

---

# Chapter 260 — The Person Model vs The Systems Model

Traditional thinking:

```text
System failed
      |
Human made mistake
      |
Punish human
```

---

Modern reliability thinking:

```text
System failed
      |
Why was the mistake possible?
      |
Improve system
```

---

Visualization:

```text
PERSON MODEL

Failure
   |
Human
```

versus

```text
SYSTEM MODEL

Failure
   |
System Design
   |
Human Action
```

---

Example:

```bash
rm -rf production
```

Question:

Who failed?

```text
Engineer?
```

Or:

```text
The organization that allowed
production deletion?
```

---

# Exercise 1

List five mistakes that should be impossible to make.

---

# Chapter 261 — Human Error Is Normal

Question:

Do humans make mistakes?

Answer:

```text
Always.
```

Examples:

* typing errors,
* forgetting steps,
* misunderstanding documentation,
* fatigue,
* stress,
* distraction.

---

Visualization:

```text
Human
   |
Mistake
```

This is not:

```text
abnormal
```

This is:

```text
human
```

---

Professional engineering assumes:

```text
humans will fail
```

and designs around it.

---

# Exercise 2

List recent mistakes you've made that software safeguards could have prevented.

---

# Chapter 262 — The Swiss Cheese Model Revisited

Imagine:

```text
Training
     |
Documentation
     |
Code Review
     |
Testing
     |
Monitoring
     |
Incident Response
```

Each layer has holes.

---

Visualization:

```text
| O |
|  O|
|O  |
| O |
```

Normally:

```text
holes don't align
```

But sometimes:

```text
everything aligns
```

↓

```text
OUTAGE
```

---

Lesson:

> Catastrophes require multiple simultaneous failures.

---

# Exercise 3

Analyze a famous outage using Swiss Cheese theory.

---

# Chapter 263 — Cognitive Bias

Humans don't observe reality objectively.

They use shortcuts.

These shortcuts are called:

# Cognitive Biases

---

Examples:

* confirmation bias,
* hindsight bias,
* anchoring bias,
* survivorship bias,
* authority bias.

---

Visualization:

```text
Reality
   |
Brain
   |
Interpretation
```

---

# Exercise 4

Find examples of cognitive bias in software debugging.

---

# Chapter 264 — Confirmation Bias

Suppose:

```text
Deploy
   |
Outage
```

Engineer concludes:

```text
Deployment caused outage.
```

Then:

* ignores other evidence,
* searches for confirming evidence,
* stops investigating.

---

Visualization:

```text
Hypothesis
      |
Evidence Selection
      |
Confirmation
```

---

Question:

Was the deployment actually responsible?

Maybe.

Maybe not.

---

# Exercise 5

Describe a debugging session where you assumed the wrong cause.

---

# Chapter 265 — Hindsight Bias

After incidents, engineers often say:

> We should have known.

Reality:

```text
Before incident:
uncertainty

After incident:
certainty illusion
```

---

Visualization:

```text
Before:
???

After:
OBVIOUS
```

---

The danger:

```text
unfair blame
```

---

# Exercise 6

Explain why hindsight makes postmortems difficult.

---

# Chapter 266 — Authority Bias

Example:

```text
Senior Engineer says:

"The database caused it."
```

Everyone stops thinking.

---

Visualization:

```text
Authority
     |
Belief
     |
No Challenge
```

---

Question:

Was the senior engineer correct?

Sometimes.

But authority is not evidence.

---

# Exercise 7

Describe situations where hierarchy harms debugging.

---

# Chapter 267 — Normalization of Deviance

Suppose:

```text
Minor failure
```

Nothing happens.

Next day:

```text
Minor failure
```

Nothing happens.

After months:

```text
Unsafe behavior
```

becomes:

```text
normal behavior
```

---

Visualization:

```text
Unsafe
    |
Repeated
    |
Accepted
```

---

Examples:

* ignored alerts,
* skipped tests,
* manual production fixes,
* undocumented procedures.

---

This phenomenon contributed to disasters such as:

* Space Shuttle Challenger disaster
* Space Shuttle Columbia disaster

---

# Exercise 8

Identify normalized deviance in software teams.

---

# Chapter 268 — Work-As-Imagined vs Work-As-Done

Management believes:

```text
Procedure
    |
Execution
```

Reality:

```text
Procedure
    |
Workarounds
    |
Shortcuts
    |
Adaptations
    |
Reality
```

---

Visualization:

```text
Documentation

↓

Ideal World

↓

Actual World
```

---

Question:

Which one keeps production running?

Answer:

```text
Actual work.
```

---

# Exercise 9

List workarounds that exist in your workflow.

---

# Chapter 269 — Local Rationality

Question:

Why did the engineer make the mistake?

Answer:

Because at that moment:

> It seemed like the correct decision.

---

Example:

```text
Server overloaded.

Engineer:

Restart server.
```

Unknown to them:

```text
Restart causes cluster collapse.
```

---

Visualization:

```text
Information Available
        |
Decision
        |
Outcome
```

---

Lesson:

People optimize based on:

```text
their knowledge
```

not:

```text
perfect knowledge
```

---

# Exercise 10

Explain a bad decision that was rational at the time.

---

# Chapter 270 — Burnout Creates Failures

Question:

Which causes more outages?

```text
Bad code?
```

or:

```text
Exhausted engineers?
```

---

Research increasingly suggests:

```text
human fatigue
```

is a major contributor.

---

Effects:

* slower reasoning,
* poorer decisions,
* tunnel vision,
* missed alerts,
* emotional reactions.

---

Visualization:

```text
Fatigue
    |
Mistakes
    |
Failures
```

---

# Exercise 11

Design an on-call schedule that minimizes burnout.

---

# Chapter 271 — Psychological Safety

Question:

Can engineers admit mistakes?

If:

```text
YES
```

↓

```text
learning
```

If:

```text
NO
```

↓

```text
hiding
```

---

Visualization:

```text
Safety
    |
Reporting
    |
Learning
```

---

Organizations with psychological safety:

* detect failures earlier,
* share information faster,
* recover quicker.

---

# Exercise 12

How can teams encourage psychological safety?

---

# Chapter 272 — High Reliability Organizations (HROs)

Examples:

* aircraft carriers,
* air traffic control,
* nuclear power plants,
* emergency medicine.

---

Characteristics:

### Preoccupation with failure

```text
What could go wrong?
```

---

### Reluctance to simplify

```text
Reality is complicated.
```

---

### Sensitivity to operations

```text
Watch production closely.
```

---

### Commitment to resilience

```text
Recover rapidly.
```

---

### Deference to expertise

```text
Listen to knowledge,
not hierarchy.
```

---

# Exercise 13

Evaluate your organization using HRO principles.

---

# Chapter 273 — Organizations Are Systems Too

We often model:

```text
Software System
```

But ignore:

```text
Human System
```

Examples:

```text
Management
Teams
Communication
Budgets
Culture
Policies
Incentives
```

---

Visualization:

```text
Organization
       |
Software
       |
Failures
```

---

This leads to:

> Conway's Law.

---

# Chapter 274 — Conway's Law

Formulated by:

Melvin Conway

---

The law:

> Organizations design systems that mirror their communication structures.

---

Example:

```text
4 teams
```

↓

```text
4 microservices
```

---

Visualization:

```text
Org Chart
    |
Architecture
```

---

Question:

Why is architecture hard?

Answer:

Because:

```text
architecture
=
organizational structure
```

---

# Exercise 14

Map your organization's structure to its architecture.

---

# Chapter 275 — The Human Reliability Loop

```text
Human
    |
Decision
    |
System
    |
Failure
    |
Investigation
    |
Learning
    |
Adaptation
```

---

# The Human Factors Model

```text
Failure
    |
Human Action
    |
Context
    |
Organization
    |
System Design
```

---

# The Most Important Diagram In Reliability Engineering

```text
Technology
      |
Humans
      |
Organizations
      |
Culture
      |
Failures
      |
Learning
      |
Resilience
```

---

# Summary

In this article we learned:

✅ person model vs systems model
✅ human error theory
✅ cognitive bias
✅ confirmation bias
✅ hindsight bias
✅ authority bias
✅ normalization of deviance
✅ work-as-imagined vs work-as-done
✅ local rationality
✅ burnout
✅ psychological safety
✅ high reliability organizations
✅ Conway's Law
✅ organizational systems

---

# Conclusion

At the beginning of this series, we thought error handling meant:

```python
try:
    dangerous()
except:
    recover()
```

But after studying reliability, distributed systems, observability, and human factors, we discover a deeper truth:

> **Software failures are not merely technical failures.**

They are:

* human failures,
* organizational failures,
* communication failures,
* knowledge failures,
* and sometimes,
* failures of imagination.

And perhaps the most important lesson in all of engineering is:

> **Humans are not the problem to be eliminated.**

They are:

> **the adaptive component that makes complex systems survivable.** 🚨
