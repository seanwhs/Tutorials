**✅ Python Primer: `app.py` — Main App Controller**

This primer teaches **core Python concepts** using real code from the main `app.py` file in the Markly grading app. Each section explains the Python idea simply, shows the original code, gives a beginner-friendly mini demo you can try, and links it to how it works in the app.

---

## Module Deep Dive: `app.py`

This file is the **main controller** of Markly. It builds the interactive web interface and coordinates all the other parts (grading, image marking, PDF reports, etc.).

### 1. Panel imports and setup
```python
import panel as pn
import json
```

**Python Concept: Importing Modules**  
`import` brings in tools from other files or libraries. `as pn` gives a shorter nickname.

**Mini Demo You Can Try**:
```python
import panel as pn
import json

print("Panel and JSON imported successfully!")
```

**In app.py**: Loads the UI framework (`panel`) and the JSON tool needed later for AI responses.

---

### 2. Project module imports
```python
from utils import extract_text_from_file, image_to_base64
from engine import (
    detect_subject,
    extract_grade,
    grade_image_with_markup,
    judge_assignment,
)
```

**Python Concepts**:
- `from module import ...` — import only specific functions.
- Parentheses for **multiline imports** (makes long lists easier to read).
- **Modular design** — each file has one job.

**Mini Demo**:
```python
# helpers.py
def greet(name):
    return f"Hello {name}!"

# main.py
from helpers import greet
print(greet("Student"))
```

**In app.py**: Connects the interface to specialized modules instead of doing everything itself.

---

### 3. Panel extension
```python
pn.extension(sizing_mode="stretch_width")
```

**Python Concepts**:
- **Function call with keyword arguments** (`name=value`).
- Code that runs once at startup (initialization).

**Mini Demo**:
```python
import panel as pn
pn.extension(sizing_mode="stretch_width")  # Makes things resize nicely
```

**In app.py**: Prepares the web framework before building the interface.

---

### 4. Custom CSS styling
```python
pn.config.raw_css.append("""
...
""")
```

**Python Concepts**:
- **Triple-quoted multiline strings** — for long text.
- `.append(...)` — adds something to a list.

**Mini Demo**:
```python
styles = """
    .box { background: white; padding: 20px; }
"""
print(styles)
```

**In app.py**: Makes the app look professional using CSS.

---

### 5. Title pane
```python
title = pn.pane.Markdown(
    "## 🔴 Markly\n*AI-powered red-pen grading*",
    styles={"margin-bottom": "0"},
)
```

**Python Concepts**:
- **Object creation with keyword arguments**.
- `pn.pane.Markdown` renders formatted text.

**Mini Demo**:
```python
import panel as pn
pn.extension()
title = pn.pane.Markdown("## My App")
```

**In app.py**: Creates the heading shown to users.

---

### 6–7. Widgets and Preview Components
```python
student_name = pn.widgets.TextInput(...)
paper_preview = pn.pane.PNG(...)
paper_placeholder = pn.pane.Markdown(...)
```

**Python Concepts**:
- **Stateful objects** (widgets remember their values).
- `visible=True/False` — controls what is shown.
- Keyword arguments for configuration.

**Mini Demo**:
```python
name = pn.widgets.TextInput(value="Alice")
print(name.value)          # Read current value
name.visible = False       # Hide it
```

**In app.py**: Collects input and shows results.

---

### 8–10. Layouts
```python
left_pane = pn.Column(
    paper_heading,
    paper_placeholder,
    paper_preview,
    css_classes=["markly-paper-pane"],
    width=570,
    scroll=True,
)
```

**Python Concepts**:
- `pn.Column` and `pn.Row` — stack things vertically or horizontally.
- `css_classes=[...]` and keyword arguments for styling.

**Mini Demo**:
```python
layout = pn.Column(
    pn.pane.Markdown("Header"),
    pn.Spacer(height=20)
)
```

**In app.py**: Organizes the screen into left (paper) and right (controls) panes.

---

### 11. Grading callback: input validation
```python
async def grade_assignment(event):
    if upload.value is None or not student_name.value.strip():
        feedback.object = "..."
        return
```

**Python Concepts**:
- `async def` — function that can wait for slow tasks.
- `if ... return` — **guard clause** (early exit).
- `.strip()` — removes extra spaces.

