# 🚀 Python Asyncio Explained Like a Systems Engineer (Part 4):

# Building Real Systems with Queues, Worker Pools, and Backpressure

> *"Individual async tasks are interesting.*
>
> *But real-world async systems are built from queues, workers, and controlled chaos."*

---

# Introduction

In Part 3, we learned:

* coroutines describe work,
* tasks schedule work,
* the event loop coordinates execution,
* `gather()` runs tasks concurrently,
* `TaskGroup` provides structured concurrency,
* and cancellation enables graceful shutdown.

But real applications rarely look like this:

```python
await asyncio.gather(
    task1(),
    task2(),
    task3()
)
```

Real systems look more like:

```text
Incoming Requests
        |
        V
     Queue
        |
        V
   Worker Pool
        |
        V
 Processing
        |
        V
 Database
```

Examples:

* web crawlers
* trading systems
* chat servers
* ETL pipelines
* AI inference services
* event processing systems
* message brokers

The fundamental building block of all of these systems is:

# The Queue

---

# Chapter 24 — Why Direct Communication Doesn't Scale

Suppose we write:

```python
async def producer():

    while True:
        data = await fetch()

        await consumer(data)
```

Looks reasonable.

However:

```text
Producer
     |
     V
Consumer
```

This creates tight coupling.

Problems:

* producer must wait for consumer
* producer cannot outpace consumer
* consumer failures affect producer
* difficult to scale
* impossible to load balance

---

# Real Systems Use Buffers

Instead:

```text
Producer
     |
     V
   Queue
     |
     V
Consumer
```

Advantages:

✅ decoupling
✅ buffering
✅ fault isolation
✅ load balancing
✅ backpressure
✅ scalability

---

# Exercise 1 — Visualize the Problem

Suppose:

```text
Producer:
100 items/sec

Consumer:
10 items/sec
```

Questions:

1. What happens without a queue?
2. What happens with an unlimited queue?
3. What happens with a bounded queue?

---

# Chapter 25 — Meet `asyncio.Queue`

Create a queue:

```python
import asyncio

queue = asyncio.Queue()
```

Put data:

```python
await queue.put(item)
```

Retrieve data:

```python
item = await queue.get()
```

Signal completion:

```python
queue.task_done()
```

Wait for all work:

```python
await queue.join()
```

---

# Visual Model

```text
        Queue

+-------------------+
| A | B | C | D | E |
+-------------------+

 put() --->

 <--- get()
```

---

# Chapter 26 — Your First Producer Consumer System

Producer:

```python
import asyncio

async def producer(queue):

    for i in range(5):

        print(f"Produced {i}")

        await queue.put(i)

        await asyncio.sleep(1)
```

Consumer:

```python
async def consumer(queue):

    while True:

        item = await queue.get()

        print(f"Consumed {item}")

        queue.task_done()
```

Main:

```python
async def main():

    queue = asyncio.Queue()

    producer_task = asyncio.create_task(
        producer(queue)
    )

    consumer_task = asyncio.create_task(
        consumer(queue)
    )

    await producer_task

    await queue.join()

    consumer_task.cancel()

asyncio.run(main())
```

---

# Exercise 2 — Observe Queue Behavior

Modify:

```python
await asyncio.sleep()
```

in:

* producer
* consumer

Questions:

* what happens if producer is faster?
* what happens if consumer is faster?
* does data get lost?

---

# Chapter 27 — The Infinite Consumer Problem

Consider:

```python
while True:

    item = await queue.get()
```

How does the consumer know:

```text
"There is no more work."
```

It doesn't.

This is called:

# The Shutdown Problem

---

# Sentinel Values

Solution:

```python
STOP = None
```

Producer:

```python
await queue.put(STOP)
```

Consumer:

```python
if item is STOP:

    queue.task_done()

    break
```

---

# Example

Producer:

```python
async def producer(queue):

    for i in range(5):

        await queue.put(i)

    await queue.put(None)
```

Consumer:

```python
async def consumer(queue):

    while True:

        item = await queue.get()

        if item is None:

            queue.task_done()

            break

        print(item)

        queue.task_done()
```

---

# Exercise 3 — Multiple Consumers

Create:

```text
Producer
    |
    V
 Queue
  / | \
 /  |  \
C1 C2 C3
```

Questions:

* how many sentinels are required?
* why?

---

# Chapter 28 — Worker Pools

Real systems use worker pools.

Example:

```text
          Queue

      /     |     \
     /      |      \
    V       V       V

 Worker1 Worker2 Worker3
```

Benefits:

* parallel task processing
* load balancing
* fault isolation
* predictable resource usage

---

# Example Worker Pool

Worker:

```python
async def worker(name, queue):

    while True:

        item = await queue.get()

        if item is None:

            queue.task_done()

            break

        print(
            f"{name}: {item}"
        )

        await asyncio.sleep(1)

        queue.task_done()
```

Create workers:

```python
workers = [

    asyncio.create_task(
        worker(
            f"W{i}",
            queue
        )
    )

    for i in range(5)
]
```

---

# Exercise 4 — Build a Worker Pool

Requirements:

* 100 jobs
* 5 workers
* each job sleeps 1 second

Question:

Should runtime be:

```text
100 seconds?
20 seconds?
5 seconds?
```

Explain why.

---

# Chapter 29 — The Hidden Danger: Unlimited Queues

Most beginners write:

```python
queue = asyncio.Queue()
```

This means:

```text
maximum size = infinity
```

Suppose:

```text
Producer:
10000/sec

Consumer:
100/sec
```

Memory usage:

```text
0
10000
20000
50000
100000
500000
...
```

Eventually:

```text
OOM
```

(out of memory)

---

# Exercise 5 — Crash Your Program

Try:

```python
queue = asyncio.Queue()
```

Producer:

```python
while True:
    await queue.put(object())
```

Consumer:

```python
await asyncio.sleep(1)
```

Observe memory growth.

---

# Chapter 30 — Backpressure

Backpressure means:

> Slow producers down when consumers cannot keep up.

Solution:

```python
queue = asyncio.Queue(
    maxsize=100
)
```

Now:

```text
Producer
    |
queue full
    |
producer waits
    |
consumer catches up
```

---

# Visualization

Without backpressure:

```text
Producer >>>>>>>>>>>>>>

Consumer >>
```

Memory:

```text
∞
```

---

With backpressure:

```text
Producer >>>>

Consumer >>>
```

Memory:

```text
constant
```

---

# Exercise 6 — Add Backpressure

Create:

```python
queue = asyncio.Queue(
    maxsize=5
)
```

Observe:

```python
await queue.put()
```

Questions:

* when does producer block?
* why doesn't memory grow?

---

# Chapter 31 — Semaphores

Suppose:

```text
10000 URLs
```

API limit:

```text
Maximum 50 concurrent requests
```

Without limits:

```text
429 Too Many Requests
```

---

# Solution

```python
sem = asyncio.Semaphore(50)
```

Usage:

```python
async with sem:

    await fetch()
```

Guarantee:

```text
Never exceed
50 concurrent operations
```

---

# Example

```python
import asyncio

sem = asyncio.Semaphore(3)

async def worker(n):

    async with sem:

        print(
            f"start {n}"
        )

        await asyncio.sleep(2)

        print(
            f"end {n}"
        )

async def main():

    await asyncio.gather(*[
        worker(i)
        for i in range(10)
    ])

asyncio.run(main())
```

Observe:

```text
Only 3 active workers.
```

---

# Exercise 7 — Rate Limited Downloader

Build:

```text
100 URLs
     |
Semaphore(10)
     |
Downloader
```

Requirements:

* maximum 10 concurrent
* timeout
* retry
* error logging

---

# Chapter 32 — Pipelines

Large systems use pipelines.

Example:

```text
Downloader
     |
Parser
     |
Transformer
     |
Database
```

Each stage:

```python
asyncio.Queue()
```

---

# Example Architecture

```text
              Download Queue
                     |
                     V
             Download Workers
                     |
                     V
               Parse Queue
                     |
                     V
               Parser Workers
                     |
                     V
            Transform Queue
                     |
                     V
            Database Workers
```

Advantages:

* isolation
* scaling
* fault tolerance
* monitoring
* backpressure

---

# Exercise 8 — Build a Three-Stage Pipeline

Implement:

```text
Stage 1:
download

Stage 2:
parse

Stage 3:
save
```

Requirements:

* queue per stage
* multiple workers
* graceful shutdown
* statistics collection

---

# Chapter 33 — Async Architecture Patterns

---

## Web Scraper

```text
URL Generator
       |
       V
    Queue
       |
       V
100 Downloaders
       |
       V
Parser Pool
       |
       V
Database
```

---

## Trading System

```text
Market Feed
       |
       V
Normalizer
       |
       V
Strategy Engine
       |
       V
Risk Engine
       |
       V
Order Router
```

---

## AI Serving System

```text
HTTP Requests
       |
       V
Request Queue
       |
       V
Batch Scheduler
       |
       V
GPU Workers
       |
       V
Response Cache
```

---

## ETL System

```text
Extract
    |
Transform
    |
Validate
    |
Load
```

---

# Summary

In this article we learned:

✅ why queues exist
✅ producer-consumer architecture
✅ worker pools
✅ graceful shutdown
✅ sentinel values
✅ backpressure
✅ bounded queues
✅ semaphores
✅ rate limiting
✅ async pipelines

---

# Conclusion

Most beginners think async is about:

```python
async def
await
create_task
```

Experienced engineers know that async is really about:

```text
Queues
Workers
Backpressure
Rate Limiting
Pipelines
Graceful Shutdown
```

Because once your system grows beyond a few tasks, the real challenge is no longer:

> "How do I run things concurrently?"

The real challenge becomes:

> "How do I stop my concurrent system from destroying itself?"

In **Part 5**, we'll explore advanced async engineering topics:

* timeouts
* cancellation
* `asyncio.wait_for()`
* `asyncio.wait()`
* locks
* events
* conditions
* async context managers
* async generators
* debugging async systems
* diagnosing deadlocks
* production observability
* common async disasters and how to avoid them.
