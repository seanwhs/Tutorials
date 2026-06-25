# PART 1: PYTHON FUNDAMENTALS

## 1.1 What is Python?

**What:** Python is a programming language that reads almost like English. It's "high-level," meaning it handles complex computer tasks (like memory management) for you.

**Why:** Python is the most popular language for beginners because you can write powerful programs with very little code. It's used by scientists, web developers, and AI engineers.

**How:** You write instructions in a `.py` file, and Python executes them line by line.

**When:** Use Python when you want to automate tasks, process data, build web apps, or work with AI.

```python
# This is a Python program
print("Hello, Student!")
name = "Alice"
print(f"Welcome, {name}!")
```

---

## 1.2 Variables: Storing Information

**What:** A variable is a labeled box that stores data.

**Why:** Without variables, you'd have to rewrite data everywhere. Variables let you reuse and update information.

**How:** Use `=` to put data into a variable. The variable name goes on the left, the value on the right.

**When:** Every time you need to remember something for later use.

```python
# Creating variables
student_name = "Alice"      # Text (string)
grade = 85                  # Number (integer)
score = 92.5                # Decimal number (float)
is_passing = True           # Yes/No value (boolean)

# Using variables
print(student_name)         # Alice
print(grade + 5)           # 90

# Updating variables
grade = 90                  # The box now holds 90
print(grade)               # 90
```

**⚠️ Common Mistake:** `=` in Python means "store this value," NOT "equals." For comparison, use `==`.

```python
x = 5      # Store 5 in x
print(x == 5)  # True (comparison)
print(x == 3)  # False
```

---

## 1.3 Data Types: What Kind of Data?

**What:** Data types tell Python what kind of information you're working with.

**Why:** Python treats text differently from numbers. Knowing types prevents bugs.

**How:** Python figures out types automatically, but you can check them.

**When:** Always be aware of types, especially when converting between them.

```python
# Strings: Text
name = "Alice"
print(type(name))  # <class 'str'>

# Integers: Whole numbers
age = 16
print(type(age))   # <class 'int'>

# Floats: Decimal numbers
score = 92.5
print(type(score)) # <class 'float'>

# Booleans: True or False
passed = True
print(type(passed)) # <class 'bool'>

# None: Represents "nothing"
result = None
print(type(result)) # <class 'NoneType'>
```

**In Markly:** We use all these types:
```python
# From utils.py
def extract_grade(text: str) -> str:
    """text is a string, returns a string"""
    if not text:        # text is None or empty string
        return "N/A"    # returns a string
```

---

## 1.4 Type Hints: Documenting Your Code

**What:** Type hints are notes that tell other programmers (and tools) what type a variable should be.

**Why:** They make code easier to understand and catch mistakes early.

**How:** Use `:` after a parameter name and `->` before the return type.

**When:** In function definitions, especially in shared codebases.

```python
# Without type hints
def add(a, b):
    return a + b

# With type hints (much clearer!)
def add(a: int, b: int) -> int:
    return a + b

# More examples from Markly
def extract_grade(text: str) -> str:
    """Takes a string, returns a string"""
    pass

def _font(size: int, bold: bool = False, italic: bool = False):
    """Takes int, bool, bool; returns a font object"""
    pass
```

**Note:** Python doesn't enforce type hints! They're just hints. But they help you and your IDE catch errors.

---

## 1.5 Strings: Working with Text

**What:** A string is a sequence of characters enclosed in quotes.

**Why:** Almost all data in programs starts as text. You need to manipulate it.

**How:** Create with quotes, manipulate with methods.

**When:** Every time you handle names, messages, file contents, or AI responses.

```python
# Creating strings
name = "Alice"
message = 'Hello, World!'
multiline = """This string
spans multiple
lines."""

# String methods (tools built into strings)
text = "  Hello, World!  "
print(text.lower())        # "  hello, world!  "
print(text.upper())        # "  HELLO, WORLD!  "
print(text.strip())        # "Hello, World!" (removes spaces)
print(text.replace("World", "Python"))  # "  Hello, Python!  "

# Splitting strings
filename = "essay.PDF"
parts = filename.split('.')      # ['essay', 'PDF']
extension = parts[-1]            # 'PDF' (last item)
print(extension.lower())         # 'pdf'

# Joining strings
words = ["Hello", "World"]
sentence = " ".join(words)      # "Hello World"
lines = ["Line 1", "Line 2"]
paragraph = "\n".join(lines)   # "Line 1\nLine 2"

# f-strings: inserting variables into text
student = "Alice"
grade = "A"
print(f"{student} received grade {grade}!")  # Alice received grade A!
```

**In Markly:**
```python
# From utils.py
ext = filename.lower().split('.')[-1]  # Extract extension
raise ValueError(f"Unsupported file type: {filename}")  # f-string error message
```

---

## 1.6 Numbers: Math in Python

**What:** Python handles integers (whole numbers) and floats (decimals).

**Why:** Grades, scores, coordinates, and measurements all need math.

**How:** Standard math operators.

**When:** Calculating grades, positioning elements, or any numeric operation.

```python
# Basic math
a = 10
b = 3
print(a + b)    # 13
print(a - b)    # 7
print(a * b)    # 30
print(a / b)    # 3.333... (always returns float)
print(a // b)   # 3 (integer division, drops remainder)
print(a % b)    # 1 (modulo: remainder after division)
print(a ** b)   # 1000 (10 to the power of 3)

# Math module for advanced operations
import math
print(math.pi)           # 3.14159...
print(math.sqrt(16))     # 4.0
print(math.sin(math.pi / 2))  # 1.0
print(math.floor(3.7))   # 3 (round down)
print(math.ceil(3.2))    # 4 (round up)

# Random numbers
import random
print(random.random())           # Random float between 0 and 1
print(random.randint(1, 10))     # Random integer between 1 and 10
print(random.uniform(-5, 5))     # Random float between -5 and 5
```

**In Markly:**
```python
# From markup.py - jitter adds randomness to handwriting
import random

def _jitter(val: float, amount: float = 2.5) -> float:
    return val + random.uniform(-amount, amount)

# From markup.py - sine waves for wavy underlines
import math
py = y + amplitude * math.sin(2 * math.pi * i * (x1 - x0) / (steps * wavelength))
```

---

# PART 2: WORKING WITH DATA

## 2.1 Lists: Ordered Collections

**What:** A list is an ordered sequence of items.

**Why:** You need to store multiple things in order — pages, students, grades.

**How:** Create with square brackets `[]`, access by position.

**When:** Any time you have a collection where order matters.

```python
# Creating lists
grades = [85, 92, 78, 95]
students = ["Alice", "Bob", "Charlie"]
mixed = [1, "hello", True, 3.14]  # Lists can hold different types

# Accessing items (indexing starts at 0!)
print(grades[0])      # 85 (first item)
print(grades[1])      # 92 (second item)
print(grades[-1])     # 95 (last item)
print(grades[-2])     # 78 (second to last)

# Slicing: getting a portion
print(grades[1:3])    # [92, 78] (items 1 and 2)
print(grades[:2])     # [85, 92] (first two)
print(grades[2:])     # [78, 95] (from index 2 to end)

# Modifying lists
grades.append(88)     # Add to end: [85, 92, 78, 95, 88]
grades.insert(1, 90)  # Insert at position 1: [85, 90, 92, 78, 95, 88]
grades.remove(78)     # Remove first occurrence of 78
popped = grades.pop() # Remove and return last item (88)

# List length
print(len(grades))    # 5

# Checking membership
print(92 in grades)   # True
print(100 in grades)  # False
```

**In Markly:**
```python
# From utils.py - patterns is a list of regex patterns
patterns = [
    r"\b(\d{1,2}(?:.\d+)?)\s*/\s*10\b",
    r"\bGrade[:\s]* ([A-F][+-]?)\b",
    r"\b(\d{1,2}(?:.\d+)?)\s*/\s*(?:100|20|50)\b",
]
for pat in patterns:  # Loop through each pattern
    m = re.search(pat, text, re.I)
```

---

## 2.2 Dictionaries: Key-Value Pairs

**What:** A dictionary stores data as key-value pairs, like a real dictionary (word = key, definition = value).

**Why:** Look up data by name instead of position. Much more readable!

**How:** Create with curly braces `{}` or `dict()`, access with keys.

**When:** Storing structured data like student records, settings, or configurations.

```python
# Creating dictionaries
student = {
    "name": "Alice",
    "grade": "A",
    "score": 95,
    "subjects": ["Math", "Science"]
}

# Accessing values
print(student["name"])       # Alice
print(student.get("grade"))  # A (safer way)
print(student.get("age", 0)) # 0 (default if key doesn't exist)

# Adding and updating
student["age"] = 16          # Add new key
student["score"] = 98        # Update existing key

# Checking membership
print("name" in student)     # True (checks keys)
print("Alice" in student)    # False (checks keys, not values)

# Getting all keys, values, or items
print(student.keys())        # dict_keys(['name', 'grade', ...])
print(student.values())      # dict_values(['Alice', 'A', ...])
print(student.items())       # dict_items([('name', 'Alice'), ...])

# Nested dictionaries
school = {
    "Alice": {"grade": "A", "history": []},
    "Bob": {"grade": "B", "history": []}
}
print(school["Alice"]["grade"])  # A

# Dictionary length
print(len(student))          # 5 (number of key-value pairs)
```

**In Markly:**
```python
# From storage.py - the entire database is a dictionary
def load_db():
    data = json.load(f)
    return data if isinstance(data, dict) else {}

# Student records are nested dictionaries
db = {
    "Alice": {"history": [{"subject": "Math", "grade": "A"}]},
    "Bob": {"history": []}
}
```

---

## 2.3 Tuples: Immutable Lists

**What:** A tuple is like a list, but you can't change it after creation.

**Why:** Tuples protect data from accidental changes. They're also slightly faster.

**How:** Create with parentheses `()` or just commas.

**When:** Storing coordinates, RGB colors, or any fixed data pair.

```python
# Creating tuples
coordinates = (10, 20)
color = (255, 0, 0)  # Red in RGB
single = (42,)       # Single-item tuple needs a comma!

# Accessing (same as lists)
print(coordinates[0])   # 10
print(coordinates[1])   # 20

# Unpacking: splitting a tuple into variables
x, y = coordinates
print(x)  # 10
print(y)  # 20

# Tuples are immutable (can't change)
# coordinates[0] = 5  # ERROR! Can't modify tuple

# Tuples as dictionary keys (lists can't be keys!)
positions = {
    (0, 0): "origin",
    (10, 20): "point A"
}
```

**In Markly:**
```python
# From markup.py - font cache uses tuples as keys
_FONT_CACHE = {}

def _font(size: int, bold: bool = False, italic: bool = False):
    key = (size, bold, italic)  # Tuple as dictionary key
    if key in _FONT_CACHE:
        return _FONT_CACHE[key]
```

---

## 2.4 Sets: Unique Collections

**What:** A set is an unordered collection with no duplicates.

**Why:** Perfect for membership testing and removing duplicates.

**How:** Create with curly braces `{}` or `set()`.

**When:** Checking if an item exists in a group, or removing duplicates.

```python
# Creating sets
unique_grades = {"A", "B", "C", "A", "B"}
print(unique_grades)  # {'A', 'B', 'C'} (duplicates removed!)

# Membership testing (very fast!)
print("A" in unique_grades)   # True
print("F" in unique_grades)   # False

# Adding and removing
unique_grades.add("D")
unique_grades.discard("Z")  # No error if not present

# Set operations
math_students = {"Alice", "Bob", "Charlie"}
science_students = {"Bob", "Diana", "Eve"}

print(math_students & science_students)  # Intersection: {'Bob'}
print(math_students | science_students)  # Union: all names
print(math_students - science_students)  # Difference: {'Alice', 'Charlie'}
```

**In Markly:**
```python
# From utils.py - checking file extensions
elif ext in ("png", "jpg", "jpeg"):  # Tuple used like a set for membership
    return extract_image(file_bytes)
```

---

# PART 3: FILE HANDLING & PERSISTENCE

## 3.1 Reading and Writing Files

**What:** Files let you save data permanently, even when the program closes.

**Why:** Without files, all data disappears when the program ends.

**How:** Use `open()` with context managers (`with` statement).

**When:** Saving grades, loading configurations, or storing any persistent data.

```python
# Writing to a file
with open("hello.txt", "w", encoding="utf-8") as f:
    f.write("Hello, World!\n")
    f.write("This is line 2.")

# Reading from a file
with open("hello.txt", "r", encoding="utf-8") as f:
    content = f.read()
    print(content)

# Reading line by line
with open("hello.txt", "r", encoding="utf-8") as f:
    for line in f:
        print(line.strip())  # strip() removes newline characters

# Appending to a file (adds to end, doesn't overwrite)
with open("hello.txt", "a", encoding="utf-8") as f:
    f.write("\nThis is appended.")
```

**File Modes Explained:**
- `"r"` = Read (default, file must exist)
- `"w"` = Write (creates new or overwrites existing!)
- `"a"` = Append (adds to end)
- `"r+"` = Read and write
- `"b"` = Binary mode (for images, PDFs)

**In Markly:**
```python
# From storage.py
with open(DB_FILE, "w", encoding="utf-8") as f:
    json.dump(db, f, indent=2)  # Write JSON to file

with open(DB_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)  # Read JSON from file
```

---

## 3.2 Context Managers: The `with` Statement

**What:** A context manager automatically handles setup and cleanup (like opening and closing files).

**Why:** Prevents resource leaks. Guarantees files get closed even if errors occur.

**How:** Use the `with` keyword.

**When:** Any time you acquire a resource that needs cleanup.

```python
# Without context manager (risky!)
f = open("file.txt", "r")
data = f.read()
f.close()  # What if an error happens before this?

# With context manager (safe!)
with open("file.txt", "r") as f:
    data = f.read()
# File is automatically closed here, even if errors occurred!

# How it works behind the scenes
class ManagedFile:
    def __enter__(self):
        print("Opening file...")
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        print("Closing file...")
    
    def read(self):
        return "data"

with ManagedFile() as f:
    print(f.read())
# Output:
# Opening file...
# data
# Closing file...
```

**In Markly:**
```python
# Every file operation uses a context manager
with open(DB_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

# fitz (PyMuPDF) also uses context manager behavior
document = fitz.open(stream=file_bytes, filetype="pdf")
```

---

## 3.3 JSON: Saving Python Objects as Text

**What:** JSON (JavaScript Object Notation) is a text format for storing structured data.

**Why:** It's human-readable, works across programming languages, and Python supports it natively.

**How:** Use the `json` module to convert between Python objects and JSON text.

**When:** Saving configurations, databases, or any structured data to disk.

```python
import json

# Python dictionary
student = {
    "name": "Alice",
    "grade": "A",
    "scores": [95, 88, 92]
}

# Convert to JSON string
json_string = json.dumps(student)
print(json_string)
# {"name": "Alice", "grade": "A", "scores": [95, 88, 92]}

# Pretty-print with indentation
pretty = json.dumps(student, indent=2)
print(pretty)
# {
#   "name": "Alice",
#   "grade": "A",
#   "scores": [95, 88, 92]
# }

# Save to file
with open("student.json", "w") as f:
    json.dump(student, f, indent=2)

# Load from file
with open("student.json", "r") as f:
    loaded = json.load(f)
print(loaded["name"])  # Alice

# JSON types map to Python types
# JSON object  -> Python dict
# JSON array   -> Python list
# JSON string  -> Python str
# JSON number  -> Python int or float
# JSON true    -> Python True
# JSON false   -> Python False
# JSON null    -> Python None
```

**In Markly:**
```python
# From storage.py - entire database is JSON
def save_db(db):
    with open(DB_FILE, "w", encoding="utf-8") as f:
        json.dump(db, f, indent=2)

def load_db():
    with open(DB_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
        return data if isinstance(data, dict) else {}
```

---

## 3.4 Checking if Files Exist

**What:** Before reading a file, check if it actually exists.

**Why:** Prevents crashes from missing files.

**How:** Use `os.path.exists()` from the `os` module.

**When:** Loading configuration files, databases, or any external resource.

```python
import os

# Check if file exists
if os.path.exists("students.json"):
    print("Database found!")
else:
    print("No database yet. Creating one...")

# Other useful checks
print(os.path.isfile("students.json"))   # True (it's a file)
print(os.path.isdir("students.json"))    # False (not a folder)
print(os.path.getsize("students.json"))  # File size in bytes
```

**In Markly:**
```python
# From storage.py
def load_db():
    if not os.path.exists(DB_FILE):
        return {}  # Return empty database if file missing
    # ... load from file
```

---

# PART 4: FUNCTIONS & MODULARITY

## 4.1 Defining Functions

**What:** A function is a reusable block of code that performs a specific task.

**Why:** Avoid repeating code. Make programs organized and testable.

**How:** Use `def` keyword, followed by name, parameters, and body.

**When:** Any time you need to do the same thing more than once.

```python
# Simple function
def greet(name):
    """Says hello to someone."""
    print(f"Hello, {name}!")

greet("Alice")  # Hello, Alice!
greet("Bob")    # Hello, Bob!

# Function with return value
def add(a, b):
    """Returns the sum of two numbers."""
    return a + b

result = add(5, 3)
print(result)  # 8

# Function with multiple returns
def get_min_max(numbers):
    """Returns both minimum and maximum."""
    return min(numbers), max(numbers)

minimum, maximum = get_min_max([3, 1, 4, 1, 5])
print(minimum, maximum)  # 1 5
```

**In Markly:**
```python
# From utils.py
def extract_pdf(file_bytes):
    """Extracts text page by page from a PDF."""
    document = fitz.open(stream=file_bytes, filetype="pdf")
    return "\n".join([page.get_text() for page in document])
```

---

## 4.2 Function Parameters

**What:** Parameters are inputs a function accepts.

**Why:** Make functions flexible and reusable with different data.

**How:** Define in parentheses; provide defaults for optional values.

**When:** Every function definition.

```python
# Required parameters
def greet(name):
    print(f"Hello, {name}!")

greet("Alice")  # Works
greet()         # ERROR! Missing required argument

# Default parameters (optional)
def greet(name, greeting="Hello"):
    print(f"{greeting}, {name}!")

greet("Alice")           # Hello, Alice! (uses default)
greet("Bob", "Hi")       # Hi, Bob! (overrides default)
greet("Carol", greeting="Hey")  # Hey, Carol! (named argument)

# Keyword arguments (order doesn't matter)
def create_student(name, age, grade):
    print(f"{name}, {age}, {grade}")

create_student(grade="A", age=16, name="Alice")  # All work!

# *args: variable number of positional arguments
def sum_all(*numbers):
    return sum(numbers)

print(sum_all(1, 2, 3, 4))  # 10

# **kwargs: variable number of keyword arguments
def print_info(**kwargs):
    for key, value in kwargs.items():
        print(f"{key}: {value}")

print_info(name="Alice", age=16, grade="A")
```

**In Markly:**
```python
# From markup.py - multiple defaults
def _jitter(val: float, amount: float = 2.5) -> float:
    return val + random.uniform(-amount, amount)

# From markup.py - many parameters
def create_marked_pdf(student, subject, filename, marked_image_buffer,
                      overall_feedback="", grade="", report_text="", corrections=None):
    # corrections=None is a common pattern for optional mutable defaults
```

---

## 4.3 Docstrings: Documenting Functions

**What:** A docstring is a string at the start of a function that explains what it does.

**Why:** Helps other programmers (and future you!) understand the code.

**How:** Triple quotes right after the `def` line.

**When:** Every function, class, and module.

