# Part 4 — Creating Your First LLM Client

In the previous chapter, we learned:

* What APIs are
* What API keys are
* Why `.env` files exist
* How our application will communicate with an AI provider

Now it's finally time to write our first real code.

By the end of this chapter, you'll have a Python program that can:

```text
Send a message to an AI
        ↓
Receive a response
        ↓
Print the result
```

This is the foundation of our entire debugger.

Everything we build later will depend on this component.

---

# What Is An LLM Client?

Before writing code, let's understand what we're building.

Imagine calling a friend.

You need:

```text
A phone
     ↓
A phone number
     ↓
A connection
```

Without a phone, you can't make the call.

---

Software works similarly.

If our application wants to talk to an AI model, it needs:

```text
Application
      ↓
Client
      ↓
AI Service
```

The client manages communication.

Think of it as a telephone connecting our application to the AI provider.

---

# Why Create llm_client.py?

A beginner might ask:

> Why don't we just put everything inside app.py?

Because applications grow.

Today:

```text
10 lines
```

Tomorrow:

```text
500 lines
```

Later:

```text
5000 lines
```

If everything is placed into one file:

```text
UI Code
AI Code
PDF Code
State Code
```

mixed together,

the application becomes difficult to understand.

---

Instead we separate responsibilities.

```text
llm_client.py
```

will contain:

```text
Everything related to AI communication
```

and nothing else.

This is our first exposure to an important engineering principle:

> Separation of Concerns

Each file should focus on one responsibility.

---

# Creating The File

Create:

```text
ai-python-debugger/

├── app.py
├── llm_client.py
├── .env
├── .gitignore
└── requirements.txt
```

---

Open:

```text
llm_client.py
```

This file will become our AI gateway.

---

# Understanding Imports

The first code we'll write is:

```python
import os
```

Beginners often memorize imports without understanding them.

Let's fix that.

---

# What Is A Library?

Imagine building furniture.

You could create:

```text
Hammer
Saw
Screwdriver
Drill
```

from scratch.

Or you could use tools someone already built.

Most people choose the second option.

---

Programming works the same way.

Python comes with many useful tools.

These collections of tools are called:

```text
Libraries
```

---

Examples:

```text
os
math
json
datetime
```

Each library provides reusable functionality.

---

# What Does import Mean?

When Python sees:

```python
import os
```

it means:

> Please load the os library so I can use its features.

---

Think of it like opening a toolbox.

```text
Toolbox Closed
      ↓
import os
      ↓
Toolbox Open
```

Now we can use tools from that library.

---

# What Is os?

The `os` library helps Python interact with the operating system.

Examples:

```text
Read environment variables

Create folders

Delete files

Access system information
```

We need it because our API key lives inside:

```text
.env
```

and we must retrieve it.

---

# Loading Environment Variables

Next:

```python
from dotenv import load_dotenv
```

This line introduces a new syntax.

---

# Understanding from ... import ...

Earlier we wrote:

```python
import os
```

which loads the entire library.

Sometimes we only need one specific tool.

Example:

```python
from math import sqrt
```

means:

> Import only the square root function.

---

Similarly:

```python
from dotenv import load_dotenv
```

means:

> Import only the load_dotenv function.

---

# What Is python-dotenv?

Remember our `.env` file?

```text
OPENROUTER_API_KEY=abc123
```

Python cannot automatically read this file.

We need a helper library.

That helper is:

```text
python-dotenv
```

---

Its job:

```text
Read .env file
      ↓
Load values into environment
      ↓
Allow Python to access them
```

---

# Loading The Environment

Add:

```python
load_dotenv()
```

---

What does this do?

It tells Python:

```text
Look for a .env file

Read its contents

Make variables available
```

---

Before:

```text
.env exists

Python cannot see it
```

After:

```text
load_dotenv()

Python can read values
```

---

# Retrieving The API Key

Now add:

```python
API_KEY = os.getenv("OPENROUTER_API_KEY")
```

This line deserves careful explanation.

---

# Understanding Variables

A variable stores data.

Example:

```python
name = "Sean"
```

Think:

```text
Label
  ↓
Box
  ↓
Value
```

---

Example:

```python
age = 25
```

means:

```text
age
 ↓
25
```

---

