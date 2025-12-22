# 🐍 **The Practical Python Mastery Guide**

## **Learn Python by Building a Complete, Real Application — Then Scale It Like a Pro**

**Edition:** 1.1
**Audience:** Beginners → Junior Engineers → Bootcamp Learners → Early Professionals
**Learning Style:** Build-first, explain-when-needed
**Primary Outcome:** Transition from writing "scripts" to engineering maintainable, scalable "systems"

---

## 🌟 The Application We Will Build

We will build **PyInsight**, a production-ready Python CLI application for data analysis.

**Features:**

* Ingress Layer: CLI interface handling user arguments and commands
* Processing Layer: CSV loading, validation, and analytics
* Core Engine: Functional and OOP-based analysis
* Egress Layer: Structured logs, reports in terminal and file formats (JSON/CSV)
* Extensible CLI commands for automation
* Fully testable, packageable, and deployable
* Can handle large datasets and multi-user scenarios

**Text-Based Application Flow Diagram:**

```
User Input (CLI)
      ↓
  CSV Loader
      ↓
  Validator
      ↓
  Analysis Engine
      ↓
  Report Generator
      ↓
Output (Terminal / File / JSON)
```

> Building this **real application** ensures every concept—from variables to CI/CD pipelines—has a practical context.

---

## 🌟 Learning Outcomes

By the end of this guide, readers will be able to:

✔ Read, write, and reason about Python code confidently
✔ Apply functional and OOP paradigms
✔ Build, test, and deploy a complete Python application
✔ Implement error handling, logging, and observability
✔ Use CLI frameworks like `argparse` and `typer`
✔ Package Python projects into executable applications
✔ Implement CI/CD pipelines for Python
✔ Build scalable, maintainable systems

---

# 🧠 Core Learning Philosophy

> You don’t learn Python by memorizing syntax. You learn by **solving real problems under constraints repeatedly**.

**Guiding Principle:**

```
"Memorized syntax is a liability; understood patterns are an asset."
```

We introduce concepts **only when PyInsight needs them**:

* Code breaks → Learn Error Handling
* Code gets messy → Learn Functional Programming
* Code needs state → Learn OOP
* Code must ship → Learn Packaging & CI/CD

> This mirrors **real-world Python engineering practices**.

---

# 🧩 Canonical Application Mental Model

```
User Input
   ↓
Data Loading
   ↓
Validation
   ↓
Analysis Engine
   ↓
Report Generation
   ↓
Output (Terminal / File / CLI)
```

**Key Mindset:**

* Beginners: “Make it work”
* Professionals: “Make it safe, testable, and extensible”

---

# 🧱 PHASE 1 — Python Foundations (Execution With Intent)

Python is more than syntax; it’s about **how the interpreter runs your code, stores data, and allows modular, maintainable designs**. This foundation sets the stage for PyInsight.

---

## 1️⃣ Program Entry & Execution Model

Python executes **top-to-bottom**, interpreting statements as it encounters them. Understanding **entry points** ensures modularity, prevents accidental execution, and supports testing.

```python
def main():
    print("Welcome to PyInsight!")

if __name__ == "__main__":
    main()
```

### Step-by-Step

1. **Define main logic in `main()`** – isolates program functionality.
2. **Check `__name__ == "__main__"`** – ensures code only runs when executed directly.
3. **Importing this module elsewhere** does not trigger `main()`; useful for unit tests.

### Execution Flow Diagram

```
Python Interpreter
     │
     ├─> Executes top-level statements
     ├─> Defines functions and classes
     └─> __name__ check triggers main()
```

**Key Takeaways**

* Prevents code from executing on import
* Promotes modular design
* Facilitates automated testing

---

## 2️⃣ Variables, Data Types & Memory

Python variables **store references** to objects. Types are either **mutable** (can change in-place) or **immutable** (cannot change).

```python
# Immutable types
x = 10
name = "Alice"
pi = 3.1415
status = True
coordinates = (0, 0)

# Mutable types
numbers = [1, 2, 3]
person = {"name": "Alice", "score": 85}
flags = set(["ready", "valid"])
```

### Behavior Table

| Type      | Examples                          | Behavior                                              |
| --------- | --------------------------------- | ----------------------------------------------------- |
| Immutable | int, float, str, tuple, frozenset | Cannot modify in-place; operations create new objects |
| Mutable   | list, dict, set, bytearray        | Can modify in-place; shared references matter         |

### Memory Model Diagram

```
Immutable:
a = 10
b = a       # b points to same object 10
b = 20      # b now points to new object 20, a unchanged

Mutable:
numbers = [1,2,3]
numbers2 = numbers   # both variables point to same list
numbers.append(4)    # numbers2 sees [1,2,3,4]
```

**Practical Tip:** Understanding mutability prevents subtle bugs in PyInsight when passing lists/dicts across functions and classes.

---

## 3️⃣ Collections Module — Advanced Python Data Structures

Python’s `collections` module offers **enhanced structures** for common patterns.

```python
from collections import deque, Counter, defaultdict, namedtuple

# Fast append/pop from both ends
queue = deque([1,2,3])
queue.appendleft(0)  # [0,1,2,3]

# Count occurrences
freq = Counter(["apple","banana","apple"])
# freq -> Counter({'apple': 2, 'banana': 1})

# Auto-initialize missing keys
d = defaultdict(list)
d["fruits"].append("apple")

# Immutable, tuple-like object
Point = namedtuple("Point", ["x","y"])
p = Point(1,2)
```

**Why Use Collections Module?**

* Guarantees predictable behavior
* Optimized for performance
* Reduces boilerplate code

---

## 4️⃣ Operators & Control Flow

Python offers **arithmetic, comparison, logical, membership, and identity operators**:

```
Arithmetic: + - * / // % **
Comparison: == != < > <= >=
Logical: and or not
Membership: in not in
Identity: is is not
```

### Control Flow & Truthiness

```python
if not filename:
    print("Filename required")
```

* Falsy values: `None`, `False`, `0`, `""`, `[]`, `{}`, `()`
* Everything else is **truthy**

**Step-by-Step:**

1. Evaluate the condition (`not filename`)
2. If `filename` is empty, execute block
3. Else, continue normal flow

---

## 5️⃣ Step-By-Step Mini Project Exercise

Readers can follow these steps to apply Phase 1 concepts:

1. **Create a Python file** `pyinsight_main.py`
2. **Define `main()`** with a simple print statement
3. **Use `__name__ == "__main__"`** check
4. **Declare a mix of mutable and immutable variables**
5. **Experiment with lists, dicts, sets, and collections module**
6. **Add control flow** checking for empty inputs
7. **Print results** and observe mutability effects

By completing this exercise, readers will **understand Python’s execution model, variables, mutability, collections, and control flow**, laying a strong foundation for building PyInsight.

---

# 🧱 PHASE 2 — Data Structures in PyInsight

In PyInsight, CSV data is represented as a **list of dictionaries**, where each dictionary corresponds to a row. This structure allows the analysis engine to work with **flexible, mutable, and explicit data contracts**.

---

## 1️⃣ Core Data Structures

```python
# Single row as a dictionary
row = {"name": "Alice", "score": 85}

# Multiple rows as a list of dictionaries
rows = [row]

# Set for unique tags
tags = {"python", "data", "cli"}
```

### Key Points

* **Dicts** → Key-value pairs, represent contracts for data
* **Lists** → Ordered collections, mutable, used for rows
* **Sets** → Unique items, fast membership checks, useful for tags or categories

---

## 2️⃣ Data Structure Flow Diagram

```
CSV Loader
    │
    ▼
rows -> list of dicts (mutable)
tags -> set of unique categories (mutable)
summary -> dict of metrics (immutable once created)
```

*Rows flow through the system, tags represent unique categorical data, and summaries are immutable once calculated for safety.*

---

## 3️⃣ Working With Rows

Example: iterate and access data in rows

```python
for row in rows:
    print(f"{row['name']} scored {row['score']}")
```

*Output:*

```
Alice scored 85
```

*Note:* Modifying `rows` or `row` affects the underlying data because lists and dicts are **mutable**.

---

## 4️⃣ Adding and Removing Rows

```python
# Add a new row
rows.append({"name": "Bob", "score": 92})

# Remove a row
rows.pop(0)  # removes first row

# Update a value
rows[0]["score"] = 95
```

*Demonstrates mutability — changes affect all references to the same object.*

---

## 5️⃣ CSV Loading — Step-by-Step

PyInsight uses a simple loader function to read CSV files safely:

```python
import csv

def load_csv(path):
    """Load CSV file into a list of dictionaries."""
    with open(path, newline="") as f:  # context manager ensures file closes
        return list(csv.DictReader(f))
```

### Step-by-Step Notes

1. **Context Managers** (`with open(...) as f`)

   * Ensures files are **automatically closed**, even if an exception occurs.

2. **`csv.DictReader`**

   * Reads CSV rows into **dictionaries keyed by column names**.
   * Provides a **consistent contract** for downstream processing.

3. **Return as List**

   * Wraps rows in a **mutable list**, enabling easy iteration, filtering, and analysis.

---

## 6️⃣ Accessing CSV Data

```python
rows = load_csv("data.csv")

for row in rows:
    name = row["name"]
    score = int(row["score"])
    print(f"{name}: {score}")
```

*Ensures that CSV strings are converted to the correct data type (e.g., `int`, `float`).*

---

## 7️⃣ Optional: Collect Unique Categories

```python
tags = set(row["category"] for row in rows if "category" in row)
```

*Extracts all unique categories from a CSV column.*
*Sets are ideal because duplicates are automatically removed.*

---

## 8️⃣ Next Steps in PyInsight

After loading data, the **next phase** is **validation**:

* Ensure required columns exist
* Check for missing or malformed values
* Raise custom `DataError` exceptions for invalid rows

This keeps the pipeline **predictable and robust**.

---

> ✅ **Takeaway:**
> Using **lists of dictionaries** and **sets** provides a flexible yet structured representation of CSV data. This approach forms the **backbone of PyInsight**, enabling analysis, reporting, and logging in later phases.

---

# 🧱 PHASE 3 — Error Handling

Error handling is a **critical skill** for building robust Python applications. In PyInsight, we handle errors **gracefully**, giving clear messages, preventing crashes, and making debugging easier.

---

## 1️⃣ EAFP — Easier to Ask for Forgiveness than Permission

Python encourages the **EAFP** style: assume operations will succeed and handle exceptions if they fail, instead of pre-checking everything.

```python
try:
    data = load_csv("data.csv")
except FileNotFoundError:
    print("File not found. Please check the file path.")
except PermissionError:
    print("Permission denied. Cannot read the file.")
```

**Why EAFP?**

* Less boilerplate code than checking every condition first
* Handles **unexpected edge cases** that pre-checks might miss
* Makes code **readable and Pythonic**

---

## 2️⃣ Using Multiple Exceptions

You can catch multiple types of errors in a single block:

```python
try:
    data = load_csv("data.csv")
except (FileNotFoundError, PermissionError) as e:
    print(f"Error loading CSV: {e}")
```

* `as e` captures the exception object for logging or debugging.*

---

## 3️⃣ Custom Exceptions

For **domain-specific errors**, define **custom exception classes**:

```python
class DataError(Exception):
    """Raised when dataset is invalid"""
```

**Example: Validate CSV Column**

```python
def validate_rows(rows):
    required_columns = ["name", "score"]
    for i, row in enumerate(rows, start=1):
        for col in required_columns:
            if col not in row:
                raise DataError(f"Row {i} missing required column '{col}'")
```

**Usage in PyInsight:**

```python
try:
    rows = load_csv("data.csv")
    validate_rows(rows)
except DataError as e:
    print(f"Validation failed: {e}")
```

*Benefits:*

* Improves **readability** and debugging
* Makes testing easier — you can assert exceptions in unit tests
* Keeps **business logic** separate from general Python exceptions

---

## 4️⃣ Using `finally` and `else`

Python provides **`else`** and **`finally`** for more control:

```python
try:
    rows = load_csv("data.csv")
except FileNotFoundError:
    print("File not found")
else:
    print("CSV loaded successfully")
finally:
    print("Cleanup or closing resources")
```

* `else` runs if no exception occurred
* `finally` always runs, ideal for resource cleanup (closing files, DB connections)

---

## 5️⃣ Logging Exceptions

Instead of `print()`, log errors for production applications:

```python
import logging

logging.basicConfig(level=logging.INFO)
try:
    rows = load_csv("data.csv")
except FileNotFoundError as e:
    logging.error("Failed to load CSV: %s", e)
```

* Combines **error handling** with **observability** (logs → metrics → traces)
* Makes debugging in production easier

---

## 6️⃣ Step-by-Step Error Handling in PyInsight

1. **Load CSV** → catch `FileNotFoundError`, `PermissionError`
2. **Validate Rows** → raise `DataError` for missing/invalid data
3. **Analysis** → catch calculation errors (`ZeroDivisionError`, `ValueError`)
4. **Report Generation** → catch file writing errors (`IOError`)
5. **Log Everything** → integrate with logging module for structured observability

**Flow Diagram:**

```
CSV Loader
   │
   ▼
  Try/Except: FileNotFoundError, PermissionError
   │
Validation
   │
   ▼
Custom Exception: DataError
   │
Analysis Engine
   │
   ▼
Try/Except: ValueError, ZeroDivisionError
   │
Report Generator
   │
   ▼
Try/Except: IOError
   │
Logging → Metrics → Traces
```

> **Takeaway:** Proper error handling in PyInsight ensures **predictable, safe, and debuggable execution**, while keeping user-friendly messages and system logs intact.

---

# 🧱 PHASE 4 — Functional Programming

Functional programming in Python emphasizes **pure functions, immutability, and predictable behavior**. In PyInsight, we use these principles to make our **analytics engine testable, modular, and maintainable**.

---

## 1️⃣ Pure Functions

A **pure function**:

* Always produces the same output for the same input
* Has **no side effects** (does not modify global or external state)
* Is **predictable and testable**

**Example: Summarizing a Column in PyInsight**

```python
def summarize(rows, column):
    values = [float(r[column]) for r in rows]
    return {
        "count": len(values),
        "avg": sum(values) / len(values),
        "min": min(values),
        "max": max(values)
    }
```

**Benefits:**

* Easy to unit test:

```python
rows = [{"score": "10"}, {"score": "20"}, {"score": "30"}]
result = summarize(rows, "score")
assert result["avg"] == 20
assert result["count"] == 3
```

* Can be composed with other functions without worrying about hidden state
* Makes debugging simpler because output depends only on input

---

## 2️⃣ Immutability

Pure functions often **avoid modifying the input**. Instead of changing `rows` directly:

```python
# Avoid this (side-effect)
def normalize_in_place(rows, column):
    for r in rows:
        r[column] = float(r[column]) / 100
```

We return a **new dataset**:

```python
def normalize(rows, column):
    return [{**r, column: float(r[column])/100} for r in rows]
```

*Original data remains unchanged, preventing accidental bugs in later stages.*

---

## 3️⃣ Lambdas — Anonymous Functions

Lambdas are **one-line functions** useful for short operations. In PyInsight:

```python
# Sort rows by score
rows.sort(key=lambda r: float(r["score"]))
```

**When to use:**

* Quick, short, obvious operations
* Inline with `sort`, `map`, `filter`, `reduce`

**Avoid complex logic in lambdas** — extract to named pure functions for readability:

```python
def score_key(row):
    return float(row["score"])

rows.sort(key=score_key)
```

---

## 4️⃣ Higher-Order Functions

A **higher-order function** either:

* Accepts a function as an argument
* Returns a function

**Example: Apply a transformation to any column**

```python
def apply_column(rows, column, func):
    return [{**r, column: func(r[column])} for r in rows]

# Usage: convert scores to percentages
rows = apply_column(rows, "score", lambda x: float(x)/100)
```

*Encapsulates transformation logic and keeps it reusable.*

---

## 5️⃣ Map, Filter, Reduce

Python functional helpers allow concise transformations:

```python
from functools import reduce

# Extract scores
scores = list(map(lambda r: float(r["score"]), rows))

# Filter high scores
high_scores = list(filter(lambda x: x > 80, scores))

# Reduce to sum
total_score = reduce(lambda a, b: a+b, scores)
```

*Functional style avoids explicit loops, making intent clear.*

---

## 6️⃣ Benefits of Functional Programming in PyInsight

| Feature                 | Benefit                                           |
| ----------------------- | ------------------------------------------------- |
| Pure Functions          | Predictable output, easy testing                  |
| Immutability            | Prevents accidental side-effects, safer pipelines |
| Lambdas                 | Concise inline operations                         |
| Higher-Order Functions  | Reusable transformations, composable logic        |
| `map`/`filter`/`reduce` | Declarative data processing, reduces boilerplate  |

---

## 7️⃣ Step-by-Step Usage in PyInsight

1. **Load CSV** → list of dicts
2. **Validate Data** → pure function returning valid rows
3. **Analyze Columns** → pure functions: `summarize`, `normalize`, `aggregate`
4. **Sort or Transform** → lambdas or higher-order functions
5. **Generate Reports** → pure formatting functions returning strings or dicts

**Text-Based Flow:**

```
CSV Loader
    │
    ▼
Validation (pure function)
    │
    ▼
Analysis Engine (summarize, normalize, aggregate)
    │
    ▼
Sorting / Transformation (lambdas / map/filter)
    │
    ▼
Report Generator (pure formatting)
```

> **Takeaway:** Functional programming keeps PyInsight **predictable, testable, and modular**, especially as datasets grow and transformations become complex.

---

# 🧱 PHASE 5 — Argument Unpacking (`*args` & `**kwargs`)

In Python, argument unpacking allows functions to accept **a variable number of positional and keyword arguments**. This is a cornerstone for **flexible APIs, decorators, and modular systems**.

---

## 1️⃣ `*args` — Variable Positional Arguments

`*args` allows a function to accept **any number of positional arguments** as a tuple.

```python
def log(*args):
    print("Positional arguments:", args)

log("Starting analysis", "File:", "data.csv")
```

**Output:**

```
Positional arguments: ('Starting analysis', 'File:', 'data.csv')
```

✅ Use case in PyInsight: pass multiple indicators to the analysis engine without defining them upfront.

```python
def analyze(data, *indicators):
    for indicator in indicators:
        print(f"Calculating {indicator}...")
        
analyze(my_data, "RSI", "MACD", "EMA")
```

---

## 2️⃣ `**kwargs` — Variable Keyword Arguments

`**kwargs` allows a function to accept **any number of named arguments** as a dictionary.