```python
def calculate_grade(score, total=100):
    """
    Calculate a letter grade from a numeric score.
    
    Args:
        score (int): The student's raw score.
        total (int): The maximum possible score. Defaults to 100.
    
    Returns:
        str: The letter grade (A, B, C, D, or F).
    
    Example:
        >>> calculate_grade(85)
        'B'
    """
    percentage = (score / total) * 100
    if percentage >= 90:
        return "A"
    elif percentage >= 80:
        return "B"
    elif percentage >= 70:
        return "C"
    elif percentage >= 60:
        return "D"
    else:
        return "F"

# Access docstrings programmatically
print(calculate_grade.__doc__)
```

**In Markly:**
```python
# From utils.py
def extract_pdf(file_bytes):
    """Extracts text page by page from a PDF."""
    ...

def extract_grade(text: str) -> str:
    """Uses regex patterns to find grades within AI-generated text."""
    ...
```

---

## 4.4 Lambda Functions: Quick One-Liners

**What:** A lambda is a small anonymous function written in one line.

**Why:** Useful for short operations you don't want to name.

**How:** `lambda arguments: expression`

**When:** Sorting, filtering, or simple transformations.

```python
# Regular function
def square(x):
    return x ** 2

# Equivalent lambda
square_lambda = lambda x: x ** 2

print(square(5))         # 25
print(square_lambda(5))  # 25

# Common use: sorting
students = [
    {"name": "Alice", "score": 95},
    {"name": "Bob", "score": 82},
    {"name": "Charlie", "score": 88}
]

# Sort by score
students_sorted = sorted(students, key=lambda s: s["score"])
print([s["name"] for s in students_sorted])  # ['Bob', 'Charlie', 'Alice']

# Common use: mapping
numbers = [1, 2, 3, 4]
squared = list(map(lambda x: x ** 2, numbers))
print(squared)  # [1, 4, 9, 16]
```

---

## 4.5 Modules and Imports

**What:** A module is a Python file. Imports let you use code from other files.

**Why:** Organize code into logical files. Reuse code without copying.

**How:** Use `import`, `from ... import`, or `from ... import *`.

**When:** Always! Good programs are split across multiple files.

```python
# Import entire module
import math
print(math.sqrt(16))  # 4.0

# Import specific items
from math import sqrt, pi
print(sqrt(16))  # 4.0
print(pi)        # 3.14159...

# Import with alias
import numpy as np
import pandas as pd

# Import everything (generally not recommended)
from math import *
print(sin(pi / 2))  # 1.0

# Import from your own files
# If you have utils.py in the same folder:
from utils import extract_pdf, extract_docx
```

**In Markly:**
```python
# From utils.py
import fitz           # PyMuPDF for PDFs
import io             # In-memory file objects
import pytesseract    # OCR for images
import base64         # Binary encoding
from PIL import Image # Image processing
from docx import Document  # Word documents
```

---

# PART 5: OBJECT-ORIENTED THINKING

## 5.1 Classes and Objects

**What:** A class is a blueprint for creating objects. An object is an instance of a class.

**Why:** Bundle data (attributes) and behavior (methods) together.

**How:** Use `class` keyword, `__init__` for setup, `self` for instance access.

**When:** Modeling real-world entities with state and behavior.

```python
# Defining a class
class Student:
    def __init__(self, name, age):
        """Constructor: called when creating a new student."""
        self.name = name      # Instance attribute
        self.age = age
        self.grades = []      # Start with empty list
    
    def add_grade(self, subject, score):
        """Add a grade to the student's record."""
        self.grades.append({"subject": subject, "score": score})
    
    def get_average(self):
        """Calculate average score."""
        if not self.grades:
            return 0
        return sum(g["score"] for g in self.grades) / len(self.grades)
    
    def __str__(self):
        """String representation."""
        return f"Student({self.name}, age {self.age})"

# Creating objects (instances)
alice = Student("Alice", 16)
bob = Student("Bob", 17)

# Using methods
alice.add_grade("Math", 95)
alice.add_grade("Science", 88)
print(alice.get_average())  # 91.5
print(alice)                # Student(Alice, age 16)
```

---

## 5.2 Inheritance: Building on Existing Code

**What:** Inheritance lets a new class use features from an existing class.

**Why:** Avoid duplicating code. Create specialized versions of general classes.

**How:** Put the parent class in parentheses after the class name.

**When:** Creating variations of similar things.

```python
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
    
    def introduce(self):
        return f"Hi, I'm {self.name}."

class Student(Person):  # Student inherits from Person
    def __init__(self, name, age, student_id):
        super().__init__(name, age)  # Call parent's __init__
        self.student_id = student_id
        self.grades = []
    
    def add_grade(self, subject, grade):
        self.grades.append({"subject": subject, "grade": grade})

class Teacher(Person):  # Teacher also inherits from Person
    def __init__(self, name, age, subject):
        super().__init__(name, age)
        self.subject = subject
    
    def grade_student(self, student, subject, grade):
        student.add_grade(subject, grade)

# Usage
alice = Student("Alice", 16, "S001")
mr_smith = Teacher("Mr. Smith", 45, "Math")

print(alice.introduce())  # Hi, I'm Alice. (inherited!)
mr_smith.grade_student(alice, "Math", "A")
```

---

## 5.3 Special Methods (Dunder Methods)

**What:** Methods with double underscores (`__init__`, `__str__`, etc.) that Python calls automatically.

**Why:** Control how your objects behave with built-in operations.

**How:** Define them in your class.

**When:** Customizing object behavior.

```python
class Grade:
    def __init__(self, score, total=100):
        self.score = score
        self.total = total
    
    def __str__(self):
        return f"{self.score}/{self.total}"
    
    def __repr__(self):
        return f"Grade({self.score}, {self.total})"
    
    def __eq__(self, other):
        """Check if two grades are equal."""
        return self.score == other.score
    
    def __lt__(self, other):
        """Check if this grade is less than another."""
        return self.score < other.score
    
    def __add__(self, other):
        """Add two grades together."""
        return Grade(self.score + other.score, self.total + other.total)
    
    def __len__(self):
        """Return 'length' (we'll use it for percentage)."""
        return int((self.score / self.total) * 100)

# Usage
g1 = Grade(85)
g2 = Grade(90)

print(str(g1))       # 85/100
print(repr(g1))      # Grade(85, 100)
print(g1 == g2)      # False
print(g1 < g2)       # True
print(g1 + g2)       # 175/200
print(len(g1))       # 85
```

---

# PART 6: EXTERNAL LIBRARIES

## 6.1 Installing Packages with pip

**What:** `pip` is Python's package installer. It downloads libraries from PyPI (Python Package Index).

**Why:** Python's standard library is great, but external packages add superpowers.

**How:** Run `pip install package_name` in your terminal.

**When:** Before using any non-standard library.

```bash
# Install a single package
pip install requests

# Install specific version
pip install requests==2.31.0

# Install from requirements file
pip install -r requirements.txt

# List installed packages
pip list

# Uninstall a package
pip uninstall requests
```

**In Markly (requirements.txt):**
```
panel==1.9.3
openai==2.43.0
PyMuPDF==1.27.2.3
python-docx==1.2.0
pytesseract==0.3.13
pillow==12.2.0
reportlab==5.0.0
python-dotenv==1.2.2
```

---

## 6.2 Virtual Environments

**What:** A virtual environment is an isolated Python installation for a project.

**Why:** Different projects need different package versions. Isolation prevents conflicts.

**How:** Use `venv` module.

**When:** Starting any new Python project.

```bash
# Create a virtual environment
python -m venv myenv

# Activate it (Windows)
myenv\Scripts\activate

# Activate it (Mac/Linux)
source myenv/bin/activate

# You'll see (myenv) in your terminal prompt
# Now install packages - they'll only exist in this environment
pip install requests

# Deactivate when done
deactivate
```

---

## 6.3 Regular Expressions (regex) with `re`

**What:** Regex is a language for pattern matching in text.

**Why:** Extract specific information (grades, emails, phone numbers) from messy text.

**How:** Use the `re` module with pattern strings.

**When:** Parsing AI responses, validating input, or extracting data.

```python
import re

# Basic matching
text = "The grade is 85/100"
pattern = r"\d+"  # One or more digits
match = re.search(pattern, text)
print(match.group())  # 85

# Common patterns
# \d     = digit (0-9)
# \w     = word character (letter, digit, underscore)
# \s     = whitespace
# .     = any character
# +       = one or more
# *       = zero or more
# ?       = zero or one
# ^       = start of string
# $       = end of string
# []      = character class
# ()      = capture group

# Extracting grade patterns
text = "Grade: A\nScore: 85/100"

# Pattern for "85/100"
score_pattern = r"(\d+)\s*/\s*(\d+)"
match = re.search(score_pattern, text)
if match:
    score = match.group(1)   # 85
    total = match.group(2)   # 100
    print(f"Score: {score}/{total}")

# Pattern for letter grade
grade_pattern = r"Grade[:\s]*([A-F][+-]?)"
match = re.search(grade_pattern, text, re.IGNORECASE)
if match:
    print(match.group(1))  # A

# Find all matches
text = "Scores: 85, 92, 78, 95"
all_scores = re.findall(r"\d+", text)
print(all_scores)  # ['85', '92', '78', '95']

# Replace text
text = "The grade is F"
new_text = re.sub(r"F", "A", text)
print(new_text)  # The grade is A
```

**In Markly:**
```python
# From utils.py
def extract_grade(text: str) -> str:
    if not text:
        return "N/A"
    patterns = [
        r"\b(\d{1,2}(?:.\d+)?)\s*/\s*10\b",
        r"\bGrade[:\s]* ([A-F][+-]?)\b",
        r"\b(\d{1,2}(?:.\d+)?)\s*/\s*(?:100|20|50)\b",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.I)  # re.I = case-insensitive
        if m:
            if "Grade" in pat:
                return m.group(1)
            return m.group(0).replace(" ", "")
    return "N/A"
```

---

## 6.4 Base64 Encoding

**What:** Base64 converts binary data (images, files) into text-safe strings.

**Why:** JSON and HTTP can only handle text. Base64 lets you embed binary data.

**How:** Use the `base64` module.

**When:** Sending images to AI APIs, embedding files in JSON.

```python
import base64

# Original binary data
binary_data = b"\x89PNG\r\n\x1a\n"  # PNG file header

# Encode to base64
encoded = base64.b64encode(binary_data)
print(encoded)  # b'iVBO...' (bytes)

# Decode to string for JSON
string_version = encoded.decode("utf-8")
print(string_version)  # iVBO... (str)

# Decode back to binary
decoded = base64.b64decode(string_version)
print(decoded == binary_data)  # True

# Common workflow
with open("photo.jpg", "rb") as f:
    image_bytes = f.read()

base64_string = base64.b64encode(image_bytes).decode("utf-8")
# Now you can put base64_string in JSON!
```

**In Markly:**
```python
# From utils.py
def image_to_base64(file_bytes):
    """Encodes image bytes to base64 for AI API consumption."""
    return base64.b64encode(file_bytes).decode("utf-8")
```

---

## 6.5 In-Memory File Objects with `io`

**What:** The `io` module lets you create file-like objects in memory (RAM) instead of on disk.

**Why:** Faster than disk I/O. Essential for web apps and data pipelines.

**How:** Use `io.BytesIO` for binary data, `io.StringIO` for text.

**When:** Processing uploaded files, generating PDFs in memory, or any temporary storage.

```python
import io

# BytesIO: in-memory binary buffer
buffer = io.BytesIO()
buffer.write(b"Hello, World!")
buffer.seek(0)  # Reset to beginning
print(buffer.read())  # b'Hello, World!'

# StringIO: in-memory text buffer
text_buffer = io.StringIO()
text_buffer.write("Hello, World!")
text_buffer.seek(0)
print(text_buffer.read())  # Hello, World!

# Simulating a file
fake_file = io.BytesIO(b"PDF content here")
# Now you can pass fake_file to anything expecting a file object!

# Getting the raw bytes
buffer = io.BytesIO()
buffer.write(b"data")
raw_bytes = buffer.getvalue()
print(raw_bytes)  # b'data'
```

**In Markly:**
```python
# From utils.py
def extract_docx(file_bytes):
    document = Document(io.BytesIO(file_bytes))
    return "\n".join([paragraph.text for paragraph in document.paragraphs])

def extract_image(file_bytes):
    image = Image.open(io.BytesIO(file_bytes))
    return pytesseract.image_to_string(image)

# From report.py
buffer = io.BytesIO()  # PDF built entirely in memory
doc = SimpleDocTemplate(buffer, pagesize=A4)
```

---

# PART 7: IMAGE PROCESSING WITH PILLOW

## 7.1 Introduction to Pillow (PIL)

**What:** Pillow is Python's main image processing library. "PIL" stands for Python Imaging Library.

**Why:** Open, edit, draw on, and save images programmatically.

**How:** Import from `PIL` package.

**When:** Any image manipulation — resizing, drawing, filtering, or creating from scratch.

```python
from PIL import Image, ImageDraw, ImageFont

# Open an image
img = Image.open("photo.jpg")
print(img.size)   # (width, height)
print(img.mode)   # 'RGB' or 'RGBA'

# Basic operations
img_resized = img.resize((300, 200))
img_rotated = img.rotate(45)
img.save("output.png")

# Create a new image from scratch
new_img = Image.new("RGB", (400, 300), color="blue")
new_img.save("blue.png")
```

---

## 7.2 Image Modes and Color Systems

**What:** Image mode defines how colors are stored.

**Why:** Different modes use different amounts of memory and support different features.

**How:** Check with `.mode`, convert with `.convert()`.

**When:** Working with transparency, grayscale, or color images.

```python
from PIL import Image

# Common modes:
# "L"     = Grayscale (1 byte per pixel)
# "RGB"   = Red, Green, Blue (3 bytes per pixel)
# "RGBA"  = RGB + Alpha (transparency) (4 bytes per pixel)
# "1"     = Black and white (1 bit per pixel)

img = Image.open("photo.png")
print(img.mode)  # Might be 'RGB' or 'RGBA'

# Convert between modes
rgb = img.convert("RGB")      # Remove transparency
rgba = img.convert("RGBA")    # Add transparency channel
gray = img.convert("L")       # Grayscale

# RGBA colors are tuples: (Red, Green, Blue, Alpha)
# Each value is 0-255
red = (255, 0, 0, 255)        # Fully opaque red
transparent_red = (255, 0, 0, 128)  # Semi-transparent
```

**In Markly:**
```python
# From markup.py
base = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
# Converts to RGBA to support transparency for annotations
```

---

## 7.3 Drawing on Images with ImageDraw

**What:** `ImageDraw` lets you draw shapes, lines, and text on images.

**Why:** Create annotations, highlights, and visual feedback.

**How:** Create a draw object from an image, then call drawing methods.

**When:** Marking up student assignments with teacher-style annotations.

```python
from PIL import Image, ImageDraw, ImageFont

# Create image and draw object
img = Image.new("RGB", (400, 300), color="white")
draw = ImageDraw.Draw(img)

# Draw shapes
draw.rectangle([50, 50, 150, 100], fill="red", outline="black", width=2)
draw.ellipse([200, 50, 300, 150], fill="blue", outline="black")
draw.line([50, 200, 350, 200], fill="green", width=3)
draw.polygon([(100, 250), (150, 200), (200, 250)], fill="yellow")

# Draw text
try:
    font = ImageFont.truetype("arial.ttf", 20)
except:
    font = ImageFont.load_default()

draw.text((50, 150), "Hello, Student!", fill="black", font=font)

img.save("drawing.png")
```

**In Markly:**
```python
# From markup.py - all annotations use ImageDraw
def _jittered_line(draw, x0, y0, x1, y1, fill, width=2, segments=6):
    pts = []
    for i in range(segments + 1):
        t = i / segments
        px = x0 + (x1 - x0) * t + _jitter(0, 1.5)
        py = y0 + (y1 - y0) * t + _jitter(0, 1.5)
        pts.append((px, py))
    for i in range(len(pts) - 1):
        draw.line([pts[i], pts[i + 1]], fill=fill, width=width)
```

---

## 7.4 Fonts and Text Rendering

**What:** `ImageFont` loads fonts for drawing text on images.

**Why:** Control text appearance — size, style, and font family.

**How:** Load TrueType fonts or use the default.

**When:** Adding labels, scores, or feedback text to images.

```python
from PIL import Image, ImageDraw, ImageFont

# Load a TrueType font
font = ImageFont.truetype("arial.ttf", size=24)

# Or use default (always available)
default_font = ImageFont.load_default()

# Bold/italic variants
bold_font = ImageFont.truetype("arialbd.ttf", size=24)
italic_font = ImageFont.truetype("ariali.ttf", size=24)

# Get text size
bbox = font.getbbox("Hello")
width = bbox[2] - bbox[0]
height = bbox[3] - bbox[1]
print(f"Text size: {width}x{height}")

# Draw text
draw = ImageDraw.Draw(Image.new("RGB", (400, 200)))
draw.text((50, 50), "Grade: A+", fill="red", font=font)
```

**In Markly:**
```python
# From markup.py - font caching for performance
_FONT_CACHE = {}

def _font(size: int, bold: bool = False, italic: bool = False):
    key = (size, bold, italic)  # Tuple key for cache
    if key in _FONT_CACHE:
        return _FONT_CACHE[key]
    # Load and cache font...
```

---

## 7.5 Alpha Channels and Transparency

**What:** The alpha channel controls transparency (0 = invisible, 255 = fully visible).

**Why:** Create overlays, highlights, and semi-transparent effects.

**How:** Work with RGBA mode and alpha layers.

**When:** Creating subtle highlights or watermark-like annotations.

```python
from PIL import Image

# Create a semi-transparent overlay
base = Image.open("photo.jpg").convert("RGBA")
overlay = Image.new("RGBA", base.size, (255, 255, 0, 50))  # Yellow, very transparent

# Composite (blend) images
result = Image.alpha_composite(base, overlay)
result.save("highlighted.png")

# Working with alpha layers separately
img = Image.new("RGBA", (400, 300), (0, 0, 0, 0))  # Fully transparent
draw = ImageDraw.Draw(img)
draw.rectangle([50, 50, 150, 150], fill=(255, 0, 0, 100))  # Semi-transparent red
```

**In Markly:**
```python
# From markup.py - correction boxes use alpha for subtle highlighting
def _draw_correction_box(draw, left, top, right, bottom, color, alpha_layer):
    ad = ImageDraw.Draw(alpha_layer)
    _rounded_rect(ad, int(left), int(top), int(right), int(bottom), 6,
                  fill=(*color[:3], 35))  # Very transparent fill
    _rounded_rect(draw, int(left), int(top), int(right), int(bottom), 6,
                  outline=color, width=3)  # Solid outline
```

---

# PART 8: PDF GENERATION WITH REPORTLAB

## 8.1 Introduction to ReportLab

**What:** ReportLab is Python's premier library for creating PDFs programmatically.

**Why:** Generate professional reports, invoices, and documents without manual tools.

**How:** Build documents from "flowables" (paragraphs, tables, images).

**When:** Creating downloadable reports from application data.

```python
from reportlab.lib.pagesizes import A4, letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
import io

# Create PDF in memory
buffer = io.BytesIO()
doc = SimpleDocTemplate(buffer, pagesize=A4)

# Get styles
styles = getSampleStyleSheet()

# Build content
story = [
    Paragraph("Hello, World!", styles["Title"]),
    Spacer(1, 12),
    Paragraph("This is my first PDF.", styles["BodyText"]),
]

# Generate PDF
doc.build(story)

# Get the bytes
buffer.seek(0)
pdf_bytes = buffer.getvalue()
print(f"PDF size: {len(pdf_bytes)} bytes")
```

