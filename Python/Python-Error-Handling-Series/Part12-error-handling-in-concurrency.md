# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 12)

# Error Handling in Concurrency: Threads, Futures, Executors, Deadlocks, and Failure Propagation

> *"Single-threaded errors are easy.*
>
> *Concurrent errors are where software engineering becomes systems engineering."*

---

# Introduction

Consider this code:

```python
def divide():
    return 1 / 0

divide()
```

Easy.

Python prints:

```text
ZeroDivisionError
```

Now consider:

```python
import threading

def divide():
    return 1 / 0

thread = threading.Thread(
    target=divide
)

thread.start()

print("done")
```

Question:

Where did the exception go?

Answer:

> Somewhere else.

Welcome to one of the most confusing parts of Python:

# Concurrent Error Handling

Because once you introduce:

* threads,
* processes,
* futures,
* executors,
* async tasks,

you no longer have:

```text
one execution path
```

You have:

```text
many independent failure domains
```

---

# Chapter 151 — Why Concurrent Exceptions Are Different

Single-threaded execution:

```text
A
|
B
|
C
|
Exception
```

Simple.

---

Threaded execution:

```text
Thread A
     |
     V
 Exception


Thread B
     |
 Continue
```

Question:

Who owns the exception?

---

Example:

```python
import threading

def worker():

    raise ValueError(
        "boom"
    )

t = threading.Thread(
    target=worker
)

t.start()
t.join()

print("finished")
```

Output:

```text
Exception in thread...
finished
```

Notice:

```text
program continues
```

---

# Exercise 1

Why doesn't:

```python
try:
    thread.start()
except:
    ...
```

catch thread exceptions?

---

# Chapter 152 — Exceptions Stay Inside Threads

Consider:

```python
import threading

def worker():

    raise RuntimeError(
        "failure"
    )

try:

    t = threading.Thread(
        target=worker
    )

    t.start()
    t.join()

except Exception:

    print("caught")
```

Output:

```text
RuntimeError

caught never executes
```

---

Why?

Because:

```text
each thread has its own stack
```

---

Visualization:

```text
Main Stack

A
B
C


Worker Stack

X
Y
Z
Exception
```

---

# Exercise 2

Create two threads:

* one crashes
* one succeeds

Observe behavior.

---

# Chapter 153 — Thread Exception Hooks (Python 3.8+)

Python introduced:

```python
threading.excepthook
```

Example:

```python
import threading

def hook(args):

    print(
        "thread failed:",
        args.exc_type
    )

threading.excepthook = hook
```

---

Example:

```python
def worker():

    raise ValueError()

threading.Thread(
    target=worker
).start()
```

Output:

```text
thread failed:
ValueError
```

---

Visualization:

```text
Thread
   |
Exception
   |
excepthook
```

---

# Exercise 3

Log:

* thread name
* exception type
* traceback

inside:

```python
threading.excepthook
```

---

# Chapter 154 — Futures Solve Exception Propagation

Enter:

```python
concurrent.futures
```

Example:

```python
from concurrent.futures import \
    ThreadPoolExecutor
```

---

Code:

```python
def worker():

    return 1/0

with ThreadPoolExecutor() as pool:

    future = pool.submit(
        worker
    )
```

No exception yet.

---

The exception is stored.

---

Retrieve:

```python
future.result()
```

Output:

```text
ZeroDivisionError
```

---

Visualization:

```text
Worker
   |
Exception
   |
Future
   |
result()
```

---

# Exercise 4

Create three futures:

* success
* timeout
* exception

---

# Chapter 155 — Futures Are Deferred Exceptions

Example:

```python
def fail():

    raise ValueError()

future = pool.submit(
    fail
)

print(
    future.done()
)
```

Output:

```text
True
```

---

Inspect:

```python
future.exception()
```

Output:

```text
ValueError(...)
```

---

Retrieve:

```python
future.result()
```

↓

```text
raises ValueError
```

---

# Visualization

```text
Exception
      |
Stored
      |
Retrieved
```

---

# Exercise 5

Compare:

```python
future.exception()
```

versus:

```python
future.result()
```

---

# Chapter 156 — Process Pool Exceptions

Example:

```python
from concurrent.futures import \
    ProcessPoolExecutor
```

---

Code:

```python
def worker():

    raise RuntimeError(
        "boom"
    )

with ProcessPoolExecutor() as p:

    future = p.submit(
        worker
    )

    future.result()
```

Output:

```text
RuntimeError
```

---

Question:

How?

Because:

```text
exceptions are serialized
```

between processes.

---

Visualization:

```text
Child Process
        |
Serialize
        |
Parent Process
        |
Reconstruct
```

---

# Exercise 6

Raise custom exceptions in a process pool.

---

# Chapter 157 — Exception Fan-Out

Suppose:

```python
100 workers
```

run simultaneously.

Question:

What if:

```text
20 fail?
```

---

Example:

```python
futures = [

    pool.submit(work)

    for _ in range(100)
]
```

Now:

```text
100 results
20 exceptions
```

---

You need:

```text
aggregation
```

