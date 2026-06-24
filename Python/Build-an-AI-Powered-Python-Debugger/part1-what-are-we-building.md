# Part 1 — What Are We Building?

Before writing any code, we need to understand our destination.

Many beginners make the mistake of immediately opening a code editor and typing random code.

Professional engineers do the opposite.

They start by answering a simple question:

> What problem are we trying to solve?

---

## The Problem

Imagine you are learning Python.

You write this program:

```python
numbers = [1, 2, 3]

print(numbers[10])
```

When you run it, Python crashes.

You see:

```text
IndexError: list index out of range
```

If you've never seen this error before, the message may not be very useful.

Questions immediately appear:

* What is an IndexError?
* What is an index?
* Why is Python angry?
* How do I fix it?

A beginner often spends more time understanding the error than fixing it.

---

## What If We Had A Programming Tutor?

Imagine sitting next to an experienced software engineer.

You show them the code.

Instead of saying:

```text
IndexError
```

they explain:

```text
Your list contains only three items.

Python starts counting from zero.

The valid positions are:

0
1
2

You are asking for item number 10,
which does not exist.
```

That explanation is much easier to understand.

---

## Our Goal

We want to build software that behaves like that tutor.

The user pastes code:

```python
numbers = [1, 2, 3]

print(numbers[10])
```

Our application sends the code to an AI.

The AI analyzes the code.

The AI returns a helpful explanation.

The user learns what went wrong.

---

## The Complete Vision

Eventually our system will be able to:

### Analyze Python Code

```text
User Pastes Code
       ↓
AI Explains Bugs
```

---

### Answer Questions

```text
User:
Why is line 5 failing?

AI:
Explanation...
```

---

### Generate Diagrams

```text
Source Code
      ↓
Architecture Diagram
```

---

### Produce Reports

```text
Analysis
    ↓
PDF Report
```

---

### Create Engineering Notes

```text
Code Review
      ↓
Formal Documentation
```

---

## The Finished System

At the end of this tutorial, the architecture will look something like this:

```text
┌─────────────────────┐
│      Browser        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│         UI          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Conversation      │
│      Memory         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│     AI Gateway      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│      LLM API        │
└──────────┬──────────┘
           │
           ▼
      AI Response
```

Don't worry if most of this looks unfamiliar.

By the end of the tutorial every box will make sense.

---

## How This Tutorial Is Different

Many tutorials do this:

```text
Copy this code.

Paste it here.

Run this command.
```

The code works.

But the reader learns very little.

Our approach will be different.

For every concept we will answer:

### What is it?

Example:

```text
What is an API?
```

---

### Why do we need it?

Example:

```text
Why can't our application talk
directly to ChatGPT?
```

---

### How does it work?

Example:

```text
What actually happens when
we send a request?
```

---

### Then we write code.

Only after understanding the concept.

---

## What You Need To Know Before Starting

The good news:

You do **not** need:

* AI experience
* Web development experience
* Architecture experience
* Docker experience

You only need:

* Basic Python
* Curiosity
* Patience

Everything else will be explained from first principles.

---

## What We'll Learn Along The Way

Even though we're building an AI debugger, you'll also learn:

### Software Architecture

How large applications are organized.

---

### Design Patterns

Reusable solutions to common engineering problems.

---

### Event-Driven Programming

How buttons and web applications work.

---

### State Management

How applications remember information.

---

### API Communication

How software talks to external services.

---

### Deployment

How applications move from your laptop to the cloud.

---

## What Happens Next?

Before we can build the debugger, we need to understand something fundamental:

> How does software actually communicate with an AI model?

That is exactly what we'll explore in **Part 2 — Understanding Large Language Models (LLMs)**.

There we'll answer:

* What is an LLM?
* How does ChatGPT work from a software perspective?
* What is a prompt?
* What is a response?
* How does our application communicate with an AI?

Only after understanding those ideas will we write our first line of code.
