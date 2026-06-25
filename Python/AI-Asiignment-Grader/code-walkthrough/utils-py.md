**✅ Rewritten & Polished Version**

---

## Module Deep Dive: `utils.py` — File Ingestion and Processing

This module serves as the **ingestion layer** of the Markly project. It normalizes student submissions — regardless of whether they are PDFs, Word documents, or photos — into clean text and (when needed) base64-encoded images that the rest of the system can reliably use.

### 1. Imports
```python
import fitz
import io
import pytesseract
import base64
from PIL import Image
from docx import Document
```

**Why this block exists**  
These imports provide specialized tools for handling different document formats. `fitz` (PyMuPDF) excels at fast PDF text extraction, `python-docx` reads structured Word files, PIL + pytesseract enable OCR on images, and `base64` prepares image data for multimodal AI APIs.

**Python concepts used**  
- Selective imports from external libraries  
- Format-specific tooling instead of a one-size-fits-all approach  
- Working with binary data (`bytes`) and converting it for different consumers  

**Pattern analysis**  
This is a **format-specific extraction setup**. Each file type gets its own optimized handler.

**What if**  
Removing `pytesseract` would immediately break support for image-based assignments, clearly revealing where OCR is essential in the pipeline.

---

### 2. PDF Extraction
```python
def extract_pdf(file_bytes):
    """Extracts text page by page from a PDF."""
    document = fitz.open(stream=file_bytes, filetype="pdf")
    return "\n".join([page.get_text() for page in document])
```

**Why this block exists**  
It converts raw PDF bytes (held in memory) into a single readable text string by extracting content from every page.

**Python concepts used**  
- Opening a file from a byte stream (`stream=`)  
- List comprehension + generator-style iteration over document pages  
- Joining results with explicit separators  

**Pattern analysis**  
**Page-by-page reduction** pattern — process individually, then aggregate.

**What if**  
Changing `"\n".join(...)` to `"".join(...)` removes page boundaries, which can hurt readability and subject detection in longer documents.

---

### 3. DOCX Extraction
```python
def extract_docx(file_bytes):
    """Extracts paragraphs from a DOCX file."""
    document = Document(io.BytesIO(file_bytes))
    return "\n".join([paragraph.text for paragraph in document.paragraphs])
```

**Why this block exists**  
It respects the semantic structure of Word documents by traversing paragraphs rather than treating the file as raw text.

**Python concepts used**  
- `io.BytesIO` for in-memory file-like objects  
- Library-specific document model (`document.paragraphs`)  
- List comprehensions for clean data collection  

**Pattern analysis**  
**Structured document traversal** — follows the natural hierarchy of the file format.

**What if**  
Adding a filter like `if paragraph.text.strip()` would skip empty paragraphs and produce cleaner input for the AI.

---

### 4. Image OCR Extraction
```python
def extract_image(file_bytes):
    """Extracts text from images via Tesseract OCR."""
    image = Image.open(io.BytesIO(file_bytes))
    return pytesseract.image_to_string(image)
```

**Why this block exists**  
Many student submissions arrive as photos. This function makes handwritten or printed image-based assignments machine-readable.

**Python concepts used**  
- Converting bytes back into an image object  
- Delegating complex OCR work to Tesseract  

**Pattern analysis**  
**OCR fallback path** — converts visual content into text so downstream modules don’t need special handling.

**What if**  
Testing with blurry vs. clear images quickly demonstrates how OCR quality directly affects grading accuracy.

---

### 5. File Type Dispatcher
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

**Why this block exists**  
It acts as the central router, directing each upload to the correct extraction handler.

**Python concepts used**  
- String normalization and extension parsing  
- Simple but effective control flow (`if/elif`)  
- Explicit error handling for unsupported formats  

**Pattern analysis**  
**Dispatcher / router pattern** — keeps the rest of the codebase format-agnostic.