```python
def log(**kwargs):
    print("Keyword arguments:", kwargs)

log(level="INFO", module="loader", message="CSV loaded")
```

**Output:**

```
Keyword arguments: {'level': 'INFO', 'module': 'loader', 'message': 'CSV loaded'}
```

✅ Use case in PyInsight: configurable options for functions or decorators.

```python
def analyze(data, **config):
    period = config.get("period", 14)
    threshold = config.get("threshold", 70)
    print(f"Using period={period}, threshold={threshold}")
    
analyze(my_data, period=20, threshold=60)
```

---

## 3️⃣ Combining `*args` and `**kwargs`

You can combine both to accept **any combination of positional and keyword arguments**.

```python
def analyze(data, *indicators, **config):
    print("Indicators:", indicators)
    print("Config:", config)

analyze(my_data, "RSI", "MACD", period=14, threshold=70)
```

**Output:**

```
Indicators: ('RSI', 'MACD')
Config: {'period': 14, 'threshold': 70}
```

---

## 4️⃣ Using Argument Unpacking When Calling Functions

You can also **unpack sequences and dictionaries** into function arguments.

```python
numbers = [1, 2, 3]
def add(a, b, c):
    return a + b + c

print(add(*numbers))  # Output: 6

params = {"a": 1, "b": 2, "c": 3}
print(add(**params))  # Output: 6
```

✅ In PyInsight, this allows **passing configuration dictionaries or lists of columns** directly to functions.

---

## 5️⃣ Practical Benefits in PyInsight

* **Flexible APIs:** Allow users to add more indicators, metrics, or options without changing the function signature.
* **Decorators & Logging:** Wrap functions and forward any arguments without knowing them in advance.
* **Dynamic Configuration:** Pass runtime options (CLI args, config files) to core functions seamlessly.

```python
def timed(func):
    def wrapper(*args, **kwargs):
        import time
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        print(f"{func.__name__} took {end-start:.2f}s")
        return result
    return wrapper

@timed
def summarize(rows, *columns, **options):
    print("Columns:", columns)
    print("Options:", options)
    return {col: sum(float(r[col]) for r in rows) for col in columns}

summarize(rows, "score", "age", normalize=True)
```

---

## 6️⃣ Summary

| Feature          | Example                          | Benefit                                    |
| ---------------- | -------------------------------- | ------------------------------------------ |
| `*args`          | `def f(*args)`                   | Accepts any number of positional arguments |
| `**kwargs`       | `def f(**kwargs)`                | Accepts any number of named arguments      |
| Unpacking        | `f(*list)`, `f(**dict)`          | Forward arguments dynamically              |
| Use in PyInsight | `analyze(*indicators, **config)` | Flexible APIs and decorators               |

---

> **Takeaway:** Mastering `*args` and `**kwargs` makes PyInsight **extensible and adaptable**, letting you write functions that can grow with future requirements without rewriting signatures.

---

# 🧱 PHASE 6 — Logging & Observability

> Observability is **how you understand your system from the outside** without changing its behavior.
> It allows you to **debug, monitor, and optimize** PyInsight in production and development.

---

## 1️⃣ The Three Pillars of Observability

1. **Logs (Structured Events)**

   * Describe **what happened** at a point in time.
   * Include context: row IDs, filenames, timestamps.
   * Example:

```python
import logging

logging.basicConfig(
    level=logging.INFO, 
    format="%(asctime)s %(levelname)s [%(module)s] %(message)s"
)

logging.info("Loaded %d rows from %s", len(rows), filename)
logging.warning("Missing values detected in column 'score'")
logging.error("Failed to process row %d: %s", 5, row)
```

✅ Tips:

* Use levels (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`)
* Avoid `print()` for production code
* Include structured data to help filtering and analytics

---

2. **Metrics (Quantitative Measurements)**

   * Track **how the system is performing** over time.
   * Examples in PyInsight:

* Number of rows processed per second
* Average memory usage per file
* Number of errors per dataset

- Libraries / tools: `Prometheus`, `StatsD`, `OpenTelemetry`

```python
processed_rows = len(rows)
error_count = sum(1 for r in rows if not r.get("score"))

# Pseudo-metric reporting
metrics.report("rows_processed", processed_rows)
metrics.report("errors", error_count)
```

✅ Metrics give **trends and alerts**, letting you know when the system behaves abnormally.

---

3. **Traces (Flow of Execution)**

   * Show the **path of a request** through the system.
   * Useful for identifying bottlenecks, slow stages, or failed operations.
   * Example: Track how a CSV file moves through PyInsight:

```
CSV File Loaded
      │
      ▼
Validation & Cleaning
      │
      ▼
Analysis Engine
      │
      ▼
Report Generation
      │
      ▼
Logs / Metrics / Traces
```

*Tools:* `Jaeger`, `Zipkin`, `OpenTelemetry`

✅ Traces help **visualize execution**, especially in multi-step pipelines or distributed systems.

---

## 2️⃣ Observability Implementation in PyInsight

Step-by-step:

1. **Replace `print()` with structured logging**

   ```python
   logging.info("Starting analysis for file %s", filename)
   ```
2. **Emit metrics for key operations**

   ```python
   metrics.report("rows_loaded", len(rows))
   ```
3. **Add trace markers for critical stages**

   ```python
   with tracer.span("validation"):
       validate_rows(rows)
   ```
4. **Combine logs, metrics, and traces**

   * Logs give details per event
   * Metrics give aggregate numbers
   * Traces show execution flow

---

## 3️⃣ Observability Flow Diagram

```
CSV Loader
      │
      ▼
Validation
      │
      ▼
Analysis Engine
      │
      ▼
Report Generator
      │
      ▼
Logs / Metrics / Traces emitted to monitoring
```

*This maps directly to PyInsight layers, ensuring every step is observable.*

---

## 4️⃣ Benefits for PyInsight

* Quickly pinpoint **bottlenecks or errors**
* Understand **system behavior under load**
* Debug production issues **without stopping the service**
* Provide **audit trails** and reproducibility for analytics

---

## 5️⃣ Step-by-Step Exercise for Readers

1. **Add structured logging** to CSV loading:

   ```python
   logging.info("Loading CSV: %s", path)
   ```
2. **Track metrics** for number of rows and missing values.
3. **Add simple traces** around `validate_rows()` and `summarize()` functions.
4. **Run the application** with a test CSV and observe logs, metrics, and traces in console output.
5. **Optionally integrate** a metrics library (`prometheus_client`) for real-time dashboards.

---

> **Takeaway:** Observability is **non-negotiable** for production-grade Python applications. In PyInsight, combining logs, metrics, and traces ensures you can **monitor, debug, and optimize** efficiently.

---


# 🧱 PHASE 7 — Object-Oriented Programming (OOP)

> Object-Oriented Programming helps **manage complexity, encapsulate state, and design scalable systems**.
> In PyInsight, OOP is used to wrap CSV data, analytics logic, and reporting functionality into **modular, reusable, and testable classes**.

---

## 1️⃣ The Four Pillars of OOP in PyInsight

### 1. **Encapsulation**

Encapsulation hides internal state and exposes a controlled interface.

```python
class Dataset:
    def __init__(self, rows):
        self._rows = rows  # private internal state

    def summarize(self, column):
        values = [float(r[column]) for r in self._rows]
        return {"count": len(values), "avg": sum(values)/len(values)}
```

✅ **Why it matters:**

* Prevents external code from accidentally modifying internal state
* Provides a single point of control to manage data
* Makes testing and debugging easier

---

### 2. **Abstraction**

Abstraction defines **what a class should do**, not how. Use **abstract base classes** for standard interfaces.

```python
from abc import ABC, abstractmethod

class Analyzer(ABC):
    @abstractmethod
    def analyze(self, data):
        """Analyze the dataset"""
        pass
```

**Example implementation:**

```python
class CSVAnalyzer(Analyzer):
    def analyze(self, data):
        print("Analyzing CSV data")
        # specific logic here
```

✅ **Why it matters:**

* Sets clear contracts for subclasses
* Allows interchangeable implementations (e.g., CSV, JSON, Excel analyzers)
* Enables polymorphism

---

### 3. **Inheritance & Mixins**

Inheritance lets you **reuse and extend behavior**, while mixins add specialized functionality.

```python
class LoggingMixin:
    def log(self, message):
        print(f"[LOG] {message}")

class CSVAnalyzer(Analyzer, LoggingMixin):
    def analyze(self, data):
        self.log("Starting CSV analysis")
        # Analysis logic here
```

**Key Points:**

* `CSVAnalyzer` inherits the abstract interface from `Analyzer`
* Adds logging functionality via `LoggingMixin`
* Can extend or override methods as needed

---

### 4. **Polymorphism**

Polymorphism allows **different classes to be used interchangeably** as long as they share the same interface.

```python
def run_analysis(analyzer: Analyzer, data):
    analyzer.analyze(data)

csv_analyzer = CSVAnalyzer()
run_analysis(csv_analyzer, data)
```

*Result:* Any class implementing `Analyzer` can be passed to `run_analysis()`, enabling **flexible and extensible systems**.

---

## 2️⃣ Practical Example: PyInsight Dataset & Analyzer

```python
class Dataset:
    def __init__(self, rows):
        self._rows = rows

    def summarize(self, column):
        values = [float(r[column]) for r in self._rows]
        return {"count": len(values), "avg": sum(values)/len(values)}

class Analyzer(ABC):
    @abstractmethod
    def analyze(self, dataset: Dataset):
        pass

class CSVAnalyzer(Analyzer, LoggingMixin):
    def analyze(self, dataset: Dataset):
        self.log("Starting analysis")
        summary = dataset.summarize("score")
        self.log(f"Summary: {summary}")
        return summary
```

**Usage:**

```python
rows = [{"name": "Alice", "score": 85}, {"name": "Bob", "score": 90}]
dataset = Dataset(rows)
analyzer = CSVAnalyzer()
result = analyzer.analyze(dataset)
```

**Output:**

```
[LOG] Starting analysis
[LOG] Summary: {'count': 2, 'avg': 87.5}
```

---

## 3️⃣ Step-by-Step Guide for Readers

1. **Encapsulate Data**: Wrap CSV rows inside a `Dataset` class and hide the internal list (`_rows`).
2. **Define Abstract Interface**: Create `Analyzer` abstract base class with `analyze()` method.
3. **Implement Concrete Analyzers**: CSV, JSON, or other data sources implement `Analyzer`.
4. **Add Mixins**: Logging, timing, or metrics mixins can be reused across analyzers.
5. **Use Polymorphism**: Pass any `Analyzer` instance to generic processing functions for flexible pipelines.

---

## ✅ Benefits in PyInsight

* **Modularity**: Each class has a clear responsibility
* **Extensibility**: Easily add new analyzers without changing existing code
* **Testability**: Encapsulation and abstraction simplify unit testing
* **Maintainability**: Mixins and clear contracts prevent code duplication

---

# 🧱 PHASE 8 — Testing in PyInsight

> Testing is **not optional**. A system without tests is a system waiting to fail.
> PyInsight uses **unit tests, integration tests, and functional tests** to ensure reliability and safe refactoring.

---

## 1️⃣ Why Testing Matters

1. **Safety** – Prevents accidental breaks when changing code.
2. **Documentation** – Tests describe expected behavior.
3. **Refactoring Confidence** – You can restructure code without fear of introducing bugs.
4. **Early Bug Detection** – Catch issues before they reach production.

---

## 2️⃣ Types of Tests

| Type                 | Purpose                                      | Example                                        |
| -------------------- | -------------------------------------------- | ---------------------------------------------- |
| **Unit Test**        | Test a small piece of logic in isolation     | `calculate_avg()`                              |
| **Integration Test** | Test multiple components working together    | `Dataset + Analyzer`                           |
| **Functional Test**  | Test the app end-to-end                      | CLI command `pyinsight analyze data.csv score` |
| **Regression Test**  | Ensure bugs fixed in the past don’t reappear | Re-run previously failing tests                |

---

## 3️⃣ Unit Testing Example

```python
# pyinsight/tests/test_analysis.py
from pyinsight.analysis import calculate_avg

def test_calculate_avg():
    mock_data = [{"val": "10"}, {"val": "20"}]
    assert calculate_avg(mock_data, "val") == 15.0
```

✅ **Key points:**

* Small and isolated
* Fast execution
* Focused on a **single function**
* Uses `assert` statements to check behavior

---

## 4️⃣ Integration Testing Example

```python
# pyinsight/tests/test_integration.py
from pyinsight.analysis import summarize
from pyinsight.loader import load_csv

def test_dataset_summary(tmp_path):
    # Create a temporary CSV file
    file = tmp_path / "data.csv"
    file.write_text("name,score\nAlice,85\nBob,90")
    
    # Load data
    rows = load_csv(file)
    
    # Summarize
    result = summarize(rows, "score")
    
    assert result["count"] == 2
    assert result["avg"] == 87.5
```

✅ **Why it matters:**

* Ensures multiple modules work together correctly
* Simulates a real use case (CSV loading + analysis)

---

## 5️⃣ Functional / End-to-End Testing

```python
# tests/test_cli.py
from subprocess import run, PIPE

def test_cli_analysis(tmp_path):
    csv_file = tmp_path / "data.csv"
    csv_file.write_text("name,score\nAlice,85\nBob,90")
    
    result = run(["python", "pyinsight/cli.py", "--file", str(csv_file), "--column", "score"],
                 stdout=PIPE, stderr=PIPE, text=True)
    
    assert "Average: 87.5" in result.stdout
```

*Validates the **full CLI pipeline** from user input → CSV loader → analyzer → output.*

---

## 6️⃣ Test-Driven Development (TDD) Workflow

1. **Write a failing test** for a feature you want to implement.
2. **Implement minimal code** to pass the test.
3. **Refactor code**, keeping the test passing.
4. Repeat for every feature.

✅ **Benefit:** Ensures code is **always tested and modular**.

---

## 7️⃣ Best Practices for Testing PyInsight

* **Isolate tests** – use temporary files or mocks instead of real data
* **Test edge cases** – empty CSVs, missing columns, invalid data
* **Use descriptive names** – `test_average_with_empty_list()`
* **Keep tests fast** – use in-memory data when possible
* **Automate** – integrate with CI/CD pipelines

---

## 8️⃣ Running Tests

```bash
# Run all tests
pytest

# Run a single test file
pytest tests/test_analysis.py

# Run with verbose output
pytest -v
```

✅ **Tip:** Use `pytest` fixtures to create reusable mock datasets and environments.

---

## 9️⃣ Observability in Tests

* Use logs in tests to understand failures:

```python
import logging
logging.basicConfig(level=logging.DEBUG)

def test_debug_example():
    logging.debug("Rows: %s", [{"val": 10}])
    assert True
```

* Helps **quickly debug failing tests** without changing production code.

---

### Step-by-Step Reader Instructions:

1. **Start small:** Write unit tests for each pure function in `analysis.py`.
2. **Expand coverage:** Write integration tests combining `Dataset`, `Analyzer`, and loader modules.
3. **Test CLI:** Simulate real user input and check outputs.
4. **Automate:** Add `pytest` runs to your CI/CD pipeline.
5. **Refactor confidently:** With tests in place, you can improve code safely.

---

> **Takeaway:** Testing is the **safety net and documentation** of PyInsight. Every function, module, and CLI command should be **covered with meaningful tests**.

---

# 🧱 PHASE 9 — Decorators

> Decorators allow you to **wrap functions or methods** to add behavior **without modifying their core logic**.
> They are critical for implementing cross-cutting concerns like **logging, validation, timing, caching, and authorization**.

---

## 1️⃣ What a Decorator Is

A **decorator** is a **function that takes another function and returns a new function** with extended behavior.

**Basic Syntax:**

```python
def my_decorator(func):
    def wrapper(*args, **kwargs):
        print("Before the function runs")
        result = func(*args, **kwargs)
        print("After the function runs")
        return result
    return wrapper

@my_decorator
def greet(name):
    print(f"Hello {name}!")

greet("Alice")
```

**Output:**

```
Before the function runs
Hello Alice!
After the function runs
```

✅ Key point: `@my_decorator` is equivalent to `greet = my_decorator(greet)`.

---

## 2️⃣ Why Decorators Matter in PyInsight

In a **real application**, you often want to:

* Log function entry and exit
* Validate inputs
* Measure execution time
* Enforce preconditions or authorization

Without decorators, you’d have to **duplicate this logic** in every function.
Decorators **centralize cross-cutting concerns**.

---

## 3️⃣ Common PyInsight Decorators

### a) Timing Decorator

Tracks how long a function takes to execute:

```python
import time
import logging

def timed(func):
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        logging.info("%s executed in %.4f seconds", func.__name__, end - start)
        return result
    return wrapper
```

**Usage:**

```python
@timed
def summarize(rows, column):
    values = [float(r[column]) for r in rows]
    return {"count": len(values), "avg": sum(values)/len(values)}
```

**Result:** Every call logs its execution time automatically.

---

### b) Input Validation Decorator

Ensures functions are not called with empty or invalid data:

```python
def require_nonempty(func):
    def wrapper(rows, column, *args, **kwargs):
        if not rows:
            raise ValueError("Rows cannot be empty")
        if not column:
            raise ValueError("Column name must be provided")
        return func(rows, column, *args, **kwargs)
    return wrapper
```

**Usage:**

```python
@require_nonempty
def summarize(rows, column):
    ...
```

**Behavior:** Prevents runtime errors and centralizes input validation.

---

### c) Composing Multiple Decorators

Decorators **stack top-to-bottom**: the decorator closest to the function runs first.

```python
@timed
@require_nonempty
def summarize(rows, column):
    values = [float(r[column]) for r in rows]
    return {"count": len(values), "avg": sum(values)/len(values)}
```

**Execution Flow:**

1. `require_nonempty` checks inputs first
2. `timed` measures execution time of the actual function

**Tip:** Order matters—place validation decorators **closest to the function**, logging or timing decorators **outermost**.

---

## 4️⃣ Advanced Decorator Patterns

### a) Decorators with Arguments

```python
def log_message(level="INFO"):
    def decorator(func):
        def wrapper(*args, **kwargs):
            getattr(logging, level.lower())("Running %s", func.__name__)
            return func(*args, **kwargs)
        return wrapper
    return decorator

@log_message(level="DEBUG")
def summarize(rows, column):
    ...
```

✅ Provides **customizable behavior** for decorators.

---

### b) Class Method Decorators

Decorators work on methods too:

```python
class Dataset:
    def __init__(self, rows):
        self.rows = rows

    @timed
    @require_nonempty
    def summarize(self, column):
        values = [float(r[column]) for r in self.rows]
        return {"count": len(values), "avg": sum(values)/len(values)}
```

**Benefit:** Keeps your **Dataset class clean** while adding logging, timing, or validation automatically.

---

### c) Preserving Metadata with `functools.wraps`

Always use `functools.wraps` to keep function metadata:

```python
from functools import wraps

def timed(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        logging.info("%s executed in %.4f seconds", func.__name__, time.time() - start)
        return result
    return wrapper
```

**Why:** Without `wraps`, function name, docstring, and signature may be lost.

---

## 5️⃣ Step-by-Step Implementation in PyInsight

1. **Add decorators directory/module**

   ```
   pyinsight/
   └── decorators.py
   ```

2. **Implement cross-cutting decorators**

   * `timed` for performance monitoring
   * `require_nonempty` for input validation
   * `log_message` for logging and debugging

3. **Apply decorators to core functions**

   * Analysis functions
   * CSV loader and validator
   * Report generators

4. **Verify behavior**

   * Empty rows → raise exception
   * Execution time → logged automatically
   * Logs formatted consistently

---

✅ **Takeaway:**

Decorators allow PyInsight to be **extensible, maintainable, and production-ready** by:

* Keeping core logic clean
* Centralizing cross-cutting concerns
* Providing consistent validation, logging, and monitoring

---

# 🧱 PHASE 🔟 — Packaging & Modules

```
pyinsight/
├── pyinsight/
│   ├── __init__.py
│   ├── analysis.py
│   ├── loader.py
│   ├── decorators.py
│   └── errors.py
├── tests/
└── pyproject.toml
```

* Run as module: `python -m pyinsight.analysis`

---

# 🧱 PHASE 1️⃣1️⃣ — CLI Tools

* **argparse:** `python pyinsight/cli.py --file data.csv --column score`
* **typer:** `python pyinsight/cli_typer.py analyze data.csv score`

---

# 🧱 PHASE 1️⃣2️⃣ — Production Packaging

```toml
[project]
name = "pyinsight"
version = "0.1.0"
dependencies = ["typer","pytest","pandas"]

[project.scripts]
pyinsight = "pyinsight.cli:main"
```

* Package installable via `pip install .`
* Executable: `pyinsight --help`

---

# 🧱 PHASE 1️⃣3️⃣ — CI/CD

Automate testing, linting, packaging, and deployment:

```yaml
jobs:
  build:
    steps:
      - run: pytest
      - run: python -m build
```

# 🧱 PHASE 1️⃣4️⃣ — Observability

> Observability is **how you understand your system from the outside**, without changing its behavior.
> It ensures you can **monitor, debug, and optimize** production systems effectively.

---

## 1️⃣ The Three Pillars of Observability

Observability in Python (and in PyInsight) relies on **three key pillars**:

### 1. Logs — Record What Happened

* **Definition:** Structured events describing **what happened, when, and where** in your system.
* **Purpose:** Quickly identify issues and understand flow.
* **Implementation Example:**

```python
import logging

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s"
)

logging.info("Loaded %d rows from file %s", len(rows), filename)
logging.warning("Missing values in column 'score'")
logging.error("Failed to process row %d: %s", 5, row)
```

**Tips:**

* Use **levels**: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`
* Include **context**: row numbers, filenames, function names
* Avoid `print()` in production

---

### 2. Metrics — Quantitative Measurements

* **Definition:** Numbers that quantify your system’s performance over time.
* **Purpose:** Monitor health, track trends, detect anomalies.
* **Examples in PyInsight:**

  * Rows processed per second
  * Memory usage while loading large CSVs
  * Error count per file
* **Implementation Example (Prometheus client for Python):**

```python
from prometheus_client import Counter, start_http_server

# Start Prometheus metrics server
start_http_server(8000)

# Define metric
rows_processed = Counter("rows_processed_total", "Number of rows processed")

# Increment during processing
for row in rows:
    rows_processed.inc()
```

**Tip:** Metrics are often **scraped** by monitoring systems like Prometheus, Grafana, or StatsD.

---

### 3. Traces — Follow the Flow

* **Definition:** Track the execution path of requests or operations across components.
* **Purpose:** Understand **latency, bottlenecks, and dependencies**.
* **PyInsight Example:** Track a CSV file through Loader → Validator → Analysis → Report Generator.
* **Implementation Example (OpenTelemetry):**

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor

trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)
trace.get_tracer_provider().add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))

