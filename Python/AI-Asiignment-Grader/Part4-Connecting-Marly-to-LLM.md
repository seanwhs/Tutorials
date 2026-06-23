# Part 4 — Connecting Markly to an AI Model with OpenRouter

Up to this point, Markly can successfully upload assignments and extract their contents. That’s already a major milestone, but the application still isn’t *intelligent*. It can read documents, but it cannot evaluate them or generate meaningful feedback.

In this chapter, we upgrade Markly into an **AI-powered system** by connecting it to Large Language Models (LLMs) using **OpenRouter**.

We’ll also go one step further than a basic integration: instead of relying on a single model, we’ll build a **multi-model failover system** that makes Markly more resilient and reliable.

By the end of this chapter, you’ll learn how to:

* Store API keys securely using environment variables
* Connect to OpenRouter using the **Async OpenAI SDK**
* Understand asynchronous LLM requests
* Use a pool of models for redundancy
* Implement automatic failover when a model fails
* Build an AI orchestration layer (`engine.py`)
* Integrate AI responses into Markly’s UI

---

# What is OpenRouter?

There are many companies that provide access to Large Language Models:

* OpenAI
* Anthropic
* Google
* Meta
* Mistral AI
* DeepSeek
* Cohere
* Qwen

Each provider has its own models, pricing, and APIs.

Normally, switching between them means rewriting parts of your application.

OpenRouter solves this problem by acting as a **unified routing layer**.

Instead of connecting to each provider individually, your application connects to one API:

```text
                Markly
                   │
                   ▼
             OpenRouter API
                   │
      ┌────────────┼────────────┐
      ▼            ▼            ▼
   GPT Models   Claude      Llama Models
      │            │            │
      └────────────┼────────────┘
                   ▼
              AI Response
```

This allows us to swap models simply by changing a string.

---

# Why We Use the Async OpenAI SDK

Although we are using OpenRouter, we still use the **OpenAI Python SDK** because OpenRouter is fully API-compatible.

In this version, we take it a step further by using:

> **AsyncOpenAI**

Why?

Because AI requests are slow network operations. If we make them synchronously, the UI (or server) has to wait.

With async calls, Markly can:

* Handle multiple requests efficiently
* Avoid blocking the UI
* Prepare for future scaling (multiple graders, batch marking, etc.)

---

# Securing Your API Key

Make sure your `.env` file contains:

```text
OPENROUTER_API_KEY=your_api_key_here
```

We never hardcode secrets like this:

```python
API_KEY = "sk-xxxx"
```

Because if the code is ever shared or pushed to GitHub, the key becomes exposed.

Instead, we load it securely at runtime.

---

# Setting Up the AI Engine

Open **engine.py**.

We start with imports:

```python
import os
import asyncio
import random

from dotenv import load_dotenv
from openai import AsyncOpenAI
```

---

## Load Environment Variables

```python
load_dotenv()
API_KEY = os.getenv("OPENROUTER_API_KEY")
```

This reads the `.env` file and retrieves your API key safely.

---

## Create the Async Client

Now we create the OpenRouter client:

```python
client = AsyncOpenAI(
    api_key=API_KEY,
    base_url="https://openrouter.ai/api/v1"
)
```

### What’s different here?

| Feature     | Purpose                       |
| ----------- | ----------------------------- |
| AsyncOpenAI | Enables non-blocking requests |
| base_url    | Redirects SDK to OpenRouter   |

Everything else behaves like the OpenAI API.

---

# Introducing a Model Pool (Multi-Model Strategy)

Instead of relying on a single AI model, we define a **pool of models**:

```python
MODELS_POOL = [
    "openai/gpt-oss-20b:free",
    "qwen/qwen3-coder:free",
    "google/gemma-4-31b-it:free",
    "meta-llama/llama-3.3-70b-instruct:free",
]
```

### Why multiple models?

Because in real-world systems:

* Some models fail
* Some hit rate limits
* Some become temporarily unavailable

So instead of failing the whole system, we **try another model automatically**.

This is called:

> **Failover orchestration**

---

# Step 1 — Single Model Request

We define a low-level function that talks to one model.

```python
async def ask_ai(prompt, model_name):
    """Performs a single async request to OpenRouter."""
    try:
        response = await client.chat.completions.create(
            model=model_name,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        return response.choices[0].message.content

    except Exception as e:
        raise Exception(f"Model {model_name} failed: {e}")
```

### What’s happening here?

* We send a prompt
* The model generates a response
* We extract only the useful text
* If anything fails, we pass the error upward

We deliberately **don’t hide failures here**.

We let the next layer handle them.

---

# Step 2 — Model Failover Orchestrator

Now we build the intelligence layer.

```python
async def get_ai_response_with_failover(prompt):
    """Tries multiple models until one succeeds."""
```

We start by randomizing the model order:

```python
shuffled_models = list(MODELS_POOL)
random.shuffle(shuffled_models)
```

### Why shuffle?

This ensures:

* No single model is always overloaded
* Fair usage distribution
* Better resilience

---

## Try Each Model One by One

```python
for model in shuffled_models:
    try:
        print(f"Trying: {model}...")
        return await ask_ai(prompt, model)

    except Exception as e:
        print(f"Error: {e}")
        await asyncio.sleep(1)
```

### What this means:

* Try model 1
* If it fails → try model 2
* If it fails → try model 3
* Continue until success

This makes Markly **self-healing**.

---

## If Everything Fails

```python
return "Error: All models in the pool failed."
```

This is your final fallback safety net.

---

# Step 3 — Testing the Engine

We define an entry point:

```python
async def main():
    prompt = "Explain the event loop in one sentence."
    result = await get_ai_response_with_failover(prompt)

    print(f"\nFinal Result:\n{result}")
```

Run it:

```bash
python engine.py
```

Expected output:

```text
Trying: qwen/qwen3-coder:free...
Trying: meta-llama/llama-3.3-70b-instruct:free...

Final Result:
The event loop is a mechanism that continuously checks for and executes asynchronous tasks in a program.
```

---

# Understanding the Architecture

At this point, Markly is no longer a simple API client.

It is now an **AI orchestration system**.

```text
Teacher Input
     │
     ▼
Markly Engine
     │
     ▼
Model Router (Failover System)
     │
     ▼
Multiple LLMs (OpenRouter)
     │
     ▼
Best Available Response
```

---

# Why This Design Matters

This architecture introduces three important engineering principles:

## 1. Resilience

If one model fails, others take over.

## 2. Flexibility

You are not locked into one provider.

## 3. Scalability

You can add more models without changing core logic.

---

# Connecting Back to Markly UI

In `app.py`, nothing changes conceptually.

Instead of calling a single model:

```python
grade_assignment()
```

You now call:

```python
await get_ai_response_with_failover(prompt)
```

Or wrap it inside a synchronous bridge depending on Panel constraints.

The UI remains simple:

```text
Upload → Extract → Send to Engine → Display Feedback
```

But the engine behind it is now significantly more powerful.

---

# What We’ve Built So Far

Markly now supports:

* Document upload (PDF/DOCX)
* Text extraction
* AI grading via LLMs
* Async API calls
* Multi-model failover system
* Resilient AI orchestration layer

---

# What’s Still Missing

Right now, Markly still behaves like a **generic AI grader**.

It does not yet understand:

* Subject differences (Math vs English vs Science)
* Grading rubrics
* Teaching styles
* Evaluation consistency

In the next chapter, we’ll solve this by introducing:

> 🎓 **Teacher Personas (Subject-Specific AI Grading Systems)**

This is where Markly starts to feel like a real educational assistant rather than a generic chatbot.
