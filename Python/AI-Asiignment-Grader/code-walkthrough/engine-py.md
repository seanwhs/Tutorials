## 1. Imports and client setup

```python
import os
import asyncio
import re
from dotenv import load_dotenv
from openai import AsyncOpenAI
```

### Why this block exists
This block brings in the basic tools the script needs before it can do any real work. `os` helps read environment variables, `asyncio` supports asynchronous programming, `re` handles text pattern matching, `load_dotenv()` loads secret values from a `.env` file, and `AsyncOpenAI` creates the AI client.

### Python concepts used
- `import` loads modules into the program.
- `asyncio` is Python’s built-in async system.
- `re` is the regular expression module for searching text patterns.
- `load_dotenv()` is used to load environment variables from a file.
- `AsyncOpenAI` is an async client, so later API calls can use `await`.

### Pattern analysis
This is a **setup block**. It prepares the program’s dependencies first, before defining the actual grading logic.

### What if
Try imagining what would happen if `asyncio` were removed. The later async functions would no longer work properly, because the program depends on non-blocking API calls.

***

## 2. Environment loading and shared client

```python
load_dotenv()
API_KEY = os.getenv("OPENROUTER_API_KEY")

client = AsyncOpenAI(
    api_key=API_KEY,
    base_url="https://openrouter.ai/api/v1"
)
```

### Why this block exists
This block solves the problem of securely storing and retrieving the API key. Instead of hardcoding secrets into the source file, the program reads the key from the environment and creates one reusable client for all future AI requests.

### Python concepts used
- `load_dotenv()` loads values from a `.env` file into the environment.
- `os.getenv(...)` fetches a variable safely.
- Keyword arguments like `api_key=` and `base_url=` make the client configuration readable.

### Pattern analysis
This is a **shared service object** pattern. The client is built once and reused everywhere, which is cleaner than creating a new client for every request.

### What if
Rename `OPENROUTER_API_KEY` in your `.env` file to something else and see how the program loses access to the key. That shows why the variable name matters.

***

## 3. Prompt templates

```python
SUBJECT_DETECTION_PROMPT = """
You are an academic subject classifier.

Choose ONLY one:
Mathematics, English, Science, Programming.

Return ONLY the word.
No explanation.

Assignment:
"""
```

This same style is used for `JSON_SCHEMA_PROMPT`, `MATH_MARKING_PROMPT`, `ENGLISH_MARKING_PROMPT`, `SCIENCE_MARKING_PROMPT`, `PROGRAMMING_MARKING_PROMPT`, `GENERIC_MARKING_PROMPT`, and `VISION_PROMPT`.

### Why this block exists
These prompts tell the AI how to behave. One prompt is for identifying the subject, others are for grading style, and one is for strict JSON markup. Each prompt narrows the model’s behavior so the output is more predictable.

### Python concepts used
- Triple-quoted strings store multiline text.
- Uppercase names indicate constants by convention.
- These strings are later combined with user content using normal string concatenation or f-strings.

### Pattern analysis
This is **prompt construction**. The code is not calling the AI yet — it is preparing the instructions that will be sent to the AI later.

### What if
Remove the line `Return ONLY the word.` from the subject prompt and see how the model might start giving explanations instead of a clean label.

***

## 4. Subject prompt mapping

```python
SUBJECT_PROMPTS = {
    "Mathematics": MATH_MARKING_PROMPT,
    "English": ENGLISH_MARKING_PROMPT,
    "Science": SCIENCE_MARKING_PROMPT,
    "Programming": PROGRAMMING_MARKING_PROMPT,
}
```

### Why this block exists
Different subjects need different marking styles. A math assignment should be judged differently from an English essay or a programming solution, so the code stores the right prompt for each subject.

### Python concepts used
- Dictionaries store key/value pairs.
- `.get(subject, default)` is used later to safely retrieve a prompt.
- This avoids long chains of `if` and `elif`.

### Pattern analysis
This is a **dispatch table**. The subject name acts like a key, and the dictionary selects the right behavior.

### What if
Add a new subject like `"History"` and give it its own prompt. That helps you see how easily the design can scale.

***

## 5. Vision prompt

```python
VISION_PROMPT = """
Analyze the assignment and provide:
Strengths, Mistakes, Suggestions, Final Grade
"""
```

### Why this block exists
This prompt gives a vision model a simple checklist for what to produce after looking at an image of student work.

### Python concepts used
- It is just a string constant.
- It is inserted into later API calls as part of the model instruction.

### Pattern analysis
This is **separation of concerns**. The instruction text lives in its own variable instead of being buried inside the function.

### What if
Make the prompt more detailed, such as asking for “exactly 3 strengths and 3 mistakes,” and see how the output becomes more structured.

***

## 6. Model pool

```python
MODELS_POOL = [
    "openai/gpt-oss-20b:free",
    "qwen/qwen3-coder:free",
    "google/gemma-4-31b-it:free",
    "meta-llama/llama-3.3-70b-instruct:free",
]
```

