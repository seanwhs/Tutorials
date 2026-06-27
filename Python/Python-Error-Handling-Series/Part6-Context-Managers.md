# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 6)

# Context Managers, `with`, `__enter__`, and `__exit__`: Engineering Failure-Safe Systems

> *"Most developers think `with` is a shortcut for `open()`.*
>
> *Professional engineers know that context managers are Python's mechanism for guaranteeing correctness in the presence of failure."*

---

# Introduction

Consider this code:

```python
file = open("data.txt")

data = file.read()

process(data)

file.close()
```

Looks fine.

Until:

```python
process(data)
```

throws:

```text
ValueError
```

Now:

```python
file.close()
```

never runs.

Congratulations.

You just leaked a resource.

Now replace:

```text
file
```

with:

* database transaction,
* network socket,
* cloud connection,
* payment authorization,
* distributed lock,
* GPU allocation,
* Kubernetes lease.

Suddenly:

```text
resource leak
```

becomes:

```text
production incident
```

This is why context managers exist.

---

# Chapter 63 — The Fundamental Problem

Consider:

```python
conn = connect()

result = conn.query()

conn.close()
```

Question:

What happens if:

```python
conn.query()
```

fails?

---

Execution:

```text
connect
    |
query
    |
EXCEPTION
    |
program jumps away
```

Result:

```text
close() never runs
```

---

# Exercise 1

Find every possible leak:

```python
file = open("data.txt")

data = file.read()

json.loads(data)

file.close()
```

---

# Chapter 64 — The Traditional Solution: `finally`

Before context managers:

```python
file = open("data.txt")

try:

    process(file)

finally:

    file.close()
```

---

Execution:

```text
try
   |
success
   |
finally


try
   |
exception
   |
finally
```

---

This works.

But imagine:

```python
db = connect()
lock = acquire()
file = open()
```

Now:

```python
try:

    ...

finally:

    file.close()
    release(lock)
    db.close()
```

This quickly becomes ugly.

---

# Exercise 2

Add cleanup for:

* database
* file
* socket

using only:

```python
finally
```

---

# Chapter 65 — Enter The Context Manager

Python introduces:

```python
with
```

Example:

```python
with open("data.txt") as file:

    data = file.read()
```

This guarantees:

```text
open
    |
execute
    |
cleanup
```

regardless of success or failure.

---

# Visualization

```text
ENTER
   |
BODY
   |
EXIT
```

---

# Exercise 3

Rewrite:

```python
file = open("data.txt")

try:
    process(file)

finally:
    file.close()
```

using:

```python
with
```

---

# Chapter 66 — What Does `with` Actually Do?

This:

```python
with open("x.txt") as f:

    process(f)
```

is approximately equivalent to:

```python
manager = open("x.txt")

f = manager.__enter__()

try:

    process(f)

finally:

    manager.__exit__(
        None,
        None,
        None
    )
```

---

If exception occurs:

```python
manager.__exit__(
    exc_type,
    exc_value,
    traceback
)
```

is called.

---

# Visualization

```text
Create Manager
       |
       V
__enter__()
       |
       V
Body
       |
       V
__exit__()
```

---

# Exercise 4

Expand this manually:

```python
with lock:
    work()
```

---

# Chapter 67 — Building Your First Context Manager

Example:

```python
class Resource:

    def __enter__(self):

        print("acquire")

        return self

    def __exit__(
        self,
        exc_type,
        exc,
        tb
    ):

        print("release")
```

Usage:

```python
with Resource():

    print("working")
```

Output:

```text
acquire
working
release
```

---

# Exercise 5

Add:

```python
raise Exception()
```

inside the block.

What happens?

---

# Chapter 68 — Exceptions Inside Context Managers

Example:

```python
class Resource:

    def __enter__(self):

        print("open")

    def __exit__(
        self,
        exc_type,
        exc,
        tb
    ):

        print("close")
```

Usage:

```python
with Resource():

    raise ValueError()
```

Output:

```text
open
close
ValueError
```

---

Important:

```text
__exit__()
```

runs before exception propagation.

---

# Visualization

```text
raise
    |
call __exit__
    |
continue exception
```

---

# Exercise 6

Print:

```python
exc_type
exc
```

inside:

```python
__exit__()
```

---

# Chapter 69 — Exception Suppression

Here's something surprising.

If:

```python
__exit__()
```

returns:

```python
True
```

Python suppresses the exception.

---

Example:

```python
class Ignore:

    def __enter__(self):
        return self

    def __exit__(
        self,
        exc_type,
        exc,
        tb
    ):

        return True
```

Usage:

```python
with Ignore():

    raise ValueError()

print("done")
```

Output:

```text
done
```

The exception vanished.

---

# Visualization

```text
raise
   |
__exit__
   |
returns True
   |
destroy exception
```

---

# Exercise 7

Implement:

```python
IgnoreValueError
```

that suppresses only:

```python
ValueError
```

---

# Chapter 70 — Selective Suppression

Example:

```python
class IgnoreValueError:

    def __exit__(
        self,
        exc_type,
        exc,
        tb
    ):

        return (
            exc_type is ValueError
        )
```

---

Usage:

```python
with IgnoreValueError():

    raise ValueError()
```

↓

```text
suppressed
```

---

But:

```python
with IgnoreValueError():

    raise TypeError()
```

↓

```text
TypeError
```

---

# Exercise 8

Suppress:

```text
FileNotFoundError
```

only.

---

# Chapter 71 — Context Managers As Transactions

Consider:

```python
db.begin()

try:

    update()

    db.commit()

except:

    db.rollback()
```

---

Using context managers:

```python
with transaction():

    update()
```

---

Implementation:

```python
class Transaction:

    def __enter__(self):

        db.begin()

    def __exit__(
        self,
        exc_type,
        exc,
        tb
    ):

        if exc:

            db.rollback()

        else:

            db.commit()
```

---

# Visualization

```text
ENTER
   |
begin
   |
execute
   |
success?
 /      \
yes      no
 |        |
commit rollback
```

---

# Exercise 9

Implement a transaction manager.

---

# Chapter 72 — Context Managers As Locks

Example:

```python
lock.acquire()

try:

    critical()

finally:

    lock.release()
```

becomes:

```python
with lock:

    critical()
```

---

Threading locks already implement:

```python
__enter__()
__exit__()
```

---

Example:

```python
import threading

lock = threading.Lock()

with lock:

    print("safe")
```

---

# Exercise 10

Verify:

```python
dir(threading.Lock())
```

contains:

```text
__enter__
__exit__
```

---

# Chapter 73 — Nested Context Managers

Example:

```python
with open("a") as f:

    with lock:

        with transaction():

            work()
```

---

Execution:

```text
enter file
enter lock
enter transaction

work

exit transaction
exit lock
exit file
```

---

This is:

```text
LIFO cleanup
```

---

# Visualization

```text
ENTER
 file
   lock
      tx

EXIT
 tx
   lock
      file
```

---

# Exercise 11

Predict cleanup order.

---

# Chapter 74 — Multiple Context Managers

Instead of:

```python
with open("a") as f:

    with open("b") as g:

        process()
```

you can write:

```python
with open("a") as f, \
     open("b") as g:

    process()
```

---

Equivalent:

```text
enter a
enter b

process

exit b
exit a
```

---

# Exercise 12

Add three files.

Predict cleanup order.

---

# Chapter 75 — Generator Context Managers

Python provides:

```python
contextlib.contextmanager
```

Example:

```python
from contextlib import contextmanager

@contextmanager
def timer():

    print("start")

    yield

    print("stop")
```

Usage:

```python
with timer():

    work()
```

---

Output:

```text
start
work
stop
```

---

Internally:

```text
before yield -> __enter__
after yield -> __exit__
```

---

# Exercise 13

Implement:

```text
database_transaction()
```

using:

```python
@contextmanager
```

---

# Chapter 76 — Context Managers As Resource Ownership

This is the deepest insight.

A context manager represents:

> ownership of a resource.

---

Example:

```python
with open("file") as f:
```

means:

```text
I own this file
inside this block
```

Outside:

```text
ownership released
```

---

Examples:

```python
with database():
```

↓

```text
own connection
```

---

```python
with lock:
```

↓

```text
own lock
```

---

```python
with transaction():
```

↓

```text
own transaction
```

---

# This Is Actually RAII

C++ uses:

```text
constructor
destructor
```

Python uses:

```text
__enter__
__exit__
```

Both solve:

> guaranteed cleanup.

---

# The Context Manager Lifecycle

```text
Acquire Resource
        |
        V
Transfer Ownership
        |
        V
Execute Code
        |
        V
Success?
   /       \
 yes       no
  |         |
cleanup cleanup
        |
        V
Release Ownership
```

---

# The Most Important Diagram In Resource Safety

```text
Acquire
    |
    V
Own
    |
    V
Use
    |
    V
Failure?
  /    \
yes    no
 |      |
cleanup cleanup
     |
     V
Release
```

---

# Summary

In this article we learned:

✅ why cleanup matters
✅ `with` statement internals
✅ `__enter__`
✅ `__exit__`
✅ exception propagation
✅ exception suppression
✅ transaction managers
✅ lock managers
✅ nested contexts
✅ generator contexts
✅ RAII in Python
✅ ownership semantics

---

# Conclusion

Most developers think:

> Context managers are a convenient way to open files.

Professional engineers understand:

> Context managers are Python's mechanism for guaranteeing correctness under failure.

Because the real purpose of:

```python
with resource():
```

isn't:

> "Open this resource."

It's:

> **"No matter what happens next, I promise this resource will not leak."**

In **Part 7**, we'll dive into one of the most misunderstood features in Python:

* exception chaining,
* implicit chaining,
* explicit chaining,
* `raise from`,
* `__cause__`,
* `__context__`,
* root-cause analysis,
* and how modern observability systems reconstruct failures across thousands of services.

Because failures don't happen in isolation.

They happen in chains. 🚨
