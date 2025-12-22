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

---
PyInsight is a **production-grade CSV analysis and rule-based pipeline tool**. Its architecture makes it suitable for **data-heavy, operational, or analytics workflows**, especially where **automation, async processing, and plugin extensibility** are needed. Here’s a practical breakdown:

---

## 1️⃣ **Data Analysis & Reporting**

* **Quick CSV analytics:** Summarize, validate, and report on CSV datasets.
* **Automated reporting pipelines:** Generate terminal reports, JSON, CSV, or Excel outputs for dashboards.
* **Examples:**

  * Sales CSV → average sales, min/max, flagged anomalies.
  * Sensor data → daily metrics summary.

---

## 2️⃣ **Rule-Based Monitoring**

* **Custom rules engine:** Evaluate datasets against declarative rules (`rules.yaml`).
* **Alerts & flags:** Automatically detect thresholds, anomalies, or policy violations.
* **Examples:**

  * Finance: Flag transactions above a threshold.
  * HR: Identify employees with missing critical data.
  * IoT: Trigger warnings for out-of-range sensor readings.

---

## 3️⃣ **Plugin-Driven Extensibility**

* **Custom analytics plugins:** Users can write domain-specific analysis modules.
* **Parallel execution:** Plugins run asynchronously to extend core capabilities without blocking pipelines.
* **Examples:**

  * Technical indicators in stock data (RSI, volatility).
  * Data enrichment from APIs (geolocation, weather, currency rates).
  * Machine learning inference pipelines.

---

## 4️⃣ **Asynchronous Processing & Streaming**

* **Large dataset handling:** Async CSV loading and async computations reduce blocking for big files.
* **Streaming / API integrations:** Can adapt to streaming data from web APIs or IoT feeds.
* **Examples:**

  * Processing millions of rows in batches without blocking.
  * Live analytics of telemetry or financial feeds.

---

## 5️⃣ **Observability & Metrics**

* Integrated **OpenTelemetry metrics, logs, and traces**.
* **Operational monitoring:** Track rows processed, plugin execution times, and rule evaluations.
* **Example:** Monitor pipeline health and performance in production dashboards.

---

## 6️⃣ **Secure & Configurable**

* Secrets management via environment variables or Vault/KMS.
* Flexible configuration (`pyinsight.toml`) for data source paths, report formats, and analysis defaults.
* Ensures pipelines **don’t leak credentials** and can adapt to different environments.

---

## 7️⃣ **Deployment & Automation**

* **Dockerized:** Ready for containerized deployment.
* **Kubernetes-friendly:** Can run batch jobs, cron jobs, or scheduled analytics.
* **CI/CD pipelines:** Easy to integrate into existing DevOps workflows.
* **Example:** Nightly batch analytics on operational CSV datasets.

---

### ✅ **Real-World Use Cases**

1. **Finance / Trading Analytics:** Automatically compute indicators, flag high/low values, generate reports for traders.
2. **Operations & Logistics:** Daily validation and summary of shipment or inventory CSVs.
3. **IoT & Sensor Data:** Async ingestion and summarization, detect anomalies, plug in ML models.
4. **HR & Compliance:** Validate employee records, detect missing or abnormal values, flag compliance issues.
5. **Data Engineering / Pipelines:** Build modular ETL steps that can integrate plugins, rules, and metrics into production pipelines.

---

In short, **PyInsight is like a modular, production-grade “CSV + Rule + Plugin” automation engine**, designed for **analytics, validation, monitoring, and reporting workflows** in real-world business or operational settings.

---

# 🗺️ PyInsight — Practical Applications Map

```
                         ┌───────────────────────────┐
                         │        PyInsight          │
                         │  CSV + Rules + Plugins    │
                         │  Async, Metrics, Secure   │
                         └───────────┬──────────────┘
                                     │
       ┌─────────────────────────────┼─────────────────────────────┐
       ▼                             ▼                             ▼
┌───────────────┐             ┌───────────────┐             ┌───────────────┐
│ Finance &     │             │ Operations &   │             │ IoT & Sensor  │
│ Trading       │             │ Logistics      │             │ Data          │
└───────────────┘             └───────────────┘             └───────────────┘
│ - Compute RSI / Moving Avg    │ - Validate shipments          │ - Stream sensor data
│ - Flag high/low transactions │ - Summarize inventory        │ - Detect anomalies
│ - Auto reporting              │ - Detect delays / issues     │ - Async aggregation
│ - Plugin analytics (ML/AI)   │ - Daily / batch reports      │ - Plugin ML models
│ - Rule engine alerts          │ - Rules: thresholds, flags  │ - Alerts & notifications
└───────────────────────────────┴─────────────────────────────┴─────────────────┘
       │                             │                             │
       ▼                             ▼                             ▼
┌───────────────┐             ┌───────────────┐             ┌───────────────┐
│ HR & Compliance│             │ Data Engineering│           │ DevOps &      │
│ & Payroll      │             │ Pipelines       │           │ Automation    │
└───────────────┘             └───────────────┘             └───────────────┘
│ - Validate employee records   │ - ETL steps & CSV ingestion │ - Batch jobs (K8s)
│ - Detect missing / abnormal   │ - Async processing          │ - Automated reports
│   values                      │ - Plugin enrichment (API,  │ - Metrics / logs / alerts
│ - Compliance & policy checks  │   ML models)               │ - Secrets / config injection
│ - Rule engine checks           │ - Rule-based validations   │ - Cron / scheduled pipelines
└───────────────────────────────┴─────────────────────────────┴─────────────────┘
                                     │
                                     ▼
                           ┌───────────────────────┐
                           │ Unified Output Layer  │
                           │ - Terminal Reports    │
                           │ - JSON / CSV / Excel  │
                           │ - Alerts / Flags      │
                           └───────────────────────┘
```