---

## 8.2 Page Sizes and Units

**What:** ReportLab uses points (1/72 inch) as default units. `mm` provides metric.

**Why:** Precise control over layout dimensions.

**How:** Import from `reportlab.lib.pagesizes` and `reportlab.lib.units`.

**When:** Setting up document templates and table widths.

```python
from reportlab.lib.pagesizes import A4, letter, landscape
from reportlab.lib.units import mm, cm, inch

# Standard sizes
print(A4)        # (595.27, 841.89) in points
print(letter)    # (612.0, 792.0) in points

# Converting units
print(10 * mm)   # 28.35 points
print(1 * cm)    # 28.35 points
print(1 * inch)  # 72.0 points

# Landscape orientation
wide_page = landscape(A4)
print(wide_page)  # (841.89, 595.27)

# Custom size
from reportlab.lib.pagesizes import mm
custom = (210*mm, 297*mm)  # Same as A4
```

**In Markly:**
```python
# From report.py
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm

t = Table(data, colWidths=[38*mm, None])  # Fixed + flexible columns
```

---

## 8.3 Paragraphs and Styles

**What:** `Paragraph` is ReportLab's text container with HTML-like markup.

**Why:** Rich text formatting without complex positioning.

**How:** Create with text and style, use HTML tags for formatting.

**When:** Any text content in PDFs.

```python
from reportlab.platypus import Paragraph
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

styles = getSampleStyleSheet()

# Available styles
print(list(styles.keys()))
# ['Normal', 'Title', 'Heading1', 'Heading2', 'Heading3',
#  'Heading4', 'Heading5', 'Heading6', 'Bullet', 'Definition',
#  'Code', 'Italic', 'BodyText']

# Using built-in styles
title = Paragraph("<b>Report Title</b>", styles["Title"])
body = Paragraph("This is <i>italic</i> and <b>bold</b> text.", styles["BodyText"])

# Custom style
custom_style = ParagraphStyle(
    'Custom',
    parent=styles['Normal'],
    fontSize=14,
    textColor='red',
    spaceAfter=12
)
custom = Paragraph("Custom styled text", custom_style)

# HTML-like tags supported
# <b>bold</b>, <i>italic</i>, <u>underline</u>
# <super>superscript</super>, <sub>subscript</sub>
# <font color="red" size="14">colored text</font>
```

**In Markly:**
```python
# From report.py
def _meta_table(student, subject, filename, styles):
    data = [
        [Paragraph("<b>Student</b>", styles["SmallMeta"]),
         Paragraph(student, styles["BodyText"])],
        [Paragraph("<b>Subject</b>", styles["SmallMeta"]),
         Paragraph(subject, styles["BodyText"])],
    ]
```

---

## 8.4 Tables in PDFs

**What:** `Table` creates structured grids of data in PDFs.

**Why:** Present tabular data cleanly — grades, metadata, schedules.

**How:** Create with data matrix, style with `TableStyle`.

**When:** Any grid-like data presentation.

```python
from reportlab.platypus import Table, TableStyle
from reportlab.lib import colors

# Table data (list of rows, each row is a list of cells)
data = [
    ["Subject", "Score", "Grade"],
    ["Math", "95", "A"],
    ["Science", "88", "B+"],
]

t = Table(data, colWidths=[100, 80, 80])

# Styling
t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), colors.grey),   # Header background
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),  # Header text
    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),          # Center all text
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'), # Bold header
    ('FONTSIZE', (0, 0), (-1, 0), 14),              # Header font size
    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),         # Header padding
    ('BACKGROUND', (0, 1), (-1, -1), colors.beige), # Row background
    ('GRID', (0, 0), (-1, -1), 1, colors.black),    # Grid lines
]))

# TableStyle commands:
# ('BACKGROUND', start_cell, end_cell, color)
# ('TEXTCOLOR', start_cell, end_cell, color)
# ('ALIGN', start_cell, end_cell, alignment)
# ('FONTNAME', start_cell, end_cell, font_name)
# ('FONTSIZE', start_cell, end_cell, size)
# ('GRID', start_cell, end_cell, width, color)
# ('SPAN', start_cell, end_cell) - merge cells
```

**In Markly:**
```python
# From report.py
def _meta_table(student, subject, filename, styles):
    data = [
        [Paragraph("<b>Student</b>", styles["SmallMeta"]),
         Paragraph(student, styles["BodyText"])],
        [Paragraph("<b>Subject</b>", styles["SmallMeta"]),
         Paragraph(subject, styles["BodyText"])],
        [Paragraph("<b>File</b>", styles["SmallMeta"]),
         Paragraph(filename, styles["SmallMeta"])],
    ]
    t = Table(data, colWidths=[38*mm, None])
    return t
```

---

# PART 9: DOCUMENT PARSING

## 9.1 PyMuPDF (fitz) for PDFs

**What:** PyMuPDF (imported as `fitz`) is a fast PDF processing library.

**Why:** Extract text, images, and metadata from PDFs efficiently.

**How:** Open PDFs from files or byte streams, iterate pages.

**When:** Processing uploaded PDF assignments.

```python
import fitz  # PyMuPDF

# Open from file
doc = fitz.open("document.pdf")

# Open from bytes (uploaded files)
with open("document.pdf", "rb") as f:
    file_bytes = f.read()
doc = fitz.open(stream=file_bytes, filetype="pdf")

# Get info
print(f"Pages: {len(doc)}")
print(f"Metadata: {doc.metadata}")

# Extract text from all pages
full_text = ""
for page in doc:
    text = page.get_text()
    full_text += text + "\n"

# Extract from specific page
page = doc[0]  # First page
text = page.get_text()

# Get page as image (for OCR or display)
pix = page.get_pixmap()
pix.save("page.png")

# Close when done
doc.close()
```

**In Markly:**
```python
# From utils.py
def extract_pdf(file_bytes):
    document = fitz.open(stream=file_bytes, filetype="pdf")
    return "\n".join([page.get_text() for page in document])
```

---

## 9.2 python-docx for Word Documents

**What:** `python-docx` reads and writes Microsoft Word (.docx) files.

**Why:** Extract structured text from Word documents without Microsoft Office.

**How:** Open document, iterate paragraphs and tables.

**When:** Processing uploaded Word assignments.

```python
from docx import Document

# Open a document
doc = Document("essay.docx")

# Read paragraphs
for paragraph in doc.paragraphs:
    print(paragraph.text)

# Read tables
for table in doc.tables:
    for row in table.rows:
        for cell in row.cells:
            print(cell.text)

# From bytes (uploaded files)
import io
with open("essay.docx", "rb") as f:
    file_bytes = f.read()
doc = Document(io.BytesIO(file_bytes))
```

**In Markly:**
```python
# From utils.py
def extract_docx(file_bytes):
    document = Document(io.BytesIO(file_bytes))
    return "\n".join([paragraph.text for paragraph in document.paragraphs])
```

---

## 9.3 Pytesseract for OCR

**What:** Pytesseract is a Python wrapper for Google's Tesseract OCR engine.

**Why:** Convert images of text into actual text that computers can process.

**How:** Pass a PIL Image to `image_to_string()`.

**When:** Students submit photos of handwritten or printed work.

```python
import pytesseract
from PIL import Image

# Basic OCR
img = Image.open("homework.jpg")
text = pytesseract.image_to_string(img)
print(text)

# Specify language
chinese_text = pytesseract.image_to_string(img, lang='chi_sim')

# Get bounding box data
data = pytesseract.image_to_data(img, output_type=pytesseract.Output.DICT)
for i, word in enumerate(data['text']):
    if word.strip():
        print(f"Word: {word}, Position: ({data['left'][i]}, {data['top'][i]})")

# From bytes
import io
with open("homework.jpg", "rb") as f:
    file_bytes = f.read()
img = Image.open(io.BytesIO(file_bytes))
text = pytesseract.image_to_string(img)
```

**In Markly:**
```python
# From utils.py
def extract_image(file_bytes):
    image = Image.open(io.BytesIO(file_bytes))
    return pytesseract.image_to_string(image)
```

---

# PART 10: PATTERN GLOSSARY

## Pattern 1: The Dispatcher Pattern

**What:** Route different inputs to different handlers based on a key.

**Why:** Clean, extensible code that doesn't need endless if-else chains.

```python
# Instead of this:
def process_file(filename, data):
    if filename.endswith('.pdf'):
        return process_pdf(data)
    elif filename.endswith('.docx'):
        return process_docx(data)
    # ... more elifs

# Use a dispatcher:
HANDLERS = {
    'pdf': process_pdf,
    'docx': process_docx,
    'png': process_image,
    'jpg': process_image,
}

def process_file(filename, data):
    ext = filename.split('.')[-1].lower()
    handler = HANDLERS.get(ext)
    if handler:
        return handler(data)
    raise ValueError(f"Unknown format: {ext}")
```

---

## Pattern 2: Defensive Programming

**What:** Expect things to go wrong and handle them gracefully.

**Why:** Programs that crash are frustrating. Programs that recover are robust.

```python
# Defensive loading
def load_config(filename):
    if not os.path.exists(filename):
        return {}  # Return default instead of crashing
    try:
        with open(filename, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}  # Corrupted file? Return default.

# Defensive parsing
def safe_int(value, default=0):
    try:
        return int(value)
    except (ValueError, TypeError):
        return default
```

---

## Pattern 3: Caching/Memoization

**What:** Store expensive computation results to avoid recalculating.

**Why:** Loading fonts, parsing files, or computing values can be slow.

```python
# Simple cache with dictionary
_FONT_CACHE = {}

def get_font(name, size):
    key = (name, size)
    if key not in _FONT_CACHE:
        _FONT_CACHE[key] = ImageFont.truetype(name, size)
    return _FONT_CACHE[key]

# Using functools (built-in)
from functools import lru_cache

@lru_cache(maxsize=128)
def fibonacci(n):
    if n < 2:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

print(fibonacci(100))  # Instant, even though it's recursive!
```

---

## Pattern 4: Context Managers

**What:** Automatic resource management (setup and cleanup).

**Why:** Prevents leaks. Guarantees cleanup even with errors.

```python
# Custom context manager
from contextlib import contextmanager

@contextmanager
def managed_resource(name):
    print(f"Acquiring {name}...")
    resource = {"name": name}
    try:
        yield resource
    finally:
        print(f"Releasing {name}...")

with managed_resource("database") as db:
    print(f"Using {db['name']}")
# Output:
# Acquiring database...
# Using database
# Releasing database...
```

---

## Pattern 5: Factory Functions

**What:** Functions that create and configure objects.

**Why:** Centralize object creation logic. Make code more flexible.

```python
from datetime import datetime

def create_student_record(name, subject, grade):
    """Factory: creates properly structured student record."""
    return {
        "name": name,
        "subject": subject,
        "grade": grade,
        "timestamp": datetime.now().isoformat(),
        "history": []
    }

# Usage
alice = create_student_record("Alice", "Math", "A")
```

---

## Pattern 6: The Builder Pattern

**What:** Construct complex objects step by step.

**Why:** Simplifies creation of objects with many optional parts.

```python
class PDFBuilder:
    def __init__(self):
        self.elements = []
    
    def add_title(self, text):
        self.elements.append(Paragraph(text, styles["Title"]))
        return self  # Enable chaining
    
    def add_text(self, text):
        self.elements.append(Paragraph(text, styles["BodyText"]))
        return self
    
    def add_spacer(self, height):
        self.elements.append(Spacer(1, height))
        return self
    
    def build(self):
        return self.elements

# Usage with method chaining
pdf = PDFBuilder()
pdf.add_title("Report").add_spacer(12).add_text("Content here...")
elements = pdf.build()
```

---

# APPENDIX: QUICK REFERENCE

## Common Python Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `+` | Addition / Concatenation | `5 + 3`, `"a" + "b"` |
| `-` | Subtraction | `5 - 3` |
| `*` | Multiplication / Repeat | `5 * 3`, `"a" * 3` |
| `/` | Division (always float) | `5 / 2` → `2.5` |
| `//` | Integer division | `5 // 2` → `2` |
| `%` | Modulo (remainder) | `5 % 2` → `1` |
| `**` | Exponentiation | `2 ** 3` → `8` |
| `==` | Equal to | `5 == 5` → `True` |
| `!=` | Not equal to | `5 != 3` → `True` |
| `>` | Greater than | `5 > 3` → `True` |
| `<` | Less than | `5 < 3` → `False` |
| `>=` | Greater than or equal | `5 >= 5` → `True` |
| `<=` | Less than or equal | `5 <= 3` → `False` |
| `and` | Both must be True | `True and False` → `False` |
| `or` | At least one True | `True or False` → `True` |
| `not` | Flip the boolean | `not True` → `False` |
| `in` | Membership test | `"a" in "abc"` → `True` |
| `is` | Same object identity | `None is None` → `True` |

## Common String Methods

| Method | What it does | Example |
|--------|-------------|---------|
| `.lower()` | All lowercase | `"Hello".lower()` → `"hello"` |
| `.upper()` | All uppercase | `"Hello".upper()` → `"HELLO"` |
| `.strip()` | Remove whitespace | `"  hi  ".strip()` → `"hi"` |
| `.split(x)` | Split by x | `"a,b".split(",")` → `["a", "b"]` |
| `.join(list)` | Join with string | `" ".join(["a", "b"])` → `"a b"` |
| `.replace(a, b)` | Replace a with b | `"hi".replace("i", "o")` → `"ho"` |
| `.find(x)` | Find position | `"hello".find("l")` → `2` |
| `.startswith(x)` | Check prefix | `"abc".startswith("a")` → `True` |
| `.endswith(x)` | Check suffix | `"abc".endswith("c")` → `True` |
| `f"{var}"` | f-string formatting | `f"Score: {95}"` → `"Score: 95"` |

## Common List Methods

| Method | What it does | Example |
|--------|-------------|---------|
| `.append(x)` | Add to end | `[1].append(2)` → `[1, 2]` |
| `.insert(i, x)` | Insert at index | `[1, 3].insert(1, 2)` → `[1, 2, 3]` |
| `.remove(x)` | Remove first x | `[1, 2, 1].remove(1)` → `[2, 1]` |
| `.pop()` | Remove & return last | `[1, 2].pop()` → `2` |
| `.pop(i)` | Remove & return at i | `[1, 2, 3].pop(1)` → `2` |
| `.sort()` | Sort in place | `[3, 1].sort()` → `[1, 3]` |
| `.reverse()` | Reverse in place | `[1, 2].reverse()` → `[2, 1]` |
| `.index(x)` | Find position of x | `[1, 2, 3].index(2)` → `1` |
| `.count(x)` | Count occurrences | `[1, 1, 2].count(1)` → `2` |
| `len(list)` | Number of items | `len([1, 2])` → `2` |

## Common Dictionary Methods

| Method | What it does | Example |
|--------|-------------|---------|
| `dict[key]` | Get value | `d["name"]` |
| `dict.get(k, default)` | Safe get | `d.get("age", 0)` |
| `dict.keys()` | All keys | `d.keys()` |
| `dict.values()` | All values | `d.values()` |
| `dict.items()` | All pairs | `d.items()` |
| `key in dict` | Check key exists | `"name" in d` |
| `dict.update(other)` | Merge dicts | `d.update({"b": 2})` |
| `dict.pop(key)` | Remove & return | `d.pop("name")` |
| `len(dict)` | Number of pairs | `len(d)` |

## File Modes Cheat Sheet

| Mode | Meaning | Use When |
|------|---------|----------|
| `"r"` | Read text | Reading existing text files |
| `"w"` | Write text | Creating new or overwriting |
| `"a"` | Append text | Adding to end of file |
| `"r+"` | Read + write | Modifying existing file |
| `"rb"` | Read binary | Reading images, PDFs |
| `"wb"` | Write binary | Writing images, PDFs |
| `"ab"` | Append binary | Adding to binary files |

## Markly Module Map

| Module | Role | Key Concepts |
|--------|------|-------------|
| `utils.py` | File ingestion | Dispatcher pattern, regex, base64, OCR |
| `markup.py` | Image annotations | PIL drawing, random jitter, alpha channels |
| `report.py` | PDF generation | ReportLab, flowables, tables, styles |
| `storage.py` | Data persistence | JSON, defensive loading, file I/O |
| `engine.py` | AI pipeline | API calls, prompt engineering (not shown) |
| `app.py` | UI layer | Panel widgets, callbacks (not shown) |

---
# PART 9: ASYNC PYTHON IN MARKLY

## 9.1 What is Async?

**What:** Async (asynchronous) Python lets your program do multiple things at once without waiting. Instead of blocking and doing nothing while one task finishes, async lets you start a task, move on to other work, and come back when the result is ready.

**Why:** In Markly, grading assignments can be slow — AI API calls, OCR on images, and PDF generation all take time. Async keeps the UI responsive and lets you grade multiple assignments concurrently.

**How:** Use `async` and `await` keywords, plus `asyncio` for running the event loop.

**When:** Any time you have I/O-bound work (network requests, file operations, database calls) where you'd otherwise sit idle waiting.

```python
# Synchronous (blocking) — BAD for UI
import time

def slow_task():
    print("Starting slow task...")
    time.sleep(3)  # Blocks everything for 3 seconds!
    print("Done!")
    return "result"

result = slow_task()  # Your app freezes here
print(result)

# Asynchronous (non-blocking) — GOOD for UI
import asyncio

async def slow_task():
    print("Starting slow task...")
    await asyncio.sleep(3)  # Other tasks can run during this wait!
    print("Done!")
    return "result"

async def main():
    result = await slow_task()  # Wait here, but let other things happen
    print(result)

asyncio.run(main())
```

---

## 9.2 The Event Loop

**What:** The event loop is the heart of async Python. It's a loop that keeps track of all the tasks that are waiting and runs them when they're ready.

**Why:** You don't manage threads manually. The event loop handles switching between tasks for you.

**How:** `asyncio.run()` starts the loop. `await` tells the loop "I'm going to wait, let someone else run."

**When:** Every async program needs an event loop running.

```python
import asyncio

async def say_hello():
    await asyncio.sleep(1)
    print("Hello!")

async def say_goodbye():
    await asyncio.sleep(0.5)
    print("Goodbye!")

async def main():
    # Run them one at a time (sequential)
    await say_hello()   # Wait 1 second
    await say_goodbye() # Wait 0.5 seconds
    # Total: 1.5 seconds

    # Run them at the same time (concurrent)
    task1 = asyncio.create_task(say_hello())
    task2 = asyncio.create_task(say_goodbye())
    await task1  # Both started, now wait for hello
    await task2  # Goodbye probably already finished
    # Total: ~1 second (the longer of the two)

asyncio.run(main())
```

---

## 9.3 `async` and `await`

**What:** `async def` makes a function a coroutine — a function that can pause and resume. `await` is where the pause happens.

**Why:** `await` is the magic that lets the event loop switch to other tasks. Without it, you're still blocking.

**How:** Put `async` before `def`. Put `await` before any async operation.

**When:** Use `await` on anything that returns a coroutine or awaitable.

```python
import asyncio

# async def makes a coroutine
async def fetch_grade(student_id):
    print(f"Fetching grade for {student_id}...")
    await asyncio.sleep(2)  # Simulating network delay
    return {"id": student_id, "grade": "A"}

# You CANNOT call an async function normally!
# result = fetch_grade("S001")  # WRONG! Returns a coroutine object, not the result

# You MUST await it inside another async function
async def main():
    # This is a coroutine object — it hasn't run yet!
    coro = fetch_grade("S001")
    print(type(coro))  # <class 'coroutine'>
    
    # await runs it and waits for the result
    result = await coro
    print(result)  # {'id': 'S001', 'grade': 'A'}

asyncio.run(main())
```

