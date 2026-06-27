# 🚀 Python Asyncio Explained Like a Systems Engineer (Part 3):

# How Thousands of Tasks Run on One Thread

> *"The magic of `asyncio` isn't that Python runs thousands of things simultaneously.*
>
> *The magic is that Python remembers exactly where thousands of things stopped."*

---

# Introduction

In Part 2, we learned that:

```python
await something()
```

does **not** mean:

> "wait here."

Instead, it means:

> "I'm done for now. Let someone else run."

This raises a new question:

If a coroutine pauses itself, then:

* who remembers where it stopped?
* who decides which coroutine runs next?
* how do thousands of coroutines share one thread?
* what exactly is a Task?

In this chapter, we'll explore the machinery that turns individual coroutines into a complete asynchronous operating system.

---

# Chapter 13 — Coroutines Are Not Concurrent

This surprises many beginners.

Consider:

```python
import asyncio

async def worker(n):

    print(f"start {n}")

    await asyncio.sleep(1)

    print(f"end {n}")

async def main():

    await worker(1)
    await worker(2)
    await worker(3)

asyncio.run(main())
```

Output:

```text
start 1
end 1

start 2
end 2

start 3
end 3
```

Execution time:

```text
3 seconds
```

Why?

Because:

```text
await worker(1)
      ↓
wait until finished
      ↓
await worker(2)
      ↓
wait until finished
      ↓
await worker(3)
```

This is still sequential.

---

# Exercise 1 — Predict the Runtime

```python
async def A():
    await asyncio.sleep(2)

async def B():
    await asyncio.sleep(2)

async def main():

    await A()
    await B()
```

Question:

```text
Runtime?

2 sec?
4 sec?
```

---

# Chapter 14 — What Is a Task?

A task is a wrapper around a coroutine.

Example:

```python
task = asyncio.create_task(worker())
```

Internally:

```text
Task
 ├── coroutine
 ├── execution state
 ├── result
 ├── exception
 ├── cancellation flag
 ├── callbacks
 └── scheduler metadata
```

Think of a task as:

```text
Coroutine
     +
Bookmark
     +
Control Panel
```

The bookmark remembers:

> where execution should resume.

---

# Visual Example

Suppose:

```python
async def worker():

    print("A")

    await asyncio.sleep(5)

    print("B")
```

Task state:

```text
Task
    |
    +--- current instruction:
            await sleep()
    |
    +--- resume point:
            print("B")
```

---

# Chapter 15 — Creating Tasks

To create concurrency:

```python
import asyncio

async def worker(n):

    print(f"start {n}")

    await asyncio.sleep(1)

    print(f"end {n}")

async def main():

    t1 = asyncio.create_task(worker(1))
    t2 = asyncio.create_task(worker(2))
    t3 = asyncio.create_task(worker(3))

    await t1
    await t2
    await t3

asyncio.run(main())
```

Output:

```text
start 1
start 2
start 3

end 1
end 2
end 3
```

Execution:

```text
≈ 1 second
```

instead of:

```text
≈ 3 seconds
```

---

# What Actually Happened?

Timeline:

```text
Time 0

Task1 start
Task2 start
Task3 start

All tasks:
await sleep()

Event loop:
nothing ready

Time 1

resume task1
resume task2
resume task3
```

---

# Exercise 2 — Create 100 Tasks

```python
import asyncio

async def worker(i):

    await asyncio.sleep(1)

    return i

async def main():

    tasks = []

    for i in range(100):
        tasks.append(
            asyncio.create_task(
                worker(i)
            )
        )

    results = []

    for task in tasks:
        results.append(
            await task
        )

    print(len(results))

asyncio.run(main())
```

Questions:

* How long does this run?
* Why doesn't it take 100 seconds?
* How much memory does it consume?

---

# Chapter 16 — Scheduling

The event loop scheduler works roughly like this:

```python
while True:

    ready = get_ready_tasks()

    for task in ready:

        task.resume()
```

Imagine:

```text
READY QUEUE

Task A
Task B
Task C
Task D
```

Execution:

```text
Run A
Run B
Run C
Run D
```

If A blocks:

```text
A → waiting queue
```

Continue:

```text
Run B
Run C
Run D
```

---

# Visual Timeline

```text
Time

A: RUN ----- WAIT -------- RUN
B: RUN -- WAIT -- RUN
C: RUN -------- WAIT ---- RUN
```

Notice:

```text
One thread
Many tasks
```

---

# Exercise 3 — Observe Scheduling

```python
import asyncio

async def worker(name):

    print(f"{name}: start")

    await asyncio.sleep(1)

    print(f"{name}: resume")

async def main():

    await asyncio.gather(
        worker("A"),
        worker("B"),
        worker("C")
    )

asyncio.run(main())
```

Questions:

* Why do all tasks start immediately?
* Why do they resume later?
* Who resumes them?

---

# Chapter 17 — `asyncio.gather()`

This is the first major coordination primitive.

Example:

```python
results = await asyncio.gather(
    fetch_user(),
    fetch_orders(),
    fetch_products()
)
```

