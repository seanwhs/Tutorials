## 1. Imports and database file

```python
import os
import json

DB_FILE = "students.json"
```

### Why this block exists
This section prepares the basic tools for saving and loading student records. `os` checks whether the database file exists, and `json` reads and writes the data in a simple file-based format. `DB_FILE` stores the filename in one place so the rest of the module can use it consistently.

### Python concepts used
- `import` brings in standard library modules.
- A module-level constant like `DB_FILE` is written in uppercase by convention.
- JSON is used because it is easy to store and reload as plain text.

### Pattern analysis
This is a **flat-file persistence setup**. Instead of using a database server, the app stores history in a JSON file.

### What if
Rename `students.json` to something else and notice that all load/save functions would need to follow the new name.

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

### Why this block exists
This function reads the saved student history from disk. If the file does not exist, or if the file is damaged, the function returns an empty dictionary so the program can keep going safely.

### Python concepts used
- `os.path.exists(...)` checks whether a file exists.
- `with open(...)` is a context manager that safely opens and closes the file.
- `json.load(...)` reads JSON from a file object.
- `try/except` handles bad files or file access problems.
- `isinstance(data, dict)` checks that the loaded data has the expected shape.

### Pattern analysis
This is a **defensive load function**. It expects file corruption or missing data and falls back gracefully.

### What if
Put invalid JSON into `students.json` and see that the function returns `{}` instead of crashing.

***

## 3. Save database

```python
def save_db(db):
    """Writes the current state to the JSON file."""
    with open(DB_FILE, "w", encoding="utf-8") as f:
        json.dump(db, f, indent=2)
```

### Why this block exists
This writes the current in-memory student data back to disk. The file becomes the persistent record of grading history.

### Python concepts used
- `with open(..., "w")` opens the file for writing.
- `json.dump(...)` serializes a Python dictionary to JSON.
- `indent=2` makes the output human-readable.

### Pattern analysis
This is a **write-through persistence** step. Whenever the data changes, it gets saved back into the file.

### What if
Remove `indent=2` and observe how the file becomes harder to read, even though it still works.

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

### Why this block exists
This function adds a new grading result to a student’s history. If the student does not already exist in the database, it creates a new record first.

### Python concepts used
- Dictionary membership with `if student not in db`.
- Nested dictionary structure.
- List history storage.

### Pattern analysis
This is a **record-append pattern**. Each new result becomes part of a student’s historical log.

### What if
Pretend the student is new and compare that path to adding a record for an existing student.

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

### Why this block exists
This function looks up old grading records for one student. If there is no history, it returns a simple message instead of failing.

### Python concepts used
- Reusing `load_db()` to access current data.
- Membership testing with `if name not in db`.
- Returning a string as a fallback when no data exists.

### Pattern analysis
This is a **lookup helper** with a graceful no-data path.

### What if
Try looking up a name that has never been saved and see how the fallback message keeps the app simple.

## Big-picture reading of the module

This file is the persistence layer for Markly. It stores grading history in a plain JSON file instead of a real database, which keeps the project lightweight and easy to understand. That makes it a good learning choice for a small app, even if a larger production system would eventually need something more robust.

The main ideas here are:
- **File-based storage** for simplicity.
- **Graceful fallback behavior** when files are missing or invalid.
- **Student-centric records** organized by name.
- **Separate load, save, append, and lookup responsibilities**.

One useful next step would be to turn the placeholder comments in `add_record()` and `get_student_history()` into full implementations and walk through how the `students.json` structure grows over time.
