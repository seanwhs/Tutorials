# Build an AI-Powered Python Debugger

This tutorial walks you through building a professional, session-aware AI Python debugger using **Panel** and **OpenRouter**. We will create an application that performs live code analysis, generates architecture diagrams, and manages conversation history—all while handling API failures gracefully.

---

## Prerequisites

* **Python 3.10+**
* An **OpenRouter API Key** ([Get one here](https://openrouter.ai/))
* A terminal/command prompt

### Setup Your Environment

Create a folder for your project and install the necessary libraries:

```bash
mkdir ai-debugger
cd ai-debugger
python -m venv venv
# Activate virtual environment
source venv/bin/activate  # Or 'venv\Scripts\activate' on Windows
pip install panel openai python-dotenv reportlab

```

Create a `.env` file in the root and add: `OPENROUTER_API_KEY=your_api_key_here`.

---

## Phase 1: Architecture & Foundations

An AI-powered dashboard must be non-blocking. If we run LLM calls on the main thread, the web interface will freeze while waiting for a response. We solve this by using `threading` and `pn.state.cache` to keep the UI responsive and track user sessions.

### The Core Logic

We use an **LLM Fallback Pattern**. Instead of relying on one model, we iterate through a `MODELS_POOL`. If the first model hits a rate limit, the code automatically tries the next one.

---

## Phase 2: State & Session Management

To allow multiple users to use the debugger without their conversations mixing, we implement `get_conv()`. This checks for a `session_id` in the URL and ensures each user has an isolated conversation object stored in `pn.state.cache`.

---

## Phase 3: Streaming & UI Implementation

We use a `threading.Thread` to offload the LLM request. The `stream_to_pane` function reads tokens as they arrive and updates the UI pane in real-time.

### UI Assembly

Finally, we build the interface. By using `pn.Column` and `pn.Row`, we create a clean, responsive layout.

---

## Phase 4: Adding PDF Export

To export the analysis, we use `reportlab` to generate a PDF in memory. This is critical for cloud hosting (like Hugging Face Spaces) where direct disk access may be restricted.

### PDF Export Logic

Add this to your `app.py`:

```python
import io
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

def create_pdf(text: str) -> io.BytesIO:
    """Creates an in-memory PDF file from the AI analysis text."""
    buffer = io.BytesIO()
    c = canvas.Canvas(buffer, pagesize=letter)
    c.drawString(100, 750, "AI Python Debugger Report")
    
    text_object = c.beginText(100, 720)
    for line in text.split('\n'):
        text_object.textLine(line[:80]) # Basic wrapping
    c.drawText(text_object)
    c.save()
    buffer.seek(0)
    return buffer

```

### Integrate into the UI

Add this button to your `build_ui` function:

```python
download_btn = pn.widgets.FileDownload(
    callback=lambda: create_pdf(output.object),
    filename="debug_report.pdf",
    button_type="primary",
    name="📥 Download Report"
)

```

---

## Launching & Verification

To run your debugger, use the following command in your terminal:

```bash
panel serve app.py --show

```

The browser will open at `http://localhost:5006/app`.

### Why This Architecture Is Robust:

1. **Threaded Streaming:** The UI remains responsive; you can click "Diagram" or "Download" even while an analysis is streaming.
2. **Graceful Fallbacks:** The `call_llm` loop ensures the application continues functioning even if specific free-tier models are overloaded.
3. **In-Memory Buffering:** By using `io.BytesIO` for PDFs, your app stays lightweight and platform-agnostic, making it ready for production deployment.
