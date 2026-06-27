# 🚀 Python Asyncio Explained Like a Systems Engineer (Part 2):

# What Actually Happens When You Write `await`?

> *"The single most important thing to understand about async programming is this:*
>
> ***`await` does not wait.***
>
> *It gives somebody else permission to run."*

---

# Introduction

In Part 1, we learned:

* why asynchronous programming exists,
* why computers spend most of their time waiting,
* why threads become expensive,
* and why `asyncio` was invented.

We concluded with an important observation:

> Async programming is not about making your code faster.
>
> It's about preventing your program from wasting time.

But this raises a much more interesting question:

```python
await something()
```

What actually happens here?

Does Python:

* pause the CPU?
* pause the thread?
* create another thread?
* create another process?
* suspend the entire program?

The answer is:

> None of the above.

To understand async, we must understand the **event loop**.

---

# Chapter 6 — Meet the Event Loop

The event loop is the operating system of your async program.

Imagine you're running a restaurant.

You have:

* one waiter,
* twenty tables,
* and hundreds of customers.

A terrible waiter works like this:

```text
Take order
Stand still
Wait
Wait
Wait
Deliver food
```

A good waiter works like this:

```text
Take order
Visit another table
Take another order
Deliver food
Visit another table
Return later
```

This is exactly what the event loop does.

---

# The Simplified Event Loop

Conceptually:

```python
while True:

    ready_tasks = get_ready_tasks()

    for task in ready_tasks:
        execute(task)
```

The loop continuously asks:

```text
Who is ready?

Who is waiting?

Who finished?

Who timed out?

Who was cancelled?
```

---

# Exercise 1 — Build a Tiny Event Loop

Try to understand this simplified scheduler:

```python
tasks = [
    "task1",
    "task2",
    "task3"
]

while tasks:

    task = tasks.pop(0)

    print(f"Running {task}")

    finished = False

    if not finished:
        tasks.append(task)
```

Questions:

1. Why does every task eventually run?
2. Why doesn't one task monopolize execution?
3. How is this similar to the event loop?

---

# Chapter 7 — Coroutines Are Not Functions

Consider:

```python
def hello():
    return "hello"
```

Calling it:

```python
hello()
```

Immediately executes:

```text
enter function
execute
return
done
```

---

Now consider:

```python
async def hello():
    return "hello"
```

Calling:

```python
hello()
```

Produces:

```text
<coroutine object>
```

Nothing executed.

This surprises almost every beginner.

---

# Demonstration

```python
import asyncio

async def hello():

    print("running")

    return 123

coro = hello()

print(coro)
```

Output:

```text
<coroutine object hello at 0x...>
```

Notice:

```text
"running"
```

never appeared.

---

# Why?

Because:

```text
async function
        ≠
executing function
```

Instead:

```text
async function
        ↓
creates coroutine object
        ↓
event loop executes coroutine
```

---

# Exercise 2 — Predict the Output

```python
async def test():
    print("A")

x = test()

print("B")
```

Question:

What prints?

```text
?
```

---

# Chapter 8 — Coroutines Are State Machines

This is the hidden secret of async.

Suppose we write:

```python
async def worker():

    print("A")

    await asyncio.sleep(5)

    print("B")
```

Python transforms this into something conceptually similar to:

```python
class Worker:

    state = 0

    def resume(self):

        if self.state == 0:

            print("A")

            self.state = 1

            return

        if self.state == 1:

            print("B")

            return
```

---

# Visualizing Execution

Initial state:

```text
state = 0
```

Execute:

```text
print("A")
```

Pause:

```text
state = 1
```

Later:

```text
resume()
```

Continue:

```text
print("B")
```

This is how Python remembers where to continue execution.

---

# Exercise 3 — Draw the State Machine

Convert:

```python
async def calculate():

    print("step1")

    await asyncio.sleep(1)

    print("step2")

    await asyncio.sleep(1)

    print("step3")
```

Into a state diagram:

```text
State 0
   ↓
State 1
   ↓
State 2
   ↓
Finished
```

---

# Chapter 9 — What Does `await` Actually Do?

This line:

```python
await asyncio.sleep(5)
```

does NOT mean:

```text
sleep entire program
```

It means:

```text
pause this coroutine
save its execution state
return control to event loop
execute something else
resume later
```

---

# Timeline Example

Suppose:

```python
async def A():

    print("A1")

    await asyncio.sleep(3)

    print("A2")

async def B():

    print("B1")

    await asyncio.sleep(1)

    print("B2")
```

Execution:

```text
Time 0

A1
B1

Time 1

B2

Time 3

A2
```

Total runtime:

```text
3 seconds
```

not:

```text
4 seconds
```

---

# Exercise 4 — Predict the Output

```python
import asyncio

async def A():

    print("A")

    await asyncio.sleep(2)

    print("AA")

async def B():

    print("B")

    await asyncio.sleep(1)

    print("BB")

async def main():

    await asyncio.gather(
        A(),
        B()
    )

asyncio.run(main())
```

Write the exact output order before running it.

---

# Chapter 10 — `asyncio.run()`

Most tutorials say:

```python
asyncio.run(main())
```

but never explain what it does.

Internally:

```text
create event loop
        ↓
create task
        ↓
start scheduler
        ↓
execute tasks
        ↓
wait for completion
        ↓
cleanup resources
        ↓
destroy event loop
```

Conceptually:

```python
loop = EventLoop()

loop.run(main())

loop.close()
```

---

# Exercise 5 — Observe the Event Loop

```python
import asyncio

async def worker():

    print("running")

async def main():

    loop = asyncio.get_running_loop()

    print(loop)

    await worker()

asyncio.run(main())
```

Questions:

* What object is printed?
* Why is there only one event loop?
* Who owns the loop?

---

# Chapter 11 — Why `time.sleep()` Breaks Async

Beginners often write:

```python
async def worker():

    print("start")

    time.sleep(5)

    print("end")
```

This is disastrous.

Why?

Because:

```text
time.sleep()
        ↓
blocks thread
        ↓
blocks event loop
        ↓
blocks ALL tasks
```

---

# Example

```python
import asyncio
import time

async def A():

    print("A")

    time.sleep(5)

    print("AA")

async def B():

    print("B")

    await asyncio.sleep(1)

    print("BB")

asyncio.run(
    asyncio.gather(
        A(),
        B()
    )
)
```

Output:

```text
A
(wait 5 sec)
AA
B
(wait 1 sec)
BB
```

Notice:

```text
B never ran concurrently.
```

---

# The Correct Version

```python
async def A():

    print("A")

    await asyncio.sleep(5)

    print("AA")
```

Now:

```text
A
B
BB
AA
```

---

# Exercise 6 — Find the Bug

Which line breaks async?

```python
async def fetch():

    response = requests.get(url)

    return response.text
```

Hint:

```text
requests
```

is not asynchronous.

---

# Chapter 12 — Cooperative Scheduling

Async is called:

# Cooperative Multitasking

Because tasks voluntarily surrender control.

Example:

```python
async def worker():

    while True:

        await asyncio.sleep(0)
```

The coroutine says:

> I'm willing to let others execute.

If you never yield:

```python
async def bad():

    while True:
        pass
```

then:

```text
event loop freezes
all tasks freeze
program freezes
```

---

# Exercise 7 — Freeze the Event Loop

Try:

```python
async def freeze():

    while True:
        pass

asyncio.run(freeze())
```

Question:

Why can't the event loop recover?

---

# Summary

In this article we learned:

✅ what the event loop actually is
✅ why coroutines are not functions
✅ how Python transforms coroutines into state machines
✅ what `await` really does
✅ why `time.sleep()` breaks async
✅ why async is cooperative multitasking

The most important realization is:

> `await` does not wait.
>
> `await` yields.

---

# Conclusion

Most async tutorials teach:

```python
async
await
gather
create_task
```

But underneath all of those APIs is one simple mechanism:

```text
pause current task
save execution state
run something else
resume later
```

That's it.

Everything else in `asyncio`—tasks, gather, TaskGroups, queues, semaphores, cancellation—is built on top of this one idea.

In Part 3, we'll move from understanding individual coroutines to understanding **how multiple coroutines run together**, covering:

* `create_task()`
* `asyncio.gather()`
* `TaskGroup`
* structured concurrency
* task scheduling
* exception propagation
* cancellation propagation
* production task orchestration.