---

### 🔑 Map Explanation

1. **Central Engine:**
   PyInsight handles **CSV ingestion, validation, summarization, async processing, and plugin execution**.

2. **Industry Applications:**

   * **Finance/Trading:** Automated metrics, technical indicators, alerting.
   * **Operations & Logistics:** Daily batch reports, anomaly detection, shipment/inventory validation.
   * **IoT & Sensor Data:** Streaming data pipelines, async summarization, anomaly detection.
   * **HR & Compliance:** Employee data validation, missing data detection, policy compliance checks.
   * **Data Engineering Pipelines:** ETL automation, async enrichment, plugin-driven data processing.
   * **DevOps & Automation:** Containerized jobs, metrics collection, secrets injection, scheduled pipelines.

3. **Unified Output:**
   All pipelines merge results into a **consistent output**, including terminal summaries, JSON/CSV files, alerts, and flags.

---

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
# **NOTE**

> **🧠 What Does `python -m` Mean?**

When you run:

```bash
python -m pyinsight.analysis
```

you are telling Python:

> **“Run this module as a script, using Python’s module system.”**

This is very different from running a file directly.

---

## 🔍 Two Ways to Run Python Code

### ❌ Running a File Directly

```bash
python pyinsight/analysis.py
```

**What happens:**

* Python treats `analysis.py` as a standalone script
* The directory structure is ignored
* Imports can break
* Relative imports may fail

Example problem:

```python
# analysis.py
from pyinsight.decorators import timed
```

❌ This may fail if Python doesn’t know where `pyinsight` lives.

---

### ✅ Running a Module (`python -m`)

```bash
python -m pyinsight.analysis
```

**What happens:**

* Python searches for `pyinsight` on `PYTHONPATH`
* Loads it as a **package**
* Executes `analysis.py` **inside its package context**
* Imports work correctly and predictably

---

## 📦 What Is a “Module” vs a “Package”?

| Term    | Meaning                                        |
| ------- | ---------------------------------------------- |
| Module  | A single `.py` file                            |
| Package | A directory containing modules + `__init__.py` |

Example:

```
pyinsight/          ← package
├── __init__.py
├── analysis.py    ← module
├── loader.py
└── cli.py
```

So:

```bash
python -m pyinsight.analysis
```

means:

> Run the **analysis module inside the pyinsight package**

---

## 🔑 Why `-m` Matters (Especially for Real Projects)

### 1️⃣ Correct Import Resolution

Using `-m` ensures imports work **as designed**:

```python
from pyinsight.decorators import timed
```

This works because Python knows:

```
pyinsight → package root
analysis → module inside package
```

---

### 2️⃣ Enables Relative Imports

Inside a package, you can safely use:

```python
from .decorators import timed
```

This **only works** when executed as a module.

---

### 3️⃣ Consistent Behavior in Development & Production

| Environment       | Works with `python -m` | Works with `python file.py` |
| ----------------- | ---------------------- | --------------------------- |
| Local dev         | ✅                      | ❌ sometimes                 |
| Tests             | ✅                      | ❌                           |
| CI/CD             | ✅                      | ❌                           |
| Installed package | ✅                      | ❌                           |

---

## 🔄 What About `__name__ == "__main__"`?

When you run:

```bash
python -m pyinsight.analysis
```

Python sets:

```python
__name__ = "__main__"
```

**inside `analysis.py`**

This means:

```python
if __name__ == "__main__":
    main()
```

✅ **executes normally**

But when imported:

```python
from pyinsight import analysis
```

Then:

```python
__name__ = "pyinsight.analysis"
```

❌ `main()` does NOT run

➡️ This is how Python supports **reusable modules + executable scripts**

---

## 🧩 How This Applies to PyInsight

### Development

```bash
python -m pyinsight.cli --file data.csv --column score
```

✔ Correct imports
✔ Package-aware execution
✔ Matches production behavior

---

### Installed CLI (via `pyproject.toml`)

```bash
pyinsight --file data.csv --column score
```

Behind the scenes, Python still uses **module execution**, not file execution.

---

## 🧠 Mental Model (Text Diagram)

```
python -m pyinsight.analysis
        │
        ▼
Locate package "pyinsight"
        │
        ▼
Load module "analysis"
        │
        ▼
Set __name__ = "__main__"
        │
        ▼
Execute module code
```

---

## ✅ When Should You Use `python -m`?

**Always use `python -m` when:**

✔ Running code inside a package
✔ Building reusable applications
✔ Writing libraries or CLIs
✔ Preparing for packaging & distribution

**Avoid running `.py` files directly** once your project has structure.

---

## 🏁 Takeaway

> `python -m` is the bridge between **scripts** and **systems**.

It ensures:

✔ Correct imports
✔ Predictable execution
✔ Production-ready behavior

In short:

**Scripts use `python file.py`**
**Applications use `python -m package.module`**

---

# 🧱 PHASE 1️⃣1️⃣ — CLI Tools

## From Script to Executable Interface

> A **Command-Line Interface (CLI)** is not a convenience feature.
> It is the **public API** of your application.

If the CLI is unclear, inconsistent, or unpredictable, the entire system feels fragile — regardless of how good the internal code is.