with tracer.start_as_current_span("load_csv"):
    rows = load_csv("data.csv")

with tracer.start_as_current_span("analyze_data"):
    analysis = summarize(rows, "score")
```

**Tip:** Traces help **pinpoint performance bottlenecks** and **understand dependencies**.

---

## 2️⃣ Observability Flow in PyInsight

**Step-by-step visual flow** of how logs, metrics, and traces interact in PyInsight:

```
CSV File Loaded
      │
      ▼
Validation & Cleaning
      │
      ▼
Analysis Engine
      │
      ▼
Report Generation
      │
      ▼
Logs, Metrics, Traces
```

**Key Observability Benefits:**

1. **Debug faster** – Find errors without guessing
2. **Monitor performance** – Detect slow processes or memory spikes
3. **Optimize workflow** – Identify bottlenecks in the analysis engine
4. **Ensure reliability** – Catch and fix issues before they reach users

---

## 3️⃣ Practical Step-by-Step Instructions

**Step 1:** Add logging to each module

* Loader: Log CSV read start, row count, missing values
* Validator: Log invalid rows, skipped rows
* Analyzer: Log functions called, metrics computed
* Reporter: Log report generation success or failure

**Step 2:** Collect metrics

* Define counters, timers, and gauges for critical operations
* Expose them via HTTP endpoint for monitoring

**Step 3:** Trace execution

* Wrap each major phase (Loader, Validator, Analyzer, Reporter) in a **trace span**
* Use this for debugging latency or performance issues

**Step 4:** Visualize and act

* Use dashboards (Grafana, Kibana) to monitor logs, metrics, and traces in real time
* Use alerts for failures, slow performance, or anomalies

---

✅ **Takeaway:** Observability is **not optional**—it transforms a script into a **maintainable, production-ready system**. Every module in PyInsight should log its activity, expose metrics, and participate in traces.

---

# 🧱 PHASE 1️⃣5️⃣ — Large-Scale Python Systems

**Scales Well:**

* Pure functions, clear contracts, explicit boundaries, testing

**Does Not Scale:**

* Global variables, hidden mutable state, magic

**System Mental Model:**

```
User Input
   │
