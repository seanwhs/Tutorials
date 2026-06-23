# Part 4 — Connecting Markly to an AI Model with OpenRouter

Up to this point, Markly can successfully upload assignments and extract their contents. That’s already a major milestone, but the application still isn’t *intelligent*. It can read documents, but it cannot evaluate them or generate meaningful feedback.

In this chapter, we upgrade Markly into an **AI-powered system** by connecting it to Large Language Models (LLMs) using **OpenRouter**.

We’ll go beyond a basic integration and build something closer to a real production-grade architecture:

> A **concurrent multi-model AI orchestration system** with built-in timeout and automatic cancellation.

Instead of waiting for models one by one, Markly will now run them **in parallel** and return the fastest valid response.

---

By the end of this chapter, you’ll learn how to:

* Store API keys securely using environment variables
* Connect to OpenRouter using the **Async OpenAI SDK**
* Understand asynchronous + concurrent LLM execution
* Run multiple models in parallel for faster responses
* Implement timeout-based request control (internal abort system)
* Cancel unnecessary tasks to save resources
* Build a robust AI orchestration layer (`engine.py`)
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

Each provider exposes its own models, APIs, and limitations.

Normally, switching between them requires rewriting application logic.

OpenRouter simplifies this by acting as a **unified routing layer**.

Instead of connecting to each provider separately, Markly connects to a single API:

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

This makes model experimentation as simple as changing a string.

---

# Why We Use Async OpenAI SDK

Although we are using OpenRouter, we still use the **OpenAI Python SDK** because it is fully API-compatible.

In this version, we rely on:

> **AsyncOpenAI + asyncio concurrency**

Why this matters:

Traditional LLM calls are slow because they depend on network latency and model load.

If we call models one-by-one:

* We wait for each model sequentially
* Total latency increases
* UI feels slow

With async + concurrency:

* All models are triggered at the same time
* The fastest successful response wins
* Slower models are automatically discarded

This is closer to how production AI systems behave.

---

# Securing Your API Key

Your `.env` file should contain:

```text
OPENROUTER_API_KEY=your_api_key_here
```

Never hardcode secrets:

```python
API_KEY = "sk-xxxx"
```

Because this exposes your credentials if the code is shared or uploaded.

Instead, we load it at runtime.

---

# Setting Up the AI Engine

Open **engine.py**.

We start with the core imports:

```python
import os
import asyncio

from dotenv import load_dotenv
from openai import AsyncOpenAI
```

---

## Load Environment Variables

```python
load_dotenv()
API_KEY = os.getenv("OPENROUTER_API_KEY")
```

This safely retrieves the API key from your environment.

---

## Initialize the OpenRouter Client

```python
client = AsyncOpenAI(
    api_key=API_KEY,
    base_url="https://openrouter.ai/api/v1"
)
```

| Component   | Purpose                       |
| ----------- | ----------------------------- |
| AsyncOpenAI | Enables asynchronous requests |
| base_url    | Routes traffic to OpenRouter  |

---

# Introducing the Model Pool

Instead of relying on a single model, we define a pool:

```python
MODELS_POOL = [
    "openai/gpt-oss-20b:free",
    "qwen/qwen3-coder:free",
    "google/gemma-4-31b-it:free",
    "meta-llama/llama-3.3-70b-instruct:free",
]
```

### Why multiple models?

Because real-world AI systems must handle:

* Rate limits
* Model downtime
* Latency variation
* Temporary API failures

So instead of failing, we **switch strategies dynamically**.

---

# Step 1 — Single Model Request with Timeout Control

We define a low-level function that talks to one model.

```python
async def ask_ai(prompt, model_name, timeout=10.0):
    """
    Performs a single async request with timeout control.
    """
    try:
        response = await client.chat.completions.create(
            model=model_name,
            messages=[{"role": "user", "content": prompt}],
            timeout=timeout
        )

        return response.choices[0].message.content

    except asyncio.TimeoutError:
        raise Exception(f"Model {model_name} exceeded timeout.")

    except Exception as e:
        raise Exception(f"Model {model_name} failed: {e}")
```

---

### What’s new here?

We introduced an important concept:

> **Internal request timeout (abort mechanism)**

This ensures:

* Slow models don’t block execution
* Hanging requests are automatically terminated
* System remains responsive