In **PyInsight**, the CLI is the **Ingress Layer** of the system.

---

## 🧠 What the CLI Is Responsible For

The CLI must **never** contain business logic.
Its role is orchestration and control.

**Responsibilities:**

✔ Capture user intent
✔ Validate input early
✔ Route execution to core logic
✔ Produce deterministic output
✔ Exit with machine-readable status codes

Everything else belongs elsewhere.

---

## 🧩 CLI as a System Boundary

```
User / Automation
        │
        ▼
CLI (Ingress Layer)
        │
        ├─ Argument parsing
        ├─ Validation
        ├─ Error mapping
        └─ Command routing
        │
        ▼
Core Application Logic
```

This boundary is what allows PyInsight to scale from:

* ad-hoc scripts
* to CI pipelines
* to production batch jobs
* to packaged executables

---

## 🎯 Why CLIs Matter in Real Systems

A well-designed CLI makes PyInsight:

✔ **Automatable** — cron, CI/CD, schedulers
✔ **Scriptable** — bash, PowerShell, Makefiles
✔ **Deployable** — containers, servers, batch nodes
✔ **Composable** — pipes, redirection, chaining
✔ **Stable** — backward-compatible interfaces

> A good CLI is usable by **humans and machines** equally well.

---

## 🧠 The CLI Execution Model

Every professional CLI follows the same high-level flow:

```
Command Invocation
        │
        ▼
Argument Parsing
        │
        ▼
Validation
        │
        ▼
Dispatch to Core Logic
        │
        ▼
Output + Exit Code
```

This phase teaches you how to implement that model cleanly in Python.

---

# Option 1️⃣ — `argparse`

## Explicit Control, Standard Library

`argparse` is built into Python and exposes how CLIs *actually work*.

It is verbose by design — which makes it ideal for learning and low-level control.

---

### 📄 `pyinsight/cli.py`

```python
import argparse
from pyinsight.loader import load_csv
from pyinsight.analysis import summarize

def main():
    parser = argparse.ArgumentParser(
        description="PyInsight — CSV Analytics Tool"
    )

    parser.add_argument(
        "--file",
        required=True,
        help="Path to CSV file"
    )

    parser.add_argument(
        "--column",
        required=True,
        help="Column to analyze"
    )

    args = parser.parse_args()

    rows = load_csv(args.file)
    result = summarize(rows, args.column)

    print(result)

if __name__ == "__main__":
    main()
```

---

### ▶ Run as a Module

```bash
python -m pyinsight.cli --file data.csv --column score
```

Running with `-m` ensures:

* Correct import resolution
* Package-aware execution
* No reliance on relative paths

---

### ✅ Concepts Introduced

* Arguments as **contracts**
* Automatic `--help` generation
* Early failure on invalid input
* Strict separation of CLI and logic

---

## When to Use `argparse`

✔ You want zero dependencies
✔ You need full manual control
✔ You want to understand CLI internals

For real applications, however, verbosity becomes friction.

---

# Option 2️⃣ — `typer`

## Modern, Typed, Production-Ready

`typer` builds on `click` and Python type hints to produce **clean, declarative CLIs**.

> Think of Typer as **FastAPI for the command line**.

---

### 📄 `pyinsight/cli.py` (Typer-based)

```python
import typer
from pyinsight.loader import load_csv
from pyinsight.analysis import summarize

app = typer.Typer(
    help="PyInsight — CSV Analytics Tool"
)

@app.command()
def analyze(
    file: str = typer.Argument(..., help="Path to CSV file"),
    column: str = typer.Argument(..., help="Column to analyze"),
):
    rows = load_csv(file)
    result = summarize(rows, column)
    typer.echo(result)

def main():
    app()

if __name__ == "__main__":
    main()
```

---

### ▶ Run It

```bash
python -m pyinsight.cli analyze data.csv score
```

---

### 🧠 What Typer Gives You for Free

✔ Type-based validation
✔ Automatic conversion
✔ Nested subcommands
✔ Rich help output
✔ Shell auto-completion
✔ Minimal boilerplate

This dramatically reduces error surface and maintenance cost.

---

## 🆚 argparse vs Typer

| Dimension        | argparse            | Typer           |
| ---------------- | ------------------- | --------------- |
| Standard library | ✅                   | ❌               |
| Type awareness   | ❌                   | ✅               |
| Subcommands      | Manual              | Native          |
| Readability      | Verbose             | Declarative     |
| Best use case    | Learning, low-level | Production CLIs |

**Guideline:**

* Learn with `argparse`
* Ship with `typer`

---

# 🧩 Scaling the CLI: Subcommands

Real tools do not expose one action — they expose **capabilities**.

```
pyinsight analyze
pyinsight validate
pyinsight report
```

---

### 📄 Subcommand Structure

```python
app = typer.Typer()

@app.command()
def analyze(...):
    ...

@app.command()
def validate(...):
    ...

@app.command()
def report(...):
    ...
```

This creates a **command router**, not a script.

---

## 🧠 Subcommands as Contracts

Each subcommand:

* Has a clear responsibility
* Can evolve independently
* Can be tested in isolation
* Is discoverable via `--help`

This is how CLIs remain stable over years.

---

# 🧪 Testing the CLI (Non-Negotiable)

CLIs are **interfaces**, and interfaces must be tested.

---

### 📄 `tests/test_cli.py`

