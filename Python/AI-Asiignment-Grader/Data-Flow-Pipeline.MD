# The Markly Data Flow Pipeline: A Deep Dive into AI-Powered Assignment Grading

**Published:** 2026-06-26  
**Reading Time:** ~12 minutes  
**Audience:** Software engineers, technical architects, and educators interested in automated grading systems

---

## Introduction

Markly is an AI-powered assignment grading system that transforms a raw student submission into a fully annotated, professionally formatted PDF report — all in under a minute. At its core lies a five-stage data flow pipeline that orchestrates file ingestion, AI inference, visual annotation, report generation, and data persistence.

This article examines each stage in detail, exploring the design decisions, data transformations, and engineering trade-offs that make the pipeline both robust and extensible.

---

## The Pipeline at a Glance

```
┌──────────┐    ┌────────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Teacher │───►│   Upload   │───►│  Extract │───►│  AI      │───►│  Markup  │───►│  PDF     │
│  Action  │    │  (Panel)   │    │ (utils)  │    │ (engine) │    │ (markup) │    │ (report) │
└──────────┘    └────────────┘    └──────────┘    └──────────┘    └────┬─────┘    └────┬─────┘
                                                                      │               │
                                                                      ▼               ▼
                                                               ┌──────────┐    ┌──────────┐
                                                               │ Annotated│    │  Report  │
                                                               │  Image   │    │   PDF    │
                                                               └──────────┘    └────┬─────┘
                                                                                    │
                                                                                    ▼
                                                                             ┌──────────┐
                                                                             │  Save    │
                                                                             │ (storage)│
                                                                             └──────────┘
```

| Stage | Module | Input → Output | Latency Target |
|-------|--------|----------------|----------------|
| File Ingestion | `utils.py` | File bytes → extracted text (+ base64 image) | < 2s |
| AI Grading | `engine.py` | Text + subject → grade/feedback/markup JSON | < 30s |
| Visual Markup | `markup.py` | Original image + markup JSON → annotated PNG | < 3s |
| PDF Report | `report.py` | Annotated image + feedback → two-page PDF | < 2s |
| Persistence | `storage.py` | Grade record → append to `students.json` | < 100ms |

---

## Stage 1: File Ingestion (`utils.py`)

### The Challenge

Teachers upload assignments in diverse formats — PDFs with embedded text, scanned PDFs containing images, Word documents, and photographs of handwritten work. Each format requires a distinct extraction strategy, and the system must handle all of them transparently.

### The Router Pattern

Markly employs a simple router pattern that delegates to format-specific extractors based on file extension:

```python
def extract_text_from_file(file_bytes, filename):
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

### Extractor Deep-Dives

| Format | Library | Technique | Key Consideration |
|--------|---------|-----------|-----------------|
| **PDF** | PyMuPDF (`fitz`) | Page-by-page text extraction | Handles both text-based and image-based PDFs; text extraction is native, images pass through to OCR |
| **DOCX** | `python-docx` | Paragraph iteration | Preserves paragraph structure; ignores formatting metadata |
| **Images** | `pytesseract` + Pillow | Tesseract OCR | Requires system-installed Tesseract engine; accuracy depends on image quality |

### The Base64 Bridge

For image uploads, the pipeline must preserve the original image for annotation while also extracting its text for AI analysis. The `image_to_base64()` function encodes raw image bytes into a base64 string, enabling the AI API to "see" the assignment visually:

```python
def image_to_base64(file_bytes):
    return base64.b64encode(file_bytes).decode("utf-8")