**⚠️ Common Mistake:** Calling an async function without `await` gives you a coroutine object, not the result. It also never runs!

```python
async def get_data():
    return "data"

async def main():
    # WRONG
    result = get_data()  # Just a coroutine object, never executes!
    print(result)        # <coroutine object get_data at 0x...>
    
    # RIGHT
    result = await get_data()
    print(result)        # "data"

asyncio.run(main())
```

---

## 9.4 Running Multiple Tasks Concurrently

**What:** `asyncio.gather()` runs multiple async tasks at the same time and waits for all of them to finish.

**Why:** In Markly, you might want to grade 5 assignments simultaneously instead of one by one.

**How:** Pass multiple coroutines to `asyncio.gather()`.

**When:** You have multiple independent async operations that can run in parallel.

```python
import asyncio

async def grade_assignment(student, subject):
    print(f"Grading {student}'s {subject} assignment...")
    await asyncio.sleep(2)  # Simulating AI API call
    return f"{student}: {subject} = A"

async def main():
    # Sequential — SLOW (10 seconds total)
    result1 = await grade_assignment("Alice", "Math")
    result2 = await grade_assignment("Bob", "Science")
    result3 = await grade_assignment("Charlie", "English")
    result4 = await grade_assignment("Diana", "History")
    result5 = await grade_assignment("Eve", "Programming")
    
    # Concurrent — FAST (~2 seconds total!)
    results = await asyncio.gather(
        grade_assignment("Alice", "Math"),
        grade_assignment("Bob", "Science"),
        grade_assignment("Charlie", "English"),
        grade_assignment("Diana", "History"),
        grade_assignment("Eve", "Programming"),
    )
    print(results)
    # ['Alice: Math = A', 'Bob: Science = A', ...]

asyncio.run(main())
```

---

## 9.5 `asyncio.create_task()`

**What:** `create_task()` schedules a coroutine to run "in the background" on the event loop.

**Why:** Start a task now, do other work, and check on it later. You don't have to wait immediately.

**How:** Wrap a coroutine in `create_task()`, then `await` the task when you need the result.

**When:** You want to fire off work and check results later, or run tasks with timeouts.

```python
import asyncio

async def slow_api_call(name):
    await asyncio.sleep(3)
    return f"Result for {name}"

async def main():
    # Fire off tasks immediately — they start running NOW
    task1 = asyncio.create_task(slow_api_call("Assignment 1"))
    task2 = asyncio.create_task(slow_api_call("Assignment 2"))
    
    # Do other work while they run...
    print("Tasks are running in the background!")
    await asyncio.sleep(1)
    print("Still doing other things...")
    
    # Now wait for results
    result1 = await task1
    result2 = await task2
    print(result1, result2)

asyncio.run(main())
```

---

## 9.6 Timeouts with `asyncio.wait_for()`

**What:** Don't let slow operations hang forever. Set a maximum wait time.

**Why:** AI APIs can be slow or unresponsive. Timeouts prevent your app from freezing.

**How:** Wrap any awaitable in `asyncio.wait_for(awaitable, timeout_seconds)`.

**When:** Any external API call, file download, or operation that might hang.

```python
import asyncio

async def unreliable_api():
    await asyncio.sleep(10)  # Way too slow!
    return "data"

async def main():
    try:
        # Wait max 3 seconds
        result = await asyncio.wait_for(unreliable_api(), timeout=3.0)
        print(result)
    except asyncio.TimeoutError:
        print("API took too long! Using fallback...")
        result = "fallback_data"
    
    print(f"Final result: {result}")

asyncio.run(main())
# Output: API took too long! Using fallback...
#         Final result: fallback_data
```

---

## 9.7 Async Context Managers

**What:** Just like regular context managers (`with` statement), but for async resources like network connections.

**Why:** Clean up async resources (like API clients or database connections) properly.

**How:** Use `async with` instead of `with`.

**When:** Managing async connections, sessions, or any resource that needs async cleanup.

```python
import asyncio

class AsyncAPIClient:
    async def __aenter__(self):
        print("Opening API connection...")
        await asyncio.sleep(0.5)  # Simulating connection setup
        return self
    
    async def __aexit__(self, exc_type, exc, tb):
        print("Closing API connection...")
        await asyncio.sleep(0.5)  # Simulating cleanup
    
    async def fetch(self, endpoint):
        await asyncio.sleep(1)
        return f"Data from {endpoint}"

async def main():
    # async with ensures cleanup happens even if errors occur
    async with AsyncAPIClient() as client:
        data = await client.fetch("/grades")
        print(data)
    # Connection automatically closed here

asyncio.run(main())
# Output:
# Opening API connection...
# Data from /grades
# Closing API connection...
```

---

## 9.8 Async Iterators

**What:** Iterate over data that arrives asynchronously — like streaming API responses.

**Why:** Process data as it arrives instead of waiting for everything to download.

**How:** Use `async for` with an async iterator.

**When:** Streaming responses, reading from async queues, or paginated API results.

```python
import asyncio

class AsyncGradeStream:
    """Simulates streaming grades from an API."""
    def __init__(self, students):
        self.students = students
        self.index = 0
    
    def __aiter__(self):
        return self
    
    async def __anext__(self):
        if self.index >= len(self.students):
            raise StopAsyncIteration
        
        student = self.students[self.index]
        await asyncio.sleep(0.5)  # Simulating network delay
        self.index += 1
        return {"student": student, "grade": "A"}

async def main():
    stream = AsyncGradeStream(["Alice", "Bob", "Charlie"])
    
    # Process grades as they arrive
    async for grade in stream:
        print(f"Received: {grade}")

asyncio.run(main())
# Output (with 0.5s delay between each):
# Received: {'student': 'Alice', 'grade': 'A'}
# Received: {'student': 'Bob', 'grade': 'A'}
# Received: {'student': 'Charlie', 'grade': 'A'}
```

---

## 9.9 Async Queues

**What:** `asyncio.Queue` is a thread-safe, async way to pass data between tasks.

**Why:** One task produces work, another consumes it — perfect for producer/consumer patterns in Markly.

**How:** `await queue.put(item)` to add, `await queue.get()` to remove.

**When:** Pipeline architectures where one stage feeds the next.

```python
import asyncio

async def producer(queue, items):
    """Produces grading jobs."""
    for item in items:
        print(f"Producing: {item}")
        await queue.put(item)
        await asyncio.sleep(0.5)
    await queue.put(None)  # Sentinel to signal done

async def consumer(queue, worker_id):
    """Consumes and processes grading jobs."""
    while True:
        item = await queue.get()
        if item is None:  # Sentinel received
            queue.task_done()
            break
        
        print(f"Worker {worker_id} processing: {item}")
        await asyncio.sleep(1)  # Simulating grading work
        queue.task_done()

async def main():
    queue = asyncio.Queue(maxsize=3)  # Buffer up to 3 items
    
    items = ["Alice-Math", "Bob-Science", "Charlie-English", "Diana-History"]
    
    # Start producer and consumers
    await asyncio.gather(
        producer(queue, items),
        consumer(queue, 1),
        consumer(queue, 2),
    )

asyncio.run(main())
```

---

## 9.10 Mixing Sync and Async Code

**What:** Sometimes you have blocking (synchronous) code inside an async program. You need to run it without blocking the event loop.

**Why:** Libraries like `pytesseract`, `PIL`, and some file operations are synchronous. Running them directly in async code blocks everything.

**How:** Use `asyncio.to_thread()` (Python 3.9+) or `loop.run_in_executor()` to run sync code in a separate thread.

**When:** Calling any blocking library from within async code.

```python
import asyncio
import time

# This is a synchronous, blocking function
def sync_ocr(image_path):
    """Simulates slow OCR processing."""
    time.sleep(3)  # Blocking sleep!
    return f"Text from {image_path}"

async def main():
    # WRONG: This blocks the entire event loop for 3 seconds!
    # result = sync_ocr("photo.jpg")
    
    # RIGHT: Run in a thread pool, don't block the loop
    result = await asyncio.to_thread(sync_ocr, "photo.jpg")
    print(result)

asyncio.run(main())
```

**In Markly context:**
```python
import asyncio
from PIL import Image
import pytesseract

async def extract_image_async(file_bytes):
    """Run synchronous OCR in a thread so it doesn't block."""
    def _do_ocr():
        image = Image.open(io.BytesIO(file_bytes))
        return pytesseract.image_to_string(image)
    
    # to_thread runs the function in a thread pool
    return await asyncio.to_thread(_do_ocr)
```

---

## 9.11 Real-World Markly Example: Concurrent Grading

**What:** Putting it all together — a realistic async pipeline for Markly.

**Why:** Grade multiple assignments concurrently, with timeouts, error handling, and progress tracking.

```python
import asyncio
import random

async def extract_text(file_bytes, filename):
    """Simulate text extraction from various formats."""
    await asyncio.sleep(0.5)  # Simulating I/O
    if filename.endswith(".pdf"):
        return "PDF content extracted"
    elif filename.endswith(".docx"):
        return "DOCX content extracted"
    else:
        return "Image OCR completed"

async def call_ai_api(text, subject):
    """Simulate AI grading API call."""
    await asyncio.sleep(random.uniform(1, 3))  # Variable API latency
    if random.random() < 0.1:  # 10% chance of failure
        raise ConnectionError("AI API timeout")
    return {
        "grade": random.choice(["A", "B", "C"]),
        "feedback": f"Good work on {subject}!",
        "score": random.randint(70, 100)
    }

async def generate_pdf(result):
    """Simulate PDF report generation."""
    await asyncio.sleep(1)
    return f"PDF for {result['student']}"

async def grade_single_assignment(student, subject, file_bytes, filename):
    """Grade one assignment end-to-end."""
    try:
        # Step 1: Extract text (with timeout)
        text = await asyncio.wait_for(
            extract_text(file_bytes, filename),
            timeout=5.0
        )
        
        # Step 2: Call AI (with timeout)
        ai_result = await asyncio.wait_for(
            call_ai_api(text, subject),
            timeout=10.0
        )
        
        # Step 3: Generate PDF
        pdf = await generate_pdf({
            "student": student,
            **ai_result
        })
        
        return {
            "student": student,
            "success": True,
            "grade": ai_result["grade"],
            "pdf": pdf
        }
        
    except asyncio.TimeoutError:
        return {"student": student, "success": False, "error": "Timeout"}
    except Exception as e:
        return {"student": student, "success": False, "error": str(e)}

async def grade_all_assignments(assignments):
    """Grade many assignments concurrently."""
    tasks = [
        grade_single_assignment(
            a["student"], a["subject"], a["file_bytes"], a["filename"]
        )
        for a in assignments
    ]
    
    # Run all grading tasks concurrently
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # Process results
    successful = [r for r in results if isinstance(r, dict) and r.get("success")]
    failed = [r for r in results if isinstance(r, dict) and not r.get("success")]
    
    return successful, failed

async def main():
    # Simulate 5 assignments to grade
    assignments = [
        {"student": "Alice", "subject": "Math", "file_bytes": b"...", "filename": "alice.pdf"},
        {"student": "Bob", "subject": "Science", "file_bytes": b"...", "filename": "bob.docx"},
        {"student": "Charlie", "subject": "English", "file_bytes": b"...", "filename": "charlie.jpg"},
        {"student": "Diana", "subject": "History", "file_bytes": b"...", "filename": "diana.pdf"},
        {"student": "Eve", "subject": "Programming", "file_bytes": b"...", "filename": "eve.png"},
    ]
    
    print("Starting concurrent grading...")
    successful, failed = await grade_all_assignments(assignments)
    
    print(f"\n✅ Successful: {len(successful)}")
    for s in successful:
        print(f"  {s['student']}: Grade {s['grade']}")
    
    print(f"\n❌ Failed: {len(failed)}")
    for f in failed:
        print(f"  {f['student']}: {f['error']}")

asyncio.run(main())
```

---

## 9.12 Key Takeaways

| Concept | What it does | Markly use case |
|---------|-------------|-----------------|
| `async def` | Makes a coroutine function | Define async grading operations |
| `await` | Pause and let other tasks run | Wait for AI API responses |
| `asyncio.gather()` | Run multiple tasks concurrently | Grade 5 assignments at once |
| `asyncio.create_task()` | Start a background task | Fire off PDF generation early |
| `asyncio.wait_for()` | Add timeout to any awaitable | Prevent hanging on slow APIs |
| `asyncio.to_thread()` | Run sync code in a thread | Call pytesseract without blocking |
| `async with` | Async resource management | Manage API client sessions |
| `async for` | Iterate async data streams | Stream AI responses |

---

**In Markly:** Async is essential for keeping the grading pipeline fast and responsive. Without it, grading 10 assignments sequentially might take 30+ seconds. With async concurrency, it could take as little as 3–5 seconds — and your UI stays responsive the whole time.

---
# PART 10: LLMS AND AI AGENTS

## 10.1 What is an LLM?

**What:** An LLM (Large Language Model) is an AI system trained on vast amounts of text to understand and generate human-like language. Think of it as a super-powered autocomplete that can reason, write, analyze, and answer questions.

**Why:** Markly couldn't exist without LLMs. They read student assignments, understand the subject matter, compare against rubrics, and generate personalized feedback — tasks that would take human teachers hours.

**How:** You send the LLM a "prompt" (instructions + context), and it returns a "completion" (the generated response).

**When:** Use LLMs whenever you need language understanding, generation, or reasoning at scale.

```python
# The basic idea (pseudocode)
prompt = """
You are a math teacher. Grade this assignment out of 100.
Assignment: Solve for x: 2x + 5 = 15
Student answer: x = 5
"""

# Send to LLM
response = llm.ask(prompt)

# Get back structured feedback
print(response)
# "Grade: 100/100. The student correctly isolated x by subtracting
#  5 from both sides and dividing by 2. Well done!"
```

---

## 10.2 How LLMs Work (The Simple Version)

**What:** LLMs don't "think" like humans. They predict the most likely next word (token) based on patterns learned from training data.

**Why:** Understanding this helps you write better prompts and set realistic expectations.

**How:** The model converts your text into numbers (tokens), runs them through a neural network with billions of parameters, and decodes the output back into text.

**When:** This knowledge helps debug why an LLM gives unexpected answers.

```python
# Tokenization example (conceptual)
text = "Hello, world!"
tokens = ["Hello", ",", " world", "!"]  # Simplified

# The model sees these as numbers
token_ids = [15496, 11, 995, 0]  # GPT-style token IDs

# It predicts the next token probability distribution
# "!" might have 95% probability after "world"

# Temperature controls randomness
# temperature=0.0  -> Always pick the highest probability token (deterministic)
# temperature=0.7 -> Some randomness (creative but coherent)
# temperature=2.0 -> Very random (often nonsensical)
```

---

## 10.3 Connecting to an LLM API

**What:** You don't run LLMs on your own computer (usually). You call them through APIs over the internet.

**Why:** Running a 70-billion parameter model requires expensive GPUs. APIs let you pay per use.

**How:** Use HTTP requests or SDK libraries like `openai`, `anthropic`, or `httpx` for custom endpoints.

**When:** Every time Markly grades an assignment, it sends a prompt to an LLM API.

```python
# Method 1: Using the OpenAI SDK (recommended)
import openai

client = openai.OpenAI(api_key="your-api-key")

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": "You are a helpful grading assistant."},
        {"role": "user", "content": "Grade this essay: [essay text here]"}
    ],
    temperature=0.7,
    max_tokens=1000
)

print(response.choices[0].message.content)

# Method 2: Using raw HTTP with requests
import requests

response = requests.post(
    "https://api.openai.com/v1/chat/completions",
    headers={
        "Authorization": "Bearer your-api-key",
        "Content-Type": "application/json"
    },
    json={
        "model": "gpt-4o",
        "messages": [
            {"role": "user", "content": "Hello, how are you?"}
        ]
    }
)

data = response.json()
print(data["choices"][0]["message"]["content"])
```

---

## 10.4 API Keys and Environment Variables

**What:** API keys are secret passwords that identify you to the LLM provider. Never hardcode them!

**Why:** If you commit API keys to GitHub, bots will steal them within minutes and rack up thousands in charges.

**How:** Store keys in environment variables or `.env` files, load them with `python-dotenv`.

**When:** Every project that uses external APIs.

```python
# ❌ NEVER DO THIS
client = openai.OpenAI(api_key="sk-abc123...")  # Hardcoded = stolen!

# ✅ CORRECT WAY: Use environment variables

# 1. Create a .env file (add to .gitignore!)
# OPENAI_API_KEY=sk-your-secret-key-here
# ANTHROPIC_API_KEY=sk-ant-your-key-here

# 2. Load in Python
from dotenv import load_dotenv
import os

load_dotenv()  # Loads variables from .env file

api_key = os.getenv("OPENAI_API_KEY")
client = openai.OpenAI(api_key=api_key)

# 3. Check if key exists
if not api_key:
    raise ValueError("OPENAI_API_KEY not found! Check your .env file.")
```

**In Markly (requirements.txt includes `python-dotenv`):**
```python
# At the top of your main file
from dotenv import load_dotenv
load_dotenv()

# Now os.getenv works everywhere
OPENAI_KEY = os.getenv("OPENAI_API_KEY")
```

---

## 10.5 The Chat Completions Format

**What:** Modern LLMs use a "chat" format with messages having roles: `system`, `user`, and `assistant`.

**Why:** The `system` role sets the behavior. The `user` provides input. The `assistant` is the AI's response.

**How:** Build a list of message dictionaries and send to the API.

**When:** Every LLM call in Markly uses this format.

```python
messages = [
    # SYSTEM: Sets the AI's persona and rules
    {
        "role": "system",
        "content": """You are an expert high school math teacher.
        You grade assignments fairly and provide constructive feedback.
        Always format grades as 'Score: X/100'."""
    },
    
    # USER: The actual request
    {
        "role": "user",
        "content": """Grade this algebra assignment:
        
        Problem: Solve 3x - 7 = 14
        Student answer: x = 7
        
        Provide:
        1. The correct answer
        2. Student's score out of 100
        3. Specific feedback on errors
        4. Suggestions for improvement"""
    }
]

response = client.chat.completions.create(
    model="gpt-4o",
    messages=messages,
    temperature=0.3,  # Lower = more consistent grading
    max_tokens=500
)

print(response.choices[0].message.content)
```

---

## 10.6 Prompt Engineering Basics

**What:** Prompt engineering is the art of writing instructions that get the LLM to produce exactly what you want.

**Why:** A bad prompt gives garbage output. A good prompt gives structured, accurate, useful results.

**How:** Be specific, provide examples, specify output format, and set constraints.

**When:** Every Markly grading prompt is carefully engineered.

```python
# ❌ BAD PROMPT (vague, unstructured)
prompt = "Grade this essay."

# ✅ GOOD PROMPT (specific, structured, with examples)
prompt = """
You are an AP English Literature teacher grading student essays.

RUBRIC:
- Thesis (25 points): Clear, arguable thesis responding to prompt
- Evidence (25 points): Relevant quotes with analysis
- Organization (25 points): Logical flow, transitions
- Mechanics (25 points): Grammar, spelling, style

OUTPUT FORMAT (STRICT JSON):
{
    "total_score": <0-100>,
    "breakdown": {
        "thesis": <0-25>,
        "evidence": <0-25>,
        "organization": <0-25>,
        "mechanics": <0-25>
    },
    "feedback": "<2-3 sentences of constructive feedback>",
    "strengths": ["<strength 1>", "<strength 2>"],
    "improvements": ["<suggestion 1>", "<suggestion 2>"]
}

ESSAY:
{essay_text}

Respond ONLY with valid JSON. No markdown, no explanations.
"""
```

