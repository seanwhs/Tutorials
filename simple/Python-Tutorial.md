# 📘 Python Mastery Tutorial — Beginner to Advanced (Functional Programming / FB Approach)

---

## 🎯 Learning Objectives

By the end of this tutorial, you will:

1. Understand **Python syntax, variables, and data types**, and how they behave in memory.
2. Apply **control flow**, **ternary operators**, and **FB transformations**.
3. Use **collections**, **comprehensions**, **unpacking operators**, and **functional programming techniques**.
4. Write **functions** (named, anonymous, recursive) with pure and impure patterns.
5. Handle **files, exceptions, debugging**, and functional pipelines.
6. Apply **OOP principles** only when necessary, favoring **FB style** for most transformations.
7. Master **generators, decorators, iterators, context managers, async/await, threading**.
8. Build **mini-projects** and **advanced projects** using functional programming.
9. Develop **mental models** and **ASCII diagrams** to understand code execution and data flow.

---

# 🧠 Section 1 — Python Basics

Python is an **interpreted, dynamically typed, high-level programming language** designed for readability and productivity.

### Mental Model:

```
Your Code (.py)
       |
Python Interpreter
       |
Executes line by line -> Output
```

* Interpreted → no compilation needed.
* Dynamically typed → variable types are determined at runtime.
* High-level → abstracts memory management, pointers, etc.

---

# 🧠 Section 2 — Variables, Data Types, and FB Thinking

Python supports several data types: integers, floats, strings, booleans, None, and collections.

```python
x = 10        # integer
pi = 3.14     # float
name = "Alice" # string
flag = True   # boolean
```

**Functional Programming Mental Model (FB):**

* Variables are **data references**, preferably immutable.
* Functions should **take inputs and return outputs** rather than mutating global state.

```
Data (input) -> Function (pure transformation) -> Data (output)
```

---

# 🧠 Section 3 — Operators, Ternary, and Unpacking

### Arithmetic and Comparison Operators

```python
a, b = 5, 2
add = a + b
sub = a - b
div = a / b
mod = a % b
```

### Ternary Operator

```python
max_val = a if a > b else b
```

* **Mental Model:** Inline decision → simpler conditional assignments.

### Unpacking

```python
nums = [1, 2, 3]
first, *rest = nums
print(first)  # 1
print(rest)   # [2, 3]

d1 = {'x': 1}
d2 = {'y': 2}
combined = {**d1, **d2}  # dictionary unpacking
```

* **FB Principle:** Deconstruct data structures to pass clean, structured data to pure functions.

---

# 🧠 Section 4 — Control Flow

### Conditional Statements (FB Style)

```python
def classify(score):
    return "A" if score >= 90 else "B" if score >= 80 else "C"
```

### Loops

```python
# For Loop
for i in range(5):
    print(i)

# While Loop
count = 0
while count < 5:
    print(count)
    count += 1
```

**FB Pattern:** Functions should **return results** instead of printing inside loops.

---

# 🧠 Section 5 — Functions

### Named Functions

```python
def greet(name):
    return f"Hello, {name}"
```

### Anonymous / Lambda Functions

```python
square = lambda x: x**2
print(square(5))  # 25
```

### Recursive Functions

```python
def factorial(n):
    return 1 if n == 0 else n * factorial(n-1)
```

**Mental Model: Stack / Call Frames**

```
factorial(3)
 -> 3*factorial(2)
      -> 2*factorial(1)
           -> 1*factorial(0)
                -> returns 1
 -> resolves back up the stack
```

---

# 🧠 Section 6 — Collections (Lists, Tuples, Sets, Dicts)

### FB Principles:

* Data flows through **pure transformations**.
* Use comprehensions for **concise, readable, functional code**.

```python
# List comprehension
squares = [x**2 for x in range(5)]

# Filtering in comprehension
evens = [x for x in range(10) if x % 2 == 0]

# Set comprehension
squares_set = {x**2 for x in range(5)}

# Dict comprehension
square_dict = {x: x**2 for x in range(5)}

# Functional mapping/filtering
nums = [1, 2, 3, 4]
evens = list(filter(lambda x: x%2==0, nums))
squares = list(map(lambda x: x**2, nums))
```

**Mental Model / Data Flow:**

```
Input List -> Filter -> Map/Transform -> Output
```

---

# 🧠 Section 7 — File I/O (FB Style)

```python
def write_file(filename, content):
    with open(filename, "w") as f:
        f.write(content)

def read_file(filename):
    with open(filename) as f:
        return f.read()
```

**FB Principle:** Return content instead of printing → supports pipelines.

---

# 🧠 Section 8 — Exceptions (FB Style)