```python
from typer.testing import CliRunner
from pyinsight.cli import app

runner = CliRunner()

def test_analyze_command():
    result = runner.invoke(app, ["analyze", "data.csv", "score"])
    assert result.exit_code == 0
```

---

### Why This Matters

✔ Prevents breaking changes
✔ Enables CI/CD automation
✔ Documents expected behavior
✔ Treats the CLI as a public API

---

# 📦 Turning the CLI into an Executable

## Entry Point Registration

### 📄 `pyproject.toml`

```toml
[project.scripts]
pyinsight = "pyinsight.cli:main"
```

After installation:

```bash
pyinsight analyze data.csv score
```

No `python`, no module paths — **this is a real command**.

---

## 🧠 Why Entry Points Matter

They:

* Hide implementation details
* Provide stable invocation
* Enable packaging and distribution
* Are required for binaries

---

# 🧠 Professional Takeaway

> A CLI is an API for humans and machines.

By the end of this phase, PyInsight’s CLI:

✔ Is explicit and predictable
✔ Separates interface from logic
✔ Supports automation and scripting
✔ Scales via subcommands
✔ Is testable and stable
✔ Can be packaged as an executable

This is the **inflection point** where PyInsight stops being a Python script and becomes **software**.

---

### ✅ Phase Outcome

Readers now know how to:

✔ Design clean CLI boundaries
✔ Parse and validate arguments
✔ Implement subcommands
✔ Test CLI behavior
✔ Expose a real executable

---

Moving forward, we can build on this foundation to add:

➡ Exit codes and error mapping
➡ Shell auto-completion
➡ Single-file binaries (PyInstaller)
➡ Configuration and environment management

> **Syntax got you started.
> Engineering lets you ship.**

---

# 🧱 PHASE 1️⃣2️⃣ — Configuration & Environment Management

> Hard-coded values do not scale.
> Configuration is how software adapts **without code changes**.

---

## 🎯 Goals of This Phase

By the end of this phase, PyInsight will:

✔ Support configuration files
✔ Support environment variables
✔ Have sane defaults
✔ Be production-safe
✔ Work identically in local, CI, and production

---

## 1️⃣ Configuration Strategy (Industry Standard)

We use **three layers**, evaluated in this order:

```
CLI Arguments (highest priority)
        ↓
Environment Variables
        ↓
Config File
        ↓
Defaults (lowest priority)
```

This mirrors how tools like **Docker**, **AWS CLI**, and **Kubernetes** work.

---

## 2️⃣ Adding a Config File (`pyinsight.toml`)

### 📄 Example `pyinsight.toml`

```toml
[logging]
level = "INFO"

[analysis]
default_column = "score"
precision = 2

[output]
format = "json"
```

---

## 3️⃣ Loading Configuration Safely

### 📄 `pyinsight/config.py`

```python
import os
import tomllib

DEFAULT_CONFIG = {
    "logging": {"level": "INFO"},
    "analysis": {"precision": 2},
    "output": {"format": "terminal"},
}

def load_config(path: str | None = None) -> dict:
    config = DEFAULT_CONFIG.copy()

    if path and os.path.exists(path):
        with open(path, "rb") as f:
            file_config = tomllib.load(f)
            merge(config, file_config)

    return config

def merge(base: dict, override: dict):
    for k, v in override.items():
        if isinstance(v, dict):
            merge(base.setdefault(k, {}), v)
        else:
            base[k] = v
```

---

## 4️⃣ Environment Variable Overrides

### Example

```bash
export PYINSIGHT_LOG_LEVEL=DEBUG
```

### 📄 `pyinsight/config.py` (extend)

```python
def apply_env_overrides(config: dict):
    if level := os.getenv("PYINSIGHT_LOG_LEVEL"):
        config["logging"]["level"] = level
```

---

## 5️⃣ Wiring Config Into CLI

```python
@app.callback()
def main(
    config: str = typer.Option(None, help="Path to config file"),
):
    cfg = load_config(config)
    apply_env_overrides(cfg)
```

✔ CLI is flexible
✔ No code changes required to reconfigure
✔ Safe defaults always exist

---

## 🧠 Takeaway

> Configuration is a **contract**, not a hack.

---

# 🧱 PHASE 1️⃣3️⃣ — Output Formats & UX Polishing

> Professional tools don’t just compute — they **communicate clearly**.

---

## 1️⃣ Output Modes

PyInsight supports:

✔ Terminal (human-readable)
✔ JSON (machine-readable)
✔ CSV (pipeline-friendly)

---

## 2️⃣ Output Formatter Design

### 📄 `pyinsight/output.py`

```python
import json
import csv
import sys

def output_terminal(data: dict):
    for k, v in data.items():
        print(f"{k}: {v}")

def output_json(data: dict):
    print(json.dumps(data, indent=2))

def output_csv(data: dict):
    writer = csv.writer(sys.stdout)
    writer.writerow(data.keys())
    writer.writerow(data.values())
```

---

## 3️⃣ CLI Option: `--format`

```python
@app.command()
def analyze(
    file: str,
    column: str,
    format: str = typer.Option("terminal"),
):
    rows = load_csv(file)
    result = summarize(rows, column)

    match format:
        case "json":
            output_json(result)
        case "csv":
            output_csv(result)
        case _:
            output_terminal(result)
```

---

## 🧠 Takeaway

> CLI output is an **API surface**.

---

# 🧱 PHASE 1️⃣4️⃣ — Plugin Architecture (Extensibility)

> You don’t scale systems by modifying core code.
> You scale systems by **extending them**.

---

## 1️⃣ Plugin Contract

