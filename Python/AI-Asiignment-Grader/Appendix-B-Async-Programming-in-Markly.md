# Appendix B — Understanding Async Programming in Markly

One of the most important engineering concepts introduced in Markly is something many developers initially find confusing:

> **Asynchronous programming.**

The grading engine uses:

* `async`
* `await`
* `asyncio`
* concurrent tasks
* task cancellation

Without understanding these concepts, the architecture in `engine.py` can feel like magic.

This appendix explains the mental model behind asynchronous execution and why it matters in AI applications.

---

# Why We Needed Async at All

Consider a traditional grading workflow:

```text
Upload Assignment
        │
        ▼
Call Model A
        │
(wait)
        ▼
Receive Response
        │
        ▼
Return Feedback
```

The problem is that LLM requests are slow.

A request may take:

* 2 seconds
* 5 seconds
* 15 seconds

depending on:

* network latency
* model load
* provider congestion

During that wait time:

> The application is doing absolutely nothing.

---

# Synchronous Execution

Traditional code executes line-by-line.

Example:

```python
response_a = ask_model_a()

response_b = ask_model_b()

response_c = ask_model_c()
```

Execution:

```text
Model A → wait
Model B → wait
Model C → wait
```

Timeline:

```text
0s ─────── 5s ─────── 10s ─────── 15s

Model A
          Model B
                     Model C
```

Total:

```text
15 seconds
```

This is called:

> **Sequential execution**

---

# The Problem with Sequential AI Calls

Imagine we want resilience.

We want to query:

* GPT
* Claude
* Llama

and use whichever succeeds first.

Sequential execution means:

```text
Try GPT
If fail → try Claude
If fail → try Llama
```

Worst-case latency becomes enormous.

---

# The Async Mindset

Instead of saying:

> "Do one thing at a time"

we say:

> "Start everything and wait for whichever finishes."

This is asynchronous execution.

---

# Async Does NOT Mean Parallel CPU Processing

This is the first misconception.

People often think:

```text
async = multithreading
```

Not necessarily.

Async is about:

> Efficient waiting.

---

Consider:

```python
await ask_model()
```

While waiting for:

* network
* API response
* database query

the program can work on something else.

---

# Real-World Analogy

Imagine ordering coffee.

### Synchronous Version

```text
Order coffee
Stand at counter
Watch barista
Wait 5 minutes
Receive coffee
```

Nothing else happens.

---

### Async Version

```text
Order coffee
Receive queue number
Sit down
Answer emails
Coffee ready
Collect coffee
```

The waiting time is utilized.

That is async programming.

---

# Understanding `async`

A normal function:

```python
def calculate():
    return 42
```

An async function:

```python
async def calculate():
    return 42
```

This does not execute immediately.

Instead:

```python
calculate()
```

returns a coroutine object.

Think of it as:

```text
A task that can be scheduled later
```

---

# Understanding `await`

To execute an async function:

```python
result = await calculate()
```

`await` means:

> Pause here until the task completes.

But importantly:

> Other async tasks may continue running.

---

# Visualizing the Event Loop

At the center of asyncio is the event loop.

Think of it as:

```text
Traffic Controller
```

---

```text
Task A waiting
Task B waiting
Task C waiting

      │
      ▼

 Event Loop

      │
      ▼

Resume whichever task is ready
```

---

The loop continuously checks:

```text
Is Task A ready?
No.

Is Task B ready?
Yes.

Resume Task B.
```

This happens thousands of times per second.

---

# What Happens in Markly

Consider:

```python
tasks = [
    asyncio.create_task(
        ask_ai(prompt, model)
    )
    for model in MODELS_POOL
]
```

Suppose:

```python
GPT
Claude
Llama
Gemma
```

Execution becomes:

```text
Start GPT
Start Claude
Start Llama
Start Gemma
```

Immediately.

---

# Concurrent Timeline

Sequential:

```text
GPT     5s
Claude  5s
Llama   5s

Total = 15s
```

Concurrent:

```text
GPT      5s
Claude   3s
Llama    7s
Gemma    4s
```

All start together.

Total:

```text
3 seconds
```

because Claude finished first.

---

# Understanding `FIRST_COMPLETED`

Markly uses:

```python
asyncio.wait(
    tasks,
    return_when=asyncio.FIRST_COMPLETED
)
```

Meaning:

```text
Wait until ANY task finishes
```

not:

```text
Wait until ALL tasks finish
```

---

Example:

```text
GPT      5s
Claude   2s
Llama    8s
Gemma    6s
```

Result:

```text
Claude wins
```

Return immediately.

---

# Why We Cancel Remaining Tasks

After a winner exists:

```python
task.cancel()
```

for remaining models.

Without cancellation:

```text
GPT continues
Llama continues
Gemma continues
```

even though their outputs are no longer needed.

This wastes:

* tokens
* API quota
* memory
* network resources

---

# What Happens During Cancellation

```python
task.cancel()
```

sends a cancellation request.

The task may stop:

```text
Immediately
```

or

```text
At next await point
```

depending on its state.

---

Markly then performs cleanup:

```python
await asyncio.gather(
    *pending,
    return_exceptions=True
)
```

This ensures:

* resources released
* no orphan tasks
* clean shutdown

---

# Timeout Protection

Every model call includes:

```python
timeout=10
```

Suppose a provider hangs:

```text
Request sent
...
...
...
never returns
```

Without timeout:

```text
Task hangs forever
```

With timeout:

```text
10 seconds reached
↓
Abort task
```

---

# Why Async Matters for AI Systems

AI systems spend most of their time waiting for:

* network calls
* model inference
* API responses

This makes async a natural fit.

---

# Traditional Web App

```text
CPU-bound
```

Most time spent computing.

---

# AI Application

```text
IO-bound
```

Most time spent waiting.

---

Async is specifically designed for IO-bound workloads.

---

# Markly's Execution Model

When a teacher clicks:

```text
Grade Assignment
```

Markly now does:

```text
Start Multiple Models
        │
        ▼
Wait for First Success
        │
        ▼
Cancel Remaining Models
        │
        ▼
Return Feedback
```

This architecture gives:

* lower latency
* higher reliability
* better fault tolerance
* lower API waste

---

# Key Takeaways

The goal of async programming is not:

> "Run code faster."

The goal is:

> "Avoid wasting time while waiting."

Markly uses async because AI requests are network-bound operations.

Understanding these concepts will help you build:

* AI copilots
* AI agents
* multi-model routers
* workflow orchestrators
* production AI systems

In many modern AI applications, async programming is not an optimization.

It is a foundational architectural requirement.