**Mini Demo**:
```python
def check(name):
    if not name.strip():
        return "Missing name!"
    return "Good"
print(check("   "))
```

**In app.py**: Validates input before doing heavy work.

---

### 12. UI reset before processing
```python
paper_preview.visible = False
paper_heading.object = "### Processing…"
```

**Python Concepts**:
- Updating object properties (`.object`, `.visible`, `.disabled`).
- **Reactive UI** — changes happen live in the browser.

**Mini Demo**:
```python
status = pn.pane.Markdown("Ready")
status.object = "⏳ Working..."   # Updates the screen
```

---

### 13. File type detection
```python
filename = upload.filename.lower()
is_image = filename.endswith((".png", ".jpg", ".jpeg"))
```

**Python Concepts**:
- `.lower()` — makes text lowercase.
- `.endswith(tuple)` — checks multiple options at once.
- `if/else` branching.

**Mini Demo**:
```python
name = "report.PDF"
print(name.lower())
print(name.endswith((".pdf", ".docx")))
```

---

### 14–17. Subject detection, JSON parsing & data extraction
```python
predicted_subject = await detect_subject(content)
markup_data = json.loads(markup_json_str)
grade_val = markup_data.get("grade", "N/A")
```

**Python Concepts**:
- `await` — waiting for async results.
- `json.loads()` — convert text to Python dictionary.
- `.get(key, default)` — safe dictionary lookup.
- `try/except` — defensive error handling.

**Mini Demo**:
```python
import json
data = json.loads('{"grade": "A"}')
print(data.get("grade", "N/A"))
```

---

### 18–20. Rendering and PDF output
```python
marked_buf.seek(0)
paper_preview.object = marked_buf.read()
download.filename = f"marked_{name}.pdf"
```

**Python Concepts**:
- `seek(0)` and `read()` — working with file-like buffers.
- **f-strings** — modern way to build strings with variables.
- `rsplit('.', 1)` — safe string splitting.

**Mini Demo**:
```python
name = "essay.pdf"
clean = name.rsplit('.', 1)[0]
print(f"marked_{clean}.pdf")
```

---

### 21. Building readable result text
```python
lines = [f"**Grade: {grade_val}**"]
result = "\n".join(lines)
```

**Python Concepts**:
- Lists as temporary storage.
- `.join()` — combine list items into one string.
- `if` checks to avoid empty sections.

**Mini Demo**:
```python
lines = ["Hello", "World"]
print("\n".join(lines))
```

---

### 22–25. Branching, finalization & persistence
```python
else:
    result = await judge_assignment(...)
feedback.object = f"### Feedback\n{result}"
add_record(...)   # function call
```

**Python Concepts**:
- `if/else` branching for different paths.
- f-strings for dynamic text.
- Function calls to delegate work.

---

### 26. Error handling
```python
except Exception:
    import traceback
    feedback.object = f"### Error\n{traceback.format_exc()}"
```

**Python Concept: Error Handling**  
`try/except` catches problems gracefully.

**Mini Demo**:
```python
try:
    print(10 / 0)
except Exception:
    print("Something went wrong!")
```

---

### 27. Event binding and app serving
```python
grade_button.on_click(grade_assignment)
app = pn.Row(left_pane, right_pane)
app.servable()
```

**Python Concepts**:
- `.on_click(...)` — connect events to functions.
- `pn.Row(...)` — layout composition.
- `servable()` — make the app runnable in a browser.

---

## Big-Picture Python Concepts You Learned

- **Organizing code**: Imports, modules, constants, functions
- **Data structures**: Lists, Dictionaries, Strings
- **Control flow**: `if/else`, guard clauses, `try/except`
- **Functions**: `def`, `async def`, parameters, keyword arguments
- **String handling**: f-strings, `.join()`, `.strip()`, `.lower()`
- **UI reactivity**: Updating `.object`, `.visible`, etc.
- **Modular design**: Breaking big programs into small, focused pieces

These are fundamental skills used in real Python web applications.

---

**Practice Suggestions**:
1. Create a simple Panel app with one button and one text area.
2. Add `async def` that waits 1 second then updates the text.
3. Use a dictionary to choose different messages.

