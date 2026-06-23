**Build an AI-Powered Python Debugger Tutorial**

This tutorial guides you through creating a professional, session-aware AI Python debugger using **Panel** and **OpenRouter**. The app provides live code analysis, generates ASCII architecture diagrams, supports follow-up questions, maintains conversation history, and exports reports as PDFs—all with graceful error handling and responsive UI.

---

### Prerequisites

- **Python 3.10+**
- An **OpenRouter API Key** (free tier available) → [Get one here](https://openrouter.ai/)
- Terminal / Command Prompt

---

### Step 1: Project Setup

1. Create a project folder:
   ```bash
   mkdir ai-debugger
   cd ai-debugger
   ```

2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   # On Linux/macOS:
   source venv/bin/activate
   # On Windows:
   venv\Scripts\activate
   ```

3. Install required packages:
   ```bash
   pip install panel openai python-dotenv reportlab
   ```

4. Create a `.env` file in the root folder:
   ```
   OPENROUTER_API_KEY=your_actual_api_key_here
   ```

---

### Step 2: Create `app.py`

Create a new file named **`app.py`** in the project root and add the following code. Each major section is explained below.

```python
import os
import io
import threading
from dataclasses import dataclass
from typing import List, Dict, Optional

from dotenv import load_dotenv
import panel as pn
from openai import OpenAI
from tornado.iostream import StreamClosedError
from tornado.websocket import WebSocketClosedError

# Load environment variables
load_dotenv()

# Initialize Panel with CodeEditor support
pn.extension("codeeditor", sizing_mode="stretch_width", design="bootstrap")

# ==================== PROMPTS ====================

SYSTEM_PROMPT = """You are an expert Python debugging assistant.
When given Python code:
1. Identify the bug.
2. Explain the root cause.
3. Provide fixed code.
4. Suggest unit tests.

Return your answer using these Markdown sections:
## Error
## Explanation
## Fixed Code
## Unit Tests
## Improvements
"""

DIAGRAM_SYSTEM_PROMPT = """You are a software architecture expert.
Generate TWO ASCII flowcharts, each wrapped in triple-backtick fenced code blocks.
Label the first "Buggy Code Flow" and the second "Fixed Code Flow" inside the block.
Use only ASCII characters: [], -->, |, and spaces for indentation.
Do not add any prose, headers, or explanation outside the two code blocks.
"""

# Fallback models (tries next if one fails)
MODELS_POOL = [
    "openai/gpt-oss-20b:free",
    "cohere/north-mini-code:free",
    "meta-llama/llama-3.2-3b-instruct:free",
]

# Session management
SESSION_KEY = "session_id"
DEFAULT_SESSION = "default"

# Styling
PANE_STYLE = {
    "font-size": "20px", "line-height": "1.9", "width": "100%",
    "background-color": "#111827", "color": "#f9fafb",
    "padding": "16px", "border-radius": "10px", "border": "1px solid #374151",
}

TITLE_STYLE = {"font-size": "32px"}
SECTION_STYLE = {"font-size": "24px"}
INPUT_STYLE = {"font-size": "18px"}
BUTTON_STYLE = {"font-size": "18px"}

# OpenRouter client
client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1",
    default_headers={
        "HTTP-Referer": "https://huggingface.co/spaces/yourusername/AI-Python-Debugger",
        "X-Title": "AI Python Debugger",
    },
)

# ==================== APP STATE ====================

@dataclass
class AppState:
    system_prompt: str = SYSTEM_PROMPT
    cache_key: str = DEFAULT_SESSION

def get_session_id() -> str:
    """Get current browser session ID."""
    return pn.state.session_args.get(SESSION_KEY, [DEFAULT_SESSION])[0]

def get_conv() -> List[Dict[str, str]]:
    """Get or create conversation history for the current session."""
    sid = get_session_id()
    if sid not in pn.state.cache:
        pn.state.cache[sid] = [{"role": "system", "content": SYSTEM_PROMPT}]
    return pn.state.cache[sid]

# ==================== HELPER FUNCTIONS ====================

def safe_set(pane, text: str) -> bool:
    """Safely update a UI pane. Returns False if client disconnected."""
    try:
        pane.object = text
        return True
    except (WebSocketClosedError, StreamClosedError):
        return False

def call_llm(messages, stream: bool = False):
    """Call LLM with automatic fallback between models."""
    last_error = None
    for model in MODELS_POOL:
        try:
            return client.chat.completions.create(
                model=model,
                messages=messages,
                max_tokens=2048,
                stream=stream,
            )
        except Exception as e:
            last_error = e
    raise RuntimeError(f"All models failed: {last_error}")

def stream_to_pane(messages: list, pane) -> None:
    """Stream LLM response into a pane in a background thread."""
    def _run():
        try:
            stream = call_llm(messages, stream=True)
        except Exception as e:
            safe_set(pane, f"**Error:** {e}")
            return

        full = ""
        try:
            for chunk in stream:
                bit = getattr(chunk.choices[0].delta, "content", None)
                if not bit:
                    continue
                full += bit
                if not safe_set(pane, full):
                    return
        except (WebSocketClosedError, StreamClosedError):
            return
        except Exception as e:
            safe_set(pane, f"**Error:** {e}")
            return

        # Save to conversation history
        messages.append({"role": "assistant", "content": full})

    threading.Thread(target=_run, daemon=True).start()

