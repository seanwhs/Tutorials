# 🚀 Python Asyncio Explained Like a Systems Engineer:

# Why Your Program Spends 99% of Its Time Doing Absolutely Nothing

> *"Async doesn't make your programs faster.*
>
> *It stops your programs from wasting time."*

---

# Introduction

If you've ever encountered Python code like this:

```python
import asyncio

async def hello():
    await asyncio.sleep(1)
    print("Hello")

asyncio.run(hello())
```

you've probably asked yourself at least one of these questions:

* What exactly is `async`?
* What does `await` actually do?
* Why can't I simply use threads?
* What is an event loop?
* Is async faster than normal Python?
* When should I use `asyncio`?
* Why does everybody say async is difficult?

The problem is that most tutorials immediately teach syntax:

```python
async def
await
create_task()
gather()
TaskGroup()
```

without first explaining **why asynchronous programming exists in the first place**.

This article takes a different approach.

Rather than memorizing APIs, we're going to learn:

* why async was invented,
* how Python executes asynchronous code,
* what the event loop actually does,
* when async is appropriate,
* when async is the wrong solution,
* and how production systems use async to handle thousands of simultaneous operations.

By the end, you'll understand not just how to write async Python, but how to think like an engineer designing concurrent systems.

---

# Chapter 1 — The Real Problem: Computers Are Fast, Networks Are Slow

Let's begin with a simple question.

Suppose we need to download five web pages:

```python
import requests

urls = [
    "https://example.com",
    "https://example.com",
    "https://example.com",
    "https://example.com",
    "https://example.com"
]

for url in urls:
    response = requests.get(url)
    print(len(response.text))
```

Looks innocent enough.

But let's imagine each request takes one second.

Our execution timeline looks like this:

```text
Request 1
================== waiting ==================

Request 2
                                    ================== waiting ==================

Request 3
                                                                ================== waiting ==================
```

Total execution time:

```text
1 + 1 + 1 + 1 + 1 = 5 seconds
```

Now here's the shocking part:

During those five seconds, your CPU is doing almost nothing.

```text
CPU utilization:

████□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□

≈ 1%
```

Your computer spends most of its time simply waiting.

---

# Exercise 1 — Observe CPU Waiting

Run this program:

```python
import requests
import time

start = time.time()

for _ in range(5):
    requests.get(
        "https://httpbin.org/delay/1"
    )

print(
    f"{time.time()-start:.2f} seconds"
)
```

### Questions

1. How long did it take?
2. Was your CPU heavily utilized?
3. What exactly was Python doing during those five seconds?

---

# Chapter 2 — What Problem Does Async Actually Solve?

The key insight is this:

> Most modern applications are not computation problems.
>
> They are waiting problems.

Examples:

| Application       | Mostly Doing               |
| ----------------- | -------------------------- |
| Web scraper       | Waiting for websites       |
| REST API          | Waiting for databases      |
| Chat application  | Waiting for users          |
| Trading platform  | Waiting for market data    |
| Microservice      | Waiting for other services |
| Cloud application | Waiting for network I/O    |

The question becomes:

> Can we do something useful while we're waiting?

The answer is:

> Yes.
>
> This is called concurrency.

---

# Chapter 3 — Concurrency vs Parallelism

Most beginners think these are the same thing.

They aren't.

---

## Sequential Execution

```text
Task A
────────────────────

Task B
                    ────────────────────

Task C
                                        ────────────────────
```

Total:

```text
A + B + C
```

---

## Concurrent Execution

```text
Task A
───────      ──────

Task B
     ───────      ──────

Task C
          ───────      ─────
```

Tasks overlap.

---

## Parallel Execution

```text
CPU1: Task A
CPU2: Task B
CPU3: Task C
```

Tasks physically execute simultaneously.

---

# The Simplest Explanation

| Term        | Meaning                 |
| ----------- | ----------------------- |
| Concurrency | Deal with many tasks    |
| Parallelism | Execute many tasks      |
| Async       | Cooperative concurrency |
| Threads     | Preemptive concurrency  |
| Processes   | True parallelism        |