---

## 10.7 Few-Shot Prompting

**What:** Give the LLM examples of the input/output you want. It learns the pattern from examples.

**Why:** Much more reliable than just describing what you want. Shows, don't tell.

**How:** Include 2-3 examples in your prompt before the actual task.

**When:** When you need consistent formatting or complex reasoning patterns.

```python
prompt = """
You are a math grader. For each problem, output ONLY "Correct" or "Incorrect: [explanation]".

Example 1:
Problem: 2 + 2 = ?
Student: 4
Your response: Correct

Example 2:
Problem: 5 * 6 = ?
Student: 30
Your response: Correct

Example 3:
Problem: 10 / 2 = ?
Student: 5
Your response: Correct

Example 4:
Problem: 7 - 3 = ?
Student: 2
Your response: Incorrect: The student subtracted incorrectly. 7 - 3 = 4, not 2.

Now grade this:
Problem: {problem}
Student: {answer}
Your response:
"""
```

---

## 10.8 Parsing LLM Responses

**What:** LLMs return text. You need to extract structured data from that text.

**Why:** Markly needs grades, scores, and feedback as Python objects — not just text.

**How:** Use regex, JSON parsing, or structured output formats.

**When:** After every LLM call in Markly.

```python
import json
import re

# Method 1: Ask for JSON and parse it
response_text = '''
{
    "grade": "A",
    "score": 95,
    "feedback": "Excellent work on the thesis!"
}
'''

try:
    result = json.loads(response_text)
    print(result["grade"])      # A
    print(result["score"])      # 95
except json.JSONDecodeError:
    print("LLM didn't return valid JSON!")

# Method 2: Extract with regex (fallback)
text_response = "Grade: A\nScore: 95/100\nFeedback: Great job!"

grade_match = re.search(r"Grade:\s*([A-F][+-]?)", text_response)
score_match = re.search(r"Score:\s*(\d+)/100", text_response)
feedback_match = re.search(r"Feedback:\s*(.+)", text_response)

grade = grade_match.group(1) if grade_match else "N/A"
score = int(score_match.group(1)) if score_match else 0
feedback = feedback_match.group(1) if feedback_match else "No feedback"

print(f"Grade: {grade}, Score: {score}, Feedback: {feedback}")
```

**In Markly:**
```python
# From utils.py - extract_grade uses regex as fallback
def extract_grade(text: str) -> str:
    if not text:
        return "N/A"
    patterns = [
        r"\b(\d{1,2}(?:.\d+)?)\s*/\s*10\b",
        r"\bGrade[:\s]* ([A-F][+-]?)\b",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.I)
        if m:
            return m.group(1) if "Grade" in pat else m.group(0)
    return "N/A"
```

---

## 10.9 Handling LLM Errors

**What:** LLMs fail — rate limits, timeouts, bad responses, API outages. Your code must handle this.

**Why:** Markly can't crash just because OpenAI is having a bad day.

**How:** Use try/except, retries with backoff, and fallback models.

**When:** Every production LLM call needs error handling.

```python
import time
import random

def call_llm_with_retry(client, messages, max_retries=3):
    """Call LLM with exponential backoff retry logic."""
    
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model="gpt-4o",
                messages=messages,
                timeout=30  # Don't wait forever
            )
            return response.choices[0].message.content
            
        except openai.RateLimitError:
            # Hit rate limit — wait and retry
            wait_time = (2 ** attempt) + random.uniform(0, 1)
            print(f"Rate limited. Waiting {wait_time:.1f}s...")
            time.sleep(wait_time)
            
        except openai.APITimeoutError:
            print(f"Timeout on attempt {attempt + 1}")
            if attempt == max_retries - 1:
                raise  # Give up after max retries
                
        except Exception as e:
            print(f"Unexpected error: {e}")
            raise
    
    raise Exception("Max retries exceeded")

# Usage
try:
    feedback = call_llm_with_retry(client, grading_messages)
except Exception as e:
    feedback = "Unable to grade at this time. Please try again later."
```

---

## 10.10 Model Racing (Calling Multiple LLMs)

**What:** Send the same prompt to multiple LLM providers and use the first response that comes back.

**Why:** Different providers have different speeds, costs, and strengths. Racing gives you the best of all worlds.

**How:** Use `asyncio.gather()` with `return_exceptions=True` and pick the first valid result.

**When:** Markly uses this to ensure fast, reliable grading regardless of which provider is fastest.

```python
import asyncio
import openai
import anthropic

openai_client = openai.AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))
anthropic_client = anthropic.AsyncAnthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

async def call_openai(messages):
    """Call OpenAI GPT-4o."""
    response = await openai_client.chat.completions.create(
        model="gpt-4o",
        messages=messages,
        max_tokens=1000
    )
    return {"provider": "openai", "content": response.choices[0].message.content}

async def call_anthropic(messages):
    """Call Anthropic Claude."""
    # Convert OpenAI format to Anthropic format
    system_msg = next((m["content"] for m in messages if m["role"] == "system"), "")
    user_msgs = [m["content"] for m in messages if m["role"] == "user"]
    
    response = await anthropic_client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1000,
        system=system_msg,
        messages=[{"role": "user", "content": msg} for msg in user_msgs]
    )
    return {"provider": "anthropic", "content": response.content[0].text}

async def race_llms(messages, timeout=15):
    """Call multiple LLMs and return the first valid response."""
    
    # Create tasks for all providers
    tasks = [
        asyncio.create_task(call_openai(messages)),
        asyncio.create_task(call_anthropic(messages)),
    ]
    
    # Wait for the FIRST one to complete
    done, pending = await asyncio.wait(
        tasks,
        return_when=asyncio.FIRST_COMPLETED,
        timeout=timeout
    )
    
    # Cancel any still-running tasks
    for task in pending:
        task.cancel()
    
    # Get the result from the first completed task
    if done:
        result = await list(done)[0]
        print(f"Winner: {result['provider']}")
        return result["content"]
    
    raise TimeoutError("All LLMs failed to respond in time")

# Usage
async def main():
    messages = [
        {"role": "system", "content": "You are a math teacher."},
        {"role": "user", "content": "Grade: 2+2=4. Score out of 10?"}
    ]
    
    result = await race_llms(messages)
    print(result)

asyncio.run(main())
```

---

## 10.11 Building an AI Agent

**What:** An agent is an LLM-powered system that can make decisions, use tools, and take actions — not just answer questions.

**Why:** Markly's agent doesn't just grade; it decides which rubric to use, extracts grades, generates markup instructions, and coordinates the whole pipeline.

**How:** Give the LLM a system prompt with available tools, let it decide which to use, then execute its choices.

**When:** When you need the AI to do multi-step reasoning with external tools.

```python
import json

class GradingAgent:
    """A simple agent that grades assignments using tools."""
    
    def __init__(self, client):
        self.client = client
        self.tools = {
            "detect_subject": self.detect_subject,
            "load_rubric": self.load_rubric,
            "grade_with_rubric": self.grade_with_rubric,
            "generate_markup": self.generate_markup
        }
    
    def detect_subject(self, text: str) -> str:
        """Tool: Detect the subject from assignment text."""
        subjects = ["math", "english", "science", "history", "programming"]
        text_lower = text.lower()
        for subject in subjects:
            if subject in text_lower:
                return subject
        return "general"
    
    def load_rubric(self, subject: str) -> dict:
        """Tool: Load the grading rubric for a subject."""
        rubrics = {
            "math": {"criteria": ["correctness", "work_shown", "units"], "total": 100},
            "english": {"criteria": ["thesis", "evidence", "grammar"], "total": 100},
        }
        return rubrics.get(subject, rubrics["general"])
    
    def grade_with_rubric(self, text: str, rubric: dict) -> dict:
        """Tool: Call LLM to grade using the rubric."""
        prompt = f"""
        Grade this assignment using this rubric: {json.dumps(rubric)}
        
        Assignment: {text}
        
        Return JSON with scores for each criterion and total.
        """
        response = self.client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}]
        )
        return json.loads(response.choices[0].message.content)
    
    def generate_markup(self, feedback: str) -> list:
        """Tool: Generate image annotation instructions."""
        # Returns coordinates and annotation types
        return [
            {"type": "tick", "x": 100, "y": 200},
            {"type": "comment", "x": 150, "y": 200, "text": feedback[:50]}
        ]
    
    def run(self, assignment_text: str) -> dict:
        """Run the full grading pipeline."""
        
        # Step 1: Detect subject
        subject = self.detect_subject(assignment_text)
        print(f"Detected subject: {subject}")
        
        # Step 2: Load appropriate rubric
        rubric = self.load_rubric(subject)
        print(f"Loaded rubric: {rubric}")
        
        # Step 3: Grade with rubric
        grade_result = self.grade_with_rubric(assignment_text, rubric)
        print(f"Grade result: {grade_result}")
        
        # Step 4: Generate markup instructions
        markup = self.generate_markup(grade_result.get("feedback", ""))
        
        return {
            "subject": subject,
            "rubric": rubric,
            "grade": grade_result,
            "markup_instructions": markup
        }

# Usage
agent = GradingAgent(client)
result = agent.run("""
Problem: Solve for x: 2x + 5 = 15
Student work:
2x + 5 = 15
2x = 10
x = 5
""")
print(json.dumps(result, indent=2))
```

---

## 10.12 The ReAct Pattern (Reasoning + Acting)

**What:** ReAct is a powerful agent pattern where the LLM alternates between THINKING (reasoning) and DOING (calling tools).

**Why:** Complex grading tasks need multi-step reasoning. The LLM should think about what it needs, then act.

**How:** The LLM outputs structured reasoning steps. Your code parses them and executes tool calls.

**When:** When one LLM call isn't enough — you need a chain of reasoning and actions.

```python
class ReActAgent:
    """
    ReAct Agent: Reasoning + Acting
    The LLM thinks step by step and decides which tools to use.
    """
    
    SYSTEM_PROMPT = """
    You are a grading assistant. Solve grading tasks by thinking step by step.
    
    Available tools:
    - extract_text(file_path): Extract text from a document
    - detect_subject(text): Determine the subject area
    - grade(subject, text, rubric): Grade the assignment
    - format_feedback(grade_result): Format feedback for the student
    
    Respond in this EXACT format:
    
    Thought: [your reasoning about what to do next]
    Action: [tool_name]([arguments])
    Observation: [result of the action — filled by the system]
    
    When done:
    Thought: I have completed the grading.
    Final Answer: [the final grading result]
    """
    
    def __init__(self, client):
        self.client = client
        self.tools = {
            "extract_text": self._extract_text,
            "detect_subject": self._detect_subject,
            "grade": self._grade,
            "format_feedback": self._format_feedback
        }
    
    def _extract_text(self, file_path):
        # Simulated — in real Markly this calls utils.py
        return "Student essay about photosynthesis..."
    
    def _detect_subject(self, text):
        if "photosynthesis" in text.lower():
            return "biology"
        return "general"
    
    def _grade(self, subject, text, rubric):
        # Simulated grading
        return {"score": 85, "feedback": "Good understanding of photosynthesis."}
    
    def _format_feedback(self, grade_result):
        return f"Score: {grade_result['score']}/100\nFeedback: {grade_result['feedback']}"
    
    def run(self, task):
        """Run the ReAct loop until the agent finishes."""
        messages = [
            {"role": "system", "content": self.SYSTEM_PROMPT},
            {"role": "user", "content": f"Task: {task}"}
        ]
        
        max_steps = 10
        for step in range(max_steps):
            # Get LLM's next thought/action
            response = self.client.chat.completions.create(
                model="gpt-4o",
                messages=messages,
                temperature=0.2
            )
            output = response.choices[0].message.content
            print(f"\n--- Step {step + 1} ---")
            print(output)
            
            # Check if we're done
            if "Final Answer:" in output:
                return output.split("Final Answer:")[1].strip()
            
            # Parse Thought and Action
            thought = self._extract_thought(output)
            action_str = self._extract_action(output)
            
            if action_str:
                # Execute the tool
                tool_name, args = self._parse_action(action_str)
                if tool_name in self.tools:
                    try:
                        result = self.tools[tool_name](*args)
                        observation = f"Observation: {json.dumps(result)}"
                    except Exception as e:
                        observation = f"Observation: Error — {str(e)}"
                else:
                    observation = f"Observation: Unknown tool '{tool_name}'"
                
                print(observation)
                messages.append({"role": "assistant", "content": output})
                messages.append({"role": "user", "content": observation})
            else:
                break
        
        return "Agent did not complete the task."
    
    def _extract_thought(self, text):
        if "Thought:" in text:
            return text.split("Thought:")[1].split("Action:")[0].strip()
        return ""
    
    def _extract_action(self, text):
        if "Action:" in text and "Final Answer:" not in text:
            return text.split("Action:")[1].split("\n")[0].strip()
        return None
    
    def _parse_action(self, action_str):
        # Simple parser: tool_name(arg1, arg2)
        tool_name = action_str.split("(")[0].strip()
        args_str = action_str.split("(")[1].rstrip(")")
        args = [a.strip().strip('"\'') for a in args_str.split(",") if a.strip()]
        return tool_name, args

# Usage
agent = ReActAgent(client)
result = agent.run("Grade the assignment at path 'essay.docx'")
print(f"\nFinal Result:\n{result}")
```

---

## 10.13 Structured Output with JSON Schema

**What:** Force the LLM to return valid JSON matching a specific structure.

**Why:** No more regex parsing or hoping the LLM follows instructions. Guaranteed valid output.

**How:** Use OpenAI's `response_format` with JSON schema (GPT-4o and newer).

**When:** When you need reliable, parseable output from the LLM.

```python
from pydantic import BaseModel
from openai import OpenAI

# Define your output structure
class GradeResult(BaseModel):
    total_score: int
    grade_letter: str
    feedback: str
    strengths: list[str]
    improvements: list[str]
    rubric_scores: dict[str, int]

client = OpenAI()

# The LLM will return JSON matching this schema
completion = client.beta.chat.completions.parse(
    model="gpt-4o-2024-08-06",
    messages=[
        {
            "role": "system",
            "content": "You are an expert grader. Grade the assignment and return structured data."
        },
        {
            "role": "user",
            "content": "Grade this essay about climate change: [essay text]"
        }
    ],
    response_format=GradeResult,  # Pydantic model = JSON schema
)

result = completion.choices[0].message.parsed
print(result.total_score)      # 87
print(result.grade_letter)     # B+
print(result.feedback)         # "Strong thesis but needs more evidence..."
print(result.rubric_scores)    # {"thesis": 22, "evidence": 18, ...}
```

---

## 10.14 Streaming Responses

**What:** Instead of waiting for the entire response, get tokens as they're generated.

**Why:** Show progress to users. Start processing before the full response arrives.

**How:** Set `stream=True` and iterate over chunks.

**When:** Long grading feedback where users want to see text appearing in real-time.

```python
# Streaming response
stream = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Write detailed feedback for a student essay."}],
    stream=True  # Enable streaming
)

full_response = ""
for chunk in stream:
    if chunk.choices[0].delta.content:
        token = chunk.choices[0].delta.content
        full_response += token
        print(token, end="", flush=True)  # Print as it arrives

print(f"\n\nFull response: {full_response}")
```

---

## 10.15 Cost Tracking and Token Counting

**What:** LLM APIs charge by the token (roughly 4 characters = 1 token). Track usage to manage costs.

**Why:** Markly could process thousands of assignments. Costs add up fast.

**How:** Check `usage` in the API response. Use `tiktoken` to count tokens before sending.

**When:** Every production system needs cost monitoring.

```python
import tiktoken

def count_tokens(text, model="gpt-4o"):
    """Count tokens in text before sending to API."""
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))

# Check prompt size before sending
prompt = "Your very long grading prompt here..."
token_count = count_tokens(prompt)
print(f"Prompt is {token_count} tokens")

# GPT-4o costs ~$0.005 per 1K input tokens, $0.015 per 1K output tokens
estimated_cost = (token_count / 1000) * 0.005
print(f"Estimated cost: ${estimated_cost:.4f}")

# After API call, check actual usage
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": prompt}]
)

print(f"Prompt tokens: {response.usage.prompt_tokens}")
print(f"Completion tokens: {response.usage.completion_tokens}")
print(f"Total tokens: {response.usage.total_tokens}")
```

---

## 10.16 Markly's Complete LLM Pipeline

**What:** Putting it all together — how Markly actually uses LLMs end-to-end.

**Why:** See how every concept connects in the real system.

```python
import os
import json
import asyncio
from typing import Optional
import openai
from dotenv import load_dotenv

load_dotenv()

class MarklyGrader:
    """
    Complete Markly grading pipeline using LLMs.
    """
    
    def __init__(self):
        self.client = openai.AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        self.fallback_client = openai.AsyncOpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=os.getenv("OPENROUTER_API_KEY")
        )
    
    async def detect_subject(self, text: str) -> str:
        """Use LLM to detect the subject from assignment text."""
        prompt = f"""
        What subject is this assignment? Reply with ONLY the subject name.
        Options: math, english, science, history, programming, art, music, other
        
        Assignment (first 500 chars): {text[:500]}
        """
        
        response = await self.client.chat.completions.create(
            model="gpt-4o-mini",  # Cheap model for simple task
            messages=[{"role": "user", "content": prompt}],
            max_tokens=20,
            temperature=0.0  # Deterministic
        )
        
        subject = response.choices[0].message.content.strip().lower()
        return subject if subject in ["math", "english", "science", "history", "programming", "art", "music"] else "other"
    
    async def grade_assignment(
        self,
        student: str,
        subject: str,
        text: str,
        image_b64: Optional[str] = None
    ) -> dict:
        """
        Grade a single assignment using the appropriate persona and rubric.
        """
        # Load subject-specific system prompt
        system_prompt = self._load_persona(subject)
        rubric = self._load_rubric(subject)
        
        # Build the grading prompt
        user_prompt = f"""
        SUBJECT: {subject}
        RUBRIC: {json.dumps(rubric, indent=2)}
        
        STUDENT ASSIGNMENT:
        {text}
        
        Grade this assignment following the rubric exactly.
        Return ONLY valid JSON in this format:
        {{
            "grade": "A-F",
            "score": <number>,
            "total": <number>,
            "feedback": "<detailed feedback>",
            "corrections": [
                {{"location": "<description>", "issue": "<what's wrong>", "correction": "<how to fix>"}}
            ],
            "strengths": ["<strength 1>", "<strength 2>"],
            "markup_instructions": [
                {{"type": "tick|cross|circle|underline|comment", "x": <number>, "y": <number>, "text": "<optional text>"}}
            ]
        }}
        """
        
        # Add image if provided (multimodal)
        messages = [{"role": "system", "content": system_prompt}]
        
        if image_b64:
            messages.append({
                "role": "user",
                "content": [
                    {"type": "text", "text": user_prompt},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"}}
                ]
            })
        else:
            messages.append({"role": "user", "content": user_prompt})
        
        # Try primary model with fallback
        try:
            response = await asyncio.wait_for(
                self.client.chat.completions.create(
                    model="gpt-4o",
                    messages=messages,
                    temperature=0.3,
                    max_tokens=2000
                ),
                timeout=30.0
            )
            result_text = response.choices[0].message.content
            
        except (asyncio.TimeoutError, Exception) as e:
            print(f"Primary model failed: {e}. Trying fallback...")
            response = await self.fallback_client.chat.completions.create(
                model="anthropic/claude-3.5-sonnet",
                messages=messages,
                temperature=0.3,
                max_tokens=2000
            )
            result_text = response.choices[0].message.content
        
        # Parse the structured response
        return self._parse_grading_result(result_text, student, subject)
    
    def _load_persona(self, subject: str) -> str:
        """Load the teaching persona for a subject."""
        personas = {
            "math": "You are a patient high school math teacher...",
            "english": "You are an AP English Literature teacher...",
            "science": "You are a passionate biology teacher...",
        }
        return personas.get(subject, "You are a helpful teacher.")
    
    def _load_rubric(self, subject: str) -> dict:
        """Load the grading rubric for a subject."""
        rubrics = {
            "math": {
                "correctness": 40,
                "work_shown": 30,
                "units_and_notation": 20,
                "clarity": 10
            },
            # ... more rubrics
        }
        return rubrics.get(subject, {"general_quality": 100})
    
    def _parse_grading_result(self, text: str, student: str, subject: str) -> dict:
        """Parse and validate the LLM's grading output."""
        # Try to extract JSON from markdown code blocks
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0]
        elif "```" in text:
            text = text.split("```")[1].split("```")[0]
        
        try:
            result = json.loads(text.strip())
        except json.JSONDecodeError:
            # Fallback: extract what we can with regex
            result = {
                "grade": "N/A",
                "score": 0,
                "total": 100,
                "feedback": text[:500],
                "corrections": [],
                "strengths": [],
                "markup_instructions": []
            }
        
        # Add metadata
        result["student"] = student
        result["subject"] = subject
        return result
    
    async def grade_batch(self, assignments: list[dict]) -> list[dict]:
        """Grade multiple assignments concurrently."""
        tasks = [
            self.grade_assignment(
                a["student"],
                a["subject"],
                a["text"],
                a.get("image_b64")
            )
            for a in assignments
        ]
        return await asyncio.gather(*tasks, return_exceptions=True)

