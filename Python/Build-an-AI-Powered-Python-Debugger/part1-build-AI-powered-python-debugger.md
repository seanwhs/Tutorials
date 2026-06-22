# Build an AI-Powered Python Debugger Using OpenRouter  
## A Comprehensive Multi-Part Tutorial Series

***

## Overview

Artificial intelligence has evolved into an essential programming assistant. Rather than manually parsing stack traces or scouring forums for solutions, you can build a streamlined application that analyzes Python code, explains errors, and suggests robust fixes automatically.

In this series, you will build a complete AI-powered Python debugger using:

- **Python** – the core logic engine  
- **Panel** – a powerful library for creating high-performance web interfaces using pure Python [github](https://github.com/holoviz/panel)
- **OpenRouter** – a universal API gateway to access various LLMs (including free models) via an OpenAI-compatible interface [openrouter](https://openrouter.ai/deepseek/deepseek-r1:free%C2%A0for)

Unlike many tutorials that require paid OpenAI keys, this project uses **OpenRouter with a free model**, making it accessible to anyone.

***

## What You’ll Build

Your final application will feature a clean, interactive dashboard:

| Component        | Functionality                                                           |
|-----------------|-------------------------------------------------------------------------|
| Code Input      | A syntax-highlighted editor for your Python code.  [panel.holoviz](https://panel.holoviz.org/reference/widgets/CodeEditor.html)     |
| Analysis Engine | Auto-generates explanations, fixes, and unit tests.                    |
| Follow-up Chat  | A conversational interface to refine the AI’s suggestions.             |
| Reset Control   | Clears the state to start fresh debugging sessions.                    |

By the end, your debugger will:

- Identify bugs in Python code  
- Explain the root cause of errors  
- Provide corrected code  
- Suggest unit tests  
- Support follow-up questions about the same code  
- Be testable with `pytest` [geeksforgeeks](https://www.geeksforgeeks.org/python/getting-started-with-pytest/)
- Be packaged and ready to share with others  

***

## Prerequisites

You should have:

- **Python 3.10+** installed  
- A **code editor** (e.g., VS Code)  
- **Foundational knowledge**:
  - Basic familiarity with functions  
  - Ability to execute scripts from the terminal  

If you can run a simple `print("Hello, world!")` script, you’re ready.

***

# Phase 1: Setup & Environment

## Step 1 – Project Initialization

Create your workspace and isolate your dependencies to ensure a clean build.

```bash
mkdir ai-debugger
cd ai-debugger
python -m venv venv
```

Activate the virtual environment:

- **Windows**:

```bash
venv\Scripts\activate
```

- **macOS/Linux**:

```bash
source venv/bin/activate
```

When active, your prompt usually starts with `(venv)`.

***

## Step 2 – Dependencies

Install the necessary libraries to handle the web UI, API requests, and testing:

```bash
pip install panel openai python-dotenv pytest
```

Packages explained:

- **Panel** – builds the web interface using pure Python. [github](https://github.com/holoviz/panel)
- **OpenAI SDK** – communicates with OpenRouter via an OpenAI-compatible API. [openrouter](https://openrouter.ai/docs/guides/routing/routers/free-router)
- **python-dotenv** – loads environment variables from a `.env` file. [medium](https://medium.com/pythoneers/environment-variables-in-python-with-the-dotenv-env-module-f2e40df6dbc9)
- **pytest** – testing framework used in later parts. [testdriven](https://testdriven.io/blog/pytest-for-beginners/)

***

## Step 3 – API Configuration

### Register

- Sign up at [OpenRouter.ai](https://openrouter.ai/).  
- Create an API key in your dashboard.

### Environment File

Create a `.env` file in your root folder:

```env
OPENROUTER_API_KEY=your_api_key_here
```

Replace `your_api_key_here` with your actual key.

### Security Note

- **Never** hard-code API keys in your source code.  
- Add `.env` to your `.gitignore` to prevent accidental exposure of credentials.

***

# Phase 2: Building the Logic

## Step 4 – The Core Application (`app.py`)

### Create the File

In your project root, create `app.py`.

### Initialize the Application

```python
import os

import panel as pn

from dotenv import load_dotenv
from openai import OpenAI

# Load configuration
load_dotenv()
pn.extension()

# Initialize client pointing to OpenRouter
client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1",
)

MODEL_NAME = "deepseek/deepseek-r1-0528:free"
```

Explanation:

- `load_dotenv()` reads your `.env` file. [geeksforgeeks](https://www.geeksforgeeks.org/python/using-python-environment-variables-with-python-dotenv/)
- `pn.extension()` initializes Panel’s JavaScript/CSS resources. [github](https://github.com/holoviz/panel)
- The `OpenAI` client is configured with:
  - Your API key from the environment  
  - `base_url` pointing to OpenRouter instead of OpenAI [openrouter](https://openrouter.ai/deepseek/deepseek-r1:free%C2%A0for)
- `MODEL_NAME` selects a free model from OpenRouter. [openrouter](https://openrouter.ai/deepseek/deepseek-r1:free)

***

## Step 5 – Defining the System Prompt

The system prompt defines the “personality” and output structure of your debugger.

```python
SYSTEM_PROMPT = """
You are an expert Python debugging assistant.

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
```

This prompt:

- Tells the AI its role (expert debugging assistant).  
- Defines exactly how to respond.  
- Requests unit tests in a `## Unit Tests` section.

***

# Phase 3: UI & Interactivity

## Step 6 – Implementing Streamed Responses

To keep the UI responsive, we use a generator function to stream tokens as they arrive from the API.

```python
conversation_messages = [
    {
        "role": "system",
        "content": SYSTEM_PROMPT,
    }
]

def debug_code_stream(code: str):
    """
    Generator that yields chunks of the model's response as they arrive,
    while preserving conversation history.
    """
    # Add user message to conversation history
    conversation_messages.append(
        {
            "role": "user",
            "content": code,
        }
    )

    stream = client.chat.completions.create(
        model=MODEL_NAME,
        messages=conversation_messages,
        stream=True,
    )

    full_reply = ""

    for chunk in stream:
        delta = chunk.choices[0].delta
        if delta and delta.content:
            text = delta.content
            full_reply += text
            yield text

    # Store AI response in history
    conversation_messages.append(
        {
            "role": "assistant",
            "content": full_reply,
        }
    )
```

Key concepts:

- `stream=True` tells the API to send chunks instead of one big response.  
- The `yield` statement makes this a generator, so you can iterate over chunks.  
- `conversation_messages` preserves history for follow-up questions.

***

## Step 7 – Finalizing the UI

Use `pn.widgets` to create the input areas and connect them to the processing functions defined in Step 6. Finish by calling `.servable()` to prepare the app for the Panel server.

### Create Widgets

```python
code_input = pn.widgets.CodeEditor(
    name="Python Code",
    language="python",
    height=350,
    sizing_mode="stretch_width",
)

debug_button = pn.widgets.Button(
    name="Debug Code",
    button_type="primary",
)

followup_input = pn.widgets.TextInput(
    name="Follow-up Question",
    placeholder="Ask a question about the previous analysis...",
)

followup_button = pn.widgets.Button(
    name="Ask Follow-up",
    button_type="secondary",
)

reset_button = pn.widgets.Button(
    name="Reset Conversation",
    button_type="danger",
)

output = pn.pane.Markdown(
    "AI analysis will appear here.",
    height=400,
)
```

- `CodeEditor` provides syntax highlighting and line numbers. [panel.holoviz](https://panel.holoviz.org/reference/widgets/CodeEditor.html)
- `TextInput` and buttons enable follow-up questions.  
- `Markdown` renders the AI’s response with headings and code blocks.

### Wire Interactions

```python
def on_click(event):
    code = code_input.value.strip()

    if not code:
        output.object = "Please enter some Python code."
        return

    output.object = "Analyzing...\n"

    try:
        full_text = ""
        for chunk in debug_code_stream(code):
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
        for chunk in debug_code_stream(question):
            full_text += chunk
            output.object = full_text
    except Exception as e:
        output.object = f"Error: {e}"


def on_reset(event):
    global conversation_messages
    conversation_messages = [
        {
            "role": "system",
            "content": SYSTEM_PROMPT,
        }
    ]
    output.object = "Conversation reset. Paste new code to start a fresh analysis."
    followup_input.value = ""
    code_input.value = ""


debug_button.on_click(on_click)
followup_button.on_click(on_followup)
reset_button.on_click(on_reset)
```

### Layout

```python
app = pn.Column(
    "# AI Python Debugger",
    code_input,
    debug_button,
    output,
    "## Follow-up",
    followup_input,
    followup_button,
    reset_button,
    width=800,
)

app.servable()
```

`pn.Column` stacks everything vertically. [github](https://github.com/holoviz/panel)

***

# Phase 4: Deployment & Testing

## Step 8 – Launch the Application

From the `ai-debugger` directory (with your virtual environment active):

```bash
panel serve app.py --show
```

Your browser opens automatically with the debugger interface. [github](https://github.com/holoviz/panel/blob/main/panel/__init__.py)

***

## Step 9 – Test the Debugger

### Test 1 – IndexError

Paste this code:

```python
numbers = [1, 2, 3]
print(numbers [panel.holoviz](https://panel.holoviz.org/api/panel.widgets.codeeditor.html))
```

The AI should:

- Identify the `IndexError`  
- Explain why index 5 is out of range  
- Show corrected code  
- Suggest unit tests  

### Test 2 – NameError

```python
name = "Alice"
print(age)
```

The AI should identify a `NameError` and explain that `age` is not defined.

***

## Step 10 – Run Unit Tests with `pytest`

### Create a Test File

1. Create a `tests` folder:

```bash
mkdir tests
```

2. Create `tests/test_debugger_examples.py`.

3. Copy the AI’s suggested tests into this file.

### Create Sample Functions

Create `code_examples.py` in the project root:

```python
def divide(a, b):
    return a / b

def get_item(lst, index):
    return lst[index]
```

Adjust imports in your test file to match these functions.

### Run Tests

```bash
pytest
```

You should see green dots for passing tests and a summary like `2 passed in 0.03s`.

***

## Step 11 – Project Structure

Ensure your directory follows standard practices:

```text
ai-debugger/
├── app.py
├── code_examples.py
├── tests/
│   └── test_debugger_examples.py
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

Install with:

```bash
pip install -r requirements.txt
```

### README

Add a `README.md` with:

- Project description  
- Features  
- Setup instructions  
- Usage examples  
- Project structure  

This documents usage instructions for other developers and makes your project shareable.

***

## Next Steps

This framework provides a scalable foundation. From here, you can extend the project by adding features like:

- File-upload support  
- Advanced linting tools  
- Multi-language support (e.g., JavaScript)  
- Abort/stop controls for long-running AI responses  
- Enhanced prompt engineering for better unit test generation  

***
