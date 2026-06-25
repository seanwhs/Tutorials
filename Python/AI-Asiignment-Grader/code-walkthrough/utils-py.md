# ✅ **Python Primer: `utils.py` — File Ingestion and Processing**

This primer teaches core Python concepts using real code from a document ingestion module. Each section shows the original code, explains the Python idea simply, provides a short runnable mini-demo, and ties it back to the module.

***

## Module Deep Dive: `utils.py`

This file is the **ingestion layer**: it normalizes student submissions — PDFs, Word documents, or photos — into clean text and base64-encoded images that the rest of the system can reliably use.

***

## 1. Imports

```python
import fitz
import io
import pytesseract
import base64
from PIL import Image
from docx import Document
```

**Python Concept: Selective Imports from External Libraries**  
You can import entire modules (`import io`) or specific names from them (`from PIL import Image`). Each library here solves one format: `fitz` (PyMuPDF) for PDFs, `python-docx` for Word files, PIL + `pytesseract` for OCR on images, and `base64` for encoding binary data as text.

**Mini Demo**:
```python
import io

# BytesIO creates an in-memory file-like object
buf = io.BytesIO(b"hello")
print(buf.read())  # b'hello'

# base64 encodes bytes to ASCII-safe strings
import base64
encoded = base64.b64encode(b"hello")
print(encoded.decode("utf-8"))  # aGVsbG8=
```

**In `utils.py`**: These imports assemble the toolkit for format-specific extraction. Removing any one would break support for that file type.

***

## 2. PDF Extraction

```python
def extract_pdf(file_bytes):
    """Extracts text page by page from a PDF."""
    document = fitz.open(stream=file_bytes, filetype="pdf")
    return "\n".join([page.get_text() for page in document])
```

**Python Concept: Opening Files from Byte Streams + List Comprehensions**  
`fitz.open(stream=...)` reads PDF data directly from memory without needing a physical file. The list comprehension `[page.get_text() for page in document]` iterates over every page, extracts text, and collects results. `"\n".join(...)` aggregates them with page separators.

**Mini Demo**:
```python
import io

# Simulating page-by-page join
pages = ["Page 1 content", "Page 2 content"]
result = "\n".join(pages)
print(result)
# Page 1 content
# Page 2 content

# Changing separator affects readability
print("".join(pages))  # Page 1 contentPage 2 content
```

**In `utils.py`**: This is a **page-by-page reduction** pattern — process individually, then aggregate. Changing `"\n"` to `""` would remove page boundaries and hurt readability.

***

## 3. DOCX Extraction

```python
def extract_docx(file_bytes):
    """Extracts paragraphs from a DOCX file."""
    document = Document(io.BytesIO(file_bytes))
    return "\n".join([paragraph.text for paragraph in document.paragraphs])
```

**Python Concept: In-Memory File Objects + Structured Traversal**  
`io.BytesIO(file_bytes)` wraps raw bytes into a file-like object that `Document()` can read. The `.paragraphs` attribute follows Word's semantic structure, extracting text paragraph by paragraph rather than as raw bytes.

**Mini Demo**:
```python
import io

# BytesIO makes bytes behave like a file
data = b"line1\nline2"
stream = io.BytesIO(data)
print(stream.read())  # b'line1\nline2'

# List comprehension collects items cleanly
words = ["hello", "world"]
upper = [w.upper() for w in words]
print(upper)  # ['HELLO', 'WORLD']
```

**In `utils.py`**: This is a **structured document traversal** pattern. It respects Word's paragraph hierarchy. Adding `if paragraph.text.strip()` would skip empty lines and produce cleaner input.

***

## 4. Image OCR Extraction

```python
def extract_image(file_bytes):
    """Extracts text from images via Tesseract OCR."""
    image = Image.open(io.BytesIO(file_bytes))
    return pytesseract.image_to_string(image)
```

**Python Concept: Binary-to-Image Conversion + Delegation**  
`Image.open()` accepts a file-like object, so `BytesIO` bridges raw bytes and PIL. The function delegates complex OCR work to Tesseract, treating it as a black box that returns plain text.

**Mini Demo**:
```python
from PIL import Image
import io

# Create a tiny 1x1 pixel image in memory
img = Image.new("RGB", (1, 1), color="red")
buf = io.BytesIO()
img.save(buf, format="PNG")
buf.seek(0)

# Reload from bytes
reloaded = Image.open(buf)
print(reloaded.size)  # (1, 1)
print(reloaded.mode)  # RGB
```

