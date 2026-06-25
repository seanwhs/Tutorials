**✅ Python Primer: `markup.py` — Teacher Markup Drawing Engine**

This primer teaches **core Python concepts** using real code from `markup.py` in the Markly app. Every section shows the original code, explains the Python idea in simple terms, gives a short runnable mini demo, and connects it back to the app.

---

## Module Deep Dive: `markup.py`

This file is the **artist** of the Markly system. It takes structured instructions from the AI and draws realistic red-pen marks, ticks, crosses, speech bubbles, and grades on student assignment images.

### 1. Imports and font cache
```python
import io, json, math, os, random
from PIL import Image, ImageDraw, ImageFont
_FONT_CACHE: dict[tuple, ImageFont.FreeTypeFont] = {}
```

**Python Concept: Importing Modules + Caching**  
`import` brings in tools. You can import several on one line. The `_FONT_CACHE` dictionary remembers previously loaded fonts (caching) so the program runs faster.

**Mini Demo**:
```python
import random

cache = {}
def get_font(name):
    if name in cache:
        return cache[name]          # Return cached version
    result = f"Loaded {name}"
    cache[name] = result
    return result

print(get_font("Caveat"))
print(get_font("Caveat"))   # Fast because it's cached
```

**In markup.py**: Prevents reloading fonts every time text is drawn.

---

### 2. Font loader
```python
def _font(size: int, bold: bool = False, italic: bool = False) -> ImageFont.FreeTypeFont:
    # tries several font files and falls back to default
```

**Python Concepts**:
- **Functions with default parameters** (`bold=False`)
- **Type hints** (`size: int`) — optional notes for humans
- `try/except` + `break` for safe fallbacks

**Mini Demo**:
```python
def load_font(preferred="nice.ttf", fallback="basic.ttf"):
    if os.path.exists(preferred):
        return preferred
    return fallback                     # Graceful fallback

print(load_font("missing.ttf"))
```

**In markup.py**: Tries nice handwritten fonts first, then falls back safely.

---

### 3. Color constants
```python
RED = (198, 30, 30, 255)
BLUE = (30, 90, 200, 255)
```

**Python Concept: Constants & Tuples**  
Constants are written in `UPPER_CASE`. Tuples are fixed lists of values (here used for colors: Red, Green, Blue, Alpha).

**Mini Demo**:
```python
RED = (255, 0, 0, 255)
print(RED[0])        # 255 = red intensity
print(RED)           # (255, 0, 0, 255)
```

**In markup.py**: Defines the teacher’s pen colors used throughout the drawing code.

---

### 4. Jitter helper
```python
def _jitter(val: float, amount: float = 2.5) -> float:
    return val + random.uniform(-amount, amount)
```

**Python Concepts**:
- Helper function with default value
- `random.uniform()` for natural variation

**Mini Demo**:
```python
import random
def jitter(val, amount=3):
    return val + random.uniform(-amount, amount)

print(jitter(100))   # Example: 98.4 or 101.7
```

**In markup.py**: Makes lines and shapes look hand-drawn instead of perfectly straight.

---

### 5–8. Drawing Helper Functions
```python
def _jittered_line(...):
def _text_size(...):
def _wavy_underline(...):
def _wobbly_ellipse(...):
```

**Python Concepts**:
- `for` loops to build shapes step-by-step
- `math.sin()` and `math.cos()` for curves
- Reusing small functions inside bigger ones

**Mini Demo**:
```python
import math
for i in range(5):
    angle = 2 * math.pi * i / 5
    print(round(math.sin(angle), 2))
```

**In markup.py**: These small helpers are the building blocks for realistic teacher annotations.

---

### 9–10. Rounded Rectangle & Speech Bubble
```python
def _rounded_rect(...):
def _speech_bubble(...):
```

**Python Concepts**:
- Complex functions built from simpler ones
- `textwrap.wrap()` to break long text into lines
- `min()` / `max()` to keep things visible on screen

**Mini Demo**:
```python
import textwrap
text = "This is a very long comment from the teacher."
lines = textwrap.wrap(text, width=20)
print(lines)
```

**In markup.py**: Creates nice comment bubbles with tails pointing to the marked area.

---

### 11–15. Symbol & Annotation Functions
```python
def _draw_tick(...):
def _draw_cross(...):
def _draw_score_stamp(...):
# ... correction, comment, margin_note
```

**Python Concepts**:
- `if/elif` chains (dispatcher pattern)
- String methods like `.split("/")`
- Reusing helper functions

**Mini Demo**:
```python
def draw_mark(mark_type):
    if mark_type == "tick":
        print("✓ Correct!")
    elif mark_type == "cross":
        print("✕ Needs work")
    else:
        print("Comment")

draw_mark("tick")
```

**In markup.py**: Chooses the right visual style based on the AI’s markup type.

---

### 16. Main Entry Point
```python
def draw_teacher_markup(image_bytes: bytes, markup_json: str) -> io.BytesIO:
    random.seed(42)                    # Makes results repeatable
    base = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
```

**Python Concepts**:
- Main function (entry point)
- `io.BytesIO` for working with images in memory
- `random.seed()` for consistent results during testing

**Mini Demo**:
```python
from io import BytesIO
data = b"fake image data"
buffer = BytesIO(data)
print(buffer)
```

---

### 17. JSON Parsing & Drawing Loop
```python
try:
    data = json.loads(markup_json)
except json.JSONDecodeError:
    data = {"marks": []}

for mark in marks:
    if mtype == "correction":
        ...
    elif mtype == "comment":
        ...
```

**Python Concepts**:
- Safe `try/except` for JSON
- Looping through lists of dictionaries
- `if/elif` dispatcher

**Mini Demo**:
```python
import json
data = json.loads('{"type": "correction", "text": "Fix this"}')
print(data.get("type"))
```

---

### 18. Final Image Composition
```python
result = Image.alpha_composite(base, alpha_fill)
result = result.convert("RGB")
out = io.BytesIO()
result.save(out, format="PNG")
out.seek(0)
return out
```

**Python Concepts**:
- Combining image layers
- `.seek(0)` to reset buffer position so it can be read again

**Mini Demo**:
```python
from io import BytesIO
buf = BytesIO()
buf.write(b"image data")
buf.seek(0)          # Important!
print(buf.read(10))
```

---

## Big-Picture Python Concepts You Learned

- **Helper functions** — breaking complex tasks into small, reusable pieces
- **Caching** — remembering results to improve speed
- **Fallbacks & `try/except`** — making code robust and safe
- **Math & geometry** — using loops, `sin/cos`, and coordinates
- **Randomness with control** — `random` + `seed`
- **Working with images** — basic Pillow usage
- **String & list processing** — splitting, wrapping, joining

These are fundamental skills used in graphics, games, web apps, and automation.

---

**Practice Suggestions**:
1. Create a function that draws a jittered red line on a blank image using Pillow.
2. Build a small dictionary of colors and randomly pick one.
3. Load any image and draw a simple text label on it.
