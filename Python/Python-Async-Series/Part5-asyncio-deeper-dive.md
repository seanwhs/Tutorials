# 🚀 Python Asyncio Explained Like a Systems Engineer (Part 5):

# Timeouts, Cancellation, Locks, and How Async Systems Fail in Production

> *"The hardest part of asynchronous programming is not making things run.*
>
> *It's making things stop."*

---

# Introduction

In Part 4, we learned how real async systems are built using:

* queues,
* worker pools,
* backpressure,
* semaphores,
* and pipelines.

But once systems become large, a new class of problems appears:

```text
Tasks never finish.
Tasks refuse to stop.
Resources leak.
Workers deadlock.
Queues never drain.
Shutdown hangs forever.
Memory slowly climbs.
```

These are not beginner problems.

These are production problems.

In this chapter, we'll learn the engineering techniques used to prevent async systems from destroying themselves.

---

# Chapter 34 — The Most Dangerous Bug: Infinite Waiting

Consider:

```python
async def fetch():

    return await api_call()
```

Looks harmless.

But what if:

```text
api_call()
```

never returns?

Then:

```text
Task
    ↓
waits forever
    ↓
holds memory forever
    ↓
holds connections forever
    ↓
system slowly dies
```

---

# Real Production Example

```python
response = await websocket.recv()
```

What happens if:

* server crashes?
* packet disappears?
* network cable disconnects?
* peer hangs?

Answer:

```text
wait forever
```

---

# Exercise 1 — Create an Infinite Wait

```python
import asyncio

async def forever():

    await asyncio.Future()

asyncio.run(forever())
```

Questions:

* Does the program exit?
* Does the CPU spike?
* Does memory leak?

---

# Chapter 35 — Timeouts Save Systems

The solution is:

# Timeouts

Instead of:

```python
await api_call()
```

write:

```python
await asyncio.wait_for(
    api_call(),
    timeout=5
)
```

Meaning:

> Wait no longer than 5 seconds.

---

# Example

```python
import asyncio

async def slow():

    await asyncio.sleep(10)

async def main():

    try:

        await asyncio.wait_for(
            slow(),
            timeout=2
        )

    except TimeoutError:

        print("Timed out")

asyncio.run(main())
```

Output:

```text
Timed out
```

---

# Internal Behavior

```text
start task
      |
timer starts
      |
task still running?
      |
yes
      |
cancel task
      |
raise TimeoutError
```

---

# Exercise 2 — Measure Timeouts

Try:

```python
await asyncio.wait_for(
    asyncio.sleep(5),
    timeout=1
)
```

Then:

```python
await asyncio.wait_for(
    asyncio.sleep(5),
    timeout=10
)
```

Questions:

* Which one fails?
* Which one succeeds?
* Why?

---

# Chapter 36 — Cancellation

Every task can be cancelled.

```python
task.cancel()
```

Example:

```python
task = asyncio.create_task(
    worker()
)

task.cancel()
```

But what actually happens?

---

# The Hidden Mechanism

Python does NOT do:

```text
kill thread
destroy stack
terminate immediately
```

Instead:

```text
inject exception
```

Specifically:

```python
asyncio.CancelledError
```

---

# Example

```python
import asyncio

async def worker():

    while True:

        print("working")

        await asyncio.sleep(1)

async def main():

    task = asyncio.create_task(
        worker()
    )

    await asyncio.sleep(3)

    task.cancel()

    await task

asyncio.run(main())
```

Output:

```text
working
working
working
CancelledError
```

---

# Chapter 37 — Cancellation Must Be Handled

Bad:

```python
async def worker():

    while True:

        await work()
```

Good:

```python
async def worker():

    try:

        while True:

            await work()

    except asyncio.CancelledError:

        cleanup()

        raise
```

---

# Why?

Imagine:

```text
download file
open socket
open database
create temp file
```

Cancellation occurs.

Without cleanup:

```text
socket leak
database leak
file leak
memory leak
```

---

# Exercise 3 — Graceful Cancellation

Write:

```python
async def downloader():
```

Requirements:

* infinite loop
* catches cancellation
* closes resources
* logs shutdown
* re-raises exception

---

# Chapter 38 — The Cancellation Tree

Consider:

```text
Parent
    |
    +--- Task A
    |
    +--- Task B
    |
    +--- Task C
```

Parent cancellation:

```text
cancel parent
      ↓
cancel children
      ↓
cleanup children
      ↓
exit
```

This is called:

# Structured Cancellation

---

# Chapter 39 — TaskGroup Cancellation

Example:

```python
import asyncio

async def worker(name):

    try:

        await asyncio.sleep(100)

    finally:

        print(
            f"{name} cleanup"
        )

async def main():

    async with asyncio.TaskGroup() as tg:

        tg.create_task(
            worker("A")
        )

        tg.create_task(
            worker("B")
        )

        raise Exception()

asyncio.run(main())
```

Output:

```text
A cleanup
B cleanup
Exception
```

---

# Exercise 4 — Observe Cancellation Propagation

Modify:

```python
worker()
```

to:

```python
print(
    "cancelled"
)
```

inside:

```python
except CancelledError
```

Observe:

```text
all tasks cancelled
```

---

