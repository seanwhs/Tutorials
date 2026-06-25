# Part 4 — Connecting Markly to AI with OpenRouter

At this point, Markly can successfully:

* Upload assignments
* Read PDF files
* Read Word documents
* Extract text from images

This is a huge milestone.

However, Markly still has one major limitation:

> It can read assignments, but it cannot understand them.

A human teacher does much more than read text.

A teacher can:

* Understand what the student is trying to say
* Detect mistakes
* Evaluate quality
* Assign marks
* Provide feedback

This is where Artificial Intelligence enters the picture.

In this chapter, we will connect Markly to a Large Language Model (LLM) so that it can begin behaving like a teaching assistant.

By the end of this chapter, Markly will be able to:

* Connect to OpenRouter
* Send extracted assignments to an AI model
* Receive AI-generated responses
* Build reusable prompting functions
* Separate AI logic from the user interface
* Create the foundation for grading and feedback generation

---

# Understanding the Role of the AI Engine

Before writing any code, let's understand the architecture.

Currently our application looks like this:

```text
Teacher
   │
   ▼
Upload Assignment
   │
   ▼
Extract Text
   │
   ▼
Display Text
```

The missing piece is the intelligence layer.

After this chapter:

```text
Teacher
   │
   ▼
Upload Assignment
   │
   ▼
Extract Text
   │
   ▼
AI Model
   │
   ▼
Feedback
```

The AI model becomes the "brain" of the application.

---

# What Is OpenRouter?

OpenRouter is a service that provides access to many different AI models through a single API.

Instead of connecting directly to:

* OpenAI
* Anthropic
* Google
* DeepSeek
* Meta

you connect to OpenRouter.

OpenRouter then routes your request to the model you choose.

```text
                Markly
                   │
                   ▼
               OpenRouter
                   │
      ┌────────────┼────────────┐
      ▼            ▼            ▼
     GPT         Claude      Llama
```

This makes experimentation much easier because changing models often requires changing only a single line of code.

---

# Why Use OpenRouter?

Without OpenRouter:

```text
Application
   ├── OpenAI API
   ├── Anthropic API
   ├── Google API
   └── DeepSeek API
```

Every provider has:

* Different URLs
* Different SDKs
* Different authentication methods

With OpenRouter:

```text
Application
      │
      ▼
 OpenRouter API
      │
      ▼
 Any Supported Model
```

One API.

Many models.

Much simpler.

---

# Securing Your API Key

Earlier, we created a `.env` file.

It should contain:

```text
OPENROUTER_API_KEY=your_key_here
```

Never do this:

```python
API_KEY = "sk-123456"
```

Hardcoding secrets is dangerous because:

* Keys may be uploaded to GitHub
* Other developers may see them
* Attackers may misuse them

Instead, we load them from the environment.

---

# Creating engine.py

Open:

```text
engine.py
```

This file will contain all AI-related logic.

Keeping AI code separate from UI code follows an important software engineering principle:

> Separation of Concerns

Each file should have one primary responsibility.

| File        | Responsibility   |
| ----------- | ---------------- |
| app.py      | User Interface   |
| utils.py    | File Processing  |
| personas.py | Teacher Prompts  |
| engine.py   | AI Communication |

---

# Importing Required Libraries

Start with:

```python
import os

from dotenv import load_dotenv
from openai import AsyncOpenAI
```

---

# Loading Environment Variables

```python
load_dotenv()

API_KEY = os.getenv("OPENROUTER_API_KEY")
```

What happens here?

```text
.env
   │
   ▼
load_dotenv()
   │
   ▼
Environment Variables
   │
   ▼
os.getenv(...)
```

Now the application can safely access the API key.

---

# Creating the OpenRouter Client

Next:

```python
client = AsyncOpenAI(
    api_key=API_KEY,
    base_url="https://openrouter.ai/api/v1"
)
```

---

## Why AsyncOpenAI?

Earlier Python applications often used:

```python
OpenAI()
```

which is synchronous.

That means:

```text
Request Sent
      │
      ▼
Wait...
      ▼
Wait...
      ▼
Wait...
      ▼
Response
```

The application is blocked until the response arrives.

With:

```python
AsyncOpenAI()
```

the application can continue working while waiting for the model.

This becomes important later when we add:

* streaming responses
* multiple AI requests
* vision models
* grading pipelines

---

# Sending Your First AI Request

Create a simple function:

```python
async def ask_ai(prompt):
    response = await client.chat.completions.create(
        model="openai/gpt-oss-20b:free",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ]
    )

    return response.choices[0].message.content
```

---

# Understanding Messages

Modern LLMs communicate using messages.

A message contains:

```python
{
    "role": "user",
    "content": "Hello"
}
```

Roles can be:

| Role      | Purpose      |
| --------- | ------------ |
| system    | Instructions |
| user      | Human input  |
| assistant | AI response  |

Example:

```python
messages = [
    {
        "role": "system",
        "content": "You are a helpful teacher."
    },
    {
        "role": "user",
        "content": "Explain fractions."
    }
]
```

This conversation is sent to the model.

---

# Testing the Connection

Add:

```python
import asyncio
```

Then:

```python
async def main():
    result = await ask_ai(
        "Explain what a programming bug is."
    )

    print(result)

asyncio.run(main())
```

Run:

```bash
python engine.py
```

Example:

```text
A programming bug is an error or flaw in software that causes unexpected behaviour.
```

Congratulations.

Markly is now talking to an AI model.

---

# Making the Function Reusable

Soon we will have many AI features:

* Subject detection
* Assignment grading
* Report generation
* Teacher feedback
* Student progress summaries

Rather than rewriting AI calls repeatedly, create a reusable helper.

```python
async def generate_response(messages):

    response = await client.chat.completions.create(
        model="openai/gpt-oss-20b:free",
        messages=messages
    )

    return response.choices[0].message.content
```

Now any feature can call:

```python
await generate_response(messages)
```

---

# Building Our First Educational Prompt

Let's test with an assignment.

```python
assignment = """
Python is a programming language.
It was invented by Guido van Rossum.
"""
```

Prompt:

```python
messages = [
    {
        "role": "system",
        "content": "You are a teacher."
    },
    {
        "role": "user",
        "content": f"""
Review this assignment:

{assignment}

Provide feedback.
"""
    }
]
```

Send it to the model.

The response will resemble teacher feedback.

---

# Why Prompts Matter

The same model behaves differently depending on instructions.

Prompt:

```text
Provide feedback.
```

Produces generic results.

Prompt:

```text
Act as an experienced teacher.

Identify strengths.
Identify weaknesses.
Provide suggestions.
Assign a score out of 10.
```

Produces much better educational feedback.

This idea becomes the foundation of the next chapter.

---

# Connecting the AI to the User Interface

Back in `app.py`, we currently display extracted text.

Instead of:

```python
feedback.object = text
```

we will eventually do:

```python
feedback.object = ai_feedback
```

The workflow becomes:

```text
Upload Assignment
        │
        ▼
Extract Text
        │
        ▼
Build Prompt
        │
        ▼
Send To AI
        │
        ▼
Receive Feedback
        │
        ▼
Display Results
```

This is the first complete AI pipeline in Markly.

---

# What We Built

By the end of this chapter, Markly can:

* Connect to OpenRouter
* Authenticate securely
* Send prompts to AI models
* Receive responses
* Separate AI logic from UI logic
* Build reusable AI functions
* Create educational feedback

Most importantly:

> Markly has evolved from a document reader into an AI-powered application.

---

# What's Next?

Right now, Markly behaves like a generic assistant.

A mathematics teacher and an English teacher grade very differently.

In the next chapter, we will build:

# Part 5 — Teacher Personas and Subject-Aware Grading

You'll learn how to create specialized AI teachers that evaluate assignments according to:

* Mathematics reasoning
* English writing quality
* Science understanding
* Programming correctness

This is where Markly starts behaving less like a chatbot and more like a real educator.
