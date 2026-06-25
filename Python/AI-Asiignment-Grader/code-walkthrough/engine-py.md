**✅ Code Walkthrough: `engine.py` — AI Orchestration & Grading Core**

---

## Module Deep Dive: `engine.py` — AI Pipeline, Subject Detection, and Model Racing

This module is the **brain** of the Markly project. It transforms the normalized text and images from `utils.py` into structured teacher feedback, grades, and machine-readable markup instructions. It handles prompt engineering, asynchronous AI calls via OpenRouter, model racing for reliability, subject-specific rubrics, and structured output for downstream visual annotations.

### 1. Imports and Client Setup
```python
import os
import asyncio
import re
from dotenv import load_dotenv
from openai import AsyncOpenAI
```

**Why this block exists**  
It equips the module with everything needed for secure configuration, asynchronous AI communication, and text parsing. `AsyncOpenAI` enables efficient concurrent requests to multiple models.

**Python concepts used**  
- Module imports (standard library + third-party)  
- `asyncio` for non-blocking I/O  
- `re` for robust post-processing of AI output  
- Environment-based configuration via `dotenv`

**Pattern analysis**  
**Setup & dependency declaration** block — all foundational tools are loaded upfront.

**What if**  
Removing `asyncio` would break all async functions, forcing synchronous (slower) calls and reducing the effectiveness of model racing.

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

**Why this block exists**  
Securely loads the OpenRouter API key and creates a single reusable async client for all AI interactions.

**Python concepts used**  
- Environment variable loading and safe retrieval  
- Client instantiation with configuration keywords  

**Pattern analysis**  
**Shared service object** pattern — one client instance reused across the entire module.

**What if**  
A mismatched environment variable name would cause all AI calls to fail, highlighting the importance of consistent configuration.

---

### 3. Prompt Templates
```python
SUBJECT_DETECTION_PROMPT = """..."""
# Similar constants exist for: JSON_SCHEMA_PROMPT, MATH_MARKING_PROMPT, ENGLISH_MARKING_PROMPT, etc.
```

**Why this block exists**  
Centralized, reusable instructions that guide the AI’s behavior for different tasks (subject classification, subject-specific marking, structured JSON output, vision analysis).

**Python concepts used**  
- Triple-quoted multiline strings  
- Constant naming convention (UPPER_CASE)  

**Pattern analysis**  
**Prompt engineering as code** — separating instructions from logic makes prompts easier to tune and version.

**What if**  
Removing constraints like “Return ONLY the word” from the subject prompt would lead to noisier, less parseable outputs.

---

### 4. Subject Prompt Mapping
```python
SUBJECT_PROMPTS = {
    "Mathematics": MATH_MARKING_PROMPT,
    "English": ENGLISH_MARKING_PROMPT,
    "Science": SCIENCE_MARKING_PROMPT,
    "Programming": PROGRAMMING_MARKING_PROMPT,
}
```

**Why this block exists**  
Routes grading logic to the appropriate subject-specific rubric and tone.

**Python concepts used**  
- Dictionary as a dispatch table  
- Safe lookup with `.get(subject, default)`  

**Pattern analysis**  
**Strategy / dispatch table** pattern — avoids lengthy `if-elif` chains and makes adding new subjects trivial.

**What if**  
Adding `"History": HISTORY_MARKING_PROMPT` demonstrates the scalability of this design.

---

### 5. Vision Prompt
```python
VISION_PROMPT = """Analyze the assignment and provide: Strengths, Mistakes, Suggestions, Final Grade"""
```

**Why this block exists**  
Provides a clear checklist for multimodal (vision) models when grading image-based submissions.

**Pattern analysis**  
**Concern separation** — prompt text is defined once and reused.

---

### 6. Model Pool
```python
MODELS_POOL = [
    "openai/gpt-oss-20b:free",
    "qwen/qwen3-coder:free",
    "google/gemma-4-31b-it:free",
    "meta-llama/llama-3.3-70b-instruct:free",
]
```

