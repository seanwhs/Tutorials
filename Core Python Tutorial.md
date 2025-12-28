# 🐍 Python Fundamentals Tutorial 

**Edition:** 1.0 

**Focus:** Python 3.12+, Types, Collections, Variables, Operators, Functions, Recursion, Functional Programming, OOP, Comprehensions, Error Handling, Files, Modules, CLI, Packaging

---

## **Core Mental Models**

Understanding Python deeply requires **mental models**:

1. **Boxes (Variables)** – Containers for values; can be **local**, **global**, or **nonlocal**.
2. **Machines (Functions)** – Transform input into output. Functions can be **first-class**, **higher-order**, **recursive**, or **anonymous (lambda)**.
3. **Factories (Objects)** – Encapsulate **state** (attributes) and **behavior** (methods).
4. **Magic Methods** – Special methods controlling object behavior, operators, iteration, and representation.
5. **Assembly Lines (Comprehensions)** – Efficiently transform collections.
6. **Pipelines (Functional Programming)** – Compose small, reusable functions.
7. **Safety Nets (Error Handling)** – Prevent programs from crashing.
8. **Persistent Boxes (Files)** – Data stored outside memory, accessible across program runs.
9. **Toolboxes (Modules & Packages)** – Organize reusable code for clarity and maintainability.

> **Mental Tip:** Imagine Python programs as a **network of interconnected boxes, machines, and assembly lines**, each with clearly defined interfaces.

---

## 🔹 1. Python: The Modern Landscape

Python is a **high-level, readable, type-safe, and versatile language**.

**Applications:**

* Web Development: Django, FastAPI
* Data Science & AI: pandas, NumPy, PyTorch
* Automation & Scripting
* DevOps & CLI Tools

**Hello Python Example:**

```python
name: str = "Alice"
print(f"Hello, {name}!")  # Python 3.12+ f-string with type annotation
```

* Type annotations allow **IDEs and linters** to detect errors before runtime.
* F-strings provide a **concise, readable way** to format strings.

---

## 🔹 2. Types and Collections

### 2.1 Primitive Types

```python
age: int = 30
price: float = 19.99
name: str = "Alice"
is_active: bool = True
nothing: None = None
```

* `int` / `float` – numeric operations
* `str` – textual data
* `bool` – logical True/False
* `None` – absence of a value (like `null`)

**Example – Optional Values:**

```python
from typing import Optional

def greet(name: Optional[str] = None):
    if name:
        print(f"Hello, {name}")
    else:
        print("Hello, Guest")
```

---

### 2.2 Union Types

```python
def process(data: str | list[str]):
    if isinstance(data, str):
        print(f"Processing string: {data}")
    else:
        print(f"Processing list: {data}")
```

* `str | list[str]` means the value can be **either type**.
* Union types make **interfaces clear** and reduce runtime errors.

---

### 2.3 Collections

```python
numbers: list[int] = [1,2,3]        # mutable, ordered
point: tuple[int,int] = (10,20)     # immutable, ordered
fruits: set[str] = {"apple","banana"}  # unique, unordered
student: dict[str,int] = {"Alice":90}  # key-value pairs
```

**Mental Model:** Collections = **boxes of boxes**, each with rules for **mutability**, **ordering**, and **uniqueness**.

---

## 🔹 3. Operators

### 3.1 Arithmetic

```python
a, b = 10, 3
print(a + b, a - b, a * b, a / b, a // b, a % b, a ** b)
```

* `/` float division, `//` floor division
* `%` remainder, `**` exponentiation

### 3.2 Comparison

```python
x, y = 5, 10
print(x == y, x != y, x < y, x <= y, x > y, x >= y)
```

### 3.3 Logical

```python
x, y = True, False
print(x and y, x or y, not x)
```

### 3.4 Bitwise

```python
a, b = 5, 3  # 101, 011
print(a & b, a | b, a ^ b, ~a, a << 1, a >> 1)
```

### 3.5 Membership & Identity

```python
letters = ["a","b","c"]
print("a" in letters, "z" not in letters)

x = [1,2]; y = x; z = [1,2]
print(x is y, x is z)
```

### 3.6 Unpacking Operators

```python
numbers = [1,2,3]
a, *rest = numbers
print(a, rest)

data = {"x":1,"y":2}
new_data = {**data, "z":3}
print(new_data)
```

---

## 🔹 4. Variables: Local, Global, Nonlocal

```python
counter = 0  # global variable

def increment():
    global counter
    counter += 1

increment()
print(counter)
```

```python
def outer():
    x = 10  # local to outer
    def inner():
        nonlocal x
        x += 5
    inner()
    print(x)

outer()  # 15
```

* **Local:** Defined inside function only
* **Global:** Accessible anywhere
* **Nonlocal:** Allows inner function to modify outer function variables

---

## 🔹 5. Functions – Mini Machines

### 5.1 Basics

```python
def greet(name: str) -> str:
    return f"Hello, {name}!"
```

### 5.2 Default & Optional Arguments

```python
def greet(name: str, title: str | None = None):
    if title: print(f"Hello, {title} {name}")
    else: print(f"Hello, {name}")
```

### 5.3 Variable-Length Arguments

```python
def summarize(*args, **kwargs):
    print("Positional:", args)
    print("Keyword:", kwargs)

summarize(1,2,3,name="Alice",age=30)
```

### 5.4 Recursion

```python
def factorial(n: int) -> int:
    if n == 0: return 1
    return n * factorial(n-1)

print(factorial(5))  # 120
```

