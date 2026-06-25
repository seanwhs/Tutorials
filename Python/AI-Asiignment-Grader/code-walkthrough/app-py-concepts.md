**✅ app.py Python Primer for Absolute Beginners**

### **Introduction: What is Python?**

Python is a simple, readable programming language. You write instructions in plain English-like text, and the computer follows them.

**Your very first program:**
```python
# This is a comment. Python ignores everything after #
print("Hello, app.py!")   # print() shows text on screen
```

**How to run it**:
1. Save the code in a file called `hello.py`
2. Open terminal/command prompt and type: `python hello.py`

---

### **Module 1: Imports, Modules & Project Structure**

**Explanation**:  
When your program grows, you don’t want everything in one giant file. **Imports** let you bring in code from other files (called modules). This keeps your code organized and reusable.

```python
# Import the whole library and give it a short nickname
import panel as pn        # Now we can type "pn" instead of "panel"
import json               # Built-in tool for reading JSON data

# Import only the functions you need from another file
from utils import extract_text_from_file, image_to_base64

# Clean multiline import (easier to read when there are many items)
from engine import (
    detect_subject,           # Function to guess the subject
    extract_grade,
    grade_image_with_markup,
    judge_assignment,
)
```

**Mini Demo You Can Run**:
```python
# Save this as helpers.py
def greet(name):              # Define a reusable function
    return f"Hello {name}!"   # f-string puts variable inside text

# Save this as main.py
from helpers import greet     # Import the function
print(greet("Alice"))         # Output: Hello Alice!
```

**In app.py**: The main file stays clean because all heavy work (grading, PDF creation, image drawing) is split into separate files.

---

### **Module 2: Panel Setup & Configuration**

**Explanation**:  
Panel is a library that turns Python code into interactive web pages. `pn.extension()` prepares the environment. Custom CSS changes how things look.

```python
import panel as pn

# This must run once at the very beginning
pn.extension(sizing_mode="stretch_width")   # Makes app adjust to screen size

# Add your own styling rules
pn.config.raw_css.append("""
    .app.py-paper-pane {                /* This is a CSS class name */
        background: white;
        border: 1px solid #ccc;
        padding: 30px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
""")
```

**Why triple quotes?** They let you write text that spans multiple lines.

---

### **Module 3: Variables, Strings & Basic UI Components**

**Explanation**:  
**Variables** are boxes that hold data. **Widgets** are the buttons, text boxes, and dropdowns users interact with.

```python
# Variables
student_name = "Alice"      # String (text)
score = 92                  # Integer (whole number)
is_image_file = True        # Boolean (True or False)

# Creating UI widgets with keyword arguments
import panel as pn
pn.extension()

name_input = pn.widgets.TextInput(
    placeholder="Enter student name here...",   # Hint text
    value="Alice",                              # Starting value
    width=350                                   # Width in pixels
)

grade_button = pn.widgets.Button(
    name="Grade Assignment", 
    button_type="primary"       # Makes button blue
)
```

**Keyword arguments** (`name=value`) are like settings you pass when creating something.

---

### **Module 4: Markdown & Displaying Content**

**Explanation**:  
`pn.pane.Markdown` converts text written in Markdown into nicely formatted output (headings, bold, lists, etc.).

```python
import panel as pn
pn.extension()

feedback = pn.pane.Markdown("""
### Feedback for Alice          # This creates a heading
Great job on your essay!

_This text is italic_          # Underscores make italics
**This text is bold**          # Double asterisks make bold
""")

# Change the content later
feedback.object = "### New Feedback\n✅ Assignment graded!"
```

**In app.py**: Used for status messages, feedback, and the app title.

---

### **Module 5: Lists & Building Text**

**Explanation**:  
A **list** is a collection of items. You can add to it and then combine everything into one big string.

```python
corrections = ["Fix spelling mistake", "Add conclusion paragraph"]

lines = ["**Grade: A**"]                    # Start with grade
lines.append("")                            # Empty line
lines += ["**Corrections:**"]               # Add a heading

for item in corrections:                    # Loop through list
    lines.append(f"- {item}")               # Add each item as bullet

final_text = "\n".join(lines)               # Join with new lines
print(final_text)
```

**Output**:
```
**Grade: A**

**Corrections:**
- Fix spelling mistake
- Add conclusion paragraph
```

---

### **Module 6: Layouts (Organizing the Screen)**