# Chapter 40 — Waiting Strategies

Python provides several ways to wait.

---

## Wait for One Task

```python
await task
```

---

## Wait for All

```python
await asyncio.gather()
```

---

## Wait for First Completion

```python
done, pending = await asyncio.wait(
    tasks,
    return_when=
        asyncio.FIRST_COMPLETED
)
```

---

## Wait for Timeout

```python
await asyncio.wait_for()
```

---

## Structured Waiting

```python
async with TaskGroup()
```

---

# Exercise 5 — Race Two Tasks

Implement:

```python
google()
bing()
duckduckgo()
```

Requirement:

Return whichever responds first.

Hint:

```python
asyncio.wait(
    return_when=
        FIRST_COMPLETED
)
```

---

# Chapter 41 — Locks

You might think:

> Async has one thread.

Therefore:

> Race conditions disappear.

Wrong.

---

# Example

```python
counter = 0

async def worker():

    global counter

    temp = counter

    await asyncio.sleep(0)

    counter = temp + 1
```

Multiple tasks can still interfere.

---

# Exercise 6 — Create an Async Race Condition

```python
counter = 0

async def worker():

    global counter

    for _ in range(10000):

        temp = counter

        await asyncio.sleep(0)

        counter = temp + 1
```

Run:

```python
await asyncio.gather(
    worker(),
    worker()
)
```

Question:

Why isn't:

```text
20000
```

guaranteed?

---

# Chapter 42 — asyncio.Lock

Solution:

```python
lock = asyncio.Lock()
```

Usage:

```python
async with lock:

    critical_section()
```

Example:

```python
lock = asyncio.Lock()

counter = 0

async def worker():

    global counter

    for _ in range(10000):

        async with lock:

            counter += 1
```

Now:

```text
correct answer
every time
```

---

# Chapter 43 — Events

Events are async signals.

Create:

```python
event = asyncio.Event()
```

Wait:

```python
await event.wait()
```

Signal:

```python
event.set()
```

---

# Example

```python
import asyncio

event = asyncio.Event()

async def waiter():

    print("waiting")

    await event.wait()

    print("resumed")

async def setter():

    await asyncio.sleep(2)

    event.set()

asyncio.run(
    asyncio.gather(
        waiter(),
        setter()
    )
)
```

---

# Exercise 7 — Build an Async Traffic Light

Requirements:

```text
Red
wait

Green
go
```

Use:

```python
asyncio.Event
```

---

# Chapter 44 — Conditions

Conditions combine:

```text
Lock
+
Event
```

Example:

```python
condition = asyncio.Condition()
```

Wait:

```python
async with condition:

    await condition.wait()
```

Notify:

```python
async with condition:

    condition.notify()
```

Useful for:

* worker coordination
* resource pools
* state machines

---

# Chapter 45 — Async Context Managers

Normal:

```python
with open():
```

Async:

```python
async with session:
```

Why?

Because cleanup may require waiting.

Example:

```python
async with aiohttp.ClientSession() as session:

    ...
```

Equivalent:

```python
await acquire()

try:
    ...

finally:
    await release()
```

---

# Exercise 8 — Create an Async Context Manager

Build:

```python
async with Database():
```

Requirements:

* connect
* print
* disconnect

---

# Chapter 46 — Async Generators

Normal generator:

```python
yield
```

Async generator:

```python
async def stream():

    while True:

        await asyncio.sleep(1)

        yield value
```

Usage:

```python
async for item in stream():

    print(item)
```

---

# Example

```python
async def counter():

    for i in range(5):

        await asyncio.sleep(1)

        yield i
```

Usage:

```python
async for x in counter():

    print(x)
```

---

# Exercise 9 — Build a Market Data Feed

Implement:

```text
price stream
     |
yield
     |
consumer
```

Requirements:

* random prices
* every second
* stop after 20 updates

---

# Chapter 47 — The Five Most Common Async Disasters

---

## Disaster #1

```python
time.sleep()
```

inside async.

---

## Disaster #2

```python
requests.get()
```

inside async.

---

## Disaster #3

```python
while True:
    pass
```

inside async.

---

## Disaster #4

```python
create_task()
```

without storing references.

---

## Disaster #5

```python
asyncio.Queue()
```

without:

```python
maxsize
```

---

# Exercise 10 — Find the Bugs

```python
async def fetch():

    while True:

        response = requests.get(url)

        time.sleep(1)

        asyncio.create_task(
            process(response)
        )
```

Find every problem.

---

# Summary

In this article we learned:

✅ timeouts
✅ cancellation
✅ structured cancellation
✅ waiting strategies
✅ locks
✅ events
✅ conditions
✅ async context managers
✅ async generators
✅ common async disasters

---

# Conclusion

Junior developers ask:

> "How do I make async code run?"

Senior engineers ask:

> "How do I guarantee async code eventually stops?"

Because production failures usually come from:

```text
things
that
never
stop
running
```

In **Part 6**, we'll dive into the deepest layer of Python async:

* how the event loop is implemented
* selectors and epoll
* futures
* transports and protocols
* callbacks
* how `await` works internally
* generators vs coroutines
* building a mini event loop
* implementing our own scheduler
* understanding the internals of `asyncio` itself.