Execution:

```text
create task 1
create task 2
create task 3

run concurrently

wait for all
```

Result:

```python
[
    user,
    orders,
    products
]
```

---

# Exercise 4 — Sequential vs Gather

Sequential:

```python
await api1()
await api2()
await api3()
```

Concurrent:

```python
await asyncio.gather(
    api1(),
    api2(),
    api3()
)
```

Experiment:

```python
async def api():

    await asyncio.sleep(1)
```

Measure:

* sequential runtime
* gather runtime

---

# Chapter 18 — The Problem with `gather()`

Suppose:

```python
await asyncio.gather(
    good(),
    bad(),
    good()
)
```

and:

```python
bad()
```

raises:

```python
ValueError()
```

What happens?

Many people assume:

```text
all tasks stop
```

Wrong.

Actual behavior:

```text
task A continues
task B crashes
task C continues
exception propagates
```

This can create inconsistent systems.

---

# Demonstration

```python
import asyncio

async def good():

    await asyncio.sleep(3)

    print("good")

async def bad():

    await asyncio.sleep(1)

    raise Exception("boom")

async def main():

    await asyncio.gather(
        good(),
        bad(),
        good()
    )

asyncio.run(main())
```

Observe carefully.

---

# Exercise 5 — Preserve Exceptions

Modify:

```python
await asyncio.gather(...)
```

using:

```python
return_exceptions=True
```

Expected:

```python
[
    "success",
    Exception(...),
    "success"
]
```

---

# Chapter 19 — The Birth of Structured Concurrency

Traditional async:

```text
Parent
   |
Task A
Task B
Task C
```

Problem:

```text
Task B crashes
Task A survives
Task C survives
```

Result:

```text
system partially broken
```

---

# Structured Concurrency

Rule:

> Children succeed together.
>
> Children fail together.

---

# Chapter 20 — TaskGroup

Python 3.11 introduced:

```python
asyncio.TaskGroup
```

Example:

```python
import asyncio

async def worker(name, sec):

    await asyncio.sleep(sec)

    print(name)

async def main():

    async with asyncio.TaskGroup() as tg:

        tg.create_task(
            worker("A",1)
        )

        tg.create_task(
            worker("B",2)
        )

        tg.create_task(
            worker("C",3)
        )

asyncio.run(main())
```

---

# Exercise 6 — Cause Failure

Modify:

```python
if name == "B":
    raise Exception()
```

Observe:

```text
A completes
B crashes
C cancelled
```

Question:

Why is this safer?

---

# Chapter 21 — Task Cancellation

Every task can be cancelled.

```python
task.cancel()
```

Internally:

```text
inject CancelledError
allow cleanup
terminate task
```

---

# Example

```python
import asyncio

async def worker():

    try:

        while True:

            print("working")

            await asyncio.sleep(1)

    except asyncio.CancelledError:

        print("cleanup")

        raise

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
cleanup
```

---

# Exercise 7 — Build a Graceful Shutdown

Create:

```text
Producer
     |
Queue
     |
Consumer
```

Requirements:

* infinite producer
* consumer worker
* cancellation handling
* cleanup code
* graceful exit

---

# Chapter 22 — Fire-and-Forget Is Dangerous

Bad:

```python
asyncio.create_task(
    background()
)
```

Why?

Because:

```text
task reference lost
```

Possible result:

```text
task crashes
nobody notices
```

---

# Better:

```python
tasks = []

tasks.append(
    asyncio.create_task(
        background()
    )
)
```

Or:

```python
async with TaskGroup():
```

---

# Chapter 23 — Waiting Strategies

You have several options.

---

## Wait for one

```python
await task
```

---

## Wait for all

```python
await asyncio.gather()
```

---

## Wait for some

```python
done, pending = await asyncio.wait()
```

---

## Wait with timeout

```python
await asyncio.wait_for()
```

---

## Structured waiting

```python
async with TaskGroup()
```

---

# Exercise 8 — Compare Waiting Methods

Implement:

* await
* gather
* wait
* wait_for
* TaskGroup

Measure:

* behavior
* exceptions
* cancellation
* performance

---

# Summary

In this article we learned:

✅ coroutines are not concurrent
✅ tasks create concurrency
✅ the event loop schedules tasks
✅ `gather()` coordinates tasks
✅ `TaskGroup` creates structured concurrency
✅ tasks can be cancelled
✅ fire-and-forget is dangerous

---

# Conclusion

The most important lesson is:

> Coroutines describe work.
>
> Tasks schedule work.

Without tasks:

```python
await A()
await B()
await C()
```

you still have sequential execution.

With tasks:

```python
create_task(A())
create_task(B())
create_task(C())
```

you get concurrency.

In Part 4, we'll move beyond individual tasks and explore how production systems coordinate thousands of tasks using:

* `asyncio.Queue`
* producer-consumer systems
* worker pools
* backpressure
* semaphores
* rate limiting
* async pipelines
* streaming architectures
* high-throughput system design.