```python
class Plugin:
    name: str

    def run(self, rows: list[dict]) -> dict:
        raise NotImplementedError
```

---

## 2️⃣ Built-In Plugin Example

```python
class AveragePlugin(Plugin):
    name = "average"

    def run(self, rows):
        values = [float(r["score"]) for r in rows]
        return {"avg": sum(values)/len(values)}
```

---

## 3️⃣ Plugin Loader

```python
def load_plugins():
    return {
        "average": AveragePlugin(),
    }
```

---

## 4️⃣ CLI Integration

```bash
pyinsight analyze data.csv --plugin average
```

---

## 🧠 Takeaway

> Plugin systems turn tools into **platforms**.

---

# 🧱 PHASE 1️⃣5️⃣ — CI/CD (End-to-End Automation)

> If it isn’t automated, it’s broken.

---

## 1️⃣ CI Goals

✔ Lint
✔ Test
✔ Build
✔ Package
✔ Fail fast

---

## 2️⃣ GitHub Actions Pipeline

### 📄 `.github/workflows/ci.yml`

```yaml
name: CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: "3.12"
      - run: pip install -e .[dev]
      - run: pytest
      - run: python -m build
```

---

## 3️⃣ Release Automation (Optional)

```yaml
- run: pyinstaller --onefile pyinsight/cli.py
```

---

## 🧠 Takeaway

> CI/CD is **part of the codebase**, not infrastructure.

---

# 🧱 PHASE 1️⃣6️⃣ — Distribution Strategies

You now have **three ways to ship PyInsight**:

---

### 1️⃣ Python Package

```bash
pip install pyinsight
```

✔ Developers
✔ CI systems

---

### 2️⃣ Single Binary (PyInstaller)

```bash
./pyinsight analyze data.csv score
```

✔ End users
✔ Air-gapped systems

---

### 3️⃣ Docker (Optional)

```dockerfile
FROM python:3.12-slim
COPY . /app
RUN pip install .
ENTRYPOINT ["pyinsight"]
```

✔ Cloud
✔ Kubernetes

---

# 🏁 FINAL STATE — PyInsight Is Now Real Software

```
User
 │
 ▼
CLI (subcommands + completion)
 │
 ▼
Config → Validation → Analysis
 │
 ▼
Logging → Metrics → Traces
 │
 ▼
Output Formats
 │
 ▼
Binary / Package / Container
```

---

# 🎓 What Readers Have Truly Learned

✔ Python execution model
✔ Data modeling
✔ Functional & OOP design
✔ Error handling & testing
✔ CLI engineering
✔ Observability
✔ Packaging & binaries
✔ CI/CD
✔ Scalable architecture

> **They didn’t learn Python syntax.
> They learned Python engineering.**

---

# 🧱 PHASE 1️⃣2️⃣ — Production Packaging

## From Source Code to Installable Software

> Packaging is the moment your code becomes **a product**.
>
> If your application cannot be installed, versioned, and reproduced reliably, it is not production-ready — no matter how good the logic is.

In this phase, PyInsight becomes:

✔ Installable
✔ Executable
✔ Versioned
✔ Reproducible
✔ Distributable

---

## 🧠 What “Production Packaging” Really Means

Production packaging solves **non-functional requirements**:

* How do users install the tool?
* How do machines run it?
* How do versions stay consistent?
* How do dependencies stay isolated?
* How do builds remain reproducible?

This phase answers all of those questions.

---

## 🧩 Packaging Mental Model

```
Source Code
     │
     ▼
pyproject.toml (Metadata + Dependencies)
     │
     ▼
Build Backend (PEP 517 / 518)
     │
     ▼
Wheel / Installable Package
     │
     ▼
Executable Entry Point
```

Everything starts with **`pyproject.toml`**.

---

## 📦 The Modern Python Packaging Standard

Python packaging today is defined by:

* **PEP 517 / 518** — build isolation
* **PEP 621** — project metadata in `pyproject.toml`

> `setup.py` is legacy.
> `pyproject.toml` is the future — and the present.

---

## 📄 `pyproject.toml` (Production-Ready)

```toml
[project]
name = "pyinsight"
version = "0.1.0"
description = "Production-grade CSV analytics CLI"
readme = "README.md"
requires-python = ">=3.9"
authors = [
  { name="PyInsight Team" }
]

dependencies = [
  "typer>=0.9",
]

[project.optional-dependencies]
dev = [
  "pytest",
  "black",
  "ruff",
]

[project.scripts]
pyinsight = "pyinsight.cli:main"
```

---

## 🧠 What Each Section Does

### `[project]`

Defines **who your software is**:

* `name` → install name (`pip install pyinsight`)
* `version` → semantic versioning
* `requires-python` → prevents incompatible installs
* `dependencies` → runtime requirements only

---

### Optional Dependencies

```bash
pip install .[dev]
```

Installs:

✔ testing tools
✔ linters
✔ formatters

Without polluting production environments.

---

## 🚀 Installing PyInsight

From the project root:

```bash
pip install .
```

What happens:

1. Dependencies are resolved
2. Package is installed
3. Entry point is registered

---

## ▶ Running the Installed CLI

```bash
pyinsight --help
```

```bash
pyinsight analyze data.csv score
```

There is **no reference to Python**, paths, or modules.

This is how real tools behave.

---

## 🧠 How Entry Points Work

```toml
[project.scripts]
pyinsight = "pyinsight.cli:main"
```

This tells Python:

```
When user types "pyinsight":
→ import pyinsight.cli
→ call main()
```

This mechanism works across:

✔ macOS
✔ Linux
✔ Windows

---

## 📁 Recommended Project Structure

```
pyinsight/
├── pyinsight/
│   ├── __init__.py
│   ├── cli.py
│   ├── loader.py
│   ├── analysis.py
│   ├── validator.py
│   ├── report.py
│   └── errors.py
│
├── tests/
│   └── test_analysis.py
│
├── pyproject.toml
├── README.md
└── .gitignore
```

> Clear structure reduces cognitive load and onboarding time.

---

## 🧪 Packaging Verification Checklist

Before shipping, always verify:

```bash
pip install .
pyinsight --help
pyinsight analyze data.csv score
pytest
```

If this works, your package is **deployable**.

---

## 🧠 Versioning Strategy (Semantic Versioning)

```
MAJOR.MINOR.PATCH
```

* `PATCH` → bug fixes
* `MINOR` → backward-compatible features
* `MAJOR` → breaking changes

Example:

```
0.1.0 → 0.1.1 → 0.2.0 → 1.0.0
```

This matters for CI/CD and automation consumers.

---

## 🏗 Why Packaging Comes *Before* CI/CD

CI/CD automates **what already works**.

If packaging is broken:

❌ pipelines fail
❌ deployments break
❌ environments drift

Packaging correctness is the **foundation** for everything that follows.

---

## ✅ Phase Completion Outcomes

By the end of this phase, readers can:

✔ Create modern Python packages
✔ Define dependencies correctly
✔ Expose real executables
✔ Install tools with `pip`
✔ Prepare software for distribution

PyInsight is now:

> **Installable software, not just code.**

---

## 🧠 Professional Takeaway

> If your project does not install cleanly, it is not finished.

With production packaging in place, PyInsight is ready for:

➡ CI/CD pipelines
➡ Binary packaging (PyInstaller)
➡ Docker images
➡ Enterprise deployment

---

# 🧱 PHASE 1️⃣3️⃣ — CI/CD

## From Local Code to Reproducible Releases

> CI/CD is not about automation.
> It is about **trust**.
>
> Trust that every change is tested, every artifact is reproducible, and every release is intentional.

In this phase, PyInsight gains:

✔ Automated testing
✔ Consistent formatting and linting
✔ Deterministic builds
✔ Repeatable releases
✔ Machine-verifiable quality gates

---

## 🧠 What CI/CD Solves in Real Systems

Without CI/CD:

* Bugs slip into production
* “Works on my machine” becomes the norm
* Releases are manual, risky, and slow
* Confidence erodes with every change

With CI/CD:

* Every commit is validated
* Failures are caught early
* Releases are predictable
* Engineers refactor safely

---

## 🧩 CI/CD Mental Model

```
Code Commit
     │
     ▼
Continuous Integration (CI)
     │
     ├── Install dependencies
     ├── Lint & format
     ├── Run tests
     └── Build artifacts
     │
     ▼
Continuous Delivery / Deployment (CD)
     │
     ├── Version tagging
     ├── Publish package
     └── Ship binaries
```

CI answers: **“Is this change safe?”**
CD answers: **“Can this change be released?”**

---

## 🔧 Tooling Choices for PyInsight

| Concern      | Tool           | Reason                     |
| ------------ | -------------- | -------------------------- |
| CI Platform  | GitHub Actions | Ubiquitous, free, reliable |
| Test Runner  | pytest         | Fast, expressive           |
| Linting      | ruff           | Extremely fast, modern     |
| Formatting   | black          | Deterministic              |
| Build System | build          | PEP 517 compliant          |
| Packaging    | pyproject.toml | Modern standard            |

---

## 📄 GitHub Actions Workflow

### `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install .[dev] build

      - name: Lint
        run: ruff pyinsight

      - name: Format check
        run: black --check pyinsight

      - name: Run tests
        run: pytest

      - name: Build package
        run: python -m build