```

This dual-path approach — text for analysis, image for annotation — is a critical design decision that enables the visual feedback layer.

### Grade Extraction

After AI grading, the response contains free-form text. The `extract_grade()` function uses a cascading regex strategy to locate numerical or letter grades:

```python
patterns = [
    r"\b(\d{1,2}(?:.\d+)?)\s*/\s*10\b",           # 8/10
    r"\bGrade[:\s]* ([A-F][+-]?)\b",              # Grade: B+
    r"\b(\d{1,2}(?:.\d+)?)\s*/\s*(?:100|20|50)\b", # 85/100
]
```

The cascading approach prioritizes the most common format (`/10`) while remaining flexible. If no pattern matches, the system gracefully returns `"N/A"` rather than failing.

---

## Stage 2: AI Grading (`engine.py`)

### The OpenRouter Abstraction

Rather than coupling to a single AI provider, Markly uses **OpenRouter** — a unified gateway that exposes multiple LLM models (GPT-4, Claude, Gemini, etc.) behind a single API. This abstraction provides two key advantages:

1. **Model Racing:** The system can send the same grading prompt to multiple models simultaneously and select the best response
2. **Provider Resilience:** If one model is unavailable, the system automatically falls back to another

### The Grading Pipeline

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Subject        │────►│  Prompt         │────►│  Model          │
│  Detection      │     │  Assembly       │     │  Racing         │
│                 │     │                 │     │                 │
│ • Content       │     │ • Persona       │     │ • Parallel      │
│   analysis      │     │   selection     │     │   requests      │
│ • Keyword       │     │ • Rubric        │     │ • Response      │
│   matching      │     │   injection     │     │   scoring       │
│ • Fallback to   │     │ • Context       │     │ • Consensus     │
│   user input    │     │   assembly      │     │   selection     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │  Response       │
                                               │  Parsing        │
                                               │                 │
                                               │ • Grade extract │
                                               │ • Markup JSON   │
                                               │ • Feedback text │
                                               └─────────────────┘
```

### Subject Detection

The engine attempts to auto-detect the subject from assignment content using keyword analysis. If detection fails or confidence is low, it falls back to the subject explicitly selected by the teacher in the UI.

### Prompt Assembly

The prompt is constructed from three components stored in `personas.py` and `rubrics.py`:

| Component | Source | Purpose |
|-----------|--------|---------|
| **Persona** | `personas.py` | Defines the AI's grading personality, tone, and evaluation approach per subject |
| **Rubric** | `rubrics.py` | Provides structured scoring criteria with point allocations |
| **Context** | Runtime | Injects the actual assignment text and any base64-encoded images |

### Model Racing Strategy

When multiple models respond, the system evaluates responses based on:
- **Grade consistency:** Do multiple models agree on the grade?
- **Feedback completeness:** Does the response include all required sections?
- **Markup validity:** Is the JSON markup well-formed and actionable?

The winning response is parsed into three artifacts:
- `grade`: Extracted via `utils.extract_grade()`
- `feedback`: Free-form text feedback
- `markup_json`: Structured annotation instructions for the visual layer

---

## Stage 3: Visual Markup (`markup.py`)

### The Philosophy: Authentic Teacher Feedback

The visual annotation layer is what distinguishes Markly from generic grading tools. Rather than generating sterile digital comments, it simulates the organic, imperfect quality of handwritten teacher marks — ticks, crosses, circles, margin notes, and wavy underlines.

### The Jitter Algorithm

At the heart of this simulation is a **deterministic jitter** system. Every coordinate is perturbed by a small random offset:

```python
def _jitter(val: float, amount: float = 2.5) -> float:
    return val + random.uniform(-amount, amount)
```

The random seed is fixed (`random.seed(42)`) at the start of each annotation session, ensuring that the same markup JSON always produces the same visual output — critical for reproducibility and testing.

### Annotation Primitives

| Primitive | Visual Effect | Implementation |
|-----------|--------------|----------------|
| **Tick** | ✓ Hand-drawn checkmark | Three jittered line segments |
| **Cross** | ✗ Hand-drawn X | Two diagonal jittered lines |
| **Circle** | ⭕ Wobbly ellipse | Radius wobble (0.93–1.07×) + angle wobble (±0.04 rad) |
| **Underline** | 〰 Wavy line | Sinusoidal curve (amplitude=5px, wavelength=14px) |
| **Box** | ▭ Rounded rectangle | Arc-based corners with semi-transparent fill |
| **Margin Note** | 📝 Side comment | Wrapped text with background in left/right margin |
| **Score Stamp** | ⭕ Fractional score | Large numerator, small denominator in circular format |
| **Summary Block** | 📋 Yellow feedback block | Semi-transparent yellow rectangle at bottom |

### The Alpha Layer Pattern

For semi-transparent overlays (correction boxes, summary blocks), the system uses a separate alpha channel layer:

```python
alpha_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
# Draw semi-transparent fill on alpha layer
# Draw opaque outline on main image
```

This compositing approach ensures that highlights are visible without obscuring the underlying assignment content.

### Font Caching

Handwriting fonts (Caveat, PatrickHand) are expensive to load. A module-level cache eliminates repeated disk I/O:

```python
_FONT_CACHE = {}

def _font(size: int, bold: bool = False, italic: bool = False):
    key = (size, bold, italic)
    if key in _FONT_CACHE:
        return _FONT_CACHE[key]
    # Load and cache font
```

### Input/Output Contract

| Input | Type | Description |
|-------|------|-------------|
| `image_bytes` | `bytes` | Original assignment image |
| `markup_json` | `str` | JSON array of annotation objects |

| Output | Type | Description |
|--------|------|-------------|
| `annotated_buffer` | `io.BytesIO` | PNG-encoded annotated image |

---

## Stage 4: PDF Report Generation (`report.py`)

### The Two-Page Format

Markly generates a standardized two-page PDF report that mirrors traditional teacher feedback forms:

**Page 1: The Annotated Assignment**
- The annotated image is scaled to fit A4 width (210mm)
- Aspect ratio is preserved to prevent distortion
- Sufficient margins ensure printer compatibility

**Page 2: The Structured Report**
- Metadata table (Student, Subject, File)
- Overall feedback paragraph
- Grade display
- Detailed corrections list

### ReportLab Architecture

ReportLab uses a **flowable** document model where content elements (Paragraphs, Tables, Images) are arranged in a top-down flow. Markly configures this with:

```python
doc = SimpleDocTemplate(buffer, pagesize=A4)
styles = getSampleStyleSheet()
# Custom styles for metadata and body text
```

### The Metadata Table

A fixed-width table provides structured context:

| Column | Width | Content |
|--------|-------|---------|
| Label | 38mm | Bold field names ("Student", "Subject", "File") |
| Value | Flexible | Actual data |

This table uses ReportLab's `TableStyle` for borders, padding, and alignment.

### Text-Only Fallback

For assignments without images (pure text uploads), the system provides a streamlined text-focused report via `create_pdf_report()`, omitting the image page and expanding the textual feedback.

### Input/Output Contract

| Input | Type | Description |
|-------|------|-------------|
| `student` | `str` | Student name |
| `subject` | `str` | Subject name |
| `filename` | `str` | Original filename |
| `marked_image_buffer` | `io.BytesIO` | Annotated image (Page 1) |
| `overall_feedback` | `str` | Summary feedback text |
| `grade` | `str` | Extracted grade |
| `report_text` | `str` | Detailed corrections |
| `corrections` | `list` | Structured correction objects |

| Output | Type | Description |
|--------|------|-------------|
| `pdf_buffer` | `io.BytesIO` | Complete two-page PDF |

---

## Stage 5: Persistence (`storage.py`)

### The Flat-File Philosophy

Markly deliberately avoids database servers in favor of a JSON flat-file (`students.json`). This decision prioritizes:

- **Zero operational overhead** — no database installation, configuration, or backup procedures
- **Human readability** — teachers can inspect and edit records directly
- **Simple portability** — the entire application state is a single file

### Schema Design

```json
{
  "Alice Johnson": {
    "history": [
      {
        "timestamp": "2026-06-26T00:00:00",
        "subject": "Mathematics",
        "grade": "8/10",
        "feedback": "Good work on the derivatives..."
      }
    ]
  }
}
```

The schema is intentionally flat — student names are top-level keys, and each student maintains a chronological array of grading records.

### Atomic Write Pattern

To prevent corruption during concurrent access (or process crashes), the system uses a read-modify-write pattern with full file replacement:

```python
def save_db(db):
    with open(DB_FILE, "w", encoding="utf-8") as f:
        json.dump(db, f, indent=2)
```

While this doesn't provide true atomicity at the OS level, it minimizes the window of vulnerability. For a single-user deployment, this is sufficient.

### Graceful Degradation

The `load_db()` function is defensive:

```python
def load_db():
    if not os.path.exists(DB_FILE):
        return {}
    try:
        with open(DB_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data if isinstance(data, dict) else {}
    except (json.JSONDecodeError, OSError):
        return {}
```

If the file is missing, corrupted, or unreadable, the system returns an empty dictionary rather than crashing. This resilience is critical for a tool that may be run in varied environments.

### Input/Output Contract

| Input | Type | Description |
|-------|------|-------------|
| `student` | `str` | Student name |
| `subject` | `str` | Subject |
| `grade` | `str` | Grade string |
| `feedback` | `str` | Feedback text |

| Output | Type | Description |
|--------|------|-------------|
| `students.json` (updated) | `file` | Appended record |

---

