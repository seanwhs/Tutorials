# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 27)

# Decision Theory, Rationality, Uncertainty, and Why Error Handling Is Ultimately About Making Decisions Under Incomplete Information

> *"Every exception handler is a decision."
>
> "Every engineering action is a bet on the future."*

---

# Introduction

Consider this Python code:

```python
try:
    payment()
except TimeoutError:
    retry()
```

Question:

Is retrying the correct decision?

Answer:

```text
Nobody knows.
```

---

Because at the moment of failure:

You don't know:

* whether the server crashed,
* whether the network dropped the packet,
* whether the payment succeeded,
* whether the payment failed,
* whether the customer will retry,
* whether retrying will make things worse.

---

Visualization:

```text
Reality
   |
Unknown
   |
Decision
   |
Outcome
```

---

This reveals perhaps the deepest truth in software engineering:

> Engineering is not programming.

It is:

> **decision-making under uncertainty.**

Welcome to:

# Decision Theory

The mathematical science of:

> **how rational agents should make decisions when they don't know what is true.**

---

# Chapter 375 — What Is A Decision?

A decision requires:

* possible actions,
* uncertain outcomes,
* preferences,
* consequences.

---

Example:

```python
except TimeoutError:
    ???
```

Possible actions:

```text
retry
fail
fallback
wait
escalate
```

---

Visualization:

```text
Situation
     |
Possible Actions
     |
Possible Outcomes
     |
Decision
```

---

Examples in software:

* retry or fail,
* cache or database,
* consistency or availability,
* deploy or rollback,
* alert or suppress.

---

# Exercise 1

List ten engineering decisions you make every day.

---

# Chapter 376 — Decisions Under Certainty

Suppose:

```text
2 + 2 = ?
```

Answer:

```text
4
```

---

No uncertainty.

---

Example:

```python
if x == 0:
    raise ValueError()
```

---

Visualization:

```text
Known World
      |
Optimal Action
```

---

Most beginner programming assumes:

```text
certainty
```

---

Reality contains:

```text
almost none
```

---

# Exercise 2

Find examples of deterministic decisions.

---

# Chapter 377 — Decisions Under Uncertainty

Suppose:

```text
Request timed out.
```

Possible realities:

| Reality           | Probability |
| ----------------- | ----------- |
| Network failure   | 40%         |
| Server overloaded | 30%         |
| Packet loss       | 20%         |
| Bug               | 10%         |

---

Question:

What should you do?

Answer:

```text
choose without certainty
```

---

Visualization:

```text
Unknown State
      |
Estimate
      |
Decision
```

---

This is the default state of distributed systems.

---

# Exercise 3

List uncertain decisions in cloud systems.

---

# Chapter 378 — Expected Value

Suppose:

### Retry

Success probability:

```text
80%
```

Cost:

```text
100 ms
```

---

### Fail

Success probability:

```text
0%
```

Cost:

```text
0 ms
```

---

Question:

Which is better?

Answer:

Calculate:

```text
Expected Value
```

---

Formula:

```text
Expected Value
=
Probability × Outcome
```

---

Visualization:

```text
Probability
      |
Outcome
      |
Expected Value
```

---

Examples:

* retries,
* caching,
* autoscaling,
* deployments.

---

# Exercise 4

Calculate expected values for retry policies.

---

# Chapter 379 — Risk

Suppose:

Strategy A:

```text
99% success
1% catastrophe
```

---

Strategy B:

```text
95% success
0% catastrophe
```

---

Question:

Which is better?

Answer:

```text
depends
```

---

Visualization:

```text
Expected Value
         |
Risk
         |
Decision
```

---

Examples:

* financial systems,
* aerospace,
* medical systems,
* distributed databases.

---

Lesson:

> High expected value does not imply low risk.

---

# Exercise 5

Find examples of high-risk engineering decisions.

---

# Chapter 380 — Utility Functions

Question:

What is:

```text
success?
```

---

Answer:

It depends on:

```text
what you value
```

---

Examples:

### Bank

Values:

```text
correctness
```

---

### Social media

Values:

```text
availability
```

---

### Hospital

Values:

```text
safety
```

---

Visualization:

```text
Goals
    |
Utility
    |
Decision
```

---

This is called:

# Utility Theory

---

# Exercise 6

Define utility functions for:

* banking,
* gaming,
* healthcare,
* e-commerce.

---

# Chapter 381 — Bounded Rationality

Economists once assumed:

```text
Humans are rational.
```

---

Reality:

```text
Humans are tired.
Humans are stressed.
Humans are overloaded.
Humans are wrong.
```

---

Visualization:

```text
Perfect Decision

↓

Human Decision
```