CSV Loader → Validator → Analysis → Reports
   │
   └── Logs / Metrics / Traces
```

> **Takeaway:** Design for clarity, modularity, observability from day one.

---

✅ **Next Step for Readers:**

* Implement each phase **step by step** in `pyinsight/`
* Use `pytest` to test each component
* Package using `pyproject.toml`
* Run as CLI tool locally
* Integrate CI/CD to ensure production readiness

---

# 📂 Appendix: Complete PyInsight Source Code

### Project Structure

```
pyinsight/
├── pyinsight/
│   ├── __init__.py
│   ├── cli.py
│   ├── loader.py
│   ├── validator.py
│   ├── analysis.py
│   ├── reports.py
│   ├── decorators.py
│   ├── errors.py
│   └── logger.py
├── tests/
│   ├── test_analysis.py
│   ├── test_loader.py
│   └── test_validator.py
└── pyproject.toml
```

---

## 1️⃣ `pyinsight/__init__.py`

```python
# pyinsight/__init__.py
"""PyInsight: CSV Data Analysis CLI Tool"""
__version__ = "0.1.0"
```

---

## 2️⃣ `pyinsight/errors.py`

```python
class PyInsightError(Exception):
    """Base class for PyInsight exceptions."""

class DataError(PyInsightError):
    """Raised when CSV data is invalid."""

