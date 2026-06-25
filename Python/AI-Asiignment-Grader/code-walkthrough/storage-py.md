# ✅ **Direct rewrite following the example style**

# Python Primer: `persistence.py` — JSON Flat-File Database

This primer teaches core Python concepts using real code from a student record persistence module. Each section shows the original code, explains the Python idea simply, provides a short runnable mini-demo, and ties it back to the module.

***

## Module Deep Dive: `persistence.py`

This file is the **data layer**: it stores and retrieves student grading history using a simple JSON flat-file, keeping the project lightweight without requiring a database server.

***

## 1. Imports and database file

```python
import os
import json

DB_FILE = "students.json"
```

**Python Concept: Importing Standard Library Modules + Module-Level Constants**  
Imports bring in built-in tools. `os` handles filesystem checks, and `json` serializes Python objects to text. A module-level constant like `DB_FILE` is written in uppercase by convention, making it easy to change the filename in one place without hunting through the code.

**Mini Demo**:
```python
import os
import json

# Check if a file exists before reading
print(os.path.exists("some_file.txt"))  # False

# JSON converts Python dicts to strings and back
data = {"key": "value"}
json_str = json.dumps(data)
print(json.loads(json_str))  # {'key': 'value'}
```

**In `persistence.py`**: These imports and the constant set up the foundation for all file-based storage operations. Changing `DB_FILE` renames the database for the entire module.

***

## 2. Load database

```python
def load_db():
    """Reads the JSON flat-file database."""
    if not os.path.exists(DB_FILE):
        return {}
    try:
        with open(DB_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data if isinstance(data, dict) else {}
    except (json.JSONDecodeError, OSError):
        return {}
```

**Python Concept: Defensive Programming with `try/except` and Context Managers**  
The `with open(...)` context manager safely opens and closes the file, even if errors occur. `try/except` catches two specific problems: corrupted JSON (`JSONDecodeError`) and filesystem issues (`OSError`). `isinstance(data, dict)` validates that the loaded data has the expected shape before returning it.

**Mini Demo**:
```python
import os
import json
from io import StringIO

# Simulate corrupted JSON
bad_json = "{invalid"
try:
    json.loads(bad_json)
except json.JSONDecodeError:
    print("Caught bad JSON!")  # This prints

# isinstance checks object type
data = {"a": 1}
print(isinstance(data, dict))  # True
print(isinstance([], dict))    # False
```

**In `persistence.py`**: This is a **defensive load function**. It expects file corruption or missing data and falls back gracefully to an empty dictionary instead of crashing the application.

***

## 3. Save database

```python
def save_db(db):
    """Writes the current state to the JSON file."""
    with open(DB_FILE, "w", encoding="utf-8") as f:
        json.dump(db, f, indent=2)
```

**Python Concept: Writing Files with Context Managers + Pretty-Printing JSON**  
The `"w"` mode opens the file for writing, replacing any existing content. `json.dump()` serializes a Python dictionary directly to a file object. `indent=2` formats the output with line breaks and indentation, making it human-readable and easier to debug.

**Mini Demo**:
```python
import json
from io import StringIO

# Without indent: compact but hard to read
buf = StringIO()
json.dump({"a": 1, "b": 2}, buf)
print(buf.getvalue())  # {"a": 1, "b": 2}

# With indent: structured and readable
buf2 = StringIO()
json.dump({"a": 1, "b": 2}, buf2, indent=2)
print(buf2.getvalue())
# {
#   "a": 1,
#   "b": 2
# }
```

**In `persistence.py`**: This is a **write-through persistence** step. Whenever student data changes, it gets saved back to disk immediately, ensuring the JSON file always reflects the current in-memory state.

***

## 4. Add record

```python
def add_record(student, subject, grade, feedback):
    """Appends a new history entry for a student."""
    db = load_db()
    if student not in db:
        db[student] = {"history": []}
    # Append entry and save_db(db)... [25]
```

**Python Concept: Dictionary Membership Testing + Nested Data Structures**  
`if student not in db` checks for key existence without raising a `KeyError`. If the student is new, the code initializes a nested dictionary structure with a `"history"` list. This pattern separates the "create if missing" logic from the "append data" logic.

**Mini Demo**:
```python
db = {}

# Membership testing
print("Alice" not in db)  # True

# Initialize nested structure
student = "Alice"
if student not in db:
    db[student] = {"history": []}

# Now we can safely append
db[student]["history"].append({"grade": "A"})
print(db)  # {'Alice': {'history': [{'grade': 'A'}]}}
```

**In `persistence.py`**: This is a **record-append pattern**. Each new grading result becomes part of a student's historical log, organized under their name in the top-level dictionary.

***

## 5. Get student history

```python
def get_student_history(name):
    """Retrieves previous records for a specific student."""
    db = load_db()
    if name not in db:
        return "No previous records."
    # Return history logic... [26]
```

**Python Concept: Lookup with Graceful Fallbacks**  
Instead of letting a missing key raise an exception, the function returns a descriptive string. This keeps calling code simple—it never has to handle `None` or exceptions, just check for the string message.

**Mini Demo**:
```python
db = {"Alice": {"history": [{"grade": "A"}]}}

# Graceful fallback
def get_history(name):
    if name not in db:
        return "No previous records."
    return db[name]["history"]

print(get_history("Alice"))   # [{'grade': 'A'}]
print(get_history("Bob"))     # No previous records.
```

**In `persistence.py`**: This is a **lookup helper** with a graceful no-data path. It encapsulates the database access and provides a user-friendly response when no history exists.

***

## Big-picture reading of the module

This module is the **persistence layer** of the system. It stores grading history in a plain JSON file instead of a real database, which keeps the project lightweight and easy to understand—an excellent choice for learning, even if production systems would eventually need something more robust.

The main ideas are:
- **File-based storage** for simplicity and zero setup.
- **Graceful fallback behavior** when files are missing, corrupted, or invalid.
- **Student-centric records** organized by name with nested history lists.
- **Separate load, save, append, and lookup responsibilities** for clear code organization.

One useful next step would be to turn the placeholder comments in `add_record()` and `get_student_history()` into full implementations and walk through how the `students.json` structure grows over time.

***

## Practice suggestions

- Put invalid JSON into `students.json` and observe how `load_db()` returns `{}` instead of crashing.
- Rename `DB_FILE` to `"grades_backup.json"` and verify that all operations target the new file.
- Add a `delete_student(name)` function that uses `db.pop(name, None)` and calls `save_db()`.
- Compare this flat-file approach to using Python's `shelve` module for persistent dictionaries.

***

## References

- Python `json` module documentation for serialization patterns.
- Python `os.path` documentation for filesystem operations.
- Python context manager documentation for safe file handling.