---

Examples:

* incident response,
* debugging,
* architecture decisions,
* postmortems.

---

Concept introduced by:

Herbert A. Simon

---

# Exercise 7

Find examples of bounded rationality in engineering.

---

# Chapter 382 — Heuristics

Question:

How do humans make decisions?

Usually:

```text
rules of thumb
```

---

Examples:

```text
If CPU > 80%, scale.
If errors > 5%, rollback.
If database fails, failover.
```

---

Visualization:

```text
Complex Reality
       |
Simplification
       |
Decision
```

---

Heuristics are:

```text
fast
cheap
imperfect
```

---

# Exercise 8

List engineering heuristics you use.

---

# Chapter 383 — Decision Trees

Suppose:

```text
Timeout
```

Possible actions:

```text
Retry
Fallback
Abort
Escalate
```

---

Visualization:

```text
Timeout
   |
   +-- Retry
   |
   +-- Fallback
   |
   +-- Abort
   |
   +-- Escalate
```

---

Decision trees appear everywhere:

* exception handling,
* incident response,
* runbooks,
* diagnosis.

---

# Exercise 9

Create a decision tree for payment failures.

---

# Chapter 384 — Bayesian Decision Making

Suppose:

```text
Server down.
```

Initial belief:

```text
Database failure = 50%
```

---

New evidence:

```text
Database healthy.
```

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
Updated Belief
```

---

This is:

# Bayesian inference

---

Examples:

* debugging,
* monitoring,
* anomaly detection,
* incident response.

---

# Exercise 10

Perform Bayesian analysis on an outage.

---

# Chapter 385 — Exploration vs Exploitation

Question:

Should we:

```text
Use what works?
```

or:

```text
Try something new?
```

---

Examples:

* deployments,
* A/B testing,
* machine learning,
* architecture.

---

Visualization:

```text
Known Strategy
        |
Unknown Strategy
        |
Tradeoff
```

---

This is called:

# The Multi-Armed Bandit Problem

---

Examples:

* recommendation systems,
* canary deployments,
* feature flags.

---

# Exercise 11

Explain canary releases as exploration.

---

# Chapter 386 — Regret Minimization

Question:

How do we know if a decision was good?

Answer:

We compare:

```text
what happened
```

against:

```text
what could have happened
```

---

Visualization:

```text
Actual Outcome
       |
Optimal Outcome
       |
Regret
```

---

Examples:

* incident reviews,
* architecture reviews,
* postmortems.

---

Question:

What are postmortems?

Answer:

```text
regret analysis
```

---

# Exercise 12

Calculate regret for engineering decisions.

---

# Chapter 387 — The OODA Loop Revisited

Recall:

```text
Observe
Orient
Decide
Act
```

---

Visualization:

```text
Observe
    |
Orient
    |
Decide
    |
Act
```

---

This loop is fundamentally:

> a decision-making engine.

---

Examples:

* debugging,
* SRE,
* incident response,
* observability.

---

# Exercise 13

Map the OODA loop to software debugging.

---

# Chapter 388 — Error Handling Is Decision Theory

At the beginning:

```python
try:
    dangerous()
except:
    recover()
```

appeared to mean:

```text
handle failure
```

---

Now we understand:

```text
Observe
     |
Infer
     |
Estimate
     |
Decide
     |
Act
```

---

This is:

# Decision Theory

---

# The Decision Engineering Model

```text
Uncertainty
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
```

---

# The Reliability Decision Model

```text
Failure
     |
Evidence
     |
Inference
     |
Decision
     |
Recovery
     |
Learning
```

---

# The Most Important Diagram In Decision Engineering

```text
Reality
     |
Uncertainty
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
```

---

# Summary

In this article we learned:

✅ decision theory
✅ uncertainty
✅ expected value
✅ risk
✅ utility theory
✅ bounded rationality
✅ heuristics
✅ decision trees
✅ Bayesian reasoning
✅ exploration vs exploitation
✅ regret minimization
✅ OODA loops
✅ engineering decisions

---

# Conclusion

At the start of this series, we thought:

```python
try:
    dangerous()
except:
    recover()
```

was a piece of Python syntax.

After exploring:

* operating systems,
* distributed systems,
* information theory,
* control theory,
* cybernetics,
* evolution,
* economics,
* game theory,
* decision theory,

we arrive at perhaps the deepest lesson yet:

> **Every exception handler is a decision policy.**

And every software system is ultimately:

> **a machine for making decisions under uncertainty.**

Which means that software engineering is not fundamentally about writing code.

It is about:

> **deciding what to do when you don't know what is happening, cannot predict the future, and must act anyway.** 🚨