## Cross-Cutting Concerns

### Error Handling Strategy

Each stage implements graceful failure with clear error propagation:

| Stage | Failure Mode | Recovery |
|-------|-------------|----------|
| File Ingestion | Corrupted PDF | Return error message; skip to next file |
| AI Grading | API timeout | Retry 3× with exponential backoff; fail with user message |
| Visual Markup | Invalid markup JSON | Skip unparseable annotations; render valid ones |
| PDF Generation | Memory error | Reduce image resolution; retry |
| Persistence | Disk full | Log error; continue without saving history |

### Memory Management

All stages operate on in-memory buffers (`io.BytesIO`) rather than temporary files. This design:

- **Eliminates file cleanup** — no orphaned temp files
- **Improves security** — sensitive assignment data never touches disk
- **Reduces I/O latency** — pure RAM operations

The trade-off is higher RAM usage for large assignments, which is acceptable given the target deployment on machines with 4GB+ RAM.

### Data Integrity

| Checkpoint | Validation |
|------------|------------|
| Post-extraction | Text is non-empty; image is valid base64 |
| Post-AI | Grade is extractable; markup JSON is valid |
| Post-annotation | Image dimensions preserved; annotations within bounds |
| Post-PDF | PDF is valid; both pages present |
| Post-save | JSON is valid; record retrievable |

---

## Performance Characteristics

### End-to-End Latency

| Assignment Type | Typical Size | Total Pipeline Time |
|-----------------|-------------|---------------------|
| Text PDF (1 page) | ~50KB | ~15–25 seconds |
| Image PDF (1 page) | ~500KB | ~20–35 seconds |
| DOCX (2 pages) | ~100KB | ~15–25 seconds |
| Photo (JPG) | ~2MB | ~25–40 seconds |

*Latency is dominated by the OpenRouter API call (~15–30s).*

### Bottleneck Analysis

```
┌────────────────────────────────────────────────────────────┐
│  Time Distribution (typical 30-second grading)               │
│                                                            │
│  ████████████████████████████████████████  AI API call     │
│  ██                                       File extraction  │
│  █                                        Visual markup    │
│  █                                        PDF generation   │
│  ░                                        Persistence      │
│                                                            │
│  0s        10s        20s        30s                       │
└────────────────────────────────────────────────────────────┘
```

The AI grading stage is the clear bottleneck. Future optimizations (caching, async processing, faster models) should target this stage.

---

## Extensibility Patterns

### Adding a New File Format

To support `.txt` files, add an extractor and extend the router:

```python
def extract_txt(file_bytes):
    return file_bytes.decode("utf-8")

# In extract_text_from_file():
elif ext == "txt":
    return extract_txt(file_bytes)
```

### Adding a New Annotation Type

Implement a new drawing function in `markup.py` and extend the JSON parser to recognize the new annotation type:

```python
def _draw_arrow(draw, x0, y0, x1, y1, color):
    # Implementation
    pass
```

### Adding a New Subject

Create entries in `personas.py` and `rubrics.py`:

```python
# personas.py
HISTORY_PERSONA = """You are a history teacher..."""

# rubrics.py
HISTORY_RUBRIC = {
    "historical_accuracy": 4,
    "argumentation": 3,
    "source_citation": 3
}
```

---

## Conclusion

The Markly data flow pipeline demonstrates how a well-structured sequence of discrete stages can transform a complex problem — automated assignment grading — into a manageable, testable, and extensible system. Each stage has a single responsibility, clear input/output contracts, and defensive error handling.

Key architectural strengths include:

1. **Format abstraction** — `utils.py` hides file format complexity behind a unified interface
2. **AI provider abstraction** — OpenRouter enables model flexibility and resilience
3. **Visual authenticity** — Deterministic jitter produces believable handwritten feedback
4. **Zero-ops persistence** — JSON flat-file eliminates database operational burden
5. **In-memory processing** — Security and simplicity through buffer-based operations

The pipeline is designed for evolution: new file formats, annotation types, AI models, and subjects can be added without disrupting existing functionality. For educators, this means a tool that grows with their needs; for developers, it means a codebase that remains maintainable over time.

---

**About the Author:** This article was generated from the Markly source architecture documentation. For implementation details, refer to the [Markly Architecture Document](sandbox:///mnt/agents/output/ARCHITECTURE.md) and [Software Requirements Document](sandbox:///mnt/agents/output/SRD.md).
