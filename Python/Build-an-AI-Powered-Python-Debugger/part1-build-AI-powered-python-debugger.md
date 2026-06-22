# Build an AI-Powered Python Debugger Using OpenRouter

## Overview

Artificial intelligence has evolved into an essential programming assistant. Rather than manually parsing stack traces or scouring forums for solutions, you can build a streamlined application that analyzes Python code, explains errors, and suggests robust fixes automatically.

In this series, you will build a complete, resilient AI-powered Python debugger using:

* **Python** – the core logic engine
* **Panel** – a powerful library for creating high-performance web interfaces using pure Python [github](https://github.com/holoviz/panel)
* **OpenRouter** – a universal API gateway to access various LLMs (including a resilient fallback pool of free models) via an OpenAI-compatible interface [openrouter](https://openrouter.ai/)

Unlike many tutorials that break when a single free API endpoint experiences heavy traffic, this project implements a **multi-model fallback architecture** using OpenRouter's free tier, making it both completely free to run and highly reliable.

---

## What You’ll Build

Your final application will feature a fluid, production-ready interactive dashboard:

| Component | Functionality |
| --- | --- |
| Code Input | A syntax-highlighted editor for your Python code. [panel.holoviz](https://panel.holoviz.org/reference/widgets/CodeEditor.html) |
| Fallback Engine | Automatically cycles through alternative free LLMs if one hits a rate limit. |
| Analysis Engine | Auto-generates explanations, fixes, and unit tests without raw chain-of-thought clutter. |
| Follow-up Chat | A conversational interface to refine the AI’s suggestions. |
| Dynamic UI | Responsive controls with side-by-side action buttons and fluid layouts. |

By the end, your debugger will:

* Identify bugs and explain the root cause of errors
* Provide clean, corrected code and suggest unit tests
* Gracefully bypass API rate limits using an LLM pool
* Support follow-up questions about the same code
* Be testable with `pytest` [geeksforgeeks](https://www.geeksforgeeks.org/python/getting-started-with-pytest/)
* Be packaged and ready for headless hosting (e.g., Hugging Face Spaces)

---

## Prerequisites

You should have:

* **Python 3.10+** installed
* A **code editor** (e.g., VS Code)
* **Foundational knowledge**: Basic familiarity with functions and executing terminal commands.

---

# Phase 1: Setup & Environment

## Step 1 – Project Initialization

Create your workspace and isolate your dependencies to ensure a clean build.

```bash
mkdir ai-debugger
cd ai-debugger
python -m venv venv

```

Activate the virtual environment:

* **Windows**:

```bash
venv\Scripts\activate

```

* **macOS/Linux**:

```bash
source venv/bin/activate

```

When active, your prompt will display `(venv)`.

---

## Step 2 – Dependencies

Install the necessary libraries to handle the web UI, API requests, and testing:

```bash
pip install panel openai python-dotenv pytest

```

Packages explained:

* **Panel** – Builds the web interface using pure Python.
* **OpenAI SDK** – Communicates with OpenRouter via an OpenAI-compatible API.
* **python-dotenv** – Loads environment variables securely from a `.env` file.
* **pytest** – Testing framework used to verify the AI's generated code solutions.

---

## Step 3 – API Configuration

### Register

* Sign up at [OpenRouter.ai](https://openrouter.ai/).
* Navigate to your dashboard and create a new API key.

### Environment File

Create a `.env` file in your project root directory:

```env
OPENROUTER_API_KEY=your_api_key_here

```

> ⚠️ **Security Note:** Never hard-code your API keys. Add `.env` to your `.gitignore` file immediately to prevent public exposure.

---

# Phase 2: Building the Logic

## Step 4 – The Core Application (`app.py`)

### Create the File

In your project root, create `app.py`.

### Initialize Configuration and Client

```python
import os
import panel as pn
from dotenv import load_dotenv
from openai import OpenAI

# Load configuration from .env file
load_dotenv()

# Debug: check if the variable is loaded properly
print(f"DEBUG: API Key loaded: {os.getenv('OPENROUTER_API_KEY') is not None}")

# Initialize the Panel extension explicitly loading 'codeeditor' assets 
# to prevent WebSocket timeouts on headless hosting setups like Hugging Face
pn.extension('codeeditor')

# Agent Configuration: Define stable free models to iterate through if one fails
MODELS_POOL = [
    "openai/gpt-oss-20b:free",
    "cohere/north-mini-code:free",
    "meta-llama/llama-3.2-3b-instruct:free"
]

# Initialize OpenRouter Client with explicit identification headers
client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1",
    default_headers={
        "HTTP-Referer": "https://huggingface.co/spaces/seanwhs/AI-Enabled-Python-Debugger",
        "X-Title": "AI Enabled Python Debugger"
    }
)

```

### Explanation:

* **`pn.extension('codeeditor')`**: Explicitly loads the code editor components. This is crucial for cloud setups (like Hugging Face Spaces) to prevent asset loading delays and WebSocket timeouts.
* **`MODELS_POOL`**: Rather than relying on a single model, we declare an array of capable, free-tier models to serve as immediate fallbacks.
* **`default_headers`**: OpenRouter requires these headers to correctly rank and display your app on public leaderboard platforms.

---

## Step 5 – Defining the System Prompt

The system prompt defines the personality, goals, and strict response formatting constraints for your AI agent.

```python
SYSTEM_PROMPT = """
You are an expert Python debugging assistant. 
Do not include your internal reasoning or chain-of-thought process in the final output 
unless requested.

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

# Initialize conversation history with the system role
conversation_messages = [
    {
        'role': 'system', 
        'content': SYSTEM_PROMPT
    }
]

```

> 💡 **Key Cleanliness Choice:** The instruction *"Do not include your internal reasoning or chain-of-thought process"* keeps the UI clean by filtering out raw `<think>` tokens used by modern reasoning models.

---

# Phase 3: UI & Interactivity

## Step 6 – Implementing Resilient Streamed Responses

To prevent the web page from freezing during heavy API loads, we use a generator function to stream text chunks. We also wrap our API calls in an error-handling loop that automatically falls back to alternative models if a rate limit (`HTTP 429`) is hit.

```python
def debug_code_stream(code: str, instance: None = None):
    """
    Generator that yields chunks of the model's response as they arrive,
    while iterating through a fallback pool if rate limits are hit.
    """
    conversation_messages.append({'role': 'user', 'content': code})
    
    stream = None
    # Try each model in the pool sequentially if an error occurs (like a 429)
    for model in MODELS_POOL:
        try:
            stream = client.chat.completions.create(
                model=model,
                messages=conversation_messages,
                max_tokens=2048,
                stream=True
            )
            break  # Successfully acquired a stream, break out of the loop
        except Exception as e:
            print(f"Model {model} failed with error: {e}. Trying next fallback...")
            continue
            
    if not stream:
        yield "⚠️ **Error:** All free OpenRouter endpoints are currently swamped or unavailable. Please try again in a few moments."
        return

    full_reply = ''
    # Process and yield chunks as they arrive from the working API connection
    for chunk in stream:
        if chunk.choices[0].delta.content:
            text = chunk.choices[0].delta.content
            full_reply += text
            yield text
            
    # Store the final full AI response in history to maintain context
    conversation_messages.append({'role': 'assistant', 'content': full_reply})

```

---

## Step 7 – Finalizing the Interactive UI Layout

Now, we create our Panel widgets, define how user actions run our streaming logic, and set up a clean layout.

```python
# Create Widgets
code_input = pn.widgets.CodeEditor(
    name='Python Code',
    language='python',
    height=350,
    sizing_mode='stretch_width',
)
    
debug_button = pn.widgets.Button(
    name='Debug Code',
    button_type='primary',
    sizing_mode='stretch_width'
)

followup_input = pn.widgets.TextInput(
    name='Follow-Up Question',
    placeholder='Ask a question about the previous analysis...',
    sizing_mode='stretch_width'
)

followup_button = pn.widgets.Button(
    name='Ask Follow-Up',
    button_type='light',
    sizing_mode='stretch_width'
)

reset_button = pn.widgets.Button(
    name='Reset Conversation',
    button_type='danger',
    sizing_mode='stretch_width'
)

# UI FIX: No hardcoded height. The component expands dynamically with content.
output = pn.pane.Markdown(
    '### AI Analysis will appear here...',
    sizing_mode='stretch_width',
    margin=(15, 5, 15, 5)
)
    
# Define Event Handlers (The "Glue" between logic and UI)
def on_click(event):
    code = code_input.value.strip()
    if not code:
        output.object = "Please enter some Python code."
        return

    output.object = "Analyzing...\n"
    try:
        full_text = ""
        for chunk in debug_code_stream(code, None):
            full_text += chunk
            output.object = full_text
    except Exception as e:
        output.object = f"Error: {e}"

def on_followup(event):
    question = followup_input.value.strip()
    if not question:
        output.object = "Please enter a follow-up question."
        return

    output.object = "Thinking about your follow-up...\n"
    try:
        full_text = ""
        for chunk in debug_code_stream(question, None):
            full_text += chunk
            output.object = full_text
    except Exception as e:
        output.object = f"Error: {e}"

def on_reset(event):
    global conversation_messages
    conversation_messages = [{'role': 'system', 'content': SYSTEM_PROMPT}]
    output.object = "Conversation reset. Paste new code to start a fresh analysis."
    followup_input.value = ""
    code_input.value = ""

# Link Buttons to Event Handlers
debug_button.on_click(on_click)
followup_button.on_click(on_followup)
reset_button.on_click(on_reset)

# Define Layout (Stack Components fluidly)
app = pn.Column(
    "# 🐍 AI Python Debugger",
    code_input,
    debug_button,
    pn.layout.Divider(), # Visual separation before output
    output,
    pn.layout.Divider(), # Visual separation after output
    "## 💬 Follow-up Conversation",
    followup_input,
    pn.Row(followup_button, reset_button), # Placed bottom action buttons side-by-side
    width=800,
    sizing_mode='stretch_width'
)

app.servable()

```

### Key UI Enhancements:

* **`pn.Row(followup_button, reset_button)`**: Positions related actions efficiently on the same line to save screen space.
* **`pn.layout.Divider()`**: Clean horizontal rules help separate user inputs from the AI's output.
* **Dynamic Output Resizing**: Removing `height=400` from the markdown pane prevents responses from getting cut off or forcing unnecessary inner scrollbars.

---

# Phase 4: Deployment & Testing

## Step 8 – Launching the Application

From your root project directory (with your virtual environment active), run the server command:

```bash
panel serve app.py --show

```

Your default browser will automatically open to `http://localhost:5006/app`.

---

## Step 9 – Verification & Testing

### Test Case 1: Out-of-Bounds Error

Paste the following broken snippet into the **Python Code** window and click **Debug Code**:

```python
numbers = [1, 2, 3]
print(numbers[5])

```

The AI response panel will dynamically stream responses into your structured Markdown sections: `## Error`, `## Explanation`, `## Fixed Code`, and `## Unit Tests`.

### Test Case 2: Multi-Turn Conversation

In the **Follow-Up Question** input box below the output, type:

> *"Can you rewrite the fix using a try-except block instead?"*

Click **Ask Follow-Up**. Thanks to our chat history array management, the model remembers your code snippet and modifies its earlier response contextually.

---

## Step 10 – Project Directory Blueprint

Your finalized, production-ready workspace structure should look exactly like this:

```text
ai-debugger/
├── app.py
├── .env
├── .gitignore
├── requirements.txt
└── README.md

```

### `.gitignore`

```gitignore
venv/
.env
__pycache__/
.pytest_cache/

```

### `requirements.txt`

```txt
panel
openai
python-dotenv
pytest

```