### Why this block exists
This list gives the program multiple models to try. If one model is slow or fails, another may still respond successfully.

### Python concepts used
- Lists store ordered collections.
- Each item is a model name string.

### Pattern analysis
This is a **fallback and racing strategy**. Instead of relying on one model, the program gives itself several chances to get a usable answer.

### What if
Remove one model from the list and observe that the system still works, just with fewer options.

***

## 7. Grade extraction helper

```python
def extract_grade(text: str) -> str:
    if not text:
        return "N/A"
    patterns = [
        r"\b(\d{1,2}(?:\.\d+)?)\s*/\s*10\b",
        r"\bGrade[:\s]*([A-F][+-]?)\b",
        r"\b(\d{1,2}(?:\.\d+)?)\s*/\s*(?:100|20|50)\b",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.I)
        if m:
            if "Grade" in pat:
                return m.group(1)
            return m.group(0).replace(" ", "")
    return "N/A"
```

### Why this block exists
AI responses are not always nicely formatted. This helper tries to pull a grade out of different possible text patterns, such as `8/10`, `A-`, or `75/100`.

### Python concepts used
- Functions are defined with `def`.
- Type hints like `text: str` describe expected types.
- `re.search()` finds a match using a regular expression.
- `if not text` checks for empty input.
- `m.group(...)` extracts matched text.

### Pattern analysis
This is a **robust parser**. It accepts that AI text may vary and tries several patterns in sequence.

### What if
Add another regex for a phrase like `85 percent` and see how the parser becomes more flexible.

***

## 8. Subject detection

```python
async def detect_subject(content):
    response = await client.chat.completions.create(
        model="openai/gpt-oss-20b:free",
        messages=[{
            "role": "user",
            "content": SUBJECT_DETECTION_PROMPT + content
        }],
        temperature=0
    )
    return response.choices[0].message.content.strip()
```

### Why this block exists
Before the program can grade the work, it needs to know what subject it is looking at. This function sends the content to a classifier model and gets back one subject label.

### Python concepts used
- `async def` defines an asynchronous function.
- `await` pauses execution until the API returns.
- `messages` is the chat-style request format.
- `temperature=0` encourages more consistent output.

### Pattern analysis
This is a **classification step** in a pipeline. It performs one small task, and later steps depend on its result.

### What if
Change `temperature` from `0` to a higher value and see whether the classification becomes less stable.

***

## 9. Single-model request helper

```python
async def ask_ai(prompt, model_name, timeout=10.0):
    try:
        response = await client.chat.completions.create(
            model=model_name,
            messages=[{"role": "user", "content": prompt}],
            timeout=timeout,
        )
        return response.choices[0].message.content
    except Exception:
        return None
```

### Why this block exists
This function sends one prompt to one model and returns the response. It also protects the program by catching errors and returning `None` instead of crashing.

### Python concepts used
- `try/except` handles runtime errors.
- Default arguments like `timeout=10.0` make the function easier to use.
- Returning `None` is a simple way to signal failure.

### Pattern analysis
This is an **error-tolerant helper**. It hides the low-level API request details and gives callers a simple result.

### What if
Remove the `try/except` and notice how a single failed request would stop the entire flow.

***

## 10. Concurrent model racing

```python
async def get_ai_response_concurrently(prompt, timeout=10.0):
    tasks = [
        asyncio.create_task(ask_ai(prompt, m, timeout))
        for m in MODELS_POOL
    ]
    done, pending = await asyncio.wait(
        tasks,
        return_when=asyncio.FIRST_COMPLETED
    )
    for task in done:
        result = task.result()
        if result:
            for p in pending:
                p.cancel()
            return result
    return "Error: All models failed"
```

### Why this block exists
This function asks several models the same question at the same time and uses the first usable answer. That makes the system faster and more resilient.

### Python concepts used
- List comprehensions build lists compactly.
- `asyncio.create_task(...)` starts tasks concurrently.
- `asyncio.wait(..., FIRST_COMPLETED)` waits for the first task to finish.
- `task.result()` retrieves the output.
- `p.cancel()` stops tasks that are no longer needed.

### Pattern analysis
This is the main **orchestration** layer for model racing. It does not generate prompts itself; it coordinates multiple helper calls and chooses the best outcome.

### What if
Change `FIRST_COMPLETED` to a strategy that waits for all tasks and compare the behavior. You’ll see the difference between “fastest answer wins” and “collect all answers first.”

### Main purpose
The main purpose of `get_ai_response_concurrently()` is to **improve reliability and speed by racing multiple AI models and returning the first valid result**. It is the program’s fallback mechanism when one model might fail or be too slow.

***

## 11. Image grading

