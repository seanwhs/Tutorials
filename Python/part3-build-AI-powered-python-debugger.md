# Add an Abort/Stop Control to Cancel Long-Running AI Responses  
## In Your AI-Powered Python Debugger

***

## Overview

In previous tutorials, you built an AI debugger that:

- Explains bugs  
- Suggests fixes  
- Generates unit tests  
- Supports follow-up questions  
- Uses streaming responses  

But sometimes:

- The AI response is too long  
- The user wants to change the question  
- The model is slow or stuck  

In this tutorial, you’ll add a **Stop** button that:

- Cancels the current streaming response  
- Stops fetching new chunks from the API  
- Resets the UI so the user can start a new request  

This is a **user experience polish** feature that makes your tool more robust and professional.

***

## What You’ll Add

| Before (No Stop Control)                  | After (With Stop Control)                              |
|------------------------------------------|--------------------------------------------------------|
| User must wait for full response         | User can cancel mid-stream                             |
| No way to interrupt slow responses       | One click stops the response                           |
| UI may feel “stuck” while streaming      | UI returns to idle state immediately                   |

***

## Prerequisites

You should have:

- The working `ai-debugger` project from Tutorial 8  
- Python 3.10+  
- Virtual environment with:
  - `panel`
  - `openai`
  - `python-dotenv`
  - `pytest`
- An OpenRouter API key in `.env`

***

# Phase 1 – Understand How to Cancel Streaming in Python

## 1.1 – How Streaming Works in Your Current Code

Your current `debug_code_stream` function:

```python
def debug_code_stream(code: str):
    conversation_messages.append({"role": "user", "content": code})

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

    conversation_messages.append({"role": "assistant", "content": full_reply})
```

Key points:

- `stream = client.chat.completions.create(..., stream=True)` creates a streaming iterator. [stackoverflow](https://stackoverflow.com/questions/72207914/how-to-stop-listening-on-a-stream-in-python-grpc-client)
- `for chunk in stream:` loops over chunks as they arrive.  
- `yield text` sends each chunk back to the caller.  

To cancel, you need to:

- Stop the loop early  
- Close the stream  
- Optionally raise a cancellation signal  

***

## 1.2 – Canceling a Streaming Call

In Python, there are a few ways to cancel streaming:

1. **Break the loop and close the stream** (simplest for beginners)  
   - When the user clicks Stop, you set a flag.  
   - The generator checks the flag and stops yielding.  
   - You close the stream manually. [blog.csdn](https://blog.csdn.net/qq_54655817/article/details/154015599)

2. **Use `asyncio` tasks and cancel them** (more advanced)  
   - Wrap the streaming in an `asyncio.Task`.  
   - Call `task.cancel()` when the user clicks Stop. [docs.python](https://docs.python.org/3/library/asyncio-task.html)

For a beginner-friendly tutorial, we’ll use **approach 1**: a shared cancellation flag and stream closing.

***

# Phase 2 – Add a Shared Cancellation Flag

## 2.1 – Create a Global Cancel Flag

Add a global variable to track cancellation state:

```python
# Global cancellation flag
cancel_streaming = False
```

Place this near the top of `app.py`, after `conversation_messages`:

```python
conversation_messages = [
    {
        "role": "system",
        "content": SYSTEM_PROMPT,
    }
]

cancel_streaming = False
```

***

## 2.2 – Add a Reset Function for Cancel State

Define a helper to reset the flag:

```python
def reset_cancel_flag():
    global cancel_streaming
    cancel_streaming = False
```

You’ll call this when starting a new request.

***

# Phase 3 – Modify `debug_code_stream` to Support Cancellation

## 3.1 – Update the Generator to Check the Flag

Modify `debug_code_stream` so it:

- Checks `cancel_streaming` in the loop  
- Stops yielding when the flag is set  
- Closes the stream

```python
def debug_code_stream(code: str):
    """
    Generator that yields chunks of the model's response as they arrive,
    while supporting cancellation via cancel_streaming flag.
    """
    global cancel_streaming

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

    try:
        for chunk in stream:
            # If cancellation is requested, stop early
            if cancel_streaming:
                # Close the stream
                stream.close()
                # Add a partial message to history
                conversation_messages.append(
                    {
                        "role": "assistant",
                        "content": full_reply + "\n[Response cancelled by user]",
                    }
                )
                return

            delta = chunk.choices[0].delta
            if delta and delta.content:
                text = delta.content
                full_reply += text
                yield text
    finally:
        # If not cancelled, store full response
        if not cancel_streaming:
            conversation_messages.append(
                {
                    "role": "assistant",
                    "content": full_reply,
                }
            )
```

Key points:

- The generator checks `cancel_streaming` on each chunk.  
- If cancelled:
  - It closes the stream with `stream.close()`. [blog.csdn](https://blog.csdn.net/qq_54655817/article/details/154015599)
  - It appends a partial message with “Response cancelled by user”.  
  - It returns early.  
- If not cancelled, it stores the full response in history.

***

# Phase 4 – Add a Stop Button and Handler

## 4.1 – Add a Stop Button Widget

Add a new button:

```python
stop_button = pn.widgets.Button(
    name="Stop",
    button_type="warning",
)
```

Place it near your other buttons.

***

## 4.2 – Add a Stop Handler

Define a function that sets the cancel flag:

```python
def on_stop(event):
    global cancel_streaming
    cancel_streaming = True
    output.object += "\n[Response cancelled by user]"
```

Wire it up:

```python
stop_button.on_click(on_stop)
```

***

## 4.3 – Reset Cancel Flag Before Each New Request

In your `on_click` and `on_followup` functions, reset the flag before starting streaming:

```python
def on_click(event):
    code = code_input.value.strip()

    if not code:
        output.object = "Please enter some Python code."
        return

    # Reset cancel flag before starting
    reset_cancel_flag()

    output.object = "Analyzing...\n"

    try:
        full_text = ""
        for chunk in debug_code_stream(code):
            full_text += chunk
            output.object = full_text
    except Exception as e:
        output.object = f"Error: {e}"
```

And for follow-ups:

```python
def on_followup(event):
    question = followup_input.value.strip()

    if not question:
        output.object = "Please enter a follow-up question."
        return

    # Reset cancel flag before starting
    reset_cancel_flag()

    output.object = "Thinking about your follow-up...\n"

    try:
        full_text = ""
        for chunk in debug_code_stream(question):
            full_text += chunk
            output.object = full_text
    except Exception as e:
        output.object = f"Error: {e}"
```

***

# Phase 5 – Update the Layout

Add the stop button near the debug and follow-up buttons:

```python
app = pn.Column(
    "# AI Debugger (Multi-Language)",
    "## Language",
    language_selector,
    code_input,
    debug_button,
    stop_button,
    output,
    "## Follow-up",
    followup_input,
    followup_button,
    reset_button,
    width=800,
)
```

(We’ll add `language_selector` in the next part for multi-language support.)

***

# Phase 6 – Test the Stop Control

Restart your app:

```bash
panel serve app.py --show
```

Test:

1. Paste a code snippet that triggers a long response.  
2. Click **Debug Code**.  
3. While the response is streaming, click **Stop**.  
4. You should see:
   - Streaming stops immediately  
   - Output ends with `[Response cancelled by user]`  
   - UI returns to idle state  

Now you can start a new request.

***

# Phase 7 – Optional: Hide Stop Button When Not Streaming

For a more polished UI, you can hide the Stop button when no streaming is happening.

Add a state variable:

```python
is_streaming = False
```

In `on_click`:

```python
is_streaming = True
stop_button.visible = True
```

When streaming ends or is cancelled:

```python
is_streaming = False
stop_button.visible = False
```

This keeps the UI cleaner but is optional for beginners.

***

Now let’s move to the **multi-language extension**.

***

# Tutorial 10 – Extend the Debugger to Support Multiple Languages  
## Python + JavaScript

***

## Overview

In previous tutorials, you built an AI debugger that:

- Works with Python  
- Explains bugs  
- Suggests fixes  
- Generates unit tests  
- Supports follow-up questions  
- Has a Stop button to cancel streaming  

Now you’ll extend it to support **multiple languages**, specifically:

- **Python**  
- **JavaScript**  

Users will:

1. Choose a language from a dropdown  
2. Paste code in that language  
3. Get:
   - Language-specific error explanations  
   - Fixes in the same language  
   - Unit tests using the right framework  
     - Python → `pytest`  
     - JavaScript → `jest` (or similar)

This makes your debugger more versatile and closer to a real multi-language AI coding assistant.

***

## What You’ll Add

| Before (Python Only)                      | After (Multi-Language)                                   |
|------------------------------------------|----------------------------------------------------------|
| Prompt is Python-specific                | Prompt adapts to chosen language                         |
| Tests use `pytest` only                  | Tests use `pytest` for Python, `jest` for JavaScript     |
| No language selection UI                 | Dropdown to choose Python or JavaScript                  |

***

## Prerequisites

You should have:

- The working `ai-debugger` project from Tutorial 9  
- Python 3.10+  
- Virtual environment with:
  - `panel`
  - `openai`
  - `python-dotenv`
  - `pytest`
- An OpenRouter API key in `.env`

***

# Phase 1 – Add a Language Selector

## 1.1 – Add a Dropdown Widget

Add a language selector:

```python
language_selector = pn.widgets.Select(
    name="Language",
    options=["Python", "JavaScript"],
    value="Python",
)
```

Place this near your other widgets.

***

## 1.2 – Store Current Language Globally

Add a global variable:

```python
current_language = "Python"
```

Update it when the user changes the dropdown:

```python
def on_language_change(event):
    global current_language
    current_language = language_selector.value
```

Wire it:

```python
language_selector.param.watch(on_language_change, "value")
```

***

# Phase 2 – Create Language-Specific System Prompts

## 2.1 – Python System Prompt (From Tutorial 8)

```python
PYTHON_SYSTEM_PROMPT = """
You are an expert Python debugging assistant.

When given Python code:

1. Identify the bug.
   - Name the error type if possible (e.g., IndexError, NameError, ZeroDivisionError).

2. Explain the root cause step-by-step.
   - Describe what the code is trying to do.
   - Explain exactly where and why it fails.
   - Use clear, beginner-friendly language.

3. Provide fixed code.
   - The fixed code must be complete and runnable.
   - Handle common edge cases (e.g., empty lists, zero, negative numbers) where relevant.
   - Use safe patterns (e.g., check before accessing list indices, avoid division by zero).

4. Suggest unit tests.
   - Provide 2–5 tests using pytest style.
   - Each test must:
     - Be named clearly: test_<function_name>_<scenario>
     - Use assert statements
     - Import the function (e.g., `from code_examples import divide`)
   - Include:
     - At least one normal case
     - At least one edge case (e.g., empty input, zero, negative values)
     - At least one error case if the function can raise exceptions
   - Tests must be runnable with pytest without extra setup.

   Example of desired test style:

   ```python
   import pytest
   from code_examples import divide

   def test_divide_normal_case():
       assert divide(10, 2) == 5

   def test_divide_by_zero():
       with pytest.raises(ZeroDivisionError):
           divide(10, 0)

   def test_divide_negative_numbers():
       assert divide(-10, 2) == -5
   ```

5. Mention improvements.
   - Suggest readability, performance, or safety improvements.

Return your answer using exactly these Markdown sections:

## Error
## Explanation
## Fixed Code
## Unit Tests
## Improvements
"""
```

***

## 2.2 – JavaScript System Prompt

Create a similar prompt for JavaScript, but with `jest` tests:

```python
JAVASCRIPT_SYSTEM_PROMPT = """
You are an expert JavaScript debugging assistant.

When given JavaScript code:

1. Identify the bug.
   - Name the error type if possible (e.g., TypeError, ReferenceError).

2. Explain the root cause step-by-step.
   - Describe what the code is trying to do.
   - Explain exactly where and why it fails.
   - Use clear, beginner-friendly language.

3. Provide fixed code.
   - The fixed code must be complete and runnable.
   - Handle common edge cases (e.g., null, undefined, empty arrays) where relevant.
   - Use safe patterns (e.g., check before accessing array indices, avoid dividing by zero).

4. Suggest unit tests.
   - Provide 2–5 tests using Jest style.
   - Each test must:
     - Be named clearly: describe('<function>') and test('<scenario>') or it('<scenario>')
     - Use assert-like patterns from Jest (e.g., expect(...).toBe(...))
     - Import the function if needed (e.g., `const { divide } = require('./code_examples')`)
   - Include:
     - At least one normal case
     - At least one edge case (e.g., null, undefined, empty arrays)
     - At least one error case if the function can throw exceptions
   - Tests must be runnable with Jest without extra setup.

   Example of desired test style:

   ```javascript
   const { divide } = require('./code_examples');

   test('divide normal case', () => {
       expect(divide(10, 2)).toBe(5);
   });

   test('divide by zero throws error', () => {
       expect(() => divide(10, 0)).toThrow();
   });

   test('divide negative numbers', () => {
       expect(divide(-10, 2)).toBe(-5);
   });
   ```

5. Mention improvements.
   - Suggest readability, performance, or safety improvements.

Return your answer using exactly these Markdown sections:

## Error
## Explanation
## Fixed Code
## Unit Tests
## Improvements
"""
```

***

## 2.3 – Choose Prompt Based on Language

Update your code to select the right prompt:

```python
def get_system_prompt(language: str) -> str:
    if language == "Python":
        return PYTHON_SYSTEM_PROMPT
    elif language == "JavaScript":
        return JAVASCRIPT_SYSTEM_PROMPT
    else:
        # Default to Python
        return PYTHON_SYSTEM_PROMPT
```

Update `conversation_messages` initialization:

```python
conversation_messages = [
    {
        "role": "system",
        "content": get_system_prompt(current_language),
    }
]
```

When the language changes, reset the conversation with the new prompt:

```python
def on_language_change(event):
    global current_language, conversation_messages
    current_language = language_selector.value
    conversation_messages = [
        {
            "role": "system",
            "content": get_system_prompt(current_language),
        }
    ]
    output.object = "Language changed. Conversation reset. Paste new code to start a fresh analysis."
    followup_input.value = ""
    code_input.value = ""
```

***

# Phase 3 – Update CodeEditor Language

Update your `CodeEditor` to respect the selected language:

```python
code_input = pn.widgets.CodeEditor(
    name="Code",
    language="python",  # initial
    height=350,
    sizing_mode="stretch_width",
)

def on_language_change(event):
    global current_language, conversation_messages
    current_language = language_selector.value
    conversation_messages = [
        {
            "role": "system",
            "content": get_system_prompt(current_language),
        }
    ]

    # Update CodeEditor language
    if current_language == "JavaScript":
        code_input.language = "javascript"
    else:
        code_input.language = "python"

    output.object = "Language changed. Conversation reset. Paste new code to start a fresh analysis."
    followup_input.value = ""
    code_input.value = ""
```

***

# Phase 4 – Update Layout and Test

Update your layout:

```python
app = pn.Column(
    "# AI Multi-Language Debugger",
    "## Language",
    language_selector,
    code_input,
    debug_button,
    stop_button,
    output,
    "## Follow-up",
    followup_input,
    followup_button,
    reset_button,
    width=800,
)
```

Test:

1. Choose **Python**:
   - Paste Python code  
   - Get Python explanations and `pytest` tests  

2. Choose **JavaScript**:
   - Paste JavaScript code  
   - Get JavaScript explanations and `jest` tests  

Example JavaScript code:

```javascript
function divide(a, b) {
    return a / b;
}

console.log(divide(10, 0));
```

***

## Summary

You now have an AI debugger that:

- Supports **Python and JavaScript**  
- Uses **language-specific system prompts**  
- Generates **pytest tests for Python** and **jest tests for JavaScript**  
- Updates the **CodeEditor language** based on selection  
- Resets conversation when language changes  

This is a solid foundation for a multi-language AI coding assistant.

***

## Next Steps

You could extend this further by:

- Adding more languages (TypeScript, Python + TypeScript, etc.)  
- Adding file upload support  
- Integrating linting tools  
- Building a richer UI with tabs per language  

