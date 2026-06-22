Here is a more beginner-friendly, step‑by‑step version of your tutorial, with all key concepts and libraries explained in plain language.

***

## Overview: What You’re Building

In this tutorial, you’ll build a simple **AI-powered Python debugger**.  

You’ll paste some Python code into a web page, click a **Debug Code** button, and an AI model will:

- Read your code  
- Find possible errors  
- Explain what went wrong  
- Suggest a fixed version of the code  

You will use:

- **Python** – the programming language running everything  
- **Panel** – a Python library for building simple web apps and dashboards without writing HTML/CSS/JS yourself [github](https://github.com/holoviz/panel)
- **OpenRouter** – a service that lets you call many different AI models (including free ones) through an API that looks like the OpenAI API [openrouter](https://openrouter.ai/deepseek/deepseek-r1:free%C2%A0for)
- **python-dotenv** – a small helper that loads secrets (like API keys) from a `.env` file into environment variables [medium](https://medium.com/pythoneers/environment-variables-in-python-with-the-dotenv-env-module-f2e40df6dbc9)

You will not need a paid OpenAI key—this tutorial uses **OpenRouter** and a **free model**.

***

## Prerequisites (Beginner-Friendly)

You should have:

- **Python 3.10 or newer** installed on your machine  
- **Basic Python knowledge**  
  - You should know what a function is  
  - You should be able to run a `.py` file from the terminal  
- A **code editor**  
  - **VS Code** is recommended, but any editor is fine  

If you can print `"Hello, world!"` from a `.py` file, you’re good to go.

***

## Step 1 – Create the Project Folder

1. Open your **terminal** (Command Prompt, PowerShell, or a shell).  
2. Run:

```bash
mkdir ai-debugger
cd ai-debugger
```

- `mkdir ai-debugger` creates a new folder named `ai-debugger`.  
- `cd ai-debugger` moves you into that folder so all files you create are inside this project.

***

## Step 2 – Create and Activate a Virtual Environment

A **virtual environment** keeps the Python packages for this project isolated from other projects.

### On Windows

```bash
python -m venv venv
venv\Scripts\activate
```

### On macOS / Linux

```bash
python3 -m venv venv
source venv/bin/activate
```

What these do:

- `python -m venv venv` creates a folder called `venv` that contains its own Python and installed packages.  
- `activate` tells your terminal to use Python and packages from this `venv` for the current session.

You’ll know it’s active if your prompt starts with `(venv)` or similar.

***

## Step 3 – Install the Required Python Packages

Run:

```bash
pip install panel openai python-dotenv
```

What these packages are:

- **Panel**  
  - A Python library to build web apps and dashboards.  
  - It lets you build pages using Python objects like buttons, text areas, and layouts. [github](https://github.com/holoviz/panel)

- **OpenAI (Python SDK)**  
  - This is the official Python client library for OpenAI’s API.  
  - OpenRouter intentionally uses an API that looks the same, so we can use this SDK to talk to OpenRouter as well. [openrouter](https://openrouter.ai/docs/guides/routing/routers/free-router)

- **python-dotenv**  
  - Loads values from a `.env` file (like your API key) into environment variables so you don’t hard-code secrets in your code. [geeksforgeeks](https://www.geeksforgeeks.org/python/using-python-environment-variables-with-python-dotenv/)

***

## Step 4 – Create an OpenRouter Account and API Key

1. Go to: https://openrouter.ai  
2. Sign up for a free account.  
3. Navigate to your **API keys** page and create an API key.  

This key is a secret token that proves “this request is from your account” when you call OpenRouter’s API. [openrouter](https://openrouter.ai/deepseek/deepseek-r1:free%C2%A0for)

***

## Step 5 – Store Your API Key Safely with `.env`

In your `ai-debugger` folder:

1. Create a file named `.env` (no name, just `.env`).  
2. Add this line to the file, replacing the placeholder with your real key:

```env
OPENROUTER_API_KEY=your_api_key_here
```

Important:

- **Do not** put your real API key in your Python files.  
- If you use Git, add `.env` to `.gitignore` so you never commit it. [medium](https://medium.com/pythoneers/environment-variables-in-python-with-the-dotenv-env-module-f2e40df6dbc9)

***

## Step 6 – Create the Main Application File

In your `ai-debugger` folder, create a new file called:

```text
app.py
```

This file will contain all the code for your debugger.

***

## Step 7 – Import the Libraries

Open `app.py` and paste:

```python
import os

import panel as pn

from dotenv import load_dotenv
from openai import OpenAI
```

What these imports do:

- `os` – Python’s standard library module for interacting with the operating system, including reading environment variables.  
- `panel as pn` – imports the Panel library and gives it the short name `pn`.  
- `load_dotenv` – a function from `python-dotenv` to load the `.env` file. [geeksforgeeks](https://www.geeksforgeeks.org/python/using-python-environment-variables-with-python-dotenv/)
- `OpenAI` – the client class from the OpenAI Python SDK that we’ll configure to talk to OpenRouter. [openrouter](https://openrouter.ai/deepseek/deepseek-r1:free%C2%A0for)

***

## Step 8 – Load Environment Variables from `.env`

Still in `app.py`, add:

```python
load_dotenv()
```

This line:

- Reads your `.env` file.  
- Makes `OPENROUTER_API_KEY` available as an environment variable. [medium](https://medium.com/pythoneers/environment-variables-in-python-with-the-dotenv-env-module-f2e40df6dbc9)

Later, you’ll access it via `os.getenv("OPENROUTER_API_KEY")`.

***

## Step 9 – Create the OpenRouter Client

Add this code next:

```python
client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1",
)
```

Explanation:

- `api_key=os.getenv("OPENROUTER_API_KEY")`  
  - Fetches your API key from the environment (which came from `.env`).  
- `base_url="https://openrouter.ai/api/v1"`  
  - Tells the client to send requests to OpenRouter instead of OpenAI’s own endpoint. [openrouter](https://openrouter.ai/docs/guides/routing/routers/free-router)

The OpenRouter API is **OpenAI-compatible**, so we can reuse the same `OpenAI` client. [openrouter](https://openrouter.ai/docs/guides/routing/routers/free-router)

***

## Step 10 – Choose a Free AI Model

For this tutorial, you’ll use a free model on OpenRouter:

```python
MODEL_NAME = "deepseek/deepseek-r1-0528:free"
```

This is:

- A reasoning-focused model called **DeepSeek R1** (free variant) available via OpenRouter. [openrouter](https://openrouter.ai/deepseek/deepseek-r1:free)
- You can swap this string later to try other models, such as the automatic **openrouter/free** router that chooses from currently available free models. [openrouter](https://openrouter.ai/docs/guides/routing/routers/free-router)

***

## Step 11 – Define the AI’s Role with a System Prompt

AI models respond better when you give them a clear role and structure.

Add:

```python
SYSTEM_PROMPT = """
You are an expert Python debugging assistant.

When given Python code:

1. Identify the bug.
2. Explain why it occurs.
3. Suggest the fix.
4. Produce corrected code.
5. Mention any improvements.
"""
```

This **system prompt**:

- Tells the model what it should act like (an expert debugging assistant).  
- Explains exactly how you want it to respond.  

You can improve this prompt later to get more structured or more detailed answers.

***

## Step 12 – Initialize Panel

Now set up Panel:

```python
pn.extension()
```

This line:

- Initializes Panel’s JavaScript/CSS resources so that widgets and layouts work correctly in the browser. [github](https://github.com/holoviz/panel)

***

## Step 13 – Create the Function That Calls the AI

Add this function:

```python
def debug_code(code: str) -> str:
    response = client.chat.completions.create(
        model=MODEL_NAME,
        temperature=0,
        messages=[
            {
                "role": "system",
                "content": SYSTEM_PROMPT,
            },
            {
                "role": "user",
                "content": code,
            },
        ],
    )

    return response.choices[0].message.content
```

What happens here:

- `debug_code` takes the user’s Python code as a string.  
- `client.chat.completions.create(...)` sends a **chat-style request** to the AI model:
  - `model=MODEL_NAME` chooses which model to use.  
  - `temperature=0` makes responses more deterministic (less creative, more stable).  
  - `messages` is a list of chat messages:
    - One **system** message (your instructions).  
    - One **user** message (the code the user pasted).  
- The function then returns the **text content** of the first AI message in `response.choices`.

***

## Step 14 – Build the User Interface with Panel Widgets

Now you will create three main UI pieces:

1. A text area to paste Python code  
2. A button to trigger debugging  
3. An output area to show the AI’s response  

Add:

```python
code_input = pn.widgets.TextAreaInput(
    name="Python Code",
    height=350,
    placeholder="Paste your Python code here...",
)

debug_button = pn.widgets.Button(
    name="Debug Code",
    button_type="primary",
)

output = pn.pane.Markdown(
    "AI analysis will appear here.",
    height=400,
)
```

- `TextAreaInput` – a multi-line text box for the user to paste code.  
- `Button` – a clickable button.  
- `Markdown` pane – displays the AI analysis as Markdown (so you can later style it with headings, code blocks, etc.). [github](https://github.com/holoviz/panel)

***

## Step 15 – Connect the Button to the AI Function

You now need to tell Panel what to do when the button is clicked.

Add:

```python
def on_click(event):
    code = code_input.value.strip()

    if not code:
        output.object = "Please enter some Python code."
        return

    output.object = "Analyzing..."

    try:
        result = debug_code(code)
        output.object = result
    except Exception as e:
        output.object = f"Error: {e}"
```

Explanation:

- `on_click` is a function that will run whenever the button is pressed.  
- `code_input.value` contains the text from the text area.  
- If the user left it empty, you show a friendly message.  
- Otherwise:
  - Set the output to `"Analyzing..."` while waiting.  
  - Call `debug_code(code)` to talk to the AI.  
  - Replace the output with whatever the AI returned.  
- If anything goes wrong (e.g., bad API key), you catch the exception and show the error.

Now register this function as the button’s click handler:

```python
debug_button.on_click(on_click)
```

This “wires up” the UI: clicking the button triggers `on_click`.

***

## Step 16 – Arrange the Layout

Now you’ll put all the UI pieces into a vertical layout:

```python
app = pn.Column(
    "# AI Python Debugger",
    code_input,
    debug_button,
    output,
    width=800,
)
```

- `pn.Column` stacks components vertically.  
- The first element `"# AI Python Debugger"` is a Markdown heading.  
- Setting `width=800` limits the width so it looks nicer. [github](https://github.com/holoviz/panel)

Make the layout servable:

```python
app.servable()
```

This tells Panel: “This object is the web app you should serve.”

***

## Full Source Code (For Reference)

Your `app.py` should now look like this:

```python
import os

import panel as pn
from dotenv import load_dotenv
from openai import OpenAI

# 1. Load environment variables from .env
load_dotenv()

# 2. Configure OpenRouter client
client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1",
)

# 3. Model name (free model on OpenRouter)
MODEL_NAME = "deepseek/deepseek-r1-0528:free"

# 4. System prompt defining the AI's role
SYSTEM_PROMPT = """
You are an expert Python debugging assistant.

When given Python code:

1. Identify the bug.
2. Explain why it occurs.
3. Suggest the fix.
4. Produce corrected code.
5. Mention any improvements.
"""

# 5. Initialize Panel
pn.extension()

# 6. Function to send code to the AI model
def debug_code(code: str) -> str:
    response = client.chat.completions.create(
        model=MODEL_NAME,
        temperature=0,
        messages=[
            {
                "role": "system",
                "content": SYSTEM_PROMPT,
            },
            {
                "role": "user",
                "content": code,
            },
        ],
    )
    return response.choices[0].message.content

# 7. UI components
code_input = pn.widgets.TextAreaInput(
    name="Python Code",
    height=350,
    placeholder="Paste your Python code here...",
)

debug_button = pn.widgets.Button(
    name="Debug Code",
    button_type="primary",
)

output = pn.pane.Markdown(
    "AI analysis will appear here.",
    height=400,
)

# 8. Callback for button clicks
def on_click(event):
    code = code_input.value.strip()

    if not code:
        output.object = "Please enter some Python code."
        return

    output.object = "Analyzing..."

    try:
        result = debug_code(code)
        output.object = result
    except Exception as e:
        output.object = f"Error: {e}"

debug_button.on_click(on_click)

# 9. Layout
app = pn.Column(
    "# AI Python Debugger",
    code_input,
    debug_button,
    output,
    width=800,
)

app.servable()
```

***

## Step 17 – Run the Application

From inside the `ai-debugger` folder (and with your virtual environment activated), run:

```bash
panel serve app.py --show
```

- `panel serve app.py` starts a small web server that serves your app.  
- `--show` automatically opens your default browser with the app. [github](https://github.com/holoviz/panel/blob/main/panel/__init__.py)

You should see:

- A page titled “AI Python Debugger”  
- A big text area  
- A **Debug Code** button  
- A result area

***

## Step 18 – Test the Debugger with Simple Bugs

Test 1 – IndexError:

```python
numbers = [1, 2, 3]
print(numbers [geeksforgeeks](https://www.geeksforgeeks.org/python/using-python-environment-variables-with-python-dotenv/))
```

- Paste into the editor, click **Debug Code**.  
- The AI should explain that you’re trying to access index 5 when the list only has 3 items, and suggest a fix.

Test 2 – NameError:

```python
name = "Alice"
print(age)
```

- The AI should tell you that `age` is not defined and needs to be created first.

Try a few more small bugs to see how the model responds.

***

## Step 19 – Make the Output Nicely Structured (Optional Upgrade)

To make the AI output easier to read, you can ask for Markdown sections in the system prompt.

Change `SYSTEM_PROMPT` to something like:

```python
SYSTEM_PROMPT = """
You are an expert Python debugging assistant.

When given Python code:

1. Identify the bug.
2. Explain why it occurs.
3. Suggest the fix.
4. Produce corrected code.
5. Mention any improvements.

Return your answer using the following Markdown sections:

## Error

## Explanation

## Fixed Code

## Improvements
"""
```

Now the AI will usually return nicely structured Markdown with headings and code blocks.

***

## Step 20 – Ideas for Future Enhancements

Once the basic debugger works, you can start iterating:

- Add **syntax highlighting** for the code input/output  
- Add a **“Run Code”** feature in a sandboxed environment  
- Support **multiple languages** (e.g., JavaScript, TypeScript) by tweaking the prompt  
- Add **conversation history** so the AI remembers previous messages  
- Stream responses for “typing” effect  
- Allow **file uploads** instead of just pasting  
- Generate **unit tests** based on the buggy code  
- Provide **performance** and **complexity** suggestions  

Panel can integrate with other plotting and web frameworks, so you can extend this into a full dev assistant dashboard over time. [github](https://github.com/holoviz/panel)

***

Great, let’s turn this into a multi‑part series. Below are draft sections you can drop in as **Part 2, Part 3, and Part 4** of your tutorial, written to stay beginner‑friendly and consistent with Part 1.

I’ll assume the final `app.py` from Part 1 is already working.

***

## Part 2 – Add Syntax Highlighting to the Debugger

Right now, the input and output are just plain text. In this part, you’ll add **syntax highlighting** so Python code is easier to read.

### 2.1 – Why Syntax Highlighting?

Syntax highlighting:

- Colors keywords, strings, and comments differently  
- Makes it easier to spot mistakes (like missing quotes or mis‑indented code)  
- Improves the overall feel of your tool  

Panel supports different display components; for code, the most useful are:

- `pn.pane.Code` – display read‑only code with syntax highlighting  
- `pn.widgets.CodeEditor` – code editor widget with highlighting and line numbers  

You’ll start by improving the **output** using `pn.pane.Code`, then optionally upgrade the **input**.

***

### 2.2 – Highlight the AI’s “Fixed Code” Section

First, update your **system prompt** so the AI clearly separates the fixed code in a Markdown code block. If you applied the Markdown sections from Part 1, tweak the “Fixed Code” section like this:

```python
SYSTEM_PROMPT = """
You are an expert Python debugging assistant.

When given Python code:

1. Identify the bug.
2. Explain why it occurs.
3. Suggest the fix.
4. Produce corrected code.
5. Mention any improvements.

Return your answer using the following Markdown sections:

## Error

## Explanation

## Fixed Code

Provide the fixed code inside a fenced code block like:

```python
# your fixed code here
```

## Improvements
"""
```

Now the AI will put the corrected code inside a ` ```python ... ``` ` block, which Markdown understands.

Your existing `output = pn.pane.Markdown(...)` can already display highlighted code inside Markdown, so you may already see colored code after this change. If so, you don’t need extra work for output highlighting.

***

### 2.3 – Optional: Use a Code Editor for Input

If you want a more “IDE‑like” feel for the input, you can switch from `TextAreaInput` to `CodeEditor`. This widget is part of Panel’s `ace` editor support.

Replace your `code_input` definition:

```python
code_input = pn.widgets.TextAreaInput(
    name="Python Code",
    height=350,
    placeholder="Paste your Python code here...",
)
```

with:

```python
code_input = pn.widgets.CodeEditor(
    name="Python Code",
    language="python",
    height=350,
    sizing_mode="stretch_width",
)
```

Notes for beginners:

- `language="python"` tells the editor to use Python syntax rules.  
- `CodeEditor` gives you line numbers and better editing, which makes debugging more comfortable.  

Everything else (reading `code_input.value`) stays the same.

***

### 2.4 – Check the Improved UI

Restart your app:

```bash
panel serve app.py --show
```

Paste the same buggy code examples:

```python
numbers = [1, 2, 3]
print(numbers[5])
```

The input (if you switched to `CodeEditor`) should now highlight Python syntax, and the “Fixed Code” section in the output should be shown in a colored code block.

***

## Part 3 – Add Streaming AI Responses

Currently, the user clicks **Debug Code**, sees “Analyzing…”, and then the entire response appears at once. In this part, you’ll:

- Stream the AI’s response token‑by‑token  
- Update the UI as new text arrives  
- Make the app feel more responsive

> Important: The exact streaming API may differ between models and providers over time. The pattern below shows how to integrate streaming conceptually in a beginner‑friendly way.

***

### 3.1 – What Is Streaming?

Without streaming:

- You send a request  
- You wait until the model has generated the **entire** response  
- You receive one big blob of text

With streaming:

- You still send one request  
- The model sends **small chunks** of text as they’re ready  
- You can append each chunk to the UI, so the user sees the answer “typing out” in real time  

This feels faster, especially for long explanations.

***

### 3.2 – Adjust the `debug_code` Function to Support Streaming

You’ll create a **second** function for streaming, so your original `debug_code` stays simple.

Add this new function next to `debug_code`:

```python
def debug_code_stream(code: str):
    """
    Generator that yields chunks of the model's response as they arrive.
    """
    stream = client.chat.completions.create(
        model=MODEL_NAME,
        temperature=0,
        messages=[
            {
                "role": "system",
                "content": SYSTEM_PROMPT,
            },
            {
                "role": "user",
                "content": code,
            },
        ],
        stream=True,  # ask the API to stream the response
    )

    for chunk in stream:
        # Each chunk contains part of the final message
        delta = chunk.choices[0].delta
        if delta and delta.content:
            # Yield the new text piece
            yield delta.content
```

Conceptually:

- `stream=True` tells the API to send back multiple partial chunks instead of a single final message.  
- The function is a **generator** – you can loop over it and get new pieces of content as they arrive.  
- `yield delta.content` gives each token (or small group of tokens) to the caller.

If this streaming pattern ever changes in the library, the idea remains the same: loop over chunks and gradually build a string.

***

### 3.3 – Update the Click Handler to Use Streaming

Now change your `on_click` function to build the output incrementally.

Replace the inside of `try:` with something like this:

```python
def on_click(event):
    code = code_input.value.strip()

    if not code:
        output.object = "Please enter some Python code."
        return

    # Start with empty output or a header
    output.object = "Analyzing...\n"

    try:
        # Accumulate text as it streams in
        full_text = ""

        for chunk in debug_code_stream(code):
            full_text += chunk
            # Update the output pane as we go
            output.object = full_text

    except Exception as e:
        output.object = f"Error: {e}"
```

What’s happening here:

- `debug_code_stream(code)` gives you pieces of text one by one.  
- `full_text` accumulates the full message.  
- `output.object = full_text` re‑renders the markdown pane each time you receive more content, so the user sees the answer being constructed live.

If streaming feels too fast or noisy, you can update less frequently (e.g., only every few chunks), but this basic loop works for beginners.

***

### 3.4 – Test Streaming

Restart your app and debug a snippet that triggers a longer explanation, like:

```python
def divide(a, b):
    return a / b

print(divide(10, 0))
```

You should see the analysis appear gradually, line by line or token by token, instead of all at once.

***

## Part 4 – Understand the OpenRouter Request and Response Objects

This part is designed for beginners who want to understand **what’s actually going over the wire** when you call the AI.

You’ll take a closer look at:

- The **request** you send to OpenRouter  
- The **response** you get back  
- How to inspect and debug these objects in Python  

You’ll stay at a conceptual level so it’s not overwhelming.

***

### 4.1 – The Chat Completion Request in Plain English

When you call:

```python
response = client.chat.completions.create(
    model=MODEL_NAME,
    temperature=0,
    messages=[
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": code},
    ],
)
```

you’re sending a JSON‑shaped payload that looks like this conceptually:

- `model` – a string telling OpenRouter which model you want (for example `"deepseek/deepseek-r1-0528:free"`).  
- `temperature` – how “random/creative” the model should be (0 = deterministic, 1 = more creative).  
- `messages` – a list of objects representing a conversation:
  - Each object has a `role` (`"system"`, `"user"`, or `"assistant"`)  
  - And a `content` string (what that role said).

Even though you never manually build JSON, the client library handles this for you behind the scenes.

For streaming calls, the payload is the same, but you additionally pass `stream=True`.

***

### 4.2 – What the Response Looks Like

The `response` you get back from the non‑streaming call is a Python object that behaves like a structured dictionary.

At a high level, it contains:

- `id` – a unique identifier for the request  
- `model` – the model that actually responded  
- `choices` – a list of candidate completions; you usually use the first one  
- `usage` – token counts (how many tokens in the prompt and completion)  

Inside `choices[0]`, you’ll find:

- `message.role` – `"assistant"`  
- `message.content` – the full text the AI returned (what you show in the UI)

That’s why your code does:

```python
return response.choices[0].message.content
```

You’re picking the first candidate (`choices[0]`) and returning its message text.

***

### 4.3 – Inspecting the Response for Learning and Debugging

If you want to help beginners understand what’s going on, you can show them how to print or log the response.

For example, temporarily modify your `debug_code` function:

```python
def debug_code(code: str) -> str:
    response = client.chat.completions.create(
        model=MODEL_NAME,
        temperature=0,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": code},
        ],
    )

    # For debugging/learning: print to console
    print("Raw response:", response)

    return response.choices[0].message.content
```

When you run the app from the terminal, you’ll see the full response object printed out as you use the debugger. Beginners can see:

- The shape of the data  
- Where `choices` and `message` live  
- How token usage is reported  

After they understand it, you can remove the `print` statement.

***

### 4.4 – Inspecting Streaming Responses

For streaming, each `chunk` from the generator represents a partial update, and each chunk still has a similar shape, but only for the next piece of the message.

In this snippet:

```python
for chunk in debug_code_stream(code):
    full_text += chunk
    output.object = full_text
```

each `chunk` typically contains:

- `choices[0].delta.content` – the next piece of output text  

You can temporarily add:

```python
print("Chunk:", chunk)
```

inside the loop to show beginners how chunks arrive gradually.

***

### 4.5 – When Things Go Wrong

Understanding the request and response objects helps beginners debug issues like:

- Wrong model name – API may complain about unknown model  
- Missing/invalid API key – you’ll see authentication errors  
- Prompt too long – token limits errors  

Encourage them to:

- Print the **exception message** in the `except` block (which you already do)  
- Use `print(response)` or `print(chunk)` during development  
- Verify `MODEL_NAME` matches an actual model identifier from OpenRouter’s dashboard  

Once they’re comfortable, they can remove or replace prints with proper logging.

***

Let’s do a **Part 5** that builds on your existing flow and stays beginner‑friendly, but still feels like “real” AI tooling to a junior dev.

Since you said “yes” to all three earlier parts and now want to keep going, a natural **next** piece (Part 5) is:

> **Part 5 – Add Conversation History and Auto‑Generated Unit Tests**

Below is a draft Part 5 you can drop into the tutorial after Parts 2–4.

***

## Part 5 – Add Conversation History and Auto‑Generated Unit Tests

At this point your AI debugger:

- Accepts Python code  
- Sends it to an AI model via OpenRouter  
- Streams back a structured explanation and fixed code  
- Shows everything in a Panel web app  

In this part, you’ll add two capabilities that make it feel more like a “real” developer tool:

1. **Conversation history** – let the user ask follow‑up questions about the same code  
2. **Unit‑test suggestions** – automatically ask the model to propose tests for the buggy function(s)

You’ll still keep everything beginner‑friendly and in a single `app.py`.

***

### 5.1 – What Is Conversation History?

Right now, each call to `debug_code_stream` sends **only**:

- One system message (instructions)  
- One user message (the pasted code)  

This means the AI has no memory of previous messages. If a user says:

> “Can you make the fixed code use a `for` loop instead of a list comprehension?”

the model has no context unless the user pastes all the code again.

To support follow‑ups, you will:

- Keep a list of past messages in memory on the server  
- Send that list to the model each time instead of starting from scratch  

This is a light, beginner‑friendly way to implement “chat history” for a single user session.

***

### 5.2 – Add a Global Messages List

At the top of `app.py`, after your imports and before functions, add:

```python
# Simple in-memory conversation history for this session
conversation_messages = []
```

This will store a list of messages in the same format you send to the model, for example:

```python
{"role": "user", "content": "..."}
{"role": "assistant", "content": "..."}
```

You’ll seed it with the system prompt and then append as the user interacts.

***

### 5.3 – Initialize the Conversation with the System Prompt

Right after `SYSTEM_PROMPT` and before `pn.extension()`, initialize the history:

```python
conversation_messages = [
    {
        "role": "system",
        "content": SYSTEM_PROMPT,
    }
]
```

Now `conversation_messages` always starts with your system instruction, and you’ll keep appending new user and assistant messages.

***

### 5.4 – Update `debug_code_stream` to Use History

Change your streaming function so it:

- Adds the new user message to `conversation_messages`  
- Sends the **whole** history to the model  
- Appends the AI’s reply to history when done  

Here’s a beginner‑friendly version:

```python
def debug_code_stream(code: str):
    """
    Generator that yields chunks of the model's response as they arrive,
    while preserving conversation history.
    """
    # Add the new user message to the conversation
    conversation_messages.append(
        {
            "role": "user",
            "content": code,
        }
    )

    stream = client.chat.completions.create(
        model=MODEL_NAME,
        temperature=0,
        messages=conversation_messages,
        stream=True,
    )

    full_reply = ""

    for chunk in stream:
        delta = chunk.choices[0].delta
        if delta and delta.content:
            full_reply += delta.content
            yield delta.content

    # After streaming finishes, store the AI's response in history
    conversation_messages.append(
        {
            "role": "assistant",
            "content": full_reply,
        }
    )
```

Now each call:

- Extends the chat history  
- Lets the model “remember” what it said previously  

From the user’s perspective, they can paste code, click **Debug**, then type a follow‑up like:

> “Rewrite the fixed code to handle empty lists too.”

…and the model will know what “fixed code” refers to, because it has the previous messages.

***

### 5.5 – Add a “Follow‑Up Question” Box

To make follow‑ups explicit in the UI, add another text input and button below your main debugger.

Add these near your existing widgets:

```python
followup_input = pn.widgets.TextInput(
    name="Follow-up Question",
    placeholder="Ask a question about the previous analysis...",
)

followup_button = pn.widgets.Button(
    name="Ask Follow-up",
    button_type="secondary",
)
```

Then create a handler for follow‑ups:

```python
def on_followup(event):
    question = followup_input.value.strip()

    if not question:
        output.object = "Please enter a follow-up question."
        return

    output.object = "Thinking about your follow-up...\n"

    try:
        full_text = ""
        # Use the question as the user message (no code this time)
        for chunk in debug_code_stream(question):
            full_text += chunk
            output.object = full_text
    except Exception as e:
        output.object = f"Error: {e}"
```

Wire it up:

```python
followup_button.on_click(on_followup)
```

Update your layout (add these near the bottom of your `pn.Column`):

```python
app = pn.Column(
    "# AI Python Debugger",
    code_input,
    debug_button,
    output,
    "## Follow-up",
    followup_input,
    followup_button,
    width=800,
)
```

Now the user flow is:

1. Paste code → click **Debug Code**  
2. Read the explanation & fixed code  
3. Type a follow‑up in “Follow-up Question” → click **Ask Follow-up**  

***

### 5.6 – Teach the Model to Suggest Unit Tests

To make the tool more “production‑thinking”, you’ll ask the AI to generate unit tests for the functions it repairs.

You can do this entirely via the prompt—no test runner needed for beginners.

Update your `SYSTEM_PROMPT` to include a **Unit Tests** section, for example:

```python
SYSTEM_PROMPT = """
You are an expert Python debugging assistant.

When given Python code:

1. Identify the bug.
2. Explain why it occurs.
3. Suggest the fix.
4. Produce corrected code.
5. Mention any improvements.
6. Propose unit tests for the most important functions.

Return your answer using the following Markdown sections:

## Error

## Explanation

## Fixed Code

## Unit Tests

In the "Unit Tests" section, provide Python test code using either unittest or pytest style.
Focus on 2-5 meaningful tests that cover common and edge cases.

## Improvements
"""
```

You don’t have to change any code logic: the model will:

- Still find and fix the bug  
- Now also output a `## Unit Tests` section with example tests  

Your `output` pane already renders Markdown, so the tests will appear as highlighted code blocks under that heading.

***

### 5.7 – Encourage Beginners to Read the Tests

In the tutorial text (not in the code), explicitly explain to beginners how to learn from these tests:

- Each test should show:  
  - How to call the function  
  - What inputs are used  
  - What outputs are expected  
- Ask them to notice:  
  - Which edge cases the tests cover (e.g., empty list, zero, negative numbers)  
  - How the tests reflect the **bug** the AI just fixed  

You can add a small note like:

> “Even if you don’t run the tests yet, reading them helps you think like a professional developer. Tests describe the intended behavior of the function in a precise, machine‑checkable way.”

Later you can write a follow‑up post on “Now let’s actually run those tests with `pytest`”.

***

### 5.8 – Resetting Conversation History (Optional)

Because `conversation_messages` is global and in‑memory:

- It resets whenever you restart `panel serve`  
- It accumulates messages as you interact  

For beginners, you may want a **Reset** button.

Add:

```python
reset_button = pn.widgets.Button(
    name="Reset Conversation",
    button_type="danger",
)

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

reset_button.on_click(on_reset)
```

Then put it in your layout, maybe under the follow-up section:

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
```

This keeps the experience clean and easy for beginners.

***

Let’s extend the series with a **Part 6** that is very beginner‑friendly but still “real dev” enough to feel useful.

You can drop this in after Part 5.

***

## Part 6 – Run the AI‑Generated Unit Tests with `pytest`

In Part 5 you asked the AI to **suggest unit tests** in a `## Unit Tests` section. Those tests are just text until you actually run them.  

In this part, you’ll:

- Install `pytest`  
- Save the AI‑generated tests into a file  
- Run them from the terminal  
- Learn how to interpret the results  

`pytest` is a popular testing framework that makes it easy to write and run tests in Python. [geeksforgeeks](https://www.geeksforgeeks.org/python/getting-started-with-pytest/)

***

### 6.1 – Install `pytest` in Your Virtual Environment

With your virtual environment active, install `pytest`:

```bash
pip install pytest
```

This adds the `pytest` command to your environment so you can run tests from the terminal. [testdriven](https://testdriven.io/blog/pytest-for-beginners/)

For beginners:

- You **do not** need to import `pytest` in every test file if you only use plain `assert` statements.  
- `pytest` will discover tests by looking for files named `test_*.py` or `*_test.py`. [docs.pytest](https://docs.pytest.org/en/stable/getting-started.html)

***

### 6.2 – Decide Where Test Code Will Live

When the AI suggests tests, it will typically give something like:

```python
def test_add_positive_numbers():
    assert add(2, 3) == 5
```

You need to put this into a **test file** that `pytest` can find.

For a simple single‑file project, create a `tests` folder:

```bash
mkdir tests
```

Inside `tests`, create a file called:

```text
test_debugger_examples.py
```

You will paste tests here as you go. Later, you can split tests into multiple files if you like.

***

### 6.3 – Separate Your “App Code” and “Business Code” (Beginner Version)

Right now, your logic and UI are all in `app.py`. `pytest` works best when:

- Your **business logic** (functions to test) live in one module  
- Your **Panel app** lives in another module  

For a beginner‑friendly split:

1. Create a new file in the project root:  

   ```text
   code_examples.py
   ```

2. Put some simple functions there that you want to test. For example:

   ```python
   # code_examples.py

   def divide(a, b):
       return a / b

   def get_item(lst, index):
       return lst[index]
   ```

3. In your tutorial, tell the reader:

> “For now, we’ll pretend the bugs you paste into the debugger live in this `code_examples.py` file, so we can write and run tests against them. In a real project, these would be the functions from your actual application.”

This keeps things conceptually clean for beginners.

***

### 6.4 – Use the AI’s Suggested Tests in a File

When the AI suggests tests in the `## Unit Tests` section, it will usually give you a code block like:

```python
def test_divide_by_zero():
    import pytest
    from code_examples import divide

    with pytest.raises(ZeroDivisionError):
        divide(10, 0)

def test_divide_normal_case():
    from code_examples import divide

    assert divide(10, 2) == 5
```

You can guide the reader to:

1. Copy only the **Python code** inside the code block.  
2. Paste it into `tests/test_debugger_examples.py`.  
3. Make sure the imports (like `from code_examples import divide`) match the functions you actually have in `code_examples.py`.

You might add a short note:

> “If your AI tests import different function names, adjust them so they match the functions you actually have in `code_examples.py`.”

***

### 6.5 – Run Tests with `pytest`

To run all tests:

```bash
pytest
```

What happens:

- `pytest` will scan the project for files named `test_*.py` (like `test_debugger_examples.py`). [docs.pytest](https://docs.pytest.org/en/stable/getting-started.html)
- It will run all functions that start with `test_`.  
- It will show a summary:

  - Green dots for passing tests  
  - `F` for failures  
  - A final line like `2 passed in 0.03s` or `1 passed, 1 failed in 0.05s`

Encourage beginners to:

- Change a function in `code_examples.py` to the *wrong* behavior and re‑run `pytest`.  
- Observe how a failing test points to the mismatch between expected and actual behavior.

This reinforces that tests are **executable specifications** of how the code should behave. [testdriven](https://testdriven.io/blog/pytest-for-beginners/)

***

### 6.6 – Connect Back to the AI Debugger

Tie it back to the app:

1. Paste buggy code into the AI debugger.  
2. Let the AI:

   - Explain the bug  
   - Show fixed code  
   - Suggest unit tests  

3. Copy the fixed code into `code_examples.py`.  
4. Copy the unit tests into `tests/test_debugger_examples.py`.  
5. Run:

   ```bash
   pytest
   ```

6. Confirm that all tests pass. If tests fail, ask the debugger follow‑up questions like:

> “Your unit test `test_divide_by_zero` is failing with a different error. Can you adjust the fixed code so it passes all these tests?”

This loop teaches beginners:

- How AI suggestions map to real files  
- How **tests** enforce correctness  
- How to use AI to iteratively improve code with real feedback

***

### 6.7 – Optional: Add a “Copy Tests” UX Hint in the App

For beginner readers, you can add a short static note under the output pane (no code changes needed), something like:

> “Tip: Look for the `## Unit Tests` section above, copy the code into `tests/test_debugger_examples.py`, and run `pytest` in your terminal to validate the fix.”

This small hint bridges the gap between the browser UI and the terminal workflow.

***

At this point, your tutorial series takes a beginner from:

- “Paste code → get AI explanation”  
to  
- “Paste code → get AI explanation + fixed code + unit tests → run tests in `pytest` → iterate.”

That’s already a nice full learning arc.