**Why this block exists**  
Enables model racing — multiple models compete to provide the fastest reliable response.

**Pattern analysis**  
**Fallback & redundancy** strategy for resilience and speed.

---

### 7. Grade Extraction Helper
```python
def extract_grade(text: str) -> str:
    # Regex patterns for common grade formats (X/10, A-, 85/100, etc.)
```

**Why this block exists**  
Extracts a clean grade from free-form AI responses, bridging unstructured LLM output with structured data.

**Python concepts used**  
- Type hints, regex pattern matching, defensive programming  

**Pattern analysis**  
**Robust post-processing parser** — compensates for variability in model outputs.

---

### 8. Subject Detection
```python
async def detect_subject(content):
    # Uses a cheap/fast model with temperature=0 for consistent classification
```

**Why this block exists**  
Determines the academic subject when the user doesn’t specify one, enabling the correct rubric and persona.

**Key dependency**: Relies on clean `extracted_text` from `utils.py`.

---

### 9. Single-Model Request Helper
```python
async def ask_ai(prompt, model_name, timeout=10.0):
    # Try/except wrapper around the API call
```

**Why this block exists**  
Encapsulates a single API request with error tolerance.

**Pattern analysis**  
**Error-tolerant wrapper** — isolates low-level details.

---

### 10. Concurrent Model Racing
```python
async def get_ai_response_concurrently(prompt, timeout=10.0):
    # Launches all models in parallel, returns first successful result
```

**Why this block exists**  
The heart of reliability: races multiple models and takes the winner, cancelling the rest.

**Python concepts used**  
- `asyncio.create_task`, `asyncio.wait(..., FIRST_COMPLETED)`, task cancellation  

**Pattern analysis**  
**Orchestration with concurrency** — dramatically improves speed and resilience.

---

### 11–13. Image Grading Functions
```python
async def grade_image(image_base64, subject):
    # Multimodal call with vision model

async def grade_image_with_markup(image_base64, subject):
    # Structured JSON output for visual annotations
```

**Why these exist**  
Handle visual assignments by sending both text instructions and base64 images to multimodal models (e.g., GPT-4o), with optional strict JSON formatting for markup generation.

**Key dependency**: `image_to_base64()` output from `utils.py`.

---

### 14. Text-Based Assignment Judging
```python
async def judge_assignment(content, rubric):
    # Builds prompt + delegates to concurrent racing
```

**Why this block exists**  
Main entry point for text-only submissions, combining rubric, student work, and model racing.

---

### 15. Main Guard
```python
if __name__ == "__main__":
    asyncio.run(asyncio.sleep(0))  # Placeholder for testing
```

**Why this block exists**  
Standard Python entry point that keeps the module import-safe.

---

## Big-Picture Reading of `engine.py`

`engine.py` is the **orchestration and intelligence layer** of Markly. It connects the dots between:

- Clean input from `utils.py` (text + optional base64 image)
- Subject detection → rubric & persona selection
- Prompt construction → concurrent AI calls (model racing)
- Structured output → `markup.py`, `report.py`, and `storage.py`

### Core Design Principles Demonstrated
- **Separation of concerns**: Prompt templates, API helpers, orchestration, and parsing are cleanly divided.
- **Resilience**: Model racing + error handling + graceful fallbacks.
- **Extensibility**: Easy to add subjects, models, or new prompt styles.
- **Performance**: Heavy use of `asyncio` and `FIRST_COMPLETED` racing.
- **Quality control**: Temperature=0 for detection, JSON mode for markup, regex parsing for grades.

This architecture turns raw student work into consistent, teacher-like feedback while remaining fast and fault-tolerant.

---

**How it fits the overall pipeline**  
`utils.py` → **engine.py** (this module) → `markup.py` (visual annotations) → `report.py` (PDF) → `storage.py` (history).