```python
def safe_divide(a, b):
    try:
        return a / b
    except ZeroDivisionError:
        return None  # explicit error value
```

* **FB Mental Model:** Avoid side effects, propagate errors as **return values**.

---

# 🧠 Section 9 — Object-Oriented Programming (Minimal, FB First)

```python
class Person:
    def __init__(self, name):
        self.name = name
    def greet(self):
        print(f"Hello {self.name}")
```

* **FB Principle:** Prefer functions for data transformations; use classes only for stateful objects.

---

# 🧠 Section 10 — Generators & Iterators

```python
def gen_numbers(n):
    for i in range(n):
        yield i

# Generator expression
squares = (x**2 for x in range(5))
```

**FB Mental Model:** Lazy evaluation → memory-efficient, composable.

---

# 🧠 Section 11 — Decorators (FB Style)

```python
def debug(func):
    def wrapper(*args, **kwargs):
        print(f"Calling {func.__name__}")
        return func(*args, **kwargs)
    return wrapper

@debug
def add(a, b):
    return a + b
```

* Decorators = **pure function enhancers**.

---

# 🧠 Section 12 — Context Managers

```python
with open("file.txt") as f:
    content = f.read()
```

Custom:

```python
class MyContext:
    def __enter__(self):
        print("Enter")
    def __exit__(self, exc_type, exc_val, exc_tb):
        print("Exit")

with MyContext():
    print("Inside")
```

* FB Principle: Encapsulate resource management in pure functions or context blocks.

---

# 🧠 Section 13 — Async / Await

```python
import asyncio

async def square(x):
    await asyncio.sleep(0.5)
    return x**2

async def process(nums):
    return [await square(n) for n in nums]

print(asyncio.run(process([1, 2, 3])))
```

* Non-blocking, pure transformations in pipelines.

---

# 🧠 Section 14 — Threading

```python
from threading import Thread

def worker(data, results, index):
    results[index] = data**2

nums = [1, 2, 3]
results = [None]*len(nums)
threads = [Thread(target=worker, args=(n, results, i)) for i, n in enumerate(nums)]

for t in threads: t.start()
for t in threads: t.join()
print(results)
```

* Concurrent FB tasks → functions remain stateless and pure.

---

# 🏁 Section 15 — FB Mini Project: Contact Book

```python
contacts = []

def add_contact(contacts, name, phone):
    return contacts + [{"name": name, "phone": phone}]

def list_contacts(contacts):
    return [f"{c['name']} - {c['phone']}" for c in contacts]

contacts = add_contact(contacts, "Alice", "123")
contacts = add_contact(contacts, "Bob", "456")
print(list_contacts(contacts))
```

* **FB Principle:** Data flows through **pure transformations**, state is returned rather than mutated.

---

# 🧾 Addendum A — Full Project Structure

```
python_fb_project/
├── main.py
├── utils.py
├── data/
└── README.md
```

---

# 🧾 Addendum B — Visual Cheat Sheet

```
Variables -> immutable by default
Functions -> pure input -> output
Control Flow -> decisions return values
Collections -> comprehensions, map/filter/reduce
Recursion -> stack-based FB computations
Decorators -> wrap pure functions
Generators -> lazy evaluation
Context Managers -> with blocks
Async -> non-blocking pure tasks
Threads -> concurrent stateless tasks
OOP -> only for stateful objects
```

---

# 🧾 Addendum C — Advanced Async FB Pipeline

**Project:** Build an **async pipeline** reading, transforming, and logging data in FB style.

```
async_pipeline_fb/
├── main.py
├── processors.py
├── utils.py
└── data/
```

### utils.py

```python
def debug(func):
    def wrapper(*args, **kwargs):
        print(f"[DEBUG] {func.__name__}({args},{kwargs})")
        return func(*args, **kwargs)
    return wrapper
```

### processors.py

```python
import asyncio
from utils import debug

@debug
async def process_item(item):
    await asyncio.sleep(0.5)
    return item*2

def data_generator(n):
    for i in range(n):
        yield i
```

### main.py

```python
import asyncio
from processors import process_item, data_generator

async def main():
    results = []
    for item in data_generator(5):
        results.append(await process_item(item))
    print("Pipeline Results:", results)

asyncio.run(main())
```

**ASCII Diagram:**

```
Data Source -> Generator -> Async Processor (Decorator logs) -> Results -> Output
```

---

# 🧾 Addendum D — Python FB Visual Pipeline Map

This addendum shows **how data flows through Python programs** using **functional programming (FB) principles**, **advanced constructs**, and **state management patterns**.

---