**What if**  
Adding a `.txt` case (e.g., `return file_bytes.decode("utf-8")`) would be straightforward and extend support easily.

---

### 6. Base64 Image Encoding
```python
def image_to_base64(file_bytes):
    """Encodes image bytes to base64 for AI API consumption."""
    return base64.b64encode(file_bytes).decode("utf-8")
```

**Why this block exists**  
Multimodal AI models (like GPT-4o or Claude-3.5) often expect images as text-embedded data rather than raw binary.

**Python concepts used**  
- Binary-to-text encoding (`base64`)  
- Bytes ↔ string conversion  

**Pattern analysis**  
**Transport preparation step** — bridges binary media with text-based APIs.

**What if**  
Forgetting `.decode("utf-8")` would leave you with `bytes` instead of a string, causing JSON serialization or API errors.

---

### Big-Picture Reading of `utils.py`
`utils.py` is the **normalization gateway** of Markly. Its primary job is to hide format complexity from the rest of the application so that `engine.py`, `markup.py`, and `report.py` can work with clean, consistent inputs.

Core design principles demonstrated:
- Specialized handlers per format
- Clean dispatcher pattern
- OCR support for real-world student submissions
- Base64 encoding for visual AI reasoning

---

## How Extracted Outputs Feed into `engine.py`

**The extracted text and base64 image are the foundational inputs for the entire AI grading pipeline.**

### High-Level Flow
1. **User Upload** (`app.py`) → `extract_text_from_file()` + `image_to_base64()` (`utils.py`)
2. **Normalized data** → `engine.py` (subject detection + grading)
3. **AI results** (feedback, grade, markup instructions) → `markup.py` → `report.py` → `storage.py`

### Detailed Walkthrough

#### Step 1: Ingestion & Normalization
`extract_text_from_file()` produces `extracted_text`.  
Optionally, `image_to_base64()` produces `img_b64` for visual assignments.

This step ensures `engine.py` receives uniform data regardless of original format.

#### Step 2: `engine.py` – Subject Detection & Grading
```python
# Expected structure in engine.py
def grade_assignment(student, subject, filename, file_bytes):
    text = extract_text_from_file(file_bytes, filename)
    img_b64 = image_to_base64(file_bytes) if is_image(filename) else None

    # Subject detection (if needed)
    detected_subject = detect_subject(text, img_b64)

    # Load appropriate persona and rubric
    persona = load_persona(detected_subject)
    rubric = load_rubric(detected_subject)

    # Build rich prompt for AI
    prompt = build_grading_prompt(text, img_b64, student, detected_subject, rubric, persona)

    # Model racing + parsing
    feedback, grade, markup_json = call_ai_models(prompt)
    final_grade = extract_grade(feedback) or grade   # utils.py helper

    return feedback, final_grade, markup_json
```

**Critical Dependencies**:
- **Subject Detection**: Relies heavily on good `extracted_text` (keywords, problem types, instructions).
- **Grading Quality**: The full text + image (when available) is fed to the LLM so it can reference specific parts.
- **Markup Generation**: AI returns structured `markup_json` that `markup.py` later renders as handwritten-style annotations.

#### Step 3: Downstream Modules
- `markup.py`: Uses original image + `markup_json` to draw realistic teacher annotations (ticks, crosses, correction boxes, margin notes, etc.).
- `report.py`: Combines annotated image and structured feedback into a polished two-page PDF.
- `storage.py`: Saves student history for longitudinal tracking.

### Why This Architecture Matters
- **Decoupling** — Format logic stays isolated in `utils.py`.
- **Robustness** — OCR + base64 support handles messy real-world submissions.
- **Extensibility** — Adding new file types only touches the dispatcher.
- **Quality Chain** — Clean extraction directly improves subject detection, grading accuracy, and visual feedback quality.

This well-designed ingestion layer is what allows Markly to feel like a true teacher assistant rather than just another automated grader.