* Recursion = **breaking a problem into smaller versions of itself**
* Always define **base case** to prevent infinite loops

---

## 🔹 6. Functional Programming (FP)

### 6.1 First-Class Functions

```python
def add(x,y): return x+y
def sub(x,y): return x-y

operations = {"add": add, "sub": sub}
print(operations["add"](5,3))
```

### 6.2 Higher-Order Functions

```python
def apply_fn(fn, value): return fn(value)
print(apply_fn(lambda x:x**2, 5))
```

### 6.3 Lambdas

```python
square = lambda x:x**2
add = lambda x,y:x+y
```

### 6.4 Map, Filter, Reduce

```python
from functools import reduce
numbers = [1,2,3,4,5]

squared = list(map(lambda x:x**2, numbers))
evens = list(filter(lambda x:x%2==0, numbers))
total = reduce(lambda acc,x:acc+x, numbers)
```

### 6.5 Decorators

```python
def log_calls(fn):
    def wrapper(*args, **kwargs):
        print(f"Calling {fn.__name__} with args={args}, kwargs={kwargs}")
        result = fn(*args, **kwargs)
        print(f"{fn.__name__} returned {result}")
        return result
    return wrapper

@log_calls
def add(x,y): return x+y
add(3,4)
```

---

## 🔹 7. Comprehensions

```python
numbers = [1,2,3,4,5]

# List
squares = [x**2 for x in numbers]
evens = [x for x in numbers if x%2==0]

# Dict
square_dict = {x:x**2 for x in numbers if x%2==0}

# Set
unique_squares = {x**2 for x in numbers}

# Generator
gen = (x**2 for x in numbers)

# Nested
matrix = [[1,2],[3,4],[5,6]]
flatten = [x for row in matrix for x in row]

# Conditional
labels = ["Even" if x%2==0 else "Odd" for x in numbers]
```

> **Mental Model:** Comprehensions = **mini assembly lines for transforming data**.

---

## 🔹 8. Object-Oriented Programming (OOP)

### 8.1 Encapsulation

```python
class BankAccount:
    def __init__(self, owner:str, balance:float):
        self.owner = owner
        self._balance = balance  # Protected attribute

    def deposit(self, amount): self._balance += amount
    def get_balance(self): return self._balance
```

### 8.2 Inheritance & Polymorphism

```python
class Vehicle: 
    def move(self): print("Vehicle moving")
class Car(Vehicle): 
    def move(self): print("Car driving")

class Dog: 
    def speak(self): return "Woof!"
class Cat: 
    def speak(self): return "Meow!"

vehicles = [Vehicle(), Car()]
animals = [Dog(), Cat()]
for v in vehicles: v.move()
for a in animals: print(a.speak())
```

### 8.3 Abstraction

```python
from abc import ABC, abstractmethod
class Shape(ABC):
    @abstractmethod
    def area(self): pass
```

### 8.4 Dataclasses

```python
from dataclasses import dataclass
@dataclass
class Product:
    name: str
    price: float
    stock: int = 0
```

### 8.5 Magic Methods

```python
class Vector:
    def __init__(self,x,y): self.x,self.y=x,y
    def __str__(self): return f"Vector({self.x},{self.y})"
    def __add__(self,other): return Vector(self.x+other.x,self.y+other.y)
```

---

## 🔹 9. Error Handling

```python
try:
    x = int(input("Enter number: "))
    print(10/x)
except ZeroDivisionError: print("Cannot divide by zero")
except ValueError: print("Invalid input")
finally: print("Done")
```

* **Custom Exception:**

```python
class NegativeBalanceError(Exception): pass
```

---

## 🔹 10. File Handling

```python
# Text
with open("file.txt","w") as f: f.write("Hello\n")
with open("file.txt","r") as f: print(f.read())

# CSV
import csv
with open("data.csv","w",newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Name","Age"])
    writer.writerow(["Alice",30])

# JSON
import json
data={"name":"Alice"}
with open("data.json","w") as f: json.dump(data,f)
```

---

## 🔹 11. Modules & Packages

```python
# utils.py
def greet(name): return f"Hello {name}"

# main.py
from utils import greet
print(greet("Alice"))
```

* **Packages:** folders with `__init__.py`
* Avoid **circular imports**

---

## 🔹 12. CLI & Packaging

### Command-Line Interface (argparse)

```python
import argparse
parser = argparse.ArgumentParser(description="Add two numbers")
parser.add_argument("x", type=int)
parser.add_argument("y", type=int)
args = parser.parse_args()
print(args.x + args.y)
```

### Packaging into Executables (PyInstaller)

```bash
pip install pyinstaller
pyinstaller --onefile src/main.py
```

---

## 🔹 13. Project Structure

```
my-python-project/
├── .venv/
├── src/
│   ├── __init__.py
│   ├── main.py
│   └── utils.py
├── tests/
├── cli_tool.py
├── data/
├── docs/
├── .gitignore
├── README.md
├── pyproject.toml
└── uv.lock
```

---

✅ **Highlights:**

* **Types, Collections, Variables, Operators**
* Functions: **Local/Global, Recursion, *args/**kwargs, HOF, FP, Decorators, Lambdas**
* OOP: **Encapsulation, Inheritance, Polymorphism, Abstraction, Dataclasses, Magic Methods**
* Comprehensions & Functional Pipelines
* Error Handling, Files, Modules, CLI, Packaging

---


Do you want me to generate that next?