---

# Exercise 2 — Identify the Model

Classify the following:

### Scenario A

```python
for url in urls:
    requests.get(url)
```

Sequential or concurrent?

---

### Scenario B

```python
await asyncio.gather(
    fetch(url1),
    fetch(url2),
    fetch(url3)
)
```

Sequential, concurrent, or parallel?

---

### Scenario C

```python
Pool(8).map(work, data)
```

Sequential, concurrent, or parallel?

---

# Chapter 4 — Why Not Just Use Threads?

Before async existed, programmers solved waiting problems with threads.

Example:

```python
from threading import Thread
import requests

def fetch(url):

    response = requests.get(url)

    print(
        len(response.text)
    )

for url in urls:

    Thread(
        target=fetch,
        args=(url,)
    ).start()
```

This works.

So why invent async?

---

## Problem 1 — Memory

Each thread requires memory.

Approximate cost:

```text
1 MB per thread
```

This means:

| Threads | Memory |
| ------- | ------ |
| 100     | 100 MB |
| 1000    | 1 GB   |
| 10000   | 10 GB  |

---

## Problem 2 — Context Switching

The operating system constantly performs:

```text
save thread A
load thread B
run thread B
save thread B
load thread C
run thread C
```

This overhead becomes expensive.

---

## Problem 3 — Synchronization

Threads introduce:

* race conditions
* deadlocks
* starvation
* lock contention
* priority inversion

For example:

```python
x += 1
```

is not actually:

```python
x += 1
```

It's:

```text
LOAD x
ADD 1
STORE x
```

Multiple threads can interfere with each other.

---

# Exercise 3 — Create a Race Condition

Run:

```python
import threading

counter = 0

def worker():

    global counter

    for _ in range(100000):
        counter += 1

threads = []

for _ in range(2):

    t = threading.Thread(
        target=worker
    )

    t.start()

    threads.append(t)

for t in threads:
    t.join()

print(counter)
```

Question:

Why isn't the answer always:

```text
200000
```

---

# Chapter 5 — The Big Idea Behind Async

Instead of:

```text
10000 operating system threads
```

we use:

```text
1 operating system thread
10000 lightweight tasks
```

Architecture:

```text
                   Event Loop

                        |
     ---------------------------------------
     |         |          |          |
   Task A    Task B     Task C     Task D
```

This is the core innovation of `asyncio`.

Instead of asking:

> "Which thread should run?"

we ask:

> "Which task is ready to continue?"

---

# Exercise 4 — Measure Async Scalability

Create:

```python
import asyncio

async def worker():

    await asyncio.sleep(1)

async def main():

    tasks = [
        asyncio.create_task(worker())
        for _ in range(10000)
    ]

    await asyncio.gather(*tasks)

asyncio.run(main())
```

Questions:

1. How long does this take?
2. How much memory does it consume?
3. Could you create 10,000 operating system threads?

---

# Summary

In this article we learned:

✅ why programs spend most of their time waiting
✅ why concurrency exists
✅ the difference between concurrency and parallelism
✅ why threads become expensive
✅ why async was invented
✅ how async achieves high scalability

Most importantly:

> Async programming is not about making your CPU faster.
>
> Async programming is about keeping your CPU busy while everything else is slow.

---

# Conclusion

Many developers approach `asyncio` backwards.

They start by memorizing:

```python
async
await
create_task
gather
TaskGroup
```

But these are merely tools.

The real question is:

> What problem are we trying to solve?

The answer is:

> We are trying to eliminate wasted waiting time.

In the next article, we'll go deeper into the beating heart of Python async:

# The Event Loop

We'll answer questions like:

* What actually happens when you call `await`?
* Where does a coroutine pause?
* How does Python remember where to resume?
* How does the event loop decide which task executes next?
* Is async just fancy generators?

Because once you understand the event loop, the rest of `asyncio` suddenly becomes obvious.
