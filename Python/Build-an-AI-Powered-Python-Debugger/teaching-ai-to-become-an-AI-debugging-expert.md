# Part 6 — Turning the AI into a Python Debugging Expert (System Prompts)

Right now, our AI is working, but it’s still *generic*.

If you ask:

```python
Explain Python
```

it responds like a general tutor.

But our goal is different:

> We are building a **Python debugging assistant**, not a chatbot.

So we need to control *how the AI behaves*.

This is where system prompts come in.

---

# What Problem Are We Solving?

Right now, our function does this:

```text id="p0k2mm"
User Question
     ↓
AI Answer (generic)
```

But we want:

```text id="m3xq9a"
Python Code
     ↓
AI Debugger Response
     ↓
Bug explanation + fixes + reasoning
```

Same AI.

Different behavior.

---

# What Is a System Prompt?

A system prompt is:

> A hidden instruction that defines the AI’s role and behavior.

Think of it like assigning a job title.

---

## Example

```text id="xk2p9v"
You are a helpful assistant.
```

vs

```text id="q8m1ld"
You are a senior Python debugging expert.
You explain bugs clearly, step by step.
You never give vague answers.
You focus on correctness and clarity.
```

Same model.

Completely different personality.

---

# Why System Prompts Matter

Without system instructions:

```text id="a2m9xx"
AI = General Knowledge Assistant
```

With system instructions:

```text id="k9d1pp"
AI = Specialized Tool
```

We are not “changing the model”.

We are *guiding its behavior*.

---

# Where System Prompts Fit in the Message Flow

Remember our message structure:

```text id="w1c9zz"
messages = [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."}
]
```

Now we introduce a third role:

```text id="r8k2aa"
system
```

---

# The Three Roles (Again, But Properly Understood)

## 1. System

> Defines behavior

```text id="s1p0aa"
You are a Python debugging expert.
```

---

## 2. User

> The actual request

```text id="u8m3bb"
Why is my code crashing?
```

---

## 3. Assistant

> AI’s response (generated later)

```text id="a9k2cc"
Your code fails because...
```

---

# Updating Our llm_client.py

Now we modify our function.

Go to:

```text id="c2m9dd"
llm_client.py
```

---

## Step 1 — Create a System Prompt

Add this at the top:

```python
SYSTEM_PROMPT = """
You are a senior Python debugging expert.

Your job is to:
- Identify bugs in Python code
- Explain why they happen in simple terms
- Provide corrected code
- Suggest improvements

Always structure your response clearly:
1. Problem
2. Explanation
3. Fix
4. Best practices
"""
```

---

# Why This Works

We are essentially telling the AI:

```text id="y2p9ee"
How to think
How to respond
How to format output
```

This is extremely powerful.

---

# Step 2 — Inject System Prompt Into Messages

Now update your function:

```python
def generate_text(messages):
    full_messages = [
        {
            "role": "system",
            "content": SYSTEM_PROMPT
        }
    ] + messages
```

---

## What is happening here?

We are combining two lists:

### System instruction:

```text id="m2k9ff"
[
    {"role": "system", "content": "..."}
]
```

### User messages:

```text id="u3p9gg"
[
    {"role": "user", "content": "..."}
]
```

---

### Final result:

```text id="f9k2hh"
[
    system prompt,
    user message(s)
]
```

---

# Why We Prepend the System Prompt

Because order matters.

AI reads messages like a conversation timeline:

```text id="t9m1ii"
System → Instruction Set
User → Request
```

System always comes first.

It defines the rules of the conversation.

---

# Step 3 — Keep the Rest of the Function

Your function becomes:

```python
def generate_text(messages):
    full_messages = [
        {
            "role": "system",
            "content": SYSTEM_PROMPT
        }
    ] + messages

    response = client.chat.completions.create(
        model="openai/gpt-4.1-mini",
        messages=full_messages
    )

    return response.choices[0].message.content
```

---

# What Changed?

Before:

```text id="b1k9jj"
User → AI (generic response)
```

After:

```text id="c9m2kk"
System rules + User → AI (debugger response)
```

---

# Testing the New Behavior

Try:

```python
messages = [
    {
        "role": "user",
        "content": """
numbers = [1, 2, 3]
print(numbers[10])
"""
    }
]

print(generate_text(messages))
```

---

# Expected AI Behavior Now

Instead of:

```text id="g2m9ll"
IndexError
```

You should get something like:

```text id="h9k2mm"
1. Problem:
   IndexError: list index out of range

2. Explanation:
   The list has only 3 elements...

3. Fix:
   Use a valid index...

4. Best practices:
   Always validate indices...
```

---

# What We Just Achieved

We transformed a general AI into:

```text id="d9k1nn"
A specialized debugging assistant
```

without changing the model itself.

---

# Important Insight

This is one of the most powerful ideas in AI systems:

> Behavior is controlled by prompts, not code changes.

We did NOT:

* Retrain the model
* Modify the model
* Change infrastructure

We only changed:

```text id="p9m2oo"
Instructions
```

---

# Why This Matters for Our Project

Our AI debugger now has:

```text id="x9k1pp"
Understanding of bugs
Structured reasoning
Consistent output format
Predictable behavior
```

This is critical for later steps like:

* PDF generation
* Marking annotations
* Diagram creation

Because structured output = usable output.

---

# The Pattern We Now Have

```text id="z9m2qq"
SYSTEM PROMPT
     ↓
Controls behavior

USER MESSAGE
     ↓
Provides input

AI RESPONSE
     ↓
Structured debugging output
```

---

# What We’ve Learned

In this chapter:

### What system prompts are

Hidden instructions that define AI behavior.

---

### Why they matter

They transform general AI into specialized tools.

---

### How roles work

* system → rules
* user → input
* assistant → output

---

### How message composition works

We prepend system instructions to user messages.

---

### Why order matters

System messages define context before input is processed.

---

# What Comes Next?

Now we finally have:

```text id="v9k1rr"
A working AI debugger brain
```

But right now it only returns text.

Next, we need to build something real engineers use every day:

> A structured debugging workflow

In **Part 7 — Designing the Debugging Pipeline**, we will learn:

* How to break analysis into stages
* Why raw AI output is not enough
* How to structure responses for UI rendering
* How to prepare for diagrams and PDFs
* How to design “analysis → transformation → output” pipelines

This is where our project starts becoming a real engineering system instead of just an AI call wrapper.
