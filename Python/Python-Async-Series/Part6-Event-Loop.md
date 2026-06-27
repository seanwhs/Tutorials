# 🚀 Python Asyncio Explained Like a Systems Engineer (Part 6):

# Inside the Machine: How Python's Event Loop Actually Works

> *"Once you understand the event loop, `asyncio` stops looking like magic and starts looking like engineering."*

---

# Introduction

In the previous five articles, we learned how to:

* write coroutines,
* create tasks,
* coordinate thousands of concurrent operations,
* build worker pools,
* implement backpressure,
* manage cancellation,
* and construct production-grade async systems.

But one mystery remains.

When you write:

```python
await asyncio.sleep(1)
```

What actually happens?

Questions every engineer eventually asks:

* Where does the coroutine go?
* Who remembers where it stopped?
* Who wakes it back up?
* What exactly is a Future?
* How does the event loop know when a socket is ready?
* How can one thread manage 100,000 connections?

To answer these questions, we need to descend into the internals of `asyncio`.

---

# Chapter 48 — The Great Illusion

Consider:

```python
async def worker():

    print("A")

    await asyncio.sleep(2)

    print("B")
```

It appears that Python does this:

```text
Run A
Pause
Wait 2 seconds
Run B
```

But that's not what happens.

What really happens:

```text
Run A
Save execution state
Return to event loop
Run other tasks
OS notifies completion
Restore execution state
Run B
```

The keyword:

# State

Async programming is fundamentally:

> Saving and restoring execution state.

---

# Chapter 49 — The Event Loop Is Just a Scheduler

Most people imagine the event loop as something magical.

Actually, it's conceptually very simple.

```python
while True:

    ready_tasks = get_ready_tasks()

    for task in ready_tasks:

        run(task)
```

That's the entire idea.

The complexity comes from answering:

```text
Which tasks are ready?
```

---

# Visualizing the Event Loop

```text
                  Event Loop

                       |
        --------------------------------
        |              |              |
        V              V              V

     READY         WAITING        DONE
```

Tasks constantly move between these states.

---

# Exercise 1 — Build a Fake Scheduler

```python
tasks = ["A", "B", "C"]

while tasks:

    current = tasks.pop(0)

    print(f"Running {current}")

    tasks.append(current)
```

Questions:

* Why does every task run?
* Why does no task starve?
* What does this resemble?

---

# Chapter 50 — Futures: The Missing Piece

Everything in `asyncio` ultimately revolves around one object:

```python
asyncio.Future
```

A Future represents:

> A result that doesn't exist yet.

Example:

```python
future = asyncio.Future()
```

Current state:

```text
PENDING
```

Later:

```python
future.set_result(42)
```

State becomes:

```text
FINISHED
```

---

# Analogy

Imagine ordering food.

```text
Restaurant ticket:

Order #57

Status:
WAITING
```

Later:

```text
Order #57

Status:
READY
```

A Future is simply an asynchronous promise.

---

# Example

```python
import asyncio

async def main():

    future = asyncio.Future()

    future.set_result("hello")

    result = await future

    print(result)

asyncio.run(main())
```

Output:

```text
hello
```

---

# Exercise 2 — Experiment with Futures

Try:

```python
future = asyncio.Future()

print(
    future.done()
)

future.set_result(100)

print(
    future.done()
)
```

Questions:

* What changed?
* Why?

---

# Chapter 51 — Coroutines Wait on Futures

Consider:

```python
await asyncio.sleep(5)
```

Internally:

```text
sleep()
    |
creates Future
    |
register timer
    |
yield Future
    |
event loop waits
    |
timer expires
    |
Future completes
    |
coroutine resumes
```

The key insight:

> Coroutines do not wait for functions.

They wait for Futures.

---

# Visual Diagram

```text
Coroutine
     |
await
     |
Future
     |
OS/Event Loop
     |
Result
     |
Resume Coroutine
```

---

# Chapter 52 — Implementing Sleep Yourself

A fake implementation:

```python
class FakeSleep:

    def __init__(self):

        self.done = False

    def finish(self):

        self.done = True
```

Usage:

```python
sleep = FakeSleep()

while not sleep.done:

    pass
```

This is essentially what the event loop automates.

---

# Exercise 3 — Build a Manual Future

Implement:

```python
class Future:

    def done(self):
        ...

    def set_result(self):
        ...

    def result(self):
        ...
```

---

# Chapter 53 — Selectors: The Real Magic

Suppose:

```python
await socket.recv()
```

Question:

How does Python know when data arrives?

Answer:

It asks the operating system.

---

# Linux

```text
epoll
```

---

# macOS

```text
kqueue
```

---

# Windows

```text
IOCP
```

---

# Architecture

```text
Application
      |
asyncio
      |
selectors
      |
operating system
      |
network hardware
```

---

# Example

Python:

```python
await socket.recv()
```

Internally:

```text
register socket
      |
yield execution
      |
OS monitors socket
      |
data arrives
      |
OS wakes event loop
      |
event loop resumes coroutine
```

---

# Exercise 4 — Observe Network Waiting

Run:

```python
import asyncio

async def main():

    await asyncio.open_connection(
        "google.com",
        80
    )

asyncio.run(main())
```

