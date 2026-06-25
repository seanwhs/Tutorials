# **✅ Python Primer: `engine.py` — AI Orchestration & Grading Core**

This primer teaches **core Python concepts** using real code from `engine.py` in the Markly app. Each section explains the Python idea in simple terms, shows the original code, gives a beginner-friendly mini demo you can copy and run, and links it to the Markly grading system.

---

## Module Deep Dive: `engine.py`

This file is the **brain** of Markly. It shows how to organize real-world Python code for talking to AI, handling different subjects, and making reliable decisions.

### 1. Imports and Client Setup
```python
import os
import asyncio
import re
from dotenv import load_dotenv
from openai import AsyncOpenAI
```

**Python Concept: Importing Modules**  
`import` lets you bring in ready-made tools.  
- `import os`, `import asyncio`, `import re` → built-in Python tools.  
- `from ... import ...` → brings specific tools from other libraries.

**Mini Demo You Can Try**:
```python
import os
import asyncio

print(os.name)                    # Shows info about your system
print("All modules imported!")
```

**In Markly**: These imports prepare everything needed for AI communication and text processing.

---

### 2. Environment Loading and Shared Client
```python
load_dotenv()
API_KEY = os.getenv("OPENROUTER_API_KEY")
client = AsyncOpenAI(
    api_key=API_KEY,
    base_url="https://openrouter.ai/api/v1"
)
```

**Python Concepts**:
- **Variables**: Store information (`API_KEY = ...`).
- **Keyword arguments**: Pass settings by name (`api_key=...`).
- `os.getenv()`: Safely get secret values (returns default if missing).

**Mini Demo**:
```python
def create_ai_helper(key):
    print(f"Connected with key: {key}")

create_ai_helper("example-secret-key")   # Using keyword style
```

**In Markly**: Creates one reusable AI client shared across the whole file.

---

### 3. Prompt Templates
```python
SUBJECT_DETECTION_PROMPT = """... long text ..."""
```

**Python Concepts**:
- **Constants**: Variables written in `UPPER_CASE` that don’t change.
- **Triple-quoted multiline strings**: Great for long blocks of text.

**Mini Demo**:
```python
WELCOME_PROMPT = """Hello student!
Tell me about your assignment.
I will help grade it."""

print(WELCOME_PROMPT)
```

**In Markly**: Stores clear instructions for the AI in one easy-to-edit place.

---

### 4. Subject Prompt Mapping
```python
SUBJECT_PROMPTS = {
    "Mathematics": MATH_MARKING_PROMPT,
    "English": ENGLISH_MARKING_PROMPT,
}
```

**Python Concept: Dictionaries**  
Dictionaries store data as `key: value` pairs. Perfect for quick lookups.

**Mini Demo**:
```python
subject_prompts = {
    "Math": "Show your calculations",
    "English": "Check grammar and spelling"
}

chosen = subject_prompts.get("Math", "Default prompt")
print(chosen)
```

**In Markly**: Acts as a **dispatch table** — picks the right prompt without many `if` statements.

---

### 5. Vision Prompt & Model Pool
```python
VISION_PROMPT = """Analyze the assignment..."""

MODELS_POOL = [
    "openai/gpt-oss-20b:free",
    "qwen/qwen3-coder:free",
    "google/gemma-4-31b-it:free",
]
```

**Python Concepts**:
- **Lists**: Ordered groups of items inside `[]`.
- You can loop through them with `for`.

**Mini Demo**:
```python
models = ["fast-model", "smart-model", "reliable-model"]

for model in models:
    print("Trying model:", model)
```

**In Markly**: Lists of models and prompts for flexible AI usage.

---

### 6. Grade Extraction Helper
```python
def extract_grade(text: str) -> str:
    # Regex patterns for common grade formats
```

**Python Concepts**:
- **Defining Functions**: `def name(parameters):` — reusable code blocks.
- **Type hints**: `: str` and `-> str` (helpful notes, not required).
- `re` module: Pattern matching in text.

**Mini Demo**:
```python
import re

def extract_grade(text):
    match = re.search(r'(\d+/\d+|[A-F][+-]?)', text)
    return match.group(1) if match else "N/A"

print(extract_grade("Student received A- on the test"))
```

**In Markly**: Cleans up messy AI output into a usable grade.

---

### 7. Subject Detection Function
```python
async def detect_subject(content):
    # Uses a cheap/fast model...
```

**Python Concept: Async Functions**  
`async def` lets functions **wait** for slow tasks (like AI answers) without freezing everything.

**Mini Demo**:
```python
import asyncio

async def detect_subject(content):
    print("Detecting subject...")
    await asyncio.sleep(1)          # Simulate waiting for AI
    return "Mathematics"

# Run the async function
result = asyncio.run(detect_subject("2x + 3 = 7"))
print(result)
```

**In Markly**: Automatically figures out the subject of an assignment.

---

### 8. Single-Model Request Helper
```python
async def ask_ai(prompt, model_name, timeout=10.0):
    # Try/except wrapper around the API call
```

**Python Concepts**:
- **Default parameters**: `timeout=10.0` (optional value).
- **try / except**: Catch problems so the program doesn’t crash.

**Mini Demo**:
```python
try:
    result = 10 / 2
except Exception:
    result = "Something went wrong"
print(result)
```

**In Markly**: Safely talks to one AI model at a time.

---

### 9. Concurrent Model Racing
```python
async def get_ai_response_concurrently(prompt, timeout=10.0):
    # Launches all models in parallel...
```

**Python Concept: Concurrency with asyncio**  
Run several tasks at the same time and use the first good result.

**Key Ideas**:
- `asyncio.create_task()` starts background work.
- `asyncio.wait(..., FIRST_COMPLETED)` waits for the fastest success.

**In Markly**: Makes grading faster and more reliable by racing multiple AIs.

---

### 10. Image Grading Functions
```python
async def grade_image(image_base64, subject):
    ...

async def grade_image_with_markup(image_base64, subject):
    ...
```

**Python Concepts**:
- **Multiple similar functions**: Good code reuse.
- Passing data into functions (e.g., image data and subject name).

**In Markly**: Handles photo-based homework using AI vision.

---

### 11. Text-Based Assignment Judging
```python
async def judge_assignment(content, rubric):
    # Builds prompt + delegates to concurrent racing
```

**Python Concept: Function Composition**  
Building bigger functions by combining smaller ones.

**In Markly**: Main function for grading normal text assignments.

---

### 12. Main Guard
```python
if __name__ == "__main__":
    asyncio.run(asyncio.sleep(0))
```

**Python Concept: Entry Point Guard**  
This code runs only when you execute the file directly, not when another file imports it.

**Mini Demo**:
```python
if __name__ == "__main__":
    print("Running tests for this file directly!")
```

---

## Big-Picture Python Concepts You Learned

- **Organizing code**: Imports, constants, functions, modules
- **Data structures**: Lists, Dictionaries, Strings
- **Control flow**: `if`, `try/except`, loops
- **Functions**: `def`, parameters, return values, async functions
- **Waiting efficiently**: `asyncio`
- **Error handling**: Graceful recovery with `try/except`
- **Modular design**: Each piece has one clear job

These are essential Python skills used in professional projects like Markly.

---

**Practice Suggestions**:
1. Create a new file. Add a dictionary of subjects and a simple function that returns a prompt.
2. Turn that function into `async def` and add `await asyncio.sleep(1)`.
3. Test it with `python yourfile.py`.