# Usage
async def main():
    grader = MarklyGrader()
    
    assignments = [
        {
            "student": "Alice",
            "subject": "math",
            "text": "2x + 5 = 15\nx = 5",
        },
        {
            "student": "Bob", 
            "subject": "english",
            "text": "The Great Gatsby explores the American Dream...",
        }
    ]
    
    results = await grader.grade_batch(assignments)
    for r in results:
        if isinstance(r, dict):
            print(f"{r['student']}: {r['grade']} ({r['score']}/{r['total']})")
        else:
            print(f"Error: {r}")

asyncio.run(main())
```

---

## 10.17 Key Takeaways

| Concept | What it does | Markly use case |
|---------|-------------|-----------------|
| **LLM API** | Send prompts, get completions | Every grading operation |
| **System prompt** | Set AI persona and rules | Subject-specific grading personalities |
| **Prompt engineering** | Write effective instructions | Get structured, accurate grades |
| **JSON schema** | Force structured output | Reliable grade parsing |
| **Error handling** | Retry, fallback, timeout | Never crash on API failures |
| **Model racing** | Call multiple providers | Fastest response wins |
| **Token counting** | Track API costs | Budget management |
| **ReAct agent** | Reasoning + tool use | Multi-step grading pipeline |
| **Async LLM calls** | Non-blocking API requests | Grade 10 assignments at once |
| **Multimodal** | Text + image input | Grade handwritten assignments |

---

**🎓 Without LLMs, Markly is just a file parser.** The AI is what transforms extracted text into meaningful grades, personalized feedback, and visual annotations. Understanding how to talk to LLMs effectively — prompt engineering, error handling, structured output — is the single most important skill for building AI-powered applications like Markly.

---

# PART 11: BUILDING INTERFACES WITH PANEL

## 11.1 What is Panel?

**What:** Panel is a Python library for building interactive web apps and dashboards. You write Python, and Panel turns it into a web page — no HTML, CSS, or JavaScript required.

**Why:** Markly needs a user interface where teachers upload assignments, see grades, and download PDFs. Panel lets you build this entirely in Python.

**How:** Create widgets (buttons, text boxes, file uploaders), arrange them in layouts, and connect them to Python functions with callbacks.

**When:** Any time you need a web-based UI for a Python tool — dashboards, data apps, or tools like Markly.

```python
import panel as pn

# A minimal Panel app
pn.extension()

text = pn.widgets.TextInput(name="Student Name", value="Alice")
button = pn.widgets.Button(name="Say Hello", button_type="primary")
output = pn.pane.Markdown("Enter a name and click the button.")

def on_click(event):
    output.object = f"Hello, {text.value}!"

button.on_click(on_click)

# Arrange widgets in a layout
app = pn.Column(
    "# My First Panel App",
    text,
    button,
    output
)

app.servable()  # Run with: panel serve script.py
```

---

## 11.2 Installing and Running Panel

**What:** Panel is installed via pip and run with the `panel` command-line tool.

**Why:** You need both the library and the server to serve your app.

**How:** `pip install panel`, then `panel serve your_file.py`.

**When:** Before building and every time you want to run your app.

```bash
# Install Panel
pip install panel==1.9.3

# Run a Panel app
panel serve my_app.py

# Run with auto-reload (development)
panel serve my_app.py --autoreload

# Run on a specific port
panel serve my_app.py --port 5006

# Run in a Jupyter notebook
# Just run: pn.extension() in a cell
```

**In Markly (requirements.txt):**
```
panel==1.9.3
```

---

## 11.3 Widgets: Interactive Inputs

**What:** Widgets are UI elements that users interact with — text boxes, buttons, file uploaders, sliders, etc.

**Why:** Every piece of data your app needs from the user comes through a widget.

**How:** Import from `panel.widgets`, create them, and read their `.value` attribute.

**When:** Any time you need user input in your app.

```python
import panel as pn
pn.extension()

# Text input
name_input = pn.widgets.TextInput(
    name="Student Name",
    placeholder="Enter name...",
    value="Alice"
)

# Number input
score_input = pn.widgets.IntSlider(
    name="Score",
    start=0,
    end=100,
    value=85
)

# Dropdown
subject_select = pn.widgets.Select(
    name="Subject",
    options=["Math", "English", "Science", "History", "Programming"],
    value="Math"
)

# File upload
file_upload = pn.widgets.FileInput(
    name="Upload Assignment",
    accept=".pdf,.docx,.png,.jpg,.jpeg"
)

# Button
grade_button = pn.widgets.Button(
    name="Grade Assignment",
    button_type="primary"  # Blue button
)

# Checkbox
show_feedback = pn.widgets.Checkbox(
    name="Show Detailed Feedback",
    value=True
)

# Display all widgets
pn.Column(name_input, score_input, subject_select, file_upload, grade_button, show_feedback)
```

---

## 11.4 Panes: Displaying Output

**What:** Panes are display elements that show content — text, images, Markdown, HTML, plots, etc.

**Why:** After grading, you need to show results to the user. Panes handle all the rendering.

**How:** Create a pane with content, update its `.object` attribute to change what's displayed.

**When:** Any time your app needs to show something to the user.

```python
import panel as pn
pn.extension()

# Markdown pane — great for formatted text
md = pn.pane.Markdown("""
# Grading Results

**Student:** Alice  
**Grade:** A  
**Score:** 95/100
""")

# HTML pane — for custom HTML
html = pn.pane.HTML("<h2 style='color: green;'>Excellent Work!</h2>")

# Image pane — display images
image = pn.pane.PNG("graded_assignment.png")

# DataFrame pane — show tables
import pandas as pd
df = pd.DataFrame({
    "Subject": ["Math", "English"],
    "Grade": ["A", "B+"]
})
table = pn.pane.DataFrame(df)

# JSON pane — show structured data
json_pane = pn.pane.JSON({"grade": "A", "score": 95})

# Str pane — plain text
text = pn.pane.Str("Raw text output here")

# Display everything
pn.Column(md, html, table, json_pane)
```

---

## 11.5 Layouts: Organizing Your UI

**What:** Layouts arrange widgets and panes into rows, columns, tabs, and grids.

**Why:** A good layout makes your app intuitive and professional.

**How:** Use `Row`, `Column`, `Tabs`, `GridSpec`, and `FlexBox`.

**When:** Every app needs layout to organize its components.

```python
import panel as pn
pn.extension()

# Column — stack vertically
col = pn.Column(
    pn.pane.Markdown("# Header"),
    pn.widgets.TextInput(name="Input"),
    pn.widgets.Button(name="Submit")
)

# Row — arrange horizontally
row = pn.Row(
    pn.pane.Markdown("Label:"),
    pn.widgets.TextInput(),
    pn.widgets.Button(name="Go")
)

# Tabs — multiple pages
tabs = pn.Tabs(
    ("Upload", pn.Column(file_upload, grade_button)),
    ("Results", pn.Column(grade_display, feedback_display)),
    ("History", pn.Column(history_table))
)

# GridSpec — precise grid layout
grid = pn.GridSpec(width=800, height=600)
grid[0, 0] = pn.pane.Markdown("# Title")
grid[0, 1] = pn.widgets.Button(name="Settings")
grid[1:3, 0:2] = pn.Column(content_pane)  # Spans 2 rows, 2 columns

# Card — grouped section with header
card = pn.Card(
    pn.widgets.TextInput(name="Student"),
    pn.widgets.Select(name="Subject"),
    title="Assignment Details",
    collapsed=False  # Start expanded
)

# Spacer — add empty space
spaced = pn.Column(
    widget1,
    pn.layout.Spacer(height=20),  # 20 pixels of space
    widget2
)

# Display
pn.Column(col, row, tabs, grid, card)
```

---

## 11.6 Callbacks: Making It Interactive

**What:** Callbacks are Python functions that run when something happens — a button click, text change, etc.

**Why:** Without callbacks, your app is just a static page. Callbacks make it respond to users.

**How:** Use `.param.watch()` for reactive updates or `.on_click()` for button clicks.

**When:** Every interactive element needs a callback.

```python
import panel as pn
pn.extension()

# --- Method 1: Button on_click ---
name_input = pn.widgets.TextInput(name="Student")
greet_button = pn.widgets.Button(name="Greet")
output = pn.pane.Markdown("Waiting...")

def greet(event):
    """Called when button is clicked."""
    output.object = f"Hello, {name_input.value}!"

greet_button.on_click(greet)

# --- Method 2: Reactive watch (runs on ANY change) ---
score_slider = pn.widgets.IntSlider(name="Score", start=0, end=100, value=50)
grade_display = pn.pane.Markdown("Grade: F")

def update_grade(event):
    """Called whenever slider value changes."""
    score = event.new  # The new value
    if score >= 90:
        grade = "A"
    elif score >= 80:
        grade = "B"
    elif score >= 70:
        grade = "C"
    elif score >= 60:
        grade = "D"
    else:
        grade = "F"
    grade_display.object = f"Grade: {grade} ({score}/100)"

# Watch for changes to the 'value' parameter
score_slider.param.watch(update_grade, 'value')

# --- Method 3: Reactive functions with @pn.depends ---
subject = pn.widgets.Select(name="Subject", options=["Math", "English", "Science"])
difficulty = pn.widgets.Select(name="Difficulty", options=["Easy", "Medium", "Hard"])

@pn.depends(subject.param.value, difficulty.param.value)
def generate_prompt(subj, diff):
    """Automatically re-runs when either widget changes."""
    return f"Create a {diff.lower()} {subj.lower()} problem."

prompt_output = pn.pane.Markdown(generate_prompt)

# Layout
pn.Column(
    pn.Row(name_input, greet_button),
    output,
    pn.Row(score_slider, grade_display),
    pn.Row(subject, difficulty),
    prompt_output
)
```

---

## 11.7 File Uploads in Panel

**What:** Panel's `FileInput` widget lets users upload files from their computer.

**Why:** Markly's entire workflow starts with a teacher uploading a student assignment.

**How:** Read `.value` for the bytes, `.filename` for the name.

**When:** Any app that needs user-uploaded files.

```python
import panel as pn
import io
from PIL import Image

pn.extension()

file_input = pn.widgets.FileInput(
    name="Upload Assignment",
    accept=".pdf,.docx,.png,.jpg,.jpeg",  # Allowed file types
    multiple=False  # Only one file at a time
)

file_info = pn.pane.Markdown("No file uploaded yet.")
preview = pn.pane.Empty()

def handle_upload(event):
    """Called when a file is uploaded."""
    if file_input.value is None:
        file_info.object = "No file uploaded."
        return
    
    # File data
    filename = file_input.filename
    file_bytes = file_input.value  # Raw bytes
    file_size = len(file_bytes)
    
    file_info.object = f"""
    **Filename:** {filename}
    **Size:** {file_size:,} bytes
    **Type:** {file_input.mime_type}
    """
    
    # Preview if image
    if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
        image = Image.open(io.BytesIO(file_bytes))
        preview.object = image

# Watch for value changes
file_input.param.watch(handle_upload, 'value')

pn.Column(
    "# Upload Assignment",
    file_input,
    file_info,
    preview
)
```

---

## 11.8 Dynamic Updates and Loading States

**What:** Show loading spinners and update UI dynamically while long operations run.

**Why:** Grading takes time. Users need to know something is happening.

**How:** Use `pn.state.sync_busy` or manual loading indicators with callbacks.

**When:** Any slow operation — AI grading, file processing, PDF generation.

```python
import panel as pn
import asyncio

pn.extension()

status = pn.pane.Markdown("Ready")
progress = pn.indicators.Progress(
    name="Grading Progress",
    value=0,
    max=100,
    bar_color="primary"
)
result = pn.pane.Markdown("")

async def grade_assignment(event):
    """Simulate a slow grading operation."""
    status.object = "⏳ Grading in progress..."
    progress.value = 0
    
    # Simulate steps
    for i in range(10):
        await asyncio.sleep(0.3)  # Non-blocking sleep
        progress.value = (i + 1) * 10
    
    status.object = "✅ Grading complete!"
    result.object = """
    # Results
    
    **Grade:** A
    **Score:** 95/100
    **Feedback:** Excellent work! Clear reasoning and correct answers.
    """

grade_button = pn.widgets.Button(name="Grade Now", button_type="primary")
grade_button.on_click(lambda e: asyncio.create_task(grade_assignment(e)))

# Alternative: Disable button during processing
async def safe_grade(event):
    grade_button.disabled = True
    grade_button.name = "Grading..."
    
    try:
        await grade_assignment(event)
    finally:
        grade_button.disabled = False
        grade_button.name = "Grade Now"

grade_button.on_click(lambda e: asyncio.create_task(safe_grade(e)))

pn.Column(
    grade_button,
    status,
    progress,
    result
)
```

---

## 11.9 Downloading Files from Panel

**What:** Let users download generated files (like PDF reports) from your app.

**Why:** After grading, teachers need to download the annotated PDF.

**How:** Use `pn.widgets.FileDownload` or serve bytes directly.

**When:** Any app that generates files for user download.

```python
import panel as pn
import io
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph
from reportlab.lib.styles import getSampleStyleSheet

pn.extension()

def generate_pdf(student, grade, feedback):
    """Generate a PDF in memory."""
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4)
    styles = getSampleStyleSheet()
    
    story = [
        Paragraph(f"<b>Student:</b> {student}", styles["Normal"]),
        Paragraph(f"<b>Grade:</b> {grade}", styles["Normal"]),
        Paragraph(f"<b>Feedback:</b> {feedback}", styles["Normal"]),
    ]
    
    doc.build(story)
    buffer.seek(0)
    return buffer.getvalue()

# Method 1: FileDownload widget (pre-generated)
pdf_bytes = generate_pdf("Alice", "A", "Great work!")
file_download = pn.widgets.FileDownload(
    file=io.BytesIO(pdf_bytes),
    filename="alice_grade_report.pdf",
    button_type="success",
    label="Download PDF Report"
)

# Method 2: Dynamic download (generated on click)
student_name = pn.widgets.TextInput(name="Student", value="Bob")
grade_select = pn.widgets.Select(name="Grade", options=["A", "B", "C", "D", "F"])
download_btn = pn.widgets.Button(name="Generate & Download", button_type="primary")
download_output = pn.pane.Empty()

async def create_download(event):
    """Generate PDF dynamically when button is clicked."""
    download_btn.name = "Generating..."
    
    pdf_data = generate_pdf(
        student_name.value,
        grade_select.value,
        "Feedback generated by AI..."
    )
    
    # Create a new download widget with the generated file
    download = pn.widgets.FileDownload(
        file=io.BytesIO(pdf_data),
        filename=f"{student_name.value}_report.pdf",
        button_type="success"
    )
    
    download_output.object = download
    download_btn.name = "Generate & Download"

download_btn.on_click(lambda e: asyncio.create_task(create_download(e)))

pn.Column(
    pn.Row(student_name, grade_select),
    download_btn,
    download_output,
    pn.pane.Markdown("---"),
    file_download  # Pre-generated example
)
```

---

## 11.10 Templates: Professional App Layouts

**What:** Panel provides pre-built templates that give your app a professional look — headers, sidebars, navigation.

**Why:** A polished UI makes your tool feel professional and trustworthy.

**How:** Wrap your content in templates like `BootstrapTemplate`, `MaterialTemplate`, or `FastListTemplate`.

**When:** Any production app should use a template.

```python
import panel as pn

pn.extension()

# Create some content
sidebar = pn.Column(
    pn.pane.Markdown("## Markly"),
    pn.widgets.Select(name="Subject", options=["Math", "English", "Science"]),
    pn.widgets.Button(name="Settings", button_type="light")
)

main_content = pn.Column(
    pn.pane.Markdown("# Grade Assignments"),
    pn.Row(
        pn.widgets.FileInput(name="Upload"),
        pn.widgets.Button(name="Grade All", button_type="primary")
    ),
    pn.pane.Markdown("## Recent Grades"),
    pn.pane.DataFrame({
        "Student": ["Alice", "Bob", "Charlie"],
        "Grade": ["A", "B+", "A-"],
        "Subject": ["Math", "English", "Science"]
    })
)

# Apply a template
template = pn.template.BootstrapTemplate(
    title="Markly - AI Grading Assistant",
    sidebar=sidebar,
    main=main_content,
    header_background="#2c3e50"  # Dark blue header
)

template.servable()
```

**Available Templates:**
- `BootstrapTemplate` — Clean, responsive, familiar
- `MaterialTemplate` — Modern Material Design look
- `FastListTemplate` — Sidebar with list navigation
- `GoldenTemplate` — Resizable panes (like IDE)
- `VanillaTemplate` — Minimal, no framework

---

## 11.11 Connecting Panel to Async Functions

**What:** Panel works great with async Python. Long operations don't freeze the UI.

**Why:** AI grading, file processing, and PDF generation are all slow. Async keeps the interface responsive.

**How:** Use `asyncio.create_task()` inside callbacks, or use `pn.state.execute()` for thread-based execution.

**When:** Any callback that does I/O or CPU-intensive work.

```python
import panel as pn
import asyncio

pn.extension()

# UI elements
upload = pn.widgets.FileInput(accept=".pdf,.docx")
grade_btn = pn.widgets.Button(name="Grade", button_type="primary")
status = pn.pane.Markdown("Ready")
result_card = pn.Card(title="Results", collapsed=True)