**In `utils.py`**: This is an **OCR fallback path**. It converts visual content to text so downstream modules don't need special image handling. OCR quality directly affects grading accuracy.

***

## 5. File Type Dispatcher

```python
def extract_text_from_file(file_bytes, filename):
    """Orchestrates text extraction based on file extension."""
    ext = filename.lower().split('.')[-1]
    if ext == "pdf":
        return extract_pdf(file_bytes)
    elif ext == "docx":
        return extract_docx(file_bytes)
    elif ext in ("png", "jpg", "jpeg"):
        return extract_image(file_bytes)
    else:
        raise ValueError(f"Unsupported file type: {filename}")
```

**Python Concept: String Parsing + Control Flow Dispatch**  
`filename.lower().split('.')[-1]` normalizes and extracts the extension. The `if/elif/else` chain routes to the correct handler. `raise ValueError(...)` stops execution with a descriptive message when no handler matches.

**Mini Demo**:
```python
# Extension extraction
filename = "Essay.PDF"
ext = filename.lower().split('.')[-1]
print(ext)  # pdf

# Membership testing with tuples
print("jpg" in ("png", "jpg", "jpeg"))  # True
print("gif" in ("png", "jpg", "jpeg"))  # False

# Raising errors
try:
    raise ValueError("Bad input")
except ValueError as e:
    print(e)  # Bad input
```

**In `utils.py`**: This is a **dispatcher / router pattern**. It keeps the rest of the codebase format-agnostic. Adding a `.txt` case (`return file_bytes.decode("utf-8")`) would be straightforward.

***

## 6. Base64 Image Encoding

```python
def image_to_base64(file_bytes):
    """Encodes image bytes to base64 for AI API consumption."""
    return base64.b64encode(file_bytes).decode("utf-8")
```

**Python Concept: Binary-to-Text Encoding + Bytes/String Conversion**  
`base64.b64encode()` converts binary data to ASCII-safe bytes. `.decode("utf-8")` turns those bytes into a Python string. This two-step process is necessary because JSON and HTTP APIs expect text, not raw binary.

**Mini Demo**:
```python
import base64

raw = b"\x00\x01\x02"  # Binary data
encoded_bytes = base64.b64encode(raw)
print(type(encoded_bytes))  # <class 'bytes'>
print(encoded_bytes)        # b'AAEC'

# Without decode, you have bytes — problematic for JSON
text = encoded_bytes.decode("utf-8")
print(type(text))  # <class 'str'>
print(text)        # AAEC

# JSON serialization requires strings
import json
print(json.dumps({"img": text}))   # {"img": "AAEC"}
# print(json.dumps({"img": encoded_bytes}))  # TypeError!
```

**In `utils.py`**: This is a **transport preparation step**. Forgetting `.decode("utf-8")` would return `bytes`, causing JSON serialization or API errors downstream.

***

## Big-picture reading of the module

This module is the **normalization gateway** of the system. It hides format complexity from the rest of the application so that grading, markup, and reporting modules can work with clean, consistent inputs.

The main ideas are:
- **Specialized handlers per format** — each file type gets optimized extraction.
- **Dispatcher pattern** — one entry point routes to the correct handler.
- **OCR fallback** — image submissions become machine-readable text.
- **Base64 encoding** — bridges binary media with text-based AI APIs.

This well-designed ingestion layer is what allows the system to handle real-world student submissions regardless of original format.

***

## Practice suggestions

- Remove `pytesseract` and observe how image-based assignments fail, revealing where OCR is essential.
- Add a `.txt` case to the dispatcher using `file_bytes.decode("utf-8")`.
- Change `"\n".join(...)` to `"".join(...)` in `extract_pdf()` and compare readability.
- Test `image_to_base64()` without `.decode("utf-8")` and watch JSON serialization fail.
- Create a small script that dispatches different file types and prints their extracted text lengths.

***

## References

- PyMuPDF (`fitz`) documentation for PDF text extraction.
- `python-docx` documentation for Word document structure.
- Pillow (PIL) documentation for image handling.
- Pytesseract documentation for OCR configuration.

***

One important style note: if you are polishing this for teaching material, docstrings are usually better than many inline comments because they explain intent without cluttering the code.