```

---

## 🧠 What Each Step Guarantees

### 1️⃣ Checkout

Ensures the workflow runs against **exact commit state**.

---

### 2️⃣ Python Setup

Locks runtime consistency:

✔ Same interpreter
✔ Same behavior
✔ Same results

---

### 3️⃣ Dependency Installation

```bash
pip install .[dev] build
```

Ensures:

* Runtime deps are installable
* Dev tools work
* `pyproject.toml` is correct

---

### 4️⃣ Linting (`ruff`)

Prevents:

❌ unused imports
❌ shadowed variables
❌ subtle bugs

Fast enough to run on every commit.

---

### 5️⃣ Formatting (`black`)

Enforces:

✔ consistent style
✔ zero bike-shedding
✔ clean diffs

---

### 6️⃣ Tests (`pytest`)

Tests are the **non-negotiable gate**.

If tests fail:

```
❌ pipeline fails
❌ merge blocked
```

---

### 7️⃣ Build Artifact

```bash
python -m build
```

Validates:

✔ package metadata
✔ dependency resolution
✔ installability

Build failures are **release blockers**.

---

## 🚦 CI as a Quality Gate

A merge is allowed only if:

✔ Lint passes
✔ Format is correct
✔ Tests pass
✔ Build succeeds

This creates **engineering discipline**.

---

## 📦 Preparing for Continuous Delivery

Once CI is stable, CD becomes trivial.

### Example: Tag-Based Release

```
git tag v0.1.0
git push origin v0.1.0
```

CI can detect the tag and:

✔ build artifacts
✔ publish to PyPI
✔ attach binaries

---

## 🔐 Secrets & Security

Sensitive data (tokens, credentials):

* Stored in GitHub Secrets
* Never committed
* Injected at runtime

This is **non-negotiable** for production.

---

## 🧪 CI Testing Philosophy

| Test Type   | Runs In CI | Purpose             |
| ----------- | ---------- | ------------------- |
| Unit        | ✅ Always   | Protect behavior    |
| Integration | ⚠ Optional | Validate boundaries |
| E2E         | ❌ Rare     | Slow, brittle       |

Fast CI is **a competitive advantage**.

---

## 🧠 Professional Takeaway

> CI/CD is the enforcement mechanism for engineering standards.

Without CI/CD:

* Standards are suggestions

With CI/CD:

* Standards are law

---

## ✅ Phase Completion Outcomes

By the end of this phase, readers can:

✔ Build CI pipelines from scratch
✔ Enforce quality gates
✔ Detect regressions automatically
✔ Produce reproducible artifacts
✔ Prepare projects for automated release

PyInsight now has **institutional memory** encoded in automation.

---

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

# 📂 Appendix — PyInsight Production Ready Source Code & Architecture

> Complete, production-grade PyInsight project, including CLI, async pipelines, plugins, metrics, secrets, Docker/Kubernetes, and rule engines.

---

## 📁 Project Directory Structure

```
pyinsight/
├── pyinsight/                   # Core package
│   ├── __init__.py
│   ├── cli.py
│   ├── loader.py
│   ├── loader_async.py          # Async CSV loader
│   ├── validator.py
│   ├── analysis.py
│   ├── analysis_async.py        # Async analysis
│   ├── reports.py
│   ├── decorators.py
│   ├── errors.py
│   ├── logger.py
│   ├── config.py
│   ├── metrics.py
│   ├── secrets.py
│   └── plugins/
│       ├── __init__.py
│       └── base.py
├── pyinsight_plugins/           # User/company-specific plugins
│   ├── __init__.py
│   └── rsi.py
├── tests/                       # Unit tests
│   ├── test_analysis.py
│   ├── test_loader.py
│   └── test_validator.py
├── data/                        # Sample datasets
│   └── data.csv
├── pyproject.toml               # Packaging and dependencies
├── pyinsight.toml               # Runtime config
├── rules.yaml                   # Rule engine definitions
├── Dockerfile
└── k8s-job.yaml                 # Kubernetes batch job
```

---

## 1️⃣ Core Package: `pyinsight/`

### `__init__.py`

```python
"""
PyInsight — Production-Grade CSV Analysis CLI
"""
__version__ = "0.1.0"
```

### `errors.py`

```python
class PyInsightError(Exception):
    exit_code = 1

class DataError(PyInsightError):
    exit_code = 2

class ValidationError(PyInsightError):
    exit_code = 3
```

### `logger.py`

```python
import logging

def configure_logging(level=logging.INFO):
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )

logger = logging.getLogger("pyinsight")
```

### `decorators.py`

```python
import time
from functools import wraps
from pyinsight.logger import logger
from pyinsight.errors import ValidationError