async def async_grade(file_bytes, filename):
    """Simulate async grading pipeline."""
    # Step 1: Extract text
    status.object = "📄 Extracting text..."
    await asyncio.sleep(1)
    
    # Step 2: Detect subject
    status.object = "🔍 Detecting subject..."
    await asyncio.sleep(0.5)
    
    # Step 3: Call AI
    status.object = "🤖 Grading with AI..."
    await asyncio.sleep(2)
    
    # Step 4: Generate PDF
    status.object = "📑 Generating report..."
    await asyncio.sleep(1)
    
    return {
        "grade": "A",
        "score": 95,
        "feedback": "Excellent understanding of the material!"
    }

def on_grade(event):
    """Button callback — starts async grading."""
    if upload.value is None:
        status.object = "❌ Please upload a file first!"
        return
    
    # Fire off async grading without blocking
    asyncio.create_task(run_grading())

async def run_grading():
    """Run the full grading pipeline."""
    grade_btn.disabled = True
    grade_btn.name = "Grading..."
    
    try:
        result = await async_grade(upload.value, upload.filename)
        
        # Update UI with results
        result_card.object = pn.Column(
            pn.pane.Markdown(f"**Grade:** {result['grade']}"),
            pn.pane.Markdown(f"**Score:** {result['score']}/100"),
            pn.pane.Markdown(f"**Feedback:** {result['feedback']}")
        )
        result_card.collapsed = False
        status.object = "✅ Done!"
        
    except Exception as e:
        status.object = f"❌ Error: {str(e)}"
    
    finally:
        grade_btn.disabled = False
        grade_btn.name = "Grade"

grade_btn.on_click(on_grade)

pn.Column(
    pn.pane.Markdown("# Markly Grading"),
    upload,
    grade_btn,
    status,
    result_card
).servable()
```

---

## 11.12 Complete Markly UI Example

**What:** Putting it all together — a realistic Markly interface.

**Why:** See how every Panel concept connects in the real app.

```python
import panel as pn
import asyncio
import io
import os
from dotenv import load_dotenv

load_dotenv()
pn.extension()

# ============================================================
# MARKLY MAIN APPLICATION
# ============================================================

class MarklyApp:
    def __init__(self):
        self._build_ui()
    
    def _build_ui(self):
        """Construct the entire UI."""
        
        # --- Sidebar ---
        self.subject_select = pn.widgets.Select(
            name="Subject",
            options=["Auto-detect", "Math", "English", "Science", "History", "Programming"],
            value="Auto-detect"
        )
        
        self.grade_level = pn.widgets.Select(
            name="Grade Level",
            options=["Middle School", "High School", "College"],
            value="High School"
        )
        
        self.sidebar = pn.Column(
            pn.pane.Markdown("## ⚙️ Settings"),
            self.subject_select,
            self.grade_level,
            pn.layout.Divider(),
            pn.pane.Markdown("## 📊 Stats"),
            pn.pane.Markdown("Assignments graded: **0**"),
            pn.pane.Markdown("Avg. grade time: **--**")
        )
        
        # --- Main Content ---
        self.upload = pn.widgets.FileInput(
            name="Upload Assignment",
            accept=".pdf,.docx,.png,.jpg,.jpeg",
            multiple=True
        )
        
        self.grade_btn = pn.widgets.Button(
            name="📝 Grade Assignment",
            button_type="primary",
            width=200
        )
        
        self.clear_btn = pn.widgets.Button(
            name="Clear",
            button_type="light",
            width=100
        )
        
        self.status = pn.pane.Alert(
            "Ready to grade. Upload a student assignment to begin.",
            alert_type="info"
        )
        
        self.progress = pn.indicators.Progress(
            name="Progress",
            value=0,
            max=100,
            bar_color="primary",
            visible=False
        )
        
        self.results_area = pn.Column()
        
        # --- Bind callbacks ---
        self.grade_btn.on_click(self._on_grade)
        self.clear_btn.on_click(self._on_clear)
        
        # --- Layout ---
        self.main = pn.Column(
            pn.pane.Markdown("# 🎓 Markly - AI Grading Assistant"),
            pn.Card(
                pn.Row(self.upload, self.grade_btn, self.clear_btn),
                title="Upload Assignment",
                collapsed=False
            ),
            self.status,
            self.progress,
            pn.Card(
                self.results_area,
                title="Grading Results",
                collapsed=False
            )
        )
        
        # --- Template ---
        self.template = pn.template.BootstrapTemplate(
            title="Markly",
            sidebar=self.sidebar,
            main=self.main,
            header_background="#1a5276"
        )
    
    async def _grade_single(self, filename, file_bytes, index, total):
        """Grade a single assignment."""
        # Simulate the pipeline
        await asyncio.sleep(0.5)  # Extract
        await asyncio.sleep(1.0)    # AI call
        await asyncio.sleep(0.5)  # PDF generation
        
        return {
            "filename": filename,
            "student": filename.split('.')[0],
            "grade": "A" if index % 3 == 0 else "B+",
            "score": 95 - (index * 5),
            "feedback": f"Good work on {filename}!",
            "pdf_ready": True
    }
    
    def _on_grade(self, event):
        """Start grading when button clicked."""
        if not self.upload.value:
            self.status.object = "❌ Please upload at least one file!"
            self.status.alert_type = "danger"
            return
        
        asyncio.create_task(self._run_grading())
    
    async def _run_grading(self):
        """Run the full grading pipeline."""
        self.grade_btn.disabled = True
        self.grade_btn.name = "Grading..."
        self.progress.visible = True
        self.status.object = "⏳ Starting grading pipeline..."
        self.status.alert_type = "warning"
        
        try:
            # Handle multiple files
            files = self.upload.value
            filenames = self.upload.filename
            
            # Normalize to lists
            if not isinstance(files, list):
                files = [files]
                filenames = [filenames]
            
            results = []
            for i, (fname, fbytes) in enumerate(zip(filenames, files)):
                self.status.object = f"📄 Grading {fname}... ({i+1}/{len(files)})"
                self.progress.value = int((i / len(files)) * 100)
                
                result = await self._grade_single(fname, fbytes, i, len(files))
                results.append(result)
                
                # Add result card immediately
                self._add_result_card(result)
            
            self.progress.value = 100
            self.status.object = f"✅ Graded {len(results)} assignment(s)!"
            self.status.alert_type = "success"
            
        except Exception as e:
            self.status.object = f"❌ Error: {str(e)}"
            self.status.alert_type = "danger"
        
        finally:
            self.grade_btn.disabled = False
            self.grade_btn.name = "📝 Grade Assignment"
            self.progress.visible = False
    
    def _add_result_card(self, result):
        """Add a result card to the results area."""
        download_btn = pn.widgets.Button(
            name="📥 Download PDF",
            button_type="success",
            width=150
        )
        
        card = pn.Card(
            pn.Column(
                pn.pane.Markdown(f"**Student:** {result['student']}"),
                pn.pane.Markdown(f"**Grade:** {result['grade']} ({result['score']}/100)"),
                pn.pane.Markdown(f"**Feedback:** {result['feedback']}"),
                download_btn
            ),
            title=f"📄 {result['filename']}",
            collapsed=False,
            margin=(10, 0)
        )
        
        self.results_area.append(card)
    
    def _on_clear(self, event):
        """Clear all results."""
        self.results_area.clear()
        self.upload.value = None
        self.status.object = "Ready to grade. Upload a student assignment to begin."
        self.status.alert_type = "info"
    
    def servable(self):
        """Return the app for panel serve."""
        return self.template

# Create and serve
app = MarklyApp()
app.servable()
```

---

## 11.13 Key Takeaways

| Concept | What it does | Markly use case |
|---------|-------------|-----------------|
| **Widgets** | User input elements | File upload, subject selection, buttons |
| **Panes** | Display elements | Show grades, feedback, images, tables |
| **Layouts** | Arrange UI components | Organize upload area, results, sidebar |
| **Callbacks** | Respond to user actions | Start grading when button clicked |
| **Templates** | Professional app frames | Give Markly a polished look |
| **Async callbacks** | Non-blocking interactions | Grade without freezing the UI |
| **File upload** | Receive user files | Get student assignments |
| **File download** | Send files to users | Deliver graded PDF reports |
| **Progress indicators** | Show operation status | Let teachers know grading is happening |
| **Alert panes** | Status messages | Success/error notifications |

---

**🎓 Panel transforms Markly from a command-line script into a professional web application.** Teachers don't need to know Python — they just open a browser, upload files, and get results. The combination of Panel's reactive widgets, async support, and professional templates makes it the perfect choice for building AI-powered tools like Markly.

---

# PART 12: THE MARKLY LIBRARY ECOSYSTEM

## 12.1 The Full Stack at a Glance

**What:** Markly is built on a carefully chosen stack of Python libraries. Each one solves a specific problem — from reading PDFs to drawing teacher annotations to serving the web interface.

**Why:** No single library can do everything. Understanding what each one does helps you debug, extend, and appreciate how the pieces fit together.

**How:** Install everything with `pip install -r requirements.txt`, then import what you need.

**When:** Every time you work on any part of Markly.

```
┌─────────────────────────────────────────────────────────────┐
│                     MARKLY ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────┤
│  UI Layer        │  panel, param, bokeh, holoviews           │
│  AI Layer        │  openai, httpx, aiohttp                   │
│  Document Layer  │  PyMuPDF (fitz), python-docx, pytesseract │
│  Image Layer     │  pillow (PIL), reportlab                  │
│  Data Layer      │  json, os, io, re, base64                 │
│  Config Layer    │  python-dotenv                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 12.2 Panel, Param, Bokeh, and HoloViews

**What:** These four libraries work together to create Markly's web interface.

| Library | Role | Why Markly Needs It |
|---------|------|---------------------|
| **Panel** | High-level app framework | Build the entire UI with Python |
| **Param** | Declarative parameters | Define reactive widget properties |
| **Bokeh** | Interactive plotting engine | Render plots and visualizations in the browser |
| **HoloViews** | High-level data visualization | Create charts from data easily |

**How they connect:**
- **Panel** sits on top of **Bokeh** for rendering
- **Panel** uses **Param** for reactive parameter handling
- **HoloViews** provides plotting capabilities that Panel can embed

```python
# You mostly just import Panel — the others come along
import panel as pn

# But Bokeh is there under the hood for plots
from bokeh.plotting import figure

# And HoloViews for data viz
import holoviews as hv

# Param is used when you build custom components
import param

class GradingParams(param.Parameterized):
    subject = param.Selector(default="Math", objects=["Math", "English", "Science"])
    strictness = param.Number(default=0.5, bounds=(0, 1))
```

**In Markly:**
```python
# app.py — the entire UI is built with Panel
import panel as pn

pn.extension()  # Loads Bokeh JS, sets up Param

# File upload widget
upload = pn.widgets.FileInput(accept=".pdf,.docx,.png,.jpg")

# Results displayed in a Panel layout
results = pn.Column(pn.pane.Markdown("## Grading Results"))
```

**Install:** `pip install panel==1.9.3` (pulls in Bokeh, Param, and HoloViews automatically)

---

## 12.3 OpenAI and HTTP Clients

**What:** `openai` is the official SDK for calling OpenAI's APIs. `httpx` and `aiohttp` are modern HTTP clients for calling other AI providers.

| Library | Role | Why Markly Needs It |
|---------|------|---------------------|
| **openai** | Official OpenAI SDK | Call GPT-4o, GPT-4o-mini for grading |
| **httpx** | Modern HTTP client | Call alternative AI providers (OpenRouter, etc.) |
| **aiohttp** | Async HTTP client | Concurrent API calls without blocking |