class ValidationError(PyInsightError):
    """Raised when validation fails."""
```

---

## 3️⃣ `pyinsight/logger.py`

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger("pyinsight")
```

---

## 4️⃣ `pyinsight/decorators.py`

```python
import time
from pyinsight.logger import logger
from functools import wraps

def timed(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        elapsed = time.time() - start
        logger.info("Function %s executed in %.4f seconds", func.__name__, elapsed)
        return result
    return wrapper

def require_nonempty(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        for arg in args:
            if arg is None or arg == []:
                raise ValueError(f"Empty argument passed to {func.__name__}")
        return func(*args, **kwargs)
    return wrapper
```

---

## 5️⃣ `pyinsight/loader.py`

```python
import csv
from pyinsight.errors import DataError
from pyinsight.logger import logger

def load_csv(path: str) -> list[dict]:
    try:
        with open(path, newline="", encoding="utf-8") as f:
            rows = list(csv.DictReader(f))
            logger.info("Loaded %d rows from %s", len(rows), path)
            return rows
    except FileNotFoundError:
        logger.error("File not found: %s", path)
        raise DataError(f"File not found: {path}")
    except Exception as e:
        logger.exception("Failed to load CSV")
        raise DataError(f"Failed to load CSV: {e}")
```

---

## 6️⃣ `pyinsight/validator.py`

```python
from pyinsight.errors import ValidationError

def validate_rows(rows: list[dict], required_columns: list[str]) -> None:
    for idx, row in enumerate(rows, start=1):
        for col in required_columns:
            if col not in row or row[col] == "":
                raise ValidationError(f"Missing '{col}' in row {idx}")
```

---

## 7️⃣ `pyinsight/analysis.py`

```python
from pyinsight.decorators import timed, require_nonempty
from pyinsight.logger import logger

@timed
@require_nonempty
def summarize(rows: list[dict], column: str) -> dict:
    values = [float(r[column]) for r in rows if r[column] != ""]
    count = len(values)
    avg = sum(values) / count if count else 0
    result = {"count": count, "avg": avg, "min": min(values, default=0), "max": max(values, default=0)}
    logger.info("Summary for column '%s': %s", column, result)
    return result
```

---

## 8️⃣ `pyinsight/reports.py`

```python
import json
from pyinsight.logger import logger

def report_terminal(summary: dict, column: str) -> None:
    print(f"Column: {column}")
    for k, v in summary.items():
        print(f"{k.capitalize()}: {v}")

def report_json(summary: dict, column: str, path: str) -> None:
    data = {column: summary}
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    logger.info("Report saved to %s", path)
```

---

## 9️⃣ `pyinsight/cli.py`

```python
import argparse
from pyinsight.loader import load_csv
from pyinsight.validator import validate_rows
from pyinsight.analysis import summarize
from pyinsight.reports import report_terminal, report_json

def main():
    parser = argparse.ArgumentParser(description="PyInsight CSV Analyzer")
    parser.add_argument("--file", required=True, help="CSV file path")
    parser.add_argument("--column", required=True, help="Column to summarize")
    parser.add_argument("--json", help="Optional JSON report path")
    args = parser.parse_args()

    rows = load_csv(args.file)
    validate_rows(rows, [args.column])
    summary = summarize(rows, args.column)
    report_terminal(summary, args.column)
    if args.json:
        report_json(summary, args.column, args.json)

if __name__ == "__main__":
    main()
```

---

## 1️⃣0️⃣ `pyproject.toml`

```toml
[project]
name = "pyinsight"
version = "0.1.0"
dependencies = ["typer", "pytest"]

[project.scripts]
pyinsight = "pyinsight.cli:main"
```

---

## 1️⃣1️⃣ Sample Unit Test — `tests/test_analysis.py`

```python
from pyinsight.analysis import summarize

def test_summarize():
    rows = [{"score": "10"}, {"score": "20"}, {"score": "30"}]
    result = summarize(rows, "score")
    assert result["count"] == 3
    assert result["avg"] == 20
    assert result["min"] == 10
    assert result["max"] == 30
```

---

### ✅ Features Implemented

* **CLI Tool** (`argparse`)
* **CSV Loading & Validation**
* **Functional & OOP Principles** (pure functions, decorators)
* **Logging & Observability**
* **Reporting** (Terminal + JSON)
* **Custom Exceptions**
* **Unit Testing** with `pytest`
* **Installable Package** via `pyproject.toml`

---

This **complete PyInsight project** is ready to run:

```bash
# Run CLI directly
python -m pyinsight.cli --file data.csv --column score

# Run and save JSON report
python -m pyinsight.cli --file data.csv --column score --json report.json

# Run tests
pytest tests/
```

---