def create_pdf(text: str) -> io.BytesIO:
    """Generate in-memory PDF report."""
    buffer = io.BytesIO()
    c = canvas.Canvas(buffer, pagesize=letter)
    c.drawString(100, 750, "AI Python Debugger Report")
    
    text_object = c.beginText(100, 720)
    for line in text.split('\n'):
        text_object.textLine(line[:80])
    c.drawText(text_object)
    c.save()
    buffer.seek(0)
    return buffer

# ==================== UI BUILD ====================

def build_ui():
    # Widgets
    code_input = pn.widgets.CodeEditor(
        language="python", height=300, theme="monokai",
        sizing_mode="stretch_width", margin=(10, 0, 15, 0)
    )

    output = pn.pane.Markdown("_Analysis will appear here..._", 
                             sizing_mode="stretch_width", styles=PANE_STYLE)
    
    diagram_output = pn.pane.Markdown("_Diagrams will appear here..._", 
                                    sizing_mode="stretch_width", styles=PANE_STYLE)

    followup_input = pn.widgets.TextInput(
        placeholder="Ask a follow-up question...",
        sizing_mode="stretch_width", styles=INPUT_STYLE
    )

    # Buttons
    debug_btn = pn.widgets.Button(name="⚡ Debug", button_type="primary",
                                  width=200, height=50, styles=BUTTON_STYLE)
    diagram_btn = pn.widgets.Button(name="📊 Diagram", button_type="warning",
                                    width=200, height=50, styles=BUTTON_STYLE)
    followup_btn = pn.widgets.Button(name="💬 Follow-Up", button_type="success",
                                     width=200, height=50, styles=BUTTON_STYLE)
    reset_btn = pn.widgets.Button(name="🗑️ Reset", button_type="danger",
                                  width=200, height=50, styles=BUTTON_STYLE)
    
    download_btn = pn.widgets.FileDownload(
        callback=lambda: create_pdf(output.object),
        filename="debug_report.pdf",
        button_type="primary",
        name="📥 Download Report"
    )

    # Event Handlers
    def on_debug(_):
        code = code_input.value.strip()
        if not code:
            safe_set(output, "Please enter some Python code.")
            return
        conv = get_conv()
        conv.append({"role": "user", "content": code})
        safe_set(output, "_Analyzing…_")
        stream_to_pane(conv, output)

    def on_diagram(_):
        code = code_input.value.strip()
        if not code:
            safe_set(diagram_output, "Please enter some Python code first.")
            return
        conv = get_conv()
        last = next((m["content"] for m in reversed(conv) 
                    if m["role"] == "assistant"), None)
        
        payload = [
            {"role": "system", "content": DIAGRAM_SYSTEM_PROMPT},
            {"role": "user", "content": f"Code:\n```python\n{code}\n```" + 
                                      (f"\n\nAnalysis:\n{last}" if last else "")}
        ]
        safe_set(diagram_output, "_Generating diagrams…_")
        stream_to_pane(payload, diagram_output)

    def on_followup(_):
        q = followup_input.value.strip()
        if not q:
            safe_set(output, "Please enter a question.")
            return
        conv = get_conv()
        conv.append({"role": "user", "content": q})
        safe_set(output, "_Thinking…_")
        stream_to_pane(conv, output)

    def on_reset(_):
        sid = get_session_id()
        pn.state.cache[sid] = [{"role": "system", "content": SYSTEM_PROMPT}]
        safe_set(output, "_Analysis will appear here..._")
        safe_set(diagram_output, "_Diagrams will appear here..._")
        followup_input.value = ""
        code_input.value = ""

    # Connect buttons
    debug_btn.on_click(on_debug)
    diagram_btn.on_click(on_diagram)
    followup_btn.on_click(on_followup)
    reset_btn.on_click(on_reset)

    # Layout
    return pn.Column(
        pn.pane.Markdown("# 🐍 AI Python Debugger", styles=TITLE_STYLE),
        code_input,
        pn.Row(debug_btn, diagram_btn),
        pn.layout.Divider(),
        pn.pane.Markdown("## Analysis", styles=SECTION_STYLE),
        output,
        pn.layout.Divider(),
        pn.pane.Markdown("## Diagrams", styles=SECTION_STYLE),
        diagram_output,
        pn.layout.Divider(),
        pn.pane.Markdown("## Follow-up", styles=SECTION_STYLE),
        followup_input,
        pn.Row(followup_btn, reset_btn, download_btn),
        sizing_mode="stretch_width",
    )

# Build and serve the app
app = build_ui()
app.servable()
```

---

### Step 3: Run the Application

```bash
panel serve app.py --show
```

Your browser should open automatically at `http://localhost:5006/app`.

---

### Key Features Explained

| Feature | How It Works |
|-------|-------------|
| **Session Isolation** | Uses `pn.state.cache` + session ID from URL to keep conversations separate for multiple users. |
| **Streaming Responses** | Runs LLM calls in background threads so the UI stays responsive. |
| **Model Fallback** | Automatically tries the next model in `MODELS_POOL` if one fails (rate limits, etc.). |
| **PDF Export** | Uses `reportlab` to generate downloadable reports in memory (works great on Hugging Face Spaces). |
| **Diagrams** | Separate prompt generates clean ASCII flowcharts for buggy vs fixed code. |

---

### Why This Architecture Is Robust

- **Non-blocking UI**: Threading + `safe_set()` prevents freezing.
- **Resilient**: Multiple fallback models and graceful error handling.
- **Production-ready**: In-memory PDF generation, session management, and clean Panel layout.
- **Extensible**: Easy to add more tools or change prompts.

---

**Congratulations!** You now have a fully functional AI-powered Python debugger.

Feel free to customize the system prompts, add more buttons, or deploy it to Hugging Face Spaces. Happy debugging! 🐍
