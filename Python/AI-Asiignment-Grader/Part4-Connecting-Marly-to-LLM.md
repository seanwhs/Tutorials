# Part 4 — Connecting Markly to an AI Model with OpenRouter

Up to this point, Markly can successfully upload assignments and extract their contents. That's a major milestone, but the application still isn't "intelligent." It simply reads documents and displays their text.

In this chapter, we'll connect Markly to a Large Language Model (LLM) using **OpenRouter**. Once the connection is established, our application will be able to send a student's assignment to the AI and receive feedback in return.

This is the point where Markly begins to transform from a document processing application into an AI-powered grading assistant.

By the end of this chapter, you'll learn how to:

* Store API keys securely using environment variables
* Connect to OpenRouter using the OpenAI Python SDK
* Understand the anatomy of an LLM request
* Send prompts to an AI model
* Display AI responses inside the application
* Organize AI-related code inside `engine.py`

---

# What is OpenRouter?

There are many companies that provide access to Large Language Models.

Some of the most well-known include:

* OpenAI
* Anthropic
* Google
* Meta
* Mistral AI
* DeepSeek
* Cohere
* Qwen

Each company offers its own models, pricing, APIs, and capabilities.

Normally, switching between providers means learning a different API for each one.

OpenRouter simplifies this process.

Instead of integrating separately with every AI provider, your application communicates with **one API**, and OpenRouter routes your request to whichever model you choose.

```text
                Markly
                   │
                   ▼
             OpenRouter API
                   │
      ┌────────────┼────────────┐
      ▼            ▼            ▼
   GPT Models   Claude      Llama Models
      │            │            │
      └────────────┼────────────┘
                   ▼
              AI Response
```

This makes it easy to experiment with different models without changing your application's code.

---

# Why Use the OpenAI Python SDK?

Although we're using OpenRouter, we'll actually write our code using the **OpenAI Python SDK**.

That may sound strange at first.

Here's why.

OpenRouter is designed to be **compatible** with the OpenAI API.

Instead of learning a completely new client library, we simply tell the OpenAI SDK to send requests to OpenRouter instead of OpenAI.

That means almost all OpenAI examples work with only a few small changes.

---

# Securing Your API Key

Earlier, we created a `.env` file.

```text
OPENROUTER_API_KEY=your_api_key_here
```

Why didn't we simply write:

```python
API_KEY = "sk-xxxxxxxxxxxxxxxx"
```

inside our code?

Because API keys are secrets.

If you accidentally upload your project to GitHub, anyone can see that key and potentially use your account.

A better approach is to store secrets outside the source code.

The `.env` file allows us to do exactly that.

---

# Loading Environment Variables

Open **engine.py**.

Let's begin by importing a few libraries.

```python
import os

from dotenv import load_dotenv

from openai import OpenAI
```

Now load the environment variables.

```python
load_dotenv()
```

This reads the `.env` file and makes its contents available to Python.

We can now retrieve the API key.

```python
API_KEY = os.getenv("OPENROUTER_API_KEY")
```

If your `.env` file contains

```text
OPENROUTER_API_KEY=abc123
```

then

```python
print(API_KEY)
```

would display

```text
abc123
```

Never print your real API key in production.

We're only showing this example so you understand what `os.getenv()` returns.

---

# Creating the OpenRouter Client

Next, create an OpenAI client.

```python
client = OpenAI(

    api_key=API_KEY,

    base_url="https://openrouter.ai/api/v1"

)
```

Let's examine the parameters.

## api_key

```python
api_key=API_KEY
```

This tells OpenRouter who is making the request.

Without an API key, the request will be rejected.

---

## base_url

Normally the OpenAI SDK sends requests to OpenAI.

By changing the `base_url`, we redirect every request to OpenRouter instead.

```python
base_url="https://openrouter.ai/api/v1"
```

Everything else remains exactly the same.

---

# Understanding Chat Completions

Modern LLMs communicate using **messages**.

Instead of sending one giant string, we send a conversation.

For example,

```text
System:
You are a teacher.

User:
Grade this assignment.

Assistant:
...
```

Each message has two parts.

| Field   | Purpose         |
| ------- | --------------- |
| role    | Who is speaking |
| content | What they said  |

The three most common roles are:

| Role      | Meaning                 |
| --------- | ----------------------- |
| system    | Instructions for the AI |
| user      | The user's request      |
| assistant | Previous AI responses   |

---

# Your First AI Request

Let's write our first function.

```python
def ask_ai(prompt):

    response = client.chat.completions.create(

        model="openai/gpt-oss-20b:free",

        messages=[

            {
                "role": "user",
                "content": prompt
            }

        ]

    )

    return response.choices[0].message.content
```