Think of it as a **safety timer per model call**.

---

# Step 2 — Concurrent Model Execution (Core Innovation)

Now we move from sequential logic → concurrent orchestration.

```python
async def get_ai_response_concurrently(prompt, timeout=10.0):
    """
    Runs multiple models in parallel and returns the first successful result.
    """
```

---

## Create Tasks for All Models

```python
tasks = [
    asyncio.create_task(ask_ai(prompt, model, timeout))
    for model in MODELS_POOL
]
```

Now every model starts **at the same time**.

---

## Track Pending Tasks

```python
pending = set(tasks)
```

We maintain a dynamic set of unfinished tasks.

---

## Wait for First Successful Result

```python
while pending:
    done, pending = await asyncio.wait(
        pending,
        return_when=asyncio.FIRST_COMPLETED
    )
```

### Key idea:

We don’t wait for all models.

We stop at the **first completed task** (successful or failed).

---

## Handle Completed Tasks

```python
for task in done:
    try:
        return task.result()
```

If a model succeeds:

* We immediately return the result
* We ignore slower models

If it fails:

```python
except Exception as e:
    print(f"Task failed, checking next: {e}")
```

We continue waiting for others.

---

## Fallback if Everything Fails

```python
return "Error: All models in the pool failed."
```

---

# Step 3 — Critical Resource Cleanup

This is an important production-level detail.

```python
finally:
    for task in pending:
        if not task.done():
            task.cancel()

    await asyncio.gather(*pending, return_exceptions=True)
```

### Why this matters:

Without cleanup:

* Background tasks continue running
* Memory leaks may occur
* API quotas may be wasted

So we explicitly:

* Cancel unused tasks
* Await cancellation cleanup
* Ensure no orphan processes remain

This is what makes the system **production-safe**.

---

# Step 4 — Testing the Engine

```python
async def main():
    prompt = "Explain the event loop in one sentence."
    result = await get_ai_response_concurrently(prompt)
    print(f"\nFinal Result:\n{result}")
```

Run it:

```bash
python engine.py
```

---

### Example output:

```text
Final Result:
The event loop is a system that continuously checks and executes asynchronous tasks in a program.
```

Behind the scenes:

```text
Model A → slow (ignored)
Model B → error
Model C → fast winner ✔
Model D → still running → cancelled
```

---

# Understanding the Architecture

Markly is now a **concurrent AI orchestration system**.

```text
Teacher Input
     │
     ▼
Markly Engine
     │
     ▼
Parallel Model Execution
     │
     ▼
OpenRouter (Multiple LLMs)
     │
     ▼
Fastest Successful Response
     │
     ▼
Teacher Feedback
```

---

# Why This Design Matters

## 1. Speed (Low Latency)

Instead of waiting for multiple sequential calls, we take the fastest response.

## 2. Fault Tolerance

If one model fails, others continue.

## 3. Efficiency

Unused tasks are cancelled, saving compute and API usage.

## 4. Production Readiness

This mirrors real-world AI routing systems used in:

* AI copilots
* Multi-model gateways
* Enterprise AI routers

---

# Connecting Back to Markly UI

In `app.py`, the interface remains unchanged.

Instead of:

```python
grade_assignment()
```

We now call:

```python
await get_ai_response_concurrently(prompt)
```

The UI flow stays simple:

```text
Upload → Extract → Send to Engine → Display Feedback
```

But the backend is now significantly more advanced.

---

# What We’ve Built So Far

Markly now includes:

* Document upload (PDF/DOCX)
* Text extraction
* Async AI calls
* Multi-model execution
* Concurrent model orchestration
* Timeout-based internal abort system
* Automatic task cancellation
* Fastest-response selection strategy

---

# What’s Still Missing

Even though Markly is now fast and resilient, it still behaves like a **generic AI grader**.

It does not yet understand:

* Subject-specific grading logic
* Rubrics and marking schemes
* Teaching styles
* Assessment consistency

---

# Next Chapter Preview

In the next chapter, we will upgrade Markly’s intelligence layer:

> 🎓 **Teacher Personas — Subject-Aware AI Grading**

This will transform Markly from a generic AI system into a **multi-disciplinary educational assistant** that behaves like different types of teachers depending on context.