## 1️⃣ Core Data Flow (FB Style)

```
Input Data (variables / function arguments)
           |
           v
   Pure Functions / Transformations
   - Comprehensions
   - Map / Filter / Reduce
   - Lambdas / Anonymous functions
           |
           v
Intermediate Data (lists, sets, dicts)
           |
           v
Optional IO / Side Effects
   - File read/write
   - API calls
   - Print / Logging
           |
           v
Output Data (return values / results)
```

**Explanation:**

* Data **always flows through transformations**.
* FB principle: functions do not mutate external state.
* Side effects are **isolated**.

---

## 2️⃣ Control Flow Visual

```
Conditional Logic
      |
      v
 +-------------+
 |  Condition  |
 +-------------+
      |
  True/False
      |----------------+
      |                |
True branch        False branch
      |                |
      v                v
 Output / Next step  Output / Next step
```

* Ternary operators are **inline versions** of this flow:

```python
result = x if cond else y
```

---

## 3️⃣ Collection Pipelines

```
Input List -> [Comprehension / Map / Filter] -> Intermediate List -> Reduce / Aggregate -> Output
```

Example:

```python
nums = [1,2,3,4,5]
evens = list(filter(lambda x: x%2==0, nums))
squares = list(map(lambda x: x**2, evens))
sum_val = sum(squares)
```

ASCII Flow:

```
[1,2,3,4,5] 
      |
   Filter Even
      v
   [2,4]
      |
   Map Square
      v
   [4,16]
      |
     Sum
      v
     20
```

---

## 4️⃣ Recursion Flow

**Example:** factorial(3)

```
factorial(3)
  |
  v
3 * factorial(2)
        |
        v
    2 * factorial(1)
            |
            v
        1 * factorial(0)
            |
            v
           1 (base case)
```

* **Mental Model:** Stack frames are **pushed for each recursive call**, then **resolved back up**.

---

## 5️⃣ Generators / Iterators Flow

```
Data Source -> Generator Function -> Yielded Values -> Consumer Loop / Function
```

Example:

```python
def gen_numbers(n):
    for i in range(n):
        yield i
```

ASCII Flow:

```
gen_numbers(3)
   |
   v
Yield 0 -> Consumer
Yield 1 -> Consumer
Yield 2 -> Consumer
Stop
```

* **FB principle:** lazy evaluation → memory efficient, composable.

---

## 6️⃣ Decorators Flow

```
Original Function -> Decorator Wrapper -> Modified / Enhanced Function -> Output
```

Example:

```python
@debug
def add(a,b):
    return a+b
```

ASCII:

```
Call add(2,3)
       |
       v
   debug.wrapper
       |
       v
Original add function
       |
       v
Return result (5)
```

---

## 7️⃣ Async / Await Pipeline Flow

```
Data Generator -> Async Function (awaitable) -> Concurrent Tasks -> Gather / Results -> Output
```

Example:

```python
async def process(nums):
    return [await square(n) for n in nums]
```

ASCII:

```
[1,2,3] -> async square(1) -> pending
         -> async square(2) -> pending
         -> async square(3) -> pending
         |
         v
await all -> [1,4,9] -> Output
```

* **Mental Model:** Tasks execute concurrently, return **pure transformed data**.

---

## 8️⃣ Threading Pipeline Flow

```
Input Data -> Thread Worker Functions -> Shared Results List -> Join Threads -> Output
```

ASCII:

```
[1,2,3] -> Thread 1 (1^2) -> results[0]
         -> Thread 2 (2^2) -> results[1]
         -> Thread 3 (3^2) -> results[2]
         |
         v
Join Threads -> [1,4,9]
```

* **FB principle:** threads do not mutate original data; results are collected explicitly.

---

## 9️⃣ Context Managers Flow

```
Resource Acquisition -> __enter__ -> Block Execution -> __exit__ -> Resource Release
```

ASCII:

```
with MyContext():
   print("Inside")
---------------------
__enter__ -> print "Enter"
Block executes -> print "Inside"
__exit__ -> print "Exit"
```

* Encapsulates **setup/cleanup** reliably.

---

## 10️⃣ FB Mini Project Pipeline

**Contact Book Example:**

```
Initial contacts -> add_contact() -> returns new contacts list -> list_contacts() -> Output
```

ASCII:

```
[] 
  |
add_contact("Alice","123") -> [{"name":"Alice","phone":"123"}]
  |
add_contact("Bob","456") -> [{"name":"Alice","phone":"123"}, {"name":"Bob","phone":"456"}]
  |
list_contacts() -> ["Alice - 123", "Bob - 456"]
```

* Shows **pure functional transformations**, no mutation.