Although this function is short, several things happen behind the scenes.

```text
Python
   │
   ▼
OpenAI SDK
   │
   ▼
OpenRouter
   │
   ▼
Large Language Model
   │
   ▼
Generated Response
   │
   ▼
Python
```

The SDK handles all of the networking for us.

---

# Understanding the Response

The response object contains a lot of information.

```python
response
```

includes

* generated text
* model name
* token usage
* finish reason
* request metadata

We're interested in only one field.

```python
response.choices[0].message.content
```

This contains the actual response produced by the model.

For example,

```text
The student's essay demonstrates a clear understanding
of the topic but would benefit from stronger supporting evidence...
```

---

# Testing the Connection

Before integrating the AI into our application, let's test the function.

Temporarily add

```python
print(
    ask_ai(
        "Say hello!"
    )
)
```

Run

```bash
python engine.py
```

If everything is configured correctly, you should see something similar to

```text
Hello! How can I help you today?
```

Congratulations!

Markly can now communicate with a Large Language Model.

---

# Turning the AI into a Teacher

At the moment, our AI behaves like a general chatbot.

If we ask

```text
Grade this assignment.
```

the quality of the response will vary considerably.

We need to provide better instructions.

This is where **system prompts** become useful.

Instead of saying only

```text
Grade this assignment.
```

we'll first tell the AI who it is.

```python
messages=[

    {
        "role":"system",
        "content":"You are an experienced teacher."
    },

    {
        "role":"user",
        "content":prompt
    }

]
```

Now every response will be generated from the perspective of an experienced educator.

This simple addition dramatically improves consistency.

---

# Building a Reusable Grading Function

Rather than exposing `ask_ai()` to the rest of the application, let's create a function with a more meaningful name.

```python
def grade_assignment(
    assignment_text
):
    prompt = f"""
Please grade the following assignment.

Provide:

- strengths
- weaknesses
- suggestions
- final grade

Assignment

{assignment_text}
"""

    return ask_ai(prompt)
```

Notice how this function hides the complexity of prompt construction.

The rest of the application only needs to write

```python
feedback = grade_assignment(text)
```

without worrying about how the prompt is created.

This is another example of good software design: keep the user interface separate from AI-specific logic.

---

# Connecting the AI to the Interface

Open `app.py`.

Locate the `preview_assignment()` function that currently displays the extracted text.

Instead of showing the raw assignment, we'll send it to the AI.

First, import the grading function.

```python
from engine import grade_assignment
```

Now update the button callback.

```python
def grade(event):

    if upload.value is None:

        feedback.object = """
## Feedback

Please upload an assignment first.
"""

        return

    assignment = extract_text_from_file(
        upload.value,
        upload.filename
    )

    feedback.object = """
## Feedback

⏳ Grading assignment...
"""

    result = grade_assignment(
        assignment
    )

    feedback.object = result
```

Let's walk through what happens when the teacher clicks **Grade Assignment**:

1. Check whether a file has been uploaded.
2. Extract the assignment's text.
3. Display a temporary "Grading..." message.
4. Send the assignment to the LLM.
5. Wait for the response.
6. Replace the temporary message with the AI's feedback.

Although this process only takes a few lines of code, a significant amount of work is happening behind the scenes.

---

# Testing the Application

Restart the Panel server:

```bash
panel serve app.py --autoreload
```

Now:

1. Upload a PDF or DOCX assignment.
2. Choose any subject (we'll make this meaningful in the next chapter).
3. Click **Grade Assignment**.

After a short delay, the AI should return feedback on the student's work.

At this stage, the feedback will likely be generic because we're not yet telling the AI *what kind of teacher it should be*. A mathematics assignment and an English essay may receive similarly structured comments, even though they require different evaluation criteria.

---

# Current Architecture

Our application has grown considerably since the beginning of the tutorial.

```text
Teacher
    │
    ▼
Upload Assignment
    │
    ▼
Extract Text
    │
    ▼
Create Prompt
    │
    ▼
OpenRouter
    │
    ▼
Large Language Model
    │
    ▼
Teacher Feedback
    │
    ▼
Display Results
```

We've now built the core AI pipeline. Markly can upload documents, extract their contents, send them to a language model, and display AI-generated feedback.

However, there's still a major limitation: the AI behaves like a general-purpose assistant rather than a subject specialist.

In the next instalment, we'll introduce one of Markly's defining features: **Teacher Personas**. We'll create specialized prompts for Mathematics, English, Science, and Programming, allowing the same language model to adopt different grading philosophies and produce feedback that more closely resembles the expectations of experienced educators in each discipline.
