# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 28)

# Philosophy, Epistemology, and Why Error Handling Is Ultimately About the Limits of Human Knowledge

> *"The fundamental cause of trouble is that in the modern world the stupid are cocksure while the intelligent are full of doubt."*
>
> — Bertrand Russell
>
> *"All models are wrong, but some are useful."*
>
> — George Box

---

# Introduction

Consider this Python code:

```python
try:
    process_payment()
except TimeoutError:
    retry()
```

Question:

Why did the timeout occur?

Possible answers:

```text
Server overloaded
Network congestion
Packet loss
DNS failure
Database lock
Kernel bug
Cloud outage
Hardware failure
Solar flare
Unknown
```

Question:

Which answer is correct?

Answer:

```text
We don't know.
```

---

This may be the most important realization in all of engineering:

> Most failures occur because reality differs from what we believe.

This leads us into one of humanity's oldest questions:

# Epistemology

The branch of philosophy that studies:

> **What can we know?**
>
> **How do we know it?**
>
> **How do we know that we know it?**

---

# Chapter 389 — The Map Is Not The Territory

Suppose you have a map:

```text
Singapore
     |
Roads
Buildings
Stations
```

Question:

Is the map Singapore?

Answer:

```text
No.
```

---

The map is:

```text
a model
```

---

Likewise:

```python
class Customer:
    id: int
    name: str
```

Question:

Is this a customer?

Answer:

```text
No.
```

---

Visualization:

```text
Reality
    |
Model
    |
Prediction
```

---

Examples:

| Reality  | Model                |
| -------- | -------------------- |
| Weather  | Forecast             |
| Economy  | Economics            |
| Database | Schema               |
| Network  | Architecture diagram |
| User     | User persona         |

---

Lesson:

> Models are not reality.

---

# Exercise 1

List ten models you use every day.

---

# Chapter 390 — All Models Are Wrong

Consider:

```python
if payment_success:
    ship_product()
```

Question:

What assumptions exist?

---

Hidden assumptions:

```text
Payment gateway works
Network works
Database works
Clock works
User is legitimate
Inventory is correct
Business rules are correct
```

---

Visualization:

```text
Visible Logic
      |
Hidden Assumptions
```

---

Question:

Are these assumptions always true?

Answer:

```text
No.
```

---

This leads to George Box's famous observation:

> All models are wrong.
>
> Some are useful.

---

# Exercise 2

Identify hidden assumptions in your code.

---

# Chapter 391 — Unknown Unknowns

There are four kinds of knowledge.

---

## Known Knowns

```text
Things we know.
```

Example:

```python
1 + 1 == 2
```

---

## Known Unknowns

```text
Things we know we don't know.
```

Example:

```text
Will traffic spike tomorrow?
```

---

## Unknown Knowns

```text
Things we know but forget.
```

Example:

```text
tribal knowledge
```

---

## Unknown Unknowns

```text
Things we don't know exist.
```

---

Visualization:

```text
Known
   |
Unknown
   |
Unknown Unknown
```

---

Most catastrophic failures belong here.

---

Examples:

* black swan events,
* cascading failures,
* emergent behaviors,
* novel attacks.

---

# Exercise 3

Find examples of unknown unknowns.

---

# Chapter 392 — Black Swan Events

Popularized by:

Nassim Nicholas Taleb

---

Definition:

A Black Swan event is:

* unexpected,
* high impact,
* explainable only afterward.

---

Examples:

* financial crises,
* pandemics,
* cloud outages,
* major security breaches.

---

Visualization:

```text
Normal Events
       |
Rare Event
       |
Catastrophe
```

---

Question:

Can Black Swans be predicted?

Answer:

```text
Usually no.
```

---

# Exercise 4

List historical Black Swan events in technology.

---

# Chapter 393 — Induction And Prediction

Question:

If a server survived yesterday:

Will it survive tomorrow?

---

Question:

If your code worked yesterday:

Will it work tomorrow?

---

Question:

If your architecture scaled yesterday:

Will it scale tomorrow?

---

Answer:

```text
Probably.
Not certainly.
```

---

Visualization:

```text
Past
  |
Prediction
  |
Future
```

---

This is known as:

# The Problem of Induction

Introduced by:

David Hume

---

# Exercise 5

Find examples where past performance failed to predict the future.

---

# Chapter 394 — Observability Is Epistemology

Question:

Why do we build:

* logs,
* metrics,
* traces,
* dashboards?

---

Answer:

Because:

```text
we don't know what the system is doing
```

---

Visualization:

```text
Reality
    |
Observation
    |
Knowledge
```

---

Observability is fundamentally:

> the science of knowing what can be known.

---

# Exercise 6

Explain observability as a knowledge problem.

---

# Chapter 395 — Debugging Is Scientific Inquiry

Suppose:

```text
System crashed.
```

What happens next?

---

Step 1:

```text
Observe
```

---

Step 2:

```text
Hypothesize
```

---

Step 3:

```text
Experiment
```

---

Step 4:

```text
Update belief
```

---

Visualization:

```text
Observation
      |
Hypothesis
      |
Experiment
      |
Knowledge
```

---

Question:

What discipline uses this process?

Answer:

```text
Science
```

---

Therefore:

> Debugging is applied science.

---

# Exercise 7

Map debugging to the scientific method.

---

# Chapter 396 — Bayesian Knowledge

Suppose:

Initial belief:

```text
Database failure = 80%
```

---

New evidence:

```text
Database healthy
```

---

Updated belief:

```text
Database failure = 5%
```

---

Visualization:

```text
Belief
    |
Evidence
    |
Knowledge
```

---

This is:

# Bayesian Epistemology

---

Question:

What do engineers actually do?

Answer:

```text
update beliefs
```

---

# Exercise 8

Perform Bayesian reasoning during an outage.

---

# Chapter 397 — Gödel And Incompleteness

One of the deepest discoveries in mathematics.

Proven by:

Kurt Gödel

---

Simplified:

> Some truths cannot be proven within a system.

---

Question:

What does this imply for software?

---

Answer:

```text
Some failures
cannot be predicted
from inside the system.
```

---

Visualization:

```text
System
   |
Questions
   |
Unanswerable Questions
```

---

Lesson:

> Complete certainty is impossible.

---

# Exercise 9

Find engineering problems that cannot be fully proven.

---

# Chapter 398 — The Observer Effect

Question:

Can observing a system change it?

Answer:

```text
Yes.
```

---

Examples:

```text
Logging slows systems.
Tracing changes timing.
Debuggers alter execution.
Monitoring consumes resources.
```

---

Visualization:

```text
Observe
    |
Change System
    |
Observe Different System
```

---

Examples exist in:

* quantum mechanics,
* distributed systems,
* performance engineering.

---

# Exercise 10

Find examples of observer effects.

---

# Chapter 399 — Humility As An Engineering Principle

Question:

What distinguishes junior engineers from senior engineers?

Often:

### Junior engineer:

```text
I know what happened.
```

---

### Senior engineer:

```text
I think this happened.
I might be wrong.
Let's verify.
```

---

Visualization:

```text
Confidence
      |
Humility
      |
Investigation
```

---

Lesson:

> Expertise often increases uncertainty awareness.

---

# Exercise 11

Identify situations where overconfidence caused failures.

---

# Chapter 400 — Error Handling Is Epistemology

At the beginning:

```python
try:
    dangerous()
except:
    recover()
```

appeared to mean:

```text
handle error
```

---

Now we understand:

```text
Reality
     |
Observation
     |
Inference
     |
Belief
     |
Decision
     |
Action
```

---

This is:

# Epistemology

---

# The Knowledge Engineering Model

```text
Reality
    |
Observation
    |
Model
    |
Prediction
    |
Action
```

---

# The Reliability Knowledge Model

```text
Failure
    |
Observation
    |
Hypothesis
    |
Experiment
    |
Knowledge
```

---

# The Most Important Diagram In Engineering Philosophy

```text
Reality
    |
Observation
    |
Belief
    |
Decision
    |
Action
    |
Outcome
    |
Learning
    |
Updated Belief
```

---

# Summary

In this article we learned:

✅ epistemology
✅ models and reality
✅ hidden assumptions
✅ unknown unknowns
✅ Black Swan events
✅ induction
✅ observability
✅ debugging as science
✅ Bayesian reasoning
✅ incompleteness
✅ observer effects
✅ intellectual humility

---

# Conclusion

At the beginning of this series, we thought:

```python
try:
    dangerous()
except:
    recover()
```

was simply a language feature in Python.

After exploring:

* operating systems,
* distributed systems,
* cybernetics,
* evolution,
* economics,
* game theory,
* decision theory,
* philosophy,

we arrive at perhaps the deepest realization of all:

> **Software failures are not fundamentally failures of computation.**

They are:

> **failures of human understanding.**

Because every system we build exists in the gap between:

```text
Reality
    and
Our beliefs about reality
```

And error handling itself is nothing more—and nothing less—than our attempt to survive that gap.

Perhaps that is why the greatest engineers are rarely those who claim certainty.

They are the ones who understand, deeply and permanently:

> **"I may be wrong."** 🚨