```python
async def grade_image(image_base64, subject):
    response = await client.chat.completions.create(
        model="openai/gpt-4o",
        messages=[{
            "role": "user",
            "content": [
                {"type": "text", "text": f"Subject: {subject}\n{VISION_PROMPT}"},
                {"type": "image_url", "image_url": {
                    "url": f"data:image/jpeg;base64,{image_base64}"
                }}
            ]
        }]
    )
    return response.choices[0].message.content
```

### Why this block exists
This function sends an image of a student assignment to a vision-capable model and asks for feedback. It combines text instructions and image data in one request.

### Python concepts used
- f-strings insert variable values into strings.
- The `content` field contains multiple message parts.
- Base64 encoding lets the image be embedded in the request body.

### Pattern analysis
This is a **multimodal API call**. The model receives both text and image input at once.

### What if
Make the prompt more specific, for example by asking for a grading rubric, and see how that changes the response.

***

## 12. Image grading with markup

```python
async def grade_image_with_markup(image_base64, subject):
    marking_prompt = SUBJECT_PROMPTS.get(subject, GENERIC_MARKING_PROMPT)

    full_prompt = f"""
Subject: {subject}

You are doing STRICT RED PEN EXAM MARKING.

CRITICAL:
- Mark EVERYTHING visible
- Be extremely dense
- Do NOT skip steps
- Mimic real teacher annotations

{marking_prompt}

{JSON_SCHEMA_PROMPT}
"""
```

### Why this block exists
This function prepares a stricter version of the image grading task. Instead of just returning feedback, it asks for structured annotations that can be turned into markup on the image.

### Python concepts used
- `.get(subject, default)` provides a safe dictionary lookup.
- Triple-quoted f-strings make it easy to build large prompts.

### Pattern analysis
This is **prompt construction** again, but now with a stronger output contract. It combines the subject-specific prompt with a JSON schema prompt.

### What if
Replace the fallback `GENERIC_MARKING_PROMPT` with the math prompt and see how the default behavior changes.

***

## 13. JSON-enforced vision call

```python
    response = await client.chat.completions.create(
        model="openai/gpt-4o",
        messages=[{
            "role": "user",
            "content": [
                {"type": "text", "text": full_prompt},
                {"type": "image_url", "image_url": {
                    "url": f"data:image/jpeg;base64,{image_base64}"
                }}
            ]
        }],
        max_completion_tokens=1200,
        response_format={"type": "json_object"},
    )
    return response.choices[0].message.content
```

### Why this block exists
The program wants structured output that it can later parse and render. Asking for JSON makes the result easier to consume in code.

### Python concepts used
- Keyword arguments control model behavior.
- `max_completion_tokens` limits how much the model can write.
- `response_format={"type": "json_object"}` requests machine-readable output.

### Pattern analysis
This is a **structured response contract**. The code is telling the model not just what to say, but what format to say it in.

### What if
Remove `response_format` and compare how much harder it becomes to use the response programmatically.

***

## 14. Assignment judging

```python
async def judge_assignment(content, rubric):
    prompt = f"""
You are a strict teacher grading a student assignment.

Use this rubric:
{rubric}

Student work:
{content}

Return:
- short overall feedback
- a clear grade in the form X/10
- concise corrections if needed
"""
    return await get_ai_response_concurrently(prompt, timeout=10.0)
```

### Why this block exists
This function handles text-based assignments. It builds a grading prompt using the rubric and student work, then sends that prompt to the concurrent model-racing helper.

### Python concepts used
- Another f-string builds the request dynamically.
- The function delegates the actual model selection to another helper.

### Pattern analysis
This is an **orchestration function**. It does not do everything itself; it prepares the task and hands it off to `get_ai_response_concurrently()`.

### What if
Add a rule like “return exactly three corrections” and see how the output becomes more controlled.

***

## 15. Main guard

```python
if __name__ == "__main__":
    asyncio.run(asyncio.sleep(0))
```

### Why this block exists
This makes the file behave differently when run directly versus imported into another module. Right now it doesn’t perform a real action, but it sets up the standard entry-point structure.

### Python concepts used
- `__name__ == "__main__"` is the standard main-guard pattern.
- `asyncio.run(...)` runs an async coroutine from normal Python code.

### Pattern analysis
This is a **script entry point**. It keeps the file import-safe while still allowing it to be executed directly.

### What if
Replace `asyncio.sleep(0)` with a real function call to test the pipeline end to end.

## Core idea of the design

The whole file is built as a pipeline:
1. Load configuration.
2. Build prompts.
3. Ask the AI for subject detection or grading.
4. Use async helpers to make requests.
5. Use orchestration functions to connect the pieces.

The separation between prompt construction, async API calling, and orchestration makes the code easier to understand and extend. Prompt construction is about **what to ask**. Async API calling is about **sending and waiting efficiently**. Orchestration is about **combining smaller helpers into a complete workflow**.

What do you want next: a similarly annotated walkthrough of `utils.py`, `markup.py`, `report.py`, and `storage.py`, or a cleaned-up “teacher notes” version you can drop into your tutorial?