Similarly:

```python
API_KEY = ...
```

stores the API key.

---

# Understanding os.getenv()

Let's break it apart.

---

## os

The library we imported.

---

## getenv

Short for:

```text
Get Environment Variable
```

---

## OPENROUTER_API_KEY

The name of the variable we stored in `.env`.

---

Therefore:

```python
os.getenv("OPENROUTER_API_KEY")
```

means:

> Retrieve the value associated with OPENROUTER_API_KEY.

---

Example:

If:

```text
OPENROUTER_API_KEY=abc123
```

then:

```python
API_KEY
```

contains:

```text
abc123
```

---

# Importing The OpenAI Client

Now add:

```python
from openai import OpenAI
```

Many beginners find this confusing.

Let's clarify.

---

# Why Are We Using OpenAI If We Use OpenRouter?

Good question.

The OpenAI library is simply a tool.

Think:

```text
Web Browser
```

You can use:

```text
Chrome

Firefox

Edge
```

to visit many websites.

---

Similarly:

```text
OpenAI Library
```

can communicate with many compatible services.

Including:

```text
OpenRouter
```

---

The library is the tool.

OpenRouter is the destination.

---

# Creating The Client

Now we create our client.

```python
client = OpenAI(
    api_key=API_KEY,
    base_url="https://openrouter.ai/api/v1"
)
```

This is one of the most important lines in the project.

Let's dissect it.

---

# What Is An Object?

This introduces Object-Oriented Programming.

Don't panic.

We'll keep it simple.

---

Imagine a blueprint.

```text
Car Blueprint
```

From the blueprint we can create:

```text
Car #1

Car #2

Car #3
```

Each car is an object.

---

In Python:

```python
OpenAI(...)
```

creates an object.

---

The object contains functionality for:

```text
Sending requests

Receiving responses

Managing connections
```

---

# What Are Parameters?

Inside:

```python
OpenAI(
    api_key=API_KEY,
    base_url="https://openrouter.ai/api/v1"
)
```

we provide configuration values.

These values are called parameters.

---

Think:

```text
Order Pizza

Size = Large

Topping = Pepperoni
```

The size and topping are parameters.

---

Similarly:

```python
api_key=API_KEY
```

tells the client:

> Use this credential.

---

And:

```python
base_url="https://openrouter.ai/api/v1"
```

tells the client:

> Send requests to OpenRouter.

---

# Why Store The Client In A Variable?

Notice:

```python
client = OpenAI(...)
```

We save the object.

Why?

Because we will use it repeatedly.

---

Later:

```python
client.chat.completions.create(...)
```

---

Later again:

```python
client.chat.completions.create(...)
```

---

And again:

```python
client.chat.completions.create(...)
```

Creating one reusable client is more efficient.

---

# Testing Our Setup

Before sending AI requests, let's verify everything works.

Add:

```python
print(API_KEY)
```

Run:

```bash
python llm_client.py
```

---

If successful:

```text
sk-xxxxxxxxxxxx
```

appears.

---

If you see:

```text
None
```

then Python could not find your `.env` file.

Check:

```text
File name

Location

Variable name
```

carefully.

---

# Your Completed File

At this point:

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

Notice something interesting.

We still haven't sent any AI requests.

We've only built the connection.

Think of it like installing a telephone.

The telephone exists.

But we haven't dialed anyone yet.

---

# What We've Learned

In this chapter we learned:

### What imports are

Ways to access functionality from libraries.

---

### What libraries are

Collections of reusable tools.

---

### What variables are

Named containers for data.

---

### What environment variables are

External values loaded into an application.

---

### What objects are

Instances created from a blueprint.

---

### What parameters are

Configuration values passed into objects and functions.

---

### What a client is

A component responsible for communicating with another service.

---

### Why we created llm_client.py

To isolate all AI-related functionality into one module.

---

# What Comes Next?

We now have a connection to OpenRouter.

But we haven't actually spoken to the AI yet.

In **Part 5 — Sending Your First AI Request**, we'll learn:

* What functions are
* Why functions exist
* What arguments are
* What return values are
* How `client.chat.completions.create()` works
* How to send a prompt
* How to receive a response
* How to extract the AI's answer

For the first time, we'll make the AI say something back to us.
