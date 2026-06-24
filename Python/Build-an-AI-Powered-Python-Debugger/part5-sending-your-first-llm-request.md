# Part 5 — Sending Your First AI Request

In the previous chapter, we built our connection to OpenRouter.

At this point our application knows:

```text
Where the AI service is
```

and

```text
How to authenticate
```

using our API key.

But there is still a problem.

We haven't actually sent a message.

Think of it like this:

```text
Telephone Installed
       ✓

Phone Number Known
       ✓

Conversation Started
       ✗
```

In this chapter, we're going to make our first real AI request.

By the end, you'll be able to:

```text
Send a message
      ↓
Receive an answer
      ↓
Display it on screen
```

This will be the first truly exciting moment in the project.

Because for the first time:

> Your code will talk to an AI.

---

# Before We Start: Understanding Functions

To send requests properly, we need to understand one of the most important concepts in programming:

```text
Functions
```

Everything we build later depends on them.

---

# Why Functions Exist

Imagine writing this code:

```python
print("Hello")
print("Hello")
print("Hello")
print("Hello")
print("Hello")
```

This works.

But it's repetitive.

Now imagine the same block repeated 100 times.

The code becomes difficult to maintain.

---

Programmers hate repetition.

One of the most famous principles in software engineering is:

```text
DRY

Don't Repeat Yourself
```

Functions help solve this problem.

---

# A Real-World Analogy

Think about a coffee machine.

You don't need to know:

```text
How water heats

How pressure works

How beans are ground
```

You simply press:

```text
Espresso
```

and receive coffee.

---

Functions work the same way.

```text
Input
   ↓
Function
   ↓
Output
```

You provide information.

The function performs work.

The function returns a result.

---

# Creating Your First Function

Let's create a simple example.

```python
def say_hello():
    print("Hello")
```

Let's examine every part.

---

## The def Keyword

```python
def
```

means:

> I am creating a function.

---

## The Function Name

```python
say_hello
```

is simply the name.

We could have chosen:

```python
greet
```

or

```python
welcome_user
```

The name is chosen by the programmer.

---

## Parentheses

```python
()
```

hold inputs.

Currently there are none.

---

## The Colon

```python
:
```

marks the start of the function body.

---

## The Function Body

```python
print("Hello")
```

is the code that executes when the function runs.

---

# Creating Inputs

Functions become powerful when they accept information.

Example:

```python
def greet(name):
    print(f"Hello {name}")
```

Now:

```python
greet("Sean")
```

produces:

```text
Hello Sean
```

---

The value:

```python
"Sean"
```

is called an argument.

---

# Parameters vs Arguments

These two terms confuse almost every beginner.

Let's clarify.

---

## Parameter

The variable defined by the function.

```python
def greet(name):
```

Here:

```python
name
```

is a parameter.

---

## Argument

The actual value supplied.

```python
greet("Sean")
```

Here:

```python
"Sean"
```

is an argument.

---

Think:

```text
Parameter = Empty Box

Argument = Value Put Into Box
```

---

# Returning Values

Functions can also give results back.

Example:

```python
def add(a, b):
    return a + b
```

Notice:

```python
return
```

---

The return statement means:

> Send this value back to whoever called me.

---

Example:

```python
result = add(5, 3)
```

---

Execution:

```text
5 enters function
3 enters function
      ↓
5 + 3
      ↓
8 returned
```

---

Now:

```python
result
```

contains:

```text
8
```

---

# Why This Matters

Soon we'll create:

```python
def generate_text(messages):
```

The function will:

```text
Receive Messages
        ↓
Send Request To AI
        ↓
Receive Response
        ↓
Return Answer
```

Exactly the same idea.

---

# Sending Our First Request

Let's return to:

```python
llm_client.py
```

Currently we have:

```python
import os

from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

API_KEY = os.getenv("OPENROUTER_API_KEY")

client = OpenAI(
    api_key=API_KEY,
    base_url="https://openrouter.ai/api/v1"
)
```

Now we'll add our first request.

---

# Understanding Messages

Earlier we learned:

AI models receive conversations.

Not plain strings.

---

Example:

```python
messages = [
    {
        "role": "user",
        "content": "Say hello"
    }
]
```

Let's break this apart.

---

# What Is A List?

A list stores multiple values.

Example:

```python
fruits = [
    "apple",
    "banana",
    "orange"
]
```

---

Visualized:

```text
fruits

[0] apple
[1] banana
[2] orange
```

---

Lists preserve order.

This is important for conversations.

---

# What Is A Dictionary?

Inside the list we have:

```python
{
    "role": "user",
    "content": "Say hello"
}
```

This is a dictionary.

---

Think:

```text
Key      Value
----------------
role     user
content  Say hello
```

---

The AI API expects messages in this format.

---

# Understanding Roles

Here:

```python
"role": "user"
```

means:

> This message came from the user.

---

And:

```python
"content": "Say hello"
```

means:

> This is the actual message.

---

# Creating A Test Conversation

Add:

```python
messages = [
    {
        "role": "user",
        "content": "Say hello in one sentence."
    }
]
```

Simple.

One message.

One request.

---

# Making The Request

Now add:

```python
response = client.chat.completions.create(
    model="openai/gpt-4.1-mini",
    messages=messages
)
```

This line looks scary.

Don't worry.

We'll dissect every piece.

---

# Understanding Method Chaining

Notice:

```python
client.chat.completions.create(...)
```

Many beginners see this and panic.

Let's simplify.

---

Imagine:

```text
House
 └─ Kitchen
     └─ Drawer
         └─ Spoon
```

Each level contains another level.

---

Similarly:

```text
client
  └─ chat
       └─ completions
              └─ create()
```

We're simply navigating through objects.

---

# What Does create() Do?

This is the action.

Think:

```text
Create Request
      ↓
Send To AI
      ↓
Return Response
```

That's exactly what happens.

---

# Understanding model=

```python
model="openai/gpt-4.1-mini"
```

This tells OpenRouter:

> Which AI model should handle the request?

---

Think:

```text
Hospital
   ↓
Choose Doctor
```

or

```text
School
   ↓
Choose Teacher
```

---

Different models have different strengths.

---

# Understanding messages=

```python
messages=messages
```

means:

> Send this conversation to the AI.

---

The AI reads:

```python
[
  {
    "role":"user",
    "content":"Say hello in one sentence."
  }
]
```

and generates a response.

---

# What Is Returned?

The result is stored in:

```python
response
```

Think:

```text
Request Sent
      ↓
AI Responds
      ↓
Store Result In response
```

---

# Inspecting The Response

Add:

```python
print(response)
```

Run:

```bash
python llm_client.py
```

You will see a huge structure.

Something like:

```text
ChatCompletion(
    ...
)
```

This is normal.

---

The response contains lots of information.

Examples:

```text
Model Used

Usage Statistics

Message Content

Token Counts
```

---

We only want one thing:

```text
The AI's Answer
```

---

# Extracting The Response Text

Add:

```python
print(
    response.choices[0].message.content
)
```

Let's decode this.

---

## response

The entire response object.

---

## choices

A list of generated responses.

Usually there is one.

---

## [0]

Get the first item.

Remember:

```text
Lists Start At Zero
```

---

## message

The generated message.

---

## content

The actual text.

---

Therefore:

```python
response.choices[0].message.content
```

means:

> Give me the text produced by the AI.

---

# Example Result

The terminal might display:

```text
Hello! I hope you're having a wonderful day.
```

Congratulations.

Your application has officially spoken to an AI.

---

# Creating A Reusable Function

Right now our code is hardcoded.

We want something reusable.

Create:

```python
def generate_text(messages):
    response = client.chat.completions.create(
        model="openai/gpt-4.1-mini",
        messages=messages
    )

    return response.choices[0].message.content
```

---

Notice the flow:

```text
Messages Enter
      ↓
Request Sent
      ↓
Response Received
      ↓
Text Returned
```

This function becomes the foundation of our debugger.

---

# Testing The Function

Add:

```python
messages = [
    {
        "role":"user",
        "content":"Explain what Python is."
    }
]

answer = generate_text(messages)

print(answer)
```

Run:

```bash
python llm_client.py
```

You should receive an explanation from the AI.

---

# Why This Function Matters

Later:

```python
generate_text(...)
```

will be used for:

```text
Bug Analysis

Code Reviews

Diagram Generation

Engineering Notes

Follow-Up Questions
```

One reusable function.

Many uses.

---

# The Pattern We Just Built

This is actually a software design pattern.

```text
Application
      ↓
generate_text()
      ↓
OpenRouter
      ↓
AI Model
```

The rest of the application does not need to know how requests are sent.

It simply calls:

```python
generate_text(...)
```

and gets a result.

This is a simplified example of the **Facade Pattern**.

The complexity is hidden behind a simple interface.

---

# What We've Learned

In this chapter we learned:

### What functions are

Reusable blocks of code.

---

### What parameters are

Inputs defined by a function.

---

### What arguments are

Values passed into a function.

---

### What return values are

Data sent back by a function.

---

### How AI conversations are structured

Using lists of message dictionaries.

---

### How `client.chat.completions.create()` works

It sends a request to the AI service.

---

### How responses are structured

Using objects that contain generated messages.

---

### How to extract the AI's answer

Using:

```python
response.choices[0].message.content
```

---

### Why we created `generate_text()`

To provide a reusable AI interface for the rest of the application.

---

# What Comes Next?

Right now our AI can answer general questions.

But our goal is not to build a chatbot.

Our goal is to build a debugger.

In **Part 6 — Teaching the AI to Become a Python Debugging Expert**, we'll learn:

* What system prompts are
* Why AI personas matter
* How to control AI behavior
* How to create a debugging assistant
* How to build our first debugging prompt
* How to analyze real Python code

For the first time, we'll transform the AI from a general assistant into a specialized Python debugging expert.