---

Example:

```python
errors = []

for f in futures:

    try:

        f.result()

    except Exception as e:

        errors.append(e)
```

---

# Exercise 7

Aggregate worker failures.

---

# Chapter 158 — Exception Fan-In

Sometimes:

```text
any failure
=
whole operation fails
```

Example:

```text
Payment
Inventory
Shipping
```

If one fails:

```text
abort all
```

---

Visualization:

```text
A ✓
B ✓
C X

Result:
FAIL
```

---

Example:

```python
if errors:

    raise RuntimeError(
        errors
    )
```

---

# Exercise 8

Implement fail-fast behavior.

---

# Chapter 159 — Deadlocks Are Error Handling Failures

Consider:

```python
lock1.acquire()
lock2.acquire()
```

Thread two:

```python
lock2.acquire()
lock1.acquire()
```

Result:

```text
deadlock
```

---

Visualization:

```text
T1 waits for T2

T2 waits for T1
```

---

Neither crashes.

Both freeze.

---

# Exercise 9

Create a deadlock.

Then fix it.

---

# Chapter 160 — Timeout As Deadlock Detection

Example:

```python
lock.acquire(
    timeout=5
)
```

Output:

```text
False
```

instead of:

```text
hang forever
```

---

Visualization:

```text
Acquire
    |
Wait
    |
Timeout?
```

---

# Exercise 10

Add timeouts to locks.

---

# Chapter 161 — Thread Cancellation Doesn't Exist

Question:

How do we stop a thread?

Answer:

```text
You generally can't.
```

---

Example:

```python
thread.stop()
```

does not exist.

---

Instead:

```python
stop_event = threading.Event()
```

---

Worker:

```python
while not stop_event.is_set():

    work()
```

---

Controller:

```python
stop_event.set()
```

---

Visualization:

```text
Controller
     |
Signal
     |
Worker
```

---

# Exercise 11

Implement cooperative cancellation.

---

# Chapter 162 — Executor Shutdown

Example:

```python
executor.shutdown()
```

Options:

```python
shutdown()

shutdown(wait=True)

shutdown(cancel_futures=True)
```

---

Visualization:

```text
Submit
   |
Shutdown
   |
Cancel?
```

---

# Exercise 12

Experiment with:

```python
cancel_futures=True
```

---

# Chapter 163 — Failure Containment In Thread Pools

Bad:

```text
One worker dies
Entire service dies
```

---

Good:

```text
Worker dies
Task retried
Pool survives
```

---

Visualization:

```text
Pool
 |
 +---Worker X
 |
 +---Worker ✓
 |
 +---Worker ✓
```

---

Example:

```python
try:

    future.result()

except:

    retry()
```

---

# Exercise 13

Implement worker retries.

---

# Chapter 164 — Error Boundaries For Concurrent Systems

Each worker should define:

```text
what fails
what propagates
what recovers
```

---

Example:

```python
def worker():

    try:

        process()

    except Retryable:

        retry()

    except Fatal:

        raise
```

---

Visualization:

```text
Failure
    |
Retryable?
   / \
yes no
 |    |
retry propagate
```

---

# Exercise 14

Design worker exception policies.

---

# Chapter 165 — Concurrent Failures Become Failure Graphs

Single-thread:

```text
Failure
```

---

Concurrent:

```text
Failure A
     |
Failure B

Failure C
     |
Failure D
```

---

Example:

```text
Database timeout
        |
Payment timeout

Inventory timeout
        |
Checkout failure
```

---

Now debugging becomes:

```text
graph traversal
```

not:

```text
stack traversal
```

---

# The Concurrent Failure Model

```text
Thread
    |
Task
    |
Future
    |
Exception
    |
Aggregation
    |
Recovery
```

---

# The Concurrent Recovery Pipeline

```text
Failure
    |
Capture
    |
Serialize
    |
Aggregate
    |
Classify
    |
Recover
```

---

# The Most Important Diagram In Concurrent Error Handling

```text
Worker
    |
Failure
    |
Future
    |
Aggregation
    |
Classification
    |
Recovery
    |
Observability
```

---

# Summary

In this article we learned:

✅ thread exceptions
✅ thread-local stacks
✅ `threading.excepthook`
✅ futures
✅ deferred exceptions
✅ process exceptions
✅ exception aggregation
✅ fail-fast design
✅ deadlocks
✅ timeout detection
✅ cooperative cancellation
✅ failure containment

---

# Conclusion

Most developers think:

> Concurrency means running things in parallel.

Professional engineers understand:

> **Concurrency means managing multiple simultaneous failures.**

Because once you have:

* 10 threads,
* 100 futures,
* 1000 workers,

you're no longer debugging:

> a program.

You're debugging:

> **an ecosystem of interacting failure domains.**

In **Part 13**, we'll tackle perhaps the hardest topic in modern Python:

* `asyncio`,
* task failures,
* cancellation,
* `CancelledError`,
* `TaskGroup`,
* structured concurrency,
* exception groups,
* and why asynchronous error handling forced Python to redesign exceptions themselves. 🚨
