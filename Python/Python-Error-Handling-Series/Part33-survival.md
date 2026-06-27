# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 33)

# Control Theory, Feedback, Stability, and Why Error Handling Is Actually About Keeping Systems Alive

> *"The purpose of a system is what it does."*
>
> — Stafford Beer
>
> *"Control is not about preventing errors. Control is about surviving them."*

---

# Introduction

Consider this Python code:

```python
try:
    process_request()
except TimeoutError:
    retry()
```

Question:

What is this code doing?

Most programmers answer:

```text
handling exceptions
```

But suppose we zoom out.

What is a thermostat doing?

```text
Measure temperature
        |
Compare target
        |
Adjust heating
```

What is cruise control doing?

```text
Measure speed
       |
Compare target
       |
Adjust throttle
```

What is Kubernetes doing?

```text
Measure replicas
       |
Compare target
       |
Create pods
```

What is exception handling doing?

```text
Measure failure
       |
Compare expectation
       |
Adjust behavior
```

---

Suddenly we realize:

> Error handling is not about errors.

It is about:

> **control.**

Welcome to:

# Control Theory

The science of:

> **how systems maintain stability in the presence of disturbance.**

---

# Chapter 449 — What Is A Control System?

A control system contains:

* a system,
* a measurement,
* a goal,
* a controller,
* an actuator,
* feedback.

---

Example:

### Air conditioner

```text
Room Temperature
        |
     Sensor
        |
   Controller
        |
    Aircon
        |
 Room Temperature
```

---

Example:

### Python retry

```python
try:
    api_call()
except TimeoutError:
    retry()
```

Actually means:

```text
Request
   |
Failure
   |
Observe
   |
Adjust
   |
Retry
```

---

Visualization:

```text
Observe
    |
Compare
    |
Act
    |
Observe
```

---

# Exercise 1

Identify ten control systems you use every day.

---

# Chapter 450 — Open Loop Systems

Suppose:

```python
send_email()
```

No checking.

No confirmation.

No feedback.

---

Visualization:

```text
Input
   |
Action
   |
Hope
```

---

Examples:

* batch jobs,
* cron jobs,
* fire-and-forget messaging,
* UDP.

---

Question:

What happens if reality changes?

Answer:

```text
failure
```

---

Open-loop systems are:

```text
simple
fast
fragile
```

---

# Exercise 2

Find examples of open-loop software.

---

# Chapter 451 — Closed Loop Systems

Suppose:

```python
while not success:
    retry()
```

Now we have:

```text
Observe
    |
Act
    |
Observe
```

---

Visualization:

```text
      +---------+
      |         |
      V         |
Observe -> Act
```

---

Examples:

* TCP,
* retries,
* autoscaling,
* Kubernetes,
* thermostats.

---

Properties:

```text
adaptive
stable
resilient
```

---

# Exercise 3

Identify closed-loop systems in your architecture.

---

# Chapter 452 — Feedback Revisited

Recall:

```text
Output
   |
Input
```

---

Two kinds exist.

---

## Positive Feedback

Example:

```text
Timeout
   |
Retry
   |
Load
   |
More timeout
```

---

Visualization:

```text
+
+
+
+
+
+
BOOM
```

---

Examples:

* retry storms,
* bank runs,
* panic selling,
* congestion collapse.

---

## Negative Feedback

Example:

```text
Timeout
   |
Backoff
   |
Reduced load
   |
Recovery
```

---

Visualization:

```text
Oscillation
     |
Stability
```

---

Lesson:

> Stability requires negative feedback.

---

# Exercise 4

Find positive and negative feedback loops in your systems.

---

# Chapter 453 — Setpoints

Question:

How do we know whether a system is healthy?

Answer:

```text
desired state
```

---

Examples:

### Thermostat

```text
22°C
```

---

### Kubernetes

```yaml
replicas: 5
```

---

### SRE

```text
99.99% uptime
```

---

### Database

```text
CPU < 70%
```

---

Visualization:

```text
Desired State
       |
Actual State
       |
Difference
```

---

Question:

What is an error?

Answer:

```text
difference from desired state
```

---

# Exercise 5

Identify the setpoints in your systems.

---

# Chapter 454 — Error Signals

Suppose:

Desired:

```text
100 requests/sec
```

Actual:

```text
80 requests/sec
```

---

Error:

```text
20 requests/sec
```

---

Visualization:

```text
Target
   |
Reality
   |
Difference
```

---

Examples:

* latency SLOs,
* availability SLOs,
* autoscaling targets,
* queue lengths.

---

Question:

What is monitoring?

Answer:

```text
measuring error signals
```

---

# Exercise 6

Define error signals for your services.

---

# Chapter 455 — Oscillation

Suppose autoscaling does:

```text
CPU > 80%
     |
Add 100 servers
```

---

Then:

```text
CPU < 20%
     |
Remove 100 servers
```

---

Result:

```text
up
down
up
down
up
down
```

---

Visualization:

```text
/\ /\ /\ /\ /\
```

---

Examples:

* autoscaling,
* markets,
* organizations,
* retry loops.

---

Question:

Why do systems oscillate?

Answer:

```text
feedback too aggressive
```

---

# Exercise 7

Find oscillating systems in production.

---

# Chapter 456 — Stability

Question:

When is a system stable?

---

If disturbance:

```text
increases
```

causes:

```text
return to equilibrium
```

---

Visualization:

```text
Push
 |
Recovery
```

---

Examples:

* TCP congestion control,
* circuit breakers,
* exponential backoff,
* caching.

---

Unstable:

```text
Push
 |
Explosion
```

---

Examples:

* retry storms,
* cascading failures,
* flash crashes.

---

# Exercise 8

Classify your systems as stable or unstable.

---

# Chapter 457 — Delays Destroy Stability

Suppose:

```text
Measure load
```

Wait:

```text
5 minutes
```

Then:

```text
scale up
```

---

Question:

What happens?

Answer:

```text
probably disaster
```

---

Visualization:

```text
Observe
    |
Delay
    |
Action
    |
Wrong Reality
```

---

Examples:

* cloud autoscaling,
* incident response,
* human organizations,
* economic policy.

---

Lesson:

> Delayed feedback destabilizes systems.

---

# Exercise 9

Identify delayed feedback loops.

---

# Chapter 458 — Overcorrection

Suppose:

```python
except TimeoutError:
    for _ in range(1000):
        retry()
```

Question:

What happens?

Answer:

```text
catastrophe
```

---

Visualization:

```text
Small Error
      |
Huge Correction
      |
Larger Error
```

---

Examples:

* retry storms,
* over-alerting,
* aggressive autoscaling,
* financial bubbles.

---

Lesson:

> Controllers can become the cause of failure.

---

# Exercise 10

Find examples of overcorrection.

---

# Chapter 459 — Homeostasis

Biology discovered that organisms survive using:

# Homeostasis

Examples:

```text
body temperature
blood sugar
oxygen levels
heart rate
```

---

Visualization:

```text
Disturbance
      |
Correction
      |
Survival
```

---

Question:

What is a resilient software system?

Answer:

```text
a digital organism maintaining homeostasis
```

---

Examples:

* autoscaling,
* circuit breakers,
* retries,
* failover,
* load balancing.

---

# Exercise 11

Map biological homeostasis to software systems.

---

# Chapter 460 — Cybernetics Revisited

Recall:

> Cybernetics is the science of control and communication.

---

Every resilient system performs:

```text
Observe
    |
Compare
    |
Act
    |
Learn
```

---

Visualization:

```text
Observe
    |
Compare
    |
Act
    |
Learn
    |
Observe
```

---

Examples:

* humans,
* companies,
* AI systems,
* operating systems,
* distributed systems.

---

Question:

What is software?

Answer:

```text
a control system
```

---

# Exercise 12

Describe your software stack as a cybernetic controller.

---

# Chapter 461 — Error Handling Is Control Theory

At the beginning:

```python
try:
    dangerous()
except:
    recover()
```

appeared to mean:

```text
handle exceptions
```

---

Now we understand:

```text
Observe
    |
Measure Error
    |
Compute Response
    |
Act
    |
Observe Again
```

---

This is:

# Control Theory

---

# The Control Engineering Model

```text
Goal
   |
Measurement
   |
Error
   |
Controller
   |
Action
   |
Feedback
```

---

# The Reliability Control Model

```text
Failure
    |
Observation
    |
Diagnosis
    |
Recovery
    |
Observation
    |
Learning
```

---

# The Most Important Diagram In Reliability Engineering

```text
Reality
    |
Observe
    |
Compare
    |
Error Signal
    |
Control Action
    |
System Change
    |
Observe
```

---

# Summary

In this article we learned:

✅ control systems
✅ open-loop systems
✅ closed-loop systems
✅ feedback
✅ positive feedback
✅ negative feedback
✅ setpoints
✅ error signals
✅ oscillation
✅ stability
✅ delays
✅ overcorrection
✅ homeostasis
✅ cybernetics

---

# Conclusion

At the beginning of this series, we thought:

```python
try:
    dangerous()
except:
    recover()
```

was a way to catch exceptions.

After exploring:

* operating systems,
* distributed systems,
* complexity,
* information theory,
* thermodynamics,
* systems thinking,
* decision theory,
* philosophy,
* cybernetics,
* control theory,

we arrive at another profound realization:

> **Errors are not things to eliminate.**

They are:

> **signals used to control systems.**

Which means that software engineering is not fundamentally about writing programs.

It is:

> **the science of building stable control systems that can survive an unstable world.**

And perhaps that is why the ultimate purpose of error handling is not:

> **to prevent failure,**

but rather:

> **to keep the system alive long enough to recover from it.** 🚨