Question:

Who actually waits?

* Python?
* The CPU?
* The operating system?

---

# Chapter 54 — Ready Queue vs Waiting Queue

The event loop maintains multiple queues.

---

## Ready Queue

```text
Ready:

Task A
Task B
Task C
```

---

## Waiting Queue

```text
Waiting:

Socket A
Timer B
Future C
```

---

Example:

```text
Task A:
await sleep()
```

Moves:

```text
READY
   ↓
WAITING
```

When timer expires:

```text
WAITING
   ↓
READY
```

---

# Exercise 5 — Simulate State Transitions

Draw:

```text
Task
   |
RUNNING
   |
WAITING
   |
READY
   |
RUNNING
   |
FINISHED
```

for:

```python
await asyncio.sleep()
```

---

# Chapter 55 — Callbacks: Async Before Async

Before:

```python
await download()
```

we had:

```python
download(
    callback=finished
)
```

Example:

```python
def done(result):

    print(result)

download(done)
```

Problems:

```text
callback hell
```

---

# Example

```python
download(

    lambda x:

        parse(

            x,

            lambda y:

                save(

                    y,

                    lambda z:
                        notify()
                )
        )
)
```

---

# Exercise 6 — Callback Hell

Rewrite:

```text
download
    |
parse
    |
save
    |
notify
```

using callbacks only.

---

# Chapter 56 — Async/Await Is Syntactic Sugar

This:

```python
result = await task()
```

is conceptually:

```python
yield task()
```

In fact:

```text
async/await
```

was built on top of:

```text
generators
```

---

# Traditional Generator

```python
def numbers():

    yield 1

    yield 2

    yield 3
```

---

# Async Generator

```python
async def numbers():

    yield 1

    yield 2

    yield 3
```

---

# Similarity

```text
yield
     ↓
pause execution

await
     ↓
pause execution
```

---

# Exercise 7 — Compare Generators and Coroutines

Implement:

```python
def generator():

    yield 1

    yield 2
```

and:

```python
async def coroutine():

    await asyncio.sleep(1)
```

Questions:

* What pauses?
* What resumes?
* Who controls execution?

---

# Chapter 57 — Building a Tiny Event Loop

Let's build a toy scheduler.

```python
tasks = []

def create_task(fn):

    tasks.append(fn)
```

Scheduler:

```python
while tasks:

    task = tasks.pop(0)

    finished = task()

    if not finished:

        tasks.append(task)
```

---

# Example

```python
def A():

    print("A")

    return False

def B():

    print("B")

    return False
```

Produces:

```text
A
B
A
B
A
B
...
```

This is the basic idea behind every scheduler.

---

# Exercise 8 — Build Round Robin Scheduling

Implement:

```text
Task A
Task B
Task C
```

Requirements:

* rotate tasks
* remove completed tasks
* prevent starvation

---

# Chapter 58 — Why Async Scales

Threads:

```text
10000 threads
```

require:

```text
10000 stacks
10000 contexts
10000 schedulers
```

---

# Async:

```text
1 thread
10000 tasks
```

requires:

```text
1 scheduler
10000 state objects
```

---

# Memory Comparison

| Model                | Approximate Memory |
| -------------------- | ------------------ |
| 10,000 threads       | 10 GB              |
| 10,000 asyncio tasks | <100 MB            |

---

# Exercise 9 — Benchmark Scale

Try:

```python
tasks = [

    asyncio.create_task(
        asyncio.sleep(1)
    )

    for _ in range(100000)
]
```

Questions:

* Does it work?
* How much memory?
* Could you create 100,000 threads?

---

# Chapter 59 — Why Async Doesn't Make CPU Code Faster

Bad:

```python
async def calculate():

    total = 0

    for i in range(100000000):

        total += i

    return total
```

Why?

Because:

```text
No await
No yielding
No scheduling
No concurrency
```

The event loop freezes.

---

# Exercise 10 — Freeze Async

Run:

```python
async def cpu():

    while True:
        pass

await cpu()
```

Question:

Why can't the event loop recover?

---

# Summary

In this article we learned:

✅ event loops are schedulers
✅ Futures represent unfinished results
✅ coroutines wait on Futures
✅ selectors talk to the OS
✅ sockets wake the event loop
✅ callbacks evolved into async/await
✅ generators inspired coroutines
✅ async is fundamentally state management

---

# The One Diagram To Remember

```text
Coroutine
     |
   await
     |
   Future
     |
 Event Loop
     |
 Selector
     |
 Operating System
     |
 Network/File/Timer
     |
 Selector
     |
 Event Loop
     |
 Resume Coroutine
```

---

# Conclusion

At this point, you should realize something profound:

> Async programming is not a programming paradigm.

It's a scheduling system.

Everything you've learned:

* `await`
* tasks
* queues
* semaphores
* cancellation
* pipelines
* futures
* selectors

exists to answer one question:

> **"What should run next?"**

In **Part 7**, we'll leave the internals behind and become architects, learning how to design and build complete production-grade async systems:

* web crawlers,
* websocket servers,
* chat systems,
* streaming pipelines,
* ETL platforms,
* market data systems,
* AI inference services,
* and distributed event-driven architectures.
