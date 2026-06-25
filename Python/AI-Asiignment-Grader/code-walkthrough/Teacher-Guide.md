# **✅ Teacher’s Guide: Markly Project Architecture**

### Welcome to the Markly Teacher’s Guide

**Markly** is an intelligent AI-powered grading assistant that mimics a real teacher. It accepts student submissions (PDF, DOCX, or photos), extracts the content, uses AI to analyze and grade them, applies realistic handwritten-style annotations directly on the work, and produces professional PDF reports — all while keeping a history of student performance.

This guide is written for **educators, developers, and students** who want to understand how the system works under the hood. It explains the architecture clearly, like a well-organized lesson plan.

---

### 1. Overall System Architecture

Markly follows a clean **pipeline architecture** with strong separation of concerns:

```
Student Upload (app.py)
        ↓
[utils.py] ── Ingestion & Normalization
        ↓ (text + optional base64 image)
[engine.py] ── AI Brain (subject detection, grading, model racing)
        ↓ (feedback, grade, markup_json)
├── [markup.py] ── Visual Teacher Annotations (handwriting-style)
├── [report.py] ── Professional PDF Report Generation
└── [storage.py] ── Student History Tracking
```

**Key Layers**:
- **Ingestion Layer** (`utils.py`): Handles messy real-world files
- **Intelligence Layer** (`engine.py`): AI reasoning and orchestration
- **Presentation Layer** (`markup.py` + `report.py`): Teacher-like output
- **Persistence Layer** (`storage.py`): Memory and history

---

### 2. Module Walkthroughs

#### **utils.py — File Ingestion and Processing** (The Foundation)
This is the **entry gate** of the system. It normalizes all student submissions into clean, AI-ready data.

**Core Functions**:
- `extract_text_from_file()` — Dispatcher that routes PDFs, DOCX, and images
- `extract_pdf()`, `extract_docx()`, `extract_image()` (OCR via Tesseract)
- `image_to_base64()` — Prepares images for vision models
- `extract_grade()` — Regex-based grade parser

**Why it matters**: Without this layer, the AI would choke on different file formats. It makes the rest of the system format-agnostic.

**Teacher Note**: Think of this as the “student work scanner” that turns photos, scanned PDFs, and Word files into readable text for the AI grader.

---

#### **engine.py — AI Orchestration & Grading Core** (The Brain)
This is the **most sophisticated module**. It turns raw student work into thoughtful feedback.

**Key Capabilities**:
- **Subject Detection** — Automatically classifies work (Math, English, Science, Programming)
- **Model Racing** — Runs multiple free/open models in parallel via OpenRouter and takes the fastest reliable answer
- **Prompt Engineering** — Uses subject-specific rubrics and personas
- **Multimodal Support** — Sends images + text to vision models (e.g., GPT-4o)
- **Structured Output** — Requests JSON for markup instructions when needed

**Core Functions**:
- `detect_subject()`
- `get_ai_response_concurrently()` (the racing engine)
- `grade_image_with_markup()`
- `judge_assignment()`
- `extract_grade()`

**Teacher Note**: This module is like having several teaching assistants working simultaneously. The system is resilient — if one model is slow or fails, others pick up the slack.

---

#### **markup.py — Teacher-Style Image Annotations** (The Red Pen)
This module makes the feedback feel **human**.

**Highlights**:
- Uses Pillow (PIL) to draw on student images
- Realistic handwriting effects: jitter, wobbly lines, wavy underlines
- Visual elements: ticks, crosses, correction boxes, margin notes, score stamps, speech bubbles
- Hand-drawn style fonts and subtle randomness for authenticity

**Main Function**: `draw_teacher_markup(image_bytes, markup_json)`

**Teacher Note**: This is what makes Markly special. Students don’t get cold typed feedback — they get annotations that look like their teacher sat down with a red pen.

---

#### **report.py — PDF Report Generation** (The Professional Output)
Creates polished, printable deliverables.

**Features**:
- Two-page PDF:
  - Page 1: Annotated student work
  - Page 2: Structured teacher report (metadata, feedback, grade, corrections)
- Uses ReportLab for layout control
- Separate path for text-only assignments (`create_pdf_report`)

**Teacher Note**: The final output looks professional enough to send to students or parents.

---

#### **storage.py — Persistence** (The Memory)
Simple but effective student history tracking.

**Functions**:
- `load_db()` / `save_db()` — Flat-file JSON database (`students.json`)
- `add_record()` — Logs each grading session
- `get_student_history()` — Retrieves past performance

**Teacher Note**: This enables longitudinal tracking — seeing how a student improves over time.

---

### 3. End-to-End Data Flow (The Grading Pipeline)

1. **Upload** → `app.py` receives file + student info
2. **Extraction** → `utils.py` produces `text` and/or `base64_image`
3. **AI Analysis** → `engine.py`:
   - Detects subject (if needed)
   - Selects rubric/persona
   - Runs model racing (or vision call)
   - Extracts grade + generates `markup_json`
4. **Visualization** → `markup.py` draws annotations on the original image
5. **Reporting** → `report.py` assembles annotated image + feedback into PDF
6. **Persistence** → `storage.py` saves the record

---

### 4. Key Design Decisions & Teaching Points

**Strengths**:
- **Modularity** — Each file has one clear responsibility
- **Resilience** — Model racing + error handling + OCR fallback
- **Extensibility** — Easy to add new subjects, file types, or models
- **Realism** — Handwriting-style markup + teacher tone prompts
- **Privacy/Security** — API key via `.env`, local JSON storage

**Trade-offs**:
- Relies on external AI services (OpenRouter)
- OCR quality depends on image clarity
- Flat-file database is simple but not suited for very large-scale use

**Python Patterns Demonstrated**:
- Dispatcher pattern (`utils.py`)
- Strategy pattern via dictionaries (`engine.py`)
- Async concurrency & racing
- Separation of concerns
- Robust parsing (regex + JSON mode)

---

### 5. How to Extend Markly (For Developers & Advanced Users)

- **Add a new subject**: Add prompt in `personas.py`/`rubrics.py`, update mapping in `engine.py`
- **New file type**: Extend dispatcher in `utils.py`
- **Better annotations**: Enhance drawing functions in `markup.py`
- **Improve grading**: Tune prompts or add more models
- **UI enhancements**: Modify `app.py` (Panel-based dashboard)

---

### Final Thoughts for Teachers

Markly is more than just an autograder — it’s a **teaching assistant simulator**. The combination of:
- Accurate content extraction
- Intelligent subject-aware grading
- Human-like visual feedback
- Professional reporting

…creates an experience that feels personal and constructive for students.

The codebase is intentionally well-documented and modular, making it an excellent project for learning about real-world Python architecture, AI integration, image processing, and async programming.

---