def timed(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        logger.info("Function %s executed in %.4fs", func.__name__, elapsed)
        return result
    return wrapper

def require_nonempty(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        if not args or not args[0]:
            raise ValidationError(f"{func.__name__} received empty input")
        return func(*args, **kwargs)
    return wrapper
```

---

### `loader.py` — Synchronous CSV

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
        raise DataError(f"File not found: {path}")
    except Exception as exc:
        raise DataError(str(exc))
```

### `loader_async.py` — Async CSV

```python
import aiofiles, csv

async def load_csv_async(path: str) -> list[dict]:
    async with aiofiles.open(path, "r", encoding="utf-8") as f:
        content = await f.read()
        return list(csv.DictReader(content.splitlines()))
```

---

### `validator.py`

```python
from pyinsight.errors import ValidationError

def validate_rows(rows: list[dict], required_columns: list[str]) -> None:
    for idx, row in enumerate(rows, start=1):
        for col in required_columns:
            if col not in row or row[col] == "":
                raise ValidationError(f"Missing or empty '{col}' in row {idx}")
```

---

### `analysis.py`

```python
from pyinsight.decorators import timed, require_nonempty
from pyinsight.logger import logger

@timed
@require_nonempty
def summarize(rows: list[dict], column: str) -> dict:
    values = [float(r[column]) for r in rows if r[column] != ""]
    count = len(values)
    result = {
        "count": count,
        "avg": sum(values)/count if count else 0,
        "min": min(values) if values else 0,
        "max": max(values) if values else 0
    }
    logger.info("Summary for column '%s': %s", column, result)
    return result
```

### `analysis_async.py`

```python
import asyncio
from pyinsight.loader_async import load_csv_async
from pyinsight.analysis import summarize

async def analyze_async(path: str, column: str):
    rows = await load_csv_async(path)
    return summarize(rows, column)
```

---

### `reports.py`

```python
import json
from pyinsight.logger import logger

def report_terminal(summary: dict, column: str):
    print(f"\nSummary for column: {column}")
    print("-"*30)
    for k,v in summary.items():
        print(f"{k:<10}: {v}")

def report_json(summary: dict, column: str, path: str):
    with open(path, "w", encoding="utf-8") as f:
        json.dump({column: summary}, f, indent=2)
    logger.info("Report written to %s", path)
```

---

### `config.py`

```python
import tomllib
from pathlib import Path

def load_config(path: str | None):
    if not path: return {}
    p = Path(path)
    if not p.exists(): raise FileNotFoundError(f"Config not found: {path}")
    with p.open("rb") as f:
        return tomllib.load(f)
```

---

### `metrics.py`

```python
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider

metrics.set_meter_provider(MeterProvider())
meter = metrics.get_meter("pyinsight")
rows_processed = meter.create_counter("rows_processed", unit="rows")
```

---

### `secrets.py`

```python
import os

def get_secret(name: str, default=None):
    value = os.getenv(name, default)
    if value is None:
        raise RuntimeError(f"Missing secret: {name}")
    return value
```

---

### `plugins/base.py`

```python
from abc import ABC, abstractmethod

class Plugin(ABC):
    name: str
    @abstractmethod
    def analyze(self, rows: list[dict]) -> dict:
        ...
```

---

### `cli.py`

```python
import typer, asyncio
from pyinsight.loader import load_csv
from pyinsight.analysis import summarize
from pyinsight.validator import validate_rows
from pyinsight.reports import report_terminal, report_json
from pyinsight.errors import PyInsightError
from pyinsight.analysis_async import analyze_async
from pyinsight.logger import configure_logging

app = typer.Typer(help="PyInsight — CSV Analysis Tool")

@app.command()
def analyze(file: str, column: str, json_out: str | None = None):
    rows = load_csv(file)
    validate_rows(rows, [column])
    summary = summarize(rows, column)
    report_terminal(summary, column)
    if json_out: report_json(summary, column, json_out)

@app.command()
def analyze_async_cli(file: str, column: str):
    summary = asyncio.run(analyze_async(file, column))
    report_terminal(summary, column)

def main():
    configure_logging()
    try:
        app()
    except PyInsightError as e:
        typer.echo(f"Error: {e}", err=True)
        raise typer.Exit(code=e.exit_code)

if __name__=="__main__":
    main()
```

---

## 2️⃣ Plugin Example: `pyinsight_plugins/rsi.py`

```python
from pyinsight.plugins.base import Plugin

class RSICalculator(Plugin):
    name = "rsi"
    def analyze(self, rows):
        return {"rsi": 42}  # Placeholder for actual calculation
```

---

## 3️⃣ Test Example: `tests/test_analysis.py`

```python
from pyinsight.analysis import summarize

def test_summarize_basic():
    rows = [{"score": "10"}, {"score": "20"}, {"score": "30"}]
    result = summarize(rows, "score")
    assert result["count"] == 3
    assert result["avg"] == 20
    assert result["min"] == 10
    assert result["max"] == 30
```

---

## 4️⃣ Sample CSV: `data/data.csv`

```csv
name,score
Alice,95
Bob,82
Charlie,67
Diana,40
```

---

## 5️⃣ Configuration: `pyinsight.toml`

```toml
[logging]
level = "INFO"

[data]
delimiter = ","
encoding = "utf-8"

[analysis]
default_column = "score"

[report]
format = "json"
output = "report.json"
```

---

## 6️⃣ Rule Engine: `rules.yaml`

```yaml
rules:
  - name: high_score
    column: score
    condition: "value > 90"
    action: "flag"
  - name: low_score
    column: score
    condition: "value < 40"
    action: "warn"
```

---

## 7️⃣ Dockerfile

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY pyproject.toml .
RUN pip install .
COPY pyinsight pyinsight
ENTRYPOINT ["pyinsight"]
```

---

## 8️⃣ Kubernetes Job: `k8s-job.yaml`

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pyinsight-job
spec:
  template:
    spec:
      containers:
        - name: pyinsight
          image: pyinsight:latest
          args: ["analyze", "/data/data.csv", "score"]
      restartPolicy: Never
```

---

## 9️⃣ Pyproject.toml

```toml
[project]
name = "pyinsight"
version = "0.1.0"
description = "Production-grade CSV analysis CLI"
dependencies = ["typer", "opentelemetry-api", "opentelemetry-sdk"]

[project.optional-dependencies]
dev = ["pytest", "ruff", "black", "build"]

[project.scripts]
pyinsight = "pyinsight.cli:main"
```

---

# 🏗 Architecture Overview & Data Flow

```
CLI / Typer
   │
   ▼
Config Loader
   │
   ▼
Command Router / Orchestrator
   │
   ├─ Core Engine (loader, validator, analysis, reports)
   ├─ Async Pipeline (loader_async, analysis_async)
   ├─ Rule Engine (rules.yaml)
   └─ Plugin Orchestrator (pyinsight_plugins/*)
       │
       ▼
Aggregator / Result Merge
   │
   ▼
Output Layer (Terminal, JSON, CSV)
   │
   ▼
Observability (metrics, logs, traces)
   │
   ▼
Secrets / Config Management
   │
   ▼
Deployment (Docker / Kubernetes)
```

---

# 🕒 Async + Plugins + Rules Execution Timeline

```
Task         0ms       100ms       200ms       300ms       400ms       500ms
----------------------------------------------------------------------------
CSV Load     ██████████
Validation           █████
Async Load              ██████████████
Async Summarize                      ███████
Rule Eval      ████
Plugin RSI                    ██████
Plugin Volatility                  ██████
Aggregation                               ███
Output Layer                                     █
```

* **Async pipelines** run in parallel with plugins.
* **Aggregator merges results** after all async and plugin tasks finish.
* Observability metrics/logs are captured throughout.
* Secrets are injected dynamically where required.