**How they connect:**
- `openai` uses `httpx` under the hood for its HTTP requests
- `httpx` supports both sync and async (critical for Markly's concurrency)
- `aiohttp` is a pure-async alternative for maximum performance

```python
# Sync client (simple, but blocks)
import openai
client = openai.OpenAI(api_key="...")

# Async client (non-blocking, for Panel apps)
async_client = openai.AsyncOpenAI(api_key="...")

# Raw httpx for custom endpoints
import httpx
response = httpx.post("https://openrouter.ai/api/v1/chat/completions", json={...})

# Async httpx for non-blocking calls
async with httpx.AsyncClient() as client:
    response = await client.post("...", json={...})
```

**In Markly:**
```python
# engine.py — AI pipeline uses async OpenAI client
import openai
import httpx

class AIGrader:
    def __init__(self):
        self.client = openai.AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        self.fallback = httpx.AsyncClient(
            base_url="https://openrouter.ai/api/v1",
            headers={"Authorization": f"Bearer {os.getenv('OPENROUTER_API_KEY')}"}
        )
    
    async def grade(self, prompt):
        # Try OpenAI first
        try:
            return await self._call_openai(prompt)
        except Exception:
            # Fallback to OpenRouter via httpx
            return await self._call_openrouter(prompt)
```

**Install:** `pip install openai==2.43.0 httpx aiohttp`

---

## 12.4 PyMuPDF (fitz)

**What:** PyMuPDF is a fast, lightweight library for reading, writing, and manipulating PDF files. It's imported as `fitz` for historical reasons.

**Why Markly needs it:** Students submit PDFs. PyMuPDF extracts text page-by-page without needing Adobe Acrobat or any external dependencies.

**Key capabilities:**
- Extract text from any PDF page
- Convert PDF pages to images (for OCR fallback)
- Read metadata (title, author, creation date)
- Handle encrypted PDFs

```python
import fitz  # PyMuPDF

# Open from file path
doc = fitz.open("essay.pdf")

# Or from bytes (for uploaded files)
doc = fitz.open(stream=file_bytes, filetype="pdf")

# Iterate pages
for page_num, page in enumerate(doc):
    text = page.get_text()
    print(f"Page {page_num + 1}: {text[:200]}...")

# Convert page to image
pix = page.get_pixmap(dpi=200)
pix.save("page.png")

# Get metadata
print(doc.metadata)  # {'title': '...', 'author': '...', ...}

# Close when done
doc.close()
```

**In Markly:**
```python
# utils.py — PDF text extraction
def extract_pdf(file_bytes):
    """Extracts text page by page from a PDF."""
    document = fitz.open(stream=file_bytes, filetype="pdf")
    return "\n".join([page.get_text() for page in document])
```

**Install:** `pip install PyMuPDF==1.27.2.3`

**⚠️ Note:** The import name is `fitz`, but the package name is `PyMuPDF`. This is confusing but historical.

---

## 12.5 python-docx

**What:** `python-docx` reads and writes Microsoft Word `.docx` files — the modern Word format (not the old `.doc`).

**Why Markly needs it:** Many students submit assignments as Word documents. This library extracts the text without needing Microsoft Word installed.

**Key capabilities:**
- Read paragraphs and their formatting
- Extract text from tables
- Read document properties (title, author)
- Create new Word documents (not used in Markly, but possible)

```python
from docx import Document

# Open a document
doc = Document("essay.docx")

# Read all paragraphs
full_text = []
for paragraph in doc.paragraphs:
    if paragraph.text.strip():  # Skip empty paragraphs
        full_text.append(paragraph.text)

print("\n".join(full_text))

# Read tables
for table in doc.tables:
    for row in table.rows:
        cells = [cell.text for cell in row.cells]
        print(" | ".join(cells))

# From bytes (uploaded files)
import io
doc = Document(io.BytesIO(file_bytes))
```

**In Markly:**
```python
# utils.py — DOCX text extraction
def extract_docx(file_bytes):
    """Extracts paragraphs from a DOCX file."""
    document = Document(io.BytesIO(file_bytes))
    return "\n".join([paragraph.text for paragraph in document.paragraphs])
```

**Install:** `pip install python-docx==1.2.0`

---

## 12.6 Pytesseract and Pillow (PIL)

**What:** `pytesseract` is a Python wrapper for Google's Tesseract OCR engine. `Pillow` (imported as `PIL`) is Python's imaging library.

**Why Markly needs them:** Students often submit photos of handwritten work. OCR converts images to text so the AI can grade them. Pillow handles all image operations.

| Library | Role | Key Functions |
|---------|------|-------------|
| **Pillow (PIL)** | Image processing | Open, edit, draw, save images |
| **pytesseract** | OCR text extraction | Convert images to text |

```python
from PIL import Image, ImageDraw, ImageFont
import pytesseract
import io

# === PILLOW: Image Processing ===

# Open an image
img = Image.open("homework.jpg")

# Resize
img = img.resize((800, 600))

# Convert to grayscale for better OCR
gray = img.convert("L")

# Draw on image
draw = ImageDraw.Draw(img)
draw.rectangle([50, 50, 200, 100], outline="red", width=3)
draw.text((60, 60), "Grade: A", fill="red")

# Save
img.save("annotated.jpg")

# === PYTESSERACT: OCR ===

# Basic OCR
text = pytesseract.image_to_string(gray)
print(text)

# OCR with configuration
text = pytesseract.image_to_string(
    gray,
    config='--psm 6'  # Page segmentation mode: assume single block of text
)

# Get bounding boxes for each word
data = pytesseract.image_to_data(gray, output_type=pytesseract.Output.DICT)
for i, word in enumerate(data['text']):
    if word.strip():
        print(f"Word: {word} at ({data['left'][i]}, {data['top'][i]})")

# From bytes
img = Image.open(io.BytesIO(file_bytes))
text = pytesseract.image_to_string(img)
```

**In Markly:**
```python
# utils.py — Image OCR
def extract_image(file_bytes):
    """Extracts text from images via Tesseract OCR."""
    image = Image.open(io.BytesIO(file_bytes))
    return pytesseract.image_to_string(image)

# markup.py — Drawing teacher annotations
def _jittered_line(draw, x0, y0, x1, y1, fill, width=2, segments=6):
    pts = []
    for i in range(segments + 1):
        t = i / segments
        px = x0 + (x1 - x0) * t + _jitter(0, 1.5)
        py = y0 + (y1 - y0) * t + _jitter(0, 1.5)
        pts.append((px, py))
    for i in range(len(pts) - 1):
        draw.line([pts[i], pts[i + 1]], fill=fill, width=width)
```

**Install:** `pip install pytesseract==0.3.13 pillow==12.2.0`

**⚠️ Note:** Pytesseract requires the Tesseract OCR engine installed on your system:
- **Windows:** Download installer from GitHub
- **Mac:** `brew install tesseract`
- **Linux:** `sudo apt-get install tesseract-ocr`

---

## 12.7 ReportLab

**What:** ReportLab is Python's premier PDF generation library. It creates professional PDFs programmatically.

**Why Markly needs it:** After grading, Markly generates a two-page PDF report — the annotated assignment image plus structured feedback.

**Key capabilities:**
- Create multi-page PDFs
- Draw text with styles and fonts
- Create tables with borders and colors
- Embed images
- Use precise measurements (points, mm, inches)

```python
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Table, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm
import io

# Create PDF in memory
buffer = io.BytesIO()
doc = SimpleDocTemplate(buffer, pagesize=A4)

# Styles
styles = getSampleStyleSheet()

# Content
story = [
    Paragraph("<b>Student Report</b>", styles["Title"]),
    Spacer(1, 12),
    Paragraph("Grade: <b>A</b>", styles["Normal"]),
    Spacer(1, 12),
    Table([
        ["Subject", "Score", "Grade"],
        ["Math", "95", "A"],
        ["English", "88", "B+"]
    ], colWidths=[50*mm, 30*mm, 30*mm])
]

# Build PDF
doc.build(story)

# Get bytes for download
buffer.seek(0)
pdf_bytes = buffer.getvalue()
```

**In Markly:**
```python
# report.py — PDF report generation
def create_marked_pdf(student, subject, filename, marked_image_buffer,
                      overall_feedback="", grade="", report_text="", corrections=None):
    """Creates a two-page PDF with annotated image and feedback report."""
    buffer = io.BytesIO()
    PAGE_W, PAGE_H = A4
    
    # Page 1: Annotated image
    # Page 2: Text report
    
    return buffer
```

**Install:** `pip install reportlab==5.0.0`

---

## 12.8 python-dotenv

**What:** `python-dotenv` reads key-value pairs from a `.env` file and loads them as environment variables.

**Why Markly needs it:** API keys, database URLs, and other secrets should never be hardcoded. `.env` keeps them out of your code and Git history.

**How:** Create a `.env` file, call `load_dotenv()`, then use `os.getenv()`.

```python
# .env file (NEVER commit this to Git!)
OPENAI_API_KEY=sk-your-secret-key-here
OPENROUTER_API_KEY=sk-or-your-key-here
DB_FILE=students.json
DEBUG=True

# Python code
from dotenv import load_dotenv
import os

load_dotenv()  # Loads variables from .env into environment

api_key = os.getenv("OPENAI_API_KEY")
db_file = os.getenv("DB_FILE", "students.json")  # Default fallback
debug = os.getenv("DEBUG", "False").lower() == "true"

print(f"Using database: {db_file}")
print(f"Debug mode: {debug}")
```

**In Markly:**
```python
# At the top of app.py or main entry point
from dotenv import load_dotenv
load_dotenv()

# Now all modules can use os.getenv()
import os
OPENAI_KEY = os.getenv("OPENAI_API_KEY")
```

**Install:** `pip install python-dotenv==1.2.2`

**⚠️ Critical:** Add `.env` to your `.gitignore` file immediately:
```gitignore
# .gitignore
.env
__pycache__/
*.pyc
students.json
```

---

## 12.9 Python Standard Library Modules

**What:** Python comes with a rich standard library — no installation needed. Markly relies heavily on these built-in modules.

| Module | What It Does | Markly Use |
|--------|-------------|------------|
| **`os`** | Operating system interface | Check if files exist (`os.path.exists`) |
| **`json`** | JSON encoding/decoding | Save/load student database |
| **`io`** | In-memory file objects | Process uploaded files without disk I/O |
| **`re`** | Regular expressions | Extract grades from AI text |
| **`base64`** | Binary-to-text encoding | Send images to AI APIs |
| **`asyncio`** | Async programming | Concurrent grading, responsive UI |
| **`random`** | Random numbers | Jitter for handwriting simulation |
| **`math`** | Mathematical functions | Sine waves for wavy underlines |
| **`textwrap`** | Text wrapping | Wrap margin notes in annotations |

```python
import os
import json
import io
import re
import base64
import asyncio
import random
import math
import textwrap

# All of these are built into Python — no pip install needed!
```

---

## 12.10 The Complete requirements.txt

**What:** This is the single file that defines every dependency for Markly.

**Why:** One command — `pip install -r requirements.txt` — sets up the entire environment.

```txt
# Markly Requirements
# Install with: pip install -r requirements.txt

# === UI Layer ===
panel==1.9.3           # Web interface framework
# (includes: bokeh, param, holoviews, pyviz-comms)

# === AI Layer ===
openai==2.43.0         # OpenAI API client
httpx>=0.27.0          # Modern HTTP client
aiohttp>=3.9.0         # Async HTTP client

# === Document Processing ===
PyMuPDF==1.27.2.3      # PDF text extraction (imported as fitz)
python-docx==1.2.0     # Word document reading
pytesseract==0.3.13    # OCR for images
pillow==12.2.0         # Image processing (PIL)

# === PDF Generation ===
reportlab==5.0.0       # PDF report creation

# === Configuration ===
python-dotenv==1.2.2   # Environment variable management

# === Optional but Recommended ===
tiktoken>=0.7.0        # Token counting for cost tracking
pydantic>=2.0.0        # Data validation and structured output
```

---

## 12.11 Library Cheat Sheet

| If you need to... | Use this library | Import as |
|--------------------|----------------|-----------|
| Build a web UI | Panel | `import panel as pn` |
| Call OpenAI's API | openai | `import openai` |
| Make HTTP requests | httpx | `import httpx` |
| Read PDF text | PyMuPDF | `import fitz` |
| Read Word docs | python-docx | `from docx import Document` |
| OCR images | pytesseract | `import pytesseract` |
| Process images | Pillow | `from PIL import Image` |
| Generate PDFs | ReportLab | `from reportlab.platypus import ...` |
| Load secrets | python-dotenv | `from dotenv import load_dotenv` |
| Save data as JSON | json (built-in) | `import json` |
| In-memory files | io (built-in) | `import io` |
| Pattern matching | re (built-in) | `import re` |
| Async programming | asyncio (built-in) | `import asyncio` |

---

## 12.12 Key Takeaways

1. **Each library has one job.** PyMuPDF reads PDFs. Pillow draws images. Panel builds UIs. Don't try to make one library do everything.

2. **Version pinning matters.** `==1.9.3` ensures everyone uses the exact same version. Without pinning, a library update could break Markly.

3. **The standard library is powerful.** `os`, `json`, `io`, `re` — you already have everything you need for file handling, data persistence, and text processing.

4. **Async libraries enable concurrency.** `openai.AsyncOpenAI`, `httpx.AsyncClient`, and `asyncio` let Markly grade multiple assignments simultaneously without freezing the UI.

5. **Environment variables keep secrets safe.** Never hardcode API keys. Use `python-dotenv` and `.env` files.

6. **Dependencies have dependencies.** Installing `panel` automatically brings in `bokeh`, `param`, and `holoviews`. This is why virtual environments are essential.

---

**🎓 Understanding the library ecosystem is as important as knowing Python itself.** When you know which tool to reach for — and why — you can build complex applications like Markly by combining the right libraries in the right way.

---
Here is **Part 13: APIs, the Request/Response Cycle, and How Markly Uses Them**.

---

# PART 13: APIs, THE REQUEST/RESPONSE CYCLE, AND MARKLY

## 13.1 What Is an API?

**What:** An API (Application Programming Interface) is a set of rules that lets one piece of software talk to another. When Markly grades an assignment, it doesn't do the thinking itself — it sends the student's work to an AI model (like GPT-4o) via an API and receives the graded feedback back.

**Why:** APIs let you leverage powerful external services without building them yourself. Markly doesn't contain a neural network; it *calls* one.

**How:** You construct a **request** (a structured message with data), send it over the internet to an API endpoint, and receive a **response** (the result).

**When:** Every time Markly grades an assignment, it makes one or more API calls.

---

## 13.2 The Request/Response Cycle

Every API interaction follows the same cycle. Understanding this cycle is essential for debugging why a grading call failed, why it was slow, or why the AI returned nonsense.

```
┌─────────────┐         HTTP Request          ┌─────────────┐
│   MARKLY    │  ───────────────────────────► │  AI SERVER  │
│  (Client)   │                               │  (Server)   │
│             │  ◄─────────────────────────── │             │
└─────────────┘         HTTP Response           └─────────────┘
```

### Stage 1: The Client Prepares a Request

Markly (the client) builds an HTTP request containing:
- **Method**: Usually `POST` for sending data to be processed
- **URL/Endpoint**: The API address (e.g., `https://api.openai.com/v1/chat/completions`)
- **Headers**: Metadata including authentication (`Authorization: Bearer sk-...`) and content type (`Content-Type: application/json`)
- **Body/Payload**: The actual data — the student's text, the grading rubric, the system prompt

```python
# What a raw API request looks like conceptually
import json

request_body = {
    "model": "gpt-4o",
    "messages": [
        {"role": "system", "content": "You are a strict math teacher."},
        {"role": "user", "content": "Grade this algebra homework: 2x + 5 = 15..."}
    ],
    "temperature": 0.3
}

headers = {
    "Authorization": "Bearer sk-your-key-here",
    "Content-Type": "application/json"
}
```

### Stage 2: The Request Travels Over the Network

The request is serialized to JSON, split into packets, and sent over the internet via HTTP/HTTPS. This takes time — anywhere from 50ms to 500ms depending on server location and network conditions.

### Stage 3: The Server Processes the Request

The AI provider's server:
1. Authenticates the API key
2. Parses the JSON payload
3. Routes to the correct model
4. Runs the neural network inference (this is the slow part — 1–10 seconds)
5. Formats the result

### Stage 4: The Server Sends a Response

The server returns an HTTP response containing:
- **Status Code**: `200 OK` (success), `401 Unauthorized` (bad key), `429 Too Many Requests` (rate limit), `500 Internal Server Error` (server problem)
- **Headers**: Metadata like rate limit remaining, content type
- **Body**: The actual result — a JSON object with the AI's generated text

```python
# A typical successful response body
response_body = {
    "id": "chatcmpl-abc123",
    "model": "gpt-4o",
    "choices": [{
        "message": {
            "role": "assistant",
            "content": "Grade: B+\n\nFeedback: Good work on solving for x..."
        }
    }],
    "usage": {
        "prompt_tokens": 250,
        "completion_tokens": 180,
        "total_tokens": 430
    }
}
```

### Stage 5: The Client Processes the Response

Markly receives the response, checks the status code, parses the JSON, extracts the AI's text, and passes it to the next stage — extracting the grade, generating the PDF report, or drawing annotations.

---

## 13.3 HTTP Methods in Practice

| Method | What It Does | Markly Use Case |
|--------|-------------|-----------------|
| **GET** | Read data from server | Fetch student history from a local endpoint (rare) |
| **POST** | Send data to be processed | **Send assignment text to AI for grading** |
| **PUT** | Update existing resource | Update a stored rubric (if built) |
| **DELETE** | Remove a resource | Delete a student record (if built) |

In Markly, **POST** is the workhorse. Every grading call is a POST request because Markly is *sending* data (the assignment) and *creating* a result (the grade). 

---

## 13.4 Status Codes: The API's Way of Talking Back

Status codes are three-digit numbers that tell you what happened. Markly's `engine.py` must handle these correctly.

| Code | Meaning | What Markly Should Do |
|------|---------|----------------------|
| `200 OK` | Success | Parse the response and continue |
| `400 Bad Request` | Your request was malformed | Log error, check prompt formatting |
| `401 Unauthorized` | Invalid API key | Alert user to check `.env` file |
| `429 Too Many Requests` | Rate limit hit | Wait and retry, or switch to fallback model |
| `500/502/503` | Server error | Retry with exponential backoff, or use fallback |

```python
# Robust status code handling in Markly's engine
import httpx

async def call_ai_api(prompt):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api.openai.com/v1/chat/completions",
            headers={"Authorization": f"Bearer {api_key}"},
            json={"model": "gpt-4o", "messages": prompt},
            timeout=30.0
        )
        
        if response.status_code == 200:
            return response.json()["choices"][0]["message"]["content"]
        elif response.status_code == 429:
            # Rate limited — switch to fallback provider
            return await call_fallback_provider(prompt)
        elif response.status_code >= 500:
            # Server error — retry once
            await asyncio.sleep(2)
            return await call_ai_api(prompt)  # One retry
        else:
            raise Exception(f"API Error {response.status_code}: {response.text}")
```

---

## 13.5 Synchronous vs. Asynchronous API Calls

**Synchronous** (`requests`, `openai.OpenAI`):
- Blocks execution until the response comes back
- Simple to write, but the UI freezes while waiting
- Bad for Markly because grading takes 5–15 seconds

**Asynchronous** (`httpx.AsyncClient`, `openai.AsyncOpenAI`, `aiohttp`):
- Sends the request and *immediately* moves on
- Other tasks (UI updates, file processing) continue running
- When the response arrives, a callback processes it
- Essential for Panel apps so the interface stays responsive

```python
# === SYNC: Blocks everything ===
import openai
client = openai.OpenAI(api_key="...")  # Sync client

def grade_sync(text):
    response = client.chat.completions.create(  # STOPS HERE until done
        model="gpt-4o",
        messages=[{"role": "user", "content": text}]
    )
    return response.choices[0].message.content  # UI frozen the whole time

# === ASYNC: Non-blocking ===
import openai
client = openai.AsyncOpenAI(api_key="...")  # Async client

async def grade_async(text):
    response = await client.chat.completions.create(  # YIELDS control
        model="gpt-4o",
        messages=[{"role": "user", "content": text}]
    )
    return response.choices[0].message.content  # UI stays responsive
```

**In Markly:** `engine.py` uses `AsyncOpenAI` and `httpx.AsyncClient` so Panel's widgets don't freeze when a student clicks "Grade." 

---

## 13.6 Authentication: Proving Who You Are

APIs require authentication to prevent abuse and track usage. Markly uses **Bearer Token** authentication.

```
Authorization: Bearer sk-your-secret-key-here
```

**The `.env` file stores the key:**
```bash
# .env — NEVER commit this to Git!
OPENAI_API_KEY=sk-your-openai-key
OPENROUTER_API_KEY=sk-or-your-key
```

**Loading it in Python:**
```python
from dotenv import load_dotenv
import os

load_dotenv()  # Loads .env into environment variables

api_key = os.getenv("OPENAI_API_KEY")
# Now api_key = "sk-your-openai-key"
```

**Why this matters:** Hardcoding keys in source code is a security risk. If you push to GitHub, bots scrape repositories for API keys within minutes. `python-dotenv` keeps secrets out of your code. 

---

## 13.7 JSON: The Language of APIs

APIs speak JSON (JavaScript Object Notation). Python dictionaries map directly to JSON objects.

```python
import json

# Python dict → JSON string (sending)
payload = {"model": "gpt-4o", "messages": [{"role": "user", "content": "Hello"}]}
json_string = json.dumps(payload)
# Result: '{"model": "gpt-4o", "messages": [{"role": "user", "content": "Hello"}]}'

# JSON string → Python dict (receiving)
response_text = '{"grade": "A", "feedback": "Excellent work"}'
data = json.loads(response_text)
# Result: {"grade": "A", "feedback": "Excellent work"}
print(data["grade"])  # "A"
```

**In Markly:** `engine.py` builds a Python dict with the prompt, `json.dumps()` serializes it for the request body, and `json.loads()` or `response.json()` deserializes the response.

---

## 13.8 How Markly Uses APIs: The Full Flow

Here's how the request/response cycle plays out in Markly's grading pipeline:

```
┌─────────────────────────────────────────────────────────────────┐
│                    MARKLY GRADING PIPELINE                      │
├─────────────────────────────────────────────────────────────────┤
│  1. USER uploads file (PDF/DOCX/image)                         │
│     ↓                                                           │
│  2. UTILS extracts text (PyMuPDF, python-docx, pytesseract)   │
│     ↓                                                           │
│  3. ENGINE builds API request (prompt + rubric + extracted text)│
│     ↓                                                           │
│  4. NETWORK sends POST to OpenAI/OpenRouter                    │
│     ↓                                                           │
│  5. AI SERVER processes (1–10 seconds)                         │
│     ↓                                                           │
│  6. NETWORK returns JSON response                               │
│     ↓                                                           │
│  7. ENGINE parses response (extract grade, feedback)            │
│     ↓                                                           │
│  8. MARKUP draws annotations on assignment image               │
│     ↓                                                           │
│  9. REPORT generates PDF with annotated image + feedback       │
│     ↓                                                           │
│  10. STORAGE saves record to students.json                      │
│     ↓                                                           │
│  11. UI displays results to user                               │
└─────────────────────────────────────────────────────────────────┘
```

### The API Request Markly Actually Sends

```python
# Inside engine.py — constructing the API call
import openai
import os

async def grade_assignment(extracted_text, subject, strictness):
    client = openai.AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    
    # Build the prompt (persona + rubric + student work)
    system_prompt = f"You are a {subject} teacher. Be {'strict' if strictness > 0.7 else 'fair'}."
    
    response = await client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Grade this {subject} assignment:\n\n{extracted_text}"}
        ],
        temperature=0.3,  # Lower = more consistent grading
        max_tokens=2000
    )
    
    # Extract the AI's text from the response
    ai_text = response.choices[0].message.content
    return ai_text
```

### Handling the Response

```python
# Inside engine.py — parsing the response
from utils import extract_grade

def process_ai_response(ai_text):
    """Turns raw AI text into structured data."""
    grade = extract_grade(ai_text)  # Regex extraction from Part 1
    feedback = ai_text.split("Feedback:")[-1].strip() if "Feedback:" in ai_text else ai_text
    
    return {
        "grade": grade,
        "feedback": feedback,
        "raw_response": ai_text
    }
```

---

## 13.9 Fallbacks and Resilience

Real-world APIs fail. Markly's `engine.py` implements a **model racing** pattern — trying multiple providers if one fails.

```python
import httpx
import openai

class AIGrader:
    def __init__(self):
        self.openai = openai.AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        self.fallback = httpx.AsyncClient(
            base_url="https://openrouter.ai/api/v1",
            headers={"Authorization": f"Bearer {os.getenv('OPENROUTER_API_KEY')}"}
        )
    
    async def grade(self, prompt):
        # Try OpenAI first
        try:
            return await self._call_openai(prompt)
        except (openai.RateLimitError, openai.APIError):
            # Fallback to OpenRouter
            return await self._call_openrouter(prompt)
    
    async def _call_openai(self, prompt):
        response = await self.openai.chat.completions.create(
            model="gpt-4o",
            messages=prompt
        )
        return response.choices[0].message.content
    
    async def _call_openrouter(self, prompt):
        response = await self.fallback.post(
            "/chat/completions",
            json={"model": "anthropic/claude-3.5-sonnet", "messages": prompt}
        )
        return response.json()["choices"][0]["message"]["content"]
```

**Why this matters:** If OpenAI is down or rate-limited, Markly doesn't crash — it seamlessly switches to OpenRouter. The user never knows there was a problem.

---

## 13.10 Timeouts: Don't Wait Forever

API calls can hang. Markly sets timeouts to prevent the UI from freezing indefinitely.

```python
import httpx

# Default timeout: 30 seconds
async with httpx.AsyncClient(timeout=30.0) as client:
    response = await client.post("https://api.openai.com/...", json=payload)

# Or more granular: connect timeout + read timeout
timeout = httpx.Timeout(10.0, read=30.0)  # 10s to connect, 30s to read
async with httpx.AsyncClient(timeout=timeout) as client:
    response = await client.post("...", json=payload)
```

**Best practice:** Always set timeouts. Without them, a hung request can block your app forever.

---

## 13.11 Key Takeaways

1. **The request/response cycle is universal.** Every API call — OpenAI, OpenRouter, any web service — follows the same pattern: prepare, send, process, receive, handle.

2. **POST is for creating results.** Markly uses POST to send assignment text and receive grades. GET is for reading existing data.

3. **Status codes tell the story.** `200` means success, `401` means check your API key, `429` means slow down, `500` means try again later.

4. **Async is non-negotiable for UIs.** Markly uses `AsyncOpenAI` and `httpx.AsyncClient` so Panel stays responsive during 10-second AI calls.

5. **Never hardcode secrets.** Use `python-dotenv` and `.env` files for API keys. Add `.env` to `.gitignore`.

6. **Plan for failure.** Implement fallback providers, retries, and timeouts. Real APIs are unreliable — your app shouldn't be.

7. **JSON is the bridge.** Python dicts become JSON for the request, and JSON becomes Python dicts in the response. `json.dumps()` and `json.loads()` are your friends.

---

**🎓 Understanding APIs and the request/response cycle transforms you from a coder who uses libraries into a developer who understands how systems talk.** Markly isn't just Python code — it's a network of requests and responses, orchestrated to turn student work into meaningful feedback.

**🎓 Congratulations!** You've now covered every Python concept used across the entire Markly codebase. Start with Part 1 if you're brand new, or jump to any section where you need a refresher. Happy coding!