**Explanation**:  
`Column` stacks things vertically. `Row` puts them side by side. This is how the left (paper) and right (controls) panes are built.

```python
left_pane = pn.Column(
    pn.pane.Markdown("### 📄 Marked Assignment"),   # Title
    paper_preview,                                  # Image area
    width=570,                                      # Fixed width
    scroll=True                                     # Allow scrolling
)

right_pane = pn.Column(
    title,
    pn.layout.Divider(),      # Horizontal line
    pn.pane.Markdown("**Student**"),
    name_input,
    pn.Spacer(height=20),     # Empty space
    grade_button
)

app = pn.Row(left_pane, right_pane)   # Side-by-side layout
```

---

### **Module 7: Functions & Control Flow**

**Explanation**:  
Functions are reusable blocks of code. `if` statements make decisions.

```python
def check_input(student_name, uploaded_file):
    if not student_name.strip():           # .strip() removes spaces
        return "❌ Please enter a student name"
    
    if uploaded_file is None:
        return "❌ Please upload an assignment"
    
    return "✅ All inputs are good!"       # Early returns stop the function

print(check_input("Alice", "assignment.pdf"))
print(check_input("", None))
```

---

### **Module 8: File Handling Basics**

**Explanation**:  
Working with filenames and in-memory files (buffers).

```python
filename = "student_essay.pdf"

print(filename.lower())                    # "student_essay.pdf"
print(filename.endswith((".pdf", ".docx", ".png")))   # True

# Safely remove file extension
base_name = filename.rsplit('.', 1)[0]     # Splits from right, once
print(base_name)                           # "student_essay"

# Buffer example (used for images)
from io import BytesIO
buf = BytesIO()
# ... write image data to buf ...
buf.seek(0)           # Move back to the beginning of the "file"
image_data = buf.read()
```

---

### **Module 9: JSON – Working with Structured Data**

**Explanation**:  
AI models often return answers as JSON (a structured text format). We need to safely convert it into Python data.

```python
import json

# Fake response from AI
json_string = '{"grade": "A", "overall_feedback": "Excellent work!"}'

try:
    data = json.loads(json_string)          # Convert string to dictionary
    grade = data.get("grade", "N/A")        # Safe get with default
    feedback = data.get("overall_feedback", "")
    print(f"Grade: {grade}")
except json.JSONDecodeError:
    print("AI gave bad JSON. Using empty data.")
    data = {}
```

---

### **Module 10: Async Programming (Waiting for AI)**

**Explanation**:  
Some tasks (like asking an AI for feedback) take time. `async` and `await` let the app stay responsive while waiting.

```python
import asyncio

async def get_grade_from_ai(text):
    print("Sending to AI...") 
    await asyncio.sleep(2)          # Simulate waiting for AI response
    return "Grade: B+ with great explanation"

# In real app.py this is called with await
result = asyncio.run(get_grade_from_ai("Student essay text"))
print(result)
```

---

### **Module 11: Error Handling**

**Explanation**:  
When something goes wrong (bad file, AI timeout, etc.), we catch the error and show a helpful message instead of crashing.

```python
try:
    # Risky code goes here
    result = 10 / 0                    # This causes an error
except Exception:                      # Catch almost any problem
    import traceback
    error_message = traceback.format_exc()
    print("Something went wrong:")
    print(error_message)
```

**In app.py**: The error appears nicely in the feedback panel.

---

### **Module 12: Event Handling & Connecting Everything**

**Explanation**:  
`on_click` connects a button to a function so something happens when the user clicks.

```python
import panel as pn
pn.extension()

status = pn.pane.Markdown("Ready to grade")

async def grade_assignment(event):        # event contains click info
    status.object = "⏳ Grading in progress..."
    # ... all the other code (validation, AI calls, etc.) ...
    status.object = "✅ Grading complete!"

button = pn.widgets.Button(name="Grade Assignment")
button.on_click(grade_assignment)         # Link button to function

button.servable()   # Run with: panel serve file.py
```

---

**Congratulations!** You now understand all the core Python concepts used in the app.py app.

**Practice Project Idea**:  
Try building a very small version:
1. One text input + one button
2. Button click shows a Markdown message
3. Add a file uploader and print the filename

Would you like me to create **exercises with solutions** for each module, or a complete `mini_app.py.py` starter file for practice? Just say what you need next! 🚀
